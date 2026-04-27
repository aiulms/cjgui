# P1 Frame Hash Source Normalization Policy Preflight

日期：2026-04-25

性质：docs-only / source normalization policy preflight / no implementation

状态：完成；不批准直接实现

范围：冻结 `target-window screenshot crop` 作为 frame hash source 时的 source normalization 边界。本轮不实现 source normalization，不修改 harness，不保存 hash value，不建立 baseline / golden hash，不做 baseline compare 或 pixel diff。

## 1. 背景

当前已经完成：

- [P1 user-visible window screenshot verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [P1 frame hash feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [P1 frame hash baseline-readiness diagnostics first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [P1 frame hash baseline owner / update policy first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)

当前 evidence 可以证明：

- 当前本机一次 smoke 运行中，harness 可以归属目标 smoke window。
- `target_window_screenshot_crop` 可以作为一次 `user_visible_screenshot` evidence source。
- 当前运行内可以对临时 target-window crop artifact 执行 `sha256` 计算。
- hash value 没有输出、没有持久化。
- baseline compare 没有执行。
- 成功 screenshot artifact 默认删除。

当前 evidence 仍不能证明：

- source image 已经被长期规范化。
- bounds、scale、color space、pixel format、window decoration 和 timing 已经可作为 baseline contract。
- CI / headless 可复核。
- baseline / golden hash 已允许。
- pixel diff 可以开启。

## 2. 当前 Source Normalization 是否完成

结论：

> 未完成。

当前 harness 只输出 feasibility / diagnostics：

```text
cjgui frame hash feasibility: source=target_window_screenshot_crop
cjgui frame hash feasibility: source_truth=user_visible_screenshot
cjgui frame hash feasibility: bounds=<target_bounds|unknown>
cjgui frame hash feasibility: scale=<scale|unknown>
cjgui frame hash feasibility: color_space=unknown
cjgui frame hash feasibility: pixel_format=unknown
```

这些字段足够说明“当前运行内可以计算 hash feasibility summary”，但不足以说明“可以保存 hash value、建立 baseline 或做 baseline compare”。

未完成的关键项：

- bounds 语义未冻结。
- scale 归一化未冻结。
- color space 未定义。
- pixel format 未定义。
- window decoration 是否进入 crop 未冻结。
- timing / presentation 稳定性未冻结。
- CI / headless 分类策略未冻结。

## 3. Source Truth

当前唯一 source：

```text
source=target_window_screenshot_crop
source_truth=user_visible_screenshot
```

含义：

- 这是 OS / WindowServer / compositor 之后的用户可见截图证据。
- 它不是 Metal readback truth。
- 它不是 offscreen renderer truth。
- 它不是 Renderer / Scene truth。
- 它不能与 `source_truth=metal_readback` 的 hash 混用。

本轮不允许新增第二 source，也不允许把 screenshot hash 与 Metal readback hash 共用 baseline。

## 4. Bounds 语义

未来必须区分至少四类 bounds：

- `screen_bounds_points`：系统窗口枚举返回的屏幕坐标和窗口尺寸，通常服务于 target attribution。
- `capture_bounds_pixels`：实际 screenshot artifact 的像素宽高。
- `target_window_crop_bounds`：用于 capture 的目标窗口 crop 区域，可能包含窗口 frame 或 decoration。
- `content_interior_bounds`：未来 GUI 内容区域，理论上应排除 title bar、shadow、rounded corner、traffic-light buttons 等系统 decoration。

当前状态：

- harness 已能记录目标窗口 bounds 和 artifact size。
- frame hash feasibility 会从 target bounds 与 artifact size 估算 `scale`。
- 但当前没有冻结 screen point-space 与 pixel-space 的正式转换规则。
- 当前没有冻结 target-window crop 是否等同于 content interior。
- 当前没有冻结 rounding、origin、display coordinate、multi-display coordinate 或 negative origin 规则。

结论：

> 当前 bounds 只能作为脱水 diagnostics，不允许作为 baseline input contract。

未来要进入 source normalization first slice，至少要明确：

- 哪个 bounds 字段参与 hash input。
- point-space 到 pixel-space 如何转换。
- rounding 如何处理。
- crop 是否包含 window decoration。
- content interior 是否需要另行观测或推导。
- bounds unknown 时如何分类，而不是继续计算 baseline。

## 5. Scale 记录与归一化

当前状态：

- harness 可从 artifact pixel size 与 target bounds 估算 scale。
- 成功路径曾输出类似 `scale=2.00`。
- `scale_observed=true` 只说明当前运行中观察到可计算 scale。

当前不足：

- scale 的 owner 还不是正式 runtime。
- Retina scale、多显示器 scale、window 跨显示器、display profile 变化都未冻结。
- scale 估算依赖当前截图 artifact 与目标 bounds 的关系，尚未定义为长期规范。
- scale 是否用于 hash input 归一化尚未确定。

未来需要定义：

- scale 记录使用 display scale、capture scale，还是 artifact-to-bounds inferred scale。
- scale 不一致时是否降级为 `source_not_normalized`。
- 跨显示器或 scale 变化时如何分类。
- 是否允许 resample；当前倾向不允许在 P1 smoke 中引入 resample。

结论：

> 当前 scale 足够做 diagnostics，不足够做 baseline normalization。

## 6. Color Space

当前状态：

```text
color_space=unknown
color_space_defined=false
```

原因：

- 当前 frame hash feasibility 计算的是临时 screenshot artifact 文件的 `sha256` feasibility summary。
- 当前没有冻结 artifact 中是否包含 color profile、gamma、sRGB / Display P3、linear / non-linear 语义。
- 当前 `3x3` sample 为 clear-color sample summary 服务，不定义整张 source image 的 hash color space。
- 当前不应把 `sample_match=true` 误当成 source color space 已定义。

未来需要定义：

- hash input 是否必须转换为 sRGB。
- 是否保留或剥离 PNG color profile。
- 是否记录 display color profile 的脱水信息。
- 是否允许 `color_space=unknown` 进入 baseline；当前答案为不允许。
- color space 无法确认时如何分类，例如 `source_not_normalized`、`color_space_unknown` 或 `unknown`。

结论：

> color space 未定义前，不允许 baseline / golden hash。

## 7. Pixel Format

当前状态：

```text
pixel_format=unknown
pixel_format_defined=false
```

原因：

- 当前 source 是 screenshot artifact，不是 Metal texture。
- 当前没有定义 hash input 是 PNG encoded bytes、decoded pixels、premultiplied alpha、RGBA / BGRA，还是某种 canonical buffer。
- 当前不保存 raw bytes，不读取整图像素，不输出 hash value。
- 当前不能诚实声明 source image 的长期 pixel format。

未来需要定义：

- hash input 的 canonical representation。
- channel order。
- bit depth。
- alpha / premultiplication policy。
- row stride 是否参与 hash。
- PNG metadata 是否参与 hash。
- pixel format unknown 时是否必须阻塞 baseline；当前答案为必须阻塞。

结论：

> pixel format 未定义前，不允许 baseline / golden hash 或 baseline compare。

## 8. Window Decoration

需要明确的问题：

- target-window screenshot crop 是否包含 title bar。
- 是否包含 shadow。
- 是否包含 rounded corner。
- 是否包含 traffic-light buttons。
- 是否包含系统主题、active / inactive window decoration 差异。
- 是否包含透明边缘或 compositor 合成结果。

当前状态：

- 当前 harness 使用目标 bounds capture 用户可见窗口区域。
- 当前没有冻结 decoration included / excluded。
- 当前 `3x3` center sample 避开了大部分 decoration 风险，但 frame hash source 覆盖整个 crop 时不能忽略 decoration。
- 当前不能确认 target-window crop 是否足够作为 baseline source。

结论：

> 当前 window decoration policy 未冻结，不允许进入 baseline。

未来如果继续，必须先决定：

- baseline source 是 whole window crop 还是 content interior crop。
- 如果包含 decoration，如何处理 macOS 主题、active state、shadow 和 rounded corner。
- 如果排除 decoration，content interior bounds 从哪里来。
- 是否允许因 decoration mismatch 产生 failure classification，而不是 render failure。

## 9. Timing

当前相关时序：

```text
first frame rendered
-> compositor / WindowServer presentation
-> screenshot request
-> auto-close
```

当前状态：

- screenshot verification harness 等待 `cjgui: first frame rendered`。
- `first frame rendered` 说明 bridge / smoke 观测到 first frame path 完成。
- 它不等于 compositor presentation 已稳定。
- auto-close 延迟降低了竞争风险，但不是长期 timing contract。

风险：

- screenshot request 可能早于 compositor 可见更新。
- window focus / active state 可能在 request 前变化。
- auto-close 可能与 capture 竞争。
- 系统动画、Mission Control、Space 切换可能影响 capture。

未来需要定义：

- 是否需要 presentation settle delay。
- 是否需要重复 capture / stable frame confirmation。
- timing failure 如何分类：`render_not_ready`、`capture_failed`、`target_mismatch`、`window_not_visible`、`unknown`。
- 不允许把 timing / compositor failure 直接写成 render failure，除非有明确 render 日志证据。

## 10. Target Attribution 与桌面环境

source normalization 必须继续约束这些环境因素：

- `target_pid_observed`
- `window_title_matched`
- `window_bounds_observed`
- `frontmost_app_matched`
- `display_observed`
- `scale_observed`
- `capture_covers_target_bounds`
- window visibility
- Space / Mission Control
- 多显示器
- 遮挡 / window occlusion

当前规则：

- 如果无法确认目标窗口归属，不能声明 source normalized。
- 如果窗口不可见、被遮挡或不在当前 Space，不能建立 baseline。
- 如果 display 或 scale 不可观察，只能输出 unknown / degraded。
- frontmost app 不匹配不一定是 render failure，必须单独分类。

未来 first slice 最多应输出 source normalization readiness diagnostics，不应为了让 source normalized 而修改 native bridge 或正式 runtime。

## 11. CI / Headless 分类

当前结论：

> CI / headless 不可声称可复核。

如果未来在 CI / headless 下运行，应分类而不是伪装成功：

- 无 WindowServer / display：`display_unavailable`
- 无 Screen Recording 权限：`permission_denied`
- 无目标窗口：`window_not_found`
- 目标窗口不可见或不在当前 Space：`window_not_visible`
- capture API 失败：`capture_failed`
- 无法确认目标归属：`target_mismatch`
- source normalization 前置不足：`source_not_normalized` 或 `unknown`

在 CI / headless 策略未冻结前：

- 不允许 baseline compare。
- 不允许把 skipped / unavailable 写成 pass。
- 不允许把 display / permission failure 写成 render failure。
- 不允许建立依赖本机桌面环境的长期 baseline。

## 12. Hash Value / Baseline / Pixel Diff

本轮明确回答：

- 当前是否允许保存 hash value：不允许。
- 当前是否允许把 hash value 写入日志、文档或仓库：不允许。
- 当前是否允许 baseline / golden hash：不允许。
- 当前是否允许 baseline compare：不允许。
- 当前是否允许 pixel diff：不允许。
- 当前是否允许保存成功 screenshot artifact：不允许。
- 当前是否允许保存 raw bytes：不允许。

原因：

- source normalization 未完成。
- baseline owner / update policy 虽已冻结为 human-only，但还没有批准 baseline。
- artifact retention policy 仍禁止成功 artifact 长期保留。
- color space / pixel format unknown。
- CI / headless 不可复核。
- 当前 smoke demo 不是正式 GUI runtime。

## 13. Baseline Owner / Update Policy 与 Source Normalization 的关系

baseline owner 不能绕过 source normalization。

即使未来 human owner 明确签署：

- source normalization 未冻结时，`baseline_allowed=false` 必须继续成立。
- proposal 只能记录 unknown / degraded。
- 不能保存 hash value。
- 不能建立 baseline。
- 不能执行 baseline compare。

source normalization 是 baseline creation / update 的前置条件之一，不是 owner approval 的替代品。

反过来，source normalization 也不能绕过 owner / update policy：

- 即使未来 source normalized，baseline 仍需要 human owner、human review、artifact baseline storage、hash value storage / deletion policy、CI / headless policy 和 mismatch classification。
- AI 仍不能自动更新 baseline。

## 14. Future Execution Card 最大边界

如果继续推进，下一张最多只能是 docs-only：

> `P1 frame hash source normalization policy execution card`

该 execution card 最多只能授权未来一个极窄 first slice：

- 在现有 screenshot verification harness 或 closure flow 中输出 source normalization readiness diagnostics。
- 继续只使用 `target_window_screenshot_crop`。
- 继续只声明 `source_truth=user_visible_screenshot`。
- 继续保持 `baseline_allowed=false`。
- 继续不保存 hash value。
- 继续不建立 baseline / golden hash。
- 继续不做 baseline compare。
- 继续不做 pixel diff。
- 继续不保存成功 screenshot artifact。

它不能授权：

- 真正 baseline / golden hash。
- hash value persistence。
- pixel diff。
- baseline compare。
- raw bytes 保存。
- offscreen renderer。
- native bridge 修改。
- public C ABI / runtime API。
- Renderer / Scene / Widget / Layout / DSL。

如果未来执行卡想把 unknown 字段改为 defined / normalized，必须逐项说明依据、write set、验证证据和 fallback classification。

## 15. Stop-line

本轮明确不做：

- 不实现 source normalization。
- 不修改 screenshot verification harness。
- 不保存 hash value。
- 不把 hash value 写入日志、文档或仓库。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不保存成功 screenshot artifact。
- 不保存 raw bytes。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 `verify_auto_close.sh`。
- 不修改 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 16. Next Opening

当前没有自动开启的直接实现 opening。

推荐下一步仍为 docs-only：

> `P1 frame hash source normalization policy execution card`

该 execution card 必须继续禁止 source normalization implementation、baseline / golden hash、hash value persistence、baseline compare、pixel diff、raw bytes 保存、成功 screenshot artifact 保留、offscreen renderer、native bridge 修改、public runtime API 和 Renderer / Scene。
