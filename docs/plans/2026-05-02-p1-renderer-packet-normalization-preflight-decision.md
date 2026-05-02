# P1 Renderer packet normalization preflight decision

日期：2026-05-02

本轮任务：完成 `P1 internal Renderer packet normalization preflight decision`。

本轮是 docs-only preflight，不写 runtime code，不修改 `.cj` 文件，不运行 build / smoke。

## Current Context

Renderer command packet validation 已由 manifest 封账：

- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)

当前 canonical endpoint：

- `CjguiInternalRendererCommandValidationResult`
- `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`

它只表达 backend-agnostic command / batching packet integrity facts：

- full rebuild only。
- stable node id。
- bounds。
- clip。
- z-order。
- material key。
- version。
- invalidation / repaint hint。
- placeholder command kind。
- batch key hint。
- ordering hint。
- dehydrated batching plan。

它不是 backend shell、platform adapter、Metal / AppKit、command buffer、renderer state write、render permission 或真实 draw / batching。

## Preflight Question

是否进入 packet normalization value boundary？

本 preflight 判定 normalization 可以作为下一刀，但必须限定为 backend-agnostic value facts，用来固定 packet shape、ordering facts、material grouping hints、stable ids 与 version facts。

Normalization 不允许执行排序 side effect，不允许做 diff / patch，不允许生成 backend packet / command buffer，也不允许 render。

## Proposed Owner / Truth

若下一轮 implementation，默认新建 owner file：

- `runtime/cjgui/src/runtime_renderer_packet_normalization.cj`

唯一入口：

- `CjguiInternalRendererCommandValidationResult`

默认 draft：

- 只能调用 `cjguiInternalExecuteDefaultRendererCommandValidationDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不回塞 `runtime_renderer_command_validation.cj`。
- 不触碰 `runtime_state.cj`。

Suggested internal value-style symbols：

- `CjguiInternalRendererNormalizedPacketCandidate`
- `CjguiInternalRendererNormalizedOrderingFacts`
- `CjguiInternalRendererNormalizedMaterialGroupingFacts`
- `CjguiInternalRendererPacketNormalizationResult`

Suggested builders / default draft：

- `cjguiInternalBuildRendererNormalizedPacketCandidate`
- `cjguiInternalBuildRendererNormalizedOrderingFacts`
- `cjguiInternalBuildRendererNormalizedMaterialGroupingFacts`
- `cjguiInternalBuildRendererPacketNormalizationResult`
- `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft`

## Normalization Semantics

Normalized packet candidate：

- 只是 value facts，不是 backend packet。
- 只能投影 validated command / batching facts。
- 应保留 stable node id、bounds、clip、z-order、material key、version、invalidation hint 与 placeholder command kind。

Normalized ordering facts：

- 只声明当前 packet order 已被规范化描述。
- 不执行真实排序副作用。
- 不表示 backend scheduler、draw queue 或 render pass ordering 已存在。

Normalized material grouping facts：

- 只表达 backend-agnostic grouping hints。
- 不是真实 draw-call merge。
- 不是真实 GPU batching。
- 不是真实 GPU pipeline key。

Normalization result：

- 只表达 internal normalization value facts。
- 不是 render permission。
- 不是 backend permission。
- 不是 command buffer readiness。
- 不写 renderer state。

P1 仍保持 full DisplayList / command list / batching packet rebuild only，不做 dirty-region / diff / patch / incremental render。

## Candidate Comparison

### A. P1 internal Renderer packet normalization boundary bundle implementation

选择。

理由：

- Validation endpoint 已由 manifest 固定，下一步需要评估 validated packet 是否具有可审计的 normalized packet shape。
- Normalization 能新增明确语义：packet shape、ordering facts、material grouping hints、stable ids、version facts。
- 它回到 renderer packet value integrity 主线，不继续 validation receipt / record / publication 同构尾巴。
- 它仍是 backend-agnostic，不接平台后端、不执行排序、不 render。

### B. P1 internal Renderer validation error taxonomy boundary bundle implementation

暂缓。

当前 validation result 已表达 accepted / deferred / blocked / fail-closed facts。若后续发现 failure reason、degraded、blocked taxonomy 不足，可在 normalization preflight 后重新评估。

### C. P1 internal Renderer command packet validation consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才选。当前没有发现明确 cleanup 对象，不为 cleanup 而 cleanup。

### D. Packet normalization manifest-only

拒绝。

Owner / truth / input / output 已足够清楚。当前不需要先做 manifest-only stabilization；下一轮可以进入 implementation，但必须保持 stop-line。

### E. Validation receipt / record / publication

拒绝。

Same-shape Boundary Brake 已生效；这类 wrapper 会把 validation result 再包装成同构尾巴。

### F. Backend packet / command buffer / backend submission

拒绝。

Normalization result 不是 backend packet、command buffer 或 backend submission。

### G. Sorting side effect / draw-call merge / GPU batching

拒绝。

Ordering facts 只能是 value facts，不执行排序；material grouping 只能是 hint，不是真实 merge 或 GPU batching。

### H. Dirty-region / diff / patch / incremental render

暂缓。

P1 仍 full rebuild only。Normalization 不打开 diff / patch 或 incremental render。

### I. Metal / AppKit / CAMetalLayer / MTLDevice / native handle / raw pointer

拒绝。

Normalization 不接平台对象和 native resources。

### J. Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

这些需要独立 owner truth，不进入 packet normalization boundary。

### K. Runtime / Queue / Action integration

暂缓。

Normalization 只消费 command validation endpoint，不读取 Queue / Action / Runtime lower-level mutable facts。

### L. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Decision

选择：

`P1 internal Renderer packet normalization boundary bundle implementation`

## Next Opening

下一轮默认 owner / write set：

- 新建 `runtime/cjgui/src/runtime_renderer_packet_normalization.cj`。
- 只消费 `CjguiInternalRendererCommandValidationResult`。
- 只输出 internal backend-agnostic normalization value facts。
- 更新 runtime README / README / GUI_TASK_TRACKER / docs/plans README / relevant renderer manifest / closure。
- 不回塞 `runtime_renderer_command_validation.cj`。
- 不触碰 `runtime_state.cj`。

下一轮 implementation 必须继续保持：

- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no stable backend API promise。
- no render / draw call。
- no real draw op / GPU batching / draw-call merge。
- no sorting side effect。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。

## Verification Plan

本轮验证：

- `git diff --check`
- Markdown absolute link missing target check
- README / GUI_TASK_TRACKER / docs/plans README can find this preflight and next opening
- forbidden check: no runtime code, no `runtime_state.cj`, no `runtime/cjgui/cjpm.toml`, no smoke / harness / native bridge / entry, no `AGENTS.md` / `CLAUDE.md` / `CANGJIE_ISSUE_LEDGER.md`
- public declaration scan: only `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged)`

本轮不运行 `cjpm build` / smoke guard，因为没有 runtime code change。
