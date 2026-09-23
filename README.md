# Super Mario 3D World VR

**Alpha 1.0** · Windows x64 · Cemu · OpenXR

Stereo rendering and six-degree-of-freedom head tracking for the Wii U
version of **Super Mario 3D World**. Play with a gamepad in either diorama
or first-person mode.

[Installation](INSTALL.md) · [Known issues](KNOWN-ISSUES.md) ·
[Build from source](BUILD.md) · [Credits](CREDITS.md)

## Choose a mode

| Mode | Launcher | View |
| --- | --- | --- |
| **Diorama** | `Start-VR.cmd` | View the level as a diorama. |
| **First person** | `Start-VR-FirstPerson.cmd` | View from the character, with free stick turning. |

Both modes include room-anchored menus and HUD, head tracking, and VR camera
framing for the opening cinematic.

## Get started

1. Download the **Alpha 1.0 installation ZIP** from [Releases](../../releases).
2. Place its `Mario3DWorld-VR` folder beside `Cemu.exe`.
3. Close Cemu and run the launcher for your preferred mode.
4. Open Super Mario 3D World in Cemu and play with your gamepad.

Use the installation ZIP to play. GitHub's **Code → Download ZIP** contains
source code and requires building the VR layer first.

See [INSTALL.md](INSTALL.md) for headset setup, graphics settings and FPS options.

## Requirements

| Component | Supported / tested configuration |
| --- | --- |
| System | Windows x64 |
| Emulator | Cemu **2.6**, Vulkan renderer |
| Game | European Wii U base game **v0**, without an update |
| Game identifiers | Title ID `0005000010145D00` · module checksum `D2308838` |
| VR | An active OpenXR headset runtime |
| Input | A gamepad configured in Cemu |

Headset testing used an RTX 4080 and Virtual Desktop/VDXR at 120 Hz.
Other hardware, runtimes and game versions have not been validated.
Cemu and the game are not included.

## Controls

| Input | Action |
| --- | --- |
| Head movement | Look around and move your viewpoint in VR |
| Gamepad | Normal game controls |
| Right stick left/right, first person | Turn the view |
| Right stick straight down, first person | Reset stick turning to the game's camera direction |
| Left stick, first person | Move relative to the stick-turned view |

The HUD stays in the room as you turn. Head tracking remains separate from
stick turning.

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

Original project code is licensed under [MIT](LICENSE). Third-party licenses
are included in [licenses/](licenses/); see [THIRD-PARTY.txt](THIRD-PARTY.txt)
for a dependency and license summary.

## Unofficial project

This project is not affiliated with or endorsed by Nintendo, Cemu or BetterVR.
Game names, characters and assets belong to their respective rights holders.
Users must provide their own legally obtained game. The package contains no
game dump, keys, firmware, saves or extracted game assets.
