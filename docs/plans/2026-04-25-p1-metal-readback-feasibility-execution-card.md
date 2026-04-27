# P1 Metal Readback Feasibility Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization
状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行
范围：只授权未来一个极窄 first slice，在 `labs/macos_bridge_smoke` 内部探索 smoke-only、single-frame、clear-color Metal readback feasibility。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 确认依据：
  - [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 仍只允许复用当前 macOS smoke、Metal bridge 和 shell harness。
- 上层尽量仓颉原生：是。不得新增 public C ABI / runtime API，也不得让仓颉层持有 Metal / AppKit 对象。
- 底层只保留必要平台桥接：是。readback feasibility 只能作为 bridge 内部 smoke diagnostics。
- 没有过早抽象跨平台：是。本卡只覆盖 macOS smoke，不定义跨平台 readback contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现必须新增 public API、保存 raw bytes、生成 screenshot、设计 Renderer / Scene、实现 frame hash / pixel diff / offscreen renderer 或扩大 write set，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)

背景约束：

- [2026-04-25-p1-frame-metadata-render-stats-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-preflight.md)
- [2026-04-25-p1-frame-metadata-render-stats-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡扩展成：

- screenshot。
- window screenshot。
- frame hash。
- pixel diff。
- offscreen renderer。
- Renderer / Scene。
- Widget / Layout / DSL。
- 跨平台 readback abstraction。
- public C ABI / runtime API。

## 2. Why Metal Readback, Not Screenshot

选择 Metal readback feasibility 作为下一条候选 evidence chain，而不是 screenshot，原因是：

- 当前 smoke 的最小视觉正确性是“受控 Metal render target 中出现预期 clear color 的机器可复核像素证据”，不是完整用户可见窗口截图。
- Metal readback 更贴近当前已有证据链：drawable size、pixel format、clear color metadata、submitted 状态和 render success。
- Metal readback 不依赖窗口焦点、窗口可见性、遮挡、多显示器、屏幕录制权限或 Space 状态。
- 之前 screenshot 路径已经出现过 `could not create image from display`，说明它受外部显示环境影响较大。
- screenshot 更适合未来验证用户可见窗口结果，但不适合作为当前第一条稳定机器证据。

这不意味着 Metal readback 已被批准实现。

本卡只允许未来在 smoke 内探索 feasibility，且只输出脱水 summary。

## 3. Goal

本卡授权的未来唯一目标：

- 在 `labs/macos_bridge_smoke` 内部完成一个 smoke-only、single-frame、clear-color Metal readback feasibility first slice。

未来 first slice 只验证：

- 当前 smoke 的受控 clear-color render target 是否能在 command buffer completion 之后产生可机器复核的 readback summary。
- `verify_auto_close.sh` 是否能复核该 summary 日志。
- 既有 auto-close、capability、metadata / stats 日志 needle 是否仍通过。

未来 first slice 不验证：

- 用户可见窗口像素。
- screenshot / window screenshot。
- frame hash。
- pixel diff。
- offscreen renderer。
- Renderer / Scene。
- Widget / Layout / DSL。
- 跨平台一致性。

## 4. Scope

未来 first slice 只允许：

- 在 smoke bridge 内部添加最小 Metal readback feasibility path。
- 只针对单帧 clear-color probe。
- 只输出脱水 readback summary 日志。
- 让 `verify_auto_close.sh` 最多增加 readback summary needle。
- 更新 smoke README，明确 readback 只证明受控 Metal render target，不证明用户可见窗口。
- 创建 future closure review 并更新计划索引 / 任务账本。

未来 first slice 明确不允许：

- 保存 raw pixel bytes。
- 生成 screenshot artifact。
- 生成 window screenshot artifact。
- 实现 frame hash。
- 实现 pixel diff。
- 实现 offscreen renderer。
- 新增 public C ABI / runtime API。
- 暴露 Metal / AppKit / Objective-C 平台对象。
- 设计 Renderer / Scene / Widget / Layout / DSL。

## 5. Write Set

未来 implementation 允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
  - 仅允许在 smoke bridge 内部实现 single-frame clear-color Metal readback feasibility。
  - 仅允许输出脱水 readback summary 日志。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - 仅允许增加 readback summary 日志 needle。
  - 原有 auto-close、capability、frame metadata / render stats needle 必须保留。
- `labs/macos_bridge_smoke/README.md`
  - 仅允许记录 smoke readback diagnostics 字段、验证命令和非截图 / 非用户可见窗口边界。
- future closure review：
  - 建议路径：`docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md`
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未来 implementation 默认不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `README.md`
- 正式 runtime 目录。
- public GUI API。
- Renderer / Scene / Widget / Layout / DSL。
- 跨平台 backend。
- 文本、输入法、无障碍相关实现。
- AI semantic tree / Action Router 相关实现。

例外规则：

- 如果未来发现不修改 `cjgui_macos.h` 就无法实现内部 helper 声明，必须暂停并在 execution card 追加批准；不得顺手新增 public C ABI。
- 如果未来发现必须修改 `build_and_run.sh` 或仓颉入口，必须暂停并另开 execution card。

本轮创建 execution card 时允许修改：

- 本 execution card。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)，仅用于入口链接。

本轮创建 execution card 时禁止修改：

- `labs/macos_bridge_smoke`。
- `verify_auto_close.sh`。
- 任何运行时代码。

## 6. Allowed Logs

未来 first slice 允许输出的日志只能是脱水 summary。

建议日志 needle 方向：

```text
cjgui: metal readback: requested=true
cjgui: metal readback: command_buffer_completed=true
cjgui: metal readback: source=clear_color_probe
cjgui: metal readback: clear_color_match=true
cjgui: metal readback: success=true degraded=none
```

允许字段：

- `requested`
- `command_buffer_completed`
- `source`
- `pixel_format`
- `clear_color_match`
- `success`
- `degraded`
- `degraded_reason`

默认不允许输出：

- raw pixel bytes。
- full pixel dump。
- screenshot path。
- frame hash。
- pixel diff result。
- texture pointer。
- drawable pointer。
- command buffer pointer。
- Objective-C object identity。

如果未来实现认为必须输出一个 sampled color summary：

- 必须是脱水标量 summary。
- 不得保存 raw bytes。
- 不得输出整帧 bytes。
- 不得把 sampled color 写成 public API。
- closure review 必须说明 sample / summary 的真实语义和限制。

## 7. Readback Result Boundary

readback 结果只能是脱水 summary。

允许：

- `clear_color_match=true/false`
- `success=true/false`
- `degraded_reason=<short-enum>`
- `command_buffer_completed=true/false`
- `pixel_format=BGRA8Unorm`

不允许：

- 保存 raw pixel bytes。
- 写出二进制 artifact。
- 写出 screenshot artifact。
- 生成 hash artifact。
- 生成 diff artifact。
- 将 readback bytes 返回给仓颉层。
- 将 readback bytes 挂到 public runtime API。

## 8. Platform Object Boundary

未来 first slice 不允许暴露以下对象：

- `CAMetalDrawable*`
- `id<MTLTexture>`
- `id<MTLCommandBuffer>`
- `CAMetalLayer*`
- `id<MTLBuffer>`
- `NSWindow*`
- `NSView*`
- Objective-C `id`
- 任何平台对象裸指针或 native handle。

这些对象只能存在于 bridge 内部短生命周期路径中。

不允许：

- 写入日志。
- 传给仓颉层。
- 暴露为 public C ABI。
- 被 harness 持有。
- 被 README 写成用户可依赖的接口。

## 9. Command Buffer Completion

readback 必须诚实处理 command buffer completion。

规则：

- 仅 `commit` 不等于 completed。
- 仅 `submitted=true` 不等于 completed。
- 当前 metadata 的 `committed=unknown` 不能被伪装成：
  - `completed=true`
  - `presented=true`
  - `GPU done`
  - `displayed`
  - `pixel correct`
  - `visual verified`
- readback 必须在 bridge 能诚实判断 command buffer 已完成后执行。

允许的完成语义：

- 使用 command buffer completion handler，并在 handler 内或 handler 后做 readback summary。
- 或在未来 first slice 中使用 `waitUntilCompleted`，但必须满足下一节限制。

closure review 必须记录：

- 使用的是 completion handler 还是 `waitUntilCompleted`。
- readback 发生在 completion 之前还是之后。
- 如果 completion 不可用或失败，degraded reason 是什么。

## 10. `waitUntilCompleted` Boundary

未来 first slice 可以谨慎允许 `waitUntilCompleted`，但只限于：

- `labs/macos_bridge_smoke/native/cjgui_macos.m` 内部。
- 单帧 clear-color readback feasibility。
- 自动关闭 smoke / verification harness 路径。
- 仅为了获得第一条可复核 readback evidence。

必须说明：

- 这是实验期同步点。
- 这不是长期 render loop 架构。
- 这不是 Renderer / Scene scheduling 模型。
- 这不是 public runtime behavior。
- 该同步成本必须写入 closure review。

禁止：

- 把 `waitUntilCompleted` 设计成正式渲染帧同步策略。
- 在仓颉公共层暴露 wait / sync API。
- 为了等待完成重写事件循环或 lifecycle queue。

## 11. Staging Buffer / Texture Boundary

如果未来实现需要 staging buffer 或 staging texture，必须收口为：

- bridge 内部临时对象。
- 单帧 clear-color probe 专用。
- 不跨 FFI 暴露。
- 不写入 public API。
- 不保存 raw bytes 到文件。
- 不复用为正式 Renderer resource abstraction。
- 创建 / 使用 / 释放路径必须在 closure review 中说明。

如果无法在这个边界内完成，必须暂停，不得继续实现。

## 12. Render Pipeline Boundary

默认不允许改变 render pipeline。

未来 first slice 只可在必要时做最小局部调整，例如：

- 为 readback feasibility 调整当前 smoke clear pass 的局部配置。
- 为 staging / blit 增加最小内部命令。

但必须满足：

- 不改变仓颉入口。
- 不改变 public C ABI。
- 不引入 Renderer / Scene。
- 不影响 auto-close lifecycle queue。
- 不把 readback path 变成正式 render path。
- closure review 必须解释为什么该局部调整必要。

默认禁止：

- 重写 Metal setup。
- 重写 frame scheduling。
- 新增 render command graph。
- 新增 offscreen renderer。
- 新增 Renderer / Scene abstraction。

## 13. Avoiding Renderer Abstraction

为避免 Metal readback 变成 renderer abstraction，未来实现必须遵守：

- 文件名、日志和文档都称为 `smoke readback diagnostics` 或 `Metal readback feasibility`。
- 不使用 `RendererFrame`、`SceneFrame`、`RenderTarget` 这类正式抽象名作为 public concept。
- 不记录 scene id。
- 不记录 widget / layout 信息。
- 不创建 renderer package / module。
- 不把 readback path 做成可复用平台抽象。
- 不让 smoke readback 反向决定未来 Renderer / Scene API。

如果未来需要正式 renderer diagnostics：

- 必须另开 Renderer / Scene preflight。
- 必须重新定义 renderer truth、scene truth 和 render command owner。

## 14. Avoiding Runtime API Creep

为避免 smoke diagnostics 变成正式 runtime API：

- 不新增 public C ABI。
- 不新增仓颉 public runtime API。
- 不新增 header declaration 给仓颉层调用。
- 不把 readback summary 作为稳定协议发布。
- 不把日志格式写成跨版本承诺。
- 不让外部用户依赖 readback fields。

README / closure review 必须写清：

- 这是 `labs/macos_bridge_smoke` 的实验诊断。
- 这不是正式 GUI runtime 测试框架。
- 这不证明用户可见窗口正确。

## 15. Verification Harness Boundary

未来 `verify_auto_close.sh` 最多可以增加这些 needle：

- `cjgui: metal readback:`
- `requested=true`
- `command_buffer_completed=true`
- `source=clear_color_probe`
- `clear_color_match=true`
- `success=true`
- `degraded=none`

它必须继续检查原有 needle：

- SDKROOT。
- bridge init。
- Metal capability check。
- window created。
- metal setup complete。
- first frame rendered。
- frame metadata / render stats。
- post close request。
- main-thread drain。
- close requested。
- destroy complete。
- event loop exited。
- `Cangjie: cjgui_app_run returned 0`。

harness 不允许：

- 保存 raw bytes。
- 保存 screenshot。
- 计算 frame hash。
- 做 pixel diff。
- 解析或持有平台对象。
- 宣称完成用户可见窗口验证。

## 16. Future Closure Requirements

未来 implementation 完成后必须创建 closure review。

closure review 至少记录：

- 本 execution card 路径。
- 实际 write set。
- 是否修改了 render pipeline；如果修改，为什么是最小必要调整。
- command buffer completion 语义：
  - completion handler 还是 `waitUntilCompleted`。
  - readback 是否发生在 completed 之后。
  - 同步成本和时序风险。
- 是否使用 staging buffer / texture。
- staging object 的生命周期。
- 实际 readback summary 日志格式。
- `verify_auto_close.sh` 命令。
- 日志路径。
- 原有 auto-close / capability / metadata needle 是否仍通过。
- 新增 readback summary needle 是否通过。
- 是否保存 raw bytes：必须为否。
- 是否生成 screenshot artifact：必须为否。
- 是否新增 public C ABI / runtime API：必须为否。
- 是否暴露平台对象：必须为否。
- 明确声明：
  - 这不是 screenshot。
  - 这不是 frame hash。
  - 这不是 pixel diff。
  - 这不是 offscreen renderer。
  - 这不证明用户可见窗口正确。
  - 这不是正式 GUI runtime。
- residual risk：
  - 用户可见窗口仍未验证。
  - compositor / display presentation 仍未验证。
  - 多帧、多窗口、resize、CI / headless 仍未验证。

## 17. Stop-Line

本轮创建 execution card 的 stop-line：

- 本轮不实现 Metal readback。
- 本轮不修改 `labs/macos_bridge_smoke` 代码。
- 本轮不修改 `verify_auto_close.sh`。
- 本轮不读取像素。
- 本轮不生成 screenshot artifact。
- 本轮不保存 raw pixel bytes。
- 本轮不实现 frame hash。
- 本轮不实现 pixel diff。
- 本轮不实现 offscreen renderer。
- 本轮不新增 public C ABI / runtime API。
- 本轮不设计 Renderer / Scene。
- 本轮不设计 Widget / Layout / DSL。
- 本轮不做跨平台抽象。
- 本轮不做文本、输入法、无障碍。
- 本轮不做 AI semantic tree / Action Router。
- 本轮不把当前 smoke demo 宣称为正式 runtime。

未来 implementation first slice 的 stop-line：

- 只做 smoke-only、single-frame、clear-color readback feasibility。
- 不保存 raw bytes。
- 不生成 screenshot artifact。
- 不实现 frame hash / pixel diff / offscreen renderer。
- 不新增 public C ABI / runtime API。
- 不暴露平台对象。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 readback summary 当成用户可见窗口验证。

## 18. Next Opening

本卡创建后，不自动执行实现。

如果用户明确继续推进，下一条 bounded implementation opening 是：

- `P1 Metal readback feasibility bounded implementation first slice`

该 opening 只能按本卡执行：

- 只在 `labs/macos_bridge_smoke` 内部探索 single-frame clear-color Metal readback feasibility。
- 只输出脱水 summary。
- 只让 `verify_auto_close.sh` 增加 summary needle。
- 完成后必须创建 closure review。

除非另开 execution card，否则不得进入 screenshot、frame hash、pixel diff、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、跨平台抽象或正式 runtime API 设计。
