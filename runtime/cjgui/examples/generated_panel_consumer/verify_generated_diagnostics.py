#!/usr/bin/env python3
"""Pair a normal generated window's diagnostic read with real public candidates."""

from __future__ import annotations

import sys
import time
from dataclasses import replace
from pathlib import Path

SOURCE_ROOT = Path(__file__).resolve().parents[2]
CORE_DIR = SOURCE_ROOT / "shared_operation_core"
if not CORE_DIR.is_dir():
    CORE_DIR = SOURCE_ROOT / "framework" / "cjgui" / "shared_operation_core"
if not CORE_DIR.is_dir():
    raise SystemExit("exported public generated client is missing")
sys.path.insert(0, str(CORE_DIR))

from cjgui_generated_client import GeneratedNode, GeneratedUiSession  # noqa: E402

LEGAL = "70,multiply,0,0,0,100,0:0|100:100;blur=8,unblurred"
INVALID = "50,screen,0,0,100,0,0:0|100:100"


def replace_group(nodes: tuple[GeneratedNode, ...], value: str) -> tuple[GeneratedNode, ...]:
    changed = False
    result = []
    for node in nodes:
        if node.key != "effectGroup":
            result.append(node)
            continue
        changed = True
        result.append(replace(node, properties=tuple(
            replace(prop, value=value) if prop.name == "effectGroup" else prop
            for prop in node.properties
        )))
    if not changed:
        raise AssertionError("accepted generated group is absent")
    return tuple(result)


def wait_log(path: Path, marker: str) -> str:
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        content = path.read_text(errors="replace") if path.exists() else ""
        matching = [line for line in content.splitlines() if line.startswith(marker)]
        if matching:
            return matching[-1]
        time.sleep(0.04)
    raise AssertionError(f"normal app did not emit {marker}: {path}")


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: verify_generated_diagnostics.py DESCRIPTOR GATE APP_LOG")
    descriptor, gate, app_log = sys.argv[1], sys.argv[2], Path(sys.argv[3])
    ready = wait_log(app_log, "CJGUI_GENERATED_DIAGNOSTIC_READY ")
    session = GeneratedUiSession.connect(descriptor)
    baseline = session.structure()
    legal_result = session.submit(replace_group(baseline.nodes, LEGAL), baseline.version)
    legal = session.wait_for_candidate_result(legal_result.ticket(), timeout_ms=8000, poll_ms=40)
    if legal.outcome != "terminal" or legal.last_state is None or legal.last_state.terminal_state != "ACCEPTED":
        raise AssertionError(f"legal public candidate not accepted: {legal}")
    accepted = session.structure()
    if accepted.version != legal.last_state.accepted_version:
        raise AssertionError("accepted public readback differs from candidate ticket")
    Path(gate + ".accepted").touch()
    app_accepted = wait_log(app_log, "CJGUI_GENERATED_DIAGNOSTIC_PHASE accepted")
    workload = wait_log(app_log, "CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=workload_observed ")
    if "ok=1" not in workload or "result=accepted" not in workload:
        raise AssertionError(f"generated workload observation failed: {workload}")
    expected_writes = int(workload.split("attempt_writes=")[1].split()[0])
    expected_scene = int(workload.split("scene=")[1].split()[0])
    public_progress = session.client.get_window_progress()
    public_reread = session.client.get_window_progress()
    if (public_progress.kind != "WINDOW_PROGRESS" or
            public_progress.value("WINDOW_WORKLOAD_STATUS") != ("enabled",) or
            public_progress.value("WINDOW_WORKLOAD_LAST_ATTEMPT_RESULT") != ("accepted",) or
            public_progress.integer("WINDOW_WORKLOAD_LAST_ATTEMPT_NODE_WRITES") != expected_writes or
            public_progress.integer("WINDOW_WORKLOAD_SCENE_VERSION") != expected_scene or
            public_progress.integer("WINDOW_ACCEPTED_SCENE_VERSION") != expected_scene or
            public_progress.integer("WINDOW_WORKLOAD_NODE_WRITES") < expected_writes or
            public_reread.integer("WINDOW_WORKLOAD_NODE_WRITES") !=
                public_progress.integer("WINDOW_WORKLOAD_NODE_WRITES") or
            public_reread.integer("WINDOW_WORKLOAD_NODE_CLONES") !=
                public_progress.integer("WINDOW_WORKLOAD_NODE_CLONES")):
        raise AssertionError(f"public workload disagrees with normal app: {public_progress.raw}")
    invalid_result = session.submit(replace_group(accepted.nodes, INVALID), accepted.version)
    invalid = session.wait_for_candidate_result(invalid_result.ticket(), timeout_ms=8000, poll_ms=40)
    if invalid.outcome != "terminal" or invalid.last_state is None or invalid.last_state.terminal_state != "REJECTED":
        raise AssertionError(f"invalid public candidate not rejected: {invalid}")
    if invalid.last_state.reason != "effect_group_value_invalid":
        raise AssertionError(f"unexpected rejection: {invalid.last_state.reason}")
    if session.structure() != accepted:
        raise AssertionError("rejected candidate changed accepted generated structure")
    Path(gate + ".rejected").touch()
    done = wait_log(app_log, "CJGUI_GENERATED_DIAGNOSTIC_DONE ")
    if "failed=0" not in done:
        raise AssertionError(f"normal app diagnostic assertion failed: {done}")
    if expected_writes < 1:
        raise AssertionError(f"accepted public candidate wrote no nodes: {workload}")
    disabled = wait_log(app_log, "CJGUI_GENERATED_DIAGNOSTIC_ASSERT name=workload_disabled ")
    if "ok=1" not in disabled:
        raise AssertionError(f"generated workload disabled state failed: {disabled}")
    print("CJGUI_GENERATED_DIAGNOSTIC_CLIENT PASS "
          f"ready=[{ready}] accepted=[{app_accepted}] "
          f"ticket={legal.last_state.terminal_state}/{invalid.last_state.terminal_state} "
          f"structure={baseline.version}->{accepted.version} "
          f"public_workload_writes={expected_writes} scene={expected_scene} done=[{done}]")


if __name__ == "__main__":
    main()
