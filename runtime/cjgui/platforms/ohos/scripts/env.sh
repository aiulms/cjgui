#!/usr/bin/env bash
# CJGUI 鸿蒙应用环境变量。用法： source scripts/env.sh
# 与 labs/ohos_cangjie_smoke/scripts/env.sh 同源；SDK/模拟器核对见
# docs/plans/2026-09-20-harmonyos-cangjie-handoff.md §1。

set -o pipefail

export DEVECO_STUDIO_HOME="${DEVECO_STUDIO_HOME:-/Applications/DevEco-Studio.app}"
export DEVECO_OH_NATIVE_HOME="${DEVECO_OH_NATIVE_HOME:-$DEVECO_STUDIO_HOME/Contents/sdk/default/openharmony/native}"

export DEVECO_CANGJIE_HOME="${DEVECO_CANGJIE_HOME:-$HOME/cangjie-toolchains/harmonyos-cangjie-26.0.0.105/cangjie}"
export DEVECO_CANGJIE_PATH="${DEVECO_CANGJIE_PATH:-$DEVECO_CANGJIE_HOME}"
export CANGJIE_HOME="${CANGJIE_HOME:-$DEVECO_CANGJIE_HOME/build-tools}"

export AARCH64_LIBS="${AARCH64_LIBS:-$DEVECO_CANGJIE_HOME/api/lib/linux_ohos_aarch64_cjnative}"
export AARCH64_MACRO_LIBS="${AARCH64_MACRO_LIBS:-$DEVECO_CANGJIE_HOME/api/macro/ohos}"
export AARCH64_KIT_LIBS="${AARCH64_KIT_LIBS:-$DEVECO_CANGJIE_HOME/api/lib/linux_ohos_aarch64_cjnative/kit}"

export HDC="${HDC:-$DEVECO_STUDIO_HOME/Contents/sdk/default/openharmony/toolchains/hdc}"
export DEVECO_CLI="${DEVECO_CLI:-$HOME/.local/bin/devecocli}"
export EMULATOR_BIN="${EMULATOR_BIN:-$DEVECO_STUDIO_HOME/Contents/tools/emulator/Emulator}"

export EMULATOR_NAME="${EMULATOR_NAME:-Pura 90}"
export EMULATOR_INSTANCE_PATH="${EMULATOR_INSTANCE_PATH:-$HOME/.Huawei/Emulator/deployed}"
export EMULATOR_IMAGE_ROOT="${EMULATOR_IMAGE_ROOT:-$HOME/Library/Huawei/Sdk}"

export CJGUI_APP_BUNDLE="${CJGUI_APP_BUNDLE:-com.example.cjguiapp}"
export CJGUI_APP_ABILITY="${CJGUI_APP_ABILITY:-EntryAbility}"
