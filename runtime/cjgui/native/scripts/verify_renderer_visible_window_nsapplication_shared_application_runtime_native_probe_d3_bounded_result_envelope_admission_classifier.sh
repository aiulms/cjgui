#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 bounded result-envelope admission schema，并分类该
# isolated envelope 是否可进入 admission。即使 admission=true，也不开放
# renderer-state write，不升级 production truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-admission-classifier"
SCHEMA_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_admission_schema.sh"
SCHEMA_LOG="$TMP_DIR/schema.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-admission-classifier.packet"
SCHEMA_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_ADMISSION_SCHEMA_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$SCHEMA_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$SCHEMA_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: missing executable schema script $SCHEMA_SCRIPT" >&2
  exit 3
fi

if [[ -z "$SCHEMA_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/schema" zsh "$SCHEMA_SCRIPT" > "$SCHEMA_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: schema failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: log=$SCHEMA_LOG" >&2
    exit 4
  fi
  SCHEMA_PACKET="$(grep -Eo 'schema_packet_path=[^[:space:]]+' "$SCHEMA_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$SCHEMA_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: provided schema packet missing $SCHEMA_PACKET" >&2
    exit 5
  fi
  {
    echo "provided_schema_packet_used=true"
    echo "schema_packet_path=$SCHEMA_PACKET"
  } > "$SCHEMA_LOG"
fi

if [[ -z "$SCHEMA_PACKET" || ! -f "$SCHEMA_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: missing schema packet" >&2
  exit 6
fi

required_schema_facts=(
  "d3_bounded_result_envelope_admission_schema_version=1"
  "bounded_result_envelope_schema_valid=true"
  "result_envelope_is_not_production_truth=true"
  "result_envelope_isolated_evidence_only=true"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "cjpm_toml_change=false"
)
for fact in "${required_schema_facts[@]}"; do
  if ! grep -F "$fact" "$SCHEMA_PACKET" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: missing schema fact $fact" >&2
    exit 7
  fi
done

admission_candidate="$(grep -Eo '^bounded_result_envelope_admission_candidate=(true|false)' "$SCHEMA_PACKET" | tail -1 | cut -d= -f2)"
executed="$(grep -Eo '^bounded_d3_runtime_native_probe_executed=(true|false)' "$SCHEMA_PACKET" | tail -1 | cut -d= -f2)"
passed="$(grep -Eo '^bounded_d3_runtime_native_probe_passed=(true|false)' "$SCHEMA_PACKET" | tail -1 | cut -d= -f2)"
denial_reason="$(grep -Eo '^bounded_result_envelope_admission_denial_reason=[A-Za-z0-9_]+' "$SCHEMA_PACKET" | tail -1 | cut -d= -f2)"
failure_domain="$(grep -Eo '^failure_domain=[A-Za-z0-9_]+' "$SCHEMA_PACKET" | tail -1 | cut -d= -f2)"

if [[ -z "$admission_candidate" || -z "$executed" || -z "$passed" ||
      -z "$denial_reason" || -z "$failure_domain" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: missing parsed schema facts" >&2
  exit 8
fi

bounded_result_envelope_admitted="false"
bounded_result_envelope_quarantined="true"
if [[ "$admission_candidate" == "true" ]]; then
  if [[ "$executed" != "true" || "$passed" != "true" ||
        "$failure_domain" != "none" || "$denial_reason" != "none" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: candidate has inconsistent admission facts" >&2
    exit 9
  fi
  bounded_result_envelope_admitted="true"
  bounded_result_envelope_quarantined="false"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: protected path modified" >&2
  exit 10
fi

{
  echo "d3_bounded_result_envelope_admission_classifier_version=1"
  echo "schema_packet=$SCHEMA_PACKET"
  echo "bounded_result_envelope_admission_classifier_passed=true"
  echo "bounded_result_envelope_schema_valid=true"
  echo "bounded_result_envelope_admission_candidate=$admission_candidate"
  echo "bounded_result_envelope_admitted=$bounded_result_envelope_admitted"
  echo "bounded_result_envelope_quarantined=$bounded_result_envelope_quarantined"
  echo "bounded_result_envelope_admission_denial_reason=$denial_reason"
  echo "bounded_d3_runtime_native_probe_executed=$executed"
  echo "bounded_d3_runtime_native_probe_passed=$passed"
  echo "failure_domain=$failure_domain"
  echo "result_envelope_isolated_evidence_only=true"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_singleton_ownership_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write_after_admission_allowed=false"
  echo "runtime_native_probe_execution=$executed"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: route_classification=d3_bounded_result_envelope_admission_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: bounded_result_envelope_admission_classifier_passed=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: bounded_result_envelope_admitted=$bounded_result_envelope_admitted"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: bounded_result_envelope_quarantined=$bounded_result_envelope_quarantined"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: result_envelope_promoted_to_production_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: renderer_state_write_after_admission_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: runtime_native_probe_execution=$executed"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope admission classifier: renderer_state_write=false"
