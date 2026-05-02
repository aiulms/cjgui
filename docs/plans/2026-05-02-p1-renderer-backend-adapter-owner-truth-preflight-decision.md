# P1 Renderer backend-adapter owner / truth preflight decision

日期：2026-05-02

状态：docs-only preflight / decision

## Current Facts

- `P1 internal Renderer backend-adapter preflight decision` 已批准进入 backend-adapter preflight。
- 当前 renderer handoff endpoint 是 `CjguiInternalRendererPacketHandoffReceipt` / `cjguiInternalExecuteDefaultRendererPacketHandoffDraft()`。
- Handoff receipt 来自 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_handoff.cj`。
- Handoff receipt 只消费 `CjguiInternalRenderBatchingPacket`，只表示 renderer packet handoff receipt facts。
- 它不是 backend adapter、Metal adapter、AppKit adapter、CAMetalLayer owner、command buffer、GPU device、native handle、raw pointer、renderer state write 或真实 render permission。
- P1 仍是 full DisplayList / command list / batching packet rebuild only。
- 当前不接 Metal / AppKit / backend / native handle / raw pointer / CAMetalLayer / command buffer。
- 当前不 render，不实现 draw call，不实现 real draw op / GPU batching / draw-call merge。
- 当前不实现 Widget / Layout / Text / IME / Accessibility / ECS。
- 当前不做 dirty-region / diff / patch / incremental render。
- 当前不读取 Queue / Action / Runtime lower-level mutable facts。
- `runtime_state.cj` 未修改且仍为 10065 行 critical warning。
- public allowlist 未变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Owner / Truth Conclusion

backend-adapter 第一刀应使用新 owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_adapter.cj`

理由：

- `runtime_scene_renderer_input.cj` 已是 SceneSnapshot / RenderNode / DisplayList / RenderCommand / material-batching hint 的 owner，不应继续承担 adapter-adjacent tail。
- `runtime_renderer_handoff.cj` 已完成 Tail Endpoint Exit Gate，把 `CjguiInternalRenderBatchingPacket` 交给 downstream handoff receipt，不应在同 owner 内继续追加 backend-adapter thin wrapper。
- 新 owner 能明确分离 renderer input / command facts 与 future backend-adapter preflight facts，防止 handoff receipt 被误读为 platform backend permission。
- 新 owner 仍只能持有 internal value-style candidate facts；不能持有 platform object、native handle、GPU device、command buffer、renderer state 或 render execution。

backend-adapter 第一刀只应消费：

- `CjguiInternalRendererPacketHandoffReceipt`

第一刀只应表达 internal value-style facts：

- backend adapter candidate。
- backend capability placeholder。
- adapter admission。
- no-render readiness。

这些 facts 只是 future backend adapter 的前置契约，不是 backend object、Metal / AppKit adapter、CAMetalLayer owner、command buffer、GPU device、native handle、raw pointer、renderer state write 或真实 render permission。

## Candidate Comparison

- A. `P1 internal Renderer backend-adapter value boundary bundle implementation`：选择。owner / truth / stop-line 已足够清楚；下一刀可以 bounded implementation，新建 `runtime_renderer_backend_adapter.cj`，只消费 `CjguiInternalRendererPacketHandoffReceipt`，只表达 backend adapter candidate / capability placeholder / adapter admission / no-render readiness value facts。
- B. backend-adapter manifest / stabilization only：不选择。当前没有明显 manifest drift；继续只做 stabilization 会让 backend-adapter runway 原地打转。
- C. backend capability taxonomy docs-only：不选择。capability vocabulary 可以作为 A 的 placeholder facts 内联表达，当前无需单开薄 taxonomy。
- D. Metal / AppKit / CAMetalLayer backend implementation：拒绝。当前没有 platform bridge、native handle、layer lifecycle、command buffer 或 render permission。
- E. command buffer / render execution：拒绝。handoff receipt 不授权 command buffer、render pass、draw submission 或 renderer state write。
- F. real draw op / GPU batching / draw-call merge：拒绝。当前 command kind、batch key、batching plan 仍是 placeholder / hint / dehydrated facts。
- G. Widget / Layout / Text / IME / Accessibility：暂缓。Scene / Renderer runway 仍在 renderer input / command / handoff / adapter preflight 层。
- H. dirty-region / diff / patch / incremental render：暂缓。P1 仍 full rebuild only，增量能力只保留 future audit hint。
- I. Runtime / Queue / Action integration：暂缓。当前 renderer path 不读取 lower-level mutable facts，也不得靠近 `runtime_state.cj`。
- J. public surface expansion：拒绝。public shell milestone 已封账，allowlist 不扩第二个 public symbol。
- K. consolidation：不选择。当前没有明确 dead helper、duplicate projection 或 self-wrapping；下一步应该落 backend-adapter value boundary，而不是 cleanup。

## Final Decision

选择 A：

- `P1 internal Renderer backend-adapter value boundary bundle implementation`

下一轮允许 bounded runtime implementation，但仅限新 owner 内的 internal value-style boundary facts。下一轮不批准真实 backend code、Metal / AppKit bridge、CAMetalLayer、MTLDevice、command buffer、GPU pipeline state、native handle、raw pointer、render execution、draw call、GPU batching、draw-call merge、dirty-region / diff / patch、public API expansion 或 `runtime_state.cj` 修改。

## Next Implementation Scope

下一轮默认 owner / write set：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_adapter.cj`。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/README.md`。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`。
- 更新 relevant renderer manifest / closure as needed。

下一轮默认 input：

- `CjguiInternalRendererPacketHandoffReceipt`

下一轮 suggested value-style symbols：

- `CjguiInternalRendererBackendAdapterCandidate`
- `CjguiInternalRendererBackendCapabilityPlaceholder`
- `CjguiInternalRendererBackendAdapterAdmission`
- `CjguiInternalRendererBackendNoRenderReadiness`

下一轮 default draft 只能调用：

- `cjguiInternalExecuteDefaultRendererPacketHandoffDraft()`

再构建 backend-adapter candidate / capability placeholder / admission / no-render readiness pipeline。

## Stop-line

下一轮必须继续禁止：

- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no GPU device / pipeline state / render pass。
- no render side effect / draw call execution。
- no real draw op semantics。
- no real GPU batching / draw-call merge。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Verification Requirements For Next Implementation

下一轮 implementation 必须验证：

- `cjpm build --target-dir /tmp/cjgui-renderer-backend-adapter-value-boundary-target --skip-script`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- `git diff --check`。
- Markdown absolute link missing target check。
- closure reachable from `GUI_TASK_TRACKER.md` and `docs/plans/README.md`。
- forbidden check：不得修改 `runtime_state.cj` / `runtime/cjgui/cjpm.toml` / smoke tracked source / harness / native bridge / entry / `AGENTS.md` / `CLAUDE.md` / `CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan：allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- source scan：不得出现 Metal / AppKit / CAMetalLayer / MTLDevice / command buffer / native handle / raw pointer / platform object / render execution / draw-call merge / GPU batching implementation。
- GitNexus impact for consumed input symbols and `gitnexus_detect_changes(scope=unstaged)`。

## Public Surface

public symbol allowlist 继续保持：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 preflight 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Opening

`P1 internal Renderer backend-adapter value boundary bundle implementation`
