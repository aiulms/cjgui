# 渲染器真实 command queue 分支后续边界决策

日期：2026-05-08

状态：docs-only branch closure / no runtime truth

## 文件定位

本文件收口 `P1 internal Renderer real command queue branch closure / next real command queue decision`。它确认 command queue first slice manifest 已足够作为本阶段封账，并选择下一步是否进入 real drawable first implementation preflight。

本轮 docs-only，不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不获取 drawable，不调用 `nextDrawable`，不创建 command buffer，不提交 GPU work。

## 分支判断

确认 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()` 已足够作为当前 no-real-command-queue shell endpoint，且 [real command queue first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-manifest.md) 足够作为本分支阶段封账。

当前 endpoint 只代表 command queue shell / creation admission shell / ownership proof / teardown proof / failure classification / no-real-command-queue-shell readiness facts。它不是真实 `MTLCommandQueue`、`newCommandQueue`、drawable、command buffer、GPU submission、render、renderer state write、backend ready truth 或 public API permission。

## 候选判断

A 推荐：`P1 internal Renderer real drawable first implementation preflight decision`

选择 A。下一步仍是 docs-only preflight，只评估是否可以打开 real drawable 第一实现切片 runway；不得直接获取 drawable 或调用 `nextDrawable`。

B 暂缓：native bridge drawable write-set preflight。

C 暂缓：command queue shell hardening。

D 拒绝：直接 drawable acquisition / `nextDrawable` / command buffer / GPU / render / state write / public API。

## 同形边界刹车

不得把 command queue shell endpoint、slice manifest、旧 lifecycle manifest、implementation admission manifest 或 smoke evidence 包成 drawable-ready、queue-ready、backend-ready、native-handle-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper。

## 停止线

- no drawable acquisition。
- no `nextDrawable`。
- no command buffer。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no native bridge / Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no public diagnostics / API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 command queue first slice manifest stabilization completed 推进到 command queue branch closure completed。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，只确认 command queue 分支封账足够。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real drawable first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real drawable first implementation preflight decision`
