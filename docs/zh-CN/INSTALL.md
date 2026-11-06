# TABS Fusion 安装教程

[English](../INSTALL.md) | **简体中文**

[下载 v0.6.3](https://github.com/swaggyp7/tabs-order-tablet/releases/tag/v0.6.3) · [中文首页](../../README.zh-CN.md)

同时使用 Hit Replay？请按[兼容版教程](HIT-REPLAY.md)安装。以下步骤用于普通版。

需要单人游戏、[TABS Vehicle Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3148138736) 及其必需项目。订阅指令板后，还需要安装桥接替换文件。

1. **退出 Teardown**。打开上述 Release，从 **Assets** 下载 **TABS-Fusion-v0.6.3.zip**，不要下载 Source code。
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

- 普通 ZIP 不包含 Hit Replay 合并补丁；同时使用请改用[兼容 ZIP](HIT-REPLAY.md)，不要叠加独立替换包。
- TABS 更新可能覆盖补丁，需重新确认版本兼容性。
- 卸载时退出游戏，恢复**你自己安装前备份的** main.lua，再禁用指令板。
- 如果提示未连接，检查是否替换了正确 Steam 库中 TABS 根目录的 main.lua，确认 TABS 已启用，并重新载入地图。
