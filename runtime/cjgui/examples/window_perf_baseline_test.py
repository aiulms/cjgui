#!/usr/bin/env python3
"""Focused contract tests for normal-window baseline lifecycle signals."""

from __future__ import annotations

import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import textwrap
import unittest

import window_perf_baseline as baseline


ROOT = Path(__file__).resolve().parent


class WindowReadySignalTest(unittest.TestCase):
    def test_preserves_current_workload_facts_without_inventing_missing_timings(self) -> None:
        response = baseline.public_client.SharedOperationResponse("CJGUI_SHARED_OPERATION/2", "WINDOW_PROGRESS",
            (("WINDOW_WORKLOAD_TEXT_LAYOUT_PREPARATIONS", ("63",)),), "original")
        facts = baseline.window_progress(response)
        self.assertEqual("63", facts["WINDOW_WORKLOAD_TEXT_LAYOUT_PREPARATIONS"])
        self.assertNotIn("WINDOW_WORK_TIMING_MS", facts)

    def test_sparse_observation_retains_stderr_and_normal_close(self) -> None:
        import io
        with tempfile.TemporaryDirectory(prefix="cjgui-sparse-cost-") as temporary:
            root = Path(temporary)
            app = root / "window.py"
            app.write_text("#!/usr/bin/env python3\nimport sys,time\n"
                "print('CJGUI_RULE_SET_READY WINDOW_READY sparse_session 1',flush=True)\n"
                "sys.stderr.write('x'*131072);sys.stderr.flush()\ntime.sleep(.3)\n")
            app.chmod(0o755)
            result = baseline.observe_interactive_window(app, [], root / "result.json",
                sample_s=.05, maximum_s=3, commands=io.StringIO(''))
            self.assertEqual(0, result["exit_code"])
            self.assertEqual("sparse_session", result["ready"]["session_identity"])
            self.assertGreater(len(result["samples"]), 0)
            self.assertEqual(131072, (root / "result.stderr.log").stat().st_size)
            self.assertIsNone(result["presentation_latency_ns"])

    def test_reports_ready_and_warmup_intervals_without_combining_them(self) -> None:
        timings = baseline.lifecycle_timings(10.0, 12.25, 17.0)

        self.assertEqual(2.25, timings["startup_to_ready_s"])
        self.assertEqual(4.75, timings["ready_to_measurement_start_s"])

    def test_requires_a_submitted_window_signal_after_a_descriptor(self) -> None:
        lines = [
            "CJGUI_RULE_SET_READY DESCRIPTOR_PATH /private/tmp/descriptor",
            "CJGUI_RULE_SET_READY PROTOCOL CJGUI_SHARED_OPERATION/2",
        ]

        self.assertIsNone(baseline.window_ready_signal(lines))

        lines.append("CJGUI_RULE_SET_READY WINDOW_READY session_42 1")
        ready = baseline.window_ready_signal(lines)

        self.assertIsNotNone(ready)
        assert ready is not None
        self.assertEqual("CJGUI_RULE_SET_READY", ready.marker)
        self.assertEqual("session_42", ready.session_identity)
        self.assertEqual(1, ready.submitted_frame_index)
        self.assertIsNone(baseline.measurement_start_signal(lines, ready))

        lines.append("CJGUI_RULE_SET_READY MEASUREMENT_START session_42")
        self.assertEqual(ready, baseline.measurement_start_signal(lines, ready))

    def test_rejects_an_invalid_or_unsubmitted_window_signal(self) -> None:
        self.assertIsNone(baseline.window_ready_signal([
            "CJGUI_SHARED_DOCUMENT_READY WINDOW_READY session_9 0",
        ]))
        self.assertIsNone(baseline.window_ready_signal([
            "CJGUI_SHARED_DOCUMENT_READY WINDOW_READY session_9 invalid",
        ]))
        ready = baseline.WindowReadySignal("CJGUI_SHARED_DOCUMENT_READY", "session_9", 1)
        self.assertIsNone(baseline.measurement_start_signal([
            "CJGUI_SHARED_DOCUMENT_READY MEASUREMENT_START another_session",
        ], ready))

    def test_marks_zero_rss_or_thread_samples_as_terminal_races(self) -> None:
        self.assertTrue(baseline.is_live_process_sample({"rss_kib": 1024, "threads": 2}))
        self.assertFalse(baseline.is_live_process_sample({"rss_kib": 0, "threads": 2}))
        self.assertFalse(baseline.is_live_process_sample({"rss_kib": 1024, "threads": 0}))

    def test_run_cycle_drains_large_stderr_before_child_exit(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cjgui-window-stderr-test-") as temporary:
            temporary_path = Path(temporary)
            fake_app = temporary_path / "fake_window.py"
            fake_app.write_text(textwrap.dedent("""\
                #!/usr/bin/env python3
                import sys
                import time
                print('CJGUI_RULE_SET_READY WINDOW_READY fake_session 1', flush=True)
                print('CJGUI_RULE_SET_READY MEASUREMENT_START fake_session', flush=True)
                sys.stderr.write('x' * (128 * 1024))
                sys.stderr.flush()
                time.sleep(0.2)
            """), encoding="utf-8")
            fake_app.chmod(0o755)
            invocation = textwrap.dedent(f"""\
                import sys
                from pathlib import Path
                sys.path.insert(0, {str(ROOT)!r})
                import window_perf_baseline as baseline
                baseline.run_cycle('stderr-drain', Path({str(fake_app)!r}), [], 1.0, 0.0, 0.1, False, False)
            """)
            process = subprocess.Popen(
                [sys.executable, "-c", invocation],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                start_new_session=True,
            )
            try:
                stdout, stderr = process.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGTERM)
                stdout, stderr = process.communicate(timeout=5)
                self.fail(f"run_cycle blocked on a child stderr pipe: stdout={stdout!r} stderr={stderr!r}")
            self.assertEqual(0, process.returncode, stderr)


if __name__ == "__main__":
    unittest.main()
