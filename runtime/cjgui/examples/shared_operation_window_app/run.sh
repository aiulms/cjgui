#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$SCRIPT_DIR"
NATIVE_LIB_DIR="$APP_DIR/native/lib"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "CJGUI sample: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi
if ! command -v cjc >/dev/null 2>&1 || ! command -v cjpm >/dev/null 2>&1; then
  export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
  set +u
  source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
  set -u
fi

mkdir -p "$NATIVE_LIB_DIR"
clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" \
  -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" \
  -o "$NATIVE_LIB_DIR/cjgui_internal_renderer.o"
clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" \
  -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" \
  -o "$NATIVE_LIB_DIR/cjgui_native_bridge.o"
ar rcs "$NATIVE_LIB_DIR/libcjgui_internal_renderer.a" \
  "$NATIVE_LIB_DIR/cjgui_internal_renderer.o" \
  "$NATIVE_LIB_DIR/cjgui_native_bridge.o"
clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" \
  -mmacosx-version-min=12.0 \
  -I "$RUNTIME_DIR/native" \
  -c "$APP_DIR/native/macos_launcher.m" \
  -o "$NATIVE_LIB_DIR/cjgui_shared_operation_launcher.o"
ar rcs "$NATIVE_LIB_DIR/libcjgui_shared_operation_launcher.a" \
  "$NATIVE_LIB_DIR/cjgui_shared_operation_launcher.o"

export SDKROOT="$SDKROOT_PATH"
cd "$APP_DIR"
cjpm build

BUNDLE_DIR="$APP_DIR/target/release/CJGUISharedOperation.app"
RUNTIME_LIB_DIR="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative"
mkdir -p "$BUNDLE_DIR/Contents/MacOS" "$BUNDLE_DIR/Contents/Frameworks"
cp "$APP_DIR/native/Info.plist" "$BUNDLE_DIR/Contents/Info.plist"
cp "$APP_DIR/target/release/bin/main" "$BUNDLE_DIR/Contents/MacOS/CJGUISharedOperation"
cp "$RUNTIME_LIB_DIR/libcangjie-runtime.dylib" "$BUNDLE_DIR/Contents/Frameworks/"
cp "$RUNTIME_LIB_DIR/libboundscheck.dylib" "$BUNDLE_DIR/Contents/Frameworks/"
install_name_tool -add_rpath "@executable_path/../Frameworks" \
  "$BUNDLE_DIR/Contents/MacOS/CJGUISharedOperation"
codesign --force --deep --sign - "$BUNDLE_DIR"
# Run the signed bundle executable directly by default so the deliberate
# descriptor handoff printed by the Cangjie app stays available to the caller
# that launched this example. The process still creates a normal AppKit window
# through the bundle's launcher. Set this only when testing Launch Services
# behavior, where stdout is intentionally not a discovery channel.
if [[ "${CJGUI_USE_LAUNCH_SERVICES:-0}" == "1" ]]; then
  exec open -W "$BUNDLE_DIR"
fi
exec "$BUNDLE_DIR/Contents/MacOS/CJGUISharedOperation"
