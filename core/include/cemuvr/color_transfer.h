#pragma once
#include <vulkan/vulkan.h>

namespace cemuvr {
// Preserve the existing UNORM submission's numeric RGB values when OpenXR
// only offers an sRGB destination. Alpha is linear in both formats.
inline bool needsSrgbEncoding(VkFormat source, VkFormat destination) {
    return (source == VK_FORMAT_R8G8B8A8_UNORM && destination == VK_FORMAT_R8G8B8A8_SRGB) ||
           (source == VK_FORMAT_B8G8R8A8_UNORM && destination == VK_FORMAT_B8G8R8A8_SRGB);
}

inline void recordColorTransfer(PFN_vkCmdCopyImage copy, PFN_vkCmdBlitImage blit,
                               VkCommandBuffer cb, VkImage source, VkImage destination,
                               const VkImageCopy& region, bool encodeSrgb) {
    if (!encodeSrgb) {
        copy(cb, source, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
             destination, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);
        return;
    }
    // Equal extents and nearest sampling: no resize or blur. Vulkan encodes
    // RGB on writes to sRGB, leaving alpha unchanged. The compositor decodes
    // it back to the values used by the original UNORM path.
    VkImageBlit r{};
    r.srcSubresource = region.srcSubresource;
    r.dstSubresource = region.dstSubresource;
    r.srcOffsets[0] = region.srcOffset;
    r.dstOffsets[0] = region.dstOffset;
    r.srcOffsets[1] = {region.srcOffset.x + int32_t(region.extent.width),
                       region.srcOffset.y + int32_t(region.extent.height),
                       region.srcOffset.z + int32_t(region.extent.depth)};
    r.dstOffsets[1] = {region.dstOffset.x + int32_t(region.extent.width),
                       region.dstOffset.y + int32_t(region.extent.height),
                       region.dstOffset.z + int32_t(region.extent.depth)};
    blit(cb, source, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
         destination, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &r, VK_FILTER_NEAREST);
}
} // namespace cemuvr
