#!/usr/bin/env bash
# 消费方薄包装（历史名）：转发到框架平台同步入口。
#
# 旧实现自带一份「快照 → entry」的复制逻辑，与框架 platforms/ohos/scripts/
# sync_platform.sh 重复且会出现两套指纹。现在只转发，不再持有实现副本。
#
# 用法： bash scripts/sync_sources.sh
set -euo pipefail
_HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="$(cd "$_HERE/.." && pwd)"
exec bash "$LAB/../../runtime/cjgui/platforms/ohos/scripts/sync_platform.sh" "$LAB"
