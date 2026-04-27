# P1 Frame Hash Source Normalization Evidence Closure / Next-boundary Preflight

日期：2026-04-26

性质：docs-only / evidence closure review / next-boundary preflight / no implementation

状态：完成；不批准直接实现

范围：复核 `P1 frame hash source normalization readiness diagnostics first slice` 的 evidence，并判断下一条 source normalization 边界应优先冻结哪一项。本轮不实现 source normalization，不修改 harness，不修改 `labs/macos_bridge_smoke`，不保存或输出 hash value，不建立 baseline / golden hash，不做 baseline compare、pixel diff 或 offscreen renderer。

## 1. 背景

本轮依据：

- [P1 frame hash source normalization readiness diagnostics closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md)
- [P1 frame hash source normalization policy execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md)
- [P1 frame hash source normalization policy preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)
- [P1 frame hash baseline owner / update policy closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)
- [P1 frame hash baseline-readiness diagnostics closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [P1 frame hash feasibility closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [P1 user-visible window screenshot verification closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [P1 pixel diff / frame hash prerequisites preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)

当前最新 evidence 状态必须按下面这些字段理解：

```text
source=target_window_screenshot_crop
source_truth=user_visible_screenshot
source_normalized=false
blocked_reason=source_policy_incomplete
baseline_allowed=false
hash_value_persistence_allowed=false
pixel_diff_allowed=false
success=true reason=none
```

其中 `success=true reason=none` 只表示 source normalization readiness diagnostics 成功输出；它不表示 source 已 normalized，不表示 baseline 允许，不表示 hash value 可持久化，也不表示 pixel diff 可开启。

## 2. Diagnostics 已经证明什么

本轮 readiness diagnostics first slice 可以证明：

- 现有 screenshot verification harness 可以在不改变 capture、artifact lifecycle、frame hash feasibility、baseline readiness 和 baseline owner policy 语义的前提下，输出一组 source normalization readiness diagnostics。
- 当前 frame hash source 仍被固定为 `target_window_screenshot_crop`。
- 当前 source truth 仍被固定为 `user_visible_screenshot`，即 OS / WindowServer / compositor 之后的用户可见截图证据，而不是 Metal readback truth 或 offscreen renderer truth。
- harness 可以诚实输出 `source_normalized=false` 和 `blocked_reason=source_policy_incomplete`。
- readiness diagnostics 可以继续保持 `baseline_allowed=false`、`hash_value_persistence_allowed=false`、`pixel_diff_allowed=false`。
- 原有 screenshot verification、frame hash feasibility、baseline readiness、baseline owner policy、artifact cleanup、artifact lifecycle 和 auto-close 验证语义仍然存在。

这些结论只说明“诊断面可以表达当前阻塞状态”，不说明“阻塞已经解除”。

## 3. Diagnostics 没有证明什么

当前 diagnostics 没有证明：

- source image 已经 normalized。
- 当前 hash 输入矩形已经冻结。
- `screen_bounds_points`、`capture_bounds_pixels`、`target_window_crop_bounds` 和 `content_interior_bounds` 已经被区分并建立转换规则。
- scale 已经可以作为 baseline normalization contract。
- color space 已经定义。
- pixel format 已经定义。
- window decoration 是否进入 hash 输入已经冻结。
- first frame、compositor presentation、screenshot request 和 auto-close 之间的 timing 已经稳定。
- CI / headless 环境可复核。
- hash value 可以保存、输出或写入仓库。
- baseline / golden hash 可以建立。
- baseline compare 可以执行。
- pixel diff 可以开启。

也就是说，当前 diagnostics 是“下一步应该冻结什么”的证据，不是“可以开始 regression baseline”的证据。

## 4. 为什么必须保持 `source_normalized=false`

`source_normalized=false` 必须继续保持，因为 source normalization 仍缺少最基础的输入契约：

- 还没有定义到底 hash 哪个矩形。
- 还没有区分窗口枚举返回的 point-space bounds 与截图 artifact 的 pixel-space bounds。
- 还没有定义 point 到 pixel 的转换和 rounding 规则。
- 还没有定义 target-window crop 是否包含 title bar、shadow、rounded corner、traffic-light buttons 等 window decoration。
- 还没有定义 content interior 与 window frame 的关系。
- 还没有定义 scale、color space、pixel format 和 timing 对 source 的约束。
- 还没有定义 CI / headless 下无法获得同等 source 时应如何分类。

只要这些契约没有冻结，`target_window_screenshot_crop` 就只能作为当前运行内 evidence source，不能成为 normalized source。

## 5. 为什么必须保持 `baseline_allowed=false`

`baseline_allowed=false` 必须继续保持，因为 baseline 至少需要：

- normalized source。
- 明确的 human baseline owner。
- 明确的 baseline creation / update / rejection / defer 流程。
- 可审查的 artifact retention policy。
- 可解释的 hash value persistence policy。
- 可复核的 source environment 和 failure classification。
- 可区分 screenshot source、Metal readback source 和 offscreen renderer source 的 truth 边界。

当前这些条件仍未满足。尤其是 source normalization 未完成时，即使当前本机可以计算 hash，也不能把这个 hash 提升为 baseline / golden hash。

## 6. 为什么不能保存或输出 hash value

当前不能保存或输出 hash value，原因是：

- source 尚未 normalized，hash value 会绑定未冻结的 crop、scale、decoration、color space、pixel format 和 timing。
- 一旦 hash value 进入日志、文档或仓库，容易被误读为 golden value。
- artifact retention policy 仍禁止成功 screenshot artifact 长期保留，hash value 也不能绕过该隐私与清理边界。
- baseline owner / update policy 当前仍不允许 AI 自动更新 baseline，也不允许无 owner 的长期 hash 存档。
- 当前 hash feasibility 的目的只是证明“当前运行内可以计算”，不是产出 regression truth。

因此，hash 可以在运行内被计算以证明 feasibility，但不能被输出、保存、提交或写入文档。

## 7. 为什么不能进入 Baseline / Golden Hash

不能进入 baseline / golden hash，因为：

- source normalization 未完成。
- baseline owner 尚未对 source、artifact、hash、环境和更新流程作出批准。
- 成功 screenshot artifact 不允许作为 baseline 输入被保留。
- failure artifact 只能服务短期诊断，不能升级为 baseline artifact。
- 当前 `target_window_screenshot_crop` 仍混入用户可见环境因素，包括窗口状态、遮挡、display、Space、frontmost app、timing 和 compositor 行为。
- 当前没有 CI / headless 可复核策略。

baseline / golden hash 必须等 source normalization、owner approval、artifact policy、environment policy 都成形后再讨论。

## 8. 为什么不能进入 Baseline Compare

baseline compare 依赖一个已批准、可追溯、可复核的 baseline。当前没有 baseline，也没有可保存的 hash value，因此 baseline compare 没有合法输入。

如果现在执行 compare，会出现两个问题：

- mismatch 可能来自 crop、scale、decoration、timing、color space、artifact 编码或环境差异，而不是 render failure。
- pass 也只能说明某个未规范化输入在当前环境下重复相等，不能证明用户可见 UI 回归安全。

所以 baseline compare 继续禁止，且任何 readiness / policy failure 都不能被写成 render failure。

## 9. 为什么不能进入 Pixel Diff

pixel diff 比 frame hash 需要更多前置条件：

- 稳定 source image。
- 明确 crop semantics。
- 明确 scale normalization。
- 明确 color space 与 pixel format。
- 明确透明度、window decoration 和 compositor 行为。
- 明确 threshold、anti-aliasing、Retina scale、display profile 和 timing 策略。
- 明确 baseline artifact 与 privacy / cleanup policy。
- 明确 CI / headless 是否可复核。

当前已有的 `3x3` clear-color sample 只证明一个极窄 interior sample 可以通过；当前 frame hash feasibility 也只证明当前运行内可以计算 hash summary。二者都不是 pixel diff 的前置完成证明。

因此 pixel diff 不能作为下一步。

## 10. 为什么当前 Screenshot Crop Hash 不能作为长期 Regression Truth

当前 screenshot crop hash 不能作为长期 regression truth，因为：

- 当前 hash value 没有输出、没有持久化，也不应输出或持久化。
- 当前 source 仍是 `target_window_screenshot_crop`，但没有冻结 hash 输入矩形。
- 当前 source truth 是 `user_visible_screenshot`，会受到 OS / WindowServer / compositor / display presentation 环境影响。
- 当前没有冻结 window decoration 是否进入 hash。
- 当前没有冻结 screenshot request timing 与 presentation settle。
- 当前没有冻结 color space、pixel format、scale 和 artifact 编码。
- 当前没有 CI / headless 可复核结论。
- 当前没有 human owner 批准 baseline。

所以它只能作为 feasibility / readiness evidence，不能成为长期 regression truth。

## 11. 下一条边界候选项评估

候选项：

- `bounds / crop semantics`
- `scale`
- `color space`
- `pixel format`
- `window decoration`
- `timing / presentation settle`
- `CI / headless classification`

评估：

- `bounds / crop semantics` 是第一优先级。当前 source 是 `target_window_screenshot_crop`，但还没有冻结到底 hash 哪个矩形。
- `scale` 很重要，但 scale 归一化依赖 bounds 语义；先定义 scale 而不定义矩形，会导致 point / pixel 转换没有锚点。
- `color space` 很重要，但在不知道 hash 输入区域之前，先定义颜色空间容易变成空中楼阁。
- `pixel format` 很重要，但同样依赖输入区域和 artifact / decoded buffer 的选择。
- `window decoration` 是否进入 hash，直接取决于 crop semantics。
- `timing / presentation settle` 会影响 source 稳定性，但需要先知道要 capture / hash 的矩形。
- `CI / headless classification` 可以继续延后，因为当前还没有 baseline 资格，也没有 normalized source。

## 12. 推荐下一条边界

推荐下一条 docs-only opening：

> `P1 frame hash bounds / crop semantics policy preflight`

推荐理由：

- 当前 source 已固定为 `target_window_screenshot_crop`，但 hash 输入矩形还没有被冻结。
- 必须先区分 `screen_bounds_points`、`capture_bounds_pixels`、`target_window_crop_bounds` 和 `content_interior_bounds`。
- point-space 到 pixel-space 的转换、rounding、display origin、多显示器和 Retina scale 都需要依赖 bounds 语义。
- window decoration 是否进入 hash 也依赖 crop 语义。
- scale、color space、pixel format 和 timing 都需要在“哪个矩形是 source”明确后才有稳定意义。
- CI / headless classification 可以继续作为后续边界，因为当前没有 baseline 资格。

下一篇文档应只冻结 policy，不实现 normalization；它应回答：

- 哪些 bounds 字段允许作为 diagnostics。
- 哪个 bounds 未来可能进入 hash input。
- point-space / pixel-space 如何区分。
- target window frame 与 content interior 是否分离。
- decoration 是否允许进入 future hash source。
- bounds unknown / mismatch / occluded 时如何分类。
- 为什么仍不允许 hash value persistence、baseline、baseline compare 或 pixel diff。

## 13. 本轮 Stop-line

本轮强制保持：

- 不实现 source normalization。
- 不修改 harness。
- 不修改 `labs/macos_bridge_smoke`。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 14. Next Opening

当前没有自动开启的直接实现 opening。

下一步推荐创建 docs-only：

> `P1 frame hash bounds / crop semantics policy preflight`

该 opening 仍不自动开启实现；它只应冻结 bounds / crop semantics policy，不得进入 source normalization implementation、hash value persistence、baseline / golden hash、baseline compare、pixel diff、offscreen renderer、native bridge、public runtime API 或 Renderer / Scene / Widget / Layout / DSL。
