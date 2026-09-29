#!/usr/bin/env python3
"""Long-lived public shared-operation driver for the dual-window latency probe.

One process, one :class:`SharedOperationClient`, one public INVOKE per sample.
The script never writes business state: it only writes probe-coordination
marker files and calls the public descriptor-gated client API. It reuses the
real `shared_operation_core/client.py` module (imported through sys.path), so
no parsing or framing logic is duplicated here.

Coordination contract with the Cangjie probe (`--latency-only`):

* the run launcher (the verifier shell script) publishes `latency-armed`; both
  this driver and the probe wait for it, so the driver's single
  pre-measurement GET_CONTEXT cannot race the ready observer's per-sample
  accounting;
* for sample ``i`` this driver writes ``latency-request-<i>`` immediately
  before sending the invoke, then saves the raw response to
  ``latency-response-<i>.txt`` and waits for ``latency-accepted-<i>`` before
  starting sample ``i + 1``.

Exactly one public request is in flight at any time, and the driver performs
no GET/poll between the first sample and the last.
"""

from __future__ import annotations

import argparse
import pathlib
import sys
import time
from typing import Sequence

DOCUMENT_B = 7302
SUCCESS_PREFIX = "CJGUI_INTERACTION_SCHEDULING_LATENCY_CLIENT"


def parse_values(spec: str) -> list[int]:
    """Parse a ``START-END`` inclusive range or a comma-separated value list."""

    text = spec.strip()
    if not text:
        raise ValueError("empty sample value specification")
    if "," not in text and "-" in text:
        start_text, end_text = text.split("-", 1)
        start = int(start_text)
        end = int(end_text)
        if end < start:
            raise ValueError("sample value range is reversed")
        return list(range(start, end + 1))
    values = [int(part) for part in text.split(",") if part.strip()]
    if not values:
        raise ValueError("empty sample value list")
    return values


def wait_for(path: pathlib.Path, timeout_seconds: float) -> bool:
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        if path.exists():
            return True
        time.sleep(0.002)
    return False


def shared_operation_core_dir() -> pathlib.Path:
    # native/scripts/latency_public_client.py -> cjgui/shared_operation_core
    return pathlib.Path(__file__).resolve().parents[2] / "shared_operation_core"


def load_public_client() -> object:
    directory = shared_operation_core_dir()
    entry = str(directory)
    if entry not in sys.path:
        sys.path.insert(0, entry)
    import client  # type: ignore  # the public module, never a local copy

    return client


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("descriptor", help="application-issued private descriptor path")
    result.add_argument("--ack-dir", required=True, help="probe coordination directory")
    result.add_argument(
        "--values",
        default="129-148",
        help="sample values as START-END (inclusive) or a comma-separated list",
    )
    result.add_argument("--target", type=int, default=DOCUMENT_B, help="target document resource id")
    result.add_argument("--gate-marker", help="send the first request after native submit gate opens")
    result.add_argument("--motion-ready", help="send the first request after window A starts motion")
    result.add_argument("--armed-timeout", type=float, default=60.0)
    result.add_argument("--accepted-timeout", type=float, default=15.0)
    return result


def fail(message: str) -> int:
    print(f"{SUCCESS_PREFIX} samples=0 valid=false reason={message}", flush=True)
    return 1


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    ack_directory = pathlib.Path(args.ack_dir)

    try:
        client = load_public_client()
    except Exception as error:  # pragma: no cover - defensive, loud failure
        return fail(f"client_import_error:{type(error).__name__}")

    try:
        values = parse_values(args.values)
    except ValueError as error:
        return fail(f"invalid_values:{error}")

    if len(values) != (1 if args.gate_marker else 20):
        return fail(f"unexpected_sample_count_{len(values)}")

    if not wait_for(ack_directory / "latency-armed", args.armed_timeout):
        return fail("armed_timeout")

    try:
        operation_client = client.SharedOperationClient.from_descriptor(args.descriptor)
        context = operation_client.get_context([args.target])
        version = context.integer("VERSION")
    except Exception as error:
        raw = context.raw if "context" in locals() else "<no response>"
        return fail(f"get_context_error:{type(error).__name__}:{error}:raw={raw!r}")
    print(f"{SUCCESS_PREFIX}_BASELINE target={args.target} version={version}", flush=True)
    (ack_directory / "latency-baseline-ready").write_text(
        f"version={version}\n", encoding="utf-8"
    )
    if args.motion_ready and not wait_for(pathlib.Path(args.motion_ready), args.armed_timeout):
        return fail("motion_ready_timeout")

    completed = 0
    for index, value in enumerate(values, start=1):
        if index == 1 and args.gate_marker and not wait_for(pathlib.Path(args.gate_marker), args.armed_timeout):
            return fail("submit_gate_timeout")
        request_path = ack_directory / f"latency-request-{index}"
        response_path = ack_directory / f"latency-response-{index}.txt"
        accepted_path = ack_directory / f"latency-accepted-{index}"
        request_path.write_text(f"index={index} value={value}\n", encoding="utf-8")
        try:
            response = operation_client.invoke(
                version,
                "SET_PREVIEW_LIMIT",
                [args.target],
                [client.SharedOperationArgument.integer("value", value)],
            )
        except Exception as error:
            return fail(f"invoke_error:index={index}:{type(error).__name__}")
        response_path.write_text(response.raw, encoding="utf-8")
        if response.kind != "RESULT":
            print(
                f"{SUCCESS_PREFIX} samples={completed} valid=false reason=remote_error "
                f"index={index} value={value} kind={response.kind} raw={response.raw!r}",
                flush=True,
            )
            return 1
        if not response.boolean("APPLIED"):
            print(
                f"{SUCCESS_PREFIX} samples={completed} valid=false reason=not_applied "
                f"index={index} value={value} raw={response.raw!r}",
                flush=True,
            )
            return 1
        version = response.integer("VERSION_AFTER")
        if not wait_for(accepted_path, args.accepted_timeout):
            print(
                f"{SUCCESS_PREFIX} samples={completed} valid=false reason=accepted_timeout "
                f"index={index} value={value} version_after={version}",
                flush=True,
            )
            return 1
        completed = index

    print(
        f"{SUCCESS_PREFIX} samples={completed} valid=true target={args.target} "
        f"first_value={values[0]} last_value={values[-1]} final_version={version}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
