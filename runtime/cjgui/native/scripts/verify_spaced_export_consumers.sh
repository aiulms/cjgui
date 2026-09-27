#!/usr/bin/env zsh
# Targeted spaced-path export verification for the two consumers this task
# names: the UI-only consumer (adaptive_layout_public_consumer) and the
# runtime-generated consumer (generated_panel_consumer).
#
# It exports the framework preview into a destination whose path contains
# spaces, builds both consumers from the export alone, runs each consumer's
# own self-verifying mode, and writes a fingerprint binding (framework source
# payload / client / consumer source / built bundle) into the export root, so
# a later reader can tie the artifact to its exact inputs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_SPACED_EXPORT_TMPDIR:-/private/tmp/cjgui-spaced-export}"
STAMP="$(date +%Y%m%d%H%M%S)-$$"
DEST="$OUTPUT_DIR/Spaced Preview Workspace $STAMP/CJGUI Framework Preview"

export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-}"
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

mkdir -p "$(dirname "$(dirname "$DEST")")"
zsh "$RUNTIME_DIR/scripts/export_framework_preview.sh" "$DEST"

BUILD_LOG="$OUTPUT_DIR/build-$STAMP.log"
: > "$BUILD_LOG"

UI_CONSUMER="$DEST/consumers/adaptive_layout_public_consumer"
GEN_CONSUMER="$DEST/consumers/generated_panel_consumer"
[[ -d "$UI_CONSUMER" ]] || { echo "spaced export verify: missing UI-only consumer" >&2; exit 1; }
[[ -d "$GEN_CONSUMER" ]] || { echo "spaced export verify: missing generated consumer" >&2; exit 1; }

# RED contract: this exported UI-only consumer must prove that the ordinary
# effect-group buttons dispatch through the accepted scene and read the result
# back from the same owner. Keep the source guard before build/run so an older
# --verify-hit implementation cannot pass by emitting only the P2/P3 verdict.
for assertion in effect_group_opacity_control effect_group_mask_control \
    effect_group_blend_control effect_group_blur_control effect_group_owner_readback; do
  if ! rg -q "name=${assertion} " "$UI_CONSUMER/src/main.cj"; then
    echo "RED: exported UI-only --verify-hit has no ${assertion} assertion" >&2
    exit 1
  fi
done

( cd "$UI_CONSUMER" && zsh run.sh --build-only ) >>"$BUILD_LOG" 2>&1
( cd "$GEN_CONSUMER" && zsh run.sh --build-only ) >>"$BUILD_LOG" 2>&1

UI_BIN="$UI_CONSUMER/target/release/AdaptiveLayoutPublicConsumer.app/Contents/MacOS/AdaptiveLayoutPublicConsumer"
GEN_BIN="$GEN_CONSUMER/target/release/CJGUICollaborationStarter.app/Contents/MacOS/CJGUICollaborationStarter"
[[ -x "$UI_BIN" ]] || { echo "spaced export verify: UI-only binary not built" >&2; exit 1; }
[[ -x "$GEN_BIN" ]] || { echo "spaced export verify: generated binary not built" >&2; exit 1; }

# Each consumer's own self-verifying mode, run from the export alone. The
# wrapper asserts BOTH the process exit code AND the completion marker, so a
# missing or failing marker is never read as a pass. `--inject-verify-failure`
# proves the same chain fails when one assertion is made to fail.
UI_DONE_TOKEN="CJGUI_ADAPTIVE_HIT_DONE"
GEN_DONE_TOKEN="CJGUI_GENERATED_ANIMATION_DONE"

run_self_verify() { # <label> <dir> <binary> <done-token> <args...>
  local label="$1" dir="$2" binary="$3" token="$4"
  shift 4
  local log="$OUTPUT_DIR/${label}-run-$STAMP.log"
  set +e
  ( cd "$dir" && "$binary" "$@" --instance-token "spaced-${label}-${STAMP}" ) >"$log" 2>&1
  local exit_code=$?
  set -e
  local marker
  marker="$(grep "^${token} " "$log" | tail -1 || true)"
  print -r -- "spaced export verify: $label exit=$exit_code marker=[${marker}]"
  if [[ -z "$marker" ]]; then
    echo "spaced export verify: $label produced no completion marker (log=$log)" >&2
    return 1
  fi
  local failed
  failed="$(print -r -- "$marker" | sed -n 's/.*failed=\([0-9]*\).*/\1/p')"
  if (( exit_code != 0 )) || [[ "$failed" != "0" ]]; then
    echo "spaced export verify: $label failed (exit=$exit_code marker=$marker log=$log)" >&2
    return 1
  fi
  LAST_RUN_LOG="$log"
  return 0
}

inject_must_fail() { # <label> <dir> <binary> <args...>
  local label="$1" dir="$2" binary="$3"
  shift 3
  local log="$OUTPUT_DIR/${label}-inject-$STAMP.log"
  set +e
  ( cd "$dir" && "$binary" "$@" --inject-verify-failure ) >"$log" 2>&1
  local exit_code=$?
  set -e
  if (( exit_code == 0 )); then
    echo "spaced export verify: $label injected failure still exited 0 (log=$log)" >&2
    return 1
  fi
  if ! grep -q 'failed=[1-9]' "$log"; then
    echo "spaced export verify: $label injected failure has no failed>0 marker (log=$log)" >&2
    return 1
  fi
  print -r -- "spaced export verify: $label injected failure correctly rejected (exit=$exit_code)"
  return 0
}

run_self_verify ui-pass "$UI_CONSUMER" "$UI_BIN" "$UI_DONE_TOKEN" --verify-hit || exit 1
UI_RUN_LOG="$LAST_RUN_LOG"
run_self_verify ui-material "$UI_CONSUMER" "$UI_BIN" "CJGUI_ADAPTIVE_WINDOW_MATERIAL_DONE" --verify-window-material || exit 1
UI_MATERIAL_LOG="$LAST_RUN_LOG"
run_self_verify ui-diagnostic "$UI_CONSUMER" "$UI_BIN" "CJGUI_ADAPTIVE_DIAGNOSTIC_DONE" --verify-diagnostics || exit 1
UI_DIAGNOSTIC_LOG="$LAST_RUN_LOG"
grep -q '^CJGUI_ADAPTIVE_HIT_VERDICT assertions=15 failed=0 ' "$UI_RUN_LOG" || {
  echo "spaced export verify: UI-only --verify-hit did not complete all 15 assertions (log=$UI_RUN_LOG)" >&2
  exit 1
}
for assertion in effect_group_opacity_control effect_group_mask_control \
    effect_group_blend_control effect_group_blur_control effect_group_owner_readback accent_control; do
  grep -q "CJGUI_ADAPTIVE_HIT_ASSERT name=${assertion} ok=1" "$UI_RUN_LOG" || {
    echo "spaced export verify: UI-only effect-group assertion failed or missing: $assertion (log=$UI_RUN_LOG)" >&2
    exit 1
  }
done
run_self_verify gen-pass "$GEN_CONSUMER" "$GEN_BIN" "$GEN_DONE_TOKEN" --verify-animation || exit 1
GEN_RUN_LOG="$LAST_RUN_LOG"
inject_must_fail ui-inject "$UI_CONSUMER" "$UI_BIN" --verify-hit || exit 1
inject_must_fail gen-inject "$GEN_CONSUMER" "$GEN_BIN" --verify-animation || exit 1

# Run the exported normal generated application and its exported public client
# together. The verifier discovers the effectGroup contract, submits candidates,
# waits for their own tickets, and checks accepted readback and rejected rollback.
# This exact child PID is the only process the cleanup may stop.
GEN_EXTERNAL_APP_LOG="$OUTPUT_DIR/gen-external-app-$STAMP.log"
GEN_EXTERNAL_LOG="$OUTPUT_DIR/gen-external-client-$STAMP.log"
run_external_generated() (
  set -euo pipefail
  ( cd "$GEN_CONSUMER" && "$GEN_BIN" --instance-token "spaced-external-$STAMP" ) >"$GEN_EXTERNAL_APP_LOG" 2>&1 &
  local app_pid=$!
  trap 'kill -TERM "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true' EXIT
  local descriptor=""
  local attempt
  for (( attempt = 0; attempt < 100; attempt++ )); do
    descriptor="$(sed -n 's/^CJGUI_COLLABORATION_READY DESCRIPTOR_PATH //p' "$GEN_EXTERNAL_APP_LOG" | tail -1)"
    if [[ -n "$descriptor" && -f "$descriptor" ]]; then break; fi
    if ! kill -0 "$app_pid" 2>/dev/null; then
      echo "spaced export verify: generated normal app exited before descriptor (log=$GEN_EXTERNAL_APP_LOG)" >&2
      return 1
    fi
    sleep 0.1
  done
  if [[ -z "$descriptor" || ! -f "$descriptor" ]]; then
    echo "spaced export verify: generated normal app gave no descriptor (log=$GEN_EXTERNAL_APP_LOG)" >&2
    return 1
  fi
  python3 "$GEN_CONSUMER/verify_generated_effect_candidates.py" "$descriptor" >"$GEN_EXTERNAL_LOG" 2>&1
  grep -q '^CJGUI_EXTERNAL_EFFECT_GROUP_VERDICT PASS$' "$GEN_EXTERNAL_LOG" || {
    echo "spaced export verify: exported external effect client failed (log=$GEN_EXTERNAL_LOG)" >&2
    return 1
  }
  print -r -- "spaced export verify: generated external client PASS log=$GEN_EXTERNAL_LOG"
)
run_external_generated

# The same exported binary and client must distinguish an accepted blur request
# from the committed unblurred fallback, then observe the restored blurred frame.
GEN_EFFECT_APP_LOG="$OUTPUT_DIR/gen-effect-app-$STAMP.log"
GEN_EFFECT_CLIENT_LOG="$OUTPUT_DIR/gen-effect-client-$STAMP.log"
GEN_EFFECT_GATE="$OUTPUT_DIR/gen-effect-release-$STAMP"
run_external_effect_observation() (
  set -euo pipefail
  ( cd "$GEN_CONSUMER" && "$GEN_BIN" --verify-effect-fallback "$GEN_EFFECT_GATE" \
      --instance-token "spaced-effect-$STAMP" ) >"$GEN_EFFECT_APP_LOG" 2>&1 &
  local app_pid=$!
  trap 'kill -TERM "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true' EXIT
  local descriptor=""
  local attempt
  for (( attempt = 0; attempt < 100; attempt++ )); do
    descriptor="$(sed -n 's/^CJGUI_COLLABORATION_READY DESCRIPTOR_PATH //p' "$GEN_EFFECT_APP_LOG" | tail -1)"
    if [[ -n "$descriptor" && -f "$descriptor" ]]; then break; fi
    if ! kill -0 "$app_pid" 2>/dev/null; then
      echo "spaced export verify: effect app exited before descriptor (log=$GEN_EFFECT_APP_LOG)" >&2
      return 1
    fi
    sleep 0.1
  done
  if [[ -z "$descriptor" || ! -f "$descriptor" ]]; then
    echo "spaced export verify: effect app gave no descriptor (log=$GEN_EFFECT_APP_LOG)" >&2
    return 1
  fi
  python3 "$GEN_CONSUMER/verify_public_effect_observation.py" "$descriptor" "$GEN_EFFECT_GATE" \
    >"$GEN_EFFECT_CLIENT_LOG" 2>&1
  grep -q '^CJGUI_PUBLIC_EFFECT_OBSERVATION_VERDICT PASS$' "$GEN_EFFECT_CLIENT_LOG" || {
    echo "spaced export verify: exported public effect observation failed (log=$GEN_EFFECT_CLIENT_LOG)" >&2
    return 1
  }
  print -r -- "spaced export verify: public effect observation PASS log=$GEN_EFFECT_CLIENT_LOG"
)
run_external_effect_observation

# A fresh normal generated window starts with the system content-area request.
# The exported typed client discovers the root contract, switches/clears it
# through accepted candidates, and reads the actual AppKit host receipt.
GEN_MATERIAL_APP_LOG="$OUTPUT_DIR/gen-material-app-$STAMP.log"
GEN_MATERIAL_CLIENT_LOG="$OUTPUT_DIR/gen-material-client-$STAMP.log"
run_external_window_material() (
  set -euo pipefail
  ( cd "$GEN_CONSUMER" && "$GEN_BIN" --instance-token "spaced-material-$STAMP" ) >"$GEN_MATERIAL_APP_LOG" 2>&1 &
  local app_pid=$!
  trap 'kill -TERM "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true' EXIT
  local descriptor=""
  local attempt
  for (( attempt = 0; attempt < 100; attempt++ )); do
    descriptor="$(sed -n 's/^CJGUI_COLLABORATION_READY DESCRIPTOR_PATH //p' "$GEN_MATERIAL_APP_LOG" | tail -1)"
    if [[ -n "$descriptor" && -f "$descriptor" ]]; then break; fi
    if ! kill -0 "$app_pid" 2>/dev/null; then
      echo "spaced export verify: window material app exited before descriptor (log=$GEN_MATERIAL_APP_LOG)" >&2
      return 1
    fi
    sleep 0.1
  done
  [[ -n "$descriptor" && -f "$descriptor" ]] || return 1
  python3 "$GEN_CONSUMER/verify_public_window_material.py" "$descriptor" >"$GEN_MATERIAL_CLIENT_LOG" 2>&1
  grep -q '^CJGUI_PUBLIC_WINDOW_MATERIAL_VERDICT PASS$' "$GEN_MATERIAL_CLIENT_LOG" || {
    echo "spaced export verify: public window material failed (log=$GEN_MATERIAL_CLIENT_LOG)" >&2
    return 1
  }
  print -r -- "spaced export verify: public window material PASS log=$GEN_MATERIAL_CLIENT_LOG"
)
run_external_window_material

# The exported generated app uses the public diagnostic window API while a
# separate exported typed client submits the legal and rejected candidates.
GEN_DIAGNOSTIC_APP_LOG="$OUTPUT_DIR/gen-diagnostic-app-$STAMP.log"
GEN_DIAGNOSTIC_CLIENT_LOG="$OUTPUT_DIR/gen-diagnostic-client-$STAMP.log"
GEN_DIAGNOSTIC_GATE="$OUTPUT_DIR/gen-diagnostic-gate-$STAMP"
run_external_generated_diagnostic() (
  set -euo pipefail
  ( cd "$GEN_CONSUMER" && "$GEN_BIN" --verify-diagnostics "$GEN_DIAGNOSTIC_GATE" \
      --instance-token "spaced-diagnostic-$STAMP" ) >"$GEN_DIAGNOSTIC_APP_LOG" 2>&1 &
  local app_pid=$!
  trap 'kill -TERM "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true' EXIT
  local descriptor=""
  local attempt
  for (( attempt = 0; attempt < 100; attempt++ )); do
    descriptor="$(sed -n 's/^CJGUI_COLLABORATION_READY DESCRIPTOR_PATH //p' "$GEN_DIAGNOSTIC_APP_LOG" | tail -1)"
    if [[ -n "$descriptor" && -f "$descriptor" ]]; then break; fi
    if ! kill -0 "$app_pid" 2>/dev/null; then
      echo "spaced export verify: generated diagnostic app exited before descriptor" >&2
      return 1
    fi
    sleep 0.1
  done
  [[ -n "$descriptor" && -f "$descriptor" ]] || return 1
  python3 "$GEN_CONSUMER/verify_generated_diagnostics.py" "$descriptor" \
    "$GEN_DIAGNOSTIC_GATE" "$GEN_DIAGNOSTIC_APP_LOG" >"$GEN_DIAGNOSTIC_CLIENT_LOG" 2>&1
  grep -q '^CJGUI_GENERATED_DIAGNOSTIC_CLIENT PASS ' "$GEN_DIAGNOSTIC_CLIENT_LOG" || return 1
  wait "$app_pid"
  grep -q '^CJGUI_GENERATED_DIAGNOSTIC_DONE .*failed=0$' "$GEN_DIAGNOSTIC_APP_LOG" || return 1
  print -r -- "spaced export verify: generated public diagnostic PASS log=$GEN_DIAGNOSTIC_CLIENT_LOG"
)
run_external_generated_diagnostic

hash_tree() { # directory -> sha256 of sorted file digests
  ( cd "$1" && find . -type f -print0 | sort -z | xargs -0 shasum -a 256 ) | shasum -a 256 | awk '{print $1}'
}
hash_file() { shasum -a 256 "$1" | awk '{print $1}'; }

# The fingerprint covers the ACTUAL generated client and ALL consumer sources
# (the whole src/ tree of each consumer, not just one entry file), so a source
# change that the built bundle consumes cannot go unhashed.
FRAMEWORK_SRC_SHA="$(hash_tree "$DEST/framework/cjgui/src")"
FRAMEWORK_NATIVE_SHA="$(hash_tree "$DEST/framework/cjgui/native")"
FRAMEWORK_RESOURCE_SHA="$(hash_tree "$DEST/framework/cjgui/resources")"
CLIENT_SHA="$(hash_file "$DEST/framework/cjgui/shared_operation_core/client.py")"
GENERATED_CLIENT_SHA="$(hash_file "$DEST/framework/cjgui/shared_operation_core/cjgui_generated_client.py")"
GEN_VERIFIER_SHA="$(hash_file "$GEN_CONSUMER/verify_generated_effect_candidates.py")"
GEN_EFFECT_VERIFIER_SHA="$(hash_file "$GEN_CONSUMER/verify_public_effect_observation.py")"
GEN_MATERIAL_VERIFIER_SHA="$(hash_file "$GEN_CONSUMER/verify_public_window_material.py")"
GEN_DIAGNOSTIC_VERIFIER_SHA="$(hash_file "$GEN_CONSUMER/verify_generated_diagnostics.py")"
UI_SOURCE_SHA="$(hash_tree "$UI_CONSUMER/src")"
GEN_SOURCE_SHA="$(hash_tree "$GEN_CONSUMER/src")"
UI_BUNDLE_SHA="$(hash_tree "$UI_CONSUMER/target/release/AdaptiveLayoutPublicConsumer.app")"
GEN_BUNDLE_SHA="$(hash_tree "$GEN_CONSUMER/target/release/CJGUICollaborationStarter.app")"
UI_RESOURCE_SHA="$(hash_tree "$UI_CONSUMER/target/release/AdaptiveLayoutPublicConsumer.app/Contents/Resources")"
GEN_RESOURCE_SHA="$(hash_tree "$GEN_CONSUMER/target/release/CJGUICollaborationStarter.app/Contents/Resources")"
RUNNER_SHA="$(hash_file "$DEST/framework/cjgui/scripts/run_macos_application.sh")"
EXPORTER_SHA="$(hash_file "$RUNTIME_DIR/scripts/export_framework_preview.sh")"

# The exported consumers must have consumed the NEW capabilities, not merely an
# older build: the B1/B2/B3 assertions have to be present in the export run log.
grep -q 'name=platform_state_chain ok=1' "$UI_RUN_LOG" || { echo "spaced export verify: UI consumer did not run the B3 platform chain in the export" >&2; exit 1; }
grep -q 'name=host_theme_accepted_paint ok=1' "$GEN_RUN_LOG" || { echo "spaced export verify: generated consumer did not apply the host theme to accepted paint" >&2; exit 1; }
grep -q 'name=framework_common_definition ok=1' "$GEN_RUN_LOG" || { echo "spaced export verify: generated consumer did not consume the framework motion definition" >&2; exit 1; }
grep -q '^CJGUI_GENERATED_MOTION_CAPABILITY motion_rule=generated.opacity ' "$GEN_RUN_LOG" || { echo "spaced export verify: generated consumer did not publish the registered motion capability" >&2; exit 1; }
grep -q '^CJGUI_GENERATED_EFFECT_SUBMIT accepted=true ' "$GEN_RUN_LOG" || { echo "spaced export verify: generated motion candidate was not accepted" >&2; exit 1; }
grep -E -q '^CJGUI_GENERATED_ANIMATION_STATE key=effectAnimate .* started=1 .* rule=generated.opacity duration=160 ' "$GEN_RUN_LOG" || { echo "spaced export verify: accepted generated rule did not drive the real generated node" >&2; exit 1; }
grep -q 'name=alpha_composed_once ok=1' "$GEN_RUN_LOG" || { echo "spaced export verify: generated consumer did not run the B1 alpha invariant" >&2; exit 1; }
grep -q 'name=reduce_motion_converges_and_stops ok=1' "$GEN_RUN_LOG" || { echo "spaced export verify: generated consumer did not run the B3 reduce-motion check" >&2; exit 1; }
grep -q '^CJGUI_GENERATED_EFFECT_SUBMIT accepted=true ' "$GEN_EXTERNAL_APP_LOG" || { echo "spaced export verify: normal exported generated app did not accept its effect group" >&2; exit 1; }
grep -q '^CJGUI_EXTERNAL_EFFECT_GROUP_EVIDENCE ' "$GEN_EXTERNAL_LOG" || { echo "spaced export verify: normal exported client gave no P4 effect evidence" >&2; exit 1; }
grep -q '^CJGUI_EFFECT_PROBE phase=fallback$' "$GEN_EFFECT_APP_LOG" || { echo "spaced export verify: effect app did not exercise transparent-root fallback" >&2; exit 1; }
grep -q '^CJGUI_EFFECT_PROBE phase=restored$' "$GEN_EFFECT_APP_LOG" || { echo "spaced export verify: effect app did not restore opaque-root blur" >&2; exit 1; }
grep -q '^CJGUI_PUBLIC_EFFECT_OBSERVATION ' "$GEN_EFFECT_CLIENT_LOG" || { echo "spaced export verify: public client has no fallback/recovery evidence" >&2; exit 1; }
grep -q '^CJGUI_ADAPTIVE_WINDOW_MATERIAL_VERDICT .*failed=0 ' "$UI_MATERIAL_LOG" || { echo "spaced export verify: UI-only material chain failed" >&2; exit 1; }
grep -q '^CJGUI_PUBLIC_WINDOW_MATERIAL ' "$GEN_MATERIAL_CLIENT_LOG" || { echo "spaced export verify: generated material chain has no evidence" >&2; exit 1; }
grep -q '^CJGUI_ADAPTIVE_DIAGNOSTIC_ASSERT name=overlay_isolated ok=1 ' "$UI_DIAGNOSTIC_LOG" || { echo "spaced export verify: UI diagnostic toggle did not remain isolated" >&2; exit 1; }
grep -q '^CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=rejected_keeps_accepted ok=1 ' "$GEN_DIAGNOSTIC_APP_LOG" || { echo "spaced export verify: generated diagnostic did not preserve accepted on rejection" >&2; exit 1; }

FINGERPRINT="$DEST/CONSUMER_FINGERPRINTS.txt"
{
  print -r -- "spaced_export_consumers=v9"
  print -r -- "destination=$DEST"
  print -r -- "ui_only_consumer=adaptive_layout_public_consumer"
  print -r -- "generated_consumer=generated_panel_consumer"
  print -r -- "ui_run_exit=0"
  print -r -- "generated_run_exit=0"
  print -r -- "ui_run_marker=${UI_DONE_TOKEN}"
  print -r -- 'ui_effect_group_controls=opacity_mask_multiply_blur_accepted_owner_readback'
  print -r -- "generated_run_marker=${GEN_DONE_TOKEN}"
  print -r -- "injected_failure_rejected=1"
  print -r -- "generated_external_effect_group=PASS"
  print -r -- "generated_public_effect_observation=PASS"
  print -r -- "ui_only_window_material=PASS"
  print -r -- "generated_public_window_material=PASS"
  print -r -- "ui_only_diagnostic=PASS"
  print -r -- "generated_public_diagnostic=PASS"
  print -r -- "framework_src_sha256=$FRAMEWORK_SRC_SHA"
  print -r -- "framework_native_sha256=$FRAMEWORK_NATIVE_SHA"
  print -r -- "framework_resource_sha256=$FRAMEWORK_RESOURCE_SHA"
  print -r -- "client_sha256=$CLIENT_SHA"
  print -r -- "generated_client_sha256=$GENERATED_CLIENT_SHA"
  print -r -- "generated_effect_verifier_sha256=$GEN_VERIFIER_SHA"
  print -r -- "generated_public_effect_verifier_sha256=$GEN_EFFECT_VERIFIER_SHA"
  print -r -- "generated_public_window_material_verifier_sha256=$GEN_MATERIAL_VERIFIER_SHA"
  print -r -- "generated_diagnostic_verifier_sha256=$GEN_DIAGNOSTIC_VERIFIER_SHA"
  print -r -- "ui_consumer_src_tree_sha256=$UI_SOURCE_SHA"
  print -r -- "generated_consumer_src_tree_sha256=$GEN_SOURCE_SHA"
  print -r -- "ui_bundle_sha256=$UI_BUNDLE_SHA"
  print -r -- "generated_bundle_sha256=$GEN_BUNDLE_SHA"
  print -r -- "ui_resource_sha256=$UI_RESOURCE_SHA"
  print -r -- "generated_resource_sha256=$GEN_RESOURCE_SHA"
  print -r -- "runner_sha256=$RUNNER_SHA"
  print -r -- "exporter_sha256=$EXPORTER_SHA"
  print -r -- "ui_run_log=$UI_RUN_LOG"
  print -r -- "generated_run_log=$GEN_RUN_LOG"
  print -r -- "generated_external_app_log=$GEN_EXTERNAL_APP_LOG"
  print -r -- "generated_external_client_log=$GEN_EXTERNAL_LOG"
  print -r -- "generated_public_effect_app_log=$GEN_EFFECT_APP_LOG"
  print -r -- "generated_public_effect_client_log=$GEN_EFFECT_CLIENT_LOG"
  print -r -- "ui_window_material_run_log=$UI_MATERIAL_LOG"
  print -r -- "ui_diagnostic_run_log=$UI_DIAGNOSTIC_LOG"
  print -r -- "generated_diagnostic_app_log=$GEN_DIAGNOSTIC_APP_LOG"
  print -r -- "generated_diagnostic_client_log=$GEN_DIAGNOSTIC_CLIENT_LOG"
  print -r -- "generated_public_window_material_app_log=$GEN_MATERIAL_APP_LOG"
  print -r -- "generated_public_window_material_client_log=$GEN_MATERIAL_CLIENT_LOG"
} > "$FINGERPRINT"

cat "$FINGERPRINT"
print -r -- "spaced export verify: ok ui_only=build_run_marker ui_effect_group=opacity_mask_multiply_blur_accepted_owner_readback generated=build_run_marker injected_failure=rejected fingerprints=$FINGERPRINT build_log=$BUILD_LOG"
