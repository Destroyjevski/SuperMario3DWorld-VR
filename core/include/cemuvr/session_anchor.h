#pragma once
#include <openxr/openxr.h>
#include <cmath>

namespace cemuvr {
inline XrQuaternionf anchorMultiply(const XrQuaternionf& a,const XrQuaternionf& b) {
    return {a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y,
            a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x,
            a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w,
            a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z};
}
inline XrVector3f anchorRotate(const XrQuaternionf& q,const XrVector3f& p) {
    const auto r=anchorMultiply(anchorMultiply(q,{p.x,p.y,p.z,0}),{-q.x,-q.y,-q.z,q.w});
    return {r.x,r.y,r.z};
}
inline XrPosef anchorCompose(const XrPosef& a,const XrPosef& b) {
    const auto p=anchorRotate(a.orientation,b.position);
    return {anchorMultiply(a.orientation,b.orientation),
            {p.x+a.position.x,p.y+a.position.y,p.z+a.position.z}};
}
inline XrPosef anchorInverse(const XrPosef& a) {
    const XrQuaternionf q{-a.orientation.x,-a.orientation.y,-a.orientation.z,a.orientation.w};
    return {q,anchorRotate(q,{-a.position.x,-a.position.y,-a.position.z})};
}
inline bool anchorPoseValid(const XrPosef& p) {
    const auto& q=p.orientation;
    const float n=q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w;
    return std::isfinite(n) && std::abs(n-1.f)<.01f &&
           std::isfinite(p.position.x) && std::isfinite(p.position.y) && std::isfinite(p.position.z);
}

// One physical origin for the whole session. Menu/render transitions and lost
// tracking never call reset(). Runtime origin changes are compensated in space.
//
// 2026-09-21 (user): the origin must not depend on where the head is or looks
// at start. latch() therefore stores a ROOM-FIXED pose: the reference space's
// origin and forward direction, level; only the height is the first tracked
// head height (seated or standing). World, menu surface and HUD all derive
// from it, so they share one place in the room, whatever the start pose was.
class SessionAnchor {
    bool m_ready{};
    XrPosef m_pose{{0,0,0,1},{0,0,0}};
public:
    bool ready() const { return m_ready; }
    const XrPosef& pose() const { return m_pose; }
    void reset() { m_ready=false; m_pose={{0,0,0,1},{0,0,0}}; }
    bool latch(const XrPosef& head,bool tracked,unsigned trackedFrames) {
        if(m_ready || !tracked || trackedFrames<30 || !anchorPoseValid(head))return false;
        m_pose={{0,0,0,1},{0,head.position.y,0}};m_ready=true;return true;
    }
    XrPosef surface(float distance) const {
        const auto& q=m_pose.orientation;
        const float yaw=std::atan2(2.f*(q.w*q.y+q.x*q.z),1.f-2.f*(q.y*q.y+q.z*q.z));
        return {{0,std::sin(yaw*.5f),0,std::cos(yaw*.5f)},
                {m_pose.position.x-std::sin(yaw)*distance,m_pose.position.y,
                 m_pose.position.z-std::cos(yaw)*distance}};
    }
    XrPosef hud(bool title=true) const {
        const auto& q=m_pose.orientation;
        const float dx=-4.f*(q.x*q.z+q.w*q.y);
        // Title placement is accepted. In-game HUDs use an independently
        // raised plane above the level, still tied only to the session pose.
        const float dy=4.f*(q.w*q.x-q.y*q.z)+(title?.35f:1.20f);
        const float dz=-2.f*(1.f-2.f*(q.x*q.x+q.y*q.y));
        const float yaw=std::atan2(-dx,-dz),pitch=std::atan2(dy,std::sqrt(dx*dx+dz*dz));
        const float sy=std::sin(yaw*.5f),cy=std::cos(yaw*.5f),sp=std::sin(pitch*.5f),cp=std::cos(pitch*.5f);
        return {{cy*sp,sy*cp,-sy*sp,cy*cp},
                {m_pose.position.x+dx,m_pose.position.y+dy,m_pose.position.z+dz}};
    }
};
}
