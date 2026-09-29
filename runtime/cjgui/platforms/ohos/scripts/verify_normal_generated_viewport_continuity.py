#!/usr/bin/env python3
"""Normal-HAP generated scroll viewport, focus and selection continuity verifier.

The caller supplies an already-running normal HAP, current PID/HAP identity,
explicit bundle/target ports, a successful forward receipt, and complete v1/reorder
candidates. This verifier never builds, launches, stops, installs, or creates a
forward. It drives only the supplied app with UITest and saves raw public exchanges,
owner responses, hilog, screenshots, layouts, and binding checks.
"""
from __future__ import annotations

import argparse
from dataclasses import asdict
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import shlex
import sys
import time
import uuid

import verify_current_normal_selection_replace as selection
import verify_normal_generated_consumption as normal
from cjgui_generated_client import GeneratedUiSession, parse_generated_fields, same_structure


def validate_candidate_pair(v1: str, reorder: str, field: str, action: str) -> tuple[tuple, tuple]:
    """Require same-key/same-binding structures with a meaningful order change."""
    first = normal.candidate_nodes(v1)
    second = normal.candidate_nodes(reorder)
    def signature(nodes):
        rows = [(n.key, n.kind, n.field_id, n.action) for n in nodes]
        keys = [row[0] for row in rows]
        if len(keys) != len(set(keys)):
            raise ValueError("candidate keys are not unique")
        return rows
    left, right = signature(first), signature(second)
    if {tuple(row) for row in left} != {tuple(row) for row in right}:
        raise ValueError("reorder must preserve every accepted key/kind/field/action binding")
    if left == right:
        raise ValueError("reorder candidate does not change node order")
    for rows in (left, right):
        nodes = first if rows is left else second
        if rows[0][1] != "vertical" or not any(r[0] == "viewport" and r[1] == "scrollArea" for r in rows):
            raise ValueError("candidate needs root vertical and generated scrollArea viewport")
        viewport_index = next(i for i, node in enumerate(nodes) if node.key == "viewport")
        viewport_depth = nodes[viewport_index].depth
        if not any(r[0] == "trigger" and r[1] == "action" and r[3] == action for r in rows):
            raise ValueError("candidate action binding does not match requested action")
        if not any(r[0] == "editor" and r[1] == "textInput" and r[2] == field for r in rows):
            raise ValueError("candidate editor binding does not match requested owner field")
        if any(nodes[i].depth <= viewport_depth for i, node in enumerate(nodes)
               if node.key in ("trigger", "editor")):
            raise ValueError("generated action and editor must be descendants of scrollArea")
    return first, second


def parse_interaction(raw: str) -> dict[str, object]:
    values: dict[str, list[str]] = {}
    for line in raw.splitlines():
        if " " in line:
            key, value = line.split(" ", 1)
            values.setdefault(key, []).append(value)
    focus_state = values.get("WINDOW_FOCUS_STATE", [""])
    focus = values.get("WINDOW_FOCUS", [""])
    selections = values.get("WINDOW_SELECTION", [])
    if len(focus_state) != 1 or len(focus) != 1:
        raise ValueError("window interaction response has ambiguous focus")
    selection_value = None
    if selections:
        if len(selections) != 1:
            raise ValueError("window interaction response has ambiguous selection")
        tokens = selections[0].split()
        if len(tokens) != 3 or not tokens[1].isdigit() or not tokens[2].isdigit():
            raise ValueError("window selection record is malformed")
        selection_value = (tokens[0], int(tokens[1]), int(tokens[2]))
    return {"state": focus_state[0], "focus": focus[0], "selection": selection_value,
            "raw": raw}


def assert_live_selection(observed: dict[str, object], semantic_id: str,
                          expected_range: tuple[int, int] | None = None) -> tuple[int, int]:
    selected = observed["selection"]
    if observed["state"] != "valid" or observed["focus"] != semantic_id or not selected:
        raise ValueError("generated editor focus/selection is not live")
    control, start, end = selected
    if control != semantic_id or end <= start:
        raise ValueError("generated editor does not have a nonempty selection")
    if expected_range is not None and (start, end) != expected_range:
        raise ValueError("generated selection range changed across scene update")
    return start, end


def utf16_length(value: str) -> int:
    return len(value.encode("utf-16-le")) // 2


def assert_full_text_selection(observed_range: tuple[int, int], text: str, stage: str):
    expected = utf16_length(text)
    if expected <= 0 or observed_range != (0, expected):
        raise ValueError(f"{stage}_selection_not_full: expected [0,{expected}), got {observed_range}")
    return observed_range


def assert_owner_backed_field_projection(raw: str, field_id: str, owner_value: str) -> str:
    """Validate generated DRAFT as an owner projection, not native proxy text."""
    rows = [line.split() for line in raw.splitlines()
            if line.startswith("FIELD ") and len(line.split()) >= 4 and
            line.split()[1] == field_id]
    if len(rows) != 1:
        raise ValueError(f"generated field {field_id!r} owner projection is absent or ambiguous")
    tokens = rows[0]
    values = {}
    index = 3
    while index + 1 < len(tokens):
        key = tokens[index]
        if key == "SELECTION":
            index += 3
        else:
            values[key] = tokens[index + 1]
            index += 2
    owner_hex = owner_value.encode("utf-8").hex().upper()
    if values.get("DRAFT_HEX") != owner_hex or values.get("APPLIED_HEX") != owner_hex:
        raise ValueError("generated field owner-backed draft/applied projection differs from owner")
    source = values.get("DRAFT_SOURCE", "")
    if not source.startswith("owner_"):
        raise ValueError(f"generated field draft source is not explicitly owner-backed: {source!r}")
    return source


def focused_ime_proxy_text(tree, semantic_id: str, mount: str, hilog: str) -> str:
    """Read the platform proxy text from fresh focused layout, separate from owner fields."""
    hits = []
    def visit(node):
        if not isinstance(node, dict):
            return
        attrs = node.get("attributes", {})
        if (isinstance(attrs, dict) and attrs.get("id") == "cjguiImeProxy" and
                attrs.get("type") == "TextInput" and attrs.get("visible") == "true" and
                attrs.get("focused") == "true"):
            hits.append(attrs)
        for child in node.get("children", []):
            visit(child)
    visit(tree)
    if len(hits) != 1 or "text" not in hits[0]:
        raise ValueError(f"expected one visible focused text proxy with text, found {len(hits)}")
    focused = re.findall(r"ime proxy FOCUSED field=(\S+) mount=(\S+)$", hilog, re.MULTILINE)
    if not any(field == semantic_id and observed_mount == mount for field, observed_mount in focused):
        raise ValueError("text proxy layout does not match the current focused semantic mount")
    return hits[0]["text"]


def assert_continuation_proxy_empty(tree, semantic_id: str, mount: str, hilog: str) -> str:
    value = focused_ime_proxy_text(tree, semantic_id, mount, hilog)
    if value != "":
        raise ValueError(f"continuation_empty_proxy_not_retained: focused proxy text is {value!r}")
    return value


def _log_timestamp(line: str):
    match = re.match(r"^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})", line)
    if not match:
        return None
    try:
        return datetime.strptime("2000-" + match.group(1), "%Y-%m-%d %H:%M:%S.%f")
    except ValueError:
        return None


def _fresh_pid_rows(before: list[str], after: list[str], pid: str) -> list[str]:
    before_rows = selection.app_rows("\n".join(before), pid)
    after_rows = selection.app_rows("\n".join(after), pid)
    try:
        return selection.fresh_rows(before_rows, after_rows)
    except AssertionError as error:
        if "hilog baseline missing/rotated" not in str(error):
            raise
        baseline_stamps = [_log_timestamp(line) for line in before_rows]
        baseline_stamps = [stamp for stamp in baseline_stamps if stamp is not None]
        if not before_rows or not baseline_stamps:
            raise AssertionError("rotated hilog has no timestamped same-PID baseline") from error
        cutoff = max(baseline_stamps)
        fresh = []
        for line in after_rows:
            stamp = _log_timestamp(line)
            if stamp is None:
                continue
            if cutoff.month == 12 and stamp.month == 1:
                stamp = stamp.replace(year=2001)
            if stamp > cutoff:
                fresh.append(line)
        if not fresh:
            raise AssertionError("no later same-PID hilog event after rotation") from error
        return fresh


def assert_fresh_selection_state(before: list[str], after: list[str], pid: str,
                                 mount: str, allow_empty: bool = False) -> tuple[int, int]:
    """Read the latest same-PID/mount selection event, optionally including a caret."""
    rows = _fresh_pid_rows(before, after, pid)
    pattern = re.compile(r"ime select \[(\d+),(\d+)\) rc=0 mount="
                         + re.escape(mount) + r"$")
    ranges = []
    for line in rows:
        match = pattern.search(line)
        if match:
            start, end = map(int, match.groups())
            if end > start or allow_empty:
                ranges.append((start, end))
    if not ranges:
        raise AssertionError("no fresh selection event from current PID/mount")
    return ranges[-1]


class SelectionAcceptanceTimeout(TimeoutError):
    def __init__(self, latest_hilog: str, latest_interaction_raw: str,
                 event_range: tuple[int, int] | None,
                 public_range: tuple[int, int] | None):
        super().__init__("fresh same-mount IME selection and matching public selection were not both observed")
        self.latest_hilog = latest_hilog
        self.latest_interaction_raw = latest_interaction_raw
        self.event_range = event_range
        self.public_range = public_range


def wait_for_matching_selection(before_hilog: str, read_hilog, read_interaction_raw,
                                pid: str, mount: str, semantic_id: str,
                                timeout_seconds: float = 3.0, poll_seconds: float = 0.15,
                                monotonic=time.monotonic, sleep=time.sleep,
                                check_binding=None, allow_empty: bool = False):
    """Wait for one fresh IME selection and the exact same accepted public range."""
    if timeout_seconds <= 0 or poll_seconds <= 0:
        raise ValueError("selection polling bounds must be positive")
    deadline = monotonic() + timeout_seconds
    latest_hilog = ""
    latest_raw = ""
    latest_event = None
    latest_public = None
    while True:
        if check_binding is not None:
            check_binding()
        latest_hilog = read_hilog()
        latest_raw = read_interaction_raw()
        if check_binding is not None:
            check_binding()
        try:
            latest_event = assert_fresh_selection_state(
                before_hilog.splitlines(), latest_hilog.splitlines(), pid, mount,
                allow_empty=allow_empty)
        except AssertionError:
            latest_event = None
        try:
            observed = parse_interaction(latest_raw)
            if observed["state"] != "valid" or observed["focus"] != semantic_id:
                raise ValueError("generated editor focus changed during selection wait")
            public = observed["selection"]
            if not public or public[0] != semantic_id:
                raise ValueError("generated editor public selection is missing or belongs to another mount")
            public_range = (public[1], public[2])
            if not allow_empty and public_range[1] <= public_range[0]:
                raise ValueError("generated editor does not have a nonempty selection")
            latest_public = public_range
        except ValueError:
            observed = None
            latest_public = None
        if latest_event is not None and latest_public == latest_event:
            return latest_event, latest_hilog, latest_raw, observed
        remaining = deadline - monotonic()
        if remaining <= 0:
            raise SelectionAcceptanceTimeout(latest_hilog, latest_raw,
                                             latest_event, latest_public)
        sleep(min(poll_seconds, remaining))


def assert_fresh_positive_draft(before: list[str], after: list[str], pid: str, mount: str):
    fresh = _fresh_pid_rows(before, after, pid)
    lengths = []
    for line in fresh:
        match = re.search(r"ime proxy onChange len=(\d+) verdict=(\S+) mount=(\S+)$", line)
        if match:
            if match.group(2) != "ok" or match.group(3) != mount:
                raise ValueError("continuation draft event belongs to another/rejected mount")
            lengths.append(int(match.group(1)))
    if not lengths or lengths[-1] <= 0:
        raise ValueError("legitimate continuation produced no fresh nonempty draft")
    return lengths


def assert_fresh_draft_change(before: list[str], after: list[str], pid: str, mount: str,
                              require_empty_transition: bool = False,
                              expected_final_length: int | None = None):
    fresh = _fresh_pid_rows(before, after, pid)
    lengths = []
    for line in fresh:
        match = re.search(r"ime proxy onChange len=(\d+) verdict=(\S+) mount=(\S+)$", line)
        if match:
            if match.group(2) != "ok" or match.group(3) != mount:
                raise ValueError("draft event belongs to a different/rejected mount")
            lengths.append(int(match.group(1)))
    if (not lengths or
            (expected_final_length is None and lengths[-1] <= 0) or
            (expected_final_length is not None and lengths[-1] != expected_final_length) or
            (require_empty_transition and 0 not in lengths)):
        expected = (f" expected final length {expected_final_length}" if expected_final_length is not None
                    else "")
        raise ValueError(f"fresh draft transition is incomplete:{expected} lengths={lengths}")
    return lengths


def public_integer(response, resource_id: int, field_id: str) -> int:
    rows = [tokens for label, tokens in response.entries if label == "FIELD" and len(tokens) >= 4
            and tokens[0] == str(resource_id) and tokens[1] == field_id and tokens[2] == "INTEGER"]
    if len(rows) != 1 or not rows[0][3].lstrip("-").isdigit():
        raise ValueError(f"public owner integer {field_id!r} is missing or ambiguous")
    return int(rows[0][3])


def action_counter_field(action: str) -> str:
    fields = {"INCREMENT": "count", "DECREMENT": "count",
              "TEMP_UP": "targetTemp", "TEMP_DOWN": "targetTemp"}
    try:
        return fields[action]
    except KeyError as exc:
        raise ValueError(f"unsupported generated test action {action!r}") from exc


def assert_generated_draft(fields, field_id: str, owner_value: str,
                           expected_selection: tuple[int, int] | None = None):
    matches = [value for value in fields if value.field_id == field_id]
    if (len(matches) != 1 or matches[0].draft != owner_value or
            matches[0].applied != owner_value):
        raise ValueError("generated field owner-backed draft/applied projection changed")
    if not matches[0].focused:
        raise ValueError("generated field no longer reports the same focused editor")
    observed_selection = (matches[0].selection_start, matches[0].selection_end)
    if expected_selection is not None and observed_selection != expected_selection:
        raise ValueError("generated field public selection changed across accepted scene")
    return matches[0]


def accepted_instance(instances, key: str, *, kind: str, field: str | None = None,
                      action: str | None = None, require_visible: bool = True):
    matches = [item for item in instances.instances if item.key == key]
    if len(matches) != 1:
        raise ValueError(f"accepted instance {key!r} is absent or ambiguous")
    item = matches[0]
    if ((require_visible and not item.visible) or item.kind != kind or
            item.bounds[2] <= 0 or item.bounds[3] <= 0
            or (field is not None and item.field_id != field)
            or (action is not None and item.action != action) or not item.semantic_id):
        raise ValueError(f"accepted instance {key!r} has the wrong binding or no visible bounds")
    return item


class Hdc:
    def __init__(self, binary: str, target: str):
        self.base = selection.Hdc(binary, target)

    @property
    def commands(self):
        return self.base.records

    def listing(self):
        return self.base.run("fport", "ls", global_list=True).stdout

    def pidof(self, bundle: str):
        return self.base.shell(f"pidof {bundle}")

    def shell(self, command: str, timeout: int = 45):
        return self.base.shell(command, timeout=timeout)

    def pull(self, remote: str, local: Path):
        self.base.run("file", "recv", remote, str(local), timeout=45)


def _check_binding(args, hdc, pid, receipt):
    normal._receipt(receipt, args.target, args.local_port, args.device_port)
    listing = hdc.listing()
    normal._forward_map(listing, args.target, args.local_port, args.device_port)
    actual = hdc.pidof(args.bundle).strip()
    if actual != pid or not re.fullmatch(r"[1-9]\d*", actual):
        raise ValueError(f"PID changed/ambiguous for {args.bundle}: {actual!r}")
    return {"bundle": args.bundle, "target": args.target, "pid": pid,
            "local_port": args.local_port, "device_port": args.device_port,
            "fport_ls_raw": listing, "pidof_raw": actual}


def _layout(hdc: Hdc, out: Path, label: str, pid: str, bundle: str,
            allow_system_ime_overlay: bool = False, allow_ime_only_root: bool = False):
    if hdc.pidof(bundle).strip() != pid:
        raise ValueError("PID changed before UITest layout")
    remote = f"/data/local/tmp/cjgui-viewport-{uuid.uuid4().hex}.json"
    local = out / f"layout_{label}.json"
    try:
        hdc.shell("uitest dumpLayout -p " + shlex.quote(remote))
        hdc.pull(remote, local)
    finally:
        hdc.shell("rm -f " + shlex.quote(remote))
    tree = json.loads(local.read_text(encoding="utf-8"))
    if allow_ime_only_root and _is_ime_only_layout(tree):
        return tree, None
    _visible_root_identity(tree, bundle, allow_system_ime_overlay)
    hits = []
    def visit(node):
        if not isinstance(node, dict): return
        attrs = node.get("attributes", {})
        if isinstance(attrs, dict) and attrs.get("type") == "XComponent" and attrs.get("visible") == "true":
            hits.append(attrs.get("bounds", ""))
        for child in node.get("children", []): visit(child)
    visit(tree)
    if len(hits) != 1:
        raise ValueError(f"expected one visible XComponent, found {hits!r}")
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", hits[0])
    if not match: raise ValueError("XComponent bounds malformed")
    x1, y1, x2, y2 = map(int, match.groups())
    if x2 <= x1 or y2 <= y1: raise ValueError("XComponent bounds empty")
    return tree, (x1, y1, x2-x1, y2-y1)


SYSTEM_IME_BUNDLE = "com.huawei.hmos.inputmethod"


def _is_ime_only_layout(tree) -> bool:
    roots = []
    def visit(node):
        if not isinstance(node, dict): return
        attrs = node.get("attributes", {})
        if isinstance(attrs, dict) and attrs.get("type") == "root" and attrs.get("visible") == "true":
            roots.append(attrs.get("bundleName", ""))
        for child in node.get("children", []): visit(child)
    visit(tree)
    return roots == [SYSTEM_IME_BUNDLE]


def _app_window_id(tree, bundle: str) -> str:
    ids = []
    def visit(node):
        if not isinstance(node, dict): return
        attrs = node.get("attributes", {})
        if (isinstance(attrs, dict) and attrs.get("type") == "root" and
                attrs.get("bundleName") == bundle and attrs.get("visible") == "true"):
            ids.append(attrs.get("hostWindowId", ""))
        for child in node.get("children", []): visit(child)
    visit(tree)
    if len(ids) != 1 or not re.fullmatch(r"[1-9]\d*", ids[0]):
        raise ValueError("current app root has no unique hostWindowId")
    return ids[0]


def _check_ime_only_foreground(hdc, window_id: str, bundle: str, pid: str):
    if not re.fullmatch(r"[1-9]\d*", window_id):
        raise ValueError("app window id is malformed")
    focus = hdc.shell("hidumper -s WindowManagerService -a -a")
    focused = re.findall(r"(?m)^\s*Focus window:\s*(\d+)\s*$", focus)
    if len(focused) != 1 or focused[0] != window_id:
        raise ValueError("IME-only input app window is not the WindowManager focused window")
    detail = hdc.shell(f'hidumper -s 4606 -a "-w {window_id} -a"')
    fields = {}
    for line in detail.splitlines():
        if ":" in line:
            name, value = line.split(":", 1)
            fields.setdefault(name.strip(), []).append(value.strip())
    expected = {"WinId": window_id, "Pid": pid, "IsVisible": "true",
                "isRSVisible": "true", "bundleName": bundle}
    if any(fields.get(name) != [value] for name, value in expected.items()):
        raise ValueError("IME-only input app window identity or visibility changed")


def assert_ime_surface_resize(before_bounds, after_bounds, before, after):
    if (before_bounds[:3] != after_bounds[:3] or
            not 0 < after_bounds[3] < before_bounds[3]):
        raise ValueError("system IME did not reduce the live XComponent height")
    # This public revision is a fingerprint of accepted instance geometry,
    # not a monotonic counter. A real resize can produce a smaller integer.
    if after.window_geometry_revision == before.window_geometry_revision:
        raise ValueError("system IME Surface geometry fingerprint did not change")
    if (after.window_accepted_scene_version <= before.window_accepted_scene_version or
            after.owner_pending_scene):
        raise ValueError("system IME resized scene did not settle at a newer accepted version")
    return {"before_bounds": before_bounds, "after_bounds": after_bounds,
            "before_geometry_revision": before.window_geometry_revision,
            "after_geometry_revision": after.window_geometry_revision,
            "before_accepted_scene_version": before.window_accepted_scene_version,
            "after_accepted_scene_version": after.window_accepted_scene_version}


def _visible_root_identity(tree, expected_bundle: str,
                           allow_system_ime_overlay: bool = False):
    roots = []
    def visit(node):
        if not isinstance(node, dict): return
        attrs = node.get("attributes", {})
        if isinstance(attrs, dict) and attrs.get("type") == "root" and attrs.get("visible") == "true":
            roots.append((attrs.get("bundleName", ""), attrs.get("bounds", "")))
        for child in node.get("children", []): visit(child)
    visit(tree)
    app_roots = [root for root in roots if root[0] != SYSTEM_IME_BUNDLE]
    ime_roots = [root for root in roots if root[0] == SYSTEM_IME_BUNDLE]
    if len(app_roots) != 1 or len(ime_roots) > 1:
        raise ValueError(f"expected one visible UITest root for the app and at most one system IME root, found {roots!r}")
    bundle, bounds = app_roots[0]
    unexpected = [root_bundle for root_bundle, _ in roots
                  if root_bundle != expected_bundle and
                  not (allow_system_ime_overlay and root_bundle == SYSTEM_IME_BUNDLE)]
    if bundle != expected_bundle or unexpected:
        raise ValueError(f"foreground UITest root bundle mismatch: expected {expected_bundle!r}, got {roots!r}")
    if ime_roots and not allow_system_ime_overlay:
        raise ValueError(f"system IME root is only allowed during text operations: {roots!r}")
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    if not match:
        raise ValueError("visible UITest root bounds are malformed")
    x1, y1, x2, y2 = map(int, match.groups())
    if not bundle or x2 <= x1 or y2 <= y1:
        raise ValueError("visible UITest root identity/bounds are invalid")
    return bundle, (x1, y1, x2-x1, y2-y1)


def _ui_input(hdc, out, args, pid, checked_binding, label, command,
              allow_system_ime_overlay: bool = False, *, allow_ime_only_key: bool = False,
              app_window_id: str = "", checked_public_focus=None):
    """Guard every coordinate/key injection with a fresh foreground-root check."""
    if not command.startswith("uitest uiInput "):
        raise ValueError("foreground guard only admits UITest uiInput commands")
    if allow_ime_only_key and not command.startswith("uitest uiInput keyEvent "):
        raise ValueError("IME-only foreground exception is keyEvent only")
    checked_binding()
    tree, _ = _layout(hdc, out, f"pre_ui_{label}", pid, args.bundle,
                      allow_system_ime_overlay or allow_ime_only_key,
                      allow_ime_only_root=allow_ime_only_key)
    if _is_ime_only_layout(tree):
        if not allow_ime_only_key or checked_public_focus is None:
            raise ValueError("IME-only key input requires current public focus")
        _check_ime_only_foreground(hdc, app_window_id, args.bundle, pid)
        checked_public_focus()
    result = hdc.shell(command)
    checked_binding()
    return result


def select_full_text_keyboard(hdc, out, args, pid, checked_binding, checked_public_focus,
                              app_window_id, label, before_hilog, read_hilog,
                              read_interaction_raw, mount, semantic_id, text_value,
                              timeout_seconds):
    """Select the whole live system draft without leaving a floating OS menu."""
    _ui_input(hdc, out, args, pid, checked_binding, label,
        "uitest uiInput keyEvent 2072 2017", allow_system_ime_overlay=True,
        allow_ime_only_key=True, app_window_id=app_window_id,
        checked_public_focus=checked_public_focus)
    try:
        selected, selected_log, selected_raw, interaction = wait_for_matching_selection(
            before_hilog, read_hilog, read_interaction_raw, pid, mount, semantic_id,
            timeout_seconds=timeout_seconds, check_binding=checked_binding)
    except SelectionAcceptanceTimeout as error:
        (out / f"hilog_{label}_timeout.txt").write_text(error.latest_hilog, encoding="utf-8")
        (out / f"window_interaction_{label}_timeout.raw.txt").write_text(
            error.latest_interaction_raw, encoding="utf-8")
        raise ValueError(f"{label}_acceptance_timeout: fresh same-mount IME and matching public selection were not both observed") from error
    assert_full_text_selection(selected, text_value, label)
    assert_live_selection(interaction, semantic_id, selected)
    return selected, selected_log, selected_raw, interaction


def _screen_point(instance, origin):
    """Convert accepted XComponent-local bounds to UITest screen coordinates."""
    x0, y0, width, height = instance.bounds
    x, y = origin[0] + x0 + width//2, origin[1] + y0 + height//2
    if not (0 <= x < 5000 and 0 <= y < 5000): raise ValueError("screen point out of bounds")
    return x, y


def _visible_root_bounds(tree, expected_bundle: str, allow_system_ime_overlay: bool = False):
    _, bounds = _visible_root_identity(tree, expected_bundle, allow_system_ime_overlay)
    return bounds


def focused_ime_proxy_point(tree, window_bounds, semantic_id: str, mount: str, hilog: str):
    """Return the OS text proxy center after verifying its focus mount and app window bounds."""
    hits = []
    def visit(node):
        if not isinstance(node, dict): return
        attrs = node.get("attributes", {})
        if (isinstance(attrs, dict) and attrs.get("id") == "cjguiImeProxy" and
                attrs.get("type") == "TextInput" and attrs.get("visible") == "true" and
                attrs.get("focused") == "true"):
            match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]",
                                 attrs.get("bounds", ""))
            if match:
                hits.append(tuple(map(int, match.groups())))
        for child in node.get("children", []): visit(child)
    visit(tree)
    if len(hits) != 1:
        raise ValueError(f"expected one visible focused cjguiImeProxy, found {hits!r}")
    focused = re.findall(r"ime proxy FOCUSED field=(\S+) mount=(\S+)$", hilog, re.MULTILINE)
    if not any(field == semantic_id and observed_mount == mount for field, observed_mount in focused):
        raise ValueError("visible system text proxy does not match the current focused semantic mount")
    x1, y1, x2, y2 = hits[0]
    wx, wy, ww, wh = window_bounds
    if (x2 <= x1 or y2 <= y1 or x1 < wx or y1 < wy or x2 > wx + ww or y2 > wy + wh):
        raise ValueError("focused system text proxy is outside the current app window bounds")
    return (x1 + x2) // 2, (y1 + y2) // 2


def _vertical_overflow(child, parent) -> int:
    top = max(parent.bounds[1] - child.bounds[1], 0)
    bottom = max(child.bounds[1] + child.bounds[3] - parent.bounds[1] - parent.bounds[3], 0)
    return top + bottom


def _scroll_trigger_into_view(session, hdc, out, args, pid, checked_binding, label):
    """Use real UITest drags until accepted action bounds are back in the viewport."""
    history = []
    direction = 1
    for attempt in range(8):
        instances = session.instances()
        trigger = accepted_instance(instances, "trigger", kind="action", action=args.action,
                                    require_visible=False)
        viewport = accepted_instance(instances, "viewport", kind="scrollArea",
                                     require_visible=True)
        overflow = _vertical_overflow(trigger, viewport)
        if trigger.visible and overflow == 0:
            tree, origin, = _layout(hdc, out, f"{label}_settled", pid, args.bundle)
            return trigger, viewport, origin, history
        tree, origin = _layout(hdc, out, f"{label}_{attempt}", pid, args.bundle)
        vx, vy = origin[0] + viewport.bounds[0], origin[1] + viewport.bounds[1]
        x = vx + viewport.bounds[2] // 2
        y1 = vy + 36
        y2 = vy + viewport.bounds[3] - 36
        if y2 <= y1:
            raise ValueError("generated viewport is too short to restore action visibility")
        start_y, end_y = (y1, y2) if direction > 0 else (y2, y1)
        checked_binding()
        _ui_input(hdc, out, args, pid, checked_binding, f"{label}_restore_{attempt}",
            f"uitest uiInput swipe {x} {start_y} {x} {end_y} 500")
        time.sleep(args.settle_seconds)
        checked_binding()
        after = session.instances()
        next_trigger = accepted_instance(after, "trigger", kind="action", action=args.action,
                                         require_visible=False)
        next_viewport = accepted_instance(after, "viewport", kind="scrollArea", require_visible=True)
        next_overflow = _vertical_overflow(next_trigger, next_viewport)
        movement = next_trigger.bounds[1] - trigger.bounds[1]
        history.append({"attempt": attempt + 1, "direction": direction,
                        "before_trigger_bounds": trigger.bounds,
                        "after_trigger_bounds": next_trigger.bounds,
                        "before_overflow": overflow, "after_overflow": next_overflow,
                        "visible": next_trigger.visible})
        if next_trigger.visible and next_overflow == 0:
            _, origin = _layout(hdc, out, f"{label}_visible", pid, args.bundle)
            return next_trigger, next_viewport, origin, history
        if movement != 0 and next_overflow > overflow:
            direction = -direction
    raise TimeoutError("generated action could not be returned to the visible viewport start")


def _capture(hdc, out, label, pid, bundle):
    if hdc.pidof(bundle).strip() != pid: raise ValueError("PID changed before screenshot")
    remote = f"/data/local/tmp/cjgui-viewport-{uuid.uuid4().hex}.jpeg"
    local = out / f"screen_{label}.jpeg"
    try:
        hdc.shell(f"snapshot_display -f {shlex.quote(remote)}")
        hdc.pull(remote, local)
    finally:
        hdc.shell("rm -f " + shlex.quote(remote))
    if not local.is_file() or local.stat().st_size == 0: raise ValueError("screenshot missing")
    return local


def _submit(session, recorder, payload, wait_ms, poll_ms, *, expect_accept):
    before = session.structure()
    submitted = session.submit_text(payload, before.version)
    ticket = submitted.ticket()
    waited = session.wait_for_candidate_result(ticket, timeout_ms=wait_ms, poll_ms=poll_ms)
    state = waited.last_state
    if waited.outcome != "terminal" or state is None:
        raise ValueError(f"candidate ticket did not reach named terminal: {waited.outcome}")
    structure = session.structure()
    snapshot = session.snapshot()
    if expect_accept:
        parsed = normal.candidate_nodes(payload)
        if (state.terminal_state != "ACCEPTED" or state.accepted_version != structure.version
                or not same_structure(parsed, structure.nodes)
                or snapshot.accepted_structure_version != structure.version
                or snapshot.structure_candidate_pending or snapshot.owner_pending_scene):
            raise ValueError("candidate was not accepted as the current settled scene")
    else:
        if state.terminal_state != "REJECTED" or structure.version != before.version:
            raise ValueError("malformed candidate did not reject while preserving accepted panel")
    return {"before_version": before.version, "ticket": asdict(ticket),
            "wait": asdict(waited), "structure": asdict(structure),
            "snapshot": asdict(snapshot), "accepted": expect_accept}


def run_probe(args, hdc: Hdc):
    if not args.bundle or not args.field or not args.action or not args.caller:
        raise ValueError("bundle, field, action and caller are required")
    if args.device_port < 1 or args.local_port < 1 or args.wait_ms <= 0 or args.poll_ms <= 0:
        raise ValueError("ports and wait bounds must be positive")
    if not args.draft or not args.continuation or args.draft == args.continuation:
        raise ValueError("draft and continuation must be distinct nonempty strings")
    if not 0.1 <= args.selection_timeout_seconds <= 10:
        raise ValueError("selection timeout must be in 0.1..10 seconds")
    v1 = Path(args.candidate).read_text(encoding="utf-8")
    reorder = Path(args.reorder_candidate).read_text(encoding="utf-8")
    first_nodes, reorder_nodes = validate_candidate_pair(v1, reorder, args.field, args.action)
    out = Path(args.run_dir)
    out.mkdir(parents=True, exist_ok=False)
    try:
        return _run(args, hdc, out, v1, reorder, first_nodes, reorder_nodes)
    except Exception as exc:
        normal.write_json(out / "failure.json", {"error_type": type(exc).__name__, "error": str(exc),
            "commands": hdc.commands})
        raise
    finally:
        normal.write_json(out / "commands.json", hdc.commands)


def _run(args, hdc, out, v1, reorder, first_nodes, reorder_nodes):
    hap = Path(args.hap)
    identity_raw = Path(args.identity).read_text(encoding="utf-8")
    pid = normal._identity(identity_raw, args.target, hap)
    receipt_raw = Path(args.forward_receipt_json).read_text(encoding="utf-8")
    receipt = json.loads(receipt_raw)
    if not isinstance(receipt, dict): raise ValueError("forward receipt must be an object")
    (out / "identity.raw.txt").write_text(identity_raw, encoding="utf-8")
    (out / "forward_receipt.raw.json").write_text(receipt_raw, encoding="utf-8")
    (out / "candidate_v1.raw.txt").write_text(v1, encoding="utf-8")
    (out / "candidate_reorder.raw.txt").write_text(reorder, encoding="utf-8")
    def checked_binding():
        if normal._identity(identity_raw, args.target, hap) != pid:
            raise ValueError("supplied identity no longer binds this HAP/PID")
        return _check_binding(args, hdc, pid, receipt)

    bindings = [checked_binding()]
    recorder = normal.ExchangeRecorder(out / "exchanges.jsonl")
    session = GeneratedUiSession.connect_forwarded_tcp(target=args.target,
        local_port=args.local_port, device_port=args.device_port, capability=args.capability,
        caller=args.caller)
    session.client = normal.RecordingClient(session.client.descriptor,
        session.client.fragment_bytes, session.client, recorder)
    capabilities = session.capabilities()
    field_spec = capabilities.field(args.field)
    if field_spec is None or not field_spec.callable or field_spec.input_kind != "textInput":
        raise ValueError("generated editor is not a callable public text field")
    context_before = session.client.get_context()
    owner_before = normal.parse_owner(context_before, args.field, field_spec.resource_id)
    bindings.append(checked_binding())
    recorder.phase = "candidate_v1"
    v1_result = _submit(session, recorder, v1, args.wait_ms, args.poll_ms, expect_accept=True)
    instances = session.instances()
    trigger = accepted_instance(instances, "trigger", kind="action", action=args.action,
                               require_visible=False)
    editor = accepted_instance(instances, "editor", kind="textInput", field=args.field,
                               require_visible=False)
    viewport = accepted_instance(instances, "viewport", kind="scrollArea")
    trigger, viewport, origin, reset_to_start = _scroll_trigger_into_view(
        session, hdc, out, args, pid, checked_binding, "reset_start")
    point = _screen_point(trigger, origin)
    _capture(hdc, out, "initial", pid, args.bundle)
    hilog_before = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
    (out / "hilog_before.txt").write_text(hilog_before, encoding="utf-8")
    owner_touch_before = normal.parse_owner(session.client.get_context(), args.field, field_spec.resource_id)
    business_field = action_counter_field(args.action)
    business_before = public_integer(session.client.get_context(), field_spec.resource_id, business_field)
    vp = _screen_point(viewport, origin)
    viewport_top = origin[1] + viewport.bounds[1]
    viewport_bottom = viewport_top + viewport.bounds[3]
    swipe_end_y = viewport_bottom - 20
    if not (viewport_top < swipe_end_y < viewport_bottom):
        raise ValueError("generated scrollArea is too short for a real swipe")
    recorder.phase = "generated_swipe"
    # Start inside the accepted action and end within the generated scroll viewport.
    bindings.append(checked_binding())
    _ui_input(hdc, out, args, pid, checked_binding, "generated_action_origin_swipe",
        f"uitest uiInput swipe {point[0]} {point[1]} {vp[0]} {swipe_end_y} 700")
    time.sleep(args.settle_seconds)
    bindings.append(checked_binding())
    owner_touch_after = normal.parse_owner(session.client.get_context(), args.field, field_spec.resource_id)
    if owner_touch_after != owner_touch_before:
        raise ValueError("generated action activation occurred during the starting swipe")
    (out / "hilog_after_swipe.txt").write_text(
        hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'"), encoding="utf-8")
    bindings.append(checked_binding())
    # Re-resolve and, if needed, scroll back to the start before clicking.
    trigger_after_swipe, viewport_after_swipe, origin_after_swipe, reset_after_swipe = (
        _scroll_trigger_into_view(session, hdc, out, args, pid, checked_binding, "reset_after_swipe"))
    current_point = _screen_point(trigger_after_swipe, origin_after_swipe)
    # A single deliberate click on the re-resolved accepted action must change its business field once.
    recorder.phase = "generated_action_click"
    bindings.append(checked_binding())
    _ui_input(hdc, out, args, pid, checked_binding, "generated_action_click",
        f"uitest uiInput click {current_point[0]} {current_point[1]}")
    time.sleep(args.settle_seconds)
    bindings.append(checked_binding())
    (out / "hilog_after_action.txt").write_text(
        hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'"), encoding="utf-8")
    context_after_action = session.client.get_context()
    owner_after_action = normal.parse_owner(context_after_action, args.field, field_spec.resource_id)
    business_after = public_integer(context_after_action, field_spec.resource_id, business_field)
    expected_delta = -1 if args.action in ("DECREMENT", "TEMP_DOWN") else 1
    if business_after != business_before + expected_delta:
        raise ValueError("one generated action click did not apply exactly one business action")
    owner_action_baseline = owner_after_action

    # Scroll until the generated editor is visible; record actual instance geometry each try.
    editor = accepted_instance(session.instances(), "editor", kind="textInput", field=args.field,
                               require_visible=False)
    for _ in range(5):
        if (editor.visible and editor.bounds[1] >= viewport.bounds[1] and
                editor.bounds[1] + editor.bounds[3] <= viewport.bounds[1] + viewport.bounds[3]): break
        bindings.append(checked_binding())
        _ui_input(hdc, out, args, pid, checked_binding, f"editor_reveal_{_}",
            f"uitest uiInput swipe {vp[0]} {vp[1]+100} {vp[0]} {vp[1]-100} 500")
        time.sleep(0.25)
        bindings.append(checked_binding())
        editor = accepted_instance(session.instances(), "editor", kind="textInput", field=args.field,
                                   require_visible=False)
    if (not editor.visible or editor.bounds[1] < viewport.bounds[1] or
            editor.bounds[1] + editor.bounds[3] > viewport.bounds[1] + viewport.bounds[3]):
        raise ValueError("generated editor did not become wholly visible inside its accepted viewport")
    tree, component_bounds = _layout(hdc, out, "editor", pid, args.bundle)
    app_window_id = _app_window_id(tree, args.bundle)
    pre_ime_snapshot = session.snapshot()
    pre_ime_bounds = component_bounds
    editor_point = _screen_point(editor, component_bounds)
    baseline = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
    bindings.append(checked_binding())
    _ui_input(hdc, out, args, pid, checked_binding, "editor_focus",
        f"uitest uiInput click {editor_point[0]} {editor_point[1]}")
    time.sleep(args.settle_seconds)
    bindings.append(checked_binding())
    focused = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
    (out / "hilog_focused.txt").write_text(focused, encoding="utf-8")
    mount = selection.assert_fresh_focus(
        baseline.splitlines(), focused.splitlines(), pid, editor.semantic_id)

    def checked_public_focus():
        interaction = parse_interaction(session.client.get_window_interaction().raw)
        if interaction["state"] != "valid" or interaction["focus"] != editor.semantic_id:
            raise ValueError("public focus lost before IME-only key input")
        fields = [field for field in session.fields() if field.field_id == args.field]
        if len(fields) != 1 or not fields[0].focused:
            raise ValueError("public focus field binding lost before IME-only key input")
        hilog = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
        focused_rows = selection.app_rows(hilog, pid)
        if not any(f"ime proxy FOCUSED field={editor.semantic_id} mount={mount}" in row
                   for row in focused_rows):
            raise ValueError("public focus has no same-PID IME mount evidence")

    proxy_points = []
    def current_ime_proxy_point(label, expected_text: str | None = None):
        binding_before = checked_binding()
        proxy_tree, _ = _layout(hdc, out, label, pid, args.bundle,
                                allow_system_ime_overlay=True)
        current_hilog = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
        interaction = parse_interaction(session.client.get_window_interaction().raw)
        if interaction["state"] != "valid" or interaction["focus"] != editor.semantic_id:
            raise ValueError("window focus changed before using the system text proxy")
        # The focused ArkUI proxy is a system input overlay. Its bounds can
        # extend below the resized XComponent while remaining inside the
        # foreground app window, so validate against the visible root window.
        window_bounds = _visible_root_bounds(proxy_tree, args.bundle,
                                             allow_system_ime_overlay=True)
        proxy_point = focused_ime_proxy_point(proxy_tree, window_bounds,
            editor.semantic_id, mount, current_hilog)
        proxy_text = focused_ime_proxy_text(proxy_tree, editor.semantic_id, mount, current_hilog)
        if expected_text is not None and proxy_text != expected_text:
            raise ValueError(f"live platform text proxy changed: expected {expected_text!r}, got {proxy_text!r}")
        binding_after = checked_binding()
        proxy_points.append({"label": label, "point": proxy_point,
            "text": proxy_text,
            "window_bounds": window_bounds,
            "binding_before": binding_before, "binding_after": binding_after})
        return proxy_point

    # Select and clear the prefilled value so the same input session proves an
    # empty intermediate draft followed by real nonempty system text input. Use
    # the OS focused proxy because the native editor may be covered by the IME.
    prefill_text = owner_action_baseline["value"]
    if not isinstance(prefill_text, str) or not prefill_text:
        raise ValueError("prefill_selection_owner_value_not_text")
    prefill_selection_range, selected_prefill, selected_prefill_raw, prefill_interaction = (
        select_full_text_keyboard(hdc, out, args, pid, checked_binding,
            checked_public_focus, app_window_id, "prefill", focused,
            lambda: hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'"),
            lambda: session.client.get_window_interaction().raw,
            mount, editor.semantic_id, prefill_text, args.selection_timeout_seconds))
    (out / "hilog_prefill_selected.txt").write_text(selected_prefill, encoding="utf-8")
    (out / "window_interaction_prefill_selected.raw.txt").write_text(
        selected_prefill_raw, encoding="utf-8")
    draft_baseline = selected_prefill
    _ui_input(hdc, out, args, pid, checked_binding, "prefill_delete",
        "uitest uiInput keyEvent 2055", allow_system_ime_overlay=True)
    bindings.append(checked_binding())
    _ = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
    # Real system input creates an unsaved live draft; public owner must stay unchanged.
    draft_point = current_ime_proxy_point("ime_proxy_initial_draft")
    _ui_input(hdc, out, args, pid, checked_binding, "initial_draft_input",
        f"uitest uiInput inputText {draft_point[0]} {draft_point[1]} {shlex.quote(args.draft)}",
        allow_system_ime_overlay=True)
    time.sleep(args.settle_seconds)
    bindings.append(checked_binding())
    draft_log = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
    (out / "hilog_draft.txt").write_text(draft_log, encoding="utf-8")
    lengths = assert_fresh_draft_change(
        draft_baseline.splitlines(), draft_log.splitlines(), pid, mount,
        require_empty_transition=True)
    owner_draft_response = session.client.get_context()
    owner_draft = normal.parse_owner(owner_draft_response, args.field, field_spec.resource_id)
    if owner_draft != owner_action_baseline:
        raise ValueError("live text draft changed public owner after the action baseline")
    selected, selected_log, selected_raw, interaction_before = (
        select_full_text_keyboard(hdc, out, args, pid, checked_binding,
            checked_public_focus, app_window_id, "draft", draft_log,
            lambda: hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'"),
            lambda: session.client.get_window_interaction().raw,
            mount, editor.semantic_id, args.draft, args.selection_timeout_seconds))
    (out / "hilog_selected.txt").write_text(selected_log, encoding="utf-8")
    (out / "window_interaction_selected.raw.txt").write_text(selected_raw, encoding="utf-8")
    selection_range = assert_live_selection(interaction_before, editor.semantic_id, selected)
    # The IME has resized the actual ArkUI XComponent while the unsaved draft
    # and its nonempty selection remain live. Read both sides of that transition.
    _, live_ime_bounds = _layout(hdc, out, "live_ime_resize", pid, args.bundle,
                                 allow_system_ime_overlay=True)
    owner_during_ime_resize = normal.parse_owner(
        session.client.get_context(), args.field, field_spec.resource_id)
    if owner_during_ime_resize != owner_action_baseline:
        raise ValueError("IME Surface resize changed public owner during live draft")
    assert_generated_draft(session.fields(), args.field, owner_action_baseline["value"],
                           expected_selection=selection_range)
    _capture(hdc, out, "live_ime_resize", pid, args.bundle)

    malformed = "GENERATED_UI_STRUCTURE 1\nEND\n"
    bindings.append(checked_binding())
    recorder.phase = "rejected_candidate"
    rejected = _submit(session, recorder, malformed, args.wait_ms, args.poll_ms, expect_accept=False)
    _capture(hdc, out, "rejected_panel", pid, args.bundle)
    interaction_rejected = parse_interaction(session.client.get_window_interaction().raw)
    assert_live_selection(interaction_rejected, editor.semantic_id, selection_range)
    # The previous draft remains fully selected after rejection. Delete that
    # selection first: UITest inputText taps the proxy and may collapse a
    # selection before inserting, which otherwise appends to the old draft.
    continuation_delete_baseline = selected_log
    _ui_input(hdc, out, args, pid, checked_binding, "continuation_delete",
        "uitest uiInput keyEvent 2055", allow_system_ime_overlay=True)
    time.sleep(args.settle_seconds)
    bindings.append(checked_binding())
    continuation_deleted_log = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
    (out / "hilog_continuation_deleted.txt").write_text(
        continuation_deleted_log, encoding="utf-8")
    continuation_deleted_lengths = assert_fresh_draft_change(
        continuation_delete_baseline.splitlines(), continuation_deleted_log.splitlines(),
        pid, mount, require_empty_transition=True, expected_final_length=0)
    try:
        (deleted_selection, continuation_deleted_log, continuation_deleted_interaction_raw,
         continuation_deleted_interaction) = wait_for_matching_selection(
                continuation_delete_baseline,
                lambda: hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'"),
                lambda: session.client.get_window_interaction().raw,
                pid, mount, editor.semantic_id, timeout_seconds=args.selection_timeout_seconds,
                check_binding=checked_binding, allow_empty=True)
    except SelectionAcceptanceTimeout as error:
        (out / "hilog_continuation_deleted_selection_timeout.txt").write_text(
            error.latest_hilog, encoding="utf-8")
        (out / "window_interaction_continuation_deleted_timeout.raw.txt").write_text(
            error.latest_interaction_raw, encoding="utf-8")
        (out / "continuation_delete_selection_timeout.json").write_text(json.dumps({
            "status": "not_accepted", "reason": str(error), "pid": pid,
            "mount": mount, "semantic_id": editor.semantic_id,
            "expected_range": [0, 0], "ime_range": error.event_range,
            "public_range": error.public_range,
        }, ensure_ascii=False, indent=2), encoding="utf-8")
        raise ValueError("continuation_delete_selection_acceptance_timeout: fresh same-mount [0,0) and public focus were not both observed") from error
    if deleted_selection != (0, 0):
        raise ValueError(f"continuation_delete_did_not_collapse_selection: {deleted_selection}")
    (out / "hilog_continuation_deleted.txt").write_text(
        continuation_deleted_log, encoding="utf-8")
    (out / "window_interaction_continuation_deleted.raw.txt").write_text(
        continuation_deleted_interaction_raw, encoding="utf-8")
    continuation_owner_response = session.client.get_context()
    (out / "continuation_owner_after_delete.raw.txt").write_text(
        continuation_owner_response.raw, encoding="utf-8")
    continuation_owner_after_delete = normal.parse_owner(
        continuation_owner_response, args.field, field_spec.resource_id)
    if continuation_owner_after_delete != owner_action_baseline:
        raise ValueError("continuation selection deletion changed the public owner")
    continuation_fields_response = session.client.request(session._query("GET_GENERATED_UI_FIELDS"))
    (out / "generated_fields_after_delete.raw.txt").write_text(
        continuation_fields_response.raw, encoding="utf-8")
    continuation_fields = parse_generated_fields(continuation_fields_response)
    owner_draft_source = assert_owner_backed_field_projection(
        continuation_fields_response.raw, args.field, owner_action_baseline["value"])
    empty_field_projections = [value for value in continuation_fields if value.field_id == args.field]
    if (len(empty_field_projections) != 1 or not empty_field_projections[0].focused or
            (empty_field_projections[0].selection_start,
             empty_field_projections[0].selection_end) != (0, 0)):
        raise ValueError("continuation deletion lost owner-backed focused field or collapsed public selection")
    continuation_deleted_layout, _ = _layout(
        hdc, out, "continuation_deleted", pid, args.bundle, allow_system_ime_overlay=True)
    continuation_deleted_layout_path = out / "continuation_deleted.json"
    continuation_deleted_layout_path.write_text(
        json.dumps(continuation_deleted_layout, ensure_ascii=False), encoding="utf-8")
    continuation_proxy_text = focused_ime_proxy_text(
        continuation_deleted_layout, editor.semantic_id, mount, continuation_deleted_log)
    _capture(hdc, out, "continuation_deleted", pid, args.bundle)
    (out / "continuation_draft_after_delete.json").write_text(json.dumps({
        "fresh_on_change_lengths": continuation_deleted_lengths,
        "ime_selection": deleted_selection,
        "public_selection": continuation_deleted_interaction["selection"],
        "field_id": args.field,
        "owner_backed_draft": empty_field_projections[0].draft,
        "applied": empty_field_projections[0].applied,
        "draft_source": owner_draft_source,
        "focused": empty_field_projections[0].focused,
        "native_proxy_text": continuation_proxy_text,
        "owner": continuation_owner_after_delete,
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    if continuation_proxy_text != "":
        raise ValueError(
            "continuation_empty_proxy_not_retained: invalid empty owner edit visibly restored " +
            f"platform proxy text {continuation_proxy_text!r}; inspect saved screenshot/layout")

    # Keep old panel operable after named rejection with a second draft.
    continuation_point = current_ime_proxy_point("ime_proxy_continuation")
    _ui_input(hdc, out, args, pid, checked_binding, "continuation_input",
        f"uitest uiInput inputText {continuation_point[0]} {continuation_point[1]} {shlex.quote(args.continuation)}",
        allow_system_ime_overlay=True)
    time.sleep(args.settle_seconds)
    bindings.append(checked_binding())
    continuation_log = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
    (out / "hilog_continuation.txt").write_text(continuation_log, encoding="utf-8")
    continuation_lengths = assert_fresh_draft_change(
        continuation_deleted_log.splitlines(), continuation_log.splitlines(), pid, mount,
        expected_final_length=utf16_length(args.continuation))
    interaction_continuation = parse_interaction(session.client.get_window_interaction().raw)
    owner_after_continuation_input = normal.parse_owner(
        session.client.get_context(), args.field, field_spec.resource_id)
    if owner_after_continuation_input != owner_action_baseline:
        raise ValueError("continuation draft input changed the public owner before commit")
    continuation_field = assert_generated_draft(
        session.fields(), args.field, owner_action_baseline["value"])
    selection_range, continuation_selected_log, continuation_selected_raw, interaction_continuation = (
        select_full_text_keyboard(hdc, out, args, pid, checked_binding,
            checked_public_focus, app_window_id, "continuation", continuation_log,
            lambda: hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'"),
            lambda: session.client.get_window_interaction().raw,
            mount, editor.semantic_id, args.continuation,
            args.selection_timeout_seconds))
    assert_live_selection(interaction_continuation, editor.semantic_id, selection_range)
    assert_full_text_selection(selection_range, args.continuation, "continuation")
    (out / "hilog_continuation_selected.txt").write_text(
        continuation_selected_log, encoding="utf-8")
    (out / "window_interaction_continuation_selected.raw.txt").write_text(
        continuation_selected_raw, encoding="utf-8")
    owner_continuation = normal.parse_owner(session.client.get_context(), args.field, field_spec.resource_id)
    if owner_continuation != owner_action_baseline: raise ValueError("rejected candidate changed owner/editor draft")
    assert_generated_draft(session.fields(), args.field, owner_action_baseline["value"],
                           expected_selection=selection_range)

    bindings.append(checked_binding())
    recorder.phase = "same_key_reorder"
    reorder_result = _submit(session, recorder, reorder, args.wait_ms, args.poll_ms, expect_accept=True)
    # UITest may expose only the system IME root after Select All/reorder. A
    # screenshot and WindowManager still bind this live keyboard to our window;
    # no coordinate action is attempted through the obscured app root.
    reorder_layout, reorder_component = _layout(
        hdc, out, "after_reorder", pid, args.bundle,
        allow_system_ime_overlay=True, allow_ime_only_root=True)
    if reorder_component is None:
        _check_ime_only_foreground(hdc, app_window_id, args.bundle, pid)
        checked_public_focus()
    moved_editor = accepted_instance(session.instances(), "editor", kind="textInput", field=args.field)
    if moved_editor.semantic_id != editor.semantic_id: raise ValueError("reorder changed editor identity")
    interaction_reordered = parse_interaction(session.client.get_window_interaction().raw)
    assert_live_selection(interaction_reordered, editor.semantic_id, selection_range)
    owner_reordered = normal.parse_owner(session.client.get_context(), args.field, field_spec.resource_id)
    if owner_reordered != owner_action_baseline:
        raise ValueError("same-key reorder changed public owner during live draft")
    reordered_field = assert_generated_draft(session.fields(), args.field, owner_action_baseline["value"],
                                               expected_selection=selection_range)
    # The accepted scene may consume the already-observed IME Surface size only
    # when the same-key candidate is published. Both bounds were read live from
    # the app XComponent; this later snapshot proves the new geometry was used.
    ime_resize = assert_ime_surface_resize(
        pre_ime_bounds, live_ime_bounds, pre_ime_snapshot, session.snapshot())
    _capture(hdc, out, "reordered", pid, args.bundle)

    # Commit the exact current continuation draft; read the public owner bytes back.
    submit_baseline = continuation_log
    bindings.append(checked_binding())
    _ui_input(hdc, out, args, pid, checked_binding, "commit_draft",
        "uitest uiInput keyEvent 2054", allow_system_ime_overlay=True,
        allow_ime_only_key=True, app_window_id=app_window_id,
        checked_public_focus=checked_public_focus)
    time.sleep(args.settle_seconds)
    bindings.append(checked_binding())
    submit_log = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'")
    selection.assert_fresh_submit(submit_baseline.splitlines(), submit_log.splitlines(), pid, mount)
    owner_after_response = session.client.get_context()
    owner_after = normal.parse_owner(owner_after_response, args.field, field_spec.resource_id)
    if owner_after["value"] != args.continuation or owner_after["version"] != owner_action_baseline["version"] + 1:
        raise ValueError("exact owner readback/version differs after final text commit")
    (out / "owner_before.raw.txt").write_text(context_before.raw, encoding="utf-8")
    (out / "owner_draft.raw.txt").write_text(owner_draft_response.raw, encoding="utf-8")
    (out / "owner_after.raw.txt").write_text(owner_after_response.raw, encoding="utf-8")
    _capture(hdc, out, "committed", pid, args.bundle)
    bindings.append(checked_binding())
    result = {"status": "passed", "bundle": args.bundle, "target": args.target, "pid": pid,
        "hap_sha256": hashlib.sha256(hap.read_bytes()).hexdigest(), "device_port": args.device_port,
        "v1_acceptance": v1_result, "reset_to_start": reset_to_start,
        "reset_after_swipe": reset_after_swipe, "swipe_owner_before": owner_touch_before,
        "swipe_owner_after": owner_touch_after, "single_action_owner": owner_after_action,
        "focus_mount": mount, "draft_lengths": lengths, "selection_utf16": selection_range,
        "ime_proxy_points": proxy_points,
        "generated_field_after_reorder": asdict(reordered_field),
        "rejected_candidate": rejected, "continuation_lengths": continuation_lengths,
        "reorder_acceptance": reorder_result,
        "ime_surface_resize": ime_resize,
        "post_reorder_uitest_ime_only": reorder_component is None,
        "owner_before": owner_before, "owner_after": owner_after,
        "binding_checks": bindings, "screenshots": ["screen_initial.jpeg", "screen_rejected_panel.jpeg",
            "screen_live_ime_resize.jpeg", "screen_reordered.jpeg", "screen_committed.jpeg"],
        "named_not_run": []}
    normal.write_json(out / "result.json", result)
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True); parser.add_argument("--bundle", required=True)
    parser.add_argument("--local-port", type=int, required=True); parser.add_argument("--device-port", type=int, required=True)
    parser.add_argument("--capability", required=True); parser.add_argument("--caller", required=True)
    parser.add_argument("--hap", type=Path, required=True); parser.add_argument("--identity", type=Path, required=True)
    parser.add_argument("--forward-receipt-json", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True); parser.add_argument("--reorder-candidate", type=Path, required=True)
    parser.add_argument("--field", required=True); parser.add_argument("--action", required=True)
    parser.add_argument("--draft", required=True); parser.add_argument("--continuation", required=True)
    parser.add_argument("--run-dir", type=Path, required=True); parser.add_argument("--hdc", default=normal.DEFAULT_HDC)
    parser.add_argument("--wait-ms", type=int, default=5000); parser.add_argument("--poll-ms", type=int, default=50)
    parser.add_argument("--settle-seconds", type=float, default=0.6)
    parser.add_argument("--selection-timeout-seconds", type=float, default=3.0,
                        help="bounded wait for fresh same-mount IME and matching public selection")
    args = parser.parse_args(argv)
    if not 0 <= args.settle_seconds <= 10: parser.error("--settle-seconds must be in 0..10")
    if not 0.1 <= args.selection_timeout_seconds <= 10:
        parser.error("--selection-timeout-seconds must be in 0.1..10")
    run_probe(args, Hdc(args.hdc, args.target))


if __name__ == "__main__":
    main()
