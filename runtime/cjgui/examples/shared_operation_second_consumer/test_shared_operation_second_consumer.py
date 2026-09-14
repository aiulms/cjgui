#!/usr/bin/env python3
"""Actual v2 socket acceptance for the list's pure-core second consumer."""

from __future__ import annotations

import os
import socket
import stat
import subprocess
import sys
from pathlib import Path


CONSUMER_ROOT = Path(__file__).resolve().parent
CORE_ROOT = CONSUMER_ROOT.parents[1] / "shared_operation_core"
CLIENT = CORE_ROOT / "client.py"
CONSUMER = CONSUMER_ROOT / "target/release/bin/main"
CAPABILITY = "second-consumer-acceptance-capability"
WRITABLE_ID = 7127
LURE_ID = 7199


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def launch(max_clients: int) -> tuple[subprocess.Popen[str], Path]:
    environment = dict(os.environ)
    environment["CJGUI_SECOND_CONSUMER_CAPABILITY"] = CAPABILITY
    toolchain = Path(environment.get("CANGJIE_HOME", "/Users/jiangxuanyang/cangjie-toolchains/cangjie"))
    runtime = toolchain / "runtime/lib/darwin_aarch64_cjnative"
    require(runtime.exists(), "Cangjie runtime is unavailable")
    environment["DYLD_LIBRARY_PATH"] = f"{runtime}:{environment['DYLD_LIBRARY_PATH']}" if environment.get("DYLD_LIBRARY_PATH") else str(runtime)
    process = subprocess.Popen(
        [str(CONSUMER), "--max-clients", str(max_clients)],
        cwd=CONSUMER_ROOT,
        env=environment,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert process.stdout is not None
    ready = process.stdout.readline().strip()
    prefix = "CJGUI_READY_V2 DESCRIPTOR_PATH_UTF8_HEX "
    require(ready.startswith(prefix), f"consumer was not ready: {ready!r}")
    size, encoded_path = ready[len(prefix) :].split(" ", 1)
    descriptor = Path(bytes.fromhex(encoded_path).decode("utf-8"))
    require(len(str(descriptor).encode("utf-8")) == int(size), "descriptor length mismatch")
    require(stat.S_IMODE(descriptor.stat().st_mode) == 0o600, "descriptor is not 0600")
    return process, descriptor


def generic_client(descriptor: Path, *arguments: str, expected_codes: tuple[int, ...] = (0,)) -> str:
    completed = subprocess.run(
        [sys.executable, str(CLIENT), str(descriptor), *arguments],
        text=True,
        capture_output=True,
        check=False,
    )
    require(
        completed.returncode in expected_codes,
        f"generic client returned {completed.returncode}: {completed.stderr}",
    )
    return completed.stdout


def socket_path(descriptor: Path) -> str:
    for line in descriptor.read_text(encoding="utf-8").splitlines():
        fields = line.split(" ")
        if len(fields) == 3 and fields[0] == "SOCKET_PATH_UTF8_HEX":
            return bytes.fromhex(fields[2]).decode("utf-8")
    raise AssertionError("descriptor socket path missing")


def wrong_capability(socket_name: str) -> str:
    payload = b"PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH not-granted\nGET_CONTEXT 0"
    frame = str(len(payload)).encode("ascii") + b"\n" + payload
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(2)
        connection.connect(socket_name)
        for index in range(0, len(frame), 3):
            connection.sendall(frame[index : index + 3])
        response = bytearray()
        while b"\n" not in response:
            response.extend(connection.recv(4096))
        header, body = response.split(b"\n", 1)
        while len(body) < int(header):
            body.extend(connection.recv(4096))
        return bytes(body).decode("utf-8")


def wait_success(process: subprocess.Popen[str]) -> None:
    code = process.wait(timeout=5)
    require(code == 0, f"consumer exited {code}: {process.stderr.read() if process.stderr else ''}")


def main() -> int:
    require(CONSUMER.exists(), "build second consumer before acceptance")
    primary, primary_descriptor = launch(7)
    secondary, secondary_descriptor = launch(1)
    try:
        description = generic_client(primary_descriptor, "describe")
        require("ACTION GET_CONTEXT" in description and "ACTION SET_MARKED PARAMETERS 1 TARGETS 1 1024" in description, "descriptor did not discover generic list actions")
        require("ACTION TOGGLE" not in description, "ungranted action leaked through discovery")
        require(socket_path(primary_descriptor) != socket_path(secondary_descriptor), "two independent processes shared an endpoint")

        secondary_snapshot = generic_client(secondary_descriptor, "get")
        require("RESOURCE 7127" in secondary_snapshot and "RESOURCE 7199" in secondary_snapshot, "second process did not expose its own list")
        wait_success(secondary)

        initial = generic_client(primary_descriptor, "--fragment-bytes", "5", "get")
        require("VERSION 0" in initial and "RESOURCE 7127" in initial, "fragmented generic GET_CONTEXT failed")

        applied = generic_client(
            primary_descriptor,
            "invoke",
            "0",
            "SET_MARKED",
            "--target",
            str(WRITABLE_ID),
            "--arg",
            "isMarked=BOOLEAN:true",
        )
        require("APPLIED true" in applied and "VERSION_AFTER 1" in applied, "generic list action did not apply")

        read_back = generic_client(primary_descriptor, "get", "--target", str(WRITABLE_ID))
        require("FIELD 7127 isMarked BOOLEAN 1" in read_back, "list change was not read back")

        outside_scope = generic_client(
            primary_descriptor,
            "invoke",
            "1",
            "SET_MARKED",
            "--target",
            str(LURE_ID),
            "--arg",
            "isMarked=BOOLEAN:true",
            expected_codes=(5,),
        )
        require("ERROR unauthorized_resource" in outside_scope, "write scope was bypassed")

        denied = wrong_capability(socket_path(primary_descriptor))
        require("ERROR unauthorized_caller" in denied, "capability check was bypassed")

        stale = generic_client(
            primary_descriptor,
            "invoke",
            "0",
            "SET_MARKED",
            "--target",
            str(WRITABLE_ID),
            "--arg",
            "isMarked=BOOLEAN:false",
            expected_codes=(4,),
        )
        require("CONFLICT true" in stale and "VERSION_AFTER 1" in stale, "stale list action did not fail closed")

        final = generic_client(primary_descriptor, "get", "--target", str(WRITABLE_ID))
        require("VERSION 1" in final and "FIELD 7127 isMarked BOOLEAN 1" in final, "rejected calls changed list truth")
        wait_success(primary)
    finally:
        for process in (primary, secondary):
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
        require(not primary_descriptor.exists(), "primary descriptor survived cleanup")
        require(not secondary_descriptor.exists(), "secondary descriptor survived cleanup")
    print("shared_operation_second_consumer acceptance passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
