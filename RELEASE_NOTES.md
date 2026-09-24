# Alpha 1.1

## Added

- Switch between Diorama and First Person in a level with R3 (right-stick click),
  without restarting Cemu.
- Each switch resets camera turning and recentres headset position.
- Continuous 360-degree right-stick turning in First Person; R3 handles reset.

## Launcher

- One launcher, `Start-VR.cmd`, starts in Diorama; R3 switches modes in game.
- Verbose Cemu debug logging is disabled for the session and restored on exit.

Compatibility and existing alpha limitations remain unchanged.

---

# Alpha 1.0

Initial alpha release of Super Mario 3D World VR for Cemu.

## Included

- Stereoscopic rendering and 6DOF head tracking through OpenXR.
- Diorama mode.
- Experimental first-person mode, with free stick turning
  and movement relative to the stick-turned view.
- VR camera framing for the opening cinematic in both modes.
- Room-anchored HUD and menus.
- FPS presets for 60, 90, 120 and 144 FPS, with gameplay updates near 60 Hz.
- Windows session launchers, source code, build instructions and license notices.

## Compatibility

Cemu 2.6 on Windows x64 with Vulkan and an OpenXR runtime. Targets the European
Wii U base game v0: title ID `0005000010145D00`, module checksum `D2308838`.

## Limitations

The mod remains incomplete. Read [KNOWN-ISSUES.md](KNOWN-ISSUES.md) before use.
