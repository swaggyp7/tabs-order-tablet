do
    local P=TVRPlan.prefix
    local runs={}
    local last=0
    local finalBrakes={}
    local function brake(v)
        v.controls.drive=0; v.controls.steer=0; v.controls.handbrake=true
    end
    local function statusKey(id) return P.."car."..id.."." end
    local function finish(run,msg)
        TVRPlan.releaseWheels(run.wheelDrives)
        finalBrakes[run.id]=true
        local v=TABSVehicles[run.id]
        if v and TVRPlan.valid(run.id) then
            for _,k in ipairs({"drive","steer","handbrake","aimOX","aimOY","targetVehicle"}) do
                v.controls[k]=run.saved[k]
            end
            -- In-flight TABS rounds still read both guidance vectors.
            v.controls.aimpos=run.saved.aimpos or v.controls.aimpos
            v.controls.aimdir=run.saved.aimdir or v.controls.aimdir
        end
        runs[run.id]=nil
        SetBool(run.key.."running",false)
        SetString(run.key.."message",msg)
    end
    local function start(id)
        if runs[id] then return end
        local key=statusKey(id)
        local v=TABSVehicles[id]
        if not v or not TVRPlan.valid(id) then return SetString(key.."message","Select a live TABS vehicle") end
        if GetPlayerVehicle()==id then return SetString(key.."message","Exit this vehicle first") end
        local count=GetInt(P.."count")
        if count<1 or count>TVRPlan.limit then return SetString(key.."message","Add an order first") end
        local steps={}
        for i=1,count do
            local key=P.."step."..i.."."
            local kind=GetString(key.."kind")
            if kind~="move" and kind~="fire" then return SetString(statusKey(id).."message","Invalid order") end
            steps[i]={kind=kind,weapon=GetInt(key.."weapon"),ammo=GetInt(key.."ammo"),body=GetInt(key.."body"),point=Vec(GetFloat(key.."x"),GetFloat(key.."y"),GetFloat(key.."z"))}
            if kind=="move" and GetBool(key.."attack") then
                local k=key.."target."
                steps[i].attack={weapon=GetInt(k.."weapon"),ammo=GetInt(k.."ammo"),body=GetInt(k.."body"),point=Vec(GetFloat(k.."x"),GetFloat(k.."y"),GetFloat(k.."z"))}
            end
        end
        local saved={}
        for k,x in pairs(v.controls) do saved[k]=x end
        runs[id]={id=id,key=key,steps=steps,i=1,time=0,saved=saved,wheelDrives={}}
        SetBool(key.."running",true); SetString(key.."message","Executing"); SetInt(key.."index",1)
    end
    local function shoot(run,step,point,dt,moving)
        local v=TABSVehicles[run.id]
        local index=step.weapon>0 and step.weapon or v.controls.curWeapon
        local w=v.parts.weapons[index]
        if not w or w.broken or w:getTurret().broken then return finish(run,"Stopped: weapon unavailable") end
        if step.ammo>0 then
            if not w.shelltypes or not w.shelltypes[step.ammo] then return finish(run,"Stopped: ammunition type unavailable") end
            if w.curShell~=step.ammo then
                local old=w:getCurShell()
                w.curShell=step.ammo
                if old and old.ammo==0 and old.reserveammo==0 then w.triggerReload=true end
            end
        end
        v.controls.curWeapon=index
        if w.triggerReload then return end
        local target=step.body~=0 and GetBodyVehicle(step.body) or 0
        v.controls.targetVehicle=target~=0 and target or nil
        local aligned=TVRPlan.aim(v,w,point)
        if (w.reloadtimer or 0)>0 or (w.shoottimer or 0)>0 then
            local timer=math.max(w.reloadtimer or 0,w.shoottimer or 0)
            if not moving and run.timer and timer>=run.timer then run.stalled=(run.stalled or 0)+dt
            else run.stalled=0 end
            run.timer=timer
            if not moving and run.stalled>10 then return finish(run,"Stopped: weapon reload stalled") end
            if not moving then run.time=0 end; return
        end
        local shell=w:getCurShell()
        if not shell or shell.ammo<=0 then return finish(run,"Stopped: out of ammunition") end
        if not aligned or (not moving and VecLength(GetBodyVelocity(v.parts.hull))>1) then
            if not moving and run.time>20 then finish(run,"Stopped: cannot align gun") end
            return
        end
        TVRPlan.fire(v,w,dt)
        return true
    end
    local function advance(run,dt)
        local v=TABSVehicles[run.id]
        if not v or not TVRPlan.valid(run.id) then return finish(run,"Vehicle lost") end
        if GetPlayerVehicle()==run.id then return finish(run,"Stopped: manual control") end
        local step=run.steps[run.i]
        local point=TVRPlan.point(step)
        if not point then return finish(run,"Stopped: target lost") end
        run.time=run.time+dt
        if step.kind=="move" then
            local arrived,distance,reason=TVRPlan.move(v,point,run.wheelDrives)
            SetFloat(run.key.."remaining",distance)
            if reason then return finish(run,"Stopped: "..reason) end
            if not arrived then
                if not run.best or distance<run.best-.5 then run.best=distance; run.progress=run.time end
                if run.time-run.progress>12 then
                    local wheels=v.wheels or {}
                    local speed=VecLength(GetBodyVelocity(GetVehicleBody(run.id)))
                    local detail=string.format("drive %.2f, speed %.1f m/s, wheels %d/%d",
                        GetVehicleDrive(run.id),speed,#(wheels.left or {}),#(wheels.right or {}))
                    print("TABS Order Tablet v3: "..(v.displayName or tostring(run.id)).." - stalled: "..detail)
                    finish(run,"Waypoint stalled: "..detail)
                end
                return
            end
            brake(v)
            DriveVehicle(v.vehiclehandle,0,0,true)
        else
            brake(v)
            if not shoot(run,step,point,dt,false) then return end
        end
        run.i=run.i+1; run.time=0; run.best=nil; run.timer=nil; run.stalled=nil
        if run.i>#run.steps then finish(run,"Plan complete")
        else SetInt(run.key.."index",run.i) end
    end
    local ai=HandleTankAI
    function HandleTankAI(v,...)
        if not runs[v.vehiclehandle] then return ai(v,...) end
    end
    local movement=ApplyTankMovement
    function ApplyTankMovement(v,...)
        -- Submit the planner input once, after the framework tick.
        if runs[v.vehiclehandle] then return end
        return movement(v,...)
    end
    local function guardedAdvance(run,dt)
        local ok,err=pcall(advance,run,dt)
        if not ok then finish(run,"Stopped: "..tostring(err)); DebugPrint("Order Tablet: "..tostring(err)) end
    end
    local originalTick=tick
    function tick(dt)
        SetFloat(P.."bridgeTime",GetTime())
        SetInt(P.."motionVersion",5)
        if not HasKey(P.."clientTime") or math.abs(GetTime()-GetFloat(P.."clientTime"))>.75 then
            for _,run in pairs(runs) do finish(run,"Tool disabled") end
        else
            local selected=GetInt(P.."inspect")
            if selected~=GetInt(P.."catalog.vehicle") and TABSVehicles[selected] then
                TVRPlan.catalog(P.."catalog.",TABSVehicles[selected])
            end
            local seq=GetInt(P.."request")
            if seq~=last then
                last=seq
                local id=GetInt(P.."vehicle")
                if GetString(P.."command")=="run" then start(id)
                elseif runs[id] then finish(runs[id],"Stopped") end
                SetInt(P.."ack",seq)
            end
        end
        local occupied=GetPlayerVehicle()
        if runs[occupied] then finish(runs[occupied],"Stopped: manual control") end
        originalTick(dt)
        for id in pairs(finalBrakes) do
            if not runs[id] and TVRPlan.valid(id) and GetPlayerVehicle()~=id then DriveVehicle(id,0,0,true) end
            finalBrakes[id]=nil
        end
        for id,run in pairs(runs) do
            if run.steps[run.i].kind=="move" then guardedAdvance(run,dt)
            elseif TVRPlan.valid(id) and GetPlayerVehicle()~=id then DriveVehicle(id,0,0,true) end
        end
    end
    local originalUpdate=update
    function update(dt)
        originalUpdate(dt)
        for _,run in pairs(runs) do
            local step=run.steps[run.i]
            if step.kind=="fire" then guardedAdvance(run,dt)
            elseif step.attack then
                local ok,err=pcall(function()
                    local point=TVRPlan.point(step.attack)
                    if not point then return finish(run,"Stopped: target lost") end
                    shoot(run,step.attack,point,dt,true)
                end)
                if not ok then finish(run,"Stopped: "..tostring(err)) end
            end
        end
    end
end
