#!/usr/bin/env python3
"""Read the normal generated PNG endpoint through its public socket API."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

CORE = Path(__file__).resolve().parents[2] / "shared_operation_core"
sys.path.insert(0, str(CORE))
import client  # noqa: E402


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def descriptor_from_log(path: Path) -> Path:
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = re.search(r"CJGUI_COLLABORATION_READY DESCRIPTOR_PATH (\S+)", line)
        if match:
            return Path(match.group(1))
    raise AssertionError("generated application descriptor was not logged")


def generated_read(operation: client.SharedOperationClient, command: str, kind: str) -> client.SharedOperationResponse:
    payload = f"PROTOCOL {client.PROTOCOL}\nAUTH {operation.descriptor['capability']}\n{command}"
    result = operation.request(payload)
    require(result.kind == kind, f"{command} failed: {result.raw}")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("application_log", type=Path)
    args = parser.parse_args()
    operation = client.SharedOperationClient.from_descriptor(descriptor_from_log(args.application_log))
    capabilities = generated_read(operation, "GET_GENERATED_UI_CAPABILITIES", "GENERATED_UI_CAPABILITIES")
    structure = generated_read(operation, "GET_GENERATED_UI_STRUCTURE", "GENERATED_UI_STRUCTURE")
    instances = generated_read(operation, "GET_GENERATED_UI_INSTANCES", "GENERATED_UI_INSTANCES")

    require("TRANSFER_ENDPOINT_METADATA image/png roles=TARGET,SOURCE" in capabilities.raw,
            "public catalog omitted the PNG roles")
    for token in ("max_bytes=524288", "queue_bytes=2097152", "system_format=public.png",
                  "file_url_format=public.file-url",
                  "file_source_order=local_file_url,pasteboard_png",
                  "system_fetch_preflight_bounded=false", "binding=accepted_generated_scene_snapshot",
                  "status=provider_connected"):
        require(token in capabilities.raw, f"public catalog omitted {token}")
    version = structure.integer("STRUCTURE_VERSION")
    require(version > 0 and instances.integer("STRUCTURE_VERSION") == version,
            "accepted structure and instances did not identify the same version")

    discovered: dict[str, tuple[str, str]] = {}
    for key, role in (("generatedPngTarget", "TARGET"), ("generatedPngSource", "SOURCE")):
        require(re.search(rf"(?m)^NODE \d+ {key} action action=PNG_TRANSFER_ENDPOINT$", structure.raw) is not None,
                f"accepted structure omitted {key}")
        require(re.search(rf"(?m)^PROPERTY \d+ {key} transferRole {role}$", structure.raw) is not None,
                f"accepted structure omitted the {key} role")
        require(re.search(rf"(?m)^PROPERTY \d+ {key} transferFormat image/png$", structure.raw) is not None,
                f"accepted structure omitted the {key} format")
        if role == "TARGET":
            require(re.search(rf"(?m)^PROPERTY \d+ {key} transferFileSource local_file_url$",
                              structure.raw) is not None,
                    "accepted generated target omitted local file opt-in")
        match = re.search(rf"(?m)^INSTANCE {key} .*\bid=(\d+) .*\bsemantic=(\S+) "
                          rf".*\benabled=([01]) .*\bvisible=([01])", instances.raw)
        require(match is not None and int(match.group(1)) > 0 and match.group(3) == "1",
                f"accepted instance omitted enabled {key} identity")
        if role == "TARGET":
            require(match.group(4) == "1", "generated PNG target is clipped out of the normal viewport")
        discovered[key] = (match.group(1), match.group(2))

    print(f"png generated client passed structure_version={version} "
          f"target={discovered['generatedPngTarget']} source={discovered['generatedPngSource']} "
          "format=image/png standard_uti=public.png")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError) as exc:
        print(f"png generated client failed: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
