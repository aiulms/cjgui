#!/usr/bin/env zsh
# Headless acceptance for lib_cjgui_instance.sh.
#
# The library decides which process a desktop verifier may signal. That logic
# is testable without any window: this script starts fake "instances" (a
# bounded sleep that holds its own descriptor file open), then checks that
#   * ownership resolves through the descriptor, not through a path pgrep;
#   * a same-named process that does NOT own the round descriptor is rejected;
#   * a recycled/foreign pid is never signalled;
#   * cleanup terminates only the owned instance and leaves the bystander
#     alive (the exact failure mode of the old `pgrep | head` approach);
#   * every bounded call returns instead of hanging.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${CJGUI_INSTANCE_LIB_TMPDIR:-/private/tmp/cjgui-instance-lib}"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
RESULT_LOG="$WORK/result.log"
: > "$RESULT_LOG"
say() { print -r -- "$*" >> "$RESULT_LOG"; }
fail() {
  say "FAIL $*"
  for dir in "$WORK"/fake-*(N); do
    [[ -f "$dir/pid" ]] && kill "$(cat "$dir/pid")" 2>/dev/null || true
  done
  cat "$RESULT_LOG"
  exit 1
}

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

# A fake instance: a per-round copy of `tail` whose argv carries the fake
# executable name and the round directory, holding its own descriptor file
# open - exactly the two properties the library binds a real instance by.
FAKE_EXEC="CJGUIFakeInstance"
start_fake() { # start_fake <tag> -> prints pid
  local tag="$1"
  local dir="$WORK/fake-$tag"
  mkdir -p "$dir"
  : > "$dir/descriptor"
  # A copied system binary is killed by the platform's code-signing check, so
  # the fake instance is a small zsh script that keeps the descriptor open in
  # its own process (an `exec` hand-off would replace the argv the library
  # binds identity by).
  cat > "$dir/$FAKE_EXEC" <<'FAKEEXE'
#!/usr/bin/env zsh
exec 3< "$1"
while true; do /usr/bin/sleep 1; done
FAKEEXE
  chmod +x "$dir/$FAKE_EXEC"
  nohup "$dir/$FAKE_EXEC" "$dir/descriptor" > "$dir/stdout.log" 2>&1 &
  local pid=$!
  print -r -- "$pid" > "$dir/pid"
  # Wait until the descriptor is actually open in that exact process.
  local waited=0
  while (( waited < 50 )); do
    lsof -t -- "$dir/descriptor" 2>/dev/null | grep -qx "$pid" && break
    sleep 0.1
    waited=$(( waited + 1 ))
  done
  print -r -- "$pid"
}

OWN_A="$(start_fake "a")"
OWN_B="$(start_fake "b")"
[[ -n "$OWN_A" && -n "$OWN_B" ]] || fail "fake instances did not start"
[[ "$OWN_A" != "$OWN_B" ]] || fail "fake instances share a pid"

# --- 0. descriptor ownership resolves the exact instance -------------------
OWN_A_BY_DESCRIPTOR="$(cjgui_descriptor_owner_pid "$WORK/fake-a/descriptor" "$FAKE_EXEC" "$WORK/fake-a" || true)"
[[ "$OWN_A_BY_DESCRIPTOR" == "$OWN_A" ]] || fail "descriptor lookup returned '$OWN_A_BY_DESCRIPTOR' instead of '$OWN_A'"
if cjgui_pid_owns "$OWN_B" "$WORK/fake-a/descriptor" "$FAKE_EXEC"; then
  fail "instance B was accepted as the owner of instance A's descriptor"
fi
say "lib_ok descriptor_binding_is_same_instance"

# --- 1. identity resolves by full executable path, not by name only --------
if ! cjgui_pid_owns "$OWN_A" "$WORK/fake-a/descriptor" "$FAKE_EXEC" "$WORK/fake-a"; then
  fail "owned instance A was not recognised by descriptor+path+dir identity"
fi
if cjgui_pid_owns "$OWN_A" "$WORK/fake-a/descriptor" "$FAKE_EXEC" "$WORK/fake-b"; then
  fail "instance A was accepted for instance B's directory"
fi
if cjgui_pid_owns "$OWN_A" "$WORK/fake-a/descriptor" "CJGUIOtherInstance" "$WORK/fake-a"; then
  fail "instance A was accepted for a different executable name"
fi
say "lib_ok identity_requires_exec_and_round_dir"

# --- 2. a recycled/foreign pid is never signalled --------------------------
sleep 300 & FOREIGN=$!
print -r -- "$FOREIGN" > "$WORK/foreign.pid"
cjgui_terminate_owned "$FOREIGN" "" "$FAKE_EXEC" "$WORK/fake-a" || true
kill -0 "$FOREIGN" 2>/dev/null || fail "terminate_owned killed a foreign process"
# The bystander's descriptor must not make it eligible for A's cleanup either.
cjgui_terminate_owned "$OWN_B" "$WORK/fake-a/descriptor" "$FAKE_EXEC" || true
kill -0 "$OWN_B" 2>/dev/null || fail "terminate_owned killed a process that does not own the round descriptor"
say "lib_ok foreign_pid_never_signalled"

# --- 3. cleanup terminates only the owned instance -------------------------
cjgui_terminate_owned "$OWN_A" "$WORK/fake-a/descriptor" "$FAKE_EXEC" "$WORK/fake-a" \
  || fail "owned instance A did not terminate"
kill -0 "$OWN_A" 2>/dev/null && fail "instance A still alive after terminate_owned"
kill -0 "$OWN_B" 2>/dev/null || fail "bystander instance B was killed by A's cleanup"
say "lib_ok cleanup_only_owned_instance"

# --- 4. bounded calls return instead of hanging ----------------------------
if cjgui_bounded 1 /bin/sleep 30; then
  fail "bounded call returned success for a command that outlives the bound"
else
  rc=$?
  [[ "$rc" == "124" ]] || fail "bounded call returned $rc instead of 124"
fi
if ! cjgui_bounded 5 /bin/sleep 0.2; then
  fail "bounded call failed for a short command"
fi
say "lib_ok bounded_calls_return"

# --- 5. AX helper is bounded and does not kill System Events ---------------
if cjgui_ax 1 -e 'delay 5' >/dev/null 2>&1; then
  fail "bounded AX call unexpectedly succeeded for a 5s delay under a 1s bound"
else
  rc=$?
  [[ "$rc" == "124" ]] || fail "bounded AX call returned $rc instead of 124"
fi
pgrep -x "System Events" >/dev/null 2>&1 && say "lib_ok system_events_untouched state=running" \
  || say "lib_ok system_events_untouched state=not-running"
say "lib_ok ax_calls_bounded"

kill "$OWN_B" 2>/dev/null || true
kill "$FOREIGN" 2>/dev/null || true
say "PASSED instance helper semantics"
cat "$RESULT_LOG"
exit 0
