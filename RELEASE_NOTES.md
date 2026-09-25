# Alpha 1.2

An early alpha release. The changes below build on Alpha 1.1.

## VR controllers

- The VR controllers act as the Wii U GamePad. The layer publishes both
  controllers, and the game profile writes them into the pad state before the
  game reads it. Cemu's input configuration is not involved at any point.
- Buttons:
  - left hand: X to X, Y to Y, trigger to ZL, grip to L, menu to Plus,
    stick click to Minus
  - right hand: A to A, B to X (run), trigger to B, grip to R
  - left stick moves, right stick looks
- D-pad: hold the left controller close to your head. While it is there the
  right stick acts as the D-pad and stops turning the view. A short pulse in
  that controller confirms the gesture has engaged.
- Pad and controllers work at the same time, button by button. A controller
  stick at rest leaves the pad's own value alone.
- B on the right hand is the run button rather than a second jump, so that
  running does not need the hand that is already pushing the stick.

## Switching between diorama and first person

- The button is selectable in Cemu's settings for the graphic pack: right
  stick click (default), left stick click, either of the two, ZL and ZR
  together, L and R together, or Minus.
- The right controller's stick click switches as well.

## View

- First person keeps the horizon level. The view no longer inherits the game
  camera's tilt, so walking up a staircase no longer tips it forward.
- The extra visibility test now uses the same camera and the same prepared
  pose as the picture. Objects no longer appear only after a mode switch.
- The near clip plane in first person moved from about 67 to about 7
  centimetres. Standing against a wall no longer cuts a strip out of it.
- The player model is hidden in first person.

## Image

- The game's depth of field is off.
- Its flare filter is off - the coloured smears that lay over the whole
  picture.
- Its god rays are off.

These effects are disabled to reduce blur and visual artifacts in VR.

## What the controllers need from Cemu

Nothing has to be mapped. The controller state comes from OpenXR through the
VR layer and is written into the pad the game reads, so no button and no stick
needs an assignment in Cemu's input settings.

One thing does matter: emulated controller 1 has to be a **Wii U GamePad**.
The game asks for a GamePad and for the other controller types through
different paths, and only the GamePad path carries the controllers.

## Compatibility

Unchanged: Cemu 2.6 on Windows x64 with Vulkan and an OpenXR runtime, European
base game v0, title ID `0005000010145D00`, module checksum `D2308838`.

Read [KNOWN-ISSUES.md](KNOWN-ISSUES.md) before use.
