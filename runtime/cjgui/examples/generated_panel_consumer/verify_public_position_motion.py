#!/usr/bin/env python3
"""Exercise one normal app's authorized accepted translation target over its public socket."""

from __future__ import annotations

import math
from pathlib import Path
import sys
import time

SOURCE_ROOT = Path(__file__).resolve().parents[2]
CORE_DIR = SOURCE_ROOT / "shared_operation_core"
if not CORE_DIR.is_dir():
    CORE_DIR = SOURCE_ROOT / "framework" / "cjgui" / "shared_operation_core"
sys.path.insert(0, str(CORE_DIR))

from client import SharedOperationClient  # noqa: E402


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def point(response, name: str) -> tuple[float, float]:
    values = response.value(name)
    require(len(values) == 2, f"invalid {name}: {response.raw!r}")
    result = (float(values[0]), float(values[1]))
    require(all(math.isfinite(value) for value in result), f"nonfinite {name}")
    return result


def read(client: SharedOperationClient, node_id: int):
    response = client.read_node_translation(node_id)
    require(response.kind == "NODE_TRANSLATION", f"position read: {response.raw!r}")
    require(response.integer("NODE_ID") == node_id, "wrong target identity")
    return response


def set_with_current_cas(client: SharedOperationClient, node_id: int,
                         target: tuple[float, float]):
    deadline = time.monotonic() + 2.0
    while time.monotonic() < deadline:
        current = read(client, node_id)
        result = client.set_node_translation(node_id, current.value("CAS")[0], *target)
        require(result.kind == "NODE_TRANSLATION_DECISION", f"set response: {result.raw!r}")
        if result.boolean("ADMITTED"):
            return current, result
        require(result.value("REASON") == ("version_conflict",), f"set rejected: {result.raw!r}")
        time.sleep(0.015)
    raise AssertionError("position CAS did not stabilize within two seconds")


def reject_unknown_with_current_cas(client: SharedOperationClient, node_id: int,
                                    baseline: tuple[float, float]):
    deadline = time.monotonic() + 2.0
    while time.monotonic() < deadline:
        current = read(client, node_id)
        result = client.set_node_translation(node_id, current.value("CAS")[0],
                                             baseline[0] + 18.0, baseline[1], "unknown.position")
        require(result.kind == "NODE_TRANSLATION_DECISION" and not result.boolean("ADMITTED"),
                f"invalid request admitted: {result.raw!r}")
        if result.value("REASON") == ("unknown_motion_reference",):
            after = read(client, node_id)
            require(after.integer("REQUEST_REVISION") == current.integer("REQUEST_REVISION") and
                    point(after, "REQUESTED") == point(current, "REQUESTED"),
                    "invalid request changed the position target")
            return
        require(result.value("REASON") == ("version_conflict",),
                f"invalid request had unexpected refusal: {result.raw!r}")
        time.sleep(0.015)
    raise AssertionError("unknown-reference refusal CAS did not stabilize within two seconds")


def wait_presented(client: SharedOperationClient, node_id: int,
                   target: tuple[float, float]):
    deadline = time.monotonic() + 5.0
    while time.monotonic() < deadline:
        current = read(client, node_id)
        actual = point(current, "PRESENTED")
        if actual == target and not current.boolean("ACTIVE") and not current.boolean("PENDING"):
            require(current.integer("ACCEPTED_REQUEST_REVISION") ==
                    current.integer("REQUEST_REVISION"), "target was not presented")
            return current
        time.sleep(0.015)
    raise AssertionError(f"position did not settle at {target}: {current.raw!r}")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: verify_public_position_motion.py DESCRIPTOR_PATH", file=sys.stderr)
        return 2
    client = SharedOperationClient.from_descriptor(argv[1])
    baseline_owner = client.get_context().integer("VERSION")
    deadline = time.monotonic() + 3.0
    targets = client.list_node_translations()
    while targets.kind == "NODE_TRANSLATION_TARGETS" and targets.integer("COUNT") == 0 and \
            time.monotonic() < deadline:
        time.sleep(0.015)
        targets = client.list_node_translations()
    require(targets.kind == "NODE_TRANSLATION_TARGETS" and targets.integer("COUNT") == 1,
            f"missing exact target: {targets.raw!r}")
    node_id = int(targets.value("TARGET")[0])
    initial = read(client, node_id)
    baseline = point(initial, "DECLARED")
    require(point(initial, "PRESENTED") == baseline, "initial presented point differs from declaration")
    reject_unknown_with_current_cas(client, node_id, baseline)

    forward = (baseline[0] + 18.0, baseline[1] + 9.0)
    old, admitted = set_with_current_cas(client, node_id, forward)
    stale = client.set_node_translation(node_id, old.value("CAS")[0], *forward)
    require(not stale.boolean("ADMITTED") and stale.value("REASON") == ("version_conflict",),
            "stale accepted request was replayed")
    at_forward = wait_presented(client, node_id, forward)
    backward = (baseline[0] - 12.0, baseline[1] + 3.0)
    _, _ = set_with_current_cas(client, node_id, backward)
    at_backward = wait_presented(client, node_id, backward)
    cleared = client.clear_node_translation(node_id, at_backward.value("CAS")[0])
    require(cleared.kind == "NODE_TRANSLATION_DECISION" and cleared.boolean("ADMITTED"),
            f"clear was rejected: {cleared.raw!r}")
    restored = wait_presented(client, node_id, baseline)
    require(client.get_context().integer("VERSION") == baseline_owner,
            "position motion changed business owner")
    require(at_forward.integer("SCENE") > initial.integer("SCENE") and
            at_backward.integer("SCENE") > at_forward.integer("SCENE") and
            restored.integer("SCENE") >= at_backward.integer("SCENE"),
            "accepted scene did not follow position operations")
    print("CJGUI_PUBLIC_POSITION_MOTION_PASS "
          f"session={initial.value('SESSION')[0]} node={node_id} "
          f"scene={initial.integer('SCENE')}->{at_forward.integer('SCENE')}"
          f"->{at_backward.integer('SCENE')}->{restored.integer('SCENE')} "
          f"owner={baseline_owner} point={baseline}->{forward}->{backward}->{baseline}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
