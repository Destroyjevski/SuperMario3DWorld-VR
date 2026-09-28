# Alpha 1.4

## SteamVR compatibility

- Integrates Anakins' fix for a black or waiting screen on SteamVR runtimes
  that offer an sRGB swapchain instead of the requested UNORM format.
- Imports the HUD's shared texture using the format selected by OpenXR.
- Keeps the current start-up and runtime-recovery behavior, with resolution
  and colour-channel-order checks still in place.

A SteamVR/PSVR2 tester now gets an image, but reported darker, more saturated
colours compared with Quest 3. That visual difference is still under
investigation; this release does not claim to resolve it.

Camera modes, controls and game-version requirements are unchanged.

See [CREDITS.md](CREDITS.md) for the contribution and
[KNOWN-ISSUES.md](KNOWN-ISSUES.md) for remaining limitations.

---

# Alpha 1.3

An early alpha release. The changes below build on Alpha 1.2.

## Camera

- A third view, the close diorama: the diorama from half its distance, with
  the same direction, head tracking and scale. The mode switch now steps from
  the diorama to the close diorama, then to first person, then back; every
  step resets camera turning and recentres head position, as before. Like
  first person, the close diorama applies in levels; intro and world map keep
  the diorama.

## Lighting

- The known eye-dependent lighting mismatch is fixed. Since the first alpha a light could sit
  on the left wall in the left eye and on the right wall in the right eye,
  most visibly in small enclosed stages. The game's screen-space passes - the
  light pre-pass, glare, depth of field and indirect light - read the camera
  and the projection from the renderer's view data, which still held the
  game's own symmetric projection while each eye had been drawn with its own
  frustum. The VR graphic pack now hands those passes the eye's camera and
  projection as well, and puts the game's own back before the game's logic
  runs. Shadows are unchanged.

## Start-up

- The VR layer initialises OpenXR in two phases: the runtime, the headset and
  the view configuration are prepared at the first frame Cemu presents, and
  the session, the swapchains and the image transport follow as soon as the
  first complete stereo pair reports its size and format. Cemu rebuilding its
  own swapchain at start no longer tears the OpenXR session down, and a
  runtime that is not ready yet is retried instead of failing the start.

## Compatibility

Unchanged: Cemu 2.6 on Windows x64 with Vulkan and an OpenXR runtime, European
base game v0, title ID `0005000010145D00`, module checksum `D2308838`.

Read [KNOWN-ISSUES.md](KNOWN-ISSUES.md) before use.
