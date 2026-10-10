#!/usr/bin/env python3
"""事项1回归：恢复证据必须限定本腿当前启动实例。

- 旧实例-only 行 + instance=当前 → 拒绝（fixla10-review 反例的闭合）。
- 当前实例行 + 旧实例行混合 + instance=当前 → 接受且配对当前票据（混排不遮蔽）。
- 无 instance（默认）→ 行为不变（向后兼容）。
使用真实函数与 fixla10 归档行；无设备、无生产修改。
"""
import inspect
import json
import re
import sys
import unittest
from pathlib import Path

P = Path(__file__).resolve().parent
REPO = P.parents[4]
ARCHIVE = (REPO / "labs/ohos_cangjie_smoke/artifacts/cjgui-backend"
           / "run/visual-edit-fixla10-20261005")

sys.path.insert(0, str(P))
import verify_pharos_dual_owner as vdo

ACCEPTED = ("restore_ack", "mount_snapshot")
PID_PATTERN = re.compile(r"\S+\s+\S+\s+(\d+)\s")

assert "instance_pid" in inspect.signature(vdo.body_restore_evidence).parameters
assert "instance_pid" in inspect.signature(
    vdo._mount_lifecycle).parameters


def load_archive():
    run = json.loads((ARCHIVE / "run.json").read_text())
    freeze = next(x for x in run["freeze_decisions"]
                  if x["label"] == "edit after reopen")
    hint = freeze["decision"]["current_identity"]
    owner_version = freeze["decision"]["owner_version"]
    current_pid = PID_PATTERN.match(
        run["public_save_1"]["terminal_row"])[1]
    ack_rows, adopted_rows = [], []
    with (ARCHIVE / "hilog-rows.txt").open(errors="replace") as stream:
        for line in stream:
            if "proxy restore ack accepted" in line:
                ack_rows.append(line.rstrip())
            elif "PHAROS_OHOS_RESTORE_ADOPTED" in line:
                adopted_rows.append(line.rstrip())
    return hint, owner_version, current_pid, ack_rows, adopted_rows


HINT, OWNER_VERSION, CURRENT_PID, ACK_ROWS, ADOPTED_ROWS = load_archive()
ALL_ROWS = ACK_ROWS + ADOPTED_ROWS
STALE_ROWS = [r for r in ALL_ROWS if PID_PATTERN.match(r)[1] != CURRENT_PID]
CURRENT_ROWS = [r for r in ALL_ROWS if PID_PATTERN.match(r)[1] == CURRENT_PID]
assert STALE_ROWS and CURRENT_ROWS, "archive lacks both epochs"


def decide(rows, instance_pid):
    return vdo.body_restore_evidence(
        rows, 0, HINT["node"], 0, None, OWNER_VERSION,
        identity_hint=dict(HINT), instance_pid=instance_pid)


class InstanceScopedEvidenceTest(unittest.TestCase):
    def test_old_instance_only_is_refused(self):
        got = decide(STALE_ROWS, int(CURRENT_PID))
        self.assertTrue(not got or got.get("source") not in ACCEPTED, got)

    def test_mixed_epochs_pair_current_ticket(self):
        got = decide(CURRENT_ROWS + STALE_ROWS, int(CURRENT_PID))
        self.assertTrue(got and got.get("source") in ACCEPTED, got)
        self.assertEqual(got.get("ticket"), 2, got)
        self.assertEqual(tuple(got.get("sel")), (11, 11), got)

    def test_no_instance_preserves_legacy_behavior(self):
        got = decide(CURRENT_ROWS, None)
        self.assertTrue(got and got.get("source") in ACCEPTED, got)


if __name__ == "__main__":
    unittest.main()
