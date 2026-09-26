#!/usr/bin/env bash
# 启动鸿蒙模拟器（复用 labs/ohos_cangjie_smoke 已验证的启动方式）。
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

connected() {
  "$HDC" list targets 2>/dev/null | tr -d '\r' | grep -vE "^(\[Empty\]|Empty)$" | grep -q .
}

if connected; then
  echo "模拟器已连接：$("$HDC" list targets)"
  exit 0
fi

"$EMULATOR_BIN" -start "$EMULATOR_NAME" \
  -instancePath "$EMULATOR_INSTANCE_PATH" \
  -imageRoot "$EMULATOR_IMAGE_ROOT" &
EMULATOR_PID=$!

for _ in $(seq 1 90); do
  if connected; then
    echo "模拟器就绪：$("$HDC" list targets)"
    exit 0
  fi
  sleep 2
done

echo "模拟器 120s 内未就绪（PID=${EMULATOR_PID}）；查看 Emulator 输出" >&2
exit 1
