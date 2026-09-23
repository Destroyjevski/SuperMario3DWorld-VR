#pragma once
#include <windows.h>
#include <array>
#include <algorithm>
#include <cstdio>
#include <vector>

namespace cemuvr {
inline double perfMs() {
    static const double scale=[] { LARGE_INTEGER f; QueryPerformanceFrequency(&f); return 1000.0/f.QuadPart; }();
    LARGE_INTEGER t; QueryPerformanceCounter(&t); return t.QuadPart*scale;
}
// Bounded in-memory observations. Disk I/O only at orderly shutdown.
struct PerfRow {
    unsigned long long present=0;
    int eye=0, surface=0, complete=0;
    double time=0, begin=0, profile=0, copy=0, presentWait=0, acquire=0, submit=0, end=0;
};
struct Performance {
    static constexpr size_t capacity=131072;
    std::vector<PerfRow> rows;
    unsigned long long dropped=0;
    void add(const PerfRow& row) {
        if (rows.empty()) rows.reserve(capacity);
        if (rows.size()<capacity) rows.push_back(row); else ++dropped;
    }
    void save(const char* logPath) {
        if (rows.empty()) return;
        const std::string path=std::string(logPath)+".performance.csv";
        FILE* f=nullptr;
        if (fopen_s(&f,path.c_str(),"w") || !f) { CVR_ERR("performance", "cannot_write=%s",path.c_str()); return; }
        fprintf(f,"present;eye;surface;complete;t_ms;begin_ms;profile_ms;copy_enqueue_ms;present_ms;acquire_ms;submit_ms;end_ms\n");
        for (const auto& r:rows) fprintf(f,"%llu;%d;%d;%d;%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;%.6f\n",
            r.present,r.eye,r.surface,r.complete,r.time,r.begin,r.profile,r.copy,r.presentWait,r.acquire,r.submit,r.end);
        fclose(f);
        CVR_INFO("performance", "rows=%zu dropped=%llu file=%s -- CPU wall durations, not GPU execution times",rows.size(),dropped,path.c_str());
        rows.clear();
    }
};
}
