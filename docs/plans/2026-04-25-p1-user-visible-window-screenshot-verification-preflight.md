# P1 User-Visible Window Screenshot Verification Preflight

日期：2026-04-25

性质：docs-only / screenshot verification preflight / P1 runtime foundation

状态：完成；不批准直接实现

范围：冻结是否应该从 screenshot feasibility 进入真正 screenshot verification。本轮不实现 screenshot verification，不保存 screenshot artifact，不读取或比较像素，不实现 pixel diff / frame hash / offscreen renderer。

## 1. 背景

当前已经完成：

- [P1 automated GUI verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [P1 frame metadata / render stats first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [P1 Metal readback feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [P1 user-visible window screenshot feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)

当前已有 evidence：

- lifecycle / capability / auto-close 日志 harness。
- 脱水 frame metadata / render stats。
- smoke-only、single-frame、clear-color Metal readback summary。
- 当前本机可以请求一次 CoreGraphics on-screen image object，并得到 `success=true reason=none`。

当前仍没有 evidence：

- screenshot 内容是否包含目标 smoke window。
- 用户可见窗口像素颜色是否正确。
- 窗口是否无遮挡。
- compositor / display presentation 是否正确。
- CI / headless 是否可复核。
- screenshot artifact / baseline / pixel diff / frame hash。

本 preflight 只冻结下一步是否进入 screenshot verification，以及若进入应如何切到最窄。

## 2. Feasibility 已经证明什么

`P1 user-visible window screenshot feasibility first slice` 已证明：

- 独立 harness 可以启动现有 `labs/macos_bridge_smoke`。
- harness 可以等待 readiness 日志：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- readiness 达成后，当前本机可以请求一次 CoreGraphics on-screen image feasibility probe。
- probe 能返回非空 image object。
- harness 可以输出脱水 summary：
  - `requested=true`
  - `image_created=true`
  - `success=true reason=none`
- smoke 仍能自动关闭并返回 `0`。

这属于：

- screenshot path feasibility evidence。
- 当前本机桌面会话 evidence。
- harness-level evidence。

它不是：

- full screenshot verification。
- pixel correctness proof。
- compositor correctness proof。
- CI / headless proof。
- public runtime capability。

## 3. Feasibility 仍不能证明什么

feasibility first slice 仍不能证明：

- image object 内容包含目标 smoke window。
- 目标窗口没有被其他窗口遮挡。
- 目标窗口位于当前 Space 且用户可见。
- 目标窗口是 frontmost / key window。
- 截图区域坐标与目标窗口 bounds 正确匹配。
- Retina scale、多显示器和坐标转换正确。
- 目标窗口像素颜色符合 expected clear color。
- screenshot artifact 可保存、可复核、可作为 baseline。
- pixel diff 或 frame hash 稳定。
- CI / headless 环境可复核。

关键边界：

> `image_created=true` 只说明截图路径能创建图像对象，不说明图像内容正确。

## 4. Screenshot Verification 与 Feasibility 的 Truth 区别

screenshot feasibility 的 truth 是：

- 截图 API / 命令是否能被请求。
- 是否能创建非空 image object。
- 如果失败，失败原因能否分类。

screenshot verification 的 truth 是：

- OS / compositor 之后的截图 evidence 是否能被归属到目标 smoke window。
- 截图中的目标区域是否能被机器检查为符合当前 smoke 的最小视觉预期。

二者不能互相冒充：

- feasibility 成功不等于内容正确。
- screenshot verification 失败不一定是 render failure。
- screenshot truth 不等于 Metal readback truth。
- screenshot truth 不等于 Renderer / Scene / UI state truth。

当前证据链位置：

```text
render intent
-> Metal command submitted
-> command buffer completed
-> Metal readback summary
-> AppKit / CoreAnimation / compositor presentation
-> CoreGraphics screenshot image object
-> future target-window verification
-> future pixel diff / frame hash
```

当前项目已经到达 CoreGraphics image object feasibility。
下一步若继续，只能验证这个 image object 是否可以被安全地归属和极窄采样。

## 5. 如果进入 Screenshot Verification，最小 Target 是什么

未来第一张 execution card 的最小 verification target 应该是：

> 在当前本机运行 `labs/macos_bridge_smoke` 期间，确认一次截图 artifact 的目标区域来自 smoke window，并在该目标区域内做极窄 clear-color sample，输出脱水 summary。

最小 target 只允许回答：

- smoke window 是否能被外部 harness 以 process id / title / bounds 归属。
- screenshot capture 是否覆盖目标窗口 bounds。
- 目标窗口是否处于可见状态，至少没有明显被判定为隐藏、最小化或完全不可见。
- 在目标窗口安全 interior 区域内，一个或少量 clear-color sample 是否接近 expected clear color。

最小 target 不允许回答：

- 整图视觉正确。
- 所有像素正确。
- 多窗口、多场景、多帧稳定。
- pixel diff 通过。
- frame hash 通过。
- CI / headless 稳定。
- Renderer / Scene / Widget / Layout 正确。

## 6. Screenshot Artifact Policy

如果进入真正 screenshot verification，建议允许保存临时 screenshot artifact，但必须极窄限制。

原因：

- 不保存 artifact 时，无法确认 image object 的内容是否包含目标 smoke window。
- 不保存 artifact 时，无法为 closure review 提供可复核的截图来源和失败证据。
- artifact 是 screenshot verification 的输入 evidence，不是 runtime API，也不是 baseline。

未来 execution card 若允许 artifact，必须同时限制：

- 路径：只允许写入 `/tmp/cjgui-p1-screenshot-verification-*` 或 `mktemp -d` 创建的临时目录。
- 生命周期：默认成功后删除；失败时可以保留临时路径供人工排查，但 closure review 必须记录路径和删除策略。
- 提交规则：不得提交到仓库。
- baseline 规则：不得进入 baseline，不得作为 golden image。
- 命名规则：必须带 `smoke` / `verification` / timestamp 或随机后缀，避免覆盖用户文件。
- 内容范围：只保存当前 probe 必需的一张截图或裁剪图；不得批量保存帧序列。
- 访问范围：只由 verification harness 使用，不暴露给仓颉 runtime。

本轮结论：

- 本 preflight 不保存 artifact。
- 未来第一张 execution card 可以授权临时 artifact，但必须写清路径、保留条件、删除策略和“不得提交 / 不得 baseline”。

## 7. Pixel Read / Compare Policy

如果进入 screenshot verification，建议允许读取像素，但只能限于极窄 sample。

允许的最小读取范围：

- 首选：目标窗口 interior 的单点 sample。
- 可选：目标窗口 interior 的小区域 sample，例如中心附近 `3x3` 或少量固定点。
- 默认不允许：整图扫描。
- 默认不允许：读取整张 screenshot bytes 并输出。

允许的最小比较：

- 只比较当前 smoke 的 expected clear color sample。
- 必须使用小容忍度，并记录颜色空间 / alpha / scale 的不确定性。
- 输出只能是脱水 summary，例如 `sample_match=true`、`reason=none` 或 `reason=color_mismatch`。
- 不输出 raw pixel bytes。
- 不输出整图像素数组。

不允许：

- 通用 UI pixel verification。
- 复杂区域 diff。
- baseline comparison。
- anti-aliasing 策略。
- 文本 / 控件 / layout 视觉判断。

本轮结论：

- 本 preflight 不读取像素。
- 未来第一张 execution card 可以授权极窄 clear-color sample。
- 任何超出单点 / 小区域 sample 的读取都必须另开 preflight。

## 8. Pixel Diff / Frame Hash / Offscreen Renderer

pixel diff：

- 本轮不允许。
- 未来第一张 screenshot verification execution card 也不应允许。
- 原因是当前没有稳定 baseline owner、diff 阈值、颜色空间、Retina scale、多显示器和遮挡策略。

frame hash：

- 本轮不允许。
- 未来第一张 screenshot verification execution card 也不应允许。
- 原因是 hash 需要稳定 source image、裁剪范围、row stride、pixel format、颜色空间和 scale 规则。

offscreen renderer：

- 不允许。
- 原因是 offscreen renderer 会要求定义 render target owner、render command、resource lifecycle，并很可能提前打开 Renderer / Scene 设计。

结论：

- 下一步如果继续，只能是 screenshot verification first slice。
- pixel diff、frame hash 和 offscreen renderer 继续延后，必须单独 preflight / execution card。

## 9. Write Set Boundary

本轮不允许修改 `labs/macos_bridge_smoke`。

如果未来创建 `P1 user-visible window screenshot verification execution card`，默认允许的最大 write set 应比 feasibility 稍宽，但仍只限 verification harness：

- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
  - 仅允许受控扩展为 screenshot verification first slice，或拆出新的独立 verification harness。
- 可选新增：
  - `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
- `labs/macos_bridge_smoke/README.md`
  - 只记录验证命令、artifact 边界、sample 边界和非正式 runtime 说明。
- future closure review。
- `docs/plans/README.md`。
- `GUI_TASK_TRACKER.md`。

默认不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- 正式 runtime 目录。
- public GUI API。
- Renderer / Scene / Widget / Layout / DSL。

明确回答：

- 是否允许修改 `cjgui_macos.m`：默认不允许。
- 是否允许修改 `verify_auto_close.sh`：默认不允许。
- 是否允许修改现有 screenshot feasibility harness：未来可以，但只能在 execution card 明确授权下，把它极窄扩展为 screenshot verification harness；不得改变现有 auto-close harness，也不得新增 runtime API。

如果未来发现必须修改 bridge 代码才能定位窗口，必须暂停并另开 execution card。

## 10. Target Window Identity

真正 screenshot verification 必须确认截图内容来自目标 smoke window，而不是其他窗口或桌面。

建议第一刀使用外部 harness 侧信息，不改 runtime：

- harness 启动 smoke 后记录 smoke process id。
- 使用系统窗口枚举信息寻找 owner process id 匹配的窗口。
- 可结合窗口 title 或 owner name 作为辅助匹配。
- 记录脱水 bounds：`x`、`y`、`width`、`height`。
- 记录 display / scale 相关的脱水信息。
- 在截图中只检查该 bounds 内的安全 interior sample。

是否需要 window bounds / title / process id / frontmost app 信息：

- 需要，但只作为 verification harness diagnostics。
- `process id` 用于归属目标进程。
- `title` / owner name 用于降低误匹配风险。
- `bounds` 用于定位截图内的目标区域。
- `frontmost app` 可作为环境诊断，不应成为 runtime contract。

这些信息不允许：

- 进入 public runtime API。
- 作为 Widget / Scene / Renderer contract。
- 以平台对象或 native handle 形式暴露。
- 写成跨平台抽象。

允许输出的只能是脱水值，例如：

- `target_pid_observed=true`
- `window_bounds_observed=true`
- `window_title_matched=true`
- `frontmost_app_matched=true|false|unknown`

不得输出：

- `NSWindow*`
- `CGWindowID` 作为长期 public identity。
- `CGImageRef`
- `NSScreen*`
- 任何 Objective-C `id` 或平台对象裸指针。

## 11. Occlusion / Visibility / Timing

窗口遮挡：

- 如果能通过窗口列表判断更高层窗口覆盖目标 bounds，应分类为 `window_not_visible` 或 `window_occluded`，但第一张 execution card 必须先定义具体分类名。
- 如果不能判断遮挡，不能伪称无遮挡。
- sample mismatch 若可能由遮挡导致，不能直接写成 render failure。

Retina scale：

- harness 必须区分 point bounds 和 pixel bounds。
- sample 坐标必须从目标窗口 bounds 和截图尺寸推导，并记录 scale 假设。
- scale 不确定时，结果应降级为 `capture_failed` 或 `unknown`，不能伪称 pixel incorrect。

多显示器：

- harness 必须记录目标窗口所在 display 或至少记录 display 归属是否已观察。
- 多显示器坐标原点和 scale 可能不同。
- 如果无法确认 capture 覆盖目标 display，应分类为 `display_unavailable`、`window_not_visible` 或 `unknown`。

Space / Mission Control：

- 目标窗口不在当前 Space、Mission Control 介入、窗口隐藏或最小化，都应视为可见性问题。
- 不允许 harness 为了通过验证自动切换 Space 或操纵用户桌面状态，除非后续 execution card 单独批准。

frontmost app：

- screenshot verification 可以记录 frontmost app 是否为 smoke 进程。
- 非 frontmost 不必自动失败，但如果 target bounds 被遮挡或不可确认，应归为可见性 / 环境失败。

timing：

- 必须等待 readiness 日志后再截图。
- 必须给窗口呈现留出受控延迟或轮询窗口可见状态。
- 自动关闭时间必须足够长，不能让截图 probe 与窗口销毁竞争。
- timing 失败不能写成 render failure，除非日志明确证明 render readiness 失败。

## 12. Permission / CI / Headless

Screen Recording 权限：

- 权限失败必须被归为 `permission_denied`。
- 不允许 runtime 申请或管理权限。
- 不允许把权限失败写成 render failure。
- closure review 必须记录错误文本或系统返回证据。

历史错误：

- `could not create image from display` 默认归类为 `display_unavailable`。
- 只有在能证明它由权限引起时，才能归类为 `permission_denied`。

CI / headless：

- 当前不承诺 CI / headless 可复核。
- 如果没有真实 display session，应分类为 `display_unavailable` 或 `unknown`。
- 不允许为了 CI 提前引入 offscreen renderer。
- 不允许为了 CI 设计跨平台 screenshot abstraction。

## 13. Failure Classification

未来 screenshot verification 不应把失败统一写成 render failure。

建议至少沿用 feasibility 分类：

- `permission_denied`
- `display_unavailable`
- `window_not_found`
- `window_not_visible`
- `capture_failed`
- `render_not_ready`
- `render_failure`
- `unknown`

未来如果第一张 execution card 需要区分遮挡，可以在 docs-only 卡里增加：

- `window_occluded`
- `target_mismatch`
- `color_mismatch`

但新增分类必须仍然是 harness diagnostics，不得变成 public runtime API。

render failure 只有在以下条件同时成立时才允许：

- readiness 或 render 日志明确失败。
- 失败与权限、display、window visibility、capture API、timing 无关。
- closure review 能提供证据。

## 14. Runtime Pollution Guard

为了避免 screenshot verification 反向污染 Renderer / Scene / Widget / Layout / DSL：

- screenshot verification 只能是 verification harness。
- screenshot artifact 只能是外部 evidence。
- window bounds / title / process id / frontmost app 只能是 harness diagnostics。
- 不把截图坐标、display id、window id、bounds 写成 public widget contract。
- 不为了截图便利修改正式 render pipeline。
- 不为了截图便利设计 Renderer / Scene。
- 不为了截图便利设计 Widget / Layout / DSL。
- 不为了截图便利引入跨平台 backend。
- 不为了截图便利改变 bridge lifecycle。

为了避免 smoke demo 被升级成正式 runtime：

- 始终称为 `labs/macos_bridge_smoke`。
- 始终称为 smoke demo、smoke diagnostics 或 verification harness。
- 不把 smoke 日志字段、window title、bounds、截图策略写成 public runtime contract。
- 每个后续实现必须有 execution card 和 closure review。
- closure review 必须说明“这不是正式 GUI runtime”。

## 15. 本轮允许与禁止

本轮允许：

- 新建本 preflight 文档。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

本轮不允许：

- 实现 screenshot verification。
- 保存 screenshot artifact。
- 读取屏幕像素。
- 比较像素颜色。
- 实现 pixel diff。
- 实现 frame hash。
- 实现 offscreen renderer。
- 修改 `labs/macos_bridge_smoke`。
- 修改 `verify_user_visible_window_screenshot_feasibility.sh`。
- 修改 `verify_auto_close.sh`。
- 修改 `cjgui_macos.m`。
- 新增 public C ABI / runtime API。
- 设计 Renderer / Scene。
- 设计 Widget / Layout / DSL。
- 做跨平台抽象。
- 做文本、输入法、无障碍。
- 做 AI semantic tree / Action Router。
- 把当前 smoke demo 宣称为正式 runtime。

## 16. 结论

本轮结论：

- screenshot feasibility first slice 已经证明当前本机能在 smoke readiness 后创建 CoreGraphics on-screen image object。
- 它仍不能证明 image content 属于目标 smoke window，也不能证明像素颜色正确、无遮挡、compositor 正确或 CI / headless 可复核。
- 可以继续推进到 docs-only `P1 user-visible window screenshot verification execution card`，但该卡必须保持极窄。
- 未来第一刀可以允许临时 screenshot artifact 和极窄 clear-color sample，但必须严格限制路径、生命周期、删除策略、非 baseline、非提交、非 pixel diff。
- pixel diff、frame hash 和 offscreen renderer 继续不允许，必须另开 preflight。

下一步推荐 opening：

- `P1 user-visible window screenshot verification execution card`

该 opening 仍然不自动开启实现。

未来 execution card 必须继续禁止：

- full GUI verification framework。
- pixel diff。
- frame hash。
- offscreen renderer。
- public C ABI / runtime API。
- Renderer / Scene / Widget / Layout / DSL。
- 跨平台 screenshot abstraction。
- 把 smoke demo 宣称为正式 runtime。
