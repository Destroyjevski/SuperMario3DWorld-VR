#pragma once
#include <cmath>
#include <cstdint>

namespace cemuvr {
// Metres in one tracking space; times are OpenXR nanoseconds.
// No audio capture: the game's native microphone remains independent.
class HeadBlowGesture {
public:
    bool update(bool trackedAndFocused, float distanceSquared, int64_t now) {
        if (!trackedAndFocused || !std::isfinite(distanceSquared) ||
            distanceSquared < 0.f || now <= 0) { reset(); return false; }
        if (last_ && (now < last_ || now - last_ > 250000000)) reset();
        last_ = now;
        const float radius = active_ ? 0.35f : 0.28f;
        if (distanceSquared > radius * radius) {
            entered_ = 0; active_ = false; return false;
        }
        if (!entered_) entered_ = now;
        if (now - entered_ >= 150000000) active_ = true;
        return active_;
    }
    bool active() const { return active_; }
    void reset() { entered_ = last_ = 0; active_ = false; }
private:
    int64_t entered_{0}, last_{0};
    bool active_{false};
};
} // namespace cemuvr
