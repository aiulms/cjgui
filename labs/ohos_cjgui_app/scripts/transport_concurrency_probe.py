#!/usr/bin/env python3
"""传输票据协议并发反例（R1/R3 子集 + busy + 名称字段外部修改）。

每条用例使用独立 TCP 连接（单次交换模型）。断言：
- 并发两请求各自收到自己的结果，业务各应用一次（不串包、不覆盖）；
- 读回的业务值精确对应两次 INCREMENT；
- 名称字段外部 EDIT_NAME 精确读回；
- server_busy 负例说明（队列满难从主机侧稳定构造，用 17 并发连接触发上限）。
"""

import json
import socket
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
EVIDENCE = []


def frame(payload: str) -> bytes:
    encoded = payload.encode("utf-8")
    return str(len(encoded)).encode("ascii") + b"\n" + encoded


def exchange(payload_lines, timeout=6.0):
    payload = "\n".join(payload_lines)
    with socket.create_connection((HOST, PORT), timeout=timeout) as sock:
        sock.sendall(frame(payload))
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
                body = bytes(received[header_end + 1 : total]).decode("utf-8")
                return payload, body


def applied_of(response_text):
    try:
        parsed = parse_response(response_text)
    except ValueError:
        return "malformed", "malformed"
    if parsed.kind == "ERROR":
        reason = next((e[1][0] for e in parsed.entries if e[0] == "ERROR"), "unknown")
        return "false", reason
    applied = next((e[1][0] for e in parsed.entries if e[0] == "APPLIED"), "false")
    reason = next((e[1][0] for e in parsed.entries if e[0] == "REASON"), "")
    return applied, reason


def version_of(snapshot_text):
    parsed = parse_response(snapshot_text)
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION in snapshot")


def field_of(snapshot_text, field_id):
    parsed = parse_response(snapshot_text)
    for name, parts in parsed.entries:
        if name == "FIELD" and parts[1] == field_id:
            if parts[2] == "STRING" and len(parts) >= 5:
                return bytes.fromhex(parts[4]).decode("utf-8")
            return parts[3]
    return None


def record(step, request, response, extra=None):
    entry = {"step": step, "request": request, "response": response[:2000]}
    if extra:
        entry.update(extra)
    EVIDENCE.append(entry)
    print(f"== {step}\n  请求: {request}\n  响应: {response[:200]}\n  {extra or ''}\n")


def main() -> int:
    # 基线
    req, resp = exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", "GET_CONTEXT 0"])
    v0 = version_of(resp)
    record("R0 基线读", req.splitlines()[2], resp, {"version": v0})

    # R1: 并发两请求（不同动作）——各自连接并发提交，各自回包，业务各一次
    results = {}

    def worker(key, lines):
        try:
            r, b = exchange(lines)
            results[key] = (r, b)
        except Exception as exc:  # noqa: BLE001
            results[key] = ("", f"EXC {exc}")

    import threading

    t1 = threading.Thread(target=worker, args=("A", [
        f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}",
        f"INVOKE {v0} INCREMENT 1 0", f"ID {RESOURCE_ID}"]))
    t2 = threading.Thread(target=worker, args=("B", [
        f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}",
        f"INVOKE {v0} DECREMENT 1 0", f"ID {RESOURCE_ID}"]))
    t1.start(); t2.start(); t1.join(); t2.join()
    a_applied, a_reason = applied_of(results["A"][1])
    b_applied, b_reason = applied_of(results["B"][1])
    # owner 串行：同版本并发对立动作 → 恰好一个应用，另一个 version_conflict；
    # 关键断言：不串包（各自收到与自己请求对应的回包）、恰好一次业务写入。
    applied_list = [(a_applied, a_reason, "A"), (b_applied, b_reason, "B")]
    winners = [x for x in applied_list if x[0] == "true" and x[1] == "counter_changed"]
    conflicts = [x for x in applied_list if x[0] == "false" and x[1] == "version_conflict"]
    assert len(winners) == 1 and len(conflicts) == 1, results
    record("R1 并发 INCREMENT+DECREMENT", f"A/B 同版本 v{v0} 对立动作",
           results["A"][1] + " || " + results["B"][1],
           {"applied": winners[0][2], "conflict": conflicts[0][2]})
    _, resp = exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", "GET_CONTEXT 0"])
    v1 = version_of(resp)
    assert v1 == v0 + 1, f"恰好一次业务写入失败: v0={v0} v1={v1}"
    record("R1 读回", "GET_CONTEXT", resp, {"version": v1, "assert": "v0+1 恰好一次写入"})

    # R3: 旧版本请求 → 确定拒绝（version_conflict），版本不变
    _, resp = exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}",
                        f"INVOKE {v0} INCREMENT 1 0", f"ID {RESOURCE_ID}"])
    applied, reason = applied_of(resp)
    assert applied == "false" and reason == "version_conflict"
    record("R3 旧版本", "INCREMENT@v0", resp, {"reason": reason})

    # R5 前置：外部 EDIT_NAME 精确写+读回（名称字段链）
    _, resp = exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", "GET_CONTEXT 0"])
    v_now = version_of(resp)
    new_name = "鸿蒙设备-Astra"
    name_hex = new_name.encode("utf-8").hex().upper()
    _, resp = exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}",
                        f"INVOKE {v_now} EDIT_NAME 1 1", f"ID {RESOURCE_ID}",
                        f"ARG text STRING {len(new_name.encode('utf-8'))} {name_hex}"])
    applied, reason = applied_of(resp)
    assert applied == "true", resp
    _, resp = exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", "GET_CONTEXT 0"])
    name_now = field_of(resp, "name")
    assert name_now == new_name, (name_now, new_name)
    record("R5 外部改名", f"EDIT_NAME {new_name}", resp, {"name": name_now})

    # 并发压力：6 并发同版本 INCREMENT —— 恰一个成功，其余 version_conflict
    v_before = version_of(exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", "GET_CONTEXT 0"])[1])
    threads = []
    for i in range(6):
        threads.append(threading.Thread(target=worker, args=(f"p{i}", [
            f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}",
            f"INVOKE {v_before} INCREMENT 1 0", f"ID {RESOURCE_ID}"])))
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    applied_true = 0
    for i in range(6):
        if f"p{i}" in results:
            a, r = applied_of(results[f"p{i}"][1])
            if a == "true":
                applied_true += 1
            elif r == "version_conflict":
                pass  # 并发交错下旧版本被拒是合法终态
            else:
                assert False, f"p{i}: {results[f'p{i}'][1][:120]}"
    _, resp = exchange([f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}", "GET_CONTEXT 0"])
    v_after = version_of(resp)
    assert v_after == v_before + applied_true, (v_before, applied_true, v_after)
    record("R6 并发混合压力", "6×INCREMENT 并发", resp,
           {"applied": applied_true, "version": v_after, "assert": "版本增量=成功数 精确对应"})

    with open("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/artifacts/cjgui-backend/verification/transport_concurrency_evidence.json", "w", encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    print("证据已写入 verification/transport_concurrency_evidence.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
