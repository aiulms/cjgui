#!/usr/bin/env python3
"""Observe real normal-window blur fallback/recovery through the public socket.

The application changes only its root clear under a private test gate. The
candidate, accepted declaration, committed effect receipt and incremental
EFFECTS section are all read through the exported client.
"""

from __future__ import annotations

import sys
import time
from pathlib import Path

from verify_generated_effect_candidates import (
    LEGAL_BLUR_ON, read_group_child_owners, replace_group, require, submit_and_wait,
)
from cjgui_generated_client import GeneratedUiSession


def one(response, label: str) -> str:
    values = response.value(label)
    require(len(values) == 1, f"{label} was not one scalar")
    return values[0]


def wait_progress(session: GeneratedUiSession, mode: str, reason: str, *, timeout: float = 12.0):
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
        last = session.client.get_window_progress()
        if (one(last, "WINDOW_EFFECT_REQUESTED_RADIUS_POINTS") == "8" and
                one(last, "WINDOW_EFFECT_SUBMITTED_MODE") == mode and
                one(last, "WINDOW_EFFECT_FALLBACK_REASON") == reason and
                one(last, "WINDOW_EFFECT_COMPLETION") == "succeeded"):
            return last
        time.sleep(0.05)
    raise AssertionError(f"effect {mode}/{reason} was not observed: {last.raw if last else 'no response'}")


def effects_section(session: GeneratedUiSession, mode: str, reason: str) -> str:
    observed = session.observe_once()
    require(observed.kind == "changes",
            f"effect transition did not produce an incremental change: {observed.kind}")
    section = (observed.sections or {}).get("EFFECTS", "")
    require(f"EFFECT_SUBMITTED_MODE {mode}" in section and
            f"EFFECT_FALLBACK_REASON {reason}" in section,
            f"EFFECTS section did not report {mode}/{reason}: {section!r}")
    require(any(change.category == "EFFECTS" for change in observed.changes.changes),
            "effect transition lacked an EFFECTS category")
    return section


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: verify_public_effect_observation.py DESCRIPTOR_PATH RELEASE_GATE", file=sys.stderr)
        return 2
    gate = Path(argv[2])
    session = GeneratedUiSession.connect(argv[1])
    baseline = session.snapshot()
    require("EFFECT_ID none" in baseline.effects_text, "initial snapshot did not carry the effect section")
    structure = session.structure()
    candidate, terminal = submit_and_wait(session, replace_group(structure.nodes, LEGAL_BLUR_ON), structure.version)
    require(candidate.candidate_accepted and terminal.terminal_state == "ACCEPTED",
            f"public blur candidate did not settle accepted: {candidate.reason} {terminal.terminal_state}")
    accepted = session.structure()
    require(next(node for node in accepted.nodes if node.key == "effectGroup").property("effectGroup") == LEGAL_BLUR_ON,
            "accepted scene lost the declared blur request")
    owners = read_group_child_owners(session, accepted.version)

    fallback = wait_progress(session, "unblurred", "non_opaque_clear")
    require(one(fallback, "WINDOW_EFFECT_ID") == "root_backdrop", "fallback lost the accepted effect identity")
    require(one(fallback, "WINDOW_EFFECT_SUBMITTED_RADIUS_POINTS") == "8", "fallback lost requested blur radius")
    require(one(fallback, "WINDOW_EFFECT_SUBMITTED_SCENE_VERSION") ==
            one(fallback, "WINDOW_ACCEPTED_SCENE_VERSION"), "fallback receipt belongs to another scene")
    fallback_frame = fallback.integer("WINDOW_EFFECT_SUBMITTED_FRAME_INDEX")
    require(fallback_frame > 0, "fallback has no committed frame")
    fallback_section = effects_section(session, "unblurred", "non_opaque_clear")

    gate.write_text("restore\n", encoding="utf-8")
    restored = wait_progress(session, "blurred", "none")
    restored_frame = restored.integer("WINDOW_EFFECT_SUBMITTED_FRAME_INDEX")
    require(restored_frame > fallback_frame, "restored blur did not submit a newer frame")
    require(one(restored, "WINDOW_SESSION") == one(fallback, "WINDOW_SESSION"),
            "recovery changed the window session")
    require(one(restored, "WINDOW_EFFECT_SUBMITTED_SCENE_VERSION") ==
            one(restored, "WINDOW_ACCEPTED_SCENE_VERSION"),
            "recovery receipt belongs to another accepted scene")
    restored_section = effects_section(session, "blurred", "none")
    require(read_group_child_owners(session, accepted.version) == owners,
            "fallback/recovery changed the group's owner bindings")
    print("CJGUI_PUBLIC_EFFECT_OBSERVATION"
          f" acceptedBlur={LEGAL_BLUR_ON} owner={owners}"
          f" fallbackFrame={fallback_frame} fallbackMode={one(fallback, 'WINDOW_EFFECT_SUBMITTED_MODE')}"
          f" fallbackReason={one(fallback, 'WINDOW_EFFECT_FALLBACK_REASON')}"
          f" fallbackCompletion={one(fallback, 'WINDOW_EFFECT_COMPLETION')}"
          f" restoredFrame={restored_frame} restoredMode={one(restored, 'WINDOW_EFFECT_SUBMITTED_MODE')}"
          f" fallbackSectionLines={len(fallback_section.splitlines())}"
          f" restoredSectionLines={len(restored_section.splitlines())}")
    print("CJGUI_PUBLIC_EFFECT_OBSERVATION_VERDICT PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv))
    except (AssertionError, StopIteration) as exc:
        print(f"CJGUI_PUBLIC_EFFECT_OBSERVATION_VERDICT FAIL reason={exc}", file=sys.stderr)
        raise SystemExit(1)
