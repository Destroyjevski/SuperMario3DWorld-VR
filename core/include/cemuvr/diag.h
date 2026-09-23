// CemuVR-Kern -- Diagnose
//
// Maschinenlesbare Protokollierung. Jede Zeile ist ein Datensatz mit festem
// Schluessel=Wert-Aufbau, damit Auswertung ohne Textverstaendnis moeglich ist.
//
// Reine ASCII-Ausgabe. Keine Abhaengigkeit ausser der C++-Standardbibliothek
// und der Win32-API.
#pragma once

#include <cstdint>
#include <cstdio>
#include <cstdarg>
#ifdef _MSC_VER
#include <share.h>
#endif
#include <mutex>
#include <cstring>
#include <cstdlib>
#include <string>

namespace cemuvr {

enum class Sev { Info, Warn, Error, Trace };

class Diag {
public:
    static Diag& get() {
        static Diag d;
        return d;
    }

    // Datei oeffnen. Bei Misserfolg bleibt nur die Konsolenausgabe.
    void open(const char* path) {
        std::lock_guard<std::mutex> lk(m_mtx);
        if (m_file) { std::fclose(m_file); m_file = nullptr; }
        if (path && *path) {
#ifdef _MSC_VER
            // _SH_DENYWR statt fopen_s: andere Prozesse duerfen waehrend des
            // Laufs MITLESEN. Ohne das ist das Protokoll bis zum Prozessende
            // gesperrt und eine laufende Beobachtung unmoeglich.
            m_file = _fsopen(path, "w", _SH_DENYWR);
#else
            m_file = std::fopen(path, "w");
#endif
        }
    }

    void close() {
        std::lock_guard<std::mutex> lk(m_mtx);
        if (m_file) { std::fclose(m_file); m_file = nullptr; }
    }

    void setEcho(bool on) { m_echo = on; }
    void setTrace(bool on) { m_trace = on; }

    // Ein Datensatz. `kind` ist der Satztyp, `fmt` die Schluessel=Wert-Liste.
    // Periodic status records are diagnostics: written only with
    // CEMUVR_DIAG=1. One-time records, warnings and errors always go out.
    // Periodic diagnostic output is opt-in.
    static bool periodicKind(const char* kind) {
        static const char* const kinds[] = {
            "reference.pose", "reference.stamp", "reference.transport", "reference.surface",
            "reference.hud", "reference.clear", "reference.snapshot", "reference.pair",
            "reference.attach", "reference.xrpose", "xr.drehung", "stereo.bildlage",
            "stereo.bildlage.bilanz", "stereo.checksum", "performance" };
        for (const char* k : kinds) if (!std::strcmp(kind, k)) return true;
        return false;
    }
    static bool diagWanted() {
        static const bool on = [] { const char* v = std::getenv("CEMUVR_DIAG"); return v && v[0] == '1'; }();
        return on;
    }
    void rec(Sev sev, const char* kind, const char* fmt, ...) {
        if (sev == Sev::Trace && !m_trace) return;
        if (sev == Sev::Info && !diagWanted() && periodicKind(kind)) return;
        char body[1024];
        va_list ap;
        va_start(ap, fmt);
        std::vsnprintf(body, sizeof(body), fmt, ap);
        va_end(ap);

        const char* s = "INFO";
        switch (sev) {
            case Sev::Warn:  s = "WARN"; break;
            case Sev::Error: s = "ERR "; break;
            case Sev::Trace: s = "TRC "; break;
            default: break;
        }

        std::lock_guard<std::mutex> lk(m_mtx);
        const unsigned long long n = ++m_seq;
        if (m_file) {
            std::fprintf(m_file, "%06llu %s %-14s %s\n", n, s, kind, body);
            std::fflush(m_file);
        }
        if (m_echo) {
            std::fprintf(stdout, "%06llu %s %-14s %s\n", n, s, kind, body);
            std::fflush(stdout);
        }
    }

    unsigned long long records() const { return m_seq; }

private:
    Diag() = default;
    ~Diag() { close(); }
    Diag(const Diag&) = delete;
    Diag& operator=(const Diag&) = delete;

    std::FILE* m_file{nullptr};
    bool m_echo{true};
    bool m_trace{true};
    std::mutex m_mtx;
    unsigned long long m_seq{0};
};

} // namespace cemuvr

#define CVR_INFO(kind, ...)  ::cemuvr::Diag::get().rec(::cemuvr::Sev::Info,  kind, __VA_ARGS__)
#define CVR_WARN(kind, ...)  ::cemuvr::Diag::get().rec(::cemuvr::Sev::Warn,  kind, __VA_ARGS__)
#define CVR_ERR(kind, ...)   ::cemuvr::Diag::get().rec(::cemuvr::Sev::Error, kind, __VA_ARGS__)
#define CVR_TRACE(kind, ...) ::cemuvr::Diag::get().rec(::cemuvr::Sev::Trace, kind, __VA_ARGS__)
