#!/usr/bin/env python3
"""Complete shared-operation readback collector for OHOS device chains.

Why this exists: earlier evidence kept only a response prefix, so a truncated
reply could look like a snapshot. This collector reads the exact length-framed
response, requires the protocol terminator, parses it with the same client the
SDK ships, and only then writes a complete record.

Usage:
  python3 readback_complete.py --out DIR --label NAME [--host H] [--port P]

Exit status:
  0  complete, parseable response saved
  2  transport/protocol failure (no complete record written)
"""

import argparse
import json
import os
import socket
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../../.."))
sys.path.insert(0, os.path.join(REPO, "runtime/cjgui/shared_operation_core"))

from client import parse_response  # noqa: E402

PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAPABILITY = "cjgui-settings-counter-agent-20260925"
MAX_FRAME_BYTES = 4 * 1024 * 1024


def frame(payload: str) -> bytes:
    encoded = payload.encode("utf-8")
    return str(len(encoded)).encode("ascii") + b"\n" + encoded


def read_exact_frame(sock) -> str:
    header = bytearray()
    while b"\n" not in header:
        chunk = sock.recv(1)
        if not chunk:
            raise ConnectionError("closed before frame header")
        header.extend(chunk)
        if len(header) > 32:
            raise ConnectionError("frame header exceeds 32 bytes")
    length = int(bytes(header[:-1]).decode("ascii"))
    if length <= 0 or length > MAX_FRAME_BYTES:
        raise ConnectionError(f"frame length out of bounds: {length}")
    body = bytearray()
    while len(body) < length:
        chunk = sock.recv(min(65536, length - len(body)))
        if not chunk:
            raise ConnectionError(f"closed after {len(body)}/{length} bytes")
        body.extend(chunk)
    return bytes(body).decode("utf-8")


def request(host: str, port: int, payload_lines) -> str:
    payload = "\n".join(payload_lines)
    with socket.create_connection((host, port), timeout=5) as sock:
        sock.sendall(frame(payload))
        return read_exact_frame(sock)


def decode_field(parts):
    field_id, field_type = parts[1], parts[2]
    rest = parts[3:]
    if field_type == "STRING" and rest:
        try:
            return field_id, bytes.fromhex(rest[-1]).decode("utf-8")
        except ValueError:
            return field_id, rest[-1]
    return field_id, rest[-1] if rest else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=17856)
    args = parser.parse_args()

    try:
        raw = request(args.host, args.port,
                      [f"PROTOCOL {PROTOCOL}", f"AUTH {CAPABILITY}", "GET_CONTEXT 0"])
        parsed = parse_response(raw)
    except Exception as error:  # noqa: BLE001 - report the actual transport/parse failure
        print(f"READBACK-INCOMPLETE label={args.label}: {error}", file=sys.stderr)
        return 2
    if not raw.endswith("\nEND") and raw != "END" and not raw.rstrip().endswith("END"):
        print(f"READBACK-INCOMPLETE label={args.label}: missing END terminator", file=sys.stderr)
        return 2

    fields = {}
    version = None
    for name, parts in parsed.entries:
        if name == "VERSION" and parts:
            version = int(parts[0])
        elif name == "FIELD" and len(parts) >= 4:
            field_id, value = decode_field(parts)
            fields[field_id] = value

    record = {
        "label": args.label,
        "complete": True,
        "protocol": PROTOCOL,
        "kind": parsed.kind,
        "bytes": len(raw.encode("utf-8")),
        "version": version,
        "fields": fields,
        "entries": [[name, list(parts)] for name, parts in parsed.entries],
        "raw": raw,
    }
    os.makedirs(args.out, exist_ok=True)
    path = os.path.join(args.out, f"readback_{args.label}.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(record, handle, ensure_ascii=False, indent=2)
    print(f"READBACK-COMPLETE label={args.label} bytes={record['bytes']} "
          f"version={version} fields={len(fields)} path={path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
