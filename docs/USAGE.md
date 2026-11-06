# TABS Fusion user guide

**English** | [简体中文](zh-CN/USAGE.md)

[Home](../README.md) · [Ordinary installation](INSTALL.md) · [Hit Replay installation](HIT-REPLAY.md)

## Selecting and editing

Equip Fusion in tool group 6 and left-click a TABS vehicle. Q cycles Route, Single shot and Moving fire target modes. Click drivable ground in Route mode to append a waypoint. In target modes, Z selects a weapon, X selects ammunition, and LMB selects a target.

Single shot adds one stop-and-fire instruction. A moving-fire target is pending until you click a route endpoint; selecting it alone does not add a queue entry. The tool automatically returns to Route mode after target selection. G cancels the pending target. The completed entry is labeled MOVE+FIRE, with an orange line to its target.

For example: move to A → shoot at X → drive to B while attacking Y → move to C. Instructions run in order. Undo the last instruction with Backspace; Delete clears the selected vehicle's instructions but keeps its delay.

## Moving fire

During the assigned movement segment the gun tracks the target and fires when aligned and ready. Reaching the endpoint ends that segment's firing, even if no shot was possible. Each additional segment needs its own target. Ordinary movement entries do not inherit an attack target. Dynamic targets follow the clicked point on the body; static targets use world coordinates.

## Delays and multiple vehicles

T cycles 3 / 5 / 7 / 10 seconds for the selected vehicle; default 3. The delay is applied before the first instruction when a plan is started. During countdown the vehicle brakes and does not aim or fire. Delay cannot be edited during execution. F5 cancels the selected vehicle even during countdown.

R selects another vehicle while retaining plans. Each vehicle has its own instructions, delay and execution state. F7 starts the selected plan. F8 starts all valid prepared plans with at least one instruction; with a Hit Replay bridge installed, START ALL automatically uses F6 instead. Each countdown starts from the launch request. Running or waiting plans are not restarted.

Entering the executing vehicle stops that vehicle's plan. Entering another vehicle does not. Plans last for the current level only.

## Controls and HUD

| Key | Action |
| --- | --- |
| LMB | Select vehicle / add instruction |
| Q | Cycle modes |
| Z / X | Weapon / ammunition in target modes |
| F7 | Start selected |
| F8, or F6 with replay bridge | Start all |
| F5 | Stop selected |
| T | Change delay |
| R | Select another vehicle |
| Backspace / Delete | Undo last / clear selected queue |
| G | Cancel pending target |
| H | Expand / hide controls |

The bottom-left HUD shows the selected vehicle, mode, delay, nearby queue entries and status. During execution it shows countdown or progress. H expands help. The panel scales with the screen and clips long weapon names. With Hit Replay enabled, Backspace also dismisses its current overlay.

## Limits

Routes use native wheels and game physics. Choose drivable ground and add waypoints for turns. Shots use native weapons, ammunition, reloads and rate of fire. Gun alignment, turret limits and vehicle motion affect firing and accuracy; no ballistic lead prediction. A stalled route, deleted target, broken/unavailable weapon or insufficient ammunition stops that vehicle's plan. The queue limit is 128 instructions per vehicle.
