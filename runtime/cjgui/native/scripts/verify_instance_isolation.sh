#!/usr/bin/env zsh
# A1 acceptance: instance ownership and clipboard guard behavior.
#
# What this driver proves, and how:
#
# 1. The user's real general clipboard is snapshotted (every item type and raw
#    byte payload) BEFORE this harness writes anything anywhere. No fixture
#    value is ever placed on the general pasteboard by the driver itself, so
#    the outer snapshot can never be overwritten by a fixture.
# 2. The guard's own contract (conditional restore, foreign preservation,
#    fixture recovery, full-type comparison) runs headlessly on a PRIVATE
#    pasteboard first, so the driver's assumptions are verified, not assumed.
# 3. Control instances are identified by their own connection descriptor plus
#    the round's executable name and directory - never by "first pid with this
#    path". Cleanup re-checks that identity before signalling, and this script
#    never signals anything it does not own (no killall, no System Events).
# 4. After EVERY tested child run exits - normal, forced timeout, and forced
#    failure - the live general clipboard is checked against the real user
#    snapshot. A leaked fixture of our own is recovered and re-verified; a
#    foreign value is preserved; anything unidentifiable is a FAIL.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_INSTANCE_ISOLATION_TMPDIR:-/private/tmp/cjgui-instance-isolation}"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  SDKROOT_PATH="$CJ_GUI_SDKROOT"
else
  SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
export SDKROOT="$SDKROOT_PATH"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
RESULT_LOG="$WORK/result.log"
: > "$RESULT_LOG"
say() { print -r -- "$*" >> "$RESULT_LOG"; }
fail() { say "FAIL $*"; cat "$RESULT_LOG"; exit 1; }
blocked() { say "BLOCKED $*"; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

GUARD="$WORK/cjgui_clipboard_guard"
clang -fobjc-arc -framework AppKit "$RUNTIME_DIR/native/tests/clipboard_guard.m" -o "$GUARD" 2>"$WORK/guard-build.log" \
  || fail "guard build failed"
OUTER_SNAPSHOT="$WORK/outer-original.plist"
LAST_EXPECTED="$WORK/last-expected.plist"

# --- 1. capture the REAL user clipboard before any fixture write ----------
"$GUARD" snapshot "$OUTER_SNAPSHOT" > "$WORK/outer-snapshot.log" 2>&1 \
  || fail "outer snapshot failed (no fixture had been written yet)"
"$GUARD" snapshot "$LAST_EXPECTED" >> "$WORK/outer-snapshot.log" 2>&1
say "outer_snapshot_captured state=user-original-before-any-write"

update_last_expected() { # only after a confirmed write or confirmed restore
  "$GUARD" snapshot "$LAST_EXPECTED" >> "$WORK/guard.log" 2>&1 || true
}

# --- 2. control instances (own identity only) ------------------------------
# Deferred until after the guard semantics check so a failure there cannot
# leave an application running.
close_control() { # close_control <dir>: re-verify identity, then bounded shutdown
  local dir="$1" pid desc exec_name
  pid="$(cat "$dir/pid" 2>/dev/null || true)"
  desc="$(cat "$dir/descriptor" 2>/dev/null || true)"
  exec_name="$(basename "$dir" | sed 's/^control-/CJGUISharedDocument/')"
  [[ -n "$pid" ]] || return 0
  # Ownership re-check through the shared identity library: the connection
  # descriptor is a plain published file that the application does not hold
  # open, so an lsof-only check reported "not ours" and left the control
  # instance running. Identity is the round-unique executable name plus the
  # per-round directory.
  cjgui_pid_owns "$pid" "$desc" "$exec_name" "$dir" || return 0
  if ! cjgui_terminate_owned "$pid" "$desc" "$exec_name" "$dir"; then
    say "note control_pid_still_alive pid=$pid dir=$(basename "$dir")"
  fi
}
cleanup_all() {
  for dir in "$WORK"/control-*(N); do
    [[ -d "$dir" ]] || continue
    close_control "$dir"
  done
}
trap cleanup_all EXIT

# Instance identity comes from the shared helper: descriptor holder when the
# descriptor is an open handle, otherwise the unique process whose command line
# carries both the round executable and the round directory, started at or after
# this round began.
descriptor_owner_pid() { # descriptor_owner_pid <descriptor> <exec-name> <dir> [since]
  cjgui_descriptor_owner_pid "$1" "$2" "$3" "${4:-}"
}

launch_control() { # launch_control <tag>
  local tag dir exec_name desc pid waited
  tag="$1"
  dir="$WORK/control-$tag"
  exec_name="CJGUISharedDocument$tag"
  mkdir -p "$dir"
  cp -R "$RUNTIME_DIR/examples/shared_document_window_app/src" "$dir/src"
  cp "$RUNTIME_DIR/examples/shared_document_window_app/cjpm.toml" "$dir/cjpm.toml"
  cp "$RUNTIME_DIR/examples/shared_document_window_app/cjgui_macos_app.sh" "$dir/cjgui_macos_app.sh"
  python3 - "$dir" "$RUNTIME_DIR" "$tag" <<'PYID'
import re
import sys
app, runtime, tag = sys.argv[1:4]
toml = open(f"{app}/cjpm.toml").read()
toml = re.sub(r'cjgui = \{ path = "[^"]+" \}', f'cjgui = {{ path = "{runtime}" }}', toml)
toml = re.sub(r'cjgui_shared_operation_core = \{ path = "[^"]+" \}',
              f'cjgui_shared_operation_core = {{ path = "{runtime}/shared_operation_core" }}', toml)
open(f"{app}/cjpm.toml", "w").write(toml)
m = open(f"{app}/cjgui_macos_app.sh").read()
m = m.replace("CJGUISharedDocument", f"CJGUISharedDocument{tag}")
m = m.replace("org.cangjie.cjgui.shared-document.example",
              f"org.cangjie.cjgui.shared-document.control.{tag}")
open(f"{app}/cjgui_macos_app.sh", "w").write(m)
PYID
  cat > "$dir/run.sh" <<RUNSH
#!/usr/bin/env zsh
exec zsh "$RUNTIME_DIR/scripts/run_macos_application.sh" "$dir/cjgui_macos_app.sh" "\$@"
RUNSH
  chmod +x "$dir/run.sh"
  local started
  started="$(date +%s)"
  ( cd "$dir" && nohup zsh run.sh --with-connection > "$dir/stdout.log" 2>&1 & )
  waited=0
  while (( waited < 90 )); do
    desc="$(grep 'CJGUI_SHARED_DOCUMENT_READY DESCRIPTOR_PATH' "$dir/stdout.log" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
    if [[ -n "$desc" && -f "$desc" ]]; then
      pid="$(descriptor_owner_pid "$desc" "$exec_name" "$dir" "$started" || true)"
      if [[ -n "$pid" ]]; then
        print -r -- "$pid" > "$dir/pid"
        print -r -- "$desc" > "$dir/descriptor"
        say "control_launched tag=$tag pid=$pid descriptor=$desc"
        return 0
      fi
    fi
    sleep 2; waited=$((waited + 2))
  done
  return 1
}

control_alive() { # control_alive <dir>
  local dir="$1" pid desc exec_name
  pid="$(cat "$dir/pid" 2>/dev/null || true)"
  desc="$(cat "$dir/descriptor" 2>/dev/null || true)"
  exec_name="$(basename "$dir" | sed 's/^control-/CJGUISharedDocument/')"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  # Same identity rule as cleanup: executable name + this round's own dir (the
  # published descriptor is not an open handle, so lsof alone proves nothing).
  cjgui_pid_owns "$pid" "$desc" "$exec_name" "$dir" || return 1
  # A real public read against the control instance's own descriptor: the
  # instance must still answer, not merely exist.
  [[ -n "$desc" && -f "$desc" ]] || return 1
  python3 "$RUNTIME_DIR/shared_operation_core/client.py" "$desc" get 2>/dev/null | grep -q '^KIND SNAPSHOT'
}

# --- 3. the tested chain, one run at a time ---------------------------------
# The tested chain's OWN exit code decides how this driver reports it:
#   0  the chain ran and its assertions held;
#   3  a verified environment precondition stopped it (BLOCKED, never a pass);
#   *  a product/verification failure (FAIL).
# A non-zero normal run is never downgraded to a logged note: that is how a red
# product result could previously still end in "PASSED all checks" with exit 0.
classify_child_exit() { # classify_child_exit <exit-code> -> ok|blocked|fail
  local rc="$1"
  case "$rc" in
    0) print -r -- "ok" ;;
    3) print -r -- "blocked" ;;
    *) print -r -- "fail" ;;
  esac
}

# The forced-failure injection is only a valid negative control when the run
# actually reached the injection point: a start-up failure must not be accepted
# as "the expected failure happened".
FORCED_FAILURE_REACHED_MARKER="step5 transfer_paste_ok"
FORCED_FAILURE_MARKER="forced failure after copy (test-only injection CHAIN_FORCE_FAIL_AFTER_COPY)"
verify_injection_point() { # verify_injection_point <chain-log>
  local log="$1"
  grep -q "$FORCED_FAILURE_REACHED_MARKER" "$log" 2>/dev/null || return 1
  grep -q "$FORCED_FAILURE_MARKER" "$log" 2>/dev/null || return 1
  return 0
}

# Deterministic, bounded fixture for the exit-code matrix: every class is
# verified from synthetic exit codes and logs, so the classification does not
# depend on re-running desktop chains, and a "reached the injection point" check
# is verified to reject a run that never got there.
selftest_classification() {
  local dir="$WORK/selftest" spec rc expected class
  mkdir -p "$dir"
  print -r -- "$FORCED_FAILURE_REACHED_MARKER" > "$dir/reached.log"
  print -r -- "$FORCED_FAILURE_MARKER" >> "$dir/reached.log"
  print -r -- "$FORCED_FAILURE_REACHED_MARKER" > "$dir/not-injected.log"
  for spec in "0:ok" "1:fail" "2:fail" "3:blocked" "130:fail"; do
    rc="${spec%%:*}"; expected="${spec#*:}"
    class="$(classify_child_exit "$rc")"
    [[ "$class" == "$expected" ]] || \
      fail "classification selftest: exit $rc classified '$class', expected '$expected'"
  done
  verify_injection_point "$dir/reached.log" || \
    fail "injection selftest: a reached injection point was not recognized"
  if verify_injection_point "$dir/not-injected.log"; then
    fail "injection selftest: a run that never reached the injection point was accepted"
  fi
  say "selftest_ok exit_matrix=0/1/2/3/130 injection_point=verified"
}

run_chain() { # run_chain <label> [env NAME=VALUE ...]
  local label="$1"; shift
  # `status` is a read-only special parameter in zsh: using it as the exit
  # accumulator aborted the whole script before the first chain finished.
  local log="$WORK/chain-$label.log" rc=0
  env "$@" zsh "$SCRIPT_DIR/verify_shared_document_transfer_chain.sh" > "$log" 2>&1 || rc=$?
  print -r -- "$rc" > "$WORK/chain-$label.status"
  say "tested_run label=$label exit=$rc log=$log"
  return 0
}

BLOCKED_REASONS=()

# Aftercare runs for EVERY child verdict: the real clipboard is verified against
# the user snapshot, and the control instance this driver owns must still be
# alive and answering (the tested run must never signal it).
handle_segment() { # handle_segment <label> <control-dir>
  local label="$1" ctrl="$2" rc log class reason
  rc="$(cat "$WORK/chain-$label.status")"
  log="$WORK/chain-$label.log"
  verify_clipboard_after "$label" "$log" "$rc"
  control_alive "$ctrl" || fail "control instance was killed by the '$label' run"
  class="$(classify_child_exit "$rc")"
  reason="$(grep -E '^(BLOCKED|FAIL)' "$log" 2>/dev/null | tail -1 || true)"
  case "$class" in
    ok)
      say "child_ok label=$label exit=0"
      say "isolation_ok ${label}_run_control_survived"
      ;;
    blocked)
      BLOCKED_REASONS+=("$label: $reason")
      say "child_blocked label=$label exit=$rc reason=$reason"
      ;;
    fail)
      fail "tested chain '$label' exited $rc (product/verification failure): $reason"
      ;;
  esac
  return 0
}

verify_clipboard_after() { # verify_clipboard_after <label> <chain-log> <exit>
  local label="$1" log="$2" child_status="$3" live fixture
  if "$GUARD" status "$OUTER_SNAPSHOT" >/dev/null 2>&1; then
    update_last_expected
    say "clipboard_ok label=$label state=user-original-intact exit=$child_status verified=after-exit"
    return 0
  fi
  live="$(osascript -e 'the clipboard as text' 2>/dev/null || true)"
  # (a) Our own fixture leaked (for example the child was killed mid-run).
  #     Recover it only while the live value is still exactly that fixture,
  #     then re-verify the real post-exit result.
  for fixture in "external-text" "W2" "W4"; do
    if [[ "$live" == "$fixture" ]]; then
      "$GUARD" restore-fixture "$OUTER_SNAPSHOT" "$fixture" >> "$WORK/guard.log" 2>&1 || true
      if "$GUARD" status "$OUTER_SNAPSHOT" >/dev/null 2>&1; then
        update_last_expected
        say "clipboard_recovered label=$label fixture=$fixture state=user-original-restored exit=$child_status verified=after-exit"
        return 0
      fi
      fail "clipboard recovery failed for own fixture '$fixture' after '$label'"
    fi
  done
  # (b) An external write is only accepted as the explanation when the child's
  #     own guard observed it: `clipboard_guard_observed_foreign` is printed
  #     only when the live pasteboard no longer matches the value this round
  #     last wrote. Without that observation an unexplained mismatch stays a
  #     failure - it could equally be a copy that never took effect or a
  #     product-side content error.
  if grep -q "clipboard_guard_observed_foreign" "$log" 2>/dev/null; then
    say "clipboard_ok label=$label state=foreign-observed-and-preserved exit=$child_status verified=after-exit text='$live'"
    return 0
  fi
  fail "clipboard after '$label' is neither the user snapshot nor an evidenced external write (text='$live'; the child guard never observed a foreign write)"
}

# --- 4. run the checks ------------------------------------------------------
selftest_classification

zsh "$SCRIPT_DIR/verify_clipboard_guard_semantics.sh" >> "$WORK/guard-semantics.log" 2>&1 \
  || fail "clipboard guard semantics failed (see $WORK/guard-semantics.log)"
say "guard_semantics_ok private_pasteboard_only"

# The classification matrix and the guard semantics are environment-independent.
# This mode runs exactly those two and exits, so a locked session still verifies
# the failure-classification logic instead of skipping the whole driver (the
# desktop chain runs in the interaction section of the sweep).
if [[ -n "${CJGUI_ISOLATION_HEADLESS_ONLY:-}" ]]; then
  say "headless_ok classification_matrix=true clipboard_guard_semantics=true"
  cat "$RESULT_LOG"
  exit 0
fi

launch_control "ctlA" || fail "control instance A did not start"
CTRL_A="$WORK/control-ctlA"
say "control_a_running pid=$(cat "$CTRL_A/pid")"

run_chain "normal"
handle_segment "normal" "$CTRL_A"

# Forced graceful-timeout path: cleanup skips the AX close and signals only the
# verified round PID. The chain itself is a normal run and must reach exit 0;
# the control must still survive.
launch_control "ctlB" || { fail "control instance B did not start"; }
CTRL_B="$WORK/control-ctlB"
say "control_b_running pid=$(cat "$CTRL_B/pid")"
run_chain "timeout" "CHAIN_SKIP_GRACEFUL=1"
handle_segment "timeout" "$CTRL_B"

# Forced failure inside the tested script, after it had already written the
# clipboard: a failing tested run must still leave the user's value intact, and
# the negative control only counts when the log proves the injection point was
# reached (a start-up failure is not "the expected failure").
run_chain "forced-failure" "CHAIN_FORCE_FAIL_AFTER_COPY=1"
FAILURE_STATUS="$(cat "$WORK/chain-forced-failure.status")"
FAILURE_LOG="$WORK/chain-forced-failure.log"
verify_clipboard_after "forced-failure" "$FAILURE_LOG" "$FAILURE_STATUS"
control_alive "$CTRL_B" || fail "control instance B was killed by the forced-failure run"
case "$(classify_child_exit "$FAILURE_STATUS")" in
  ok)
    fail "forced-failure injection unexpectedly exited 0"
    ;;
  blocked)
    BLOCKED_REASONS+=("forced-failure: environment precondition before the injection point ($(grep -E '^(BLOCKED|FAIL)' "$FAILURE_LOG" | tail -1 || true))")
    say "child_blocked label=forced-failure exit=$FAILURE_STATUS (injection not reached)"
    ;;
  fail)
    [[ "$FAILURE_STATUS" == "1" ]] || \
      fail "forced-failure injection must exit 1 (product-failure class), got $FAILURE_STATUS"
    verify_injection_point "$FAILURE_LOG" || \
      fail "forced-failure injection point was not reached (log=$FAILURE_LOG)"
    say "isolation_ok failed_run_left_clipboard_intact exit=$FAILURE_STATUS injection=reached"
    ;;
esac

# Only this round's own instances are ever signalled, and only after the
# identity is re-proven at that moment.
close_control "$CTRL_B"
close_control "$CTRL_A"

if (( ${#BLOCKED_REASONS[@]} > 0 )); then
  for reason in "${BLOCKED_REASONS[@]}"; do
    blocked "$reason"
  done
  say "BLOCKED a tested chain reported an environment precondition; isolation and clipboard aftercare still ran"
  cat "$RESULT_LOG"
  exit 3
fi
say "PASSED all checks"
cat "$RESULT_LOG"
exit 0
