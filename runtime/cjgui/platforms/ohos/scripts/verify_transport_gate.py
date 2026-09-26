#!/usr/bin/env python3
"""B 节返工验证：测试接缝隔离、连接上限精确断言、暂停认领下的确定取消、真正 stop。

对应任务页第三次复核 B1/B2/B3：

  B1 隔离：暂停认领只能由**显式测试构建**注册的接缝驱动，且必须持有本轮一次性凭据。
     本脚本对普通产物与测试产物分别断言：
       - 无凭据 / 错误凭据 的控制帧：不切换任何状态；
       - 合法业务帧里恰好包含 "PAUSE_CLAIM" 字样：仍按业务规则处理，不暂停认领。
     判据不靠日志措辞：暂停是否生效由「一次正常写入是否立刻应用」与
     （测试产物）STATE 读数共同判定。

  B2 关闭队列：暂停认领后放入 1 张与多张 Pending 票，再**直接调用生产 stop**
     （接缝 OP STOP → 生产 requestStop()），全部必须得到确定的「未执行」结果，
     队列/字节/在途/连接归零；随后 awaitProductionClosed 观察收敛。

  B3 失败分类：客户端本地 timeout 只记「未定」，**不计**服务端 Cancelled；
     半帧连接按 EOF/reset 与仍活超时分开记录；原半帧到期证据按其实际范围命名。

用法：
  python3 verify_transport_gate.py --variant verify   # 测试产物（含接缝）
  python3 verify_transport_gate.py --variant normal   # 普通产物（无接缝）
"""

import argparse
import os
import re
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
CONTROL_PROTOCOL = "CONTROL CJGUI_VERIFY/1"
HDC = os.environ.get("HDC", "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc")
BUNDLE = os.environ.get("CJGUI_APP_BUNDLE", "com.example.cjguiapp")
OUT = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
       "artifacts/cjgui-backend/verification/transport_gate_evidence.txt")

LINES = []
TOKEN = None


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


def business(lines, timeout=8.0):
    return exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}"] + lines, timeout)


def field_string_of(snapshot_text, field_id):
    parsed = parse_response(snapshot_text)
    for name, parts in parsed.entries:
        if name == "FIELD" and parts[1] == field_id:
            if parts[2] == "STRING" and len(parts) >= 5:
                return bytes.fromhex(parts[4]).decode("utf-8")
            return parts[3]
    return None


def version_of():
    parsed = parse_response(business(["GET_CONTEXT 0"]))
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


def field_of(text, key):
    for line in text.splitlines():
        if line.startswith(key + " "):
            return line[len(key) + 1:].strip()
    return ""


def control(op, token="", timeout=8.0):
    """控制帧：严格 4 行（CONTROL / TOKEN / OP / END）。token 为空串即「无凭据」。
    连接层异常（listener 已退出等）返回空串，由调用方按断言给出结论，不让脚本崩掉。"""
    try:
        return exchange([CONTROL_PROTOCOL, f"TOKEN {token}", f"OP {op}", "END"], timeout)
    except Exception as exc:  # noqa: BLE001
        return f"CONNECTION_ERROR {type(exc).__name__}"


def is_control_response(text):
    return text.strip().startswith(CONTROL_PROTOCOL)


def read_token_from_hilog():
    """本轮凭据只在注册时写一次 hilog；从设备读回，不从仓库读取。
    凭据形状为 't' + 十六进制（见 ohos_transport_verify.cj 的 newVerifyToken）。"""
    out = subprocess.run([HDC, "shell", "hilog -x 2>/dev/null | grep -a 'verify seam armed'"],
                         capture_output=True, text=True).stdout
    matches = re.findall(r"token=([A-Za-z0-9]+)", out)
    return matches[-1] if matches else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--variant", choices=["verify", "normal"], default="verify")
    args = ap.parse_args()
    variant = args.variant
    failures = 0

    subprocess.run([HDC, "fport", "tcp:17856", "tcp:7856"], capture_output=True, text=True)
    time.sleep(1.0)

    global TOKEN
    if variant == "verify":
        TOKEN = read_token_from_hilog()
        note(f"== B0 测试产物：本轮凭据 {'已从 hilog 读回' if TOKEN else '未读到（FAIL）'}")
        if not TOKEN:
            failures += 1
        else:
            note(f"   token={TOKEN}")

    v0 = version_of()
    note(f"   OK   基线版本 v={v0}")

    # ---------------------------------------------------------------- B1 隔离
    note("\n== B1 无凭据控制帧：不得切换任何状态")
    resp = control("PAUSE_CLAIM", "")
    note(f"   响应：{resp.strip().splitlines()[:3]}")
    if variant == "normal":
        # 普通产物根本没有注册接缝：控制帧不是控制帧，直接落回业务路径。
        failures += check("普通产物不识别控制帧（落回业务路径）", is_control_response(resp), False)
    else:
        failures += check("测试产物拒绝无凭据控制帧", field_of(resp, "ERROR"), "verify_missing_token")
    failures += check("无凭据后闸门未暂停", field_of(resp, "PAUSED"), "")
    # 判定「未暂停」的行为证据：一次正常写入必须立刻应用（暂停时它会到期取消）。
    v = version_of()
    a, r = applied_of(business([f"INVOKE {v} INCREMENT 1 0", f"ID {RESOURCE_ID}"]))
    failures += check("无凭据后正常写入立刻应用（未被暂停）", f"{a}/{r}", "true/counter_changed")

    note("\n== B1 错误凭据控制帧：不得切换任何状态")
    wrong = "tdeadbeefdeadbeef" if TOKEN != "tdeadbeefdeadbeef" else "t0000000000000000"
    resp = control("PAUSE_CLAIM", wrong)
    if variant == "normal":
        failures += check("普通产物对伪凭据仍走业务路径", is_control_response(resp), False)
    else:
        failures += check("错误凭据被显式拒绝", field_of(resp, "ERROR"), "verify_token_mismatch")
    v = version_of()
    a, r = applied_of(business([f"INVOKE {v} INCREMENT 1 0", f"ID {RESOURCE_ID}"]))
    failures += check("错误凭据后正常写入立刻应用（未被暂停）", f"{a}/{r}", "true/counter_changed")

    note("\n== B1 合法业务字段值含 'PAUSE_CLAIM'：值必须真正进入 owner")
    # 这正是旧实现的缺陷形状：serveFrame 曾经在正常 submit 之前做 contains 嗅探。
    # 证明强度：把关键字作为 EDIT_NAME 的合法 STRING 值写入，再经公开读回核对——
    # 只证明"返回了业务响应"不够（GET_CONTEXT 0 PAUSE_CLAIM 是非法帧返回 ERROR，
    # 那只说明没被控制入口吞掉，没证明值进入 owner）。
    legit = business(["GET_CONTEXT 0   PAUSE_CLAIM"])
    note(f"   业务响应前 40 字节：{legit[:40]!r}")
    failures += check("含关键字的业务帧不返回控制帧", is_control_response(legit), False)
    v = version_of()
    keyword = "PAUSE_CLAIM"
    kw_hex = keyword.encode("utf-8").hex().upper()
    a, r = applied_of(business([
        f"INVOKE {v} EDIT_NAME 1 1", f"ID {RESOURCE_ID}",
        f"ARG text STRING {len(keyword.encode('utf-8'))} {kw_hex}"]))
    failures += check("关键字作为合法值被应用", f"{a}/{r}", "true/name_changed")
    state = business(["GET_CONTEXT 0"])
    owner_name = field_string_of(state, "name")
    failures += check("公开读回确认关键字值进入 owner", owner_name, keyword)

    if variant == "verify":
        state = control("STATE", TOKEN)
        failures += check("此时闸门状态为未暂停", field_of(state, "PAUSED"), "false")
        # 反向自证：用正确凭据暂停后，同一「业务帧含关键字」必须仍然不被吞。
        control("PAUSE_CLAIM", TOKEN)
        legit2 = exchange([CONTROL_PROTOCOL, f"TOKEN {TOKEN}", "OP STATE", "END"])
        note(f"   暂停后 STATE：{field_of(legit2, 'PAUSED')}")
        control("RESUME_CLAIM", TOKEN)
        failures += check("暂停经凭据生效（自证闸门可工作）", field_of(legit2, "PAUSED"), "true")

    # ------------------------------------------------------------ B3 连接上限
    note("\n== B3 连接上限：精确断言占用上限与拒绝数（maxConnections=8，共 12 条）")
    socks = []
    opened = 0
    for _ in range(12):
        try:
            socks.append(socket.create_connection((HOST, PORT), timeout=3))
            opened += 1
        except OSError:
            pass
    time.sleep(0.6)
    # 一次性、非阻塞地快照每条连接的状态：串行 recv + 逐条超时会把等待时间累加，
    # 超过帧期限(3s)后连「额度内」的连接也会因为到期收场而被误记成拒绝（实测踩中）。
    refused = 0
    alive = 0
    for s in socks:
        s.setblocking(False)
        try:
            data = s.recv(64)
            if data == b"":
                refused += 1
            else:
                alive += 1
        except BlockingIOError:
            alive += 1
        except OSError:
            refused += 1
    note(f"   建立 {opened} 条：服务端主动关闭 {refused}，仍活 {alive}")
    failures += check("超出额度的连接被精确拒绝（12-8=4）", refused, 4)
    failures += check("额度内连接不被拒绝", alive, 8)
    # 关闭全部占用者后再读计数：额度内 8 条仍在时新连接会被拒，读不到 COUNTERS
    # （这正是额度生效的表现），所以释放后才做这项断言。
    for s in socks:
        s.close()
    time.sleep(1.0)
    if variant == "verify":
        counters = control("COUNTERS", TOKEN)
        note(f"   COUNTERS（释放后）：CONNS={field_of(counters, 'CONNS')} "
             f"QUEUED={field_of(counters, 'QUEUED')} INFLIGHT={field_of(counters, 'INFLIGHT')}")
        failures += check("额度释放后只剩本次调用连接", field_of(counters, "CONNS"), "1")
    v = version_of()
    a, r = applied_of(business([f"INVOKE {v} INCREMENT 1 0", f"ID {RESOURCE_ID}"]))
    failures += check("额度释放后正常写入仍可应用", f"{a}/{r}", "true/counter_changed")

    # ---------------------------------------- B3 半帧：EOF/reset 与仍活超时分开
    note("\n== B3 半帧连接（只发长度头，声明 500 字节）")
    half = socket.create_connection((HOST, PORT), timeout=3)
    half.sendall(b"500\n")
    time.sleep(1.2)
    half.settimeout(0.3)
    early = "alive-timeout"
    try:
        data = half.recv(64)
        early = "eof" if data == b"" else f"data:{data[:40]!r}"
    except socket.timeout:
        early = "alive-timeout"
    except OSError as exc:
        early = f"reset:{type(exc).__name__}"
    note(f"   1.2s（< 3s 帧期限）：{early}")
    failures += check("短于帧期限时半帧连接仍活（未误报关闭）", early, "alive-timeout")
    time.sleep(2.6)   # 越过 FRAME_DEADLINE_MS=3000
    half.settimeout(0.5)
    late = "alive-timeout"
    try:
        data = half.recv(64)
        late = "eof" if data == b"" else f"data:{data[:40]!r}"
    except socket.timeout:
        late = "alive-timeout"
    except OSError as exc:
        late = f"reset:{type(exc).__name__}"
    note(f"   3.8s（> 3s 帧期限）：{late}")
    # 修正：超帧期限后 alive-timeout 是假绿（服务端未收场）；只有 eof/reset
    # 才算"被收场"。仍活超时记为失败并保留原因。
    settled_ok = late == "eof" or late.startswith("reset:")
    failures += check("超过帧期限后半帧连接被服务端收场（eof/reset；alive-timeout=失败）",
                      settled_ok, True)
    note("   本段只覆盖「半帧到期收场」，不主张关闭重开；关闭重开另见下节。")
    half.close()

    if variant != "verify":
        note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
        write_out()
        return failures

    # ------------------------------------------- B2/B3 暂停 → 生产 stop → 收敛
    note("\n== B2 暂停认领后放入 1 张 Pending 票：必须得到确定的未执行结果")
    v_before = version_of()
    control("PAUSE_CLAIM", TOKEN)
    resp = business([f"INVOKE {v_before} INCREMENT 1 0", f"ID {RESOURCE_ID}"], timeout=10.0)
    note(f"   单票结果：{resp.strip().splitlines()[:2]}")
    failures += check("单张 Pending 票被确定为未执行",
                      "transport_timeout_not_executed" in resp, True)
    note("   （暂停期间拿不到业务读数，因此这里不做版本比较；"
         "「未执行」本身就是没有业务写入的证据。）")

    note("\n== B2 暂停认领后放入 4 张 Pending 票，然后直接调用生产 stop")
    results = {}

    def worker(key):
        try:
            results[key] = business([f"INVOKE {v_before} INCREMENT 1 0", f"ID {RESOURCE_ID}"],
                                    timeout=12.0)
        except Exception as exc:  # noqa: BLE001
            # 客户端本地 timeout 只是「未定」，绝不能计作服务端已取消。
            results[key] = f"CLIENT_UNDETERMINED {type(exc).__name__}"

    threads = [threading.Thread(target=worker, args=(f"p{i}",)) for i in range(4)]
    for t in threads:
        t.start()
    time.sleep(0.4)   # 让 4 张票进入队列
    if variant == "verify":
        pre = control("COUNTERS", TOKEN)
        note(f"   stop 前 COUNTERS：QUEUED={field_of(pre, 'QUEUED')} INFLIGHT={field_of(pre, 'INFLIGHT')}")
        failures += check("stop 前队列里确有 Pending 票", int(field_of(pre, "QUEUED") or 0) >= 4, True)
    stopped = control("SETTLE", TOKEN, timeout=12.0)
    note(f"   SETTLE 响应：SETTLED={field_of(stopped, 'SETTLED')} "
         f"QUEUED={field_of(stopped, 'QUEUED')} INFLIGHT={field_of(stopped, 'INFLIGHT')} "
         f"BYTES={field_of(stopped, 'BYTES')} CONNS={field_of(stopped, 'CONNS')} "
         f"LIFECYCLE={field_of(stopped, 'LIFECYCLE')}")
    # SETTLE 与 STOP 必须在同一帧内：requestStop 之后 listener 退出，新连接不再被
    # accept（实测表现为 ConnectionResetError），开不出第二条控制连接来读计数。
    # 命名修正（第四次复核）：SETTLE 只证明"取消排队已完成"，可能仍处于
    # Closing（LIFECYCLE=1 / CONNS=1），不得自证 Closed。Closed 由
    # verify_transport_reopen.py 的 owner 外观察入口单独取证。
    failures += check("生产停止入口被调用，排队取消完成",
                      field_of(stopped, "SETTLED"), "true")
    failures += check("队列归零", field_of(stopped, "QUEUED"), "0")
    failures += check("在途票据归零", field_of(stopped, "INFLIGHT"), "0")
    failures += check("字节归零", field_of(stopped, "BYTES"), "0")
    lifecycle = field_of(stopped, "LIFECYCLE")
    note(f"   LIFECYCLE={lifecycle}（1=Closing 属预期；Closed 由重开脚本取证）")
    failures += check("LIFECYCLE 有上报且不为未知", lifecycle in ("1", "2"), True)
    for t in threads:
        t.join()
    closed_not_executed = sum(1 for v in results.values()
                              if isinstance(v, str) and "transport_closed_not_executed" in v)
    undetermined = sum(1 for v in results.values() if isinstance(v, str) and v.startswith("CLIENT_UNDETERMINED"))
    note(f"   4 票结果：确定未执行 {closed_not_executed}/4，客户端未定 {undetermined}/4")
    failures += check("关闭时全部 Pending 票得到确定的未执行结果", closed_not_executed, 4)
    failures += check("没有任何一张票被记成客户端超时", undetermined, 0)

    note("\n== B3 关闭后新的业务连接应被拒绝（listener 已退出）")
    try:
        late_resp = business(["GET_CONTEXT 0"], timeout=3.0)
        note(f"   关闭后仍拿到业务响应：{late_resp[:60]!r}")
        failures += check("关闭后不应再有业务响应", "responded", "refused")
    except socket.timeout as exc:
        # timeout 不属于预期收场：保留原因并失败（不得静默当 refused）。
        note(f"   关闭后连接 timeout（非预期）：{exc}")
        failures += check("关闭后连接被拒", f"timeout:{exc}", "refused")
    except OSError as exc:
        note(f"   关闭后连接被拒（预期）：{type(exc).__name__}: {exc}")
        failures += check("关闭后连接被拒", "refused", "refused")

    note("\n== 收尾：DISARM 复位闸门（保留反例可复跑能力）")
    try:
        dis = control("DISARM", TOKEN, timeout=3.0)
        note(f"   DISARM：{field_of(dis, 'DISARMED')}")
    except Exception as exc:  # noqa: BLE001
        note(f"   DISARM 未取到响应（连接可能已随 owner 收敛关闭）：{type(exc).__name__}")

    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    write_out()
    return failures


def write_out():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(LINES) + "\n")
    print(f"证据已写入 {OUT}")


if __name__ == "__main__":
    sys.exit(0 if main() == 0 else 1)
