#!/bin/bash
# 安装 input-remapper-joystick-mouse 配置:
#   1. 拷贝调好的 preset 到 ~/.config/input-remapper-2/presets/
#   2. 拷贝 ir-accel-flat 到 ~/.local/bin/
#   3. 生成 autostart(开机自动注入 + 打 flat 加速)
set -e

# 按需修改: 你的手柄设备名(input-remapper-control --list-devices 查看)
DEVICE_NAME="Microsoft X-Box 360 pad"
PRESET="desktop"

DEST_PRESET="$HOME/.config/input-remapper-2/presets/$DEVICE_NAME"
DEST_BIN="$HOME/.local/bin"
DEST_AUTOSTART="$HOME/.config/autostart"

mkdir -p "$DEST_PRESET" "$DEST_BIN" "$DEST_AUTOSTART"
cp "presets/$DEVICE_NAME/$PRESET.json" "$DEST_PRESET/$PRESET.json"
cp ir-accel-flat "$DEST_BIN/ir-accel-flat"
chmod +x "$DEST_BIN/ir-accel-flat"
sed "s|__HOME__|$HOME|g" autostart/input-remapper.desktop > "$DEST_AUTOSTART/input-remapper.desktop"

echo "已安装完成。"
echo "立即生效:"
echo "  input-remapper-control --command start --device \"$DEVICE_NAME\" --preset $PRESET"
echo "  $DEST_BIN/ir-accel-flat"
echo "(下次开机 autostart 会自动执行这两步)"
