# P1 Renderer adapter selection next-boundary decision

## 当前事实

上一轮已完成 `P1 internal Renderer backend capability profile boundary bundle implementation`：

- owner file：[runtime_renderer_backend_capability.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_capability.cj)
- 当前 endpoint：`CjguiInternalRendererBackendNoRenderCapabilityReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererBackendCapabilityDraft()`
- 输入只来自 `CjguiInternalRendererBackendNoRenderContractReadiness`
- 输出只表达 backend capability profile / feature placeholder / constraint profile / no-render capability readiness value facts

`CjguiInternalRendererBackendNoRenderCapabilityReadiness` 只表示 future backend capability boundary 可以继续评估。它不是 backend implementation，不是具体平台能力承诺，不是 platform resource permission，不是 command buffer / GPU device，也不是 render permission。

P1 仍固定 full DisplayList / command list / batching packet rebuild only；不做 dirty-region / diff / patch / incremental render，不实现 Widget / Layout / Text / IME / Accessibility / ECS，不读取 Queue / Action / Runtime lower-level mutable facts，不扩 public surface，也不触碰 critical `runtime_state.cj`。

## 候选比较

### A. P1 internal Renderer adapter selection value boundary bundle implementation

选择。

理由：

- 当前 capability profile owner / truth / stop-line 已清楚，适合进入 adapter selection 的 internal value facts。
- 下一刀可以新建 `runtime/cjgui/src/runtime_renderer_adapter_selection.cj`，只消费 `CjguiInternalRendererBackendNoRenderCapabilityReadiness`。
- 输出应限于 adapter selection policy / adapter candidate family / selection admission / no-render selection readiness facts。
- adapter candidate family 只能是 backend-agnostic placeholder / family facts，不能变成具体平台选择、Metal / AppKit adapter 承诺或 render permission。

### B. capability manifest stabilization

不选。

理由：现有 closure、runtime README 和 renderer material / batching manifest 已说明 capability owner / truth / stop-line，未发现 manifest drift 或 owner 不清楚问题。此时只做 stabilization 会延缓必要的 downstream adapter selection boundary。

### C. capability hardening / stop-line comment cleanup

不选。

理由：未发现 `runtime_renderer_backend_capability.cj` 或 closure 的注释 / stop-line 缺口。若下一轮 implementation 发现新 owner 需要维护注释，应在新 owner 内补齐，而不是单开 cleanup。

### D. concrete Metal adapter selection / AppKit adapter selection

拒绝。当前 capability readiness 不是具体平台选择许可；不能选择 Metal、AppKit 或任何具体平台 adapter。

### E. CAMetalLayer / MTLDevice / command buffer / native handle / raw pointer

拒绝。当前阶段不得创建、接收或拥有 platform resource / native handle / raw pointer，也不得形成 command buffer 或 GPU device ownership。

### F. render execution / draw call / GPU batching / draw-call merge

拒绝。当前 capability facts 不是 draw-call permission；P1 仍没有真实 draw op、GPU batching、draw-call merge 或 renderer state write。

### G. dirty-region / diff / patch / incremental render

暂缓。P1 仍 full rebuild only；dirty-region / diff / patch 只能作为 future hints，不进入实现。

### H. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。Scene / Renderer input chain只保留 future semantic hint，不实现这些系统。

### I. Runtime / Queue / Action integration

暂缓。adapter selection 第一刀不应读取 lower-level mutable facts，也不应接 runtime global state。

### J. public surface expansion

拒绝。当前 public allowlist 保持 `cjguiExperimentalQueueSubmitShellReady(): Bool`，下一轮不新增 public symbol，也不改变 Bool-only shell。

### K. consolidation

不选。未发现明确 dead helper、duplicate projection 或 self-wrapping；不为 cleanup 而 cleanup。

## Decision

选择：

`P1 internal Renderer adapter selection value boundary bundle implementation`

## 下一轮 implementation scope

默认 write set：

- 新建 `runtime/cjgui/src/runtime_renderer_adapter_selection.cj`
- 更新 runtime README / README / GUI_TASK_TRACKER / docs/plans README / relevant renderer manifest / closure
- 不回塞 `runtime_renderer_backend_capability.cj`
- 不触碰 `runtime_state.cj`

默认输入：

- 只消费 `CjguiInternalRendererBackendNoRenderCapabilityReadiness`
- default draft 只调用 `cjguiInternalExecuteDefaultRendererBackendCapabilityDraft()`

建议 symbols：

- `CjguiInternalRendererAdapterSelectionPolicy`
- `CjguiInternalRendererAdapterCandidateFamily`
- `CjguiInternalRendererAdapterSelectionAdmission`
- `CjguiInternalRendererBackendNoRenderSelectionReadiness`
- `cjguiInternalBuildRendererAdapterSelectionPolicy`
- `cjguiInternalBuildRendererAdapterCandidateFamily`
- `cjguiInternalBuildRendererAdapterSelectionAdmission`
- `cjguiInternalBuildRendererBackendNoRenderSelectionReadiness`
- `cjguiInternalExecuteDefaultRendererAdapterSelectionDraft`

行为边界：

- open path：backend no-render capability readiness open / ready 且无 defer / block / inconsistent 时，形成 adapter selection policy / candidate family / selection admission / no-render selection readiness facts。
- defer-only：保持 defer，不伪造 selection readiness。
- blocked / inconsistent：fail-closed blocked，不伪造 adapter selection success。
- no-render selection readiness 只表示 future adapter selection boundary 可以继续评估，不代表选择了具体平台 adapter，也不代表可以 render。

## Stop-line

下一轮仍必须保持：

- no concrete platform adapter selection; no Metal / AppKit adapter implementation
- no CAMetalLayer / MTLDevice / command buffer
- no native handle / raw pointer / platform object
- adapter candidate family 只能是 backend-agnostic placeholder / family facts，不能变成具体平台承诺
- no render / draw call
- no real draw op / GPU batching / draw-call merge
- no dirty-region / diff / patch / incremental render
- no Widget / Layout / Text / IME / Accessibility / ECS
- no Queue / Action / Runtime lower-level mutable facts
- no public symbol expansion; keep `cjguiExperimentalQueueSubmitShellReady(): Bool` unchanged
- no `runtime_state.cj`

## 当前 next opening

`P1 internal Renderer adapter selection value boundary bundle implementation`
