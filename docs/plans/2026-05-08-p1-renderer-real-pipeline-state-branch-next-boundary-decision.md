# P1 渲染器真实 pipeline state 分支后续边界决策

状态：完成 / docs-only / 不新增 runtime owner

## 读取入口

本轮已先读取设计意图入口：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [P1 设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [real pipeline state first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-slice-manifest.md)
- [real pipeline state first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-pipeline-state-first-implementation-slice-manifest-stabilization-closure-review.md)
- [runtime_renderer_pipeline_state_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_real.cj)
- [runtime_renderer_encoder_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder_real.cj)
- [draw call implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)
- [draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)

## 当前结论

`CjguiInternalRendererNoRealPipelineStateShellReadiness` / `cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft()` 足够作为当前 no-real-pipeline-state shell endpoint。

该 endpoint 只代表 pipeline state shell intent、shader function denial proof、pipeline descriptor denial proof、pipeline binding denial proof、compatibility failure classification 与 no-real-pipeline-state-shell readiness facts。

它不是真实 pipeline state、shader function load / compile、pipeline descriptor creation、pipeline / buffer / texture / resource binding、draw call、GPU submission、render、renderer state write、backend ready truth 或 public API permission。

## 候选取舍

- A 胜出：进入 `P1 internal Renderer real draw call first implementation preflight decision`。理由是 pipeline state shell 已完成 manifest 封账，下一步仍是 docs-only preflight，不直接打开 draw call 实现。
- B 暂缓：pipeline state shell hardening。当前未发现 shell facts 缺口。
- C 暂缓：native bridge pipeline write-set preflight。当前下一步不需要 native bridge / Metal / AppKit 写集。
- D 拒绝：直接 draw call / resource binding / GPU / render / state write / public API。

## 同构边界刹车

不得把 `CjguiInternalRendererNoRealPipelineStateShellReadiness`、pipeline state slice manifest、build / smoke evidence 或 topic manifest 包装成 pipeline-ready wrapper、shader-ready wrapper、binding-ready wrapper、draw-ready wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、public diagnostics wrapper 或 receipt / record / publication。

下一步只能评估 real draw call first implementation preflight；不能跳过 preflight 直接发出 draw command，也不能把 no-real-pipeline-state shell 解释成真实 pipeline state 或 binding permission。

## 停止线

- no real draw call
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no pipeline / buffer / texture / resource binding
- no real pipeline state
- no shader function load / compile
- no pipeline descriptor creation
- no real encoder
- no `renderCommandEncoder`
- no `endEncoding`
- no command buffer
- no `commandBuffer`
- no `commit`
- no `present`
- no `nextDrawable`
- no GPU submission
- no render execution
- no renderer state write
- no `runtime_state.cj` modification
- no public API / C ABI
- no native bridge / Objective-C / Metal / AppKit / FFI
- no native handle / raw pointer
- no retain / release / destroy
- no module-level mutable `var`

## 设计意图出口自检

- 本轮改变主题状态：是，从 real pipeline state branch closure 推进到 real draw call preflight。
- 本轮改变 canonical tail / endpoint：否，当前 tail 仍是 `CjguiInternalRendererNoRealPipelineStateShellReadiness`。
- 本轮改变 owner / truth / stop-line：否，只确认既有 owner 与 stop-line。
- 本轮改变唯一 next opening：是，转为 `P1 internal Renderer real draw call first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real draw call first implementation preflight decision`
