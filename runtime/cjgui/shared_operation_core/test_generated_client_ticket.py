#!/usr/bin/env python3
"""Ticket classification tests over a REAL AF_UNIX server.

The holder owns the attempt; these tests pin how the PUBLIC typed client reads
that ownership back and how it distinguishes the outcomes a model-driven bridge
must not conflate:

* PENDING until the endpoint settles the ticket, then ACCEPTED;
* SUPERSEDED for an attempt that was replaced before the scene accepted it;
* REJECTED keeps the attempt's own reason/path;
* UNKNOWN for a token outside the holder's bounded table;
* `accepted_then_replaced` for a ticket that WAS accepted and whose structure a
  later candidate replaced — the terminal state stays ACCEPTED;
* a response from ANOTHER endpoint epoch is `endpoint_replaced`, and a closed
  endpoint is `endpoint_unavailable`; neither is a business rejection.

The peer is a real socket peer (no mocking of exchange/read_frame/socket), and it
records the exact bytes it read for each request.
"""

from __future__ import annotations

import os
import socket
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

MODULE_DIR = Path(__file__).resolve().parent
if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import client  # noqa: E402
import cjgui_generated_client as generated  # noqa: E402


def read_framed(connection: socket.socket) -> str:
    received = bytearray()
    while b"\n" not in received:
        chunk = connection.recv(4096)
        if not chunk:
            raise ConnectionError("peer closed before the request header")
        received.extend(chunk)
    header, payload = bytes(received).split(b"\n", 1)
    expected = int(header)
    while len(payload) < expected:
        chunk = connection.recv(4096)
        if not chunk:
            raise ConnectionError("peer closed before the request payload")
        payload += chunk
    return payload.decode("utf-8")


def write_descriptor(directory: Path, socket_path: Path, endpoint_epoch: int) -> Path:
    descriptor_path = directory / "connection.cjgui"
    descriptor = "\n".join(
        [
            f"PROTOCOL {client.PROTOCOL}",
            f"SOCKET_PATH_UTF8_HEX {len(os.fsencode(socket_path))} {os.fsencode(socket_path).hex().upper()}",
            "CAPABILITY_UTF8_HEX 5 746F6B656E",
            "CALLER_UTF8_HEX 6 7075626C6963",
            f"ENDPOINT_EPOCH {endpoint_epoch}",
            "ENDPOINT_INSTANCE test-endpoint",
            f"ENDPOINT_BIND_GENERATION {endpoint_epoch}",
            "END",
        ]
    )
    descriptor_path.write_text(descriptor, encoding="utf-8")
    descriptor_path.chmod(0o600)
    return descriptor_path


def candidate_reply(token: int, *, terminal: str, scene: str = "none", reason: str = "none",
                    path: str = "none", accepted_version: int = 0, current_accepted: int = 0,
                    pending: int = 0, endpoint_epoch: int = 7) -> str:
    return "\n".join(
        [
            f"PROTOCOL {client.PROTOCOL}",
            "KIND GENERATED_UI_CANDIDATE",
            f"ENDPOINT_EPOCH {endpoint_epoch}",
            "ENDPOINT_INSTANCE test-endpoint",
            f"ENDPOINT_BIND_GENERATION {endpoint_epoch}",
            f"CANDIDATE_TOKEN {token}",
            f"RECEIPT generated-ui-candidate-{token}",
            "BASE_VERSION 3",
            "CANDIDATE_VERSION 4",
            f"TERMINAL_STATE {terminal}",
            f"SCENE_STATE {scene}",
            f"REASON {reason}",
            f"PATH {path}",
            f"ACCEPTED_VERSION {accepted_version}",
            f"CURRENT_ACCEPTED_TOKEN {current_accepted}",
            f"PENDING_TOKEN {pending}",
            "END",
        ]
    )


class ScriptedTicketServer:
    """Wire-compatible peer that answers each candidate read from a script."""

    def __init__(self, replies: list[str]) -> None:
        self.replies = list(replies)
        self.requests: list[str] = []
        self._directory = tempfile.TemporaryDirectory()
        directory = Path(self._directory.name)
        self.socket_path = directory / "operation.sock"
        self.descriptor_path = write_descriptor(directory, self.socket_path, 7)
        self._ready = threading.Event()
        self._stop = threading.Event()
        self._failures: list[BaseException] = []
        self._thread = threading.Thread(target=self._serve)
        self._thread.start()
        self._ready.wait(2.0)

    def _serve(self) -> None:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                listener.bind(os.fspath(self.socket_path))
                listener.listen(8)
                listener.settimeout(0.2)
                self._ready.set()
                while not self._stop.is_set():
                    try:
                        connection, _ = listener.accept()
                    except socket.timeout:
                        continue
                    with connection:
                        payload = read_framed(connection)
                        self.requests.append(payload)
                        reply = self.replies.pop(0) if self.replies else self.replies_last
                        body = reply.encode("utf-8")
                        connection.sendall(f"{len(body)}\n".encode("ascii") + body)
        except BaseException as exc:
            self._failures.append(exc)

    replies_last = candidate_reply(1, terminal="PENDING")

    def close(self) -> None:
        self._stop.set()
        self._thread.join(2.0)
        self._directory.cleanup()
        if self._failures:
            raise self._failures[0]


class TicketTests(unittest.TestCase):
    def test_pending_then_accepted_uses_one_deadline(self) -> None:
        server = ScriptedTicketServer([
            candidate_reply(4, terminal="PENDING", scene="candidate_received", pending=4),
            candidate_reply(4, terminal="ACCEPTED", scene="scene_accepted",
                            accepted_version=4, current_accepted=4),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            ticket = generated.GeneratedCandidateTicket(4, "generated-ui-candidate-4",
                                             generated.GeneratedEndpointIdentity("test-endpoint", 7), 3, 4)
            started = time.monotonic()
            state = session.wait_for_candidate(ticket, timeout_ms=2_000, poll_ms=10)
            elapsed = time.monotonic() - started
            self.assertEqual(state.terminal_state, "ACCEPTED")
            self.assertEqual(state.scene_state, "scene_accepted")
            self.assertEqual(state.accepted_version, 4)
            self.assertFalse(state.accepted_then_replaced)
            self.assertEqual(state.endpoint_epoch, 7)
            self.assertLess(elapsed, 2.0)
            # Both reads were real requests for the ticket, nothing was replayed.
            self.assertEqual(len(server.requests), 2)
            self.assertIn("GET_GENERATED_UI_CANDIDATE 4", server.requests[0])
        finally:
            server.close()

    def test_superseded_and_rejected_keep_their_own_state(self) -> None:
        server = ScriptedTicketServer([
            candidate_reply(4, terminal="SUPERSEDED", scene="superseded_by_newer_candidate",
                            current_accepted=5),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            state = session.wait_for_candidate(4, timeout_ms=500, poll_ms=10)
            self.assertEqual(state.terminal_state, "SUPERSEDED")
            self.assertEqual(state.scene_state, "superseded_by_newer_candidate")
            self.assertFalse(state.accepted_then_replaced)
        finally:
            server.close()

        server = ScriptedTicketServer([
            candidate_reply(9, terminal="REJECTED", scene="candidate_rejected",
                            reason="malformed_node", path="1"),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            state = session.wait_for_candidate(9, timeout_ms=500, poll_ms=10)
            self.assertEqual(state.terminal_state, "REJECTED")
            self.assertEqual(state.reason, "malformed_node")
            self.assertEqual(state.path, "1")
        finally:
            server.close()

    def test_unknown_token_and_accepted_then_replaced(self) -> None:
        server = ScriptedTicketServer([
            candidate_reply(12, terminal="UNKNOWN", scene="none", current_accepted=11),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            state = session.wait_for_candidate(12, timeout_ms=500, poll_ms=10)
            self.assertEqual(state.terminal_state, "UNKNOWN")
            self.assertTrue(state.settled())
        finally:
            server.close()

        # The ticket was accepted; a LATER candidate is the accepted one now.
        server = ScriptedTicketServer([
            candidate_reply(11, terminal="ACCEPTED", scene="scene_accepted",
                            accepted_version=4, current_accepted=13),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            state = session.wait_for_candidate(11, timeout_ms=500, poll_ms=10)
            self.assertEqual(state.terminal_state, "ACCEPTED")
            self.assertTrue(state.accepted_then_replaced)
        finally:
            server.close()

    def test_endpoint_replacement_and_closed_endpoint_are_endpoint_errors(self) -> None:
        # A ticket that belongs to epoch 7 answered by an endpoint at epoch 8:
        # the attempt cannot be attributed to this endpoint any more.
        server = ScriptedTicketServer([
            candidate_reply(4, terminal="ACCEPTED", scene="scene_accepted",
                            accepted_version=4, current_accepted=4, endpoint_epoch=8),
        ])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            ticket = generated.GeneratedCandidateTicket(4, "generated-ui-candidate-4",
                generated.GeneratedEndpointIdentity("test-endpoint", 7), 3, 4)
            with self.assertRaises(generated.GeneratedUiEndpointError) as raised:
                session.wait_for_candidate(ticket, timeout_ms=500, poll_ms=10)
            self.assertEqual(raised.exception.code, "endpoint_replaced")
        finally:
            server.close()

        # The descriptor exists but no endpoint listens: an endpoint failure,
        # NOT a rejected candidate.
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "gone.sock"
            descriptor_path = write_descriptor(directory, socket_path, 7)
            session = generated.GeneratedUiSession.connect(str(descriptor_path))
            with self.assertRaises(generated.GeneratedUiEndpointError) as raised:
                session.wait_for_candidate(4, timeout_ms=200, poll_ms=10)
            self.assertEqual(raised.exception.code, "endpoint_unavailable")

    def test_submit_result_exposes_the_attempt_ticket(self) -> None:
        payload = "\n".join(
            [
                "GENERATED_UI_STRUCTURE 1",
                "NODE 0 root vertical",
                "NODE 1 edit textInput field=label",
                "END",
            ]
        )
        body = "\n".join(
            [
                f"PROTOCOL {client.PROTOCOL}",
                "KIND GENERATED_UI_SUBMIT",
                "APPLIED true",
                "REASON none",
                "PATH none",
                "VERSION_BEFORE 3",
                "VERSION_AFTER 3",
                "CANDIDATE_ACCEPTED true",
                "SCENE_ACCEPTED false",
                "CANDIDATE_VERSION 4",
                "ENDPOINT_EPOCH 7",
                "ENDPOINT_INSTANCE test-endpoint",
                "ENDPOINT_BIND_GENERATION 7",
                "CANDIDATE_TOKEN 21",
                "RECEIPT generated-ui-candidate-21",
                "END",
            ]
        )
        server = ScriptedTicketServer([body])
        try:
            session = generated.GeneratedUiSession.connect(str(server.descriptor_path))
            result = session.submit_text(payload, 3)
            self.assertEqual(result.candidate_token, 21)
            self.assertEqual(result.receipt, "generated-ui-candidate-21")
            self.assertEqual(result.endpoint_epoch, 7)
            ticket = result.ticket()
            self.assertEqual(ticket.token, 21)
            self.assertEqual(ticket.base_version, 3)
            self.assertEqual(ticket.candidate_version, 4)
            self.assertEqual(server.requests[0].split("\n")[2], "SUBMIT_GENERATED_UI 3")
            self.assertIn("NODE 1 edit textInput field=label", server.requests[0])
            self.assertEqual(len(server.requests), 1)
        finally:
            server.close()


if __name__ == "__main__":
    unittest.main()
