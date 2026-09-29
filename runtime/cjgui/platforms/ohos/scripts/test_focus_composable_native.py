#!/usr/bin/env python3
"""Exercise the real OHOS native focus entry against accepted clip and binding fixtures."""

from pathlib import Path
import re
import subprocess
import tempfile
import unittest


PLATFORM = Path(__file__).resolve().parents[1]
SOURCE = PLATFORM / "host" / "ohos_renderer.cpp"
SNAPSHOT = PLATFORM / "snapshot"


def extract_function(source: str, signature: str) -> str:
    if source.count(signature) != 1:
        raise ValueError(f"expected one native function: {signature}")
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 0
    for offset in range(opening, len(source)):
        if source[offset] == "{":
            depth += 1
        elif source[offset] == "}":
            depth -= 1
            if depth == 0:
                return source[start:offset + 1]
    raise ValueError(f"native function is incomplete: {signature}")


def harness() -> str:
    source = SOURCE.read_text(encoding="utf-8")
    functions = []
    helper = "static CjguiInternalRendererStatus focusComposableNodeLocked("
    if helper in source:
        functions.append(extract_function(source, helper))
    functions.append(extract_function(source,
        "CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node(uint64_t session, uint64_t nodeId)"))
    checked = "CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node_checked("
    if checked in source:
        functions.append(extract_function(source, checked))
    body = "\n\n".join(functions)
    names = ["kKindTextInput", "kKindIntegerInput"]
    if "kEvFocus" in body:
        names.append("kEvFocus")
    constants = "\n".join(re.search(rf"^constexpr uint32_t {name} = \d+;", source, re.M).group()
                          for name in names)
    return r'''
#include "cjgui_internal_renderer.h"
#include <cstdint>
#include <mutex>
#include <string>
#include <vector>
#define RLOGI(...) do {} while (0)
''' + constants + r'''
struct SceneNode { CjguiInternalRendererComposableNode pod{}; };
struct QueuedEvent {
    uint32_t kind = 0;
    uint32_t recordIndex = 0;
    uint64_t nodeId = 0;
    uint64_t projectionVersion = 0;
    int64_t resourceId = 0;
    uint32_t nodeKind = 0;
};
struct Session {
    std::vector<SceneNode> accepted;
    std::vector<QueuedEvent> events;
    bool editing = false;
    bool editingContextRevealRequested = false;
    int64_t editingContextId = 0;
    std::string editingFieldName;
};
static struct { std::mutex lock; } g_sessions;
static Session *g_testSession = nullptr;
static int g_editingCalls = 0;
static Session *lookupSessionLocked(uint64_t session) {
    return session == 1 ? g_testSession : nullptr;
}
static void beginEditingOnNodeLocked(Session &session, const SceneNode &) {
    session.editing = true;
    session.editingContextId = ++g_editingCalls;
}
''' + body + r'''
static SceneNode editor(int64_t x, int64_t y, int64_t width, int64_t height) {
    SceneNode node;
    node.pod.nodeId = 77;
    node.pod.nodeKind = kKindTextInput;
    node.pod.isInteractive = 1;
    node.pod.x = x;
    node.pod.y = y;
    node.pod.width = width;
    node.pod.height = height;
    node.pod.clipX = 0;
    node.pod.clipY = 0;
    node.pod.clipWidth = 100;
    node.pod.clipHeight = 100;
    node.pod.acceptedBindingEpoch = 5;
    return node;
}
static bool rejectedWithoutSideEffects(Session &session) {
    g_testSession = &session;
    g_editingCalls = 0;
    const auto status = cjgui_internal_renderer_focus_composable_node(1, 77);
    return status == CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY && !session.editing &&
           g_editingCalls == 0 && session.events.empty();
}
int main() {
    {
        Session session;
        session.accepted.push_back(editor(0, 200, 100, 20));
        if (!rejectedWithoutSideEffects(session)) return 1;
    }
    {
        Session session;
        session.accepted.push_back(editor(0, 0, 100, 20));
        session.accepted[0].pod.clipWidth = 0;
        if (!rejectedWithoutSideEffects(session)) return 2;
    }
    {
        Session session;
        session.accepted.push_back(editor(0, 90, 100, 20));
        g_testSession = &session;
        g_editingCalls = 0;
        if (cjgui_internal_renderer_focus_composable_node(1, 77) != CJGUI_INTERNAL_RENDERER_OK ||
            !session.editing || g_editingCalls != 1 || !session.events.empty()) return 3;
    }
    {
        Session session;
        session.accepted.push_back(editor(0, 90, 100, 20));
        auto &node = session.accepted[0].pod;
        node.clipConstraintCount = 2;
        node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 100; node.clip0Height = 100;
        node.clip1X = 0; node.clip1Y = 200; node.clip1Width = 100; node.clip1Height = 100;
        if (!rejectedWithoutSideEffects(session)) return 4;
    }
    {
        Session session;
        session.accepted.push_back(editor(0, 90, 100, 20));
        auto &node = session.accepted[0].pod;
        node.clipConstraintCount = 4;
        node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 100; node.clip0Height = 100;
        node.clip1X = 0; node.clip1Y = 0; node.clip1Width = 100; node.clip1Height = 100;
        node.clip2X = 0; node.clip2Y = 0; node.clip2Width = 100; node.clip2Height = 100;
        node.clip3X = 0; node.clip3Y = 200; node.clip3Width = 100; node.clip3Height = 100;
        if (!rejectedWithoutSideEffects(session)) return 5;
    }
    {
        Session session;
        session.accepted.push_back(editor(0, 0, 0, 20));
        if (!rejectedWithoutSideEffects(session)) return 6;
    }
    {
        Session session;
        session.accepted.push_back(editor(0, 0, 100, 20));
        g_testSession = &session;
        g_editingCalls = 0;
        if (cjgui_internal_renderer_focus_composable_node_checked(1, 77, 4) !=
                CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND || session.editing ||
            g_editingCalls != 0 || !session.events.empty()) return 7;
        if (cjgui_internal_renderer_focus_composable_node_checked(1, 77, 5) !=
                CJGUI_INTERNAL_RENDERER_OK || !session.editing || g_editingCalls != 1) return 8;
    }
    {
        Session session;
        session.accepted.push_back(editor(0, 200, 100, 20));
        g_testSession = &session;
        g_editingCalls = 0;
        if (cjgui_internal_renderer_focus_composable_node_checked(1, 77, 5) !=
                CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY || session.editing ||
            g_editingCalls != 0 || !session.events.empty()) return 9;
    }
    {
        Session session;
        session.accepted.push_back(editor(0, 0, 100, 20));
        session.accepted[0].pod.acceptedBindingEpoch = 0;
        g_testSession = &session;
        g_editingCalls = 0;
        if (cjgui_internal_renderer_focus_composable_node_checked(1, 77, 0) !=
                CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND || session.editing ||
            g_editingCalls != 0 || !session.events.empty()) return 10;
    }
    return 0;
}
'''


class NativeFocusTest(unittest.TestCase):
    def test_extracted_production_focus_entry(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cjgui-ohos-native-focus-") as directory:
            source = Path(directory) / "focus.cpp"
            binary = Path(directory) / "focus"
            source.write_text(harness(), encoding="utf-8")
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            "-I", str(SNAPSHOT), str(source), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main()
