# P1 Automated GUI Verification Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization
状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行
范围：只授权未来第一刀封装现有自动关闭日志断言为可复用 verification harness。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 确认依据：
  - [2026-04-25-p1-automated-gui-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 只能使用已有 shell / smoke 构建能力，不引入重型 GUI 测试框架。
- 上层尽量仓颉原生：是。不得新增正式 public runtime API，也不得把 verification harness 写成框架能力。
- 底层只保留必要平台桥接：是。本卡不授权修改 Objective-C bridge；bridge 仍只是被验证对象。
- 没有过早抽象跨平台：是。本卡只覆盖 `labs/macos_bridge_smoke` 的 macOS 单平台 smoke。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现日志 harness 不足以证明目标，必须暂停并另开或扩展 execution card，不能顺手实现截图、pixel diff、Metal readback 或 offscreen renderer。

## 1. Authority

本轮唯一 authority：

- [2026-04-25-p1-automated-gui-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-preflight.md)

其他治理文档只作为背景约束，不能把本卡授权范围扩展成：

- 自动截图系统
- window screenshot
- Metal drawable readback
- frame hash
- pixel diff
- offscreen renderer
- Renderer / Scene
- Widget / Layout / DSL
- 跨平台 verification abstraction
- 正式 GUI runtime 测试框架

## 2. Goal

本卡授权的未来唯一目标：

- 创建 `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 或等价极窄脚本，把现有自动关闭日志断言封装成可复用 verification harness。

第一刀只验证现有日志证据，不验证像素结果。

未来 harness 必须至少断言：

- `SDKROOT`
- `bridge init`
- `Metal capability check`
- `window created`
- `metal setup complete`
- `first frame rendered`
- `post close request`
- `main-thread drain`
- `close requested`
- `destroy complete`
- `event loop exited`
- `Cangjie: cjgui_app_run returned 0`

建议对应的日志 needle 包括：

- `cjgui: using SDKROOT=`
- `cjgui: bridge init`
- `cjgui: capability check: metal device ok`
- `cjgui: capability check: command queue ok`
- `cjgui: window created`
- `cjgui: metal setup complete`
- `cjgui: first frame rendered`
- `cjgui: post close request`
- `cjgui: main-thread drain`
- `cjgui: close requested`
- `cjgui: destroy complete`
- `cjgui: event loop exited`
- `Cangjie: cjgui_app_run returned 0`

成功标准：

- harness 可以从零运行现有 auto-close smoke。
- harness 能收集日志并检查 expected needles。
- harness 在缺失日志时输出清晰失败信息，例如 `missing expected log: <needle>`。
- harness 的成功结果只能表示 lifecycle / capability / first-frame-submitted 日志证据成立。
- harness 不得声称完成像素级验证。

## 3. Scope

本卡允许的未来实现范围：

- 只增加一个极窄 verification harness。
- 默认通过现有 `labs/macos_bridge_smoke/scripts/build_and_run.sh` 执行 smoke。
- 默认设置 `CJGUI_AUTOCLOSE_SECONDS=1` 或等价自动关闭方式。
- 默认把运行日志写入临时文件，便于失败排查。
- 只检查现有日志，不改变被测 bridge 行为。
- 只在 `labs/macos_bridge_smoke/README.md` 记录 smoke 验证命令和日志语义。

本卡明确不做：

- 不实现自动截图。
- 不实现 window screenshot。
- 不实现 Metal drawable readback。
- 不实现 frame hash。
- 不实现 pixel diff。
- 不实现 offscreen renderer。
- 不新增 frame metadata / render stats 代码。
- 不修改 Objective-C bridge；如确需修改，必须另开 execution card。
- 不引入重型 GUI 测试框架。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 runtime。

可选规划但本卡不授权实现：

- frame metadata。
- render stats。
- screenshot degraded result。
- future Metal readback exploratory slice。

这些只能写在文档计划里，不得在 first slice 中落代码。

## 4. Write Set

本卡授权的未来 implementation 允许修改：

- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- [macos_bridge_smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- future closure review 文档
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

本卡授权的未来 implementation 禁止触碰：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- 正式 runtime 目录
- public GUI API
- Renderer / Scene / Widget / Layout / DSL
- 跨平台 backend
- 文本、输入法、无障碍相关实现
- AI semantic tree / Action Router 相关实现
- `reference_repos/`
- `sources/`
- `/Users/jiangxuanyang/cangjie-toolchains/cangjie`

如果未来实现发现必须修改 Objective-C bridge，说明当前目标已经越过本卡授权，应停止并另开 execution card。

本轮创建 execution card 时允许修改：

- 本 execution card
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)，仅用于入口链接

本轮创建 execution card 时禁止修改：

- `labs/macos_bridge_smoke`
- 任何运行时代码
- 任何 verification harness 脚本

## 5. Truth / Projection

未来 first slice 的真相层：

- smoke 进程实际退出码。
- harness 捕获到的原始日志。
- expected needles 是否全部存在。
- `cjgui_app_run()` 是否返回 `0`。

本轮只是投影 / read surface 的部分：

- harness 的终端摘要。
- README 中记录的验证说明。
- closure review 中引用的验证结果。

重要边界：

- 日志存在只能证明执行路径和首帧提交日志存在。
- 日志存在不能证明屏幕像素正确。
- 日志存在不能证明窗口没有被遮挡。
- 日志存在不能证明 Metal drawable 最终像素非空。
- 日志 harness 不能成为 Renderer / Scene truth。

## 6. Invariants

未来实现必须守住：

- harness 只验证现有日志证据。
- harness 不得声称完成像素级验证。
- harness 不得修改被测 bridge 行为。
- harness 不得新增正式 public runtime API。
- harness 不得暴露或依赖 `NSWindow*`、`NSView*`、`NSEvent*`、`CAMetalLayer*`、Metal 对象或 Objective-C `id`。
- harness 不得绕过现有 `RequestClose` lifecycle queue。
- 自动关闭路径仍必须经由 `post close request -> main-thread drain -> close requested -> destroy complete -> event loop exited`。
- 失败输出必须清楚指出缺失哪条日志或哪个命令失败。
- 成功输出必须避免把日志验证写成视觉验证、像素验证或正式 GUI runtime 验证。

## 7. Verification Evidence Contract

未来 implementation 的 closure review 可以接受的证据：

- 执行的 harness 命令。
- harness 捕获的日志路径。
- expected needles 全部通过的摘要。
- smoke 退出码。
- `Cangjie: cjgui_app_run returned 0`。
- 明确声明“本验证不是像素级验证”。

未来 implementation 的 closure review 不能接受的错误解释：

- 把日志断言通过写成 pixel diff 通过。
- 把 `first frame rendered` 写成屏幕像素正确。
- 把 auto-close harness 写成完整 GUI 自动化测试框架。
- 把 smoke demo 写成正式 runtime。

本卡明确无法验证：

- 真实多线程压力。
- handle generation。
- 多窗口。
- target update。
- 真实屏幕截图。
- window screenshot。
- Metal readback。
- frame hash。
- pixel diff。
- offscreen render。
- 自动视觉验证。
- 窗口是否被遮挡、最小化或位于不可见桌面空间。

## 8. Fallout Scan Targets

未来实现完成前必须检查：

- 公共 API：不得新增 public runtime API。
- 事件流：不得改变 close / drain 生命周期语义。
- 状态流：不得新增第二 lifecycle truth。
- 渲染流：不得新增 Renderer / Scene / redraw queue。
- 平台桥接：不得修改 Objective-C bridge，除非另开 execution card。
- 视觉 / 交互：必须说明没有像素级证据。
- 文档 / 示例：README 只能记录 smoke 行为和日志验证。
- 测试：harness 只封装当前日志断言，不引入重型测试框架。

## 9. Stop-Line

本轮创建 execution card 的 stop-line：

- 不实现 verification harness。
- 不修改 `labs/macos_bridge_smoke`。
- 不实现自动截图。
- 不实现 pixel diff。
- 不实现 Metal readback。
- 不实现 offscreen renderer。
- 不设计正式 Renderer / Scene。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象、文本、输入法、无障碍、AI semantic tree / Action Router。
- 不引入重型 GUI 测试框架。

未来 implementation first slice 的 stop-line：

- 只创建 `verify_auto_close.sh` 或等价极窄脚本。
- 只验证现有日志证据。
- 不修改 Objective-C bridge。
- 不新增 frame metadata / render stats 代码。
- 不做截图、readback、hash、diff 或 offscreen。
- 不把 harness 变成正式 runtime API。
- 不把 bounded harness 写成无限授权。

## 10. Closure Requirements

未来 implementation 完成后必须创建 closure review。

closure review 至少记录：

- landed code reality。
- 实际 write set。
- harness 命令。
- 日志断言结果。
- 未覆盖风险。
- stop-line 是否守住。
- 明确说明没有像素级验证。

建议 closure review 路径：

- `docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md`

## 11. Next Opening

本卡创建后，不自动执行实现。

如果用户明确继续推进，下一条 bounded implementation opening 是：

- `P1 automated GUI verification bounded implementation first slice`

该 opening 只能按本卡执行：

- 创建 `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 或等价极窄脚本。
- 更新 `labs/macos_bridge_smoke/README.md`。
- 创建 future closure review。
- 更新 `docs/plans/README.md` 和 `GUI_TASK_TRACKER.md`。

除非另开 execution card，否则不得进入截图、pixel diff、Metal readback、offscreen renderer、Renderer / Scene 或正式 runtime 设计。
