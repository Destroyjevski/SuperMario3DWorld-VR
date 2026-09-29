# Alpha 1.4

## OpenXR compatibility and colours

- Integrates Anakins' swapchain-format and HUD texture-import fix for runtimes
  that offer an sRGB swapchain instead of the requested UNORM format.
- Corrects eye and HUD colour transfer when the runtime requires sRGB,
  addressing the darker, oversaturated image. The existing UNORM path is preserved.
- Retains the current OpenXR start-up and recovery behaviour.

## USA support

- Both the VR and FPS graphic packs now support USA v1 as well as European v0.
- Supported modules: European `D2308838` and USA `BBAF1908`. The code, data and
  relocation layouts were compared before enabling the USA module.

## First-person movement

- Left-stick movement follows your horizontal head direction combined with
  right-stick turning. Light smoothing softens small heading changes without
  changing movement speed. Looking up/down and head tilt do not steer movement.
- Enabled automatically in first-person gameplay with a gamepad or VR
  controllers. Diorama, world-map and menu movement retain their existing behaviour.

## Visibility and transitions

- Hides distant pipes and route details that appeared above the World 1 map.
- Separates the bonus-world map planes and filters associated foreign models
  and particle effects while retaining neighbouring areas on the current plane.
- Hides the detached room beside World 2 and during pipe travel from World 1;
  retains it when entering its own area.
- Corrects visibility of the remote bonus room in the first level, preventing
  it from being brought into view solely by the expanded VR visibility test.
- Removes the distracting cyan screen flare in the first level.
- Moves title confirmation and file-selection transitions onto the complete
  menu canvas so the iris effect is presented with its scene.

All three camera modes, VR-controller bindings, the D-pad gesture, selectable
mode-switch button, stereo-lighting corrections and FPS options are retained.

See [CREDITS.md](CREDITS.md) for contributions and
[KNOWN-ISSUES.md](KNOWN-ISSUES.md) for current limitations.

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
