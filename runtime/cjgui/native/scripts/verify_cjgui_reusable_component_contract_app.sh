#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI reusable component contract app.
# Scope: compile and run runtime/cjgui/demo/reusable_component_contract_app.cj against temporary cjgui API sources.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/reusable_component_contract_app.cj"
CONTRACT_API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_reusable_component_contract_api.cj"
TMP_DIR="${CJGUI_REUSABLE_COMPONENT_CONTRACT_TMPDIR:-/private/tmp/cjgui-reusable-component-contract-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/reusable-component-contract-output.log"

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
    echo "cjgui reusable component contract app verification: missing source line: $expected" >&2
    exit 10
  fi
}

require_output_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui reusable component contract app verification: missing output line: $expected" >&2
    echo "cjgui reusable component contract app verification: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 20
  fi
}

for source_file in "$DEMO_SRC" "$CONTRACT_API_SRC"; do
  if [[ ! -f "$source_file" ]]; then
    echo "cjgui reusable component contract app verification: missing source $source_file" >&2
    exit 2
  fi
done

require_source_line "public class CjguiExperimentalReusableComponentContractOutput" "$CONTRACT_API_SRC"
require_source_line "public func cjguiExperimentalBuildReusableComponentContractOutput" "$CONTRACT_API_SRC"
require_source_line "public let componentKinds: String" "$CONTRACT_API_SRC"
require_source_line "public let reusedDemoCount: Int64" "$CONTRACT_API_SRC"
require_source_line "public let beforeState: String" "$CONTRACT_API_SRC"
require_source_line "public let afterState: String" "$CONTRACT_API_SRC"
require_source_line "package cjgui_reusable_component_contract_demo" "$DEMO_SRC"
require_source_line "import cjgui.*" "$DEMO_SRC"
require_source_line "class ReusableComponentContractState" "$DEMO_SRC"
require_source_line "var componentCount: Int64" "$DEMO_SRC"
require_source_line "var componentKinds: String" "$DEMO_SRC"
require_source_line "var reusedDemoCount: Int64" "$DEMO_SRC"
require_source_line "var actionTrace: String" "$DEMO_SRC"
require_source_line "func runTodoAdd" "$DEMO_SRC"
require_source_line "func runFileSelect" "$DEMO_SRC"
require_source_line "func runAiAccept" "$DEMO_SRC"
require_source_line "main(): Int64" "$DEMO_SRC"
require_source_line "CjguiExperimentalReusableComponentContractOutput" "$DEMO_SRC"
require_source_line "cjguiExperimentalBuildReusableComponentContractOutput" "$DEMO_SRC"
require_source_line "cjgui reusable component contract app: status_before=not_started" "$DEMO_SRC"
require_source_line "cjgui reusable component contract app: status_after=runnable" "$DEMO_SRC"
require_source_line "cjgui reusable component contract app: state_before=" "$DEMO_SRC"
require_source_line "cjgui reusable component contract app: state_after=" "$DEMO_SRC"
require_source_line "cjgui reusable component contract app: state_readback=" "$DEMO_SRC"
require_source_line "cjgui reusable component contract app: public_api_consumed=true" "$DEMO_SRC"
require_source_line "cjgui reusable component contract app: public_api_name=cjguiExperimentalBuildReusableComponentContractOutput" "$DEMO_SRC"
require_source_line "cjgui reusable component contract app: public_api_output=" "$DEMO_SRC"

if grep -E 'foreign[[:space:]]+func|cjgui_native_bridge_|public[[:space:]]+(func|class|struct|enum|let|var)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui reusable component contract app verification: forbidden runtime/native/public token in demo source" >&2
  exit 11
fi

if grep -E 'println\("cjgui reusable component contract app: (runtime_state_write|renderer_state_write|visibility_published|public_c_abi_added)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui reusable component contract app verification: governance stop-line output must stay out of demo app" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui reusable component contract app verification: cjpm not found" >&2
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
  echo "cjgui reusable component contract app verification: CJ_GUI_SDKROOT not found" >&2
  exit 14
fi

cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_REUSABLE_COMPONENT_CONTRACT_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_reusable_component_contract_demo"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"

[dependencies]
  cjgui = { path = "$PROBE_API_PACKAGE_DIR" }
CJGUI_REUSABLE_COMPONENT_CONTRACT_TOML
cat > "$PROBE_API_PACKAGE_DIR/cjpm.toml" <<CJGUI_REUSABLE_COMPONENT_CONTRACT_API_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
CJGUI_REUSABLE_COMPONENT_CONTRACT_API_TOML
cp "$DEMO_SRC" "$PROBE_PACKAGE_DIR/src/main.cj"
cp "$CONTRACT_API_SRC" "$PROBE_API_PACKAGE_DIR/src/runtime_cjgui_experimental_reusable_component_contract_api.cj"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm build --target-dir "$BUILD_DIR/cjpm-target" --skip-script
  if [[ -d "${CANGJIE_HOME:-}/runtime/lib/darwin_x86_64_cjnative" ]]; then
    export DYLD_LIBRARY_PATH="${CANGJIE_HOME}/runtime/lib/darwin_x86_64_cjnative:${DYLD_LIBRARY_PATH:-}"
  fi
  "$BUILD_DIR/cjpm-target/release/bin/main" > "$OUTPUT_LOG"
)

require_output_line "cjgui reusable component contract app: demo=reusable_component_contract"
require_output_line "cjgui reusable component contract app: status_before=not_started"
require_output_line "cjgui reusable component contract app: status_after=runnable"
require_output_line "cjgui reusable component contract app: reused_demos=todo,file_browser,ai_generated_ui"
require_output_line "cjgui reusable component contract app: component_kinds=task_row,file_row,ai_form"
require_output_line "cjgui reusable component contract app: interaction=register_file_row,register_ai_form,todo_add,file_select,ai_accept"
require_output_line "cjgui reusable component contract app: state_before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input"
require_output_line "cjgui reusable component contract app: state_after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button"
require_output_line "cjgui reusable component contract app: state_readback=true"
require_output_line "cjgui reusable component contract app: public_api_consumed=true"
require_output_line "cjgui reusable component contract app: public_api_name=cjguiExperimentalBuildReusableComponentContractOutput"
require_output_line "cjgui reusable component contract app: public_api_output=contract=reusable_component_contract;components=task_row,file_row,ai_form;reused_count=3;reused=todo,file_browser,ai_generated_ui;component_count=3;before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button;actions=register_file_row,register_ai_form,todo_add,file_select,ai_accept;layout=single_column->split_detail;style=neutral_list->sage_panel;input=<empty>->filter:src,username;focus=todo_input->save_button;readback=true"

echo "cjgui_reusable_component_contract_app_compiled=true"
echo "cjgui_reusable_component_contract_app_ran=true"
echo "reusable_component_contract_progress_before=not_started"
echo "reusable_component_contract_progress_after=runnable"
echo "reusable_component_contract_has_main=true"
echo "reusable_component_contract_deterministic_business_output=true"
echo "reusable_component_contract_non_bool_public_api_consumed=true"
echo "reusable_component_contract_public_api_name=cjguiExperimentalBuildReusableComponentContractOutput"
echo "reusable_component_contract_public_api_return=CjguiExperimentalReusableComponentContractOutput"
echo "reusable_component_contract_owner_local_write_readback=true"
echo "reusable_component_contract_state_write_scope=ReusableComponentContractState.componentCount,componentKinds,reusedDemoCount,reusedDemos,actionTrace,todoTitle,fileSelection,aiAcceptedScreen,layoutMode,styleToken,inputText,focusTarget"
echo "reusable_component_contract_runtime_state_write=false"
echo "reusable_component_contract_renderer_state_write=false"
echo "reusable_component_contract_public_c_abi_added=false"
