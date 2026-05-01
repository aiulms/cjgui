# P1 AI-Native Architecture Radar / Future Plan

日期：2026-05-01

状态：future architecture radar / docs-only

本文件记录一组对 CJGUI 长期形态有价值的架构思想：代数效应、ECS、CRDT，以及它们和 Scene / DisplayList 渲染契约的关系。它不是 P1 implementation card，也不改变当前 Queue / Action Router / runtime owner runway。

## 背景

CJGUI 的长期目标不是在传统 GUI framework 后面外挂 AI provider，而是探索一层更底的 AI-native GUI runtime substrate：Owner truth、Intent / Action / Fact、Action Router、Queue、Store、Handoff、Scene / Renderer input 等核心契约要天然适合 AI 参与、审计、回放和拒绝。

近期讨论中出现了几个高价值概念：

- 代数效应：把“请求副作用”和“执行副作用”分离。
- ECS：用 stable entity id 与扁平组件数据替代深继承 Widget 对象树。
- CRDT / 差分同步：为未来人类与 AI 高频协作提供最终一致的操作模型。
- Scene Tree + DisplayList：上游保留语义投影，下游生成脱水、扁平、可批处理的 render command list。

这些概念和项目方向高度契合，但不应在 P1 阶段被完整实现或作为稳定依赖引入。

## 当前结论

P1 只吸收这些理论的工程收益，不引入它们的完整框架外壳：

- 不依赖仓颉实验性 Effect Handler。
- 不实现完整代数效应库。
- 不实现 ECS engine。
- 不实现 CRDT engine。
- 不引入 renderer / scene / widget / layout / text / IME / accessibility 真实实现。

P1 应继续使用最克制的数据结构兑现这些思想：

- enum / struct / value-style facts。
- admission / guard / readiness / handoff pipeline。
- stable id / version / owner / bounds / material key 等未来可增量化字段。
- fail-closed blocked facts。
- explicit stop-line 与 closure review。

一句话原则：

> 吸收代数效应、ECS、CRDT 的架构神韵；P1 只用 enum、struct、value pipeline、stable id 与 version facts 兑现收益，不依赖实验性语言特性或完整框架实现。

## 代数效应雷达

仓颉原始文档中存在 Effect Handler 相关编译选项：`--enable-eh`，并要求配合 `--experimental`；效应命令通过继承 `stdx.effect.Command` 定义。官方文档同时明确标注该能力仍是实验性特性，未来可能变化。

因此当前判断：

- 可以把 Effect Handler 作为未来语言能力观察项。
- 不把 `stdx.effect` 放进 P1 runtime core。
- 不修改 `cjpm.toml` 添加 `--enable-eh` / `--experimental`。
- 不让 runtime owner files 依赖 `perform` / `handle` / `resume`。

P1 的工程翻译：

- `ActionIntent` 表达想做什么。
- `EffectPlan` / `CommitCandidate` / `Finalization` 表达 future side effect facts。
- `Admission` / `Guard` / `Readiness` 表达执行前约束。
- `Handoff` 表达交给下游 owner，而不是本地直接执行。
- 顶层 future executor 才能解释这些 facts；当前不真实执行 side effect。

未来触发条件：

- 仓颉 Effect Handler 从实验性进入稳定能力，且工具链 / 调试 / profile / build pipeline 都能支撑。
- runtime 已有真实 Action execution / platform bridge / rollback / audit boundary。
- 有明确收益证明 Effect Handler 能减少复杂度，而不是增加控制流隐式性。

## ECS 雷达

ECS 的价值不在于马上引入一个 engine，而在于它提醒我们避免深继承、指针互相嵌套和渲染层递归遍历。

P1 / P2 的工程翻译：

- Scene / Render 未来应优先使用 stable id + 扁平结构体数组。
- Render System 只读 render components。
- AI / semantic system 只读 semantic components。
- Hit-test / accessibility 只读 geometry / semantic projection。
- GPU backend 只消费脱水 DisplayList / RenderPacket，而不是直接消费 State Tree 或 Widget Tree。

推荐未来形态：

```text
Owner State / Facts
  -> Semantic Scene Snapshot
  -> Render Node / Component Facts
  -> DisplayList / RenderCommandList
  -> Backend Packet
  -> Metal / Direct2D / Skia / platform GPU
```

P1 不做：

- 不实现 Entity allocator。
- 不实现 archetype storage。
- 不实现 query scheduler。
- 不做 render diff / cache / batching。
- 不接 Metal backend。

未来触发条件：

- 已进入 Scene / Renderer input preflight。
- 已定义 stable node id / bounds / clip / z-order / material key。
- 出现真实 renderer backend 或 display list 性能问题。

## CRDT / Collaboration 雷达

CRDT 的价值在于给未来人类与 AI 同时操作同一 GUI state 提供数学一致性的方向，但它的实现复杂度很高，不应在 P1 提前引爆。

P1 的工程翻译：

- 所有 state / queue / action movement 保留 owner、version、candidate、blocked reason。
- 冲突先 fail-closed 或进入 explicit negotiation facts。
- 不把多个 writer 直接写入同一 mutable truth。
- 不做 optimistic multi-writer merge。

未来触发条件：

- 明确出现人类与 AI 同时编辑同一 owner truth 的需求。
- 已有 stable operation log / causality / rollback facts。
- 已有 semantic projection 能区分冲突类型。
- 单 owner / Action Router / Queue / Store 的失败与审计链路足够稳定。

## Scene / DisplayList 路线

P1 未来进入 Scene / Renderer input 时，应采用双层模型：

- Scene Tree / Semantic Scene：保留层级、语义、hit-test、accessibility、AI projection。
- DisplayList / RenderCommandList：脱水、扁平、按 z-order / material / clip 等信息组织，供 backend 翻译。

初期策略：

- P1 先全量生成 DisplayList，保证确定性、可回放、可审计。
- 结构字段从第一天为增量更新预留扩展位。
- 不在 P1 实现 Dirty Region / Repaint Boundary / DisplayList patch。

建议预留字段：

- `RenderNodeId`
- `SceneVersion`
- `DisplayListVersion`
- `Bounds`
- `Clip`
- `ZIndex`
- `MaterialKey`
- `InvalidationReason`
- `RepaintBoundaryHint`

阶段路线：

```text
P1: State -> SceneSnapshot -> full DisplayList rebuild contract
P2: stable node id / bounds / material key / repaint boundary hint
P3: DisplayList diff / patch / cache / atlas / batching
P4: backend-specific optimization for Metal / Direct2D / Skia / Vulkan
```

## P1 禁止事项

除非后续有明确 decision，否则 P1 不得因为本 radar：

- 引入 `stdx.effect`。
- 打开 `--enable-eh` / `--experimental`。
- 修改 `runtime/cjgui/cjpm.toml`。
- 实现 ECS storage / query scheduler。
- 实现 CRDT merge engine。
- 接入 Scene / Renderer / Widget / Layout / Text / IME / Accessibility。
- 接入 AppKit / Metal / Objective-C 新 bridge。
- 真实执行 action side effect。
- 写 process-wide runtime / queue global mutable state。
- 新增 public API / C ABI。

## 什么时候读取本文件

本文件不是每轮 implementation 必读项。只在以下场景按需读取：

- 准备进入 Scene / Renderer input preflight。
- 准备设计 semantic projection / AI-readable UI snapshot。
- 准备靠近真实 action side effect executor。
- 准备评估仓颉 Effect Handler 是否可作为稳定能力。
- 准备引入多人 / 人机并发协作模型。
- 准备选择 DisplayList full rebuild、dirty region、或 render diff 策略。

## 当前 next opening 不变

本文件仅记录未来规划，不改变当前 active / next opening。当前 runtime 主线仍以 `GUI_TASK_TRACKER.md` 为准。
