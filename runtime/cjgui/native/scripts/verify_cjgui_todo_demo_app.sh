#!/usr/bin/env zsh
#
# Focused verification for the independent CJGUI Todo demo app.
# Scope: compile and run runtime/cjgui/demo/todo_app.cj against a temporary package built from the production Todo demo API source.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
DEMO_SRC="$ROOT_DIR/demo/todo_app.cj"
API_SRC="$ROOT_DIR/src/runtime_cjgui_experimental_todo_demo_api.cj"
SUPPORT_SRC="$ROOT_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
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

if [[ ! -f "$API_SRC" ]]; then
  echo "cjgui todo demo app verification: missing API source $API_SRC" >&2
  exit 2
fi

if [[ ! -f "$SUPPORT_SRC" ]]; then
  echo "cjgui todo demo app verification: missing shared support source $SUPPORT_SRC" >&2
  exit 2
fi

if ! grep -F "public class CjguiExperimentalTodoDemoOutput" "$API_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func cjguiExperimentalBuildTodoDemoOutput" "$API_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing non-Bool public Todo demo API declaration" >&2
  exit 4
fi

if ! grep -F "public class CjguiExperimentalDemoInteractionTrace" "$SUPPORT_SRC" >/dev/null 2>&1 || \
   ! grep -F "public func recordAction" "$SUPPORT_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared interaction trace support declaration" >&2
  exit 4
fi

if ! grep -F "main(): Int64" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing demo main" >&2
  exit 3
fi

if ! grep -F "import cjgui.{CjguiExperimentalTodoDemoOutput, cjguiExperimentalBuildTodoDemoOutput}" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "import cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace}" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "cjguiExperimentalBuildTodoDemoOutput" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing non-Bool public API consumption" >&2
  exit 4
fi

if ! grep -F "CjguiExperimentalDemoInteractionTrace" "$DEMO_SRC" >/dev/null 2>&1 || \
   ! grep -F "sharedTrace.recordAction" "$DEMO_SRC" >/dev/null 2>&1; then
  echo "cjgui todo demo app verification: missing shared interaction trace consumption" >&2
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
cp "$DEMO_SRC" "$PROBE_PACKAGE_DIR/src/main.cj"
cp "$API_SRC" "$PROBE_API_PACKAGE_DIR/src/runtime_cjgui_experimental_todo_demo_api.cj"
cp "$SUPPORT_SRC" "$PROBE_API_PACKAGE_DIR/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj"
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm build --target-dir "$BUILD_DIR/cjpm-target" --skip-script
  if [[ -d "${CANGJIE_HOME:-}/runtime/lib/darwin_x86_64_cjnative" ]]; then
    export DYLD_LIBRARY_PATH="${CANGJIE_HOME}/runtime/lib/darwin_x86_64_cjnative:${DYLD_LIBRARY_PATH:-}"
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
require_line "cjgui todo demo app: public_api_name=cjguiExperimentalBuildTodoDemoOutput"
require_line "cjgui todo demo app: public_api_output=items=1;first=Write first CJGUI todo;first_done=true"
require_line "cjgui todo demo app: shared_support=CjguiExperimentalDemoInteractionTrace"
require_line "cjgui todo demo app: shared_support_output=demo=todo;writes=2;actions=todo.add,todo.complete;before=items=0;first=<none>;first_done=false;after=items=1;first=Write first CJGUI todo;first_done=true"
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
echo "todo_public_api_name=cjguiExperimentalBuildTodoDemoOutput"
echo "todo_owner_local_write_readback=true"
echo "todo_state_write_scope=TodoList.items,nextId"
echo "todo_shared_support_imported=true"
echo "todo_shared_support_name=CjguiExperimentalDemoInteractionTrace"
echo "todo_runtime_state_write=false"
echo "todo_renderer_state_write=false"
echo "todo_public_api_available=true"
