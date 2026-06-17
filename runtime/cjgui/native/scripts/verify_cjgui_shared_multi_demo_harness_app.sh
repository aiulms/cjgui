#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI shared multi-demo harness app.
# Scope: compile and run runtime/cjgui/demo/shared_multi_demo_harness_app.cj against temporary packages built from shared demo support sources.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/shared_multi_demo_harness_app.cj"
API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_shared_multi_demo_harness_api.cj"
SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
OUTPUT_SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj"
UI_STATE_CORE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj"
TMP_DIR="${CJGUI_SHARED_MULTI_DEMO_HARNESS_TMPDIR:-/private/tmp/cjgui-shared-multi-demo-harness-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/shared-multi-demo-harness-output.log"

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
    echo "cjgui shared multi-demo harness app verification: missing source line: $expected" >&2
    exit 10
  fi
}

require_output_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui shared multi-demo harness app verification: missing output line: $expected" >&2
    echo "cjgui shared multi-demo harness app verification: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 20
  fi
}

if [[ ! -f "$DEMO_SRC" ]]; then
  echo "cjgui shared multi-demo harness app verification: missing demo source $DEMO_SRC" >&2
  exit 2
fi

if [[ ! -f "$SUPPORT_SRC" ]]; then
  echo "cjgui shared multi-demo harness app verification: missing shared support source $SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$OUTPUT_SUPPORT_SRC" ]]; then
  echo "cjgui shared multi-demo harness app verification: missing shared output support source $OUTPUT_SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$UI_STATE_CORE_SRC" ]]; then
  echo "cjgui shared multi-demo harness app verification: missing shared UI state core source $UI_STATE_CORE_SRC" >&2
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
require_source_line "package cjgui_shared_multi_demo_harness_demo" "$DEMO_SRC"
require_source_line "import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder, CjguiExperimentalDemoUiStateCore}" "$DEMO_SRC"
require_source_line "class SharedMultiDemoHarnessState" "$DEMO_SRC"
require_source_line "var servedDemos: String" "$DEMO_SRC"
require_source_line "var todoItemCount: Int64" "$DEMO_SRC"
require_source_line "var fileSelectedPath: String" "$DEMO_SRC"
require_source_line "let uiState: CjguiExperimentalDemoUiStateCore" "$DEMO_SRC"
require_source_line "var focusRoute: String" "$DEMO_SRC"
require_source_line "var styleRoute: String" "$DEMO_SRC"
require_source_line "sharedUiState()" "$DEMO_SRC"
require_source_line "main(): Int64" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoInteractionTrace" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoOutputBuilder" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoUiStateCore" "$DEMO_SRC"
require_source_line "sharedTrace.recordAction" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: status_before=not_started" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: status_after=runnable" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: served_demos=todo,file_browser" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: state_before=" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: state_after=" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: state_readback=" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: public_api_consumed=true" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: public_api_name=CjguiExperimentalDemoOutputBuilder" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: public_api_output=" "$DEMO_SRC"
require_source_line "cjgui shared multi-demo harness app: shared_support=CjguiExperimentalDemoInteractionTrace" "$DEMO_SRC"

if grep -F "cjguiExperimentalBuildSharedMultiDemoHarnessOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "CjguiExperimentalSharedMultiDemoHarnessOutput" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui shared multi-demo harness app verification: demo must not directly consume legacy shared multi-demo harness output API" >&2
  exit 10
fi

if grep -E 'foreign[[:space:]]+func|cjgui_native_bridge_|public[[:space:]]+(func|class|struct|enum|let|var)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui shared multi-demo harness app verification: forbidden runtime/native/public token in shared multi-demo harness demo source" >&2
  exit 11
fi

if grep -E 'println\("cjgui shared multi-demo harness app: (runtime_state_write|renderer_state_write|visibility_published|public_c_abi_added)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui shared multi-demo harness app verification: governance stop-line output must stay out of demo app" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui shared multi-demo harness app verification: cjpm not found" >&2
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
  echo "cjgui shared multi-demo harness app verification: CJ_GUI_SDKROOT not found" >&2
  exit 14
fi

cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_SHARED_MULTI_DEMO_HARNESS_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_shared_multi_demo_harness_demo"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"

[dependencies]
  cjgui = { path = "$PROBE_API_PACKAGE_DIR" }
CJGUI_SHARED_MULTI_DEMO_HARNESS_TOML
cat > "$PROBE_API_PACKAGE_DIR/cjpm.toml" <<CJGUI_SHARED_MULTI_DEMO_HARNESS_API_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
CJGUI_SHARED_MULTI_DEMO_HARNESS_API_TOML
cp "$DEMO_SRC" "$PROBE_PACKAGE_DIR/src/main.cj"
cp "$SUPPORT_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
cp "$OUTPUT_SUPPORT_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj"
cp "$UI_STATE_CORE_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm build --target-dir "$BUILD_DIR/cjpm-target" --skip-script
  if [[ -d "${CANGJIE_HOME:-}/runtime/lib/darwin_x86_64_cjnative" ]]; then
    export DYLD_LIBRARY_PATH="${CANGJIE_HOME}/runtime/lib/darwin_x86_64_cjnative:${DYLD_LIBRARY_PATH:-}"
  fi
  "$BUILD_DIR/cjpm-target/release/bin/main" > "$OUTPUT_LOG"
)

require_output_line "cjgui shared multi-demo harness app: demo=shared_multi_demo_harness"
require_output_line "cjgui shared multi-demo harness app: status_before=not_started"
require_output_line "cjgui shared multi-demo harness app: status_after=runnable"
require_output_line "cjgui shared multi-demo harness app: served_demos=todo,file_browser"
require_output_line "cjgui shared multi-demo harness app: served_demo_count=2"
require_output_line "cjgui shared multi-demo harness app: interaction=run_todo_add_complete,run_file_browser_select"
require_output_line "cjgui shared multi-demo harness app: state_before=todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list"
require_output_line "cjgui shared multi-demo harness app: state_after=todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent"
require_output_line "cjgui shared multi-demo harness app: state_readback=true"
require_output_line "cjgui shared multi-demo harness app: public_api_consumed=true"
require_output_line "cjgui shared multi-demo harness app: public_api_name=CjguiExperimentalDemoOutputBuilder"
require_output_line "cjgui shared multi-demo harness app: public_api_output=demo=shared_multi_demo_harness;readback=true;writes=6;actions=shared_multi_demo_harness.todo_add,shared_multi_demo_harness.todo_complete,shared_multi_demo_harness.file_expand,shared_multi_demo_harness.file_filter,shared_multi_demo_harness.file_select,shared_multi_demo_harness.file_focus;before=todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list;after=todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent;summary=harness=shared_multi_demo_harness;served_count=2;served=todo,file_browser;actions=6;focus_route=todo_input->todo_first_item->todo_first_item->file_tree->file_filter->file_detail_pane->file_detail_pane;style_route=neutral_list->todo_active_list->todo_completed_accent->split_detail_accent"
require_output_line "cjgui shared multi-demo harness app: shared_support=CjguiExperimentalDemoInteractionTrace"
require_output_line "cjgui shared multi-demo harness app: shared_support_output=demo=shared_multi_demo_harness;writes=6;actions=shared_multi_demo_harness.todo_add,shared_multi_demo_harness.todo_complete,shared_multi_demo_harness.file_expand,shared_multi_demo_harness.file_filter,shared_multi_demo_harness.file_select,shared_multi_demo_harness.file_focus;before=todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list;after=todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent"
require_output_line "cjgui shared multi-demo harness app: shared_state_core=layout=multi_demo_harness;style=split_detail_accent;input=main;focus=file_detail_pane"

echo "cjgui_shared_multi_demo_harness_app_compiled=true"
echo "cjgui_shared_multi_demo_harness_app_ran=true"
echo "shared_multi_demo_harness_progress_before=not_started"
echo "shared_multi_demo_harness_progress_after=runnable"
echo "shared_multi_demo_harness_served_demos=todo,file_browser"
echo "shared_multi_demo_harness_served_demo_count=2"
echo "shared_multi_demo_harness_has_main=true"
echo "shared_multi_demo_harness_deterministic_business_output=true"
echo "shared_multi_demo_harness_non_bool_public_api_consumed=true"
echo "shared_multi_demo_harness_public_api_name=CjguiExperimentalDemoOutputBuilder"
echo "shared_multi_demo_harness_public_api_return=CjguiExperimentalDemoOutput"
echo "shared_multi_demo_harness_legacy_output_api_direct_consumption=false"
echo "shared_multi_demo_harness_owner_local_write_readback=true"
echo "shared_multi_demo_harness_state_write_scope=SharedMultiDemoHarnessState.servedDemoCount,servedDemos,actionCount,todoItemCount,todoFirstTitle,todoFirstDone,fileExpandedPath,fileSelectedPath,fileSelectedKind,fileDetailTitle,fileFilterText,uiState,focusRoute,styleRoute"
echo "shared_multi_demo_harness_shared_support_imported=true"
echo "shared_multi_demo_harness_shared_support_name=CjguiExperimentalDemoInteractionTrace"
echo "shared_multi_demo_harness_shared_state_core_imported=true"
echo "shared_multi_demo_harness_shared_state_core_name=CjguiExperimentalDemoUiStateCore"
echo "shared_multi_demo_harness_runtime_state_write=false"
echo "shared_multi_demo_harness_renderer_state_write=false"
echo "shared_multi_demo_harness_public_c_abi_added=false"
