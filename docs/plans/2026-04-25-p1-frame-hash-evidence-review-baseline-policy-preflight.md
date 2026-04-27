# P1 Frame Hash Evidence Review / Baseline Policy Preflight

日期：2026-04-25

性质：docs-only / baseline policy preflight / frame hash evidence review

状态：完成；不批准直接实现

范围：复核 `frame hash feasibility` evidence 之后，冻结是否、何时、以什么边界允许 baseline / golden hash。本轮不实现 baseline，不实现 pixel diff，不做 baseline compare，不修改 harness 或 runtime。

## 1. 背景

当前已经完成：

- [P1 automated GUI verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [P1 frame metadata / render stats first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [P1 Metal readback feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [P1 user-visible window screenshot verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [P1 screenshot artifact retention first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)
- [P1 frame hash feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)

当前 frame hash feasibility first slice 已经做到：

- source 只选择 `target_window_screenshot_crop`。
- source truth 只声明为 `user_visible_screenshot`。
- 在当前运行内对临时 target-window crop artifact 执行 `sha256` 计算。
- 丢弃 hash 输出，只记录 `hash_computed=true`。
- 明确 `hash_persisted=false`、`hash_value_logged=false`、`baseline_compared=false`。
- 成功路径继续删除 screenshot artifact，并输出 `artifact_deleted=true`、`artifact_retained=false`。

本 preflight 要回答：

> 这些 evidence 是否已经足以允许 baseline / golden hash？

结论先行：

> 当前不允许建立 baseline / golden hash，也不允许保存 hash value 或把 hash value 写入日志、文档、仓库。

## 2. 当前 Evidence 证明了什么

当前 evidence 可以证明：

- 当前本机、当前桌面会话、当前 smoke 运行期间，可以归属目标 smoke window。
- `target_window_screenshot_crop` 可以作为一次 user-visible screenshot evidence source。
- harness 可以在临时 artifact 存在期间计算 `sha256`。
- harness 可以不输出 hash value、不持久化 hash、不做 baseline compare。
- 成功路径仍遵守 artifact retention policy，删除 artifact 和临时目录。
- 原有 readiness、target attribution、`3x3` clear-color sample、artifact lifecycle 和 auto-close harness 没有被破坏。

当前 evidence 不能证明：

- frame hash 在不同机器、不同显示器、不同 Space、不同 scale 或不同时间下稳定。
- 该 hash 可作为 regression baseline。
- screenshot 内容总是无遮挡、frontmost、来自目标窗口且不含系统偶然性。
- `target_window_screenshot_crop` 的颜色空间和 pixel format 已被完整定义。
- CI / headless 环境可以复核同一 hash。
- Metal render target hash 与 screenshot hash 可以互相替代。
- 未来 Renderer / Scene / Widget / Layout 的视觉输出已经有稳定 truth。
- 当前 smoke demo 是正式 GUI runtime。

## 3. 当前是否允许建立 Baseline / Golden Hash

结论：

> 不允许。

不允许的具体范围：

- 不允许建立 baseline / golden hash。
- 不允许建立 baseline / golden image。
- 不允许做 baseline compare。
- 不允许把 hash mismatch 写成 render failure。
- 不允许保存 hash value。
- 不允许把 hash value 写入日志、文档或仓库。
- 不允许长期保存 hash value。
- 不允许保存成功 screenshot artifact 作为 baseline 输入。
- 不允许把失败 artifact 自动提升为 baseline artifact。

原因：

- 当前只有单次本机 success evidence，没有跨环境稳定性证据。
- 当前 source 是 user-visible screenshot crop，仍受桌面环境影响。
- 当前没有 baseline owner。
- 当前没有 baseline update 审批规则。
- 当前没有 baseline storage / retention / deletion 规则。
- 当前没有 hash input normalization contract。
- 当前没有 CI / headless 可复核策略。
- 当前没有 Renderer / Scene truth。

## 4. 缺失的前置条件

在允许 baseline / golden hash 前，至少缺少这些前置条件：

- baseline owner。
- baseline update 审批流程。
- human review 要求。
- source image 的唯一 truth 选择。
- hash input normalization 规则。
- bounds / scale / color space / pixel format / alpha / decoration policy。
- target-window crop 是否包含 title bar、shadow、rounded corner、traffic-light buttons 的规则。
- artifact 隐私策略。
- hash value 存储位置、生命周期、删除策略和访问权限。
- CI / headless 运行分类规则。
- mismatch classification。
- 不把 permission / display / target / visibility failure 写成 render failure 的硬规则。
- 与 Metal readback evidence 的边界。
- 与未来 Renderer / Scene evidence 的边界。

这些前置条件未冻结前，baseline / golden hash 不能进入实现。

## 5. Baseline / Golden Hash Owner

当前 owner：

> 未设立。

未来可能的 owner 分工：

- verification harness owner：负责截图 / artifact / cleanup / failure classification。
- renderer / scene owner：未来负责稳定 render input、scene truth、render output semantics。
- test harness owner：未来负责 CI matrix、环境分类、失败报告。
- human architect / maintainer：负责批准 baseline creation 和 baseline update。

当前 P1 smoke 阶段不应由任何一个局部 harness 独占 baseline owner。

建议：

- baseline owner 必须是显式文档化的角色，而不是由当前脚本自然继承。
- baseline update 必须有人类审核。
- AI 可以生成候选报告，但不能自动更新 baseline / golden hash。

## 6. AI 是否允许自动更新 Baseline

结论：

> 不允许。

原因：

- AI 自动更新 baseline 会把一次成功运行误提升为 truth。
- 当前 smoke 画面过窄，容易把 demo 偶然性写成长期契约。
- 截图 source 可能受遮挡、权限、显示器、scale、timing 和系统 decoration 影响。
- hash mismatch 需要人类判断是环境波动、capture failure、目标归属问题，还是真实视觉回归。

未来如果允许 AI 参与，只能是：

- 生成 baseline update proposal。
- 汇总 evidence。
- 列出 source、bounds、scale、color space、pixel format、环境信息和风险。
- 等 human maintainer 批准后再由受控流程更新。

AI 不允许：

- 自动把当前 hash 写入 baseline。
- 自动提交 golden hash。
- 自动覆盖旧 baseline。
- 自动把 mismatch 标成 render failure。

## 7. Hash Value Policy

当前政策：

- hash value 不允许写入日志。
- hash value 不允许写入文档。
- hash value 不允许写入仓库。
- hash value 不允许长期保存。
- hash value 不允许作为 closure review evidence。

当前允许的只有脱水 summary：

```text
cjgui frame hash feasibility: hash_computed=true
cjgui frame hash feasibility: hash_persisted=false
cjgui frame hash feasibility: hash_value_logged=false
cjgui frame hash feasibility: baseline_compared=false
```

原因：

- 一旦 hash value 进入文档或仓库，后续 AI 很容易把它误当成 golden value。
- hash value 本身不能说明 source truth、环境、scale、颜色空间或遮挡状态。
- 当前 hash 只证明“能算”，不证明“应保存”。

未来如果要保存 hash value，必须另开 baseline policy execution card，并至少规定：

- owner。
- storage。
- review。
- update。
- deletion。
- source normalization。
- CI / headless 分类。
- mismatch classification。

## 8. Screenshot Artifact 与 Baseline 输入

当前成功 screenshot artifact：

- 不允许保留为 baseline 输入。
- 不允许进入仓库。
- 不允许进入 baseline / golden image。
- 不允许长期缓存。
- 成功路径必须删除。

当前失败 artifact：

- 只允许短期、受控、可解释地保留。
- 只用于 failure diagnosis。
- 必须记录 retention reason、failure classification、path、TTL 和 deletion strategy。
- 不能自动提升为 baseline artifact。

baseline artifact 与 failure artifact 的区别：

- failure artifact 是诊断证据，说明哪里失败。
- baseline artifact 是长期期望输出，必须有 owner、review、隐私、存储和更新策略。
- failure artifact 不能因为“看起来正确”就被转成 baseline。
- baseline artifact 不能来自未审查的 `/tmp` 临时目录。

artifact retention policy 对 hash / baseline 的硬约束：

- 成功 artifact 默认删除。
- 失败 artifact 短期保留，TTL 默认 24 小时。
- artifact 默认只能位于 `/tmp` 或 `mktemp -d` 临时目录。
- 不保存 full-screen screenshot。
- target-window crop 也不能默认长期保留。
- 不内联 artifact，不 base64 写入日志，不提交 artifact。
- 不从 artifact 自动生成 baseline。

## 9. Target-window Screenshot Crop 是否足够作为 Baseline Source

当前结论：

> 不足够。

它当前足够作为：

- user-visible screenshot evidence source。
- frame hash feasibility source。
- 当前运行内 hash computation input。

它当前不足以作为 baseline source，原因：

- 当前只有本机一次成功路径。
- source 受 Screen Recording 权限影响。
- source 受窗口遮挡、frontmost app、Space / Mission Control 影响。
- source 受多显示器和 Retina scale 影响。
- source 可能包含系统 window decoration。
- source 的颜色空间和 pixel format 当前为 `unknown`。
- source 的 timing 仍依赖 smoke readiness 与 auto-close 窗口。
- 当前没有 CI / headless 策略。

未来如果继续使用 target-window screenshot crop 作为 baseline source，必须先冻结：

- crop 是否包含 decoration。
- crop 坐标空间是 point-space 还是 pixel-space。
- scale 如何记录和归一化。
- color space 和 pixel format 如何记录或转换。
- target attribution 失败如何分类。
- window occlusion 如何检测或降级。
- CI / headless 不可用时如何跳过、降级或标记。

## 10. Metal Readback Hash 与 Screenshot Hash 是否能混用

结论：

> 不能混用。

原因：

- Metal readback truth 是 render target / command buffer completion 后的内部图形 evidence。
- Screenshot hash truth 是 OS / compositor / display presentation 后的用户可见 evidence。
- 二者经过的管线不同。
- 二者受影响的风险不同。
- 二者不能共享 baseline，也不能互相替代 mismatch 解释。

未来如果同时存在两条 hash 线，必须分开：

- `source_truth=metal_readback`
- `source_truth=user_visible_screenshot`

每条线都要有独立 baseline owner、source normalization 和 failure classification。

本轮不批准 Metal readback hash，也不批准 screenshot baseline hash。

## 11. CI / Headless 可复核性

当前结论：

> 不可声称 CI / headless 可复核。

如果在 CI / headless 下运行，应诚实分类：

- 没有 display / WindowServer：`display_unavailable`。
- 没有 Screen Recording 权限：`permission_denied`。
- 不能找到目标窗口：`window_not_found`。
- 目标窗口不可见或不在当前 Space：`window_not_visible`。
- 截图 API 返回 nil 或失败：`capture_failed`。
- source image 存在但无法确认属于目标窗口：`target_mismatch`。
- source image 存在但 hash 前置条件不足：`prerequisite_missing` 或 `unknown`。

在 CI / headless 策略未冻结前：

- 不允许 baseline compare。
- 不允许把 skipped / unavailable 写成 pass。
- 不允许把 display / permission failure 写成 render failure。
- 不允许建立必须依赖本机桌面环境的长期 baseline。

## 12. 环境因素对 Baseline 的影响

### 12.1 遮挡

遮挡会改变 screenshot crop 内容。

要求：

- 遮挡必须单独分类为 `window_occluded` 或 `target_mismatch`。
- 不能把遮挡导致的 hash mismatch 写成 render failure。

### 12.2 权限

Screen Recording / screenshot 权限缺失会让截图失败或返回不可用图像。

要求：

- 权限问题必须分类为 `permission_denied`。
- 不能生成 baseline，也不能更新 baseline。

### 12.3 Frontmost App / Space

窗口不在当前 Space、应用不在前台、Mission Control 状态变化，都可能影响 screenshot source。

要求：

- 必须继续记录 frontmost / visibility diagnostics。
- 无法确认时只能降级或失败，不能建立 baseline。

### 12.4 多显示器

不同 display 的 bounds、origin、scale、color profile 可能不同。

要求：

- baseline source 必须记录 display identity 的脱水信息或明确 `unknown`。
- 多显示器策略未冻结前，不允许 baseline。

### 12.5 Retina Scale

point-space 与 pixel-space 不同。

要求：

- hash input 必须记录 scale。
- 未能确认 scale 时不能建立 baseline。

### 12.6 颜色空间

sRGB、Display P3、display profile、linear / non-linear 转换都会影响 hash。

要求：

- hash baseline 必须定义 color space。
- 当前 `color_space=unknown` 不能进入 baseline。

### 12.7 Window Decoration

title bar、shadow、rounded corner、traffic-light buttons 和系统主题都可能影响截图。

要求：

- baseline source 必须说明 decoration included / excluded。
- decoration diff 不得自动写成 renderer failure。

### 12.8 Timing

first frame rendered、compositor presentation、screenshot request 和 auto-close 之间存在时序。

要求：

- timing 不足应分类为 `render_not_ready`、`capture_failed` 或 `unknown`。
- 不能为了让 baseline 成立而延长或改变 runtime path。

## 13. Pixel Diff 是否可以作为下一步

结论：

> 不可以。

原因：

- 当前 baseline / golden hash 尚不允许。
- 当前更不具备 golden image / pixel diff owner。
- 当前没有 threshold、region policy、color space、scale、alpha、anti-aliasing 策略。
- 当前没有 CI / headless 复核。
- 当前没有 Renderer / Scene truth。
- 当前 smoke demo 只有 clear-color，pixel diff 容易绑定无意义的偶然画面。

下一步不能直接是 pixel diff execution card。

## 14. Future Execution Card 最大边界

如果未来要开 execution card，第一刀最多只能授权：

> `P1 frame hash baseline-readiness diagnostics first slice`

该 first slice 最多允许：

- 在现有 screenshot verification harness 中输出 baseline readiness summary。
- 继续只使用 `target_window_screenshot_crop` 作为 source。
- 继续声明 `source_truth=user_visible_screenshot`。
- 继续不输出 hash value。
- 继续不持久化 hash。
- 继续不保存成功 screenshot artifact。
- 继续不建立 baseline / golden image。
- 继续不做 baseline compare。
- 继续不做 pixel diff。
- 只输出脱水 readiness fields，例如：
  - `baseline_readiness_requested=true`
  - `baseline_allowed=false`
  - `baseline_blocked_reason=<reason>`
  - `baseline_owner_defined=false`
  - `source_normalized=false`
  - `ci_headless_supported=false`
  - `human_review_required=true`

该 first slice 不允许：

- 写入 hash value。
- 保存 baseline。
- 保存 raw bytes。
- 提交 artifact。
- 修改 native bridge。
- 新增 public C ABI / runtime API。
- 设计 Renderer / Scene / Widget / Layout / DSL。

如果未来目标是允许真正 baseline / golden hash，则必须先完成：

- baseline owner preflight。
- baseline storage / retention preflight。
- source normalization preflight。
- CI / headless strategy preflight。
- human approval gate。

## 15. 本轮 Stop-line

本轮明确不做：

- 不实现 baseline / golden hash。
- 不实现 pixel diff。
- 不实现 baseline compare。
- 不保存 hash value。
- 不把 hash 写入文档或仓库。
- 不保存成功 screenshot artifact。
- 不保存 raw bytes。
- 不修改 screenshot verification harness。
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

如果继续推进，推荐下一步仍为 docs-only：

> `P1 frame hash baseline-readiness diagnostics execution card`

该 execution card 只能授权未来一个极窄 baseline readiness diagnostics first slice；不能授权 baseline / golden hash、hash value persistence、baseline compare、pixel diff、offscreen renderer、native bridge 修改、public runtime API 或 Renderer / Scene。
