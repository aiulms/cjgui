#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "backup rule form: unavailable SDKROOT=$SDKROOT_PATH" >&2; exit 2
fi
set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u
mkdir -p "$SCRIPT_DIR/native/lib"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$SCRIPT_DIR/native/lib/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$SCRIPT_DIR/native/lib/cjgui_native_bridge.o"
ar rcs "$SCRIPT_DIR/native/lib/libcjgui_internal_renderer.a" "$SCRIPT_DIR/native/lib/cjgui_internal_renderer.o" "$SCRIPT_DIR/native/lib/cjgui_native_bridge.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 -I "$RUNTIME_DIR/native" -c "$RUNTIME_DIR/examples/shared_operation_window_app/native/macos_launcher.m" -o "$SCRIPT_DIR/native/lib/cjgui_shared_operation_launcher.o"
ar rcs "$SCRIPT_DIR/native/lib/libcjgui_shared_operation_launcher.a" "$SCRIPT_DIR/native/lib/cjgui_shared_operation_launcher.o"
export SDKROOT="$SDKROOT_PATH"
cd "$SCRIPT_DIR"; cjpm build
BUNDLE_DIR="$SCRIPT_DIR/target/release/CJGUIBackupRuleForm.app"
RUNTIME_LIB_DIR="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative"
mkdir -p "$BUNDLE_DIR/Contents/MacOS" "$BUNDLE_DIR/Contents/Frameworks"
cp "$SCRIPT_DIR/native/Info.plist" "$BUNDLE_DIR/Contents/Info.plist"
cp "$SCRIPT_DIR/target/release/bin/main" "$BUNDLE_DIR/Contents/MacOS/CJGUIBackupRuleForm"
cp "$RUNTIME_LIB_DIR/libcangjie-runtime.dylib" "$RUNTIME_LIB_DIR/libboundscheck.dylib" "$BUNDLE_DIR/Contents/Frameworks/"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$BUNDLE_DIR/Contents/MacOS/CJGUIBackupRuleForm"
codesign --force --deep --sign - "$BUNDLE_DIR"
exec "$BUNDLE_DIR/Contents/MacOS/CJGUIBackupRuleForm"
