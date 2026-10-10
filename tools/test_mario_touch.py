"""Run the production Mario touch PPC helpers with synthetic memory, offline."""
from pathlib import Path
import re,struct,math,itertools,random
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'graphicPacks/Mario3DWorld_VR/patch_vr.asm').read_text(encoding='utf-8')
body=s.split('[Mario3DWorld_Touch_EU_v0]')[1].split('[Mario3DWorld_Touch_Passthrough]')[0]
for label,n in [('tcPadReady',1),('tcButtons',3),('mtPad',40),('mbState',3),('mrCullEpoch',1),('mrSceneClass',1),('rrSlot',1),('mtNearState',4),('mtControl',18),('rrPoseLatch0',98)]:
 body+='\n'+label+':\n'+'.int 0\n'*n
body += "\n"+s[s.index('mtMotionRightDoneBit1:'):s.index('mtMotionRightDoneBit3:')]+"mtMotionRightDoneBit3:\nblr\n"
labels={};mem={};code={};pc=0x1800000
f32=lambda v:struct.unpack('>f',struct.pack('>f',v))[0]
bits=lambda v:struct.unpack('>I',struct.pack('>f',v))[0]
flt=lambda v:struct.unpack('>f',struct.pack('>I',v))[0]
for raw in body.splitlines():
 line=raw.split(';',1)[0].strip()
 if not line or line.startswith(('moduleMatches','.origin','0x')):continue
 if line.endswith(':'):
  assert line[:-1] not in labels;labels[line[:-1]]=pc;continue
 if line.startswith('.int'):
  v=int(line.split()[1],0);mem[pc]=v
  if v in (0x7C000026,0x7C0FF120,0x7C0902A6,0x7C0903A6,0x7C2004AC) or v>>26 in (50,54):code[pc]=['raw',v]
 elif line.startswith('.float'):mem[pc]=bits(float(line.split()[1]))
 else:code[pc]=line.replace(',',' ').split()
 pc+=4
class CPU:
 def __init__(self):
  self.m=mem.copy();self.r=[0x25000000+i*256 for i in range(32)];self.r[1]=0x31000000
  self.f=[i+.375 for i in range(32)];self.lr=0;self.cr=0;self.ctr=42;self.events=[];self.trace=[];self.externals={}
 def val(self,t):
  if '@' in t:
   k,p=t.split('@');v=labels[k]
   return (v+0x8000)>>16 if p=='ha' else ((v&65535)^32768)-32768
  return labels[t] if t in labels else int(t,0)
 def addr(self,t):
  off,r=t[:-1].split('(');i=int(r[1:]);return ((self.r[i] if i else 0)+self.val(off))&0xffffffff
 def set(self,k,off,v):self.m[labels[k]+off]=v&0xffffffff
 def get(self,k,off=0):return self.m.get(labels[k]+off,0)
 def vec(self,p,v):
  for i,x in enumerate(v):self.m[p+4*i]=bits(x)
 def readvec(self,p,n=3):return [flt(self.m.get(p+4*i,0)) for i in range(n)]
 def call(self,label):
  pc=labels[label];self.lr=0x7ffffffc
  for _ in range(20000):
   if pc==0x7ffffffc:return
   if pc not in code:
    self.events.append(pc);self.trace.append((pc,self.r.copy()))
    if pc in self.externals:self.externals[pc](self)
    pc=self.lr;continue
   op,*a=code[pc];nxt=pc+4;r=lambda t:int(t[1:]);signed=lambda v:(v^0x80000000)-0x80000000
   if op=='raw':
    v=a[0]
    if v==0x7C000026:self.r[0]=self.cr&0xffffffff
    elif v==0x7C0FF120:self.cr=signed(self.r[0])
    elif v==0x7C0902A6:self.r[0]=self.ctr
    elif v==0x7C0903A6:self.ctr=self.r[0]
    elif v==0x7C2004AC:pass
    else:
     i=(v>>21)&31;at=(self.r[(v>>16)&31]+(v&65535))&0xffffffff
     if v>>26==54:
      lo,hi=struct.unpack('>II',struct.pack('>d',self.f[i]));self.m[at]=lo;self.m[at+4]=hi
     else:self.f[i]=struct.unpack('>d',struct.pack('>II',self.m[at],self.m[at+4]))[0]
   elif op in ('li','lis'):self.r[r(a[0])]=(self.val(a[1])<<(16 if op=='lis' else 0))&0xffffffff
   elif op=='addi':self.r[r(a[0])]=((self.r[r(a[1])] if r(a[1]) else 0)+self.val(a[2]))&0xffffffff
   elif op=='add':self.r[r(a[0])]=(self.r[r(a[1])]+self.r[r(a[2])])&0xffffffff
   elif op=='and':self.r[r(a[0])]=self.r[r(a[1])]&self.r[r(a[2])]
   elif op=='subf':self.r[r(a[0])]=(self.r[r(a[2])]-self.r[r(a[1])])&0xffffffff
   elif op=='mulli':self.r[r(a[0])]=(self.r[r(a[1])]*self.val(a[2]))&0xffffffff
   elif op in ('stw','stwu'):
    at=self.addr(a[1]);self.m[at]=self.r[r(a[0])]
    if op=='stwu':self.r[int(a[1][a[1].index('(r')+2:-1])]=at
   elif op=='lwz':self.r[r(a[0])]=self.m.get(self.addr(a[1]),0)
   elif op=='lbz':
    at=self.addr(a[1]);self.r[r(a[0])]=(self.m.get(at&~3,0)>>(8*(3-(at&3))))&255
   elif op=='lfs':self.f[r(a[0])]=flt(self.m.get(self.addr(a[1]),0))
   elif op=='stfs':self.m[self.addr(a[1])]=bits(self.f[r(a[0])])
   elif op in ('fmuls','fadds','fsubs'):
    x,y=self.f[r(a[1])],self.f[r(a[2])];self.f[r(a[0])]=f32(x*y if op=='fmuls' else x+y if op=='fadds' else x-y)
   elif op in ('fneg','fmr'):self.f[r(a[0])]=self.f[r(a[1])]*(-1 if op=='fneg' else 1)
   elif op in ('cmpw','cmpwi','cmplw','cmplwi'):
    x=self.r[r(a[0])];y=self.val(a[1]) if op.endswith('i') else self.r[r(a[1])]
    if not op.startswith('cmpl'):x=signed(x);y=signed(y&0xffffffff)
    self.cr=(x>y)-(x<y)
   elif op in ('andi.','ori'):
    x=self.r[r(a[1])];v=self.val(a[2]);v=x&v if op=='andi.' else x|v;self.r[r(a[0])]=v
    if op=='andi.':self.cr=(v>0)
   elif op=='mr':self.r[r(a[0])]=self.r[r(a[1])]
   elif op=='mflr':self.r[r(a[0])]=self.lr
   elif op=='mtlr':self.lr=self.r[r(a[0])]
   elif op=='blr':nxt=self.lr
   elif op in ('b','bl','beq','bne','blt','ble','bge','bgt'):
    take={'b':True,'bl':True,'beq':self.cr==0,'bne':self.cr!=0,'blt':self.cr<0,'ble':self.cr<=0,'bge':self.cr>=0,'bgt':self.cr>0}[op]
    if take:
     if op=='bl':self.lr=nxt
     nxt=self.val(a[0])
   else:raise AssertionError((op,a))
   pc=nxt
  raise AssertionError('instruction budget '+label)
checks=0
def check(ok,msg):
 global checks
 assert ok,msg;checks+=1

def inputs():
 c=CPU();c.set('tcPadReady',0,1);c.set('mtPad',0,200);c.set('mtPad',88,1)
 c.set('tcWorld',48,100);c.set('mrCullEpoch',0,100);c.set('tcPacket',8,99);c.set('tcPacket',12,3);return c
for grip,trigger,valid,fresh,lease in itertools.product((0,1),repeat=5):
 c=inputs();c.set('mtPad',140,grip*32+trigger*16);c.set('mtPad',88,valid);c.set('tcPadReady',0,fresh)
 if not lease:c.set('tcPacket',8,80)
 registers=c.r.copy();floats=c.f.copy();c.call('tcInputUpdate');active=grip and valid and fresh and lease
 check(c.get('tcButtons')==active,'grip ownership');check(c.get('tcButtons',4)==(active and trigger),'trigger needs grip')
 check(c.get('tcButtons',8)==(active and trigger),'jump consumed only for touch')
 check(c.r==registers and c.f==floats and c.ctr==42,'input hook preserves native state')
c=inputs()
for buttons,held,down,consumed in [(32,1,0,0),(48,1,1,1),(16,0,0,1),(0,0,0,0),(16,0,0,0)]:
 c.set('mtPad',140,buttons);c.call('tcInputUpdate');check(tuple(c.get('tcButtons',i*4) for i in range(3))==(held,down,consumed),'release must not cause a jump')
for buttons,expected,consumed in [(0,0,0),(16,16384,0),(32,0,0),(48,0,1),(16,0,1)]:
 c=inputs();c.set('mtPad',140,buttons);c.set('tcButtons',8,consumed);c.call('tcInputUpdate')
 c.r[5]=0;c.r[6]=0xffffffff;c.r[11]=buttons;c.call('mtMotionRightDoneBit1')
 check(c.r[5]==expected,'native VPAD jump/R mapping respects grip ownership')
# Camera/anchor transforms: arbitrary independent head and rig orientations.
# Expected rays come from the original rigid world transform, not a copy of
# the inverse-camera expression in production assembly.
def rot(yaw,pitch):
 y,p=math.cos(yaw),math.cos(pitch);a,b=math.sin(yaw),math.sin(pitch)
 return [[y,a*b,a*p],[0,p,-b],[-a,y*b,y*p]]
def mul(a,b):return [[sum(a[i][k]*b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def tr(a):return list(map(list,zip(*a)))
def mv(a,v):return [sum(x*y for x,y in zip(row,v)) for row in a]
random.seed(42)
for mode in (0,1,2):
 for slot,eye in itertools.product((0,1),repeat=2):
  for case in range(20):
   c=inputs();scale=.1 if mode==1 else 1
   W=rot(random.uniform(-3,3),random.uniform(-1,1));D=rot(random.uniform(-2,2),random.uniform(-1,1))
   t=[random.uniform(-300,300) for _ in range(3)];dt=[random.uniform(-100,100) for _ in range(3)]
   V=mul(D,tr(W));vt=[scale*dt[i]-v for i,v in enumerate(mv(V,t))]
   view=0x28000000;c.r[9]=view;c.r[10]=eye;c.vec(view,[v for i in range(3) for v in V[i]+[vt[i]]])
   c.set('mrSceneClass',0,0x103286DC);c.set('rrSlot',0,slot);c.set('mtNearState',(slot*2+eye)*4,mode)
   c.set('rrPoseLatch0',slot*196,400);c.vec(labels['rrPoseLatch0']+slot*196+4+(48 if eye==0 else 0),[v for i in range(3) for v in D[i]+[dt[i]]])
   c.call('tcCameraCapture');check(c.r[9]==view and c.r[10]==eye,'camera hook preserves pointers')
   # Grip and aim differ in both pitch and origin. Only aim may drive touch.
   c.vec(labels['mtPad']+92,[1,0,0,99,0,1,0,888,0,0,1,77])
   hand=rot(.3,-.4);origin=[15,25,35];ap=labels['tcAimHistory']+((400//2)%8)*56
   c.m[ap]=400;c.m[ap+4]=1;c.vec(ap+8,[v for i in range(3) for v in hand[i]+[origin[i]]])
   c.set('tcButtons',0,1);c.call('tcPrepareRay');check(c.get('tcRay')==1,'fresh ray')
   want=[v+t[i] for i,v in enumerate(mv(W,[scale*x for x in origin]))];direction=mv(W,[-hand[i][2] for i in range(3)])
   check(max(abs(a-b) for a,b in zip(c.readvec(labels['tcRay']+16),want))<.001,'world ray origin')
   check(max(abs(a-b) for a,b in zip(c.readvec(labels['tcRay']+28),direction))<.00001,'world ray direction')
   hit=[13,24,-35];c.vec(labels['tcRay']+52,hit);c.set('tcRay',8,1);c.set('tcHand',4,1);c.set('tcHand',8,100)
   c.r[9]=view;c.r[10]=eye;c.call('tcCameraCapture');record=labels['tcPacket']+16+(slot*2+eye)*160
   check(c.m[record]==400 and c.m[record+16]==2,'action point stamped with complete pose')
   expected=[v+vt[i] for i,v in enumerate(mv(V,hit))]
   check(max(abs(a-b) for a,b in zip(c.readvec(record+20),expected))<.001,'rendered-eye hit position')
   c.set('mrCullEpoch',0,104);c.call('tcPrepareRay');check(c.get('tcRay')==0,'old camera cannot drive touch')
# First hover classification never depends on the preceding interaction.
for previous,platform in itertools.product((0,1),(False,True)):
 c=inputs();c.set('tcRay',0,1);c.set('tcRay',8,previous);mesh=0x26000000;obj=0x27000000;component=0x27100000;owner=0x27200000
 c.r[28]=mesh;c.m[mesh]=obj;c.m[obj+0x120]=component;c.m[component+0x2c]=owner;c.m[owner]=0x102E17D8 if platform else 0x10001000
 c.vec(mesh+0x64,[1,2,3]);c.call('tcMeshHit')
 check(c.get('tcRay',8)==platform,'only current platform gets activation symbol');check(c.readvec(labels['tcRay']+52)==[1,2,3],'nearest hit point')
# Reset clears even reused object addresses. Test actual entry-hook tail return.
c=inputs();c.set('tcWorld',48,100);c.set('tcRay',0,1);c.set('tcGuides',0,0x20000000);c.set('tcGuides',4,100)
c.call('tcManagerReset');check(c.get('tcWorld',48)==c.get('tcRay')==c.get('tcGuides')==c.get('tcGuides',4)==0,'level construction clears old state')
print(f'{checks} production PPC touch checks passed; headset/game test pending')

for present in (False,True):
 c=inputs();guide=0x26000000;point=0x28000000;c.r[3]=guide;c.r[5]=point;c.vec(point,[25,50,-100]);c.m[guide+0x4c]=0x01010000
 if present:c.set('tcGuides',0,guide)
 c.call('tcGuideAnchor');check(c.get('tcGuides',4)==(100 if present else 0),'only registered touch guide captured')
 if present:check(c.readvec(labels['tcGuides']+8)==[25,50,-100],'native world anchor unchanged')
 c.events=[];c.r[3]=guide;c.call('tcGuideDraw');check((0x0245EA14 not in c.events)==present,'only replaced guide draw suppressed')
 c.events=[];c.set('tcPacket',12,1);c.r[3]=guide;c.call('tcGuideDraw');check(0x0245EA14 in c.events,'host unavailable keeps native guide')
print(f'{checks} total PPC checks including native guide preservation')

# Aim history is accepted only for the full latched sequence, including wraps.
for seq in (2,14,16,131070,131072,0xfffffffe):
 for published,valid in ((seq,1),(seq+2,1),(seq-16,1),(seq-1,1),(seq,0)):
  c=inputs();c.set('tcButtons',0,1);c.set('rrPoseLatch0',0,seq)
  c.vec(labels['tcWorld'],[1,0,0,0,0,1,0,0,0,0,1,0]);c.set('tcWorld',52,bits(1.))
  ap=labels['tcAimHistory']+((seq//2)%8)*56;c.m[ap]=published;c.m[ap+4]=valid
  c.vec(ap+8,[1,0,0,12,0,1,0,34,0,0,1,56]);c.call('tcPrepareRay')
  check(c.get('tcRay')==int(published==seq and valid==1),'wrong generation/invalid aim must not touch')
# Cursor's hover and activation hooks use exactly the same point as rendering.
c=inputs();c.set('tcRay',0,1);c.vec(labels['tcRay']+16,[10,20,30]);c.vec(labels['tcRay']+28,[.2,.3,-.9]);c.vec(labels['tcRay']+52,[40,50,60])
c.r[3]=0x28000000;c.call('tcUnproject');check(c.readvec(0x28000000)==[40,50,60],'activation point equals marker hit')
c.r[3]=0x28000000;c.call('tcNormalize');check(max(abs(a-b) for a,b in zip(c.readvec(0x28000000),[.2,.3,-.9]))<1e-6,'native ray uses aim direction')
print(f'{checks} total PPC touch checks including aim/grip separation and aim-history reuse')

check(labels['tcAimHistory']-labels['tcPacket']==656,'aim history host/guest offset')
check(labels['tcAimPose']-labels['tcPacket']==1104,'bounded host/guest mailbox size')
# Eight newer publications reuse a slot but must never match its old sequence.
for seq in range(2,34,2):
 c=inputs();c.set('tcButtons',0,1);c.set('rrPoseLatch0',0,seq)
 ap=labels['tcAimHistory']+((seq//2)%8)*56;c.m[ap]=seq+16;c.m[ap+4]=1
 c.call('tcPrepareRay');check(c.get('tcRay')==0,'history slot reuse cannot activate an old frame')
print(f'{checks} total PPC touch checks including mailbox bounds and expired slots')

# Native model placement consumes exactly the activation/ring point, not the
# native screen-space estimate. Other actors and non-VR calls pass through.
for active,matching in itertools.product((0,1),repeat=2):
 c=inputs();actor=0x26000000;c.r[3]=actor;c.r[4]=0x27000000
 c.set('tcRay',0,active);c.set('tcHand',0,actor if matching else actor+4)
 c.call('tcHandPosition')
 check(c.trace[-1][0]==0x02406778,'native position setter preserved')
 check(c.trace[-1][1][4]==(labels['tcRay']+52 if active and matching else 0x27000000),'shared hand/activation point')
# Hover never runs the game's interaction/sensor dispatch, including stale
# native touch-data flags. A physical trigger is the only VR activation path.
for active,down,action in itertools.product((0,1),repeat=3):
 c=inputs();c.set('tcRay',0,active);c.set('tcRay',8,action);c.set('tcButtons',4,down)
 c.call('tcHandControl')
 check((0x021A69D4 in c.events)==bool(not active or down),'hover cannot dispatch gameplay touch')
 check((0x02401720 in c.events)==bool(active and down and not action),'neutral touch hides native hand')
 c.events=[];c.call('tcHandRelease')
 check((0x021A7890 in c.events)==bool(not active or not action),'hover does not begin release animation')
# Preview lifetimes use only the current manager-owned model, then clear on
# pointer leave, grip release and level construction. No input flags are written.
for active,action,down,owned in itertools.product((0,1),repeat=4):
 c=inputs();actor=0x26000000;c.r[3]=actor;c.set('tcHand',0,actor);c.set('tcHand',12,owned)
 c.set('tcRay',0,active);c.set('tcRay',8,action);c.set('tcButtons',4,down)
 c.externals[0x023FC848]=lambda c:c.r.__setitem__(3,1)
 c.externals[0x02441238]=lambda c:c.r.__setitem__(3,0)
 before=[c.get('tcButtons',i) for i in (0,4,8)];regs=c.r[13:].copy();sp=c.r[1]
 c.call('tcHandPreview');shown=bool(active and action)
 check(c.get('tcHand',4)==shown,'native replacement only for actionable hover')
 check((0x021A7574 in c.events)==shown,'hand placed only for actionable hover')
 check((0x02414194 in c.events)==bool(shown and not down),'visual appear is hover-only')
 check((0x0241433C in c.events)==bool(not shown and owned and not down),'preview released when leaving target')
 check(before==[c.get('tcButtons',i) for i in (0,4,8)],'preview leaves input unchanged')
 check(c.r[13:]==regs and c.r[1]==sp,'preview preserves nonvolatile ABI')
# No replacement packet is advertised merely because the collision is actionable.
for visible,epoch in [(0,100),(1,99),(1,100)]:
 c=inputs();c.set('tcRay',0,1);c.set('tcRay',8,1);c.set('tcRay',12,100)
 c.set('tcHand',4,visible);c.set('tcHand',8,epoch);c.set('tcWorld',68,400)
 c.r[9]=0x28000000;c.r[10]=0;c.call('tcPublish')
 check(c.get('tcPacket',32)==(2 if visible and epoch==100 else 1),'ring remains until native hand is ready this epoch')
c=inputs();c.set('tcHand',0,0x26000000);c.set('tcHand',4,1);c.set('tcHand',8,100);c.set('tcHand',12,1)
c.call('tcManagerReset');check(all(c.get('tcHand',i)==0 for i in (0,4,8,12)),'scene reset clears native hand identity and visibility')
print(f'{checks} total PPC checks including native preview/activation separation and placement')


# Visual alignment changes only a call-local model matrix; no second general
# actor/collision update is run and the gameplay position is never moved.
for ready,fresh,joint in itertools.product((0,1),repeat=3):
 c=inputs();actor=0x26000000;pose=0x27000000;matrix=0x28000000;c.r[3]=actor
 c.m[actor+0x44]=0x29000000;c.set('tcHand',0,actor);c.set('tcHand',4,ready);c.set('tcHand',8,100 if fresh else 99)
 c.vec(pose,[40,50,60]);c.vec(labels['tcRay']+52,[40,50,60]);c.vec(matrix,[1,0,0,60,0,1,0,68,0,0,1,72])
 c.externals[0x02402550]=lambda c:c.r.__setitem__(3,joint)
 c.externals[0x0240257C]=lambda c:c.r.__setitem__(3,matrix)
 c.externals[0x02407214]=lambda c:c.vec(c.r[3],[1,0,0,40,0,1,0,50,0,0,1,60])
 rendered=[];c.externals[0x023FBC24]=lambda c:rendered.append([flt(c.m[c.r[4]+o]) for o in (12,28,44)])
 c.call('tcHandCalc');align=bool(ready and fresh and joint)
 check(c.events.count(0x024146A0)==1,'general actor/collision update runs exactly once')
 check(len(rendered)==int(align),'only valid preview gets model-only alignment')
 if align:check(rendered[0]==[20,32,48],'animated finger offset subtracted from model matrix')
 check(c.readvec(pose)==[40,50,60],'visual alignment never moves gameplay pose')
print(f'{checks} total PPC checks including animated finger alignment without collision changes')
