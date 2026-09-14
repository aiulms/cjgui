#!/usr/bin/env zsh
set -euo pipefail

if (( $# < 1 )); then
  echo 'usage: run_macos_application.sh APP_CONFIG [--build-only] [application arguments...]' >&2
  exit 2
fi

APP_CONFIG="$1"
shift
if [[ ! -f "$APP_CONFIG" ]]; then
  echo "cjgui macOS application host: missing config $APP_CONFIG" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$(cd "$(dirname "$APP_CONFIG")" && pwd)"
APP_CONFIG="$APP_DIR/$(basename "$APP_CONFIG")"
# The normal entry point owns its compiler choice. A manifest's `cjc-version`
# constrains cjpm but cannot select a compiler inherited from an interactive
# shell.  A developer selects 1.1.3 once through CANGJIE_HOME, or makes a
# one-run override explicit through CJGUI_CANGJIE_HOME.  Do not embed a
# repository author's machine path: exported source previews use this runner.
REQUESTED_CANGJIE_HOME="${CJGUI_CANGJIE_HOME:-${CANGJIE_HOME:-}}"
if [[ -z "$REQUESTED_CANGJIE_HOME" ]]; then
  echo 'cjgui macOS application host: no selected Cangjie toolchain; set CANGJIE_HOME to Cangjie 1.1.3 or set CJGUI_CANGJIE_HOME explicitly' >&2
  exit 2
fi
if [[ ! -f "$REQUESTED_CANGJIE_HOME/envsetup.sh" ]]; then
  echo "cjgui macOS application host: unavailable Cangjie toolchain $REQUESTED_CANGJIE_HOME; set CJGUI_CANGJIE_HOME explicitly" >&2
  exit 2
fi
# The vendor setup script reads both variables under `set -u` on some
# installations.  Preserve an inherited value when present, but make an
# unset value explicit before sourcing the project-selected toolchain.
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-}"
source "$REQUESTED_CANGJIE_HOME/envsetup.sh"
if [[ -z "${CANGJIE_HOME:-}" || ! -x "$CANGJIE_HOME/bin/cjc" ]]; then
  echo "cjgui macOS application host: selected toolchain did not provide cjc (CANGJIE_HOME=${CANGJIE_HOME:-unset})" >&2
  exit 2
fi
CJGUI_CJC_VERSION="$(cjc --version 2>/dev/null | head -n 1 || true)"
if [[ -z "$CJGUI_CJC_VERSION" ]]; then
  echo "cjgui macOS application host: selected toolchain cjc did not report a version" >&2
  exit 2
fi
if [[ -z "${CJGUI_CANGJIE_HOME:-}" && "$CJGUI_CJC_VERSION" != *"1.1.3"* ]]; then
  echo "cjgui macOS application host: default toolchain must be Cangjie 1.1.3, observed: $CJGUI_CJC_VERSION" >&2
  exit 2
fi
if [[ -n "${CJGUI_CANGJIE_HOME:-}" ]]; then
  echo "cjgui macOS application host: toolchain=override home=$CANGJIE_HOME version=$CJGUI_CJC_VERSION"
else
  echo "cjgui macOS application host: toolchain=project-default home=$CANGJIE_HOME version=$CJGUI_CJC_VERSION"
fi
# The normal 1.1.3 path uses the active Command Line Tools SDK.  A caller may
# still pin a known-good older SDK (for example 15.4) through CJ_GUI_SDKROOT,
# without changing the machine-wide MacOSX.sdk link.
if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  SDKROOT_PATH="$CJ_GUI_SDKROOT"
elif [[ -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  SDKROOT_PATH="$SDKROOT"
else
  SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
NATIVE_SOURCE_DIR="${CJGUI_NATIVE_SOURCE_DIR:-$RUNTIME_DIR/native}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui macOS application host: unavailable SDKROOT=$SDKROOT_PATH; set CJ_GUI_SDKROOT explicitly" >&2
  exit 2
fi
if [[ ! -d "$NATIVE_SOURCE_DIR" ]]; then
  echo "cjgui macOS application host: unavailable native source directory $NATIVE_SOURCE_DIR" >&2
  exit 2
fi
if ! command -v clang >/dev/null 2>&1 || ! command -v ar >/dev/null 2>&1 || ! command -v cjpm >/dev/null 2>&1 || ! command -v shasum >/dev/null 2>&1 || ! command -v nm >/dev/null 2>&1; then
  echo 'cjgui macOS application host: clang, ar, cjpm, shasum and nm must be on PATH' >&2
  exit 2
fi

export CJGUI_RUNTIME_DIR="$RUNTIME_DIR"
export CJGUI_APP_DIR="$APP_DIR"
unset CJGUI_MACOS_APP_BUNDLE_NAME CJGUI_MACOS_APP_EXECUTABLE_NAME
unset CJGUI_MACOS_APP_IDENTIFIER CJGUI_MACOS_APP_DISPLAY_NAME
typeset -a CJGUI_MACOS_APP_RESOURCES
CJGUI_MACOS_APP_RESOURCES=()
source "$APP_CONFIG"

: "${CJGUI_MACOS_APP_BUNDLE_NAME:?config must set CJGUI_MACOS_APP_BUNDLE_NAME}"
: "${CJGUI_MACOS_APP_EXECUTABLE_NAME:?config must set CJGUI_MACOS_APP_EXECUTABLE_NAME}"
: "${CJGUI_MACOS_APP_IDENTIFIER:?config must set CJGUI_MACOS_APP_IDENTIFIER}"
: "${CJGUI_MACOS_APP_DISPLAY_NAME:?config must set CJGUI_MACOS_APP_DISPLAY_NAME}"
if [[ "$CJGUI_MACOS_APP_BUNDLE_NAME" == *'/'* || "$CJGUI_MACOS_APP_BUNDLE_NAME" == *'.app'* || "$CJGUI_MACOS_APP_EXECUTABLE_NAME" == *'/'* || "$CJGUI_MACOS_APP_IDENTIFIER" == *'/'* ]]; then
  echo 'cjgui macOS application host: bundle, executable and identifier must be plain configured names' >&2
  exit 2
fi

# Emit build provenance before any cache is materialized.  This makes a
# source-preview consumer's actual framework/native/dependency selection
# auditable without treating a static relative-path scan as runtime proof.
# `CJGUI_NATIVE_SOURCE_DIR` remains a supported deliberate override; callers
# that need isolation must clear it themselves rather than changing this
# normal developer entry point.
print -r -- "cjgui macOS application host: source_origin runtime=$RUNTIME_DIR native=$NATIVE_SOURCE_DIR dependency_cjgui=$RUNTIME_DIR dependency_core=$RUNTIME_DIR/shared_operation_core"
for configured_resource in "${CJGUI_MACOS_APP_RESOURCES[@]}"; do
  print -r -- "cjgui macOS application host: resource_origin=$configured_resource"
done

BUILD_ONLY=0
if [[ "${1:-}" == '--build-only' ]]; then
  BUILD_ONLY=1
  shift
fi

NATIVE_LIB_DIR="$APP_DIR/.cjgui/native/lib"
RENDERER_ARCHIVE="$NATIVE_LIB_DIR/libcjgui_internal_renderer.a"
LAUNCHER_ARCHIVE="$NATIVE_LIB_DIR/libcjgui_macos_application_launcher.a"
FINGERPRINT_FILE="$NATIVE_LIB_DIR/cjgui_macos_application_host.fingerprint"
LINK_FINGERPRINT_FILE="$NATIVE_LIB_DIR/cjgui_macos_application_host.linked.fingerprint"
RENDERER_SOURCE="$NATIVE_SOURCE_DIR/cjgui_internal_renderer.m"
BRIDGE_SOURCE="$NATIVE_SOURCE_DIR/cjgui_native_bridge.m"
RENDERER_HEADER="$NATIVE_SOURCE_DIR/cjgui_internal_renderer.h"
BRIDGE_HEADER="$NATIVE_SOURCE_DIR/cjgui_native_bridge.h"
LAUNCHER_SOURCE="$NATIVE_SOURCE_DIR/cjgui_macos_application_launcher.m"
for native_input in "$RENDERER_SOURCE" "$BRIDGE_SOURCE" "$RENDERER_HEADER" "$BRIDGE_HEADER" "$LAUNCHER_SOURCE"; do
  if [[ ! -f "$native_input" ]]; then
    echo "cjgui macOS application host: missing native input $native_input" >&2
    exit 2
  fi
done

typeset -a CLANG_FLAGS
CLANG_FLAGS=(-fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -mmacosx-version-min=12.0)
# This is an explicit build input (for example a temporary -D flag in a reproducer), not an application argument.
if [[ -n "${CJGUI_NATIVE_CLANG_FLAGS_APPEND:-}" ]]; then
  CLANG_FLAGS+=( ${=CJGUI_NATIVE_CLANG_FLAGS_APPEND} )
fi
CLANG_PATH="$(command -v clang)"
AR_PATH="$(command -v ar)"

hash_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

sdk_identity() {
  local candidate
  print -r -- "path=$SDKROOT_PATH"
  for candidate in SDKSettings.json SDKSettings.plist System/Library/CoreServices/SystemVersion.plist; do
    if [[ -f "$SDKROOT_PATH/$candidate" ]]; then
      print -r -- "$candidate=$(hash_file "$SDKROOT_PATH/$candidate")"
    fi
  done
}

native_fingerprint() {
  print -r -- 'format=2'
  print -r -- "native_source_dir=$NATIVE_SOURCE_DIR"
  print -r -- "renderer=$(hash_file "$RENDERER_SOURCE")"
  print -r -- "bridge=$(hash_file "$BRIDGE_SOURCE")"
  print -r -- "renderer_header=$(hash_file "$RENDERER_HEADER")"
  print -r -- "bridge_header=$(hash_file "$BRIDGE_HEADER")"
  print -r -- "launcher=$(hash_file "$LAUNCHER_SOURCE")"
  print -r -- "clang_path=$CLANG_PATH"
  print -r -- "clang_binary=$(hash_file "$CLANG_PATH")"
  print -r -- "clang_version=$($CLANG_PATH --version | tr '\n' ' ')"
  print -r -- "ar_path=$AR_PATH"
  print -r -- "ar_binary=$(hash_file "$AR_PATH")"
  print -r -- "ar_version=$($AR_PATH -V 2>&1 || true)"
  print -r -- "clang_flags=${(j: :)CLANG_FLAGS}"
  sdk_identity
}

FINGERPRINT="$(native_fingerprint)"
mkdir -p "$NATIVE_LIB_DIR"

# This lock is scoped to generated state for one application. Different apps keep independent locks.
BUILD_LOCK="$APP_DIR/.cjgui/macos_application_build.lock"
BUILD_LOCK_HELD=0
release_build_lock() {
  if (( BUILD_LOCK_HELD )); then
    rmdir "$BUILD_LOCK" 2>/dev/null || true
    BUILD_LOCK_HELD=0
  fi
}
cleanup_generated_staging() {
  if [[ -n "${NATIVE_BUILD_DIR:-}" && -d "$NATIVE_BUILD_DIR" ]]; then rm -rf "$NATIVE_BUILD_DIR"; fi
  if [[ -n "${BUNDLE_STAGING_DIR:-}" && -d "$BUNDLE_STAGING_DIR" ]]; then rm -rf "$BUNDLE_STAGING_DIR"; fi
  release_build_lock
}
trap cleanup_generated_staging EXIT
trap 'cleanup_generated_staging; exit 130' HUP INT TERM

lock_started="$(date +%s)"
while ! mkdir "$BUILD_LOCK" 2>/dev/null; do
  if (( $(date +%s) - lock_started >= 120 )); then
    echo "cjgui macOS application host: timed out waiting for same-app build lock $BUILD_LOCK" >&2
    exit 2
  fi
  sleep 0.1
done
BUILD_LOCK_HELD=1

NEEDS_NATIVE_REBUILD=0
if [[ ! -f "$RENDERER_ARCHIVE" || ! -f "$LAUNCHER_ARCHIVE" || ! -f "$FINGERPRINT_FILE" || "$(< "$FINGERPRINT_FILE")" != "$FINGERPRINT" ]]; then
  NEEDS_NATIVE_REBUILD=1
fi

if (( NEEDS_NATIVE_REBUILD )); then
  NATIVE_BUILD_DIR="$(mktemp -d "$NATIVE_LIB_DIR/.cjgui-native-build.XXXXXX")"
  "$CLANG_PATH" "${CLANG_FLAGS[@]}" -isysroot "$SDKROOT_PATH" -c "$RENDERER_SOURCE" -o "$NATIVE_BUILD_DIR/cjgui_internal_renderer.o"
  "$CLANG_PATH" "${CLANG_FLAGS[@]}" -isysroot "$SDKROOT_PATH" -c "$BRIDGE_SOURCE" -o "$NATIVE_BUILD_DIR/cjgui_native_bridge.o"
  "$AR_PATH" rcs "$NATIVE_BUILD_DIR/libcjgui_internal_renderer.a" "$NATIVE_BUILD_DIR/cjgui_internal_renderer.o" "$NATIVE_BUILD_DIR/cjgui_native_bridge.o"
  "$CLANG_PATH" "${CLANG_FLAGS[@]}" -isysroot "$SDKROOT_PATH" -I "$NATIVE_SOURCE_DIR" -c "$LAUNCHER_SOURCE" -o "$NATIVE_BUILD_DIR/cjgui_macos_application_launcher.o"
  "$AR_PATH" rcs "$NATIVE_BUILD_DIR/libcjgui_macos_application_launcher.a" "$NATIVE_BUILD_DIR/cjgui_macos_application_launcher.o"
  # Archives arrive before their key; an unsuccessful compile/archive never advertises a valid new fingerprint.
  mv "$NATIVE_BUILD_DIR/libcjgui_internal_renderer.a" "$RENDERER_ARCHIVE"
  mv "$NATIVE_BUILD_DIR/libcjgui_macos_application_launcher.a" "$LAUNCHER_ARCHIVE"
  print -rn -- "$FINGERPRINT" > "$NATIVE_BUILD_DIR/fingerprint"
  mv "$NATIVE_BUILD_DIR/fingerprint" "$FINGERPRINT_FILE"
  rm -rf "$NATIVE_BUILD_DIR"
  NATIVE_BUILD_DIR=""
  print -r -- 'cjgui macOS application host: native_archive=rebuilt'
else
  print -r -- 'cjgui macOS application host: native_archive=reused'
fi

# `cjgui` is itself a static CFFI package.  Its manifest deliberately names a
# package-local renderer archive, while an application owns the launcher and
# its per-app native cache.  Materialize the former from the just-verified
# app-local source build before cjpm resolves the dependency graph.  This is a
# generated cache, not an exported binary SDK: a fresh source preview starts
# without it and recreates it from the copied native sources on first build.
FRAMEWORK_NATIVE_LIB_DIR="$RUNTIME_DIR/native/lib"
FRAMEWORK_RENDERER_ARCHIVE="$FRAMEWORK_NATIVE_LIB_DIR/libcjgui_internal_renderer.a"
FRAMEWORK_RENDERER_FINGERPRINT="$FRAMEWORK_NATIVE_LIB_DIR/cjgui_internal_renderer_sidecar.fingerprint"
if [[ ! -f "$FRAMEWORK_RENDERER_ARCHIVE" || ! -f "$FRAMEWORK_RENDERER_FINGERPRINT" || "$(< "$FRAMEWORK_RENDERER_FINGERPRINT")" != "$FINGERPRINT" ]]; then
  mkdir -p "$FRAMEWORK_NATIVE_LIB_DIR"
  FRAMEWORK_NATIVE_BUILD_DIR="$(mktemp -d "$RUNTIME_DIR/native/.cjgui-framework-native-build.XXXXXX")"
  cp "$RENDERER_ARCHIVE" "$FRAMEWORK_NATIVE_BUILD_DIR/libcjgui_internal_renderer.a"
  print -rn -- "$FINGERPRINT" > "$FRAMEWORK_NATIVE_BUILD_DIR/fingerprint"
  mv "$FRAMEWORK_NATIVE_BUILD_DIR/libcjgui_internal_renderer.a" "$FRAMEWORK_RENDERER_ARCHIVE"
  mv "$FRAMEWORK_NATIVE_BUILD_DIR/fingerprint" "$FRAMEWORK_RENDERER_FINGERPRINT"
  rmdir "$FRAMEWORK_NATIVE_BUILD_DIR"
  print -r -- 'cjgui macOS application host: framework_native_archive=rebuilt'
else
  print -r -- 'cjgui macOS application host: framework_native_archive=reused'
fi

export SDKROOT="$SDKROOT_PATH"
APP_EXECUTABLE="$APP_DIR/target/release/bin/main"
# A changed native key forces only this app's executable to relink; cjpm retains its package graph.
if (( NEEDS_NATIVE_REBUILD )); then rm -f "$APP_EXECUTABLE"; fi
(cd "$APP_DIR" && cjpm build -i)
if [[ ! -x "$APP_EXECUTABLE" ]]; then
  echo "cjgui macOS application host: cjpm did not publish executable $APP_EXECUTABLE" >&2
  exit 2
fi
if ! nm "$APP_EXECUTABLE" | rg 'cjgui_internal_renderer_set_window_title' >/dev/null; then
  echo 'cjgui macOS application host: cjpm executable is not linked to the renderer archive' >&2
  exit 2
fi
LINK_BUILD_DIR="$(mktemp -d "$NATIVE_LIB_DIR/.cjgui-link-build.XXXXXX")"
print -rn -- "$FINGERPRINT" > "$LINK_BUILD_DIR/fingerprint"
mv "$LINK_BUILD_DIR/fingerprint" "$LINK_FINGERPRINT_FILE"
rmdir "$LINK_BUILD_DIR"

RUNTIME_LIB_DIR="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative"
if [[ ! -d "$RUNTIME_LIB_DIR" ]]; then
  echo "cjgui macOS application host: unavailable Cangjie runtime $RUNTIME_LIB_DIR" >&2
  exit 2
fi

BUNDLE_DIR="$APP_DIR/target/release/${CJGUI_MACOS_APP_BUNDLE_NAME}.app"
BUNDLE_STAGING_ROOT="$APP_DIR/.cjgui/bundle-staging"
mkdir -p "$BUNDLE_STAGING_ROOT"
BUNDLE_STAGING_DIR="$(mktemp -d "$BUNDLE_STAGING_ROOT/${CJGUI_MACOS_APP_BUNDLE_NAME}.app.XXXXXX")"
mkdir -p "$BUNDLE_STAGING_DIR/Contents/MacOS" "$BUNDLE_STAGING_DIR/Contents/Frameworks" "$BUNDLE_STAGING_DIR/Contents/Resources"
INFO_PLIST="$BUNDLE_STAGING_DIR/Contents/Info.plist"
plutil -create xml1 "$INFO_PLIST"
plutil -replace CFBundleDisplayName -string "$CJGUI_MACOS_APP_DISPLAY_NAME" "$INFO_PLIST"
plutil -replace CFBundleExecutable -string "$CJGUI_MACOS_APP_EXECUTABLE_NAME" "$INFO_PLIST"
plutil -replace CFBundleIdentifier -string "$CJGUI_MACOS_APP_IDENTIFIER" "$INFO_PLIST"
plutil -replace CFBundleName -string "$CJGUI_MACOS_APP_DISPLAY_NAME" "$INFO_PLIST"
plutil -replace CFBundlePackageType -string APPL "$INFO_PLIST"
plutil -replace CFBundleShortVersionString -string 0.0.0 "$INFO_PLIST"
plutil -replace LSMinimumSystemVersion -string 12.0 "$INFO_PLIST"
plutil -replace NSHighResolutionCapable -bool true "$INFO_PLIST"
plutil -lint "$INFO_PLIST" >/dev/null

typeset -A RESOURCE_DESTINATIONS
for resource in "${CJGUI_MACOS_APP_RESOURCES[@]}"; do
  if [[ ! -f "$resource" ]]; then
    echo "cjgui macOS application host: missing configured resource $resource" >&2
    exit 2
  fi
  destination="$(basename "$resource")"
  if [[ -n "${RESOURCE_DESTINATIONS[$destination]:-}" ]]; then
    echo "cjgui macOS application host: duplicate configured resource basename $destination" >&2
    exit 2
  fi
  RESOURCE_DESTINATIONS[$destination]=1
  cp "$resource" "$BUNDLE_STAGING_DIR/Contents/Resources/$destination"
done

cp "$APP_EXECUTABLE" "$BUNDLE_STAGING_DIR/Contents/MacOS/$CJGUI_MACOS_APP_EXECUTABLE_NAME"
cp "$RUNTIME_LIB_DIR/libcangjie-runtime.dylib" "$RUNTIME_LIB_DIR/libboundscheck.dylib" "$BUNDLE_STAGING_DIR/Contents/Frameworks/"
install_name_tool -add_rpath '@executable_path/../Frameworks' "$BUNDLE_STAGING_DIR/Contents/MacOS/$CJGUI_MACOS_APP_EXECUTABLE_NAME"
codesign --force --deep --sign - "$BUNDLE_STAGING_DIR"

# The published bundle is replaced only after its staged executable, resources, runtime and signature all succeed.
BUNDLE_PREVIOUS_DIR=""
if [[ -e "$BUNDLE_DIR" || -L "$BUNDLE_DIR" ]]; then
  BUNDLE_PREVIOUS_DIR="$(mktemp -d "$BUNDLE_STAGING_ROOT/${CJGUI_MACOS_APP_BUNDLE_NAME}.previous.XXXXXX")"
  rmdir "$BUNDLE_PREVIOUS_DIR"
  mv "$BUNDLE_DIR" "$BUNDLE_PREVIOUS_DIR"
fi
if ! mv "$BUNDLE_STAGING_DIR" "$BUNDLE_DIR"; then
  if [[ -n "$BUNDLE_PREVIOUS_DIR" && -e "$BUNDLE_PREVIOUS_DIR" ]]; then mv "$BUNDLE_PREVIOUS_DIR" "$BUNDLE_DIR"; fi
  exit 2
fi
BUNDLE_STAGING_DIR=""
if [[ -n "$BUNDLE_PREVIOUS_DIR" ]]; then rm -rf "$BUNDLE_PREVIOUS_DIR"; fi

release_build_lock
if (( BUILD_ONLY )); then exit 0; fi
if [[ "${CJGUI_USE_LAUNCH_SERVICES:-0}" == '1' ]]; then
  if (( $# > 0 )); then exec open -W "$BUNDLE_DIR" --args "$@"; fi
  exec open -W "$BUNDLE_DIR"
fi
exec "$BUNDLE_DIR/Contents/MacOS/$CJGUI_MACOS_APP_EXECUTABLE_NAME" "$@"
