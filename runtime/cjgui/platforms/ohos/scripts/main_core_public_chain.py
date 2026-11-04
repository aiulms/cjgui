#!/usr/bin/env python3
"""Public-chain probe for the main-core OHOS app.

Runs only public protocol exchanges against the running application:
  * a complete GET_CONTEXT snapshot,
  * one versioned EDIT_NAME invoke (machine-side owner write),
  * a follow-up snapshot proving owner/version movement,
  * the generated UI document read (GET_GENERATED_UI_STRUCTURE),
  * the compact window interaction read.

Every response is length-framed, required to end with END, parsed with the SDK
client, and stored raw so a truncated reply cannot pass as a snapshot.

Usage: python3 main_core_public_chain.py --out DIR --name TEXT [--port P]
Exit: 0 all steps complete; 2 transport/protocol failure.
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
MAX_FRAME_BYTES = 8 * 1024 * 1024
RESOURCE_ID = 9700


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


def exchange(port: int, lines) -> str:
    payload = "\n".join(lines)
    with socket.create_connection(("127.0.0.1", port), timeout=8) as sock:
        sock.sendall(frame(payload))
        raw = read_exact_frame(sock)
    if not raw.rstrip().endswith("END"):
        raise ConnectionError("missing END terminator")
    return raw


def context(port: int):
    raw = exchange(port, [f"PROTOCOL {PROTOCOL}", f"AUTH {CAPABILITY}", "GET_CONTEXT 0"])
    parsed = parse_response(raw)
    version = None
    fields = {}
    for name, parts in parsed.entries:
        if name == "VERSION" and parts:
            version = int(parts[0])
        elif name == "FIELD" and len(parts) >= 4:
            field_id, field_type, rest = parts[1], parts[2], parts[3:]
            if field_type == "STRING" and rest:
                fields[field_id] = bytes.fromhex(rest[-1]).decode("utf-8")
            else:
                fields[field_id] = rest[-1] if rest else None
    return version, fields, raw


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--port", type=int, default=17856)
    args = parser.parse_args()
    os.makedirs(args.out, exist_ok=True)
    record = {"complete": False, "steps": []}

    try:
        before_version, before_fields, before_raw = context(args.port)
        record["before"] = {"version": before_version, "fields": before_fields, "raw": before_raw}

        encoded = args.name.encode("utf-8")
        invoke = exchange(args.port, [
            f"PROTOCOL {PROTOCOL}", f"AUTH {CAPABILITY}",
            f"INVOKE {before_version} EDIT_NAME 1 1",
            f"ID {RESOURCE_ID}",
            f"ARG text STRING {len(encoded)} {encoded.hex().upper()}",
        ])
        record["invoke"] = {"expected_version": before_version, "action": "EDIT_NAME",
                            "name": args.name, "raw": invoke}

        after_version, after_fields, after_raw = context(args.port)
        record["after"] = {"version": after_version, "fields": after_fields, "raw": after_raw}
        record["owner_write_applied"] = (
            after_version > before_version and after_fields.get("name") == args.name)

        structure = exchange(args.port, [
            f"PROTOCOL {PROTOCOL}", f"AUTH {CAPABILITY}", "GET_GENERATED_UI_STRUCTURE"])
        record["generated_structure"] = structure

        interaction = exchange(args.port, [
            f"PROTOCOL {PROTOCOL}", f"AUTH {CAPABILITY}", "GET_WINDOW_INTERACTION"])
        record["window_interaction"] = interaction

        record["complete"] = True
        path = os.path.join(args.out, "public_chain.json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(record, handle, ensure_ascii=False, indent=2)
        print(f"PUBLIC-CHAIN complete before_version={before_version} after_version={after_version} "
              f"name={after_fields.get('name')} owner_write={record['owner_write_applied']} path={path}")
        return 0
    except Exception as error:  # noqa: BLE001 - report the actual transport/parse failure
        record["failure"] = str(error)
        path = os.path.join(args.out, "public_chain_failed.json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(record, handle, ensure_ascii=False, indent=2)
        print(f"PUBLIC-CHAIN-INCOMPLETE: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
