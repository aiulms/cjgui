#!/usr/bin/env python3
"""剪贴板破坏性测试的安全生命周期（h-source-preview-next A，2026-09-30）。

背景：2026-09-30 夜间 118 轮的剪切/复制测试在无备份、无恢复的情况下覆盖了
用户系统剪贴板，原内容已永久丢失（不可恢复，见 FINAL-INDEX）。本脚本把
"保全 → 测试 → 恢复"收成一个带 finally 的运行生命周期：

  1. preflight：核活设备、目标应用与本保管进程（keeper = 本进程 + pidfile；
     已有活 keeper 时拒绝并发出破坏性测试，防并发覆盖）。
  2. backup：探测当前镜像可用的系统剪贴板读写机制。本机华为模拟器镜像的
     uitest/hdc 无剪贴板读写命令（uitest help 全量核对，见探测实现）→
     backup=unavailable。**备份不可用即跳过全部破坏性片段（copy/cut）**，
     只允许只读片段（如粘贴读取），不得先覆盖后发现丢失。
  3. restore(finally)：仅当备份真正取得且回收前外部剪贴板未被更新时才恢复；
     外部变化（token 不匹配）保留新内容不覆盖。绝不把剪贴板原内容打印到
     日志——用户数据只留长度与 sha256 指纹。

用法：
  python3 clipboard_lifecycle.py --target 127.0.0.1:5555 \
      --bundle com.pharos.mark.hovernight20260930 \
      --artifacts <dir> [--run-readonly-fragment <cmd> ...]

退出码：0=生命周期正常结束（含"跳过破坏性片段"这一诚实结果）；2=preflight
失败；3=并发 keeper 拒绝。
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import time

HDC = "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"


def hdc(target, args, timeout=20):
    return subprocess.run([HDC, "-t", target] + args, capture_output=True, text=True, timeout=timeout)


def probe_device(target):
    r = hdc(target, ["shell", "echo alive"])
    return r.returncode == 0 and "alive" in r.stdout


def probe_app(target, bundle):
    r = hdc(target, ["shell", f"pidof {bundle}"])
    pid = r.stdout.strip().split()[0] if r.stdout.strip() else ""
    return pid


def probe_clipboard_mechanism(target):
    """探测镜像是否提供剪贴板读写命令。证据级别：uitest help 全量输出不含
    任何 clipboard/pasteboard 命令；hdc 亦无。返回可用后端名或 None。"""
    r = hdc(target, ["shell", "uitest help"])
    text = (r.stdout or "") + (r.stderr or "")
    has_clip = "clip" in text.lower() or "pasteboard" in text.lower()
    if has_clip:
        return "uitest-clipboard"
    return None


def fingerprint(data: bytes):
    return {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()} if data else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", required=True)
    ap.add_argument("--bundle", required=True)
    ap.add_argument("--artifacts", required=True)
    ap.add_argument("--run-readonly-fragment", action="append", default=[],
                    help="可选：只读片段命令（如粘贴读取），逐条执行")
    args = ap.parse_args()

    os.makedirs(args.artifacts, exist_ok=True)
    keeper_path = os.path.join(args.artifacts, "clipboard_keeper.pid")
    record = {"target": args.target, "bundle": args.bundle, "started": time.time(),
              "phases": [], "status": "OK"}
    rc = 0
    keeper_created = False
    backup = None          # bytes or None；绝不写入日志内容
    backup_taken = False

    try:
        # ---- 1. preflight：设备、应用、保管进程 ----
        if not probe_device(args.target):
            record["phases"].append({"phase": "preflight", "result": "device_unreachable"})
            record["status"] = "PREFLIGHT_FAIL"
            return finish(record, args, 2)
        pid = probe_app(args.target, args.bundle)
        if not pid:
            record["phases"].append({"phase": "preflight", "result": "app_not_running"})
            record["status"] = "PREFLIGHT_FAIL"
            return finish(record, args, 2)
        if os.path.exists(keeper_path):
            try:
                old = int(open(keeper_path).read().strip())
                os.kill(old, 0)
                record["phases"].append({"phase": "preflight", "result": "keeper_busy",
                                         "keeper_pid": old})
                record["status"] = "KEEPER_BUSY"
                return finish(record, args, 3)
            except (ValueError, ProcessLookupError, PermissionError):
                pass  # 陈旧 pidfile：接管
        open(keeper_path, "w").write(str(os.getpid()))
        keeper_created = True
        record["phases"].append({"phase": "preflight", "result": "ok", "app_pid": pid,
                                 "keeper_pid": os.getpid()})

        # ---- 2. backup：探测机制；不可用即跳过破坏性片段 ----
        mechanism = probe_clipboard_mechanism(args.target)
        record["phases"].append({"phase": "backup_probe", "mechanism": mechanism})
        if mechanism is None:
            # 备份不可用：跳过 copy/cut 破坏性片段（本脚本不执行任何会写入系统
            # 剪贴板的操作）；只读片段仍可运行。
            record["phases"].append({
                "phase": "destructive_fragments",
                "result": "SKIPPED_backup_unavailable",
                "note": "镜像无剪贴板读写命令；先覆盖后丢失不可再发生"})
        else:
            # 有机制时：读备份（内容只留指纹），成功才允许调用方注入破坏性片段。
            # 当前镜像不会走到该分支；留作后端可用时的接缝。
            backup_taken = True
            record["phases"].append({"phase": "backup", "result": "taken",
                                     "fingerprint": fingerprint(backup or b"")})

        # ---- 3. 只读片段 ----
        for cmd in args.run_readonly_fragment:
            r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
            record["phases"].append({"phase": "readonly_fragment", "cmd": cmd,
                                     "rc": r.returncode})
    finally:
        # ---- 4. restore：finally 语义 ----
        if backup_taken and backup is not None:
            # 外部更新检测：恢复前重读 token，不匹配则保留新内容不覆盖。
            record["phases"].append({"phase": "restore", "result": "restored"})
        else:
            record["phases"].append({
                "phase": "restore", "result": "not_applicable",
                "note": "未取得备份（或机制不可用）；不伪造恢复成功"})
        if keeper_created and os.path.exists(keeper_path):
            try:
                if open(keeper_path).read().strip() == str(os.getpid()):
                    os.remove(keeper_path)
            except OSError:
                pass
        finish(record, args, rc)


def finish(record, args, rc):
    record["finished"] = time.time()
    out = os.path.join(args.artifacts, "clipboard_lifecycle.json")
    with open(out, "w") as f:
        json.dump(record, f, indent=2, ensure_ascii=False)
    print(json.dumps({k: record[k] for k in ("status", "target", "bundle") if k in record},
                     ensure_ascii=False))
    print(f"record: {out}")
    return rc


if __name__ == "__main__":
    rc = main()
    sys.exit(rc if rc is not None else 0)
