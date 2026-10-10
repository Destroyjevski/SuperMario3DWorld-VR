#include "cemuvr/mario_touch_packet.h"
#include "cemuvr/reference_pose_history.h"
#include <iostream>
#include <limits>
#include <cstdlib>
#include <memory>
using namespace cemuvr;
#define CHECK(c) do {if(!(c)){std::cerr<<"FAIL "<<__LINE__<<"\n";std::exit(1);}}while(false)
uint32_t bits(float f){uint32_t b;std::memcpy(&b,&f,4);return b;}
int main(){
    uint32_t raw[80]{};MarioTouchPoints points{};
    for(uint32_t seq:{2u,131068u,131070u,131072u,0xfffffffeu})for(unsigned fp:{0u,1u}) {
        const float scale=1500.f*(fp?.1f:1.f);
        for(unsigned e=0;e<2;++e){auto* p=raw+e*40;p[0]=seq;p[1]=fp;p[2]=100;
            for(unsigned i=0;i<9;++i){const unsigned at=4+i*4;p[at]=i?3:1;p[at+1]=bits((e?.03f:-.03f)*scale);p[at+2]=bits(.2f*scale);p[at+3]=bits(-2.f*scale);}}
        CHECK(decodeMarioTouch(raw,seq,1500.f,points));CHECK(points[0].kind==1);CHECK(points[8].kind==3);
        CHECK(std::abs(points[0].eyes[0][0]-.03f)<.00001f);CHECK(std::abs(points[0].eyes[1][0]+.03f)<.00001f);
        CHECK(std::abs(points[0].eyes[0][2]+2.f)<.00001f);
        CHECK(!decodeMarioTouch(raw,seq==2?4:seq-2,1500.f,points));
        raw[40]=seq-2;CHECK(!decodeMarioTouch(raw,seq,1500.f,points));raw[40]=seq;
        raw[42]=99;CHECK(!decodeMarioTouch(raw,seq,1500.f,points));raw[42]=100;
        raw[41]=1-fp;CHECK(!decodeMarioTouch(raw,seq,1500.f,points));raw[41]=fp;
        raw[44]=2;CHECK(!decodeMarioTouch(raw,seq,1500.f,points));raw[44]=1;
        raw[5]=bits(std::numeric_limits<float>::quiet_NaN());CHECK(!decodeMarioTouch(raw,seq,1500.f,points));raw[5]=0;
        raw[7]=bits(1);CHECK(decodeMarioTouch(raw,seq,1500.f,points));CHECK(points[0].kind==0);CHECK(points[1].kind==3);
    }
    CHECK(!decodeMarioTouch(raw,0,1500.f,points));CHECK(!decodeMarioTouch(raw,3,1500.f,points));
    CHECK(!decodeMarioTouch(raw,2,0,points));
    // The mailbox identity is retained through the 16-bit wire-token wrap.
    auto history=std::make_unique<ReferencePoseHistory>();auto& h=*history;CemuVR_FrameContext context{};
    for(uint32_t n=1;n<131080;++n){auto p=h.publish(context,false,n*2);auto* entry=h.find(p.publication,p.token);CHECK(entry);CHECK(entry->mailboxSequence==n*2);}
    std::cout<<"Touch packet, stereo mapping, finite bounds, first-person scale and pose wrap checks passed\n";
}
