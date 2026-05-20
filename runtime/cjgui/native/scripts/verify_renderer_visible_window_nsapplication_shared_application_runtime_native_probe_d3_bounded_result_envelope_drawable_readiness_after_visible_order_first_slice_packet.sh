#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage135 drawable readiness after visible-order packet。
# 它消费 stage134 visible-order suite packet，并在当前宿主无 Metal device 时
# fail-closed 到 command pipeline contract route，不触发 drawable acquisition。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE135_TMPDIR:-/tmp/cjgui-stage135-drawable-readiness-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_drawable_readiness_after_visible_order_first_slice_owner.sh"
STAGE134_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice_suite.sh"
METAL_BINDING_SCRIPT="$SCRIPT_DIR/verify_native_bridge_metal_device_layer_binding.sh"
DRAWABLE_NO_PRESENT_SCRIPT="$SCRIPT_DIR/verify_native_bridge_drawable_no_present_acquisition.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE134_LOG="$TMP_DIR/stage134.log"
METAL_BINDING_LOG="$TMP_DIR/metal-binding.log"
DRAWABLE_LOG="$TMP_DIR/drawable-no-present.log"
RESULT_PACKET="$TMP_DIR/stage135-drawable-readiness-after-visible-order.packet"
STAGE134_SUITE_PACKET="${CJGUI_STAGE134_VISIBLE_ORDER_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage134" "$TMP_DIR/metal-binding" "$TMP_DIR/drawable"
: > "$OWNER_LOG"
: > "$STAGE134_LOG"
: > "$METAL_BINDING_LOG"
: > "$DRAWABLE_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE134_SUITE_SCRIPT" "$METAL_BINDING_SCRIPT" "$DRAWABLE_NO_PRESENT_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage135 drawable readiness packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage135 drawable readiness packet: syntax check failed $script" >&2
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
    echo "cjgui stage135 drawable readiness packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage135 drawable readiness packet: owner probe failed" >&2
  echo "cjgui stage135 drawable readiness packet: log=$OWNER_LOG" >&2
  exit 6
fi
require_file_fact "$OWNER_LOG" "drawable_readiness_after_visible_order_owner_present=true"

if [[ -z "$STAGE134_SUITE_PACKET" ]]; then
  if env CJGUI_STAGE134_TMPDIR="$TMP_DIR/stage134" zsh "$STAGE134_SUITE_SCRIPT" > "$STAGE134_LOG" 2>&1; then
    STAGE134_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE134_LOG" | tail -1 | cut -d= -f2-)"
  else
    echo "cjgui stage135 drawable readiness packet: stage134 suite failed" >&2
    echo "cjgui stage135 drawable readiness packet: log=$STAGE134_LOG" >&2
    exit 7
  fi
else
  if [[ ! -f "$STAGE134_SUITE_PACKET" ]]; then
    echo "cjgui stage135 drawable readiness packet: provided stage134 packet missing $STAGE134_SUITE_PACKET" >&2
    exit 8
  fi
  echo "provided_stage134_visible_order_suite_packet_used=true" > "$STAGE134_LOG"
fi

if [[ -z "$STAGE134_SUITE_PACKET" || ! -f "$STAGE134_SUITE_PACKET" ]]; then
  echo "cjgui stage135 drawable readiness packet: missing stage134 suite packet" >&2
  exit 9
fi
for fact in \
  "stage134_visible_order_smoke_first_slice_suite_passed=true" \
  "visible_order_smoke_observed=true" \
  "visible_order_auto_close_cleanup_observed=true" \
  "nsapplication_window_view_chain_observed=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE134_SUITE_PACKET" "$fact"
done

if ! env TMPDIR="$TMP_DIR/metal-binding" zsh "$METAL_BINDING_SCRIPT" > "$METAL_BINDING_LOG" 2>&1; then
  echo "cjgui stage135 drawable readiness packet: metal binding reprobe failed" >&2
  echo "cjgui stage135 drawable readiness packet: log=$METAL_BINDING_LOG" >&2
  exit 10
fi

metal_default_device_available="$(fact_value "$METAL_BINDING_LOG" "metal_default_device_available")"
metal_device_binding_probe="$(fact_value "$METAL_BINDING_LOG" "metal_device_binding_probe")"
drawable_readiness_probe_executed="false"
drawable_readiness_probe="not_executed"
drawable_readiness_route_classification="blocked_by_host_metal_device_unavailable"
next_drawable_called="false"
drawable_acquired="false"
drawable_nil_observed="false"
cleanup_observed="$(fact_value "$STAGE134_SUITE_PACKET" "visible_order_auto_close_cleanup_observed")"

if [[ "$metal_device_binding_probe" == "passed" ]]; then
  drawable_readiness_probe_executed="true"
  if env TMPDIR="$TMP_DIR/drawable" zsh "$DRAWABLE_NO_PRESENT_SCRIPT" > "$DRAWABLE_LOG" 2>&1; then
    drawable_readiness_probe="passed"
    drawable_readiness_route_classification="$(fact_value "$DRAWABLE_LOG" "drawable_no_present_acquisition_route")"
    next_drawable_called="$(fact_value "$DRAWABLE_LOG" "next_drawable_called")"
    drawable_acquired="$(fact_value "$DRAWABLE_LOG" "drawable_acquired")"
    drawable_nil_observed="$(fact_value "$DRAWABLE_LOG" "drawable_nil_observed")"
    cleanup_observed="$(fact_value "$DRAWABLE_LOG" "cleanup_observed")"
  else
    echo "cjgui stage135 drawable readiness packet: drawable no-present probe failed" >&2
    echo "cjgui stage135 drawable readiness packet: log=$DRAWABLE_LOG" >&2
    exit 11
  fi
elif [[ "$metal_device_binding_probe" != "skipped_no_device" ]]; then
  drawable_readiness_route_classification="metal_binding_reprobe_unclassified"
fi

{
  echo "stage135_drawable_readiness_after_visible_order_first_slice_packet_version=1"
  echo "stage134_visible_order_smoke_suite_packet=$STAGE134_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "metal_binding_log=$METAL_BINDING_LOG"
  echo "drawable_no_present_log=$DRAWABLE_LOG"
  echo "stage134_visible_order_smoke_suite_consumed=true"
  echo "visible_order_smoke_observed=$(fact_value "$STAGE134_SUITE_PACKET" "visible_order_smoke_observed")"
  echo "visible_order_auto_close_cleanup_observed=$(fact_value "$STAGE134_SUITE_PACKET" "visible_order_auto_close_cleanup_observed")"
  echo "nsapplication_window_view_chain_observed=$(fact_value "$STAGE134_SUITE_PACKET" "nsapplication_window_view_chain_observed")"
  echo "metal_device_binding_reprobe_executed=true"
  echo "metal_default_device_available=$metal_default_device_available"
  echo "metal_device_binding_probe=$metal_device_binding_probe"
  echo "drawable_readiness_route_classification=$drawable_readiness_route_classification"
  echo "drawable_readiness_probe_executed=$drawable_readiness_probe_executed"
  echo "drawable_readiness_probe=$drawable_readiness_probe"
  echo "next_drawable_called=$next_drawable_called"
  echo "drawable_acquired=$drawable_acquired"
  echo "drawable_nil_observed=$drawable_nil_observed"
  echo "cleanup_observed=$cleanup_observed"
  echo "command_pipeline_contract_route_prepared=true"
  echo "command_queue_created=false"
  echo "command_buffer_created=false"
  echo "render_command_encoder_created=false"
  echo "draw_called=false"
  echo "commit_called=false"
  echo "present_called=false"
  echo "first_frame_observed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_admission_ready=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=production_next_command_pipeline_contract_after_drawable_readiness"
  echo "stage135_drawable_readiness_after_visible_order_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage135 drawable readiness packet: route_classification=$drawable_readiness_route_classification"
echo "cjgui stage135 drawable readiness packet: drawable_readiness_packet_path=$RESULT_PACKET"
echo "cjgui stage135 drawable readiness packet: next_drawable_called=$next_drawable_called"
echo "cjgui stage135 drawable readiness packet: renderer_state_write=false"
