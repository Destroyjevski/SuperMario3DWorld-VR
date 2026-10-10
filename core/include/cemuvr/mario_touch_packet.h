#pragma once
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
namespace cemuvr {
struct MarioTouchPoint {uint32_t kind{};std::array<std::array<float,3>,2> eyes{};};
using MarioTouchPoints=std::array<MarioTouchPoint,9>;
// Host-endian packet words: two logical eyes, 40 words each. Full pose sequence
// and calc epoch must match, never just the wrapping 16-bit transport token.
inline bool decodeMarioTouch(const uint32_t* raw,uint32_t sequence,float units,MarioTouchPoints& out) {
    out={};
    if(!sequence || (sequence&1) || raw[0]!=sequence || raw[40]!=sequence ||
       !raw[2] || raw[2]!=raw[42] || raw[1]>1 || raw[1]!=raw[41] ||
       !std::isfinite(units) || units<=0)return false;
    const float scale=units*(raw[1]?.1f:1.f);
    for(unsigned i=0;i<9;++i) {
        const unsigned at=4+i*4,kind=raw[at];
        if(kind!=raw[40+at] || kind>3 || (i && kind && kind!=3) || (!i && kind==3))return false;
        if(!kind)continue;
        bool visible=true;
        for(unsigned e=0;e<2;++e)for(unsigned c=0;c<3;++c) {
            float v;const auto bits=raw[(1-e)*40+at+1+c];std::memcpy(&v,&bits,4);v/=scale;
            if(!std::isfinite(v) || std::abs(v)>1000.f)return false;
            if(c==2 && v>=-.02f)visible=false;
            out[i].eyes[e][c]=v;
        }
        if(visible)out[i].kind=kind;
    }
    return true;
}
}
