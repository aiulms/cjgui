#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 visible-window NSApplication application-singleton
# CJGUI-owned lifecycle main-thread / headless fail-closed evidence probe 的
# runtime/native-readiness 证据链已经被实际执行为 probe evidence。
# Truth: 本脚本只执行既有 owner probes 并做 source / diff scans；它不新增
# readiness owner，不调用 application accessor，不扩展 native bridge，不执行
# runtime native probe，不创建 singleton，也不升级 production singleton
# ownership truth。
# Stop-line: 不调用 application singleton accessor，不创建或激活
# NSApplication，不修改 activation policy，不启动 AppKit event loop /
# bounded pump，不执行 cleanup / teardown，不创建 window / view / layer，
# 不 visible order，不 nextDrawable，不创建 command queue / buffer /
# encoder，不 render / commit / present / GPU submission，不扩 public API /
# production C ABI，不写 runtime_state.cj / cjpm.toml。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-runtime-native-readiness-probe-evidence-execution"
OUTPUT_FILE="$TMP_DIR/owner-probe-output.log"

mkdir -p "$TMP_DIR"
: > "$OUTPUT_FILE"

owner_files=(
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_first_slice.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_preflight.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_value_boundary.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_preflight.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_value_boundary.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_preflight.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_value_boundary.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_first_slice.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_closure_preflight.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_closure_value_boundary.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_closure_first_slice.cj"
  "$ROOT_DIR/src/runtime_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_closure_completion.cj"
)

owner_probes=(
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_preflight_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_first_slice_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_preflight_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_native_readiness_value_boundary_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_preflight_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_value_boundary_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_preflight_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_value_boundary_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_first_slice_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_closure_preflight_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_closure_value_boundary_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_closure_first_slice_owner.sh"
  "$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_cjgui_owned_singleton_lifecycle_main_thread_headless_fail_closed_evidence_probe_runtime_native_readiness_probe_execution_closure_completion_owner.sh"
)

for owner_file in "${owner_files[@]}"; do
  if [[ ! -f "$owner_file" ]]; then
    echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: missing owner $owner_file" >&2
    exit 3
  fi
done

for owner_probe in "${owner_probes[@]}"; do
  if [[ ! -f "$owner_probe" ]]; then
    echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: missing owner probe $owner_probe" >&2
    exit 4
  fi
  zsh "$owner_probe" >> "$OUTPUT_FILE"
done

required_probe_facts=(
  "application_singleton_accessor_call=false"
  "production_singleton_owner_implementation=false"
  "cleanup_teardown_execution=false"
  "activation_deferred=true"
  "activation_policy_mutation_deferred=true"
  "appkit_event_loop_deferred=true"
  "bounded_run_loop_pump_deferred=true"
  "visible_order_deferred=true"
  "drawable_render_deferred=true"
  "public_api_modified=false"
  "production_public_c_abi_added=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "cjpm_toml_change=false"
  "production_singleton_ownership_truth=false"
)

for fact in "${required_probe_facts[@]}"; do
  if [[ "$(grep -F "$fact" "$OUTPUT_FILE" | wc -l | tr -d ' ')" -lt "${#owner_probes[@]}" ]]; then
    echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: missing common fact $fact" >&2
    exit 5
  fi
done

if ! grep -E 'native_bridge_expansion=false|no_native_bridge_expansion_[^=]+=true' "$OUTPUT_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: missing native bridge non-expansion fact" >&2
  exit 6
fi

if ! grep -E 'runtime_probe_execution=false|runtime_native_probe_execution=false' "$OUTPUT_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: missing runtime native probe non-execution fact" >&2
  exit 7
fi

if ! grep -E 'no_singleton_creation[^=]*=true' "$OUTPUT_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: missing no singleton creation fact" >&2
  exit 8
fi

if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "${owner_files[@]}" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: forbidden runtime surface found" >&2
  exit 9
fi

for owner_file in "${owner_files[@]}"; do
  if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$owner_file" \
    | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: forbidden production application/visible/render token found in $owner_file" >&2
    exit 10
  fi
done

if git -C "$REPO_DIR" diff -U0 -- runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m \
  | grep -E '^\+' \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|terminate|stop:|run\]|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|^[+][[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|\[[[:space:]]*(NSApplication|NSWindow|NSView|CAMetalLayer)[[:space:]]+(alloc|new|init)\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: forbidden production native bridge diff found" >&2
  exit 11
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: protected path modified" >&2
  exit 12
fi

echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: owner_probe_count=${#owner_probes[@]}"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: owner_file_count=${#owner_files[@]}"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: route_classification=non_homogeneous_probe_evidence_execution"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: readiness_owner_created=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: application_singleton_accessor_call=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: native_bridge_expansion=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: runtime_native_probe_execution=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: no_singleton_creation=true"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: production_singleton_owner_implementation=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: cleanup_teardown_execution=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: production_singleton_ownership_truth=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: protected_path_modified=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: production_public_c_abi_added=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: renderer_state_write=false"
echo "cjgui renderer NSApplication application-singleton CJGUI-owned lifecycle runtime native-readiness probe evidence execution: next_runtime_native_probe_execution_requires_d3=true"
