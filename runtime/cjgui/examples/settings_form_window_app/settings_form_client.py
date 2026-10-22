#!/usr/bin/env python3
"""Public-client checks for the grouped settings form.

The client uses the existing generated-UI connection and typed action API. It
never opens a second owner copy: EDIT_DRAFT_TEXT writes the same draft the
window displays, and APPLY_DRAFT updates the same applied values.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "shared_operation_core"))
from cjgui_generated_client import GeneratedUiSession
from client import SharedOperationArgument

RESOURCE_ID = 9300


def draft_write(session: GeneratedUiSession, field: str, text: str) -> dict:
    state = session.form_state()
    assert state.known and state.consistent and state.draft_version is not None
    response = session.invoke_action(
        "EDIT_DRAFT_TEXT",
        [RESOURCE_ID],
        [
            SharedOperationArgument.string("fieldId", field),
            SharedOperationArgument.string("text", text),
            SharedOperationArgument.integer("expectedDraftVersion", state.draft_version),
        ],
        expected_version=state.state_version,
    )
    return {"field": field, "text": text, "reply": str(response)}


def draft_boolean_write(session: GeneratedUiSession, field: str, text: str) -> dict:
    state = session.form_state()
    assert state.known and state.consistent and state.draft_version is not None
    wanted = text.strip().lower() == "true"
    response = session.invoke_action(
        "EDIT_DRAFT_BOOLEAN",
        [RESOURCE_ID],
        [
            SharedOperationArgument.string("fieldId", field),
            SharedOperationArgument.boolean("value", wanted),
            SharedOperationArgument.integer("expectedDraftVersion", state.draft_version),
        ],
        expected_version=state.state_version,
    )
    return {"field": field, "value": wanted, "reply": str(response)}


def read(session: GeneratedUiSession) -> dict:
    state = session.form_state()
    return {
        "known": state.known,
        "consistent": state.consistent,
        "state_version": state.state_version,
        "draft_version": state.draft_version,
        "applied_version": state.applied_version,
        "can_apply": state.can_apply,
        "message": state.message,
        "fields": [asdict(field) for field in state.fields],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("descriptor")
    parser.add_argument("operation", choices=("errors", "external", "apply", "read", "proxy"))
    parser.add_argument("--value", default="false")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    session = GeneratedUiSession.connect(args.descriptor)
    result: dict = {"operation": args.operation, "before": read(session)}
    if args.operation == "errors":
        result["writes"] = [
            draft_write(session, "endpoint", "ftp://bad"),
            draft_write(session, "displayName", ""),
        ]
    elif args.operation == "external":
        result["writes"] = [draft_write(session, "retryLimit", "6")]
    elif args.operation == "proxy":
        result["writes"] = [draft_boolean_write(session, "useProxy", args.value)]
    elif args.operation == "apply":
        state = session.form_state()
        response = session.invoke_action(
            "APPLY_DRAFT",
            [RESOURCE_ID],
            [
                SharedOperationArgument.integer("expectedDraftVersion", state.draft_version),
                SharedOperationArgument.integer("expectedBaseAppliedConfigVersion", state.applied_version),
            ],
            expected_version=state.state_version,
        )
        result["reply"] = str(response)
    result["after"] = read(session)
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.write_text(rendered)
    print(rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main())
