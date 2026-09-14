#!/usr/bin/env python3
"""Reproducible process-level baseline for the real shared-operation transport.

It launches the ordinary second consumer in its bounded diagnostics mode,
drives public framed GET_CONTEXT calls plus finite fragmented peers, and
samples the actual child process.  The benchmark does not call private domain
methods or synthesize queue state: queue high-water values come from the
connection owner's read-only diagnostic snapshot, and all requests use the
public descriptor/capability protocol.
"""

from __future__ import annotations

import atexit
import argparse
import json
import os
import socket
import statistics
import subprocess
import sys
import threading
import time
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
CORE = ROOT.parents[1] / "shared_operation_core"
CONSUMER = ROOT / "target/release/bin/main"
CAPABILITY = "transport-performance-baseline-capability"
TARGET_ID = 7201

sys.path.insert(0, os.fspath(CORE))
import client as public_client  # noqa: E402


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def runtime_environment() -> dict[str, str]:
    environment = dict(os.environ)
    toolchain = Path(environment.get("CANGJIE_HOME", "/Users/jiangxuanyang/cangjie-toolchains/cangjie"))
    runtime = toolchain / "runtime/lib/darwin_aarch64_cjnative"
    require(runtime.exists(), f"Cangjie runtime is unavailable: {runtime}")
    environment["CJGUI_SECOND_CONSUMER_CAPABILITY"] = CAPABILITY
    previous = environment.get("DYLD_LIBRARY_PATH", "")
    environment["DYLD_LIBRARY_PATH"] = f"{runtime}:{previous}" if previous else os.fspath(runtime)
    return environment


def descriptor_from_ready_line(line: str) -> Path:
    prefix = "CJGUI_READY_V2 DESCRIPTOR_PATH_UTF8_HEX "
    require(line.startswith(prefix), f"consumer was not ready: {line!r}")
    size, encoded = line[len(prefix) :].split(" ", 1)
    path = Path(bytes.fromhex(encoded).decode("utf-8"))
    require(len(os.fsencode(path)) == int(size), "ready descriptor path has the wrong byte length")
    return path


def parse_diagnostic(line: str) -> dict[str, int] | None:
    prefix = "CJGUI_TRANSPORT_DIAGNOSTICS_V2 "
    if not line.startswith(prefix):
        return None
    fields = line[len(prefix) :].split(" ")
    require(len(fields) % 2 == 0, f"malformed transport diagnostic: {line!r}")
    return {fields[index]: int(fields[index + 1]) for index in range(0, len(fields), 2)}


def process_sample(pid: int, elapsed_s: float) -> dict[str, float | int | None]:
    completed = subprocess.run(
        ["ps", "-o", "%cpu=,rss=", "-p", str(pid)],
        text=True,
        capture_output=True,
        check=False,
    )
    fields = completed.stdout.split()
    require(len(fields) == 2, f"unable to sample process {pid}: {completed.stderr.strip()!r}")
    thread_listing = subprocess.run(
        ["ps", "-M", "-o", "pid=", "-p", str(pid)], text=True, capture_output=True, check=False
    )
    thread_count = len(thread_listing.stdout.split())
    require(thread_count > 0, f"unable to count threads for process {pid}: {thread_listing.stderr.strip()!r}")
    lsof = subprocess.run(["lsof", "-nP", "-Ff", "-p", str(pid)], text=True, capture_output=True, check=False)
    numeric_fd_count: int | None = None
    if lsof.returncode == 0:
        # `lsof` also reports pseudo descriptors such as `cwd` and `txt`.
        # Count only distinct numeric descriptor fields, never display rows.
        descriptors = {
            line[1:]
            for line in lsof.stdout.splitlines()
            if line.startswith("f") and line[1:].isdigit()
        }
        numeric_fd_count = len(descriptors)
    return {
        "elapsed_s": round(elapsed_s, 3),
        "cpu_percent": float(fields[0]),
        "rss_kib": int(fields[1]),
        "threads": thread_count,
        "numeric_fd_count": numeric_fd_count,
    }


def cleanup_failed_cycle(process: subprocess.Popen[str], descriptor_path: Path, socket_path: str) -> None:
    """Reclaim only an endpoint issued by this child after an aborted run."""
    if process.poll() is None:
        try:
            process.terminate()
            process.wait(timeout=5)
        except (OSError, subprocess.SubprocessError):
            return
    directory = descriptor_path.parent
    expected_root = Path("/private/tmp")
    try:
        require(
            descriptor_path.name == "connection.cjgui"
            and directory.parent.resolve() == expected_root.resolve()
            and directory.name.startswith("tmpDir"),
            "refusing to clean a non-owned descriptor directory",
        )
        socket = Path(socket_path)
        if socket.parent == directory and socket.name == "shared-operation.sock":
            socket.unlink(missing_ok=True)
        descriptor_path.unlink(missing_ok=True)
        directory.rmdir()
    except (OSError, RuntimeError):
        # A later run may already have removed the endpoint.  Do not broaden
        # cleanup beyond this exact child-issued directory on any anomaly.
        return


def percentile(values: list[float], percentile_value: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    index = min(len(ordered) - 1, int((len(ordered) - 1) * percentile_value))
    return round(ordered[index], 3)


def run_cycle(
    duration_s: float,
    sample_s: float,
    normal_workers: int,
    slow_workers: int,
    idle_peer: bool = False,
) -> dict[str, Any]:
    require(CONSUMER.exists(), "build the second consumer before running the baseline")
    duration_ms = max(1, round(duration_s * 1000))
    process = subprocess.Popen(
        [os.fspath(CONSUMER), "--duration-ms", str(duration_ms)],
        cwd=ROOT,
        env=runtime_environment(),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert process.stdout is not None
    ready_line = process.stdout.readline().strip()
    descriptor_path = descriptor_from_ready_line(ready_line)
    descriptor = public_client.parse_descriptor(descriptor_path)
    socket_path = str(descriptor["socket_path"])
    atexit.register(cleanup_failed_cycle, process, descriptor_path, socket_path)
    payload = "\n".join(
        [
            f"PROTOCOL {public_client.PROTOCOL}",
            f"AUTH {descriptor['capability']}",
            "GET_CONTEXT 1",
            f"ID {TARGET_ID}",
        ]
    )
    request = public_client.frame(payload)
    deadline = time.monotonic() + duration_s
    start = time.monotonic()
    lock = threading.Lock()
    latencies_ms: list[float] = []
    outcomes: Counter[str] = Counter()
    diagnostics: list[dict[str, int]] = []
    output_lines: list[str] = []
    idle_peer_socket: socket.socket | None = None

    def read_diagnostics() -> None:
        assert process.stdout is not None
        for raw_line in process.stdout:
            line = raw_line.strip()
            with lock:
                output_lines.append(line)
                parsed = parse_diagnostic(line)
                if parsed is not None:
                    diagnostics.append(parsed)

    reader = threading.Thread(target=read_diagnostics, daemon=True)
    reader.start()

    if idle_peer:
        # This peer completes a real UDS connect but sends no frame. It is a
        # bounded read-deadline observation, not a synthetic state change.
        idle_peer_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        idle_peer_socket.settimeout(0.5)
        idle_peer_socket.connect(socket_path)

    def normal_worker() -> None:
        while time.monotonic() < deadline:
            started = time.monotonic()
            try:
                response = public_client.exchange(descriptor, payload, 0, timeout_seconds=1.0)
                if "KIND SNAPSHOT" not in response:
                    raise RuntimeError("missing snapshot")
                outcome = "ok"
            except (OSError, ValueError, TimeoutError, RuntimeError, public_client.ConnectionClosedError) as error:
                outcome = type(error).__name__
            elapsed_ms = (time.monotonic() - started) * 1000
            with lock:
                outcomes[outcome] += 1
                if outcome == "ok":
                    latencies_ms.append(elapsed_ms)

    def slow_fragment_worker() -> None:
        # A real but finite partial request consumes a reader only until the
        # transport's 160 ms deadline.  It intentionally never sends a full
        # application action or writes domain truth.
        while time.monotonic() < deadline:
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
                    connection.settimeout(0.5)
                    connection.connect(socket_path)
                    connection.sendall(request[:3])
                    time.sleep(0.125)
                outcome = "slow_peer_ok"
            except OSError as error:
                outcome = f"slow_{type(error).__name__}"
            with lock:
                outcomes[outcome] += 1

    workers = [threading.Thread(target=normal_worker, daemon=True) for _ in range(normal_workers)]
    workers.extend(threading.Thread(target=slow_fragment_worker, daemon=True) for _ in range(slow_workers))
    for worker in workers:
        worker.start()

    samples: list[dict[str, float | int | None]] = []
    next_sample = start
    while time.monotonic() < deadline and process.poll() is None:
        now = time.monotonic()
        if now >= next_sample:
            samples.append(process_sample(process.pid, now - start))
            next_sample += sample_s
        time.sleep(min(0.05, max(0.0, deadline - time.monotonic())))
    for worker in workers:
        worker.join(timeout=2)
    if idle_peer_socket is not None:
        idle_peer_socket.close()
    code = process.wait(timeout=10)
    reader.join(timeout=2)
    stderr = process.stderr.read() if process.stderr is not None else ""
    require(code == 0, f"diagnostics consumer exited {code}: {stderr.strip()}")
    require(not descriptor_path.exists(), "descriptor survived consumer close")
    require(not Path(socket_path).exists(), "socket survived consumer close")
    require(samples, "baseline collected no process samples")
    require(diagnostics, "baseline collected no owner-side diagnostic samples")
    require(
        all(sample.get("RETAINED_WORKERS") == 5 for sample in diagnostics),
        "retained worker handles did not remain fixed at five",
    )
    require(
        any(sample.get("ACTIVE_IO_WORKERS") == 5 for sample in diagnostics),
        "five active I/O loops were never observed",
    )
    require(outcomes["ok"] > 0 or normal_workers == 0, "normal public requests never completed")
    return {
        "duration_s": duration_s,
        "exit_code": code,
        "samples": samples,
        "diagnostics": diagnostics,
        "latency_ms": {
            "count": len(latencies_ms),
            "p50": percentile(latencies_ms, 0.50),
            "p95": percentile(latencies_ms, 0.95),
            "max": round(max(latencies_ms), 3) if latencies_ms else None,
        },
        "outcomes": dict(outcomes),
        "consumer_output": output_lines,
    }


def metric_trend(samples: list[dict[str, float | int | None]], name: str) -> dict[str, float | int | None]:
    values = [sample[name] for sample in samples if sample[name] is not None]
    require(values, f"metric {name} was unavailable for every sample")
    numeric = [float(value) for value in values]
    return {
        "first": values[0],
        "last": values[-1],
        "min": min(values),
        "max": max(values),
        "delta": round(numeric[-1] - numeric[0], 3),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--duration-seconds", type=float, default=600.0)
    parser.add_argument("--sample-seconds", type=float, default=5.0)
    parser.add_argument("--recovery-seconds", type=float, default=15.0)
    parser.add_argument("--idle-seconds", type=float, default=5.0)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    require(0 < arguments.duration_seconds <= 900, "duration must be in (0, 900] seconds")
    require(arguments.sample_seconds > 0, "sample interval must be positive")
    require(0 < arguments.recovery_seconds <= 120, "recovery duration must be in (0, 120] seconds")
    require(0 < arguments.idle_seconds <= 120, "idle duration must be in (0, 120] seconds")

    workload = run_cycle(arguments.duration_seconds, arguments.sample_seconds, normal_workers=2, slow_workers=2)
    recovery = run_cycle(arguments.recovery_seconds, min(arguments.sample_seconds, 2.0), normal_workers=1, slow_workers=0)
    endpoint_idle_no_peer = run_cycle(arguments.idle_seconds, min(arguments.sample_seconds, 1.0), 0, 0)
    idle_connected_peer = run_cycle(arguments.idle_seconds, min(arguments.sample_seconds, 0.05), 0, 0, idle_peer=True)
    report = {
        "schema": "cjgui_shared_operation_transport_perf_baseline_v2",
        "workload": workload,
        "workload_trend": {
            metric: metric_trend(workload["samples"], metric)
            for metric in ("cpu_percent", "rss_kib", "threads", "numeric_fd_count")
        },
        "recovery": recovery,
        "endpoint_idle_no_peer": endpoint_idle_no_peer,
        "idle_connected_peer": idle_connected_peer,
        "assertions": {
            "workload_normal_requests_completed": workload["latency_ms"]["count"] > 0,
            "workload_retained_worker_handles_fixed_at_five": all(
                sample["RETAINED_WORKERS"] == 5 for sample in workload["diagnostics"]
            ),
            "workload_active_io_loops_observed_at_five": any(
                sample["ACTIVE_IO_WORKERS"] == 5 for sample in workload["diagnostics"]
            ),
            "recovery_normal_requests_completed": recovery["latency_ms"]["count"] > 0,
            "idle_contexts_completed_without_domain_actions": True,
            "both_cycles_removed_owned_endpoint": True,
        },
    }
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"report": os.fspath(arguments.output), "assertions": report["assertions"]}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, subprocess.SubprocessError, ValueError) as error:
        print(f"transport performance baseline failed: {error}", file=sys.stderr)
        raise SystemExit(1)
