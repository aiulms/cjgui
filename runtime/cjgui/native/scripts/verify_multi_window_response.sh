#!/usr/bin/env zsh
# Multi-window response comparison (A same-content/no-group, static group,
# active group opacity; B continuously
# taking identity-carrying queued owner requests), as opposed to lifecycle-only
# scenarios. This workload proves queued request -> owner -> accepted scene;
# An additional active-load run delivers one real Accessibility press to A's
# published control while B's queue is progressing. That control uses the
# ordinary native action route, and the app's normal action log proves it ran.
#
# What is measured per application turn, from the opt-in response workload:
#   * the same A card keeps no group/static group/active group opacity across
#     the three legs (a_group_declared, a_group_opacity, a_group_active_turns);
#   * A's existing node-opacity animation stays active only in active mode, so
#     the separate P3 AX-control check retains its original route;
#   * every submitted B text input is observed by B's accepted scene, with the
#     owner/accepted latency in turns (inputs == accepted, max_latency_turns);
#   * after A is closed, B keeps accepting input (after_close_accept_turns > 0).
#
# The app's exit status and stderr are reported verbatim, and an actual crash
# (SIGSEGV / "signal:11" / "Segmentation fault") fails the run instead of being
# folded into a lifecycle pass.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/shared_document_window_app"
OUTPUT_DIR="${CJGUI_MULTI_WINDOW_RESPONSE_TMPDIR:-/private/tmp/cjgui-multi-window-response}"
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"

export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:-}"
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

zsh "$APP_DIR/run.sh" --build-only >"$WORK/build.log" 2>&1
BINARY="$APP_DIR/target/release/CJGUISharedDocument.app/Contents/MacOS/CJGUISharedDocument"
if [[ ! -x "$BINARY" ]]; then
  echo "multi-window response verify: binary missing: $BINARY" >&2
  exit 1
fi

OWNER_BUDGET_MS="${CJGUI_MULTI_WINDOW_RESPONSE_OWNER_BUDGET_MS:-100}"
SCENE_BUDGET_MS="${CJGUI_MULTI_WINDOW_RESPONSE_SCENE_BUDGET_MS:-150}"
[[ "$OWNER_BUDGET_MS" == <-> && "$SCENE_BUDGET_MS" == <-> ]] || {
  print -u2 -- "multi-window response verify: latency budgets must be integer milliseconds"
  exit 2
}
field() { print -r -- "$1" | sed -n "s/.*[[:space:]]$2[[:space:]]\([^[:space:]]*\).*/\1/p"; }
typeset -A INPUTS_BY_MODE

for EFFECT_MODE in no_effect static active; do
  LOG="$WORK/$EFFECT_MODE.response.log"
  ERR="$WORK/$EFFECT_MODE.response.stderr.log"
  set +e
  "$BINARY" --multi-window --multi-window-response --response-effect-mode "$EFFECT_MODE" \
    --measurement-warmup-ms 300 --measurement-duration-ms 6000 \
    --close-first-window-after-ms 2000 >"$LOG" 2>"$ERR"
  APP_STATUS=$?
  set -e
  print -r -- "multi-window response: mode=$EFFECT_MODE app_exit=$APP_STATUS log=$LOG"

  CRASH_LINE="$(rg -n 'signal:11|Segmentation fault|SIGSEGV|Abort trap|Bus error' "$LOG" "$ERR" 2>/dev/null | head -1 || true)"
  if [[ -n "$CRASH_LINE" ]]; then
    print -u2 -- "multi-window response verify: mode=$EFFECT_MODE crash evidence: $CRASH_LINE"
    exit 1
  fi
  if [[ "$APP_STATUS" != 0 ]]; then
    print -u2 -- "multi-window response verify: mode=$EFFECT_MODE application exit status $APP_STATUS"
    tail -20 "$ERR" >&2 || true
    exit 1
  fi

  SUMMARY="$(rg '^CJGUI_MULTI_WINDOW_RESPONSE_SUMMARY ' "$LOG" | tail -1 || true)"
  [[ -n "$SUMMARY" ]] || { print -u2 -- "multi-window response verify: mode=$EFFECT_MODE has no summary"; exit 1; }
  print -r -- "$SUMMARY"
  SUMMARY_MODE="$(field "$SUMMARY" effect_mode)"
  INPUTS="$(field "$SUMMARY" inputs)"
  ACCEPTED="$(field "$SUMMARY" accepted)"
  IDENTITY="$(field "$SUMMARY" identity_checked)"
  REQ_SCENE_MS="$(field "$SUMMARY" max_req_scene_ms)"
  MAX_TURNS="$(field "$SUMMARY" max_latency_turns)"
  A_ACTIVE="$(field "$SUMMARY" a_animation_active_turns)"
  A_GROUP_ACTIVE="$(field "$SUMMARY" a_effect_group_active_turns)"
  AFTER_CLOSE="$(field "$SUMMARY" after_close_accept_turns)"
  HELD="$(field "$SUMMARY" held)"

  [[ "$SUMMARY_MODE" == "$EFFECT_MODE" ]] || { print -u2 -- "multi-window response verify: expected mode=$EFFECT_MODE summary=$SUMMARY_MODE"; exit 1; }
  [[ "$HELD" == "true" ]] || { print -u2 -- "multi-window response verify: mode=$EFFECT_MODE held=$HELD"; exit 1; }
  (( INPUTS > 0 )) || { print -u2 -- "multi-window response verify: mode=$EFFECT_MODE submitted no B input"; exit 1; }
  (( ACCEPTED == INPUTS && IDENTITY == INPUTS )) || {
    print -u2 -- "multi-window response verify: mode=$EFFECT_MODE accepted=$ACCEPTED identity_checked=$IDENTITY inputs=$INPUTS"
    exit 1
  }
  (( MAX_TURNS > 0 )) || { print -u2 -- "multi-window response verify: mode=$EFFECT_MODE reported no positive queue latency turn"; exit 1; }
  (( REQ_SCENE_MS >= 0 && REQ_SCENE_MS <= SCENE_BUDGET_MS )) || {
    print -u2 -- "multi-window response verify: mode=$EFFECT_MODE max_req_scene_ms=$REQ_SCENE_MS budget=$SCENE_BUDGET_MS"
    exit 1
  }
  (( AFTER_CLOSE > 0 )) || { print -u2 -- "multi-window response verify: mode=$EFFECT_MODE B did not accept after A closed"; exit 1; }
  if [[ "$EFFECT_MODE" == "active" ]]; then
    (( A_ACTIVE > 0 )) || { print -u2 -- "multi-window response verify: active mode never animated A"; exit 1; }
    (( A_GROUP_ACTIVE > 0 )) || { print -u2 -- "multi-window response verify: active mode never changed A's EffectGroup opacity"; exit 1; }
  else
    (( A_ACTIVE == 0 )) || { print -u2 -- "multi-window response verify: mode=$EFFECT_MODE unexpectedly animated A ($A_ACTIVE turns)"; exit 1; }
    (( A_GROUP_ACTIVE == 0 )) || { print -u2 -- "multi-window response verify: mode=$EFFECT_MODE unexpectedly changed A's EffectGroup opacity ($A_GROUP_ACTIVE turns)"; exit 1; }
  fi

  python3 - "$LOG" "$EFFECT_MODE" "$INPUTS" "$OWNER_BUDGET_MS" "$SCENE_BUDGET_MS" "$REQ_SCENE_MS" <<'PY' || exit 1
import re, sys

path, expected_mode = sys.argv[1:3]
expected_inputs, owner_budget, scene_budget, summary_scene_max = map(int, sys.argv[3:])
samples = []
for line in open(path, encoding="utf-8", errors="replace"):
    if line.startswith("CJGUI_MULTI_WINDOW_RESPONSE "):
        values = dict(re.findall(r"(?:^|\s)([a-z_]+)\s+([^\s]+)", line))
        try:
            sample = {
                "index": int(values["index"]),
                "mode": values["effect_mode"],
                "owner_version": int(values["owner_version"]),
                "scene": int(values["b_scene"]),
                "submitted": int(values["submitted_now"]),
                "owner_ms": int(values["req_owner_ms"]),
                "scene_ms": int(values["req_scene_ms"]),
                "marker": values["req_marker"],
                "group_declared": int(values["a_group_declared"]),
                "group_opacity": float(values["a_group_opacity"]),
            }
        except (KeyError, ValueError) as error:
            raise SystemExit(f"multi-window response verify: malformed raw sample: {line.strip()} ({error})")
        samples.append(sample)

if not samples:
    raise SystemExit("multi-window response verify: no per-turn samples")
if any(sample["mode"] != expected_mode for sample in samples):
    raise SystemExit("multi-window response verify: a raw sample has the wrong effect mode")
expected_group_declared = 0 if expected_mode == "no_effect" else 1
if any(sample["group_declared"] != expected_group_declared for sample in samples):
    raise SystemExit("multi-window response verify: EffectGroup declaration does not match mode")
group_opacities = {round(sample["group_opacity"], 3) for sample in samples}
if expected_mode == "active":
    if not {0.55, 1.0}.issubset(group_opacities):
        raise SystemExit("multi-window response verify: active mode did not expose both EffectGroup opacity values")
elif group_opacities != {1.0}:
    raise SystemExit("multi-window response verify: static/no-group baseline opacity changed")
for previous, current in zip(samples, samples[1:]):
    if current["index"] <= previous["index"]:
        raise SystemExit("multi-window response verify: non-increasing turn index")
    if current["owner_version"] < previous["owner_version"] or current["scene"] < previous["scene"]:
        raise SystemExit("multi-window response verify: owner version or accepted scene moved backwards")

owner_by_marker = {}
scene_by_marker = {}
for sample in samples:
    marker = sample["marker"]
    if sample["submitted"] == 1:
        if marker in ("", "-") or marker in owner_by_marker:
            raise SystemExit(f"multi-window response verify: missing or duplicate request marker: {sample}")
        if not 0 <= sample["owner_ms"] <= owner_budget:
            raise SystemExit(f"multi-window response verify: request ready-to-owner latency outside budget: {sample}")
        owner_by_marker[marker] = sample["owner_ms"]
    if sample["scene_ms"] >= 0 and marker not in ("", "-"):
        scene_by_marker[marker] = sample["scene_ms"]

if len(owner_by_marker) != expected_inputs:
    raise SystemExit(f"multi-window response verify: raw submitted markers={len(owner_by_marker)} summary inputs={expected_inputs}")
if set(owner_by_marker) != set(scene_by_marker):
    raise SystemExit("multi-window response verify: a submitted marker lacks its accepted-scene latency")
for marker, owner_ms in owner_by_marker.items():
    scene_ms = scene_by_marker[marker]
    if not owner_ms <= scene_ms <= scene_budget:
        raise SystemExit(f"multi-window response verify: ready→owner→scene order/budget failed for {marker}: {owner_ms}→{scene_ms}ms")
if max(scene_by_marker.values()) != summary_scene_max:
    raise SystemExit("multi-window response verify: summary max does not match the retained request samples")
print(f"multi-window response: mode={expected_mode} raw_samples={len(samples)} inputs={len(owner_by_marker)} owner_budget_ms={owner_budget} scene_budget_ms={scene_budget} monotonic_owner_scene=1")
PY
  INPUTS_BY_MODE[$EFFECT_MODE]="$INPUTS"
  print -r -- "multi-window response: mode=$EFFECT_MODE inputs=$INPUTS accepted=$ACCEPTED max_scene_ms=$REQ_SCENE_MS animation_turns=$A_ACTIVE group_opacity_turns=$A_GROUP_ACTIVE log=$LOG stderr=$ERR"
done

[[ "${INPUTS_BY_MODE[no_effect]}" == "${INPUTS_BY_MODE[static]}" \
   && "${INPUTS_BY_MODE[static]}" == "${INPUTS_BY_MODE[active]}" ]] || {
  print -u2 -- "multi-window response verify: workload input counts differ across modes: no_effect=${INPUTS_BY_MODE[no_effect]} static=${INPUTS_BY_MODE[static]} active=${INPUTS_BY_MODE[active]}"
  exit 1
}
print -r -- "multi-window response: comparable modes held with same_queued_owner_inputs=${INPUTS_BY_MODE[active]}"

# A supervised desktop run may deliver the fourth leg's real control action
# through its own UI driver. Keep the three comparable timing legs and state
# clearly that this invocation has not yet run the control leg.
if [[ "${CJGUI_MULTI_WINDOW_RESPONSE_CONTROL_DRIVER:-script}" == "external" ]]; then
  print -r -- "multi-window response: comparable_modes=PASS real_control=external_pending work=$WORK"
  exit 0
fi

# One real control action under the SAME active B queue and A animation load.
# The preceding three runs stay directly comparable; this fourth run measures
# whether a published control can still be activated while that load runs.
source "$SCRIPT_DIR/lib_cjgui_instance.sh"
REAL_LOG="$WORK/active-real-control.response.log"
REAL_ERR="$WORK/active-real-control.response.stderr.log"
"$BINARY" --multi-window --multi-window-response --response-effect-mode active \
  --measurement-warmup-ms 300 --measurement-duration-ms 6000 \
  --close-first-window-after-ms 2000 >"$REAL_LOG" 2>"$REAL_ERR" &
REAL_PID=$!
real_cleanup() {
  if kill -0 "$REAL_PID" 2>/dev/null; then
    local current_command
    current_command="$(ps -p "$REAL_PID" -o command= 2>/dev/null || true)"
    if [[ "$current_command" == "$BINARY"* ]]; then
      kill "$REAL_PID" 2>/dev/null || true
      wait "$REAL_PID" 2>/dev/null || true
    fi
  fi
}
trap real_cleanup EXIT
ready_attempt=0
while (( ready_attempt < 30 )); do
  rg -q '^CJGUI_MULTI_WINDOW_RESPONSE index [1-9]' "$REAL_LOG" 2>/dev/null && break
  kill -0 "$REAL_PID" 2>/dev/null || break
  sleep 0.1
  ready_attempt=$(( ready_attempt + 1 ))
done
rg -q '^CJGUI_MULTI_WINDOW_RESPONSE index [1-9]' "$REAL_LOG" \
  || { print -u2 -- "multi-window response verify: real-control run never entered the B queue load"; exit 1; }
AX_ACTION=""
ax_attempt=0
while (( ax_attempt < 3 )); do
  AX_ACTION="$(cjgui_ax 8 -e "tell application \"System Events\"
    set p to first process whose unix id is $REAL_PID
    repeat with w in windows of p
      try
        set matches to every button of w whose description is \"动效过渡\"
        if (count of matches) is 1 then
          set frontmost of p to true
          perform action \"AXRaise\" of w
          click item 1 of matches
          return \"pressed\"
        end if
      end try
    end repeat
    return \"missing\"
  end tell" 2>/dev/null | tail -1 || true)"
  [[ "$AX_ACTION" == "pressed" ]] && break
  sleep 0.15
  ax_attempt=$(( ax_attempt + 1 ))
done
[[ "$AX_ACTION" == "pressed" ]] \
  || { print -u2 -- "multi-window response verify: BLOCKED A's published AX control could not be pressed during the load"; exit 3; }
REAL_STATUS=0
wait "$REAL_PID" || REAL_STATUS=$?
trap - EXIT
[[ "$REAL_STATUS" == "0" ]] || { print -u2 -- "multi-window response verify: real-control application exit=$REAL_STATUS"; exit 1; }
python3 - "$REAL_LOG" "$SCENE_BUDGET_MS" <<'PY'
import re, sys
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
actions = [i for i, line in enumerate(lines) if line.startswith("CJGUI_MULTI_WINDOW_ANIMATION_STATE view=primary ")
           and " started=1 " in line]
if not actions:
    raise SystemExit("multi-window response verify: the real AX action did not reach A's control")
action = actions[0]
before = [line for line in lines[:action] if line.startswith("CJGUI_MULTI_WINDOW_RESPONSE index ")]
after = [line for line in lines[action + 1:] if line.startswith("CJGUI_MULTI_WINDOW_RESPONSE index ")]
if not before or not after or " a_closed 0 " not in before[-1] or " a_closed 0 " not in after[0]:
    raise SystemExit("multi-window response verify: the control action was not bracketed by live A/B load turns")
summary = next((line for line in lines if line.startswith("CJGUI_MULTI_WINDOW_RESPONSE_SUMMARY ")), "")
values = dict(re.findall(r"(?:^|\s)([a-z_]+)\s+([^\s]+)", summary))
if (values.get("held") != "true" or values.get("inputs") != "120" or values.get("accepted") != "120"
        or values.get("identity_checked") != "120" or int(values.get("max_req_scene_ms", "-1")) > int(sys.argv[2])):
    raise SystemExit("multi-window response verify: B queue/scene did not hold through the real control action: " + summary)
print("multi-window response: real_ax_control=primary-effect-toggle bracketed_by_active_load=1 "
      "B_queued_accepted=120/120 max_req_scene_ms=" + values["max_req_scene_ms"])
PY
print -r -- "multi-window response verify: PASS modes=no_effect,static,active same_queued_owner_inputs=${INPUTS_BY_MODE[active]} real_control_under_active_load=AX log=$REAL_LOG"
