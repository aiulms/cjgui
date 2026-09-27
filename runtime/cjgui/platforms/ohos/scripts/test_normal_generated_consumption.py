#!/usr/bin/env python3
"""Real loopback protocol tests for the normal-HAP generated consumer runner."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
CORE = HERE.parents[2] / "shared_operation_core"
for directory in (HERE, CORE):
    if str(directory) not in sys.path:
        sys.path.insert(0, str(directory))

from test_generated_client_tcp_forward import (  # noqa: E402
    CAPABILITIES, CANDIDATE, CONTEXT, ForwardedPeer, SNAPSHOT, SUBMIT, envelope,
)
import verify_normal_generated_consumption as runner  # noqa: E402


class FakeHdc:
    def __init__(self, target: str, local_port: int, remote_port: int, pid: str = "5700"):
        self.target, self.local_port, self.remote_port, self.pid = (
            target, local_port, remote_port, pid)
        self.calls: list[str] = []

    def listing(self) -> str:
        self.calls.append("fport ls")
        return (f"{self.target} tcp:{self.local_port} tcp:{self.remote_port} [Forward]\n")

    def pidof(self, bundle: str) -> str:
        self.calls.append(f"pidof {bundle}")
        return self.pid


class NormalGeneratedConsumptionTests(unittest.TestCase):
    def fixture(self, root: Path, port: int, *, app: str = "settings") -> argparse.Namespace:
        device_port = 7857 if app == "thermo" else 7856
        hap = root / "normal.hap"
        hap.write_bytes(b"normal-hap-test")
        identity = root / "identity.txt"
        identity.write_text(
            f"target=127.0.0.1:5555\npid=5700\nhap_sha256={hashlib.sha256(hap.read_bytes()).hexdigest()}\n"
            "build_variant=normal\n", encoding="utf-8")
        receipt = root / "receipt.json"
        receipt.write_text(json.dumps({
            "target": "127.0.0.1:5555", "local_port": port, "device_port": device_port,
            "command": ["hdc", "-t", "127.0.0.1:5555", "fport",
                        f"tcp:{port}", f"tcp:{device_port}"],
            "returncode": 0, "stdout": "Forwardport result:OK", "stderr": "",
        }), encoding="utf-8")
        candidate = root / "candidate.txt"
        candidate.write_text(
            "GENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\n"
            "NODE 1 edit textInput field=name\nPROPERTY 1 edit label 名称\nEND\n",
            encoding="utf-8")
        return argparse.Namespace(
            app=app, target="127.0.0.1:5555", local_port=port, device_port=device_port,
            capability="private-token", caller="model-consumer", hap=hap,
            identity=identity, forward_receipt_json=receipt, run_dir=root / "evidence",
            candidate_file=candidate, model_reply_file=None, wait_ms=1000, poll_ms=10,
        )

    def test_discover_submit_ticket_and_owner_readback_preserve_raw_timing_evidence(self):
        state = {"submitted": False}

        def answer(request: str) -> str:
            if "GET_GENERATED_UI_CAPABILITIES" in request:
                return CAPABILITIES
            if "GET_GENERATED_UI_STRUCTURE" in request:
                if not state["submitted"]:
                    return envelope("GENERATED_UI_STRUCTURE", "STRUCTURE_VERSION 0",
                                    "CANDIDATE_VERSION 0", "SCENE_STATE none", "STRUCTURE_LENGTH 0")
                return envelope("GENERATED_UI_STRUCTURE", "STRUCTURE_VERSION 1",
                                "CANDIDATE_VERSION 1", "SCENE_STATE scene_accepted",
                                "STRUCTURE_LENGTH 2", "NODE 0 root vertical",
                                "NODE 1 edit textInput field=name", "PROPERTY 1 edit label 名称")
            if "GET_GENERATED_UI_FIELDS" in request:
                return envelope("GENERATED_UI_FIELDS", "INSTANCE_LENGTH 0")
            if "GET_GENERATED_UI_INSTANCES" in request:
                return envelope("GENERATED_UI_INSTANCES", "INSTANCE_LENGTH 0")
            if "GET_GENERATED_UI_SNAPSHOT" in request:
                return SNAPSHOT
            if "GET_CONTEXT" in request:
                return CONTEXT
            if "SUBMIT_GENERATED_UI" in request:
                state["submitted"] = True
                return SUBMIT
            if "GET_GENERATED_UI_CANDIDATE" in request:
                return CANDIDATE
            raise AssertionError(f"unexpected request: {request}")

        peer = ForwardedPeer(answer)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                args = self.fixture(Path(tmp), peer.port)
                summary = runner.run_workflow(args, FakeHdc(args.target, peer.port, 7856))
                self.assertEqual(summary["status"], "accepted")
                self.assertEqual(summary["ticket"]["terminal_state"], "ACCEPTED")
                self.assertEqual(summary["owner_before"]["value"], summary["owner_after"]["value"])
                self.assertTrue(summary["candidate_matches_accepted_structure"])
                self.assertEqual(set(summary["timings_ms"]), {
                    "initial_binding", "discovery", "before_submit_binding",
                    "submit", "ticket_wait", "readback", "final_binding",
                })
                self.assertTrue(all(value >= 0 for value in summary["timings_ms"].values()))
                self.assertGreaterEqual(len(peer.requests), 9)
                events = [json.loads(line) for line in (args.run_dir / "exchanges.jsonl").read_text().splitlines()]
                self.assertTrue(any(event.get("command", "").startswith("SUBMIT_GENERATED_UI")
                                    for event in events))
                self.assertTrue(all(event["duration_ms"] >= 0 for event in events))
                self.assertTrue(any("KIND GENERATED_UI_CANDIDATE" in event.get("raw_response", "")
                                    for event in events))
                self.assertNotIn("private-token", (args.run_dir / "result.json").read_text())
                model_discovery = json.loads((args.run_dir / "model_discovery.json").read_text())
                self.assertNotIn("owner", model_discovery)
                self.assertNotIn("pid", model_discovery)
                self.assertEqual(model_discovery["capabilities"]["fields"][0]["field_id"], "name")
                self.assertEqual((args.run_dir / "candidate.raw.txt").read_bytes(),
                                 args.candidate_file.read_bytes())
        finally:
            peer.close()

    def test_mismatched_forward_receipt_refuses_before_socket_request(self):
        peer = ForwardedPeer(lambda request: CAPABILITIES)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                args = self.fixture(Path(tmp), peer.port)
                receipt = json.loads(args.forward_receipt_json.read_text())
                receipt["device_port"] = 7857
                args.forward_receipt_json.write_text(json.dumps(receipt))
                with self.assertRaisesRegex(ValueError, "forward receipt"):
                    runner.run_workflow(args, FakeHdc(args.target, peer.port, 7856))
                self.assertEqual(peer.requests, [])
        finally:
            peer.close()

    def test_malformed_external_candidate_is_sent_and_public_rejection_preserves_owner(self):
        requests: list[str] = []
        reject = envelope(
            "GENERATED_UI_SUBMIT", "APPLIED false", "REASON invalid_structure",
            "PATH node[0]", "VERSION_BEFORE 0", "VERSION_AFTER 0",
            "CANDIDATE_ACCEPTED false", "SCENE_ACCEPTED false", "CANDIDATE_VERSION 0",
            "ENDPOINT_INSTANCE app-instance", "ENDPOINT_BIND_GENERATION 7",
            "CANDIDATE_TOKEN 20", "RECEIPT generated-ui-candidate-20",
        )
        rejected_ticket = envelope(
            "GENERATED_UI_CANDIDATE", "ENDPOINT_INSTANCE app-instance",
            "ENDPOINT_BIND_GENERATION 7", "CANDIDATE_TOKEN 20",
            "TERMINAL_STATE REJECTED", "SCENE_STATE scene_rejected",
            "REASON invalid_structure", "PATH node[0]", "ACCEPTED_VERSION 0",
            "CURRENT_ACCEPTED_TOKEN 0", "PENDING_TOKEN 0",
        )

        def answer(request: str) -> str:
            requests.append(request)
            if "GET_GENERATED_UI_CAPABILITIES" in request:
                return CAPABILITIES
            if "GET_GENERATED_UI_STRUCTURE" in request:
                return envelope("GENERATED_UI_STRUCTURE", "STRUCTURE_VERSION 0",
                                "CANDIDATE_VERSION 0", "SCENE_STATE none", "STRUCTURE_LENGTH 0")
            if "GET_GENERATED_UI_FIELDS" in request:
                return envelope("GENERATED_UI_FIELDS", "INSTANCE_LENGTH 0")
            if "GET_GENERATED_UI_INSTANCES" in request:
                return envelope("GENERATED_UI_INSTANCES", "INSTANCE_LENGTH 0")
            if "GET_CONTEXT" in request:
                return CONTEXT
            if "SUBMIT_GENERATED_UI" in request:
                return reject
            if "GET_GENERATED_UI_CANDIDATE" in request:
                return rejected_ticket
            if "GET_GENERATED_UI_SNAPSHOT" in request:
                return SNAPSHOT
            raise AssertionError(request)

        peer = ForwardedPeer(answer)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                args = self.fixture(Path(tmp), peer.port)
                args.candidate_file.write_text(
                    "GENERATED_UI_STRUCTURE 1\nNODE broken\nEND\n", encoding="utf-8")
                model_reply = Path(tmp) / "model_reply.txt"
                model_reply.write_text("raw model proposal: NODE broken\n", encoding="utf-8")
                args.model_reply_file = model_reply
                summary = runner.run_workflow(args, FakeHdc(args.target, peer.port, 7856))
                self.assertEqual(summary["status"], "not_accepted")
                self.assertEqual(summary["ticket"]["terminal_state"], "REJECTED")
                self.assertEqual(summary["owner_before"], summary["owner_after"])
                self.assertTrue(any("SUBMIT_GENERATED_UI" in request for request in requests))
                self.assertEqual((args.run_dir / "model_reply.raw.txt").read_bytes(),
                                 model_reply.read_bytes())
        finally:
            peer.close()

    def test_thermo_discovery_uses_the_same_public_client_without_submitting(self):
        context = envelope("SNAPSHOT", "VERSION 4", "FIELD 9801 note STRING 0 -")
        capabilities = CAPABILITIES.replace("FIELD name TEXT resource=9700",
                                            "FIELD note TEXT resource=9801")

        def answer(request: str) -> str:
            if "GET_GENERATED_UI_CAPABILITIES" in request:
                return capabilities
            if "GET_GENERATED_UI_STRUCTURE" in request:
                return envelope("GENERATED_UI_STRUCTURE", "STRUCTURE_VERSION 0",
                                "CANDIDATE_VERSION 0", "SCENE_STATE none", "STRUCTURE_LENGTH 0")
            if "GET_GENERATED_UI_FIELDS" in request:
                return envelope("GENERATED_UI_FIELDS", "INSTANCE_LENGTH 0")
            if "GET_GENERATED_UI_INSTANCES" in request:
                return envelope("GENERATED_UI_INSTANCES", "INSTANCE_LENGTH 0")
            if "GET_CONTEXT" in request:
                return context
            raise AssertionError(f"unexpected submit or request: {request}")

        peer = ForwardedPeer(answer)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                args = self.fixture(Path(tmp), peer.port, app="thermo")
                args.candidate_file = None
                summary = runner.run_workflow(args, FakeHdc(args.target, peer.port, 7857))
                self.assertEqual(summary["status"], "discovered")
                self.assertEqual(set(summary["timings_ms"]), {
                    "initial_binding", "discovery", "final_binding",
                })
                discovery = json.loads((args.run_dir / "discovery.json").read_text())
                self.assertEqual(discovery["owner"]["field_id"], "note")
                self.assertEqual(discovery["owner"]["value"], "")
                self.assertEqual(discovery["owner"]["version"], 4)
                model_discovery = json.loads((args.run_dir / "model_discovery.json").read_text())
                self.assertNotIn("owner", model_discovery)
                self.assertEqual(model_discovery["capabilities"]["fields"][0]["field_id"], "note")
                self.assertEqual(len(peer.requests), 5)
        finally:
            peer.close()


if __name__ == "__main__":
    unittest.main()
