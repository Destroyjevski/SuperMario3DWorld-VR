[Mario3DWorld_VR_FirstPerson_EU_v0]
moduleMatches = 0xD2308838
.origin = codecave
; Stereo render flow: two drawings from one calculated simulation state.
rrFlowHeader:
.int 0x4354464C
.int 1
rrEnabled:
.int 1
rrExtraDraws:
.int 0
rrSkipped:
.int 0
rrMarkerMagic:
.int 0x43544D31
rrMarkerAck:
.int 0
rrEye:
.int 0
rrSlot:
.int 0
rrCopyCalls:
.int 0
rrCopyBuffer:
.int 0
rrCopyTarget:
.int 0
rrEmitCount:
.int 0
rrValueTV:
.int 0x3D000000
rrValueDRC:
.int 0x3E000000
rrValueA:
.int 0x3DFCD6EA
rrValueB:
.int 0x3F7CD6EA
rrValueZero:
.int 0
rrValueOne:
.int 0x3F800000
0x024DB32C = rrAfterSecondDraw:
0x024DB93C = rrPresent:
0x024DB728 = rrDraw:
0x024DBA84 = rrRecord:
rrSecondDraw:
mflr r0
stwu r1, -0x20(r1)
stw r0, 0x24(r1)
lis r12, rrEnabled@ha
addi r12, r12, rrEnabled@l
lwz r11, 0(r12)
cmpwi r11, 1
bne rrSkip
lwz r11, 0x74(r29)
andi. r11, r11, 1
bne rrSkip
; Display-list preparation has to exist before an additional draw is possible.
lbz r11, 0x380(r29)
cmpwi r11, 0
beq rrSkip
lwz r11, 0x388(r29)
cmpwi r11, 0
blt rrSkip
; The original draw consumed the previous prepared list. Finish/present it.
mr r3, r29
bl import.gx2.GX2DrawDone
; Draw the just-prepared list; procDraw flips the list-buffer index itself.
mr r3, r29
bl rrDraw
; Conservative GPU barrier between eye renders.
bl import.gx2.GX2DrawDone
; Prepare the other list from the same calculated state, without another calc.
lis r12, rrEye@ha
addi r12, r12, rrEye@l
li r11, 1
stw r11, 0(r12)
lis r12, rrSecondRecord@ha
addi r12, r12, rrSecondRecord@l
li r11, 1
stw r11, 0(r12)
mr r3, r29
bl rrRecord
lis r12, rrSecondRecord@ha
addi r12, r12, rrSecondRecord@l
li r11, 0
stw r11, 0(r12)
lis r12, rrExtraDraws@ha
addi r12, r12, rrExtraDraws@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
b rrFinish
rrSkip:
lis r12, rrSkipped@ha
addi r12, r12, rrSkipped@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
rrFinish:
lwz r0, 0x24(r1)
mtlr r0
addi r1, r1, 0x20
lwz r5, 0x24(r29)
b rrAfterSecondDraw
0x024DB328 = ba rrSecondDraw

0x024DB304 = rrAfterBeforeCalc:
rrBeforeCalc:
lis r12, mrCullCount@ha
li r11, 0
stw r11, mrCullCount@l(r12)
lis r12, mrCullEpoch@ha
lwz r11, mrCullEpoch@l(r12)
addi r11, r11, 1
stw r11, mrCullEpoch@l(r12)
; Complete the submitted second eye BEFORE game calc reuses effect data.
stwu r1, -0x20(r1)
stw r0, 8(r1)
mflr r0
stw r0, 0x24(r1)
bl import.gx2.GX2DrawDone
lwz r0, 0x24(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0x20
lis r12, rrEye@ha
addi r12, r12, rrEye@l
li r11, 0
stw r11, 0(r12)
lwz r11, 4(r12)
addi r11, r11, 1
andi. r11, r11, 1
stw r11, 4(r12)
; Pose packet, published by the host; sequence is even when complete.
lis r12, rrSlot@ha
addi r12, r12, rrSlot@l
lwz r11, 0(r12)
mulli r11, r11, 196
lis r12, rrPoseLatch0@ha
addi r12, r12, rrPoseLatch0@l
add r12, r12, r11
li r11, 0
stw r11, 0(r12)
lis r8, rrPoseHeader@ha
addi r8, r8, rrPoseHeader@l
lwz r7, 8(r8)
andi. r11, r7, 1
bne rrPoseLatchDone
cmpwi r7, 0
beq rrPoseLatchDone
lwz r11, 12(r8)
cmpwi r11, 1
bne rrPoseLatchDone
.int 0x7C2004AC ; lwsync
lwz r11, 24(r8)
stw r11, 4(r12)
lwz r11, 28(r8)
stw r11, 8(r12)
lwz r11, 32(r8)
stw r11, 12(r12)
lwz r11, 36(r8)
stw r11, 16(r12)
lwz r11, 40(r8)
stw r11, 20(r12)
lwz r11, 44(r8)
stw r11, 24(r12)
lwz r11, 48(r8)
stw r11, 28(r12)
lwz r11, 52(r8)
stw r11, 32(r12)
lwz r11, 56(r8)
stw r11, 36(r12)
lwz r11, 60(r8)
stw r11, 40(r12)
lwz r11, 64(r8)
stw r11, 44(r12)
lwz r11, 68(r8)
stw r11, 48(r12)
lwz r11, 72(r8)
stw r11, 52(r12)
lwz r11, 76(r8)
stw r11, 56(r12)
lwz r11, 80(r8)
stw r11, 60(r12)
lwz r11, 84(r8)
stw r11, 64(r12)
lwz r11, 88(r8)
stw r11, 68(r12)
lwz r11, 92(r8)
stw r11, 72(r12)
lwz r11, 96(r8)
stw r11, 76(r12)
lwz r11, 100(r8)
stw r11, 80(r12)
lwz r11, 104(r8)
stw r11, 84(r12)
lwz r11, 108(r8)
stw r11, 88(r12)
lwz r11, 112(r8)
stw r11, 92(r12)
lwz r11, 116(r8)
stw r11, 96(r12)
lwz r11, 120(r8)
stw r11, 100(r12)
lwz r11, 124(r8)
stw r11, 104(r12)
lwz r11, 128(r8)
stw r11, 108(r12)
lwz r11, 132(r8)
stw r11, 112(r12)
lwz r11, 136(r8)
stw r11, 116(r12)
lwz r11, 140(r8)
stw r11, 120(r12)
lwz r11, 144(r8)
stw r11, 124(r12)
lwz r11, 148(r8)
stw r11, 128(r12)
lwz r11, 152(r8)
stw r11, 132(r12)
lwz r11, 156(r8)
stw r11, 136(r12)
lwz r11, 160(r8)
stw r11, 140(r12)
lwz r11, 164(r8)
stw r11, 144(r12)
lwz r11, 168(r8)
stw r11, 148(r12)
lwz r11, 172(r8)
stw r11, 152(r12)
lwz r11, 176(r8)
stw r11, 156(r12)
lwz r11, 180(r8)
stw r11, 160(r12)
lwz r11, 184(r8)
stw r11, 164(r12)
lwz r11, 188(r8)
stw r11, 168(r12)
lwz r11, 192(r8)
stw r11, 172(r12)
lwz r11, 196(r8)
stw r11, 176(r12)
lwz r11, 200(r8)
stw r11, 180(r12)
lwz r11, 204(r8)
stw r11, 184(r12)
lwz r11, 208(r8)
stw r11, 188(r12)
lwz r11, 212(r8)
stw r11, 192(r12)
.int 0x7C2004AC ; lwsync
lwz r11, 8(r8)
cmpw r7, r11
bne rrPoseLatchDone
stw r7, 0(r12)
rrPoseLatchDone:
lis r12, mrSceneClass@ha
li r11, 0
stw r11, mrSceneClass@l(r12)
lis r9, rrSlot@ha
addi r9, r9, rrSlot@l
lwz r10, 0(r9)
mulli r10, r10, 8
lis r9, rrMenuCameraUsed@ha
addi r9, r9, rrMenuCameraUsed@l
add r9, r9, r10
li r10, 0
stw r10, 0(r9)
stw r10, 4(r9)
mr r3, r29
b rrAfterBeforeCalc
0x024DB300 = ba rrBeforeCalc

rrCopyMarker:
mflr r0
stwu r1, -0x20(r1)
stw r0, 0x24(r1)
stw r3, 0x1C(r1)
stw r4, 0x18(r1)
lis r12, rrCopyCalls@ha
addi r12, r12, rrCopyCalls@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
stw r3, 4(r12)
stw r4, 8(r12)
bl import.gx2.GX2CopyColorBufferToScanBuffer
; Only emit protocol clear commands after this process's core acknowledges support.
lis r12, rrMarkerAck@ha
addi r12, r12, rrMarkerAck@l
lwz r11, 0(r12)
lis r10, 0x4354
addi r10, r10, 0x4D31
cmpw r11, r10
bne rrCopyExit
lwz r4, 0x18(r1)
cmpwi r4, 1
beq rrCopyTV
cmpwi r4, 4
bne rrCopyExit
lis r12, rrValueDRC@ha
addi r12, r12, rrValueDRC@l
lfs f1, 0(r12)
b rrCopyEye
rrCopyTV:
lis r12, rrValueTV@ha
addi r12, r12, rrValueTV@l
lfs f1, 0(r12)
rrCopyEye:
lis r12, rrEye@ha
addi r12, r12, rrEye@l
lwz r11, 0(r12)
cmpwi r11, 0
lis r12, rrValueA@ha
addi r12, r12, rrValueA@l
bne rrCopyRight
lfs f2, 0(r12)
lfs f3, 4(r12)
b rrCopySlot
rrCopyRight:
lfs f3, 0(r12)
lfs f2, 4(r12)
rrCopySlot:
lis r12, rrSlot@ha
addi r12, r12, rrSlot@l
lwz r11, 0(r12)
cmpwi r11, 0
lis r12, rrValueZero@ha
addi r12, r12, rrValueZero@l
bne rrCopySlotOne
lfs f4, 0(r12)
b rrEmitMarker
rrCopySlotOne:
lfs f4, 4(r12)
rrEmitMarker:
lis r12, rrEmitCount@ha
addi r12, r12, rrEmitCount@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
; Preserve the ordinary eye marker across the metadata clear call.
stwu r1, -0x20(r1)
stfs f1, 8(r1)
stfs f2, 12(r1)
stfs f3, 16(r1)
stfs f4, 20(r1)
lis r12, rrSlot@ha
addi r12, r12, rrSlot@l
lwz r11, 0(r12)
mulli r11, r11, 196
lis r12, rrPoseLatch0@ha
addi r12, r12, rrPoseLatch0@l
add r12, r12, r11
lfs f3, 164(r12)
lfs f4, 168(r12)
lwz r11, 0(r12)
cmpwi r11, 0
beq rrPoseMarkerInvalid
mr r10, r11
lis r12, rrEye@ha
addi r12, r12, rrEye@l
lwz r11, 4(r12)
lwz r12, 0(r12)
mulli r11, r11, 2
add r11, r11, r12
mulli r11, r11, 4
lis r12, rrProjectionPoseSequence@ha
addi r12, r12, rrProjectionPoseSequence@l
add r12, r12, r11
lwz r11, 0(r12)
cmpw r10, r11
beq rrPoseMarkerValid
rrPoseMarkerInvalid:
lis r12, rrValueZero@ha
addi r12, r12, rrValueZero@l
lfs f3, 0(r12)
lfs f4, 0(r12)
rrPoseMarkerValid:
lis r12, rrPoseMarkerMagic@ha
addi r12, r12, rrPoseMarkerMagic@l
lfs f1, 0(r12)
lfs f2, 4(r12)
rrMenuMetadataSelect:
lis r12, rrEye@ha
addi r12, r12, rrEye@l
lwz r11, 0(r12)
lwz r12, 4(r12)
mulli r12, r12, 2
add r11, r11, r12
mulli r11, r11, 4
lis r12, rrMenuCameraUsed@ha
addi r12, r12, rrMenuCameraUsed@l
add r12, r12, r11
lwz r11, 0(r12)
cmpwi r11, 0
bne rrMenuMetadataDone
lis r12, rrMenuMetadataMagic@ha
addi r12, r12, rrMenuMetadataMagic@l
lfs f1, 0(r12)
rrMenuMetadataDone:
lwz r3, 0x3C(r1)
bl import.gx2.GX2ClearColor
lfs f1, 8(r1)
lfs f2, 12(r1)
lfs f3, 16(r1)
lfs f4, 20(r1)
addi r1, r1, 0x20
lwz r3, 0x1C(r1)
bl import.gx2.GX2ClearColor
rrCopyExit:
lwz r0, 0x24(r1)
mtlr r0
addi r1, r1, 0x20
blr

rrCameraHeader:
.int 0x43544341
.int 1
rrCameraEnabled:
.int 1
rrCameraCalls:
.int 0
rrCameraLeft:
.int 0
rrCameraRight:
.int 0
rrCameraSource:
.int 0
rrCameraCaller:
.int 0
rrCameraOriginal:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
rrCamera0:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
rrCamera1:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
rrCamera2:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
rrCamera3:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
rrCameraFactorLeft:
.int 0x3CA3D70A
rrCameraFactorRight:
.int 0xBCA3D70A
rrCameraMinusOne:
.int 0xBF800000
rrCameraHook:
; The original epilogue restored LR and SP. Only ABI-volatile registers follow.
cmpwi r3, 0
beq rrCameraExit
mflr r10
lis r12, rrCameraEnabled@ha
addi r12, r12, rrCameraEnabled@l
lwz r11, 0(r12)
cmpwi r11, 1
bne rrCameraExit
stw r3, 16(r12)
stw r10, 20(r12)
lwz r11, 4(r12)
addi r11, r11, 1
stw r11, 4(r12)
lis r9, rrEye@ha
addi r9, r9, rrEye@l
lwz r10, 0(r9)
lwz r9, 4(r9)
mulli r9, r9, 2
add r9, r9, r10
mulli r9, r9, 4
lis r10, rrMenuCameraUsed@ha
addi r10, r10, rrMenuCameraUsed@l
add r9, r9, r10
li r10, 1
stw r10, 0(r9)
lis r9, rrCameraOriginal@ha
addi r9, r9, rrCameraOriginal@l
lwz r11, 0(r3)
stw r11, 0(r9)
lwz r11, 4(r3)
stw r11, 4(r9)
lwz r11, 8(r3)
stw r11, 8(r9)
lwz r11, 12(r3)
stw r11, 12(r9)
lwz r11, 16(r3)
stw r11, 16(r9)
lwz r11, 20(r3)
stw r11, 20(r9)
lwz r11, 24(r3)
stw r11, 24(r9)
lwz r11, 28(r3)
stw r11, 28(r9)
lwz r11, 32(r3)
stw r11, 32(r9)
lwz r11, 36(r3)
stw r11, 36(r9)
lwz r11, 40(r3)
stw r11, 40(r9)
lwz r11, 44(r3)
stw r11, 44(r9)
lwz r11, 48(r3)
stw r11, 48(r9)
lwz r11, 52(r3)
stw r11, 52(r9)
lwz r11, 56(r3)
stw r11, 56(r9)
lwz r11, 60(r3)
stw r11, 60(r9)
lwz r11, 64(r3)
stw r11, 64(r9)
lwz r11, 68(r3)
stw r11, 68(r9)
lwz r11, 72(r3)
stw r11, 72(r9)
lwz r11, 76(r3)
stw r11, 76(r9)
lwz r11, 80(r3)
stw r11, 80(r9)
lwz r11, 84(r3)
stw r11, 84(r9)
lis r12, rrEye@ha
addi r12, r12, rrEye@l
lwz r10, 0(r12)
lwz r11, 4(r12)
mulli r11, r11, 2
add r11, r11, r10
mulli r11, r11, 88
lis r9, rrCamera0@ha
addi r9, r9, rrCamera0@l
add r9, r9, r11
lwz r11, 0(r3)
stw r11, 0(r9)
lwz r11, 4(r3)
stw r11, 4(r9)
lwz r11, 8(r3)
stw r11, 8(r9)
lwz r11, 12(r3)
stw r11, 12(r9)
lwz r11, 16(r3)
stw r11, 16(r9)
lwz r11, 20(r3)
stw r11, 20(r9)
lwz r11, 24(r3)
stw r11, 24(r9)
lwz r11, 28(r3)
stw r11, 28(r9)
lwz r11, 32(r3)
stw r11, 32(r9)
lwz r11, 36(r3)
stw r11, 36(r9)
lwz r11, 40(r3)
stw r11, 40(r9)
lwz r11, 44(r3)
stw r11, 44(r9)
lwz r11, 48(r3)
stw r11, 48(r9)
lwz r11, 52(r3)
stw r11, 52(r9)
lwz r11, 56(r3)
stw r11, 56(r9)
lwz r11, 60(r3)
stw r11, 60(r9)
lwz r11, 64(r3)
stw r11, 64(r9)
lwz r11, 68(r3)
stw r11, 68(r9)
lwz r11, 72(r3)
stw r11, 72(r9)
lwz r11, 76(r3)
stw r11, 76(r9)
lwz r11, 80(r3)
stw r11, 80(r9)
lwz r11, 84(r3)
stw r11, 84(r9)
lis r12, rrCameraLeft@ha
addi r12, r12, rrCameraLeft@l
cmpwi r10, 0
beq rrCameraChooseLeft
addi r12, r12, 4
rrCameraChooseLeft:
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
lis r12, rrSlot@ha
addi r12, r12, rrSlot@l
lwz r11, 0(r12)
mulli r11, r11, 196
lis r12, rrPoseLatch0@ha
addi r12, r12, rrPoseLatch0@l
add r12, r12, r11
lwz r11, 0(r12)
cmpwi r11, 0
beq rrPoseFallback
lis r8, rrValueOne@ha
addi r8, r8, rrValueOne@l
lfs f3, 0(r8)
; Same diagnostic eye numbering: eye0 uses physical right, eye1 left.
addi r12, r12, 4
cmpwi r10, 1
beq rrPoseEyeReady
addi r12, r12, 48
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f0, 52(r3)
stfs f0, 0(r8)
lfs f0, 56(r3)
stfs f0, 4(r8)
lfs f0, 60(r3)
stfs f0, 8(r8)
lis r11, mrSceneClass@ha
addi r11, r11, mrSceneClass@l
lwz r11, 0(r11)
lis r0, 0x1027
ori r0, r0, 0xF388
cmpw r11, r0
beq mrEyeIntro
lwz r11, 580(r3)
cmpwi r11, 0
beq mrEyeKeep
lis r0, 0x1000
cmplw r11, r0
blt mrEyeKeep
lis r0, 0x5000
cmplw r11, r0
bge mrEyeKeep
lfs f0, 1976(r11)
stfs f0, 0(r8)
lfs f0, 1980(r11)
lfs f1, 12(r8)
fadds f0, f0, f1
stfs f0, 4(r8)
lfs f0, 1984(r11)
stfs f0, 8(r8)
b mrEyeKeep
mrEyeIntro:
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f6, 20(r8)
lfs f0, 52(r3)
lfs f1, 64(r3)
fsubs f1, f1, f0
fmuls f1, f1, f6
fadds f0, f0, f1
stfs f0, 0(r8)
lfs f0, 56(r3)
lfs f1, 68(r3)
fsubs f1, f1, f0
fmuls f1, f1, f6
fadds f0, f0, f1
stfs f0, 4(r8)
lfs f0, 60(r3)
lfs f1, 72(r3)
fsubs f1, f1, f0
fmuls f1, f1, f6
fadds f0, f0, f1
stfs f0, 8(r8)
mrEyeKeep:
lfs f4, 20(r3)
lfs f5, 40(r3)
fmuls f4, f4, f5
lfs f5, 24(r3)
lfs f6, 36(r3)
fmuls f5, f5, f6
fsubs f4, f4, f5
lfs f5, 0(r3)
fmuls f7, f4, f5
lfs f4, 16(r3)
lfs f5, 40(r3)
fmuls f4, f4, f5
lfs f5, 24(r3)
lfs f6, 32(r3)
fmuls f5, f5, f6
fsubs f4, f4, f5
lfs f5, 4(r3)
fmuls f4, f4, f5
fsubs f7, f7, f4
lfs f4, 16(r3)
lfs f5, 36(r3)
fmuls f4, f4, f5
lfs f5, 20(r3)
lfs f6, 32(r3)
fmuls f5, f5, f6
fsubs f4, f4, f5
lfs f5, 8(r3)
fmuls f4, f4, f5
fadds f7, f7, f4
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f5, 4(r8)
lfs f6, 28(r8)
.int 0xFC073000 ; fcmpu cr0, f7, f6
bge mrLookHandKeep
fneg f5, f5
mrLookHandKeep:
stfs f5, 8(r8)
rrPoseEyeReady:
lfs f1, 0(r12)
lfs f2, 0(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r12)
lfs f2, 16(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 32(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 0(r9)
lfs f1, 0(r12)
lfs f2, 4(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r12)
lfs f2, 20(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 36(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 4(r9)
lfs f1, 0(r12)
lfs f2, 8(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r12)
lfs f2, 24(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 40(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 8(r9)
lfs f1, 0(r12)
lfs f2, 12(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r12)
lfs f2, 28(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 44(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f4, 0(r8)
lfs f5, 8(r8)
lfs f1, 0(r9)
lfs f2, 8(r9)
fmuls f0, f1, f4
fmuls f6, f2, f5
fsubs f0, f0, f6
fmuls f7, f1, f5
fmuls f8, f2, f4
fadds f7, f7, f8
stfs f0, 0(r9)
stfs f7, 8(r9)
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f1, 0(r9)
lfs f2, 0(r8)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r9)
lfs f2, 4(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r9)
lfs f2, 8(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fneg f0, f0
lfs f1, 12(r12)
fadds f0, f0, f1
stfs f0, 12(r9)
lfs f1, 16(r12)
lfs f2, 0(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r12)
lfs f2, 16(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 32(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 16(r9)
lfs f1, 16(r12)
lfs f2, 4(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r12)
lfs f2, 20(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 36(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 20(r9)
lfs f1, 16(r12)
lfs f2, 8(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r12)
lfs f2, 24(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 40(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 24(r9)
lfs f1, 16(r12)
lfs f2, 12(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r12)
lfs f2, 28(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 44(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f4, 0(r8)
lfs f5, 8(r8)
lfs f1, 16(r9)
lfs f2, 24(r9)
fmuls f0, f1, f4
fmuls f6, f2, f5
fsubs f0, f0, f6
fmuls f7, f1, f5
fmuls f8, f2, f4
fadds f7, f7, f8
stfs f0, 16(r9)
stfs f7, 24(r9)
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f1, 16(r9)
lfs f2, 0(r8)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r9)
lfs f2, 4(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r9)
lfs f2, 8(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fneg f0, f0
lfs f1, 28(r12)
fadds f0, f0, f1
stfs f0, 28(r9)
lfs f1, 32(r12)
lfs f2, 0(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r12)
lfs f2, 16(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 32(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 32(r9)
lfs f1, 32(r12)
lfs f2, 4(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r12)
lfs f2, 20(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 36(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 36(r9)
lfs f1, 32(r12)
lfs f2, 8(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r12)
lfs f2, 24(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 40(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 40(r9)
lfs f1, 32(r12)
lfs f2, 12(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r12)
lfs f2, 28(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 44(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f4, 0(r8)
lfs f5, 8(r8)
lfs f1, 32(r9)
lfs f2, 40(r9)
fmuls f0, f1, f4
fmuls f6, f2, f5
fsubs f0, f0, f6
fmuls f7, f1, f5
fmuls f8, f2, f4
fadds f7, f7, f8
stfs f0, 32(r9)
stfs f7, 40(r9)
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f1, 32(r9)
lfs f2, 0(r8)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r9)
lfs f2, 4(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r9)
lfs f2, 8(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fneg f0, f0
lfs f1, 44(r12)
fadds f0, f0, f1
stfs f0, 44(r9)
lis r8, rrCameraMinusOne@ha
addi r8, r8, rrCameraMinusOne@l
lfs f4, 0(r8)
lfs f1, 52(r3)
lfs f2, 64(r3)
fmuls f2, f2, f4
fadds f1, f1, f2
lfs f2, 32(r3)
fmuls f1, f1, f2
fmuls f5, f1, f3
lfs f1, 56(r3)
lfs f2, 68(r3)
fmuls f2, f2, f4
fadds f1, f1, f2
lfs f2, 36(r3)
fmuls f1, f1, f2
fadds f5, f5, f1
lfs f1, 60(r3)
lfs f2, 72(r3)
fmuls f2, f2, f4
fadds f1, f1, f2
lfs f2, 40(r3)
fmuls f1, f1, f2
fadds f5, f5, f1
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f5, 16(r8)
lfs f1, 0(r9)
lfs f2, 12(r9)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 16(r9)
lfs f2, 28(r9)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 32(r9)
lfs f2, 44(r9)
fmuls f1, f1, f2
fadds f0, f0, f1
fmuls f0, f0, f4
stfs f0, 52(r9)
lfs f1, 32(r9)
fmuls f1, f1, f5
fmuls f1, f1, f4
fadds f1, f0, f1
stfs f1, 64(r9)
lfs f1, 16(r9)
stfs f1, 76(r9)
lfs f1, 4(r9)
lfs f2, 12(r9)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r9)
lfs f2, 28(r9)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 36(r9)
lfs f2, 44(r9)
fmuls f1, f1, f2
fadds f0, f0, f1
fmuls f0, f0, f4
stfs f0, 56(r9)
lfs f1, 36(r9)
fmuls f1, f1, f5
fmuls f1, f1, f4
fadds f1, f0, f1
stfs f1, 68(r9)
lfs f1, 20(r9)
stfs f1, 80(r9)
lfs f1, 8(r9)
lfs f2, 12(r9)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 24(r9)
lfs f2, 28(r9)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r9)
lfs f2, 44(r9)
fmuls f1, f1, f2
fadds f0, f0, f1
fmuls f0, f0, f4
stfs f0, 60(r9)
lfs f1, 40(r9)
fmuls f1, f1, f5
fmuls f1, f1, f4
fadds f1, f0, f1
stfs f1, 72(r9)
lfs f1, 24(r9)
stfs f1, 84(r9)
lis r12, rrSlot@ha
addi r12, r12, rrSlot@l
lwz r11, 0(r12)
mulli r11, r11, 196
lis r12, rrPoseLatch0@ha
addi r12, r12, rrPoseLatch0@l
add r12, r12, r11
lwz r8, 0(r12)
lis r12, rrSlot@ha
addi r12, r12, rrSlot@l
lwz r11, 0(r12)
mulli r11, r11, 2
add r11, r11, r10
mulli r11, r11, 4
lis r12, rrCameraPoseSequence@ha
addi r12, r12, rrCameraPoseSequence@l
add r12, r12, r11
stw r8, 0(r12)
lis r12, rrPoseUsed@ha
addi r12, r12, rrPoseUsed@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
mr r3, r9
blr
rrPoseFallback:
rrCameraExit:
blr


rrSecondRecord:
.int 0
rrShadowSkipped:
.int 0

0x026EA934 = rrShadowOriginalAlloc:
rrShadowAlloc:
lis r12, rrSecondRecord@ha
addi r12, r12, rrSecondRecord@l
lwz r11, 0(r12)
cmpwi r11, 1
beq rrShadowSkipAlloc
b rrShadowOriginalAlloc
rrShadowSkipAlloc:
lwz r11, 4(r12)
addi r11, r11, 1
stw r11, 4(r12)
blr
0x02450A8C = bla rrShadowAlloc

0x026EA95C = rrShadowOriginalDraw:
rrShadowDraw:
lis r12, rrSecondRecord@ha
addi r12, r12, rrSecondRecord@l
lwz r11, 0(r12)
cmpwi r11, 1
beq rrShadowSkipDraw
b rrShadowOriginalDraw
rrShadowSkipDraw:
lwz r11, 4(r12)
addi r11, r11, 1
stw r11, 4(r12)
blr
0x02450A98 = bla rrShadowDraw

; Root Calc receives its scene-owner object in r31 at 022F37F0.
; Preserve scratch registers and CR across the displaced mr r3,r31.
mrSceneProbe:
stwu r1, -0x20(r1)
stw r0, 8(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 12(r1)
stw r11, 16(r1)
stw r12, 20(r1)
mr r3, r31
lis r12, mrSceneClass@ha
addi r12, r12, mrSceneClass@l
li r11, 0
stw r11, 0(r12)
cmpwi r3, 0
beq mrSceneDone
lwz r11, 8(r3)
cmpwi r11, 0
beq mrSceneDone
lis r0, 0x1000
cmplw r11, r0
blt mrSceneDone
lis r0, 0x5000
cmplw r11, r0
bge mrSceneDone
lwz r11, 0x5C(r11)
cmpwi r11, 0
beq mrSceneDone
lis r0, 0x1000
cmplw r11, r0
blt mrSceneDone
lis r0, 0x5000
cmplw r11, r0
bge mrSceneDone
lwz r11, 0(r11)
stw r11, 0(r12)
mrSceneDone:
lwz r12, 20(r1)
lwz r11, 16(r1)
lwz r0, 12(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 8(r1)
addi r1, r1, 0x20
b mrSceneProbeReturn
0x022F37F4 = mrSceneProbeReturn:
0x022F37F0 = ba mrSceneProbe

rrPoseHeader:
.int 0x43545048
.int 4
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
rrPoseLatch0:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
rrPoseUsed:
.int 0
mrEyeTarget:
.int 0
.int 0
.int 0
.int 0x43110000
.int 0x42C80000
.int 0x3F2147AE
mrSceneClass:
.int 0
mrLookCos:
.int 0x3F800000
mrLookSin:
.int 0
mrLookSinEff:
.int 0
.int 0x3D3EA2F1
.int 0x3E19999A
.int 0x3F800000
.int 0x3F000000
.int 0x00000000
.int 0xBF666666
.int 0x3E99999A

mrLookInput:
stwu r1, -0x30(r1)
mflr r0
stw r0, 0x34(r1)
stw r4, 8(r1)
stw r6, 12(r1)
bl import.vpad.VPADRead
lwz r4, 8(r1)
lwz r6, 12(r1)
cmpwi r3, 0
ble mrLookInputDone
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f1, 0x14(r4)
.int 0xFC400A10 ; fabs f2, f1
; Straight down on the camera stick puts the view back on the game camera.
; No button is involved: every other form here is one Cemu's assembler has
; already accepted in a running pack, and that stays true.
lfs f6, 0x18(r4)
lfs f0, 32(r8)
.int 0xFC060000 ; fcmpu cr0, f6, f0
bge mrLookNoReset
lfs f0, 36(r8)
.int 0xFC001000 ; fcmpu cr0, f0, f2
blt mrLookNoReset
lfs f0, 20(r8)
stfs f0, 0(r8)
lfs f0, 28(r8)
stfs f0, 4(r8)
stfs f0, 8(r8)
b mrLookNoTurn
mrLookNoReset:
lfs f0, 16(r8)
.int 0xFC020000 ; fcmpu cr0, f2, f0
blt mrLookNoTurn
lfs f0, 12(r8)
fmuls f1, f1, f2
fmuls f1, f1, f0
lfs f4, 0(r8)
lfs f5, 4(r8)
fmuls f6, f1, f1
lfs f7, 24(r8)
fmuls f6, f6, f7
lfs f7, 20(r8)
fsubs f6, f7, f6
fmuls f7, f4, f6
fmuls f8, f5, f1
fsubs f7, f7, f8
fmuls f9, f5, f6
fmuls f10, f4, f1
fadds f9, f9, f10
stfs f7, 0(r8)
stfs f9, 4(r8)
mrLookNoTurn:
lfs f4, 0(r8)
lfs f5, 4(r8)
lfs f0, 28(r8)
mr r10, r3
cmpwi r10, 16
ble mrLookSample
li r10, 16
mrLookSample:
mr r11, r4
li r9, 0
mrLookNext:
cmpw r9, r10
bge mrLookInputDone
lfs f1, 0x0C(r11)
lfs f2, 0x10(r11)
fmuls f6, f1, f4
fmuls f7, f2, f5
fadds f6, f6, f7
fmuls f8, f2, f4
fmuls f10, f1, f5
fsubs f8, f8, f10
stfs f6, 0x0C(r11)
stfs f8, 0x10(r11)
stfs f0, 0x14(r11)
stfs f0, 0x18(r11)
addi r11, r11, 0xAC
addi r9, r9, 1
b mrLookNext
mrLookInputDone:
lwz r0, 0x34(r1)
mtlr r0
addi r1, r1, 0x30
blr
0x0236CA4C = bla mrLookInput

rrProjectionHeader:
.int 0x4354504A
.int 1
rrProjectionHits:
.int 0
rrProjectionSource:
.int 0
rrProjectionVtable:
.int 0x10347B00
rrProjectionCopies:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0


rrProjectionHook:
stwu r1, -0x20(r1)
stw r0, 8(r1)
stw r10, 12(r1)
stw r11, 16(r1)
stw r12, 20(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 24(r1)
cmpwi r21, 0
bne rrProjectionExit
lis r12, rrEye@ha
addi r12, r12, rrEye@l
lwz r10, 0(r12)
lwz r11, 4(r12)
mulli r11, r11, 2
add r11, r11, r10
mulli r11, r11, 88
lis r12, rrCamera0@ha
addi r12, r12, rrCamera0@l
add r12, r12, r11
cmpw r15, r12
bne rrProjectionExit
; Only the camera already accepted by the consumer may change projection.
lis r12, rrSlot@ha
addi r12, r12, rrSlot@l
lwz r11, 0(r12)
mulli r11, r11, 196
lis r12, rrPoseLatch0@ha
addi r12, r12, rrPoseLatch0@l
add r12, r12, r11
lwz r11, 0(r12)
cmpwi r11, 0
beq rrProjectionExit
lis r11, rrSlot@ha
addi r11, r11, rrSlot@l
lwz r11, 0(r11)
mulli r11, r11, 2
add r11, r11, r10
mulli r11, r11, 4
lis r0, rrCameraPoseSequence@ha
add r11, r11, r0
addi r11, r11, rrCameraPoseSequence@l
lwz r0, 0(r11)
lwz r11, 0(r12)
cmpw r0, r11
bne rrProjectionExit
; Verify concrete perspective object class before copying its complete object.
lwz r11, 144(r16)
lis r10, rrProjectionVtable@ha
addi r10, r10, rrProjectionVtable@l
lwz r0, 0(r10)
cmpw r11, r0
bne rrProjectionExit
lis r10, rrEye@ha
addi r10, r10, rrEye@l
lwz r10, 0(r10)
addi r12, r12, 100
cmpwi r10, 1
beq rrProjectionEyeReady
addi r12, r12, 32
rrProjectionEyeReady:
lis r11, rrSlot@ha
addi r11, r11, rrSlot@l
lwz r11, 0(r11)
mulli r11, r11, 2
add r11, r11, r10
mulli r11, r11, 184
lis r10, rrProjectionCopies@ha
addi r10, r10, rrProjectionCopies@l
add r10, r10, r11
lis r11, rrProjectionSource@ha
addi r11, r11, rrProjectionSource@l
stw r16, 0(r11)
lwz r11, 0(r16)
stw r11, 0(r10)
lwz r11, 4(r16)
stw r11, 4(r10)
lwz r11, 8(r16)
stw r11, 8(r10)
lwz r11, 12(r16)
stw r11, 12(r10)
lwz r11, 16(r16)
stw r11, 16(r10)
lwz r11, 20(r16)
stw r11, 20(r10)
lwz r11, 24(r16)
stw r11, 24(r10)
lwz r11, 28(r16)
stw r11, 28(r10)
lwz r11, 32(r16)
stw r11, 32(r10)
lwz r11, 36(r16)
stw r11, 36(r10)
lwz r11, 40(r16)
stw r11, 40(r10)
lwz r11, 44(r16)
stw r11, 44(r10)
lwz r11, 48(r16)
stw r11, 48(r10)
lwz r11, 52(r16)
stw r11, 52(r10)
lwz r11, 56(r16)
stw r11, 56(r10)
lwz r11, 60(r16)
stw r11, 60(r10)
lwz r11, 64(r16)
stw r11, 64(r10)
lwz r11, 68(r16)
stw r11, 68(r10)
lwz r11, 72(r16)
stw r11, 72(r10)
lwz r11, 76(r16)
stw r11, 76(r10)
lwz r11, 80(r16)
stw r11, 80(r10)
lwz r11, 84(r16)
stw r11, 84(r10)
lwz r11, 88(r16)
stw r11, 88(r10)
lwz r11, 92(r16)
stw r11, 92(r10)
lwz r11, 96(r16)
stw r11, 96(r10)
lwz r11, 100(r16)
stw r11, 100(r10)
lwz r11, 104(r16)
stw r11, 104(r10)
lwz r11, 108(r16)
stw r11, 108(r10)
lwz r11, 112(r16)
stw r11, 112(r10)
lwz r11, 116(r16)
stw r11, 116(r10)
lwz r11, 120(r16)
stw r11, 120(r10)
lwz r11, 124(r16)
stw r11, 124(r10)
lwz r11, 128(r16)
stw r11, 128(r10)
lwz r11, 132(r16)
stw r11, 132(r10)
lwz r11, 136(r16)
stw r11, 136(r10)
lwz r11, 140(r16)
stw r11, 140(r10)
lwz r11, 144(r16)
stw r11, 144(r10)
lwz r11, 148(r16)
stw r11, 148(r10)
lwz r11, 152(r16)
stw r11, 152(r10)
lwz r11, 156(r16)
stw r11, 156(r10)
lwz r11, 160(r16)
stw r11, 160(r10)
lwz r11, 164(r16)
stw r11, 164(r10)
lwz r11, 168(r16)
stw r11, 168(r10)
lwz r11, 172(r16)
stw r11, 172(r10)
lwz r11, 176(r16)
stw r11, 176(r10)
lwz r11, 180(r16)
stw r11, 180(r10)
lwz r11, 0(r12)
stw r11, 168(r10)
lwz r11, 4(r12)
stw r11, 172(r10)
lwz r11, 8(r12)
stw r11, 176(r10)
lwz r11, 12(r12)
stw r11, 180(r10)
lwz r11, 16(r12)
stw r11, 4(r10)
stw r11, 68(r10)
lwz r11, 20(r12)
stw r11, 12(r10)
stw r11, 76(r10)
lwz r11, 24(r12)
stw r11, 24(r10)
stw r11, 88(r10)
lwz r11, 28(r12)
stw r11, 28(r10)
stw r11, 92(r10)
lis r11, rrEye@ha
addi r11, r11, rrEye@l
lwz r11, 0(r11)
cmpwi r11, 1
beq rrScalarLeft
lwz r11, 52(r12)
stw r11, 156(r10)
lwz r11, 56(r12)
stw r11, 160(r10)
lwz r11, 60(r12)
stw r11, 164(r10)
b rrScalarDone
rrScalarLeft:
lwz r11, 72(r12)
stw r11, 156(r10)
lwz r11, 76(r12)
stw r11, 160(r10)
lwz r11, 80(r12)
stw r11, 164(r10)
rrScalarDone:
lwz r11, 0(r10)
andi. r11, r11, 65535
lis r0, 0x0101
add r11, r11, r0
stw r11, 0(r10)
mr r16, r10
lis r12, rrSlot@ha
addi r12, r12, rrSlot@l
lwz r11, 0(r12)
mulli r11, r11, 196
lis r12, rrPoseLatch0@ha
addi r12, r12, rrPoseLatch0@l
add r12, r12, r11
lwz r0, 0(r12)
lis r12, rrEye@ha
addi r12, r12, rrEye@l
lwz r10, 0(r12)
lwz r11, 4(r12)
mulli r11, r11, 2
add r11, r11, r10
mulli r11, r11, 4
lis r12, rrProjectionPoseSequence@ha
addi r12, r12, rrProjectionPoseSequence@l
add r12, r12, r11
stw r0, 0(r12)
lis r12, rrProjectionHits@ha
addi r12, r12, rrProjectionHits@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
rrProjectionExit:
lwz r0, 24(r1)
.int 0x7C0FF120 ; mtcrf 255, r0
lwz r0, 8(r1)
lwz r10, 12(r1)
lwz r11, 16(r1)
lwz r12, 20(r1)
addi r1, r1, 0x20
blr

rrPoseMarkerMagic:
.int 0x3E400000
.int 0x3F500000
rrCameraPoseSequence:
.int 0
.int 0
.int 0
.int 0
rrProjectionPoseSequence:
.int 0
.int 0
.int 0
.int 0

rrMenuCameraUsed:
.int 0
.int 0
.int 0
.int 0
rrMenuMetadataMagic:
.int 0x3E600000

0x026EA584 = rrShadowSecondOriginal0:
rrShadowSecondSkip0:
lis r12, rrSecondRecord@ha
lwz r11, rrSecondRecord@l(r12)
cmpwi r11, 1
beqlr
b rrShadowSecondOriginal0
0x02451098 = bla rrShadowSecondSkip0

0x026EA584 = rrShadowSecondOriginal1:
rrShadowSecondSkip1:
lis r12, rrSecondRecord@ha
lwz r11, rrSecondRecord@l(r12)
cmpwi r11, 1
beqlr
b rrShadowSecondOriginal1
0x02451158 = bla rrShadowSecondSkip1

0x026EA840 = rrShadowSecondOriginal2:
rrShadowSecondSkip2:
lis r12, rrSecondRecord@ha
lwz r11, rrSecondRecord@l(r12)
cmpwi r11, 1
beqlr
b rrShadowSecondOriginal2
0x02451198 = bla rrShadowSecondSkip2

0x0235A198 = bla rrCopyMarker

0x0235A1E8 = bla rrCopyMarker

0x0235A2C4 = bla rrCopyMarker

0x0235A324 = bla rrCopyMarker

0x0235A550 = bla rrCopyMarker

0x0235A698 = bla rrCopyMarker

0x02379030 = bla rrCopyMarker

0x02394FD8 = bla rrCopyMarker

0x02394FF8 = bla rrCopyMarker

mrStereoRender:
stwu r1, -0x100(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026
stw r0, 16(r1)
stw r3, 20(r1)
stw r4, 24(r1)
stw r5, 28(r1)
stw r6, 32(r1)
stw r7, 36(r1)
stw r8, 40(r1)
stw r9, 44(r1)
stw r10, 48(r1)
stw r11, 52(r1)
stw r12, 56(r1)
stw r15, 60(r1)
stw r16, 64(r1)
stw r21, 68(r1)
stfd f0, 80(r1)
stfd f1, 88(r1)
stfd f2, 96(r1)
stfd f3, 104(r1)
stfd f4, 112(r1)
stfd f5, 120(r1)
stfd f6, 128(r1)
stfd f7, 136(r1)
stfd f8, 144(r1)
stfd f9, 152(r1)
stfd f10, 160(r1)
stfd f11, 168(r1)
stfd f12, 176(r1)
stfd f13, 184(r1)
li r11, 0
lis r12, mrActiveCamera@ha
stw r11, mrActiveCamera@l(r12)
cmpwi r27, 0
beq mrStereoRestore
cmpwi r31, 0
beq mrStereoRestore
lwz r11, 144(r31)
lis r12, 0x1034
addi r12, r12, 0x7B00
cmpw r11, r12
bne mrStereoRestore
mr r3, r27
mr r16, r31
bl rrCameraHook
mr r15, r3
li r21, 0
bl rrProjectionHook
cmpw r16, r31
beq mrStereoRestore
mr r27, r15
mr r31, r16
lis r12, mrActiveCamera@ha
stw r27, mrActiveCamera@l(r12)
mrStereoRestore:
lfd f0, 80(r1)
lfd f1, 88(r1)
lfd f2, 96(r1)
lfd f3, 104(r1)
lfd f4, 112(r1)
lfd f5, 120(r1)
lfd f6, 128(r1)
lfd f7, 136(r1)
lfd f8, 144(r1)
lfd f9, 152(r1)
lfd f10, 160(r1)
lfd f11, 168(r1)
lfd f12, 176(r1)
lfd f13, 184(r1)
lwz r3, 20(r1)
lwz r4, 24(r1)
lwz r5, 28(r1)
lwz r6, 32(r1)
lwz r7, 36(r1)
lwz r8, 40(r1)
lwz r9, 44(r1)
lwz r10, 48(r1)
lwz r11, 52(r1)
lwz r12, 56(r1)
lwz r15, 60(r1)
lwz r16, 64(r1)
lwz r21, 68(r1)
lwz r0, 16(r1)
.int 0x7C0FF120
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0x100
lwz r3, 4(r24)
b mrNativeRender
0x022D7FC8 = mrNativeRender:
0x022D7FC4 = ba mrStereoRender

mrActiveCamera:
.int 0
mrShadowUpload:
stwu r1, -0x50(r1)
mflr r0
stw r0, 0x54(r1)
stw r3, 8(r1)
stw r4, 12(r1)
stw r5, 16(r1)
stw r6, 20(r1)
stw r7, 24(r1)
stw r8, 28(r1)
stw r9, 32(r1)
stw r10, 36(r1)
stw r11, 40(r1)
stw r12, 44(r1)
lis r12, mrActiveCamera@ha
lwz r12, mrActiveCamera@l(r12)
cmpwi r12, 0
beq mrShadowRestore
cmpw r5, r12
bne mrShadowRestore
lbz r11, 0x111(r3)
cmpwi r11, 0
beq mrShadowRestore
cmplwi r4, 2
li r11, 0
bge mrShadowInverse
mulli r11, r4, 48
mrShadowInverse:
addi r4, r3, 0xA4
add r4, r4, r11
mr r3, r5
bl mrInverseView
mrShadowRestore:
lwz r3, 8(r1)
lwz r4, 12(r1)
lwz r5, 16(r1)
lwz r6, 20(r1)
lwz r7, 24(r1)
lwz r8, 28(r1)
lwz r9, 32(r1)
lwz r10, 36(r1)
lwz r11, 40(r1)
lwz r12, 44(r1)
lwz r0, 0x54(r1)
mtlr r0
addi r1, r1, 0x50
stwu r1, -0x80(r1)
b mrShadowNative
0x026ADD2C = mrInverseView:
0x02450AFC = mrShadowNative:
0x02450AF8 = ba mrShadowUpload
0x022D77B0 = mr r29, r26
0x022D77C4 = mr r31, r26
0x022D77EC = mr r3, r26
0x022D72F4 = mr r19, r30

; HUT2: binding calls, current slot0 buffer, HUD calls, four eye/slot records.
rrHudTargetData:
.int 0x48555432
.int 0
.int 0
.int 0
rrHudTargetRecords:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0

0x024ED554 = rrHudOriginalDraw:
rrHudTrackColor:
; Tail-call original binding with all argument registers unchanged.
cmpwi r4, 0
bne rrHudTrackExit
lis r12, rrHudTargetData@ha
addi r12, r12, rrHudTargetData@l
lwz r11, 4(r12)
addi r11, r11, 1
stw r11, 4(r12)
stw r3, 8(r12)
rrHudTrackExit:
b import.gx2.GX2SetColorBuffer
rrHudTrackDraw:
mflr r0
stwu r1, -0x40(r1)
stw r0, 0x44(r1)
stw r3, 0x30(r1)
li r0, 0
stw r0, 0x28(r1)
; r7 is actor; r3 is original layout argument. Do not alter either.
lwz r11, 0(r7)
lis r12, 0x102B
addi r12, r12, -14928
cmpw r11, r12
bne rrHudDrawPass
lis r12, rrHudTargetData@ha
addi r12, r12, rrHudTargetData@l
lwz r11, 12(r12)
addi r11, r11, 1
stw r11, 12(r12)
stw r11, 0x18(r1)
lis r10, rrSlot@ha
addi r10, r10, rrSlot@l
lwz r10, 0(r10)
andi. r10, r10, 1
add r10, r10, r10
lis r11, rrEye@ha
addi r11, r11, rrEye@l
lwz r11, 0(r11)
andi. r11, r11, 1
add r10, r10, r11
add r10, r10, r10
add r10, r10, r10
add r10, r10, r10
add r10, r10, r10
add r10, r10, r10
addi r10, r10, 16
add r10, r12, r10
; count, actor, layout, current buffer, binding serial, reserved*3.
lwz r11, 0(r10)
addi r11, r11, 1
stw r11, 0(r10)
stw r7, 4(r10)
stw r3, 8(r10)
lwz r11, 8(r12)
stw r11, 12(r10)
lwz r11, 4(r12)
stw r11, 16(r10)
lis r12, rrHudWorldAck@ha
addi r12, r12, rrHudWorldAck@l
lwz r11, 0(r12)
lis r10, 0x4855
addi r10, r10, 0x4132
cmpw r11, r10
bne rrHudDrawPass
lis r12, rrHudTargetData@ha
addi r12, r12, rrHudTargetData@l
lwz r3, 8(r12)
cmpwi r3, 0
beq rrHudDrawPass
lwz r11, 4(r3)
cmpwi r11, 1280
bne rrHudDrawPass
lwz r11, 8(r3)
cmpwi r11, 720
bne rrHudDrawPass
stw r3, 0x2c(r1)
li r0, 1
stw r0, 0x28(r1)
li r4, 0
bl rrHudEmit
rrHudDrawPass:
lwz r3, 0x30(r1)
bl rrHudOriginalDraw
lwz r0, 0x28(r1)
cmpwi r0, 0
beq rrHudWorldExit
lwz r3, 0x2c(r1)
li r4, 1
bl rrHudEmit
rrHudWorldExit:
lwz r0, 0x44(r1)
mtlr r0
addi r1, r1, 0x40
blr
rrHudWorldMagic:
.int 0x48554132
rrHudWorldAck:
.int 0
rrHudValues:
.int 0x3e900000
.int 0x3f300000
.int 0x3e800000
.int 0x3f400000
.int 0x00000000
.int 0x3e800000
.int 0x3f000000
.int 0x3f400000
rrHudEmit:
lis r12, rrHudValues@ha
addi r12, r12, rrHudValues@l
lfs f1, 0(r12)
lfs f2, 4(r12)
cmpwi r4, 0
bne rrHudEmitEnd
lfs f3, 8(r12)
b rrHudEmitIndex
rrHudEmitEnd:
lfs f3, 12(r12)
rrHudEmitIndex:
lis r10, mrUiTitleGroup@ha
lwz r10, mrUiTitleGroup@l(r10)
cmpwi r10, 0
beq mrUiMarkerColorReady
lis r10, mrUiTitleColor@ha
lfs f1, mrUiTitleColor@l(r10)
mrUiMarkerColorReady:
lis r10, rrSlot@ha
addi r10, r10, rrSlot@l
lwz r10, 0(r10)
add r10, r10, r10
lis r11, rrEye@ha
addi r11, r11, rrEye@l
lwz r11, 0(r11)
add r10, r10, r11
add r10, r10, r10
add r10, r10, r10
add r12, r12, r10
lfs f4, 16(r12)
b import.gx2.GX2ClearColor


0x023598CC = bla rrHudTrackColor

0x02359CB0 = bla rrHudTrackColor

0x02379068 = bla rrHudTrackColor

0x02395480 = bla rrHudTrackColor

0x023954B8 = bla rrHudTrackColor

0x0261E37C = bla rrHudTrackColor

0x02620120 = bla rrHudTrackColor

0x026236DC = bla rrHudTrackColor

0x02628ED0 = bla rrHudTrackColor

0x026AED58 = bla rrHudTrackColor

mrUiActiveBuffer:
.int 0
mrUiTitleGroup:
.int 0
mrUiTitleColor:
.int 0x3EB00000
mrUiGroupBegin:
stwu r1, -0x20(r1)
mflr r0
stw r0, 0x24(r1)
lis r12, mrUiActiveBuffer@ha
li r11, 0
stw r11, mrUiActiveBuffer@l(r12)
lis r12, mrUiTitleGroup@ha
stw r11, mrUiTitleGroup@l(r12)
lis r12, rrHudWorldAck@ha
lwz r11, rrHudWorldAck@l(r12)
lis r10, 0x4855
addi r10, r10, 0x4132
cmpw r11, r10
bne mrUiGroupBeginExit
; Pure menus already use the host's complete menu surface; do not remove them.
lis r12, rrSlot@ha
lwz r11, rrSlot@l(r12)
mulli r11, r11, 2
lis r12, rrEye@ha
lwz r10, rrEye@l(r12)
add r11, r11, r10
mulli r11, r11, 4
lis r12, rrMenuCameraUsed@ha
addi r12, r12, rrMenuCameraUsed@l
lwzx r11, r12, r11
cmpwi r11, 0
beq mrUiGroupBeginExit
lis r12, rrHudTargetData@ha
addi r12, r12, rrHudTargetData@l
lwz r3, 8(r12)
cmpwi r3, 0
beq mrUiGroupBeginExit
lwz r11, 4(r3)
cmpwi r11, 1280
bne mrUiGroupBeginExit
lwz r11, 8(r3)
cmpwi r11, 720
bne mrUiGroupBeginExit
lis r12, mrUiActiveBuffer@ha
stw r3, mrUiActiveBuffer@l(r12)
; Inspect the same visible actors as the native layout loop. TitleLogo is
; the verified 102AC5B0 class; unrelated scene HUDs retain the game profile.
bl mrUiClassify
li r4, 0
bl rrHudEmit
mrUiGroupBeginExit:
lwz r0, 0x24(r1)
mtlr r0
addi r1, r1, 0x20
lwz r0, 0xC(r31)
b mrUiGroupLoop
mrUiGroupEnd:
stwu r1, -0x20(r1)
mflr r0
stw r0, 0x24(r1)
lis r12, mrUiActiveBuffer@ha
lwz r3, mrUiActiveBuffer@l(r12)
li r11, 0
stw r11, mrUiActiveBuffer@l(r12)
cmpwi r3, 0
beq mrUiGroupEndExit
li r4, 1
bl rrHudEmit
mrUiGroupEndExit:
lwz r0, 0x24(r1)
mtlr r0
addi r1, r1, 0x20
lwz r29, 0xC(r1)
b mrUiGroupReturn
0x02465764 = ba mrUiGroupBegin
0x02465768 = mrUiGroupLoop:
0x024657A8 = ba mrUiGroupEnd
0x024657AC = mrUiGroupReturn:
mrUiClassify:
lwz r8, 0xC(r31)
cmpwi r8, 0
ble mrUiClassifyExit
lwz r9, 0x10(r31)
li r10, 0
mrUiClassifyLoop:
lwzx r11, r9, r10
lbz r12, 0x4C(r11)
cmpwi r12, 0
beq mrUiClassifyNext
lwz r11, 0(r11)
lis r12, 0x102B
addi r12, r12, -14928
cmpw r11, r12
bne mrUiClassifyNext
lis r12, mrUiTitleGroup@ha
li r11, 1
stw r11, mrUiTitleGroup@l(r12)
blr
mrUiClassifyNext:
addi r10, r10, 4
addi r8, r8, -1
cmpwi r8, 0
bgt mrUiClassifyLoop
mrUiClassifyExit:
blr

; MCUL v1: epoch/count/builds/tests/rescues/invalid/overflow/native-visible.
mrCullHeader:
.int 0x4D43554C
.int 1
mrCullEpoch:
.int 0
mrCullCount:
.int 0
mrCullBuilds:
.int 0
mrCullTests:
.int 0
mrCullRescues:
.int 0
mrCullInvalid:
.int 0
mrCullOverflow:
.int 0
mrCullNativeVisible:
.int 0
mrCullOne:
.int 0x3F800000
mrCullZero:
.int 0
mrCullEntries:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0

0x02430A8C = mrCullBuildNative:
0x02430B10 = mrCullTestContinue:
0x0243079C = bla mrCullBuild
0x02430B0C = ba mrCullTest

mrCullBuild:
stwu r1, -0x40(r1)
mflr r0
stw r0, 0x44(r1)
stw r3, 8(r1)
stw r4, 12(r1)
stw r5, 16(r1)
bl mrCullBuildNative
stw r3, 20(r1)
lwz r5, 16(r1)
; Matrix is perspective-object+0x44. Other projection classes stay native.
lwz r11, 76(r5)
lis r12, 0x1034
addi r12, r12, 0x7B00
cmpw r11, r12
bne mrCullBuildInvalid
lis r12, rrCameraEnabled@ha
lwz r11, rrCameraEnabled@l(r12)
cmpwi r11, 1
bne mrCullBuildInvalid
lis r12, rrSlot@ha
lwz r11, rrSlot@l(r12)
mulli r11, r11, 196
lis r12, rrPoseLatch0@ha
addi r12, r12, rrPoseLatch0@l
add r12, r12, r11
lwz r11, 0(r12)
cmpwi r11, 0
beq mrCullBuildInvalid
stw r12, 24(r1)
lis r8, mrCullCount@ha
lwz r10, mrCullCount@l(r8)
lis r6, mrCullEntries@ha
addi r6, r6, mrCullEntries@l
lwz r3, 8(r1)
li r7, 0
mrCullFindBuild:
cmpw r7, r10
beq mrCullNewEntry
lwz r11, 0(r6)
cmpw r11, r3
beq mrCullEntryReady
addi r6, r6, 312
addi r7, r7, 1
b mrCullFindBuild
mrCullNewEntry:
cmpwi r10, 8
bge mrCullBuildOverflow
addi r10, r10, 1
stw r10, mrCullCount@l(r8)
mrCullEntryReady:
stw r3, 0(r6)
lis r8, mrCullEpoch@ha
lwz r11, mrCullEpoch@l(r8)
stw r11, 4(r6)
lwz r3, 12(r1)
stw r3, 8(r6)
lwz r11, 0(r12)
stw r11, 12(r6)
addi r6, r6, 16
li r10, 0
mrCullBuildEye:
lwz r3, 12(r1)
lwz r12, 24(r1)
mulli r11, r10, 48
addi r12, r12, 4
add r12, r12, r11
mr r9, r6
lis r8, mrCullOne@ha
lfs f3, mrCullOne@l(r8)
lfs f1, 0(r12)
lfs f2, 0(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r12)
lfs f2, 16(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 32(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 0(r9)
lfs f1, 0(r12)
lfs f2, 4(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r12)
lfs f2, 20(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 36(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 4(r9)
lfs f1, 0(r12)
lfs f2, 8(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r12)
lfs f2, 24(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 40(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 8(r9)
lfs f1, 0(r12)
lfs f2, 12(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r12)
lfs f2, 28(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 44(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f4, 0(r8)
lfs f5, 8(r8)
lfs f1, 0(r9)
lfs f2, 8(r9)
fmuls f0, f1, f4
fmuls f6, f2, f5
fsubs f0, f0, f6
fmuls f7, f1, f5
fmuls f8, f2, f4
fadds f7, f7, f8
stfs f0, 0(r9)
stfs f7, 8(r9)
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f1, 0(r9)
lfs f2, 0(r8)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 4(r9)
lfs f2, 4(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r9)
lfs f2, 8(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
.int 0xFC000050 ; fneg f0, f0
lfs f1, 12(r12)
fadds f0, f0, f1
stfs f0, 12(r9)
lfs f1, 16(r12)
lfs f2, 0(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r12)
lfs f2, 16(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 32(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 16(r9)
lfs f1, 16(r12)
lfs f2, 4(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r12)
lfs f2, 20(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 36(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 20(r9)
lfs f1, 16(r12)
lfs f2, 8(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r12)
lfs f2, 24(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 40(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 24(r9)
lfs f1, 16(r12)
lfs f2, 12(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r12)
lfs f2, 28(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 44(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f4, 0(r8)
lfs f5, 8(r8)
lfs f1, 16(r9)
lfs f2, 24(r9)
fmuls f0, f1, f4
fmuls f6, f2, f5
fsubs f0, f0, f6
fmuls f7, f1, f5
fmuls f8, f2, f4
fadds f7, f7, f8
stfs f0, 16(r9)
stfs f7, 24(r9)
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f1, 16(r9)
lfs f2, 0(r8)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 20(r9)
lfs f2, 4(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r9)
lfs f2, 8(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
.int 0xFC000050 ; fneg f0, f0
lfs f1, 28(r12)
fadds f0, f0, f1
stfs f0, 28(r9)
lfs f1, 32(r12)
lfs f2, 0(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r12)
lfs f2, 16(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 32(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 32(r9)
lfs f1, 32(r12)
lfs f2, 4(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r12)
lfs f2, 20(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 36(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 36(r9)
lfs f1, 32(r12)
lfs f2, 8(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r12)
lfs f2, 24(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 40(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 40(r9)
lfs f1, 32(r12)
lfs f2, 12(r3)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r12)
lfs f2, 28(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 44(r3)
fmuls f1, f1, f2
fadds f0, f0, f1
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f4, 0(r8)
lfs f5, 8(r8)
lfs f1, 32(r9)
lfs f2, 40(r9)
fmuls f0, f1, f4
fmuls f6, f2, f5
fsubs f0, f0, f6
fmuls f7, f1, f5
fmuls f8, f2, f4
fadds f7, f7, f8
stfs f0, 32(r9)
stfs f7, 40(r9)
lis r8, mrEyeTarget@ha
addi r8, r8, mrEyeTarget@l
lfs f1, 32(r9)
lfs f2, 0(r8)
fmuls f1, f1, f2
fmuls f0, f1, f3
lfs f1, 36(r9)
lfs f2, 4(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r9)
lfs f2, 8(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
.int 0xFC000050 ; fneg f0, f0
lfs f1, 44(r12)
fadds f0, f0, f1
stfs f0, 44(r9)

; Clip inequalities: w +/- x and w +/- y, including off-axis offsets.
lwz r12, 24(r1)
mulli r11, r10, 32
addi r12, r12, 116
add r12, r12, r11
lfs f7, 0(r12)
lfs f8, 4(r12)
lis r8, mrCullOne@ha
lfs f9, mrCullOne@l(r8)
fsubs f8, f8, f9
lfs f0, 0(r6)
lfs f1, 32(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 48(r6)
.int 0xFC000210 ; fabs f0, f0
.int 0xFD400090 ; fmr f10, f0
lfs f0, 4(r6)
lfs f1, 36(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 52(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 8(r6)
lfs f1, 40(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 56(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 12(r6)
lfs f1, 44(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 60(r6)
stfs f10, 64(r6)
lfs f7, 0(r12)
lfs f8, 4(r12)
.int 0xFCE03850 ; fneg f7, f7
.int 0xFD004050 ; fneg f8, f8
lis r8, mrCullOne@ha
lfs f9, mrCullOne@l(r8)
fsubs f8, f8, f9
lfs f0, 0(r6)
lfs f1, 32(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 68(r6)
.int 0xFC000210 ; fabs f0, f0
.int 0xFD400090 ; fmr f10, f0
lfs f0, 4(r6)
lfs f1, 36(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 72(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 8(r6)
lfs f1, 40(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 76(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 12(r6)
lfs f1, 44(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 80(r6)
stfs f10, 84(r6)
lfs f7, 8(r12)
lfs f8, 12(r12)
lis r8, mrCullOne@ha
lfs f9, mrCullOne@l(r8)
fsubs f8, f8, f9
lfs f0, 16(r6)
lfs f1, 32(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 88(r6)
.int 0xFC000210 ; fabs f0, f0
.int 0xFD400090 ; fmr f10, f0
lfs f0, 20(r6)
lfs f1, 36(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 92(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 24(r6)
lfs f1, 40(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 96(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 28(r6)
lfs f1, 44(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 100(r6)
stfs f10, 104(r6)
lfs f7, 8(r12)
lfs f8, 12(r12)
.int 0xFCE03850 ; fneg f7, f7
.int 0xFD004050 ; fneg f8, f8
lis r8, mrCullOne@ha
lfs f9, mrCullOne@l(r8)
fsubs f8, f8, f9
lfs f0, 16(r6)
lfs f1, 32(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 108(r6)
.int 0xFC000210 ; fabs f0, f0
.int 0xFD400090 ; fmr f10, f0
lfs f0, 20(r6)
lfs f1, 36(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 112(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 24(r6)
lfs f1, 40(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 116(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 28(r6)
lfs f1, 44(r6)
fmuls f0, f0, f7
fmuls f1, f1, f8
fadds f0, f0, f1
stfs f0, 120(r6)
stfs f10, 124(r6)
lfs f0, 32(r6)
.int 0xFC000050 ; fneg f0, f0
stfs f0, 128(r6)
.int 0xFC000210 ; fabs f0, f0
.int 0xFD400090 ; fmr f10, f0
lfs f0, 36(r6)
.int 0xFC000050 ; fneg f0, f0
stfs f0, 132(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 40(r6)
.int 0xFC000050 ; fneg f0, f0
stfs f0, 136(r6)
.int 0xFC000210 ; fabs f0, f0
fadds f10, f10, f0
lfs f0, 44(r6)
.int 0xFC000050 ; fneg f0, f0
stfs f0, 140(r6)
stfs f10, 144(r6)
addi r6, r6, 148
addi r10, r10, 1
cmpwi r10, 2
blt mrCullBuildEye
lis r12, mrCullBuilds@ha
lwz r11, mrCullBuilds@l(r12)
addi r11, r11, 1
stw r11, mrCullBuilds@l(r12)
b mrCullBuildExit
mrCullBuildOverflow:
lis r12, mrCullOverflow@ha
lwz r11, mrCullOverflow@l(r12)
addi r11, r11, 1
stw r11, mrCullOverflow@l(r12)
b mrCullBuildExit
mrCullBuildInvalid:
lis r12, mrCullInvalid@ha
lwz r11, mrCullInvalid@l(r12)
addi r11, r11, 1
stw r11, mrCullInvalid@l(r12)
mrCullBuildExit:
lwz r3, 20(r1)
lwz r0, 0x44(r1)
mtlr r0
addi r1, r1, 0x40
blr

mrCullTestOriginal:
stwu r1, -0x48(r1)
b mrCullTestContinue
mrCullTest:
stwu r1, -0x40(r1)
mflr r0
stw r0, 0x44(r1)
stw r3, 8(r1)
stw r4, 12(r1)
stfd f1, 16(r1)
stfd f2, 24(r1)
stfd f3, 32(r1)
bl mrCullTestOriginal
cmpwi r3, 0
beq mrCullTryEyes
lis r12, mrCullNativeVisible@ha
lwz r11, mrCullNativeVisible@l(r12)
addi r11, r11, 1
stw r11, mrCullNativeVisible@l(r12)
b mrCullTestExit
mrCullTryEyes:
lis r12, mrCullTests@ha
lwz r11, mrCullTests@l(r12)
addi r11, r11, 1
stw r11, mrCullTests@l(r12)
lis r12, mrCullCount@ha
lwz r10, mrCullCount@l(r12)
lis r6, mrCullEntries@ha
addi r6, r6, mrCullEntries@l
lwz r8, 8(r1)
li r7, 0
mrCullFindTest:
cmpw r7, r10
beq mrCullTestExit
lwz r11, 0(r6)
cmpw r11, r8
beq mrCullTestEntry
addi r6, r6, 312
addi r7, r7, 1
b mrCullFindTest
mrCullTestEntry:
lfd f1, 16(r1)
lfd f2, 24(r1)
lfd f3, 32(r1)
lwz r4, 12(r1)
lfs f4, 0(r4)
lfs f5, 4(r4)
lfs f6, 8(r4)
addi r6, r6, 64
li r7, 0
mrCullTestEye:
mr r8, r6
li r9, 0
mrCullTestPlane:
lfs f7, 0(r8)
lfs f8, 4(r8)
lfs f9, 8(r8)
lfs f10, 12(r8)
fmuls f7, f7, f4
fmuls f8, f8, f5
fmuls f9, f9, f6
fadds f7, f7, f8
fadds f7, f7, f9
fadds f7, f7, f10
lfs f8, 16(r8)
fmuls f8, f8, f1
cmpwi r9, 4
beq mrCullTestDepth
.int 0xFD004050 ; fneg f8, f8
.int 0xFC074000 ; fcmpu cr0, f7, f8
blt mrCullNextEye
addi r8, r8, 20
addi r9, r9, 1
b mrCullTestPlane
mrCullTestDepth:
fsubs f9, f2, f8
.int 0xFC074800 ; fcmpu cr0, f7, f9
blt mrCullNextEye
lis r12, mrCullZero@ha
lfs f10, mrCullZero@l(r12)
.int 0xFC035000 ; fcmpu cr0, f3, f10
ble mrCullVisible
fadds f9, f3, f8
.int 0xFC074800 ; fcmpu cr0, f7, f9
bgt mrCullNextEye
mrCullVisible:
li r3, 1
lis r12, mrCullRescues@ha
lwz r11, mrCullRescues@l(r12)
addi r11, r11, 1
stw r11, mrCullRescues@l(r12)
b mrCullTestExit
mrCullNextEye:
addi r6, r6, 148
addi r7, r7, 1
cmpwi r7, 2
blt mrCullTestEye
li r3, 0
mrCullTestExit:
lwz r0, 0x44(r1)
mtlr r0
addi r1, r1, 0x40
blr
