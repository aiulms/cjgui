# P1 Frame Hash Bounds / Crop Semantics Policy Preflight

日期：2026-04-26

性质：docs-only / bounds-crop-semantics policy preflight / no implementation

状态：完成；不批准直接实现

范围：冻结 `target_window_screenshot_crop` 作为 frame hash source 时的 bounds / crop semantics policy。本轮只定义未来讨论 hash / baseline / pixel diff 时“哪个矩形”才可能有资格作为 source input；不实现 bounds normalization，不修改 harness，不修改 `labs/macos_bridge_smoke`，不保存或输出 hash value，不建立 baseline / golden hash，不做 baseline compare、pixel diff 或 offscreen renderer。

## 1. 背景

本轮依据：

- [P1 frame hash source normalization evidence closure / next-boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md)
- [P1 frame hash source normalization readiness diagnostics closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md)
- [P1 frame hash source normalization policy preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)
- [P1 frame hash source normalization policy execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md)
- [P1 frame hash feasibility closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [P1 user-visible window screenshot verification closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [P1 screenshot artifact retention closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)
- [P1 pixel diff / frame hash prerequisites preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)

当前必须继续保持：

```text
source=target_window_screenshot_crop
source_truth=user_visible_screenshot
source_normalized=false
baseline_allowed=false
hash_value_persistence_allowed=false
pixel_diff_allowed=false
```

本轮结论不改变这些字段。

## 2. 四类 Bounds 定义

### 2.1 `screen_bounds_points`

`screen_bounds_points` 指系统窗口枚举、窗口管理器或等价桌面 API 观察到的窗口位置与尺寸，坐标单位是屏幕逻辑点。

它的用途：

- target attribution。
- 记录目标窗口大致位于哪个桌面坐标。
- 作为未来 point-space / pixel-space 转换的输入之一。

它不是：

- screenshot artifact 的像素矩形。
- hash input。
- content interior。
- baseline source。

当前阶段，`screen_bounds_points` 只能作为 diagnostics。它可能受多显示器 origin、负坐标、Space、Mission Control、窗口 frame、系统 decoration 和 active / inactive state 影响。

### 2.2 `capture_bounds_pixels`

`capture_bounds_pixels` 指截图 artifact 实际产生的像素区域或像素尺寸。

它的用途：

- 描述 capture 输出真实有多少像素。
- 与 `screen_bounds_points` 一起推导或诊断 scale。
- 判断 capture 是否覆盖目标窗口 bounds。

它不是：

- 系统窗口枚举的 point-space bounds。
- 自动等同于目标窗口完整 frame。
- 自动等同于 content interior。
- baseline input contract。

当前阶段，`capture_bounds_pixels` 仍只能作为 diagnostics。它依赖 Retina scale、display scale、capture API、rounding、PNG / image representation 和多显示器环境。

### 2.3 `target_window_crop_bounds`

`target_window_crop_bounds` 指 harness 以目标窗口为对象请求截图时使用的 crop 区域。

当前 source 名称 `target_window_screenshot_crop` 指向的就是这类 evidence：用户可见窗口截图的目标窗口 crop。

它的用途：

- 作为当前 frame hash feasibility 的 source label。
- 作为当前运行内临时 screenshot artifact 的来源。
- 支撑 target-window attribution、`3x3` clear-color sample 和当前运行内 hash feasibility summary。

它不是：

- 已 normalized 的 hash input。
- 长期 baseline source。
- content-only source。
- Metal readback truth。
- Renderer / Scene truth。

当前 `target_window_crop_bounds` 可能包含 title bar、shadow、rounded corner、traffic-light buttons、透明边缘和系统 compositor 后结果。它不能直接升级为 baseline input contract。

### 2.4 `content_interior_bounds`

`content_interior_bounds` 指未来 GUI 内容区域的内侧矩形。它应尽量排除 title bar、shadow、rounded corner、traffic-light buttons、系统主题 decoration 和 active / inactive decoration 噪音。

长期上，它更适合成为 frame hash source input，因为：

- 更接近 GUI runtime 真正绘制的内容区域。
- 减少系统窗口 decoration 噪音。
- 降低 macOS 主题、窗口激活状态、阴影和 rounded corner 对 hash 的影响。
- 更容易与未来 Renderer / Scene 的内容 truth 对齐。

但当前不能实现 `content_interior_bounds` extraction，因为：

- 当前没有正式 runtime view / content geometry API。
- 当前不能修改 native bridge。
- 当前不能新增 public C ABI / runtime API。
- 当前不能把 AppKit / CoreGraphics / NSView 几何暴露为公共契约。
- 当前没有 Renderer / Scene / Widget / Layout / DSL。

因此 `content_interior_bounds` 是未来倾向，不是本轮实现或当前可用 source。

## 3. 当前 Harness 已经观测到哪些 Bounds

当前 closure evidence 显示，screenshot verification / frame hash feasibility harness 已经观测到：

- `target_pid_observed=true`
- `window_title_matched=true`
- `window_bounds_observed=true`
- `target_bounds=<x,y,w,h>`，例如 closure 中记录过 `397,140,718,446` 或 frame hash feasibility 中的 `397,139,718,448`
- `capture_covers_target_bounds=true`
- `scale_observed=true`
- frame hash feasibility summary 中曾输出 `bounds=<target_bounds>` 与 `scale=2.00`

这些字段足以说明：

- 当前本机一次运行可以归属目标 smoke window。
- 当前可以围绕目标 window bounds 请求截图。
- 当前可以观察 target bounds 与 capture 输出之间的关系。

这些字段仍不能说明：

- 哪个 bounds 是正式 hash input。
- point-space 与 pixel-space 转换已经冻结。
- whole window crop 可以作为 baseline input。
- content interior 已经可观测。
- source 已 normalized。

## 4. 当前哪些 Bounds 只能作为 Diagnostics

当前以下内容都只能作为 diagnostics：

- `screen_bounds_points`
- `capture_bounds_pixels`
- `target_window_crop_bounds`
- `target_bounds=<x,y,w,h>`
- `capture_covers_target_bounds=true|false|unknown`
- `scale=<value|unknown>`
- `scale_observed=true|false|unknown`

原因：

- 它们还没有统一 owner。
- 它们没有被写成长期 source contract。
- 它们没有与 content interior 建立映射。
- 它们还没有处理多显示器、negative origin、Retina scale、rounding 和 decoration。
- 它们不能绕过 artifact retention、baseline owner 和 source normalization policy。

## 5. 未来哪个 Bounds 有可能成为 Hash Input

长期更合理的候选是：

> `content_interior_bounds`

理由：

- frame hash 应尽量绑定 GUI 内容，而不是系统窗口装饰。
- content interior 更能减少 title bar、shadow、rounded corner、traffic-light buttons 和 active / inactive state 带来的非内容噪音。
- 它更容易与未来 Renderer / Scene 的内容输出建立关系。

短期仍可能继续使用：

> `target_window_crop_bounds`

但只能作为 diagnostics / readiness / feasibility source，不能直接作为 baseline input contract。

如果未来要把 `target_window_crop_bounds` 暂时作为 hash input，至少需要另开 execution card，并显式记录：

- decoration included。
- content interior unavailable。
- source 仍非 normalized 或仅为 interim normalized。
- baseline 仍不允许，除非 source normalization、owner approval、artifact policy、CI / headless policy 全部另行满足。

## 6. 为什么不能把 Whole Window Crop 直接作为长期 Baseline Source

不能直接把 target window whole crop 当作长期 baseline source，原因包括：

- whole crop 可能包含 title bar。
- whole crop 可能包含 shadow。
- whole crop 可能包含 rounded corner。
- whole crop 可能包含 traffic-light buttons。
- active / inactive window state 会改变 decoration。
- 系统主题、macOS 版本、显示设置、透明度和 compositor 可能改变边缘像素。
- window bounds 可能是 point-space，而 artifact 是 pixel-space。
- Retina scale 与 rounding 可能导致边缘一像素差异。
- 多显示器和 negative origin 可能影响坐标转换。
- screenshot request timing 可能影响 compositor 后结果。
- 当前没有 CI / headless 可复核策略。
- 当前成功 screenshot artifact 默认删除，不能成为 baseline input。

whole window crop 当前只能作为用户可见截图 evidence source，不能升级为长期 regression truth。

## 7. Point-space / Pixel-space 区分

未来必须明确：

- `screen_bounds_points` 使用逻辑点。
- `capture_bounds_pixels` 使用像素。
- `target_window_crop_bounds` 必须声明它的输入坐标空间和输出 artifact 像素空间。
- `content_interior_bounds` 必须声明它相对于 window frame、content view 还是 screenshot artifact。

当前不能用一个 `bounds=x,y,w,h` 字段同时表达 point-space 和 pixel-space。

未来 policy 至少要回答：

- point 到 pixel 的 scale 来源是什么。
- 坐标转换发生在 capture 前还是 artifact 后。
- rounding 使用 floor、ceil、round 还是 outward-inclusive。
- 多显示器下 display origin 如何处理。
- negative origin 是否允许。
- scale unknown 或 scale mismatch 时如何降级。

## 8. Retina Scale、Multi-display、Negative Origin、Rounding 风险

### 8.1 Retina Scale

风险：

- macOS window bounds 常以 points 表达。
- screenshot artifact 常以 pixels 表达。
- `scale=2.00` 只说明当前运行中可观察，不是长期 normalization contract。

当前策略：

- scale 只能作为 diagnostics。
- `scale_observed=true` 不等于 `scale_policy_defined=true`。
- scale mismatch 时不得进入 baseline。

### 8.2 Multi-display

风险：

- 不同 display 可能有不同 scale。
- window 可能跨 display。
- display origin 和 coordinate space 可能变化。

当前策略：

- 多显示器下无法确认单一 display / scale 时，应分类为 `multi_display_ambiguous`、`scale_mismatch` 或 `unknown`。
- 不允许把多显示器坐标问题写成 render failure。

### 8.3 Negative Origin

风险：

- macOS 多显示器布局可能产生负坐标。
- capture rect 与 artifact origin 之间可能不是简单一一对应。

当前策略：

- negative origin 未冻结前只能作为 diagnostics。
- 不能把 negative origin 下的 target crop 直接作为 baseline input。

### 8.4 Rounding

风险：

- point 到 pixel 转换可能产生非整数边界。
- 不同 rounding 会改变一圈边缘像素。
- rounded corner / shadow / alpha 区域尤其容易受影响。

当前策略：

- rounding policy 未冻结前，不能建立 frame hash baseline。
- 如果未来检测到 rounding mismatch，应分类为 `bounds_mismatch` 或 `source_not_normalized`，不是 render failure。

## 9. Window Decoration 是否进入 Future Hash Source

长期倾向：

> window decoration 不应进入正式 frame hash source。

原因：

- title bar 由系统绘制，不是 GUI runtime 内容真相。
- shadow 和 rounded corner 是 compositor / OS decoration 噪音。
- traffic-light buttons 受系统主题、active state、hover state 和 macOS 版本影响。
- active / inactive state 会改变 title bar、按钮、阴影和透明度。
- decoration diff 不能可靠归因于 render failure。

短期如果必须使用 `target_window_crop_bounds`：

- 必须明确 `decoration_included=true`。
- 必须继续禁止 baseline。
- 必须把 decoration mismatch 与 render failure 分开。
- 必须记录这是 user-visible screenshot evidence，不是 Renderer / Scene truth。

## 10. Content Interior 是否应优先成为 Future Source

结论：

> 是，长期应优先考虑 `content_interior_bounds`。

理由：

- 它更贴近 GUI 内容。
- 它避免系统 decoration 被 hash。
- 它更适合未来 Renderer / Scene 稳定后做 regression。
- 它更可能跨系统主题、active state 和窗口装饰变化保持稳定。

当前不能实现：

- 没有正式 runtime view / content geometry API。
- 没有公共 handle / generation / view geometry contract。
- 不能修改 native bridge。
- 不能新增 public C ABI / public runtime API。
- 不能为了验证提前设计 Renderer / Scene / Widget / Layout / DSL。

因此本轮只能冻结 policy，不能实现 content interior extraction。

## 11. Failure Classification

未来 bounds / crop semantics 至少需要这些分类：

- `bounds_unknown`：无法观察目标窗口 bounds，或无法确认 bounds 来源。
- `bounds_mismatch`：window bounds、capture bounds 或 artifact bounds 不一致，且无法按已知 scale / rounding 解释。
- `window_not_visible`：目标窗口存在但不可见、隐藏、最小化或不在当前 Space。
- `window_occluded`：目标窗口被遮挡，不能信任用户可见 screenshot source。
- `multi_display_ambiguous`：目标窗口跨 display 或无法确认 display / origin / scale。
- `scale_mismatch`：observed scale 与 capture artifact 或 display scale 不一致。
- `target_mismatch`：capture 结果不能确认来自目标 smoke window。
- `source_not_normalized`：bounds / crop / scale / decoration policy 不完整。
- `unknown`：证据不足，不能伪装成更具体分类。

分类规则：

- bounds / scale / display / visibility failure 不能写成 render failure。
- decoration mismatch 不能写成 render failure。
- target mismatch 不能写成 render failure。
- source normalization 前置不足时必须保持 `source_normalized=false`。
- 只有存在明确 render 日志证据时，才允许考虑 `render_failure`。

## 12. 为什么仍保持 `source_normalized=false`

本轮必须继续保持 `source_normalized=false`，因为：

- 只定义 policy，不实现 normalization。
- 当前 bounds 仍只是 diagnostics。
- 当前 whole window crop 仍不能作为 baseline input contract。
- 当前 content interior 不可观测。
- point-space / pixel-space 转换未冻结。
- scale、multi-display、negative origin、rounding 未冻结。
- decoration inclusion / exclusion 未冻结。
- failure classification 只冻结了建议，不是 runtime 判断。

## 13. 为什么仍保持 `baseline_allowed=false`

本轮必须继续保持 `baseline_allowed=false`，因为：

- source 未 normalized。
- hash input 矩形未实现。
- human baseline owner 尚未批准 baseline。
- artifact retention policy 禁止成功 artifact 长期保留。
- hash value persistence 仍不允许。
- CI / headless 可复核策略未冻结。
- pixel diff / baseline compare 前置条件未满足。

## 14. 为什么不能保存或输出 Hash Value

本轮不能保存或输出 hash value，原因是：

- source 未 normalized。
- bounds / crop semantics 只冻结 policy，没有落地为可验证 input contract。
- hash value 一旦进入日志、文档或仓库，容易被误读为 golden hash。
- artifact retention policy 不允许通过 hash value 绕过成功 artifact 删除策略。
- 没有 baseline owner 批准 hash value persistence。

## 15. 为什么不能进入 Baseline / Baseline Compare / Pixel Diff

### 15.1 Baseline / Golden Hash

不能进入，因为：

- `source_normalized=false`。
- `baseline_allowed=false`。
- hash input 矩形未实现。
- hash value persistence 不允许。
- baseline owner / update approval 尚未开启 baseline。

### 15.2 Baseline Compare

不能进入，因为：

- 没有 baseline。
- 没有可保存 hash value。
- mismatch 无法可靠归因。
- bounds / decoration / scale / timing failure 可能被误判为 render failure。

### 15.3 Pixel Diff

不能进入，因为：

- 没有 normalized source。
- 没有 baseline artifact。
- 没有整图像素读取授权。
- 没有 raw bytes policy。
- 没有 color space、pixel format、scale、alpha、threshold、anti-aliasing 和 CI / headless policy。
- 当前 `3x3` sample 与 frame hash feasibility 都不是 pixel diff 前置完成证明。

## 16. 本轮 Stop-line

本轮强制保持：

- 不实现 bounds normalization。
- 不修改 harness。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 17. Next Opening

当前没有自动开启的直接实现 opening。

下一步推荐创建 docs-only：

> `P1 frame hash bounds / crop semantics policy execution card`

该 execution card 只能把本 preflight 收束成受限授权卡。它不应自动批准实现；如果未来要实现，也最多只能授权 bounds / crop semantics readiness diagnostics，不得实现 bounds normalization、hash value persistence、baseline / golden hash、baseline compare、pixel diff、offscreen renderer、native bridge 修改、public runtime API 或 Renderer / Scene / Widget / Layout / DSL。
