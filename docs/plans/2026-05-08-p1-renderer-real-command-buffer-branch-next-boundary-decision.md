# 渲染器真实 command buffer 分支后续边界决策

日期：2026-05-08

状态：docs-only decision / no runtime truth

## 文件定位

本文件收口 `P1 internal Renderer real command buffer branch closure / next real command buffer decision`。本轮只判断 real command buffer first slice 是否足够作为当前 shell 分支封账，并选择后续入口；不修改 `.cj`，不新建 runtime owner，不创建真实 command buffer，不调用 `commandBuffer` / `commit`，不进入 render pass / encoder / GPU submission / render / renderer state write / public API。

## 分支确认

`CjguiInternalRendererNoRealCommandBufferShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft()` 足够作为当前 no-real-command-buffer shell endpoint。

该 endpoint 只代表 command buffer shell intent / command buffer creation admission shell / commit denial proof / completion denial proof / command buffer teardown / failure classification / no-real-command-buffer-shell readiness facts。

它不是真实 command buffer、`commandBuffer`、`commit`、GPU submission、render pass、encoder、render、renderer state write、backend ready truth、public diagnostics 或 public API permission。

`2026-05-08-p1-renderer-real-command-buffer-first-implementation-slice-manifest.md` 与对应 closure 已足够封账当前 first slice。继续新增 command-buffer-ready thin wrapper 会违反 Same-shape Boundary Brake。

## 候选结论

候选 A 胜出：`P1 internal Renderer real render pass first implementation preflight decision`。

选择理由：

- real command buffer shell endpoint 已提供 render pass planning 所需的 no-command-buffer-object、no factory invocation、no work submit、no render execution、no state mutation 与 no public diagnostics facts。
- 下一步仍是 docs-only preflight，只评估是否打开 real render pass 第一刀 runway。
- 下一步不得创建 render pass descriptor、attachment、texture view、encoder、command buffer、GPU work 或 renderer state write。

候选 B 暂缓：command buffer shell hardening。当前未发现 shell / denial / teardown / failure classification facts 缺口。

候选 C 暂缓：native bridge command buffer write-set preflight。当前下一步不需要修改 native bridge / Objective-C / Metal / AppKit / FFI。

候选 D 拒绝：direct render pass / encoder / command buffer / commit / GPU / render / state write / public API。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealCommandBufferShellReadiness`、first slice manifest、旧 lifecycle / implementation admission manifest 或 smoke evidence 包装成 command-buffer-ready permission、render-pass-ready permission、encoder-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

若进入下一阶段，必须是 render pass shell intent / descriptor admission shell / attachment denial proof / encoder denial proof / teardown failure classification / no-real-render-pass-shell readiness 语义，而不是同构 wrapper。

## 停止线

- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no `present`。
- no `nextDrawable`。
- no real render pass descriptor。
- no attachment / texture view。
- no encoder。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no pipeline / buffer / texture / resource binding。
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

- 本轮是否改变主题状态：是，从 command buffer first slice manifest stabilization completed 推进到 command buffer branch closure completed。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealCommandBufferShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，只确认既有 command buffer shell owner / truth / stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real render pass first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real render pass first implementation preflight decision`
