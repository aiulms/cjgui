"""Runner contract regression cases; initially exercised against W1's RED runner."""
from contextlib import redirect_stderr, redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import socket
import sys
import threading
import time
import tempfile
import unittest
from unittest.mock import patch


W1_RUNNER = Path(__file__).with_name("windows_runner.py")


def load_runner():
    spec = importlib.util.spec_from_file_location("pharos_windows_runner_under_test", W1_RUNNER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def invoke(body, status="OK", include_result=True, extra_results=None):
    module = load_runner()
    with tempfile.TemporaryDirectory(prefix="pharos-windows-runner-") as folder:
        script = Path(folder) / "task.ps1"
        script.write_text("# transport is substituted; never executed\n", encoding="utf-8")
        results = {script.name: body} if include_result else {}
        results.update(extra_results or {})
        module.run_batch = lambda scripts: (results, status)
        old_argv = sys.argv
        try:
            sys.argv = [str(W1_RUNNER), str(script)]
            with redirect_stdout(io.StringIO()):
                return module.legacy_main()
        finally:
            sys.argv = old_argv


class RunnerContractTest(unittest.TestCase):
    def test_malformed_exit_trailer_fails_closed(self):
        self.assertNotEqual(invoke("result\n[exit=not-an-integer]"), 0)

    def test_partial_transport_result_cannot_report_success(self):
        self.assertNotEqual(
            invoke("partial result\n[exit=0]", status="transport error: truncated final response"), 0
        )

    def test_missing_requested_result_fails(self):
        self.assertNotEqual(invoke(None, include_result=False), 0)

    def test_unrequested_extra_result_fails(self):
        self.assertNotEqual(invoke("result\n[exit=0]", extra_results={"extra.ps1": "[exit=0]"}), 0)

    def test_trailer_must_be_a_standalone_final_line(self):
        self.assertNotEqual(invoke("result\n[exit=0] trailing text"), 0)

    def test_duplicate_exit_trailers_fail_closed(self):
        self.assertNotEqual(invoke("result\n[exit=0]\n[exit=7]"), 0)

    def test_real_nonzero_exit_code_is_preserved(self):
        self.assertEqual(invoke("negative control\n[exit=7]"), 7)

    def test_complete_success_is_zero(self):
        self.assertEqual(invoke("positive control\n[exit=0]"), 0)

    def test_disconnect_before_done_is_not_a_complete_transport(self):
        module = load_runner()
        module.start_worker = lambda: None
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
            probe.bind(("127.0.0.1", 0))
            module.PORT = probe.getsockname()[1]

        outcomes = []
        receiver = threading.Thread(
            target=lambda: outcomes.append(module.run_batch({"task.ps1": "Write-Output 'ok'"}, timeout=5)),
            daemon=True,
        )
        receiver.start()
        deadline = time.monotonic() + 3
        client = None
        while time.monotonic() < deadline:
            try:
                client = socket.create_connection(("127.0.0.1", module.PORT), timeout=0.2)
                break
            except OSError:
                time.sleep(0.01)
        self.assertIsNotNone(client, "local fake worker could not connect")

        with client:
            client.settimeout(3)
            stream = client.makefile("rb")
            client.sendall(b"HELLO fake\n")
            header = stream.readline()
            self.assertTrue(header.startswith(b"BATCH "))
            payload_length = int(header.split()[1])
            self.assertEqual(len(stream.read(payload_length)), payload_length)
            self.assertEqual(stream.readline(), b"\n")
            # Simulate a worker that sent a success-looking partial result and
            # closed before the required DONE terminator.
            body = b"partial\n[exit=0]"
            client.sendall(b"RES task.ps1 " + str(len(body)).encode("ascii") + b"\n" + body + b"\n")
            self.assertEqual(stream.readline(), b"ACK\n")
            stream.close()

        receiver.join(timeout=3)
        self.assertFalse(receiver.is_alive(), "host runner did not finish after peer disconnect")
        self.assertEqual(len(outcomes), 1)
        _results, status = outcomes[0]
        self.assertFalse(status.startswith("OK"), "EOF before DONE must not be accepted as a complete batch")

    def test_eof_with_unterminated_protocol_line_is_named_and_rejected(self):
        module = load_runner()
        receiver, sender = socket.socketpair()
        try:
            sender.sendall(b"DONE 0123456789abcdef")
            sender.close()
            with self.assertRaisesRegex(module.WorkerProtocolError, "incomplete_protocol_line_eof"):
                module.WindowsWorkerSession._read_line_from(receiver, time.monotonic() + 1)
        finally:
            receiver.close()

    def test_transport_timeout_retires_socket_and_shutdown_never_sends_stop(self):
        module = load_runner()

        class FakeSocket:
            def __init__(self):
                self.sent = []
                self.closed = False

            def sendall(self, payload):
                self.sent.append(payload)

            def close(self):
                self.closed = True

        session = object.__new__(module.WindowsWorkerSession)
        fake_socket = FakeSocket()
        session.socket = fake_socket
        session.protocol_state = "connected"
        session.transport_status = "connected"
        session.transport_failure = None
        session.worker = {"pid": 42}
        session.session_id = "0123456789abcdef0123456789abcdef"
        session.batch_count = 0
        session.stop_status = "not_requested"
        session.stopped_at = None
        session._write_session_manifest = lambda: None
        session._stop_servers = lambda: None
        with patch.object(module.WindowsWorkerSession, "_read_line_from",
                          side_effect=TimeoutError("line_deadline_expired")):
            _nonce, _response, status = session.run_batch(
                {"task.ps1": "Write-Output 'late'"}, timeout=1, task_timeout_ms=1)
        self.assertTrue(status.startswith("transport_failed: line_deadline_expired"))
        self.assertTrue(fake_socket.closed)
        self.assertIsNone(session.socket)
        session.shutdown()
        self.assertFalse(any(payload.startswith(b"STOP ") for payload in fake_socket.sent),
                         "a desynchronized session must not receive STOP")

    def test_batch_deadline_has_task_cleanup_and_result_margin(self):
        module = load_runner()
        deadline = module.minimum_batch_timeout_seconds(30, [60000, 120000])
        self.assertGreaterEqual(deadline, 30)
        self.assertGreater(deadline, 180, "host deadline must include both task budgets plus cleanup/results")

    def test_interactive_task_exit_failure_is_retained(self):
        module = load_runner()
        with tempfile.TemporaryDirectory(prefix="pharos-runner-task-fail-") as folder:
            root = Path(folder)
            artifact_root = root / "artifacts"
            script_root = root / "jobs"
            script_root.mkdir()
            (script_root / "task.ps1").write_text("exit 7\n", encoding="utf-8")

            class FakeSession:
                def __init__(self, _worker, artifact_root_arg, **_kwargs):
                    self.session_id = "task-failure"
                    self.worker = {"pid": 42, "process_architecture": "x64",
                                   "worker_path": "C:\\worker.ps1", "worker_sha256": "abc"}
                    self.batch_count = 0
                    self.session_dir = Path(artifact_root_arg) / "runner-sessions" / self.session_id
                    self.session_dir.mkdir(parents=True)

                def run_batch(self, scripts, **_kwargs):
                    return "nonce-task-failure", {
                        "nonce": "nonce-task-failure", "state": "complete", "results": [{
                            "name": "task.ps1", "exit_code": 7, "timed_out": False,
                            "stdout_truncated": False, "stderr_truncated": False,
                            "stdout_b64": "", "stderr_b64": "", "elapsed_ms": 1, "error": "",
                        }]
                    }, "OK"

                def shutdown(self):
                    return "BYE_AND_SOCKET_CLOSED"

            old_stdin = sys.stdin
            sys.stdin = io.StringIO("run task.ps1\nexit\n")
            output = io.StringIO()
            try:
                with patch.object(module, "WindowsWorkerSession", FakeSession), redirect_stdout(output):
                    code = module.interactive_main([
                        "--artifact-root", str(artifact_root), "--root", str(script_root)
                    ])
            finally:
                sys.stdin = old_stdin
            self.assertNotEqual(code, 0)
            self.assertIn("TASK_RESULT name=task.ps1 exit=7", output.getvalue())

    def test_interactive_transport_failure_stops_later_batches_and_is_logged(self):
        module = load_runner()
        with tempfile.TemporaryDirectory(prefix="pharos-runner-transport-fail-") as folder:
            root = Path(folder)
            artifact_root = root / "artifacts"
            script_root = root / "jobs"
            script_root.mkdir()
            (script_root / "task.ps1").write_text("Write-Output 'ok'\n", encoding="utf-8")

            class FakeSession:
                calls = 0

                def __init__(self, _worker, artifact_root_arg, **_kwargs):
                    self.session_id = "transport-failure"
                    self.worker = {"pid": 42, "process_architecture": "x64",
                                   "worker_path": "C:\\worker.ps1", "worker_sha256": "abc"}
                    self.batch_count = 0
                    self.session_dir = Path(artifact_root_arg) / "runner-sessions" / self.session_id
                    self.session_dir.mkdir(parents=True)

                def run_batch(self, _scripts, **_kwargs):
                    type(self).calls += 1
                    return "nonce-transport-failure", None, "transport_failed: frame_timeout"

                def shutdown(self):
                    return "shutdown_unavailable_after_transport_failure: frame_timeout"

            old_stdin = sys.stdin
            sys.stdin = io.StringIO("run task.ps1\nrun task.ps1\nexit\n")
            output = io.StringIO()
            errors = io.StringIO()
            try:
                with patch.object(module, "WindowsWorkerSession", FakeSession), \
                     redirect_stdout(output), redirect_stderr(errors):
                    code = module.interactive_main([
                        "--artifact-root", str(artifact_root), "--root", str(script_root)
                    ])
            finally:
                sys.stdin = old_stdin
            self.assertNotEqual(code, 0)
            self.assertEqual(FakeSession.calls, 1, "transport failure must retire the interactive session")
            logs = list((artifact_root / "runner-sessions" / "transport-failure" / "results").glob("*.json"))
            self.assertEqual(len(logs), 1)
            self.assertEqual(json.loads(logs[0].read_text(encoding="utf-8"))["transport_status"],
                             "transport_failed: frame_timeout")

    def test_interactive_shutdown_failure_changes_exit_code(self):
        module = load_runner()
        with tempfile.TemporaryDirectory(prefix="pharos-runner-shutdown-fail-") as folder:
            root = Path(folder)
            artifact_root = root / "artifacts"

            class FakeSession:
                def __init__(self, _worker, _artifact_root_arg, **_kwargs):
                    self.session_id = "shutdown-failure"
                    self.worker = {"pid": 42, "process_architecture": "x64",
                                   "worker_path": "C:\\worker.ps1", "worker_sha256": "abc"}
                    self.batch_count = 0

                def shutdown(self):
                    return "shutdown_failed: forced_negative_control"

            old_stdin = sys.stdin
            sys.stdin = io.StringIO("exit\n")
            output = io.StringIO()
            try:
                with patch.object(module, "WindowsWorkerSession", FakeSession), redirect_stdout(output):
                    code = module.interactive_main([
                        "--artifact-root", str(artifact_root), "--root", str(root)
                    ])
            finally:
                sys.stdin = old_stdin
            self.assertNotEqual(code, 0)
            self.assertIn("shutdown_failed: forced_negative_control", output.getvalue())


if __name__ == "__main__":
    unittest.main()
