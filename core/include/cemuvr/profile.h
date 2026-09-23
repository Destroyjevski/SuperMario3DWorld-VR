// CemuVR-Kern -- Spielprofilschnittstelle (ABI)
//
// Diese Datei ist der VERTRAG zwischen dem allgemeinen Cemu-VR-Kern und einem
// spielspezifischen Profil. Ein neuer Spiele-Workspace implementiert
// ausschliesslich diese Schnittstelle; er baut den Kern nicht um.
//
// Reines C-ABI: keine C++-Klassen, keine STL, keine Ausnahmen ueber die Grenze.
// Damit ist ein Profil als eigene DLL baubar, mit beliebigem Compiler.
//
// VERSIONIERUNG
//   Der Kern prueft CEMUVR_PROFILE_ABI beim Laden. Weicht die Zahl ab, wird das
//   Profil abgelehnt und der Grund protokolliert. Die Zahl wird nur erhoeht,
//   wenn sich Feldbedeutungen oder die Reihenfolge aendern.
#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CEMUVR_PROFILE_ABI 2u

// ABI 2 gegenueber ABI 1: CemuVR_EyeAdjust und CemuVR_PFN_AdjustEye kamen hinzu.
// Grund: ein Profil muss eine Aenderung bewirken koennen, die der Kern im
// echten Bildweg anwendet -- sonst laesst sich der Profilaufruf nicht ohne
// spielspezifisches Wissen nachweisen.

// ---------------------------------------------------------------------------
// Grunddatentypen
// ---------------------------------------------------------------------------

typedef struct CemuVR_Vec3 { float x, y, z; } CemuVR_Vec3;
typedef struct CemuVR_Quat { float x, y, z, w; } CemuVR_Quat;

typedef struct CemuVR_Pose {
    CemuVR_Quat orientation;   // Rotation im Referenzraum
    CemuVR_Vec3 position;      // Position im Referenzraum, Meter
} CemuVR_Pose;

// Sichtfeld wie von OpenXR gemeldet: Tangenswinkel in Radiant, vorzeichenbehaftet.
typedef struct CemuVR_Fov {
    float angleLeft, angleRight, angleUp, angleDown;
} CemuVR_Fov;

// 4x4-Matrix, ZEILENWEISE abgelegt (m[Zeile][Spalte]).
// Der Kern liefert sie immer in dieser Anordnung. Ein Profil, das eine andere
// Anordnung braucht, transponiert selbst -- ausdruecklich, nicht stillschweigend.
typedef struct CemuVR_Mat4 { float m[4][4]; } CemuVR_Mat4;

typedef enum CemuVR_Eye {
    CEMUVR_EYE_LEFT  = 0,
    CEMUVR_EYE_RIGHT = 1
} CemuVR_Eye;

// ---------------------------------------------------------------------------
// Was der Kern dem Profil je Gastframe liefert
// ---------------------------------------------------------------------------

typedef struct CemuVR_FrameContext {
    uint32_t     structVersion;      // == CEMUVR_PROFILE_ABI

    // Bildfolge
    uint64_t     guestSwapCounter;   // Cemus Gast-Swapzaehler, titelfrei
    uint64_t     coreFrameIndex;     // fortlaufend, vom Kern gezaehlt
    uint64_t     poseSerial;         // Seriennummer der Poseabfrage
    CemuVR_Eye   eye;                // welches Auge dieser Gastframe erzeugt
    uint32_t     pairId;             // Augenpaar, dem dieser Frame zugeordnet wird

    // Kopf und Augen, alle im STAGE-Referenzraum
    CemuVR_Pose  headPose;           // Mittelpunkt beider Augen
    CemuVR_Pose  eyePose[2];         // linkes und rechtes Auge
    CemuVR_Fov   eyeFov[2];
    float        ipdMetres;          // Abstand der beiden Augenpositionen

    // Fertig gebaute Matrizen fuer das aktive Auge, zeilenweise
    CemuVR_Mat4  viewMatrix;         // Weltraum nach Augenraum
    CemuVR_Mat4  projMatrix;         // asymmetrische Off-Axis-Projektion

    // Konfiguration, die das Profil setzen darf (siehe CemuVR_ProfileConfig)
    float        worldScale;         // Weltueinheiten je Meter
    float        nearPlane;
    float        farPlane;

    // Zugriff auf den Gastspeicher. Basis + 32-Bit-Offset.
    uint8_t*     guestMemoryBase;
    uint64_t     titleId;

    // ---------------------------------------------------------------------
    // Herkunft (Kernvorschlag 0004, Stufe A)
    // ---------------------------------------------------------------------
    //
    // Diese vier Werte hat der Kern ohnehin; sie wurden nur nicht
    // durchgereicht. Ohne sie kann ein Profil seine eigene Zeitrechnung nicht
    // an die des Kerns binden -- es zaehlt Gastbilder und weiss nicht, welches
    // Praesentationsbild und welche Anzeigezeit dazugehoeren.
    //
    // ANGEHAENGT, nicht umgedeutet: der Kern legt die Struktur an und fuellt
    // sie, ein aelteres Profil liest die neuen Felder einfach nicht. Deshalb
    // bleibt die ABI-Nummer bei 2, genau wie bei surfaceRequest.
    int64_t      predictedDisplayTime;  // aus xrWaitFrame, Nanosekunden
    uint64_t     presentIndex;          // fortlaufend je vkQueuePresentKHR
    uint32_t     swapImageIndex;        // welches Bild der TV-Swapchain
    // In welchen Augenkanal der Kern dieses Bild kopiert. Er entspricht heute
    // immer eye -- genau deshalb steht er hier: eine Uebereinstimmung, die man
    // PRUEFEN kann, ist mehr wert als eine, die man aus dem Quelltext
    // herleitet.
    uint32_t     copiedEyeChannel;
} CemuVR_FrameContext;

// ---------------------------------------------------------------------------
// Was das Profil ueber sich selbst erklaert
// ---------------------------------------------------------------------------

#define CEMUVR_MAX_SIGNATURES 32
#define CEMUVR_NAME_MAX       64

typedef enum CemuVR_HudMode {
    CEMUVR_HUD_IGNORE      = 0,  // HUD bleibt im Stereobild
    CEMUVR_HUD_SEPARATE    = 1,  // HUD wird als eigene Ebene ausgegeben
    CEMUVR_HUD_SUPPRESS    = 2   // HUD wird unterdrueckt
} CemuVR_HudMode;

typedef enum CemuVR_CullMode {
    CEMUVR_CULL_UNCHANGED  = 0,  // Culling bleibt, wie das Spiel es macht
    CEMUVR_CULL_WIDEN      = 1   // Frustum auf ein Ueberdeckungsfrustum weiten
} CemuVR_CullMode;

// Eine Signatur, mit der eine Gastadresse gefunden statt fest angegeben wird.
typedef struct CemuVR_Signature {
    char      name[CEMUVR_NAME_MAX];
    // Bytemuster mit Platzhaltern: mask[i] == 0 heisst "beliebig".
    uint8_t   pattern[64];
    uint8_t   mask[64];
    uint32_t  length;             // wieviele Bytes von pattern/mask gelten
    uint32_t  expectedHits;       // erwartete Trefferzahl; abweichend = Fehler
    uint32_t  searchStart;        // Gastadressbereich, 0 = ganzes Modul
    uint32_t  searchEnd;
    int32_t   resultOffset;       // Zuschlag auf den Treffer
} CemuVR_Signature;

typedef struct CemuVR_ProfileInfo {
    uint32_t  abiVersion;         // muss CEMUVR_PROFILE_ABI sein
    char      profileName[CEMUVR_NAME_MAX];
    char      gameName[CEMUVR_NAME_MAX];

    // Identifikation
    uint64_t  titleId;            // 0 = beliebig (nur fuer Vorlagen zulaessig)
    uint32_t  region;             // Cemus Regionscode; 0 = beliebig
    uint32_t  gameVersion;        // Version des Basisspiels
    uint32_t  updateVersion;      // Version des Updates, z. B. 208
    char      moduleName[CEMUVR_NAME_MAX];   // z. B. "U-King.rpx"
    uint32_t  moduleChecksum;     // derselbe Wert wie Cemus moduleMatches
    uint32_t  structVersion;      // Version der Spielstrukturlayouts im Profil

    // Signaturen statt fester Adressen
    CemuVR_Signature signatures[CEMUVR_MAX_SIGNATURES];
    uint32_t  signatureCount;

    // Feste Gastadressen -- nur zulaessig, wenn moduleChecksum gesetzt ist.
    // Der Kern lehnt feste Adressen ohne Pruefsumme ab.
    uint32_t  addrViewMatrix;
    uint32_t  addrProjMatrix;
    uint32_t  addrCameraPosition;
    uint32_t  addrCameraOrientation;
    uint32_t  addrFov;

    // Einstellungen
    float           worldScale;       // Welteinheiten je Meter, > 0
    float           nearPlane;
    float           farPlane;
    float           eyeOffsetScale;   // 1.0 = Runtime-IPD unveraendert
    CemuVR_CullMode cullMode;
    CemuVR_HudMode  hudMode;

    // Sonderkameras und Kinoszenen: Namen, die das Profil selbst deutet.
    char      specialCameras[8][CEMUVR_NAME_MAX];
    uint32_t  specialCameraCount;
    char      cutsceneTable[CEMUVR_NAME_MAX];  // Datei oder Kennung, leer = keine

    // Profilabhaengige Patches: Verzeichnisname eines Graphic Packs, leer = keine
    char      patchPack[CEMUVR_NAME_MAX];
} CemuVR_ProfileInfo;

// ---------------------------------------------------------------------------
// Was das Profil je Auge zurueckgeben darf, und was der Kern damit tut
// ---------------------------------------------------------------------------

// Alle Felder sind ZUSAETZLICH zu dem, was der Kern ohnehin berechnet.
// Ein Profil, das nichts aendern will, gibt die Struktur unveraendert zurueck
// (memset auf 0 mit fovScale = 1.0) oder implementiert adjustEye gar nicht.
typedef struct CemuVR_EyeAdjust {
    uint32_t structVersion;        // == CEMUVR_PROFILE_ABI

    // Verschiebung des QUELLAUSSCHNITTS in ganzen Texeln.
    // Ganzzahlig, damit es eine reine Texelkopie bleibt: der Kern verschiebt
    // nur den kopierten Bereich, er tastet nichts neu ab und erfindet nichts.
    // Der Kern begrenzt den Betrag auf ein Viertel der Bildbreite bzw. -hoehe.
    int32_t  sourceOffsetX;
    int32_t  sourceOffsetY;

    // Zusaetzlicher Augenversatz in Metern, im Augenraum der Runtime.
    // Der Kern addiert ihn auf die Augenposition der Projektionsebene.
    CemuVR_Vec3 eyePositionOffset;

    // Faktor auf die vier Sichtfeldwinkel. 0 oder 1.0 = unveraendert.
    // Der Kern begrenzt ihn auf [0.25, 4.0].
    float    fovScale;
} CemuVR_EyeAdjust;

// ---------------------------------------------------------------------------
// Die Funktionen, die ein Profil bereitstellt
// ---------------------------------------------------------------------------

// Ergebnis einer Profilfunktion.
typedef enum CemuVR_Result {
    CEMUVR_OK             = 0,
    CEMUVR_SKIP           = 1,   // dieser Frame soll unveraendert bleiben
    CEMUVR_NOT_READY      = 2,   // Profil noch nicht bereit (Kamera nicht gefunden)
    CEMUVR_ERROR          = -1
} CemuVR_Result;

// 1. Beschreibung liefern. Wird einmal beim Laden gerufen.
typedef CemuVR_Result (*CemuVR_PFN_Describe)(CemuVR_ProfileInfo* out);

// 2. An einen laufenden Titel binden. Der Kern hat Titel-ID, Modulpruefsumme und
//    Gastspeicherbasis bereits geprueft. Hier loest das Profil seine Signaturen auf.
typedef CemuVR_Result (*CemuVR_PFN_Attach)(const CemuVR_FrameContext* ctx);

// 3. Je Gastframe: die Augenkamera in den Gastspeicher schreiben.
//    Das ist die einzige Stelle, an der ein Profil den Gast veraendert.
typedef CemuVR_Result (*CemuVR_PFN_ApplyCamera)(const CemuVR_FrameContext* ctx);

// 3b. Optional: Anpassungen, die der KERN im echten Bildweg anwendet.
//
//     Das ist der Gegenstueck zu applyCamera: applyCamera schreibt in den
//     Gastspeicher, adjustEye gibt dem Kern etwas zurueck, das er selbst
//     ausfuehrt. Ein Profil, das die Gastkamera (noch) nicht kennt, kann
//     darueber trotzdem eine belegbare, augenabhaengige Wirkung erzielen.
typedef CemuVR_Result (*CemuVR_PFN_AdjustEye)(const CemuVR_FrameContext* ctx,
                                              CemuVR_EyeAdjust* out);

// 4. Optional: Soll dieser Gastframe ueberhaupt fuer VR benutzt werden?
//    Rueckgabe CEMUVR_SKIP unterdrueckt die Stereoausgabe, etwa in Menues.
typedef CemuVR_Result (*CemuVR_PFN_ShouldRender)(const CemuVR_FrameContext* ctx);

// 5. Abloesen. Wird beim Beenden oder Titelwechsel gerufen.
typedef void (*CemuVR_PFN_Detach)(void);

// ---------------------------------------------------------------------------
// Raumfeste Flaeche -- fuer Bilder, deren Kamera das Profil nicht erreicht
// ---------------------------------------------------------------------------
//
// WOZU
//
// Der Kern spannt ein Gastbild ueber das Augenfrustum. Das ist richtig,
// solange das Spiel selbst mit diesem Frustum rendert. Fuer Bildzustaende, in
// denen ein Spiel keine erreichbare Kamera setzt -- Titelbilder, Ladebilder,
// Systemdialoge --, steht dasselbe Bild danach in beiden Augen an
// verschiedenen Winkelpositionen. Beim Quest 3 sind das 30 Grad; das kann
// kein Auge zusammenbringen.
//
// Profilseitig ist das nicht loesbar: CemuVR_EyeAdjust kann den Ausschnitt
// verschieben, aber das BESCHNEIDET das Bild -- die Teilkopie verliert je Auge
// den Betrag der Verschiebung -- und es macht das Bild nicht raumfest, denn
// ein Drehversatz fehlt der Struktur.
//
// Mit einem Flaechenauftrag reicht der Kern das Bild stattdessen als
// XrCompositionLayerQuad ein: eine Flaeche mit Pose und physischer Groesse im
// Referenzraum. Sie bleibt stehen, wenn der Kopf sich bewegt oder dreht, und
// sie traegt den VOLLSTAENDIGEN Bildinhalt.
//
// WAS SIE NICHT IST
//
// Kein Ersatz fuer die urspruengliche raeumliche Tiefe der abgebildeten
// Gegenstaende. Eine Flaeche im Raum zu betrachten und in eine Szene
// hineinzuschauen sind zwei verschiedene Dinge.
typedef struct CemuVR_SurfaceRequest {
    uint32_t    structVersion;     // == CEMUVR_PROFILE_ABI

    // 0 = normale Stereoausgabe (Standard), 1 = Flaeche.
    // Die Flaeche ERSETZT die Projektionsebene; sie kommt nicht zusaetzlich.
    // Sonst bliebe das nahe Doppelbild dahinter stehen.
    uint32_t    mode;

    // 0 = der Kern setzt den Anker beim Einschalten selbst, aus der aktuellen
    //     Kopflage und distanceMetres, und laesst ihn danach stehen.
    // 1 = anchor gilt und wird jedes Bild uebernommen.
    uint32_t    anchorMode;
    CemuVR_Pose anchor;

    float       distanceMetres;    // nur bei anchorMode 0
    float       widthMetres;       // physische Breite der Flaeche
    float       heightMetres;      // physische Hoehe
} CemuVR_SurfaceRequest;

// Optional. Wird je Gastframe gerufen. Ein Profil, das die Flaeche nicht
// braucht, implementiert sie nicht -- der Kern behandelt einen Nullzeiger wie
// mode 0.
typedef CemuVR_Result (*CemuVR_PFN_SurfaceRequest)(const CemuVR_FrameContext* ctx,
                                                   CemuVR_SurfaceRequest* out);

typedef struct CemuVR_ProfileApi {
    uint32_t                abiVersion;
    CemuVR_PFN_Describe     describe;
    CemuVR_PFN_Attach       attach;        // = profile_init
    CemuVR_PFN_ApplyCamera  applyCamera;   // = Frame-Rueckruf
    CemuVR_PFN_ShouldRender shouldRender;  // darf null sein
    CemuVR_PFN_Detach       detach;        // = profile_shutdown, darf null sein
    CemuVR_PFN_AdjustEye    adjustEye;     // darf null sein
    // Neu und optional. Der Kern nullt diese Struktur vor dem Aufruf von
    // CemuVR_GetProfileApi; ein aelteres Profil laesst das Feld deshalb auf
    // null stehen, und der Kern verhaelt sich dann wie bisher. Deshalb bleibt
    // die ABI-Nummer bei 2 -- es wird nichts umgedeutet, nur angehaengt.
    CemuVR_PFN_SurfaceRequest surfaceRequest;  // darf null sein
} CemuVR_ProfileApi;

// NAMENSZUORDNUNG zu der im Auftrag benutzten Sprechweise:
//   profile_init      = attach
//   Frame-Rueckruf    = applyCamera (und, falls vorhanden, adjustEye)
//   profile_shutdown  = detach
// Die Diagnose des Kerns protokolliert unter den Auftragsnamen:
//   profile.init, profile.frame, profile.shutdown

// Der einzige Export, den eine Profil-DLL haben muss.
// Rueckgabe 0 = Erfolg.
typedef int (*CemuVR_PFN_GetProfileApi)(CemuVR_ProfileApi* out);
#define CEMUVR_PROFILE_ENTRYPOINT "CemuVR_GetProfileApi"

#ifdef __cplusplus
} // extern "C"
#endif
