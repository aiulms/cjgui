#!/usr/bin/env python3
"""Consume one running normal OHOS application's generated-UI public endpoint.

The caller owns an existing target-bound hdc forward and supplies its creation
receipt. This script only reads `hdc fport ls` and `pidof`; it never builds,
installs, starts, stops, creates/removes forwards, or drives the screen.

Run once without --candidate-file to save public discovery for an external
author or model. Run again with its complete GENERATED_UI_STRUCTURE payload to
submit it, read the exact ticket, accepted structure, owner, and scene snapshot.
Each invocation uses a fresh --run-dir. A model reply may be preserved with
--model-reply-file, but this script does not invoke or certify a model. The
result is protocol evidence, not a screenshot or visual presentation claim.

--forward-receipt-json is the saved result of the caller's successful creation
command, for example:
  {"target":"127.0.0.1:5555","local_port":17932,"device_port":7856,
   "command":["hdc","-t","127.0.0.1:5555","fport","tcp:17932","tcp:7856"],
   "returncode":0,"stdout":"Forwardport result:OK","stderr":""}

Example:
  python3 verify_normal_generated_consumption.py \\
    --app settings --target 127.0.0.1:5555 --local-port 17932 \\
    --device-port 7856 --capability "$AUTH" --hap /path/to/normal.hap \\
    --identity /path/to/h_input_runtime_identity.txt \\
    --forward-receipt-json /path/to/fport_create.json \\
    --run-dir /tmp/h-generated-discover-1

  python3 verify_normal_generated_consumption.py \\
    [same identity/forward arguments] --candidate-file /path/to/candidate.txt \\
    --model-reply-file /path/to/original-model-reply.txt \\
    --run-dir /tmp/h-generated-submit-1
"""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from typing import Any

CORE = Path(__file__).resolve().parents[3] / "shared_operation_core"
if str(CORE) not in sys.path:
    sys.path.insert(0, str(CORE))

from client import PROTOCOL, SharedOperationClient, SharedOperationResponse  # noqa: E402
from cjgui_generated_client import (  # noqa: E402
    GeneratedNode, GeneratedUiSession, parse_action_signatures,
    parse_generated_structure, same_structure,
)
from client import parse_response  # noqa: E402


DEFAULT_HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/"
               "openharmony/toolchains/hdc")
APP_CONTRACT = {
    "settings": ("com.example.cjguiapp", "name", 9700, 7856),
    "thermo": ("com.example.cjguithermo", "note", 9801, 7857),
}
MAP_ROW = re.compile(r"(?:^|\s)(\S+)\s+tcp:(\d+)\s+(\S+)\s+\[Forward\]")


def write_json(path: Path, value: Any) -> None:
    with path.open("x", encoding="utf-8") as output:
        json.dump(value, output, ensure_ascii=False, indent=2, sort_keys=True)
        output.write("\n")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


def elapsed_ms(started_ns: int) -> float:
    return round((time.perf_counter_ns() - started_ns) / 1_000_000, 3)


class ReadOnlyHdc:
    def __init__(self, binary: str, target: str):
        self.binary, self.target = binary, target
        self.commands: list[dict[str, object]] = []

    def _run(self, command: list[str]) -> str:
        started = time.perf_counter_ns()
        result = subprocess.run(command, capture_output=True, text=True, timeout=30)
        self.commands.append({
            "command": command, "returncode": result.returncode,
            "stdout": result.stdout, "stderr": result.stderr,
            "duration_ms": round((time.perf_counter_ns() - started) / 1_000_000, 3),
        })
        if result.returncode:
            raise ValueError(f"read-only hdc command failed ({result.returncode}): {command!r}")
        return result.stdout

    def listing(self) -> str:
        return self._run([self.binary, "fport", "ls"])

    def pidof(self, bundle: str) -> str:
        return self._run([self.binary, "-t", self.target, "shell", f"pidof {bundle}"])


class ExchangeRecorder:
    """Records each actual typed-client exchange, without writing AUTH secrets."""

    def __init__(self, path: Path):
        self.path = path
        self.phase = "discovery"
        with path.open("x", encoding="utf-8"):
            pass

    def append(self, record: dict[str, object]) -> None:
        with self.path.open("a", encoding="utf-8") as output:
            output.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")


@dataclass(frozen=True)
class RecordingClient(SharedOperationClient):
    underlying: SharedOperationClient | None = None
    recorder: ExchangeRecorder | None = None

    def request(self, payload: str, *, timeout_seconds: float | None = None,
                deadline_monotonic: float | None = None) -> SharedOperationResponse:
        assert self.underlying is not None and self.recorder is not None
        lines = payload.splitlines()
        command = lines[2] if len(lines) >= 3 else "malformed_request"
        started_utc = utc_now()
        started = time.perf_counter_ns()
        record: dict[str, object] = {
            "phase": self.recorder.phase, "command": command,
            "started_utc": started_utc,
        }
        try:
            response = self.underlying.request(
                payload, timeout_seconds=timeout_seconds,
                deadline_monotonic=deadline_monotonic)
            record["response_kind"] = response.kind
            record["raw_response"] = response.raw
            record["response_bytes"] = len(response.raw.encode("utf-8"))
            return response
        except Exception as exc:
            record["error_type"] = type(exc).__name__
            record["error"] = str(exc)
            raise
        finally:
            record["duration_ms"] = round((time.perf_counter_ns() - started) / 1_000_000, 3)
            self.recorder.append(record)


def _identity(raw: str, target: str, hap: Path) -> str:
    entries: dict[str, str] = {}
    for line in raw.splitlines():
        if not line.strip():
            continue
        key, separator, value = line.partition("=")
        if not separator or key in entries:
            raise ValueError("run identity has an invalid or repeated key")
        entries[key] = value
    digest = hashlib.sha256(hap.read_bytes()).hexdigest()
    pid = entries.get("pid", "")
    if (entries.get("target") != target or entries.get("hap_sha256") != digest
            or entries.get("build_variant") != "normal"
            or not re.fullmatch(r"[1-9]\d*", pid)):
        raise ValueError("run identity does not bind target/PID/current normal HAP")
    return pid


def _receipt(raw: dict[str, object], target: str, local_port: int, device_port: int) -> None:
    command = raw.get("command", raw.get("cmd"))
    expected_command_tail = ["-t", target, "fport", f"tcp:{local_port}",
                             f"tcp:{device_port}"]
    if (raw.get("target") != target or raw.get("local_port") != local_port
            or raw.get("device_port") != device_port
            or raw.get("returncode", raw.get("rc")) != 0
            or not isinstance(command, list) or command[-5:] != expected_command_tail
            or "Forwardport result:OK" not in str(raw.get("stdout", ""))
            or "[Fail]" in str(raw.get("stdout", ""))
            or "[Fail]" in str(raw.get("stderr", ""))):
        raise ValueError("forward receipt does not bind the requested successful mapping")


def _forward_map(listing: str, target: str, local_port: int, device_port: int) -> None:
    matches = [(match.group(1), match.group(3)) for line in listing.splitlines()
               if (match := MAP_ROW.search(line)) and int(match.group(2)) == local_port]
    if matches != [(target, f"tcp:{device_port}")]:
        raise ValueError(f"forward mapping mismatch for local port {local_port}: {matches!r}")


def check_binding(args: argparse.Namespace, hdc: ReadOnlyHdc, *, expected_pid: str,
                  receipt: dict[str, object]) -> dict[str, object]:
    _receipt(receipt, args.target, args.local_port, args.device_port)
    listing = hdc.listing()
    _forward_map(listing, args.target, args.local_port, args.device_port)
    bundle = APP_CONTRACT[args.app][0]
    pidof = hdc.pidof(bundle)
    if pidof.strip() != expected_pid:
        raise ValueError(f"normal app PID changed or ambiguous: {pidof.strip()!r}")
    return {"checked_utc": utc_now(), "target": args.target, "bundle": bundle,
            "pid": expected_pid, "local_port": args.local_port,
            "device_port": args.device_port, "fport_ls_raw": listing,
            "pidof_raw": pidof}


def parse_owner(response: SharedOperationResponse, field_id: str,
                resource_id: int) -> dict[str, object]:
    if response.kind != "SNAPSHOT":
        raise ValueError(f"owner readback is {response.kind}, expected SNAPSHOT")
    versions = [tokens for label, tokens in response.entries if label == "VERSION"]
    fields = [tokens for label, tokens in response.entries if label == "FIELD"
              and len(tokens) >= 2 and tokens[0] == str(resource_id) and tokens[1] == field_id]
    if (len(versions) != 1 or len(versions[0]) != 1 or not versions[0][0].isdigit()
            or len(fields) != 1 or len(fields[0]) != 5 or fields[0][2] != "STRING"
            or not fields[0][3].isdigit()):
        raise ValueError("owner snapshot has no exact version/STRING field")
    try:
        encoded = b"" if fields[0][4] == "-" else bytes.fromhex(fields[0][4])
        value = encoded.decode("utf-8")
    except (ValueError, UnicodeDecodeError) as exc:
        raise ValueError("owner field is not valid UTF-8 hex") from exc
    if len(encoded) != int(fields[0][3]):
        raise ValueError("owner field byte count differs from payload")
    return {"version": int(versions[0][0]), "field_id": field_id,
            "resource_id": resource_id, "value": value}


def candidate_nodes(payload: str) -> tuple[GeneratedNode, ...]:
    lines = payload.rstrip("\n").split("\n")
    if len(lines) < 2 or lines[0] != "GENERATED_UI_STRUCTURE 1" or lines[-1] != "END":
        raise ValueError("candidate must be a complete GENERATED_UI_STRUCTURE 1 payload")
    synthetic = "\n".join((
        f"PROTOCOL {PROTOCOL}", "KIND GENERATED_UI_STRUCTURE",
        "STRUCTURE_VERSION 0", "CANDIDATE_VERSION 0", "SCENE_STATE none",
        f"STRUCTURE_LENGTH {len(lines) - 2}", *lines[1:-1], "END",
    ))
    return parse_generated_structure(parse_response(synthetic)).nodes


def run_workflow(args: argparse.Namespace, hdc: ReadOnlyHdc) -> dict[str, object]:
    """Run against the supplied read-only HDC and real forwarded TCP endpoint."""
    if args.app not in APP_CONTRACT:
        raise ValueError("unknown normal application")
    bundle, field_id, resource_id, app_port = APP_CONTRACT[args.app]
    if args.device_port != app_port:
        raise ValueError("device port does not match the normal application")
    if args.wait_ms < 0 or args.poll_ms <= 0:
        raise ValueError("candidate wait bounds are invalid")
    if args.model_reply_file is not None and args.candidate_file is None:
        raise ValueError("model reply requires a candidate file")

    out = Path(args.run_dir)
    out.mkdir(parents=True, exist_ok=False)
    try:
        return _run(args, hdc, out, bundle, field_id, resource_id)
    except Exception as exc:
        write_json(out / "failure.json", {
            "failed_utc": utc_now(), "error_type": type(exc).__name__, "error": str(exc),
            "hdc_commands": getattr(hdc, "commands", []),
        })
        raise


def _run(args: argparse.Namespace, hdc: ReadOnlyHdc, out: Path, bundle: str,
         field_id: str, resource_id: int) -> dict[str, object]:
    hap = Path(args.hap)
    identity_raw = Path(args.identity).read_text(encoding="utf-8")
    expected_pid = _identity(identity_raw, args.target, hap)
    receipt_raw = Path(args.forward_receipt_json).read_text(encoding="utf-8")
    receipt = json.loads(receipt_raw)
    if not isinstance(receipt, dict):
        raise ValueError("forward receipt JSON must be an object")
    with (out / "identity.raw.txt").open("x", encoding="utf-8") as saved:
        saved.write(identity_raw)
    with (out / "forward_receipt.raw.json").open("x", encoding="utf-8") as saved:
        saved.write(receipt_raw)
    binding_started = time.perf_counter_ns()
    first_binding = check_binding(args, hdc, expected_pid=expected_pid, receipt=receipt)
    timings_ms = {"initial_binding": elapsed_ms(binding_started)}
    recorder = ExchangeRecorder(out / "exchanges.jsonl")
    session = GeneratedUiSession.connect_forwarded_tcp(
        target=args.target, local_port=args.local_port, device_port=args.device_port,
        capability=args.capability, caller=args.caller)
    session.client = RecordingClient(session.client.descriptor, session.client.fragment_bytes,
                                     session.client, recorder)
    discovery_started = time.perf_counter_ns()
    capabilities = session.capabilities()
    before_structure = session.structure()
    fields_before = session.fields()
    instances_before = session.instances()
    owner_context = session.client.get_context()
    owner_before = parse_owner(owner_context, field_id, resource_id)
    action_signatures = parse_action_signatures(owner_context)
    timings_ms["discovery"] = elapsed_ms(discovery_started)
    write_json(out / "model_discovery.json", {
        "capabilities": asdict(capabilities),
        "action_signatures": [asdict(signature) for signature in action_signatures],
        "accepted_structure": asdict(before_structure),
    })
    discovery = {
        "app": args.app, "bundle": bundle, "target": args.target, "pid": expected_pid,
        "hap_sha256": hashlib.sha256(hap.read_bytes()).hexdigest(),
        "build_variant": "normal", "local_port": args.local_port,
        "device_port": args.device_port, "capabilities": asdict(capabilities),
        "structure": asdict(before_structure), "fields": [asdict(v) for v in fields_before],
        "instances": asdict(instances_before), "owner": owner_before,
    }
    write_json(out / "discovery.json", discovery)

    if args.candidate_file is None:
        final_binding_started = time.perf_counter_ns()
        final_binding = check_binding(args, hdc, expected_pid=expected_pid, receipt=receipt)
        timings_ms["final_binding"] = elapsed_ms(final_binding_started)
        summary: dict[str, object] = {
            "status": "discovered", "discovery": "discovery.json",
            "model_discovery": "model_discovery.json",
            "exchanges": "exchanges.jsonl", "binding_checks": [first_binding, final_binding],
            "timings_ms": timings_ms,
            "hdc_commands": getattr(hdc, "commands", []),
        }
        write_json(out / "result.json", summary)
        return summary

    candidate_path = Path(args.candidate_file)
    candidate_bytes = candidate_path.read_bytes()
    payload = candidate_bytes.decode("utf-8")
    with (out / "candidate.raw.txt").open("xb") as candidate_copy:
        candidate_copy.write(candidate_bytes)
    model_reply_sha256: str | None = None
    if args.model_reply_file is not None:
        shutil.copyfile(args.model_reply_file, out / "model_reply.raw.txt")
        model_reply_sha256 = hashlib.sha256(
            (out / "model_reply.raw.txt").read_bytes()).hexdigest()
    before_submit_binding_started = time.perf_counter_ns()
    before_submit_binding = check_binding(args, hdc, expected_pid=expected_pid, receipt=receipt)
    timings_ms["before_submit_binding"] = elapsed_ms(before_submit_binding_started)
    recorder.phase = "submit"
    submit_started = time.perf_counter_ns()
    submitted = session.submit_text(payload, before_structure.version)
    timings_ms["submit"] = elapsed_ms(submit_started)
    ticket = submitted.ticket()
    ticket_wait_started = time.perf_counter_ns()
    wait = session.wait_for_candidate_result(ticket, timeout_ms=args.wait_ms,
                                             poll_ms=args.poll_ms)
    timings_ms["ticket_wait"] = elapsed_ms(ticket_wait_started)
    recorder.phase = "readback"
    readback_started = time.perf_counter_ns()
    if wait.last_state is not None and wait.last_state.terminal_state == "ACCEPTED":
        structure_wait = session.wait_for_structure(
            wait.last_state.accepted_version, timeout_ms=args.wait_ms, poll_ms=args.poll_ms)
        after_structure = structure_wait.structure
    else:
        structure_wait = None
        after_structure = session.structure()
    snapshot = session.snapshot()
    fields_after = session.fields()
    instances_after = session.instances()
    owner_after = parse_owner(session.client.get_context(), field_id, resource_id)
    timings_ms["readback"] = elapsed_ms(readback_started)
    final_binding_started = time.perf_counter_ns()
    final_binding = check_binding(args, hdc, expected_pid=expected_pid, receipt=receipt)
    timings_ms["final_binding"] = elapsed_ms(final_binding_started)
    try:
        expected_nodes = candidate_nodes(payload)
        candidate_parse_error = ""
    except (ValueError, RuntimeError) as exc:
        # Let the public application decide malformed candidates. A local parser
        # must not erase the endpoint's named rejection or its exact ticket.
        expected_nodes = ()
        candidate_parse_error = str(exc)
    matched = bool(not candidate_parse_error and after_structure is not None
                   and same_structure(expected_nodes, after_structure.nodes))
    state = wait.last_state
    owner_unchanged = owner_before == owner_after
    accepted = bool(
        submitted.candidate_accepted and wait.outcome == "terminal" and state is not None
        and state.terminal_state == "ACCEPTED" and state.scene_state == "scene_accepted"
        and after_structure is not None and structure_wait is not None
        and structure_wait.outcome == "reached"
        and state.accepted_version == after_structure.version and matched
        and snapshot.accepted_structure_version == after_structure.version
        and not snapshot.structure_candidate_pending and not snapshot.owner_pending_scene
    )
    summary = {
        "status": "accepted" if accepted else "not_accepted",
        "candidate_sha256": hashlib.sha256(candidate_bytes).hexdigest(),
        "candidate_file": "candidate.raw.txt", "discovery": "discovery.json",
        "model_reply_file": "model_reply.raw.txt" if model_reply_sha256 else None,
        "model_reply_sha256": model_reply_sha256,
        "model_discovery": "model_discovery.json",
        "exchanges": "exchanges.jsonl", "submit": asdict(submitted),
        "ticket_identity": asdict(ticket), "ticket_wait_outcome": wait.outcome,
        "ticket_attempted_reads": wait.attempted,
        "ticket": asdict(state) if state is not None else None,
        "structure_wait_outcome": structure_wait.outcome if structure_wait is not None else None,
        "accepted_structure": asdict(after_structure) if after_structure is not None else None,
        "candidate_matches_accepted_structure": matched,
        "candidate_local_parse_error": candidate_parse_error,
        "snapshot": asdict(snapshot),
        "fields_after": [asdict(v) for v in fields_after],
        "instances_after": asdict(instances_after),
        "owner_before": owner_before, "owner_after": owner_after,
        "owner_unchanged_during_structure_submit": owner_unchanged,
        "binding_checks": [first_binding, before_submit_binding, final_binding],
        "timings_ms": timings_ms,
        "hdc_commands": getattr(hdc, "commands", []),
        "presentation_evidence": "requires independent normal-HAP screenshot and system input",
    }
    write_json(out / "result.json", summary)
    return summary


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--app", choices=sorted(APP_CONTRACT), required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--local-port", type=int, required=True)
    parser.add_argument("--device-port", type=int, required=True)
    parser.add_argument("--capability", required=True)
    parser.add_argument("--caller", default="normal-generated-consumer")
    parser.add_argument("--hap", type=Path, required=True)
    parser.add_argument("--identity", type=Path, required=True)
    parser.add_argument("--forward-receipt-json", type=Path, required=True)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--candidate-file", type=Path)
    parser.add_argument("--model-reply-file", type=Path)
    parser.add_argument("--wait-ms", type=int, default=5000)
    parser.add_argument("--poll-ms", type=int, default=50)
    parser.add_argument("--hdc", default=DEFAULT_HDC)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        result = run_workflow(args, ReadOnlyHdc(args.hdc, args.target))
    except Exception as exc:
        print(f"normal generated consumption failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"status": result["status"], "run_dir": str(args.run_dir)},
                     ensure_ascii=False))
    return 0 if result["status"] in ("discovered", "accepted") else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
