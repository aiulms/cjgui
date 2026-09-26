#!/usr/bin/env python3
"""End-to-end monotonic-deadline tests over a REAL AF_UNIX server.

Nothing here mocks `exchange`, `read_frame` or `socket`: a threaded
wire-compatible peer records the exact accepted bytes and timings, so the single
absolute deadline is proven on genuine blocking I/O:

* a peer that accepts the framed request and never replies makes the client
  time out near its total budget;
* a peer that trickles the response in fragments whose gaps sum past the budget
  must still time out on the TOTAL deadline (per-fragment resets are banned);
* a zero / already-expired budget never connects (accept count stays zero);
* a genuinely fragmented response inside the budget parses, and the
  `fragment_bytes=1` request path still delivers the complete frame.
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


def framed(payload: str) -> bytes:
    encoded = payload.encode("utf-8")
    return f"{len(encoded)}\n".encode("ascii") + encoded


def read_framed(connection: socket.socket) -> tuple[str, int]:
    """Read exactly one request frame; return (payload, accepted byte count)."""

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
    return payload.decode("utf-8"), len(header) + 1 + len(payload)


def write_descriptor(directory: Path, socket_path: Path):
    descriptor_path = directory / "connection.cjgui"
    descriptor = "\n".join(
        [
            f"PROTOCOL {client.PROTOCOL}",
            f"SOCKET_PATH_UTF8_HEX {len(os.fsencode(socket_path))} {os.fsencode(socket_path).hex().upper()}",
            "CAPABILITY_UTF8_HEX 5 746F6B656E",
            "CALLER_UTF8_HEX 6 7075626C6963",
            "END",
        ]
    )
    descriptor_path.write_text(descriptor, encoding="utf-8")
    descriptor_path.chmod(0o600)
    return descriptor_path


def result_response() -> str:
    return "\n".join(
        [
            f"PROTOCOL {client.PROTOCOL}",
            "KIND RESULT",
            "APPLIED true",
            "CONFLICT false",
            "VERSION_BEFORE 7",
            "VERSION_AFTER 8",
            "REASON applied",
            "END",
        ]
    )


class DeadlineTests(unittest.TestCase):
    def test_silent_peer_times_out_near_the_total_budget(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)
            ready = threading.Event()
            release = threading.Event()
            state: dict[str, float] = {"accepted": 0.0, "bytes": 0.0, "accepted_at": 0.0}
            failures: list[BaseException] = []

            def serve() -> None:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                        listener.bind(os.fspath(socket_path))
                        listener.listen(1)
                        ready.set()
                        connection, _ = listener.accept()
                        state["accepted"] = 1.0
                        state["accepted_at"] = time.monotonic()
                        with connection:
                            _payload, accepted_bytes = read_framed(connection)
                            state["bytes"] = float(accepted_bytes)
                            # Accept, read the full frame, then stay silent: the
                            # client must time out on its own budget.
                            release.wait(1.0)
                except BaseException as exc:
                    failures.append(exc)

            thread = threading.Thread(target=serve)
            thread.start()
            self.assertTrue(ready.wait(1))
            started = time.monotonic()
            with self.assertRaises(TimeoutError):
                client.SharedOperationClient.from_descriptor(descriptor_path).request(
                    f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_CONTEXT 0",
                    timeout_seconds=0.15,
                )
            elapsed = time.monotonic() - started
            release.set()
            thread.join(1)
            if failures:
                raise failures[0]

            # The peer really accepted (and read a full frame) promptly; the
            # client gave up near the 150 ms budget instead of waiting forever.
            self.assertEqual(state["accepted"], 1.0)
            self.assertGreaterEqual(state["accepted_at"], started)
            self.assertLess(state["accepted_at"], started + 0.1)
            self.assertGreater(state["bytes"], 0.0)
            self.assertGreaterEqual(elapsed, 0.12)
            self.assertLess(elapsed, 0.35)

    def test_trickled_response_times_out_on_the_total_deadline(self) -> None:
        budget = 0.12
        gap = 0.03
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)
            ready = threading.Event()
            state: dict[str, float] = {"bytes": 0.0, "sent_bytes": 0.0, "fragments": 0.0}
            failures: list[BaseException] = []

            def serve() -> None:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                        listener.bind(os.fspath(socket_path))
                        listener.listen(1)
                        ready.set()
                        connection, _ = listener.accept()
                        with connection:
                            _payload, accepted_bytes = read_framed(connection)
                            state["bytes"] = float(accepted_bytes)
                            data = framed(result_response())
                            for index in range(len(data)):
                                connection.send(data[index : index + 1])
                                state["sent_bytes"] += 1.0
                                state["fragments"] += 1.0
                                time.sleep(gap)
                except OSError:
                    # The client closed its end at the total deadline, which is
                    # exactly the behaviour under test.
                    pass
                except BaseException as exc:
                    failures.append(exc)

            thread = threading.Thread(target=serve)
            thread.start()
            self.assertTrue(ready.wait(1))
            started = time.monotonic()
            with self.assertRaises(TimeoutError):
                client.SharedOperationClient.from_descriptor(descriptor_path).request(
                    f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_CONTEXT 0",
                    timeout_seconds=budget,
                )
            elapsed = time.monotonic() - started
            thread.join(1)
            if failures:
                raise failures[0]

            self.assertGreater(state["bytes"], 0.0)
            # Every fragment gap is short, but their sum runs far past the
            # budget: only a shared absolute deadline can stop it.
            nominal_trickle = len(framed(result_response())) * gap
            self.assertGreater(nominal_trickle, 1.0)
            self.assertLess(state["sent_bytes"], len(framed(result_response())))
            self.assertGreaterEqual(elapsed, budget * 0.6)
            self.assertLess(elapsed, nominal_trickle / 2)

    def test_zero_or_expired_budget_never_connects(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)
            ready = threading.Event()
            stop = threading.Event()
            state = {"accepted": 0}
            failures: list[BaseException] = []

            def serve() -> None:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                        listener.bind(os.fspath(socket_path))
                        listener.listen(4)
                        listener.settimeout(0.05)
                        ready.set()
                        while not stop.is_set():
                            try:
                                connection, _ = listener.accept()
                            except socket.timeout:
                                continue
                            except OSError:
                                break
                            state["accepted"] += 1
                            connection.close()
                except BaseException as exc:
                    failures.append(exc)

            thread = threading.Thread(target=serve)
            thread.start()
            self.assertTrue(ready.wait(1))
            operation = client.SharedOperationClient.from_descriptor(descriptor_path)
            payload = f"PROTOCOL {client.PROTOCOL}\nAUTH token\nGET_CONTEXT 0"

            started = time.monotonic()
            with self.assertRaises(TimeoutError):
                operation.request(payload, timeout_seconds=0)
            self.assertLess(time.monotonic() - started, 0.05)

            with self.assertRaises(TimeoutError):
                operation.request(payload, deadline_monotonic=time.monotonic() - 1.0)

            # Give a stray connect time to be accepted before asserting.
            time.sleep(0.15)
            stop.set()
            thread.join(1)
            if failures:
                raise failures[0]
            self.assertEqual(state["accepted"], 0)

    def test_fragmented_response_within_budget_parses_and_fragment_bytes_one_request(self) -> None:
        replacements = [
            client.TextReplacement(3, 6, "A"),
            client.TextReplacement(9, 12, "丁丁"),
        ]
        encoded_body = client.encode_text_replacements(replacements)
        expected_payload = "\n".join(
            [
                f"PROTOCOL {client.PROTOCOL}",
                "AUTH token",
                "INVOKE 7 REPLACE_RANGES 1 1",
                "ID 42",
                f"ARG replacements TEXT_REPLACEMENTS {len(encoded_body.encode('utf-8'))} "
                f"{encoded_body.encode('utf-8').hex().upper()}",
            ]
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            socket_path = directory / "operation.sock"
            descriptor_path = write_descriptor(directory, socket_path)
            ready = threading.Event()
            state: dict[str, object] = {"bytes": 0.0, "fragments": 0.0}
            failures: list[BaseException] = []

            def serve() -> None:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                        listener.bind(os.fspath(socket_path))
                        listener.listen(1)
                        ready.set()
                        connection, _ = listener.accept()
                        with connection:
                            payload, accepted_bytes = read_framed(connection)
                            state["bytes"] = float(accepted_bytes)
                            state["payload"] = payload
                            data = framed(result_response())
                            for index in range(0, len(data), 5):
                                connection.send(data[index : index + 5])
                                state["fragments"] = float(state["fragments"]) + 1.0
                                time.sleep(0.002)
                except BaseException as exc:
                    failures.append(exc)

            thread = threading.Thread(target=serve)
            thread.start()
            self.assertTrue(ready.wait(1))
            started = time.monotonic()
            response = client.SharedOperationClient.from_descriptor(
                descriptor_path, fragment_bytes=1
            ).invoke(
                7,
                "REPLACE_RANGES",
                [42],
                [client.SharedOperationArgument.text_replacements("replacements", replacements)],
                timeout_seconds=2.0,
            )
            elapsed = time.monotonic() - started
            thread.join(1)
            if failures:
                raise failures[0]

            # The 1-byte send path delivered the complete canonical frame (the
            # peer read exactly it), and the fragmented response parsed inside
            # budget.
            self.assertEqual(state["payload"], expected_payload)
            self.assertEqual(state["bytes"], float(len(framed(expected_payload))))
            self.assertGreater(float(state["fragments"]), 2.0)
            self.assertEqual(response.kind, "RESULT")
            self.assertTrue(response.boolean("APPLIED"))
            self.assertEqual(response.integer("VERSION_AFTER"), 8)
            self.assertLess(elapsed, 2.0)


if __name__ == "__main__":
    unittest.main()
