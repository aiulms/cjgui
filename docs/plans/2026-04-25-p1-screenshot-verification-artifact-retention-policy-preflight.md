# P1 Screenshot Verification Artifact Retention Policy Preflight

日期：2026-04-25

性质：docs-only / artifact review and retention policy preflight / P1 GUI verification evidence line

状态：完成；不批准直接实现

范围：冻结 screenshot verification artifact 的审查、保留、清理、隐私和 baseline 边界。本轮不修改 screenshot verification harness，不保存 screenshot artifact，不读取或比较像素，不实现 pixel diff、frame hash 或 offscreen renderer。

## 1. 背景

当前已经完成：

- [P1 automated GUI verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [P1 frame metadata / render stats first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [P1 Metal readback feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [P1 user-visible window screenshot feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)
- [P1 user-visible window screenshot verification first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)

当前已有 evidence：

- lifecycle / capability / auto-close 日志 harness。
- 脱水 frame metadata / render stats。
- smoke-only single-frame clear-color Metal readback summary。
- CoreGraphics on-screen image feasibility 成功。
- screenshot verification harness 能归属目标 smoke window。
- screenshot verification harness 能创建临时 target-window artifact，并在成功后删除。
- 当前本机中心附近 `3x3` clear-color sample summary 通过。

当前仍没有：

- artifact review / retention policy。
- 成功 artifact 保留策略。
- 失败 artifact 保留策略。
- 隐私 / 清理 / 过期策略。
- baseline policy。
- pixel diff / frame hash preflight。
- CI / headless artifact 策略。

本 preflight 只冻结 artifact policy，不进入实现。

## 2. Screenshot Verification First Slice 已经证明什么

已完成的 screenshot verification first slice 只证明：

- 独立 harness 可以启动现有 `labs/macos_bridge_smoke`。
- harness 可以等待 readiness 日志：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- 当前本机可以在 smoke 运行期间创建一个临时 target-window screenshot artifact。
- harness 可以通过 smoke process id、window title 和 bounds 归属目标窗口。
- harness 可以在目标窗口截图中心附近做 `3x3` clear-color sample summary。
- 当前本机结果为 `success=true reason=none`。
- 成功路径会删除 artifact 和临时目录。
- 原有 auto-close harness 未被破坏。

它不证明：

- full GUI verification。
- 全窗口像素正确。
- pixel diff 或 frame hash 稳定。
- baseline 可维护。
- 窗口无遮挡、多 Space、多显示器、CI / headless 场景稳定。
- Renderer / Scene / Widget / Layout 正确。
- 当前 smoke demo 是正式 GUI runtime。

## 3. 当前 Artifact 策略

当前 screenshot verification harness 的 artifact 策略是：

- artifact 只写入 `mktemp -d /tmp/cjgui-p1-screenshot-verification.XXXXXX` 创建的临时目录。
- 当前 artifact 文件名为 `target-window.png`。
- artifact 不写入仓库。
- artifact 不提交。
- artifact 不进入 baseline。
- 成功时默认删除 artifact 和临时目录。
- 失败时如果 artifact 已创建，可以保留临时目录供人工排查，但必须输出路径、保留原因、failure classification 和删除策略。

当前策略合理，但还缺少更明确的 policy：

- 成功时是否允许为了 closure evidence 保留 artifact。
- 失败 artifact 能保留多久。
- 谁负责人工审查。
- 如何避免泄露用户桌面内容。
- 是否需要自动清理旧 `/tmp/cjgui-p1-screenshot-verification.*`。
- 何时才允许进入 pixel diff / frame hash。

## 4. 成功 Artifact 保留策略

默认结论：

> 成功时应该默认删除 artifact。

原因：

- 当前 artifact 是用户可见桌面截图证据，存在隐私风险。
- 当前 smoke 只需要日志 evidence 即可证明 harness 成功路径。
- 长期保留成功 artifact 容易被误用为 golden image 或 baseline。
- 早期 smoke 的 visual target 极窄，保留图片收益低于隐私和治理成本。

成功时是否允许保留 artifact 作为 closure evidence：

- 默认不允许。
- 只有未来 `P1 screenshot artifact retention execution card` 明确授权时才允许。
- 即使允许，也只能是人工审查用的短期临时 evidence，不是 baseline。

如果未来允许成功 artifact 保留，必须同时满足：

- 路径：只能在 `/tmp` 或 `mktemp -d /tmp/cjgui-p1-screenshot-verification.XXXXXX` 临时目录。
- 命名：必须带 `target-window`、`smoke`、时间戳或随机后缀，避免覆盖用户文件。
- 内容：只能保留 target-window crop，不保留 full screen screenshot。
- 保留时长：默认不超过 24 小时；更长必须在 closure review 写明原因。
- 提交：不得提交到仓库。
- baseline：不得进入 baseline / golden image。
- 记录：closure review 必须记录 artifact 路径、保留原因、删除策略和隐私风险说明。
- 清理：完成人工审查后必须删除，或明确由用户手动删除。

成功 artifact 不得变成：

- 项目长期资产。
- regression baseline。
- docs 中的展示图片。
- CI artifact 默认产物。
- Renderer / Scene truth。

## 5. 失败 Artifact 保留策略

失败时可以更宽，但仍必须受控。

允许保留失败 artifact 的条件：

- readiness 已达成。
- screenshot request 已发起。
- artifact 已创建。
- failure classification 需要人工复查，例如：
  - `window_occluded`
  - `target_mismatch`
  - `color_mismatch`
  - `capture_failed`
  - `unknown`
- artifact 有助于区分 screenshot environment failure 和 render failure。

失败时不应保留 artifact 的情况：

- `render_not_ready`，因为此时没有可靠截图 evidence。
- `permission_denied`，除非系统返回了可保存的非敏感诊断截图，默认不保存。
- `display_unavailable`，通常没有有效 artifact。
- artifact 明显包含大量桌面背景、其他窗口或敏感内容。

失败 artifact 的保留边界：

- 路径：只能在 `/tmp` 或 `mktemp -d` 临时目录。
- 内容：优先 target-window crop；不保存 full screen screenshot。
- 保留时长：默认不超过 24 小时。
- 删除策略：closure review 必须写出 `rm -rf <dir>` 或等价清理方式。
- 人工审查责任：保留 artifact 的执行者负责确认是否包含用户桌面敏感内容，并在 closure review 中记录风险。
- 提交：不得提交到仓库。
- baseline：不得进入 baseline / golden image。
- 长期缓存：不得长期缓存。

失败 artifact 的作用只限：

- 解释本次失败分类。
- 帮助判断是否是权限、显示、遮挡、target attribution、timing 或 sample 问题。
- 作为短期 closure evidence。

失败 artifact 不得被解释为：

- render truth。
- future UI baseline。
- pixel diff 输入。
- public runtime API 的一部分。

## 6. 隐私与清理策略

artifact 最大风险是泄露用户桌面内容。

防守规则：

- 不保存 full screen screenshot。
- 只保存 target-window crop。
- 如果无法可靠裁剪到目标 window bounds，应分类为 `capture_failed`、`target_mismatch` 或 `unknown`，不保留 artifact。
- 不把 artifact 写入仓库、桌面、下载目录、文档目录或长期缓存目录。
- 不把 artifact 内联到 Markdown。
- 不把 artifact base64 编码写入日志。
- 不输出 raw bytes。
- 不把 artifact 路径设计为稳定公共路径。

是否需要裁剪到目标 window bounds：

- 需要。
- target-window crop 是 artifact 保留的默认最大内容边界。
- crop 必须基于 harness 侧的 owner pid / title / bounds attribution。

是否允许保存 full screen screenshot：

- 默认不允许。
- 除非未来另开 preflight 证明 full screen screenshot 对某个诊断不可替代，并定义严格隐私审查，否则不允许。

是否允许保存 target-window crop：

- 可以在未来 execution card 中受限允许。
- 必须只保留当前 smoke window 的 crop。
- 必须不提交、不 baseline、不长期缓存。
- 必须在 closure review 记录路径、原因、删除策略和人工审查责任。

是否需要自动清理旧 `/tmp/cjgui-p1-screenshot-verification.*`：

- 需要规划，但本轮不实现。
- 未来 execution card 可以授权 harness 在启动前或退出后清理超过 TTL 的旧目录。
- 清理规则必须保守：
  - 只匹配 `/tmp/cjgui-p1-screenshot-verification.*`。
  - 只删除超过 TTL 的目录。
  - 不删除当前运行实例的临时目录。
  - 清理动作必须输出脱水 summary。
- 当前本轮不修改 harness，所以不做自动清理实现。

## 7. Baseline Policy

当前结论：

- artifact 不允许进入仓库。
- artifact 不允许进入 baseline / golden image。
- artifact 不允许长期缓存。
- artifact 不允许成为 CI 默认产物。

原因：

- 当前只有一个 smoke clear-color sample，没有正式 Renderer / Scene / Widget / Layout。
- 当前 screenshot evidence 受桌面环境、权限、遮挡、Retina scale、多显示器、frontmost app 和 timing 影响。
- 当前没有 baseline owner。
- 当前没有 baseline update 流程。
- 当前没有颜色空间、scale、alpha、diff 阈值或 anti-aliasing 策略。

未来若要建立 baseline，必须另开 preflight，且至少回答：

- baseline 的 owner 是谁。
- source image 来自 screenshot、Metal readback 还是 offscreen renderer。
- baseline 存放在哪里。
- baseline 是否平台相关。
- baseline update 如何审批。
- diff 阈值如何定义。
- artifact 中可能包含的隐私内容如何清除。

## 8. Artifact Review 与 Pixel Diff / Frame Hash 的关系

artifact review 是前置治理，不是 pixel diff。

它解决：

- artifact 能否保存。
- artifact 保存在哪里。
- artifact 是否会泄露桌面内容。
- artifact 如何清理。
- artifact 是否允许作为 closure evidence。
- artifact 为什么不能自动变成 baseline。

pixel diff / frame hash 解决的是另一类问题：

- 用稳定 source image 或 pixel bytes 做机器比较。
- 对比当前输出与 baseline 或 hash。
- 发现视觉回归。

没有 artifact policy，不允许进入 pixel diff / frame hash。

但有 artifact policy，也不等于可以立刻进入 pixel diff / frame hash。

## 9. 什么时候才允许进入 Pixel Diff Preflight

只有满足以下条件时，才允许另开 `P1 pixel diff prerequisites preflight` 或等价文档：

- screenshot verification 或其他 source image 路线已经有稳定 artifact policy。
- 已明确 source image 是 target-window crop、Metal readback output 还是 future offscreen output。
- 已明确 artifact 不含用户桌面敏感内容，或有明确 redaction / crop 策略。
- 已明确 baseline owner 和 baseline update 流程。
- 已明确 diff 阈值、颜色空间、Retina scale、alpha、抗锯齿和平台差异策略。
- 已明确 failure classification，避免把权限 / 显示 / 遮挡 / target mismatch 误判为 render failure。

当前不直接做 pixel diff 的原因：

- 当前 source image 仍来自本机桌面环境。
- 当前没有 baseline owner。
- 当前没有 diff 阈值和颜色空间策略。
- 当前没有 CI / headless 稳定性证据。
- 当前没有 Renderer / Scene / Widget / Layout truth。

## 10. 什么时候才允许进入 Frame Hash Preflight

只有满足以下条件时，才允许另开 `P1 frame hash prerequisites preflight` 或等价文档：

- 已有稳定 source image 或 readback bytes。
- 已定义 hash 输入边界：
  - crop bounds
  - width / height
  - row stride
  - pixel format
  - color space
  - scale
  - alpha
- 已确认 hash 输入不包含用户桌面敏感内容。
- 已明确 hash 是否只用于 smoke-only closure evidence。
- 已明确 hash 不能升级为跨平台视觉 contract。

当前不直接做 frame hash 的原因：

- 当前 screenshot artifact 默认成功删除。
- 当前没有稳定 hash source。
- 当前没有 row stride、颜色空间、scale 规范。
- 当前没有 baseline / expected hash owner。

## 11. CI / Headless Artifact 策略

当前不承诺 CI / headless artifact 策略。

原因：

- 当前 screenshot verification 依赖真实 macOS desktop session。
- CI / headless 可能没有可用 display。
- Screen Recording 权限、window server、Space、frontmost app 和 compositor 状态不可默认假设。
- 当前不允许为了 CI 引入 offscreen renderer。
- 当前不允许为了 CI 设计跨平台 screenshot abstraction。

未来如果要处理 CI / headless，必须另开 preflight，至少回答：

- 是否使用真实 macOS GUI session。
- 是否允许 CI 保存 artifact。
- artifact 是否包含桌面内容。
- 权限如何配置和记录。
- 失败是否分类为 `display_unavailable`、`permission_denied` 或 `unknown`。
- 是否需要 offscreen renderer。

## 12. Write Set 与禁止项

本轮允许：

- 新建本 preflight 文档。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

本轮不允许：

- 修改 screenshot verification harness。
- 保存 screenshot artifact。
- 读取或比较像素。
- 实现 pixel diff。
- 实现 frame hash。
- 实现 offscreen renderer。
- 修改 `labs/macos_bridge_smoke`。
- 修改 `verify_user_visible_window_screenshot_verification.sh`。
- 修改 `verify_auto_close.sh`。
- 修改 `cjgui_macos.m`。
- 新增 public C ABI / runtime API。
- 设计 Renderer / Scene。
- 设计 Widget / Layout / DSL。
- 做跨平台抽象。
- 做文本、输入法、无障碍。
- 做 AI semantic tree / Action Router。
- 把当前 smoke demo 宣称为正式 runtime。

## 13. Runtime Pollution Guard

artifact policy 不能反向污染 Renderer / Scene / Widget / Layout / DSL。

规则：

- artifact 只是 external verification evidence。
- artifact 路径不是 runtime API。
- target-window crop 不是 Widget / Scene bounds contract。
- screenshot capture 策略不是 Renderer design。
- artifact retention 不是 framework feature。
- failure artifact 的人工审查不是 public diagnostics API。
- baseline policy 未批准前，不得把 screenshot artifact 当作 long-lived truth。

为了避免 smoke demo 被升级成正式 runtime：

- 始终称为 `labs/macos_bridge_smoke`。
- 始终称为 smoke demo、smoke diagnostics 或 verification harness。
- 不把 smoke window title、bounds、sample 策略、artifact 路径写成 public runtime contract。
- 不把当前 screenshot verification first slice 称为完整视觉验证。
- 不让 artifact policy 自动开启 pixel diff、frame hash、offscreen renderer 或 Renderer / Scene。

## 14. 当前 Stop-Line

本轮强制 stop-line：

- 不修改 screenshot verification harness。
- 不保存 screenshot artifact。
- 不读取或比较像素。
- 不实现 pixel diff。
- 不实现 frame hash。
- 不实现 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 `verify_user_visible_window_screenshot_verification.sh`。
- 不修改 `verify_auto_close.sh`。
- 不修改 `cjgui_macos.m`。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本、输入法、无障碍。
- 不做 AI semantic tree / Action Router。
- 不把 current smoke demo 宣称为正式 runtime。

## 15. 结论

本轮结论：

- screenshot verification first slice 已经证明当前本机可以创建 target-window artifact、归属 smoke window，并做中心附近 `3x3` clear-color sample summary。
- 当前 artifact 策略是成功默认删除、失败可保留但必须记录路径、原因、classification 和删除策略。
- 成功 artifact 仍应默认删除；只有未来 execution card 明确授权时，才允许作为短期 closure evidence 保留。
- 失败 artifact 可以在受控条件下短期保留，用于人工诊断，但不得提交、不得 baseline、不得长期缓存。
- artifact 默认只能位于 `/tmp` 或 `mktemp -d` 临时目录。
- 未来需要规划自动清理旧 `/tmp/cjgui-p1-screenshot-verification.*`，但本轮不实现。
- full screen screenshot 默认不允许保留；target-window crop 可在未来 execution card 中受限允许。
- artifact review 是 pixel diff / frame hash 的前置治理，不是 pixel diff / frame hash 本身。
- 当前不直接做 pixel diff / frame hash，因为缺少 baseline owner、diff / hash 输入规范、颜色空间 / scale 策略和 CI / headless 稳定证据。

下一步推荐 opening：

- `P1 screenshot artifact retention execution card`

该 opening 仍然应是 docs-only，不自动进入实现。它最多只能把本 preflight 收束成一张受限执行卡，未来如批准实现，也只能围绕 artifact retention / cleanup policy 的极窄 harness 调整，不得自动进入 pixel diff、frame hash、baseline、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、跨平台抽象或 public runtime API。
