#!/usr/bin/env python3
"""Offline canary for the HarmonyOS renderer event C/Cangjie mirror."""

import pathlib
import re
import subprocess
import unittest


PLATFORM = pathlib.Path(__file__).resolve().parents[1]
HEADER = PLATFORM / "snapshot/cjgui_internal_renderer.h"
SESSION = PLATFORM / "snapshot/src/runtime_renderer_session.cj"
SHARED_HEADER = PLATFORM.parents[1] / "native/cjgui_internal_renderer.h"
HOST = PLATFORM / "host/ohos_renderer.cpp"


def struct_body(source: str, name: str) -> str:
    match = re.search(rf"\bstruct {name}\s*\{{(.*?)\n\}}", source, re.S)
    if match is None:
        raise AssertionError(f"missing struct {name}")
    return match.group(1)


class EventAbiMirrorTest(unittest.TestCase):
    def test_c_event_layout_is_current_184_byte_contract(self):
        source = f'''
#include "{HEADER.name}"
_Static_assert(sizeof(CjguiInternalRendererEvent) == 184, "event size");
_Static_assert(offsetof(CjguiInternalRendererEvent, dataTransferEventId) == 128, "transfer id offset");
_Static_assert(offsetof(CjguiInternalRendererEvent, gestureAppInstance) == 136, "gesture offset");
_Static_assert(offsetof(CjguiInternalRendererEvent, acceptedBindingEpoch) == 176, "accepted offset");
'''
        completed = subprocess.run(
            ["cc", "-std=c11", "-fsyntax-only", "-x", "c", "-", "-I", str(HEADER.parent)],
            input=source,
            text=True,
            capture_output=True,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_cangjie_event_field_order_and_pump_mapping(self):
        c_body = struct_body(HEADER.read_text(), "CjguiInternalRendererEvent")
        cj_source = SESSION.read_text()
        cj_body = struct_body(cj_source, "CjguiInternalRendererEvent")
        c_fields = [
            (name, {"uint32_t": "UInt32", "uint64_t": "UInt64", "int64_t": "Int64"}[kind])
            for kind, name in re.findall(r"^\s*(uint32_t|uint64_t|int64_t)\s+(\w+);", c_body, re.M)
        ]
        cj_fields = re.findall(r"^\s*var\s+(\w+):\s+(UInt32|UInt64|Int64)\b", cj_body, re.M)
        self.assertEqual(cj_fields, c_fields)
        shared_body = struct_body(SHARED_HEADER.read_text(), "CjguiInternalRendererEvent")
        shared_fields = [
            (name, {"uint32_t": "UInt32", "uint64_t": "UInt64", "int64_t": "Int64"}[kind])
            for kind, name in re.findall(r"^\s*(uint32_t|uint64_t|int64_t)\s+(\w+);", shared_body, re.M)
        ]
        self.assertEqual(c_fields, shared_fields)
        self.assertIn("var dataTransferEventId: UInt64 = 0", cj_body)
        pump_result = struct_body(cj_source, "InternalRendererPumpResult")
        self.assertIn("let dataTransferEventId: UInt64", pump_result)
        self.assertIn("this.dataTransferEventId = dataTransferEventId", pump_result)
        self.assertRegex(
            cj_source,
            r"event\.bindingEpoch,\s*event\.dataTransferEventId,\s*event\.gestureAppInstance",
        )

    def test_harmonyos_unsupported_transfer_id_stays_zero(self):
        host = HOST.read_text()
        self.assertIn("std::memset(outEvent, 0, sizeof(*outEvent));", host)
        self.assertNotIn("outEvent->dataTransferEventId =", host)


if __name__ == "__main__":
    unittest.main()
