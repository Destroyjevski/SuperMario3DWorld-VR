// CemuVR-Kern -- allgemeiner OpenXR-Unterbau
//
// Enthaelt KEINE Cemu- und KEINE spielspezifische Kenntnis. Die Einheit ist fuer
// sich mit einem OpenXR-Testtreiber auch ohne Cemu gegen einen FakeHMD testbar.
//
// Grafikbindung: D3D11 fuer den gemeinsamen Vulkan/D3D11-Transport.
#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include <array>

#include <windows.h>
#include <d3d11.h>

#define XR_USE_PLATFORM_WIN32
#define XR_USE_GRAPHICS_API_D3D11
#include <openxr/openxr.h>
#include <openxr/openxr_platform.h>

#include "cemuvr/profile.h"
#include "cemuvr/session_anchor.h"
#include "cemuvr/hud_marker.h"

namespace cemuvr {

// Zustand des Kerns. Streng monoton bis Shutdown.
enum class XrState {
    Uninitialised,
    InstanceReady,
    SessionCreated,
    SessionRunning,
    Stopping,
    Ended,
    Failed
};

// Ergebnis eines Augen-Submits.
enum class SubmitResult {
    Ok,              // Auge angenommen
    PairComplete,    // Auge angenommen und das Paar wurde eingereicht
    Dropped,         // verworfen (kein aktiver XR-Frame)
    Error
};

struct XrCoreConfig {
    std::string appName{"CemuVR"};
    std::string engineName{"Cemu"};
    // Aufloesung je Auge. 0 = Empfehlung der Runtime uebernehmen.
    uint32_t eyeWidth{0};
    uint32_t eyeHeight{0};
    // Weltmasstab: Welteinheiten je Meter. Vom Spielprofil ueberschreibbar.
    float worldScale{1.0f};
    float nearPlane{0.05f};
    float farPlane{1000.0f};
    // Wenn true, wird bei fehlendem Partnerauge das zuletzt gueltige wiederholt.
    bool repeatMissingEye{true};
    // Senkrechtes Sichtfeld der Ausgabeebene in Grad. 0 = Sichtfeld der
    // Runtime uebernehmen (bisheriges Verhalten).
    //
    // Ein Gastbild ist mit dem SYMMETRISCHEN Frustum des Spiels gerendert,
    // nicht mit dem unsymmetrischen des Headsets. Reicht man es mit dem
    // Augenfrustum der Runtime ein, liegt seine Mitte je Auge an einer
    // anderen Winkelposition -- ein fester Winkel zwischen den Augenbildern,
    // der keine Tiefe traegt und die Augen auseinanderzieht. Ist hier ein
    // Wert gesetzt, bekommen BEIDE Augen dasselbe, symmetrische Sichtfeld.
    // Erst dann ist der Weltmasstab des Profils auch wirklich der Masstab.
    float layerFovVerticalDeg{0.0f};
    // Diagnose: je Auge eine Pruefsumme des eingereichten Bildes bilden.
    // Kostet eine GPU-Rueckkopie je Auge, daher standardmaessig aus.
    bool checksumEyes{false};
    // One new eye per XR submission; the retained eye keeps its image pose.
    // This increases delivery frequency, not the rate of new eye contents.
    bool streamGuestFrames{false};

    // Diagnose: je Auge den Helligkeitsschwerpunkt des eingereichten Bildes
    // messen. Er beantwortet, was eine Pruefsumme nicht beantworten kann:
    // WOHIN sich der Bildinhalt verschoben hat. Zusammen mit einer bekannten
    // Markenfolge im Profil laesst sich daraus der Bildweg des Emulators
    // bestimmen -- die Haelfte der Zuordnung, die auf der Gastseite
    // grundsaetzlich nicht messbar ist.
    //
    // Er benutzt denselben Rueckkopiepfad wie checksumEyes. Beides zugleich
    // waere zweimal dieselbe Kopie, deshalb schaltet der Wirt die Pruefsumme
    // dafuer ab.
    bool bildLageMessen{false};

    // --- Kernvorschlag 0004: die Pose gehoert zum Bild --------------------
    //
    // Bisher reichte endFrame die Ebenen mit m_views ein -- der Pose des
    // gerade laufenden XR-Bildes. Fuer ein frisch kopiertes Auge ist das
    // dasselbe wie die Pose beim Kopieren. Fuer ein WIEDERHOLTES Auge ist es
    // etwas anderes: dessen Inhalt gehoert zu einer aelteren Pose, bekommt
    // aber die aktuelle aufgeklebt.
    //
    // Mit poseBleibtBeimBild wird die Pose beim KOPIEREN festgehalten und
    // wandert mit dem Bild. Bei Bildweg 0 und ohne Wiederholung ist das
    // bitgleich das bisherige Verhalten; der Unterschied betrifft genau die
    // Wiederholungen.
    bool poseBleibtBeimBild{true};

    // Wie viele GASTBILDER alt die Pose sein soll, mit der ein Bild
    // eingereicht wird. 0 = die Pose beim Kopieren.
    //
    // EINHEIT GASTBILDER, ausdruecklich. Die Vorgaengerfassung zaehlte
    // XR-Bilder, und ein XR-Bild traegt zwei Gastbilder -- eine gemessene
    // Zahl aus dem Markenlauf haette hier also nicht unverwandelt
    // hineingedurft. Jetzt sind beide Seiten in derselben Einheit, und die
    // Umrechnung entfaellt statt schiefzugehen.
    //
    // Das ist der Vergleichsschalter fuer einen GEMESSENEN Weg. Er wird NICHT
    // geraten: ohne Messung bleibt er auf 0.
    uint32_t bildwegGastbilder{0};
    // Gewuenschtes Swapchainformat. DXGI_FORMAT_UNKNOWN = der Kern waehlt.
    // Die Cemu-Anbindung setzt hier die Kanalreihenfolge von Cemus eigener
    // Swapchain, damit die Kopie eine reine Bitkopie bleibt und Rot und Blau
    // nicht stillschweigend tauschen.
    DXGI_FORMAT preferredFormat{DXGI_FORMAT_UNKNOWN};
};

// Zaehler fuer die Diagnose. Alle vom Auftrag verlangten Groessen.
struct XrCoreStats {
    // Wie oft ein WIEDERHOLTES Auge mit SEINER eigenen Pose
    // eingereicht wurde statt mit der des laufenden Bildes.
    uint64_t stampsReused{0};

    // --- Der Rueckleseweg der Bildlage -------------------------------
    // Sie stehen hier und nicht privat, damit der Kerntest sie pruefen kann.
    // Ein Messfuehler, dessen Bilanz nur im Protokoll steht, laesst sich
    // nicht gegenpruefen.
    uint64_t lageKopien{0};          // angestossene Proben
    uint64_t lageGeerntet{0};        // ausgewertete Proben
    uint64_t lageUebersprungen{0};   // kein freier Platz im Ring
    uint64_t lageVerworfen{0};       // zu lange nicht bereit
    uint64_t lageNochNicht{0};       // Ernteversuche, die zu frueh kamen
    double   lageKopieMsMax{0.0};    // laengste Kopie
    double   lageErnteMsMax{0.0};    // laengster Ernteversuch
    double   lageKopieMsSumme{0.0};
    double   lageErnteMsSumme{0.0};
    uint64_t framesWaited{0};
    uint64_t framesBegun{0};
    uint64_t framesEnded{0};
    uint64_t streamFrames{0};
    uint64_t framesSkipped{0};      // kein xrWaitFrame-Ergebnis bereit
    uint64_t eyesSubmitted{0};
    uint64_t pairsComplete{0};      // beide Augen in diesem XR-Frame neu befuellt
    uint64_t pairsIncomplete{0};    // ein Auge fehlte
    uint64_t eyesRepeated{0};       // fehlendes Auge durch Wiederholung ersetzt
    uint64_t eyesDropped{0};
    uint64_t eyesOverflow{0};       // drittes Auge im selben XR-Frame angeboten
    uint64_t guestFramesSeen{0};
    uint64_t guestFramesRepeated{0};// derselbe Gastzaehler zweimal angeboten
    uint64_t guestFramesMissed{0};  // Luecken im Gastzaehler
    uint64_t syncErrors{0};
    uint64_t poseSerial{0};
    uint64_t recenters{0};
    // Zuletzt eingereichte Bildpruefsumme je Auge (nur bei checksumEyes).
    uint32_t lastEyeChecksum[2]{0, 0};
};

// Tasten eines VR-Controllers, so wie die Schicht sie meldet. Bewusst
// abstrakt: welcher Knopf eines konkreten Controllers das ist, entscheiden
// die Bindungen, nicht der Gast.
enum : uint32_t {
    kPadPrimary   = 1u << 0,   // A beziehungsweise X
    kPadSecondary = 1u << 1,   // B beziehungsweise Y
    kPadStick     = 1u << 2,   // Stickklick
    kPadMenu      = 1u << 3,
    kPadTrigger   = 1u << 4,   // aus dem Analogwert abgeleitet
    kPadSqueeze   = 1u << 5,
};

// Was eine Hand gerade meldet. Die Pose steht in DEMSELBEN Bezugsraum wie die
// Kopfpose -- ohne den gemeinsamen Raum liesse sich nicht fragen, ob eine Hand
// am Kopf ist, und genau diese Geste soll das Steuerkreuz aufschalten.
struct ControllerInput {
    uint32_t valid{0};        // 1 = verbunden und geortet
    XrPosef  pose{};
    uint32_t buttons{0};
    float    trigger{0.0f};
    float    squeeze{0.0f};
    float    stickX{0.0f};
    float    stickY{0.0f};
};

class XrCore {
public:
    XrCore() = default;
    ~XrCore();

    XrCore(const XrCore&) = delete;
    XrCore& operator=(const XrCore&) = delete;

    // --- Lebenszyklus ---------------------------------------------------
    bool initialise(const XrCoreConfig& cfg);
    // Sitzung aufbauen. Wenn `device` null ist, legt der Kern ein eigenes
    // D3D11-Geraet auf dem von OpenXR genannten Adapter an.
    bool createSession(ID3D11Device* device);
    void shutdown();

    // Ereignisse abholen. Muss regelmaessig gerufen werden.
    // Rueckgabe false = die Sitzung soll enden.
    bool pollEvents();

    XrState state() const { return m_state; }
    const XrCoreStats& stats() const { return m_stats; }

    // --- Frameloop ------------------------------------------------------
    // Wartet auf den naechsten Anzeigezeitpunkt und beginnt den XR-Frame.
    // Rueckgabe false = dieser Frame wird uebersprungen.
    bool beginFrame();
    // Schliesst den XR-Frame. Ohne vollstaendiges Augenpaar wird eine leere
    // Ebenenliste eingereicht.
    void endFrame();

    // --- Stereo ---------------------------------------------------------
    // Meldet einen neuen Gastframe an. Liefert das Auge, das dieser Gastframe
    // erzeugen soll, und die Paarnummer.
    // `guestSwapCounter` ist Cemus titelfreier Zaehler; im Test ein Ersatzwert.
    CemuVR_Eye beginGuestFrame(uint64_t guestSwapCounter, uint32_t* pairIdOut);

    // Uebergibt das fertige Augenbild. `src` muss dieselbe Groesse und ein
    // kopierkompatibles Format zur Swapchain haben.
    SubmitResult submitEye(CemuVR_Eye eye, ID3D11Texture2D* src);
    bool submitHud(ID3D11Texture2D* src,bool title=true);
    // Explicit metadata for the pair just copied; bypasses inferred history offset.
    bool stampRenderedPair(const CemuVR_FrameContext& rendered);

    // --- Posen und Projektion -------------------------------------------
    // Fuellt den Frame-Kontext fuer das Spielprofil. Gueltig zwischen
    // beginFrame und endFrame.
    bool fillFrameContext(CemuVR_FrameContext* out, CemuVR_Eye eye,
                          uint64_t guestSwapCounter, uint32_t pairId) const;

    void requestRecenter();
    // A valid runtime pose can still be an untracked origin placeholder.
    bool referenceAnchorReady() const {
        return m_viewsValid && m_viewsTracked && m_trackedFrames >= 30;
    }
    bool referenceAnchor(CemuVR_Pose* out) const {
        if(!out || !m_sessionAnchor.ready())return false;
        const auto& p=m_sessionAnchor.pose();
        *out={{p.orientation.x,p.orientation.y,p.orientation.z,p.orientation.w},
              {p.position.x,p.position.y,p.position.z}};
        return true;
    }

    // --- VR-Controller ---------------------------------------------------
    // Gueltig ab dem ersten beginFrame nach dem Aufbau. Ohne Controller oder
    // ohne Fokus bleibt `valid` null; das ist derselbe Zustand wie ein
    // abgelegter Controller und kein Sonderfall.
    const ControllerInput& controller(int hand) const { return m_hands[hand & 1]; }
    // Steigt mit jedem abgeholten Satz. Der Gast erkennt daran einen alten.
    uint32_t controllerGeneration() const { return m_handGeneration; }
    bool controllersReady() const { return m_actionsReady; }

    // Vom Spielprofil gelieferte Anpassung fuer das naechste endFrame.
    // Der Kern wendet sie auf die Projektionsebene DIESES Auges an.
    void setEyeAdjust(CemuVR_Eye eye, const CemuVR_EyeAdjust& a);

    // Was die Vulkan-Schicht ueber das gerade praesentierte Bild weiss.
    // Muss VOR fillFrameContext und submitEye gerufen werden.
    void setPresentInfo(uint64_t presentIndex, uint32_t swapImageIndex);
    // Nur fuer Pruefungen: welche Pose ist zuletzt zu welchem Auge eingereicht
    // worden? Ohne diese Auskunft liesse sich die Posebindung nur behaupten.
    bool eyeStamp(int e, XrPosef* pose, XrFovf* fov, uint64_t* poseSerial) const {
        if (e < 0 || e > 1 || !m_eyeStamp[e].valid) return false;
        if (pose) *pose = m_eyeStamp[e].pose;
        if (fov) *fov = m_eyeStamp[e].fov;
        if (poseSerial) *poseSerial = m_eyeStamp[e].poseSerial;
        return true;
    }
    void clearEyeAdjust();

    // --- Raumfeste Flaeche ----------------------------------------------
    // Statt der beiden Projektionsebenen wird EINE Flaeche eingereicht:
    // XrCompositionLayerQuad mit Pose und physischer Groesse im Referenzraum.
    // Sie bleibt stehen, wenn der Kopf sich bewegt -- das ist der Unterschied
    // zu jeder Bildverschiebung.
    //
    // Automatic placement derives from the shared initial session pose,
    // including when the surface is reopened after a menu/load transition.
    void setSurface(const CemuVR_SurfaceRequest& s);
    void clearSurface();
    bool surfaceActive() const { return m_surfaceMode != 0; }
    // Nur fuer den Testtreiber: der zuletzt eingereichte Flaechenauftrag.
    const XrPosef& surfaceAnchor() const { return m_surfaceAnchor; }
    const XrPosef& hudAnchor() const { return m_hudAnchor; }
    float surfaceWidth()  const { return m_surfaceW; }
    float surfaceHeight() const { return m_surfaceH; }
    uint64_t surfaceLayersSubmitted() const { return m_surfaceLayers; }

    // --- Abfragen -------------------------------------------------------
    uint32_t eyeWidth()  const { return m_eyeWidth; }
    uint32_t eyeHeight() const { return m_eyeHeight; }
    DXGI_FORMAT swapchainFormat() const { return m_format; }
    ID3D11Device* device() const { return m_device; }
    const std::string& runtimeName() const { return m_runtimeName; }
    float ipd() const;
    // Laeuft gerade ein XR-Frame? Die Cemu-Anbindung braucht das, weil sie
    // zwei Gastframes in einen XR-Frame einsortiert.
    bool frameActive() const { return m_frameActive; }
    // Bietet die Runtime eine Vulkan-Grafikbindung an? Nur zur Protokollierung
    // der Pfadentscheidung -- der Kern benutzt sie nicht.
    bool runtimeOffersVulkan() const { return m_runtimeVulkan; }

    // Nur fuer den Testtreiber: die zuletzt gelatchten Views.
    const std::array<XrView, 2>& views() const { return m_views; }

private:
    struct EyeChain {
        XrSwapchain handle{XR_NULL_HANDLE};
        std::vector<XrSwapchainImageD3D11KHR> images;
        uint32_t acquiredIndex{UINT32_MAX};
        bool hasContent{false};
    };

    bool createSwapchains();
    bool locateViews();
    void releaseAllAcquired();
    bool copyIntoSwapchain(EyeChain& chain, ID3D11Texture2D* src);
    uint32_t checksumTexture(ID3D11Texture2D* src);
    // Helligkeitsschwerpunkt des Bildes, waagerecht und senkrecht, jeweils
    // in -1..+1. Zusaetzlich die mittlere Helligkeit -- ein schwarzes Bild
    // hat keinen Schwerpunkt, und das muss unterscheidbar bleiben.
    // Eine Probe des gerade kopierten Augenbildes ANSTOSSEN. Sie wird NICHT
    // sofort ausgewertet: ein Map unmittelbar nach der Kopie wartet auf die
    // Grafikkarte und misst damit genau die Verzoegerung, die es zu messen
    // gilt. Stattdessen wird spaeter geerntet, wenn die Daten von selbst da
    // sind.
    void lageProbeAnstossen(ID3D11Texture2D* src, int eye);
    // Fertige Proben abholen. Nicht blockierend: was noch nicht da ist,
    // bleibt liegen und wird beim naechsten Mal versucht.
    void lageProbenErnten(bool amEnde);

    XrCoreConfig m_cfg{};
    XrState      m_state{XrState::Uninitialised};
    XrCoreStats  m_stats{};

    XrInstance  m_instance{XR_NULL_HANDLE};
    XrSystemId  m_systemId{XR_NULL_SYSTEM_ID};
    XrSession   m_session{XR_NULL_HANDLE};
    XrSpace     m_stageSpace{XR_NULL_HANDLE};
    XrSpace     m_viewSpace{XR_NULL_HANDLE};

    // --- VR-Controller (xr_actions.cpp) ---------------------------------
    bool createActions();
    void syncActions();
    void pulseAtHead();
    void destroyActions();

    XrActionSet m_actionSet{XR_NULL_HANDLE};
    XrAction    m_actPose{XR_NULL_HANDLE};
    XrAction    m_actTrigger{XR_NULL_HANDLE};
    XrAction    m_actSqueeze{XR_NULL_HANDLE};
    XrAction    m_actStick{XR_NULL_HANDLE};
    XrAction    m_actPrimary{XR_NULL_HANDLE};
    XrAction    m_actSecondary{XR_NULL_HANDLE};
    XrAction    m_actStickClick{XR_NULL_HANDLE};
    XrAction    m_actMenu{XR_NULL_HANDLE};
    XrAction    m_actHaptic{XR_NULL_HANDLE};
    // Wahr, solange die linke Hand am Kopf ist. Nur die steigende Flanke
    // loest aus - ein Puls, der sich wiederholt, waere ein Brummen.
    bool        m_handAtHead{false};
    std::array<XrPath, 2>  m_handPath{{XR_NULL_PATH, XR_NULL_PATH}};
    std::array<XrSpace, 2> m_handSpace{{XR_NULL_HANDLE, XR_NULL_HANDLE}};
    std::array<ControllerInput, 2> m_hands{};
    uint32_t m_handGeneration{0};
    bool     m_actionsReady{false};

    ID3D11Device*        m_device{nullptr};
    ID3D11DeviceContext* m_ctx{nullptr};
    bool                 m_ownDevice{false};

    std::array<EyeChain, 2> m_chains{};
    EyeChain m_hudChain{};
    XrPosef m_hudAnchor{};
    bool m_hudAnchorSet{},m_hudReady{},m_hudTitle{true};
    HudPlacement m_hudPlacement;
    std::array<XrView, 2>   m_views{};
    bool m_viewsValid{false};

    // --- Die Pose, die zu einem eingereichten Bild gehoert ---------------
    //
    // Sie wird beim Kopieren gesetzt (submitEye) und beim Einreichen benutzt
    // (endFrame). Ein wiederholtes Auge behaelt seine eigene -- das ist der
    // ganze Zweck.
    struct EyeStamp {
        XrPosef  pose{};
        XrFovf   fov{};
        uint64_t poseSerial{0};
        uint64_t presentIndex{0};
        uint32_t viewSerial{0};   // welcher Eintrag der Ansichtsgeschichte
        bool     valid{false};
    };
    std::array<EyeStamp, 2> m_eyeStamp{};
    bool m_explicitRenderedPair{false};

    // Ansichtsgeschichte, damit ein Bildweg > 0 die Pose von damals nehmen
    // kann. Ein Ring, kein Wachstum.
    //
    // JE GASTBILD ein Eintrag, nicht je XR-Bild. Die Ansicht aendert sich zwar
    // nur einmal je XR-Bild, aber der gemessene Weg zaehlt Gastbilder -- und
    // eine Geschichte in einer anderen Einheit als der Messwert ist genau die
    // Falle, in die man dabei tritt.
    static constexpr uint32_t kViewHist = 32;
    std::array<std::array<XrView, 2>, kViewHist> m_viewHist{};
    std::array<bool, kViewHist> m_viewHistOk{{false}};
    uint32_t m_viewHistN{0};      // wie viele Gastbilder schon abgelegt sind

    // Praesentationsangaben, die die Vulkan-Schicht je Gastbild meldet.
    uint64_t m_presentIndex{0};
    uint32_t m_swapImageIndex{0};

    uint32_t    m_eyeWidth{0};
    uint32_t    m_eyeHeight{0};
    DXGI_FORMAT m_format{DXGI_FORMAT_R8G8B8A8_UNORM_SRGB};
    std::string m_runtimeName;
    bool        m_runtimeVulkan{false};

    SessionAnchor m_sessionAnchor;
    XrReferenceSpaceType m_stageSpaceType{XR_REFERENCE_SPACE_TYPE_STAGE};
    XrPosef m_stageSpaceOffset{{0,0,0,1},{0,0,0}};
    std::vector<XrEventDataReferenceSpaceChangePending> m_spaceChanges;
    XrFrameState m_frameState{XR_TYPE_FRAME_STATE};
    bool m_frameActive{false};

    ID3D11Texture2D* m_staging{nullptr};   // nur fuer checksumEyes

    // --- Verzoegertes Ruecklesen der Bildlage ----------------------------
    //
    // Ein Ring aus Staging-Texturen. Beim Einreichen wird kopiert und die
    // Kennung des Bildes daneben abgelegt; geerntet wird ein oder mehr
    // Bilder spaeter, mit D3D11_MAP_FLAG_DO_NOT_WAIT. Die Kennung wandert
    // mit der Probe -- deshalb ist die Verzoegerung des Ruecklesens fuer die
    // Auswertung ohne Belang.
    struct LageProbe {
        ID3D11Texture2D* staging{nullptr};
        bool     belegt{false};
        uint64_t praesentation{0};
        uint32_t auge{0};
        uint32_t pairId{0};
        uint64_t kopiertBei{0};      // presentIndex zum Zeitpunkt der Kopie
    };
    static constexpr uint32_t kLageRing = 6;
    // Nach so vielen Gastbildern wird eine Probe aufgegeben. Sonst koennte
    // ein einziges haengendes Bild den Ring dauerhaft verstopfen.
    static constexpr uint64_t kLageGeduld = 12;
    std::array<LageProbe, kLageRing> m_lage{};
    double   m_lageBilanzMs{0.0};

    // Stereo-Buchfuehrung.
    // Die Augenzuteilung haengt an der Belegung des laufenden XR-Frames, nicht an
    // einem freilaufenden Zaehler: so enthaelt jeder XR-Frame genau ein linkes und
    // genau ein rechtes Auge, auch wenn der Gast einen Frame auslaesst oder
    // wiederholt. Der Gast-Swapzaehler dient der Erkennung genau dieser Faelle.
    uint32_t   m_pairId{0};
    uint64_t   m_lastGuestSwap{UINT64_MAX};
    std::array<bool, 2> m_eyeReady{{false, false}};
    uint64_t   m_coreFrameIndex{0};

    bool m_recenterRequested{false};

    std::array<CemuVR_EyeAdjust, 2> m_adjust{};
    std::array<bool, 2>             m_adjustSet{{false, false}};

    // Ist die Kopflage nicht nur GUELTIG, sondern auch VERFOLGT? Eine Runtime
    // darf beim Start eine gueltige, aber ungetrackte Pose melden -- meist die
    // des Ursprungs. Wer daran einen Anker setzt, haengt die Flaeche auf
    // Fussbodenhoehe auf.
    bool        m_viewsTracked{false};
    uint32_t    m_trackedFrames{0};
    uint32_t    m_validFrames{0};

    // Wie weit dreht sich der Kopf zwischen zwei XR-Bildern? Das ist der
    // Massstab fuer die Poselatenz: ein Bild Verzug kostet genau diesen
    // Winkel. Ohne die Zahl waere jede Aussage darueber geraten.
    XrQuaternionf m_letzteOri{0.0f, 0.0f, 0.0f, 1.0f};
    bool        m_letzteOriDa{false};
    double      m_drehSumme{0.0};
    double      m_drehMax{0.0};
    uint64_t    m_drehN{0};

    // Raumfeste Flaeche
    uint32_t    m_surfaceMode{0};
    uint32_t    m_surfaceAnchorMode{0};
    bool        m_surfaceAnchorSet{false};
    XrPosef     m_surfaceAnchor{{0.0f, 0.0f, 0.0f, 1.0f}, {0.0f, 0.0f, 0.0f}};
    float       m_surfaceW{1.739f};
    float       m_surfaceH{0.978f};
    float       m_surfaceDist{2.0f};
    uint64_t    m_surfaceLayers{0};
};

// Baut eine asymmetrische Off-Axis-Projektion aus einem OpenXR-Sichtfeld.
// Ergebnis ZEILENWEISE, OpenGL-Tiefenbereich (NDC-z in [-1, +1]).
CemuVR_Mat4 makeProjection(const XrFovf& fov, float nearZ, float farZ);

// Baut die View-Matrix aus einer Pose. Ergebnis ZEILENWEISE.
CemuVR_Mat4 makeView(const XrPosef& pose, float worldScale);

} // namespace cemuvr
