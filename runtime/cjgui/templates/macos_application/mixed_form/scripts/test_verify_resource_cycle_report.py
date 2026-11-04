import unittest

from verify_resource_cycle_report import ResourceCycleError, parse_rows, verify_report, verify_rows


def make_log(
    *,
    leak_cycle: int | None = None,
    live_allocation_overflow: bool = False,
    cache_growth: bool = True,
    effect_leak_cycle: int | None = None,
    effect_leak_final: bool = False,
) -> str:
    labels = ["initial"] + [
        label
        for cycle in range(1, 11)
        for label in (f"active-{cycle}", f"drained-{cycle}")
    ] + ["final"]
    lines = []
    for label in labels:
        active = label.startswith("active-")
        cycle = 0 if label == "initial" else 10 if label == "final" else int(label.split("-")[1])
        drained = label.startswith("drained-")
        active_sessions = 2 if active else 1
        committed_refs = 3 if active else 1
        subscribers = 2 if active else 1
        raw_subscribers = 4 if active else 1
        text_live = 640 if active else 320
        effect_live = 4096 if active else 0
        if drained and leak_cycle == int(label.split("-")[1]):
            active_sessions += 1
            committed_refs += 1
            raw_subscribers += 1
            text_live += 512
        cache_entries = min(4, 1 + cycle) if cache_growth else 1
        cache_bytes = cache_entries * 8192
        live_allocations = 3 if active else min(6, 2 + cycle) if cache_growth else 2
        if label == "initial":
            live_allocations = 2
        if live_allocation_overflow and label == "final":
            live_allocations = 11
        global_effect_inflight_targets = int(
            (label == f"drained-{effect_leak_cycle}") or
            (effect_leak_final and label == "final")
        )
        global_effect_inflight_bytes = 16384 if global_effect_inflight_targets else 0
        image_state = "ready"
        values = {
            "label": label,
            "status": 0,
            "schema": 1,
            "active_sessions": active_sessions,
            "cache_entries": cache_entries,
            "cache_bytes": cache_bytes,
            "cache_budget": 33554432,
            "inflight": 0,
            "pending": 0,
            "committed_refs": committed_refs,
            "subscribers": subscribers,
            "records": min(64, 2 + cycle),
            "decode_starts": 2 + cycle,
            "raw_subscribers": raw_subscribers,
            "live_allocations": live_allocations,
            "live_allocation_bytes": live_allocations * 8192,
            "windows": 2 if active else 1,
            "scene": 30 + cycle if active else 10,
            "submitted": 20 + cycle,
            "completed": 20 + cycle,
            "text_live": text_live,
            "reusable": cache_bytes + text_live,
            "effect_live": effect_live,
            "effect_cache": 0,
            "effect_inflight": 0,
            "global_effect_inflight_targets": global_effect_inflight_targets,
            "global_effect_inflight_bytes": global_effect_inflight_bytes,
            "global_effect_scope": "observed_submissions_after_enable",
            "effect_passes": 1,
            "generated_nodes": 8,
            "effect_nodes": 1,
            "scroll": 48 if active else 0,
            "image_state": image_state,
        }
        lines.append(
            "CJGUI_RESOURCE_CYCLE "
            + " ".join(f"{key}={value}" for key, value in values.items())
        )
    return "\n".join(lines + ["CJGUI_RESOURCE_CYCLE_RESULT status=ok"])


class ResourceCycleReportTests(unittest.TestCase):
    def test_accepts_ten_cycles_and_nonzero_bounded_cache(self):
        rows = parse_rows(make_log())
        result = verify_report(make_log())
        self.assertEqual(result["cycles"], 10)
        self.assertGreater(result["max_cache_entries"], 0)
        self.assertGreater(rows[-1]["cache_entries"], rows[0]["cache_entries"])
        self.assertGreater(rows[-1]["live_allocations"], rows[0]["live_allocations"])
        self.assertGreater(rows[-1]["live_allocation_bytes"], rows[0]["live_allocation_bytes"])
        self.assertEqual(result["global_effect_scope"], "observed_submissions_after_enable")
        self.assertEqual(result["max_global_effect_inflight_targets"], 0)
        self.assertEqual(result["max_global_effect_inflight_bytes"], 0)

    def test_rejects_cold_anchor_without_committed_image(self):
        rows = parse_rows(make_log())
        rows[0]["committed_refs"] = 0
        with self.assertRaisesRegex(ResourceCycleError, "ready image lease"):
            verify_rows(rows)

    def test_rejects_anchor_without_completed_warm_frame(self):
        rows = parse_rows(make_log())
        rows[0]["submitted"] = 0
        with self.assertRaisesRegex(ResourceCycleError, "completed frame baseline"):
            verify_rows(rows)

    def test_requires_initial_and_final_to_keep_the_same_warm_scene(self):
        rows = parse_rows(make_log())
        rows[-1]["scene"] += 1
        with self.assertRaisesRegex(ResourceCycleError, "initial/final.*scene"):
            verify_rows(rows)

    def test_report_requires_explicit_success_terminal(self):
        text = make_log().replace("CJGUI_RESOURCE_CYCLE_RESULT status=ok", "")
        with self.assertRaisesRegex(ResourceCycleError, "success terminal"):
            verify_report(text)

    def test_allows_normal_app_close_line_after_resource_result(self):
        self.assertEqual(
            verify_report(make_log() + "\nCJGUI_MIXED_FORM_CLOSED endpoint=cleared")["cycles"],
            10,
        )

    def test_failure_terminal_rejects_even_a_full_row_sequence(self):
        text = make_log().replace(
            "CJGUI_RESOURCE_CYCLE_RESULT status=ok",
            "CJGUI_RESOURCE_CYCLE_FAILURE reason=late_close_refused",
        )
        with self.assertRaisesRegex(ResourceCycleError, "late_close_refused"):
            verify_report(text)

    def test_failed_final_close_rejects_a_complete_workload_report(self):
        text = make_log() + "\nCJGUI_RESOURCE_CYCLE_FAILED reason=anchor_close_refused"
        with self.assertRaisesRegex(ResourceCycleError, "anchor_close_refused"):
            verify_report(text)

    def test_partial_failure_keeps_prior_rows_parseable(self):
        full_rows = make_log().splitlines()
        partial = "\n".join([
            full_rows[0],
            full_rows[1],
            "CJGUI_RESOURCE_CYCLE_FAILURE_SAMPLE reason=image_not_ready label=active-1 status=0",
            "CJGUI_RESOURCE_CYCLE_FAILURE reason=image_not_ready_1",
        ])
        self.assertEqual([row["label"] for row in parse_rows(partial)], ["initial", "active-1"])
        with self.assertRaisesRegex(ResourceCycleError, "image_not_ready_1"):
            verify_report(partial)

    def test_rejects_missing_cycle_row(self):
        text = "\n".join(line for line in make_log().splitlines() if "active-6 " not in line)
        with self.assertRaisesRegex(ResourceCycleError, "ordered rows"):
            verify_rows(parse_rows(text))

    def test_rejects_live_residue_at_each_drain(self):
        with self.assertRaisesRegex(ResourceCycleError, "drained-4.*live state changed"):
            verify_rows(parse_rows(make_log(leak_cycle=4)))

    def test_rejects_global_effect_inflight_residue_at_drain_and_final(self):
        with self.assertRaisesRegex(ResourceCycleError, "drained-4.*global effect in-flight"):
            verify_rows(parse_rows(make_log(effect_leak_cycle=4)))
        with self.assertRaisesRegex(ResourceCycleError, "final.*global effect in-flight"):
            verify_rows(parse_rows(make_log(effect_leak_final=True)))

    def test_rejects_retired_raw_subscriber_residue(self):
        text = make_log(leak_cycle=4)
        rows = parse_rows(text)
        # Keep all actual live facts at baseline while retaining one stale
        # generation entry. This must fail independently of the lease count.
        row = next(item for item in rows if item["label"] == "drained-4")
        row["active_sessions"] = 1
        row["committed_refs"] = 1
        row["text_live"] = 320
        with self.assertRaisesRegex(ResourceCycleError, "drained-4.*raw_subscribers"):
            verify_rows(rows)

    def test_bounds_live_allocations_without_requiring_cache_to_empty(self):
        with self.assertRaisesRegex(ResourceCycleError, "unique live image allocations"):
            verify_rows(parse_rows(make_log(live_allocation_overflow=True)))

    def test_rejects_image_cache_over_budget(self):
        rows = parse_rows(make_log())
        rows[3]["cache_bytes"] = 33554433
        with self.assertRaisesRegex(ResourceCycleError, "byte budget"):
            verify_rows(rows)

    def test_rejects_unaccepted_scroll_or_effect_workload(self):
        rows = parse_rows(make_log())
        rows[1]["scroll"] = 0
        with self.assertRaisesRegex(ResourceCycleError, "workload was not accepted"):
            verify_rows(rows)


if __name__ == "__main__":
    unittest.main()
