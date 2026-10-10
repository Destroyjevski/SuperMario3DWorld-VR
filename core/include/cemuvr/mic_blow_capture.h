#pragma once
#include <atomic>
#include <string>
#include <thread>

namespace cemuvr {
// Listens on a Windows recording device for blowing. Audio stays in memory,
// is analysed in 10 ms blocks by MicBlowDetector and then discarded; nothing
// is recorded, stored or sent.
//
// CEMUVR_BLOW_MIC     unset or "1": the default recording device
//                     "0": off
//                     other text: first active recording device whose name
//                     contains it (case-insensitive)
// CEMUVR_BLOW_MIC_DB  quietest level that can count as blowing, in dBFS
//                     (default -45; lower is more sensitive)
class MicBlowCapture {
public:
    MicBlowCapture() = default;
    ~MicBlowCapture() { stop(); }
    MicBlowCapture(const MicBlowCapture&) = delete;
    MicBlowCapture& operator=(const MicBlowCapture&) = delete;

    void start();
    void stop();
    bool blowing() const { return m_blowing.load(std::memory_order_acquire); }

private:
    void run(std::wstring wanted, float minLevelDb);
    std::thread m_thread;
    std::atomic<bool> m_stop{false};
    std::atomic<bool> m_blowing{false};
    void* m_wake{nullptr};
};
} // namespace cemuvr
