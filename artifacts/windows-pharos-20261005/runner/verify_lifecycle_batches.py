#!/usr/bin/env python3
"""Validate the raw three-batch worker lifecycle results without rerunning them."""
from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SESSION = ROOT.parent / "runner-sessions" / "9699bb39de514337b2a39f9cfce03e7e"
RESULTS = SESSION / "results"
MANIFEST = ROOT / "lifecycle-batches-manifest.json"
BATCHES = [
    "f58e937b25564d35881fdd10b477bee7",
    "4b27c43e5ed547b79789151284443231",
    "492ffb09753e42e9b73c5cc596b9612b",
]


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    expected = {task["name"]: task for task in manifest["tasks"]}
    session = json.loads((SESSION / "session.json").read_text(encoding="utf-8"))
    observed = []
    batch_rows = []
    errors = []
    for nonce in BATCHES:
        path = RESULTS / (nonce + ".json")
        raw = path.read_bytes()
        result = json.loads(raw)
        if result.get("transport_status") != "OK":
            errors.append("transport:" + nonce)
        if result.get("requested_names") != sorted(
            [task["name"] for task in manifest["tasks"] if task["batch"] == len(batch_rows) + 1]
        ):
            errors.append("requested_names:" + nonce)
        rows = []
        for record in result.get("response", {}).get("results", []):
            name = record.get("name")
            try:
                stdout = base64.b64decode(record.get("stdout_b64", ""), validate=True).decode("utf-8")
                identity = json.loads(stdout)
            except Exception as exc:  # evidence decoding is itself fail-closed
                errors.append("stdout_parse:%s:%s" % (name, type(exc).__name__))
                identity = {}
            task = expected.get(name)
            if task is None:
                errors.append("unexpected_task:" + str(name))
                continue
            checks = {
                "exit": record.get("exit_code") == task["exit_expected"],
                "parent": identity.get("parent_pid") == identity.get("worker_pid"),
                "hidden": identity.get("main_window_handle") == 0,
                "job_dirs": identity.get("active_job_directories") == 1,
            }
            for key, value in checks.items():
                if not value:
                    errors.append("%s:%s" % (key, name))
            rows.append({
                "name": name,
                "exit_code": record.get("exit_code"),
                "elapsed_ms": record.get("elapsed_ms"),
                "worker_pid": identity.get("worker_pid"),
                "child_pid": identity.get("child_pid"),
                "parent_pid": identity.get("parent_pid"),
                "main_window_handle": identity.get("main_window_handle"),
                "active_job_directories": identity.get("active_job_directories"),
                "checks": checks,
            })
            observed.append(rows[-1])
        batch_rows.append({
            "nonce": nonce,
            "raw_path": str(path),
            "raw_sha256": hashlib.sha256(raw).hexdigest(),
            "jobs": rows,
        })
    worker_pids = {row["worker_pid"] for row in observed}
    child_pids = [row["child_pid"] for row in observed]
    if len(observed) != 12:
        errors.append("task_count:%d" % len(observed))
    if len(worker_pids) != 1 or worker_pids != {session.get("worker", {}).get("pid")}:
        errors.append("worker_identity")
    if len(set(child_pids)) != 12:
        errors.append("child_pid_reuse_or_missing")
    if session.get("stop_status") != "BYE_AND_SOCKET_CLOSED":
        errors.append("worker_shutdown")
    summary = {
        "schema": "pharos-windows-worker-lifecycle-v1",
        "result": "PASS" if not errors else "FAIL",
        "requested_test_batches": 3,
        "jobs": len(observed),
        "worker_pid": next(iter(worker_pids), None),
        "worker_session_total_batches": session.get("batch_count"),
        "distinct_child_pids": len(set(child_pids)),
        "all_children_directly_parented_by_worker": all(row["parent_pid"] == row["worker_pid"] for row in observed),
        "all_child_windows_hidden": all(row["main_window_handle"] == 0 for row in observed),
        "no_prior_job_directory_accumulation": all(row["active_job_directories"] == 1 for row in observed),
        "exit_7_round_trip": any(row["exit_code"] == 7 for row in observed),
        "shutdown_status": session.get("stop_status"),
        "post_shutdown_pid_enumeration": "not_run; worker acknowledged BYE, closed the socket, and exited its session loop",
        "batches": batch_rows,
        "errors": errors,
    }
    target = ROOT / "lifecycle-batches-verification.json"
    target.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in summary.items() if k not in ("batches", "errors")}, ensure_ascii=False, indent=2))
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
