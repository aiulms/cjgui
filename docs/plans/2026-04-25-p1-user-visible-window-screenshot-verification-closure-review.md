# P1 User-Visible Window Screenshot Verification Closure Review

日期：2026-04-25

性质：closure review / bounded implementation first slice 封账

状态：已完成并封账

## 0. Authority

本轮唯一 implementation authority：

- [2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md)

背景依据：

- [2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md)
- [2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)
- [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

本轮目标：

- 新增独立 screenshot verification harness。
- 启动现有 `labs/macos_bridge_smoke`。
- 等待 readiness 日志。
- 保存一个临时 screenshot artifact。
- 归属目标 smoke window。
- 只做极窄 clear-color sample summary。
- 输出脱水 success / failure classification summary。

这不是 full GUI verification，不是 pixel diff，不是 frame hash，不是 offscreen renderer，也不是正式 GUI runtime。

## 1. Actual Write Set

实际修改：

- 新增 [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
- 更新 [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- 新增本 closure review
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

明确未修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `README.md`
- 正式 runtime 目录
- public GUI API

## 2. Harness Mechanism

新增独立 verification harness：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

机制：

- 不复用、不修改 `verify_user_visible_window_screenshot_feasibility.sh`。
- 不修改 `verify_auto_close.sh`。
- 调用现有 `labs/macos_bridge_smoke/scripts/build_and_run.sh` 作为被测对象。
- 默认设置 `CJGUI_AUTOCLOSE_SECONDS=8`，避免截图 probe 与自动关闭竞争。
- 先等待 readiness 日志：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- readiness 未达成时输出 `success=false reason=render_not_ready`，不继续截图。
- readiness 达成后记录 smoke process id。
- 使用 JXA 调用 CoreGraphics / AppKit：
  - `CGWindowListCopyWindowInfo` 枚举 on-screen window。
  - 用 owner pid、window title 和 bounds 归属目标 smoke window。
  - 用 `CGWindowListCreateImage` 捕获目标 window bounds 的 on-screen image region。
  - 用 `NSBitmapImageRep` 写入临时 PNG artifact。
  - 用 `NSBitmapImageRep.colorAtXY` 读取中心附近 `3x3` clear-color sample。

本机制不暴露 `CGWindowID`、`CGImageRef`、`NSWindow*`、`NSView*`、`NSScreen*`、Objective-C `id` 或任何平台对象裸指针。所有信息都只作为 harness diagnostics 输出。

## 3. Artifact Policy

临时 artifact 路径：

```text
/tmp/cjgui-p1-screenshot-verification.V0mirR/target-window.png
```

实际生命周期：

- artifact 创建：是。
- 成功时是否删除：是。
- 实际结果：`artifact_deleted=true`，`artifact_retained=false`。
- 当前路径在验证后已不存在。

提交 / baseline：

- artifact 是否提交：否。
- artifact 是否进入 baseline：否。
- artifact 是否作为 golden image：否。
- artifact 是否写入仓库目录：否。

失败保留策略：

- 若未来失败且 artifact 已创建，harness 会保留临时目录并输出 `artifact_delete_strategy=manual rm -rf <dir>`。
- 本轮实际为成功路径，因此没有保留 artifact。

## 4. Target Attribution

目标窗口归属方式：

- shell harness 启动 smoke 并解析实际 smoke process id。
- JXA / CoreGraphics window list 按 owner pid 匹配目标窗口。
- title 辅助匹配 `Cangjie macOS Bridge Smoke`。
- bounds 用于捕获目标窗口区域。
- frontmost app、display、scale 只作为脱水 diagnostics。

实际 diagnostics：

```text
cjgui screenshot verification: smoke_pid=96671
cjgui screenshot verification: target_pid_observed=true
cjgui screenshot verification: window_title_matched=true
cjgui screenshot verification: window_bounds_observed=true
cjgui screenshot verification: frontmost_app_matched=true
cjgui screenshot verification: target_bounds=397,140,718,446
cjgui screenshot verification: display_observed=true
cjgui screenshot verification: scale_observed=true
cjgui screenshot verification: capture_covers_target_bounds=true
```

这些 diagnostics 不进入 public runtime API，不构成 Widget / Scene / Renderer contract。

## 5. Sample Boundary

sample 位置：

- 目标窗口 bounds 对应 screenshot artifact 的中心附近。

sample 范围：

- `3x3`
- 实际 `sample_points=9`

sample 内容：

- 只比较当前 smoke expected clear color。
- 只输出脱水 summary。
- 不输出 sampled pixel values。
- 不输出 raw bytes。
- 不读取整图像素。

实际 sample summary：

```text
cjgui screenshot verification: sample_requested=true
cjgui screenshot verification: sample_points=9
cjgui screenshot verification: sample_match=true
```

## 6. Verification

语法检查：

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：

- 退出码：`0`

screenshot verification harness：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

日志路径：

```text
/tmp/cjgui-p1-user-visible-window-screenshot-verification.log
```

probe stderr 路径：

```text
/tmp/cjgui-p1-user-visible-window-screenshot-verification.err
```

probe stderr 大小：

```text
0 bytes
```

结果：

- 退出码：`0`
- readiness needle 出现：是。
- screenshot request 发起：是。
- 临时 artifact 创建：是。
- target pid / title / bounds / frontmost app / display / scale diagnostics 输出：是。
- 只做极窄 clear-color sample：是。
- 最终 classification：

```text
cjgui screenshot verification: success=true reason=none
```

原有 auto-close harness 回归：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

日志路径：

```text
/tmp/cjgui-p1-auto-close-verify.log
```

结果：

- 退出码：`0`
- `cjgui verify: auto-close log assertions passed`
- `Cangjie: cjgui_app_run returned 0`
- 原有 auto-close / capability / metadata / Metal readback summary needle 仍通过。

## 7. Negative Assertions

本轮明确没有：

- 修改 `cjgui_macos.m`。
- 修改 `cjgui_macos.h`。
- 修改 `src/main.cj`。
- 修改 `build_and_run.sh`。
- 修改 `verify_auto_close.sh`。
- 新增 public C ABI / runtime API。
- 提交 screenshot artifact。
- 建立 baseline。
- 读取整图像素。
- 输出 raw bytes。
- 输出整图像素数组。
- 做 pixel diff。
- 做 frame hash。
- 做 offscreen renderer。
- 设计 Renderer / Scene。
- 设计 Widget / Layout / DSL。
- 做跨平台抽象。
- 把 screenshot verification 宣称为完整视觉验证。
- 把 smoke demo 宣称为正式 GUI runtime。

## 8. What This Proves

本轮只证明：

- 独立 harness 可以启动现有 smoke。
- harness 可以等待 readiness 日志。
- 当前本机可以在 smoke 运行期间创建一个临时目标窗口 bounds 截图 artifact。
- harness 可以通过 owner pid、title 和 bounds 归属目标 smoke window。
- harness 可以在目标窗口 screenshot 中做中心附近 `3x3` clear-color sample summary。
- 当前本机本轮得到 `success=true reason=none`。
- 成功路径会删除 artifact 和临时目录。
- 原有 auto-close harness 未被破坏。

## 9. What This Does Not Prove

本轮不证明：

- full GUI verification。
- 所有像素正确。
- pixel diff。
- frame hash。
- offscreen renderer。
- baseline 稳定。
- CI / headless 可复核。
- 多窗口、多显示器、多 Space 或遮挡场景稳定。
- compositor correctness 对所有桌面状态成立。
- Renderer / Scene / Widget / Layout 设计成立。
- 当前 smoke demo 是正式 GUI runtime。

特别说明：

- 本轮 sample 成功只表示当前本机、当前 smoke、当前窗口状态下，目标 bounds 截图中心附近 clear-color sample 匹配。
- 它不能替代 Metal readback truth。
- 它也不能替代未来完整截图 diff、frame hash 或 offscreen verification。

## 10. Residual Risk

残留风险：

- 用户可见窗口只验证了当前本机一次成功路径。
- 窗口遮挡、Space / Mission Control、frontmost app 变化、Retina scale 变化、多显示器和 timing 仍可能影响结果。
- 当前没有 pixel diff、frame hash 或 baseline。
- 当前没有 CI / headless 证据。
- 当前没有验证 resize、多帧、多窗口或复杂 UI。
- 当前没有验证文本、控件、layout 或 anti-aliasing。
- 当前 screenshot artifact 成功后删除；closure 只保留日志 evidence。

## 11. Stop-Line Result

本轮 stop-line 守住：

- 不修改 `cjgui_macos.m`、`cjgui_macos.h`、`src/main.cj`、`build_and_run.sh` 或 `verify_auto_close.sh`。
- 不新增 public C ABI / runtime API。
- 不提交 screenshot artifact。
- 不建立 baseline。
- 不读取整图像素或输出 raw bytes。
- 不做 pixel diff。
- 不做 frame hash。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 screenshot verification 宣称为完整视觉验证。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 12. Next Opening

当前没有自动开启的直接实现 opening。

如果继续推进，建议下一步先走 docs-only：

- `P1 screenshot verification artifact review / retention policy preflight`

用途：

- 冻结成功时是否允许保留 artifact 作为 closure evidence。
- 冻结失败 artifact 的隐私、路径、清理和审查策略。
- 冻结何时才允许进入 pixel diff / frame hash preflight。

在该 opening 之前，不允许自动进入 pixel diff、frame hash、baseline、offscreen renderer、Renderer / Scene、Widget / Layout / DSL 或 public runtime API。
