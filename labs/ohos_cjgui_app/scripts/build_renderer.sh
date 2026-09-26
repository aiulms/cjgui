#!/usr/bin/env bash
# 消费方薄包装：转发到框架平台渲染器构建入口。
#
# 用法： bash scripts/build_renderer.sh [--test-gates]
set -euo pipefail
_HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="$(cd "$_HERE/.." && pwd)"
exec bash "$LAB/../../runtime/cjgui/platforms/ohos/scripts/build_renderer.sh" "$LAB" "$@"
