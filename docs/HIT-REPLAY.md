# TABS Fusion + Hit Replay installation

**English** | [简体中文](zh-CN/HIT-REPLAY.md)

[Download v0.6.3](https://github.com/swaggyp7/tabs-order-tablet/releases/tag/v0.6.3) · [Project home](../README.md)

## Choose the correct ZIP

| Setup | ZIP | TABS files replaced |
| --- | --- | --- |
| Fusion only | TABS-Fusion-v0.6.3.zip | main.lua |
| Fusion + Hit Replay | **TABS-Fusion-Hit-Replay-v0.6.3.zip** | **main.lua and TABS/scripts/ballistics.lua** |

Choose one package. The combined pair already includes both bridges; do not overwrite it with either standalone bridge.

## Install the combined version

1. Subscribe to [TABS Vehicle Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3148138736), TABS Fusion, [TABS Hit Replay](https://steamcommunity.com/sharedfiles/filedetails/?id=3818578313), and their required items.
2. Close Teardown. Download **TABS-Fusion-Hit-Replay-v0.6.3.zip** from the release Assets and extract it.
3. Locate `SteamLibrary/steamapps/workshop/content/1167630/3148138736/`. Back up **both main.lua and TABS/scripts/ballistics.lua** outside the framework directory.
4. Verify compatibility against INSTALL.txt and checksums.json. Native file hashes are below. Supported already-patched Hit Replay and Fusion file hashes are also recorded in checksums.json. Do not overwrite unknown modifications or a different TABS version.
5. Copy the files using these exact destinations, preserving subdirectories:

   | ZIP file | Destination within the TABS framework folder |
   | --- | --- |
   | TABS-bridge/main.lua | main.lua |
   | TABS-bridge/TABS/scripts/ballistics.lua | TABS/scripts/ballistics.lua |

6. Use either the Workshop Fusion tool or the included local `tabs-vehicle-recorder` folder in `Documents/Teardown/mods/`, not both. **The Hit Replay UI is not included in this ZIP; subscribe to it separately.**
7. Enable TABS, Fusion and Hit Replay, then reload a single-player level.

When upgrading from ordinary Fusion or a supported Hit Replay installation, replace **both** files, not only main.lua.

## Controls

| Function | Key |
| --- | --- |
| Fusion: start all prepared plans | **F6**, automatically selected when the replay bridge is detected |
| Fusion: start selected / stop selected | F7 / F5 |
| Hit Replay: toggle / replay / target mode | F8 / F9 / F10 |

Fusion's HUD shows the active key. The ordinary bridge uses F8. With the combined bridge installed, Fusion still uses F6 even if the Hit Replay UI mod is disabled. Backspace also dismisses the active replay overlay when undoing a Fusion instruction.

## Supported original files

main.lua SHA256:

```text
84dc0a005180e8c83accbe7aad6cc9548d985912b6070c4c3a6033c04bda4994
```

TABS/scripts/ballistics.lua SHA256:

```text
9536edc20189cadd5c0f91c1c77a5820a5062772e7223a8f242fa2a6aac599f2
```

Use PowerShell `Get-FileHash -Algorithm SHA256 -LiteralPath "FILE_PATH"` to check each file.

## Updates and restoring your installation

Close the game and restore **both of your own backups** to return to the previous state. If those backups already contained a patch, restoring them returns to that patched state. TABS updates can overwrite the bridge or change compatibility; verify the version before reinstalling. See the [user guide](USAGE.md) for queue and moving-fire behavior.
