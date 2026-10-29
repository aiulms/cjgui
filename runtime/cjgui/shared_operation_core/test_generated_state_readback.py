"""Complete field facts through the shipped CLI and existing edit example."""
from contextlib import redirect_stdout
from dataclasses import asdict
import importlib.util
import io
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

import cjgui_generated_client as generated
import example_generated_edit as example
from test_generated_client import response, CAPABILITIES, STRUCTURE_VERSION_1, INSTANCES


def state(owner=6201):
    return generated.parse_generated_form_state(response("\n".join([
        "PROTOCOL CJGUI_SHARED_OPERATION/2", "KIND GENERATED_UI_FIELDS", "PAYLOAD_LENGTH 400",
        f"FIELD jobName 7101 DRAFT_HEX 6472616674 APPLIED_HEX 6170706c696564 "
        f"ERROR none VERSION 7 TARGET {owner} STATE_VERSION 9 FIELD_VERSION 6 "
        "AVAILABLE 0 REASON_HEX 6c6f636b6564 VALIDATION_STATE unknown",
        "END"])))


class ReadOnlySession:
    def __init__(self):
        self.reads = []

    def capabilities(self):
        return generated.parse_generated_capabilities(response(CAPABILITIES))

    def structure(self):
        return generated.parse_generated_structure(response(STRUCTURE_VERSION_1))

    def instances(self):
        return generated.parse_generated_instances(response(INSTANCES))

    def form_state(self, **selector):
        self.reads.append(selector)
        return state(6201 if selector.get("instance_key") == "cardA" else 6200)

    def invoke_action(self, *args, **kwargs):
        raise AssertionError("readback must not edit the owner")


class CompleteStateReadbackTests(unittest.TestCase):
    def test_refused_read_keeps_scope_and_reason_without_inventing_field_values(self):
        template = Path(__file__).resolve().parents[1] / "templates/macos_application/mixed_form/client.py"
        spec = importlib.util.spec_from_file_location("mixed_refused_readback", template)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        session = ReadOnlySession()
        session.form_state = lambda **selector: (_ for _ in ()).throw(
            generated.GeneratedUiRemoteError("unknown_owner", "GENERATED_UI_FIELDS",
                versions={"CURRENT_VERSION": 9}, target="6301", raw=("ERROR", "unknown_owner")))
        output = io.StringIO()
        with patch.object(module.GeneratedUiSession, "connect", return_value=session), \
                patch.object(sys, "argv", [str(template), "unused-descriptor", "read", "--owner", "6301"]), \
                redirect_stdout(output):
            status = module.main()
        result = json.loads(output.getvalue())
        self.assertEqual(status, 1)
        self.assertEqual(result["request"]["owner"], 6301)
        self.assertEqual(result["error"]["code"], "unknown_owner")
        self.assertEqual(result["error"]["versions"], {"CURRENT_VERSION": 9})
        self.assertIsNone(result["form_state"])
        self.assertIsNone(result["fields"])

    def test_mixed_read_obeys_instance_and_keeps_field_owner_versions_and_refusal(self):
        template = Path(__file__).resolve().parents[1] / "templates/macos_application/mixed_form/client.py"
        spec = importlib.util.spec_from_file_location("mixed_state_readback", template)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        session = ReadOnlySession()
        output = io.StringIO()
        with patch.object(module.GeneratedUiSession, "connect", return_value=session), \
                patch.object(sys, "argv", [str(template), "unused-descriptor", "read", "--instance", "cardA"]), \
                redirect_stdout(output):
            module.main()
        result = json.loads(output.getvalue())
        self.assertIn({"instance_key": "cardA"}, session.reads)
        field = result["fields"][0]
        self.assertEqual(field["owner_resource_id"], 6201)
        self.assertEqual((field["draft"], field["applied"]), ("draft", "applied"))
        self.assertEqual((field["draft_version"], field["state_version"], field["field_version"]), (7, 9, 6))
        self.assertFalse(field["available"])
        self.assertEqual(field["blocked_reason"], "locked")
        self.assertIsNone(field["focused"])

    def test_edit_example_does_not_collapse_equal_field_names_across_owners(self):
        first, second = state(6201).fields[0], state(6202).fields[0]
        combined = generated.GeneratedFormState(False, False, None, None, None, None,
                                               None, -1, (first, second), ())
        session = type("Session", (), {"form_state": lambda self: combined})()
        actual = example._owner_snapshot(session)
        self.assertEqual(len(actual["fields"]), 2)
        self.assertEqual(actual["fields"], [asdict(first), asdict(second)])
        self.assertFalse(actual["known"])
        self.assertIsNone(actual["state_version"])

    def test_missing_field_bodies_and_versions_remain_unknown(self):
        raw = "\n".join(["PROTOCOL CJGUI_SHARED_OPERATION/2", "KIND GENERATED_UI_FIELDS",
                          "PAYLOAD_LENGTH 40", "FIELD jobName 7101 ERROR none", "END"])
        field = generated.parse_generated_fields(response(raw))[0]
        self.assertIsNone(field.draft)
        self.assertIsNone(field.applied)
        self.assertIsNone(field.draft_version)
        self.assertIsNone(field.state_version)
        self.assertIsNone(field.field_version)
        self.assertEqual(field.owner_resource_id, -1)


if __name__ == "__main__":
    unittest.main()
