#!/usr/bin/env zsh
# Readability of the dark knowledge-catalog surface, observed from the REAL
# window.
#
# The stage's known gap was that the catalog surface is dark while the title,
# body, action buttons, status line and page tab titles still fell back to the
# near-black default foreground. A passing style is not a visible image, so this
# chain does not assert the style: it launches the UI-only tree consumer in BOTH
# configurations (default and the opt-in large-text fixture), raises its own
# per-round window, captures the platform compositor's own pixels, and asserts
# per-control that the dark surface really shows light text.
#
# Observation rules (so a transient compositor state cannot be read as a result):
#   * every control of a round is measured from ONE captured frame, so the
#     controls cannot disagree about which frame they saw;
#   * a frame is accepted only after TWO consecutive captures agree on the
#     window's own surface statistics (stability gate), and only when the window
#     surface - not an occluding application - dominates the frame;
#   * a control whose region is dominated by a bright uniform colour is refused
#     as an occluded observation instead of being counted as "light text".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/tree_outline_consumer"
# The same chain is run against a fresh EXPORT root for the final consumption
# step, where the consumer and the framework live under different parents. The
# runner, the consumer source and its dependency then all resolve inside that
# root instead of the author checkout.
APP_DIR="${CJGUI_TREE_READABILITY_APP_DIR:-$APP_DIR}"
RUNTIME_DIR="${CJGUI_TREE_READABILITY_RUNTIME_DIR:-$RUNTIME_DIR}"
OUTPUT_DIR="${CJGUI_TREE_READABILITY_TMPDIR:-/private/tmp/cjgui-tree-readability}"
export CJGUI_READABILITY_SCRIPT_DIR="$SCRIPT_DIR"

# The window's own surface colour, as the accepted scene paints it: a frame is
# this window's only when the surface really dominates it.
export SURFACE_R=17 SURFACE_G=26 SURFACE_B=40

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/chain.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; exit 1; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

if session_locked; then
  echo "tree catalog readability: BLOCKED the session is locked (CGSSessionScreenIsLocked=Yes); no window pixels can be observed" >&2
  exit 3
fi

AX_PID=""
ROUND=""
APP_PID=""
ROUND_DIR=""
ROUND_EXEC_NAME=""
cleanup() {
  [[ -n "$APP_PID" ]] || return 0
  if cjgui_unique_round_owns "$APP_PID" "$ROUND_EXEC_NAME" "$ROUND_DIR"; then
    kill "$APP_PID" 2>/dev/null || true
    sleep 1
    cjgui_unique_round_owns "$APP_PID" "$ROUND_EXEC_NAME" "$ROUND_DIR" && kill -9 "$APP_PID" 2>/dev/null || true
  fi
  log "cleanup round=$ROUND instance closed=$(cjgui_unique_round_owns "$APP_PID" "$ROUND_EXEC_NAME" "$ROUND_DIR" && echo no || echo yes)"
  APP_PID=""
}
trap cleanup EXIT

# The raise and the capture run inside ONE System Events script, so another
# application cannot take the foreground back between them. Only this round's
# own process id is ever raised.
capture_region() { # <x> <y> <w> <h> <out.png>
  local x="$1" y="$2" w="$3" h="$4" out="$5"
  [[ "$w" == <-> && "$h" == <-> ]] && (( w > 0 && h > 0 )) || return 1
  rm -f "$out"
  cjgui_ax 30 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set frontmost of p to true
    try
      perform action \"AXRaise\" of window 1 of p
    end try
  end tell
  delay 0.5
  do shell script \"screencapture -x -R ${x},${y},${w},${h} -t png '${out}'\"
  return \"captured\"" >/dev/null 2>&1 || true
  [[ -s "$out" ]]
}

# frame_surface_stats <png> -> "dark_fraction bright_fraction surface_fraction"
frame_surface_stats() {
  python3 - "$1" <<'PY'
import os, sys
sys.path.insert(0, os.environ["CJGUI_READABILITY_SCRIPT_DIR"])
import region_luminance as rl
r = int(os.environ["SURFACE_R"]); g = int(os.environ["SURFACE_G"]); b = int(os.environ["SURFACE_B"])
w, h, bpp, pixels = rl.read_pixels(sys.argv[1])
dark = bright = surface = 0
total = w * h
for y in range(h):
    row = pixels[y]
    for x in range(w):
        off = x * bpp
        pr, pg, pb = row[off], row[off + 1], row[off + 2]
        v = rl._luminance(pr, pg, pb)
        if v < 0.15:
            dark += 1
        if v >= 0.5:
            bright += 1
        if abs(pr - r) <= 4 and abs(pg - g) <= 4 and abs(pb - b) <= 4:
            surface += 1
print(f"{dark / total:.4f} {bright / total:.4f} {surface / total:.4f}")
PY
}

# analyze_frame <png> <scale> <name:x,y,w,h> ...
# Prints one CONTROL line per region, measured inside the ONE frame.
analyze_frame() {
  local png="$1" scale="$2"; shift 2
  python3 - "$png" "$scale" "$@" <<'PY'
import os, sys
sys.path.insert(0, os.environ["CJGUI_READABILITY_SCRIPT_DIR"])
import region_luminance as rl
png = sys.argv[1]
scale = float(sys.argv[2])
w, h, bpp, pixels = rl.read_pixels(png)
for spec in sys.argv[3:]:
    name, rect = spec.split(":", 1)
    x, y, rw, rh = (float(part) for part in rect.split(","))
    x0 = max(0, int(round(x * scale))); y0 = max(0, int(round(y * scale)))
    x1 = min(w, int(round((x + rw) * scale))); y1 = min(h, int(round((y + rh) * scale)))
    if x1 <= x0 or y1 <= y0:
        print(f"CONTROL {name} pixels=0 dark_fraction=1.0 bright_pixels=0 max_luminance=0.0 uniform_fraction=1.0")
        continue
    total = dark = bright = 0
    peak = 0.0
    hist = {}
    for yy in range(y0, y1):
        row = pixels[yy]
        for xx in range(x0, x1):
            off = xx * bpp
            pr, pg, pb = row[off], row[off + 1], row[off + 2]
            v = rl._luminance(pr, pg, pb)
            total += 1
            if v < 0.15:
                dark += 1
            if v >= 0.35:
                bright += 1
            if v > peak:
                peak = v
            key = (pr, pg, pb)
            hist[key] = hist.get(key, 0) + 1
    uniform = max(hist.values()) / total if total else 1.0
    print(f"CONTROL {name} pixels={total} dark_fraction={dark / total:.4f} bright_pixels={bright} "
          f"max_luminance={peak:.4f} uniform_fraction={uniform:.4f}")
PY
}

# content_frame prints the self-drawn rect (window frame without the titlebar).
content_frame() {
  local frame x y w h
  frame="$(ax_window_frame)"
  [[ "$frame" == <->* ]] || return 1
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  h="$(print -r -- "$frame" | awk '{print $4}')"
  print -r -- "$x $(( y + 28 )) $w $(( h - 28 ))"
}

clip_frame() { # <"x y w h"> <"cx cy cw ch"> -> "x y w h" | fail
  print -r -- "$1 $2" | awk '{
    x = $1; y = $2; w = $3; h = $4; cx = $5; cy = $6; cw = $7; ch = $8
    x0 = (x > cx) ? x : cx
    y0 = (y > cy) ? y : cy
    x1 = (x + w < cx + cw) ? x + w : cx + cw
    y1 = (y + h < cy + ch) ? y + h : cy + ch
    if (x1 - x0 < 4 || y1 - y0 < 4) exit 1
    print x0, y0, x1 - x0, y1 - y0
  }'
}

# capture_stable_frame <content-rect> <out.png>
# Accepts a frame only after two consecutive captures agree on the window's own
# surface fractions, and only when the window surface (not an occluder) dominates.
capture_stable_frame() {
  local content="$1" out="$2"
  local cx cy cw ch
  cx="$(print -r -- "$content" | awk '{print $1}')"
  cy="$(print -r -- "$content" | awk '{print $2}')"
  cw="$(print -r -- "$content" | awk '{print $3}')"
  ch="$(print -r -- "$content" | awk '{print $4}')"
  local attempt=1 prev="" stats dark bright surface
  while (( attempt <= 4 )); do
    local shot="$WORK/$ROUND-frame-$attempt.png"
    if ! capture_region "$cx" "$cy" "$cw" "$ch" "$shot"; then
      log "frame attempt=$attempt capture_failed"
      prev=""; sleep 1; attempt=$(( attempt + 1 )); continue
    fi
    stats="$(frame_surface_stats "$shot")"
    dark="$(print -r -- "$stats" | awk '{print $1}')"
    bright="$(print -r -- "$stats" | awk '{print $2}')"
    surface="$(print -r -- "$stats" | awk '{print $3}')"
    log "frame attempt=$attempt dark_fraction=$dark bright_fraction=$bright surface_fraction=$surface"
    if ! awk -v s="$surface" 'BEGIN { exit (s >= 0.30) ? 0 : 1 }'; then
      log "frame attempt=$attempt rejected=surface_not_dominant"
      prev=""; sleep 1; attempt=$(( attempt + 1 )); continue
    fi
    if ! awk -v b="$bright" 'BEGIN { exit (b <= 0.60) ? 0 : 1 }'; then
      log "frame attempt=$attempt rejected=occluder_dominant"
      prev=""; sleep 1; attempt=$(( attempt + 1 )); continue
    fi
    if [[ -n "$prev" ]]; then
      local pd pb
      pd="$(print -r -- "$prev" | awk '{print $1}')"
      pb="$(print -r -- "$prev" | awk '{print $2}')"
      if awk -v a="$dark" -v b="$pd" -v c="$bright" -v d="$pb" 'BEGIN {
            da = (a > b) ? a - b : b - a
            if (da > 0.02) exit 1
            limit = (d > 20) ? d * 0.05 : 20
            diff = (c > d) ? c - d : d - c
            exit (diff <= limit) ? 0 : 1
          }'; then
        cp "$shot" "$out"
        log "frame accepted attempt=$attempt stable=true"
        return 0
      fi
      log "frame attempt=$attempt rejected=unstable"
    fi
    prev="$stats"
    sleep 1
    attempt=$(( attempt + 1 ))
  done
  return 1
}

run_round() { # <name> <fixture|default> <derived-body-semantic-id>
  ROUND="$1"
  local fixture="$2"
  local body_semantic="$3"
  ROUND_DIR="$WORK/round-$ROUND"
  ROUND_EXEC_NAME="CJGUIUiOnlyStarter${ROUND}${RUN_TAG}"
  cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "CJGUIUiOnlyStarter" \
    "${ROUND}${RUN_TAG}" "org.example.cjgui.ui-only-starter" \
    || fail "round $ROUND: per-round application copy failed"

  local stdout_log="$WORK/app-$ROUND.log"
  if [[ "$fixture" == "large-text" ]]; then
    ( cd "$ROUND_DIR" && CJGUI_TREE_OUTLINE_TEXT_FIXTURE=large-text nohup zsh run.sh > "$stdout_log" 2>&1 & )
  else
    ( cd "$ROUND_DIR" && nohup zsh run.sh > "$stdout_log" 2>&1 & )
  fi

  APP_PID=""
  local waited=0
  while (( waited < 240 )); do
    APP_PID="$(cjgui_unique_round_pid "$ROUND_EXEC_NAME" "$ROUND_DIR" || true)"
    if [[ -n "$APP_PID" ]] && grep -q 'TREE_OUTLINE_CONSUMER_READY' "$stdout_log" 2>/dev/null; then break; fi
    sleep 2; waited=$(( waited + 2 ))
  done
  [[ -n "$APP_PID" ]] || fail "round $ROUND: consumer did not start"
  cjgui_unique_round_owns "$APP_PID" "$ROUND_EXEC_NAME" "$ROUND_DIR" \
    || fail "round $ROUND: consumer pid is not this round's instance"
  AX_PID="$APP_PID"
  AX_APP_PATH="$ROUND_DIR/target/release/${ROUND_EXEC_NAME}.app"
  local ready
  ready="$(grep -m1 'TREE_OUTLINE_CONSUMER_READY' "$stdout_log")"
  log "round=$ROUND pid=$APP_PID owner_verified=unique-exec+dir ready='$ready'"
  if [[ "$fixture" == "large-text" ]] && [[ "$ready" != *"fixture=large-text"* ]]; then
    fail "round $ROUND: the consumer did not report the large-text fixture"
  fi

  real_ax_wait_ready "$APP_PID" 24 >/dev/null || fail "round $ROUND: accessibility tree never became enumerable"
  # Let the first accepted scene settle before the observation.
  sleep 3

  local content
  content="$(content_frame)" || fail "round $ROUND: window has no frame"
  log "round=$ROUND window='$(ax_window_frame)' content='$content'"
  local frame_png="$WORK/$ROUND-frame.png"
  capture_stable_frame "$content" "$frame_png" || fail "round $ROUND: no stable frame of this window was obtained"

  local cx cy cw ch
  cx="$(print -r -- "$content" | awk '{print $1}')"
  cy="$(print -r -- "$content" | awk '{print $2}')"
  cw="$(print -r -- "$content" | awk '{print $3}')"
  ch="$(print -r -- "$content" | awk '{print $4}')"
  local scale
  scale="$(python3 - "$frame_png" "$cw" <<'PY'
import os, sys
sys.path.insert(0, os.environ["CJGUI_READABILITY_SCRIPT_DIR"])
import region_luminance as rl
w, h, bpp, pixels = rl.read_pixels(sys.argv[1])
print(f"{w / float(sys.argv[2]):.4f}")
PY
)"
  log "round=$ROUND frame=$frame_png scale=$scale"

  local -a specs=()
  local -a labels=()
  local -a minimums=()
  local label semantic minimum frame clipped x0 y0 rw rh control rest
  local -a controls=("title:catalog-tree-title:200" "tab_title:catalog-workspace-tab-catalog:30"
                     "action:catalog-expand-all:30" "body:$3:200" "status:catalog-status:30")
  for control in "${controls[@]}"; do
    label="${control%%:*}"
    rest="${control#*:}"
    semantic="${rest%%:*}"
    minimum="${rest##*:}"
    frame="$(ax_identifier_frame "$semantic" "UI element")"
    if [[ "$frame" == "missing" ]]; then
      fail "round $ROUND: control $label ($semantic) has no accessibility frame"
    fi
    if ! clipped="$(clip_frame "$frame" "$content")"; then
      log "CONTROL $ROUND label=$label semantic=$semantic frame='$frame' status=clipped_outside_window"
      continue
    fi
    x0="$(print -r -- "$clipped" | awk -v cx="$cx" '{printf "%.0f", $1 - cx}')"
    y0="$(print -r -- "$clipped" | awk -v cy="$cy" '{printf "%.0f", $2 - cy}')"
    rw="$(print -r -- "$clipped" | awk '{print $3}')"
    rh="$(print -r -- "$clipped" | awk '{print $4}')"
    log "CONTROL $ROUND label=$label semantic=$semantic frame='$clipped' crop=${x0},${y0},${rw},${rh} minimum=$minimum"
    specs+=("$label:${x0},${y0},${rw},${rh}")
    labels+=("$label")
    minimums+=("$minimum")
  done
  (( ${#specs[@]} > 0 )) || fail "round $ROUND: no control of this round is inside the window"

  local analysis
  analysis="$(analyze_frame "$frame_png" "$scale" "${specs[@]}")" || fail "round $ROUND: frame analysis failed"
  print -r -- "$analysis" | sed "s/^/MEASURED $ROUND /" >> "$LOG"

  local index=1
  local line="" dark="" bright="" peak="" uniform=""
  while (( index <= ${#labels[@]} )); do
    label="${labels[index]}"
    minimum="${minimums[index]}"
    line="$(print -r -- "$analysis" | grep "^CONTROL $label " || true)"
    [[ -n "$line" ]] || fail "round $ROUND: no measurement for $label"
    dark="$(print -r -- "$line" | sed -n 's/.*dark_fraction=\([0-9.]*\).*/\1/p')"
    bright="$(print -r -- "$line" | sed -n 's/.*bright_pixels=\([0-9]*\).*/\1/p')"
    peak="$(print -r -- "$line" | sed -n 's/.*max_luminance=\([0-9.]*\).*/\1/p')"
    uniform="$(print -r -- "$line" | sed -n 's/.*uniform_fraction=\([0-9.]*\).*/\1/p')"
    # An occluded rectangle is one bright uniform colour, not text on the dark
    # catalog surface: refuse it instead of reading it as readable text.
    if awk -v d="$dark" -v u="$uniform" 'BEGIN { exit (d < 0.30 && u >= 0.90) ? 0 : 1 }'; then
      fail "round $ROUND: $label region is a uniform bright area (dark_fraction=$dark uniform_fraction=$uniform) - the window was occluded"
    fi
    if ! awk -v b="$bright" -v m="$minimum" 'BEGIN { exit (b >= m) ? 0 : 1 }'; then
      fail "round $ROUND: $label shows $bright light pixels (want >= $minimum, max_luminance=$peak) - the dark surface is not showing light text there"
    fi
    if ! awk -v p="$peak" 'BEGIN { exit (p >= 0.35) ? 0 : 1 }'; then
      fail "round $ROUND: $label has no pixel above the light-text floor (max_luminance=$peak)"
    fi
    log "ASSERT $ROUND label=$label bright_pixels=$bright max_luminance=$peak dark_fraction=$dark ok=true"
    index=$(( index + 1 ))
  done

  log "round=$ROUND summary=readable controls=${#labels[@]}"
  cp "$frame_png" "$OUTPUT_DIR/latest-$ROUND.png"
  cleanup
  ROUND_DIR=""
}

run_round default default catalog-details
run_round large large-text catalog-large-details

log "PASSED tree catalog readability in the default and large-text configurations"
cat "$LOG"
echo "PASSED tree catalog readability output=$WORK"
exit 0
