# P1 User-Visible Window Screenshot Feasibility Closure Review

日期：2026-04-25

类型：closure review

状态：完成

## 1. Execution Card

本轮唯一 authority：

- [2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md)

本轮目标是新增一个独立 screenshot feasibility harness，用于在当前本机运行 `labs/macos_bridge_smoke` 期间请求一次用户可见窗口 / 屏幕截图，并输出脱水 success / failure classification summary。

这不是 full screenshot verification，不是像素正确性验证，也不是 pixel diff / frame hash / offscreen renderer。

## 2. Actual Write Set

本轮实际修改：

- 新增 [verify_user_visible_window_screenshot_feasibility.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh)
- 更新 [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- 新增本 closure review
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

本轮没有修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- 正式 runtime 目录
- public GUI API

## 3. Harness Mechanism

新增 harness：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh
```

机制：

- 独立脚本，不修改 `verify_auto_close.sh`。
- 调用现有 `labs/macos_bridge_smoke/scripts/build_and_run.sh` 作为被测对象。
- 默认设置 `CJGUI_AUTOCLOSE_SECONDS=5`，让窗口在截图 probe 后继续自动关闭。
- 先等待 readiness 日志：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- readiness 未满足时输出 `success=false reason=render_not_ready`，不继续请求截图。
- readiness 满足后，通过 `osascript -l JavaScript` 调用 CoreGraphics `CGWindowListCreateImage` 请求一次 on-screen image feasibility probe。
- probe 只判断是否创建了非空 image object，不保存为文件，不读取或比较像素颜色，不暴露 CoreGraphics / AppKit / Metal 对象。

## 4. Actual Verification

语法检查：

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh
```

结果：退出码 `0`。

实际运行：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh
```

结果：退出码 `0`。

日志路径：

```text
/tmp/cjgui-p1-user-visible-window-screenshot-feasibility.log
```

probe stderr 路径：

```text
/tmp/cjgui-p1-user-visible-window-screenshot-feasibility.err
```

probe stderr 大小：`0` bytes。

## 5. Readiness Evidence

实际日志包含：

```text
cjgui: window created
cjgui: metal setup complete
cjgui: first frame rendered
```

因此本轮没有把 readiness 缺失误写成截图失败。

## 6. Screenshot Request Evidence

实际 summary：

```text
cjgui screenshot feasibility: requested=true
cjgui screenshot feasibility: image_created=true
cjgui screenshot feasibility: success=true reason=none
```

最终分类结果：

```text
success=true reason=none
```

这说明当前本机 smoke 运行期间可以请求一次 CoreGraphics on-screen image 并得到非空 image object。

## 7. Lifecycle Evidence

同一轮运行继续完成 smoke lifecycle：

```text
cjgui: post close request: auto-close
cjgui: main-thread drain
cjgui: close requested: auto-close
cjgui: destroy complete
cjgui: event loop exited
Cangjie: cjgui_app_run returned 0
```

## 8. Negative Assertions

本轮明确没有：

- 保存 screenshot artifact。
- 读取或比较像素颜色。
- 建立 artifact baseline。
- 做 pixel diff。
- 做 frame hash。
- 做 offscreen renderer。
- 新增 public C ABI / runtime API。
- 暴露 `NSWindow*`、`NSView*`、`CAMetalLayer*`、Metal 对象、CoreGraphics object 或 Objective-C `id`。
- 修改 `cjgui_macos.m`、`cjgui_macos.h`、`src/main.cj`、`build_and_run.sh` 或 `verify_auto_close.sh`。
- 将 screenshot failure 写成 render failure。
- 将 smoke demo 宣称为正式 GUI runtime。

forbidden 文件检查：

```text
labs/macos_bridge_smoke/native/cjgui_macos.m          mtime 2026-04-25 14:47:58
labs/macos_bridge_smoke/native/cjgui_macos.h          mtime 2026-04-25 10:17:12
labs/macos_bridge_smoke/src/main.cj                   mtime 2026-04-25 00:17:14
labs/macos_bridge_smoke/scripts/build_and_run.sh      mtime 2026-04-25 10:18:32
labs/macos_bridge_smoke/scripts/verify_auto_close.sh  mtime 2026-04-25 14:55:55
```

工作区中 `cjgui_macos.m` 和 `verify_auto_close.sh` 仍保留前序 slice 的既有 dirty 状态；本轮没有修改、格式化、chmod 或重写这些 forbidden 文件。

## 9. What This Proves

本轮只证明：

- 独立 harness 可以启动现有 smoke。
- harness 可以等待当前 smoke readiness 日志。
- 在 readiness 达成后，当前本机可以请求一次 CoreGraphics on-screen image feasibility probe。
- harness 可以输出机器可读的脱水 success / failure classification summary。
- smoke 仍能自动关闭并返回 `0`。

## 10. What This Does Not Prove

本轮不证明：

- 用户可见窗口像素正确。
- screenshot 内容包含目标窗口。
- 窗口没有被遮挡。
- frontmost app、Space / Mission Control 或多显示器状态正确。
- compositor / display presentation 正确。
- CI / headless 环境可复核。
- pixel diff、frame hash 或 offscreen renderer 可用。
- Renderer / Scene / Widget / Layout 设计成立。

## 11. Residual Risk

残留风险：

- CoreGraphics 能返回 image object，不等于目标窗口内容正确。
- 当前没有读取像素，不能判断颜色、尺寸、窗口位置或遮挡。
- 当前没有保存 artifact，因此无法做后续人工复查或 baseline 对比。
- 当前没有区分 window-not-visible 与成功捕获但内容无关的情况。
- 屏幕录制权限、Retina scale、多显示器、Space / Mission Control、窗口遮挡、frontmost app 和 timing 仍可能影响后续真正 screenshot verification。
- CI / headless 仍未验证。

## 12. Stop-Line Result

本轮 stop-line 守住：

- 没有实现 full screenshot verification。
- 没有实现 window screenshot 选择。
- 没有读取屏幕像素。
- 没有保存 screenshot artifact。
- 没有实现 pixel diff。
- 没有实现 frame hash。
- 没有实现 offscreen renderer。
- 没有修改 smoke bridge native code。
- 没有修改 `verify_auto_close.sh`。
- 没有新增 public C ABI / runtime API。
- 没有设计 Renderer / Scene / Widget / Layout / DSL。
- 没有做跨平台抽象、文本、输入法、无障碍或 AI semantic tree / Action Router。

## 13. Next Opening

当前没有自动开启的直接实现 opening。

如果继续推进，建议先开 docs-only：

- `P1 user-visible window screenshot verification preflight`

该 preflight 应在是否允许保存临时 artifact、是否允许读取像素、如何处理权限 / 遮挡 / 多显示器 / Retina scale / timing，以及是否进入 pixel diff 或 frame hash 之前重新冻结边界。
