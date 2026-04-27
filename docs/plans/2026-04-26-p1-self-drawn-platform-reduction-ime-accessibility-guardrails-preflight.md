# P1 Self-drawn Platform Reduction / IME / Accessibility Guardrails Preflight

日期：2026-04-26

性质：docs-only / architecture guardrails / future debt intake / no implementation

状态：完成；不批准直接实现

范围：接收“自绘降维”和“IME 隔离”相关讨论，判断哪些结论可以进入当前 runtime 线的硬纪律，哪些只能登记为 future opening。本轮不写 runtime 代码，不修改 `labs/macos_bridge_smoke`，不改变当前 next opening。

## 1. 背景

本轮依据：

- [P1 red-team risk intake / runtime guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 minimal app/window lifecycle runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI-native UI semantics](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)

本轮输入的核心想法：

- 自绘路线可以把平台原生控件、平台窗口管理器细微信号和控件行为差异，尽量降维为框架内部的 geometry、layout、render 和 invalidation 问题。
- IME 可以考虑通过隔离区把复杂 composition 过程挡在框架文本状态之外，只把最终 committed text 提交给框架。
- 这些策略会带来新的责任：过度重绘、电池消耗、手感不原生、IME candidate window 坐标错位、自绘无障碍黑盒。

本轮目标不是判断这些方案最终是否可实现，而是把它们转成当前 P1 runtime 线必须记住的护栏。

## 2. 总体判断

这组意见合理，应该落文档，但不能照单全收为当前实现策略。

可以接受的部分：

- 自绘路线确实能减少对平台原生控件系统的依赖。
- 平台窗口事件可以被尽量脱水成 geometry、scale、visibility、focus、lifecycle 等事实。
- 文本 / IME / 无障碍必须作为后期硬仗，不能在 app/window lifecycle 或 skeleton 阶段顺手打开。
- 过度渲染和语义树热路径都是未来性能地雷，必须提前登记。

必须降温的部分：

- 自绘不是消灭平台复杂性。窗口管理器、DPI、resize、display scale、compositor、截图权限、IME、无障碍和系统输入仍然真实存在。
- “IME 只提交最终字符串”最多是早期隔离策略候选，不能被写成长期完整文本系统真相。真实输入框未来仍要面对 preedit、candidate position、cursor rect、composition cancel / commit 和 selection。
- “游戏引擎式 global tick”不能默认进入 GUI runtime。GUI 默认应按需重绘，动画或连续输入才可以显式请求 frame。

## 3. 自绘降维的可采纳边界

当前项目继续选择自绘 / GPU 路线，而不是原生控件薄绑定路线。

这意味着：

- OS 原生控件不定义框架公共 widget 行为。
- 平台 bridge / adapter 可以处理平台脏活，core 只接收脱水事实。
- window manager 的 resize / scale / expose / visibility 等信号，未来应尽量被转成框架自己的 lifecycle / geometry / invalidation 输入。

但这不意味着：

- core 可以忽略平台 lifecycle。
- runtime 可以假设所有平台都有相同 event loop / frame scheduling。
- 框架可以不做 IME / 无障碍，只因为它是自绘。
- `labs/macos_bridge_smoke` 中的 AppKit / Metal 行为可以直接升格为正式 runtime truth。

当前 hard rule：

> 自绘降低的是公共 API 对平台控件系统的耦合，不是免除平台 adapter 对真实系统边界的责任。

## 4. Over-rendering / Battery Guardrail

风险：如果 future runtime 引入默认全局 tick，并在无变化时也以 `60fps` / `120fps` 重绘整个窗口，自绘路线会变成电池杀手。

当前结论：

- 默认不允许 global tick 驱动全窗口重绘。
- 默认模型应是 event-driven / invalidation-driven。
- 重绘需要由明确事实触发：窗口 resize / expose、state change、input event、animation request、timer request、platform restore、surface invalidation。
- animation 可以在未来拥有 frame scheduling，但必须另开 preflight，不得偷偷变成 runtime 默认循环。
- Dirty rect / invalidation owner 是 future slot，不在当前 skeleton / lifecycle slice 实现。

当前 hard rule：

> 任何 runtime / render execution card 若引入 `tick`、`frame loop`、`requestAnimationFrame` 或等价机制，必须同时说明 idle 时如何不重绘，以及 invalidation / dirty region 的 owner。

## 5. Native Feel / Rendering Backend Guardrail

风险：自绘 UI 的滚动惯性、文本渲染、字体 hinting、subpixel / antialiasing、selection 和 focus feedback 很容易和原生手感出现细微偏差。

当前结论：

- 第一阶段可以接受手感不完美。
- 不允许把滚动物理、文字渲染策略、输入反馈写死在控件内部。
- 滚动物理模型、text shaping / raster backend、focus / selection visual policy 都应保留为未来可替换模块。
- 现在不做 ScrollView、Text、Input、IME 或 Accessibility。

当前 hard rule：

> 未来控件不应直接拥有平台手感常量；滚动物理和文本渲染后端必须有独立 owner。

## 6. IME Isolation Guardrail

风险：如果未来把 IME 完全隔离在外部输入区，只在 commit 时提交最终字符串，早期可以降低复杂度，但 candidate window / composition UI 可能在滚动、resize、DPI 切换或光标移动时出现视觉错位。

当前结论：

- P1 不做 Input / IME。
- IME 隔离可以登记为 future candidate，但不能成为长期完整方案。
- 未来 IME preflight 必须回答：
  - committed text owner 是谁。
  - preedit / composition state 是否进入框架文本模型。
  - candidate window 的 cursor rect / screen coordinate 如何同步。
  - scroll / layout / scale 变化时如何更新 IME anchor。
  - cancel / commit / reconversion / selection 如何表达。
- 当前只预留 `IME cursor rect sync channel` 这个未来设计位，不实现。

当前 hard rule：

> 不能把“只提交最终字符串”写成完整输入系统 contract；它只是 early isolation candidate。

## 7. Accessibility / Semantic Guardrail

风险：自绘窗口对屏幕朗读器和系统无障碍 API 来说可能只是一张不可读图像。若不提前保留 semantic projection 位置，未来会被迫在控件层打补丁。

当前结论：

- P1 不做无障碍。
- 当前不实现 semantic tree / Action Router。
- 未来无障碍应尽量复用 UI truth 的 semantic projection，不为 AI 和 accessibility 造两套真相。
- semantic projection 必须 lazy / on-demand，不能进入 render hot path。
- render dirty 和 semantic dirty 未来必须分离。

当前 hard rule：

> 无障碍现在不实现，但自绘路线不能把无障碍需求视为不存在；semantic bridge 是 future slot。

## 8. 对当前 Next Opening 的影响

当前 next opening 保持：

> `P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight`

本轮不改变主线，不要求回滚 runtime skeleton，也不要求立即开 Dirty Rect、IME、Accessibility 或 Renderer。

但下一篇 runtime surface review preflight 必须吸收本轮 guardrails：

- runtime skeleton 不能诱导默认 global tick。
- app/window lifecycle surface 不能把 frame loop 作为默认事实。
- platform adapter 可以接收平台 expose / resize / visibility，但 core 只接收脱水 facts。
- window / app lifecycle surface 不得暗中打开 Text / Input / IME / Accessibility。
- 若未来讨论 redraw / render scheduling，必须先开 `redraw invalidation / dirty rect policy preflight`。

## 9. Future Openings

本轮登记以下 future openings，但不自动开启：

### `P1 redraw invalidation / dirty rect policy preflight`

用途：

- 冻结 invalidation owner、dirty region、idle behavior、animation frame request、resize / expose / state change 如何触发 redraw。
- 明确是否允许 global tick，以及何时必须禁止全窗口盲重绘。

### `P1 scroll physics and text rendering backend boundary preflight`

用途：

- 冻结滚动物理模型、文本 shaping / raster backend、字体 fallback、focus / selection visual policy 的 owner。
- 避免未来控件直接写死平台手感和文本渲染细节。

### `P1 IME composition isolation / cursor rect sync preflight`

用途：

- 评估 IME 隔离策略是否可行。
- 明确 committed text、preedit state、candidate positioning、cursor rect、screen coordinate sync 和 scroll / layout 更新关系。

### `P1 accessibility semantic bridge preflight`

用途：

- 冻结自绘 UI 如何在未来接回 OS accessibility。
- 明确 semantic projection 与 AI semantic tree 的关系、lazy / dirty 策略和 owner。

## 10. 本轮 Stop-line

本轮强制保持：

- 不写 runtime 代码。
- 不修改 runtime skeleton。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 harness。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不实现 Dirty Rect / invalidation system。
- 不实现 global tick / frame scheduler。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 ScrollView / Text / Input / IME。
- 不实现 Accessibility / semantic tree / Action Router。
- 不做 command-list hash、pixel diff、baseline 或 offscreen renderer。

## 11. 结论

这组“降维打击”意见应被接收为 runtime 线的未来护栏，而不是当前实现任务。

最重要的即时结论是：

- 自绘可以降维平台控件差异，但不能否认平台边界。
- 默认不允许 global tick / blind redraw。
- IME 隔离只能作为 future candidate，不能成为完整文本 contract。
- 无障碍现在不开，但必须长期保留 semantic bridge 位置。
- 当前 next opening 不变，仍应走 docs-only skeleton closure / app-window lifecycle surface review。
