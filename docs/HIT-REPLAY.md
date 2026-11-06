# TABS Fusion + Hit Replay 兼容安装 / Combined installation

[下载 v0.6.3](https://github.com/swaggyp7/tabs-order-tablet/releases/tag/v0.6.3)

## 选择正确的 ZIP

| 使用场景 | 下载文件 | 替换文件 |
| --- | --- | --- |
| 只使用 Fusion | TABS-Fusion-v0.6.3.zip | main.lua |
| 同时使用 Fusion 与 Hit Replay | **TABS-Fusion-Hit-Replay-v0.6.3.zip** | **main.lua 和 TABS/scripts/ballistics.lua** |

两个包是替代关系。兼容版已经合并双方桥接，不要再叠加普通 Fusion 或独立 Hit Replay 的替换文件。

## 安装兼容版

1. 订阅 [TABS Vehicle Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3148138736)、TABS Fusion、[TABS Hit Replay](https://steamcommunity.com/sharedfiles/filedetails/?id=3818578313) 及它们的必需项目。
2. 退出游戏，下载 Release 的 **TABS-Fusion-Hit-Replay-v0.6.3.zip** 并解压。
3. 找到 `SteamLibrary/steamapps/workshop/content/1167630/3148138736/`。将自己的 **main.lua 和 TABS/scripts/ballistics.lua 都备份**到其他位置。
4. 按包内 INSTALL.txt 与 checksums.json 核对版本。支持的原版基础文件哈希见下方；支持的已安装 Hit Replay 或 Fusion 文件哈希也列在 checksums.json。未知修改或其他版本不要直接覆盖。
5. 按下面对应关系同时替换两个文件，保留子目录结构：

   ```text
   ZIP 内                                      TABS 框架目录内
   TABS-bridge/main.lua                     -> main.lua
   TABS-bridge/TABS/scripts/ballistics.lua   -> TABS/scripts/ballistics.lua
   ```

6. 已订阅 Fusion 工坊版则不用复制本地工具；否则将包内 tabs-vehicle-recorder 放入 Documents/Teardown/mods。只启用一个 Fusion 工具副本。**本包不包含 Hit Replay 界面本体，需要单独订阅。**
7. 启用 TABS、Fusion 和 Hit Replay，重新进入单人地图。

从普通 Fusion 或已支持的 Hit Replay 版本升级，也应同时替换这两个文件，不要只复制 main.lua。

## 按键

| 功能 | 按键 |
| --- | --- |
| Fusion：全部执行 | **F6**（检测到回放桥接后自动切换） |
| Fusion：执行当前车 / 停止当前车 | F7 / F5 |
| Hit Replay：开关 / 重播 / 目标模式 | F8 / F9 / F10 |

Fusion 工具界面会显示实际的全部执行按键。普通版仍使用 F8。兼容桥接装着但关闭 Hit Replay 界面模组时，Fusion 仍使用 F6。Backspace 在撤销 Fusion 指令的同时，也会关闭当前回放叠层。

## 版本与恢复

支持的原版 main.lua SHA256：

```text
84dc0a005180e8c83accbe7aad6cc9548d985912b6070c4c3a6033c04bda4994
```

支持的原版 TABS/scripts/ballistics.lua SHA256：

```text
9536edc20189cadd5c0f91c1c77a5820a5062772e7223a8f242fa2a6aac599f2
```

卸载或还原时，退出游戏并恢复自己的两个文件备份。备份原来已有某个补丁时，恢复后会回到那个状态。TABS 更新可能覆盖补丁或改变兼容性，请重新核对后再安装。

## English

Download **TABS-Fusion-Hit-Replay-v0.6.3.zip** for both mods; the ordinary Fusion ZIP is for Fusion alone. Subscribe to TABS Vehicle Framework, Fusion and Hit Replay. Close the game, back up BOTH TABS files, verify compatibility against INSTALL.txt/checksums.json, then copy the contents of TABS-bridge into Workshop item 3148138736's directory. Replace both main.lua and TABS/scripts/ballistics.lua, preserving paths.

The archive includes the Fusion tool but not the Hit Replay UI. Use the Workshop Fusion tool or its local copy, not both. Enable all three mods and reload a single-player level. Fusion START ALL automatically uses **F6** with the replay bridge; Hit Replay retains F8/F9/F10. Backspace also dismisses the active replay overlay. Do not overwrite this combined pair with standalone bridge packages. Restore your own two-file backup to uninstall; recheck compatibility after TABS updates.
