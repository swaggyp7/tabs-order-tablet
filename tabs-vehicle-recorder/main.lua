local P="level.tvrplan."
local TOOL="tabs_order_tablet"
local vehicle=0
local steps={}
local plans={}
local delays={3,5,7,10}
local function statusKey() return P.."car."..vehicle.."." end
local mode="move"
local notice=""
local attack=nil
local pending=nil
local showHelp=false
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
local function serialize(prefix,id,plan)
    SetInt(prefix.."vehicle",id); SetInt(prefix.."count",#plan.steps)
    SetInt(prefix.."delay",delays[plan.delay or 1])
    for i,s in ipairs(plan.steps) do
        local k=prefix.."step."..i.."."
        SetString(k.."kind",s.kind); SetInt(k.."body",s.body)
        SetBool(k.."attack",s.attack~=nil)
        if s.attack then
            local t=s.attack; local key=k.."target."
            SetInt(key.."body",t.body); SetInt(key.."weapon",t.weapon); SetInt(key.."ammo",t.ammo)
            SetFloat(key.."x",t.point[1]); SetFloat(key.."y",t.point[2]); SetFloat(key.."z",t.point[3])
        end
        SetInt(k.."weapon",s.weapon or 0); SetInt(k.."ammo",s.ammo or 0)
        SetFloat(k.."x",s.point[1]); SetFloat(k.."y",s.point[2]); SetFloat(k.."z",s.point[3])
    end
end
local function execute()
    if #steps==0 then notice="Add a waypoint or target first"; return end
    serialize(P,vehicle,plans[vehicle]); send("run")
end
local function executeAll()
    if not ready() then notice="Enable TABS and reload the level"; return end
    local count=0
    for id,plan in pairs(plans) do
        if valid(id) and #plan.steps>0 then
            count=count+1; serialize(P.."batch."..count..".",id,plan)
        end
    end
    if count==0 then notice="No vehicle plans to execute"; return end
    SetInt(P.."batch.count",count); send("runall")
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
        attack=plan.attack
        SetInt(P.."inspect",v); SetInt(catalog.."vehicle",0)
        notice="Vehicle selected"; return
    end
    if #steps>=128 then notice="128 order limit"; return end
    if mode=="move" and n[2]<.55 then notice="Choose drivable ground"; return end
    local point=VecAdd(t.pos,VecScale(dir,dist))
    local body=0
    if mode~="move" and IsBodyDynamic(b) then body=b; point=TransformToLocalPoint(GetBodyTransform(b),point) end
    if mode~="move" and (not loaded() or weapon==0 or GetInt(catalog..weapon..".count")==0) then
        notice="Waiting for an available weapon"; return
    end
    if mode=="movingfire" then
        attack={body=body,point=point,weapon=weapon,ammo=ammo}
        mode="move"; notice="Target selected: click the next waypoint"; return
    end
    steps[#steps+1]={kind=mode,body=body,point=point,weapon=weapon,ammo=ammo,attack=mode=="move" and attack or nil}
    if mode=="move" then attack=nil end
    notice="Added order "..#steps
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
            if s.attack then
                local t=s.attack
                local target=t.body==0 and t.point or (valid(t.body) and TransformToParentPoint(GetBodyTransform(t.body),t.point))
                if target then DrawLine(p,target,1,.35,.25,1) end
            end
            if moving then last=p end
        end
    end
end
function init()
    RegisterTool(TOOL,"TABS Fusion","MOD/tool.xml",6)
    SetBool("game.tool."..TOOL..".enabled",true)
end
function tick()
    SetFloat(P.."clientTime",GetTime())
    if pending and GetInt(P.."ack")==pending then pending=nil end
    local running=GetBool(statusKey().."running")
    if running and not pending and InputPressed("f5") then send("stop"); return end
    if not equipped() then return end
    -- Explicit camera-space pose avoids the generic tool's head-level fallback.
    if not GetBool("game.thirdperson") then
        SetToolTransformOverride(Transform(Vec(0.42,-0.48,-0.3),QuatEuler(0,-30,0)))
        SetToolHandPoseLocalTransform(Transform(Vec(0,0,-0.05),QuatEuler(0,90,0)),nil)
    end
    if valid(vehicle) then markers() elseif vehicle~=0 then plans[vehicle]=nil; vehicle=0; steps={}; notice="Vehicle lost" end
    if InputPressed("h") then showHelp=not showHelp end
    if pending then return end
    if InputPressed("f8") then executeAll(); return end
    if vehicle~=0 and InputPressed("r") then
        local plan=plans[vehicle]
        plan.mode,plan.weapon,plan.ammo,plan.attack=mode,weapon,ammo,attack
        attack=nil
        vehicle=0; steps={}; notice="Select a vehicle"; return
    end
    if running then return end
    if loaded() and weapon==0 and GetInt(catalog.."count")>0 then selectWeapon(GetInt(catalog.."current")) end
    if valid(vehicle) and InputPressed("t") then
        local plan=plans[vehicle]; plan.delay=(plan.delay or 1)%#delays+1; notice="Start delay: "..delays[plan.delay].." s"
    elseif valid(vehicle) and InputPressed("delete") then
        steps={}; attack=nil; plans[vehicle].steps=steps; notice="Selected plan cleared"
    elseif InputPressed("q") and valid(vehicle) then mode=mode=="move" and "fire" or (mode=="fire" and "movingfire" or "move"); notice=""
    elseif InputPressed("g") then attack=nil; notice="Moving fire target cleared"
    elseif mode~="move" and loaded() and InputPressed("z") and GetInt(catalog.."count")>0 then
        selectWeapon(weapon%GetInt(catalog.."count")+1); notice=""
    elseif mode~="move" and loaded() and InputPressed("x") and GetInt(catalog..weapon..".count")>0 then
        ammo=ammo%GetInt(catalog..weapon..".count")+1; notice=""
    elseif InputPressed("backspace") and #steps>0 then table.remove(steps); notice="Removed last order"
    elseif InputPressed("f7") and valid(vehicle) then execute()
    elseif InputPressed("lmb") then pick() end
end
function draw()
    if not equipped() then return end
    local selected=valid(vehicle)
    local running=selected and GetBool(statusKey().."running")
    local wait=running and GetFloat(statusKey().."delay") or 0
    local index=GetInt(statusKey().."index")
    local online=ready() and GetInt(P.."motionVersion")==6
    local names={move="ROUTE",fire="SINGLE SHOT",movingfire="MOVING FIRE"}
    local state=not online and "OFFLINE" or (wait>0 and "COUNTDOWN" or (running and "RUNNING" or (selected and names[mode] or "SELECT VEHICLE")))
    local accent=not online and {1,.48,.3} or (running and {1,.72,.28} or {.28,.85,.7})
    local scale=math.min(1,UiWidth()/1280,UiHeight()/720)
    local height=showHelp and 398 or 298
    UiPush(); UiTranslate(24,UiHeight()-24-height*scale); UiScale(scale); UiAlign("left top")
    UiColor(.035,.05,.065,.94); UiRect(500,height)
    UiColor(unpack(accent)); UiRect(3,height)
    local function text(x,y,value,size,color,width)
        UiPush(); UiTranslate(x,y); UiWindow(width or (480-x),size+7,true)
        UiFont("regular.ttf",size); UiColor(unpack(color or {.88,.92,.94})); UiText(value); UiPop()
    end
    local function rule(y)
        UiPush(); UiTranslate(18,y); UiColor(1,1,1,.10); UiRect(464,1); UiPop()
    end
    text(18,14,"TABS / FUSION",19)
    text(330,17,state,13,accent,152)
    local fleet=0
    for id,plan in pairs(plans) do if valid(id) and #plan.steps>0 then fleet=fleet+1 end end
    text(18,44,selected and ("VEHICLE #"..vehicle.."   /   "..#steps.." ORDERS") or "Aim at a TABS vehicle and click to select",14,{.6,.67,.72})
    text(18,66,selected and ("T  DELAY "..delays[plans[vehicle].delay or 1].."s    /    "..fleet.." VEHICLE PLANS") or (fleet.." vehicle plans ready   /   F8 to start all"),13,{.6,.67,.72})
    rule(90)
    local first=running and math.max(1,index) or math.max(1,#steps-2)
    if #steps==0 then
        text(18,106,selected and "No orders yet" or "Plan routes. Assign targets. Execute together.",16)
        text(18,133,"LMB  Select / add     Q  Route / Shot / Moving fire",13,{.6,.67,.72})
    else
        for row=0,2 do
            local n=first+row; local step=steps[n]
            if step then
                local label=step.kind=="fire" and "FIRE" or (step.attack and "MOVE + FIRE" or "MOVE")
                local target=step.attack or step
                if step.kind=="fire" or step.attack then label=label.."   W"..target.weapon.." / A"..target.ammo end
                text(18,102+row*23,string.format("%03d",n),13,{.6,.67,.72},40)
                text(65,100+row*23,label,15,(running and n==index) and accent or nil)
            end
        end
    end
    local status=notice~="" and notice or GetString(statusKey().."message")
    if attack then status="Target ready: click a waypoint  /  G cancel" end
    if running then
        status=wait>0 and string.format("Starting in %.1f seconds",wait) or ("Executing order "..index.." / "..#steps)
        if wait<=0 and steps[index] and steps[index].kind=="move" then status=status..string.format("  /  %.1f m",GetFloat(statusKey().."remaining")) end
    end
    if not online then status="TABS connection unavailable. Enable TABS and reload." end
    text(18,178,status~="" and status or "Ready",13,accent)
    if mode~="move" and loaded() then
        text(18,202,"Z  "..GetString(catalog..weapon..".name").."    X  "..GetString(catalog..weapon.."."..ammo),13)
    else text(18,202,"LMB  Add order     Q  Change mode     R  Select vehicle",13,{.6,.67,.72}) end
    rule(228)
    text(18,242,"F7  START      F8  START ALL      F5  STOP",15)
    text(18,270,"H  "..(showHelp and "Hide controls" or "Show controls"),12,{.6,.67,.72})
    if showHelp then
        rule(294)
        text(18,306,"Q  Route > Single shot > Moving fire target",13)
        text(18,328,"Z / X  Weapon / Ammo     G  Cancel pending target",13)
        text(18,350,"Backspace  Undo     Delete  Clear     R  Select vehicle",13)
        text(18,372,"T  Start delay: 3 / 5 / 7 / 10 seconds",13)
    end
    UiPop()
end
