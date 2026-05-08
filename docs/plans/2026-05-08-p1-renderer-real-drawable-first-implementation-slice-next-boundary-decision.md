# 渲染器真实 drawable 第一刀切片后续边界决策

日期：2026-05-08

状态：docs-only next-boundary / no runtime truth

## 文件定位

本文件收口 `P1 internal Renderer real drawable first implementation slice closure / next real drawable decision`。本轮确认 [runtime_renderer_drawable_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_real.cj) 的当前 shell endpoint 是否足够，不修改 `.cj`，不新建 runtime owner，不获取 drawable，不调用 `nextDrawable`。

## 端点判断

确认 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()` 足够作为当前 no-real-drawable-shell endpoint。

该 endpoint 只代表 drawable shell intent、drawable availability admission shell、drawable acquisition denial proof、presentation denial proof、drawable teardown / failure classification 与 no-real-drawable-shell readiness facts。它不是真实 drawable permission、`nextDrawable` permission、present permission、command buffer permission、GPU submission permission、render permission、renderer state write permission、backend ready truth 或 public API permission。

## 候选判断

A 推荐：`P1 internal Renderer real drawable first implementation slice manifest stabilization bundle implementation`

选择 A。当前 owner shell 已有 closure，下一步只做 manifest 封账，固定 owner / runtime input / canonical endpoint / default draft / current truth / stop-line。

B 暂缓：native bridge drawable write-set preflight。

C 暂缓：drawable shell hardening。

D 拒绝：直接 drawable acquisition、`nextDrawable`、present、command buffer、GPU submission、renderer state write、public API、receipt / record / publication。

## 停止线

- no drawable acquisition。
- no `nextDrawable`。
- no `present`。
- no command buffer。
- no `commit`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no native bridge / Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no public diagnostics / API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real drawable first implementation slice completed 推进到 next-boundary decision completed。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，只确认现有 owner / truth / stop-line 足够进入 manifest stabilization。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real drawable first implementation slice manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real drawable first implementation slice manifest stabilization bundle implementation`
