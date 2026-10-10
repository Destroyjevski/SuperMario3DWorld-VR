#include "cemuvr/mic_blow_capture.h"
#include "cemuvr/mic_blow_detector.h"
#include "cemuvr/diag.h"

#include <windows.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <mmreg.h>

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cwctype>
#include <string>
#include <vector>

namespace cemuvr {
namespace {

// PKEY_Device_FriendlyName, spelled out so no GUID library is needed.
const PROPERTYKEY kFriendlyName = {
    {0xa45c254e, 0xdf1c, 0x4efd, {0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0}}, 14};
// WAVEFORMATEXTENSIBLE sub-formats share this GUID; Data1 is the format tag.
const GUID kSubFormatBase = {
    0x00000000, 0x0000, 0x0010, {0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71}};

template <class T> void release(T*& p) { if (p) { p->Release(); p = nullptr; } }

std::string utf8(const std::wstring& w) {
    if (w.empty()) return {};
    const int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), int(w.size()), nullptr, 0, nullptr, nullptr);
    std::string s(size_t(n > 0 ? n : 0), '\0');
    if (n > 0) WideCharToMultiByte(CP_UTF8, 0, w.c_str(), int(w.size()), &s[0], n, nullptr, nullptr);
    for (char& c : s) if (c == '"') c = '\'';   // keeps the log record's quoting intact
    return s;
}

std::wstring lower(std::wstring s) {
    for (auto& c : s) c = wchar_t(std::towlower(c));
    return s;
}

std::wstring friendlyName(IMMDevice* device) {
    std::wstring name;
    IPropertyStore* store = nullptr;
    if (SUCCEEDED(device->OpenPropertyStore(STGM_READ, &store))) {
        PROPVARIANT value;
        PropVariantInit(&value);
        if (SUCCEEDED(store->GetValue(kFriendlyName, &value)) && value.vt == VT_LPWSTR && value.pwszVal)
            name = value.pwszVal;
        PropVariantClear(&value);
        store->Release();
    }
    return name;
}

IMMDevice* pickDevice(IMMDeviceEnumerator* devices, const std::wstring& wanted, std::wstring& name) {
    IMMDevice* chosen = nullptr;
    if (wanted.empty()) {
        if (FAILED(devices->GetDefaultAudioEndpoint(eCapture, eConsole, &chosen))) return nullptr;
    } else {
        IMMDeviceCollection* all = nullptr;
        if (FAILED(devices->EnumAudioEndpoints(eCapture, DEVICE_STATE_ACTIVE, &all))) return nullptr;
        UINT count = 0;
        all->GetCount(&count);
        const std::wstring needle = lower(wanted);
        for (UINT i = 0; i < count && !chosen; ++i) {
            IMMDevice* device = nullptr;
            if (FAILED(all->Item(i, &device))) continue;
            if (lower(friendlyName(device)).find(needle) != std::wstring::npos) chosen = device;
            else device->Release();
        }
        all->Release();
        if (!chosen) return nullptr;
    }
    name = friendlyName(chosen);
    return chosen;
}

enum class Sample { Unsupported, Float32, Int16, Int24, Int32 };

Sample sampleKind(const WAVEFORMATEX* f) {
    WORD tag = f->wFormatTag;
    if (tag == WAVE_FORMAT_EXTENSIBLE && f->cbSize >= 22) {
        const GUID& sub = reinterpret_cast<const WAVEFORMATEXTENSIBLE*>(f)->SubFormat;
        GUID base = kSubFormatBase;
        base.Data1 = sub.Data1;
        if (std::memcmp(&base, &sub, sizeof(GUID)) != 0) return Sample::Unsupported;
        tag = WORD(sub.Data1);
    }
    if (tag == WAVE_FORMAT_IEEE_FLOAT && f->wBitsPerSample == 32) return Sample::Float32;
    if (tag == WAVE_FORMAT_PCM && f->wBitsPerSample == 16) return Sample::Int16;
    if (tag == WAVE_FORMAT_PCM && f->wBitsPerSample == 24) return Sample::Int24;
    if (tag == WAVE_FORMAT_PCM && f->wBitsPerSample == 32) return Sample::Int32;
    return Sample::Unsupported;
}

const char* sampleName(Sample kind) {
    switch (kind) {
    case Sample::Float32: return "float32";
    case Sample::Int16: return "int16";
    case Sample::Int24: return "int24";
    case Sample::Int32: return "int32";
    default: return "unsupported";
    }
}

void toMono(const BYTE* data, UINT32 frames, UINT channels, Sample kind, std::vector<float>& mono) {
    mono.resize(frames);
    const float share = 1.f / float(channels ? channels : 1);
    for (UINT32 i = 0; i < frames; ++i) {
        float sum = 0.f;
        for (UINT c = 0; c < channels; ++c) {
            const size_t k = size_t(i) * channels + c;
            switch (kind) {
            case Sample::Float32: { float v; std::memcpy(&v, data + k * 4, 4); sum += v; break; }
            case Sample::Int16: { int16_t v; std::memcpy(&v, data + k * 2, 2); sum += v / 32768.f; break; }
            case Sample::Int24: {
                const BYTE* p = data + k * 3;
                const int32_t v = int32_t(uint32_t(p[2]) << 24 | uint32_t(p[1]) << 16 | uint32_t(p[0]) << 8) >> 8;
                sum += v / 8388608.f;
                break;
            }
            case Sample::Int32: { int32_t v; std::memcpy(&v, data + k * 4, 4); sum += float(v / 2147483648.0); break; }
            default: break;
            }
        }
        mono[i] = sum * share;
    }
}

std::string hex(HRESULT hr) {
    char text[16];
    std::snprintf(text, sizeof(text), "0x%08lx", (unsigned long)hr);
    return text;
}

// Everything one capture session holds, released in reverse order.
struct Session {
    IMMDeviceEnumerator* devices{nullptr};
    IMMDevice* device{nullptr};
    IAudioClient* client{nullptr};
    IAudioCaptureClient* capture{nullptr};
    WAVEFORMATEX* format{nullptr};
    HANDLE ready{nullptr};
    bool started{false};
    ~Session() {
        if (started) client->Stop();
        release(capture);
        release(client);
        release(device);
        release(devices);
        if (format) CoTaskMemFree(format);
        if (ready) CloseHandle(ready);
    }
};

// Runs until asked to stop (returns "") or until the device fails (returns why).
std::string listen(const std::wstring& wanted, float minLevelDb, HANDLE wake,
                   const std::atomic<bool>& stop, std::atomic<bool>& blowing,
                   uint32_t& onsets, uint32_t& vetoes) {
    Session s;
    HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                                  __uuidof(IMMDeviceEnumerator), reinterpret_cast<void**>(&s.devices));
    if (FAILED(hr)) return "device_list hr=" + hex(hr);
    std::wstring name;
    s.device = pickDevice(s.devices, wanted, name);
    if (!s.device) return wanted.empty() ? "no_default_recording_device"
                                         : "no_recording_device_named=\"" + utf8(wanted) + "\"";
    hr = s.device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, reinterpret_cast<void**>(&s.client));
    if (hr == E_ACCESSDENIED) return "access_denied -- Windows privacy: microphone access for desktop apps";
    if (FAILED(hr)) return "activate hr=" + hex(hr);
    hr = s.client->GetMixFormat(&s.format);
    if (FAILED(hr) || !s.format) return "mix_format hr=" + hex(hr);
    const Sample kind = sampleKind(s.format);
    if (kind == Sample::Unsupported || !s.format->nChannels) return "unsupported_format";
    hr = s.client->Initialize(AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
                              2000000, 0, s.format, nullptr);   // 200 ms shared buffer
    if (hr == E_ACCESSDENIED) return "access_denied -- Windows privacy: microphone access for desktop apps";
    if (FAILED(hr)) return "initialize hr=" + hex(hr);
    s.ready = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (!s.ready || FAILED(s.client->SetEventHandle(s.ready))) return "event";
    hr = s.client->GetService(__uuidof(IAudioCaptureClient), reinterpret_cast<void**>(&s.capture));
    if (FAILED(hr)) return "capture_service hr=" + hex(hr);
    MicBlowDetector detector(s.format->nSamplesPerSec, minLevelDb);
    hr = s.client->Start();
    if (FAILED(hr)) return "start hr=" + hex(hr);
    s.started = true;
    CVR_INFO("mic.capture", "listening=1 device=\"%s\" rate=%lu channels=%u format=%s minLevel=%.1f -- analysed in memory, nothing recorded",
             utf8(name).c_str(), (unsigned long)s.format->nSamplesPerSec, (unsigned)s.format->nChannels,
             sampleName(kind), minLevelDb);

    HANDLE waits[2] = {s.ready, wake};
    std::vector<float> mono;
    ULONGLONG lastAudio = GetTickCount64(), since = 0;
    bool active = false;
    uint32_t seenVetoes = 0, traces = 0;
    MicBlowDetector::Trace trace;
    while (!stop.load(std::memory_order_acquire)) {
        if (WaitForMultipleObjects(2, waits, FALSE, 250) == WAIT_OBJECT_0 + 1) break;
        UINT32 packet = 0;
        while (SUCCEEDED(hr = s.capture->GetNextPacketSize(&packet)) && packet > 0) {
            BYTE* data = nullptr;
            UINT32 frames = 0;
            DWORD flags = 0;
            hr = s.capture->GetBuffer(&data, &frames, &flags, nullptr, nullptr);
            if (FAILED(hr)) break;
            if (flags & AUDCLNT_BUFFERFLAGS_SILENT) mono.assign(frames, 0.f);
            else toMono(data, frames, s.format->nChannels, kind, mono);
            s.capture->ReleaseBuffer(frames);
            detector.push(mono.data(), mono.size());
            lastAudio = GetTickCount64();
            // Feature numbers per 100 ms with sound, for tuning; never audio.
            if (detector.takeTrace(trace) && traces < 1500) {
                ++traces;
                CVR_INFO("mic.trace", "level=%.0f..%.0f blowPitch=%.2f..%.2f voicePitch=%.2f..%.2f low=%.2f..%.2f audible=%d candidates=%d voiced=%d raw=%d blowing=%d",
                         trace.minLevel, trace.maxLevel, trace.minPeriodicity, trace.maxPeriodicity,
                         trace.minVoice, trace.maxVoice, trace.minLow, trace.maxLow, trace.audible,
                         trace.candidates, trace.voiced, trace.raw, trace.active);
            }
        }
        if (FAILED(hr)) {
            blowing.store(false, std::memory_order_release);
            return hr == AUDCLNT_E_DEVICE_INVALIDATED ? "device_lost" : "read hr=" + hex(hr);
        }
        // Unpitched sound next to a vowel: speech, not blowing.
        if (detector.stats().vetoes != seenVetoes) {
            seenVetoes = detector.stats().vetoes;
            ++vetoes;
            if (vetoes <= 30 || vetoes % 50 == 0)
                CVR_INFO("mic.blow", "ignored=speech count=%u level=%.1f periodicity=%.2f low=%.2f",
                         vetoes, detector.stats().levelDb, detector.stats().periodicity, detector.stats().lowRatio);
        }
        // A stalled stream must not hold the game in a blow.
        const ULONGLONG now = GetTickCount64();
        const bool on = detector.active() && now - lastAudio < 500;
        if (on != active) {
            active = on;
            const auto& st = detector.stats();
            if (on) {
                since = now;
                ++onsets;
                if (onsets <= 30 || onsets % 50 == 0)
                    CVR_INFO("mic.blow", "start=1 count=%u level=%.1f floor=%.1f periodicity=%.2f low=%.2f",
                             onsets, st.levelDb, st.floorDb, st.periodicity, st.lowRatio);
            } else if (onsets <= 30 || onsets % 50 == 0) {
                CVR_INFO("mic.blow", "stop=1 count=%u ms=%llu meanPeriodicity=%.2f meanLow=%.2f voicedBlocks=%u",
                         onsets, (unsigned long long)(now - since), st.eventPeriodicity, st.eventLowRatio,
                         st.eventVoiced);
            }
        }
        blowing.store(on, std::memory_order_release);
    }
    blowing.store(false, std::memory_order_release);
    return {};
}

} // namespace

void MicBlowCapture::start() {
    if (m_thread.joinable()) return;
    const wchar_t* setting = _wgetenv(L"CEMUVR_BLOW_MIC");
    std::wstring wanted = setting ? setting : L"";
    while (!wanted.empty() && std::iswspace(wanted.back())) wanted.pop_back();
    while (!wanted.empty() && std::iswspace(wanted.front())) wanted.erase(wanted.begin());
    const std::wstring flag = lower(wanted);
    if (flag == L"0" || flag == L"off" || flag == L"false" || flag == L"no") {
        CVR_INFO("mic.capture", "off=1 -- CEMUVR_BLOW_MIC=0; the right-hand gesture still works");
        return;
    }
    if (flag == L"1" || flag == L"on" || flag == L"default") wanted.clear();

    float minLevelDb = MicBlowDetector::kDefaultMinLevelDb;
    if (const char* db = std::getenv("CEMUVR_BLOW_MIC_DB")) {
        char* end = nullptr;
        const float value = std::strtof(db, &end);
        if (end != db && std::isfinite(value)) minLevelDb = value;
    }

    // The thread runs code from this DLL, so the DLL must outlive it. Pinning
    // keeps a loader-initiated unload from ever racing the capture thread.
    HMODULE self = nullptr;
    GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_PIN,
                       reinterpret_cast<LPCWSTR>(&kFriendlyName), &self);

    m_wake = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!m_wake) { CVR_WARN("mic.capture", "unavailable reason=event"); return; }
    m_stop.store(false, std::memory_order_release);
    m_blowing.store(false, std::memory_order_release);
    try {
        m_thread = std::thread(&MicBlowCapture::run, this, wanted, minLevelDb);
    } catch (...) {
        CVR_WARN("mic.capture", "unavailable reason=thread");
        CloseHandle(m_wake);
        m_wake = nullptr;
    }
}

void MicBlowCapture::stop() {
    if (m_thread.joinable()) {
        m_stop.store(true, std::memory_order_release);
        SetEvent(m_wake);
        m_thread.join();
    }
    if (m_wake) { CloseHandle(m_wake); m_wake = nullptr; }
    m_blowing.store(false, std::memory_order_release);
}

void MicBlowCapture::run(std::wstring wanted, float minLevelDb) {
    const HRESULT com = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    std::string lastProblem;
    uint32_t onsets = 0, vetoes = 0;
    while (!m_stop.load(std::memory_order_acquire)) {
        const std::string problem = listen(wanted, minLevelDb, m_wake, m_stop, m_blowing, onsets, vetoes);
        m_blowing.store(false, std::memory_order_release);
        if (m_stop.load(std::memory_order_acquire)) break;
        if (problem != lastProblem) {
            CVR_WARN("mic.capture", "unavailable reason=%s -- retrying every 3 s; the right-hand gesture still works",
                     problem.c_str());
            lastProblem = problem;
        }
        WaitForSingleObject(m_wake, 3000);
    }
    CVR_INFO("mic.capture", "stopped=1 blows=%u ignoredSpeech=%u", onsets, vetoes);
    if (SUCCEEDED(com)) CoUninitialize();
}

} // namespace cemuvr
