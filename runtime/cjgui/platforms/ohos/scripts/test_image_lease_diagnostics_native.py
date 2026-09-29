#!/usr/bin/env python3
"""Compile the renderer's image lease diagnostic against accepted scene swaps."""

import pathlib
import subprocess
import tempfile
import unittest


SOURCE = pathlib.Path(__file__).resolve().parents[1] / "host" / "ohos_renderer.cpp"
BEGIN = "// BEGIN CJGUI OHOS IMAGE LEASE DIAGNOSTICS"
END = "// END CJGUI OHOS IMAGE LEASE DIAGNOSTICS"


def method(source: str, signature: str) -> str:
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 0
    for i in range(opening, len(source)):
        depth += (source[i] == "{") - (source[i] == "}")
        if depth == 0:
            return source[start:i + 1]
    raise ValueError(signature)


class ImageLeaseDiagnosticsNativeTest(unittest.TestCase):
    def test_exact_accepted_identity_counts_and_transition_sequence(self):
        source = SOURCE.read_text()
        self.assertTrue(BEGIN in source, "production accepted lease diagnostic is missing")
        self.assertTrue(END in source, "production accepted lease diagnostic terminator is missing")
        diagnostics = source.split(BEGIN, 1)[1].split(END, 1)[0]
        harness = r'''
#include <algorithm>
#include <array>
#include <atomic>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <memory>
#include <string>
#include <vector>
std::vector<std::string> logs;
void capture(const char *format, ...) {
    std::string normalized(format);
    for (size_t pos = 0; (pos = normalized.find("%{public}", pos)) != std::string::npos;)
        normalized.replace(pos, 9, "%");
    char line[1024];
    va_list args;
    va_start(args, format);
    vsnprintf(line, sizeof(line), normalized.c_str(), args);
    va_end(args);
    logs.emplace_back(line);
}
#define RLOGI(...) capture(__VA_ARGS__)
constexpr size_t kImageMaxRecords = 64;
struct OhosImageEntry {
    const uint64_t id, epoch;
    const std::string key;
    const uint64_t version;
    OhosImageEntry(uint64_t i, uint64_t e, std::string k, uint64_t v)
        : id(i), epoch(e), key(std::move(k)), version(v) {}
};
using OhosImageRef = std::shared_ptr<OhosImageEntry>;
struct SceneNode { OhosImageRef image; };
struct Session {
    uint64_t token = 7, acceptedProjectionVersion = 10;
    std::vector<SceneNode> accepted;
};
''' + diagnostics + r'''
bool has(const std::string &needle) {
    return std::any_of(logs.begin(), logs.end(), [&](const auto &line) {
        return line.find(needle) != std::string::npos;
    });
}
int main() {
    auto a = std::make_shared<OhosImageEntry>(11, 3, "a b", 1);
    auto b = std::make_shared<OhosImageEntry>(12, 3, "other", 1);
    auto reopened = std::make_shared<OhosImageEntry>(13, 4, "a b", 1);
    Session s;
    s.accepted = {{a}, {a}};
    std::vector<SceneNode> next = {{a}, {b}};
    std::vector<SceneNode> old = s.accepted;
    s.accepted = next;
    s.acceptedProjectionVersion = 11;
    cjguiOhosLogAcceptedImageSwap(s, old, 10, 91, "commit");
    if (!has("stage=accepted-swap seq=1 session=7 ticket=91 cause=commit oldProjection=10 newProjection=11 rows=2 omitted=0")) return 1;
    if (!has("stage=accepted-entry seq=1 epoch=3 entry=11 keyHex=612062 version=1 oldCount=2 newCount=1")) return 2;
    if (!has("stage=accepted-entry seq=1 epoch=3 entry=12 keyHex=6f74686572 version=1 oldCount=0 newCount=1")) return 3;
    old = s.accepted;
    s.accepted.clear();
    s.acceptedProjectionVersion = 12;
    cjguiOhosLogAcceptedImageSwap(s, old, 11, 92, "commit");
    if (!has("stage=accepted-swap seq=2 session=7 ticket=92 cause=commit oldProjection=11 newProjection=12 rows=2 omitted=0")) return 4;
    if (!has("stage=accepted-entry seq=2 epoch=3 entry=11 keyHex=612062 version=1 oldCount=1 newCount=0")) return 5;
    old = s.accepted;
    s.accepted = {{reopened}};
    s.acceptedProjectionVersion = 13;
    cjguiOhosLogAcceptedImageSwap(s, old, 12, 93, "commit");
    if (!has("stage=accepted-entry seq=3 epoch=4 entry=13 keyHex=612062 version=1 oldCount=0 newCount=1")) return 6;
    old = s.accepted;
    s.accepted.clear();
    s.acceptedProjectionVersion = 0;
    cjguiOhosLogAcceptedImageSwap(s, old, 13, 0, "destroy");
    if (!has("stage=accepted-swap seq=4 session=7 ticket=0 cause=destroy oldProjection=13 newProjection=0 rows=1 omitted=0")) return 7;
    if (!has("stage=accepted-entry seq=4 epoch=4 entry=13 keyHex=612062 version=1 oldCount=1 newCount=0")) return 8;
    old = s.accepted;
    s.acceptedProjectionVersion = 14;
    cjguiOhosLogAcceptedImageSwap(s, old, 0, 94, "commit");
    if (!has("stage=accepted-swap seq=5 session=7 ticket=94 cause=commit oldProjection=0 newProjection=14 rows=0 omitted=0")) return 9;
    return 0;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            cpp = pathlib.Path(directory) / "image_lease.cpp"
            binary = pathlib.Path(directory) / "image_lease"
            cpp.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(cpp), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)

    def test_diagnostic_is_wired_to_successful_swap_destroy_bitmap_and_real_draw(self):
        source = SOURCE.read_text()
        pending = method(source, "static uint32_t settlePendingTicketLocked(")
        present = method(source, "CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene(")
        destroy = method(source, "CjguiInternalRendererStatus cjgui_internal_renderer_destroy(")
        draw = method(source, "void drawNodeImage(")
        self.assertTrue('cjguiOhosLogAcceptedImageSwap(*s, p.nodes' in pending,
                        "pending accepted swap diagnostic is missing")
        self.assertTrue('cjguiOhosLogAcceptedImageSwap(*s, nodes' in present,
                        "synchronous accepted swap diagnostic is missing")
        self.assertTrue('cjguiOhosLogAcceptedImageSwap(*s, oldAccepted' in destroy,
                        "destroy accepted clear diagnostic is missing")
        self.assertLess(pending.index('s->accepted.swap(p.nodes)'),
                        pending.index('cjguiOhosLogAcceptedImageSwap(*s, p.nodes'))
        self.assertLess(present.index('s->accepted.swap(nodes)'),
                        present.index('cjguiOhosLogAcceptedImageSwap(*s, nodes'))
        self.assertLess(destroy.index('oldAccepted.swap(s->accepted)'),
                        destroy.index('cjguiOhosLogAcceptedImageSwap(*s, oldAccepted'))
        self.assertTrue('image-lease stage=bitmap-create' in source)
        self.assertTrue('image-lease stage=bitmap-destroy' in source)
        self.assertLess(draw.index('OH_Drawing_CanvasDrawBitmapRect('),
                        draw.index('image-lease stage=draw'))
        self.assertNotIn('#ifdef CJGUI_OHOS_TEST_GATES',
                         draw[draw.index('OH_Drawing_CanvasDrawBitmapRect('):
                              draw.index('image-lease stage=draw')])


if __name__ == "__main__":
    unittest.main()
