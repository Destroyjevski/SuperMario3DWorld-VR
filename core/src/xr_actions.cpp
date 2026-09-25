// CemuVR-Kern -- die VR-Controller, nach Kernvorschlag 0006.
//
// WOZU DAS HIER STEHT
//
// Das Spielprofil ist PPC-Code im Gast. Es sieht ausschliesslich, was ihm die
// Schicht in den Gastspeicher legt. Die OpenXR-Laufzeit, und damit die
// Controller, sieht nur die Schicht. Ohne diesen Aktionssatz erreicht keine
// Controllertaste jemals das Profil -- und die Umschaltung haengt weiter an
// Cemus Eingabekonfiguration, die auf fremden Rechnern anders aussieht.
//
// DER GEMEINSAME BEZUGSRAUM IST DER KERN DER SACHE
//
// Geortet wird gegen m_stageSpace, also gegen genau den Raum, den auch
// xrLocateViews benutzt. Das ist keine Bequemlichkeit: Nur im gemeinsamen
// Raum hat der Abstand zwischen Hand und Kopf ueberhaupt eine Bedeutung, und
// genau dieser Abstand soll spaeter das Steuerkreuz aufschalten.
//
// WAS HIER NICHT PASSIERT
//
// Keine Haptik, kein Handtracking, keine sichtbaren Haende, keine Zeigestrahlen,
// keine eigenen Menues. Die Schicht liefert Zustand, sonst nichts. Was daraus
// fuer ein Spiel wird, entscheidet das Profil.
#include "cemuvr/xr_core.h"
#include "cemuvr/diag.h"

#include <cstring>

namespace cemuvr {

namespace {

// Ein Eintrag der Bindungstabelle. `hand` ist -1 fuer beide Haende.
struct Binding {
    XrAction* action;
    const char* suffix;   // ohne /user/hand/<seite>
    int hand;             // -1 = beide, 0 = links, 1 = rechts
};

const char* const kHandRoot[2] = {"/user/hand/left", "/user/hand/right"};

bool pathOf(XrInstance instance, const std::string& text, XrPath* out) {
    const XrResult r = xrStringToPath(instance, text.c_str(), out);
    if (XR_FAILED(r)) {
        CVR_WARN("xr.action", "op=xrStringToPath path=%s", text.c_str());
        return false;
    }
    return true;
}

} // namespace

// ---------------------------------------------------------------------------
// Aufbau
// ---------------------------------------------------------------------------

bool XrCore::createActions() {
    if (m_session == XR_NULL_HANDLE) return false;

    XrActionSetCreateInfo asi{XR_TYPE_ACTION_SET_CREATE_INFO};
    std::strcpy(asi.actionSetName, "cemuvr");
    std::strcpy(asi.localizedActionSetName, "CemuVR");
    asi.priority = 0;
    XrResult r = xrCreateActionSet(m_instance, &asi, &m_actionSet);
    if (XR_FAILED(r)) {
        CVR_ERR("xr.action", "op=xrCreateActionSet result=%d", (int)r);
        return false;
    }

    if (!pathOf(m_instance, kHandRoot[0], &m_handPath[0]) ||
        !pathOf(m_instance, kHandRoot[1], &m_handPath[1])) return false;

    struct Declare { XrAction* action; XrActionType type; const char* name; const char* label; };
    const Declare declare[] = {
        {&m_actPose,       XR_ACTION_TYPE_POSE_INPUT,     "hand_pose",   "Hand"},
        {&m_actTrigger,    XR_ACTION_TYPE_FLOAT_INPUT,    "trigger",     "Trigger"},
        {&m_actSqueeze,    XR_ACTION_TYPE_FLOAT_INPUT,    "squeeze",     "Grip"},
        {&m_actStick,      XR_ACTION_TYPE_VECTOR2F_INPUT, "stick",       "Stick"},
        {&m_actPrimary,    XR_ACTION_TYPE_BOOLEAN_INPUT,  "primary",     "Primary button"},
        {&m_actSecondary,  XR_ACTION_TYPE_BOOLEAN_INPUT,  "secondary",   "Secondary button"},
        {&m_actStickClick, XR_ACTION_TYPE_BOOLEAN_INPUT,  "stick_click", "Stick click"},
        {&m_actMenu,       XR_ACTION_TYPE_BOOLEAN_INPUT,  "menu",        "Menu"},
        {&m_actHaptic,     XR_ACTION_TYPE_VIBRATION_OUTPUT, "haptic",    "Haptics"},
    };
    for (const auto& d : declare) {
        XrActionCreateInfo aci{XR_TYPE_ACTION_CREATE_INFO};
        aci.actionType = d.type;
        std::strcpy(aci.actionName, d.name);
        std::strcpy(aci.localizedActionName, d.label);
        aci.countSubactionPaths = 2;
        aci.subactionPaths = m_handPath.data();
        r = xrCreateAction(m_actionSet, &aci, d.action);
        if (XR_FAILED(r)) {
            CVR_ERR("xr.action", "op=xrCreateAction name=%s result=%d", d.name, (int)r);
            return false;
        }
    }

    // Die Bindungen je Interaktionsprofil. Ein Pfad, den ein Profil nicht hat,
    // laesst die ganze Anmeldung scheitern -- deshalb steht hier je Profil
    // genau das, was es wirklich anbietet, und ein Fehlschlag kostet nur
    // dieses eine Profil.
    struct Profile { const char* path; std::vector<Binding> bindings; };
    const std::vector<Profile> profiles = {
        {"/interaction_profiles/khr/simple_controller", {
            {&m_actHaptic,    "/output/haptic",     -1},
            {&m_actPose,      "/input/grip/pose",   -1},
            {&m_actPrimary,   "/input/select/click", -1},
            {&m_actMenu,      "/input/menu/click",   -1},
        }},
        {"/interaction_profiles/oculus/touch_controller", {
            {&m_actHaptic,     "/output/haptic",          -1},
            {&m_actPose,       "/input/grip/pose",        -1},
            {&m_actTrigger,    "/input/trigger/value",    -1},
            {&m_actSqueeze,    "/input/squeeze/value",    -1},
            {&m_actStick,      "/input/thumbstick",       -1},
            {&m_actStickClick, "/input/thumbstick/click", -1},
            {&m_actPrimary,    "/input/x/click",           0},
            {&m_actSecondary,  "/input/y/click",           0},
            {&m_actPrimary,    "/input/a/click",           1},
            {&m_actSecondary,  "/input/b/click",           1},
            {&m_actMenu,       "/input/menu/click",        0},
        }},
        {"/interaction_profiles/valve/index_controller", {
            {&m_actHaptic,     "/output/haptic",          -1},
            {&m_actPose,       "/input/grip/pose",        -1},
            {&m_actTrigger,    "/input/trigger/value",    -1},
            {&m_actSqueeze,    "/input/squeeze/value",    -1},
            {&m_actStick,      "/input/thumbstick",       -1},
            {&m_actStickClick, "/input/thumbstick/click", -1},
            {&m_actPrimary,    "/input/a/click",          -1},
            {&m_actSecondary,  "/input/b/click",          -1},
        }},
        {"/interaction_profiles/htc/vive_controller", {
            {&m_actHaptic,     "/output/haptic",         -1},
            {&m_actPose,       "/input/grip/pose",       -1},
            {&m_actTrigger,    "/input/trigger/value",   -1},
            {&m_actSqueeze,    "/input/squeeze/click",   -1},
            {&m_actStick,      "/input/trackpad",        -1},
            {&m_actStickClick, "/input/trackpad/click",  -1},
            {&m_actMenu,       "/input/menu/click",      -1},
        }},
        {"/interaction_profiles/microsoft/motion_controller", {
            {&m_actHaptic,     "/output/haptic",          -1},
            {&m_actPose,       "/input/grip/pose",        -1},
            {&m_actTrigger,    "/input/trigger/value",    -1},
            {&m_actSqueeze,    "/input/squeeze/click",    -1},
            {&m_actStick,      "/input/thumbstick",       -1},
            {&m_actStickClick, "/input/thumbstick/click", -1},
            {&m_actMenu,       "/input/menu/click",       -1},
        }},
    };

    unsigned accepted = 0;
    for (const auto& profile : profiles) {
        std::vector<XrActionSuggestedBinding> suggested;
        bool ok = true;
        for (const auto& b : profile.bindings) {
            for (int hand = 0; hand < 2 && ok; ++hand) {
                if (b.hand >= 0 && b.hand != hand) continue;
                XrPath path{};
                if (!pathOf(m_instance, std::string(kHandRoot[hand]) + b.suffix, &path)) { ok = false; break; }
                suggested.push_back({*b.action, path});
            }
        }
        if (!ok) continue;
        XrPath profilePath{};
        if (!pathOf(m_instance, profile.path, &profilePath)) continue;
        XrInteractionProfileSuggestedBinding sb{XR_TYPE_INTERACTION_PROFILE_SUGGESTED_BINDING};
        sb.interactionProfile = profilePath;
        sb.countSuggestedBindings = (uint32_t)suggested.size();
        sb.suggestedBindings = suggested.data();
        r = xrSuggestInteractionProfileBindings(m_instance, &sb);
        if (XR_FAILED(r)) {
            // Kein Grund aufzugeben: ein Profil, das diese Laufzeit nicht
            // kennt, sagt nichts ueber die anderen.
            CVR_WARN("xr.action", "op=xrSuggestInteractionProfileBindings profile=%s result=%d",
                     profile.path, (int)r);
            continue;
        }
        ++accepted;
    }
    if (!accepted) {
        CVR_ERR("xr.action", "reason=no_interaction_profile_accepted");
        return false;
    }

    for (int hand = 0; hand < 2; ++hand) {
        XrActionSpaceCreateInfo si{XR_TYPE_ACTION_SPACE_CREATE_INFO};
        si.action = m_actPose;
        si.subactionPath = m_handPath[hand];
        si.poseInActionSpace.orientation.w = 1.0f;
        r = xrCreateActionSpace(m_session, &si, &m_handSpace[hand]);
        if (XR_FAILED(r)) {
            CVR_ERR("xr.action", "op=xrCreateActionSpace hand=%d result=%d", hand, (int)r);
            return false;
        }
    }

    XrSessionActionSetsAttachInfo ai{XR_TYPE_SESSION_ACTION_SETS_ATTACH_INFO};
    ai.countActionSets = 1;
    ai.actionSets = &m_actionSet;
    r = xrAttachSessionActionSets(m_session, &ai);
    if (XR_FAILED(r)) {
        CVR_ERR("xr.action", "op=xrAttachSessionActionSets result=%d", (int)r);
        return false;
    }

    m_actionsReady = true;
    CVR_INFO("xr.action", "ready=1 profiles=%u hands=2 space=stage", accepted);
    return true;
}

// ---------------------------------------------------------------------------
// Ein Bild lang Zustand abholen
// ---------------------------------------------------------------------------

void XrCore::syncActions() {
    if (!m_actionsReady || m_session == XR_NULL_HANDLE) return;

    XrActiveActionSet active{m_actionSet, XR_NULL_PATH};
    XrActionsSyncInfo si{XR_TYPE_ACTIONS_SYNC_INFO};
    si.countActiveActionSets = 1;
    si.activeActionSets = &active;
    const XrResult r = xrSyncActions(m_session, &si);
    if (XR_FAILED(r)) {
        // XR_SESSION_NOT_FOCUSED ist keine Stoerung, sondern der Normalfall,
        // solange ein Systemmenue vorn ist. Dann bleibt der letzte Zustand
        // stehen, und der Gast sieht keine zufaellig gedrueckte Taste.
        if (r != XR_SESSION_NOT_FOCUSED)
            CVR_WARN("xr.action", "op=xrSyncActions result=%d", (int)r);
        for (auto& hand : m_hands) { hand.buttons = 0; hand.trigger = 0.f; hand.squeeze = 0.f;
                                     hand.stickX = 0.f; hand.stickY = 0.f; }
        return;
    }

    for (int hand = 0; hand < 2; ++hand) {
        ControllerInput state{};
        XrActionStateGetInfo gi{XR_TYPE_ACTION_STATE_GET_INFO};
        gi.subactionPath = m_handPath[hand];

        auto readFloat = [&](XrAction action, float* out) {
            gi.action = action;
            XrActionStateFloat value{XR_TYPE_ACTION_STATE_FLOAT};
            if (XR_SUCCEEDED(xrGetActionStateFloat(m_session, &gi, &value)) && value.isActive)
                *out = value.currentState;
        };
        auto readButton = [&](XrAction action, uint32_t bit) {
            gi.action = action;
            XrActionStateBoolean value{XR_TYPE_ACTION_STATE_BOOLEAN};
            if (XR_SUCCEEDED(xrGetActionStateBoolean(m_session, &gi, &value)) &&
                value.isActive && value.currentState)
                state.buttons |= bit;
        };

        readFloat(m_actTrigger, &state.trigger);
        readFloat(m_actSqueeze, &state.squeeze);

        gi.action = m_actStick;
        XrActionStateVector2f stick{XR_TYPE_ACTION_STATE_VECTOR2F};
        if (XR_SUCCEEDED(xrGetActionStateVector2f(m_session, &gi, &stick)) && stick.isActive) {
            state.stickX = stick.currentState.x;
            state.stickY = stick.currentState.y;
        }

        readButton(m_actPrimary,    kPadPrimary);
        readButton(m_actSecondary,  kPadSecondary);
        readButton(m_actStickClick, kPadStick);
        readButton(m_actMenu,       kPadMenu);

        // Analoge Achsen bekommen zusaetzlich eine Taste. Der Schwellwert ist
        // grosszuegig genug, um nicht zu flackern, und klein genug, um nicht
        // wie ein klemmender Knopf zu wirken.
        if (state.trigger > 0.60f) state.buttons |= kPadTrigger;
        if (state.squeeze > 0.60f) state.buttons |= kPadSqueeze;

        gi.action = m_actPose;
        XrActionStatePose pose{XR_TYPE_ACTION_STATE_POSE};
        if (XR_SUCCEEDED(xrGetActionStatePose(m_session, &gi, &pose)) && pose.isActive) {
            XrSpaceLocation location{XR_TYPE_SPACE_LOCATION};
            const XrResult lr = xrLocateSpace(m_handSpace[hand], m_stageSpace,
                                              m_frameState.predictedDisplayTime, &location);
            const XrSpaceLocationFlags need = XR_SPACE_LOCATION_ORIENTATION_VALID_BIT |
                                              XR_SPACE_LOCATION_POSITION_VALID_BIT;
            if (XR_SUCCEEDED(lr) && (location.locationFlags & need) == need) {
                state.pose = location.pose;
                state.valid = 1;
            }
        }

        m_hands[hand] = state;
    }
    ++m_handGeneration;
    pulseAtHead();

}

// Der kurze Stups, wenn die linke Hand an den Kopf kommt.
//
// Dieselbe Frage, die das Spielprofil stellt, nur hier: Kopf und Hand liegen
// in demselben Bezugsraum, also ist der Abstand zwischen ihnen ein Abstand.
// Der Schwellwert muss zu dem in `motion.py` passen - dort 450 Spieleinheiten
// bei 1500 je Meter, hier dieselben 0,30 Meter.
void XrCore::pulseAtHead() {
    constexpr float kReach = 0.30f;
    const auto& hand = m_hands[0];
    bool atHead = false;   // MSVC: near ist ein altes Windows-Makro
    if (hand.valid && m_viewsValid) {
        const XrVector3f& a = m_views[0].pose.position;
        const XrVector3f& b = m_views[1].pose.position;
        const float dx = hand.pose.position.x - (a.x + b.x) * 0.5f;
        const float dy = hand.pose.position.y - (a.y + b.y) * 0.5f;
        const float dz = hand.pose.position.z - (a.z + b.z) * 0.5f;
        atHead = dx * dx + dy * dy + dz * dz < kReach * kReach;
    }
    if (atHead && !m_handAtHead && m_actHaptic != XR_NULL_HANDLE) {
        XrHapticVibration shake{XR_TYPE_HAPTIC_VIBRATION};
        shake.duration = 40 * 1000 * 1000;      // vierzig Millisekunden
        shake.frequency = XR_FREQUENCY_UNSPECIFIED;
        shake.amplitude = 0.5f;
        XrHapticActionInfo info{XR_TYPE_HAPTIC_ACTION_INFO};
        info.action = m_actHaptic;
        info.subactionPath = m_handPath[0];
        xrApplyHapticFeedback(m_session, &info, (const XrHapticBaseHeader*)&shake);
    }
    m_handAtHead = atHead;
}

void XrCore::destroyActions() {
    for (auto& space : m_handSpace)
        if (space != XR_NULL_HANDLE) { xrDestroySpace(space); space = XR_NULL_HANDLE; }
    if (m_actionSet != XR_NULL_HANDLE) {
        // Die einzelnen Aktionen gehoeren dem Satz und gehen mit ihm.
        xrDestroyActionSet(m_actionSet);
        m_actionSet = XR_NULL_HANDLE;
    }
    m_actPose = m_actTrigger = m_actSqueeze = m_actStick = XR_NULL_HANDLE;
    m_actPrimary = m_actSecondary = m_actStickClick = m_actMenu = XR_NULL_HANDLE;
    m_actHaptic = XR_NULL_HANDLE;
    m_handAtHead = false;
    m_hands = {};
    m_actionsReady = false;
}

} // namespace cemuvr
