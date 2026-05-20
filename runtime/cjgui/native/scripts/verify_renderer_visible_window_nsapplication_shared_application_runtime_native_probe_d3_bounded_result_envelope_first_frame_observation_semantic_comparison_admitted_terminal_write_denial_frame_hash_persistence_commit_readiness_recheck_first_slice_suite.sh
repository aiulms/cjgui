#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage132 positive-probe backing-store commit
# predicate / token result envelope / frame-hash persistence commit readiness
# recheck 连续阶段包 focused suite。它验证 backing-store token 只由正向
# live probe + nonzero frame hash + 无宿主限制 + 无 harness gap 共同打开。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE132_TMPDIR:-/tmp/cjgui-stage132-persistence-commit-recheck-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"

SCRIPT_PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial"
SRC_PREFIX="runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial"

PREDICATE_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_frame_hash_persistence_commit_predicate_first_slice_owner.sh"
TOKEN_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_backing_store_token_result_first_slice_owner.sh"
RECHECK_OWNER="$SCRIPT_DIR/${SCRIPT_PREFIX}_frame_hash_persistence_commit_recheck_first_slice_owner.sh"
PREDICATE_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_frame_hash_persistence_commit_predicate_first_slice_packet.sh"
TOKEN_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_backing_store_token_result_first_slice_packet.sh"
RECHECK_PACKET_SCRIPT="$SCRIPT_DIR/${SCRIPT_PREFIX}_frame_hash_persistence_commit_recheck_first_slice_packet.sh"

PREDICATE_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_frame_hash_persistence_commit_predicate_first_slice.cj"
TOKEN_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_backing_store_token_result_first_slice.cj"
RECHECK_OWNER_FILE="$ROOT_DIR/src/${SRC_PREFIX}_frame_hash_persistence_commit_recheck_first_slice.cj"

PREDICATE_OWNER_LOG="$TMP_DIR/predicate-owner.log"
TOKEN_OWNER_LOG="$TMP_DIR/token-owner.log"
RECHECK_OWNER_LOG="$TMP_DIR/recheck-owner.log"
PREDICATE_PACKET_LOG="$TMP_DIR/predicate-packet.log"
TOKEN_PACKET_LOG="$TMP_DIR/token-packet.log"
RECHECK_PACKET_LOG="$TMP_DIR/recheck-packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage132-frame-hash-persistence-commit-readiness-recheck-first-slice-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$PREDICATE_OWNER_LOG"
: > "$TOKEN_OWNER_LOG"
: > "$RECHECK_OWNER_LOG"
: > "$PREDICATE_PACKET_LOG"
: > "$TOKEN_PACKET_LOG"
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
    echo "cjgui stage132 persistence commit recheck suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in \
  "$PREDICATE_OWNER" \
  "$TOKEN_OWNER" \
  "$RECHECK_OWNER" \
  "$PREDICATE_PACKET_SCRIPT" \
  "$TOKEN_PACKET_SCRIPT" \
  "$RECHECK_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage132 persistence commit recheck suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage132 persistence commit recheck suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$PREDICATE_OWNER" > "$PREDICATE_OWNER_LOG" 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: predicate owner failed" >&2
  echo "cjgui stage132 persistence commit recheck suite: log=$PREDICATE_OWNER_LOG" >&2
  exit 6
fi
if ! zsh "$TOKEN_OWNER" > "$TOKEN_OWNER_LOG" 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: token owner failed" >&2
  echo "cjgui stage132 persistence commit recheck suite: log=$TOKEN_OWNER_LOG" >&2
  exit 7
fi
if ! zsh "$RECHECK_OWNER" > "$RECHECK_OWNER_LOG" 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: recheck owner failed" >&2
  echo "cjgui stage132 persistence commit recheck suite: log=$RECHECK_OWNER_LOG" >&2
  exit 8
fi

for fact in \
  "positive_probe_backing_store_commit_predicate_ready=true" \
  "backing_store_commit_requires_positive_probe=true" \
  "backing_store_commit_requires_nonzero_frame_hash=true"; do
  require_file_fact "$PREDICATE_OWNER_LOG" "$fact"
done
for fact in \
  "backing_store_token_result_envelope_ready=true" \
  "backing_store_token_issue_denied=true" \
  "backing_store_token_issued=false"; do
  require_file_fact "$TOKEN_OWNER_LOG" "$fact"
done
for fact in \
  "frame_hash_persistence_commit_readiness_recheck_ready=true" \
  "frame_hash_persistence_commit_still_blocked_by_token_result=true" \
  "frame_hash_persisted=false"; do
  require_file_fact "$RECHECK_OWNER_LOG" "$fact"
done

if ! env CJGUI_STAGE132_TMPDIR="/tmp/cjgui-stage132-suite-predicate-$$" \
  zsh "$PREDICATE_PACKET_SCRIPT" > "$PREDICATE_PACKET_LOG" 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: predicate packet failed" >&2
  echo "cjgui stage132 persistence commit recheck suite: log=$PREDICATE_PACKET_LOG" >&2
  exit 9
fi
predicate_packet="$(grep -Eo 'positive_probe_backing_store_commit_predicate_packet_path=[^[:space:]]+' "$PREDICATE_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$predicate_packet" || ! -f "$predicate_packet" ]]; then
  echo "cjgui stage132 persistence commit recheck suite: missing predicate packet" >&2
  exit 10
fi

if ! env CJGUI_STAGE132_TMPDIR="/tmp/cjgui-stage132-suite-token-$$" \
  CJGUI_STAGE132_POSITIVE_PROBE_BACKING_STORE_COMMIT_PREDICATE_PACKET="$predicate_packet" \
  zsh "$TOKEN_PACKET_SCRIPT" > "$TOKEN_PACKET_LOG" 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: token packet failed" >&2
  echo "cjgui stage132 persistence commit recheck suite: log=$TOKEN_PACKET_LOG" >&2
  exit 11
fi
token_packet="$(grep -Eo 'backing_store_token_result_envelope_packet_path=[^[:space:]]+' "$TOKEN_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$token_packet" || ! -f "$token_packet" ]]; then
  echo "cjgui stage132 persistence commit recheck suite: missing token packet" >&2
  exit 12
fi

if ! env CJGUI_STAGE132_TMPDIR="/tmp/cjgui-stage132-suite-recheck-$$" \
  CJGUI_STAGE132_BACKING_STORE_TOKEN_RESULT_ENVELOPE_PACKET="$token_packet" \
  zsh "$RECHECK_PACKET_SCRIPT" > "$RECHECK_PACKET_LOG" 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: recheck packet failed" >&2
  echo "cjgui stage132 persistence commit recheck suite: log=$RECHECK_PACKET_LOG" >&2
  exit 13
fi
recheck_packet="$(grep -Eo 'frame_hash_persistence_commit_readiness_recheck_packet_path=[^[:space:]]+' "$RECHECK_PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$recheck_packet" || ! -f "$recheck_packet" ]]; then
  echo "cjgui stage132 persistence commit recheck suite: missing recheck packet" >&2
  exit 14
fi

for fact in \
  "stage132_positive_probe_backing_store_commit_predicate_first_slice_packet_passed=true" \
  "positive_probe_backing_store_commit_predicate_ready=true" \
  "positive_live_probe_observed=false" \
  "nonzero_frame_hash_observed=false" \
  "host_runtime_limitation_absent=false" \
  "backing_store_commit_predicate_satisfied=false" \
  "backing_store_token_issued=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$predicate_packet" "$fact"
done
for fact in \
  "stage132_backing_store_token_result_envelope_first_slice_packet_passed=true" \
  "backing_store_token_result_envelope_ready=true" \
  "backing_store_token_issue_denied=true" \
  "backing_store_token_issued=false" \
  "backing_store_token_denial_reason=missing_positive_live_probe_or_nonzero_frame_hash_or_host_limit" \
  "frame_hash_persistence_commit_recheck_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$token_packet" "$fact"
done
for fact in \
  "stage132_frame_hash_persistence_commit_readiness_recheck_first_slice_packet_passed=true" \
  "frame_hash_persistence_commit_readiness_recheck_ready=true" \
  "frame_hash_persistence_commit_still_blocked_by_token_result=true" \
  "frame_hash_persistence_commit_admitted=false" \
  "frame_hash_persisted=false" \
  "result_envelope_promoted_to_production_truth=false" \
  "renderer_state_write_admission_ready=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$recheck_packet" "$fact"
done

for owner_file in \
  "$PREDICATE_OWNER_FILE" \
  "$TOKEN_OWNER_FILE" \
  "$RECHECK_OWNER_FILE"; do
  if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$owner_file" >/dev/null 2>&1; then
    echo "cjgui stage132 persistence commit recheck suite: public or foreign declaration found in $owner_file" >&2
    exit 15
  fi
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$owner_file" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
    echo "cjgui stage132 persistence commit recheck suite: forbidden native/render/capture token found in $owner_file" >&2
    exit 16
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: protected path modified" >&2
  exit 17
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: cjpm unavailable" >&2
  exit 18
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage132 persistence commit recheck suite: runtime package build failed" >&2
  echo "cjgui stage132 persistence commit recheck suite: log=$BUILD_LOG" >&2
  exit 19
fi

positive_live_probe="$(fact_value "$predicate_packet" "positive_live_probe_observed")"
nonzero_hash="$(fact_value "$predicate_packet" "nonzero_frame_hash_observed")"
host_absent="$(fact_value "$predicate_packet" "host_runtime_limitation_absent")"
harness_absent="$(fact_value "$predicate_packet" "cjgui_harness_gap_absent")"
host_limit="$(fact_value "$predicate_packet" "host_runtime_limitation_detected")"
harness_gap="$(fact_value "$predicate_packet" "cjgui_harness_gap_detected")"
runtime_native_probe_execution="$(fact_value "$recheck_packet" "runtime_native_probe_execution")"
token_denial_reason="$(fact_value "$token_packet" "backing_store_token_denial_reason")"
persistence_block_reason="$(fact_value "$recheck_packet" "frame_hash_persistence_commit_block_reason")"

{
  echo "stage132_frame_hash_persistence_commit_readiness_recheck_first_slice_suite_version=1"
  echo "predicate_owner_log=$PREDICATE_OWNER_LOG"
  echo "token_owner_log=$TOKEN_OWNER_LOG"
  echo "recheck_owner_log=$RECHECK_OWNER_LOG"
  echo "predicate_packet_log=$PREDICATE_PACKET_LOG"
  echo "token_packet_log=$TOKEN_PACKET_LOG"
  echo "recheck_packet_log=$RECHECK_PACKET_LOG"
  echo "positive_probe_backing_store_commit_predicate_packet=$predicate_packet"
  echo "backing_store_token_result_envelope_packet=$token_packet"
  echo "frame_hash_persistence_commit_readiness_recheck_packet=$recheck_packet"
  echo "build_log=$BUILD_LOG"
  echo "stage132_positive_probe_backing_store_commit_predicate_owner_probe_passed=true"
  echo "stage132_backing_store_token_result_envelope_owner_probe_passed=true"
  echo "stage132_frame_hash_persistence_commit_readiness_recheck_owner_probe_passed=true"
  echo "stage132_positive_probe_backing_store_commit_predicate_packet_passed=true"
  echo "stage132_backing_store_token_result_envelope_packet_passed=true"
  echo "stage132_frame_hash_persistence_commit_readiness_recheck_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage132_public_foreign_scan_passed=true"
  echo "stage132_forbidden_native_render_token_scan_passed=true"
  echo "stage132_protected_path_scan_passed=true"
  echo "positive_probe_backing_store_commit_predicate_ready=true"
  echo "positive_live_probe_observed=$positive_live_probe"
  echo "nonzero_frame_hash_observed=$nonzero_hash"
  echo "host_runtime_limitation_absent=$host_absent"
  echo "cjgui_harness_gap_absent=$harness_absent"
  echo "host_runtime_limitation_detected=$host_limit"
  echo "cjgui_harness_gap_detected=$harness_gap"
  echo "backing_store_commit_predicate_satisfied=false"
  echo "backing_store_token_result_envelope_ready=true"
  echo "backing_store_token_issue_denied=true"
  echo "backing_store_token_denial_reason=$token_denial_reason"
  echo "backing_store_token_issued=false"
  echo "frame_hash_persistence_commit_readiness_recheck_ready=true"
  echo "frame_hash_persistence_commit_still_blocked_by_token_result=true"
  echo "frame_hash_persistence_commit_block_reason=$persistence_block_reason"
  echo "frame_hash_persistence_commit_admitted=false"
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
  echo "next_route=frame_hash_persistence_positive_probe_materialization_or_production_truth_token_gate_recheck_first_slice"
  echo "stage132_frame_hash_persistence_commit_readiness_recheck_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage132 persistence commit recheck suite: route_classification=stage132_frame_hash_persistence_commit_readiness_recheck_first_slice_suite"
echo "cjgui stage132 persistence commit recheck suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage132 persistence commit recheck suite: backing_store_token_issued=false"
echo "cjgui stage132 persistence commit recheck suite: renderer_state_write=false"
