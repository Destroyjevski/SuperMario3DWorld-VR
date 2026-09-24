# Installation

## Before you start

- Set up Cemu 2.6 and confirm that your European Super Mario 3D World base
  game v0 runs normally with a gamepad.
- Select an OpenXR runtime for your headset. The tested runtime is Virtual
  Desktop/VDXR.
- For the default 120 FPS preset, use a 120 Hz headset refresh rate.
- Close Cemu before starting a VR session.

## Install Alpha 1.1

1. Extract `SuperMario3DWorld-VR-Alpha-1.1-install.zip`.
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

## Switching modes

Click **R3** (the right stick) in a level to switch between diorama and
first person without restarting Cemu. The same click resets camera turning
and recentres head position. First person supports continuous 360-degree
turning with the right stick. Intro and world map use diorama view.

Map the right-stick click in Cemu's gamepad settings if it is not assigned.
`Start-VR.cmd` is the only launcher. It disables the old separate
first-person pack when upgrading from Alpha 1.0.

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
