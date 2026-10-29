#!/usr/bin/env python3
"""Contract tests for the key-addressed generated-UI editor.

These pin the local plan/preflight semantics and the submission outcome
classification over the SAME typed client.  They do not replace a real
application chain; the live mixed-form chain is recorded in
GENERATED_EDITING.md and the phase evidence directory.
"""

from __future__ import annotations

import contextlib
import hashlib
import io
import json
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from unittest.mock import patch

MODULE_DIR = Path(__file__).resolve().parent
if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import cjgui_generated_edit as editor  # noqa: E402
import cjgui_generated_client as generated  # noqa: E402


def props(**values):
    return tuple(generated.GeneratedProperty(name, value) for name, value in values.items())


def capability_catalog(**overrides):
    defaults = dict(
        max_depth=4,
        max_nodes=8,
        max_properties_per_node=3,
        max_string_length=32,
        components=(
            generated.GeneratedComponentSpec("vertical", True, 8, (
                generated.GeneratedPropertySpec("gap", "INTEGER", False, 0, 32, 0),
                generated.GeneratedPropertySpec("padding", "INTEGER", False, 0, 32, 0),
            )),
            generated.GeneratedComponentSpec("label", False, 0, (
                generated.GeneratedPropertySpec("text", "STRING", True, 0, 0, 16),
                generated.GeneratedPropertySpec("fontSize", "INTEGER", False, 0, 96, 0),
            )),
            generated.GeneratedComponentSpec("textInput", False, 0, (
                generated.GeneratedPropertySpec("label", "STRING", False, 0, 0, 32),
            )),
            generated.GeneratedComponentSpec("action", False, 0, (
                generated.GeneratedPropertySpec("label", "STRING", False, 0, 0, 32),
            )),
        ),
        composites=(),
        elements=(),
        actions=(generated.GeneratedActionSpec("APPLY_DRAFT", "apply", ()),),
        fields=(generated.GeneratedFieldSpec(
            "jobName", "textInput", 81001, "EDIT_DRAFT_TEXT", False, 0, 0, 0, True,
            "text", "textInput", "Job"),),
        image_resources=(),
        window_background=None,
        font_resources=(),
    )
    defaults.update(overrides)
    return generated.GeneratedCapabilities(**defaults)


BASE_NODES = (
    generated.GeneratedNode(0, "root", "vertical", None, None, props(gap="6", padding="4")),
    generated.GeneratedNode(1, "title", "label", None, None, props(text="Title", fontSize="14")),
    generated.GeneratedNode(1, "editor", "textInput", "jobName", None, props(label="Job")),
    generated.GeneratedNode(1, "panel", "vertical", None, None, props(gap="2")),
    generated.GeneratedNode(2, "panel-label", "label", None, None, props(text="Panel")),
    generated.GeneratedNode(1, "apply", "action", None, "APPLY_DRAFT", props(label="Apply")),
)

BASE_STRUCTURE = generated.GeneratedStructure(7, 0, "pending", BASE_NODES)
IDENTITY = generated.GeneratedEndpointIdentity("endpoint-a", 3)


def snapshot_for(structure, identity=IDENTITY, *, candidate_state="scene_accepted",
                 candidate_token=None):
    return generated.GeneratedSnapshot(
        stream_epoch=1, stream_identity="stream-a", cursor=1, endpoint=identity,
        owner_field_revision=0, owner_draft_revision=0, binding_revision=0,
        accepted_structure_version=structure.version,
        candidate_token=structure.candidate_version if candidate_token is None else candidate_token,
        candidate_state=candidate_state, window_accepted_scene_version=0,
        window_geometry_revision=0, window_interaction_revision=0,
        instance_revision=0, resource_revision=0, style_revision=0,
        owner_pending_scene=False, structure_candidate_pending=False,
        fields_text="", structure_text=generated.encode_generated_structure(structure.nodes),
        instances_text="", styles_text="")


def plan(*operations, base_version=7):
    return generated_plan(operations, base_version)


def generated_plan(operations, base_version):
    return editor.edit_plan_from_dict({"base_version": base_version,
                                       "operations": list(operations)})


def accepted_wait(token, version, identity=IDENTITY, replaced=False):
    state = generated.GeneratedCandidateState(
        "ACCEPTED", "scene_accepted", "none", "", version, token, 0, identity,
        accepted_then_replaced=replaced)
    return generated.GeneratedCandidateWait("terminal", state, 2)


def submit_reply(*, accepted=True, token=91, before=7, after=8, candidate_version=8,
                 reason="none", path="", identity=IDENTITY):
    return generated.GeneratedSubmitResult(
        applied=accepted, reason=reason, path=path, version_before=before,
        version_after=after, candidate_accepted=accepted, scene_accepted=False,
        candidate_version=candidate_version, candidate_token=token, receipt="receipt-1",
        endpoint_identity=identity)


class FakeSession:
    """Only the typed surface the editor is allowed to use."""

    def __init__(self, *, structures=(), replies=(), waits=(), capabilities=None,
                 snapshots=(), candidate_states=()):
        self._structures = list(structures)
        self._snapshots = list(snapshots) if snapshots else None
        self._replies = list(replies)
        self._waits = list(waits)
        self._candidate_states = list(candidate_states)
        self.capabilities_object = capabilities or capability_catalog()
        self.calls = []
        self.submitted = []
        self.submitted_documents = []
        self.submit_versions = []
        self.wait_timeouts = []

    def capabilities(self):
        self.calls.append("capabilities")
        return self.capabilities_object

    def structure(self):
        self.calls.append("structure")
        item = self._structures.pop(0) if len(self._structures) > 1 else self._structures[0]
        if isinstance(item, BaseException):
            raise item
        return item

    def snapshot(self, *, deadline_monotonic=None):
        self.calls.append("snapshot")
        if self._snapshots is not None:
            item = self._snapshots.pop(0) if len(self._snapshots) > 1 else self._snapshots[0]
        else:
            item = self._structures.pop(0) if len(self._structures) > 1 else self._structures[0]
        if isinstance(item, BaseException):
            raise item
        if isinstance(item, generated.GeneratedSnapshot):
            return item
        return snapshot_for(item)

    def candidate_state(self, token, *, endpoint=None, deadline_monotonic=None):
        self.calls.append("candidate_state")
        if not self._candidate_states:
            raise AssertionError("unexpected candidate state read")
        item = self._candidate_states.pop(0)
        if isinstance(item, BaseException):
            raise item
        return item

    def submit(self, nodes, expected_version, *, deadline_monotonic=None):
        self.calls.append("submit")
        self.submitted.append(tuple(nodes))
        self.submit_versions.append(expected_version)
        if not self._replies:
            raise AssertionError("unexpected submit")
        reply = self._replies.pop(0)
        if isinstance(reply, BaseException):
            raise reply
        return reply

    def submit_document(self, document, expected_version, *, deadline_monotonic=None):
        self.calls.append("submit")
        self.submitted.append(generated.encode_generated_structure_document(document))
        self.submitted_documents.append(document)
        self.submit_versions.append(expected_version)
        if not self._replies:
            raise AssertionError("unexpected submit")
        reply = self._replies.pop(0)
        if isinstance(reply, BaseException):
            raise reply
        return reply

    def wait_for_candidate_result(self, ticket, *, timeout_ms, poll_ms):
        self.calls.append("candidate")
        self.wait_timeouts.append(timeout_ms)
        if not self._waits:
            raise AssertionError("unexpected candidate wait")
        wait = self._waits.pop(0)
        if isinstance(wait, BaseException):
            raise wait
        return wait

    def invoke_action(self, *args, **kwargs):
        raise AssertionError("structure editing must not invoke a domain action")

    def fields(self, *args, **kwargs):
        raise AssertionError("structure editing must not read or submit drafts")


class TreeTests(unittest.TestCase):
    def test_round_trip_preserves_keys_bindings_properties_and_order(self):
        root = editor.tree_from_nodes(BASE_NODES)
        self.assertEqual(root.key, "root")
        self.assertEqual([child.key for child in root.children],
                         ["title", "editor", "panel", "apply"])
        self.assertEqual(root.children[1].field_id, "jobName")
        self.assertEqual(root.children[3].action, "APPLY_DRAFT")
        self.assertTrue(generated.same_structure(BASE_NODES, editor.generated_nodes_of(root)))

    def test_malformed_flat_descriptions_are_refused(self):
        orphan = (generated.GeneratedNode(0, "root", "vertical", None, None),
                  generated.GeneratedNode(2, "deep", "label", None, None))
        skipped = (generated.GeneratedNode(0, "root", "vertical", None, None),
                   generated.GeneratedNode(1, "child", "vertical", None, None),
                   generated.GeneratedNode(3, "deep", "label", None, None))
        duplicate = (generated.GeneratedNode(0, "root", "vertical", None, None),
                     generated.GeneratedNode(1, "same", "label", None, None),
                     generated.GeneratedNode(1, "same", "label", None, None))
        for nodes in ((), orphan, skipped, duplicate):
            with self.subTest(nodes=nodes):
                with self.assertRaises(editor.GeneratedEditError):
                    editor.tree_from_nodes(nodes)


class PlanTests(unittest.TestCase):
    def apply(self, operations, structure=BASE_STRUCTURE, capabilities=None):
        return editor.preview_plan(structure, plan(*operations), capabilities)

    def test_property_edit_keeps_untouched_declarations_and_bindings(self):
        preview = self.apply([
            {"op": "set_property", "key": "title", "name": "fontSize", "value": 22},
        ])
        title = editor._find_node(preview.root, "title")
        editor_node = editor._find_node(preview.root, "editor")
        self.assertEqual(title.property("text"), "Title")
        self.assertEqual(title.property("fontSize"), "22")
        self.assertEqual(editor_node.field_id, "jobName")
        self.assertTrue(all(prop.name != "garbage" for prop in preview.root.properties))

    def test_insert_subtree_delete_and_move_are_one_batch(self):
        preview = self.apply([
            {"op": "insert", "parent": "root", "index": 1,
             "node": {"key": "added", "kind": "vertical", "properties": {"gap": "1"},
                      "children": [
                          {"key": "added-a", "kind": "label", "properties": {"text": "A"}},
                          {"key": "added-b", "kind": "label", "properties": {"text": "B"}},
                      ]}},
            {"op": "move", "key": "panel", "parent": "root", "index": 0},
            {"op": "delete", "key": "apply"},
        ])
        self.assertEqual([child.key for child in preview.root.children],
                         ["panel", "title", "added", "editor"])
        added = editor._find_node(preview.root, "added")
        self.assertEqual([child.key for child in added.children], ["added-a", "added-b"])
        self.assertIsNone(editor._find_node(preview.root, "apply"))
        self.assertIn("+ added (vertical) under root at 2 (+3 nodes)", preview.diff.lines)
        self.assertIn("root", preview.diff.reordered_parents)
        self.assertIn("- apply (action)", preview.diff.lines)

    def test_reorder_without_parent_change_is_reported(self):
        preview = self.apply([
            {"op": "move", "key": "apply", "parent": "root", "index": 0},
        ])
        self.assertEqual([child.key for child in preview.root.children],
                         ["apply", "title", "editor", "panel"])
        self.assertIn("root", preview.diff.reordered_parents)
        self.assertEqual(preview.diff.moved, ())

    def test_remove_property(self):
        preview = self.apply([
            {"op": "remove_property", "key": "title", "name": "fontSize"},
        ])
        self.assertEqual(editor._find_node(preview.root, "title").property("fontSize"), "")
        self.assertIn("~ title.fontSize: unset (was '14')", preview.diff.lines)

    def test_unknown_key_is_refused_with_the_operation_index(self):
        with self.assertRaises(editor.GeneratedEditError) as caught:
            self.apply([{"op": "set_property", "key": "missing", "name": "gap", "value": "1"}])
        self.assertEqual(caught.exception.code, "unknown_key")
        self.assertEqual(caught.exception.operation_index, 0)

    def test_duplicate_key_inside_an_inserted_subtree_is_refused(self):
        with self.assertRaises(editor.GeneratedEditError) as caught:
            self.apply([{"op": "insert", "parent": "root", "index": 0,
                         "node": {"key": "x", "kind": "vertical", "children": [
                             {"key": "x", "kind": "label", "properties": {"text": "A"}}]}}])
        self.assertEqual(caught.exception.code, "duplicate_key")

    def test_inserting_an_existing_key_is_refused(self):
        with self.assertRaises(editor.GeneratedEditError) as caught:
            self.apply([{"op": "insert", "parent": "root", "index": 0,
                         "node": {"key": "title", "kind": "label",
                                  "properties": {"text": "again"}}}])
        self.assertEqual(caught.exception.code, "duplicate_key")

    def test_cycles_and_root_operations_are_refused(self):
        cases = [
            ({"op": "move", "key": "panel", "parent": "panel-label", "index": 0}, "cycle"),
            ({"op": "move", "key": "panel", "parent": "panel", "index": 0}, "cycle"),
            ({"op": "move", "key": "root", "parent": "panel", "index": 0}, "root_move"),
            ({"op": "delete", "key": "root"}, "root_delete"),
        ]
        for operation, code in cases:
            with self.subTest(operation=operation):
                with self.assertRaises(editor.GeneratedEditError) as caught:
                    self.apply([operation])
                self.assertEqual(caught.exception.code, code)

    def test_out_of_range_indexes_are_refused(self):
        for operation in (
            {"op": "insert", "parent": "root", "index": 9,
             "node": {"key": "x", "kind": "label", "properties": {"text": "X"}}},
            {"op": "move", "key": "title", "parent": "root", "index": -1},
        ):
            with self.subTest(operation=operation):
                with self.assertRaises(editor.GeneratedEditError) as caught:
                    self.apply([operation])
                self.assertEqual(caught.exception.code, "index_out_of_range")

    def test_no_change_plan_is_refused(self):
        with self.assertRaises(editor.GeneratedEditError) as caught:
            self.apply([{"op": "set_property", "key": "root", "name": "gap", "value": "6"}])
        self.assertEqual(caught.exception.code, "no_changes")

    def test_plan_against_another_base_version_is_stale(self):
        stale = generated_plan([{"op": "set_property", "key": "root", "name": "gap",
                                 "value": "9"}], 6)
        with self.assertRaises(editor.GeneratedEditError) as caught:
            editor.preview_plan(BASE_STRUCTURE, stale)
        self.assertEqual(caught.exception.code, "stale_base_version")

    def test_preview_is_explicitly_local(self):
        preview = self.apply([
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"},
        ])
        self.assertTrue(preview.local_only)
        self.assertIn("LOCAL PREVIEW (not submitted", preview.to_text())
        rendered = preview.to_dict()
        self.assertTrue(rendered["local_only"])
        self.assertEqual(rendered["base_version"], 7)
        self.assertNotIn("accepted", rendered)


class PlanJsonTests(unittest.TestCase):
    def test_valid_json_plan(self):
        text = json.dumps({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": 9},
            {"op": "insert", "parent": "root", "index": 0,
             "node": {"key": "x", "kind": "label", "properties": {"text": True}}},
        ]})
        parsed = editor.edit_plan_from_text(text)
        self.assertEqual(parsed.base_version, 7)
        self.assertEqual(parsed.operations[0].value, "9")
        self.assertEqual(parsed.operations[1].node.property("text"), "true")

    def test_unknown_fields_and_operations_are_refused(self):
        cases = [
            {"base_version": 7, "operations": [], "extra": 1},
            {"base_version": 7, "operations": [{"op": "explode", "key": "root"}]},
            {"base_version": 7, "operations": [{"op": "delete", "key": "root", "extra": 1}]},
            {"base_version": True, "operations": [{"op": "delete", "key": "title"}]},
            {"base_version": 7, "operations": [{"op": "move", "key": "title",
                                                "parent": "root", "index": True}]},
            {"base_version": 7, "operations": [{"op": "set_property", "key": "root",
                                                "name": "gap", "value": None}]},
            {"base_version": 7, "operations": [{"op": "insert", "parent": "root", "index": 0,
                                                "node": {"key": "bad key", "kind": "label"}}]},
        ]
        for value in cases:
            with self.subTest(value=value):
                with self.assertRaises(editor.GeneratedEditError) as caught:
                    editor.edit_plan_from_dict(value)
                self.assertEqual(caught.exception.code, "invalid_plan")


class PreflightTests(unittest.TestCase):
    def preview(self, operations, capabilities, base=BASE_STRUCTURE):
        return editor.preview_plan(base, plan(*operations), capabilities)

    def assert_code(self, code, operations, capabilities=None):
        with self.assertRaises(editor.GeneratedEditError) as caught:
            self.preview(operations, capabilities or capability_catalog())
        self.assertEqual(caught.exception.code, code)

    def test_unknown_kind_property_field_and_action(self):
        self.assert_code("unknown_kind", [
            {"op": "insert", "parent": "root", "index": 0,
             "node": {"key": "x", "kind": "hologram"}}])
        self.assert_code("unknown_property", [
            {"op": "set_property", "key": "title", "name": "nonsense", "value": "1"}])
        self.assert_code("unknown_field", [
            {"op": "insert", "parent": "root", "index": 0,
             "node": {"key": "x", "kind": "textInput", "field": "missing"}}])
        self.assert_code("unknown_action", [
            {"op": "insert", "parent": "root", "index": 0,
             "node": {"key": "x", "kind": "action", "action": "MISSING"}}])

    def test_required_property_and_child_rules(self):
        self.assert_code("missing_required_property", [
            {"op": "insert", "parent": "root", "index": 0,
             "node": {"key": "x", "kind": "label"}}])
        self.assert_code("children_not_allowed", [
            {"op": "insert", "parent": "title", "index": 0,
             "node": {"key": "x", "kind": "label", "properties": {"text": "X"}}}])
        self.assert_code("child_limit_exceeded", [
            {"op": "insert", "parent": "root", "index": 0,
             "node": {"key": "space-a", "kind": "vertical"}},
            {"op": "insert", "parent": "root", "index": 0,
             "node": {"key": "space-b", "kind": "vertical"}}],
            capability_catalog(components=(
                generated.GeneratedComponentSpec("vertical", True, 4, (
                    generated.GeneratedPropertySpec("gap", "INTEGER", False, 0, 32, 0),
                    generated.GeneratedPropertySpec("padding", "INTEGER", False, 0, 32, 0))),
                *capability_catalog().components[1:])))

    def test_property_value_types_ranges_and_lengths(self):
        self.assert_code("property_not_integer", [
            {"op": "set_property", "key": "root", "name": "gap", "value": "wide"}])
        self.assert_code("property_out_of_range", [
            {"op": "set_property", "key": "root", "name": "gap", "value": "99"}])
        self.assert_code("property_too_long", [
            {"op": "set_property", "key": "title", "name": "text", "value": "x" * 17}])
        capabilities = capability_catalog(components=(
            generated.GeneratedComponentSpec("vertical", True, 4, (
                generated.GeneratedPropertySpec("gap", "INTEGER", False, 0, 32, 0),
                generated.GeneratedPropertySpec("padding", "INTEGER", False, 0, 32, 0))),
            generated.GeneratedComponentSpec("label", False, 0, (
                generated.GeneratedPropertySpec("text", "STRING", True, 0, 0, 16,
                                                values=("Title", "Panel", "Other")),
                generated.GeneratedPropertySpec("fontSize", "INTEGER", False, 0, 96, 0))),
            *capability_catalog().components[2:]))
        self.assert_code("property_value_not_allowed", [
            {"op": "set_property", "key": "title", "name": "text", "value": "C"}],
            capabilities)

    def test_depth_and_node_budgets(self):
        deep = {"key": "d0", "kind": "vertical"}
        cursor = deep
        for depth in range(1, 5):
            child = {"key": f"d{depth}", "kind": "vertical" if depth < 4 else "label",
                     "properties": {} if depth < 4 else {"text": "deep"}}
            cursor["children"] = [child]
            cursor = child
        self.assert_code("max_depth_exceeded", [
            {"op": "insert", "parent": "root", "index": 0, "node": deep}])
        self.assert_code("max_nodes_exceeded", [
            {"op": "insert", "parent": "root", "index": 0,
             "node": {"key": f"n{index}", "kind": "label", "properties": {"text": "X"}}}
            for index in range(4)])
        self.assert_code("too_many_properties", [
            {"op": "set_property", "key": "title", "name": "text", "value": "x"},
            {"op": "set_property", "key": "title", "name": "fontSize", "value": "12"},
            {"op": "set_property", "key": "title", "name": "semanticLabel", "value": "X"}],
            capability_catalog(max_properties_per_node=2))


class DiffTests(unittest.TestCase):
    def test_diff_lists_changes_in_readable_order(self):
        preview = editor.preview_plan(BASE_STRUCTURE, plan(
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"},
            {"op": "delete", "key": "apply"},
        ))
        text = preview.to_text()
        self.assertIn("BASE_VERSION 7", text)
        self.assertIn("root.gap: '6' -> '9'", text)
        self.assertIn("- apply (action)", text)
        self.assertLess(text.index("root.gap"), text.index("- apply"))


class SubmissionTests(unittest.TestCase):
    def preview(self):
        return editor.preview_plan(BASE_STRUCTURE, plan(
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}))

    def accepted_structure(self, version=8, padding="4"):
        nodes = [generated.GeneratedNode(0, "root", "vertical", None, None,
                                         props(gap="9", padding=padding))] + list(BASE_NODES[1:])
        return generated.GeneratedStructure(version, 0, "pending", tuple(nodes))

    def test_accepted_requires_ticket_and_exact_readback(self):
        session = FakeSession(
            structures=[self.accepted_structure()],
            replies=[submit_reply()],
            waits=[accepted_wait(91, 8)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "accepted")
        self.assertTrue(outcome.exact_readback)
        self.assertEqual(outcome.accepted_version, 8)
        self.assertIsNotNone(outcome.submit_to_accepted_ms)
        self.assertEqual(session.calls, ["submit", "candidate", "snapshot"])
        self.assertEqual(session.submit_versions, [7])

    def test_version_increment_alone_is_not_success(self):
        session = FakeSession(
            structures=[self.accepted_structure()],
            replies=[submit_reply()],
            waits=[accepted_wait(91, 8)])
        preview = self.preview()
        forged = dataclass_replace_nodes(preview, (generated.GeneratedNode(
            0, "root", "vertical", None, None, props(gap="99", padding="4")),))
        outcome = editor.submit_preview(session, forged)
        self.assertEqual(outcome.outcome, "readback_mismatch")
        self.assertFalse(outcome.exact_readback)

    def test_rejected_candidate_keeps_old_structure(self):
        rejected = generated.GeneratedCandidateState(
            "REJECTED", "none", "unknown_component", "/root/x", 0, 0, 0, IDENTITY)
        session = FakeSession(
            structures=[BASE_STRUCTURE],
            replies=[submit_reply(accepted=False, reason="unknown_component",
                                  token=92, after=7, candidate_version=0)],
            waits=[generated.GeneratedCandidateWait("terminal", rejected, 1)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "rejected")
        self.assertEqual(outcome.reason, "unknown_component")
        self.assertEqual(outcome.terminal_state, "REJECTED")
        self.assertEqual(outcome.path, "/root/x")
        self.assertEqual(session.calls, ["submit", "candidate"])

    def test_synchronous_version_conflict_is_confirmed_by_its_ticket(self):
        rejected = generated.GeneratedCandidateState(
            "REJECTED", "none", "structure_version_conflict", "", 0, 0, 0, IDENTITY)
        session = FakeSession(
            structures=[BASE_STRUCTURE],
            replies=[submit_reply(accepted=False, reason="structure_version_conflict",
                                  token=95, after=8, candidate_version=0)],
            waits=[generated.GeneratedCandidateWait("terminal", rejected, 1)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "stale")
        self.assertEqual(outcome.terminal_state, "REJECTED")
        self.assertEqual(outcome.current_version, 8)
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_STALE)

    def test_async_rejection_through_the_ticket(self):
        state = generated.GeneratedCandidateState(
            "REJECTED", "none", "unknown_property", "/root/x", 0, 0, 0, IDENTITY)
        session = FakeSession(
            structures=[BASE_STRUCTURE],
            replies=[submit_reply()],
            waits=[generated.GeneratedCandidateWait("terminal", state, 2)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "rejected")
        self.assertEqual(outcome.terminal_state, "REJECTED")
        self.assertEqual(outcome.reason, "unknown_property")

    def test_timeout_is_not_replayed(self):
        session = FakeSession(
            structures=[BASE_STRUCTURE],
            replies=[submit_reply()],
            waits=[generated.GeneratedCandidateWait("timeout", None, 3)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "timeout")
        self.assertEqual(session.calls, ["submit", "candidate"])
        self.assertEqual(len(session.submit_versions), 1)

    def test_endpoint_replacement_is_distinct(self):
        session = FakeSession(
            structures=[BASE_STRUCTURE],
            replies=[submit_reply()],
            waits=[generated.GeneratedCandidateWait("endpoint_replaced", None, 1)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "endpoint_replaced")
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_ENDPOINT)

    def test_lost_endpoint_at_submit_is_endpoint_unavailable(self):
        session = FakeSession(structures=[BASE_STRUCTURE],
                              replies=[ConnectionError("socket gone")])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "endpoint_unavailable")
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_ENDPOINT)

    def test_lost_endpoint_during_readback_is_not_accepted(self):
        session = FakeSession(
            structures=[ConnectionError("socket gone")],
            replies=[submit_reply()],
            waits=[accepted_wait(91, 8)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "endpoint_unavailable")
        self.assertFalse(outcome.succeeded())

    def test_accepted_then_replaced_is_not_reported_accepted(self):
        session = FakeSession(
            structures=[self.accepted_structure(version=9)],
            replies=[submit_reply()],
            waits=[accepted_wait(91, 8, replaced=True)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "replaced_after_accept")
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_REJECTED)

    def test_missing_ticket_is_not_success(self):
        session = FakeSession(
            structures=[BASE_STRUCTURE],
            replies=[submit_reply(token=0)],
            waits=[])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "refused")
        self.assertFalse(outcome.succeeded())

    def test_stale_plan_is_refused_before_submit(self):
        session = FakeSession(structures=[BASE_STRUCTURE])
        stale = generated_plan([{"op": "set_property", "key": "root", "name": "gap",
                                 "value": "9"}], 6)
        outcome = editor.submit_plan(session, stale, capabilities=capability_catalog())
        self.assertEqual(outcome.outcome, "stale")
        self.assertEqual(outcome.current_version, 7)
        self.assertNotIn("submit", session.calls)

    def test_remote_version_conflict_is_stale_without_retry(self):
        error = generated.GeneratedUiRemoteError(
            "structure_version_conflict", "GENERATED_UI_SUBMIT",
            versions={"REQUEST_VERSION": 7, "OBSERVED_VERSION": 8})
        session = FakeSession(structures=[BASE_STRUCTURE], replies=[error])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "stale")
        self.assertEqual(outcome.current_version, 8)
        self.assertEqual(session.calls, ["submit"])

    def test_failure_then_legal_modification_continues(self):
        rejected_state = generated.GeneratedCandidateState(
            "REJECTED", "none", "unknown_component", "", 0, 0, 0, IDENTITY)
        session = FakeSession(
            structures=[self.accepted_structure(9, padding="5")],
            replies=[submit_reply(accepted=False, reason="unknown_component",
                                  token=93, after=7, candidate_version=0),
                     submit_reply(token=94, before=8, after=9, candidate_version=9)],
            waits=[generated.GeneratedCandidateWait("terminal", rejected_state, 1),
                   accepted_wait(94, 9)])
        first = editor.submit_preview(session, self.preview())
        self.assertEqual(first.outcome, "rejected")
        retry = editor.preview_plan(self.accepted_structure(8), plan(
            {"op": "set_property", "key": "root", "name": "padding", "value": "5"},
            base_version=8))
        second = editor.submit_preview(session, retry)
        self.assertEqual(second.outcome, "accepted")
        self.assertEqual(session.submit_versions, [7, 8])
        self.assertTrue(second.exact_readback)


def dataclass_replace_nodes(preview, nodes):
    root = editor.tree_from_nodes(tuple(nodes))
    format_version = 2 if preview.expected_compositions else 1
    document = generated.GeneratedStructureDocument(
        format_version, (), tuple(nodes))
    expected = generated.GeneratedStructure(
        preview.base_version + 1, preview.accepted_candidate_version,
        preview.scene_state, tuple(nodes), format_version=format_version,
        compositions=preview.expected_compositions)
    return replace(
        preview, root=root, nodes=tuple(nodes), document=document,
        submitted_sha256=hashlib.sha256(
            generated.encode_generated_structure_document(document).encode("utf-8")
        ).hexdigest(),
        expected_structure_sha256=editor.structure_document_digest(expected))


class ContractReworkTests(unittest.TestCase):
    def preview(self):
        return editor.preview_plan(BASE_STRUCTURE, plan(
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}),
            endpoint=IDENTITY)

    def accepted_structure(self, version=8):
        nodes = [generated.GeneratedNode(0, "root", "vertical", None, None,
                                         props(gap="9", padding="4"))] + list(BASE_NODES[1:])
        return generated.GeneratedStructure(version, 0, "scene_accepted", tuple(nodes))

    def test_unknown_terminal_state_stays_unknown(self):
        state = generated.GeneratedCandidateState(
            "UNKNOWN", "none", "none", "", 0, 0, 0, IDENTITY)
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[generated.GeneratedCandidateWait("terminal", state, 1)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "unknown")
        self.assertEqual(outcome.terminal_state, "UNKNOWN")
        self.assertFalse(outcome.exact_readback)
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_UNKNOWN)
        self.assertEqual(len(session.submit_versions), 1)

    def test_readback_deadline_is_timeout_not_protocol_error(self):
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[generated.GeneratedUiDeadlineExceeded("readback deadline")])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "timeout")
        self.assertEqual(outcome.phase, "readback")
        self.assertEqual(outcome.token, 91)
        self.assertEqual(outcome.accepted_version, 8)
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_TIMEOUT)
        self.assertEqual(len(session.submit_versions), 1)

    def test_candidate_wait_endpoint_loss_keeps_the_ticket(self):
        state = generated.GeneratedCandidateState(
            "UNKNOWN", "none", "none", "", 0, 91, 0, IDENTITY)
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[generated.GeneratedCandidateWait("endpoint_unavailable", state, 1)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "endpoint_unavailable")
        self.assertEqual(outcome.phase, "candidate_wait")
        self.assertEqual(outcome.token, 91)
        self.assertEqual(outcome.terminal_state, "UNKNOWN")
        self.assertIsNotNone(outcome.ticket)
        self.assertTrue(outcome.submitted_sha256)
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_ENDPOINT)
        self.assertIsNotNone(editor.receipt_from_outcome(outcome))

    def test_accepted_readback_disconnect_keeps_observed_acceptance(self):
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[ConnectionResetError("readback lost")])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "endpoint_unavailable")
        self.assertEqual(outcome.phase, "readback")
        self.assertEqual(outcome.token, 91)
        self.assertEqual(outcome.terminal_state, "ACCEPTED")
        self.assertEqual(outcome.accepted_version, 8)
        self.assertFalse(outcome.exact_readback)
        self.assertIsNotNone(outcome.ticket)
        self.assertIsNotNone(editor.receipt_from_outcome(outcome))
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_ENDPOINT)
        self.assertEqual(len(session.submit_versions), 1)

    def test_initial_snapshot_timeout_is_timeout_for_api_and_cli(self):
        for error in (TimeoutError("snapshot deadline"),
                      generated.GeneratedUiDeadlineExceeded("snapshot deadline")):
            with self.subTest(error=type(error).__name__):
                session = FakeSession(snapshots=[error])
                outcome = editor.submit_plan(
                    session, plan({"op": "set_property", "key": "root",
                                   "name": "gap", "value": "9"}),
                    capabilities=capability_catalog())
                self.assertEqual(outcome.outcome, "timeout")
                self.assertEqual(outcome.phase, "snapshot")
                self.assertEqual(outcome.token, 0)
                self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_TIMEOUT)
                self.assertNotIn("submit", session.calls)

    def test_initial_snapshot_deadline_is_timeout_for_initialize(self):
        root = editor.EditNode("seed-root", "vertical", properties=props(gap="4"))
        session = FakeSession(
            snapshots=[generated.GeneratedUiDeadlineExceeded("initialize deadline")])
        outcome = editor.initialize_structure(session, root, capability_catalog())
        self.assertEqual(outcome.outcome, "timeout")
        self.assertEqual(outcome.phase, "snapshot")
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_TIMEOUT)

    def test_status_checks_saved_candidate_version(self):
        outcome_session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[snapshot_for(self.accepted_structure())])
        outcome = editor.submit_preview(outcome_session, self.preview())
        receipt = editor.load_receipt_document(
            json.dumps(editor.receipt_from_outcome(outcome)))
        bad = replace(receipt, ticket=replace(receipt.ticket, candidate_version=999))
        state = generated.GeneratedCandidateState(
            "ACCEPTED", "scene_accepted", "none", "", 8, 91, 0, IDENTITY)
        query = editor.query_receipt(
            FakeSession(candidate_states=[state],
                        snapshots=[snapshot_for(self.accepted_structure())]),
            bad, mode="status")
        self.assertEqual(query.outcome, "readback_mismatch")
        self.assertIn("candidate version 999", query.detail)
        self.assertEqual(editor.query_exit_code(query), editor.EXIT_PROTOCOL)

    def test_atomic_snapshot_must_belong_to_the_ticket_endpoint(self):
        other = generated.GeneratedEndpointIdentity("endpoint-b", 9)
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[snapshot_for(self.accepted_structure(), identity=other)])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "endpoint_replaced")
        self.assertFalse(outcome.succeeded())
        self.assertNotIn("structure", session.calls)
        self.assertEqual(editor.outcome_exit_code(outcome), editor.EXIT_ENDPOINT)

    def test_capability_projection_keeps_every_typed_fact(self):
        prop = generated.GeneratedPropertySpec(
            "gradient", "STRING", False, 0, 0, 256, values=("none",),
            encoding="linear,start,end,stops", unit="normalized",
            value_range="position:0..1", semantics="empty clears",
            stability="experimental", backend_support="declared")
        caps = capability_catalog(
            components=(generated.GeneratedComponentSpec("vertical", True, 8, (prop,)),),
            composites=(generated.GeneratedCompositeSpec("card", True, 4, 12, 5),),
            elements=(generated.GeneratedElementSpec(
                "card", "title", "heading", "", "jobName", "text", "preset", "APPLY_DRAFT",
                "Title"),),
            image_resources=(generated.GeneratedImageResource(
                "beacon", "image/png", 3, "Beacon"),),
            window_background=generated.GeneratedWindowBackgroundSpec(
                "background", "STRING", True, ("none", "image"), "none", "inherit",
                "stable", "declared"),
            font_resources=(generated.GeneratedFontResource(
                "body", 2, "available", "PingFang", "Body"),),
            surface=generated.GeneratedSurface(
                "1.2", "stable", "additive_only", "2", ("nodes", "fields"),
                (("future", "kept"),)),
            support=(generated.GeneratedSupportFact(
                "component", "vertical", "available", "", "registry"),),
            evidence=(generated.GeneratedDeliveryEvidence(
                "mixed", "verified", ""),))
        data = editor._capabilities_dict(caps)
        self.assertNotIn("runtime_composition", data)
        client = data["client"]
        self.assertEqual(client["source"], "cjgui_generated_edit")
        self.assertEqual(client["structure_editing"], "supported_format_1_and_2")
        self.assertEqual(client["choice_discovery"], "supported_v1")
        self.assertEqual(client["runtime_composite_input"],
                         "supported_v2_definitions_instances_end_remove")
        self.assertEqual(client["runtime_composite_losslessness"],
                         "lossless_or_named_refusal")
        self.assertEqual(client["runtime_composite_editing"],
                         "supported_stable_keys_batch_per_published_budget_nested_compose")
        self.assertEqual(client["runtime_composite_readback"],
                         "supported_complete_accepted_catalog_atomic_snapshot")
        self.assertEqual(client["runtime_composite_instances"],
                         "supported_read_only_atomic_owner_facts")
        self.assertIsNone(data["choice_format"])
        self.assertEqual(data["choice_options"], [])
        self.assertIn("CHOICE_FORMAT absent", editor._capabilities_text(caps))
        self.assertNotIn("handed off", json.dumps(client))
        out_prop = data["components"][0]["properties"][0]
        self.assertEqual(out_prop["encoding"], "linear,start,end,stops")
        self.assertEqual(out_prop["unit"], "normalized")
        self.assertEqual(out_prop["value_range"], "position:0..1")
        self.assertEqual(out_prop["semantics"], "empty clears")
        self.assertEqual(out_prop["stability"], "experimental")
        self.assertEqual(out_prop["backend_support"], "declared")
        self.assertEqual(data["elements"][0]["element_key"], "title")
        self.assertEqual(data["image_resources"][0]["version"], 3)
        self.assertEqual(data["window_background"]["root_only"], True)
        self.assertEqual(data["font_resources"][0]["resolved_family"], "PingFang")
        self.assertEqual(data["surface"]["extra"], [{"name": "future", "value": "kept"}])
        self.assertEqual(data["support"][0]["source"], "registry")
        self.assertEqual(data["evidence"][0]["state"], "verified")
        text = editor._capabilities_text(caps)
        self.assertIn('"encoding":"linear,start,end,stops"', text)
        self.assertIn("ELEMENT ", text)
        self.assertIn("WINDOW_BACKGROUND ", text)
        self.assertIn("SUPPORT ", text)
        self.assertIn("EVIDENCE ", text)
        self.assertIn("CLIENT_FORMATS ", text)
        self.assertNotIn("RUNTIME_COMPOSITION", text)

    def test_saved_plan_round_trip_and_baseline_checks(self):
        preview = self.preview()
        saved = editor.saved_plan_from_preview(
            plan({"op": "set_property", "key": "root", "name": "gap", "value": "9"}),
            preview)
        loaded_plan, loaded = editor.load_plan_document(json.dumps(saved.to_dict()))
        self.assertIsNotNone(loaded)
        self.assertEqual(loaded_plan.to_dict(), saved.plan.to_dict())
        same = editor._verify_saved_plan(
            loaded, snapshot_for(BASE_STRUCTURE), capability_catalog())
        self.assertEqual(editor.generated_nodes_of(same.root), preview.nodes)
        with self.assertRaises(editor.GeneratedEditError) as stale:
            editor._verify_saved_plan(
                loaded, snapshot_for(self.accepted_structure()), capability_catalog())
        self.assertEqual(stale.exception.code, "stale_base_version")
        changed_same_version = generated.GeneratedStructure(
            BASE_STRUCTURE.version, BASE_STRUCTURE.candidate_version,
            BASE_STRUCTURE.scene_state,
            (generated.GeneratedNode(0, "root", "vertical", None, None,
                                     props(gap="5")),) + tuple(BASE_NODES[1:]))
        with self.assertRaises(editor.GeneratedEditError) as changed:
            editor._verify_saved_plan(
                loaded, snapshot_for(changed_same_version), capability_catalog())
        self.assertEqual(changed.exception.code, "stale_base_version")
        self.assertIn("v7", changed.exception.detail)
        other = generated.GeneratedEndpointIdentity("endpoint-b", 4)
        with self.assertRaises(editor.GeneratedEditError) as replaced:
            editor._verify_saved_plan(
                loaded, snapshot_for(BASE_STRUCTURE, identity=other), capability_catalog())
        self.assertEqual(replaced.exception.code, "endpoint_replaced")
        tampered = replace(loaded, preview={**loaded.preview, "nodes": []})
        with self.assertRaises(editor.GeneratedEditError) as mismatch:
            editor._verify_saved_plan(
                tampered, snapshot_for(BASE_STRUCTURE), capability_catalog())
        self.assertEqual(mismatch.exception.code, "saved_preview_mismatch")

    def test_public_apply_saved_plan_keeps_guards_and_submits_once(self):
        preview = self.preview()
        saved = editor.saved_plan_from_preview(
            plan({"op": "set_property", "key": "root", "name": "gap", "value": "9"}),
            preview)
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[snapshot_for(BASE_STRUCTURE),
                       snapshot_for(self.accepted_structure())])
        outcome = editor.apply_saved_plan(
            session, saved, capability_catalog())
        self.assertEqual(outcome.outcome, "accepted")
        self.assertTrue(outcome.exact_readback)
        self.assertEqual(session.submit_versions, [7])
        self.assertEqual(session.calls.count("submit"), 1)
        self.assertEqual(session.calls[:2], ["snapshot", "submit"])

        stale_session = FakeSession(
            structures=[BASE_STRUCTURE],
            snapshots=[snapshot_for(self.accepted_structure(version=9))])
        stale = editor.apply_saved_plan(stale_session, saved, capability_catalog())
        self.assertEqual(stale.outcome, "stale")
        self.assertEqual(editor.outcome_exit_code(stale), editor.EXIT_STALE)
        self.assertNotIn("submit", stale_session.calls)

        other = generated.GeneratedEndpointIdentity("endpoint-b", 4)
        replaced_session = FakeSession(
            structures=[BASE_STRUCTURE],
            snapshots=[snapshot_for(BASE_STRUCTURE, identity=other)])
        replaced = editor.apply_saved_plan(replaced_session, saved, capability_catalog())
        self.assertEqual(replaced.outcome, "endpoint_replaced")
        self.assertEqual(editor.outcome_exit_code(replaced), editor.EXIT_ENDPOINT)
        self.assertNotIn("submit", replaced_session.calls)

        timeout_session = FakeSession(
            snapshots=[generated.GeneratedUiDeadlineExceeded("saved plan snapshot")])
        timeout = editor.apply_saved_plan(timeout_session, saved, capability_catalog())
        self.assertEqual(timeout.outcome, "timeout")
        self.assertEqual(timeout.phase, "snapshot")
        self.assertEqual(editor.outcome_exit_code(timeout), editor.EXIT_TIMEOUT)
        self.assertNotIn("submit", timeout_session.calls)

    def test_receipt_status_and_resume_never_submit(self):
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[snapshot_for(self.accepted_structure())])
        outcome = editor.submit_preview(session, self.preview())
        self.assertEqual(outcome.outcome, "accepted")
        receipt = editor.receipt_from_outcome(outcome)
        self.assertIsNotNone(receipt)
        loaded = editor.load_receipt_document(json.dumps(receipt))
        self.assertEqual(loaded.ticket.token, 91)
        self.assertEqual(loaded.ticket.receipt, "receipt-1")
        self.assertEqual(loaded.submitted_sha256, editor.structure_digest(outcome.preview.nodes))

        state = generated.GeneratedCandidateState(
            "ACCEPTED", "scene_accepted", "none", "", 8, 91, 0, IDENTITY)
        status_session = FakeSession(
            structures=[BASE_STRUCTURE], candidate_states=[state],
            snapshots=[snapshot_for(self.accepted_structure())])
        status = editor.query_receipt(status_session, loaded, mode="status")
        self.assertEqual(status.outcome, "accepted")
        self.assertTrue(status.exact_readback)
        self.assertNotIn("submit", status_session.calls)
        self.assertEqual(editor.query_exit_code(status), 0)

        timeout_session = FakeSession(
            structures=[BASE_STRUCTURE],
            waits=[generated.GeneratedCandidateWait("timeout", None, 1)])
        timeout = editor.query_receipt(timeout_session, loaded, mode="resume", timeout_ms=1)
        self.assertEqual(timeout.outcome, "timeout")
        self.assertNotIn("submit", timeout_session.calls)

    def test_empty_region_initialization_uses_the_same_submit_and_refuses_existing(self):
        empty = generated.GeneratedStructure(0, 0, "none", ())
        root = editor.EditNode("seed-root", "vertical", properties=props(gap="4"), children=(
            editor.EditNode("seed-title", "label", properties=props(text="Title")),))
        accepted = generated.GeneratedStructure(1, 1, "scene_accepted",
                                                editor.generated_nodes_of(root))
        session = FakeSession(
            structures=[empty], replies=[submit_reply(before=0, after=1, candidate_version=1)],
            waits=[accepted_wait(91, 1)],
            snapshots=[snapshot_for(empty), snapshot_for(accepted)])
        outcome = editor.initialize_structure(session, root, capability_catalog())
        self.assertEqual(outcome.outcome, "accepted")
        self.assertTrue(outcome.exact_readback)
        self.assertEqual(session.submit_versions, [0])
        with self.assertRaises(editor.GeneratedEditError) as existing:
            editor.initialize_preview(snapshot_for(BASE_STRUCTURE), root, capability_catalog())
        self.assertEqual(existing.exception.code, "structure_not_empty")


class DeterministicSavedPlanTests(unittest.TestCase):
    OPERATIONS = (
        {"op": "move", "key": "panel-label", "parent": "root", "index": 1},
        {"op": "move", "key": "title", "parent": "panel", "index": 0},
    )

    def preview(self):
        structure = editor.structure_from_snapshot(snapshot_for(BASE_STRUCTURE))
        return editor.preview_plan(structure, plan(*self.OPERATIONS),
                                   capability_catalog(), endpoint=IDENTITY)

    def saved(self):
        return editor.saved_plan_from_preview(plan(*self.OPERATIONS), self.preview())

    def accepting_session(self, preview):
        accepted = generated.GeneratedStructure(8, 0, "pending", preview.nodes)
        return FakeSession(
            snapshots=[snapshot_for(BASE_STRUCTURE), snapshot_for(accepted)],
            replies=[submit_reply()], waits=[accepted_wait(91, 8)])

    def test_multi_parent_diff_order_is_tree_order(self):
        preview = self.preview()
        self.assertEqual(preview.diff.reordered_parents, ("root", "panel"))
        self.assertEqual(preview.diff.moved,
                         (("panel-label", "panel", "root"), ("title", "root", "panel")))
        self.assertEqual([line.split(":")[0] for line in preview.diff.lines],
                         ["> panel-label", "> title", "< root", "< panel"])

    def test_saved_multi_parent_plan_applies_once(self):
        saved = self.saved()
        loaded_plan, loaded = editor.load_plan_document(json.dumps(saved.to_dict()))
        self.assertEqual(loaded_plan.to_dict(), saved.plan.to_dict())
        session = self.accepting_session(self.preview())
        outcome = editor.apply_saved_plan(session, loaded, capability_catalog())
        self.assertEqual(outcome.outcome, "accepted")
        self.assertTrue(outcome.exact_readback)
        self.assertEqual(session.submit_versions, [7])
        self.assertEqual(session.calls.count("submit"), 1)
        self.assertEqual(session.calls[:3], ["snapshot", "submit", "candidate"])

    def test_old_v1_diff_order_is_accepted(self):
        saved = self.saved()
        value = saved.to_dict()
        old_preview = value["preview"]
        diff = old_preview["diff"]
        diff["reordered_parents"] = list(reversed(diff["reordered_parents"]))
        moved_lines = [line for line in diff["lines"] if not line.startswith("<")]
        reorder_lines = [line for line in diff["lines"] if line.startswith("<")]
        diff["lines"] = moved_lines + list(reversed(reorder_lines))
        old_saved = replace(saved, preview=old_preview)
        preview = editor._verify_saved_plan(
            old_saved, snapshot_for(BASE_STRUCTURE), capability_catalog())
        self.assertEqual(preview.diff.reordered_parents, ("root", "panel"))
        session = self.accepting_session(preview)
        outcome = editor.apply_saved_plan(session, old_saved, capability_catalog())
        self.assertEqual(outcome.outcome, "accepted")
        self.assertEqual(session.submit_versions, [7])

    def test_tampered_diff_content_is_still_refused(self):
        saved = self.saved()
        base = saved.to_dict()["preview"]
        tampered_previews = []
        for mutate in (
            lambda diff: diff.update(reordered_parents=["root"]),
            lambda diff: diff.update(lines=diff["lines"][:-1]),
            lambda diff: diff["moved"][0].update({"from": "root"}),
            lambda diff: diff["moved"].append(
                {"key": "editor", "from": "root", "to": "panel"}),
            lambda diff: diff.update(future="ignored"),
        ):
            preview = json.loads(json.dumps(base))
            mutate(preview["diff"])
            tampered_previews.append(replace(saved, preview=preview))
        nodes_preview = json.loads(json.dumps(base))
        nodes_preview["nodes"] = []
        tampered_previews.append(replace(saved, preview=nodes_preview))
        operations_preview = json.loads(json.dumps(base))
        operations_preview["operations"] = operations_preview["operations"][:-1]
        tampered_previews.append(replace(saved, preview=operations_preview))
        for tampered in tampered_previews:
            with self.assertRaises(editor.GeneratedEditError) as caught:
                editor._verify_saved_plan(
                    tampered, snapshot_for(BASE_STRUCTURE), capability_catalog())
            self.assertEqual(caught.exception.code, "saved_preview_mismatch")


class DeclarationEditTests(unittest.TestCase):
    def catalog(self):
        base = capability_catalog()
        select = generated.GeneratedComponentSpec("select", False, 0, (
            generated.GeneratedPropertySpec("label", "STRING", False, 0, 0, 32),
            generated.GeneratedPropertySpec("placeholder", "STRING", False, 0, 0, 32),
        ))
        duplex = generated.GeneratedFieldSpec(
            "duplex", "select", 6203, "EDIT_DRAFT_BOOLEAN", False, 0, 0, 0, True,
            "value", "select", "Duplex")
        cancel = generated.GeneratedActionSpec("CANCEL_DRAFT", "cancel", ())
        return replace(base, components=base.components + (select,),
                       fields=base.fields + (duplex,),
                       actions=base.actions + (cancel,))

    def declaration_plan(self):
        return plan(
            {"op": "set_declaration", "key": "title", "kind": "select",
             "field": "duplex", "action": None},
            {"op": "remove_property", "key": "title", "name": "text"},
            {"op": "remove_property", "key": "title", "name": "fontSize"},
            {"op": "set_property", "key": "title", "name": "label", "value": "Duplex"},
            {"op": "set_declaration", "key": "apply", "action": "CANCEL_DRAFT"},
        )

    def test_type_field_and_action_changes_share_one_batch_and_keep_the_rest(self):
        catalog = self.catalog()
        preview = editor.preview_plan(BASE_STRUCTURE, self.declaration_plan(), catalog,
                                      endpoint=IDENTITY)
        title = next(node for node in editor.generated_nodes_of(preview.root)
                     if node.key == "title")
        self.assertEqual(title.kind, "select")
        self.assertEqual(title.field_id, "duplex")
        self.assertIsNone(title.action)
        self.assertEqual({prop.name: prop.value for prop in title.properties},
                         {"label": "Duplex"})
        apply_node = next(node for node in editor.generated_nodes_of(preview.root)
                          if node.key == "apply")
        self.assertEqual(apply_node.action, "CANCEL_DRAFT")
        self.assertEqual(apply_node.properties, BASE_NODES[5].properties)
        for key in ("editor", "panel", "panel-label"):
            self.assertTrue(generated.same_structure(
                tuple(node for node in BASE_NODES if node.key == key),
                tuple(node for node in editor.generated_nodes_of(preview.root)
                      if node.key == key)))
        self.assertEqual([change.key for change in preview.diff.declaration_changes],
                         ["title", "apply"])
        self.assertTrue(any("title.kind" in line for line in preview.diff.lines))
        self.assertTrue(any("title.field" in line for line in preview.diff.lines))
        self.assertTrue(any("apply.action" in line for line in preview.diff.lines))
        self.assertEqual(preview.diff.to_dict()["declaration_changes"][0]["kind"],
                         {"old": "label", "new": "select"})

        accepted = generated.GeneratedStructure(8, 0, "scene_accepted", preview.nodes)
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[snapshot_for(accepted)])
        outcome = editor.submit_preview(session, preview)
        self.assertEqual(outcome.outcome, "accepted")
        self.assertTrue(outcome.exact_readback)
        self.assertEqual(session.submit_versions, [7])
        self.assertEqual(len(session.submitted), 1)

    def test_declaration_preflight_and_json_round_trip(self):
        catalog = self.catalog()
        cases = (
            ({"op": "set_declaration", "key": "title", "kind": "missing"}, "unknown_kind"),
            ({"op": "set_declaration", "key": "title", "field": "missing"}, "unknown_field"),
            ({"op": "set_declaration", "key": "apply", "action": "NOPE"}, "unknown_action"),
        )
        for operation, code in cases:
            with self.subTest(code=code):
                with self.assertRaises(editor.GeneratedEditError) as error:
                    editor.preview_plan(BASE_STRUCTURE, plan(operation), catalog)
                self.assertEqual(error.exception.code, code)
        with self.assertRaises(editor.GeneratedEditError) as no_change:
            editor.edit_plan_from_dict({"base_version": 7, "operations": [
                {"op": "set_declaration", "key": "title"}]})
        self.assertEqual(no_change.exception.code, "invalid_plan")

        operation = {"op": "set_declaration", "key": "apply", "action": None}
        parsed = editor.edit_plan_from_dict({"base_version": 7, "operations": [operation]})
        self.assertEqual(parsed.to_dict()["operations"], [operation])
        preview = editor.preview_plan(BASE_STRUCTURE, parsed, catalog)
        apply_node = next(node for node in editor.generated_nodes_of(preview.root)
                          if node.key == "apply")
        self.assertEqual((apply_node.kind, apply_node.field_id, apply_node.action),
                         ("action", None, None))


CHOICE_FORMAT_V1 = ("CHOICE_FORMAT version=1 encoding=token "
                    "fields=fieldId,key,value,enabled,reason,label")

PRESET_CARD_DOCUMENT = r"""GENERATED_UI_STRUCTURE 2
COMPOSITION runtimePresetCard 64 8
CPARAM title STRING 0 0 40 40 \e
CELEMENT name field field=jobName argument=text
CELEMENT copies field field=copies argument=text
CELEMENT duplex field field=duplex argument=value
CELEMENT apply action action=APPLY_DRAFT label=应用
CELEMENT cancel action action=CANCEL_DRAFT label=取消
CELEMENT nameError projection field=jobName source=field_error
CTEMPLATE 0 root split axis=horizontal first=380 minfirst=220 minsecond=150 gap=8 padding=8
CTEMPLATE 1 fields vertical gap=4
CTEMPLATE 2 title label style=preset-card-title text=${title}
CTEMPLATE 2 name element element=name presentation=text
CTEMPLATE 2 copies element element=copies presentation=text
CTEMPLATE 2 duplex element element=duplex presentation=text style=preset-card-field-label gap=6
CTEMPLATE 2 nameError element element=nameError presentation=text
CTEMPLATE 1 side vertical gap=6 grow=1
CTEMPLATE 2 apply element element=apply presentation=text
CTEMPLATE 2 cancel element element=cancel presentation=text
NODE 0 board vertical
NODE 1 deck horizontal
NODE 2 cardA runtimePresetCard
PROPERTY 2 cardA title 卡片 A
NODE 2 cardB runtimePresetCard
PROPERTY 2 cardB title 卡片 B
END"""


def capability_response(*lines):
    body = "\n".join(("PAYLOAD_LENGTH 1",) + lines + ("END",))
    return generated.SharedOperationResponse(
        protocol="section", kind="GENERATED_UI_CAPABILITIES",
        entries=(("GENERATED_UI_CAPABILITIES", ("1",)),), raw=body)


def composition_snapshot(document, *, version=3, identity=IDENTITY, instances_text=""):
    return generated.GeneratedSnapshot(
        stream_epoch=1, stream_identity="stream-a", cursor=1, endpoint=identity,
        owner_field_revision=0, owner_draft_revision=0, binding_revision=0,
        accepted_structure_version=version, candidate_token=0,
        candidate_state="scene_accepted", window_accepted_scene_version=0,
        window_geometry_revision=0, window_interaction_revision=0,
        instance_revision=0, resource_revision=0, style_revision=0,
        owner_pending_scene=False, structure_candidate_pending=False,
        fields_text="", structure_text=document,
        instances_text=instances_text, styles_text="")


class ChoiceDiscoveryTests(unittest.TestCase):
    def choices(self, *rows, field="duplex", fmt=CHOICE_FORMAT_V1):
        published = [f"FIELD {field} select resource=1 input=select"]
        return generated.parse_generated_capabilities(
            capability_response(*published, fmt, *rows))

    def test_handoff_samples_are_current_options(self):
        caps = self.choices(
            "CHOICE duplex key=single value=false enabled=1 reason=none "
            "label=u8:e58d95e99da2",
            "CHOICE duplex key=double value=true enabled=1 reason=none "
            "label=u8:e58f8ce99da2")
        self.assertTrue(caps.choice_format.supported)
        self.assertEqual(caps.choice_format.version, 1)
        self.assertEqual(caps.choice_format.encoding, "token")
        self.assertEqual(caps.choice_format.fields, generated.CHOICE_FORMAT_FIELDS_V1)
        self.assertEqual([(option.field_id, option.key, option.value, option.enabled,
                           option.disabled_reason, option.label)
                          for option in caps.choice_options],
                         [("duplex", "single", "false", True, "", "单面"),
                          ("duplex", "double", "true", True, "", "双面")])
        self.assertEqual([option.key for option in caps.choice_options_for("duplex")],
                         ["single", "double"])
        self.assertEqual(caps.choice_fields(), ("duplex",))
        self.assertEqual(caps.choice_options_for("other"), ())

    def test_disabled_reason_is_a_separate_published_fact(self):
        caps = self.choices(
            "CHOICE duplex key=single value=false enabled=1 reason=none "
            "label=u8:e58d95e99da2",
            "CHOICE duplex key=double value=true enabled=0 "
            "reason=u8:e98089e9a1b9e7bbb4e68aa4e4b8ad label=u8:e58f8ce99da2")
        disabled = caps.choice_options[1]
        self.assertFalse(disabled.enabled)
        self.assertEqual(disabled.disabled_reason, "选项维护中")
        self.assertEqual(disabled.label, "双面")

    def test_rules_choice_labels_are_decoded(self):
        caps = self.choices(
            "CHOICE enabled key=enabled value=true enabled=1 reason=none "
            "label=u8:e5b7b2e590afe794a8",
            "CHOICE enabled key=disabled value=false enabled=1 reason=none "
            "label=u8:e5b7b2e5819ce794a8", field="enabled")
        self.assertEqual([(option.key, option.label) for option in caps.choice_options],
                         [("enabled", "已启用"), ("disabled", "已停用")])

    def test_unknown_version_encoding_or_field_table_is_client_unsupported(self):
        variants = (
            "CHOICE_FORMAT version=2 encoding=token "
            "fields=fieldId,key,value,enabled,reason,label",
            "CHOICE_FORMAT version=1 encoding=utf8 "
            "fields=fieldId,key,value,enabled,reason,label",
            "CHOICE_FORMAT version=1 encoding=token fields=fieldId,key,value,enabled",
        )
        for fmt in variants:
            with self.subTest(fmt=fmt):
                caps = self.choices(
                    "CHOICE duplex key=single value=false enabled=1 reason=none label=x",
                    fmt=fmt)
                self.assertEqual(caps.choice_format.state, "unsupported_by_client")
                self.assertFalse(caps.choice_format.supported)
                self.assertEqual(caps.choice_options, ())
                self.assertEqual(caps.choice_fields(), ())
                # The client states its own gap; it never invents an endpoint
                # capability claim such as "the endpoint publishes no choices".
                projection = editor._capabilities_dict(caps)
                self.assertEqual(projection["choice_format"]["state"],
                                 "unsupported_by_client")
                self.assertEqual(projection["choice_options"], [])
                self.assertEqual(projection["client"]["choice_discovery"],
                                 "supported_v1")

    def test_choice_without_format_is_refused(self):
        with self.assertRaisesRegex(generated.GeneratedUiError, "before CHOICE_FORMAT"):
            self.choices("CHOICE duplex key=single value=false enabled=1 "
                         "reason=none label=x", fmt="")
        caps = generated.parse_generated_capabilities(
            capability_response("FIELD duplex select resource=1 input=select"))
        self.assertIsNone(caps.choice_format)
        self.assertEqual(caps.choice_options, ())
        self.assertEqual(editor._capabilities_dict(caps)["choice_format"], None)

    def test_duplicate_key_is_refused(self):
        with self.assertRaisesRegex(generated.GeneratedUiError, "repeats key"):
            self.choices(
                "CHOICE duplex key=single value=false enabled=1 reason=none label=x",
                "CHOICE duplex key=single value=true enabled=1 reason=none label=y")

    def test_malformed_rows_are_refused_not_guessed(self):
        invalid = (
            "CHOICE duplex key=single value=false enabled=2 reason=none label=x",
            "CHOICE duplex key=single value=false enabled=1 reason=none",
            "CHOICE duplex key=single value=false enabled=1 reason=none label=x extra=y",
            "CHOICE duplex key=u8:zz value=false enabled=1 reason=none label=x",
            "CHOICE duplex key=single value=u8:abc enabled=1 reason=none label=x",
            "CHOICE duplex key=single value=false enabled=1 reason=u8:ff label=x",
            "CHOICE duplex key=single value=false enabled=1 reason=none label=u8:",
        )
        for row in invalid:
            with self.subTest(row=row):
                with self.assertRaises(generated.GeneratedUiError):
                    self.choices(row)

    def test_choice_field_must_be_published(self):
        with self.assertRaisesRegex(generated.GeneratedUiError, "unpublished field"):
            generated.parse_generated_capabilities(capability_response(
                "FIELD other select resource=1 input=select", CHOICE_FORMAT_V1,
                "CHOICE duplex key=single value=false enabled=1 reason=none label=x"))

    def test_literal_reason_none_is_empty(self):
        caps = self.choices(
            "CHOICE duplex key=single value=false enabled=0 reason=none label=x")
        self.assertEqual(caps.choice_options[0].disabled_reason, "")

    def test_text_token_encoder_matches_the_producer(self):
        self.assertEqual(generated.encode_generated_text_token("single"), "single")
        self.assertEqual(generated.encode_generated_text_token("单面"),
                         "u8:e58d95e99da2")
        self.assertEqual(generated.encode_generated_text_token("a=b"),
                         "u8:613d62")
        self.assertEqual(generated.encode_generated_text_token("u8:literal"),
                         "u8:75383a6c69746572616c")
        self.assertEqual(generated.encode_generated_text_token("two words"),
                         "u8:74776f20776f726473")
        with self.assertRaises(generated.GeneratedUiError):
            generated.encode_generated_text_token("")
        with self.assertRaises(generated.GeneratedUiError):
            generated.encode_generated_text_token("abcd", max_bytes=3)

    def test_projection_exposes_current_option_facts(self):
        caps = self.choices(
            "CHOICE duplex key=single value=false enabled=1 reason=none label=x",
            "CHOICE duplex key=double value=true enabled=0 reason=u8:e4bc91 "
            "label=y")
        data = editor._capabilities_dict(caps)
        self.assertEqual(data["choice_format"]["state"], "supported")
        self.assertEqual(data["choice_format"]["fields"],
                         list(generated.CHOICE_FORMAT_FIELDS_V1))
        self.assertEqual(data["choice_options"][1],
                         {"field_id": "duplex", "key": "double", "value": "true",
                          "enabled": False, "disabled_reason": "休", "label": "y"})
        text = editor._capabilities_text(caps)
        self.assertIn('"state":"supported"', text)
        self.assertIn("CHOICE_OPTION ", text)


class CompositionInputTests(unittest.TestCase):
    def test_handoff_preset_card_document_parses_losslessly(self):
        document = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        self.assertEqual(document.format_version, 2)
        self.assertEqual(len(document.compositions), 1)
        composition = document.compositions[0]
        self.assertEqual((composition.name, composition.expanded_node_limit,
                          composition.expanded_depth_limit),
                         ("runtimePresetCard", 64, 8))
        self.assertEqual([(item.name, item.value_type, item.required, item.default)
                          for item in composition.parameters],
                         [("title", "STRING", False, "")])
        self.assertEqual([(item.key, item.role, item.field_id, item.label)
                          for item in composition.elements],
                         [("name", "field", "jobName", ""),
                          ("copies", "field", "copies", ""),
                          ("duplex", "field", "duplex", ""),
                          ("apply", "action", "", "应用"),
                          ("cancel", "action", "", "取消"),
                          ("nameError", "projection", "jobName", "")])
        root = composition.template
        self.assertEqual((root.depth, root.key, root.kind, root.axis),
                         (0, "root", "split", "horizontal"))
        self.assertEqual((root.first_size, root.min_first, root.min_second),
                         (380, 220, 150))
        self.assertEqual([(child.key, child.kind) for child in root.children],
                         [("fields", "vertical"), ("side", "vertical")])
        self.assertEqual(root.children[0].children[0].text, "${title}")
        self.assertEqual(root.children[0].children[3].style_name, "preset-card-field-label")
        self.assertEqual([(node.depth, node.key, node.kind) for node in document.nodes],
                         [(0, "board", "vertical"), (1, "deck", "horizontal"),
                          (2, "cardA", "runtimePresetCard"),
                          (2, "cardB", "runtimePresetCard")])
        self.assertEqual(document.nodes[2].property("title"), "卡片 A")

    def test_rules_document_parses(self):
        document = generated.parse_generated_structure_document(
            "\n".join((
                "GENERATED_UI_STRUCTURE 2",
                "COMPOSITION runtimeRuleCard 64 8",
                "CPARAM title STRING 0 0 40 40 规则",
                "CELEMENT name field field=label argument=text",
                "CELEMENT retention field field=retentionCount argument=text",
                "CELEMENT apply action action=APPLY_DRAFT label=应用",
                "CTEMPLATE 0 root vertical gap=4",
                "CTEMPLATE 1 title label text=${title}",
                "CTEMPLATE 1 name element element=name presentation=text",
                "CTEMPLATE 1 retention element element=retention presentation=text",
                "CTEMPLATE 1 apply element element=apply presentation=text",
                "NODE 0 board vertical",
                "NODE 1 deck horizontal",
                "NODE 2 rule1 runtimeRuleCard",
                "PROPERTY 2 rule1 title 规则一",
                "NODE 2 rule2 runtimeRuleCard",
                "PROPERTY 2 rule2 title 规则二",
                "END")))
        self.assertEqual(document.compositions[0].parameters[0].default, "规则")
        self.assertEqual([node.kind for node in document.nodes],
                         ["vertical", "horizontal", "runtimeRuleCard", "runtimeRuleCard"])

    def test_document_round_trips_semantically(self):
        document = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        encoded = generated.encode_generated_structure_document(document)
        self.assertEqual(generated.parse_generated_structure_document(encoded), document)
        self.assertIn("GENERATED_UI_STRUCTURE 2\nCOMPOSITION runtimePresetCard 64 8\n",
                      encoded)
        self.assertIn("NODE 2 cardB runtimePresetCard", encoded)

    def test_encoder_refuses_a_composition_without_elements(self):
        document = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        composition = replace(document.compositions[0], elements=())
        with self.assertRaisesRegex(generated.GeneratedUiError, "no elements"):
            generated.encode_generated_structure_document(
                replace(document, compositions=(composition,)))

    def test_select_presentation_round_trips(self):
        document = generated.parse_generated_structure_document(
            PRESET_CARD_DOCUMENT.replace("presentation=text", "presentation=select", 1))
        encoded = generated.encode_generated_structure_document(document)
        self.assertIn("presentation=select", encoded)
        self.assertIn("COMPOSITION_END runtimePresetCard", encoded)
        self.assertEqual(generated.parse_generated_structure_document(encoded).compositions,
                         document.compositions)

    def test_malformed_definitions_are_refused(self):
        base = PRESET_CARD_DOCUMENT
        cases = {
            "format 1 with definitions": base.replace("GENERATED_UI_STRUCTURE 2",
                                                      "GENERATED_UI_STRUCTURE 1", 1),
            "unsupported format": base.replace("GENERATED_UI_STRUCTURE 2",
                                               "GENERATED_UI_STRUCTURE 3", 1),
            "multiple roots": base.replace("CTEMPLATE 1 side vertical",
                                           "CTEMPLATE 0 side vertical", 1),
            "orphan": base.replace("CTEMPLATE 1 fields vertical",
                                   "CTEMPLATE 2 fields vertical", 1),
            "missing END": base.rsplit("\nEND", 1)[0],
            "row after END": base + "\nNODE 0 extra vertical",
            "unknown parameter type": base.replace("CPARAM title STRING",
                                                   "CPARAM title FLOAT", 1),
        }
        for name, text in cases.items():
            with self.subTest(name=name):
                with self.assertRaises(generated.GeneratedUiError):
                    generated.parse_generated_structure_document(text)

    def test_definition_budgets_are_bounded(self):
        header = "GENERATED_UI_STRUCTURE 2\nCOMPOSITION c 64 8\n"
        elements = "".join(f"CELEMENT e{i} field field=f\n" for i in range(24))
        template = "CTEMPLATE 0 root vertical\n"
        too_many_params = header + "".join(
            f"CPARAM p{i} STRING 0 0 4 4 x\n" for i in range(9)) + elements + template + "END"
        too_many_elements = header + "".join(
            f"CELEMENT e{i} field field=f\n" for i in range(25)) + template + "END"
        too_deep = header + "CELEMENT e field field=f\n" + \
            "CTEMPLATE 0 root vertical\nCTEMPLATE 1 a vertical\nCTEMPLATE 2 b vertical\n" \
            "CTEMPLATE 3 c vertical\nCTEMPLATE 4 d vertical\nCTEMPLATE 5 e vertical\n" \
            "CTEMPLATE 6 f vertical\nCTEMPLATE 7 g vertical\nCTEMPLATE 8 h vertical\n" \
            "CTEMPLATE 9 i vertical\nEND"
        for text in (too_many_params, too_many_elements, too_deep):
            with self.subTest(prefix=text.split("\n")[2][:20]):
                with self.assertRaises(generated.GeneratedUiError):
                    generated.parse_generated_structure_document(text)

    def test_submit_document_reuses_the_existing_cas_path(self):
        document = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        captured = {}

        class Capture:
            def submit_text(self, payload, expected_version, *, deadline_monotonic=None):
                captured["payload"] = payload
                captured["version"] = expected_version
                captured["deadline"] = deadline_monotonic
                return "submitted"

        result = generated.GeneratedUiSession.submit_document(
            Capture(), document, 7, deadline_monotonic=12.5)
        self.assertEqual(result, "submitted")
        self.assertEqual(captured["payload"],
                         generated.encode_generated_structure_document(document))
        self.assertEqual(captured["version"], 7)
        self.assertEqual(captured["deadline"], 12.5)

    def test_node_only_plan_retains_accepted_definitions(self):
        document = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        structure = editor.structure_from_snapshot(snapshot)
        self.assertEqual(structure.format_version, 2)
        self.assertEqual(structure.compositions, document.compositions)
        preview = editor.preview_plan(structure, plan(
            {"op": "set_property", "key": "cardA", "name": "title", "value": "C"},
            base_version=3))
        # The candidate OMITS the definition (format 2, no COMPOSITION line),
        # so the producer retains the accepted catalog.
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("GENERATED_UI_STRUCTURE 2", candidate)
        self.assertNotIn("COMPOSITION ", candidate)
        self.assertIn("PROPERTY 2 cardA title C", candidate)
        # The preview still carries the complete expected accepted state.
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard"])
        self.assertNotEqual(preview.submitted_sha256, preview.expected_structure_sha256)
        self.assertNotEqual(preview.base_structure_sha256,
                            preview.expected_structure_sha256)

    def test_definition_update_and_instances_are_one_candidate(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        preview = editor.preview_plan(editor.structure_from_snapshot(snapshot), plan(
            {"op": "set_composition_parameter", "composition": "runtimePresetCard",
             "name": "title", "default": "规则"},
            {"op": "set_composition_template", "composition": "runtimePresetCard",
             "key": "duplex", "presentation": "select"},
            {"op": "set_property", "key": "cardA", "name": "title", "value": "A"},
            {"op": "set_property", "key": "cardB", "name": "title", "value": "B"},
            base_version=3))
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("CPARAM title STRING 0 0 40 40 规则", candidate)
        self.assertIn("element=duplex presentation=select", candidate)
        self.assertIn("COMPOSITION_END runtimePresetCard", candidate)
        self.assertIn("PROPERTY 2 cardA title A", candidate)
        self.assertIn("PROPERTY 2 cardB title B", candidate)
        self.assertEqual([item.name for item in preview.candidate_compositions],
                         ["runtimePresetCard"])
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard"])

    def test_candidate_document_carries_several_complete_definitions(self):
        base = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        second = replace(base.compositions[0], name="runtimeStatusCard")
        document = generated.GeneratedStructureDocument(
            2, (base.compositions[0], second), base.nodes)
        text = generated.encode_generated_structure_document(document)
        self.assertIn("COMPOSITION runtimePresetCard", text)
        self.assertIn("COMPOSITION runtimeStatusCard", text)
        self.assertIn("COMPOSITION_END runtimePresetCard", text)
        self.assertIn("COMPOSITION_END runtimeStatusCard", text)
        parsed = generated.parse_generated_structure_document(text)
        self.assertEqual([item.name for item in parsed.compositions],
                         ["runtimePresetCard", "runtimeStatusCard"])
        self.assertEqual(parsed, document)
        # A second section without its END is not a boundary: refuse instead of
        # silently merging the definitions.
        broken = text.replace("COMPOSITION_END runtimeStatusCard\n", "")
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_generated_structure_document(broken)

    def test_remove_is_explicit_and_unknown_or_referenced_removal_is_refused(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        structure = editor.structure_from_snapshot(snapshot)
        with self.assertRaises(editor.GeneratedEditError) as referenced:
            editor.preview_plan(structure, plan(
                {"op": "remove_composition", "name": "runtimePresetCard"},
                base_version=3))
        self.assertEqual(referenced.exception.code, "composition_remove_still_referenced")
        with self.assertRaises(editor.GeneratedEditError) as unknown:
            editor.preview_plan(structure, plan(
                {"op": "remove_composition", "name": "absent"}, base_version=3))
        self.assertEqual(unknown.exception.code, "composition_remove_unknown")

    def test_two_definition_updates_are_one_candidate_when_capacity_is_published(self):
        second = generated.GeneratedRuntimeComposition(
            "secondCard", 64, 8,
            (generated.GeneratedCompositionParameter("title", "STRING", False, 0, 40, 40, "x"),),
            (generated.GeneratedCompositionElement("title", "field", "jobName"),),
            generated.GeneratedCompositionTemplateNode(
                0, "root", "vertical", children=(
                    generated.GeneratedCompositionTemplateNode(
                        1, "title", "element", "title", "text"),)))
        nodes = (generated.GeneratedNode(0, "board", "vertical", None, None),
                 generated.GeneratedNode(1, "one", "runtimePresetCard", None, None),
                 generated.GeneratedNode(1, "two", "secondCard", None, None))
        structure = generated.GeneratedStructure(
            3, 0, "scene_accepted", nodes, format_version=2,
            compositions=(generated.parse_generated_structure_document(
                PRESET_CARD_DOCUMENT).compositions[0], second))
        operations = plan(
            {"op": "set_composition_limits", "composition": "runtimePresetCard",
             "expanded_node_limit": 80},
            {"op": "set_composition_limits", "composition": "secondCard",
             "expanded_node_limit": 80},
            base_version=3)
        # An endpoint that never published COMPOSITION_BUDGET keeps the legacy
        # one-definition behaviour instead of optimistically splitting.
        with self.assertRaises(editor.GeneratedEditError) as raised:
            editor.preview_plan(structure, operations, capability_catalog())
        self.assertEqual(raised.exception.code, "composition_batch_unsupported")
        # With the published capacity both definitions travel in ONE candidate.
        capabilities = replace(
            capability_catalog(),
            composition_budget=generated.GeneratedCompositionBudget(8, 96, 256, 262144))
        preview = editor.preview_plan(structure, operations, capabilities)
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("COMPOSITION runtimePresetCard", candidate)
        self.assertIn("COMPOSITION secondCard", candidate)
        self.assertIn("COMPOSITION_END secondCard", candidate)
        self.assertEqual([item.name for item in preview.candidate_compositions],
                         ["runtimePresetCard", "secondCard"])
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard", "secondCard"])
        self.assertEqual(preview.document.format_version, 2)

    def test_unexpected_definition_is_not_exact_readback(self):
        document = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        base = generated.GeneratedStructure(7, 0, "pending", document.nodes)
        preview = editor.preview_plan(base, plan(
            {"op": "set_property", "key": "cardA", "name": "title", "value": "C"},
            base_version=7))
        readback_text = PRESET_CARD_DOCUMENT.replace(
            "PROPERTY 2 cardA title 卡片 A", "PROPERTY 2 cardA title C")
        session = FakeSession(
            snapshots=[composition_snapshot(readback_text, version=8)],
            replies=[submit_reply()], waits=[accepted_wait(91, 8)])
        outcome = editor.submit_preview(session, preview)
        self.assertEqual(outcome.outcome, "readback_mismatch")
        self.assertFalse(outcome.exact_readback)
        self.assertFalse(outcome.succeeded())
        self.assertIsNotNone(outcome.accepted_structure)
        self.assertEqual(len(outcome.accepted_structure.compositions), 1)

    def test_definition_readback_matches_the_expected_complete_state(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        preview = editor.preview_plan(editor.structure_from_snapshot(snapshot), plan(
            {"op": "set_property", "key": "cardA", "name": "title", "value": "C"},
            base_version=3))
        readback_text = PRESET_CARD_DOCUMENT.replace(
            "PROPERTY 2 cardA title 卡片 A", "PROPERTY 2 cardA title C")
        session = FakeSession(
            snapshots=[composition_snapshot(readback_text, version=4)],
            replies=[submit_reply(before=3, after=4, candidate_version=4)],
            waits=[accepted_wait(91, 4)])
        outcome = editor.submit_preview(session, preview)
        self.assertEqual(outcome.outcome, "accepted", outcome.detail)
        self.assertTrue(outcome.exact_readback)
        self.assertEqual([item.name for item in outcome.accepted_structure.compositions],
                         ["runtimePresetCard"])
        self.assertEqual(outcome.expected_structure_sha256,
                         preview.expected_structure_sha256)

    def test_definition_readback_mismatch_is_refused(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        preview = editor.preview_plan(editor.structure_from_snapshot(snapshot), plan(
            {"op": "set_composition_parameter", "composition": "runtimePresetCard",
             "name": "title", "default": "规则"},
            base_version=3))
        session = FakeSession(
            snapshots=[composition_snapshot(PRESET_CARD_DOCUMENT, version=4)],
            replies=[submit_reply(before=3, after=4, candidate_version=4)],
            waits=[accepted_wait(91, 4)])
        outcome = editor.submit_preview(session, preview)
        self.assertEqual(outcome.outcome, "readback_mismatch")
        self.assertFalse(outcome.exact_readback)

    def test_initialize_retains_a_definition_bearing_empty_snapshot(self):
        definitions_only = PRESET_CARD_DOCUMENT.rsplit("\nNODE 0", 1)[0] + "\nEND"
        snapshot = composition_snapshot(definitions_only, version=0)
        preview = editor.initialize_preview(
            snapshot, editor.EditNode("board", "vertical", children=(
                editor.EditNode("cardA", "runtimePresetCard"),)))
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("GENERATED_UI_STRUCTURE 2", candidate)
        self.assertNotIn("COMPOSITION ", candidate)
        self.assertIn("NODE 1 cardA runtimePresetCard", candidate)
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard"])


class ExampleCompositionSpecTests(unittest.TestCase):
    def test_public_example_builds_one_definition_and_instance_edits(self):
        import example_generated_edit as example
        case = CompositionTransactionTests()
        structure = case.structure()
        capabilities = capability_catalog(components=(
            generated.GeneratedComponentSpec("vertical", True, 8, (
                generated.GeneratedPropertySpec("gap", "INTEGER", False, 0, 32, 0),
                generated.GeneratedPropertySpec("padding", "INTEGER", False, 0, 32, 0))),
            generated.GeneratedComponentSpec("horizontal", True, 8, (
                generated.GeneratedPropertySpec("gap", "INTEGER", False, 0, 32, 0),)),
            generated.GeneratedComponentSpec("label", False, 0, (
                generated.GeneratedPropertySpec("text", "STRING", True, 0, 0, 16),)),
            generated.GeneratedComponentSpec("textInput", False, 0, (
                generated.GeneratedPropertySpec("label", "STRING", False, 0, 0, 32),)),
            generated.GeneratedComponentSpec("action", False, 0, (
                generated.GeneratedPropertySpec("label", "STRING", False, 0, 0, 32),)),
        ))
        spec = {
            "name": "thirdCard",
            "parameters": [{"name": "title", "type": "STRING", "max_length": 40}],
            "elements": [{"key": "name", "role": "field", "field": "jobName",
                          "argument": "text"}],
            "reuse_nodes": [{"key": "cardA", "properties": {"title": "三方 A"}}],
            "new_instances": [{"key": "cardC", "parent": "board",
                               "properties": {"title": "三方 C"}}],
        }
        document = example.build_composition_plan(capabilities, structure, spec)
        preview = editor.preview_plan(
            structure, editor.edit_plan_from_dict(document), capabilities,
            endpoint=IDENTITY)
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard", "secondCard", "thirdCard"])
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("COMPOSITION thirdCard", candidate)
        self.assertIn("NODE 2 cardA thirdCard", candidate)
        self.assertIn("NODE 1 cardC thirdCard", candidate)
        removal = example.build_removal_plan(structure, {
            "definitions": ["secondCard"], "nodes": ["cardB"]})
        removal_preview = editor.preview_plan(
            structure, editor.edit_plan_from_dict(removal), capabilities,
            endpoint=IDENTITY)
        self.assertEqual(removal_preview.removals, ("secondCard",))
        with self.assertRaises(AssertionError):
            example.build_composition_plan(capabilities, structure, {
                "name": "thirdCard",
                "elements": [{"key": "ghost", "role": "field",
                              "field": "not_published"}]})


class CompositionTransactionTests(unittest.TestCase):
    """END/REMOVE, full accepted state, cross-process plan, status/resume."""

    def second_composition(self):
        return generated.GeneratedRuntimeComposition(
            "secondCard", 64, 8,
            (generated.GeneratedCompositionParameter(
                "title", "STRING", False, 0, 40, 40, ""),),
            (generated.GeneratedCompositionElement("title", "field", "jobName"),
             generated.GeneratedCompositionElement(
                 "apply", "action", action="APPLY_DRAFT", label="应用")),
            generated.GeneratedCompositionTemplateNode(
                0, "root", "vertical", children=(
                    generated.GeneratedCompositionTemplateNode(
                        1, "title", "element", "title", "text"),
                    generated.GeneratedCompositionTemplateNode(
                        1, "apply", "element", "apply", "text"))))

    def structure(self, version=3):
        preset = generated.parse_generated_structure_document(
            PRESET_CARD_DOCUMENT).compositions[0]
        return generated.GeneratedStructure(
            version, 0, "scene_accepted",
            generated.parse_generated_structure_document(
                PRESET_CARD_DOCUMENT).nodes,
            format_version=2, compositions=(preset, self.second_composition()))

    def snapshot(self, structure, version=None, instances_text=""):
        document = generated.GeneratedStructureDocument(
            structure.format_version, structure.compositions, structure.nodes)
        text = generated.encode_generated_structure_document(
            document, allow_multiple=True)
        return composition_snapshot(
            text, version=structure.version if version is None else version,
            instances_text=instances_text)

    def instances(self):
        return "\n".join((
            "INSTANCE cardA element=name role=field id=803002 kind=textInput "
            "semantic=s field=jobName action=EDIT_TEXT resource=- resource_version=0 "
            "resource_state=- effectGroup=none control_role=none selected=0 expandable=0 "
            "expanded=0 enabled=1 level=0 row_key=- parent_key=- visible=1 owner=6301 "
            "bounds=0,0,0,0 label_hex=E68993",
            "INSTANCE cardB element=name role=field id=804002 kind=textInput "
            "semantic=s field=jobName action=EDIT_TEXT resource=- resource_version=0 "
            "resource_state=- effectGroup=none control_role=none selected=0 expandable=0 "
            "expanded=0 enabled=1 level=0 row_key=- parent_key=- visible=1 owner=6302 "
            "bounds=0,0,0,0 label_hex=E68993"))

    def preview(self, operations):
        structure = self.structure()
        snapshot = self.snapshot(structure, instances_text=self.instances())
        preview = editor.preview_plan(
            editor.structure_from_snapshot(snapshot),
            editor.edit_plan_from_dict({"base_version": 3,
                                        "operations": list(operations)}),
            endpoint=IDENTITY)
        return structure, preview

    def expected_snapshot(self, preview, version=4):
        document = generated.GeneratedStructureDocument(
            2, preview.expected_compositions, preview.nodes)
        text = generated.encode_generated_structure_document(
            document, allow_multiple=True)
        return composition_snapshot(text, version=version,
                                    instances_text=self.instances())

    def test_end_and_removal_grammar_is_strict(self):
        two = self.snapshot(self.structure())
        parsed = editor._parse_structure_text(two.structure_text)
        self.assertEqual([item.name for item in parsed.compositions],
                         ["runtimePresetCard", "secondCard"])
        self.assertTrue(parsed.lossless)
        # A candidate may remove an accepted definition explicitly.
        document = generated.parse_generated_structure_document(
            "GENERATED_UI_STRUCTURE 2\n"
            "COMPOSITION_REMOVE secondCard\n"
            "NODE 0 board vertical\nEND")
        self.assertEqual(document.removals, ("secondCard",))
        self.assertTrue(document.lossless)
        encoded = generated.encode_generated_structure_document(document)
        self.assertIn("COMPOSITION_REMOVE secondCard", encoded)
        cases = {
            "end name mismatch": PRESET_CARD_DOCUMENT.replace(
                "\nNODE 0", "\nCOMPOSITION_END wrongName\nNODE 0"),
            "content after end": PRESET_CARD_DOCUMENT.replace(
                "\nNODE 0", "\nCOMPOSITION_END runtimePresetCard\nCPARAM x STRING 0 0 4 4 y\nNODE 0"),
            "second declaration without end": PRESET_CARD_DOCUMENT.replace(
                "\nNODE 0", "\nCOMPOSITION other 64 8\nNODE 0"),
            "duplicate removal": (
                "GENERATED_UI_STRUCTURE 2\nCOMPOSITION_REMOVE a\n"
                "COMPOSITION_REMOVE a\nNODE 0 board vertical\nEND"),
            "update and remove same name": (
                "GENERATED_UI_STRUCTURE 2\nCOMPOSITION c 64 8\n"
                "CELEMENT e field field=f\nCTEMPLATE 0 root vertical\n"
                "CTEMPLATE 1 e element element=e\nCOMPOSITION_END c\n"
                "COMPOSITION_REMOVE c\nNODE 0 board vertical\nEND"),
        }
        for name, text in cases.items():
            with self.subTest(name=name):
                if name == "update and remove same name":
                    with self.assertRaisesRegex(generated.GeneratedUiError,
                                                "composition_update_and_remove:c"):
                        generated.parse_generated_structure_document(text)
                else:
                    with self.assertRaises(generated.GeneratedUiError):
                        generated.parse_generated_structure_document(text)
        # An accepted snapshot never carries COMPOSITION_REMOVE: treating it as
        # an accepted fact would be a second, wrong removal model.
        accepted_removal = editor._parse_structure_text(
            "STRUCTURE_VERSION 3\nCANDIDATE_VERSION 0\nSCENE_STATE accepted\n"
            "COMPOSITION_REMOVE runtimePresetCard\nNODE 0 board vertical\nEND")
        self.assertFalse(accepted_removal.lossless)

    def test_node_edit_and_definition_update_share_one_candidate(self):
        structure, preview = self.preview([
            {"op": "set_composition_parameter", "composition": "runtimePresetCard",
             "name": "title", "default": "规则"},
            {"op": "set_property", "key": "cardA", "name": "title", "value": "A"},
            {"op": "set_property", "key": "cardB", "name": "title", "value": "B"},
        ])
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("CPARAM title STRING 0 0 40 40 规则", candidate)
        self.assertIn("PROPERTY 2 cardA title A", candidate)
        self.assertNotIn("secondCard", candidate)
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard", "secondCard"])
        self.assertNotEqual(preview.submitted_sha256,
                            preview.expected_structure_sha256)
        saved = editor.saved_plan_from_preview(
            editor.edit_plan_from_dict({"base_version": 3, "operations": [
                {"op": "set_composition_parameter", "composition": "runtimePresetCard",
                 "name": "title", "default": "规则"},
                {"op": "set_property", "key": "cardA", "name": "title", "value": "A"},
                {"op": "set_property", "key": "cardB", "name": "title", "value": "B"}]}),
            preview)
        payload = json.dumps(saved.to_dict(), ensure_ascii=False)
        _plan, reloaded = editor.load_plan_document(payload)
        self.assertIsNotNone(reloaded)
        self.assertEqual(reloaded.expected_structure_sha256,
                         preview.expected_structure_sha256)
        self.assertEqual(reloaded.submitted_sha256, preview.submitted_sha256)
        self.assertEqual([item["name"] for item in reloaded.preview["compositions"]],
                         ["runtimePresetCard", "secondCard"])
        session = FakeSession(
            snapshots=[self.snapshot(structure),
                       self.expected_snapshot(preview)],
            replies=[submit_reply(before=3, after=4, candidate_version=4)],
            waits=[accepted_wait(91, 4)])
        outcome = editor.apply_saved_plan(session, reloaded)
        self.assertEqual(outcome.outcome, "accepted", outcome.detail)
        self.assertTrue(outcome.exact_readback)
        self.assertEqual(outcome.instance_owners, {"cardA": 6301, "cardB": 6302})
        self.assertTrue(outcome.instances_sha256)
        self.assertEqual(outcome.expected_structure_sha256,
                         preview.expected_structure_sha256)

    def test_removal_retains_unrelated_definition_and_reads_back(self):
        structure, preview = self.preview([
            {"op": "remove_composition", "name": "secondCard"}])
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("COMPOSITION_REMOVE secondCard", candidate)
        self.assertNotIn("COMPOSITION secondCard", candidate)
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard"])
        session = FakeSession(
            snapshots=[self.snapshot(structure), self.expected_snapshot(preview)],
            replies=[submit_reply(before=3, after=4, candidate_version=4)],
            waits=[accepted_wait(91, 4)])
        outcome = editor.submit_plan(
            session, editor.edit_plan_from_dict({"base_version": 3, "operations": [
                {"op": "remove_composition", "name": "secondCard"}]}))
        self.assertEqual(outcome.outcome, "accepted", outcome.detail)

    def test_one_definition_update_can_accompany_an_explicit_removal(self):
        structure, preview = self.preview([
            {"op": "set_composition_limits", "composition": "runtimePresetCard",
             "expanded_node_limit": 40},
            {"op": "remove_composition", "name": "secondCard"}])
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("COMPOSITION runtimePresetCard 40 8", candidate)
        self.assertIn("COMPOSITION_REMOVE secondCard", candidate)
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard"])
        self.assertEqual(preview.removals, ("secondCard",))

    def test_duplicate_removal_and_granular_after_removal_are_refused(self):
        with self.assertRaises(editor.GeneratedEditError) as caught:
            self.preview([{"op": "remove_composition", "name": "secondCard"},
                          {"op": "remove_composition", "name": "secondCard"}])
        self.assertEqual(caught.exception.code, "composition_remove_duplicate")
        with self.assertRaises(editor.GeneratedEditError) as caught:
            self.preview([{"op": "remove_composition", "name": "secondCard"},
                          {"op": "set_composition_limits", "composition": "secondCard",
                           "expanded_node_limit": 40}])
        self.assertEqual(caught.exception.code, "composition_update_and_remove")

    def test_status_and_resume_require_the_complete_expected_state(self):
        structure, preview = self.preview([
            {"op": "set_composition_parameter", "composition": "runtimePresetCard",
             "name": "title", "default": "规则"}])
        session = FakeSession(
            snapshots=[self.snapshot(structure), self.expected_snapshot(preview)],
            replies=[submit_reply(before=3, after=4, candidate_version=4)],
            waits=[accepted_wait(91, 4)])
        outcome = editor.submit_plan(
            session, editor.edit_plan_from_dict({"base_version": 3, "operations": [
                {"op": "set_composition_parameter", "composition": "runtimePresetCard",
                 "name": "title", "default": "规则"}]}))
        self.assertEqual(outcome.outcome, "accepted", outcome.detail)
        receipt_value = editor.receipt_from_outcome(outcome)
        self.assertIsNotNone(receipt_value)
        receipt = editor.load_receipt_document(
            json.dumps(receipt_value, ensure_ascii=False))
        state = generated.GeneratedCandidateState(
            "ACCEPTED", "scene_accepted", "none", "", 4, 91, 0, IDENTITY)
        status_session = FakeSession(
            candidate_states=[state],
            snapshots=[self.expected_snapshot(preview, version=4)])
        query = editor.query_receipt(status_session, receipt, mode="status")
        self.assertEqual(query.outcome, "accepted", query.detail)
        self.assertTrue(query.exact_readback)
        self.assertEqual(query.instance_owners, {"cardA": 6301, "cardB": 6302})
        wrong_session = FakeSession(
            candidate_states=[state],
            snapshots=[self.snapshot(structure, version=4)])
        wrong = editor.query_receipt(wrong_session, receipt, mode="status")
        self.assertEqual(wrong.outcome, "readback_mismatch")
        self.assertFalse(wrong.exact_readback)

    def test_instance_readback_inherits_snapshot_and_names_bad_rows(self):
        operations = [{"op": "set_composition_parameter",
                       "composition": "runtimePresetCard", "name": "title",
                       "default": "规则"}]
        structure, preview = self.preview(operations)
        snapshot = self.expected_snapshot(preview, version=4)
        parsed = editor.instances_from_snapshot(snapshot)
        self.assertEqual(
            (parsed.structure_version, parsed.candidate_version, parsed.scene_state),
            (snapshot.accepted_structure_version, snapshot.candidate_token,
             snapshot.candidate_state))
        changed = replace(parsed, instances=(replace(
            parsed.instances[0], visible=not parsed.instances[0].visible),) +
            parsed.instances[1:])
        self.assertEqual(editor.instance_facts(parsed)["sha256"],
                         editor.instance_facts(changed)["sha256"])
        self.assertNotEqual(editor.instance_facts(parsed)["presentation_sha256"],
                            editor.instance_facts(changed)["presentation_sha256"])
        self.assertNotEqual(editor.instance_facts(parsed)["visible"],
                            editor.instance_facts(changed)["visible"])

        session = FakeSession(
            snapshots=[self.snapshot(structure), self.expected_snapshot(preview)],
            replies=[submit_reply(before=3, after=4, candidate_version=4)],
            waits=[accepted_wait(91, 4)])
        outcome = editor.submit_plan(
            session, editor.edit_plan_from_dict({"base_version": 3,
                                                 "operations": operations}))
        self.assertEqual(outcome.outcome, "accepted", outcome.detail)
        receipt = editor.load_receipt_document(json.dumps(
            editor.receipt_from_outcome(outcome), ensure_ascii=False))
        state = generated.GeneratedCandidateState(
            "ACCEPTED", "scene_accepted", "none", "", 4, 91, 0, IDENTITY)
        broken = replace(snapshot,
                         instances_text="INSTANCE cardA id=not_an_integer")
        for mode in ("status", "resume"):
            with self.subTest(mode=mode):
                query_session = FakeSession(
                    candidate_states=[state], waits=[accepted_wait(91, 4)],
                    snapshots=[broken])
                query = editor.query_receipt(query_session, receipt, mode=mode)
                self.assertEqual(query.outcome, "protocol_error", query.detail)
                self.assertFalse(query.exact_readback)
                self.assertEqual(query.terminal_state, "ACCEPTED")
                self.assertEqual(query.accepted_version, 4)
                self.assertEqual(query.current_version, 4)
                self.assertEqual(query.instance_owners, {})
                self.assertNotIn("submit", query_session.calls)

    def test_rejected_update_keeps_catalog_then_legal_re_edit(self):
        structure, _ = self.preview([
            {"op": "set_composition_parameter", "composition": "runtimePresetCard",
             "name": "title", "default": "bad"}])
        rejected = generated.GeneratedCandidateState(
            "REJECTED", "scene_accepted", "composition_rejected:bad", "/root", 0, 92, 0,
            IDENTITY)
        first = FakeSession(
            snapshots=[self.snapshot(structure)],
            replies=[submit_reply(accepted=False, token=92, after=3, candidate_version=0,
                                  reason="composition_rejected:bad")],
            waits=[generated.GeneratedCandidateWait("terminal", rejected, 1)])
        refused = editor.submit_plan(
            first, editor.edit_plan_from_dict({"base_version": 3, "operations": [
                {"op": "set_composition_parameter", "composition": "runtimePresetCard",
                 "name": "title", "default": "bad"}]}))
        self.assertEqual(refused.outcome, "rejected")
        self.assertIn("composition_rejected:bad", refused.reason)
        # Same accepted version: a legal update is built and submitted once.
        good_structure, good_preview = self.preview([
            {"op": "set_composition_parameter", "composition": "runtimePresetCard",
             "name": "title", "default": "规则"}])
        second = FakeSession(
            snapshots=[self.snapshot(good_structure),
                       self.expected_snapshot(good_preview)],
            replies=[submit_reply(before=3, after=4, candidate_version=4)],
            waits=[accepted_wait(91, 4)])
        accepted = editor.submit_plan(
            second, editor.edit_plan_from_dict({"base_version": 3, "operations": [
                {"op": "set_composition_parameter", "composition": "runtimePresetCard",
                 "name": "title", "default": "规则"}]}))
        self.assertEqual(accepted.outcome, "accepted", accepted.detail)
        self.assertEqual(len(second.submit_versions), 1)


CODEC_BASE_DOCUMENT = """GENERATED_UI_STRUCTURE 2
COMPOSITION card 64 8
CPARAM title STRING 0 0 40 40 title
CELEMENT title field field=title argument=text
CTEMPLATE 0 root vertical
CTEMPLATE 1 title element element=title presentation=text
NODE 0 root vertical
NODE 1 a card
END"""


class LosslessCodecTests(unittest.TestCase):
    def document(self, text=CODEC_BASE_DOCUMENT):
        return generated.parse_generated_structure_document(text)

    def with_parameter(self, document, **changes):
        composition = replace(document.compositions[0],
                              parameters=(replace(document.compositions[0].parameters[0],
                                                  **changes),))
        return replace(document, compositions=(composition,))

    def test_space_default_is_refused_before_encoding(self):
        document = self.document()
        for value in ("双面 打印", "two words", "tab\there", "line\nbreak"):
            with self.subTest(value=value):
                with self.assertRaisesRegex(
                        generated.GeneratedUiError,
                        "composition_token_not_single:parameter default title"):
                    generated.encode_generated_structure_document(
                        self.with_parameter(document, default=value))

    def test_space_default_line_is_refused_by_the_parser(self):
        text = CODEC_BASE_DOCUMENT.replace(
            "CPARAM title STRING 0 0 40 40 title",
            "CPARAM title STRING 0 0 40 40 双面 打印")
        with self.assertRaisesRegex(
                generated.GeneratedUiError,
                "composition_token_not_single:parameter default title"):
            generated.parse_generated_structure_document(text)

    def test_all_single_token_positions_refuse_spaces_before_encoding(self):
        document = self.document()
        composition = document.compositions[0]
        parameter = composition.parameters[0]
        element = composition.elements[0]
        template = composition.template

        def with_composition(**changes):
            return replace(document, compositions=(replace(composition, **changes),))

        cases = (
            ("composition name",
             with_composition(name="bad name"), "composition name"),
            ("parameter name",
             with_composition(parameters=(replace(parameter, name="bad name"),)),
             "parameter name bad name"),
            ("element key",
             with_composition(elements=(replace(element, key="bad key"),
                                        *composition.elements[1:])),
             "element key"),
            ("element field",
             with_composition(elements=(replace(element, field_id="bad field"),
                                        *composition.elements[1:])),
             "element field"),
            ("template key",
             with_composition(template=replace(template, key="bad key")),
             "template key"),
            ("template element",
             with_composition(template=replace(template, element_key="bad element")),
             "template element"),
            ("template style",
             with_composition(template=replace(template, style_name="bad style")),
             "template style"),
        )
        for label, changed, code in cases:
            with self.subTest(label):
                with self.assertRaisesRegex(generated.GeneratedUiError, code):
                    generated.encode_generated_structure_document(changed)

    def test_representable_defaults_still_round_trip(self):
        document = self.document()
        for value in ("", "title", "规则", "a=b", "\\e"):
            with self.subTest(value=value):
                changed = self.with_parameter(document, default=value)
                reparsed = generated.parse_generated_structure_document(
                    generated.encode_generated_structure_document(changed))
                self.assertEqual(reparsed.compositions[0].parameters[0].default, value)

    def test_spaces_in_trailing_label_and_text_round_trip(self):
        document = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        composition = document.compositions[0]
        elements = (replace(composition.elements[0], label="  双面 打印  "),
                    *composition.elements[1:])

        def relabel(node):
            if node.kind == "label":
                return replace(node, text="  打印  设置  ")
            return replace(node, children=tuple(relabel(child)
                                                for child in node.children))

        def first_label(node):
            if node.kind == "label":
                return node
            for child in node.children:
                found = first_label(child)
                if found is not None:
                    return found
            return None

        changed = replace(document, compositions=(replace(
            composition, elements=elements,
            template=relabel(composition.template)),))
        reparsed = generated.parse_generated_structure_document(
            generated.encode_generated_structure_document(changed))
        self.assertEqual(reparsed.compositions[0].elements[0].label, "  双面 打印  ")
        self.assertEqual(first_label(reparsed.compositions[0].template).text,
                         "  打印  设置  ")

    def test_unknown_element_or_template_token_is_never_dropped(self):
        replacements = (
            ("CTEMPLATE 0 root vertical",
             "CTEMPLATE 0 root vertical future=value"),
            ("CELEMENT title field field=title argument=text",
             "CELEMENT title field field=title argument=text future=value"),
        )
        for old, new in replacements:
            with self.subTest(new=new):
                document = self.document(CODEC_BASE_DOCUMENT.replace(old, new, 1))
                self.assertFalse(document.lossless)
                self.assertIn("future=value", document.source_text)
                with self.assertRaisesRegex(
                        generated.GeneratedUiError,
                        "composition_document_not_lossless"):
                    generated.encode_generated_structure_document(document)

    def test_future_header_and_parameter_fields_are_reported(self):
        cases = (
            CODEC_BASE_DOCUMENT.replace("COMPOSITION card 64 8",
                                        "COMPOSITION card 64 8 future=1", 1),
            CODEC_BASE_DOCUMENT.replace(
                "CPARAM title STRING 0 0 40 40 title",
                "CPARAM title STRING 0 0 40 40 title future=1", 1),
        )
        for text in cases:
            with self.subTest(text=text.splitlines()[1]):
                document = self.document(text)
                self.assertFalse(document.lossless)
                with self.assertRaisesRegex(generated.GeneratedUiError,
                                            "composition_document_not_lossless"):
                    generated.encode_generated_structure_document(document)

    def test_unknown_declaration_line_is_never_dropped(self):
        text = CODEC_BASE_DOCUMENT.replace(
            "NODE 0 root vertical", "FUTURE_BINDING owner=other\nNODE 0 root vertical", 1)
        document = self.document(text)
        self.assertFalse(document.lossless)
        self.assertIn("FUTURE_BINDING owner=other", document.source_text)
        with self.assertRaisesRegex(generated.GeneratedUiError,
                                    "composition_document_not_lossless"):
            generated.encode_generated_structure_document(document)

    def test_lossy_document_is_refused_by_digest_and_editing(self):
        text = CODEC_BASE_DOCUMENT.replace(
            "CTEMPLATE 0 root vertical", "CTEMPLATE 0 root vertical future=value", 1)
        structure = editor.structure_from_snapshot(composition_snapshot(text, version=3))
        self.assertFalse(structure.lossless)
        with self.assertRaises(editor.GeneratedEditError) as digest_error:
            editor.structure_document_digest(structure)
        self.assertEqual(digest_error.exception.code, "composition_document_not_lossless")
        with self.assertRaises(editor.GeneratedEditError) as preview_error:
            editor.preview_plan(structure, plan(
                {"op": "set_property", "key": "a", "name": "title", "value": "B"},
                base_version=3))
        self.assertEqual(preview_error.exception.code, "composition_document_not_lossless")

    def test_unknown_node_token_is_reported_too(self):
        text = CODEC_BASE_DOCUMENT.replace("NODE 1 a card", "NODE 1 a card future=value", 1)
        document = self.document(text)
        self.assertFalse(document.lossless)
        with self.assertRaisesRegex(generated.GeneratedUiError,
                                    "composition_document_not_lossless"):
            generated.encode_generated_structure_document(document)

    def test_lossy_readback_is_not_exact(self):
        text = CODEC_BASE_DOCUMENT.replace(
            "CTEMPLATE 0 root vertical", "CTEMPLATE 0 root vertical future=value", 1)
        structure = editor.structure_from_snapshot(composition_snapshot(text, version=3))
        self.assertFalse(editor._exact_node_readback(structure.nodes, structure))

    def test_equals_inside_a_value_token_is_representable(self):
        document = self.document()
        composition = document.compositions[0]
        element = replace(composition.elements[0], field_id="a=b")
        changed = replace(document, compositions=(replace(composition, elements=(element,)),))
        reparsed = generated.parse_generated_structure_document(
            generated.encode_generated_structure_document(changed))
        self.assertEqual(reparsed.compositions[0].elements[0].field_id, "a=b")

    def test_complete_definition_document_is_digested_not_node_only(self):
        document = self.document()
        encoded = generated.encode_generated_structure_document(document)
        first = editor.structure_from_snapshot(composition_snapshot(encoded, version=3))
        again = editor.structure_from_snapshot(composition_snapshot(encoded, version=3))
        self.assertEqual(editor.structure_document_digest(first),
                         editor.structure_document_digest(again))
        changed = editor.structure_from_snapshot(composition_snapshot(
            generated.encode_generated_structure_document(
                self.with_parameter(document, default="other")), version=3))
        self.assertEqual(editor.structure_digest(first.nodes),
                         editor.structure_digest(changed.nodes))
        self.assertNotEqual(editor.structure_document_digest(first),
                            editor.structure_document_digest(changed))

    def test_same_document_compares_definitions_not_nodes(self):
        document = generated.parse_generated_structure_document(PRESET_CARD_DOCUMENT)
        original = editor.structure_from_snapshot(composition_snapshot(PRESET_CARD_DOCUMENT))
        same = editor.structure_from_snapshot(composition_snapshot(PRESET_CARD_DOCUMENT))
        self.assertTrue(editor.same_document(original, same))
        composition = document.compositions[0]
        changed_document = replace(document, compositions=(replace(
            composition,
            parameters=(replace(composition.parameters[0], default="other"),)),))
        changed = editor.structure_from_snapshot(composition_snapshot(
            generated.encode_generated_structure_document(changed_document)))
        self.assertTrue(generated.same_structure(original.nodes, changed.nodes))
        self.assertFalse(editor.same_document(original, changed))

    def test_same_document_normalizes_producer_default_spelling(self):
        original = editor.structure_from_snapshot(composition_snapshot(CODEC_BASE_DOCUMENT))
        spelled_text = CODEC_BASE_DOCUMENT.replace(
            "CTEMPLATE 0 root vertical",
            "CTEMPLATE 0 root vertical axis=horizontal first=240 "
            "minfirst=120 minsecond=120", 1).replace(
            "CELEMENT title field field=title argument=text",
            "CELEMENT title field field=title argument=text label=", 1)
        spelled = editor.structure_from_snapshot(composition_snapshot(spelled_text))
        self.assertEqual(original.compositions[0].template.axis, "")
        self.assertEqual(spelled.compositions[0].template.axis, "horizontal")
        self.assertTrue(editor.same_document(original, spelled))
        self.assertEqual(editor.structure_document_digest(original),
                         editor.structure_document_digest(spelled))

    def test_same_document_never_matches_a_lossy_document(self):
        complete = editor.structure_from_snapshot(composition_snapshot(CODEC_BASE_DOCUMENT))
        lossy = editor.structure_from_snapshot(composition_snapshot(
            CODEC_BASE_DOCUMENT.replace(
                "CTEMPLATE 0 root vertical",
                "CTEMPLATE 0 root vertical future=value", 1)))
        self.assertFalse(editor.same_document(complete, lossy))
        self.assertFalse(editor.same_document(lossy, complete))


class CliTests(unittest.TestCase):
    def run_cli(self, argv, session):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = editor.run_cli(argv, session_factory=lambda _descriptor: session)
        return code, out.getvalue(), err.getvalue()

    def accepted_session(self):
        nodes = [generated.GeneratedNode(0, "root", "vertical", None, None,
                                         props(gap="9", padding="4"))] + list(BASE_NODES[1:])
        return FakeSession(
            structures=[BASE_STRUCTURE,
                        generated.GeneratedStructure(8, 0, "pending", tuple(nodes))],
            replies=[submit_reply()],
            waits=[accepted_wait(91, 8)])

    def write_plan(self, value):
        handle = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False,
                                             encoding="utf-8")
        json.dump(value, handle)
        handle.close()
        self.addCleanup(Path(handle.name).unlink)
        return handle.name

    def test_show_prints_the_accepted_structure(self):
        session = FakeSession(structures=[BASE_STRUCTURE])
        code, out, _ = self.run_cli(["desc", "show"], session)
        self.assertEqual(code, 0)
        self.assertIn("STRUCTURE_VERSION 7", out)
        self.assertIn("NODE 1 editor textInput field=jobName", out)

    def test_show_keeps_composition_definitions(self):
        session = FakeSession(snapshots=[composition_snapshot(PRESET_CARD_DOCUMENT)])
        code, out, _ = self.run_cli(["desc", "show"], session)
        self.assertEqual(code, 0)
        self.assertIn("STRUCTURE_FORMAT 2", out)
        self.assertIn("COMPOSITION_READBACK supported", out)
        self.assertIn("COMPOSITIONS 1", out)
        self.assertIn("COMPOSITION runtimePresetCard 64 8", out)
        self.assertIn("COMPOSITION_END runtimePresetCard", out)
        self.assertIn("CTEMPLATE 0 root split ", out)
        self.assertIn("NODE 2 cardA runtimePresetCard", out)
        code, out, _ = self.run_cli(["desc", "show", "--json"], session)
        self.assertEqual(code, 0)
        payload = json.loads(out)
        self.assertEqual(payload["format_version"], 2)
        self.assertEqual(payload["composition_readback"], "supported")
        self.assertEqual(payload["compositions"][0]["name"], "runtimePresetCard")
        self.assertEqual(payload["compositions"][0]["elements"][3]["label"], "应用")
        self.assertIn("COMPOSITION runtimePresetCard 64 8", payload["document"])

    def test_show_lossy_document_keeps_raw_and_claims_no_digest(self):
        text = CODEC_BASE_DOCUMENT.replace(
            "CTEMPLATE 0 root vertical", "CTEMPLATE 0 root vertical future=value", 1)
        session = FakeSession(snapshots=[composition_snapshot(text, version=3)])
        code, out, _ = self.run_cli(["desc", "show"], session)
        self.assertEqual(code, 0)
        self.assertIn("DOCUMENT_LOSSLESS 0", out)
        self.assertIn("COMPOSITION_READBACK lossy_unknown_content", out)
        self.assertIn("BASE_STRUCTURE_SHA256 unavailable_not_lossless", out)
        self.assertIn("future=value", out)
        code, out, _ = self.run_cli(["desc", "show", "--json"], session)
        self.assertEqual(code, 0)
        payload = json.loads(out)
        self.assertFalse(payload["lossless"])
        self.assertEqual(payload["composition_readback"], "lossy_unknown_content")
        self.assertIsNone(payload["base_structure_sha256"])
        self.assertIn("future=value", payload["document"])

    def test_preview_node_edit_keeps_accepted_definition_without_submit(self):
        path = self.write_plan({"base_version": 3, "operations": [
            {"op": "set_property", "key": "cardA", "name": "title", "value": "C"}]})
        components = capability_catalog().components + (
            generated.GeneratedComponentSpec("horizontal", True, 8, ()),)
        session = FakeSession(
            snapshots=[composition_snapshot(PRESET_CARD_DOCUMENT)],
            capabilities=capability_catalog(components=components))
        code, out, err = self.run_cli(["desc", "preview", path], session)
        self.assertEqual(code, editor.EXIT_ACCEPTED, err)
        self.assertIn("CANDIDATE_FORMAT 2", out)
        self.assertIn("CANDIDATE_DEFINITIONS -", out)
        self.assertIn("EXPECTED_DEFINITIONS runtimePresetCard", out)
        self.assertIn("EXPECTED_STRUCTURE_SHA256 ", out)
        self.assertIn("cardA.title: '卡片 A' -> 'C'", out)
        self.assertNotIn("submit", session.calls)

    def test_capabilities_json(self):
        session = FakeSession(structures=[BASE_STRUCTURE])
        code, out, _ = self.run_cli(["desc", "capabilities", "--json"], session)
        self.assertEqual(code, 0)
        payload = json.loads(out)
        self.assertEqual(payload["bounds"]["max_nodes"], 8)
        self.assertEqual(payload["fields"][0]["field_id"], "jobName")

    def test_preview_does_not_submit(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        session = FakeSession(structures=[BASE_STRUCTURE])
        code, out, _ = self.run_cli(["desc", "preview", path], session)
        self.assertEqual(code, 0)
        self.assertIn("LOCAL PREVIEW", out)
        self.assertIn("END_PREVIEW", out)
        self.assertNotIn("submit", session.calls)

    def test_apply_accepted(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        session = self.accepted_session()
        code, out, _ = self.run_cli(["desc", "apply", path], session)
        self.assertEqual(code, 0)
        self.assertIn("outcome=accepted", out)
        self.assertIn("exact_readback=1", out)
        self.assertIn("submit_to_accepted_ms=", out)

    def test_apply_stale_plan_exits_4_without_submit(self):
        path = self.write_plan({"base_version": 6, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        session = FakeSession(structures=[BASE_STRUCTURE])
        code, out, err = self.run_cli(["desc", "apply", path], session)
        self.assertEqual(code, editor.EXIT_STALE)
        self.assertNotIn("submit", session.calls)
        self.assertIn("stale_base_version", err)

    def test_apply_rejected_exits_5(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        rejected = generated.GeneratedCandidateState(
            "REJECTED", "none", "unknown_component", "", 0, 0, 0, IDENTITY)
        session = FakeSession(
            structures=[BASE_STRUCTURE],
            replies=[submit_reply(accepted=False, reason="unknown_component",
                                  token=93, after=7, candidate_version=0)],
            waits=[generated.GeneratedCandidateWait("terminal", rejected, 1)])
        code, out, _ = self.run_cli(["desc", "apply", path], session)
        self.assertEqual(code, editor.EXIT_REJECTED)
        self.assertIn("outcome=rejected", out)
        self.assertIn("terminal=REJECTED", out)

    def test_apply_timeout_exits_6(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        session = FakeSession(
            structures=[BASE_STRUCTURE],
            replies=[submit_reply()],
            waits=[generated.GeneratedCandidateWait("timeout", None, 2)])
        code, out, _ = self.run_cli(["desc", "apply", path], session)
        self.assertEqual(code, editor.EXIT_TIMEOUT)
        self.assertIn("outcome=timeout", out)

    def test_apply_unknown_exits_9(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        state = generated.GeneratedCandidateState(
            "UNKNOWN", "none", "none", "", 0, 0, 0, IDENTITY)
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[generated.GeneratedCandidateWait("terminal", state, 1)])
        code, out, _ = self.run_cli(["desc", "apply", path], session)
        self.assertEqual(code, editor.EXIT_UNKNOWN)
        self.assertIn("outcome=unknown", out)
        self.assertIn("terminal=UNKNOWN", out)

    def test_saved_plan_preview_and_apply(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        with tempfile.NamedTemporaryFile("w", suffix=".saved.json", delete=False,
                                         encoding="utf-8") as handle:
            saved_path = handle.name
        self.addCleanup(Path(saved_path).unlink)
        session = FakeSession(snapshots=[snapshot_for(BASE_STRUCTURE)])
        code, out, _ = self.run_cli(["desc", "preview", path, "--json",
                                     "--save-plan", saved_path], session)
        self.assertEqual(code, 0)
        json.loads(out)
        saved = json.loads(Path(saved_path).read_text(encoding="utf-8"))
        self.assertEqual(saved["format"], editor.SAVED_PLAN_FORMAT)
        self.assertEqual(saved["endpoint"], {"instance": "endpoint-a", "bind_generation": 3})
        self.assertEqual(len(saved["base_structure_sha256"]), 64)

        accepted = generated.GeneratedStructure(
            8, 0, "scene_accepted",
            (generated.GeneratedNode(0, "root", "vertical", None, None,
                                     props(gap="9", padding="4")),) + BASE_NODES[1:])
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[snapshot_for(BASE_STRUCTURE), snapshot_for(accepted)])
        code, out, _ = self.run_cli(["desc", "apply", saved_path], session)
        self.assertEqual(code, 0)
        self.assertIn("outcome=accepted", out)
        self.assertEqual(session.submit_versions, [7])

    def test_status_queries_receipt_without_submit(self):
        session = FakeSession(
            structures=[BASE_STRUCTURE], replies=[submit_reply()],
            waits=[accepted_wait(91, 8)],
            snapshots=[snapshot_for(generated.GeneratedStructure(
                8, 0, "scene_accepted",
                (generated.GeneratedNode(0, "root", "vertical", None, None,
                                         props(gap="9", padding="4")),) + BASE_NODES[1:]))])
        preview = editor.preview_plan(BASE_STRUCTURE, plan(
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}),
            endpoint=IDENTITY)
        outcome = editor.submit_preview(session, preview)
        receipt = editor.receipt_from_outcome(outcome)
        with tempfile.NamedTemporaryFile("w", suffix=".receipt.json", delete=False,
                                         encoding="utf-8") as handle:
            handle.write(json.dumps(receipt))
            receipt_path = handle.name
        self.addCleanup(Path(receipt_path).unlink)
        state = generated.GeneratedCandidateState(
            "ACCEPTED", "scene_accepted", "none", "", 8, 91, 0, IDENTITY)
        query_session = FakeSession(
            structures=[BASE_STRUCTURE], candidate_states=[state],
            snapshots=[snapshot_for(generated.GeneratedStructure(
                8, 0, "scene_accepted",
                (generated.GeneratedNode(0, "root", "vertical", None, None,
                                         props(gap="9", padding="4")),) + BASE_NODES[1:]))])
        code, out, _ = self.run_cli(["desc", "status", receipt_path], query_session)
        self.assertEqual(code, 0)
        self.assertIn("QUERY mode=status outcome=accepted", out)
        self.assertNotIn("submit", query_session.calls)

    def test_init_cli_uses_the_public_initialization_path(self):
        init = {"node": {"key": "seed-root", "kind": "vertical",
                         "properties": {"gap": "4"},
                         "children": [{"key": "seed-title", "kind": "label",
                                       "properties": {"text": "Title"}}]}}
        with tempfile.NamedTemporaryFile("w", suffix=".init.json", delete=False,
                                         encoding="utf-8") as handle:
            json.dump(init, handle)
            init_path = handle.name
        self.addCleanup(Path(init_path).unlink)
        empty = generated.GeneratedStructure(0, 0, "none", ())
        accepted = generated.GeneratedStructure(1, 1, "scene_accepted", (
            generated.GeneratedNode(0, "seed-root", "vertical", None, None, props(gap="4")),
            generated.GeneratedNode(1, "seed-title", "label", None, None, props(text="Title")),
        ))
        session = FakeSession(
            structures=[empty],
            replies=[submit_reply(before=0, after=1, candidate_version=1)],
            waits=[accepted_wait(91, 1)],
            snapshots=[snapshot_for(empty), snapshot_for(accepted)])
        code, out, _ = self.run_cli(["desc", "init", init_path], session)
        self.assertEqual(code, 0)
        self.assertIn("outcome=accepted", out)
        self.assertEqual(session.submit_versions, [0])

    def test_apply_initial_snapshot_timeout_exits_6(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        for error in (TimeoutError("CLI snapshot deadline"),
                      generated.GeneratedUiDeadlineExceeded("CLI snapshot deadline")):
            with self.subTest(error=type(error).__name__):
                session = FakeSession(snapshots=[error])
                code, out, err = self.run_cli(["desc", "apply", path, "--json"], session)
                self.assertEqual(code, editor.EXIT_TIMEOUT)
                self.assertIn('"outcome": "timeout"', out)
                self.assertIn('"phase": "snapshot"', out)
                self.assertNotIn("submit", session.calls)

    def test_apply_endpoint_loss_exits_7(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "root", "name": "gap", "value": "9"}]})
        session = FakeSession(structures=[BASE_STRUCTURE],
                              replies=[ConnectionError("socket gone")])
        code, out, _ = self.run_cli(["desc", "apply", path], session)
        self.assertEqual(code, editor.EXIT_ENDPOINT)
        self.assertIn("outcome=endpoint_unavailable", out)

    def test_invalid_plan_exits_3(self):
        path = self.write_plan({"base_version": 7, "operations": [
            {"op": "set_property", "key": "missing", "name": "gap", "value": "9"}]})
        session = FakeSession(structures=[BASE_STRUCTURE])
        code, _, err = self.run_cli(["desc", "apply", path], session)
        self.assertEqual(code, editor.EXIT_INVALID_PLAN)
        self.assertIn("unknown_key", err)
        self.assertNotIn("submit", session.calls)


class ExampleExecutionExitTests(unittest.TestCase):
    """The example must expose the core's exits and real saved receipts."""

    def _accepted(self):
        case = CompositionTransactionTests()
        ops = [{"op": "set_composition_parameter", "composition": "runtimePresetCard",
                "name": "title", "default": "规则"}]
        structure, preview = case.preview(ops)
        plan = editor.edit_plan_from_dict({"base_version": 3, "operations": ops})
        saved = editor.saved_plan_from_preview(plan, preview)
        session = FakeSession(
            snapshots=[case.snapshot(structure), case.expected_snapshot(preview)],
            replies=[submit_reply(before=3, after=4, candidate_version=4)],
            waits=[accepted_wait(91, 4)])
        outcome = editor.submit_plan(session, plan)
        self.assertEqual(outcome.outcome, "accepted", outcome.detail)
        return outcome, saved

    def test_apply_saves_the_core_receipt_for_unsettled_outcomes(self):
        import example_generated_edit as example
        accepted, saved = self._accepted()
        outcomes = (
            replace(accepted, outcome="timeout", phase="readback",
                    exact_readback=False),
            replace(accepted, outcome="endpoint_unavailable", phase="readback",
                    exact_readback=False),
            replace(accepted, outcome="unknown", phase="wait",
                    terminal_state="UNKNOWN", accepted_version=None,
                    current_version=None, exact_readback=False),
        )
        with tempfile.TemporaryDirectory(prefix="c8-example-") as temp:
            plan_path = Path(temp) / "plan.json"
            plan_path.write_text(json.dumps(saved.to_dict(), ensure_ascii=False))
            for outcome in outcomes:
                with self.subTest(outcome=outcome.outcome):
                    receipt_path = Path(temp) / f"{outcome.outcome}.json"
                    output = io.StringIO()
                    with patch.object(example.GeneratedUiSession, "connect",
                                      return_value=FakeSession()), \
                         patch.object(editor, "apply_saved_plan",
                                      return_value=outcome), \
                         contextlib.redirect_stdout(output):
                        code = example.run_apply("descriptor", str(plan_path),
                                                 str(receipt_path), json_output=True)
                    summary = json.loads(output.getvalue())
                    self.assertEqual(code, editor.outcome_exit_code(outcome))
                    self.assertTrue(receipt_path.exists())
                    self.assertEqual(summary["saved_receipt"], str(receipt_path))
                    self.assertTrue(summary["receipt_available"])
                    written = json.loads(receipt_path.read_text())
                    self.assertEqual(written["ticket"]["token"], 91)

    def test_apply_without_ticket_writes_nothing_and_says_so(self):
        import example_generated_edit as example
        accepted, saved = self._accepted()
        stale = editor.GeneratedEditOutcome(
            "stale", "baseline changed", 3, None, current_version=4,
            endpoint=accepted.endpoint, phase="snapshot")
        with tempfile.TemporaryDirectory(prefix="c8-example-") as temp:
            plan_path = Path(temp) / "plan.json"
            plan_path.write_text(json.dumps(saved.to_dict(), ensure_ascii=False))
            receipt_path = Path(temp) / "stale.json"
            output = io.StringIO()
            with patch.object(example.GeneratedUiSession, "connect",
                              return_value=FakeSession()), \
                 patch.object(editor, "apply_saved_plan", return_value=stale), \
                 contextlib.redirect_stdout(output):
                code = example.run_apply("descriptor", str(plan_path),
                                         str(receipt_path), json_output=True)
            summary = json.loads(output.getvalue())
            self.assertEqual(code, editor.EXIT_STALE)
            self.assertFalse(receipt_path.exists())
            self.assertIsNone(summary["saved_receipt"])
            self.assertFalse(summary["receipt_available"])
            self.assertIn("no ticket", summary["receipt_note"])

    def test_query_returns_the_core_code(self):
        import example_generated_edit as example
        accepted, _ = self._accepted()
        receipt = editor.receipt_from_outcome(accepted)
        query = editor.GeneratedEditQuery(
            "status", "protocol_error", "bad instance", "ACCEPTED",
            accepted_version=4, current_version=4)
        with tempfile.TemporaryDirectory(prefix="c8-example-") as temp:
            receipt_path = Path(temp) / "receipt.json"
            receipt_path.write_text(json.dumps(receipt, ensure_ascii=False))
            with patch.object(example.GeneratedUiSession, "connect",
                              return_value=FakeSession()), \
                 patch.object(editor, "query_receipt", return_value=query), \
                 contextlib.redirect_stdout(io.StringIO()):
                code = example.run_query("descriptor", str(receipt_path),
                                         "status", json_output=True)
            self.assertEqual(code, editor.query_exit_code(query))
            self.assertEqual(code, editor.EXIT_PROTOCOL)


if __name__ == "__main__":
    unittest.main()

    def test_nested_composition_reference_round_trips_and_previews(self):
        """§16: panel→card→field-group nests through compose= nodes; the plan
        carries all three definitions in one candidate, the preview validates
        the reference graph locally, and an unknown target is refused."""
        field_group = generated.GeneratedRuntimeComposition(
            "fieldGroup", 24, 4,
            (generated.GeneratedCompositionParameter("heading", "STRING", False, 0, 64, 64, ""),),
            (generated.GeneratedCompositionElement("title", "field", "jobName"),),
            generated.GeneratedCompositionTemplateNode(
                0, "root", "vertical", children=(
                    generated.GeneratedCompositionTemplateNode(
                        1, "heading", "label", text="${heading}"),
                    generated.GeneratedCompositionTemplateNode(
                        1, "title", "element", "title", "text"))))
        card = generated.GeneratedRuntimeComposition(
            "card", 40, 6,
            (),
            (generated.GeneratedCompositionElement("apply", "action", "APPLY_DRAFT"),),
            generated.GeneratedCompositionTemplateNode(
                0, "root", "vertical", children=(
                    generated.GeneratedCompositionTemplateNode(
                        1, "group", "composition", compose_name="fieldGroup"),
                    generated.GeneratedCompositionTemplateNode(
                        1, "apply", "element", "apply", "text"))))
        panel = generated.GeneratedRuntimeComposition(
            "panel", 64, 8,
            (),
            (generated.GeneratedCompositionElement("status", "projection", source="owner_status"),),
            generated.GeneratedCompositionTemplateNode(
                0, "root", "horizontal", children=(
                    generated.GeneratedCompositionTemplateNode(
                        1, "status", "element", "status", "text"),
                    generated.GeneratedCompositionTemplateNode(
                        1, "cardOne", "composition", compose_name="card"),
                    generated.GeneratedCompositionTemplateNode(
                        1, "cardTwo", "composition", compose_name="card"))))
        nodes = (generated.GeneratedNode(0, "form", "vertical", None, None),
                 generated.GeneratedNode(1, "left", "panel", None, None),
                 generated.GeneratedNode(1, "right", "panel", None, None))
        text = generated.encode_generated_structure_document(
            generated.GeneratedStructureDocument(2, (field_group, card, panel), (), nodes, True))
        self.assertIn("compose=fieldGroup", text)
        self.assertIn("compose=card", text)
        parsed = generated.parse_generated_structure_document(text)
        self.assertEqual([item.name for item in parsed.compositions],
                         ["fieldGroup", "card", "panel"])
        # Unknown target is refused before any submission.
        ghost_panel = generated.GeneratedRuntimeComposition(
            "panel", 64, 8,
            (panel.elements[0],),
            generated.GeneratedCompositionTemplateNode(
                0, "root", "horizontal", children=(
                    generated.GeneratedCompositionTemplateNode(
                        1, "ghost", "composition", compose_name="ghostCard"),)),
            )
        with self.assertRaises(generated.GeneratedUiError) as unknown:
            generated.encode_generated_structure_document(
                generated.GeneratedStructureDocument(2, (ghost_panel,), (), nodes, True))
        self.assertIn("ghostCard", str(unknown.exception))
