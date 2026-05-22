#!/usr/bin/env zsh
#
# 维护注释：stage387 focused suite 消费 stage386 edited text refresh packet，
# 验证 shared text edit action commit dry-run 与 rollback preview 只停留在 owner-local 预览层。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE387_TMPDIR:-/tmp/cjgui-stage387-shared-text-edit-action-commit-dry-run-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage387-shared-text-edit-action-commit-dry-run-suite.packet"
STAGE386_SUITE_PACKET="${CJGUI_STAGE387_INPUT_PACKET:-${CJGUI_STAGE386_SHARED_TEXT_EDIT_ACTION_COMMIT_INPUT_PACKET:-${CJGUI_STAGE386_EDITED_TEXT_RENDER_REFRESH_DEMO_PROBE_SUITE_PACKET:-}}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage387_shared_text_edit_action_commit_dry_run_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage387_shared_text_edit_action_commit_dry_run.cj"
OWNER_LOG="$TMP_DIR/stage387-shared-text-edit-action-commit-dry-run-owner.log"

mkdir -p "$TMP_DIR" "$PS_SHIM_DIR" "$CLANG_CACHE_DIR" "$BUILD_TARGET_DIR"
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
    echo "cjgui stage387 shared text edit action commit dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage387 shared text edit action commit dry-run suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage386_edited_text_render_refresh_demo_probe_consumed=true" \
  "shared_text_edit_commit_intent_materialized=true" \
  "commit_intent_bound_to_todo_edited_text_delta=true" \
  "commit_intent_bound_to_settings_focus_delta=true" \
  "owner_acceptance_gate_for_text_edit_commit_materialized=true" \
  "text_edit_state_commit_dry_run_materialized=true" \
  "accepted_text_buffer_state_preview_materialized=true" \
  "settings_focus_state_preview_materialized=true" \
  "commit_dry_run_bound_to_stage383_state_update_dry_run=true" \
  "commit_dry_run_bound_to_stage386_render_refresh=true" \
  "rollback_snapshot_before_text_edit_commit_materialized=true" \
  "rejected_text_edit_rollback_preview_materialized=true" \
  "text_edit_commit_dry_run_uncommitted=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE386_SUITE_PACKET" || ! -f "$STAGE386_SUITE_PACKET" ]]; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: missing stage386 packet; set CJGUI_STAGE387_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage386_edited_text_render_refresh_demo_probe_suite_version=1" \
  "stage385_shared_text_input_focus_editing_demo_probe_consumed=true" \
  "stage384_shared_input_event_to_action_intent_adapter_demo_probe_consumed_transitively=true" \
  "route_convergence_needed=false" \
  "convergence_exit_already_materialized_by_stage381=true" \
  "edited_text_buffer_delta_consumed=true" \
  "todo_edited_text_surface_refresh_preview_materialized=true" \
  "settings_focus_surface_refresh_preview_materialized=true" \
  "caret_render_command_refresh_preview_materialized=true" \
  "edited_text_render_command_refresh_plan_materialized=true" \
  "edited_text_refresh_bound_to_stage383_render_bridge=true" \
  "edited_text_refresh_bound_to_stage384_input_adapter=true" \
  "edited_text_refresh_bound_to_stage385_editing_dry_run=true" \
  "owner_local_edited_text_state_render_dry_run_materialized=true" \
  "owner_acceptance_required=true" \
  "owner_acceptance_granted=false" \
  "backend_ready_truth=false" \
  "input_event_pipeline_enabled=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "visibility_published=false" \
  "public_component_api_added=false" \
  "native_bridge_expansion=false" \
  "production_public_c_abi_added=false"; do
  require_file_fact "$STAGE386_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage387 shared text edit action commit dry-run suite: runtime package build failed" >&2
  echo "cjgui stage387 shared text edit action commit dry-run suite: log=$BUILD_LOG" >&2
  exit 15
fi

stage386_next_route="$(fact_value "$STAGE386_SUITE_PACKET" "next_route")"

{
  echo "stage387_shared_text_edit_action_commit_dry_run_suite_version=1"
  echo "stage386_edited_text_render_refresh_demo_probe_suite_packet=$STAGE386_SUITE_PACKET"
  echo "stage386_next_route=$stage386_next_route"
  echo "build_log=$BUILD_LOG"
  echo "stage387_shared_text_edit_action_commit_dry_run_owner_passed=true"
  echo "stage386_edited_text_render_refresh_demo_probe_consumed=true"
  echo "stage385_shared_text_input_focus_editing_demo_probe_consumed_transitively=true"
  echo "route_convergence_needed=false"
  echo "convergence_exit_already_materialized_by_stage381=true"
  echo "shared_text_edit_commit_intent_materialized=true"
  echo "commit_intent_bound_to_todo_edited_text_delta=true"
  echo "commit_intent_bound_to_settings_focus_delta=true"
  echo "owner_acceptance_gate_for_text_edit_commit_materialized=true"
  echo "text_edit_state_commit_dry_run_materialized=true"
  echo "accepted_text_buffer_state_preview_materialized=true"
  echo "settings_focus_state_preview_materialized=true"
  echo "commit_dry_run_bound_to_stage383_state_update_dry_run=true"
  echo "commit_dry_run_bound_to_stage386_render_refresh=true"
  echo "rollback_snapshot_before_text_edit_commit_materialized=true"
  echo "rejected_text_edit_rollback_preview_materialized=true"
  echo "text_edit_commit_dry_run_uncommitted=true"
  echo "runtime_package_build_passed=true"
  echo "stage387_public_foreign_scan_passed=true"
  echo "stage387_forbidden_native_render_token_scan_passed=true"
  echo "stage387_protected_path_scan_passed=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "public_component_api_added=false"
  echo "layout_engine_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "shared_text_edit_action_commit_dry_run=true"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "backend_implementation=false"
  echo "concrete_platform_capability_promise=false"
  echo "platform_command_buffer=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "runtime_state_write_schema_change=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "stage388_shared_text_edit_commit_result_render_refresh_demo_probe_prepared=true"
  echo "next_route=stage388_shared_text_edit_commit_result_render_refresh_demo_probe_after_stage387"
  echo "stage387_shared_text_edit_action_commit_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage387 shared text edit action commit dry-run suite: route_classification=text_edit_commit_dry_run_ready"
echo "cjgui stage387 shared text edit action commit dry-run suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage387 shared text edit action commit dry-run suite: consumed_stage386=true"
echo "cjgui stage387 shared text edit action commit dry-run suite: renderer_state_write=false"
