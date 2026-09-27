#!/usr/bin/env zsh

# Generated-candidate commit probe.
#
# Builds the production renderer with the test-only injection seams and drives
# the ordinary window transaction: a native present failure while a generated
# candidate is prepared must roll the candidate back (no published version, no
# identity change), the previous structure must stay addressable, and a fresh
# candidate must commit normally afterwards.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/lib_cjgui_source_set.sh"
if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  SDKROOT_PATH="$CJ_GUI_SDKROOT"
elif [[ -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  SDKROOT_PATH="$SDKROOT"
else
  SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
OUTPUT_DIR="${CJGUI_GENERATED_COMMIT_PROBE_TMPDIR:-/private/tmp/cjgui-generated-commit-probe}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui generated commit probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR/native"

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_generated_commit_probe.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" true)}")
cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/composable_ui_generated_commit_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_generated_commit_probe \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/composable_ui_generated_commit_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/composable_ui_generated_commit_probe"
