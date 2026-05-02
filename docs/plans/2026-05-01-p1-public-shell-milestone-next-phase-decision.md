# P1 public shell milestone next phase decision

日期：2026-05-01

状态：docs-only decision

## Current Facts

- Experimental public submit shell milestone stabilization 已完成。
- 当前唯一 public symbol allowlist 仍是 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Bool-only signature 保留。
- 没有第二个 public symbol。
- 没有 structured public return。
- 没有 `enqueue` 命名。
- 没有 public C ABI、real enqueue、queue write、drain、scheduler / event loop 或 runtime cycle。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。
- Public submit shell milestone manifest 已存在：[2026-05-01-p1-experimental-public-submit-shell-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-experimental-public-submit-shell-milestone-manifest.md)。

## Decision

选择 H：`P1 Scene / Renderer input preflight decision`。

不继续扩 public surface。第一个 public shell 已经完成 visibility probe 与 Bool-only result hardening，继续扩第二个 public symbol 或 structured return 会过早形成 compatibility surface。下一步应转向更基础、更有战略价值的 Scene / Renderer input contract preflight。

## Candidate Comparison

- A. expand second public symbol：拒绝。刚封第一个 public shell milestone，继续扩面会快速形成 compatibility surface。
- B. structured public result preflight：暂缓。当前 Bool-only shell 足够作为 API visibility probe，structured return 会扩大 public compatibility surface。
- C. public C ABI preflight：拒绝。C ABI 需要 stable handle / lifecycle / error ABI，当前 public shell milestone 不提供这些承诺。
- D. real enqueue / queue write：拒绝。public shell / Bool result facts 不是真实 queue write permission。
- E. drain / scheduler / event loop：拒绝。当前仍太早靠近 runtime cycle。
- F. runtime state integration：暂缓。该方向会靠近 critical `runtime_state.cj` / global runtime state。
- G. return to internal queue/runtime hardening：暂不选。当前没有明确 dead helper、重复 projection 或 self-wrapping cleanup 对象；为了 cleanup 而 cleanup 不值得。
- H. Scene / Renderer input preflight：选择。public API 可见性探针已封账，Queue / Action Router runway 已证明 internal-to-public boundary 可治理；下一块更有价值的是定义 semantic scene 与 dehydrated display list 的中间契约。
- I. Queue public shell milestone / next phase checkpoint：暂不选。milestone manifest 已经完成封账，若再做 checkpoint 容易文档空转；直接进入 docs-only Scene / Renderer input preflight更有推进力。

## Public Surface Decision

本 decision 明确不继续扩 public surface：

- 不新增第二个 public symbol。
- 不修改 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- 不新增 structured public return。
- 不使用 `enqueue` 命名。
- 不承诺 stable public API compatibility。
- 不开放 public C ABI。
- 不 real enqueue / queue write。

## Scene / Renderer Input Preflight Scope

下一轮只做 docs-only preflight，不写 runtime code。必须回答：

- Scene / Renderer input contract 的 owner 应是谁。
- 上游 semantic `SceneSnapshot` 保留哪些 truth。
- 下游 flat `DisplayList` / `RenderCommandList` / `RendererInputPacket` 应如何表达。
- `RenderNode` / render component facts 是否应作为中间层。
- 初期是否只允许 full DisplayList rebuild。
- stable id / bounds / clip / z-order / material key / version / repaint hint 如何预留。
- 如何避免把 Scene / Renderer preflight 误写成 Widget / Layout / Text / IME / Accessibility implementation。

## Scene / Renderer Stop-line

下一轮仍禁止：

- Metal / AppKit / Objective-C / platform bridge。
- platform object / native handle / raw pointer。
- renderer code。
- Widget / Layout / Text / IME / Accessibility implementation。
- Dirty Region / Repaint Boundary / DisplayList diff / patch。
- event loop / scheduler / drain / runtime cycle。
- runtime global state write。
- `runtime_state.cj` modification。
- `runtime/cjgui/cjpm.toml` modification。

## Radar Alignment

该选择与 [P1 AI-Native Architecture Radar / Future Plan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-ai-native-architecture-radar-future-plan.md) 一致：P1 只吸收 Scene / DisplayList 的工程神韵，优先定义 stable id + flat DisplayList / RenderCommandList contract，不实现 ECS engine、CRDT engine、renderer backend、Metal / AppKit bridge 或真实 rendering。

## Next Opening

`P1 Scene / Renderer input preflight decision`
