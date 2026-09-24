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

## Package Alpha 1.1

```powershell
python tools/package.py --dll build/Release/cemuvr_layer.dll
```

The script creates installation and source ZIPs plus `SHA256SUMS.txt` in
`Releases/`. It reads the release name from `VERSION` and checks package
contents for private paths and unexpected file types before writing archives.

The installation ZIP includes the DLL. The source ZIP includes the C++ source,
ASM packs, launchers and notices. Build outputs and local Cemu settings are
excluded from Git.
