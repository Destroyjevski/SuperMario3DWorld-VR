// CemuVR -- Zugriff auf Cemus eigenes Objektmodell, Implementierung.
#include "cemuvr/cemu_bridge.h"
#include "cemuvr/diag.h"

#include <cstring>

namespace cemuvr {

// Jeder Zugriff geht durch diese Pruefung. Ein falscher Offset darf Cemu
// NICHT zum Absturz bringen -- er darf nur dazu fuehren, dass die Gegenprobe
// ausfaellt und das protokolliert wird.
bool CemuBridge::readable(const void* p, size_t n) const {
    if (!p) return false;
    MEMORY_BASIC_INFORMATION mbi{};
    if (VirtualQuery(p, &mbi, sizeof(mbi)) != sizeof(mbi)) return false;
    if (mbi.State != MEM_COMMIT) return false;
    if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return false;
    const uint8_t* start = (const uint8_t*)mbi.BaseAddress;
    const uint8_t* end   = start + mbi.RegionSize;
    return ((const uint8_t*)p + n) <= end;
}

void CemuBridge::attach() {
    HMODULE mod = GetModuleHandleW(L"Cemu.exe");
    if (!mod) {
        // Cemu kann auch anders heissen. Dann das Hauptmodul nehmen und pruefen.
        mod = GetModuleHandleW(nullptr);
        wchar_t path[MAX_PATH]{};
        GetModuleFileNameW(mod, path, MAX_PATH);
        CVR_WARN("cemu.module", "name=Cemu.exe nicht gefunden; Hauptmodul=\"%ls\"", path);
    }
    m_base = (uint8_t*)mod;
    m_status.moduleFound = (m_base != nullptr);
    if (!m_base) {
        CVR_ERR("cemu.module", "reason=no_module");
        return;
    }

    wchar_t path[MAX_PATH]{};
    GetModuleFileNameW(mod, path, MAX_PATH);
    CVR_INFO("cemu.module", "base=%p path=\"%ls\" slide=0x%llX",
             (void*)m_base, path,
             (unsigned long long)((uint64_t)m_base - CemuAddresses::kImageBase));

    m_getTitleId    = (uint64_t(*)())GetProcAddress(mod, "gameMeta_getTitleId");
    m_getMemoryBase = (void*(*)())  GetProcAddress(mod, "memory_getBase");
    m_status.exportsFound = (m_getTitleId && m_getMemoryBase);
    CVR_INFO("cemu.exports", "gameMeta_getTitleId=%p memory_getBase=%p",
             (void*)m_getTitleId, (void*)m_getMemoryBase);

    refreshRenderer();
}

uint64_t CemuBridge::titleId() const {
    return m_getTitleId ? m_getTitleId() : 0;
}

uint8_t* CemuBridge::guestMemoryBase() const {
    return m_getMemoryBase ? (uint8_t*)m_getMemoryBase() : nullptr;
}

// --- Punkt 2: Renderer-Singleton -------------------------------------------

bool CemuBridge::refreshRenderer() {
    if (!m_base) return false;

    void* r = nullptr;
    if (!read(rebase(CemuAddresses::kRendererSingleton), &r) || !r) {
        m_renderer = nullptr;
        m_status.rendererFound = false;
        return false;
    }
    if (!readable(r, 0x600)) {
        CVR_WARN("cemu.renderer", "ptr=%p reason=not_readable", r);
        m_renderer = nullptr;
        m_status.rendererFound = false;
        return false;
    }

    // Die vtable ist die Identitaetspruefung. Stimmt sie, ist es DER Renderer
    // dieses Cemu-Builds und nicht irgendein Zeiger.
    void* vtbl = nullptr;
    std::memcpy(&vtbl, r, sizeof(vtbl));
    const uint64_t expected = rebase(CemuAddresses::kRendererVTable);
    const bool match = ((uint64_t)vtbl == expected);

    if (m_renderer != r || m_status.vtableMatches != match) {
        CVR_INFO("cemu.renderer", "ptr=%p vtable=%p expected=0x%llX match=%d",
                 r, vtbl, (unsigned long long)expected, (int)match);
    }
    m_renderer = r;
    m_status.rendererFound = true;
    m_status.vtableMatches = match;
    if (!match) {
        CVR_WARN("cemu.renderer",
                 "vtable_mismatch -- andere Cemu-Version oder OpenGL-Renderer; "
                 "Gegenprobe wird abgeschaltet");
    }
    return true;
}

// --- Gast-Swapzaehler ------------------------------------------------------

uint32_t CemuBridge::guestSwapCounter() {
    if (!m_base || !m_counterUsable) return 0;
    uint32_t be = 0;
    if (!read(rebase(CemuAddresses::kGuestSwapCounter), &be)) return 0;
    // Big Endian im Gastspeicher.
    const uint32_t v = (be >> 24) | ((be >> 8) & 0x0000FF00u) |
                       ((be << 8) & 0x00FF0000u) | (be << 24);

    // Selbstpruefung. Ein Frameszaehler MUSS sich von Frame zu Frame aendern.
    // Tut er das in den ersten 120 Abfragen nicht mindestens zur Haelfte, ist
    // die Adresse fuer diesen Zweck widerlegt -- dann wird sie stillgelegt,
    // statt jeden Frame eine falsche Wiederholung zu melden.
    if (!m_counterDecided) {
        if (m_counterLast != 0xFFFFFFFFu && v != m_counterLast) ++m_status.swapCounterChanges;
        m_counterLast = v;
        if (++m_status.swapCounterProbes >= 120) {
            m_counterDecided = true;
            const bool ok = (m_status.swapCounterChanges * 2 >= m_status.swapCounterProbes);
            m_status.swapCounterPlausible = ok;
            m_counterUsable = ok;
            if (ok) {
                CVR_INFO("cemu.swapcounter",
                         "usable=1 probes=%u changes=%u addr=CEMU-FRM-004",
                         m_status.swapCounterProbes, m_status.swapCounterChanges);
            } else {
                m_status.swapCounterRefuted = true;
                CVR_WARN("cemu.swapcounter",
                         "WIDERLEGT usable=0 probes=%u changes=%u -- die dokumentierte "
                         "Adresse 0x1416F9948 (CEMU-FRM-004) ist im laufenden Spiel kein "
                         "je Frame steigender Zaehler; es wird auf die Zaehlung der "
                         "TV-Praesentationen umgeschaltet",
                         m_status.swapCounterProbes, m_status.swapCounterChanges);
            }
        }
    }
    return v;
}

// --- Punkt 5: TV-Erkennung, Gegenprobe -------------------------------------

VkSwapchainKHR CemuBridge::findTvSwapchain(const VkSwapchainKHR* known, uint32_t count) {
    if (!m_renderer || !m_status.vtableMatches || !known || !count) return VK_NULL_HANDLE;

    void* sc = nullptr;
    if (!read((uint64_t)m_renderer + CemuAddresses::kOffTvSwapchain, &sc) || !sc) return VK_NULL_HANDLE;
    if (!readable(sc, 0x100)) return VK_NULL_HANDLE;
    m_tvSwapchainInfo = sc;

    // Der Offset des VkSwapchainKHR im SwapchainInfo ist nicht dokumentiert.
    // Statt zu raten wird das Objekt nach einem der Handles abgesucht, die die
    // Vulkan-Schicht selbst erzeugt hat. Ein Treffer belegt beides zugleich:
    // welches Objekt der TV ist, und wo das Handle darin steht.
    for (uint32_t off = 0; off + 8 <= 0x100; off += 8) {
        uint64_t v = 0;
        if (!read((uint64_t)sc + off, &v) || !v) continue;
        for (uint32_t i = 0; i < count; ++i) {
            if (v == (uint64_t)known[i]) {
                if (m_status.tvSwapchainOffset != (int)off) {
                    CVR_INFO("cemu.tvswapchain",
                             "swapchainInfo=%p offset=0x%02X handle=0x%llX -- "
                             "Gegenprobe gefunden", sc, off, (unsigned long long)v);
                }
                m_status.tvSwapchainOffset = (int)off;
                m_status.tvSwapchainIdentified = true;
                return (VkSwapchainKHR)v;
            }
        }
    }
    if (!m_status.tvSwapchainIdentified)
        CVR_TRACE("cemu.tvswapchain", "swapchainInfo=%p kein bekanntes Handle gefunden", sc);
    return VK_NULL_HANDLE;
}

// --- Punkte 3 und 4: Texturobjekt und VkImage-Ableitung --------------------

VkImage CemuBridge::tvImageFromCemuObjects() {
    if (!m_tvSwapchainInfo) return VK_NULL_HANDLE;

    uint32_t idx = 0;
    if (!read((uint64_t)m_tvSwapchainInfo + CemuAddresses::kOffScImageIndex, &idx))
        return VK_NULL_HANDLE;
    if (idx > 16) return VK_NULL_HANDLE;         // offensichtlich unplausibel

    void* vec = nullptr;
    if (!read((uint64_t)m_tvSwapchainInfo + CemuAddresses::kOffScImageVector, &vec) || !vec)
        return VK_NULL_HANDLE;
    if (!readable(vec, sizeof(void*) * (idx + 1))) return VK_NULL_HANDLE;

    uint64_t img = 0;
    if (!read((uint64_t)vec + sizeof(void*) * idx, &img) || !img) return VK_NULL_HANDLE;
    return (VkImage)img;
}

void CemuBridge::recordCrossCheck(VkImage fromApi, VkImage fromCemu) {
    if (fromCemu == VK_NULL_HANDLE) return;
    m_status.imageCrossCheckDone = true;
    if (fromApi == fromCemu) {
        ++m_status.crossCheckAgree;
        m_status.imageCrossCheckAgreed = true;
        if (m_status.crossCheckAgree == 1)
            CVR_INFO("cemu.crosscheck",
                     "agree=1 image=0x%llX -- Vulkan-API und Cemus Objektmodell "
                     "nennen dasselbe Bild", (unsigned long long)(uint64_t)fromApi);
    } else {
        ++m_status.crossCheckDisagree;
        if (m_status.crossCheckDisagree <= 3)
            CVR_WARN("cemu.crosscheck", "disagree api=0x%llX cemu=0x%llX",
                     (unsigned long long)(uint64_t)fromApi,
                     (unsigned long long)(uint64_t)fromCemu);
    }
}

} // namespace cemuvr
