#!/usr/bin/env zsh

# Same-process application acceptance. This script keeps static contract
# checks separate from normal AppKit-process evidence: the latter opens real
# windows and drives one authorized external CAS through the public socket.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/shared_document_window_app"
TEMP_ROOT="$(mktemp -d /private/tmp/cjgui-multi-window-application.XXXXXX)"
APP_PID=""
DESCRIPTOR=""

cleanup() {
  if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    kill -TERM "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  if [[ "${CJGUI_MULTI_WINDOW_KEEP_TMPDIR:-0}" != 1 ]]; then
    rm -rf "$TEMP_ROOT"
  fi
}
trap cleanup EXIT HUP INT TERM

# The vendor setup reads both library variables under `set -u` on some local
# toolchains. Define empty inherited values before selecting this script's
# explicit 1.1.3 compiler.
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-}"
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh

# Public identities must stay values, and an external mutation must be
# consumed once without globally forcing a rebuild. The normal-process checks
# below verify the resulting targeted behavior.
rg -q 'public class CjguiMacosApplicationWindowIdentifier' "$RUNTIME_DIR/src/macos_application_host.cj"
rg -q 'public class CjguiMacosApplication <: CjguiSharedOperationWindowProjectionTargetProvider' "$RUNTIME_DIR/src/macos_application_host.cj"
rg -q 'func requestApplicationExit\(\): Bool' "$RUNTIME_DIR/src/macos_application_host.cj"
rg -q 'let _ = connection.consumeWindowRefreshRequest()' "$RUNTIME_DIR/src/macos_application_host.cj"
! rg -q 'window\.testSessionToken\(' "$APP_DIR/src/main.cj"
! rg -q '^foreign \{' "$APP_DIR/src/main.cj"
rg -q -- '--multi-window' "$APP_DIR/src/main.cj"

APPLICATION_LOG="$TEMP_ROOT/application-probe.log"
zsh "$SCRIPT_DIR/verify_composable_ui_appkit_text.sh" --multi-window >"$APPLICATION_LOG" 2>"$TEMP_ROOT/application-probe.stderr.log"
rg -q 'CJGUI_MULTI_WINDOW_APPLICATION windows=1,2,4 shared_owner=appkit_human_and_external close_reject_reopen=passed single_wait_rotation=passed' "$APPLICATION_LOG"

REENTRANCY_LOG="$TEMP_ROOT/reentrancy.log"
zsh "$SCRIPT_DIR/verify_composable_ui_appkit_text.sh" --multi-window-reentrancy >"$REENTRANCY_LOG" 2>"$TEMP_ROOT/reentrancy.stderr.log"
rg -q 'CJGUI_MULTI_WINDOW_REENTRANCY callback_close_deferred=true nested_wait_suppressed=true exit_rejected_preserved_a=true open_rejected_during_turn=true reclaimed=true' "$REENTRANCY_LOG"

IDENTITY_LOG="$TEMP_ROOT/identity.log"
zsh "$SCRIPT_DIR/verify_composable_ui_appkit_text.sh" --multi-window-identity >"$IDENTITY_LOG" 2>"$TEMP_ROOT/identity.stderr.log"
rg -q 'CJGUI_MULTI_WINDOW_IDENTITY cross_application_rejected=true stale_rebuild_rejected=true sibling_application_turn_survived=true reclaimed=true' "$IDENTITY_LOG"

EXCEPTION_GUARD_LOG="$TEMP_ROOT/exception-guard.log"
zsh "$SCRIPT_DIR/verify_composable_ui_appkit_text.sh" --multi-window-exception-guard >"$EXCEPTION_GUARD_LOG" 2>"$TEMP_ROOT/exception-guard.stderr.log"
rg -q 'CJGUI_MULTI_WINDOW_EXCEPTION_GUARD callback_exception_propagated=true guard_released=true sibling_turn_served=true reclaimed=true' "$EXCEPTION_GUARD_LOG"

PARTIAL_CREATION_LOG="$TEMP_ROOT/partial-creation.log"
zsh "$SCRIPT_DIR/verify_composable_ui_appkit_text.sh" --multi-window-partial-creation >"$PARTIAL_CREATION_LOG" 2>"$TEMP_ROOT/partial-creation.stderr.log"
rg -q 'CJGUI_MULTI_WINDOW_PARTIAL_CREATION native_start_failed=true failed_owner_empty=true sibling_preserved=true reopen_after_capacity_release=true reclaimed=true' "$PARTIAL_CREATION_LOG"

FAIRNESS_LOG="$TEMP_ROOT/fairness.log"
zsh "$SCRIPT_DIR/verify_composable_ui_appkit_text.sh" --multi-window-fairness >"$FAIRNESS_LOG" 2>"$TEMP_ROOT/fairness.stderr.log"
for windows in 1 2 4; do
  [[ "$(rg -c "^CJGUI_MULTI_WINDOW_FAIRNESS windows=$windows " "$FAIRNESS_LOG")" == 30 ]]
  rg -q "CJGUI_MULTI_WINDOW_FAIRNESS_SUMMARY windows=$windows samples=30 .*fair_rotation=true reclaimed=true" "$FAIRNESS_LOG"
done
! rg -q '^CJGUI_MULTI_WINDOW_FAIRNESS .* valid=false' "$FAIRNESS_LOG"

# Build the ordinary consumer from its package, then run the published bundle
# directly so source build and runtime bundle facts do not get conflated.
zsh "$APP_DIR/run.sh" --build-only >"$TEMP_ROOT/consumer-build.log" 2>&1
BINARY="$APP_DIR/target/release/CJGUISharedDocument.app/Contents/MacOS/CJGUISharedDocument"
test -x "$BINARY"

CONNECTION_LOG="$TEMP_ROOT/connection.log"
"$BINARY" --multi-window --with-connection --measurement-warmup-ms 0 --measurement-duration-ms 5000 \
  --close-first-window-after-ms 2000 --reopen-first-window-after-close >"$CONNECTION_LOG" 2>"$TEMP_ROOT/connection.stderr.log" &
APP_PID=$!
for attempt in {1..160}; do
  DESCRIPTOR="$(sed -n 's/^CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_READY DESCRIPTOR_PATH //p' "$CONNECTION_LOG" | tail -n 1)"
  if [[ -n "$DESCRIPTOR" && -f "$DESCRIPTOR" ]]; then
    break
  fi
  sleep 0.1
done
if [[ -z "$DESCRIPTOR" || ! -f "$DESCRIPTOR" ]]; then
  wait "$APP_PID" || true
  APP_PID=""
  print -u2 -- "multi-window consumer never published its descriptor; log=$CONNECTION_LOG"
  exit 1
fi

TARGETS="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-targets)"
TARGET_A="$(awk '$1 == "WINDOW_TARGET" { print $2; exit }' <<< "$TARGETS")"
TARGET_B="$(awk '$1 == "WINDOW_TARGET" { count += 1; if (count == 2) { print $2; exit } }' <<< "$TARGETS")"
test -n "$TARGET_A"
test -n "$TARGET_B"

# Read two distinct projections before the controlled ordinary close. The
# semantic roots prove this is not a domain-only snapshot and that B was not
# silently substituted for A.
CONTEXT_A="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-context "$TARGET_A")"
CONTEXT_B="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-context "$TARGET_B")"
print -r -- "$CONTEXT_A" >"$TEMP_ROOT/context-a.log"
print -r -- "$CONTEXT_B" >"$TEMP_ROOT/context-b.log"
rg -q "WINDOW_TARGET $TARGET_A" "$TEMP_ROOT/context-a.log"
rg -q 'WINDOW_NODE shared-document-multi-root-primary 1 window' "$TEMP_ROOT/context-a.log"
rg -q "WINDOW_TARGET $TARGET_B" "$TEMP_ROOT/context-b.log"
rg -q 'WINDOW_NODE shared-document-multi-root-review 1 window' "$TEMP_ROOT/context-b.log"

# Progress and interaction are now target-bound observations as well. The
# response must carry the requested target so a client can correlate a late
# read without consulting a first-live/default window.
PROGRESS_A="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-progress "$TARGET_A")"
INTERACTION_B="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-interaction "$TARGET_B")"
print -r -- "$PROGRESS_A" >"$TEMP_ROOT/progress-a.log"
print -r -- "$INTERACTION_B" >"$TEMP_ROOT/interaction-b.log"
rg -q 'KIND WINDOW_PROGRESS' "$TEMP_ROOT/progress-a.log"
rg -q "WINDOW_TARGET $TARGET_A" "$TEMP_ROOT/progress-a.log"
rg -q 'WINDOW_PROJECTION ACTIVE' "$TEMP_ROOT/progress-a.log"
rg -q 'KIND WINDOW_INTERACTION' "$TEMP_ROOT/interaction-b.log"
rg -q "WINDOW_TARGET $TARGET_B" "$TEMP_ROOT/interaction-b.log"

CONTEXT="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" get)"
print -r -- "$CONTEXT" >"$TEMP_ROOT/context.log"
VERSION="$(awk '$1 == "VERSION" { print $2; exit }' "$TEMP_ROOT/context.log")"
test -n "$VERSION"
INVOKE="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" invoke "$VERSION" REPLACE_RANGE --target 7101 --arg start=INTEGER:0 --arg end=INTEGER:3 --arg text=STRING:外部)"
rg -q 'APPLIED true' <<< "$INVOKE"

# A closed A is an error, never a request to read whichever sibling happens
# to be first. B remains a separately addressable live projection.
STALE_A_RESPONSE=""
STALE_A_STATUS=0
for attempt in {1..100}; do
  set +e
  STALE_A_RESPONSE="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-context "$TARGET_A" 2>&1)"
  STALE_A_STATUS=$?
  set -e
  if [[ "$STALE_A_STATUS" == 3 ]] && rg -q 'ERROR unknown_window_target' <<< "$STALE_A_RESPONSE"; then
    break
  fi
  sleep 0.1
done
[[ "$STALE_A_STATUS" == 3 ]]
rg -q 'ERROR unknown_window_target' <<< "$STALE_A_RESPONSE"
STALE_A_PROGRESS=""
STALE_A_PROGRESS_STATUS=0
for attempt in {1..100}; do
  set +e
  STALE_A_PROGRESS="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-progress "$TARGET_A" 2>&1)"
  STALE_A_PROGRESS_STATUS=$?
  set -e
  if [[ "$STALE_A_PROGRESS_STATUS" == 3 ]] && rg -q 'ERROR unknown_window_target' <<< "$STALE_A_PROGRESS"; then
    break
  fi
  sleep 0.1
done
[[ "$STALE_A_PROGRESS_STATUS" == 3 ]]
rg -q 'ERROR unknown_window_target' <<< "$STALE_A_PROGRESS"
print -r -- "$STALE_A_PROGRESS" >"$TEMP_ROOT/stale-progress-a.log"
STALE_A_INTERACTION=""
STALE_A_INTERACTION_STATUS=0
for attempt in {1..100}; do
  set +e
  STALE_A_INTERACTION="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-interaction "$TARGET_A" 2>&1)"
  STALE_A_INTERACTION_STATUS=$?
  set -e
  if [[ "$STALE_A_INTERACTION_STATUS" == 3 ]] && rg -q 'ERROR unknown_window_target' <<< "$STALE_A_INTERACTION"; then
    break
  fi
  sleep 0.1
done
[[ "$STALE_A_INTERACTION_STATUS" == 3 ]]
rg -q 'ERROR unknown_window_target' <<< "$STALE_A_INTERACTION"
print -r -- "$STALE_A_INTERACTION" >"$TEMP_ROOT/stale-interaction-a.log"
CONTEXT_B_AFTER_CLOSE="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-context "$TARGET_B")"
print -r -- "$CONTEXT_B_AFTER_CLOSE" >"$TEMP_ROOT/context-b-after-close.log"
rg -q "WINDOW_TARGET $TARGET_B" "$TEMP_ROOT/context-b-after-close.log"
rg -q 'WINDOW_NODE shared-document-multi-root-review 1 window' "$TEMP_ROOT/context-b-after-close.log"
PROGRESS_B_AFTER_CLOSE="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-progress "$TARGET_B")"
INTERACTION_B_AFTER_CLOSE="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-interaction "$TARGET_B")"
print -r -- "$PROGRESS_B_AFTER_CLOSE" >"$TEMP_ROOT/progress-b-after-close.log"
print -r -- "$INTERACTION_B_AFTER_CLOSE" >"$TEMP_ROOT/interaction-b-after-close.log"
rg -q "WINDOW_TARGET $TARGET_B" "$TEMP_ROOT/progress-b-after-close.log"
rg -q "WINDOW_TARGET $TARGET_B" "$TEMP_ROOT/interaction-b-after-close.log"
REOPENED_TARGET=""
for attempt in {1..100}; do
  REOPENED_TARGET="$(awk '$1 == "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_RESULT" && $2 == "REOPENED_TARGET" { print $3; exit }' "$CONNECTION_LOG")"
  if [[ -n "$REOPENED_TARGET" ]]; then
    break
  fi
  sleep 0.1
done
test -n "$REOPENED_TARGET"
REOPENED_PROGRESS="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$DESCRIPTOR" window-progress "$REOPENED_TARGET")"
print -r -- "$REOPENED_PROGRESS" >"$TEMP_ROOT/progress-reopened.log"
rg -q "WINDOW_TARGET $REOPENED_TARGET" "$TEMP_ROOT/progress-reopened.log"
rg -q 'WINDOW_PROJECTION ACTIVE' "$TEMP_ROOT/progress-reopened.log"

wait "$APP_PID"
APP_PID=""
test ! -e "$DESCRIPTOR"
rg -q 'DESCRIPTION_VERSION 1' "$CONNECTION_LOG"
rg -q 'NOTES_VERSION 0' "$CONNECTION_LOG"
rg -q "CLOSED_TARGET $TARGET_A" "$CONNECTION_LOG"
! rg -q 'WINDOW .* GENERATION 1 SCENE ' "$CONNECTION_LOG"
rg -q 'WINDOW .* GENERATION 2 SCENE 2 BUILD 2 SUBMIT 2' "$CONNECTION_LOG"
rg -q 'WINDOW .* GENERATION 3 SCENE 1 BUILD 1 SUBMIT 1' "$CONNECTION_LOG"
rg -q "REOPENED_TARGET $REOPENED_TARGET GENERATION 4" "$CONNECTION_LOG"
rg -q 'WINDOW .* GENERATION 4 SCENE 1 BUILD 1 SUBMIT 1' "$CONNECTION_LOG"

# Keep four real external callers continuously in flight while one CAS moves
# the shared primary document. The consumer records each application turn:
# served external actions, B's actual submitted scene, and the remaining
# AppKit wait budget. This is a bounded UDS backlog, not direct dispatch.
BACKLOG_LOG="$TEMP_ROOT/external-backlog.log"
"$BINARY" --multi-window --with-connection --measurement-warmup-ms 0 --measurement-duration-ms 4000 \
  --record-turn-observations >"$BACKLOG_LOG" 2>"$TEMP_ROOT/external-backlog.stderr.log" &
APP_PID=$!
BACKLOG_DESCRIPTOR=""
for attempt in {1..160}; do
  BACKLOG_DESCRIPTOR="$(sed -n 's/^CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_READY DESCRIPTOR_PATH //p' "$BACKLOG_LOG" | tail -n 1)"
  if [[ -n "$BACKLOG_DESCRIPTOR" && -f "$BACKLOG_DESCRIPTOR" ]]; then
    break
  fi
  sleep 0.1
done
if [[ -z "$BACKLOG_DESCRIPTOR" || ! -f "$BACKLOG_DESCRIPTOR" ]]; then
  wait "$APP_PID" || true
  APP_PID=""
  print -u2 -- "backlog consumer never published its descriptor; log=$BACKLOG_LOG"
  exit 1
fi
BACKLOG_TARGETS="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$BACKLOG_DESCRIPTOR" window-targets)"
BACKLOG_TARGET_B="$(awk '$1 == "WINDOW_TARGET" { count += 1; if (count == 2) { print $2; exit } }' <<< "$BACKLOG_TARGETS")"
test -n "$BACKLOG_TARGET_B"
BACKLOG_B_PROGRESS="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$BACKLOG_DESCRIPTOR" window-progress "$BACKLOG_TARGET_B")"
BACKLOG_B_SESSION="$(awk '$1 == "WINDOW_SESSION" { print $2; exit }' <<< "$BACKLOG_B_PROGRESS")"
test -n "$BACKLOG_B_SESSION"
BACKLOG_CLIENT_PIDS=()
for client_index in {1..4}; do
  (
    for request_index in {1..32}; do
      python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$BACKLOG_DESCRIPTOR" get >/dev/null
    done
  ) &
  BACKLOG_CLIENT_PIDS+=("$!")
done
sleep 0.1
BACKLOG_CONTEXT="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$BACKLOG_DESCRIPTOR" get)"
print -r -- "$BACKLOG_CONTEXT" >"$TEMP_ROOT/backlog-context.log"
BACKLOG_VERSION="$(awk '$1 == "VERSION" { print $2; exit }' "$TEMP_ROOT/backlog-context.log")"
test -n "$BACKLOG_VERSION"
BACKLOG_INVOKE="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$BACKLOG_DESCRIPTOR" invoke "$BACKLOG_VERSION" REPLACE_RANGE --target 7101 --arg start=INTEGER:0 --arg end=INTEGER:3 --arg text=STRING:繁忙)"
rg -q 'APPLIED true' <<< "$BACKLOG_INVOKE"
BACKLOG_B_WAIT="$(python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$BACKLOG_DESCRIPTOR" wait-window "$BACKLOG_B_SESSION" 2 --target "$BACKLOG_TARGET_B" --timeout-ms 3000)"
print -r -- "$BACKLOG_B_WAIT" >"$TEMP_ROOT/backlog-b-wait.log"
rg -q 'WINDOW_WAIT_OUTCOME completed' "$TEMP_ROOT/backlog-b-wait.log"
for backlog_client_pid in "${BACKLOG_CLIENT_PIDS[@]}"; do
  wait "$backlog_client_pid"
done
wait "$APP_PID"
APP_PID=""
test ! -e "$BACKLOG_DESCRIPTOR"
awk '
  $1 == "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_TURN" {
    turns += 1
    for (field_index = 1; field_index <= NF; field_index += 1) {
      if ($field_index == "served_actions") { served = $(field_index + 1) }
      if ($field_index == "b_scene") { scene = $(field_index + 1) }
      if ($field_index == "event_wait_budget_ms") { wait_budget = $(field_index + 1) }
    }
    if (served > 0) { busy_turns += 1 }
    if (scene >= 2) { b_progressed = 1 }
    if (wait_budget < 0) { invalid_wait_budget = 1 }
  }
  END { exit !(turns >= 5 && busy_turns >= 1 && b_progressed && !invalid_wait_budget) }
' "$BACKLOG_LOG"
awk '
  $1 == "CJGUI_SHARED_DOCUMENT_MULTI_WINDOW_RESULT" && $2 == "TRANSPORT" {
    found = 1
    for (field_index = 1; field_index <= NF; field_index += 1) {
      if ($field_index == "ready_high_water") { ready_high_water = $(field_index + 1) }
      if ($field_index == "serviced_actions") { serviced_actions = $(field_index + 1) }
    }
  }
  END { exit !(found && ready_high_water >= 4 && ready_high_water <= 8 && serviced_actions >= 16) }
' "$BACKLOG_LOG"

FAILURE_LOG="$TEMP_ROOT/connection-start-failure.log"
"$BINARY" --multi-window --verify-connection-start-failure >"$FAILURE_LOG" 2>"$TEMP_ROOT/connection-start-failure.stderr.log"
rg -q 'connection_start_failure_preserved_windows=true endpoint_absent_before_and_after=true application_closed=true' "$FAILURE_LOG"

if [[ "${CJGUI_MULTI_WINDOW_KEEP_TMPDIR:-0}" == 1 ]]; then
  evidence_location="$TEMP_ROOT"
else
  evidence_location="not_retained_set_CJGUI_MULTI_WINDOW_KEEP_TMPDIR_1"
fi
print -r -- "cjgui_multi_window_application=ok application_probe=passed reentrancy=passed exception_guard=passed identity_binding=passed partial_creation=passed fairness=1_2_4x30 consumer_bundle=passed external_cas=passed exact_target_contexts=passed busy_backlog_b_progressed=true closed_target_rejected=true sibling_target_survived=true unrelated_window_idle=true endpoint_cleared=true connection_start_failure_preserved_windows=true evidence_location=$evidence_location"
