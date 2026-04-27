# P1 User-Visible Window Verification Evidence Preflight

日期：2026-04-25

性质：docs-only / verification evidence preflight / P1 runtime foundation

状态：完成；不批准直接实现

范围：冻结“用户可见窗口验证证据”是否现在开启，以及未来若开启第一张 execution card 应该如何收窄。本轮不实现 screenshot、window screenshot、pixel diff、frame hash 或 offscreen renderer。

## 1. 背景

当前已经完成：

- [P1 automated GUI verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [P1 frame metadata / render stats first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [P1 Metal readback feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)

当前已有三类机器可复核证据：

- lifecycle / capability / auto-close 日志 harness。
- 脱水 frame metadata / render stats。
- smoke-only、single-frame、clear-color Metal readback summary。

当前仍没有：

- 用户可见窗口像素正确性证明。
- compositor / display presentation 正确性证明。
- 稳定 window screenshot 能力。
- CI / headless 环境稳定可复核视觉证据。

本 preflight 只冻结下一条证据线的边界。

它不是：

- screenshot implementation authorization。
- window screenshot implementation authorization。
- pixel diff / frame hash implementation authorization。
- offscreen renderer design。
- Renderer / Scene design。
- public runtime API design。

## 2. Metal Readback Summary 已经证明什么

当前 Metal readback summary 能证明：

- 当前 smoke bridge 可以在 command buffer completion 之后读取一个 clear-color probe sample。
- 当前 readback 发生在 bridge 内部，使用临时 staging buffer，不跨 FFI。
- 当前 readback summary 可以被 `verify_auto_close.sh` 机器复核。
- 当前受控 Metal render target 的单点 clear color summary 与 intended clear color 匹配。
- 既有 build、capability、frame metadata、lifecycle queue、auto-close 和返回码验证仍通过。

这些证据属于：

- Metal render target evidence。
- bridge-internal diagnostics evidence。
- smoke-only feasibility evidence。

它们比纯日志更接近像素证据，但仍不是用户可见窗口证据。

## 3. Metal Readback Summary 仍不能证明什么

当前 Metal readback summary 不能证明：

- 用户可见窗口像素正确。
- AppKit window 已经在屏幕上可见。
- 窗口没有被遮挡、隐藏、最小化或切到其他 Space。
- compositor 已经把 drawable 呈现到 display。
- display presentation 之后的颜色和 Metal render target 一致。
- window screenshot 稳定可用。
- screenshot 权限、焦点、多显示器、Retina scale 和 CI / headless 环境可控。
- frame hash 或 pixel diff 通过。
- 多帧、多窗口、resize 或真实 UI 场景正确。

关键边界：

> Metal readback truth 是 render target truth；用户可见窗口 truth 是 OS / compositor / display 之后的 evidence。二者不能互相冒充。

## 4. Truth 分层

### 4.1 Metal Render Target Truth

Metal render target readback 的 truth 是：

- 某个受控 Metal texture / drawable 在 command buffer completion 之后的 bytes / sample / summary。

它适合证明：

- GPU command 已完成。
- 受控 clear path 至少写入了预期 sample。
- 当前 render target 可被 bridge 内部读取并降为 summary。

它不证明：

- 用户看到了该内容。
- compositor 已经呈现。
- window screenshot 可用。
- UI 状态、Renderer / Scene 或 Widget / Layout 正确。

### 4.2 User-Visible Window Truth

用户可见窗口验证的 truth 是：

- OS / compositor 之后，某个屏幕区域或窗口区域的可见图像证据。

它适合证明：

- 当前窗口最终被系统合成到用户可见 display 上。
- 未来可以作为 screenshot artifact、frame hash 或 pixel diff 的 source image。
- 人类肉眼看到的结果与机器证据开始收敛。

它不等于：

- Metal render target truth。
- Renderer / Scene truth。
- UI state truth。
- public runtime API truth。

### 4.3 Compositor / Display Presentation 的位置

证据链可以理解为：

```text
render intent
-> Metal command submitted
-> command buffer completed
-> render target readback summary
-> AppKit / CoreAnimation / compositor presentation
-> display / screen capture evidence
-> future hash / diff / review artifact
```

当前项目已经到达：

- command buffer completed 后的 smoke-only readback summary。

当前项目尚未到达：

- compositor / display presentation 后的用户可见窗口 evidence。

因此，下一条线如果开启，应该先证明 screenshot / window capture feasibility，而不是直接承诺完整视觉验证。

## 5. 是否现在直接实现 Screenshot

结论：

> 当前不应该直接实现 screenshot。

原因：

- 当前 screenshot 线牵涉外部桌面环境，不只是 GUI runtime 代码。
- 本机历史上已经出现过 `could not create image from display`，说明截图路径存在真实环境风险。
- 直接实现容易把权限、窗口可见性、焦点、Space、多显示器和 timing 噪音误判成 render failure。
- 当前没有 baseline image、hash 输入规范、diff 阈值或 artifact policy。
- 当前 smoke 还不是正式 runtime，不应为了验证而反向扩写 Renderer / Scene / Widget / Layout / DSL。

当前应该做的是：

- 先冻结用户可见窗口证据的边界。
- 如果继续推进，再开一张极窄 execution card，只做 screenshot feasibility probe。

## 6. Screenshot / Window Screenshot 风险

未来 screenshot 或 window screenshot 至少有这些风险：

- 屏幕录制权限：macOS 可能需要 Screen Recording / capture 权限；缺失时截图失败或返回空图。
- 窗口焦点 / frontmost app：目标窗口不在前台时，捕获结果可能被其他 app 覆盖。
- Space / Mission Control：窗口可能在其他 Space、Mission Control 状态或不可见 desktop 上。
- Retina scale：点坐标、像素坐标、backing scale、截图尺寸需要明确映射。
- 多显示器：窗口所在 display、坐标原点和 scale 可能不同。
- 窗口遮挡：其他窗口覆盖目标区域时，screen screenshot 会捕获遮挡结果。
- 动画 timing：窗口创建、激活、首次显示、compositor 呈现和自动关闭之间存在时序窗口。
- CI / headless：CI 可能没有真实 display server、权限会话或稳定窗口管理环境。
- 本机历史失败：此前自动截图曾出现 `could not create image from display`。

这些风险说明：

- screenshot 更接近用户可见结果。
- screenshot 也更容易把外部环境噪音带进 harness。
- 第一刀必须是 feasibility，不是 full verification。

## 7. 未来第一刀边界

如果未来要做用户可见窗口验证，第一刀应该是：

> screenshot feasibility probe

而不是：

- full screenshot verification。
- pixel diff。
- frame hash。
- offscreen renderer。
- 正式 GUI runtime visual test framework。

第一刀最多回答：

- 当前本机是否能在 smoke 运行期间请求一次窗口 / 屏幕截图。
- 是否能把失败原因分成 permission、window-not-visible、capture-failed 或 unknown。
- 是否能在不污染 runtime API 的情况下输出脱水 summary。
- 既有 auto-close / capability / metadata / Metal readback summary harness 是否仍可独立工作。

第一刀不能回答：

- 窗口像素颜色正确。
- 截图与 baseline 匹配。
- frame hash 稳定。
- pixel diff 通过。
- CI / headless 稳定。

## 8. 本轮允许与禁止

本轮允许：

- 新建本 preflight 文档。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

本轮不允许：

- 实现 screenshot。
- 实现 window screenshot。
- 读取屏幕像素。
- 保存 screenshot artifact。
- 实现 pixel diff。
- 实现 frame hash。
- 实现 offscreen renderer。
- 修改 `labs/macos_bridge_smoke`。
- 修改 `verify_auto_close.sh`。
- 新增 public C ABI / runtime API。
- 设计 Renderer / Scene。
- 设计 Widget / Layout / DSL。
- 做跨平台抽象。
- 做文本、输入法、无障碍。
- 做 AI semantic tree / Action Router。
- 把当前 smoke demo 宣称为正式 runtime。

因此，本轮对下面问题的答案都是“不允许”：

- 是否允许保存 screenshot artifact：不允许。
- 是否允许做 pixel diff：不允许。
- 是否允许做 frame hash：不允许。
- 是否允许做 offscreen renderer：不允许。
- 是否允许修改 `labs/macos_bridge_smoke`：不允许。
- 是否允许修改 `verify_auto_close.sh`：不允许。

## 9. 未来 Screenshot Feasibility Execution Card 的最大 Write Set

如果未来用户明确开启 `P1 user-visible window screenshot feasibility execution card`，建议最大 write set 仍然非常窄：

- 新建或修改一个独立 screenshot feasibility harness：
  - 建议路径：`labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- 轻量更新：
  - `labs/macos_bridge_smoke/README.md`
- 新建 future closure review：
  - `docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md`
- 更新：
  - [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
  - [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

默认不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- 正式 runtime 目录。
- public GUI API。
- Renderer / Scene / Widget / Layout / DSL。

如果未来 feasibility 发现必须改 bridge 代码、build script 或 Cangjie 入口，必须暂停并另开 execution card。

## 10. 未来 Harness 最多能断言什么

未来 screenshot feasibility harness 最多断言：

- smoke process 可以启动。
- 已出现现有 readiness 日志，例如 `window created`、`metal setup complete`、`first frame rendered`。
- 截图请求被发起。
- 截图 API / 命令返回了可分类结果。
- 如果成功，只记录脱水 summary，例如 `screenshot_probe_succeeded=true`、`window_bounds_observed=true`、`image_created=true`。
- 如果失败，只记录分类 reason，例如 `permission_denied`、`window_not_visible`、`capture_failed`、`display_unavailable`、`unknown`。

未来 harness 不应断言：

- 像素颜色正确。
- screenshot 与 baseline 一致。
- frame hash 一致。
- pixel diff 通过。
- CI / headless 可用。
- 用户可见窗口在所有环境中稳定可验证。

未来第一刀默认不应保存 screenshot artifact。

如果某个 execution card 认为必须保存临时 artifact 才能证明 feasibility，必须单独写入该卡，并限定：

- 仅临时路径。
- 不提交 artifact。
- 不建立 baseline。
- 不做 pixel diff。
- closure review 记录 artifact 生命周期和删除 / 保留策略。

## 11. 失败分类

未来要避免把所有失败都写成 render failure。

建议分类：

- `permission_denied`：截图 API 明确因权限失败，或返回符合权限缺失特征的错误。
- `display_unavailable`：没有可用 display，或出现类似 `could not create image from display` 的环境错误。
- `window_not_found`：无法找到 smoke window 或窗口标识。
- `window_not_visible`：窗口存在但不可见、最小化、隐藏、切到其他 Space，或无法获得可见区域。
- `capture_failed`：权限和窗口都看似满足，但截图 API 返回 nil / empty / command failure。
- `render_not_ready`：现有日志未到 `first frame rendered` 或 readiness 前置条件未满足。
- `render_failure`：只有在 render readiness 明确失败、且与截图环境无关时才使用。
- `unknown`：证据不足，不能伪装成上述任一原因。

分类原则：

- screenshot failure 不等于 render failure。
- permission failure 不等于 window-not-visible failure。
- window-not-visible failure 不等于 Metal render target failure。
- 只有证据链能支撑时，才允许写更具体原因。

## 12. 防止污染 Runtime 设计

用户可见窗口验证不得反向污染 Renderer / Scene / Widget / Layout / DSL。

规则：

- screenshot harness 只能是 verification harness，不是 runtime API。
- screenshot evidence 只能是外部 evidence，不是 UI state truth。
- 不把 screenshot 坐标、window bounds、display id 写成 public widget contract。
- 不为了截图方便而调整正式 render pipeline。
- 不为了 screenshot 引入跨平台 backend。
- 不为了 screenshot 设计 Renderer / Scene。
- 不为了截图验证提前定义 baseline / diff / artifact 系统。
- 不让 smoke 的窗口标题、尺寸、日志格式变成正式 runtime contract。

## 13. 如何保持 Smoke 不升级成正式 Runtime

规则：

- 始终称为 `labs/macos_bridge_smoke`。
- 始终称为 smoke demo、smoke diagnostics 或 verification harness。
- 不把 smoke API、日志字段、截图策略写成 public runtime API。
- 不让 smoke 的 screenshot / readback evidence 定义 future Renderer / Scene truth。
- 每个 execution card 都必须限定 write set、验证证据和 stop-line。
- 每个 closure review 都必须说明“这不是正式 GUI runtime”。

## 14. 当前 Stop-Line

本轮强制 stop-line：

- 不实现 screenshot。
- 不实现 window screenshot。
- 不读取屏幕像素。
- 不保存 screenshot artifact。
- 不实现 pixel diff。
- 不实现 frame hash。
- 不实现 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 `verify_auto_close.sh`。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本、输入法、无障碍。
- 不做 AI semantic tree / Action Router。
- 不把当前 smoke demo 宣称为正式 runtime。

## 15. 结论

本轮结论：

- 当前 Metal readback summary 已经证明 smoke bridge 内部受控 Metal render target 的 single-frame clear-color sample 可以在 command buffer completion 后被读到并降为 summary。
- 当前 Metal readback summary 仍不能证明用户可见窗口、compositor / display presentation、window screenshot 或 CI / headless 稳定性。
- 用户可见窗口验证与 Metal render target readback 是两条不同 truth：前者是 OS / compositor 之后的 evidence，后者是 GPU render target evidence。
- 当前不应直接实现 screenshot。
- 如果继续推进，应先创建 docs-only execution card，最大边界为 screenshot feasibility probe，而不是 full verification。

下一步推荐 opening：

- `P1 user-visible window screenshot feasibility execution card`

该 opening 仍然不自动开启实现。

未来 execution card 必须继续禁止：

- pixel diff。
- frame hash。
- offscreen renderer。
- public C ABI / runtime API。
- Renderer / Scene / Widget / Layout / DSL。
- 把 smoke demo 宣称为正式 runtime。
