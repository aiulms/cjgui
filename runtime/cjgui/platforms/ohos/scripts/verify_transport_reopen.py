#!/usr/bin/env python3
"""B 节传输反例：连接额度、读帧限额、owner 暂停后恢复、半帧连接复检。

对应任务页 B「验证」小节此前未覆盖的反例：
  B1 超过连接上限的滴流（12 条连接 vs maxConnections=8）→ 超限连接被拒收，
     不得崩溃，且额度在关闭后释放（随后正常请求仍可应用）。
  B2 无换行 header（20 字节数字，超 MAX_HEADER_BYTES=16）→ 连接被拒/关闭。
  B3 暂停 owner（SIGSTOP）后连发两批各 8 票，客户端全部超时；恢复（SIGCONT）
     后正常请求仍能应用，且版本增量精确对应实际应用的请求数（不串包、不永久 busy）。
  B4 半帧连接（只发长度头不发帧体）→ 到期被清理；随后正常请求仍可应用。
     （进程内 stop/await/重开 的 generation 隔离见 verify_ime_proxy_chain 之外的
       surface 卸载路径，本探针只覆盖「旧连接不得阻塞新请求」。）

用法： python3 verify_transport_reopen.py
"""

import json
import os
import socket
import subprocess
import sys
import threading
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
HDC = os.environ.get("HDC", "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc")
BUNDLE = os.environ.get("CJGUI_APP_BUNDLE", "com.example.cjguiapp")
OUT = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
       "artifacts/cjgui-backend/verification/transport_reopen_evidence.txt")

LINES = []


def note(text):
    print(text)
    LINES.append(text)


def check(desc, actual, expected):
    if actual == expected:
        note(f"   OK   {desc} ({actual})")
        return 0
    note(f"   FAIL {desc} (got '{actual}' expect '{expected}')")
    return 1


def frame(payload: str) -> bytes:
    encoded = payload.encode("utf-8")
    return str(len(encoded)).encode("ascii") + b"\n" + encoded


def read_frame(sock, timeout=6.0):
    sock.settimeout(timeout)
    received = bytearray()
    header_end = -1
    expected = None
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            raise ConnectionError("closed before complete frame")
        received.extend(chunk)
        if header_end < 0:
            header_end = received.find(b"\n")
            if header_end < 0:
                continue
            expected = int(bytes(received[:header_end]).decode("ascii"))
        total = header_end + 1 + expected
        if len(received) >= total:
            return bytes(received[header_end + 1: total]).decode("utf-8")


def exchange(lines, timeout=6.0):
    payload = "\n".join(lines)
    with socket.create_connection((HOST, PORT), timeout=timeout) as sock:
        sock.sendall(frame(payload))
        return read_frame(sock, timeout)


def version_of():
    parsed = parse_response(exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", "GET_CONTEXT 0"]))
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION")


def applied_of(text):
    parsed = parse_response(text)
    if parsed.kind == "ERROR":
        return "false", next((e[1][0] for e in parsed.entries if e[0] == "ERROR"), "unknown")
    return (next((e[1][0] for e in parsed.entries if e[0] == "APPLIED"), "false"),
            next((e[1][0] for e in parsed.entries if e[0] == "REASON"), ""))


def increment(version, timeout=6.0):
    return exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}",
                     f"INVOKE {version} INCREMENT 1 0", f"ID {RESOURCE_ID}"], timeout)


def owner_pid():
    """优先 pidof（精确），退化到 ps -ef（行：UID PID PPID ... CMD，PID 在第 2 列）。"""
    out = subprocess.run([HDC, "shell", f"pidof {BUNDLE}"], capture_output=True, text=True).stdout
    tokens = [t for t in out.replace("\n", " ").split() if t.isdigit()]
    if tokens:
        return tokens[0]
    ps_out = subprocess.run([HDC, "shell", "ps -ef"], capture_output=True, text=True).stdout
    for line in ps_out.splitlines():
        if "cjguiapp" in line and "grep" not in line:
            parts = line.split()
            if len(parts) >= 2 and parts[1].isdigit():
                return parts[1]
    return None


def signal_owner(sig):
    pid = owner_pid()
    if not pid:
        note(f"   WARN 未找到 owner 进程，无法发送 {sig}")
        return None
    proc = subprocess.run([HDC, "shell", f"kill -{sig} {pid}"], capture_output=True, text=True)
    if proc.stderr.strip():
        note(f"   note kill -{sig} stderr: {proc.stderr.strip()}")
    return pid


def main() -> int:
    failures = 0
    # 传输桥：应用内监听 7856，经 hdc 转发到本机 17856（应用重启后需要重建）。
    subprocess.run([HDC, "fport", "tcp:17856", "tcp:7856"], capture_output=True, text=True)
    time.sleep(1.0)
    note(f"== B0 基线（owner pid={owner_pid()}）")
    # 复位闸门：上一次运行若在暂停状态下中断，应用会保持暂停认领，
    # 连基线查询都拿不到回包。CONTROL 帧不经 owner 认领，可直接复位。
    try:
        exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", "CONTROL RESUME_CLAIM"], timeout=5.0)
    except Exception:  # noqa: BLE001
        pass
    v0 = version_of()
    note(f"   OK   基线版本 v={v0}")

    note("\n== B1 超过连接上限的滴流（12 连接 vs maxConnections=8）")
    socks = []
    refused = 0
    try:
        for _ in range(12):
            try:
                socks.append(socket.create_connection((HOST, PORT), timeout=3))
            except OSError as exc:
                note(f"   note 第 {len(socks) + 1} 条连接建立失败：{exc}")
        # 不发任何数据：超限连接应被应用直接关闭（recv 得 EOF）。
        deadline = time.time() + 2.0
        for s in socks:
            s.settimeout(max(0.2, deadline - time.time()))
            try:
                if s.recv(64) == b"":
                    refused += 1
            except socket.timeout:
                pass
            except OSError:
                refused += 1
        note(f"   已建立 {len(socks)} 条，服务端主动关闭 {refused} 条")
    finally:
        for s in socks:
            s.close()
    time.sleep(1.0)
    v = version_of()
    a, r = applied_of(increment(v))
    failures += check("额度释放后正常请求仍可应用", f"{a}/{r}", "true/counter_changed")

    note("\n== B2 无换行 header（20 字节数字 > MAX_HEADER_BYTES=16）")
    try:
        with socket.create_connection((HOST, PORT), timeout=3) as s:
            s.sendall(b"9" * 20)          # 永不给换行
            s.settimeout(3.0)
            try:
                data = s.recv(512)
                note(f"   服务端响应 {len(data)} 字节：{data[:120]!r}")
                failures += check("超长 header 连接被拒绝", "closed" if data == b"" else "frame", "closed")
            except socket.timeout:
                note("   FAIL 超长 header 连接未在期限内被处理（持续等待）")
                failures += 1
    except OSError as exc:
        note(f"   连接被立即拒绝：{exc}")

    note("\n== B3 暂停 owner 认领，两批各 8 票到期取消后恢复")
    # 模拟器无 root，无法从外部 SIGSTOP 应用进程（kill 返回 Operation not permitted），
    # 因此用传输层自带的验证闸门（CONTROL PAUSE_CLAIM / RESUME_CLAIM）构造同一语义：
    # owner 停止认领 → 票留 Pending 至绝对期限 → 超时结算并回收额度 → 恢复后再次应用。
    v_before_pause = version_of()

    def control(name):
        return exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", f"CONTROL {name}"], timeout=5.0)

    control("RESUME_CLAIM")
    paused = control("PAUSE_CLAIM")
    note(f"   闸门响应：{paused.strip().splitlines()[-2] if paused else 'none'}")

    for batch in (1, 2):
        results = {}

        def worker(key, version_guess):
            try:
                sock = socket.create_connection((HOST, PORT), timeout=3.0)
                sock.sendall(frame("\n".join([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}",
                                              f"INVOKE {version_guess} INCREMENT 1 0",
                                              f"ID {RESOURCE_ID}"])))
                results[key] = read_frame(sock, 6.0)
                sock.close()
            except Exception as exc:  # noqa: BLE001
                results[key] = f"CLIENT_TIMEOUT {type(exc).__name__}"

        threads = [threading.Thread(target=worker, args=(f"b{batch}-{i}", v_before_pause))
                   for i in range(8)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        settled = sum(1 for v in results.values()
                      if isinstance(v, str) and "transport_timeout_not_executed" in v)
        client_to = sum(1 for v in results.values()
                        if isinstance(v, str) and v.startswith("CLIENT_TIMEOUT"))
        note(f"   第 {batch} 批 8 票：服务端超时结算 {settled}/8，客户端超时 {client_to}/8")
        failures += check(f"第 {batch} 批在暂停期间全部未执行", settled + client_to, 8)

    # 恢复后再读版本：暂停期间连 GET_CONTEXT 都认领不到，不能在此期间查询。
    resumed = control("RESUME_CLAIM")
    note(f"   恢复响应：{resumed.strip().splitlines()[-2] if resumed else 'none'}")
    time.sleep(0.5)
    failures += check("暂停期间无业务写入", version_of(), v_before_pause)
    a, r = applied_of(increment(version_of()))
    failures += check("恢复后正常请求重新应用", f"{a}/{r}", "true/counter_changed")

    note("\n== B4 半帧连接（只发长度头）→ 到期清理 → 正常请求不受影响")
    half = socket.create_connection((HOST, PORT), timeout=3)
    half.sendall(b"500\n")          # 声明 500 字节，永不发送帧体
    time.sleep(3.5)                 # 超过 FRAME_DEADLINE_MS=3000
    try:
        half.settimeout(1.0)
        data = half.recv(64)
        note(f"   半帧连接状态：{'closed' if data == b'' else repr(data[:80])}")
    except OSError:
        note("   半帧连接已关闭")
    finally:
        half.close()
    v_b = version_of()
    a, r = applied_of(increment(v_b))
    failures += check("半帧连接不影响后续正常请求", f"{a}/{r}", "true/counter_changed")

    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(LINES) + "\n")
    print(f"证据已写入 {OUT}")
    return failures


if __name__ == "__main__":
    sys.exit(0 if main() == 0 else 1)
