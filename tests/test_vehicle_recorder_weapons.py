"""Check the planner fires only through TABS with scoped ownership on failure."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
lua.execute('TVRPlan={}; saved=71; function GetInt() return saved end; function SetInt(k,v) saved=v end; function HasKey() return true end; function PlayShootSound() end')
lua.execute((ROOT/'tabs-vehicle-recorder/weapons.lua').read_text(encoding='utf-8-sig'))
lua.execute("function ShootWeapon(v,w,dt) assert(saved==v.vehiclehandle); error('injected') end; assert(not pcall(TVRPlan.fire,{vehiclehandle=100},{},.016)); assert(saved==71)")
print('PASS: native firing ownership restored on failure')

