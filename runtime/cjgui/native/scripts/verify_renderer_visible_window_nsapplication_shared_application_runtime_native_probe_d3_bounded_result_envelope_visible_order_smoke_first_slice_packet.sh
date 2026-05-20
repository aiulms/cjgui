#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage134 visible-order smoke first-slice packet。
# 它消费 stage133 state token gate suite packet，并执行 fresh bounded AppKit
# visible-order smoke probe；结果仍是 isolated envelope，不写 production truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE134_TMPDIR:-/tmp/cjgui-stage134-visible-order-smoke-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice_owner.sh"
PROBE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice_probe.sh"
METAL_BINDING_SCRIPT="$SCRIPT_DIR/verify_native_bridge_metal_device_layer_binding.sh"
STAGE133_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_terminal_write_denial_production_truth_token_gate_recheck_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
PROBE_LOG="$TMP_DIR/visible-order-smoke.log"
METAL_BINDING_LOG="$TMP_DIR/metal-device-binding.log"
STAGE133_LOG="$TMP_DIR/stage133.log"
RESULT_PACKET="$TMP_DIR/stage134-visible-order-smoke-first-slice.packet"
STAGE133_SUITE_PACKET="${CJGUI_STAGE133_TOKEN_GATE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
mkdir -p "$TMP_DIR/visible-order-probe"
: > "$OWNER_LOG"
: > "$PROBE_LOG"
: > "$METAL_BINDING_LOG"
: > "$STAGE133_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$PROBE_SCRIPT" "$METAL_BINDING_SCRIPT" "$STAGE133_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage134 visible order smoke packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage134 visible order smoke packet: syntax check failed $script" >&2
    exit 4
  fi
done

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage134 visible order smoke packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage134 visible order smoke packet: owner probe failed" >&2
  echo "cjgui stage134 visible order smoke packet: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "runtime_owner_present=true"
require_file_fact "$OWNER_LOG" "bounded_visible_order_smoke_probe_required=true"

if [[ -z "$STAGE133_SUITE_PACKET" ]]; then
  if env CJGUI_STAGE133_TMPDIR="/tmp/cjgui-stage134-upstream-stage133-$$" \
    zsh "$STAGE133_SUITE_SCRIPT" > "$STAGE133_LOG" 2>&1; then
    STAGE133_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE133_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage134 visible order smoke packet: stage133 suite failed" >&2
    echo "cjgui stage134 visible order smoke packet: log=$STAGE133_LOG" >&2
    exit 7
  fi
else
  if [[ ! -f "$STAGE133_SUITE_PACKET" ]]; then
    echo "cjgui stage134 visible order smoke packet: provided stage133 packet missing $STAGE133_SUITE_PACKET" >&2
    exit 8
  fi
  echo "provided_stage133_suite_packet_used=true" > "$STAGE133_LOG"
fi

if [[ -z "$STAGE133_SUITE_PACKET" || ! -f "$STAGE133_SUITE_PACKET" ]]; then
  echo "cjgui stage134 visible order smoke packet: missing stage133 suite packet" >&2
  exit 9
fi

for fact in \
  "stage133_production_truth_token_gate_recheck_first_slice_suite_passed=true" \
  "renderer_state_write_token_gate_recheck_ready=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE133_SUITE_PACKET" "$fact"
done

set +e
env TMPDIR="$TMP_DIR/visible-order-probe" zsh "$PROBE_SCRIPT" > "$PROBE_LOG" 2>&1
probe_exit="$?"
set -e
if [[ "$probe_exit" != "0" && "$probe_exit" != "20" ]]; then
  echo "cjgui stage134 visible order smoke packet: visible-order smoke probe failed" >&2
  echo "cjgui stage134 visible order smoke packet: exit=$probe_exit log=$PROBE_LOG" >&2
  exit 10
fi

nsapplication_observed="$(fact_value "$PROBE_LOG" "nsapplication_shared_application_observed")"
activation_policy_set="$(fact_value "$PROBE_LOG" "activation_policy_set")"
nswindow_created="$(fact_value "$PROBE_LOG" "nswindow_created")"
nsview_created="$(fact_value "$PROBE_LOG" "nsview_created")"
content_view_attached="$(fact_value "$PROBE_LOG" "nsview_content_view_attached")"
visible_order_called="$(fact_value "$PROBE_LOG" "visible_order_smoke_called")"
visible_order_observed="$(fact_value "$PROBE_LOG" "visible_order_smoke_observed")"
auto_close_observed="$(fact_value "$PROBE_LOG" "visible_order_auto_close_cleanup_observed")"
failure_domain="$(fact_value "$PROBE_LOG" "visible_order_smoke_failure_domain")"
probe_route="$(fact_value "$PROBE_LOG" "visible_order_smoke_probe")"

if [[ "$probe_exit" == "0" &&
      "$probe_route" == "passed" &&
      "$nsapplication_observed" == "true" &&
      "$nswindow_created" == "true" &&
      "$nsview_created" == "true" &&
      "$content_view_attached" == "true" &&
      "$visible_order_called" == "true" &&
      "$visible_order_observed" == "true" &&
      "$auto_close_observed" == "true" ]]; then
  route_classification="visible_order_smoke_observed"
else
  route_classification="host_or_session_visible_order_limit_classified"
fi

if ! zsh "$METAL_BINDING_SCRIPT" > "$METAL_BINDING_LOG" 2>&1; then
  echo "cjgui stage134 visible order smoke packet: metal binding reprobe failed" >&2
  echo "cjgui stage134 visible order smoke packet: log=$METAL_BINDING_LOG" >&2
  exit 11
fi
metal_default_device_available="$(fact_value "$METAL_BINDING_LOG" "metal_default_device_available")"
metal_device_binding_probe="$(fact_value "$METAL_BINDING_LOG" "metal_device_binding_probe")"
if [[ "$metal_device_binding_probe" == "passed" ]]; then
  visible_order_to_metal_next_gap="none_metal_device_binding_available"
elif [[ "$metal_device_binding_probe" == "skipped_no_device" ]]; then
  visible_order_to_metal_next_gap="metal_device_unavailable"
else
  visible_order_to_metal_next_gap="metal_device_binding_probe_unclassified"
fi

{
  echo "stage134_visible_order_smoke_first_slice_packet_version=1"
  echo "stage133_token_gate_suite_packet=$STAGE133_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "probe_log=$PROBE_LOG"
  echo "metal_binding_log=$METAL_BINDING_LOG"
  echo "stage133_renderer_state_write_token_gate_recheck_consumed=true"
  echo "bounded_visible_order_smoke_probe_executed=true"
  echo "visible_order_smoke_route_classification=$route_classification"
  echo "visible_order_smoke_probe_exit_code=$probe_exit"
  echo "visible_order_smoke_failure_domain=$failure_domain"
  echo "nsapplication_shared_application_observed=$nsapplication_observed"
  echo "activation_policy_set=$activation_policy_set"
  echo "nswindow_created=$nswindow_created"
  echo "nsview_created=$nsview_created"
  echo "nsview_content_view_attached=$content_view_attached"
  echo "visible_order_smoke_called=$visible_order_called"
  echo "visible_order_smoke_observed=$visible_order_observed"
  echo "visible_order_auto_close_cleanup_observed=$auto_close_observed"
  echo "metal_device_required=false"
  echo "metal_device_binding_reprobe_executed=true"
  echo "metal_default_device_available=$metal_default_device_available"
  echo "metal_device_binding_probe=$metal_device_binding_probe"
  echo "visible_order_to_metal_next_gap=$visible_order_to_metal_next_gap"
  echo "drawable_requested=false"
  echo "render_command_encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "first_frame_observed=false"
  echo "positive_live_probe_observed=false"
  echo "nonzero_frame_hash_observed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_admission_ready=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=production_next_drawable_readiness_reprobe_after_visible_order_smoke"
  echo "stage134_visible_order_smoke_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage134 visible order smoke packet: route_classification=$route_classification"
echo "cjgui stage134 visible order smoke packet: visible_order_smoke_first_slice_packet_path=$RESULT_PACKET"
echo "cjgui stage134 visible order smoke packet: visible_order_smoke_observed=$visible_order_observed"
echo "cjgui stage134 visible order smoke packet: renderer_state_write=false"
