"""Build the manual bridge-replacement + mod release from a verified native main.lua."""
from pathlib import Path
import argparse,hashlib,json,zipfile
from deploy_vehicle_recorder import patched,BRIDGE_FILES,ADDON_FILES
ROOT=Path(__file__).resolve().parents[1]
BASE_SHA="84dc0a005180e8c83accbe7aad6cc9548d985912b6070c4c3a6033c04bda4994"
p=argparse.ArgumentParser();p.add_argument('--base-main',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args()
base=a.base_main.read_bytes()
if hashlib.sha256(base).hexdigest()!=BASE_SHA: p.error('Native TABS main.lua does not match the supported baseline')
src=ROOT/'tabs-vehicle-recorder'
bridge=patched(base,[(src/n).read_bytes() for n in BRIDGE_FILES])
assert b'WTRWire=' not in bridge and bridge.count(b'-- BEGIN TABS VEHICLE RECORDER v1')==1
files={'TABS-bridge/main.lua':bridge,'INSTALL.txt':(ROOT/'MANUAL-INSTALL.txt').read_bytes()}
for n in (*ADDON_FILES,'README.md','RELEASE.md'): files['tabs-vehicle-recorder/'+n]=(src/n).read_bytes()
manifest={'release':'v0.6.2','tabs_workshop_id':'3148138736','supported_native_main_sha256':BASE_SHA,'sha256':{n:hashlib.sha256(b).hexdigest() for n,b in files.items()}}
files['checksums.json']=(json.dumps(manifest,indent=2)+'\n').encode()
a.output.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(a.output,'w',zipfile.ZIP_DEFLATED) as z:
 for n,b in files.items(): z.writestr(n,b)
with zipfile.ZipFile(a.output) as z:
 assert z.testzip() is None
 for n,b in files.items(): assert z.read(n)==b
print(a.output.resolve())
