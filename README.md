# input-remapper-joystick-mouse

把游戏手柄的摇杆变成**好用的鼠标** —— KDE Plasma (Wayland) + [input-remapper](https://github.com/sezanzeb/input-remapper) 2.x 的完整配置与修复脚本。

针对掌机/手柄用户在桌面上用摇杆操作鼠标的三个痛点：

| 痛点 | 方案 | 对应参数 |
|---|---|---|
| 灵敏度不合适 | 调整 analog 映射的 `gain` | `gain` |
| 死区太大 / 太小 | 调整 deadzone | `deadzone` |
| 快速甩杆时突然加速发飘 | 把 KWin 对虚拟鼠标的自适应加速改为**线性(flat)** | `ir-accel-flat` 脚本 |

适用于：Steam Deck / GPD 系列 / ROG Ally 等掌机，以及任何"手柄当鼠标"的桌面场景。
要求：**KDE Plasma 6 (KWin 6) + Wayland**、input-remapper **2.x**（Debian/Ubuntu: `apt install input-remapper`）。

---

## 安装

```bash
# 1. 克隆
git clone https://github.com/Kiriusss/input-remapper-joystick-mouse.git
cd input-remapper-joystick-mouse

# 2. 安装（拷贝 preset + 修复脚本 + autostart）
./install.sh

# 3. 立即生效（下次开机由 autostart 自动执行）
input-remapper-control --command start \
  --device "Microsoft X-Box 360 pad" \
  --preset desktop
~/.local/bin/ir-accel-flat
```

> 手柄名称不一定叫 "Microsoft X-Box 360 pad"，用 `input-remapper-control --list-devices` 查看你的设备名，改 `install.sh` 里的 `DEVICE_NAME` 和 `PRESET` 即可。

---

## 工作原理

1. **input-remapper 2.x** 以 root 系统服务运行，把摇杆（ABS 轴）映射成虚拟鼠标的 REL 事件。
   - 生效的配置目录是 `~/.config/input-remapper-2/`（**不是**旧版 `~/.config/input-remapper/`，那个是残留，改了没用）。
   - 左摇杆 → 鼠标：两条 `mapping_type: "analog"` 的映射（`ABS_X → REL_X`、`ABS_Y → REL_Y`）。
2. **KWin 对虚拟鼠标默认开启"自适应指针加速"**：推得越快，放大越猛 —— 这就是"加速度太快的发飘感"。
   `ir-accel-flat` 通过 KWin 的 DBus 接口（`org.kde.KWin.InputDevice`）把该设备改为 flat（线性）：
   ```bash
   busctl --user set-property org.kde.KWin \
     /org/kde/KWin/InputDevice/<eventN> \
     org.kde.KWin.InputDevice pointerAccelerationProfileFlat b 1
   busctl --user set-property org.kde.KWin \
     /org/kde/KWin/InputDevice/<eventN> \
     org.kde.KWin.InputDevice pointerAcceleration d 0
   ```
3. **KWin 的设备设置不写盘**，注入进程重启/开机后虚拟鼠标会回到自适应加速 —— 所以 `install.sh` 把 `ir-accel-flat` 挂进了 `~/.config/autostart/input-remapper.desktop`，开机注入成功后自动重打。

---

## 调参指南

配置文件：`~/.config/input-remapper-2/presets/<设备名>/<preset>.json`
**改完文件不会热加载**，必须重跑一次 `input-remapper-control --command start ...`（或在 GUI 里应用）。

```json
{
    "input_combination": [{"type": 3, "code": 0}],
    "target_uinput": "mouse",
    "output_type": 2,
    "output_code": 0,
    "mapping_type": "analog",
    "gain": 0.18,       // 速度：0~1 浮点，越大越快
    "deadzone": 0.03,   // 死区：0~1，吃掉的轴行程比例（默认 0.1！）
    "expo": 0.4         // 曲线：0 线性；>0 小行程压软、大行程保持
}
```

### 参数说明

- **`gain`** — 输出速度乘数。整体快慢就调它。
- **`deadzone`** — 死区，默认 `0.1`（吃掉最内圈 10% 行程，会感觉"推了没反应"）。
  `0` = 完全无死区。**不建议设为 0**：摇杆中心附近天然有 ±几单位的抖动，deadzone=0 会把每次抖动都放大成鼠标事件，导致光标持续漂移/某轴偏快（表现为"注入后变快"）。`0.03` 足以吃掉抖动且几乎无感。
- **`expo`** — 响应曲线（`f(x) = (1-k)·x + k·x³`，k∈[0,1]）：
  - `0`：线性，小推多少走多少
  - `0.4`（推荐）：小行程压软 → 微调精度高；推满时仍 100% 速度
  - 更大值更"软"，更小值更"硬"

### 常见组合

| 场景 | gain | deadzone | expo |
|---|---|---|---|
| 精细操作（本仓库默认） | 0.18 | 0.03 | 0.4 |
| 追求速度 | 0.3~0.5 | 0.03 | 0.2 |
| 摇杆漂移严重 | 0.2 | 0.05 | 0.4 |

---

## 文件结构

```
├── install.sh                    # 一键安装
├── ir-accel-flat                 # KWin 线性加速修复脚本
├── presets/
│   └── Microsoft X-Box 360 pad/
│       └── desktop.json          # 调好的 preset（改设备名即可用）
└── autostart/
    └── input-remapper.desktop    # 开机自启模板（注入 + 打 flat）
```

## 踩坑记录

1. **配置目录认错**：input-remapper 2.x 用 `~/.config/input-remapper-2/`；旧版 `~/.config/input-remapper/` 是残留，改它无效（`--config-dir` 的 help 文案还是旧路径，别信）。
2. **服务重启后映射不恢复**：`input-remapper-daemon.service` 是系统级 root 服务，重启后不会自动注入 preset，要重跑 `input-remapper-control --command start ...`。
3. **KWin 加速不持久**：DBus 设置是运行时状态，重启后丢失，必须靠 autostart 钩子重打。
4. **gain 的历史渊源**：v1.5 配置里的 `pointer_speed: 80` 迁移到 v2 就是 `gain: 0.8`（80/100）。
5. **"注入后就变快/某轴偏快"其实是死区**：deadzone=0 时，摇杆中心 ±几单位的硬件抖动会被手柄驱动 ~236Hz 轮询持续放大成鼠标移动流。排查方法：`sudo python3 -c "import evdev,time; d=evdev.InputDevice('/dev/input/event21'); [print(e) for _ in range(3) for e in d.read()]"`（注入器 grab 了物理设备，读不到源，但虚拟鼠标事件可见）。修复：deadzone 0.03（见上）。

## License

MIT
