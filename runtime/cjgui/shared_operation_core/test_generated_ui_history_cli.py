from __future__ import annotations
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from dataclasses import asdict, replace
import cjgui_generated_client as generated
import cjgui_generated_edit as editor
from test_generated_ui_history import reply
import test_generated_ui_history as fixtures

class Transport:
    descriptor = {"capability": "test-only"}
    def __init__(self, response=None, error=None):
        self.response, self.error = response, error
        self.requests, self.closed = [], False
    def request(self, payload, **kwargs):
        self.requests.append(payload)
        if self.error is not None:
            raise self.error
        return self.response
    def close(self):
        self.closed = True

class GeneratedUiHistoryCliTests(unittest.TestCase):
    def invoke(self, command, transport, baseline=None, raw=None):
        with tempfile.TemporaryDirectory() as directory:
            argv = ["unused.descriptor", command, "--json"]
            if command != "ui-history":
                path = Path(directory) / "observed.json"
                path.write_text(raw if raw is not None else json.dumps(asdict(baseline)))
                argv = ["unused.descriptor", command, str(path), "--json"]
            out, err = io.StringIO(), io.StringIO()
            with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
                code = editor.run_cli(argv, session_factory=lambda _: generated.GeneratedUiSession(transport))
            return code, json.loads(out.getvalue()), err.getvalue()

    def baseline(self):
        return fixtures.GeneratedUiHistoryTests().baseline()

    def test_read_keeps_missing_support_and_mutability_facts_unknown(self):
        transport = Transport(reply("GENERATED_UI_HISTORY", ["UI_DOCUMENT_HISTORY 1"]))
        code, value, _ = self.invoke("ui-history", transport)
        self.assertEqual(code, editor.EXIT_ACCEPTED)
        self.assertIsNone(value["supported"])
        self.assertIsNone(value["enabled"])
        self.assertIsNone(value["can_undo"])
        self.assertEqual(len(transport.requests), 1)

    def test_real_candidate_receipt_exits_pending_and_never_reads_or_replays(self):
        transport = Transport(reply("GENERATED_UI_SUBMIT", ["APPLIED true", "REASON submitted",
            "VERSION_BEFORE 9", "VERSION_AFTER 9", "CANDIDATE_ACCEPTED true",
            "SCENE_ACCEPTED false", "CANDIDATE_VERSION 10", "CANDIDATE_TOKEN 55", "RECEIPT test55"]))
        baseline = self.baseline()
        code, value, _ = self.invoke("ui-undo", transport, baseline)
        self.assertEqual(code, editor.EXIT_UNKNOWN)
        self.assertEqual(value["phase"], "candidate_pending")
        self.assertFalse(value["accepted"])
        self.assertIsNone(value["presented"])
        self.assertEqual(value["submit"]["candidate_token"], 55)
        self.assertEqual(value["baseline"]["accepted_digest"], baseline.accepted_digest)
        self.assertEqual(len(transport.requests), 1)

    def test_disabled_and_incomplete_saved_cas_are_named_local_refusals(self):
        for baseline, reason in [(replace(self.baseline(), enabled=False), "ui_document_history_disabled"),
                                 (replace(self.baseline(), accepted_digest=None), "ui_document_history_baseline_incomplete")]:
            transport = Transport()
            code, value, _ = self.invoke("ui-redo", transport, baseline)
            self.assertEqual(code, editor.EXIT_REJECTED)
            self.assertEqual(value["reason"], reason)
            self.assertFalse(value["submitted"])
            self.assertEqual(transport.requests, [])

    def test_malformed_saved_json_does_not_send_or_traceback(self):
        transport = Transport()
        code, value, _ = self.invoke("ui-undo", transport, raw="{invalid")
        self.assertEqual(code, editor.EXIT_REJECTED)
        self.assertEqual(value["reason"], "ui_document_history_baseline_invalid")
        self.assertEqual(transport.requests, [])

    def test_lost_response_preserves_unknown_submission_and_acceptance(self):
        transport = Transport(error=generated.GeneratedUiEndpointError("endpoint_unavailable", "response lost"))
        code, value, _ = self.invoke("ui-undo", transport, self.baseline())
        self.assertEqual(code, editor.EXIT_ENDPOINT)
        self.assertEqual(value["phase"], "unknown")
        self.assertIsNone(value["submitted"])
        self.assertIsNone(value["accepted"])
        self.assertIsNone(value["presented"])
        self.assertEqual(len(transport.requests), 1)

if __name__ == "__main__":
    unittest.main()
