# Installation

## Before you start

- Set up Cemu 2.6 and confirm that your European Super Mario 3D World base
  game v0 runs normally with a gamepad.
- Select an OpenXR runtime for your headset. The tested runtime is Virtual
  Desktop/VDXR.
- For the default 120 FPS preset, use a 120 Hz headset refresh rate.
- Close Cemu before starting a VR session.

## Install Alpha 1.3

1. Extract `SuperMario3DWorld-VR-Alpha-1.3-install.zip`.
2. Copy its **`Mario3DWorld-VR`** folder into your Cemu folder, beside `Cemu.exe`.
3. Open that folder and run **`Start-VR.cmd`**. The game starts in diorama mode.
4. Launch the game from Cemu's game list.
5. Keep the launcher window open. Quit Cemu normally to end the session.

If the launcher cannot find Cemu, it asks you to select `Cemu.exe` once.
The installation ZIP includes the VR layer. The source ZIP requires a build;
see [BUILD.md](BUILD.md).

## Graphics and frame rate

The launcher enables Vulkan, the chosen VR mode and the FPS pack. It uses your
existing Cemu configuration and saves; it does not create a separate game profile.

For a sharper image, enable Cemu's community resolution graphic pack and
select **3840×2160**, if your GPU can sustain it. That pack is not bundled.

The initial FPS preset is **120 FPS (60 Hz gameplay)**. To change it, select
a different preset in Cemu's graphic-pack settings during a session. Quit
Cemu normally; the launcher remembers the selection for the next start.
The available presets are 60, 90, 120 and 144 FPS. Start with 60 if 120 is unstable.

## Controls

### Gamepad

Keep your normal Cemu gamepad mapping and use the game's standard controls.
**Only R3 (right stick click) has a custom button assignment by default:**
it cycles Diorama, Close diorama and First Person, then returns to Diorama.
Each switch also resets camera turning and recentres your headset position.
Make sure your physical right stick click is assigned to the emulated right
stick click in Cemu.

The gamepad's other button assignments, including the D-pad, stay unchanged.
The VR-controller bindings and gesture below apply only to VR controllers.

### VR controllers (motion controllers)

VR controllers use the bindings below instead of Cemu's physical gamepad
mapping. **No button mapping is needed in Cemu for VR controllers.** Set
emulated controller 1 to **Wii U GamePad**; other emulated controller types
do not receive this input.

The button names in this table are for **Quest / Oculus Touch controllers**.
The Wii U column names the input sent to the game, not a button you need to
assign in Cemu. Other controller layouts may differ and have not been validated.

| VR controller input | Wii U input / action |
| --- | --- |
| Left stick | Left stick: move |
| Right stick | Right stick: camera turning |
| Left X | X: run / action |
| Left Y | Y: game action |
| Right A | A: jump / confirm |
| Right B | X: run / action |
| Left trigger | ZL |
| Right trigger | B: jump / back in menus |
| Left grip | L |
| Right grip | R |
| Left menu button | Plus: pause menu |
| Left stick click | Minus |
| Right stick click | Cycle camera modes and recenter |

**D-pad gesture (VR controllers only):** hold the left controller near your
head and use the right stick for D-pad directions. While the gesture is
active, that stick stops turning the camera. A short vibration in the left
controller confirms activation. Move it away from your head to return to
camera turning.

A configured gamepad can still be used alongside VR controllers. A resting
VR stick does not override the gamepad stick.

### Camera behaviour with either input device

Head tracking works with either control option. In first person, right-stick
left/right turns through 360 degrees, and movement follows the stick-turned
view. These camera behaviours do not change the gamepad's button assignments.

## Switching camera modes

Click the right controller's stick, or **R3** on the pad: the first click
moves to the close diorama, the same view from half the distance, the second
to first person, the third back to the diorama. Every click resets camera
turning and recentres head position. Intro and world map use the diorama
view.

Optionally, the gamepad mode-switch button can be changed in the VR graphic pack:
right stick click (the default), left stick click, either of the two, ZL and
ZR together, L and R together, or Minus. Pick another one if the stick click
is not assigned in your Cemu gamepad settings.

`Start-VR.cmd` is the only launcher.

## What the launcher changes

For the session, it copies the included graphic packs into Cemu's data folder,
enables the selected packs, switches to Vulkan and loads the VR layer for the
Cemu process. Verbose Cemu debug logging is disabled for the session.
Existing unrelated graphic packs remain enabled.

Settings backups are kept in `Mario3DWorld-VR-backups` inside Cemu's data folder.
After a normal exit, the launcher disables its packs and restores the previous
graphics API and debug-logging settings. The copied pack files remain installed.

If Cemu or the launcher is forcibly closed, check the enabled graphic packs
before returning to ordinary 2D play. No system-wide Vulkan layer is installed.
