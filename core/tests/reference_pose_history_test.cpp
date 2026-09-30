#include "cemuvr/reference_pose_history.h"
#include "cemuvr/reference_pair.h"
#include <cstdlib>
#include <iostream>
#include <memory>
#include <limits>

using namespace cemuvr;
#define CHECK(condition) do { if (!(condition)) { std::cerr << "FAIL line " << __LINE__ << ": " #condition "\n"; std::exit(1); } } while (false)

static CemuVR_FrameContext pose(uint64_t n) {
    CemuVR_FrameContext c{};
    c.poseSerial=n; c.presentIndex=n+7; c.predictedDisplayTime=int64_t(n*1000);
    c.eyePose[0].position.x=float(n%1009); c.eyePose[1].position.x=float(n%1013);
    c.eyeFov[0].angleLeft=-.7f; c.eyeFov[1].angleRight=.8f;
    return c;
}
static void matches(const ReferencePoseHistory::Entry* e,uint64_t n) {
    CHECK(e); const auto c=pose(n);
    CHECK(e->context.poseSerial==c.poseSerial);
    CHECK(e->context.presentIndex==c.presentIndex);
    CHECK(e->context.predictedDisplayTime==c.predictedDisplayTime);
    CHECK(e->context.eyePose[0].position.x==c.eyePose[0].position.x);
    CHECK(e->context.eyePose[1].position.x==c.eyePose[1].position.x);
    CHECK(e->context.eyeFov[0].angleLeft==c.eyeFov[0].angleLeft);
    CHECK(e->context.eyeFov[1].angleRight==c.eyeFov[1].angleRight);
}
static void wireTokens() {
    for(uint32_t token=1;token<=65535;++token) {
        for(bool quantized:{false,true}) {
            float values[4]={quantized?47.f/255:.1875f,quantized?207.f/255:.8125f,0,0};
            for(int i=0;i<2;++i) {
                uint32_t byte=(token>>(i?0:8))&255;
                values[i+2]=quantized?float(byte)/255:(byte==255?1.f:(byte+.25f)/255.f);
            }
            uint32_t words[4],decoded{}; std::memcpy(words,values,sizeof(words));
            CHECK(decodeReferencePoseToken(words,decoded)); CHECK(decoded==token);
        }
    }
    float menu[4]={.21875f,.8125f,0,0}; uint32_t words[4],token{};
    std::memcpy(words,menu,sizeof(words)); CHECK(decodeReferencePoseToken(words,token));
    CHECK(token==0x10000); CHECK(referenceUnposedSurface(0,0,true));
    CHECK(!referenceUnposedSurface(0,1,true));
}
static void boundaries() {
    auto h=std::make_unique<ReferencePoseHistory>();
    CHECK(!h->bind(1)); CHECK(!h->bind(0)); CHECK(!h->bind(0x10000));
    auto old=h->publish(pose(1));
    CHECK(h->bind(1)==old.publication);
    for(uint64_t i=2;i<=2048;++i) h->publish(pose(i));
    matches(h->find(old.publication,1),1); // Oldest retained entry.
    h->publish(pose(2049)); CHECK(!h->find(old.publication,1)); CHECK(!h->bind(1));
    for(uint64_t i=2050;i<=65535;++i) h->publish(pose(i));
    const uint64_t last=h->bind(65535),penultimate=h->bind(65534);
    auto next=h->publish(pose(65536));
    CHECK(next.wrapped && next.token==1 && next.publication==65536);
    matches(h->find(last,65535),65535); // Preserve in-flight previous-cycle eyes.
    matches(h->find(penultimate,65534),65534);
    matches(h->pair(last,last,65535,65535),65535);
    matches(h->find(next.publication,1),65536);
    CHECK(!h->find(old.publication,1)); // Same wire token, old publication rejected.
    CHECK(!h->pair(old.publication,next.publication,1,1));
    CHECK(!h->pair(next.publication,next.publication,1,2));
    CHECK(!h->pair(0,0,1,1)); CHECK(!h->pair(next.publication,next.publication,0x10000,0x10000));
    CHECK(!h->bind(2)); // A future token cannot select an entry from the old cycle.
    for(uint64_t i=65537;i<=3*65535+1;++i) h->publish(pose(i));
    CHECK(!h->find(next.publication,1));
    matches(h->find(h->bind(1),1),3*65535+1);

    auto strict=std::make_unique<ReferencePoseHistory>();
    for(uint64_t i=1;i<=65535;++i) CHECK(strict->publish(pose(i),true).token==i);
    CHECK(!strict->publish(pose(65536),true).token);
    matches(strict->find(strict->bind(65535),65535),65535);
    CHECK(strict->publish(pose(65536),false).wrapped); // Opt-in policy only.

    CHECK(nextReferencePoseSequence(131070)==131072); // Wire wrap does not reset seqlock.
    uint32_t seq=0xfffffffau;
    for(uint32_t expected:{0xfffffffcu,0xfffffffeu,2u,4u}) {
        seq=nextReferencePoseSequence(seq); CHECK(seq==expected); CHECK(seq && !(seq&1));
    }
}
static void session(unsigned hz) {
    auto h=std::make_unique<ReferencePoseHistory>();
    const uint64_t frames=uint64_t(hz)*60*60*24;
    uint64_t wraps=0;
    ReferencePoseHistory::Published pending[4]{};
    for(uint64_t i=1;i<=frames;++i) {
        // Context serials also cross 32 bits; the host must retain all bits.
        const uint64_t serial=0xffffff00ULL+i;
        auto p=h->publish(pose(serial)); CHECK(p.token && p.token<=65535);
        CHECK(p.publication==i); wraps+=p.wrapped;
        CHECK(h->bind(p.token)==p.publication);
        auto delayed=pending[i%4];
        if(delayed.token) matches(h->pair(delayed.publication,delayed.publication,delayed.token,delayed.token),serial-4);
        pending[i%4]=p;
    }
    CHECK(wraps==(frames-1)/65535);
    std::cout<<hz<<" Hz: 24 simulated hours, "<<frames<<" publications, "<<wraps<<" wraps, correct pose/frame binding\n";
}
static VKAPI_ATTR void VKAPI_CALL barrier(VkCommandBuffer,VkPipelineStageFlags,VkPipelineStageFlags,VkDependencyFlags,
    uint32_t,const VkMemoryBarrier*,uint32_t,const VkBufferMemoryBarrier*,uint32_t,const VkImageMemoryBarrier*) {}
static VKAPI_ATTR void VKAPI_CALL blit(VkCommandBuffer,VkImage,VkImageLayout,VkImage,VkImageLayout,uint32_t,const VkImageBlit*,VkFilter) {}
static VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL proc(VkDevice,const char*) { return reinterpret_cast<PFN_vkVoidFunction>(blit); }
static void transport() {
    // Exercise actual slot recording without allocating resources or launching a game.
    ReferencePairImages p; p.width=p.height=16; p.sourceFormat=VK_FORMAT_R8G8B8A8_UNORM;
    VulkanCtx vk{}; vk.fn.CmdPipelineBarrier=barrier; vk.fn.GetDeviceProcAddr=proc;
    VkImageCreateInfo ci{}; ci.imageType=VK_IMAGE_TYPE_2D; ci.extent={16,16,1};
    ci.format=p.sourceFormat; ci.arrayLayers=1; ci.samples=VK_SAMPLE_COUNT_1_BIT; ci.usage=VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
    for(unsigned slot=0;slot<2;++slot) {
        const uint64_t id=65535+slot; const uint32_t token=slot?1:65535;
        p.record(vk,{}, {},VK_IMAGE_LAYOUT_GENERAL,ci,{0,slot,1},token,id);
        CHECK(p.order.latest()==(slot?0:-1));
        p.record(vk,{}, {},VK_IMAGE_LAYOUT_GENERAL,ci,{1,slot,1},token,id);
        CHECK(p.order.latest()==int(slot));
        for(unsigned eye=0;eye<2;++eye) { CHECK(p.poseTokens[slot*2+eye]==token); CHECK(p.posePublications[slot*2+eye]==id); }
    }
    p.order.serial=0xffffffffULL;
    p.record(vk,{}, {},VK_IMAGE_LAYOUT_GENERAL,ci,{0,0,1},2,65537);
    p.record(vk,{}, {},VK_IMAGE_LAYOUT_GENERAL,ci,{1,0,1},2,65537);
    CHECK(p.order.complete[0]==0x100000000ULL); CHECK(p.order.latest()==0);
    p.order.consumed[0]=p.order.complete[0]; p.order.consumed[1]=p.order.complete[1]; CHECK(p.order.latest()==-1);
}
int main() {
    wireTokens(); boundaries(); transport();
    for(unsigned hz:{60u,90u,120u,144u}) session(hz);
    std::cout<<"PASS: token encoding, stale/future/mixed identities, history eviction, strict diagnostics, seqlock and transport boundaries\n";
}
