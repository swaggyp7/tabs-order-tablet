# TABS Fusion

Plan vehicle action sequences with a handheld tool: drive, fire, fire on the move, and coordinate multiple vehicles with independent launch delays.

- Native wheel movement and TABS weapons, with weapon/ammunition selection.
- World targets or tracked points on moving bodies.
- Independent vehicle queues; F8 starts all prepared plans together.
- Per-vehicle 3 / 5 / 7 / 10 second launch delay.
- Compact HUD with H to expand controls.

## Requirements and installation

Single-player Teardown with TABS Vehicle Framework (Workshop 3148138736). **Enabling this tool alone does not install the bridge.** This distribution includes a Python installer that adds a bounded bridge to your local TABS main.lua and preserves a verified backup. The manual release ZIP includes a version-specific replacement main.lua; see MANUAL-INSTALL.txt in the archive. The source installer remains available separately.

1. Extract the full archive. Install Python 3 if needed.
2. Run `python tools/deploy_vehicle_recorder.py` from the extracted folder. Default TABS path: `D:/Steam/steamapps/workshop/content/1167630/3148138736`. Use `--target "YOUR_TABS_FOLDER"` to change it; `--help` lists other options.
3. Enable TABS Fusion and TABS; reload the level. Equip the tool in group 6.

Keep the installer backup folder. Before TABS is updated or patched with another installer, restore using `python tools/deploy_vehicle_recorder.py --uninstall`, then update and reinstall. If Workshop changes the source, this installer refuses to overwrite the changed file; keep the backup and resolve the update before reinstalling.

## Controls

LMB selects a TABS vehicle, then adds orders. Q cycles Route / Single shot / Moving fire target. For moving fire, click the target, then the route endpoint. Z/X choose weapon/ammo. G cancels a pending moving-fire target. F7 starts the selected plan; F8 starts all prepared plans. T cycles launch delay (default 3 seconds). F5 stops the selected vehicle even during countdown. R selects another vehicle while retaining plans. Backspace undoes an order, Delete clears orders, H expands controls.

Moving fire ends at its waypoint. Each segment needs its own target. Live scripts are not restarted by F8. Entering the executing vehicle stops its plan; entering another vehicle does not. Plans last for the current level only. Shots consume native ammunition; turret limits, vehicle motion and terrain affect firing. No ballistic lead prediction. A blocked route, lost target or unavailable weapon/ammo stops that vehicle's plan.

## Release verification

Installer preservation/rollback and simulated route, moving-fire, launch-delay and fleet-start checks pass. Actual HUD rendering and physical driving accuracy must be checked in Teardown before publication. The preview is the supplied in-game screenshot, unchanged.

## Manual replacement ZIP (v0.6.2)

The release asset includes both the mod folder and `TABS-bridge/main.lua`. Follow the root `INSTALL.txt`; this route needs no Python. Use only one installation method. Compare the original TABS main.lua SHA256 before replacing it and preserve your own backup. The bundled main.lua excludes unrelated local patches.
