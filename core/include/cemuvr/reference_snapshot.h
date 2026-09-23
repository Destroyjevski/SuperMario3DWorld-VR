#pragma once
#include "cemuvr/interop.h"
#include "cemuvr/reference_marker.h"
#include "cemuvr/diag.h"
#include "cemuvr/reference_diagnostic.h"
#include <fstream>
#include <cstdlib>
#include <string>

namespace cemuvr {
// Bounded diagnostic readback, separate from the real-time XR transport.
// Four immutable buffers retain the first observed command of each eye/slot.
struct ReferenceSnapshots {
    struct Shot { VkBuffer buffer{}; VkDeviceMemory memory{}; uint32_t w{},h{},poseToken{}; bool recorded{}; } shots[4];
    bool dumped{}, armed{};
    unsigned armPoll{};
    unsigned captureId{};
    void record(const VulkanCtx& vk, VkCommandBuffer cb, VkImage image, VkImageLayout layout,
                const VkImageCreateInfo& info, const ReferenceMarker& marker,uint32_t poseToken=0) {
        const char* dir=std::getenv("CEMUVR_REFERENCE_CAPTURE_DIR");
        if (!armed || !dir || !*dir || marker.target!=1 || marker.eye>1 || marker.slot>1) return;
        auto& s=shots[marker.slot*2+marker.eye];
        if(s.recorded || info.format!=VK_FORMAT_A2B10G10R10_UNORM_PACK32 || info.samples!=VK_SAMPLE_COUNT_1_BIT
            || info.imageType!=VK_IMAGE_TYPE_2D || info.arrayLayers!=1 || info.extent.depth!=1
            || !(info.usage&VK_IMAGE_USAGE_TRANSFER_SRC_BIT) || !info.extent.width || !info.extent.height
            || info.extent.width>8192 || info.extent.height>8192) return;
        if(s.buffer && (s.w!=info.extent.width || s.h!=info.extent.height))return;
        auto create=(PFN_vkCreateBuffer)vk.fn.GetDeviceProcAddr(vk.device,"vkCreateBuffer");
        auto requirements=(PFN_vkGetBufferMemoryRequirements)vk.fn.GetDeviceProcAddr(vk.device,"vkGetBufferMemoryRequirements");
        auto bind=(PFN_vkBindBufferMemory)vk.fn.GetDeviceProcAddr(vk.device,"vkBindBufferMemory");
        auto copy=(PFN_vkCmdCopyImageToBuffer)vk.fn.GetDeviceProcAddr(vk.device,"vkCmdCopyImageToBuffer");
        auto destroy=(PFN_vkDestroyBuffer)vk.fn.GetDeviceProcAddr(vk.device,"vkDestroyBuffer");
        if(!s.buffer) {
        VkBufferCreateInfo bi{VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
        bi.size=VkDeviceSize(info.extent.width)*info.extent.height*4;
        bi.usage=VK_BUFFER_USAGE_TRANSFER_DST_BIT;
        if(create(vk.device,&bi,nullptr,&s.buffer)!=VK_SUCCESS) return;
        VkMemoryRequirements req{}; requirements(vk.device,s.buffer,&req);
        VkPhysicalDeviceMemoryProperties props{}; vk.fn.GetPhysicalDeviceMemoryProperties(vk.phys,&props);
        uint32_t type=UINT32_MAX;
        const auto flags=VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT|VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
        for(uint32_t i=0;i<props.memoryTypeCount;++i)
            if((req.memoryTypeBits&(1u<<i)) && (props.memoryTypes[i].propertyFlags&flags)==flags) {type=i;break;}
        VkMemoryAllocateInfo ai{VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO}; ai.allocationSize=req.size;ai.memoryTypeIndex=type;
        if(type==UINT32_MAX || vk.fn.AllocateMemory(vk.device,&ai,nullptr,&s.memory)!=VK_SUCCESS) {
            destroy(vk.device,s.buffer,nullptr);s={};return;
        }
        if(bind(vk.device,s.buffer,s.memory,0)!=VK_SUCCESS) {
            destroy(vk.device,s.buffer,nullptr);vk.fn.FreeMemory(vk.device,s.memory,nullptr);s={};return;
        }
        }
        VkImageMemoryBarrier ib{VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};
        ib.srcAccessMask=VK_ACCESS_MEMORY_WRITE_BIT;ib.dstAccessMask=VK_ACCESS_TRANSFER_READ_BIT;
        ib.oldLayout=layout;ib.newLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
        ib.srcQueueFamilyIndex=ib.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED;ib.image=image;
        ib.subresourceRange={VK_IMAGE_ASPECT_COLOR_BIT,0,1,0,1};
        vk.fn.CmdPipelineBarrier(cb,VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,VK_PIPELINE_STAGE_TRANSFER_BIT,0,0,nullptr,0,nullptr,1,&ib);
        VkBufferImageCopy region{};region.imageSubresource={VK_IMAGE_ASPECT_COLOR_BIT,0,0,1};region.imageExtent=info.extent;
        copy(cb,image,VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,s.buffer,1,&region);
        ib.srcAccessMask=VK_ACCESS_TRANSFER_READ_BIT;ib.dstAccessMask=VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT;
        ib.oldLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;ib.newLayout=layout;
        VkBufferMemoryBarrier bb{VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER};
        bb.srcAccessMask=VK_ACCESS_TRANSFER_WRITE_BIT;bb.dstAccessMask=VK_ACCESS_HOST_READ_BIT;
        bb.srcQueueFamilyIndex=bb.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED;bb.buffer=s.buffer;bb.size=VK_WHOLE_SIZE;
        vk.fn.CmdPipelineBarrier(cb,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_PIPELINE_STAGE_ALL_COMMANDS_BIT|VK_PIPELINE_STAGE_HOST_BIT,0,0,nullptr,1,&bb,1,&ib);
        s.w=info.extent.width;s.h=info.extent.height;s.poseToken=poseToken;s.recorded=true;
        CVR_INFO("reference.snapshot","recorded eye=%u slot=%u size=%ux%u capture=%u poseToken=%u",marker.eye,marker.slot,s.w,s.h,captureId,poseToken);
    }
    void dump(const VulkanCtx& vk,VkQueue queue) {
        const char* dir=std::getenv("CEMUVR_REFERENCE_CAPTURE_DIR");if(!dir||!*dir)return;
        // Called under the same mutex as record(). No readback or allocations
        // before an explicit request in this run's unique evidence directory.
        if(!armed || dumped) {
            if(armPoll++%60!=0) return;
            std::ifstream request(std::string(dir)+"/capture.request");
            std::string token; std::getline(request,token);unsigned id{};
            if(!parseReferenceCapture(token,id) || id<=captureId) return;
            captureId=id;armed=true;dumped=false;
            for(auto& s:shots)s.recorded=false;
            CVR_INFO("reference.snapshot","armed by explicit level capture request id=%u",id);
            return;
        }
        for(const auto& s:shots) if(!s.recorded) return;
        // One diagnostic stall, after Cemu submitted its rendering for this present.
        if(vk.fn.QueueWaitIdle(queue)!=VK_SUCCESS)return;
        auto map=(PFN_vkMapMemory)vk.fn.GetDeviceProcAddr(vk.device,"vkMapMemory");
        auto unmap=(PFN_vkUnmapMemory)vk.fn.GetDeviceProcAddr(vk.device,"vkUnmapMemory");
        dumped=true;
        for(unsigned i=0;i<4;++i) {
            const auto& s=shots[i];void* data=nullptr;
            if(map(vk.device,s.memory,0,VK_WHOLE_SIZE,0,&data)!=VK_SUCCESS)continue;
            std::string path=std::string(dir)+"/"+(captureId>1?"capture"+std::to_string(captureId)+"-":"")+"slot"+std::to_string(i/2)+"-eye"+std::to_string(i%2)+".a2b10g10r10";
            std::ofstream out(path,std::ios::binary);
            const uint32_t header[]={0x52525331,s.w,s.h,64};
            out.write((const char*)header,sizeof(header));out.write((const char*)data,std::streamsize(s.w)*s.h*4);
            CVR_INFO("reference.snapshot","saved=%d path=%s",int(out.good()),path.c_str());
            std::ofstream meta(path+".json");
            meta<<"{\"capture\":"<<captureId<<",\"slot\":"<<i/2<<",\"eye\":"<<i%2<<",\"poseToken\":"<<s.poseToken<<"}";
            unmap(vk.device,s.memory);
        }
    }
    void destroy(const VulkanCtx& vk) {
        auto destroyBuffer=(PFN_vkDestroyBuffer)vk.fn.GetDeviceProcAddr(vk.device,"vkDestroyBuffer");
        for(auto& s:shots) {if(s.buffer)destroyBuffer(vk.device,s.buffer,nullptr);if(s.memory)vk.fn.FreeMemory(vk.device,s.memory,nullptr);s={};}
    }
};
}
