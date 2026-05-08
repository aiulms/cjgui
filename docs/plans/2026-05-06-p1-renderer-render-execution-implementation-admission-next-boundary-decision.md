# P1 渲染器渲染执行实现准入收口与下一步决策

日期：2026-05-06

状态：docs-only next-boundary decision

## 入口依据

本轮先读取设计意图导航入口：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)

本决策只用于收口 render execution implementation admission value boundary 的下一步，不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，不授权真实 render、GPU submission、command submission、presentation、renderer state write 或 public API。

## 决策结论

确认 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()` 足够作为当前 no-render-execution-implementation endpoint。

选择下一步：

`P1 internal Renderer render execution implementation admission manifest stabilization bundle implementation`

下一步仍必须 docs-only，不修改 `.cj`，只固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line / Same-shape Boundary Brake。不得继续把当前 endpoint 包成 render-ready wrapper、completion wrapper、command-submission wrapper、presentation wrapper、GPU-submission wrapper、renderer-state-write wrapper、receipt / record / publication 或 public API wrapper。

## 端点确认

当前 owner 是 [runtime_renderer_render_execution_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_execution_admission.cj)。它的唯一 runtime input 是 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`。

当前 canonical endpoint 是：

- `CjguiInternalRendererNoRenderExecutionImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()`

当前 endpoint 只代表以下 value facts：

- render execution implementation intent
- execution admission policy
- completion observation admission guard
- rollback admission policy
- no-render-execution-implementation readiness

它不是 render permission、GPU submission permission、command submission permission、presentation permission、completion callback permission、renderer state write permission 或 public API permission。

## 候选比较

### 候选 A：推荐并选择

`P1 internal Renderer render execution implementation admission manifest stabilization bundle implementation`

选择 A。理由是 value boundary closure 已证明当前 endpoint 足够封账，下一刀应固定 owner / truth / canonical endpoint / stop-line，而不是继续新增 tail wrapper。

### 候选 B 到 D：暂缓

renderer state write implementation preflight、completion observation hardening、command submission / presentation hardening 均暂缓。当前 endpoint 已足够表达 no-render-execution-implementation readiness facts；若未来靠近 completion callback、command submission、presentation、state visibility 或 state mutation，必须另开 docs-only preflight。

### 候选 E 到 K：拒绝

拒绝 direct render execution implementation、direct command buffer commit / GPU submission、direct drawable present / acquisition、direct encoder / draw call / resource binding、renderer state write、public API / C ABI expansion、receipt / record / publication。

## 同构边界刹车

`CjguiInternalRendererNoRenderExecutionImplementationReadiness` 不得继续包装成：

- render-ready wrapper
- completion wrapper
- command-submission wrapper
- presentation wrapper
- GPU-submission wrapper
- renderer-state-write wrapper
- receipt / record / publication
- public API wrapper

下一步若进入 manifest stabilization，只能固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line / Same-shape Boundary Brake。它不能表达 render 可执行、command buffer 可提交、drawable 可 present、GPU work 可提交、completion callback 可注册、renderer state 可写或 public API 可扩展。

## 停止线

本轮与下一步继续保持：

- no render execution
- no GPU submission
- no `commit`
- no `present`
- no `nextDrawable`
- no command buffer creation / submission
- no encoder creation
- no `renderCommandEncoder`
- no `endEncoding`
- no draw call
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no pipeline / buffer / texture / sampler / resource binding
- no native handle
- no raw pointer
- no C ABI
- no FFI declaration
- no bridge call
- no retain / release / destroy
- no Metal / AppKit / Objective-C
- no renderer state write
- no public API

## 文档同步

本决策作为以下文档的 downstream：

- [render execution implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-preflight-decision.md)
- [draw call implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)
- [render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)

同步入口：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [Renderer implementation admission chain topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)

## 下游 manifest 封账

本决策的 manifest stabilization 已完成：

- [render execution implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md)
- [render execution implementation admission manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-execution-implementation-admission-manifest-stabilization-closure-review.md)

该 downstream 只固定 [runtime_renderer_render_execution_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_execution_admission.cj) 的 owner / truth / canonical endpoint / default draft / runtime input / stop-line，不新增 tail wrapper，不授权 render、GPU submission、command submission、presentation、completion callback、renderer state write 或 public API。

新的唯一后续入口转为：

`P1 internal Renderer renderer state write implementation preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，render execution implementation admission 从 value boundary closure 转入 manifest stabilization 待执行。
- 本轮是否改变 canonical tail / endpoint：否，仍为 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，owner、current truth 与 stop-line 只被确认，不被扩展。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer render execution implementation admission manifest stabilization bundle implementation`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`。
- 若未同步，理由：不适用。

## 验证清单

本轮必须验证：

- `git diff --check`
- 新 decision no-index whitespace check
- Markdown absolute link missing target check，限定 project docs scope，避开 `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability
- Markdown 中文标题与正文抽查
- forbidden check：确认无 tracked `.cj` diff、无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`
- public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

## 唯一后续入口

`P1 internal Renderer renderer state write implementation preflight decision`
