# TABS 载具指令板 v5

启用 TABS Order Tablet 和 TABS Vehicle Framework，重载单人地图，从工具第 6 组拿出工具。

- 左键选择 TABS 载具。
- Q 依次切换路径、停车射击、移动射击目标模式。
- 路径模式：左键地面，追加移动终点。
- 停车射击模式：Z 选武器、X 选弹种，左键目标，追加一次停车射击。
- 移动射击目标模式：Z/X 选武器/弹种，左键选目标，自动返回路径模式；再左键地面，追加一条“移动到该点，同时持续攻击刚才目标”的指令。目标只附带在这一条移动指令上。选目标后可按 G 取消，再添加普通移动点。
- F7 从首条执行；F5 停止当前选择车辆。Backspace 撤销末条，Delete 清空当前车辆计划。
- R 重新选车并保留当前计划。每辆车的计划和运行状态独立；上其他车辆不会中止，亲自驾驶执行中的车辆会中止该车计划。

例如：普通移动到 A → 停车射击甲 → 移动到 B 并持续攻击乙 → 普通移动到 C。

移动射击的目标选择本身不占队列条目，必须再设置路径终点；队列显示 MOVE+FIRE，橙线连接路径终点和攻击目标。到达终点立即结束该段射击，即使未开出一炮也继续下一条。需要连续多段攻击时，为各段分别选择目标。

车辆通过原版车轮行驶，射击消耗实际弹药，遵循原武器装填和射速。动态目标跟随点击部位，静态目标保存世界坐标。仅当炮口对准目标时开火，行驶颠簸、炮塔转速和射界会影响能否开火及命中。当前不做弹道提前量预测。车辆卡住、目标消失、武器损坏或弹药不足时停止该车计划。

## 安装

从项目根目录执行 `python tools/deploy_vehicle_recorder.py`。默认目标为本机 D 盘 Steam 下的 TABS Workshop 安装；其他位置用 `--help` 查看路径参数。卸载桥接：`python tools/deploy_vehicle_recorder.py --uninstall`。安装器核验原文件和备份，不包含游戏或 Workshop 原文件。安装后重载地图，确认工具标题为 v5。

## 检查

需要 Python 和 Lupa（`pip install lupa`）。运行 `python tests/test_vehicle_recorder.py`、`python tests/test_vehicle_recorder_weapons.py`、`python tests/test_vehicle_recorder_install.py`。这些是模拟回调检查，不能替代游戏内实测。
