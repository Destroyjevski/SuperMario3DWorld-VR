# Known issues

**Alpha 1.2** is intended for early testing. A full playthrough has not
been validated, and compatibility testing covers one Windows/Cemu/VDXR setup.

## Lighting and shadows

- Lighting can differ between the eyes, most visible in small enclosed stages.
- Shadows can be misplaced or perspectivally wrong.

## Rendering and performance

- Geometry outside the original camera view may be missing, exposed or visibly
  incomplete. Some effects, particles and visibility transitions can look
  wrong.
- The closer near clip plane in first person is a compromise. The game's
  depth-reading passes work from the original plane, so their depth is
  slightly off.
- Cinematic framing has limited testing, particularly in diorama mode.
- Higher render rates do not interpolate animation between the game's 60 Hz
  updates. 90 and 144 FPS presets remain experimental.
- Death, respawn and scene transitions may still cause instability at 120 FPS.
  If a crash occurs, try the 60 FPS reference preset and report the location
  and steps that trigger it.

## Controls

- The GamePad's touchscreen and its microphone have no equivalent on a VR
  controller and cannot be reached from one.
- Emulated controller 1 has to be a Wii U GamePad. With a Pro Controller or a
  Wii Remote profile the game reads its input through a different path, which
  the VR controllers do not reach.
- On Oculus Touch controllers the menu button exists only on the left
  controller, so Plus comes from there.

## First person

- HUD elements stay anchored in the room and can move out of view as you turn.
- Intro and world map use the diorama view. A selected first-person mode
  resumes in supported gameplay scenes.
- Fixed cameras and cinematics may produce awkward framing.

## Compatibility

Only Cemu 2.6, the European base game v0 and Virtual Desktop/VDXR have been
validated. Other game revisions, emulator versions, runtimes and hardware may
behave differently.

## Reporting a problem

Include the mode, level, game version, Cemu version, GPU, OpenXR runtime, FPS
preset and steps to reproduce the issue. Screenshots or a short recording can
help explain camera and rendering problems. Remove personal paths or account
information before sharing logs. Do not attach game files or keys.
