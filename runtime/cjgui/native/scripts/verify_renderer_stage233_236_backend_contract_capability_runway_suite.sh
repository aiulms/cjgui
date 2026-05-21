#!/usr/bin/env zsh
#
# 维护注释：stage233-236 focused suite 串联 backend contract/capability
# ledger、submission token dry-run、no-submit command envelope 与 runway readiness。
# 输入是 stage232 suite packet；输出仍不执行 backend、不写 state、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE233_236_TMPDIR:-/tmp/cjgui-stage233-236-backend-contract-capability-runway-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
STAGE232_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage229_232_backend_handoff_dry_run_suite.sh"
STAGE232_LOG="$TMP_DIR/stage232.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage236-backend-runway-readiness-decision-suite.packet"
STAGE232_SUITE_PACKET="${CJGUI_STAGE232_BACKEND_HANDOFF_READINESS_DECISION_SUITE_PACKET:-}"
ALLOW_STAGE232_REGEN="${CJGUI_STAGE233_236_ALLOW_SLOW_STAGE232_REGEN:-false}"

OWNER_SCRIPTS=(
  "$SCRIPT_DIR/verify_renderer_stage233_backend_contract_capability_ledger_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage234_backend_submission_token_dry_run_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage235_backend_command_envelope_owner.sh"
  "$SCRIPT_DIR/verify_renderer_stage236_backend_runway_readiness_decision_owner.sh"
)

OWNER_SOURCES=(
  "$ROOT_DIR/src/runtime_renderer_stage233_backend_contract_capability_ledger.cj"
  "$ROOT_DIR/src/runtime_renderer_stage234_backend_submission_token_dry_run.cj"
  "$ROOT_DIR/src/runtime_renderer_stage235_backend_command_envelope.cj"
  "$ROOT_DIR/src/runtime_renderer_stage236_backend_runway_readiness_decision.cj"
)

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$STAGE232_LOG"
: > "$BUILD_LOG"
: > "$SUITE_PACKET"

cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

ensure_toolchain() {
  if command -v cjpm >/dev/null 2>&1 && command -v cjc >/dev/null 2>&1; then
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

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage233-236 backend contract capability runway suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "${OWNER_SCRIPTS[@]}" "$STAGE232_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage233-236 backend contract capability runway suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage233-236 backend contract capability runway suite: syntax check failed $script" >&2
    exit 4
  fi
done

owner_logs=()
for script in "${OWNER_SCRIPTS[@]}"; do
  log="$TMP_DIR/$(basename "$script" .sh).log"
  owner_logs+=("$log")
  if ! zsh "$script" > "$log" 2>&1; then
    echo "cjgui stage233-236 backend contract capability runway suite: owner probe failed $script" >&2
    echo "cjgui stage233-236 backend contract capability runway suite: log=$log" >&2
    exit 6
  fi
done

require_file_fact "${owner_logs[1]}" "renderer_backend_contract_capability_ledger_materialized=true"
require_file_fact "${owner_logs[2]}" "renderer_backend_submission_token_dry_run_materialized=true"
require_file_fact "${owner_logs[3]}" "renderer_backend_command_envelope_materialized=true"
require_file_fact "${owner_logs[4]}" "renderer_backend_runway_readiness_decision_materialized=true"

if [[ -n "$STAGE232_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE232_SUITE_PACKET" ]]; then
    echo "cjgui stage233-236 backend contract capability runway suite: provided stage232 packet missing $STAGE232_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_stage232_suite_packet_used=true"
    echo "stage232_suite_packet_path=$STAGE232_SUITE_PACKET"
  } > "$STAGE232_LOG"
elif [[ "$ALLOW_STAGE232_REGEN" == "true" ]]; then
  if ! env CJGUI_STAGE229_232_TMPDIR="$TMP_DIR/stage229-232" zsh "$STAGE232_SUITE_SCRIPT" > "$STAGE232_LOG" 2>&1; then
    echo "cjgui stage233-236 backend contract capability runway suite: stage229-232 suite failed" >&2
    echo "cjgui stage233-236 backend contract capability runway suite: log=$STAGE232_LOG" >&2
    exit 8
  fi
  STAGE232_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE232_LOG" | tail -1 | cut -d= -f2-)"
else
  echo "cjgui stage233-236 backend contract capability runway suite: missing stage232 packet; set CJGUI_STAGE232_BACKEND_HANDOFF_READINESS_DECISION_SUITE_PACKET or CJGUI_STAGE233_236_ALLOW_SLOW_STAGE232_REGEN=true" >&2
  exit 7
fi

stage232_packet="$STAGE232_SUITE_PACKET"
if [[ -z "$stage232_packet" || ! -f "$stage232_packet" ]]; then
  echo "cjgui stage233-236 backend contract capability runway suite: missing stage232 packet" >&2
  exit 9
fi
for fact in \
  "stage229_232_backend_handoff_dry_run_suite_passed=true" \
  "renderer_backend_handoff_readiness_decision_materialized=true" \
  "stage233_renderer_backend_contract_capability_input_prepared=true" \
  "minimal_ui_framework_backend_handoff_input_prepared=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "backend_ready_truth=false" \
  "backend_implementation=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false" \
  "visibility_published=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$stage232_packet" "$fact"
done

for src in "${OWNER_SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "cjgui stage233-236 backend contract capability runway suite: missing owner source $src" >&2
    exit 10
  fi
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$src" >/dev/null 2>&1; then
    echo "cjgui stage233-236 backend contract capability runway suite: public or foreign declaration found in $src" >&2
    exit 11
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$src" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
    echo "cjgui stage233-236 backend contract capability runway suite: forbidden native/render token found in $src" >&2
    exit 12
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage233-236 backend contract capability runway suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage233-236 backend contract capability runway suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage233-236 backend contract capability runway suite: runtime package build failed" >&2
  echo "cjgui stage233-236 backend contract capability runway suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage232_route="$(fact_value "$stage232_packet" "next_route")"

{
  echo "stage233_236_backend_contract_capability_runway_suite_version=1"
  echo "stage232_backend_handoff_readiness_decision_suite_packet=$stage232_packet"
  echo "stage232_next_route=$stage232_route"
  echo "build_log=$BUILD_LOG"
  echo "stage233_backend_contract_capability_ledger_owner_passed=true"
  echo "stage234_backend_submission_token_dry_run_owner_passed=true"
  echo "stage235_backend_command_envelope_owner_passed=true"
  echo "stage236_backend_runway_readiness_decision_owner_passed=true"
  echo "stage232_backend_handoff_readiness_decision_consumed=true"
  echo "renderer_backend_no_render_contract_readiness_consumed=true"
  echo "renderer_backend_no_render_capability_readiness_consumed=true"
  echo "renderer_backend_contract_capability_ledger_materialized=true"
  echo "backend_handoff_bound_to_no_render_contract=true"
  echo "no_render_contract_bound_to_capability_readiness=true"
  echo "stage234_renderer_backend_submission_token_dry_run_input_prepared=true"
  echo "renderer_backend_submission_token_dry_run_materialized=true"
  echo "backend_submission_token_bound_to_contract_capability_ledger=true"
  echo "backend_submission_token_non_executable=true"
  echo "stage235_renderer_backend_command_envelope_input_prepared=true"
  echo "renderer_backend_command_envelope_materialized=true"
  echo "backend_command_envelope_bound_to_non_executable_submission_token=true"
  echo "backend_command_envelope_bound_to_rollback_boundary=true"
  echo "backend_command_envelope_no_submit=true"
  echo "stage236_renderer_backend_runway_readiness_decision_input_prepared=true"
  echo "backend_contract_capability_ledger_joined_with_submission_token_dry_run=true"
  echo "backend_submission_token_dry_run_joined_with_command_envelope=true"
  echo "renderer_backend_runway_readiness_decision_materialized=true"
  echo "stage237_minimal_backend_adapter_preview_input_prepared=true"
  echo "minimal_ui_framework_backend_runway_advanced=true"
  echo "runtime_package_build_passed=true"
  echo "stage233_236_public_foreign_scan_passed=true"
  echo "stage233_236_forbidden_native_render_token_scan_passed=true"
  echo "stage233_236_protected_path_scan_passed=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "backend_implementation=false"
  echo "concrete_platform_capability_promise=false"
  echo "platform_command_buffer=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage237_minimal_backend_adapter_preview_after_backend_runway_readiness_decision"
  echo "stage233_236_backend_contract_capability_runway_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage233-236 backend contract capability runway suite: route_classification=stage236_backend_runway_readiness_decision_ready"
echo "cjgui stage233-236 backend contract capability runway suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage233-236 backend contract capability runway suite: stage237_minimal_backend_adapter_preview_input_prepared=true"
echo "cjgui stage233-236 backend contract capability runway suite: renderer_state_write=false"
