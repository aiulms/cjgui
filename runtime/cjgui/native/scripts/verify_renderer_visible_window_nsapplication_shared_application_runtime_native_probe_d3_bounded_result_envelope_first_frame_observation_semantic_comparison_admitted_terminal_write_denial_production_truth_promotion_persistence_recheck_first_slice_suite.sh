#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage131 frame-hash persistence backing-store
# contract / persistence result envelope / production-truth promotion recheck
# 连续阶段包 focused suite。它验证 backing-store contract 是 non-mutating
# source-owned input，仍不持久化真实 hash value，也不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE131_TMPDIR:-/tmp/cjgui-stage131-persistence-recheck-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

SCRIPT_PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial"
SRC_PREFIX="runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial"

CONTRACT_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_frame_hash_persistence_backing_store_contract_first_slice_owner.sh"
PERSISTENCE_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_frame_hash_persistence_result_envelope_first_slice_owner.sh"
RECHECK_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_production_truth_promotion_persistence_recheck_first_slice_owner.sh"
CONTRACT_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_frame_hash_persistence_backing_store_contract_first_slice_packet.sh"
PERSISTENCE_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_frame_hash_persistence_result_envelope_first_slice_packet.sh"
RECHECK_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_production_truth_promotion_persistence_recheck_first_slice_packet.sh"

CONTRACT_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_frame_hash_persistence_backing_store_contract_first_slice.cj"
PERSISTENCE_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_frame_hash_persistence_result_envelope_first_slice.cj"
RECHECK_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_production_truth_promotion_persistence_recheck_first_slice.cj"

CONTRACT_OWNER_LOG="$TMP_DIR/contract-owner.log"
PERSISTENCE_OWNER_LOG="$TMP_DIR/persistence-owner.log"
RECHECK_OWNER_LOG="$TMP_DIR/recheck-owner.log"
CONTRACT_PACKET_LOG="$TMP_DIR/contract-packet.log"
PERSISTENCE_PACKET_LOG="$TMP_DIR/persistence-packet.log"
RECHECK_PACKET_LOG="$TMP_DIR/recheck-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage131-production-truth-promotion-persistence-recheck-first-slice-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$CONTRACT_OWNER_LOG"
: > "$PERSISTENCE_OWNER_LOG"
: > "$RECHECK_OWNER_LOG"
: > "$CONTRACT_PACKET_LOG"
: > "$PERSISTENCE_PACKET_LOG"
: > "$RECHECK_PACKET_LOG"
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
    echo "cjgui stage131 persistence recheck suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in \
  "$CONTRACT_OWNER" \
  "$PERSISTENCE_OWNER" \
  "$RECHECK_OWNER" \
  "$CONTRACT_PACKET_SCRIPT" \
  "$PERSISTENCE_PACKET_SCRIPT" \
  "$RECHECK_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage131 persistence recheck suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage131 persistence recheck suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$CONTRACT_OWNER" > "$CONTRACT_OWNER_LOG" 2>&1; then
  echo "cjgui stage131 persistence recheck suite: backing-store contract owner failed" >&2
  echo "cjgui stage131 persistence recheck suite: log=$CONTRACT_OWNER_LOG" >&2
  exit 6
fi
if ! zsh "$PERSISTENCE_OWNER" > "$PERSISTENCE_OWNER_LOG" 2>&1; then
  echo "cjgui stage131 persistence recheck suite: persistence result owner failed" >&2
  echo "cjgui stage131 persistence recheck suite: log=$PERSISTENCE_OWNER_LOG" >&2
  exit 7
fi
if ! zsh "$RECHECK_OWNER" > "$RECHECK_OWNER_LOG" 2>&1; then
  echo "cjgui stage131 persistence recheck suite: promotion recheck owner failed" >&2
  echo "cjgui stage131 persistence recheck suite: log=$RECHECK_OWNER_LOG" >&2
  exit 8
fi

for fact in \
  "frame_hash_persistence_backing_store_contract_ready=true" \
  "backing_store_contract_non_mutating=true" \
  "hash_value_redaction_boundary_defined=true"; do
  require_file_fact "$CONTRACT_OWNER_LOG" "$fact"
done
for fact in \
  "frame_hash_persistence_result_envelope_ready=true" \
  "frame_hash_persistence_result_fail_closed=true" \
  "frame_hash_persisted=false"; do
  require_file_fact "$PERSISTENCE_OWNER_LOG" "$fact"
done
for fact in \
  "production_truth_promotion_persistence_recheck_ready=true" \
  "production_truth_promotion_still_blocked_by_hash_persistence=true" \
  "result_envelope_promoted_to_production_truth=false"; do
  require_file_fact "$RECHECK_OWNER_LOG" "$fact"
done

if ! env CJGUI_STAGE131_TMPDIR="/tmp/cjgui-stage131-suite-contract-$$" \
  zsh "$CONTRACT_PACKET_SCRIPT" > "$CONTRACT_PACKET_LOG" 2>&1; then
  echo "cjgui stage131 persistence recheck suite: backing-store contract packet failed" >&2
  echo "cjgui stage131 persistence recheck suite: log=$CONTRACT_PACKET_LOG" >&2
  exit 9
fi
contract_packet="$(grep -Eo 'backing_store_contract_packet_path=[^[:space:]]+' "$CONTRACT_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$contract_packet" || ! -f "$contract_packet" ]]; then
  echo "cjgui stage131 persistence recheck suite: missing backing-store contract packet" >&2
  exit 10
fi

if ! env CJGUI_STAGE131_TMPDIR="/tmp/cjgui-stage131-suite-persistence-$$" \
  CJGUI_STAGE131_BACKING_STORE_CONTRACT_PACKET="$contract_packet" \
  zsh "$PERSISTENCE_PACKET_SCRIPT" > "$PERSISTENCE_PACKET_LOG" 2>&1; then
  echo "cjgui stage131 persistence recheck suite: persistence result packet failed" >&2
  echo "cjgui stage131 persistence recheck suite: log=$PERSISTENCE_PACKET_LOG" >&2
  exit 11
fi
persistence_packet="$(grep -Eo 'frame_hash_persistence_result_packet_path=[^[:space:]]+' "$PERSISTENCE_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$persistence_packet" || ! -f "$persistence_packet" ]]; then
  echo "cjgui stage131 persistence recheck suite: missing persistence result packet" >&2
  exit 12
fi

if ! env CJGUI_STAGE131_TMPDIR="/tmp/cjgui-stage131-suite-recheck-$$" \
  CJGUI_STAGE131_FRAME_HASH_PERSISTENCE_RESULT_PACKET="$persistence_packet" \
  zsh "$RECHECK_PACKET_SCRIPT" > "$RECHECK_PACKET_LOG" 2>&1; then
  echo "cjgui stage131 persistence recheck suite: promotion persistence recheck packet failed" >&2
  echo "cjgui stage131 persistence recheck suite: log=$RECHECK_PACKET_LOG" >&2
  exit 13
fi
recheck_packet="$(grep -Eo 'production_truth_promotion_persistence_recheck_packet_path=[^[:space:]]+' "$RECHECK_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$recheck_packet" || ! -f "$recheck_packet" ]]; then
  echo "cjgui stage131 persistence recheck suite: missing promotion persistence recheck packet" >&2
  exit 14
fi

for fact in \
  "stage131_frame_hash_persistence_backing_store_contract_first_slice_packet_passed=true" \
  "frame_hash_persistence_backing_store_contract_ready=true" \
  "backing_store_contract_non_mutating=true" \
  "backing_store_token_issued=false" \
  "frame_hash_value_redacted=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$contract_packet" "$fact"
done
for fact in \
  "stage131_frame_hash_persistence_result_envelope_first_slice_packet_passed=true" \
  "frame_hash_persistence_result_envelope_ready=true" \
  "frame_hash_persistence_result_fail_closed=true" \
  "frame_hash_persisted=false" \
  "frame_hash_persistence_backing_store_contract_consumed=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$persistence_packet" "$fact"
done
for fact in \
  "stage131_production_truth_promotion_persistence_recheck_first_slice_packet_passed=true" \
  "production_truth_promotion_persistence_recheck_ready=true" \
  "production_truth_promotion_still_blocked_by_hash_persistence=true" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write_admission_ready=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$recheck_packet" "$fact"
done

for owner_file in \
  "$CONTRACT_OWNER_FILE" \
  "$PERSISTENCE_OWNER_FILE" \
  "$RECHECK_OWNER_FILE"; do
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$owner_file" >/dev/null 2>&1; then
    echo "cjgui stage131 persistence recheck suite: public or foreign declaration found in $owner_file" >&2
    exit 15
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$owner_file" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
    echo "cjgui stage131 persistence recheck suite: forbidden native/render/capture token found in $owner_file" >&2
    exit 16
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage131 persistence recheck suite: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage131 persistence recheck suite: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage131 persistence recheck suite: runtime package build failed" >&2
  echo "cjgui stage131 persistence recheck suite: log=$BUILD_LOG" >&2
  exit 19
fi

probe_positive="$(fact_value "$contract_packet" "current_shell_bounded_probe_positive")"
host_limit="$(fact_value "$contract_packet" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$contract_packet" "cjgui_harness_gap_detected")"
positive_probe_frame_hash_input="$(fact_value "$contract_packet" "positive_probe_frame_hash_input_available")"
runtime_native_probe_execution="$(fact_value "$recheck_packet" "runtime_native_probe_execution")"
promotion_block_reason="$(fact_value "$recheck_packet" "production_truth_promotion_block_reason")"

{
  echo "stage131_production_truth_promotion_persistence_recheck_first_slice_suite_version=1"
  echo "contract_owner_log=$CONTRACT_OWNER_LOG"
  echo "persistence_owner_log=$PERSISTENCE_OWNER_LOG"
  echo "recheck_owner_log=$RECHECK_OWNER_LOG"
  echo "contract_packet_log=$CONTRACT_PACKET_LOG"
  echo "persistence_packet_log=$PERSISTENCE_PACKET_LOG"
  echo "recheck_packet_log=$RECHECK_PACKET_LOG"
  echo "backing_store_contract_packet=$contract_packet"
  echo "frame_hash_persistence_result_packet=$persistence_packet"
  echo "production_truth_promotion_persistence_recheck_packet=$recheck_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage131_backing_store_contract_owner_probe_passed=true"
  echo "stage131_frame_hash_persistence_result_owner_probe_passed=true"
  echo "stage131_production_truth_promotion_persistence_recheck_owner_probe_passed=true"
  echo "stage131_backing_store_contract_packet_passed=true"
  echo "stage131_frame_hash_persistence_result_packet_passed=true"
  echo "stage131_production_truth_promotion_persistence_recheck_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage131_public_foreign_scan_passed=true"
  echo "stage131_forbidden_native_render_token_scan_passed=true"
  echo "stage131_protected_path_scan_passed=true"
  echo "frame_hash_persistence_backing_store_contract_ready=true"
  echo "backing_store_contract_non_mutating=true"
  echo "backing_store_token_issued=false"
  echo "frame_hash_persistence_result_envelope_ready=true"
  echo "frame_hash_persistence_result_fail_closed=true"
  echo "production_truth_promotion_persistence_recheck_ready=true"
  echo "production_truth_promotion_still_blocked_by_hash_persistence=true"
  echo "production_truth_promotion_block_reason=$promotion_block_reason"
  echo "positive_probe_frame_hash_input_available=$positive_probe_frame_hash_input"
  echo "current_shell_bounded_probe_positive=$probe_positive"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "frame_hash_value_redacted=true"
  echo "frame_hash_value_logged=false"
  echo "frame_hash_persisted=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "renderer_state_write_admission_ready=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "next_route=frame_hash_persistence_positive_probe_backing_store_commit_predicate_first_slice"
  echo "stage131_production_truth_promotion_persistence_recheck_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage131 persistence recheck suite: route_classification=stage131_production_truth_promotion_persistence_recheck_first_slice_suite"
echo "cjgui stage131 persistence recheck suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage131 persistence recheck suite: result_envelope_promoted_to_production_truth=false"
echo "cjgui stage131 persistence recheck suite: renderer_state_write=false"
