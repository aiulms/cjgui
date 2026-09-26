# Desktop-session diagnosis.
#
# A real-input chain needs to distinguish an unavailable desktop from a product
# failure. This helper deliberately requires an explicit, reliable session fact
# before returning a blocking state:
#
#   active                - an explicit unlocked console session and a window
#   locked                - an explicit window-server lock signal
#   session_inaccessible  - no console session
#   ax_tool_error         - an accessibility/tool probe failed
#   unknown               - the probes completed but do not establish either
#                           an available window or an environment block
#
# The result and all probe evidence come from one bounded sample. The sample is
# cached in a per-source temporary file as well as shell variables because
# callers commonly use command substitution (`state="$(...)"`); that otherwise
# runs the function in a child shell and would make a later diagnostic resample
# the desktop.

typeset -g _CJGUI_SESSION_SAMPLE_READY=0
typeset -g _CJGUI_SESSION_SAMPLE_STATE=""
typeset -g _CJGUI_SESSION_SAMPLE_CACHE_FILE="${TMPDIR:-/tmp}/cjgui-session-guard-${PPID}-${RANDOM}-${EPOCHSECONDS:-0}"

_cjgui_session_one_line() {
  local value="$1"
  value="${value//$'\r'/ }"
  value="${value//$'\n'/ }"
  value="${value//$'\t'/ }"
  print -r -- "$value"
}

_cjgui_session_cache_reset_variables() {
  _CJGUI_SESSION_SAMPLE_READY=0
  _CJGUI_SESSION_SAMPLE_STATE=""
  _CJGUI_SESSION_LOCKED_VALUE=""
  _CJGUI_SESSION_LOCKED_RC=""
  _CJGUI_SESSION_LOCKED_ERROR=""
  _CJGUI_SESSION_LOCKED_SOURCE="window-server:IOConsoleUsers[console]"
  _CJGUI_SESSION_CONSOLE_VALUE=""
  _CJGUI_SESSION_CONSOLE_RC=""
  _CJGUI_SESSION_CONSOLE_ERROR=""
  _CJGUI_SESSION_CONSOLE_SOURCE="window-server:IOConsoleUsers[kCGSSessionOnConsoleKey]"
  _CJGUI_SESSION_FRONT_VALUE=""
  _CJGUI_SESSION_FRONT_RC=""
  _CJGUI_SESSION_FRONT_ERROR=""
  _CJGUI_SESSION_FRONT_SOURCE="System Events:frontmost application process"
  _CJGUI_SESSION_WINDOWS_VALUE=""
  _CJGUI_SESSION_WINDOWS_RC=""
  _CJGUI_SESSION_WINDOWS_ERROR=""
  _CJGUI_SESSION_WINDOWS_SOURCE="System Events:frontmost application process windows"
}

_cjgui_session_cache_write() {
  local key value
  : >| "$_CJGUI_SESSION_SAMPLE_CACHE_FILE" || return 1
  for key in \
    _CJGUI_SESSION_SAMPLE_STATE \
    _CJGUI_SESSION_LOCKED_VALUE _CJGUI_SESSION_LOCKED_RC _CJGUI_SESSION_LOCKED_ERROR \
    _CJGUI_SESSION_LOCKED_SOURCE _CJGUI_SESSION_CONSOLE_VALUE _CJGUI_SESSION_CONSOLE_RC \
    _CJGUI_SESSION_CONSOLE_ERROR _CJGUI_SESSION_CONSOLE_SOURCE _CJGUI_SESSION_FRONT_VALUE \
    _CJGUI_SESSION_FRONT_RC _CJGUI_SESSION_FRONT_ERROR _CJGUI_SESSION_FRONT_SOURCE \
    _CJGUI_SESSION_WINDOWS_VALUE _CJGUI_SESSION_WINDOWS_RC _CJGUI_SESSION_WINDOWS_ERROR \
    _CJGUI_SESSION_WINDOWS_SOURCE; do
    value="${(P)key}"
    printf '%s\t%s\n' "$key" "$(_cjgui_session_one_line "$value")" >> "$_CJGUI_SESSION_SAMPLE_CACHE_FILE"
  done
  printf '%s\t%s\n' _CJGUI_SESSION_SAMPLE_READY 1 >> "$_CJGUI_SESSION_SAMPLE_CACHE_FILE"
}

_cjgui_session_cache_load() {
  [[ -s "$_CJGUI_SESSION_SAMPLE_CACHE_FILE" ]] || return 1
  local key value
  _cjgui_session_cache_reset_variables
  while IFS=$'\t' read -r key value; do
    case "$key" in
      _CJGUI_SESSION_SAMPLE_STATE|\
      _CJGUI_SESSION_LOCKED_VALUE|_CJGUI_SESSION_LOCKED_RC|_CJGUI_SESSION_LOCKED_ERROR|\
      _CJGUI_SESSION_LOCKED_SOURCE|_CJGUI_SESSION_CONSOLE_VALUE|_CJGUI_SESSION_CONSOLE_RC|\
      _CJGUI_SESSION_CONSOLE_ERROR|_CJGUI_SESSION_CONSOLE_SOURCE|_CJGUI_SESSION_FRONT_VALUE|\
      _CJGUI_SESSION_FRONT_RC|_CJGUI_SESSION_FRONT_ERROR|_CJGUI_SESSION_FRONT_SOURCE|\
      _CJGUI_SESSION_WINDOWS_VALUE|_CJGUI_SESSION_WINDOWS_RC|_CJGUI_SESSION_WINDOWS_ERROR|\
      _CJGUI_SESSION_WINDOWS_SOURCE)
        typeset -g "$key=$value"
        ;;
      _CJGUI_SESSION_SAMPLE_READY)
        [[ "$value" == 1 ]] || return 1
        _CJGUI_SESSION_SAMPLE_READY=1
        ;;
    esac
  done < "$_CJGUI_SESSION_SAMPLE_CACHE_FILE"
  [[ "$_CJGUI_SESSION_SAMPLE_READY" == 1 ]]
}

# Remove the one-sample memo. Tests use this between controlled counterexamples;
# production callers can use it when they intentionally begin a new round.
real_ax_session_reset_sample() {
  _cjgui_session_cache_reset_variables
  rm -f -- "$_CJGUI_SESSION_SAMPLE_CACHE_FILE"
}

_cjgui_session_run_bounded() {
  local seconds="${CJGUI_SESSION_PROBE_TIMEOUT_SECONDS:-5}"
  [[ "$seconds" == <-> && "$seconds" -gt 0 ]] || seconds=5
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  elif command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV' "$seconds" "$@"
  else
    print -u2 -- "session guard cannot run bounded probe: timeout and perl unavailable"
    return 125
  fi
}

# Explicit lock signal from the window server. The selected IOConsoleUsers
# entry is the actual console session. Missing fields remain empty; they are
# never converted to false.
real_ax_session_screen_locked() {
  _cjgui_session_run_bounded ioreg -n Root -d1 -a | python3 -c '
import plistlib, sys
try:
    data = plistlib.loads(sys.stdin.buffer.read())
except Exception as exc:
    print("ioreg plist parse failed: %s" % exc, file=sys.stderr)
    raise SystemExit(2)
users = data.get("IOConsoleUsers")
if users is None:
    print("IOConsoleUsers missing", file=sys.stderr)
    raise SystemExit(2)
if not users:
    print("")
    raise SystemExit(0)
console = [u for u in users if u.get("kCGSSessionOnConsoleKey") is True]
if len(console) != 1:
    print("")
    raise SystemExit(0)
value = console[0].get("CGSSessionScreenIsLocked")
if value is True or value == 1:
    print("true")
elif value is False or value == 0:
    print("false")
else:
    print("")
' 
}

# Whether the window server has a logged-in user owning the display. An empty
# IOConsoleUsers list is a reliable false; a missing flag is unknown.
real_ax_session_on_console() {
  _cjgui_session_run_bounded ioreg -n Root -d1 -a | python3 -c '
import plistlib, sys
try:
    data = plistlib.loads(sys.stdin.buffer.read())
except Exception as exc:
    print("ioreg plist parse failed: %s" % exc, file=sys.stderr)
    raise SystemExit(2)
users = data.get("IOConsoleUsers")
if users is None:
    print("IOConsoleUsers missing", file=sys.stderr)
    raise SystemExit(2)
if not users:
    print("false")
    raise SystemExit(0)
flags = [u.get("kCGSSessionOnConsoleKey") for u in users]
if any(value is True for value in flags):
    print("true")
elif all(value is False for value in flags):
    print("false")
else:
    print("")
' 
}

# Query the actual frontmost application process. `first process` is merely the
# enumeration order and can be loginwindow even while a user session is active.
# A front-process name is diagnostic context; it is not a lock assertion by
# itself. The explicit window-server lock fact above owns that decision.
real_ax_session_front_process() {
  _cjgui_session_run_bounded osascript -e 'tell application "System Events" to return name of first application process whose frontmost is true'
}

# Count windows on the process that was frontmost for this probe. An empty count
# is kept as unknown; a non-zero exit is an AX/tool error.
real_ax_session_window_count() {
  _cjgui_session_run_bounded osascript -e 'tell application "System Events"
    set p to first application process whose frontmost is true
    return (count of windows of p) as string
  end tell'
}

_cjgui_session_capture_probe() {
  local value_var="$1" rc_var="$2" error_var="$3" source_var="$4" label="$5" command="$6"
  local error_file="${_CJGUI_SESSION_SAMPLE_CACHE_FILE}.${label}.err"
  local value rc error
  value="$($command 2>"$error_file")"
  rc=$?
  error=""
  [[ -e "$error_file" ]] && error="$(<"$error_file")"
  rm -f -- "$error_file"
  value="$(_cjgui_session_one_line "$value")"
  error="$(_cjgui_session_one_line "$error")"
  typeset -g "$value_var=$value"
  typeset -g "$rc_var=$rc"
  typeset -g "$error_var=$error"
  typeset -g "$source_var=$(_cjgui_session_one_line "${(P)source_var}")"
}

# One bounded sample shared by state, availability, blocking and diagnostics.
real_ax_session_sample() {
  if [[ "$_CJGUI_SESSION_SAMPLE_READY" == 1 ]]; then
    return 0
  fi
  _cjgui_session_cache_load && return 0

  _cjgui_session_cache_reset_variables
  _cjgui_session_capture_probe _CJGUI_SESSION_LOCKED_VALUE _CJGUI_SESSION_LOCKED_RC \
    _CJGUI_SESSION_LOCKED_ERROR _CJGUI_SESSION_LOCKED_SOURCE locked real_ax_session_screen_locked
  _cjgui_session_capture_probe _CJGUI_SESSION_CONSOLE_VALUE _CJGUI_SESSION_CONSOLE_RC \
    _CJGUI_SESSION_CONSOLE_ERROR _CJGUI_SESSION_CONSOLE_SOURCE console real_ax_session_on_console
  _cjgui_session_capture_probe _CJGUI_SESSION_FRONT_VALUE _CJGUI_SESSION_FRONT_RC \
    _CJGUI_SESSION_FRONT_ERROR _CJGUI_SESSION_FRONT_SOURCE front real_ax_session_front_process
  _cjgui_session_capture_probe _CJGUI_SESSION_WINDOWS_VALUE _CJGUI_SESSION_WINDOWS_RC \
    _CJGUI_SESSION_WINDOWS_ERROR _CJGUI_SESSION_WINDOWS_SOURCE windows real_ax_session_window_count

  if [[ "$_CJGUI_SESSION_LOCKED_VALUE" == true && "$_CJGUI_SESSION_LOCKED_RC" == 0 ]]; then
    _CJGUI_SESSION_SAMPLE_STATE=locked
  elif [[ "$_CJGUI_SESSION_CONSOLE_VALUE" == false && "$_CJGUI_SESSION_CONSOLE_RC" == 0 ]]; then
    _CJGUI_SESSION_SAMPLE_STATE=session_inaccessible
  elif (( _CJGUI_SESSION_LOCKED_RC != 0 || _CJGUI_SESSION_CONSOLE_RC != 0 ||
          _CJGUI_SESSION_FRONT_RC != 0 || _CJGUI_SESSION_WINDOWS_RC != 0 )); then
    _CJGUI_SESSION_SAMPLE_STATE=ax_tool_error
  elif [[ -n "$_CJGUI_SESSION_LOCKED_ERROR$_CJGUI_SESSION_CONSOLE_ERROR$_CJGUI_SESSION_FRONT_ERROR$_CJGUI_SESSION_WINDOWS_ERROR" ]]; then
    _CJGUI_SESSION_SAMPLE_STATE=ax_tool_error
  elif [[ "$_CJGUI_SESSION_LOCKED_VALUE" != true && "$_CJGUI_SESSION_LOCKED_VALUE" != false ||
          "$_CJGUI_SESSION_CONSOLE_VALUE" != true && "$_CJGUI_SESSION_CONSOLE_VALUE" != false ]]; then
    _CJGUI_SESSION_SAMPLE_STATE=unknown
  elif [[ -z "$_CJGUI_SESSION_FRONT_VALUE" || "$_CJGUI_SESSION_FRONT_VALUE" == loginwindow ]]; then
    # A missing or contradictory frontmost fact cannot be promoted by a window
    # count. In particular, loginwindow in an enumeration/front probe is not a
    # standalone lock assertion.
    _CJGUI_SESSION_SAMPLE_STATE=unknown
  elif [[ "$_CJGUI_SESSION_WINDOWS_VALUE" == <-> ]] && (( _CJGUI_SESSION_WINDOWS_VALUE > 0 )); then
    _CJGUI_SESSION_SAMPLE_STATE=active
  else
    _CJGUI_SESSION_SAMPLE_STATE=unknown
  fi

  _CJGUI_SESSION_SAMPLE_READY=1
  _cjgui_session_cache_write || return 1
}

real_ax_session_state() {
  real_ax_session_sample || return 1
  print -r -- "$_CJGUI_SESSION_SAMPLE_STATE"
}

real_ax_desktop_session_available() {
  real_ax_session_sample || return 1
  [[ "$_CJGUI_SESSION_SAMPLE_STATE" == active ]]
}

# Only explicit environment facts are strong enough to stop a real-input chain.
real_ax_session_blocking() {
  real_ax_session_sample || return 1
  [[ "$_CJGUI_SESSION_SAMPLE_STATE" == locked ||
     "$_CJGUI_SESSION_SAMPLE_STATE" == session_inaccessible ]]
}

# Human-readable evidence line. All fields come from the same sample used by the
# immediately preceding state/blocking call.
real_ax_session_diagnostic() {
  real_ax_session_sample || return 1
  print -r -- "session_state=$_CJGUI_SESSION_SAMPLE_STATE locked=$_CJGUI_SESSION_LOCKED_VALUE locked_probe_rc=$_CJGUI_SESSION_LOCKED_RC locked_probe_error='$_CJGUI_SESSION_LOCKED_ERROR' locked_source=$_CJGUI_SESSION_LOCKED_SOURCE on_console=$_CJGUI_SESSION_CONSOLE_VALUE on_console_probe_rc=$_CJGUI_SESSION_CONSOLE_RC on_console_probe_error='$_CJGUI_SESSION_CONSOLE_ERROR' on_console_source=$_CJGUI_SESSION_CONSOLE_SOURCE front_process=$_CJGUI_SESSION_FRONT_VALUE front_probe_rc=$_CJGUI_SESSION_FRONT_RC front_probe_error='$_CJGUI_SESSION_FRONT_ERROR' front_source=$_CJGUI_SESSION_FRONT_SOURCE session_app_windows=$_CJGUI_SESSION_WINDOWS_VALUE windows_probe_rc=$_CJGUI_SESSION_WINDOWS_RC windows_probe_error='$_CJGUI_SESSION_WINDOWS_ERROR' windows_source=$_CJGUI_SESSION_WINDOWS_SOURCE"
}
