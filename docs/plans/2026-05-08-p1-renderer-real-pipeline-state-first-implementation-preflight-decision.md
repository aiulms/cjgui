# 渲染器真实 pipeline state 第一刀实现预检

日期：2026-05-08

状态：docs-only preflight / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real pipeline state first implementation preflight decision`。本轮只评估是否允许打开 real pipeline state 第一实现切片 runway；不修改 `.cj`，不新增 runtime owner，不创建真实 pipeline state，不加载或编译 shader function，不创建 pipeline descriptor，不绑定 pipeline、buffer、texture 或 resource。

## 上游证据

`CjguiInternalRendererNoRealEncoderShellReadiness` / `cjguiInternalExecuteDefaultRendererRealEncoderShellDraft()` 足够作为进入 real pipeline state planning 的上游 endpoint。

该 endpoint 只表达 encoder shell intent / encoder creation admission shell / binding denial proof / end-encoding denial proof / encoder teardown / failure classification / no-real-encoder-shell readiness facts。它不是 encoder creation、pipeline binding、shader、GPU submission、render、renderer state write 或 public API permission。

旧 pipeline state lifecycle endpoint `CjguiInternalRendererNoPipelineStateReadiness` 与 implementation admission endpoint `CjguiInternalRendererNoPipelineStateImplementationReadiness` 只作为 vocabulary / admission evidence；它们不是本轮 runtime input，也不能升格为真实 pipeline state 或 shader permission。

## runway 判断

允许打开 real pipeline state first implementation slice，但下一步必须保持极窄 internal owner shell / dehydrated pipeline result facts。

默认 owner candidate：

- `runtime/cjgui/src/runtime_renderer_pipeline_state_real.cj`

runtime input candidate：

- `CjguiInternalRendererNoRealEncoderShellReadiness`

输出 truth candidate 仅限：

- real pipeline state shell intent。
- shader function denial proof。
- pipeline descriptor denial proof。
- pipeline binding denial proof。
- compatibility failure classification。
- no-real-pipeline-state-shell readiness facts。

第一刀不得创建真实 pipeline state、不得加载 / 编译 shader function、不得创建 pipeline descriptor、不得绑定 pipeline / buffer / texture / resource、不得触碰 native bridge / Objective-C / Metal / AppKit / FFI。

## 候选结论

候选 A 胜出：`P1 internal Renderer real pipeline state first implementation slice bundle`。

选择理由：

- 可以用 owner-local shell facts 表达 shader denial、descriptor denial、pipeline binding denial 与 compatibility failure classification，不需要触碰 native bridge 或 Metal runtime。
- `CjguiInternalRendererNoRealEncoderShellReadiness` 已提供足够的上游 no-real-encoder evidence，可作为 pipeline shell 的唯一 runtime input。
- 下一步仍不创建 `MTLRenderPipelineState`、shader function、descriptor、pipeline binding 或 GPU work。

候选 B 暂缓：pipeline state shell hardening。当前 preflight 未发现必须先硬化的事实缺口。

候选 C 暂缓：native bridge pipeline write-set preflight。下一步不修改 native bridge / Objective-C / Metal / AppKit / C ABI / FFI。

候选 D 拒绝：direct pipeline state / shader / descriptor / binding / GPU / render / renderer state write / public API。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealEncoderShellReadiness`、旧 pipeline state lifecycle / admission manifest、smoke evidence 或 topic manifest 包装成 pipeline-ready、shader-ready、descriptor-ready、binding-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication。

若选择 A，下一轮必须新增 real pipeline state shell / shader function denial / descriptor denial / pipeline binding denial / compatibility failure classification / no-real-pipeline-state-shell 语义，而不是薄包装。

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

- 本轮是否改变主题状态：是，从 real encoder branch next-boundary decision completed 推进到 real pipeline state first implementation preflight completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 runtime tail 仍是 `CjguiInternalRendererNoRealEncoderShellReadiness`；下一轮 candidate endpoint 才是 `CjguiInternalRendererNoRealPipelineStateShellReadiness`。
- 本轮是否改变 owner / truth / stop-line：否，本轮只做 docs-only preflight，未新增 owner。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real pipeline state first implementation slice bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real pipeline state first implementation slice bundle`
