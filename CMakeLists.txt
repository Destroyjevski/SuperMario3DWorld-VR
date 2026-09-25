cmake_minimum_required(VERSION 3.20)
project(SuperMario3DWorldVR LANGUAGES CXX)

find_package(Vulkan REQUIRED)
find_path(OPENXR_INCLUDE_DIR openxr/openxr.h REQUIRED)
find_library(OPENXR_LOADER_LIBRARY NAMES openxr_loader REQUIRED)

add_library(cemuvr_layer SHARED
    core/src/cemu_layer.cpp
    core/src/interop.cpp
    core/src/cemu_bridge.cpp
    core/src/profile_host.cpp
    core/src/xr_core.cpp
    core/src/xr_actions.cpp
    core/cemuvr_layer.def
)
target_compile_features(cemuvr_layer PRIVATE cxx_std_17)
target_compile_definitions(cemuvr_layer PRIVATE _CRT_SECURE_NO_WARNINGS)
target_include_directories(cemuvr_layer PRIVATE core/include ${OPENXR_INCLUDE_DIR} ${Vulkan_INCLUDE_DIRS})
target_link_libraries(cemuvr_layer PRIVATE ${OPENXR_LOADER_LIBRARY} d3d11 dxgi advapi32 ole32 shlwapi pathcch user32)
set_target_properties(cemuvr_layer PROPERTIES OUTPUT_NAME cemuvr_layer)
