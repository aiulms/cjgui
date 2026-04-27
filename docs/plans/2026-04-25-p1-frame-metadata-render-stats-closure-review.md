# P1 Frame Metadata / Render Stats Closure Review

日期：2026-04-25

性质：closure review / bounded implementation first slice 封账

状态：已完成并封账

## 0. Authority

本轮唯一 implementation authority：

- [2026-04-25-p1-frame-metadata-render-stats-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-execution-card.md)

背景依据：

- [2026-04-25-p1-frame-metadata-render-stats-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-preflight.md)
- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

## 1. Landed Code Reality

本轮只完成 `labs/macos_bridge_smoke` 内部 first slice：

- `CJGuiMetalView` 内部新增 smoke diagnostics 计数：
  - frame index
  - render attempt count
- smoke bridge 在 diagnostics 启用后输出一条或少量脱水 frame metadata / render stats 日志。
- `verify_auto_close.sh` 继续封装现有自动关闭日志断言，并新增 metadata / stats needle。
- smoke README 记录 diagnostics 字段语义和非像素级边界。

本轮没有新增：

- C ABI。
- public runtime API。
- JSON schema / parser。
- Renderer / Scene / Widget / Layout / DSL。
- 截图、Metal readback、frame hash、pixel diff 或 offscreen renderer。

## 2. Write Set

实际修改：

- [labs/macos_bridge_smoke/native/cjgui_macos.m](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m)
- [labs/macos_bridge_smoke/scripts/verify_auto_close.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh)
- [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

明确未修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`

## 3. Metadata / Stats Log Format

当前日志格式：

```text
cjgui: frame metadata: index=1 drawable=1440x840 scale=2.00 pixel_format=BGRA8Unorm clear_color=0.08,0.16,0.20,1.00 submitted=true committed=unknown attempts=1 success=true degraded=none
```

最终日志中实际出现了 `index=1` 和 `index=2` 两条 metadata line；`index=1` 是 harness 断言的 first diagnostics frame，后续 `index=2` 来自 AppKit lifecycle 触发的后续 render。两条日志字段形态相同，且都只包含脱水 diagnostics。

字段语义：

- `index`：smoke diagnostics 启用后的 frame index。
- `drawable`：bridge 观测到的 drawable width / height。
- `scale`：bridge 观测到的 scale factor。
- `pixel_format`：脱水 pixel format 名称。
- `clear_color`：intended clear color metadata。
- `submitted`：当前 render path 已提交 frame。
- `committed`：当前 bridge 不能诚实证明 GPU / display 完成状态，因此输出 `unknown`。
- `attempts`：smoke diagnostics 启用后的 render attempt count。
- `success` / `degraded`：当前 render attempt 在 bridge 观测范围内的成功状态和降级原因。

这些字段只包含数字、布尔和短字符串；不携带 `NSWindow*`、`NSView*`、`CAMetalLayer*`、`CAMetalDrawable*`、`id<MTLTexture>`、`id<MTLCommandBuffer>`、Objective-C `id` 或任何平台对象裸指针。

## 4. Verification

红线确认：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

在只新增 harness needle、尚未输出 metadata 日志时，命令按预期失败，并报告：

```text
missing expected log: cjgui: frame metadata:
missing expected log: index=1
missing expected log: drawable=
missing expected log: scale=
missing expected log: pixel_format=BGRA8Unorm
missing expected log: clear_color=
missing expected log: submitted=true
missing expected log: committed=unknown
missing expected log: attempts=1
missing expected log: success=true
missing expected log: degraded=none
```

最终验证命令：

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
- 原有 auto-close needle 继续通过：
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
- 新增 metadata / stats needle 通过：
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

## 5. Evidence Boundary

本验证只证明：

- 当前 smoke bridge 可以输出一条或少量脱水 frame metadata / render stats 日志。
- 当前 harness 可以机器复核这些日志字段存在。
- 既有构建、Metal capability、lifecycle queue、auto-close 和返回码验证仍通过。

本验证不证明：

- 屏幕真实像素正确。
- clear color 真实落到了窗口像素上。
- window screenshot 正确。
- Metal drawable 可读。
- frame hash 或 pixel diff 通过。
- offscreen renderer 可用。
- Renderer / Scene / Widget / Layout 正确。

`clear_color` 只是 intended clear color metadata；它不是像素级验证，也不证明屏幕真实颜色正确。

## 6. Stop-Line Review

已守住：

- 不读取像素。
- 不生成 screenshot artifact。
- 不做 window screenshot。
- 不做 Metal readback。
- 不做 frame hash。
- 不做 pixel diff。
- 不做 offscreen renderer。
- 不新增 JSON schema / parser。
- 不新增 C ABI。
- 不新增 public runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象、文本、输入法、无障碍、AI semantic tree / Action Router。
- 不暴露 AppKit / Metal / Objective-C 平台对象指针。
- 不修改 `labs/macos_bridge_smoke/src/main.cj`。
- 不修改 `labs/macos_bridge_smoke/scripts/build_and_run.sh`。
- 不把 smoke demo 宣称为正式 runtime。

## 7. Residual Risk

残留风险：

- metadata / stats 仍然只是 bridge 观测日志，不是视觉结果。
- `committed=unknown` 表示当前没有 GPU completion 或 display presentation 证明。
- 当前 harness 只做日志 needle 检查，不解析字段类型、不验证字段范围。
- 当前没有真实多窗口、多 drawable、多 display 或 resize 压力验证。
- 当前没有 screenshot、Metal readback、frame hash、pixel diff 或 offscreen renderer。
- 当前没有自动视觉验证，也没有 headless GUI 测试能力。

这些风险必须在后续截图、Metal readback、frame hash、pixel diff 或 offscreen renderer 相关 preflight / execution card 中单独处理。

## 8. Next Opening

本 slice 已封账。

当前不自动开启新的直接实现 opening。

若继续推进，推荐仍先 docs-only 冻结下一条验证路径，例如：

- `P1 screenshot / Metal readback verification preflight`
- 或 `P1 frame metadata field parsing preflight`

不得从本 closure 自动进入截图、Metal readback、frame hash、pixel diff、offscreen renderer、Renderer / Scene、Widget / Layout / DSL 或跨平台抽象。
