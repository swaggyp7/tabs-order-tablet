# TABS Fusion

Plan vehicle action sequences with a handheld tool: drive, fire, fire on the move, and coordinate multiple vehicles with independent launch delays.

- Native wheel movement and TABS weapons, with weapon/ammunition selection.
- World targets or tracked points on moving bodies.
- Independent vehicle queues; F8 starts all prepared plans together.
- Per-vehicle 3 / 5 / 7 / 10 second launch delay.
- Compact HUD with H to expand controls.

## Requirements and installation

**No Python required for the release ZIP.** Requires single-player Teardown, TABS Vehicle Framework (Workshop 3148138736) and its required items.

Download **TABS-Fusion-v0.6.2.zip** from the [release Assets](https://github.com/swaggyp7/tabs-order-tablet/releases/tag/v0.6.2). Follow the archive's INSTALL.txt or the [中英文安装教程](../docs/INSTALL.md). Back up your original TABS main.lua and verify the supported SHA256 before replacing it with TABS-bridge/main.lua from the ZIP.

Use either the Workshop tool or the ZIP's local tool folder, not both. Enable TABS and Fusion, reload the level, and equip the tool in group 6. Restore your own original main.lua backup to uninstall. This ZIP is not a combined Hit Replay patch; other replacements of the same file conflict.

## Controls

LMB selects a TABS vehicle, then adds orders. Q cycles Route / Single shot / Moving fire target. For moving fire, click the target, then the route endpoint. Z/X choose weapon/ammo. G cancels a pending moving-fire target. F7 starts the selected plan; F8 starts all prepared plans. T cycles launch delay (default 3 seconds). F5 stops the selected vehicle even during countdown. R selects another vehicle while retaining plans. Backspace undoes an order, Delete clears orders, H expands controls.

Moving fire ends at its waypoint. Each segment needs its own target. Live scripts are not restarted by F8. Entering the executing vehicle stops its plan; entering another vehicle does not. Plans last for the current level only. Shots consume native ammunition; turret limits, vehicle motion and terrain affect firing. No ballistic lead prediction. A blocked route, lost target or unavailable weapon/ammo stops that vehicle's plan.

## Release verification

Installer preservation/rollback and simulated route, moving-fire, launch-delay and fleet-start checks pass. Actual HUD rendering and physical driving accuracy must be checked in Teardown before publication. The preview is the supplied in-game screenshot, unchanged.

## Manual replacement ZIP (v0.6.2)

The release asset includes both the mod folder and `TABS-bridge/main.lua`. Follow the root `INSTALL.txt`; this route needs no Python. Use only one installation method. Compare the original TABS main.lua SHA256 before replacing it and preserve your own backup. The bundled main.lua excludes unrelated local patches.

## Developer tools

The optional Python patch installer is an alternative development installation method. It is not required for players using the manual ZIP. Do not run it on top of the manual replacement. Run `python tools/deploy_vehicle_recorder.py --help` for development options. Its `--uninstall` option applies to installations it manages; manual ZIP users restore their own backup.

The build script requires Python and a verified original TABS main.lua. Simulated checks additionally require Lupa; they do not replace in-game validation.
