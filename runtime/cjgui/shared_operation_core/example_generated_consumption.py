#!/usr/bin/env python3
"""Short public example: discover -> build -> submit -> wait -> read back.

Usage:
    python3 example_generated_consumption.py <DESCRIPTOR_PATH>

It uses ONLY the exported public client and the capability text the application
itself publishes:

  1. ask the running application what it can present (kinds/properties/fields);
  2. pick an editable field from that answer and build a small panel for it;
  3. submit the candidate and read the application's own submit result;
  4. wait (bounded) for the ACCEPTED structure to reach the expected version;
  5. confirm the accepted structure really is the candidate that was submitted;
  6. ask the OWNERSHIP ticket of its own submission what the endpoint did with it
     (a token is allocated per attempt, so two submitters that share a base
     version are still distinguishable);
  7. address the accepted control by its DECLARED key and read its real geometry.

There is no action name, field id or resource id hard-coded here, and no model or
Agent runtime: it is the same typed public client a developer (or an external
bridge) would import.
"""

from __future__ import annotations

import sys

from cjgui_generated_client import (
    GeneratedNode,
    GeneratedProperty,
    GeneratedUiSession,
    same_structure,
)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__)
        return 2
    session = GeneratedUiSession.connect(argv[1])
    capabilities = session.capabilities()
    editor = next((field for field in capabilities.fields
                   if field.callable and field.input_kind in ("textInput", "integerInput")), None)
    if editor is None:
        print("the application publishes no editable text/integer field")
        return 1
    if capabilities.component(editor.input_kind) is None:
        print(f"the application does not publish a {editor.input_kind} component")
        return 1

    nodes = [
        GeneratedNode(0, "example-root", "vertical", None, None,
                      (GeneratedProperty("gap", "6"),)),
        GeneratedNode(1, "example-edit", editor.input_kind, editor.field_id, None,
                      (GeneratedProperty("label", editor.label),)),
    ]
    before = session.structure()
    result = session.submit(nodes, before.version)
    print(f"submit {result.describe()} candidate_accepted={result.candidate_accepted} "
          f"scene_accepted={result.scene_accepted} token={result.candidate_token} "
          f"receipt={result.receipt}")
    if not result.candidate_accepted:
        return 1
    ticket = result.ticket()
    if ticket.token <= 0:
        print("the submit reply did not hand back an attempt token")
        return 1

    wait = session.wait_for_structure(before.version + 1, timeout_ms=5_000)
    print(f"wait outcome={wait.outcome} accepted_version={wait.structure.version} "
          f"scene_state={wait.structure.scene_state}")
    if wait.outcome != "reached":
        return 1
    if not same_structure(nodes, wait.structure.nodes):
        print("the accepted structure is not the candidate that was submitted")
        return 1

    # The ownership ticket of THIS submission: the terminal state comes from the
    # holder that performed the asynchronous scene commit, not from a version
    # number the caller has to interpret.
    candidate = session.wait_for_candidate(ticket, timeout_ms=5_000, poll_ms=25)
    print(f"ticket token={ticket.token} receipt={ticket.receipt} "
          f"endpoint_epoch={ticket.endpoint_epoch} terminal={candidate.terminal_state} "
          f"scene={candidate.scene_state} accepted_version={candidate.accepted_version}")
    if candidate.terminal_state != "ACCEPTED":
        print("the ownership ticket did not settle as accepted")
        return 1
    if candidate.accepted_version != wait.structure.version:
        print("the ticket's accepted version does not match the accepted structure")
        return 1

    instance = session.instances().instance("example-edit")
    if instance is None:
        print("the accepted instance is missing from the public instance projection")
        return 1
    print(f"instance key={instance.key} kind={instance.kind} node={instance.node_id} "
          f"field={instance.field_id} visible={instance.visible} bounds={instance.bounds}")

    values = {value.field_id: value for value in session.fields()}
    value = values.get(instance.field_id or "")
    if value is None:
        print("the accepted field projection is missing")
        return 1
    print(f"field {value.field_id} draft={value.draft!r} applied={value.applied!r} "
          f"version={value.draft_version}")
    print("PASSED example consumption")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
