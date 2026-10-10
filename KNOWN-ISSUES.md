# Known issues

**Alpha 1.6** is intended for early testing. A full playthrough has not
been validated, and compatibility testing covers one Windows/Cemu/VDXR setup.

## Shadows

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
- A crash on death and respawn at 120 FPS was reproduced and fixed. Not every
  death, respawn and scene-transition situation has been validated since; if a
  crash occurs, report the location and steps that trigger it.

## VR controllers (motion controllers)

These limitations concern VR-controller input. A physical gamepad keeps the
game's standard button assignments, with R3 used for camera-mode switching
by default.

- Touch with VR controllers was tested on the touch platforms in World 2-2.
  Other GamePad touch interactions have not been tested with VR controllers.
- Emulated controller 1 has to be a Wii U GamePad. With a Pro Controller or a
  Wii Remote profile the game reads its input through a different path, which
  the VR controllers do not reach.
- On Oculus Touch controllers the menu button exists only on the left
  controller, so Plus comes from there.

## Blowing

- Blowing into the microphone is recognised deliberately strictly, so that
  talking does not blow in the game: blow steadily and directly onto the
  microphone. If you find it too strict, please report it, or use the
  right-controller gesture.
- Speech or noise filtering in the headset or streaming software can weaken
  blowing.
- Microphone blowing was tested with a Quest 3 through Virtual Desktop only.

## First person

- Head-directed lighting in Captain Toad levels, touch and blowing are
  currently enabled for the European v0 game only. Other supported revisions
  keep their native lighting, touch and microphone input.
- HUD elements stay anchored in the room and can move out of view as you turn.
- Intro and world map use the diorama view. A selected first-person mode
  resumes in supported gameplay scenes.
- Fixed cameras and cinematics may produce awkward framing.

## Compatibility

The primary tested setup uses Cemu 2.6, the European base game v0 and
Virtual Desktop/VDXR. USA v1 is also supported by both graphic packs; its
module code and data were checked against the European version. Broader
testing across runtimes and headsets remains limited. Other game revisions,
emulator versions and hardware may behave differently.

## Reporting a problem

Include the mode, level, game version, Cemu version, GPU, OpenXR runtime, FPS
preset and steps to reproduce the issue. Screenshots or a short recording can
help explain camera and rendering problems. Remove personal paths or account
information before sharing logs. Do not attach game files or keys.
