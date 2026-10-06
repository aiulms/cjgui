#!/usr/bin/env python3
"""Generate deterministic guest tasks for the persistent worker lifecycle check."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "batches" / "acceptance" / "lifecycle"


def script(task: str, exit_seven: bool = False) -> str:
    tail = "& $env:ComSpec /d /c exit 7\n" if exit_seven else ""
    return f"""$ErrorActionPreference = 'Stop'
$workerPid = [int]$env:PHAROS_WORKER_PID
$self = Get-CimInstance Win32_Process -Filter \"ProcessId = $PID\"
$main = Get-Process -Id $PID
$root = Join-Path $env:TEMP ('pharos-worker-' + $env:PHAROS_TRANSFER_SESSION)
$jobDirs = @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction Stop)
$row = [ordered]@{{
    task = '{task}'
    worker_pid = $workerPid
    child_pid = [int]$PID
    parent_pid = [int]$self.ParentProcessId
    main_window_handle = $main.MainWindowHandle.ToInt64()
    active_job_directories = $jobDirs.Count
}}
Write-Output (ConvertTo-Json -InputObject $row -Compress)
if ($workerPid -le 0 -or [int]$self.ParentProcessId -ne $workerPid -or
    $main.MainWindowHandle -ne [IntPtr]::Zero -or $jobDirs.Count -ne 1) {{
    throw 'worker_child_or_temp_lifecycle_mismatch'
}}
Start-Sleep -Milliseconds 12
{tail}"""


def main() -> None:
    manifest = {"batches": [], "tasks": []}
    for batch in range(1, 4):
        folder = OUT / f"batch-{batch:02d}"
        folder.mkdir(parents=True, exist_ok=True)
        batch_record = {"directory": str(folder.relative_to(ROOT)), "tasks": []}
        for ordinal in range(1, 5):
            name = f"b{batch:02d}-t{ordinal:02d}"
            filename = f"{ordinal:02d}-{name}.ps1"
            data = script(name, exit_seven=(batch == 1 and ordinal == 2)).encode("utf-8")
            path = folder / filename
            path.write_bytes(data)
            record = {"batch": batch, "name": filename, "task": name,
                      "exit_expected": 7 if batch == 1 and ordinal == 2 else 0,
                      "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}
            batch_record["tasks"].append(record)
            manifest["tasks"].append(record)
        manifest["batches"].append(batch_record)
    target = ROOT / "lifecycle-batches-manifest.json"
    target.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"manifest": str(target), "tasks": len(manifest["tasks"]),
                      "batches": [x["directory"] for x in manifest["batches"]]}, indent=2))


if __name__ == "__main__":
    main()
