#!/usr/bin/env python3
"""Measure normal CJGUI consumers without creating a second runtime.

Normal mode launches the existing rule-set/document bundles through their
ordinary public descriptor.  Internal nanosecond timings are consumed only
when the app-owned ``WINDOW_WORK_TIMING_NS`` diagnostic is present.  The old
millisecond projection is retained as a separate, visibly quantized consumer
projection and is never promoted to an internal nanosecond stage sample.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from typing import Any, Callable


SCRIPT = Path(__file__).resolve()
RUNTIME = SCRIPT.parents[2]
EXAMPLES = RUNTIME / "examples"
BASELINE_PATH = EXAMPLES / "window_perf_baseline.py"
RULE_APP = EXAMPLES / "rule_set_window_app" / "target" / "release" / "CJGUIRuleSet.app" / "Contents" / "MacOS" / "CJGUIRuleSet"
DOCUMENT_APP = EXAMPLES / "shared_document_window_app" / "target" / "release" / "CJGUISharedDocument.app" / "Contents" / "MacOS" / "CJGUISharedDocument"
SCHEMA = "cjgui_complex_scene_performance_v1"
STAGES = ("build", "identity_reference", "candidate_clone", "layout", "measure", "native_staging_submission")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_baseline() -> Any:
    spec = importlib.util.spec_from_file_location("cjgui_window_perf_baseline", BASELINE_PATH)
    require(spec is not None and spec.loader is not None, f"cannot load baseline: {BASELINE_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def percentile(values: list[int], fraction: float) -> int | None:
    if not values:
        return None
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, int((len(ordered) - 1) * fraction))]


def stage_summary(values: list[int], *, precision: str, observability: str = "normal_window_projection") -> dict[str, Any]:
    return {
        "valid_samples": len(values),
        "p50_ns": percentile(values, 0.50),
        "p95_ns": percentile(values, 0.95),
        "work_units": len(values),
        "clock": "mach_continuous_time_via_app_MonoTime" if precision == "app_ns" else "derived_from_app_ms_projection",
        "precision": precision,
        "observability": observability,
    }


def empty_stage_summary() -> dict[str, Any]:
    return stage_summary([], precision="not_observed", observability="not_exposed_by_normal_public_projection")


def parse_timing(progress: dict[str, str | int] | None) -> tuple[dict[str, int], dict[str, Any]]:
    """Parse the fixed app-owned ns keys, with a quantized legacy fallback."""

    if not progress:
        return {}, {"raw": None, "reason": "no_window_progress_observed"}
    raw_ns = progress.get("WINDOW_WORK_TIMING_NS")
    if isinstance(raw_ns, str):
        raw = {}
        for token in raw_ns.split():
            if "=" in token:
                key, value = token.split("=", 1)
                try:
                    raw[key] = int(value)
                except ValueError:
                    continue
        aliases = {
            "build_ns": ("build_ns",),
            "identity_resolution_ns": ("identity_resolution_ns", "identity_ns"),
            "candidate_clone_ns": ("candidate_clone_ns", "clone_ns"),
            "layout_ns": ("layout_ns",),
            "native_stage_submit_ns": ("native_stage_submit_ns", "stage_submit_ns"),
        }
        resolved = {
            canonical: next((raw[key] for key in names if key in raw), -1)
            for canonical, names in aliases.items()
        }
        required = set(resolved)
        if all(any(key in raw for key in names) for names in aliases.values()) and all(resolved[key] >= -1 for key in required):
            result = {
                "build": resolved["build_ns"],
                "identity_reference": resolved["identity_resolution_ns"],
                "candidate_clone": resolved["candidate_clone_ns"],
                "layout": resolved["layout_ns"],
                "native_staging_submission": resolved["native_stage_submit_ns"],
            }
            # Native measurement remains a separate legacy projection until a
            # future snapshot key exists; never subtract or infer it.
            return {key: value for key, value in result.items() if value >= 0}, {"raw": raw, "precision": "app_ns"}
        return {}, {"raw": raw, "reason": "incomplete_ns_field_shape"}
    raw_ms = progress.get("WINDOW_WORK_TIMING_MS")
    if isinstance(raw_ms, str) and len(raw_ms.split()) == 4:
        try:
            values = [int(part) for part in raw_ms.split()]
        except ValueError:
            values = []
        if values and all(value >= 0 for value in values):
            return {}, {
                "raw": values,
                "precision": "app_ms_projection",
                "projection_ms": {
                    "build": values[0],
                    "layout": values[1],
                    "measure": values[2],
                    "native_staging_submission": values[3],
                },
                "resolution_ms": 1,
            }
    return {}, {"raw": None, "reason": "timing_field_unavailable"}


def cycle_sample(result: dict[str, Any], wrapper_elapsed_ns: int) -> dict[str, Any]:
    progress = result.get("window_progress_from_read_only_get")
    timings, metadata = parse_timing(progress)
    return {
        "name": result.get("name"),
        "wrapper_elapsed_ns": wrapper_elapsed_ns,
        "timing": timings,
        "timing_meta": metadata,
        "timing_projection_ms": metadata.get("projection_ms"),
        "work_counts": progress.get("WINDOW_WORK_COUNTS") if isinstance(progress, dict) else None,
        "layout_reuse": progress.get("WINDOW_LAYOUT_REUSE") if isinstance(progress, dict) else None,
        "refresh_pending": progress.get("WINDOW_REFRESH_PENDING") if isinstance(progress, dict) else None,
        "business_workload": result.get("business_workload"),
        "business_recovery": result.get("business_recovery"),
    }


def stage_samples(samples: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    values: dict[str, list[int]] = defaultdict(list)
    precisions: dict[str, set[str]] = defaultdict(set)
    for sample in samples:
        for stage, value in sample.get("timing", {}).items():
            if stage in STAGES and isinstance(value, int) and value >= 0:
                values[stage].append(value)
                precisions[stage].add(sample.get("timing_meta", {}).get("precision", "not_observed"))
    output: dict[str, dict[str, Any]] = {}
    for stage in STAGES:
        if values[stage]:
            precision = "app_ns" if precisions[stage] == {"app_ns"} else "derived_from_app_ms_projection"
            output[stage] = stage_summary(values[stage], precision=precision)
        else:
            output[stage] = empty_stage_summary()
    return output


def projection_ms(samples: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    """Summarize the legacy app-ms projection without relabeling it as ns."""

    values: dict[str, list[int]] = defaultdict(list)
    for sample in samples:
        projection = sample.get("timing_projection_ms")
        if not isinstance(projection, dict):
            continue
        for stage, value in projection.items():
            if stage in STAGES and isinstance(value, int) and value >= 0:
                values[stage].append(value)
    return {
        stage: {
            "valid_samples": len(values[stage]),
            "p50_ms": percentile(values[stage], 0.50),
            "p95_ms": percentile(values[stage], 0.95),
            "work_units": len(values[stage]),
            "clock": "app_reported_ms",
            "precision": "1ms_quantized_projection",
            "resolution_ms": 1,
            "observability": "normal_window_projection_only",
        }
        for stage in STAGES
    }


def result_applied(baseline: Any, response: Any, action: str) -> int:
    baseline.require(response.kind == "RESULT", f"{action} returned {response.kind}")
    baseline.require(response.boolean("APPLIED"), f"{action} rejected: {response.value('REASON')}")
    return response.integer("VERSION_AFTER")


def request_arg(public_client: Any, name: str, value: str) -> Any:
    return public_client.SharedOperationArgument.string(name, value)


def run_dynamic_insert_delete(baseline: Any, client: Any, count: int) -> dict[str, Any]:
    initial = client.get_context(timeout_seconds=2.0)
    version = initial.integer("VERSION")
    containers = baseline.resource_ids_with_field(initial, "recordCount")
    baseline.require(len(containers) == 1, f"expected one rule container, got {containers}")
    container_id = containers[0]
    for index in range(count):
        response = client.invoke(
            version,
            "CREATE_RECORD",
            [container_id],
            [
                request_arg(baseline.public_client, "label", f"complex-dynamic-{index:04d}"),
                baseline.public_client.SharedOperationArgument.boolean("enabled", False),
                baseline.public_client.SharedOperationArgument.integer("retentionCount", 7),
                request_arg(baseline.public_client, "excludedType", "perf"),
                request_arg(baseline.public_client, "requestId", f"complex-create-{index:04d}"),
            ],
        )
        version = result_applied(baseline, response, "CREATE_RECORD")
    snapshot = client.get_context(timeout_seconds=2.0)
    ids = [resource_id for resource_id in baseline.resource_ids_with_field(snapshot, "enabled") if resource_id != container_id]
    baseline.require(len(ids) >= count, f"created {count} records but found {len(ids)}")
    stale_version = snapshot.integer("VERSION")
    delete_ids = ids[-max(1, count // 4):]
    for index, resource_id in enumerate(delete_ids):
        response = client.invoke(version, "DELETE_RECORD", [resource_id], [request_arg(baseline.public_client, "requestId", f"complex-delete-{index:04d}")])
        version = result_applied(baseline, response, "DELETE_RECORD")
    stale = client.invoke(stale_version, "DELETE_RECORD", [ids[0]], [request_arg(baseline.public_client, "requestId", "complex-stale-delete")])
    selected = client.invoke(version, "SELECT_RECORD", [ids[0]], [request_arg(baseline.public_client, "requestId", "complex-select-after-churn")])
    version = result_applied(baseline, selected, "SELECT_RECORD")
    final_snapshot = client.get_context(timeout_seconds=2.0)
    final_ids = [resource_id for resource_id in baseline.resource_ids_with_field(final_snapshot, "enabled") if resource_id != container_id]
    baseline.require(len(final_ids) == len(ids) - len(delete_ids), "dynamic delete count did not converge")
    return {
        "kind": "dynamic_insert_delete",
        "inserted_count": count,
        "deleted_count": len(delete_ids),
        "dynamic_count_converged": True,
        "stale_version_conflict": baseline.result_is_version_conflict(stale),
        "selection_after_churn_applied": True,
        "final_version": version,
    }


def run_global_invalidation(baseline: Any, client: Any) -> dict[str, Any]:
    initial = client.get_context(timeout_seconds=2.0)
    version = initial.integer("VERSION")
    containers = baseline.resource_ids_with_field(initial, "recordCount")
    baseline.require(len(containers) == 1, f"expected one rule container, got {containers}")
    target = containers[0]
    changed = client.invoke(version, "SET_SPLIT_SIZE", [target], [
        baseline.public_client.SharedOperationArgument.integer("value", 540),
        request_arg(baseline.public_client, "requestId", "complex-global-invalidation"),
    ])
    after = result_applied(baseline, changed, "SET_SPLIT_SIZE")
    stale = client.invoke(version, "SET_SPLIT_SIZE", [target], [
        baseline.public_client.SharedOperationArgument.integer("value", 560),
        request_arg(baseline.public_client, "requestId", "complex-global-stale"),
    ])
    return {"kind": "global_invalidation", "set_split_size_applied": True, "version_after": after, "stale_version_conflict": baseline.result_is_version_conflict(stale)}


def run_reject_recovery(baseline: Any, client: Any) -> dict[str, Any]:
    initial = client.get_context(timeout_seconds=2.0)
    version = initial.integer("VERSION")
    containers = baseline.resource_ids_with_field(initial, "recordCount")
    baseline.require(len(containers) == 1, f"expected one rule container, got {containers}")
    target = containers[0]
    rejected = client.invoke(version, "SET_SPLIT_SIZE", [target], [
        baseline.public_client.SharedOperationArgument.integer("value", 99),
        request_arg(baseline.public_client, "requestId", "complex-invalid-split"),
    ])
    accepted = client.invoke(version, "SET_SPLIT_SIZE", [target], [
        baseline.public_client.SharedOperationArgument.integer("value", 520),
        request_arg(baseline.public_client, "requestId", "complex-recovery-split"),
    ])
    version_after = result_applied(baseline, accepted, "SET_SPLIT_SIZE")
    return {"kind": "reject_recovery", "invalid_rejected": rejected.kind == "RESULT" and not rejected.boolean("APPLIED"), "invalid_reason": rejected.value("REASON"), "recovery_applied": True, "version_after": version_after}


def synthetic_contract_report(output: Path) -> None:
    stages: dict[str, dict[str, Any]] = {}
    for index, stage in enumerate(STAGES):
        stages[stage] = empty_stage_summary() if stage in {"identity_reference", "candidate_clone"} else stage_summary([1000 + index] * 30, precision="app_ns")
    output.write_text(json.dumps({
        "schema": SCHEMA,
        "measurement_clock": "mach_continuous_time_via_app_MonoTime",
        "stage_samples_ns": stages,
        "source_fingerprint": {"probe": sha256(SCRIPT)},
        "binary_fingerprint": {"normal_bundles": "not_started_in_contract_fixture"},
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def normal_report(arguments: argparse.Namespace, output: Path) -> None:
    baseline = load_baseline()
    for executable in (RULE_APP, DOCUMENT_APP):
        require(executable.is_file(), f"normal bundle unavailable: {executable}; build normal consumers first")
    raw_root = Path(arguments.raw_root) if arguments.raw_root else Path(tempfile.mkdtemp(prefix="cjgui-complex-scene-performance.", dir="/private/tmp"))
    raw_root.mkdir(parents=True, exist_ok=True)
    scenario_samples: dict[str, list[dict[str, Any]]] = defaultdict(list)
    scenario_results: dict[str, list[dict[str, Any]]] = defaultdict(list)

    def run_many(name: str, rounds: int, runner: Callable[[int], dict[str, Any]]) -> None:
        for index in range(rounds):
            started_ns = time.monotonic_ns()
            result = runner(index)
            wrapper_elapsed_ns = time.monotonic_ns() - started_ns
            scenario_results[name].append(result)
            scenario_samples[name].append(cycle_sample(result, wrapper_elapsed_ns))

    common = {"duration_s": arguments.duration_seconds, "warmup_s": arguments.warmup_seconds, "sample_s": arguments.sample_seconds}
    for label, count in (("small", 16), ("medium", 64), ("large", 256)):
        scenario = f"rule_local_field_change_{label}"
        run_many(scenario, arguments.rounds, lambda index, count=count, scenario=scenario: baseline.run_cycle(
            f"{scenario}_round_{index + 1}", RULE_APP, [], **common, requires_descriptor=True, repeated_public_get=True,
            business_workload=lambda client, count=count: baseline.run_rule_set_fixture_batch(client, count), public_get_interval_s=0.05,
        ))
    run_many("dynamic_insert_delete", arguments.rounds, lambda index: baseline.run_cycle(
        f"dynamic_insert_delete_round_{index + 1}", RULE_APP, [], **common, requires_descriptor=True, repeated_public_get=True,
        business_workload=lambda client: run_dynamic_insert_delete(baseline, client, 32), public_get_interval_s=0.05,
    ))
    run_many("global_invalidation", arguments.rounds, lambda index: baseline.run_cycle(
        f"global_invalidation_round_{index + 1}", RULE_APP, [], **common, requires_descriptor=True, repeated_public_get=True,
        business_workload=lambda client: run_global_invalidation(baseline, client), public_get_interval_s=0.05,
    ))
    run_many("reject_recovery", arguments.rounds, lambda index: baseline.run_cycle(
        f"reject_recovery_round_{index + 1}", RULE_APP, [], **common, requires_descriptor=True, repeated_public_get=True,
        business_workload=lambda client: run_reject_recovery(baseline, client), public_get_interval_s=0.05,
    ))
    run_many("document_local_edit", arguments.rounds, lambda index: baseline.run_cycle(
        f"document_local_edit_round_{index + 1}", DOCUMENT_APP, ["--with-connection"], **common, requires_descriptor=True, repeated_public_get=True,
        business_workload=baseline.run_document_edit_workload, public_get_interval_s=0.05,
    ))
    run_many("no_change_idle", arguments.rounds, lambda index: baseline.run_cycle(
        f"no_change_idle_round_{index + 1}", DOCUMENT_APP, ["--with-connection"], **common, requires_descriptor=True, repeated_public_get=True,
        business_workload=None, public_get_interval_s=0.05,
    ))

    for name, results in scenario_results.items():
        (raw_root / f"{name}.json").write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    all_samples = [sample for samples in scenario_samples.values() for sample in samples]
    source_files = [RUNTIME / "src" / "composable_ui_window.cj", RUNTIME / "src" / "composable_ui_animation.cj", RUNTIME / "src" / "composable_ui.cj", RUNTIME / "native" / "cjgui_internal_renderer.m", BASELINE_PATH, SCRIPT]
    source_fingerprint = {str(path.relative_to(RUNTIME)): sha256(path) for path in source_files}
    binary_fingerprint = {"rule_executable_sha256": sha256(RULE_APP), "document_executable_sha256": sha256(DOCUMENT_APP), "rule_executable": str(RULE_APP), "document_executable": str(DOCUMENT_APP)}
    report = {
        "schema": SCHEMA,
        "captured_at_unix_s": time.time(),
        "measurement_clock": "wrapper_time.monotonic_ns_plus_app_MonoTime_when_WINDOW_WORK_TIMING_NS_is_present",
        "source_fingerprint": source_fingerprint,
        "binary_fingerprint": binary_fingerprint,
        "configuration": {"rounds_per_condition": arguments.rounds, "duration_seconds": arguments.duration_seconds, "warmup_seconds": arguments.warmup_seconds, "sample_seconds": arguments.sample_seconds, "input_sizes": {"small": 16, "medium": 64, "large": 256}, "same_process_per_sample": True},
        "stage_samples_ns": stage_samples(all_samples),
        "normal_consumer_projection_ms": projection_ms(all_samples),
        "scenarios": {name: {"valid_samples": len(samples), "p50_wrapper_elapsed_ns": percentile([int(sample["wrapper_elapsed_ns"]) for sample in samples], 0.50), "p95_wrapper_elapsed_ns": percentile([int(sample["wrapper_elapsed_ns"]) for sample in samples], 0.95), "stage_samples_ns": stage_samples(samples), "normal_consumer_projection_ms": projection_ms(samples), "raw_artifact": str(raw_root / f"{name}.json")} for name, samples in scenario_samples.items()},
        "coverage": {
            "local_field_change": "rule BATCH_SET_ENABLED plus document REPLACE_RANGE through public CAS",
            "dynamic_insert_delete": "rule CREATE_RECORD/DELETE_RECORD/SELECT_RECORD through public CAS; virtual-list scroll is not externally injectable",
            "popup_toggle": "not_run: normal public authorization exposes no popup/layer action",
            "global_invalidation": "rule SET_SPLIT_SIZE through public CAS",
            "no_change_idle": "repeated GET_CONTEXT/GET_WINDOW_PROGRESS only",
            "reject_and_recovery": "invalid split rejection plus stale-version conflict followed by accepted action",
            "quiescence": "same-process recovery fields and WINDOW_REFRESH_PENDING retained; retained/pending are not total memory",
            "multi_window_fairness": "not_run in this probe; existing controlled logs are reference-only",
        },
        "observability_boundary": {"build": "not_observed_as_internal_ns: normal public progress lacked WINDOW_WORK_TIMING_NS; legacy WINDOW_WORK_TIMING_MS is reported separately", "identity_reference": "not_observed_as_internal_ns: app-owned ns diagnostic only", "candidate_clone": "not_observed_as_internal_ns: app-owned ns diagnostic only", "layout": "not_observed_as_internal_ns: legacy app-ms projection reported separately", "measure": "not_observed_as_internal_ns: legacy app-ms projection reported separately", "native_staging_submission": "not_observed_as_internal_ns: legacy app-ms projection reported separately; no GPU completion or screen presentation", "gpu_and_screen": "not_run/not_claimed"},
        "raw_root": str(raw_root),
        "raw_sample_count": len(all_samples),
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract-fixture", action="store_true")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--raw-root", type=Path)
    parser.add_argument("--rounds", type=int, default=30)
    parser.add_argument("--duration-seconds", type=float, default=1.0)
    parser.add_argument("--warmup-seconds", type=float, default=0.0)
    parser.add_argument("--sample-seconds", type=float, default=0.2)
    arguments = parser.parse_args()
    if arguments.contract_fixture:
        synthetic_contract_report(arguments.output)
        return 0
    require(arguments.rounds >= 30, "at least 30 samples are required per applicable condition")
    require(arguments.duration_seconds >= 1.0, "normal window runner requires at least one second")
    normal_report(arguments, arguments.output)
    print(json.dumps({"report": str(arguments.output), "raw_root": str(arguments.raw_root or "created_by_probe")}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"complex scene performance probe failed: {error}", file=os.sys.stderr)
        raise SystemExit(1)
