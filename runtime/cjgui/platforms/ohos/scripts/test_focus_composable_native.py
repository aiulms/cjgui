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


def span(text: str, start_anchor: str, end_anchor: str) -> str:
    """生产原文切片（含两端）：替身的纯数据字段用它注入，字段漂移即编译失败。"""
    start = text.index(start_anchor)
    return text[start:text.index(end_anchor, start) + len(end_anchor)]


# 可视编辑包（H 线）：focusComposableNodeLocked 的 owned 锚点判据读这四个身份字段
# （presentation 节点经声明绑定才能被程序化聚焦）。手写副本落后于生产就会让那道
# 判据静默少判，因此这里注入生产原文而不是自己重抄一遍。
OWNED_ID_ANCHORS = ('    bool ownedTextSessionEnabled = false;',
                    '    uint64_t ownedTextSessionBindingEpoch = 0;')


def harness() -> str:
    source = SOURCE.read_text(encoding="utf-8")
    functions = []
    # 生产聚焦入口用这个谓词判定"可编辑文本 kind"（含多行正文），必须先于调用者摘出。
    functions.append(extract_function(source, "bool isEditableTextKind(uint32_t kind)"))
    helper = "static CjguiInternalRendererStatus focusComposableNodeLocked("
    if helper in source:
        functions.append(extract_function(source, helper))
    functions.append(extract_function(source,
        "CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node(uint64_t session, uint64_t nodeId)"))
    checked = "CjguiInternalRendererStatus cjgui_internal_renderer_focus_composable_node_checked("
    if checked in source:
        functions.append(extract_function(source, checked))
    functions.append(extract_function(source, 'extern "C" uint64_t cjgui_ohos_focus_generation('))
    functions.append(extract_function(source, 'extern "C" CjguiInternalRendererStatus cjgui_ohos_restore_focus_checked('))
    body = "\n\n".join(functions)
    names = ["kKindTextInput", "kKindIntegerInput", "kKindMultiline"]
    if "kEvFocus" in body:
        names.append("kEvFocus")
    constants = "\n".join(re.search(rf"^constexpr uint32_t {name} = \d+;", source, re.M).group()
                          for name in names)
    text = r'''
#include "cjgui_internal_renderer.h"
#include "cjgui_ohos_focus_authority.h"
#include <cstdint>
#include <mutex>
#include <string>
#include <vector>
#define RLOGI(...) do {} while (0)
''' + constants + r'''
struct SceneNode { CjguiInternalRendererComposableNode pod{}; std::string semanticId; };
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
    CjguiOhosFocusAuthority focusAuthority;
    bool editingContextLive = false, editorRetired = false;
    uint64_t editingNodeId = 0, editingAcceptedBindingEpoch = 0;
    bool editing = false;
    bool editingContextRevealRequested = false;
    int64_t editingContextId = 0;
    std::string editingFieldName;
    // owned 会话锚点身份字段取生产原文（占位由 span 注入）。
    %OWNED_ID_FIELDS%
};
static struct { std::mutex lock; } g_sessions;
static Session *g_testSession = nullptr;
static int g_editingCalls = 0;
static Session *lookupSessionLocked(uint64_t session) {
    return session == 1 ? g_testSession : nullptr;
}
static void beginEditingOnNodeLocked(Session &session, const SceneNode &node) {
    session.editingContextLive = true;
    session.editingNodeId = node.pod.nodeId;
    session.editingAcceptedBindingEpoch = node.pod.acceptedBindingEpoch;
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
        Session session; session.accepted.push_back(editor(0, 0, 100, 20));
        g_testSession = &session; g_editingCalls = 0;
        if (cjgui_internal_renderer_focus_composable_node_checked(1,77,5) != CJGUI_INTERNAL_RENDERER_OK) return 11;
        const auto original = cjgui_ohos_focus_generation(1);
        if (!original || cjgui_ohos_restore_focus_checked(1,77,5,original) != CJGUI_INTERNAL_RENDERER_OK || g_editingCalls != 1) return 12;
        session.focusAuthority.revoke(original);
        if (cjgui_ohos_focus_generation(1) || cjgui_ohos_restore_focus_checked(1,77,5,original) == CJGUI_INTERNAL_RENDERER_OK || g_editingCalls != 1) return 13;
        session.focusAuthority.setForeground(false);
        if (cjgui_internal_renderer_focus_composable_node_checked(1,77,5) == CJGUI_INTERNAL_RENDERER_OK || g_editingCalls != 1) return 14;
        session.focusAuthority.setForeground(true);
        if (cjgui_ohos_restore_focus_checked(1,77,5,original) == CJGUI_INTERNAL_RENDERER_OK) return 15;
        if (cjgui_internal_renderer_focus_composable_node_checked(1,77,5) != CJGUI_INTERNAL_RENDERER_OK) return 16;
        if (cjgui_ohos_restore_focus_checked(1,77,5,original) == CJGUI_INTERNAL_RENDERER_OK) return 17;
    }
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
    return text.replace("%OWNED_ID_FIELDS%", span(source, *OWNED_ID_ANCHORS))


class NativeFocusTest(unittest.TestCase):
    def test_extracted_production_focus_entry(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cjgui-ohos-native-focus-") as directory:
            source = Path(directory) / "focus.cpp"
            binary = Path(directory) / "focus"
            source.write_text(harness(), encoding="utf-8")
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            "-I", str(SNAPSHOT), "-I", str(PLATFORM / "host"), str(source), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main()
