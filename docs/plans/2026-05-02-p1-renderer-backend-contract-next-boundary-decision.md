# P1 Renderer backend contract next-boundary decision

日期：2026-05-02

状态：docs-only decision

## Current Facts

- `P1 internal Renderer backend-adapter value boundary bundle implementation` 已完成。
- 当前 owner file 是 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_adapter.cj`。
- 当前 endpoint 是 `CjguiInternalRendererBackendNoRenderReadiness` / `cjguiInternalExecuteDefaultRendererBackendAdapterDraft()`。
- `CjguiInternalRendererBackendNoRenderReadiness` 只消费 `CjguiInternalRendererPacketHandoffReceipt`，表达 backend adapter candidate / capability placeholder / adapter admission / no-render readiness value facts。
- no-render readiness 只表示 future adapter boundary 可以继续评估。
- 它不是 backend object、Metal adapter、AppKit adapter、CAMetalLayer owner、MTLDevice、command buffer、GPU device、native handle、raw pointer、renderer state write、draw-call permission 或 render execution。
- P1 仍是 full DisplayList / command list / batching packet rebuild only。
- 当前不做 dirty-region / diff / patch / incremental render。
- 当前不实现 Widget / Layout / Text / IME / Accessibility / ECS。
- 当前不读取 Queue / Action / Runtime lower-level mutable facts。
- public allowlist 未变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- `runtime_state.cj` 未触碰且仍为 10065 行 critical warning。

## Decision Question

`CjguiInternalRendererBackendNoRenderReadiness` 之后，下一刀是否进入 backend contract value boundary，还是先做 manifest stabilization / capability taxonomy / stop-line hardening？

## Candidate Comparison

- A. `P1 internal Renderer backend contract value boundary bundle implementation`：选择。backend-adapter value boundary 已经把 handoff receipt 收束到 no-render readiness；下一刀应把 adapter-adjacent readiness 交给新的 backend contract owner，表达 backend contract / capability set / adapter contract admission / no-render contract readiness facts。它仍是 internal value-style contract，不是真实 backend。
- B. backend-adapter manifest stabilization：不选择。closure 与 renderer manifest 已记录 owner / truth / stop-line；当前没有明显 manifest drift，继续 stabilization 会让 renderer backend runway 原地空转。
- C. capability taxonomy docs-only：不选择。capability vocabulary 可以在 backend contract value facts 中 bounded 表达；单开 taxonomy 容易变成薄文档层。
- D. backend implementation / Metal adapter / AppKit adapter：拒绝。当前缺少 platform lifecycle、native handle policy、command buffer safety、backend ownership 和 render verification。
- E. CAMetalLayer / MTLDevice / command buffer / native handle / raw pointer：拒绝。这些都是平台资源或执行资源，不能从 no-render readiness 直接打开。
- F. render execution / draw call / GPU batching / draw-call merge：拒绝。当前 command kind、batch key、batching plan 仍是 placeholder / hint / dehydrated facts。
- G. dirty-region / diff / patch / incremental render：暂缓。P1 仍 full rebuild only，增量渲染只保留 future hint，不实现算法或 patch。
- H. Widget / Layout / Text / IME / Accessibility / ECS：暂缓。Scene / Renderer runway 仍在 renderer packet / adapter / contract value boundary。
- I. Runtime / Queue / Action integration：暂缓。当前 renderer path 不读取 lower-level mutable facts，也不靠近 `runtime_state.cj`。
- J. public surface expansion：拒绝。experimental public submit shell milestone 已封账，public allowlist 不扩第二个 symbol。
- K. consolidation：不选择。当前未发现明确 dead helper、duplicate projection 或 same-owner self-wrapping；下一步应进入 downstream backend contract owner，而不是 cleanup。

## Final Decision

选择 A：

- `P1 internal Renderer backend contract value boundary bundle implementation`

理由：

- `CjguiInternalRendererBackendNoRenderReadiness` 已经明确“可继续评估但不可 render”的边界。
- backend contract value boundary 能把 adapter readiness 继续降风险为 contract / capability / admission facts，而不是直接接真实 backend。
- 新 owner 可以避免把 `runtime_renderer_backend_adapter.cj` 变成 adapter-adjacent thin-tail 堆叠，也符合 Tail Endpoint Exit Gate。
- capability vocabulary 不需要先单独 docs-only taxonomy；可以作为 contract value facts 的一部分，由下一轮 implementation 以 bounded symbols 表达。

## Next Implementation Scope

下一轮默认 owner / write set：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_contract.cj`。
- 只消费 `CjguiInternalRendererBackendNoRenderReadiness`。
- 只输出 internal value-style backend contract facts。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/README.md`。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`。
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`。
- 更新 relevant renderer manifest / closure as needed。
- 不回塞 `runtime_renderer_backend_adapter.cj`。
- 不触碰 `runtime_state.cj`。

下一轮 suggested value-style symbols：

- `CjguiInternalRendererBackendContract`
- `CjguiInternalRendererBackendCapabilitySet`
- `CjguiInternalRendererBackendContractAdmission`
- `CjguiInternalRendererBackendContractNoRenderReadiness`

下一轮 default draft 只能调用：

- `cjguiInternalExecuteDefaultRendererBackendAdapterDraft()`

再构建 backend contract / capability set / contract admission / no-render contract readiness pipeline。

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

- `cjpm build --target-dir /tmp/cjgui-renderer-backend-contract-value-boundary-target --skip-script`。
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

本 decision 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Opening

`P1 internal Renderer backend contract value boundary bundle implementation`
