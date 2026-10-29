#!/usr/bin/env python3
"""Contract tests for `cjgui.ui-document` export/import.

These exercise the file wrapper and the import plan on typed structures. The
real window chain is recorded in the phase evidence; no test here claims an
application accepted the import.
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from unittest.mock import patch

MODULE_DIR = Path(__file__).resolve().parent
if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import cjgui_generated_client as generated  # noqa: E402
import cjgui_generated_edit as editor  # noqa: E402
import cjgui_ui_document as ui  # noqa: E402
from test_generated_edit import (  # noqa: E402
    IDENTITY,
    PRESET_CARD_DOCUMENT,
    capability_catalog,
    composition_snapshot,
    props,
)


def import_capabilities():
    base = capability_catalog()
    components = base.components + (
        generated.GeneratedComponentSpec("horizontal", True, 8, ()),)
    fields = (
        generated.GeneratedFieldSpec("jobName", "textInput", 81001, "EDIT_DRAFT_TEXT",
                                     False, 0, 0, 0, True, "text", "textInput", "Job"),
        generated.GeneratedFieldSpec("copies", "textInput", 81002, "EDIT_DRAFT_TEXT",
                                     False, 0, 0, 0, True, "text", "textInput", "Copies"),
        generated.GeneratedFieldSpec("duplex", "textInput", 81003, "EDIT_DRAFT_TEXT",
                                     False, 0, 0, 0, True, "value", "textInput", "Duplex"),
    )
    actions = (
        generated.GeneratedActionSpec("APPLY_DRAFT", "apply", ()),
        generated.GeneratedActionSpec("CANCEL_DRAFT", "cancel", ()),
    )
    return replace(base, components=components, fields=fields, actions=actions)


def simple_structure(version=3):
    nodes = (generated.GeneratedNode(0, "board", "vertical", None, None),
             generated.GeneratedNode(1, "title", "label", None, None,
                                     props(text="Only")))
    return generated.GeneratedStructure(version, 0, "scene_accepted", nodes)


class UIDocumentFileTests(unittest.TestCase):
    def test_export_carries_only_interface_facts_and_roundtrips(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        document = ui.ui_document_from_snapshot(snapshot)
        self.assertEqual(document.structure_sha256,
                         hashlib.sha256(document.structure_text.encode()).hexdigest())
        self.assertIn("jobName", document.requirements.fields)
        self.assertIn("APPLY_DRAFT", document.requirements.actions)
        self.assertIn("runtimePresetCard", document.requirements.runtime_compositions)
        self.assertIn("preset-card-title", document.requirements.styles)
        payload = document.to_dict()
        self.assertEqual(set(payload), ui.UI_DOCUMENT_KEYS)
        serialized = json.dumps(payload, ensure_ascii=False)
        for forbidden in ("endpoint", "ticket", "incarnation", "instance-a",
                          "nodeId", "base_version"):
            self.assertNotIn(forbidden, serialized)
        with tempfile.TemporaryDirectory(prefix="ui-doc-") as temp:
            path = Path(temp) / "preset.ui.json"
            ui.write_ui_document(path, document)
            loaded = ui.read_ui_document(path)
        self.assertEqual(loaded, document)
        self.assertEqual(loaded.structure_document().compositions,
                         document.structure_document().compositions)

    def test_atomic_write_keeps_the_previous_file_on_failure(self):
        document = ui.ui_document_from_snapshot(
            composition_snapshot(PRESET_CARD_DOCUMENT, version=3))
        with tempfile.TemporaryDirectory(prefix="ui-doc-") as temp:
            path = Path(temp) / "window.ui.json"
            ui.write_ui_document(path, document)
            before = path.read_text(encoding="utf-8")
            with patch.object(ui.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    ui.write_ui_document(path, document)
            self.assertEqual(path.read_text(encoding="utf-8"), before)
            self.assertEqual([item.name for item in Path(temp).iterdir()],
                             ["window.ui.json"])

    def test_tampered_unknown_and_lossy_documents_are_refused(self):
        document = ui.ui_document_from_snapshot(
            composition_snapshot(PRESET_CARD_DOCUMENT, version=3))
        value = document.to_dict()
        tampered = dict(value)
        tampered["structure"] = tampered["structure"].replace("卡片 A", "卡片 X")
        with self.assertRaises(editor.GeneratedEditError) as digest:
            ui.parse_ui_document(json.dumps(tampered, ensure_ascii=False))
        self.assertEqual(digest.exception.code, "ui_document_digest_mismatch")
        unknown = dict(value)
        unknown["endpoint"] = {"instance": "leaked"}
        with self.assertRaises(editor.GeneratedEditError) as extra:
            ui.parse_ui_document(json.dumps(unknown, ensure_ascii=False))
        self.assertEqual(extra.exception.code, "invalid_ui_document")
        lossy_text = value["structure"].replace(
            "NODE 1 deck horizontal", "NODE 1 deck horizontal mystery=1")
        lossy = dict(value)
        lossy["structure"] = lossy_text
        lossy["structure_sha256"] = hashlib.sha256(lossy_text.encode()).hexdigest()
        with self.assertRaises(editor.GeneratedEditError) as lossy_error:
            ui.parse_ui_document(json.dumps(lossy, ensure_ascii=False))
        self.assertEqual(lossy_error.exception.code, "ui_document_lossy")
        viewed = ui.parse_ui_document(json.dumps(lossy, ensure_ascii=False),
                                      allow_lossy=True)
        self.assertFalse(viewed.structure_document().lossless)


class UIDocumentImportTests(unittest.TestCase):
    def _edited_document(self):
        document = ui.ui_document_from_snapshot(
            composition_snapshot(PRESET_CARD_DOCUMENT, version=3))
        text = document.structure_text.replace("卡片 A", "卡片 A2")
        return ui.UIDocument(document.structure_format, text,
                             hashlib.sha256(text.encode()).hexdigest(),
                             document.requirements)

    def test_import_preview_keeps_unmentioned_definitions_and_rebinds(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        preview = ui.preview_ui_import(snapshot, self._edited_document(),
                                       import_capabilities())
        self.assertIn("卡片 A2", preview.to_text())
        self.assertEqual(preview.removals, ())
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard"])
        self.assertEqual(preview.candidate_compositions, ())
        self.assertEqual(preview.endpoint, IDENTITY)
        self.assertEqual(preview.base_version, 3)
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertNotIn("COMPOSITION_REMOVE", candidate)
        self.assertIn("PROPERTY 2 cardA title 卡片 A2", candidate)

    def test_replace_definitions_lists_the_explicit_removal(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        plain = ui.ui_document_from_structure(simple_structure())
        preview = ui.preview_ui_import(snapshot, plain, import_capabilities(),
                                       replace_definitions=True)
        self.assertEqual(preview.removals, ("runtimePresetCard",))
        self.assertEqual(preview.expected_compositions, ())
        candidate = generated.encode_generated_structure_document(preview.document)
        self.assertIn("COMPOSITION_REMOVE runtimePresetCard", candidate)
        self.assertIn("remove definition runtimePresetCard",
                      preview.to_text())
        merged = ui.preview_ui_import(snapshot, plain, import_capabilities())
        self.assertEqual(merged.removals, ())
        self.assertEqual([item.name for item in merged.expected_compositions],
                         ["runtimePresetCard"])

    def test_import_into_an_empty_region_adds_the_whole_tree(self):
        document = ui.ui_document_from_snapshot(
            composition_snapshot(PRESET_CARD_DOCUMENT, version=3))
        empty = replace(composition_snapshot("", version=0), structure_text="")
        preview = ui.preview_ui_import(empty, document, import_capabilities())
        self.assertEqual(preview.base_version, 0)
        self.assertEqual(preview.diff.added, ("board",))
        self.assertEqual(preview.diff.removed, ())
        self.assertEqual(preview.nodes, document.structure_document().nodes)
        self.assertEqual(preview.root.key, "board")
        self.assertIn("+ board (vertical) under $root", preview.to_text())
        self.assertEqual([item.name for item in preview.expected_compositions],
                         ["runtimePresetCard"])
        self.assertEqual([item.name for item in preview.candidate_compositions],
                         ["runtimePresetCard"])

    def test_missing_declaration_is_named_and_commits_nothing(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        document = ui.ui_document_from_snapshot(snapshot)
        text = document.structure_text.replace("field=jobName", "field=ghost")
        parsed = generated.parse_generated_structure_document(text)
        requirements = ui.requirements_from_structure(
            ui.structure_from_document(parsed))
        broken = ui.UIDocument(document.structure_format, text,
                               hashlib.sha256(text.encode()).hexdigest(),
                               requirements)
        with self.assertRaises(editor.GeneratedEditError) as raised:
            ui.preview_ui_import(snapshot, broken, import_capabilities())
        self.assertEqual(raised.exception.code, "ui_document_missing_declaration")
        self.assertIn("field:ghost", raised.exception.detail)

    def test_saved_import_plan_refuses_other_endpoint_or_baseline(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        document = self._edited_document()
        preview = ui.preview_ui_import(snapshot, document, import_capabilities())
        saved = ui.saved_ui_import_plan(preview, document)
        reloaded = ui.parse_saved_ui_import_plan(saved.to_text())
        self.assertEqual(reloaded.document, document)
        self.assertEqual(reloaded.base_structure_sha256,
                         preview.base_structure_sha256)
        rebuilt = ui.apply_saved_ui_import(snapshot, reloaded,
                                           import_capabilities())
        self.assertEqual(rebuilt.expected_structure_sha256,
                         preview.expected_structure_sha256)
        newer = composition_snapshot(PRESET_CARD_DOCUMENT, version=4)
        with self.assertRaises(editor.GeneratedEditError) as stale:
            ui.apply_saved_ui_import(newer, reloaded, import_capabilities())
        self.assertEqual(stale.exception.code, "stale_base_version")
        other = composition_snapshot(PRESET_CARD_DOCUMENT, version=3,
                                     identity=generated.GeneratedEndpointIdentity(
                                         "endpoint-b", 1))
        with self.assertRaises(editor.GeneratedEditError) as replaced:
            ui.apply_saved_ui_import(other, reloaded, import_capabilities())
        self.assertEqual(replaced.exception.code, "endpoint_replaced")

    def test_tampered_expected_digest_is_refused_before_preview(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        document = self._edited_document()
        saved = ui.saved_ui_import_plan(
            ui.preview_ui_import(snapshot, document, import_capabilities()),
            document)
        value = saved.to_dict()
        value["expected_structure_sha256"] = "0" * 64
        reloaded = ui.parse_saved_ui_import_plan(
            json.dumps(value, ensure_ascii=False))
        with self.assertRaises(editor.GeneratedEditError) as raised:
            ui.apply_saved_ui_import(snapshot, reloaded, import_capabilities())
        self.assertEqual(raised.exception.code, "saved_import_plan_mismatch")

    def test_string_false_policy_is_rejected_by_the_parser(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        document = self._edited_document()
        saved = ui.saved_ui_import_plan(
            ui.preview_ui_import(snapshot, document, import_capabilities()),
            document)
        value = saved.to_dict()
        value["replace_definitions"] = "false"
        text = json.dumps(value, ensure_ascii=False)
        with self.assertRaises(editor.GeneratedEditError) as raised:
            ui.parse_saved_ui_import_plan(text)
        self.assertEqual(raised.exception.code, "invalid_saved_import_plan")
        self.assertIn("JSON boolean", raised.exception.detail)

    def test_saved_plan_refuses_a_policy_that_changes_the_removals(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        plain = ui.ui_document_from_structure(simple_structure())
        preview = ui.preview_ui_import(snapshot, plain, import_capabilities(),
                                       replace_definitions=True)
        with self.assertRaises(editor.GeneratedEditError) as paired:
            ui.saved_ui_import_plan(preview, plain)
        self.assertEqual(paired.exception.code, "import_plan_replace_mismatch")
        with self.assertRaises(editor.GeneratedEditError) as other_document:
            ui.saved_ui_import_plan(preview, self._edited_document(),
                                    replace_definitions=True)
        self.assertEqual(other_document.exception.code,
                         "import_plan_document_mismatch")

    def test_saved_v2_empty_removals_is_an_exact_fact_not_a_wildcard(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        plain = ui.ui_document_from_structure(simple_structure())
        preview = ui.preview_ui_import(snapshot, plain, import_capabilities(),
                                       replace_definitions=True)
        self.assertIn("runtimePresetCard", preview.removals)
        saved = ui.saved_ui_import_plan(preview, plain, replace_definitions=True)
        value = saved.to_dict()
        self.assertEqual(value["format_version"], 2)
        value["removals"] = []
        tampered = ui.parse_saved_ui_import_plan(
            json.dumps(value, ensure_ascii=False))
        self.assertEqual(tampered.format_version, 2)
        with self.assertRaises(editor.GeneratedEditError) as raised:
            ui.apply_saved_ui_import(snapshot, tampered, import_capabilities())
        self.assertEqual(raised.exception.code, "saved_import_plan_mismatch")
        # The same explicit empty list is a positive fact when the approved
        # operation really removes nothing (merge). It must still apply.
        merged = ui.preview_ui_import(snapshot, plain, import_capabilities())
        self.assertEqual(merged.removals, ())
        approved_merge = ui.saved_ui_import_plan(merged, plain)
        rebuilt = ui.apply_saved_ui_import(
            snapshot, ui.parse_saved_ui_import_plan(approved_merge.to_text()),
            import_capabilities())
        self.assertEqual(rebuilt.removals, ())

    def test_v1_saved_plan_with_matching_expected_still_applies(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        document = self._edited_document()
        preview = ui.preview_ui_import(snapshot, document, import_capabilities())
        saved = ui.saved_ui_import_plan(preview, document)
        value = saved.to_dict()
        value["format_version"] = 1
        del value["submitted_sha256"]
        del value["removals"]
        reloaded = ui.parse_saved_ui_import_plan(
            json.dumps(value, ensure_ascii=False))
        self.assertEqual(reloaded.submitted_sha256, "")
        rebuilt = ui.apply_saved_ui_import(snapshot, reloaded,
                                           import_capabilities())
        self.assertEqual(rebuilt.expected_structure_sha256,
                         preview.expected_structure_sha256)

    def test_plan_numbers_require_real_integers_and_digests(self):
        snapshot = composition_snapshot(PRESET_CARD_DOCUMENT, version=3)
        document = self._edited_document()
        saved = ui.saved_ui_import_plan(
            ui.preview_ui_import(snapshot, document, import_capabilities()),
            document)
        cases = (("base_version", True), ("base_version", "3"),
                 ("base_version", 3.0),
                 ("base_structure_sha256", "not-a-digest"),
                 ("expected_structure_sha256", "0" * 63))
        for key, replacement in cases:
            value = saved.to_dict()
            value[key] = replacement
            with self.assertRaises(editor.GeneratedEditError) as raised:
                ui.parse_saved_ui_import_plan(
                    json.dumps(value, ensure_ascii=False))
            self.assertEqual(raised.exception.code,
                             "invalid_saved_import_plan", f"{key}={replacement!r}")
        value = saved.to_dict()
        value["endpoint"]["bind_generation"] = True
        with self.assertRaises(editor.GeneratedEditError) as endpoint:
            ui.parse_saved_ui_import_plan(json.dumps(value, ensure_ascii=False))
        self.assertEqual(endpoint.exception.code, "invalid_saved_import_plan")

    def test_requirements_must_match_the_structure_references(self):
        document = ui.ui_document_from_snapshot(
            composition_snapshot(PRESET_CARD_DOCUMENT, version=3))
        value = document.to_dict()
        value["requirements"]["components"].append("ghost")
        with self.assertRaises(editor.GeneratedEditError) as raised:
            ui.parse_ui_document(json.dumps(value, ensure_ascii=False))
        self.assertEqual(raised.exception.code, "ui_document_requirements_mismatch")
        self.assertIn("ghost", raised.exception.detail)

    def test_font_requirement_consumes_the_declared_version(self):
        node = generated.GeneratedNode(
            0, "board", "vertical", None, None,
            props(fontResource="serif", fontVersion="3"))
        structure = generated.GeneratedStructure(3, 0, "scene", (node,))
        document = ui.ui_document_from_structure(structure)
        self.assertIn(("serif", 3), document.requirements.fonts)
        reloaded = ui.parse_ui_document(document.to_text())
        self.assertEqual(reloaded.requirements.fonts, (("serif", 3),))

    def test_document_with_removals_is_not_a_complete_document(self):
        node = generated.GeneratedNode(0, "board", "vertical", None, None)
        source = generated.GeneratedStructureDocument(2, (), (node,),
                                                      removals=("runtimePresetCard",))
        text = generated.encode_generated_structure_document(source)
        structure = ui.structure_from_document(source)
        document = ui.UIDocument(2, text, hashlib.sha256(text.encode()).hexdigest(),
                                 ui.requirements_from_structure(structure))
        with self.assertRaises(editor.GeneratedEditError) as raised:
            ui.parse_ui_document(document.to_text())
        self.assertEqual(raised.exception.code, "ui_document_delta_content")

    def test_json_duplicate_keys_and_special_files_are_refused(self):
        document = ui.ui_document_from_snapshot(
            composition_snapshot(PRESET_CARD_DOCUMENT, version=3))
        text = document.to_text().replace(
            '  "format": "cjgui.ui-document",',
            '  "format": "cjgui.ui-document",\n  "format": "cjgui.ui-document",', 1)
        with self.assertRaises(editor.GeneratedEditError) as duplicate:
            ui.parse_ui_document(text)
        self.assertEqual(duplicate.exception.code, "invalid_ui_document")
        with tempfile.TemporaryDirectory(prefix="ui-doc-") as temp:
            fifo = Path(temp) / "pipe.ui.json"
            os.mkfifo(fifo)
            with self.assertRaises(editor.GeneratedEditError) as special:
                ui.read_ui_document(fifo)
            self.assertEqual(special.exception.code, "ui_document_path")
            oversized = Path(temp) / "large.ui.json"
            oversized.write_bytes(b"x" * (ui.UI_DOCUMENT_MAX_BYTES + 1))
            with self.assertRaises(editor.GeneratedEditError) as too_large:
                ui.read_ui_document(oversized)
            self.assertEqual(too_large.exception.code, "ui_document_too_large")


if __name__ == "__main__":
    unittest.main()
