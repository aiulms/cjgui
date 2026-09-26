#!/usr/bin/env python3
"""B：真正关闭后同进程重开（第五次复核 B.1/B.2/B.4 强化版）。

流程（全部通过 verify 接缝驱动生产入口，不伪造状态）：
  1. 普通业务帧验证服务可用；STATE 取旧实例身份；
  2. PAUSE_CLAIM 闸住 4 张 Pending；**stop 前**保留一条旧 socket，发送可辨识
     INCREMENT 帧的前半部（长度头 + 半个业务体）；
  3. SETTLE_HOLD：生产停止入口，4 张 Pending 全部确定未执行；分离 close+boot
     线程（等控制连接终结→生产 awaitClosed→生产 boot），800ms 关闭窗口；
  4. 关闭窗口内连接被拒：只认 EOF/reset/refused；**timeout 不能当被拒**，
     单独记失败（含「仅超时」分类负控自检）；
  5. Closed/boot 后在**同一条旧 socket** 上补发余帧：旧连接必须被拒
     （对端已关闭/无应答），对应 INCREMENT 未应用、owner 版本不变；
  6. BOOT_STATE 轮询：生产 awaitClosed 判定 Closed=true、BOOTED=true、新身份；
  7. 新身份下业务可用、取消票未重复应用、owner 值保留；新连接新请求成功。

原始请求/回包逐条归档（transport_reopen_raw.json），断言随 run 可复核。
"""

import json
import re
import socket
import subprocess
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import (  # noqa: E402
    BoundedExchange, FrameError, classify_failure, parse_control_frame_strict)
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
TOKEN = ""
EVIDENCE = []
RAW_ARCHIVE = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
               "artifacts/cjgui-backend/verification/transport_reopen_raw.json")
EXCHANGE = BoundedExchange(HOST, PORT, RAW_ARCHIVE)


def note(msg):
    print(msg)


def check(desc, actual, expected):
    ok = actual == expected
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} (got {actual!r} expect {expected!r})")
    EVIDENCE.append({"check": desc, "actual": actual, "expected": expected, "pass": ok})
    return 0 if ok else 1


def business(lines, timeout=8.0):
    return EXCHANGE.exchange_strict(
        [f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}"] + lines, timeout)


def control_map(op, timeout=6.0):
    _, body = EXCHANGE.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", f"OP {op}", "END"], timeout)
    return parse_control_frame_strict(body)


def field_of(entries_text, field_id):
    parsed = parse_response(entries_text)
    for name, parts in parsed.entries:
        if name == "FIELD" and parts[1] == field_id:
            if parts[2] == "STRING" and len(parts) >= 5:
                return bytes.fromhex(parts[4]).decode("utf-8")
            return parts[3]
    return None


def version_of(snapshot_text):
    parsed = parse_response(snapshot_text)
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION")


def half_frame_old_socket(v0: int):
    """stop 前建立旧 socket，发送可辨识 INCREMENT 帧的前半部。

    返回 (sock, rest_bytes, full_body)。余帧留给 Closed/boot 后在同一 socket
    上补发（B.2：不再是 boot 后新建连接）。
    """
    body = f"PROTOCOL {PROTOCOL}\nAUTH {CAP}\nINVOKE {v0} INCREMENT 1 0\nID {RESOURCE_ID}"
    encoded = body.encode("utf-8")
    header = str(len(encoded)).encode("ascii") + b"\n"
    full = header + encoded
    sock = socket.create_connection((HOST, PORT), timeout=3.0)
    first = len(full) // 2
    sock.sendall(full[:first])
    return sock, full[first:], body


def main() -> int:
    global TOKEN
    token_out = subprocess.run(
        ["/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc",
         "shell", "hilog -x 2>/dev/null | grep -a 'verify seam armed token=' | tail -1"],
        capture_output=True, text=True).stdout
    m = re.search(r"token=(\S+)", token_out)
    if not m:
        note(f"FAIL 未读到本轮 verify token（hilog: {token_out[:80]!r}）")
        return 2
    TOKEN = m.group(1)
    note(f"== B0 token={TOKEN}")
    failures = 0

    # B.1 自检：「仅超时」不得归类为拒绝（负控——分类器若放行超时即闸门失效）
    class FakeTimeout(socket.timeout):
        pass
    failures += check("负控：仅超时不判为拒绝", classify_failure(FakeTimeout("t")), "timeout")
    failures += check("负控：reset 判为拒绝", classify_failure(ConnectionResetError()), "ConnectionResetError")

    # 1) 基线 + 旧实例身份
    _, resp = business(["GET_CONTEXT 0"])
    v0 = version_of(resp)
    name0 = field_of(resp, "name")
    count0 = field_of(resp, "count")
    note(f"   基线: v={v0} name={name0!r} count={count0}")
    failures += check("服务可用", bool(v0 is not None), True)
    old_identity = control_map("STATE").get("IDENTITY", "")
    note(f"   旧实例身份: {old_identity!r}")
    failures += check("旧实例身份可读", old_identity != "" and old_identity != "none", True)

    # 2) PAUSE + 4 张 Pending + stop 前旧 socket 半帧
    failures += check("认领已暂停", control_map("PAUSE_CLAIM").get("PAUSED"), "true")
    import threading
    results = {}

    def worker(key):
        try:
            _, body = business([f"INVOKE {v0} INCREMENT 1 0", f"ID {RESOURCE_ID}"], timeout=12.0)
            results[key] = body
        except Exception as exc:  # noqa: BLE001
            results[key] = f"CLIENT_UNDETERMINED {type(exc).__name__}"

    threads = [threading.Thread(target=worker, args=(f"p{i}",)) for i in range(4)]
    for t in threads:
        t.start()
    time.sleep(0.5)
    half_sock, half_rest, half_body = half_frame_old_socket(v0)
    note(f"   旧 socket 已建立，INCREMENT 帧 {len(half_rest)} 字节待补发")

    # 3) SETTLE_HOLD：停 + 取消排队票 + 分离 close+boot（800ms 关闭窗口）
    _, settle_body = EXCHANGE.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", "OP SETTLE_HOLD", "END"], timeout=10.0)
    try:
        settled_map = parse_control_frame_strict(settle_body)
    except FrameError as exc:
        note(f"FAIL SETTLE 响应不可解析: {exc}")
        return 3
    note(f"   SETTLE: {settled_map}")
    failures += check("排队取消完成", settled_map.get("SETTLED"), "true")
    failures += check("close+boot 线程已分离", settled_map.get("BOOT_PENDING"), "true")
    failures += check("关闭窗口已保持（800ms）", settled_map.get("BOOT_HOLD"), "800")
    for t in threads:
        t.join()
    definite_not_executed = 0
    undetermined = 0
    reasons = []
    for key in sorted(results):
        v = results[key]
        if isinstance(v, str) and v.startswith("CLIENT_UNDETERMINED"):
            undetermined += 1
            reasons.append(f"{key}: client-undetermined")
        elif "transport_closed_not_executed" in v or "transport_timeout_not_executed" in v:
            definite_not_executed += 1
            reasons.append(f"{key}: {'closed' if 'closed_not_executed' in v else 'timeout'}")
        else:
            reasons.append(f"{key}: {v[:60]!r}")
    failures += check("4 张 Pending 全部确定未执行（closed/timeout）", definite_not_executed, 4)
    failures += check("无客户端未定", undetermined, 0)
    note("   4 票归属: " + "; ".join(reasons))

    # 4) 关闭窗口内连接被拒：EOF/reset/refused 才算；timeout 记失败（B.1）
    refusal_kinds = []
    timeout_seen = False
    for attempt in range(5):
        try:
            business(["GET_CONTEXT 0"], timeout=2.0)
            time.sleep(0.12)
        except Exception as exc:  # noqa: BLE001
            kind = classify_failure(exc)
            if kind == "timeout":
                timeout_seen = True
                break
            refusal_kinds.append(kind)
            break
    failures += check("关闭窗口内连接被拒（EOF/reset/refused）", len(refusal_kinds) >= 1, True)
    failures += check("关闭窗口内无超时冒充拒绝", timeout_seen, False)

    # 5) 旧 socket 余帧补发（B.2）：同一条连接，Closed/boot 之后
    old_socket_outcome = "no_attempt"
    try:
        half_sock.sendall(half_rest)
        # 发送成功也要读：对端若已关闭，recv 得 EOF/reset；任何回包都算泄露
        half_sock.settimeout(2.0)
        data = half_sock.recv(4096)
        if not data:
            old_socket_outcome = "eof"
        else:
            old_socket_outcome = f"UNEXPECTED_RESPONSE {data[:60]!r}"
    except Exception as exc:  # noqa: BLE001
        old_socket_outcome = classify_failure(exc)
    finally:
        try:
            half_sock.close()
        except OSError:
            pass
    note(f"   旧 socket 补发结果: {old_socket_outcome}")
    failures += check("旧连接补发被拒（无业务回包）",
                      old_socket_outcome in ("eof", "ConnectionResetError", "BrokenPipeError"),
                      True)

    # 6) BOOT_STATE：生产 awaitClosed → 同进程 boot → 新身份
    boot_map = None
    deadline = time.monotonic() + 15.0
    last_err = ""
    while time.monotonic() < deadline:
        try:
            bm = control_map("BOOT_STATE", timeout=3.0)
            if bm.get("PENDING") != "true":
                boot_map = bm
                break
        except Exception as exc:  # noqa: BLE001
            last_err = classify_failure(exc)
        time.sleep(0.2)
    if boot_map is None:
        note(f"FAIL BOOT_STATE 未收敛（最后错误: {last_err}）")
        failures += 1
    else:
        note(f"   BOOT_STATE: {boot_map}")
        failures += check("owner 外确认 Closed（生产 awaitClosed 判定）",
                          boot_map.get("CLOSED"), "true")
        failures += check("同进程 BOOT 完成", boot_map.get("BOOTED"), "true")
        new_identity = boot_map.get("NEW_IDENTITY", "")
        failures += check("新身份不等于旧身份",
                          new_identity != "" and new_identity != old_identity, True)

    # 7) 新连接新请求成功；取消票未重复应用；旧半帧 INCREMENT 未泄露
    _, resp = business(["GET_CONTEXT 0"])
    v_after = version_of(resp)
    name_after = field_of(resp, "name")
    count_after = field_of(resp, "count")
    note(f"   重开后读回: v={v_after} name={name_after!r} count={count_after}")
    failures += check("重开后业务可用", v_after is not None, True)
    failures += check("owner 值保留", name_after, name0)
    failures += check("取消票+旧半帧未应用（版本不变）", v_after, v0)
    failures += check("取消票+旧半帧未应用（计数不变）", count_after, count0)
    _, resp = business([f"INVOKE {v0} INCREMENT 1 0", f"ID {RESOURCE_ID}"])
    parsed = parse_response(resp)
    applied = next((e[1][0] for e in parsed.entries if e[0] == "APPLIED"), "false")
    failures += check("新身份下 INCREMENT 应用", applied, "true")

    out = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
           "artifacts/cjgui-backend/verification/transport_reopen_evidence.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())
