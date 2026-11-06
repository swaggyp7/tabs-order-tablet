"""Build the manual bridge-replacement + mod release from a verified native main.lua."""
from pathlib import Path
import argparse,hashlib,json,zipfile
from deploy_vehicle_recorder import patched,BRIDGE_FILES,ADDON_FILES
ROOT=Path(__file__).resolve().parents[1]
BASE_SHA="84dc0a005180e8c83accbe7aad6cc9548d985912b6070c4c3a6033c04bda4994"
p=argparse.ArgumentParser()
p.add_argument('--base-main',required=True,type=Path)
p.add_argument('--output',required=True,type=Path)
p.add_argument('--hit-replay-main',type=Path)
p.add_argument('--hit-replay-ballistics',type=Path)
a=p.parse_args()
base=a.base_main.read_bytes()
if hashlib.sha256(base).hexdigest()!=BASE_SHA: p.error('Native TABS main.lua does not match the supported baseline')
combined=a.hit_replay_main is not None or a.hit_replay_ballistics is not None
if combined and not (a.hit_replay_main and a.hit_replay_ballistics):
 p.error('Both verified Hit Replay inputs are required')
src=ROOT/'tabs-vehicle-recorder'
files={}
if combined:
 replay_main=a.hit_replay_main.read_bytes()
 ballistics=a.hit_replay_ballistics.read_bytes()
 if hashlib.sha256(replay_main).hexdigest()!='e4f97ef2a6389f5e60e2ec46d31e0f97bfc8ac3bd1d0f63459b2d016e4654fae':
  p.error('Unsupported Hit Replay main.lua')
 if hashlib.sha256(ballistics).hexdigest()!='f1cdb6822c68c052662e79844af4f7975d8a13e08dbb3a508884ae7e287c07a8':
  p.error('Unsupported Hit Replay ballistics.lua')
 assert replay_main.startswith(base)
 bridge=patched(replay_main,[(src/n).read_bytes() for n in BRIDGE_FILES])
 assert bridge.count(b'WTRWire={}')==1
 assert bridge.count(b'function WTRImpactBegin(')==1
 files['TABS-bridge/TABS/scripts/ballistics.lua']=ballistics
 instructions=ROOT/'COMBINED-INSTALL.txt'
else:
 bridge=patched(base,[(src/n).read_bytes() for n in BRIDGE_FILES])
 assert b'WTRWire=' not in bridge
 instructions=ROOT/'MANUAL-INSTALL.txt'
assert bridge.count(b'-- BEGIN TABS VEHICLE RECORDER v1')==1
files.update({'TABS-bridge/main.lua':bridge,'INSTALL.txt':instructions.read_bytes()})
for n in (*ADDON_FILES,'README.md','RELEASE.md'): files['tabs-vehicle-recorder/'+n]=(src/n).read_bytes()
manifest={'release':'v0.6.3','tabs_workshop_id':'3148138736','supported_native_main_sha256':BASE_SHA,'sha256':{n:hashlib.sha256(b).hexdigest() for n,b in files.items()}}
manifest['variant']='fusion-hit-replay' if combined else 'fusion-only'
if combined:
 manifest['supported_native_ballistics_sha256']='9536edc20189cadd5c0f91c1c77a5820a5062772e7223a8f242fa2a6aac599f2'
 manifest['supported_fusion_main_sha256']=hashlib.sha256(patched(base,[(src/n).read_bytes() for n in BRIDGE_FILES])).hexdigest()
 manifest['supported_hit_replay_main_sha256']=hashlib.sha256(replay_main).hexdigest()
 manifest['supported_hit_replay_ballistics_sha256']=hashlib.sha256(ballistics).hexdigest()
files['checksums.json']=(json.dumps(manifest,indent=2)+'\n').encode()
a.output.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(a.output,'w',zipfile.ZIP_DEFLATED) as z:
 for n,b in files.items(): z.writestr(n,b)
with zipfile.ZipFile(a.output) as z:
 assert z.testzip() is None
 for n,b in files.items(): assert z.read(n)==b
print(a.output.resolve())
