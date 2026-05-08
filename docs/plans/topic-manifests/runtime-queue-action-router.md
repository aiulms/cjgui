# 运行时 / 队列 / Action Router 主题 manifest

状态：docs-only / topic manifest / no runtime truth

## 主题定位

本主题记录 runtime tail、state store、ingress、Action Router、Queue 和 experimental public submit shell 的 owner / truth / stop-line。

## 当前状态

Runtime tail 已从 execution-state loop closure 进入 state store transition 与 ingress manifest stabilization；Action Router 已完成 guarded execution、handoff downstream consumer 与 queue-adjacent integration；Queue 已推进到 public exposure gate / symbol readiness 与 experimental public submit shell value facts。

public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## 已落地现实

- runtime internal tail milestone 固定 default tail，不再无限新增 old tail wrapper。
- runtime state store transition 只表达 previous / next snapshot、version 与 transition value facts，不写 global mutable state。
- runtime ingress 固定 input / scheduler / coordinator ingress 主线，不直接成为 platform adapter truth。
- Action Router canonical endpoint 是 `CjguiInternalActionGuardedExecutionHandoffCandidate`，下游通过 action handoff / queue integration 消费。
- Queue public submit shell 是 Bool-only readiness projection，不返回 structured public result，不暴露 internal owner facts。

## 未落地与明确禁止

- Action Router 不执行真实 action，不接 AI provider / prompt / external agent。
- Queue public shell 不执行真实 enqueue、queue storage write、drain、scheduler、event loop 或 runtime cycle。
- 不新增 public C ABI，不新增第二个 public symbol，不承诺 stable public API compatibility。
- 不让 platform callback、runtime ingress 或 public shell 绕过 owner gate。

## 当前 owner 链摘要

Runtime 主题的当前 tail 从 `CjguiInternalRuntimeExecutionStateLoopClosure` 进入 value-style state store transition；Action Router 主题的 canonical endpoint 是 guarded execution handoff candidate；Queue 主题的 public-facing milestone 是 experimental submit shell Bool readiness projection。

## 关键文档链

- [runtime internal tail milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-internal-tail-milestone-manifest.md)
- [runtime state store transition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-state-store-transition-manifest.md)
- [runtime ingress manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-ingress-manifest.md)
- [Action Router manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-action-router-manifest.md)
- [experimental public submit shell milestone](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-experimental-public-submit-shell-milestone-manifest.md)
- [GUI task tracker](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## 下次开 gate 前必须读取

开 runtime tail、queue write、public surface、Action Router execution、AI action gateway、scheduler / event loop 或 public API gate 前，至少读取 runtime internal tail manifest、runtime state store transition manifest、Action Router manifest、experimental public submit shell milestone 和 tracker 当前段落。

## 推荐下一步

本主题不改变当前 Renderer next opening。Runtime / Queue / Action Router 后续若要扩 public surface，必须先新 visibility / compatibility / result-shape decision。

## 禁止误读点

- Action Router 是 zero-trust gateway，不是真实 action side effect。
- Queue public shell 不是真实 enqueue / drain。
- `cjguiExperimentalQueueSubmitShellReady(): Bool` 是唯一 public allowlist symbol，且是 experimental readiness projection。

## 维护备注

若未来新增 AI action、external agent、public action API 或 real queue storage，必须在本 manifest 更新 owner chain，并先通过 docs-only gate。
