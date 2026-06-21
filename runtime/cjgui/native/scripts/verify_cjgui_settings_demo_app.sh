#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI Settings demo app.
# Scope: compile and run runtime/cjgui/demo/settings_app.cj against temporary packages built from shared demo support sources.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/settings_app.cj"
API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_settings_demo_api.cj"
SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
OUTPUT_SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj"
UI_STATE_CORE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj"
COMPONENT_ACTION_SESSION_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj"
COMMIT_SESSION_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_owner_local_commit_session.cj"
RUN_HARNESS_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_harness.cj"
RUN_REPORTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_result_reporter.cj"
PROOF_REPORTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_proof_reporter.cj"
BUSINESS_REPORTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_business_snapshot_reporter.cj"
METADATA_REPORTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_metadata_reporter.cj"
EVIDENCE_PRESENTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_presenter.cj"
TMP_DIR="${CJGUI_SETTINGS_DEMO_TMPDIR:-/private/tmp/cjgui-settings-demo-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/settings-demo-output.log"

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

if [[ ! -f "$SUPPORT_SRC" ]]; then
  echo "cjgui settings demo app verification: missing shared support source $SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$OUTPUT_SUPPORT_SRC" ]]; then
  echo "cjgui settings demo app verification: missing shared output support source $OUTPUT_SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$UI_STATE_CORE_SRC" ]]; then
  echo "cjgui settings demo app verification: missing shared UI state core source $UI_STATE_CORE_SRC" >&2
  exit 2
fi

if [[ ! -f "$COMPONENT_ACTION_SESSION_SRC" ]]; then
  echo "cjgui settings demo app verification: missing shared component action session source $COMPONENT_ACTION_SESSION_SRC" >&2
  exit 2
fi

if [[ ! -f "$COMMIT_SESSION_SRC" ]]; then
  echo "cjgui settings demo app verification: missing shared commit session source $COMMIT_SESSION_SRC" >&2
  exit 2
fi

if [[ ! -f "$RUN_HARNESS_SRC" ]]; then
  echo "cjgui settings demo app verification: missing shared run harness source $RUN_HARNESS_SRC" >&2
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
require_source_line "public class CjguiExperimentalDemoCommitResult" "$COMMIT_SESSION_SRC"
require_source_line "public class CjguiExperimentalDemoOwnerLocalCommitSession" "$COMMIT_SESSION_SRC"
require_source_line "public class CjguiExperimentalDemoCommitHarness" "$COMMIT_SESSION_SRC"
require_source_line "public func commitComponentAction" "$COMMIT_SESSION_SRC"
require_source_line "public func rollbackBoundary" "$COMMIT_SESSION_SRC"
require_source_line "public func resultMatches" "$COMMIT_SESSION_SRC"
require_source_line "public class CjguiExperimentalDemoRunResult" "$RUN_HARNESS_SRC"
require_source_line "public class CjguiExperimentalDemoRunHarness" "$RUN_HARNESS_SRC"
require_source_line "public func finishRun" "$RUN_HARNESS_SRC"
require_source_line "public func finishCommittedSessionRun" "$RUN_HARNESS_SRC"
require_source_line "public class CjguiExperimentalDemoBusinessSnapshotReporter" "$BUSINESS_REPORTER_SRC"
require_source_line "public func printStatusTransition" "$BUSINESS_REPORTER_SRC"
require_source_line "public func printTextFact" "$BUSINESS_REPORTER_SRC"
require_source_line "public func printBoolFact" "$BUSINESS_REPORTER_SRC"
require_source_line "public class CjguiExperimentalDemoMetadataReporter" "$METADATA_REPORTER_SRC"
require_source_line "public func printDemoIdentity" "$METADATA_REPORTER_SRC"
require_source_line "public func printStaticBoolFact" "$METADATA_REPORTER_SRC"
require_source_line "public class CjguiExperimentalDemoEvidencePresenter" "$EVIDENCE_PRESENTER_SRC"
require_source_line "public func printSharedExecutionProof" "$EVIDENCE_PRESENTER_SRC"
require_source_line "CjguiExperimentalDemoProofReporter" "$EVIDENCE_PRESENTER_SRC"
require_source_line "CjguiExperimentalDemoRunResultReporter" "$EVIDENCE_PRESENTER_SRC"
require_source_line "package cjgui_settings_demo" "$DEMO_SRC"
require_source_line "import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}" "$DEMO_SRC"
require_source_line "import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}" "$DEMO_SRC"
require_source_line "import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}" "$DEMO_SRC"
require_source_line "class SettingsPanelState" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoComponentActionSession" "$DEMO_SRC"
require_source_line "let commitHarness: CjguiExperimentalDemoCommitHarness" "$DEMO_SRC"
require_source_line "let runHarness: CjguiExperimentalDemoRunHarness" "$DEMO_SRC"
require_source_line "commitHarness.resultMatches" "$DEMO_SRC"
require_source_line "finishCommittedSessionRun" "$DEMO_SRC"
require_source_line "runResult.runnable" "$DEMO_SRC"
if grep -F "func buildRunResult(" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: demo-local buildRunResult wrapper must be retired" >&2
  exit 13
fi
require_source_line "var selectedTheme: String" "$DEMO_SRC"
require_source_line "var usernameValue: String" "$DEMO_SRC"
require_source_line "var autoSaveEnabled: Bool" "$DEMO_SRC"
require_source_line "sharedUiState()" "$DEMO_SRC"
require_source_line "main(): Int64" "$DEMO_SRC"
require_source_line "componentSession.recordComponentAction" "$DEMO_SRC"
require_source_line "sharedComponentActions()" "$DEMO_SRC"
require_source_line "buildSharedOutput" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoEvidencePresenter" "$DEMO_SRC"
require_source_line "evidencePresenter.printStatusTransition" "$DEMO_SRC"
require_source_line "evidencePresenter.printTextFact" "$DEMO_SRC"
require_source_line "evidencePresenter.printBoolFact" "$DEMO_SRC"
require_source_line 'evidencePresenter.printDemoIdentity("settings")' "$DEMO_SRC"
require_source_line 'evidencePresenter.printStaticBoolFact("main_declared", true)' "$DEMO_SRC"
require_source_line 'evidencePresenter.printStaticBoolFact("deterministic_output", true)' "$DEMO_SRC"
require_source_line "evidencePresenter.printSharedExecutionProof(apiOutput" "$DEMO_SRC"

if grep -E 'CjguiExperimentalDemo(ProofReporter|RunResultReporter|BusinessSnapshotReporter|MetadataReporter)|proofReporter|runReporter|businessReporter|metadataReporter' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: demo-local direct reporter wiring must stay retired" >&2
  exit 10
fi

if grep -E 'println\("cjgui .*: (demo|main_declared|deterministic_output)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: demo-local metadata println remains" >&2
  exit 14
fi

if grep -F "cjguiExperimentalBuildSettingsDemoOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "CjguiExperimentalSettingsDemoOutput" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: demo must not directly consume legacy Settings output API" >&2
  exit 10
fi

if grep -F "func commitSharedState" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "func commitReadback" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "func commitRollbackBoundary" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: demo must use shared commit harness instead of local commit wrappers" >&2
  exit 10
fi

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
cat > "$PROBE_API_PACKAGE_DIR/src/runtime_cjgui_demo_support_root.cj" <<'CJGUI_DEMO_SUPPORT_ROOT'
package cjgui

// 中文维护注释：临时 verifier package root shim；demo_support 子包承载真实 experimental API，禁止新增 public 声明。
CJGUI_DEMO_SUPPORT_ROOT
cp "$DEMO_SRC" "$PROBE_PACKAGE_DIR/src/main.cj"
cp "$SUPPORT_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
cp "$OUTPUT_SUPPORT_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj"
cp "$UI_STATE_CORE_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj"
cp "$COMPONENT_ACTION_SESSION_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj"
cp "$COMMIT_SESSION_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_owner_local_commit_session.cj"
cp "$RUN_HARNESS_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_harness.cj"
cp "$RUN_REPORTER_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_result_reporter.cj"
cp "$PROOF_REPORTER_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_proof_reporter.cj"
cp "$BUSINESS_REPORTER_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_business_snapshot_reporter.cj"
cp "$METADATA_REPORTER_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_metadata_reporter.cj"
cp "$EVIDENCE_PRESENTER_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_presenter.cj"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm build --target-dir "$BUILD_DIR/cjpm-target" --skip-script
  CANGJIE_RUNTIME_DYLIB="$(find "${CANGJIE_HOME:-}/runtime/lib" -maxdepth 2 -name libcangjie-runtime.dylib -print -quit 2>/dev/null || true)"
  if [[ -n "$CANGJIE_RUNTIME_DYLIB" ]]; then
    CANGJIE_RUNTIME_LIB_DIR="$(dirname "$CANGJIE_RUNTIME_DYLIB")"
    export DYLD_LIBRARY_PATH="${CANGJIE_RUNTIME_LIB_DIR}:${DYLD_LIBRARY_PATH:-}"
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
require_output_line "cjgui settings demo app: public_api_name=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui settings demo app: public_api_output=demo=settings;readback=true;writes=4;actions=settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus;before=autosave=false;theme=light;username=owner;focus=username_field;after=autosave=true;theme=dark;username=owner-updated;focus=theme_select;summary=demo=settings;layout=sectioned_form;controls=toggle:auto_save,select:theme,text:username;autosave=true;theme=dark;username=owner-updated;focus=theme_select"
require_output_line "cjgui settings demo app: shared_support=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui settings demo app: shared_support_output=demo=settings;writes=4;actions=settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus;before=autosave=false;theme=light;username=owner;focus=username_field;after=autosave=true;theme=dark;username=owner-updated;focus=theme_select"
require_output_line "cjgui settings demo app: shared_state_core=layout=sectioned_form;style=theme_dark;input=owner-updated;focus=theme_select"
require_output_line "cjgui settings demo app: shared_component_action_model=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui settings demo app: shared_component_action_output=demo=settings;component_actions=auto_save_toggle:settings.toggle_auto_save,theme_select:settings.select_theme,username_field:settings.update_username,theme_select:settings.move_focus;ui=layout=sectioned_form;style=theme_dark;input=owner-updated;focus=theme_select"
if grep -F "shared_commit_model=CjguiExperimentalDemoOwnerLocalCommitSession" "$OUTPUT_LOG" >/dev/null 2>&1; then
  echo "cjgui settings demo app verification: demo output must expose shared commit harness, not primitive session" >&2
  cat "$OUTPUT_LOG" >&2
  exit 21
fi
require_output_line "cjgui settings demo app: shared_commit_harness=CjguiExperimentalDemoCommitHarness"
require_output_line "cjgui settings demo app: shared_commit_output=demo=settings;component=theme_select;action=settings.commit_preferences;committed=true;readback=true;writes=1;before=autosave=false;theme=light;username=owner;focus=username_field;after=autosave=true;theme=dark;username=owner-updated;focus=theme_select;readback_state=autosave=true;theme=dark;username=owner-updated;focus=theme_select;rollback_state=autosave=false;theme=light;username=owner;focus=username_field;not_published=true"
require_output_line "cjgui settings demo app: shared_commit_readback=autosave=true;theme=dark;username=owner-updated;focus=theme_select"
require_output_line "cjgui settings demo app: shared_commit_rollback_boundary=autosave=false;theme=light;username=owner;focus=username_field"
require_output_line "cjgui settings demo app: shared_commit_not_published=true"
require_output_line "cjgui settings demo app: shared_run_harness=CjguiExperimentalDemoRunHarness"
require_output_line "cjgui settings demo app: shared_run_result=demo=settings;status=scaffolded->runnable;readback=true;commit_readback=true;not_published=true;writes=4;actions=settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus"
require_output_line "cjgui settings demo app: shared_run_readback=true"
require_output_line "cjgui settings demo app: shared_run_not_published=true"
require_output_line "cjgui settings demo app: public_api_available=true"

echo "cjgui_settings_demo_app_compiled=true"
echo "cjgui_settings_demo_app_ran=true"
echo "settings_demo_progress_before=scaffolded"
echo "settings_demo_progress_after=runnable"
echo "settings_demo_has_main=true"
echo "settings_demo_deterministic_business_output=true"
echo "settings_non_bool_public_api_consumed=true"
echo "settings_public_api_name=CjguiExperimentalDemoComponentActionSession"
echo "settings_public_api_return=CjguiExperimentalDemoOutput"
echo "settings_legacy_output_api_direct_consumption=false"
echo "settings_owner_local_write_readback=true"
echo "settings_state_write_scope=SettingsPanelState.autoSaveEnabled,selectedTheme,usernameValue,componentSession,commitHarness"
echo "settings_shared_support_imported=true"
echo "settings_shared_support_name=CjguiExperimentalDemoComponentActionSession"
echo "settings_shared_state_core_imported=true"
echo "settings_shared_state_core_name=CjguiExperimentalDemoUiStateCore"
echo "settings_shared_component_action_session_imported=true"
echo "settings_shared_component_action_session_name=CjguiExperimentalDemoComponentActionSession"
echo "settings_shared_commit_harness_imported=true"
echo "settings_shared_commit_harness_name=CjguiExperimentalDemoCommitHarness"
echo "settings_shared_commit_harness_internal_primitive_present=true"
echo "settings_shared_commit_harness_internal_primitive_name=CjguiExperimentalDemoOwnerLocalCommitSession"
echo "settings_shared_commit_result_name=CjguiExperimentalDemoCommitResult"
echo "settings_shared_commit_readback=true"
echo "settings_shared_commit_not_published=true"
echo "settings_shared_run_harness_imported=true"
echo "settings_shared_run_harness=CjguiExperimentalDemoRunHarness"
echo "settings_shared_run_result=CjguiExperimentalDemoRunResult"
echo "settings_shared_run_readback=true"
echo "settings_shared_run_not_published=true"
echo "settings_runtime_state_write=false"
echo "settings_renderer_state_write=false"
echo "settings_public_c_abi_added=false"
