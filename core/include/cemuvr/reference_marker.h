#pragma once
#include <cstdint>
#include <cstring>
#include <cmath>
namespace cemuvr {
// GPU-command protocol. RR09 also observed Cemu's UNORM8 truncation of all RGB channels.
struct ReferenceMarker { uint32_t eye{}, slot{}, target{}; };
// Missing pose on BOTH records may be shown as a monoscopic surface, never
// promoted to valid stereo. Mixed/stale/mismatched pose tokens remain rejected.
inline bool referenceUnposedSurface(uint32_t a,uint32_t b,bool enabled) {
    return enabled && a==0 && b==0;
}
inline bool decodeReferencePoseToken(const uint32_t words[4],uint32_t& token) {
    float v[4];std::memcpy(v,words,16);
    // Explicit menu metadata, outside the 16-bit pose-token domain.
    if((v[0]==.21875f && v[1]==.8125f) ||
       (std::abs(v[0]-55.f/255)<.000001f && std::abs(v[1]-207.f/255)<.000001f)) {
        token=0x10000;return true;
    }
    // Accept exact protocol floats and Cemu's observed floor-to-UNORM8 path.
    if(!((v[0]==.1875f && v[1]==.8125f) ||
         (std::abs(v[0]-47.f/255)<.000001f && std::abs(v[1]-207.f/255)<.000001f)))return false;
    uint32_t b[2];
    for(int i=0;i<2;++i) {
        float x=v[i+2];if(!std::isfinite(x) || x<0 || x>1)return false;
        b[i]=uint32_t(std::floor(x*255+.001f));
    }
    token=b[0]*256+b[1];return true;
}
inline bool decodeReferenceMarker(const uint32_t words[4], ReferenceMarker& out) {
    const bool quantized=words[0]==0x3ce0e0e1 || words[0]==0x3df8f8f9;
    const uint32_t a=quantized?0x3df8f8f9:0x3dfcd6ea;
    const uint32_t b=quantized?0x3f7bfbfc:0x3f7cd6ea;
    if (words[1]==a && words[2]==b) out.eye=0;
    else if (words[1]==b && words[2]==a) out.eye=1;
    else return false;
    if (words[0]==(quantized?0x3ce0e0e1u:0x3d000000u)) out.target=1; // 1/32 or 7/255
    else if (words[0]==(quantized?0x3df8f8f9u:0x3e000000u)) out.target=4; // 4/32 or 31/255
    else return false;
    if (words[3]==0) out.slot=0;
    else if (words[3]==0x3f800000) out.slot=1;
    else return false;
    return true;
}
}
