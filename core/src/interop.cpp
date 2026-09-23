// CemuVR -- Vulkan/D3D11-Interop, Implementierung.
#include "cemuvr/interop.h"
#include "cemuvr/diag.h"

#include <cstring>

namespace cemuvr {

// ---------------------------------------------------------------------------
// Namen und Formate
// ---------------------------------------------------------------------------

const char* vkResultName(VkResult r) {
    switch (r) {
        case VK_SUCCESS:                       return "VK_SUCCESS";
        case VK_NOT_READY:                     return "VK_NOT_READY";
        case VK_TIMEOUT:                       return "VK_TIMEOUT";
        case VK_ERROR_OUT_OF_HOST_MEMORY:      return "OUT_OF_HOST_MEMORY";
        case VK_ERROR_OUT_OF_DEVICE_MEMORY:    return "OUT_OF_DEVICE_MEMORY";
        case VK_ERROR_INITIALIZATION_FAILED:   return "INITIALIZATION_FAILED";
        case VK_ERROR_DEVICE_LOST:             return "DEVICE_LOST";
        case VK_ERROR_EXTENSION_NOT_PRESENT:   return "EXTENSION_NOT_PRESENT";
        case VK_ERROR_FEATURE_NOT_PRESENT:     return "FEATURE_NOT_PRESENT";
        case VK_ERROR_FORMAT_NOT_SUPPORTED:    return "FORMAT_NOT_SUPPORTED";
        case VK_ERROR_INVALID_EXTERNAL_HANDLE: return "INVALID_EXTERNAL_HANDLE";
        case VK_ERROR_OUT_OF_DATE_KHR:         return "OUT_OF_DATE_KHR";
        case VK_SUBOPTIMAL_KHR:                return "SUBOPTIMAL_KHR";
        default: {
            static thread_local char b[32];
            std::snprintf(b, sizeof(b), "VkResult(%d)", (int)r);
            return b;
        }
    }
}

const char* vkFormatName(VkFormat f) {
    switch (f) {
        case VK_FORMAT_R8G8B8A8_UNORM: return "R8G8B8A8_UNORM";
        case VK_FORMAT_R8G8B8A8_SRGB:  return "R8G8B8A8_SRGB";
        case VK_FORMAT_B8G8R8A8_UNORM: return "B8G8R8A8_UNORM";
        case VK_FORMAT_B8G8R8A8_SRGB:  return "B8G8R8A8_SRGB";
        case VK_FORMAT_A2B10G10R10_UNORM_PACK32: return "A2B10G10R10_UNORM";
        case VK_FORMAT_R16G16B16A16_SFLOAT:      return "R16G16B16A16_SFLOAT";
        case VK_FORMAT_UNDEFINED:      return "UNDEFINED";
        default: {
            static thread_local char b[32];
            std::snprintf(b, sizeof(b), "VkFormat(%d)", (int)f);
            return b;
        }
    }
}

// Nur bitgleiche Entsprechungen. Wo keine existiert, wird nicht geraten.
VkFormat dxgiToVk(DXGI_FORMAT f) {
    switch (f) {
        case DXGI_FORMAT_R8G8B8A8_UNORM:      return VK_FORMAT_R8G8B8A8_UNORM;
        case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB: return VK_FORMAT_R8G8B8A8_SRGB;
        case DXGI_FORMAT_B8G8R8A8_UNORM:      return VK_FORMAT_B8G8R8A8_UNORM;
        case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB: return VK_FORMAT_B8G8R8A8_SRGB;
        default: return VK_FORMAT_UNDEFINED;
    }
}

DXGI_FORMAT vkToDxgi(VkFormat f) {
    switch (f) {
        case VK_FORMAT_R8G8B8A8_UNORM: return DXGI_FORMAT_R8G8B8A8_UNORM;
        case VK_FORMAT_R8G8B8A8_SRGB:  return DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
        case VK_FORMAT_B8G8R8A8_UNORM: return DXGI_FORMAT_B8G8R8A8_UNORM;
        case VK_FORMAT_B8G8R8A8_SRGB:  return DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
        default: return DXGI_FORMAT_UNKNOWN;
    }
}

bool VkFns::complete() const {
    return CreateImage && DestroyImage && GetImageMemoryRequirements && AllocateMemory &&
           QueueWaitIdle &&
           FreeMemory && BindImageMemory && CreateCommandPool && DestroyCommandPool &&
           AllocateCommandBuffers && BeginCommandBuffer && EndCommandBuffer &&
           ResetCommandBuffer && CmdPipelineBarrier && CmdCopyImage && QueueSubmit &&
           CreateFence && DestroyFence && WaitForFences && ResetFences &&
           CreateSemaphore && DestroySemaphore && GetPhysicalDeviceMemoryProperties;
}

// ---------------------------------------------------------------------------
// Lebenszyklus
// ---------------------------------------------------------------------------

EyeInterop::~EyeInterop() {
    destroyD3D11Side();
}

bool EyeInterop::createD3D11Side(ID3D11Device* d3d, uint32_t w, uint32_t h, DXGI_FORMAT fmt) {
    if (!d3d || !w || !h) return false;
    m_w = w; m_h = h; m_fmt = fmt;

    D3D11_TEXTURE2D_DESC td{};
    td.Width = w;
    td.Height = h;
    td.MipLevels = 1;
    td.ArraySize = 1;
    td.Format = fmt;
    td.SampleDesc.Count = 1;
    td.Usage = D3D11_USAGE_DEFAULT;
    td.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
    td.MiscFlags = D3D11_RESOURCE_MISC_SHARED_NTHANDLE | D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX;

    for (int e = 0; e < 2; ++e) {
        HRESULT hr = d3d->CreateTexture2D(&td, nullptr, &m_eye[e].tex);
        if (FAILED(hr)) {
            CVR_ERR("interop.d3d11", "op=CreateTexture2D eye=%d hr=0x%08lx w=%u h=%u fmt=%u",
                    e, (unsigned long)hr, w, h, (unsigned)fmt);
            return false;
        }
        hr = m_eye[e].tex->QueryInterface(__uuidof(IDXGIKeyedMutex), (void**)&m_eye[e].mutex);
        if (FAILED(hr)) {
            CVR_ERR("interop.d3d11", "op=QueryKeyedMutex eye=%d hr=0x%08lx", e, (unsigned long)hr);
            return false;
        }
        IDXGIResource1* res = nullptr;
        hr = m_eye[e].tex->QueryInterface(__uuidof(IDXGIResource1), (void**)&res);
        if (SUCCEEDED(hr)) {
            hr = res->CreateSharedHandle(nullptr,
                                         DXGI_SHARED_RESOURCE_READ | DXGI_SHARED_RESOURCE_WRITE,
                                         nullptr, &m_eye[e].shared);
            res->Release();
        }
        if (FAILED(hr) || !m_eye[e].shared) {
            CVR_ERR("interop.d3d11", "op=CreateSharedHandle eye=%d hr=0x%08lx", e, (unsigned long)hr);
            return false;
        }
        CVR_INFO("interop.d3d11", "eye=%d tex=ok handle=%p w=%u h=%u fmt=%u",
                 e, m_eye[e].shared, w, h, (unsigned)fmt);
    }
    return true;
}

bool EyeInterop::importIntoVulkan(const VulkanCtx& vk, VkFormat vkFormat) {
    if (!vk.device || !vk.fn.complete()) {
        CVR_ERR("interop.vk", "reason=incomplete_dispatch");
        return false;
    }
    m_vkFmt = vkFormat;
    m_keyedMutex = vk.keyedMutex;

    VkPhysicalDeviceMemoryProperties mp{};
    vk.fn.GetPhysicalDeviceMemoryProperties(vk.phys, &mp);

    for (int e = 0; e < 2; ++e) {
        VkExternalMemoryImageCreateInfo emi{VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO};
        emi.handleTypes = m_handleType;

        VkImageCreateInfo ici{VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO};
        ici.pNext = &emi;
        ici.imageType = VK_IMAGE_TYPE_2D;
        ici.format = vkFormat;
        ici.extent = {m_w, m_h, 1};
        ici.mipLevels = 1;
        ici.arrayLayers = 1;
        ici.samples = VK_SAMPLE_COUNT_1_BIT;
        ici.tiling = VK_IMAGE_TILING_OPTIMAL;
        ici.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
                    VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_SAMPLED_BIT;
        ici.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
        ici.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;

        VkResult r = vk.fn.CreateImage(vk.device, &ici, nullptr, &m_eye[e].image);
        if (r != VK_SUCCESS) {
            CVR_ERR("interop.vk", "op=vkCreateImage eye=%d result=%s format=%s",
                    e, vkResultName(r), vkFormatName(vkFormat));
            return false;
        }

        VkMemoryRequirements mr{};
        vk.fn.GetImageMemoryRequirements(vk.device, m_eye[e].image, &mr);

        uint32_t typeBits = mr.memoryTypeBits;
        if (vk.fn.GetMemoryWin32HandleProperties) {
            VkMemoryWin32HandlePropertiesKHR hp{
                VK_STRUCTURE_TYPE_MEMORY_WIN32_HANDLE_PROPERTIES_KHR};
            const VkResult hr = vk.fn.GetMemoryWin32HandleProperties(
                vk.device, m_handleType, m_eye[e].shared, &hp);
            if (hr == VK_SUCCESS && hp.memoryTypeBits) typeBits &= hp.memoryTypeBits;
            CVR_TRACE("interop.vk", "eye=%d handleProps=%s bits=0x%08x", e, vkResultName(hr), typeBits);
        }

        uint32_t typeIndex = UINT32_MAX;
        for (uint32_t i = 0; i < mp.memoryTypeCount; ++i)
            if ((typeBits & (1u << i)) &&
                (mp.memoryTypes[i].propertyFlags & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)) {
                typeIndex = i; break;
            }
        if (typeIndex == UINT32_MAX)
            for (uint32_t i = 0; i < mp.memoryTypeCount; ++i)
                if (typeBits & (1u << i)) { typeIndex = i; break; }
        if (typeIndex == UINT32_MAX) {
            CVR_ERR("interop.vk", "eye=%d reason=no_memory_type bits=0x%08x", e, typeBits);
            return false;
        }

        // Dedizierte Zuteilung ist bei D3D11-Handles Pflicht: die Sonde meldete
        // dedicatedOnly=1 fuer alle geprueften Formate.
        VkMemoryDedicatedAllocateInfo ded{VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO};
        ded.image = m_eye[e].image;
        VkImportMemoryWin32HandleInfoKHR imp{
            VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_KHR};
        imp.pNext = &ded;
        imp.handleType = m_handleType;
        imp.handle = m_eye[e].shared;
        VkMemoryAllocateInfo mai{VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};
        mai.pNext = &imp;
        mai.allocationSize = mr.size;
        mai.memoryTypeIndex = typeIndex;

        r = vk.fn.AllocateMemory(vk.device, &mai, nullptr, &m_eye[e].memory);
        if (r != VK_SUCCESS) {
            CVR_ERR("interop.vk", "op=vkAllocateMemory eye=%d result=%s size=%llu type=%u",
                    e, vkResultName(r), (unsigned long long)mr.size, typeIndex);
            return false;
        }
        r = vk.fn.BindImageMemory(vk.device, m_eye[e].image, m_eye[e].memory, 0);
        if (r != VK_SUCCESS) {
            CVR_ERR("interop.vk", "op=vkBindImageMemory eye=%d result=%s", e, vkResultName(r));
            return false;
        }
        CVR_INFO("interop.vk", "eye=%d imported=1 format=%s size=%llu memType=%u",
                 e, vkFormatName(vkFormat), (unsigned long long)mr.size, typeIndex);
    }

    // Kommandopool und Ring
    VkCommandPoolCreateInfo pci{VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
    pci.queueFamilyIndex = vk.queueFamily;
    pci.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    VkResult r = vk.fn.CreateCommandPool(vk.device, &pci, nullptr, &m_pool);
    if (r != VK_SUCCESS) {
        CVR_ERR("interop.vk", "op=vkCreateCommandPool result=%s family=%u",
                vkResultName(r), vk.queueFamily);
        return false;
    }
    for (uint32_t i = 0; i < kRing; ++i) {
        VkCommandBufferAllocateInfo cbai{VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
        cbai.commandPool = m_pool;
        cbai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
        cbai.commandBufferCount = 1;
        r = vk.fn.AllocateCommandBuffers(vk.device, &cbai, &m_slot[i].cb);
        if (r != VK_SUCCESS) {
            CVR_ERR("interop.vk", "op=vkAllocateCommandBuffers slot=%u result=%s", i, vkResultName(r));
            return false;
        }
        VkFenceCreateInfo fci{VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
        vk.fn.CreateFence(vk.device, &fci, nullptr, &m_slot[i].fence);
        VkSemaphoreCreateInfo sci{VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO};
        vk.fn.CreateSemaphore(vk.device, &sci, nullptr, &m_slot[i].sem);
    }

    m_vulkanReady = true;
    CVR_INFO("interop.vk", "ready=1 ring=%u keyedMutex=%d queueFamily=%u",
             kRing, (int)m_keyedMutex, vk.queueFamily);
    return true;
}

// ---------------------------------------------------------------------------
// Die Kopie
// ---------------------------------------------------------------------------

bool EyeInterop::copyFromSwapchainImage(const VulkanCtx& vk,
                                        int eye,
                                        VkImage srcImage,
                                        uint32_t srcW, uint32_t srcH,
                                        const VkSemaphore* waitSems, uint32_t waitCount,
                                        VkSemaphore* signalSemOut,
                                        int32_t srcOffsetX, int32_t srcOffsetY, VkImageLayout sourceLayout) {
    if (!m_vulkanReady || eye < 0 || eye > 1 || srcImage == VK_NULL_HANDLE) return false;

    // Keine Skalierung. vkCmdCopyImage kann nicht skalieren, und es soll auch
    // nicht -- abweichende Groesse ist ein Fehler, kein Anlass zum Umrechnen.
    if (srcW != m_w || srcH != m_h) {
        CVR_ERR("copy.mismatch", "reason=size srcW=%u srcH=%u dstW=%u dstH=%u",
                srcW, srcH, m_w, m_h);
        return false;
    }

    Slot& s = m_slot[m_nextSlot];
    m_nextSlot = (m_nextSlot + 1) % kRing;

    if (s.inFlight) {
        const VkResult w = vk.fn.WaitForFences(vk.device, 1, &s.fence, VK_TRUE,
                                               1000ull * 1000 * 1000);
        if (w != VK_SUCCESS) {
            CVR_ERR("copy.sync", "op=WaitForFences result=%s", vkResultName(w));
            return false;
        }
        s.inFlight = false;
    }
    vk.fn.ResetFences(vk.device, 1, &s.fence);
    vk.fn.ResetCommandBuffer(s.cb, 0);

    VkCommandBufferBeginInfo bi{VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    VkResult r = vk.fn.BeginCommandBuffer(s.cb, &bi);
    if (r != VK_SUCCESS) {
        CVR_ERR("copy.record", "op=BeginCommandBuffer result=%s", vkResultName(r));
        return false;
    }

    const VkImageSubresourceRange range{VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1};

    // Barriere 1: Cemus Swapchainbild von PRESENT_SRC nach TRANSFER_SRC.
    // Cemu hat es unmittelbar vor vkQueuePresentKHR nach PRESENT_SRC_KHR
    // ueberfuehrt -- das ist die einzige Layoutannahme dieser Einheit, und sie
    // ist von der Vulkan-Spezifikation erzwungen, nicht geraten.
    VkImageMemoryBarrier pre[2]{};
    pre[0] = VkImageMemoryBarrier{VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};
    pre[0].srcAccessMask = VK_ACCESS_MEMORY_READ_BIT | VK_ACCESS_MEMORY_WRITE_BIT;
    pre[0].dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
    pre[0].oldLayout = sourceLayout;
    pre[0].newLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
    pre[0].srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    pre[0].dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    pre[0].image = srcImage;
    pre[0].subresourceRange = range;

    // Barriere 2: Augenressource nach TRANSFER_DST.
    // Beim ersten Mal aus UNDEFINED (Inhalt darf verworfen werden), danach aus
    // GENERAL -- das Layout, in dem D3D11 sie zuletzt gesehen hat.
    pre[1] = VkImageMemoryBarrier{VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};
    pre[1].srcAccessMask = 0;
    pre[1].dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    pre[1].oldLayout = m_eye[eye].everWritten ? VK_IMAGE_LAYOUT_GENERAL
                                              : VK_IMAGE_LAYOUT_UNDEFINED;
    pre[1].newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    pre[1].srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    pre[1].dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    pre[1].image = m_eye[eye].image;
    pre[1].subresourceRange = range;

    vk.fn.CmdPipelineBarrier(s.cb,
                             VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
                             VK_PIPELINE_STAGE_TRANSFER_BIT,
                             0, 0, nullptr, 0, nullptr, 2, pre);

    // Ein vom Spielprofil gewuenschter Quellversatz verschiebt den kopierten
    // AUSSCHNITT. Er ist ganzzahlig in Texeln, deshalb bleibt es eine reine
    // Texelkopie: es wird nichts neu abgetastet und nichts erfunden. Der Betrag
    // wird auf ein Viertel der Kantenlaenge begrenzt.
    const int32_t maxX = (int32_t)(m_w / 4), maxY = (int32_t)(m_h / 4);
    int32_t dx = srcOffsetX, dy = srcOffsetY;
    if (dx >  maxX) dx =  maxX;
    if (dx < -maxX) dx = -maxX;
    if (dy >  maxY) dy =  maxY;
    if (dy < -maxY) dy = -maxY;

    VkImageCopy region{};
    region.srcSubresource = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 0, 1};
    region.dstSubresource = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 0, 1};
    region.srcOffset = { dx > 0 ?  dx : 0, dy > 0 ?  dy : 0, 0 };
    region.dstOffset = { dx < 0 ? -dx : 0, dy < 0 ? -dy : 0, 0 };
    region.extent = { m_w - (uint32_t)(dx < 0 ? -dx : dx),
                      m_h - (uint32_t)(dy < 0 ? -dy : dy), 1 };

    if (dx || dy)
        CVR_TRACE("copy.region", "eye=%d dxIn=%d dyIn=%d dx=%d dy=%d "
                                 "src=%d,%d dst=%d,%d extent=%ux%u",
                  eye, srcOffsetX, srcOffsetY, dx, dy,
                  region.srcOffset.x, region.srcOffset.y,
                  region.dstOffset.x, region.dstOffset.y,
                  region.extent.width, region.extent.height);
    vk.fn.CmdCopyImage(s.cb,
                       srcImage,          VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                       m_eye[eye].image,  VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                       1, &region);

    // Zurueck: Swapchainbild nach PRESENT_SRC, Augenressource nach GENERAL
    // (das Layout, in dem D3D11 sie lesen darf).
    VkImageMemoryBarrier post[2]{};
    post[0] = pre[0];
    post[0].srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
    post[0].dstAccessMask = VK_ACCESS_MEMORY_READ_BIT;
    post[0].oldLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
    post[0].newLayout = sourceLayout;

    post[1] = pre[1];
    post[1].srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    post[1].dstAccessMask = VK_ACCESS_MEMORY_READ_BIT;
    post[1].oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    post[1].newLayout = VK_IMAGE_LAYOUT_GENERAL;

    vk.fn.CmdPipelineBarrier(s.cb,
                             VK_PIPELINE_STAGE_TRANSFER_BIT,
                             VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
                             0, 0, nullptr, 0, nullptr, 2, post);

    r = vk.fn.EndCommandBuffer(s.cb);
    if (r != VK_SUCCESS) {
        CVR_ERR("copy.record", "op=EndCommandBuffer result=%s", vkResultName(r));
        return false;
    }

    // Auf Cemus Renderabschluss warten. Genau die Semaphoren, die Cemu selbst
    // dem Praesentieren vorangestellt haette.
    std::vector<VkPipelineStageFlags> stages(waitCount, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT);

    const uint64_t acquireKey = 0, releaseKey = 1;
    const uint32_t keyTimeout = 1000;
    VkWin32KeyedMutexAcquireReleaseInfoKHR km{
        VK_STRUCTURE_TYPE_WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_KHR};
    km.acquireCount = 1;
    km.pAcquireSyncs = &m_eye[eye].memory;
    km.pAcquireKeys = &acquireKey;
    km.pAcquireTimeouts = &keyTimeout;
    km.releaseCount = 1;
    km.pReleaseSyncs = &m_eye[eye].memory;
    km.pReleaseKeys = &releaseKey;

    VkSubmitInfo si{VK_STRUCTURE_TYPE_SUBMIT_INFO};
    if (m_keyedMutex) si.pNext = &km;
    si.waitSemaphoreCount = waitCount;
    si.pWaitSemaphores = waitCount ? waitSems : nullptr;
    si.pWaitDstStageMask = waitCount ? stages.data() : nullptr;
    si.commandBufferCount = 1;
    si.pCommandBuffers = &s.cb;
    si.signalSemaphoreCount = 1;
    si.pSignalSemaphores = &s.sem;

    r = vk.fn.QueueSubmit(vk.queue, 1, &si, s.fence);
    if (r != VK_SUCCESS) {
        CVR_ERR("copy.submit", "op=vkQueueSubmit result=%s eye=%d waits=%u",
                vkResultName(r), eye, waitCount);
        return false;
    }
    s.inFlight = true;
    m_eye[eye].everWritten = true;
    if (signalSemOut) *signalSemOut = s.sem;
    return true;
}

// ---------------------------------------------------------------------------
// Uebergabe an D3D11
// ---------------------------------------------------------------------------

bool EyeInterop::acquireForD3D11(int eye, uint32_t timeoutMs, double* waitedMsOut) {
    if (eye < 0 || eye > 1) return false;
    if (!m_keyedMutex || !m_eye[eye].mutex) return true;   // ohne Mutex: nichts zu tun

    LARGE_INTEGER f{}, a{}, b{};
    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&a);

    const HRESULT hr = m_eye[eye].mutex->AcquireSync(1, timeoutMs);

    QueryPerformanceCounter(&b);
    if (waitedMsOut && f.QuadPart)
        *waitedMsOut = 1000.0 * double(b.QuadPart - a.QuadPart) / double(f.QuadPart);

    if (FAILED(hr) || hr == (HRESULT)WAIT_TIMEOUT) {
        CVR_ERR("interop.acquire", "eye=%d hr=0x%08lx timeoutMs=%u", eye, (unsigned long)hr, timeoutMs);
        return false;
    }
    m_eye[eye].d3dHolds = true;
    return true;
}

void EyeInterop::releaseFromD3D11(int eye) {
    if (eye < 0 || eye > 1) return;
    if (!m_keyedMutex || !m_eye[eye].mutex || !m_eye[eye].d3dHolds) return;
    m_eye[eye].mutex->ReleaseSync(0);      // Schluessel 0 holt sich Vulkan als naechstes
    m_eye[eye].d3dHolds = false;
}

// ---------------------------------------------------------------------------
// Abbau
// ---------------------------------------------------------------------------

void EyeInterop::destroyVulkanSide(const VulkanCtx& vk) {
    if (!vk.device || !m_vulkanReady) return;

    // Die Signalsemaphoren dieser Einheit wurden an vkQueuePresentKHR
    // weitergereicht. Ein Fence belegt nur, dass die KOPIE fertig ist -- nicht,
    // dass die Praesentation die Semaphore verbraucht hat. Eine noch
    // ausstehende Semaphore zu zerstoeren ist nach der Vulkan-Spezifikation
    // unzulaessig und aeussert sich als Absturz beim Beenden.
    //
    // Deshalb hier EINMALIG auf die Queue warten. Das ist kein globales
    // vkDeviceWaitIdle und liegt ausserhalb des Bildwegs: es geschieht genau
    // einmal, beim Abbau.
    if (vk.fn.QueueWaitIdle && vk.queue) {
        const VkResult r = vk.fn.QueueWaitIdle(vk.queue);
        if (r != VK_SUCCESS)
            CVR_WARN("interop.vk", "op=vkQueueWaitIdle result=%s", vkResultName(r));
    }

    for (uint32_t i = 0; i < kRing; ++i) {
        if (m_slot[i].inFlight && m_slot[i].fence)
            vk.fn.WaitForFences(vk.device, 1, &m_slot[i].fence, VK_TRUE, 1000ull * 1000 * 1000);
        if (m_slot[i].fence) vk.fn.DestroyFence(vk.device, m_slot[i].fence, nullptr);
        if (m_slot[i].sem)   vk.fn.DestroySemaphore(vk.device, m_slot[i].sem, nullptr);
        m_slot[i] = Slot{};
    }
    if (m_pool) { vk.fn.DestroyCommandPool(vk.device, m_pool, nullptr); m_pool = VK_NULL_HANDLE; }
    for (int e = 0; e < 2; ++e) {
        if (m_eye[e].image)  { vk.fn.DestroyImage(vk.device, m_eye[e].image, nullptr); m_eye[e].image = VK_NULL_HANDLE; }
        if (m_eye[e].memory) { vk.fn.FreeMemory(vk.device, m_eye[e].memory, nullptr);  m_eye[e].memory = VK_NULL_HANDLE; }
    }
    m_vulkanReady = false;
    CVR_INFO("interop.vk", "destroyed=1");
}

void EyeInterop::destroyD3D11Side() {
    for (int e = 0; e < 2; ++e) {
        if (m_eye[e].d3dHolds && m_eye[e].mutex) { m_eye[e].mutex->ReleaseSync(0); m_eye[e].d3dHolds = false; }
        if (m_eye[e].mutex)  { m_eye[e].mutex->Release(); m_eye[e].mutex = nullptr; }
        if (m_eye[e].tex)    { m_eye[e].tex->Release();   m_eye[e].tex = nullptr; }
        if (m_eye[e].shared) { CloseHandle(m_eye[e].shared); m_eye[e].shared = nullptr; }
    }
}

} // namespace cemuvr
