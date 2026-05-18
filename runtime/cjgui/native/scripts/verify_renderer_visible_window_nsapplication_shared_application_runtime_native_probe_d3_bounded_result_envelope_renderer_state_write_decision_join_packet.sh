#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 bounded result-envelope admission suite packet 与
# independent write-decision contract suite packet，生成 guarded join preflight
# packet。current shell 没有 admitted bounded envelope 时只分类为 join 未就绪，
# 不把它当作脚本失败。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-renderer-state-write-decision-join-packet"
ADMISSION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_suite.sh"
WRITE_DECISION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_result_envelope_renderer_state_write_decision_contract_suite.sh"
ADMISSION_LOG="$TMP_DIR/d3-bounded-result-envelope-admission-suite.log"
WRITE_DECISION_LOG="$TMP_DIR/d3-result-envelope-renderer-state-write-decision-contract-suite.log"
JOIN_PACKET="$TMP_DIR/d3-bounded-result-envelope-renderer-state-write-decision-join.packet"
ADMISSION_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SUITE_PACKET:-}"
WRITE_DECISION_SUITE_PACKET="${CJGUI_D3_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_CONTRACT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$ADMISSION_LOG"
: > "$WRITE_DECISION_LOG"
: > "$JOIN_PACKET"

for script in "$ADMISSION_SUITE_SCRIPT" "$WRITE_DECISION_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: missing executable script $script" >&2
    exit 3
  fi
done

if [[ -n "$ADMISSION_SUITE_PACKET" ]]; then
  if [[ ! -f "$ADMISSION_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: admission suite packet missing $ADMISSION_SUITE_PACKET" >&2
    exit 4
  fi
  {
    echo "admission_suite_packet_used=true"
    echo "suite_packet_path=$ADMISSION_SUITE_PACKET"
    cat "$ADMISSION_SUITE_PACKET"
  } > "$ADMISSION_LOG"
else
  if ! env TMPDIR="$TMP_DIR/admission" zsh "$ADMISSION_SUITE_SCRIPT" > "$ADMISSION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: admission suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: log=$ADMISSION_LOG" >&2
    exit 5
  fi
fi

admission_suite_packet="${ADMISSION_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$ADMISSION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$admission_suite_packet" || ! -f "$admission_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: missing admission suite packet" >&2
  exit 6
fi

if [[ -n "$WRITE_DECISION_SUITE_PACKET" ]]; then
  if [[ ! -f "$WRITE_DECISION_SUITE_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: write-decision suite packet missing $WRITE_DECISION_SUITE_PACKET" >&2
    exit 7
  fi
  {
    echo "write_decision_suite_packet_used=true"
    echo "suite_packet_path=$WRITE_DECISION_SUITE_PACKET"
    cat "$WRITE_DECISION_SUITE_PACKET"
  } > "$WRITE_DECISION_LOG"
else
  SHORT_WRITE_DECISION_TMP="/tmp/cjgui-stage104-write-decision-suite-${$}"
  mkdir -p "$SHORT_WRITE_DECISION_TMP"
  if ! env TMPDIR="$SHORT_WRITE_DECISION_TMP" zsh "$WRITE_DECISION_SUITE_SCRIPT" > "$WRITE_DECISION_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: write-decision suite failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: log=$WRITE_DECISION_LOG" >&2
    exit 8
  fi
fi

write_decision_suite_packet="${WRITE_DECISION_SUITE_PACKET:-$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$WRITE_DECISION_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$write_decision_suite_packet" || ! -f "$write_decision_suite_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: missing write-decision suite packet" >&2
  exit 9
fi

required_admission_facts=(
  "d3_bounded_result_envelope_admission_suite_passed=true"
  "result_envelope_promoted_to_production_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write_after_admission_allowed=false"
  "renderer_state_write=false"
)
for fact in "${required_admission_facts[@]}"; do
  if ! grep -F "$fact" "$admission_suite_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: missing admission fact $fact" >&2
    exit 10
  fi
done

required_write_decision_facts=(
  "d3_result_envelope_renderer_state_write_decision_contract_suite_passed=true"
  "renderer_state_write_decision_contract_ready=true"
  "write_decision_contract_is_independent=true"
  "renderer_state_write_after_two_key_join_allowed=false"
  "renderer_state_write=false"
)
for fact in "${required_write_decision_facts[@]}"; do
  if ! grep -F "$fact" "$write_decision_suite_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: missing write-decision fact $fact" >&2
    exit 11
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: protected path modified" >&2
  exit 12
fi

bounded_result_envelope_admitted="$(grep -Eo '^bounded_result_envelope_admitted=(true|false)' "$admission_suite_packet" | tail -1 | cut -d= -f2)"
runtime_native_probe_execution="$(grep -Eo '^runtime_native_probe_execution=(true|false)' "$admission_suite_packet" | tail -1 | cut -d= -f2)"
admitted_fixture_input_used="false"
if grep -F "fixture_only=true" "$admission_suite_packet" >/dev/null 2>&1; then
  admitted_fixture_input_used="true"
fi
if [[ "$bounded_result_envelope_admitted" == "true" ]]; then
  bounded_admission_input_missing="false"
  guarded_join_preflight_ready="true"
else
  bounded_admission_input_missing="true"
  guarded_join_preflight_ready="false"
fi

{
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_packet_version=1"
  echo "bounded_result_envelope_admission_suite_packet=$admission_suite_packet"
  echo "write_decision_contract_suite_packet=$write_decision_suite_packet"
  echo "bounded_admission_input_consumed=true"
  echo "bounded_result_envelope_admitted=$bounded_result_envelope_admitted"
  echo "bounded_admission_input_missing=$bounded_admission_input_missing"
  echo "admitted_fixture_input_used=$admitted_fixture_input_used"
  echo "independent_write_decision_contract_consumed=true"
  echo "renderer_state_write_decision_contract_ready=true"
  echo "write_decision_contract_is_independent=true"
  echo "write_decision_contract_is_not_write_permission=true"
  echo "guarded_write_decision_join_preflight_ready=$guarded_join_preflight_ready"
  echo "production_write_admission_after_join_preflight_required=true"
  echo "renderer_state_write_after_join_preflight_allowed=false"
  echo "renderer_state_write_blocked_until_production_write_admission=true"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_packet_passed=true"
  echo "code_failure_domain=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$JOIN_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: route_classification=d3_bounded_result_envelope_renderer_state_write_decision_join_packet"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: join_packet_path=$JOIN_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: bounded_result_envelope_admitted=$bounded_result_envelope_admitted"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: guarded_write_decision_join_preflight_ready=$guarded_join_preflight_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: renderer_state_write_after_join_preflight_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join packet: renderer_state_write=false"
