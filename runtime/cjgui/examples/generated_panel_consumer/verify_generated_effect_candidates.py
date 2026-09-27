#!/usr/bin/env python3
"""Exercise generated effect groups through the application's public client.

The script discovers the value contract, reads the app's accepted generated
description, submits effect-group candidates, and waits on each candidate's own
ticket. It never calls the consumer holder or a UI callback.

Usage:
    python3 verify_generated_effect_candidates.py <DESCRIPTOR_PATH>
"""

from __future__ import annotations

import sys
from dataclasses import replace
from pathlib import Path

SOURCE_ROOT = Path(__file__).resolve().parents[2]
CORE_DIR = SOURCE_ROOT / "shared_operation_core"
if not CORE_DIR.is_dir():
    CORE_DIR = SOURCE_ROOT / "framework" / "cjgui" / "shared_operation_core"
if not CORE_DIR.is_dir():
    raise SystemExit("generated effect verifier: exported public client is missing")
sys.path.insert(0, str(CORE_DIR))

from cjgui_generated_client import GeneratedNode, GeneratedUiSession  # noqa: E402

LEGAL_INITIAL = "50,normal,0,0,100,0,0:0|100:100"
LEGAL_MULTIPLY = "70,multiply,0,0,0,100,0:0|100:100"
LEGAL_RECOVERY = "65,normal,0,0,100,0,0:0|100:100"
LEGAL_BLUR_ON = "65,normal,0,0,100,0,0:0|100:100;blur=8,unblurred"
LEGAL_BLUR_OFF = LEGAL_RECOVERY
INVALID_RANGE = "50,normal,101,0,100,0,0:0|100:100"
UNKNOWN_MODE = "50,screen,0,0,100,0,0:0|100:100"
INVALID_BLUR_RADIUS = "65,normal,0,0,100,0,0:0|100:100;blur=17,unblurred"
INVALID_BLUR_FALLBACK = "65,normal,0,0,100,0,0:0|100:100;blur=8,drop"


def replace_group(nodes: tuple[GeneratedNode, ...], value: str) -> tuple[GeneratedNode, ...]:
    updated: list[GeneratedNode] = []
    found = False
    for node in nodes:
        if node.key != "effectGroup":
            updated.append(node)
            continue
        properties = tuple(
            replace(prop, value=value) if prop.name == "effectGroup" else prop
            for prop in node.properties
        )
        if not any(prop.name == "effectGroup" for prop in node.properties):
            raise AssertionError("accepted effectGroup node has no effectGroup property")
        updated.append(replace(node, properties=properties))
        found = True
    if not found:
        raise AssertionError("accepted generated structure has no effectGroup node")
    return tuple(updated)


def submit_and_wait(session: GeneratedUiSession, nodes: tuple[GeneratedNode, ...], version: int):
    result = session.submit(nodes, version)
    ticket = result.ticket()
    wait = session.wait_for_candidate_result(ticket, timeout_ms=8_000, poll_ms=50)
    if wait.outcome != "terminal" or wait.last_state is None:
        raise AssertionError(f"ticket {ticket.token} did not reach a terminal state: {wait.outcome}")
    return result, wait.last_state


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_card_inside_group(nodes: tuple[GeneratedNode, ...]) -> None:
    parent_keys: list[str] = []
    card_inside_group = False
    for node in nodes:
        parent_keys = parent_keys[: node.depth]
        if node.key == "taskCard":
            card_inside_group = "effectGroup" in parent_keys
        if len(parent_keys) == node.depth:
            parent_keys.append(node.key)
        else:
            parent_keys[node.depth] = node.key
    require(card_inside_group, "registered task-edit composite is outside the effect group")


def read_group_child_owners(session: GeneratedUiSession, accepted_version: int) -> str:
    """Read the accepted composite bindings and their live owner fields."""
    instances = session.instances()
    require(instances.structure_version == accepted_version,
            "group child instances do not belong to the accepted scene version")
    fields = {field.field_id: field for field in session.fields()}
    capabilities = session.capabilities()
    summaries: list[str] = []
    for element, field_id, writer in (
        ("title", "title", "SET_TITLE"),
        ("notes", "notes", "SET_NOTES"),
    ):
        instance = instances.instance("taskCard", element)
        require(instance is not None, f"accepted composite element {element} is missing")
        require(instance.role == "field" and instance.field_id == field_id and instance.action == "EDIT_TEXT",
                f"accepted composite element {element} lost its {field_id} edit binding: {instance!r}")
        field_spec = capabilities.field(field_id)
        require(field_spec is not None and field_spec.writer == writer,
                f"public field {field_id} lost its {writer} owner writer")
        field = fields.get(field_id)
        require(field is not None, f"owner did not publish the {field_id} field")
        require(field.available is True and field.owner_resource_id > 0,
                f"owner readback for {field_id} is not available or lacks its target")
        summaries.append(
            f"{element}:{field_id}:{writer}:target={field.owner_resource_id}:applied={field.applied!r}")
    return "|".join(summaries)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: verify_generated_effect_candidates.py DESCRIPTOR_PATH", file=sys.stderr)
        return 2

    session = GeneratedUiSession.connect(argv[1])
    capabilities = session.capabilities(refresh=True)
    vertical = capabilities.component("vertical")
    if vertical is None:
        raise AssertionError("public directory did not publish vertical")
    group_spec = next((item for item in vertical.properties if item.name == "effectGroup"), None)
    if group_spec is None:
        raise AssertionError("public vertical directory did not publish effectGroup")
    require(group_spec.value_type == "STRING", "effectGroup is not published as STRING")
    require(group_spec.max_length >= len(LEGAL_BLUR_ON),
            "public effectGroup limit is too short for the discovered blur form")
    require(group_spec.encoding ==
            "opacityPercent,mode,maskOrNone(sx,sy,ex,ey,pos:alpha|...);blur=radiusPoints,unblurred",
            f"effectGroup encoding was not discovered: {group_spec.encoding!r}")
    require(group_spec.unit == "wire_percent_0..100,normalized_0..1,blur_radius_logical_points",
            f"effectGroup units were not discovered: {group_spec.unit!r}")
    require(group_spec.value_range ==
            "opacity:0..1,blend:normal|multiply,mask_coordinate:0..1,mask_position:0..1,"
            "mask_alpha:0..1,mask_stops:2..4,target_edge:4096,target_pixels:4194304,"
            "total_budget_bytes:100663296,groups:16,depth:4,backdrop_blur_radius_points:0..16,"
            "backdrop_blur_fallback:unblurred",
            f"effectGroup bounds were not discovered: {group_spec.value_range!r}")
    require(group_spec.semantics ==
            "none_or_empty=clear,absent=inherit,mask=sx,sy,ex,ey,pos:alpha|...,stops=2..4,"
            "blur=radiusPoints,unblurred",
            f"effectGroup clear/inherit semantics were not discovered: {group_spec.semantics!r}")
    require(group_spec.stability == "experimental",
            f"effectGroup stability was not discovered: {group_spec.stability!r}")
    require(group_spec.backend_support ==
            "macos:supported,ohos:unpublished_snapshot;backdrop_blur=macos:experimental_supported,"
            "ohos:unpublished_snapshot",
            f"effectGroup backend support was not discovered: {group_spec.backend_support!r}")
    require(any(spec.kind == "taskEditCard" for spec in capabilities.composites),
            "public directory did not publish the registered task-edit composite")

    baseline = session.structure()
    group_node = next((node for node in baseline.nodes if node.key == "effectGroup"), None)
    if group_node is None or group_node.kind != "vertical":
        raise AssertionError("normal app did not expose a generated vertical effect group")
    require(group_node.property("effectGroup") == LEGAL_INITIAL,
            "normal app's accepted group does not match its discovered legal declaration")

    # The composite task editor must be a descendant of the effect group in the
    # accepted generated tree.
    require_card_inside_group(baseline.nodes)

    # A valid external candidate must settle ACCEPTED on its own endpoint-bound
    # ticket, with the submitted value present in the accepted readback.
    legal, legal_state = submit_and_wait(session,
        replace_group(baseline.nodes, LEGAL_MULTIPLY), baseline.version)
    require(legal.candidate_accepted, f"legal candidate was refused: {legal.reason} {legal.path}")
    require(legal_state.terminal_state == "ACCEPTED",
            f"legal ticket terminal state was {legal_state.terminal_state}")
    accepted = session.structure()
    require(accepted.version == legal_state.accepted_version,
            "accepted readback version differs from the legal ticket")
    require(next(node for node in accepted.nodes if node.key == "effectGroup").property("effectGroup") == LEGAL_MULTIPLY,
            "accepted readback did not carry the external group declaration")
    require_card_inside_group(accepted.nodes)
    owner_readback = read_group_child_owners(session, accepted.version)

    failures: list[tuple[str, str, str]] = []
    for label, value in (("invalid_range", INVALID_RANGE), ("unknown_mode", UNKNOWN_MODE)):
        _result, state = submit_and_wait(session, replace_group(accepted.nodes, value), accepted.version)
        require(state.terminal_state == "REJECTED",
                f"{label} ticket terminal state was {state.terminal_state}")
        require(state.reason == "effect_group_value_invalid",
                f"{label} rejection reason was {state.reason!r}")
        require(state.path.endswith("/effectGroup"),
                f"{label} rejection did not identify the effectGroup property: {state.path!r}")
        failures.append((label, state.reason, state.path))
        unchanged = session.structure()
        require(unchanged.version == accepted.version,
                f"{label} changed the accepted structure version")
        require(unchanged.nodes == accepted.nodes,
                f"{label} changed the old accepted panel")
        # These accepted controls and the composite are the extant interactive
        # panel surface after a rejected external candidate.
        keys = {node.key for node in unchanged.nodes}
        require({"effectToggle", "effectRemove", "effectRestore", "taskCard"} <= keys,
                f"{label} lost the generated controls or composite from the panel")

    recovered, recovery_state = submit_and_wait(session,
        replace_group(accepted.nodes, LEGAL_RECOVERY), accepted.version)
    require(recovered.candidate_accepted, f"recovery candidate was refused: {recovered.reason} {recovered.path}")
    require(recovery_state.terminal_state == "ACCEPTED",
            f"recovery ticket terminal state was {recovery_state.terminal_state}")
    recovered_structure = session.structure()
    recovered_node = next(node for node in recovered_structure.nodes if node.key == "effectGroup")
    require(recovered_structure.version == recovery_state.accepted_version,
            "recovery readback version differs from its ticket")
    require(recovered_node.property("effectGroup") == LEGAL_RECOVERY,
            "legal recovery did not replace the rejected values")
    require_card_inside_group(recovered_structure.nodes)
    require(read_group_child_owners(session, recovered_structure.version) == owner_readback,
            "legal recovery changed the generated group children's owner readback")

    # Exercise the new optional backdrop blur suffix through the same real
    # generated candidate and scene transaction as the base effect group.
    blurred, blurred_state = submit_and_wait(session,
        replace_group(recovered_structure.nodes, LEGAL_BLUR_ON), recovered_structure.version)
    require(blurred.candidate_accepted, f"blur candidate was refused: {blurred.reason} {blurred.path}")
    require(blurred_state.terminal_state == "ACCEPTED",
            f"blur-on ticket terminal state was {blurred_state.terminal_state}")
    blurred_structure = session.structure()
    require(blurred_structure.version == blurred_state.accepted_version,
            "blur-on readback version differs from its ticket")
    blurred_node = next(node for node in blurred_structure.nodes if node.key == "effectGroup")
    require(blurred_node.property("effectGroup") == LEGAL_BLUR_ON,
            "accepted generated group did not retain its blur declaration")
    require_card_inside_group(blurred_structure.nodes)
    require(read_group_child_owners(session, blurred_structure.version) == owner_readback,
            "blur-on scene lost or changed the group children's owner bindings/readback")

    blur_rejections: list[tuple[str, str, str]] = []
    for label, value in (("blur_radius", INVALID_BLUR_RADIUS), ("blur_fallback", INVALID_BLUR_FALLBACK)):
        _result, state = submit_and_wait(session,
            replace_group(blurred_structure.nodes, value), blurred_structure.version)
        require(state.terminal_state == "REJECTED",
                f"{label} ticket terminal state was {state.terminal_state}")
        require(state.reason == "effect_group_value_invalid",
                f"{label} rejection reason was {state.reason!r}")
        require(state.path.endswith("/effectGroup"),
                f"{label} rejection did not identify the effectGroup property: {state.path!r}")
        blur_rejections.append((label, state.reason, state.path))
        unchanged = session.structure()
        require(unchanged.version == blurred_structure.version and unchanged.nodes == blurred_structure.nodes,
                f"{label} refusal changed the accepted blurred scene")
        require(read_group_child_owners(session, unchanged.version) == owner_readback,
                f"{label} refusal changed the group children's owner readback")

    unblurred, unblurred_state = submit_and_wait(session,
        replace_group(blurred_structure.nodes, LEGAL_BLUR_OFF), blurred_structure.version)
    require(unblurred.candidate_accepted, f"blur-off candidate was refused: {unblurred.reason} {unblurred.path}")
    require(unblurred_state.terminal_state == "ACCEPTED",
            f"blur-off ticket terminal state was {unblurred_state.terminal_state}")
    unblurred_structure = session.structure()
    require(unblurred_structure.version == unblurred_state.accepted_version,
            "blur-off readback version differs from its ticket")
    unblurred_node = next(node for node in unblurred_structure.nodes if node.key == "effectGroup")
    require(unblurred_node.property("effectGroup") == LEGAL_BLUR_OFF,
            "blur-off accepted group retained a blur suffix")
    require_card_inside_group(unblurred_structure.nodes)
    require(read_group_child_owners(session, unblurred_structure.version) == owner_readback,
            "blur-off scene lost or changed the group children's owner bindings/readback")

    print(
        "CJGUI_EXTERNAL_EFFECT_GROUP_EVIDENCE"
        f" directoryType={group_spec.value_type}"
        f" directoryEncoding={group_spec.encoding}"
        f" initial={LEGAL_INITIAL} acceptedTicket={legal_state.terminal_state}"
        f" acceptedVersion={accepted.version}"
        f" invalidRange={failures[0][1]}:{failures[0][2]}"
        f" unknownMode={failures[1][1]}:{failures[1][2]}"
        f" oldPanelControlsRetained=1 recoveryTicket={recovery_state.terminal_state}"
        f" recoveryValue={recovered_node.property('effectGroup')}"
        f" blurOnTicket={blurred_state.terminal_state} blurOn={blurred_node.property('effectGroup')}"
        f" blurOnOwners={owner_readback}"
        f" invalidBlurRadius={blur_rejections[0][1]}:{blur_rejections[0][2]}"
        f" invalidBlurFallback={blur_rejections[1][1]}:{blur_rejections[1][2]}"
        f" blurOffTicket={unblurred_state.terminal_state} blurOff={unblurred_node.property('effectGroup')}"
    )
    print("CJGUI_EXTERNAL_EFFECT_GROUP_VERDICT PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv))
    except (AssertionError, StopIteration) as exc:
        print(f"CJGUI_EXTERNAL_EFFECT_GROUP_VERDICT FAIL reason={exc}", file=sys.stderr)
        raise SystemExit(1)
