#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI Settings demo app.
# Scope: compile and run runtime/cjgui/demo/settings_app.cj against a temporary package built from the production Settings demo API source.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/settings_app.cj"
API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_settings_demo_api.cj"
TMP_DIR="${CJGUI_SETTINGS_DEMO_TMPDIR:-/private/tmp/cjgui-settings-demo-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/settings-demo-output.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$BUILD_DIR" "$PROBE_PACKAGE_DIR/src" "$PROBE_API_PACKAGE_DIR/src"
: > "$OUTPUT_LOG"

cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

ensure_toolchain() {
  if command -v cjc >/dev/null 2>&1 && command -v cjpm >/dev/null 2>&1; then
    return
  fi
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    export PATH="$PS_SHIM_DIR:$PATH"
    set +u
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
    set -u
  fi
}

require_source_line() {
  local expected="$1"
  local source_file="$2"
  if ! grep -F "$expected" "$source_file" >/dev/null 2>&1; then
    echo "cjgui settings demo app verification: missing source line: $expected" >&2
    exit 10
  fi
}

require_output_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui settings demo app verification: missing output line: $expected" >&2
    echo "cjgui settings demo app verification: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 20
  fi
}

if [[ ! -f "$DEMO_SRC" ]]; then
  echo "cjgui settings demo app verification: missing demo source $DEMO_SRC" >&2
  exit 2
fi

if [[ ! -f "$API_SRC" ]]; then
  echo "cjgui settings demo app verification: missing API source $API_SRC" >&2
  exit 2
fi

require_source_line "public class CjguiExperimentalSettingsDemoOutput" "$API_SRC"
require_source_line "public func cjguiExperimentalBuildSettingsDemoOutput" "$API_SRC"
require_source_line "public let summary: String" "$API_SRC"
require_source_line "package cjgui_settings_demo" "$DEMO_SRC"
require_source_line "import cjgui.*" "$DEMO_SRC"
require_source_line "class SettingsPanelState" "$DEMO_SRC"
require_source_line "var selectedTheme: String" "$DEMO_SRC"
require_source_line "var usernameValue: String" "$DEMO_SRC"
require_source_line "var focusTarget: String" "$DEMO_SRC"
require_source_line "var autoSaveEnabled: Bool" "$DEMO_SRC"
require_source_line "main(): Int64" "$DEMO_SRC"
require_source_line "CjguiExperimentalSettingsDemoOutput" "$DEMO_SRC"
require_source_line "cjguiExperimentalBuildSettingsDemoOutput" "$DEMO_SRC"
require_source_line "cjgui settings demo app: status_before=scaffolded" "$DEMO_SRC"
require_source_line "cjgui settings demo app: status_after=runnable" "$DEMO_SRC"
require_source_line "cjgui settings demo app: state_before=" "$DEMO_SRC"
require_source_line "cjgui settings demo app: state_after=" "$DEMO_SRC"
require_source_line "cjgui settings demo app: state_readback=" "$DEMO_SRC"
require_source_line "cjgui settings demo app: public_api_consumed=true" "$DEMO_SRC"
require_source_line "cjgui settings demo app: public_api_name=cjguiExperimentalBuildSettingsDemoOutput" "$DEMO_SRC"
require_source_line "cjgui settings demo app: public_api_output=" "$DEMO_SRC"

if grep -E 'foreign[[:space:]]+func|cjgui_native_bridge_|public[[:space:]]+(func|class|struct|enum|let|var)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: forbidden runtime/native/public token in settings demo source" >&2
  exit 11
fi

if grep -E 'println\("cjgui settings demo app: (runtime_state_write|renderer_state_write|visibility_published|public_c_abi_added)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: governance stop-line output must stay out of demo app" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: cjpm not found" >&2
  exit 13
fi

KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui settings demo app verification: CJ_GUI_SDKROOT not found" >&2
  exit 14
fi

cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_SETTINGS_DEMO_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_settings_demo"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"

[dependencies]
  cjgui = { path = "$PROBE_API_PACKAGE_DIR" }
CJGUI_SETTINGS_DEMO_TOML
cat > "$PROBE_API_PACKAGE_DIR/cjpm.toml" <<CJGUI_SETTINGS_API_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
CJGUI_SETTINGS_API_TOML
cp "$DEMO_SRC" "$PROBE_PACKAGE_DIR/src/main.cj"
cp "$API_SRC" "$PROBE_API_PACKAGE_DIR/src/runtime_cjgui_experimental_settings_demo_api.cj"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm build --target-dir "$BUILD_DIR/cjpm-target" --skip-script
  if [[ -d "${CANGJIE_HOME:-}/runtime/lib/darwin_x86_64_cjnative" ]]; then
    export DYLD_LIBRARY_PATH="${CANGJIE_HOME}/runtime/lib/darwin_x86_64_cjnative:${DYLD_LIBRARY_PATH:-}"
  fi
  "$BUILD_DIR/cjpm-target/release/bin/main" > "$OUTPUT_LOG"
)

require_output_line "cjgui settings demo app: demo=settings"
require_output_line "cjgui settings demo app: status_before=scaffolded"
require_output_line "cjgui settings demo app: status_after=runnable"
require_output_line "cjgui settings demo app: main_declared=true"
require_output_line "cjgui settings demo app: deterministic_output=true"
require_output_line "cjgui settings demo app: layout=sectioned_form"
require_output_line "cjgui settings demo app: controls=toggle:auto_save,select:theme,text:username"
require_output_line "cjgui settings demo app: interaction=toggle_auto_save,select_theme,update_username,move_focus"
require_output_line "cjgui settings demo app: state_before=autosave=false;theme=light;username=owner;focus=username_field"
require_output_line "cjgui settings demo app: state_after=autosave=true;theme=dark;username=owner-updated;focus=theme_select"
require_output_line "cjgui settings demo app: state_readback=true"
require_output_line "cjgui settings demo app: summary_after=demo=settings;layout=sectioned_form;controls=toggle:auto_save,select:theme,text:username;autosave=true;theme=dark;username=owner-updated;focus=theme_select"
require_output_line "cjgui settings demo app: public_api_consumed=true"
require_output_line "cjgui settings demo app: public_api_name=cjguiExperimentalBuildSettingsDemoOutput"
require_output_line "cjgui settings demo app: public_api_output=layout=sectioned_form;theme=dark;autosave=true;selected=dark;username=owner-updated;focus=theme_select"
require_output_line "cjgui settings demo app: public_api_available=true"

echo "cjgui_settings_demo_app_compiled=true"
echo "cjgui_settings_demo_app_ran=true"
echo "settings_demo_progress_before=scaffolded"
echo "settings_demo_progress_after=runnable"
echo "settings_demo_has_main=true"
echo "settings_demo_deterministic_business_output=true"
echo "settings_non_bool_public_api_consumed=true"
echo "settings_public_api_name=cjguiExperimentalBuildSettingsDemoOutput"
echo "settings_public_api_return=CjguiExperimentalSettingsDemoOutput"
echo "settings_owner_local_write_readback=true"
echo "settings_state_write_scope=SettingsPanelState.autoSaveEnabled,selectedTheme,usernameValue,focusTarget"
echo "settings_runtime_state_write=false"
echo "settings_renderer_state_write=false"
echo "settings_public_c_abi_added=false"
