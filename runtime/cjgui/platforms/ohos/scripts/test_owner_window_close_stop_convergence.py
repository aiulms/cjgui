#!/usr/bin/env python3
"""Offline source contract for normal owner exit after a window close."""

from pathlib import Path
import os
import re
import unittest


HOST_SOURCE = Path(__file__).resolve().parents[1] / "host" / "cjgui_host_bridge.cpp"


def block_after(source: str, marker: str) -> str:
    """Return the brace-delimited C++ block immediately following marker."""
    start = source.index(marker)
    opening = source.index("{", start + len(marker))
    depth = 0
    for index in range(opening, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[opening + 1:index]
    raise AssertionError(f"unclosed C++ block after {marker!r}")


class OwnerWindowCloseStopConvergenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source_path = Path(os.environ.get("CJGUI_HOST_SOURCE", str(HOST_SOURCE)))
        cls.source = source_path.read_text(encoding="utf-8")
        returned = cls.source.index("int rc = appMain(&g_ingress);")
        cls.owner_return = cls.source[returned:]
        cls.owner_return_block = cls.owner_return.split("\n    });", 1)[0]
        observer_signature = "static void startStopMonitorOnce(uint64_t stopAppInstance)"
        observer_start = cls.source.rfind(observer_signature)
        cls.observer = (block_after(cls.source[observer_start:], observer_signature)
                        if observer_start >= 0 else "")

    def test_declared_normal_exit_from_running_enters_same_instance_stop_monitor(self):
        """Window-close owner exit must not take the old Running -> Failed path."""
        self.assertTrue(re.search(r"orderly\s*=\s*rc\s*==\s*0\s*&&\s*ownerStopDeclared", self.owner_return),
                        "rc success plus owner stop declaration must define orderly exit")
        self.assertTrue(re.search(r"else if \(orderly && \(after == kHostStarting \|\| after == kHostRunning\)\)",
                                  self.owner_return),
                        "orderly owner exit from Running must be adopted")
        orderly_branch = block_after(self.owner_return, "else if (orderly && (after == kHostStarting || after == kHostRunning))")
        self.assertTrue(re.search(r"g_hostPhase\.store\(kHostStopping\)", orderly_branch))
        self.assertRegex(orderly_branch, r"startMonitor\s*=\s*true")
        self.assertNotRegex(self.owner_return_block,
                            r"requestHostStopOnce|requestAppStopFn|retireAllSurfacesOfInstance")
        self.assertTrue(re.search(r"if \(startMonitor\)\s*startStopMonitorOnce\(startAppInstance\)",
                                  self.owner_return_block))

    def test_stop_outcome_is_recorded_before_owner_exit_signal(self):
        """The monitor must observe the chosen stop state before ownerExited."""
        self.assertTrue("g_ownerOutcome = orderly ? 0 : 1;" in self.owner_return_block,
                        "outcome must be written before ownerExited")
        outcome = self.owner_return_block.index("g_ownerOutcome = orderly ? 0 : 1;")
        stopping = self.owner_return_block.index("g_hostPhase.store(kHostStopping);")
        exited = self.owner_return_block.index("g_ownerExited.store(true);")
        monitor = self.owner_return_block.index("startStopMonitorOnce(startAppInstance)")
        self.assertLess(outcome, stopping)
        self.assertLess(stopping, exited)
        self.assertLess(exited, monitor)

    def test_abnormal_owner_exit_marks_failed_even_if_stop_was_in_progress(self):
        abnormal_stop = re.search(
            r"if \(!orderly && \(after == kHostStarting \|\| after == kHostRunning \|\| after == kHostStopping\)\)\s*\{\s*g_hostPhase\.store\(kHostFailed\)",
            self.owner_return_block,
        )
        self.assertTrue(abnormal_stop,
                        "abnormal exit must fail even if it races with Stopping")

    def test_observer_only_settles_same_orderly_instance_with_all_counters_zero(self):
        self.assertTrue(re.search(r"std::thread\(\[stopAppInstance\]", self.observer),
                        "same-instance observer must own its monitor thread")
        self.assertTrue(re.search(
            r"g_appInstance\.load\(\)\s*!=\s*stopAppInstance[\s\S]*?g_ownerOutcomeInstance\s*!=\s*stopAppInstance",
            self.observer,
        ), "observer must reject stale appInstance and owner-outcome identities")
        self.assertRegex(self.observer, r"ownerOutcome\s*=\s*g_ownerOutcome")
        self.assertRegex(self.observer, r"ownerJoined && ownerOutcome == 0")
        self.assertRegex(self.observer, r"rendererDone \|\| rendererNotStarted")
        for condition in ("occupied == 0", "unacked == 0", "pending == 0",
                          "refsUnclosed == 0", "activeSurfaces == 0"):
            self.assertIn(condition, self.observer)
        self.assertRegex(self.observer,
                         r"converged && g_ownerOutcome == 0 && after == kHostStopping")
        self.assertRegex(self.observer, r"g_hostPhase\.store\(kHostStopped\)")


if __name__ == "__main__":
    unittest.main()
