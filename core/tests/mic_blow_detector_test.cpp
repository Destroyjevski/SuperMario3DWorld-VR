#include "cemuvr/mic_blow_detector.h"
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <random>
#include <string>
#include <vector>
#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL line " << __LINE__ << ": " #x "\n"; std::exit(1); } } while (false)

// Synthetic audio only; no device, recording or file is used.
namespace {
constexpr float kPi = 3.14159265f;

struct Clip {
    std::vector<float> samples;
    void normalise(float dbfs) {
        double energy = 0.0;
        for (float s : samples) energy += double(s) * s;
        energy /= samples.empty() ? 1.0 : double(samples.size());
        const float gain = energy > 0.0 ? float(std::pow(10.0, dbfs / 20.0) / std::sqrt(energy)) : 0.f;
        for (float& s : samples) s *= gain;
    }
};

struct Generator {
    uint32_t rate;
    std::mt19937 rng{1234};
    std::normal_distribution<float> gauss{0.f, 1.f};

    Clip room(float seconds, float dbfs) {
        Clip c; c.samples.resize(size_t(seconds * rate));
        for (float& s : c.samples) s = gauss(rng);
        c.normalise(dbfs); return c;
    }
    // Wind noise on the capsule: strong rumble plus a broadband share.
    Clip blow(float seconds, float dbfs, float gustHz = 0.f, float gustDepth = 0.f) {
        Clip c; c.samples.resize(size_t(seconds * rate));
        const float a = 1.f - std::exp(-2.f * kPi * 300.f / float(rate));
        float low = 0.f;
        std::vector<float> lowPart(c.samples.size()), wide(c.samples.size());
        double le = 0.0, we = 0.0;
        for (size_t i = 0; i < c.samples.size(); ++i) {
            low += a * (gauss(rng) - low);
            lowPart[i] = low; wide[i] = gauss(rng);
            le += double(low) * low; we += double(wide[i]) * wide[i];
        }
        const float lg = float(std::sqrt(0.8 / (le + 1e-30))), wg = float(std::sqrt(0.2 / (we + 1e-30)));
        for (size_t i = 0; i < c.samples.size(); ++i) {
            float gust = 1.f;
            if (gustHz > 0.f)
                gust = 1.f - gustDepth * (0.5f + 0.5f * std::sin(2.f * kPi * gustHz * float(i) / float(rate)));
            c.samples[i] = (lowPart[i] * lg + wide[i] * wg) * gust;
        }
        c.normalise(dbfs); return c;
    }
    // Voiced speech: gliding pitch, falling harmonics, syllable envelope.
    Clip speech(float seconds, float dbfs, float f0From, float f0To) {
        Clip c; c.samples.resize(size_t(seconds * rate));
        float phase = 0.f;
        for (size_t i = 0; i < c.samples.size(); ++i) {
            const float t = float(i) / float(rate);
            const float f0 = f0From + (f0To - f0From) * (0.5f + 0.5f * std::sin(2.f * kPi * 0.7f * t));
            phase += 2.f * kPi * f0 / float(rate);
            float v = 0.f;
            for (int k = 1; k * f0 < 4000.f && k < 40; ++k) {
                const float f = k * f0;
                const float formant = std::exp(-std::pow((f - 600.f) / 400.f, 2.f)) +
                                      0.6f * std::exp(-std::pow((f - 1700.f) / 500.f, 2.f)) + 0.1f;
                v += formant / float(k) * std::sin(float(k) * phase);
            }
            const float syllable = std::pow(std::sin(kPi * std::fmod(t * 4.f, 1.f)), 2.f);
            c.samples[i] = v * (0.15f + 0.85f * syllable) + 0.01f * gauss(rng);
        }
        c.normalise(dbfs); return c;
    }
    // Blowing as a gated microphone may deliver it: 20 ms dropouts every 100 ms.
    Clip gappyBlow(float seconds, float dbfs) {
        Clip c = blow(seconds, dbfs);
        const size_t every = rate / 10, gap = rate / 50;
        for (size_t start = every / 2; start < c.samples.size(); start += every)
            for (size_t i = start; i < std::min(c.samples.size(), start + gap); ++i) c.samples[i] = 0.f;
        return c;
    }
    Clip silence(float seconds) {
        Clip c; c.samples.assign(size_t(seconds * rate), 0.f); return c;
    }
    // Speech as a headset microphone with noise suppression delivers it: words
    // of an unpitched breathy consonant (h) and a pitched vowel with jitter and
    // breath, separated by digital silence (or faint room noise when ungated).
    Clip words(float seconds, float dbfs, bool gated = true, float jitter = 0.005f, float breathiness = 0.15f) {
        Clip c;
        const int consonantMs[] = {60, 90, 120, 140, 100, 80};
        const int vowelMs[] = {160, 220, 180, 250, 140, 200};
        const int gapMs[] = {120, 300, 450, 200, 600, 150};
        const float breathA = 1.f - std::exp(-2.f * kPi * 2500.f / float(rate));
        float phase = 0.f, breath = 0.f;
        for (int w = 0; c.samples.size() < size_t(seconds * rate); ++w) {
            const size_t consonant = size_t(consonantMs[w % 6]) * rate / 1000;
            for (size_t i = 0; i < consonant; ++i) {
                breath += breathA * (gauss(rng) - breath);
                c.samples.push_back(0.5f * breath);
            }
            const size_t vowel = size_t(vowelMs[w % 6]) * rate / 1000;
            // Pitch glides slowly within the vowel and jitters once per period.
            const float base = 100.f + 25.f * float(w % 6);
            float f0 = base;
            for (size_t i = 0; i < vowel; ++i) {
                phase += 2.f * kPi * f0 / float(rate);
                if (phase >= 2.f * kPi) {
                    phase -= 2.f * kPi;
                    const float glide = 1.f + 0.08f * (float(i) / float(vowel) - 0.5f);
                    f0 = std::clamp(base * glide * (1.f + jitter * gauss(rng)), 70.f, 300.f);
                }
                float v = 0.f;
                for (int k = 1; k * f0 < 4000.f && k < 40; ++k) {
                    const float f = k * f0;
                    const float formant = std::exp(-std::pow((f - 600.f) / 400.f, 2.f)) +
                                          0.6f * std::exp(-std::pow((f - 1700.f) / 500.f, 2.f)) + 0.1f;
                    v += formant / float(k) * std::sin(float(k) * phase);
                }
                breath += breathA * (gauss(rng) - breath);
                const float envelope = std::sin(kPi * (float(i) + 0.5f) / float(vowel));
                c.samples.push_back(v * (0.3f + 0.7f * envelope) + breathiness * breath);
            }
            const size_t gap = size_t(gapMs[w % 6]) * rate / 1000;
            for (size_t i = 0; i < gap; ++i) c.samples.push_back(gated ? 0.f : 0.0005f * gauss(rng));
        }
        c.normalise(dbfs); return c;
    }
    Clip tone(float seconds, float dbfs, float hz) {
        Clip c; c.samples.resize(size_t(seconds * rate));
        for (size_t i = 0; i < c.samples.size(); ++i)
            c.samples[i] = std::sin(2.f * kPi * hz * float(i) / float(rate));
        c.normalise(dbfs); return c;
    }
    // Hissing ("sss"): differentiated noise, energy at high frequencies.
    Clip hiss(float seconds, float dbfs) {
        Clip c; c.samples.resize(size_t(seconds * rate));
        float p1 = 0.f, p2 = 0.f;
        for (float& s : c.samples) { const float w = gauss(rng); s = w - 2.f * p1 + p2; p2 = p1; p1 = w; }
        c.normalise(dbfs); return c;
    }
    // Whispering: band noise around 1-4 kHz.
    Clip whisper(float seconds, float dbfs) {
        Clip c; c.samples.resize(size_t(seconds * rate));
        const float hiA = 1.f - std::exp(-2.f * kPi * 4000.f / float(rate));
        const float loA = 1.f - std::exp(-2.f * kPi * 1000.f / float(rate));
        float hi = 0.f, lo = 0.f;
        for (float& s : c.samples) { const float w = gauss(rng); hi += hiA * (w - hi); lo += loA * (hi - lo); s = hi - lo; }
        c.normalise(dbfs); return c;
    }
    // Five millisecond knocks every 200 ms over room noise.
    Clip clicks(float seconds, float dbfs) {
        Clip c = room(seconds, -62.f);
        const size_t burst = rate / 200, every = rate / 5;
        const float amp = std::pow(10.f, dbfs / 20.f) * 1.4f;
        for (size_t start = every / 2; start + burst < c.samples.size(); start += every)
            for (size_t i = 0; i < burst; ++i) c.samples[start + i] += amp * gauss(rng) * 0.7f;
        return c;
    }
};

struct Run {
    cemuvr::MicBlowDetector detector;
    uint32_t rate;
    std::vector<uint8_t> state;   // one entry per 10 ms of audio fed
    size_t fed{0};
    Run(uint32_t r, float minDb = cemuvr::MicBlowDetector::kDefaultMinLevelDb) : detector(r, minDb), rate(r) {}
    // Mark where a clip starts and ends in 10 ms units.
    std::pair<size_t, size_t> feed(const Clip& clip) {
        const size_t first = fed / (rate / 100);
        size_t pos = 0, chunk = 137;   // odd chunk sizes cross block boundaries
        while (pos < clip.samples.size()) {
            const size_t n = std::min(chunk, clip.samples.size() - pos);
            detector.push(clip.samples.data() + pos, n);
            for (size_t i = 0; i < n; ++i) {
                ++fed;
                if (fed % (rate / 100) == 0) state.push_back(detector.active() ? 1 : 0);
            }
            pos += n; chunk = chunk == 137 ? 61 : 137;
        }
        return {first, fed / (rate / 100)};
    }
    bool anyActive(std::pair<size_t, size_t> r) const {
        for (size_t i = r.first; i < r.second && i < state.size(); ++i) if (state[i]) return true;
        return false;
    }
    bool allActive(std::pair<size_t, size_t> r, size_t skip) const {
        for (size_t i = r.first + skip; i < r.second && i < state.size(); ++i) if (!state[i]) return false;
        return true;
    }
    size_t firstActive(std::pair<size_t, size_t> r) const {
        for (size_t i = r.first; i < r.second; ++i) if (state[i]) return i - r.first;
        return SIZE_MAX;
    }
};
} // namespace

int main() {
    int checks = 0;
    for (uint32_t rate : {16000u, 44100u, 48000u}) {
        Generator g{rate};
        Run run(rate);
        auto quiet = run.feed(g.room(3.f, -62.f));
        CHECK(!run.anyActive(quiet)); ++checks;

        auto blow = run.feed(g.blow(1.5f, -20.f));
        CHECK(run.firstActive(blow) <= 30); ++checks;             // within 300 ms
        CHECK(run.allActive(blow, 30)); ++checks;
        auto after = run.feed(g.room(1.f, -62.f));
        CHECK(!run.anyActive({after.first + 15, after.second})); ++checks; // off within 150 ms

        auto speech = run.feed(g.speech(3.f, -15.f, 110.f, 190.f));
        CHECK(!run.anyActive(speech)); ++checks;
        run.feed(g.room(1.f, -62.f));
        auto high = run.feed(g.speech(3.f, -15.f, 220.f, 320.f));
        CHECK(!run.anyActive(high)); ++checks;
        run.feed(g.room(1.f, -62.f));
        auto whistle = run.feed(g.tone(2.f, -10.f, 1000.f));
        CHECK(!run.anyActive(whistle)); ++checks;
        run.feed(g.room(1.f, -62.f));
        auto hum = run.feed(g.tone(2.f, -20.f, 150.f));
        CHECK(!run.anyActive(hum)); ++checks;
        run.feed(g.room(1.f, -62.f));
        auto hiss = run.feed(g.hiss(2.f, -20.f));
        CHECK(!run.anyActive(hiss)); ++checks;
        run.feed(g.room(1.f, -62.f));
        auto whisper = run.feed(g.whisper(2.f, -25.f));
        CHECK(!run.anyActive(whisper)); ++checks;
        run.feed(g.room(1.f, -62.f));
        auto knocks = run.feed(g.clicks(3.f, -6.f));
        CHECK(!run.anyActive(knocks)); ++checks;
        run.feed(g.room(1.f, -62.f));

        auto gusty = run.feed(g.blow(3.f, -22.f, 4.f, 0.6f));
        CHECK(run.firstActive(gusty) <= 30); ++checks;
        CHECK(run.allActive(gusty, 30)); ++checks;
        run.feed(g.room(2.f, -62.f));

        auto longBlow = run.feed(g.blow(6.f, -25.f));
        CHECK(run.allActive(longBlow, 30)); ++checks;
        auto rest = run.feed(g.room(2.f, -62.f));
        CHECK(!run.anyActive({rest.first + 15, rest.second})); ++checks;

        // A fan that starts and keeps running is noise, not blowing: it may
        // pass for blowing at first but must stop once the floor learns it.
        run.feed(g.room(9.f, -62.f));
        auto fan = run.feed(g.blow(12.f, -35.f));
        CHECK(!run.anyActive({fan.first + 900, fan.second})); ++checks;
        auto blowOverFan = run.feed(g.blow(1.5f, -12.f));
        CHECK(run.firstActive(blowOverFan) <= 30); ++checks;
        CHECK(run.detector.stats().onsets >= 3); ++checks;
    }

    // Noise suppression gates the headset microphone to digital silence, so the
    // noise floor is useless there; vowels must keep speech from counting.
    for (uint32_t rate : {16000u, 48000u}) {
        Generator g{rate};
        Run run(rate);
        run.feed(g.silence(2.f));
        auto blow = run.feed(g.blow(1.5f, -20.f));
        CHECK(run.firstActive(blow) <= 30); ++checks;
        CHECK(run.allActive(blow, 30)); ++checks;
        auto pause = run.feed(g.silence(1.f));
        CHECK(!run.anyActive({pause.first + 15, pause.second})); ++checks;
        auto talk = run.feed(g.words(8.f, -20.f));
        CHECK(!run.anyActive(talk)); ++checks;
        auto loud = run.feed(g.words(4.f, -8.f));
        CHECK(!run.anyActive(loud)); ++checks;
        auto quietTalk = run.feed(g.words(4.f, -38.f));
        CHECK(!run.anyActive(quietTalk)); ++checks;
        auto ungated = run.feed(g.words(4.f, -20.f, false));
        CHECK(!run.anyActive(ungated)); ++checks;
        auto rough = run.feed(g.words(4.f, -20.f, true, 0.02f, 0.4f));   // rough, breathy voice
        CHECK(!run.anyActive(rough)); ++checks;
        run.feed(g.silence(1.f));
        auto gappy = run.feed(g.gappyBlow(2.f, -22.f));
        CHECK(run.firstActive(gappy) <= 30); ++checks;
        CHECK(run.allActive(gappy, 30)); ++checks;
        run.feed(g.silence(1.f));
        auto blowAfterTalk = run.feed(g.blow(1.5f, -20.f));    // speech just ended
        CHECK(run.firstActive(blowAfterTalk) <= 60); ++checks;
        CHECK(run.allActive(blowAfterTalk, 60)); ++checks;
        auto talkAfterBlow = run.feed(g.words(2.f, -20.f));    // speaking ends a blow
        CHECK(!run.anyActive({talkAfterBlow.first + 40, talkAfterBlow.second})); ++checks;
        CHECK(run.detector.stats().onsets == 3); ++checks;
    }

    // Too quiet to be blowing, even in a silent room.
    {
        Generator g{48000};
        Run run(48000);
        run.feed(g.room(2.f, -85.f));
        auto faint = run.feed(g.blow(2.f, -50.f));
        CHECK(!run.anyActive(faint)); ++checks;
        Run sensitive(48000, -55.f);   // CEMUVR_BLOW_MIC_DB lowers the limit
        sensitive.feed(g.room(2.f, -85.f));
        auto heard = sensitive.feed(g.blow(2.f, -50.f));
        CHECK(sensitive.firstActive(heard) <= 30); ++checks;
    }

    // Non-finite samples are silence; null input and empty pushes change nothing.
    {
        Generator g{48000};
        Run run(48000);
        run.feed(g.room(2.f, -62.f));
        Clip broken = g.blow(1.f, -20.f);
        for (size_t i = 0; i < broken.samples.size(); i += 97)
            broken.samples[i] = (i / 97) % 2 ? std::numeric_limits<float>::quiet_NaN()
                                             : std::numeric_limits<float>::infinity();
        auto r = run.feed(broken);
        CHECK(run.firstActive(r) <= 30); ++checks;
        const bool before = run.detector.active();
        CHECK(run.detector.push(nullptr, 1000) == before); ++checks;
        CHECK(run.detector.push(broken.samples.data(), 0) == before); ++checks;
        run.detector.reset();
        CHECK(!run.detector.active()); ++checks;
        cemuvr::MicBlowDetector odd(3, std::numeric_limits<float>::quiet_NaN());
        std::vector<float> zeros(100000, 0.f);
        CHECK(!odd.push(zeros.data(), zeros.size())); ++checks;
    }
    std::cout << "Microphone blow detector: " << checks
              << " checks passed (16/44.1/48 kHz; blow, gusts, long blow; speech, whistle, hum,"
                 " hiss, whisper, knocks, fan, faint input, broken samples)\n";
}
