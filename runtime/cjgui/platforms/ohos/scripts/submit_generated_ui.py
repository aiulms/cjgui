#!/usr/bin/env python3
"""Submit a generated-UI structure candidate over the shared-operation socket.

Reads the exact candidate payload from a file, sends the length-framed
submission, and stores the complete response plus a small parse of the
APPLIED/REASON/PATH/VERSION_* receipts. Exit 2 on transport or truncation.
"""

import argparse
import json
import os
import socket
import sys

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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True, help="candidate payload file")
    parser.add_argument("--expected-version", type=int, required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=17856)
    args = parser.parse_args()

    with open(args.file, "r", encoding="utf-8") as handle:
        candidate = handle.read()
    if not candidate.strip():
        print("SUBMIT-FAILED: empty candidate", file=sys.stderr)
        return 2
    payload = "\n".join([
        f"PROTOCOL {PROTOCOL}",
        f"AUTH {CAPABILITY}",
        f"SUBMIT_GENERATED_UI {args.expected_version}",
        candidate,
    ])
    try:
        with socket.create_connection((args.host, args.port), timeout=8) as sock:
            sock.sendall(frame(payload))
            raw = read_exact_frame(sock)
    except Exception as error:  # noqa: BLE001 - report the actual transport failure
        print(f"SUBMIT-INCOMPLETE label={args.label}: {error}", file=sys.stderr)
        return 2
    if not raw.rstrip().endswith("END"):
        print(f"SUBMIT-INCOMPLETE label={args.label}: missing END terminator", file=sys.stderr)
        return 2

    receipts = {}
    for line in raw.splitlines():
        parts = line.split(" ", 1)
        if len(parts) == 2 and parts[0] in (
                "KIND", "APPLIED", "REASON", "PATH", "CANDIDATE_VERSION",
                "VERSION_BEFORE", "VERSION_AFTER", "TICKET", "STRUCTURE_VERSION"):
            receipts[parts[0].lower()] = parts[1]
    record = {
        "label": args.label,
        "complete": True,
        "expected_version": args.expected_version,
        "candidate": candidate,
        "receipts": receipts,
        "raw": raw,
        "bytes": len(raw.encode("utf-8")),
    }
    os.makedirs(args.out, exist_ok=True)
    path = os.path.join(args.out, f"generated_ui_submit_{args.label}.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(record, handle, ensure_ascii=False, indent=2)
    print(f"SUBMIT-COMPLETE label={args.label} bytes={record['bytes']} "
          f"applied={receipts.get('applied')} reason={receipts.get('reason')} "
          f"version={receipts.get('version_before')}->{receipts.get('version_after')} path={path}")
    return 0 if receipts.get("applied") else 1


if __name__ == "__main__":
    sys.exit(main())
