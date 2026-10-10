#include "cemuvr/head_blow_gesture.h"
#include <cstdlib>
#include <iostream>
#include <limits>
#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL line " << __LINE__ << "\n"; std::exit(1); } } while (false)
int main() {
    using cemuvr::HeadBlowGesture;
    for (int hz : {60, 90, 120, 144}) {
        HeadBlowGesture g;
        const int64_t start=1000000000, step=1000000000/hz;
        unsigned rising=0;
        for (int i=0; i<hz*10; ++i) {
            bool was=g.active();
            CHECK(g.update(true, .2f*.2f, start+i*step)==(i*step>=150000000));
            rising += !was && g.active();
        }
        CHECK(rising==1);
        auto t=start+hz*10*step;
        CHECK(g.update(true, .32f*.32f, t)); // exit hysteresis
        CHECK(!g.update(true, .36f*.36f, t+step));
        CHECK(!g.update(true, .32f*.32f, t+2*step)); // cannot enter here
        CHECK(!g.update(true, .2f*.2f, t+3*step)); // must dwell again
        CHECK(!g.update(false, .0f, t+4*step));
    }
    for (int loss=0; loss<6; ++loss) {
        HeadBlowGesture g;
        CHECK(!g.update(true, .04f, 1000000000));
        CHECK(g.update(true, .04f, 1200000000));
        switch(loss) {
        case 0: CHECK(!g.update(false, .04f, 1210000000)); break;
        case 1: CHECK(!g.update(true, std::numeric_limits<float>::quiet_NaN(), 1210000000)); break;
        case 2: CHECK(!g.update(true, std::numeric_limits<float>::infinity(), 1210000000)); break;
        case 3: CHECK(!g.update(true, .04f, 1500000001)); break; // gap, require new dwell
        case 4: CHECK(!g.update(true, .04f, 1100000000)); break; // time reset
        case 5: g.reset(); CHECK(!g.active()); break;
        }
        CHECK(!g.active());
    }
    HeadBlowGesture g;
    CHECK(!g.update(true, -.1f, 1));
    CHECK(!g.update(true, .04f, 0));
    CHECK(!g.update(true, .04f, -1));
    const auto t=std::numeric_limits<int64_t>::max()-200000000;
    CHECK(!g.update(true, .04f, t));
    CHECK(g.update(true, .04f, t+150000000));
    // Repeated display times do not count as elapsed hold time.
    g.reset();
    for(int i=0;i<100;++i) CHECK(!g.update(true, .04f, 1000000000));
    std::cout << "Head blow gesture: dwell, hysteresis, tracking/focus loss, time reset, 60/90/120/144 Hz passed\n";
}
