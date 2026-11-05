-- Deterministic engine surface for recorder math and lifecycle tests.
registry = {}; entities = {}; nativeCalls = {}; replayed = {}; writes = {}
clock = 10; playerVehicle = 0; pressed = {}; down = {}; rays = {hit=true, distance=10, normal={0,1,0}}

function copy(value)
    if type(value)~="table" then return value end
    local out={}; for k,v in pairs(value) do out[k]=copy(v) end; return out
end
function Vec(x,y,z) return {x or 0,y or 0,z or 0} end
function VecAdd(a,b) return Vec(a[1]+b[1],a[2]+b[2],a[3]+b[3]) end
function VecSub(a,b) return Vec(a[1]-b[1],a[2]-b[2],a[3]-b[3]) end
function VecScale(a,s) return Vec(a[1]*s,a[2]*s,a[3]*s) end
function VecDot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
function VecLength(a) return math.sqrt(VecDot(a,a)) end
function VecLerp(a,b,t) return VecAdd(a,VecScale(VecSub(b,a),t)) end
function Quat() return {0,0,0,1} end
function QuatConjugate(q) return {-q[1],-q[2],-q[3],q[4]} end
function QuatMul(a,b)
    return {a[4]*b[1]+a[1]*b[4]+a[2]*b[3]-a[3]*b[2],
        a[4]*b[2]-a[1]*b[3]+a[2]*b[4]+a[3]*b[1],
        a[4]*b[3]+a[1]*b[2]-a[2]*b[1]+a[3]*b[4],
        a[4]*b[4]-a[1]*b[1]-a[2]*b[2]-a[3]*b[3]}
end
function QuatEuler(x,y,z)
    x,y,z=math.rad(x)/2,math.rad(y)/2,math.rad(z)/2
    return QuatMul(QuatMul({0,math.sin(y),0,math.cos(y)},{math.sin(x),0,0,math.cos(x)}),{0,0,math.sin(z),math.cos(z)})
end
function QuatRotateVec(q,v)
    local t=QuatMul(QuatMul(q,{v[1],v[2],v[3],0}),QuatConjugate(q)); return Vec(t[1],t[2],t[3])
end
function QuatSlerp(a,b,t)
    local dot=0; for i=1,4 do dot=dot+a[i]*b[i] end
    b=copy(b)
    if dot<0 then dot=-dot; for i=1,4 do b[i]=-b[i] end end
    dot=math.max(-1,math.min(1,dot))
    local x,y
    if dot>0.9995 then x,y=1-t,t
    else local angle=math.acos(dot); x,y=math.sin((1-t)*angle)/math.sin(angle),math.sin(t*angle)/math.sin(angle) end
    local out,n={},0
    for i=1,4 do out[i]=x*a[i]+y*b[i]; n=n+out[i]^2 end
    for i=1,4 do out[i]=out[i]/math.sqrt(n) end
    return out
end
function Transform(pos,rot) return {pos=copy(pos or Vec()),rot=copy(rot or Quat())} end
function TransformToParentVec(t,v) return QuatRotateVec(t.rot,v) end
function TransformToLocalVec(t,v) return QuatRotateVec(QuatConjugate(t.rot),v) end
function TransformToParentPoint(t,p) return VecAdd(t.pos,TransformToParentVec(t,p)) end
function TransformToLocalPoint(t,p) return TransformToLocalVec(t,VecSub(p,t.pos)) end
function TransformToParentTransform(t,b) return Transform(TransformToParentPoint(t,b.pos),QuatMul(t.rot,b.rot)) end
function TransformToLocalTransform(t,b) return Transform(TransformToLocalPoint(t,b.pos),QuatMul(QuatConjugate(t.rot),b.rot)) end
function near(a,b,message)
    if type(a)=="table" then for i=1,#a do near(a[i],b[i],message) end
    else assert(math.abs(a-b)<1e-6,(message or "numbers differ")..": "..tostring(a).." != "..tostring(b)) end
end
function IsHandleValid(h) return entities[h]~=nil end
function GetVehicleBody(h) return entities[h].body end
function GetBodyVehicle(h) return entities[h].vehicle or 0 end
function IsBodyDynamic(h) return entities[h].dynamic~=false end
function IsBodyBroken(h) return entities[h].broken or false end
function GetBodyTransform(h) return copy(entities[h].transform) end
function GetJointedBodies(h) return copy(entities[h].linked or {h}) end
function GetBodyBounds(h)
    local e=entities[h]; local ext=e.ext or Vec(.5,.5,.5)
    return VecSub(e.transform.pos,ext),VecAdd(e.transform.pos,ext)
end
function SetBodyTransform(h,t) writes[#writes+1]={kind="pose",body=h}; entities[h].transform=copy(t) end
function SetBodyVelocity(h,v) writes[#writes+1]={kind="velocity",body=h}; entities[h].velocity=copy(v) end
function SetBodyAngularVelocity(h,v) writes[#writes+1]={kind="angular",body=h}; entities[h].angular=copy(v) end
function HasTag(h,t) return entities[h] and entities[h].tags and entities[h].tags[t]~=nil or false end
function GetString(k) return registry[k] or "" end
function GetBool(k) return registry[k] or false end
function GetInt(k) return registry[k] or 0 end
function GetFloat(k) return registry[k] or 0 end
function SetString(k,v) registry[k]=v end
function SetBool(k,v) registry[k]=v end
function SetInt(k,v) registry[k]=v end
function SetFloat(k,v) registry[k]=v end
function HasKey(k) return registry[k]~=nil end
function GetTime() return clock end
function GetPlayerVehicle() return playerVehicle end
function DebugPrint(s) lastError=s end
function InputPressed(k) return pressed[k] or false end
function InputDown(k) return down[k] or false end
function InputClear() pressed={} end
function GetCameraTransform() return Transform(Vec(0,5,0)) end
function QueryRejectVehicle(v) rejectedVehicle=v end
function QueryRequire(v) requireArg=v end
function QueryRaycast(...) return rays.hit,rays.distance,rays.normal end
function DrawLine(...) end

function setupVehicle()
    entities={
        [100]={body=10,tags={TABS=""}}, [200]={body=40,tags={TABS=""}},
        [10]={vehicle=100,transform=Transform(Vec(10,2,20)),linked={10,20}},
        [20]={transform=Transform(Vec(10,3,18))},
        [30]={transform=Transform(Vec(9,1,20)),dynamic=false},
        [40]={vehicle=200,transform=Transform(Vec(70,2,50)),linked={40}},
    }
    TABSVehicles={
        [100]={vehiclehandle=100,controls={curWeapon=1},tracks={left={pieces={{handle=30},{handle=30}}}}},
        [200]={vehiclehandle=200,controls={curWeapon=2}},
    }
end
function nativeCall(name,v)
    nativeCalls[name]=nativeCalls[name] or {}
    local vehicle=v and v.vehiclehandle or 0
    nativeCalls[name][vehicle]=(nativeCalls[name][vehicle] or 0)+1
end
function HandleTankAI(v) nativeCall("ai",v) end
function ApplyTankMovement(v) nativeCall("movement",v) end
function HandleTracks(v) nativeCall("tracks",v) end
function tick(dt)
    nativeCall("tick")
    for _,v in pairs(TABSVehicles) do HandleTankAI(v); ApplyTankMovement(v); HandleTracks(v) end
    if nativeAction then nativeAction(dt) end
end
function update(dt)
    nativeCall("update")
    for _,v in pairs(TABSVehicles) do HandleTankAI(v); ApplyTankMovement(v); HandleTracks(v) end
end
TVRWeapons={
    captureState=function(v) return copy(v.controls) end,
    applyState=function(v,s) v.controls=copy(s) end,
    install=function(onShot,isRecording,isPlaying)
        shotHook,recordPredicate,playPredicate=onShot,isRecording,isPlaying
    end,
    replayShot=function(v,event,dt)
        replayed[#replayed+1]={id=event.id,time=event.time,position=GetBodyTransform(GetVehicleBody(v.vehiclehandle)).pos}
        return event.unavailable~=true
    end,
}
function recordShot(vehicle,event)
    local v=TABSVehicles[vehicle]
    if recordPredicate(v) then shotHook(v,copy(event)) end
end
function lease()
    registry["level.tvr.enabled"]=true
    registry["level.tvr.clientTime"]=clock
end
function command(value)
    registry["level.tvr.command"]=value
    registry["level.tvr.request"]=(registry["level.tvr.request"] or 0)+1
end
function step(dt)
    clock=clock+dt; lease(); tick(dt)
end
