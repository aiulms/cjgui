# P1 Renderer backend capability profile next-boundary decision

## 当前事实

上一轮已完成 `P1 internal Renderer backend contract value boundary bundle implementation`：

- owner file：[runtime_renderer_backend_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_contract.cj)
- 当前 endpoint：`CjguiInternalRendererBackendNoRenderContractReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererBackendContractDraft()`
- 输入只来自 `CjguiInternalRendererBackendNoRenderReadiness`
- 输出只表达 backend contract / capability set / adapter contract admission / no-render contract readiness value facts

`CjguiInternalRendererBackendNoRenderContractReadiness` 只表示 future backend contract boundary 可以继续评估。它不是 backend implementation，不是 Metal / AppKit adapter，不是 CAMetalLayer / MTLDevice / command buffer / GPU device，不是 native handle / raw pointer / platform object，不是 renderer state write，也不是 render permission。

P1 仍固定 full DisplayList / command list / batching packet rebuild only；不做 dirty-region / diff / patch / incremental render，不实现 Widget / Layout / Text / IME / Accessibility / ECS，不读取 Queue / Action / Runtime lower-level mutable facts，不扩 public surface，也不触碰 critical `runtime_state.cj`。

## 候选比较

### A. P1 internal Renderer backend capability profile boundary bundle implementation

选择。

理由：

- 当前 backend contract owner / truth / stop-line 已清楚，适合进入下一层 capability profile facts。
- 下一刀可以新建 `runtime/cjgui/src/runtime_renderer_backend_capability.cj`，只消费 `CjguiInternalRendererBackendNoRenderContractReadiness`。
- 输出应限于 backend capability profile / feature placeholder / constraint profile / no-render capability readiness facts。
- capability 只能是 backend-agnostic placeholder / profile facts，不能变成具体平台能力枚举承诺，也不能授予 render / platform resource permission。

### B. backend contract manifest stabilization

不选。

理由：当前 closure 与 renderer manifest 已说明 `runtime_renderer_backend_contract.cj` 的 owner / truth / stop-line，未发现 manifest drift 或 owner 不清楚问题。此时只做 stabilization 会比 capability profile 更像文档空转。

### C. contract hardening / stop-line comment cleanup

不选。

理由：未发现现有 contract closure、runtime README 或 renderer manifest 的 stop-line 缺口。若下一轮 implementation 发现注释不足，可在新 owner 内补维护注释，而不是单开 cleanup。

### D. backend implementation / Metal adapter / AppKit adapter

拒绝。当前 readiness 不是 backend implementation permission，直接接 Metal / AppKit 会绕过 backend capability profile 与 platform resource stop-line。

### E. CAMetalLayer / MTLDevice / command buffer / native handle / raw pointer

拒绝。当前阶段不得创建或接收 platform resource / native handle / raw pointer，也不得形成 command buffer 或 GPU device ownership。

### F. render execution / draw call / GPU batching / draw-call merge

拒绝。当前 contract facts 不是 draw-call permission；P1 仍没有真实 draw op、GPU batching 或 renderer state write。

### G. dirty-region / diff / patch / incremental render

暂缓。P1 仍 full rebuild only；dirty-region / diff / patch 只能作为 future hints，不进入实现。

### H. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。Scene / Renderer input chain只保留 future semantic hint，不实现这些系统。

### I. Runtime / Queue / Action integration

暂缓。backend capability profile 第一刀不应读取 lower-level mutable facts，也不应接 runtime global state。

### J. public surface expansion

拒绝。当前 public allowlist 保持 `cjguiExperimentalQueueSubmitShellReady(): Bool`，本轮不新增 public symbol，也不改变 Bool-only shell。

### K. consolidation

不选。未发现明确 dead helper、duplicate projection 或 self-wrapping；不为 cleanup 而 cleanup。

## Decision

选择：

`P1 internal Renderer backend capability profile boundary bundle implementation`

## 下一轮 implementation scope

默认 write set：

- 新建 `runtime/cjgui/src/runtime_renderer_backend_capability.cj`
- 更新 runtime README / README / GUI_TASK_TRACKER / docs/plans README / relevant renderer manifest / closure
- 不回塞 `runtime_renderer_backend_contract.cj`
- 不触碰 `runtime_state.cj`

默认输入：

- 只消费 `CjguiInternalRendererBackendNoRenderContractReadiness`
- default draft 只调用 `cjguiInternalExecuteDefaultRendererBackendContractDraft()`

建议 symbols：

- `CjguiInternalRendererBackendCapabilityProfile`
- `CjguiInternalRendererBackendFeaturePlaceholder`
- `CjguiInternalRendererBackendConstraintProfile`
- `CjguiInternalRendererBackendNoRenderCapabilityReadiness`
- `cjguiInternalBuildRendererBackendCapabilityProfile`
- `cjguiInternalBuildRendererBackendFeaturePlaceholder`
- `cjguiInternalBuildRendererBackendConstraintProfile`
- `cjguiInternalBuildRendererBackendNoRenderCapabilityReadiness`
- `cjguiInternalExecuteDefaultRendererBackendCapabilityProfileDraft`

行为边界：

- open path：contract no-render readiness open / ready 且无 defer / block / inconsistent 时，形成 capability profile / feature placeholder / constraint profile / no-render capability readiness facts。
- defer-only：保持 defer，不伪造 capability readiness。
- blocked / inconsistent：fail-closed blocked，不伪造 backend capability profile success。
- no-render capability readiness 只表示 future capability boundary 可以继续评估，不代表可以 render。

## Stop-line

下一轮仍必须保持：

- no Metal / AppKit / backend implementation
- no CAMetalLayer / MTLDevice / command buffer
- no native handle / raw pointer / platform object
- capability 只能是 backend-agnostic placeholder / profile facts，不能变成具体平台能力枚举承诺
- no render / draw call
- no real draw op / GPU batching / draw-call merge
- no dirty-region / diff / patch / incremental render
- no Widget / Layout / Text / IME / Accessibility / ECS
- no Queue / Action / Runtime lower-level mutable facts
- no public symbol expansion; keep `cjguiExperimentalQueueSubmitShellReady(): Bool` unchanged
- no `runtime_state.cj`

## 当前 next opening

`P1 internal Renderer backend capability profile boundary bundle implementation`
