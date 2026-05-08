# 渲染器真实 pipeline state 第一刀切片后续边界决策

日期：2026-05-08

状态：docs-only decision / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real pipeline state first implementation slice closure / next real pipeline state decision`。本轮只确认 `CjguiInternalRendererNoRealPipelineStateShellReadiness` / `cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft()` 是否足够作为当前 no-real-pipeline-state shell endpoint，并选择是否进入 manifest stabilization；不修改 `.cj`，不新增 runtime owner，不创建真实 pipeline state、shader function、pipeline descriptor 或 binding relation。

## endpoint 确认

`CjguiInternalRendererNoRealPipelineStateShellReadiness` / `cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft()` 足够作为当前 no-real-pipeline-state-shell endpoint。

当前 owner shell 只代表 real pipeline state shell intent / shader function denial proof / pipeline descriptor denial proof / pipeline binding denial proof / compatibility failure classification / no-real-pipeline-state-shell readiness facts。

它不是真实 pipeline state permission、shader function permission、pipeline descriptor permission、pipeline binding permission、buffer / texture / resource binding permission、encoder permission、GPU submission permission、render permission、renderer state write permission、public diagnostics 或 public API permission。

## 候选结论

候选 A 胜出：`P1 internal Renderer real pipeline state first implementation slice manifest stabilization bundle implementation`。

选择理由：

- `cjpm build` 与 auto-close smoke 已通过，新增 owner shell 可编译且不依赖 native bridge / Metal。
- 当前 endpoint 已包含 shader denial、descriptor denial、binding denial 与 compatibility failure classification，足够进入 manifest 封账。
- 继续新增 pipeline-ready thin wrapper 会违反 Same-shape Boundary Brake。

候选 B 暂缓：native bridge pipeline write-set preflight。当前下一步只做 manifest stabilization，不需要 native bridge / Metal / AppKit write-set。

候选 C 暂缓：real draw call first implementation preflight。draw call 更靠近 GPU work，应在 pipeline state shell manifest 封账后再评估。

候选 D 暂缓：pipeline state shell hardening。当前未发现 shell facts 缺口。

候选 E 拒绝：direct pipeline state / shader / descriptor / binding / GPU / render / state write / public API。

## 同形边界刹车

`CjguiInternalRendererNoRealPipelineStateShellReadiness` 不得继续包装成 pipeline-ready wrapper、shader-ready wrapper、descriptor-ready wrapper、binding-ready wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、public diagnostics wrapper、receipt、record 或 publication。

下一步若选择 manifest stabilization，只能固定 owner / truth / canonical endpoint / stop-line。

## 停止线

- no real pipeline state creation。
- no shader function load / compile。
- no pipeline descriptor creation。
- no pipeline binding。
- no buffer / texture / resource binding。
- no real encoder creation。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no real render pass descriptor creation。
- no attachment / texture view。
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

- 本轮是否改变主题状态：是，从 real pipeline state first implementation slice completed 推进到 slice next-boundary decision completed。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealPipelineStateShellReadiness` / `cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，只确认既有 pipeline state shell owner / truth / stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real pipeline state first implementation slice manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real pipeline state first implementation slice manifest stabilization bundle implementation`
