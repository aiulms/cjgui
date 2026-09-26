#!/usr/bin/env zsh
# C1: classify only from reliable session facts and retain one probe sample for
# state, blocking and diagnostics. The cases are controlled probe boundaries;
# the final case invokes the real bounded probes once.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/lib_cjgui_session_guard.sh"

failures=0
check_state() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$expected" == "$actual" ]]; then
    print -r -- "PASS session_guard case=${label} state=${actual}"
  else
    print -r -- "FAIL session_guard case=${label} expected=${expected} actual=${actual}"
    failures=$(( failures + 1 ))
  fi
}

check_blocking() {
  local expected="$1" label="$2" rc
  if real_ax_session_blocking; then
    rc=0
  else
    rc=$?
  fi
  if [[ "$expected" == true && "$rc" == 0 || "$expected" == false && "$rc" != 0 ]]; then
    print -r -- "PASS session_guard case=${label} blocking=${expected}"
  else
    print -r -- "FAIL session_guard case=${label} blocking=${expected} actual_rc=${rc}"
    failures=$(( failures + 1 ))
  fi
}

reset_case() {
  real_ax_session_reset_sample
}

# 1. The process enumeration may begin with loginwindow. That is not the
# frontmost query and, even as returned context, cannot override explicit
# locked=false. A contradictory loginwindow/window combination remains unknown
# and non-blocking.
reset_case
real_ax_session_screen_locked() { print -r -- false }
real_ax_session_on_console() { print -r -- true }
real_ax_session_front_process() { print -r -- loginwindow }
real_ax_session_window_count() { print -r -- 1 }
check_state unknown "$(real_ax_session_state)" "enumeration_loginwindow_with_unlocked_target"
check_blocking false "enumeration_loginwindow_with_unlocked_target"

# 2. An explicit lock signal is the environment fact that blocks the chain.
reset_case
real_ax_session_screen_locked() { print -r -- true }
real_ax_session_on_console() { print -r -- true }
real_ax_session_front_process() { print -r -- Finder }
real_ax_session_window_count() { print -r -- 0 }
check_state locked "$(real_ax_session_state)" "explicit_lock_screen"
check_blocking true "explicit_lock_screen"

# 3. AX/tool failure is diagnostic, not a lock and not a product failure.
reset_case
real_ax_session_screen_locked() { print -r -- false }
real_ax_session_on_console() { print -r -- true }
real_ax_session_front_process() { print -u2 -- "osascript not authorized"; return 77 }
real_ax_session_window_count() { print -r -- 1 }
check_state ax_tool_error "$(real_ax_session_state)" "ax_probe_error"
check_blocking false "ax_probe_error"

# 4. A positively usable session has explicit unlocked/console facts and a
# frontmost process window.
reset_case
real_ax_session_screen_locked() { print -r -- false }
real_ax_session_on_console() { print -r -- true }
real_ax_session_front_process() { print -r -- Finder }
real_ax_session_window_count() { print -r -- 3 }
check_state active "$(real_ax_session_state)" "active_session_with_windows"
real_ax_desktop_session_available
if (( $? == 0 )); then
  print -r -- "PASS session_guard case=active_session_with_windows available=true"
else
  print -r -- "FAIL session_guard case=active_session_with_windows available=false"
  failures=$(( failures + 1 ))
fi

# 5. No console session is a separate environment fact and is blocking.
reset_case
real_ax_session_screen_locked() { print -r -- "" }
real_ax_session_on_console() { print -r -- false }
real_ax_session_front_process() { print -r -- "" }
real_ax_session_window_count() { print -r -- "" }
check_state session_inaccessible "$(real_ax_session_state)" "no_console_session"
check_blocking true "no_console_session"

# 6. An unlocked desktop whose common/frontmost application has no window is
# unknown, not blocked. A missing window must not become false lock evidence.
reset_case
real_ax_session_screen_locked() { print -r -- false }
real_ax_session_on_console() { print -r -- true }
real_ax_session_front_process() { print -r -- Finder }
real_ax_session_window_count() { print -r -- 0 }
check_state unknown "$(real_ax_session_state)" "unlocked_without_addressable_window"
check_blocking false "unlocked_without_addressable_window"

# 7. Missing lock data stays unknown even when a window exists; it is never
# silently defaulted to false.
reset_case
real_ax_session_screen_locked() { print -r -- "" }
real_ax_session_on_console() { print -r -- true }
real_ax_session_front_process() { print -r -- Finder }
real_ax_session_window_count() { print -r -- 1 }
check_state unknown "$(real_ax_session_state)" "missing_lock_fact"
check_blocking false "missing_lock_fact"

# 8. The implementation must use the actual frontmost predicate. Keep this a
# source boundary assertion in addition to the controlled result above.
if rg -q "whose frontmost is true" "$script_dir/lib_cjgui_session_guard.sh" && \
   ! rg -q "name of first process([[:space:]]|$)" "$script_dir/lib_cjgui_session_guard.sh"; then
  print -r -- "PASS session_guard case=frontmost_query_source"
else
  print -r -- "FAIL session_guard case=frontmost_query_source"
  failures=$(( failures + 1 ))
fi

# 9. State, blocking and diagnostic share one bounded probe round. Four probe
# calls are expected even though state is first requested in a child shell.
reset_case
counter_file="$(mktemp "${TMPDIR:-/tmp}/cjgui-session-guard-count.XXXXXX")"
real_ax_session_screen_locked() { print -r -- locked >> "$counter_file"; print -r -- false }
real_ax_session_on_console() { print -r -- console >> "$counter_file"; print -r -- true }
real_ax_session_front_process() { print -r -- front >> "$counter_file"; print -r -- Finder }
real_ax_session_window_count() { print -r -- windows >> "$counter_file"; print -r -- 1 }
check_state active "$(real_ax_session_state)" "one_sample_state"
if real_ax_session_blocking; then
  :
fi
real_ax_session_diagnostic >/dev/null
sample_calls="$(wc -l < "$counter_file" | tr -d ' ')"
rm -f -- "$counter_file"
if [[ "$sample_calls" == 4 ]]; then
  print -r -- "PASS session_guard case=one_sample_state_blocking_diagnostic calls=${sample_calls}"
else
  print -r -- "FAIL session_guard case=one_sample_state_blocking_diagnostic calls=${sample_calls}"
  failures=$(( failures + 1 ))
fi

# 10. One bounded real probe round. This is a live classification only; it does
# not claim that any product window or control is present.
real_state="$(zsh -c 'source "'"$script_dir"'/lib_cjgui_session_guard.sh"; real_ax_session_state')"
case "$real_state" in
  active|locked|session_inaccessible|ax_tool_error|unknown)
    print -r -- "PASS session_guard case=real_probe state=${real_state}"
    ;;
  *)
    print -r -- "FAIL session_guard case=real_probe unexpected_state='${real_state}'"
    failures=$(( failures + 1 ))
    ;;
esac

if (( failures > 0 )); then
  print -r -- "FAILED session guard classification failures=${failures}"
  exit 1
fi
print -r -- "PASSED session guard classification"
