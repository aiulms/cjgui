#!/usr/bin/env python3
"""Exercise imported PNG selection through an app-issued local descriptor.

The application must already be running with at least one accepted PNG image.
This probe reads its descriptor path from the captured stdout log and sends
ordinary CJGUI_SHARED_OPERATION/2 socket requests. It does not launch or build
the application.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re
import sys

CORE = Path(__file__).resolve().parents[2] / "shared_operation_core"
sys.path.insert(0, str(CORE))

import client  # noqa: E402


DESCRIPTOR_MARKER = "CJGUI_PNG_EXTERNAL_READY "


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def descriptor_from_log(log_path: Path) -> Path:
    for line in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        marker_index = line.find(DESCRIPTOR_MARKER)
        if marker_index < 0:
            continue
        details = line[marker_index + len(DESCRIPTOR_MARKER) :]
        match = re.search(r"(?:^|\s)descriptor=(\S+)", details)
        path = match.group(1) if match else ""
        if path and path != "unavailable":
            return Path(path)
    raise AssertionError(f"no application PNG owner descriptor found in {log_path}")


def field_values(response: client.SharedOperationResponse) -> dict[int, dict[str, tuple[str, str]]]:
    fields: dict[int, dict[str, tuple[str, str]]] = {}
    for values in response.values("FIELD"):
        require(len(values) >= 4, f"malformed FIELD entry: {values!r}")
        resource_id = int(values[0])
        name, value_type = values[1], values[2]
        if value_type == "STRING":
            require(len(values) == 5, f"malformed STRING field: {values!r}")
            byte_count = int(values[3])
            raw = b"" if values[4] == "-" else bytes.fromhex(values[4])
            require(len(raw) == byte_count, f"wrong UTF-8 byte count for {name}")
            text = raw.decode("utf-8")
        elif value_type == "INTEGER":
            require(len(values) == 4, f"malformed INTEGER field: {values!r}")
            text = values[3]
        elif value_type == "BOOLEAN":
            require(len(values) == 4 and values[3] in ("0", "1"),
                    f"malformed BOOLEAN field: {values!r}")
            text = "true" if values[3] == "1" else "false"
        else:
            raise AssertionError(f"unexpected PNG owner field type {value_type!r}")
        fields.setdefault(resource_id, {})[name] = (value_type, text)
    return fields


def integer(fields: dict[str, tuple[str, str]], name: str) -> int:
    value_type, value = fields[name]
    require(value_type == "INTEGER", f"{name} was not an integer")
    return int(value)


def text(fields: dict[str, tuple[str, str]], name: str) -> str:
    value_type, value = fields[name]
    require(value_type == "STRING", f"{name} was not a string")
    return value


def transfer_digest(payload: bytes) -> str:
    first, second = 2166136261 & 0x3FFFFFFF, 0x185AC1D
    for index, byte in enumerate(payload):
        first = ((first ^ byte) * 16777619) & 0x3FFFFFFF
        second = ((second ^ (byte + index)) * 65599) & 0x3FFFFFFF
    return f"fnv30x2:{first}:{second}:{len(payload)}"


def read_owner(operation: client.SharedOperationClient, owner_slot: int) -> tuple[int, dict[str, tuple[str, str]]]:
    response = operation.get_context((owner_slot,))
    require(response.kind == "SNAPSHOT", f"owner read failed: {response.raw}")
    by_resource = field_values(response)
    require(owner_slot in by_resource, "authorized snapshot omitted the owner slot")
    return response.integer("VERSION"), by_resource[owner_slot]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("application_log", type=Path, help="captured stdout containing DESCRIPTOR_PATH")
    parser.add_argument("--owner-slot", type=int, help="owner slot ID; discovered from GET_CONTEXT by default")
    parser.add_argument("--expected-png", type=Path, help="source PNG fixture whose bytes must match an owned digest")
    args = parser.parse_args()

    descriptor_path = descriptor_from_log(args.application_log)
    operation = client.SharedOperationClient.from_descriptor(descriptor_path)

    overview = operation.get_context()
    require(overview.kind == "SNAPSHOT", f"initial GET_CONTEXT failed: {overview.raw}")
    owner_slot = args.owner_slot
    if owner_slot is None:
        for resource_id, values in field_values(overview).items():
            if "ownerVersion" in values and "ownedImageCount" in values:
                owner_slot = resource_id
                break
    require(owner_slot is not None and owner_slot > 0, "PNG owner slot was not found in authorized GET_CONTEXT")
    assert owner_slot is not None

    version, state = read_owner(operation, owner_slot)
    count = integer(state, "ownedImageCount")
    require(0 < count <= 4, f"expected 1..4 imported images, got {count}")
    require(version > 0, "an imported image must have a positive owner version")
    available: list[tuple[int, str, int, int]] = []
    for index in range(count):
        prefix = f"ownedImage{index}"
        identity = integer(state, f"{prefix}ResourceId")
        digest = text(state, f"{prefix}Digest")
        width = integer(state, f"{prefix}Width")
        height = integer(state, f"{prefix}Height")
        encoded_bytes = integer(state, f"{prefix}EncodedBytes")
        require(identity > 0 and re.fullmatch(r"fnv30x2:[0-9]+:[0-9]+:[0-9]+", digest),
                "owned image identity or digest is malformed")
        require(width > 0 and height > 0 and encoded_bytes > 0, "owned image metadata is incomplete")
        available.append((identity, digest, width, height))

    current_identity = integer(state, "currentImageResourceId")
    if args.expected_png is not None:
        source_bytes = args.expected_png.read_bytes()
        source_digest = transfer_digest(source_bytes)
        require(any(item[1] == source_digest for item in available),
                f"no owned image matches source bytes digest {source_digest}")
    selected = next((item for item in available if item[0] != current_identity), available[0])
    selected_identity, selected_digest, selected_width, selected_height = selected
    # Existing GET_CONTEXT publishes authorized action metadata alongside the
    # context snapshot; no second discovery endpoint is introduced here.
    require("SELECT_OWNED_IMAGE" in overview.raw,
            "application descriptor did not disclose SELECT_OWNED_IMAGE")

    denied = operation.request(
        f"PROTOCOL {client.PROTOCOL}\nAUTH png-owner-probe-without-grant\nGET_CONTEXT 0")
    require(denied.kind == "ERROR" and denied.values("ERROR") and
            denied.values("ERROR")[0][0] == "unauthorized_caller",
            f"wrong capability was not rejected: {denied.raw}")

    unknown = operation.invoke(version, "SELECT_OWNED_IMAGE", (owner_slot,),
        (client.SharedOperationArgument.integer("resourceId", 0x7FFFFFFFFFFFFFFE),))
    require(unknown.kind == "RESULT" and unknown.values("APPLIED") == (("false",),),
            f"unknown image ID was not rejected by the owner: {unknown.raw}")
    require(read_owner(operation, owner_slot)[0] == version,
            "unknown image ID changed the owner version")

    stale = operation.invoke(version - 1, "SELECT_OWNED_IMAGE", (owner_slot,),
        (client.SharedOperationArgument.integer("resourceId", selected_identity),))
    require(stale.kind == "RESULT" and stale.values("CONFLICT") == (("true",),),
            f"stale version did not report a CAS conflict: {stale.raw}")
    require(read_owner(operation, owner_slot)[0] == version,
            "stale image selection changed the owner version")

    applied = operation.invoke(version, "SELECT_OWNED_IMAGE", (owner_slot,),
        (client.SharedOperationArgument.integer("resourceId", selected_identity),))
    require(applied.kind == "RESULT" and applied.values("APPLIED") == (("true",),),
            f"authorized image selection failed: {applied.raw}")
    require(applied.integer("VERSION_BEFORE") == version and
            applied.integer("VERSION_AFTER") == version + 1,
            f"selection did not advance exactly one owner version: {applied.raw}")

    final_version, final_state = read_owner(operation, owner_slot)
    require(final_version == version + 1, "exact readback has the wrong owner version")
    require(integer(final_state, "currentImageResourceId") == selected_identity,
            "exact readback selected a different image resource")
    require(text(final_state, "currentImageDigest") == selected_digest,
            "exact readback digest differs from the selected resource")
    require(integer(final_state, "currentImageWidth") == selected_width and
            integer(final_state, "currentImageHeight") == selected_height,
            "exact readback dimensions differ from the selected resource")
    print(f"png external owner passed slot={owner_slot} version={version}->{final_version} "
          f"resourceId={selected_identity} digest={selected_digest} size={selected_width}x{selected_height}" +
          (f" expected_sha256={hashlib.sha256(source_bytes).hexdigest()}" if args.expected_png is not None else ""))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError) as exc:
        print(f"png external owner failed: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
