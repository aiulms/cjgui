#!/usr/bin/env zsh

# Generated-interface image lifecycle.
#
# Runs the production renderer with the test-only launch gate and fixture seams
# and drives the ORDINARY generated path (catalog declaration -> generated
# structure -> window scene transaction). It asserts, with raw markers:
#
#   COLD      the accepted binding starts `unrequested` before the first draw;
#   LOADING   a held launch gate keeps the generated node at `loading` with
#             bounded pending work;
#   READY     releasing the gate converges to `ready` AND the real drawable
#             pixel is the fixture colour (painted, not merely "ready");
#   FAILED    a declaration whose raster cannot be decoded reports `failed`, the
#             accepted structure stays at its version, and the same (key,
#             version) cannot be silently repointed at different content;
#   RECOVERY  a NEW declared version recovers to a painted image;
#   STALE     an older in-flight completion cannot repaint the accepted scene
#             after it rebinds to a newer version;
#   OTHER_WINDOW  another live window's scene advances while this one loads;
#   RELEASE   after the owner windows close, the bounded application resource
#             domain drops to zero subscribers/in-flight/pending.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  SDKROOT_PATH="$CJ_GUI_SDKROOT"
elif [[ -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  SDKROOT_PATH="$SDKROOT"
else
  SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
OUTPUT_DIR="${CJGUI_GENERATED_IMAGE_LIFECYCLE_TMPDIR:-/private/tmp/cjgui-generated-image-lifecycle}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui generated image lifecycle: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR/native"
rm -f "$OUTPUT_DIR/generated-*.png" "$OUTPUT_DIR/result.log" "$OUTPUT_DIR/manifest"

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_generated_image_lifecycle.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" \
  "$RUNTIME_DIR/src/composable_ui_composite_component.cj" \
  "$RUNTIME_DIR/src/composable_ui_generated.cj" \
  "$RUNTIME_DIR/src/composable_ui_named_style.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$RUNTIME_DIR/probe/generated_ui_image_lifecycle_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_generated_image_lifecycle \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/generated_ui_image_lifecycle_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
export CJGUI_GENERATED_IMAGE_LIFECYCLE_DIR="$OUTPUT_DIR"
set +e
"$OUTPUT_DIR/generated_ui_image_lifecycle_probe" | tee "$OUTPUT_DIR/result.log"
PROBE_STATUS="${pipestatus[1]}"
set -e

SOURCE_HASH="$(shasum -a 256 "$RUNTIME_DIR/probe/generated_ui_image_lifecycle_probe.cj" | awk '{print $1}')"
BINARY_HASH="$(shasum -a 256 "$OUTPUT_DIR/generated_ui_image_lifecycle_probe" | awk '{print $1}')"
{
  echo 'format=1'
  echo "probe_status=$PROBE_STATUS"
  echo "source_sha256=$SOURCE_HASH"
  echo "binary_sha256=$BINARY_HASH"
  echo "sdkroot=$SDKROOT_PATH"
  echo "result_log=$OUTPUT_DIR/result.log"
} >"$OUTPUT_DIR/manifest"

if [[ "$PROBE_STATUS" -ne 0 ]]; then
  echo "cjgui generated image lifecycle: probe failed status=$PROBE_STATUS output=$OUTPUT_DIR" >&2
  exit "$PROBE_STATUS"
fi

LOG="$OUTPUT_DIR/result.log"
fail() {
  echo "cjgui generated image lifecycle: $*" >&2
  exit 1
}
grep -q '^CJGUI_GENERATED_IMAGE_COLD cold=unrequested cold_ok=true' "$LOG" \
  || fail "the accepted binding was not cold before its first draw"
grep -q '^CJGUI_GENERATED_IMAGE_LOADING state=loading sampled=loading' "$LOG" \
  || fail "a held launch gate did not leave the generated node loading"
grep -q '^CJGUI_GENERATED_IMAGE_READY sampled=ready direct=ready .* painted=true' "$LOG" \
  || fail "the generated image did not converge to a painted ready scene"
grep -q '^CJGUI_GENERATED_IMAGE_FAILED .* sampled=failed direct=failed .* same_version_rewrite=false' "$LOG" \
  || fail "the undecodable declaration did not report a failed binding"
grep -q '^CJGUI_GENERATED_IMAGE_RECOVERY committed=true sampled=ready .* painted=true' "$LOG" \
  || fail "a new declared version did not recover the generated image"
grep -q '^CJGUI_GENERATED_IMAGE_STALE .* v2_state=ready .* v2_painted=true' "$LOG" \
  || fail "an older completion repainted the accepted generated scene"
# C2: the fairness claim is made on the NORMAL multi-window application loop with
# TWO live windows, and the value is read from window B's ACCEPTED scene.
grep -q '^CJGUI_GENERATED_IMAGE_SAME_APPLICATION a_loading=loading .* a_committed=true .* b_first_accepted=true' "$LOG" \
  || fail "window A never held a real loading binding under the application loop"
grep -q '^CJGUI_GENERATED_IMAGE_SAME_APPLICATION .* b_accepted_before_pump=.B-初始值. b_accepted_during_load=true a_still_loading=true a_structure_during_load=1' "$LOG" \
  || fail "window B's ACCEPTED scene did not advance only when the application loop accepted it while A was still loading"
grep -q '^CJGUI_GENERATED_IMAGE_SAME_APPLICATION .* a_converged=ready' "$LOG" \
  || fail "window A did not converge after its launch gate was released"
grep -q '^CJGUI_GENERATED_IMAGE_SAME_APPLICATION .* negative_accepted=true a_loading_during_negative=false' "$LOG" \
  || fail "the negative control did not show that the observation depends on A still loading"
grep -q '^CJGUI_GENERATED_IMAGE_SAME_APPLICATION .* a_close_requested=true a_closed=true b_accepted_after_close=true' "$LOG" \
  || fail "window B did not keep accepting owner writes after window A closed"
grep -q '^CJGUI_GENERATED_IMAGE_RELEASE subscribers=0 inflight=0 pending=0 .* converged=true' "$LOG" \
  || fail "the bounded resource domain did not converge after the owners closed"
# The RELEASE line must also prove no live texture reference survives, and the
# bounded cache it leaves behind must stay inside the declaration ceiling.
RELEASE_LINE="$(grep -m1 '^CJGUI_GENERATED_IMAGE_RELEASE ' "$LOG" || true)"
print -r -- "$RELEASE_LINE" | grep -q 'texture_refs=0' \
  || fail "the release convergence kept a live texture reference ('$RELEASE_LINE')"
RELEASE_CACHE_BYTES="$(print -r -- "$RELEASE_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^cache_bytes=/) {sub(/^cache_bytes=/, "", $i); print $i}}')"
[[ "$RELEASE_CACHE_BYTES" == <-> ]] || fail "the release line published no bounded cache size ('$RELEASE_LINE')"
(( RELEASE_CACHE_BYTES <= 65536 )) \
  || fail "the retained image cache after release is not bounded ($RELEASE_CACHE_BYTES bytes)"

# REAL decode/upload work, not a state name: while the launch gate holds, the
# declaration has pending decode work; when it converges, a texture was loaded,
# cached and decoded exactly through the production path.
LOADING_LINE="$(grep -m1 '^CJGUI_GENERATED_IMAGE_LOADING ' "$LOG" || true)"
LOADING_PENDING="$(print -r -- "$LOADING_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^pending=/) {sub(/^pending=/, "", $i); print $i}}')"
[[ "$LOADING_PENDING" == <-> ]] || fail "the loading line published no pending work counter ('$LOADING_LINE')"
(( LOADING_PENDING >= 1 )) \
  || fail "a held launch gate left no pending decode work ($LOADING_PENDING)"
READY_LINE="$(grep -m1 '^CJGUI_GENERATED_IMAGE_READY ' "$LOG" || true)"
READY_LOADED="$(print -r -- "$READY_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^loaded=/) {sub(/^loaded=/, "", $i); print $i}}')"
READY_CACHE="$(print -r -- "$READY_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^cache=/) {sub(/^cache=/, "", $i); print $i}}')"
READY_DECODE="$(print -r -- "$READY_LINE" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^decode=/) {sub(/^decode=/, "", $i); print $i}}')"
[[ "$READY_LOADED" == <-> && "$READY_CACHE" == <-> && "$READY_DECODE" == <-> ]] \
  || fail "the ready line published no decode/upload counters ('$READY_LINE')"
(( READY_LOADED >= 1 && READY_CACHE >= 1 && READY_DECODE >= 1 )) \
  || fail "the converged generated image reported no real decode/upload work (loaded=$READY_LOADED cache=$READY_CACHE decode=$READY_DECODE)"
grep -q '^CJGUI_GENERATED_IMAGE_LIFECYCLE passed=true' "$LOG" \
  || fail "the generated image lifecycle probe did not pass"

echo "cjgui generated image lifecycle: PASS output=$OUTPUT_DIR manifest=$OUTPUT_DIR/manifest decode_work=loaded:${READY_LOADED}:cache:${READY_CACHE}:decode:${READY_DECODE} pending_while_gated=${LOADING_PENDING} release_cache_bytes=${RELEASE_CACHE_BYTES}"
