#!/usr/bin/env bash
# 消费方薄包装：环境变量由框架平台入口拥有。
#
# 这里不再复制 SDK / 模拟器 / 工具链定义；唯一来源是
#   runtime/cjgui/platforms/ohos/scripts/env.sh
# lab 只负责声明「我在哪」，框架负责「怎么构建」。
#
# 用法： source scripts/env.sh
set -o pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export CJGUI_LAB_ROOT="$(cd "$_HERE/.." && pwd)"
export CJGUI_PLATFORM_ROOT="$(cd "$CJGUI_LAB_ROOT/../../runtime/cjgui/platforms/ohos" && pwd)"

if [ ! -f "$CJGUI_PLATFORM_ROOT/scripts/env.sh" ]; then
  echo "缺少框架平台入口: $CJGUI_PLATFORM_ROOT/scripts/env.sh" >&2
  return 1 2>/dev/null || exit 1
fi

# shellcheck source=/dev/null
source "$CJGUI_PLATFORM_ROOT/scripts/env.sh"
