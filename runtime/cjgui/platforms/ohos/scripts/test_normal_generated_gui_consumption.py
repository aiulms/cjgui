#!/usr/bin/env python3
"""Offline GUI-command counterexamples against a real loopback protocol peer."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
CORE = HERE.parents[2] / "shared_operation_core"
for directory in (HERE, CORE):
    if str(directory) not in sys.path:
        sys.path.insert(0, str(directory))

from test_generated_client_tcp_forward import (  # noqa: E402
    CAPABILITIES, ForwardedPeer, SNAPSHOT, envelope,
)
import verify_normal_generated_gui_consumption as gui  # noqa: E402


def owner(version: int, value: str, resource: int = 9700, field: str = "name") -> str:
    encoded = value.encode("utf-8")
    return envelope("SNAPSHOT", f"VERSION {version}",
                    f"FIELD {resource} {field} STRING {len(encoded)} {encoded.hex().upper() or '-'}")


def row(message: str, pid: str = "5700") -> str:
    return f"09-27 19:42:48.787 {pid} {pid} I A00000/CjguiApp: {message}"


class FakeGuiHdc:
    def __init__(self, target: str, local_port: int, device_port: int, state: dict):
        self.target, self.local_port, self.device_port = target, local_port, device_port
        self.state = state
        self.commands: list[dict] = []
        self.logs = [row("baseline")]
        self.mount = "app1/s1/c3/e1/m3"
        self.menu_open = False

    def listing(self) -> str:
        self.commands.append({"command": "hdc fport ls"})
        return f"{self.target} tcp:{self.local_port} tcp:{self.device_port} [Forward]\n"

    def pidof(self, bundle: str) -> str:
        self.commands.append({"command": f"hdc pidof {bundle}"})
        return "5700\n"

    def shell(self, command: str, *, timeout: int = 45) -> str:
        self.commands.append({"command": command})
        if command.startswith("hilog -x"):
            return "\n".join(self.logs) + "\n"
        if command.startswith("uitest uiInput click "):
            if self.menu_open:
                self.logs.append(row(f"ime select [0,2) rc=0 mount={self.mount}"))
                self.menu_open = False
            else:
                self.logs.append(row(
                    f"ime proxy FOCUSED field={self.state.get('semantic', 'generated-edit-node')} "
                    f"mount={self.mount}"))
        elif command.startswith("uitest uiInput longClick "):
            self.menu_open = True
        elif command == "uitest uiInput keyEvent 2055":
            self.logs.append(row(f"ime proxy onChange len=0 verdict=ok mount={self.mount}"))
        elif command.startswith("uitest uiInput inputText "):
            self.logs.append(row(f"ime proxy onChange len=6 verdict=ok mount={self.mount}"))
        elif command == "uitest uiInput keyEvent 2054":
            self.logs.append(row(f"ime proxy submit verdict=ok mount={self.mount}"))
            self.state["version"] += 1
            self.state["value"] = self.state.get("replacement", "新名")
        return ""

    def pull(self, remote: str, local: Path) -> None:
        self.commands.append({"command": f"hdc file recv {remote} {local}"})
        if remote.endswith(".json"):
            local.write_text(json.dumps({
                "attributes": {"text": ""},
                "children": [{"attributes": {"text": "全选", "bounds": "[300,400][340,440]"},
                              "children": []}],
            }), encoding="utf-8")
        else:
            local.write_bytes(b"fake-jpeg-bytes")


class GeneratedGuiTests(unittest.TestCase):
    def fixture(self, root: Path, local_port: int, *, app: str = "settings") -> argparse.Namespace:
        device_port = 7857 if app == "thermo" else 7856
        field = "note" if app == "thermo" else "name"
        hap = root / "normal.hap"
        hap.write_bytes(b"normal-hap-test")
        identity = root / "identity.txt"
        identity.write_text(
            f"target=127.0.0.1:5555\npid=5700\nhap_sha256={hashlib.sha256(hap.read_bytes()).hexdigest()}\n"
            "build_variant=normal\n", encoding="utf-8")
        receipt = root / "receipt.json"
        receipt.write_text(json.dumps({
            "target": "127.0.0.1:5555", "local_port": local_port,
            "device_port": device_port,
            "command": ["hdc", "-t", "127.0.0.1:5555", "fport",
                        f"tcp:{local_port}", f"tcp:{device_port}"],
            "returncode": 0, "stdout": "Forwardport result:OK", "stderr": "",
        }), encoding="utf-8")
        return argparse.Namespace(
            app=app, target="127.0.0.1:5555", local_port=local_port,
            device_port=device_port, capability="private-token", caller="generated-gui-test",
            hap=hap, identity=identity, forward_receipt_json=receipt,
            run_dir=root / "gui-evidence", accepted_key="edit", field=field,
            screen_x=None, screen_y=None, xcomponent_offset_x=50,
            xcomponent_offset_y=100, replacement="新名", settle_seconds=0,
        )

    def peer(self, state: dict) -> ForwardedPeer:
        field = state.get("field", "name")
        resource = state.get("resource", 9700)
        semantic = state.get("semantic", "generated-edit-node")
        capabilities = CAPABILITIES.replace("FIELD name TEXT resource=9700",
                                            f"FIELD {field} TEXT resource={resource}")
        instances = envelope(
            "GENERATED_UI_INSTANCES", "STRUCTURE_VERSION 1", "CANDIDATE_VERSION 1",
            "SCENE_STATE scene_accepted", "INSTANCE_LENGTH 2",
            "INSTANCE root element=- role=- id=800001 kind=vertical semantic=generated-root-node "
            "field=- action=- visible=1 bounds=0,0,300,240 label_hex=-",
            f"INSTANCE edit element=- role=field id=800002 kind=textInput semantic={semantic} "
            f"field={field} action=- visible=1 bounds=10,60,200,26 label_hex=E5908DE7A7B0",
        )
        structure = envelope(
            "GENERATED_UI_STRUCTURE", "STRUCTURE_VERSION 1", "CANDIDATE_VERSION 1",
            "SCENE_STATE scene_accepted", "STRUCTURE_LENGTH 2",
            "NODE 0 root vertical", f"NODE 1 edit textInput field={field}",
        )

        def answer(request: str) -> str:
            if "GET_GENERATED_UI_CAPABILITIES" in request:
                return capabilities
            if "GET_GENERATED_UI_STRUCTURE" in request:
                return structure
            if "GET_GENERATED_UI_INSTANCES" in request:
                return instances
            if "GET_GENERATED_UI_FIELDS" in request:
                return envelope("GENERATED_UI_FIELDS", "INSTANCE_LENGTH 0")
            if "GET_GENERATED_UI_SNAPSHOT" in request:
                return SNAPSHOT
            if "GET_CONTEXT" in request:
                return owner(state["version"], state["value"], resource, field)
            raise AssertionError(f"unexpected request: {request}")

        return ForwardedPeer(answer)

    def test_generated_field_click_system_replace_and_owner_readback(self):
        state = {"version": 3, "value": "旧名"}
        peer = self.peer(state)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                args = self.fixture(Path(tmp), peer.port)
                hdc = FakeGuiHdc(args.target, peer.port, 7856, state)
                result = gui.run_probe(args, hdc)
                self.assertEqual(result["status"], "passed")
                self.assertEqual(result["owner_before"]["value"], "旧名")
                self.assertEqual(result["owner_after"]["value"], "新名")
                self.assertEqual(result["click_point"], {"x": 160, "y": 173,
                                                         "source": "instance_bounds_plus_xcomponent_offset"})
                commands = [record["command"] for record in hdc.commands]
                self.assertIn("uitest uiInput click 160 173", commands)
                self.assertIn("uitest uiInput keyEvent 2054", commands)
                self.assertFalse(any(" fport tcp:" in command or "fport rm" in command
                                     for command in commands))
                self.assertTrue((args.run_dir / "hilog_after_submit.txt").is_file())
                self.assertTrue((args.run_dir / "screen_after.jpeg").is_file())
                self.assertTrue((args.run_dir / "exchanges.jsonl").is_file())
        finally:
            peer.close()

    def test_wrong_generated_key_refuses_before_click(self):
        state = {"version": 3, "value": "旧名"}
        peer = self.peer(state)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                args = self.fixture(Path(tmp), peer.port)
                args.accepted_key = "handwritten-field"
                hdc = FakeGuiHdc(args.target, peer.port, 7856, state)
                with self.assertRaisesRegex(ValueError, "accepted generated instance"):
                    gui.run_probe(args, hdc)
                self.assertFalse(any("uitest uiInput" in record["command"]
                                     for record in hdc.commands))
        finally:
            peer.close()

    def test_thermo_empty_note_uses_supplied_screen_point_without_selection(self):
        state = {"version": 4, "value": "", "field": "note", "resource": 9801,
                 "semantic": "generated-note-node", "replacement": "暖和"}
        peer = self.peer(state)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                args = self.fixture(Path(tmp), peer.port, app="thermo")
                args.screen_x, args.screen_y = 200, 300
                args.xcomponent_offset_x = args.xcomponent_offset_y = None
                args.replacement = "暖和"
                hdc = FakeGuiHdc(args.target, peer.port, 7857, state)
                result = gui.run_probe(args, hdc)
                self.assertEqual(result["status"], "passed")
                self.assertEqual(result["click_point"], {
                    "x": 200, "y": 300, "source": "caller_screen_point"})
                self.assertEqual(result["owner_after"]["value"], "暖和")
                self.assertEqual(result["owner_after"]["version"], 5)
                self.assertFalse(any("longClick" in record["command"] for record in hdc.commands))
        finally:
            peer.close()

    def test_system_submit_without_exact_owner_commit_is_a_failure(self):
        state = {"version": 3, "value": "旧名"}
        peer = self.peer(state)
        try:
            with tempfile.TemporaryDirectory() as tmp:
                args = self.fixture(Path(tmp), peer.port)

                class WrongOwnerHdc(FakeGuiHdc):
                    def shell(self, command: str, *, timeout: int = 45) -> str:
                        result = super().shell(command, timeout=timeout)
                        if command == "uitest uiInput keyEvent 2054":
                            self.state["value"] = "错误值"
                        return result

                hdc = WrongOwnerHdc(args.target, peer.port, 7856, state)
                with self.assertRaisesRegex(ValueError, "exact owner"):
                    gui.run_probe(args, hdc)
                self.assertTrue((args.run_dir / "failure.json").is_file())
                self.assertTrue((args.run_dir / "commands.json").is_file())
                self.assertFalse((args.run_dir / "result.json").exists())
        finally:
            peer.close()


if __name__ == "__main__":
    unittest.main()
