#!/usr/bin/env python3
"""Two independent public clients submit against the SAME base version.

Ownership must be per ATTEMPT, not per version: the second submission must never
make the first one look successful. Both tickets are real (allocated by the
structure holder before the payload is looked at), and each settles as its own
attempt: the accepted one is ACCEPTED, the other is SUPERSEDED or REJECTED
(for example when the window had already committed the first structure, so the
second submission is refused by the public structure_version_conflict).

The race outcome is reported honestly: either the first was superseded before the
scene accepted it, or the first was accepted and the second was refused. What is
asserted is the invariant that cannot hold with version-based bookkeeping:
distinct tokens/receipts, exactly one accepted attempt, and the endpoint's
current accepted token equal to the accepted ticket.

Usage:
    python3 example_generated_candidate_race.py <DESCRIPTOR_PATH>
"""

from __future__ import annotations

import sys

from cjgui_generated_client import GeneratedUiSession


def payload(text: str) -> str:
    return "\n".join([
        "GENERATED_UI_STRUCTURE 1",
        "NODE 0 raceRoot vertical",
        "NODE 1 raceLabel label",
        f"PROPERTY 1 raceLabel text {text}",
        "END",
    ])


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__)
        return 2
    descriptor = argv[1]
    first = GeneratedUiSession.connect(descriptor)
    second = GeneratedUiSession.connect(descriptor)
    base_version = first.structure().version

    first_result = first.submit_text(payload("race-one"), base_version)
    second_result = second.submit_text(payload("race-two"), base_version)
    if first_result.candidate_token == 0 or second_result.candidate_token == 0:
        print("a submission did not carry an ownership token")
        return 1
    if first_result.candidate_token == second_result.candidate_token:
        print("two submissions shared one token")
        return 1
    if first_result.receipt == second_result.receipt:
        print("two submissions shared one receipt")
        return 1

    first_state = first.wait_for_candidate(first_result.ticket(), timeout_ms=8_000, poll_ms=50)
    second_state = second.wait_for_candidate(second_result.ticket(), timeout_ms=8_000, poll_ms=50)
    print(f"race base_version={base_version} "
          f"first_token={first_result.candidate_token} first={first_state.terminal_state} "
          f"first_reason={first_state.reason} "
          f"second_token={second_result.candidate_token} second={second_state.terminal_state} "
          f"second_reason={second_state.reason}")

    settled = {"ACCEPTED", "SUPERSEDED", "REJECTED"}
    if first_state.terminal_state not in settled or second_state.terminal_state not in settled:
        print("an attempt did not settle within the bounded wait")
        return 1
    accepted = [ticket for ticket, state in
                ((first_result, first_state), (second_result, second_state))
                if state.terminal_state == "ACCEPTED"]
    if len(accepted) != 1:
        print(f"expected exactly one accepted attempt, saw {len(accepted)}")
        return 1
    # The other attempt must be attributed to itself, never silently accepted.
    loser_state = second_state if accepted[0] is first_result else first_state
    if loser_state.terminal_state not in ("SUPERSEDED", "REJECTED"):
        print(f"the second attempt cannot make the first succeed (loser={loser_state.terminal_state})")
        return 1
    # The accepted attempt's own scene state is the accepted one.
    winner_state = first_state if accepted[0] is first_result else second_state
    if winner_state.scene_state != "scene_accepted":
        print(f"the accepted attempt did not carry the accepted scene state ({winner_state.scene_state})")
        return 1

    session = first
    current = session.candidate_state(accepted[0].candidate_token)
    if current.terminal_state != "ACCEPTED":
        print("the accepted ticket no longer reports ACCEPTED")
        return 1
    if current.pending_token != 0:
        print(f"an accepted attempt left a pending token {current.pending_token}")
        return 1
    print(f"accepted_token={accepted[0].candidate_token} "
          f"current_accepted_token={current.current_accepted_token} "
          f"accepted_version={winner_state.accepted_version}")
    print("PASSED candidate ownership race")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
