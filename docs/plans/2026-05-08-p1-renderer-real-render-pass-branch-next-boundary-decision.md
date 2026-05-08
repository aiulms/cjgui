# 渲染器真实 render pass 分支后续边界决策

日期：2026-05-08

状态：docs-only decision / no runtime truth

## 文件定位

本文件收口 `P1 internal Renderer real render pass branch closure / next real render pass decision`。本轮只确认 real render pass first slice 是否足够作为当前 shell 分支封账，并选择后续入口；不修改 `.cj`，不新建 runtime owner，不创建真实 render pass descriptor，不创建 attachment / texture view，不创建 encoder，不调用 `renderCommandEncoder` / `endEncoding`，不进入 GPU submission、render、renderer state write 或 public API。

## 分支确认

`CjguiInternalRendererNoRealRenderPassShellReadiness` / `cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()` 足够作为当前 no-real-render-pass shell endpoint。

该 endpoint 只代表 real render pass shell intent / render pass descriptor admission shell / attachment denial proof / encoder denial proof / render pass teardown / failure classification / no-real-render-pass-shell readiness facts。

它不是真实 render pass descriptor、attachment、texture view、encoder、`renderCommandEncoder`、`endEncoding`、command buffer、`commandBuffer`、`commit`、`present`、`nextDrawable`、GPU submission、render、renderer state write、backend ready truth、public diagnostics 或 public API permission。

[real render pass first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-slice-manifest.md) 与对应 closure 已足够封账当前 first slice。继续新增 render-pass-ready 或 encoder-ready thin wrapper 会违反 Same-shape Boundary Brake。

## 候选结论

候选 A 胜出：`P1 internal Renderer real encoder first implementation preflight decision`。

选择理由：

- real render pass shell endpoint 已提供 encoder planning 所需的 no-render-pass-descriptor、no attachment、no texture view、no encoder factory、no encoding finalization、no command buffer factory、no work submit、no render execution、no state mutation 与 no public diagnostics facts。
- 下一步仍是 docs-only preflight，只评估是否打开 real encoder 第一刀 runway。
- 下一步不得创建真实 encoder，不得调用 `renderCommandEncoder` 或 `endEncoding`，不得绑定 pipeline / buffer / texture / resource，不得提交 GPU work 或写 renderer state。

候选 B 暂缓：render pass shell hardening。当前未发现 shell / denial / teardown / failure classification facts 缺口。

候选 C 暂缓：native bridge render pass write-set preflight。当前下一步不需要修改 native bridge / Objective-C / Metal / AppKit / FFI。

候选 D 拒绝：direct encoder / binding / command buffer / commit / GPU / render / state write / public API。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealRenderPassShellReadiness`、first slice manifest、旧 lifecycle / implementation admission manifest 或 smoke evidence 包装成 render-pass-ready permission、encoder-ready permission、binding-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

若进入下一阶段，必须是 encoder shell intent / encoder creation admission shell / binding denial proof / end-encoding denial proof / teardown failure classification / no-real-encoder-shell readiness 语义，而不是同构 wrapper。

## 停止线

- no real render pass descriptor creation。
- no attachment / texture view。
- no real encoder creation。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no pipeline / buffer / texture / resource binding。
- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no `present`。
- no `nextDrawable`。
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

- 本轮是否改变主题状态：是，从 real render pass first slice manifest stabilization completed 推进到 real render pass branch closure completed。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealRenderPassShellReadiness` / `cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，只确认既有 render pass shell owner / truth / stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real encoder first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real encoder first implementation preflight decision`

