# 渲染器真实 encoder 分支后续边界决策

日期：2026-05-08

状态：docs-only decision / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real encoder branch closure / next real encoder decision`。本轮只确认 real encoder first slice 是否已经足够作为当前 no-real-encoder shell endpoint，并选择是否进入 real pipeline state first implementation preflight；不修改 `.cj`，不新增 runtime owner，不创建真实 encoder，不调用 `renderCommandEncoder` 或 `endEncoding`，不绑定 pipeline、buffer、texture 或 resource。

## 端点确认

`CjguiInternalRendererNoRealEncoderShellReadiness` / `cjguiInternalExecuteDefaultRendererRealEncoderShellDraft()` 足够作为当前 no-real-encoder-shell endpoint。

当前 endpoint 只代表 real encoder shell intent / encoder creation admission shell / binding denial proof / end-encoding denial proof / encoder teardown / failure classification / no-real-encoder-shell readiness facts。

它不是真实 encoder permission、`renderCommandEncoder` permission、`endEncoding` permission、pipeline state permission、pipeline / buffer / texture / resource binding permission、GPU submission permission、render permission、renderer state write permission、backend ready truth、public diagnostics 或 public API permission。

## 候选结论

候选 A 胜出：`P1 internal Renderer real pipeline state first implementation preflight decision`。

选择理由：

- real encoder first slice manifest 已固定 owner、runtime input、canonical endpoint、default draft、truth 与 stop-line。
- 当前 endpoint 只提供 encoder shell / denial / teardown / failure classification evidence，足够作为 pipeline state first implementation planning 的上游 evidence。
- 下一步仍是 docs-only preflight，不会创建 pipeline state、shader function、pipeline descriptor 或 binding relation。
- 继续新增 encoder-ready thin wrapper 会违反 Same-shape Boundary Brake。

候选 B 暂缓：encoder shell hardening。当前未发现 shell facts 缺口。

候选 C 暂缓：native bridge encoder write-set preflight。下一步只评估 pipeline state shell runway，不触碰 native bridge / Objective-C / Metal / AppKit / FFI。

候选 D 拒绝：direct pipeline / shader / descriptor / binding / GPU / render / state write / public API。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealEncoderShellReadiness`、slice manifest、build / smoke evidence 或 topic manifest 包装成 encoder-ready、binding-ready、pipeline-ready、shader-ready、GPU-submission、render-permission、renderer-state-write、public diagnostics、receipt、record 或 publication wrapper。

若进入下一阶段，必须是 real pipeline state first implementation preflight，而不是继续同构 wrapper。

## 停止线

- no real encoder creation。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no pipeline state creation。
- no shader function load / compile。
- no pipeline descriptor creation。
- no pipeline / buffer / texture / resource binding。
- no real render pass descriptor creation。
- no attachment / texture view。
- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no `present`。
- no `nextDrawable`。
- no GPU submission / render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no public diagnostics / API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real encoder first implementation slice manifest stabilization completed 推进到 real encoder branch next-boundary decision completed。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealEncoderShellReadiness` / `cjguiInternalExecuteDefaultRendererRealEncoderShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，只确认既有 real encoder shell owner / truth / stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real pipeline state first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real pipeline state first implementation preflight decision`
