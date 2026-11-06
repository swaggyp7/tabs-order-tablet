local TOOL="tvr_no_patch_probe"
local P="level.tvr_no_patch_probe."
local vehicle=0
local point=nil
local sent=nil
local notice="F9 checks TABS events; LMB selects a vehicle, then a waypoint"
local function valid(v) return v~=0 and IsHandleValid(v) end
local function ping()
    local token=tostring(GetTime())
    SetString(P.."expected",token); ClearKey(P.."ack")
    TriggerEvent("Tabs Vehicle Framework Listener",
        "SetString~TypeSeperation~String~ArgTypeSeperation~"..P.."ack~ArgSeperation~String~ArgTypeSeperation~"..token)
    sent=GetTime(); notice="Waiting for TABS event acknowledgement"
end
function init()
    RegisterTool(TOOL,"TABS No-Patch Probe","",6)
    SetBool("game.tool."..TOOL..".enabled",true)
end
function tick()
    if sent then
        if GetString(P.."ack")==GetString(P.."expected") then notice="TABS event acknowledged"; sent=nil
        elseif GetTime()-sent>2 then notice="No event response from TABS"; sent=nil end
    end
    if GetString("game.player.tool")~=TOOL or GetPlayerVehicle()~=0 then return end
    if InputPressed("f9") then ping() end
    if InputPressed("r") then vehicle=0; point=nil end
    if InputPressed("lmb") then
        local t=GetCameraTransform(); local dir=TransformToParentVec(t,Vec(0,0,-1))
        if valid(vehicle) then QueryRejectVehicle(vehicle) end
        local hit,dist,normal,shape=QueryRaycast(t.pos,dir,1000)
        if hit then
            if not valid(vehicle) then
                local v=GetBodyVehicle(GetShapeBody(shape))
                if valid(v) and HasTag(v,"TABS") then vehicle=v; notice="Vehicle selected; click ground for a waypoint"
                else notice="Select a TABS hull" end
            elseif normal[2]>.55 then point=VecAdd(t.pos,VecScale(dir,dist)); notice="F6 sends native AI waypoint" end
        end
    end
    if InputPressed("f6") and valid(vehicle) and point then
        if not HasTag(vehicle,"tabs_ai") then
            notice="Assign this vehicle an AI faction with native TABS TAK first"
        else
            SetTag(vehicle,"TABS_TAK_MOVE",table.concat(point,","))
            SetTag(vehicle,"TABS_TAK_NEW_COMMAND")
            notice="Waypoint sent; native AI owns driving and automatic weapon decisions"
        end
    end
    if point and valid(vehicle) then DrawLine(GetVehicleTransform(vehicle).pos,point,.2,1,.5,1) end
end
function draw()
    if GetString("game.player.tool")~=TOOL then return end
    UiPush(); UiTranslate(25,UiHeight()-120); UiFont("regular.ttf",18); UiAlign("left top")
    UiText("NO-PATCH PROBE / not full feature parity"); UiTranslate(0,25)
    UiText("LMB select / waypoint   F6 send move   F9 ping   R select another"); UiTranslate(0,25)
    UiText(notice); UiPop()
end
