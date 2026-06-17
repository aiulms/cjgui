#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI FileBrowser demo app.
# Scope: compile and run runtime/cjgui/demo/file_browser_app.cj against temporary packages built from shared demo support sources.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/file_browser_app.cj"
API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_file_browser_demo_api.cj"
SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
OUTPUT_SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj"
UI_STATE_CORE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj"
COMPONENT_ACTION_SESSION_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj"
TMP_DIR="${CJGUI_FILE_BROWSER_DEMO_TMPDIR:-/private/tmp/cjgui-file-browser-demo-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/file-browser-demo-output.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$BUILD_DIR" "$PROBE_PACKAGE_DIR/src" "$PROBE_API_PACKAGE_DIR/src" "$PROBE_API_PACKAGE_DIR/src/demo_support"
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
    echo "cjgui file browser demo app verification: missing source line: $expected" >&2
    exit 10
  fi
}

require_output_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui file browser demo app verification: missing output line: $expected" >&2
    echo "cjgui file browser demo app verification: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 20
  fi
}

if [[ ! -f "$DEMO_SRC" ]]; then
  echo "cjgui file browser demo app verification: missing demo source $DEMO_SRC" >&2
  exit 2
fi

if [[ ! -f "$SUPPORT_SRC" ]]; then
  echo "cjgui file browser demo app verification: missing shared support source $SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$OUTPUT_SUPPORT_SRC" ]]; then
  echo "cjgui file browser demo app verification: missing shared output support source $OUTPUT_SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$UI_STATE_CORE_SRC" ]]; then
  echo "cjgui file browser demo app verification: missing shared UI state core source $UI_STATE_CORE_SRC" >&2
  exit 2
fi

if [[ ! -f "$COMPONENT_ACTION_SESSION_SRC" ]]; then
  echo "cjgui file browser demo app verification: missing shared component action session source $COMPONENT_ACTION_SESSION_SRC" >&2
  exit 2
fi

require_source_line "public class CjguiExperimentalDemoInteractionTrace" "$SUPPORT_SRC"
require_source_line "public func recordAction" "$SUPPORT_SRC"
require_source_line "public class CjguiExperimentalDemoOutput" "$OUTPUT_SUPPORT_SRC"
require_source_line "public class CjguiExperimentalDemoOutputBuilder" "$OUTPUT_SUPPORT_SRC"
require_source_line "public func buildFromTrace" "$OUTPUT_SUPPORT_SRC"
require_source_line "public class CjguiExperimentalDemoUiStateCore" "$UI_STATE_CORE_SRC"
require_source_line "public func applyStyle" "$UI_STATE_CORE_SRC"
require_source_line "public func typeInput" "$UI_STATE_CORE_SRC"
require_source_line "public func moveFocus" "$UI_STATE_CORE_SRC"
require_source_line "public class CjguiExperimentalDemoComponentActionSession" "$COMPONENT_ACTION_SESSION_SRC"
require_source_line "public func recordComponentAction" "$COMPONENT_ACTION_SESSION_SRC"
require_source_line "public func buildOutput" "$COMPONENT_ACTION_SESSION_SRC"
require_source_line "package cjgui_file_browser_demo" "$DEMO_SRC"
require_source_line "import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}" "$DEMO_SRC"
require_source_line "class FileBrowserState" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoComponentActionSession" "$DEMO_SRC"
require_source_line "private var entries" "$DEMO_SRC"
require_source_line "var selectedPath: String" "$DEMO_SRC"
require_source_line "var expandedPath: String" "$DEMO_SRC"
require_source_line "sharedUiState()" "$DEMO_SRC"
require_source_line "main(): Int64" "$DEMO_SRC"
require_source_line "componentSession.recordComponentAction" "$DEMO_SRC"
require_source_line "sharedComponentActions()" "$DEMO_SRC"
require_source_line "buildSharedOutput" "$DEMO_SRC"
require_source_line "cjgui file browser demo app: status_before=not_started" "$DEMO_SRC"
require_source_line "cjgui file browser demo app: status_after=runnable" "$DEMO_SRC"
require_source_line "cjgui file browser demo app: state_before=" "$DEMO_SRC"
require_source_line "cjgui file browser demo app: state_after=" "$DEMO_SRC"
require_source_line "cjgui file browser demo app: state_readback=" "$DEMO_SRC"
require_source_line "cjgui file browser demo app: public_api_consumed=true" "$DEMO_SRC"
require_source_line "cjgui file browser demo app: public_api_name=CjguiExperimentalDemoComponentActionSession" "$DEMO_SRC"
require_source_line "cjgui file browser demo app: public_api_output=" "$DEMO_SRC"

if grep -F "cjguiExperimentalBuildFileBrowserDemoOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "CjguiExperimentalFileBrowserDemoOutput" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui file browser demo app verification: demo must not directly consume legacy FileBrowser output API" >&2
  exit 10
fi

if grep -E 'foreign[[:space:]]+func|cjgui_native_bridge_|public[[:space:]]+(func|class|struct|enum|let|var)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui file browser demo app verification: forbidden runtime/native/public token in file browser demo source" >&2
  exit 11
fi

if grep -E 'println\("cjgui file browser demo app: (runtime_state_write|renderer_state_write|visibility_published|public_c_abi_added)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui file browser demo app verification: governance stop-line output must stay out of demo app" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui file browser demo app verification: cjpm not found" >&2
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
  echo "cjgui file browser demo app verification: CJ_GUI_SDKROOT not found" >&2
  exit 14
fi

cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_FILE_BROWSER_DEMO_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_file_browser_demo"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"

[dependencies]
  cjgui = { path = "$PROBE_API_PACKAGE_DIR" }
CJGUI_FILE_BROWSER_DEMO_TOML
cat > "$PROBE_API_PACKAGE_DIR/cjpm.toml" <<CJGUI_FILE_BROWSER_API_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
CJGUI_FILE_BROWSER_API_TOML
cp "$DEMO_SRC" "$PROBE_PACKAGE_DIR/src/main.cj"
cp "$SUPPORT_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
cp "$OUTPUT_SUPPORT_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj"
cp "$UI_STATE_CORE_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj"
cp "$COMPONENT_ACTION_SESSION_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm build --target-dir "$BUILD_DIR/cjpm-target" --skip-script
  if [[ -d "${CANGJIE_HOME:-}/runtime/lib/darwin_x86_64_cjnative" ]]; then
    export DYLD_LIBRARY_PATH="${CANGJIE_HOME}/runtime/lib/darwin_x86_64_cjnative:${DYLD_LIBRARY_PATH:-}"
  fi
  "$BUILD_DIR/cjpm-target/release/bin/main" > "$OUTPUT_LOG"
)

require_output_line "cjgui file browser demo app: demo=file_browser"
require_output_line "cjgui file browser demo app: status_before=not_started"
require_output_line "cjgui file browser demo app: status_after=runnable"
require_output_line "cjgui file browser demo app: layout=tree_detail_split"
require_output_line "cjgui file browser demo app: interaction=expand_folder,filter_entries,select_file,refresh_detail,move_focus"
require_output_line "cjgui file browser demo app: state_before=items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree"
require_output_line "cjgui file browser demo app: state_after=items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane"
require_output_line "cjgui file browser demo app: state_readback=true"
require_output_line "cjgui file browser demo app: public_api_consumed=true"
require_output_line "cjgui file browser demo app: public_api_name=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui file browser demo app: public_api_output=demo=file_browser;readback=true;writes=5;actions=file_browser.expand_folder,file_browser.filter_entries,file_browser.select_file,file_browser.refresh_detail,file_browser.move_focus;before=items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree;after=items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane;summary=demo=file_browser;layout=tree_detail_split;items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane"
require_output_line "cjgui file browser demo app: shared_support=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui file browser demo app: shared_support_output=demo=file_browser;writes=5;actions=file_browser.expand_folder,file_browser.filter_entries,file_browser.select_file,file_browser.refresh_detail,file_browser.move_focus;before=items=3;expanded=/workspace;selected=/workspace:folder;detail=workspace;filter=;focus=tree;after=items=3;expanded=/workspace/src;selected=/workspace/src/main.cj:file;detail=main.cj;filter=main;focus=detail_pane"
require_output_line "cjgui file browser demo app: shared_state_core=layout=tree_detail_split;style=detail_ready;input=main;focus=detail_pane"
require_output_line "cjgui file browser demo app: shared_component_action_model=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui file browser demo app: shared_component_action_output=demo=file_browser;component_actions=folder_tree:file_browser.expand_folder,tree_filter:file_browser.filter_entries,file_row:file_browser.select_file,detail_pane:file_browser.refresh_detail,detail_pane:file_browser.move_focus;ui=layout=tree_detail_split;style=detail_ready;input=main;focus=detail_pane"

echo "cjgui_file_browser_demo_app_compiled=true"
echo "cjgui_file_browser_demo_app_ran=true"
echo "file_browser_demo_progress_before=not_started"
echo "file_browser_demo_progress_after=runnable"
echo "file_browser_demo_has_main=true"
echo "file_browser_demo_deterministic_business_output=true"
echo "file_browser_non_bool_public_api_consumed=true"
echo "file_browser_public_api_name=CjguiExperimentalDemoComponentActionSession"
echo "file_browser_public_api_return=CjguiExperimentalDemoOutput"
echo "file_browser_legacy_output_api_direct_consumption=false"
echo "file_browser_owner_local_write_readback=true"
echo "file_browser_state_write_scope=FileBrowserState.entries,selectedPath,selectedKind,detailTitle,detailPreview,expandedPath,componentSession"
echo "file_browser_shared_support_imported=true"
echo "file_browser_shared_support_name=CjguiExperimentalDemoComponentActionSession"
echo "file_browser_shared_state_core_imported=true"
echo "file_browser_shared_state_core_name=CjguiExperimentalDemoUiStateCore"
echo "file_browser_shared_component_action_session_imported=true"
echo "file_browser_shared_component_action_session_name=CjguiExperimentalDemoComponentActionSession"
echo "file_browser_runtime_state_write=false"
echo "file_browser_renderer_state_write=false"
echo "file_browser_public_c_abi_added=false"
