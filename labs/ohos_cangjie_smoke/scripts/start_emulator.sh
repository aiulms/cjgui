#!/usr/bin/env bash
# 启动鸿蒙模拟器。
#
# 注意：`devecocli emulator start` 走的是 deveco-cli 自己的镜像注册表，
# 会报 "The system image file ... cannot be found"（GUI 装的镜像它不认）。
# 直接用 DevEco 自带 Emulator 二进制的 -start 子命令可绕开。

set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

exec "$EMULATOR_BIN" -start "$EMULATOR_NAME" \
  -instancePath "$EMULATOR_INSTANCE_PATH" \
  -imageRoot "$EMULATOR_IMAGE_ROOT"
