#pragma once
#include <cstdint>
#include <cstring>
#include <cmath>
namespace cemuvr {
// Loading/title fades can contain one incomplete canvas before TitleLogo is
// drawn. Keep its accepted placement until three complete game HUDs arrive.
class HudPlacement {
    unsigned m_gameFrames{};
public:
    bool selectTitle(bool title) {
        if(title)m_gameFrames=0;
        else if(m_gameFrames<3)++m_gameFrames;
        return m_gameFrames<3;
    }
};
struct HudMarker { unsigned eye{},slot{};bool end{},title{}; };
inline bool decodeHudMarker(const uint32_t* w,HudMarker& out) {
    float v[4];std::memcpy(v,w,16);
    auto eq=[](float x,float y){return x==y || std::abs(x-std::floor(y*255)/255)<.000001f;};
    out.title=eq(v[0],.34375f);
    if((!eq(v[0],.28125f)&&!out.title)||!eq(v[1],.6875f))return false;
    if(eq(v[2],.25f))out.end=false;else if(eq(v[2],.75f))out.end=true;else return false;
    for(unsigned i=0;i<4;++i)if(eq(v[3],float(i)*.25f)){out.eye=i%2;out.slot=i/2;return true;}
    return false;
}
}
