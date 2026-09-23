# Known issues

**Alpha 1.0** is intended for early testing. A full playthrough has not been
validated, and compatibility testing covers one Windows/Cemu/VDXR setup.

## Rendering and performance

- Geometry outside the original camera view may be missing, exposed or visibly
  incomplete. Some effects, particles, shadows and visibility transitions can look wrong.
- Cinematic framing has limited testing, particularly in diorama mode.
- Higher render rates do not interpolate animation between the game's 60 Hz
  updates. 90 and 144 FPS presets remain experimental.
- Death, respawn and scene transitions may still cause instability at 120 FPS.
  If a crash occurs, try the 60 FPS reference preset and report the location
  and steps that trigger it.

## First person

- The view inherits the game camera's tilt and automatic turns.
- The character's model remains visible around the viewpoint. Nearby geometry
  can clip against the game's near plane.
- HUD elements stay anchored in the room and can move out of view as you turn.
- Stick turning also affects movement on the world map. Pull the right stick
  straight down to restore the game's camera direction.
- Fixed cameras and cinematics may produce awkward framing.

## Compatibility

Only Cemu 2.6, the European base game v0 and Virtual Desktop/VDXR have been
validated. Other game revisions, emulator versions, runtimes and hardware
may behave differently. Motion-controller gameplay is not included.

## Reporting a problem

Include the mode, level, game version, Cemu version, GPU, OpenXR runtime,
FPS preset and steps to reproduce the issue. Screenshots or a short recording
can help explain camera and rendering problems. Remove personal paths or
account information before sharing logs. Do not attach game files or keys.
