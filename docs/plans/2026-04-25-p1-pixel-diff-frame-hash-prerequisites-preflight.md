# P1 Pixel Diff / Frame Hash Prerequisites Preflight

日期：2026-04-25

性质：docs-only / visual verification prerequisites preflight / P1 GUI verification evidence line

状态：完成；不批准直接实现

范围：冻结未来是否、何时、以什么边界进入 pixel diff / frame hash。本轮不实现 pixel diff，不实现 frame hash，不建立 baseline，不读取整图像素，不修改任何 harness 或 runtime。

## 1. 背景

当前已经完成：

- [P1 automated GUI verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [P1 frame metadata / render stats first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [P1 Metal readback feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [P1 user-visible window screenshot feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)
- [P1 user-visible window screenshot verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [P1 screenshot artifact retention first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)

当前已有 evidence：

- lifecycle / capability / auto-close 日志 harness。
- 脱水 frame metadata / render stats。
- smoke-only single-frame clear-color Metal readback summary。
- CoreGraphics on-screen image feasibility success。
- 目标 smoke window 归属成功。
- 临时 target-window screenshot artifact 创建成功并在成功路径删除。
- 目标窗口中心附近 `3x3` clear-color sample summary 通过。
- screenshot artifact retention / cleanup policy first slice 已落地，成功 artifact 删除，失败 artifact 只允许短期保留，历史 `/tmp/cjgui-p1-screenshot-verification.*` 目录按 24 小时 TTL 清理。

当前仍没有：

- baseline / golden image owner。
- baseline update / review 流程。
- 稳定 source image 选择。
- 整图像素读取授权。
- raw bytes 保存策略。
- hash 输入边界。
- diff 阈值。
- 颜色空间 / scale / alpha / anti-aliasing 策略。
- CI / headless 复核策略。
- Renderer / Scene truth。

## 2. 当前是否具备进入 Pixel Diff / Frame Hash 的条件

结论：

> 当前不具备进入 pixel diff 或正式 frame hash 的实现条件。

原因：

- 当前 screenshot verification 只做 target-window attribution 和中心附近 `3x3` clear-color sample，不读取整图。
- 当前 Metal readback summary 只证明 command buffer completion 之后的 smoke clear-color probe summary，不提供整帧 bytes。
- 当前 artifact retention policy 明确禁止 artifact 进入仓库、baseline / golden image 或 long-term cache。
- 当前没有 baseline owner，也没有 baseline update 审批规则。
- 当前没有 source image 的唯一 truth。
- 当前没有 diff / hash 的颜色空间、Retina scale、alpha、row stride、window decoration、裁剪范围和 timing 规则。
- 当前没有 CI / headless 复核环境。
- 当前没有正式 Renderer / Scene / Widget / Layout，pixel diff 的长期语义很弱。

本 preflight 可以允许后续另开更窄 execution card，但不能直接批准实现。

## 3. Pixel Diff 解决什么，不能解决什么

pixel diff 解决的问题：

- 将当前 source image 与 baseline / golden image 做逐像素或区域级比较。
- 发现空白帧、错色、偏移、裁剪错误和明显视觉回归。
- 在 Renderer / Scene 稳定之后，为 GUI regression test 提供机器可复核证据。

pixel diff 不能解决的问题：

- 不能证明 UI 状态真相正确。
- 不能证明事件、布局、资源生命周期或 FFI owner 正确。
- 不能证明截图环境稳定。
- 不能区分权限、遮挡、Space、frontmost app、display failure 和 render failure，除非有独立 failure classification。
- 不能替代 Metal readback truth。
- 不能替代用户可见窗口 proof。
- 不能在没有 baseline owner 和更新流程时安全运行。

当前阶段的判断：

- pixel diff 不能作为下一刀。
- pixel diff 至少要等 source image、baseline policy、artifact privacy、diff threshold 和 failure classification 冻结后再开。
- 对正式 UI 的 pixel diff 应等待 Renderer / Scene 稳定后再进入，因为否则 baseline 只会绑定当前 smoke demo 的偶然画面。

## 4. Frame Hash 解决什么，不能解决什么

frame hash 解决的问题：

- 将一帧或受控裁剪区域压缩成短文本 evidence。
- 避免在 closure review 中长期保存大图或 raw bytes。
- 在 source image 稳定后，提供轻量回归信号。
- 可作为 pixel diff 之前的 feasibility step，先验证 source image 输入是否可稳定归一化。

frame hash 不能解决的问题：

- 不能定位视觉差异发生在哪里。
- 不能解释差异原因。
- 不能天然跨机器、跨显示器、跨颜色空间稳定。
- 不能在没有 source image 规则时成立。
- 不能证明用户可见窗口无遮挡或 compositor 正确。
- 不能替代 pixel diff，也不能替代 Renderer / Scene 级验证。

frame hash 是否可能比 pixel diff 更早做：

- 可以，但只能是 `frame hash feasibility`，不是 baseline verification。
- 前提是先选定 source image，定义裁剪范围、scale、pixel format、颜色空间和 hash 输入边界。
- 第一刀最多输出脱水 hash feasibility summary，不保存 raw bytes，不建立 baseline，不做 pass/fail 回归判断。
- 如果 source image 来自 screenshot，还必须继续遵守 artifact retention policy 和隐私边界。

## 5. Source Image 应该来自哪里

候选 source image 有三类：

### 5.1 User-visible Screenshot

适合证明：

- OS / compositor / display presentation 之后，用户可见窗口近似呈现了预期结果。
- target-window crop 可以作为未来视觉证据源。

风险：

- 受 Screen Recording 权限、窗口焦点、frontmost app、Space / Mission Control、遮挡、多显示器、Retina scale、窗口 decoration、timing 和桌面环境影响。
- 不适合直接作为 CI / headless 默认 source。
- artifact 隐私风险最高。

当前状态：

- 已完成 feasibility、target attribution、`3x3` clear-color sample 和 artifact retention / cleanup first slice。
- 仍不允许读取整图、建立 baseline、保存成功 artifact 或做 diff / hash。

### 5.2 Metal Readback

适合证明：

- command buffer completion 后，受控 Metal render target 中出现预期 clear-color probe。
- 避免窗口遮挡、屏幕权限和 desktop environment 噪音。

风险：

- 更接近 render target，不证明用户可见窗口。
- 如果扩成整帧 readback，必须处理 texture storage mode、row bytes、pixel format、颜色空间、同步成本和 GPU / CPU readback 生命周期。
- 容易滑向 renderer diagnostics 或 render abstraction。

当前状态：

- 只有 smoke-only、single-frame、clear-color summary。
- 没有整帧 bytes，也没有 frame hash 输入。

### 5.3 Future Offscreen Renderer

适合证明：

- 最适合 CI / headless 和稳定 regression。
- 可以绕开窗口、权限、遮挡和 compositor。

风险：

- 当前没有 Renderer / Scene。
- 引入 offscreen renderer 会提前打开 render target owner、scene input、resource lifecycle 和 renderer contract。
- 当前 P1 smoke 边界内不允许。

当前状态：

- 不允许定论为 source image。
- 必须等 Renderer / Scene 独立 preflight 后再评估。

### 5.4 当前结论

当前不允许定论唯一 source image。

推荐判断：

- 如果目标是用户可见窗口 evidence，未来 source 应优先考虑 target-window screenshot crop。
- 如果目标是 render target evidence，未来 source 应优先考虑受控 Metal readback。
- 如果目标是 CI / headless regression，未来 source 很可能需要 offscreen renderer，但当前不得开启。

任何 execution card 都必须只选一个 source，不能一次把 screenshot、Metal readback 和 offscreen renderer 混成一个系统。

## 6. Baseline / Golden Image Owner

当前 baseline / golden image 没有 owner。

未来可能 owner：

- verification harness owner：负责 artifact 路径、隐私、cleanup、failure classification。
- renderer / scene owner：负责 render input、scene truth、稳定输出和 baseline 更新。
- test harness owner：负责 CI matrix、阈值、更新审批和失败报告。

当前不允许建立 baseline，原因：

- 当前没有正式 Renderer / Scene truth。
- 当前 smoke 画面只是 clear-color demo，不是产品级 UI。
- 当前 source image 还没有唯一选择。
- 当前没有 baseline review / update 流程。
- 当前没有隐私 redaction / crop / retention 规则能支持长期资产。
- 当前没有跨机器稳定性策略。

baseline / golden image 不允许：

- 写入仓库。
- 从 `/tmp` 临时 artifact 自动提升。
- 由单次成功 screenshot 自动生成。
- 由 AI 自动更新。
- 作为 public runtime API 或 Renderer / Scene truth。

## 7. Artifact Retention Policy 如何约束后续

artifact retention policy 对后续 pixel diff / frame hash 的硬约束：

- 成功 artifact 默认删除。
- 失败 artifact 只允许短期、受控、可解释地保留。
- artifact 默认只能位于 `/tmp` 或 `mktemp -d` 临时目录。
- 历史临时目录清理只允许匹配 `/tmp/cjgui-p1-screenshot-verification.*`，TTL 默认 24 小时。
- artifact 不允许进入仓库。
- artifact 不允许成为 baseline / golden image。
- artifact 不允许长期缓存。
- artifact 不允许内联进 Markdown 或日志。
- artifact 不允许保存 full screen screenshot；target-window crop 也只能服务短期诊断。

对失败截图：

- 可以在短期保留条件下服务 failure classification。
- 不能直接转成 baseline。
- 不能因为存在 artifact 就开始 pixel diff。

对成功截图：

- 当前成功路径必须删除。
- 如果未来需要保留成功 artifact 作为 diff / hash 输入，必须另开 execution card，并重新回答隐私、路径、生命周期、删除策略和 baseline 禁令。

对临时 artifact：

- 可以作为当前运行内的临时输入。
- 不能变成长期 source of truth。
- 不能被 public runtime 或上层 API 依赖。

## 8. 是否允许读取整图像素

当前不允许读取整图像素。

原因：

- 整图读取会把 screenshot artifact 从“极窄 sample evidence”扩大成“完整视觉数据处理”。
- target-window crop 仍可能包含用户桌面敏感内容或系统 decoration。
- 当前没有 raw bytes 处理、清理、脱敏或日志禁止策略的实现授权。
- 当前没有颜色空间、scale、alpha、stride 和坐标边界规则。
- 当前没有 baseline owner。
- 当前没有 CI / headless 复核策略。

未来如果允许整图读取，必须另开 execution card，并至少限制：

- 只读取单一受控 source image。
- 不输出 raw bytes。
- 不保存 raw bytes。
- 不提交 artifact。
- 不建立 baseline，除非另有 baseline preflight。
- 只输出脱水 summary。
- 记录 source、bounds、scale、pixel format、颜色空间和 failure classification。

## 9. 是否允许保存 Raw Bytes、Hash、Diff Result

当前结论：

- raw bytes：不允许保存。
- hash：不允许作为 baseline 或长期证据保存；不允许本轮生成。
- diff result：不允许生成或保存。

原因：

- raw bytes 隐私风险高，且容易变成未经治理的长期 artifact。
- hash 虽然体积小，但一旦写入仓库或文档，容易被误当成稳定 golden value。
- diff result 需要 baseline、阈值、source image 和 failure classification；当前均未冻结。
- 保存 hash / diff result 会过早制造视觉 regression contract。

未来第一刀如果做 frame hash feasibility，最多允许：

- 当前运行内临时读取受控 source image。
- 输出脱水 hash feasibility summary。
- 不保存 raw bytes。
- 不写 baseline hash。
- 不把 hash mismatch 写成 render failure。
- 不作为 pass/fail regression 判断。

## 10. 视觉稳定性风险

### 10.1 颜色空间

风险：

- screenshot 可能经过 display color profile。
- Metal readback 可能是 BGRA8Unorm 等 render target format。
- sRGB / Display P3 / linear / premultiplied alpha 可能不同。

要求：

- 任何 hash / diff 必须声明颜色空间。
- 未声明时只能输出 `unknown` 或 `degraded`，不能声称 pixel correct。

### 10.2 Retina Scale

风险：

- AppKit points 与 pixel 坐标不同。
- window bounds 与 screenshot pixels 可能需要 scale 映射。
- 多显示器 scale 可能不同。

要求：

- hash / diff 输入必须记录 scale。
- source crop 必须说明是 point-space 还是 pixel-space。

### 10.3 Window Decoration

风险：

- screenshot crop 可能包含 title bar、shadow、rounded corner、traffic-light buttons。
- window decoration 由系统主题和 OS 版本影响。

要求：

- 未来 source crop 应尽量选择 content-safe interior，或明确 decoration included。
- 不得把 window decoration diff 写成 renderer failure。

### 10.4 透明度 / Alpha

风险：

- premultiplied alpha、transparent layer、window shadow 和 compositor blending 会改变像素。

要求：

- diff / hash 必须定义 alpha 处理方式。
- 未定义时不能进入 baseline。

### 10.5 Compositor / Presentation

风险：

- screenshot 看到的是 compositor 后结果。
- Metal readback 看到的是 render target。
- 二者 truth 不同。

要求：

- source 必须声明属于 screenshot truth 还是 Metal readback truth。
- 二者不能互相替代。

### 10.6 遮挡 / 多显示器 / Timing

风险：

- 窗口可能被遮挡、隐藏、移动到其他 Space 或 display。
- 截图可能早于 first presentation。
- 自动关闭可能与截图时机竞争。

要求：

- failure classification 必须保留 `window_occluded`、`target_mismatch`、`render_not_ready`、`capture_failed`、`display_unavailable` 等非 render failure。
- timing 不足不能伪装成 render failure。

### 10.7 Anti-aliasing

风险：

- 未来文本、边框、圆角、shape 都会受 anti-aliasing 和字体 rasterization 影响。
- pixel-perfect diff 很容易误报。

要求：

- 在 Renderer / Scene / Widget / Text 未稳定前，不允许为复杂 UI 建立 pixel-perfect baseline。
- 未来 pixel diff 必须有阈值和局部容忍策略。

## 11. CI / Headless 可复核性

当前不可声称 CI / headless 可复核。

分类规则：

- 没有 display / WindowServer：`display_unavailable`。
- 没有 Screen Recording 权限：`permission_denied`。
- 不能找到目标窗口：`window_not_found`。
- 目标窗口不可见或不在当前 Space：`window_not_visible`。
- 截图 API 返回 nil 或失败：`capture_failed`。
- source image 存在但不能确认属于目标窗口：`target_mismatch`。
- source image 存在但无法满足 hash / diff 前置条件：`prerequisite_missing` 或 `unknown`。

CI / headless 下一步不能直接是 pixel diff。

更合理路线：

- 先用日志 harness、metadata 和 Metal readback summary 做无窗口依赖的 smoke evidence。
- 对 user-visible screenshot evidence 保持本机 / 有桌面会话限定。
- 等 Renderer / Scene 成熟后再评估 offscreen renderer。

## 12. 当前 `3x3` Sample 与真正 Pixel Diff / Frame Hash 的边界

当前 `3x3` clear-color sample 证明：

- screenshot verification harness 可以归属目标窗口。
- 可以在目标窗口 safe interior 读取极小区域。
- 当前 smoke 的中心区域接近 expected clear color。

它不证明：

- 整个窗口像素正确。
- 边缘、decoration、scale、alpha、shadow 或 anti-aliasing 正确。
- pixel diff 可用。
- frame hash 稳定。
- baseline 可建立。

当前 Metal readback summary 证明：

- command buffer completion 后，smoke bridge 可读取 clear-color probe summary。
- render target 层面的 clear-color sample 与 expected clear color 匹配。

它不证明：

- 用户可见窗口正确。
- compositor / display presentation 正确。
- 整帧 bytes 可 hash。
- screenshot crop 可 diff。

二者都是 prerequisites evidence，不是 pixel diff / frame hash 本身。

## 13. Future Execution Card 第一刀最大边界

如果未来要开 execution card，第一刀最多允许：

> `P1 frame hash feasibility execution card`

该卡只能授权一个极窄 feasibility slice：

- 只选择一个 source image，不允许同时支持 screenshot、Metal readback 和 offscreen renderer。
- 推荐优先选择当前已经完成 target attribution 的 target-window screenshot crop，或明确选择 Metal readback source；必须在 execution card 中二选一。
- 只计算当前运行内的脱水 hash summary。
- 不建立 baseline。
- 不比较 golden image。
- 不做 pixel diff。
- 不保存 raw bytes。
- 不提交 artifact。
- 不修改 native bridge，除非 execution card 单独把 Metal source 作为唯一 source 并解释必要性。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不把 hash mismatch 写成 render failure，除非 source、bounds、scale、颜色空间和环境前置条件全部成立。

pixel diff execution card 不应作为下一张卡。

原因：

- pixel diff 需要 baseline owner、baseline storage、threshold、颜色空间和 update 流程。
- 当前这些前置条件还没有冻结。

## 14. 本轮 Stop-line

本轮明确不做：

- 不实现 pixel diff。
- 不实现 frame hash。
- 不建立 baseline / golden image。
- 不保存 screenshot artifact。
- 不读取整图像素。
- 不输出 raw bytes。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 screenshot verification harness。
- 不修改 `verify_auto_close.sh`。
- 不修改 native bridge。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做 offscreen renderer。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 15. Next Opening

当前没有自动开启的直接实现 opening。

如果继续推进，推荐下一步仍是 docs-only：

> `P1 frame hash feasibility execution card`

这张卡必须继续限制为 feasibility，不得授权 pixel diff、baseline、golden image、raw bytes 保存、offscreen renderer、public runtime API 或 Renderer / Scene。
