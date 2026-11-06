# Initial no-patch investigation

Branch: codex/no-patch-control. Stable implementation remains unchanged.

## Reproduced against local native functions

`tools/probe_native_tabs.py` reads the installed TABS sources, extracts the original receiver, ShootWeapon and retrieve_tak_commands functions, and runs them with minimal host stubs under Lua 5.1 (Lupa). No TABS source is written or copied into the repository. Run with `pip install lupa`, then `python tools/probe_native_tabs.py --tabs-root YOUR_TABS_FOLDER`.

- Event listener: `Tabs Vehicle Framework Listener`, registered by main.lua. The original receiver dispatches `_G[FunctionName](unpack(FunctionArguments))`.
- SetString events work in the receiver-level test. Engine delivery is not tested.
- Numeric vehicle/weapon handles are passed as numbers, not looked up in TABSVehicles. Passing them to the original ShootWeapon fails when it dereferences the weapon object.
- Serialized tables are positional data, not references to the live vehicle/weapon objects and their methods.
- Native TAK command reader accepts `TABS_TAK_MOVE` plus `TABS_TAK_NEW_COMMAND`; the attack branch is empty and returns no attack target in the test.

## What remains unproven

The independent probe mod provides F9 acknowledgement and F6 native-AI waypoint commands for an already faction-assigned vehicle. Engine event delivery, physical movement, precise stopping and interactions with combat AI require in-game testing against unpatched TABS. Native AI retains weapon/ammo and target decisions. This is not equivalent to the stable scripted shot system.

There is currently no demonstrated no-patch replacement for explicit target, selected weapon/ammo, shot timing, ammunition accounting and reload integration. An event listener alone does not establish that these can be exposed. Other existing callable functions or registry/tag controls may still be investigated; the present results do not prove that every possible approach is impossible.

No automatic bridge uninstall, Workshop edits, stable tablet replacement or AI-faction changes were performed. The probe is separate and has no installer dependency on the bridge. Follow its README for a clean game test.
