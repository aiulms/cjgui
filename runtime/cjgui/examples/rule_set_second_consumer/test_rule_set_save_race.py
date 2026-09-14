#!/usr/bin/env python3
"""Real-process save race for the ordinary rule-set persistence path."""

from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent
CONSUMER = ROOT / "target/release/bin/main"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def runtime_env() -> dict[str, str]:
    environment = dict(os.environ)
    runtime = Path(environment.get("CANGJIE_HOME", "/Users/jiangxuanyang/cangjie-toolchains/cangjie")) / "runtime/lib/darwin_aarch64_cjnative"
    environment["DYLD_LIBRARY_PATH"] = f"{runtime}:{environment['DYLD_LIBRARY_PATH']}" if environment.get("DYLD_LIBRARY_PATH") else str(runtime)
    return environment


def main() -> int:
    require(CONSUMER.exists(), "build rule-set second consumer before process race")
    with tempfile.TemporaryDirectory(prefix="cjgui-rule-set-race-") as directory:
        path = str(Path(directory) / "rules.cjgui-rules")
        seeded = subprocess.run([str(CONSUMER), "--seed-save", path], text=True, capture_output=True, env=runtime_env(), check=False)
        require(seeded.returncode == 0 and "SAVE_RESULT saved" in seeded.stdout, f"seed failed: {seeded.stdout} {seeded.stderr}")
        before = Path(path).read_text(encoding="utf-8")

        gate = Path(directory) / "start-save"
        ready_first = Path(directory) / "first-ready"
        ready_second = Path(directory) / "second-ready"
        gate.write_text("hold", encoding="utf-8")
        first_env = runtime_env() | {"CJGUI_RULE_SET_SAVE_RACE_GATE": str(gate), "CJGUI_RULE_SET_SAVE_RACE_READY": str(ready_first)}
        second_env = runtime_env() | {"CJGUI_RULE_SET_SAVE_RACE_GATE": str(gate), "CJGUI_RULE_SET_SAVE_RACE_READY": str(ready_second)}
        first = subprocess.Popen([str(CONSUMER), "--save-race", path, "进程一"], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=first_env)
        second = subprocess.Popen([str(CONSUMER), "--save-race", path, "进程二"], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=second_env)
        for _ in range(100):
            if ready_first.exists() and ready_second.exists():
                break
            import time
            time.sleep(0.02)
        require(ready_first.exists() and ready_second.exists(), "race workers did not both reach the production save boundary")
        gate.unlink()
        first_out, first_err = first.communicate(timeout=10)
        second_out, second_err = second.communicate(timeout=10)
        outcomes = [first_out, second_out]
        require(any("SAVE_RESULT saved" in item for item in outcomes), f"no writer won: {first_out} {first_err} {second_out} {second_err}")
        require(any("SAVE_RESULT external_file_conflict" in item or "SAVE_RESULT save_in_progress" in item for item in outcomes),
                f"second process did not fail closed: {first_out} {first_err} {second_out} {second_err}")
        persisted = Path(path).read_text(encoding="utf-8")
        require(persisted.startswith("CJGUI_RULE_SET 1\n") and persisted != before, "race damaged the persisted document or wrote neither winner")
        require(not Path(f"{path}.cjgui-save-lock").exists(), "cooperating winner leaked its save lease")

        # A killed cooperating writer must leave an unknown lease intact. The
        # next writer fails closed and the last good document remains readable;
        # automatic deletion of this directory would be unsafe.
        hold = Path(directory) / "hold-after-lease"
        hold.write_text("hold", encoding="utf-8")
        held_env = runtime_env() | {"CJGUI_RULE_SET_SAVE_HOLD_AFTER_LEASE": str(hold)}
        held = subprocess.Popen([str(CONSUMER), "--save-race", path, "将被终止"], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=held_env)
        lease = Path(f"{path}.cjgui-save-lock")
        for _ in range(100):
            if lease.exists():
                break
            import time
            time.sleep(0.02)
        require(lease.exists(), "holder never acquired the production lease")
        held.terminate()
        held.wait(timeout=5)
        survivor = subprocess.run([str(CONSUMER), "--save-race", path, "幸存者"], text=True, capture_output=True, env=runtime_env(), check=False)
        require("SAVE_RESULT save_in_progress" in survivor.stdout, f"abandoned lease was not classified safely: {survivor.stdout} {survivor.stderr}")
        require(lease.exists() and Path(path).read_text(encoding="utf-8") == persisted,
                "abandoned lease was silently removed or damaged the persisted document")
    print("rule-set real two-process save race passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
