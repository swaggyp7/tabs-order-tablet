# No-patch probe

Experimental, separate mod. It does not edit or include TABS source and does not replace the stable tablet. Copy this directory to Documents/Teardown/mods and enable it with TABS; select TABS No-Patch Probe in tool group 6. It deliberately has no handheld model.

For a clean in-game test, first use the stable installer's `--uninstall` operation to restore its verified TABS baseline, disable the stable tablet and reload the map. Existing unrelated patches in that baseline may remain; verify against a clean Workshop version for a definitive compatibility test. Reinstall the stable bridge afterwards with the normal installer command if desired. This experiment does not run either operation automatically.

F9 asks the existing native listener to acknowledge by writing a unique registry token. A response proves event reachability, not vehicle or weapon access. LMB selects a TABS hull, then a ground waypoint. F6 writes the native TAK MOVE and NEW_COMMAND tags. This requires an already AI-faction-assigned vehicle; assign its faction using TABS TAK. The probe does not activate AI, change factions, force wheel movement, aim guns or fire. Native AI can choose and engage enemies on its own. These are experiments, not scripted shots.

No stop/restore is promised for AI state: clearing a command tag does not cancel a path already accepted into TABS AI. Reload the level after testing. No full queue or ammunition control is implemented in this probe.
