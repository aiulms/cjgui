# 渲染器真实 drawable 分支后续边界决策

日期：2026-05-08

状态：docs-only branch closure / no runtime truth

## 文件定位

本文件收口 `P1 internal Renderer real drawable branch closure / next real drawable decision`。本轮只确认 real drawable first-slice manifest 是否足够作为当前分支封账，并判断是否可以进入 real command buffer first implementation preflight。

本文件不修改 `.cj`，不新建 runtime owner，不获取 drawable，不调用 `nextDrawable` / `present`，不创建 command buffer，不提交 GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## 分支判断

确认 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()` 足够作为当前 no-real-drawable-shell endpoint。

该 endpoint 只代表 drawable shell intent、availability admission shell、acquisition denial proof、presentation denial proof、teardown failure classification 与 no-real-drawable-shell readiness facts。它不是 drawable acquisition、`nextDrawable`、present、command buffer、GPU submission、render、renderer state write、backend ready truth、public diagnostics 或 public API permission。

当前 first-slice manifest 已固定 owner / runtime input / endpoint / default draft / truth / stop-line，不需要继续新增 drawable-ready、backend-ready、GPU-submission、render-permission、receipt、record 或 publication wrapper。

## 候选比较

A 推荐：`P1 internal Renderer real command buffer first implementation preflight decision`

选择 A。理由是 drawable shell endpoint 已完成 manifest 封账，下一步只能 docs-only 评估 command buffer first slice runway，仍不得创建真实 command buffer 或靠近 `commit` / GPU submission。

B 暂缓：drawable shell hardening。

C 暂缓：native bridge drawable write-set preflight。

D 拒绝：直接 command buffer、`commit`、GPU submission、render、renderer state write、public API 或 C ABI expansion。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealDrawableShellReadiness`、real drawable lifecycle / admission manifest、smoke evidence 或 branch milestone 包装成 drawable-ready、command-buffer-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication。

若进入下一阶段，必须是 command buffer first implementation preflight，而不是继续同构 wrapper。

## 停止线

- no drawable acquisition。
- no `nextDrawable`。
- no `present`。
- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no render pass / encoder / pipeline / draw call。
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

- 本轮是否改变主题状态：是，从 real drawable first slice manifest stabilization completed 推进到 drawable branch closure completed。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，只确认既有 owner / truth / stop-line 足够作为分支封账。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real command buffer first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real command buffer first implementation preflight decision`
