#!/usr/bin/env python3
"""Public example: read the generated UI through the atomic observation seam.

Usage:
    python3 example_generated_observation.py <DESCRIPTOR_PATH> phase1 <STATE_FILE>
    python3 example_generated_observation.py <DESCRIPTOR_PATH> phase2 <STATE_FILE>

This is a two-phase example because a change must really happen between the two
reads; each phase uses ONLY the exported public client.

  phase1: take ONE atomic snapshot (owner/scene facts plus the field, structure
          and instance sections of a SINGLE provider call), record its cursor,
          then confirm that an UNCHANGED round costs one bounded change read and
          does NOT resend the tree. The measured byte sizes are printed.
  phase2: read the change cursor after a real owner change happened, print the
          categories, then drive two more transitions from the public surface:
          a rejected candidate submission (CANDIDATE) and a stale stream epoch
          (RESYNC_REQUIRED). Nothing is stitched from an unguarded section read.

The state file is a tiny JSON document; it carries only the stream epoch, the
cursor and the measured byte sizes.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from cjgui_generated_client import GeneratedUiSession


def geometry_bounds(instances_text: str) -> dict[str, tuple[int, int, int, int]]:
    """Declared key -> accepted bounds, from the public INSTANCES section lines."""
    bounds: dict[str, tuple[int, int, int, int]] = {}
    for line in instances_text.split("\n"):
        parts = line.split(" ")
        if not parts or parts[0] != "INSTANCE" or len(parts) < 3:
            continue
        key = parts[1]
        for part in parts:
            if part.startswith("bounds="):
                values = part[len("bounds="):].split(",")
                if len(values) == 4 and all(value.lstrip("-").isdigit() for value in values):
                    bounds[key] = tuple(int(value) for value in values)  # type: ignore[assignment]
    return bounds


def main(argv: list[str]) -> int:
    if argv[2] not in ("phase1", "phase2", "phase3", "phase4"):
        print(__doc__)
        return 2
    if argv[2] == "phase4":
        if len(argv) != 6:
            print(__doc__)
            return 2
    elif len(argv) != 4:
        print(__doc__)
        return 2
    descriptor, phase, state_path = argv[1], argv[2], Path(argv[3])
    session = GeneratedUiSession.connect(descriptor)

    if phase == "phase1":
        # The poller's first call IS the atomic snapshot; it also seeds the
        # cursor cache, so the next call is an unchanged incremental round.
        first = session.observe_once()
        snapshot = first.snapshot
        if snapshot is None:
            print("the first observation was not a snapshot")
            return 1
        snapshot_bytes = session.last_response_bytes()
        print(f"snapshot stream_epoch={snapshot.stream_epoch} cursor={snapshot.cursor} "
              f"endpoint_epoch={snapshot.endpoint_epoch} structure_version={snapshot.accepted_structure_version} "
              f"owner_field_revision={snapshot.owner_field_revision} scene_version={snapshot.window_accepted_scene_version} "
              f"pending_scene={int(snapshot.owner_pending_scene)} "
              f"bytes={snapshot_bytes} structure_bytes={len(snapshot.structure_text)}")
        # An unchanged round must not resend the tree.
        observed = session.observe_once()
        unchanged_bytes = session.last_response_bytes()
        print(f"unchanged_round kind={observed.kind} resync={observed.changes.resync_required} "
              f"bytes={unchanged_bytes} snapshot_bytes={snapshot_bytes}")
        if observed.kind != "none":
            print("an unchanged round did not answer none")
            return 1
        if observed.changes.changes:
            print("an unchanged round reported changes")
            return 1
        if snapshot.structure_text and unchanged_bytes >= snapshot_bytes:
            print("the unchanged round did not carry fewer bytes than the snapshot")
            return 1
        # ONE real submission attempt on THIS endpoint instance. Its ticket is
        # recorded so the restarted endpoint can be asked about it later.
        # The attempt is a DUPLICATE-KEY candidate on purpose: it still receives a
        # real ownership token bound to this endpoint instance, but the structure
        # validator refuses it, so the accepted scene keeps exactly the demo
        # structure below. A structurally valid attempt here would be accepted and
        # would replace the geometry this phase hands to phase3's resize check.
        candidate = "\n".join([
            "GENERATED_UI_STRUCTURE 1",
            "NODE 0 restartRoot vertical",
            "NODE 1 restartLabel label",
            "NODE 1 restartLabel label",
            "END",
        ])
        submitted = session.submit_text(candidate, session.structure().version)
        ticket = submitted.ticket()
        print(f"endpoint_a_ticket token={ticket.token} receipt={ticket.receipt} "
              f"instance={ticket.endpoint.instance} bind={ticket.endpoint.bind_generation} "
              f"candidate_accepted={submitted.candidate_accepted} reason={submitted.reason}")
        if ticket.token <= 0:
            print("the submission did not get an ownership token")
            return 1
        state_path.write_text(json.dumps({
            "stream_epoch": snapshot.stream_epoch,
            "cursor": snapshot.cursor,
            "snapshot_bytes": snapshot_bytes,
            "geometry_revision": snapshot.window_geometry_revision,
            "instances_text": snapshot.instances_text,
            "ticket_token": ticket.token,
            "ticket_receipt": ticket.receipt,
            "ticket_instance": ticket.endpoint.instance,
            "ticket_bind": ticket.endpoint.bind_generation,
        }), encoding="utf-8")
        print(f"geometry revision={snapshot.window_geometry_revision} "
              f"instances_bytes={len(snapshot.instances_text)}")
        print("PASSED observation phase1")
        return 0

    if phase == "phase3":
        # A REAL window resize happened between the phases. The structure did
        # not change, so the increment must report the SCENE (geometry) change
        # and re-read exactly the INSTANCES section that carries the new bounds
        # -- never a structure change.
        state = json.loads(state_path.read_text(encoding="utf-8"))
        session.seed_cursor(int(state["stream_epoch"]), int(state["cursor"]))
        observed = session.observe_once()
        if observed.kind != "changes":
            print(f"the window resize was not observed as an increment (kind={observed.kind})")
            return 1
        categories = [change.category for change in observed.changes.changes]
        sections = observed.sections or {}
        print(f"resize current={observed.changes.current} categories={','.join(categories)} "
              f"sections={','.join(sorted(sections))} resync={observed.changes.resync_required}")
        if "STRUCTURE" in categories:
            print("the resize claimed a structure change")
            return 1
        if "SCENE" not in categories:
            print("the resize did not report the scene/geometry change")
            return 1
        if "INSTANCES" not in sections:
            print("the resize did not re-read the affected INSTANCES section")
            return 1
        if "SNAPSHOT_STRUCTURE" in sections.get("INSTANCES", ""):
            print("the resize section read carried a structure")
            return 1
        # The two REAL window geometries must produce different ACCEPTED bounds
        # for the accepted instances: a narrow/wide comparison without a full
        # structure change and without hard-coding any declared key.
        before_bounds = geometry_bounds(state.get("instances_text", ""))
        after_bounds = geometry_bounds(sections.get("INSTANCES", ""))
        changed = sum(1 for key, box in after_bounds.items()
                      if key in before_bounds and before_bounds[key] != box)
        print(f"geometry before_revision={state.get('geometry_revision', 0)} "
              f"before_instances={len(before_bounds)} after_instances={len(after_bounds)} "
              f"changed_bounds={changed}")
        if changed == 0:
            # Ground truth for the diagnostic: the two raw section texts, so the
            # next reader can tell "the window never re-laid-out" from "the
            # section read returned a cached text".
            print("before_text_begin")
            print(state.get("instances_text", ""))
            print("before_text_end")
            print("after_text_begin")
            print(sections.get("INSTANCES", ""))
            print("after_text_end")
        if not before_bounds or not after_bounds:
            print("one of the two geometries published no accepted instance bounds")
            return 1
        if changed == 0:
            print("the real resize did not change any accepted instance bounds")
            return 1
        print("PASSED observation phase3")
        return 0

    if phase == "phase4":
        # A DIFFERENT endpoint instance: the old (stream_epoch, cursor) must not
        # be served incrementally. The stream epoch identifies one endpoint
        # instance, so a restarted application cannot reuse it; the increment is
        # refused and a fresh snapshot is taken from the new endpoint.
        old_epoch = int(argv[4])
        old_cursor = int(argv[5])
        state = json.loads(state_path.read_text(encoding="utf-8"))
        session.seed_cursor(old_epoch, old_cursor)
        observed = session.observe_once()
        if observed.kind != "snapshot":
            print(f"the restarted endpoint served the old cursor (kind={observed.kind})")
            return 1
        snapshot = observed.snapshot
        changes = observed.changes
        resync = bool(changes.resync_required) if changes is not None else False
        epoch_changed = bool(changes is not None and changes.stream_epoch != old_epoch)
        print(f"restart old_epoch={old_epoch} old_cursor={old_cursor} "
              f"new_epoch={snapshot.stream_epoch} new_cursor={snapshot.cursor} "
              f"resync={resync} epoch_changed={epoch_changed}")
        if not resync and not epoch_changed:
            print("the restarted endpoint neither asked for a resync nor changed its stream epoch")
            return 1
        if snapshot.stream_epoch == old_epoch:
            print("the restarted endpoint reused the old stream epoch")
            return 1
        # The old ticket belongs to the PREVIOUS endpoint instance. The
        # restarted endpoint must refuse it instead of satisfying it with its own
        # coincidentally equal token.
        ticket_token = int(state.get("ticket_token", 0))
        if ticket_token > 0:
            from cjgui_generated_client import GeneratedCandidateTicket, GeneratedEndpointIdentity
            old_ticket = GeneratedCandidateTicket(ticket_token, str(state.get("ticket_receipt", "none")),
                                                  GeneratedEndpointIdentity(str(state.get("ticket_instance", "")),
                                                                            int(state.get("ticket_bind", 0))),
                                                  0, 0)
            wait = session.wait_for_candidate_result(old_ticket, timeout_ms=2_000, poll_ms=25)
            print(f"restart_ticket token={ticket_token} outcome={wait.outcome}")
            if wait.outcome != "endpoint_replaced":
                print(f"the restarted endpoint did not refuse the old ticket ({wait.outcome})")
                return 1
        print("PASSED observation phase4")
        return 0

    state = json.loads(state_path.read_text(encoding="utf-8"))
    stream_epoch = int(state["stream_epoch"])
    cursor = int(state["cursor"])
    # This is a NEW process since phase1, so the cursor observed there is seeded
    # from the state file: the poller then reads only the increment instead of
    # taking another full snapshot.
    session.seed_cursor(stream_epoch, cursor)
    # The poller re-reads ONLY the sections the categories make stale, each one
    # guarded at the change cursor. The stale-epoch check below still uses the
    # raw change read, because that is where a stream replacement surfaces.
    observed = session.observe_once()
    if observed.kind == "snapshot":
        print("a change round unexpectedly required a full snapshot")
        return 1
    if observed.kind != "changes":
        print(f"the real owner draft change was not observed (kind={observed.kind})")
        return 1
    changes = observed.changes
    categories = [change.category for change in changes.changes]
    sections = observed.sections or {}
    print(f"changes since={cursor} current={changes.current} resync={changes.resync_required} "
          f"categories={','.join(categories)} sections={','.join(sorted(sections))} "
          f"section_bytes={session.last_response_bytes()}")
    if changes.resync_required:
        print("the cursor right after a snapshot asked for a resync")
        return 1
    if "FIELDS" not in categories:
        print("the real owner draft change was not observed as FIELDS")
        return 1
    if "FIELDS" not in sections or "FIELD " not in sections["FIELDS"]:
        print("the affected FIELDS section was not re-read at the guarded cursor")
        return 1

    # The change round carried no structure: only the affected sections were
    # re-read.
    if "SNAPSHOT_STRUCTURE" in "".join(sections.values()):
        print("the change round fabricated a structure section")
        return 1

    # A REJECTED candidate submission is a real attempt and must be observable as
    # CANDIDATE, not as a structure change. The payload is shape-valid (so the
    # attempt reaches the owner) but duplicates a declared key, which the
    # structure validator refuses.
    rejected_candidate = "\n".join([
        "GENERATED_UI_STRUCTURE 1",
        "NODE 0 observationRoot vertical",
        "NODE 1 duplicateKey label",
        "NODE 1 duplicateKey label",
        "END",
    ])
    result = session.submit_text(rejected_candidate, session.structure().version)
    print(f"rejected_submit applied={result.applied} reason={result.reason} token={result.candidate_token}")
    if result.applied:
        print("the duplicate-key candidate was accepted")
        return 1
    if result.candidate_token <= 0:
        print("the rejected attempt did not carry an ownership token")
        return 1
    after_submit = session.observe_once()
    submit_changes = after_submit.changes
    submit_categories = [change.category for change in submit_changes.changes]
    print(f"after_rejected_submit kind={after_submit.kind} "
          f"categories={','.join(submit_categories)} current={submit_changes.current} "
          f"sections={','.join(sorted(after_submit.sections or {}))}")
    if "CANDIDATE" not in submit_categories:
        print("the rejected candidate attempt was not observable")
        return 1
    if after_submit.sections:
        print("a candidate-only change re-read sections it did not make stale")
        return 1

    # A stale stream epoch cannot be served incrementally.
    stale = session.changes(changes.stream_epoch + 99, submit_changes.current)
    print(f"stale_stream resync={stale.resync_required} changes={len(stale.changes)}")
    if not stale.resync_required or stale.changes:
        print("a stale stream epoch was answered with a fabricated increment")
        return 1
    # Persist the cursor for phase3 (a separate process, after a real resize).
    state_path.write_text(json.dumps({
        "stream_epoch": submit_changes.stream_epoch,
        "cursor": submit_changes.current,
        "snapshot_bytes": state.get("snapshot_bytes", 0),
        "geometry_revision": state.get("geometry_revision", 0),
        "instances_text": state.get("instances_text", ""),
        "ticket_token": state.get("ticket_token", 0),
        "ticket_receipt": state.get("ticket_receipt", "none"),
        "ticket_instance": state.get("ticket_instance", ""),
        "ticket_bind": state.get("ticket_bind", 0),
    }), encoding="utf-8")
    print("PASSED observation phase2")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
