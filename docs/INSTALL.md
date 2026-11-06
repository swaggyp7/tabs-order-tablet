# TABS Fusion 安装教程 / Installation

[GitHub 项目](https://github.com/swaggyp7/tabs-order-tablet) · [下载 v0.6.2](https://github.com/swaggyp7/tabs-order-tablet/releases/tag/v0.6.2)

## 中文

需要单人游戏、[TABS Vehicle Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3148138736) 及其必需项目。订阅指令板后，还需要安装桥接替换文件。

1. **退出 Teardown**。打开上述 Release，从 **Assets** 下载 **TABS-Fusion-v0.6.2.zip**，不要下载 Source code。
2. 解压后确认有 `TABS-bridge/main.lua`、`tabs-vehicle-recorder/`、`INSTALL.txt` 和 `checksums.json`。
3. 找到安装 TABS 的 Steam 库，进入 `steamapps/workshop/content/1167630/3148138736/`。这个目录应已存在 `main.lua`，不是游戏 data 目录，也不是指令板模组目录。
4. 备份你自己的原始 `main.lua`。核对原文件 SHA256 是否匹配下方数值；不匹配表示不同版本或已有补丁，勿直接覆盖。
5. 将 ZIP 中的 `TABS-bridge/main.lua` 复制到上述 TABS 目录，替换同名文件。无需替换 `ballistics.lua`。
6. 工具本体二选一：使用工坊订阅版本；或将 ZIP 中的 `tabs-vehicle-recorder` 整个文件夹放入 `Documents/Teardown/mods/`。只启用一个版本。
7. 启动游戏，启用 TABS 和 TABS Fusion，重新进入单人地图，在工具第 6 组找到工具。按 H 展开完整按键。

适配的原版 main.lua SHA256：

```text
84dc0a005180e8c83accbe7aad6cc9548d985912b6070c4c3a6033c04bda4994
```

可使用 PowerShell 的 `Get-FileHash -Algorithm SHA256 -LiteralPath "你的TABS目录/main.lua"` 检查。

### 第一次使用

左键选车，路径模式左键设置终点。Q 切换目标模式，Z/X 选武器和弹种，左键添加射击。移动射击模式下先选目标，再点地面设置这一段的终点。T 设置该车启动延迟，F7 启动该车，F8 启动所有已编排车辆，F5 停止当前车。

### 冲突、更新与卸载

- 本 ZIP 不包含 Hit Replay 合并补丁。两者都替换 main.lua，直接相互覆盖会丢失其中一套功能。已有其他补丁时不要叠加覆盖。
- TABS 更新可能覆盖补丁，需重新确认版本兼容性。
- 卸载时退出游戏，恢复**你自己安装前备份的** main.lua，再禁用指令板。
- 如果提示未连接，检查是否替换了正确 Steam 库中 TABS 根目录的 main.lua，确认 TABS 已启用，并重新载入地图。

## English

Requires single-player Teardown, TABS Vehicle Framework and its required items. A tool subscription alone does not complete setup.

1. Close Teardown. Download **TABS-Fusion-v0.6.2.zip** from the release **Assets**, not Source code.
2. Extract it. Locate `SteamLibrary/steamapps/workshop/content/1167630/3148138736/`.
3. Back up your original main.lua and compare its SHA256 with the supported value above. A different hash means another version or existing modifications; do not overwrite it with this replacement.
4. Copy the ZIP's `TABS-bridge/main.lua` over main.lua in that TABS folder. No ballistics.lua replacement is needed.
5. Use either the Workshop tool or the local ZIP copy. For the local copy, place the entire tabs-vehicle-recorder folder in Documents/Teardown/mods. Enable only one copy.
6. Enable TABS and TABS Fusion, reload a single-player level, and equip the tool in group 6. Press H for controls.

This release does not combine the Hit Replay bridge. Patches replacing the same main.lua overwrite each other. TABS updates may overwrite the bridge or change compatibility. Restore YOUR original backup to uninstall, then disable the tool.
