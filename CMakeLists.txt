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
    core/src/mic_blow_capture.cpp
    core/cemuvr_layer.def
)
target_compile_features(cemuvr_layer PRIVATE cxx_std_17)
target_compile_definitions(cemuvr_layer PRIVATE _CRT_SECURE_NO_WARNINGS)
target_include_directories(cemuvr_layer PRIVATE core/include ${OPENXR_INCLUDE_DIR} ${Vulkan_INCLUDE_DIRS})
target_link_libraries(cemuvr_layer PRIVATE ${OPENXR_LOADER_LIBRARY} d3d11 dxgi advapi32 ole32 shlwapi pathcch user32)
set_target_properties(cemuvr_layer PROPERTIES OUTPUT_NAME cemuvr_layer)

# Offline regression tests; no Cemu, runtime or headset is launched.
option(CEMUVR_BUILD_TESTS "Build pose transport regression tests" OFF)
if(CEMUVR_BUILD_TESTS)
    enable_testing()
    add_executable(mario_touch_packet_test core/tests/mario_touch_packet_test.cpp)
    target_compile_features(mario_touch_packet_test PRIVATE cxx_std_17)
    target_include_directories(mario_touch_packet_test PRIVATE core/include)
    add_test(NAME mario_touch_packet COMMAND mario_touch_packet_test)
    add_executable(head_blow_gesture_test core/tests/head_blow_gesture_test.cpp)
    target_compile_features(head_blow_gesture_test PRIVATE cxx_std_17)
    target_include_directories(head_blow_gesture_test PRIVATE core/include)
    add_test(NAME head_blow_gesture COMMAND head_blow_gesture_test)
    add_executable(mic_blow_detector_test core/tests/mic_blow_detector_test.cpp)
    target_compile_features(mic_blow_detector_test PRIVATE cxx_std_17)
    target_include_directories(mic_blow_detector_test PRIVATE core/include)
    add_test(NAME mic_blow_detector COMMAND mic_blow_detector_test)
    add_executable(reference_pose_history_test core/tests/reference_pose_history_test.cpp)
    target_compile_features(reference_pose_history_test PRIVATE cxx_std_17)
    target_compile_definitions(reference_pose_history_test PRIVATE _CRT_SECURE_NO_WARNINGS)
    target_include_directories(reference_pose_history_test PRIVATE core/include ${Vulkan_INCLUDE_DIRS})
    add_test(NAME reference_pose_history COMMAND reference_pose_history_test)
endif()
