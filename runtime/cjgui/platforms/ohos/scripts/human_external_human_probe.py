#!/usr/bin/env python3
"""人 → 外部 → 人 精确读回取证探针（工作包 C）。

用途：在人类正在代理里编辑某个字段的过程中，由外部共同操作客户端改写同一
业务值，然后让人类按失焦语义提交，最后核对 owner 的真实值与版本。

本脚本只做外部侧（发现/读取/授权改写）。人类侧的触摸与输入由 hdc 驱动，
应用侧的服务端日志（ime blur settle / ime readback / accepted node）作为
人类提交与渲染的原始证据。每次调用把结果追加到 evidence json。

用法：
  python3 human_external_human_probe.py read <label>
  python3 human_external_human_probe.py rename <value> <label>
  python3 human_external_human_probe.py alias <value> <label>
"""

import json
import os
import socket
import sys

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAPABILITY = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
EVIDENCE_PATH = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
                 "artifacts/cjgui-backend/verification/human_external_human_evidence.json")


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
            return bytes(received[header_end + 1: total]).decode("utf-8")


def request(payload_lines):
    payload = "\n".join(payload_lines)
    with socket.create_connection((HOST, PORT), timeout=5) as sock:
        sock.sendall(frame(payload))
        return read_frame(sock)


def decode_field(parts):
    """FIELD <resourceId> <fieldId> <type> ...：整数/布尔直接取值，字符串是
    <字节数> <utf8hex>。返回 (fieldId, 可读值)。"""
    field_id, field_type = parts[1], parts[2]
    rest = parts[3:]
    if field_type == "STRING" and rest:
        try:
            return field_id, bytes.fromhex(rest[-1]).decode("utf-8")
        except ValueError:
            return field_id, rest[-1]
    return field_id, rest[-1] if rest else None


def snapshot(label):
    response = request([f"PROTOCOL {PROTOCOL}", f"AUTH {CAPABILITY}", "GET_CONTEXT 0"])
    parsed = parse_response(response)
    fields, version = {}, None
    for name, parts in parsed.entries:
        if name == "VERSION":
            version = int(parts[0])
        if name == "FIELD" and len(parts) >= 4:
            field_id, value = decode_field(parts)
            fields[field_id] = value
    return {"label": label, "version": version, "fields": fields, "raw": response[:2000]}


def invoke(action, value, label):
    # 字符串参数的线格式：ARG <name> <type> <字节数> <utf8hex>
    # 期望版本取当前版本：外部写入与人类草稿并发，不做旧版本写入。
    expected = snapshot("version-for-external")["version"]
    encoded = value.encode("utf-8")
    response = request([
        f"PROTOCOL {PROTOCOL}", f"AUTH {CAPABILITY}",
        f"INVOKE {expected} {action} 1 1", f"ID {RESOURCE_ID}",
        f"ARG text STRING {len(encoded)} {encoded.hex().upper()}",
    ])
    parsed = parse_response(response)
    record = {"label": label, "action": action, "value": value, "raw": response[:2000]}
    if parsed.kind == "ERROR":
        record["applied"] = False
        record["reason"] = next((e[1][0] for e in parsed.entries if e[0] == "ERROR"), "unknown")
    else:
        record["applied"] = next((e[1][0] for e in parsed.entries if e[0] == "APPLIED"), "false") == "true"
        record["reason"] = next((e[1][0] for e in parsed.entries if e[0] == "REASON"), "")
        record["version_after"] = next((int(e[1][0]) for e in parsed.entries if e[0] == "VERSION_AFTER"), None)
    return record


def append(record):
    existing = []
    if os.path.exists(EVIDENCE_PATH):
        with open(EVIDENCE_PATH, encoding="utf-8") as f:
            existing = json.load(f)
    existing.append(record)
    os.makedirs(os.path.dirname(EVIDENCE_PATH), exist_ok=True)
    with open(EVIDENCE_PATH, "w", encoding="utf-8") as f:
        json.dump(existing, f, ensure_ascii=False, indent=2)


def main() -> int:
    argv = sys.argv[1:]
    if not argv:
        print(__doc__)
        return 2
    mode = argv[0]
    if mode == "read":
        record = snapshot(argv[1] if len(argv) > 1 else "read")
    elif mode in ("rename", "alias"):
        value = argv[1]
        label = argv[2] if len(argv) > 2 else mode
        record = invoke("EDIT_NAME" if mode == "rename" else "EDIT_ALIAS", value, label)
    else:
        print(f"unknown mode {mode}")
        return 2
    append(record)
    print(json.dumps(record, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
