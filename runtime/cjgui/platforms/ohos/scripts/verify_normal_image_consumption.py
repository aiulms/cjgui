#!/usr/bin/env python3
"""Normal-HAP image evidence over the public generated-UI and system UI paths.

Requires an already launched *normal* settings or thermo HAP, its exact HAP/PID
identity file and an owned target-bound hdc forward receipt. This script does
not install, launch, restart or create a forward. It records the handwritten
image's startup cold decode from the normal-PID renderer log. The public
"no_image" scene removes only the generated image; the handwritten one stays.
The first generated v1 reference usually hits that startup cache. Later steps
use the actual switch button, reject a stale version, accept the new one,
exercise Surface resize and clip the image through a public scroll parent.
Screenshots are inspected with JPEG tolerance and saved for visual review.
Public TCP duration is recorded only as public request duration, never as a
render/queue/decode duration. The 20 read-only GET_CONTEXT requests are joined
to current-PID transport owner-claim logs only when the complete alternating
request transcript has one unambiguous instance and continuous request IDs.
Reads do not cause scene acceptance.

The system-input check can be run with verify_normal_generated_gui_consumption.py
against the same accepted editor and identity. A fast normal HAP may finish its
decode before any public loading read; this run records that observation as such.
"""

from __future__ import annotations

import argparse
from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import re
import shutil
import sys
import time
import uuid
import zipfile

from PIL import Image

import verify_normal_generated_consumption as normal
import verify_normal_generated_gui_consumption as gui
from verify_normal_generated_gui_consumption import GuiHdc
from verify_same_pid_restart_probe import ui_button_center
from cjgui_generated_client import GeneratedUiSession


IMAGE = {
    "settings": ("settings-beacon", "name", "名称", "INCREMENT", "DECREMENT",
                 {1: ((17, 132, 173), (102, 241, 235)),
                  2: ((176, 44, 117), (255, 205, 70))}),
    "thermo": ("thermo-heat-map", "note", "备注", "TEMP_UP", "TEMP_DOWN",
               {1: ((194, 77, 24), (255, 204, 102)),
                2: ((22, 119, 151), (97, 238, 197))}),
}
NOT_OBSERVED = "not_observed"
PID_LINE = re.compile(r"^\S+\s+\S+\s+(\d+)\s+\d+\s+[A-Z]\s+")
COST_VALUE = re.compile(r"\b([A-Za-z]+)=(\d+)\b")
OWNER_CLAIM = re.compile(
    r"transport-cost stage=owner-claim instance=(ohos_transport_[0-9]+) "
    r"requestId=([1-9][0-9]*) op=(GET_CONTEXT_0|GET_GENERATED_UI_INSTANCES|OTHER) "
    r"queueUs=([0-9]+)$"
)


def candidate(app: str, version: int | None, *, clipped: bool = False) -> str:
    """Only logical, application-registered key/version cross the public wire."""
    key, field, label, *_ = IMAGE[app]
    lines = ["GENERATED_UI_STRUCTURE 1", "NODE 0 board vertical"]
    if clipped and version is None:
        raise ValueError("clipped candidate requires an image")
    if version is not None:
        if version not in (1, 2):
            raise ValueError("image version must be 1 or 2")
        if clipped:
            lines += ["NODE 1 crop scrollArea", "PROPERTY 1 crop fixedWidth 100",
                      "PROPERTY 1 crop fixedHeight 60", "NODE 2 canvas vertical"]
        # Scroll's direct content is laid out at the viewport width. The inner
        # vertical lets its fixed-width image remain 160px while the scroll
        # viewport adds the 100px clip constraint.
        depth = 3 if clipped else 1
        lines += [f"NODE {depth} icon image", f"PROPERTY {depth} icon resource {key}",
                  f"PROPERTY {depth} icon resourceVersion {version}",
                  f"PROPERTY {depth} icon contentMode fill", f"PROPERTY {depth} icon fixedWidth 160",
                  f"PROPERTY {depth} icon fixedHeight 72"]
    lines += [f"NODE 1 editor textInput field={field}",
              f"PROPERTY 1 editor label {label}", "END"]
    return "\n".join(lines)


def _near(pixel: tuple[int, ...], target: tuple[int, int, int], tolerance: int) -> bool:
    return all(abs(pixel[index] - target[index]) <= tolerance for index in range(3))


def inspect_palette(path: Path, rect: tuple[int, int, int, int], app: str,
                    version: int, mode: str, *, tolerance: int = 42) -> dict[str, object]:
    """Check two distinctive source colors inside measured screen bounds.

    Count a broad middle strip so antialiased edges and transparent corners do
    not turn a real JPEG screenshot into an exact-RGB false negative. Fit also
    requires largely empty 20px side bands for the 160x96 source in 160x72.
    """
    if mode not in ("fit", "fill") or app not in IMAGE or version not in (1, 2):
        raise ValueError("unknown image palette or geometry mode")
    x, y, width, height = rect
    with Image.open(path) as source:
        screen = source.convert("RGB")
        if (width <= 0 or height <= 0 or x < 0 or y < 0 or
                x + width > screen.width or y + height > screen.height):
            raise ValueError("image rect is outside the screenshot")
        main, aux = IMAGE[app][5][version]
        top = y + height // 4
        bottom = y + 3 * height // 4
        main_count = aux_count = margin_other = margin_total = 0
        for sy in range(top, bottom):
            for sx in range(x, x + width):
                pixel = screen.getpixel((sx, sy))
                is_main = _near(pixel, main, tolerance)
                is_aux = _near(pixel, aux, tolerance)
                main_count += int(is_main)
                aux_count += int(is_aux)
                if sx - x < width // 10 or sx - x >= width - width // 10:
                    margin_total += 1
                    margin_other += int(not is_main and not is_aux)
    area = width * max(1, bottom - top)
    margin_fraction = margin_other / margin_total if margin_total else 0.0
    passed = (main_count >= area * 0.04 and aux_count >= area * 0.04
              and (mode != "fit" or margin_fraction >= 0.9))
    return {"pass": passed, "screen_rect": rect, "mode": mode,
            "source_size": [160, 96], "main_rgb": main, "aux_rgb": aux,
            "jpeg_tolerance": tolerance, "main_pixels": main_count,
            "aux_pixels": aux_count,
            "side_margin_other_fraction": round(margin_fraction, 4)}


def inspect_parent_clip(path: Path, image_rect: tuple[int, int, int, int],
                        parent_rect: tuple[int, int, int, int], app: str,
                        version: int, *, tolerance: int = 42) -> dict[str, object]:
    """Prove a larger image is colored inside its parent and absent outside it."""
    ix, iy, iw, ih = image_rect
    px, py, pw, ph = parent_rect
    if (iw != 160 or ih != 72 or pw != 100 or ph != 60 or
            px != ix or py != iy or pw >= iw or ph >= ih):
        raise ValueError("accepted image/scroll parent do not form the expected clip")
    with Image.open(path) as source:
        screen = source.convert("RGB")
        if ix < 0 or iy < 0 or ix + iw > screen.width or iy + ih > screen.height:
            raise ValueError("clip evidence lies outside screenshot")
        main, aux = IMAGE[app][5][version]
        inside = outside = outside_total = 0
        for sy in range(py + ph // 4, py + 3 * ph // 4):
            for sx in range(px + 4, px + pw - 4):
                color = screen.getpixel((sx, sy))
                inside += int(_near(color, main, tolerance) or _near(color, aux, tolerance))
            # Exclude the JPEG blend at the exact clip edge and transparent PNG
            # corners. This band would show a large, unmistakable colored area
            # if the 160px child escaped the 100px parent.
            for sx in range(px + pw + 10, ix + iw - 5):
                color = screen.getpixel((sx, sy))
                outside += int(_near(color, main, tolerance) or _near(color, aux, tolerance))
                outside_total += 1
    inside_total = (pw - 8) * (ph // 2)
    inside_fraction = inside / inside_total
    outside_fraction = outside / outside_total if outside_total else 1.0
    return {"pass": inside_fraction >= 0.20 and outside_fraction <= 0.02,
            "image_rect": image_rect, "parent_rect": parent_rect,
            "inside_palette_fraction": round(inside_fraction, 4),
            "outside_palette_fraction": round(outside_fraction, 4),
            "outside_pixels": outside, "outside_total": outside_total,
            "jpeg_tolerance": tolerance}


def assess_resize(before, after, before_bounds: tuple[int, int, int, int],
                  after_bounds: tuple[int, int, int, int],
                  *, target_ratio: float) -> dict[str, object]:
    """Use both ArkUI bounds and the public accepted geometry revision."""
    if before_bounds[2] <= 0 or after_bounds[2] <= 0:
        raise ValueError("XComponent has no width")
    ratio = after_bounds[2] / before_bounds[2]
    if (after.window_geometry_revision == before.window_geometry_revision or
            after.window_accepted_scene_version <= before.window_accepted_scene_version or
            before.owner_pending_scene or after.owner_pending_scene or
            abs(ratio - target_ratio) > 0.04 or
            abs(after_bounds[3] - before_bounds[3]) > 4):
        raise ValueError("real XComponent resize and accepted geometry did not agree")
    return {"pass": True, "before_bounds": before_bounds, "after_bounds": after_bounds,
            "before_geometry_revision": before.window_geometry_revision,
            "after_geometry_revision": after.window_geometry_revision,
            "before_accepted_scene_version": before.window_accepted_scene_version,
            "after_accepted_scene_version": after.window_accepted_scene_version,
            "width_ratio": round(ratio, 4), "target_ratio": target_ratio}


def cost_record(stats: dict[str, int] | None) -> dict[str, int | str]:
    """No hidden renderer costs are inferred from transport round trips."""
    keys = ("decode_starts", "encoded_read_bytes", "decode_micros", "cache_hits",
            "in_flight", "queued", "awaiting", "ready_records", "resident_bytes",
            "bitmap_creates", "bitmap_destroys", "stale_discards")
    record: dict[str, int | str] = {
        key: stats.get(key, NOT_OBSERVED) if stats is not None else NOT_OBSERVED
        for key in keys
    }
    for key in ("read_micros", "in_flight_bytes", "peak_in_flight_bytes",
                "bitmap_create_micros", "bitmap_destroy_micros", "build_micros",
                "scene_submit_micros", "owner_queue_micros", "scene_accept_micros"):
        record[key] = NOT_OBSERVED
    return record


def parse_cost_snapshot(lines: list[str]) -> dict[str, int] | None:
    """Read the latest pair of normal-renderer frame counters from real hilog."""
    pending: dict[str, int] | None = None
    complete: dict[str, int] | None = None
    for line in lines:
        if "image-cost stage=frame " not in line:
            continue
        values = {name: int(value) for name, value in COST_VALUE.findall(line)}
        if "starts" in values:
            pending = values
        elif "resident" in values and pending is not None:
            complete = {**pending, **values}
            pending = None
    return complete


def startup_cold_cost(lines: list[str], app: str) -> dict[str, object]:
    """Identify the handwritten v1 decode at normal-HAP startup from native rows."""
    frames: list[dict[str, int]] = []
    pending: dict[str, int] | None = None
    for line in lines:
        if "image-cost stage=frame " not in line:
            continue
        values = {name: int(value) for name, value in COST_VALUE.findall(line)}
        if "starts" in values:
            pending = values
        elif "resident" in values and pending is not None:
            frames.append({**pending, **values})
            pending = None
    if app not in IMAGE:
        raise ValueError("unknown application for startup cost")
    decode_events = [line for line in lines if "image-cost stage=decode " in line and
                     "version=1 " in line and "ok=1" in line]
    bitmap_events = [line for line in lines if "image-cost stage=bitmap-create " in line and
                     "version=1 " in line and ("ok=1" in line or "ok=" not in line)]
    first = frames[0] if frames else None
    if (first is None or first.get("starts") != 1 or first.get("encoded", 0) <= 0 or
            first.get("hits") != 0 or not decode_events or not bitmap_events):
        return {"status": NOT_OBSERVED, **cost_record(None),
                "reason": "first normal-PID frame or exact v1 decode/bitmap event absent"}
    realized = next((frame for frame in frames if frame.get("starts") == 1 and
                     frame.get("bitmapCreates", 0) >= 1), None)
    if realized is None:
        return {"status": NOT_OBSERVED, **cost_record(None),
                "reason": "normal-PID v1 bitmap realization frame absent"}
    zeros = {name: 0 for name in ("starts", "encoded", "readUs", "decodeUs",
                                    "hits", "bitmapCreates", "bitmapDestroys",
                                    "bitmapCreateUs", "bitmapDestroyUs")}
    return {"status": "observed", **phase_cost(zeros, realized),
            "source": "first same-PID decode and bitmap frames before public candidates",
            "decode_events": decode_events, "bitmap_events": bitmap_events,
            "first_frame": first, "bitmap_frame": realized}


def resource_temperature(cost: dict[str, object]) -> str:
    starts, hits = cost.get("decode_starts"), cost.get("cache_hits")
    if isinstance(starts, int) and isinstance(hits, int):
        if starts > 0:
            return "new_decode"
        if hits > 0:
            return "cache_hit"
    return NOT_OBSERVED


def phase_cost(before: dict[str, int] | None,
               after: dict[str, int] | None) -> dict[str, object]:
    if before is None or after is None:
        return cost_record(None)

    def difference(key: str) -> int | str:
        if key not in before or key not in after:
            return NOT_OBSERVED
        delta = after[key] - before[key]
        if delta < 0:
            raise ValueError(f"image-cost counter {key} moved backward in one normal PID")
        return delta

    result = cost_record({
        "decode_starts": difference("starts"),
        "encoded_read_bytes": difference("encoded"),
        "decode_micros": difference("decodeUs"),
        "cache_hits": difference("hits"),
        "in_flight": after.get("running", NOT_OBSERVED),
        "queued": after.get("queued", NOT_OBSERVED),
        "awaiting": NOT_OBSERVED,
        "ready_records": NOT_OBSERVED,
        "resident_bytes": after.get("resident", NOT_OBSERVED),
        "bitmap_creates": difference("bitmapCreates"),
        "bitmap_destroys": difference("bitmapDestroys"),
        "stale_discards": NOT_OBSERVED,
    })
    result.update({
        "read_micros": difference("readUs"),
        "in_flight_bytes": after.get("activeBytes", NOT_OBSERVED),
        "peak_in_flight_bytes": after.get("peakActiveBytes", NOT_OBSERVED),
        "reservation_bytes": after.get("reservations", NOT_OBSERVED),
        "peak_tracked_bytes": after.get("peakTracked", NOT_OBSERVED),
        "idle_cache_bytes": after.get("idle", NOT_OBSERVED),
        "bitmap_create_micros": difference("bitmapCreateUs"),
        "bitmap_destroy_micros": difference("bitmapDestroyUs"),
        "counter_before": before, "counter_after": after,
    })
    return result


def _capture_cost(hdc: GuiHdc, out: Path, label: str,
                  pid: str) -> tuple[dict[str, int] | None, list[str]]:
    # The global hilog stream may contain unrelated binary payloads. Filter on
    # device before Hdc's UTF-8 decode; native image-cost rows are ASCII.
    raw = hdc.shell("hilog -x 2>/dev/null | grep -a 'image-cost stage=' || true",
                    timeout=45)
    rows = [line for line in raw.splitlines()
            if "image-cost stage=" in line and
            (match := PID_LINE.match(line)) and match.group(1) == pid]
    (out / f"image_cost_{label}.hilog.txt").write_text("\n".join(rows) + "\n", encoding="utf-8")
    return parse_cost_snapshot(rows), rows


def _capture_owner_claims(hdc: GuiHdc, out: Path, label: str,
                          pid: str, app: str) -> list[str]:
    """Archive current-PID claim logs without clearing the device's log buffer."""
    raw = hdc.shell("hilog -x 2>/dev/null | grep -a 'transport-cost stage=owner-claim' || true",
                    timeout=45)
    rows = [line for line in raw.splitlines()
            if "transport-cost stage=owner-claim" in line and
            (match := PID_LINE.match(line)) and match.group(1) == pid]
    (out / f"transport_claim_{label}.hilog.txt").write_text(
        "\n".join(rows) + "\n", encoding="utf-8")
    if hdc.pidof(normal.APP_CONTRACT[app][0]).strip() != pid:
        raise ValueError("owner_claim_pid_changed")
    return rows


def _parse_owner_claim(line: str, pid: str) -> dict[str, int | str]:
    header = PID_LINE.match(line)
    parsed = OWNER_CLAIM.search(line.strip())
    if header is None or header.group(1) != pid or parsed is None:
        raise ValueError("owner_claim_malformed_or_wrong_pid")
    instance, request_id, operation, queue_us = parsed.groups()
    return {"instance": instance, "request_id": int(request_id),
            "operation": operation, "owner_queue_us": int(queue_us)}


def correlate_owner_claims(before: list[str], after: list[str],
                           pid: str) -> list[dict[str, int | str]]:
    """Attribute 20 serial reads only if all 40 client commands have exact claims.

    The read is followed by an accepted-instance read each time. Requiring the
    whole uninterrupted server transcript rejects other callers and truncated
    hilog rather than guessing which identical GET_CONTEXT response owns a row.
    """
    if not before:
        raise ValueError("owner_claim_missing_baseline")
    if len(after) < len(before) or after[:len(before)] != before:
        raise ValueError("owner_claim_hilog_not_continuous")
    baseline = _parse_owner_claim(before[-1], pid)
    delta = after[len(before):]
    if len(delta) != 40:
        raise ValueError(f"owner_claim_count_expected_40_got_{len(delta)}")
    parsed = [_parse_owner_claim(line, pid) for line in delta]
    attributed: list[dict[str, int | str]] = []
    for index, claim in enumerate(parsed):
        expected_operation = ("GET_CONTEXT_0" if index % 2 == 0 else
                              "GET_GENERATED_UI_INSTANCES")
        if claim["instance"] != baseline["instance"]:
            raise ValueError("owner_claim_instance_changed")
        if claim["request_id"] != int(baseline["request_id"]) + index + 1:
            raise ValueError("owner_claim_request_id_gap_or_duplicate")
        if claim["operation"] != expected_operation:
            raise ValueError("owner_claim_operation_order_changed")
        if index % 2 == 0:
            attributed.append({"instance": str(claim["instance"]),
                               "request_id": int(claim["request_id"]),
                               "owner_queue_us": int(claim["owner_queue_us"])})
    return attributed


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _instance(instances, app: str, version: int):
    image = instances.instance("icon")
    if image is None or image.kind != "image" or not image.visible:
        raise ValueError("accepted generated image instance is absent")
    if image.resource != IMAGE[app][0] or image.resource_version != version:
        raise ValueError("accepted generated image binding changed")
    if image.bounds[2:] != (160, 72):
        raise ValueError(f"generated image bounds are not 160x72: {image.bounds!r}")
    return image


def _owner(session: GeneratedUiSession, app: str) -> dict[str, object]:
    _, field, _, _, _, _ = IMAGE[app]
    return normal.parse_owner(session.client.get_context(), field,
                              normal.APP_CONTRACT[app][2])


def _image_version(session: GeneratedUiSession, app: str) -> int:
    response = session.client.get_context()
    rows = [tokens for label, tokens in response.entries
            if label == "FIELD" and len(tokens) >= 4 and
            tokens[0] == str(normal.APP_CONTRACT[app][2]) and
            tokens[1] == "imageVersion" and tokens[2] == "INTEGER"]
    if len(rows) != 1 or not rows[0][3].isdigit():
        raise ValueError("owner imageVersion field is missing or ambiguous")
    return int(rows[0][3])


def _business_number(session: GeneratedUiSession, app: str) -> int:
    field = "count" if app == "settings" else "targetTemp"
    response = session.client.get_context()
    rows = [tokens for label, tokens in response.entries
            if label == "FIELD" and len(tokens) >= 4 and
            tokens[0] == str(normal.APP_CONTRACT[app][2]) and
            tokens[1] == field and tokens[2] == "INTEGER"]
    if len(rows) != 1 or not rows[0][3].lstrip("-").isdigit():
        raise ValueError(f"owner {field} field is missing or ambiguous")
    return int(rows[0][3])


def _capture(hdc: GuiHdc, out: Path, label: str, pid: str, app: str) -> Path:
    if hdc.pidof(normal.APP_CONTRACT[app][0]).strip() != pid:
        raise ValueError("PID changed before screenshot")
    remote = f"/data/local/tmp/cjgui-image-{uuid.uuid4().hex}.jpeg"
    local = out / f"screen_{label}.jpeg"
    try:
        hdc.shell(f"snapshot_display -f {remote}")
        hdc.pull(remote, local)
        if not local.is_file() or local.stat().st_size == 0:
            raise ValueError("device screenshot is empty")
    finally:
        hdc.shell(f"rm -f {remote}")
    return local


def _layout(hdc: GuiHdc, out: Path, label: str, pid: str, app: str) -> tuple[dict, tuple[int, int, int, int]]:
    if hdc.pidof(normal.APP_CONTRACT[app][0]).strip() != pid:
        raise ValueError("PID changed before UITest layout")
    remote = f"/data/local/tmp/cjgui-image-layout-{uuid.uuid4().hex}.json"
    local = out / f"layout_{label}.json"
    try:
        hdc.shell(f"uitest dumpLayout -p {remote}")
        hdc.pull(remote, local)
    finally:
        hdc.shell(f"rm -f {remote}")
    layout = json.loads(local.read_text(encoding="utf-8"))
    hits = []

    def walk(node):
        if not isinstance(node, dict):
            return
        attributes = node.get("attributes", {})
        if (isinstance(attributes, dict) and attributes.get("type") == "XComponent" and
                attributes.get("visible") == "true"):
            hits.append(attributes.get("bounds", ""))
        for child in node.get("children", []):
            walk(child)

    walk(layout)
    if len(hits) != 1:
        raise ValueError(f"unique visible XComponent absent: {hits!r}")
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", hits[0])
    if match is None:
        raise ValueError("XComponent bounds are malformed")
    x1, y1, x2, y2 = map(int, match.groups())
    if x2 <= x1 or y2 <= y1:
        raise ValueError("XComponent bounds have no area")
    return layout, (x1, y1, x2 - x1, y2 - y1)


def _phase(session: GeneratedUiSession, recorder: normal.ExchangeRecorder,
           out: Path, app: str, label: str, version: int | None,
           *, on_submitted=None, expect_accepted: bool = True,
           clipped: bool = False) -> dict[str, object]:
    recorder.phase = label
    before = session.structure()
    payload = candidate(app, version, clipped=clipped)
    (out / f"candidate_{label}.txt").write_text(payload, encoding="utf-8")
    started_ns = time.perf_counter_ns()
    submit = session.submit_text(payload, before.version)
    submitted_ms = normal.elapsed_ms(started_ns)
    if on_submitted is not None:
        on_submitted()
    wait = session.wait_for_candidate_result(submit.ticket(), timeout_ms=8000, poll_ms=30)
    state = wait.last_state
    after = session.structure()
    instances = session.instances()
    snapshot = session.snapshot()
    terminal = state.terminal_state if state is not None else NOT_OBSERVED
    accepted = bool(submit.candidate_accepted and wait.outcome == "terminal" and
                    terminal == "ACCEPTED" and state.scene_state == "scene_accepted" and
                    after.version == state.accepted_version and
                    snapshot.accepted_structure_version == after.version and
                    not snapshot.structure_candidate_pending and
                    not snapshot.owner_pending_scene)
    if accepted != expect_accepted:
        raise ValueError(f"{label}: candidate terminal did not match expectation: {terminal}")
    result = {"candidate_file": f"candidate_{label}.txt", "submit": asdict(submit),
              "ticket": asdict(state) if state else None, "wait_outcome": wait.outcome,
              "ticket_reads": wait.attempted, "public_submit_request_ms": submitted_ms,
              "accepted": accepted, "structure": asdict(after),
              "snapshot": asdict(snapshot), "instances": asdict(instances)}
    normal.write_json(out / f"phase_{label}.json", result)
    return result


def _ready(session: GeneratedUiSession, app: str, version: int,
           timeout_seconds: float = 8.0) -> tuple[object, list[str]]:
    deadline = time.monotonic() + timeout_seconds
    seen: list[str] = []
    while time.monotonic() < deadline:
        image = _instance(session.instances(), app, version)
        if image.resource_state not in seen:
            seen.append(image.resource_state)
        if image.resource_state == "ready":
            return image, seen
        if image.resource_state == "failed":
            raise ValueError("accepted image resource failed to load")
        time.sleep(0.03)
    raise TimeoutError(f"image {version} never became ready; states={seen!r}")


def _twenty_contexts(session: GeneratedUiSession, app: str,
                     out: Path, hdc: GuiHdc, pid: str) -> list[dict[str, object]]:
    before_claims = _capture_owner_claims(hdc, out, "before_twenty", pid, app)
    rows: list[dict[str, object]] = []
    try:
        for ordinal in range(1, 21):
            started_utc = normal.utc_now()
            started_ns = time.perf_counter_ns()
            response = session.client.get_context()
            response_utc = normal.utc_now()
            public_request_ms = normal.elapsed_ms(started_ns)
            owner = normal.parse_owner(response, IMAGE[app][1],
                                       normal.APP_CONTRACT[app][2])
            accepted_image = session.instances().instance("icon")
            row = {"ordinal": ordinal, "public_operation": "GET_CONTEXT 0",
                   "sent_utc": started_utc, "response_utc": response_utc,
                   "public_request_ms": public_request_ms,
                   "success": response.kind == "SNAPSHOT", "owner": owner,
                   "accepted_image_state_at_read": (accepted_image.resource_state
                                                    if accepted_image else "no_image"),
                   "image_state_read_utc": normal.utc_now(),
                   "scene_accept_ms": "not_applicable_read", "raw_response": response.raw}
            rows.append(row)
    finally:
        after_claims = _capture_owner_claims(hdc, out, "after_twenty", pid, app)
    if len(rows) != 20 or not all(row["success"] for row in rows):
        raise ValueError("twenty public reads were not all successful")
    claims = correlate_owner_claims(before_claims, after_claims, pid)
    (out / "transport_claim_twenty_delta.hilog.txt").write_text(
        "\n".join(after_claims[len(before_claims):]) + "\n", encoding="utf-8")
    for row, claim in zip(rows, claims):
        row["transport_instance"] = claim["instance"]
        row["transport_request_id"] = claim["request_id"]
        row["owner_queue_us"] = claim["owner_queue_us"]
        row["owner_queue_ms"] = round(int(claim["owner_queue_us"]) / 1000, 3)
        row["owner_queue_log"] = "transport_claim_twenty_delta.hilog.txt"
    (out / "twenty_public_requests.jsonl").write_text(
        "\n".join(json.dumps(row, ensure_ascii=False, sort_keys=True) for row in rows) + "\n",
        encoding="utf-8")
    return rows


def _write_actions(session: GeneratedUiSession, app: str,
                   out: Path) -> list[dict[str, object]]:
    result = []
    start_value = _business_number(session, app)
    for direction, action in ((1, IMAGE[app][3]), (-1, IMAGE[app][4])):
        before = _owner(session, app)
        business_before = _business_number(session, app)
        started_utc = normal.utc_now()
        started_ns = time.perf_counter_ns()
        response = session.invoke_action(action, [normal.APP_CONTRACT[app][2]],
                                         expected_version=before["version"])
        response_utc = normal.utc_now()
        public_request_ms = normal.elapsed_ms(started_ns)
        after = _owner(session, app)
        business_after = _business_number(session, app)
        applied = [tokens[0] for label, tokens in response.entries
                   if label == "APPLIED" and len(tokens) == 1]
        if (response.kind != "RESULT" or applied != ["true"] or
                after["version"] != before["version"] + 1 or
                business_after != business_before + direction):
            raise ValueError(f"public owner action failed: {action}")
        deadline = time.monotonic() + 8
        scene = session.snapshot()
        while scene.owner_pending_scene and time.monotonic() < deadline:
            time.sleep(0.03)
            scene = session.snapshot()
        if (scene.owner_pending_scene or scene.structure_candidate_pending or
                scene.window_accepted_scene_version <= 0):
            raise ValueError(f"public owner action scene did not settle: {action}")
        row = {"action": action, "sent_utc": started_utc,
               "response_utc": response_utc,
               "public_request_ms": public_request_ms,
               "owner_before": before, "owner_after": after,
               "business_before": business_before, "business_after": business_after,
               "scene_snapshot": asdict(scene),
               "owner_queue_ms": NOT_OBSERVED, "scene_accept_ms": NOT_OBSERVED,
               "raw_response": response.raw}
        result.append(row)
    if _business_number(session, app) != start_value:
        raise ValueError("two owner actions did not restore the business numeric field")
    normal.write_json(out / "owner_writes.json", result)
    return result


def _resize_once(session: GeneratedUiSession, recorder: normal.ExchangeRecorder,
                 hdc: GuiHdc, out: Path, app: str, pid: str,
                 before_snapshot, before_layout: dict,
                 before_bounds: tuple[int, int, int, int],
                 *, button: str, next_button: str, label: str,
                 target_ratio: float) -> tuple[dict[str, object], object, dict, tuple[int, int, int, int]]:
    recorder.phase = label
    center = ui_button_center(before_layout, button)
    if hdc.pidof(normal.APP_CONTRACT[app][0]).strip() != pid:
        raise ValueError("PID changed before real Surface resize")
    hdc.shell(f"uitest uiInput click {center[0]} {center[1]}")
    deadline = time.monotonic() + 8
    last = "new button, XComponent width or geometry revision absent"
    while time.monotonic() < deadline:
        layout, bounds = _layout(hdc, out, label, pid, app)
        snapshot = session.snapshot()
        try:
            ui_button_center(layout, next_button)
            measured = assess_resize(before_snapshot, snapshot, before_bounds,
                                     bounds, target_ratio=target_ratio)
            image = _instance(session.instances(), app, 2)
            if image.resource_state != "ready":
                last = f"image state after resize: {image.resource_state}"
                time.sleep(0.08)
                continue
        except (AssertionError, ValueError) as exc:
            last = str(exc)
            time.sleep(0.08)
            continue
        shot = _capture(hdc, out, label, pid, app)
        rect = (bounds[0] + image.bounds[0], bounds[1] + image.bounds[1],
                image.bounds[2], image.bounds[3])
        pixels = inspect_palette(shot, rect, app, 2, "fill")
        if not pixels["pass"]:
            raise ValueError(f"{label}: generated image lost v2 pixels after Surface resize")
        return ({"button": button, "button_center": center,
                 "layout_file": f"layout_{label}.json", "screenshot": shot.name,
                 "public_image": asdict(image), "generated_pixels": pixels,
                 "surface_geometry": measured, "snapshot": asdict(snapshot)},
                snapshot, layout, bounds)
    raise TimeoutError(f"{label}: real Surface resize did not settle: {last}")


def _surface_resize(session: GeneratedUiSession, recorder: normal.ExchangeRecorder,
                    hdc: GuiHdc, out: Path, app: str, pid: str,
                    xcomponent_origin: tuple[int, int]) -> dict[str, object]:
    baseline_layout, baseline_bounds = _layout(hdc, out, "resize_before", pid, app)
    if (abs(baseline_bounds[0] - xcomponent_origin[0]) > 4 or
            abs(baseline_bounds[1] - xcomponent_origin[1]) > 4):
        raise ValueError("measured XComponent origin conflicts with UITest layout")
    before = session.snapshot()
    narrow, after_narrow, narrow_layout, narrow_bounds = _resize_once(
        session, recorder, hdc, out, app, pid, before, baseline_layout, baseline_bounds,
        button="RESIZE→60%", next_button="RESIZE→100%", label="resize_60",
        target_ratio=0.6)
    wide, _after_wide, _wide_layout, _wide_bounds = _resize_once(
        session, recorder, hdc, out, app, pid, after_narrow, narrow_layout, narrow_bounds,
        button="RESIZE→100%", next_button="RESIZE→60%", label="resize_100",
        target_ratio=1 / 0.6)
    return {"status": "passed", "baseline_layout_file": "layout_resize_before.json",
            "baseline_xcomponent_bounds": baseline_bounds, "baseline_snapshot": asdict(before),
            "narrow": narrow, "restored": wide}


def run(args: argparse.Namespace, hdc: GuiHdc) -> dict[str, object]:
    if args.app not in IMAGE or args.device_port != normal.APP_CONTRACT[args.app][3]:
        raise ValueError("application/port mismatch")
    if args.switch_x < 0 or args.switch_y < 0:
        raise ValueError("real switch-button screen coordinates are required")
    if args.handwritten_rect[2:] != [160, 72]:
        raise ValueError("handwritten image rect must be the measured 160x72 fit node")
    out = Path(args.run_dir)
    out.mkdir(parents=True, exist_ok=False)
    try:
        result = _run(args, hdc, out)
        normal.write_json(out / "result.json", result)
        return result
    except Exception as exc:
        normal.write_json(out / "failure.json", {"error_type": type(exc).__name__,
                                                  "error": str(exc), "utc": normal.utc_now()})
        raise
    finally:
        normal.write_json(out / "hdc_commands.json", hdc.commands)


def _run(args: argparse.Namespace, hdc: GuiHdc, out: Path) -> dict[str, object]:
    hap = Path(args.hap)
    identity_raw = Path(args.identity).read_text(encoding="utf-8")
    pid = normal._identity(identity_raw, args.target, hap)
    receipt_raw = Path(args.forward_receipt_json).read_text(encoding="utf-8")
    receipt = json.loads(receipt_raw)
    binding_before = normal.check_binding(args, hdc, expected_pid=pid, receipt=receipt)
    (out / "identity.raw.txt").write_text(identity_raw, encoding="utf-8")
    (out / "forward_receipt.raw.json").write_text(receipt_raw, encoding="utf-8")
    contract = IMAGE[args.app]
    lab = "ohos_cjgui_app" if args.app == "settings" else "ohos_thermo_app"
    rawfile = Path(__file__).resolve().parents[5] / "labs" / lab / "entry/src/main/resources/rawfile"
    pngs = [rawfile / f"cjgui_image_v{version}.png" for version in (1, 2)]
    for png in pngs:
        shutil.copyfile(png, out / png.name)
    with zipfile.ZipFile(hap) as archive:
        packaged = {}
        native_libraries = {name: hashlib.sha256(archive.read(name)).hexdigest()
                            for name in archive.namelist() if name.endswith(".so")}
        for version in (1, 2):
            matches = [name for name in archive.namelist()
                       if name.endswith(f"cjgui_image_v{version}.png")]
            if len(matches) != 1:
                raise ValueError(f"HAP does not contain exactly one v{version} PNG")
            packaged[str(version)] = {"entry": matches[0],
                "sha256": hashlib.sha256(archive.read(matches[0])).hexdigest()}
            if packaged[str(version)]["sha256"] != _sha(pngs[version - 1]):
                raise ValueError("HAP PNG differs from the current application source")
    source_root = Path(__file__).resolve().parents[1]
    host = source_root / "host/ohos_renderer.cpp"
    manifest_paths = sorted((Path(__file__).resolve().parents[5] / "labs" / lab / "entry").glob("cjgui_sync_*.manifest"))
    if len(manifest_paths) != 1:
        raise ValueError("normal HAP has no unique current snapshot sync manifest")
    sdk_root = Path(args.sdk_root)
    sdk_files = [sdk_root / "sdk-pkg.json",
                 sdk_root / "openharmony/native/oh-uni-package.json",
                 sdk_root / "openharmony/toolchains/hdc"]
    sdk_identity = {str(path): {"sha256": _sha(path),
                                "bytes": path.stat().st_size}
                    for path in sdk_files if path.is_file()}
    identity = {"app": args.app, "target": args.target, "pid": pid,
                "hap": str(hap), "hap_sha256": _sha(hap),
                "png": packaged, "host_source": str(host), "host_source_sha256": _sha(host),
                "packaged_native_libraries_sha256": native_libraries,
                "snapshot_manifest": [{"path": str(p), "sha256": _sha(p)} for p in manifest_paths],
                "sdk_root": str(sdk_root), "sdk_files": sdk_identity,
                "sdk_root_exists": sdk_root.is_dir(),
                "device_image": {name: hdc.shell(command).strip() for name, command in {
                    "software_version": "param get const.product.software.version",
                    "api_version": "param get const.ohos.apiversion",
                    "uname": "uname -a"}.items()},
                "forward": binding_before}
    normal.write_json(out / "package_runtime_identity.json", identity)
    recorder = normal.ExchangeRecorder(out / "public_exchanges.jsonl")
    session = GeneratedUiSession.connect_forwarded_tcp(
        target=args.target, local_port=args.local_port, device_port=args.device_port,
        capability=args.capability, caller=args.caller)
    session.client = normal.RecordingClient(session.client.descriptor,
        session.client.fragment_bytes, session.client, recorder)
    capabilities = session.capabilities()
    if capabilities.image_resource(contract[0], 1) is None:
        raise ValueError("normal application did not publicly register v1 image")
    owner_initial = _owner(session, args.app)
    if _image_version(session, args.app) != 1:
        raise ValueError("normal application must start with image v1")
    phases = {}
    last_cost, last_cost_rows = _capture_cost(hdc, out, "baseline", pid)
    startup_cold = startup_cold_cost(last_cost_rows, args.app)
    startup_cold["raw_hilog_file"] = "image_cost_baseline.hilog.txt"
    normal.write_json(out / "startup_cold.json", startup_cold)

    def record_cost(label: str) -> dict[str, object]:
        nonlocal last_cost, last_cost_rows
        current, rows = _capture_cost(hdc, out, label, pid)
        measured = phase_cost(last_cost, current)
        measured["raw_hilog_file"] = f"image_cost_{label}.hilog.txt"
        continuous = rows[:len(last_cost_rows)] == last_cost_rows
        measured["hilog_continuous"] = continuous
        measured["new_decode_and_bitmap_events"] = ([line for line in rows[len(last_cost_rows):]
            if "stage=decode " in line or "stage=bitmap-" in line] if continuous else NOT_OBSERVED)
        last_cost = current
        last_cost_rows = rows
        return measured

    phases["no_image"] = _phase(session, recorder, out, args.app, "no_image", None)
    if session.instances().instance("icon") is not None:
        raise ValueError("no-image generated candidate retained an image instance")
    no_screen = _capture(hdc, out, "no_image", pid, args.app)
    phases["no_image"]["screenshot"] = no_screen.name
    phases["no_image"]["scope"] = "generated_region_only; handwritten v1 image remains"
    phases["no_image"]["native_cost"] = record_cost("no_image")
    request_rows: list[dict[str, object]] = []
    phases["cold"] = _phase(session, recorder, out, args.app, "cold", 1,
                            on_submitted=lambda: request_rows.extend(
                                _twenty_contexts(session, args.app, out, hdc, pid)))
    cold_image, cold_states = _ready(session, args.app, 1)
    cold_screen = _capture(hdc, out, "cold", pid, args.app)
    x0, y0 = args.xcomponent_screen_x, args.xcomponent_screen_y
    cold_rect = (x0 + cold_image.bounds[0], y0 + cold_image.bounds[1],
                 cold_image.bounds[2], cold_image.bounds[3])
    phases["cold"].update({"public_states": cold_states, "screenshot": cold_screen.name,
        "generated_pixels": inspect_palette(cold_screen, cold_rect, args.app, 1, "fill"),
        "native_cost": record_cost("cold")})
    phases["cold"]["resource_temperature"] = resource_temperature(phases["cold"]["native_cost"])
    phases["cold"]["scope"] = "first generated v1 reference; handwritten startup loaded v1"
    if not phases["cold"]["generated_pixels"]["pass"]:
        raise ValueError("cold generated image pixels do not match v1")
    phases["hot_clear"] = _phase(session, recorder, out, args.app, "hot_clear", None)
    if session.instances().instance("icon") is not None:
        raise ValueError("hot-clear generated candidate retained an image instance")
    phases["hot_clear"]["native_cost"] = record_cost("hot_clear")
    phases["hot"] = _phase(session, recorder, out, args.app, "hot", 1)
    hot_image, hot_states = _ready(session, args.app, 1)
    hot_screen = _capture(hdc, out, "hot", pid, args.app)
    hot_rect = (x0 + hot_image.bounds[0], y0 + hot_image.bounds[1],
                hot_image.bounds[2], hot_image.bounds[3])
    phases["hot"].update({"public_states": hot_states, "screenshot": hot_screen.name,
        "generated_pixels": inspect_palette(hot_screen, hot_rect, args.app, 1, "fill"),
        "native_cost": record_cost("hot")})
    phases["hot"]["resource_temperature"] = resource_temperature(phases["hot"]["native_cost"])
    if not phases["hot"]["generated_pixels"]["pass"]:
        raise ValueError("hot generated image pixels do not match v1")
    # Real system click. This does not call the public SWITCH_IMAGE action.
    recorder.phase = "real_switch_button"
    hdc.shell(f"uitest uiInput click {args.switch_x} {args.switch_y}")
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline:
        if (session.capabilities(refresh=True).image_resource(contract[0], 2) is not None
                and _image_version(session, args.app) == 2):
            break
        time.sleep(0.05)
    else:
        raise TimeoutError("real switch button did not publish image v2")
    old_accepted = _instance(session.instances(), args.app, 1)
    before_stale = session.structure()
    stale = phases["stale_v1"] = _phase(session, recorder, out, args.app, "stale_v1", 1,
                                        expect_accepted=False)
    if (stale["ticket"] is None or
            stale["ticket"]["reason"] != "image_resource_version_mismatch" or
            stale["structure"]["version"] != before_stale.version):
        raise ValueError("stale v1 was not rejected while old accepted stayed bound")
    retained_v1 = _instance(session.instances(), args.app, 1)
    stale_screen = _capture(hdc, out, "stale_v1_retained", pid, args.app)
    stale_rect = (x0 + retained_v1.bounds[0], y0 + retained_v1.bounds[1],
                  retained_v1.bounds[2], retained_v1.bounds[3])
    stale_pixels = inspect_palette(stale_screen, stale_rect, args.app, 1, "fill")
    if not stale_pixels["pass"]:
        raise ValueError("stale-version rejection did not retain old v1 pixels")
    phases["stale_v1"].update({"screenshot": stale_screen.name,
                                "retained_generated_pixels": stale_pixels,
                                "retained_instance": asdict(retained_v1)})
    # Reuse the existing normal-HAP UITest editor probe while the rejected
    # candidate has left the old accepted image and field binding in place.
    edit_args = argparse.Namespace(
        app=args.app, target=args.target, local_port=args.local_port,
        device_port=args.device_port, capability=args.capability, caller=args.caller,
        hap=hap, identity=args.identity, forward_receipt_json=args.forward_receipt_json,
        accepted_key="editor", field=contract[1], screen_x=None, screen_y=None,
        xcomponent_offset_x=x0, xcomponent_offset_y=y0,
        replacement=args.editor_replacement or f"图像验证{uuid.uuid4().hex[:8]}",
        settle_seconds=1.2, run_dir=out / "system_edit_after_rejection", hdc=args.hdc)
    edit_result = gui.run_probe(edit_args, hdc)
    if edit_result["status"] != "passed":
        raise ValueError("system editor readback after image rejection failed")
    phases["version_switch"] = _phase(session, recorder, out, args.app, "version_switch", 2)
    v2_image, v2_states = _ready(session, args.app, 2)
    v2_screen = _capture(hdc, out, "version_switch", pid, args.app)
    v2_rect = (x0 + v2_image.bounds[0], y0 + v2_image.bounds[1],
               v2_image.bounds[2], v2_image.bounds[3])
    phases["version_switch"].update({"public_states": v2_states,
        "screenshot": v2_screen.name,
        "generated_pixels": inspect_palette(v2_screen, v2_rect, args.app, 2, "fill"),
        "old_accepted_before_replacement": asdict(old_accepted),
        "stale_rejection": stale["ticket"], "native_cost": record_cost("version_switch")})
    phases["version_switch"]["resource_temperature"] = resource_temperature(
        phases["version_switch"]["native_cost"])
    if not phases["version_switch"]["generated_pixels"]["pass"]:
        raise ValueError("version-switch generated pixels do not match v2")
    handwritten = {}
    rect = tuple(args.handwritten_rect)
    for label, version, shot in (("no_image", 1, no_screen),
                                 ("cold", 1, cold_screen),
                                 ("version_switch", 2, v2_screen)):
        handwritten[label] = inspect_palette(shot, rect, args.app, version, "fit")
        if not handwritten[label]["pass"]:
            raise ValueError(f"handwritten fit image pixels failed in {label}")
    writes = _write_actions(session, args.app, out)
    resized = _surface_resize(session, recorder, hdc, out, args.app, pid, (x0, y0))
    resized["native_cost"] = record_cost("surface_resize")
    owner_before_clip = _owner(session, args.app)
    editor_before_clip = session.instances().instance("editor")
    if editor_before_clip is None or editor_before_clip.field_id != contract[1]:
        raise ValueError("editor binding absent before parent clip candidate")
    phases["parent_clip"] = _phase(session, recorder, out, args.app,
                                    "parent_clip", 2, clipped=True)
    clipped_image, clipped_states = _ready(session, args.app, 2)
    clipped_instances = session.instances()
    clip_parent = clipped_instances.instance("crop")
    editor_after_clip = clipped_instances.instance("editor")
    if (clip_parent is None or clip_parent.kind != "scrollArea" or
            not clip_parent.visible or editor_after_clip is None or
            editor_after_clip.field_id != editor_before_clip.field_id or
            editor_after_clip.node_id != editor_before_clip.node_id or
            editor_after_clip.semantic_id != editor_before_clip.semantic_id or
            _owner(session, args.app) != owner_before_clip):
        raise ValueError("parent clip candidate changed the long-lived editor/owner binding")
    _clip_layout, clip_surface_bounds = _layout(hdc, out, "parent_clip", pid, args.app)
    clip_screen = _capture(hdc, out, "parent_clip", pid, args.app)
    clip_origin = clip_surface_bounds[:2]
    clip_image_rect = (clip_origin[0] + clipped_image.bounds[0],
                       clip_origin[1] + clipped_image.bounds[1],
                       clipped_image.bounds[2], clipped_image.bounds[3])
    clip_parent_rect = (clip_origin[0] + clip_parent.bounds[0],
                        clip_origin[1] + clip_parent.bounds[1],
                        clip_parent.bounds[2], clip_parent.bounds[3])
    clip_pixels = inspect_parent_clip(clip_screen, clip_image_rect,
                                      clip_parent_rect, args.app, 2)
    if not clip_pixels["pass"]:
        raise ValueError("v2 image escaped its accepted 100x60 scroll parent")
    phases["parent_clip"].update({"public_states": clipped_states,
        "screenshot": clip_screen.name, "layout_file": "layout_parent_clip.json",
        "scroll_parent": asdict(clip_parent), "image": asdict(clipped_image),
        "editor_before": asdict(editor_before_clip), "editor_after": asdict(editor_after_clip),
        "owner_before": owner_before_clip, "owner_after": _owner(session, args.app),
        "clip_pixels": clip_pixels, "native_cost": record_cost("parent_clip")})
    binding_after = normal.check_binding(args, hdc, expected_pid=pid, receipt=receipt)
    loading_observed = ("loading" in cold_states or any(
        row["accepted_image_state_at_read"] == "loading" for row in request_rows))
    summary = {"status": "accepted", "identity": identity,
               "startup_cold": startup_cold,
               "owner_initial": owner_initial, "owner_writes": writes,
               "binding_after": binding_after, "phases": phases,
               "handwritten_fit": handwritten, "twenty_public_requests": request_rows,
               "surface_resize": resized,
               "system_edit_after_rejection": {
                   "status": edit_result["status"],
                   "run_dir": "system_edit_after_rejection",
                   "owner_before": edit_result["owner_before"],
                   "owner_after": edit_result["owner_after"]},
               "loading_observed_normal": loading_observed,
               "normal_loading_limitation": (None if loading_observed else
                   "decode completed before public polling; no loading claim"),
               "system_edit_while_loading": NOT_OBSERVED,
               "server_queue_and_scene_times": {
                   "owner_queue": "observed_for_20_read_requests",
                   "scene_accept": "not_applicable_to_read_requests"}}
    return summary


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", choices=sorted(IMAGE), required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--local-port", type=int, required=True)
    parser.add_argument("--device-port", type=int, required=True)
    parser.add_argument("--capability", required=True)
    parser.add_argument("--caller", default="normal-image-consumer")
    parser.add_argument("--hap", type=Path, required=True)
    parser.add_argument("--identity", type=Path, required=True)
    parser.add_argument("--forward-receipt-json", type=Path, required=True)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--xcomponent-screen-x", type=int, required=True)
    parser.add_argument("--xcomponent-screen-y", type=int, required=True)
    parser.add_argument("--handwritten-rect", type=int, nargs=4, required=True,
                        metavar=("X", "Y", "W", "H"))
    parser.add_argument("--switch-x", type=int, required=True)
    parser.add_argument("--switch-y", type=int, required=True)
    parser.add_argument("--sdk-root", type=Path, required=True)
    parser.add_argument("--editor-replacement")
    parser.add_argument("--hdc", default=normal.DEFAULT_HDC)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        result = run(args, GuiHdc(args.hdc, args.target))
    except Exception as exc:
        print(f"normal image consumption failed: {type(exc).__name__}: {exc}",
              file=sys.stderr)
        return 2
    print(json.dumps({"status": result["status"], "run_dir": str(args.run_dir)},
                     ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
