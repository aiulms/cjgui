# P1 User-Visible Window Screenshot Verification Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization

状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行

范围：只授权未来一个极窄 first slice，在独立 verification harness 中，基于当前 `labs/macos_bridge_smoke` 运行期间的用户可见窗口截图，保存一个临时 screenshot artifact，确认截图目标归属，并做极窄 clear-color sample summary。

本卡不授权 full GUI verification、pixel diff、frame hash、baseline、offscreen renderer、Renderer / Scene、Widget / Layout / DSL 或 public runtime API。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 确认依据：
  - [2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 只能使用当前 smoke、shell harness、macOS 最小截图 / 窗口枚举能力和临时 artifact。
- 上层尽量仓颉原生：是。不得新增 public C ABI / runtime API，也不得让仓颉层持有 screenshot、window、display 或 platform object。
- 底层只保留必要平台桥接：是。截图验证只能作为外部 verification harness，不是 runtime capability。
- 没有过早抽象跨平台：是。本卡只覆盖当前 macOS smoke，不定义跨平台 screenshot contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现必须修改 bridge、扩大 artifact 生命周期、读取整图像素、建立 baseline、做 pixel diff / frame hash、设计 Renderer / Scene、或新增 public API，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md)

背景约束：

- [2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)
- [2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md)
- [2026-04-25-p1-user-visible-window-verification-evidence-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-verification-evidence-preflight.md)
- [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [2026-04-25-p1-metal-readback-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-execution-card.md)
- [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)
- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡扩展成：

- full GUI verification framework。
- pixel diff。
- frame hash。
- offscreen renderer。
- public C ABI / runtime API。
- Renderer / Scene。
- Widget / Layout / DSL。
- 跨平台 screenshot abstraction。

## 2. Why A First Slice, Not Full GUI Verification

本卡只能授权 screenshot verification first slice，而不是 full GUI verification，原因是：

- 当前 smoke 没有正式 Renderer / Scene / Widget / Layout。
- 当前 screenshot feasibility 只证明能创建 on-screen image object，不证明 image content 属于目标窗口。
- 当前没有 baseline owner、diff 阈值、frame hash 输入规则、颜色空间策略或 CI / headless 策略。
- 当前窗口遮挡、frontmost app、Space / Mission Control、Retina scale、多显示器和 timing 仍可能影响 screenshot evidence。
- 当前 smoke demo 不是正式 runtime，不能为了验证反向设计 public UI / Renderer / Scene API。

因此未来 first slice 只允许回答：

- 截图 artifact 是否可临时保存并被 closure review 复核。
- artifact 是否可以被归属到目标 smoke window。
- 目标窗口安全 interior 的极窄 clear-color sample 是否与当前 smoke expected clear color 接近。

它不能回答：

- 整图视觉正确。
- 所有像素正确。
- 多窗口、多场景、多帧稳定。
- pixel diff 通过。
- frame hash 通过。
- CI / headless 稳定。
- Renderer / Scene / Widget / Layout 正确。

## 3. Truth Boundary

screenshot verification 不能替代 Metal readback truth。

Metal readback truth 是：

- command buffer completion 之后，受控 Metal render target 的 sample / summary。

screenshot verification truth 是：

- OS / compositor / display presentation 之后，外部截图路径拿到的用户可见 image evidence。

两者关系：

- Metal readback 更接近 GPU render target。
- screenshot verification 更接近用户最终看到的窗口。
- screenshot sample 成功不能证明 Metal render target readback 语义。
- Metal readback 成功不能证明用户可见窗口内容、遮挡、Space 或 display presentation。
- 两者都不是 Renderer / Scene truth，也都不是 UI state truth。
- 两者都不能成为 public runtime API。

本卡只授权外部 harness 收集 screenshot evidence 并做极窄 sample，不授权把 screenshot 结果解释为正式视觉正确性。

## 4. Goal

未来 first slice 的唯一目标：

- 在当前本机运行 `labs/macos_bridge_smoke` 期间，用独立 verification harness 保存一个临时 screenshot artifact，确认 artifact 目标区域来自 smoke window，并在该区域内做极窄 clear-color sample summary。

未来 first slice 只验证：

- smoke process 可以启动。
- readiness 日志出现：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- screenshot capture request 被发起。
- 临时 screenshot artifact 被写入受控临时路径。
- 目标 smoke window 可以通过脱水 process id / title / bounds 等 diagnostics 被归属。
- 目标窗口 bounds 能映射到 screenshot pixel coordinates。
- 一个或少量安全 interior clear-color sample 与 expected clear color 接近。
- harness 输出脱水 success / failure classification summary。

未来 first slice 不验证：

- 整图视觉正确。
- pixel diff。
- frame hash。
- baseline。
- offscreen renderer。
- CI / headless。
- Renderer / Scene / Widget / Layout。
- 正式 GUI runtime 行为。

## 5. Future Write Set

未来 implementation 最多允许修改：

- 可选复用 / 扩展：
  - `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
  - 只能在 execution card 明确批准下，将其极窄扩展为 screenshot verification first slice。
- 推荐新增独立 verification harness：
  - `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
- 轻量更新：
  - [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- future closure review：
  - `docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md`
- 更新：
  - [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
  - [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未来 implementation 默认不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `README.md`
- 正式 runtime 目录。
- public GUI API。
- Renderer / Scene / Widget / Layout / DSL。
- 跨平台 backend。
- 文本、输入法、无障碍相关实现。
- AI semantic tree / Action Router 相关实现。

明确回答：

- 是否允许修改 `cjgui_macos.m`：默认不允许。
- 是否允许修改 `verify_auto_close.sh`：默认不允许。
- 是否允许复用或扩展 `verify_user_visible_window_screenshot_feasibility.sh`：可以，但只允许在未来 implementation 中把现有 feasibility probe 极窄扩成 verification first slice；不得改变 auto-close harness，不得新增 runtime API，不得扩大到 pixel diff / frame hash。
- 是否允许新增独立 verification harness：可以，推荐路径为 `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`。

如果未来发现必须修改 bridge、build script 或 Cangjie 入口才能定位窗口或采样，必须暂停并另开 execution card。

## 6. Artifact Policy

未来 first slice 允许保存一个临时 screenshot artifact，但必须严格限制。

默认路径：

- 使用 `mktemp -d /tmp/cjgui-p1-screenshot-verification.XXXXXX` 创建临时目录。
- artifact 文件名可以是：
  - `target-window.png`
  - 或 `screenshot.png`
- 不允许写到仓库目录。
- 不允许写到用户桌面、下载目录或长期缓存目录。

生命周期：

- 成功时默认删除 artifact 和临时目录。
- 失败时可以保留 artifact 供人工排查，但 closure review 必须记录：
  - artifact 路径。
  - 保留原因。
  - failure classification。
  - 是否包含目标窗口。
  - 后续删除策略。
  - 是否已确认不会提交到仓库。
- 若成功但为了 closure review 需要保留 artifact，必须在 implementation 输出中明确说明，并仍然不得提交。

提交 / baseline：

- 是否允许提交 artifact：不允许。
- 是否允许建立 baseline：不允许。
- 是否允许作为 golden image：不允许。
- 是否允许生成 artifact 序列：不允许。

本卡创建轮次：

- 本轮不保存 screenshot artifact。
- 本轮不创建临时目录。
- 本轮不读取或比较像素。

## 7. Pixel Read / Compare Policy

未来 first slice 允许读取像素，但只能读取极窄 clear-color sample。

允许：

- 读取目标 smoke window bounds 内的安全 interior 单点 sample。
- 或读取小区域 sample，例如中心附近 `3x3` 或少量固定点。
- 比较当前 smoke expected clear color。
- 输出脱水 summary：
  - `sample_requested=true`
  - `sample_match=true|false`
  - `sample_points=<small-count>`
  - `reason=none|color_mismatch|unknown`

限制：

- sample 只能服务当前 smoke clear-color verification。
- 必须记录颜色空间、alpha、scale 或坐标转换的不确定性。
- sample mismatch 若可能来自遮挡、Space、frontmost、scale 或 timing，不能写成 render failure。

不允许：

- 读取整图像素。
- 输出 raw bytes。
- 输出整图像素数组。
- 保存 raw screen pixels。
- 做 pixel diff。
- 做 frame hash。
- 做 baseline comparison。
- 做通用 UI pixel verification。
- 验证文本、控件、layout、anti-aliasing 或复杂视觉结构。

本卡创建轮次：

- 本轮不读取像素。
- 本轮不比较像素颜色。

## 8. Pixel Diff / Frame Hash / Offscreen Renderer

pixel diff：

- 不允许。
- 原因是当前没有 baseline owner、diff 阈值、颜色空间、Retina scale、多显示器、遮挡和 CI 策略。

frame hash：

- 不允许。
- 原因是 hash 需要稳定 source image、裁剪范围、row stride、pixel format、颜色空间和 scale 规则。

offscreen renderer：

- 不允许。
- 原因是 offscreen renderer 会要求 render target owner、render command、resource lifecycle，并会提前打开 Renderer / Scene。

这些能力必须另开 preflight / execution card。

## 9. Target Window Attribution

未来 first slice 必须确认截图内容来自目标 smoke window，而不是其他窗口或桌面。

允许的归属策略：

- harness 启动 smoke 后记录 smoke process id。
- 使用系统窗口枚举信息寻找 owner process id 匹配的窗口。
- 可结合 window title、owner name 或 window layer 做辅助匹配。
- 记录脱水 bounds：
  - `x`
  - `y`
  - `width`
  - `height`
- 记录 display / scale 相关脱水信息。
- 在截图中只检查目标 bounds 的安全 interior sample。

允许记录的 diagnostics：

- `target_pid_observed=true|false`
- `window_title_matched=true|false|unknown`
- `window_bounds_observed=true|false`
- `frontmost_app_matched=true|false|unknown`
- `display_observed=true|false|unknown`
- `scale_observed=true|false|unknown`
- `capture_covers_target_bounds=true|false|unknown`

这些 diagnostics 只属于 harness projection。

不允许：

- 将 process id / title / bounds / frontmost app / display / scale 写入 public runtime API。
- 将这些信息作为 Widget / Scene / Renderer contract。
- 将 `CGWindowID` 作为长期 public identity。
- 输出或暴露 `NSWindow*`、`NSView*`、`NSScreen*`、`CGImageRef`、Objective-C `id` 或任何平台对象裸指针。

如果无法确认目标归属：

- 不允许继续伪称 screenshot verification 成功。
- 应分类为 `window_not_found`、`window_not_visible`、`target_mismatch`、`capture_failed` 或 `unknown`，具体分类必须由实现卡内规则决定。

## 10. Platform Risk Handling

窗口遮挡：

- 如果能判断更高层窗口覆盖目标 bounds，应分类为 `window_occluded` 或 `window_not_visible`。
- 如果不能判断遮挡，不能伪称无遮挡。
- sample mismatch 若可能由遮挡造成，不能写成 render failure。

Space / Mission Control：

- 目标窗口不在当前 Space、Mission Control 介入、窗口隐藏或最小化，都应视为可见性问题。
- 不允许 harness 为了通过验证自动切换 Space 或操纵用户桌面状态，除非另开 execution card。

frontmost app：

- 可记录 frontmost app 是否为 smoke 进程。
- 非 frontmost 不必自动失败。
- 如果非 frontmost 导致 target bounds 被遮挡或不可确认，应归为可见性 / 环境失败。

Retina scale：

- 必须区分 point bounds 和 pixel bounds。
- sample 坐标必须从目标窗口 bounds、screenshot size 和 scale 假设推导。
- scale 不确定时，应降级为 `capture_failed` 或 `unknown`，不能伪称 pixel incorrect。

多显示器：

- 必须记录目标窗口 display 是否可观察。
- 多显示器坐标原点、scale 和 screenshot bounds 可能不同。
- 如果无法确认 capture 覆盖目标 display，应分类为 `display_unavailable`、`window_not_visible` 或 `unknown`。

timing：

- 必须等待 readiness 日志后再截图。
- 必须给窗口呈现留出受控延迟或轮询可见状态。
- 自动关闭时间必须足够长，不能让 screenshot probe 与窗口销毁竞争。
- timing 失败不能写成 render failure，除非日志明确证明 render readiness 失败且与截图环境无关。

Screen Recording 权限：

- 权限失败必须归类为 `permission_denied`。
- 不允许 runtime 申请或管理权限。
- 不允许把权限失败写成 render failure。
- closure review 必须记录错误文本或系统返回证据。

历史错误：

- `could not create image from display` 默认归类为 `display_unavailable`。
- 只有在能证明它由权限导致时，才可归类为 `permission_denied`。

CI / headless：

- 当前不承诺 CI / headless 可复核。
- 如果没有真实 display session，应分类为 `display_unavailable` 或 `unknown`。
- 不允许为了 CI 提前引入 offscreen renderer。
- 不允许为了 CI 设计跨平台 screenshot abstraction。

## 11. Failure Classification

未来 implementation 至少应沿用这些分类：

- `permission_denied`
- `display_unavailable`
- `window_not_found`
- `window_not_visible`
- `capture_failed`
- `render_not_ready`
- `render_failure`
- `unknown`

未来 first slice 可新增以下 harness-only 分类：

- `window_occluded`
- `target_mismatch`
- `color_mismatch`

新增分类仍然只是 harness diagnostics，不得进入 public runtime API。

分类原则：

- screenshot failure 不等于 render failure。
- permission failure 不等于 render failure。
- target mismatch 不等于 render failure。
- window-not-visible 不等于 Metal readback failure。
- color mismatch 只有在目标窗口归属、bounds、scale、visibility 和 capture 都成立后才可使用。
- render failure 只有在 readiness 或 render 日志明确失败，且与权限、display、visibility、capture API、timing 无关时才允许。

## 12. Harness Output Boundary

未来 harness 可以输出脱水 summary，例如：

```text
cjgui screenshot verification: requested=true
cjgui screenshot verification: artifact_created=true
cjgui screenshot verification: target_pid_observed=true
cjgui screenshot verification: window_bounds_observed=true
cjgui screenshot verification: capture_covers_target_bounds=true
cjgui screenshot verification: sample_requested=true
cjgui screenshot verification: sample_match=true
cjgui screenshot verification: success=true reason=none
```

失败时可以输出：

```text
cjgui screenshot verification: requested=true
cjgui screenshot verification: success=false reason=permission_denied
```

不允许输出：

- raw pixel bytes。
- full pixel dump。
- base64 image。
- screenshot binary data。
- frame hash。
- pixel diff result。
- platform object pointer。
- native handle。
- stable public window id。

## 13. Future Verification Plan

未来 implementation first slice 至少要验证：

- 新 harness shell 语法检查。
- 新 harness 在当前本机运行一次。
- readiness needle 是否出现：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- screenshot request 是否发起。
- 临时 artifact 是否按策略创建。
- 目标窗口 attribution diagnostics 是否输出。
- 极窄 clear-color sample summary 是否输出。
- 成功或失败 classification 是否来自允许分类。
- smoke lifecycle 是否仍完成：
  - `cjgui: destroy complete`
  - `cjgui: event loop exited`
  - `Cangjie: cjgui_app_run returned 0`
- `verify_auto_close.sh` 未被修改且仍可独立运行。
- forbidden files 未修改。
- closure review 可从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。

允许的成功形态：

- `success=true reason=none`，且 artifact / target attribution / sample summary 均有脱水证据。

允许的失败形态：

- `success=false reason=<classification>`，其中 classification 必须来自本卡允许列表。

失败不是 implementation failure 的充分条件。

如果本机因为权限、display、visibility 或 timing 失败，closure review 可以接受失败分类本身作为 evidence，但必须诚实说明未获得完整 screenshot verification。

## 14. Future Closure Review Requirements

未来 closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 是否复用 / 扩展 feasibility harness。
- 是否新增独立 verification harness。
- screenshot capture 使用的机制 / 命令 / API。
- 目标窗口 attribution 使用的机制 / 命令 / API。
- 实际命令。
- 日志路径。
- 临时 artifact 路径。
- artifact 生命周期：
  - 成功时是否删除。
  - 失败时是否保留。
  - 若保留，删除策略是什么。
- artifact 是否提交：必须为否。
- artifact 是否进入 baseline：必须为否。
- readiness needle 是否出现。
- screenshot request 是否发起。
- target pid / title / bounds / frontmost app / display / scale diagnostics 是否输出。
- sample 位置选择和 sample 范围。
- 是否只做极窄 clear-color sample。
- 是否读取整图像素：必须为否。
- 是否输出 raw bytes：必须为否。
- 是否做 pixel diff：必须为否。
- 是否做 frame hash：必须为否。
- 是否做 offscreen renderer：必须为否。
- 是否新增 public C ABI / runtime API：必须为否。
- 是否暴露平台对象：必须为否。
- 是否把 screenshot failure 写成 render failure：必须为否，除非有明确 render 日志证据。
- 是否把 smoke demo 宣称为正式 runtime：必须为否。

closure review 还必须明确：

- 这只是 screenshot verification first slice。
- 这不是 full GUI verification。
- 这不是 pixel diff。
- 这不是 frame hash。
- 这不是 offscreen renderer。
- 这不是 CI / headless proof。
- 这不是 Renderer / Scene / Widget / Layout 设计。
- 这不是正式 GUI runtime。

## 15. Runtime Pollution Guard

为了避免 screenshot verification 反向污染 Renderer / Scene / Widget / Layout / DSL：

- screenshot verification 只能是 verification harness。
- screenshot artifact 只能是外部 evidence。
- process id / title / bounds / frontmost app / display / scale 只能是 harness diagnostics。
- 不把截图坐标、display id、window id、bounds 写成 public widget contract。
- 不为了截图便利修改正式 render pipeline。
- 不为了截图便利设计 Renderer / Scene。
- 不为了截图便利设计 Widget / Layout / DSL。
- 不为了截图便利引入跨平台 backend。
- 不为了截图便利改变 bridge lifecycle。
- 不为了截图便利新增 public C ABI / runtime API。

为了避免 smoke demo 被升级成正式 runtime：

- 始终称为 `labs/macos_bridge_smoke`。
- 始终称为 smoke demo、smoke diagnostics 或 verification harness。
- 不把 smoke 日志字段、window title、bounds、截图策略写成 public runtime contract。
- 不把 artifact policy 写成框架承诺。
- 每个后续实现必须有 execution card 和 closure review。
- closure review 必须说明“这不是正式 GUI runtime”。

## 16. Stop-Line

本轮创建 execution card 的强制 stop-line：

- 本轮不实现 screenshot verification。
- 本轮不保存 screenshot artifact。
- 本轮不读取或比较像素。
- 本轮不实现 pixel diff。
- 本轮不实现 frame hash。
- 本轮不实现 offscreen renderer。
- 本轮不修改 `labs/macos_bridge_smoke`。
- 本轮不修改 `verify_user_visible_window_screenshot_feasibility.sh`。
- 本轮不修改 `verify_auto_close.sh`。
- 本轮不修改 `cjgui_macos.m`。
- 本轮不新增 public C ABI / runtime API。
- 本轮不设计 Renderer / Scene。
- 本轮不设计 Widget / Layout / DSL。
- 本轮不做跨平台抽象。
- 本轮不做文本、输入法、无障碍。
- 本轮不做 AI semantic tree / Action Router。
- 本轮不把当前 smoke demo 宣称为正式 runtime。

未来 implementation first slice 的 stop-line：

- 只做 screenshot verification first slice。
- 只允许临时 screenshot artifact。
- 只允许目标窗口 attribution。
- 只允许极窄 clear-color sample summary。
- 不允许提交 artifact。
- 不允许建立 baseline。
- 不允许读取整图像素或输出 raw bytes。
- 不允许 pixel diff。
- 不允许 frame hash。
- 不允许 offscreen renderer。
- 不允许 public C ABI / runtime API。
- 不允许 Renderer / Scene / Widget / Layout / DSL。
- 不允许把 screenshot verification 宣称为完整视觉验证。

## 17. Next Opening

本卡创建后，不自动执行实现。

如果用户明确继续推进，下一条 bounded implementation opening 是：

- `P1 user-visible window screenshot verification bounded implementation first slice`

该 opening 只能按本卡执行：

- 最多新增独立 verification harness，或受控扩展现有 screenshot feasibility harness。
- 最多保存一个临时 screenshot artifact。
- 最多做目标窗口 attribution 和极窄 clear-color sample summary。
- 完成后必须创建 closure review。

除非另开 preflight / execution card，否则不得进入 full GUI verification、pixel diff、frame hash、baseline、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、跨平台抽象或正式 runtime API。
