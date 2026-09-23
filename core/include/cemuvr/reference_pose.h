#pragma once
#include "profile.h"
#include <cmath>
namespace cemuvr {
// Complete the scalar representation of the same off-axis frustum.
// angle is the symmetric equivalent vertical FOV, not upAngle-downAngle.
inline bool referenceProjectionScalars(const CemuVR_Fov& f,float out[3]);
inline bool referenceProjection(const CemuVR_Fov& f,float out[8]) {
    const float angles[4]={f.angleLeft,f.angleRight,f.angleDown,f.angleUp};
    for(float x:angles)if(!std::isfinite(x) || std::abs(x)>=1.56f)return false;
    const float l=std::tan(f.angleLeft),r=std::tan(f.angleRight),
                d=std::tan(f.angleDown),u=std::tan(f.angleUp);
    if(r-l<.01f || u-d<.01f)return false;
    out[0]=(u-d)*.5f;out[1]=(r-l)/(u-d);
    out[2]=(r+l)/(2*(r-l));out[3]=(u+d)/(2*(u-d));
    out[4]=2/(r-l);out[5]=(r+l)/(r-l);out[6]=2/(u-d);out[7]=(u+d)/(u-d);
    return true;
}
inline bool referenceProjectionScalars(const CemuVR_Fov& f,float out[3]) {
    float p[8];if(!referenceProjection(f,p))return false;
    const float half=std::atan(p[0]);
    out[0]=2*half;out[1]=std::sin(half);out[2]=std::cos(half);
    return true;
}
// Eye-local inverse transform used to construct relative view matrices.
// No projection or presentation-pose policy is implied by these matrices.
inline bool referenceRotation(const CemuVR_Quat& q, float r[3][3]) {
    const float n=q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w;
    if (!std::isfinite(n) || n<0.5f || n>1.5f) return false;
    const float s=2/n,x=q.x,y=q.y,z=q.z,w=q.w;
    r[0][0]=1-s*(y*y+z*z);r[0][1]=s*(x*y-z*w);r[0][2]=s*(x*z+y*w);
    r[1][0]=s*(x*y+z*w);r[1][1]=1-s*(x*x+z*z);r[1][2]=s*(y*z-x*w);
    r[2][0]=s*(x*z-y*w);r[2][1]=s*(y*z+x*w);r[2][2]=1-s*(x*x+y*y);
    return true;
}
inline bool referencePoseDelta(const CemuVR_Pose& anchor,const CemuVR_Pose& eye,
                               float scale,float out[12]) {
    float a[3][3],e[3][3];
    if (!std::isfinite(scale) || scale<=0 || !referenceRotation(anchor.orientation,a)
        || !referenceRotation(eye.orientation,e)) return false;
    float t[3]={anchor.position.x-eye.position.x,anchor.position.y-eye.position.y,
                anchor.position.z-eye.position.z};
    for(int i=0;i<3;++i) {
        if(!std::isfinite(t[i]))return false;
        for(int j=0;j<3;++j) {
            out[i*4+j]=0;
            for(int k=0;k<3;++k)out[i*4+j]+=e[k][i]*a[k][j];
        }
        out[i*4+3]=0;
        for(int k=0;k<3;++k)out[i*4+3]+=e[k][i]*t[k]*scale;
    }
    for(int i=0;i<12;++i)if(!std::isfinite(out[i]))return false;
    return true;
}
}
