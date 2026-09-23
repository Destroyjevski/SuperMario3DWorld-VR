// CemuVR -- Profilwirt.
//
// Die Einheit, die im LAUFENDEN Kern ein Spielprofil sucht, laedt, prueft,
// aufruft und wieder entlaedt. Der Offline-Pruefer (cemuvr_profileprobe.exe)
// belegt nur Format und statische Gueltigkeit; erst diese Einheit belegt, dass
// ein fremdes Profil ohne Aenderung am Kern tatsaechlich benutzt wird.
//
// GRUNDSATZ
//   Kein Fehler eines Profils darf Cemu zum Absturz bringen. Jeder Aufruf in
//   fremden Code laeuft in einem geschuetzten Rahmen; eine Zugriffsverletzung
//   im Profil beendet das Profil, nicht das Spiel.
#pragma once

#define NOMINMAX
#include <windows.h>
#include <cstdint>
#include <string>
#include <vector>

#include "cemuvr/profile.h"

namespace cemuvr {

// Zustand des Wirts. Bei fehlendem oder unpassendem Profil wird KONTROLLIERT
// einer dieser Zustaende eingenommen -- der Kern laeuft in jedem Fall weiter.
enum class ProfileStatus {
    NoTitle,          // noch kein Titel bekannt
    NoDirectory,      // Profilordner fehlt
    NoCandidate,      // Ordner da, aber kein Profil fuer diesen Titel
    AbiMismatch,      // Profil gefunden, ABI passt nicht
    LoadFailed,       // DLL nicht ladbar oder Einsprungpunkt fehlt
    Incomplete,       // Pflichtfunktionen fehlen
    InitFailed,       // profile_init hat einen Fehler gemeldet
    Faulted,          // Profil hat eine Ausnahme ausgeloest, stillgelegt
    Active            // Profil laeuft
};

const char* profileStatusName(ProfileStatus s);

struct ProfileHostStats {
    uint64_t initCalls{0};
    uint64_t shutdownCalls{0};
    uint64_t frameCalls{0};
    uint64_t adjustCalls{0};
    uint64_t frameLeft{0};
    uint64_t frameRight{0};
    uint64_t skipped{0};        // shouldRender meldete SKIP
    uint64_t notReady{0};
    uint64_t errors{0};         // Profil meldete CEMUVR_ERROR
    uint64_t faults{0};         // Ausnahme im Profil
    uint64_t adjustsApplied{0};
    uint64_t candidatesSeen{0};
    uint64_t candidatesRejected{0};
};

class ProfileHost {
public:
    ~ProfileHost();

    // Profilordner setzen. Standard: <Verzeichnis der Schicht>\profiles
    void setDirectory(const std::wstring& dir) { m_dir = dir; }
    const std::wstring& directory() const { return m_dir; }

    // Punkte 1 bis 6: Titel erkennen, Profil finden, ABI pruefen, laden,
    // Funktionen aufloesen, profile_init rufen.
    // `titleId` kommt aus Cemus Export gameMeta_getTitleId.
    // Rueckgabe true = ein Profil ist aktiv.
    bool attachToTitle(uint64_t titleId, uint8_t* guestBase);

    // Punkt 10: Titelwechsel. Ist es derselbe Titel, passiert nichts.
    bool titleChanged(uint64_t titleId) const { return titleId != m_titleId; }

    // Punkt 7 und 8: der Frame-Rueckruf.
    // Ruft shouldRender, applyCamera und adjustEye -- alle geschuetzt.
    // `adjustOut` wird nur beschrieben, wenn das Profil etwas liefert.
    // Rueckgabe false = dieser Gastframe soll NICHT stereoskopisch ausgegeben
    // werden (das Profil hat SKIP gemeldet).
    // surfaceOut darf null sein. Ist es das nicht und liefert das Profil
    // einen Auftrag, traegt es ihn ein; sonst bleibt er auf mode 0 stehen --
    // also bei der normalen Stereoausgabe.
    bool frame(const CemuVR_FrameContext* ctx, CemuVR_EyeAdjust* adjustOut,
               CemuVR_SurfaceRequest* surfaceOut = nullptr);

    // Punkt 10: profile_shutdown rufen und die DLL entladen.
    void detach(const char* reason);

    ProfileStatus status() const { return m_status; }
    bool active() const { return m_status == ProfileStatus::Active; }
    const ProfileHostStats& stats() const { return m_stats; }
    const CemuVR_ProfileInfo& info() const { return m_info; }
    uint64_t titleId() const { return m_titleId; }
    const std::string& profileFile() const { return m_file; }

private:
    void setStatus(ProfileStatus s, const char* detail);
    bool tryCandidate(const std::wstring& path, uint64_t titleId);

    std::wstring m_dir;
    HMODULE      m_module{nullptr};
    CemuVR_ProfileApi  m_api{};
    CemuVR_ProfileInfo m_info{};
    ProfileStatus m_status{ProfileStatus::NoTitle};
    ProfileHostStats m_stats{};
    uint64_t m_titleId{0};
    std::string m_file;
    bool m_initDone{false};
};

} // namespace cemuvr
