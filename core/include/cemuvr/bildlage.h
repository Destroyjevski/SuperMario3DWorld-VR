// Der Helligkeitsschwerpunkt eines Bildes -- die reine Rechnung, ohne
// Direct3D, ohne OpenXR, ohne Zustand.
//
// WOZU SIE HIER STEHT UND NICHT IN xr_core.cpp
//
// Weil sie sonst nur im laufenden Kern zu pruefen waere, also nur mit Cemu
// und einer Brille. Als eigene Kopfdatei laesst sie sich mit kontrollierten
// Testbildern fuettern: ein bekannter Fleck an einer bekannten Stelle muss
// einen bekannten Schwerpunkt ergeben, und eine bekannte Verschiebung muss
// ihn um den richtigen Betrag in die richtige Richtung bewegen.
//
// Der Pruefer im Spielprojekt bindet GENAU DIESE Datei ein. Damit ist der
// Bildlesepfad selbst geprueft und nicht nur ein vorberechneter Zahlenwert.
#pragma once

#include <stdint.h>

namespace cemuvr {

// Jeder <schritt>-te Bildpunkt in beiden Richtungen. Bei 2496x2688 und
// Schritt 8 sind das rund hunderttausend Proben -- genug fuer einen
// stabilen Schwerpunkt und wenig genug, um nicht selbst die Bremse zu sein.
constexpr uint32_t kBildlageSchritt = 8;

// base   Zeiger auf die erste Zeile, vier Byte je Bildpunkt
// pitch  Abstand zweier Zeilen in Byte (nicht Breite mal vier!)
//
// sx, sy liegen zwischen -1 und +1: -1 ist der linke beziehungsweise obere
// Rand. lum ist die mittlere Helligkeit zwischen 0 und 1.
//
// Rueckgabe false heisst: kein Schwerpunkt bestimmbar. Ein schwarzes Bild
// hat keinen, und das muss unterscheidbar bleiben von  Schwerpunkt in der
// Mitte .
inline bool bildlageAusPuffer(const uint8_t* base, uint32_t w, uint32_t h,
                              uint32_t pitch, uint32_t schritt,
                              double* sxOut, double* syOut, double* lumOut) {
    if (sxOut) *sxOut = 0.0;
    if (syOut) *syOut = 0.0;
    if (lumOut) *lumOut = 0.0;
    if (!base || w < 2 || h < 2 || pitch < w * 4u || !schritt) return false;

    double summe = 0.0, sx = 0.0, sy = 0.0;
    uint32_t n = 0;
    for (uint32_t y = 0; y < h; y += schritt) {
        const uint8_t* row = base + (size_t)y * (size_t)pitch;
        const double yn = (double)y / (double)(h - 1u) * 2.0 - 1.0;
        for (uint32_t x = 0; x < w; x += schritt) {
            const uint8_t* px = row + (size_t)x * 4u;
            // Grobe Helligkeit. Die Kanalreihenfolge ist gleichgueltig: an
            // der RICHTUNG eines Schwerpunkts aendert sie nichts, und nur
            // die Richtung wird ausgewertet.
            const double l = (double)px[0] + 2.0 * (double)px[1] + (double)px[2];
            const double xn = (double)x / (double)(w - 1u) * 2.0 - 1.0;
            summe += l;
            sx += xn * l;
            sy += yn * l;
            ++n;
        }
    }
    if (summe <= 0.0 || !n) return false;
    if (sxOut) *sxOut = sx / summe;
    if (syOut) *syOut = sy / summe;
    if (lumOut) *lumOut = summe / (double)n / (4.0 * 255.0);
    return true;
}

} // namespace cemuvr
