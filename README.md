# Super Mario 3D World VR

**Alpha 1.4** · Windows x64 · Cemu · OpenXR

Stereo rendering and six-degree-of-freedom head tracking for the Wii U
version of **Super Mario 3D World**. Play with a gamepad or VR controllers
in diorama, close diorama or first-person mode.

[Installation](INSTALL.md) · [Known issues](KNOWN-ISSUES.md) ·
[Build from source](BUILD.md) · [Credits](CREDITS.md)

## Choose a mode

| Mode | Selection | View |
| --- | --- | --- |
| **Diorama** | Default on start | View the level as a diorama. |
| **Close diorama** | Click the right stick (R3) once | The same diorama from half the distance. |
| **First person** | Click R3 again | View from the character, with free 360-degree stick turning. |

Run `Start-VR.cmd`. Click **R3** in a level to step through the three views
without restarting Cemu; a third click returns to the diorama. Each switch
also resets camera turning and recentres your headset position. Intro and
world map use the diorama view.

All modes include room-anchored menus and HUD, head tracking, and VR camera
framing for the opening cinematic.

## New in Alpha 1.4

- SteamVR compatibility fix by **Anakins** for runtimes that select an sRGB
  swapchain, including the matching HUD texture import.
- Converts eye and HUD colours when the runtime requires sRGB; keeps the
  existing UNORM transfer unchanged.
- Adds **USA v1** support alongside **European v0** in both graphic packs.
- First-person movement follows your horizontal head direction, with light
  smoothing. Works with both gamepads and VR controllers; no extra button.
- Improves visibility on the world maps: hides distant pipes and separate
  bonus-map planes, with their associated objects and effects.
- Hides the detached room beside World 2, including the pipe transition
  from World 1, and corrects visibility of the remote bonus room in the first level.
- Removes the distracting cyan screen flare in the first level.
- Presents the title confirmation and file-selection transition on the
  menu canvas instead of over the surrounding VR scene.

See [release notes](RELEASE_NOTES.md) and [known issues](KNOWN-ISSUES.md)
for test coverage and remaining limitations.

## New in Alpha 1.3

- **A third view between diorama and first person.** The close diorama shows
  the level from half the diorama's distance, with the same direction, head
  tracking and scale. The mode switch now steps from the diorama to the close
  diorama, then to first person, then back.
- **The known eye-dependent lighting mismatch is fixed.** A light no longer sits on the left
  wall in one eye and on the right wall in the other; the screen-space passes
  now use the eye's camera and projection.
- **Sturdier start:** OpenXR is prepared at the first frame and attached once
  the stereo pair is known, so Cemu's swapchain rebuild at start and a runtime
  that is not ready yet no longer break the session.

Alpha 1.2 brought VR controller input with no button mapping in Cemu, the
D-pad gesture, the selectable mode-switch button and the first-person camera
improvements; they are all still here.

See [release notes](RELEASE_NOTES.md) for details and [installation](INSTALL.md)
for controller bindings. Shadows and depth effects still have limitations;
see [known issues](KNOWN-ISSUES.md).

## Get started

1. Download the **Alpha 1.4 installation ZIP** from [Releases](../../releases).
2. Place its `Mario3DWorld-VR` folder beside `Cemu.exe`.
3. Close Cemu and run `Start-VR.cmd`.
4. Open Super Mario 3D World in Cemu and play with your gamepad or VR controllers.

Use the installation ZIP to play. GitHub's **Code → Download ZIP** contains
source code and requires building the VR layer first.

See [INSTALL.md](INSTALL.md) for headset setup, graphics settings and FPS options.

## Requirements

| Component | Supported / tested configuration |
| --- | --- |
| System | Windows x64 |
| Emulator | Cemu **2.6**, Vulkan renderer |
| Game | European Wii U **v0** or USA **v1** |
| European identifiers | Title ID `0005000010145D00` · module checksum `D2308838` |
| USA identifiers | Title ID `0005000010145C00` · module checksum `BBAF1908` |
| VR | An active OpenXR headset runtime |
| Input | A configured gamepad or supported OpenXR VR controllers; emulated controller 1 must be a Wii U GamePad |

Headset testing used an RTX 4080 and Virtual Desktop/VDXR at 120 Hz.
The USA module was checked against the European module; broader headset and
hardware testing is still limited. Other game revisions are not yet supported.
Cemu and the game are not included.

## Controls

### Gamepad

Use the game's standard controls with your existing Cemu gamepad mapping.
**R3 (right stick click) is the only custom button assignment by default:**
it cycles **Diorama → Close diorama → First Person → Diorama** and resets
camera turning and your headset centre. Make sure R3 is mapped in Cemu.

The VR-controller bindings and D-pad gesture below do not apply to the
gamepad. Its D-pad keeps working normally. An alternative mode-switch button
can be selected in the VR graphic pack settings.

### VR controllers (motion controllers)

VR controllers use their own bindings and need no button mapping in Cemu.
Set emulated controller 1 to **Wii U GamePad**.

- **Left stick:** move. **Right stick:** turn the camera.
- **Right stick click:** cycle camera modes and recenter.
- **D-pad gesture:** hold the left controller near your head, then use the
  right stick for D-pad directions. Move the left controller away to resume
  camera turning. A short vibration confirms the gesture.

See the [VR controller button table](INSTALL.md#vr-controllers-motion-controllers)
for the full Quest/Touch layout. These bindings are separate from the gamepad's.

### Camera behaviour with either input device

Head movement controls your viewpoint in VR. In first person, the right stick
turns freely through 360 degrees. The left stick moves relative to your
horizontal head direction combined with that stick turning, with light
smoothing and unchanged movement speed. Looking up/down or tilting your head
does not steer movement. The HUD stays in the room as you turn.

## Frame rate

The default preset targets **120 rendered stereo pairs per second** while
keeping gameplay updates near **60 Hz**. It does not interpolate character
motion between gameplay updates. Actual frame rate depends on your system.

A 60 FPS reference preset is available; 90 and 144 FPS are experimental.

## Alpha status

This is an early, incomplete release. A full playthrough has not been
validated. Camera behavior, visibility, effects and scene transitions can
still have problems, especially in first person. See [KNOWN-ISSUES.md](KNOWN-ISSUES.md)
for limitations and what to include in a bug report.

## Credits and license

Created by **Destroyjevski**.

Huge thanks to **Crementif and the BetterVR contributors** for their excellent
work on Cemu VR. Their research and implementation provided an important
technical foundation for this project. See [CREDITS.md](CREDITS.md) for
acknowledgements and implementation background.

Thanks to **JShodanVR** for putting the early builds through their paces and
sharing useful feedback and footage.

Original project code is licensed under [MIT](LICENSE). Third-party licenses
are included in [licenses/](licenses/); see [THIRD-PARTY.txt](THIRD-PARTY.txt)
for a dependency and license summary.

## Unofficial project

This project is not affiliated with or endorsed by Nintendo, Cemu or BetterVR.
Game names, characters and assets belong to their respective rights holders.
Users must provide their own legally obtained game. The package contains no
game dump, keys, firmware, saves or extracted game assets.
