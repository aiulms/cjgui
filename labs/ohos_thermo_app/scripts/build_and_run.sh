#!/usr/bin/env bash
# thermo 宿主的薄包装：固定应用身份参数后转发到框架平台构建+运行入口。
#
# 与产品宿主（Pharos Mark/apps/pharos_mark_ohos/scripts/build_and_run.sh）同形：
# 构建、闭包校验、启动断言、证据落盘都在框架里
# （runtime/cjgui/platforms/ohos/scripts/build_and_run.sh），这里只固定身份：
#   * HOST = 本目录
#   * 应用源 = 共享示例 thermostat_application（唯一来源，不另建应用）
#   * 目录名 / 包名 / 产物库名 = 本宿主的实际值
# 不写死就会退回框架默认值（设置计数示例）：实测会把
# `libcjgui_settings_counter_application.so` 当成必需产物判 MISS，而真正的
# `libcjgui_thermostat_application.so` 在 HAP 里躺着；同时示例目录会被同步进本
# 宿主，产品应用源码则**不**再同步——上一轮 `takeRestoreAdoptionFact is not a
# member` 就是这么来的（手工 cp 的镜像与框架源漂移）。
# 负对照与选项原样透传。
set -euo pipefail
_HERE="$(cd "$(dirname "$0")" && pwd)"
HOST="$(cd "$_HERE/.." && pwd)"
CJGUI_PLATFORM="${CJGUI_PLATFORM:-/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos}"
REPO_ROOT="$(cd "$CJGUI_PLATFORM/../../../.." && pwd)"

export CJGUI_APP_SRC="${CJGUI_APP_SRC:-$REPO_ROOT/runtime/cjgui/examples/thermostat_application/src}"
export CJGUI_APP_DIR_NAME="${CJGUI_APP_DIR_NAME:-thermostat_application}"
export CJGUI_APP_PKG_NAME="${CJGUI_APP_PKG_NAME:-cjgui_thermostat_application}"
export CJGUI_APP_PKG_LIB="${CJGUI_APP_PKG_LIB:-libcjgui_thermostat_application.so}"

exec bash "$CJGUI_PLATFORM/scripts/build_and_run.sh" "$HOST" "$@"
