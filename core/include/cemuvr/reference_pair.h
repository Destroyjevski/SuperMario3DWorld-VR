#pragma once
#include "cemuvr/interop.h"
#include "cemuvr/reference_marker.h"
#include "cemuvr/diag.h"
namespace cemuvr {
// Serial marker order, not slot parity alone, identifies complete generations.
struct ReferencePairOrder {
    uint64_t serial{}, complete[2]{}, consumed[2]{}, rejected{};
    int pending{-1};
    void observe(unsigned eye,unsigned slot) {
        if(eye>1 || slot>1) {pending=-1;++rejected;return;}
        if(!eye) {if(pending>=0) ++rejected; pending=int(slot);complete[slot]=0;}
        else if(pending==int(slot)) {complete[slot]=++serial;pending=-1;}
        else {complete[slot]=0;pending=-1;++rejected;}
    }
    int latest() const {
        int result=-1;
        for(int i=0;i<2;++i) if(complete[i]>consumed[i] && (result<0 || complete[i]>complete[result])) result=i;
        return result;
    }
};
struct ReferencePairImages {
    struct Image {VkImage handle{};VkDeviceMemory memory{};bool written{};} images[4];
    uint32_t width{},height{};VkFormat format{},sourceFormat{};
    ReferencePairOrder order;
    uint32_t poseTokens[4]{};
    bool failed{};
    bool preserveFormat{};
    bool initialize(const VulkanCtx& vk,const VkImageCreateInfo& source) {
        if(width) return width==source.extent.width && height==source.extent.height && sourceFormat==source.format;
        if(source.format!=VK_FORMAT_A2B10G10R10_UNORM_PACK32 && source.format!=VK_FORMAT_R8G8B8A8_UNORM)return false;
        if(!vk.fn.GetPhysicalDeviceFormatProperties)return false;
        VkFormatProperties srcProps{},dstProps{};
        vk.fn.GetPhysicalDeviceFormatProperties(vk.phys,source.format,&srcProps);
        vk.fn.GetPhysicalDeviceFormatProperties(vk.phys,VK_FORMAT_R8G8B8A8_UNORM,&dstProps);
        if(!(srcProps.optimalTilingFeatures&VK_FORMAT_FEATURE_BLIT_SRC_BIT) || !(dstProps.optimalTilingFeatures&VK_FORMAT_FEATURE_BLIT_DST_BIT))return false;
        if(!vk.fn.GetDeviceProcAddr(vk.device,"vkCmdBlitImage"))return false;
        VkImageCreateInfo ci{VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO};
        ci.imageType=VK_IMAGE_TYPE_2D;ci.format=preserveFormat?source.format:VK_FORMAT_R8G8B8A8_UNORM;ci.extent=source.extent;
        ci.mipLevels=1;ci.arrayLayers=1;ci.samples=VK_SAMPLE_COUNT_1_BIT;
        ci.tiling=VK_IMAGE_TILING_OPTIMAL;ci.usage=VK_IMAGE_USAGE_TRANSFER_DST_BIT|VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
        ci.sharingMode=VK_SHARING_MODE_EXCLUSIVE;
        VkPhysicalDeviceMemoryProperties props{};vk.fn.GetPhysicalDeviceMemoryProperties(vk.phys,&props);
        for(auto& im:images) {
            if(vk.fn.CreateImage(vk.device,&ci,nullptr,&im.handle)!=VK_SUCCESS)return false;
            VkMemoryRequirements req{};vk.fn.GetImageMemoryRequirements(vk.device,im.handle,&req);
            uint32_t type=UINT32_MAX;
            for(uint32_t i=0;i<props.memoryTypeCount;++i) if((req.memoryTypeBits&(1u<<i)) && (props.memoryTypes[i].propertyFlags&VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)) {type=i;break;}
            if(type==UINT32_MAX)return false;
            VkMemoryAllocateInfo ai{VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};ai.allocationSize=req.size;ai.memoryTypeIndex=type;
            if(vk.fn.AllocateMemory(vk.device,&ai,nullptr,&im.memory)!=VK_SUCCESS)return false;
            if(vk.fn.BindImageMemory(vk.device,im.handle,im.memory,0)!=VK_SUCCESS)return false;
        }
        width=ci.extent.width;height=ci.extent.height;format=ci.format;sourceFormat=source.format;
        CVR_INFO("reference.pair","allocated=4 size=%ux%u format=%u",width,height,format);
        return true;
    }
    void record(const VulkanCtx& vk,VkCommandBuffer cb,VkImage source,VkImageLayout layout,
                const VkImageCreateInfo& ci,const ReferenceMarker& marker,uint32_t poseToken=0) {
        if(failed || marker.target!=1 || marker.eye>1 || marker.slot>1)return;
        if(ci.imageType!=VK_IMAGE_TYPE_2D || ci.arrayLayers!=1 || ci.samples!=VK_SAMPLE_COUNT_1_BIT ||
           ci.extent.depth!=1 || !ci.extent.width || !ci.extent.height || ci.extent.width>8192 || ci.extent.height>8192 ||
           !(ci.usage&VK_IMAGE_USAGE_TRANSFER_SRC_BIT)) {failed=true;return;}
        if(!initialize(vk,ci)) {failed=true;CVR_ERR("reference.pair","allocation_or_extent_failed=1");return;}
        auto& im=images[marker.slot*2+marker.eye];
        VkImageMemoryBarrier bars[2]{};
        for(auto& b:bars) {b.sType=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;b.srcQueueFamilyIndex=b.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED;b.subresourceRange={VK_IMAGE_ASPECT_COLOR_BIT,0,1,0,1};}
        bars[0].image=source;bars[0].oldLayout=layout;bars[0].newLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
        bars[0].srcAccessMask=VK_ACCESS_MEMORY_WRITE_BIT;bars[0].dstAccessMask=VK_ACCESS_TRANSFER_READ_BIT;
        bars[1].image=im.handle;bars[1].oldLayout=im.written?VK_IMAGE_LAYOUT_GENERAL:VK_IMAGE_LAYOUT_UNDEFINED;
        bars[1].newLayout=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
        bars[1].srcAccessMask=im.written?(VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT):0;bars[1].dstAccessMask=VK_ACCESS_TRANSFER_WRITE_BIT;
        vk.fn.CmdPipelineBarrier(cb,VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,VK_PIPELINE_STAGE_TRANSFER_BIT,0,0,nullptr,0,nullptr,2,bars);
        // Numerical UNORM conversion only; same extent, nearest sampling, no sRGB transfer.
        VkImageBlit region{};region.srcSubresource=region.dstSubresource={VK_IMAGE_ASPECT_COLOR_BIT,0,0,1};
        region.srcOffsets[1]=region.dstOffsets[1]={int32_t(width),int32_t(height),1};
        auto blit=(PFN_vkCmdBlitImage)vk.fn.GetDeviceProcAddr(vk.device,"vkCmdBlitImage");
        blit(cb,source,VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,im.handle,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,1,&region,VK_FILTER_NEAREST);
        bars[0].oldLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;bars[0].newLayout=layout;
        bars[0].srcAccessMask=VK_ACCESS_TRANSFER_READ_BIT;bars[0].dstAccessMask=VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT;
        bars[1].oldLayout=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;bars[1].newLayout=VK_IMAGE_LAYOUT_GENERAL;
        bars[1].srcAccessMask=VK_ACCESS_TRANSFER_WRITE_BIT;bars[1].dstAccessMask=VK_ACCESS_MEMORY_READ_BIT;
        vk.fn.CmdPipelineBarrier(cb,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,0,0,nullptr,0,nullptr,2,bars);
        im.written=true;poseTokens[marker.slot*2+marker.eye]=poseToken;order.observe(marker.eye,marker.slot);
    }
    void destroy(const VulkanCtx& vk) {
        if(vk.fn.QueueWaitIdle && vk.queue)vk.fn.QueueWaitIdle(vk.queue);
        for(auto& im:images) {if(im.handle)vk.fn.DestroyImage(vk.device,im.handle,nullptr);if(im.memory)vk.fn.FreeMemory(vk.device,im.memory,nullptr);im={};}
    }
};
}
