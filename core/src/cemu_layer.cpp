// CemuVR -- Vulkan-Schicht in Cemus Prozess.
//
// Das ist der Prozess-Hook (Punkt 1). Kein Detour, keine Injektion: die Schicht
// wird von der Vulkan-Ladeschicht regulaer in Cemus Prozess geladen, sobald
// CEMUVR_ENABLE=1 gesetzt ist. Damit hat sie
//   - Cemus VkInstance, VkPhysicalDevice, VkDevice, VkQueue,
//   - Cemus Swapchains samt Bildern,
//   - den Zeitpunkt, an dem der Gastframe fertig ist (vkQueuePresentKHR),
//   - und ueber GetModuleHandle Cemus eigenes Objektmodell.
//
// Zwei Eingriffe sind zwingend und werden ausdruecklich vorgenommen:
//   1. vkCreateDevice: die Erweiterungen fuer externen Speicher werden
//      ANGEFUEGT. Cemu kennt sie nicht einmal dem Namen nach -- die
//      Zeichenketten VK_KHR_external_memory* kommen im Binaerbild nicht vor.
//   2. vkCreateSwapchainKHR: VK_IMAGE_USAGE_TRANSFER_SRC_BIT wird ANGEFUEGT,
//      sonst darf aus dem fertigen TV-Bild nicht kopiert werden.
//
// Beides ist genau das, wofuer es Vulkan-Schichten gibt.

#define NOMINMAX
#define VK_USE_PLATFORM_WIN32_KHR
#include <windows.h>
#include <vulkan/vulkan.h>
#include <vulkan/vk_layer.h>

#include "cemuvr/xr_core.h"
#include "cemuvr/interop.h"
#include "cemuvr/reference_hud.h"
#include "cemuvr/cemu_bridge.h"
#include "cemuvr/profile_host.h"
#include "cemuvr/diag.h"

#include <map>
#include <array>
#include <set>
#include <mutex>
#include <vector>
#include <string>
#include <cstring>
#include <cstdlib>
#include "cemuvr/performance.h"
#include "cemuvr/reference_marker.h"
#include "cemuvr/reference_snapshot.h"
#include "cemuvr/reference_pair.h"
#include "cemuvr/reference_pose.h"
#include "cemuvr/reference_diagnostic.h"

using namespace cemuvr;

namespace {

// ---------------------------------------------------------------------------
// Dispatch
// ---------------------------------------------------------------------------

struct InstanceData {
    VkInstance instance{VK_NULL_HANDLE};
    PFN_vkGetInstanceProcAddr gipa{nullptr};
    PFN_vkDestroyInstance                          DestroyInstance{nullptr};
    PFN_vkCreateDevice                             CreateDevice{nullptr};
    PFN_vkEnumerateDeviceExtensionProperties       EnumDeviceExt{nullptr};
    PFN_vkGetPhysicalDeviceMemoryProperties        GetPhysMemProps{nullptr};
    PFN_vkGetPhysicalDeviceProperties2             GetPhysProps2{nullptr};
    PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR  GetSurfCaps{nullptr};
    PFN_vkCreateWin32SurfaceKHR                    CreateWin32Surface{nullptr};
    PFN_vkDestroySurfaceKHR                        DestroySurface{nullptr};
};

struct SwapRec {
    VkSwapchainKHR handle{VK_NULL_HANDLE};
    VkSurfaceKHR   surface{VK_NULL_HANDLE};
    HWND           hwnd{nullptr};
    VkFormat       format{VK_FORMAT_UNDEFINED};
    VkExtent2D     extent{0, 0};
    std::vector<VkImage> images;
    bool           isTv{false};
    bool           usageAdded{false};
};

struct DeviceData {
    VkDevice         device{VK_NULL_HANDLE};
    VkPhysicalDevice phys{VK_NULL_HANDLE};
    InstanceData*    inst{nullptr};
    PFN_vkGetDeviceProcAddr gdpa{nullptr};
    PFN_vkDestroyDevice        DestroyDevice{nullptr};
    PFN_vkGetDeviceQueue       GetDeviceQueue{nullptr};
    PFN_vkCreateSwapchainKHR   CreateSwapchain{nullptr};
    PFN_vkDestroySwapchainKHR  DestroySwapchain{nullptr};
    PFN_vkGetSwapchainImagesKHR GetSwapchainImages{nullptr};
    PFN_vkQueuePresentKHR      QueuePresent{nullptr};
    PFN_vkSetDeviceLoaderData  SetDeviceLoaderData{nullptr};
    PFN_vkCmdClearColorImage   CmdClearColorImage{nullptr};
    PFN_vkCmdClearAttachments  CmdClearAttachments{nullptr};
    PFN_vkCreateImage          CreateImage{nullptr};
    PFN_vkDestroyImage         DestroyImage{nullptr};
    std::map<VkImage, VkImageCreateInfo> referenceImages;
    uint64_t referenceMarkers{0};
    uint64_t referenceClearCalls{0};
    uint64_t referenceAttachmentCalls{0};
    std::set<std::array<uint32_t,4>> referenceClearValues;
    ReferenceSnapshots referenceSnapshots;
    ReferencePairImages referencePairImages;
    ReferenceHud referenceHud;
    EyeInterop hudInterop;
    std::map<VkCommandBuffer,std::pair<VkImage,uint32_t>> referencePoseMarkers;
    VulkanCtx  vk{};
    bool       externalMemoryEnabled{false};
    std::map<VkSwapchainKHR, SwapRec> swapchains;
};

std::mutex g_mtx;
std::map<void*, InstanceData> g_instances;
std::map<void*, DeviceData>   g_devices;
std::map<VkSurfaceKHR, HWND>  g_surfaces;

inline void* dispatchKey(void* obj) { return *(void**)obj; }

InstanceData* instanceOf(void* obj) {
    auto it = g_instances.find(dispatchKey(obj));
    return it == g_instances.end() ? nullptr : &it->second;
}
DeviceData* deviceOf(void* obj) {
    auto it = g_devices.find(dispatchKey(obj));
    return it == g_devices.end() ? nullptr : &it->second;
}

// ---------------------------------------------------------------------------
// Zustand der VR-Anbindung
// ---------------------------------------------------------------------------

struct LayerState {
    bool      enabled{false};
    bool      dualOutput{false};
    bool      streamGuestFrames{false};
    Performance performance;
    uint64_t padPresentCount{0};
    bool      initTried{false};
    bool      ready{false};
    bool      failed{false};
    XrCore    xr;
    EyeInterop interop;
    CemuBridge bridge;
    ProfileHost profiles;
    uint64_t   lastTitleId{0};
    uint64_t   profileSkips{0};
    DeviceData* dev{nullptr};

    uint64_t presentCount{0};
    uint64_t tvPresentCount{0};
    uint64_t copiesOk{0};
    uint64_t copiesFailed{0};
    uint32_t guestFramesInXrFrame{0};
    double   acquireWaitTotalMs{0.0};
    double   acquireWaitMaxMs{0.0};
    uint64_t acquireCount{0};
    uint64_t maxPairs{0};          // 0 = unbegrenzt
    bool     stopped{false};
    uint64_t pairsChecked{0};      // Paare mit beiden Pruefsummen
    uint64_t identicalPairs{0};    // Paare, deren Augen bitgleich sind
    uint64_t firstIdentical{0};
    uint64_t lastIdentical{0};
    bool     tornDown{false};
    // Absichtliche Frameverzoegerung zur Pruefung. 0 = aus.
    uint32_t delayEvery{0};
    uint32_t delayMs{0};
    uint64_t delaysInjected{0};
};

// ABSICHTLICH auf dem Heap und NIE freigegeben.
//
// Liefe dieser Zustand bei Prozessende durch seine Destruktoren, wuerden
// ~EyeInterop und ~XrCore D3D11-, DXGI- und OpenXR-Aufrufe ausloesen, nachdem
// die Ladeschicht diese Bibliotheken moeglicherweise schon abgebaut hat. Das
// aeusserte sich als Absturz mit 0xC0000409 beim Beenden von Cemu -- und zwar
// nur bei manchen Spielen, weil es von der Abbaureihenfolge abhaengt.
//
// Der Speicher wird vom Betriebssystem beim Prozessende zurueckgenommen.
// Der geordnete Abbau geschieht in teardown(), zu einem Zeitpunkt, an dem
// alle Bibliotheken noch stehen.
LayerState& g = *(new LayerState());

bool envFlag(const char* name, bool dflt = false) {
    char buf[64]{};
    DWORD n = GetEnvironmentVariableA(name, buf, sizeof(buf));
    if (!n || n >= sizeof(buf)) return dflt;
    return buf[0] == '1' || buf[0] == 'y' || buf[0] == 'Y' || buf[0] == 't' || buf[0] == 'T';
}
uint64_t envNum(const char* name, uint64_t dflt = 0) {
    char buf[64]{};
    DWORD n = GetEnvironmentVariableA(name, buf, sizeof(buf));
    if (!n || n >= sizeof(buf)) return dflt;
    return std::strtoull(buf, nullptr, 10);
}
std::string envStr(const char* name, const char* dflt) {
    char buf[512]{};
    DWORD n = GetEnvironmentVariableA(name, buf, sizeof(buf));
    return (n && n < sizeof(buf)) ? std::string(buf) : std::string(dflt);
}

// ---------------------------------------------------------------------------
// Punkt 5 -- Welches Fenster ist der Fernseher?
// ---------------------------------------------------------------------------

bool windowLooksLikeGamePad(HWND hwnd) {
    if (!hwnd) return false;
    hwnd = GetAncestor(hwnd, GA_ROOT);
    wchar_t title[256]{};
    GetWindowTextW(hwnd, title, 255);
    std::wstring t(title);
    for (auto& c : t) c = (wchar_t)towlower(c);
    // Cemus zweites Fenster heisst "GamePad View".
    return t.find(L"gamepad") != std::wstring::npos ||
           t.find(L"game pad") != std::wstring::npos;
}

void describeWindow(HWND hwnd, const char* what) {
    if (!hwnd) { CVR_INFO("cemu.window", "%s hwnd=null", what); return; }
    wchar_t title[256]{}, cls[128]{};
    GetWindowTextW(hwnd, title, 255);
    GetClassNameW(hwnd, cls, 127);
    RECT rc{};
    GetClientRect(hwnd, &rc);
    CVR_INFO("cemu.window", "%s hwnd=%p class=\"%ls\" title=\"%ls\" client=%ldx%ld",
             what, (void*)hwnd, cls, title, rc.right - rc.left, rc.bottom - rc.top);
}

// ---------------------------------------------------------------------------
// Formatwahl -- Kanalreihenfolge darf sich NICHT aendern
// ---------------------------------------------------------------------------

bool isBgra(VkFormat f) {
    return f == VK_FORMAT_B8G8R8A8_UNORM || f == VK_FORMAT_B8G8R8A8_SRGB;
}
bool isBgra(DXGI_FORMAT f) {
    return f == DXGI_FORMAT_B8G8R8A8_UNORM || f == DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
}

// Bevorzugtes OpenXR-Format zu Cemus Swapchainformat: gleiche Kanalreihenfolge,
// sRGB-Variante bevorzugt (der Compositor erwartet sRGB, und Cemus fertiges
// Bild traegt bereits gammakodierte Werte -- die Umdeutung ist genau richtig
// und bewegt kein einziges Bit).
DXGI_FORMAT preferredDxgiFor(VkFormat cemuFormat) {
    switch (cemuFormat) {
        case VK_FORMAT_B8G8R8A8_UNORM:
        case VK_FORMAT_B8G8R8A8_SRGB: return DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
        case VK_FORMAT_R8G8B8A8_UNORM:
        case VK_FORMAT_R8G8B8A8_SRGB: return DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
        default: return DXGI_FORMAT_UNKNOWN;
    }
}

// ---------------------------------------------------------------------------
// Verzoegerter Aufbau -- erst wenn Cemus TV-Swapchain bekannt ist
// ---------------------------------------------------------------------------

bool lazyInit(DeviceData* dd, const SwapRec& sc) {
    if (g.initTried) return g.ready;
    g.initTried = true;

    CVR_INFO("init.begin", "tvExtent=%ux%u cemuFormat=%s",
             sc.extent.width, sc.extent.height, vkFormatName(sc.format));

    if (!dd->externalMemoryEnabled) {
        CVR_ERR("init", "reason=external_memory_extensions_not_enabled");
        g.failed = true;
        return false;
    }

    const DXGI_FORMAT want = envFlag("CEMUVR_REFERENCE_PAIR_TRANSPORT",true) && sc.format==VK_FORMAT_R8G8B8A8_UNORM
        ? DXGI_FORMAT_R8G8B8A8_UNORM : preferredDxgiFor(sc.format);
    if (want == DXGI_FORMAT_UNKNOWN) {
        CVR_ERR("init", "reason=unsupported_cemu_format format=%s -- "
                        "es wird NICHT geraten", vkFormatName(sc.format));
        g.failed = true;
        return false;
    }

    XrCoreConfig cfg;
    cfg.appName = "CemuVR";
    cfg.engineName = "Cemu";
    // Augengroesse = Cemus TV-Groesse. Damit bleibt der ganze Weg eine
    // 1:1-Kopie; es wird nirgends skaliert.
    cfg.eyeWidth  = sc.extent.width;
    cfg.eyeHeight = sc.extent.height;
    cfg.preferredFormat = want;
    // Der Bildlagemessung und der Pruefsumme liegt dieselbe Rueckkopie
    // zugrunde. Beides zugleich waere sie doppelt, also hat die Messung
    // Vorrang, sobald sie verlangt wird.
    cfg.bildLageMessen = envFlag("CEMUVR_BILDLAGE", false);
    cfg.checksumEyes = envFlag("CEMUVR_CHECKSUM", false) && !cfg.bildLageMessen;
    cfg.repeatMissingEye = true;
    if(envFlag("CEMUVR_REFERENCE_PAIR_TRANSPORT",true)) cfg.repeatMissingEye=false;
    // Kernvorschlag 0004. Standard: die Pose bleibt beim Bild, Bildweg 0.
    // Damit ist das Verhalten fuer frisch kopierte Augen bitgleich wie
    // vorher; anders wird es nur bei einer Bildwiederholung, und dort war
    // es vorher falsch. CEMUVR_BILDPOSE=0 stellt den alten Weg wieder her
    // -- das ist der Vergleichsschalter.
    cfg.poseBleibtBeimBild = envFlag("CEMUVR_BILDPOSE", true);
    // EINHEIT GASTBILDER. Der alte Name CEMUVR_BILDWEG zaehlte XR-Bilder;
    // wer ihn noch setzt, bekommt eine Warnung statt einer stillen
    // Fehlinterpretation.
    cfg.bildwegGastbilder = (uint32_t)envNum("CEMUVR_BILDWEG_GASTBILDER", 2);
    if (envNum("CEMUVR_BILDWEG", 0))
        CVR_WARN("layer.bildpose",
                 "CEMUVR_BILDWEG ist entfallen -- die Einheit war XR-Bilder. "
                 "Bitte CEMUVR_BILDWEG_GASTBILDER setzen; ein XR-Bild traegt "
                 "zwei Gastbilder.");
    CVR_INFO("layer.bildpose",
             "poseBleibtBeimBild=%d bildwegGastbilder=%u%s",
             (int)cfg.poseBleibtBeimBild, cfg.bildwegGastbilder,
             cfg.bildwegGastbilder
                 ? "  -- ACHTUNG: nur mit gemessenem Weg benutzen"
                 : "  (0 = die Pose beim Kopieren)");
    // Senkrechtes Sichtfeld der Ausgabeebene in Millidegree, damit die
    // vorhandene ganzzahlige Hilfsfunktion reicht. 0 = Sichtfeld der Runtime,
    // also das bisherige Verhalten. Siehe XrCoreConfig::layerFovVerticalDeg.
    cfg.layerFovVerticalDeg =
        (float)envNum("CEMUVR_LAYER_FOV_MILLIDEG", 0) / 1000.0f;
    CVR_INFO("layer.fov", "vertikal=%.3f Grad (%s)",
             cfg.layerFovVerticalDeg,
             cfg.layerFovVerticalDeg > 0.0f ? "symmetrisch, beide Augen gleich"
                                            : "Sichtfeld der Runtime");

    g.streamGuestFrames=envFlag("CEMUVR_XRBILD_JE_GASTBILD",false);
    if(envFlag("CEMUVR_REFERENCE_PAIR_TRANSPORT",true)) g.streamGuestFrames=false;
    if (g.streamGuestFrames && g.dualOutput) {
        CVR_ERR("init", "stream and dual-output modes cannot be combined");
        g.failed=true; return false;
    }
    cfg.streamGuestFrames=g.streamGuestFrames;
    if (g.streamGuestFrames) cfg.repeatMissingEye=true;
    CVR_INFO("delivery.mode", "stream=%d -- one fresh eye per guest; image-pose binding retained",(int)g.streamGuestFrames);
    if (!g.xr.initialise(cfg)) { g.failed = true; return false; }
    if (!g.xr.createSession(nullptr)) { g.failed = true; return false; }

    // Kanalreihenfolge gegenpruefen. Ein stiller Tausch von Rot und Blau ist
    // genau der Fehler, der im Fake-HMD-Belegweg schon einmal aufgetreten ist.
    const DXGI_FORMAT got = g.xr.swapchainFormat();
    if (isBgra(got) != isBgra(sc.format)) {
        CVR_ERR("init", "reason=channel_order_mismatch cemu=%s openxr=%u -- "
                        "abgebrochen statt Rot und Blau zu vertauschen",
                vkFormatName(sc.format), (unsigned)got);
        g.failed = true;
        return false;
    }
    if (g.xr.eyeWidth() != sc.extent.width || g.xr.eyeHeight() != sc.extent.height) {
        CVR_ERR("init", "reason=eye_size_mismatch xr=%ux%u cemu=%ux%u",
                g.xr.eyeWidth(), g.xr.eyeHeight(), sc.extent.width, sc.extent.height);
        g.failed = true;
        return false;
    }

    if (!g.interop.createD3D11Side(g.xr.device(), sc.extent.width, sc.extent.height, got)) {
        g.failed = true; return false;
    }
    const VkFormat vkf = dxgiToVk(got);
    if (vkf == VK_FORMAT_UNDEFINED) {
        CVR_ERR("init", "reason=no_vk_equivalent dxgi=%u", (unsigned)got);
        g.failed = true; return false;
    }
    if (!g.interop.importIntoVulkan(dd->vk, vkf)) { g.failed = true; return false; }

    g.dev = dd;
    g.ready = true;
    g.maxPairs   = envNum("CEMUVR_MAX_PAIRS", 0);
    g.delayEvery = (uint32_t)envNum("CEMUVR_TEST_DELAY_EVERY", 0);
    g.delayMs    = (uint32_t)envNum("CEMUVR_TEST_DELAY_MS", 0);

    CVR_INFO("init.done",
             "ready=1 eye=%ux%u dxgi=%u vk=%s runtime=\"%s\" maxPairs=%llu",
             g.xr.eyeWidth(), g.xr.eyeHeight(), (unsigned)got, vkFormatName(vkf),
             g.xr.runtimeName().c_str(), (unsigned long long)g.maxPairs);
    if (g.delayEvery)
        CVR_INFO("init.done", "testDelay every=%u ms=%u", g.delayEvery, g.delayMs);

    // Punkte 1 bis 6: Titel erkennen, Profil suchen, pruefen, laden, init.
    const uint64_t title = g.bridge.titleId();
    g.lastTitleId = title;
    CVR_INFO("profile.host", "titleId=%016llX dir gesetzt", (unsigned long long)title);
    g.profiles.attachToTitle(title, g.bridge.guestMemoryBase());
    CVR_INFO("profile.host", "status=%s aktiv=%d",
             profileStatusName(g.profiles.status()), (int)g.profiles.active());
    return true;
}

void closeXrFrameIfOpen() {
    if (g.ready && g.xr.frameActive()) {
        g.xr.endFrame();
        g.guestFramesInXrFrame = 0;
    }
}

// `alsoProfile` false: nur die VR-Ausgabe abbauen, das Profil bleibt geladen.
// Cemu legt beim Start einmal eine Swapchain an und ersetzt sie sofort wieder.
// Wuerde das Profil dabei entladen und neu geladen, saehe man je Cemu-Sitzung
// zwei profile_init statt einem -- ohne dass sich am Titel etwas geaendert hat.
void teardown(bool alsoProfile = true) {
    // Das Profil wird ZUERST und UNABHAENGIG vom uebrigen Abbau entladen.
    // Sonst verhindert die Wiedereintrittssperre unten, dass profile_shutdown
    // ueberhaupt noch gerufen wird, wenn die VR-Ausgabe vorher schon einmal
    // ohne Profilabbau beendet wurde. ProfileHost::detach ist mehrfach
    // aufrufbar und tut beim zweiten Mal nichts.
    if (alsoProfile) g.profiles.detach("teardown");

    if (!g.initTried || g.tornDown) return;
    g.tornDown = true;
    if (!alsoProfile)
        CVR_INFO("profile.host", "VR-Ausgabe wird neu aufgebaut, Profil bleibt geladen");
    closeXrFrameIfOpen();
    if (g.dev) g.interop.destroyVulkanSide(g.dev->vk);
    g.interop.destroyD3D11Side();
    g.xr.shutdown();

    const XrCoreStats& s = g.xr.stats();
    CVR_INFO("layer.summary",
             "tvPresents=%llu copiesOk=%llu copiesFailed=%llu pairsOk=%llu pairsBad=%llu "
             "eyesRepeated=%llu overflow=%llu sync=%llu",
             (unsigned long long)g.tvPresentCount, (unsigned long long)g.copiesOk,
             (unsigned long long)g.copiesFailed, (unsigned long long)s.pairsComplete,
             (unsigned long long)s.pairsIncomplete, (unsigned long long)s.eyesRepeated,
             (unsigned long long)s.eyesOverflow, (unsigned long long)s.syncErrors);
    if (g.acquireCount)
        CVR_INFO("layer.summary", "keyedMutexWait avgMs=%.4f maxMs=%.4f n=%llu",
                 g.acquireWaitTotalMs / (double)g.acquireCount, g.acquireWaitMaxMs,
                 (unsigned long long)g.acquireCount);
    CVR_INFO("layer.summary",
             "pairsChecked=%llu identicalPairs=%llu firstIdentical=%llu lastIdentical=%llu",
             (unsigned long long)g.pairsChecked, (unsigned long long)g.identicalPairs,
             (unsigned long long)g.firstIdentical, (unsigned long long)g.lastIdentical);
    CVR_INFO("layer.summary", "swapCounterUsable=%d swapCounterRefuted=%d probes=%u changes=%u",
             (int)g.bridge.swapCounterUsable(), (int)g.bridge.status().swapCounterRefuted,
             g.bridge.status().swapCounterProbes, g.bridge.status().swapCounterChanges);
    const BridgeStatus& b = g.bridge.status();
    CVR_INFO("layer.summary",
             "bridge module=%d exports=%d renderer=%d vtable=%d tvOffset=%d "
             "crossAgree=%llu crossDisagree=%llu",
             (int)b.moduleFound, (int)b.exportsFound, (int)b.rendererFound,
             (int)b.vtableMatches, b.tvSwapchainOffset,
             (unsigned long long)b.crossCheckAgree,
             (unsigned long long)b.crossCheckDisagree);
    CVR_INFO("layer.summary", "delaysInjected=%llu every=%u ms=%u",
             (unsigned long long)g.delaysInjected, g.delayEvery, g.delayMs);
    {
        const ProfileHostStats& ps = g.profiles.stats();
        CVR_INFO("layer.summary",
                 "profile status=%s init=%llu shutdown=%llu frames=%llu (L=%llu R=%llu) "
                 "adjust=%llu applied=%llu skip=%llu notReady=%llu err=%llu faults=%llu "
                 "candidates=%llu rejected=%llu",
                 profileStatusName(g.profiles.status()),
                 (unsigned long long)ps.initCalls, (unsigned long long)ps.shutdownCalls,
                 (unsigned long long)ps.frameCalls, (unsigned long long)ps.frameLeft,
                 (unsigned long long)ps.frameRight, (unsigned long long)ps.adjustCalls,
                 (unsigned long long)ps.adjustsApplied, (unsigned long long)ps.skipped,
                 (unsigned long long)ps.notReady, (unsigned long long)ps.errors,
                 (unsigned long long)ps.faults, (unsigned long long)ps.candidatesSeen,
                 (unsigned long long)ps.candidatesRejected);
    }
    CVR_INFO("dual.output", "probe=%d tv=%llu pad=%llu -- source identity is not stereo proof",
             (int)g.dualOutput, (unsigned long long)g.tvPresentCount,
             (unsigned long long)g.padPresentCount);
    CVR_INFO("delivery.summary", "stream=%d streamedFrames=%llu framesEnded=%llu -- streamed frames each reuse one eye",
             (int)g.streamGuestFrames,(unsigned long long)s.streamFrames,(unsigned long long)s.framesEnded);
    g.ready = false;
    g.dev = nullptr;
}

// ---------------------------------------------------------------------------
// Punkt 6 bis 10 -- der Eingriff am fertigen Gastframe
// ---------------------------------------------------------------------------

bool referenceProbeEnabled() {
    static const bool enabled=[] { const char* v=std::getenv("CEMUVR_REFERENCE_MARKER_PROBE"); return !v || !std::strcmp(v,"1"); }();
    return enabled;
}

VKAPI_ATTR VkResult VKAPI_CALL ReferenceCreateImage(VkDevice device, const VkImageCreateInfo* ci,
        const VkAllocationCallbacks* alloc, VkImage* out) {
    DeviceData* dd; { std::lock_guard<std::mutex> lk(g_mtx); dd=deviceOf(device); }
    if (!dd) return VK_ERROR_INITIALIZATION_FAILED;
    VkResult result=dd->CreateImage(device,ci,alloc,out);
    if (result==VK_SUCCESS && referenceProbeEnabled()) {
        std::lock_guard<std::mutex> lk(g_mtx);
        auto copy=*ci; copy.pNext=nullptr; copy.pQueueFamilyIndices=nullptr;
        dd->referenceImages[*out]=copy;
    }
    return result;
}

VKAPI_ATTR void VKAPI_CALL ReferenceDestroyImage(VkDevice device, VkImage image, const VkAllocationCallbacks* alloc) {
    DeviceData* dd; { std::lock_guard<std::mutex> lk(g_mtx); dd=deviceOf(device); if(dd) dd->referenceImages.erase(image); }
    if (dd) dd->DestroyImage(device,image,alloc);
}

VKAPI_ATTR void VKAPI_CALL ReferenceClearColor(VkCommandBuffer cb, VkImage image, VkImageLayout layout,
        const VkClearColorValue* color, uint32_t count, const VkImageSubresourceRange* ranges) {
    DeviceData* dd; { std::lock_guard<std::mutex> lk(g_mtx); dd=deviceOf(cb); }
    if (!dd) return;
    HudMarker hudTag{};
    if(referenceProbeEnabled() && envFlag("CEMUVR_REFERENCE_WORLD_HUD",true) && color && decodeHudMarker(color->uint32,hudTag)) {
        std::lock_guard<std::mutex> lk(g_mtx);
        auto it=dd->referenceImages.find(image);
        if(it!=dd->referenceImages.end() && count==1 && ranges && ranges[0].baseMipLevel==0 && ranges[0].baseArrayLayer==0)
            dd->referenceHud.record(dd->vk,cb,image,layout,it->second,hudTag);
        return;
    }
    uint32_t poseToken{};
    if(referenceProbeEnabled() && envFlag("CEMUVR_REFERENCE_POSE_STAMP",true) && color && decodeReferencePoseToken(color->uint32,poseToken)) {
        std::lock_guard<std::mutex> lk(g_mtx);
        dd->referencePoseMarkers[cb]={image,poseToken};return;
    }
    ReferenceMarker marker{};
    if (referenceProbeEnabled() && color) {
        std::lock_guard<std::mutex> lk(g_mtx);
        ++dd->referenceClearCalls;
        std::array<uint32_t,4> values{color->uint32[0],color->uint32[1],color->uint32[2],color->uint32[3]};
        if (dd->referenceClearValues.size()<64 && dd->referenceClearValues.insert(values).second)
            CVR_INFO("reference.clear","n=%llu rgba=%08X/%08X/%08X/%08X",(unsigned long long)dd->referenceClearCalls,
                values[0],values[1],values[2],values[3]);
    }
    if (referenceProbeEnabled() && color && decodeReferenceMarker(color->uint32,marker)) {
        std::lock_guard<std::mutex> lk(g_mtx);
        auto it=dd->referenceImages.find(image);
        const auto meta=dd->referencePoseMarkers.find(cb);
        if(meta!=dd->referencePoseMarkers.end()) {
            if(meta->second.first==image)poseToken=meta->second.second;
            dd->referencePoseMarkers.erase(meta);
        }
        const VkImageCreateInfo* info=it==dd->referenceImages.end()?nullptr:&it->second;
        if(info && count==1 && ranges && ranges[0].baseMipLevel==0 && ranges[0].baseArrayLayer==0) {
            dd->referenceSnapshots.record(dd->vk,cb,image,layout,*info,marker,poseToken);
            if(envFlag("CEMUVR_REFERENCE_PAIR_TRANSPORT",true)) dd->referencePairImages.record(dd->vk,cb,image,layout,*info,marker,poseToken);
        }
        ++dd->referenceMarkers;
        // This command is our protocol marker. Preserve the original color image.
        return;
    }
    {std::lock_guard<std::mutex> lk(g_mtx);dd->referencePoseMarkers.erase(cb);}
    dd->CmdClearColorImage(cb,image,layout,color,count,ranges);
}

VKAPI_ATTR void VKAPI_CALL ReferenceClearAttachments(VkCommandBuffer cb, uint32_t count,
        const VkClearAttachment* attachments, uint32_t rectCount, const VkClearRect* rects) {
    DeviceData* dd; { std::lock_guard<std::mutex> lk(g_mtx); dd=deviceOf(cb); }
    if (!dd) return;
    if (referenceProbeEnabled()) {
        std::vector<VkClearAttachment> remaining;
        for(uint32_t i=0;i<count;++i) {
            const auto& a=attachments[i]; ReferenceMarker tag{};
            HudMarker hudTag{};
            if(envFlag("CEMUVR_REFERENCE_WORLD_HUD",true) && decodeHudMarker(a.clearValue.color.uint32,hudTag)) {
                CVR_ERR("reference.hud","attachment_marker_unsupported=1");continue;
            }
            uint32_t token{};
            if(envFlag("CEMUVR_REFERENCE_POSE_STAMP",true) && decodeReferencePoseToken(a.clearValue.color.uint32,token)) {
                dd->referencePairImages.failed=true;
                CVR_ERR("reference.pose","attachment_metadata_unsupported=1");continue;
            }
            if ((a.aspectMask & VK_IMAGE_ASPECT_COLOR_BIT) && decodeReferenceMarker(a.clearValue.color.uint32,tag)) {
                ++dd->referenceMarkers;
            } else remaining.push_back(a);
            if (++dd->referenceAttachmentCalls<=16)
                CVR_INFO("reference.attach","aspect=%u rgba=%08X/%08X/%08X/%08X",a.aspectMask,
                    a.clearValue.color.uint32[0],a.clearValue.color.uint32[1],a.clearValue.color.uint32[2],a.clearValue.color.uint32[3]);
        }
        if(!remaining.empty()) dd->CmdClearAttachments(cb,(uint32_t)remaining.size(),remaining.data(),rectCount,rects);
        return;
    }
    dd->CmdClearAttachments(cb,count,attachments,rectCount,rects);
}

void acknowledgeReferenceProbe() {
    static bool done=false;
    if (done || !referenceProbeEnabled()) return;
    auto* base=g.bridge.guestMemoryBase();
    if (!base) return;
    const uint8_t signature[]={0x43,0x54,0x46,0x4c,0,0,0,1};
    for (uintptr_t off=0x01800000; off<0x01a00000;) {
        MEMORY_BASIC_INFORMATION mbi{};
        if (!VirtualQuery(base+off,&mbi,sizeof(mbi))) break;
        uintptr_t next=(uintptr_t)mbi.BaseAddress+mbi.RegionSize-(uintptr_t)base;
        if (next<=off) break;
        uintptr_t end=(std::min)(next,uintptr_t(0x01a00000));
        if (mbi.State==MEM_COMMIT && (mbi.Protect & (PAGE_READWRITE|PAGE_EXECUTE_READWRITE)) && !(mbi.Protect & PAGE_GUARD)) {
            for (uintptr_t p=off;p+40<=end;p+=4) {
                if (!std::memcmp(base+p,signature,8) && !std::memcmp(base+p+20,"CTM1",4)) {
                    InterlockedExchange((volatile LONG*)(base+p+24),_byteswap_ulong(0x43544d31));
                    if(envFlag("CEMUVR_REFERENCE_WORLD_HUD",true)) {
                        for(uintptr_t hp=p;hp+8<=end && hp<p+0x4000;hp+=4) {
                            if(!std::memcmp(base+hp,"HUA2",4) && !*(uint32_t*)(base+hp+4)) {
                                InterlockedExchange((volatile LONG*)(base+hp+4),_byteswap_ulong(0x48554132));
                                CVR_INFO("reference.hud","protocol_ack=2 guest=%08X",uint32_t(hp));break;
                            }
                        }
                    }
                    done=true; CVR_INFO("reference.ack","guest=%08X marker-only protocol acknowledged",(uint32_t)p); return;
                }
            }
        }
        off=next;
    }
}

struct ReferencePoseHistoryEntry {uint32_t token{};CemuVR_FrameContext context{};};
static std::array<ReferencePoseHistoryEntry,2048> referencePoseHistory{};

void publishReferencePose(uint64_t generation) {
    // Enabled by default for the Mario release; an environment override remains available.
    if(!envFlag("CEMUVR_REFERENCE_POSE_EXPERIMENT",true))return;
    static const float unitsPerMeter=[] {
        const auto value=envStr("CEMUVR_MARIO_WORLD_SIZE","2");
        const float factor=std::strtof(value.c_str(),nullptr);
        return 3000.f/((factor>=.25f && factor<=30.f)?factor:1.f);
    }();
    static uint8_t* packet=nullptr;
    static bool mailboxFailed=false;
    static uint32_t packetVersion=0;
    static uint32_t sequence=0;
    static bool anchorReported=false;
    auto* base=g.bridge.guestMemoryBase();
    if(!base || mailboxFailed)return;
    if(!packet) {
        const uint8_t sig[]={0x43,0x54,0x50,0x48,0,0,0};
        for(uintptr_t off=0x01800000;off<0x01a00000;) {
            MEMORY_BASIC_INFORMATION mbi{};
            if(!VirtualQuery(base+off,&mbi,sizeof(mbi)))break;
            uintptr_t next=(uintptr_t)mbi.BaseAddress+mbi.RegionSize-(uintptr_t)base;
            if(next<=off)break;
            uintptr_t end=(std::min)(next,uintptr_t(0x01a00000));
            if(mbi.State==MEM_COMMIT && (mbi.Protect&(PAGE_READWRITE|PAGE_EXECUTE_READWRITE)) && !(mbi.Protect&PAGE_GUARD))
                for(uintptr_t p=off;p+192<=end;p+=4)if(!std::memcmp(base+p,sig,7) && (base[p+7]>=1 && base[p+7]<=4) && p+(base[p+7]==4?216:192)<=end) {
                    if(packet){mailboxFailed=true;packet=nullptr;CVR_ERR("reference.pose","ambiguous_mailbox=1");return;}
                    packet=base+p;
                    packetVersion=base[p+7];
                }
            off=next;
        }
        if(!packet)return;
        CVR_INFO("reference.pose","mailbox=%08X version=%u experiment=1 scale=%.2f projection_unchanged=%d",uint32_t(packet-base),packetVersion,unitsPerMeter,int(packetVersion==1));
    }
    CemuVR_FrameContext fc{};
    if(!g.xr.fillFrameContext(&fc,CEMUVR_EYE_LEFT,generation,0))return;
    CemuVR_Pose candidate{};
    if(!g.xr.referenceAnchor(&candidate)) {
        static bool reported=false;
        if(!reported) {
            CVR_INFO("reference.anchor","waiting_for_tracked_pose=1 required_consecutive_frames=30");
            reported=true;
        }
        return;
    }
    const auto control=envStr("CEMUVR_REFERENCE_DIAGNOSTIC_CONTROL","");
    if(!control.empty() && envStr("XR_RUNTIME_JSON","").find("fakehmd.json")!=std::string::npos) {
        static CemuVR_FrameContext neutral=fc;
        static ReferenceDiagnosticCommand command{0,"CENTER"};
        if(generation%30==0) {
            std::ifstream file(control);std::string line;std::getline(file,line);
            ReferenceDiagnosticCommand next;
            if(parseReferenceDiagnostic(line,next) && next.serial>command.serial) {
                command=next;
                CVR_INFO("reference.diagnostic","command=%u preset=%s applies_from_serial=%llu synthetic_pose=1",
                    command.serial,command.preset.c_str(),(unsigned long long)fc.poseSerial);
            }
        }
        applyReferenceDiagnostic(neutral,command.preset,fc);
    }
    float deltas[24];
    if(!referencePoseDelta(candidate,fc.eyePose[0],unitsPerMeter,deltas) ||
       !referencePoseDelta(candidate,fc.eyePose[1],unitsPerMeter,deltas+12))return;
    float projection[16];
    if(packetVersion>=2 && (!referenceProjection(fc.eyeFov[0],projection) || !referenceProjection(fc.eyeFov[1],projection+8)))return;
    float scalars[6];
    if(packetVersion>=4 && (!referenceProjectionScalars(fc.eyeFov[0],scalars) || !referenceProjectionScalars(fc.eyeFov[1],scalars+3)))return;
    if(!anchorReported){
        anchorReported=true;
        CVR_INFO("reference.anchor","set=1 source=session_anchor serial=%llu position=%.6f/%.6f/%.6f orientation=%.6f/%.6f/%.6f/%.6f",
            (unsigned long long)fc.poseSerial,candidate.position.x,candidate.position.y,candidate.position.z,
            candidate.orientation.x,candidate.orientation.y,candidate.orientation.z,candidate.orientation.w);
    }
    // Big-endian seqlock. Both guest eyes latch this once, before simulation.
    // Bounded diagnostic protocol: never reuse a 16-bit token in this process.
    if(packetVersion>=3 && sequence>=131070) {
        if(!mailboxFailed)CVR_ERR("reference.pose","token_limit_restart_required=1");
        mailboxFailed=true;return;
    }
    sequence+=2;if(!sequence)sequence=2;
    InterlockedExchange((volatile LONG*)(packet+8),_byteswap_ulong(sequence-1));
    uint32_t payload[51]{};payload[0]=_byteswap_ulong(1);
    payload[1]=_byteswap_ulong(uint32_t(fc.poseSerial));
    for(int i=0;i<24;++i){uint32_t bits;std::memcpy(&bits,&deltas[i],4);payload[i+3]=_byteswap_ulong(bits);}
    if(packetVersion>=2)for(int i=0;i<16;++i){uint32_t bits;std::memcpy(&bits,&projection[i],4);payload[i+27]=_byteswap_ulong(bits);}
    if(packetVersion>=3) {
        const uint32_t token=sequence/2;
        for(int i=0;i<2;++i){const uint32_t byte=(token>>(i?0:8))&255;float encoded=byte==255?1.f:(byte+.25f)/255.f;
            uint32_t bits;std::memcpy(&bits,&encoded,4);payload[43+i]=_byteswap_ulong(bits);}
        referencePoseHistory[token%referencePoseHistory.size()]={token,fc};
    }
    if(packetVersion>=4)for(int i=0;i<6;++i){uint32_t bits;std::memcpy(&bits,&scalars[i],4);payload[45+i]=_byteswap_ulong(bits);}
    std::memcpy(packet+12,payload,packetVersion>=4?204:packetVersion==3?180:packetVersion==2?172:108);
    InterlockedExchange((volatile LONG*)(packet+8),_byteswap_ulong(sequence));
    if(sequence<=8 || generation%120==0)
        CVR_INFO("reference.pose","sequence=%u serial=%llu after_generation=%llu Ltx=%.3f Rtx=%.3f r00=%.5f -- future guest camera experiment",
            sequence,(unsigned long long)fc.poseSerial,(unsigned long long)generation,deltas[3],deltas[15],deltas[0]);
}

VkResult presentReferencePair(DeviceData* dd,VkQueue queue,const VkPresentInfoKHR* pi) {
    std::lock_guard<std::mutex> lock(g_mtx);
    auto& pairs=dd->referencePairImages;
    const int slot=pairs.order.latest();
    if(slot<0 || pairs.failed) return dd->QueuePresent(queue,pi);
    if(queue!=dd->vk.queue || !dd->vk.keyedMutex || pairs.width!=g.interop.width() ||
       pairs.height!=g.interop.height() || pairs.format!=dxgiToVk(g.interop.format())) {
        pairs.failed=true;CVR_ERR("reference.transport","queue_format_size_or_mutex_mismatch=1");
        return dd->QueuePresent(queue,pi);
    }
    const uint64_t generation=pairs.order.complete[slot];
    pairs.order.consumed[slot]=generation;
    VkPresentInfoKHR next=*pi;VkSemaphore last{};
    bool copied[2]{};
    for(int eye=0;eye<2;++eye) {
        VkSemaphore signal{};
        // Diagnostic view translation: source eye 1 is physically left.
        copied[eye]=g.interop.copyFromSwapchainImage(dd->vk,eye,pairs.images[slot*2+(1-eye)].handle,
            pairs.width,pairs.height,next.pWaitSemaphores,next.waitSemaphoreCount,&signal,0,0,VK_IMAGE_LAYOUT_GENERAL);
        if(!copied[eye])break;
        last=signal;next.waitSemaphoreCount=1;next.pWaitSemaphores=&last;
    }
    auto& hud=dd->referenceHud;
    bool hudCopied=false,hudHeld=false;
    if(envFlag("CEMUVR_REFERENCE_WORLD_HUD",true) && hud.ready[slot*2] && hud.ready[slot*2+1] && !hud.hud.failed &&
       hud.hud.width==pairs.width && hud.hud.height==pairs.height) {
        auto& hi=dd->hudInterop;
        if(!hi.width()) {
            if(!hi.createD3D11Side(g.xr.device(),pairs.width,pairs.height,g.interop.format()) ||
               !hi.importIntoVulkan(dd->vk,pairs.format))hud.hud.failed=true;
        }
        if(hi.vulkanReady() && !hud.hud.failed) {
            VkSemaphore signal{};
            hudCopied=hi.copyFromSwapchainImage(dd->vk,0,hud.hud.images[slot*2].handle,pairs.width,pairs.height,
                next.pWaitSemaphores,next.waitSemaphoreCount,&signal,0,0,VK_IMAGE_LAYOUT_GENERAL);
            if(hudCopied){last=signal;next.waitSemaphoreCount=1;next.pWaitSemaphores=&last;}
        }
    }
    const bool hudTitle=hud.title[slot*2]||hud.title[slot*2+1];
    hud.ready[slot*2]=hud.ready[slot*2+1]=false;
    const VkResult result=dd->QueuePresent(queue,&next);
    if(hudCopied)hudHeld=dd->hudInterop.acquireForD3D11(0,2000,nullptr);
    bool held[2]{};
    for(int eye=0;eye<2;++eye) if(copied[eye])held[eye]=g.interop.acquireForD3D11(eye,2000,nullptr);
    bool submitted=false;
    if(held[0] && held[1] && g.xr.pollEvents() && g.xr.state()==XrState::SessionRunning && g.xr.beginFrame()) {
        uint32_t pairId{};g.xr.setPresentInfo(g.tvPresentCount,0);
        g.xr.beginGuestFrame(generation,&pairId); // one simulation generation, two explicit eyes
        publishReferencePose(generation);
        const bool strict=envFlag("CEMUVR_REFERENCE_POSE_STAMP",true);
        const uint32_t token=pairs.poseTokens[slot*2];
        const bool menu=token==0x10000 && pairs.poseTokens[slot*2+1]==0x10000;
        const bool unposed=referenceUnposedSurface(token,pairs.poseTokens[slot*2+1],
            envFlag("CEMUVR_REFERENCE_UNPOSED_SURFACE",true));
        const bool surfaceFrame=menu || unposed;
        static int previousSurfaceReason=-1;
        const int surfaceReason=menu?1:unposed?2:0;
        if(surfaceReason!=previousSurfaceReason) {
            CVR_INFO("reference.surface","generation=%llu reason=%s tokens=%u/%u",
                (unsigned long long)generation,menu?"menu":unposed?"unposed_mono_fallback":"stereo",
                token,pairs.poseTokens[slot*2+1]);
            previousSurfaceReason=surfaceReason;
        }
        if(surfaceFrame) {
            CemuVR_SurfaceRequest surface{};surface.structVersion=CEMUVR_PROFILE_ABI;
            surface.mode=1;surface.distanceMetres=2.f;surface.widthMetres=2.31f;
            surface.heightMetres=surface.widthMetres*float(pairs.height)/float(pairs.width);
            g.xr.setSurface(surface);
        } else if(g.xr.surfaceActive())g.xr.clearSurface();
        const auto& stamp=referencePoseHistory[token%referencePoseHistory.size()];
        const bool stampValid=token && token<0x10000 && token==pairs.poseTokens[slot*2+1] && stamp.token==token;
        if(surfaceFrame || !strict || stampValid) {
        const auto left=g.xr.submitEye(CEMUVR_EYE_LEFT,g.interop.d3dTexture(0));
        const auto right=g.xr.submitEye(CEMUVR_EYE_RIGHT,g.interop.d3dTexture(1));
        submitted=left==SubmitResult::Ok && right==SubmitResult::PairComplete;
        if(strict && submitted && !surfaceFrame)submitted=g.xr.stampRenderedPair(stamp.context);
        }
        if(strict && (generation<=4 || generation%120==0 || (!stampValid && !surfaceFrame)))
            CVR_INFO("reference.stamp","generation=%llu tokens=%u/%u valid=%d renderSerial=%llu submitted=%d",
                (unsigned long long)generation,token,pairs.poseTokens[slot*2+1],int(stampValid),
                (unsigned long long)(stampValid?stamp.context.poseSerial:0),int(submitted));
        if(submitted && !surfaceFrame && hudHeld)g.xr.submitHud(dd->hudInterop.d3dTexture(0),hudTitle);
        g.xr.endFrame();
    }
    if(hudHeld)dd->hudInterop.releaseFromD3D11(0);
    for(int eye=0;eye<2;++eye)if(held[eye])g.interop.releaseFromD3D11(eye);
    if(!copied[0] || !copied[1] || !held[0] || !held[1])pairs.failed=true;
    if(generation<=4 || generation%120==0 || !submitted)
        CVR_INFO("reference.transport","generation=%llu slot=%d copies=%d%d held=%d%d submitted=%d rejected=%llu",
            (unsigned long long)generation,slot,int(copied[0]),int(copied[1]),int(held[0]),int(held[1]),int(submitted),(unsigned long long)pairs.order.rejected);
    return result;
}

VKAPI_ATTR VkResult VKAPI_CALL QueuePresentKHR(VkQueue queue, const VkPresentInfoKHR* pi) {
    DeviceData* dd = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        dd = deviceOf(queue);
    }
    if (!dd) return VK_ERROR_INITIALIZATION_FAILED;

    ++g.presentCount;

    if (!g.enabled || g.failed || g.stopped || !pi || pi->swapchainCount == 0)
        return dd->QueuePresent(queue, pi);

    // Welcher der praesentierten Swapchains ist der Fernseher?
    int tvIdx = -1;
    SwapRec* tv = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        for (uint32_t i = 0; i < pi->swapchainCount; ++i) {
            auto it = dd->swapchains.find(pi->pSwapchains[i]);
            if (it != dd->swapchains.end() && (it->second.isTv || g.dualOutput)) { tvIdx = (int)i; tv = &it->second; break; }
        }
    }
    if (tvIdx < 0 || !tv || tv->images.empty()) return dd->QueuePresent(queue, pi);

    const uint32_t imgIdx = pi->pImageIndices[tvIdx];
    if (imgIdx >= tv->images.size()) {
        CVR_WARN("present", "imageIndex=%u out_of_range n=%zu", imgIdx, tv->images.size());
        return dd->QueuePresent(queue, pi);
    }
    VkImage tvImage = tv->images[imgIdx];
    const bool sourceTv = tv->isTv;
    if (!sourceTv && (!g.ready || !g.xr.frameActive()))
        return dd->QueuePresent(queue, pi);
    if (sourceTv) {
        ++g.tvPresentCount;
        // A second TV without a pad must not join two different guest frames.
        if (g.dualOutput && g.xr.frameActive()) closeXrFrameIfOpen();
    } else {
        ++g.padPresentCount;
        if (tv->extent.width != g.xr.eyeWidth() || tv->extent.height != g.xr.eyeHeight()) {
            if (g.padPresentCount == 1)
                CVR_ERR("dual.output", "pad_extent=%ux%u tv_extent=%ux%u -- cannot copy",
                        tv->extent.width, tv->extent.height, g.xr.eyeWidth(), g.xr.eyeHeight());
            closeXrFrameIfOpen();
            return dd->QueuePresent(queue, pi);
        }
    }

    SwapRec sourceSpec=*tv;
    if(envFlag("CEMUVR_REFERENCE_PAIR_TRANSPORT",true)) {
        // The bridge is attached at layer startup; acknowledging does not need XR.
        // Do not create a throwaway desktop-sized runtime before eye images exist.
        acknowledgeReferenceProbe();
        auto& pair=dd->referencePairImages;
        if(!pair.width || pair.failed) return dd->QueuePresent(queue,pi);
        sourceSpec.extent={pair.width,pair.height};sourceSpec.format=pair.format;
        if(g.ready && (g.interop.width()!=pair.width || g.interop.height()!=pair.height || dxgiToVk(g.interop.format())!=pair.format)) {
            pair.failed=true;
            CVR_ERR("reference.transport","source_changed_restart_required=1");
            return dd->QueuePresent(queue,pi);
        }
    }
    if (!lazyInit(dd, sourceSpec)) return dd->QueuePresent(queue, pi);
    acknowledgeReferenceProbe();
    if(referenceProbeEnabled()) { std::lock_guard<std::mutex> lk(g_mtx); dd->referenceSnapshots.dump(dd->vk,queue); }
    if(envFlag("CEMUVR_REFERENCE_PAIR_TRANSPORT",true)) return presentReferencePair(dd,queue,pi);
    PerfRow perf{};
    perf.present=g.tvPresentCount;
    double stage=perfMs();

    // Gegenprobe: nennt Cemus eigenes Objektmodell dasselbe Bild?
    g.bridge.refreshRenderer();
    if (sourceTv && g.bridge.status().vtableMatches) {
        VkSwapchainKHR known[8];
        uint32_t n = 0;
        {
            std::lock_guard<std::mutex> lk(g_mtx);
            for (auto& kv : dd->swapchains) { if (n < 8) known[n++] = kv.first; }
        }
        g.bridge.findTvSwapchain(known, n);
        g.bridge.recordCrossCheck(tvImage, g.bridge.tvImageFromCemuObjects());
    }

    // XR-Frame oeffnen, falls noetig
    if (!g.xr.frameActive()) {
        if (!g.xr.pollEvents()) { CVR_WARN("present", "xr=stop"); g.stopped = true; return dd->QueuePresent(queue, pi); }
        if (g.xr.state() != XrState::SessionRunning) return dd->QueuePresent(queue, pi);
        if (!g.xr.beginFrame()) return dd->QueuePresent(queue, pi);
        g.guestFramesInXrFrame = 0;
    }
    ++g.guestFramesInXrFrame;
    perf.begin=perfMs()-stage;

    // Gastframe anmelden. Der Zaehler kommt bevorzugt aus Cemus eigenem
    // Swapzaehler; faellt er aus, zaehlt die Schicht die TV-Praesentationen.
    const uint32_t cemuCounter = g.bridge.guestSwapCounter();
    const uint64_t counter = cemuCounter ? (uint64_t)cemuCounter : g.tvPresentCount;

    uint32_t pairId = 0;
    // Erst die Herkunftsangaben, dann das Auge: fillFrameContext und
    // submitEye lesen sie beide.
    if (sourceTv) g.xr.setPresentInfo(g.tvPresentCount, imgIdx);
    const CemuVR_Eye eye = sourceTv ? g.xr.beginGuestFrame(counter, &pairId)
                                             : CEMUVR_EYE_RIGHT;
    const int eyeIdx = (eye == CEMUVR_EYE_LEFT) ? 0 : 1;
    perf.eye=eyeIdx;
    stage=perfMs();

    // Punkt 10: Titelwechsel im laufenden Betrieb erkennen.
    {
        const uint64_t nowTitle = g.bridge.titleId();
        if (nowTitle != g.lastTitleId) {
            CVR_INFO("profile.host", "Titelwechsel %016llX -> %016llX",
                     (unsigned long long)g.lastTitleId, (unsigned long long)nowTitle);
            g.lastTitleId = nowTitle;
            g.profiles.attachToTitle(nowTitle, g.bridge.guestMemoryBase());
        }
    }

    // Punkt 7: Frame-, Pose-, Eye-, Kamera- und Projection-Daten uebergeben.
    CemuVR_EyeAdjust adjust{};
    adjust.fovScale = 1.0f;
    bool haveAdjust = false;
    if (sourceTv && g.profiles.active()) {
        CemuVR_FrameContext fc{};
        if (g.xr.fillFrameContext(&fc, eye, counter, pairId)) {
            fc.guestMemoryBase = g.bridge.guestMemoryBase();
            fc.titleId         = g.lastTitleId;
            CemuVR_EyeAdjust a{};
            a.structVersion = CEMUVR_PROFILE_ABI;
            a.fovScale = 1.0f;
            // Der Flaechenauftrag. mode 0 heisst normale Stereoausgabe; ein
            // Profil ohne surfaceRequest laesst ihn dabei.
            CemuVR_SurfaceRequest sq{};
            sq.structVersion = CEMUVR_PROFILE_ABI;
            sq.mode = 0;
            const bool render = g.profiles.frame(&fc, &a, &sq);
            if (sq.mode) g.xr.setSurface(sq);
            else if (g.xr.surfaceActive()) g.xr.clearSurface();
            if (!render) ++g.profileSkips;
            if (a.sourceOffsetX || a.sourceOffsetY || a.fovScale != 1.0f ||
                a.eyePositionOffset.x || a.eyePositionOffset.y || a.eyePositionOffset.z) {
                adjust = a;
                haveAdjust = true;
                // Punkt 8: die View-/Projection-Aenderung an den Kern geben.
                g.xr.setEyeAdjust(eye, a);
            }
        }
    }

    // Absichtliche Verzoegerung zur Pruefung: haelt GENAU diesen Gastframe auf,
    perf.profile=perfMs()-stage;
    // nachdem das Auge schon zugeteilt ist. Wenn Paarbildung und Augenwechsel
    // das aushalten, halten sie auch echte Ruckler aus.
    if (sourceTv && g.delayEvery && (g.tvPresentCount % g.delayEvery) == 0 && g.delayMs) {
        ++g.delaysInjected;
        CVR_WARN("test.delay", "present=%llu eye=%d ms=%u",
                 (unsigned long long)g.tvPresentCount, (int)eye, g.delayMs);
        Sleep(g.delayMs);
    }

    // Punkte 7 und 8: Barrieren und Kopie, eingehaengt zwischen Cemus
    // Renderabschluss und Cemus Praesentation.
    VkSemaphore mySem = VK_NULL_HANDLE;
    stage=perfMs();
    const bool copied = g.interop.copyFromSwapchainImage(
        dd->vk, eyeIdx, tvImage, tv->extent.width, tv->extent.height,
        pi->pWaitSemaphores, pi->waitSemaphoreCount, &mySem,
        haveAdjust ? adjust.sourceOffsetX : 0,
        haveAdjust ? adjust.sourceOffsetY : 0);
    perf.copy=perfMs()-stage;

    if (copied) ++g.copiesOk; else ++g.copiesFailed;

    // Punkt 9: keine globale Synchronisation. Cemus Praesentation wartet auf
    // MEINE Semaphore, die wiederum auf Cemus Renderabschluss gewartet hat.
    // vkDeviceWaitIdle kommt im gesamten Kern nicht vor.
    VkPresentInfoKHR pi2 = *pi;
    if (copied && mySem != VK_NULL_HANDLE) {
        pi2.waitSemaphoreCount = 1;
        pi2.pWaitSemaphores = &mySem;
    }
    stage=perfMs();
    const VkResult res = dd->QueuePresent(queue, &pi2);
    perf.presentWait=perfMs()-stage;

    // Punkt 10: Uebergabe an den bereits geprueften Kern.
    if (copied) {
        double waited = 0.0;
        if (g.interop.acquireForD3D11(eyeIdx, 2000, &waited)) {
            g.acquireWaitTotalMs += waited;
            if (waited > g.acquireWaitMaxMs) g.acquireWaitMaxMs = waited;
            ++g.acquireCount;
            perf.acquire=waited;
            stage=perfMs();
            g.xr.submitEye(eye, g.interop.d3dTexture(eyeIdx));
            g.interop.releaseFromD3D11(eyeIdx);
            perf.submit=perfMs()-stage;
        } else {
            CVR_ERR("present", "reason=acquire_timeout eye=%d", eyeIdx);
        }
    }

    // XR-Frame schliessen, wenn das Paar voll ist -- oder notfalls, damit ein
    // fehlgeschlagenes Auge den Frame nicht offen haelt.
    if (g.streamGuestFrames || eye == CEMUVR_EYE_RIGHT || g.guestFramesInXrFrame >= 4) {
        // Bitgleiche Augen ausdruecklich melden. Das ist NICHT zwangslaeufig ein
        // Fehler des Kerns: zeigt das Spiel ein stehendes Bild (Ladebildschirm,
        // Menue), sind zwei aufeinanderfolgende Gastframes zu Recht gleich.
        // Gemeldet wird es trotzdem, damit die Unterscheidung am Beleg haengt
        // und nicht an einer Annahme.
        const uint32_t cl = g.xr.stats().lastEyeChecksum[0];
        const uint32_t cr = g.xr.stats().lastEyeChecksum[1];
        if (cl && cr) {
            ++g.pairsChecked;
            if (cl == cr) {
                ++g.identicalPairs;
                if (!g.firstIdentical) g.firstIdentical = g.pairsChecked;
                g.lastIdentical = g.pairsChecked;
                CVR_WARN("stereo.identical",
                         "pair=%u crc=%08x -- beide Augen bitgleich; der Gast hat "
                         "zweimal dasselbe Bild erzeugt", pairId, cl);
            }
        }
        perf.surface=g.xr.surfaceActive()?1:0;
        const auto completedBefore=g.xr.stats().pairsComplete;
        const auto streamedBefore=g.xr.stats().streamFrames;
        const auto framesEndedBefore=g.xr.stats().framesEnded;
        stage=perfMs();
        g.xr.endFrame();
        perf.end=perfMs()-stage;
        perf.complete=(g.xr.stats().framesEnded>framesEndedBefore &&
            (g.xr.stats().pairsComplete>completedBefore || g.xr.stats().streamFrames>streamedBefore))?1:0;
        g.guestFramesInXrFrame = 0;

        if (g.maxPairs && g.xr.stats().pairsComplete >= g.maxPairs) {
            CVR_INFO("layer.stop", "reason=maxPairs pairs=%llu",
                     (unsigned long long)g.xr.stats().pairsComplete);
            g.stopped = true;
            teardown();
        }
    }
    perf.time=perfMs();
    return res;
}

// ---------------------------------------------------------------------------
// Swapchains
// ---------------------------------------------------------------------------

VKAPI_ATTR VkResult VKAPI_CALL CreateSwapchainKHR(VkDevice device,
                                                  const VkSwapchainCreateInfoKHR* ci,
                                                  const VkAllocationCallbacks* alloc,
                                                  VkSwapchainKHR* out) {
    DeviceData* dd = nullptr;
    HWND hwnd = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        dd = deviceOf(device);
        auto it = g_surfaces.find(ci->surface);
        if (it != g_surfaces.end()) hwnd = it->second;
    }
    if (!dd) return VK_ERROR_INITIALIZATION_FAILED;

    VkSwapchainCreateInfoKHR ci2 = *ci;

    // ZWINGEND: ohne TRANSFER_SRC darf aus dem fertigen Bild nicht kopiert
    // werden. Nur anfuegen, wenn die Oberflaeche es auch zulaesst.
    bool added = false;
    if (g.enabled && !(ci->imageUsage & VK_IMAGE_USAGE_TRANSFER_SRC_BIT)) {
        VkSurfaceCapabilitiesKHR caps{};
        VkResult cr = VK_ERROR_INITIALIZATION_FAILED;
        if (dd->inst && dd->inst->GetSurfCaps)
            cr = dd->inst->GetSurfCaps(dd->phys, ci->surface, &caps);
        if (cr == VK_SUCCESS && (caps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_SRC_BIT)) {
            ci2.imageUsage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
            added = true;
        } else {
            CVR_ERR("swapchain", "reason=surface_forbids_transfer_src supported=0x%08x result=%s",
                    cr == VK_SUCCESS ? caps.supportedUsageFlags : 0u, vkResultName(cr));
        }
    }

    const VkResult r = dd->CreateSwapchain(device, &ci2, alloc, out);
    if (r != VK_SUCCESS) {
        CVR_ERR("swapchain", "op=vkCreateSwapchainKHR result=%s", vkResultName(r));
        return r;
    }

    SwapRec rec;
    rec.handle  = *out;
    rec.surface = ci->surface;
    rec.hwnd    = hwnd;
    rec.format  = ci->imageFormat;
    rec.extent  = ci->imageExtent;
    rec.usageAdded = added;

    // Punkt 5, erster Teil: Fernseher oder GamePad?
    rec.isTv = !windowLooksLikeGamePad(hwnd);

    uint32_t n = 0;
    if (dd->GetSwapchainImages(device, *out, &n, nullptr) == VK_SUCCESS && n) {
        rec.images.resize(n);
        dd->GetSwapchainImages(device, *out, &n, rec.images.data());
    }

    describeWindow(hwnd, rec.isTv ? "tv" : "gamepad");
    // Ein- UND ausgehende Nutzung protokollieren. Auf Rechnern mit weiteren
    // impliziten Schichten (Aufnahmewerkzeuge, Overlays) kann TRANSFER_SRC
    // bereits gesetzt sein, bevor diese Schicht den Aufruf sieht -- dann ist
    // transferSrcAdded=0 richtig und transferSrcPresent=1 das, worauf es ankommt.
    // Der Praesentationsmodus gehoert ins Protokoll, nicht nur in Cemus
    // Einstellungen: er entscheidet, ob Cemus Praesentation den Gast bremst.
    // FIFO wartet auf den Bildschirm, IMMEDIATE und MAILBOX nicht.
    const char* pmName = "unbekannt";
    switch (ci->presentMode) {
    case VK_PRESENT_MODE_IMMEDIATE_KHR:    pmName = "IMMEDIATE"; break;
    case VK_PRESENT_MODE_MAILBOX_KHR:      pmName = "MAILBOX"; break;
    case VK_PRESENT_MODE_FIFO_KHR:         pmName = "FIFO"; break;
    case VK_PRESENT_MODE_FIFO_RELAXED_KHR: pmName = "FIFO_RELAXED"; break;
    default: break;
    }
    CVR_INFO("swapchain",
             "created handle=0x%llX %ux%u format=%s images=%u usageIn=0x%08x usageOut=0x%08x "
             "transferSrcAdded=%d transferSrcPresent=%d isTv=%d presentMode=%s",
             (unsigned long long)(uint64_t)*out, rec.extent.width, rec.extent.height,
             vkFormatName(rec.format), n, ci->imageUsage, ci2.imageUsage, (int)added,
             (int)((ci2.imageUsage & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) != 0),
             (int)rec.isTv, pmName);

    {
        std::lock_guard<std::mutex> lk(g_mtx);
        // Gibt es bereits einen TV, ist dieser hier keiner mehr.
        if (rec.isTv)
            for (auto& kv : dd->swapchains)
                if (kv.second.isTv && kv.second.hwnd != hwnd) {
                    CVR_INFO("swapchain", "zweiter TV-Kandidat -- der aeltere bleibt der TV");
                    rec.isTv = false;
                    break;
                }
        dd->swapchains[*out] = std::move(rec);
    }
    return r;
}

VKAPI_ATTR void VKAPI_CALL DestroySwapchainKHR(VkDevice device, VkSwapchainKHR sc,
                                               const VkAllocationCallbacks* alloc) {
    DeviceData* dd = nullptr;
    bool wasTv = false;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        dd = deviceOf(device);
        if (dd) {
            auto it = dd->swapchains.find(sc);
            if (it != dd->swapchains.end()) { wasTv = it->second.isTv; dd->swapchains.erase(it); }
        }
    }
    if (wasTv) {
        CVR_INFO("swapchain", "tv destroyed -- VR-Ausgabe wird beendet");
        // Das Profil ueberlebt einen reinen Swapchain-Neuaufbau. Es wird erst
        // beim Titelwechsel oder beim Abbau des Geraets entladen.
        teardown(false);
        g.initTried = false;      // ein neuer TV darf neu aufbauen
        g.tornDown = false;
        g.failed = false;
        g.stopped = false;
    }
    if (dd) dd->DestroySwapchain(device, sc, alloc);
}

VKAPI_ATTR VkResult VKAPI_CALL GetSwapchainImagesKHR(VkDevice device, VkSwapchainKHR sc,
                                                     uint32_t* count, VkImage* images) {
    DeviceData* dd = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        dd = deviceOf(device);
    }
    if (!dd) return VK_ERROR_INITIALIZATION_FAILED;
    const VkResult r = dd->GetSwapchainImages(device, sc, count, images);
    if (r == VK_SUCCESS && images && count) {
        std::lock_guard<std::mutex> lk(g_mtx);
        auto it = dd->swapchains.find(sc);
        if (it != dd->swapchains.end())
            it->second.images.assign(images, images + *count);
    }
    return r;
}

VKAPI_ATTR VkResult VKAPI_CALL CreateWin32SurfaceKHR(VkInstance instance,
                                                     const VkWin32SurfaceCreateInfoKHR* ci,
                                                     const VkAllocationCallbacks* alloc,
                                                     VkSurfaceKHR* out) {
    InstanceData* id = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        id = instanceOf(instance);
    }
    if (!id || !id->CreateWin32Surface) return VK_ERROR_INITIALIZATION_FAILED;
    const VkResult r = id->CreateWin32Surface(instance, ci, alloc, out);
    if (r == VK_SUCCESS) {
        std::lock_guard<std::mutex> lk(g_mtx);
        g_surfaces[*out] = ci->hwnd;
        describeWindow(ci->hwnd, "surface");
    }
    return r;
}

VKAPI_ATTR void VKAPI_CALL GetDeviceQueue(VkDevice device, uint32_t family,
                                          uint32_t index, VkQueue* out) {
    DeviceData* dd = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        dd = deviceOf(device);
    }
    if (!dd) return;
    dd->GetDeviceQueue(device, family, index, out);
    if (out && *out && dd->vk.queue == VK_NULL_HANDLE) {
        dd->vk.queue = *out;
        dd->vk.queueFamily = family;
        CVR_INFO("device.queue", "queue=%p family=%u index=%u", (void*)*out, family, index);
    }
}

// ---------------------------------------------------------------------------
// Instanz und Geraet
// ---------------------------------------------------------------------------

VKAPI_ATTR VkResult VKAPI_CALL LayerCreateInstance(const VkInstanceCreateInfo* ci,
                                                   const VkAllocationCallbacks* alloc,
                                                   VkInstance* out) {
    auto* chain = (VkLayerInstanceCreateInfo*)ci->pNext;
    while (chain && !(chain->sType == VK_STRUCTURE_TYPE_LOADER_INSTANCE_CREATE_INFO &&
                      chain->function == VK_LAYER_LINK_INFO))
        chain = (VkLayerInstanceCreateInfo*)chain->pNext;
    if (!chain) return VK_ERROR_INITIALIZATION_FAILED;

    PFN_vkGetInstanceProcAddr nextGipa = chain->u.pLayerInfo->pfnNextGetInstanceProcAddr;
    chain->u.pLayerInfo = chain->u.pLayerInfo->pNext;

    auto nextCreate = (PFN_vkCreateInstance)nextGipa(VK_NULL_HANDLE, "vkCreateInstance");
    if (!nextCreate) return VK_ERROR_INITIALIZATION_FAILED;

    // Instanzerweiterungen anfuegen, soweit vorhanden und noch nicht angefordert.
    std::vector<const char*> exts(ci->ppEnabledExtensionNames,
                                  ci->ppEnabledExtensionNames + ci->enabledExtensionCount);
    if (g.enabled) {
        auto enumInstExt = (PFN_vkEnumerateInstanceExtensionProperties)
            nextGipa(VK_NULL_HANDLE, "vkEnumerateInstanceExtensionProperties");
        std::vector<VkExtensionProperties> avail;
        if (enumInstExt) {
            uint32_t n = 0;
            enumInstExt(nullptr, &n, nullptr);
            avail.resize(n);
            if (n) enumInstExt(nullptr, &n, avail.data());
        }
        const char* wanted[] = {
            VK_KHR_EXTERNAL_MEMORY_CAPABILITIES_EXTENSION_NAME,
            VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_EXTENSION_NAME,
        };
        for (const char* w : wanted) {
            bool already = false;
            for (const char* e : exts) if (!std::strcmp(e, w)) { already = true; break; }
            bool present = false;
            for (const auto& a : avail) if (!std::strcmp(a.extensionName, w)) { present = true; break; }
            if (!already && present) { exts.push_back(w); CVR_INFO("instance.ext", "added=%s", w); }
            else if (!already && !present) CVR_WARN("instance.ext", "unavailable=%s", w);
        }
    }

    VkInstanceCreateInfo ci2 = *ci;
    ci2.enabledExtensionCount = (uint32_t)exts.size();
    ci2.ppEnabledExtensionNames = exts.data();

    const VkResult r = nextCreate(&ci2, alloc, out);
    if (r != VK_SUCCESS) return r;

    InstanceData id;
    id.instance = *out;
    id.gipa = nextGipa;
    id.DestroyInstance    = (PFN_vkDestroyInstance)nextGipa(*out, "vkDestroyInstance");
    id.CreateDevice       = (PFN_vkCreateDevice)nextGipa(*out, "vkCreateDevice");
    id.EnumDeviceExt      = (PFN_vkEnumerateDeviceExtensionProperties)nextGipa(*out, "vkEnumerateDeviceExtensionProperties");
    id.GetPhysMemProps    = (PFN_vkGetPhysicalDeviceMemoryProperties)nextGipa(*out, "vkGetPhysicalDeviceMemoryProperties");
    id.GetPhysProps2      = (PFN_vkGetPhysicalDeviceProperties2)nextGipa(*out, "vkGetPhysicalDeviceProperties2");
    if (!id.GetPhysProps2)
        id.GetPhysProps2  = (PFN_vkGetPhysicalDeviceProperties2)nextGipa(*out, "vkGetPhysicalDeviceProperties2KHR");
    id.GetSurfCaps        = (PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR)nextGipa(*out, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR");
    id.CreateWin32Surface = (PFN_vkCreateWin32SurfaceKHR)nextGipa(*out, "vkCreateWin32SurfaceKHR");
    id.DestroySurface     = (PFN_vkDestroySurfaceKHR)nextGipa(*out, "vkDestroySurfaceKHR");

    {
        std::lock_guard<std::mutex> lk(g_mtx);
        g_instances[dispatchKey(*out)] = id;
    }
    CVR_INFO("instance", "created=%p apiVersion=0x%08x extensions=%zu",
             (void*)*out, ci->pApplicationInfo ? ci->pApplicationInfo->apiVersion : 0, exts.size());
    return r;
}

VKAPI_ATTR void VKAPI_CALL LayerDestroyInstance(VkInstance instance,
                                                const VkAllocationCallbacks* alloc) {
    PFN_vkDestroyInstance down = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        auto it = g_instances.find(dispatchKey(instance));
        if (it != g_instances.end()) { down = it->second.DestroyInstance; g_instances.erase(it); }
    }
    if (down) down(instance, alloc);
}

VKAPI_ATTR VkResult VKAPI_CALL LayerCreateDevice(VkPhysicalDevice phys,
                                                 const VkDeviceCreateInfo* ci,
                                                 const VkAllocationCallbacks* alloc,
                                                 VkDevice* out) {
    auto* chain = (VkLayerDeviceCreateInfo*)ci->pNext;
    while (chain && !(chain->sType == VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO &&
                      chain->function == VK_LAYER_LINK_INFO))
        chain = (VkLayerDeviceCreateInfo*)chain->pNext;
    if (!chain) return VK_ERROR_INITIALIZATION_FAILED;

    PFN_vkGetInstanceProcAddr nextGipa = chain->u.pLayerInfo->pfnNextGetInstanceProcAddr;
    PFN_vkGetDeviceProcAddr   nextGdpa = chain->u.pLayerInfo->pfnNextGetDeviceProcAddr;
    chain->u.pLayerInfo = chain->u.pLayerInfo->pNext;

    // Rueckruf, mit dem die Ladeschicht dispatchbare Objekte einrichtet.
    PFN_vkSetDeviceLoaderData setLoaderData = nullptr;
    {
        auto* cb = (VkLayerDeviceCreateInfo*)ci->pNext;
        while (cb && !(cb->sType == VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO &&
                       cb->function == VK_LOADER_DATA_CALLBACK))
            cb = (VkLayerDeviceCreateInfo*)cb->pNext;
        if (cb) setLoaderData = cb->u.pfnSetDeviceLoaderData;
    }

    InstanceData* id = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        id = instanceOf(phys);
    }

    // Die Geraeteerweiterungen fuer externen Speicher anfuegen. Cemu fordert
    // sie nicht an -- es kennt sie nicht. Ohne diesen Eingriff ist Pfad B
    // unmoeglich.
    std::vector<const char*> exts(ci->ppEnabledExtensionNames,
                                  ci->ppEnabledExtensionNames + ci->enabledExtensionCount);
    bool externalOk = false;
    bool keyedMutex = false;
    if (g.enabled && id && id->EnumDeviceExt) {
        uint32_t n = 0;
        id->EnumDeviceExt(phys, nullptr, &n, nullptr);
        std::vector<VkExtensionProperties> avail(n);
        if (n) id->EnumDeviceExt(phys, nullptr, &n, avail.data());
        auto have = [&](const char* w) {
            for (const auto& a : avail) if (!std::strcmp(a.extensionName, w)) return true;
            return false;
        };
        auto already = [&](const char* w) {
            for (const char* e : exts) if (!std::strcmp(e, w)) return true;
            return false;
        };
        struct { const char* name; bool required; } want[] = {
            { VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME,           true  },
            { VK_KHR_EXTERNAL_MEMORY_WIN32_EXTENSION_NAME,     true  },
            { VK_KHR_DEDICATED_ALLOCATION_EXTENSION_NAME,      true  },
            { VK_KHR_GET_MEMORY_REQUIREMENTS_2_EXTENSION_NAME, true  },
            { VK_KHR_WIN32_KEYED_MUTEX_EXTENSION_NAME,         false },
        };
        bool allReq = true;
        for (auto& w : want) {
            const bool h = have(w.name);
            const bool wasAlready = already(w.name);
            const bool add = h && !wasAlready;
            if (add) exts.push_back(w.name);
            if (!h && w.required) allReq = false;
            if (h && !std::strcmp(w.name, VK_KHR_WIN32_KEYED_MUTEX_EXTENSION_NAME)) keyedMutex = true;
            CVR_INFO("device.ext", "name=%s available=%d requestedByApp=%d added=%d required=%d",
                     w.name, (int)h, (int)wasAlready, (int)add, (int)w.required);
        }
        externalOk = allReq;
        if (!allReq) CVR_ERR("device.ext", "reason=required_extensions_missing");
    }

    VkDeviceCreateInfo ci2 = *ci;
    ci2.enabledExtensionCount = (uint32_t)exts.size();
    ci2.ppEnabledExtensionNames = exts.data();

    // Cemu upstream 61484598: protect streamout/dynamic uniform accesses.
    // The pinned Cemu 2.6 uses legacy pEnabledFeatures. Apply the upstream
    // device-wide fallback here without changing its shader/camera code.
    VkPhysicalDeviceFeatures robustFeatures{};
    bool robustEnabled = false;
    if (envFlag("CEMUVR_MARIO_ROBUST_BUFFERS", true) && ci->pEnabledFeatures) {
        auto getFeatures = (PFN_vkGetPhysicalDeviceFeatures)nextGipa(
            id ? id->instance : VK_NULL_HANDLE, "vkGetPhysicalDeviceFeatures");
        VkPhysicalDeviceFeatures available{};
        if (getFeatures) getFeatures(phys, &available);
        if (available.robustBufferAccess) {
            robustFeatures = *ci->pEnabledFeatures;
            robustFeatures.robustBufferAccess = VK_TRUE;
            ci2.pEnabledFeatures = &robustFeatures;
            robustEnabled = true;
        }
    }
    if (envFlag("CEMUVR_MARIO_ROBUST_BUFFERS", true))
        CVR_INFO("mario.robust", "requested=1 enabled=%d legacyFeatures=%d original=%d",
                 int(robustEnabled), int(ci->pEnabledFeatures != nullptr),
                 ci->pEnabledFeatures ? int(ci->pEnabledFeatures->robustBufferAccess) : -1);

    auto nextCreate = (PFN_vkCreateDevice)nextGipa(id ? id->instance : VK_NULL_HANDLE, "vkCreateDevice");
    if (!nextCreate) return VK_ERROR_INITIALIZATION_FAILED;
    VkResult r = nextCreate(phys, &ci2, alloc, out);
    if (r != VK_SUCCESS) {
        // Wenn das Anfuegen der Grund war, ohne die Zusaetze erneut versuchen --
        // Cemu muss auf jeden Fall starten koennen.
        CVR_ERR("device", "op=vkCreateDevice result=%s -- erneuter Versuch ohne Zusaetze",
                vkResultName(r));
        VkDeviceCreateInfo fallback = *ci;
        if (robustEnabled) fallback.pEnabledFeatures = &robustFeatures;
        r = nextCreate(phys, &fallback, alloc, out);
        externalOk = false;
        keyedMutex = false;
        if (r != VK_SUCCESS) return r;
    }

    DeviceData dd;
    dd.device = *out;
    dd.phys   = phys;
    dd.inst   = id;
    dd.gdpa   = nextGdpa;
    dd.SetDeviceLoaderData = setLoaderData;
    dd.externalMemoryEnabled = externalOk;

    dd.DestroyDevice       = (PFN_vkDestroyDevice)nextGdpa(*out, "vkDestroyDevice");
    dd.GetDeviceQueue      = (PFN_vkGetDeviceQueue)nextGdpa(*out, "vkGetDeviceQueue");
    dd.CreateSwapchain     = (PFN_vkCreateSwapchainKHR)nextGdpa(*out, "vkCreateSwapchainKHR");
    dd.DestroySwapchain    = (PFN_vkDestroySwapchainKHR)nextGdpa(*out, "vkDestroySwapchainKHR");
    dd.GetSwapchainImages  = (PFN_vkGetSwapchainImagesKHR)nextGdpa(*out, "vkGetSwapchainImagesKHR");
    dd.QueuePresent        = (PFN_vkQueuePresentKHR)nextGdpa(*out, "vkQueuePresentKHR");
    dd.CmdClearColorImage   = (PFN_vkCmdClearColorImage)nextGdpa(*out, "vkCmdClearColorImage");
    dd.CmdClearAttachments  = (PFN_vkCmdClearAttachments)nextGdpa(*out, "vkCmdClearAttachments");
    dd.CreateImage          = (PFN_vkCreateImage)nextGdpa(*out, "vkCreateImage");
    dd.DestroyImage         = (PFN_vkDestroyImage)nextGdpa(*out, "vkDestroyImage");

    VkFns& f = dd.vk.fn;
    f.GetDeviceProcAddr            = nextGdpa;
    f.CreateImage                  = (PFN_vkCreateImage)nextGdpa(*out, "vkCreateImage");
    f.DestroyImage                 = (PFN_vkDestroyImage)nextGdpa(*out, "vkDestroyImage");
    f.GetImageMemoryRequirements   = (PFN_vkGetImageMemoryRequirements)nextGdpa(*out, "vkGetImageMemoryRequirements");
    f.AllocateMemory               = (PFN_vkAllocateMemory)nextGdpa(*out, "vkAllocateMemory");
    f.FreeMemory                   = (PFN_vkFreeMemory)nextGdpa(*out, "vkFreeMemory");
    f.BindImageMemory              = (PFN_vkBindImageMemory)nextGdpa(*out, "vkBindImageMemory");
    f.CreateCommandPool            = (PFN_vkCreateCommandPool)nextGdpa(*out, "vkCreateCommandPool");
    f.DestroyCommandPool           = (PFN_vkDestroyCommandPool)nextGdpa(*out, "vkDestroyCommandPool");
    f.AllocateCommandBuffers       = (PFN_vkAllocateCommandBuffers)nextGdpa(*out, "vkAllocateCommandBuffers");
    f.BeginCommandBuffer           = (PFN_vkBeginCommandBuffer)nextGdpa(*out, "vkBeginCommandBuffer");
    f.EndCommandBuffer             = (PFN_vkEndCommandBuffer)nextGdpa(*out, "vkEndCommandBuffer");
    f.ResetCommandBuffer           = (PFN_vkResetCommandBuffer)nextGdpa(*out, "vkResetCommandBuffer");
    f.CmdPipelineBarrier           = (PFN_vkCmdPipelineBarrier)nextGdpa(*out, "vkCmdPipelineBarrier");
    f.CmdCopyImage                 = (PFN_vkCmdCopyImage)nextGdpa(*out, "vkCmdCopyImage");
    f.QueueSubmit                  = (PFN_vkQueueSubmit)nextGdpa(*out, "vkQueueSubmit");
    f.QueueWaitIdle                = (PFN_vkQueueWaitIdle)nextGdpa(*out, "vkQueueWaitIdle");
    f.CreateFence                  = (PFN_vkCreateFence)nextGdpa(*out, "vkCreateFence");
    f.DestroyFence                 = (PFN_vkDestroyFence)nextGdpa(*out, "vkDestroyFence");
    f.WaitForFences                = (PFN_vkWaitForFences)nextGdpa(*out, "vkWaitForFences");
    f.ResetFences                  = (PFN_vkResetFences)nextGdpa(*out, "vkResetFences");
    f.CreateSemaphore              = (PFN_vkCreateSemaphore)nextGdpa(*out, "vkCreateSemaphore");
    f.DestroySemaphore             = (PFN_vkDestroySemaphore)nextGdpa(*out, "vkDestroySemaphore");
    f.GetMemoryWin32HandleProperties =
        (PFN_vkGetMemoryWin32HandlePropertiesKHR)nextGdpa(*out, "vkGetMemoryWin32HandlePropertiesKHR");
    f.GetPhysicalDeviceMemoryProperties = id ? id->GetPhysMemProps : nullptr;
    f.GetPhysicalDeviceFormatProperties = id ? (PFN_vkGetPhysicalDeviceFormatProperties)id->gipa(id->instance,"vkGetPhysicalDeviceFormatProperties") : nullptr;
    f.GetPhysicalDeviceProperties2      = id ? id->GetPhysProps2 : nullptr;

    dd.vk.instance = id ? id->instance : VK_NULL_HANDLE;
    dd.vk.phys = phys;
    dd.vk.device = *out;
    dd.vk.keyedMutex = keyedMutex;

    {
        std::lock_guard<std::mutex> lk(g_mtx);
        g_devices[dispatchKey(*out)] = dd;
    }

    // LUID des Geraets protokollieren: die D3D11-Seite MUSS derselbe Adapter sein.
    if (id && id->GetPhysProps2) {
        VkPhysicalDeviceIDProperties idp{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES};
        VkPhysicalDeviceProperties2 p2{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2};
        p2.pNext = &idp;
        id->GetPhysProps2(phys, &p2);
        LUID l{};
        std::memcpy(&l, idp.deviceLUID, sizeof(LUID));
        CVR_INFO("device", "created=%p gpu=\"%s\" luidValid=%d luid=%08lx:%08lx "
                           "externalMemory=%d keyedMutex=%d dispatchComplete=%d",
                 (void*)*out, p2.properties.deviceName, (int)idp.deviceLUIDValid,
                 (unsigned long)l.HighPart, (unsigned long)l.LowPart,
                 (int)externalOk, (int)keyedMutex, (int)f.complete());
    }
    return r;
}

VKAPI_ATTR void VKAPI_CALL LayerDestroyDevice(VkDevice device, const VkAllocationCallbacks* alloc) {
    // Erst abbauen, DANN die Sperre nehmen: teardown() wartet auf die GPU, und
    // das darf nicht unter dem Mutex geschehen, den auch vkQueuePresentKHR
    // braucht.
    // Bedingungslos abbauen. Frueher haengte das an `g.dev == &it->second` --
    // aber ein vorangegangener Swapchain-Abbau hat g.dev bereits genullt, und
    // dann wurde profile_shutdown nie gerufen. teardown() ist mehrfach
    // aufrufbar; der Profilabbau darin ebenfalls.
    teardown(true);
    PFN_vkDestroyDevice down = nullptr;
    {
        std::lock_guard<std::mutex> lk(g_mtx);
        auto it = g_devices.find(dispatchKey(device));
        if (it != g_devices.end()) { it->second.hudInterop.destroyVulkanSide(it->second.vk); it->second.hudInterop.destroyD3D11Side(); it->second.referenceHud.destroy(it->second.vk); it->second.referencePairImages.destroy(it->second.vk); it->second.referenceSnapshots.destroy(it->second.vk); down = it->second.DestroyDevice; g_devices.erase(it); }
    }
    if (down) down(device, alloc);
}

// ---------------------------------------------------------------------------
// Einsprungpunkte
// ---------------------------------------------------------------------------

struct Hook { const char* name; PFN_vkVoidFunction fn; };

const Hook kHooks[] = {
    { "vkCreateInstance",       (PFN_vkVoidFunction)LayerCreateInstance    },
    { "vkDestroyInstance",      (PFN_vkVoidFunction)LayerDestroyInstance   },
    { "vkCreateDevice",         (PFN_vkVoidFunction)LayerCreateDevice      },
    { "vkDestroyDevice",        (PFN_vkVoidFunction)LayerDestroyDevice     },
    { "vkGetDeviceQueue",       (PFN_vkVoidFunction)GetDeviceQueue         },
    { "vkCreateWin32SurfaceKHR",(PFN_vkVoidFunction)CreateWin32SurfaceKHR  },
    { "vkCreateSwapchainKHR",   (PFN_vkVoidFunction)CreateSwapchainKHR     },
    { "vkDestroySwapchainKHR",  (PFN_vkVoidFunction)DestroySwapchainKHR    },
    { "vkGetSwapchainImagesKHR",(PFN_vkVoidFunction)GetSwapchainImagesKHR  },
    { "vkQueuePresentKHR",      (PFN_vkVoidFunction)QueuePresentKHR        },
    { "vkCreateImage",          (PFN_vkVoidFunction)ReferenceCreateImage   },
    { "vkDestroyImage",         (PFN_vkVoidFunction)ReferenceDestroyImage  },
    { "vkCmdClearColorImage",   (PFN_vkVoidFunction)ReferenceClearColor    },
    { "vkCmdClearAttachments",  (PFN_vkVoidFunction)ReferenceClearAttachments },
};

PFN_vkVoidFunction findHook(const char* name) {
    for (const auto& h : kHooks) if (!std::strcmp(h.name, name)) return h.fn;
    return nullptr;
}

} // namespace

extern "C" {

__declspec(dllexport) VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
cemuvr_GetInstanceProcAddr(VkInstance instance, const char* name) {
    if (auto f = findHook(name)) return f;
    if (!std::strcmp(name, "vkGetInstanceProcAddr"))
        return (PFN_vkVoidFunction)cemuvr_GetInstanceProcAddr;
    std::lock_guard<std::mutex> lk(g_mtx);
    if (!instance) return nullptr;
    auto* id = instanceOf(instance);
    return (id && id->gipa) ? id->gipa(instance, name) : nullptr;
}

__declspec(dllexport) VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
cemuvr_GetDeviceProcAddr(VkDevice device, const char* name) {
    if (auto f = findHook(name)) return f;
    if (!std::strcmp(name, "vkGetDeviceProcAddr"))
        return (PFN_vkVoidFunction)cemuvr_GetDeviceProcAddr;
    std::lock_guard<std::mutex> lk(g_mtx);
    if (!device) return nullptr;
    auto* dd = deviceOf(device);
    return (dd && dd->gdpa) ? dd->gdpa(device, name) : nullptr;
}

VKAPI_ATTR VkResult VKAPI_CALL
vkNegotiateLoaderLayerInterfaceVersion(VkNegotiateLayerInterface* pVersion) {
    if (!pVersion) return VK_ERROR_INITIALIZATION_FAILED;
    if (pVersion->loaderLayerInterfaceVersion > 2) pVersion->loaderLayerInterfaceVersion = 2;
    pVersion->pfnGetInstanceProcAddr       = cemuvr_GetInstanceProcAddr;
    pVersion->pfnGetDeviceProcAddr         = cemuvr_GetDeviceProcAddr;
    pVersion->pfnGetPhysicalDeviceProcAddr = nullptr;

    g.enabled = envFlag("CEMUVR_ENABLE", false);
    const std::string log = envStr("CEMUVR_LOG", "cemuvr_layer.log");
    Diag::get().open(log.c_str());
    Diag::get().setEcho(false);
    Diag::get().setTrace(envFlag("CEMUVR_TRACE", false));
    g.dualOutput = envFlag("CEMUVR_DUAL_OUTPUT_PROBE", false);

    wchar_t exe[MAX_PATH]{};
    GetModuleFileNameW(nullptr, exe, MAX_PATH);
    CVR_INFO("layer.load", "version=%u enabled=%d exe=\"%ls\" log=\"%s\"",
             pVersion->loaderLayerInterfaceVersion, (int)g.enabled, exe, log.c_str());

    if (g.enabled) {
        g.bridge.attach();
        // Profilordner: CEMUVR_PROFILE_DIR, sonst <Verzeichnis dieser DLL>\profiles
        std::string cfg = envStr("CEMUVR_PROFILE_DIR", "");
        std::wstring dir;
        if (!cfg.empty()) {
            dir.assign(cfg.begin(), cfg.end());
        } else {
            // Verzeichnis DIESER DLL bestimmen. Der Zeiger auf eine eigene
            // statische Groesse ist der zuverlaessige Weg -- eine Funktion
            // koennte ueber eine Sprungtabelle liegen.
            static const int kSelfAnchor = 0;
            const wchar_t kSep[] = { L'\\', L'/', 0 };
            wchar_t self[MAX_PATH]{};
            HMODULE me = nullptr;
            const BOOL gotModule =
                GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                                   GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                   (LPCWSTR)&kSelfAnchor, &me);
            const DWORD gotName = gotModule ? GetModuleFileNameW(me, self, MAX_PATH) : 0;
            std::wstring p(self);
            const size_t slash = p.find_last_of(kSep);
            if (gotName && slash != std::wstring::npos) {
                dir = p.substr(0, slash);
                dir.push_back(L'\\');
                dir += L"profiles";
            }
            CVR_INFO("profile.dir", "self=\"%ls\" gotModule=%d gotName=%lu",
                     self, (int)gotModule, (unsigned long)gotName);
        }
        if (dir.empty())
            CVR_ERR("profile.dir", "Profilordner nicht bestimmbar -- "
                                   "CEMUVR_PROFILE_DIR setzen");
        g.profiles.setDirectory(dir);
    }
    return VK_SUCCESS;
}

} // extern "C"

BOOL APIENTRY DllMain(HMODULE, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_DETACH) {
        // Kein teardown() hier: beim Prozessende sind Treiber und Ladeschicht
        // moeglicherweise schon abgebaut. Ein Zugriff darauf waere genau die
        // Art Verklemmung, die vermieden werden soll.
        Diag::get().close();
    }
    return TRUE;
}
