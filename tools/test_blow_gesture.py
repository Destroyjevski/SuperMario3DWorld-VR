"""Execute the production blow-gesture PPC blocks against synthetic memory.
No game data, Cemu, headset runtime or audio device is used.
"""
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
PACK = next(p for p in (ROOT / "graphicPacks").rglob("*.asm")
            if "mbGetDetected:" in p.read_text(encoding="utf-8"))
source = PACK.read_text(encoding="utf-8")
# Use the actual blocks, not a second implementation of the guest policy.
body = source[source.index("; Accept the gesture only"):source.index("rrPoseLatchDone:")]
body += "blr\n" + source[source.index("mbState:"):source.index("\n[", source.index("mbState:"))]
body += source[source.index("[VR_BlowGesture_Verified]"):source.index("[Mario3DWorld_Touch_EU_v0]")]
body += "\nrrEnabled:\n.int 1\nmtPad:\n" + ".int 0\n" * 40
labels, memory, instructions = {}, {}, {}
address = 0x1800000
external = {}
for raw in body.splitlines():
    line = raw.split(";", 1)[0].strip()
    if not line or line.startswith(("[", "moduleMatches", ".origin")):
        continue
    if line.startswith("0x"):
        if line.endswith(":"):
            at, name = line.split("=")
            external[name.strip()[:-1]] = int(at, 16)
        continue
    if line.endswith(":"):
        assert line[:-1] not in labels
        labels[line[:-1]] = address
        continue
    if line.startswith(".int"):
        memory[address] = int(line.split()[1], 0)
    elif line.startswith(".float"):
        memory[address] = struct.unpack(">I", struct.pack(">f", float(line.split()[1])))[0]
    else:
        instructions[address] = line.replace(",", " ").split()
    address += 4
labels.update(external)

class CPU:
    def __init__(self):
        self.mem = memory.copy()
        self.r = [0x10000000+i for i in range(32)]
        self.f = [i+.125 for i in range(32)]
        self.lr = 0x7ffffffc
        self.cr = 0
    def value(self, token):
        if "@" in token:
            name, part = token.split("@")
            value = labels[name]
            if part == "ha": return (value+0x8000) >> 16
            value &= 0xffff
            return value if value < 0x8000 else value-0x10000
        return labels[token] if token in labels else int(token, 0)
    def loc(self, token):
        displacement, reg = token[:-1].split("(")
        return (self.r[int(reg[1:])] + self.value(displacement)) & 0xffffffff
    def set(self, label, offset, value):
        self.mem[labels[label]+offset] = value & 0xffffffff
    def get(self, label, offset=0):
        return self.mem[labels[label]+offset]
    def run(self, pc):
        if isinstance(pc,str): pc=labels[pc]
        for _ in range(300):
            if pc not in instructions: return pc
            op,*a = instructions[pc]
            nxt=pc+4
            reg=lambda t: int(t[1:])
            if op in ("lis","li"):
                self.r[reg(a[0])] = (self.value(a[1]) << (16 if op=="lis" else 0)) & 0xffffffff
            elif op=="addi":
                self.r[reg(a[0])] = (self.r[reg(a[1])] + self.value(a[2])) & 0xffffffff
            elif op=="stw": self.mem[self.loc(a[1])] = self.r[reg(a[0])]
            elif op=="lwz": self.r[reg(a[0])] = self.mem[self.loc(a[1])]
            elif op=="lfs": self.f[reg(a[0])] = struct.unpack(">f",struct.pack(">I",self.mem[self.loc(a[1])]))[0]
            elif op in ("cmpwi","cmpw"):
                def signed(v): return v if v < 0x80000000 else v-0x100000000
                x=signed(self.r[reg(a[0])]); y=self.value(a[1]) if op=="cmpwi" else signed(self.r[reg(a[1])])
                self.cr=(x>y)-(x<y)
            elif op=="andi.":
                value=self.r[reg(a[1])] & self.value(a[2]); self.r[reg(a[0])]=value; self.cr=(value>0)
            elif op=="mflr": self.r[reg(a[0])] = self.lr
            elif op=="blr": return self.lr
            elif op in ("b","beq","bne","bge"):
                take={"b":True,"beq":self.cr==0,"bne":self.cr!=0,"bge":self.cr>=0}[op]
                if take: nxt=self.value(a[0])
            else: raise AssertionError(op)
            pc=nxt
        raise AssertionError("instruction budget")
    def frame(self, generation, valid=1, buttons=0x40, accepted=True):
        # rrBeforeCalc resets the active flag before the seqlock read.
        self.set("mbState",0,0)
        self.set("mtPad",0,generation)
        self.set("mtPad",88,valid)
        self.set("mtPad",140,buttons)
        self.r[10]=labels["mtPad"]
        if accepted: self.run(0x1800000)
        return self.get("mbState")

checks=0
def check(condition):
    global checks
    assert condition
    checks+=1

# A new controller sample keeps the gesture alive regardless of refresh rate.
for hz in (60,90,120,144):
    c=CPU()
    for frame in range(hz*5): check(c.frame(frame+1)==1)
    check(c.frame(hz*5+1,buttons=0)==0)
    check(c.frame(hz*5+2)==1)
    check(c.frame(hz*5+3,valid=0)==1) # microphone blowing needs no tracked hand
    check(c.frame(hz*5+4,valid=0,buttons=0x3f)==0) # untracked: only the blow bit counts
    check(c.frame(hz*5+4)==1)
    check(c.frame(hz*5+5,accepted=False)==0) # invalid or torn packet
    check(c.frame(hz*5+6)==1)
    check(c.frame(hz*5+7,buttons=0x3f)==0) # buttons are not blow input
c=CPU()
check(c.frame(42)==1)
for age in range(1,100): check(c.frame(42)==(1 if age<4 else 0))
check(c.get("mbState",8)==4) # saturating age cannot wrap back to active
check(c.frame(43)==1)
for generation in (0xfffffffe,0xffffffff,0,1,2):
    check(c.frame(generation)==(0 if generation==0 else 1))
c.set("rrEnabled",0,0);check(c.frame(3)==0)

# Each getter must tail-resume native microphone code when inactive and leave
# all native arguments intact. Active hooks only replace their return value.
for name in [n for n in labels if re.fullmatch(r"mbGet\w+",n) and not n.endswith(("Native","Resume"))]:
    is_float=name in ("mbGetRaw","mbGetFiltered","mbGetNormalized")
    for active in (0,1):
        for enabled in (0,1):
            c=CPU();c.set("mbState",0,active);c.set("rrEnabled",0,enabled)
            before=c.r.copy();floats=c.f.copy();mem=c.mem.copy()
            destination=c.run(name)
            if active and enabled:
                check(destination==c.lr)
                if is_float:
                    check(c.f[1]==(1.0 if name=="mbGetNormalized" else 3300.0))
                    check(c.r[3]==before[3])
                else: check(c.r[3]==1)
                check(c.r[0]==before[0])
            else:
                check(destination==labels[name+"Resume"])
                check(c.r[0]==c.lr)
                check(c.r[3]==before[3])
                check(c.f==floats) # native audio including silence/negative sentinel unchanged
            check(c.r[1:3]==before[1:3] and c.r[4:12]==before[4:12] and c.r[13:]==before[13:])
            check(c.f[:1]==floats[:1] and c.f[2:]==floats[2:])
            check(c.mem==mem) # no game objects, sample buffers, stack or mic state modified

# The state update is reached only AFTER the existing seqlock acceptance.
check(source.index("stw r11, mbState@l(r12)") < source.index("; Pose packet"))
check("cmpw r7, r11\nbne rrPoseLatchDone\nstw r7, 0(r12)\n; Accept the gesture" in source)
print(f"{checks} PPC microphone checks passed; actual headset/game test pending")
