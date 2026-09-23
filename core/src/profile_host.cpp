// CemuVR -- Profilwirt, Implementierung.
#include "cemuvr/profile_host.h"
#include "cemuvr/diag.h"

#include <cstring>
#include <excpt.h>

namespace cemuvr {

const char* profileStatusName(ProfileStatus s) {
    switch (s) {
        case ProfileStatus::NoTitle:     return "NoTitle";
        case ProfileStatus::NoDirectory: return "NoDirectory";
        case ProfileStatus::NoCandidate: return "NoCandidate";
        case ProfileStatus::AbiMismatch: return "AbiMismatch";
        case ProfileStatus::LoadFailed:  return "LoadFailed";
        case ProfileStatus::Incomplete:  return "Incomplete";
        case ProfileStatus::InitFailed:  return "InitFailed";
        case ProfileStatus::Faulted:     return "Faulted";
        case ProfileStatus::Active:      return "Active";
    }
    return "?";
}

// ---------------------------------------------------------------------------
// Geschuetzte Aufrufe in fremden Code
// ---------------------------------------------------------------------------
//
// Jede dieser Huellen enthaelt KEINE C++-Objekte mit Destruktor -- das ist die
// Bedingung dafuer, dass __try/__except zulaessig ist. Eine Zugriffsverletzung
// im Profil landet hier und beendet das Profil, nicht Cemu.

namespace {

int filterAndReport(unsigned code, const char* what) {
    CVR_ERR("profile.fault", "op=%s exception=0x%08X -- Profil wird stillgelegt",
            what, code);
    return EXCEPTION_EXECUTE_HANDLER;
}

bool guardedDescribe(CemuVR_PFN_Describe fn, CemuVR_ProfileInfo* out, CemuVR_Result* res) {
    __try {
        *res = fn(out);
        return true;
    } __except (filterAndReport(GetExceptionCode(), "describe")) {
        return false;
    }
}

bool guardedAttach(CemuVR_PFN_Attach fn, const CemuVR_FrameContext* ctx, CemuVR_Result* res) {
    __try {
        *res = fn(ctx);
        return true;
    } __except (filterAndReport(GetExceptionCode(), "profile_init")) {
        return false;
    }
}

bool guardedApply(CemuVR_PFN_ApplyCamera fn, const CemuVR_FrameContext* ctx, CemuVR_Result* res) {
    __try {
        *res = fn(ctx);
        return true;
    } __except (filterAndReport(GetExceptionCode(), "applyCamera")) {
        return false;
    }
}

bool guardedShould(CemuVR_PFN_ShouldRender fn, const CemuVR_FrameContext* ctx, CemuVR_Result* res) {
    __try {
        *res = fn(ctx);
        return true;
    } __except (filterAndReport(GetExceptionCode(), "shouldRender")) {
        return false;
    }
}

bool guardedAdjust(CemuVR_PFN_AdjustEye fn, const CemuVR_FrameContext* ctx,
                   CemuVR_EyeAdjust* out, CemuVR_Result* res) {
    __try {
        *res = fn(ctx, out);
        return true;
    } __except (filterAndReport(GetExceptionCode(), "adjustEye")) {
        return false;
    }
}

bool guardedSurface(CemuVR_PFN_SurfaceRequest fn, const CemuVR_FrameContext* ctx,
                    CemuVR_SurfaceRequest* out, CemuVR_Result* res) {
    __try {
        *res = fn(ctx, out);
        return true;
    } __except (filterAndReport(GetExceptionCode(), "surfaceRequest")) {
        return false;
    }
}

bool guardedDetach(CemuVR_PFN_Detach fn) {
    __try {
        fn();
        return true;
    } __except (filterAndReport(GetExceptionCode(), "profile_shutdown")) {
        return false;
    }
}

bool guardedGetApi(CemuVR_PFN_GetProfileApi fn, CemuVR_ProfileApi* out, int* rc) {
    __try {
        *rc = fn(out);
        return true;
    } __except (filterAndReport(GetExceptionCode(), "CemuVR_GetProfileApi")) {
        return false;
    }
}

std::string narrow(const std::wstring& w) {
    if (w.empty()) return {};
    const int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), nullptr, 0, nullptr, nullptr);
    std::string s(n, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &s[0], n, nullptr, nullptr);
    return s;
}

} // namespace

// ---------------------------------------------------------------------------

ProfileHost::~ProfileHost() {
    // Kein detach() hier: der Destruktor kann bei Prozessende laufen, wenn die
    // Profil-DLL bereits entladen ist. Der geordnete Abbau steht in detach().
}

void ProfileHost::setStatus(ProfileStatus s, const char* detail) {
    if (m_status == s) return;
    m_status = s;
    CVR_INFO("profile.status", "state=%s %s", profileStatusName(s), detail ? detail : "");
}

// --- Punkte 1 bis 6 --------------------------------------------------------

bool ProfileHost::attachToTitle(uint64_t titleId, uint8_t* guestBase) {
    if (m_status == ProfileStatus::Active && titleId == m_titleId) return true;

    if (m_module || m_initDone) detach("titlechange");

    m_titleId = titleId;
    m_stats.candidatesSeen = 0;
    m_stats.candidatesRejected = 0;

    if (titleId == 0) { setStatus(ProfileStatus::NoTitle, "titleId=0"); return false; }

    CVR_INFO("profile.title", "titleId=%016llX dir=\"%s\"",
             (unsigned long long)titleId, narrow(m_dir).c_str());

    if (m_dir.empty()) { setStatus(ProfileStatus::NoDirectory, "dir=leer"); return false; }
    const DWORD attr = GetFileAttributesW(m_dir.c_str());
    if (attr == INVALID_FILE_ATTRIBUTES || !(attr & FILE_ATTRIBUTE_DIRECTORY)) {
        char d[600];
        std::snprintf(d, sizeof(d), "dir=\"%s\" existiert nicht", narrow(m_dir).c_str());
        setStatus(ProfileStatus::NoDirectory, d);
        return false;
    }

    // Punkt 2: passendes Profil finden.
    std::wstring pattern = m_dir + L"\\*.dll";
    WIN32_FIND_DATAW fd{};
    HANDLE h = FindFirstFileW(pattern.c_str(), &fd);
    if (h == INVALID_HANDLE_VALUE) {
        setStatus(ProfileStatus::NoCandidate, "keine DLL im Profilordner");
        return false;
    }
    bool found = false;
    do {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        ++m_stats.candidatesSeen;
        if (tryCandidate(m_dir + L"\\" + fd.cFileName, titleId)) { found = true; break; }
        ++m_stats.candidatesRejected;
    } while (FindNextFileW(h, &fd));
    FindClose(h);

    if (!found) {
        char d[256];
        std::snprintf(d, sizeof(d), "geprueft=%llu titleId=%016llX",
                      (unsigned long long)m_stats.candidatesSeen, (unsigned long long)titleId);
        if (m_status != ProfileStatus::AbiMismatch && m_status != ProfileStatus::Incomplete)
            setStatus(ProfileStatus::NoCandidate, d);
        return false;
    }

    // Punkt 6: profile_init.
    CemuVR_FrameContext ctx{};
    ctx.structVersion   = CEMUVR_PROFILE_ABI;
    ctx.titleId         = titleId;
    ctx.guestMemoryBase = guestBase;
    ctx.worldScale      = m_info.worldScale > 0.0f ? m_info.worldScale : 1.0f;
    ctx.nearPlane       = m_info.nearPlane;
    ctx.farPlane        = m_info.farPlane;

    CemuVR_Result r = CEMUVR_ERROR;
    if (!guardedAttach(m_api.attach, &ctx, &r)) {
        ++m_stats.faults;
        setStatus(ProfileStatus::Faulted, "profile_init hat eine Ausnahme ausgeloest");
        detach("fault-in-init");
        return false;
    }
    ++m_stats.initCalls;
    CVR_INFO("profile.init", "called=1 result=%d file=\"%s\" guestBase=%p",
             (int)r, m_file.c_str(), (void*)guestBase);

    if (r == CEMUVR_ERROR) {
        setStatus(ProfileStatus::InitFailed, "profile_init meldete CEMUVR_ERROR");
        detach("init-failed");
        return false;
    }
    m_initDone = true;
    // NOT_READY ist ausdruecklich kein Fehler: das Profil laeuft, hat seine
    // Gastadressen nur noch nicht.
    setStatus(ProfileStatus::Active, m_file.c_str());
    return true;
}

bool ProfileHost::tryCandidate(const std::wstring& path, uint64_t titleId) {
    const std::string narrowPath = narrow(path);

    HMODULE mod = LoadLibraryW(path.c_str());
    if (!mod) {
        CVR_WARN("profile.candidate", "file=\"%s\" LoadLibrary=fehlgeschlagen err=%lu",
                 narrowPath.c_str(), GetLastError());
        return false;
    }

    auto getApi = (CemuVR_PFN_GetProfileApi)GetProcAddress(mod, CEMUVR_PROFILE_ENTRYPOINT);
    if (!getApi) {
        CVR_WARN("profile.candidate", "file=\"%s\" Einsprungpunkt %s fehlt",
                 narrowPath.c_str(), CEMUVR_PROFILE_ENTRYPOINT);
        FreeLibrary(mod);
        return false;
    }

    CemuVR_ProfileApi api{};
    int rc = 1;
    if (!guardedGetApi(getApi, &api, &rc) || rc != 0) {
        CVR_WARN("profile.candidate", "file=\"%s\" GetProfileApi rc=%d", narrowPath.c_str(), rc);
        FreeLibrary(mod);
        return false;
    }

    // Punkt 3: ABI pruefen.
    if (api.abiVersion != CEMUVR_PROFILE_ABI) {
        CVR_ERR("profile.abi", "file=\"%s\" profil=%u kern=%u -- abgelehnt",
                narrowPath.c_str(), api.abiVersion, CEMUVR_PROFILE_ABI);
        setStatus(ProfileStatus::AbiMismatch, narrowPath.c_str());
        FreeLibrary(mod);
        return false;
    }

    // Punkt 5: Pflichtfunktionen.
    if (!api.describe || !api.attach || !api.applyCamera) {
        CVR_ERR("profile.candidate", "file=\"%s\" Pflichtfunktionen fehlen "
                "(describe=%d attach=%d applyCamera=%d)",
                narrowPath.c_str(), api.describe != nullptr, api.attach != nullptr,
                api.applyCamera != nullptr);
        setStatus(ProfileStatus::Incomplete, narrowPath.c_str());
        FreeLibrary(mod);
        return false;
    }

    CemuVR_ProfileInfo info{};
    CemuVR_Result dr = CEMUVR_ERROR;
    if (!guardedDescribe(api.describe, &info, &dr) || dr != CEMUVR_OK) {
        CVR_WARN("profile.candidate", "file=\"%s\" describe result=%d", narrowPath.c_str(), (int)dr);
        FreeLibrary(mod);
        return false;
    }
    if (info.abiVersion != CEMUVR_PROFILE_ABI) {
        CVR_ERR("profile.abi", "file=\"%s\" describe meldet abi=%u", narrowPath.c_str(), info.abiVersion);
        setStatus(ProfileStatus::AbiMismatch, narrowPath.c_str());
        FreeLibrary(mod);
        return false;
    }

    // Punkt 1 und 2: passt das Profil zu diesem Titel?
    // titleId == 0 im Profil heisst "beliebig" und ist ausdruecklich erlaubt --
    // genau das braucht ein neutrales Testprofil.
    const bool matches = (info.titleId == 0) || (info.titleId == titleId);
    CVR_INFO("profile.candidate",
             "file=\"%s\" name=\"%s\" spiel=\"%s\" titleId=%016llX abi=%u passt=%d",
             narrowPath.c_str(), info.profileName, info.gameName,
             (unsigned long long)info.titleId, info.abiVersion, (int)matches);
    if (!matches) { FreeLibrary(mod); return false; }

    // Feste Gastadressen ohne Modulpruefsumme werden abgelehnt -- derselbe
    // Vertrag, den der Offline-Pruefer durchsetzt.
    const bool anyFixed = info.addrViewMatrix || info.addrProjMatrix ||
                          info.addrCameraPosition || info.addrCameraOrientation || info.addrFov;
    if (anyFixed && info.moduleChecksum == 0) {
        CVR_ERR("profile.candidate", "file=\"%s\" feste Gastadressen ohne moduleChecksum -- abgelehnt",
                narrowPath.c_str());
        FreeLibrary(mod);
        return false;
    }
    if (info.moduleChecksum != 0)
        CVR_WARN("profile.candidate",
                 "moduleChecksum=%08X wird NICHT geprueft -- das Verfahren ist noch "
                 "nicht rekonstruiert (CEMU-SIG-O1)", info.moduleChecksum);

    m_module = mod;
    m_api    = api;
    m_info   = info;
    m_file   = narrowPath;
    CVR_INFO("profile.load",
             "geladen file=\"%s\" name=\"%s\" abi=%u worldScale=%.4f near=%.4f far=%.4f "
             "adjustEye=%d shouldRender=%d detach=%d",
             narrowPath.c_str(), info.profileName, info.abiVersion,
             info.worldScale, info.nearPlane, info.farPlane,
             api.adjustEye != nullptr, api.shouldRender != nullptr, api.detach != nullptr);
    return true;
}

// --- Punkte 7 und 8 --------------------------------------------------------

bool ProfileHost::frame(const CemuVR_FrameContext* ctx, CemuVR_EyeAdjust* adjustOut,
                        CemuVR_SurfaceRequest* surfaceOut) {
    if (m_status != ProfileStatus::Active || !ctx) return true;

    ++m_stats.frameCalls;
    if (ctx->eye == CEMUVR_EYE_LEFT) ++m_stats.frameLeft; else ++m_stats.frameRight;

    CemuVR_Result r = CEMUVR_OK;

    if (m_api.shouldRender) {
        if (!guardedShould(m_api.shouldRender, ctx, &r)) {
            ++m_stats.faults;
            setStatus(ProfileStatus::Faulted, "Ausnahme in shouldRender");
            detach("fault-in-shouldRender");
            return true;
        }
        if (r == CEMUVR_SKIP) { ++m_stats.skipped; return false; }
    }

    if (!guardedApply(m_api.applyCamera, ctx, &r)) {
        ++m_stats.faults;
        setStatus(ProfileStatus::Faulted, "Ausnahme in applyCamera");
        detach("fault-in-applyCamera");
        return true;
    }
    if (r == CEMUVR_NOT_READY) ++m_stats.notReady;
    else if (r == CEMUVR_ERROR) ++m_stats.errors;

    // Der Flaechenauftrag kommt VOR adjustEye. So kann ein Profil im
    // Flaechenmodus die Bildverschiebung sein lassen -- sie waere dort nicht
    // nur ueberfluessig, sondern schaedlich, weil sie das Bild beschneidet.
    if (m_api.surfaceRequest && surfaceOut) {
        CemuVR_SurfaceRequest q{};
        q.structVersion = CEMUVR_PROFILE_ABI;
        q.mode = 0;
        CemuVR_Result sr = CEMUVR_OK;
        if (!guardedSurface(m_api.surfaceRequest, ctx, &q, &sr)) {
            ++m_stats.faults;
            setStatus(ProfileStatus::Faulted, "Ausnahme in surfaceRequest");
            detach("fault-in-surfaceRequest");
            return true;
        }
        if (sr == CEMUVR_OK) *surfaceOut = q;
    }

    if (m_api.adjustEye && adjustOut) {
        CemuVR_EyeAdjust a{};
        a.structVersion = CEMUVR_PROFILE_ABI;
        a.fovScale = 1.0f;
        CemuVR_Result ar = CEMUVR_OK;
        if (!guardedAdjust(m_api.adjustEye, ctx, &a, &ar)) {
            ++m_stats.faults;
            setStatus(ProfileStatus::Faulted, "Ausnahme in adjustEye");
            detach("fault-in-adjustEye");
            return true;
        }
        ++m_stats.adjustCalls;
        if (ar == CEMUVR_OK) {
            *adjustOut = a;
            ++m_stats.adjustsApplied;
        }
    }
    return true;
}

// --- Punkt 10 --------------------------------------------------------------

void ProfileHost::detach(const char* reason) {
    if (m_initDone && m_api.detach) {
        if (guardedDetach(m_api.detach)) {
            ++m_stats.shutdownCalls;
            CVR_INFO("profile.shutdown", "called=1 reason=%s file=\"%s\"",
                     reason ? reason : "?", m_file.c_str());
        } else {
            ++m_stats.faults;
        }
    } else if (m_initDone) {
        CVR_INFO("profile.shutdown", "called=0 reason=%s (Profil hat kein detach)",
                 reason ? reason : "?");
    }
    m_initDone = false;

    if (m_module) {
        FreeLibrary(m_module);
        CVR_INFO("profile.unload", "file=\"%s\" reason=%s", m_file.c_str(), reason ? reason : "?");
        m_module = nullptr;
    }
    std::memset(&m_api, 0, sizeof(m_api));
    std::memset(&m_info, 0, sizeof(m_info));
    m_file.clear();
    m_titleId = 0;
    if (m_status != ProfileStatus::Faulted) m_status = ProfileStatus::NoTitle;
}

} // namespace cemuvr
