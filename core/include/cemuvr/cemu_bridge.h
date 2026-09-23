// CemuVR -- Zugriff auf Cemus eigenes Objektmodell.
//
// Diese Einheit ist die EINZIGE im Kern, die Cemu-Adressen kennt. Alles andere
// arbeitet auf Vulkan- und OpenXR-Ebene.
//
// GRUNDSATZ
//   Keine dieser Adressen wird gebraucht, um das Bild zu kopieren -- das
//   geschieht vollstaendig ueber die Vulkan-API. Sie dienen der GEGENPROBE und
//   dem Gast-Swapzaehler. Faellt die Gegenprobe aus, arbeitet der Kern weiter
//   und protokolliert, dass er ohne sie laeuft.
//
// ASLR
//   Cemu.exe traegt DYNAMIC_BASE und HIGH_ENTROPY_VA (aus dem PE-Header
//   nachgelesen). Jede dokumentierte Adresse ist eine Adresse zur Bildbasis
//   0x140000000 und MUSS umgerechnet werden:
//       tatsaechlich = Modulbasis + (dokumentiert - 0x140000000)
//   Ohne diese Umrechnung greift jeder Zugriff ins Leere.
#pragma once

#define NOMINMAX
#include <windows.h>
#ifndef VK_USE_PLATFORM_WIN32_KHR
#define VK_USE_PLATFORM_WIN32_KHR
#endif
#include <vulkan/vulkan.h>
#include <cstdint>
#include <cstring>

namespace cemuvr {

// Die dokumentierten Adressen, jeweils zur PE-Bildbasis 0x140000000.
// Herkunft je Eintrag in 03_ENGINES/.
struct CemuAddresses {
    static const uint64_t kImageBase        = 0x140000000ull;
    static const uint64_t kRendererSingleton= 0x1417F7F68ull; // .data  CEMU-GFX
    static const uint64_t kRendererVTable   = 0x1413B0A08ull; // .rdata CEMU-GFX
    static const uint64_t kGuestSwapCounter = 0x1416F9948ull; // .data  CEMU-FRM-004
    static const uint64_t kLatteRegisters   = 0x1416798E0ull; // .data  CEMU-GFX-010

    // Offsets im Renderer-Objekt
    static const uint32_t kOffTvSwapchain   = 0x5A8;          // CEMU-RTI-008
    static const uint32_t kOffPadSwapchain  = 0x5B0;          // CEMU-RTI-008
    // Offsets im SwapchainInfo-Objekt
    static const uint32_t kOffScImageIndex  = 0x50;           // CEMU-RTI-009
    static const uint32_t kOffScImageVector = 0x70;           // CEMU-RTI-009
    // Offsets im VKRObjectTexture
    static const uint32_t kOffTexAlloc      = 0x118;          // CEMU-RTI-004
    static const uint32_t kOffAllocImage    = 0x38;           // CEMU-RTI-004
};

// Was die Gegenprobe ergeben hat. Jeder Wert traegt, ob er belegt ist.
struct BridgeStatus {
    bool moduleFound{false};
    bool exportsFound{false};
    bool rendererFound{false};
    bool vtableMatches{false};
    bool swapCounterPlausible{false};
    bool swapCounterRefuted{false};
    uint32_t swapCounterProbes{0};
    uint32_t swapCounterChanges{0};
    bool tvSwapchainIdentified{false};
    int  tvSwapchainOffset{-1};       // gefundener Offset des VkSwapchainKHR im SwapchainInfo
    bool imageCrossCheckDone{false};
    bool imageCrossCheckAgreed{false};
    uint64_t crossCheckAgree{0};
    uint64_t crossCheckDisagree{0};
};

class CemuBridge {
public:
    // An den laufenden Cemu-Prozess binden. Schlaegt nie hart fehl: was nicht
    // auffindbar ist, wird als nicht auffindbar protokolliert.
    void attach();

    bool attached() const { return m_status.moduleFound; }
    const BridgeStatus& status() const { return m_status; }

    uint8_t* moduleBase() const { return m_base; }
    uint64_t rebase(uint64_t documented) const {
        return m_base ? (uint64_t)m_base + (documented - CemuAddresses::kImageBase) : 0;
    }

    // --- Cemus eigene Exporte -------------------------------------------
    uint64_t titleId() const;
    uint8_t* guestMemoryBase() const;

    // --- Renderer-Singleton (Punkt 2) -----------------------------------
    void* renderer() const { return m_renderer; }
    // Erneut lesen; der Singleton entsteht erst beim Anlegen des Renderers.
    bool refreshRenderer();

    // --- Gast-Swapzaehler ------------------------------------------------
    // Big Endian im Gastspeicher, deshalb beim Lesen drehen.
    //
    // ACHTUNG: Der Wert wird SELBST GEPRUEFT. Die dokumentierte Adresse
    // CEMU-FRM-004 liefert im laufenden Spiel keinen je Frame steigenden
    // Zaehler (gemessen 2026-09-06: 4 verschiedene Werte bei 3501 Frames).
    // Bewaehrt er sich in den ersten Frames nicht, wird er als unbrauchbar
    // vermerkt und nicht mehr benutzt.
    uint32_t guestSwapCounter();
    bool swapCounterUsable() const { return m_counterUsable; }

    // --- TV-Erkennung (Punkt 5), Gegenprobe ------------------------------
    // Sucht im TV-SwapchainInfo-Objekt nach einem der bekannten
    // VkSwapchainKHR-Handles. Findet sie eines, ist damit ZWEIERLEI belegt:
    // welches Objekt der TV ist, und an welchem Offset das Handle steht.
    VkSwapchainKHR findTvSwapchain(const VkSwapchainKHR* known, uint32_t count);

    // --- Bildableitung ueber Cemus Objektmodell (Punkte 3 und 4) ---------
    // Liefert das VkImage, das Cemu selbst gerade als TV-Bild fuehrt.
    // Rein zur Gegenprobe gegen den Weg ueber vkGetSwapchainImagesKHR.
    VkImage tvImageFromCemuObjects();

    // Ergebnis der Gegenprobe verbuchen.
    void recordCrossCheck(VkImage fromApi, VkImage fromCemu);

private:
    bool readable(const void* p, size_t n) const;
    template <typename T> bool read(uint64_t addr, T* out) const {
        if (!readable((const void*)addr, sizeof(T))) return false;
        std::memcpy(out, (const void*)addr, sizeof(T));
        return true;
    }

    uint8_t* m_base{nullptr};
    void*    m_renderer{nullptr};
    void*    m_tvSwapchainInfo{nullptr};
    BridgeStatus m_status{};

    bool     m_counterUsable{true};
    bool     m_counterDecided{false};
    uint32_t m_counterLast{0xFFFFFFFFu};

    uint64_t (*m_getTitleId)(){nullptr};
    void*    (*m_getMemoryBase)(){nullptr};
};

} // namespace cemuvr
