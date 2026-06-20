#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI Todo demo app.
# Scope: compile and run runtime/cjgui/demo/todo_app.cj against temporary packages built from shared demo support sources.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/todo_app.cj"
API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_todo_demo_api.cj"
SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
OUTPUT_SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj"
UI_STATE_CORE_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj"
COMPONENT_ACTION_SESSION_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj"
COMMIT_SESSION_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_owner_local_commit_session.cj"
RUN_HARNESS_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_run_harness.cj"
TMP_DIR="${CJGUI_TODO_DEMO_TMPDIR:-/private/tmp/cjgui-todo-demo-app}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
BUILD_DIR="$TMP_DIR/build"
PROBE_PACKAGE_DIR="$TMP_DIR/package"
PROBE_API_PACKAGE_DIR="$TMP_DIR/cjgui-api"
OUTPUT_LOG="$TMP_DIR/todo-demo-output.log"
EXECUTABLE="$BUILD_DIR/cjgui_todo_demo_app"

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

require_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui todo demo app verification: missing output line: $expected" >&2
    echo "cjgui todo demo app verification: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 10
  fi
}

if [[ ! -f "$DEMO_SRC" ]]; then
  echo "cjgui todo demo app verification: missing demo source $DEMO_SRC" >&2
  exit 2
fi

if [[ ! -f "$SUPPORT_SRC" ]]; then
  echo "cjgui todo demo app verification: missing shared support source $SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$OUTPUT_SUPPORT_SRC" ]]; then
  echo "cjgui todo demo app verification: missing shared output support source $OUTPUT_SUPPORT_SRC" >&2
  exit 2
fi

if [[ ! -f "$UI_STATE_CORE_SRC" ]]; then
  echo "cjgui todo demo app verification: missing shared UI state core source $UI_STATE_CORE_SRC" >&2
  exit 2
fi

if [[ ! -f "$COMPONENT_ACTION_SESSION_SRC" ]]; then
  echo "cjgui todo demo app verification: missing shared component action session source $COMPONENT_ACTION_SESSION_SRC" >&2
  exit 2
fi

if [[ ! -f "$COMMIT_SESSION_SRC" ]]; then
  echo "cjgui todo demo app verification: missing shared commit session source $COMMIT_SESSION_SRC" >&2
  exit 2
fi

if [[ ! -f "$RUN_HARNESS_SRC" ]]; then
  echo "cjgui todo demo app verification: missing shared run harness source $RUN_HARNESS_SRC" >&2
  exit 2
fi

if ! grep -F "public class CjguiExperimentalDemoInteractionTrace" "$SUPPORT_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func recordAction" "$SUPPORT_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared interaction trace support declaration" >&2
  exit 4
fi

if ! grep -F "public class CjguiExperimentalDemoOutput" "$OUTPUT_SUPPORT_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoOutputBuilder" "$OUTPUT_SUPPORT_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func buildFromTrace" "$OUTPUT_SUPPORT_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared output builder declaration" >&2
  exit 4
fi

if ! grep -F "public class CjguiExperimentalDemoUiStateCore" "$UI_STATE_CORE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func applyLayout" "$UI_STATE_CORE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func applyStyle" "$UI_STATE_CORE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func typeInput" "$UI_STATE_CORE_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func moveFocus" "$UI_STATE_CORE_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared UI state core declaration" >&2
  exit 4
fi

if ! grep -F "public class CjguiExperimentalDemoComponentActionSession" "$COMPONENT_ACTION_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func recordComponentAction" "$COMPONENT_ACTION_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func buildOutput" "$COMPONENT_ACTION_SESSION_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared component action session declaration" >&2
  exit 4
fi

if ! grep -F "public class CjguiExperimentalDemoCommitResult" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoOwnerLocalCommitSession" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoCommitHarness" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func commitComponentAction" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func rollbackBoundary" "$COMMIT_SESSION_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func resultMatches" "$COMMIT_SESSION_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared owner-local commit session declaration" >&2
  exit 4
fi

if ! grep -F "public class CjguiExperimentalDemoRunResult" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public class CjguiExperimentalDemoRunHarness" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func finishRun" "$RUN_HARNESS_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func finishCommittedSessionRun" "$RUN_HARNESS_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared run harness declaration" >&2
  exit 4
fi

if ! grep -F "main(): Int64" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing demo main" >&2
  exit 3
fi

if ! grep -F "import cjgui.demo_support.{CjguiExperimentalDemoComponentActionSession, CjguiExperimentalDemoOutput}" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness, CjguiExperimentalDemoCommitResult}" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "import cjgui.demo_support.{CjguiExperimentalDemoRunHarness, CjguiExperimentalDemoRunResult}" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "buildSharedOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "finishCommittedSessionRun" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "CjguiExperimentalDemoComponentActionSession" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "let commitHarness: CjguiExperimentalDemoCommitHarness" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "let runHarness: CjguiExperimentalDemoRunHarness" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "commitHarness.resultMatches" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "runResult.runnable" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "sharedUiState()" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared output builder consumption" >&2
  exit 4
fi

if grep -F "func buildRunResult(" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: demo-local buildRunResult wrapper must be retired" >&2
  exit 13
fi

if grep -F "func commitSharedState" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "func commitReadback" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "func commitRollbackBoundary" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: demo must use shared commit harness instead of local commit wrappers" >&2
  exit 4
fi

if grep -F "cjguiExperimentalBuildTodoDemoOutput" "$DEMO_SRC" >/dev/null 2>&1 || \
   grep -F "CjguiExperimentalTodoDemoOutput" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: demo must not directly consume legacy Todo output API" >&2
  exit 4
fi

if ! grep -F "componentSession.recordComponentAction" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "sharedComponentActions()" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared component action session consumption" >&2
  exit 4
fi

if ! grep -F "class TodoList" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "private var items" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing owner-local mutable TodoList" >&2
  exit 5
fi

if grep -E 'foreign[[:space:]]+func|cjgui_native_bridge|public[[:space:]]+(func|class|struct|enum|let|var)' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: forbidden runtime/native/public token in demo source" >&2
  exit 6
fi

ensure_toolchain
if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: cjc not found" >&2
  exit 7
fi
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: cjpm not found" >&2
  exit 8
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
  echo "cjgui todo demo app verification: CJ_GUI_SDKROOT not found" >&2
  exit 9
fi

cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_TODO_DEMO_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_todo_demo"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"

[dependencies]
  cjgui = { path = "$PROBE_API_PACKAGE_DIR" }
CJGUI_TODO_DEMO_TOML
cat > "$PROBE_API_PACKAGE_DIR/cjpm.toml" <<CJGUI_TODO_API_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
CJGUI_TODO_API_TOML
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

require_line "cjgui todo demo app: demo=todo"
require_line "cjgui todo demo app: status_before=state_writable"
require_line "cjgui todo demo app: status_after=runnable"
require_line "cjgui todo demo app: interaction=add_todo,complete_todo"
require_line "cjgui todo demo app: summary_before=items=0;first=<none>;first_done=false"
require_line "cjgui todo demo app: summary_after_add=items=1;first=Write first CJGUI todo;first_done=false"
require_line "cjgui todo demo app: summary_after_complete=items=1;first=Write first CJGUI todo;first_done=true"
require_line "cjgui todo demo app: public_api_consumed=true"
require_line "cjgui todo demo app: public_api_name=CjguiExperimentalDemoComponentActionSession"
require_line "cjgui todo demo app: public_api_output=demo=todo;readback=true;writes=2;actions=todo.add,todo.complete;before=items=0;first=<none>;first_done=false;after=items=1;first=Write first CJGUI todo;first_done=true;summary=items=1;first=Write first CJGUI todo;first_done=true"
require_line "cjgui todo demo app: shared_support=CjguiExperimentalDemoComponentActionSession"
require_line "cjgui todo demo app: shared_support_output=demo=todo;writes=2;actions=todo.add,todo.complete;before=items=0;first=<none>;first_done=false;after=items=1;first=Write first CJGUI todo;first_done=true"
require_line "cjgui todo demo app: shared_state_core=layout=todo_list;style=completed_accent;input=Write first CJGUI todo;focus=todo_first_item"
require_line "cjgui todo demo app: shared_component_action_model=CjguiExperimentalDemoComponentActionSession"
require_line "cjgui todo demo app: shared_component_action_output=demo=todo;component_actions=todo_input:todo.add,todo_item:todo.complete;ui=layout=todo_list;style=completed_accent;input=Write first CJGUI todo;focus=todo_first_item"
if grep -F "shared_commit_model=CjguiExperimentalDemoOwnerLocalCommitSession" "$OUTPUT_LOG" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: demo output must expose shared commit harness, not primitive session" >&2
  cat "$OUTPUT_LOG" >&2
  exit 21
fi
require_line "cjgui todo demo app: shared_commit_harness=CjguiExperimentalDemoCommitHarness"
require_line "cjgui todo demo app: shared_commit_output=demo=todo;component=todo_item;action=todo.commit_complete;committed=true;readback=true;writes=1;before=items=0;first=<none>;first_done=false;after=items=1;first=Write first CJGUI todo;first_done=true;readback_state=items=1;first=Write first CJGUI todo;first_done=true;rollback_state=items=0;first=<none>;first_done=false;not_published=true"
require_line "cjgui todo demo app: shared_commit_readback=items=1;first=Write first CJGUI todo;first_done=true"
require_line "cjgui todo demo app: shared_commit_rollback_boundary=items=0;first=<none>;first_done=false"
require_line "cjgui todo demo app: shared_commit_not_published=true"
require_line "cjgui todo demo app: shared_run_harness=CjguiExperimentalDemoRunHarness"
require_line "cjgui todo demo app: shared_run_result=demo=todo;status=state_writable->runnable;readback=true;commit_readback=true;not_published=true;writes=2;actions=todo.add,todo.complete"
require_line "cjgui todo demo app: shared_run_readback=true"
require_line "cjgui todo demo app: shared_run_not_published=true"
require_line "cjgui todo demo app: owner_local_write_readback=true"

if grep -E 'println\("cjgui todo demo app: (runtime_state_write|renderer_state_write|visibility_published|public_c_abi_added)=' "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: governance stop-line output must stay out of demo app" >&2
  exit 11
fi

echo "cjgui_todo_demo_app_compiled=true"
echo "cjgui_todo_demo_app_ran=true"
echo "todo_demo_progress_before=state_writable"
echo "todo_demo_progress_after=runnable"
echo "todo_main_entry_executed=true"
echo "todo_focused_verifier=verify_cjgui_todo_demo_app"
echo "todo_non_bool_public_api_consumed=true"
echo "todo_public_api_name=CjguiExperimentalDemoComponentActionSession"
echo "todo_public_api_return=CjguiExperimentalDemoOutput"
echo "todo_legacy_output_api_direct_consumption=false"
echo "todo_owner_local_write_readback=true"
echo "todo_state_write_scope=TodoList.items,nextId,componentSession"
echo "todo_shared_support_imported=true"
echo "todo_shared_support_name=CjguiExperimentalDemoComponentActionSession"
echo "todo_shared_state_core_imported=true"
echo "todo_shared_state_core_name=CjguiExperimentalDemoUiStateCore"
echo "todo_shared_component_action_session_imported=true"
echo "todo_shared_component_action_session_name=CjguiExperimentalDemoComponentActionSession"
echo "todo_shared_commit_harness_imported=true"
echo "todo_shared_commit_harness_name=CjguiExperimentalDemoCommitHarness"
echo "todo_shared_commit_harness_internal_primitive_present=true"
echo "todo_shared_commit_harness_internal_primitive_name=CjguiExperimentalDemoOwnerLocalCommitSession"
echo "todo_shared_commit_result_name=CjguiExperimentalDemoCommitResult"
echo "todo_shared_commit_readback=true"
echo "todo_shared_commit_not_published=true"
echo "todo_shared_run_harness_imported=true"
echo "todo_shared_run_harness=CjguiExperimentalDemoRunHarness"
echo "todo_shared_run_result=CjguiExperimentalDemoRunResult"
echo "todo_shared_run_readback=true"
echo "todo_shared_run_not_published=true"
echo "todo_runtime_state_write=false"
echo "todo_renderer_state_write=false"
echo "todo_public_api_available=true"
