#!/usr/bin/env python3
"""Exercise window material through the normal generated application's public socket.

All candidate changes pass the existing generated authorization, validation and
accepted-scene transaction. This client reads the committed host receipt and
the live task-card owner rather than the consumer's controller fields.
"""

from __future__ import annotations

import sys
import time
from dataclasses import replace

from verify_generated_effect_candidates import read_group_child_owners, require, submit_and_wait
from cjgui_generated_client import GeneratedNode, GeneratedUiSession
from client import SharedOperationArgument


def one(response, label: str) -> str:
    values = response.value(label)
    require(len(values) == 1, f"{label} was not a scalar")
    return values[0]


def root_background(nodes: tuple[GeneratedNode, ...], mode: str | None) -> tuple[GeneratedNode, ...]:
    updated: list[GeneratedNode] = []
    for node in nodes:
        if node.key != "board" or node.depth != 0:
            updated.append(node)
            continue
        properties = tuple(prop for prop in node.properties if prop.name != "windowBackground")
        if mode is not None:
            from cjgui_generated_client import GeneratedProperty
            properties += (GeneratedProperty("windowBackground", mode),)
        updated.append(replace(node, properties=properties))
    require(len(updated) == len(nodes) and any(node.key == "board" and node.depth == 0 for node in updated),
            "accepted generated root is missing")
    return tuple(updated)


def wait_receipt(session: GeneratedUiSession, requested: str, prior_scene: int,
                 *, require_current_native_scene: bool = True, timeout: float = 10.0):
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
        last = session.client.get_window_progress()
        accepted_scene = last.integer("WINDOW_ACCEPTED_SCENE_VERSION")
        native_scene = last.integer("WINDOW_BACKGROUND_ACCEPTED_SCENE_VERSION")
        if (one(last, "WINDOW_BACKGROUND_REQUESTED") == requested and accepted_scene > prior_scene and
                (not require_current_native_scene or native_scene == accepted_scene) and
                one(last, "WINDOW_BACKGROUND_COMPLETION") == "succeeded"):
            return last
        time.sleep(0.05)
    raise AssertionError(f"window material {requested} after scene {prior_scene} has no committed receipt: "
                         f"{last.raw if last else 'no response'}")


def require_effects_increment(session: GeneratedUiSession, requested: str) -> None:
    observed = session.observe_once()
    require(observed.kind == "changes", f"window material transition produced {observed.kind}, not changes")
    section = (observed.sections or {}).get("EFFECTS", "")
    require(f"WINDOW_BACKGROUND_REQUESTED {requested}" in section,
            f"EFFECTS omitted material request {requested}: {section!r}")
    require(any(change.category == "EFFECTS" for change in observed.changes.changes),
            "window material transition lacked the EFFECTS change category")


def accepted_change(session: GeneratedUiSession, mode: str | None):
    before = session.structure()
    previous_scene = session.client.get_window_progress().integer("WINDOW_ACCEPTED_SCENE_VERSION")
    candidate, terminal = submit_and_wait(session, root_background(before.nodes, mode), before.version)
    require(candidate.candidate_accepted and terminal.terminal_state == "ACCEPTED",
            f"material candidate did not settle ACCEPTED: {candidate.reason}/{terminal.terminal_state}")
    accepted = session.structure()
    require(accepted.version == terminal.accepted_version and accepted.version > before.version,
            "material accepted version does not match its ticket")
    root = next(node for node in accepted.nodes if node.key == "board" and node.depth == 0)
    require(root.property("windowBackground") == (mode or ""),
            f"accepted material root differs from candidate: {root.property('windowBackground')!r}")
    requested = mode or "opaque"
    receipt = wait_receipt(session, requested, previous_scene, require_current_native_scene=mode is not None)
    require(receipt.integer("WINDOW_BACKGROUND_FRAME_INDEX") > 0,
            "material receipt has no submitted frame")
    if mode is None:
        # Omission after explicit opaque is a distinct accepted declaration,
        # with the same effective host state. It need not fabricate an EFFECTS
        # change or a GPU frame; the structure section carries the change.
        observed = session.observe_once()
        require(observed.kind == "changes", "clear did not enter the incremental observation stream")
    else:
        require_effects_increment(session, requested)
    return accepted, receipt


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: verify_public_window_material.py DESCRIPTOR_PATH", file=sys.stderr)
        return 2
    session = GeneratedUiSession.connect(argv[1])
    discovered = session.capabilities(refresh=True).window_background
    require(discovered is not None, "generated capability did not publish windowBackground")
    require(discovered.root_only and discovered.values == ("opaque", "system_content_area") and
            discovered.default == "opaque" and discovered.omitted == "opaque",
            f"window background discovery disagrees with validator: {discovered!r}")
    require(discovered.backend_support == "macos:experimental_supported,ohos:unpublished_snapshot",
            "window background discovery overstates platform support")

    session.snapshot()  # Anchor the existing public incremental observation stream.
    initial = session.structure()
    initial_root = next(node for node in initial.nodes if node.key == "board" and node.depth == 0)
    require(initial_root.property("windowBackground") == "system_content_area",
            "normal generated application did not request the system material")
    initial_receipt = wait_receipt(session, "system_content_area", -1)
    require(one(initial_receipt, "WINDOW_BACKGROUND_BACKEND") == "appkit_behind_window",
            "normal window did not use the AppKit content-area backend")
    initial_actual = one(initial_receipt, "WINDOW_BACKGROUND_ACTUAL")
    initial_scheme = one(initial_receipt, "WINDOW_BACKGROUND_COLOR_SCHEME")
    require(initial_actual in ("system_host_installed", "opaque_fallback"),
            f"host reported an invalid actual mode: {initial_actual}")
    require(initial_scheme in ("light", "dark"),
            f"host did not publish its adopted appearance: {initial_scheme}")
    require(one(initial_receipt, "WINDOW_BACKGROUND_VISUAL_RESULT") == "unobserved",
            "public receipt falsely claimed to observe the desktop compositor")
    original_owners = read_group_child_owners(session, initial.version)
    title = "系统材质窗口读回"
    write = session.invoke_action("SET_TITLE", [8101], [SharedOperationArgument.string("title", title)])
    require(one(write, "APPLIED") == "true", f"public title input was not applied: {write.raw}")
    require(next(field for field in session.fields() if field.field_id == "title").applied == title,
            "public title input did not reach the owner readback")
    owners = read_group_child_owners(session, initial.version)
    require(owners != original_owners and f"applied='{title}'" in owners,
            "owner binding did not publish the newly written title")

    opaque, opaque_receipt = accepted_change(session, "opaque")
    require(one(opaque_receipt, "WINDOW_BACKGROUND_ACTUAL") == "opaque" and
            one(opaque_receipt, "WINDOW_BACKGROUND_FALLBACK_REASON") == "not_requested",
            "explicit opaque switch did not remove the material")
    require(read_group_child_owners(session, opaque.version) == owners,
            "opaque switch changed generated control owner bindings")

    cleared, cleared_receipt = accepted_change(session, None)
    require(one(cleared_receipt, "WINDOW_BACKGROUND_ACTUAL") == "opaque" and
            one(cleared_receipt, "WINDOW_BACKGROUND_FALLBACK_REASON") == "not_requested",
            "omitting the root property did not clear the material")

    before_rejection = session.structure()
    _bad, rejected = submit_and_wait(session, root_background(before_rejection.nodes, "system_unknown"),
                                     before_rejection.version)
    require(rejected.terminal_state == "REJECTED" and rejected.reason == "window_background_value_invalid",
            f"unknown material was not refused at candidate boundary: {rejected!r}")
    after_rejection = session.structure()
    require(after_rejection.version == before_rejection.version and
            after_rejection.nodes == before_rejection.nodes,
            "rejected material changed the accepted generated scene")

    recovered, recovery_receipt = accepted_change(session, "system_content_area")
    require(one(recovery_receipt, "WINDOW_BACKGROUND_ACTUAL") == initial_actual,
            "recovery did not restore the original host mode for unchanged system settings")
    require(one(recovery_receipt, "WINDOW_BACKGROUND_COLOR_SCHEME") == initial_scheme,
            "recovery did not preserve the same accepted platform appearance")
    require(read_group_child_owners(session, recovered.version) == owners,
            "material recovery changed generated control owner bindings")
    require(recovery_receipt.integer("WINDOW_BACKGROUND_FRAME_INDEX") >
            cleared_receipt.integer("WINDOW_BACKGROUND_FRAME_INDEX"),
            "recovery reused the old clear frame")
    print("CJGUI_PUBLIC_WINDOW_MATERIAL"
          f" backend={one(initial_receipt, 'WINDOW_BACKGROUND_BACKEND')}"
          f" initial={initial_actual}"
          f" opaqueFrame={one(opaque_receipt, 'WINDOW_BACKGROUND_FRAME_INDEX')}"
          f" clearFrame={one(cleared_receipt, 'WINDOW_BACKGROUND_FRAME_INDEX')}"
          f" recoveryFrame={one(recovery_receipt, 'WINDOW_BACKGROUND_FRAME_INDEX')}"
          f" recoveryActual={one(recovery_receipt, 'WINDOW_BACKGROUND_ACTUAL')}"
          f" scheme={initial_scheme}"
          f" reduction={one(recovery_receipt, 'WINDOW_BACKGROUND_REDUCE_TRANSPARENCY')}"
          f" owners={owners}")
    print("CJGUI_PUBLIC_WINDOW_MATERIAL_VERDICT PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv))
    except (AssertionError, StopIteration) as exc:
        print(f"CJGUI_PUBLIC_WINDOW_MATERIAL_VERDICT FAIL reason={exc}", file=sys.stderr)
        raise SystemExit(1)
