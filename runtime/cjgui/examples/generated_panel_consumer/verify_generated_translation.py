#!/usr/bin/env python3
"""Public generated client: discover, move, reject, clear and restore F11 geometry."""

from __future__ import annotations

from dataclasses import replace
from pathlib import Path
import sys

SOURCE_ROOT = Path(__file__).resolve().parents[2]
CORE_DIR = SOURCE_ROOT / "shared_operation_core"
if not CORE_DIR.is_dir():
    CORE_DIR = SOURCE_ROOT / "framework" / "cjgui" / "shared_operation_core"
sys.path.insert(0, str(CORE_DIR))

from cjgui_generated_client import GeneratedNode, GeneratedProperty, GeneratedUiSession  # noqa: E402


def require(value: bool, detail: str) -> None:
    if not value:
        raise AssertionError(detail)


def node(nodes: tuple[GeneratedNode, ...], key: str) -> GeneratedNode:
    return next(item for item in nodes if item.key == key)


def patch(nodes: tuple[GeneratedNode, ...], values: dict[str, dict[str, str | None]]) -> tuple[GeneratedNode, ...]:
    result: list[GeneratedNode] = []
    for item in nodes:
        changes = values.get(item.key)
        if changes is None:
            result.append(item)
            continue
        props = [prop for prop in item.properties if prop.name not in changes]
        props.extend(GeneratedProperty(name, value) for name, value in changes.items() if value is not None)
        result.append(replace(item, properties=tuple(props)))
    return tuple(result)


def submit(session: GeneratedUiSession, nodes: tuple[GeneratedNode, ...], version: int):
    attempt = session.submit(nodes, version)
    wait = session.wait_for_candidate_result(attempt.ticket(), timeout_ms=8_000, poll_ms=50)
    require(wait.outcome == "terminal" and wait.last_state is not None,
            f"candidate did not settle: {wait.outcome}")
    return attempt, wait.last_state


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: verify_generated_translation.py DESCRIPTOR_PATH", file=sys.stderr)
        return 2
    session = GeneratedUiSession.connect(argv[1])
    capabilities = session.capabilities(refresh=True)
    vertical = capabilities.component("vertical")
    require(vertical is not None, "missing vertical capability")
    for name in ("translateX", "translateY"):
        spec = next((item for item in vertical.properties if item.name == name), None)
        require(spec is not None and spec.value_type == "STRING" and spec.unit == "logical points" and
                spec.value_range == "[-1024,1024]; cumulative [-4096,4096]" and
                spec.semantics == "absent=inherit named style; empty=clear to 0" and
                spec.backend_support == "macOS; other backends unsupported",
                f"undiscoverable {name}: {spec!r}")
    accepted = session.structure()
    require(node(accepted.nodes, "effectGroup").property("translateX") == "0.25" and
            node(accepted.nodes, "effectGroup").property("translateY") == "0.5" and
            node(accepted.nodes, "gradientTitle").property("translateX") == "-0.75" and
            node(accepted.nodes, "taskCard").property("translateX") == "0.125",
            "normal generated window did not consume F11 declarations")
    initial_version = accepted.version
    owner_before = tuple((field.field_id, field.owner_resource_id, field.applied)
                         for field in session.fields())

    far_nodes = patch(accepted.nodes, {"effectGroup": {"translateX": "30.25", "translateY": "12.5"}})
    far_attempt, far_state = submit(session, far_nodes, accepted.version)
    require(far_attempt.candidate_accepted and far_state.terminal_state == "ACCEPTED",
            f"far translation was not accepted: {far_state}")
    far = session.structure()
    require(far.version == far_state.accepted_version and
            node(far.nodes, "effectGroup").property("translateX") == "30.25" and
            node(far.nodes, "effectGroup").property("translateY") == "12.5",
            "far accepted readback differs from ticket")

    invalid_nodes = patch(far.nodes, {"effectGroup": {"translateX": "1025"}})
    _invalid_attempt, invalid_state = submit(session, invalid_nodes, far.version)
    require(invalid_state.terminal_state == "REJECTED" and
            invalid_state.reason == "translation_value_invalid" and
            invalid_state.path.endswith("/translateX"),
            f"invalid translation was not rejected by name: {invalid_state}")
    refused_readback = session.structure()
    require(refused_readback.version == far.version and refused_readback.nodes == far.nodes,
            "invalid translation changed accepted generated structure")

    cleared_nodes = patch(far.nodes, {
        "effectGroup": {"translateX": "", "translateY": ""},
        "gradientTitle": {"translateX": None, "translateY": None},
        "taskCard": {"translateX": None, "translateY": None},
    })
    clear_attempt, clear_state = submit(session, cleared_nodes, far.version)
    require(clear_attempt.candidate_accepted and clear_state.terminal_state == "ACCEPTED",
            f"clear was not accepted: {clear_state}")
    cleared = session.structure()
    require(cleared.version == clear_state.accepted_version and
            node(cleared.nodes, "effectGroup").property("translateX") == "" and
            all(prop.name != "translateX" for prop in node(cleared.nodes, "taskCard").properties),
            "clear/absence was not retained in accepted readback")

    restore_attempt, restore_state = submit(session, accepted.nodes, cleared.version)
    require(restore_attempt.candidate_accepted and restore_state.terminal_state == "ACCEPTED",
            f"restore was not accepted: {restore_state}")
    restored = session.structure()
    owner_after = tuple((field.field_id, field.owner_resource_id, field.applied)
                        for field in session.fields())
    require(restored.nodes == accepted.nodes and restored.version == restore_state.accepted_version and
            owner_after == owner_before, "restore changed accepted structure or owner fields")
    print("CJGUI_EXTERNAL_TRANSLATION_PASS "
          f"version={initial_version}->{far.version}->{cleared.version}->{restored.version} "
          f"invalid={invalid_state.reason}@{invalid_state.path} owner_fields={len(owner_after)} "
          "group=0.25,0.5->30.25,12.5->clear->0.25,0.5")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
