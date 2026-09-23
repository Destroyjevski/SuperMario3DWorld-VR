[MarioFPS_EUv0]
moduleMatches = 0xD2308838
.origin = codecave
mfTelemetry:
.int 0x4D465053
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
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
.int 0
; Guest bus/4 clock: 62,156,250 ticks/s. Twice ticks gives exact 60 Hz.
; One step maximum per rendered frame. Rebase after >= 33.333 ms stalls.
mfClock:
stwu r1, -0x20(r1)
mflr r0
stw r0, 0x24(r1)
stw r3, 8(r1)
.int 0x7C000026 ; mfcr r0 (not supported by Cemu's text assembler)
stw r0, 12(r1)
bl import.coreinit.OSGetSystemTime
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r10, 32(r12)
stw r4, 32(r12)
subf r9, r10, r4
lis r8, 31
ori r8, r8, 40259
cmpwi r10, 0
beq mfClockReset
cmplw r9, r8
bge mfClockReset
slwi r9, r9, 1
lwz r10, 36(r12)
add r9, r9, r10
b mfClockCompare
mfClockReset:
mr r9, r8
mfClockCompare:
li r11, 0
cmplw r9, r8
blt mfClockStore
li r11, 1
subf r9, r8, r9
cmplw r9, r8
blt mfClockStore
li r9, 0
mfClockStore:
stw r9, 36(r12)
stw r11, 152(r12)
lwz r3, 8(r1)
lwz r0, 12(r1)
.int 0x7C0FF120 ; mtcrf 0xFF, r0
lwz r0, 0x24(r1)
mtlr r0
addi r1, r1, 0x20
blr

; Poll and advance controller state only on the same ticks as gameplay.
mfInput:
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 152(r12)
cmpwi r11, 0
beqlr
lwz r11, 156(r12)
addi r11, r11, 1
stw r11, 156(r12)
mflr r0
b mfInputContinue
0x0236B428 = ba mfInput
0x0236B42C = mfInputContinue:
mfFrame:

lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 8(r12)
addi r11, r11, 1
stw r11, 8(r12)
stw r3, 28(r12)
stwu r1, -0x10(r1)
mflr r0
stw r0, 0x14(r1)
bl mfClock
lwz r0, 0x14(r1)
mtlr r0
addi r1, r1, 0x10
mflr r0
b mfFrameContinue
0x024DB2B8 = ba mfFrame
0x024DB2BC = mfFrameContinue:
mfCalc:
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
stw r3, 96(r12)
lwz r11, 8(r3)
stw r11, 48(r12)
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 152(r12)
cmpwi r11, 0
bne mfDoCalc
lwz r11, 40(r12)
addi r11, r11, 1
stw r11, 40(r12)
; Release temporary render textures for every owner observed in the
; preceding native update. Death/respawn transitions can render more than one
; child scene; remembering only the last owner eventually exhausts the pool.
; Never execute the full child scene here: that also advances gameplay.
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 184(r12)
cmpwi r11, 0
bne mfHasOwners
; Before the first owner exists (e.g. the opening menu), there is no
; render-texture cleanup to preserve and no reason to advance that scene.
lwz r10, 88(r12)
cmpwi r10, 0
beq mfSkipDone
b mfUnsafeNoOwner
mfHasOwners:
cmpwi r11, 12
bgt mfUnsafeOverflow
lwz r10, 8(r3)
cmpwi r10, 0
beq mfUnsafeContext
lwz r9, 88(r12)
cmpw r9, r10
bne mfUnsafeContext
lwz r10, 0x5C(r10)
lwz r9, 92(r12)
cmpw r9, r10
bne mfUnsafeContext
stwu r1, -0x20(r1)
mflr r0
stw r0, 0x24(r1)
li r11, 0
stw r11, 8(r1)
mfReplayLoop:
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 8(r1)
lwz r10, 184(r12)
cmpw r11, r10
bge mfReplayDone
slwi r10, r11, 2
add r10, r12, r10
lwz r3, 188(r10)
cmpwi r3, 0
beq mfReplayNext
bl mfCleanup
mfReplayNext:
lwz r11, 8(r1)
addi r11, r11, 1
stw r11, 8(r1)
b mfReplayLoop
mfReplayDone:
lwz r0, 0x24(r1)
mtlr r0
addi r1, r1, 0x20
mfSkipDone:
blr
; An extra Draw without a cleanup owner can exhaust temporary textures during
; loading/death transitions. Use a native Calc for that frame as well.
mfUnsafeNoOwner:
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 248(r12)
addi r11, r11, 1
stw r11, 248(r12)
b mfUnsafeCalc
mfUnsafeOverflow:
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 244(r12)
addi r11, r11, 1
stw r11, 244(r12)
b mfUnsafeCalc
mfUnsafeContext:
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 240(r12)
addi r11, r11, 1
stw r11, 240(r12)
mfUnsafeCalc:
lwz r11, 236(r12)
addi r11, r11, 1
stw r11, 236(r12)
mfDoCalc:
lis r12, mfTelemetry@ha
li r11, 0
stw r11, mfTelemetry@l+184(r12)

lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 12(r12)
addi r11, r11, 1
stw r11, 12(r12)
b mfNativeCalc
0x02440BB8 = mfNativeCalc:
0x022F37F4 = bla mfCalc
mfCleanup:
lis r12, mfTelemetry@ha
addi r12, r12, mfTelemetry@l
lwz r11, 84(r12)
addi r11, r11, 1
stw r11, 84(r12)
; Calls replayed on an extra render frame must not append themselves.
lwz r10, 152(r12)
cmpwi r10, 0
beq mfCleanupNative
; Preserve every cleanup owner from the native step. Twelve slots provide a
; bounded safety margin for overlapping transition scenes.
lwz r11, 184(r12)
cmpwi r11, 12
bge mfCleanupOverflow
slwi r10, r11, 2
add r10, r12, r10
stw r3, 188(r10)
addi r11, r11, 1
stw r11, 184(r12)
b mfRememberContext
mfCleanupOverflow:
li r11, 13
stw r11, 184(r12)
mfRememberContext:
lwz r11, 96(r12)
cmpwi r11, 0
beq mfNoCleanupOwner
lwz r11, 8(r11)
cmpwi r11, 0
beq mfNoCleanupOwner
stw r11, 88(r12)
lwz r11, 0x5C(r11)
stw r11, 92(r12)
b mfCleanupNative
mfNoCleanupOwner:
li r11, 0
stw r11, 184(r12)
mfCleanupNative:
lwz r3, 8(r3)
b mfCleanupContinue
0x024556FC = ba mfCleanup
0x02455700 = mfCleanupContinue:
