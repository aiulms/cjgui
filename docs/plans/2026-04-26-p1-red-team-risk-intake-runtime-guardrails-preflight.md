# P1 Red-team Risk Intake / Runtime Guardrails Preflight

日期：2026-04-26

性质：docs-only / red-team risk intake / runtime guardrails / no implementation

状态：完成；不批准直接实现

范围：接收第三方红队视角提出的结构性盲点，并判断哪些风险应立即进入当前 runtime pivot 护栏，哪些应登记为 future opening。本轮不写 runtime 代码，不修改 `labs/macos_bridge_smoke`，不创建 runtime 目录，不改变当前 next opening。

## 1. 背景

本轮依据：

- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 minimal app / window lifecycle runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)
- [P1 frame hash verification evidence line closure / runtime pivot preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI-native UI semantics](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)

红队提出四类结构性风险：

- 治理反噬：文档与规范数量增长导致 AI 上下文过载、逻辑冲突和治理死锁。
- 像素哈希陷阱：严格 frame hash / pixel diff 在 GPU、字体、颜色空间和硬件差异下可能成为 CI 噪声源。
- 平台过拟合：macOS AppKit runloop / dispatch / event callback 语义可能污染未来 core runtime。
- 语义树性能：AI semantic tree 若热路径维护，可能产生 CPU、内存和 GC 压力，并成为第二真相源风险。

本轮目标不是打开新实现线，而是把这些风险转成当前可执行的架构护栏。

## 2. 总体判断

红队意见整体有效，但不能照单全收。

本项目当前已经对部分风险有防线：

- frame hash 线已经明确 `hash_value_persistence_allowed=false`、`baseline_allowed=false`、`pixel_diff_allowed=false`。
- AI semantic tree 已被长期方向文档限制为投影，不能成为第二真相源。
- smoke-to-runtime boundary 已禁止直接迁移 smoke C ABI、目录结构和 harness。

但红队意见指出了三件必须补强的事：

- 文档治理需要压缩机制，否则治理本身会成为负担。
- 下一张 runtime execution card 必须防止 AppKit runloop 语义进入 core truth。
- 未来 render evidence 和 semantic projection 要提前登记方向，避免后续在 Renderer / Scene 深水区仓促补救。

## 3. 风险 1：治理反噬

结论：接受；这是最近的真实风险。

当前表现：

- P1 文档数量已经很高。
- 执行 AI 每轮需要读取大量 preflight / execution card / closure review。
- 历史文档之间未来可能出现隐性冲突。
- 文档越多，越容易让执行 AI 过度防御、遗漏前置约束或误读旧结论。

当前处置：

- 不把每份历史文档永久升级为每轮必读。
- 当前 next execution card 仍以 tracker、当前 preflight / execution card、risk ledger 和必要 closure 为主。
- 本轮登记 future opening：

> `P1 governance compaction / truth manifest preflight`

该 future opening 应回答：

- 哪些历史决策被压缩为当前 truth。
- 哪些 closure 只保留为审计记录。
- 当前最小必读文档集是什么。
- 是否需要创建 `CJGUI_TRUTH_MANIFEST.md` 或等价 manifest。
- manifest 和原始计划文档谁是真相源。
- manifest 如何更新、谁能更新、何时必须重新压缩。

约束：

- governance compaction 不应成为新重流程。
- manifest 只能压缩已有决策，不能发明新架构能力。
- manifest 不能取代当前 execution card 的局部 authority。

## 4. 风险 2：像素哈希陷阱

结论：接受风险判断；不改变当前 runtime opening。

当前防线已经存在：

```text
hash_value_persistence_allowed=false
baseline_allowed=false
pixel_diff_allowed=false
source_normalized=false
```

这意味着当前项目没有把截图 hash、pixel diff 或 baseline 当成正式 regression truth。

红队建议的 `Display List / Command List Hash` 方向有价值，但当前不能立即打开，因为它会提前引出：

- Renderer / Scene。
- Display list / render command ownership。
- render truth 和 state truth 的边界。
- command serialization / normalization。
- future test framework。

当前处置：

- pixel screenshot / frame hash 继续只作为 smoke guard 和 feasibility evidence。
- 不继续深挖 pixel diff / baseline。
- 在 future opening 中登记：

> `P1 render evidence model / command list hash preflight`

该 future opening 应出现在 Renderer / render pipeline preflight 之前或之中，回答：

- render command list 是否比 pixel hash 更适合作为业务回归 evidence。
- command list owner 是谁。
- command list 是否属于 truth、projection 还是 diagnostics。
- command list hash 是否允许保存。
- pixel evidence 和 command evidence 如何分层。

约束：

- 当前不定义 Display List / Command Buffer API。
- 当前不实现 command hash。
- 当前不重开 pixel diff / baseline。

## 5. 风险 3：macOS 运行循环过拟合

结论：接受；这是下一张 runtime execution card 必须立即吸收的风险。

当前危险点：

- smoke 运行在 AppKit event loop 之上。
- main-thread queue / drain 已验证的是 macOS 单实例路径。
- 如果 future core runtime 直接采用 AppKit callback / `NSRunLoop` / `dispatch_get_main_queue` 作为核心真相，未来 Windows / Wayland / 其他平台会被 macOS 语义污染。

当前处置：

下一张 `P1 minimal app/window lifecycle runtime execution card` 必须明确：

- AppKit event loop 只能属于 macOS platform adapter / bridge。
- core runtime 不得把 `NSRunLoop`、`NSEvent`、`dispatch_main`、Objective-C callback 语义当成公共 truth。
- core 层未来只应看到脱水 lifecycle / input / frame step / queue drain 等抽象事实。
- `tick` / `step` / input buffer 可以作为 future candidate，但本轮不承诺游戏引擎式 API。
- 平台 adapter 可以驱动 core，core 不能反向持有平台 runloop owner。

约束：

- 不因为防过拟合而提前做跨平台抽象。
- 不在 app/window lifecycle first slice 中设计完整 event model。
- 不引入 Renderer / Scene / Widget。

## 6. 风险 4：AI Semantic Tree 性能

结论：接受方向判断；登记 future invariant，不进入当前 runtime first slice。

当前已有原则：

- semantic tree 只能是 UI state truth 的投影。
- semantic tree 不能成为第二真相源。
- Action Router 不在当前 opening 内实现。

红队补充的性能护栏合理：

- semantic projection 应默认 cold / lazy / on-demand。
- render hot path 不应每帧维护完整 semantic tree。
- semantic dirty 与 render dirty 应分离。
- 动画、进度条、纯视觉变化不应默认触发语义重建。
- 文本、结构、role、action、可操作状态变化才可能触发 semantic dirty。

当前处置：

- 不打开 AI semantic tree / Action Router 实现。
- 在 future `AI semantic tree preflight` 或 `Element / Scene preflight` 中必须回答 lazy / dirty-driven 策略。
- 当前 runtime execution card 只需保持“不引入 semantic tree，不引入 action router”。

## 7. 对当前 Next Opening 的影响

当前 next opening 仍保持：

> `P1 minimal app/window lifecycle runtime execution card`

但该 execution card 必须新增本轮 guardrails：

- 读取本风险 intake 文档作为前置依据。
- 明确 runtime first slice 不解决 governance compaction，但不得扩大必读历史文档集。
- 明确 runtime first slice 不进入 pixel hash / command hash / baseline / pixel diff。
- 明确 macOS platform adapter 和 core runtime 的 event loop truth 必须隔离。
- 明确不引入 semantic tree / Action Router，并登记 lazy / dirty-driven 为 future invariant。

## 8. 新增 Future Openings

本轮登记以下 future openings，但不自动开启：

### `P1 governance compaction / truth manifest preflight`

用途：

- 将已经稳定的 P0 / P1 决策压缩成当前最小 truth snapshot。
- 降低执行 AI 上下文负担。
- 防止历史文档冲突和文档腐化。

### `P1 render evidence model / command list hash preflight`

用途：

- 在进入 Renderer / render pipeline 前，判断业务回归 evidence 应优先基于 command list / display list，而不是 pixel-perfect hash。
- 保留 screenshot / pixel evidence 作为 smoke guard，而不是默认业务 regression truth。

### `P1 semantic projection lazy / dirty policy preflight`

用途：

- 在未来 Element / Scene / AI semantic tree 之前，冻结 semantic tree 的 cold path、on-demand projection、dirty marking 和 action gateway 边界。

## 9. 本轮 Stop-line

本轮强制保持：

- 不写 runtime 代码。
- 不创建 runtime 目录。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 harness。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不实现 command list / display list。
- 不做 pixel diff / baseline / offscreen renderer。
- 不实现 semantic tree / Action Router。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 10. 结论

红队四点均应进入长期治理视野。

短期最需要防守的是：

- 治理反噬。
- macOS runloop / AppKit event model 过拟合。

中期必须登记但不立即打开的是：

- render evidence model / command list hash。
- semantic projection lazy / dirty policy。

当前不改变 next opening。下一步仍推荐 docs-only：

> `P1 minimal app/window lifecycle runtime execution card`

该 execution card 必须吸收本轮 guardrails，但不自动进入 runtime implementation。
