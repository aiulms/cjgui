#!/usr/bin/env bash
# 只检查本轮 build_and_run 的启动证据；不重启应用，也不读取设备全局旧日志。
# 用法：check_real_ref_capability.sh RUN_DIR RUN_ID HAP TARGET
set -euo pipefail
python3 - "$@" <<'PY'
import hashlib
import pathlib
import re
import sys

if len(sys.argv) != 5:
    print("VERDICT=ERROR reason=usage")
    sys.exit(1)
run_dir, run_id, hap, target = (pathlib.Path(sys.argv[1]), sys.argv[2],
                                pathlib.Path(sys.argv[3]), sys.argv[4])


def finish(verdict, reason, code):
    print(f"VERDICT={verdict} reason={reason}")
    sys.exit(code)


try:
    digest = hashlib.sha256(hap.read_bytes()).hexdigest()
    recorded = (run_dir / "hap_sha256.txt").read_text().splitlines()[0].strip()
    install_receipt = (run_dir / f"install_{run_id}.txt").read_text(errors="replace")
    assertion = (run_dir / f"startup_assert_{run_id}.txt").read_text()
    log = (run_dir / f"runlog_{run_id}.txt").read_text(errors="replace")
except (OSError, IndexError) as exc:
    finish("ERROR", f"missing_current_build_evidence:{type(exc).__name__}", 1)

fields = dict(re.findall(r"^([a-z0-9_]+)=([^\r\n]*)$", assertion, re.M))
pid = fields.get("launch_pid", "")
launch_id = fields.get("launch_id", "")
if (digest != recorded or fields.get("hap_sha256") != digest
        or f"App install path:{hap}" not in install_receipt
        or "install bundle successfully" not in install_receipt.lower()
        or fields.get("run_id") != run_id
        or fields.get("build_variant") != "verify-transport+test-gates"
        or fields.get("log_cleared") != "ok"
        or not pid.isdigit() or not launch_id or not fields.get("launch_ts")):
    finish("ERROR", "current_hap_or_launch_identity_invalid", 1)

identity = (f"run_id={run_id}\ntarget={target}\nhap={hap}\n"
            f"hap_sha256={digest}\ninstall_receipt=install_{run_id}.txt\n"
            f"build_variant=verify-transport+test-gates\n"
            f"launch_pid={pid}\nlaunch_id={launch_id}\n"
            f"launch_ts={fields['launch_ts']}\n")
(run_dir / "run_identity.txt").write_text(identity)

# hilog 格式含日期、时间、PID、TID；只认清空后本轮 runlog 中当前启动 PID。
current = []
for line in log.splitlines():
    match = re.match(r"^\S+\s+\S+\s+(\d+)\s+(\d+)\s+", line)
    if match and match.group(1) == pid:
        current.append(line)
tokens = [m.group(1) for line in current if "verify seam armed token=" in line
          for m in [re.search(r"verify seam armed token=(\S+)", line)] if m]
if not tokens:
    finish("ERROR", "missing_current_launch_token", 1)
launch_token = tokens[-1]
with (run_dir / "run_identity.txt").open("a") as out:
    out.write(f"launch_token={launch_token}\n")
pending_capability = None
pairs = []
for line in current:
    if "ref capability decided" in line:
        match = re.search(r"\bcapability=(\w+)", line)
        pending_capability = match.group(1) if match else None
    elif "surface created" in line and pending_capability:
        match = re.search(r"\bpublished=([01])\b", line)
        if match:
            pairs.append((pending_capability, match.group(1)))
            pending_capability = None
if not pairs:
    finish("BLOCKED", "missing_current_instance_capability_evidence", 42)
capability, published = pairs[-1]
print(f"capability={capability} published={published} launch_pid={pid}")
if capability == "VerifiedNativeRef" and published == "1":
    finish("CAPABLE", "current_instance_native_ref_published", 0)
if capability == "KnownShimNoRef" and published == "0":
    finish("BLOCKED", "KnownShimNoRef_current_instance", 42)
finish("BLOCKED", "current_instance_ref_or_publication_unverified", 42)
PY
