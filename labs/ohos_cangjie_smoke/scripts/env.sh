#!/usr/bin/env bash
# 仓颉（Cangjie）鸿蒙侧环境变量。用法： source scripts/env.sh
#
# 说明：DevEco 26 的仓颉能力随插件分发，插件内含
#   harmonyos-cangjie-sdk-mac-arm.zip（本仓库作者已解压到下面默认路径）。
# 可通过环境变量覆盖，便于换机器/换版本。

set -o pipefail

# ── DevEco Studio 与 native SDK ─────────────────────────────────────────────
export DEVECO_STUDIO_HOME="${DEVECO_STUDIO_HOME:-/Applications/DevEco-Studio.app}"
export DEVECO_OH_NATIVE_HOME="${DEVECO_OH_NATIVE_HOME:-$DEVECO_STUDIO_HOME/Contents/sdk/default/openharmony/native}"

# ── 仓颉 SDK（HarmonyOS 版，ohos 交叉工具链） ──────────────────────────────
export DEVECO_CANGJIE_HOME="${DEVECO_CANGJIE_HOME:-$HOME/cangjie-toolchains/harmonyos-cangjie-26.0.0.105/cangjie}"
export DEVECO_CANGJIE_PATH="${DEVECO_CANGJIE_PATH:-$DEVECO_CANGJIE_HOME}"
export CANGJIE_HOME="${CANGJIE_HOME:-$DEVECO_CANGJIE_HOME/build-tools}"

# ── 供 cjpm 的 bin-dependencies 解析 kit / macro / ohos 库 ──────────────────
export AARCH64_LIBS="${AARCH64_LIBS:-$DEVECO_CANGJIE_HOME/api/lib/linux_ohos_aarch64_cjnative}"
export AARCH64_MACRO_LIBS="${AARCH64_MACRO_LIBS:-$DEVECO_CANGJIE_HOME/api/macro/ohos}"
export AARCH64_KIT_LIBS="${AARCH64_KIT_LIBS:-$DEVECO_CANGJIE_HOME/api/lib/linux_ohos_aarch64_cjnative/kit}"

# ── 命令行工具 ──────────────────────────────────────────────────────────────
export HDC="${HDC:-$DEVECO_STUDIO_HOME/Contents/sdk/default/openharmony/toolchains/hdc}"
export DEVECO_CLI="${DEVECO_CLI:-$HOME/.local/bin/devecocli}"
export EMULATOR_BIN="${EMULATOR_BIN:-$DEVECO_STUDIO_HOME/Contents/tools/emulator/Emulator}"

# 默认模拟器实例（可用 EMULATOR_NAME 覆盖）
export EMULATOR_NAME="${EMULATOR_NAME:-Pura 90}"
export EMULATOR_INSTANCE_PATH="${EMULATOR_INSTANCE_PATH:-$HOME/.Huawei/Emulator/deployed}"
export EMULATOR_IMAGE_ROOT="${EMULATOR_IMAGE_ROOT:-$HOME/Library/Huawei/Sdk}"

# 冒烟用的 bundle / ability（见 entry/src/main/module.json5 与 AppScope/app.json5）
export SMOKE_BUNDLE="${SMOKE_BUNDLE:-com.example.hellopoc}"
export SMOKE_ABILITY="${SMOKE_ABILITY:-MainAbility}"
