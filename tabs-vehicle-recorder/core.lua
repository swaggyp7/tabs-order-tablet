TVRPlan = {prefix="level.tvrplan.", limit=128}

function TVRPlan.valid(h)
    return type(h)=="number" and h~=0 and IsHandleValid(h)
end

function TVRPlan.point(step)
    if step.body~=0 then
        if not TVRPlan.valid(step.body) then return nil end
        return TransformToParentPoint(GetBodyTransform(step.body),step.point)
    end
    return step.point
end

-- Native wheel inputs are frame controls: call this from tick, never update.
local function clamp(x,lo,hi) return math.max(lo,math.min(hi,x)) end

function TVRPlan.releaseWheels(saved)
    for wheel,value in pairs(saved) do
        if TVRPlan.valid(wheel) then SetProperty(wheel,"drive",value) end
    end
end

local function trackPower(v,side,power,saved)
    for _,wheel in ipairs(v.wheels[side]) do
        if TVRPlan.valid(wheel) then
            if saved[wheel]==nil then saved[wheel]=GetProperty(wheel,"drive") end
            SetProperty(wheel,"drive",power*(v.wheels.origDrives[wheel] or saved[wheel]))
        end
    end
end

function TVRPlan.move(v,point,saved)
    local hull=GetVehicleBody(v.vehiclehandle)
    if not TVRPlan.valid(hull) then return false,0,"Vehicle body missing" end
    local pose=GetVehicleTransform(v.vehiclehandle)
    local delta=VecSub(point,pose.pos)
    local distance=math.sqrt(delta[1]^2+delta[3]^2)
    if distance<2 then
        if math.abs(delta[2])>5 then return false,distance,"Waypoint on another level" end
        return true,distance
    end
    local localDir=TransformToLocalVec(pose,Vec(delta[1],0,delta[3]))
    local angle=math.atan2(-localDir[1],-localDir[3])
    local turn=clamp(angle*1.4,-1,1)
    if math.abs(angle)<.035 then turn=0 end
    local wheels=v.wheels
    local tracked=not v.criticalErrorTracks and wheels and #wheels.left>0 and #wheels.right>0
    local speed=VecLength(GetBodyVelocity(hull))
    local desired=clamp((distance-1)*.85,1.2,7)
    local throttle=clamp((desired-speed)*.6,0,1)
    local brake=speed>desired+1.5
    if v.curParams and (v.curParams.strength<=0 or v.curParams.acceleration<=0) then
        return false,distance,"No engine or transmission power"
    end
    local steering=turn
    if tracked then
        if v.tracks.left.tracked and v.tracks.right.tracked then return false,distance,"Both tracks broken" end
        -- A fixed-steer tank turns through its native left/right wheel motors.
        -- For small course corrections both sides continue rolling forwards.
        local forward=throttle*math.max(0,math.cos(angle))
        local left,right=forward-turn,forward+turn
        local peak=math.max(math.abs(left),math.abs(right),.001)
        trackPower(v,"left",v.tracks.left.tracked and 0 or left/peak,saved)
        trackPower(v,"right",v.tracks.right.tracked and 0 or right/peak,saved)
        throttle=math.min(1,peak)
        steering=0
    elseif math.abs(angle)>1.1 then
        throttle=math.min(throttle,.55)
    end
    v.controls.drive=throttle; v.controls.steer=turn; v.controls.handbrake=brake
    DriveVehicle(v.vehiclehandle,brake and 0 or throttle,steering,brake)
    return false,distance
end
