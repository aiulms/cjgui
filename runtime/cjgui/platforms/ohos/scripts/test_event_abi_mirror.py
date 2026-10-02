#!/usr/bin/env python3
"""Offline canary for the HarmonyOS renderer event/node ABI and binding gates."""

import pathlib
import re
import subprocess
import unittest


PLATFORM = pathlib.Path(__file__).resolve().parents[1]
HEADER = PLATFORM / "snapshot/cjgui_internal_renderer.h"
SESSION = PLATFORM / "snapshot/src/runtime_renderer_session.cj"
SHARED_HEADER = PLATFORM.parents[1] / "native/cjgui_internal_renderer.h"
SHARED_SESSION = PLATFORM.parents[1] / "src/runtime_renderer_session.cj"
HOST = PLATFORM / "host/ohos_renderer.cpp"
WINDOW = PLATFORM / "snapshot/src/composable_ui_window.cj"
SHARED_WINDOW = PLATFORM.parents[1] / "src/composable_ui_window.cj"

C_TYPE_TO_CJ = {
    "uint32_t": "UInt32",
    "uint64_t": "UInt64",
    "int64_t": "Int64",
    "double": "Float64",
}


def binding_gate_statement(text: str) -> str:
    """The COMPLETE `let gestureBindingReady = ...` statement.

    r10 漏检原因（2026-09-29）：旧检查的正则只截到
    `... == nativeEvent.acceptedBindingEpoch)`，语句其后重新追加的让步
    （例如 `|| nativeEvent.text.startsWith("fling:")`）落在断言范围之外，
    于是「恢复旧 fling 旁路」仍能通过。这里按括号配平一直取到语句结束，
    任何追加在门表达式之后的旁路都在比对范围内。
    """
    marker = "let gestureBindingReady = "
    start = text.find(marker)
    if start < 0:
        raise AssertionError("gestureBindingReady declaration not found")
    i = start + len(marker)
    depth = 0
    in_string = False
    last_significant = ""
    while i < len(text):
        ch = text[i]
        if in_string:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                in_string = False
        elif ch == '"':
            in_string = True
        elif ch == "/" and text[i:i + 2] == "//":
            newline = text.find("\n", i)
            if newline < 0:
                break
            i = newline
            continue
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "\n" and depth == 0:
            # 语句可能在行尾的二元运算符处续行（门表达式就是 `... ||` 换行）；
            # 只有「上一有效字符不是运算符」且「下一有效字符不是运算符」才结束。
            j = i + 1
            while j < len(text) and text[j] in " \t":
                j += 1
            nxt = text[j] if j < len(text) else ""
            if last_significant in "|&+-*/%.,=?:<>!" or nxt in "|&.?,:":
                i += 1
                continue
            break
        if not ch.isspace():
            last_significant = ch
        i += 1
    return text[start:i]


def normalized_statement(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def assert_no_binding_bypass(statement: str) -> None:
    """The gate must not let a text marker (legacy `fling:`) past the identity check."""
    if "fling" in statement.lower():
        raise AssertionError(
            "gestureBindingReady reintroduced a text bypass: " + normalized_statement(statement))


def struct_body(source: str, name: str) -> str:
    match = re.search(rf"\bstruct {name}\s*\{{(.*?)\n\}}", source, re.S)
    if match is None:
        raise AssertionError(f"missing struct {name}")
    return match.group(1)


def c_struct_fields(source: str, name: str) -> list:
    """Ordered (name, Cangjie type) pairs; multi-name declarations expand."""
    body = re.sub(r"//[^\n]*", "", struct_body(source, name))
    fields = []
    for decl in re.findall(r"[^;]+;", body):
        decl = decl.strip()
        if not decl:
            continue
        match = re.match(r"(uint32_t|uint64_t|int64_t|double)\s+(.*)$", decl, re.S)
        if match is None:
            raise AssertionError(f"unparsed C declaration in {name}: {decl}")
        kind = C_TYPE_TO_CJ[match.group(1)]
        remainder = match.group(2).strip().rstrip(";")
        for piece in remainder.split(","):
            fields.append((piece.strip(), kind))
    return fields


def cj_struct_fields(source: str, name: str) -> list:
    body = struct_body(source, name)
    return re.findall(r"^\s*var\s+(\w+):\s+(UInt32|UInt64|Int64|Float64)\b", body, re.M)


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

    def test_c_node_layout_is_current_888_byte_contract(self):
        # 复核反例（r10）：snapshot 仓颉镜像曾在 tabSelected 后直接放
        # acceptedBindingEpoch，缺 semantic/effect/wheel 60 字段；native 按
        # 完整 C Node（888 B）拷贝入参，错位使 epoch 通道读到 garbage。
        # 这里把 C 侧尺寸与关键偏移钉死为契约（与头部尾部 _Static_assert 互补）。
        source = f'''
#include "{HEADER.name}"
_Static_assert(sizeof(CjguiInternalRendererComposableNode) == 888, "node size");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, inputScope) == 416, "input scope offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, tabGroupId) == 424, "tab group offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, tabSelected) == 432, "tab selected offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, semanticRole) == 436, "semantic role offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, shadowPresent) == 464, "shadow offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, gradientPresent) == 536, "gradient offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, effectGroupPresent) == 736, "effect group offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, effectBackdropBlurRadiusPoints) == 864, "backdrop offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, wheelScrollable) == 872, "wheel offset");
_Static_assert(offsetof(CjguiInternalRendererComposableNode, acceptedBindingEpoch) == 880, "accepted offset");
'''
        completed = subprocess.run(
            ["cc", "-std=c11", "-fsyntax-only", "-x", "c", "-", "-I", str(HEADER.parent)],
            input=source,
            text=True,
            capture_output=True,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_node_four_way_field_order_is_identical(self):
        # 主 src 头、H snapshot 头、主 src 镜像与 H snapshot 镜像必须逐字段
        # 同序同名同宽；snapshot 是交付副本，不能少字段，也不能保留旧序。
        snap_c = c_struct_fields(HEADER.read_text(), "CjguiInternalRendererComposableNode")
        main_c = c_struct_fields(SHARED_HEADER.read_text(), "CjguiInternalRendererComposableNode")
        snap_cj = cj_struct_fields(SESSION.read_text(), "CjguiInternalRendererComposableNode")
        main_cj = cj_struct_fields(SHARED_SESSION.read_text(), "CjguiInternalRendererComposableNode")
        self.assertEqual(snap_c, main_c)
        self.assertEqual(snap_cj, main_cj)
        self.assertEqual(snap_cj, snap_c)
        # H 不支持的效果不得以删槽位代替：语义/效果/滚动声明字段必须保留。
        names = [name for name, _ in snap_cj]
        for required in ("semanticRole", "semanticState", "semanticLevel", "semanticIncarnation",
                         "shadowPresent", "gradientPresent", "effectGroupPresent", "effectMaskPresent",
                         "effectBackdropBlurRadiusPoints", "wheelScrollable", "acceptedBindingEpoch"):
            self.assertIn(required, names)
        self.assertEqual(names.index("acceptedBindingEpoch"), len(names) - 1)
        self.assertEqual(names.index("wheelScrollable"), len(names) - 2)

    def test_host_copies_the_full_c_node_pod(self):
        host = HOST.read_text()
        self.assertIn("dst.pod = *node;", host)

    def test_snapshot_window_binding_gate_matches_main_and_has_no_fling_bypass(self):
        # r10 复核：snapshot 曾对 "fling:" 文本开旁路跳过 acceptedBindingEpoch
        # 比对（当时理由为 ABI 错位）。ABI 已对齐后，指针门必须与主 src 逐字
        # 一致；fling 与其他指针事件共用同一严格身份比对，不再有文本旁路。
        # 2026-09-29 返工：比对单位改为**整条赋值语句**（括号配平到语句末），
        # 否则追加在门表达式之后的旧旁路不在断言范围内（指导内存变异已复现）。
        snap_gate = normalized_statement(binding_gate_statement(WINDOW.read_text()))
        main_gate = normalized_statement(binding_gate_statement(SHARED_WINDOW.read_text()))
        self.assertEqual(snap_gate, main_gate)
        assert_no_binding_bypass(snap_gate)

    def test_binding_gate_check_catches_an_appended_legacy_bypass(self):
        # 负控（红）：把旧旁路按原样追加回语句末尾，检查必须失败。若本用例
        # 通过而上一用例仍绿，说明比对范围又退回了「截到 epoch 比较为止」。
        source = WINDOW.read_text()
        statement = binding_gate_statement(source)
        legacy = ' || nativeEvent.text.startsWith("fling:")'
        mutated = source.replace(statement, statement + legacy, 1)
        self.assertNotEqual(source, mutated, "负控变异未生效（语句未匹配）")
        mutated_statement = normalized_statement(binding_gate_statement(mutated))
        # 变异后的完整语句必须与正常语句不同 —— 这正是旧检查漏掉的部分。
        self.assertNotEqual(mutated_statement, normalized_statement(statement))
        with self.assertRaises(AssertionError):
            assert_no_binding_bypass(mutated_statement)
        # 旧检查的盲区本身也要可复现：它的正则截到 epoch 比较为止，追加旁路后
        # 仍返回「无 fling」。这条断言把「为什么必须按整语句比对」钉在测试里。
        legacy_pattern = (
            r"let gestureBindingReady = .*?currentAcceptedBindingEpoch\(continuation\)"
            r" == nativeEvent\.acceptedBindingEpoch\)")
        legacy_match = re.search(legacy_pattern, mutated, re.S)
        self.assertIsNotNone(legacy_match)
        legacy_gate = re.sub(r"\s+", " ", legacy_match.group(0)).strip()
        self.assertNotIn("fling", legacy_gate)

    def test_harmonyos_unsupported_transfer_id_stays_zero(self):
        host = HOST.read_text()
        self.assertIn("std::memset(outEvent, 0, sizeof(*outEvent));", host)
        self.assertNotIn("outEvent->dataTransferEventId =", host)


if __name__ == "__main__":
    unittest.main()
