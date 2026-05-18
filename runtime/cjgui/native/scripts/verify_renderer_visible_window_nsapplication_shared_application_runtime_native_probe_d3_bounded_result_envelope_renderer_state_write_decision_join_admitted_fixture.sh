#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 fixture-only admitted bounded result-envelope admission
# suite packet，用于验证 join preflight 的正向 contract 形状。它不是 runtime
# native probe evidence，不升级 production truth，也不写 renderer state。
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-renderer-state-write-decision-join-admitted-fixture"
FIXTURE_PACKET="$TMP_DIR/d3-bounded-result-envelope-admission-admitted.fixture.packet"

mkdir -p "$TMP_DIR"
: > "$FIXTURE_PACKET"

{
  echo "d3_bounded_result_envelope_admission_suite_version=1"
  echo "d3_bounded_result_envelope_admission_fixture_version=1"
  echo "fixture_only=true"
  echo "fixture_promoted_to_production_truth=false"
  echo "d3_bounded_result_envelope_admission_suite_passed=true"
  echo "d3_bounded_result_envelope_admission_owner_probe_passed=true"
  echo "d3_bounded_result_envelope_admission_schema_passed=true"
  echo "d3_bounded_result_envelope_admission_classifier_passed=true"
  echo "source_build_guard_passed=true"
  echo "smoke_environment_classification=fixture_admitted_bounded_envelope"
  echo "bounded_result_envelope_admitted=true"
  echo "bounded_result_envelope_quarantined=false"
  echo "bounded_d3_runtime_native_probe_executed=true"
  echo "bounded_d3_runtime_native_probe_passed=true"
  echo "bounded_d3_runtime_native_probe_exit_code=0"
  echo "isolated_metal_device_available=true"
  echo "failure_count=0"
  echo "failure_domain=none"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=false"
  echo "fixture_runtime_native_probe_execution=false"
  echo "renderer_state_write_after_admission_allowed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "production_public_c_abi_added=false"
} > "$FIXTURE_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join admitted fixture: route_classification=d3_bounded_result_envelope_renderer_state_write_decision_join_admitted_fixture"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join admitted fixture: fixture_packet_path=$FIXTURE_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join admitted fixture: bounded_result_envelope_admitted=true"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join admitted fixture: fixture_promoted_to_production_truth=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join admitted fixture: renderer_state_write=false"
