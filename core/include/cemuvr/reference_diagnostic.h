#pragma once
#include "profile.h"
#include <cmath>
#include <sstream>
#include <string>
namespace cemuvr {
struct ReferenceDiagnosticCommand { unsigned serial{};std::string preset; };
inline bool parseReferenceDiagnostic(const std::string& text,ReferenceDiagnosticCommand& out) {
    std::istringstream s(text);ReferenceDiagnosticCommand c;std::string extra;
    if(!(s>>c.serial>>c.preset) || c.serial<1 || c.serial>32 || (s>>extra))return false;
    if(c.preset!="CENTER" && c.preset!="YAW_LEFT" && c.preset!="YAW_RIGHT" &&
       c.preset!="LEAN_LEFT" && c.preset!="LEAN_RIGHT" && c.preset!="FORWARD")return false;
    out=c;return true;
}
// Synthetic diagnostic pose, NOT a claim about the runtime's located head pose.
// Rotate both eyes rigidly around the neutral head centre; preserve their IPD.
inline void applyReferenceDiagnostic(const CemuVR_FrameContext& neutral,const std::string& preset,CemuVR_FrameContext& fc) {
    const float yaw=preset=="YAW_LEFT"?.174532925f:preset=="YAW_RIGHT"?-.174532925f:0;
    const float x=preset=="LEAN_LEFT"?-.1f:preset=="LEAN_RIGHT"?.1f:0;
    const float z=preset=="FORWARD"?-.1f:0;
    const float c=std::cos(yaw),s=std::sin(yaw),h=std::sin(yaw/2),w=std::cos(yaw/2);
    auto move=[&](const CemuVR_Pose& p) {
        CemuVR_Pose r=p;auto centre=neutral.headPose.position;
        const float dx=p.position.x-centre.x,dz=p.position.z-centre.z;
        r.position.x=centre.x+c*dx+s*dz+x;r.position.z=centre.z-s*dx+c*dz+z;
        const auto q=p.orientation;
        r.orientation={w*q.x+h*q.z,w*q.y+h*q.w,w*q.z-h*q.x,w*q.w-h*q.y};return r;
    };
    fc.headPose=move(neutral.headPose);
    for(int e=0;e<2;++e)fc.eyePose[e]=move(neutral.eyePose[e]);
}
inline bool parseReferenceCapture(const std::string& text,unsigned& id) {
    std::istringstream in(text);std::string token,extra;unsigned n=1;
    if(!(in>>token) || token!="capture-level-v1")return false;
    in>>std::ws;
    if(!in.eof() && !(in>>n))return false;
    if((in>>extra) || n<1 || n>8)return false;
    id=n;return true;
}
}
