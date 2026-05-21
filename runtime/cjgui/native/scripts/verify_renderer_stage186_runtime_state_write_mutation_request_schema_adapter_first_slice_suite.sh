#!/usr/bin/env zsh
#
# 维护注释：stage186 focused suite 验证 schema candidate ->
# mutation request schema adapter dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE186_TMPDIR:-/tmp/cjgui-stage186-runtime-state-mutation-request-schema-adapter-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage186_runtime_state_write_mutation_request_schema_adapter_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_stage186_runtime_state_write_mutation_request_schema_adapter_first_slice_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage186_runtime_state_write_mutation_request_schema_adapter_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage186-runtime-state-write-mutation-request-schema-adapter-first-slice-suite.packet"

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
    echo "cjgui stage186 runtime_state mutation request schema adapter suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage186 runtime_state mutation request schema adapter suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage186 runtime_state mutation request schema adapter suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: owner probe failed" >&2
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage186_runtime_state_mutation_request_schema_adapter_owner_present=true" \
  "runtime_state_write_mutation_request_schema_adapter_materialized=true" \
  "schema_candidate_to_mutation_request_bound=true" \
  "runtime_state_write_mutation_request_dry_run_payload_materialized=true" \
  "runtime_state_write_admission_denial_to_mutation_request_bound=true" \
  "stage187_runtime_state_write_guarded_executor_schema_preflight_input_prepared=true" \
  "runtime_state_write_mutation_request_dry_run_only=true" \
  "renderer_state_write_eligibility=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: packet failed" >&2
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'mutation_request_schema_adapter_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage186_runtime_state_mutation_request_schema_adapter_packet_passed=true" \
  "stage185_runtime_state_schema_candidate_consumed=true" \
  "runtime_state_write_mutation_request_schema_adapter_ready=true" \
  "runtime_state_write_mutation_request_schema_adapter_source_ready=true" \
  "runtime_state_write_mutation_request_schema_adapter_runtime_admitted=false" \
  "runtime_state_write_mutation_request_schema_adapter_materialized=true" \
  "schema_candidate_to_mutation_request_bound=true" \
  "runtime_state_write_mutation_request_dry_run_payload_materialized=true" \
  "runtime_state_write_admission_denial_to_mutation_request_bound=true" \
  "runtime_state_write_mutation_request_dry_run_only=true" \
  "renderer_state_write_eligibility=false" \
  "stage187_runtime_state_write_guarded_executor_schema_preflight_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "visibility_publication_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "runtime_state_write_mutation_request_schema_adapter_route_classification")"
if [[ "$route" != "runtime_state_write_mutation_request_schema_adapter_ready_write_blocked" ]]; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: unexpected route $route" >&2
  exit 9
fi

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: runtime package build failed" >&2
  echo "cjgui stage186 runtime_state mutation request schema adapter suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage186_runtime_state_mutation_request_schema_adapter_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "runtime_state_mutation_request_schema_adapter_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage186_owner_probe_passed=true"
  echo "stage186_runtime_state_mutation_request_schema_adapter_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage186_public_foreign_scan_passed=true"
  echo "stage186_forbidden_native_render_token_scan_passed=true"
  echo "stage186_protected_path_scan_passed=true"
  echo "runtime_state_write_mutation_request_schema_adapter_route_classification=$route"
  echo "runtime_state_write_mutation_request_schema_adapter_ready=true"
  echo "runtime_state_write_mutation_request_schema_adapter_source_ready=true"
  echo "runtime_state_write_mutation_request_schema_adapter_runtime_admitted=false"
  echo "runtime_state_write_mutation_request_schema_adapter_materialized=true"
  echo "schema_candidate_to_mutation_request_bound=true"
  echo "runtime_state_write_mutation_request_dry_run_payload_materialized=true"
  echo "runtime_state_write_admission_denial_to_mutation_request_bound=true"
  echo "runtime_state_write_mutation_request_dry_run_only=true"
  echo "renderer_state_write_eligibility=false"
  echo "stage187_runtime_state_write_guarded_executor_schema_preflight_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "result_envelope_promotion_token=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage187_runtime_state_write_guarded_executor_schema_preflight_after_mutation_request"
  echo "stage186_runtime_state_mutation_request_schema_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage186 runtime_state mutation request schema adapter suite: route_classification=stage186_runtime_state_mutation_request_schema_adapter_suite"
echo "cjgui stage186 runtime_state mutation request schema adapter suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage186 runtime_state mutation request schema adapter suite: runtime_state_write=false"
