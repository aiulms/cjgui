"""Structured worker protocol contract; written before its validator/worker."""
import base64
import importlib.util
from pathlib import Path
import unittest


RUNNER_PATH = Path(__file__).with_name("windows_runner.py")
WORKER_PATH = Path(__file__).with_name("worker_run.ps1")
SPEC = importlib.util.spec_from_file_location("windows_runner_protocol_under_test", RUNNER_PATH)
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


def encoded(text):
    return base64.b64encode(text.encode("utf-8")).decode("ascii")


def result(name="one.ps1", exit_code=0, **overrides):
    record = {
        "name": name,
        "exit_code": exit_code,
        "timed_out": False,
        "stdout_truncated": False,
        "stderr_truncated": False,
        "stdout_b64": encoded("stdout"),
        "stderr_b64": encoded("stderr"),
        "elapsed_ms": 12,
        "error": "",
    }
    record.update(overrides)
    return record


def payload(*records, nonce="run-1", state="complete"):
    return {"nonce": nonce, "state": state, "results": list(records)}


class StructuredWorkerProtocolTest(unittest.TestCase):
    def test_task_job_is_closed_before_output_pipe_drain(self):
        source = WORKER_PATH.read_text(encoding="utf-8")
        exit_record = source.index("$record.exit_code = [int]$process.ExitCode")
        pipe_drain = source.index("::WaitAll", exit_record)
        job_cleanup = source.index("$childJob.Dispose()", exit_record)
        self.assertLess(job_cleanup, pipe_drain,
                        "descendants can retain inherited stdout/stderr handles until the pipe drain times out")

    def validator(self):
        function = getattr(RUNNER, "validate_worker_batch", None)
        self.assertTrue(callable(function), "structured worker result validator is missing")
        return function

    def test_exit_code_seven_is_preserved(self):
        records = self.validator()(["one.ps1"], payload(result(exit_code=7)), "run-1")
        self.assertEqual(records[0]["exit_code"], 7)

    def test_exit_code_boolean_is_not_an_integer_result(self):
        with self.assertRaisesRegex(ValueError, "exit_code_type"):
            self.validator()(["one.ps1"], payload(result(exit_code=True)), "run-1")

    def test_partial_transport_never_accepts_success_looking_results(self):
        with self.assertRaisesRegex(ValueError, "transport_failed"):
            self.validator()(["one.ps1"], payload(result(exit_code=0)), "run-1", "transport_failed: truncated")

    def test_missing_extra_and_duplicate_results_fail(self):
        validate = self.validator()
        with self.assertRaisesRegex(ValueError, "missing_results"):
            validate(["one.ps1", "two.ps1"], payload(result()), "run-1")
        with self.assertRaisesRegex(ValueError, "unexpected_results"):
            validate(["one.ps1"], payload(result(), result(name="two.ps1")), "run-1")
        with self.assertRaisesRegex(ValueError, "duplicate_result"):
            validate(["one.ps1"], payload(result(), result()), "run-1")

    def test_timeout_and_truncated_stream_fail_even_with_exit_zero(self):
        validate = self.validator()
        with self.assertRaisesRegex(ValueError, "task_timeout"):
            validate(["one.ps1"], payload(result(timed_out=True)), "run-1")
        with self.assertRaisesRegex(ValueError, "output_truncated"):
            validate(["one.ps1"], payload(result(stdout_truncated=True)), "run-1")

    def test_nonce_and_terminal_state_are_required(self):
        validate = self.validator()
        with self.assertRaisesRegex(ValueError, "nonce_mismatch"):
            validate(["one.ps1"], payload(result(), nonce="stale"), "run-1")
        with self.assertRaisesRegex(ValueError, "worker_not_complete"):
            validate(["one.ps1"], payload(result(), state="running"), "run-1")

    def test_cancelled_result_is_named_and_never_success(self):
        validate = self.validator()
        records = validate(["one.ps1"], payload(result(exit_code=125, cancelled=True)), "run-1")
        self.assertTrue(records[0]["cancelled"])
        self.assertEqual(records[0]["exit_code"], 125)
        with self.assertRaisesRegex(ValueError, "cancelled_and_timed_out"):
            validate(["one.ps1"], payload(result(timed_out=True, cancelled=True)), "run-1")
        with self.assertRaisesRegex(ValueError, "cancelled_flag_invalid"):
            validate(["one.ps1"], payload(result(cancelled="yes")), "run-1")

    def test_worker_has_bounded_named_cancel_channel(self):
        source = WORKER_PATH.read_text(encoding="utf-8")
        self.assertIn("Pump-Control", source, "the task wait loop must keep reading control frames")
        self.assertIn("$script:cancelRequested", source)
        self.assertIn("New-CancelledRecord", source, "cancelled jobs need an explicit record")
        self.assertIn("cancelled_child_not_reaped", source, "cancel must reap the killed child")
        wait_index = source.index("$waitRemaining = [int]$Job.timeout_ms")
        kill_index = source.index("$record.cancelled = $true")
        self.assertLess(wait_index, kill_index, "cancel is only checked inside the bounded wait loop")


if __name__ == "__main__":
    unittest.main()
