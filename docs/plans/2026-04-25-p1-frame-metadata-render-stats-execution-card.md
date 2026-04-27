# P1 Frame Metadata / Render Stats Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization
状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行
范围：只授权未来一个极窄 first slice，在 `labs/macos_bridge_smoke` 内输出脱水 frame metadata / render stats 日志，并让 `verify_auto_close.sh` 增加对应日志 needle。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 确认依据：
  - [2026-04-25-p1-frame-metadata-render-stats-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 仍只允许复用当前 smoke、shell harness 和 macOS bridge 内部日志。
- 上层尽量仓颉原生：是。不得新增正式 public runtime API，也不得让仓颉层持有平台对象。
- 底层只保留必要平台桥接：是。未来只允许在 smoke bridge 内输出脱水 diagnostics，不扩大桥接向上接口。
- 没有过早抽象跨平台：是。本卡只覆盖 macOS smoke，不定义跨平台 metadata contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现必须读取像素、修改公共 API、设计 Renderer / Scene、引入 JSON 协议或扩大 write set，必须暂停并另开 execution card。

## 1. Authority

本轮唯一 authority：

- [2026-04-25-p1-frame-metadata-render-stats-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-preflight.md)

背景约束：

- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡授权范围扩展成：

- 自动截图。
- window screenshot。
- Metal drawable readback。
- raw pixel readback。
- frame hash。
- pixel diff。
- offscreen renderer。
- Renderer / Scene。
- Widget / Layout / DSL。
- 跨平台 diagnostics abstraction。
- 正式 GUI runtime 测试框架。

## 2. Goal

本卡授权的未来唯一目标：

- 在 `labs/macos_bridge_smoke` 内完成一个极窄 frame metadata / render stats first slice，让当前 auto-close harness 可以复核更细的 first-frame 诊断日志。

第一刀只允许：

- smoke bridge 输出脱水 frame metadata / render stats 日志。
- `verify_auto_close.sh` 增加这些日志的 needle。
- smoke README 记录字段语义和非像素级边界。
- closure review 记录验证命令、日志路径和 stop-line。

第一刀不允许：

- 读取真实像素。
- 产出 screenshot artifact。
- 做 Metal readback。
- 做 frame hash。
- 做 pixel diff。
- 做 offscreen renderer。
- 设计正式 Renderer / Scene / Widget / Layout / DSL。
- 把 metadata 当成像素正确证明。

成功标准：

- `verify_auto_close.sh` 仍可运行并返回 `0`。
- 原有 auto-close 日志 needle 继续通过。
- 新增 metadata / stats 日志 needle 能被 harness 检查。
- 日志字段只包含脱水数据。
- closure review 明确说明这不是像素级验证。

## 3. Allowed Fields

未来 first slice 只允许输出以下字段。

允许字段：

- `frame_index`
  - 当前 smoke 进程内的 frame index，可从 `1` 开始。
- `drawable_width`
  - 当前 bridge 观测到的 drawable width。
- `drawable_height`
  - 当前 bridge 观测到的 drawable height。
- `scale_factor`
  - 当前窗口 / view 观测到的 scale factor。
- `pixel_format`
  - 脱水 pixel format 名称或数值，不携带 Metal 对象。
- `clear_color`
  - clear color metadata，只代表 intended clear color。
- `first_frame_submitted`
  - first frame 是否提交到当前渲染路径。
- `first_frame_committed`
  - first frame 是否到达当前 bridge 能诚实判断的 committed 语义；如果无法证明，必须输出 `unknown`、`not_available` 或 degraded reason，不能伪称。
- `render_attempt_count`
  - 当前 smoke 进程内 render attempt count。
- `render_success`
  - 当前 render attempt 是否在 bridge 观测范围内成功。
- `degraded_reason`
  - `none` 或明确降级原因，例如 `no_metal_device`、`no_command_queue`、`no_drawable`、`command_buffer_unavailable`。

字段要求：

- 字段必须是数字、布尔、短字符串或枚举。
- 字段必须能被日志 needle 或简单文本检查复核。
- 字段不得携带平台对象。
- 字段不得定义 public runtime ABI。
- 字段不得表达 Renderer / Scene / Widget / Layout 语义。

## 4. Forbidden Fields

未来 first slice 禁止输出：

- raw pixels。
- screenshot artifact。
- window screenshot artifact。
- Metal texture bytes。
- frame hash。
- pixel diff result。
- renderer scene id。
- render command id。
- widget information。
- layout information。
- accessibility information。
- input state。
- 任何 AppKit 平台对象。
- 任何 Metal 平台对象。
- 任何 Objective-C 平台对象。

明确禁止携带的对象包括：

- `NSWindow*`
- `NSView*`
- `NSEvent*`
- `CAMetalLayer*`
- `CAMetalDrawable*`
- `id<MTLTexture>`
- `id<MTLCommandBuffer>`
- `id<MTLDevice>`
- `id<MTLCommandQueue>`
- Objective-C `id`
- 任何平台对象裸指针或可长期保存的 native handle

## 5. Scope

本卡允许的未来实现范围：

- 只在 smoke bridge 内输出一条或少量脱水 diagnostics 日志。
- 只让 `verify_auto_close.sh` 增加对应日志 needle。
- 只更新 smoke README 说明字段和非像素级边界。
- 只创建 future closure review 并更新计划索引 / 任务账本。

建议未来日志形态：

```text
cjgui: frame metadata: index=1 drawable=800x600 scale=2.00 pixel_format=BGRA8Unorm clear_color=0.00,0.50,0.55,1.00 submitted=true committed=true attempts=1 success=true degraded=none
```

该示例只定义允许的脱水方向，不批准 JSON 协议、C ABI、public API 或 Renderer / Scene contract。

本卡明确不做：

- 不读取像素。
- 不做截图。
- 不做 Metal readback。
- 不做 frame hash / pixel diff。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 metadata 写成像素正确证明。

## 6. Write Set

本卡授权的未来 implementation 允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
  - 仅允许输出脱水 frame metadata / render stats 日志。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - 仅允许增加 metadata / stats 日志 needle。
- `labs/macos_bridge_smoke/README.md`
  - 仅允许记录 smoke diagnostics 字段、验证命令和非像素级边界。
- future closure review 文档。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。

谨慎允许：

- `labs/macos_bridge_smoke/native/cjgui_macos.h`
  - 仅当内部声明无法避免，且不得新增 public runtime API。

本卡授权的未来 implementation 禁止触碰：

- `labs/macos_bridge_smoke/src/main.cj`，除非另开 execution card。
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`，除非另开 execution card。
- 正式 runtime 目录。
- public GUI API。
- Renderer / Scene / Widget / Layout / DSL。
- 跨平台 backend。
- 文本、输入法、无障碍相关实现。
- AI semantic tree / Action Router 相关实现。
- JSON schema / parser，除非另开 execution card。
- 重型 GUI 测试框架。

本轮创建 execution card 时允许修改：

- 本 execution card。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)，仅用于入口链接。

本轮创建 execution card 时禁止修改：

- `labs/macos_bridge_smoke`。
- `verify_auto_close.sh`。
- 任何运行时代码。

## 7. Truth / Projection

未来 first slice 的真相层：

- bridge 对 frame metadata / render stats 的当场观测。
- `verify_auto_close.sh` 捕获到的原始日志。
- expected metadata / stats needles 是否存在。
- 原有 auto-close lifecycle 日志是否仍通过。

只是投影 / read surface：

- harness 输出摘要。
- README 说明。
- closure review 中的验证结果。

重要边界：

- `clear_color` 是 intended clear color metadata，不是真实像素。
- `first_frame_submitted` 是执行路径证据，不是屏幕结果。
- `drawable_width` / `drawable_height` 是 bridge 观测值，不是 screenshot 尺寸证明。
- metadata / stats 不是 Renderer / Scene truth。
- metadata / stats 不是 public runtime API。

## 8. Invariants

未来实现必须守住：

- 不暴露 AppKit / Metal / Objective-C 平台对象。
- 不读取 raw pixels。
- 不生成 screenshot artifact。
- 不读取 Metal texture bytes。
- 不计算 frame hash。
- 不做 pixel diff。
- 不新增 offscreen renderer。
- 不新增 Renderer / Scene / Widget / Layout / DSL。
- 不新增跨平台 diagnostics abstraction。
- 不把 metadata 当成像素正确证明。
- 不把 smoke diagnostics 写成正式 runtime API。
- 不破坏现有 auto-close harness 和 lifecycle needle。

## 9. Verification

未来 implementation 必须验证：

- `verify_auto_close.sh` 退出码为 `0`。
- 原有 auto-close 日志 needle 全部仍存在。
- 新增 metadata / stats 日志 needle 全部存在。
- 日志中出现允许字段。
- 日志中不出现禁止字段或平台对象指针。
- closure review 明确说明不是像素级验证。

未来 implementation 无法验证：

- 屏幕真实像素正确。
- screenshot / window screenshot。
- Metal readback。
- frame hash。
- pixel diff。
- offscreen renderer。
- Renderer / Scene 正确性。
- Widget / Layout 正确性。

这些无法验证项必须作为 residual risk 写入 future closure review。

## 10. Fallout Scan Targets

未来实现完成前必须检查：

- 公共 API：不得新增 public runtime API。
- 事件流：不得改变 close / drain 生命周期语义。
- 状态流：不得新增 UI 状态真相。
- 渲染流：只能增加 smoke diagnostics，不得新增 Renderer / Scene。
- 平台桥接：平台对象仍只存在于 bridge 内部。
- 视觉 / 交互：必须说明没有像素级证据。
- 文档 / 示例：README 只能记录 smoke diagnostics，不得宣称视觉验证。
- 测试：`verify_auto_close.sh` 只能增加日志 needle，不得引入重型测试框架。

## 11. Stop-Line

本轮创建 execution card 的 stop-line：

- 不修改 `labs/macos_bridge_smoke`。
- 不修改 `verify_auto_close.sh`。
- 不实现 frame metadata / render stats。
- 不实现截图、Metal readback、frame hash、pixel diff、offscreen renderer。
- 不设计正式 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象、文本、输入法、无障碍、AI semantic tree / Action Router。
- 不引入重型 GUI 测试框架。

未来 implementation first slice 的 stop-line：

- 不读取像素。
- 不做截图。
- 不做 window screenshot。
- 不做 Metal readback。
- 不做 frame hash。
- 不做 pixel diff。
- 不做 offscreen renderer。
- 不设计正式 Renderer / Scene / Widget / Layout / DSL。
- 不新增 public runtime API。
- 不暴露平台对象。
- 不把 metadata 当成像素正确证明。

## 12. Closure Requirements

未来 implementation 完成后必须创建 closure review。

closure review 至少记录：

- landed code reality。
- 实际 write set。
- 新增 metadata / stats 日志格式。
- `verify_auto_close.sh` 命令。
- 日志路径。
- metadata / stats needle 断言结果。
- 原有 auto-close needle 是否仍通过。
- 明确声明“这不是像素级验证”。
- stop-line 是否守住。
- 未覆盖风险。

建议 future closure review 路径：

- `docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md`

## 13. Next Opening

本卡创建后，不自动执行实现。

如果用户明确继续推进，下一条 bounded implementation opening 是：

- `P1 frame metadata / render stats bounded implementation first slice`

该 opening 只能按本卡执行：

- smoke bridge 输出脱水 frame metadata / render stats 日志。
- `verify_auto_close.sh` 增加日志 needle。
- 更新 smoke README。
- 创建 future closure review。
- 更新 `docs/plans/README.md` 和 `GUI_TASK_TRACKER.md`。

除非另开 execution card，否则不得进入截图、Metal readback、frame hash、pixel diff、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、跨平台抽象或正式 runtime API 设计。
