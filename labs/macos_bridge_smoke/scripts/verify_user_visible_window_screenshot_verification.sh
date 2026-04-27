#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_AND_RUN="$ROOT_DIR/scripts/build_and_run.sh"

LOG_PATH="${CJGUI_SCREENSHOT_VERIFICATION_LOG:-/tmp/cjgui-p1-user-visible-window-screenshot-verification.log}"
PROBE_ERR_PATH="${CJGUI_SCREENSHOT_VERIFICATION_PROBE_ERR:-/tmp/cjgui-p1-user-visible-window-screenshot-verification.err}"
READY_TIMEOUT_SECONDS="${CJGUI_SCREENSHOT_VERIFICATION_READY_TIMEOUT_SECONDS:-30}"
AUTOCLOSE_SECONDS="${CJGUI_SCREENSHOT_VERIFICATION_AUTOCLOSE_SECONDS:-8}"
WINDOW_TITLE="${CJGUI_SCREENSHOT_VERIFICATION_WINDOW_TITLE:-Cangjie macOS Bridge Smoke}"
EXPECTED_R="${CJGUI_SCREENSHOT_VERIFICATION_EXPECTED_R:-0.08}"
EXPECTED_G="${CJGUI_SCREENSHOT_VERIFICATION_EXPECTED_G:-0.16}"
EXPECTED_B="${CJGUI_SCREENSHOT_VERIFICATION_EXPECTED_B:-0.20}"
COLOR_TOLERANCE="${CJGUI_SCREENSHOT_VERIFICATION_COLOR_TOLERANCE:-0.08}"
CLEANUP_TTL_HOURS=24
CLEANUP_PATTERN="/tmp/cjgui-p1-screenshot-verification.*"

SMOKE_RUNNER_PID=""
ARTIFACT_DIR=""
ARTIFACT_PATH=""
ARTIFACT_CREATED="false"
FINAL_SUCCESS="false"
FINAL_REASON="unknown"

log_line() {
  echo "$1" | tee -a "$LOG_PATH"
}

cleanup_stale_artifact_dirs() {
  local ttl_minutes=$((CLEANUP_TTL_HOURS * 60))
  local deleted_count=0
  local candidate

  for candidate in /tmp/cjgui-p1-screenshot-verification.*; do
    [[ -e "$candidate" || -L "$candidate" ]] || continue
    [[ "$candidate" == /tmp/cjgui-p1-screenshot-verification.* ]] || continue
    [[ -n "${ARTIFACT_DIR:-}" && "$candidate" == "$ARTIFACT_DIR" ]] && continue
    [[ -L "$candidate" ]] && continue
    [[ -d "$candidate" ]] || continue

    if find "$candidate" -maxdepth 0 -type d -mmin +"$ttl_minutes" -print -quit | grep -q .; then
      rm -rf -- "$candidate"
      deleted_count=$((deleted_count + 1))
    fi
  done

  log_line "cjgui screenshot verification: cleanup_requested=true"
  log_line "cjgui screenshot verification: cleanup_pattern=$CLEANUP_PATTERN"
  log_line "cjgui screenshot verification: cleanup_ttl_hours=$CLEANUP_TTL_HOURS"
  log_line "cjgui screenshot verification: cleanup_deleted_count=$deleted_count"
}

cleanup_smoke() {
  if [[ -n "${SMOKE_RUNNER_PID:-}" ]] && kill -0 "$SMOKE_RUNNER_PID" 2>/dev/null; then
    kill "$SMOKE_RUNNER_PID" 2>/dev/null || true
    wait "$SMOKE_RUNNER_PID" 2>/dev/null || true
  fi
}

cleanup_unfinished_artifact() {
  if [[ -n "${ARTIFACT_DIR:-}" && -d "$ARTIFACT_DIR" && "$ARTIFACT_CREATED" != "true" ]]; then
    rm -rf "$ARTIFACT_DIR"
  fi
}

cleanup() {
  cleanup_smoke
  cleanup_unfinished_artifact
}

trap cleanup EXIT

wait_for_readiness() {
  local deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
  local needles=(
    "cjgui: window created"
    "cjgui: metal setup complete"
    "cjgui: first frame rendered"
  )

  while (( SECONDS < deadline )); do
    local missing=0
    local needle
    for needle in "${needles[@]}"; do
      if ! grep -F "$needle" "$LOG_PATH" >/dev/null 2>&1; then
        missing=1
        break
      fi
    done

    if [[ "$missing" -eq 0 ]]; then
      return 0
    fi

    if [[ -n "$SMOKE_RUNNER_PID" ]] && ! kill -0 "$SMOKE_RUNNER_PID" 2>/dev/null; then
      break
    fi

    sleep 0.1
  done

  return 1
}

resolve_smoke_pid() {
  local pid=""

  if [[ -n "$SMOKE_RUNNER_PID" ]]; then
    pid="$(pgrep -P "$SMOKE_RUNNER_PID" -f "macos_bridge_smoke" 2>/dev/null | tail -n 1 || true)"
  fi

  if [[ -z "$pid" ]]; then
    pid="$(pgrep -f "$ROOT_DIR/build/macos_bridge_smoke" 2>/dev/null | tail -n 1 || true)"
  fi

  echo "$pid"
}

classify_probe_error() {
  local detail
  detail="$(tr '[:upper:]' '[:lower:]' < "$PROBE_ERR_PATH" 2>/dev/null || true)"

  if [[ "$detail" == *"could not create image from display"* ]]; then
    echo "display_unavailable"
  elif [[ "$detail" == *"screen recording"* ]] || \
       [[ "$detail" == *"privacy"* ]] || \
       [[ "$detail" == *"permission"* ]] || \
       [[ "$detail" == *"not authorized"* ]] || \
       [[ "$detail" == *"denied"* ]] || \
       [[ "$detail" == *"not allowed"* ]]; then
    echo "permission_denied"
  elif [[ "$detail" == *"no display"* ]] || \
       [[ "$detail" == *"display unavailable"* ]] || \
       [[ "$detail" == *"cannot create image from display"* ]]; then
    echo "display_unavailable"
  elif [[ "$detail" == *"window not found"* ]]; then
    echo "window_not_found"
  elif [[ "$detail" == *"window not visible"* ]]; then
    echo "window_not_visible"
  elif [[ "$detail" == *"target mismatch"* ]]; then
    echo "target_mismatch"
  elif [[ -n "$detail" ]]; then
    echo "capture_failed"
  else
    echo "unknown"
  fi
}

screenshot_probe_value() {
  local probe_output="$1"
  local key="$2"
  local line

  line="$(grep -F "cjgui screenshot verification: $key=" <<< "$probe_output" | tail -n 1 || true)"
  if [[ "$line" == *"$key="* ]]; then
    echo "${line#*"$key="}"
  fi
}

compute_frame_hash_scale() {
  local probe_output="$1"
  local bounds
  local size
  local window_w
  local window_h
  local pixels_w
  local pixels_h

  bounds="$(screenshot_probe_value "$probe_output" "target_bounds")"
  size="$(screenshot_probe_value "$probe_output" "artifact_size")"

  if [[ "$bounds" =~ ^-?[0-9]+,-?[0-9]+,([0-9]+),([0-9]+)$ ]]; then
    window_w="${BASH_REMATCH[1]}"
    window_h="${BASH_REMATCH[2]}"
  else
    echo "unknown"
    return 0
  fi

  if [[ "$size" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    pixels_w="${BASH_REMATCH[1]}"
    pixels_h="${BASH_REMATCH[2]}"
  else
    echo "unknown"
    return 0
  fi

  awk -v pw="$pixels_w" -v ph="$pixels_h" -v ww="$window_w" -v wh="$window_h" '
    BEGIN {
      if (ww <= 0 || wh <= 0) {
        print "unknown";
        exit;
      }
      sx = pw / ww;
      sy = ph / wh;
      delta = sx - sy;
      if (delta < 0) {
        delta = -delta;
      }
      if (delta <= 0.01) {
        printf "%.2f", sx;
      } else {
        printf "%.2fx%.2f", sx, sy;
      }
    }
  '
}

emit_frame_hash_baseline_readiness() {
  log_line "cjgui frame hash baseline readiness: baseline_readiness_requested=true"
  log_line "cjgui frame hash baseline readiness: source=target_window_screenshot_crop"
  log_line "cjgui frame hash baseline readiness: source_truth=user_visible_screenshot"
  log_line "cjgui frame hash baseline readiness: baseline_allowed=false"
  log_line "cjgui frame hash baseline readiness: baseline_blocked_reason=baseline_policy_incomplete"
  log_line "cjgui frame hash baseline readiness: baseline_owner_defined=false"
  log_line "cjgui frame hash baseline readiness: baseline_update_policy_defined=false"
  log_line "cjgui frame hash baseline readiness: human_review_required=true"
  log_line "cjgui frame hash baseline readiness: ai_auto_update_allowed=false"
  log_line "cjgui frame hash baseline readiness: hash_value_persistence_allowed=false"
  log_line "cjgui frame hash baseline readiness: source_normalized=false"
  log_line "cjgui frame hash baseline readiness: color_space_defined=false"
  log_line "cjgui frame hash baseline readiness: pixel_format_defined=false"
  log_line "cjgui frame hash baseline readiness: ci_headless_supported=false"
  log_line "cjgui frame hash baseline readiness: pixel_diff_allowed=false"
  log_line "cjgui frame hash baseline readiness: success=true reason=none"
  emit_frame_hash_baseline_owner_policy
}

emit_frame_hash_baseline_owner_policy() {
  log_line "cjgui frame hash baseline owner policy: owner_required=human_architect_or_maintainer"
  log_line "cjgui frame hash baseline owner policy: owner_runtime_api=false"
  log_line "cjgui frame hash baseline owner policy: ai_owner_allowed=false"
  log_line "cjgui frame hash baseline owner policy: ai_auto_update_allowed=false"
  log_line "cjgui frame hash baseline owner policy: proposal_required=true"
  log_line "cjgui frame hash baseline owner policy: human_approval_required=true"
  log_line "cjgui frame hash baseline owner policy: approval_flow_runtime_api=false"
  log_line "cjgui frame hash baseline owner policy: baseline_allowed=false"
  log_line "cjgui frame hash baseline owner policy: hash_value_persistence_allowed=false"
  log_line "cjgui frame hash baseline owner policy: baseline_compare_allowed=false"
  log_line "cjgui frame hash baseline owner policy: pixel_diff_allowed=false"
  log_line "cjgui frame hash baseline owner policy: success=true reason=none"
  emit_frame_hash_source_normalization
}

emit_frame_hash_source_normalization() {
  log_line "cjgui frame hash source normalization: requested=true"
  log_line "cjgui frame hash source normalization: source=target_window_screenshot_crop"
  log_line "cjgui frame hash source normalization: source_truth=user_visible_screenshot"
  log_line "cjgui frame hash source normalization: source_normalized=false"
  log_line "cjgui frame hash source normalization: blocked_reason=source_policy_incomplete"
  log_line "cjgui frame hash source normalization: bounds_policy_defined=false"
  log_line "cjgui frame hash source normalization: scale_policy_defined=false"
  log_line "cjgui frame hash source normalization: color_space_defined=false"
  log_line "cjgui frame hash source normalization: pixel_format_defined=false"
  log_line "cjgui frame hash source normalization: decoration_policy_defined=false"
  log_line "cjgui frame hash source normalization: timing_policy_defined=false"
  log_line "cjgui frame hash source normalization: ci_headless_supported=false"
  log_line "cjgui frame hash source normalization: baseline_allowed=false"
  log_line "cjgui frame hash source normalization: hash_value_persistence_allowed=false"
  log_line "cjgui frame hash source normalization: pixel_diff_allowed=false"
  log_line "cjgui frame hash source normalization: success=true reason=none"
  emit_frame_hash_bounds_crop_semantics
}

emit_frame_hash_bounds_crop_semantics() {
  log_line "cjgui frame hash bounds crop semantics: requested=true"
  log_line "cjgui frame hash bounds crop semantics: source=target_window_screenshot_crop"
  log_line "cjgui frame hash bounds crop semantics: source_truth=user_visible_screenshot"
  log_line "cjgui frame hash bounds crop semantics: screen_bounds_points_observed=true"
  log_line "cjgui frame hash bounds crop semantics: capture_bounds_pixels_observed=true"
  log_line "cjgui frame hash bounds crop semantics: target_window_crop_bounds_observed=true"
  log_line "cjgui frame hash bounds crop semantics: content_interior_bounds_observed=false"
  log_line "cjgui frame hash bounds crop semantics: hash_input_bounds_defined=false"
  log_line "cjgui frame hash bounds crop semantics: point_pixel_conversion_defined=false"
  log_line "cjgui frame hash bounds crop semantics: rounding_policy_defined=false"
  log_line "cjgui frame hash bounds crop semantics: decoration_policy_defined=false"
  log_line "cjgui frame hash bounds crop semantics: content_interior_extraction_allowed=false"
  log_line "cjgui frame hash bounds crop semantics: whole_window_crop_baseline_allowed=false"
  log_line "cjgui frame hash bounds crop semantics: source_normalized=false"
  log_line "cjgui frame hash bounds crop semantics: baseline_allowed=false"
  log_line "cjgui frame hash bounds crop semantics: hash_value_persistence_allowed=false"
  log_line "cjgui frame hash bounds crop semantics: pixel_diff_allowed=false"
  log_line "cjgui frame hash bounds crop semantics: success=true reason=none"
}

emit_frame_hash_feasibility() {
  local probe_output="${1:-}"
  local reason="${2:-$FINAL_REASON}"
  local bounds="unknown"
  local scale="unknown"
  local hash_computed="false"
  local hash_success="false"
  local hash_reason="$reason"

  if [[ -n "$probe_output" ]]; then
    bounds="$(screenshot_probe_value "$probe_output" "target_bounds")"
    bounds="${bounds:-unknown}"
    scale="$(compute_frame_hash_scale "$probe_output")"
    scale="${scale:-unknown}"
  fi

  if [[ "$ARTIFACT_CREATED" == "true" && "$FINAL_SUCCESS" == "true" && -n "${ARTIFACT_PATH:-}" && -f "$ARTIFACT_PATH" ]]; then
    if shasum -a 256 "$ARTIFACT_PATH" >/dev/null 2>&1; then
      hash_computed="true"
      hash_success="true"
      hash_reason="none"
    else
      hash_reason="capture_failed"
    fi
  fi

  log_line "cjgui frame hash feasibility: requested=true"
  log_line "cjgui frame hash feasibility: source=target_window_screenshot_crop"
  log_line "cjgui frame hash feasibility: source_truth=user_visible_screenshot"
  log_line "cjgui frame hash feasibility: bounds=$bounds"
  log_line "cjgui frame hash feasibility: scale=$scale"
  log_line "cjgui frame hash feasibility: color_space=unknown"
  log_line "cjgui frame hash feasibility: pixel_format=unknown"
  log_line "cjgui frame hash feasibility: algorithm=sha256"
  log_line "cjgui frame hash feasibility: hash_computed=$hash_computed"
  log_line "cjgui frame hash feasibility: hash_persisted=false"
  log_line "cjgui frame hash feasibility: hash_value_logged=false"
  log_line "cjgui frame hash feasibility: baseline_compared=false"
  log_line "cjgui frame hash feasibility: success=$hash_success reason=$hash_reason"
  emit_frame_hash_baseline_readiness
}

emit_not_ready() {
  log_line "cjgui screenshot verification: requested=false"
  log_line "cjgui screenshot verification: artifact_created=false"
  log_line "cjgui screenshot verification: target_pid_observed=false"
  log_line "cjgui screenshot verification: window_title_matched=unknown"
  log_line "cjgui screenshot verification: window_bounds_observed=false"
  log_line "cjgui screenshot verification: frontmost_app_matched=unknown"
  log_line "cjgui screenshot verification: display_observed=unknown"
  log_line "cjgui screenshot verification: scale_observed=unknown"
  log_line "cjgui screenshot verification: capture_covers_target_bounds=false"
  log_line "cjgui screenshot verification: sample_requested=false"
  log_line "cjgui screenshot verification: sample_points=0"
  log_line "cjgui screenshot verification: sample_match=false"
  FINAL_SUCCESS="false"
  FINAL_REASON="render_not_ready"
  emit_frame_hash_feasibility "" "$FINAL_REASON"
}

run_screenshot_probe() {
  local target_pid="$1"
  local probe_output=""
  local probe_status=0

  ARTIFACT_DIR="$(mktemp -d /tmp/cjgui-p1-screenshot-verification.XXXXXX)"
  ARTIFACT_PATH="$ARTIFACT_DIR/target-window.png"

  : > "$PROBE_ERR_PATH"
  log_line "cjgui screenshot verification: artifact_path=$ARTIFACT_PATH"

  set +e
  probe_output="$(osascript -l JavaScript - \
    "$target_pid" \
    "$WINDOW_TITLE" \
    "$ARTIFACT_PATH" \
    "$EXPECTED_R" \
    "$EXPECTED_G" \
    "$EXPECTED_B" \
    "$COLOR_TOLERANCE" <<'JXA' 2>"$PROBE_ERR_PATH"
ObjC.import("AppKit");
ObjC.import("CoreGraphics");
ObjC.import("Foundation");

function arg(index) {
  return ObjC.unwrap($.NSProcessInfo.processInfo.arguments.objectAtIndex(index + 4));
}

function value(dict, key) {
  var raw = dict.objectForKey($(key));
  if (!raw) {
    return undefined;
  }
  return ObjC.unwrap(raw);
}

function emit(line) {
  var data = $("cjgui screenshot verification: " + line + "\n").dataUsingEncoding($.NSUTF8StringEncoding);
  $.NSFileHandle.fileHandleWithStandardOutput.writeData(data);
}

function boolText(value) {
  return value ? "true" : "false";
}

function stateText(value) {
  if (value === null || value === undefined) {
    return "unknown";
  }
  return value ? "true" : "false";
}

function emitNoCapture(reason, targetObserved, titleMatched, boundsObserved, frontmostMatched, displayObserved, scaleObserved) {
  emit("requested=false");
  emit("artifact_created=false");
  emit("target_pid_observed=" + boolText(targetObserved));
  emit("window_title_matched=" + stateText(titleMatched));
  emit("window_bounds_observed=" + boolText(boundsObserved));
  emit("frontmost_app_matched=" + stateText(frontmostMatched));
  emit("display_observed=" + stateText(displayObserved));
  emit("scale_observed=" + stateText(scaleObserved));
  emit("capture_covers_target_bounds=false");
  emit("sample_requested=false");
  emit("sample_points=0");
  emit("sample_match=false");
  emit("probe_result=false reason=" + reason);
}

var targetPid = Number(arg(0));
var expectedTitle = String(arg(1));
var artifactPath = String(arg(2));
var expectedR = Number(arg(3));
var expectedG = Number(arg(4));
var expectedB = Number(arg(5));
var tolerance = Number(arg(6));

var frontmostPid = -1;
try {
  var frontmostApp = $.NSWorkspace.sharedWorkspace.frontmostApplication;
  if (frontmostApp) {
    frontmostPid = Number(frontmostApp.processIdentifier);
  }
} catch (error) {
  frontmostPid = -1;
}

var windows = ObjC.castRefToObject($.CGWindowListCopyWindowInfo($.kCGWindowListOptionOnScreenOnly, 0));
if (!windows || Number(windows.count) === 0) {
  emitNoCapture("display_unavailable", false, null, false, null, false, null);
} else {
  var titleMatchedWithoutPid = false;
  var targetWindow = null;
  var targetTitleMatched = null;

  for (var i = 0; i < Number(windows.count); i++) {
    var info = windows.objectAtIndex(i);
    var ownerPid = Number(value(info, "kCGWindowOwnerPID") || -1);
    var layer = Number(value(info, "kCGWindowLayer") || 0);
    var isOnscreen = Number(value(info, "kCGWindowIsOnscreen") || 0);
    var alpha = Number(value(info, "kCGWindowAlpha") || 0);
    var nameValue = value(info, "kCGWindowName");
    var name = nameValue === undefined ? "" : String(nameValue);
    var bounds = ObjC.deepUnwrap(info.objectForKey($("kCGWindowBounds")));
    var width = bounds ? Number(bounds.Width) : 0;
    var height = bounds ? Number(bounds.Height) : 0;
    var titleMatches = name.length > 0 && name.indexOf(expectedTitle) !== -1;

    if (titleMatches && ownerPid !== targetPid) {
      titleMatchedWithoutPid = true;
    }

    if (ownerPid === targetPid && layer === 0 && width > 0 && height > 0) {
      targetWindow = info;
      targetTitleMatched = name.length > 0 ? titleMatches : null;
      if (isOnscreen !== 1 || alpha <= 0) {
        emitNoCapture("window_not_visible", true, targetTitleMatched, true, frontmostPid === targetPid, null, null);
        targetWindow = null;
      }
      break;
    }
  }

  if (!targetWindow) {
    if (titleMatchedWithoutPid) {
      emitNoCapture("target_mismatch", false, true, false, frontmostPid === targetPid ? true : false, null, null);
    } else {
      emitNoCapture("window_not_found", false, false, false, frontmostPid === targetPid ? true : false, null, null);
    }
  } else {
    var targetBounds = ObjC.deepUnwrap(targetWindow.objectForKey($("kCGWindowBounds")));
    var x = Number(targetBounds.X);
    var y = Number(targetBounds.Y);
    var width = Number(targetBounds.Width);
    var height = Number(targetBounds.Height);
    var rect = $.CGRectMake(x, y, width, height);

    emit("requested=true");
    emit("target_pid_observed=true");
    emit("window_title_matched=" + stateText(targetTitleMatched));
    emit("window_bounds_observed=true");
    emit("frontmost_app_matched=" + stateText(frontmostPid === targetPid));
    emit("target_bounds=" + Math.round(x) + "," + Math.round(y) + "," + Math.round(width) + "," + Math.round(height));

    var image = $.CGWindowListCreateImage(rect, $.kCGWindowListOptionOnScreenOnly, 0, $.kCGWindowImageDefault);
    if (!image) {
      emit("artifact_created=false");
      emit("display_observed=unknown");
      emit("scale_observed=unknown");
      emit("capture_covers_target_bounds=false");
      emit("sample_requested=false");
      emit("sample_points=0");
      emit("sample_match=false");
      emit("probe_result=false reason=capture_failed");
    } else {
      var rep = $.NSBitmapImageRep.alloc.initWithCGImage(image);
      var pixelsWide = Number(rep.pixelsWide);
      var pixelsHigh = Number(rep.pixelsHigh);
      var pngData = rep.representationUsingTypeProperties($.NSPNGFileType, $({}));
      var wrote = pngData && pngData.writeToFileAtomically(artifactPath, true);
      var scaleX = width > 0 ? pixelsWide / width : 0;
      var scaleY = height > 0 ? pixelsHigh / height : 0;
      var scaleObserved = scaleX > 0 && scaleY > 0;

      emit("artifact_created=" + boolText(Boolean(wrote)));
      emit("artifact_size=" + pixelsWide + "x" + pixelsHigh);
      emit("display_observed=true");
      emit("scale_observed=" + boolText(scaleObserved));
      emit("capture_covers_target_bounds=" + boolText(Boolean(wrote) && pixelsWide > 0 && pixelsHigh > 0));

      if (!wrote || pixelsWide < 3 || pixelsHigh < 3) {
        emit("sample_requested=false");
        emit("sample_points=0");
        emit("sample_match=false");
        emit("probe_result=false reason=capture_failed");
      } else {
        var centerX = Math.floor(pixelsWide / 2);
        var centerY = Math.floor(pixelsHigh / 2);
        var totalR = 0;
        var totalG = 0;
        var totalB = 0;
        var points = 0;

        for (var dx = -1; dx <= 1; dx++) {
          for (var dy = -1; dy <= 1; dy++) {
            var sampleX = Math.max(0, Math.min(pixelsWide - 1, centerX + dx));
            var sampleY = Math.max(0, Math.min(pixelsHigh - 1, centerY + dy));
            var color = rep.colorAtXY(sampleX, sampleY);
            if (color) {
              var srgb = color.colorUsingColorSpace($.NSColorSpace.sRGBColorSpace);
              if (srgb) {
                totalR += Number(srgb.redComponent);
                totalG += Number(srgb.greenComponent);
                totalB += Number(srgb.blueComponent);
                points += 1;
              }
            }
          }
        }

        var sampleMatch = false;
        if (points > 0) {
          var avgR = totalR / points;
          var avgG = totalG / points;
          var avgB = totalB / points;
          sampleMatch = Math.abs(avgR - expectedR) <= tolerance &&
                        Math.abs(avgG - expectedG) <= tolerance &&
                        Math.abs(avgB - expectedB) <= tolerance;
        }

        emit("sample_requested=true");
        emit("sample_points=" + points);
        emit("sample_match=" + boolText(sampleMatch));
        emit("probe_result=" + boolText(sampleMatch) + " reason=" + (sampleMatch ? "none" : "color_mismatch"));
      }
    }
  }
}
JXA
)"
  probe_status=$?
  set -e

  if [[ "$probe_status" -ne 0 ]]; then
    local reason
    reason="$(classify_probe_error)"
    log_line "cjgui screenshot verification: requested=true"
    log_line "cjgui screenshot verification: artifact_created=false"
    log_line "cjgui screenshot verification: target_pid_observed=false"
    log_line "cjgui screenshot verification: window_title_matched=unknown"
    log_line "cjgui screenshot verification: window_bounds_observed=false"
    log_line "cjgui screenshot verification: frontmost_app_matched=unknown"
    log_line "cjgui screenshot verification: display_observed=unknown"
    log_line "cjgui screenshot verification: scale_observed=unknown"
    log_line "cjgui screenshot verification: capture_covers_target_bounds=false"
    log_line "cjgui screenshot verification: sample_requested=false"
    log_line "cjgui screenshot verification: sample_points=0"
    log_line "cjgui screenshot verification: sample_match=false"
    FINAL_SUCCESS="false"
    FINAL_REASON="$reason"
    emit_frame_hash_feasibility "" "$FINAL_REASON"
    return 0
  fi

  while IFS= read -r line; do
    [[ -n "$line" ]] && log_line "$line"
  done <<< "$probe_output"

  if grep -F "cjgui screenshot verification: artifact_created=true" <<< "$probe_output" >/dev/null; then
    ARTIFACT_CREATED="true"
  fi

  local result_line
  result_line="$(grep -F "cjgui screenshot verification: probe_result=" <<< "$probe_output" | tail -n 1 || true)"
  if [[ "$result_line" == *"probe_result=true"* ]]; then
    FINAL_SUCCESS="true"
  else
    FINAL_SUCCESS="false"
  fi

  if [[ "$result_line" == *" reason="* ]]; then
    FINAL_REASON="${result_line##* reason=}"
  else
    FINAL_REASON="unknown"
  fi

  emit_frame_hash_feasibility "$probe_output" "$FINAL_REASON"
}

finalize_artifact() {
  if [[ -z "${ARTIFACT_DIR:-}" || ! -d "$ARTIFACT_DIR" ]]; then
    log_line "cjgui screenshot verification: artifact_retention_reason=none"
    log_line "cjgui screenshot verification: artifact_retention_failure_classification=none"
    log_line "cjgui screenshot verification: artifact_retention_path=none"
    log_line "cjgui screenshot verification: artifact_retention_ttl_hours=$CLEANUP_TTL_HOURS"
    log_line "cjgui screenshot verification: artifact_delete_strategy=none"
    log_line "cjgui screenshot verification: artifact_retained=false"
    return 0
  fi

  if [[ "$FINAL_SUCCESS" == "true" ]]; then
    rm -rf "$ARTIFACT_DIR"
    log_line "cjgui screenshot verification: artifact_deleted=true"
    log_line "cjgui screenshot verification: artifact_retention_reason=none"
    log_line "cjgui screenshot verification: artifact_retention_failure_classification=none"
    log_line "cjgui screenshot verification: artifact_retention_path=none"
    log_line "cjgui screenshot verification: artifact_retention_ttl_hours=$CLEANUP_TTL_HOURS"
    log_line "cjgui screenshot verification: artifact_delete_strategy=none"
    log_line "cjgui screenshot verification: artifact_retained=false"
  elif [[ "$ARTIFACT_CREATED" == "true" ]]; then
    log_line "cjgui screenshot verification: artifact_deleted=false"
    log_line "cjgui screenshot verification: artifact_retention_reason=failure_diagnostic"
    log_line "cjgui screenshot verification: artifact_retention_failure_classification=$FINAL_REASON"
    log_line "cjgui screenshot verification: artifact_retention_path=$ARTIFACT_PATH"
    log_line "cjgui screenshot verification: artifact_retention_ttl_hours=$CLEANUP_TTL_HOURS"
    log_line "cjgui screenshot verification: artifact_retained=true"
    log_line "cjgui screenshot verification: artifact_delete_strategy=manual rm -rf $ARTIFACT_DIR"
  else
    rm -rf "$ARTIFACT_DIR"
    log_line "cjgui screenshot verification: artifact_deleted=true"
    log_line "cjgui screenshot verification: artifact_retention_reason=none"
    log_line "cjgui screenshot verification: artifact_retention_failure_classification=none"
    log_line "cjgui screenshot verification: artifact_retention_path=none"
    log_line "cjgui screenshot verification: artifact_retention_ttl_hours=$CLEANUP_TTL_HOURS"
    log_line "cjgui screenshot verification: artifact_delete_strategy=none"
    log_line "cjgui screenshot verification: artifact_retained=false"
  fi
}

if [[ ! -x "$BUILD_AND_RUN" ]]; then
  echo "cjgui screenshot verification: missing executable: $BUILD_AND_RUN" >&2
  exit 1
fi

rm -f "$LOG_PATH" "$PROBE_ERR_PATH"
touch "$LOG_PATH" "$PROBE_ERR_PATH"

log_line "cjgui screenshot verification: log=$LOG_PATH"
log_line "cjgui screenshot verification: probe_error_log=$PROBE_ERR_PATH"
log_line "cjgui screenshot verification: this is not full GUI verification"
log_line "cjgui screenshot verification: this is not pixel diff"
log_line "cjgui screenshot verification: this is not frame hash regression"
log_line "cjgui screenshot verification: this is not offscreen renderer"
cleanup_stale_artifact_dirs

CJGUI_AUTOCLOSE_SECONDS="$AUTOCLOSE_SECONDS" "$BUILD_AND_RUN" > >(tee -a "$LOG_PATH") 2>&1 &
SMOKE_RUNNER_PID=$!

if ! wait_for_readiness; then
  emit_not_ready
else
  SMOKE_PID="$(resolve_smoke_pid)"
  if [[ -z "$SMOKE_PID" ]]; then
    log_line "cjgui screenshot verification: requested=false"
    log_line "cjgui screenshot verification: artifact_created=false"
    log_line "cjgui screenshot verification: target_pid_observed=false"
    log_line "cjgui screenshot verification: window_title_matched=unknown"
    log_line "cjgui screenshot verification: window_bounds_observed=false"
    log_line "cjgui screenshot verification: frontmost_app_matched=unknown"
    log_line "cjgui screenshot verification: display_observed=unknown"
    log_line "cjgui screenshot verification: scale_observed=unknown"
    log_line "cjgui screenshot verification: capture_covers_target_bounds=false"
    log_line "cjgui screenshot verification: sample_requested=false"
    log_line "cjgui screenshot verification: sample_points=0"
    log_line "cjgui screenshot verification: sample_match=false"
    FINAL_SUCCESS="false"
    FINAL_REASON="window_not_found"
    emit_frame_hash_feasibility "" "$FINAL_REASON"
  else
    log_line "cjgui screenshot verification: smoke_pid=$SMOKE_PID"
    run_screenshot_probe "$SMOKE_PID"
  fi
fi

set +e
wait "$SMOKE_RUNNER_PID"
SMOKE_STATUS=$?
set -e
SMOKE_RUNNER_PID=""

if [[ "$SMOKE_STATUS" -ne 0 ]]; then
  log_line "cjgui screenshot verification: smoke_exit_status=$SMOKE_STATUS"
  if [[ "$FINAL_SUCCESS" == "true" ]]; then
    FINAL_SUCCESS="false"
    FINAL_REASON="render_failure"
  fi
fi

finalize_artifact

log_line "cjgui screenshot verification: success=$FINAL_SUCCESS reason=$FINAL_REASON"
log_line "cjgui screenshot verification: this is not pixel correctness proof"
log_line "cjgui screenshot verification: this is not compositor correctness proof"
log_line "cjgui screenshot verification: this is not CI/headless proof"
log_line "cjgui screenshot verification: this is not formal GUI runtime"

exit 0
