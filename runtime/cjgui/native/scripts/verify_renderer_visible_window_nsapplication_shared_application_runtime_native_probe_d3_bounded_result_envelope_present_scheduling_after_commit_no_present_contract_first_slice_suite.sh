#!/usr/bin/env zsh
#
# 维护注释：本脚本是 stage141 present scheduling after stage140 commit
# no-present contract focused suite。它消费 stage140 suite packet，且继续阻断
# first-frame production truth / renderer state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE141_TMPDIR:-/tmp/cjgui-stage141-present-scheduling-after-commit-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
PREFIX="verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_scheduling_after_commit_no_present_contract_first_slice"
OWNER_SCRIPT="$SCRIPT_DIR/${PREFIX}_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/${PREFIX}_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_scheduling_after_commit_no_present_contract_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage141-present-scheduling-after-commit-no-present-contract-suite.packet"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
: > "$OWNER_LOG"
: > "$PACKET_LOG"
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
    echo "cjgui stage141 present scheduling suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

for script in "$OWNER_SCRIPT" "$PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage141 present scheduling suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage141 present scheduling suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage141 present scheduling suite: owner probe failed" >&2
  echo "cjgui stage141 present scheduling suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage141_present_scheduling_after_commit_no_present_contract_owner_present=true" \
  "stage140_commit_no_present_packet_required=true" \
  "positive_commit_before_present_scheduling_required=true" \
  "bounded_present_scheduling_probe_required=true" \
  "first_frame_observed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage141 present scheduling suite: packet failed" >&2
  echo "cjgui stage141 present scheduling suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'present_scheduling_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage141 present scheduling suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage141_present_scheduling_after_commit_no_present_contract_first_slice_packet_passed=true" \
  "stage140_commit_no_present_packet_consumed=true" \
  "positive_commit_before_present_scheduling_required=true" \
  "first_frame_observed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "present_scheduling_route_classification")"
if [[ "$route" == "present_scheduling_after_commit_no_present_contract_ready" ]]; then
  for fact in \
    "bounded_present_scheduling_executed=true" \
    "current_shell_present_scheduling_ready=true" \
    "drawable_present_scheduled=true" \
    "commit_called=true" \
    "gpu_work_submitted=true"; do
    require_file_fact "$packet" "$fact"
  done
elif [[ "$route" == "host_metal_device_unavailable" ]]; then
  for fact in \
    "bounded_present_scheduling_executed=false" \
    "current_shell_present_scheduling_ready=false" \
    "drawable_present_scheduled=false" \
    "first_frame_observed=false"; do
    require_file_fact "$packet" "$fact"
  done
elif [[ "$route" == "blocked_pending_commit_no_present_contract" ]]; then
  require_file_fact "$packet" "bounded_present_scheduling_should_execute=false"
else
  echo "cjgui stage141 present scheduling suite: unexpected route $route" >&2
  exit 9
fi

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage141 present scheduling suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage141 present scheduling suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage141 present scheduling suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage141 present scheduling suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage141 present scheduling suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage141 present scheduling suite: runtime package build failed" >&2
  echo "cjgui stage141 present scheduling suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage141_present_scheduling_after_commit_no_present_contract_first_slice_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "present_scheduling_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage141_owner_probe_passed=true"
  echo "stage141_present_scheduling_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage141_public_foreign_scan_passed=true"
  echo "stage141_forbidden_native_render_token_scan_passed=true"
  echo "stage141_protected_path_scan_passed=true"
  echo "present_scheduling_route_classification=$route"
  grep -E '^stage140_command_buffer_commit_no_present_route_classification=' "$packet" | tail -1
  grep -E '^commit_called=' "$packet" | tail -1
  grep -E '^bounded_present_scheduling_should_execute=' "$packet" | tail -1
  grep -E '^bounded_present_scheduling_executed=' "$packet" | tail -1
  grep -E '^current_shell_present_scheduling_ready=' "$packet" | tail -1
  grep -E '^drawable_present_scheduled=' "$packet" | tail -1
  grep -E '^present_called=' "$packet" | tail -1
  grep -E '^gpu_work_submitted=' "$packet" | tail -1
  grep -E '^bounded_gpu_submission_completed=' "$packet" | tail -1
  echo "first_frame_observed=false"
  echo "production_render_truth=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=first_frame_observation_after_present_scheduling_contract"
  echo "stage141_present_scheduling_after_commit_no_present_contract_first_slice_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage141 present scheduling suite: route_classification=stage141_present_scheduling_after_commit_no_present_contract_first_slice_suite"
echo "cjgui stage141 present scheduling suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage141 present scheduling suite: present_scheduling_route=$route"
echo "cjgui stage141 present scheduling suite: renderer_state_write=false"
