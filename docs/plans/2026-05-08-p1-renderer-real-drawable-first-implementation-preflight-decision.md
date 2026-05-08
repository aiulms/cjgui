# 渲染器真实 drawable 第一刀实现预检决策

日期：2026-05-08

状态：docs-only preflight / no drawable acquisition / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real drawable first implementation preflight decision`。本轮只判断 command queue shell endpoint 封账后，是否可以打开 real drawable 第一实现切片 runway。

本轮 docs-only，不修改 `.cj`，不新增 runtime owner，不运行 `cjpm build` / smoke，不获取 drawable，不调用 `nextDrawable`，不调用 `present`，不创建 command buffer，不提交 GPU work，不执行 render，不写 renderer state，不修改 native bridge / Objective-C / Metal / AppKit / C ABI / FFI，也不扩 public API。

## 上游端点判断

确认 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()` 足够作为 real drawable first implementation planning 的上游 endpoint。

理由：

- command queue first slice manifest 已固定 owner、runtime input、endpoint、default draft、truth 与 stop-line。
- command queue shell endpoint 只代表 command queue shell / creation admission shell / ownership proof / teardown proof / failure classification facts，不是真实 queue permission。
- real drawable lifecycle manifest 与 real drawable implementation admission manifest 已提供 availability、acquisition denial、presentation ownership、no-drawable 与 failure vocabulary evidence，但仍不是 runtime truth。

## 第一切片判断

选择打开 real drawable 第一实现切片 runway，但下一步只能是极窄 internal owner shell / dehydrated drawable result facts。

默认 owner candidate：

- `runtime/cjgui/src/runtime_renderer_drawable_real.cj`

runtime input candidate：

- `CjguiInternalRendererNoRealCommandQueueShellReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`

输出 truth candidate 只限：

- drawable shell intent。
- drawable availability admission shell。
- drawable acquisition denial proof。
- presentation denial proof。
- drawable teardown / failure classification。
- no-real-drawable-shell readiness facts。

这些 facts 不得获取 drawable，不得调用 `nextDrawable` 或 `present`，不得创建 command buffer，不得创建 native handle / raw pointer，不得新增 C ABI / FFI，不得调用 native bridge / Metal / AppKit / Objective-C，不得提交 GPU work、执行 render、写 renderer state 或发布 public API。

## 候选判断

A 推荐：`P1 internal Renderer real drawable first implementation slice bundle`

选择 A。下一步最多新增一个 internal-only owner shell，并保持 no drawable acquisition / no native / no GPU stop-line。

B fallback：native bridge drawable write-set preflight。

C fallback：real drawable smoke-only lab probe preflight。

D 暂缓：drawable acquisition admission hardening。

E 拒绝：直接 drawable acquisition、`nextDrawable`、`present`、command buffer、GPU submission、render、renderer state write、public API / C ABI expansion、receipt / record / publication 或任何 permission wrapper。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealCommandQueueShellReadiness`、real drawable lifecycle manifest、implementation admission manifest、smoke evidence 或 branch milestone 包装成 drawable-ready permission、queue-ready permission、backend-ready permission、native-handle permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

若下一轮选择 A，必须新增 drawable shell / availability admission shell / acquisition denial proof / presentation denial proof / teardown / failure classification / no-real-drawable-shell readiness 语义，而不是薄包装 command queue shell endpoint。

## 停止线

- no drawable acquisition。
- no `nextDrawable`。
- no `present`。
- no command buffer / `commandBuffer`。
- no `commit`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no native bridge / Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no public diagnostics / API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 command queue branch closure completed 推进到 real drawable first implementation preflight completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 runtime endpoint 仍是 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`；本轮只固定下一刀 drawable shell endpoint 方向。
- 本轮是否改变 owner / truth / stop-line：是，docs-only 固定下一刀 owner candidate、runtime input candidate、truth vocabulary 与 stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real drawable first implementation slice bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real drawable first implementation slice bundle`
