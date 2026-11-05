function TVRPlan.catalog(p,v)
    local weapons=v.parts.weapons
    for i,w in ipairs(weapons) do
        local key=p..i.."."
        SetString(key.."name",w.name or ("Weapon "..i))
        local shells=w.shelltypes or {}
        SetInt(key.."count",#shells)
        SetInt(key.."current",w.curShell or 1)
        for j,s in ipairs(shells) do
            local name=s.beltname or (type(s.name)=="table" and s.name[1]) or (type(s.name)=="string" and s.name)
            SetString(key..j,name or ("Ammo "..j))
        end
    end
    SetInt(p.."count",#weapons)
    SetInt(p.."current",v.controls.curWeapon or 1)
    SetInt(p.."vehicle",v.vehiclehandle)
end

function TVRPlan.aim(v,w,point)
    local origin=w:getTransform().pos
    local direction=VecNormalize(VecSub(point,origin))
    v.controls.aimpos=origin
    v.controls.aimdir=direction
    v.controls.aimOY,v.controls.aimOX=GetQuatEuler(QuatLookAt(origin,point))
    local turret=w:getTurret()
    if w.ballJoint then HandleBallRot(true,v,w,w.rotspeed)
    else HandleTurretRotation(v,false,w,turret,0,turret.rotspeed,w.rotspeed,true,turret.rotxsound) end
    return VecDot(VecNormalize(w:getDir()),direction)>math.cos(math.rad(2))
end

function TVRPlan.fire(v,w,dt)
    local key="level.tabs.balistics.last_vehicle_fired"
    local existed,old=HasKey(key),GetInt(key)
    -- TABS prefers the player's occupied vehicle over last_vehicle_fired.
    -- Track only the pool slots written by this synchronous native shot.
    local pool=TABSProjectileHandler
    local first=pool and pool.shellNum
    local limit=NoProjectileLimit and PROJECTILE_LIMIT
    local predecessor=first and limit and (first-2)%limit+1
    local previous=predecessor and pool.shells[predecessor]
    SetInt(key,v.vehiclehandle)
    local ok,reason=pcall(function()
        PlayShootSound(v,w)
        ShootWeapon(v,w,dt)
    end)
    if existed then SetInt(key,old) else ClearKey(key) end
    if first then
        local count=pool.shellNum-first
        if limit then
            count=pool.shells[predecessor]~=previous and limit or count%limit
        end
        for offset=0,count-1 do
            local i=limit and (first+offset-1)%limit+1 or first+offset
            if pool.shells[i] then pool.shells[i].vInfo=v end
        end
    end
    if not ok then error(reason) end
end
