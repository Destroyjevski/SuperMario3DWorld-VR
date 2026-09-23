# Credits

## Project

**Destroyjevski** — Super Mario 3D World VR integration and release.

## BetterVR

Special thanks to **Crementif and the contributors to
[BetterVR / BotW-BetterVR](https://github.com/Crementif/BotW-BetterVR)**.
Their implementation and research were an essential foundation for this port.

BetterVR provided implementation references and, where applicable,
MIT-licensed groundwork for areas including:

- Rendering two eye views from one simulation state.
- GPU clear-color markers for eye identification and buffer-slot signaling.
- Reusing shadow maps and their associated state for the second eye.
- Shared engine camera and projection structures.
- Separating HUD capture and submitting it as an OpenXR layer.
- Cemu integration and interception of rendered images.

Mario-specific hook addresses and game integration were determined separately.
The Vulkan–D3D11 transport, pose protocol, pair validation and HUD placement
were implemented or extended for these ports. Some groundwork carries over
through the Captain Toad VR port. BetterVR's BotW-specific gameplay, weapon
and motion-control systems are not used.

BetterVR is MIT licensed: **Copyright (c) 2021 Crementif**.
The unchanged license is included in [licenses/BetterVR-MIT.txt](licenses/BetterVR-MIT.txt)
and is retained in the distributed release archives.
This project is independent; no endorsement by Crementif or BetterVR is claimed.

## Other components

- **Khronos OpenXR loader** — Apache 2.0; notice in
  [licenses/OpenXR-Apache-2.0.txt](licenses/OpenXR-Apache-2.0.txt).
- **JsonCpp** — MIT; notice in [licenses/JsonCpp-MIT.txt](licenses/JsonCpp-MIT.txt).
  It may be incorporated through the statically linked OpenXR loader.
- **Cemu / Exzap** — Mario's robust-buffer-access handling is based on Cemu's
  implementation.
- **Crementif and getdls** — the community resolution graphic pack used in
  the documented setup. That pack is not redistributed here.

See [THIRD-PARTY.txt](THIRD-PARTY.txt) for the dependency summary.
