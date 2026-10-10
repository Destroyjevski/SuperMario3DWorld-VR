# Build from source

## Requirements

- Windows x64 and Visual Studio 2022 with C++ tools
- CMake 3.20 or later
- Vulkan SDK
- Khronos OpenXR SDK headers and an x64 static OpenXR loader library,
  built with the dynamic MSVC runtime
- Python 3.9 or later for packaging

## Compile the VR layer

```powershell
cmake -S . -B build -A x64 `
  -DOPENXR_INCLUDE_DIR="C:/path/to/OpenXR/include" `
  -DOPENXR_LOADER_LIBRARY="C:/path/to/openxr_loader.lib"
cmake --build build --config Release
```

The include directory must provide `openxr/openxr.h` and
`openxr/openxr_platform.h`. The layer links Windows D3D11/DXGI system
libraries and uses the dynamic MSVC runtime. The Microsoft Visual C++ x64
Redistributable may be needed on the machine running the mod.

The files under `graphicPacks/` are assembled by Cemu when it starts the game.
No game executable is required to compile the C++ layer.

## Package Alpha 1.6

```powershell
python tools/package.py --dll build/Release/cemuvr_layer.dll
```

The script creates installation and source ZIPs plus `SHA256SUMS.txt` in
`Releases/`. It reads the release name from `VERSION` and checks package
contents for private paths and unexpected file types before writing archives.

The installation ZIP includes the DLL. The source ZIP includes the C++ source,
ASM packs, launchers and notices. Build outputs and local Cemu settings are
excluded from Git.

## Regression tests

Configure with `-DCEMUVR_BUILD_TESTS=ON`, build Release, then run:

```powershell
ctest --test-dir build -C Release --output-on-failure
```

These offline tests exercise the production history and transport-slot code,
including token wrap, stale markers, the mailbox seqlock rollover and 24 simulated
hours each at 60, 90, 120 and 144 Hz. Further tests cover the touch packet, the
blow gesture and the microphone blow detector, which runs on synthetic audio
only. They do not launch Cemu or a headset runtime and do not use a microphone.

`python tools/test_blow_gesture.py` and `python tools/test_mario_touch.py`
execute the guest code of the graphic pack against synthetic memory.

Normal sessions wrap pose tokens automatically. Each wrap emits one
`reference.token wrap=1` record, even with periodic diagnostics disabled.
For explicitly bounded FakeHMD/diagnostic runs only,
`CEMUVR_REFERENCE_STRICT_TOKEN_LIMIT=1` restores the stop before token reuse.
Leave this variable unset for normal play and long-session testing.
