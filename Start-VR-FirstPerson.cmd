@echo off
rem Super Mario 3D World VR - Alpha 1.0 - firstperson
rem Close Cemu before starting. See INSTALL.md for setup and KNOWN-ISSUES.md for limits.
rem Set the active OpenXR headset to 120 Hz for the default FPS preset.
set "VR_MODE=firstperson"
set "CEMUVR_MARIO_WORLD_SIZE=20"
rem Keep the packs enabled after quitting (0 = disable them).
set "VR_KEEP_PACKS=0"
rem Allow other implicit Vulkan layers (0 = disable them for this session).
set "VR_KEEP_OTHER_LAYERS=0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-VR.ps1"
if errorlevel 1 pause
