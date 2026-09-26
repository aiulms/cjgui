#!/usr/bin/env bash
# 构建 → 安装 → 启动 → 读取 UI 树，验证仓颉声明式 UI 在模拟器上真实渲染。
#
# 前置：模拟器已启动（见 scripts/start_emulator.sh），且已 source scripts/env.sh 所需路径。
# 用法： bash scripts/build_and_run.sh

set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

echo "== 1/5 构建仓颉 HAP =="
"$DEVECO_CLI" build --build-mode debug

HAP="entry/build/default/outputs/default/entry-default-unsigned.hap"
[ -f "$HAP" ] || { echo "未找到 HAP: $HAP"; exit 1; }
echo "HAP: $HAP ($(du -h "$HAP" | cut -f1))"

echo "== 2/5 设备检查 =="
"$HDC" list targets
"$HDC" install -r "$HAP"

echo "== 3/5 启动 Ability =="
"$HDC" shell "aa force-stop $SMOKE_BUNDLE; aa start -a $SMOKE_ABILITY -b $SMOKE_BUNDLE"

sleep 5
echo "== 4/5 仓颉侧日志（期望看到 MyAbilityStage/MainAbility 生命周期）=="
"$HDC" shell "hilog -x 2>/dev/null | grep -i CangjiePoc | tail -8"

echo "== 5/5 UI 树（期望出现 Text \"Hello Cangjie\"）=="
"$DEVECO_CLI" ui layout --device "$("$HDC" list targets | head -1 | tr -d '\r')" | head -6
