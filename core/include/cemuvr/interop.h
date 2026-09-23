// CemuVR -- Vulkan/D3D11-Interop fuer die Augenressourcen.
//
// WARUM ES DIESE EINHEIT GIBT
//
// Cemus eigene Bilder sind NICHT exportierbar. Belegt zweifach:
//   1. Cemu legt seine Texturen ohne VkExternalMemoryImageCreateInfo an
//      (beobachtet beim untersuchten Cemu-Build).
//   2. Die Zeichenkette VK_KHR_external_memory kommt im gesamten Cemu-Binaerbild
//      nicht vor -- Cemu kennt diese Erweiterungen nicht einmal dem Namen nach.
//
// Ein nicht exportierbares Bild darf nicht als Interop-Ressource behandelt
// werden. Diese Einheit erzeugt deshalb eine EIGENE, ausdruecklich gemeinsame
// Ressource je Auge:
//
//   D3D11 erzeugt die Textur  (SHARED_NTHANDLE | SHARED_KEYEDMUTEX)
//     -> CreateSharedHandle
//       -> Vulkan importiert sie als VkImage (D3D11_TEXTURE-Handle)
//         -> vkCmdCopyImage aus Cemus Swapchainbild hinein
//           -> Keyed Mutex uebergibt an D3D11
//             -> CopyResource in die OpenXR-Swapchain
//
// Richtung beachtet: D3D11 erzeugt, Vulkan importiert. Der umgekehrte Weg
// (Vulkan exportiert, D3D11 oeffnet) ist auf Windows deutlich schlechter
// unterstuetzt.
#pragma once

#define NOMINMAX
#include <windows.h>
#include <d3d11_4.h>
#include <dxgi1_2.h>
#ifndef VK_USE_PLATFORM_WIN32_KHR
#define VK_USE_PLATFORM_WIN32_KHR
#endif
#include <vulkan/vulkan.h>

#include <cstdint>
#include <vector>

namespace cemuvr {

// Die Vulkan-Funktionen, die diese Einheit braucht. Sie kommen aus der
// Layer-Dispatchtabelle, NICHT aus der globalen Ladeschicht -- ein Layer darf
// vulkan-1.lib nicht direkt aufrufen, sonst umgeht er die Kette unter sich.
struct VkFns {
    PFN_vkGetDeviceProcAddr                 GetDeviceProcAddr{nullptr};
    PFN_vkCreateImage                       CreateImage{nullptr};
    PFN_vkDestroyImage                      DestroyImage{nullptr};
    PFN_vkGetImageMemoryRequirements        GetImageMemoryRequirements{nullptr};
    PFN_vkAllocateMemory                    AllocateMemory{nullptr};
    PFN_vkFreeMemory                        FreeMemory{nullptr};
    PFN_vkBindImageMemory                   BindImageMemory{nullptr};
    PFN_vkCreateCommandPool                 CreateCommandPool{nullptr};
    PFN_vkDestroyCommandPool                DestroyCommandPool{nullptr};
    PFN_vkAllocateCommandBuffers            AllocateCommandBuffers{nullptr};
    PFN_vkBeginCommandBuffer                BeginCommandBuffer{nullptr};
    PFN_vkEndCommandBuffer                  EndCommandBuffer{nullptr};
    PFN_vkResetCommandBuffer                ResetCommandBuffer{nullptr};
    PFN_vkCmdPipelineBarrier                CmdPipelineBarrier{nullptr};
    PFN_vkCmdCopyImage                      CmdCopyImage{nullptr};
    PFN_vkQueueSubmit                       QueueSubmit{nullptr};
    PFN_vkQueueWaitIdle                     QueueWaitIdle{nullptr};
    PFN_vkCreateFence                       CreateFence{nullptr};
    PFN_vkDestroyFence                      DestroyFence{nullptr};
    PFN_vkWaitForFences                     WaitForFences{nullptr};
    PFN_vkResetFences                       ResetFences{nullptr};
    PFN_vkCreateSemaphore                   CreateSemaphore{nullptr};
    PFN_vkDestroySemaphore                  DestroySemaphore{nullptr};
    PFN_vkGetMemoryWin32HandlePropertiesKHR GetMemoryWin32HandleProperties{nullptr};
    // Instanzseitig
    PFN_vkGetPhysicalDeviceMemoryProperties GetPhysicalDeviceMemoryProperties{nullptr};
    PFN_vkGetPhysicalDeviceFormatProperties GetPhysicalDeviceFormatProperties{nullptr};
    PFN_vkGetPhysicalDeviceProperties2      GetPhysicalDeviceProperties2{nullptr};

    bool complete() const;
};

struct VulkanCtx {
    VkInstance       instance{VK_NULL_HANDLE};
    VkPhysicalDevice phys{VK_NULL_HANDLE};
    VkDevice         device{VK_NULL_HANDLE};
    VkQueue          queue{VK_NULL_HANDLE};
    uint32_t         queueFamily{UINT32_MAX};
    VkFns            fn{};
    bool             keyedMutex{false};   // VK_KHR_win32_keyed_mutex aktiv
};

// Ein Augenpaar gemeinsamer Texturen samt Kopierwerk.
class EyeInterop {
public:
    ~EyeInterop();

    // Schritt 1: D3D11 legt die gemeinsamen Texturen an.
    // `fmt` MUSS die Kanalreihenfolge von Cemus Swapchain haben -- sonst
    // vertauscht die Bitkopie stillschweigend Rot und Blau.
    bool createD3D11Side(ID3D11Device* d3d, uint32_t w, uint32_t h, DXGI_FORMAT fmt);

    // Schritt 2: Vulkan importiert dieselben Texturen.
    bool importIntoVulkan(const VulkanCtx& vk, VkFormat vkFormat);

    // Schritt 3: je Gastframe -- Cemus Bild in die Augenressource kopieren.
    //
    // Wartet auf `waitSems` (Cemus Renderabschluss, aus VkPresentInfoKHR) und
    // signalisiert `signalSemOut`, das der Aufrufer dann dem echten
    // vkQueuePresentKHR als Wartesemaphore uebergibt. Damit haengt die Kopie
    // zwischen Cemus Rendern und Cemus Praesentation -- ohne CPU-Stillstand und
    // ohne vkDeviceWaitIdle.
    bool copyFromSwapchainImage(const VulkanCtx& vk,
                                int eye,
                                VkImage srcImage,
                                uint32_t srcW, uint32_t srcH,
                                const VkSemaphore* waitSems, uint32_t waitCount,
                                VkSemaphore* signalSemOut,
                                int32_t srcOffsetX = 0, int32_t srcOffsetY = 0,
                                VkImageLayout sourceLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR);

    // Schritt 4: die D3D11-Seite uebernimmt. Blockt, bis die Vulkan-Kopie
    // fertig ist. Rueckgabe false = Zeitueberschreitung, Auge nicht benutzbar.
    bool acquireForD3D11(int eye, uint32_t timeoutMs, double* waitedMsOut);
    void releaseFromD3D11(int eye);

    ID3D11Texture2D* d3dTexture(int eye) const {
        return (eye >= 0 && eye < 2) ? m_eye[eye].tex : nullptr;
    }
    uint32_t width()  const { return m_w; }
    uint32_t height() const { return m_h; }
    DXGI_FORMAT format() const { return m_fmt; }
    bool vulkanReady() const { return m_vulkanReady; }

    void destroyVulkanSide(const VulkanCtx& vk);
    void destroyD3D11Side();

private:
    static const uint32_t kRing = 4;

    struct Eye {
        ID3D11Texture2D* tex{nullptr};
        IDXGIKeyedMutex* mutex{nullptr};
        HANDLE           shared{nullptr};
        VkImage          image{VK_NULL_HANDLE};
        VkDeviceMemory   memory{VK_NULL_HANDLE};
        bool             d3dHolds{false};
        bool             everWritten{false};
    };

    struct Slot {
        VkCommandBuffer cb{VK_NULL_HANDLE};
        VkFence         fence{VK_NULL_HANDLE};
        VkSemaphore     sem{VK_NULL_HANDLE};
        bool            inFlight{false};
    };

    Eye  m_eye[2]{};
    Slot m_slot[kRing]{};
    uint32_t m_nextSlot{0};

    VkCommandPool m_pool{VK_NULL_HANDLE};
    uint32_t m_w{0}, m_h{0};
    DXGI_FORMAT m_fmt{DXGI_FORMAT_UNKNOWN};
    VkFormat m_vkFmt{VK_FORMAT_UNDEFINED};
    VkExternalMemoryHandleTypeFlagBits m_handleType{
        VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT};
    bool m_vulkanReady{false};
    bool m_keyedMutex{false};
};

// DXGI-Format zu Vulkan-Format, nur die Faelle, die hier vorkommen koennen.
// Gibt VK_FORMAT_UNDEFINED zurueck, wenn keine bitgleiche Entsprechung
// existiert -- dann wird NICHT geraten, sondern abgebrochen.
VkFormat dxgiToVk(DXGI_FORMAT f);
DXGI_FORMAT vkToDxgi(VkFormat f);
const char* vkFormatName(VkFormat f);
const char* vkResultName(VkResult r);

} // namespace cemuvr
