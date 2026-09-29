#!/usr/bin/env python3
"""Offline counterexamples for same-key rebind during a real held touch."""

import unittest

import verify_normal_touch_rebind as probe


class TouchRebindGateTest(unittest.TestCase):
    def evidence(self):
        return {
            "pid": "123", "gesture_epoch": 42,
            "positive": {"before": {"version": 0, "temp": 22, "note": ""},
                         "after": {"version": 1, "temp": 23, "note": ""},
                         "begin": {"pid": "123", "epoch": 41, "action": 37},
                         "terminal": {"pid": "123", "epoch": 41, "action": 39}},
            "rebind": {"before": {"version": 1, "temp": 23, "note": ""},
                       "after": {"version": 1, "temp": 23, "note": ""},
                       "begin": {"pid": "123", "epoch": 42, "action": 37},
                       "terminal": {"pid": "123", "epoch": 42, "action": 39},
                       "begin_before_submit": True,
                       "terminal_absent_at_acceptance": True,
                       "process_running_at_acceptance": True,
                       "ticket_terminal_state": "ACCEPTED",
                       "scene_state": "scene_accepted",
                       "candidate_version": 2,
                       "accepted_version": 2},
            "new": {"before": {"version": 1, "temp": 23, "note": ""},
                    "after": {"version": 2, "temp": 22, "note": ""},
                    "begin": {"pid": "123", "epoch": 43, "action": 37},
                    "terminal": {"pid": "123", "epoch": 43, "action": 39}},
        }

    def test_exact_positive_old_zero_and_new_down_pass(self):
        self.assertEqual(probe.evaluate(self.evidence())["status"], "pass")

    def test_old_end_before_candidate_acceptance_is_not_observed(self):
        evidence = self.evidence()
        evidence["rebind"]["terminal_absent_at_acceptance"] = False
        self.assertEqual(probe.evaluate(evidence)["status"], "not_observed")

    def test_no_positive_control_is_not_a_rebind_proof(self):
        evidence = self.evidence()
        evidence["positive"]["after"]["temp"] = 22
        self.assertEqual(probe.evaluate(evidence)["status"], "not_observed")

    def test_old_touch_business_activation_fails(self):
        evidence = self.evidence()
        evidence["rebind"]["after"]["temp"] = 24
        evidence["rebind"]["after"]["version"] = 2
        self.assertEqual(probe.evaluate(evidence)["status"], "fail")

    def test_new_click_must_decrement_exactly_once(self):
        evidence = self.evidence()
        evidence["new"]["after"]["temp"] = 21
        self.assertEqual(probe.evaluate(evidence)["status"], "fail")

    def test_wrong_pid_or_epoch_terminal_does_not_count(self):
        evidence = self.evidence()
        evidence["rebind"]["terminal"]["epoch"] = 99
        self.assertEqual(probe.evaluate(evidence)["status"], "not_observed")

    def test_old_owner_change_without_live_crossing_is_not_proof(self):
        evidence = self.evidence()
        evidence["rebind"]["terminal_absent_at_acceptance"] = False
        evidence["rebind"]["after"] = {"version": 2, "temp": 24, "note": ""}
        self.assertEqual(probe.evaluate(evidence)["status"], "not_observed")

    def test_missing_candidate_version_cannot_equal_missing_accepted_version(self):
        evidence = self.evidence()
        evidence["rebind"]["candidate_version"] = None
        evidence["rebind"]["accepted_version"] = None
        self.assertEqual(probe.evaluate(evidence)["status"], "not_observed")

    def test_same_capture_clock_can_still_record_ordered_begin_end(self):
        evidence = self.evidence()
        evidence["positive"]["begin"]["at_ns"] = 100
        evidence["positive"]["terminal"]["at_ns"] = 100
        self.assertEqual(probe.evaluate(evidence)["status"], "pass")

    def test_duplicate_or_old_begin_is_not_a_fresh_phase(self):
        begin = {"pid": "123", "epoch": 42, "action": 37}
        self.assertIsNone(probe.fresh_begin([begin, begin], {41}))
        self.assertIsNone(probe.fresh_begin([begin], {42}))

    def test_cancel_does_not_count_as_successful_click_terminal(self):
        evidence = self.evidence()
        evidence["new"]["terminal"]["action"] = 40
        self.assertEqual(probe.evaluate(evidence)["status"], "not_observed")

    def test_rebind_candidate_changes_only_action_binding(self):
        v1 = ("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\n"
              "NODE 1 viewport scrollArea\nNODE 2 content vertical\n"
              "NODE 3 trigger action action=TEMP_UP\nNODE 3 editor textInput field=note\nEND\n")
        changed = probe.rebind_candidate(v1)
        self.assertIn("NODE 3 trigger action action=TEMP_DOWN", changed)
        self.assertEqual(changed.replace("action=TEMP_DOWN", "action=TEMP_UP"), v1)
        with self.assertRaises(ValueError):
            probe.rebind_candidate(v1.replace("field=note", "field=eco"))


if __name__ == "__main__":
    unittest.main()
