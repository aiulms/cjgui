#!/usr/bin/env python3
"""Process-level baseline for normal CJGUI rule-set and document windows.

This runner starts the packaged macOS applications through their ordinary
window entry points.  It samples CPU/RSS and uses only the issued public
descriptor for the two read-only connection scenarios.  It deliberately does
not synthesize AppKit events, claim a visible desktop, or equate a public GET
with physical keyboard/IME input.
"""

from __future__ import annotations

import argparse
from collections import deque
import hashlib
import json
import os
import statistics
import subprocess
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parent
RUNTIME = ROOT.parent
CORE = RUNTIME / "shared_operation_core"
RULE_APP = ROOT / "rule_set_window_app" / "target" / "release" / "CJGUIRuleSet.app" / "Contents" / "MacOS" / "CJGUIRuleSet"
DOCUMENT_APP = ROOT / "shared_document_window_app" / "target" / "release" / "CJGUISharedDocument.app" / "Contents" / "MacOS" / "CJGUISharedDocument"

import sys

sys.path.insert(0, os.fspath(CORE))
import client as public_client  # noqa: E402


WINDOW_READY_MARKERS = frozenset({"CJGUI_RULE_SET_READY", "CJGUI_SHARED_DOCUMENT_READY"})


@dataclass(frozen=True)
class WindowReadySignal:
    """The normal app started a native window and submitted its first frame.

    It is deliberately not an assertion that the desktop made pixels visible
    to a person or that an IME received physical input.
    """

    marker: str
    session_identity: str
    submitted_frame_index: int


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def process_sample(pid: int, elapsed_s: float) -> dict[str, float | int]:
    completed = subprocess.run(
        ["ps", "-o", "%cpu=,rss=", "-p", str(pid)],
        text=True,
        capture_output=True,
        check=False,
    )
    fields = completed.stdout.split()
    require(len(fields) == 2, f"cannot sample window process {pid}: {completed.stderr.strip()!r}")
    threads = subprocess.run(["ps", "-M", "-o", "pid=", "-p", str(pid)], text=True, capture_output=True, check=False)
    thread_count = len(threads.stdout.split())
    require(thread_count > 0, f"cannot count window threads for {pid}: {threads.stderr.strip()!r}")
    return {
        "elapsed_s": round(elapsed_s, 3),
        "cpu_percent": float(fields[0]),
        "rss_kib": int(fields[1]),
        "threads": thread_count,
    }


def is_live_process_sample(sample: dict[str, float | int]) -> bool:
    """Reject `ps`'s zeroed final record when a child exits during sampling."""

    return int(sample["rss_kib"]) > 0 and int(sample["threads"]) > 0


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    return round(ordered[min(len(ordered) - 1, int((len(ordered) - 1) * fraction))], 3)


def trend(samples: list[dict[str, float | int]], name: str) -> dict[str, float | int]:
    values = [float(sample[name]) for sample in samples]
    require(values, f"no {name} samples")
    return {
        "first": values[0],
        "last": values[-1],
        "min": min(values),
        "max": max(values),
        "delta": round(values[-1] - values[0], 3),
    }


def lifecycle_timings(launched_at: float, ready_at: float, measurement_started_at: float) -> dict[str, float]:
    """Keep startup, submitted-window readiness, and warmup as separate facts."""

    require(launched_at <= ready_at <= measurement_started_at, "window lifecycle times are not monotonic")
    return {
        "startup_to_ready_s": round(ready_at - launched_at, 3),
        "ready_to_measurement_start_s": round(measurement_started_at - ready_at, 3),
    }


def business_recovery(
    samples: list[dict[str, float | int]], business_finished_elapsed_s: float,
) -> dict[str, float | int | bool | dict[str, float | int]]:
    """Describe only the post-work interval observed in the same window process."""

    post_work_samples = [sample for sample in samples if float(sample["elapsed_s"]) >= business_finished_elapsed_s]
    require(post_work_samples, "business workload completed without a sampled same-process recovery interval")
    return {
        "same_process": True,
        "business_finished_elapsed_s": round(business_finished_elapsed_s, 3),
        "post_work_observed_s": round(float(post_work_samples[-1]["elapsed_s"]) - business_finished_elapsed_s, 3),
        "sample_count": len(post_work_samples),
        "cpu_percent": trend(post_work_samples, "cpu_percent"),
        "rss_kib": trend(post_work_samples, "rss_kib"),
        "threads": trend(post_work_samples, "threads"),
    }


def ready_descriptor(lines: list[str]) -> Path | None:
    for line in lines:
        if " DESCRIPTOR_PATH " not in line:
            continue
        prefix, path = line.split(" DESCRIPTOR_PATH ", 1)
        if prefix in {"CJGUI_RULE_SET_READY", "CJGUI_SHARED_DOCUMENT_READY"} and path:
            return Path(path)
    return None


def window_ready_signal(lines: list[str]) -> WindowReadySignal | None:
    """Find one valid submitted-window marker from normal app stdout."""

    for line in lines:
        parts = line.split(" ")
        if len(parts) != 4 or parts[0] not in WINDOW_READY_MARKERS or parts[1] != "WINDOW_READY":
            continue
        try:
            submitted_frame_index = int(parts[3])
        except ValueError:
            continue
        if parts[2] and submitted_frame_index > 0:
            return WindowReadySignal(parts[0], parts[2], submitted_frame_index)
    return None


def measurement_start_signal(lines: list[str], ready: WindowReadySignal) -> WindowReadySignal | None:
    """Accept only this ready window's explicit warmup-complete marker."""

    expected = f"{ready.marker} MEASUREMENT_START {ready.session_identity}"
    return ready if expected in lines else None


def window_progress(response: public_client.SharedOperationResponse) -> dict[str, str | int]:
    fields = (
        "WINDOW_SESSION",
        "WINDOW_ACCEPTED_SCENE_VERSION",
        "WINDOW_SUBMITTED_SCENE_VERSION",
        "WINDOW_SUBMITTED_FRAME_INDEX",
        "WINDOW_METAL_COMPLETED_FRAME_INDEX",
        "WINDOW_METAL_FAILED_FRAME_INDEX",
        "WINDOW_METAL_GPU_DURATION_MICROS",
        "WINDOW_OVERLAY_DRAWN_SCENE_VERSION",
        "WINDOW_INTERACTION_VERSION",
        "WINDOW_FOCUS",
        "WINDOW_SELECTION",
        "WINDOW_ACTIVE_LAYER",
        "WINDOW_WORK_COUNTS",
        "WINDOW_WORK_TIMING_MS",
        "WINDOW_MEASUREMENT_CALL_COUNT",
        "WINDOW_LAYOUT_REUSE",
    )
    result: dict[str, str | int] = {}
    for field in fields:
        values = response.values(field)
        if not values:
            continue
        result[field] = " ".join(values[0])
    return result


def resource_ids_with_field(response: public_client.SharedOperationResponse, field_name: str) -> list[int]:
    """Discover resource identities from the protocol snapshot, never source IDs."""

    result: list[int] = []
    for values in response.values("FIELD"):
        if len(values) >= 2 and values[1] == field_name:
            try:
                resource_id = int(values[0])
            except ValueError as error:
                raise RuntimeError(f"invalid resource id for {field_name}") from error
            if resource_id not in result:
                result.append(resource_id)
    return result


def field_value(response: public_client.SharedOperationResponse, resource_id: int, field_name: str) -> tuple[str, ...]:
    for values in response.values("FIELD"):
        if len(values) >= 3 and values[0] == str(resource_id) and values[1] == field_name:
            return values[2:]
    raise RuntimeError(f"missing {field_name} for resource {resource_id}")


def snapshot_frame_index(response: public_client.SharedOperationResponse) -> int:
    require(response.kind == "SNAPSHOT", f"expected snapshot, received {response.kind}")
    return response.integer("WINDOW_SUBMITTED_FRAME_INDEX")


def progress_frame_index(response: public_client.SharedOperationResponse) -> int:
    require(response.kind == "WINDOW_PROGRESS", f"expected narrow progress, received {response.kind}")
    return response.integer("WINDOW_SUBMITTED_FRAME_INDEX")


def result_applied(response: public_client.SharedOperationResponse, action: str) -> int:
    require(response.kind == "RESULT", f"{action} returned {response.kind}, not RESULT")
    require(response.boolean("APPLIED"), f"{action} was rejected: {response.value('REASON')}")
    return response.integer("VERSION_AFTER")


def result_is_version_conflict(response: public_client.SharedOperationResponse) -> bool:
    return response.kind == "RESULT" and not response.boolean("APPLIED") and response.boolean("CONFLICT") and response.value("REASON") == ("version_conflict",)


def await_completed_frame(
    client: public_client.SharedOperationClient,
    submitted_before_work: int,
    *,
    timeout_s: float = 5.0,
) -> tuple[public_client.SharedOperationResponse, int]:
    """Observe a later real submission and its actual Metal terminal result."""

    deadline = time.monotonic() + timeout_s
    last: public_client.SharedOperationResponse | None = None
    while time.monotonic() < deadline:
        response = client.get_window_progress(timeout_seconds=min(1.0, max(0.05, deadline - time.monotonic())))
        last = response
        submitted = progress_frame_index(response)
        completed = response.integer("WINDOW_METAL_COMPLETED_FRAME_INDEX")
        failed = response.integer("WINDOW_METAL_FAILED_FRAME_INDEX")
        if submitted > submitted_before_work:
            if completed >= submitted:
                return response, submitted
            if failed >= submitted:
                raise RuntimeError(f"new frame {submitted} reported Metal failure")
        time.sleep(0.03)
    detail = window_progress(last) if last is not None else {}
    raise RuntimeError(f"no completed frame after business work: {detail}")


def run_rule_set_fixture_batch(
    client: public_client.SharedOperationClient,
    fixture_record_count: int,
) -> dict[str, Any]:
    """Create a disposable 1,001-item-style fixture, batch it, and read it back."""

    initial = client.get_context(timeout_seconds=2.0)
    version = initial.integer("VERSION")
    frame_before = snapshot_frame_index(initial)
    containers = resource_ids_with_field(initial, "recordCount")
    require(len(containers) == 1, f"expected one rule-set container, got {containers}")
    container_id = containers[0]
    started = time.monotonic()
    for index in range(fixture_record_count):
        response = client.invoke(
            version,
            "CREATE_RECORD",
            [container_id],
            [
                public_client.SharedOperationArgument.string("label", f"baseline-fixture-{index:04d}"),
                public_client.SharedOperationArgument.boolean("enabled", False),
                public_client.SharedOperationArgument.integer("retentionCount", 30),
                public_client.SharedOperationArgument.string("excludedType", "baseline"),
                public_client.SharedOperationArgument.string("requestId", f"baseline-create-{index:04d}"),
            ],
        )
        version = result_applied(response, "CREATE_RECORD")
    fixture_elapsed_ms = round((time.monotonic() - started) * 1_000, 3)
    fixture_snapshot = client.get_context(timeout_seconds=2.0)
    record_ids = [resource_id for resource_id in resource_ids_with_field(fixture_snapshot, "enabled") if resource_id != container_id]
    require(len(record_ids) >= fixture_record_count, f"fixture discovery returned {len(record_ids)} records")
    batch_ids = record_ids[: min(100, fixture_record_count)]
    batch_version = fixture_snapshot.integer("VERSION")
    batch = client.invoke(
        batch_version,
        "BATCH_SET_ENABLED",
        batch_ids,
        [
            public_client.SharedOperationArgument.boolean("enabled", True),
            public_client.SharedOperationArgument.string("requestId", "baseline-batch-enabled"),
        ],
    )
    version_after_batch = result_applied(batch, "BATCH_SET_ENABLED")
    stale = client.invoke(
        batch_version,
        "BATCH_SET_ENABLED",
        batch_ids,
        [
            public_client.SharedOperationArgument.boolean("enabled", False),
            public_client.SharedOperationArgument.string("requestId", "baseline-batch-stale"),
        ],
    )
    readback = client.get_context(batch_ids, timeout_seconds=2.0)
    all_enabled = all(field_value(readback, resource_id, "enabled") == ("BOOLEAN", "1") for resource_id in batch_ids)
    # Leave a sparse, target-1 update after the wide batch so the incremental
    # observer has an actual one-resource change to detect under the same load.
    time.sleep(0.25)
    sparse_target_id = batch_ids[0]
    sparse = client.invoke(
        version_after_batch,
        "BATCH_SET_ENABLED",
        [sparse_target_id],
        [
            public_client.SharedOperationArgument.boolean("enabled", False),
            public_client.SharedOperationArgument.string("requestId", "baseline-sparse-target-change"),
        ],
    )
    version_after_sparse = result_applied(sparse, "BATCH_SET_ENABLED")
    sparse_readback = client.get_context((sparse_target_id,), timeout_seconds=2.0)
    sparse_target_disabled = field_value(sparse_readback, sparse_target_id, "enabled") == ("BOOLEAN", "0")
    completed_progress, frame_after = await_completed_frame(client, frame_before)
    completed_snapshot = client.get_context(timeout_seconds=2.0)
    require(completed_snapshot.kind == "SNAPSHOT", "rule fixture completion snapshot was unavailable")
    return {
        "kind": "rule_set_fixture_batch",
        "fixture_record_count": fixture_record_count,
        "fixture_elapsed_ms": fixture_elapsed_ms,
        "batch_target_count": len(batch_ids),
        "batch_applied": True,
        "version_after_batch": version_after_batch,
        "stale_version_conflict": result_is_version_conflict(stale),
        "readback_all_enabled": all_enabled,
        "sparse_target_resource_id": sparse_target_id,
        "version_after_sparse_target_change": version_after_sparse,
        "sparse_target_change_applied": True,
        "sparse_target_readback_disabled": sparse_target_disabled,
        "frame_progress_before_work": frame_before,
        "frame_progress_after_work": frame_after,
        "completed_window_progress": window_progress(completed_snapshot),
        "completed_frame_progress": window_progress(completed_progress),
    }


def run_document_edit_workload(client: public_client.SharedOperationClient) -> dict[str, Any]:
    """Apply and read back an authorized document replacement plus stale CAS."""

    initial = client.get_context(timeout_seconds=2.0)
    version = initial.integer("VERSION")
    frame_before = snapshot_frame_index(initial)
    editable_documents = resource_ids_with_field(initial, "byteLength")
    require(editable_documents, "document snapshot did not expose byteLength resources")
    document_id = editable_documents[0]
    byte_length = field_value(initial, document_id, "byteLength")
    require(byte_length[0] == "INTEGER", "document byteLength has the wrong public type")
    offset = int(byte_length[1])
    replacement_text = "[baseline-document-edit]"
    replacement = client.invoke(
        version,
        "REPLACE_RANGE",
        [document_id],
        [
            public_client.SharedOperationArgument.integer("start", offset),
            public_client.SharedOperationArgument.integer("end", offset),
            public_client.SharedOperationArgument.string("text", replacement_text),
        ],
    )
    version_after_replace = result_applied(replacement, "REPLACE_RANGE")
    stale = client.invoke(
        version,
        "REPLACE_RANGE",
        [document_id],
        [
            public_client.SharedOperationArgument.integer("start", offset),
            public_client.SharedOperationArgument.integer("end", offset),
            public_client.SharedOperationArgument.string("text", "[stale]"),
        ],
    )
    readback = client.read_range(document_id, offset, offset + len(replacement_text.encode("utf-8")), version_after_replace)
    require(readback.kind == "RANGE" and readback.boolean("AVAILABLE"), "document range readback was unavailable")
    completed_progress, frame_after = await_completed_frame(client, frame_before)
    completed_snapshot = client.get_context(timeout_seconds=2.0)
    require(completed_snapshot.kind == "SNAPSHOT", "document completion snapshot was unavailable")
    return {
        "kind": "document_edit",
        "resource_id": document_id,
        "replace_applied": True,
        "version_after_replace": version_after_replace,
        "stale_version_conflict": result_is_version_conflict(stale),
        "range_readback_matches": readback.text("CONTENT_UTF8_HEX") == replacement_text,
        "frame_progress_before_work": frame_before,
        "frame_progress_after_work": frame_after,
        "completed_window_progress": window_progress(completed_snapshot),
        "completed_frame_progress": window_progress(completed_progress),
    }


def run_cycle(
    name: str,
    executable: Path,
    app_args: list[str],
    duration_s: float,
    warmup_s: float,
    sample_s: float,
    requires_descriptor: bool,
    repeated_public_get: bool,
    business_workload: Callable[[public_client.SharedOperationClient], dict[str, Any]] | None = None,
    public_get_interval_s: float = 0.1,
    public_read_mode: str = "full",
    public_targets: tuple[int, ...] = (),
) -> dict[str, Any]:
    require(executable.is_file(), f"normal app bundle is unavailable: {executable}")
    require(public_get_interval_s > 0, "public GET interval must be positive")
    require(public_read_mode in {"full", "targeted", "observation"}, "unknown public read mode")
    if public_read_mode == "targeted":
        require(public_targets, "targeted public read needs at least one resource")
    duration_ms = max(1, round(duration_s * 1000))
    warmup_ms = max(0, round(warmup_s * 1000))
    process = subprocess.Popen(
        [
            os.fspath(executable),
            *app_args,
            "--measurement-warmup-ms",
            str(warmup_ms),
            "--measurement-duration-ms",
            str(duration_ms),
        ],
        cwd=executable.parent,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert process.stdout is not None
    assert process.stderr is not None
    stdout_lines: list[str] = []
    stdout_lock = threading.Lock()
    stderr_tail_chunks: deque[str] = deque()
    stderr_tail_size = 0
    stderr_lock = threading.Lock()

    def read_stdout() -> None:
        for raw in process.stdout:
            with stdout_lock:
                stdout_lines.append(raw.strip())

    reader = threading.Thread(target=read_stdout, daemon=True)
    reader.start()

    def read_stderr() -> None:
        nonlocal stderr_tail_size
        while True:
            chunk = process.stderr.read(4096)
            if not chunk:
                return
            with stderr_lock:
                stderr_tail_chunks.append(chunk)
                stderr_tail_size += len(chunk)
                while stderr_tail_size > 64 * 1024:
                    stderr_tail_size -= len(stderr_tail_chunks.popleft())

    stderr_reader = threading.Thread(target=read_stderr, daemon=True)
    stderr_reader.start()
    launched = time.monotonic()
    descriptor_path: Path | None = None
    descriptor: dict[str, object] | None = None
    ready: WindowReadySignal | None = None
    ready_observed_at: float | None = None
    readiness_deadline = launched + 30.0
    while time.monotonic() < readiness_deadline and process.poll() is None:
        with stdout_lock:
            ready = window_ready_signal(stdout_lines)
            candidate = ready_descriptor(stdout_lines)
        if candidate is not None:
            descriptor_path = candidate
            descriptor = public_client.parse_descriptor(candidate)
        if ready is not None and (not requires_descriptor or descriptor is not None):
            ready_observed_at = time.monotonic()
            break
        time.sleep(0.01)
    require(ready is not None, f"{name} did not issue an initial submitted-window readiness signal")
    require(ready_observed_at is not None, f"{name} did not observe its submitted-window readiness signal")
    if requires_descriptor:
        require(descriptor is not None, f"{name} did not issue a normal public descriptor")

    measurement_started: float | None = None
    measurement_deadline = time.monotonic() + warmup_s + 30.0
    while time.monotonic() < measurement_deadline and process.poll() is None:
        with stdout_lock:
            warmed = measurement_start_signal(stdout_lines, ready)
        if warmed is not None:
            measurement_started = time.monotonic()
            break
        time.sleep(0.01)
    require(measurement_started is not None, f"{name} did not complete its explicit warmup")

    latencies_ms: list[float] = []
    response_bytes: list[int] = []
    outcomes: dict[str, int] = {}
    final_progress: dict[str, str | int] | None = None
    workload_stop = threading.Event()

    def request_loop() -> None:
        nonlocal final_progress
        assert descriptor is not None
        connection = public_client.SharedOperationClient(descriptor)
        observer = public_client.SharedOperationObserver(connection, public_targets) if public_read_mode == "observation" else None
        # The comparison intentionally targets the first fixture record.  Give
        # the concurrent fixture its bounded head start so the baseline
        # measures a real target read, rather than repeatedly sampling the
        # documented unknown-target error before that record exists.
        if public_read_mode in {"targeted", "observation"}:
            workload_stop.wait(0.5)
        while not workload_stop.is_set() and process.poll() is None:
            request_started = time.monotonic()
            try:
                if public_read_mode == "full":
                    response = connection.get_context(timeout_seconds=1.0)
                    outcome = "snapshot" if response.kind == "SNAPSHOT" else f"remote_{response.kind.lower()}"
                    response_bytes.append(len(response.raw.encode("utf-8")))
                    if response.kind == "SNAPSHOT":
                        final_progress = window_progress(response)
                elif public_read_mode == "targeted":
                    response = connection.get_context(public_targets, timeout_seconds=1.0)
                    outcome = "targeted_snapshot" if response.kind == "SNAPSHOT" else f"remote_{response.kind.lower()}"
                    response_bytes.append(len(response.raw.encode("utf-8")))
                    if response.kind == "SNAPSHOT":
                        final_progress = window_progress(response)
                else:
                    assert observer is not None
                    observed = observer.observe_once(timeout_seconds=1.0)
                    outcome = f"observation_{observed.outcome}"
                    response_bytes.append(observed.wire_bytes)
                    progress = connection.get_window_progress(timeout_seconds=1.0)
                    if progress.kind == "WINDOW_PROGRESS":
                        final_progress = window_progress(progress)
                        response_bytes[-1] += len(progress.raw.encode("utf-8"))
                latencies_ms.append((time.monotonic() - request_started) * 1000)
            except (OSError, TimeoutError, ValueError, public_client.ConnectionClosedError) as error:
                outcome = type(error).__name__
            outcomes[outcome] = outcomes.get(outcome, 0) + 1
            workload_stop.wait(public_get_interval_s)

    requester = threading.Thread(target=request_loop, daemon=True) if repeated_public_get else None
    if requester is not None:
        requester.start()

    business_result: dict[str, Any] | None = None
    business_error: Exception | None = None
    business_finished_at: float | None = None

    def run_business_workload() -> None:
        nonlocal business_result, business_error, business_finished_at
        assert descriptor is not None
        try:
            business_result = business_workload(public_client.SharedOperationClient(descriptor)) if business_workload is not None else None
        except (OSError, TimeoutError, ValueError, RuntimeError, public_client.ConnectionClosedError) as error:
            business_error = error
        finally:
            business_finished_at = time.monotonic()

    business_thread = threading.Thread(target=run_business_workload, daemon=True) if business_workload is not None else None
    if business_thread is not None:
        business_thread.start()

    samples: list[dict[str, float | int]] = []
    next_sample = measurement_started
    while process.poll() is None:
        now = time.monotonic()
        if now >= next_sample:
            sample = process_sample(process.pid, now - measurement_started)
            if is_live_process_sample(sample):
                samples.append(sample)
                next_sample += sample_s
            elif process.poll() is not None:
                break
            else:
                next_sample = now + min(sample_s, 0.05)
        time.sleep(min(0.05, max(0.0, next_sample - time.monotonic())))
    workload_stop.set()
    if requester is not None:
        requester.join(timeout=2)
    if business_thread is not None:
        business_thread.join(timeout=5)
    code = process.wait(timeout=5)
    reader.join(timeout=2)
    stderr_reader.join(timeout=2)
    with stderr_lock:
        stderr = "".join(stderr_tail_chunks)
    require(code == 0, f"{name} exited {code}: {stderr.strip()}")
    require(samples, f"{name} yielded no process samples")
    require(business_error is None, f"{name} business workload failed: {business_error}")
    recovery: dict[str, float | int | bool | dict[str, float | int]] | None = None
    if business_workload is not None:
        require(business_result is not None, f"{name} business workload did not complete before normal close")
        require(business_finished_at is not None, f"{name} business workload completion timestamp is unavailable")
        recovery = business_recovery(samples, business_finished_at - measurement_started)
    if descriptor_path is not None:
        require(not descriptor_path.exists(), f"{name} left an owned descriptor behind")
        socket_path = Path(str(descriptor["socket_path"])) if descriptor is not None else None
        require(socket_path is None or not socket_path.exists(), f"{name} left an owned socket behind")
    return {
        "name": name,
        "command": [
            os.fspath(executable),
            *app_args,
            "--measurement-warmup-ms",
            str(warmup_ms),
            "--measurement-duration-ms",
            str(duration_ms),
        ],
        "window_readiness": {
            "marker": ready.marker,
            "session_identity": ready.session_identity,
            "submitted_frame_index": ready.submitted_frame_index,
            **lifecycle_timings(launched, ready_observed_at, measurement_started),
            "warmup_s": warmup_s,
            "measurement_start_is_app_emitted": True,
        },
        "exit_code": code,
        "samples": samples,
        "cpu_percent": trend(samples, "cpu_percent"),
        "rss_kib": trend(samples, "rss_kib"),
        "threads": trend(samples, "threads"),
        "public_get_latency_ms": {
            "count": len(latencies_ms),
            "p50": percentile(latencies_ms, 0.50),
            "p95": percentile(latencies_ms, 0.95),
            "max": round(max(latencies_ms), 3) if latencies_ms else None,
        },
        "public_get_outcomes": outcomes,
        "public_get_pacing": {
            "enabled": repeated_public_get,
            "interval_ms": round(public_get_interval_s * 1_000, 3),
            "mode": public_read_mode,
            "targets": list(public_targets),
            "wait": "one public read turn, then an explicit fixed wait",
        },
        "public_read_response_bytes": {
            "count": len(response_bytes),
            "p50": percentile([float(value) for value in response_bytes], 0.50),
            "p95": percentile([float(value) for value in response_bytes], 0.95),
            "max": max(response_bytes) if response_bytes else None,
        },
        "window_progress_from_read_only_get": final_progress,
        "business_workload": business_result,
        "business_recovery": recovery,
        "input_queue_to_owner_or_submission": "unavailable: this runner never injects physical AppKit/IME input",
        "stderr_tail": stderr.splitlines()[-20:],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--duration-seconds", type=float, default=60.0)
    parser.add_argument("--warmup-seconds", type=float, default=5.0)
    parser.add_argument("--sample-seconds", type=float, default=1.0)
    parser.add_argument("--public-get-interval-ms", type=float, default=100.0)
    parser.add_argument("--fixture-record-count", type=int, default=1001)
    parser.add_argument(
        "--cycles",
        default="document_no_connection_idle,document_connection_idle,rule_set_connection_idle,rule_set_repeated_public_get,document_repeated_public_get,rule_set_fixture_batch,document_edit",
        help="comma-separated normal app cycles to run",
    )
    parser.add_argument("--rounds", type=int, default=1)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    require(1.0 <= arguments.duration_seconds <= 900.0, "duration must be within 1..900 seconds")
    require(0.05 <= arguments.sample_seconds <= arguments.duration_seconds, "invalid sample interval")
    require(10.0 <= arguments.public_get_interval_ms <= 10_000.0, "public GET interval must be within 10..10000 ms")
    require(0.0 <= arguments.warmup_seconds <= 60.0, "warmup must be within 0..60 seconds")
    require(1 <= arguments.fixture_record_count <= 1001, "fixture record count must be within 1..1001")
    require(1 <= arguments.rounds <= 4, "rounds must be within 1..4")
    cycle_specs: dict[str, tuple[Path, list[str], bool, bool, Callable[[public_client.SharedOperationClient], dict[str, Any]] | None, str, tuple[int, ...]]] = {
        "document_no_connection_idle": (DOCUMENT_APP, [], False, False, None, "full", ()),
        "document_connection_idle": (DOCUMENT_APP, ["--with-connection"], True, False, None, "full", ()),
        "rule_set_connection_idle": (RULE_APP, [], True, False, None, "full", ()),
        "rule_set_repeated_public_get": (RULE_APP, [], True, True, None, "full", ()),
        "document_repeated_public_get": (DOCUMENT_APP, ["--with-connection"], True, True, None, "full", ()),
        "rule_set_fixture_batch": (
            RULE_APP,
            [],
            True,
            True,
            lambda client: run_rule_set_fixture_batch(client, arguments.fixture_record_count),
            "full",
            (),
        ),
        "rule_set_fixture_batch_idle_recovery": (
            RULE_APP,
            [],
            True,
            False,
            lambda client: run_rule_set_fixture_batch(client, arguments.fixture_record_count),
            "full",
            (),
        ),
        "rule_set_fixture_full_context": (
            RULE_APP,
            [],
            True,
            True,
            lambda client: run_rule_set_fixture_batch(client, arguments.fixture_record_count),
            "full",
            (),
        ),
        "rule_set_fixture_targeted_context": (
            RULE_APP,
            [],
            True,
            True,
            lambda client: run_rule_set_fixture_batch(client, arguments.fixture_record_count),
            "targeted",
            (1,),
        ),
        "rule_set_fixture_observation": (
            RULE_APP,
            [],
            True,
            True,
            lambda client: run_rule_set_fixture_batch(client, arguments.fixture_record_count),
            "observation",
            (1,),
        ),
        "document_edit": (DOCUMENT_APP, ["--with-connection"], True, True, run_document_edit_workload, "full", ()),
    }
    selected_cycles = [name.strip() for name in arguments.cycles.split(",") if name.strip()]
    require(selected_cycles, "at least one normal window cycle is required")
    require(len(set(selected_cycles)) == len(selected_cycles), "cycle names must not repeat; use --rounds")
    unknown_cycles = [name for name in selected_cycles if name not in cycle_specs]
    require(not unknown_cycles, f"unknown normal window cycles: {unknown_cycles}")
    completed_cycles: list[dict[str, Any]] = []
    for round_index in range(arguments.rounds):
        for cycle_name in selected_cycles:
            executable, app_args, requires_descriptor, repeated_public_get, business_workload, public_read_mode, public_targets = cycle_specs[cycle_name]
            report_name = cycle_name if arguments.rounds == 1 else f"{cycle_name}_round_{round_index + 1}"
            completed_cycles.append(
                run_cycle(
                    report_name,
                    executable,
                    app_args,
                    arguments.duration_seconds,
                    arguments.warmup_seconds,
                    arguments.sample_seconds,
                    requires_descriptor,
                    repeated_public_get,
                    business_workload,
                    arguments.public_get_interval_ms / 1_000,
                    public_read_mode,
                    public_targets,
                )
            )
    report = {
        "schema": "cjgui_normal_window_perf_baseline_v3",
        "captured_at_unix_s": time.time(),
        "build_identity": {
            "rule_executable_sha256": sha256(RULE_APP),
            "document_executable_sha256": sha256(DOCUMENT_APP),
            "renderer_source_sha256": sha256(RUNTIME / "native" / "cjgui_internal_renderer.m"),
            "composable_window_source_sha256": sha256(RUNTIME / "src" / "composable_ui_window.cj"),
        },
        "visibility": "normal macOS window processes; this runner does not assert foreground visibility or physical IME",
        "prewarm": "each cycle waits for its initial submitted-window marker, pumps the same explicit warmup, then samples only after the app emits MEASUREMENT_START",
        "cycles": completed_cycles,
        "not_run": {
            "physical_input_and_ime": "not run: no foreground desktop or real keyboard/IME action was asserted",
            "human_visible_presentation": "unavailable by contract: GPU completion and overlay draw are not a claim of human presentation",
            "user_owned_file_mutation": "not run: document cycles omit --file and the rule fixture is process-local",
        },
    }
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"report": os.fspath(arguments.output), "cycles": [cycle["name"] for cycle in report["cycles"]]}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"normal window performance baseline failed: {error}", file=sys.stderr)
        raise SystemExit(1)
