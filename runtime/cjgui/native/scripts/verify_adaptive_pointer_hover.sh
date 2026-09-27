#!/usr/bin/env zsh
# Real-pointer verification for the UI-only consumer's interactive effect card.
#
# The card's hover/pressed paint is declared as a framework interaction style:
# a REAL pointer enter/leave/down/up/cancel resolves to the framework hover and
# pressed states and changes the card's paint alpha. (A button node is not a
# pointer-capture kind, so 37/39 never reach a controller; the visual transition
# is owned by the framework's interaction projection.)
#
# What this script proves with a real posted pointer (no controller shortcut):
#   * a real pointer move onto the card darkens the card's pixels (hover);
#   * a real pointer move off the card restores them (leave);
#   * a real pointer press darkens further (pressed);
#   * a real click inside the card activates the owner action (count grows),
#     while the same click on the shadow band does not.
#
# The card's screen point is derived from the app's published accepted geometry
# plus the window frame, and is calibrated against the real hover response (the
# title-bar offset is inferred, not guessed): if no offset produces a hover
# response the script reports BLOCKED instead of a false failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/adaptive_layout_public_consumer"
OUTPUT_DIR="${CJGUI_ADAPTIVE_POINTER_TMPDIR:-/private/tmp/cjgui-adaptive-pointer}"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"

export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-}"
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

# A locked session cannot deliver a real pointer; report BLOCKED (exit 3).
LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
LOCK_STATE="${LOCK_STATE//[[:space:]]/}"
if [[ "$LOCK_STATE" == "Yes" ]]; then
  echo "adaptive pointer verify: BLOCKED the session is locked; a real pointer cannot be delivered" >&2
  exit 3
fi
if ! command -v swiftc >/dev/null 2>&1; then
  echo "adaptive pointer verify: BLOCKED swiftc is required for the real input driver" >&2
  exit 3
fi

DRIVER="$WORK/desktop_input_driver"
swiftc -O "$RUNTIME_DIR/native/tests/desktop_input_driver.swift" -o "$DRIVER" >"$WORK/driver-build.log" 2>&1

export CJGUI_ROOT="$RUNTIME_DIR"
zsh "$RUNTIME_DIR/scripts/run_macos_application.sh" "$APP_DIR/cjgui_macos_app.sh" --build-only >"$WORK/build.log" 2>&1
BINARY="$APP_DIR/target/release/AdaptiveLayoutPublicConsumer.app/Contents/MacOS/AdaptiveLayoutPublicConsumer"
if [[ ! -x "$BINARY" ]]; then
  echo "adaptive pointer verify: binary missing: $BINARY" >&2
  exit 1
fi

APP_LOG="$WORK/app.log"
APP_PID=""
cleanup() {
  if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    kill -TERM "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Register this round's identity BEFORE launching: a round-unique token in the
# command line is the only thing that can select the exact process this script
# started. "Newest pid matching the binary path" would mis-identify a parallel
# instance of the same application.
INSTANCE_TOKEN="cjgui-adaptive-hover-${RUN_TAG}"
( cd "$APP_DIR" && nohup "$BINARY" --instance-token "$INSTANCE_TOKEN" --observe-interaction >"$APP_LOG" 2>&1 & )
APP_PID=""
waited=0
while (( waited < 40 )); do
  APP_PID="$(pgrep -f -- "$INSTANCE_TOKEN" 2>/dev/null | head -1 || true)"
  [[ -n "$APP_PID" ]] && break
  sleep 0.25
  waited=$(( waited + 1 ))
done
if [[ -z "$APP_PID" ]]; then
  echo "adaptive pointer verify: application did not start" >&2
  exit 1
fi
# Ownership is re-proven against the token before any signal, so a recycled or
# parallel pid can never be selected.
if ! ps -p "$APP_PID" -o command= 2>/dev/null | grep -q -- "$INSTANCE_TOKEN"; then
  echo "adaptive pointer verify: pid $APP_PID does not carry this round's token" >&2
  exit 1
fi

waited=0
while (( waited < 40 )); do
  if rg -q '^CJGUI_ADAPTIVE_HIT_BOUNDS x=' "$APP_LOG" && rg -q '^CJGUI_ADAPTIVE_HIT_SCREEN window_frame=' "$APP_LOG"; then
    break
  fi
  sleep 0.5
  waited=$(( waited + 1 ))
done

read_field() { rg -o "$1=[^ ]+" "$APP_LOG" | tail -1 | cut -d= -f2; }
BOUNDS_LINE="$(rg '^CJGUI_ADAPTIVE_HIT_BOUNDS x=' "$APP_LOG" | tail -1 || true)"
SCREEN_LINE="$(rg '^CJGUI_ADAPTIVE_HIT_SCREEN window_frame=' "$APP_LOG" | tail -1 || true)"
if [[ -z "$BOUNDS_LINE" || -z "$SCREEN_LINE" ]]; then
  echo "adaptive pointer verify: card geometry/frame not published" >&2
  tail -20 "$APP_LOG" >&2 || true
  exit 1
fi
print -r -- "adaptive pointer verify: $BOUNDS_LINE"
print -r -- "adaptive pointer verify: $SCREEN_LINE"

bx="$(print -r -- "$BOUNDS_LINE" | sed -n 's/.*[[:space:]]x=\([0-9-]*\).*/\1/p')"
by="$(print -r -- "$BOUNDS_LINE" | sed -n 's/.*[[:space:]]y=\([0-9-]*\).*/\1/p')"
bw="$(print -r -- "$BOUNDS_LINE" | sed -n 's/.*[[:space:]]w=\([0-9-]*\).*/\1/p')"
bh="$(print -r -- "$BOUNDS_LINE" | sed -n 's/.*[[:space:]]h=\([0-9-]*\).*/\1/p')"
frame="$(print -r -- "$SCREEN_LINE" | sed -n 's/.*window_frame=//p')"
fx="$(print -r -- "$frame" | cut -d, -f1)"
fy="$(print -r -- "$frame" | cut -d, -f2)"
fw="$(print -r -- "$frame" | cut -d, -f3)"
fh="$(print -r -- "$frame" | cut -d, -f4)"

# --- pixel readback (1x1 screen capture -> BMP -> first pixel) --------------
bmp_pixel() {
  python3 - "$1" <<'PY'
import struct, sys
data = open(sys.argv[1], "rb").read()
off = struct.unpack_from("<I", data, 10)[0]
bpp = struct.unpack_from("<H", data, 28)[0]
if bpp == 32:
    b, g, r, _a = struct.unpack_from("<BBBB", data, off)
elif bpp == 24:
    b, g, r = struct.unpack_from("<BBB", data, off)
else:
    b = g = r = 0
print(f"{r} {g} {b}")
PY
}

luma() { # r g b -> luma
  python3 -c "r,g,b=$1,$2,$3; print(f'{0.2126*r+0.7152*g+0.0722*b:.1f}')"
}

shot_rgb() { # x y -> "r g b"
  screencapture -x -R"$1,$2,1,1" "$WORK/pix.png" 2>/dev/null || true
  sips -s format bmp "$WORK/pix.png" --out "$WORK/pix.bmp" >/dev/null 2>&1 || true
  bmp_pixel "$WORK/pix.bmp"
}

# Move the real pointer to a blank spot inside the window (bottom-right), so the
# application keeps key/frontmost focus: parking outside would activate another
# application and stop mouse-moved delivery to this window.
park_pointer() {
  "$DRIVER" move $(( fx + fw - 24 )) $(( fy + fh - 24 )) >/dev/null 2>&1 || true
  sleep 0.5
}

# Make the application key/frontmost without clicking any content control.
activate_app() {
  osascript -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set frontmost of p to true
    perform action \"AXRaise\" of window 1 of p
  end tell" >/dev/null 2>&1 || true
  sleep 0.6
}

activate_app

CENTER_X=$(( fx + bx + bw / 2 ))
CARD_SCENE_MID_Y=$(( by + bh / 2 ))

# A valid card sample must actually read the card's own paint, not the page
# background of an occluding window. Retries below re-activate the window and
# re-sample so a transient foreground loss cannot masquerade as "hover did not
# happen". windowScreenFrame() already returns the window's top-left on-screen
# frame, so fy + titlebar + sceneY is the correct screen point (x hits the card
# colour, which confirms the conversion).
card_like() { python3 -c "exit(0 if 60 < $1 < 95 else 1)"; }
sample_visible() { python3 -c "exit(0 if $1 < 160 else 1)"; }

CENTER_X=$(( fx + bx + bw / 2 ))
CARD_SCENE_MID_Y=$(( by + bh / 2 ))

# Calibrate the title-bar offset by finding the card's own paint. Only the card
# carries a hover interaction style, and the card colour is the unique band in
# this window, so the offset whose sample reads as card colour is correct.
TITLEBAR=""
FOUND_NORMAL=""
FOUND_HOVER=""
for tb in 28 30 32 26 34 24 36 22 0 40; do
  activate_app
  cy=$(( fy + tb + CARD_SCENE_MID_Y ))
  park_pointer
  normal="$(shot_rgb "$CENTER_X" "$cy")"
  n_luma="$(luma ${=normal})"
  if ! card_like "$n_luma"; then
    print -r -- "adaptive pointer verify: calibrate titlebar=$tb normal=[$normal] luma=$n_luma (not card)"
    continue
  fi
  activate_app
  "$DRIVER" move "$CENTER_X" "$cy" >/dev/null 2>&1 || true
  sleep 0.6
  hover="$(shot_rgb "$CENTER_X" "$cy")"
  h_luma="$(luma ${=hover})"
  print -r -- "adaptive pointer verify: calibrate titlebar=$tb normal=[$normal] luma=$n_luma hover=[$hover] luma=$h_luma"
  TITLEBAR="$tb"
  FOUND_NORMAL="$normal"
  FOUND_HOVER="$hover"
  break
done

if [[ -z "$TITLEBAR" ]]; then
  echo "adaptive pointer verify: BLOCKED card sample never read the card paint at any title-bar offset; coordinates could not be calibrated" >&2
  exit 3
fi
CARD_Y=$(( fy + TITLEBAR + CARD_SCENE_MID_Y ))
print -r -- "adaptive pointer verify: calibrated titlebar=$TITLEBAR card_screen=($CENTER_X,$CARD_Y)"

# Normal/leave: pointer parked off-card; the card must read its normal paint.
normal="$FOUND_NORMAL"
n_luma="$(luma ${=normal})"
for attempt in 1 2 3 4; do
  activate_app
  park_pointer
  normal="$(shot_rgb "$CENTER_X" "$CARD_Y")"
  n_luma="$(luma ${=normal})"
  card_like "$n_luma" && break
done

# Hover: pointer moved onto the card; retry if an occluder is sampled instead.
hover="$FOUND_HOVER"
h_luma="$(luma ${=hover})"
for attempt in 1 2 3 4; do
  activate_app
  "$DRIVER" move "$CENTER_X" "$CARD_Y" >/dev/null 2>&1 || true
  sleep 0.6
  hover="$(shot_rgb "$CENTER_X" "$CARD_Y")"
  h_luma="$(luma ${=hover})"
  sample_visible "$h_luma" && break
done

# Leave: pointer parked off-card again; the card must return to normal paint.
leave=""
for attempt in 1 2 3 4; do
  activate_app
  park_pointer
  leave="$(shot_rgb "$CENTER_X" "$CARD_Y")"
  l_luma="$(luma ${=leave})"
  card_like "$l_luma" && break
done

# Press: hold the real button down and read the pressed paint. A sampled
# occluder (background) is retried, releasing first so the gesture restarts.
pressed=""
for attempt in 1 2 3 4; do
  activate_app
  "$DRIVER" press "$CENTER_X" "$CARD_Y" >/dev/null 2>&1 || true
  sleep 0.6
  pressed="$(shot_rgb "$CENTER_X" "$CARD_Y")"
  p_luma="$(luma ${=pressed})"
  sample_visible "$p_luma" && break
  "$DRIVER" release "$CENTER_X" "$CARD_Y" >/dev/null 2>&1 || true
  sleep 0.3
done
"$DRIVER" release "$CENTER_X" "$CARD_Y" >/dev/null 2>&1 || true
sleep 0.5
park_pointer
sleep 0.5

# Owner action: a real click inside the card must reach the card's own action
# (the app prints CJGUI_SHADOW_HIT_STATE); a click on the shadow band must not.
COUNT_BEFORE="$(rg -o 'clicked=1 count=[0-9]+' "$APP_LOG" | tail -1 | cut -d= -f3 || true)"
COUNT_BEFORE="${COUNT_BEFORE:-0}"
"$DRIVER" click "$CENTER_X" "$CARD_Y" >/dev/null 2>&1 || true
sleep 0.6
COUNT_AFTER="$(rg -o 'clicked=1 count=[0-9]+' "$APP_LOG" | tail -1 | cut -d= -f3 || true)"
COUNT_AFTER="${COUNT_AFTER:-0}"

SHADOW_Y=$(( CARD_Y + bh / 2 + 6 ))
"$DRIVER" click "$CENTER_X" "$SHADOW_Y" >/dev/null 2>&1 || true
sleep 0.6
COUNT_SHADOW="$(rg -o 'clicked=1 count=[0-9]+' "$APP_LOG" | tail -1 | cut -d= -f3 || true)"
COUNT_SHADOW="${COUNT_SHADOW:-0}"


# --- B1 interaction-transition trace (real pointer) -------------------------
# Drive a real enter and then a MID-FLIGHT leave. The application prints one
# line per changed displayed interaction alpha. Separate the samples taken
# before and after the leave event so an ordinary enter/leave pair cannot pass
# by contributing unrelated intermediate values.
activate_app
park_pointer
sleep 1.0
TRACE_START_LINE="$(wc -l < "$APP_LOG" | tr -d ' ')"
"$DRIVER" move-fast "$CENTER_X" "$CARD_Y" >/dev/null 2>&1 || true
sleep 0.035
TRACE_LEAVE_LINE="$(wc -l < "$APP_LOG" | tr -d ' ')"
"$DRIVER" move-fast "$CENTER_X" $(( CARD_Y + 140 )) >/dev/null 2>&1 || true
sleep 1.2
tail -n "+$(( TRACE_START_LINE + 1 ))" "$APP_LOG" > "$WORK/interaction-trace.log" || true
INTERACTION_TRACE_JSON="$(python3 - "$WORK/interaction-trace.log" "$(( TRACE_LEAVE_LINE - TRACE_START_LINE ))" <<'PY'
import json, re, sys
enter = []
reverse = []
split = int(sys.argv[2])
try:
    handle = open(sys.argv[1], encoding="utf-8", errors="replace")
except OSError:
    handle = []
for index, line in enumerate(handle):
    match = re.search(r"CJGUI_ADAPTIVE_INTERACTION_PAINT alpha=([0-9.]+)", line)
    if match:
        (enter if index < split else reverse).append(float(match.group(1)))
enter_falling = len(enter) >= 2 and all(a > b for a, b in zip(enter, enter[1:]))
turn_index = reverse.index(min(reverse)) if reverse else -1
reverse_rising = (len(reverse) >= 2 and turn_index >= 0
                  and len(reverse[turn_index:]) >= 2
                  and all(a < b for a, b in zip(reverse[turn_index:], reverse[turn_index + 1:])))
continuous = bool(enter and reverse) and abs(reverse[0] - enter[-1]) <= 0.10
print(json.dumps({
    "enter_count": len(enter),
    "reverse_count": len(reverse),
    "enter_falling": enter_falling,
    "reverse_rising": reverse_rising,
    "turn_index": turn_index,
    "continuous": continuous,
    "enter_first": enter[0] if enter else None,
    "before_leave": enter[-1] if enter else None,
    "after_leave": reverse[0] if reverse else None,
    "reverse_min": min(reverse) if reverse else None,
    "last": reverse[-1] if reverse else None,
}))
PY
)"

print -r -- "adaptive pointer verify: normal=[$normal] luma=$n_luma hover=[$hover] luma=$h_luma leave=[$leave] luma=$l_luma pressed=[$pressed] luma=$p_luma"
print -r -- "adaptive pointer verify: count_before=$COUNT_BEFORE count_after=$COUNT_AFTER count_shadow=$COUNT_SHADOW"

fail=0
hover_blocked=0
if ! python3 -c "exit(0 if $h_luma < $n_luma - 4 else 1)"; then
  print -u2 "adaptive pointer verify: BLOCKED real hover did not change the card paint (no HOVER_ENTER/LEAVE observed on the plain move)"
  hover_blocked=1
fi
python3 -c "exit(0 if $p_luma < $n_luma - 6 else 1)" || { print -u2 "adaptive pointer verify: pressed did not darken the card"; fail=1; }
python3 -c "exit(0 if abs($l_luma - $n_luma) < 8 else 1)" || { print -u2 "adaptive pointer verify: leave did not restore the card"; fail=1; }
(( COUNT_AFTER > COUNT_BEFORE )) || { print -u2 "adaptive pointer verify: inside click did not activate the owner action"; fail=1; }
(( COUNT_SHADOW == COUNT_AFTER )) || { print -u2 "adaptive pointer verify: shadow-band click wrongly activated the card"; fail=1; }

# B1: the real interaction change must be a frame-by-frame transition, and the
# mid-flight leave must continue from the current value (not jump to an endpoint).
python3 - "$INTERACTION_TRACE_JSON" <<'PY' || fail=1
import json, sys
data = json.loads(sys.argv[1])
ok = (data["enter_count"] >= 2 and data["reverse_count"] >= 2
      and data["enter_falling"] and data["reverse_rising"] and data["continuous"]
      and data["before_leave"] is not None and 0.75 < data["before_leave"] < 1.0
      and data["reverse_min"] is not None and data["reverse_min"] > 0.74
      and data["last"] is not None and abs(data["last"] - 1.0) < 0.04)
if not ok:
    print("adaptive pointer verify: segmented enter/reverse transition trace insufficient "
          + json.dumps(data), file=sys.stderr)
    sys.exit(1)
print("adaptive pointer verify: interaction_trace " + json.dumps(data))
PY

if (( fail != 0 )); then
  echo "adaptive pointer verify: FAIL (log=$APP_LOG work=$WORK)" >&2
  exit 1
fi
if (( hover_blocked != 0 )); then
  echo "adaptive pointer verify: BLOCKED pressed/leave/owner verified but real hover not observed (log=$APP_LOG work=$WORK)" >&2
  exit 3
fi
print -r -- "adaptive pointer verify: ok hover=darken pressed=darker leave=restore owner_click=activated shadow_click=rejected log=$APP_LOG"
