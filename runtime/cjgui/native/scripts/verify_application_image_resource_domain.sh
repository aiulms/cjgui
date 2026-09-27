#!/usr/bin/env zsh

# Tests the real two-window image loading path.  It must fail against the
# old session-owned cache (two actual decodes) and pass only when an explicit,
# bounded application resource domain merges the work without exposing native
# objects across the public Cangjie boundary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$(cd "$(dirname "$0")" && pwd)/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
REPOSITORY_DIR="$(cd "$RUNTIME_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_APPLICATION_IMAGE_RESOURCE_DOMAIN_TMPDIR:-/private/tmp/cjgui-application-image-resource-domain}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  print -u2 "cjgui application image resource domain test: unavailable SDKROOT=$SDKROOT_PATH"
  exit 2
fi

set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u
mkdir -p "$OUTPUT_DIR/native"
rm -f "$OUTPUT_DIR/probe.stdout.log" "$OUTPUT_DIR/probe.stderr.log" "$OUTPUT_DIR/manifest"
cd "$REPOSITORY_DIR"

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
ar rcs "$OUTPUT_DIR/native/libcjgui_application_image_resource_domain.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/application_image_resource_domain_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_application_image_resource_domain \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/application_image_resource_domain_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
set +e
"$OUTPUT_DIR/application_image_resource_domain_probe" >"$OUTPUT_DIR/probe.stdout.log" 2>"$OUTPUT_DIR/probe.stderr.log"
PROBE_STATUS=$?
set -e

cat "$OUTPUT_DIR/probe.stdout.log"
cat "$OUTPUT_DIR/probe.stderr.log" >&2

SOURCE_HASH="$(shasum -a 256 "$RUNTIME_DIR/probe/application_image_resource_domain_probe.cj" | awk '{print $1}')"
BINARY_HASH="$(shasum -a 256 "$OUTPUT_DIR/application_image_resource_domain_probe" | awk '{print $1}')"
{
  echo 'format=1'
  echo "probe_status=$PROBE_STATUS"
  echo "source_sha256=$SOURCE_HASH"
  echo "binary_sha256=$BINARY_HASH"
  echo "sdkroot=$SDKROOT_PATH"
  echo "probe_stdout=$OUTPUT_DIR/probe.stdout.log"
  echo "probe_stderr=$OUTPUT_DIR/probe.stderr.log"
} >"$OUTPUT_DIR/manifest"

if [[ "$PROBE_STATUS" -ne 0 ]]; then
  print -u2 "cjgui application image resource domain test: failed status=$PROBE_STATUS output=$OUTPUT_DIR"
  exit "$PROBE_STATUS"
fi
if ! rg -q 'CJGUI_APPLICATION_IMAGE_DOMAIN_SHARED .*shared_actual_loads=1 .*shared_actual_decodes=1 .*late_b_state=ready .*b_survives=true' "$OUTPUT_DIR/probe.stdout.log"; then
  print -u2 "cjgui application image resource domain test: missing shared-domain pass marker output=$OUTPUT_DIR"
  exit 1
fi
print "cjgui application image resource domain test: passed output=$OUTPUT_DIR manifest=$OUTPUT_DIR/manifest"
