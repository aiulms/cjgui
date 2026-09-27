#!/usr/bin/env zsh

# Repeated normal-window rendering/resource load proof. The probe drives the
# production Cangjie scheduler and native AppKit window; test symbols exist
# only to feed the already-owned native FIFO and resize callback.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$(cd "$(dirname "$0")" && pwd)/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_RENDER_RESOURCE_EFFICIENCY_TMPDIR:-/private/tmp/cjgui-render-resource-efficiency}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui render/resource efficiency probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u
mkdir -p "$OUTPUT_DIR/native"

# The probe must exercise both the entry-count and byte-budget eviction
# paths. Keep the generated 16px asset under its per-run temp directory so
# source resources and normal application bundles remain untouched.
sips -Z 16 "$RUNTIME_DIR/resources/composable-beacon.png" --out "$OUTPUT_DIR/small-resource.png" >/dev/null
if [[ ! -s "$OUTPUT_DIR/small-resource.png" ]]; then
  echo "cjgui render/resource efficiency probe: failed to create small resource fixture" >&2
  exit 2
fi

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
ar rcs "$OUTPUT_DIR/native/libcjgui_render_resource_efficiency.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/render_resource_efficiency_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_render_resource_efficiency \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/render_resource_efficiency_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
PROBE_STDOUT_LOG="$OUTPUT_DIR/probe.stdout.log"
PROBE_STDERR_LOG="$OUTPUT_DIR/probe.stderr.log"
if ! "$OUTPUT_DIR/render_resource_efficiency_probe" >"$PROBE_STDOUT_LOG" 2>"$PROBE_STDERR_LOG"; then
  cat "$PROBE_STDOUT_LOG"
  cat "$PROBE_STDERR_LOG" >&2
  exit 1
fi
# Keep Cangjie probe facts and concurrent native diagnostics in separate raw
# files. Replaying them only after the process exits makes every 30-sample
# marker line parseable even when Metal callbacks emit NSLog concurrently.
cat "$PROBE_STDOUT_LOG"
cat "$PROBE_STDERR_LOG" >&2
