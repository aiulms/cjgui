#!/usr/bin/env zsh
#
# Focused verification for the shared CJGUI demo_support demo run harness.
# Scope: verify representative runnable demos consume the same run/result support API.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_HARNESS_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_harness.cj"
RUN_REPORTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_result_reporter.cj"
PROOF_REPORTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_proof_reporter.cj"
BUSINESS_REPORTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_business_snapshot_reporter.cj"
METADATA_REPORTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_metadata_reporter.cj"
EVIDENCE_PRESENTER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_presenter.cj"
TODO_DEMO_SRC="$ROOT_DIR/demo/todo_app.cj"
SETTINGS_DEMO_SRC="$ROOT_DIR/demo/settings_app.cj"
CHAT_DEMO_SRC="$ROOT_DIR/demo/chat_app.cj"
FILE_BROWSER_DEMO_SRC="$ROOT_DIR/demo/file_browser_app.cj"
AI_GENERATED_UI_DEMO_SRC="$ROOT_DIR/demo/ai_generated_ui_app.cj"
SHARED_DEMO_HARNESS_SRC="$ROOT_DIR/demo/shared_demo_harness_app.cj"
SHARED_MULTI_DEMO_HARNESS_SRC="$ROOT_DIR/demo/shared_multi_demo_harness_app.cj"
SHARED_LAYOUT_STYLE_INPUT_FOCUS_SRC="$ROOT_DIR/demo/shared_layout_style_input_focus_contract_app.cj"
AI_GENERATED_UI_SHARED_CONTRACT_SRC="$ROOT_DIR/demo/ai_generated_ui_shared_contract_app.cj"
REUSABLE_COMPONENT_CONTRACT_SRC="$ROOT_DIR/demo/reusable_component_contract_app.cj"
TODO_VERIFIER="$SCRIPT_DIR/verify_cjgui_todo_demo_app.sh"
SETTINGS_VERIFIER="$SCRIPT_DIR/verify_cjgui_settings_demo_app.sh"
CHAT_VERIFIER="$SCRIPT_DIR/verify_cjgui_chat_demo_app.sh"
FILE_BROWSER_VERIFIER="$SCRIPT_DIR/verify_cjgui_file_browser_demo_app.sh"
AI_GENERATED_UI_VERIFIER="$SCRIPT_DIR/verify_cjgui_ai_generated_ui_demo_app.sh"
SHARED_DEMO_HARNESS_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_demo_harness_app.sh"
SHARED_MULTI_DEMO_HARNESS_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_multi_demo_harness_app.sh"
SHARED_LAYOUT_STYLE_INPUT_FOCUS_VERIFIER="$SCRIPT_DIR/verify_cjgui_shared_layout_style_input_focus_contract_app.sh"
AI_GENERATED_UI_SHARED_CONTRACT_VERIFIER="$SCRIPT_DIR/verify_cjgui_ai_generated_ui_shared_contract_app.sh"
REUSABLE_COMPONENT_CONTRACT_VERIFIER="$SCRIPT_DIR/verify_cjgui_reusable_component_contract_app.sh"
TMP_DIR="${CJGUI_SHARED_DEMO_RUN_TMPDIR:-/private/tmp/cjgui-shared-demo-run-harness}"
TODO_LOG="$TMP_DIR/todo.log"
SETTINGS_LOG="$TMP_DIR/settings.log"
CHAT_LOG="$TMP_DIR/chat.log"
FILE_BROWSER_LOG="$TMP_DIR/file-browser.log"
AI_GENERATED_UI_LOG="$TMP_DIR/ai-generated-ui.log"
SHARED_DEMO_HARNESS_LOG="$TMP_DIR/shared-demo-harness.log"
SHARED_MULTI_DEMO_HARNESS_LOG="$TMP_DIR/shared-multi-demo-harness.log"
SHARED_LAYOUT_STYLE_INPUT_FOCUS_LOG="$TMP_DIR/shared-layout-style-input-focus.log"
AI_GENERATED_UI_SHARED_CONTRACT_LOG="$TMP_DIR/ai-generated-ui-shared-contract.log"
REUSABLE_COMPONENT_CONTRACT_LOG="$TMP_DIR/reusable-component-contract.log"

mkdir -p "$TMP_DIR"
: > "$TODO_LOG"
: > "$SETTINGS_LOG"
: > "$CHAT_LOG"
: > "$FILE_BROWSER_LOG"
: > "$AI_GENERATED_UI_LOG"
: > "$SHARED_DEMO_HARNESS_LOG"
: > "$SHARED_MULTI_DEMO_HARNESS_LOG"
: > "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_LOG"
: > "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
: > "$REUSABLE_COMPONENT_CONTRACT_LOG"

require_line() {
  local expected="$1"
  local log_file="$2"
  if ! grep -F "$expected" "$log_file" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: missing line '$expected' in $log_file" >&2
    echo "cjgui shared demo run harness verification: full log follows" >&2
    cat "$log_file" >&2
    exit 10
  fi
}

require_run_harness_lines() {
  local prefix="$1"
  local log_file="$2"
  require_line "${prefix}_shared_run_harness_imported=true" "$log_file"
  require_line "${prefix}_shared_run_harness=CjguiExperimentalDemoRunHarness" "$log_file"
  require_line "${prefix}_shared_run_result=CjguiExperimentalDemoRunResult" "$log_file"
  require_line "${prefix}_shared_run_readback=true" "$log_file"
  require_line "${prefix}_shared_run_not_published=true" "$log_file"
}

if [[ ! -f "$RUN_HARNESS_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing run harness source $RUN_HARNESS_SRC" >&2
  exit 2
fi

if [[ ! -f "$RUN_REPORTER_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing run result reporter source $RUN_REPORTER_SRC" >&2
  exit 2
fi

if [[ ! -f "$PROOF_REPORTER_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing proof reporter source $PROOF_REPORTER_SRC" >&2
  exit 2
fi

if [[ ! -f "$BUSINESS_REPORTER_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing business snapshot reporter source $BUSINESS_REPORTER_SRC" >&2
  exit 2
fi

if [[ ! -f "$METADATA_REPORTER_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing metadata reporter source $METADATA_REPORTER_SRC" >&2
  exit 2
fi

if [[ ! -f "$EVIDENCE_PRESENTER_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing evidence presenter source $EVIDENCE_PRESENTER_SRC" >&2
  exit 2
fi

if ! grep -F "public class CjguiExperimentalDemoRunResult" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoRunHarness" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func finishRun" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func finishCommittedSessionRun" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoComponentActionSession" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "notPublished" "$RUN_HARNESS_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected run harness declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoRunResultReporter" "$RUN_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printRunResult" "$RUN_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "shared_run_harness=CjguiExperimentalDemoRunHarness" "$RUN_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F 'shared_run_result=${runResult.summary}' "$RUN_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F 'shared_run_readback=${runResult.runnable}' "$RUN_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F 'shared_run_not_published=${runResult.notPublished}' "$RUN_REPORTER_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected run result reporter declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoProofReporter" "$PROOF_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printSharedPrimitiveProof" "$PROOF_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public_api_consumed=true" "$PROOF_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "shared_support=CjguiExperimentalDemoComponentActionSession" "$PROOF_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "shared_component_action_model=CjguiExperimentalDemoComponentActionSession" "$PROOF_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "shared_commit_harness=CjguiExperimentalDemoCommitHarness" "$PROOF_REPORTER_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected proof reporter declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoBusinessSnapshotReporter" "$BUSINESS_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printStatusTransition" "$BUSINESS_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printTextFact" "$BUSINESS_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printBoolFact" "$BUSINESS_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "status_before=" "$BUSINESS_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F 'println("${outputPrefix}: ${name}=${value}")' "$BUSINESS_REPORTER_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected business snapshot reporter declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoMetadataReporter" "$METADATA_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printDemoIdentity" "$METADATA_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printStaticBoolFact" "$METADATA_REPORTER_SRC" >/dev/null 2>&1 || \
   ! grep -F 'println("${outputPrefix}: demo=${demoName}")' "$METADATA_REPORTER_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected metadata reporter declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoEvidencePresenter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printSharedExecutionProof" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoMetadataReporter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoBusinessSnapshotReporter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoProofReporter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoRunResultReporter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected evidence presenter declarations" >&2
  exit 3
fi

for demo_src in \
  "$TODO_DEMO_SRC" \
  "$SETTINGS_DEMO_SRC" \
  "$CHAT_DEMO_SRC" \
  "$FILE_BROWSER_DEMO_SRC" \
  "$AI_GENERATED_UI_DEMO_SRC" \
  "$SHARED_DEMO_HARNESS_SRC" \
  "$SHARED_MULTI_DEMO_HARNESS_SRC" \
  "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_SRC" \
  "$AI_GENERATED_UI_SHARED_CONTRACT_SRC" \
  "$REUSABLE_COMPONENT_CONTRACT_SRC"; do
  if grep -F "func buildRunResult(" "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local buildRunResult wrapper remains in $demo_src" >&2
    exit 4
  fi
  if ! grep -F "CjguiExperimentalDemoEvidencePresenter" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "evidencePresenter.printDemoIdentity" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "evidencePresenter.printStatusTransition" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "evidencePresenter.printTextFact" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "evidencePresenter.printBoolFact" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "evidencePresenter.printSharedExecutionProof(apiOutput" "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo must use shared evidence presenter in $demo_src" >&2
    exit 4
  fi
  if grep -E 'CjguiExperimentalDemo(ProofReporter|RunResultReporter|BusinessSnapshotReporter|MetadataReporter)|proofReporter|runReporter|businessReporter|metadataReporter' "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local direct reporter wiring remains in $demo_src" >&2
    exit 4
  fi
  if grep -F 'println("cjgui ' "$demo_src" | grep -F "shared_run_" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local shared_run println remains in $demo_src" >&2
    exit 4
  fi
  if grep -E 'println\("cjgui .*: (public_api_consumed|public_api_name|public_api_output|shared_support|shared_support_output|shared_state_core|shared_component_action_model|shared_component_action_output|shared_commit_harness|shared_commit_output|shared_commit_readback|shared_commit_rollback_boundary|shared_commit_not_published)=' "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local shared proof println remains in $demo_src" >&2
    exit 4
  fi
  if grep -E 'println\("cjgui .*: (status_before|status_after|layout|controls|interaction|state_before|state_after|state_readback|summary_before|summary_after|summary_after_add|summary_after_complete|served_demo|served_demos|served_demo_count|reused_demos|component_kinds|owner_local_write_readback|public_api_available)=' "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local business snapshot println remains in $demo_src" >&2
    exit 4
  fi
  if grep -E 'println\("cjgui .*: (demo|main_declared|deterministic_output)=' "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local metadata println remains in $demo_src" >&2
    exit 4
  fi
done

CJGUI_TODO_DEMO_TMPDIR="$TMP_DIR/todo-tmp" "$TODO_VERIFIER" > "$TODO_LOG"
CJGUI_SETTINGS_DEMO_TMPDIR="$TMP_DIR/settings-tmp" "$SETTINGS_VERIFIER" > "$SETTINGS_LOG"
CJGUI_CHAT_DEMO_TMPDIR="$TMP_DIR/chat-tmp" "$CHAT_VERIFIER" > "$CHAT_LOG"
CJGUI_FILE_BROWSER_DEMO_TMPDIR="$TMP_DIR/file-browser-tmp" "$FILE_BROWSER_VERIFIER" > "$FILE_BROWSER_LOG"
CJGUI_AI_GENERATED_UI_DEMO_TMPDIR="$TMP_DIR/ai-generated-ui-tmp" "$AI_GENERATED_UI_VERIFIER" > "$AI_GENERATED_UI_LOG"
CJGUI_SHARED_DEMO_HARNESS_TMPDIR="$TMP_DIR/shared-demo-harness-tmp" "$SHARED_DEMO_HARNESS_VERIFIER" > "$SHARED_DEMO_HARNESS_LOG"
CJGUI_SHARED_MULTI_DEMO_HARNESS_TMPDIR="$TMP_DIR/shared-multi-demo-harness-tmp" "$SHARED_MULTI_DEMO_HARNESS_VERIFIER" > "$SHARED_MULTI_DEMO_HARNESS_LOG"
CJGUI_SHARED_LAYOUT_STYLE_INPUT_FOCUS_CONTRACT_TMPDIR="$TMP_DIR/shared-layout-style-input-focus-tmp" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_VERIFIER" > "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_LOG"
CJGUI_AI_GENERATED_UI_SHARED_CONTRACT_TMPDIR="$TMP_DIR/ai-generated-ui-shared-contract-tmp" "$AI_GENERATED_UI_SHARED_CONTRACT_VERIFIER" > "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
CJGUI_REUSABLE_COMPONENT_CONTRACT_TMPDIR="$TMP_DIR/reusable-component-contract-tmp" "$REUSABLE_COMPONENT_CONTRACT_VERIFIER" > "$REUSABLE_COMPONENT_CONTRACT_LOG"

require_run_harness_lines "todo" "$TODO_LOG"
require_run_harness_lines "settings" "$SETTINGS_LOG"
require_run_harness_lines "chat" "$CHAT_LOG"
require_run_harness_lines "file_browser" "$FILE_BROWSER_LOG"
require_run_harness_lines "ai_generated_ui" "$AI_GENERATED_UI_LOG"
require_run_harness_lines "shared_demo_harness" "$SHARED_DEMO_HARNESS_LOG"
require_run_harness_lines "shared_multi_demo_harness" "$SHARED_MULTI_DEMO_HARNESS_LOG"
require_run_harness_lines "shared_layout_style_input_focus_contract" "$SHARED_LAYOUT_STYLE_INPUT_FOCUS_LOG"
require_run_harness_lines "ai_generated_ui_shared_contract" "$AI_GENERATED_UI_SHARED_CONTRACT_LOG"
require_run_harness_lines "reusable_component_contract" "$REUSABLE_COMPONENT_CONTRACT_LOG"

echo "cjgui_shared_demo_run_harness_verified=true"
echo "cjgui_shared_demo_run_harness=CjguiExperimentalDemoRunHarness"
echo "cjgui_shared_demo_run_result=CjguiExperimentalDemoRunResult"
echo "cjgui_shared_demo_run_demo_count=10"
echo "cjgui_shared_demo_run_demos=todo,settings,chat,file_browser,ai_generated_ui,shared_demo_harness,shared_multi_demo_harness,shared_layout_style_input_focus_contract,ai_generated_ui_shared_contract,reusable_component_contract"
echo "cjgui_shared_demo_run_binary_execution=true"
echo "cjgui_shared_demo_run_readback=true"
echo "cjgui_shared_demo_run_not_published=true"
echo "cjgui_shared_demo_run_harness_boilerplate_reduced=true"
echo "cjgui_shared_demo_run_session_api=finishCommittedSessionRun"
echo "cjgui_shared_demo_run_result_reporter=CjguiExperimentalDemoRunResultReporter"
echo "cjgui_shared_demo_run_result_reporter_demo_count=10"
echo "cjgui_shared_demo_run_result_output_rendering_shared=true"
echo "cjgui_shared_demo_run_local_shared_run_println_retired=true"
echo "cjgui_shared_demo_proof_reporter=CjguiExperimentalDemoProofReporter"
echo "cjgui_shared_demo_proof_reporter_demo_count=10"
echo "cjgui_shared_demo_public_component_commit_output_rendering_shared=true"
echo "cjgui_shared_demo_local_shared_proof_println_retired=true"
echo "cjgui_shared_demo_business_snapshot_reporter=CjguiExperimentalDemoBusinessSnapshotReporter"
echo "cjgui_shared_demo_business_snapshot_reporter_demo_count=10"
echo "cjgui_shared_demo_business_snapshot_output_rendering_shared=true"
echo "cjgui_shared_demo_local_business_snapshot_println_retired=true"
echo "cjgui_shared_demo_metadata_reporter=CjguiExperimentalDemoMetadataReporter"
echo "cjgui_shared_demo_metadata_reporter_demo_count=10"
echo "cjgui_shared_demo_metadata_output_rendering_shared=true"
echo "cjgui_shared_demo_local_metadata_println_retired=true"
echo "cjgui_shared_demo_evidence_presenter=CjguiExperimentalDemoEvidencePresenter"
echo "cjgui_shared_demo_evidence_presenter_demo_count=10"
echo "cjgui_shared_demo_evidence_presenter_output_orchestration_shared=true"
echo "cjgui_shared_demo_direct_reporter_wiring_retired=true"
echo "cjgui_shared_demo_run_runtime_state_write=false"
echo "cjgui_shared_demo_run_renderer_state_write=false"
echo "cjgui_shared_demo_run_public_c_abi_added=false"
