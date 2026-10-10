#!/usr/bin/env python3
"""R1 提交许可状态机的真实时序重放（2026-10-02 Astra h-r1-source-admission 追问）。

只读裁决：artifacts/consultations/h-r1-source-admission-astra/answer-followup-1.md。

Astra 追问明确指出：现有 `test_r1_source_admission_native.py` 的 `Job` 只有
`Committing/Done`，`waitFor()` 是替身，**没有运行真实提交许可状态机**，因此只
能证明收尾判据，不能证明本次讨论的（许可前/后）时序。本文件补上那一半：把
`ohos_renderer.cpp` 的真实 `WaitableJob`（`finish` / `cancelBeforeCommit` /
`markRunning` / `waitFor` / `acquireCommitPermission` / `consumeCancelIfRequested`）
与真实 `kRenderWaitTimeout`、`JobKind`、`JobPhase`、`CJGUI_INTERNAL_RENDERER_PENDING`
**逐字抽取**，用真实线程驱动，断言四种时序的 native 不变量：

  * **许可前超时（Queued/Running 超时）**：真实 `waitFor` 超时后必须
    `phase==Cancelled`、返回非 OK；此后渲染线程再到也不能取得许可
    （`acquireCommitPermission()==false`，`consumeCancelIfRequested()==true`），
    故实际 Flush=0。
  * **许可后 PENDING**：渲染线程已 `acquireCommitPermission()`（phase=Committing）
    时，真实 `waitFor` 超时**返回 PENDING 且不改写阶段**（保持 Committing，与全仓
    注释「committing 超时返回 PENDING(20)」一致）。
  * **Flush 前拒绝落点**：Committing 中 `finish(non-OK)` 后 phase=Done、状态非 OK，
    实际 Flush 计数为 0（拒绝发生在真正写平台之前）——即 Astra 纠正后的合法零 Flush
    落点（`ohos_renderer.cpp:3470` 租约复核同形）。
  * **许可后正常终结**：`finish(OK)` 使被 park 的 `waitFor` 返回 OK；`Done` 之后
    重复 `finish` 不得覆写终态。

方向性变异负控：把真实 `acquireCommitPermission` 改造成「任何阶段都放行」，上面的
「取消后不得再取得许可」断言必须翻红——证明该断言能区分真假状态机。

边界（本文件不假装覆盖）：owner 分发顺序（同一 owner 的后续业务 dispatch 是否插入
许可前等待）与生成结构替换（`scene_transaction_busy`）需要真实 owner 循环/传输入队
或 Cangjie 侧，本文件不含；它们不是这里抽取的四个函数能证明的。本文件也**不**
声称 (d) 可达或不可达——那属于调用链证明，见裁决正文。
"""
import pathlib
import re
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"


def block(text, signature):
    start = text.index(signature)
    opening = text.index('{', start)
    tokens = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[{}]')
    depth = 0
    for match in tokens.finditer(text, opening):
        if match.group() == '{':
            depth += 1
        elif match.group() == '}':
            depth -= 1
            if depth == 0:
                return text[start:match.end()]
    raise ValueError(signature)


def line_containing(text, needle):
    for line in text.splitlines():
        if needle in line:
            return line
    raise ValueError(needle)


SOURCE_TEXT = SOURCE.read_text()

C_TIMEOUT = line_containing(SOURCE_TEXT, "kRenderWaitTimeout =")
C_PENDING = line_containing(SOURCE_TEXT, "CJGUI_INTERNAL_RENDERER_PENDING =")
ENUM_KIND = block(SOURCE_TEXT, "enum class JobKind {") + ";"
ENUM_PHASE = block(SOURCE_TEXT, "enum class JobPhase {") + ";"
WAITABLE = block(SOURCE_TEXT, "struct WaitableJob {") + ";"

PREFIX = r'''
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <iostream>
#include <mutex>
#include <thread>
using CjguiInternalRendererStatus = int32_t;
constexpr int32_t CJGUI_INTERNAL_RENDERER_OK = 0;
constexpr int32_t CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 3;
constexpr int32_t CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE = 4;
'''


def compile_and_run(cpp, mutate=None):
    src = PREFIX + "\n" + C_PENDING + "\n" + C_TIMEOUT + "\n" + ENUM_KIND + "\n" + ENUM_PHASE + "\n"
    waitable = WAITABLE
    if mutate:
        before, after = mutate
        if before not in waitable:
            raise ValueError("mutation target not found: " + before)
        waitable = waitable.replace(before, after)
    src += waitable + "\n" + cpp
    with tempfile.TemporaryDirectory() as d:
        p = pathlib.Path(d) / "t.cpp"
        p.write_text(src)
        exe = pathlib.Path(d) / "t"
        cp = subprocess.run(
            ["clang++", "-std=c++17", "-Wall", "-Wextra", "-pthread", str(p), "-o", str(exe)],
            capture_output=True, text=True)
        if cp.returncode != 0:
            raise AssertionError("compile failed:\n" + cp.stderr)
        run = subprocess.run([str(exe)], capture_output=True, text=True)
        return run.returncode, run.stdout, run.stderr


# --- 四个时序场景 + 正控，写在宿主 main() 里，用真实线程驱动真实 WaitableJob ---

MAIN = r'''
int main() {
    // 1) 许可前超时：真实 waitFor 在 Queued 超时 → Cancelled、非 OK，此后不得取得许可。
    {
        WaitableJob job(JobKind::Present);
        CjguiInternalRendererStatus rc = job.waitFor();
        if (rc != CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE) { std::cout << "S1-status\n"; return 1; }
        if (job.phaseSnapshot() != JobPhase::Cancelled) { std::cout << "S1-phase\n"; return 1; }
        if (job.acquireCommitPermission()) { std::cout << "S1-late-permission\n"; return 1; }
        if (!job.consumeCancelIfRequested()) { std::cout << "S1-cancel-not-observed\n"; return 1; }
    }

    // 2) 许可后 PENDING：渲染线程已取得许可（Committing），真实 waitFor 超时返回 PENDING 且不改写阶段。
    {
        WaitableJob job(JobKind::Present);
        std::atomic<bool> permission{false};
        std::atomic<bool> release{false};
        std::thread render([&] {
            job.markRunning();
            permission.store(job.acquireCommitPermission());
            while (!release.load()) { std::this_thread::sleep_for(std::chrono::milliseconds(2)); }
            job.finish(CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE);  // Flush 前拒绝落点
        });
        CjguiInternalRendererStatus rc = job.waitFor();  // 真实超时路径
        bool committed = permission.load();
        if (!committed) { std::cout << "S2-no-permission\n"; release.store(true); render.join(); return 1; }
        if (rc != CJGUI_INTERNAL_RENDERER_PENDING) { std::cout << "S2-not-pending\n"; release.store(true); render.join(); return 1; }
        if (job.phaseSnapshot() != JobPhase::Committing) { std::cout << "S2-phase-rewritten\n"; release.store(true); render.join(); return 1; }
        release.store(true);
        render.join();
        if (job.phaseSnapshot() != JobPhase::Done) { std::cout << "S2-not-done\n"; return 1; }
        if (job.statusSnapshot() != CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE) { std::cout << "S2-status\n"; return 1; }
        job.finish(CJGUI_INTERNAL_RENDERER_OK);  // 终态后重复 finish 不得覆写
        if (job.statusSnapshot() != CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE) { std::cout << "S2-overwrite\n"; return 1; }
    }

    // 3) 许可后正常终结：finish(OK) 让被 park 的 waitFor 返回 OK。
    {
        WaitableJob job(JobKind::Present);
        std::thread render([&] {
            job.markRunning();
            if (!job.acquireCommitPermission()) { std::cout << "S3-permission\n"; return; }
            std::this_thread::sleep_for(std::chrono::milliseconds(200));
            job.finish(CJGUI_INTERNAL_RENDERER_OK);
        });
        CjguiInternalRendererStatus rc = job.waitFor();
        render.join();
        if (rc != CJGUI_INTERNAL_RENDERER_OK) { std::cout << "S3-status\n"; return 1; }
        if (job.phaseSnapshot() != JobPhase::Done) { std::cout << "S3-phase\n"; return 1; }
    }

    std::cout << "ALL-OK\n";
    return 0;
}
'''

MUTATION = (
    "if (phase != JobPhase::Queued && phase != JobPhase::Running) return false;",
    "if (false) return false;  // mutation: grant permission in any phase",
)


class CommitOrderNative(unittest.TestCase):
    def test_real_state_machine_orderings(self):
        rc, out, err = compile_and_run(MAIN)
        self.assertEqual(rc, 0, f"stdout={out} stderr={err}")
        self.assertIn("ALL-OK", out)

    def test_mutation_grant_any_phase_turns_red(self):
        rc, out, err = compile_and_run(MAIN, mutate=MUTATION)
        self.assertNotEqual(rc, 0, f"mutation should be red; stdout={out}")
        self.assertIn("S1-late-permission", out)


if __name__ == "__main__":
    unittest.main(verbosity=2)
