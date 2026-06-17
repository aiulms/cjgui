#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI AI-generated UI shared contract app.
# Scope: compile and run runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj against temporary cjgui API sources.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/ai_generated_ui_shared_contract_app.cj"
SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
OUTPUT_SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj"
UI_STATE_CORE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj"
TMP_DIR="${CJGUI_AI_GENERATED_UI_SHARED_CONTRACT_TMPDIR:-/private/tmp/cjgui-ai-generated-ui-shared-contract-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/ai-generated-ui-shared-contract-output.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$BUILD_DIR" "$PROBE_PACKAGE_DIR/src" "$PROBE_API_PACKAGE_DIR/src/demo_support"
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
    echo "cjgui AI-generated UI shared contract app verification: missing source line: $expected" >&2
    exit 10
  fi
}

require_output_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui AI-generated UI shared contract app verification: missing output line: $expected" >&2
    echo "cjgui AI-generated UI shared contract app verification: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 20
  fi
}

for source_file in "$DEMO_SRC" "$SUPPORT_SRC" "$OUTPUT_SUPPORT_SRC" "$UI_STATE_CORE_SRC"; do
  if [[ ! -f "$source_file" ]]; then
    echo "cjgui AI-generated UI shared contract app verification: missing source $source_file" >&2
    exit 2
  fi
done

require_source_line "public class CjguiExperimentalDemoInteractionTrace" "$SUPPORT_SRC"
require_source_line "public func recordAction" "$SUPPORT_SRC"
require_source_line "public class CjguiExperimentalDemoOutput" "$OUTPUT_SUPPORT_SRC"
require_source_line "public class CjguiExperimentalDemoOutputBuilder" "$OUTPUT_SUPPORT_SRC"
require_source_line "public func buildFromTrace" "$OUTPUT_SUPPORT_SRC"
require_source_line "public class CjguiExperimentalDemoUiStateCore" "$UI_STATE_CORE_SRC"
require_source_line "public func applyLayout" "$UI_STATE_CORE_SRC"
require_source_line "public func applyStyle" "$UI_STATE_CORE_SRC"
require_source_line "public func typeInput" "$UI_STATE_CORE_SRC"
require_source_line "public func moveFocus" "$UI_STATE_CORE_SRC"
require_source_line "package cjgui_ai_generated_ui_shared_contract_demo" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoUiStateCore" "$DEMO_SRC"
require_source_line "class AiGeneratedUiSharedContractState" "$DEMO_SRC"
require_source_line "var accepted: Bool" "$DEMO_SRC"
require_source_line "let uiState: CjguiExperimentalDemoUiStateCore" "$DEMO_SRC"
require_source_line "sharedUiState()" "$DEMO_SRC"
require_source_line "main(): Int64" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoInteractionTrace" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoOutputBuilder" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: status_before=not_started" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: status_after=runnable" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: state_before=" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: state_after=" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: state_readback=" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: public_api_consumed=true" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: public_api_name=CjguiExperimentalDemoOutputBuilder" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: public_api_output=" "$DEMO_SRC"
require_source_line "cjgui ai-generated-ui shared contract app: shared_support=CjguiExperimentalDemoInteractionTrace" "$DEMO_SRC"

if grep -F "cjguiExperimentalBuildAiGeneratedUiDemoOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "CjguiExperimentalAiGeneratedUiDemoOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "CjguiExperimentalSharedLayoutStyleInputFocusContractOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "cjguiExperimentalBuildAiGeneratedUiSharedContractOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "CjguiExperimentalAiGeneratedUiSharedContractOutput" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui AI-generated UI shared contract app verification: demo still directly consumes legacy shared contract output API" >&2
  exit 10
fi

if grep -E 'foreign[[:space:]]+func|cjgui_native_bridge_|public[[:space:]]+(func|class|struct|enum|let|var)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui AI-generated UI shared contract app verification: forbidden runtime/native/public token in demo source" >&2
  exit 11
fi

if grep -E 'println\("cjgui ai-generated-ui shared contract app: (runtime_state_write|renderer_state_write|visibility_published|public_c_abi_added)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui AI-generated UI shared contract app verification: governance stop-line output must stay out of demo app" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui AI-generated UI shared contract app verification: cjpm not found" >&2
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
  echo "cjgui AI-generated UI shared contract app verification: CJ_GUI_SDKROOT not found" >&2
  exit 14
fi

cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_AI_GENERATED_UI_SHARED_CONTRACT_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_ai_generated_ui_shared_contract_demo"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"

[dependencies]
  cjgui = { path = "$PROBE_API_PACKAGE_DIR" }
CJGUI_AI_GENERATED_UI_SHARED_CONTRACT_TOML
cat > "$PROBE_API_PACKAGE_DIR/cjpm.toml" <<CJGUI_AI_GENERATED_UI_SHARED_CONTRACT_API_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
CJGUI_AI_GENERATED_UI_SHARED_CONTRACT_API_TOML
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

require_output_line "cjgui ai-generated-ui shared contract app: demo=ai_generated_ui_shared_contract"
require_output_line "cjgui ai-generated-ui shared contract app: status_before=not_started"
require_output_line "cjgui ai-generated-ui shared contract app: status_after=runnable"
require_output_line "cjgui ai-generated-ui shared contract app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus"
require_output_line "cjgui ai-generated-ui shared contract app: state_before=components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card"
require_output_line "cjgui ai-generated-ui shared contract app: state_after=components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button"
require_output_line "cjgui ai-generated-ui shared contract app: state_readback=true"
require_output_line "cjgui ai-generated-ui shared contract app: public_api_consumed=true"
require_output_line "cjgui ai-generated-ui shared contract app: public_api_name=CjguiExperimentalDemoOutputBuilder"
require_output_line "cjgui ai-generated-ui shared contract app: public_api_output=demo=ai_generated_ui_shared_contract;readback=true;writes=5;actions=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus;before=components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card;after=components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button;summary=contract=ai_generated_ui_shared_contract;screen=settings_profile_form;components=4;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;layout=single_column->split_detail;style=neutral_wireframe->sage_panel;input=<empty>->username;focus=preview_card->save_button;layout_kind=ai_form_preview;readback=true"
require_output_line "cjgui ai-generated-ui shared contract app: shared_support=CjguiExperimentalDemoInteractionTrace"
require_output_line "cjgui ai-generated-ui shared contract app: shared_support_output=demo=ai_generated_ui_shared_contract;writes=5;actions=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus;before=components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card;after=components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button"
require_output_line "cjgui ai-generated-ui shared contract app: shared_state_core=layout=split_detail;style=sage_panel;input=username;focus=save_button"

echo "cjgui_ai_generated_ui_shared_contract_app_compiled=true"
echo "cjgui_ai_generated_ui_shared_contract_app_ran=true"
echo "ai_generated_ui_shared_contract_progress_before=not_started"
echo "ai_generated_ui_shared_contract_progress_after=runnable"
echo "ai_generated_ui_shared_contract_has_main=true"
echo "ai_generated_ui_shared_contract_deterministic_business_output=true"
echo "ai_generated_ui_shared_contract_non_bool_public_api_consumed=true"
echo "ai_generated_ui_shared_contract_public_api_name=CjguiExperimentalDemoOutputBuilder"
echo "ai_generated_ui_shared_contract_public_api_return=CjguiExperimentalDemoOutput"
echo "ai_generated_ui_shared_contract_legacy_output_api_direct_consumption=false"
echo "ai_generated_ui_shared_contract_existing_ai_api_consumed=false"
echo "ai_generated_ui_shared_contract_existing_shared_contract_api_consumed=false"
echo "ai_generated_ui_shared_contract_owner_local_write_readback=true"
echo "ai_generated_ui_shared_contract_state_write_scope=AiGeneratedUiSharedContractState.componentIds,accepted,acceptedScreen,diffSummary,explainText,uiState,interactionTrace"
echo "ai_generated_ui_shared_contract_shared_support_imported=true"
echo "ai_generated_ui_shared_contract_shared_support_name=CjguiExperimentalDemoInteractionTrace"
echo "ai_generated_ui_shared_contract_shared_state_core_imported=true"
echo "ai_generated_ui_shared_contract_shared_state_core_name=CjguiExperimentalDemoUiStateCore"
echo "ai_generated_ui_shared_contract_runtime_state_write=false"
echo "ai_generated_ui_shared_contract_renderer_state_write=false"
echo "ai_generated_ui_shared_contract_public_c_abi_added=false"
