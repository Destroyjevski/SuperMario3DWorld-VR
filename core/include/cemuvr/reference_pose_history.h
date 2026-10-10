#pragma once
#include "profile.h"
#include <array>
#include <cstdint>

namespace cemuvr {
// Mailbox seqlock and wire token are independent. Zero means "not published".
inline uint32_t nextReferencePoseSequence(uint32_t sequence) {
    sequence += 2u;
    return sequence ? sequence : 2u;
}

// Touch markers carry the full mailbox sequence, not the wrapping wire token.
inline bool referencePoseSequenceMatches(uint32_t left, uint32_t right, uint32_t expected) {
    return expected && !(expected & 1u) && left == expected && right == expected;
}

// Access is serialized by the layer's g_mtx. Tokens are only a 16-bit wire
// representation; queued markers retain the full publication identity below.
class ReferencePoseHistory {
public:
    static constexpr uint32_t maxToken = 65535;
    static constexpr size_t capacity = 2048;
    struct Entry {
        uint64_t publication{};
        uint32_t token{};
        CemuVR_FrameContext context{};
        uint32_t mailboxSequence{};
    };
    struct Published {
        uint64_t publication{};
        uint32_t token{};
        bool wrapped{};
    };

    Published publish(const CemuVR_FrameContext& context, bool strictDiagnostic = false, uint32_t mailboxSequence = 0) {
        if (strictDiagnostic && m_publication >= maxToken) return {};
        const bool wrapped = m_token == maxToken;
        m_token = wrapped ? 1u : m_token + 1u;
        // A 64-bit rollover is not a session limit either. Discard the old ring.
        if (++m_publication == 0) { m_entries = {}; m_publication = 1; }
        m_entries[m_publication % capacity] = {m_publication, m_token, context, mailboxSequence};
        return {m_publication, m_token, wrapped};
    }

    // Resolve once, when the pose marker is intercepted, NOT at presentation.
    // The guest latches one mailbox for both eyes; serial command processing
    // and the two transport slots bound pending work. No token-only reference
    // is allowed to survive in the host and get reinterpreted after a wrap.
    uint64_t bind(uint32_t token) const {
        if (!token || token > maxToken || !m_publication) return 0;
        const uint32_t age = (m_token + maxToken - token) % maxToken;
        if (age >= capacity || age >= m_publication) return 0;
        const uint64_t publication = m_publication - age;
        return find(publication, token) ? publication : 0;
    }

    const Entry* find(uint64_t publication, uint32_t token) const {
        if (!publication || !token || token > maxToken ||
            publication > m_publication || m_publication - publication >= capacity) return nullptr;
        const auto& entry = m_entries[publication % capacity];
        return entry.publication == publication && entry.token == token ? &entry : nullptr;
    }

    const Entry* pair(uint64_t left, uint64_t right, uint32_t leftToken, uint32_t rightToken) const {
        if (left != right || leftToken != rightToken) return nullptr;
        return find(left, leftToken);
    }

private:
    uint64_t m_publication{};
    uint32_t m_token{};
    std::array<Entry, capacity> m_entries{};
};
}
