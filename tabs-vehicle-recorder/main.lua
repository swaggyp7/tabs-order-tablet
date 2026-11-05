local P="level.tvrplan."
local TOOL="tabs_order_tablet"
local vehicle=0
local steps={}
local plans={}
local function statusKey() return P.."car."..vehicle.."." end
local mode="move"
local notice=""
local pending=nil
local catalog=P.."catalog."
local weapon,ammo=0,0
local function loaded()
    return vehicle~=0 and vehicle==GetInt(catalog.."vehicle")
end
local function selectWeapon(i)
    weapon=i
    ammo=math.max(1,GetInt(catalog..i..".current"))
end

local function valid(h) return h and h~=0 and IsHandleValid(h) end
local function equipped()
    return GetString("game.player.tool")==TOOL and GetPlayerVehicle()==0
end
local function ready()
    return HasKey(P.."bridgeTime") and math.abs(GetTime()-GetFloat(P.."bridgeTime"))<.75
end
local function send(command)
    if not ready() then notice="Enable TABS and reload the level"; return end
    local seq=GetInt(P.."request")+1
    SetInt(P.."vehicle",vehicle)
    SetString(P.."command",command); SetInt(P.."request",seq); pending=seq
    notice=""
end
local function execute()
    if #steps==0 then notice="Add a waypoint or target first"; return end
    SetInt(P.."vehicle",vehicle); SetInt(P.."count",#steps)
    for i,s in ipairs(steps) do
        local k=P.."step."..i.."."
        SetString(k.."kind",s.kind); SetInt(k.."body",s.body)
        SetInt(k.."weapon",s.weapon or 0); SetInt(k.."ammo",s.ammo or 0)
        SetFloat(k.."x",s.point[1]); SetFloat(k.."y",s.point[2]); SetFloat(k.."z",s.point[3])
    end
    send("run")
end
local function owner(b)
    local v=GetBodyVehicle(b)
    if valid(v) then return v end
    v=GetEntityParent(b,"","vehicle")
    if valid(v) then return v end
    if IsBodyDynamic(b) then
        for _,linked in ipairs(GetJointedBodies(b)) do
            v=GetBodyVehicle(linked)
            if valid(v) then return v end
        end
    end
    return 0
end
local function pick()
    local t=GetCameraTransform()
    local dir=TransformToParentVec(t,Vec(0,0,-1))
    if valid(vehicle) then QueryRejectVehicle(vehicle) end
    QueryRequire("physical")
    local hit,dist,n,shape=QueryRaycast(t.pos,dir,1000)
    if not hit then notice="Aim at a visible surface"; return end
    local b=GetShapeBody(shape)
    if not valid(vehicle) then
        local v=owner(b)
        if not valid(v) or not HasTag(v,"TABS") then notice="Aim at a TABS vehicle"; return end
        vehicle=v
        local plan=plans[v] or {steps={},mode="move",weapon=0,ammo=0}
        plans[v]=plan
        steps,mode,weapon,ammo=plan.steps,plan.mode,plan.weapon,plan.ammo
        SetInt(P.."inspect",v); SetInt(catalog.."vehicle",0)
        notice="Vehicle selected"; return
    end
    if #steps>=128 then notice="128 order limit"; return end
    if mode=="move" and n[2]<.55 then notice="Choose drivable ground"; return end
    local point=VecAdd(t.pos,VecScale(dir,dist))
    local body=0
    if mode=="fire" and IsBodyDynamic(b) then body=b; point=TransformToLocalPoint(GetBodyTransform(b),point) end
    if mode=="fire" and (not loaded() or weapon==0 or GetInt(catalog..weapon..".count")==0) then
        notice="Waiting for an available weapon"; return
    end
    steps[#steps+1]={kind=mode,body=body,point=point,weapon=weapon,ammo=ammo}; notice="Added order "..#steps
end
local function markers()
    local last=GetVehicleTransform(vehicle).pos
    for _,s in ipairs(steps) do
        local p=s.point
        if s.body~=0 then p=valid(s.body) and TransformToParentPoint(GetBodyTransform(s.body),p) or nil end
        if p then
            local moving=s.kind=="move"
            local r,g,b=moving and .1 or 1,moving and .9 or .35,.25
            p=VecAdd(p,Vec(0,.15,0))
            DrawLine(last,p,r,g,b,.7)
            DrawLine(VecAdd(p,Vec(-.45,0,0)),VecAdd(p,Vec(.45,0,0)),r,g,b,1)
            DrawLine(p,VecAdd(p,Vec(0,1,0)),r,g,b,1)
            if moving then last=p end
        end
    end
end
function init()
    RegisterTool(TOOL,"TABS Order Tablet","MOD/tool.xml",6)
    SetBool("game.tool."..TOOL..".enabled",true)
end
function tick()
    SetFloat(P.."clientTime",GetTime())
    if pending and GetInt(P.."ack")==pending then pending=nil end
    local running=GetBool(statusKey().."running")
    if running and not pending and InputPressed("f5") then send("stop"); return end
    if not equipped() then return end
    if valid(vehicle) then markers() elseif vehicle~=0 then plans[vehicle]=nil; vehicle=0; steps={}; notice="Vehicle lost" end
    if pending then return end
    if vehicle~=0 and InputPressed("r") then
        local plan=plans[vehicle]
        plan.mode,plan.weapon,plan.ammo=mode,weapon,ammo
        vehicle=0; steps={}; notice="Select a vehicle"; return
    end
    if running then return end
    if loaded() and weapon==0 and GetInt(catalog.."count")>0 then selectWeapon(GetInt(catalog.."current")) end
    if valid(vehicle) and InputPressed("delete") then
        steps={}; plans[vehicle].steps=steps; notice="Selected plan cleared"
    elseif InputPressed("q") and valid(vehicle) then mode=mode=="move" and "fire" or "move"; notice=""
    elseif mode=="fire" and loaded() and InputPressed("z") and GetInt(catalog.."count")>0 then
        selectWeapon(weapon%GetInt(catalog.."count")+1); notice=""
    elseif mode=="fire" and loaded() and InputPressed("x") and GetInt(catalog..weapon..".count")>0 then
        ammo=ammo%GetInt(catalog..weapon..".count")+1; notice=""
    elseif InputPressed("backspace") and #steps>0 then table.remove(steps); notice="Removed last order"
    elseif InputPressed("f7") and valid(vehicle) then execute()
    elseif InputPressed("lmb") then pick() end
end
function draw()
    if not equipped() then return end
    local running=GetBool(statusKey().."running")
    UiPush(); UiTranslate(26,UiHeight()-205); UiFont("regular.ttf",17); UiAlign("left top")
    UiColor(.03,.05,.07,.9); UiRect(720,185); UiTranslate(14,10); UiColor(1,1,1)
    local function line(s) UiText(s); UiTranslate(0,25) end
    line("TABS ORDER TABLET  v4  /  "..(running and "EXECUTING" or (vehicle==0 and "SELECT" or string.upper(mode))))
    line(vehicle==0 and "LMB  Select vehicle" or "LMB  Add order      Q  Move / Fire      Backspace  Undo      R  Switch vehicle")
    line("F7  Execute     F5  Stop selected     Del  Clear    |    Vehicle #"..vehicle.."    "..#steps.." orders")
    if mode=="fire" and loaded() then
        line("Z  Weapon: "..GetString(catalog..weapon..".name").."     X  Ammo: "..GetString(catalog..weapon.."."..ammo))
    end
    local first=running and math.max(1,GetInt(statusKey().."index")-1) or math.max(1,#steps-5)
    local labels={}
    for i=first,math.min(#steps,first+5) do
        local s=steps[i]
        labels[#labels+1]=i.." "..(s.kind=="fire" and ("FIRE "..s.weapon.."/"..s.ammo) or "MOVE")
    end
    line(table.concat(labels,"   "))
    local i=GetInt(statusKey().."index")
    local status=notice~="" and notice or GetString(statusKey().."message")
    if running then
        status="Executing order "..i
        if steps[i] and steps[i].kind=="move" then status=status..string.format("   %.1f m remaining",GetFloat(statusKey().."remaining")) end
    end
    if not ready() or GetInt(P.."motionVersion")~=4 then status="Reload the level to load the v4 TABS bridge" end
    line(status)
    UiPop()
end
