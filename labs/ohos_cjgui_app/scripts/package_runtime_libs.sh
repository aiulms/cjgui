#!/usr/bin/env bash
# 消费方薄包装：转发到框架平台运行时库闭包打包入口。
#
# 用法： bash scripts/package_runtime_libs.sh
set -euo pipefail
_HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="$(cd "$_HERE/.." && pwd)"
exec bash "$LAB/../../runtime/cjgui/platforms/ohos/scripts/package_runtime_libs.sh" "$LAB"
