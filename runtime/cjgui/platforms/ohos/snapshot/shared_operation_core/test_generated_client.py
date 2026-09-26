#!/usr/bin/env python3
"""Contract tests for the typed generated-UI client.

These are protocol-boundary tests over the SAME public client module the export
ships. They do not replace a real application consumption (that runs in the
export chains); they pin the typed parsing/encoding rules, including the ones a
model-driven bridge depends on: capability/element/action/field types, candidate
vs scene acceptance, resolved instance identity and the "no silent newline"
encoding rule.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

MODULE_DIR = Path(__file__).resolve().parent
if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import client  # noqa: E402
import cjgui_generated_client as generated  # noqa: E402


def response(body: str) -> client.SharedOperationResponse:
    return client.parse_response(body)


CAPABILITIES = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_CAPABILITIES",
    "PAYLOAD_LENGTH 400",
    "GENERATED_UI 1",
    "BOUNDS 12 64 8 256",
    "COMPONENT vertical 1 64",
    "PROPERTY vertical gap INTEGER 0 0 32 0",
    "COMPONENT textInput 0 0",
    "PROPERTY textInput label STRING 0 0 0 100",
    "COMPONENT retentionEdit 0 0",
    "PROPERTY retentionEdit gap INTEGER 0 0 32 0",
    "COMPOSITE retentionEdit children=0 child_limit=0 expanded_nodes=4 expanded_depth=3",
    "ELEMENT retentionEdit root container parent=root field=none argument=none preset=none action=none label=",
    "ELEMENT retentionEdit edit field parent=root field=retentionCount argument=text preset=none action=none label=",
    "ELEMENT retentionEdit preset preset parent=root field=retentionCount argument=text preset=90 action=none label=设为 90",
    "ACTION APPLY_DRAFT argument=expectedDraftVersion 应用草稿",
    "FIELD label TEXT resource=81001 writer=EDIT_DRAFT_TEXT required=0 min=0 max=0 maxlen=0 callable=1 argument=text input=textInput label=规则名称",
    "END",
])

STRUCTURE_VERSION_0 = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_STRUCTURE",
    "STRUCTURE_VERSION 0",
    "CANDIDATE_VERSION 0",
    "SCENE_STATE none",
    "STRUCTURE_LENGTH 0",
    "END",
])

STRUCTURE_VERSION_1 = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_STRUCTURE",
    "STRUCTURE_VERSION 1",
    "CANDIDATE_VERSION 0",
    "SCENE_STATE scene_accepted",
    "STRUCTURE_LENGTH 120",
    "NODE 0 root vertical",
    "PROPERTY 0 root gap 8",
    "NODE 1 edit textInput field=label",
    "PROPERTY 1 edit label 规则名称",
    "END",
])

INSTANCES = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_INSTANCES",
    "STRUCTURE_VERSION 2",
    "CANDIDATE_VERSION 0",
    "SCENE_STATE scene_accepted",
    "INSTANCE_LENGTH 200",
    "INSTANCE root element=- role=- id=800001 kind=vertical semantic=generated-panel-node field=- action=- visible=1 bounds=10,20,300,180 label_hex=-",
    "INSTANCE edit element=edit role=field id=800002 kind=integerInput semantic=generated-edit-node field=retentionCount action=- visible=1 bounds=10,60,200,26 label_hex=E4BF9DE79599",
    "END",
])

FIELDS = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_FIELDS",
    "PAYLOAD_LENGTH 120",
    "FIELD retentionCount 81003 DRAFT_HEX 37 APPLIED_HEX 35 ERROR none FOCUS 1 SELECTION 1 1 VERSION 4",
    "END",
])

SUBMIT_PENDING = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_SUBMIT",
    "ENDPOINT_INSTANCE test-endpoint",
    "ENDPOINT_BIND_GENERATION 7",
    "APPLIED true",
    "REASON none",
    "PATH none",
    "VERSION_BEFORE 0",
    "VERSION_AFTER 0",
    "CANDIDATE_ACCEPTED true",
    "SCENE_ACCEPTED false",
    "CANDIDATE_VERSION 1",
    "END",
])

SUBMIT_STALE = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_SUBMIT",
    "ENDPOINT_INSTANCE test-endpoint",
    "ENDPOINT_BIND_GENERATION 7",
    "APPLIED false",
    "REASON structure_version_conflict",
    "PATH none",
    "VERSION_BEFORE 1",
    "VERSION_AFTER 1",
    "CANDIDATE_ACCEPTED false",
    "SCENE_ACCEPTED false",
    "CANDIDATE_VERSION 0",
    "END",
])

SNAPSHOT = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND CONTEXT",
    "VERSION 7",
    "ACTION SET_TITLE PARAMETERS 1 TARGETS 1 1",
    "ACTION_DISPLAY_NAME_UTF8_HEX SET_TITLE 18 E58699E59B9EE4BBBBE58AA1E6A087E9A298",
    "PARAMETER SET_TITLE title STRING REQUIRED",
    "END",
])

# One action with all four declared types so typed-argument validation can be
# exercised against a real published signature (not a comma name list).
SNAPSHOT_TYPED = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND CONTEXT",
    "VERSION 7",
    "ACTION TEST_PARAMS PARAMETERS 3 TARGETS 1 2",
    "ACTION_DISPLAY_NAME_UTF8_HEX TEST_PARAMS 4 74657374",
    "PARAMETER TEST_PARAMS count INTEGER REQUIRED",
    "PARAMETER TEST_PARAMS title STRING REQUIRED",
    "PARAMETER TEST_PARAMS replacements TEXT_REPLACEMENTS OPTIONAL",
    "END",
])


class CapabilityTests(unittest.TestCase):
    def test_capabilities_are_typed(self) -> None:
        capabilities = generated.parse_generated_capabilities(response(CAPABILITIES))
        self.assertEqual(capabilities.max_depth, 12)
        self.assertEqual(capabilities.max_nodes, 64)
        self.assertEqual(capabilities.component("vertical").child_limit, 64)
        self.assertEqual(capabilities.component("vertical").properties[0].name, "gap")
        self.assertEqual(capabilities.component("vertical").properties[0].maximum, 32)
        field = capabilities.field("label")
        self.assertEqual(field.editor_kind, "TEXT")
        self.assertEqual(field.resource_id, 81001)
        self.assertEqual(field.argument, "text")
        self.assertEqual(field.input_kind, "textInput")
        self.assertEqual(field.label, "规则名称")
        self.assertTrue(field.callable)
        self.assertEqual(capabilities.action("APPLY_DRAFT").arguments, ("expectedDraftVersion",))
        elements = capabilities.elements_of("retentionEdit")
        self.assertEqual(len(elements), 3)
        self.assertEqual(elements[1].role, "field")
        self.assertEqual(elements[1].element_key, "edit")
        self.assertEqual(elements[1].argument, "text")
        self.assertEqual(elements[2].preset, "90")
        self.assertEqual(elements[2].label, "设为 90")
        self.assertEqual(capabilities.composites[0].expanded_nodes, 4)


class StructureTests(unittest.TestCase):
    def test_structure_parse(self) -> None:
        structure = generated.parse_generated_structure(response(STRUCTURE_VERSION_1))
        self.assertEqual(structure.version, 1)
        self.assertEqual(structure.scene_state, "scene_accepted")
        self.assertEqual(len(structure.nodes), 2)
        self.assertEqual(structure.nodes[0].property("gap"), "8")
        self.assertEqual(structure.nodes[1].field_id, "label")

    def test_encode_round_trips_through_the_public_parser(self) -> None:
        nodes = (
            generated.GeneratedNode(0, "root", "vertical", None, None,
                                    (generated.GeneratedProperty("gap", "8"),)),
            generated.GeneratedNode(1, "edit", "textInput", "label", None,
                                    (generated.GeneratedProperty("label", "规则名称"),)),
        )
        payload = generated.encode_generated_structure(nodes)
        body = STRUCTURE_VERSION_1.replace(
            "\n".join(STRUCTURE_VERSION_1.split("\n")[5:8]),
            "STRUCTURE_LENGTH %d\n%s" % (len(payload.encode()), payload),
        )
        parsed = generated.parse_generated_structure(response(body))
        self.assertTrue(generated.same_structure(nodes, parsed.nodes))

    def test_different_content_is_not_the_same_structure(self) -> None:
        left = (generated.GeneratedNode(0, "root", "vertical", None, None,
                                        (generated.GeneratedProperty("gap", "8"),)),)
        right = (generated.GeneratedNode(0, "root", "vertical", None, None,
                                         (generated.GeneratedProperty("gap", "4"),)),)
        self.assertFalse(generated.same_structure(left, right))

    def test_newline_and_identifier_are_rejected(self) -> None:
        with self.assertRaises(generated.GeneratedUiError):
            generated.encode_generated_structure((
                generated.GeneratedNode(0, "root", "vertical", None, None,
                                        (generated.GeneratedProperty("gap", "8\n9"),)),))
        with self.assertRaises(generated.GeneratedUiError):
            generated.encode_generated_structure((generated.GeneratedNode(0, "bad key", "vertical", None, None),))
        with self.assertRaises(generated.GeneratedUiError):
            generated.encode_generated_structure((
                generated.GeneratedNode(0, "root", "vertical", None, None,
                                        (generated.GeneratedProperty("gap", "8"),
                                         generated.GeneratedProperty("gap", "9"))),))


class InstanceTests(unittest.TestCase):
    def test_instances_expose_identity_and_geometry(self) -> None:
        instances = generated.parse_generated_instances(response(INSTANCES))
        self.assertEqual(instances.structure_version, 2)
        root = instances.instance("root")
        self.assertEqual(root.node_id, 800001)
        self.assertEqual(root.kind, "vertical")
        self.assertEqual(root.bounds, (10, 20, 300, 180))
        self.assertTrue(root.visible)
        edit = instances.instance("edit", "edit")
        self.assertEqual(edit.role, "field")
        self.assertEqual(edit.field_id, "retentionCount")
        self.assertEqual(edit.label, "保留")
        self.assertIsNone(edit.action)

    def test_empty_projection_parses(self) -> None:
        body = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_INSTANCES",
            "STRUCTURE_VERSION 0",
            "CANDIDATE_VERSION 0",
            "SCENE_STATE none",
            "INSTANCE_LENGTH 0",
            "END",
        ])
        self.assertEqual(generated.parse_generated_instances(response(body)).instances, ())


class FieldAndSubmitTests(unittest.TestCase):
    def test_field_projection(self) -> None:
        values = generated.parse_generated_fields(response(FIELDS))
        self.assertEqual(len(values), 1)
        self.assertEqual(values[0].draft, "7")
        self.assertEqual(values[0].applied, "5")
        self.assertTrue(values[0].focused)
        self.assertEqual((values[0].selection_start, values[0].selection_end), (1, 1))
        self.assertEqual(values[0].draft_version, 4)

    def test_field_projection_preserves_an_unconfirmed_focus(self) -> None:
        """A producer that cannot confirm focus says `unknown` and publishes no
        selection; the client must not turn that into a confirmed False."""
        body = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_FIELDS",
            "PAYLOAD_LENGTH 110",
            "FIELD retentionCount 81003 DRAFT_HEX 37 APPLIED_HEX 35 ERROR none "
            "FOCUS unknown VERSION 4",
            "END",
        ])
        unknown = generated.parse_generated_fields(response(body))
        self.assertEqual(len(unknown), 1)
        self.assertIsNone(unknown[0].focused)
        self.assertIsNone(unknown[0].selection_start)
        self.assertIsNone(unknown[0].selection_end)

        # An unconfirmed NOT-focused fact stays False, and a confirmed one may
        # carry its real selection.
        not_focused = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_FIELDS",
            "PAYLOAD_LENGTH 110",
            "FIELD retentionCount 81003 DRAFT_HEX 37 APPLIED_HEX 35 ERROR none "
            "FOCUS 0 SELECTION 0 0 VERSION 4",
            "END",
        ])
        confirmed = generated.parse_generated_fields(response(not_focused))
        self.assertIs(confirmed[0].focused, False)
        self.assertEqual((confirmed[0].selection_start, confirmed[0].selection_end), (0, 0))

        # Anything else is a protocol error, never a silent default.
        bogus = body.replace("FOCUS unknown", "FOCUS probably")
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_generated_fields(response(bogus))

    def test_field_projection_publishes_owner_availability(self) -> None:
        """The owner's CURRENT availability travels with the field read, so an
        external caller never infers it from the draft or from an attempted
        write. `unknown` stays unknown instead of becoming a verdict."""
        blocked = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_FIELDS",
            "PAYLOAD_LENGTH 200",
            "FIELD title 8101 DRAFT_HEX 37 APPLIED_HEX 37 ERROR none FOCUS 0 "
            "SELECTION 0 0 AVAILABLE 0 REASON_HEX 66726f7a656e TARGET 42 STATE_VERSION 7 VERSION 4",
            "END",
        ])
        values = generated.parse_generated_fields(response(blocked))
        self.assertIs(values[0].available, False)
        self.assertEqual(values[0].blocked_reason, "frozen")
        self.assertEqual(values[0].owner_resource_id, 42)
        self.assertEqual(values[0].state_version, 7)

        unknown = blocked.replace("AVAILABLE 0 REASON_HEX 66726f7a656e", "AVAILABLE unknown REASON_HEX -")
        unresolved = generated.parse_generated_fields(response(unknown))
        self.assertIsNone(unresolved[0].available)
        self.assertIsNone(unresolved[0].blocked_reason)

        bogus = blocked.replace("AVAILABLE 0", "AVAILABLE maybe")
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_generated_fields(response(bogus))

    def test_candidate_and_scene_acceptance_are_separate(self) -> None:
        pending = generated.parse_generated_submit(response(SUBMIT_PENDING))
        self.assertTrue(pending.applied)
        self.assertTrue(pending.candidate_accepted)
        self.assertFalse(pending.scene_accepted)
        self.assertEqual(pending.candidate_version, 1)
        stale = generated.parse_generated_submit(response(SUBMIT_STALE))
        self.assertFalse(stale.applied)
        self.assertEqual(stale.reason, "structure_version_conflict")
        self.assertEqual((stale.version_before, stale.version_after), (1, 1))


class ActionSignatureTests(unittest.TestCase):
    def test_typed_actions_come_from_the_snapshot(self) -> None:
        actions = generated.parse_action_signatures(response(SNAPSHOT))
        self.assertEqual(len(actions), 1)
        self.assertEqual(actions[0].name, "SET_TITLE")
        self.assertEqual(actions[0].display_name, "写回任务标题")
        self.assertEqual(actions[0].parameters[0].value_type, "STRING")
        self.assertTrue(actions[0].parameters[0].required)
        self.assertEqual((actions[0].minimum_targets, actions[0].maximum_targets), (1, 1))


class SessionTests(unittest.TestCase):
    def test_wait_reports_timeout_with_the_last_observation(self) -> None:
        calls = {"count": 0}

        class FakeClient:
            descriptor = {"capability": "cap"}

            def request(self, payload, **kwargs):
                calls["count"] += 1
                self.last_kwargs = kwargs
                return response(STRUCTURE_VERSION_0)

        session = generated.GeneratedUiSession(FakeClient())
        wait = session.wait_for_structure(1, timeout_ms=30, poll_ms=5)
        self.assertEqual(wait.outcome, "timeout")
        self.assertEqual(wait.structure.version, 0)
        self.assertGreaterEqual(calls["count"], 2)

    def test_wait_with_a_zero_budget_issues_no_request(self) -> None:
        calls = {"count": 0}

        class FakeClient:
            descriptor = {"capability": "cap"}

            def request(self, payload, **kwargs):
                calls["count"] += 1
                return response(STRUCTURE_VERSION_0)

        session = generated.GeneratedUiSession(FakeClient())
        wait = session.wait_for_structure(1, timeout_ms=0, poll_ms=1)
        self.assertEqual(wait.outcome, "timeout")
        self.assertIsNone(wait.structure)
        self.assertEqual(calls["count"], 0)

    def test_invoke_requires_a_published_action_and_its_arguments(self) -> None:
        class FakeClient:
            descriptor = {"capability": "cap"}

            def request(self, payload):
                return response(SNAPSHOT)

            def get_context(self, *args, **kwargs):
                return response(SNAPSHOT)

            def invoke(self, *args, **kwargs):
                raise AssertionError("invoke must not run for an invalid request")

        session = generated.GeneratedUiSession(FakeClient())
        with self.assertRaises(generated.GeneratedUiError):
            session.invoke_action("NOT_PUBLISHED", [1])
        with self.assertRaises(generated.GeneratedUiError):
            session.invoke_action("SET_TITLE", [1])
        with self.assertRaises(generated.GeneratedUiError):
            session.invoke_action("SET_TITLE", [1, 2],
                                  [client.SharedOperationArgument.string("title", "x")])


class ArgumentValidationTests(unittest.TestCase):
    """Typed `invoke_action` validation: exact codes, no request on rejection."""

    class FakeClient:
        descriptor = {"capability": "cap"}

        def __init__(self) -> None:
            self.context_calls = 0
            self.invocations: list[tuple[tuple[object, ...], dict[str, object]]] = []

        def get_context(self, *args, **kwargs):
            self.context_calls += 1
            return response(SNAPSHOT_TYPED)

        def invoke(self, *args, **kwargs):
            self.invocations.append((args, kwargs))
            return response(SUBMIT_PENDING)

    def setUp(self) -> None:
        self.fake = self.FakeClient()
        self.session = generated.GeneratedUiSession(self.fake)

    def assert_validation(self, code: str, action: str, targets, arguments, **fields) -> None:
        with self.assertRaises(generated.GeneratedUiArgumentValidationError) as raised:
            self.session.invoke_action(action, targets, arguments, expected_version=7)
        error = raised.exception
        self.assertEqual(error.code, code)
        self.assertEqual(error.action, action)
        for name, expected in fields.items():
            self.assertEqual(getattr(error, name), expected, name)
        self.assertEqual(self.fake.invocations, [])

    def test_unknown_action(self) -> None:
        self.assert_validation("unknown_action", "NOT_PUBLISHED", [1], [])

    def test_target_count_out_of_range(self) -> None:
        self.assert_validation(
            "target_count_out_of_range", "TEST_PARAMS", [1, 2, 3],
            [client.SharedOperationArgument.integer("count", 1),
             client.SharedOperationArgument.string("title", "x")],
        )

    def test_duplicate_argument(self) -> None:
        self.assert_validation(
            "duplicate_argument", "TEST_PARAMS", [1],
            [client.SharedOperationArgument.integer("count", 1),
             client.SharedOperationArgument.integer("count", 2)],
            name="count", actual_type="INTEGER",
        )

    def test_unknown_argument(self) -> None:
        self.assert_validation(
            "unknown_argument", "TEST_PARAMS", [1],
            [client.SharedOperationArgument.integer("count", 1),
             client.SharedOperationArgument.string("title", "x"),
             client.SharedOperationArgument.string("nope", "x")],
            name="nope", actual_type="STRING",
        )

    def test_string_declaration_never_accepts_an_integer_argument(self) -> None:
        self.assert_validation(
            "argument_type_mismatch", "TEST_PARAMS", [1],
            [client.SharedOperationArgument.integer("count", 1),
             client.SharedOperationArgument.integer("title", 5)],
            name="title", expected_type="STRING", actual_type="INTEGER",
        )

    def test_integer_declaration_never_accepts_a_string_argument(self) -> None:
        self.assert_validation(
            "argument_type_mismatch", "TEST_PARAMS", [1],
            [client.SharedOperationArgument.string("count", "1"),
             client.SharedOperationArgument.string("title", "x")],
            name="count", expected_type="INTEGER", actual_type="STRING",
        )

    def test_missing_required_argument(self) -> None:
        self.assert_validation(
            "missing_required_argument", "TEST_PARAMS", [1],
            [client.SharedOperationArgument.integer("count", 1)],
            name="title", expected_type="STRING",
        )

    def test_unusable_action_metadata_is_reported(self) -> None:
        body = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND CONTEXT",
            "VERSION 7",
            "ACTION WEIRD PARAMETERS 1 TARGETS 1 1",
            "ACTION_DISPLAY_NAME_UTF8_HEX WEIRD 4 74657374",
            "PARAMETER WEIRD value FLOAT REQUIRED",
            "END",
        ])

        class BadMetadataClient(self.FakeClient):
            def get_context(self, *args, **kwargs):
                return response(body)

        session = generated.GeneratedUiSession(BadMetadataClient())
        with self.assertRaises(generated.GeneratedUiArgumentValidationError) as raised:
            session.invoke_action("WEIRD", [1])
        self.assertEqual(raised.exception.code, "invalid_action_metadata")
        self.assertEqual(raised.exception.action, "WEIRD")
        self.assertEqual(raised.exception.name, "value")
        self.assertEqual(raised.exception.actual_type, "FLOAT")

    def test_valid_text_replacements_argument_reaches_the_endpoint(self) -> None:
        replacements = client.SharedOperationArgument.text_replacements(
            "replacements", [client.TextReplacement(3, 6, "A")])
        self.session.invoke_action(
            "TEST_PARAMS", [1],
            [client.SharedOperationArgument.integer("count", 1),
             client.SharedOperationArgument.string("title", "x"),
             replacements],
            expected_version=7,
        )
        self.assertEqual(len(self.fake.invocations), 1)
        _args, kwargs = self.fake.invocations[0]
        self.assertEqual(kwargs.get("deadline_monotonic"), None)
        passed_arguments = _args[3]
        self.assertIn(replacements, passed_arguments)
        self.assertEqual(replacements.value_type, "TEXT_REPLACEMENTS")
        self.assertTrue(replacements.wire_line().startswith("ARG replacements TEXT_REPLACEMENTS "))


if __name__ == "__main__":
    unittest.main()
