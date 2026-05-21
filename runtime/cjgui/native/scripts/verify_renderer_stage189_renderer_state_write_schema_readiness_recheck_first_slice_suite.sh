#!/usr/bin/env zsh
#
# 维护注释：stage189 focused suite 验证 stage188 visibility publication
# schema bridge -> renderer-state schema-readiness recheck。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE189_TMPDIR:-/tmp/cjgui-stage189-renderer-state-schema-readiness-recheck-suite-$$}"
PS_SHIM_DIR="$TMP_DIR/ps-shim"
CLANG_CACHE_DIR="$TMP_DIR/clang-cache"
BUILD_TARGET_DIR="$TMP_DIR/target"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage189_renderer_state_write_schema_readiness_recheck_first_slice_owner.sh"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_stage189_renderer_state_write_schema_readiness_recheck_first_slice_packet.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage189_renderer_state_write_schema_readiness_recheck_first_slice.cj"
OWNER_LOG="$TMP_DIR/owner.log"
PACKET_LOG="$TMP_DIR/packet.log"
BUILD_LOG="$TMP_DIR/cjpm-build.log"
SUITE_PACKET="$TMP_DIR/stage189-renderer-state-write-schema-readiness-recheck-first-slice-suite.packet"

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
    echo "cjgui stage189 renderer_state schema readiness recheck suite: missing fact $fact in $file" >&2
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
    echo "cjgui stage189 renderer_state schema readiness recheck suite: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage189 renderer_state schema readiness recheck suite: syntax check failed $script" >&2
    exit 4
  fi
done

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: owner probe failed" >&2
  echo "cjgui stage189 renderer_state schema readiness recheck suite: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage189_renderer_state_schema_readiness_recheck_owner_present=true" \
  "runtime_state_write_schema_candidate_rechecked=true" \
  "runtime_state_write_mutation_request_payload_rechecked=true" \
  "runtime_state_write_guarded_executor_predicates_rechecked=true" \
  "visibility_publication_schema_ledger_rechecked=true" \
  "renderer_state_write_schema_readiness_ledger_materialized=true" \
  "renderer_state_write_missing_predicate_ledger_materialized=true" \
  "stage190_renderer_state_write_positive_predicate_fixture_input_prepared=true" \
  "schema_readiness_recheck_non_mutating=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if ! zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: packet failed" >&2
  echo "cjgui stage189 renderer_state schema readiness recheck suite: log=$PACKET_LOG" >&2
  exit 7
fi
packet="$(grep -Eo 'schema_readiness_recheck_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
if [[ -z "$packet" || ! -f "$packet" ]]; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: missing packet" >&2
  exit 8
fi
for fact in \
  "stage189_renderer_state_schema_readiness_recheck_packet_passed=true" \
  "stage188_runtime_state_visibility_publication_schema_bridge_consumed=true" \
  "renderer_state_write_schema_readiness_recheck_ready=true" \
  "renderer_state_write_schema_readiness_recheck_source_ready=true" \
  "renderer_state_write_schema_readiness_recheck_runtime_admitted=false" \
  "runtime_state_write_schema_candidate_rechecked=true" \
  "runtime_state_write_mutation_request_payload_rechecked=true" \
  "runtime_state_write_guarded_executor_predicates_rechecked=true" \
  "visibility_publication_schema_ledger_rechecked=true" \
  "renderer_state_write_schema_readiness_ledger_materialized=true" \
  "renderer_state_write_missing_predicate_ledger_materialized=true" \
  "stage190_renderer_state_write_positive_predicate_fixture_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "semantic_runtime_admission=false" \
  "result_envelope_promotion_token=false" \
  "write_token=false" \
  "guarded_executor_predicates_satisfied=false" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "renderer_state_write_eligibility=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$packet" "$fact"
done

route="$(fact_value "$packet" "renderer_state_write_schema_readiness_recheck_route_classification")"
if [[ "$route" != "renderer_state_write_schema_readiness_recheck_ready_missing_predicates_materialized" ]]; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: unexpected route $route" >&2
  exit 9
fi

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: missing source owner $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: public or foreign declaration found" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: forbidden native/render token found in owner" >&2
  exit 12
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: protected production bridge/state path modified" >&2
  exit 13
fi

ensure_toolchain
if ! command -v cjpm >/dev/null 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: cjpm unavailable" >&2
  exit 14
fi
if ! (
  cd "$ROOT_DIR" &&
  env CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR" cjpm build --target-dir "$BUILD_TARGET_DIR" --skip-script
) > "$BUILD_LOG" 2>&1; then
  echo "cjgui stage189 renderer_state schema readiness recheck suite: runtime package build failed" >&2
  echo "cjgui stage189 renderer_state schema readiness recheck suite: log=$BUILD_LOG" >&2
  exit 15
fi

{
  echo "stage189_renderer_state_schema_readiness_recheck_suite_version=1"
  echo "owner_log=$OWNER_LOG"
  echo "packet_log=$PACKET_LOG"
  echo "renderer_state_schema_readiness_recheck_packet=$packet"
  echo "build_log=$BUILD_LOG"
  echo "stage189_owner_probe_passed=true"
  echo "stage189_renderer_state_schema_readiness_recheck_packet_passed=true"
  echo "runtime_package_build_passed=true"
  echo "stage189_public_foreign_scan_passed=true"
  echo "stage189_forbidden_native_render_token_scan_passed=true"
  echo "stage189_protected_path_scan_passed=true"
  echo "renderer_state_write_schema_readiness_recheck_route_classification=$route"
  echo "renderer_state_write_schema_readiness_recheck_ready=true"
  echo "renderer_state_write_schema_readiness_recheck_source_ready=true"
  echo "renderer_state_write_schema_readiness_recheck_runtime_admitted=false"
  echo "runtime_state_write_schema_candidate_rechecked=true"
  echo "runtime_state_write_mutation_request_payload_rechecked=true"
  echo "runtime_state_write_guarded_executor_predicates_rechecked=true"
  echo "visibility_publication_schema_ledger_rechecked=true"
  echo "renderer_state_write_schema_readiness_ledger_materialized=true"
  echo "renderer_state_write_missing_predicate_ledger_materialized=true"
  echo "stage190_renderer_state_write_positive_predicate_fixture_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "result_envelope_promotion_token=false"
  echo "write_token=false"
  echo "guarded_executor_predicates_satisfied=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write_eligibility=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage190_renderer_state_write_positive_predicate_fixture_after_schema_readiness_recheck"
  echo "stage189_renderer_state_schema_readiness_recheck_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage189 renderer_state schema readiness recheck suite: route_classification=stage189_renderer_state_schema_readiness_recheck_suite"
echo "cjgui stage189 renderer_state schema readiness recheck suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage189 renderer_state schema readiness recheck suite: runtime_state_write=false"
