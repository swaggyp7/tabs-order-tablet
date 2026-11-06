"""Drive the real tablet and framework callbacks through a five-order program."""
from pathlib import Path
import sys
import os
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
def load(path):
    lua.execute((ROOT/path).read_text(encoding='utf-8-sig'))
load('tests/vehicle_recorder_mock.lua')
lua.execute("""
setupVehicle()
V=TABSVehicles[100]; V.parts={hull=10,weapons={}}
W={reloadtimer=0,shoottimer=0,rotspeed=10,ammo=3}
function W:getTurret() return {rotspeed=10} end
function W:getTransform() return GetBodyTransform(10) end
function W:getDir() return V.controls.aimdir end
W.name="Cannon"; W.curShell=1; W.shelltypes={{name={"AP"},ammo=2},{name={"HE"},ammo=2}}
function W:getCurShell() return self.shelltypes[self.curShell] end
MG=setmetatable({name="Coax",curShell=1,shelltypes={{name={"Tracer"},ammo=5}},reloadtimer=0},{__index=W})
V.wheels={left={501},right={502},origDrives={[501]=1,[502]=1}}
entities[501]={}; entities[502]={}; V.tracks={left={},right={}}
power={}
function SetProperty(w,k,p) assert(k=="drive"); power[w]=p end
V.parts.weapons={W,MG}; V.controls.curWeapon=1
function GetVehicleTransform(id) return GetBodyTransform(GetVehicleBody(id)) end
function VecNormalize(a) return VecScale(a,1/math.max(VecLength(a),.001)) end
function GetBodyVelocity(b) return Vec() end
function GetQuatEuler() return 0,0,0 end
function QuatLookAt() return Quat() end
QuatRotateQuat=QuatMul
function GetProperty(w,k) assert(k=="drive"); return power[w] or 1 end
function SetBodyTransform() error("planner moved body directly") end
function SetBodyVelocity() error("planner set velocity directly") end
function SetBodyAngularVelocity() error("planner set angular velocity directly") end
function DriveVehicle(id,throttle,steer,brake)
    assert(phase=="tick","DriveVehicle outside tick")
    assert(id==100 or id==200)
    demand={throttle=throttle,steer=steer,brake=brake}
end
function PlayShootSound(...) end
function HandleTurretRotation(...) end
function HandleTankAI(...) end
function ApplyTankMovement(...) end
function ClearKey(k) registry[k]=nil end
function GetShapeBody(s) return s end
function RegisterTool(id,name,file,group) assert(group==6 and file=="MOD/tool.xml"); tool=id end
function GetCameraTransform() return Transform(Vec(10,2,30)) end
function QueryRaycast() return true,rayDist or 10,Vec(0,1,0),rayBody or 10 end
shots={}
function ShootWeapon(v,w,dt)
    shots[#shots+1]=GetInt('level.tvrplan.car.'..v.vehiclehandle..'.index')
    local shell=w:getCurShell(); shell.ammo=shell.ammo-1; w.reloadtimer=1
end
function SetToolTransformOverride(t) toolPose=t end
function SetToolHandPoseLocalTransform(r,l) handPose=r end
function tick() end
function update() end
""")
replay_main=os.environ.get('TVR_TEST_REPLAY_MAIN')
if replay_main:
    replay=Path(replay_main).read_text(encoding='utf-8-sig')
    lua.execute('function SaveDebugInfo() end; function ProjectileOperations() end; function SpallOperations() end; function Spall() end')
    lua.execute(replay[replay.index('-- Local TABS Hit Replay integration'):])
for name in ('core','weapons','bridge'):
    load('tabs-vehicle-recorder/'+name+'.lua')
lua.execute("""
local nativeTick,nativeUpdate=tick,update
function backendTick(dt) phase="tick"; nativeTick(dt); phase=nil end
function backendUpdate(dt) phase="update"; nativeUpdate(dt); phase=nil end
-- Wheel contact stub is separate from the command sink. It cannot turn an
-- update-only input or a direct transform/velocity write into a passing test.
function physics(dt)
    if demand and not demand.brake then
        local l=(power[501] or 1)*demand.throttle
        local r=(power[502] or 1)*demand.throttle
        local t=entities[10].transform
        t.rot=QuatMul(t.rot,QuatEuler(0,(r-l)*60*dt,0))
        t.pos=TransformToParentPoint(t,Vec(0,0,-(r+l)*2*dt))
    end
    demand=nil
end
""")
load('tabs-vehicle-recorder/main.lua')
lua.execute("""
init(); registry['game.player.tool']=tool
function click(key)
    if key=="f8" and HasKey("level.wtr.bridgeVersion") then key="f6" end
    pressed={[key]=true}; tick(); pressed={}
end
backendTick(0); click('lmb'); backendTick(0)
rayBody=30; rayDist=15; click('lmb')
click('q'); rayBody=40; click('lmb'); click('x'); click('lmb')
click('q'); click('q'); rayBody=30; rayDist=25; click('lmb')
click('q'); rayBody=40; click('z'); click('lmb'); click('f7'); backendTick(3)
backendTick(.016)
local p='level.tvrplan.car.100.'
assert(GetBool(p..'running') and GetInt('level.tvrplan.count')==5)
assert(GetInt(p..'index')==1 and demand.throttle>0 and not demand.brake)
local before=copy(entities[10].transform)
backendUpdate(.1)
near(entities[10].transform.pos,before.pos)
assert(power[501]>0 and power[502]>0)
for i=1,200 do
    if GetInt(p.."index")==1 then backendTick(.05); physics(.05) end
end
assert(GetInt(p..'index')==2 and entities[10].transform.pos[3]<18)
entities[40].transform.pos[1]=entities[40].transform.pos[1]+8
backendUpdate(.1); assert(#shots==1 and shots[1]==2 and GetInt(p..'index')==3)
assert(V.controls.aimdir[1]>0,'aim follows moving target')
backendUpdate(.1); assert(#shots==1,'must await reload')
W.reloadtimer=0; backendUpdate(.1); assert(shots[2]==3 and GetInt(p..'index')==4)
backendUpdate(.1); assert(GetInt(p..'index')==4 and #shots==2)
for i=1,300 do if GetInt(p.."index")==4 then backendTick(.05); physics(.05) end end; W.reloadtimer=0; backendUpdate(.1)
assert(shots[3]==5 and not GetBool(p..'running') and W.shelltypes[1].ammo==1 and W.shelltypes[2].ammo==1 and MG.shelltypes[1].ammo==4)
click('f7'); backendTick(3); backendTick(0); click('f5'); backendTick(0)
assert(not GetBool(p..'running') and #shots==3)
-- A tank pivots on opposing wheel torque before advancing behind its hull.
local goal=TransformToParentPoint(GetBodyTransform(10),Vec(8,0,12))
local saved={}; local arrived=false
phase="tick"
for i=1,900 do
    arrived=TVRPlan.move(V,goal,saved)
    if i==1 then assert(power[501]*power[502]<0) end
    if arrived then break end
    physics(1/60)
end
assert(arrived)
TVRPlan.releaseWheels(saved); assert(power[501]==1 and power[502]==1)
V.criticalErrorTracks=true
TVRPlan.move(V,TransformToParentPoint(GetBodyTransform(10),Vec(5,0,-10)),{})
assert(demand.throttle>0 and demand.steer<0 and not demand.brake)
phase=nil
""")
print('PASS: tablet selection, mixed five-order execution, moving target, reload, ammo and stop')


lua.execute("""
-- Configure a moving-fire segment through actual tablet inputs.
V.criticalErrorTracks=false
entities[10].transform=Transform(Vec(10,0,30))
MG.reloadtimer=0; MG.shoottimer=0; MG.shelltypes[1].ammo=5
click('delete'); click('q'); rayBody=40; click('lmb')
rayBody=30; rayDist=40; click('lmb')
rayDist=60; click('lmb'); click('f7'); backendTick(3); backendTick(.05)
local p='level.tvrplan.car.100.'
assert(GetBool('level.tvrplan.step.1.attack'))
assert(not GetBool('level.tvrplan.step.2.attack'))
assert(demand.throttle>0 and not demand.brake)
local before=copy(entities[10].transform.pos); physics(.1)
assert(VecLength(VecSub(entities[10].transform.pos,before))>0)
function GetBodyVelocity() return Vec(0,0,-4) end
local n=#shots
backendUpdate(.1)
assert(#shots==n+1 and GetInt(p..'index')==1,'must shoot at speed without advancing waypoint')
backendUpdate(.1); assert(#shots==n+1,'moving fire respects reload')
MG.reloadtimer=0; backendUpdate(.1); assert(#shots==n+2)
click('f5'); backendTick(0); MG.reloadtimer=0; backendUpdate(.1)
assert(#shots==n+2 and not GetBool(p..'running'))
""")
print('PASS: moving fire at speed, target serialization, segment isolation, reload and stop')

lua.execute("""
-- Build a second vehicle plan and execute both using the real F8 command.
entities[200]={body=20,tags={TABS=true}}
entities[20]=copy(entities[10]); entities[20].vehicle=200
local second=copy(V); second.vehiclehandle=200; second.parts.hull=20
TABSVehicles[200]=second
click('r'); rayBody=20; click('lmb'); backendTick(0)
rayBody=30; rayDist=80; click('lmb')
-- Default 3 s -> 5 -> 7 -> 10 -> 3 -> 5, independently for car 200.
for i=1,5 do click('t') end
click('f8'); backendTick(0)
local a='level.tvrplan.car.100.'; local b='level.tvrplan.car.200.'
assert(GetBool(a..'running') and GetBool(b..'running'))
assert(GetFloat(a..'delay')==3 and GetFloat(b..'delay')==5)
assert(demand.brake and GetInt(a..'index')==1 and GetInt(b..'index')==1)
local n=#shots; backendUpdate(.1); assert(#shots==n,'countdown must not fire')
backendTick(2); backendUpdate(.1); assert(#shots==n)
assert(GetFloat(a..'delay')==1 and GetFloat(b..'delay')==3)
backendTick(1); assert(GetFloat(a..'delay')==0 and GetFloat(b..'delay')==2)
-- F5 cancels the selected second car while it is still waiting.
click('f5'); backendTick(0)
assert(not GetBool(b..'running') and GetBool(a..'running'))
-- Re-trigger all does not restart the first car's active script.
click('f8'); backendTick(0)
assert(GetFloat(a..'delay')==0 and GetFloat(b..'delay')==5)
assert(toolPose.pos[1]>0 and toolPose.pos[2]<0 and handPose)
""")
print('PASS: F8 batches independent plans, four delay choices, countdown suppresses fire, cancel waiting and no restart')

lua.execute("""
-- The HUD remains balanced with countdowns, expanded controls and small screens.
local depth=0; local text={}
function UiPush() depth=depth+1 end
function UiPop() depth=depth-1; assert(depth>=0) end
function UiWidth() return 960 end
function UiHeight() return 540 end
function UiScale(s) assert(s>0 and s<=1) end
function UiAlign() end
function UiColor() end
function UiTranslate() end
function UiRect(w,h) assert(w<=500 and h<=400) end
function UiWindow(w,h) assert(w>0 and h>0) end
function UiFont() end
function UiText(s) text[s]=true end
draw(); assert(depth==0 and text['COUNTDOWN'] and text['F7  START      '..(HasKey('level.wtr.bridgeVersion') and 'F6' or 'F8')..'  START ALL      F5  STOP'])
click('h'); draw(); assert(depth==0 and text['T  Start delay: 3 / 5 / 7 / 10 seconds'])
""")
print('PASS: compact HUD, expanded help and small-screen draw lifecycle')

if replay_main:
    lua.execute("""
    assert(GetInt('level.wtr.bridgeVersion')==3 and GetInt('level.tvrplan.motionVersion')==6)
    local seq=GetInt('level.tvrplan.request')
    pressed={f8=true}; tick(); pressed={}
    assert(GetInt('level.tvrplan.request')==seq,'F8 must remain reserved for Hit Replay')
    pressed={f6=true}; tick(); pressed={}
    assert(GetInt('level.tvrplan.request')==seq+1,'F6 must launch fleet with replay bridge')
    assert(WTR.now>0)
    """)
    print('PASS: real Hit Replay callback chain survives Fusion queues; F8 reserved and F6 starts fleet')
