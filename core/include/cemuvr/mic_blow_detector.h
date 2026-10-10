#pragma once
#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace cemuvr {
// Recognises blowing into a microphone, analysed in 10 ms blocks.
//
// Blowing: loud, unpitched, much energy below 700 Hz. Eight such blocks out of
// ten start a raw detection (the rule that recognised real blowing through
// Virtual Desktop in the first headset test).
// Speech: its unpitched consonants also pass that rule, but only briefly, and
// every syllable carries a pitched vowel. The output therefore needs the raw
// detection to hold for 150 ms and no vowel in the last 300 ms; a vowel during
// a blow ends it. Vowels are judged with a second pitch measure in the voice
// band, so the blow rule itself is unchanged.
// Nothing beyond the current 40 ms analysis window is kept.
class MicBlowDetector {
public:
    struct Stats {
        float levelDb{-120.f}, floorDb{-120.f}, lowRatio{0.f};
        float periodicity{0.f};      // blow rule: 12 kHz, pre-emphasis, 30 ms
        float voicePeriodicity{0.f}; // vowel rule: below 1.5 kHz, 40 ms
        bool candidate{false}, voiced{false}, raw{false};
        uint32_t onsets{0}, vetoes{0};
        uint32_t eventBlocks{0}, eventVoiced{0};
        float eventPeriodicity{0.f}, eventLowRatio{0.f};
    };

    // Feature summary of 100 ms with sound, for the session log: numbers only.
    struct Trace {
        float minLevel{0.f}, maxLevel{0.f}, minPeriodicity{0.f}, maxPeriodicity{0.f};
        float minVoice{0.f}, maxVoice{0.f}, minLow{0.f}, maxLow{0.f};
        int audible{0}, candidates{0}, voiced{0}, raw{0}, active{0};
    };

    static constexpr float kDefaultMinLevelDb = -45.f;

    explicit MicBlowDetector(uint32_t sampleRate = 48000,
                             float minLevelDb = kDefaultMinLevelDb) {
        configure(sampleRate, minLevelDb);
    }

    void configure(uint32_t sampleRate, float minLevelDb = kDefaultMinLevelDb) {
        m_rate = std::clamp<uint32_t>(sampleRate, 8000, 192000);
        m_block = m_rate / 100;
        const float pi = 3.14159265f;
        m_blow.configure(m_rate, (m_rate + 6000) / 12000, 0.030f);
        m_voice.configure(m_rate, (m_rate + 3000) / 6000, 0.040f);
        m_lowAlpha = 1.f - std::exp(-2.f * pi * 700.f / float(m_rate));
        m_emphasis = std::exp(-2.f * pi * 200.f / float(m_rate));
        m_voiceAlpha = 1.f - std::exp(-2.f * pi * 1500.f / float(m_rate));
        m_minLevelDb = std::isfinite(minLevelDb) ? std::clamp(minLevelDb, -90.f, -6.f)
                                                 : kDefaultMinLevelDb;
        reset();
    }

    void reset() {
        m_low = 0.f; m_energy = m_lowEnergy = 0.0; m_filled = 0;
        m_blowPrevious = m_voicePrevious = m_voice1 = m_voice2 = 0.f;
        m_blow.reset(); m_voice.reset();
        m_chunks.fill(kSilent); m_chunkPos = 0; m_chunkCount = 0;
        m_chunkMin = kSilent; m_chunkBlocks = 0;
        m_candidates = 0; m_voicedBlocks = 0; m_raw = false; m_rawRun = 0;
        m_vetoed = false; m_active = false;
        m_sumPeriodicity = m_sumLow = 0.0;
        m_trace = Trace{}; m_traceBlocks = 0; m_traceReady = false;
        const uint32_t onsets = m_stats.onsets, vetoes = m_stats.vetoes;
        m_stats = Stats{}; m_stats.onsets = onsets; m_stats.vetoes = vetoes;
    }

    // Samples in [-1, 1]; non-finite samples count as silence.
    bool push(const float* samples, size_t count) {
        if (!samples) return m_active;
        for (size_t i = 0; i < count; ++i) {
            float x = samples[i];
            if (!std::isfinite(x)) x = 0.f;
            x = std::clamp(x, -1.f, 1.f);
            m_low += m_lowAlpha * (x - m_low);
            m_energy += double(x) * x;
            m_lowEnergy += double(m_low) * m_low;
            if (m_blow.add(x)) {
                const float d = m_blow.decimated();
                m_blow.store(d - 0.9f * m_blowPrevious);   // pre-emphasis whitens rumble
                m_blowPrevious = d;
            }
            const float emphasised = x - m_emphasis * m_voicePrevious;
            m_voicePrevious = x;
            m_voice1 += m_voiceAlpha * (emphasised - m_voice1);
            m_voice2 += m_voiceAlpha * (m_voice1 - m_voice2);
            if (m_voice.add(m_voice2)) m_voice.store(m_voice.decimated());
            if (++m_filled == m_block) finishBlock();
        }
        return m_active;
    }

    bool active() const { return m_active; }
    const Stats& stats() const { return m_stats; }
    // True once per 100 ms that contained sound above the level limit.
    bool takeTrace(Trace& out) {
        if (!m_traceReady) return false;
        out = m_traceDone; m_traceReady = false; return true;
    }

private:
    // Decimating ring buffer with a normalised autocorrelation pitch measure.
    struct Pitch {
        static constexpr uint32_t kRing = 512;
        std::array<float, kRing> ring{};
        uint32_t pos{0}, filled{0}, factor{1}, count{0}, window{256}, minLag{1}, maxLag{2};
        float sum{0.f};
        void configure(uint32_t rate, uint32_t decimate, float seconds) {
            factor = std::max<uint32_t>(1, decimate);
            const float r = float(rate) / float(factor);
            window = std::min<uint32_t>(kRing, uint32_t(r * seconds + 0.5f));
            minLag = std::max<uint32_t>(1, uint32_t(r / 400.f + 0.5f));
            maxLag = std::min<uint32_t>(window / 2, uint32_t(r / 70.f + 0.5f));
        }
        void reset() { ring.fill(0.f); pos = filled = count = 0; sum = 0.f; }
        bool add(float x) { sum += x; return ++count == factor; }
        float decimated() const { return sum / float(factor); }
        void store(float v) {
            ring[pos] = v; pos = (pos + 1) % kRing;
            filled = std::min<uint32_t>(filled + 1, kRing);
            sum = 0.f; count = 0;
        }
        float measure() const {
            if (filled < window) return 0.f;
            float x[kRing];
            for (uint32_t i = 0; i < window; ++i) x[i] = ring[(pos + kRing - window + i) % kRing];
            float best = 0.f;
            for (uint32_t lag = minLag; lag <= maxLag; ++lag) {
                double cross = 0.0, a = 0.0, b = 0.0;
                for (uint32_t n = lag; n < window; ++n) {
                    cross += double(x[n]) * x[n - lag];
                    a += double(x[n]) * x[n];
                    b += double(x[n - lag]) * x[n - lag];
                }
                if (a > 1e-14 && b > 1e-14) best = std::max(best, float(cross / std::sqrt(a * b)));
            }
            return best;
        }
    };

    static constexpr uint32_t kChunks = 80;       // 8 s noise-floor memory in 100 ms chunks
    static constexpr float kSilent = 1e9f;
    static constexpr float kAboveFloorDb = 15.f;
    static constexpr float kMinLowRatio = 0.2f;
    static constexpr float kMaxBlowPeriodicity = 0.5f;
    static constexpr float kVoicedPeriodicity = 0.5f;
    static constexpr int kRawOn = 8, kRawOff = 2;            // of the last ten blocks
    static constexpr uint32_t kHoldBlocks = 15;              // raw detection held 150 ms
    static constexpr uint32_t kVoiceMask = 0x3fffffffu;      // last 30 blocks: 300 ms
    static constexpr int kVetoVoiced = 2, kEndVoiced = 3;    // in 300 ms / in 100 ms

    static int bits(uint32_t v) { int n = 0; for (; v; v &= v - 1) ++n; return n; }

    void finishBlock() {
        const double energy = m_energy / m_block;
        const float level = 10.f * std::log10(float(energy) + 1e-12f);
        const float lowRatio = energy > 1e-12 ? float(m_lowEnergy / m_block / energy) : 0.f;
        const bool audible = level >= m_minLevelDb;
        const float periodic = audible ? m_blow.measure() : 0.f;
        const float voicePeriodic = audible ? m_voice.measure() : 0.f;

        m_chunkMin = std::min(m_chunkMin, level);
        float floor = m_chunkMin;
        for (uint32_t i = 0; i < m_chunkCount; ++i) floor = std::min(floor, m_chunks[i]);
        if (++m_chunkBlocks == 10) {
            m_chunks[m_chunkPos] = m_chunkMin;
            m_chunkPos = (m_chunkPos + 1) % kChunks;
            m_chunkCount = std::min<uint32_t>(m_chunkCount + 1, kChunks);
            m_chunkMin = kSilent; m_chunkBlocks = 0;
        }

        const bool candidate = audible && level >= floor + kAboveFloorDb &&
                               lowRatio >= kMinLowRatio && periodic <= kMaxBlowPeriodicity;
        const bool voiced = audible && voicePeriodic >= kVoicedPeriodicity;
        m_candidates = ((m_candidates << 1) | (candidate ? 1u : 0u)) & 0x3ffu;
        m_voicedBlocks = ((m_voicedBlocks << 1) | (voiced ? 1u : 0u)) & kVoiceMask;

        const int recent = bits(m_candidates);
        if (!m_raw && recent >= kRawOn) m_raw = true;
        else if (m_raw && recent <= kRawOff) m_raw = false;
        m_rawRun = m_raw ? m_rawRun + 1 : 0;
        const bool speechNearby = bits(m_voicedBlocks) >= kVetoVoiced;
        if (!m_raw || !speechNearby) m_vetoed = false;

        if (!m_active) {
            if (m_raw && m_rawRun >= kHoldBlocks) {
                if (speechNearby) {
                    if (!m_vetoed) { m_vetoed = true; ++m_stats.vetoes; }   // count once per stretch
                } else {
                    m_active = true; ++m_stats.onsets;
                    m_stats.eventBlocks = m_stats.eventVoiced = 0;
                    m_sumPeriodicity = m_sumLow = 0.0;
                }
            }
        } else if (!m_raw || bits(m_voicedBlocks & 0x3ffu) >= kEndVoiced) {
            m_active = false;      // blowing stopped, or speech began
        }
        if (m_active) {
            ++m_stats.eventBlocks;
            m_stats.eventVoiced += voiced ? 1 : 0;
            m_sumPeriodicity += periodic; m_sumLow += lowRatio;
            m_stats.eventPeriodicity = float(m_sumPeriodicity / m_stats.eventBlocks);
            m_stats.eventLowRatio = float(m_sumLow / m_stats.eventBlocks);
        }

        if (audible) {
            Trace& t = m_trace;
            if (!t.audible) {
                t.minLevel = t.maxLevel = level; t.minPeriodicity = t.maxPeriodicity = periodic;
                t.minVoice = t.maxVoice = voicePeriodic; t.minLow = t.maxLow = lowRatio;
            }
            t.minLevel = std::min(t.minLevel, level); t.maxLevel = std::max(t.maxLevel, level);
            t.minPeriodicity = std::min(t.minPeriodicity, periodic);
            t.maxPeriodicity = std::max(t.maxPeriodicity, periodic);
            t.minVoice = std::min(t.minVoice, voicePeriodic); t.maxVoice = std::max(t.maxVoice, voicePeriodic);
            t.minLow = std::min(t.minLow, lowRatio); t.maxLow = std::max(t.maxLow, lowRatio);
            ++t.audible;
        }
        m_trace.candidates += candidate; m_trace.voiced += voiced;
        m_trace.raw += m_raw; m_trace.active += m_active;
        if (++m_traceBlocks == 10) {
            if (m_trace.audible) { m_traceDone = m_trace; m_traceReady = true; }
            m_trace = Trace{}; m_traceBlocks = 0;
        }

        m_stats.levelDb = level; m_stats.floorDb = floor; m_stats.lowRatio = lowRatio;
        m_stats.periodicity = periodic; m_stats.voicePeriodicity = voicePeriodic;
        m_stats.candidate = candidate; m_stats.voiced = voiced; m_stats.raw = m_raw;
        m_energy = m_lowEnergy = 0.0; m_filled = 0;
    }

    uint32_t m_rate{48000}, m_block{480};
    float m_lowAlpha{0.f}, m_emphasis{0.f}, m_voiceAlpha{0.f}, m_minLevelDb{kDefaultMinLevelDb};
    float m_low{0.f};
    double m_energy{0.0}, m_lowEnergy{0.0};
    uint32_t m_filled{0};
    Pitch m_blow, m_voice;
    float m_blowPrevious{0.f}, m_voicePrevious{0.f}, m_voice1{0.f}, m_voice2{0.f};
    std::array<float, kChunks> m_chunks{}; uint32_t m_chunkPos{0}, m_chunkCount{0};
    float m_chunkMin{kSilent}; uint32_t m_chunkBlocks{0};
    uint32_t m_candidates{0}, m_voicedBlocks{0}, m_rawRun{0};
    bool m_raw{false}, m_vetoed{false}, m_active{false};
    double m_sumPeriodicity{0.0}, m_sumLow{0.0};
    Trace m_trace{}, m_traceDone{};
    uint32_t m_traceBlocks{0};
    bool m_traceReady{false};
    Stats m_stats{};
};
} // namespace cemuvr
