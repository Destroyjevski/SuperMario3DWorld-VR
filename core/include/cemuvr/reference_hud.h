#pragma once
#include "cemuvr/reference_pair.h"
#include "cemuvr/hud_marker.h"
namespace cemuvr {
// The two protocol clears bracket ONLY the main HUD draw. Save the native
// color image losslessly, draw HUD over transparent black, then restore world.
struct ReferenceHud {
    ReferencePairImages world,hud;
    VkImage active{}; unsigned activeIndex{}; bool ready[4]{},title[4]{};
    uint64_t captures{};
    ReferenceHud(){world.preserveFormat=true;}
    void record(const VulkanCtx& vk,VkCommandBuffer cb,VkImage source,VkImageLayout layout,
                const VkImageCreateInfo& ci,const HudMarker& tag) {
        const unsigned index=tag.slot*2+tag.eye;
        if(!tag.end) {
            const bool accumulated=ready[index];
            if(!accumulated)title[index]=false;
            ready[index]=false;
            if(active || !(ci.usage&VK_IMAGE_USAGE_TRANSFER_DST_BIT))return;
            world.record(vk,cb,source,layout,ci,{0,0,1});
            if(world.failed || !world.images[0].written)return;
            active=source;activeIndex=index;
            if(accumulated && !hud.failed) {
                // Continue the same eye's transparent UI canvas across groups.
                // Blit allows the captured RGBA8 canvas to return to RGB10A2.
                VkImageMemoryBarrier b[2]{};
                for(auto& v:b){v.sType=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;v.srcQueueFamilyIndex=v.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED;v.subresourceRange={VK_IMAGE_ASPECT_COLOR_BIT,0,1,0,1};}
                b[0].image=hud.images[index].handle;b[0].oldLayout=VK_IMAGE_LAYOUT_GENERAL;b[0].newLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
                b[0].srcAccessMask=VK_ACCESS_MEMORY_WRITE_BIT;b[0].dstAccessMask=VK_ACCESS_TRANSFER_READ_BIT;
                b[1].image=source;b[1].oldLayout=layout;b[1].newLayout=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
                b[1].srcAccessMask=VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT;b[1].dstAccessMask=VK_ACCESS_TRANSFER_WRITE_BIT;
                vk.fn.CmdPipelineBarrier(cb,VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,VK_PIPELINE_STAGE_TRANSFER_BIT,0,0,nullptr,0,nullptr,2,b);
                VkImageBlit area{};area.srcSubresource=area.dstSubresource={VK_IMAGE_ASPECT_COLOR_BIT,0,0,1};
                area.srcOffsets[1]=area.dstOffsets[1]={int32_t(ci.extent.width),int32_t(ci.extent.height),1};
                auto blit=(PFN_vkCmdBlitImage)vk.fn.GetDeviceProcAddr(vk.device,"vkCmdBlitImage");
                blit(cb,b[0].image,b[0].newLayout,source,b[1].newLayout,1,&area,VK_FILTER_NEAREST);
                b[0].oldLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;b[0].newLayout=VK_IMAGE_LAYOUT_GENERAL;
                b[0].srcAccessMask=VK_ACCESS_TRANSFER_READ_BIT;b[0].dstAccessMask=VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT;
                b[1].oldLayout=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;b[1].newLayout=layout;
                b[1].srcAccessMask=VK_ACCESS_TRANSFER_WRITE_BIT;b[1].dstAccessMask=VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT;
                vk.fn.CmdPipelineBarrier(cb,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,0,0,nullptr,0,nullptr,2,b);
                return;
            }
            VkClearColorValue zero{};VkImageSubresourceRange range{VK_IMAGE_ASPECT_COLOR_BIT,0,1,0,1};
            auto clear=(PFN_vkCmdClearColorImage)vk.fn.GetDeviceProcAddr(vk.device,"vkCmdClearColorImage");
            clear(cb,source,layout,&zero,1,&range);
            return;
        }
        if(active!=source || activeIndex!=index)return;
        title[index]=title[index]||tag.title;
        hud.record(vk,cb,source,layout,ci,{tag.eye,tag.slot,1});
        VkImageMemoryBarrier bars[2]{};
        for(auto& b:bars){b.sType=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;b.srcQueueFamilyIndex=b.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED;b.subresourceRange={VK_IMAGE_ASPECT_COLOR_BIT,0,1,0,1};}
        bars[0].image=world.images[0].handle;bars[0].oldLayout=VK_IMAGE_LAYOUT_GENERAL;bars[0].newLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
        bars[0].srcAccessMask=VK_ACCESS_MEMORY_WRITE_BIT;bars[0].dstAccessMask=VK_ACCESS_TRANSFER_READ_BIT;
        bars[1].image=source;bars[1].oldLayout=layout;bars[1].newLayout=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
        bars[1].srcAccessMask=VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT;bars[1].dstAccessMask=VK_ACCESS_TRANSFER_WRITE_BIT;
        vk.fn.CmdPipelineBarrier(cb,VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,VK_PIPELINE_STAGE_TRANSFER_BIT,0,0,nullptr,0,nullptr,2,bars);
        VkImageCopy copy{};copy.srcSubresource=copy.dstSubresource={VK_IMAGE_ASPECT_COLOR_BIT,0,0,1};copy.extent=ci.extent;
        auto transfer=(PFN_vkCmdCopyImage)vk.fn.GetDeviceProcAddr(vk.device,"vkCmdCopyImage");
        transfer(cb,world.images[0].handle,VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,source,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,1,&copy);
        bars[0].oldLayout=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;bars[0].newLayout=VK_IMAGE_LAYOUT_GENERAL;
        bars[0].srcAccessMask=VK_ACCESS_TRANSFER_READ_BIT;bars[0].dstAccessMask=VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT;
        bars[1].oldLayout=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;bars[1].newLayout=layout;
        bars[1].srcAccessMask=VK_ACCESS_TRANSFER_WRITE_BIT;bars[1].dstAccessMask=VK_ACCESS_MEMORY_READ_BIT|VK_ACCESS_MEMORY_WRITE_BIT;
        vk.fn.CmdPipelineBarrier(cb,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,0,0,nullptr,0,nullptr,2,bars);
        active={};ready[index]=!hud.failed;
        if(++captures<=4 || captures%240==0)CVR_INFO("reference.hud","captured=%llu eye=%u slot=%u size=%ux%u restored=1 title=%d",(unsigned long long)captures,tag.eye,tag.slot,ci.extent.width,ci.extent.height,int(title[index]));
    }
    void destroy(const VulkanCtx& vk){world.destroy(vk);hud.destroy(vk);}
};
}
