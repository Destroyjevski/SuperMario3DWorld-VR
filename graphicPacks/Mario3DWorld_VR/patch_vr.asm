[Mario3DWorld_VR_R3_EU_v0_US_v1]
moduleMatches = 0xD2308838,0xBBAF1908
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
bl mtProjectionRestore
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
; Synthetic microphone input expires unless this calc validates the pose packet.
lis r12, mbState@ha
li r11, 0
stw r11, mbState@l(r12)
lis r12, tcPadReady@ha
stw r11, tcPadReady@l(r12)
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
bl mtProjectionRestore
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
; The controllers, copied under the same sequence guard as the pose.
lis r10, mtPad@ha
addi r10, r10, mtPad@l
lwz r11, 216(r8)
stw r11, 0(r10)
lwz r11, 220(r8)
stw r11, 4(r10)
lwz r11, 224(r8)
stw r11, 8(r10)
lwz r11, 228(r8)
stw r11, 12(r10)
lwz r11, 232(r8)
stw r11, 16(r10)
lwz r11, 236(r8)
stw r11, 20(r10)
lwz r11, 240(r8)
stw r11, 24(r10)
lwz r11, 244(r8)
stw r11, 28(r10)
lwz r11, 248(r8)
stw r11, 32(r10)
lwz r11, 252(r8)
stw r11, 36(r10)
lwz r11, 256(r8)
stw r11, 40(r10)
lwz r11, 260(r8)
stw r11, 44(r10)
lwz r11, 264(r8)
stw r11, 48(r10)
lwz r11, 268(r8)
stw r11, 52(r10)
lwz r11, 272(r8)
stw r11, 56(r10)
lwz r11, 276(r8)
stw r11, 60(r10)
lwz r11, 280(r8)
stw r11, 64(r10)
lwz r11, 284(r8)
stw r11, 68(r10)
lwz r11, 288(r8)
stw r11, 72(r10)
lwz r11, 292(r8)
stw r11, 76(r10)
lwz r11, 296(r8)
stw r11, 80(r10)
lwz r11, 300(r8)
stw r11, 84(r10)
lwz r11, 304(r8)
stw r11, 88(r10)
lwz r11, 308(r8)
stw r11, 92(r10)
lwz r11, 312(r8)
stw r11, 96(r10)
lwz r11, 316(r8)
stw r11, 100(r10)
lwz r11, 320(r8)
stw r11, 104(r10)
lwz r11, 324(r8)
stw r11, 108(r10)
lwz r11, 328(r8)
stw r11, 112(r10)
lwz r11, 332(r8)
stw r11, 116(r10)
lwz r11, 336(r8)
stw r11, 120(r10)
lwz r11, 340(r8)
stw r11, 124(r10)
lwz r11, 344(r8)
stw r11, 128(r10)
lwz r11, 348(r8)
stw r11, 132(r10)
lwz r11, 352(r8)
stw r11, 136(r10)
lwz r11, 356(r8)
stw r11, 140(r10)
lwz r11, 360(r8)
stw r11, 144(r10)
lwz r11, 364(r8)
stw r11, 148(r10)
lwz r11, 368(r8)
stw r11, 152(r10)
lwz r11, 372(r8)
stw r11, 156(r10)
.int 0x7C2004AC ; lwsync
lwz r11, 8(r8)
cmpw r7, r11
bne rrPoseLatchDone
stw r7, 0(r12)
; Accept the gesture only from this validated controller snapshot. Four calc
; frames without a new controller generation expire it (including host loss).
lis r9, mbState@ha
addi r9, r9, mbState@l
lwz r11, 0(r10)
cmpwi r11, 0
beq mbLatchDone
lwz r7, 4(r9)
cmpw r7, r11
beq mbRepeated
stw r11, 4(r9)
li r7, 0
b mbAgeReady
mbRepeated:
lwz r7, 8(r9)
cmpwi r7, 4
bge mbLatchDone
addi r7, r7, 1
mbAgeReady:
stw r7, 8(r9)
cmpwi r7, 4
bge mbLatchDone
lis r11, rrEnabled@ha
lwz r11, rrEnabled@l(r11)
cmpwi r11, 1
bne mbLatchDone
; No located-hand check: the host sends only this bit for an untracked hand,
; so microphone blowing also works with a gamepad and no controllers.
lwz r11, 140(r10)
andi. r11, r11, 0x40 ; kPadBlow, independent of VPAD buttons
beq mbLatchDone
li r11, 1
stw r11, 0(r9)
mbLatchDone:
li r11, 1
lis r9, tcPadReady@ha
stw r11, tcPadReady@l(r9)
rrPoseLatchDone:
; The camera switch off the right controller's stick click. This path never
; touches Cemu's input configuration, which is where the reported failures live.
lis r9, mtPad@ha
addi r9, r9, mtPad@l
lwz r7, 0(r9)
cmpwi r7, 0
beq mtPadDone
li r7, 0
lwz r10, 88(r9)
cmpwi r10, 0
beq mtPadStore
lwz r10, 140(r9)
li r11, 4
and r10, r10, r11
cmpwi r10, 0
beq mtPadStore
li r7, 1
mtPadStore:
lis r10, mtControl@ha
addi r10, r10, mtControl@l
lwz r11, 68(r10)
stw r7, 68(r10)
cmpwi r7, 0
beq mtPadDone
cmpw r7, r11
beq mtPadDone
; The same three states as the pad switch.
lwz r11, 0(r10)
li r7, 2
cmpwi r11, 0
beq mtPadFlip
li r7, 1
cmpwi r11, 2
beq mtPadFlip
li r7, 0
mtPadFlip:
stw r7, 0(r10)
lwz r7, 8(r10)
addi r7, r7, 1
stw r7, 8(r10)
lis r10, mrLookCos@ha
addi r10, r10, mrLookCos@l
lis r7, 0x3F80
stw r7, 0(r10)
li r7, 0
stw r7, 4(r10)
stw r7, 8(r10)
mtPadDone:
lis r8, mtControl@ha
addi r8, r8, mtControl@l
lis r11, rrSlot@ha
lwz r11, rrSlot@l(r11)
mulli r11, r11, 8
add r11, r11, r8
lwz r7, 0(r8)
stw r7, 32(r11)
lwz r7, 8(r8)
stw r7, 36(r11)
lis r11, rrDioramaDistance@ha
lis r7, 0x3F26
ori r7, r7, 0x6666
stw r7, rrDioramaDistance@l(r11)
lis r11, rrDioramaAdvance@ha
lis r7, 0x3EB3
ori r7, r7, 0x3333
stw r7, rrDioramaAdvance@l(r11)
lis r12, mrSceneClass@ha
li r11, 0
stw r11, mrSceneClass@l(r12)
lis r12, tsScene@ha
stw r11, tsScene@l(r12)
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
; Only live TitleScene presentation; other scenes retain VR.
lis r9, tsStats@ha
addi r9, r9, tsStats@l
lwz r11, 0(r9)
addi r11, r11, 1
stw r11, 0(r9)
lis r9, tsScene@ha
lwz r9, tsScene@l(r9)
lis r12, 0x1000
cmplw r9, r12
blt tsCameraContinue
lis r12, 0x5000
cmplw r9, r12
bge tsCameraContinue
andi. r12, r9, 3
bne tsCameraContinue
lwz r11, 0(r9)
lis r12, tsStats@ha
addi r12, r12, tsStats@l
stw r11, 8(r12)
lis r12, 0x1032
ori r12, r12, 0x8FEC
cmpw r11, r12
bne tsCameraContinue
; Native state getter 022E3F28 -> scene+4. Native query 02440DD0
; prefers pending state (+8) to current (+4), catching A before iris starts.
lwz r11, 4(r9)
lis r12, 0x1000
cmplw r11, r12
blt tsCheckWipe
lis r12, 0x5000
cmplw r11, r12
bge tsCheckWipe
andi. r12, r11, 3
bne tsCheckWipe
lwz r12, 8(r11)
cmpwi r12, 0
bne tsStateReady
lwz r12, 4(r11)
tsStateReady:
lis r11, tsStats@ha
addi r11, r11, tsStats@l
stw r12, 12(r11)
lis r11, 0x104E
ori r11, r11, 0x6228
cmpw r12, r11
beq tsUseSurface
lis r11, 0x104E
ori r11, r11, 0x622C
cmpw r12, r11
beq tsUseSurface
lis r11, 0x104E
ori r11, r11, 0x6230
cmpw r12, r11
beq tsUseSurface
lis r11, 0x104E
ori r11, r11, 0x6234
cmpw r12, r11
beq tsUseSurface
lis r11, 0x104E
ori r11, r11, 0x6238
cmpw r12, r11
beq tsUseSurface
lis r11, 0x104E
ori r11, r11, 0x623C
cmpw r12, r11
beq tsUseSurface
lis r11, 0x104E
ori r11, r11, 0x6244
cmpw r12, r11
beq tsUseSurface
tsCheckWipe:
; Exact TitleScene WipeCircle owner (constructor 022E2898/28A0).
; Native title code itself checks actor+4C at 022E35B8 and 022E3C0C.
lwz r11, 0xA4(r9)
lis r12, 0x1000
cmplw r11, r12
blt tsCameraContinue
lis r12, 0x5000
cmplw r11, r12
bge tsCameraContinue
andi. r12, r11, 3
bne tsCameraContinue
lwz r9, 0(r11)
lis r12, 0x1037
ori r12, r12, 0x3F14
cmpw r9, r12
bne tsCameraContinue
lbz r11, 0x4C(r11)
cmpwi r11, 0
beq tsCameraContinue
tsUseSurface:
lis r9, tsStats@ha
addi r9, r9, tsStats@l
lwz r11, 4(r9)
addi r11, r11, 1
stw r11, 4(r9)
b rrCameraExit
tsCameraContinue:
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
beq mtEyeSelected
addi r12, r12, 48
mtEyeSelected:
lis r8, mtControl@ha
addi r8, r8, mtControl@l
lis r11, rrSlot@ha
lwz r11, rrSlot@l(r11)
mulli r11, r11, 8
add r11, r11, r8
lwz r7, 32(r11)
stw r7, 28(r8)
lwz r7, 36(r11)
lwz r0, 12(r8)
cmpw r7, r0
beq mtAnchorReady
stw r7, 12(r8)
addi r11, r12, 48
cmpwi r10, 1
beq mtOtherEyeReady
addi r11, r12, -48
mtOtherEyeReady:
lfs f1, 12(r12)
lfs f2, 12(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 0(r12)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 28(r12)
lfs f2, 28(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 16(r12)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 44(r12)
lfs f2, 44(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 32(r12)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 16(r8)
lfs f1, 12(r12)
lfs f2, 12(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 4(r12)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 28(r12)
lfs f2, 28(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 20(r12)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 44(r12)
lfs f2, 44(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 36(r12)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 20(r8)
lfs f1, 12(r12)
lfs f2, 12(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 8(r12)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 28(r12)
lfs f2, 28(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 24(r12)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 44(r12)
lfs f2, 44(r11)
fadds f1, f1, f2
lfs f2, 48(r8)
fmuls f1, f1, f2
lfs f2, 40(r12)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 24(r8)
mtAnchorReady:
lwz r0, 28(r8)
cmpwi r0, 1
bne mtUseDiorama
lis r11, mrSceneClass@ha
lwz r11, mrSceneClass@l(r11)
lis r7, 0x1032
ori r7, r7, 0x86DC
cmpw r11, r7
bne mtUseDiorama
lwz r11, 580(r3)
lis r7, 0x1000
cmplw r11, r7
blt mtUseDiorama
lis r7, 0x5000
cmplw r11, r7
bge mtUseDiorama
andi. r0, r11, 3
bne mtUseDiorama
lwz r0, 0(r11)
lis r7, 0x1031
ori r7, r7, 0x9EF4
cmpw r0, r7
bne mtUseDiorama
lis r7, mrEyeTarget@ha
addi r7, r7, mrEyeTarget@l
lfs f0, 1976(r11)
stfs f0, 0(r7)
lfs f0, 1980(r11)
lfs f1, 12(r7)
fadds f0, f0, f1
stfs f0, 4(r7)
lfs f0, 1984(r11)
stfs f0, 8(r7)
stwu r1, -0x20(r1)
stw r5, 8(r1)
stw r6, 12(r1)
stw r9, 16(r1)
stw r10, 20(r1)
stw r12, 24(r1)
mr r7, r11
lis r10, mtHideModel@ha
addi r10, r10, mtHideModel@l
li r0, 0
stw r0, 16(r10)
lis r12, mtHideActor@ha
addi r12, r12, mtHideActor@l
stw r11, 0(r12)
lwz r7, 252(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawParts
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawParts
andi. r0, r7, 3
bne mtHideDrawParts
lwz r6, 24(r7)
cmplwi r6, 7
bgt mtHideDrawParts
lwz r7, 20(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawParts
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawParts
andi. r0, r7, 3
bne mtHideDrawParts
mulli r6, r6, 4
add r7, r7, r6
lwz r7, 0(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawParts
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawParts
andi. r0, r7, 3
bne mtHideDrawParts
mr r9, r7
lwz r7, 68(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawParts
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawParts
andi. r0, r7, 3
bne mtHideDrawParts
lwz r7, 0(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawParts
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawParts
andi. r0, r7, 3
bne mtHideDrawParts
lwz r7, 8(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawParts
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawParts
andi. r0, r7, 3
bne mtHideDrawParts
stw r7, 0(r10)
stw r7, 20(r10)
li r0, 1
stw r0, 16(r10)
lwz r7, 112(r9)
lis r11, 0x1000
cmplw r7, r11
blt mtHideCaptureStamp
lis r11, 0x5000
cmplw r7, r11
bge mtHideCaptureStamp
andi. r0, r7, 3
bne mtHideCaptureStamp
lwz r6, 8(r7)
cmplwi r6, 16
bgt mtHideCaptureStamp
cmpwi r6, 0
beq mtHideCaptureStamp
lwz r5, 12(r7)
lis r11, 0x1000
cmplw r5, r11
blt mtHideCaptureStamp
lis r11, 0x5000
cmplw r5, r11
bge mtHideCaptureStamp
andi. r0, r5, 3
bne mtHideCaptureStamp
li r9, 0
mtHideChildLoop:
add r7, r5, r9
lwz r7, 0(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideChildNext
lis r11, 0x5000
cmplw r7, r11
bge mtHideChildNext
andi. r0, r7, 3
bne mtHideChildNext
lwz r7, 0(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideChildNext
lis r11, 0x5000
cmplw r7, r11
bge mtHideChildNext
andi. r0, r7, 3
bne mtHideChildNext
lwz r7, 68(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideChildNext
lis r11, 0x5000
cmplw r7, r11
bge mtHideChildNext
andi. r0, r7, 3
bne mtHideChildNext
lwz r7, 0(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideChildNext
lis r11, 0x5000
cmplw r7, r11
bge mtHideChildNext
andi. r0, r7, 3
bne mtHideChildNext
lwz r7, 8(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideChildNext
lis r11, 0x5000
cmplw r7, r11
bge mtHideChildNext
andi. r0, r7, 3
bne mtHideChildNext
lwz r12, 16(r10)
mulli r0, r12, 4
add r12, r10, r0
stw r7, 20(r12)
lwz r12, 16(r10)
addi r12, r12, 1
stw r12, 16(r10)
mtHideChildNext:
addi r9, r9, 4
addi r6, r6, -1
cmpwi r6, 0
bgt mtHideChildLoop
mtHideCaptureStamp:
lwz r0, 12(r10)
stw r0, 4(r10)
mtHideDrawParts:
lis r7, mtHideActor@ha
addi r7, r7, mtHideActor@l
lwz r7, 0(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideCaptureDone
lis r11, 0x5000
cmplw r7, r11
bge mtHideCaptureDone
andi. r0, r7, 3
bne mtHideCaptureDone
lwz r7, 252(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideCaptureDone
lis r11, 0x5000
cmplw r7, r11
bge mtHideCaptureDone
andi. r0, r7, 3
bne mtHideCaptureDone
lwz r7, 172(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideCaptureDone
lis r11, 0x5000
cmplw r7, r11
bge mtHideCaptureDone
andi. r0, r7, 3
bne mtHideCaptureDone
mr r9, r7
li r6, 48
mtHideDrawLoop:
lwz r12, 16(r10)
cmplwi r12, 17
bge mtHideCaptureDone
add r5, r9, r6
lwz r7, 0(r5)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawNext
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawNext
andi. r0, r7, 3
bne mtHideDrawNext
lwz r7, 56(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawNext
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawNext
andi. r0, r7, 3
bne mtHideDrawNext
lwz r7, 724(r7)
lis r11, 0x1000
cmplw r7, r11
blt mtHideDrawNext
lis r11, 0x5000
cmplw r7, r11
bge mtHideDrawNext
andi. r0, r7, 3
bne mtHideDrawNext
mulli r5, r12, 4
add r5, r10, r5
stw r7, 20(r5)
addi r12, r12, 1
stw r12, 16(r10)
mtHideDrawNext:
addi r6, r6, 4
cmpwi r6, 80
blt mtHideDrawLoop
mtHideCaptureDone:
lwz r5, 8(r1)
lwz r6, 12(r1)
lwz r9, 16(r1)
lwz r10, 20(r1)
lwz r12, 24(r1)
addi r1, r1, 0x20
b mtPreparePose
mtUseDiorama:
; The middle camera is the diorama at half distance. Like first person it
; belongs to gameplay scenes; intro and world map stay the diorama.
lwz r0, 28(r8)
cmpwi r0, 2
bne mtUseDioramaZero
lis r11, mrSceneClass@ha
lwz r11, mrSceneClass@l(r11)
lis r7, 0x1032
ori r7, r7, 0x86DC
cmpw r11, r7
beq mtPreparePose
mtUseDioramaZero:
li r0, 0
stw r0, 28(r8)
mtPreparePose:
; Latch the validated FP mode alongside this camera's slot/eye.
lis r7, rrSlot@ha
lwz r7, rrSlot@l(r7)
mulli r7, r7, 2
add r7, r7, r10
mulli r7, r7, 4
lis r11, mtNearState@ha
addi r11, r11, mtNearState@l
add r11, r11, r7
lwz r0, 28(r8)
stw r0, 0(r11)
; Private per-call pose. Never change the shared pose mailbox or its stamp.
lis r11, mtPoseScratch@ha
addi r11, r11, mtPoseScratch@l
lwz r7, 0(r12)
stw r7, 0(r11)
lwz r7, 4(r12)
stw r7, 4(r11)
lwz r7, 8(r12)
stw r7, 8(r11)
lwz r7, 12(r12)
stw r7, 12(r11)
lwz r7, 16(r12)
stw r7, 16(r11)
lwz r7, 20(r12)
stw r7, 20(r11)
lwz r7, 24(r12)
stw r7, 24(r11)
lwz r7, 28(r12)
stw r7, 28(r11)
lwz r7, 32(r12)
stw r7, 32(r11)
lwz r7, 36(r12)
stw r7, 36(r11)
lwz r7, 40(r12)
stw r7, 40(r11)
lwz r7, 44(r12)
stw r7, 44(r11)
lwz r0, 28(r8)
cmpwi r0, 1
bne mtLevelDone
lfs f5, 20(r3)
lfs f6, 36(r3)
lfs f1, 4(r11)
lfs f2, 8(r11)
fmuls f0, f1, f5
fmuls f7, f2, f6
fsubs f0, f0, f7
fmuls f8, f1, f6
fmuls f9, f2, f5
fadds f8, f8, f9
stfs f0, 4(r11)
stfs f8, 8(r11)
lfs f1, 20(r11)
lfs f2, 24(r11)
fmuls f0, f1, f5
fmuls f7, f2, f6
fsubs f0, f0, f7
fmuls f8, f1, f6
fmuls f9, f2, f5
fadds f8, f8, f9
stfs f0, 20(r11)
stfs f8, 24(r11)
lfs f1, 36(r11)
lfs f2, 40(r11)
fmuls f0, f1, f5
fmuls f7, f2, f6
fsubs f0, f0, f7
fmuls f8, f1, f6
fmuls f9, f2, f5
fadds f8, f8, f9
stfs f0, 36(r11)
stfs f8, 40(r11)
mtLevelDone:
lfs f4, 56(r8)
lwz r0, 28(r8)
cmpwi r0, 1
bne mtScaleReady
lfs f4, 52(r8)
mtScaleReady:
lfs f0, 12(r12)
lfs f1, 0(r12)
lfs f2, 16(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 4(r12)
lfs f2, 20(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r12)
lfs f2, 24(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fmuls f0, f0, f4
stfs f0, 12(r11)
lfs f0, 28(r12)
lfs f1, 16(r12)
lfs f2, 16(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 20(r12)
lfs f2, 20(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r12)
lfs f2, 24(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fmuls f0, f0, f4
stfs f0, 28(r11)
lfs f0, 44(r12)
lfs f1, 32(r12)
lfs f2, 16(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 36(r12)
lfs f2, 20(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r12)
lfs f2, 24(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fmuls f0, f0, f4
stfs f0, 44(r11)
lis r7, mtPoseEye@ha
addi r7, r7, mtPoseEye@l
mulli r0, r10, 48
add r7, r7, r0
lwz r0, 0(r11)
stw r0, 0(r7)
lwz r0, 4(r11)
stw r0, 4(r7)
lwz r0, 8(r11)
stw r0, 8(r7)
lwz r0, 12(r11)
stw r0, 12(r7)
lwz r0, 16(r11)
stw r0, 16(r7)
lwz r0, 20(r11)
stw r0, 20(r7)
lwz r0, 24(r11)
stw r0, 24(r7)
lwz r0, 28(r11)
stw r0, 28(r7)
lwz r0, 32(r11)
stw r0, 32(r7)
lwz r0, 36(r11)
stw r0, 36(r7)
lwz r0, 40(r11)
stw r0, 40(r7)
lwz r0, 44(r11)
stw r0, 44(r7)
mr r12, r11
lwz r0, 28(r8)
cmpwi r0, 1
bne mtDioramaMath
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
b mtCameraStamp
mtDioramaMath:
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
lis r8, rrDioramaAdvance@ha
addi r8, r8, rrDioramaAdvance@l
lfs f6, 0(r8)
; Middle camera: A' = A + (1 - m) * D, the eye moves forward by what the kept
; distance loses.
lis r8, mtControl@ha
addi r8, r8, mtControl@l
lwz r8, 28(r8)
cmpwi r8, 2
bne mtMiddleAdvanceRender
lis r8, rrDioramaDistance@ha
addi r8, r8, rrDioramaDistance@l
lfs f1, 0(r8)
lis r8, mtMiddle@ha
addi r8, r8, mtMiddle@l
lfs f2, 4(r8)
fmuls f1, f1, f2
fadds f6, f6, f1
mtMiddleAdvanceRender:
fmuls f6, f6, f5
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
lfs f1, 8(r12)
fmuls f1, f1, f6
fadds f0, f0, f1
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
lfs f1, 24(r12)
fmuls f1, f1, f6
fadds f0, f0, f1
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
lfs f1, 40(r12)
fmuls f1, f1, f6
fadds f0, f0, f1
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
lis r8, rrDioramaDistance@ha
addi r8, r8, rrDioramaDistance@l
lfs f1, 0(r8)
; Middle camera: D' = m * D, the look-at distance of the camera fields.
lis r8, mtControl@ha
addi r8, r8, mtControl@l
lwz r8, 28(r8)
cmpwi r8, 2
bne mtMiddleDistance
lis r8, mtMiddle@ha
addi r8, r8, mtMiddle@l
lfs f2, 0(r8)
fmuls f1, f1, f2
mtMiddleDistance:
fmuls f5, f5, f1
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
mtCameraStamp:
; Publish the completed player view without changing camera/transport state.
stwu r1, -0x40(r1)
stw r0, 8(r1)
mflr r0
stw r0, 0x44(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 12(r1)
stw r3, 16(r1)
stw r4, 20(r1)
stw r5, 24(r1)
stw r6, 28(r1)
stw r7, 32(r1)
stw r8, 36(r1)
stw r11, 40(r1)
stw r12, 44(r1)
bl tcCameraCapture
bl hlCaptureView
lwz r3, 16(r1)
lwz r4, 20(r1)
lwz r5, 24(r1)
lwz r6, 28(r1)
lwz r7, 32(r1)
lwz r8, 36(r1)
lwz r11, 40(r1)
lwz r12, 44(r1)
lwz r0, 12(r1)
.int 0x7C0FF120 ; mtcrf 255, r0
lwz r0, 0x44(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0x40
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
lis r12, mtHideModel@ha
addi r12, r12, mtHideModel@l
lwz r11, 12(r12)
addi r11, r11, 1
stw r11, 12(r12)
mr r3, r31
lis r12, mrSceneClass@ha
addi r12, r12, mrSceneClass@l
li r11, 0
stw r11, 0(r12)
lis r12, tsScene@ha
stw r11, tsScene@l(r12)
lis r12, pfState@ha
addi r12, r12, pfState@l
stw r11, 8(r12)
stw r11, 24(r12)
lis r12, mrSceneClass@ha
addi r12, r12, mrSceneClass@l
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
; r11 is the validated child scene pointer at this insertion point.
lis r12, pfState@ha
addi r12, r12, pfState@l
li r0, 0
stw r0, 8(r12)
stw r11, 20(r12)
lwz r0, 0(r11)
lis r12, 0x1027
ori r12, r12, 0xF388
cmpw r0, r12
bne pfStateDone
lwz r0, 0x104(r11)
lis r12, pfState@ha
addi r12, r12, pfState@l
stw r0, 12(r12)
cmpwi r0, 9
blt pfStateDone
cmpwi r0, 12
bgt pfStateDone
cmpwi r0, 9
beq pfStateLower
cmpwi r0, 12
beq pfStateUpper
li r0, 2
b pfStateStore
pfStateLower:
li r0, 1
b pfStateStore
pfStateUpper:
li r0, 3
pfStateStore:
stw r0, 8(r12)
pfStateDone:
lis r12, mrSceneClass@ha
addi r12, r12, mrSceneClass@l
lis r12, tsScene@ha
stw r11, tsScene@l(r12)
lis r12, mrSceneClass@ha
addi r12, r12, mrSceneClass@l
lwz r11, 0(r11)
stw r11, 0(r12)
mrSceneDone:
lis r11, rrDioramaDistance@ha
lis r0, 0x3F26
ori r0, r0, 0x6666
stw r0, rrDioramaDistance@l(r11)
lis r11, rrDioramaAdvance@ha
lis r0, 0x3EB3
ori r0, r0, 0x3333
stw r0, rrDioramaAdvance@l(r11)
lwz r11, 0(r12)
lis r0, 0x1027
ori r0, r0, 0xF388
cmpw r11, r0
bne mrIntroFactorsDone
lis r11, rrDioramaDistance@ha
lis r0, 0x3EBD
ori r0, r0, 0x70A4
stw r0, rrDioramaDistance@l(r11)
lis r11, rrDioramaAdvance@ha
lis r0, 0x3F21
ori r0, r0, 0x47AE
stw r0, rrDioramaAdvance@l(r11)
mrIntroFactorsDone:
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
.int 5
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
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
bl tcInputUpdate
lwz r4, 8(r1)
lwz r6, 12(r1)
cmpwi r3, 0
ble mrLookInputDone
; Motion controls: the VR controllers are written into the pad state before
; anything else reads it. Nothing here depends on Cemu's input configuration.
lis r9, mtPad@ha
addi r9, r9, mtPad@l
lwz r11, 0(r9)
cmpwi r11, 0
beq mtMotionDone
lis r7, mtMotionData@ha
addi r7, r7, mtMotionData@l
li r5, 0
lis r6, 65535
ori r6, r6, 65535
lwz r11, 16(r9)
cmpwi r11, 0
beq mtMotionLeftDone
lwz r11, 68(r9)
li r12, 1
and r12, r11, r12
cmpwi r12, 0
beq mtMotionLeftDoneBit0
ori r5, r5, 8192
lis r12, 65535
ori r12, r12, 57343
and r6, r6, r12
mtMotionLeftDoneBit0:
li r12, 2
and r12, r11, r12
cmpwi r12, 0
beq mtMotionLeftDoneBit1
ori r5, r5, 4096
lis r12, 65535
ori r12, r12, 61439
and r6, r6, r12
mtMotionLeftDoneBit1:
li r12, 16
and r12, r11, r12
cmpwi r12, 0
beq mtMotionLeftDoneBit2
ori r5, r5, 128
lis r12, 65535
ori r12, r12, 65407
and r6, r6, r12
mtMotionLeftDoneBit2:
li r12, 32
and r12, r11, r12
cmpwi r12, 0
beq mtMotionLeftDoneBit3
ori r5, r5, 32
lis r12, 65535
ori r12, r12, 65503
and r6, r6, r12
mtMotionLeftDoneBit3:
li r12, 8
and r12, r11, r12
cmpwi r12, 0
beq mtMotionLeftDoneBit4
ori r5, r5, 8
lis r12, 65535
ori r12, r12, 65527
and r6, r6, r12
mtMotionLeftDoneBit4:
li r12, 4
and r12, r11, r12
cmpwi r12, 0
beq mtMotionLeftDoneBit5
ori r5, r5, 4
lis r12, 65535
ori r12, r12, 65531
and r6, r6, r12
mtMotionLeftDoneBit5:
mtMotionLeftDone:
lwz r11, 88(r9)
cmpwi r11, 0
beq mtMotionRightDone
lwz r11, 140(r9)
li r12, 1
and r12, r11, r12
cmpwi r12, 0
beq mtMotionRightDoneBit0
ori r5, r5, 32768
lis r12, 65535
ori r12, r12, 32767
and r6, r6, r12
mtMotionRightDoneBit0:
li r12, 2
and r12, r11, r12
cmpwi r12, 0
beq mtMotionRightDoneBit1
ori r5, r5, 8192
lis r12, 65535
ori r12, r12, 57343
and r6, r6, r12
mtMotionRightDoneBit1:
lis r12, tcButtons@ha
addi r12, r12, tcButtons@l
lwz r12, 8(r12)
cmpwi r12, 0
bne mtMotionRightDoneBit2
li r12, 16
and r12, r11, r12
cmpwi r12, 0
beq mtMotionRightDoneBit2
ori r5, r5, 16384
lis r12, 65535
ori r12, r12, 49151
and r6, r6, r12
mtMotionRightDoneBit2:
lis r12, tcButtons@ha
lwz r12, tcButtons@l(r12)
cmpwi r12, 0
bne mtMotionRightDoneBit3
li r12, 32
and r12, r11, r12
cmpwi r12, 0
beq mtMotionRightDoneBit3
ori r5, r5, 16
lis r12, 65535
ori r12, r12, 65519
and r6, r6, r12
mtMotionRightDoneBit3:
mtMotionRightDone:
li r8, 0
lwz r11, 16(r9)
cmpwi r11, 0
beq mtMotionLeftStick
lfs f4, 80(r9)
lfs f5, 84(r9)
fmuls f6, f4, f4
fmuls f7, f5, f5
fadds f6, f6, f7
lfs f0, 0(r7)
.int 0xFC060000 ; fcmpu cr0, f6, f0
blt mtMotionLeftStick
li r8, 1
mtMotionLeftStick:
li r10, 0
lwz r11, 88(r9)
cmpwi r11, 0
beq mtMotionRightStick
lfs f8, 152(r9)
lfs f9, 156(r9)
fmuls f6, f8, f8
fmuls f7, f9, f9
fadds f6, f6, f7
lfs f0, 0(r7)
.int 0xFC060000 ; fcmpu cr0, f6, f0
blt mtMotionRightStick
li r10, 1
mtMotionRightStick:
; Geste: linker Controller am Kopf schaltet das Steuerkreuz auf.
li r11, 0
lwz r12, 16(r9)
cmpwi r12, 0
beq mtMotionReach
lfs f10, 4(r9)
lfs f11, 32(r9)
fsubs f10, f10, f11
fmuls f12, f10, f10
lfs f10, 8(r9)
lfs f11, 48(r9)
fsubs f10, f10, f11
fmuls f10, f10, f10
fadds f12, f12, f10
lfs f10, 12(r9)
lfs f11, 64(r9)
fsubs f10, f10, f11
fmuls f10, f10, f10
fadds f12, f12, f10
lfs f0, 4(r7)
.int 0xFC0C0000 ; fcmpu cr0, f12, f0
bge mtMotionReach
li r11, 1
mtMotionReach:
cmpwi r11, 0
beq mtMotionGestureDone
lfs f10, 152(r9)
lfs f11, 156(r9)
lfs f0, 8(r7)
.int 0xFC0A0000 ; fcmpu cr0, f10, f0
ble mtMotionNoRight
ori r5, r5, 1024
lis r12, 65535
ori r12, r12, 64511
and r6, r6, r12
mtMotionNoRight:
lfs f0, 12(r7)
.int 0xFC0A0000 ; fcmpu cr0, f10, f0
bge mtMotionNoLeft
ori r5, r5, 2048
lis r12, 65535
ori r12, r12, 63487
and r6, r6, r12
mtMotionNoLeft:
lfs f0, 8(r7)
.int 0xFC0B0000 ; fcmpu cr0, f11, f0
ble mtMotionNoUp
ori r5, r5, 512
lis r12, 65535
ori r12, r12, 65023
and r6, r6, r12
mtMotionNoUp:
lfs f0, 12(r7)
.int 0xFC0B0000 ; fcmpu cr0, f11, f0
bge mtMotionNoDown
ori r5, r5, 256
lis r12, 65535
ori r12, r12, 65279
and r6, r6, r12
mtMotionNoDown:
li r10, 1
lfs f8, 16(r7)
lfs f9, 16(r7)
mtMotionGestureDone:
mr r0, r3
cmpwi r0, 16
blt mtMotionCount
li r0, 16
mtMotionCount:
mulli r0, r0, 0xAC
add r0, r0, r4
mr r11, r4
mtMotionNext:
cmpw r11, r0
bge mtMotionDone
lwz r12, 0(r11)
and r12, r12, r6
add r12, r12, r5
stw r12, 0(r11)
cmpwi r8, 0
beq mtMotionKeepLeft
stfs f4, 12(r11)
stfs f5, 16(r11)
mtMotionKeepLeft:
cmpwi r10, 0
beq mtMotionKeepRight
stfs f8, 20(r11)
stfs f9, 24(r11)
mtMotionKeepRight:
addi r11, r11, 0xAC
b mtMotionNext
mtMotionDone:
lis r8, mtControl@ha
addi r8, r8, mtControl@l
lwz r7, 0(r4)
; Two configurable combinations, either of which switches. The test asks for
; all bits of a mask, so one mask is a single button or a chord; a mask of
; zero is switched off.
li r5, 0
lwz r9, 60(r8)
cmpwi r9, 0
beq mtToggleAlt
and r12, r7, r9
cmpw r12, r9
bne mtToggleAlt
li r5, 1
b mtToggleState
mtToggleAlt:
lwz r9, 64(r8)
cmpwi r9, 0
beq mtToggleState
and r12, r7, r9
cmpw r12, r9
bne mtToggleState
li r5, 1
mtToggleState:
mr r7, r5
lwz r9, 4(r8)
stw r7, 4(r8)
cmpwi r7, 0
beq mtInputMode
cmpw r7, r9
beq mtInputMode
; Three camera states on the one switch: diorama (0) -> middle (2) ->
; first person (1) -> diorama. Every other reader asks for 1.
lwz r9, 0(r8)
li r7, 2
cmpwi r9, 0
beq mtStoreMode
li r7, 1
cmpwi r9, 2
beq mtStoreMode
li r7, 0
mtStoreMode:
stw r7, 0(r8)
lwz r7, 8(r8)
addi r7, r7, 1
stw r7, 8(r8)
lis r9, mrLookCos@ha
addi r9, r9, mrLookCos@l
lis r7, 0x3F80
stw r7, 0(r9)
li r7, 0
stw r7, 4(r9)
stw r7, 8(r9)
lis r9, hbmState@ha
addi r9, r9, hbmState@l
stw r7, 16(r9)
stw r7, 12(r9)
lis r7, 0x3F80
stw r7, 8(r9)
b mrLookInputDone
mtInputMode:
lwz r7, 0(r8)
cmpwi r7, 1
bne mrLookInputDone
; SceneClass is cleared before calc, including the input poll. Use the last
; actual camera selection, which survives that boundary and rejects fallback.
lwz r7, 28(r8)
cmpwi r7, 1
bne mrLookInputDone
lis r8, mrLookCos@ha
addi r8, r8, mrLookCos@l
lfs f1, 0x14(r4)
.int 0xFC400A10 ; fabs f2, f1
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
bl hbmCompose
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
; Only the copied projection changes. Native source and far plane stay intact.
lis r11, rrSlot@ha
lwz r0, rrSlot@l(r11)
mulli r0, r0, 2
lis r11, rrEye@ha
lwz r12, rrEye@l(r11)
add r0, r0, r12
mulli r0, r0, 4
lis r11, mtNearState@ha
addi r11, r11, mtNearState@l
add r12, r11, r0
lwz r0, 0(r12)
cmpwi r0, 1
bne mtNearDone
lwz r0, 16(r11)
stw r0, 148(r10)

mtNearDone:
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
; View struct override (1/3): never copy from a copy. If the struct still
; hands us one of our own copies, take the remembered native object.
lis r12, rrProjectionCopies@ha
addi r12, r12, rrProjectionCopies@l
cmplw r16, r12
blt mtProjNativeKnown
addi r11, r12, 736
cmplw r16, r11
bge mtProjNativeKnown
lis r11, mtNativeProjection@ha
lwz r16, mtNativeProjection@l(r11)
cmpwi r16, 0
beq mrStereoRestore
mr r31, r16
mtProjNativeKnown:
lis r11, mtNativeProjection@ha
addi r11, r11, mtNativeProjection@l
stw r16, 0(r11)
; Same for the camera: r27 is the render function's camera, r3 goes to the
; camera hook as the source of the copy.
lis r12, rrCamera0@ha
addi r12, r12, rrCamera0@l
cmplw r27, r12
blt mtCamNativeKnown
addi r11, r12, 352
cmplw r27, r11
bge mtCamNativeKnown
lis r11, mtNativeCamera@ha
lwz r27, mtNativeCamera@l(r11)
cmpwi r27, 0
beq mrStereoRestore
mr r3, r27
mtCamNativeKnown:
lis r11, mtNativeCamera@ha
addi r11, r11, mtNativeCamera@l
stw r27, 0(r11)
bl rrCameraHook
mr r15, r3
li r21, 0
bl rrProjectionHook
cmpw r16, r31
beq mrStereoRestore
mr r27, r15
mr r31, r16
; View struct override (2/3): every reader of the struct sees this eye's
; copies from here on.
lwz r11, 4(r24)
lwz r11, 0x18(r11)
lis r12, mtProjectionField@ha
addi r12, r12, mtProjectionField@l
stw r11, 0(r12)
stw r16, 0xC(r11)
stw r15, 4(r11)
lwz r11, 4(r12)
addi r11, r11, 1
stw r11, 4(r12)
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
lis r12, mtPoseEye@ha
addi r12, r12, mtPoseEye@l
mulli r11, r10, 48
add r12, r12, r11
mr r9, r6
lis r8, mrCullOne@ha
lfs f3, mrCullOne@l(r8)
lis r11, mtControl@ha
addi r11, r11, mtControl@l
lwz r11, 28(r11)
cmpwi r11, 1
bne mtCullDiorama
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
b mtCullComposed
mtCullDiorama:
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
lis r8, rrDioramaAdvance@ha
addi r8, r8, rrDioramaAdvance@l
lfs f6, 0(r8)
; Middle camera: A' = A + (1 - m) * D, the eye moves forward by what the kept
; distance loses.
lis r8, mtControl@ha
addi r8, r8, mtControl@l
lwz r8, 28(r8)
cmpwi r8, 2
bne mtMiddleAdvanceCull
lis r8, rrDioramaDistance@ha
addi r8, r8, rrDioramaDistance@l
lfs f1, 0(r8)
lis r8, mtMiddle@ha
addi r8, r8, mtMiddle@l
lfs f2, 4(r8)
fmuls f1, f1, f2
fadds f6, f6, f1
mtMiddleAdvanceCull:
fmuls f6, f6, f5
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
lfs f1, 8(r12)
fmuls f1, f1, f6
fadds f0, f0, f1
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
lfs f1, 24(r12)
fmuls f1, f1, f6
fadds f0, f0, f1
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
lfs f1, 40(r12)
fmuls f1, f1, f6
fadds f0, f0, f1
lfs f1, 44(r12)
fadds f0, f0, f1
stfs f0, 44(r9)
mtCullComposed:

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
lis r12, pfPipeState@ha
addi r12, r12, pfPipeState@l
lwz r11, 0(r12)
cmpwi r11, 0
beq pfPipeRescueAllowed
lwz r11, 8(r12)
addi r11, r11, 1
stw r11, 8(r12)
b mrCullTestExit
pfPipeRescueAllowed:
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

rrDioramaDistance:
.int 0x3F266666
rrDioramaAdvance:
.int 0x3EB33333
; mode, previous switch state, generation, anchored generation, centre xyz,
; effective mode, slot0 mode/generation, slot1 mode/generation, -0.5, 0.1, 1,
; the two switch combinations the player can choose in Cemu, and last the
; previous state of the controller switch, which has its own edge.
mtControl:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0xBF000000
.int 0x3DCCCCCD
.int 0x3F800000
.int $switchMain
.int $switchAlt
.int 0
mtPoseScratch:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
mtPoseEye:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0

; First-person player visibility: render-only, original predicate in diorama.
0x024E775C = mtHideNativeResume:
mtHideShape:
stwu r1, -0x20(r1)
stw r0, 8(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 12(r1)
stw r7, 16(r1)
stw r8, 20(r1)
stw r12, 24(r1)
mflr r7
stw r7, 28(r1)
bl pfGate
lwz r7, 28(r1)
mtlr r7
cmpwi r3, 0
bne pfGatePassed
lwz r7, 16(r1)
lwz r8, 20(r1)
lwz r12, 24(r1)
lwz r0, 12(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 8(r1)
addi r1, r1, 0x20
blr
pfGatePassed:
lis r7, mtControl@ha
addi r7, r7, mtControl@l
lwz r0, 0(r7)
cmpwi r0, 1
bne mtHidePass
; Require the effective FP mode of this exact copied camera/eye as well.
lis r7, rrSlot@ha
lwz r0, rrSlot@l(r7)
mulli r0, r0, 2
lis r7, rrEye@ha
lwz r12, rrEye@l(r7)
add r0, r0, r12
mulli r0, r0, 4
lis r7, mtNearState@ha
addi r7, r7, mtNearState@l
add r7, r7, r0
lwz r0, 0(r7)
cmpwi r0, 1
bne mtHidePass
lis r8, mtHideModel@ha
addi r8, r8, mtHideModel@l
; Reject an identity older than two scene calculation ticks, including
; across level changes. Unsigned subtraction also handles epoch wraparound.
lwz r12, 12(r8)
lwz r0, 4(r8)
subf r12, r0, r12
cmplwi r12, 2
bgt mtHidePass
lwz r12, 16(r8)
cmplwi r12, 17
bgt mtHidePass
cmpwi r12, 0
beq mtHidePass
addi r7, r8, 20
mtHideCompare:
lwz r0, 0(r7)
cmpw r3, r0
beq mtHideMatched
addi r7, r7, 4
addi r12, r12, -1
cmpwi r12, 0
bgt mtHideCompare
b mtHidePass
mtHideMatched:
lwz r12, 8(r8)
addi r12, r12, 1
stw r12, 8(r8)
lwz r7, 16(r1)
lwz r8, 20(r1)
lwz r12, 24(r1)
lwz r0, 12(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 8(r1)
addi r1, r1, 0x20
li r3, 0
blr
mtHidePass:
lwz r7, 16(r1)
lwz r8, 20(r1)
lwz r12, 24(r1)
lwz r0, 12(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 8(r1)
addi r1, r1, 0x20
lwz r11, 0(r3)
b mtHideNativeResume
0x024E7758 = ba mtHideShape
mtHideModel:
.int 0 ; runtime model pointer
.int 0 ; most recent validated camera scene epoch
.int 0 ; suppressed shape-query count (private diagnostics)
.int 0 ; scene calculation epoch
.int 0 ; captured model count
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
mtHideActor:
.int 0

mtNearState:
.int 0
.int 0
.int 0
.int 0
.int 0x41200000
.int 0x00000000

mtPad:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0

mtMotionData:
.int 0x3CB851EC
.int 0x4845C100
.int 0x3F000000
.int 0xBF000000
.int 0x00000000

mtMiddle:
.int 0x3F000000
.int 0x3F000000

; Depth of field off: take the branch the game takes when its own switch is
; clear, so the pass is never entered and r8 keeps the previous target.
0x024AD714 = mtDofSkip:
0x024AD708 = b mtDofSkip

; Glare off: take the branch the game takes when the flare filter's own switch
; is clear, so the effect is never entered and r30 keeps the current target.
0x022D874C = mtGlareSkip:
0x022D86B8 = b mtGlareSkip

; Light shafts off: take the branch the game takes when the god ray reports
; nothing to do, so the effect is never entered and r30 keeps the target.
0x022D8690 = mtGodRaySkip:
0x022D85CC = b mtGodRaySkip

; View struct override (3/3): the native objects go back before the game's
; own logic runs. Reached from rrBeforeCalc and rrSecondDraw with LR saved.
mtProjectionRestore:
lis r12, mtProjectionField@ha
addi r12, r12, mtProjectionField@l
lwz r11, 0(r12)
cmpwi r11, 0
beqlr
lwz r0, 0xC(r11)
lis r12, rrProjectionCopies@ha
addi r12, r12, rrProjectionCopies@l
cmplw r0, r12
blt mtProjectionRestoreCamera
addi r12, r12, 736
cmplw r0, r12
bge mtProjectionRestoreCamera
lis r12, mtNativeProjection@ha
lwz r12, mtNativeProjection@l(r12)
cmpwi r12, 0
beq mtProjectionRestoreCamera
stw r12, 0xC(r11)
mtProjectionRestoreCamera:
lwz r0, 4(r11)
lis r12, rrCamera0@ha
addi r12, r12, rrCamera0@l
cmplw r0, r12
blt mtProjectionRestoreDone
addi r12, r12, 352
cmplw r0, r12
bge mtProjectionRestoreDone
lis r12, mtNativeCamera@ha
lwz r12, mtNativeCamera@l(r12)
cmpwi r12, 0
beq mtProjectionRestoreDone
stw r12, 4(r11)
mtProjectionRestoreDone:
blr

; struct, writes; the native camera and projection last seen there.
mtProjectionField:
.int 0
.int 0
mtNativeCamera:
.int 0
mtNativeProjection:
.int 0

; Head-based movement: FP gameplay only, shared by both input sources.
hbmCompose:
lis r12, hbmState@ha
addi r12, r12, hbmState@l
lis r10, rrSlot@ha
lwz r10, rrSlot@l(r10)
cmpwi r10, 1
bgt hbmCached
mulli r10, r10, 196
lis r9, rrPoseLatch0@ha
addi r9, r9, rrPoseLatch0@l
add r10, r10, r9
lwz r11, 0(r10)
cmpwi r11, 0
beq hbmCached
lwz r9, 16(r12)
cmpw r11, r9
beq hbmCached
; Inverse eye rotation row 2 is the head forward axis in anchor space.
; Translation, pitch magnitude and roll do not steer the horizontal stick.
lfs f6, 44(r10)
lfs f7, 36(r10)
fneg f7, f7
fmuls f9, f6, f6
fmuls f10, f7, f7
fadds f9, f9, f10
lfs f13, 36(r12)
.int 0xFC096800 ; fcmpu cr0,f9,f13
blt hbmCached
lfs f13, 40(r12)
.int 0xFC096800 ; fcmpu cr0,f9,f13
bgt hbmCached
; Reject NaN by checking each source word, rather than float comparisons.
lwz r0, 44(r10)
rlwinm r0, r0, 0, 1, 31
lis r9, 0x3F82
cmplw r0, r9
bgt hbmCached
lwz r0, 36(r10)
rlwinm r0, r0, 0, 1, 31
cmplw r0, r9
bgt hbmCached
lfs f10, 20(r12)
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f6, f6, f10
fmuls f7, f7, f10
lwz r9, 16(r12)
stw r11, 16(r12)
cmpwi r9, 0
beq hbmStoreRaw
; Smooth the unnormalised vector; never feed its normalisation back.
; This also allows an exact 180-degree reversal to cross through zero.
lfs f8, 0(r12)
lfs f9, 4(r12)
lfs f10, 32(r12)
fsubs f6, f6, f8
fsubs f7, f7, f9
fmuls f6, f6, f10
fmuls f7, f7, f10
fadds f6, f6, f8
fadds f7, f7, f9
hbmStoreRaw:
stfs f6, 0(r12)
stfs f7, 4(r12)
fmuls f9, f6, f6
fmuls f10, f7, f7
fadds f9, f9, f10
lfs f13, 36(r12)
.int 0xFC096800 ; fcmpu cr0,f9,f13
blt hbmCached
lfs f10, 20(r12)
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f11, f10, f10
fmuls f11, f11, f9
lfs f13, 24(r12)
fmuls f11, f11, f13
lfs f13, 28(r12)
fsubs f11, f13, f11
fmuls f10, f10, f11
fmuls f6, f6, f10
fmuls f7, f7, f10
stfs f6, 8(r12)
stfs f7, 12(r12)
hbmCached:
lfs f6, 8(r12)
lfs f7, 12(r12)
; Compose with the existing stick yaw, leaving the view itself untouched.
fmuls f8, f4, f6
fmuls f9, f5, f7
fsubs f8, f8, f9
fmuls f9, f5, f6
fmuls f10, f4, f7
fadds f5, f9, f10
fmr f4, f8
blr
hbmState:
.int 0x3F800000
.int 0x00000000
.int 0x3F800000
.int 0x00000000
.int 0x00000000
.int 0x3F800000
.int 0x3F000000
.int 0x3FC00000
.int 0x3F000000
.int 0x3D23D70A
.int 0x40066666

tsScene:
.int 0
tsStats:
.int 0
.int 0
.int 0
.int 0

pfGate:
stwu r1, -0x40(r1)
stw r4, 8(r1)
stw r5, 12(r1)
stw r6, 16(r1)
stw r7, 20(r1)
stw r8, 24(r1)
stw r9, 28(r1)
stw r10, 32(r1)
stw r11, 36(r1)
stw r12, 40(r1)
lis r12, pfState@ha
addi r12, r12, pfState@l
li r0, 0
stw r0, 24(r12)
lis r9, mrSceneClass@ha
lwz r9, mrSceneClass@l(r9)
lis r8, 0x1027
ori r8, r8, 0xF388
cmpw r9, r8
bne pfW2RoomPass
lwz r9, 12(r12)
cmpwi r9, 1
beq pfW2RoomName
cmpwi r9, 2
bne pfW2RoomPass
pfW2RoomName:
lbz r0, 36(r3)
cmpwi r0, 79
bne pfW2RoomWater
lbz r0, 37(r3)
cmpwi r0, 98
bne pfW2RoomWater
lbz r0, 38(r3)
cmpwi r0, 106
bne pfW2RoomWater
lbz r0, 39(r3)
cmpwi r0, 101
bne pfW2RoomWater
lbz r0, 40(r3)
cmpwi r0, 99
bne pfW2RoomWater
lbz r0, 41(r3)
cmpwi r0, 116
bne pfW2RoomWater
lbz r0, 42(r3)
cmpwi r0, 68
bne pfW2RoomWater
lbz r0, 43(r3)
cmpwi r0, 97
bne pfW2RoomWater
lbz r0, 44(r3)
cmpwi r0, 116
bne pfW2RoomWater
lbz r0, 45(r3)
cmpwi r0, 97
bne pfW2RoomWater
lbz r0, 46(r3)
cmpwi r0, 47
bne pfW2RoomWater
lbz r0, 47(r3)
cmpwi r0, 67
bne pfW2RoomWater
lbz r0, 48(r3)
cmpwi r0, 111
bne pfW2RoomWater
lbz r0, 49(r3)
cmpwi r0, 117
bne pfW2RoomWater
lbz r0, 50(r3)
cmpwi r0, 114
bne pfW2RoomWater
lbz r0, 51(r3)
cmpwi r0, 115
bne pfW2RoomWater
lbz r0, 52(r3)
cmpwi r0, 101
bne pfW2RoomWater
lbz r0, 53(r3)
cmpwi r0, 83
bne pfW2RoomWater
lbz r0, 54(r3)
cmpwi r0, 101
bne pfW2RoomWater
lbz r0, 55(r3)
cmpwi r0, 108
bne pfW2RoomWater
lbz r0, 56(r3)
cmpwi r0, 101
bne pfW2RoomWater
lbz r0, 57(r3)
cmpwi r0, 99
bne pfW2RoomWater
lbz r0, 58(r3)
cmpwi r0, 116
bne pfW2RoomWater
lbz r0, 59(r3)
cmpwi r0, 85
bne pfW2RoomWater
lbz r0, 60(r3)
cmpwi r0, 110
bne pfW2RoomWater
lbz r0, 61(r3)
cmpwi r0, 100
bne pfW2RoomWater
lbz r0, 62(r3)
cmpwi r0, 101
bne pfW2RoomWater
lbz r0, 63(r3)
cmpwi r0, 114
bne pfW2RoomWater
lbz r0, 64(r3)
cmpwi r0, 71
bne pfW2RoomWater
lbz r0, 65(r3)
cmpwi r0, 114
bne pfW2RoomWater
lbz r0, 66(r3)
cmpwi r0, 111
bne pfW2RoomWater
lbz r0, 67(r3)
cmpwi r0, 117
bne pfW2RoomWater
lbz r0, 68(r3)
cmpwi r0, 110
bne pfW2RoomWater
lbz r0, 69(r3)
cmpwi r0, 100
bne pfW2RoomWater
lbz r0, 70(r3)
cmpwi r0, 65
bne pfW2RoomWater
lbz r0, 71(r3)
cmpwi r0, 0
bne pfW2RoomWater
b pfW2RoomPlayer
pfW2RoomWater:
lbz r0, 36(r3)
cmpwi r0, 79
bne pfW2RoomPass
lbz r0, 37(r3)
cmpwi r0, 98
bne pfW2RoomPass
lbz r0, 38(r3)
cmpwi r0, 106
bne pfW2RoomPass
lbz r0, 39(r3)
cmpwi r0, 101
bne pfW2RoomPass
lbz r0, 40(r3)
cmpwi r0, 99
bne pfW2RoomPass
lbz r0, 41(r3)
cmpwi r0, 116
bne pfW2RoomPass
lbz r0, 42(r3)
cmpwi r0, 68
bne pfW2RoomPass
lbz r0, 43(r3)
cmpwi r0, 97
bne pfW2RoomPass
lbz r0, 44(r3)
cmpwi r0, 116
bne pfW2RoomPass
lbz r0, 45(r3)
cmpwi r0, 97
bne pfW2RoomPass
lbz r0, 46(r3)
cmpwi r0, 47
bne pfW2RoomPass
lbz r0, 47(r3)
cmpwi r0, 67
bne pfW2RoomPass
lbz r0, 48(r3)
cmpwi r0, 111
bne pfW2RoomPass
lbz r0, 49(r3)
cmpwi r0, 117
bne pfW2RoomPass
lbz r0, 50(r3)
cmpwi r0, 114
bne pfW2RoomPass
lbz r0, 51(r3)
cmpwi r0, 115
bne pfW2RoomPass
lbz r0, 52(r3)
cmpwi r0, 101
bne pfW2RoomPass
lbz r0, 53(r3)
cmpwi r0, 83
bne pfW2RoomPass
lbz r0, 54(r3)
cmpwi r0, 101
bne pfW2RoomPass
lbz r0, 55(r3)
cmpwi r0, 108
bne pfW2RoomPass
lbz r0, 56(r3)
cmpwi r0, 101
bne pfW2RoomPass
lbz r0, 57(r3)
cmpwi r0, 99
bne pfW2RoomPass
lbz r0, 58(r3)
cmpwi r0, 116
bne pfW2RoomPass
lbz r0, 59(r3)
cmpwi r0, 87
bne pfW2RoomPass
lbz r0, 60(r3)
cmpwi r0, 97
bne pfW2RoomPass
lbz r0, 61(r3)
cmpwi r0, 118
bne pfW2RoomPass
lbz r0, 62(r3)
cmpwi r0, 101
bne pfW2RoomPass
lbz r0, 63(r3)
cmpwi r0, 85
bne pfW2RoomPass
lbz r0, 64(r3)
cmpwi r0, 110
bne pfW2RoomPass
lbz r0, 65(r3)
cmpwi r0, 100
bne pfW2RoomPass
lbz r0, 66(r3)
cmpwi r0, 101
bne pfW2RoomPass
lbz r0, 67(r3)
cmpwi r0, 114
bne pfW2RoomPass
lbz r0, 68(r3)
cmpwi r0, 71
bne pfW2RoomPass
lbz r0, 69(r3)
cmpwi r0, 114
bne pfW2RoomPass
lbz r0, 70(r3)
cmpwi r0, 111
bne pfW2RoomPass
lbz r0, 71(r3)
cmpwi r0, 117
bne pfW2RoomPass
lbz r0, 72(r3)
cmpwi r0, 110
bne pfW2RoomPass
lbz r0, 73(r3)
cmpwi r0, 100
bne pfW2RoomPass
lbz r0, 74(r3)
cmpwi r0, 0
bne pfW2RoomPass
pfW2RoomPlayer:
lwz r8, 20(r12)
cmpwi r8, 0
beq pfW2RoomHide
lwz r8, 0xF0(r8)
cmpwi r8, 0
beq pfW2RoomHide
lwz r8, 0x28(r8)
cmpwi r8, 0
beq pfW2RoomHide
lwz r11, 0(r8)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfW2RoomHide
lwz r11, 4(r8)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfW2RoomHide
lwz r11, 8(r8)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfW2RoomHide
lwz r11, 0(r8)
lis r0, 0x466A
ori r0, r0, 0x6000
cmplw r11, r0
blt pfW2RoomHide
lis r0, 0x4690
ori r0, r0, 0x8800
cmplw r11, r0
bgt pfW2RoomHide
lwz r11, 4(r8)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x45BB
ori r0, r0, 0x8000
cmplw r11, r0
bgt pfW2RoomHide
lwz r11, 8(r8)
cmpwi r11, 0
bge pfW2RoomHide
rlwinm r11, r11, 0, 1, 31
lis r0, 0x458C
ori r0, r0, 0xA000
cmplw r11, r0
blt pfW2RoomHide
lis r0, 0x4614
ori r0, r0, 0x7000
cmplw r11, r0
bgt pfW2RoomHide
b pfW2RoomPass
pfW2RoomHide:
li r3, 0
b pfGateDone
pfW2RoomPass:

lwz r0, 8(r12)
cmpwi r0, 0
beq pfWorldOneAttachments
lbz r0, 36(r3)
cmpwi r0, 79
bne pfOtherModel
lbz r0, 37(r3)
cmpwi r0, 98
bne pfOtherModel
lbz r0, 38(r3)
cmpwi r0, 106
bne pfOtherModel
lbz r0, 39(r3)
cmpwi r0, 101
bne pfOtherModel
lbz r0, 40(r3)
cmpwi r0, 99
bne pfOtherModel
lbz r0, 41(r3)
cmpwi r0, 116
bne pfOtherModel
lbz r0, 42(r3)
cmpwi r0, 68
bne pfOtherModel
lbz r0, 43(r3)
cmpwi r0, 97
bne pfOtherModel
lbz r0, 44(r3)
cmpwi r0, 116
bne pfOtherModel
lbz r0, 45(r3)
cmpwi r0, 97
bne pfOtherModel
lbz r0, 46(r3)
cmpwi r0, 47
bne pfOtherModel
lbz r0, 47(r3)
cmpwi r0, 67
bne pfOtherModel
lbz r0, 48(r3)
cmpwi r0, 111
bne pfOtherModel
lbz r0, 49(r3)
cmpwi r0, 117
bne pfOtherModel
lbz r0, 50(r3)
cmpwi r0, 114
bne pfOtherModel
lbz r0, 51(r3)
cmpwi r0, 115
bne pfOtherModel
lbz r0, 52(r3)
cmpwi r0, 101
bne pfOtherModel
lbz r0, 53(r3)
cmpwi r0, 83
bne pfOtherModel
lbz r0, 54(r3)
cmpwi r0, 101
bne pfOtherModel
lbz r0, 55(r3)
cmpwi r0, 108
bne pfOtherModel
lbz r0, 56(r3)
cmpwi r0, 101
bne pfOtherModel
lbz r0, 57(r3)
cmpwi r0, 99
bne pfOtherModel
lbz r0, 58(r3)
cmpwi r0, 116
bne pfOtherModel
lbz r0, 59(r3)
cmpwi r0, 87
bne pfOtherModel
lbz r0, 60(r3)
cmpwi r0, 83
bne pfOtherModel
lbz r0, 61(r3)
cmpwi r0, 0
bne pfOtherModel
cmplwi r4, 13
bgt pfGateDone
lwz r8, 0(r3)
lhz r0, 0x14(r8)
cmpwi r0, 14
bne pfGateDone
lwz r8, 0x1C(r8)
mulli r9, r4, 48
add r8, r8, r9
lwz r8, 0(r8)
lwz r0, 0(r8)
lis r9, 0x4653
ori r9, r9, 0x4850
cmpw r0, r9
bne pfGateDone
lhz r0, 12(r8)
cmpw r0, r4
bne pfGateDone
lwz r9, 0x24(r8)
cmpwi r9, 0
beq pfGateDone
addi r8, r8, 0x24
add r8, r8, r9
lwz r0, 0(r8)
cmpwi r0, 4
bne pfGateDone
lwz r0, 4(r8)
cmpwi r0, 4
bne pfGateDone
lwz r0, 0x18(r8)
cmpwi r0, 0
bne pfGateDone
lis r9, pfRanges@ha
addi r9, r9, pfRanges@l
mulli r10, r4, 72
add r9, r9, r10
lwz r0, 0(r9)
lwz r10, 8(r8)
cmpw r0, r10
bne pfGateDone
lwz r0, 4(r9)
lhz r10, 12(r8)
cmpw r0, r10
bne pfGateDone
stw r8, 24(r12)
stw r4, 28(r12)
b pfGateDone
pfOtherModel:
lbz r0, 36(r3)
cmpwi r0, 79
bne pfPrefix0Next
lbz r0, 37(r3)
cmpwi r0, 98
bne pfPrefix0Next
lbz r0, 38(r3)
cmpwi r0, 106
bne pfPrefix0Next
lbz r0, 39(r3)
cmpwi r0, 101
bne pfPrefix0Next
lbz r0, 40(r3)
cmpwi r0, 99
bne pfPrefix0Next
lbz r0, 41(r3)
cmpwi r0, 116
bne pfPrefix0Next
lbz r0, 42(r3)
cmpwi r0, 68
bne pfPrefix0Next
lbz r0, 43(r3)
cmpwi r0, 97
bne pfPrefix0Next
lbz r0, 44(r3)
cmpwi r0, 116
bne pfPrefix0Next
lbz r0, 45(r3)
cmpwi r0, 97
bne pfPrefix0Next
lbz r0, 46(r3)
cmpwi r0, 47
bne pfPrefix0Next
lbz r0, 47(r3)
cmpwi r0, 67
bne pfPrefix0Next
lbz r0, 48(r3)
cmpwi r0, 111
bne pfPrefix0Next
lbz r0, 49(r3)
cmpwi r0, 117
bne pfPrefix0Next
lbz r0, 50(r3)
cmpwi r0, 114
bne pfPrefix0Next
lbz r0, 51(r3)
cmpwi r0, 115
bne pfPrefix0Next
lbz r0, 52(r3)
cmpwi r0, 101
bne pfPrefix0Next
lbz r0, 53(r3)
cmpwi r0, 83
bne pfPrefix0Next
lbz r0, 54(r3)
cmpwi r0, 101
bne pfPrefix0Next
lbz r0, 55(r3)
cmpwi r0, 108
bne pfPrefix0Next
lbz r0, 56(r3)
cmpwi r0, 101
bne pfPrefix0Next
lbz r0, 57(r3)
cmpwi r0, 99
bne pfPrefix0Next
lbz r0, 58(r3)
cmpwi r0, 116
bne pfPrefix0Next
b pfObjectPosition
pfPrefix0Next:
lbz r0, 36(r3)
cmpwi r0, 79
bne pfPrefix1Next
lbz r0, 37(r3)
cmpwi r0, 98
bne pfPrefix1Next
lbz r0, 38(r3)
cmpwi r0, 106
bne pfPrefix1Next
lbz r0, 39(r3)
cmpwi r0, 101
bne pfPrefix1Next
lbz r0, 40(r3)
cmpwi r0, 99
bne pfPrefix1Next
lbz r0, 41(r3)
cmpwi r0, 116
bne pfPrefix1Next
lbz r0, 42(r3)
cmpwi r0, 68
bne pfPrefix1Next
lbz r0, 43(r3)
cmpwi r0, 97
bne pfPrefix1Next
lbz r0, 44(r3)
cmpwi r0, 116
bne pfPrefix1Next
lbz r0, 45(r3)
cmpwi r0, 97
bne pfPrefix1Next
lbz r0, 46(r3)
cmpwi r0, 47
bne pfPrefix1Next
lbz r0, 47(r3)
cmpwi r0, 77
bne pfPrefix1Next
lbz r0, 48(r3)
cmpwi r0, 105
bne pfPrefix1Next
lbz r0, 49(r3)
cmpwi r0, 110
bne pfPrefix1Next
lbz r0, 50(r3)
cmpwi r0, 105
bne pfPrefix1Next
lbz r0, 51(r3)
cmpwi r0, 97
bne pfPrefix1Next
lbz r0, 52(r3)
cmpwi r0, 116
bne pfPrefix1Next
lbz r0, 53(r3)
cmpwi r0, 117
bne pfPrefix1Next
lbz r0, 54(r3)
cmpwi r0, 114
bne pfPrefix1Next
lbz r0, 55(r3)
cmpwi r0, 101
bne pfPrefix1Next
b pfObjectPosition
pfPrefix1Next:
lbz r0, 36(r3)
cmpwi r0, 79
bne pfPrefix2Next
lbz r0, 37(r3)
cmpwi r0, 98
bne pfPrefix2Next
lbz r0, 38(r3)
cmpwi r0, 106
bne pfPrefix2Next
lbz r0, 39(r3)
cmpwi r0, 101
bne pfPrefix2Next
lbz r0, 40(r3)
cmpwi r0, 99
bne pfPrefix2Next
lbz r0, 41(r3)
cmpwi r0, 116
bne pfPrefix2Next
lbz r0, 42(r3)
cmpwi r0, 68
bne pfPrefix2Next
lbz r0, 43(r3)
cmpwi r0, 97
bne pfPrefix2Next
lbz r0, 44(r3)
cmpwi r0, 116
bne pfPrefix2Next
lbz r0, 45(r3)
cmpwi r0, 97
bne pfPrefix2Next
lbz r0, 46(r3)
cmpwi r0, 47
bne pfPrefix2Next
lbz r0, 47(r3)
cmpwi r0, 67
bne pfPrefix2Next
lbz r0, 48(r3)
cmpwi r0, 111
bne pfPrefix2Next
lbz r0, 49(r3)
cmpwi r0, 97
bne pfPrefix2Next
lbz r0, 50(r3)
cmpwi r0, 115
bne pfPrefix2Next
lbz r0, 51(r3)
cmpwi r0, 116
bne pfPrefix2Next
lbz r0, 52(r3)
cmpwi r0, 101
bne pfPrefix2Next
lbz r0, 53(r3)
cmpwi r0, 114
bne pfPrefix2Next
lbz r0, 54(r3)
cmpwi r0, 83
bne pfPrefix2Next
lbz r0, 55(r3)
cmpwi r0, 116
bne pfPrefix2Next
lbz r0, 56(r3)
cmpwi r0, 97
bne pfPrefix2Next
lbz r0, 57(r3)
cmpwi r0, 114
bne pfPrefix2Next
b pfObjectPosition
pfPrefix2Next:
lbz r0, 36(r3)
cmpwi r0, 79
bne pfPrefix3Next
lbz r0, 37(r3)
cmpwi r0, 98
bne pfPrefix3Next
lbz r0, 38(r3)
cmpwi r0, 106
bne pfPrefix3Next
lbz r0, 39(r3)
cmpwi r0, 101
bne pfPrefix3Next
lbz r0, 40(r3)
cmpwi r0, 99
bne pfPrefix3Next
lbz r0, 41(r3)
cmpwi r0, 116
bne pfPrefix3Next
lbz r0, 42(r3)
cmpwi r0, 68
bne pfPrefix3Next
lbz r0, 43(r3)
cmpwi r0, 97
bne pfPrefix3Next
lbz r0, 44(r3)
cmpwi r0, 116
bne pfPrefix3Next
lbz r0, 45(r3)
cmpwi r0, 97
bne pfPrefix3Next
lbz r0, 46(r3)
cmpwi r0, 47
bne pfPrefix3Next
lbz r0, 47(r3)
cmpwi r0, 84
bne pfPrefix3Next
lbz r0, 48(r3)
cmpwi r0, 105
bne pfPrefix3Next
lbz r0, 49(r3)
cmpwi r0, 99
bne pfPrefix3Next
lbz r0, 50(r3)
cmpwi r0, 111
bne pfPrefix3Next
b pfObjectPosition
pfPrefix3Next:
b pfGateDone
pfObjectPosition:
addi r8, r3, 36
li r9, 64
pfNameEnd:
lbz r0, 0(r8)
cmpwi r0, 0
beq pfHaveNameEnd
addi r8, r8, 1
addi r9, r9, -1
cmpwi r9, 0
bgt pfNameEnd
b pfGateDone
pfHaveNameEnd:
addi r8, r8, 4
rlwinm r8, r8, 0, 0, 29
lwz r8, 28(r8)
lis r9, 0x46AB
ori r9, r9, 0xE000
cmplw r8, r9
blt pfGateDone
lis r9, 0x470E
ori r9, r9, 0x9400
cmplw r8, r9
bgt pfGateDone
lis r9, 0x46D0
ori r9, r9, 0x3400
cmplw r8, r9
blt pfObjectLower
lis r9, 0x46F7
ori r9, r9, 0xDA00
cmplw r8, r9
blt pfObjectMiddle
li r8, 3
b pfObjectCompare
pfObjectLower:
li r8, 1
b pfObjectCompare
pfObjectMiddle:
li r8, 2
pfObjectCompare:
lwz r0, 8(r12)
cmpw r0, r8
beq pfGateDone
lwz r9, 32(r12)
addi r9, r9, 1
stw r9, 32(r12)
li r3, 0
b pfGateDone
pfWorldOneAttachments:
; W1 node/rail Y range is -275..20; its pipe parts are all Y=120.
; Only distant elevated road/pipe models qualify, never clouds or scenery.
lis r9, mrSceneClass@ha
lwz r9, mrSceneClass@l(r9)
lis r8, 0x1027
ori r8, r8, 0xF388
cmpw r9, r8
bne pfGateDone
lwz r9, 12(r12)
cmpwi r9, 1
bne pfGateDone
lbz r0, 36(r3)
cmpwi r0, 79
bne pfW1Road
lbz r0, 37(r3)
cmpwi r0, 98
bne pfW1Road
lbz r0, 38(r3)
cmpwi r0, 106
bne pfW1Road
lbz r0, 39(r3)
cmpwi r0, 101
bne pfW1Road
lbz r0, 40(r3)
cmpwi r0, 99
bne pfW1Road
lbz r0, 41(r3)
cmpwi r0, 116
bne pfW1Road
lbz r0, 42(r3)
cmpwi r0, 68
bne pfW1Road
lbz r0, 43(r3)
cmpwi r0, 97
bne pfW1Road
lbz r0, 44(r3)
cmpwi r0, 116
bne pfW1Road
lbz r0, 45(r3)
cmpwi r0, 97
bne pfW1Road
lbz r0, 46(r3)
cmpwi r0, 47
bne pfW1Road
lbz r0, 47(r3)
cmpwi r0, 82
bne pfW1Road
lbz r0, 48(r3)
cmpwi r0, 111
bne pfW1Road
lbz r0, 49(r3)
cmpwi r0, 117
bne pfW1Road
lbz r0, 50(r3)
cmpwi r0, 116
bne pfW1Road
lbz r0, 51(r3)
cmpwi r0, 101
bne pfW1Road
lbz r0, 52(r3)
cmpwi r0, 68
bne pfW1Road
lbz r0, 53(r3)
cmpwi r0, 111
bne pfW1Road
lbz r0, 54(r3)
cmpwi r0, 107
bne pfW1Road
lbz r0, 55(r3)
cmpwi r0, 97
bne pfW1Road
lbz r0, 56(r3)
cmpwi r0, 110
bne pfW1Road
b pfW1Position
pfW1Road:
lbz r0, 36(r3)
cmpwi r0, 79
bne pfGateDone
lbz r0, 37(r3)
cmpwi r0, 98
bne pfGateDone
lbz r0, 38(r3)
cmpwi r0, 106
bne pfGateDone
lbz r0, 39(r3)
cmpwi r0, 101
bne pfGateDone
lbz r0, 40(r3)
cmpwi r0, 99
bne pfGateDone
lbz r0, 41(r3)
cmpwi r0, 116
bne pfGateDone
lbz r0, 42(r3)
cmpwi r0, 68
bne pfGateDone
lbz r0, 43(r3)
cmpwi r0, 97
bne pfGateDone
lbz r0, 44(r3)
cmpwi r0, 116
bne pfGateDone
lbz r0, 45(r3)
cmpwi r0, 97
bne pfGateDone
lbz r0, 46(r3)
cmpwi r0, 47
bne pfGateDone
lbz r0, 47(r3)
cmpwi r0, 67
bne pfGateDone
lbz r0, 48(r3)
cmpwi r0, 111
bne pfGateDone
lbz r0, 49(r3)
cmpwi r0, 117
bne pfGateDone
lbz r0, 50(r3)
cmpwi r0, 114
bne pfGateDone
lbz r0, 51(r3)
cmpwi r0, 115
bne pfGateDone
lbz r0, 52(r3)
cmpwi r0, 101
bne pfGateDone
lbz r0, 53(r3)
cmpwi r0, 83
bne pfGateDone
lbz r0, 54(r3)
cmpwi r0, 101
bne pfGateDone
lbz r0, 55(r3)
cmpwi r0, 108
bne pfGateDone
lbz r0, 56(r3)
cmpwi r0, 101
bne pfGateDone
lbz r0, 57(r3)
cmpwi r0, 99
bne pfGateDone
lbz r0, 58(r3)
cmpwi r0, 116
bne pfGateDone
lbz r0, 59(r3)
cmpwi r0, 82
bne pfGateDone
lbz r0, 60(r3)
cmpwi r0, 111
bne pfGateDone
lbz r0, 61(r3)
cmpwi r0, 97
bne pfGateDone
lbz r0, 62(r3)
cmpwi r0, 100
bne pfGateDone
pfW1Position:
addi r8, r3, 36
li r9, 64
pfW1NameEnd:
lbz r0, 0(r8)
cmpwi r0, 0
beq pfW1HaveName
addi r8, r8, 1
addi r9, r9, -1
cmpwi r9, 0
bgt pfW1NameEnd
b pfGateDone
pfW1HaveName:
addi r8, r8, 4
rlwinm r8, r8, 0, 0, 29
lwz r8, 28(r8)
lis r9, 0x44FA ; 2000.0: generous separation from all W1 road/pipe placements
cmplw r8, r9
blt pfGateDone
lis r9, 0x470E
ori r9, r9, 0x9400 ; 36500.0: unknown/nonfinite positions pass
cmplw r8, r9
bgt pfGateDone
lwz r9, 56(r12)
addi r9, r9, 1
stw r9, 56(r12)
li r3, 0
pfGateDone:
lwz r4, 8(r1)
lwz r5, 12(r1)
lwz r6, 16(r1)
lwz r7, 20(r1)
lwz r8, 24(r1)
lwz r9, 28(r1)
lwz r10, 32(r1)
lwz r11, 36(r1)
lwz r12, 40(r1)
addi r1, r1, 0x40
blr
pfDraw:
stwu r1, -0x80(r1)
mflr r0
stw r0, 0x84(r1)
stw r3, 8(r1)
stw r4, 12(r1)
stw r5, 16(r1)
stw r6, 20(r1)
stw r7, 24(r1)
stw r8, 28(r1)
stw r20, 32(r1)
stw r21, 36(r1)
stw r22, 40(r1)
stw r23, 44(r1)
stw r24, 48(r1)
stw r25, 52(r1)
stw r26, 56(r1)
stw r27, 60(r1)
lis r12, pfState@ha
addi r12, r12, pfState@l
lwz r9, 24(r12)
cmpw r9, r30
bne pfDrawOriginal
lwz r25, 8(r12)
cmplwi r25, 1
blt pfDrawOriginal
cmplwi r25, 3
bgt pfDrawOriginal
lwz r9, 28(r12)
cmplwi r9, 13
bgt pfDrawOriginal
cmpwi r3, 4
bne pfDrawOriginal
cmpwi r5, 4
bne pfDrawOriginal
cmpwi r7, 0
bne pfDrawOriginal
cmplwi r4, 0
beq pfDrawOriginal
andi. r0, r31, 1
bne pfDrawOriginal
lis r20, pfRanges@ha
addi r20, r20, pfRanges@l
mulli r9, r9, 72
add r20, r20, r9
srwi r22, r31, 1
add r23, r22, r4
cmplw r23, r22
blt pfDrawOriginal
lwz r0, 0(r20)
cmplw r23, r0
bgt pfDrawOriginal
subf r24, r31, r6
lwz r21, 8(r20)
addi r20, r20, 12
pfDrawLoop:
lwz r0, 0(r20)
cmpw r0, r25
bne pfDrawNext
lwz r26, 4(r20)
lwz r27, 8(r20)
add r27, r26, r27
cmplw r26, r22
bge pfDrawLoReady
mr r26, r22
pfDrawLoReady:
cmplw r27, r23
ble pfDrawHiReady
mr r27, r23
pfDrawHiReady:
cmplw r26, r27
bge pfDrawNext
lwz r3, 8(r1)
subf r4, r26, r27
lwz r5, 16(r1)
slwi r6, r26, 1
add r6, r6, r24
lwz r7, 24(r1)
lwz r8, 28(r1)
bl import.gx2.GX2DrawIndexedEx
pfDrawNext:
addi r20, r20, 12
addi r21, r21, -1
cmpwi r21, 0
bgt pfDrawLoop
lis r12, pfState@ha
addi r12, r12, pfState@l
lwz r11, 36(r12)
addi r11, r11, 1
stw r11, 36(r12)
b pfDrawDone
pfDrawOriginal:
lwz r3, 8(r1)
lwz r4, 12(r1)
lwz r5, 16(r1)
lwz r6, 20(r1)
lwz r7, 24(r1)
lwz r8, 28(r1)
bl import.gx2.GX2DrawIndexedEx
pfDrawDone:
lwz r20, 32(r1)
lwz r21, 36(r1)
lwz r22, 40(r1)
lwz r23, 44(r1)
lwz r24, 48(r1)
lwz r25, 52(r1)
lwz r26, 56(r1)
lwz r27, 60(r1)
lwz r0, 0x84(r1)
mtlr r0
addi r1, r1, 0x80
blr
pfState:
.int 0x50464C54
.int 1
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
pfRanges:
.int 6936
.int 15
.int 1
.int 2
.int 0
.int 6936
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 10845
.int 14
.int 1
.int 2
.int 0
.int 10845
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 7020
.int 17
.int 1
.int 1
.int 0
.int 7020
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 9894
.int 16
.int 1
.int 3
.int 0
.int 9894
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 16440
.int 20
.int 2
.int 2
.int 0
.int 12408
.int 1
.int 12408
.int 4032
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 7524
.int 15
.int 5
.int 2
.int 0
.int 12
.int 1
.int 12
.int 1737
.int 2
.int 1749
.int 201
.int 1
.int 1950
.int 99
.int 2
.int 2049
.int 5475
.int 8496
.int 24
.int 1
.int 2
.int 0
.int 8496
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 7824
.int 16
.int 1
.int 1
.int 0
.int 7824
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 13272
.int 22
.int 1
.int 2
.int 0
.int 13272
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 11520
.int 15
.int 1
.int 3
.int 0
.int 11520
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 7020
.int 17
.int 1
.int 1
.int 0
.int 7020
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 9894
.int 16
.int 1
.int 3
.int 0
.int 9894
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 6936
.int 15
.int 1
.int 2
.int 0
.int 6936
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 10845
.int 14
.int 1
.int 2
.int 0
.int 10845
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
pfParticleFill:
stwu r1, -0x30(r1)
mflr r0
stw r0, 0x34(r1)
stw r3, 8(r1)
stw r4, 12(r1)
bl pfParticleFillOriginal
lis r12, pfParticleDebug@ha
addi r12, r12, pfParticleDebug@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
lwz r10, 12(r1)
lwz r10, 0x12C(r10)
stw r10, 4(r12)
lwz r9, 0x130(r10)
stw r9, 8(r12)
lwz r11, 8(r1)
lwz r11, 4(r11)
stw r11, 12(r12)
lis r6, pfParticleCensus@ha
addi r6, r6, pfParticleCensus@l
srwi r8, r9, 4
rlwinm r8, r8, 6, 18, 25
li r7, 8
pfCensusProbe:
add r5, r6, r8
lwz r0, 0(r5)
cmpw r0, r9
beq pfCensusRecord
cmpwi r0, 0
beq pfCensusRecord
addi r8, r8, 64
rlwinm r8, r8, 0, 18, 25
addi r7, r7, -1
cmpwi r7, 0
bgt pfCensusProbe
lis r12, pfParticleDebug@ha
addi r12, r12, pfParticleDebug@l
lwz r4, 48(r12)
addi r4, r4, 1
stw r4, 48(r12)
b pfCensusDone
pfCensusRecord:
stw r9, 0(r5)
lwz r4, 4(r5)
addi r4, r4, 1
stw r4, 4(r5)
lis r11, mrSceneClass@ha
lwz r11, mrSceneClass@l(r11)
stw r11, 16(r5)
lis r0, 0x1027
ori r0, r0, 0xF388
cmpw r11, r0
bne pfCensusNotMap
lwz r4, 8(r5)
addi r4, r4, 1
stw r4, 8(r5)
b pfCensusMetadata
pfCensusNotMap:
lwz r4, 12(r5)
addi r4, r4, 1
stw r4, 12(r5)
pfCensusMetadata:
lwz r0, 0(r9)
stw r0, 20(r5)
lwz r0, 4(r9)
stw r0, 24(r5)
lwz r0, 0x38(r9)
stw r0, 28(r5)
lwz r0, 0x2E8(r9)
stw r0, 32(r5)
lwz r0, 0x3C(r9)
stw r0, 52(r5)
lwz r4, 12(r1)
stw r4, 60(r5)
lwz r0, 0x18(r4)
stw r0, 36(r5)
lwz r0, 0x12C(r4)
stw r0, 56(r5)
lwz r4, 8(r1)
lwz r0, 4(r4)
stw r0, 40(r5)
lis r12, pfState@ha
addi r12, r12, pfState@l
lwz r0, 12(r12)
stw r0, 44(r5)
lwz r0, 8(r12)
stw r0, 48(r5)
pfCensusDone:
lis r11, mrSceneClass@ha
lwz r11, mrSceneClass@l(r11)
lis r9, 0x1027
ori r9, r9, 0xF388
cmpw r11, r9
beq pfCensusGuardPassed
lis r12, pfParticleDebug@ha
addi r12, r12, pfParticleDebug@l
lwz r4, 44(r12)
addi r4, r4, 1
stw r4, 44(r12)
b pfParticleDone
pfCensusGuardPassed:
lis r12, pfParticleDebug@ha
addi r12, r12, pfParticleDebug@l
lwz r4, 40(r12)
addi r4, r4, 1
stw r4, 40(r12)
; Particle +12C owns the emitter, independent of the caller's GPR allocation.
lis r12, pfState@ha
addi r12, r12, pfState@l
lwz r8, 8(r12)
lwz r10, 12(r1)
lwz r10, 0x12C(r10)
lwz r9, 0x130(r10)
cmpwi r9, 0
beq pfParticleDone
; Road Glow is independent from the model draw and has four definitions.
lwz r11, 0x38(r9)
cmplwi r11, 0x3F0C
beq pfRoadGlow
cmplwi r11, 0x3F11
beq pfRoadPtcl
cmplwi r11, 0x3F16
beq pfRoadCore
cmplwi r11, 0x3F1B
beq pfRoadCore
cmplwi r8, 1
blt pfParticleDone
cmplwi r8, 3
bgt pfParticleDone
; Three unique tuples in the verified EU-v0 effect resource.
lwz r0, 0(r9)
cmpwi r0, 0
bne pfParticleDone
lwz r0, 4(r9)
lis r10, 0x0080
cmpw r0, r10
bne pfParticleDone
lwz r10, 0x2E8(r9)
lwz r11, 0x38(r9)
cmpwi r10, 152
beq pfParticleA
cmpwi r10, 153
beq pfParticleB
cmpwi r10, 154
bne pfParticleDone
cmplwi r11, 0xA289
bne pfParticleDone
b pfParticlePosition
pfParticleA:
cmplwi r11, 0xA27D
bne pfParticleDone
b pfParticlePosition
pfParticleB:
cmplwi r11, 0xA283
bne pfParticleDone
pfParticlePosition:
lis r11, pfParticleDebug@ha
addi r11, r11, pfParticleDebug@l
lwz r4, 16(r11)
addi r4, r4, 1
stw r4, 16(r11)
stw r9, 24(r11)
lwz r11, 40(r12)
addi r11, r11, 1
stw r11, 40(r12)
; Classify FallPtcl in its primitive's local space, before native transform.
; The verified source meshes lie at -8.40, 4790.73 and 10140.73.
; 0254D070..0254D0F0 applies particle+104 to local +14/+18/+1C.
lwz r9, 12(r1)
lwz r10, 0x18(r9)
lis r11, pfParticleDebug@ha
addi r11, r11, pfParticleDebug@l
stw r10, 28(r11)
stw r10, 48(r12)
lwz r11, 12(r1)
lwz r11, 0x12C(r11)
stw r11, 52(r12)
cmpwi r10, 0
bge pfParticlePositiveLocal
rlwinm r10, r10, 0, 1, 31
lis r11, 0x44FA ; permit local negative drift only down to -2000
cmplw r10, r11
bgt pfParticleDone
b pfParticleLower
pfParticlePositiveLocal:
lis r11, 0x463F
ori r11, r11, 0x6800 ; 12250; NaN/Inf and unknown positions pass
cmplw r10, r11
bgt pfParticleDone
lis r11, 0x4516 ; 2400
cmplw r10, r11
blt pfParticleLower
lis r11, 0x45E9
ori r11, r11, 0x9800 ; 7475
cmplw r10, r11
blt pfParticleMiddle
li r10, 3
b pfParticleCompare
pfRoadGlow:
lwz r0, 0(r9)
cmpwi r0, 1
bne pfParticleDone
lwz r0, 4(r9)
lis r11, 0x0038
cmpw r0, r11
bne pfParticleDone
b pfRoadIdentity
pfRoadPtcl:
lwz r0, 0(r9)
cmpwi r0, 1
bne pfParticleDone
b pfRoadZeroFlags
pfRoadCore:
lwz r0, 0(r9)
cmpwi r0, 0
bne pfParticleDone
pfRoadZeroFlags:
lwz r0, 4(r9)
cmpwi r0, 0
bne pfParticleDone
pfRoadIdentity:
lwz r0, 0x2E8(r9)
cmpwi r0, -1
bne pfParticleDone
lis r11, pfParticleDebug@ha
addi r11, r11, pfParticleDebug@l
lwz r4, 20(r11)
addi r4, r4, 1
stw r4, 20(r11)
stw r9, 32(r11)
lwz r11, 40(r12)
addi r11, r11, 1
stw r11, 40(r12)
; Road effects follow their owner's position. Classify native world output.
lwz r9, 8(r1)
lwz r10, 4(r9)
lis r11, pfParticleDebug@ha
addi r11, r11, pfParticleDebug@l
stw r10, 36(r11)
stw r10, 48(r12)
cmplwi r8, 1
blt pfRoadWorldOne
cmplwi r8, 3
bgt pfParticleDone
lis r11, 0x46AB
ori r11, r11, 0xE000 ; 22000
cmplw r10, r11
blt pfParticleDone
lis r11, 0x470E
ori r11, r11, 0x9400 ; 36500
cmplw r10, r11
bgt pfParticleDone
lis r11, 0x46D0
ori r11, r11, 0x3400 ; 26650
cmplw r10, r11
blt pfParticleLower
lis r11, 0x46F7
ori r11, r11, 0xDA00 ; 31725
cmplw r10, r11
blt pfParticleMiddle
li r10, 3
b pfParticleCompare
pfParticleLower:
li r10, 1
b pfParticleCompare
pfParticleMiddle:
li r10, 2
pfParticleCompare:
cmpw r10, r8
beq pfParticleDone
b pfParticleHide
pfRoadWorldOne:
lwz r11, 12(r12)
cmpwi r11, 1
bne pfParticleDone
lis r11, 0x44FA ; same distant-attachment bound as the W1 model filter
cmplw r10, r11
blt pfParticleDone
lis r11, 0x470E
ori r11, r11, 0x9400
cmplw r10, r11
bgt pfParticleDone
pfParticleHide:
lwz r9, 8(r1)
; Only this frame's 0xC0-byte GPU record. Scale xy and both colour alphas.
li r0, 0
stw r0, 0x10(r9)
stw r0, 0x14(r9)
stw r0, 0x2C(r9)
stw r0, 0x3C(r9)
lwz r11, 44(r12)
addi r11, r11, 1
stw r11, 44(r12)
pfParticleDone:
lwz r0, 0x34(r1)
mtlr r0
addi r1, r1, 0x30
blr
pfParticleDebug:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
pfParticleCensus:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
0x0254DF08 = pfParticleFillOriginal:
0x02558F78 = bla pfParticleFill
0x02548B3C = bla pfParticleFill
0x0255C220 = bla pfParticleFill
0x0255C2F8 = bla pfParticleFill
pfPipeActor:
stwu r1, -0x20(r1)
mflr r0
stw r0, 0x24(r1)
lis r12, pfPipeState@ha
addi r12, r12, pfPipeState@l
lwz r0, 0(r12)
stw r0, 8(r1)
li r0, 0
stw r0, 0(r12)
lis r10, mrSceneClass@ha
lwz r10, mrSceneClass@l(r10)
; First-stage capture: a rescued remote bonus room has a large Black01
; enclosure. Keep native visibility for this exact actor/model only; this
; still permits the room when the game's own camera accepts it.
lis r11, 0x1032
ori r11, r11, 0x86DC
cmpw r10, r11
bne pfPipeMapScene
lwz r9, 0(r3)
cmpwi r9, 0
beq pfPipeCall
lwz r11, 0(r9)
lis r0, 0x1037
ori r0, r0, 0x6518
cmpw r11, r0
bne pfPipeCall
lwz r9, 0x44(r9)
cmpwi r9, 0
beq pfPipeCall
lwz r9, 4(r9)
cmpwi r9, 0
beq pfPipeCall
lbz r0, 0(r9)
cmpwi r0, 69
bne pfPipeCall
lbz r0, 1(r9)
cmpwi r0, 110
bne pfPipeCall
lbz r0, 2(r9)
cmpwi r0, 116
bne pfPipeCall
lbz r0, 3(r9)
cmpwi r0, 101
bne pfPipeCall
lbz r0, 4(r9)
cmpwi r0, 114
bne pfPipeCall
lbz r0, 5(r9)
cmpwi r0, 67
bne pfPipeCall
lbz r0, 6(r9)
cmpwi r0, 97
bne pfPipeCall
lbz r0, 7(r9)
cmpwi r0, 116
bne pfPipeCall
lbz r0, 8(r9)
cmpwi r0, 77
bne pfPipeCall
lbz r0, 9(r9)
cmpwi r0, 97
bne pfPipeCall
lbz r0, 10(r9)
cmpwi r0, 114
bne pfPipeCall
lbz r0, 11(r9)
cmpwi r0, 105
bne pfPipeCall
lbz r0, 12(r9)
cmpwi r0, 111
bne pfPipeCall
lbz r0, 13(r9)
cmpwi r0, 66
bne pfPipeCall
lbz r0, 14(r9)
cmpwi r0, 111
bne pfPipeCall
lbz r0, 15(r9)
cmpwi r0, 110
bne pfPipeCall
lbz r0, 16(r9)
cmpwi r0, 117
bne pfPipeCall
lbz r0, 17(r9)
cmpwi r0, 115
bne pfPipeCall
lbz r0, 18(r9)
cmpwi r0, 82
bne pfPipeCall
lbz r0, 19(r9)
cmpwi r0, 111
bne pfPipeCall
lbz r0, 20(r9)
cmpwi r0, 111
bne pfPipeCall
lbz r0, 21(r9)
cmpwi r0, 109
bne pfPipeCall
lbz r0, 22(r9)
cmpwi r0, 0
bne pfPipeCall
b pfPipeFound
pfPipeMapScene:
lis r11, 0x1027
ori r11, r11, 0xF388
cmpw r10, r11
bne pfPipeCall
lwz r9, 0(r3)
cmpwi r9, 0
beq pfPipeCall
lwz r10, 0(r9)
; RouteDokan, CourseSelectRouteDokan, CourseSelectRouteDokan terminator.
lis r11, 0x1030
ori r11, r11, 0x5018
cmpw r10, r11
beq pfPipeFound
lis r11, 0x1027
ori r11, r11, 0xE918
cmpw r10, r11
beq pfPipeFound
lis r11, 0x1027
ori r11, r11, 0xEBF4
cmpw r10, r11
beq pfPipeFound
; Generic parts: only a verified model-resource name qualifies.
lwz r9, 0x44(r9)
cmpwi r9, 0
beq pfPipeCall
lwz r9, 0(r9)
cmpwi r9, 0
beq pfPipeCall
lwz r9, 8(r9)
cmpwi r9, 0
beq pfPipeCall
lis r10, pfState@ha
addi r10, r10, pfState@l
lwz r10, 12(r10)
cmpwi r10, 2
bne pfPipeW1Names
lbz r0, 36(r9)
cmpwi r0, 79
bne pfW2Families
lbz r0, 37(r9)
cmpwi r0, 98
bne pfW2Families
lbz r0, 38(r9)
cmpwi r0, 106
bne pfW2Families
lbz r0, 39(r9)
cmpwi r0, 101
bne pfW2Families
lbz r0, 40(r9)
cmpwi r0, 99
bne pfW2Families
lbz r0, 41(r9)
cmpwi r0, 116
bne pfW2Families
lbz r0, 42(r9)
cmpwi r0, 68
bne pfW2Families
lbz r0, 43(r9)
cmpwi r0, 97
bne pfW2Families
lbz r0, 44(r9)
cmpwi r0, 116
bne pfW2Families
lbz r0, 45(r9)
cmpwi r0, 97
bne pfW2Families
lbz r0, 46(r9)
cmpwi r0, 47
bne pfW2Families
lbz r0, 47(r9)
cmpwi r0, 82
bne pfW2Families
lbz r0, 48(r9)
cmpwi r0, 111
bne pfW2Families
lbz r0, 49(r9)
cmpwi r0, 117
bne pfW2Families
lbz r0, 50(r9)
cmpwi r0, 116
bne pfW2Families
lbz r0, 51(r9)
cmpwi r0, 101
bne pfW2Families
lbz r0, 52(r9)
cmpwi r0, 68
bne pfW2Families
lbz r0, 53(r9)
cmpwi r0, 111
bne pfW2Families
lbz r0, 54(r9)
cmpwi r0, 107
bne pfW2Families
lbz r0, 55(r9)
cmpwi r0, 97
bne pfW2Families
lbz r0, 56(r9)
cmpwi r0, 110
bne pfW2Families
b pfPipeFound
pfW2Families:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfW2NameNext0
lbz r0, 37(r9)
cmpwi r0, 98
bne pfW2NameNext0
lbz r0, 38(r9)
cmpwi r0, 106
bne pfW2NameNext0
lbz r0, 39(r9)
cmpwi r0, 101
bne pfW2NameNext0
lbz r0, 40(r9)
cmpwi r0, 99
bne pfW2NameNext0
lbz r0, 41(r9)
cmpwi r0, 116
bne pfW2NameNext0
lbz r0, 42(r9)
cmpwi r0, 68
bne pfW2NameNext0
lbz r0, 43(r9)
cmpwi r0, 97
bne pfW2NameNext0
lbz r0, 44(r9)
cmpwi r0, 116
bne pfW2NameNext0
lbz r0, 45(r9)
cmpwi r0, 97
bne pfW2NameNext0
lbz r0, 46(r9)
cmpwi r0, 47
bne pfW2NameNext0
lbz r0, 47(r9)
cmpwi r0, 67
bne pfW2NameNext0
lbz r0, 48(r9)
cmpwi r0, 111
bne pfW2NameNext0
lbz r0, 49(r9)
cmpwi r0, 117
bne pfW2NameNext0
lbz r0, 50(r9)
cmpwi r0, 114
bne pfW2NameNext0
lbz r0, 51(r9)
cmpwi r0, 115
bne pfW2NameNext0
lbz r0, 52(r9)
cmpwi r0, 101
bne pfW2NameNext0
lbz r0, 53(r9)
cmpwi r0, 83
bne pfW2NameNext0
lbz r0, 54(r9)
cmpwi r0, 101
bne pfW2NameNext0
lbz r0, 55(r9)
cmpwi r0, 108
bne pfW2NameNext0
lbz r0, 56(r9)
cmpwi r0, 101
bne pfW2NameNext0
lbz r0, 57(r9)
cmpwi r0, 99
bne pfW2NameNext0
lbz r0, 58(r9)
cmpwi r0, 116
bne pfW2NameNext0
lbz r0, 59(r9)
cmpwi r0, 82
bne pfW2NameNext0
lbz r0, 60(r9)
cmpwi r0, 111
bne pfW2NameNext0
lbz r0, 61(r9)
cmpwi r0, 97
bne pfW2NameNext0
lbz r0, 62(r9)
cmpwi r0, 100
bne pfW2NameNext0
b pfW2NameEndStart
pfW2NameNext0:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfW2NameNext1
lbz r0, 37(r9)
cmpwi r0, 98
bne pfW2NameNext1
lbz r0, 38(r9)
cmpwi r0, 106
bne pfW2NameNext1
lbz r0, 39(r9)
cmpwi r0, 101
bne pfW2NameNext1
lbz r0, 40(r9)
cmpwi r0, 99
bne pfW2NameNext1
lbz r0, 41(r9)
cmpwi r0, 116
bne pfW2NameNext1
lbz r0, 42(r9)
cmpwi r0, 68
bne pfW2NameNext1
lbz r0, 43(r9)
cmpwi r0, 97
bne pfW2NameNext1
lbz r0, 44(r9)
cmpwi r0, 116
bne pfW2NameNext1
lbz r0, 45(r9)
cmpwi r0, 97
bne pfW2NameNext1
lbz r0, 46(r9)
cmpwi r0, 47
bne pfW2NameNext1
lbz r0, 47(r9)
cmpwi r0, 67
bne pfW2NameNext1
lbz r0, 48(r9)
cmpwi r0, 111
bne pfW2NameNext1
lbz r0, 49(r9)
cmpwi r0, 117
bne pfW2NameNext1
lbz r0, 50(r9)
cmpwi r0, 114
bne pfW2NameNext1
lbz r0, 51(r9)
cmpwi r0, 115
bne pfW2NameNext1
lbz r0, 52(r9)
cmpwi r0, 101
bne pfW2NameNext1
lbz r0, 53(r9)
cmpwi r0, 83
bne pfW2NameNext1
lbz r0, 54(r9)
cmpwi r0, 101
bne pfW2NameNext1
lbz r0, 55(r9)
cmpwi r0, 108
bne pfW2NameNext1
lbz r0, 56(r9)
cmpwi r0, 101
bne pfW2NameNext1
lbz r0, 57(r9)
cmpwi r0, 99
bne pfW2NameNext1
lbz r0, 58(r9)
cmpwi r0, 116
bne pfW2NameNext1
lbz r0, 59(r9)
cmpwi r0, 80
bne pfW2NameNext1
lbz r0, 60(r9)
cmpwi r0, 111
bne pfW2NameNext1
lbz r0, 61(r9)
cmpwi r0, 105
bne pfW2NameNext1
lbz r0, 62(r9)
cmpwi r0, 110
bne pfW2NameNext1
lbz r0, 63(r9)
cmpwi r0, 116
bne pfW2NameNext1
b pfW2NameEndStart
pfW2NameNext1:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfW2NameNext2
lbz r0, 37(r9)
cmpwi r0, 98
bne pfW2NameNext2
lbz r0, 38(r9)
cmpwi r0, 106
bne pfW2NameNext2
lbz r0, 39(r9)
cmpwi r0, 101
bne pfW2NameNext2
lbz r0, 40(r9)
cmpwi r0, 99
bne pfW2NameNext2
lbz r0, 41(r9)
cmpwi r0, 116
bne pfW2NameNext2
lbz r0, 42(r9)
cmpwi r0, 68
bne pfW2NameNext2
lbz r0, 43(r9)
cmpwi r0, 97
bne pfW2NameNext2
lbz r0, 44(r9)
cmpwi r0, 116
bne pfW2NameNext2
lbz r0, 45(r9)
cmpwi r0, 97
bne pfW2NameNext2
lbz r0, 46(r9)
cmpwi r0, 47
bne pfW2NameNext2
lbz r0, 47(r9)
cmpwi r0, 67
bne pfW2NameNext2
lbz r0, 48(r9)
cmpwi r0, 111
bne pfW2NameNext2
lbz r0, 49(r9)
cmpwi r0, 117
bne pfW2NameNext2
lbz r0, 50(r9)
cmpwi r0, 114
bne pfW2NameNext2
lbz r0, 51(r9)
cmpwi r0, 115
bne pfW2NameNext2
lbz r0, 52(r9)
cmpwi r0, 101
bne pfW2NameNext2
lbz r0, 53(r9)
cmpwi r0, 83
bne pfW2NameNext2
lbz r0, 54(r9)
cmpwi r0, 101
bne pfW2NameNext2
lbz r0, 55(r9)
cmpwi r0, 108
bne pfW2NameNext2
lbz r0, 56(r9)
cmpwi r0, 101
bne pfW2NameNext2
lbz r0, 57(r9)
cmpwi r0, 99
bne pfW2NameNext2
lbz r0, 58(r9)
cmpwi r0, 116
bne pfW2NameNext2
lbz r0, 59(r9)
cmpwi r0, 85
bne pfW2NameNext2
lbz r0, 60(r9)
cmpwi r0, 110
bne pfW2NameNext2
lbz r0, 61(r9)
cmpwi r0, 100
bne pfW2NameNext2
lbz r0, 62(r9)
cmpwi r0, 101
bne pfW2NameNext2
lbz r0, 63(r9)
cmpwi r0, 114
bne pfW2NameNext2
lbz r0, 64(r9)
cmpwi r0, 71
bne pfW2NameNext2
lbz r0, 65(r9)
cmpwi r0, 114
bne pfW2NameNext2
lbz r0, 66(r9)
cmpwi r0, 111
bne pfW2NameNext2
lbz r0, 67(r9)
cmpwi r0, 117
bne pfW2NameNext2
lbz r0, 68(r9)
cmpwi r0, 110
bne pfW2NameNext2
lbz r0, 69(r9)
cmpwi r0, 100
bne pfW2NameNext2
b pfW2NameEndStart
pfW2NameNext2:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfW2NameNext3
lbz r0, 37(r9)
cmpwi r0, 98
bne pfW2NameNext3
lbz r0, 38(r9)
cmpwi r0, 106
bne pfW2NameNext3
lbz r0, 39(r9)
cmpwi r0, 101
bne pfW2NameNext3
lbz r0, 40(r9)
cmpwi r0, 99
bne pfW2NameNext3
lbz r0, 41(r9)
cmpwi r0, 116
bne pfW2NameNext3
lbz r0, 42(r9)
cmpwi r0, 68
bne pfW2NameNext3
lbz r0, 43(r9)
cmpwi r0, 97
bne pfW2NameNext3
lbz r0, 44(r9)
cmpwi r0, 116
bne pfW2NameNext3
lbz r0, 45(r9)
cmpwi r0, 97
bne pfW2NameNext3
lbz r0, 46(r9)
cmpwi r0, 47
bne pfW2NameNext3
lbz r0, 47(r9)
cmpwi r0, 67
bne pfW2NameNext3
lbz r0, 48(r9)
cmpwi r0, 111
bne pfW2NameNext3
lbz r0, 49(r9)
cmpwi r0, 117
bne pfW2NameNext3
lbz r0, 50(r9)
cmpwi r0, 114
bne pfW2NameNext3
lbz r0, 51(r9)
cmpwi r0, 115
bne pfW2NameNext3
lbz r0, 52(r9)
cmpwi r0, 101
bne pfW2NameNext3
lbz r0, 53(r9)
cmpwi r0, 83
bne pfW2NameNext3
lbz r0, 54(r9)
cmpwi r0, 101
bne pfW2NameNext3
lbz r0, 55(r9)
cmpwi r0, 108
bne pfW2NameNext3
lbz r0, 56(r9)
cmpwi r0, 101
bne pfW2NameNext3
lbz r0, 57(r9)
cmpwi r0, 99
bne pfW2NameNext3
lbz r0, 58(r9)
cmpwi r0, 116
bne pfW2NameNext3
lbz r0, 59(r9)
cmpwi r0, 87
bne pfW2NameNext3
lbz r0, 60(r9)
cmpwi r0, 97
bne pfW2NameNext3
lbz r0, 61(r9)
cmpwi r0, 118
bne pfW2NameNext3
lbz r0, 62(r9)
cmpwi r0, 101
bne pfW2NameNext3
lbz r0, 63(r9)
cmpwi r0, 85
bne pfW2NameNext3
lbz r0, 64(r9)
cmpwi r0, 110
bne pfW2NameNext3
lbz r0, 65(r9)
cmpwi r0, 100
bne pfW2NameNext3
lbz r0, 66(r9)
cmpwi r0, 101
bne pfW2NameNext3
lbz r0, 67(r9)
cmpwi r0, 114
bne pfW2NameNext3
lbz r0, 68(r9)
cmpwi r0, 71
bne pfW2NameNext3
lbz r0, 69(r9)
cmpwi r0, 114
bne pfW2NameNext3
lbz r0, 70(r9)
cmpwi r0, 111
bne pfW2NameNext3
lbz r0, 71(r9)
cmpwi r0, 117
bne pfW2NameNext3
lbz r0, 72(r9)
cmpwi r0, 110
bne pfW2NameNext3
lbz r0, 73(r9)
cmpwi r0, 100
bne pfW2NameNext3
b pfW2NameEndStart
pfW2NameNext3:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfW2NameNext4
lbz r0, 37(r9)
cmpwi r0, 98
bne pfW2NameNext4
lbz r0, 38(r9)
cmpwi r0, 106
bne pfW2NameNext4
lbz r0, 39(r9)
cmpwi r0, 101
bne pfW2NameNext4
lbz r0, 40(r9)
cmpwi r0, 99
bne pfW2NameNext4
lbz r0, 41(r9)
cmpwi r0, 116
bne pfW2NameNext4
lbz r0, 42(r9)
cmpwi r0, 68
bne pfW2NameNext4
lbz r0, 43(r9)
cmpwi r0, 97
bne pfW2NameNext4
lbz r0, 44(r9)
cmpwi r0, 116
bne pfW2NameNext4
lbz r0, 45(r9)
cmpwi r0, 97
bne pfW2NameNext4
lbz r0, 46(r9)
cmpwi r0, 47
bne pfW2NameNext4
lbz r0, 47(r9)
cmpwi r0, 67
bne pfW2NameNext4
lbz r0, 48(r9)
cmpwi r0, 111
bne pfW2NameNext4
lbz r0, 49(r9)
cmpwi r0, 117
bne pfW2NameNext4
lbz r0, 50(r9)
cmpwi r0, 114
bne pfW2NameNext4
lbz r0, 51(r9)
cmpwi r0, 115
bne pfW2NameNext4
lbz r0, 52(r9)
cmpwi r0, 101
bne pfW2NameNext4
lbz r0, 53(r9)
cmpwi r0, 83
bne pfW2NameNext4
lbz r0, 54(r9)
cmpwi r0, 101
bne pfW2NameNext4
lbz r0, 55(r9)
cmpwi r0, 108
bne pfW2NameNext4
lbz r0, 56(r9)
cmpwi r0, 101
bne pfW2NameNext4
lbz r0, 57(r9)
cmpwi r0, 99
bne pfW2NameNext4
lbz r0, 58(r9)
cmpwi r0, 116
bne pfW2NameNext4
lbz r0, 59(r9)
cmpwi r0, 87
bne pfW2NameNext4
b pfW2NameEndStart
pfW2NameNext4:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfW2NameNext5
lbz r0, 37(r9)
cmpwi r0, 98
bne pfW2NameNext5
lbz r0, 38(r9)
cmpwi r0, 106
bne pfW2NameNext5
lbz r0, 39(r9)
cmpwi r0, 101
bne pfW2NameNext5
lbz r0, 40(r9)
cmpwi r0, 99
bne pfW2NameNext5
lbz r0, 41(r9)
cmpwi r0, 116
bne pfW2NameNext5
lbz r0, 42(r9)
cmpwi r0, 68
bne pfW2NameNext5
lbz r0, 43(r9)
cmpwi r0, 97
bne pfW2NameNext5
lbz r0, 44(r9)
cmpwi r0, 116
bne pfW2NameNext5
lbz r0, 45(r9)
cmpwi r0, 97
bne pfW2NameNext5
lbz r0, 46(r9)
cmpwi r0, 47
bne pfW2NameNext5
lbz r0, 47(r9)
cmpwi r0, 77
bne pfW2NameNext5
lbz r0, 48(r9)
cmpwi r0, 105
bne pfW2NameNext5
lbz r0, 49(r9)
cmpwi r0, 110
bne pfW2NameNext5
lbz r0, 50(r9)
cmpwi r0, 105
bne pfW2NameNext5
lbz r0, 51(r9)
cmpwi r0, 97
bne pfW2NameNext5
lbz r0, 52(r9)
cmpwi r0, 116
bne pfW2NameNext5
lbz r0, 53(r9)
cmpwi r0, 117
bne pfW2NameNext5
lbz r0, 54(r9)
cmpwi r0, 114
bne pfW2NameNext5
lbz r0, 55(r9)
cmpwi r0, 101
bne pfW2NameNext5
b pfW2NameEndStart
pfW2NameNext5:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfW2NameNext6
lbz r0, 37(r9)
cmpwi r0, 98
bne pfW2NameNext6
lbz r0, 38(r9)
cmpwi r0, 106
bne pfW2NameNext6
lbz r0, 39(r9)
cmpwi r0, 101
bne pfW2NameNext6
lbz r0, 40(r9)
cmpwi r0, 99
bne pfW2NameNext6
lbz r0, 41(r9)
cmpwi r0, 116
bne pfW2NameNext6
lbz r0, 42(r9)
cmpwi r0, 68
bne pfW2NameNext6
lbz r0, 43(r9)
cmpwi r0, 97
bne pfW2NameNext6
lbz r0, 44(r9)
cmpwi r0, 116
bne pfW2NameNext6
lbz r0, 45(r9)
cmpwi r0, 97
bne pfW2NameNext6
lbz r0, 46(r9)
cmpwi r0, 47
bne pfW2NameNext6
lbz r0, 47(r9)
cmpwi r0, 70
bne pfW2NameNext6
lbz r0, 48(r9)
cmpwi r0, 97
bne pfW2NameNext6
lbz r0, 49(r9)
cmpwi r0, 105
bne pfW2NameNext6
lbz r0, 50(r9)
cmpwi r0, 114
bne pfW2NameNext6
lbz r0, 51(r9)
cmpwi r0, 121
bne pfW2NameNext6
lbz r0, 52(r9)
cmpwi r0, 80
bne pfW2NameNext6
lbz r0, 53(r9)
cmpwi r0, 114
bne pfW2NameNext6
lbz r0, 54(r9)
cmpwi r0, 105
bne pfW2NameNext6
lbz r0, 55(r9)
cmpwi r0, 110
bne pfW2NameNext6
lbz r0, 56(r9)
cmpwi r0, 99
bne pfW2NameNext6
lbz r0, 57(r9)
cmpwi r0, 101
bne pfW2NameNext6
lbz r0, 58(r9)
cmpwi r0, 115
bne pfW2NameNext6
lbz r0, 59(r9)
cmpwi r0, 115
bne pfW2NameNext6
b pfW2NameEndStart
pfW2NameNext6:
b pfPipeCall
pfW2NameEndStart:
addi r10, r9, 36
li r11, 64
pfW2NameEnd:
lbz r0, 0(r10)
cmpwi r0, 0
beq pfW2Matrix
addi r10, r10, 1
addi r11, r11, -1
cmpwi r11, 0
bgt pfW2NameEnd
b pfPipeCall
pfW2Matrix:
addi r10, r10, 4
rlwinm r10, r10, 0, 0, 29
lwz r11, 12(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfPipeCall
lwz r11, 28(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfPipeCall
lwz r11, 44(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfPipeCall
lwz r11, 12(r10)
lis r0, 0x453B
ori r0, r0, 0x8000
cmplw r11, r0
blt pfRoadFound
lis r0, 0x4633
ori r0, r0, 0xB000
cmplw r11, r0
bgt pfRoadFound
lwz r11, 28(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x453B
ori r0, r0, 0x8000
cmplw r11, r0
bgt pfRoadFound
lwz r11, 44(r10)
cmpwi r11, 0
bge pfRoadFound
rlwinm r11, r11, 0, 1, 31
lis r0, 0x447A
ori r0, r0, 0x0000
cmplw r11, r0
blt pfRoadFound
lis r0, 0x4604
ori r0, r0, 0xD000
cmplw r11, r0
bgt pfRoadFound
b pfPipeCall
pfPipeW1Names:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfPipeRoadCheck
lbz r0, 37(r9)
cmpwi r0, 98
bne pfPipeRoadCheck
lbz r0, 38(r9)
cmpwi r0, 106
bne pfPipeRoadCheck
lbz r0, 39(r9)
cmpwi r0, 101
bne pfPipeRoadCheck
lbz r0, 40(r9)
cmpwi r0, 99
bne pfPipeRoadCheck
lbz r0, 41(r9)
cmpwi r0, 116
bne pfPipeRoadCheck
lbz r0, 42(r9)
cmpwi r0, 68
bne pfPipeRoadCheck
lbz r0, 43(r9)
cmpwi r0, 97
bne pfPipeRoadCheck
lbz r0, 44(r9)
cmpwi r0, 116
bne pfPipeRoadCheck
lbz r0, 45(r9)
cmpwi r0, 97
bne pfPipeRoadCheck
lbz r0, 46(r9)
cmpwi r0, 47
bne pfPipeRoadCheck
lbz r0, 47(r9)
cmpwi r0, 82
bne pfPipeRoadCheck
lbz r0, 48(r9)
cmpwi r0, 111
bne pfPipeRoadCheck
lbz r0, 49(r9)
cmpwi r0, 117
bne pfPipeRoadCheck
lbz r0, 50(r9)
cmpwi r0, 116
bne pfPipeRoadCheck
lbz r0, 51(r9)
cmpwi r0, 101
bne pfPipeRoadCheck
lbz r0, 52(r9)
cmpwi r0, 68
bne pfPipeRoadCheck
lbz r0, 53(r9)
cmpwi r0, 111
bne pfPipeRoadCheck
lbz r0, 54(r9)
cmpwi r0, 107
bne pfPipeRoadCheck
lbz r0, 55(r9)
cmpwi r0, 97
bne pfPipeRoadCheck
lbz r0, 56(r9)
cmpwi r0, 110
bne pfPipeRoadCheck
b pfPipeFound
pfPipeRoadCheck:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfPipePointCheck
lbz r0, 37(r9)
cmpwi r0, 98
bne pfPipePointCheck
lbz r0, 38(r9)
cmpwi r0, 106
bne pfPipePointCheck
lbz r0, 39(r9)
cmpwi r0, 101
bne pfPipePointCheck
lbz r0, 40(r9)
cmpwi r0, 99
bne pfPipePointCheck
lbz r0, 41(r9)
cmpwi r0, 116
bne pfPipePointCheck
lbz r0, 42(r9)
cmpwi r0, 68
bne pfPipePointCheck
lbz r0, 43(r9)
cmpwi r0, 97
bne pfPipePointCheck
lbz r0, 44(r9)
cmpwi r0, 116
bne pfPipePointCheck
lbz r0, 45(r9)
cmpwi r0, 97
bne pfPipePointCheck
lbz r0, 46(r9)
cmpwi r0, 47
bne pfPipePointCheck
lbz r0, 47(r9)
cmpwi r0, 67
bne pfPipePointCheck
lbz r0, 48(r9)
cmpwi r0, 111
bne pfPipePointCheck
lbz r0, 49(r9)
cmpwi r0, 117
bne pfPipePointCheck
lbz r0, 50(r9)
cmpwi r0, 114
bne pfPipePointCheck
lbz r0, 51(r9)
cmpwi r0, 115
bne pfPipePointCheck
lbz r0, 52(r9)
cmpwi r0, 101
bne pfPipePointCheck
lbz r0, 53(r9)
cmpwi r0, 83
bne pfPipePointCheck
lbz r0, 54(r9)
cmpwi r0, 101
bne pfPipePointCheck
lbz r0, 55(r9)
cmpwi r0, 108
bne pfPipePointCheck
lbz r0, 56(r9)
cmpwi r0, 101
bne pfPipePointCheck
lbz r0, 57(r9)
cmpwi r0, 99
bne pfPipePointCheck
lbz r0, 58(r9)
cmpwi r0, 116
bne pfPipePointCheck
lbz r0, 59(r9)
cmpwi r0, 82
bne pfPipePointCheck
lbz r0, 60(r9)
cmpwi r0, 111
bne pfPipePointCheck
lbz r0, 61(r9)
cmpwi r0, 97
bne pfPipePointCheck
lbz r0, 62(r9)
cmpwi r0, 100
bne pfPipePointCheck
b pfPipeRouteBounds
pfPipePointCheck:
lbz r0, 36(r9)
cmpwi r0, 79
bne pfPipeCall
lbz r0, 37(r9)
cmpwi r0, 98
bne pfPipeCall
lbz r0, 38(r9)
cmpwi r0, 106
bne pfPipeCall
lbz r0, 39(r9)
cmpwi r0, 101
bne pfPipeCall
lbz r0, 40(r9)
cmpwi r0, 99
bne pfPipeCall
lbz r0, 41(r9)
cmpwi r0, 116
bne pfPipeCall
lbz r0, 42(r9)
cmpwi r0, 68
bne pfPipeCall
lbz r0, 43(r9)
cmpwi r0, 97
bne pfPipeCall
lbz r0, 44(r9)
cmpwi r0, 116
bne pfPipeCall
lbz r0, 45(r9)
cmpwi r0, 97
bne pfPipeCall
lbz r0, 46(r9)
cmpwi r0, 47
bne pfPipeCall
lbz r0, 47(r9)
cmpwi r0, 67
bne pfPipeCall
lbz r0, 48(r9)
cmpwi r0, 111
bne pfPipeCall
lbz r0, 49(r9)
cmpwi r0, 117
bne pfPipeCall
lbz r0, 50(r9)
cmpwi r0, 114
bne pfPipeCall
lbz r0, 51(r9)
cmpwi r0, 115
bne pfPipeCall
lbz r0, 52(r9)
cmpwi r0, 101
bne pfPipeCall
lbz r0, 53(r9)
cmpwi r0, 83
bne pfPipeCall
lbz r0, 54(r9)
cmpwi r0, 101
bne pfPipeCall
lbz r0, 55(r9)
cmpwi r0, 108
bne pfPipeCall
lbz r0, 56(r9)
cmpwi r0, 101
bne pfPipeCall
lbz r0, 57(r9)
cmpwi r0, 99
bne pfPipeCall
lbz r0, 58(r9)
cmpwi r0, 116
bne pfPipeCall
lbz r0, 59(r9)
cmpwi r0, 80
bne pfPipeCall
lbz r0, 60(r9)
cmpwi r0, 111
bne pfPipeCall
lbz r0, 61(r9)
cmpwi r0, 105
bne pfPipeCall
lbz r0, 62(r9)
cmpwi r0, 110
bne pfPipeCall
lbz r0, 63(r9)
cmpwi r0, 116
bne pfPipeCall
lbz r0, 64(r9)
cmpwi r0, 0
bne pfPipeCall
pfPipeRouteBounds:
; World 1 only: retain VR visibility on the local routes. Remote road
; segments still obey native rejection, just as in the successful grip test.
; Bonus-map filtering is deliberately unchanged.
lis r10, pfState@ha
addi r10, r10, pfState@l
lwz r10, 12(r10)
cmpwi r10, 1
bne pfPipeCall
addi r10, r9, 36
li r11, 64
pfRoadNameEnd:
lbz r0, 0(r10)
cmpwi r0, 0
beq pfRoadMatrix
addi r10, r10, 1
addi r11, r11, -1
cmpwi r11, 0
bgt pfRoadNameEnd
b pfPipeCall
pfRoadMatrix:
addi r10, r10, 4
rlwinm r10, r10, 0, 0, 29
; Validate all components first: unknown/nonfinite positions fail open.
lwz r11, 12(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000 ; 100000.0
cmplw r11, r0
bgt pfPipeCall
lwz r11, 28(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000 ; 100000.0
cmplw r11, r0
bgt pfPipeCall
lwz r11, 44(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000 ; 100000.0
cmplw r11, r0
bgt pfPipeCall
; Generous protected World-1 envelope around verified nodes and rails:
; X [-5000,5000], Y [-2000,2000], Z [0,5000]. Not a draw-distance cutoff:
; outside it only the extra VR rescue is disabled; native acceptance wins.
lwz r11, 12(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x459C
ori r0, r0, 0x4000 ; 5000.0
cmplw r11, r0
bgt pfRoadFound
lwz r11, 28(r10)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x44FA ; 2000.0
cmplw r11, r0
bgt pfRoadFound
lwz r11, 44(r10)
cmpwi r11, 0
blt pfRoadFound
lis r0, 0x459C
ori r0, r0, 0x4000
cmplw r11, r0
bgt pfRoadFound
b pfPipeCall
pfRoadFound:
lwz r11, 12(r12)
addi r11, r11, 1
stw r11, 12(r12)
pfPipeFound:

li r0, 1
stw r0, 0(r12)
lwz r11, 4(r12)
addi r11, r11, 1
stw r11, 4(r12)
pfPipeCall:
bl pfPipeNative
lis r12, pfPipeState@ha
addi r12, r12, pfPipeState@l
lwz r0, 8(r1)
stw r0, 0(r12)
lwz r0, 0x24(r1)
mtlr r0
addi r1, r1, 0x20
blr
pfPipeState:
.int 0
.int 0
.int 0
.int 0 ; remote World-1 road/point matches, separate from pipe body matches
0x0242F938 = pfPipeNative:
0x0242F984 = bla pfPipeActor
pfEffectDrawProbe:
stwu r1, -0x40(r1)
stw r0, 8(r1)
.int 0x7C000026
stw r0, 12(r1)
stw r3, 16(r1)
stw r4, 20(r1)
stw r5, 24(r1)
stw r6, 28(r1)
stw r7, 32(r1)
stw r8, 36(r1)
stw r9, 40(r1)
stw r10, 44(r1)
stw r11, 48(r1)
stw r12, 52(r1)
lis r12, pfEffectDrawState@ha
addi r12, r12, pfEffectDrawState@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
lis r10, mrSceneClass@ha
lwz r10, mrSceneClass@l(r10)
lis r0, 0x1027
ori r0, r0, 0xF388
cmpw r10, r0
bne pfEffectDrawDone
lwz r11, 4(r12)
addi r11, r11, 1
stw r11, 4(r12)
lwz r9, 0x130(r4)
cmpwi r9, 0
beq pfEffectDrawDone
lis r11, pfEffectDrawTable@ha
addi r11, r11, pfEffectDrawTable@l
srwi r8, r9, 4
rlwinm r8, r8, 6, 18, 25
li r7, 8
pfEffectDrawProbeSlot:
add r5, r11, r8
lwz r0, 0(r5)
cmpw r0, r9
beq pfEffectDrawRecord
cmpwi r0, 0
beq pfEffectDrawRecord
addi r8, r8, 64
rlwinm r8, r8, 0, 18, 25
addi r7, r7, -1
cmpwi r7, 0
bgt pfEffectDrawProbeSlot
lwz r11, 8(r12)
addi r11, r11, 1
stw r11, 8(r12)
b pfEffectDrawDone
pfEffectDrawRecord:
stw r9, 0(r5)
lwz r11, 4(r5)
addi r11, r11, 1
stw r11, 4(r5)
stw r4, 8(r5)
lwz r0, 0(r9)
stw r0, 12(r5)
lwz r0, 4(r9)
stw r0, 16(r5)
lwz r0, 0x38(r9)
stw r0, 20(r5)
lwz r0, 0x2E8(r9)
stw r0, 24(r5)
lwz r0, 0x3C(r9)
stw r0, 28(r5)
lwz r0, 0x2F8(r4)
stw r0, 32(r5)
lwz r0, 0x64(r4)
stw r0, 36(r5)
lwz r0, 0x2FC(r4)
stw r0, 40(r5)
lwz r0, 0x70(r4)
stw r0, 44(r5)
lis r12, pfState@ha
addi r12, r12, pfState@l
lwz r0, 12(r12)
stw r0, 48(r5)
lwz r0, 8(r12)
stw r0, 52(r5)
lwz r0, 28(r1) ; original r6: parent/child pass
stw r0, 56(r5)
lwz r0, 0xD4(r4) ; emitter matrix translation Y
stw r0, 60(r5)
pfEffectDrawDone:
lwz r3, 16(r1)
lwz r4, 20(r1)
lwz r5, 24(r1)
lwz r6, 28(r1)
lwz r7, 32(r1)
lwz r8, 36(r1)
lwz r9, 40(r1)
lwz r10, 44(r1)
lwz r11, 48(r1)
lwz r12, 52(r1)
lwz r0, 12(r1)
.int 0x7C0FF120
lwz r0, 8(r1)
addi r1, r1, 0x40
stwu r1, -0x70(r1)
b pfEffectDrawContinue
pfEffectDrawState:
.int 0
.int 0
.int 0
pfEffectDrawTable:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
0x0253F524 = pfEffectDrawContinue:
0x0253F520 = ba pfEffectDrawProbe
pfFlareStats:
.int 0
.int 0
.int 0
pfToadLampStats:
.int 0
pfEffectSubmit:
stwu r1, -0xA0(r1)
mflr r0
stw r0, 0xA4(r1)
stw r3, 8(r1)
stw r4, 12(r1)
stw r5, 16(r1)
stw r6, 20(r1)
stw r7, 24(r1)
stw r8, 28(r1)
stw r9, 32(r1)
stw r20, 40(r1)
stw r21, 44(r1)
stw r22, 48(r1)
stw r23, 52(r1)
stw r24, 56(r1)
stw r25, 60(r1)
stw r26, 64(r1)
stw r27, 68(r1)
stw r28, 72(r1)
stw r29, 76(r1)
stw r30, 80(r1)
stw r31, 84(r1)
; Captain Toad head ray: exact resource, effective FP, fresh nearby anchor.
lis r12, mrSceneClass@ha
lwz r12, mrSceneClass@l(r12)
lis r11, 0x1032
ori r11, r11, 0x86DC
cmpw r12, r11
bne pfToadLampContinue
lwz r10, 0x130(r31)
cmpwi r10, 0
beq pfToadLampContinue
lwz r11, 0(r10)
cmpwi r11, 0
bne pfToadLampContinue
lwz r11, 4(r10)
cmpwi r11, 0
bne pfToadLampContinue
lwz r11, 0x2E8(r10)
cmpwi r11, -1
bne pfToadLampContinue
lwz r11, 0x38(r10)
cmplwi r11, 0xD162
beq pfToadLampMode
cmplwi r11, 0xD169
bne pfToadLampContinue
pfToadLampMode:
lis r12, mtControl@ha
lwz r11, mtControl@l(r12)
cmpwi r11, 1
bne pfToadLampContinue
lis r12, rrSlot@ha
lwz r11, rrSlot@l(r12)
cmplwi r11, 1
bgt pfToadLampContinue
mulli r11, r11, 2
lis r12, rrEye@ha
lwz r10, rrEye@l(r12)
cmplwi r10, 1
bgt pfToadLampContinue
add r11, r11, r10
mulli r11, r11, 4
lis r12, mtNearState@ha
addi r12, r12, mtNearState@l
add r12, r12, r11
lwz r11, 0(r12)
cmpwi r11, 1
bne pfToadLampContinue
lis r12, mtHideModel@ha
addi r12, r12, mtHideModel@l
lwz r11, 16(r12)
cmplwi r11, 1
blt pfToadLampContinue
cmplwi r11, 17
bgt pfToadLampContinue
lwz r11, 12(r12)
lwz r10, 4(r12)
subf r11, r10, r11
cmplwi r11, 2
bgt pfToadLampContinue
; Save full FPR precision; original draw arguments are still in r3..r9.
stwu r1, -0x20(r1)
stfd f0, 8(r1)
stfd f1, 16(r1)
lis r12, mrEyeTarget@ha
addi r12, r12, mrEyeTarget@l
lfs f0, 0xC4(r31)
lfs f1, 0(r12)
fsubs f0, f0, f1
stfs f0, 24(r1)
lwz r11, 24(r1)
rlwinm r11, r11, 0, 1, 31
lis r10, 0x4348
cmplw r11, r10
bgt pfToadLampFar
lfs f0, 0xD4(r31)
lfs f1, 4(r12)
fsubs f0, f0, f1
stfs f0, 24(r1)
lwz r11, 24(r1)
rlwinm r11, r11, 0, 1, 31
lis r10, 0x4348
cmplw r11, r10
bgt pfToadLampFar
lfs f0, 0xE4(r31)
lfs f1, 8(r12)
fsubs f0, f0, f1
stfs f0, 24(r1)
lwz r11, 24(r1)
rlwinm r11, r11, 0, 1, 31
lis r10, 0x4348
cmplw r11, r10
bgt pfToadLampFar
li r10, 1
b pfToadLampRestore
pfToadLampFar:
li r10, 0
pfToadLampRestore:
lfd f0, 8(r1)
lfd f1, 16(r1)
addi r1, r1, 0x20
cmpwi r10, 0
beq pfToadLampContinue
lis r12, pfToadLampStats@ha
lwz r11, pfToadLampStats@l(r12)
addi r11, r11, 1
stw r11, pfToadLampStats@l(r12)
; Keep the native full feedback binding even when the colour draw is skipped.
cmpwi r8, 0
beq pfEffectDone
mr r5, r4
mr r4, r8
bl pfEffectBindNative
b pfEffectDone
pfToadLampContinue:
; ScreenLensFlareRight only, in StageScene. No map-state dependency.
lis r12, mrSceneClass@ha
lwz r12, mrSceneClass@l(r12)
lis r11, 0x1032
ori r11, r11, 0x86DC
cmpw r12, r11
beq pfScreenFlareStage
lis r11, 0x1027
ori r11, r11, 0xF388
cmpw r12, r11
bne pfScreenFlareContinue
lis r10, pfFlareStats@ha
addi r10, r10, pfFlareStats@l
lwz r11, 8(r10)
addi r11, r11, 1
stw r11, 8(r10)
b pfScreenFlareDefinition
pfScreenFlareStage:
pfScreenFlareDefinition:
lwz r10, 0x130(r31)
cmpwi r10, 0
beq pfScreenFlareContinue
lwz r11, 0(r10)
cmpwi r11, 0
bne pfScreenFlareContinue
lwz r11, 4(r10)
cmpwi r11, 0
bne pfScreenFlareContinue
lwz r11, 0x2E8(r10)
cmpwi r11, -1
bne pfScreenFlareContinue
lwz r11, 0x38(r10)
; Select the resource set by exact scene class; preserve sibling flare sets.
lis r10, 0x1027
ori r10, r10, 0xF388
cmpw r12, r10
beq pfScreenFlareMap
cmplwi r11, 0xD24F
beq pfScreenFlareSkip
cmplwi r11, 0xD259
beq pfScreenFlareSkip
cmplwi r11, 0xD267
beq pfScreenFlareSkip
b pfScreenFlareContinue
pfScreenFlareMap:
cmplwi r11, 0xE258
beq pfScreenFlareSkip
cmplwi r11, 0xE262
beq pfScreenFlareSkip
cmplwi r11, 0xE270
beq pfScreenFlareSkip
b pfScreenFlareContinue
pfScreenFlareSkip:
lis r10, pfFlareStats@ha
addi r10, r10, pfFlareStats@l
lis r11, 0x1027
ori r11, r11, 0xF388
cmpw r12, r11
bne pfScreenFlareCount
addi r10, r10, 4
pfScreenFlareCount:
lwz r11, 0(r10)
addi r11, r11, 1
stw r11, 0(r10)
; Preserve the full buffer binding required by native particle feedback.
; r8==0 means the caller already bound it; never filter the simulation.
cmpwi r8, 0
beq pfEffectDone
mr r5, r4
mr r4, r8
bl pfEffectBindNative
b pfEffectDone
pfScreenFlareContinue:
lis r12, mrSceneClass@ha
lwz r12, mrSceneClass@l(r12)
lis r11, 0x1027
ori r11, r11, 0xF388
cmpw r12, r11
bne pfEffectOriginal
; All four call sites retain the emitter in native r31.
lwz r10, 0x130(r31)
cmpwi r10, 0
beq pfEffectOriginal
lis r12, pfState@ha
addi r12, r12, pfState@l
lwz r11, 12(r12)
cmpwi r11, 2
bne pfW2FairyMiss
lwz r11, 0x2E8(r10)
cmpwi r11, -1
bne pfW2FairyMiss
lwz r11, 0(r10)
lis r12, 0x0000
ori r12, r12, 0x0001
cmpw r11, r12
bne pfW2FairyNext0
lwz r11, 4(r10)
lis r12, 0x0038
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext0
lwz r11, 56(r10)
lis r12, 0x0000
ori r12, r12, 0x20B9
cmpw r11, r12
bne pfW2FairyNext0
b pfW2FairyPosition
pfW2FairyNext0:
lwz r11, 0(r10)
lis r12, 0x0000
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext1
lwz r11, 4(r10)
lis r12, 0x0080
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext1
lwz r11, 56(r10)
lis r12, 0x0000
ori r12, r12, 0x20BE
cmpw r11, r12
bne pfW2FairyNext1
b pfW2FairyPosition
pfW2FairyNext1:
lwz r11, 0(r10)
lis r12, 0x0000
ori r12, r12, 0x0001
cmpw r11, r12
bne pfW2FairyNext2
lwz r11, 4(r10)
lis r12, 0x0038
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext2
lwz r11, 56(r10)
lis r12, 0x0000
ori r12, r12, 0xA661
cmpw r11, r12
bne pfW2FairyNext2
b pfW2FairyPosition
pfW2FairyNext2:
lwz r11, 0(r10)
lis r12, 0x0000
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext3
lwz r11, 4(r10)
lis r12, 0x0080
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext3
lwz r11, 56(r10)
lis r12, 0x0000
ori r12, r12, 0xA666
cmpw r11, r12
bne pfW2FairyNext3
b pfW2FairyPosition
pfW2FairyNext3:
lwz r11, 0(r10)
lis r12, 0x0000
ori r12, r12, 0x0001
cmpw r11, r12
bne pfW2FairyNext4
lwz r11, 4(r10)
lis r12, 0x0038
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext4
lwz r11, 56(r10)
lis r12, 0x0000
ori r12, r12, 0x690C
cmpw r11, r12
bne pfW2FairyNext4
b pfW2FairyPosition
pfW2FairyNext4:
lwz r11, 0(r10)
lis r12, 0x0000
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext5
lwz r11, 4(r10)
lis r12, 0x0080
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext5
lwz r11, 56(r10)
lis r12, 0x0000
ori r12, r12, 0x6911
cmpw r11, r12
bne pfW2FairyNext5
b pfW2FairyPosition
pfW2FairyNext5:
lwz r11, 0(r10)
lis r12, 0x0000
ori r12, r12, 0x0001
cmpw r11, r12
bne pfW2FairyNext6
lwz r11, 4(r10)
lis r12, 0x0038
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext6
lwz r11, 56(r10)
lis r12, 0x0000
ori r12, r12, 0xD5DD
cmpw r11, r12
bne pfW2FairyNext6
b pfW2FairyPosition
pfW2FairyNext6:
lwz r11, 0(r10)
lis r12, 0x0000
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext7
lwz r11, 4(r10)
lis r12, 0x0080
ori r12, r12, 0x0000
cmpw r11, r12
bne pfW2FairyNext7
lwz r11, 56(r10)
lis r12, 0x0000
ori r12, r12, 0xD5E2
cmpw r11, r12
bne pfW2FairyNext7
b pfW2FairyPosition
pfW2FairyNext7:
b pfW2FairyMiss
pfW2FairyPosition:
lwz r11, 196(r31)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfW2FairyMiss
lwz r11, 212(r31)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfW2FairyMiss
lwz r11, 228(r31)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x47C3
ori r0, r0, 0x5000
cmplw r11, r0
bgt pfW2FairyMiss
lwz r11, 196(r31)
lis r0, 0x453B
ori r0, r0, 0x8000
cmplw r11, r0
blt pfW2FairyHide
lis r0, 0x4633
ori r0, r0, 0xB000
cmplw r11, r0
bgt pfW2FairyHide
lwz r11, 212(r31)
rlwinm r11, r11, 0, 1, 31
lis r0, 0x453B
ori r0, r0, 0x8000
cmplw r11, r0
bgt pfW2FairyHide
lwz r11, 228(r31)
cmpwi r11, 0
bge pfW2FairyHide
rlwinm r11, r11, 0, 1, 31
lis r0, 0x447A
ori r0, r0, 0x0000
cmplw r11, r0
blt pfW2FairyHide
lis r0, 0x4604
ori r0, r0, 0xD000
cmplw r11, r0
bgt pfW2FairyHide
b pfW2FairyMiss
pfW2FairyHide:
cmpwi r8, 0
beq pfEffectDone
mr r5, r4
mr r4, r8
bl pfEffectBindNative
b pfEffectDone
pfW2FairyMiss:
lwz r11, 0x2E8(r10)
cmpwi r11, -1
bne pfAttachedMiss
lis r20, pfAttachedIdentities@ha
addi r20, r20, pfAttachedIdentities@l
li r21, 16
pfAttachedFind:
lwz r11, 0x38(r10)
lwz r12, 8(r20)
cmpw r11, r12
bne pfAttachedNext
lwz r11, 0(r10)
lwz r12, 0(r20)
cmpw r11, r12
bne pfAttachedNext
lwz r11, 4(r10)
lwz r12, 4(r20)
cmpw r11, r12
beq pfAttachedPosition
pfAttachedNext:
addi r20, r20, 12
addi r21, r21, -1
cmpwi r21, 0
bgt pfAttachedFind
b pfAttachedMiss
pfAttachedPosition:
lis r12, pfState@ha
addi r12, r12, pfState@l
lwz r22, 8(r12)
cmplwi r22, 1
blt pfEffectOriginal
cmplwi r22, 3
bgt pfEffectOriginal
lwz r11, 12(r12)
cmplwi r11, 9
blt pfEffectOriginal
cmplwi r11, 12
bgt pfEffectOriginal
lwz r11, 0xD4(r31)
lis r12, 0x46AB
ori r12, r12, 0xE000
cmplw r11, r12
blt pfEffectOriginal
lis r12, 0x470E
ori r12, r12, 0x9400
cmplw r11, r12
bgt pfEffectOriginal
lis r12, 0x46D0
ori r12, r12, 0x3400
cmplw r11, r12
blt pfAttachedLower
lis r12, 0x46F7
ori r12, r12, 0xDA00
cmplw r11, r12
blt pfAttachedMiddle
li r11, 3
b pfAttachedCompare
pfAttachedLower:
li r11, 1
b pfAttachedCompare
pfAttachedMiddle:
li r11, 2
pfAttachedCompare:
cmpw r11, r22
beq pfEffectOriginal
lis r12, pfAttachedState@ha
addi r12, r12, pfAttachedState@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
lwz r11, 4(r12)
add r11, r11, r7
stw r11, 4(r12)
; Skip only this colour draw; preserve the exact native attribute binding.
; The r8=0 feedback path already has its complete source bound.
cmpwi r8, 0
beq pfEffectDone
mr r5, r4
mr r4, r8
bl pfEffectBindNative
b pfEffectDone
pfAttachedMiss:

lwz r11, 0(r10)
cmpwi r11, 0
bne pfEffectOriginal
lwz r11, 4(r10)
lis r12, 0x80
cmpw r11, r12
bne pfEffectOriginal
lwz r11, 0x38(r10)
lwz r12, 0x2E8(r10)
cmplwi r11, 0xA27D
bne pfEffectCheckB
cmpwi r12, 152
bne pfEffectOriginal
b pfEffectIdentified
pfEffectCheckB:
cmplwi r11, 0xA283
bne pfEffectCheckC
cmpwi r12, 153
bne pfEffectOriginal
b pfEffectIdentified
pfEffectCheckC:
cmplwi r11, 0xA289
bne pfEffectOriginal
cmpwi r12, 154
bne pfEffectOriginal
pfEffectIdentified:
lis r12, pfState@ha
addi r12, r12, pfState@l
lwz r22, 8(r12)
cmplwi r22, 3
bgt pfEffectOriginal
; Plane zero means a regular world, where ALL bonus-plane glitter is foreign.
; Reject stale/unknown world state rather than infer a plane during loading.
lwz r11, 12(r12)
cmplwi r11, 1
blt pfEffectOriginal
cmplwi r11, 12
bgt pfEffectOriginal
mr r25, r8
cmpwi r25, 0
bne pfEffectHaveBuffer
mr r25, r27
pfEffectHaveBuffer:
lis r11, 0x1000
cmplw r25, r11
blt pfEffectOriginal
lis r11, 0x5000
cmplw r25, r11
bge pfEffectOriginal
cmpwi r7, 0
beq pfEffectOriginal
add r24, r6, r7
cmplw r24, r6
blt pfEffectOriginal
cmplwi r24, 8192
bgt pfEffectOriginal
mulli r11, r24, 192
add r11, r25, r11
lis r12, 0x5000
cmplw r11, r12
bgt pfEffectOriginal
mr r23, r6
li r26, -1
li r30, 0
lis r12, pfEffectFilterState@ha
addi r12, r12, pfEffectFilterState@l
lwz r11, 0(r12)
addi r11, r11, 1
stw r11, 0(r12)
pfEffectLoop:
cmplw r23, r24
bge pfEffectFlushEnd
cmpwi r22, 0
beq pfEffectReject
mulli r11, r23, 192
add r11, r25, r11
lwz r3, 4(r11)
mr r4, r22
bl pfEffectKeepY
cmpwi r3, 0
beq pfEffectReject
cmpwi r26, -1
bne pfEffectNext
mr r26, r23
b pfEffectNext
pfEffectReject:
addi r30, r30, 1
cmpwi r26, -1
beq pfEffectNext
bl pfEffectDrawRun
li r26, -1
pfEffectNext:
addi r23, r23, 1
b pfEffectLoop
pfEffectFlushEnd:
cmpwi r26, -1
beq pfEffectRebind
bl pfEffectDrawRun
pfEffectRebind:
; Restore the full binding even after rejecting every instance. Native GPU
; feedback uses it after the colour draw, so leave simulation unfiltered.
lwz r3, 8(r1)
mr r4, r25
lwz r5, 12(r1)
lwz r6, 20(r1)
lwz r7, 24(r1)
bl pfEffectBindNative
lis r12, pfEffectFilterState@ha
addi r12, r12, pfEffectFilterState@l
lwz r11, 4(r12)
add r11, r11, r30
stw r11, 4(r12)
b pfEffectDone
pfEffectOriginal:
lwz r3, 8(r1)
lwz r4, 12(r1)
lwz r5, 16(r1)
lwz r6, 20(r1)
lwz r7, 24(r1)
lwz r8, 28(r1)
lwz r9, 32(r1)
bl pfEffectNative
pfEffectDone:
lwz r20, 40(r1)
lwz r21, 44(r1)
lwz r22, 48(r1)
lwz r23, 52(r1)
lwz r24, 56(r1)
lwz r25, 60(r1)
lwz r26, 64(r1)
lwz r27, 68(r1)
lwz r28, 72(r1)
lwz r29, 76(r1)
lwz r30, 80(r1)
lwz r31, 84(r1)
lwz r0, 0xA4(r1)
mtlr r0
addi r1, r1, 0xA0
blr
; Same stack frame as caller: save only this leaf-helper return address.
pfEffectDrawRun:
mflr r0
stw r0, 92(r1)
lwz r3, 8(r1)
lwz r4, 12(r1)
lwz r5, 16(r1)
mr r6, r26
subf r7, r26, r23
mr r8, r25
lwz r9, 32(r1)
bl pfEffectNative
lis r12, pfEffectFilterState@ha
addi r12, r12, pfEffectFilterState@l
lwz r11, 8(r12)
addi r11, r11, 1
stw r11, 8(r12)
lwz r0, 92(r1)
mtlr r0
blr
; r3=IEEE local Y, r4=active plane. Return r3=1 for unknown or same plane.
pfEffectKeepY:
cmpwi r3, 0
bge pfEffectPositiveY
rlwinm r5, r3, 0, 1, 31
lis r6, 0x44FA
cmplw r5, r6
bgt pfEffectKeep
li r6, 1
b pfEffectComparePlane
pfEffectPositiveY:
lis r5, 0x463F
ori r5, r5, 0x6800
cmplw r3, r5
bgt pfEffectKeep
lis r5, 0x4516
ori r5, r5, 0x0000
cmplw r3, r5
blt pfEffectLowerY
lis r5, 0x45E9
ori r5, r5, 0x9800
cmplw r3, r5
blt pfEffectMiddleY
li r6, 3
b pfEffectComparePlane
pfEffectLowerY:
li r6, 1
b pfEffectComparePlane
pfEffectMiddleY:
li r6, 2
pfEffectComparePlane:
cmpw r6, r4
beq pfEffectKeep
li r3, 0
blr
pfEffectKeep:
li r3, 1
blr
pfAttachedState:
.int 0
.int 0
pfAttachedIdentities:
.int 0x00000000
.int 0x00000000
.int 0x0000D162
.int 0x00000000
.int 0x00000000
.int 0x0000D169
.int 0x00000000
.int 0x00800000
.int 0x00001FD4
.int 0x00000000
.int 0x00800000
.int 0x00001FDB
.int 0x00000000
.int 0x00801080
.int 0x00007F99
.int 0x00000000
.int 0x00800000
.int 0x00007FA5
.int 0x00000000
.int 0x00801880
.int 0x00007FAA
.int 0x00000001
.int 0x00060000
.int 0x0000CF43
.int 0x00000001
.int 0x00380000
.int 0x00002AC0
.int 0x00000000
.int 0x00380000
.int 0x00002AC5
.int 0x00000000
.int 0x00801800
.int 0x000012BD
.int 0x00000000
.int 0x00801880
.int 0x00006E49
.int 0x00000000
.int 0x00080200
.int 0x00006E4F
.int 0x00000000
.int 0x00801880
.int 0x00006E54
.int 0x00000000
.int 0x00801880
.int 0x00003FA3
.int 0x00000000
.int 0x00801880
.int 0x00008759

pfEffectFilterState:
.int 0
.int 0
.int 0
0x0253F478 = pfEffectNative:
0x02543ECC = pfEffectBindNative:
0x0253F8C4 = bla pfEffectSubmit
0x0253FA98 = bla pfEffectSubmit
0x0253FAB8 = bla pfEffectSubmit
0x0253FAF4 = bla pfEffectSubmit
0x023E3AD4 = bla pfDraw

; Controller gesture state. No samples or native microphone state are modified.
mbState:
.int 0 ; active this calc
.int 0 ; last accepted controller generation
.int 0 ; repeated-generation age, saturates at four
mbVolume:
.float 3300.0 ; strong input in the game's raw microphone-volume units
mbUnitVolume:
.float 1.0

tcPadReady:
.int 0
tcButtons:
.int 0
.int 0
.int 0

[Mario3DWorld_Headlamp_EU_v0]
moduleMatches = 0xD2308838
.origin = codecave

; Use the completed first-person view only for the primary player's headlamp.
; Native position, activation, brightness, range and wall collision remain intact.
; Other executable layouts retain their native lamp until independently verified.
hlCaptureView:
lis r11, hlPose@ha
addi r11, r11, hlPose@l
lis r12, mtControl@ha
addi r12, r12, mtControl@l
lwz r0, 0(r12)
cmpwi r0, 1
bne hlCaptureInvalidate
lis r8, mrSceneClass@ha
lwz r0, mrSceneClass@l(r8)
lis r8, 0x1032
ori r8, r8, 0x86DC
cmpw r0, r8
bne hlCaptureInvalidate
; Auxiliary cameras and the second eye must not replace the player view.
cmpwi r10, 0
bne hlCaptureDone
lwz r0, 28(r12)
cmpwi r0, 1
bne hlCaptureDone
li r0, 0
stw r0, 0(r11)
stw r0, 8(r11)
lis r8, mtHideActor@ha
lwz r7, mtHideActor@l(r8)
lis r8, 0x1000
cmplw r7, r8
blt hlCaptureDone
lis r8, 0x4FFF
cmplw r7, r8
bge hlCaptureDone
andi. r0, r7, 3
bne hlCaptureDone
lwz r0, 0(r7)
lis r8, 0x1031
ori r8, r8, 0x9EF4
cmpw r0, r8
bne hlCaptureDone
stw r7, 12(r11)
; Follow the same active-model selection as the existing first-person culler.
lwz r7, 0xFC(r7)
lis r8, 0x1000
cmplw r7, r8
blt hlCaptureDone
lis r8, 0x4FFF
cmplw r7, r8
bge hlCaptureDone
andi. r0, r7, 3
bne hlCaptureDone
lwz r6, 0x18(r7)
cmplwi r6, 7
bgt hlCaptureDone
lwz r7, 0x14(r7)
lis r8, 0x1000
cmplw r7, r8
blt hlCaptureDone
lis r8, 0x4FFF
cmplw r7, r8
bge hlCaptureDone
andi. r0, r7, 3
bne hlCaptureDone
mulli r6, r6, 4
add r7, r7, r6
lwz r7, 0(r7)
lis r8, 0x1000
cmplw r7, r8
blt hlCaptureDone
lis r8, 0x4FFF
cmplw r7, r8
bge hlCaptureDone
andi. r0, r7, 3
bne hlCaptureDone
li r6, 0
hlSpotOwner:
lis r8, 0x1000
cmplw r7, r8
blt hlSpotNextOwner
lis r8, 0x4FFF
cmplw r7, r8
bge hlSpotNextOwner
andi. r0, r7, 3
bne hlSpotNextOwner
lwz r8, 0x6C(r7)
lis r5, 0x1000
cmplw r8, r5
blt hlSpotNextOwner
lis r5, 0x4FFF
cmplw r8, r5
bge hlSpotNextOwner
andi. r0, r8, 3
bne hlSpotNextOwner
lwz r0, 0x18(r8)
cmpw r0, r7
bne hlSpotNextOwner
; The captain has one spotlight and one point light. Do not steer the latter.
lwz r0, 0(r8)
cmpwi r0, 2
bne hlSpotNextOwner
lwz r4, 8(r8)
lis r5, 0x1000
cmplw r4, r5
blt hlSpotNextOwner
lis r5, 0x4FFF
cmplw r4, r5
bge hlSpotNextOwner
andi. r0, r4, 3
bne hlSpotNextOwner
li r3, 0
hlSpotScan:
lwz r8, 0(r4)
lis r5, 0x1000
cmplw r8, r5
blt hlSpotScanNext
lis r5, 0x4FFF
cmplw r8, r5
bge hlSpotScanNext
andi. r0, r8, 3
bne hlSpotScanNext
lwz r0, 0(r8)
lis r5, 0x1036
ori r5, r5, 0xEAA4
cmpw r0, r5
bne hlSpotScanNext
; Authored headlamp offset (0,80,0) and rotation (-90,0,0).
lwz r0, 0x2C(r8)
cmpwi r0, 0
bne hlSpotScanNext
lwz r0, 0x30(r8)
lis r5, 0x42A0
cmpw r0, r5
bne hlSpotScanNext
lwz r0, 0x34(r8)
cmpwi r0, 0
bne hlSpotScanNext
lwz r0, 0x38(r8)
lis r5, 0xC2B4
cmpw r0, r5
bne hlSpotScanNext
lwz r0, 0x3C(r8)
cmpwi r0, 0
bne hlSpotScanNext
lwz r0, 0x40(r8)
cmpwi r0, 0
bne hlSpotScanNext
; Ambiguous identity leaves all lights native.
lwz r0, 8(r11)
cmpwi r0, 0
bne hlCaptureInvalidate
stw r8, 8(r11)
hlSpotScanNext:
addi r4, r4, 4
addi r3, r3, 1
cmpwi r3, 2
blt hlSpotScan
lwz r0, 8(r11)
cmpwi r0, 0
bne hlCaptureCommit
hlSpotNextOwner:
cmpwi r6, 1
beq hlCaptureDone
li r6, 1
lwz r7, 12(r11)
b hlSpotOwner
hlCaptureCommit:
lis r12, mtHideModel@ha
addi r12, r12, mtHideModel@l
lwz r0, 12(r12)
stw r0, 4(r11)
; View row 2 is minus world forward, including head yaw/pitch and rig yaw.
; Native collision and light submission both negate this direction once.
lwz r0, 32(r9)
stw r0, 16(r11)
lwz r0, 36(r9)
stw r0, 20(r11)
lwz r0, 40(r9)
stw r0, 24(r11)
li r0, 1
stw r0, 0(r11)
hlCaptureDone:
blr
hlCaptureInvalidate:
li r0, 0
stw r0, 0(r11)
stw r0, 8(r11)
blr
hlPose:
.int 0 ; valid
.int 0 ; scene calculation epoch
.int 0 ; current player spotlight identity (never dereferenced by the hook)
.int 0 ; primary player identity
.int 0 ; negative forward x
.int 0 ; negative forward y
.int 0 ; negative forward z

; After the native joint direction is extracted, before collision and submit.
; Replace only the three call-local direction words, not the animated skeleton.
0x02476E6C = bla hlSpotDirection
hlSpotDirection:
stwu r1, -0x20(r1)
stw r0, 8(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 12(r1)
stw r5, 16(r1)
stw r11, 20(r1)
stw r12, 24(r1)
lis r11, hlPose@ha
addi r11, r11, hlPose@l
lwz r0, 0(r11)
cmpwi r0, 1
bne hlSpotReturn
lwz r0, 8(r11)
cmpw r0, r31
bne hlSpotReturn
lis r12, rrEnabled@ha
lwz r0, rrEnabled@l(r12)
cmpwi r0, 0
beq hlSpotReturn
lis r12, mtControl@ha
lwz r0, mtControl@l(r12)
cmpwi r0, 1
bne hlSpotReturn
lis r12, mrSceneClass@ha
lwz r0, mrSceneClass@l(r12)
lis r5, 0x1032
ori r5, r5, 0x86DC
cmpw r0, r5
bne hlSpotReturn
lis r12, mtHideActor@ha
lwz r0, mtHideActor@l(r12)
lwz r5, 12(r11)
cmpw r0, r5
bne hlSpotReturn
lis r12, mtHideModel@ha
addi r12, r12, mtHideModel@l
lwz r0, 12(r12)
lwz r5, 4(r11)
subf r5, r5, r0
cmplwi r5, 1
bgt hlSpotReturn
; Native stack +0x34..0x3C, adjusted for this hook's own stack frame.
lwz r0, 16(r11)
stw r0, 0x54(r1)
lwz r0, 20(r11)
stw r0, 0x58(r1)
lwz r0, 24(r11)
stw r0, 0x5C(r1)
hlSpotReturn:
lwz r5, 16(r1)
lwz r11, 20(r1)
lwz r12, 24(r1)
lwz r0, 12(r1)
.int 0x7C0FF120 ; mtcrf 255, r0
lwz r0, 8(r1)
addi r1, r1, 0x20
lis r12, 0x1034
blr

[Mario3DWorld_Headlamp_Passthrough]
moduleMatches = 0xBBAF1908
.origin = codecave
hlCaptureView:
blr

[VR_BlowGesture_Verified]
moduleMatches = 0xD2308838
.origin = codecave
; Keep native microphone processing when the right-hand gesture is inactive.
; Facade-entry hooks also work when no audio device is configured.
mbGetRaw:
lis r12, mbState@ha
lwz r12, mbState@l(r12)
cmpwi r12, 1
bne mbGetRawNative
lis r12, rrEnabled@ha
lwz r12, rrEnabled@l(r12)
cmpwi r12, 1
bne mbGetRawNative
lis r12, mbVolume@ha
lfs f1, mbVolume@l(r12)
blr
mbGetRawNative:
mflr r0
b mbGetRawResume
0x024BC75C = mbGetRawResume:
0x024BC758 = ba mbGetRaw

mbGetLoud:
lis r12, mbState@ha
lwz r12, mbState@l(r12)
cmpwi r12, 1
bne mbGetLoudNative
lis r12, rrEnabled@ha
lwz r12, rrEnabled@l(r12)
cmpwi r12, 1
bne mbGetLoudNative
li r3, 1
blr
mbGetLoudNative:
mflr r0
b mbGetLoudResume
0x024BC814 = mbGetLoudResume:
0x024BC810 = ba mbGetLoud

mbGetFiltered:
lis r12, mbState@ha
lwz r12, mbState@l(r12)
cmpwi r12, 1
bne mbGetFilteredNative
lis r12, rrEnabled@ha
lwz r12, rrEnabled@l(r12)
cmpwi r12, 1
bne mbGetFilteredNative
lis r12, mbVolume@ha
lfs f1, mbVolume@l(r12)
blr
mbGetFilteredNative:
mflr r0
b mbGetFilteredResume
0x024BC8C8 = mbGetFilteredResume:
0x024BC8C4 = ba mbGetFiltered

mbGetDetected:
lis r12, mbState@ha
lwz r12, mbState@l(r12)
cmpwi r12, 1
bne mbGetDetectedNative
lis r12, rrEnabled@ha
lwz r12, rrEnabled@l(r12)
cmpwi r12, 1
bne mbGetDetectedNative
li r3, 1
blr
mbGetDetectedNative:
mflr r0
b mbGetDetectedResume
0x024BC980 = mbGetDetectedResume:
0x024BC97C = ba mbGetDetected

[Mario3DWorld_Touch_EU_v0]
moduleMatches = 0xD2308838
.origin = codecave
; Grip previews; only grip + trigger activates native touch. No fake hover press.
tcInputUpdate:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
lis r10, tcButtons@ha
addi r10, r10, tcButtons@l
li r0, 0
stw r0, 0(r10)
stw r0, 4(r10)
lis r11, mtPad@ha
addi r11, r11, mtPad@l
lwz r0, 140(r11)
andi. r0, r0, 16
bne tcInputHeld
li r0, 0
stw r0, 8(r10)
tcInputHeld:
lis r12, tcWorld@ha
addi r12, r12, tcWorld@l
lwz r0, 48(r12)
cmpwi r0, 0
beq tcInputDone
lis r12, mrCullEpoch@ha
lwz r12, mrCullEpoch@l(r12)
subf r0, r0, r12
cmplwi r0, 2
bgt tcInputDone
lis r12, tcPadReady@ha
addi r12, r12, tcPadReady@l
lwz r0, 0(r12)
cmpwi r0, 1
bne tcInputDone
lis r12, mbState@ha
addi r12, r12, mbState@l
lwz r0, 8(r12)
cmpwi r0, 4
bge tcInputDone
lwz r0, 88(r11)
cmpwi r0, 1
bne tcInputDone
lwz r0, 140(r11)
andi. r0, r0, 32
beq tcInputDone
bl tcLease
cmpwi r3, 0
beq tcInputDone
lis r10, tcButtons@ha
addi r10, r10, tcButtons@l
lis r11, mtPad@ha
addi r11, r11, mtPad@l
li r0, 1
stw r0, 0(r10)
lwz r0, 140(r11)
andi. r0, r0, 16
beq tcInputDone
li r0, 1
stw r0, 4(r10)
stw r0, 8(r10)
tcInputDone:
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
blr
tcLease:
lis r12, tcPacket@ha
addi r12, r12, tcPacket@l
lwz r3, 12(r12)
lwz r0, 8(r12)
cmpwi r0, 0
beq tcLeaseNo
lis r11, mrCullEpoch@ha
addi r11, r11, mrCullEpoch@l
lwz r11, 0(r11)
subf r0, r0, r11
cmplwi r0, 8
bgt tcLeaseNo
blr
tcLeaseNo:
li r3, 0
blr
tcCameraCapture:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
lis r12, tcWorld@ha
addi r12, r12, tcWorld@l
li r0, 0
stw r0, 48(r12)
lis r11, mrSceneClass@ha
addi r11, r11, mrSceneClass@l
lwz r0, 0(r11)
lis r11, 0x1032
ori r11, r11, 0x86DC
cmpw r0, r11
bne tcCameraDone
lis r11, rrSlot@ha
addi r11, r11, rrSlot@l
lwz r8, 0(r11)
mulli r7, r8, 2
add r7, r7, r10
mulli r7, r7, 4
lis r11, mtNearState@ha
addi r11, r11, mtNearState@l
add r11, r11, r7
lwz r6, 0(r11)
lis r11, tcConst@ha
addi r11, r11, tcConst@l
lfs f12, 0(r11)
cmpwi r6, 1
bne tcCameraScale
lfs f12, 4(r11)
tcCameraScale:
stfs f12, 52(r12)
stw r6, 56(r12)
lis r11, mtControl@ha
addi r11, r11, mtControl@l
lwz r0, 8(r11)
stw r0, 60(r12)
lis r11, rrPoseLatch0@ha
addi r11, r11, rrPoseLatch0@l
mulli r8, r8, 196
add r11, r11, r8
lwz r0, 0(r11)
cmpwi r0, 0
beq tcCameraDone
stw r0, 68(r12)
addi r11, r11, 4
cmpwi r10, 1
beq tcCameraDelta
addi r11, r11, 48
tcCameraDelta:
lfs f1, 0(r9)
lfs f2, 0(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 16(r9)
lfs f2, 16(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 32(r9)
lfs f2, 32(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 0(r12)
lfs f1, 0(r9)
lfs f2, 4(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 16(r9)
lfs f2, 20(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 32(r9)
lfs f2, 36(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 4(r12)
lfs f1, 0(r9)
lfs f2, 8(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 16(r9)
lfs f2, 24(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 32(r9)
lfs f2, 40(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 8(r12)
lfs f1, 0(r9)
lfs f2, 12(r11)
fmuls f2, f2, f12
lfs f3, 12(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 16(r9)
lfs f2, 28(r11)
fmuls f2, f2, f12
lfs f3, 28(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 32(r9)
lfs f2, 44(r11)
fmuls f2, f2, f12
lfs f3, 44(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 12(r12)
lfs f1, 4(r9)
lfs f2, 0(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 20(r9)
lfs f2, 16(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 36(r9)
lfs f2, 32(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 16(r12)
lfs f1, 4(r9)
lfs f2, 4(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 20(r9)
lfs f2, 20(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 36(r9)
lfs f2, 36(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 20(r12)
lfs f1, 4(r9)
lfs f2, 8(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 20(r9)
lfs f2, 24(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 36(r9)
lfs f2, 40(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 24(r12)
lfs f1, 4(r9)
lfs f2, 12(r11)
fmuls f2, f2, f12
lfs f3, 12(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 20(r9)
lfs f2, 28(r11)
fmuls f2, f2, f12
lfs f3, 28(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 36(r9)
lfs f2, 44(r11)
fmuls f2, f2, f12
lfs f3, 44(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 28(r12)
lfs f1, 8(r9)
lfs f2, 0(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 24(r9)
lfs f2, 16(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r9)
lfs f2, 32(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 32(r12)
lfs f1, 8(r9)
lfs f2, 4(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 24(r9)
lfs f2, 20(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r9)
lfs f2, 36(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 36(r12)
lfs f1, 8(r9)
lfs f2, 8(r11)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 24(r9)
lfs f2, 24(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r9)
lfs f2, 40(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 40(r12)
lfs f1, 8(r9)
lfs f2, 12(r11)
fmuls f2, f2, f12
lfs f3, 12(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 24(r9)
lfs f2, 28(r11)
fmuls f2, f2, f12
lfs f3, 28(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r9)
lfs f2, 44(r11)
fmuls f2, f2, f12
lfs f3, 44(r9)
fsubs f2, f2, f3
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 44(r12)
lis r11, mrCullEpoch@ha
addi r11, r11, mrCullEpoch@l
lwz r0, 0(r11)
stw r0, 48(r12)
bl tcPublish
tcCameraDone:
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
blr
tcManager:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
lis r12, tcHand@ha
addi r12, r12, tcHand@l
lwz r0, 8(r30)
stw r0, 0(r12)
li r0, 0
stw r0, 4(r12)
bl tcInputUpdate
bl tcPrepareRay
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcManagerDone
lwz r3, 8(r30)
cmpwi r3, 0
beq tcManagerDone
lwz r0, 0x88(r3)
cmpwi r0, 0
beq tcManagerDone
bl 0x021A6650
tcManagerDone:
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
b tcTouchDown
0x021A5368 = bla tcManager
tcTouchDown:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcTouchNative
lis r12, tcButtons@ha
addi r12, r12, tcButtons@l
lwz r3, 4(r12)
blr
tcTouchNative:
b 0x0249533C
0x021A5550 = bla tcTouchDown
0x021A5490 = bla tcTouchDown
0x021A5530 = bla tcTouchDown
tcPrepareRay:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
li r0, 0
stw r0, 0(r12)
stw r0, 4(r12)
stw r0, 8(r12)
lis r11, tcButtons@ha
addi r11, r11, tcButtons@l
lwz r0, 0(r11)
cmpwi r0, 0
beq tcPrepareDone
lis r11, tcWorld@ha
addi r11, r11, tcWorld@l
lis r10, mrCullEpoch@ha
addi r10, r10, mrCullEpoch@l
lwz r10, 0(r10)
lwz r0, 48(r11)
cmpwi r0, 0
beq tcPrepareDone
subf r0, r0, r10
cmplwi r0, 2
bgt tcPrepareDone
lis r8, mtControl@ha
addi r8, r8, mtControl@l
lwz r0, 8(r8)
lwz r7, 60(r11)
cmpw r0, r7
bne tcPrepareDone
; Separate aim history: exact pose sequence, with a second seqlock read.
lis r8, rrSlot@ha
lwz r0, rrSlot@l(r8)
mulli r0, r0, 196
lis r8, rrPoseLatch0@ha
addi r8, r8, rrPoseLatch0@l
add r8, r8, r0
lwz r7, 0(r8)
cmpwi r7, 0
beq tcPrepareDone
andi. r0, r7, 14
mulli r0, r0, 28
lis r8, tcAimHistory@ha
addi r8, r8, tcAimHistory@l
add r8, r8, r0
lwz r0, 0(r8)
cmpw r0, r7
bne tcPrepareDone
.int 0x7C2004AC ; lwsync
lwz r0, 4(r8)
cmpwi r0, 1
bne tcPrepareDone
lis r6, tcAimPose@ha
addi r6, r6, tcAimPose@l
lwz r0, 8(r8)
stw r0, 0(r6)
lwz r0, 12(r8)
stw r0, 4(r6)
lwz r0, 16(r8)
stw r0, 8(r6)
lwz r0, 20(r8)
stw r0, 12(r6)
lwz r0, 24(r8)
stw r0, 16(r6)
lwz r0, 28(r8)
stw r0, 20(r6)
lwz r0, 32(r8)
stw r0, 24(r6)
lwz r0, 36(r8)
stw r0, 28(r6)
lwz r0, 40(r8)
stw r0, 32(r6)
lwz r0, 44(r8)
stw r0, 36(r6)
lwz r0, 48(r8)
stw r0, 40(r6)
lwz r0, 52(r8)
stw r0, 44(r6)
.int 0x7C2004AC ; lwsync
lwz r0, 0(r8)
cmpw r0, r7
bne tcPrepareDone
mr r8, r6
lfs f12, 52(r11)
stfs f12, 64(r12)
stw r10, 12(r12)
lfs f1, 0(r11)
lfs f2, 12(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 4(r11)
lfs f2, 28(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r11)
lfs f2, 44(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 12(r11)
fadds f0, f0, f1
stfs f0, 16(r12)
lfs f1, 0(r11)
lfs f2, 8(r8)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 4(r11)
lfs f2, 24(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r11)
lfs f2, 40(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fneg f0, f0
stfs f0, 28(r12)
lfs f1, 16(r11)
lfs f2, 12(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 20(r11)
lfs f2, 28(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r11)
lfs f2, 44(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 28(r11)
fadds f0, f0, f1
stfs f0, 20(r12)
lfs f1, 16(r11)
lfs f2, 8(r8)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 20(r11)
lfs f2, 24(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r11)
lfs f2, 40(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fneg f0, f0
stfs f0, 32(r12)
lfs f1, 32(r11)
lfs f2, 12(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 36(r11)
lfs f2, 28(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r11)
lfs f2, 44(r8)
fmuls f2, f2, f12
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 44(r11)
fadds f0, f0, f1
stfs f0, 24(r12)
lfs f1, 32(r11)
lfs f2, 8(r8)
fmuls f1, f1, f2
fmr f0, f1
lfs f1, 36(r11)
lfs f2, 24(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r11)
lfs f2, 40(r8)
fmuls f1, f1, f2
fadds f0, f0, f1
fneg f0, f0
stfs f0, 36(r12)
lis r11, tcConst@ha
addi r11, r11, tcConst@l
lfs f5, 8(r11)
fmuls f5, f5, f12
lfs f6, 12(r11)
lfs f0, 28(r12)
fmuls f1, f0, f6
stfs f1, 40(r12)
fmuls f0, f0, f5
lfs f1, 16(r12)
fadds f0, f0, f1
stfs f0, 52(r12)
lfs f0, 32(r12)
fmuls f1, f0, f6
stfs f1, 44(r12)
fmuls f0, f0, f5
lfs f1, 20(r12)
fadds f0, f0, f1
stfs f0, 56(r12)
lfs f0, 36(r12)
fmuls f1, f0, f6
stfs f1, 48(r12)
fmuls f0, f0, f5
lfs f1, 24(r12)
fadds f0, f0, f1
stfs f0, 60(r12)
li r0, 1
stw r0, 0(r12)
tcPrepareDone:
blr
tcOrigin:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcOriginNative
addi r3, r12, 16
blr
tcOriginNative:
b 0x02429774
0x021A6674 = bla tcOrigin
0x021A6B84 = bla tcOrigin
0x021A6C4C = bla tcOrigin
tcNormalize:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcNormalizeNative
lwz r0, 28(r12)
stw r0, 0(r3)
lwz r0, 32(r12)
stw r0, 4(r3)
lwz r0, 36(r12)
stw r0, 8(r3)
blr
tcNormalizeNative:
b 0x023EBB30
0x021A66D4 = bla tcNormalize
tcCollision:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcCollisionNative
addi r4, r12, 16
addi r5, r12, 40
tcCollisionNative:
b 0x02437E98
0x021A67F4 = bla tcCollision
tcUnproject:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcUnprojectNative
lwz r0, 52(r12)
stw r0, 0(r3)
lwz r0, 56(r12)
stw r0, 4(r3)
lwz r0, 60(r12)
stw r0, 8(r3)
blr
tcUnprojectNative:
b 0x024665E4
0x021A55A8 = bla tcUnproject
tcNativeWidget:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcWidgetNative
b 0x0245F21C
tcWidgetNative:
b 0x0245F26C
0x021A5440 = bla tcNativeWidget
tcMeshHit:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcMeshDone
li r0, 1
stw r0, 4(r12)
li r0, 0
stw r0, 8(r12)
lwz r0, 100(r28)
stw r0, 52(r12)
lwz r0, 104(r28)
stw r0, 56(r12)
lwz r0, 108(r28)
stw r0, 60(r12)
lwz r11, 0(r28)
cmpwi r11, 0
beq tcMeshDone
lwz r11, 0x120(r11)
cmpwi r11, 0
beq tcMeshDone
lwz r11, 0x2C(r11)
cmpwi r11, 0
beq tcMeshDone
lwz r0, 0(r11)
lis r11, 0x102E
ori r11, r11, 0x17D8
cmpw r0, r11
bne tcMeshDone
li r0, 1
stw r0, 8(r12)
tcMeshDone:
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
mr r26, r28
blr
0x021A68A4 = bla tcMeshHit
tcGuideShow:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
mr r3, r31
bl tcGuideFind
cmpwi r3, 0
bne tcGuideShowFound
lis r3, tcGuides@ha
addi r3, r3, tcGuides@l
li r4, 8
lis r11, mrCullEpoch@ha
addi r11, r11, mrCullEpoch@l
lwz r11, 0(r11)
tcGuideFree:
lwz r0, 4(r3)
subf r0, r0, r11
cmplwi r0, 2
bgt tcGuideShowFound
lwz r0, 0(r3)
cmpwi r0, 0
beq tcGuideShowFound
addi r3, r3, 24
addi r4, r4, -1
cmpwi r4, 0
bne tcGuideFree
b tcGuideShowDone
tcGuideShowFound:
stw r31, 0(r3)
li r0, 0
stw r0, 4(r3)
tcGuideShowDone:
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
b 0x0245DF48
0x021322D4 = bla tcGuideShow
tcGuideFind:
lis r12, tcGuides@ha
addi r12, r12, tcGuides@l
li r11, 8
tcGuideFindLoop:
lwz r0, 0(r12)
cmpw r0, r3
beq tcGuideFound
addi r12, r12, 24
addi r11, r11, -1
cmpwi r11, 0
bne tcGuideFindLoop
li r3, 0
blr
tcGuideFound:
mr r3, r12
blr
tcGuideAnchor:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
lbz r0, 0x4C(r3)
cmpwi r0, 0
beq tcGuideAnchorDone
lbz r0, 0x4D(r3)
cmpwi r0, 0
beq tcGuideAnchorDone
bl tcGuideFind
cmpwi r3, 0
beq tcGuideAnchorDone
lis r11, mrCullEpoch@ha
addi r11, r11, mrCullEpoch@l
lwz r0, 0(r11)
stw r0, 4(r3)
lwz r5, 32(r1)
lwz r0, 0(r5)
stw r0, 8(r3)
lwz r0, 4(r5)
stw r0, 12(r3)
lwz r0, 8(r5)
stw r0, 16(r3)
tcGuideAnchorDone:
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
b 0x022FBFF8
0x02132348 = bla tcGuideAnchor
tcGuideDraw:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
bl tcLease
andi. r0, r3, 2
beq tcGuideDrawNative
lwz r3, 24(r1)
bl tcGuideFind
cmpwi r3, 0
beq tcGuideDrawNative
lwz r0, 4(r3)
lis r11, mrCullEpoch@ha
addi r11, r11, mrCullEpoch@l
lwz r11, 0(r11)
subf r0, r0, r11
cmplwi r0, 1
bgt tcGuideDrawNative
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
blr
tcGuideDrawNative:
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
b 0x0245EA14
0x102A59B4 = .int tcGuideDraw
tcPublish:
lis r12, tcPacket@ha
addi r12, r12, tcPacket@l
lis r11, rrSlot@ha
addi r11, r11, rrSlot@l
lwz r8, 0(r11)
mulli r8, r8, 2
add r8, r8, r10
mulli r8, r8, 160
addi r12, r12, 16
add r12, r12, r8
li r0, 0
stw r0, 0(r12)
lis r11, tcWorld@ha
addi r11, r11, tcWorld@l
lwz r0, 56(r11)
li r8, 0
cmpwi r0, 1
bne tcPublishMode
li r8, 1
tcPublishMode:
stw r8, 4(r12)
lwz r0, 48(r11)
stw r0, 8(r12)
li r0, 0
stw r0, 16(r12)
stw r0, 32(r12)
stw r0, 48(r12)
stw r0, 64(r12)
stw r0, 80(r12)
stw r0, 96(r12)
stw r0, 112(r12)
stw r0, 128(r12)
stw r0, 144(r12)
lis r11, tcRay@ha
addi r11, r11, tcRay@l
lwz r0, 0(r11)
cmpwi r0, 0
beq tcPublishGuides
lwz r0, 12(r11)
lwz r8, 8(r12)
cmpw r0, r8
bne tcPublishGuides
li r0, 1
lis r8, tcHand@ha
addi r8, r8, tcHand@l
lwz r0, 4(r8)
cmpwi r0, 1
li r0, 1
bne tcPublishCursorKind
lwz r8, 8(r8)
lwz r0, 8(r12)
cmpw r8, r0
li r0, 1
bne tcPublishCursorKind
li r0, 2
tcPublishCursorKind:
stw r0, 16(r12)
lfs f0, 12(r9)
lfs f1, 0(r9)
lfs f2, 52(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 4(r9)
lfs f2, 56(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 8(r9)
lfs f2, 60(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 20(r12)
lfs f0, 28(r9)
lfs f1, 16(r9)
lfs f2, 52(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 20(r9)
lfs f2, 56(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 24(r9)
lfs f2, 60(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 24(r12)
lfs f0, 44(r9)
lfs f1, 32(r9)
lfs f2, 52(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 36(r9)
lfs f2, 56(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
lfs f1, 40(r9)
lfs f2, 60(r11)
fmuls f1, f1, f2
fadds f0, f0, f1
stfs f0, 28(r12)
tcPublishGuides:
lis r11, tcWorld@ha
addi r11, r11, tcWorld@l
lwz r0, 68(r11)
.int 0x7C2004AC ; lwsync
stw r0, 0(r12)
blr
tcWorld:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
tcRay:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
tcGuides:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
tcConst:
.float 1.0
.float 0.1
.float 1500.0
.float 100000.0
tcPacket:
.int 0x4D544D4B
.int 2
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
tcAimHistory:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
tcAimPose:
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
; Reset on native manager construction, not by remembered pointer equality.
tcManagerReset:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
lis r12, tcHand@ha
addi r12, r12, tcHand@l
li r0, 0
stw r0, 0(r12)
stw r0, 4(r12)
stw r0, 8(r12)
stw r0, 12(r12)
lis r12, tcWorld@ha
addi r12, r12, tcWorld@l
li r0, 0
stw r0, 48(r12)
lis r12, tcRay@ha
stw r0, tcRay@l(r12)
lis r12, tcButtons@ha
addi r12, r12, tcButtons@l
stw r0, 0(r12)
stw r0, 4(r12)
stw r0, 8(r12)
lis r12, tcGuides@ha
addi r12, r12, tcGuides@l
li r11, 8
tcManagerClearGuides:
stw r0, 0(r12)
stw r0, 4(r12)
addi r12, r12, 24
addi r11, r11, -1
cmpwi r11, 0
bne tcManagerClearGuides
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
mflr r0
b 0x021A5184
0x021A5180 = ba tcManagerReset


; Native TouchPoint preview. No touch byte or sensor message is synthesized.
; Both manager return paths run this after its input/release handling.
tcHandFinish:
stwu r1, -0xE0(r1)
stw r0, 8(r1)
mflr r0
stw r0, 12(r1)
.int 0x7C000026 ; mfcr r0
stw r0, 16(r1)
.int 0x7C0902A6 ; mfctr r0
stw r0, 20(r1)
stw r3, 24(r1)
stw r4, 28(r1)
stw r5, 32(r1)
stw r6, 36(r1)
stw r7, 40(r1)
stw r8, 44(r1)
stw r9, 48(r1)
stw r10, 52(r1)
stw r11, 56(r1)
stw r12, 60(r1)
.int 0xD8010040 ; stfd f0
.int 0xD8210048 ; stfd f1
.int 0xD8410050 ; stfd f2
.int 0xD8610058 ; stfd f3
.int 0xD8810060 ; stfd f4
.int 0xD8A10068 ; stfd f5
.int 0xD8C10070 ; stfd f6
.int 0xD8E10078 ; stfd f7
.int 0xD9010080 ; stfd f8
.int 0xD9210088 ; stfd f9
.int 0xD9410090 ; stfd f10
.int 0xD9610098 ; stfd f11
.int 0xD98100A0 ; stfd f12
.int 0xD9A100A8 ; stfd f13
lwz r3, 8(r30)
bl tcHandPreview
.int 0xC8010040 ; lfd f0
.int 0xC8210048 ; lfd f1
.int 0xC8410050 ; lfd f2
.int 0xC8610058 ; lfd f3
.int 0xC8810060 ; lfd f4
.int 0xC8A10068 ; lfd f5
.int 0xC8C10070 ; lfd f6
.int 0xC8E10078 ; lfd f7
.int 0xC9010080 ; lfd f8
.int 0xC9210088 ; lfd f9
.int 0xC9410090 ; lfd f10
.int 0xC9610098 ; lfd f11
.int 0xC98100A0 ; lfd f12
.int 0xC9A100A8 ; lfd f13
lwz r3, 24(r1)
lwz r4, 28(r1)
lwz r5, 32(r1)
lwz r6, 36(r1)
lwz r7, 40(r1)
lwz r8, 44(r1)
lwz r9, 48(r1)
lwz r10, 52(r1)
lwz r11, 56(r1)
lwz r12, 60(r1)
lwz r0, 20(r1)
.int 0x7C0903A6 ; mtctr r0
lwz r0, 16(r1)
.int 0x7C0FF120 ; mtcrf 255,r0
lwz r0, 12(r1)
mtlr r0
lwz r0, 8(r1)
addi r1, r1, 0xE0
lwz r29, 0x34(r1)
blr
0x021A56E4 = bla tcHandFinish
0x021A5734 = bla tcHandFinish

tcHandPreview:
stwu r1, -0x20(r1)
mflr r0
stw r0, 0x24(r1)
stw r31, 0x1C(r1)
mr r31, r3
cmpwi r31, 0
beq tcHandPreviewDone
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcHandPreviewOff
lwz r0, 8(r12)
cmpwi r0, 0
beq tcHandPreviewOff
; PointWait is presentation only. Native control remains gated by trigger.
lis r12, tcButtons@ha
addi r12, r12, tcButtons@l
lwz r0, 4(r12)
cmpwi r0, 0
bne tcHandPreviewPlace
bl 0x023FC848
cmpwi r3, 0
beq tcHandPreviewState
mr r3, r31
bl 0x02414194
tcHandPreviewState:
mr r3, r31
lis r4, 0x104E
addi r4, r4, 0x392C
bl 0x02441238
cmpwi r3, 0
bne tcHandPreviewAnimate
mr r3, r31
lis r4, 0x104E
addi r4, r4, 0x392C
bl 0x02441158
tcHandPreviewAnimate:
; Start the native pointing animation on entering hover, not every frame.
lis r12, tcHand@ha
addi r12, r12, tcHand@l
lwz r0, 12(r12)
cmpwi r0, 0
bne tcHandPreviewPlace
mr r3, r31
lis r4, 0x102F
addi r4, r4, 0x104C
bl 0x023F8F50
tcHandPreviewPlace:
mr r3, r31
lis r4, tcRay@ha
addi r4, r4, tcRay@l
addi r4, r4, 52
addi r5, r31, 0xA8
bl 0x021A7574
mr r3, r31
bl 0x0240164C
lis r12, tcHand@ha
addi r12, r12, tcHand@l
li r0, 1
stw r0, 4(r12)
stw r0, 12(r12)
lis r11, mrCullEpoch@ha
lwz r0, mrCullEpoch@l(r11)
stw r0, 8(r12)
b tcHandPreviewDone
tcHandPreviewOff:
lis r12, tcHand@ha
addi r12, r12, tcHand@l
lwz r0, 12(r12)
li r11, 0
stw r11, 12(r12)
stw r11, 4(r12)
cmpwi r0, 0
beq tcHandPreviewDone
; A preview we made alive must not keep dispatching native touch messages.
lis r12, tcButtons@ha
addi r12, r12, tcButtons@l
lwz r0, 4(r12)
cmpwi r0, 0
bne tcHandPreviewDone
mr r3, r31
bl 0x0241433C
tcHandPreviewDone:
lwz r0, 0x24(r1)
lwz r31, 0x1C(r1)
mtlr r0
addi r1, r1, 0x20
blr

; A hover may animate the existing model but must never run its action dispatch.
; Keep the game's controller/mouse path when VR is not taking touch ownership.
tcHandControl:
lis r12, tcRay@ha
lwz r0, tcRay@l(r12)
cmpwi r0, 0
beq tcHandControlNative
lis r12, tcButtons@ha
addi r12, r12, tcButtons@l
lwz r0, 4(r12)
cmpwi r0, 0
beq tcHandControlHover
tcHandControlNative:
stwu r1, -0x20(r1)
mflr r0
stw r0, 0x24(r1)
stw r31, 0x1C(r1)
mr r31, r3
bl 0x021A69D4
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcHandControlDone
lwz r0, 8(r12)
cmpwi r0, 0
bne tcHandControlDone
mr r3, r31
bl 0x02401720
tcHandControlDone:
lwz r0, 0x24(r1)
lwz r31, 0x1C(r1)
mtlr r0
addi r1, r1, 0x20
blr
tcHandControlHover:
blr
0x102F1234 = .int tcHandControl

; Do not begin the native release animation while still hovering a platform.
tcHandRelease:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcHandReleaseNative
lwz r0, 8(r12)
cmpwi r0, 0
bne tcHandReleaseDone
tcHandReleaseNative:
b 0x021A7890
tcHandReleaseDone:
blr
0x021A5730 = bla tcHandRelease

; The native hand and its animation use the exact controller collision point.
; No screen-coordinate reprojection or separate target offset is applied.
tcHandPosition:
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lwz r0, 0(r12)
cmpwi r0, 0
beq tcHandPositionNative
lis r11, tcHand@ha
lwz r0, tcHand@l(r11)
cmpw r0, r3
bne tcHandPositionNative
addi r4, r12, 52
tcHandPositionNative:
b 0x02406778
0x021A75AC = bla tcHandPosition


; The pointing finger is offset from the native actor origin. Align its live
; animated distal joint using a model-only render matrix. Neither the actor
; pose nor its collision/sensor matrices are changed by the visual alignment.
tcHandCalc:
stwu r1, -0xA0(r1)
mflr r0
stw r0, 0xA4(r1)
stw r31, 0x9C(r1)
stw r30, 0x98(r1)
mr r31, r3
bl 0x024146A0
lis r12, tcHand@ha
addi r12, r12, tcHand@l
lwz r0, 0(r12)
cmpw r0, r31
bne tcHandCalcDone
lwz r0, 4(r12)
cmpwi r0, 1
bne tcHandCalcDone
lis r11, mrCullEpoch@ha
lwz r11, mrCullEpoch@l(r11)
lwz r0, 8(r12)
cmpw r0, r11
bne tcHandCalcDone
lwz r0, 0x44(r31)
cmpwi r0, 0
beq tcHandCalcDone
; Native lookup validates the joint before the matrix accessor is called.
mr r3, r31
lis r4, tcFingerJoint@ha
addi r4, r4, tcFingerJoint@l
bl 0x02402550
cmpwi r3, 0
beq tcHandCalcDone
mr r3, r31
lis r4, tcFingerJoint@ha
addi r4, r4, tcFingerJoint@l
bl 0x0240257C
cmpwi r3, 0
beq tcHandCalcDone
lis r12, tcRay@ha
addi r12, r12, tcRay@l
lfs f0, 52(r12)
lfs f1, 12(r3)
fsubs f0, f0, f1
stfs f0, 8(r1)
lfs f0, 56(r12)
lfs f1, 28(r3)
fsubs f0, f0, f1
stfs f0, 12(r1)
lfs f0, 60(r12)
lfs f1, 44(r3)
fsubs f0, f0, f1
stfs f0, 16(r1)
addi r3, r1, 0x30
mr r4, r31
bl 0x02407214
; Adjust a call-local render matrix, never the actor or collision transform.
lfs f0, 0x3C(r1)
lfs f1, 8(r1)
fadds f0, f0, f1
stfs f0, 0x3C(r1)
lfs f0, 0x4C(r1)
lfs f1, 12(r1)
fadds f0, f0, f1
stfs f0, 0x4C(r1)
lfs f0, 0x5C(r1)
lfs f1, 16(r1)
fadds f0, f0, f1
stfs f0, 0x5C(r1)
mr r3, r31
bl 0x024068E8
mr r5, r3
mr r3, r31
addi r4, r1, 0x30
bl 0x023FBC24
tcHandCalcDone:
lwz r0, 0xA4(r1)
lwz r30, 0x98(r1)
lwz r31, 0x9C(r1)
mtlr r0
addi r1, r1, 0xA0
blr
0x102F11AC = .int tcHandCalc
tcFingerJoint:
.int 0x496E6465 ; Index3, a model joint name, not embedded game geometry
.int 0x78330000

tcHand:
.int 0 ; current manager's native TouchPoint
.int 0 ; visible native replacement
.int 0 ; calculation epoch of replacement
.int 0 ; preview owned by VR

[Mario3DWorld_Touch_Passthrough]
moduleMatches = 0xBBAF1908
.origin = codecave
tcInputUpdate:
blr
tcCameraCapture:
blr
