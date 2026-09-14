# CJGUI UI 框架完整性验收尺

最后更新：2026-05-20

状态：core direction / completeness criteria / non-blocking compass

## 1. 为什么有这份文档

CJGUI 不能只在 Renderer、owner、probe、result envelope 里自洽。Renderer 是地基，但最终验收不是“我们有多少 internal owner”，而是：

- 开发者能不能用仓颉写出真实应用。
- 用户能不能看到、点击、输入、滚动、切换状态。
- AI 能不能基于结构化语义生成、修改、解释 UI，而不是只能截图识屏。

本文是方向尺，不是新闸门。它不阻塞当前 Renderer 主线，也不批准越过 stop-line；它只提醒后续执行者：每个阶段包都应让 CJGUI 更接近“完整 UI 框架”，而不是只堆安全包装。

## 2. 完整不是一口吃成 Qt 或 Flutter

CJGUI 的完整性分三层推进：

1. 最小可用 UI framework：app / window lifecycle、runtime state、event / action、layout / scene / render command、基础组件、输入、状态更新和第一条 renderer backend。
2. 好用的传统 GUI 能力：组件集、布局、主题 / 样式、资源管理、focus / keyboard / IME / scroll、动画、无障碍、调试、预览、打包。
3. AI-native 能力：semantic tree、Owner-controlled Action Gateway、preview / diff / explain / rollback、generated UI、低风险自动执行、高风险 owner acceptance。

第一层没完成时，不应急着宣称 AI-native UI framework；第三层也不能替代第一层。AI 原生是加在完整 UI 地基上的一等公民能力，不是跳过传统 GUI 能力的理由。

## 3. 最小完整性清单

一个阶段如果要让 CJGUI 更接近“可用 UI 框架”，至少应能推动下面某一类能力：

- UI authoring：能用仓颉描述界面结构，而不是只调用底层渲染 probe。
- Interaction：能表达点击、键盘、鼠标、焦点、滚动等输入。
- State / update：状态变化能驱动 UI 更新，且有可审计的 write / rollback 边界。
- Visual / styling：能表达颜色、文字、间距、尺寸、边框、主题等可见样式。
- Platform bridge：窗口、图层、GPU、资源、生命周期能被极窄桥接稳定托住。
- Developer experience：有示例、错误分类、调试入口、验证脚本和清晰的失败解释。
- AI-native semantics：UI 有结构化语义，AI 的建议能通过 preview / diff / explain / accept 进入 owner-controlled path。

Renderer first frame 很重要，但它只是其中一项。只有像素链路、状态链路、输入链路和语义链路逐步合拢，CJGUI 才会从“渲染实验室”变成“UI 框架”。

## 4. Demo app 验收线

在宣称 CJGUI “最小可用”之前，至少要能用框架主体能力做出下列 demo：

- Todo list：验证列表、输入、状态更新、增删改。
- Settings panel：验证表单、开关、分组、布局、主题。
- Chat view：验证滚动、消息列表、输入框、异步状态。
- File browser / list inspector：验证树 / 列表、选择、详情面板、平台资源边界。
- AI-generated UI demo：验证 AI 生成一个简单表单或设置页，经过 preview / diff / explain / accept 后进入 UI runtime。

这些 demo 不是现在马上要做的任务，但它们是判断路线有没有偏的外部验收线。后续自动化如果长期只增加 denial / guard / envelope，而不能说明这些 demo 更近了，就应主动切回更有框架产出的主线。

## 5. Renderer 到 UI 框架的转场信号

当下面条件逐渐成立时，应开始从 Renderer-only 主线转向最小 UI framework 主线：

- renderer-state write 的非突变 dry-run、guarded executor、rollback 和 visibility publication 边界稳定。
- 最小 Scene / RenderCommand 输入形态可以被 owner-local 状态构造出来。
- 第一帧链路可重复验证，并且失败能被清楚分类。
- 不再需要每轮都重复证明同一条 native readiness 安全事实。

转场时优先落最小内部 demo surface，而不是先扩稳定 public API：例如 internal Rect / Text / Button-like semantic node、简单 layout、state update dry-run 和 focused demo probe。

## 6. 自动化如何使用本文

后续 AI 在以下场景应读取本文作为方向校准：

- 一个 Renderer 阶段包结束，准备选择下一条路线。
- 自动化连续进入 admission / envelope / guard / denial，却看不出离真实应用更近。
- 用户询问“我们是不是在自嗨”“这是不是完整 UI 框架”“AI 是否知道 UI 框架需要什么”。
- 准备从 renderer-state write 进入 Scene / component / layout / demo app 方向。

使用原则：

- 本文不覆盖当前 next opening，不替代 tracker / latest report。
- 本文不授权 public API、renderer state write、production truth 或 native bridge 扩张。
- 本文只提供“完整 UI 框架”的验收视角，避免技术链路自洽但产品形态缺位。

## 7. 当前状态快照

截至 2026-05-20，CJGUI 已经跑通并记录了大量 macOS AppKit / Metal renderer runway evidence，包含 first-frame observation、bounded native probe、renderer-state write admission / dry-run / guarded executor 等阶段。

但 CJGUI 仍未达到“最小可用 UI framework”：

- 还没有稳定的公开组件模型。
- 还没有正式 layout / style / input / focus / text editing surface。
- 还没有 demo app 级验收。
- AI-native generated UI 仍是 future radar，不是当前 runtime 能力。

下一段长期转场目标应是：在 Renderer state-write 边界足够稳之后，落最小 Scene / RenderCommand / semantic node / demo probe，让框架从“能渲染”走向“能写 UI”。
