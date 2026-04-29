# AI-Native GUI Runtime Architecture Intake

日期：2026-04-30

性质：sidecar architecture intake / future risk radar

状态：按需读取，不是每轮 implementation 的默认必读项。

## 用途

本文记录一次外部架构视角对 CJGUI 方向的有效提醒。

它不改变当前 P1 runtime next opening，不授权 public API / C ABI / event loop / queue / platform bridge / renderer / semantic tree / Action Router 实现。它只在未来触碰 AI-native GUI、semantic projection、Action Router、Hard / Soft Cycle、owner 权限、input / render fast path 或最小语义 demo 前作为排雷材料读取。

## 核心判断

CJGUI 的差异点不是“仓颉版传统 UI 框架”，而是尝试把 GUI runtime 建成一个可验证、可审计、可 fail-closed 的状态演化系统。

当前项目已经在 internal runtime 链路中推进：

- owner 边界
- 单一真相
- 脱水 facts / intents / summaries
- blocked / deferred / accepted path
- next-cycle candidate
- execution admission

这些能力仍是 internal-only draft，不是可见 GUI runtime。不要把 `run`、`loop`、`commit`、`store`、`replay`、`admission` 等命名误读成真实 event loop、queue、window、renderer 或 public surface。

## 可吸收的强思路

### 1. 从组件树到状态场

传统 UI 框架常以组件树、事件回调和局部状态为中心。AI 协作进入后，状态来源会变多：用户、程序、远程同步、AI intent 都可能尝试改变同一块 UI truth。

CJGUI 应继续把 UI 看成由 owner 管辖的状态场：

- owner 拥有 truth
- projection 只能投影事实
- action / intent 只能通过受控 route 推进
- blocked path 必须可审计

这与当前 “场与波” 文档方向一致，但不能替代具体 runtime implementation。

### 2. Hard Cycle / Soft Cycle

必须区分两类推进：

- Hard Cycle：改变 owner truth 的状态推进，必须走验证、owner、blocked / fail-closed 路径。
- Soft Cycle：hover、鼠标移动、动画、临时视觉反馈、render cache、projection refresh 等高频低危路径，未来可能需要 fast path。

风险：

- 如果所有高频交互都走完整 hard cycle，可能带来延迟和内存压力。
- 如果 soft cycle 可以偷偷改变 truth，就会破坏 owner boundary。

未来开 event loop、input、animation、renderer / invalidation、IME composition 前，应重新读取本节。

### 3. Owner 是编译期保证还是运行时契约

仓颉不是 Rust。CJGUI 不应假设语言会天然提供借用检查级别的 owner enforcement。

后续需要明确：

- 哪些 owner boundary 可由 package / visibility / type shape 守住。
- 哪些只能靠 internal API contract、constructor shape、测试和 review 守住。
- 是否需要 runtime assertion 或 capability-style handle。
- projection 是只读 view、copy、snapshot，还是受限 handle。

当前 P1 internal skeleton 可以继续用 internal-only / immutable-copy style 试探 owner 边界，但未来 public API 前必须再次审查。

### 4. Semantic Projection 与 Action Router

AI-native GUI 不应退化为截图、OCR、坐标点击或 accessibility tree 外挂。

长期方向应是：

- owner 提供局部状态 snapshot。
- semantic projection 只暴露被授权事实。
- Action Router 将 human / AI intent 转成可审计 action。
- AI intent 默认受限、可 blocked、可 shadow、可协商。

当前未实现 semantic tree、Action Router 或 AI action protocol。未来开这些边界时必须避免让 semantic projection 成为第二 truth source。

### 5. Intent 冲突与权限裁决

AI 成为原生协作者后，技术问题会变成权限问题：

- human intent 与 AI intent 冲突时，谁裁决？
- AI 能看到哪些 owner facts？
- AI action 是否需要 owner confirmation？
- fail-closed 会不会导致体验卡死？
- blocked report 是否能解释给人类或 AI？

这不是当前 runtime_state.cj 的任务，但应进入未来 Action Router / controller handle 设计。

### 6. 没有理论死结，但有生死线

当前路线没有明确的理论不可行点。单向数据流、状态机、owner 模型、event-sourcing、capability safety、游戏式 pipeline 都有成熟先例。

真正风险不是“做不出来”，而是慢性退化：

- 变成一个约束很多、生产力不明的普通 UI 框架。
- 为了性能偷偷绕过 owner，最后形成第二套状态系统。
- 为了纯粹性拒绝 fast path，真实输入 / 动画 / IME 场景卡死。
- 底层秩序长期不能长出控件库或 demo，价值无法验证。

因此后续必须长期守住三条生死线：

1. 性能与严格性的平衡
   - Hard Cycle 负责 truth-changing 状态推进。
   - Soft Cycle 负责 projection / render refresh / hover / animation 等非 truth path。
   - Fast path 只能处理高频低危投影行为，不能偷偷改变 owner truth。
   - “事后补审计”只能记录已发生的投影事实，不能把未经过 owner 的 truth change 合法化。

2. 仓颉 toolchain 现实边界
   - 仓颉 1.1.0 当前不能被假设为提供 Rust 级 owner enforcement。
   - Owner 需要 package / visibility / type shape / internal API / tests / review / GitNexus 共同守住。
   - 真实 event loop、FFI lifecycle、Cycle leak / deadlock、platform bridge 前必须确认可调试、可观察、可回放。
   - 具体语言能力判断以 [cangjie-1.1-owner-tooling-ffi-capability-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/cangjie-1.1-owner-tooling-ffi-capability-intake.md) 为准。

3. 从秩序到生产力
   - 底层 owner / action / fact 不能直接成为控件作者每天手写的负担。
   - 长期需要较友好的声明式或半声明式 surface，但它只能编译 / 展开为底层强约束路径，不能重引入状态多源和回调地狱。
   - 在底层足够稳定后，应尽早用最小控件集验证“秩序之上能否长出 UI”，而不是等底层完美。

### 7. 需要提前冻结的架构岔路

这些不是 blocker，但选错会拖慢半年：

- Owner 粒度：不应按视觉节点机械划分，也不应退化成巨型全局 store。优先按业务意图 / truth 边界划分 owner。
- Cycle 驱动：输入 / fact path 倾向 push，渲染 / projection path 倾向 pull。未来应允许混合模型，但 truth-changing path 必须可排序、可审计。
- Action Router 位置：应尽量靠近 Intent -> Action / Fact 的入口，而不是放到 Fact -> Projection 之后再补救。越早拦截，AI 越像协作者；越晚拦截，越像外挂或劫持者。
- 渲染策略：不应为了“纯仓颉”自己写完整光栅化。可以半开放地复用 Skia / WebGPU / Metal / 平台 GPU 能力，但平台对象和 render truth 不能泄漏进高层 owner。

### 8. 面向 AI 生成，而不是只面向人类手写

长期来看，CJGUI 不应只优化“人类开发者手写 UI 代码的顺手程度”。如果未来大量 UI / glue code 由 AI 生成，框架需要同时服务：

- AI 可生成
- AI 可验证
- 人类可审查
- 系统可拒绝 / 可回滚 / 可解释

这与当前 owner / state field / dehydrated intent / fact / action / fail-closed 方向一致：把隐式约定变成显式契约，把运行时魔法变成可追踪推进。

可吸收的长期方向：

- API 不只是函数调用，也应逐步具备 contract / schema / capability 语义。
- AI 不应面对无限自由代码空间，而应面对有限、类型化、可组合的 AST / action / widget schema 空间。
- Owner boundary 长期可以成为 AI permission / capability boundary。
- 状态场应提供结构化 snapshot / fact stream，而不是要求 AI 通过截图、OCR 或坐标点击理解界面。
- Action Router 应提供 preview / dry-run / blocked report，让 AI 生成循环从“猜测运行效果”变成“提交结构化意图 -> 得到结构化反馈 -> 修正”。
- 人类主要审查 owner、intent、permission、schema 和 architecture；AI 可以在受限生成空间内批量组合 UI、action 和 projection。

短期禁止误读：

- 本文不授权现在实现 `@ai_prompt`、AI agent scope、AST generator、widget generator、semantic DSL 或 public AI API。
- 不允许因为 AI-native 北极星而提前打开 semantic tree / Action Router / public DSL / code generation surface。
- 当前 P1 仍以 runtime execution boundary、owner truth、platform bridge、render/input 物理层为主线。
- 现有 typed request / report / blocked summary 只是为未来 AI generation 留接缝，不是当前已经具备 AI generation surface。

## 最小验证建议

不要等控件库完整后再验证 AI-native 假设。未来合适时，可以做一个非常小的 semantic demo：

1. Counter demo
   - 必须走 Intent -> Owner -> Fact -> Projection -> Action Router 或等价链路。
   - 验证状态推进是否可追踪、可 blocked、可 replay。

2. Fake AI agent
   - 不看屏幕、不点坐标。
   - 只能读取局部 snapshot。
   - 只能提交受限 intent / action。

3. Fail-closed stress
   - 注入非法 action、过期 snapshot、owner 冲突、blocked precondition。
   - 验证系统拒绝路径是否可解释、可审计、不破坏 truth。

4. Hard / Soft Cycle probe
   - 区分 truth-changing update 与 projection-only update。
   - 验证 soft path 不会偷偷改变 owner truth。

5. Minimal productivity probe
   - 做最小 Button / Text / Dialog 或等价控件集。
   - 验证控件作者是否需要手写过多 owner / intent / action boilerplate。
   - 验证上层易用性没有绕过底层 owner / Action Router。

6. AI generation contract probe
   - 人类只定义 owner / intent / permission / schema。
   - 伪 AI 只能在结构化 action / widget schema 空间生成。
   - 系统必须能 preview、reject、diff 和解释生成结果。

## 当前不做

本文不授权：

- semantic tree 实现
- Action Router 实现
- AI agent runtime
- public AI API
- AI code generator
- AST / widget generator
- `@ai_prompt` 或等价 prompt schema
- public semantic DSL
- event loop / scheduler
- queue / drain
- renderer / layout
- Text / IME / Accessibility
- platform callback
- global mutable runtime state
- public runtime API / public C ABI

## 何时读取

只在以下开口前按需读取：

- semantic projection / semantic tree
- Action Router / AI action protocol
- controller handle / capability handle
- local state snapshot
- Hard Cycle / Soft Cycle 分层
- input / hover / drag / animation fast path
- renderer dirty / semantic dirty 分离
- public API 前的 owner / permission 审查
- 最小 AI-native semantic demo
- owner 粒度 / cycle driver / Action Router 位置裁决
- 最小控件集或声明式 surface 设计
- 渲染后端选择或半开放 rendering strategy
- AI generation contract / schema / bounded generation surface

普通 P1 runtime internal implementation 不默认读取本文。
