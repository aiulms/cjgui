#!/usr/bin/env zsh
# Shared real-desktop-input helpers for CJGUI verification scripts.
#
# Extracted verbatim from verify_framework_preview_consumer_chains.sh, where the
# driver, the AX frame walk and the bounded type/readback loop were first
# measured. A caller must define before sourcing:
#   RUNTIME_DIR  repository runtime/cjgui root (driver source path)
#   WORK         per-round work directory (driver binary + logs)
#   CLIENT       public operation client (python)
#   log / fail   logging helpers
# and set AX_PID to the round process before an edit. The exported/author
# distinction is entirely in those variables: no author-runtime seam is added.
#
# Requires cjgui_ax from lib_cjgui_instance.sh. The caller keeps its own shell
# options: this file does not change `set -u`/`set -e`.
DRIVER_SOURCE="$RUNTIME_DIR/native/tests/desktop_input_driver.swift"
DRIVER=""
APP_ACTIVATOR=""
INPUT_BLOCKED=""
REAL_EDIT_MODE=""
REAL_EDIT_BEFORE=""
REAL_EDIT_AFTER=""
REAL_EDIT_FRAME=""
REAL_EDIT_INSTANCE=""
RE_DESCRIPTOR=""
RE_FIELD_ID=""
RE_TARGET=""

session_locked() {
  local state
  state="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 \
    | awk -F= '{print $2}' | tr -d '[:space:]' || true)"
  [[ "$state" == "Yes" ]]
}
prepare_desktop_driver() {
  if session_locked; then
    INPUT_BLOCKED="session_locked (CGSSessionScreenIsLocked=Yes)"
    log "BLOCKED desktop_input reason=session_locked"
    return 1
  fi
  if ! command -v swiftc >/dev/null 2>&1; then
    INPUT_BLOCKED="swiftc_unavailable"
    log "BLOCKED desktop_input reason=swiftc_unavailable"
    return 1
  fi
  DRIVER="$WORK/cjgui_desktop_input_driver"
  if ! swiftc -O "$DRIVER_SOURCE" -o "$DRIVER" > "$WORK/driver-build.log" 2>&1; then
    INPUT_BLOCKED="driver_build_failed"
    log "BLOCKED desktop_input reason=driver_build_failed log=$WORK/driver-build.log"
    return 1
  fi
  log "step0 desktop_input_driver=built tool=$DRIVER source=$DRIVER_SOURCE role=verification_tool"
  # Record the measured post-event permission with the build: a later segment
  # that loses input can then be attributed to delivery vs. product behavior.
  log "step0b real_input_preflight $(real_input_preflight 2>/dev/null || print post_event_access=refused)"
  return 0
}

AX_PID=""
drive() { "$DRIVER" "$@" >> "$WORK/driver.log" 2>&1; }

# prepare_app_activator: build the pid-addressed activation tool into WORK
# (source native/tests/app_activate.swift). Non-fatal on failure: activate_app
# then keeps its guarded AppleScript fallback, which refuses to act when the
# process it resolved is not the requested pid.
prepare_app_activator() {
  APP_ACTIVATOR=""
  local source="$RUNTIME_DIR/native/tests/app_activate.swift"
  if [[ ! -f "$source" ]]; then
    log "BLOCKED app_activator reason=source_missing path=$source"
    return 1
  fi
  if ! command -v swiftc >/dev/null 2>&1; then
    log "BLOCKED app_activator reason=swiftc_unavailable"
    return 1
  fi
  APP_ACTIVATOR="$WORK/cjgui_app_activate"
  if ! swiftc -O "$source" -o "$APP_ACTIVATOR" > "$WORK/app-activator-build.log" 2>&1; then
    APP_ACTIVATOR=""
    log "BLOCKED app_activator reason=build_failed log=$WORK/app-activator-build.log"
    return 1
  fi
  log "step0 app_activator=built tool=$APP_ACTIVATOR source=$source role=verification_tool"
  return 0
}

# real_input_preflight
# Prints "post_event_access=granted|refused" (the driver's own measurement of
# the synthetic-event post permission) and returns 0 only when posting is
# permitted. Callers record this so a segment that loses input can be told
# apart from a product failure.
real_input_preflight() {
  local out
  out="$("$DRIVER" preflight 2>/dev/null)"
  print -r -- "$out"
  [[ "$out" == "post_event_access=granted" ]]
}
hex_to_text() {
  python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'
}
activate_app() {
  # Frontmost (per process) is not the same as the KEY window. On this host an
  # Accessibility size change leaves the window visible but not key, and posting
  # keys then reaches nothing. LaunchServices activation of the application's own
  # bundle is the canonical way to make it frontmost AND key; the AX attributes
  # are requested as well. AX_APP_PATH is optional and only ever points at the
  # caller's OWN round bundle.
  #
  # The activation itself is pid-addressed (app_activate: NSRunningApplication
  # + AX raise of that pid's window 1). Measured 2026-09-27: the System Events
  # form `first process whose unix id is N` can resolve to a DIFFERENT running
  # process with the same application name -- a query made with our round's pid
  # answered the other instance -- so `set frontmost of p to true` raised the
  # OTHER app's window above ours and every posted click landed there, while
  # `frontmost of p` still answered true. The AppleScript form survives only as
  # a fallback and now refuses to act whenever the pid it resolved is not the
  # requested one.
  if [[ -n "${AX_APP_PATH:-}" && -d "$AX_APP_PATH" ]]; then
    open "$AX_APP_PATH" >/dev/null 2>&1 || true
    sleep 0.4
  fi
  if [[ -n "${APP_ACTIVATOR:-}" && -x "${APP_ACTIVATOR:-}" ]]; then
    "$APP_ACTIVATOR" "$AX_PID" >/dev/null 2>&1 || true
    return 0
  fi
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    if (unix id of p) is not $AX_PID then return
    set frontmost of p to true
    try
      perform action \"AXRaise\" of window 1 of p
    end try
    try
      set value of attribute \"AXMain\" of window 1 of p to true
    end try
    try
      set value of attribute \"AXFocused\" of window 1 of p to true
    end try
  end tell" >/dev/null 2>&1 || true
}
app_frontmost() {
  # NSWorkspace answers "which application is frontmost" authoritatively; the
  # System Events read is kept as a guarded fallback: it refuses to answer when
  # the process it resolved is not the requested pid (the 2026-09-27 name
  # collision answered `true` for our pid while another same-named instance was
  # the frontmost application).
  if [[ -n "${APP_ACTIVATOR:-}" && -x "${APP_ACTIVATOR:-}" ]]; then
    "$APP_ACTIVATOR" "$AX_PID" --frontmost 2>/dev/null || true
    return 0
  fi
  cjgui_ax 10 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    if (unix id of p) is not $AX_PID then return \"pid_mismatch\"
    return frontmost of p
  end tell" 2>/dev/null | tail -1 || true
}
ax_focused_description() {
  cjgui_ax 10 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    try
      set e to value of attribute \"AXFocusedUIElement\" of p
      return (description of e)
    on error
      return \"missing\"
    end try
  end tell" 2>/dev/null | tail -1 || true
}
ax_window_frame() {
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set pp to position of window 1 of p
    set ss to size of window 1 of p
    return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
  end tell" 2>/dev/null | tail -1 || true
}

# real_resize_window <delta-w> <delta-h>
# Drags the window's own bottom-right corner through the real pointer path, so
# the window stays key and the application receives an ordinary resize.
real_resize_window() {
  local dw="$1" dh="$2" frame x y w h
  frame="$(ax_window_frame)"
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  h="$(print -r -- "$frame" | awk '{print $4}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> && "$h" == <-> ]] || return 1
  drive drag $(( x + w - 4 )) $(( y + h - 4 )) $(( x + w + dw )) $(( y + h + dh ))
  sleep 1.0
  return 0
}
# The window must be key before posted input is routed into it; the point sits
# in the title band so becoming key cannot press a self-drawn control.
make_window_key() {
  local frame x y w
  frame="$(ax_window_frame)"
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> ]] || return 1
  # A point in the title band's right side: it keys the window without landing on
  # a self-drawn control in the content.
  drive click $(( x + w - 20 )) $(( y + 40 ))
  sleep 0.6
  return 0
}
# Bounded AX read of one element frame by collection kind and description.
# The typed collection (`text field`, `checkbox`) is used instead of
# `entire contents`: on this host an exported cjgui window does not expose its
# descendants through `entire contents`, while `every text field of window 1`
# lists the generated editors together with their accessibility descriptions
# (measured for the exported rule consumer: "规则名称编辑" / "启用状态编辑").
# The expected AX role for a typed collection kind, so a control that shares its
# description with an enclosing/derived element is not confused with it.
ax_role_for_kind() { # ax_role_for_kind <collection-kind>
  case "$1" in
    "text field") print -r -- "AXTextField" ;;
    checkbox) print -r -- "AXCheckBox" ;;
    *) print -r -- "" ;;
  esac
}

ax_kind_frame() { # ax_kind_frame <collection-kind> <description> [role] -> "x y w h" | missing
  # Positions are read ONE ELEMENT AT A TIME. On this host the bulk form
  # (`position of every text field`) reports CONTENT-relative coordinates while
  # the per-element form reports SCREEN coordinates; pressing the bulk form's
  # point lands 336/147 points away from the control it names (measured on the
  # second consumer: bulk 44,430 vs screen 380,577). The SMALLEST match wins so a
  # container that shares the description is never pressed instead of the control.
  local kind="$1" wanted="$2" role="${3:-}"
  [[ -n "$role" ]] || role="$(ax_role_for_kind "$kind")"
  cjgui_ax 25 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set wantedRole to \"$role\"
    set bestFrame to \"missing\"
    set bestArea to -1
    try
      repeat with e in (every $kind of window 1 of p)
        try
          if (description of e) is \"$wanted\" and (wantedRole is \"\" or (role of e) is wantedRole) then
            set pp to position of e
            set ss to size of e
            set area to ((item 1 of ss) as integer) * ((item 2 of ss) as integer)
            -- Prefer a POSITIVE extent: a zero-size projection shares the caption
            -- but is not the control.
            if (area > 0 and (bestArea <= 0 or area < bestArea)) or (bestArea < 0) then
              set bestArea to area
              set bestFrame to ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
            end if
          end if
        end try
      end repeat
    end try
    return bestFrame
  end tell" 2>/dev/null | tail -1 || true
}
# The recursive walk returns SCREEN positions; on this host the typed collection
# can return CONTENT-relative ones for the same control. Both are read and the
# frame that lands inside the window's own screen rectangle is used.
ax_screen_frame() { # ax_screen_frame <description> -> "x y w h" | missing
  local wanted="$1"
  cjgui_ax 25 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    repeat with w in windows of p
      try
        repeat with e in (every UI element of w)
          try
            if (description of e) is \"$wanted\" then
              set pp to position of e
              set ss to size of e
              return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
            end if
          end try
        end repeat
      end try
    end repeat
    return \"missing\"
  end tell" 2>/dev/null | tail -1 || true
}

# real_ax_windows_report <pid>
# One line per window: index, title, frame, focus and enumerated child count.
# Evidence for which window actually owns the composable scene; a driver that
# only ever looks at window 1 can silently miss it.
real_ax_windows_report() {
  local pid="$1"
  cjgui_ax 25 -e "tell application \"System Events\"
    set out to \"\"
    try
      set p to first process whose unix id is $pid
      set windowIndex to 0
      repeat with w in windows of p
        set windowIndex to windowIndex + 1
        set lineText to \"window=\" & windowIndex
        try
          set lineText to lineText & \" title=\" & (name of w as string)
        end try
        try
          set pp to position of w
          set ss to size of w
          set lineText to lineText & \" frame=\" & (item 1 of pp) & \",\" & (item 2 of pp) & \",\" & (item 1 of ss) & \",\" & (item 2 of ss)
        end try
        try
          set lineText to lineText & \" focused=\" & (value of attribute \"AXFocused\" of w)
        end try
        try
          set lineText to lineText & \" elements=\" & (count of (every UI element of w))
        end try
        set out to out & lineText & linefeed
      end repeat
    end try
    return out
  end tell" 2>/dev/null || true
}

# ax_identifier_frame <semanticId> [kind] -> "x y w h" | missing
# Screen frame of the element whose AXIdentifier is EXACTLY the accepted
# semanticId. `kind` is the System Events role collection ("text field",
# "button", ...; default every UI element), so PID + window + role + the full
# identifier are all part of the match. The caption is only a projection and
# several editors can share one. A positive extent wins; a zero-size projection
# of the same node is kept only as a last resort.
ax_identifier_frame() { # ax_identifier_frame <semanticId> [kind] -> "x y w h" | missing
  local wanted="$1" kind="${2:-UI element}"
  cjgui_ax 25 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set fallbackFrame to \"missing\"
    repeat with w in windows of p
      try
        repeat with e in (every $kind of w)
          try
            if (value of attribute \"AXIdentifier\" of e) is \"$wanted\" then
              set pp to position of e
              set ss to size of e
              set frameText to ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
              if (((item 1 of ss) as integer) > 0) and (((item 2 of ss) as integer) > 0) then return frameText
              if fallbackFrame is \"missing\" then set fallbackFrame to frameText
            end if
          end try
        end repeat
      end try
    end repeat
    return fallbackFrame
  end tell" 2>/dev/null | tail -1 || true
}

# real_ax_wait_ready <pid> [attempts]
# Bounded wait until the application's window publishes an enumerable
# accessibility tree. Publishing the tree is asynchronous, and a query that runs
# before it is ready returns nothing at all, which must not be read as "the
# control is missing".
real_ax_wait_ready() {
  local pid="$1" attempts="${2:-24}" i=0 report=""
  while (( i < attempts )); do
    report="$(real_ax_windows_report "$pid")"
    if print -r -- "$report" | grep -q 'elements=[1-9]'; then
      print -r -- "$report"
      return 0
    fi
    i=$(( i + 1 ))
    sleep 0.5
  done
  print -r -- "${report:-ready_timeout}"
  return 1
}

# frame_is_positive <"x y w h">
# True when a frame is pressable. A laid-out-but-clipped element publishes a zero
# extent, and pressing it would be a coordinate guess.
frame_is_positive() {
  local frame="$1" w h
  w="$(print -r -- "$frame" | awk '{print $3}')"
  h="$(print -r -- "$frame" | awk '{print $4}')"
  [[ "$w" == <-> && "$h" == <-> ]] || return 1
  (( w > 0 && h > 0 ))
}

# region_pixel_hex <x> <y> [size]
# The real composited pixel at one screen point, read from a bounded region
# screenshot. It is a verification observation of the platform's output, never a
# value the application reported about itself.
region_pixel_hex() {
  local x="$1" y="$2" size="${3:-2}" shot="$WORK/pixel-region.png"
  local script_dir="${SCRIPT_DIR:-}"
  [[ -n "$script_dir" ]] || return 1
  mkdir -p "$WORK"
  screencapture -x -R "${x},${y},${size},${size}" -t png "$shot" >/dev/null 2>&1 || return 1
  [[ -s "$shot" ]] || return 1
  python3 "$script_dir/region_pixel.py" "$shot" 0 0 2>/dev/null || return 1
}

# viewport_offset_for <semanticId>
# The offset the application itself publishes for that viewport, or empty when it
# is not published. The driver never invents viewport state.
viewport_offset_for() {
  local wanted="$1" descriptor="${RE_DESCRIPTOR:-}"
  [[ -n "$descriptor" && -n "$wanted" ]] || return 1
  python3 "$CLIENT" "$descriptor" window-interaction 2>/dev/null |
    awk -v id="$wanted" '$1 == "WINDOW_VIEWPORT" && $2 == id {
      for (i = 3; i <= NF; i++) if ($i ~ /^offset=/) { sub(/^offset=/, "", $i); print $i }
    }'
}

# real_ax_scroll_reveal <semanticId> [kind] [attempts]
# Performs REAL wheel gestures inside the application's own published scroll
# viewports until the exact identifier's element has a pressable frame, then
# prints that frame. The container is addressed by the semantic id the
# application publishes (not by a guessed coordinate), the direction is
# corrected from the published offset when a step does not move, and a stop with
# no viewport movement ends the loop instead of hammering the desktop.
real_ax_scroll_reveal() {
  local wanted="$1" kind="${2:-UI element}" attempts="${3:-6}" frame="" viewport=""
  local direction=-4 i=0 vframe="" vx="" vy="" vw="" vh="" before="" after=""
  local probe_x="" probe_y="" moved=0 scrolled=0
  frame="$(ax_identifier_frame "$wanted" "$kind")"
  if frame_is_positive "$frame"; then
    print -r -- "$frame"
    return 0
  fi
  local descriptor="${RE_DESCRIPTOR:-}" viewports=""
  if [[ -n "$descriptor" ]]; then
    viewports="$(python3 "$CLIENT" "$descriptor" window-interaction 2>/dev/null |
      awk '$1 == "WINDOW_VIEWPORT" {print $2}')"
  fi
  # A target can be above the current offset as well as below it, and a nested
  # scroll area can swallow the gesture, so both directions are tried AND several
  # points inside the SAME published viewport are probed. The offset the
  # application publishes decides which point really belongs to this viewport;
  # nothing is assumed about the platform's wheel convention.
  local pass=1
  while (( pass <= 2 )); do
    i=0
    while (( i < attempts )); do
      moved=0
      for viewport in ${(z)viewports}; do
        vframe="$(ax_identifier_frame "$viewport" "group")"
        frame_is_positive "$vframe" || continue
        vx="$(print -r -- "$vframe" | awk '{print $1}')"
        vy="$(print -r -- "$vframe" | awk '{print $2}')"
        vw="$(print -r -- "$vframe" | awk '{print $3}')"
        vh="$(print -r -- "$vframe" | awk '{print $4}')"
        if [[ "$(app_frontmost)" != "true" ]]; then
          # A real wheel is only routed into the frontmost window.
          activate_app
          sleep 0.3
        fi
        for probe in "center" "left" "top" "bottom" "right"; do
          case "$probe" in
            center) probe_x=$(( vx + vw / 2 )); probe_y=$(( vy + vh / 2 )) ;;
            left) probe_x=$(( vx + 6 )); probe_y=$(( vy + vh / 2 )) ;;
            top) probe_x=$(( vx + vw / 2 )); probe_y=$(( vy + 6 )) ;;
            bottom) probe_x=$(( vx + vw / 2 )); probe_y=$(( vy + vh - 6 )) ;;
            right) probe_x=$(( vx + vw - 6 )); probe_y=$(( vy + vh / 2 )) ;;
          esac
          before="$(viewport_offset_for "$viewport")"
          drive scroll "$probe_x" "$probe_y" "$direction"
          sleep 0.5
          after="$(viewport_offset_for "$viewport")"
          if [[ -n "$before" && "$before" == "$after" ]]; then
            # This gesture did not move the intended viewport (a nested scroll
            # area may own the point, or the direction is opposite): try the
            # other direction once at the same point.
            direction=$(( 0 - direction ))
            drive scroll "$probe_x" "$probe_y" "$direction"
            sleep 0.5
            after="$(viewport_offset_for "$viewport")"
          fi
          if [[ -n "$before" && -n "$after" && "$before" != "$after" ]]; then
            moved=1
          fi
          frame="$(ax_identifier_frame "$wanted" "$kind")"
          if frame_is_positive "$frame"; then
            print -r -- "$frame"
            return 0
          fi
          if (( moved == 1 )); then
            scrolled=1
            break
          fi
        done
      done
      if (( moved == 0 )); then
        break
      fi
      i=$(( i + 1 ))
    done
    direction=$(( 0 - direction ))
    pass=$(( pass + 1 ))
  done
  if (( scrolled == 0 )); then
    print -r -- "missing"
    return 1
  fi
  print -r -- "missing"
  return 1
}

# real_ax_press_identifier <pid> <semanticId>
# Real press on the element whose AXIdentifier is exactly the accepted semantic
# identity. Prints "identifier_press_sent", or "press_missing <diagnostic>".
real_ax_press_identifier() {
  local pid="$1" wanted="$2"
  cjgui_ax 30 -e "tell application \"System Events\"
    try
      set p to first process whose unix id is $pid
      set frontmost of p to true
      try
        perform action \"AXRaise\" of window 1 of p
      end try
      repeat with w in windows of p
        try
          repeat with e in (every UI element of w)
            try
              if (value of attribute \"AXIdentifier\" of e) is \"$wanted\" then
                perform action \"AXPress\" of e
                return \"identifier_press_sent\"
              end if
            end try
          end repeat
        end try
      end repeat
      return \"press_missing identifier_not_found\"
    on error errMsg
      return \"press_missing identifier_error=\" & errMsg
    end try
  end tell" 2>/dev/null | tail -1 || true
}

# real_ax_dump_identifiers <pid> [limit]
# Prints "identifier@" lines for window elements that publish an AXIdentifier.
# Evidence only: it never presses anything and never writes product state.
real_ax_dump_identifiers() {
  local pid="$1" limit="${2:-40}"
  cjgui_ax 30 -e "tell application \"System Events\"
    set out to \"\"
    set seen to 0
    try
      set p to first process whose unix id is $pid
      repeat with w in windows of p
        try
          repeat with e in (every UI element of w)
            if seen = $limit then exit repeat
            try
              set ident to value of attribute \"AXIdentifier\" of e
              if ident is not missing value and ident is not \"\" then
                set seen to seen + 1
                set out to out & \"identifier=\" & ident & \" role=\" & (role description of e as string) & linefeed
              end if
            end try
          end repeat
        end try
      end repeat
    end try
    return out
  end tell" 2>/dev/null || true
}

# real_ax_dump_captions <pid> [limit]
# Prints "element=N role=... desc=... title=... ident=..." for window elements.
# Evidence only: it explains why a caption-based lookup missed and never presses
# or writes anything.
real_ax_dump_captions() {
  local pid="$1" limit="${2:-60}"
  cjgui_ax 30 -e "tell application \"System Events\"
    set out to \"\"
    set seen to 0
    try
      set p to first process whose unix id is $pid
      repeat with w in windows of p
        try
          repeat with e in (every UI element of w)
            if seen = $limit then exit repeat
            set seen to seen + 1
            set lineText to \"element=\" & seen & \" role=\" & (role description of e as string)
            try
              set lineText to lineText & \" desc=\" & (description of e as string)
            end try
            try
              set lineText to lineText & \" title=\" & (title of e as string)
            end try
            try
              set ident to value of attribute \"AXIdentifier\" of e
              if ident is not missing value then set lineText to lineText & \" ident=\" & (ident as string)
            end try
            set out to out & lineText & linefeed
          end repeat
        end try
      end repeat
    end try
    return out
  end tell" 2>/dev/null || true
}

# The REAL focus projection: the matched element's own AXFocused attribute and
# the window's AXFocused. The application's `generated-fields FOCUS` column is a
# hard-coded editor-kind projection, so it must never be used to conclude that
# keyboard input did or did not arrive.
ax_element_focus() { # ax_element_focus <collection-kind> <description> [role] -> true|false|missing
  local kind="$1" wanted="$2" role="${3:-}"
  [[ -n "$role" ]] || role="$(ax_role_for_kind "$kind")"
  cjgui_ax 20 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set wantedRole to \"$role\"
    try
      repeat with e in (every $kind of window 1 of p)
        try
          if (description of e) is \"$wanted\" and (wantedRole is \"\" or (role of e) is wantedRole) then
            if (value of attribute \"AXFocused\" of e) is true then return \"true\"
          end if
        end try
      end repeat
    end try
    return \"false\"
  end tell" 2>/dev/null | tail -1 || true
}

ax_window_focus() { # ax_window_focus -> true|false|missing
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    try
      if (value of attribute \"AXFocused\" of window 1 of p) is true then return \"true\"
    end try
    return \"false\"
  end tell" 2>/dev/null | tail -1 || true
}

# Which window of the process holds AXFocused, and how many exist. A process can
# own an invisible/overlay window; reading only `window 1` would then report "not
# key" even while the visible window is key.
ax_window_focus_report() {
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set report to \"windows=\" & (count of windows of p) & \" \"
    set index to 0
    repeat with w in windows of p
      set index to index + 1
      try
        set report to report & index & \":\" & (value of attribute \"AXFocused\" of w) & \",\"
      end try
    end repeat
    return report
  end tell" 2>/dev/null | tail -1 || true
}

# ensure_window_key: try the bounded activation variants and report the first one
# that really makes the window the focused (key) window. Only driver-side methods
# are used; the product is not modified to satisfy the driver.
ensure_window_key() { # -> prints the working variant, or returns 1
  local frame x y w h
  frame="$(ax_window_frame)"
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  h="$(print -r -- "$frame" | awk '{print $4}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> && "$h" == <-> ]] || return 1
  activate_app
  [[ "$(ax_window_focus)" == "true" ]] && { print -r -- "activate"; return 0; }
  drive click $(( x + 40 )) $(( y + 10 )); sleep 0.5
  [[ "$(ax_window_focus)" == "true" ]] && { print -r -- "title_bar"; return 0; }
  drive click $(( x + 30 )) $(( y + h - 30 )); sleep 0.5
  [[ "$(ax_window_focus)" == "true" ]] && { print -r -- "content_corner"; return 0; }
  activate_app; sleep 0.4
  [[ "$(ax_window_focus)" == "true" ]] && { print -r -- "re_activate"; return 0; }
  return 1
}

# frame_inside_window <"x y w h"> <"wx wy ww wh">: is the frame inside the window
# rectangle (screen coordinates)?
frame_inside_window() {
  print -r -- "$1 $2" | awk '{
    if (NF != 8) { exit 1 }
    x = $1; y = $2; w = $3; h = $4; wx = $5; wy = $6; ww = $7; wh = $8
    # A zero-size accessibility element sits at the window origin and is not a
    # pressable control: the composite elements project one. Requiring a positive
    # extent keeps the chooser from pressing the window corner.
    if (w <= 0 || h <= 0) { exit 1 }
    if (x < wx - 2 || y < wy - 2) { exit 1 }
    if (x + w > wx + ww + 2 || y + h > wy + wh + 2) { exit 1 }
    exit 0
  }'
}

# The frame this driver will actually press. An optional REAL_EDIT_CLICK_FRAME
# (screen coordinates) wins; otherwise the two AX collections are tried and the
# one inside the window rectangle is chosen. The control's identity is still
# verified afterwards through the window's focus projection or the owner read.
ax_target_frame() { # ax_target_frame <collection-kind> <description> [role] -> "x y w h" | missing
  local kind="$1" wanted="$2" role="${3:-}" window_rect candidate screen_frame
  window_rect="$(cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set pp to position of window 1 of p
    set ss to size of window 1 of p
    return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
  end tell" 2>/dev/null | tail -1 || true)"
  for candidate in "${REAL_EDIT_CLICK_FRAME:-}" "$(ax_kind_frame "$kind" "$wanted" "$role")" "$(ax_screen_frame "$wanted")"; do
    [[ -n "$candidate" && "$candidate" != "missing" ]] || continue
    if [[ -n "$window_rect" ]] && frame_inside_window "$candidate" "$window_rect"; then
      print -r -- "$candidate"
      return 0
    fi
  done
  screen_frame="$(ax_screen_frame "$wanted")"
  if [[ -n "$screen_frame" && "$screen_frame" != "missing" ]]; then
    print -r -- "$screen_frame"
    return 0
  fi
  ax_kind_frame "$kind" "$wanted" "$role"
}

click_frame_center() { # click_frame_center "x y w h"
  local frame="$1" x y w h
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  h="$(print -r -- "$frame" | awk '{print $4}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> && "$h" == <-> ]] || return 1
  (( w > 0 && h > 0 )) || return 1
  drive click $(( x + w / 2 )) $(( y + h / 2 ))
  return 0
}
click_ax_element() { # click_ax_element <collection-kind> <description> -> prints "x y w h"
  local kind="$1" description="$2" frame
  frame="$(ax_kind_frame "$kind" "$description")"
  [[ "$frame" != "missing" && -n "$frame" ]] || return 1
  click_frame_center "$frame" || return 1
  sleep 0.8
  print -r -- "$frame"
  return 0
}
# Real modifier press + letter with that flag + release: the chord the tree
# keyboard verifier uses for Command-A, so NSTextView's own select-all runs and
# a following typed string replaces the field content instead of appending.
chord_select_all() {
  drive key-down 55
  drive shortcut command 0
  drive key-up 55
  sleep 0.4
}
# The focus fact a window reports. When the caller names the window it drives
# (RE_WINDOW_TARGET), the TARGET-qualified read is used: a whole-window read could
# otherwise confirm a different window of the same process, which is exactly the
# "verified the wrong control" failure this driver must not produce.
window_focus_for() {
  local descriptor="$1" target="${RE_WINDOW_TARGET:-}"
  if [[ -n "$target" ]]; then
    python3 "$CLIENT" "$descriptor" window-interaction "$target" 2>/dev/null |
      awk '/^WINDOW_FOCUS /{print $2}'
  else
    python3 "$CLIENT" "$descriptor" window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}'
  fi
}
field_hex_value() { # field_hex_value <descriptor> <fieldId> <token>
  python3 "$CLIENT" "$1" generated-fields 2>/dev/null | awk -v id="$2" -v tag="$3" '
    $1 == "FIELD" && $2 == id { for (i = 1; i <= NF; i++) if ($i == tag) { print $(i + 1); exit } }'
}
field_text_value() { field_hex_value "$1" "$2" DRAFT_HEX | hex_to_text; }
# A read issued while the exported window commits a refresh can come back empty
# even though the owner value is set; the exact-value check below retries within
# a fixed bound instead of treating an empty read as a delivered edit.
field_text_value_retry() { # field_text_value_retry <descriptor> <fieldId> [tries]
  local descriptor="$1" fieldId="$2" tries="${3:-8}" attempt=0 value=""
  while (( attempt < tries )); do
    value="$(field_text_value "$descriptor" "$fieldId")"
    if [[ -n "$value" ]]; then
      print -r -- "$value"
      return 0
    fi
    sleep 0.3
    attempt=$(( attempt + 1 ))
  done
  print -r -- ""
  return 0
}

# ---------------------------------------------------------------------------
# Exact accepted identity and field-state isolation for real desktop edits.
#
# The driver used to type into whatever component the window reported as focused
# (a `component-` PREFIX match) and to decide success only from the target field's
# read-back. That wrote the target text into OTHER generated editors before the
# walk reached the intended one. Identity is now resolved from the CURRENT
# accepted instances: the caller's declared key (or the unique field binding),
# giving one exact semanticId. A prefix never authorizes input, and the public
# field snapshot is compared before and after every attempt so a non-target
# change fails immediately instead of being restored and hidden.
# ---------------------------------------------------------------------------

# accepted_field_instance_line <descriptor> <fieldId> [declaredKey]
# Prints the ONE accepted instance line bound to <fieldId>. Fails closed when the
# binding is absent or ambiguous (several controls bound to one field): the
# caller must name the key it actually selected.
accepted_field_instance_line() {
  local descriptor="$1" fieldId="$2" key="${3:--}"
  python3 "$CLIENT" "$descriptor" generated-instances 2>/dev/null | python3 -c '
import sys
field, key = sys.argv[1], sys.argv[2]
matches = []
for line in sys.stdin.read().split("\n"):
    if not line.startswith("INSTANCE "):
        continue
    tokens = {}
    for token in line.split(" ")[2:]:
        if "=" in token:
            name, value = token.split("=", 1)
            tokens[name] = value
    if tokens.get("field") != field:
        continue
    if key != "-" and line.split(" ")[1] != key:
        continue
    matches.append(line)
if len(matches) == 1:
    print(matches[0])
elif not matches:
    print("accepted_field_binding_missing", file=sys.stderr)
    sys.exit(2)
else:
    print("accepted_field_binding_ambiguous", file=sys.stderr)
    sys.exit(3)
' "$fieldId" "$key"
}

# instance_token <instance-line> <name> -> value or "-"
instance_token() {
  print -r -- "$1" | awk -v want="$2" '{
    for (i = 1; i <= NF; i++) {
      if (index($i, want "=") == 1) { print substr($i, length(want) + 2); exit }
    }
  }'
}

# instance_frame <instance-line> -> "x y w h" from the ACCEPTED bounds
instance_frame() {
  local bounds
  bounds="$(instance_token "$1" bounds)"
  [[ -n "$bounds" && "$bounds" != "-" ]] || return 1
  print -r -- "$bounds" | awk -F, 'NF == 4 { print $1, $2, $3, $4 }'
}

# fields_fingerprint <descriptor> -> canonical "id=drafthex;..." over ALL fields
fields_fingerprint() {
  python3 "$CLIENT" "$1" generated-fields 2>/dev/null | awk '
    $1 == "FIELD" {
      draft = "-"
      for (i = 1; i <= NF; i++) if ($i == "DRAFT_HEX") { draft = $(i + 1) }
      printf "%s=%s;", $2, draft
    }'
}

# fields_other_delta <before> <after> <targetFieldId> -> comma list of fields
# whose draft moved apart from the intended target.
fields_other_delta() {
  python3 - "$1" "$2" "$3" <<'PYDELTA'
import sys

def parse(raw):
    out = {}
    for part in raw.split(";"):
        if "=" in part:
            name, value = part.split("=", 1)
            out[name] = value
    return out

before, after, target = parse(sys.argv[1]), parse(sys.argv[2]), sys.argv[3]
changed = [name for name in set(before) | set(after)
           if name != target and before.get(name) != after.get(name)]
print(",".join(sorted(changed)))
PYDELTA
}

# real_edit_assert_isolated <label> <descriptor> <fieldId> <before> <active>
# Hard-fails when any field other than the target moved. It never restores the
# previous value: the raw before/after snapshots are kept in the message.
real_edit_assert_isolated() {
  local label="$1" descriptor="$2" fieldId="$3" before="$4" active="$5"
  local after delta
  after="$(fields_fingerprint "$descriptor")"
  delta="$(fields_other_delta "$before" "$after" "$fieldId")"
  [[ -z "$delta" ]] || fail "real_desktop_edit_side_effect label=$label target=$fieldId moved=$delta stage=$active before='$before' after='$after'"
}

# real_generated_text_edit <label> <descriptor> <fieldId> <description> <kind> <target>
# Focus path: a real press into the generated editor's own AX frame (which also
# makes the exported window key), then a Tab walk as the fallback. The edit is
# accepted only when the owner read-back equals the target exactly (replace) or
# the exact pre-edit value plus the target (append, caret at the end).
# Whether a consumer answers the public window-focus query. The rule consumer
# exposes it (component-* focus scopes); the second consumer does not authorize
# it, so its focus is judged by the owner read-back alone instead of by Tab
# traversal.
focus_query_supported() { # focus_query_supported <descriptor>
  local descriptor="$1" target="${RE_WINDOW_TARGET:-}"
  if [[ -n "$target" ]]; then
    python3 "$CLIENT" "$descriptor" window-interaction "$target" 2>/dev/null | grep -q '^WINDOW_FOCUS '
  else
    python3 "$CLIENT" "$descriptor" window-interaction 2>/dev/null | grep -q '^WINDOW_FOCUS '
  fi
}

# real_type_target: types RE_TARGET into the currently focused generated editor
# and accepts only an EXACT owner read-back equal to the target (replace). Uses
# REAL_EDIT_BEFORE / RE_* globals.
#
# The Command-A chord that clears the caret's field can miss if the editor is not
# yet first responder, which makes the typed text append instead of replace. That
# is retried (bounded) rather than accepted: every caller asserts the exact target
# value afterwards, so reporting `append` as a delivered edit only re-surfaced
# later as an unrelated read-back mismatch. A persistent append is reported as a
# delivery failure so the caller can record control input as blocked/fall back.
real_type_target() {
  local attempt=0
  while (( attempt < 3 )); do
    # Posted input follows the FRONTMOST application: if another process grabbed
    # focus between the press and the chord, the keystrokes would be delivered
    # there. The driver re-activates and records it, so the failure evidence says
    # which process actually received the input.
    local frontmost_before
    frontmost_before="$(app_frontmost)"
    [[ "$frontmost_before" == "true" ]] || activate_app || true
    chord_select_all
    drive type "$RE_TARGET"
    sleep 1.5
    log "diag real_type_target_delivery attempt=$attempt frontmost_before=$frontmost_before frontmost_after='$(app_frontmost)' target='$RE_TARGET'"
    REAL_EDIT_AFTER="$(field_text_value_retry "$RE_DESCRIPTOR" "$RE_FIELD_ID")"
    if [[ -z "$REAL_EDIT_AFTER" ]]; then
      log "diag real_type_target empty_read attempt=$attempt before='$REAL_EDIT_BEFORE' target='$RE_TARGET'"
      return 1
    fi
    if [[ "$REAL_EDIT_AFTER" == "$RE_TARGET" && "$REAL_EDIT_BEFORE" != "$RE_TARGET" ]]; then
      REAL_EDIT_MODE="replace"; return 0
    fi
    if [[ "$REAL_EDIT_AFTER" == "${REAL_EDIT_BEFORE}${RE_TARGET}" ]]; then
      # The select-all chord did not take: the text was appended. Retry the chord
      # and retype (a working chord replaces the accumulated text exactly); if it
      # keeps failing the mismatch branch below reports the real value.
      log "diag real_type_target append_retry attempt=$attempt after='$REAL_EDIT_AFTER' target='$RE_TARGET'"
      attempt=$(( attempt + 1 ))
      sleep 0.5
      continue
    fi
    log "diag real_type_target mismatch attempt=$attempt before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$RE_TARGET'"
    return 1
  done
  log "diag real_type_target append_only before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}' target='$RE_TARGET'"
  return 1
}

# real_ax_press_button <pid> <label>
# Real press on the button whose accessibility description/title/name is exactly
# `label`. The three attributes are tried in order because a self-drawn window may
# publish the caption through any of them; the caller decides whether a failure is
# a product failure or an environment limitation.
real_ax_press_button() {
  local pid="$1" label="$2" attribute
  for attribute in description title name; do
    if cjgui_ax 15 -e "tell application \"System Events\"
      set p to first process whose unix id is $pid
      set frontmost of p to true
      perform action \"AXRaise\" of window 1 of p
      set b to first button of window 1 of p whose $attribute is \"$label\"
      click b
      return \"ok\"
    end tell" >/dev/null 2>&1; then
      sleep 0.8
      return 0
    fi
  done
  return 1
}

# real_ax_press_application_command <pid> <menu-title> <window-description>
# Real press of the application's own command, with bounded attempts. The window
# is activated and raised before every attempt so a background window cannot make
# the control silently unreachable. The application menu command `menu-title` is
# tried first, then any window element whose accessibility description is exactly
# `window-description` (the self-drawn tree nests controls, so the whole window
# contents are walked). Prints "menu_press_sent" / "window_press_sent" on a sent
# press and "press_missing" otherwise; the caller classifies a bounded miss.
real_ax_press_application_command() {
  local pid="$1" title="$2" fallback="$3" attempt=0 result=""
  while (( attempt < 3 )); do
    result="$(cjgui_ax 30 -e "tell application \"System Events\"
      set diag to \"\"
      try
        set p to first process whose unix id is $pid
        set frontmost of p to true
        try
          perform action \"AXRaise\" of window 1 of p
        on error errMsg
          set diag to diag & \"raise_error=\" & errMsg & \";\"
        end try
        try
          repeat with bi in (menu bar items of menu bar 1 of p)
            try
              repeat with mi in (menu items of menu 1 of bi)
                try
                  if (name of mi) is \"$title\" then
                    perform action \"AXPress\" of mi
                    return \"menu_press_sent\"
                  end if
                end try
              end repeat
            end try
          end repeat
        on error errMsg
          set diag to diag & \"menu_error=\" & errMsg & \";\"
        end try
        try
          repeat with w in windows of p
            try
              repeat with e in (every UI element of w)
                try
                  if (description of e) is \"$fallback\" or (title of e) is \"$fallback\" or (name of e) is \"$fallback\" then
                    perform action \"AXPress\" of e
                    return \"window_press_sent\"
                  end if
                end try
              end repeat
            end try
          end repeat
          set diag to diag & \"window_scanned;\"
        on error errMsg
          set diag to diag & \"window_error=\" & errMsg & \";\"
        end try
      on error errMsg
        set diag to diag & \"process_error=\" & errMsg & \";\"
      end try
      return \"press_missing \" & diag
    end tell" 2>/dev/null || true)"
    if [[ "$result" == "menu_press_sent" || "$result" == "window_press_sent" ]]; then
      print -r -- "$result"
      return 0
    fi
    attempt=$(( attempt + 1 ))
    [[ -n "${AX_APP_PATH:-}" ]] && activate_app
    sleep 1.0
  done
  print -r -- "${result:-press_missing}"
  return 1
}

# real_ax_press_button_retry <pid> <label> [attempts]
# Bounded retry of real_ax_press_button, with the window reactivated between
# attempts. Returns 0 when a press was sent, 1 when every attempt missed.
real_ax_press_button_retry() {
  local pid="$1" label="$2" attempts="${3:-3}" attempt=0
  while (( attempt < attempts )); do
    if real_ax_press_button "$pid" "$label"; then
      return 0
    fi
    attempt=$(( attempt + 1 ))
    [[ -n "${AX_APP_PATH:-}" ]] && activate_app
    sleep 0.8
  done
  return 1
}

# real_focus_text_edit <label> <descriptor> <fieldId> <focusMatch> <target> [declaredKey]
# Real desktop input into the editor the window reports as focused. `focusMatch`
# is matched by EXACT EQUALITY only (never a prefix): `component-*` no longer
# authorizes typing into an arbitrary generated editor. When the reported focus is
# any other control the walk just presses Tab again. The public field snapshot is
# compared before and after, so a change to any other field fails immediately.
real_focus_text_edit() {
  local label="$1" descriptor="$2" fieldId="$3" focusMatch="$4" target="$5" declaredKey="${6:--}"
  REAL_EDIT_MODE=""; REAL_EDIT_FRAME=""
  RE_DESCRIPTOR="$descriptor"; RE_FIELD_ID="$fieldId"; RE_TARGET="$target"
  REAL_EDIT_BEFORE="$(field_text_value "$descriptor" "$fieldId")"
  local fieldsBefore
  fieldsBefore="$(fields_fingerprint "$descriptor")"
  local i=0 focus="" attempt=0 keyed=""
  while (( attempt < 3 )); do
    activate_app
    make_window_key || true
    keyed="$(app_frontmost)"
    log "diag real_text_edit_key label=$label attempt=$attempt frontmost=$keyed"
    [[ "$keyed" == "true" ]] && break
    sleep 0.8
    attempt=$(( attempt + 1 ))
  done
  while (( i < 160 )); do
    focus="$(window_focus_for "$descriptor")"
    if [[ "$focus" == "$focusMatch" ]]; then
      # The target field must not have been written while focus was being walked.
      real_edit_assert_isolated "$label" "$descriptor" "$fieldId" "$fieldsBefore" focus_walk
      if real_type_target; then
        REAL_EDIT_MODE="tab_${REAL_EDIT_MODE} focus=$focus"
        return 0
      fi
      return 1
    fi
    if [[ -n "$focus" && "$focus" != "none" ]]; then
      log "diag real_text_edit_skip_focus label=$label i=$i focus=$focus wanted='$focusMatch'"
    fi
    drive tab
    sleep 0.3
    if (( i % 20 == 19 )); then log "diag real_text_edit_tab label=$label i=$i focus=$focus"; fi
    i=$(( i + 1 ))
  done
  log "diag real_text_edit no_edit label=$label focus_match='$focusMatch' tabs=$i last_focus=$focus frontmost=$(app_frontmost)"
  return 1
}

# real_generated_text_edit <label> <descriptor> <fieldId> <description> <kind> <target> [declaredKey]
# Real desktop input into ONE generated editor, addressed by the currently
# ACCEPTED identity:
#   1. resolve the instance bound to <fieldId> (or to <declaredKey> when the
#      caller names the control it actually selected) and take its exact
#      semanticId + accepted bounds;
#   2. focus it either by an exact-equality focus walk or by a press inside its
#      accepted bounds - a `component-` prefix never authorizes typing;
#   3. type the target, require an EXACT owner read-back, and require every OTHER
#      field's draft to be byte-identical to the pre-attempt snapshot.
# A non-target change fails immediately and keeps the raw before/after evidence;
# it is never restored and then reported as a delivered edit.
real_generated_text_edit() {
  local label="$1" descriptor="$2" fieldId="$3" description="$4" kind="$5" target="$6" declaredKey="${7:--}"
  REAL_EDIT_MODE=""; REAL_EDIT_FRAME=""
  RE_DESCRIPTOR="$descriptor"; RE_FIELD_ID="$fieldId"; RE_TARGET="$target"
  # Consumed once: a caller may pass the exact screen frame it already located.
  local clickOverride="${REAL_EDIT_CLICK_FRAME:-}"
  REAL_EDIT_CLICK_FRAME=""
  REAL_EDIT_BEFORE="$(field_text_value "$descriptor" "$fieldId")"
  local fieldsBefore
  fieldsBefore="$(fields_fingerprint "$descriptor")"

  local instanceLine semantic targetFrame
  local lookup_error=""
  lookup_error="$(accepted_field_instance_line "$descriptor" "$fieldId" "$declaredKey" 2>&1 1>/dev/null)"
  instanceLine="$(accepted_field_instance_line "$descriptor" "$fieldId" "$declaredKey" 2>/dev/null)" || {
    log "diag real_text_edit no_instance label=$label field=$fieldId key=$declaredKey reason='$lookup_error'"
    log "diag real_text_edit instances='$(python3 "$CLIENT" "$descriptor" generated-instances 2>/dev/null | grep -c '^INSTANCE ') lines'"
    log "diag real_text_edit instance_fields='$(python3 "$CLIENT" "$descriptor" generated-instances 2>/dev/null | awk '/^INSTANCE /{for (i = 1; i <= NF; i++) if ($i ~ /^field=/) printf "%s %s;", $2, $i}')'"
    return 1
  }
  semantic="$(instance_token "$instanceLine" semantic)"
  targetFrame="$(instance_frame "$instanceLine" || true)"
  [[ -n "$semantic" && "$semantic" != "-" ]] || { log "diag real_text_edit no_semantic label=$label field=$fieldId"; return 1; }
  REAL_EDIT_INSTANCE="$instanceLine"
  log "diag real_text_edit_instance label=$label field=$fieldId semantic=$semantic frame='${targetFrame} bounds' key=$(print -r -- "$instanceLine" | awk '{print $2}')"

  if focus_query_supported "$descriptor"; then
    # Press INSIDE the accepted bounds of this exact instance and then require
    # the window's own focus projection to report that exact semanticId before
    # anything is typed. The old Tab walk is deliberately NOT used for generated
    # editors: on this host a Tab delivered while a self-drawn text editor owns
    # the focus is inserted into that editor's draft (measured: two Tabs landed in
    # an unrelated handwritten field), which is exactly the mis-write this driver
    # must not cause.
    local focusAttempt=0 focus=""
    while (( focusAttempt < 3 )); do
      # Posted pointer/key events are only routed into a FRONTMOST window. A
      # previous step (another consumer's window, a resize drag) can leave this
      # one behind, so the driver re-activates it before every press instead of
      # reading a routine activation gap as a product failure.
      if [[ "$(app_frontmost)" != "true" ]]; then
        activate_app
        sleep 0.3
      fi
      # The press uses the accessibility frame of the declared caption (screen
      # coordinates). It is only a pointer device: the window's own focus
      # projection must then report the EXACT accepted semanticId, so a click that
      # landed on a different control can never authorize typing.
      # EXACT instance address first: the accepted semanticId is published as
      # the element's AXIdentifier, so the press lands on THIS instance even when
      # several editors share a caption. The caption match stays only as a
      # logged fallback for a bundle that publishes no identifier.
      REAL_EDIT_CLICK_FRAME="$clickOverride"
      targetFrame="$(ax_identifier_frame "$semantic" "$kind")"
      REAL_EDIT_CLICK_FRAME=""
      if [[ -n "$targetFrame" && "$targetFrame" != "missing" ]] && ! frame_is_positive "$targetFrame"; then
        # The exact instance exists but is clipped out of its viewport. Reveal it
        # with a REAL wheel gesture and re-locate the SAME identifier: the caption
        # frame is never used to guess a press point for an unreachable node.
        local revealed
        # A bounded miss must reach the caller as a logged refusal, not as a
        # `set -e` abort that hides where the input stopped.
        revealed="$(real_ax_scroll_reveal "$semantic" "$kind" 8 || true)"
        log "diag real_text_edit reveal semantic=$semantic clipped_frame='${targetFrame}' revealed_frame='${revealed}'"
        REAL_EDIT_REVEALED_FRAME="$revealed"
        targetFrame="$revealed"
      fi
      if [[ "$targetFrame" == "missing" || -z "$targetFrame" ]]; then
        log "diag real_text_edit identifier_frame=missing semantic=$semantic"
        REAL_EDIT_CLICK_FRAME="$clickOverride"
        targetFrame="$(ax_target_frame "$kind" "$description" "$(ax_role_for_kind "$kind")")"
        REAL_EDIT_CLICK_FRAME=""
      fi
      if [[ "$targetFrame" != "missing" && -n "$targetFrame" ]]; then
        REAL_EDIT_FRAME="$targetFrame"
        click_frame_center "$targetFrame" || true
        sleep 0.6
      fi
      local focusPoll=0
      while (( focusPoll < 8 )); do
        focus="$(window_focus_for "$descriptor")"
        [[ "$focus" == "$semantic" ]] && break
        sleep 0.25
        focusPoll=$(( focusPoll + 1 ))
      done
      log "diag real_text_edit_focus label=$label attempt=$focusAttempt semantic=$semantic frame='${targetFrame}' observed='$focus'"
      if [[ "$focus" == "$semantic" ]]; then
        # Focus is on the intended control; nothing may have moved while it was
        # acquired, and only then is the target typed.
        real_edit_assert_isolated "$label" "$descriptor" "$fieldId" "$fieldsBefore" focus_acquire
        if real_type_target; then
          [[ "$(field_text_value "$descriptor" "$fieldId")" == "$target" ]] || {
            log "diag real_text_edit focus_value_mismatch label=$label value='$(field_text_value "$descriptor" "$fieldId")' target='$target'"
            return 1
          }
          real_edit_assert_isolated "$label" "$descriptor" "$fieldId" "$fieldsBefore" focus_after
          REAL_EDIT_MODE="click_${REAL_EDIT_MODE} focus=$focus"
          return 0
        fi
        return 1
      fi
      focusAttempt=$(( focusAttempt + 1 ))
    done
    log "diag real_text_edit no_focus label=$label semantic=$semantic frame='${targetFrame}' observed='$focus' description='$description' frontmost=$(app_frontmost)"
    return 1
  fi

  # Consumer without the public focus query: press inside the accepted control's
  # AX frame; the owner read-back decides acceptance. This path can prove the
  # OWNER value changed, NOT which instance received the input, so it says so
  # explicitly and a chain that requires exact-instance evidence stops here
  # instead of passing on a label/role match.
  log "diag real_text_edit evidence_grade=owner_readback_only exact_instance=false semantic=$semantic target='${RE_WINDOW_TARGET:-none}'"
  if [[ "${REQUIRE_EXACT_INSTANCE_EVIDENCE:-0}" == "1" ]]; then
    log "diag real_text_edit blocked reason=exact_instance_evidence_required semantic=$semantic"
    return 1
  fi
  # The window is made frontmost
  # AND key first - an Accessibility size change can leave the window visible but
  # not frontmost, in which case synthetic input is delivered nowhere.
  local keyVariant
  keyVariant="$(ensure_window_key || true)"
  log "diag real_text_edit_key label=$label key_variant='${keyVariant:-none}' window_focus='$(ax_window_focus_report)' frontmost='$(app_frontmost)'"
  if [[ -z "$keyVariant" ]]; then
    log "diag real_text_edit_not_key_window label=$label window_focus='$(ax_window_focus_report)' frontmost='$(app_frontmost)'"
  fi
  local attempt2=0
  while (( attempt2 < 3 )); do
    # Press the control's own accessibility frame in SCREEN coordinates. The
    # accepted instance bounds are content-relative, so they are only a fallback
    # when no role-matched AX frame exists at all.
    REAL_EDIT_CLICK_FRAME="$clickOverride"
    targetFrame="$(ax_target_frame "$kind" "$description" "$(ax_role_for_kind "$kind")")"
    REAL_EDIT_CLICK_FRAME=""
    if [[ "$targetFrame" == "missing" || -z "$targetFrame" ]]; then
      targetFrame="$(instance_frame "$(accepted_field_instance_line "$descriptor" "$fieldId" "$declaredKey" || true)" || true)"
    fi
    if [[ -n "$targetFrame" ]]; then
      REAL_EDIT_FRAME="$targetFrame"
      # The first press can only key an inactive exported window, so the first
      # attempt presses twice: the second press lands on the control of the now
      # key window.
      click_frame_center "$targetFrame" || true
      if (( attempt2 == 0 )); then
        sleep 0.4
        click_frame_center "$targetFrame" || true
      fi
      sleep 0.8
      local elementFocus windowFocus
      elementFocus="$(ax_element_focus "$kind" "$description")"
      windowFocus="$(ax_window_focus)"
      log "diag real_text_edit_focus label=$label attempt=$attempt2 semantic=$semantic frame='$targetFrame' element_focused=$elementFocus window_focused=$windowFocus frontmost='$(app_frontmost)'"
      # The AXFocused attribute is logged but NOT used as a gate: on this host it
      # reads false even while the native window is key, the exact input proxy is
      # the first responder and key/text-change receipts are produced. The owner
      # read-back plus the isolation check below remain the acceptance decision.
      if real_type_target; then
        real_edit_assert_isolated "$label" "$descriptor" "$fieldId" "$fieldsBefore" frame_after
        REAL_EDIT_MODE="frame_${REAL_EDIT_MODE}"
        return 0
      fi
    fi
    attempt2=$(( attempt2 + 1 ))
  done
  log "diag real_text_edit no_edit label=$label description='$description' semantic=$semantic frame='$REAL_EDIT_FRAME' frontmost=$(app_frontmost)"
  log "diag real_text_edit fields='$(python3 "$CLIENT" "$descriptor" generated-fields 2>/dev/null | grep '^FIELD ' | tr '\n' ';')'"
  return 1
}

# real_generated_boolean_toggle <label> <descriptor> <fieldId> <description> [kind]
# A real press on the generated boolean control; a single bounded second press
# covers a first press that only activated the window. Returns 0 only when the
# owner boolean actually flipped.
real_generated_boolean_toggle() {
  local label="$1" descriptor="$2" fieldId="$3" description="$4" kind="${5:-checkbox}"
  REAL_EDIT_MODE=""; REAL_EDIT_FRAME=""
  REAL_EDIT_BEFORE="$(field_text_value "$descriptor" "$fieldId")"
  activate_app
  log "diag real_boolean_toggle_key label=$label frontmost=$(app_frontmost)"
  REAL_EDIT_FRAME="$(click_ax_element "$kind" "$description")" || return 1
  sleep 1.0
  REAL_EDIT_AFTER="$(field_text_value "$descriptor" "$fieldId")"
  if [[ "$REAL_EDIT_AFTER" != "$REAL_EDIT_BEFORE" && -n "$REAL_EDIT_AFTER" ]]; then
    REAL_EDIT_MODE="click_toggle frame=$REAL_EDIT_FRAME"; return 0
  fi
  log "diag real_boolean_toggle label=$label frame='$REAL_EDIT_FRAME' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' frontmost=$(app_frontmost)"
  REAL_EDIT_FRAME="$(click_ax_element "$kind" "$description")" || return 1
  sleep 1.0
  REAL_EDIT_AFTER="$(field_text_value "$descriptor" "$fieldId")"
  if [[ "$REAL_EDIT_AFTER" != "$REAL_EDIT_BEFORE" && -n "$REAL_EDIT_AFTER" ]]; then
    REAL_EDIT_MODE="click_toggle_second frame=$REAL_EDIT_FRAME"; return 0
  fi
  return 1
}

assert_boolean_flip() { # assert_boolean_flip <what>
  [[ "$REAL_EDIT_BEFORE" == "true" || "$REAL_EDIT_BEFORE" == "false" ]] || \
    fail "$1 boolean before is not a boolean ('$REAL_EDIT_BEFORE')"
  [[ "$REAL_EDIT_AFTER" == "true" || "$REAL_EDIT_AFTER" == "false" ]] || \
    fail "$1 boolean after is not a boolean ('$REAL_EDIT_AFTER')"
  [[ "$REAL_EDIT_BEFORE" != "$REAL_EDIT_AFTER" ]] || \
    fail "$1 boolean press did not flip the owner value (still $REAL_EDIT_BEFORE)"
}
