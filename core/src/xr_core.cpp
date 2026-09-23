// CemuVR-Kern -- Implementierung des allgemeinen OpenXR-Unterbaus.
#include "cemuvr/xr_core.h"
#include "cemuvr/bildlage.h"
#include "cemuvr/diag.h"

#include <dxgi1_2.h>
#include <cmath>
#include <cstring>
#include <algorithm>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

namespace cemuvr {

namespace {

const char* xrResultName(XrInstance inst, XrResult r) {
    static char buf[XR_MAX_RESULT_STRING_SIZE];
    if (inst != XR_NULL_HANDLE && XR_SUCCEEDED(xrResultToString(inst, r, buf))) return buf;
    std::snprintf(buf, sizeof(buf), "XrResult(%d)", (int)r);
    return buf;
}

#define XR_CHECK(inst, expr, what)                                                   \
    do {                                                                             \
        XrResult _r = (expr);                                                        \
        if (XR_FAILED(_r)) {                                                         \
            CVR_ERR("xr.call", "op=%s result=%s", what, xrResultName(inst, _r));      \
            return false;                                                            \
        }                                                                            \
    } while (0)

} // namespace

// ---------------------------------------------------------------------------
// Matrizen
// ---------------------------------------------------------------------------

CemuVR_Mat4 makeProjection(const XrFovf& fov, float nearZ, float farZ) {
    const float l = std::tan(fov.angleLeft);
    const float r = std::tan(fov.angleRight);
    const float d = std::tan(fov.angleDown);
    const float u = std::tan(fov.angleUp);

    const float w = r - l;
    const float h = u - d;
    const float dz = farZ - nearZ;

    CemuVR_Mat4 m{};
    std::memset(&m, 0, sizeof(m));
    m.m[0][0] = 2.0f / w;
    m.m[0][2] = (r + l) / w;
    m.m[1][1] = 2.0f / h;
    m.m[1][2] = (u + d) / h;
    m.m[2][2] = -(farZ + nearZ) / dz;
    m.m[2][3] = -(2.0f * farZ * nearZ) / dz;
    m.m[3][2] = -1.0f;
    m.m[3][3] = 0.0f;
    return m;
}

CemuVR_Mat4 makeView(const XrPosef& pose, float worldScale) {
    // Rotationsmatrix aus dem Quaternion.
    const float x = pose.orientation.x, y = pose.orientation.y;
    const float z = pose.orientation.z, w = pose.orientation.w;
    const float xx = x*x, yy = y*y, zz = z*z;
    const float xy = x*y, xz = x*z, yz = y*z;
    const float wx = w*x, wy = w*y, wz = w*z;

    // R = Weltrotation des Auges
    float R[3][3];
    R[0][0] = 1.0f - 2.0f*(yy + zz); R[0][1] = 2.0f*(xy - wz);        R[0][2] = 2.0f*(xz + wy);
    R[1][0] = 2.0f*(xy + wz);        R[1][1] = 1.0f - 2.0f*(xx + zz); R[1][2] = 2.0f*(yz - wx);
    R[2][0] = 2.0f*(xz - wy);        R[2][1] = 2.0f*(yz + wx);        R[2][2] = 1.0f - 2.0f*(xx + yy);

    const float px = pose.position.x * worldScale;
    const float py = pose.position.y * worldScale;
    const float pz = pose.position.z * worldScale;

    // View = inverse(T * R) = R^T * inverse(T)
    CemuVR_Mat4 m{};
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 3; ++j)
            m.m[i][j] = R[j][i];              // transponiert
    m.m[0][3] = -(R[0][0]*px + R[1][0]*py + R[2][0]*pz);
    m.m[1][3] = -(R[0][1]*px + R[1][1]*py + R[2][1]*pz);
    m.m[2][3] = -(R[0][2]*px + R[1][2]*py + R[2][2]*pz);
    m.m[3][0] = m.m[3][1] = m.m[3][2] = 0.0f;
    m.m[3][3] = 1.0f;
    return m;
}

// ---------------------------------------------------------------------------
// Lebenszyklus
// ---------------------------------------------------------------------------

XrCore::~XrCore() { shutdown(); }

bool XrCore::initialise(const XrCoreConfig& cfg) {
    m_cfg = cfg;

    // 1. Runtime-Erkennung ueber die verfuegbaren Erweiterungen.
    uint32_t extCount = 0;
    XR_CHECK(XR_NULL_HANDLE, xrEnumerateInstanceExtensionProperties(nullptr, 0, &extCount, nullptr),
             "xrEnumerateInstanceExtensionProperties(count)");
    std::vector<XrExtensionProperties> exts(extCount, {XR_TYPE_EXTENSION_PROPERTIES});
    XR_CHECK(XR_NULL_HANDLE,
             xrEnumerateInstanceExtensionProperties(nullptr, extCount, &extCount, exts.data()),
             "xrEnumerateInstanceExtensionProperties");

    bool haveD3D11 = false;
    bool haveVk1 = false, haveVk2 = false;
    for (const auto& e : exts) {
        CVR_TRACE("xr.ext", "name=%s version=%u", e.extensionName, e.extensionVersion);
        if (std::strcmp(e.extensionName, XR_KHR_D3D11_ENABLE_EXTENSION_NAME) == 0) haveD3D11 = true;
        if (std::strcmp(e.extensionName, "XR_KHR_vulkan_enable")  == 0) haveVk1 = true;
        if (std::strcmp(e.extensionName, "XR_KHR_vulkan_enable2") == 0) haveVk2 = true;
    }
    m_runtimeVulkan = haveVk1 || haveVk2;
    CVR_INFO("xr.ext.count", "n=%u d3d11=%d vulkan_enable=%d vulkan_enable2=%d",
             extCount, (int)haveD3D11, (int)haveVk1, (int)haveVk2);
    // Die Pfadentscheidung wird bei JEDEM Lauf protokolliert, nicht nur einmal
    // im Dokument -- so steht im Beleg, welcher Pfad tatsaechlich moeglich war.
    CVR_INFO("path.decision",
             "chosen=B_d3d11_interop pathA_available=%d reason=%s",
             (int)m_runtimeVulkan,
             m_runtimeVulkan ? "runtime_offers_vulkan_but_core_is_d3d11"
                             : "runtime_offers_no_vulkan_binding");

    if (!haveD3D11) {
        CVR_ERR("xr.init", "reason=missing_extension name=%s", XR_KHR_D3D11_ENABLE_EXTENSION_NAME);
        m_state = XrState::Failed;
        return false;
    }

    const char* enabled[] = { XR_KHR_D3D11_ENABLE_EXTENSION_NAME };

    XrInstanceCreateInfo ici{XR_TYPE_INSTANCE_CREATE_INFO};
    std::snprintf(ici.applicationInfo.applicationName,
                  sizeof(ici.applicationInfo.applicationName), "%s", m_cfg.appName.c_str());
    std::snprintf(ici.applicationInfo.engineName,
                  sizeof(ici.applicationInfo.engineName), "%s", m_cfg.engineName.c_str());
    ici.applicationInfo.applicationVersion = 1;
    ici.applicationInfo.engineVersion = 1;
    ici.enabledExtensionCount = 1;
    ici.enabledExtensionNames = enabled;

    // Die Fassung wird AUSGEHANDELT, nicht festgeschrieben.
    //
    // Frueher stand hier fest XR_CURRENT_API_VERSION -- also die Fassung der
    // Kopfdatei, gegen die dieser Kern gebaut wurde. Nicht jede Laufzeit
    // spricht sie: VirtualDesktopXR 1.0.10 lehnt 1.1 mit
    // XR_ERROR_API_VERSION_UNSUPPORTED ab. Der Kern brach dann vor der
    // Instanzerzeugung ab, baute die VR-Ausgabe sofort wieder ab und band nie
    // ein Spielprofil an -- es kam kein Bild im Headset an, waehrend Cemu
    // aeusserlich normal weiterlief.
    //
    // Gemessen mit tools\xr_versionsprobe.cpp:
    //
    //   Fassung   VirtualDesktopXR 1.0.10      FakeHMD 0.1.0
    //   1.1.62    API_VERSION_UNSUPPORTED      OK
    //   1.1.0     API_VERSION_UNSUPPORTED      OK
    //   1.0.62    OK, Headset gefunden         OK
    //   1.0.34    OK, Headset gefunden         OK
    //   1.0.0     OK, Headset gefunden         OK
    //
    // Mit und ohne XR_KHR_D3D11_enable dasselbe Bild; an der Erweiterung liegt
    // es also nicht. Ein Simulator kann diese Eigenschaft prinzipbedingt nicht
    // beurteilen -- sie haengt an der fremden Laufzeit, nicht am Kern.
    //
    // Drei Eigenschaften dieses Wegs sind Absicht:
    //   * der ERSTE Versuch ist unveraendert XR_CURRENT_API_VERSION. Eine
    //     Laufzeit, die das heute annimmt, bekommt weiterhin genau das;
    //   * heruntergegangen wird NUR bei XR_ERROR_API_VERSION_UNSUPPORTED.
    //     Jeder andere Fehler bricht sofort ab und bleibt sichtbar, statt
    //     hinter stillen Wiederholungen zu verschwinden;
    //   * jeder Versuch wird protokolliert. Im Beleg steht danach, welche
    //     Fassung die Laufzeit tatsaechlich angenommen hat.
    static const XrVersion kApiVersionen[] = {
        XR_CURRENT_API_VERSION,
        XR_MAKE_VERSION(1, 0, XR_VERSION_PATCH(XR_CURRENT_API_VERSION)),
        XR_MAKE_VERSION(1, 0, 0),
    };
    XrResult instRes = XR_ERROR_API_VERSION_UNSUPPORTED;
    XrVersion apiGenommen = 0;
    bool ersterVersuch = true;
    for (XrVersion v : kApiVersionen) {
        // Bei Patchstand 0 fallen die letzten beiden Eintraege zusammen.
        if (!ersterVersuch && v == apiGenommen) continue;
        ersterVersuch = false;
        ici.applicationInfo.apiVersion = v;
        instRes = xrCreateInstance(&ici, &m_instance);
        apiGenommen = v;
        CVR_INFO("xr.apiversion", "versucht=%llu.%llu.%llu result=%s",
                 (unsigned long long)XR_VERSION_MAJOR(v),
                 (unsigned long long)XR_VERSION_MINOR(v),
                 (unsigned long long)XR_VERSION_PATCH(v),
                 xrResultName(XR_NULL_HANDLE, instRes));
        if (instRes != XR_ERROR_API_VERSION_UNSUPPORTED) break;
    }
    XR_CHECK(XR_NULL_HANDLE, instRes, "xrCreateInstance");
    CVR_INFO("xr.apiversion", "genommen=%llu.%llu.%llu",
             (unsigned long long)XR_VERSION_MAJOR(apiGenommen),
             (unsigned long long)XR_VERSION_MINOR(apiGenommen),
             (unsigned long long)XR_VERSION_PATCH(apiGenommen));

    XrInstanceProperties ip{XR_TYPE_INSTANCE_PROPERTIES};
    if (XR_SUCCEEDED(xrGetInstanceProperties(m_instance, &ip))) {
        m_runtimeName = ip.runtimeName;
        CVR_INFO("xr.runtime", "name=\"%s\" version=%llu.%llu.%llu",
                 ip.runtimeName,
                 (unsigned long long)XR_VERSION_MAJOR(ip.runtimeVersion),
                 (unsigned long long)XR_VERSION_MINOR(ip.runtimeVersion),
                 (unsigned long long)XR_VERSION_PATCH(ip.runtimeVersion));
    }

    XrSystemGetInfo sgi{XR_TYPE_SYSTEM_GET_INFO};
    sgi.formFactor = XR_FORM_FACTOR_HEAD_MOUNTED_DISPLAY;
    XR_CHECK(m_instance, xrGetSystem(m_instance, &sgi, &m_systemId), "xrGetSystem");

    XrSystemProperties sp{XR_TYPE_SYSTEM_PROPERTIES};
    if (XR_SUCCEEDED(xrGetSystemProperties(m_instance, m_systemId, &sp))) {
        CVR_INFO("xr.system", "name=\"%s\" vendor=%u maxW=%u maxH=%u layers=%u orient=%d pos=%d",
                 sp.systemName, sp.vendorId,
                 sp.graphicsProperties.maxSwapchainImageWidth,
                 sp.graphicsProperties.maxSwapchainImageHeight,
                 sp.graphicsProperties.maxLayerCount,
                 (int)sp.trackingProperties.orientationTracking,
                 (int)sp.trackingProperties.positionTracking);
    }

    // View-Konfiguration
    uint32_t viewCount = 0;
    XR_CHECK(m_instance,
             xrEnumerateViewConfigurationViews(m_instance, m_systemId,
                 XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO, 0, &viewCount, nullptr),
             "xrEnumerateViewConfigurationViews(count)");
    if (viewCount != 2) {
        CVR_ERR("xr.viewconfig", "reason=unexpected_view_count n=%u", viewCount);
        m_state = XrState::Failed;
        return false;
    }
    std::vector<XrViewConfigurationView> vcv(viewCount, {XR_TYPE_VIEW_CONFIGURATION_VIEW});
    XR_CHECK(m_instance,
             xrEnumerateViewConfigurationViews(m_instance, m_systemId,
                 XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO, viewCount, &viewCount, vcv.data()),
             "xrEnumerateViewConfigurationViews");

    m_eyeWidth  = m_cfg.eyeWidth  ? m_cfg.eyeWidth  : vcv[0].recommendedImageRectWidth;
    m_eyeHeight = m_cfg.eyeHeight ? m_cfg.eyeHeight : vcv[0].recommendedImageRectHeight;
    CVR_INFO("xr.viewconfig", "views=%u recW=%u recH=%u useW=%u useH=%u samples=%u",
             viewCount, vcv[0].recommendedImageRectWidth, vcv[0].recommendedImageRectHeight,
             m_eyeWidth, m_eyeHeight, vcv[0].recommendedSwapchainSampleCount);
    // Was das fuer die Schaerfe bedeutet, ausdruecklich und nicht zum
    // Ausrechnen: die Augenbildgroesse ist Cemus Fenstergroesse, das Auge der
    // Brille ist aber fast quadratisch. Was fehlt, wird gestreckt -- und
    // gestreckte Zeilen sind genau das, was als grobe Aufloesung auffaellt.
    if (m_eyeWidth && m_eyeHeight &&
        vcv[0].recommendedImageRectWidth && vcv[0].recommendedImageRectHeight) {
        const float sw = 100.0f * (float)vcv[0].recommendedImageRectWidth
                       / (float)m_eyeWidth;
        const float sh = 100.0f * (float)vcv[0].recommendedImageRectHeight
                       / (float)m_eyeHeight;
        CVR_INFO("xr.aufloesung",
                 "Streckung waagerecht %.0f%% senkrecht %.0f%% -- %s",
                 sw, sh,
                 (sh > 125.0f || sw > 125.0f)
                     ? "das Bild wird sichtbar aufgeblasen; mehr Schaerfe "
                       "braeuchte ein hoeher aufloesendes Quellbild"
                     : "im Rahmen");
    }

    for (auto& v : m_views) v = {XR_TYPE_VIEW};
    m_state = XrState::InstanceReady;
    return true;
}

bool XrCore::createSession(ID3D11Device* device) {
    if (m_state != XrState::InstanceReady) {
        CVR_ERR("xr.session", "reason=wrong_state state=%d", (int)m_state);
        return false;
    }

    auto pfnGetReq = (PFN_xrGetD3D11GraphicsRequirementsKHR)nullptr;
    XR_CHECK(m_instance,
             xrGetInstanceProcAddr(m_instance, "xrGetD3D11GraphicsRequirementsKHR",
                                   (PFN_xrVoidFunction*)&pfnGetReq),
             "xrGetInstanceProcAddr(xrGetD3D11GraphicsRequirementsKHR)");

    XrGraphicsRequirementsD3D11KHR req{XR_TYPE_GRAPHICS_REQUIREMENTS_D3D11_KHR};
    XR_CHECK(m_instance, pfnGetReq(m_instance, m_systemId, &req),
             "xrGetD3D11GraphicsRequirementsKHR");
    CVR_INFO("xr.gfxreq", "adapterLuid=%08lx:%08lx minFeatureLevel=0x%x",
             (unsigned long)req.adapterLuid.HighPart, (unsigned long)req.adapterLuid.LowPart,
             (unsigned)req.minFeatureLevel);

    if (device) {
        m_device = device;
        m_device->AddRef();
        m_ownDevice = false;
    } else {
        // Eigenes Geraet auf genau dem von OpenXR genannten Adapter.
        IDXGIFactory1* factory = nullptr;
        if (FAILED(CreateDXGIFactory1(__uuidof(IDXGIFactory1), (void**)&factory))) {
            CVR_ERR("d3d11.init", "reason=CreateDXGIFactory1_failed");
            return false;
        }
        IDXGIAdapter1* chosen = nullptr;
        for (UINT i = 0; ; ++i) {
            IDXGIAdapter1* a = nullptr;
            if (factory->EnumAdapters1(i, &a) == DXGI_ERROR_NOT_FOUND) break;
            DXGI_ADAPTER_DESC1 d{};
            a->GetDesc1(&d);
            if (d.AdapterLuid.HighPart == req.adapterLuid.HighPart &&
                d.AdapterLuid.LowPart  == req.adapterLuid.LowPart) {
                chosen = a;
                CVR_INFO("d3d11.adapter", "match=1 index=%u desc=\"%ls\"", i, d.Description);
                break;
            }
            a->Release();
        }
        if (!chosen) {
            CVR_WARN("d3d11.adapter", "match=0 fallback=default");
        }
        D3D_FEATURE_LEVEL want[] = { D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0 };
        D3D_FEATURE_LEVEL got{};
        HRESULT hr = D3D11CreateDevice(chosen,
                                       chosen ? D3D_DRIVER_TYPE_UNKNOWN : D3D_DRIVER_TYPE_HARDWARE,
                                       nullptr, 0, want, 2, D3D11_SDK_VERSION,
                                       &m_device, &got, &m_ctx);
        if (chosen) chosen->Release();
        factory->Release();
        if (FAILED(hr)) {
            CVR_ERR("d3d11.init", "reason=D3D11CreateDevice_failed hr=0x%08lx", (unsigned long)hr);
            return false;
        }
        m_ownDevice = true;
        CVR_INFO("d3d11.init", "featureLevel=0x%x own=1", (unsigned)got);
    }
    if (!m_ctx) m_device->GetImmediateContext(&m_ctx);

    XrGraphicsBindingD3D11KHR binding{XR_TYPE_GRAPHICS_BINDING_D3D11_KHR};
    binding.device = m_device;

    XrSessionCreateInfo sci{XR_TYPE_SESSION_CREATE_INFO};
    sci.next = &binding;
    sci.systemId = m_systemId;
    XR_CHECK(m_instance, xrCreateSession(m_instance, &sci, &m_session), "xrCreateSession");
    CVR_INFO("xr.session", "created=1");

    XrReferenceSpaceCreateInfo rs{XR_TYPE_REFERENCE_SPACE_CREATE_INFO};
    rs.poseInReferenceSpace.orientation.w = 1.0f;
    rs.referenceSpaceType = XR_REFERENCE_SPACE_TYPE_STAGE;
    if (XR_FAILED(xrCreateReferenceSpace(m_session, &rs, &m_stageSpace))) {
        CVR_WARN("xr.space", "stage=unavailable fallback=local");
        rs.referenceSpaceType = XR_REFERENCE_SPACE_TYPE_LOCAL;
        XR_CHECK(m_instance, xrCreateReferenceSpace(m_session, &rs, &m_stageSpace),
                 "xrCreateReferenceSpace(LOCAL)");
    }
    m_stageSpaceType=rs.referenceSpaceType;
    m_stageSpaceOffset=rs.poseInReferenceSpace;
    rs.referenceSpaceType = XR_REFERENCE_SPACE_TYPE_VIEW;
    XR_CHECK(m_instance, xrCreateReferenceSpace(m_session, &rs, &m_viewSpace),
             "xrCreateReferenceSpace(VIEW)");
    CVR_INFO("xr.space", "stage=1 view=1");

    if (!createSwapchains()) return false;

    m_state = XrState::SessionCreated;
    return true;
}

bool XrCore::createSwapchains() {
    uint32_t fmtCount = 0;
    XR_CHECK(m_instance, xrEnumerateSwapchainFormats(m_session, 0, &fmtCount, nullptr),
             "xrEnumerateSwapchainFormats(count)");
    std::vector<int64_t> formats(fmtCount);
    XR_CHECK(m_instance,
             xrEnumerateSwapchainFormats(m_session, fmtCount, &fmtCount, formats.data()),
             "xrEnumerateSwapchainFormats");

    // Bevorzugte Reihenfolge. sRGB zuerst, weil OpenXR-Compositoren das erwarten.
    // Die Cemu-Anbindung gibt die Kanalreihenfolge vor. Sie steht deshalb an
    // erster Stelle -- eine falsche Reihenfolge waere eine stille Farbvertauschung.
    std::vector<DXGI_FORMAT> wanted;
    if (m_cfg.preferredFormat != DXGI_FORMAT_UNKNOWN) wanted.push_back(m_cfg.preferredFormat);
    for (DXGI_FORMAT f : { DXGI_FORMAT_R8G8B8A8_UNORM_SRGB, DXGI_FORMAT_B8G8R8A8_UNORM_SRGB,
                           DXGI_FORMAT_R8G8B8A8_UNORM,      DXGI_FORMAT_B8G8R8A8_UNORM })
        if (f != m_cfg.preferredFormat) wanted.push_back(f);

    bool found = false;
    for (DXGI_FORMAT w : wanted) {
        for (int64_t f : formats) {
            if ((DXGI_FORMAT)f == w) { m_format = w; found = true; break; }
        }
        if (found) break;
    }
    if (!found) {
        if (formats.empty()) {
            CVR_ERR("xr.swapchain", "reason=no_formats");
            return false;
        }
        m_format = (DXGI_FORMAT)formats[0];
        CVR_WARN("xr.swapchain", "preferred=none using=%u", (unsigned)m_format);
    }
    if (m_cfg.preferredFormat != DXGI_FORMAT_UNKNOWN && m_format != m_cfg.preferredFormat) {
        CVR_WARN("xr.swapchain.format",
                 "requested=%u got=%u -- Kanalreihenfolge pruefen",
                 (unsigned)m_cfg.preferredFormat, (unsigned)m_format);
    }
    CVR_INFO("xr.swapchain.format", "dxgi=%u count=%u", (unsigned)m_format, fmtCount);

    for (int e = 0; e < 2; ++e) {
        XrSwapchainCreateInfo sci{XR_TYPE_SWAPCHAIN_CREATE_INFO};
        sci.usageFlags = XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT |
                         XR_SWAPCHAIN_USAGE_TRANSFER_DST_BIT |
                         XR_SWAPCHAIN_USAGE_SAMPLED_BIT;
        sci.format = (int64_t)m_format;
        sci.sampleCount = 1;
        sci.width = m_eyeWidth;
        sci.height = m_eyeHeight;
        sci.faceCount = 1;
        sci.arraySize = 1;
        sci.mipCount = 1;
        XR_CHECK(m_instance, xrCreateSwapchain(m_session, &sci, &m_chains[e].handle),
                 "xrCreateSwapchain");

        uint32_t imgCount = 0;
        XR_CHECK(m_instance, xrEnumerateSwapchainImages(m_chains[e].handle, 0, &imgCount, nullptr),
                 "xrEnumerateSwapchainImages(count)");
        m_chains[e].images.assign(imgCount, {XR_TYPE_SWAPCHAIN_IMAGE_D3D11_KHR});
        XR_CHECK(m_instance,
                 xrEnumerateSwapchainImages(m_chains[e].handle, imgCount, &imgCount,
                     (XrSwapchainImageBaseHeader*)m_chains[e].images.data()),
                 "xrEnumerateSwapchainImages");
        CVR_INFO("xr.swapchain", "eye=%d w=%u h=%u images=%u", e, m_eyeWidth, m_eyeHeight, imgCount);
    }
    return true;
}

void XrCore::shutdown() {
    m_sessionAnchor.reset();m_spaceChanges.clear();
    m_validFrames=0;m_trackedFrames=0;
    if (m_session != XR_NULL_HANDLE) {
        releaseAllAcquired();
        if (m_state == XrState::SessionRunning) {
            xrRequestExitSession(m_session);
            xrEndSession(m_session);
        }
    }
    for (auto& c : m_chains) {
        if (c.handle != XR_NULL_HANDLE) { xrDestroySwapchain(c.handle); c.handle = XR_NULL_HANDLE; }
        c.images.clear();
    }
    if(m_hudChain.handle)xrDestroySwapchain(m_hudChain.handle);
    m_hudChain={};m_hudAnchorSet=false;m_hudReady=false;m_hudPlacement={};
    if (m_viewSpace  != XR_NULL_HANDLE) { xrDestroySpace(m_viewSpace);  m_viewSpace  = XR_NULL_HANDLE; }
    if (m_stageSpace != XR_NULL_HANDLE) { xrDestroySpace(m_stageSpace); m_stageSpace = XR_NULL_HANDLE; }
    if (m_session    != XR_NULL_HANDLE) { xrDestroySession(m_session);  m_session    = XR_NULL_HANDLE; }
    if (m_instance   != XR_NULL_HANDLE) { xrDestroyInstance(m_instance); m_instance  = XR_NULL_HANDLE; }
    if (m_cfg.bildLageMessen) lageProbenErnten(true);
    for (auto& pr : m_lage) {
        if (pr.staging) { pr.staging->Release(); pr.staging = nullptr; }
        pr.belegt = false;
    }
    if (m_staging) { m_staging->Release(); m_staging = nullptr; }
    if (m_ctx)    { m_ctx->Release();    m_ctx = nullptr; }
    if (m_device) { m_device->Release(); m_device = nullptr; }
    if (m_state != XrState::Failed) m_state = XrState::Ended;
    CVR_INFO("xr.shutdown", "state=%d", (int)m_state);
}

// ---------------------------------------------------------------------------
// Ereignisse
// ---------------------------------------------------------------------------

bool XrCore::pollEvents() {
    XrEventDataBuffer ev{XR_TYPE_EVENT_DATA_BUFFER};
    for (;;) {
        ev = XrEventDataBuffer{XR_TYPE_EVENT_DATA_BUFFER};
        XrResult r = xrPollEvent(m_instance, &ev);
        if (r == XR_EVENT_UNAVAILABLE) break;
        if (XR_FAILED(r)) {
            CVR_ERR("xr.event", "op=xrPollEvent result=%s", xrResultName(m_instance, r));
            ++m_stats.syncErrors;
            break;
        }
        switch (ev.type) {
            case XR_TYPE_EVENT_DATA_SESSION_STATE_CHANGED: {
                auto* e = (XrEventDataSessionStateChanged*)&ev;
                CVR_INFO("xr.event", "kind=session_state state=%d", (int)e->state);
                if (e->state == XR_SESSION_STATE_READY) {
                    XrSessionBeginInfo bi{XR_TYPE_SESSION_BEGIN_INFO};
                    bi.primaryViewConfigurationType = XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;
                    XrResult br = xrBeginSession(m_session, &bi);
                    if (XR_FAILED(br)) {
                        CVR_ERR("xr.session", "op=xrBeginSession result=%s",
                                xrResultName(m_instance, br));
                        m_state = XrState::Failed;
                        return false;
                    }
                    m_state = XrState::SessionRunning;
                    CVR_INFO("xr.session", "running=1");
                } else if (e->state == XR_SESSION_STATE_STOPPING) {
                    m_state = XrState::Stopping;
                    xrEndSession(m_session);
                    CVR_INFO("xr.session", "ended=1");
                    return false;
                } else if (e->state == XR_SESSION_STATE_EXITING ||
                           e->state == XR_SESSION_STATE_LOSS_PENDING) {
                    m_state = XrState::Stopping;
                    return false;
                }
                break;
            }
            case XR_TYPE_EVENT_DATA_INSTANCE_LOSS_PENDING:
                CVR_WARN("xr.event", "kind=instance_loss_pending");
                m_state = XrState::Stopping;
                return false;
            case XR_TYPE_EVENT_DATA_REFERENCE_SPACE_CHANGE_PENDING: {
                auto* e = (XrEventDataReferenceSpaceChangePending*)&ev;
                CVR_INFO("xr.event", "kind=refspace_change type=%d valid=%u changeTime=%lld",
                    (int)e->referenceSpaceType,(unsigned)e->poseValid,(long long)e->changeTime);
                if(e->session==m_session && e->referenceSpaceType==m_stageSpaceType) {
                    m_spaceChanges.push_back(*e);
                    m_spaceChanges.back().next=nullptr;
                    std::stable_sort(m_spaceChanges.begin(),m_spaceChanges.end(),
                        [](const auto& a,const auto& b){return a.changeTime<b.changeTime;});
                }
                break;
            }
            default:
                CVR_TRACE("xr.event", "kind=other type=%d", (int)ev.type);
                break;
        }
    }
    return true;
}

void XrCore::requestRecenter() { m_recenterRequested = true; }

void XrCore::setEyeAdjust(CemuVR_Eye eye, const CemuVR_EyeAdjust& a) {
    const int e = (eye == CEMUVR_EYE_LEFT) ? 0 : 1;
    m_adjust[e] = a;
    m_adjustSet[e] = true;
}
void XrCore::clearEyeAdjust() { m_adjustSet = {{false, false}}; }

// --- Raumfeste Flaeche -----------------------------------------------------
//
// Menu placement derives from the same session origin as game headtracking
// and HUD. Hiding/reopening a surface only clears its cached derived pose.
// The automatic menu remains upright, using the initial head yaw/height.
void XrCore::setSurface(const CemuVR_SurfaceRequest& q) {
    const uint32_t vorher = m_surfaceMode;
    m_surfaceMode = q.mode;
    m_surfaceAnchorMode = q.anchorMode;
    if (q.widthMetres  > 0.01f) m_surfaceW = q.widthMetres;
    if (q.heightMetres > 0.01f) m_surfaceH = q.heightMetres;
    if (q.distanceMetres > 0.05f) m_surfaceDist = q.distanceMetres;

    if (m_surfaceMode == 0) { m_surfaceAnchorSet = false; return; }

    if (q.anchorMode == 1) {
        m_surfaceAnchor.orientation = {q.anchor.orientation.x, q.anchor.orientation.y,
                                       q.anchor.orientation.z, q.anchor.orientation.w};
        m_surfaceAnchor.position = {q.anchor.position.x, q.anchor.position.y,
                                    q.anchor.position.z};
        m_surfaceAnchorSet = true;
        return;
    }

    if (m_surfaceAnchorSet) return;
    if (!m_sessionAnchor.ready()) return;
    m_surfaceAnchor = m_sessionAnchor.surface(m_surfaceDist);
    m_surfaceAnchorSet = true;
    CVR_INFO("surface.anchor", "source=session_anchor pos=%.3f,%.3f,%.3f distance=%.2f previous_mode=%u",
             m_surfaceAnchor.position.x,m_surfaceAnchor.position.y,m_surfaceAnchor.position.z,
             m_surfaceDist,vorher);
}

void XrCore::clearSurface() {
    if (m_surfaceMode) CVR_INFO("surface.aus", "layers=%llu",
                                (unsigned long long)m_surfaceLayers);
    m_surfaceMode = 0;
    m_surfaceAnchorSet = false;
}

// ---------------------------------------------------------------------------
// Frameloop
// ---------------------------------------------------------------------------

bool XrCore::beginFrame() {
    m_explicitRenderedPair=false;
    if (m_state != XrState::SessionRunning) return false;

    if (m_recenterRequested) {
        // Recenter: den Stage-Raum an der aktuellen Kopfpose neu verankern.
        XrSpaceLocation loc{XR_TYPE_SPACE_LOCATION};
        if (m_frameState.predictedDisplayTime != 0 &&
            XR_SUCCEEDED(xrLocateSpace(m_viewSpace, m_stageSpace,
                                       m_frameState.predictedDisplayTime, &loc)) &&
            (loc.locationFlags & XR_SPACE_LOCATION_POSITION_VALID_BIT)) {
            XrReferenceSpaceCreateInfo rs{XR_TYPE_REFERENCE_SPACE_CREATE_INFO};
            rs.referenceSpaceType = m_stageSpaceType;
            rs.poseInReferenceSpace.orientation.w = 1.0f;
            rs.poseInReferenceSpace.position = loc.pose.position;
            rs.poseInReferenceSpace.position.y = 0.0f;   // Hoehe nicht verschieben
            rs.poseInReferenceSpace=anchorCompose(m_stageSpaceOffset,rs.poseInReferenceSpace);
            XrSpace ns{XR_NULL_HANDLE};
            if (XR_SUCCEEDED(xrCreateReferenceSpace(m_session, &rs, &ns))) {
                xrDestroySpace(m_stageSpace);
                m_stageSpace = ns;
                m_stageSpaceOffset=rs.poseInReferenceSpace;
                ++m_stats.recenters;
                CVR_INFO("xr.recenter", "applied=1 x=%.4f z=%.4f",
                         rs.poseInReferenceSpace.position.x, rs.poseInReferenceSpace.position.z);
            }
        }
        m_recenterRequested = false;
    }

    XrFrameWaitInfo wi{XR_TYPE_FRAME_WAIT_INFO};
    XrFrameState fs{XR_TYPE_FRAME_STATE};
    XrResult r = xrWaitFrame(m_session, &wi, &fs);
    if (XR_FAILED(r)) {
        CVR_ERR("xr.frame", "op=xrWaitFrame result=%s", xrResultName(m_instance, r));
        ++m_stats.syncErrors;
        return false;
    }
    m_frameState = fs;
    ++m_stats.framesWaited;

    XrFrameBeginInfo bi{XR_TYPE_FRAME_BEGIN_INFO};
    r = xrBeginFrame(m_session, &bi);
    if (XR_FAILED(r) && r != XR_FRAME_DISCARDED) {
        CVR_ERR("xr.frame", "op=xrBeginFrame result=%s", xrResultName(m_instance, r));
        ++m_stats.syncErrors;
        return false;
    }
    ++m_stats.framesBegun;
    m_frameActive = true;
    m_eyeReady = {{false, false}};
    ++m_pairId;   // ein XR-Frame traegt genau ein Augenpaar

    m_viewsValid = locateViews();
    return true;
}

// Je GASTBILD ein Eintrag in der Ansichtsgeschichte.
//
// Die Schicht ruft das einmal je vkQueuePresentKHR, nach beginFrame und vor
// beginGuestFrame. Die Ansicht selbst wechselt nur einmal je XR-Bild; der
// Eintrag wiederholt sie also. Genau so ist es gemeint: der gemessene Weg
// zaehlt Gastbilder, und eine Geschichte in einer anderen Einheit waere eine
// stille Umrechnung.
void XrCore::setPresentInfo(uint64_t presentIndex, uint32_t swapImageIndex) {
    m_presentIndex = presentIndex;
    m_swapImageIndex = swapImageIndex;
    if (m_viewsValid) {
        const uint32_t slot = m_viewHistN % kViewHist;
        m_viewHist[slot] = m_views;
        m_viewHistOk[slot] = true;
        ++m_viewHistN;
    }
}

bool XrCore::locateViews() {
    // Keep application-space coordinates physically stable across runtime
    // recenter/origin changes. The event maps NEW natural origin into OLD.
    while(!m_spaceChanges.empty() && m_spaceChanges.front().changeTime<=m_frameState.predictedDisplayTime) {
        const auto& e=m_spaceChanges.front();
        if(!e.poseValid || !anchorPoseValid(e.poseInPreviousSpace)) {
            CVR_WARN("session.origin","preserved=0 reason=runtime_transform_unavailable changeTime=%lld",(long long)e.changeTime);
            m_spaceChanges.erase(m_spaceChanges.begin());
            continue;
        }
        XrReferenceSpaceCreateInfo rs{XR_TYPE_REFERENCE_SPACE_CREATE_INFO};
        rs.referenceSpaceType=m_stageSpaceType;
        rs.poseInReferenceSpace=anchorCompose(anchorInverse(e.poseInPreviousSpace),m_stageSpaceOffset);
        XrSpace next{XR_NULL_HANDLE};
        if(XR_FAILED(xrCreateReferenceSpace(m_session,&rs,&next))) {
            CVR_WARN("session.origin","preserved=0 reason=create_space_failed retry=1");
            return false;
        }
        xrDestroySpace(m_stageSpace);m_stageSpace=next;
        m_stageSpaceOffset=rs.poseInReferenceSpace;
        CVR_INFO("session.origin","preserved=1 type=%d changeTime=%lld offset=%.6f/%.6f/%.6f",
            (int)m_stageSpaceType,(long long)e.changeTime,m_stageSpaceOffset.position.x,
            m_stageSpaceOffset.position.y,m_stageSpaceOffset.position.z);
        m_spaceChanges.erase(m_spaceChanges.begin());
    }
    XrViewLocateInfo vli{XR_TYPE_VIEW_LOCATE_INFO};
    vli.viewConfigurationType = XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;
    vli.displayTime = m_frameState.predictedDisplayTime;
    vli.space = m_stageSpace;

    XrViewState vs{XR_TYPE_VIEW_STATE};
    uint32_t n = 2;
    XrResult r = xrLocateViews(m_session, &vli, &vs, 2, &n, m_views.data());
    if (XR_FAILED(r) || n != 2) {
        m_viewsTracked=false;m_trackedFrames=0;
        CVR_WARN("xr.pose", "op=xrLocateViews result=%s n=%u", xrResultName(m_instance, r), n);
        return false;
    }
    const bool ori = (vs.viewStateFlags & XR_VIEW_STATE_ORIENTATION_VALID_BIT) != 0;
    const bool pos = (vs.viewStateFlags & XR_VIEW_STATE_POSITION_VALID_BIT) != 0;
    if (!ori || !pos) {
        m_viewsTracked=false;m_trackedFrames=0;
        CVR_WARN("xr.pose", "flags=0x%08x oriValid=%d posValid=%d",
                 (unsigned)vs.viewStateFlags, (int)ori, (int)pos);
        return false;
    }
    // Verfolgt ist mehr als gueltig. Fuer die Flaeche zaehlt der Unterschied:
    // eine gueltige, aber ungetrackte Pose steht meist im Ursprung, und ein
    // dort gesetzter Anker haengt die Flaeche auf Fussbodenhoehe auf.
    const bool oriT = (vs.viewStateFlags & XR_VIEW_STATE_ORIENTATION_TRACKED_BIT) != 0;
    const bool posT = (vs.viewStateFlags & XR_VIEW_STATE_POSITION_TRACKED_BIT) != 0;
    m_viewsTracked = oriT && posT;
    if (m_viewsTracked) ++m_trackedFrames; else m_trackedFrames = 0;
    ++m_validFrames;

    // Winkel zwischen der vorigen und der jetzigen Kopfdrehung. Das Skalar-
    // produkt der Quaternionen gibt den halben Winkel; doppelt genommen ist es
    // der volle. Vorzeichen egal -- q und -q sind dieselbe Drehung.
    {
        const XrQuaternionf& q = m_views[0].pose.orientation;
        if (m_letzteOriDa) {
            double d = (double)q.x * m_letzteOri.x + (double)q.y * m_letzteOri.y
                     + (double)q.z * m_letzteOri.z + (double)q.w * m_letzteOri.w;
            if (d < 0.0) d = -d;
            if (d > 1.0) d = 1.0;
            const double grad = 2.0 * std::acos(d) * 57.2957795131;
            m_drehSumme += grad;
            if (grad > m_drehMax) m_drehMax = grad;
            ++m_drehN;
            if ((m_drehN % 600) == 0)
                CVR_INFO("xr.drehung",
                         "je XR-Bild im Mittel %.2f grad, Spitze %.2f grad "
                         "ueber %llu bilder -- so viel kostet EIN bild verzug",
                         m_drehSumme / (double)m_drehN, m_drehMax,
                         (unsigned long long)m_drehN);
        }
        m_letzteOri = q;
        m_letzteOriDa = true;
    }

    XrPosef head=m_views[0].pose;
    head.position={(m_views[0].pose.position.x+m_views[1].pose.position.x)*.5f,
                   (m_views[0].pose.position.y+m_views[1].pose.position.y)*.5f,
                   (m_views[0].pose.position.z+m_views[1].pose.position.z)*.5f};
    if(m_sessionAnchor.latch(head,m_viewsTracked,m_trackedFrames)) {
        CVR_INFO("session.anchor","set=1 serial=%llu position=%.6f/%.6f/%.6f orientation=%.6f/%.6f/%.6f/%.6f",
            (unsigned long long)(m_stats.poseSerial+1),head.position.x,head.position.y,head.position.z,
            head.orientation.x,head.orientation.y,head.orientation.z,head.orientation.w);
    }
    ++m_stats.poseSerial;
    CVR_TRACE("xr.pose", "serial=%llu lx=%.4f ly=%.4f lz=%.4f rx=%.4f ry=%.4f rz=%.4f ipd=%.4f",
              (unsigned long long)m_stats.poseSerial,
              m_views[0].pose.position.x, m_views[0].pose.position.y, m_views[0].pose.position.z,
              m_views[1].pose.position.x, m_views[1].pose.position.y, m_views[1].pose.position.z,
              ipd());
    return true;
}

float XrCore::ipd() const {
    const auto& a = m_views[0].pose.position;
    const auto& b = m_views[1].pose.position;
    const float dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z;
    return std::sqrt(dx*dx + dy*dy + dz*dz);
}

void XrCore::endFrame() {
    if (!m_frameActive) return;

    std::vector<XrCompositionLayerBaseHeader*> layers;
    XrCompositionLayerProjection proj{XR_TYPE_COMPOSITION_LAYER_PROJECTION};
    std::array<XrCompositionLayerProjectionView, 2> pv{};
    XrCompositionLayerQuad quad{XR_TYPE_COMPOSITION_LAYER_QUAD};

    // Ein Auge, das in diesem XR-Frame nicht neu befuellt wurde, kann dennoch
    // eingereicht werden: die Swapchain haelt das zuletzt freigegebene Bild. Das
    // ist eine WIEDERHOLUNG, keine Synthese -- es wird kein Bild berechnet, nur
    // ein bereits erzeugtes noch einmal gezeigt. Der Zaehler weist sie aus.
    const bool complete = m_eyeReady[0] && m_eyeReady[1];
    const bool haveL = m_eyeReady[0] || (m_cfg.repeatMissingEye && m_chains[0].hasContent);
    const bool haveR = m_eyeReady[1] || (m_cfg.repeatMissingEye && m_chains[1].hasContent);

    // Raumfeste Flaeche: sie ERSETZT die Projektionsebenen. Beides zugleich
    // einzureichen hiesse, das nahe Doppelbild hinter der Flaeche stehen zu
    // lassen -- also genau den Fehler, den sie beheben soll.
    if (m_surfaceMode && m_surfaceAnchorSet && m_chains[0].hasContent &&
        m_frameState.shouldRender == XR_TRUE) {
        quad.layerFlags = 0;
        quad.space = m_stageSpace;
        // Eine Flaeche, beide Augen, dieselbe Quelle und dieselbe Bildzeit.
        quad.eyeVisibility = XR_EYE_VISIBILITY_BOTH;
        const int surfaceEye=(m_cfg.streamGuestFrames && m_eyeReady[1])?1:0;
        quad.subImage.swapchain = m_chains[surfaceEye].handle;
        quad.subImage.imageRect.offset = {0, 0};
        // Der GANZE Bildausschnitt. Keine Teilkopie, keine verlorenen Ecken.
        quad.subImage.imageRect.extent = {(int32_t)m_eyeWidth, (int32_t)m_eyeHeight};
        quad.subImage.imageArrayIndex = 0;
        quad.pose = m_surfaceAnchor;
        quad.size = {m_surfaceW, m_surfaceH};
        layers.push_back((XrCompositionLayerBaseHeader*)&quad);
        ++m_surfaceLayers;
        // Auch ein Flaechenbild ist ein eingereichtes Bild. Ohne diese Zeile
        // meldete die Bilanz nur die Projektionsbilder -- in einem Lauf mit
        // viel Menue sah das nach einem Einbruch der Bildrate aus, den es
        // nicht gab. Genau darauf bin ich eben selbst hereingefallen.
        ++m_stats.pairsComplete;
        CVR_TRACE("surface.layer",
                  "pos=%.3f,%.3f,%.3f groesse=%.3fx%.3f bild=%ux%u",
                  quad.pose.position.x, quad.pose.position.y,
                  quad.pose.position.z, m_surfaceW, m_surfaceH,
                  m_eyeWidth, m_eyeHeight);
    } else if (!m_surfaceMode && haveL && haveR && m_viewsValid && m_frameState.shouldRender == XR_TRUE) {
        for (int e = 0; e < 2; ++e) {
            pv[e] = XrCompositionLayerProjectionView{XR_TYPE_COMPOSITION_LAYER_PROJECTION_VIEW};
            // Die Pose des BILDES, nicht die des Rahmens. Fehlt der Stempel
            // -- erstes Bild, oder poseBleibtBeimBild aus --, bleibt es beim
            // bisherigen Weg. Das ist ausdruecklich kein Rueckfall auf einen
            // geratenen Wert: m_views ist genau das, was frueher hier stand.
            if ((m_explicitRenderedPair || m_cfg.poseBleibtBeimBild) && m_eyeStamp[e].valid) {
                pv[e].pose = m_eyeStamp[e].pose;
                pv[e].fov  = m_eyeStamp[e].fov;
                if (!m_eyeReady[e]) ++m_stats.stampsReused;
            } else {
                pv[e].pose = m_views[e].pose;
                pv[e].fov  = m_views[e].fov;
            }

            // Sichtfeld der Ausgabeebene, falls vorgegeben.
            //
            // Ein Gastbild ist mit dem symmetrischen Frustum des Spiels
            // gerendert. Das Augenfrustum eines Headsets ist unsymmetrisch und
            // zwischen den Augen gespiegelt: seine Mitte liegt fuer das linke
            // Auge nach links und fuer das rechte nach rechts versetzt. Wird
            // das Bild ueber dieses Frustum gespannt, steht sein Inhalt in
            // beiden Augen an verschiedenen Winkelpositionen -- ein fester
            // Winkel, der keine Tiefe traegt und die Augen auseinanderzieht.
            //
            // Mit einem vorgegebenen Wert bekommen BEIDE Augen dasselbe,
            // symmetrische Sichtfeld. Der einzige Unterschied zwischen den
            // Augenbildern ist dann die Parallaxe, die das Spielprofil in die
            // Kamera geschrieben hat -- also genau das, was Tiefe tragen soll.
            // Und erst dann bedeutet der Weltmasstab des Profils wirklich
            // Welteinheiten je Meter: die Winkeldisparitaet wird nicht mehr
            // durch das Verhaeltnis der Sichtfelder gestreckt.
            if (!m_explicitRenderedPair && m_cfg.layerFovVerticalDeg > 0.0f && m_eyeHeight) {
                const float halfV = m_cfg.layerFovVerticalDeg * 0.5f
                                  * 3.14159265358979f / 180.0f;
                const float aspect = (float)m_eyeWidth / (float)m_eyeHeight;
                const float halfH = std::atan(std::tan(halfV) * aspect);
                pv[e].fov.angleLeft  = -halfH;
                pv[e].fov.angleRight = +halfH;
                pv[e].fov.angleUp    = +halfV;
                pv[e].fov.angleDown  = -halfV;
            }

            // Anpassung des Spielprofils anwenden. Das ist der Punkt, an dem
            // eine profilseitige View-/Projection-Aenderung im echten Bildweg
            // wirksam wird -- sie steht anschliessend in den Daten, die die
            // Runtime bekommt.
            if (m_adjustSet[e] && !m_explicitRenderedPair) {
                const CemuVR_EyeAdjust& a = m_adjust[e];
                pv[e].pose.position.x += a.eyePositionOffset.x;
                pv[e].pose.position.y += a.eyePositionOffset.y;
                pv[e].pose.position.z += a.eyePositionOffset.z;
                float sc = a.fovScale;
                if (sc <= 0.0f) sc = 1.0f;
                if (sc < 0.25f) sc = 0.25f;
                if (sc > 4.0f)  sc = 4.0f;
                if (sc != 1.0f) {
                    pv[e].fov.angleLeft  *= sc;
                    pv[e].fov.angleRight *= sc;
                    pv[e].fov.angleUp    *= sc;
                    pv[e].fov.angleDown  *= sc;
                }
                CVR_TRACE("profile.adjust.applied",
                          "eye=%d dx=%d dy=%d dpos=%.4f,%.4f,%.4f fovScale=%.4f",
                          e, a.sourceOffsetX, a.sourceOffsetY,
                          a.eyePositionOffset.x, a.eyePositionOffset.y,
                          a.eyePositionOffset.z, sc);
            }
            pv[e].subImage.swapchain = m_chains[e].handle;
            pv[e].subImage.imageRect.offset = {0, 0};
            pv[e].subImage.imageRect.extent = {(int32_t)m_eyeWidth, (int32_t)m_eyeHeight};
            pv[e].subImage.imageArrayIndex = 0;
        }
        proj.layerFlags = 0;
        proj.space = m_stageSpace;
        proj.viewCount = 2;
        proj.views = pv.data();
        layers.push_back((XrCompositionLayerBaseHeader*)&proj);
        if (complete) {
            ++m_stats.pairsComplete;
        } else if (m_cfg.streamGuestFrames && (m_eyeReady[0] || m_eyeReady[1])) {
            ++m_stats.streamFrames;
            ++m_stats.eyesRepeated;
        } else {
            ++m_stats.pairsIncomplete;
            ++m_stats.eyesRepeated;
            CVR_WARN("stereo.pair", "repeated pair=%u left=%d right=%d",
                     m_pairId, (int)m_eyeReady[0], (int)m_eyeReady[1]);
        }
    } else if (m_eyeReady[0] || m_eyeReady[1]) {
        ++m_stats.pairsIncomplete;
        CVR_WARN("stereo.pair", "incomplete pair=%u left=%d right=%d shouldRender=%d views=%d",
                 m_pairId, (int)m_eyeReady[0], (int)m_eyeReady[1],
                 (int)m_frameState.shouldRender, (int)m_viewsValid);
    }

    XrCompositionLayerQuad hudQuad{XR_TYPE_COMPOSITION_LAYER_QUAD};
    if(m_hudReady && m_hudAnchorSet && !m_surfaceMode && haveL && haveR && m_frameState.shouldRender) {
        hudQuad.layerFlags=XR_COMPOSITION_LAYER_BLEND_TEXTURE_SOURCE_ALPHA_BIT;
        hudQuad.space=m_stageSpace;hudQuad.eyeVisibility=XR_EYE_VISIBILITY_BOTH;
        hudQuad.pose=m_hudAnchor;
        hudQuad.subImage.swapchain=m_hudChain.handle;
        // Mario title layout: keep the complete native canvas, no HUD corner crop.
        hudQuad.subImage.imageRect={{0,0},{int32_t(m_eyeWidth),int32_t(m_eyeHeight)}};
        hudQuad.size={2.31f,2.31f*float(m_eyeHeight)/float(m_eyeWidth)};
        layers.push_back((XrCompositionLayerBaseHeader*)&hudQuad);
    }
    m_hudReady=false;

    XrFrameEndInfo fei{XR_TYPE_FRAME_END_INFO};
    fei.displayTime = m_frameState.predictedDisplayTime;
    fei.environmentBlendMode = XR_ENVIRONMENT_BLEND_MODE_OPAQUE;
    fei.layerCount = (uint32_t)layers.size();
    fei.layers = layers.empty() ? nullptr : layers.data();

    XrResult r = xrEndFrame(m_session, &fei);
    if (XR_FAILED(r)) {
        CVR_ERR("xr.frame", "op=xrEndFrame result=%s layers=%u",
                xrResultName(m_instance, r), (unsigned)layers.size());
        ++m_stats.syncErrors;
    } else {
        ++m_stats.framesEnded;
        CVR_TRACE("xr.submit", "frame=%llu pair=%u layers=%u complete=%d",
                  (unsigned long long)m_stats.framesEnded, m_pairId,
                  (unsigned)layers.size(), (int)complete);
    }
    m_frameActive = false;
    clearEyeAdjust();
}

// ---------------------------------------------------------------------------
// Stereo
// ---------------------------------------------------------------------------

CemuVR_Eye XrCore::beginGuestFrame(uint64_t guestSwapCounter, uint32_t* pairIdOut) {
    // 0. Die eigene Frameszaehlung. Sie steigt bei JEDEM angemeldeten Gastframe,
    //    unabhaengig davon, was der Gastzaehler tut. Frueher haeng sie am
    //    Gastzaehler und blieb stehen, sobald dieser unbrauchbar war -- ein
    //    Spielprofil haette dann eine eingefrorene Framenummer bekommen.
    ++m_coreFrameIndex;

    // 1. Den Gastzaehler auswerten. Er entscheidet NICHT ueber das Auge, sondern
    //    deckt Wiederholungen und Luecken auf.
    if (guestSwapCounter == m_lastGuestSwap) {
        ++m_stats.guestFramesRepeated;
        CVR_WARN("guest.repeat", "swap=%llu", (unsigned long long)guestSwapCounter);
    } else {
        if (m_lastGuestSwap != UINT64_MAX && guestSwapCounter > m_lastGuestSwap + 1) {
            const uint64_t missed = guestSwapCounter - m_lastGuestSwap - 1;
            m_stats.guestFramesMissed += missed;
            CVR_WARN("guest.gap", "prev=%llu now=%llu missed=%llu",
                     (unsigned long long)m_lastGuestSwap,
                     (unsigned long long)guestSwapCounter,
                     (unsigned long long)missed);
        }
        m_lastGuestSwap = guestSwapCounter;
        ++m_stats.guestFramesSeen;
    }

    // 2. Das Auge folgt der Belegung des laufenden XR-Frames. Damit enthaelt jeder
    //    XR-Frame genau ein linkes und genau ein rechtes Auge -- unabhaengig davon,
    //    ob der Gast einen Frame ausgelassen oder wiederholt hat. Ein freilaufender
    //    Zaehler wuerde nach einem einzigen ausgelassenen Gastframe dauerhaft
    //    vertauschte Augen liefern.
    CemuVR_Eye eye;
    if (m_cfg.streamGuestFrames) {
        // Count callbacks, not the guest swap number, which can repeat/jump.
        eye=((m_coreFrameIndex-1u)&1u)?CEMUVR_EYE_RIGHT:CEMUVR_EYE_LEFT;
    } else if (!m_eyeReady[0]) {
        eye = CEMUVR_EYE_LEFT;
    } else if (!m_eyeReady[1]) {
        eye = CEMUVR_EYE_RIGHT;
    } else {
        // Beide Augen sind belegt: der Aufrufer haette endFrame rufen muessen.
        ++m_stats.eyesOverflow;
        CVR_WARN("stereo.overflow", "pair=%u swap=%llu",
                 m_pairId, (unsigned long long)guestSwapCounter);
        eye = CEMUVR_EYE_RIGHT;
    }

    if (pairIdOut) *pairIdOut = m_pairId;
    CVR_TRACE("stereo.guestframe", "swap=%llu core=%llu eye=%d pair=%u",
              (unsigned long long)guestSwapCounter,
              (unsigned long long)m_coreFrameIndex,
              (int)eye, m_pairId);
    return eye;
}

// Pruefsumme des Quellbildes. Reflektierte CRC-32 ueber alle Texel, damit zwei
// Augenbilder ohne Bildvergleich unterscheidbar sind. Nur fuer die Diagnose.
uint32_t XrCore::checksumTexture(ID3D11Texture2D* src) {
    if (!src || !m_device || !m_ctx) return 0;
    D3D11_TEXTURE2D_DESC sd{};
    src->GetDesc(&sd);

    if (!m_staging) {
        D3D11_TEXTURE2D_DESC td = sd;
        td.Usage = D3D11_USAGE_STAGING;
        td.BindFlags = 0;
        td.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
        td.MiscFlags = 0;
        td.MipLevels = 1;
        td.ArraySize = 1;
        if (FAILED(m_device->CreateTexture2D(&td, nullptr, &m_staging))) {
            CVR_WARN("diag.checksum", "reason=staging_create_failed");
            return 0;
        }
    }
    m_ctx->CopyResource(m_staging, src);

    D3D11_MAPPED_SUBRESOURCE map{};
    if (FAILED(m_ctx->Map(m_staging, 0, D3D11_MAP_READ, 0, &map))) return 0;

    uint32_t crc = 0xFFFFFFFFu;
    const uint8_t* base = (const uint8_t*)map.pData;
    const uint32_t bytesPerRow = sd.Width * 4;   // nur 8-Bit-Vierkanalformate
    for (uint32_t y = 0; y < sd.Height; ++y) {
        const uint8_t* row = base + (size_t)y * map.RowPitch;
        for (uint32_t i = 0; i < bytesPerRow; ++i) {
            crc ^= row[i];
            for (int b = 0; b < 8; ++b)
                crc = (crc >> 1) ^ (0xEDB88320u & (uint32_t)(-(int32_t)(crc & 1u)));
        }
    }
    m_ctx->Unmap(m_staging, 0);
    return ~crc;
}

// Eine Probe anstossen: kopieren, Kennung danebenlegen, NICHT auswerten.
//
// Warum nicht sofort auswerten: ein Map unmittelbar nach CopyResource
// wartet, bis die Grafikkarte die Kopie fertig hat. In einem Messmittel,
// das eine Verzoegerung bestimmen soll, waere das genau die falsche
// Wartezeit -- sie faellt in dem Bild an, das gerade eingereicht wird.
void XrCore::lageProbeAnstossen(ID3D11Texture2D* src, int eye) {
    if (!src || !m_device || !m_ctx) return;
    D3D11_TEXTURE2D_DESC sd{};
    src->GetDesc(&sd);

    // Einen freien Platz suchen. Ist keiner frei, wird diese Probe
    // ausgelassen und GEZAEHLT -- ein stillschweigend fehlendes Bild
    // waere in der Auswertung nicht von einem fehlenden Zeichen zu
    // unterscheiden.
    int platz = -1;
    for (uint32_t i = 0; i < kLageRing; ++i)
        if (!m_lage[i].belegt) { platz = (int)i; break; }
    if (platz < 0) { ++m_stats.lageUebersprungen; return; }

    LageProbe& pr = m_lage[platz];
    if (!pr.staging) {
        D3D11_TEXTURE2D_DESC td = sd;
        td.Usage = D3D11_USAGE_STAGING;
        td.BindFlags = 0;
        td.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
        td.MiscFlags = 0;
        td.MipLevels = 1;
        td.ArraySize = 1;
        if (FAILED(m_device->CreateTexture2D(&td, nullptr, &pr.staging))) {
            CVR_WARN("diag.bildlage", "reason=staging_create_failed");
            return;
        }
    }

    LARGE_INTEGER t0{}, t1{}, fq{};
    QueryPerformanceFrequency(&fq);
    QueryPerformanceCounter(&t0);
    m_ctx->CopyResource(pr.staging, src);
    QueryPerformanceCounter(&t1);
    const double ms = fq.QuadPart
        ? (double)(t1.QuadPart - t0.QuadPart) * 1000.0 / (double)fq.QuadPart
        : 0.0;
    m_stats.lageKopieMsSumme += ms;
    if (ms > m_stats.lageKopieMsMax) m_stats.lageKopieMsMax = ms;

    pr.belegt = true;
    pr.praesentation = m_presentIndex;
    pr.auge = (uint32_t)eye;
    pr.pairId = m_pairId;
    pr.kopiertBei = m_presentIndex;
    ++m_stats.lageKopien;
}

// Fertige Proben abholen. Nicht blockierend.
//
// amEnde: beim Herunterfahren darf gewartet werden -- dort stoert es
// niemanden mehr, und die letzten Proben waeren sonst verloren.
void XrCore::lageProbenErnten(bool amEnde) {
    if (!m_ctx) return;
    LARGE_INTEGER t0{}, t1{}, fq{};
    QueryPerformanceFrequency(&fq);
    QueryPerformanceCounter(&t0);

    for (uint32_t i = 0; i < kLageRing; ++i) {
        LageProbe& pr = m_lage[i];
        if (!pr.belegt || !pr.staging) continue;
        // Im laufenden Betrieb erst ab dem naechsten Gastbild versuchen.
        if (!amEnde && m_presentIndex <= pr.kopiertBei) continue;

        D3D11_MAPPED_SUBRESOURCE map{};
        const UINT flags = amEnde ? 0u : (UINT)D3D11_MAP_FLAG_DO_NOT_WAIT;
        const HRESULT hr = m_ctx->Map(pr.staging, 0, D3D11_MAP_READ, flags, &map);
        if (hr == DXGI_ERROR_WAS_STILL_DRAWING) {
            ++m_stats.lageNochNicht;
            // Geduld hat eine Grenze: eine Probe, die nie fertig wird,
            // wuerde den Ring dauerhaft verstopfen.
            if (m_presentIndex - pr.kopiertBei > kLageGeduld) {
                pr.belegt = false;
                ++m_stats.lageVerworfen;
                CVR_WARN("stereo.bildlage", "verworfen present=%llu eye=%u "
                         "wartete=%llu",
                         (unsigned long long)pr.praesentation, pr.auge,
                         (unsigned long long)(m_presentIndex - pr.kopiertBei));
            }
            continue;
        }
        if (FAILED(hr)) { pr.belegt = false; ++m_stats.lageVerworfen; continue; }

        D3D11_TEXTURE2D_DESC td{};
        pr.staging->GetDesc(&td);
        double sx = 0.0, sy = 0.0, lum = 0.0;
        const bool ok = cemuvr::bildlageAusPuffer(
            (const uint8_t*)map.pData, td.Width, td.Height, map.RowPitch,
            cemuvr::kBildlageSchritt, &sx, &sy, &lum);
        m_ctx->Unmap(pr.staging, 0);

        // Die Zeile traegt die Kennung des Bildes, aus dem die Probe
        // stammt -- nicht die des Bildes, in dem sie geerntet wurde.
        CVR_INFO("stereo.bildlage",
                 "eye=%u present=%llu pair=%u ok=%d sx=%.6f sy=%.6f "
                 "lum=%.5f wartete=%llu",
                 pr.auge, (unsigned long long)pr.praesentation, pr.pairId,
                 (int)ok, sx, sy, lum,
                 (unsigned long long)(m_presentIndex - pr.kopiertBei));
        pr.belegt = false;
        ++m_stats.lageGeerntet;
    }

    QueryPerformanceCounter(&t1);
    const double ms = fq.QuadPart
        ? (double)(t1.QuadPart - t0.QuadPart) * 1000.0 / (double)fq.QuadPart
        : 0.0;
    m_stats.lageErnteMsSumme += ms;
    if (ms > m_stats.lageErnteMsMax) m_stats.lageErnteMsMax = ms;

    // Bilanz alle zehn Sekunden. Kein Protokoll je Bild.
    const double jetzt = (double)GetTickCount64();
    if (amEnde || jetzt >= m_lageBilanzMs) {
        m_lageBilanzMs = jetzt + 10000.0;
        const double nk = m_stats.lageKopien ? (double)m_stats.lageKopien : 1.0;
        const double ne = m_stats.lageGeerntet ? (double)m_stats.lageGeerntet : 1.0;
        CVR_INFO("stereo.bildlage.bilanz",
                 "kopien=%llu geerntet=%llu uebersprungen=%llu verworfen=%llu "
                 "nochnicht=%llu kopie_ms=%.4f/%.4f ernte_ms=%.4f/%.4f",
                 (unsigned long long)m_stats.lageKopien,
                 (unsigned long long)m_stats.lageGeerntet,
                 (unsigned long long)m_stats.lageUebersprungen,
                 (unsigned long long)m_stats.lageVerworfen,
                 (unsigned long long)m_stats.lageNochNicht,
                 m_stats.lageKopieMsSumme / nk, m_stats.lageKopieMsMax,
                 m_stats.lageErnteMsSumme / ne, m_stats.lageErnteMsMax);
    }
}
bool XrCore::copyIntoSwapchain(EyeChain& chain, ID3D11Texture2D* src) {
    if (chain.acquiredIndex == UINT32_MAX ||
        chain.acquiredIndex >= chain.images.size()) return false;
    ID3D11Texture2D* dst = chain.images[chain.acquiredIndex].texture;
    if (!dst || !src) return false;

    D3D11_TEXTURE2D_DESC ds{}, ss{};
    dst->GetDesc(&ds);
    src->GetDesc(&ss);
    if (ds.Width != ss.Width || ds.Height != ss.Height) {
        CVR_ERR("copy.mismatch", "reason=size dstW=%u dstH=%u srcW=%u srcH=%u",
                ds.Width, ds.Height, ss.Width, ss.Height);
        return false;
    }
    // CopyResource ist eine 1:1-Texelkopie: keine Skalierung, keine Filterung.
    m_ctx->CopyResource(dst, src);
    return true;
}

bool XrCore::stampRenderedPair(const CemuVR_FrameContext& rendered) {
    if(!frameActive() || !m_eyeReady[0] || !m_eyeReady[1] || !rendered.poseSerial)return false;
    for(int e=0;e<2;++e) {
        const auto& p=rendered.eyePose[e];const auto& f=rendered.eyeFov[e];
        m_eyeStamp[e].pose={{p.orientation.x,p.orientation.y,p.orientation.z,p.orientation.w},
                            {p.position.x,p.position.y,p.position.z}};
        m_eyeStamp[e].fov={f.angleLeft,f.angleRight,f.angleUp,f.angleDown};
        m_eyeStamp[e].poseSerial=rendered.poseSerial;
        m_eyeStamp[e].presentIndex=rendered.presentIndex;
        m_eyeStamp[e].valid=true;
    }
    m_explicitRenderedPair=true;return true;
}

bool XrCore::submitHud(ID3D11Texture2D* src,bool title) {
    m_hudReady=false;
    if(!m_frameActive || !src || !referenceAnchorReady())return false;
    if(!m_hudChain.handle) {
        XrSwapchainCreateInfo ci{XR_TYPE_SWAPCHAIN_CREATE_INFO};
        ci.usageFlags=XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT|XR_SWAPCHAIN_USAGE_TRANSFER_DST_BIT|XR_SWAPCHAIN_USAGE_SAMPLED_BIT;
        ci.format=int64_t(m_format);ci.sampleCount=1;ci.width=m_eyeWidth;ci.height=m_eyeHeight;
        ci.faceCount=ci.arraySize=ci.mipCount=1;
        if(XR_FAILED(xrCreateSwapchain(m_session,&ci,&m_hudChain.handle)))return false;
        uint32_t count{};
        if(XR_FAILED(xrEnumerateSwapchainImages(m_hudChain.handle,0,&count,nullptr)))return false;
        m_hudChain.images.assign(count,{XR_TYPE_SWAPCHAIN_IMAGE_D3D11_KHR});
        if(XR_FAILED(xrEnumerateSwapchainImages(m_hudChain.handle,count,&count,
            (XrSwapchainImageBaseHeader*)m_hudChain.images.data())))return false;
    }
    XrSwapchainImageAcquireInfo ai{XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO};
    if(XR_FAILED(xrAcquireSwapchainImage(m_hudChain.handle,&ai,&m_hudChain.acquiredIndex)))return false;
    XrSwapchainImageWaitInfo wi{XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO};wi.timeout=XR_INFINITE_DURATION;
    if(XR_FAILED(xrWaitSwapchainImage(m_hudChain.handle,&wi)))return false;
    const bool copied=copyIntoSwapchain(m_hudChain,src);
    XrSwapchainImageReleaseInfo ri{XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO};
    const bool released=XR_SUCCEEDED(xrReleaseSwapchainImage(m_hudChain.handle,&ri));
    m_hudChain.acquiredIndex=UINT32_MAX;
    if(!copied || !released)return false;
    if(!m_sessionAnchor.ready())return false;
    title=m_hudPlacement.selectTitle(title);
    if(!m_hudAnchorSet || m_hudTitle!=title) {
        m_hudTitle=title;
        m_hudAnchor=m_sessionAnchor.hud(title);
        m_hudAnchorSet=true;
        CVR_INFO("hud.anchor","source=session_anchor mario_title=%d fixed_stage=1 forward=2 rise=%.2f frontal=1 full_canvas=1",int(title),title?.35f:1.20f);
    }
    m_hudReady=true;return true;
}

SubmitResult XrCore::submitEye(CemuVR_Eye eye, ID3D11Texture2D* src) {
    if (!m_frameActive) {
        ++m_stats.eyesDropped;
        CVR_WARN("stereo.submit", "dropped=1 reason=no_active_frame eye=%d", (int)eye);
        return SubmitResult::Dropped;
    }
    const int e = (eye == CEMUVR_EYE_LEFT) ? 0 : 1;
    EyeChain& chain = m_chains[e];

    XrSwapchainImageAcquireInfo ai{XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO};
    uint32_t idx = 0;
    XrResult r = xrAcquireSwapchainImage(chain.handle, &ai, &idx);
    if (XR_FAILED(r)) {
        CVR_ERR("xr.swapchain", "op=xrAcquireSwapchainImage eye=%d result=%s",
                e, xrResultName(m_instance, r));
        ++m_stats.syncErrors;
        return SubmitResult::Error;
    }
    chain.acquiredIndex = idx;

    XrSwapchainImageWaitInfo wi{XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO};
    wi.timeout = XR_INFINITE_DURATION;
    r = xrWaitSwapchainImage(chain.handle, &wi);
    if (XR_FAILED(r)) {
        CVR_ERR("xr.swapchain", "op=xrWaitSwapchainImage eye=%d result=%s",
                e, xrResultName(m_instance, r));
        ++m_stats.syncErrors;
        XrSwapchainImageReleaseInfo ri{XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO};
        xrReleaseSwapchainImage(chain.handle, &ri);
        chain.acquiredIndex = UINT32_MAX;
        return SubmitResult::Error;
    }

    const bool copied = copyIntoSwapchain(chain, src);

    XrSwapchainImageReleaseInfo ri{XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO};
    r = xrReleaseSwapchainImage(chain.handle, &ri);
    if (XR_FAILED(r)) {
        CVR_ERR("xr.swapchain", "op=xrReleaseSwapchainImage eye=%d result=%s",
                e, xrResultName(m_instance, r));
        ++m_stats.syncErrors;
    }
    chain.acquiredIndex = UINT32_MAX;

    if (!copied) {
        ++m_stats.eyesDropped;
        return SubmitResult::Error;
    }

    chain.hasContent = true;
    m_eyeReady[e] = true;
    ++m_stats.eyesSubmitted;

    // Die Pose FESTHALTEN, jetzt, wo das Bild kopiert ist. Nicht erst beim
    // Einreichen: dazwischen kann ein weiteres Gastbild liegen, und ein
    // wiederholtes Auge bekaeme dann eine Pose, zu der sein Inhalt nicht
    // gehoert.
    if (m_cfg.poseBleibtBeimBild && m_viewsValid && m_viewHistN > 0) {
        // Bildweg 0 = die Ansicht dieses XR-Bildes. Groesser = so viele
        // XR-Bilder zurueck; fehlt der Eintrag, wird NICHT genommen, was
        // gerade da ist, sondern der Stempel bleibt, wie er war.
        const uint32_t zurueck = m_cfg.bildwegGastbilder;
        if (zurueck < kViewHist && zurueck < m_viewHistN) {
            const uint32_t slot = (m_viewHistN - 1u - zurueck) % kViewHist;
            if (m_viewHistOk[slot]) {
                m_eyeStamp[e].pose        = m_viewHist[slot][e].pose;
                m_eyeStamp[e].fov         = m_viewHist[slot][e].fov;
                m_eyeStamp[e].poseSerial  = m_stats.poseSerial;
                m_eyeStamp[e].presentIndex = m_presentIndex;
                m_eyeStamp[e].viewSerial  = m_viewHistN - 1u - zurueck;
                m_eyeStamp[e].valid       = true;
            }
        }
    }

    if (m_cfg.checksumEyes) {
        m_stats.lastEyeChecksum[e] = checksumTexture(src);
        CVR_INFO("stereo.checksum", "eye=%d pair=%u crc=%08x",
                 e, m_pairId, m_stats.lastEyeChecksum[e]);
    }
    if (m_cfg.bildLageMessen) {
        // Erst ernten, dann anstossen: das gibt einen Platz frei, bevor der
        // neue gebraucht wird.
        lageProbenErnten(false);
        lageProbeAnstossen(src, e);
    }
    CVR_TRACE("stereo.submit", "eye=%d pair=%u swapIndex=%u ok=1", e, m_pairId, idx);

    return (m_eyeReady[0] && m_eyeReady[1]) ? SubmitResult::PairComplete : SubmitResult::Ok;
}

void XrCore::releaseAllAcquired() {
    for (auto& c : m_chains) {
        if (c.acquiredIndex != UINT32_MAX && c.handle != XR_NULL_HANDLE) {
            XrSwapchainImageReleaseInfo ri{XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO};
            xrReleaseSwapchainImage(c.handle, &ri);
            c.acquiredIndex = UINT32_MAX;
        }
    }
}

// ---------------------------------------------------------------------------
// Uebergabe an das Spielprofil
// ---------------------------------------------------------------------------

bool XrCore::fillFrameContext(CemuVR_FrameContext* out, CemuVR_Eye eye,
                              uint64_t guestSwapCounter, uint32_t pairId) const {
    if (!out) return false;
    std::memset(out, 0, sizeof(*out));
    out->structVersion    = CEMUVR_PROFILE_ABI;
    out->guestSwapCounter = guestSwapCounter;
    out->coreFrameIndex   = m_coreFrameIndex;
    out->poseSerial       = m_stats.poseSerial;
    // Kernvorschlag 0004, Stufe A.
    out->predictedDisplayTime = (int64_t)m_frameState.predictedDisplayTime;
    out->presentIndex     = m_presentIndex;
    out->swapImageIndex   = m_swapImageIndex;
    out->copiedEyeChannel = (uint32_t)((eye == CEMUVR_EYE_LEFT) ? 0 : 1);
    out->eye              = eye;
    out->pairId           = pairId;
    out->worldScale       = m_cfg.worldScale;
    out->nearPlane        = m_cfg.nearPlane;
    out->farPlane         = m_cfg.farPlane;

    if (!m_viewsValid) return false;

    for (int e = 0; e < 2; ++e) {
        out->eyePose[e].orientation = {m_views[e].pose.orientation.x, m_views[e].pose.orientation.y,
                                       m_views[e].pose.orientation.z, m_views[e].pose.orientation.w};
        out->eyePose[e].position    = {m_views[e].pose.position.x, m_views[e].pose.position.y,
                                       m_views[e].pose.position.z};
        out->eyeFov[e] = {m_views[e].fov.angleLeft, m_views[e].fov.angleRight,
                          m_views[e].fov.angleUp,   m_views[e].fov.angleDown};
    }
    // Kopfpose = Mittelwert beider Augen. Position arithmetisch, Orientierung
    // vom linken Auge uebernommen; beide Augen tragen dieselbe Orientierung,
    // solange die Runtime kein gekipptes Display meldet.
    out->headPose.position = {
        0.5f * (out->eyePose[0].position.x + out->eyePose[1].position.x),
        0.5f * (out->eyePose[0].position.y + out->eyePose[1].position.y),
        0.5f * (out->eyePose[0].position.z + out->eyePose[1].position.z)
    };
    out->headPose.orientation = out->eyePose[0].orientation;
    out->ipdMetres = ipd();

    const int e = (eye == CEMUVR_EYE_LEFT) ? 0 : 1;
    out->viewMatrix = makeView(m_views[e].pose, m_cfg.worldScale);
    out->projMatrix = makeProjection(m_views[e].fov, m_cfg.nearPlane, m_cfg.farPlane);
    return true;
}

} // namespace cemuvr
