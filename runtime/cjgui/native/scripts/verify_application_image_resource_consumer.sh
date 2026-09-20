#!/usr/bin/env zsh

# Normal application-image lifecycle acceptance.  The probe uses the shipped
# Cangjie window/controller path and only test-only scalar renderer facts; it
# never receives a native texture. Historical duplicate-decode RED evidence
# lives in the domain probe's pre-migration baseline note; this runner only
# executes current-source behaviour and never pretends it can recreate old
# ownership by toggling an environment variable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_APPLICATION_IMAGE_RESOURCE_TMPDIR:-/private/tmp/cjgui-application-image-resource-consumer}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui application-image consumer: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

mkdir -p "$OUTPUT_DIR/native"
rm -f "$OUTPUT_DIR/probe.stdout.log" "$OUTPUT_DIR/probe.stderr.log" "$OUTPUT_DIR/manifest"

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
ar rcs "$OUTPUT_DIR/native/libcjgui_application_image_resource_consumer.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$RUNTIME_DIR/probe/application_image_resource_consumer_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_application_image_resource_consumer \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/application_image_resource_consumer_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
set +e
"$OUTPUT_DIR/application_image_resource_consumer_probe" >"$OUTPUT_DIR/probe.stdout.log" 2>"$OUTPUT_DIR/probe.stderr.log"
PROBE_STATUS=$?
set -e

cat "$OUTPUT_DIR/probe.stdout.log"
cat "$OUTPUT_DIR/probe.stderr.log" >&2

SOURCE_HASH="$(shasum -a 256 "$RUNTIME_DIR/probe/application_image_resource_consumer_probe.cj" | awk '{print $1}')"
BLUE_HASH="$(shasum -a 256 "$RUNTIME_DIR/resources/composable-beacon.png" | awk '{print $1}')"
CORAL_HASH="$(shasum -a 256 "$RUNTIME_DIR/resources/composable-beacon-coral.png" | awk '{print $1}')"
BINARY_HASH="$(shasum -a 256 "$OUTPUT_DIR/application_image_resource_consumer_probe" | awk '{print $1}')"
{
  echo "format=1"
  echo "probe_status=$PROBE_STATUS"
  echo "source_sha256=$SOURCE_HASH"
  echo "binary_sha256=$BINARY_HASH"
  echo "blue_fixture_sha256=$BLUE_HASH"
  echo "coral_fixture_sha256=$CORAL_HASH"
  echo "sdkroot=$SDKROOT_PATH"
  echo "output_dir=$OUTPUT_DIR"
  echo "probe_stdout=$OUTPUT_DIR/probe.stdout.log"
  echo "probe_stderr=$OUTPUT_DIR/probe.stderr.log"
} >"$OUTPUT_DIR/manifest"

if [[ "$PROBE_STATUS" -ne 0 ]]; then
  echo "cjgui application-image consumer: probe failed status=$PROBE_STATUS manifest=$OUTPUT_DIR/manifest" >&2
  exit "$PROBE_STATUS"
fi
if ! rg -q 'CJGUI_APPLICATION_IMAGE_CONSUMER passed=true' "$OUTPUT_DIR/probe.stdout.log"; then
  echo 'cjgui application-image consumer: missing pass marker' >&2
  exit 1
fi
echo "CJGUI_APPLICATION_IMAGE_CONSUMER_VERIFY passed=true manifest=$OUTPUT_DIR/manifest"
