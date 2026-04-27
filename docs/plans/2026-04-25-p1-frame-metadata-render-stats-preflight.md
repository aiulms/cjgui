# P1 Frame Metadata / Render Stats Preflight

日期：2026-04-25

性质：docs-only / verification strategy preflight / P1 runtime foundation
状态：完成；不批准直接实现
范围：冻结未来 frame metadata / render stats 的边界，不实现元数据输出、不读取像素、不做截图、不设计 Renderer / Scene。

## 1. 背景

当前已经完成：

- [P0 macOS bridge smoke](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)。
- [P1 AppKit / Metal bridge boundary cleanup](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)。
- [P1 main-thread UI message queue first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)。
- [P1 automated GUI verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)。

当前 `verify_auto_close.sh` 已经可以机器复核一组稳定日志证据。

但这些证据仍然只停在：

- 构建链。
- 生命周期。
- Metal capability。
- first frame submitted / rendered 日志。
- 自动关闭路径。
- `cjgui_app_run()` 返回码。

下一步要冻结的是：

> 如何在不读取像素、不做截图、不设计 Renderer / Scene 的前提下，把验证从普通日志断言推进到更细的机器可复核渲染元数据。

本 preflight 只冻结策略。

它不是：

- execution card
- implementation authorization
- Objective-C bridge 修改批准
- JSON diagnostics 协议批准
- Renderer / Scene 设计批准
- 像素级验证批准

## 2. 当前 verification harness 已经能验证什么

当前 [verify_auto_close.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh) 能验证：

- `scripts/build_and_run.sh` 可以运行。
- `CJGUI_AUTOCLOSE_SECONDS=1` 可以触发自动关闭。
- `SDKROOT` 日志存在。
- `bridge init` 日志存在。
- Metal capability check 至少覆盖：
  - `metal device ok`
  - `command queue ok`
- `window created` 日志存在。
- `metal setup complete` 日志存在。
- `first frame rendered` 日志存在。
- 自动关闭进入：
  - `post close request`
  - `main-thread drain`
  - `close requested`
  - `destroy complete`
  - `event loop exited`
- 仓颉侧看到：
  - `Cangjie: cjgui_app_run returned 0`

这些证据证明：

- smoke 可构建。
- macOS bridge 可进入。
- 最小 Metal 初始化路径可进入。
- first-frame 提交路径至少被执行到日志点。
- `RequestClose` lifecycle queue 能完成自动关闭。

这些证据不证明：

- 屏幕上真实像素正确。
- Metal drawable 最终像素非空。
- clear color 最终落到屏幕。
- 窗口没有被遮挡、最小化或处于不可见空间。
- Retina scale / drawable size 完全符合预期。
- 多帧稳定。

## 3. 当前为什么还不能证明像素正确

当前不能证明像素正确，原因是：

- harness 只读取进程日志，不读取 framebuffer、texture 或屏幕。
- `first frame rendered` 是执行路径日志，不是 GPU readback 结果。
- `metal setup complete` 只能说明 setup 走到某个阶段，不说明最终 drawable 内容。
- 当前没有 screenshot artifact。
- 当前没有 window screenshot。
- 当前没有 Metal drawable readback。
- 当前没有 frame hash。
- 当前没有 pixel diff baseline。
- 当前没有 offscreen texture render。
- 当前没有 Renderer / Scene 输入，也没有可重放 render command。

因此：

> 日志验证和 metadata 验证都不能被写成像素级验证。它们最多证明“尝试绘制了什么”和“渲染路径走到了哪里”。

## 4. frame metadata / render stats 要解决什么风险

frame metadata / render stats 的目标不是证明像素正确，而是降低日志断言过粗带来的风险。

它要解决的风险包括：

- `first frame rendered` 太粗，无法看出 drawable 尺寸是否为 `0`。
- 无法知道当时的 scale factor。
- 无法知道桥接层认为的 pixel format。
- 无法知道本次渲染尝试次数。
- 无法知道 clear color 的意图值。
- 无法区分“尝试渲染但 degraded”和“根本没有尝试渲染”。
- 无法把未来 closure review 中的 first-frame 证据拆成更可复核的字段。

它不解决：

- 真实像素正确性。
- 截图可用性。
- GPU texture bytes 可读性。
- 多平台视觉一致性。
- Renderer / Scene 正确性。

## 5. Owner 与 Truth

owner 必须拆分。

### 5.1 bridge owner

bridge 是第一阶段 frame metadata / render stats 的事实来源。

bridge 可以拥有：

- drawable width / height 的观测值。
- scale factor 的观测值。
- pixel format 的脱水描述。
- clear color metadata 的意图值。
- first frame submitted / committed 的状态。
- render attempt count。
- render success / degraded reason。

bridge 不拥有：

- baseline image。
- pixel diff 结果。
- public Renderer / Scene truth。
- cross-platform diagnostics abstraction。
- widget / layout 信息。

### 5.2 verification harness owner

verification harness 负责：

- 启动 smoke。
- 收集日志或 diagnostics output。
- 检查 expected fields / needles。
- 把缺失字段报告成机器可复核失败。
- 在 closure review 中提供证据。

verification harness 不负责：

- 生成 metadata 真相。
- 持有平台对象。
- 推断像素正确。
- 设计 Renderer / Scene。

### 5.3 future renderer owner

future Renderer / Scene 出现后，renderer 才能拥有：

- render command truth。
- scene-level frame identity。
- offscreen render input。
- renderer-level frame hash。
- widget / layout visual evidence。

当前 smoke 还没有 Renderer / Scene。

因此当前 metadata 不得包含：

- renderer scene id。
- widget id。
- layout tree。
- render command identity。

### 5.4 diagnostics surface owner

建议未来引入一个独立 diagnostics surface 概念，但只作为实验期 read surface。

它可以定义：

- 字段名。
- 日志格式。
- 缺失字段处理。
- degraded reason 分类。

它不能升级为：

- public runtime API。
- Renderer API。
- Scene API。
- cross-platform diagnostics contract。

## 6. 第一阶段允许记录哪些字段

未来第一刀如果获得 execution card，建议只允许记录脱水字段。

允许字段：

- `frame_index`
  - 当前 smoke 中可先固定为 `0` 或 `1`，只代表本进程内第一帧尝试。
- `drawable_width`
  - 数值字段，不携带 `CAMetalDrawable` 或 texture。
- `drawable_height`
  - 数值字段，不携带 `CAMetalLayer`。
- `scale_factor`
  - 数值字段，来自 bridge 观测，不作为跨平台 DPI API。
- `pixel_format`
  - 脱水字符串或整数枚举值，例如 `BGRA8Unorm` 的日志表示。
- `clear_color`
  - 记录本次 clear color 意图值，例如 `r,g,b,a`。
- `first_frame_submitted`
  - 布尔或日志状态。
- `first_frame_committed`
  - 布尔或日志状态；如果当前实现无法可靠区分 submitted / committed，必须明确写成 degraded 或 not available。
- `render_attempt_count`
  - 进程内计数，仅用于 smoke diagnostics。
- `render_success`
  - 布尔或状态。
- `degraded_reason`
  - 例如 `none`、`no_metal_device`、`no_command_queue`、`no_drawable`、`command_buffer_unavailable`。

字段要求：

- 字段必须是标量、字符串或小型脱水结构。
- 字段不得携带平台对象。
- 字段不得成为 public runtime ABI。
- 字段不得表达 widget / layout / scene 语义。

## 7. 现在不应该记录哪些字段

当前阶段不应该记录：

- raw pixels。
- screenshot artifact。
- window screenshot artifact。
- Metal texture bytes。
- frame hash。
- pixel diff result。
- renderer scene id。
- render command id。
- widget id。
- layout information。
- accessibility node。
- input state。
- Objective-C object pointer。
- `NSWindow*`。
- `NSView*`。
- `NSEvent*`。
- `CAMetalLayer*`。
- `CAMetalDrawable*`。
- `id<MTLTexture>`。
- `id<MTLCommandBuffer>`。
- Objective-C `id`。

原因：

- raw pixels / texture bytes 会把本轮推进到 readback / pixel verification。
- screenshot artifact 会触发权限、遮挡和环境不确定性。
- frame hash / pixel diff 需要稳定像素来源。
- renderer scene id、widget、layout 信息会提前设计 Renderer / Scene / Widget。
- 平台对象会破坏桥接边界。

## 8. 是否允许暴露平台对象

不允许。

metadata / stats 不得携带：

- AppKit 对象。
- Metal 对象。
- Objective-C `id`。
- 任何平台对象裸指针。
- 可被上层长期保存的原生 handle。

允许的是脱水事实：

- 数字。
- 布尔值。
- 小型字符串。
- 明确枚举。
- degraded reason。

这条规则的原因是：

- 平台对象生命周期属于 bridge。
- 上层或 harness 不拥有平台对象。
- diagnostics 不能绕过 FFI 生命周期治理。
- 不能为了验证把平台细节泄露到公共层。

## 9. metadata 的输出形态

阶段选择建议：

### 9.1 当前本轮

本轮只写文档。

不输出：

- 新日志。
- diagnostics struct。
- JSON line。
- harness 新字段。

### 9.2 未来第一刀

如果未来开 execution card，第一刀优先考虑：

- 脱水日志行。
- 稳定日志 needle。
- `verify_auto_close.sh` 增加对应日志断言。

示例形态只作为未来讨论方向，不是本轮实现：

```text
cjgui: frame metadata: index=1 drawable=800x600 scale=2.00 pixel_format=BGRA8Unorm clear_color=0.00,0.50,0.55,1.00 submitted=true committed=true attempts=1 degraded=none
```

### 9.3 JSON line

JSON line 可以作为未来选择，但不建议第一刀默认实现。

原因：

- JSON 字段一旦出现，容易被误当成稳定协议。
- JSON parser / schema 会扩大 harness 复杂度。
- 当前 smoke 还没有正式 diagnostics surface。

如果要实现 JSON line，必须单独在 execution card 里批准。

### 9.4 diagnostics struct

diagnostics struct 可以作为未来内部 C / bridge 结构，但当前不建议直接做。

原因：

- 容易诱导新增 C ABI。
- 容易被仓颉层当作正式 runtime API。
- 当前只需要机器可复核 evidence，不需要跨边界数据结构。

### 9.5 future harness output

harness output 只是投影。

它可以总结：

- metadata needles 是否存在。
- 字段是否可解析。
- degraded reason 是否为 `none`。

但 harness output 不是渲染 truth。

## 10. 当前是否允许修改 Objective-C bridge

不允许。

本轮只做 docs-only preflight。

本轮不修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/README.md`

如果未来要实现第一刀 metadata / stats，必须先创建 execution card。

## 11. 未来第一刀 write set 建议

如果未来实现第一刀 frame metadata / render stats，write set 应该非常窄。

优先允许：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
  - 仅输出脱水日志或内部 diagnostics。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - 仅增加 metadata / stats 日志 needle。
- `labs/macos_bridge_smoke/README.md`
  - 仅记录 smoke diagnostics 字段和非像素级边界。
- future closure review。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。

谨慎允许：

- `labs/macos_bridge_smoke/native/cjgui_macos.h`
  - 仅当内部声明无法避免，且不得新增 public runtime API。

禁止：

- 修改 `labs/macos_bridge_smoke/src/main.cj`，除非 execution card 明确批准。
- 修改 `build_and_run.sh`，除非 execution card 明确批准。
- 新增正式 runtime 目录。
- 新增 public GUI API。
- 新增 Renderer / Scene。
- 新增 Widget / Layout / DSL。
- 新增跨平台 diagnostics abstraction。
- 引入 JSON schema / parser，除非 execution card 明确批准。
- 引入重型 GUI 测试框架。

## 12. 如何避免 metadata 变成正式 Renderer / Scene API

规则：

- 文档中始终称为 `smoke diagnostics` 或 `bridge diagnostics`。
- 不使用 `RendererFrame`、`SceneFrame`、`WidgetFrame` 这类名称。
- 不记录 scene id。
- 不记录 widget / layout 信息。
- 不把字段写进 public runtime API。
- 不把字段写成跨平台 contract。
- 不让 demo 反向定义未来 Renderer / Scene。
- 每个 closure review 必须说明 metadata 不是像素级验证，也不是 Renderer / Scene truth。

如果后续需要 Renderer / Scene 级 diagnostics：

- 必须另开 preflight。
- 必须重新定义 renderer owner、scene truth 和 render command 输入。

## 13. 如何避免 clear color metadata 被误当成真实像素验证

clear color metadata 只能表达：

> bridge 准备使用或已经提交给 render pass 的 clear color 意图。

它不能表达：

- 屏幕上真实颜色。
- drawable 最终像素。
- Metal command 是否产生了正确 bytes。
- 被遮挡窗口的可见结果。
- GPU / compositor 最终呈现结果。

closure review 必须写清楚：

- `clear_color` 是 intended render metadata。
- `clear_color` 不是 screenshot。
- `clear_color` 不是 readback。
- `clear_color` 不能替代 pixel diff。

如果未来想证明颜色真实正确，必须进入：

- Metal readback。
- screenshot / window screenshot。
- frame hash。
- pixel diff。
- offscreen renderer。

这些都需要单独 execution card。

## 14. closure review 可以接受什么证据

未来第一刀 closure review 可以接受：

- execution card 路径。
- 实际 write set。
- 新增 metadata / stats 日志格式。
- `verify_auto_close.sh` 的执行命令。
- 日志路径。
- metadata / stats expected needles 全部存在。
- `degraded_reason=none` 或明确 degraded reason。
- `render_attempt_count` 合理。
- `first_frame_submitted=true`。
- 如果实现了 `first_frame_committed`，必须说明它的真实语义。
- 明确声明“这不是像素级验证”。

closure review 不能接受：

- 把 `clear_color` 写成像素正确。
- 把 metadata 写成 screenshot。
- 把 first-frame stats 写成完整 render verification。
- 把 smoke diagnostics 写成正式 runtime API。
- 把 JSON line 写成稳定公共协议，除非已有 execution card 明确批准。

## 15. 当前 stop-line

本轮强制 stop-line：

- 不实现 frame metadata。
- 不实现 render stats。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 `verify_auto_close.sh`。
- 不实现自动截图。
- 不实现 window screenshot。
- 不实现 Metal readback。
- 不实现 frame hash。
- 不实现 pixel diff。
- 不实现 offscreen renderer。
- 不设计正式 Renderer / Scene。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本、输入法、无障碍。
- 不做 AI semantic tree / Action Router。
- 不引入重型 GUI 测试框架。
- 不把当前 smoke demo 宣称为正式 runtime。

额外保持：

- 不把 metadata 当作像素正确性的证明。
- 不把 diagnostics 变成 public runtime API。
- 不把 clear color metadata 写成真实屏幕颜色。
- 不把 future renderer 的字段提前塞进 smoke。

## 16. 结论

本轮结论：

- 当前 `verify_auto_close.sh` 已能机器复核构建、生命周期、Metal capability、first-frame-submitted 日志、自动关闭和返回码。
- 当前仍不能自动验证真实像素、截图、Metal readback、frame hash、pixel diff 或 offscreen renderer。
- frame metadata / render stats 的近期价值是让 first-frame evidence 更细、更可复核，而不是证明像素正确。
- 第一阶段 owner 应是 bridge 提供脱水 diagnostics，verification harness 消费并断言，future renderer 暂不参与。
- metadata 不允许暴露平台对象。
- 第一阶段优先输出脱水日志；JSON line、diagnostics struct、harness output 都需要单独 execution card 决定。
- 本轮不允许修改 Objective-C bridge、`verify_auto_close.sh` 或任何 smoke 代码。
- 本轮不实现 frame metadata / render stats。

下一步不自动进入实现。

如果继续推进，推荐下一条 docs-only opening：

- `P1 frame metadata / render stats execution card`

它只能授权一个极窄 first slice，且必须继续禁止截图、Metal readback、frame hash、pixel diff、offscreen renderer、Renderer / Scene、Widget / Layout / DSL 和跨平台抽象。
