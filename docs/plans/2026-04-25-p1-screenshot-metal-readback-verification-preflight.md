# P1 Screenshot / Metal Readback Verification Preflight

日期：2026-04-25

性质：docs-only / visual verification strategy preflight / P1 runtime foundation
状态：完成；不批准直接实现
范围：冻结未来像素级 / 视觉级 GUI 验证的第一条证据链选择，不实现 screenshot、不实现 Metal readback、不实现 frame hash / pixel diff / offscreen renderer。

## 1. 背景

当前已经完成：

- [P1 automated GUI verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [P1 frame metadata / render stats first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)

当前已有两类机器可复核证据：

- `verify_auto_close.sh` 的生命周期 / capability / first-frame 日志 harness。
- smoke bridge 输出的脱水 frame metadata / render stats 日志。

但当前仍没有：

- screenshot artifact。
- window screenshot。
- Metal texture readback。
- frame hash。
- pixel diff。
- offscreen renderer。
- 自动视觉正确性证明。

本 preflight 只冻结下一阶段证据链选择。

它不是：

- screenshot implementation authorization。
- Metal readback implementation authorization。
- pixel diff / frame hash implementation authorization。
- offscreen renderer design。
- Renderer / Scene design。
- public runtime API design。

## 2. 当前证据能证明什么

当前日志 harness 能证明：

- 构建脚本可以运行。
- `SDKROOT` 选择可见。
- Objective-C bridge init 路径进入。
- Metal device 和 command queue capability check 通过。
- AppKit window created 路径进入。
- Metal setup complete 路径进入。
- first frame render path 至少执行到日志点。
- 自动关闭通过 `post close request` 进入主线程 lifecycle queue。
- close / destroy / event loop exit 路径完成。
- 仓颉侧观察到 `cjgui_app_run()` 返回 `0`。

当前 frame metadata / render stats 能进一步证明：

- smoke bridge 观测到 drawable width / height。
- smoke bridge 观测到 scale factor。
- smoke bridge 观测到 pixel format。
- bridge 记录了 intended clear color metadata。
- bridge 记录了 submitted 状态、attempt count、success / degraded reason。
- `committed=unknown`，因为当前没有 GPU completion 或 display presentation 证明。

这些证据都属于：

- 执行路径证据。
- bridge 观测证据。
- 脱水 diagnostics 证据。

## 3. 当前证据不能证明什么

当前仍不能证明：

- 屏幕真实像素正确。
- clear color 真实落到 drawable bytes。
- clear color 真实出现在屏幕窗口。
- window 没有被遮挡、最小化、移动到其他 Space 或不可见。
- Retina scale 下 screenshot / drawable 尺寸转换正确。
- GPU command 完成。
- compositor 最终呈现正确。
- frame hash 或 pixel diff 通过。
- CI / headless 环境能稳定复核 GUI 视觉结果。

关键边界：

> `first frame rendered`、`submitted=true` 和 `clear_color=...` 都不是像素级证据。它们只说明 bridge 准备并提交了某个渲染意图。

## 4. 当前 smoke 阶段的最小视觉正确性定义

当前 smoke 还没有 Renderer / Scene / Widget / Layout。

因此当前阶段的“视觉正确性”不能定义成：

- UI tree 正确。
- layout 正确。
- widget shape 正确。
- 文本正确。
- 多控件视觉一致。
- 跨平台像素一致。

当前 smoke 阶段最小视觉正确性只能定义为：

- 在 macOS smoke 运行期间，至少一个受控渲染目标中出现了预期 clear color 的像素证据。
- 该证据能被机器复核。
- 该证据不依赖仓颉公共层持有 AppKit / Metal 平台对象。
- 该证据不把 smoke demo 升级为正式 GUI runtime。

更严格的端到端视觉正确性可以作为 future goal：

- 用户可见窗口中出现预期颜色。
- 截图区域与窗口内容匹配。
- 图像 artifact 可保存、可 hash、可 diff。

但这不是当前 smoke first slice 的默认定义。

## 5. 方案对比

### 5.1 macOS screen / window screenshot

解决的问题：

- 提供 compositor 之后的用户可见结果证据。
- 可以证明某个屏幕区域或窗口区域近似看起来正确。
- 未来可作为 pixel diff / artifact review 的 source image。

主要风险：

- 依赖窗口可见。
- 依赖窗口焦点和 Space 状态。
- 依赖屏幕录制 / 截图权限。
- 受窗口遮挡、最小化、其他 app 覆盖影响。
- 受 Retina scale、多显示器、颜色配置影响。
- 受动画 timing、窗口移动、compositor delay 影响。
- 真实 CI / headless 环境中稳定性差。
- 之前已出现过 `could not create image from display`，说明本机截图路径已经暴露环境不确定性。

成本与维护：

- 短期实现看似低成本。
- 长期维护成本高，因为失败常常来自权限、显示环境、焦点、遮挡，而不是 GUI 代码本身。
- debug 难度高，容易把环境失败误判为渲染失败。

当前判断：

- 不适合作为第一条稳定证据链。
- 适合未来单独开 `screenshot feasibility preflight / execution card`，用于验证用户可见窗口端到端证据。
- 不适合当前直接实现。

### 5.2 Metal drawable / texture readback

解决的问题：

- 直接验证 Metal 渲染目标的像素 bytes 或受控采样结果。
- 不依赖窗口焦点、遮挡、屏幕权限或多显示器可见状态。
- 更贴合当前 smoke 的目标：验证 Metal clear path 是否真的产生预期像素。

主要风险：

- 必须诚实处理 command buffer completion。
- 当前 `committed=unknown` 不能伪装成完成，需要等待或 completion handler 后才能读取。
- 可能涉及 `framebufferOnly`、texture storage mode、CPU readback 或 blit 到 CPU-visible buffer。
- 可能引入同步成本，影响事件循环时序。
- 如果直接读取 drawable texture，容易和 CAMetalLayer / drawable 生命周期纠缠。
- 如果为了 readback 顺手改 render target 结构，容易滑向 offscreen renderer 或 renderer abstraction。

成本与维护：

- 实现成本高于日志和 metadata。
- 维护成本低于 screenshot，因为环境变量更少。
- 需要非常窄的 write set 和明确 stop-line，防止把 Metal readback 扩成正式 renderer diagnostics。

当前判断：

- 如果必须进入第一条像素证据链，优先候选应是 `Metal readback feasibility`，而不是 screenshot。
- 但本轮不实现。
- 未来必须另开 execution card，并限定为 smoke-only、single-frame、clear-color feasibility。

### 5.3 frame hash

解决的问题：

- 把一帧像素证据压缩成稳定文本证据。
- 方便 harness 比较，避免保存大图。
- 可以作为 future closure review 的机器可复核摘要。

前置条件：

- 必须先有稳定 source image 或 readback bytes。
- 必须定义颜色空间、像素格式、row stride、scale、alpha、endianness。
- 必须定义 hash 输入边界。

主要风险：

- 没有稳定 readback/source image 前，hash 没有真相来源。
- 一旦 hash 被写进文档，容易被误当成跨平台视觉 contract。
- 对颜色空间、Retina scale、GPU/driver 差异敏感。

当前判断：

- 不能作为第一刀。
- 必须晚于 screenshot 或 Metal readback source 稳定之后。

### 5.4 pixel diff

解决的问题：

- 对比当前 frame 与 baseline image。
- 能发现错色、空白、偏移、局部视觉回归。
- 是更接近 GUI regression test 的形态。

前置条件：

- 必须有稳定 source image。
- 必须有 baseline artifact。
- 必须定义 diff 阈值、颜色空间、scale、抗锯齿容忍度、平台差异策略。

主要风险：

- 在没有 Renderer / Scene 前，baseline 意义很弱。
- screenshot source 会带来焦点、遮挡、权限和环境噪音。
- Metal readback source 会证明 render target，不证明用户可见窗口。
- 阈值过宽会漏问题，过窄会产生大量误报。

当前判断：

- 不能作为第一刀。
- 应晚于稳定 screenshot / readback source。
- 需要单独 preflight 和 execution card。

### 5.5 offscreen renderer

解决的问题：

- 提供最可控、最适合 CI 的渲染输入和输出。
- 可以绕开窗口、权限、遮挡和 compositor。
- 未来可成为 Renderer / Scene 级视觉测试的主力。

主要风险：

- 当前 smoke 没有正式 Renderer / Scene。
- 引入 offscreen renderer 很可能需要定义 render target、render command、frame ownership 和 resource lifecycle。
- 容易越过当前 P1 bridge smoke 边界。
- 容易提前设计 Renderer / Scene / Widget / Layout。

当前判断：

- 当前不允许引入。
- 需要等 Renderer / Scene 设计有独立 preflight 后再评估。
- 不能在本轮或下一刀为了验证而顺手实现。

## 6. 当前第一候选路线

本轮结论：

> 当前继续只做 preflight，不进入实现。

如果后续用户明确要从“日志 / metadata 证据”进入“像素证据”，第一候选路线建议是：

> `P1 Metal readback feasibility execution card`

选择 Metal readback 作为第一候选，而不是 screenshot，原因是：

- 当前 smoke 的最小视觉定义是“受控 Metal clear target 出现预期像素证据”，不是完整用户可见窗口截图。
- Metal readback 不依赖屏幕权限、窗口焦点、遮挡、多显示器或 CI 桌面会话。
- Metal readback 与当前 frame metadata 中的 drawable / pixel format / clear_color 证据链更连续。
- 已知 screenshot 路径曾失败，错误为 `could not create image from display`，不适合作为第一条稳定机器证据。

但 Metal readback 仍然不是自动批准实现。

进入实现前必须单独回答：

- 读哪个 texture / buffer？
- 何时等待 command buffer completion？
- 是否需要改变 `framebufferOnly`？
- 是否需要 blit 到 CPU-visible buffer？
- 如何保证不暴露 Metal 对象？
- 如何保证不变成 renderer abstraction？
- 如何把结果降成脱水日志，而不是 public API？

## 7. Screenshot 路线详细边界

如果未来倾向 screenshot，必须先回答：

- 窗口是否必须可见？
- 是否要求窗口为 key window / frontmost app？
- 是否需要屏幕录制权限？
- Retina scale 如何映射点坐标与像素坐标？
- 多显示器情况下窗口在哪个 display？
- 窗口被遮挡时是否算失败？
- 窗口最小化、隐藏、切 Space 时如何处理？
- 是否需要等待窗口呈现或动画完成？
- `CJGUI_AUTOCLOSE_SECONDS=1` 是否会造成截图 timing 不稳定？
- CI / headless 环境是否有真实 display server？
- 失败时如何区分截图权限失败、窗口不可见和渲染失败？

当前判断：

- screenshot 更接近用户最终可见结果。
- screenshot 也最容易把外部桌面环境噪音引进 harness。
- 现阶段不应直接实现，也不应把 screenshot 失败写成 GUI 渲染失败。

## 8. Metal Readback 路线详细边界

如果未来倾向 Metal readback，必须先回答：

- command buffer 是否已经 completed？
- completion 的 owner 是 bridge 还是 harness？
- 是否允许 `waitUntilCompleted`，以及它对事件循环时序的影响是什么？
- 当前 drawable texture 是否 CPU-readable？
- 是否需要单独 staging buffer / staging texture？
- texture storage mode、row bytes、pixel format、color conversion 如何处理？
- readback 失败属于 `fatal`、`recoverable` 还是 `degraded`？
- readback 结果是否只输出脱水日志？
- 是否允许记录 sample RGBA？如果允许，字段名、范围和非 public API 边界是什么？
- 是否允许保存 raw bytes？默认不允许。

必须禁止：

- 把 `CAMetalDrawable*`、`id<MTLTexture>`、`id<MTLCommandBuffer>` 暴露到仓颉层或 public API。
- 为了 readback 新增 public C ABI。
- 为了 readback 提前设计 Renderer / Scene。
- 为了 readback 改写整个 render pipeline。
- 把 smoke readback 写成跨平台 renderer diagnostics。

## 9. Frame Hash / Pixel Diff 路线详细边界

frame hash 和 pixel diff 都不是 source of truth。

它们依赖：

- screenshot artifact。
- window screenshot artifact。
- Metal readback bytes。
- offscreen renderer output。

如果未来启用 frame hash，必须定义：

- 输入像素来源。
- width / height。
- row stride。
- pixel format。
- color space。
- scale。
- alpha / premultiplied alpha。
- hash 算法。
- hash 是否平台相关。

如果未来启用 pixel diff，必须定义：

- baseline artifact owner。
- baseline 更新流程。
- diff 阈值。
- 颜色容忍度。
- antialiasing 容忍度。
- Retina scale 和多平台差异策略。
- 失败 artifact 存放路径。

当前判断：

- 没有稳定 source image 前，不允许实现 frame hash 或 pixel diff。
- 不允许把 frame metadata 当成 hash / diff 输入。

## 10. Offscreen Renderer 路线详细边界

offscreen renderer 很可能越过当前 P1 边界。

原因：

- 它需要定义 render target owner。
- 它需要定义 render input。
- 它需要定义 resource lifecycle。
- 它很容易要求 Renderer / Scene / render command。
- 它可能绕过 AppKit window smoke 的真实路径。

当前不允许引入 offscreen renderer。

未来如需进入，必须先完成：

- Renderer / Scene preflight。
- render command truth 定义。
- diagnostics owner 定义。
- offscreen target lifecycle 定义。
- CI artifact 策略。

## 11. Owner / Truth / Projection

### 11.1 当前 truth

当前 truth 仍然是：

- bridge lifecycle 日志。
- bridge capability 日志。
- bridge frame metadata / render stats 日志。
- `verify_auto_close.sh` 捕获的原始日志。

### 11.2 未来 screenshot truth

screenshot truth 是：

- OS / compositor 之后的可见图像 artifact。

它不是：

- Renderer / Scene truth。
- Metal render target truth。
- UI state truth。

### 11.3 未来 Metal readback truth

Metal readback truth 是：

- 某个受控 Metal render target 在 command completion 后的 bytes / sample / summary。

它不是：

- 用户可见窗口 truth。
- compositor truth。
- Renderer / Scene truth。
- public runtime API。

### 11.4 harness projection

harness 只负责：

- 收集证据。
- 检查 needle / artifact / summary。
- 输出成功或失败。

harness 不负责：

- 持有平台对象。
- 定义 Renderer / Scene。
- 推断 UI 状态真相。
- 把 demo 变成正式 runtime。

## 12. 本轮允许与禁止

本轮允许：

- 新建本 preflight 文档。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

本轮不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- 任何 runtime / bridge 代码。

本轮不允许新增：

- public C ABI。
- public runtime API。
- screenshot implementation。
- Metal readback implementation。
- frame hash implementation。
- pixel diff implementation。
- offscreen renderer。

## 13. 如何保持 smoke 不变成正式 runtime

规则：

- 始终称为 `labs/macos_bridge_smoke`。
- 始终称为 smoke diagnostics 或 verification harness。
- 不把 smoke 字段写入 public runtime API。
- 不让 smoke 的日志格式定义未来 Renderer / Scene。
- 不让 smoke 的 readback / screenshot 方案反向决定正式架构。
- 不因验证需要而设计 Widget / Layout / DSL。
- 每个 execution card 都必须限定 write set 和 stop-line。
- 每个 closure review 都必须说明“这不是正式 runtime”。

## 14. 未来 execution card 建议

如果继续推进，下一篇应是 docs-only execution card：

- `P1 Metal readback feasibility execution card`

该 execution card 只能授权一个极窄 first slice，最大边界如下：

- 只在 `labs/macos_bridge_smoke` 内部探索单帧 Metal readback feasibility。
- 只验证当前 smoke 的受控 clear-color render target。
- 只输出脱水日志 summary，例如 readback 可用性、sample / summary 是否匹配、degraded reason。
- 不保存 raw pixel bytes。
- 不生成 screenshot artifact。
- 不做 frame hash。
- 不做 pixel diff。
- 不做 offscreen renderer。
- 不新增 public C ABI / runtime API。
- 不暴露 `CAMetalDrawable*`、`id<MTLTexture>`、`id<MTLCommandBuffer>` 或 Objective-C `id`。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不修改仓颉入口，除非 execution card 另有明确批准；默认不改。
- `verify_auto_close.sh` 最多增加 readback summary 的日志 needle。
- closure review 必须记录 command buffer completion 语义、日志路径、断言结果和仍未覆盖的用户可见窗口风险。

如果用户更想优先证明用户可见窗口，则应另开：

- `P1 screenshot feasibility execution card`

但该卡必须先接受 screenshot 权限、窗口遮挡、focus、Retina scale、多显示器和 headless / CI 稳定性风险。

## 15. 当前 stop-line

本轮强制 stop-line：

- 不实现 screenshot。
- 不实现 Metal readback。
- 不实现 frame hash。
- 不实现 pixel diff。
- 不实现 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke` 代码。
- 不修改 `verify_auto_close.sh`。
- 不新增 public C ABI / runtime API。
- 不设计正式 Scene / Renderer。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本、输入法、无障碍。
- 不做 AI semantic tree / Action Router。
- 不把当前 smoke demo 宣称为正式 runtime。

## 16. 结论

本轮结论：

- 当前日志 harness 和 frame metadata / render stats 已经能证明构建、生命周期、Metal capability、first-frame render path、自动关闭路径和脱水 diagnostics 字段。
- 当前仍不能证明屏幕真实颜色正确，也不能证明 drawable bytes 正确。
- 当前 smoke 阶段的最小视觉正确性应定义为“受控 render target 中出现预期 clear color 的机器可复核像素证据”。
- screenshot 证明更接近用户可见结果，但当前受权限、焦点、遮挡、Retina、多显示器、timing 和 CI / headless 环境影响，不适合作为第一条稳定证据链。
- Metal readback 更适合作为第一候选，但仍需要单独 execution card，且只能做 smoke-only feasibility。
- frame hash / pixel diff 必须等稳定 source image / readback bytes 之后。
- offscreen renderer 很可能越过当前 P1 边界，不能本轮引入。

下一步不自动进入实现。

如果继续推进，推荐下一条 docs-only opening：

- `P1 Metal readback feasibility execution card`

它只能授权一个 bounded implementation first slice，不能扩成 screenshot、pixel diff、frame hash、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、跨平台抽象或正式 runtime API。
