from __future__ import annotations

import unittest
from dataclasses import asdict, replace

import client
import cjgui_generated_client as generated


def reply(kind: str, lines: list[str]):
    payload = "\n".join(lines)
    return client.parse_response("\n".join([
        "PROTOCOL CJGUI_SHARED_OPERATION/2", "KIND " + kind,
        "ENDPOINT_INSTANCE history-test", "ENDPOINT_BIND_GENERATION 1",
        "PAYLOAD_LENGTH " + str(len(payload.encode("utf-8"))), payload, "END"]))


class GeneratedUiHistoryTests(unittest.TestCase):
    def test_capability_is_optional_and_does_not_promote_experimental_surface(self):
        old = reply("GENERATED_UI_CAPABILITIES", ["GENERATED_UI 1", "BOUNDS 12 64 8 256"])
        self.assertIsNone(getattr(generated.parse_generated_capabilities(old), "ui_document_history", None))
        new = reply("GENERATED_UI_CAPABILITIES", ["GENERATED_UI 1", "BOUNDS 12 64 8 256",
            "UI_DOCUMENT_HISTORY version=1 supported=1 stability=experimental scope=session"])
        fact = getattr(generated.parse_generated_capabilities(new), "ui_document_history", None)
        self.assertIsNotNone(fact)
        self.assertTrue(fact.supported)
        self.assertEqual(fact.stability, "experimental")

    def test_history_missing_facts_remain_unknown_and_extra_fields_survive(self):
        parse = getattr(generated, "parse_generated_history", None)
        self.assertTrue(callable(parse), "public history parser missing")
        state = parse(reply("GENERATED_UI_HISTORY", ["UI_DOCUMENT_HISTORY 1", "SUPPORTED 1",
            "ENABLED false", "SURFACE_ID 7", "CAN_UNDO false", "FUTURE_FACT 19"]))
        self.assertIsNone(state.accepted_version)
        self.assertIsNone(state.history_epoch)
        self.assertIsNone(state.redo_depth)
        self.assertIsNone(state.can_redo)
        self.assertFalse(state.enabled)
        self.assertIn(("FUTURE_FACT", "19"), state.extra)

    def baseline(self):
        return generated.parse_generated_history(reply("GENERATED_UI_HISTORY", [
            "UI_DOCUMENT_HISTORY 1", "SUPPORTED true", "ENABLED true", "SURFACE_ID 7",
            "ACCEPTED_VERSION 9", "ACCEPTED_DIGEST " + "a" * 64,
            "HISTORY_EPOCH 81", "CAN_UNDO true", "UNDO_DEPTH 2", "REDO_DEPTH 0"]))

    def test_history_submission_uses_exact_saved_cas_and_one_existing_candidate_receipt(self):
        calls = []
        class Transport:
            descriptor = {"capability": "test-only"}
            def request(self, payload, **kwargs):
                calls.append(payload)
                return reply("GENERATED_UI_SUBMIT", ["APPLIED true", "REASON submitted",
                    "VERSION_BEFORE 9", "VERSION_AFTER 9", "CANDIDATE_ACCEPTED true",
                    "SCENE_ACCEPTED false", "CANDIDATE_VERSION 10", "CANDIDATE_TOKEN 55",
                    "RECEIPT test55"])
        baseline = self.baseline()
        result = generated.GeneratedUiSession(Transport()).history_action("undo", baseline)
        self.assertEqual(len(calls), 1)
        self.assertTrue(calls[0].endswith("APPLY_GENERATED_UI_HISTORY UI_DOC_UNDO 9 " +
            "a" * 64 + " 7 81 history-test 1"))
        self.assertEqual(result.candidate_token, 55)
        self.assertEqual(result.version_after, 9)
        self.assertFalse(result.scene_accepted)
        self.assertEqual(baseline.history_epoch, 81)

    def test_missing_or_boolean_cas_does_not_generate_a_request(self):
        class Transport:
            descriptor = {"capability": "test-only"}
            def request(self, *args, **kwargs):
                raise AssertionError("incomplete baseline must not be sent")
        session = generated.GeneratedUiSession(Transport())
        for baseline in [replace(self.baseline(), accepted_version=None),
                         replace(self.baseline(), accepted_version=True),
                         replace(self.baseline(), accepted_digest="a\nINVOKE"),
                         replace(self.baseline(), history_epoch=None),
                         replace(self.baseline(), endpoint_identity=generated.GeneratedEndpointIdentity(1, 1)),
                         replace(self.baseline(), enabled=False),
                         replace(self.baseline(), supported=False)]:
            with self.assertRaises(generated.GeneratedUiError):
                session.history_action("undo", baseline)

    def test_unknown_saved_json_facts_are_preserved_without_becoming_authority(self):
        value = asdict(self.baseline())
        value["future_fact"] = {"status": "unknown", "count": None}
        parsed = generated.history_state_from_dict(value)
        self.assertIn(("future_fact", '{"status": "unknown", "count": null}'), parsed.extra)
        for malformed in (None, {"endpoint_identity": {"instance": 1, "bind_generation": 1}},
                          {"extra": [42]}):
            with self.assertRaises(generated.GeneratedUiHistoryRefusal) as error:
                generated.history_state_from_dict(malformed)
            self.assertEqual(error.exception.code, "ui_document_history_baseline_invalid")

    def test_cas_json_roundtrip_and_future_format_do_not_invent_support(self):
        baseline = self.baseline()
        self.assertEqual(generated.history_state_from_dict(asdict(baseline)), baseline)
        future = generated.parse_generated_history(reply("GENERATED_UI_HISTORY", [
            "UI_DOCUMENT_HISTORY 2", "SUPPORTED true", "ENABLED true"]))
        self.assertIsNone(future.supported)
        self.assertIsNone(future.enabled)
        self.assertEqual(future.format_version, 2)

    def test_duplicate_known_history_fact_is_not_last_writer_wins(self):
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_generated_history(reply("GENERATED_UI_HISTORY", [
                "UI_DOCUMENT_HISTORY 1", "ACCEPTED_VERSION 1", "ACCEPTED_VERSION 2"]))


if __name__ == "__main__":
    unittest.main()
