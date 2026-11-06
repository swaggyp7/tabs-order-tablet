"""Read-only protocol checks against the locally installed native TABS receiver."""
from pathlib import Path
import argparse, hashlib, sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'.tools/python'))
from lupa.lua51 import LuaRuntime
p=argparse.ArgumentParser();p.add_argument('--tabs-root',type=Path,default=Path('D:/Steam/steamapps/workshop/content/1167630/3148138736'));args=p.parse_args()
source=args.tabs_root/'TABS/scripts/ballistics.lua'
before=source.read_bytes(); text=before.decode('utf-8-sig')
receiver=text[text.index('function RecieveEvent(String)'):text.index('function AssembleShell(')]
lua=LuaRuntime();lua.execute("""
function Split(s,d)
 local out={}; local i=1
 while true do local a,b=string.find(s,d,i,true); if not a then out[#out+1]=string.sub(s,i); break end
 out[#out+1]=string.sub(s,i,a-1); i=b+1 end
 return out
end
function tobool(s) return s=='true' end
registry={}; function SetString(k,v) registry[k]=v end
nativeVehicle={controls={},parts={weapons={}}}
function capture(v,w) capturedV=v; capturedW=w end
""")
lua.execute(receiver)
lua.execute("""
RecieveEvent('SetString~TypeSeperation~String~ArgTypeSeperation~probe~ArgSeperation~String~ArgTypeSeperation~ack')
assert(registry.probe=='ack')
RecieveEvent('capture~TypeSeperation~Number~ArgTypeSeperation~100~ArgSeperation~Number~ArgTypeSeperation~1')
assert(capturedV==100 and capturedW==1 and capturedV~=nativeVehicle)
RecieveEvent('capture~TypeSeperation~Table~ArgTypeSeperation~Number~TableTypeSeperator~100')
assert(type(capturedV)=='table' and capturedV[1]==100 and capturedV.controls==nil)
""")
main=(args.tabs_root/'main.lua').read_text(encoding='utf-8-sig')
shoot=main[main.index('function ShootWeapon(vInfo, Weapon, dt, shellInfoOverride)'):main.index('function CycleShells(')]
lua.execute(shoot)
lua.execute("""
local ok,err=pcall(RecieveEvent,'ShootWeapon~TypeSeperation~Number~ArgTypeSeperation~100~ArgSeperation~Number~ArgTypeSeperation~1~ArgSeperation~Number~ArgTypeSeperation~0.016')
assert(not ok and string.find(err,'number'),'native ShootWeapon does not resolve numeric handles')
""")
ai=(args.tabs_root/'TABS/scripts/tank_ai.lua').read_text(encoding='utf-8-sig')
command=ai[ai.index('function retrieve_tak_commands('):ai.index('function findTarget(')]
lua.execute("""
string.split=Split
function Vec(x,y,z) return {tonumber(x),tonumber(y),tonumber(z)} end
local tags={TABS_TAK_MOVE='10,2,30',TABS_TAK_NEW_COMMAND=''}
function HasTag(v,k) return tags[k]~=nil end
function RemoveTag(v,k) tags[k]=nil end
function GetTagValue(v,k) return tags[k] or '' end
function setAttackOnly() tags={TABS_TAK_ATTACK='100',TABS_TAK_NEW_COMMAND=''} end
""")
lua.execute(command)
lua.execute("""
local fresh,move,attack=retrieve_tak_commands({vehiclehandle=100})
assert(fresh and move[1]==10 and move[2]==2 and move[3]==30 and attack==nil)
assert(not HasTag(100,'TABS_TAK_NEW_COMMAND'))
setAttackOnly(); fresh,move,attack=retrieve_tak_commands({vehiclehandle=100})
assert(fresh and move==nil and attack==nil,'native attack branch is unimplemented')
""")
print('PASS: real ShootWeapon rejects numeric object references; real TAK reader accepts move tags but returns no attack target')
assert source.read_bytes()==before
print('PASS: unmodified native receiver executes scalar event calls; handles remain numbers, serialized tables lack live object fields')
print('Native receiver SHA256:',hashlib.sha256(before).hexdigest())
print('Not verified here: engine event delivery, native AI movement, original shooting/ammo parity')
