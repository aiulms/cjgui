# P1 Internal Runtime Model Compaction / Naming Normalization Decision

## Context

本轮对当前 internal runtime / lifecycle model 做短 compaction 和质量判断。指定 closure / compaction 文件均存在，未使用 fallback。

当前 internal chain 已完成到：

- readiness / root
- step / cycle / command draft / command pipeline
- driver pass / report
- run intent / run request / run boundary
- AppRun surface / controller / execution plan / dispatch
- RunLoopDraft / LoopIterationDraft / IterationWorkPacketDraft
- LifecycleWorkDraft / OwnerHandoff
- MutationReadiness / MutationPlan / CommitGate / ApplyDraft
- StateMutation / OutcomeDraft

## Quality Signals

当前模型的优点是：仍然 internal-only，owner split 已开始从 `runtime_state.cj` 切回 app/window lifecycle owners，每层都有 open / blocked 可验证路径，blocked path fail-closed，first state mutation 使用 immutable-copy，并且没有越界到 public API、public C ABI、platform callback、queue / drain 或 event loop。

这说明当前代码不是“坏代码 / 反模式”本身。它是 P1 internal scaffolding，用于验证 truth boundary、owner boundary 和状态演化链。这个阶段的 request / report / sanity 链路有明确工程价值。

但当前模型债务也已经显现：类型名过长，request/report 嵌套链很深，派生 Bool 字段较多，`didBuild* = true` marker 信息量偏低，sanity helpers 数量膨胀，`runtime_state.cj` 仍然偏胖，README / tracker 也越来越长。

## External Criticism Judgment

不接受“这就是坏代码 / 反模式”的结论，因为它忽略了当前阶段是 internal scaffolding，而不是长期 public runtime design。

接受“后续需要模型压缩”的提醒。当前 scaffolding 不能直接当作长期生产形态；如果继续拉长链条，命名、嵌套和低信息量 marker 会开始拖累阅读、验证和后续 refactor。

## Decision

不建议继续拉长 lifecycle 链条。下一步建议进入一个 bounded model compaction slice，并且必须是 behavior-preserving。

第一刀不要大规模重命名全链路，不做跨文件大重构。推荐先选局部区域做模型压缩试点：

`Lifecycle State Mutation Outcome model normalization`

目标：

- 保持 public surface 仍为 none。
- 保持 build / sanity 通过。
- 尝试减少低价值 always-true marker，或记录为什么不能安全移除。
- 评估派生 Bool 应保留为 stored field、helper function 还是 property-style read surface。
- 不跨文件大重构，不改变 mutation semantics。

## Recommended Next Opening

`P1 lifecycle state mutation outcome model normalization bundle implementation`

## Next-Slice Authorization Suggestion

- Prompt weight: W2 behavior-preserving refactor slice。
- 允许修改 `runtime_state.cj` 中 OutcomeDraft 局部 types / functions / sanity。
- 允许更新 runtime README、tracker 和 closure。
- 不允许改变 mutation semantics。
- 不允许改变 app/window state shape。
- 不允许改变 owner mutation functions。
- 不允许新增 public API / C ABI。
- 不允许进入 platform callback、queue / drain 或 event loop。
- 不允许跨全链路重命名。

## Stop-Line

本 decision 不写 runtime code，不创建 preflight / execution card，不重构代码，不改变行为，不新增 `CJGUI_TRUTH_MANIFEST.md`，不修改 `AGENTS.md` / `CLAUDE.md`。
