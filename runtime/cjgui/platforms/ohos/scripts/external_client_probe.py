#!/usr/bin/env python3
"""CJGUI 设置与计数 —— 外部共同操作取证客户端（工作包 C）。

通过 hdc fport 的 TCP 转发连接应用内薄传输桥（模拟器开发通道）；
授权、协议校验、版本契约与业务执行全部由仓颉侧 connection.dispatchPayload
完成（与人类触摸同一 owner、同一规则）。本脚本记录每步请求/响应用于留证。
"""

import socket
import sys

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from client import SharedOperationArgument, parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAPABILITY = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
EVIDENCE = []


def frame(payload: str) -> bytes:
    encoded = payload.encode("utf-8")
    return str(len(encoded)).encode("ascii") + b"\n" + encoded


def read_frame(sock):
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
            return bytes(received[header_end + 1 : total]).decode("utf-8")


def request(label, payload_lines, expect_ok=True):
    payload = "\n".join(payload_lines)
    with socket.create_connection((HOST, PORT), timeout=5) as sock:
        sock.sendall(frame(payload))
        response = read_frame(sock)
    EVIDENCE.append({
        "step": label,
        "request": payload_lines,
        "response": response[:4000],
        "expected_ok": expect_ok,
    })
    print(f"== {label}\n请求: {payload_lines}\n响应: {response[:400]}\n")
    return response


def applied_of(response):
    """RESULT 响应取 APPLIED；ERROR 响应视为 applied=false + reason。"""
    try:
        parsed = parse_response(response)
    except ValueError:
        return "false", "malformed"
    if parsed.kind == "ERROR":
        reason = next((e[1][0] for e in parsed.entries if e[0] == "ERROR"), "unknown")
        return "false", reason
    applied = next((e[1][0] for e in parsed.entries if e[0] == "APPLIED"), "false")
    reason = next((e[1][0] for e in parsed.entries if e[0] == "REASON"), "")
    return applied, reason


def version_after_of(response):
    parsed = parse_response(response)
    return int(next(e[1][0] for e in parsed.entries if e[0] == "VERSION_AFTER"))


def invoke(expected_version, action, arguments=None, capability=CAPABILITY):
    args = arguments or []
    lines = [f"PROTOCOL {PROTOCOL}", f"AUTH {capability}",
             f"INVOKE {expected_version} {action} 1 {len(args)}",
             f"ID {RESOURCE_ID}"]
    lines.extend(args)
    return request(f"INVOKE {action} (expected v{expected_version})", lines)


def get_context(capability=CAPABILITY):
    lines = [f"PROTOCOL {PROTOCOL}", f"AUTH {capability}", "GET_CONTEXT 0"]
    return request("GET_CONTEXT 发现/读取", lines)


def field_value(response, field, key):
    for name, parts in response.entries:
        if name == field:
            return dict(zip(parts[::2], parts[1::2])).get(key)
    return None


def main() -> int:
    # C1: 发现/读取 —— 上下文含 count/enabled 字段、资源身份与动作目录
    context = parse_response(get_context())
    assert context.kind == "SNAPSHOT", f"期望快照，得到 {context.kind}"

    def field_of(entries, field_id):
        for name, parts in entries:
            if name == "FIELD" and parts[1] == field_id:
                return parts[3]
        return None

    version = int(next(e for e in context.entries if e[0] == "VERSION")[1][0])
    count_value = field_of(context.entries, "count")
    enabled_value = field_of(context.entries, "enabled")
    print(f"发现: 计数={count_value} enabled={enabled_value} v{version}")

    # C2: 授权修改 —— 外部 INCREMENT（人与外部同 owner、同规则）
    applied, reason = applied_of(invoke(version, "INCREMENT"))
    assert applied == "true", (applied, reason)
    context = parse_response(get_context())
    version_after = int(next(e for e in context.entries if e[0] == "VERSION")[1][0])
    count_now = field_of(context.entries, "count")
    print(f"外部修改后读回: count={count_now} version={version_after}")
    assert int(count_now) == int(count_value) + 1

    # C4 反例: 旧版本请求 → version_conflict，版本与内容不变
    applied, reason = applied_of(invoke(0, "INCREMENT"))
    assert applied == "false" and reason == "version_conflict", (applied, reason)

    # C5 反例: 伪造授权
    applied, reason = applied_of(invoke(version_after, "INCREMENT", capability="cjgui-forged-token"))
    assert applied == "false" and "unauthorized" in reason, (applied, reason)

    # C6 反例: 未知动作
    applied, reason = applied_of(invoke(version_after, "NOT_A_REAL_ACTION"))
    assert applied == "false" and reason in ("unauthorized_action", "invalid_action"), (applied, reason)

    # C7 禁用后拒绝 + 恢复
    applied, _ = applied_of(invoke(version_after, "SET_ENABLED",
                                   arguments=["ARG value BOOLEAN 0"]))
    assert applied == "true"
    context = parse_response(get_context())
    version_disabled = int(next(e for e in context.entries if e[0] == "VERSION")[1][0])
    applied, reason = applied_of(invoke(version_disabled, "INCREMENT"))
    assert applied == "false" and reason == "counter_disabled", (applied, reason)
    applied, _ = applied_of(invoke(version_disabled, "SET_ENABLED",
                                   arguments=["ARG value BOOLEAN 1"]))
    assert applied == "true"
    context = parse_response(get_context())
    version_re = int(next(e for e in context.entries if e[0] == "VERSION")[1][0])
    print(f"禁用拒绝与恢复验证完成（disabled v{version_disabled} → re-enabled v{version_re}）")

    with open("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/artifacts/cjgui-backend/verification/external_chain_evidence.json", "w", encoding="utf-8") as f:
        import json
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    print("证据已写入 verification/external_chain_evidence.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
