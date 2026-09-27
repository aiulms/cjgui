#!/usr/bin/env python3
"""Real loopback TCP peer for the OHOS generated-UI public-client adapter."""

from __future__ import annotations

import socket
import sys
import threading
import unittest
from pathlib import Path

MODULE_DIR = Path(__file__).resolve().parent
if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import client  # noqa: E402
import cjgui_generated_client as generated  # noqa: E402


def envelope(kind: str, *lines: str) -> str:
    return "\n".join((f"PROTOCOL {client.PROTOCOL}", f"KIND {kind}", *lines, "END"))


def read_request(peer: socket.socket) -> str:
    header = bytearray()
    while not header.endswith(b"\n"):
        chunk = peer.recv(1)
        if not chunk:
            raise ConnectionError("request header closed")
        header.extend(chunk)
    size = int(header[:-1])
    payload = bytearray()
    while len(payload) < size:
        chunk = peer.recv(size - len(payload))
        if not chunk:
            raise ConnectionError("request body closed")
        payload.extend(chunk)
    return payload.decode("utf-8")


class ForwardedPeer:
    def __init__(self, answer):
        self.answer = answer
        self.requests: list[str] = []
        self.errors: list[BaseException] = []
        self.ready = threading.Event()
        self.stop = threading.Event()
        self.port = 0
        self.thread = threading.Thread(target=self.serve)
        self.thread.start()
        if not self.ready.wait(2):
            raise RuntimeError("loopback peer did not start")

    def serve(self):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
                listener.bind(("127.0.0.1", 0))
                self.port = listener.getsockname()[1]
                listener.listen(8)
                listener.settimeout(0.1)
                self.ready.set()
                while not self.stop.is_set():
                    try:
                        peer, _ = listener.accept()
                    except socket.timeout:
                        continue
                    with peer:
                        request = read_request(peer)
                        self.requests.append(request)
                        reply = self.answer(request)
                        if reply is None:
                            continue
                        if isinstance(reply, bytes):
                            wire = reply
                        else:
                            payload = reply.encode("utf-8")
                            wire = f"{len(payload)}\n".encode("ascii") + payload
                        # Multiple writes exercise the actual framed reader.
                        for index in range(0, len(wire), 7):
                            peer.sendall(wire[index:index + 7])
        except BaseException as exc:
            self.errors.append(exc)

    def close(self):
        self.stop.set()
        self.thread.join(2)
        if self.thread.is_alive():
            raise AssertionError("loopback peer did not stop")
        if self.errors:
            raise self.errors[0]


CAPABILITIES = envelope(
    "GENERATED_UI_CAPABILITIES", "PAYLOAD_LENGTH 1", "GENERATED_UI 1", "BOUNDS 12 64 8 256",
    "COMPONENT vertical 1 64", "COMPONENT textInput 0 0",
    "PROPERTY textInput label STRING 0 0 0 100",
    "FIELD name TEXT resource=9700 writer=EDIT_NAME required=1 min=0 max=0 maxlen=32 callable=1 argument=text input=textInput label=名称",
)
STRUCTURE = envelope(
    "GENERATED_UI_STRUCTURE", "STRUCTURE_VERSION 0", "CANDIDATE_VERSION 0",
    "SCENE_STATE none", "STRUCTURE_LENGTH 0",
)
SUBMIT = envelope(
    "GENERATED_UI_SUBMIT", "APPLIED true", "REASON none", "PATH none",
    "VERSION_BEFORE 0", "VERSION_AFTER 0", "CANDIDATE_ACCEPTED true",
    "SCENE_ACCEPTED false", "CANDIDATE_VERSION 1", "ENDPOINT_EPOCH 7",
    "ENDPOINT_INSTANCE app-instance", "ENDPOINT_BIND_GENERATION 7",
    "CANDIDATE_TOKEN 19", "RECEIPT generated-ui-candidate-19",
)
CANDIDATE = envelope(
    "GENERATED_UI_CANDIDATE", "ENDPOINT_EPOCH 7", "ENDPOINT_INSTANCE app-instance",
    "ENDPOINT_BIND_GENERATION 7", "CANDIDATE_TOKEN 19",
    "RECEIPT generated-ui-candidate-19", "BASE_VERSION 0", "CANDIDATE_VERSION 1",
    "TERMINAL_STATE ACCEPTED", "SCENE_STATE scene_accepted", "REASON none", "PATH none",
    "ACCEPTED_VERSION 1", "CURRENT_ACCEPTED_TOKEN 19", "PENDING_TOKEN 0",
)
CONTEXT = envelope(
    "SNAPSHOT", "VERSION 0", "FIELD 9700 name STRING 12 E68891E79A84E8AEBEE5A487",
    "ACTION EDIT_NAME PARAMETERS 1 TARGETS 1 1", "PARAMETER EDIT_NAME text STRING REQUIRED",
)
ACTION_RESULT = envelope("RESULT", "APPLIED true", "VERSION_BEFORE 0", "VERSION_AFTER 1")
SNAPSHOT = envelope(
    "GENERATED_UI_SNAPSHOT", "STREAM_EPOCH 1", "STREAM_IDENTITY stream-1", "CURSOR 0",
    "ENDPOINT_INSTANCE app-instance", "ENDPOINT_BIND_GENERATION 7",
    "ACCEPTED_STRUCTURE_VERSION 1", "WINDOW_ACCEPTED_SCENE_VERSION 4",
    "OWNER_PENDING_SCENE 0", "STRUCTURE_CANDIDATE_PENDING 0",
)
CHANGES = envelope(
    "GENERATED_UI_CHANGES", "STREAM_EPOCH 1", "STREAM_IDENTITY stream-1",
    "ENDPOINT_INSTANCE app-instance", "ENDPOINT_BIND_GENERATION 7",
    "SINCE 0", "CURRENT 0", "RESYNC_REQUIRED false",
)


class ForwardedTcpTests(unittest.TestCase):
    def test_public_generated_session_runs_discovery_submit_ticket_and_owner_read_over_tcp(self):
        def answer(request: str) -> str:
            if "GET_GENERATED_UI_CAPABILITIES" in request:
                return CAPABILITIES
            if "GET_GENERATED_UI_STRUCTURE" in request:
                return STRUCTURE
            if "SUBMIT_GENERATED_UI" in request:
                return SUBMIT
            if "GET_GENERATED_UI_CANDIDATE" in request:
                return CANDIDATE
            if "GET_GENERATED_UI_SNAPSHOT" in request:
                return SNAPSHOT
            if "GET_GENERATED_UI_CHANGES" in request:
                return CHANGES
            if "GET_CONTEXT" in request:
                return CONTEXT
            if "INVOKE" in request:
                return ACTION_RESULT
            raise AssertionError(f"unexpected request: {request}")

        peer = ForwardedPeer(answer)
        try:
            session = generated.GeneratedUiSession.connect_forwarded_tcp(
                target="127.0.0.1:5555", local_port=peer.port, device_port=7856,
                capability="token", caller="test-client", fragment_bytes=1)
            self.assertEqual(session.capabilities().field("name").resource_id, 9700)
            self.assertEqual(session.structure().version, 0)
            submitted = session.submit_text(
                "GENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\nNODE 1 edit textInput field=name\nEND", 0)
            self.assertTrue(submitted.candidate_accepted)
            self.assertEqual(session.wait_for_candidate(submitted.ticket(), timeout_ms=500).terminal_state,
                             "ACCEPTED")
            context = session.client.get_context()
            self.assertEqual(context.kind, "SNAPSHOT")
            action = session.invoke_action("EDIT_NAME", [9700],
                [client.SharedOperationArgument.string("text", "新名称")], expected_version=0)
            self.assertEqual(action.kind, "RESULT")
            snapshot = session.snapshot()
            self.assertEqual((snapshot.endpoint.instance, snapshot.cursor), ("app-instance", 0))
            self.assertEqual(session.changes(snapshot.stream_epoch, snapshot.cursor).changes, ())
            self.assertEqual(len(peer.requests), 9)
            self.assertTrue(all(request.startswith(f"PROTOCOL {client.PROTOCOL}\nAUTH token\n")
                                for request in peer.requests))
            self.assertIn("GET_GENERATED_UI_CANDIDATE 19 app-instance 7", peer.requests[3])
            self.assertTrue(any("ARG text STRING 9 E696B0E5908DE7A7B0" in request
                                for request in peer.requests))
        finally:
            peer.close()

    def test_closed_forward_is_an_endpoint_failure_not_a_candidate_rejection(self):
        peer = ForwardedPeer(lambda request: None)
        try:
            session = generated.GeneratedUiSession.connect_forwarded_tcp(
                target="127.0.0.1:5555", local_port=peer.port, device_port=7856,
                capability="token", caller="test-client")
            with self.assertRaises(generated.GeneratedUiEndpointError) as raised:
                session.candidate_state(19)
            self.assertEqual(raised.exception.code, "endpoint_unavailable")
            self.assertEqual(len(peer.requests), 1)
        finally:
            peer.close()

    def test_wrong_endpoint_identity_does_not_settle_an_old_ticket(self):
        replaced = CANDIDATE.replace("ENDPOINT_INSTANCE app-instance",
                                       "ENDPOINT_INSTANCE another-instance")
        peer = ForwardedPeer(lambda request: replaced)
        try:
            session = generated.GeneratedUiSession.connect_forwarded_tcp(
                target="127.0.0.1:5555", local_port=peer.port, device_port=7856,
                capability="token", caller="test-client")
            ticket = generated.GeneratedCandidateTicket(
                19, "generated-ui-candidate-19",
                generated.GeneratedEndpointIdentity("app-instance", 7), 0, 1)
            with self.assertRaises(generated.GeneratedUiEndpointError) as raised:
                session.wait_for_candidate(ticket, timeout_ms=500)
            self.assertEqual(raised.exception.code, "endpoint_replaced")
            self.assertIn("GET_GENERATED_UI_CANDIDATE 19 app-instance 7", peer.requests[0])
        finally:
            peer.close()

    def test_malformed_frame_boundaries_are_rejected(self):
        for wire, expected in (
            (b"20\nshort", client.ConnectionClosedError),
            (b"8388609\n", ValueError),
        ):
            with self.subTest(wire=wire):
                peer = ForwardedPeer(lambda request: wire)
                try:
                    session = generated.GeneratedUiSession.connect_forwarded_tcp(
                        target="127.0.0.1:5555", local_port=peer.port, device_port=7856,
                        capability="token", caller="test-client")
                    with self.assertRaises(expected):
                        session.client.request(f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_CONTEXT 0")
                finally:
                    peer.close()

    def test_target_and_forward_ports_are_explicit_and_validated(self):
        base = dict(target="127.0.0.1:5555", local_port=17856, device_port=7856,
                    capability="token", caller="test-client")
        for invalid in ({"target": ""}, {"target": "bad target"}, {"local_port": 0},
                        {"device_port": 65536}, {"capability": "token\nAUTH forged"}):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ValueError):
                    generated.GeneratedUiSession.connect_forwarded_tcp(**(base | invalid))


if __name__ == "__main__":
    unittest.main()
