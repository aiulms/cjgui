#!/usr/bin/env python3
"""Normal-HAP generated text control: real UITest input to exact owner readback.

The normal HAP and a target-bound forward must already be running. This script
checks the caller's forward-creation receipt, current mapping, PID, HAP hash and
accepted generated instance. It never creates/removes a forward, builds,
restarts, installs, clears hilog or claims to inspect screenshot pixels.

Choose ONE click location: exact screen --screen-x/--screen-y, or the accepted
instance's center plus --xcomponent-offset-x/--xcomponent-offset-y. The latter
requires a measured XComponent screen origin from this HAP session. The script
captures screenshots for visual review; image contents remain a separate check.

Example:
  python3 verify_normal_generated_gui_consumption.py \\
    --app settings --target 127.0.0.1:5555 --local-port 17932 --device-port 7856 \\
    --capability "$AUTH" --hap /path/to/normal.hap \\
    --identity /path/to/h_input_runtime_identity.txt \\
    --forward-receipt-json /path/to/fport_create.json \\
    --accepted-key edit --field name --xcomponent-offset-x 0 \\
    --xcomponent-offset-y 112 --replacement '新的名称' \\
    --run-dir /tmp/h-generated-gui-settings-1

The current scope is one generated text editor click, system selection/input/
submit, and exact owner readback. External owner modification, rejected
candidate continuation, same-key reorder draft/selection, and generated action
button routes require separate calls and evidence; they are marked not_run in
the summary rather than inferred from this input path.
"""

from __future__ import annotations

import argparse
from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import re
import shlex
import sys
import time
import uuid

import verify_current_normal_selection_replace as selection
import verify_normal_generated_consumption as normal
from cjgui_generated_client import GeneratedUiSession


class GuiHdc:
    """Existing probe Hdc, with only read-only identity and explicit UI calls."""

    def __init__(self, binary: str, target: str):
        self.underlying = selection.Hdc(binary, target)

    @property
    def commands(self) -> list[dict[str, object]]:
        return self.underlying.records

    def listing(self) -> str:
        return self.underlying.run("fport", "ls", global_list=True).stdout

    def pidof(self, bundle: str) -> str:
        return self.underlying.shell(f"pidof {bundle}")

    def shell(self, command: str, *, timeout: int = 45) -> str:
        return self.underlying.shell(command, timeout=timeout)

    def pull(self, remote: str, local: Path) -> None:
        self.underlying.run("file", "recv", remote, str(local), timeout=45)


def click_point(args: argparse.Namespace, instance) -> dict[str, object]:
    screen = args.screen_x is not None or args.screen_y is not None
    offset = args.xcomponent_offset_x is not None or args.xcomponent_offset_y is not None
    if screen == offset:
        raise ValueError("provide exactly one full screen point or XComponent offset pair")
    if screen:
        if args.screen_x is None or args.screen_y is None:
            raise ValueError("screen click point requires both x and y")
        x, y = args.screen_x, args.screen_y
        source = "caller_screen_point"
    else:
        if args.xcomponent_offset_x is None or args.xcomponent_offset_y is None:
            raise ValueError("XComponent offset requires both x and y")
        ix, iy, width, height = instance.bounds
        x = args.xcomponent_offset_x + ix + width // 2
        y = args.xcomponent_offset_y + iy + height // 2
        source = "instance_bounds_plus_xcomponent_offset"
    if not (0 <= x < 5000 and 0 <= y < 5000):
        raise ValueError("generated click point is outside bounded screen coordinates")
    return {"x": x, "y": y, "source": source}


def accepted_editor(instances, key: str, field: str):
    matches = [instance for instance in instances.instances
               if instance.key == key and instance.field_id == field]
    if len(matches) != 1:
        raise ValueError("accepted generated instance key/field is absent or ambiguous")
    instance = matches[0]
    if (not instance.visible or instance.kind != "textInput" or
            instance.bounds[2] <= 0 or instance.bounds[3] <= 0 or not instance.semantic_id):
        raise ValueError("accepted generated instance is not a visible text editor")
    return instance


def positive_draft(before_rows: list[str], after_rows: list[str], pid: str,
                   mount: str) -> list[int]:
    fresh = selection.fresh_rows(
        selection.app_rows("\n".join(before_rows), pid),
        selection.app_rows("\n".join(after_rows), pid))
    lengths: list[int] = []
    for line in fresh:
        match = re.search(r"ime proxy onChange len=(\d+) verdict=(\S+) mount=(\S+)$", line)
        if match:
            if match.group(2) != "ok" or match.group(3) != mount:
                raise ValueError("draft event belongs to another or rejected mount")
            lengths.append(int(match.group(1)))
    if not lengths or lengths[-1] <= 0:
        raise ValueError("system input produced no positive generated-field draft")
    return lengths


def validate_args(args: argparse.Namespace) -> None:
    if args.app not in normal.APP_CONTRACT:
        raise ValueError("unknown normal application")
    if args.device_port != normal.APP_CONTRACT[args.app][3]:
        raise ValueError("device port does not match this normal application")
    if not args.accepted_key or not args.field:
        raise ValueError("accepted key and field are required")
    if (not args.replacement or any(char in args.replacement for char in "\r\n\x00")
            or len(args.replacement.encode("utf-8")) > 4096):
        raise ValueError("replacement must be nonempty single-line UTF-8 within 4096 bytes")
    if args.settle_seconds < 0 or args.settle_seconds > 10:
        raise ValueError("settle seconds must be in 0..10")


def run_probe(args: argparse.Namespace, hdc: GuiHdc) -> dict[str, object]:
    validate_args(args)
    out = Path(args.run_dir)
    out.mkdir(parents=True, exist_ok=False)
    try:
        result = _run(args, hdc, out)
        normal.write_json(out / "result.json", result)
        return result
    except Exception as exc:
        normal.write_json(out / "failure.json", {
            "failed_utc": normal.utc_now(), "error_type": type(exc).__name__,
            "error": str(exc),
            "uncompleted_steps": ["visual screenshot review", "remaining generated GUI scenarios"],
        })
        raise
    finally:
        normal.write_json(out / "commands.json", getattr(hdc, "commands", []))


def _run(args: argparse.Namespace, hdc: GuiHdc, out: Path) -> dict[str, object]:
    hap = Path(args.hap)
    identity_raw = Path(args.identity).read_text(encoding="utf-8")
    pid = normal._identity(identity_raw, args.target, hap)
    receipt_raw = Path(args.forward_receipt_json).read_text(encoding="utf-8")
    receipt = json.loads(receipt_raw)
    if not isinstance(receipt, dict):
        raise ValueError("forward creation receipt JSON must be an object")
    (out / "identity.raw.txt").write_text(identity_raw, encoding="utf-8")
    (out / "forward_receipt.raw.json").write_text(receipt_raw, encoding="utf-8")

    bindings = [normal.check_binding(args, hdc, expected_pid=pid, receipt=receipt)]
    recorder = normal.ExchangeRecorder(out / "exchanges.jsonl")
    session = GeneratedUiSession.connect_forwarded_tcp(
        target=args.target, local_port=args.local_port, device_port=args.device_port,
        capability=args.capability, caller=args.caller)
    session.client = normal.RecordingClient(
        session.client.descriptor, session.client.fragment_bytes, session.client, recorder)
    capabilities = session.capabilities()
    field_spec = capabilities.field(args.field)
    if (field_spec is None or not field_spec.callable or
            field_spec.input_kind != "textInput"):
        raise ValueError("public capabilities do not declare a callable text field")
    before_structure = session.structure()
    before_instances = session.instances()
    before_snapshot = session.snapshot()
    before_fields = session.fields()
    if (before_structure.scene_state != "scene_accepted"
            or before_instances.structure_version != before_structure.version
            or before_snapshot.accepted_structure_version != before_structure.version
            or before_snapshot.structure_candidate_pending
            or before_snapshot.owner_pending_scene):
        raise ValueError("generated structure is not an accepted, settled normal scene")
    instance = accepted_editor(before_instances, args.accepted_key, args.field)
    point = click_point(args, instance)
    owner_before = normal.parse_owner(
        session.client.get_context(), args.field, field_spec.resource_id)
    if owner_before["value"] == args.replacement:
        raise ValueError("replacement already equals owner; an exact commit would be ambiguous")
    bindings.append(normal.check_binding(args, hdc, expected_pid=pid, receipt=receipt))

    actions: list[dict[str, object]] = []
    remote_files: list[str] = []
    remote_prefix = "/data/local/tmp/cjgui-h-generated-" + uuid.uuid4().hex

    def action(command: str, *, settle: float | None = None) -> None:
        started = time.perf_counter_ns()
        hdc.shell(command, timeout=45)
        time.sleep(args.settle_seconds if settle is None else settle)
        actions.append({"utc": normal.utc_now(), "command": command,
                        "duration_ms": normal.elapsed_ms(started)})

    def capture_hilog(label: str) -> list[str]:
        raw = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'", timeout=45)
        (out / f"hilog_{label}.txt").write_text(raw, encoding="utf-8")
        rows = selection.app_rows(raw, pid)
        if not rows:
            raise ValueError(f"no current-PID app hilog rows at {label}")
        return rows

    def pull(remote: str, local_name: str) -> Path:
        remote_files.append(remote)
        local = out / local_name
        hdc.pull(remote, local)
        if not local.is_file() or local.stat().st_size == 0:
            raise ValueError(f"device artifact was not received: {local_name}")
        return local

    def screenshot(label: str) -> None:
        remote = f"{remote_prefix}-{label}.jpeg"
        action("snapshot_display -f " + shlex.quote(remote), settle=0)
        pull(remote, f"screen_{label}.jpeg")

    try:
        before_log = capture_hilog("before")
        screenshot("before")
        action(f"uitest uiInput click {point['x']} {point['y']}")
        focus_log = capture_hilog("after_focus")
        mount = selection.assert_fresh_focus(
            before_log, focus_log, pid, instance.semantic_id)
        screenshot("focused")

        draft_baseline = focus_log
        selection_range: tuple[int, int] | None = None
        if owner_before["value"]:
            action(f"uitest uiInput longClick {point['x']} {point['y']}")
            menu_remote = remote_prefix + "-selection-menu.json"
            action("uitest dumpLayout -p " + shlex.quote(menu_remote), settle=0)
            menu = json.loads(pull(menu_remote, "selection_menu.json").read_text(encoding="utf-8"))
            menu_x, menu_y = selection.menu_point(menu)
            action(f"uitest uiInput click {menu_x} {menu_y}")
            selected_log = capture_hilog("after_selection")
            selection_range = selection.assert_fresh_selection(
                focus_log, selected_log, pid, mount)
            screenshot("selected")
            action("uitest uiInput keyEvent 2055")
            draft_baseline = selected_log

        action(f"uitest uiInput inputText {point['x']} {point['y']} "
               + shlex.quote(args.replacement))
        draft_log = capture_hilog("draft")
        if selection_range is None:
            draft_lengths = positive_draft(draft_baseline, draft_log, pid, mount)
        else:
            draft_lengths = selection.assert_fresh_draft(draft_baseline, draft_log, pid, mount)
        owner_draft = normal.parse_owner(
            session.client.get_context(), args.field, field_spec.resource_id)
        if owner_draft != owner_before:
            raise ValueError("uncommitted generated-field draft changed owner")
        screenshot("draft")

        action("uitest uiInput keyEvent 2054")
        submitted_log = capture_hilog("after_submit")
        selection.assert_fresh_submit(draft_log, submitted_log, pid, mount)
        owner_after = normal.parse_owner(
            session.client.get_context(), args.field, field_spec.resource_id)
        if (owner_after["value"] != args.replacement
                or owner_after["version"] != owner_before["version"] + 1):
            raise ValueError("system input did not commit exact owner value and next version")
        screenshot("after")

        after_structure = session.structure()
        after_instances = session.instances()
        after_snapshot = session.snapshot()
        after_fields = session.fields()
        if after_structure.version != before_structure.version:
            raise ValueError("field input unexpectedly changed accepted structure version")
        after_instance = accepted_editor(after_instances, args.accepted_key, args.field)
        if (after_instance.semantic_id != instance.semantic_id or
                after_instance.node_id != instance.node_id):
            raise ValueError("generated field route changed during this input transaction")
        bindings.append(normal.check_binding(args, hdc, expected_pid=pid, receipt=receipt))
        return {
            "status": "passed", "app": args.app, "target": args.target,
            "pid": pid, "hap_sha256": hashlib.sha256(hap.read_bytes()).hexdigest(),
            "build_variant": "normal", "bundle": normal.APP_CONTRACT[args.app][0],
            "local_port": args.local_port, "device_port": args.device_port,
            "accepted_key": args.accepted_key, "field": args.field,
            "accepted_instance_before": asdict(instance),
            "accepted_instance_after": asdict(after_instance),
            "click_point": point, "mount": mount,
            "selection_utf16": selection_range, "draft_event_lengths": draft_lengths,
            "owner_before": owner_before, "owner_draft": owner_draft,
            "owner_after": owner_after,
            "structure_before": asdict(before_structure),
            "structure_after": asdict(after_structure),
            "snapshot_before": asdict(before_snapshot),
            "snapshot_after": asdict(after_snapshot),
            "fields_before": [asdict(field) for field in before_fields],
            "fields_after": [asdict(field) for field in after_fields],
            "bindings": bindings, "ui_actions": actions,
            "screenshots": ["screen_before.jpeg", "screen_focused.jpeg",
                            *(["screen_selected.jpeg"] if selection_range is not None else []),
                            "screen_draft.jpeg", "screen_after.jpeg"],
            "visual_review": "required; screenshot pixels were not evaluated by this script",
            "remaining_scenarios": {
                "external_owner_change_then_edit": "not_run",
                "rejected_candidate_old_panel_edit": "not_run",
                "same_key_reorder_draft_selection": "not_run",
                "generated_action_button": "not_run",
            },
        }
    finally:
        # Only files this invocation created on the device are removed.
        cleanup_errors: list[str] = []
        for remote in remote_files:
            try:
                hdc.shell("rm -f " + shlex.quote(remote), timeout=30)
            except Exception as exc:
                cleanup_errors.append(f"{remote}: {type(exc).__name__}: {exc}")
        normal.write_json(out / "remote_cleanup.json", {
            "owned_remote_files": remote_files, "errors": cleanup_errors,
        })
        if cleanup_errors and sys.exc_info()[0] is None:
            raise ValueError("own remote screenshot cleanup failed")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--app", choices=sorted(normal.APP_CONTRACT), required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--local-port", type=int, required=True)
    parser.add_argument("--device-port", type=int, required=True)
    parser.add_argument("--capability", required=True)
    parser.add_argument("--caller", default="normal-generated-gui-consumer")
    parser.add_argument("--hap", type=Path, required=True)
    parser.add_argument("--identity", type=Path, required=True)
    parser.add_argument("--forward-receipt-json", type=Path, required=True)
    parser.add_argument("--accepted-key", required=True)
    parser.add_argument("--field", required=True)
    parser.add_argument("--screen-x", type=int)
    parser.add_argument("--screen-y", type=int)
    parser.add_argument("--xcomponent-offset-x", type=int)
    parser.add_argument("--xcomponent-offset-y", type=int)
    parser.add_argument("--replacement", required=True)
    parser.add_argument("--settle-seconds", type=float, default=1.2)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--hdc", default=normal.DEFAULT_HDC)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        result = run_probe(args, GuiHdc(args.hdc, args.target))
    except Exception as exc:
        print(f"generated GUI consumption failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"status": result["status"], "run_dir": str(args.run_dir)},
                     ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
