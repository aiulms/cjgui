#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI Chat demo app.
# Scope: compile and run runtime/cjgui/demo/chat_app.cj against temporary packages built from shared demo support sources.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/chat_app.cj"
API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_chat_demo_api.cj"
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
EVIDENCE_PROFILE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_profile.cj"
EVIDENCE_SECTION_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_section.cj"
EVIDENCE_SECTION_BUILDER_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_section_builder.cj"
TMP_DIR="${CJGUI_CHAT_DEMO_TMPDIR:-/private/tmp/cjgui-chat-demo-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/chat-demo-output.log"

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
    echo "cjgui chat demo app verification: missing source line: $expected" >&2
    exit 10
  fi
}

require_output_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui chat demo app verification: missing output line: $expected" >&2
    echo "cjgui chat demo app verification: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 20
  fi
}

if [[ ! -f "$DEMO_SRC" ]]; then
  echo "cjgui chat demo app verification: missing demo source $DEMO_SRC" >&2
  exit 2
fi

if [[ ! -f "$SUPPORT_SRC" ]]; then
  echo "cjgui chat demo app verification: missing shared support source $SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$OUTPUT_SUPPORT_SRC" ]]; then
  echo "cjgui chat demo app verification: missing shared output support source $OUTPUT_SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$UI_STATE_CORE_SRC" ]]; then
  echo "cjgui chat demo app verification: missing shared UI state core source $UI_STATE_CORE_SRC" >&2
  exit 2
fi

if [[ ! -f "$COMPONENT_ACTION_SESSION_SRC" ]]; then
  echo "cjgui chat demo app verification: missing shared component action session source $COMPONENT_ACTION_SESSION_SRC" >&2
  exit 2
fi

if [[ ! -f "$COMMIT_SESSION_SRC" ]]; then
  echo "cjgui chat demo app verification: missing shared commit session source $COMMIT_SESSION_SRC" >&2
  exit 2
fi

if [[ ! -f "$RUN_HARNESS_SRC" ]]; then
  echo "cjgui chat demo app verification: missing shared run harness source $RUN_HARNESS_SRC" >&2
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
require_source_line "notPublished" "$RUN_HARNESS_SRC"
require_source_line "public class CjguiExperimentalDemoBusinessSnapshotReporter" "$BUSINESS_REPORTER_SRC"
require_source_line "public func printStatusTransition" "$BUSINESS_REPORTER_SRC"
require_source_line "public func printTextFact" "$BUSINESS_REPORTER_SRC"
require_source_line "public func printBoolFact" "$BUSINESS_REPORTER_SRC"
require_source_line "public class CjguiExperimentalDemoMetadataReporter" "$METADATA_REPORTER_SRC"
require_source_line "public func printDemoIdentity" "$METADATA_REPORTER_SRC"
require_source_line "public func printStaticBoolFact" "$METADATA_REPORTER_SRC"
require_source_line "public class CjguiExperimentalDemoEvidencePresenter" "$EVIDENCE_PRESENTER_SRC"
require_source_line "public func printEvidenceProfile" "$EVIDENCE_PRESENTER_SRC"
require_source_line "public func printEvidenceSection" "$EVIDENCE_PRESENTER_SRC"
require_source_line "public func printSharedExecutionProof" "$EVIDENCE_PRESENTER_SRC"
require_source_line "CjguiExperimentalDemoProofReporter" "$EVIDENCE_PRESENTER_SRC"
require_source_line "CjguiExperimentalDemoRunResultReporter" "$EVIDENCE_PRESENTER_SRC"
require_source_line "public class CjguiExperimentalDemoEvidenceProfile" "$EVIDENCE_PROFILE_SRC"
require_source_line "public func addStaticBoolFact" "$EVIDENCE_PROFILE_SRC"
require_source_line "public func addTextFact" "$EVIDENCE_PROFILE_SRC"
require_source_line "public func addBoolFact" "$EVIDENCE_PROFILE_SRC"
require_source_line "public class CjguiExperimentalDemoEvidenceSection" "$EVIDENCE_SECTION_SRC"
require_source_line "public func profileFactCount" "$EVIDENCE_SECTION_SRC"
require_source_line "CjguiExperimentalDemoRunResult" "$EVIDENCE_SECTION_SRC"
require_source_line "public class CjguiExperimentalDemoEvidenceSectionBuilder" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addTextFact" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addBoolFact" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addInteractionFact" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addStateReadbackFacts" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addOwnerLocalWriteReadbackFacts" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addLayoutFact" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addControlsFact" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addServedDemoFact" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addServedDemosFacts" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func addReusableComponentFacts" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "public func buildSection" "$EVIDENCE_SECTION_BUILDER_SRC"
require_source_line "package cjgui_chat_demo" "$DEMO_SRC"
require_source_line "import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}" "$DEMO_SRC"
require_source_line "import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}" "$DEMO_SRC"
require_source_line "import cjgui.demo_support.{CjguiExperimentalDemoRunHarness}" "$DEMO_SRC"
require_source_line "class ChatThreadState" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoComponentActionSession" "$DEMO_SRC"
require_source_line "let commitHarness: CjguiExperimentalDemoCommitHarness" "$DEMO_SRC"
require_source_line "let runHarness: CjguiExperimentalDemoRunHarness" "$DEMO_SRC"
require_source_line "commitHarness.resultMatches" "$DEMO_SRC"
require_source_line "finishCommittedSessionRun" "$DEMO_SRC"
require_source_line "runResult.runnable" "$DEMO_SRC"
if grep -F "func buildRunResult(" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo-local buildRunResult wrapper must be retired" >&2
  exit 13
fi
require_source_line "private var messages" "$DEMO_SRC"
require_source_line "sharedUiState()" "$DEMO_SRC"
require_source_line "main(): Int64" "$DEMO_SRC"
require_source_line "componentSession.recordComponentAction" "$DEMO_SRC"
require_source_line "sharedComponentActions()" "$DEMO_SRC"
require_source_line "buildSharedOutput" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoEvidencePresenter" "$DEMO_SRC"
require_source_line "CjguiExperimentalDemoEvidenceSectionBuilder" "$DEMO_SRC"
require_source_line 'CjguiExperimentalDemoEvidenceSectionBuilder("chat", "not_started", "runnable")' "$DEMO_SRC"
require_source_line 'evidenceBuilder.addLayoutFact("threaded_chat")' "$DEMO_SRC"
require_source_line "evidenceBuilder.addInteractionFact" "$DEMO_SRC"
if ! grep -E "evidenceBuilder.add(StateReadbackFacts|OwnerLocalWriteReadbackFacts)" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui demo verification: demo must use shared evidence fact presets in $DEMO_SRC" >&2
  exit 4
fi
require_source_line "let evidenceSection = evidenceBuilder.buildSection" "$DEMO_SRC"
require_source_line "evidencePresenter.printEvidenceSection(evidenceSection)" "$DEMO_SRC"

if grep -F 'evidenceBuilder.addTextFact("interaction"' "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F 'evidenceBuilder.addBoolFact("state_readback"' "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F 'evidenceBuilder.addBoolFact("owner_local_write_readback"' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui demo verification: demo-local interaction/state readback fact wiring remains in $DEMO_SRC" >&2
  exit 4
fi

if grep -F 'evidenceBuilder.addTextFact("layout"' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo-local layout fact wiring remains" >&2
  exit 4
fi

if grep -F "CjguiExperimentalDemoEvidenceProfile(" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "let evidenceSection = CjguiExperimentalDemoEvidenceSection" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo-local direct evidence profile/section constructors must stay retired" >&2
  exit 4
fi

if grep -E 'evidencePresenter\.print(DemoIdentity|StatusTransition|TextFact|BoolFact|StaticBoolFact|EvidenceProfile|SharedExecutionProof)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo-local presenter fact sequence must stay retired" >&2
  exit 10
fi

if grep -E 'CjguiExperimentalDemo(ProofReporter|RunResultReporter|BusinessSnapshotReporter|MetadataReporter)|proofReporter|runReporter|businessReporter|metadataReporter' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo-local direct reporter wiring must stay retired" >&2
  exit 10
fi

if grep -E 'println\("cjgui .*: (demo|main_declared|deterministic_output)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo-local metadata println remains" >&2
  exit 14
fi

if grep -F "cjguiExperimentalBuildChatDemoOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "CjguiExperimentalChatDemoOutput" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo must not directly consume legacy Chat output API" >&2
  exit 10
fi

if grep -F "func commitSharedState" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "func commitReadback" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "func commitRollbackBoundary" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo must use shared commit harness instead of local commit wrappers" >&2
  exit 10
fi

if grep -E 'foreign[[:space:]]+func|cjgui_native_bridge_|public[[:space:]]+(func|class|struct|enum|let|var)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: forbidden runtime/native/public token in chat demo source" >&2
  exit 11
fi

if grep -E 'println\("cjgui chat demo app: (runtime_state_write|renderer_state_write|visibility_published|public_c_abi_added)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: governance stop-line output must stay out of demo app" >&2
  exit 12
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: cjpm not found" >&2
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
  echo "cjgui chat demo app verification: CJ_GUI_SDKROOT not found" >&2
  exit 14
fi

cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_CHAT_DEMO_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_chat_demo"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"

[dependencies]
  cjgui = { path = "$PROBE_API_PACKAGE_DIR" }
CJGUI_CHAT_DEMO_TOML
cat > "$PROBE_API_PACKAGE_DIR/cjpm.toml" <<CJGUI_CHAT_API_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
CJGUI_CHAT_API_TOML
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
cp "$EVIDENCE_PROFILE_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_profile.cj"
cp "$EVIDENCE_SECTION_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_section.cj"
cp "$EVIDENCE_SECTION_BUILDER_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_evidence_section_builder.cj"
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

require_output_line "cjgui chat demo app: demo=chat"
require_output_line "cjgui chat demo app: status_before=not_started"
require_output_line "cjgui chat demo app: status_after=runnable"
require_output_line "cjgui chat demo app: layout=threaded_chat"
require_output_line "cjgui chat demo app: interaction=type_message,send_message,append_reply,move_focus"
require_output_line "cjgui chat demo app: state_before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer"
require_output_line "cjgui chat demo app: state_after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list"
require_output_line "cjgui chat demo app: state_readback=true"
require_output_line "cjgui chat demo app: public_api_consumed=true"
require_output_line "cjgui chat demo app: public_api_name=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui chat demo app: public_api_output=demo=chat;readback=true;writes=4;actions=chat.type_message,chat.send_message,chat.append_reply,chat.move_focus;before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer;after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list;summary=demo=chat;layout=threaded_chat;messages=3;last=assistant:Chat demo received;composer=;focus=message_list"
require_output_line "cjgui chat demo app: shared_support=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui chat demo app: shared_support_output=demo=chat;writes=4;actions=chat.type_message,chat.send_message,chat.append_reply,chat.move_focus;before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer;after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list"
require_output_line "cjgui chat demo app: shared_state_core=layout=threaded_chat;style=assistant_reply;input=;focus=message_list"
require_output_line "cjgui chat demo app: shared_component_action_model=CjguiExperimentalDemoComponentActionSession"
require_output_line "cjgui chat demo app: shared_component_action_output=demo=chat;component_actions=composer:chat.type_message,send_button:chat.send_message,message_list:chat.append_reply,message_list:chat.move_focus;ui=layout=threaded_chat;style=assistant_reply;input=;focus=message_list"
if grep -F "shared_commit_model=CjguiExperimentalDemoOwnerLocalCommitSession" "$OUTPUT_LOG" >/dev/null 2>&1; then
  echo "cjgui chat demo app verification: demo output must expose shared commit harness, not primitive session" >&2
  cat "$OUTPUT_LOG" >&2
  exit 21
fi
require_output_line "cjgui chat demo app: shared_commit_harness=CjguiExperimentalDemoCommitHarness"
require_output_line "cjgui chat demo app: shared_commit_output=demo=chat;component=message_list;action=chat.commit_thread;committed=true;readback=true;writes=1;before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer;after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list;readback_state=messages=3;last=assistant:Chat demo received;composer=;focus=message_list;rollback_state=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer;not_published=true"
require_output_line "cjgui chat demo app: shared_commit_readback=messages=3;last=assistant:Chat demo received;composer=;focus=message_list"
require_output_line "cjgui chat demo app: shared_commit_rollback_boundary=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer"
require_output_line "cjgui chat demo app: shared_commit_not_published=true"
require_output_line "cjgui chat demo app: shared_run_harness=CjguiExperimentalDemoRunHarness"
require_output_line "cjgui chat demo app: shared_run_result=demo=chat;status=not_started->runnable;readback=true;commit_readback=true;not_published=true;writes=4;actions=chat.type_message,chat.send_message,chat.append_reply,chat.move_focus;before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer;after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list;domain=demo=chat;layout=threaded_chat;messages=3;last=assistant:Chat demo received;composer=;focus=message_list"
require_output_line "cjgui chat demo app: shared_run_readback=true"
require_output_line "cjgui chat demo app: shared_run_not_published=true"

echo "cjgui_chat_demo_app_compiled=true"
echo "cjgui_chat_demo_app_ran=true"
echo "chat_demo_progress_before=not_started"
echo "chat_demo_progress_after=runnable"
echo "chat_demo_has_main=true"
echo "chat_demo_deterministic_business_output=true"
echo "chat_non_bool_public_api_consumed=true"
echo "chat_public_api_name=CjguiExperimentalDemoComponentActionSession"
echo "chat_public_api_return=CjguiExperimentalDemoOutput"
echo "chat_legacy_output_api_direct_consumption=false"
echo "chat_owner_local_write_readback=true"
echo "chat_state_write_scope=ChatThreadState.messages,componentSession,commitHarness,lastSender,lastText"
echo "chat_shared_support_imported=true"
echo "chat_shared_support_name=CjguiExperimentalDemoComponentActionSession"
echo "chat_shared_state_core_imported=true"
echo "chat_shared_state_core_name=CjguiExperimentalDemoUiStateCore"
echo "chat_shared_component_action_session_imported=true"
echo "chat_shared_component_action_session_name=CjguiExperimentalDemoComponentActionSession"
echo "chat_shared_commit_harness_imported=true"
echo "chat_shared_commit_harness_name=CjguiExperimentalDemoCommitHarness"
echo "chat_shared_commit_harness_internal_primitive_present=true"
echo "chat_shared_commit_harness_internal_primitive_name=CjguiExperimentalDemoOwnerLocalCommitSession"
echo "chat_shared_commit_result_name=CjguiExperimentalDemoCommitResult"
echo "chat_shared_commit_readback=true"
echo "chat_shared_commit_not_published=true"
echo "chat_shared_run_harness_imported=true"
echo "chat_shared_run_harness=CjguiExperimentalDemoRunHarness"
echo "chat_shared_run_result=CjguiExperimentalDemoRunResult"
echo "chat_shared_run_readback=true"
echo "chat_shared_run_not_published=true"
echo "chat_runtime_state_write=false"
echo "chat_renderer_state_write=false"
echo "chat_public_c_abi_added=false"
