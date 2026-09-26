#!/usr/bin/env bash
# 消费方薄包装：转发到框架平台构建+运行入口。
#
# 构建、闭包校验、启动断言、证据落盘的实现都在框架里
# （runtime/cjgui/platforms/ohos/scripts/build_and_run.sh）；
# 这里只固定 LAB 并透传参数，避免 lab 侧再长出一套会漂移的流程。
#
# 用法： bash scripts/build_and_run.sh [--no-emulator-start] [--run-id <id>]
# 负对照： CJGUI_NEGATIVE_MISSING_LIB=libnope.so / CJGUI_NEGATIVE_NO_START=1
set -euo pipefail
_HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="$(cd "$_HERE/.." && pwd)"
exec bash "$LAB/../../runtime/cjgui/platforms/ohos/scripts/build_and_run.sh" "$LAB" "$@"
