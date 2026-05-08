# P1 渲染器真实 draw call 分支后续边界决策

状态：完成 / docs-only / 不新增 runtime owner

## 读取入口

本轮已先读取设计意图入口：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [P1 设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [real draw call first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-draw-call-first-implementation-slice-manifest.md)
- [real draw call first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-draw-call-first-implementation-slice-manifest-stabilization-closure-review.md)
- [runtime_renderer_draw_call_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_real.cj)
- [runtime_renderer_pipeline_state_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_real.cj)
- [render execution implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [renderer state write implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-admission-manifest.md)

## 当前结论

`CjguiInternalRendererNoRealDrawCallShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawCallShellDraft()` 足够作为当前 no-real-draw-call shell endpoint。

该 endpoint 只代表 draw call shell intent、primitive command denial proof、geometry binding denial proof、draw ordering admission shell、draw execution denial proof 与 no-real-draw-call-shell readiness facts。

它不是真实 draw call、resource binding、GPU submission、render execution、renderer state write、backend ready truth、public diagnostics 或 public API permission。

## 候选取舍

- A 胜出：进入 `P1 internal Renderer real render execution first implementation preflight decision`。理由是 draw call shell 已完成 manifest 封账，下一步仍是 docs-only preflight，不直接执行 render。
- B 暂缓：draw call shell hardening。当前未发现 shell facts 缺口。
- C 暂缓：native bridge draw execution write-set preflight。当前下一步不需要 native bridge / Metal / AppKit 写集。
- D 拒绝：直接 render / GPU submission / commit / state write / public API。

## 同构边界刹车

不得把 `CjguiInternalRendererNoRealDrawCallShellReadiness`、draw call slice manifest、build / smoke evidence 或 topic manifest 包装成 draw-ready wrapper、render-ready wrapper、GPU-submission wrapper、completion-ready wrapper、renderer-state-write wrapper、public diagnostics wrapper 或 receipt / record / publication。

下一步只能评估 real render execution first implementation preflight；不能跳过 preflight 直接执行 render，也不能把 no-real-draw-call shell 解释成真实 draw command、resource binding 或 GPU submission permission。

## 停止线

- no real render execution
- no GPU submission
- no `commit`
- no `present`
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no pipeline / buffer / texture / resource binding
- no real encoder
- no real render pass
- no real command buffer
- no `renderCommandEncoder`
- no `endEncoding`
- no `commandBuffer`
- no `nextDrawable`
- no renderer state write
- no `runtime_state.cj` modification
- no public API / C ABI
- no native bridge / Objective-C / Metal / AppKit / FFI
- no native handle / raw pointer
- no retain / release / destroy
- no module-level mutable `var`

## 设计意图出口自检

- 本轮改变主题状态：是，从 real draw call branch closure 推进到 real render execution preflight。
- 本轮改变 canonical tail / endpoint：否，当前 tail 仍是 `CjguiInternalRendererNoRealDrawCallShellReadiness`。
- 本轮改变 owner / truth / stop-line：否，只确认既有 owner 与 stop-line。
- 本轮改变唯一 next opening：是，转为 `P1 internal Renderer real render execution first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real render execution first implementation preflight decision`
