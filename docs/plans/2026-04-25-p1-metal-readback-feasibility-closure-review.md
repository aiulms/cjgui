# P1 Metal Readback Feasibility Closure Review

日期：2026-04-25

性质：closure review / bounded implementation first slice 封账

状态：已完成并封账

## 0. Authority

本轮唯一 implementation authority：

- [2026-04-25-p1-metal-readback-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-execution-card.md)

背景依据：

- [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)
- [2026-04-25-p1-frame-metadata-render-stats-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

## 1. Landed Code Reality

本轮只完成 `labs/macos_bridge_smoke` 内部 smoke-only first slice：

- `CJGuiMetalView` 内部在 diagnostics first frame 上执行 single-frame clear-color Metal readback feasibility probe。
- readback 只读取一个采样点，用于 clear color summary 比对。
- readback 结果只输出脱水 summary 日志。
- `verify_auto_close.sh` 保留原有 auto-close、capability、frame metadata / render stats needle，并新增 readback summary needle。
- smoke README 记录 readback diagnostics 字段和非截图 / 非用户可见窗口边界。

本轮没有新增：

- public C ABI。
- public runtime API。
- 仓颉入口改动。
- screenshot artifact。
- raw pixel bytes artifact。
- frame hash。
- pixel diff。
- offscreen renderer。
- Renderer / Scene / Widget / Layout / DSL。

## 2. Write Set

实际修改：

- [labs/macos_bridge_smoke/native/cjgui_macos.m](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m)
- [labs/macos_bridge_smoke/scripts/verify_auto_close.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh)
- [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

明确未修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `README.md`
- 正式 runtime 目录

## 3. Render Pipeline Delta

本轮有一个最小局部 render pipeline 配置变化：

- `CAMetalLayer.framebufferOnly` 从 `YES` 改为 `NO`。

原因：

- 当前 readback feasibility 需要从 drawable texture 通过 blit 复制一个采样点到 bridge 内部 staging buffer。
- `framebufferOnly=YES` 不适合该 readback / blit 用途。

边界：

- clear pass、present path 和 Cangjie 入口未改变。
- 该配置仅服务 smoke-only readback probe，不是 Renderer / Scene abstraction。
- 没有把 drawable、texture、command buffer 或 buffer 对象暴露出 bridge。

## 4. Command Buffer Completion

completion 语义：

- 本轮使用 `waitUntilCompleted`。
- 使用位置仅限 [cjgui_macos.m](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m) 内部的 single-frame clear-color readback feasibility probe。
- readback buffer contents 只在 `commandBuffer.status == MTLCommandBufferStatusCompleted` 后读取。

同步成本和时序风险：

- `waitUntilCompleted` 会同步阻塞当前 smoke first-frame render path。
- 该成本只在 diagnostics first frame 上发生一次。
- 这不是长期 render loop 架构承诺，后续如果要进入正式 renderer 或多帧验证，必须另开 preflight / execution card。

`committed=unknown` 仍保持原义：

- 它不等于 `completed=true`。
- 它不等于 displayed。
- 它不等于 pixel correct。
- 它不等于 visual verified。

## 5. Staging Object

本轮使用 bridge 内部临时 staging buffer：

- 类型：`id<MTLBuffer>`。
- storage mode：`MTLResourceStorageModeShared`。
- 用途：接收从 drawable texture blit 出来的 1x1 BGRA sample。
- 生命周期：`render` 方法内部局部对象；不跨 FFI，不持久化，不保存到文件。
- 输出：只输出 clear color match / success / degraded summary，不输出 raw bytes。

本轮没有使用独立 staging texture。

## 6. Readback Summary Log Format

实际 readback summary 日志：

```text
cjgui: metal readback: requested=true
cjgui: metal readback: command_buffer_completed=true
cjgui: metal readback: source=clear_color_probe
cjgui: metal readback: clear_color_match=true
cjgui: metal readback: success=true degraded=none
```

字段语义：

- `requested`：smoke bridge 请求执行 readback feasibility probe。
- `command_buffer_completed`：command buffer 已完成后才读取 staging buffer。
- `source`：当前只支持 `clear_color_probe`。
- `clear_color_match`：单采样点 summary 与 intended clear color 在容忍范围内匹配。
- `success` / `degraded`：probe 的脱水结果。

## 7. Verification

红线确认：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

在只新增 harness readback needle、尚未实现 bridge readback 时，命令按预期失败，退出码为 `1`，并报告：

```text
missing expected log: cjgui: metal readback:
missing expected log: requested=true
missing expected log: command_buffer_completed=true
missing expected log: source=clear_color_probe
missing expected log: clear_color_match=true
```

最终语法检查：

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- 退出码：`0`
- shell 语法检查通过。

最终 smoke harness：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

日志路径：

```text
/tmp/cjgui-p1-auto-close-verify.log
```

结果：

- 退出码：`0`
- 原有 auto-close / capability / metadata needle 继续通过。
- 新增 readback summary needle 通过。
- harness 输出：

```text
cjgui verify: auto-close log assertions passed
cjgui verify: this is not user-visible window verification
```

原有 needle 仍通过：

- `cjgui: using SDKROOT=`
- `cjgui: bridge init`
- `cjgui: capability check: metal device ok`
- `cjgui: capability check: command queue ok`
- `cjgui: window created`
- `cjgui: metal setup complete`
- `cjgui: first frame rendered`
- `cjgui: frame metadata:`
- `index=1`
- `drawable=`
- `scale=`
- `pixel_format=BGRA8Unorm`
- `clear_color=`
- `submitted=true`
- `committed=unknown`
- `attempts=1`
- `success=true`
- `degraded=none`
- `cjgui: post close request`
- `cjgui: main-thread drain`
- `cjgui: close requested`
- `cjgui: destroy complete`
- `cjgui: event loop exited`
- `Cangjie: cjgui_app_run returned 0`

新增 readback needle 通过：

- `cjgui: metal readback:`
- `requested=true`
- `command_buffer_completed=true`
- `source=clear_color_probe`
- `clear_color_match=true`
- `cjgui: metal readback: success=true degraded=none`

禁止文件检查：

```bash
git diff -- /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

结果：

- 无输出。
- `cjgui_macos.h` 未修改。
- `src/main.cj` 未修改。
- `build_and_run.sh` 未修改。

## 8. Evidence Boundary

本验证只证明：

- 当前 smoke bridge 可以在 command buffer completion 之后读取一个 clear-color probe sample。
- 当前 bridge 可以把 readback 结果压缩成机器可复核 summary。
- 当前 harness 可以复核 readback summary 日志。
- 既有构建、Metal capability、frame metadata、lifecycle queue、auto-close 和返回码验证仍通过。

本验证不是，也不证明：

- screenshot。
- window screenshot。
- frame hash。
- pixel diff。
- offscreen renderer。
- 用户可见窗口正确。
- compositor / display presentation 正确。
- 正式 GUI runtime。

## 9. Stop-Line Review

已守住：

- 不保存 raw pixel bytes。
- 不生成 screenshot artifact。
- 不实现 frame hash。
- 不实现 pixel diff。
- 不实现 offscreen renderer。
- 不新增 public C ABI / runtime API。
- 不暴露平台对象。
- 不设计 Renderer / Scene。
- 不设计 Widget / Layout / DSL。
- 不修改 `cjgui_macos.h`。
- 不修改 `src/main.cj`。
- 不修改 `build_and_run.sh`。
- 不把 readback summary 宣称为用户可见窗口验证。
- 不把 smoke demo 宣称为正式 runtime。

明确为否：

- 是否保存 raw bytes：否。
- 是否生成 screenshot artifact：否。
- 是否新增 public C ABI / runtime API：否。
- 是否暴露平台对象：否。

## 10. Residual Risk

残留风险：

- 用户可见窗口仍未验证。
- compositor / display presentation 仍未验证。
- 多帧、多窗口、resize 仍未验证。
- CI / headless 环境仍未验证。
- 当前只采样 clear-color probe，不验证整帧内容。
- 当前 `waitUntilCompleted` 只适合 smoke first slice，不适合长期 render loop。
- 当前没有 screenshot、frame hash、pixel diff 或 offscreen renderer。

这些风险不能由本 closure 自动开启实现，必须在后续 preflight / execution card 中单独处理。

## 11. Next Opening

本 slice 已封账。

当前不自动开启新的直接实现 opening。

若继续推进，建议下一步仍为 docs-only，例如：

- `P1 user-visible window verification evidence preflight`
- 或 `P1 frame hash / pixel diff prerequisites preflight`

不得从本 closure 自动进入 screenshot、frame hash、pixel diff、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、跨平台抽象或 public runtime API。
