#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI AI-generated UI demo app.
# Scope: compile and run runtime/cjgui/demo/ai_generated_ui_app.cj against a temporary package built from the production AI-generated UI demo API source.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/ai_generated_ui_app.cj"
API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_ai_generated_ui_demo_api.cj"
TMP_DIR="${CJGUI_AI_GENERATED_UI_DEMO_TMPDIR:-/private/tmp/cjgui-ai-generated-ui-demo-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/ai-generated-ui-demo-output.log"

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
    echo "cjgui ai generated ui demo app verification: missing source line: $expected" >&2
    exit 10
  fi
}

require_output_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui ai generated ui demo app verification: missing output line: $expected" >&2
    echo "cjgui ai generated ui demo app verification: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 20
  fi
}

if [[ ! -f "$DEMO_SRC" ]]; then
  echo "cjgui ai generated ui demo app verification: missing demo source $DEMO_SRC" >&2
  exit 2
fi

if [[ ! -f "$API_SRC" ]]; then
  echo "cjgui ai generated ui demo app verification: missing API source $API_SRC" >&2
  exit 2
fi

require_source_line "public class CjguiExperimentalAiGeneratedUiDemoOutput" "$API_SRC"
require_source_line "public func cjguiExperimentalBuildAiGeneratedUiDemoOutput" "$API_SRC"
require_source_line "public let acceptedScreen: String" "$API_SRC"
require_source_line "public let summary: String" "$API_SRC"
require_source_line "package cjgui_ai_generated_ui_demo" "$DEMO_SRC"
require_source_line "import cjgui.*" "$DEMO_SRC"
require_source_line "class AiGeneratedUiState" "$DEMO_SRC"
require_source_line "private var componentIds" "$DEMO_SRC"
require_source_line "var accepted: Bool" "$DEMO_SRC"
require_source_line "var acceptedScreen: String" "$DEMO_SRC"
require_source_line "var focusTarget: String" "$DEMO_SRC"
require_source_line "main(): Int64" "$DEMO_SRC"
require_source_line "CjguiExperimentalAiGeneratedUiDemoOutput" "$DEMO_SRC"
require_source_line "cjguiExperimentalBuildAiGeneratedUiDemoOutput" "$DEMO_SRC"
require_source_line "cjgui ai generated ui demo app: status_before=not_started" "$DEMO_SRC"
require_source_line "cjgui ai generated ui demo app: status_after=runnable" "$DEMO_SRC"
require_source_line "cjgui ai generated ui demo app: state_before=" "$DEMO_SRC"
require_source_line "cjgui ai generated ui demo app: state_after=" "$DEMO_SRC"
require_source_line "cjgui ai generated ui demo app: state_readback=" "$DEMO_SRC"
require_source_line "cjgui ai generated ui demo app: public_api_consumed=true" "$DEMO_SRC"
require_source_line "cjgui ai generated ui demo app: public_api_name=cjguiExperimentalBuildAiGeneratedUiDemoOutput" "$DEMO_SRC"
require_source_line "cjgui ai generated ui demo app: public_api_output=" "$DEMO_SRC"

if grep -E 'foreign[[:space:]]+func|cjgui_native_bridge_|public[[:space:]]+(func|class|struct|enum|let|var)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui ai generated ui demo app verification: forbidden runtime/native/public token in ai generated ui demo source" >&2
  exit 11
fi

if grep -E 'println\("cjgui ai generated ui demo app: (runtime_state_write|renderer_state_write|visibility_published|public_c_abi_added)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui ai generated ui demo app verification: governance stop-line output must stay out of demo app" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui ai generated ui demo app verification: cjpm not found" >&2
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
  echo "cjgui ai generated ui demo app verification: CJ_GUI_SDKROOT not found" >&2
  exit 14
fi

cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_AI_GENERATED_UI_DEMO_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_ai_generated_ui_demo"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"

[dependencies]
  cjgui = { path = "$PROBE_API_PACKAGE_DIR" }
CJGUI_AI_GENERATED_UI_DEMO_TOML
cat > "$PROBE_API_PACKAGE_DIR/cjpm.toml" <<CJGUI_AI_GENERATED_UI_API_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
CJGUI_AI_GENERATED_UI_API_TOML
cp "$DEMO_SRC" "$PROBE_PACKAGE_DIR/src/main.cj"
cp "$API_SRC" "$PROBE_API_PACKAGE_DIR/src/runtime_cjgui_experimental_ai_generated_ui_demo_api.cj"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm build --target-dir "$BUILD_DIR/cjpm-target" --skip-script
  if [[ -d "${CANGJIE_HOME:-}/runtime/lib/darwin_x86_64_cjnative" ]]; then
    export DYLD_LIBRARY_PATH="${CANGJIE_HOME}/runtime/lib/darwin_x86_64_cjnative:${DYLD_LIBRARY_PATH:-}"
  fi
  "$BUILD_DIR/cjpm-target/release/bin/main" > "$OUTPUT_LOG"
)

require_output_line "cjgui ai generated ui demo app: demo=ai_generated_ui"
require_output_line "cjgui ai generated ui demo app: status_before=not_started"
require_output_line "cjgui ai generated ui demo app: status_after=runnable"
require_output_line "cjgui ai generated ui demo app: layout=ai_form_preview"
require_output_line "cjgui ai generated ui demo app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus"
require_output_line "cjgui ai generated ui demo app: state_before=components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe"
require_output_line "cjgui ai generated ui demo app: state_after=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel"
require_output_line "cjgui ai generated ui demo app: state_readback=true"
require_output_line "cjgui ai generated ui demo app: public_api_consumed=true"
require_output_line "cjgui ai generated ui demo app: public_api_name=cjguiExperimentalBuildAiGeneratedUiDemoOutput"
require_output_line "cjgui ai generated ui demo app: public_api_output=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;focus=save_button;layout=ai_form_preview;style=sage_panel"

echo "cjgui_ai_generated_ui_demo_app_compiled=true"
echo "cjgui_ai_generated_ui_demo_app_ran=true"
echo "ai_generated_ui_demo_progress_before=not_started"
echo "ai_generated_ui_demo_progress_after=runnable"
echo "ai_generated_ui_demo_has_main=true"
echo "ai_generated_ui_demo_deterministic_business_output=true"
echo "ai_generated_ui_non_bool_public_api_consumed=true"
echo "ai_generated_ui_public_api_name=cjguiExperimentalBuildAiGeneratedUiDemoOutput"
echo "ai_generated_ui_public_api_return=CjguiExperimentalAiGeneratedUiDemoOutput"
echo "ai_generated_ui_owner_local_write_readback=true"
echo "ai_generated_ui_state_write_scope=AiGeneratedUiState.componentIds,accepted,acceptedScreen,diffSummary,explainText,focusTarget,styleToken"
echo "ai_generated_ui_runtime_state_write=false"
echo "ai_generated_ui_renderer_state_write=false"
echo "ai_generated_ui_public_c_abi_added=false"
