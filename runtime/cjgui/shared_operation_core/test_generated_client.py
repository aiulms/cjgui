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


def _u8(text: str) -> str:
    return "u8:" + text.encode("utf-8").hex().upper()


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

# A capability payload that publishes the structured-value tokens the framework
# added for encoded effects. The values stay space-free in the published form,
# but the tokenizer must survive a value that does contain spaces.
EFFECT_CAPABILITIES = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_CAPABILITIES",
    "PAYLOAD_LENGTH 900",
    "GENERATED_UI 1",
    "BOUNDS 12 64 8 256",
    "COMPONENT vertical 1 64",
    "PROPERTY vertical shadow STRING 0 0 0 64 values=none "
    "encoding=offX,offY,blur,spread,#RRGGBBAA unit=logical_points "
    "range=offset:-4096..4096,blur:0..256,spread:0..128 "
    "semantics=none_or_empty=clear,absent=inherit stability=experimental "
    "support=macos:supported,ohos:unpublished_snapshot",
    "PROPERTY vertical gradient STRING 0 0 0 256 values=none "
    "encoding=sx,sy,ex,ey,pos:color|pos:color unit=wire_percent_0..100,normalized_0..1 "
    "range=coordinate:0..1,position:0..1,stops:2..4 "
    "semantics=none_or_empty=clear,absent=inherit stability=experimental "
    "support=macos:supported,ohos:unpublished_snapshot",
    "END",
])

WINDOW_BACKGROUND_CAPABILITIES = "\n".join([
    "PROTOCOL CJGUI_SHARED_OPERATION/2",
    "KIND GENERATED_UI_CAPABILITIES",
    "PAYLOAD_LENGTH 300",
    "GENERATED_UI 1",
    "BOUNDS 12 64 8 256",
    "WINDOW_BACKGROUND_PROPERTY windowBackground STRING root_only=1 "
    "encoding=opaque|system_content_area default=opaque omitted=opaque "
    "stability=experimental support=macos:experimental_supported,ohos:unpublished_snapshot",
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
    "KIND SNAPSHOT",
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
    "KIND SNAPSHOT",
    "VERSION 7",
    "ACTION TEST_PARAMS PARAMETERS 3 TARGETS 1 2",
    "ACTION_DISPLAY_NAME_UTF8_HEX TEST_PARAMS 4 74657374",
    "PARAMETER TEST_PARAMS count INTEGER REQUIRED",
    "PARAMETER TEST_PARAMS title STRING REQUIRED",
    "PARAMETER TEST_PARAMS replacements TEXT_REPLACEMENTS OPTIONAL",
    "END",
])


class CapabilityTests(unittest.TestCase):
    def test_window_background_discovery_is_typed_and_root_scoped(self) -> None:
        capabilities = generated.parse_generated_capabilities(response(WINDOW_BACKGROUND_CAPABILITIES))
        material = capabilities.window_background
        self.assertIsNotNone(material)
        self.assertEqual(material.name, "windowBackground")
        self.assertEqual(material.value_type, "STRING")
        self.assertTrue(material.root_only)
        self.assertEqual(material.values, ("opaque", "system_content_area"))
        self.assertEqual(material.default, "opaque")
        self.assertEqual(material.omitted, "opaque")
        self.assertEqual(material.stability, "experimental")
        self.assertEqual(material.backend_support,
                         "macos:experimental_supported,ohos:unpublished_snapshot")

    def test_window_background_unknown_discovery_token_is_rejected(self) -> None:
        body = WINDOW_BACKGROUND_CAPABILITIES.replace("root_only=1", "root_only=1 bogus=1")
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_generated_capabilities(response(body))

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

    def test_structured_value_tokens_are_exposed_on_the_property(self) -> None:
        capabilities = generated.parse_generated_capabilities(response(EFFECT_CAPABILITIES))
        vertical = capabilities.component("vertical")
        shadow = vertical.properties[0]
        self.assertEqual(shadow.name, "shadow")
        self.assertEqual(shadow.values, ("none",))
        self.assertEqual(shadow.encoding, "offX,offY,blur,spread,#RRGGBBAA")
        self.assertEqual(shadow.unit, "logical_points")
        self.assertEqual(shadow.value_range, "offset:-4096..4096,blur:0..256,spread:0..128")
        self.assertEqual(shadow.semantics, "none_or_empty=clear,absent=inherit")
        self.assertEqual(shadow.stability, "experimental")
        self.assertEqual(shadow.backend_support,
                         "macos:supported,ohos:unpublished_snapshot")
        # A caller can recover the encoded grammar, unit, UPPER BOUNDS and support
        # surface from discovery alone, without reading application source.
        self.assertEqual(shadow.range_entries(),
                         (("offset", "-4096", "4096"), ("blur", "0", "256"), ("spread", "0", "128")))
        gradient = vertical.properties[1]
        self.assertEqual(gradient.unit, "wire_percent_0..100,normalized_0..1")
        self.assertEqual(gradient.range_entries(),
                         (("coordinate", "0", "1"), ("position", "0", "1"), ("stops", "2", "4")))

    def test_unknown_property_token_is_refused_not_skipped(self) -> None:
        body = CAPABILITIES.replace("PROPERTY vertical gap INTEGER 0 0 32 0",
                                    "PROPERTY vertical gap INTEGER 0 0 32 0 bogus=1")
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_generated_capabilities(response(body))

    def test_property_token_value_may_contain_spaces(self) -> None:
        body = CAPABILITIES.replace("PROPERTY vertical gap INTEGER 0 0 32 0",
                                    "PROPERTY vertical gap INTEGER 0 0 32 0 semantics=none or empty=clear")
        capabilities = generated.parse_generated_capabilities(response(body))
        self.assertEqual(capabilities.component("vertical").properties[0].semantics,
                         "none or empty=clear")


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

    def test_empty_property_value_round_trips(self) -> None:
        nodes = (generated.GeneratedNode(0, "card", "label", None, None,
                                         (generated.GeneratedProperty("shadow", ""),)),)
        payload = generated.encode_generated_structure(nodes)
        # Empty never becomes an empty protocol token: the shared escape is used.
        self.assertIn("PROPERTY 0 card shadow \\e", payload.split("\n"))
        self.assertNotIn("PROPERTY 0 card shadow ", payload.split("\n"))
        body = STRUCTURE_VERSION_1.replace(
            "\n".join(STRUCTURE_VERSION_1.split("\n")[5:8]),
            "STRUCTURE_LENGTH %d\n%s" % (len(payload.encode()), payload),
        )
        parsed = generated.parse_generated_structure(response(body))
        self.assertEqual(parsed.nodes[0].properties,
                         (generated.GeneratedProperty("shadow", ""),))
        self.assertEqual(parsed.nodes[0].property("shadow"), "")
        self.assertTrue(generated.same_structure(nodes, parsed.nodes))

    def test_edge_space_property_value_is_rejected(self) -> None:
        with self.assertRaises(generated.GeneratedUiError):
            generated.encode_generated_structure((
                generated.GeneratedNode(0, "root", "vertical", None, None,
                                        (generated.GeneratedProperty("text", " leading"),)),))

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
    def test_image_resource_state_survives_typed_public_readback(self) -> None:
        body = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_INSTANCES",
            "STRUCTURE_VERSION 2",
            "CANDIDATE_VERSION 0",
            "SCENE_STATE scene_accepted",
            "INSTANCE_LENGTH 2",
            "INSTANCE root element=- role=- id=1 kind=vertical semantic=root field=- "
            "action=- resource=- resource_version=0 resource_state=- visible=1 "
            "bounds=0,0,100,100 label_hex=-",
            "INSTANCE art element=- role=- id=2 kind=image semantic=art field=- "
            "action=- resource=icon resource_version=7 resource_state=ready visible=1 "
            "bounds=0,0,80,40 label_hex=-",
            "END",
        ])
        instances = generated.parse_generated_instances(response(body))
        self.assertEqual(instances.instance("root").resource_state, "")
        self.assertEqual(instances.instance("art").resource_state, "ready")

    def test_control_semantics_survive_typed_public_readback(self) -> None:
        body = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_INSTANCES",
            "STRUCTURE_VERSION 4",
            "CANDIDATE_VERSION 4",
            "SCENE_STATE accepted",
            "INSTANCE_LENGTH 1",
            "INSTANCE row element=- role=- id=33 kind=action semantic=group-row field=- "
            "action=EXPAND resource=- resource_version=0 resource_state=- effectGroup=none "
            "control_role=row selected=1 expandable=1 expanded=0 enabled=0 level=2 "
            "row_key=group-leaf parent_key=group visible=1 bounds=1,2,30,20 label_hex=526f77",
            "END",
        ])
        row = generated.parse_generated_instances(response(body)).instance("row")
        self.assertIsNotNone(row)
        self.assertEqual((row.control_role, row.control_selected, row.control_expandable,
                          row.control_expanded, row.control_enabled, row.control_level,
                          row.control_row_key, row.control_parent_key),
                         ("row", True, True, False, False, 2, "group-leaf", "group"))

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
    def test_old_error_none_does_not_confirm_validation(self) -> None:
        field = generated.parse_generated_fields(response(FIELDS))[0]
        self.assertEqual(getattr(field, "validation_state", "missing"), "unknown")

    def test_field_validation_message_is_utf8_and_keeps_its_versions(self) -> None:
        message = "份数需在 1–24 之间 👩‍💻"
        body = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2", "KIND GENERATED_UI_FIELDS", "PAYLOAD_LENGTH 512",
            "FIELD copies 6202 DRAFT_HEX 30 APPLIED_HEX 34 ERROR invalid "
            "VERSION 2 VALIDATION_STATE invalid VALIDATION_MESSAGE_HEX "
            + message.encode().hex() + " VALIDATION_VERSION 2 FIELD_VERSION 1",
            "END"])
        field = generated.parse_generated_fields(response(body))[0]
        self.assertEqual(field.validation_error, message)
        self.assertEqual(getattr(field, "validation_state", "missing"), "invalid")
        self.assertEqual(getattr(field, "validation_version", None), 2)
        self.assertEqual(getattr(field, "field_version", None), 1)

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


class FormFeedbackTests(unittest.TestCase):
    def fixture(self) -> str:
        message = "份数需在 1–24 之间 👩‍💻".encode().hex()
        return "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2", "KIND GENERATED_UI_FIELDS", "PAYLOAD_LENGTH 512",
            "FORM_STATE KNOWN 1 CONSISTENT 1 VERSION 3 DRAFT_VERSION 2 APPLIED_VERSION 0 "
            f"CAN_APPLY 0 MESSAGE_HEX {message} TARGET 6200",
            "FIELD copies 6202 DRAFT_HEX 30 APPLIED_HEX 34 ERROR invalid AVAILABLE 1 REASON_HEX - "
            "TARGET 6200 STATE_VERSION 3 VERSION 2 VALIDATION_STATE invalid "
            f"VALIDATION_MESSAGE_HEX {message} VALIDATION_VERSION 3 FIELD_VERSION 1",
            f"ACTION_STATE APPLY_DRAFT AVAILABLE 0 REASON_HEX {message} TARGET 6200 STATE_VERSION 3",
            "ACTION_STATE CANCEL_DRAFT AVAILABLE 1 REASON_HEX - TARGET 6200 STATE_VERSION 3", "END"])

    def test_atomic_state_keeps_validation_separate_from_editability(self) -> None:
        state = generated.parse_generated_form_state(response(self.fixture()))
        self.assertTrue(state.known and state.consistent)
        self.assertEqual((state.state_version, state.draft_version, state.applied_version), (3, 2, 0))
        self.assertFalse(state.can_apply)
        self.assertTrue(state.fields[0].available)
        self.assertEqual(state.fields[0].validation_state, "invalid")
        self.assertEqual(state.message, state.fields[0].validation_error)
        self.assertEqual(state.message, state.actions[0].blocked_reason)
        self.assertTrue(state.actions[1].available)

    def test_old_provider_is_unknown_and_mixed_versions_are_rejected(self) -> None:
        state = generated.parse_generated_form_state(response(FIELDS))
        self.assertFalse(state.known)
        self.assertIsNone(state.can_apply)
        self.assertEqual(state.fields[0].validation_state, "unknown")
        for bad in (self.fixture().replace("VALIDATION_VERSION 3", "VALIDATION_VERSION 2"),
                    self.fixture().replace("CANCEL_DRAFT AVAILABLE 1", "CANCEL_DRAFT AVAILABLE perhaps"),
                    self.fixture().replace("CONSISTENT 1", "CONSISTENT 0")):
            with self.assertRaises(generated.GeneratedUiError):
                generated.parse_generated_form_state(response(bad))

    def test_one_public_query_supplies_the_whole_form(self) -> None:
        fixture = self.fixture()
        calls = []

        class FakeClient:
            descriptor = {"capability": "cap"}

            def request(self, payload, **kwargs):
                calls.append(payload)
                return response(fixture)

        session = generated.GeneratedUiSession(FakeClient())
        self.assertFalse(session.form_state().can_apply)
        self.assertEqual(len(calls), 1)
        self.assertIn("GET_GENERATED_UI_FIELDS", calls[0])

    def test_instance_and_owner_reads_name_exactly_one_target(self) -> None:
        fixture = self.fixture()
        calls = []

        class FakeClient:
            descriptor = {"capability": "cap"}

            def request(self, payload, **kwargs):
                calls.append(payload)
                return response(fixture)

        session = generated.GeneratedUiSession(FakeClient())
        instance_state = session.form_state(instance_key="cardA")
        owner_state = session.fields(owner_resource_id=6200)
        legacy_state = session.form_state()
        self.assertTrue(instance_state.known and owner_state[0].field_id == "copies")
        self.assertTrue(legacy_state.known)
        self.assertEqual(len(calls), 3)
        self.assertEqual(calls[0].splitlines()[-1], "GET_GENERATED_UI_FIELDS INSTANCE cardA")
        self.assertEqual(calls[1].splitlines()[-1], "GET_GENERATED_UI_FIELDS OWNER 6200")
        self.assertEqual(calls[2].splitlines()[-1], "GET_GENERATED_UI_FIELDS",
                         "the legacy command must stay compatible")
        for bad in ({"instance_key": "card A"}, {"instance_key": ""},
                    {"owner_resource_id": -1}, {"owner_resource_id": True},
                    {"instance_key": "cardA", "owner_resource_id": 6200}):
            with self.assertRaises(ValueError):
                session.form_state(**bad)
        self.assertEqual(len(calls), 3, "an invalid target must not reach the endpoint")


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
    def test_wait_keeps_timeout_outcome_after_shared_read_translation(self) -> None:
        class DeadlineClient:
            descriptor = {"capability": "cap"}

            def request(self, payload, **kwargs):
                raise TimeoutError("socket deadline")

        session = generated.GeneratedUiSession(DeadlineClient())
        wait = session.wait_for_structure(1, timeout_ms=30, poll_ms=1)
        self.assertEqual(wait.outcome, "timeout")
        self.assertIsNone(wait.structure)

    def test_typed_reads_refuse_error_envelopes_without_caching_empty_state(self) -> None:
        class RefusingClient:
            descriptor = {"capability": "cap"}
            failure = "unauthorized_action"

            def request(self, payload, **kwargs):
                return response("\n".join([
                    "PROTOCOL CJGUI_SHARED_OPERATION/2", "KIND ERROR",
                    f"ERROR {self.failure}", "END"]))

        transport = RefusingClient()
        session = generated.GeneratedUiSession(transport)
        for read in (session.capabilities, session.structure, session.fields,
                     session.form_state, session.instances, session.snapshot):
            with self.subTest(read=read.__name__):
                with self.assertRaisesRegex(generated.GeneratedUiError, "unauthorized_action"):
                    read()
                self.assertIsNone(session._capabilities)
                self.assertIsNone(session._observation_snapshot)
                self.assertIsNone(session.observation_anchor())
        transport.failure = "endpoint_replaced"
        for read in (session.capabilities, session.structure, session.fields, session.instances):
            with self.subTest(read=read.__name__, error=transport.failure):
                with self.assertRaises(generated.GeneratedUiEndpointError) as refused:
                    read()
                self.assertEqual(refused.exception.code, "endpoint_replaced")

    def test_typed_reads_preserve_legitimate_empty_and_reject_wrong_kind(self) -> None:
        class EmptyClient:
            descriptor = {"capability": "cap"}

            def request(self, payload, **kwargs):
                kind = payload.splitlines()[-1].removeprefix("GET_")
                return response(f"PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND {kind}\nEND")

        session = generated.GeneratedUiSession(EmptyClient())
        self.assertEqual(session.capabilities().fields, ())
        self.assertEqual(session.structure().nodes, ())
        self.assertEqual(session.fields(), ())
        self.assertEqual(session.instances().instances, ())
        wrong = response("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\nEND")
        for parse in (generated.parse_generated_capabilities, generated.parse_generated_structure,
                      generated.parse_generated_fields, generated.parse_generated_instances):
            with self.subTest(parser=parse.__name__):
                with self.assertRaisesRegex(generated.GeneratedUiError, "expected GENERATED_UI"):
                    parse(wrong)

    def test_typed_read_timeouts_keep_the_existing_deadline_classification(self) -> None:
        class TimeoutClient:
            descriptor = {"capability": "cap"}

            def request(self, payload, **kwargs):
                raise TimeoutError("read deadline")

        session = generated.GeneratedUiSession(TimeoutClient())
        for read in (session.capabilities, session.structure, session.fields,
                     session.form_state, session.instances):
            with self.subTest(read=read.__name__):
                with self.assertRaises(generated.GeneratedUiDeadlineExceeded):
                    read()

    def test_failed_capability_refresh_drops_the_old_cached_projection(self) -> None:
        class RefreshClient:
            descriptor = {"capability": "cap"}
            refused = False

            def request(self, payload, **kwargs):
                return response("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND ERROR\n"
                                "ERROR unauthorized_action\nEND" if self.refused else CAPABILITIES)

        transport = RefreshClient()
        session = generated.GeneratedUiSession(transport)
        self.assertTrue(session.capabilities().fields)
        transport.refused = True
        with self.assertRaisesRegex(generated.GeneratedUiError, "unauthorized_action"):
            session.capabilities(refresh=True)
        self.assertIsNone(session._capabilities)
        with self.assertRaisesRegex(generated.GeneratedUiError, "unauthorized_action"):
            session.capabilities()

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
            "KIND SNAPSHOT",
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


class PublicSurfaceTests(unittest.TestCase):
    def test_surface_support_and_evidence_are_typed_without_inference(self):
        payload = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_CAPABILITIES",
            "PAYLOAD_LENGTH 400",
            "GENERATED_UI 1",
            "SURFACE version=1.0 stability=experimental compatibility=additive_only "
            "protocol=2 subset=host,fields,commands future_key=kept",
            "BOUNDS 12 64 8 256",
            "COMPONENT vertical 0 0",
            "SUPPORT component vertical state=available reason=admission_accepted source=catalog_admission",
            "SUPPORT capability window_background state=unavailable "
            "reason=window_background_not_enabled source=catalog_opt_in",
            "SUPPORT component image state=fallback reason=text_only_backend source=application_declaration",
            "SUPPORT field " + _u8("同名字段 A") + " state=unavailable reason=" + _u8("软件 回退") +
            " source=application_declaration",
            "SUPPORT backend macos_appkit state=available reason=build_target source=platform_build",
            "EVIDENCE backend:macos_appkit state=unverified reason=delivery_evidence_not_declared",
            "EVIDENCE " + _u8("component:vertical") + " state=verified reason=" + _u8("人工 验收"),
            "END",
        ])
        capabilities = generated.parse_generated_capabilities(response(payload))
        self.assertEqual(capabilities.surface.version, "1.0")
        self.assertEqual(capabilities.surface.stability, "experimental")
        self.assertEqual(capabilities.surface.compatibility, "additive_only")
        self.assertEqual(capabilities.surface.subset, ("host", "fields", "commands"))
        self.assertIn(("future_key", "kept"), capabilities.surface.extra)
        fact = capabilities.support_for("component", "vertical")
        self.assertIsNotNone(fact)
        self.assertEqual(fact.state, "available")
        self.assertEqual(fact.source, "catalog_admission")
        encoded = capabilities.support_for("field", "同名字段 A")
        self.assertEqual(encoded.state, "unavailable")
        self.assertEqual(encoded.reason, "软件 回退")
        unavailable = capabilities.support_for("capability", "window_background")
        self.assertEqual(unavailable.state, "unavailable")
        self.assertEqual(unavailable.reason, "window_background_not_enabled")
        fallback = capabilities.support_for("component", "image")
        self.assertEqual(fallback.state, "fallback")
        self.assertEqual(fallback.source, "application_declaration")
        self.assertEqual(capabilities.evidence_for("backend:macos_appkit").state, "unverified")
        self.assertEqual(capabilities.evidence_for("component:vertical").state, "verified")
        self.assertEqual(capabilities.evidence_for("component:vertical").reason, "人工 验收")
        self.assertIsNone(capabilities.support_for("component", "not_registered"))
        self.assertIsNone(capabilities.evidence_for("backend:unknown"))

    def test_surface_refuses_incompatible_versions_by_name_and_keeps_additive_keys(self):
        def capabilities(surface_line: str | None):
            lines = [
                "PROTOCOL CJGUI_SHARED_OPERATION/2",
                "KIND GENERATED_UI_CAPABILITIES",
                "PAYLOAD_LENGTH 400",
                "GENERATED_UI 1",
            ]
            if surface_line is not None:
                lines.append(surface_line)
            lines.extend([
                "BOUNDS 12 64 8 256",
                "END",
            ])
            return generated.parse_generated_capabilities(response("\n".join(lines)))

        # A legacy producer without SURFACE stays readable: absence is not
        # upgraded into a claimed compatibility.
        self.assertIsNone(capabilities(None).surface)

        # Same major, additive key: compatible; the unknown key is preserved.
        additive = capabilities(
            "SURFACE version=1.1 stability=experimental compatibility=additive_only "
            "protocol=2 subset=host,fields future_key=kept")
        self.assertEqual(additive.surface.version, "1.1")
        self.assertIn(("future_key", "kept"), additive.surface.extra)

        with self.assertRaisesRegex(generated.GeneratedUiError,
                                    r"SURFACE protocol 3 is not supported"):
            capabilities("SURFACE version=1.0 stability=experimental compatibility=additive_only "
                         "protocol=3 subset=host")
        with self.assertRaisesRegex(generated.GeneratedUiError,
                                    r"SURFACE version 2\.0 is not supported"):
            capabilities("SURFACE version=2.0 stability=experimental compatibility=additive_only "
                         "protocol=2 subset=host")
        with self.assertRaisesRegex(generated.GeneratedUiError,
                                    r"SURFACE compatibility breaking is not supported"):
            capabilities("SURFACE version=1.0 stability=experimental compatibility=breaking "
                         "protocol=2 subset=host")

    def test_duplicate_support_fact_is_refused(self):
        payload = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_CAPABILITIES",
            "PAYLOAD_LENGTH 400",
            "GENERATED_UI 1",
            "SUPPORT component image state=available reason=admission_accepted source=catalog_admission",
            "SUPPORT component image state=fallback reason=text_only_backend source=application_declaration",
            "END",
        ])
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_generated_capabilities(response(payload))

    def test_unknown_support_state_is_refused(self):
        payload = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND GENERATED_UI_CAPABILITIES",
            "PAYLOAD_LENGTH 400",
            "GENERATED_UI 1",
            "SUPPORT component vertical state=maybe reason=guessed source=catalog",
            "END",
        ])
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_generated_capabilities(response(payload))

    def test_discovery_budget_and_controls_apply_after_decoding(self):
        def parse_support(item_token: str, reason_token: str):
            payload = "\n".join([
                "PROTOCOL CJGUI_SHARED_OPERATION/2",
                "KIND GENERATED_UI_CAPABILITIES",
                "PAYLOAD_LENGTH 400",
                "GENERATED_UI 1",
                f"SUPPORT component {item_token} state=available "
                f"reason={reason_token} source=catalog_admission",
                "END",
            ])
            return generated.parse_generated_capabilities(response(payload))

        def parse_evidence(item_token: str, reason_token: str):
            payload = "\n".join([
                "PROTOCOL CJGUI_SHARED_OPERATION/2",
                "KIND GENERATED_UI_CAPABILITIES",
                "PAYLOAD_LENGTH 400",
                "GENERATED_UI 1",
                f"EVIDENCE {item_token} state=unverified reason={reason_token}",
                "END",
            ])
            return generated.parse_generated_capabilities(response(payload))

        # The reproduced gap: a literal token skipped the byte budget its own
        # encoded form was checked against.
        long_item = "a" * 129
        for token in (long_item, _u8(long_item)):
            with self.assertRaises(generated.GeneratedUiError):
                parse_support(token, "admission_accepted")
        legal = "a" * 128
        legal_fact = parse_support(legal, "admission_accepted").support_for("component", legal)
        self.assertIsNotNone(legal_fact)
        self.assertEqual(legal_fact.state, "available")

        # Control characters are refused after either decoding path.
        for token in ("u8:00", _u8("\u0000"), "u8:7F"):
            with self.assertRaises(generated.GeneratedUiError):
                parse_support("component", token)
            with self.assertRaises(generated.GeneratedUiError):
                parse_evidence(token, "unverified_reason")

        long_evidence = "e" * 193
        for token in (long_evidence, _u8(long_evidence)):
            with self.assertRaises(generated.GeneratedUiError):
                parse_evidence(token, "declared")

        # Legacy plaintext without spaces, Chinese and encoded spaces remain
        # legal: only the decoded value's facts are checked.
        plain = parse_support("同名字段", "说明")
        self.assertEqual(plain.support_for("component", "同名字段").reason, "说明")
        spaced = parse_support(_u8("同名字段 A"), _u8("人工 验收"))
        self.assertEqual(spaced.support_for("component", "同名字段 A").reason, "人工 验收")
        evidence = parse_evidence(_u8("component:vertical"), _u8("人工 验收"))
        self.assertEqual(evidence.evidence_for("component:vertical").reason, "人工 验收")

    def test_remote_error_preserves_code_detail_version_target_and_unknown_code(self):
        body = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND SNAPSHOT",
            "ERROR owner_busy DETAIL_HEX 64656c61796564 REQUEST_VERSION 7 "
            "OBSERVED_VERSION 9 TARGET window:1",
            "END",
        ])
        with self.assertRaises(generated.GeneratedUiRemoteError) as caught:
            generated._result_values(response(body), "SNAPSHOT")
        error = caught.exception
        self.assertEqual(error.code, "owner_busy")
        self.assertEqual(error.detail, "delayed")
        self.assertEqual(error.versions, {"REQUEST_VERSION": 7, "OBSERVED_VERSION": 9})
        self.assertEqual(error.request_version, 7)
        self.assertEqual(error.observed_version, 9)
        self.assertEqual(error.target, "window:1")
        self.assertFalse(error.unknown)

        unknown_body = "\n".join([
            "PROTOCOL CJGUI_SHARED_OPERATION/2",
            "KIND SNAPSHOT",
            "ERROR future_refusal",
            "END",
        ])
        with self.assertRaises(generated.GeneratedUiRemoteError) as unknown_caught:
            generated._result_values(response(unknown_body), "SNAPSHOT")
        self.assertEqual(unknown_caught.exception.code, "future_refusal")
        self.assertTrue(unknown_caught.exception.unknown)
        self.assertEqual(unknown_caught.exception.versions, {})


if __name__ == "__main__":
    unittest.main()
