#!/usr/bin/env python3
"""Verify a handwritten scroll/nav route on an already-running normal OHOS HAP.

The caller owns the app, target, and forward. This verifier creates/removes no
forward and never installs, starts, stops, builds, or clears logs. It checks an
initial button-origin swipe for zero owner writes, invokes the accepted
handwritten navigation button, reads fresh post-reveal editor geometry from this
PID's diagnostic/accepted log, selects all through the system menu, replaces
real editor text, submits, and requires an exact public GET_CONTEXT readback.

Supply identity, swipe points, the XComponent screen origin, and navigation
point explicitly for the initial swipe. After that swipe, navigation and its
hand-scroll viewport must be reported by fresh same-PID accepted bounds. A
clipped navigation target is restored with bounded reverse swipes inside the
viewport's visible intersection, then clicked using its newly accepted bounds.
The editor point is derived after navigation from fresh same-PID editor bounds.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import shlex
import sys
import time
import uuid

import verify_current_normal_selection_replace as selection
import verify_normal_generated_consumption as normal
from ohos_transport_probe_lib import BoundedExchange


def hash_file(path: Path) -> str:
    digest = hashlib.sha256()
    with Path(path).open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def nav_point_from_accepted_log(raw: str, label: str,
                                xcomponent_origin: tuple[int, int]) -> tuple[int, int]:
    """Map one accepted label to its matching visible node-rect center."""
    ids = {int(match.group(1)) for line in raw.splitlines()
           if (match := re.search(r"accepted node=(-?\d+).*?label=(.*?) value=", line))
           and match.group(2) == label}
    if len(ids) != 1:
        raise ValueError(f"accepted label {label!r} is absent or ambiguous")
    node_id = next(iter(ids))
    rects = []
    pattern = re.compile(
        r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+) "
        r"clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")
    for line in raw.splitlines():
        match = pattern.search(line)
        if match and int(match.group(1)) == node_id:
            _, x, y, width, height, clip_x, clip_y, clip_width, clip_height = map(
                int, match.groups())
            if width > 0 and height > 0 and clip_width > 0 and clip_height > 0:
                left, top = max(x, clip_x), max(y, clip_y)
                right = min(x + width, clip_x + clip_width)
                bottom = min(y + height, clip_y + clip_height)
                if right > left and bottom > top:
                    rects.append((left, top, right, bottom))
    if not rects:
        raise ValueError(f"no accepted bounds for node {node_id} in the supplied log")
    # Repeated accepted frames are expected. Conflicting live geometry is not.
    if len(set(rects)) != 1:
        raise ValueError(f"accepted bounds for node {node_id} are ambiguous")
    return _point_from_clipped_rect(rects[0], xcomponent_origin)


def _point_from_clipped_rect(rect: tuple[int, int, int, int],
                             xcomponent_origin: tuple[int, int]) -> tuple[int, int]:
    left, top, right, bottom = rect
    if right <= left or bottom <= top:
        raise ValueError("accepted target has no visible clip intersection")
    return _check_point(xcomponent_origin[0] + (left + right) // 2,
                        xcomponent_origin[1] + (top + bottom) // 2)


def _parse_touch_geometry(row: str, record_name: str, label: str) -> dict[str, object] | None:
    pattern = re.compile(
        re.escape(record_name) + r" label=(\S+) x=(-?\d+) y=(-?\d+) "
        r"w=(\d+) h=(\d+) clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")
    match = pattern.search(row)
    if match is None or match.group(1) != label:
        return None
    x, y, width, height, clip_x, clip_y, clip_width, clip_height = map(
        int, match.groups()[1:])
    # Zero-height accepted clips are the normal diagnostic representation for
    # a completely clipped target; geometry consumers decide whether that is
    # valid for their particular proof.
    invalid_clip_height = clip_height < 0
    if min(width, height, clip_width) <= 0 or invalid_clip_height:
        raise ValueError(f"fresh {record_name} has non-positive bounds or clip")
    return {"x": x, "y": y, "w": width, "h": height,
            "clip": (clip_x, clip_y, clip_width, clip_height)}


def _hilog_timestamp_key(row: str) -> tuple[int, int, int, int, int, int] | None:
    match = re.match(r"^(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?\s", row)
    if match is None:
        return None
    month, day, hour, minute, second = map(int, match.groups()[:5])
    fractional = (match.group(6) or "0")[:9].ljust(9, "0")
    return month, day, hour, minute, second, int(fractional)


def _hilog_pid(row: str) -> str | None:
    match = re.match(r"^\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?\s+(\d+)\s+\d+\s", row)
    return match.group(1) if match else None


def fresh_hilog_rows(before: list[str], after: list[str]) -> list[str]:
    """Prefer exact row overlap; on ring rotation prove same-PID time advance.

    A rotated snapshot is usable only when every row is parseable, belongs to
    the same PID as the prior snapshot, is chronologically ordered, and is
    strictly newer than the maximum timestamp in that prior state.
    """
    if not before or not after:
        raise ValueError("rotated hilog freshness needs non-empty prior and current snapshots")
    try:
        before_pids = {_hilog_pid(row) for row in before}
        after_pids = {_hilog_pid(row) for row in after}
        if None in before_pids or None in after_pids or len(before_pids) != 1 or len(after_pids) != 1:
            raise ValueError("rotated hilog freshness requires parseable single-PID rows")
        if before_pids != after_pids:
            raise ValueError("rotated hilog freshness PID changed")
        # Preserve the normal, stronger sequence-overlap proof whenever it is
        # still available.
        return selection.fresh_rows(before, after)
    except AssertionError as exc:
        if "baseline missing/rotated" not in str(exc):
            raise

    before_times = [_hilog_timestamp_key(row) for row in before]
    after_times = [_hilog_timestamp_key(row) for row in after]
    if any(timestamp is None for timestamp in before_times + after_times):
        raise ValueError("rotated hilog freshness rejected an unparseable device timestamp")
    prior_max = max(before_times)
    ordered_after = [timestamp for timestamp in after_times if timestamp is not None]
    if any(timestamp <= prior_max for timestamp in ordered_after):
        raise ValueError(
            "rotated hilog freshness requires every current row strictly newer than prior maximum")
    if any(current < previous for previous, current in zip(ordered_after, ordered_after[1:])):
        raise ValueError("rotated hilog freshness rejected device clock rollback or reordered rows")
    return after


def gesture_terminal_fence(before: list[str], after: list[str]
                           ) -> dict[str, object] | None:
    """Identify the one fresh raw terminal event and its same-epoch BEGIN."""
    try:
        fresh = fresh_hilog_rows(before, after)
    except (AssertionError, ValueError) as exc:
        raise ValueError(f"same-PID touch event freshness cannot be proven: {exc}") from exc
    touch_pattern = re.compile(r"raw touch action=(\d+) .*?\bep=(\d+)")
    touches = []
    for row in fresh:
        match = touch_pattern.search(row)
        if match is None:
            continue
        action, epoch = int(match.group(1)), int(match.group(2))
        if action in (37, 39, 40):
            timestamp = _hilog_timestamp_key(row)
            if timestamp is None:
                raise ValueError("fresh raw touch BEGIN/END/CANCEL lacks a parseable hilog timestamp")
            touches.append({"action": action, "epoch": epoch,
                            "timestamp": timestamp, "row": row})
    terminals = [row for row in touches if row["action"] in (39, 40)]
    if not terminals:
        return None
    if len(terminals) != 1:
        raise ValueError(f"expected one fresh raw touch END/CANCEL for this gesture, found {len(terminals)}")
    terminal = terminals[0]
    if len(touches) != 2:
        raise ValueError("fresh touch stream must contain exactly one BEGIN and one END/CANCEL")
    begins = [row for row in touches
              if row["action"] == 37 and row["epoch"] == terminal["epoch"]]
    if len(begins) != 1 or begins[0]["timestamp"] >= terminal["timestamp"]:
        raise ValueError("fresh raw terminal has no unique earlier BEGIN from the same gesture epoch")
    timestamp = terminal["timestamp"]
    timestamp_text = (f"{timestamp[0]:02d}-{timestamp[1]:02d} "
                      f"{timestamp[2]:02d}:{timestamp[3]:02d}:{timestamp[4]:02d}."
                      f"{timestamp[5]:09d}")
    return {"action": terminal["action"], "epoch": terminal["epoch"],
            "timestamp": timestamp,
            "timestamp_text": timestamp_text,
            "row": terminal["row"]}


def fresh_nav_viewport_geometry(before: list[str], after: list[str],
                                nav_label: str, viewport_label: str,
                                strictly_after_timestamp: tuple[int, int, int, int, int, int]
                                | None = None
                                ) -> tuple[dict[str, object], dict[str, object]]:
    """Read one fresh nav and viewport geometry pair from current-PID log rows."""
    try:
        fresh = fresh_hilog_rows(before, after)
    except (AssertionError, ValueError) as exc:
        raise ValueError(f"fresh nav/viewport geometry cannot be proven: {exc}") from exc
    records = (
        ("h_touch_nav_bounds", nav_label),
        ("h_touch_hand_viewport_bounds", viewport_label),
    )
    parsed: list[dict[str, object]] = []
    for record_name, label in records:
        candidates = []
        malformed = False
        for row in fresh:
            if record_name not in row:
                continue
            label_match = re.search(re.escape(record_name) + r" label=(\S+)", row)
            if label_match is not None and label_match.group(1) != label:
                continue
            if strictly_after_timestamp is not None:
                row_timestamp = _hilog_timestamp_key(row)
                if row_timestamp is None:
                    raise ValueError(f"fresh {record_name} lacks a parseable hilog timestamp")
                if row_timestamp <= strictly_after_timestamp:
                    continue
            geometry = _parse_touch_geometry(row, record_name, label)
            if geometry is None:
                malformed = True
            else:
                candidates.append(geometry)
        unique = {json.dumps(item, sort_keys=True) for item in candidates}
        if malformed or len(unique) != 1:
            raise ValueError(
                f"expected exactly one fresh labeled {record_name} geometry for {label!r}; "
                f"found {len(unique)}" if not malformed else
                f"fresh {record_name} is missing the matching label or full clip")
        parsed.append(json.loads(next(iter(unique))))
    nav, viewport = parsed
    if _visible_rect(viewport) is None:
        raise ValueError("fresh hand-scroll viewport has no visible clip intersection")
    return nav, viewport


def _visible_rect(geometry: dict[str, object]) -> tuple[int, int, int, int] | None:
    x, y, width, height = (int(geometry[key]) for key in ("x", "y", "w", "h"))
    clip_x, clip_y, clip_width, clip_height = geometry["clip"]
    left, top = max(x, clip_x), max(y, clip_y)
    right = min(x + width, clip_x + clip_width)
    bottom = min(y + height, clip_y + clip_height)
    return (left, top, right, bottom) if right > left and bottom > top else None


def nav_screen_point(nav: dict[str, object], xcomponent_origin: tuple[int, int],
                     viewport: dict[str, object] | None = None) -> tuple[int, int]:
    """A nav click is valid only when its whole accepted rect is visible."""
    nav_rect = (int(nav["x"]), int(nav["y"]),
                int(nav["x"]) + int(nav["w"]), int(nav["y"]) + int(nav["h"]))
    clip = nav["clip"]
    clip_rect = (clip[0], clip[1], clip[0] + clip[2], clip[1] + clip[3])
    if not _rect_contains(clip_rect, nav_rect):
        raise ValueError("navigation target is not fully inside its accepted clip")
    if viewport is not None:
        visible_viewport = _visible_rect(viewport)
        if visible_viewport is None or not _rect_contains(visible_viewport, nav_rect):
            raise ValueError("navigation target is not fully inside the visible hand viewport clip")
    return _point_from_clipped_rect(nav_rect, xcomponent_origin)


def _rect_contains(outer: tuple[int, int, int, int],
                   inner: tuple[int, int, int, int]) -> bool:
    return outer[0] <= inner[0] and outer[1] <= inner[1] \
        and inner[2] <= outer[2] and inner[3] <= outer[3]


def viewport_restore_swipe(nav: dict[str, object], viewport: dict[str, object],
                           xcomponent_origin: tuple[int, int],
                           edge_margin: int = 1) -> tuple[int, int, int, int]:
    """Return a reverse vertical swipe wholly inside the current visible viewport."""
    nav_rect = (int(nav["x"]), int(nav["y"]),
                int(nav["x"]) + int(nav["w"]), int(nav["y"]) + int(nav["h"]))
    nav_clip = nav["clip"]
    clip_rect = (nav_clip[0], nav_clip[1], nav_clip[0] + nav_clip[2],
                 nav_clip[1] + nav_clip[3])
    if nav_rect[0] < clip_rect[0] or nav_rect[2] > clip_rect[2]:
        raise ValueError("navigation target is horizontally outside its accepted clip")
    view = _visible_rect(viewport)
    if view is None:
        raise ValueError("fresh hand-scroll viewport has no visible clip intersection")
    if view[3] - view[1] <= 2 * edge_margin + 1:
        raise ValueError("visible hand viewport is too small for a safe reverse swipe")
    if nav_rect[0] < view[0] or nav_rect[2] > view[2]:
        raise ValueError("navigation target is horizontally outside the visible hand viewport")
    if nav_rect[1] < clip_rect[1]:
        wanted_delta = clip_rect[1] - nav_rect[1] + edge_margin
    elif nav_rect[3] > clip_rect[3]:
        wanted_delta = clip_rect[3] - nav_rect[3] - edge_margin
    else:
        # The accepted clip is clear but the viewport itself still clips the nav.
        if nav_rect[1] < view[1]:
            wanted_delta = view[1] - nav_rect[1] + edge_margin
        elif nav_rect[3] > view[3]:
            wanted_delta = view[3] - nav_rect[3] - edge_margin
        else:
            raise ValueError("navigation target is already fully visible")
    inset = min(edge_margin, max(0, (view[3] - view[1] - 1) // 4))
    start_y = (view[1] + view[3]) // 2
    low, high = view[1] + inset, view[3] - inset
    if low >= high:
        raise ValueError("visible hand viewport is too small for a safe reverse swipe")
    end_y = max(low, min(high, start_y + wanted_delta))
    if end_y == start_y:
        raise ValueError("visible hand viewport cannot make progress restoring navigation")
    x = (view[0] + view[2]) // 2 + xcomponent_origin[0]
    return (_check_point(x, start_y + xcomponent_origin[1])[0],
            _check_point(x, start_y + xcomponent_origin[1])[1],
            _check_point(x, end_y + xcomponent_origin[1])[0],
            _check_point(x, end_y + xcomponent_origin[1])[1])


def nav_offset_to_initial_y(nav: dict[str, object], viewport: dict[str, object],
                            initial_screen_point: tuple[int, int],
                            xcomponent_origin: tuple[int, int],
                            tolerance: int = 12) -> int:
    """Return the vertical scroll delta needed to restore the initial nav offset.

    The initial point is the accepted nav center captured before the first
    gesture. Reject it if it cannot describe this nav inside the current
    viewport; otherwise use it as the baseline even when the nav is already
    clickable at a different scroll offset.
    """
    view = _visible_rect(viewport)
    if view is None:
        raise ValueError("fresh hand-scroll viewport has no visible clip intersection")
    if view[3] - view[1] <= 3:
        raise ValueError("visible hand viewport is too small for a safe offset restore swipe")
    nav_x, nav_y = (int(nav[key]) for key in ("x", "y"))
    nav_width, nav_height = (int(nav[key]) for key in ("w", "h"))
    target_x = initial_screen_point[0] - xcomponent_origin[0]
    target_y = initial_screen_point[1] - xcomponent_origin[1]
    current_center_x = nav_x + nav_width // 2
    current_center_y = nav_y + nav_height // 2
    if abs(current_center_x - target_x) > max(4, nav_width // 4):
        raise ValueError("initial navigation point is horizontally inconsistent with current nav")
    target_rect = (target_x - nav_width // 2, target_y - nav_height // 2,
                   target_x + (nav_width + 1) // 2, target_y + (nav_height + 1) // 2)
    if not _rect_contains(view, target_rect):
        raise ValueError("initial navigation point is outside the visible hand viewport")
    delta = target_y - current_center_y
    return 0 if abs(delta) <= tolerance else delta


def viewport_scroll_delta_swipe(delta_y: int, viewport: dict[str, object],
                                xcomponent_origin: tuple[int, int],
                                edge_margin: int = 1) -> tuple[int, int, int, int]:
    """Return a bounded vertical finger swipe inside the accepted viewport."""
    if delta_y == 0:
        raise ValueError("navigation is already at the initial scroll offset")
    view = _visible_rect(viewport)
    if view is None:
        raise ValueError("fresh hand-scroll viewport has no visible clip intersection")
    if view[3] - view[1] <= 2 * edge_margin + 1:
        raise ValueError("visible hand viewport is too small for a safe offset restore swipe")
    inset = min(edge_margin, max(0, (view[3] - view[1] - 1) // 4))
    start_y = (view[1] + view[3]) // 2
    low, high = view[1] + inset, view[3] - inset
    if low >= high:
        raise ValueError("visible hand viewport is too small for a safe offset restore swipe")
    end_y = max(low, min(high, start_y + delta_y))
    if end_y == start_y:
        raise ValueError("visible hand viewport cannot make progress restoring initial offset")
    x = (view[0] + view[2]) // 2 + xcomponent_origin[0]
    return (_check_point(x, start_y + xcomponent_origin[1])[0],
            _check_point(x, start_y + xcomponent_origin[1])[1],
            _check_point(x, end_y + xcomponent_origin[1])[0],
            _check_point(x, end_y + xcomponent_origin[1])[1])


def editor_visible_in_fenced_geometry(rows: list[str], label: str,
                                      viewport: dict[str, object],
                                      strictly_after_timestamp
                                      : tuple[int, int, int, int, int, int]
                                      ) -> bool | None:
    """Return whether the editor intersects the viewport in fresh post-terminal logs."""
    pattern = re.compile(
        r"h_touch_note_bounds label=(\S+) x=(-?\d+) y=(-?\d+) "
        r"w=(\d+) h=(\d+) clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")
    geometries = []
    for row_index, row in enumerate(rows):
        if "h_touch_note_bounds" not in row:
            continue
        match = pattern.search(row)
        if match is None:
            raise ValueError("fresh editor diagnostic lacks label or full clip geometry")
        if match.group(1) != label:
            continue
        row_timestamp = _hilog_timestamp_key(row)
        if row_timestamp is None:
            raise ValueError("fresh editor geometry lacks a parseable hilog timestamp")
        if row_timestamp <= strictly_after_timestamp:
            continue
        x, y, width, height, clip_x, clip_y, clip_width, clip_height = map(
            int, match.groups()[1:])
        if min(width, height) <= 0 or clip_width < 0 or clip_height < 0:
            raise ValueError("fresh editor geometry has invalid bounds or clip")
        geometries.append((x, y, width, height, clip_x, clip_y, clip_width, clip_height))
    unique = set(geometries)
    if not unique:
        return None
    if len(unique) != 1:
        raise ValueError("fresh editor bounds are ambiguous after scroll restoration")
    x, y, width, height, clip_x, clip_y, clip_width, clip_height = next(iter(unique))
    view = _visible_rect(viewport)
    if view is None:
        raise ValueError("fresh hand-scroll viewport has no visible clip intersection")
    intersection = (max(x, clip_x, view[0]), max(y, clip_y, view[1]),
                    min(x + width, clip_x + clip_width, view[2]),
                    min(y + height, clip_y + clip_height, view[3]))
    return intersection[2] > intersection[0] and intersection[3] > intersection[1]


def poll_editor_visible_in_fenced_geometry(initial_rows: list[str], label: str,
                                           viewport: dict[str, object], fence,
                                           capture, *, timeout_seconds: float,
                                           poll_interval_seconds: float = 0.25,
                                           pause=time.sleep
                                           ) -> tuple[bool | None, list[str], int]:
    """Wait for the app's clipped editor diagnostic after the gesture terminal.

    The renderer can publish accepted navigation geometry before the app emits
    its editor diagnostic for that same settled scene. Only a row after the
    terminal is eligible; an old visible editor cannot satisfy this gate.
    """
    if timeout_seconds <= 0 or poll_interval_seconds <= 0:
        raise ValueError("editor geometry polling timeout and interval must be positive")
    deadline = time.monotonic() + timeout_seconds
    rows = initial_rows
    polls = 1
    while True:
        visible = editor_visible_in_fenced_geometry(rows, label, viewport, fence)
        if visible is not None:
            return visible, rows, polls
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return None, rows, polls
        pause(min(poll_interval_seconds, remaining))
        rows = capture()
        polls += 1


def field_point_from_fresh_logs(before: list[str], after: list[str], label: str,
                                xcomponent_origin: tuple[int, int]) -> tuple[int, int]:
    """Resolve the editor point only from fresh current-PID post-reveal geometry."""
    fresh = fresh_hilog_rows(before, after)
    diag = re.compile(
        r"h_touch_note_bounds(?: label=(\S+))? x=(-?\d+) y=(-?\d+) "
        r"w=(\d+) h=(\d+) clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")
    rects = []
    unbound_diagnostics = []
    for row in fresh:
        if "h_touch_note_bounds" not in row:
            continue
        match = diag.search(row)
        if match is None or match.group(1) != label:
            unbound_diagnostics.append(row)
            continue
        x, y, width, height, clip_x, clip_y, clip_width, clip_height = map(
            int, match.groups()[1:])
        if min(width, height, clip_width, clip_height) <= 0:
            continue
        left, top = max(x, clip_x), max(y, clip_y)
        right, bottom = min(x + width, clip_x + clip_width), min(y + height, clip_y + clip_height)
        if right > left and bottom > top:
            rects.append((left, top, right, bottom))
    if rects:
        if len(set(rects)) != 1:
            raise ValueError("fresh editor bounds are ambiguous")
        return _point_from_clipped_rect(rects[0], xcomponent_origin)
    if unbound_diagnostics:
        raise ValueError("fresh h_touch_note_bounds must include the matching label and full clip")
    # The same accepted label/node-rect form is also supported. Since only the
    # fresh post-nav rows are passed here, stale pre-reveal rectangles cannot win.
    return nav_point_from_accepted_log("\n".join(fresh), label, xcomponent_origin)


def field_text_hit_point_from_fresh_logs(before: list[str], after: list[str], label: str,
                                         xcomponent_origin: tuple[int, int],
                                         left_inset: int = 52) -> tuple[int, int]:
    """Place long-press over the leading text glyph, inside fresh clipped bounds."""
    if left_inset < 0:
        raise ValueError("text hit inset must be non-negative")
    fresh = fresh_hilog_rows(before, after)
    diag = re.compile(
        r"h_touch_note_bounds(?: label=(\S+))? x=(-?\d+) y=(-?\d+) "
        r"w=(\d+) h=(\d+) clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")
    geometries = []
    malformed = False
    for row in fresh:
        if "h_touch_note_bounds" not in row:
            continue
        match = diag.search(row)
        if match is None or match.group(1) != label:
            malformed = True
            continue
        x, y, width, height, clip_x, clip_y, clip_width, clip_height = map(
            int, match.groups()[1:])
        if min(width, height, clip_width, clip_height) <= 0:
            continue
        visible = (max(x, clip_x), max(y, clip_y),
                   min(x + width, clip_x + clip_width),
                   min(y + height, clip_y + clip_height))
        if visible[2] > visible[0] and visible[3] > visible[1]:
            geometries.append((x, y, width, height, visible))
    if not geometries:
        if malformed:
            raise ValueError("fresh h_touch_note_bounds must include matching label and full clip")
        raise ValueError("fresh clipped editor geometry is required for a text hit point")
    unique = set(geometries)
    if len(unique) != 1:
        raise ValueError("fresh editor text hit bounds are ambiguous")
    x, _y, _width, _height, visible = next(iter(unique))
    hit_x = x + left_inset
    if not visible[0] <= hit_x < visible[2]:
        raise ValueError("editor leading text hit is outside the current accepted clip")
    hit_y = (visible[1] + visible[3]) // 2
    return _check_point(xcomponent_origin[0] + hit_x,
                        xcomponent_origin[1] + hit_y)


def utf16_code_unit_length(text: str) -> int:
    return len(text.encode("utf-16-le")) // 2


def public_full_window_selection(raw: str, expected_length: int
                                 ) -> tuple[str, tuple[int, int]]:
    """Validate the public WINDOW_SELECTION identity and full UTF-16 range."""
    lines = raw.splitlines()
    if "KIND WINDOW_INTERACTION" not in lines:
        raise ValueError("public GET_WINDOW_INTERACTION returned the wrong response kind")
    states = [line.split(maxsplit=1)[1] for line in lines
              if line.startswith("WINDOW_FOCUS_STATE ")]
    focuses = [line.split(maxsplit=1)[1] for line in lines
               if line.startswith("WINDOW_FOCUS ")]
    units = [line.split(maxsplit=1)[1] for line in lines
             if line.startswith("WINDOW_SELECTION_POSITION_UNIT ")]
    selections = [line.split(maxsplit=1)[1] for line in lines
                  if line.startswith("WINDOW_SELECTION ")]
    if states != ["valid"] or len(focuses) != 1 or not focuses[0] or units != ["UTF16_CODE_UNIT"]:
        raise ValueError("public window focus or UTF-16 selection identity is unavailable")
    if len(selections) != 1:
        raise ValueError("public WINDOW_SELECTION is absent or ambiguous")
    tokens = selections[0].split()
    if len(tokens) != 3 or not tokens[1].isdigit() or not tokens[2].isdigit():
        raise ValueError("public WINDOW_SELECTION is malformed")
    control, start, end = tokens[0], int(tokens[1]), int(tokens[2])
    if control != focuses[0]:
        raise ValueError("public WINDOW_SELECTION control differs from focused control")
    if (start, end) != (0, expected_length) or end <= start:
        raise ValueError(
            f"public WINDOW_SELECTION must cover full non-empty UTF-16 range [0,{expected_length})")
    return control, (start, end)


def _read_public_full_window_selection(exchange, args, out: Path, label: str,
                                       expected_length: int
                                       ) -> tuple[str, tuple[int, int]]:
    _, raw = exchange.exchange_strict(
        [f"PROTOCOL {selection.PROTOCOL}", f"AUTH {args.auth}", "GET_WINDOW_INTERACTION"], 8)
    (out / f"window_interaction_{label}.raw.txt").write_text(raw, encoding="utf-8")
    return public_full_window_selection(raw, expected_length)


def _fresh_full_ime_selection(before: list[str], after: list[str], pid: str, mount: str,
                              expected_length: int) -> tuple[int, int]:
    fresh = fresh_hilog_rows(
        selection.app_rows("\n".join(before), pid),
        selection.app_rows("\n".join(after), pid))
    observed_ranges = []
    pattern = re.compile(r"ime select \[(\d+),(\d+)\) rc=0 mount="
                         + re.escape(mount) + r"$")
    for row in fresh:
        match = pattern.search(row)
        if match:
            observed_ranges.append((int(match.group(1)), int(match.group(2))))
    if not observed_ranges or observed_ranges[-1][1] <= observed_ranges[-1][0]:
        raise ValueError("no fresh nonempty selection from current PID/mount IME")
    observed = observed_ranges[-1]
    expected = (0, expected_length)
    if observed != expected or expected_length <= 0:
        raise ValueError(
            f"same-PID/mount IME selection {observed!r} does not cover full non-empty "
            f"UTF-16 owner range {expected!r}")
    return observed


def _check_point(x: int, y: int) -> tuple[int, int]:
    if not (0 <= x < 5000 and 0 <= y < 5000):
        raise ValueError(f"screen point out of bounds: {(x, y)!r}")
    return x, y


def resolve_nav_point(args: argparse.Namespace) -> tuple[int, int, str]:
    if args.nav_x is not None or args.nav_y is not None:
        if args.nav_x is None or args.nav_y is None or args.accepted_bounds_log:
            raise ValueError("provide either both --nav-x/--nav-y or --accepted-bounds-log")
        x, y = _check_point(args.nav_x, args.nav_y)
        return x, y, "caller_screen_point"
    if not args.accepted_bounds_log or args.xcomponent_origin_x is None or args.xcomponent_origin_y is None:
        raise ValueError("accepted bounds mode requires a log and both XComponent origin coordinates")
    raw = Path(args.accepted_bounds_log).read_text(encoding="utf-8")
    x, y = nav_point_from_accepted_log(
        raw, args.nav_label, (args.xcomponent_origin_x, args.xcomponent_origin_y))
    return x, y, "accepted_bounds_log"


class Hdc:
    def __init__(self, binary: str, target: str):
        self.base = selection.Hdc(binary, target)

    @property
    def commands(self):
        return self.base.records

    def listing(self) -> str:
        return self.base.run("fport", "ls", global_list=True).stdout

    def pidof(self, bundle: str) -> str:
        return self.base.shell(f"pidof {bundle}")

    def shell(self, command: str, *, timeout: int = 45) -> str:
        return self.base.shell(command, timeout=timeout)

    def pull(self, remote: str, local: Path) -> None:
        self.base.run("file", "recv", remote, str(local), timeout=45)


def _owner(exchange, args, out: Path, label: str) -> dict[str, object]:
    _, raw = exchange.exchange_strict(
        [f"PROTOCOL {selection.PROTOCOL}", f"AUTH {args.auth}", "GET_CONTEXT 0"], 8)
    state = selection.parse_owner(raw, args.resource_id, args.field)
    with (out / f"owner_{label}.txt").open("x", encoding="utf-8") as stream:
        stream.write(raw + "\n")
    return state


def _capture_hilog(hdc, out: Path, label: str, pid: str,
                   timeout: int = 45) -> list[str]:
    raw = hdc.shell("hilog -x 2>/dev/null | grep -aE 'CjguiApp|CjguiRenderer|CjguiHost|CjguiCore'",
                    timeout=timeout)
    (out / f"hilog_{label}.txt").write_text(raw, encoding="utf-8")
    rows = _pid_hilog_rows(raw, pid)
    if not rows:
        raise ValueError(f"no current-PID CJGUI component log rows at {label}")
    return rows


def poll_fresh_nav_viewport_geometry(hdc, out: Path, before: list[str],
                                     label: str, pid: str, nav_label: str,
                                     viewport_label: str, *, timeout_seconds: float = 8.0,
                                     poll_interval_seconds: float = 0.5,
                                     pause=time.sleep
                                     ) -> tuple[dict[str, object], dict[str, object],
                                                list[str], int, dict[str, object]]:
    """Poll for geometry emitted strictly after this gesture's same-PID END/CANCEL."""
    if timeout_seconds <= 0 or poll_interval_seconds <= 0:
        raise ValueError("geometry polling timeout and interval must be positive")
    started = time.monotonic()
    max_polls = max(1, math.ceil(timeout_seconds / poll_interval_seconds) + 1)
    last_error = "no fresh raw touch END/CANCEL yet"
    for poll_index in range(max_polls):
        elapsed = time.monotonic() - started
        remaining = timeout_seconds - elapsed
        if remaining <= 0:
            break
        command_timeout = max(1, math.ceil(remaining))
        poll_label = f"{label}_poll_{poll_index + 1:03d}"
        rows = _capture_hilog(hdc, out, poll_label, pid, timeout=command_timeout)
        try:
            fence = gesture_terminal_fence(before, rows)
            if fence is None:
                raise ValueError("no fresh raw touch END/CANCEL yet")
            nav, viewport = fresh_nav_viewport_geometry(
                before, rows, nav_label, viewport_label,
                strictly_after_timestamp=fence["timestamp"])
        except ValueError as exc:
            last_error = str(exc)
            message = str(exc)
            retryable = (
                "no fresh raw touch END/CANCEL yet" in message
                or "rotated hilog freshness" in message
                or "same-PID touch event freshness cannot be proven" in message
                or ("expected exactly one fresh labeled" in message and "found 0" in message)
            )
            if not retryable:
                raise
        else:
            (out / f"hilog_{label}.txt").write_text("\n".join(rows), encoding="utf-8")
            return nav, viewport, rows, poll_index + 1, fence
        elapsed = time.monotonic() - started
        remaining = timeout_seconds - elapsed
        if remaining <= 0 or poll_index + 1 >= max_polls:
            break
        pause(min(poll_interval_seconds, remaining))
    raise ValueError(
        f"no accepted nav/viewport geometry strictly after the current same-PID "
        f"raw END/CANCEL for {nav_label!r}/{viewport_label!r} within "
        f"{timeout_seconds:g}s: {last_error}; poll logs are archived")


def _pid_hilog_rows(raw: str, pid: str) -> list[str]:
    tag = re.compile(r"\bCjgui(?:App|Renderer|Host|Core):")
    return [line for line in raw.splitlines()
            if len(line.split()) >= 5 and line.split()[2] == pid and tag.search(line)]


def _assert_fresh_reveal_then_focus(before: list[str], after: list[str], pid: str,
                                    ime_field: str,
                                    nav_label: str = "settings-focus-note-nav",
                                    viewport_label: str = "settings-hand-scroll"
                                    ) -> tuple[str, str]:
    """Require a same-PID offscreen-to-visible geometry transition and ordered focus.

    The renderer's diagnostic `platform focus reveal requested` is conditional:
    it is absent when the accepted editor has already become visible by the time
    focus reaches the renderer. Accepted bounds are the proof of reveal; focus
    and IME events only prove that the revealed editor received system focus.
    """
    before_rows = _pid_hilog_rows("\n".join(before), pid)
    after_rows = _pid_hilog_rows("\n".join(after), pid)
    rows = fresh_hilog_rows(before_rows, after_rows)
    fence = gesture_terminal_fence(before_rows, after_rows)
    if fence is None:
        raise ValueError("navigation click has no fresh same-PID raw END/CANCEL fence")
    terminal_time = fence["timestamp"]

    def records(source: list[str], record_name: str, label: str,
                *, strictly_after: tuple[int, int, int, int, int, int] | None = None
                ) -> list[tuple[tuple[int, int, int, int, int, int], dict[str, object]]]:
        result = []
        for row in source:
            if record_name not in row:
                continue
            timestamp = _hilog_timestamp_key(row)
            if timestamp is None:
                continue
            if strictly_after is not None and timestamp <= strictly_after:
                continue
            geometry = _parse_touch_geometry(row, record_name, label)
            if geometry is not None:
                result.append((timestamp, geometry))
        return result

    prior_note = records(before_rows, "h_touch_note_bounds", ime_field)
    prior_viewport = records(before_rows, "h_touch_hand_viewport_bounds", viewport_label)
    if not prior_note or not prior_viewport:
        raise ValueError("same-PID accepted editor and viewport geometry are required before navigation")
    prior_note_time, prior_note_geometry = max(prior_note, key=lambda item: item[0])
    prior_view_time, prior_view_geometry = max(prior_viewport, key=lambda item: item[0])
    if prior_note_time >= terminal_time or prior_view_time >= terminal_time:
        raise ValueError("pre-navigation editor geometry is not fenced before the nav click")
    prior_clip = prior_note_geometry["clip"]
    prior_rect = (int(prior_note_geometry["x"]), int(prior_note_geometry["y"]),
                  int(prior_note_geometry["x"]) + int(prior_note_geometry["w"]),
                  int(prior_note_geometry["y"]) + int(prior_note_geometry["h"]))
    prior_clip_rect = (prior_clip[0], prior_clip[1], prior_clip[0] + prior_clip[2],
                       prior_clip[1] + prior_clip[3])
    prior_view_rect = _visible_rect(prior_view_geometry)
    if (_rect_contains(prior_clip_rect, prior_rect) and prior_view_rect is not None
            and _rect_contains(prior_view_rect, prior_rect)):
        raise ValueError("accepted editor was already visible before navigation; reveal is unproven")

    api_events = []
    platform_events = []
    payload_events = []
    mounted_events = []
    focused_events = []
    for row_index, row in enumerate(rows):
        timestamp = _hilog_timestamp_key(row)
        if timestamp is None or timestamp <= terminal_time:
            continue
        api = re.search(r"focus api enter node=(\d+) accepted=\S+", row)
        if api:
            api_events.append((row_index, timestamp, api.group(1), row))
        platform = re.search(r"platform focus(?: reveal requested)? node=(\d+) ctx=(\S+)"
                             r"(?: field=(\S+))?", row)
        if platform and (platform.group(3) is None or platform.group(3) == ime_field):
            platform_events.append((row_index, timestamp, platform.group(1), platform.group(2), row))
        payload = re.search(r'ime focus payload=.*["\']field["\']\s*:\s*["\']'
                            + re.escape(ime_field) + r'["\']', row)
        if payload:
            context = re.search(r'["\']context["\']\s*:\s*(\d+)', row)
            if context:
                payload_events.append((row_index, timestamp, context.group(1), row))
        mounted = re.search(r"ime proxy mounted ctx=(\S+) field=" + re.escape(ime_field)
                            + r" node=(\d+)\b", row)
        if mounted:
            mounted_events.append((row_index, timestamp, mounted.group(1),
                                   mounted.group(2), row))
        focused = re.search(r"ime proxy FOCUSED field=" + re.escape(ime_field)
                            + r" mount=(\S+)$", row)
        if focused:
            focused_events.append((row_index, timestamp, focused.group(1), row))
    if len(api_events) != 1:
        raise ValueError(f"expected one fresh same-PID focus API event after nav click; found {len(api_events)}")
    if (len(platform_events) != 1 or len(payload_events) != 1
            or len(mounted_events) != 1 or len(focused_events) != 1):
        raise ValueError("same-PID platform focus, matching IME mount, and IME FOCUSED events are required")
    api_index, api_time, node_id, _ = api_events[0]
    platform_index, platform_time, platform_node, context_id, _ = platform_events[0]
    payload_index, payload_time, payload_context, _ = payload_events[0]
    mounted_index, mounted_time, mounted_context, mounted_node, _ = mounted_events[0]
    ime_index, ime_time, mount, _ = focused_events[0]
    if (platform_node != node_id or mounted_node != node_id
            or payload_context != context_id or mounted_context != context_id
            or not terminal_time < api_time
            or not api_index < platform_index < payload_index < mounted_index < ime_index):
        raise ValueError("same-PID focus API, platform focus, payload, and IME events are out of order")

    post_note = records(rows, "h_touch_note_bounds", ime_field, strictly_after=ime_time)
    post_viewport = records(rows, "h_touch_hand_viewport_bounds", viewport_label,
                            strictly_after=ime_time)
    if not post_note or not post_viewport:
        raise ValueError("fresh accepted editor geometry after IME focus is required to prove reveal")
    _, note_geometry = max(post_note, key=lambda item: item[0])
    _, viewport_geometry = max(post_viewport, key=lambda item: item[0])
    note_rect = (int(note_geometry["x"]), int(note_geometry["y"]),
                 int(note_geometry["x"]) + int(note_geometry["w"]),
                 int(note_geometry["y"]) + int(note_geometry["h"]))
    note_clip = note_geometry["clip"]
    note_clip_rect = (note_clip[0], note_clip[1], note_clip[0] + note_clip[2],
                       note_clip[1] + note_clip[3])
    visible_view = _visible_rect(viewport_geometry)
    if (not _rect_contains(note_clip_rect, note_rect) or visible_view is None
            or not _rect_contains(visible_view, note_rect)):
        raise ValueError("post-navigation accepted editor is not fully visible in its viewport")
    return node_id, mount


def poll_fresh_reveal_then_focus(hdc, out: Path, before: list[str], label: str,
                                 pid: str, ime_field: str, nav_label: str,
                                 viewport_label: str, *, timeout_seconds: float = 8.0,
                                 poll_interval_seconds: float = 0.5,
                                 pause=time.sleep) -> tuple[str, str, list[str], int]:
    """Poll same-PID logs until terminal, ordered focus, and visible geometry agree."""
    if timeout_seconds <= 0 or poll_interval_seconds <= 0:
        raise ValueError("reveal polling timeout and interval must be positive")
    started = time.monotonic()
    max_polls = max(1, math.ceil(timeout_seconds / poll_interval_seconds) + 1)
    last_error = "focus/reveal diagnostics are not fresh yet"
    for poll_index in range(max_polls):
        remaining = timeout_seconds - (time.monotonic() - started)
        if remaining <= 0:
            break
        rows = _capture_hilog(hdc, out, f"{label}_poll_{poll_index + 1:03d}", pid,
                              timeout=max(1, math.ceil(remaining)))
        try:
            result = _assert_fresh_reveal_then_focus(
                before, rows, pid, ime_field, nav_label, viewport_label)
        except ValueError as exc:
            last_error = str(exc)
        else:
            (out / f"hilog_{label}.txt").write_text("\n".join(rows), encoding="utf-8")
            return result[0], result[1], rows, poll_index + 1
        remaining = timeout_seconds - (time.monotonic() - started)
        if remaining <= 0 or poll_index + 1 >= max_polls:
            break
        pause(min(poll_interval_seconds, remaining))
    raise ValueError(f"same-PID offscreen editor reveal/focus proof unavailable within "
                     f"{timeout_seconds:g}s: {last_error}; poll logs are archived")


def _same_pid(hdc, args) -> str:
    return selection.assert_same_pid(args.pid, hdc.pidof(args.bundle))


def _require_owner_same(expected: dict[str, object], observed: dict[str, object], stage: str) -> None:
    if (expected["version"], expected["value"]) != (observed["version"], observed["value"]):
        raise ValueError(f"owner changed during {stage}")


def _assert_no_fresh_business_action(before: list[str], after: list[str], pid: str,
                                     stage: str) -> None:
    fresh = fresh_hilog_rows(
        selection.app_rows("\n".join(before), pid),
        selection.app_rows("\n".join(after), pid))
    if any("submit" in line.lower() or "action invoke" in line.lower()
           for line in fresh):
        raise ValueError(f"{stage} produced a fresh business action log")


def _check_binding(hdc, args, receipt: dict[str, object]) -> dict[str, object]:
    normal._receipt(receipt, args.target, args.local_port, args.device_port)
    listing = hdc.listing()
    normal._forward_map(listing, args.target, args.local_port, args.device_port)
    _same_pid(hdc, args)
    return {"target": args.target, "bundle": args.bundle, "pid": args.pid,
            "local_port": args.local_port, "device_port": args.device_port,
            "fport_ls_raw": listing}


def _pull_layout(hdc, out: Path, pid: str, bundle: str,
                 label: str = "selection_menu") -> Path:
    if hdc.pidof(bundle).strip() != pid:
        raise ValueError("PID changed before system selection menu layout")
    remote = f"/data/local/tmp/cjgui-hand-nav-{label}-{uuid.uuid4().hex}.json"
    local = (out / "selection_menu.json" if label == "selection_menu"
             else out / f"uitest_layout_{label}.json")
    try:
        hdc.shell("uitest dumpLayout -p " + shlex.quote(remote), timeout=45)
        hdc.pull(remote, local)
    finally:
        hdc.shell("rm -f " + shlex.quote(remote), timeout=30)
    if not local.is_file():
        raise ValueError("system selection menu layout was not pulled")
    if hdc.pidof(bundle).strip() != pid:
        raise ValueError("PID changed while reading UITest layout")
    return local


SYSTEM_IME_BUNDLE = "com.huawei.hmos.inputmethod"


def assert_foreground_root_bundle(tree: object, expected_bundle: str,
                                  allow_ime_root: bool = False) -> list[str | None]:
    """Require exactly one visible UITest root and its explicit app bundle."""
    roots: list[str | None] = []

    def visit(node: object) -> None:
        if not isinstance(node, dict):
            return
        attrs = node.get("attributes", {})
        if isinstance(attrs, dict) and attrs.get("type") == "root" \
                and attrs.get("visible") == "true":
            bundle = attrs.get("bundleName")
            roots.append(bundle if isinstance(bundle, str) and bundle else None)
        children = node.get("children", [])
        if isinstance(children, list):
            for child in children:
                visit(child)

    visit(tree)
    allowed = ([expected_bundle, SYSTEM_IME_BUNDLE]
               if allow_ime_root else [expected_bundle])
    if (len(roots) not in (1, 2) if allow_ime_root else len(roots) != 1):
        raise ValueError(
            f"expected exactly one visible app UITest root"
            f"{(' and at most one explicit system IME root' if allow_ime_root else '')}, "
            f"found {roots!r}")
    if (roots.count(expected_bundle) != 1 or
            any(root not in allowed for root in roots) or
            (len(roots) == 2 and roots.count(SYSTEM_IME_BUNDLE) != 1)):
        raise ValueError(
            f"foreground UITest root bundle mismatch: expected one {expected_bundle!r}"
            f"{(' with optional ' + repr(SYSTEM_IME_BUNDLE) if allow_ime_root else '')}, "
            f"observed {roots!r}")
    return roots


def _gesture(hdc, args, out: Path, label: str, command: str,
             *, layout_tree: object | None = None,
             allow_ime_root: bool = False) -> None:
    """Guard every UI gesture with a current PID and visible root bundle check."""
    if layout_tree is None:
        layout_file = _pull_layout(hdc, out, args.pid, args.bundle, label)
        layout_tree = json.loads(layout_file.read_text(encoding="utf-8"))
    else:
        if hdc.pidof(args.bundle).strip() != args.pid:
            raise ValueError(f"PID changed before {label}")
    observed = assert_foreground_root_bundle(
        layout_tree, args.bundle, allow_ime_root=allow_ime_root)
    checks_path = out / "foreground_root_checks.json"
    try:
        checks = json.loads(checks_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        checks = []
    checks.append({"stage": label, "expected_bundle": args.bundle,
                   "observed_root_bundles": observed})
    _write_json(checks_path, checks)
    hdc.shell(command)


def run_probe(args: argparse.Namespace, hdc, exchange=None, *, pause=time.sleep) -> dict[str, object]:
    out = Path(args.run_dir)
    out.mkdir(parents=True, exist_ok=False)
    exchange = exchange or BoundedExchange("127.0.0.1", args.local_port,
                                            str(out / "exchanges.json"))
    receipt: dict[str, object] = {}
    bindings: list[dict[str, object]] = []
    try:
        hap_sha = hash_file(args.hap)
        if args.hap_sha256 != hap_sha:
            raise ValueError("provided HAP SHA-256 does not match the supplied file")
        identity = (f"target={args.target}\npid={args.pid}\nhap_sha256={hap_sha}\n"
                    "build_variant=normal\n")
        selection.assert_identity(identity, args.target, args.hap, args.pid)
        receipt_raw = Path(args.forward_receipt_json).read_text(encoding="utf-8")
        receipt = json.loads(receipt_raw)
        if not isinstance(receipt, dict):
            raise ValueError("forward receipt must be a JSON object")
        (out / "identity.raw.txt").write_text(identity, encoding="utf-8")
        (out / "forward_receipt.raw.json").write_text(receipt_raw, encoding="utf-8")
        nav_x, nav_y, nav_source = resolve_nav_point(args)
        if args.accepted_bounds_log:
            (out / "accepted_bounds_log.raw.txt").write_bytes(
                Path(args.accepted_bounds_log).read_bytes())
        points = {name: _check_point(getattr(args, name + "_x"), getattr(args, name + "_y"))
                  for name in ("swipe_start", "swipe_end")}
        if args.xcomponent_origin_x is None or args.xcomponent_origin_y is None:
            raise ValueError("current editor bounds require both XComponent screen-origin coordinates")
        xcomponent_origin = (args.xcomponent_origin_x, args.xcomponent_origin_y)
        _same_pid(hdc, args)
        bindings.append(_check_binding(hdc, args, receipt))

        owner_before = _owner(exchange, args, out, "before")
        owner_text = owner_before.get("value")
        if not isinstance(owner_text, str) or not owner_text:
            raise ValueError(
                "handwritten selection requires a prefill of non-empty owner text before running")
        owner_selection_length = utf16_code_unit_length(owner_text)
        if owner_selection_length <= 0:
            raise ValueError(
                "handwritten selection requires a prefill of non-empty owner text before running")
        before_swipe_log = _capture_hilog(hdc, out, "before_swipe", args.pid)
        _gesture(hdc, args, out, "before_initial_swipe",
                 "uitest uiInput swipe "
                 f"{points['swipe_start'][0]} {points['swipe_start'][1]} "
                 f"{points['swipe_end'][0]} {points['swipe_end'][1]} {args.swipe_duration_ms}")
        pause(args.settle_seconds)
        _same_pid(hdc, args)
        owner_after_swipe = _owner(exchange, args, out, "after_swipe")
        _require_owner_same(owner_before, owner_after_swipe, "initial swipe")
        current_nav, current_viewport, after_swipe_log, swipe_geometry_polls, swipe_fence = (
            poll_fresh_nav_viewport_geometry(
                hdc, out, before_swipe_log, "after_swipe", args.pid,
                args.nav_semantic_id, args.viewport_semantic_id,
                timeout_seconds=args.nav_geometry_timeout_seconds, pause=pause))
        # A swipe that accidentally activates the start button must not silently pass.
        if any("submit" in line.lower() or "action invoke" in line.lower()
               for line in fresh_hilog_rows(
                   selection.app_rows("\n".join(before_swipe_log), args.pid),
                   selection.app_rows("\n".join(after_swipe_log), args.pid))):
            raise ValueError("button-origin swipe produced a fresh business action log")
        bindings.append(_check_binding(hdc, args, receipt))

        nav_after_initial_swipe = current_nav
        viewport_after_initial_swipe = current_viewport
        nav_restore_steps: list[dict[str, object]] = []
        initial_offset_restore_steps: list[dict[str, object]] = []
        latest_geometry_log = after_swipe_log
        latest_geometry_fence = swipe_fence
        nav_geometry = {
            "point_before_initial_swipe": {"x": nav_x, "y": nav_y, "source": nav_source},
            "after_initial_swipe": {"nav": nav_after_initial_swipe,
                                     "viewport": viewport_after_initial_swipe,
                                     "geometry_poll_count": swipe_geometry_polls,
                                     "gesture_terminal_fence": swipe_fence},
            "restore_steps": nav_restore_steps,
            "point_clicked_after_fresh_geometry": None,
            "xcomponent_origin": xcomponent_origin,
            "final_nav": current_nav, "final_viewport": current_viewport,
        }
        _write_json(out / "nav_geometry.json", nav_geometry)
        for attempt in range(args.nav_restore_max_swipes + 1):
            try:
                nav_click_point = nav_screen_point(
                    current_nav, xcomponent_origin, current_viewport)
                break
            except ValueError as geometry_error:
                if attempt >= args.nav_restore_max_swipes:
                    raise ValueError(
                        f"navigation remained clipped after {attempt} bounded reverse swipes: "
                        f"{geometry_error}") from geometry_error
                restore_points = viewport_restore_swipe(
                    current_nav, current_viewport, xcomponent_origin)
                _gesture(hdc, args, out, f"before_nav_restore_{attempt + 1}",
                         "uitest uiInput swipe "
                         f"{restore_points[0]} {restore_points[1]} "
                         f"{restore_points[2]} {restore_points[3]} "
                         f"{args.swipe_duration_ms}")
                pause(args.settle_seconds)
                _same_pid(hdc, args)
                owner_after_restore = _owner(
                    exchange, args, out, f"after_nav_restore_{attempt + 1}")
                _require_owner_same(owner_before, owner_after_restore,
                                    f"navigation restore swipe {attempt + 1}")
                next_nav, next_viewport, restore_log, restore_geometry_polls, restore_fence = (
                    poll_fresh_nav_viewport_geometry(
                        hdc, out, latest_geometry_log,
                        f"after_nav_restore_{attempt + 1}", args.pid,
                        args.nav_semantic_id, args.viewport_semantic_id,
                        timeout_seconds=args.nav_geometry_timeout_seconds, pause=pause))
                _assert_no_fresh_business_action(
                    latest_geometry_log, restore_log, args.pid,
                    f"navigation restore swipe {attempt + 1}")
                nav_restore_steps.append({
                    "attempt": attempt + 1, "from_nav": current_nav,
                    "from_viewport": current_viewport,
                    "swipe_screen_points": restore_points,
                    "to_nav": next_nav, "to_viewport": next_viewport,
                    "geometry_poll_count": restore_geometry_polls,
                    "gesture_terminal_fence": restore_fence,
                })
                current_nav, current_viewport = next_nav, next_viewport
                latest_geometry_log = restore_log
                latest_geometry_fence = restore_fence
                nav_geometry["final_nav"] = current_nav
                nav_geometry["final_viewport"] = current_viewport
                _write_json(out / "nav_geometry.json", nav_geometry)
        else:
            raise ValueError("navigation could not be brought fully inside its accepted clip")

        # Becoming clickable is not enough: a short initial swipe can leave the
        # editor visible at the bottom edge, so FOCUS_NOTE does not exercise the
        # real offscreen reveal path. Return the nav to its accepted initial
        # center before clicking and verify the editor is clipped out of view.
        nav_geometry["initial_offset_restore_steps"] = initial_offset_restore_steps
        initial_nav_point = (nav_x, nav_y)
        for attempt in range(args.nav_restore_max_swipes + 1):
            offset_delta = nav_offset_to_initial_y(
                current_nav, current_viewport, initial_nav_point, xcomponent_origin)
            if offset_delta == 0:
                break
            if attempt >= args.nav_restore_max_swipes:
                raise ValueError(
                    f"navigation did not return to its initial scroll offset after "
                    f"{attempt} bounded swipes; remaining vertical delta={offset_delta}")
            restore_points = viewport_scroll_delta_swipe(
                offset_delta, current_viewport, xcomponent_origin)
            _gesture(hdc, args, out, f"before_nav_offset_restore_{attempt + 1}",
                     "uitest uiInput swipe "
                     f"{restore_points[0]} {restore_points[1]} "
                     f"{restore_points[2]} {restore_points[3]} "
                     f"{args.swipe_duration_ms}")
            pause(args.settle_seconds)
            _same_pid(hdc, args)
            owner_after_offset_restore = _owner(
                exchange, args, out, f"after_nav_offset_restore_{attempt + 1}")
            _require_owner_same(owner_before, owner_after_offset_restore,
                                f"navigation initial-offset restore {attempt + 1}")
            next_nav, next_viewport, restore_log, restore_geometry_polls, restore_fence = (
                poll_fresh_nav_viewport_geometry(
                    hdc, out, latest_geometry_log,
                    f"after_nav_offset_restore_{attempt + 1}", args.pid,
                    args.nav_semantic_id, args.viewport_semantic_id,
                    timeout_seconds=args.nav_geometry_timeout_seconds, pause=pause))
            _assert_no_fresh_business_action(
                latest_geometry_log, restore_log, args.pid,
                f"navigation initial-offset restore {attempt + 1}")
            initial_offset_restore_steps.append({
                "attempt": attempt + 1,
                "from_nav": current_nav,
                "from_viewport": current_viewport,
                "requested_vertical_delta": offset_delta,
                "swipe_screen_points": restore_points,
                "to_nav": next_nav,
                "to_viewport": next_viewport,
                "geometry_poll_count": restore_geometry_polls,
                "gesture_terminal_fence": restore_fence,
            })
            current_nav, current_viewport = next_nav, next_viewport
            latest_geometry_log = restore_log
            latest_geometry_fence = restore_fence
            nav_geometry["final_nav"] = current_nav
            nav_geometry["final_viewport"] = current_viewport
            _write_json(out / "nav_geometry.json", nav_geometry)
        nav_geometry["initial_offset_restore_steps"] = initial_offset_restore_steps
        nav_geometry["initial_offset_alignment_delta"] = nav_offset_to_initial_y(
            current_nav, current_viewport, initial_nav_point, xcomponent_origin)
        if latest_geometry_fence is None:
            raise ValueError("initial-offset geometry has no same-PID touch terminal fence")
        editor_capture_count = 0
        def capture_current_editor_geometry():
            nonlocal editor_capture_count
            _same_pid(hdc, args)
            editor_capture_count += 1
            return _capture_hilog(hdc, out,
                                  f"after_nav_editor_{editor_capture_count:03d}",
                                  args.pid, timeout=5)
        editor_visible, latest_geometry_log, editor_geometry_polls = (
            poll_editor_visible_in_fenced_geometry(
                latest_geometry_log, args.field_label, current_viewport,
                latest_geometry_fence["timestamp"], capture_current_editor_geometry,
                timeout_seconds=args.nav_geometry_timeout_seconds, pause=pause))
        nav_geometry["editor_geometry_polls"] = editor_geometry_polls
        if editor_visible is None:
            raise ValueError(
                "fresh same-PID editor geometry is required to prove it remains offscreen "
                "before navigation")
        nav_geometry["editor_visible_before_nav"] = editor_visible
        if editor_visible:
            raise ValueError(
                "editor remains visible after restoring the initial navigation offset; "
                "offscreen focus reveal cannot be verified")
        # The center can move while restoring the scroll offset; click only its
        # final accepted geometry.
        nav_click_point = nav_screen_point(
            current_nav, xcomponent_origin, current_viewport)
        _write_json(out / "nav_geometry.json", nav_geometry)

        nav_geometry["point_clicked_after_fresh_geometry"] = {
            "x": nav_click_point[0], "y": nav_click_point[1],
        }
        nav_geometry["final_nav"] = current_nav
        nav_geometry["final_viewport"] = current_viewport
        _write_json(out / "nav_geometry.json", nav_geometry)
        _gesture(hdc, args, out, "before_nav_click",
                 f"uitest uiInput click {nav_click_point[0]} {nav_click_point[1]}")
        pause(args.settle_seconds)
        _same_pid(hdc, args)
        owner_after_nav = _owner(exchange, args, out, "after_nav")
        _require_owner_same(owner_before, owner_after_nav, "handwritten navigation")
        reveal_node_id, mount, after_nav_log, reveal_poll_count = poll_fresh_reveal_then_focus(
            hdc, out, latest_geometry_log, "after_nav", args.pid, args.ime_field,
            args.nav_label, args.viewport_semantic_id,
            timeout_seconds=args.nav_geometry_timeout_seconds, pause=pause)
        nav_geometry["reveal_poll_count"] = reveal_poll_count
        nav_geometry["reveal_node_id"] = reveal_node_id
        nav_geometry["ime_mount"] = mount
        _write_json(out / "nav_geometry.json", nav_geometry)
        points["field"] = field_point_from_fresh_logs(
            latest_geometry_log, after_nav_log, args.field_label, xcomponent_origin)
        points["field_text_hit"] = field_text_hit_point_from_fresh_logs(
            latest_geometry_log, after_nav_log, args.field_label, xcomponent_origin)
        (out / "field_point.json").write_text(json.dumps({
            "screen_point": points["field"], "xcomponent_origin": xcomponent_origin,
            "long_press_screen_point": points["field_text_hit"],
            "source": "fresh_same_pid_post_nav_bounds", "field_label": args.field_label,
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        bindings.append(_check_binding(hdc, args, receipt))

        # Focus the editor at its accepted center, but long-press over the
        # leading text glyph. System selection behavior can differ across
        # platforms when a press lands on empty field space.
        _gesture(hdc, args, out, "before_field_click",
                 f"uitest uiInput click {points['field'][0]} {points['field'][1]}",
                 allow_ime_root=True)
        pause(args.settle_seconds)
        _same_pid(hdc, args)
        before_selection_log = _capture_hilog(hdc, out, "before_selection", args.pid)
        _gesture(hdc, args, out, "before_field_long_click",
                 f"uitest uiInput longClick {points['field_text_hit'][0]} "
                 f"{points['field_text_hit'][1]}",
                 allow_ime_root=True)
        pause(args.menu_settle_seconds)
        _same_pid(hdc, args)
        after_long_click_log = _capture_hilog(hdc, out, "after_long_click", args.pid)
        menu_point = None
        selection_method = "system_select_all_menu"
        selection_range = None
        selected_log = None
        direct_selection_error = None
        try:
            direct_range = _fresh_full_ime_selection(
                before_selection_log, after_long_click_log, args.pid, mount,
                owner_selection_length)
        except (AssertionError, ValueError) as exc:
            direct_selection_error = str(exc)
        else:
            try:
                _read_public_full_window_selection(
                    exchange, args, out, "after_long_click", owner_selection_length)
            except ValueError as exc:
                direct_selection_error = str(exc)
            else:
                selection_range = direct_range
                selected_log = after_long_click_log
                selection_method = "long_press_direct_full_selection"

        if selection_range is None:
            menu_file = _pull_layout(hdc, out, args.pid, args.bundle, "selection_menu")
            menu_tree = json.loads(menu_file.read_text(encoding="utf-8"))
            try:
                menu_point = selection.menu_point(menu_tree)
            except AssertionError as exc:
                raise ValueError(
                    "long press did not select the full non-empty owner text and the system "
                    "全选 menu is unavailable") from exc
            _gesture(hdc, args, out, "before_select_all_click",
                     f"uitest uiInput click {menu_point[0]} {menu_point[1]}",
                     layout_tree=menu_tree, allow_ime_root=True)
            pause(args.settle_seconds)
            _same_pid(hdc, args)
            selected_log = _capture_hilog(hdc, out, "selected", args.pid)
            selection_range = _fresh_full_ime_selection(
                before_selection_log, selected_log, args.pid, mount,
                owner_selection_length)
            _read_public_full_window_selection(
                exchange, args, out, "after_menu_select_all", owner_selection_length)
        assert selected_log is not None and selection_range is not None
        (out / "system_selection.json").write_text(json.dumps({
            "menu_point": menu_point, "method": selection_method,
            "direct_selection_fallback_reason": direct_selection_error,
            "field_text_hit_point": points["field_text_hit"],
            "mount": mount, "owner_selection_utf16_length": owner_selection_length,
            "selection_utf16": selection_range,
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        # Delete the selected range, then paste the replacement through UITest's
        # actual system input path; owner remains unchanged until submit.
        _gesture(hdc, args, out, "before_select_all_delete",
                 "uitest uiInput keyEvent 2055", allow_ime_root=True)
        _gesture(hdc, args, out, "before_replacement_input",
                 f"uitest uiInput inputText {points['field'][0]} {points['field'][1]} "
                 + shlex.quote(args.replacement), allow_ime_root=True)
        pause(args.settle_seconds)
        draft_log = _capture_hilog(hdc, out, "draft", args.pid)
        draft_lengths = selection.assert_fresh_draft(
            selected_log, draft_log, args.pid, mount)
        owner_draft = _owner(exchange, args, out, "draft")
        _require_owner_same(owner_before, owner_draft, "uncommitted system input")

        _gesture(hdc, args, out, "before_submit",
                 "uitest uiInput keyEvent 2054", allow_ime_root=True)
        pause(args.settle_seconds)
        submitted_log = _capture_hilog(hdc, out, "after_submit", args.pid)
        selection.assert_fresh_submit(draft_log, submitted_log, args.pid, mount)
        owner_after = _owner(exchange, args, out, "after")
        selection.assert_exact_commit(owner_before, owner_after, args.replacement)
        bindings.append(_check_binding(hdc, args, receipt))
        result = {
            "status": "passed", "target": args.target, "bundle": args.bundle,
            "pid": args.pid, "hap_sha256": hap_sha, "build_variant": "normal",
            "local_port": args.local_port, "device_port": args.device_port,
            "field": args.field, "resource_id": args.resource_id,
            "nav_point": {"x": nav_click_point[0], "y": nav_click_point[1],
                          "source": "fresh_post_swipe_accepted_bounds"},
            "nav_geometry": nav_geometry,
            "swipe_points": points, "owner_before": owner_before,
            "owner_after_swipe": owner_after_swipe, "owner_after_nav": owner_after_nav,
            "owner_draft": owner_draft, "owner_after": owner_after,
            "mount": mount, "reveal_node_id": reveal_node_id,
            "selection_utf16": selection_range, "selection_method": selection_method,
            "draft_event_lengths": draft_lengths, "replacement": args.replacement,
            "binding_checks": bindings, "visual_review": "screenshots not captured by this verifier",
        }
        _write_json(out / "result.json", result)
        return result
    except Exception as exc:
        _write_json(out / "failure.json", {
            "error_type": type(exc).__name__, "error": str(exc),
            "target": args.target, "bundle": args.bundle, "pid": args.pid,
            "hap": str(args.hap), "hap_sha256_expected": args.hap_sha256,
            "local_port": args.local_port, "device_port": args.device_port,
            "binding_checks": bindings,
        })
        raise
    finally:
        commands = getattr(hdc, "commands", [])
        _write_json(out / "hdc_commands.json", commands)
        flush = getattr(exchange, "flush_archive", None)
        if callable(flush):
            flush()
        if not (out / "exchanges.json").exists():
            _write_json(out / "exchanges.json", getattr(exchange, "raw_log", []))


def _write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, default=str) + "\n",
                    encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", required=True)
    parser.add_argument("--bundle", required=True)
    parser.add_argument("--hap", type=Path, required=True)
    parser.add_argument("--hap-sha256", required=True)
    parser.add_argument("--pid", required=True)
    parser.add_argument("--forward-receipt-json", type=Path, required=True)
    parser.add_argument("--local-port", type=int, required=True)
    parser.add_argument("--device-port", type=int, required=True)
    parser.add_argument("--field", required=True)
    parser.add_argument("--resource-id", type=int, required=True)
    parser.add_argument("--auth", required=True)
    parser.add_argument("--ime-field", required=True)
    parser.add_argument("--nav-label", required=True)
    parser.add_argument("--nav-semantic-id", required=True)
    parser.add_argument("--viewport-semantic-id", required=True)
    nav = parser.add_mutually_exclusive_group(required=True)
    nav.add_argument("--nav-x", type=int)
    nav.add_argument("--accepted-bounds-log", type=Path)
    parser.add_argument("--nav-y", type=int)
    parser.add_argument("--xcomponent-origin-x", type=int, required=True)
    parser.add_argument("--xcomponent-origin-y", type=int, required=True)
    for name in ("swipe-start", "swipe-end"):
        parser.add_argument(f"--{name}-x", type=int, required=True)
        parser.add_argument(f"--{name}-y", type=int, required=True)
    parser.add_argument("--field-label", required=True)
    parser.add_argument("--swipe-duration-ms", type=int, default=700)
    parser.add_argument("--nav-restore-max-swipes", type=int, default=4)
    parser.add_argument("--nav-geometry-timeout-seconds", type=float, default=8.0)
    parser.add_argument("--replacement", required=True)
    parser.add_argument("--settle-seconds", type=float, default=1.0)
    parser.add_argument("--menu-settle-seconds", type=float, default=0.8)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--hdc", default=selection.DEFAULT_HDC)
    args = parser.parse_args(argv)
    if not re.fullmatch(r"[0-9a-fA-F]{64}", args.hap_sha256):
        parser.error("--hap-sha256 must contain exactly 64 hexadecimal digits")
    if not re.fullmatch(r"[1-9]\d*", args.pid):
        parser.error("--pid must be a positive decimal process id")
    if args.local_port <= 0 or args.device_port <= 0 or args.resource_id < 0:
        parser.error("ports must be positive and resource id nonnegative")
    if args.local_port > 65535 or args.device_port > 65535:
        parser.error("ports must be within 1..65535")
    if (args.swipe_duration_ms <= 0 or args.settle_seconds < 0
            or args.menu_settle_seconds < 0 or args.nav_restore_max_swipes < 0
            or args.nav_geometry_timeout_seconds <= 0
            or args.nav_geometry_timeout_seconds > 8.0):
        parser.error("swipe duration/waits are invalid; geometry timeout must be in (0, 8] seconds")
    if args.accepted_bounds_log:
        if args.nav_y is not None:
            parser.error("accepted bounds mode does not take --nav-y")
    elif args.nav_x is None or args.nav_y is None:
        parser.error("explicit navigation point requires both --nav-x and --nav-y")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        result = run_probe(args, Hdc(args.hdc, args.target))
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except Exception as exc:
        print(f"FAILED: {type(exc).__name__}: {exc}", file=sys.stderr)
        print(f"Evidence archived at {args.run_dir}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
