#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

namespace cemuvr {
inline constexpr float touchPreviewAngularSize = 0.075f;
// A visual-only touch ripple with contrast on both sky and dark surfaces. Generated in the layer; no game texture
// or touch event is required. Pixels are straight-alpha RGBA.
inline std::vector<uint8_t> makeTouchPreview(uint32_t size) {
    if(size<16 || size>1024)return {};
    std::vector<uint8_t> pixels(size*size*4);
    const auto band=[](float radius,float centre,float width) {
        const float t=(std::max)(0.f,1.f-std::abs(radius-centre)/width);
        return t*t*(3.f-2.f*t);
    };
    for(uint32_t y=0;y<size;++y)for(uint32_t x=0;x<size;++x) {
        const float dx=(2.f*x+1.f)/size-1.f,dy=(2.f*y+1.f)/size-1.f;
        const float radius=std::sqrt(dx*dx+dy*dy);
        // The old narrow half-transparent bands vanished after headset
        // minification. A dark blue rim surrounds the bright cyan stroke.
        const float rim=band(radius,0.69f,0.145f);
        const float stroke=band(radius,0.69f,0.080f);
        const float inner=band(radius,0.44f,0.050f);
        const float alpha=(std::min)(1.f,0.96f*rim+0.40f*inner);
        const float light=(std::max)(stroke,inner);
        const auto at=(y*size+x)*4;
        const auto a=uint8_t(alpha*255.f+0.5f);
        pixels[at]=a?uint8_t(8.f+64.f*light):0;
        pixels[at+1]=a?uint8_t(48.f+170.f*light):0;
        pixels[at+2]=a?uint8_t(144.f+111.f*light):0;
        pixels[at+3]=a;
    }
    return pixels;
}
}
