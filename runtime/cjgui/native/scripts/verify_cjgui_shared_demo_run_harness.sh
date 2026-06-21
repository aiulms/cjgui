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
EVIDENCE_PROFILE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_profile.cj"
EVIDENCE_SECTION_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_section.cj"
EVIDENCE_SECTION_BUILDER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_section_builder.cj"
DOMAIN_EVIDENCE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_domain_evidence.cj"
INTERACTION_STATE_EVIDENCE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_state_evidence.cj"
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

if [[ ! -f "$EVIDENCE_PROFILE_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing evidence profile source $EVIDENCE_PROFILE_SRC" >&2
  exit 2
fi

if [[ ! -f "$EVIDENCE_SECTION_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing evidence section source $EVIDENCE_SECTION_SRC" >&2
  exit 2
fi

if [[ ! -f "$EVIDENCE_SECTION_BUILDER_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing evidence section builder source $EVIDENCE_SECTION_BUILDER_SRC" >&2
  exit 2
fi

if [[ ! -f "$DOMAIN_EVIDENCE_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing semantic domain evidence source $DOMAIN_EVIDENCE_SRC" >&2
  exit 2
fi

if [[ ! -f "$INTERACTION_STATE_EVIDENCE_SRC" ]]; then
  echo "cjgui shared demo run harness verification: missing semantic interaction/state evidence source $INTERACTION_STATE_EVIDENCE_SRC" >&2
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

if ! grep -F "public class CjguiExperimentalDemoComponentActionRoute" "$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj" >/dev/null 2>&1 || \
   ! grep -F "public func recordComponentActionRoute" "$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj" >/dev/null 2>&1 || \
   ! grep -F "public func componentIdValue" "$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj" >/dev/null 2>&1 || \
   ! grep -F "public func actionValue" "$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj" >/dev/null 2>&1 || \
   ! grep -F "public func routeValue" "$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing component action route value model declarations" >&2
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
   ! grep -F "public func printEvidenceProfile" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printEvidenceSection" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func printSharedExecutionProof" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoMetadataReporter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoBusinessSnapshotReporter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoProofReporter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoRunResultReporter" "$EVIDENCE_PRESENTER_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected evidence presenter declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoEvidenceProfile" "$EVIDENCE_PROFILE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addStaticBoolFact" "$EVIDENCE_PROFILE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addTextFact" "$EVIDENCE_PROFILE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addBoolFact" "$EVIDENCE_PROFILE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func textFactCount" "$EVIDENCE_PROFILE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func boolFactCount" "$EVIDENCE_PROFILE_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected evidence profile declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoEvidenceSection" "$EVIDENCE_SECTION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func profileFactCount" "$EVIDENCE_SECTION_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoOutput" "$EVIDENCE_SECTION_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoRunResult" "$EVIDENCE_SECTION_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected evidence section declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoEvidenceSectionBuilder" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addStaticBoolFact" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addTextFact" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addBoolFact" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addInteractionFact" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addStateReadbackFacts" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addOwnerLocalWriteReadbackFacts" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addLayoutFact" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addControlsFact" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addServedDemoFact" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addServedDemosFacts" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addReusableComponentFacts" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addLayoutEvidence" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addControlsEvidence" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addServedDemoEvidence" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addServedDemosEvidence" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addReusableComponentEvidence" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addInteractionEvidence" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addStateReadbackEvidence" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func addOwnerLocalWriteReadbackEvidence" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func buildSection" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoEvidenceProfile" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoEvidenceSection" "$EVIDENCE_SECTION_BUILDER_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected evidence section builder declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoLayoutEvidence" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoControlsEvidence" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoServedDemoEvidence" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoServedDemosEvidence" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoReusableComponentEvidence" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func factValue" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func servedDemoValue" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func servedDemosValue" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func servedDemoCountValue" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func reusedDemosValue" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func componentKindsValue" "$DOMAIN_EVIDENCE_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected semantic domain evidence declarations" >&2
  exit 3
fi

if ! grep -F "public class CjguiExperimentalDemoComponentInteractionEvidence" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoStateReadbackEvidence" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoOwnerLocalWriteReadbackEvidence" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func interactionValue" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func stateBeforeValue" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func stateAfterValue" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func readbackOkValue" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func summaryBeforeValue" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func summaryAfterAddValue" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func summaryAfterCompleteValue" "$INTERACTION_STATE_EVIDENCE_SRC" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: missing expected semantic interaction/state evidence declarations" >&2
  exit 3
fi

layout_semantic_evidence_count="$(grep -R "evidenceBuilder.addLayoutEvidence" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
served_semantic_evidence_count="$(grep -R -E "evidenceBuilder.addServedDemo(Evidence|sEvidence)" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
reuse_semantic_evidence_count="$(grep -R "evidenceBuilder.addReusableComponentEvidence" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
interaction_semantic_evidence_count="$(grep -R "evidenceBuilder.addInteractionEvidence" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
state_readback_semantic_evidence_count="$(grep -R "evidenceBuilder.addStateReadbackEvidence" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
owner_local_write_semantic_evidence_count="$(grep -R "evidenceBuilder.addOwnerLocalWriteReadbackEvidence" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
component_action_route_usage_count="$(grep -R "componentSession.recordComponentActionRoute" "$ROOT_DIR/demo" | wc -l | tr -d ' ')"
if [ "$layout_semantic_evidence_count" -lt 4 ] || \
   [ "$served_semantic_evidence_count" -lt 2 ] || \
   [ "$reuse_semantic_evidence_count" -lt 1 ]; then
  echo "cjgui shared demo run harness verification: semantic domain evidence model is not shared across expected demos" >&2
  exit 4
fi

if [ "$interaction_semantic_evidence_count" -lt 10 ] || \
   [ "$state_readback_semantic_evidence_count" -lt 9 ] || \
   [ "$owner_local_write_semantic_evidence_count" -lt 1 ]; then
  echo "cjgui shared demo run harness verification: semantic interaction/state evidence model is not shared across expected demos" >&2
  exit 4
fi

if [ "$component_action_route_usage_count" -lt 41 ]; then
  echo "cjgui shared demo run harness verification: component action route value model is not shared across expected demos" >&2
  exit 4
fi

if grep -R "componentSession.recordComponentAction(" "$ROOT_DIR/demo" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: demo-local direct component/action string recording remains" >&2
  exit 4
fi

if grep -R -E 'evidenceBuilder\.addTextFact\("(layout|controls|served_demo|served_demos|served_demo_count|reused_demos|component_kinds)"' "$ROOT_DIR/demo" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: demo-local domain fact wiring remains" >&2
  exit 4
fi

if grep -R -E 'evidenceBuilder\.add(LayoutFact|ControlsFact|ServedDemoFact|ServedDemosFacts|ReusableComponentFacts)\(' "$ROOT_DIR/demo" >/dev/null 2>&1; then
  echo "cjgui shared demo run harness verification: demo string domain fact preset calls remain" >&2
  exit 4
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
     ! grep -F "CjguiExperimentalDemoEvidenceSectionBuilder" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "CjguiExperimentalDemoComponentActionRoute" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "componentSession.recordComponentActionRoute" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "evidenceBuilder.addInteractionEvidence" "$demo_src" >/dev/null 2>&1 || \
     ! grep -E "evidenceBuilder.add(StateReadbackEvidence|OwnerLocalWriteReadbackEvidence)" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "let evidenceSection = evidenceBuilder.buildSection" "$demo_src" >/dev/null 2>&1 || \
     ! grep -F "evidencePresenter.printEvidenceSection(evidenceSection)" "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo must use shared evidence section builder in $demo_src" >&2
    exit 4
  fi
  if grep -F 'evidenceBuilder.addInteractionFact' "$demo_src" >/dev/null 2>&1 || \
     grep -F 'evidenceBuilder.addStateReadbackFacts' "$demo_src" >/dev/null 2>&1 || \
     grep -F 'evidenceBuilder.addOwnerLocalWriteReadbackFacts' "$demo_src" >/dev/null 2>&1 || \
     grep -F 'evidenceBuilder.addTextFact("interaction"' "$demo_src" >/dev/null 2>&1 || \
     grep -F 'evidenceBuilder.addBoolFact("state_readback"' "$demo_src" >/dev/null 2>&1 || \
     grep -F 'evidenceBuilder.addBoolFact("owner_local_write_readback"' "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local interaction/state readback fact wiring remains in $demo_src" >&2
    exit 4
  fi
  if grep -F "CjguiExperimentalDemoEvidenceProfile(" "$demo_src" >/dev/null 2>&1 || \
     grep -F "let evidenceSection = CjguiExperimentalDemoEvidenceSection" "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local direct profile/section constructor remains in $demo_src" >&2
    exit 4
  fi
  if grep -E 'evidencePresenter\.print(DemoIdentity|StatusTransition|TextFact|BoolFact|StaticBoolFact|EvidenceProfile|SharedExecutionProof)' "$demo_src" >/dev/null 2>&1; then
    echo "cjgui shared demo run harness verification: demo-local presenter fact sequence remains in $demo_src" >&2
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
echo "cjgui_shared_demo_evidence_profile=CjguiExperimentalDemoEvidenceProfile"
echo "cjgui_shared_demo_evidence_profile_demo_count=10"
echo "cjgui_shared_demo_evidence_profile_business_fact_batching_shared=true"
echo "cjgui_shared_demo_direct_presenter_fact_sequence_retired=true"
echo "cjgui_shared_demo_evidence_section=CjguiExperimentalDemoEvidenceSection"
echo "cjgui_shared_demo_evidence_section_demo_count=10"
echo "cjgui_shared_demo_evidence_section_typed_execution_batching_shared=true"
echo "cjgui_shared_demo_direct_profile_and_proof_calls_retired=true"
echo "cjgui_shared_demo_evidence_section_builder=CjguiExperimentalDemoEvidenceSectionBuilder"
echo "cjgui_shared_demo_evidence_section_builder_demo_count=10"
echo "cjgui_shared_demo_evidence_section_builder_profile_run_assembly_shared=true"
echo "cjgui_shared_demo_direct_profile_and_section_constructors_retired=true"
echo "cjgui_shared_demo_evidence_fact_presets=CjguiExperimentalDemoEvidenceSectionBuilder"
echo "cjgui_shared_demo_evidence_fact_preset_demo_count=10"
echo "cjgui_shared_demo_interaction_fact_preset_shared=true"
echo "cjgui_shared_demo_state_readback_fact_bundle_shared=true"
echo "cjgui_shared_demo_direct_interaction_state_readback_fact_calls_retired=true"
echo "cjgui_shared_demo_domain_fact_presets=CjguiExperimentalDemoEvidenceSectionBuilder"
echo "cjgui_shared_demo_semantic_domain_evidence_model=CjguiExperimentalDemoDomainEvidence"
echo "cjgui_shared_demo_semantic_layout_evidence_demo_count=$layout_semantic_evidence_count"
echo "cjgui_shared_demo_semantic_served_evidence_demo_count=$served_semantic_evidence_count"
echo "cjgui_shared_demo_semantic_reuse_evidence_demo_count=$reuse_semantic_evidence_count"
echo "cjgui_shared_demo_string_domain_fact_preset_calls_retired=true"
echo "cjgui_shared_demo_semantic_interaction_state_evidence_model=CjguiExperimentalDemoInteractionStateEvidence"
echo "cjgui_shared_demo_semantic_interaction_evidence_demo_count=$interaction_semantic_evidence_count"
echo "cjgui_shared_demo_semantic_state_readback_evidence_demo_count=$state_readback_semantic_evidence_count"
echo "cjgui_shared_demo_semantic_owner_local_write_evidence_demo_count=$owner_local_write_semantic_evidence_count"
echo "cjgui_shared_demo_string_interaction_state_fact_preset_calls_retired=true"
echo "cjgui_shared_demo_component_action_route_model=CjguiExperimentalDemoComponentActionRoute"
echo "cjgui_shared_demo_component_action_route_usage_count=$component_action_route_usage_count"
echo "cjgui_shared_demo_direct_component_action_string_recording_retired=true"
echo "cjgui_shared_demo_direct_domain_fact_wiring_retired=true"
echo "cjgui_shared_demo_direct_reporter_wiring_retired=true"
echo "cjgui_shared_demo_run_runtime_state_write=false"
echo "cjgui_shared_demo_run_renderer_state_write=false"
echo "cjgui_shared_demo_run_public_c_abi_added=false"
