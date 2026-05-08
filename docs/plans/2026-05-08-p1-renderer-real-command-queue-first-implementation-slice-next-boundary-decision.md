# 渲染器真实 command queue 第一刀切片后续边界决策

日期：2026-05-08

状态：docs-only next-boundary / no runtime truth

## 文件定位

本文件收口 `P1 internal Renderer real command queue first implementation slice closure / next real command queue decision`。本轮只确认 [runtime_renderer_command_queue_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_real.cj) 的当前 shell endpoint 是否足够，不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke。

本文件不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不把 command queue shell、旧 lifecycle endpoint、implementation admission manifest 或 smoke evidence 升格为 queue-ready permission。

## 端点判断

确认 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()` 足够作为当前 no-real-command-queue shell endpoint。

该 endpoint 只代表 command queue shell intent、queue creation admission shell、command queue ownership proof、command queue teardown proof、command queue failure classification 与 no-real-command-queue-shell readiness facts。旧 `CjguiInternalRendererNoRealCommandQueueReadiness` 仍归 lifecycle owner [runtime_renderer_real_command_queue.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_queue.cj)，不是本 first-slice endpoint。

## 明确非许可

`CjguiInternalRendererNoRealCommandQueueShellReadiness` 不是真实 `MTLCommandQueue` permission、`newCommandQueue` permission、native handle permission、drawable permission、command buffer permission、GPU submission permission、render permission、renderer state write permission、backend ready truth、public diagnostics permission 或 public API permission。

下一步不得把该 endpoint 继续包成 queue-ready、backend-ready、native-handle-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper。

## 候选判断

A 推荐：`P1 internal Renderer real command queue first implementation slice manifest stabilization bundle implementation`

选择 A。当前 owner shell 已有 closure、build 和 smoke 证据；下一步应只做 manifest 封账，固定 owner / runtime input / canonical endpoint / default draft / current truth / stop-line。

B 暂缓：native bridge command queue write-set preflight。

C 暂缓：command queue shell hardening。

D 拒绝：直接 drawable acquisition / `nextDrawable` / command buffer / GPU / render / state write / public API。

## 停止线

- no real `MTLCommandQueue`。
- no `newCommandQueue`。
- no native bridge / Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no drawable acquisition。
- no `nextDrawable`。
- no command buffer。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics / API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 command queue first implementation slice completed 推进到 next-boundary decision completed。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，只确认现有 owner / truth / stop-line 足够进入 manifest stabilization。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real command queue first implementation slice manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real command queue first implementation slice manifest stabilization bundle implementation`
