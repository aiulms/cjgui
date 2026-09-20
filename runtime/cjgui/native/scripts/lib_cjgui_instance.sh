#!/usr/bin/env zsh
# Shared instance-ownership helpers for CJGUI desktop verifiers.
#
# Rules implemented here (see AGENTS "已授权窗口验收"):
#   * A round may only signal the process it launched: identity is proven by
#     the round's own connection descriptor, the exact executable path and the
#     per-round directory - never by "first pid matching a path".
#   * Cleanup re-checks ownership before every signal and never touches a user
#     instance, a bystander control instance or a recycled PID.
#   * Every desktop tool call is bounded, so a hung AX bridge returns instead
#     of stalling the round; this library never kills System Events or changes
#     system settings to work around a driver failure.
#
# Source it after the caller has defined RUN_TAG/WORK and before launching.
# All helpers are plain zsh + `ps` + `lsof`; none of them writes the clipboard
# or the general pasteboard.

# cjgui_bounded <seconds> <command...>
# Runs a command with a hard upper bound. Returns the command's status, or 124
# when the bound expired (the child is then terminated).
cjgui_bounded() {
  local limit="$1"; shift
  local ticks=$(( limit * 10 ))
  # `status` is read-only in zsh; use a plain result variable.
  local waited=0 child rc=0
  "$@" &
  child=$!
  while kill -0 "$child" 2>/dev/null; do
    if (( waited >= ticks )); then
      kill -9 "$child" 2>/dev/null || true
      wait "$child" 2>/dev/null || true
      return 124
    fi
    sleep 0.1
    waited=$(( waited + 1 ))
  done
  wait "$child" || rc=$?
  return $rc
}

# cjgui_ax <seconds> <osascript argument...>
cjgui_ax() {
  local limit="$1"; shift
  cjgui_bounded "$limit" osascript "$@"
}

# cjgui_process_start_epoch <pid>
# Prints the process start time as a Unix epoch, or fails when it cannot be
# parsed. The elapsed-time field is used instead of the localized `lstart`
# string so the check works under any system locale.
cjgui_process_start_epoch() {
  local pid="$1" etime days=0 hours=0 minutes=0 seconds=0 now
  etime="$(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ')"
  [[ -n "$etime" ]] || return 1
  if [[ "$etime" == *-* ]]; then
    days="${etime%%-*}"
    etime="${etime#*-}"
  fi
  local parts
  parts=(${(s/:/)etime})
  if (( ${#parts} == 3 )); then
    hours="${parts[1]}"; minutes="${parts[2]}"; seconds="${parts[3]}"
  elif (( ${#parts} == 2 )); then
    minutes="${parts[1]}"; seconds="${parts[2]}"
  else
    return 1
  fi
  [[ "$days" == <-> && "$hours" == <-> && "$minutes" == <-> && "$seconds" == <-> ]] || return 1
  now="$(date +%s)"
  print -r -- $(( now - (days * 86400 + hours * 3600 + minutes * 60 + seconds) ))
}

# cjgui_descriptor_owner_pid <descriptor> <exec-path-or-name> [dir-hint] [since-epoch]
#
# Prints the single PID bound to this round's descriptor. Two bindings are
# accepted, in order:
#   1. the process that currently holds the descriptor open (lsof), when the
#      descriptor is an open socket/handle;
#   2. otherwise the unique process whose full command line carries both the
#      round executable and the round directory, started at or after
#      `since-epoch` when that is given.
# A round-unique executable name/directory plus the descriptor this instance
# itself published is the same-instance binding; "first pid matching a path"
# is deliberately not used, and an ambiguous match fails instead of guessing.
cjgui_descriptor_owner_pid() {
  local desc="$1" exec_name="$2" dir_hint="${3:-}" since="${4:-}" pid command_line started
  [[ -n "$desc" && -e "$desc" ]] || return 1
  for pid in $(lsof -t -- "$desc" 2>/dev/null || true); do
    command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    [[ -n "$command_line" ]] || continue
    [[ "$command_line" == *"$exec_name"* ]] || continue
    if [[ -n "$dir_hint" ]]; then
      [[ "$command_line" == *"$dir_hint"* ]] || continue
    fi
    print -r -- "$pid"
    return 0
  done
  local count=0 found=""
  for pid in $(pgrep -f "$exec_name" 2>/dev/null || true); do
    kill -0 "$pid" 2>/dev/null || continue
    command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    [[ "$command_line" == *"$exec_name"* ]] || continue
    if [[ -n "$dir_hint" ]]; then
      [[ "$command_line" == *"$dir_hint"* ]] || continue
    fi
    if [[ -n "$since" ]]; then
      started="$(cjgui_process_start_epoch "$pid" || true)"
      [[ -n "$started" ]] || continue
      (( started >= since )) || continue
    fi
    count=$(( count + 1 ))
    found="$pid"
  done
  (( count == 1 )) || return 1
  print -r -- "$found"
}

# cjgui_pid_owns <pid> <descriptor> <exec-path-or-name> [dir-hint]
cjgui_pid_owns() {
  local pid="$1" desc="$2" exec_name="$3" dir_hint="${4:-}" command_line owners
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
  [[ -n "$command_line" ]] || return 1
  [[ "$command_line" == *"$exec_name"* ]] || return 1
  if [[ -n "$dir_hint" ]]; then
    [[ "$command_line" == *"$dir_hint"* ]] || return 1
  fi
  if [[ -n "$desc" && -e "$desc" ]]; then
    owners="$(lsof -t -- "$desc" 2>/dev/null || true)"
    if [[ -n "$owners" ]]; then
      print -r -- "$owners" | grep -qx "$pid" || return 1
    fi
  fi
  return 0
}

# cjgui_terminate_owned <pid> <descriptor> <exec-path-or-name> [dir-hint]
# Bounded graceful shutdown of a process this round owns. Never signals a
# process whose ownership cannot be re-proven at that moment.
cjgui_terminate_owned() {
  local pid="$1" desc="$2" exec_name="$3" dir_hint="${4:-}" waited=0
  cjgui_pid_owns "$pid" "$desc" "$exec_name" "$dir_hint" || return 0
  kill "$pid" 2>/dev/null || true
  while (( waited < 40 )); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.25
    waited=$(( waited + 1 ))
  done
  cjgui_pid_owns "$pid" "$desc" "$exec_name" "$dir_hint" || return 0
  kill -9 "$pid" 2>/dev/null || true
  waited=0
  while (( waited < 20 )); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.25
    waited=$(( waited + 1 ))
  done
  return 1
}

# cjgui_launch_bound <app-dir> <launcher> <ready-pattern> <exec-path-or-name> <stdout-log> <timeout-seconds> [extra args...]
# Launches one round instance and returns only when the descriptor printed by
# that instance is owned by a process matching the executable identity.
# Prints "<pid> <descriptor>" and leaves them in CJGUI_APP_PID/CJGUI_DESCRIPTOR.
cjgui_launch_bound() {
  local app_dir="$1" launcher="$2" ready_pattern="$3" exec_name="$4" stdout_log="$5" limit="$6"
  shift 6
  local waited=0 descriptor="" pid=""
  ( cd "$app_dir" && nohup zsh "$launcher" "$@" > "$stdout_log" 2>&1 & )
  while (( waited < limit )); do
    descriptor="$(grep "$ready_pattern" "$stdout_log" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
    if [[ -n "$descriptor" && -f "$descriptor" ]]; then
      pid="$(cjgui_descriptor_owner_pid "$descriptor" "$exec_name" "$app_dir" || true)"
      if [[ -z "$pid" ]]; then
        # The launcher may run the binary from a per-round copy outside
        # app_dir; fall back to the executable identity plus descriptor.
        pid="$(cjgui_descriptor_owner_pid "$descriptor" "$exec_name" || true)"
      fi
      if [[ -n "$pid" ]]; then
        CJGUI_APP_PID="$pid"
        CJGUI_DESCRIPTOR="$descriptor"
        print -r -- "$pid $descriptor"
        return 0
      fi
    fi
    sleep 1
    waited=$(( waited + 1 ))
  done
  return 1
}

# cjgui_unique_round_pid <round-unique-exec-name> <dir-hint>
# For a window application with no connection descriptor (UI-only consumers),
# identity is the round-unique bundle/executable name plus the per-round
# directory. Prints the single matching PID and fails on zero or ambiguous
# matches, so a shared name can never select someone else's process.
cjgui_unique_round_pid() {
  local exec_name="$1" dir_hint="$2" pid command_line count=0 found=""
  for pid in $(pgrep -f "$exec_name" 2>/dev/null || true); do
    kill -0 "$pid" 2>/dev/null || continue
    command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    [[ "$command_line" == *"$exec_name"* ]] || continue
    [[ "$command_line" == *"$dir_hint"* ]] || continue
    count=$(( count + 1 ))
    found="$pid"
  done
  (( count == 1 )) || return 1
  print -r -- "$found"
}

# cjgui_unique_round_owns <pid> <round-unique-exec-name> <dir-hint>
cjgui_unique_round_owns() {
  local pid="$1" exec_name="$2" dir_hint="$3" owner command_line
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
  [[ "$command_line" == *"$exec_name"* ]] || return 1
  [[ "$command_line" == *"$dir_hint"* ]] || return 1
  owner="$(cjgui_unique_round_pid "$exec_name" "$dir_hint" || true)"
  [[ "$owner" == "$pid" ]]
}

# cjgui_prepare_app_copy <template-dir> <dest-dir> <runtime-dir> <name-token> <suffix> <bundle-id-token>
# Makes a per-round copy of a window application so this round never shares a
# bundle identifier, executable name, directory or descriptor with a user
# instance. Dependency paths in cjpm.toml are rewritten relative to the copy
# (and only those): the per-application native cache under `./.cjgui/native/lib`
# stays app-local, so the copy builds from its own sources instead of reading
# the author tree's build cache.
cjgui_prepare_app_copy() {
  local template="$1" dest="$2" runtime="$3" name_token="$4" suffix="$5" bundle_token="$6"
  mkdir -p "$dest"
  cp -R "$template/src" "$dest/src"
  cp "$template/cjpm.toml" "$dest/cjpm.toml"
  cp "$template/cjgui_macos_app.sh" "$dest/cjgui_macos_app.sh"
  python3 - "$dest" "$template" "$name_token" "$suffix" "$bundle_token" <<'PYID' || return 1
import os
import re
import sys

dest, template, name_token, suffix, bundle_token = sys.argv[1:6]
toml = open(f"{template}/cjpm.toml").read()


def rewrite_path(match):
    real = os.path.normpath(os.path.join(template, match.group(1)))
    return 'path = "%s"' % os.path.relpath(real, dest)


# Rewrite dependency package paths only. The [ffi.c] section names the
# application-local native cache (./.cjgui/native/lib), which the launcher
# populates inside this copy; rewriting it would make the copy read the
# author's build cache instead.
lines = toml.splitlines(keepends=True)
section = ""
rewritten = []
for line in lines:
    stripped = line.strip()
    if stripped.startswith("["):
        section = stripped
    if section == "[dependencies]":
        line = re.sub(r'path = "([^"]+)"', rewrite_path, line)
    rewritten.append(line)
toml = "".join(rewritten)
open(f"{dest}/cjpm.toml", "w").write(toml)

launcher = open(f"{template}/cjgui_macos_app.sh").read()
launcher = launcher.replace(name_token, f"{name_token}{suffix}")
launcher = launcher.replace(bundle_token, f"{bundle_token}.{suffix}")
open(f"{dest}/cjgui_macos_app.sh", "w").write(launcher)
PYID
  cat > "$dest/run.sh" <<RUNSH
#!/usr/bin/env zsh
exec zsh "$runtime/scripts/run_macos_application.sh" "$dest/cjgui_macos_app.sh" "\$@"
RUNSH
  chmod +x "$dest/run.sh"
  return 0
}

# cjgui_wait_descriptor <stdout-log> <ready-pattern> <timeout-seconds>
# Prints the descriptor path once the instance has published it.
cjgui_wait_descriptor() {
  local stdout_log="$1" ready_pattern="$2" limit="$3" waited=0 descriptor=""
  while (( waited < limit )); do
    descriptor="$(grep "$ready_pattern" "$stdout_log" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
    if [[ -n "$descriptor" && -f "$descriptor" ]]; then
      print -r -- "$descriptor"
      return 0
    fi
    sleep 1
    waited=$(( waited + 1 ))
  done
  return 1
}
