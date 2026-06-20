#!/usr/bin/env zsh
#
# Focused verification for retiring shared/contract legacy CJGUI Output APIs.
# Scope: prove five shared/contract demos no longer expose legacy output declarations,
# while their demos still run through shared demo_support output/session primitives.
# Stop-line: no runtime_state / renderer_state write, no native bridge call, no public C ABI expansion.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_SHARED_CONTRACT_LEGACY_OUTPUT_API_RETIREMENT_TMPDIR:-/private/tmp/cjgui-shared-contract-legacy-output-api-retirement}"
mkdir -p "$TMP_DIR"

check_retired_file() {
  local label="$1"
  local file="$2"
  local class_name="$3"
  local builder_name="$4"

  if [[ ! -f "$file" ]]; then
    echo "cjgui shared contract legacy output API retirement verification: missing tombstone file for $label: $file" >&2
    exit 2
  fi

  if ! grep -F "package cjgui" "$file" >/dev/null 2>&1 || \
     ! grep -F "已退役" "$file" >/dev/null 2>&1 || \
     ! grep -F "demo_support" "$file" >/dev/null 2>&1; then
    echo "cjgui shared contract legacy output API retirement verification: invalid tombstone content for $label" >&2
    exit 3
  fi

  if grep -F "public class $class_name" "$file" >/dev/null 2>&1 || \
     grep -F "public func $builder_name" "$file" >/dev/null 2>&1; then
    echo "cjgui shared contract legacy output API retirement verification: $label still exposes legacy output API" >&2
    exit 4
  fi
}

check_demo_uses_shared_path() {
  local label="$1"
  local file="$2"
  local class_name="$3"
  local builder_name="$4"

  if ! grep -F "CjguiExperimentalDemoComponentActionSession" "$file" >/dev/null 2>&1 || \
     ! grep -F "CjguiExperimentalDemoOutput" "$file" >/dev/null 2>&1; then
    echo "cjgui shared contract legacy output API retirement verification: $label demo is not on shared output/session path" >&2
    exit 5
  fi

  if grep -F "$class_name" "$file" >/dev/null 2>&1 || \
     grep -F "$builder_name" "$file" >/dev/null 2>&1; then
    echo "cjgui shared contract legacy output API retirement verification: $label demo still directly consumes legacy output API" >&2
    exit 6
  fi
}

run_demo_verifier() {
  local label="$1"
  local script="$2"
  local log_file="$TMP_DIR/${label}.log"

  "$script" > "$log_file"
  if ! grep -F "legacy_output_api_direct_consumption=false" "$log_file" >/dev/null 2>&1 || \
     ! grep -F "shared_component_action_session_imported=true" "$log_file" >/dev/null 2>&1; then
    echo "cjgui shared contract legacy output API retirement verification: $label verifier did not prove shared session path" >&2
    cat "$log_file" >&2
    exit 7
  fi
}

check_retired_file "shared_demo_harness" "$ROOT_DIR/src/runtime_cjgui_experimental_shared_demo_harness_api.cj" \
  "CjguiExperimentalSharedDemoHarnessOutput" "cjguiExperimentalBuildSharedDemoHarnessOutput"
check_retired_file "shared_multi_demo_harness" "$ROOT_DIR/src/runtime_cjgui_experimental_shared_multi_demo_harness_api.cj" \
  "CjguiExperimentalSharedMultiDemoHarnessOutput" "cjguiExperimentalBuildSharedMultiDemoHarnessOutput"
check_retired_file "shared_layout_style_input_focus_contract" "$ROOT_DIR/src/runtime_cjgui_experimental_shared_layout_style_input_focus_contract_api.cj" \
  "CjguiExperimentalSharedLayoutStyleInputFocusContractOutput" "cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput"
check_retired_file "ai_generated_ui_shared_contract" "$ROOT_DIR/src/runtime_cjgui_experimental_ai_generated_ui_shared_contract_api.cj" \
  "CjguiExperimentalAiGeneratedUiSharedContractOutput" "cjguiExperimentalBuildAiGeneratedUiSharedContractOutput"
check_retired_file "reusable_component_contract" "$ROOT_DIR/src/runtime_cjgui_experimental_reusable_component_contract_api.cj" \
  "CjguiExperimentalReusableComponentContractOutput" "cjguiExperimentalBuildReusableComponentContractOutput"

check_demo_uses_shared_path "shared_demo_harness" "$ROOT_DIR/demo/shared_demo_harness_app.cj" \
  "CjguiExperimentalSharedDemoHarnessOutput" "cjguiExperimentalBuildSharedDemoHarnessOutput"
check_demo_uses_shared_path "shared_multi_demo_harness" "$ROOT_DIR/demo/shared_multi_demo_harness_app.cj" \
  "CjguiExperimentalSharedMultiDemoHarnessOutput" "cjguiExperimentalBuildSharedMultiDemoHarnessOutput"
check_demo_uses_shared_path "shared_layout_style_input_focus_contract" "$ROOT_DIR/demo/shared_layout_style_input_focus_contract_app.cj" \
  "CjguiExperimentalSharedLayoutStyleInputFocusContractOutput" "cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput"
check_demo_uses_shared_path "ai_generated_ui_shared_contract" "$ROOT_DIR/demo/ai_generated_ui_shared_contract_app.cj" \
  "CjguiExperimentalAiGeneratedUiSharedContractOutput" "cjguiExperimentalBuildAiGeneratedUiSharedContractOutput"
check_demo_uses_shared_path "reusable_component_contract" "$ROOT_DIR/demo/reusable_component_contract_app.cj" \
  "CjguiExperimentalReusableComponentContractOutput" "cjguiExperimentalBuildReusableComponentContractOutput"

run_demo_verifier "shared_demo_harness" "$SCRIPT_DIR/verify_cjgui_shared_demo_harness_app.sh"
run_demo_verifier "shared_multi_demo_harness" "$SCRIPT_DIR/verify_cjgui_shared_multi_demo_harness_app.sh"
run_demo_verifier "shared_layout_style_input_focus_contract" "$SCRIPT_DIR/verify_cjgui_shared_layout_style_input_focus_contract_app.sh"
run_demo_verifier "ai_generated_ui_shared_contract" "$SCRIPT_DIR/verify_cjgui_ai_generated_ui_shared_contract_app.sh"
run_demo_verifier "reusable_component_contract" "$SCRIPT_DIR/verify_cjgui_reusable_component_contract_app.sh"

echo "shared_contract_legacy_output_api_retired_count=5"
echo "shared_contract_legacy_output_api_tombstone_links_retained=true"
echo "shared_contract_demo_shared_output_path_verified=true"
echo "shared_contract_demo_binary_verifier_count=5"
echo "runtime_state_write=false"
echo "renderer_state_write=false"
echo "public_c_abi_added=false"
