# 渲染器真实 command buffer 第一刀预检决策

日期：2026-05-08

状态：docs-only preflight / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real command buffer first implementation preflight decision`。本轮只判断是否可以从 real drawable shell endpoint 进入 command buffer 第一实现切片 runway，不创建真实 command buffer，不调用 `commandBuffer`，不调用 `commit`，不进入 render pass、encoder、pipeline、draw call、GPU submission、render 或 renderer state write。

## 证据读取结论

`CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()` 已完成 manifest 封账，足够作为 real command buffer planning 的上游 endpoint。

旧 lifecycle endpoint `CjguiInternalRendererNoCommandBufferReadiness` 与 implementation admission endpoint `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 只作为 vocabulary / historical evidence。它们不作为本 first-slice runtime input，也不授予 command buffer、`commandBuffer`、`commit`、render pass、encoder、GPU submission、render、state write 或 public API permission。

command submission、render execution 与 renderer state write 相关 manifest 继续提供 stop-line evidence：当前仍无 `commit`、无 `present`、无 GPU submission、无 render execution、无 renderer state write、无 completion callback publication。

## 预检判断

可以打开 real command buffer first implementation runway，但下一步只能新增极窄 internal owner shell / dehydrated command buffer result facts。

默认 owner candidate：

- `runtime/cjgui/src/runtime_renderer_command_buffer_real.cj`

唯一 runtime input candidate：

- `CjguiInternalRendererNoRealDrawableShellReadiness`

允许表达的 facts 仅限：

- real command buffer shell intent。
- command buffer creation admission shell。
- commit denial proof。
- completion denial proof。
- command buffer teardown / failure classification。
- no-real-command-buffer-shell readiness facts。

## 候选比较

A 推荐：`P1 internal Renderer real command buffer first implementation slice bundle`

选择 A。下一刀可新增 internal-only owner shell，但不得创建真实 command buffer，不得调用 `commandBuffer` / `commit`，不得修改 native bridge、Objective-C、Metal、AppKit、C ABI 或 FFI。

B 暂缓：command buffer shell hardening。

C 暂缓：native bridge command buffer write-set preflight。

D 拒绝：直接 command buffer creation、`commandBuffer`、`commit`、render pass、encoder、pipeline、draw call、GPU submission、render、renderer state write、public API / C ABI expansion。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealDrawableShellReadiness`、旧 command buffer lifecycle / implementation admission manifest、command submission evidence 或 smoke evidence 包成 command-buffer-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

若下一步选择 implementation slice，新增 owner 必须提供 command buffer shell / creation admission shell / commit denial / completion denial / teardown failure classification 语义，而不是薄包装 drawable shell endpoint。

## 停止线

- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no `present`。
- no `nextDrawable`。
- no drawable acquisition。
- no render pass。
- no encoder。
- no pipeline state。
- no draw call。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no public diagnostics / API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 drawable branch closure completed 推进到 real command buffer first implementation preflight completed。
- 本轮是否改变 canonical tail / endpoint：否，本轮 docs-only；下一刀 candidate 才可能新增 `CjguiInternalRendererNoRealCommandBufferShellReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，冻结下一刀 owner candidate、truth vocabulary 与 no-command-buffer / no-GPU / no-state / no-public stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real command buffer first implementation slice bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real command buffer first implementation slice bundle`
