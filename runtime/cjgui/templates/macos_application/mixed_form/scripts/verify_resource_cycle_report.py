#!/usr/bin/env python3
"""Validate the bounded mixed-form resource-cycle rows emitted by the app."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


ROW_PREFIX = "CJGUI_RESOURCE_CYCLE "
GLOBAL_EFFECT_SCOPE = "observed_submissions_after_enable"
EXPECTED_LABELS = ["initial"] + [
    label
    for cycle in range(1, 11)
    for label in (f"active-{cycle}", f"drained-{cycle}")
] + ["final"]
REQUIRED_INTS = {
    "status",
    "schema",
    "active_sessions",
    "cache_entries",
    "cache_bytes",
    "cache_budget",
    "inflight",
    "pending",
    "committed_refs",
    "subscribers",
    "records",
    "decode_starts",
    "raw_subscribers",
    "live_allocations",
    "live_allocation_bytes",
    "windows",
    "scene",
    "submitted",
    "completed",
    "text_live",
    "reusable",
    "effect_live",
    "effect_cache",
    "effect_inflight",
    "global_effect_inflight_targets",
    "global_effect_inflight_bytes",
    "effect_passes",
    "generated_nodes",
    "effect_nodes",
    "scroll",
}


class ResourceCycleError(ValueError):
    pass


def parse_rows(text: str) -> list[dict[str, int | str]]:
    rows: list[dict[str, int | str]] = []
    for line_number, line in enumerate(text.splitlines(), 1):
        if not line.startswith(ROW_PREFIX):
            continue
        fields: dict[str, int | str] = {}
        for token in line[len(ROW_PREFIX) :].split():
            if "=" not in token:
                raise ResourceCycleError(f"line {line_number}: malformed token {token!r}")
            key, value = token.split("=", 1)
            if not re.fullmatch(r"[a-z][a-z0-9_]*", key) or key in fields:
                raise ResourceCycleError(f"line {line_number}: duplicate or invalid key {key!r}")
            if key in {"label", "image_state", "global_effect_scope"}:
                fields[key] = value
            else:
                try:
                    fields[key] = int(value, 10)
                except ValueError as error:
                    raise ResourceCycleError(
                        f"line {line_number}: {key} is not an integer"
                    ) from error
        missing = REQUIRED_INTS - fields.keys()
        missing_text = {"label", "image_state", "global_effect_scope"} - fields.keys()
        if missing or missing_text:
            raise ResourceCycleError(
                f"line {line_number}: missing fields {', '.join(sorted(missing | missing_text))}"
            )
        rows.append(fields)
    return rows


def _same(left: dict, right: dict, fields: tuple[str, ...], label: str) -> None:
    different = [field for field in fields if left[field] != right[field]]
    if different:
        raise ResourceCycleError(f"{label}: live state changed at {', '.join(different)}")


def _require_global_effect_drain(row: dict, label: str) -> None:
    if row["global_effect_inflight_targets"] != 0 or row["global_effect_inflight_bytes"] != 0:
        raise ResourceCycleError(f"{label}: global effect in-flight targets/bytes did not drain")


def verify_rows(rows: list[dict[str, int | str]]) -> dict[str, int | str]:
    labels = [str(row["label"]) for row in rows]
    if labels != EXPECTED_LABELS:
        raise ResourceCycleError(
            f"expected exactly 22 ordered rows ({EXPECTED_LABELS[0]} through final), got {labels}"
        )
    for row in rows:
        if row["status"] != 0 or row["schema"] != 1:
            raise ResourceCycleError(f"{row['label']}: native snapshot unavailable/schema mismatch")
        if row["cache_entries"] > 8 or row["cache_budget"] != 32 * 1024 * 1024:
            raise ResourceCycleError(f"{row['label']}: image cache entry/budget contract changed")
        if row["cache_bytes"] < 0 or row["cache_bytes"] > row["cache_budget"]:
            raise ResourceCycleError(f"{row['label']}: reusable image cache exceeds its byte budget")
        if row["records"] > 64:
            raise ResourceCycleError(f"{row['label']}: resource metadata record cap exceeded")
        if row["raw_subscribers"] < row["subscribers"]:
            raise ResourceCycleError(f"{row['label']}: raw subscribers cannot be below live subscribers")
        if row["text_live"] < 0 or row["effect_live"] < 0 or row["effect_inflight"] < 0:
            raise ResourceCycleError(f"{row['label']}: accepted live resource metric unavailable")
        if row["live_allocations"] < 0 or row["live_allocation_bytes"] < 0:
            raise ResourceCycleError(f"{row['label']}: live image allocation metric unavailable")
        if row["global_effect_inflight_targets"] < 0 or row["global_effect_inflight_bytes"] < 0:
            raise ResourceCycleError(f"{row['label']}: global effect in-flight metric unavailable")
        if row["global_effect_scope"] != GLOBAL_EFFECT_SCOPE:
            raise ResourceCycleError(f"{row['label']}: global effect observation scope mismatch")

    initial, final = rows[0], rows[-1]
    live_facts = (
        "active_sessions",
        "committed_refs",
        "subscribers",
        "raw_subscribers",
        "text_live",
        "effect_live",
        "effect_inflight",
        "windows",
        "scene",
        "image_state",
    )
    if initial["active_sessions"] <= 0 or initial["windows"] <= 0:
        raise ResourceCycleError("the warm anchor must remain alive for both boundary samples")
    if initial["committed_refs"] <= 0 or initial["image_state"] != "ready":
        raise ResourceCycleError("warm anchor has no accepted, ready image lease")
    if (initial["generated_nodes"] <= 0 or initial["effect_nodes"] <= 0 or
            initial["effect_passes"] <= 0 or initial["text_live"] <= 0):
        raise ResourceCycleError("warm anchor scene is missing generated text or effect resources")
    if initial["live_allocations"] <= 0 or initial["live_allocation_bytes"] <= 0:
        raise ResourceCycleError("warm anchor did not establish a live image allocation baseline")
    if initial["submitted"] <= 0 or initial["submitted"] != initial["completed"]:
        raise ResourceCycleError("warm anchor has no accepted completed frame baseline")
    _require_global_effect_drain(initial, "initial")
    _require_global_effect_drain(final, "final")
    _same(initial, final, live_facts, "initial/final")

    # Image textures can stay strongly owned by the bounded resident cache
    # after a transient window closes. Bound unique live allocations against
    # the warm anchor plus the native cache envelope instead of requiring zero
    # or exact baseline equality. One domain has an eight-entry cache; if the
    # reported budget represents several domains, scale the entry allowance by
    # the same 32 MiB per-domain budget.
    domain_count = max(1, (int(initial["cache_budget"]) + (32 * 1024 * 1024 - 1)) // (32 * 1024 * 1024))
    live_allocation_count_cap = int(initial["live_allocations"]) + 8 * domain_count
    live_allocation_bytes_cap = int(initial["live_allocation_bytes"]) + int(initial["cache_budget"])
    for row in rows:
        if row["live_allocations"] > live_allocation_count_cap:
            raise ResourceCycleError(f"{row['label']}: unique live image allocations grew beyond cache allowance")
        if row["live_allocation_bytes"] > live_allocation_bytes_cap:
            raise ResourceCycleError(f"{row['label']}: unique live image bytes grew beyond cache allowance")

    drained = [row for row in rows if str(row["label"]).startswith("drained-")]
    for row in drained:
        _require_global_effect_drain(row, str(row["label"]))
        _same(initial, row, live_facts, str(row["label"]))
        if row["inflight"] != 0 or row["pending"] != 0:
            raise ResourceCycleError(f"{row['label']}: image load queue did not drain")
        if row["submitted"] != row["completed"]:
            raise ResourceCycleError(f"{row['label']}: submitted frame has not completed")

    active = [row for row in rows if str(row["label"]).startswith("active-")]
    saw_new_live_allocation = False
    for row in active:
        if row["windows"] != initial["windows"] + 1:
            raise ResourceCycleError(f"{row['label']}: transient application window was not open")
        if row["active_sessions"] != initial["active_sessions"] + 1:
            raise ResourceCycleError(f"{row['label']}: native session was not observed")
        if row["committed_refs"] <= initial["committed_refs"]:
            raise ResourceCycleError(f"{row['label']}: accepted image lease was not observed")
        if row["raw_subscribers"] > initial["raw_subscribers"] + 8:
            raise ResourceCycleError(f"{row['label']}: transient raw-subscriber count is outside workload bound")
        if (row["text_live"] <= 0 or row["generated_nodes"] < 5 or row["effect_nodes"] <= 0 or
                row["effect_passes"] <= 0):
            raise ResourceCycleError(f"{row['label']}: generated text/effect workload is missing")
        if row["scroll"] <= 0 or row["image_state"] != "ready":
            raise ResourceCycleError(f"{row['label']}: generated image/scroll workload was not accepted")
        if row["live_allocations"] <= 0 or row["live_allocation_bytes"] <= 0:
            raise ResourceCycleError(f"{row['label']}: live image allocation is missing")
        saw_new_live_allocation = saw_new_live_allocation or row["live_allocations"] > initial["live_allocations"]

    if not saw_new_live_allocation:
        raise ResourceCycleError("ten cycles did not add any observed live image allocation")

    if final["decode_starts"] < initial["decode_starts"]:
        raise ResourceCycleError("cumulative image decode starts moved backwards")

    return {
        "cycles": 10,
        "initial_active_sessions": int(initial["active_sessions"]),
        "final_active_sessions": int(final["active_sessions"]),
        "max_cache_entries": max(int(row["cache_entries"]) for row in rows),
        "max_cache_bytes": max(int(row["cache_bytes"]) for row in rows),
        "max_records": max(int(row["records"]) for row in rows),
        "max_raw_subscribers": max(int(row["raw_subscribers"]) for row in rows),
        "max_live_allocations": max(int(row["live_allocations"]) for row in rows),
        "max_live_allocation_bytes": max(int(row["live_allocation_bytes"]) for row in rows),
        "global_effect_scope": GLOBAL_EFFECT_SCOPE,
        "max_global_effect_inflight_targets": max(int(row["global_effect_inflight_targets"]) for row in rows),
        "max_global_effect_inflight_bytes": max(int(row["global_effect_inflight_bytes"]) for row in rows),
        "decode_starts_delta": int(final["decode_starts"]) - int(initial["decode_starts"]),
    }


def verify_report(text: str) -> dict[str, int | str]:
    """Validate both the emitted sample rows and the producer's terminal state.

    A complete-looking row prefix is still a failed run if the consumer later
    refused a close or could not settle a resource. Failure samples deliberately
    use a separate prefix so partial raw evidence remains readable without being
    mistaken for one of the 22 acceptance rows.
    """
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    failures = [line for line in lines if line.startswith((
        "CJGUI_RESOURCE_CYCLE_FAILURE ", "CJGUI_RESOURCE_CYCLE_FAILED "))]
    if failures:
        raise ResourceCycleError(f"producer reported failure: {failures[-1]}")
    terminal = [line for line in lines if line.startswith("CJGUI_RESOURCE_CYCLE_RESULT ")]
    if terminal != ["CJGUI_RESOURCE_CYCLE_RESULT status=ok"]:
        raise ResourceCycleError("missing or malformed success terminal")
    return verify_rows(parse_rows(text))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path, help="normal app/test output containing resource-cycle rows")
    args = parser.parse_args(argv)
    try:
        result = verify_report(args.log.read_text(encoding="utf-8"))
    except (OSError, ResourceCycleError) as error:
        print(f"resource-cycle: FAIL: {error}", file=sys.stderr)
        return 1
    print(json.dumps({"status": "ok", **result}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
