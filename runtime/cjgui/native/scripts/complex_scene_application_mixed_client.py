#!/usr/bin/env python3
"""Public-client half of the complex-scene application acceptance probe.

The Cangjie program owns the two actual windows and local AppKit input.  This
client knows only the private descriptor issued by that program, and sends
regular shared-operation protocol requests over its UDS endpoint.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "shared_operation_core"))

from client import SharedOperationArgument, SharedOperationClient, TextReplacement  # noqa: E402


PRIMARY = 8601
SECONDARY = 8602
BATCHES = 30


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def full_document(client: SharedOperationClient, document_id: int, version: int) -> str:
    snapshot = client.get_context([document_id])
    require(snapshot.kind == "SNAPSHOT", f"document {document_id} length snapshot was unavailable")
    byte_length = None
    for values in snapshot.values("FIELD"):
        if len(values) == 4 and values[0] == str(document_id) and values[1] == "byteLength" and values[2] == "INTEGER":
            byte_length = int(values[3])
            break
    require(byte_length is not None, f"document {document_id} has no public byteLength")
    response = client.read_range(document_id, 0, byte_length, version)
    require(response.kind == "RANGE", f"document {document_id} did not return a RANGE")
    require(response.boolean("AVAILABLE"), f"document {document_id} range was unavailable")
    return response.text("CONTENT_UTF8_HEX")


def last_sixteen_line_replacements(content: str, batch: int) -> list[TextReplacement]:
    encoded = content.encode("utf-8")
    lines = content.splitlines(keepends=True)
    require(len(lines) >= 16, "primary document no longer has sixteen rows")
    offsets: list[int] = []
    offset = 0
    for line in lines:
        offsets.append(offset)
        offset += len(line.encode("utf-8"))
    replacements: list[TextReplacement] = []
    for ordinal in range(len(lines) - 16, len(lines)):
        original = lines[ordinal]
        ending = "\n" if original.endswith("\n") else ""
        body_width = len(original.encode("utf-8")) - len(ending.encode("utf-8"))
        marker = f"batch-{batch:02d}-screen-off-{ordinal:02d}"
        replacement_body = marker.ljust(body_width, ".")[:body_width]
        start = offsets[ordinal]
        end = start + len(original.encode("utf-8"))
        replacements.append(TextReplacement(start, end, replacement_body + ending))
    require(replacements[-1].end <= len(encoded), "replacement range escaped primary document")
    return replacements


def target_set(response) -> set[str]:
    require(response.kind == "WINDOW_TARGETS", "window target enumeration failed")
    expected_count = response.integer("WINDOW_TARGETS")
    targets = {values[0] for values in response.values("WINDOW_TARGET") if len(values) == 1}
    require(len(targets) == expected_count, "window target enumeration has duplicate or malformed entries")
    return targets


def check_targeted_window_state(client: SharedOperationClient, target: str, expected_targets: set[str]) -> dict[str, int | str]:
    require(target in expected_targets, f"declared target {target} was not enumerated")
    context = client.get_window_context(target)
    progress = client.get_window_progress(target)
    require(context.kind == "SNAPSHOT", f"context for {target} did not return snapshot")
    require(context.value("WINDOW_TARGET") == (target,), f"context fell through from {target}")
    require(progress.kind == "WINDOW_PROGRESS", f"progress for {target} did not return window progress")
    require(progress.value("WINDOW_TARGET") == (target,), f"progress fell through from {target}")
    require(context.value("WINDOW_PROJECTION") == ("ACTIVE",), f"context projection inactive for {target}")
    require(progress.value("WINDOW_PROJECTION") == ("ACTIVE",), f"progress projection inactive for {target}")
    accepted = progress.integer("WINDOW_ACCEPTED_SCENE_VERSION")
    submitted = progress.integer("WINDOW_SUBMITTED_SCENE_VERSION")
    require(accepted > 0 and submitted > 0 and submitted <= accepted, f"invalid progress for {target}")
    return {"target": target, "accepted": accepted, "submitted": submitted}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("descriptor")
    parser.add_argument("primary_target")
    parser.add_argument("secondary_target")
    args = parser.parse_args()

    operation = SharedOperationClient.from_descriptor(args.descriptor)
    expected_targets = {args.primary_target, args.secondary_target}
    initial_targets = target_set(operation.get_window_targets())
    require(initial_targets == expected_targets, f"unexpected initial targets: {sorted(initial_targets)}")
    initial_primary = check_targeted_window_state(operation, args.primary_target, initial_targets)
    initial_secondary = check_targeted_window_state(operation, args.secondary_target, initial_targets)
    version = 0
    emitted: list[dict[str, int]] = []
    for batch in range(1, BATCHES + 1):
        content = full_document(operation, PRIMARY, version)
        response = operation.invoke(
            version,
            "REPLACE_RANGES",
            [PRIMARY],
            [SharedOperationArgument.text_replacements("replacements", last_sixteen_line_replacements(content, batch))],
        )
        require(response.kind == "RESULT" and response.boolean("APPLIED"), f"batch {batch} was not applied")
        require(not response.boolean("CONFLICT"), f"batch {batch} returned conflict")
        require(response.integer("VERSION_BEFORE") == version, f"batch {batch} has wrong before version")
        version = response.integer("VERSION_AFTER")
        require(version == batch, f"batch {batch} has wrong after version {version}")
        emitted.append({"batch": batch, "version_after": version})

    payload = {
        "initial_primary": initial_primary,
        "initial_secondary": initial_secondary,
        "batches": emitted,
        "expected_targets": sorted(expected_targets),
    }
    print("CJGUI_COMPLEX_MIXED_PUBLIC_BATCHES " + json.dumps(payload, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # Surface an audit-friendly failure in the raw client log.
        print(f"CJGUI_COMPLEX_MIXED_PUBLIC_FAILURE {exc}", file=sys.stderr)
        raise SystemExit(1)
