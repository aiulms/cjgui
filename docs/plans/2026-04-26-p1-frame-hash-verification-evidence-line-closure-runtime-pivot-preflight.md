# P1 Frame Hash Verification Evidence Line Closure / Runtime Pivot Preflight

日期：2026-04-26

性质：docs-only / evidence line closure / runtime pivot preflight / no implementation

状态：完成；不批准直接实现

范围：复核从 automated verification、Metal readback、user-visible screenshot、artifact retention、frame hash feasibility、baseline readiness、baseline owner policy、source normalization readiness 到 bounds / crop semantics readiness diagnostics 的整条 evidence line，并判断当前是否应继续沿 screenshot / frame hash verification 线推进，还是 pivot 回 runtime / smoke-to-runtime 边界。本轮不写 runtime 代码，不修改 harness，不修改 `labs/macos_bridge_smoke`。

## 1. 背景

本轮依据：

- [P1 automated GUI verification closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [P1 frame metadata / render stats closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
- [P1 Metal readback feasibility closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [P1 user-visible window screenshot verification closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [P1 screenshot artifact retention closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)
- [P1 frame hash feasibility closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [P1 frame hash baseline-readiness diagnostics closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [P1 frame hash baseline owner / update policy closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)
- [P1 frame hash source normalization readiness diagnostics closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md)
- [P1 frame hash source normalization evidence closure / next-boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md)
- [P1 frame hash bounds / crop semantics policy preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md)
- [P1 frame hash bounds / crop semantics readiness diagnostics closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md)
- [P1 main-thread UI message queue closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)
- [P1 AppKit / Metal bridge boundary cleanup closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)

当前 evidence line 的最新固定事实仍是：

```text
source=target_window_screenshot_crop
source_truth=user_visible_screenshot
source_normalized=false
baseline_allowed=false
hash_value_persistence_allowed=false
pixel_diff_allowed=false
```

这些字段不能被本轮解释为 source normalized、baseline allowed、hash 可保存、pixel diff 可开启或 runtime truth 已冻结。

## 2. 当前 Evidence Line 已经证明什么

### 2.1 Automated GUI Verification

已有 `verify_auto_close.sh` 日志 harness，可以机器复核：

- build / run 路径可执行。
- SDKROOT、bridge init、Metal capability、window created、metal setup complete、first frame rendered 日志存在。
- 自动关闭通过 lifecycle queue 进入主线程 drain。
- close / destroy / event loop exit 路径完成。
- `cjgui_app_run()` 返回 `0`。

它证明的是 smoke lifecycle 和日志证据链，不是视觉正确性。

### 2.2 Frame Metadata / Render Stats

已有脱水 frame metadata / render stats diagnostics，可以记录 frame index、drawable size、scale、pixel format、clear color metadata、first frame submitted、attempt count、success / degraded reason 等字段。

它证明日志粒度比单纯 `first frame rendered` 更细，但不读取像素，也不证明屏幕真实颜色正确。

### 2.3 Metal Readback

已有 smoke-only single-frame clear-color Metal readback feasibility summary：

- command buffer completion 后读取 bridge 内部临时 staging buffer。
- 只做 clear-color 单点 summary。
- 不保存 raw bytes，不暴露 Metal 对象，不新增 public C ABI / runtime API。

它证明 render target 侧 clear-color probe 在当前 smoke 内可行，但不是用户可见窗口证明，也不是 compositor / display presentation 证明。

### 2.4 User-visible Screenshot Feasibility / Verification

已有独立 screenshot verification harness，可以：

- 启动 smoke。
- 等待 readiness 日志。
- 通过 owner pid、title、bounds 归属目标 smoke window。
- 请求目标 window bounds 的临时 screenshot artifact。
- 在中心附近做 `3x3` clear-color sample summary。
- 成功路径删除 artifact，并输出 `success=true reason=none`。

它证明当前本机一次用户可见截图证据链可以走通，但不是 full GUI verification，不证明所有像素正确，也不证明 CI / headless 可复核。

### 2.5 Artifact Retention

artifact policy 已经收口：

- 成功 artifact 默认删除。
- 失败 artifact 只允许短期、受控、可解释地保留。
- 历史 `/tmp/cjgui-p1-screenshot-verification.*` cleanup 受 pattern 和 TTL 限制。
- artifact 不进入仓库，不进入 baseline / golden image，不长期缓存。

这降低了隐私和误用风险，但也意味着当前没有可作为 baseline input 的成功 artifact。

### 2.6 Frame Hash Feasibility

已有当前运行内 frame hash feasibility summary：

- source 固定为 `target_window_screenshot_crop`。
- source truth 固定为 `user_visible_screenshot`。
- 算法为 `sha256`。
- `hash_computed=true`。
- `hash_persisted=false`。
- `hash_value_logged=false`。
- `baseline_compared=false`。

它证明当前运行内可以计算 hash，但 hash value 不输出、不保存，不能变成 regression truth。

### 2.7 Baseline Readiness / Owner Policy

baseline readiness 和 owner policy 已经明确：

- `baseline_allowed=false`。
- `baseline_owner_defined=false`。
- `baseline_update_policy_defined=false`。
- `human_review_required=true`。
- `ai_auto_update_allowed=false`。
- AI 不能成为 baseline owner，也不能自动创建或更新 baseline。

这证明 policy diagnostics 可以表达阻塞状态，但 baseline / golden hash 仍未获准。

### 2.8 Source Normalization Readiness

source normalization readiness 已经明确：

- source 仍为 `target_window_screenshot_crop`。
- source truth 仍为 `user_visible_screenshot`。
- `source_normalized=false`。
- `blocked_reason=source_policy_incomplete`。
- bounds、scale、color space、pixel format、decoration、timing、CI / headless 仍未冻结。

这证明 source normalization 尚未完成。

### 2.9 Bounds / Crop Semantics Readiness

bounds / crop semantics readiness 已经明确：

- `screen_bounds_points_observed=true`。
- `capture_bounds_pixels_observed=true`。
- `target_window_crop_bounds_observed=true`。
- `content_interior_bounds_observed=false`。
- `hash_input_bounds_defined=false`。
- `whole_window_crop_baseline_allowed=false`。

这证明当前 harness 有 bounds diagnostics，但还没有 hash 哪个矩形的 contract。whole window crop 不能升级为 baseline source，content interior 仍不可用。

## 3. 当前 Evidence Line 没有证明什么

当前整条 evidence line 仍没有证明：

- full GUI verification。
- 用户可见窗口所有像素正确。
- compositor / display presentation 在所有桌面状态下正确。
- 窗口无遮挡、跨 Space、多显示器、Retina scale、frontmost app、timing 全部稳定。
- CI / headless 可复核。
- source 已 normalized。
- hash input bounds 已定义。
- content interior extraction 可用。
- baseline / golden hash 可建立。
- baseline compare 可执行。
- pixel diff 可执行。
- offscreen renderer 可用。
- Renderer / Scene / Widget / Layout / DSL 已有实现前提。
- 当前 smoke demo 是正式 GUI runtime。

## 4. Screenshot / Frame Hash 线是否足够支撑下一阶段 Runtime 边界讨论

结论：足够支撑下一阶段 runtime 边界讨论，但不足以支撑 pixel diff、baseline 或正式 visual regression。

理由：

- smoke 已经有机器可复核的 lifecycle / capability guard。
- render target 侧已有 Metal readback feasibility，且明确不是用户可见窗口证明。
- user-visible 侧已有目标窗口归属、临时 artifact、`3x3` clear-color sample 和 artifact retention policy。
- frame hash 线已经证明当前运行内可计算 hash，同时也冻结了 hash 不输出、不保存、不 baseline compare 的护栏。
- source normalization 和 bounds / crop semantics readiness 已经能诚实表达当前阻塞状态。

这些 evidence 已经足够说明：未来 runtime 讨论可以用当前 harness 作为 smoke guard，不需要继续为了证明“还不能 baseline / pixel diff”而无限细分 verification slice。

## 5. 是否继续推进 Scale / Color Space / Pixel Format / Timing / CI-headless / Pixel Diff / Baseline

本轮建议：暂时不继续推进这些细分 slice。

这些议题都真实重要，但继续向下切会产生递减收益：

- `scale` 依赖 bounds / crop semantics。
- `color space` 和 `pixel format` 依赖 source image 选择与 hash input 区域。
- `timing / presentation settle` 需要更清楚的 runtime lifecycle 和 frame scheduling owner。
- `CI / headless` 需要决定未来 verification harness 是 smoke guard、runtime test，还是独立 verification harness。
- `pixel diff` 需要 baseline artifact、threshold、source normalization 和 owner approval。
- `baseline` 需要 human owner、长期保存策略、source normalization 和 update workflow。

在 smoke-to-runtime 边界未冻结前继续深入这些验证细节，容易把 smoke harness 的偶然形态固化为正式 runtime 约束。

## 6. 为什么现在不应该继续往 Pixel Diff / Baseline 深挖

现在不应继续往 pixel diff / baseline 深挖，因为：

- 当前 source 未 normalized。
- 当前 hash input bounds 未定义。
- 当前 content interior 不可用。
- 当前成功 screenshot artifact 默认删除，不能成为 baseline input。
- 当前 hash value 不允许输出或保存。
- 当前 baseline owner 未设立，human approval flow 仅是 policy diagnostics。
- 当前 CI / headless 不可复核。
- 当前 UI 只有 smoke clear-color 路径，不是正式 Renderer / Scene / Widget 输出。
- 当前 pixel mismatch 很可能来自 screenshot 环境、window decoration、scale、timing、color space 或 compositor，而不是 render failure。

如果现在建立 baseline 或 pixel diff，会制造一个未被治理认可的第二真相源。

## 7. 为什么必须保持当前六个字段

必须继续保持：

```text
source=target_window_screenshot_crop
source_truth=user_visible_screenshot
source_normalized=false
baseline_allowed=false
hash_value_persistence_allowed=false
pixel_diff_allowed=false
```

原因：

- `source=target_window_screenshot_crop`：这是当前唯一实际走通的 user-visible evidence source；它不能被暗中替换成 Metal readback、offscreen renderer 或 future renderer source。
- `source_truth=user_visible_screenshot`：这条线的 truth 是 OS / WindowServer / compositor 后的用户可见截图，不是 Metal render target truth，也不是 future Renderer / Scene truth。
- `source_normalized=false`：bounds、scale、color space、pixel format、decoration、timing、CI / headless 都未冻结。
- `baseline_allowed=false`：没有 normalized source、human owner、approved artifact / hash retention 和 CI strategy。
- `hash_value_persistence_allowed=false`：保存或输出 hash value 会被误读为 golden value，绕过 artifact retention 和 baseline owner policy。
- `pixel_diff_allowed=false`：没有 baseline、source normalization、threshold、颜色空间和环境可复核性，diff 结果不可解释。

## 8. 为什么当前不能进入这些方向

### 8.1 Bounds Normalization

不能进入 bounds normalization，因为当前只有 diagnostics，还没有冻结：

- point-space / pixel-space 转换。
- display scale 来源。
- rounding policy。
- multi-display / negative origin 处理。
- target window crop 与 content interior 的关系。

### 8.2 Content Interior Extraction

不能进入 content interior extraction，因为当前没有正式 runtime view / content geometry API，也不能修改 native bridge 或新增 public C ABI / runtime API。把 content interior 宣称为当前可用 source 会越过 P1 边界。

### 8.3 Baseline / Golden Hash

不能进入 baseline / golden hash，因为 baseline owner、source normalization、artifact retention、hash persistence 和 CI / headless policy 都未满足。AI 也不能自动创建或更新 baseline。

### 8.4 Baseline Compare

不能进入 baseline compare，因为没有合法 baseline，也没有可保存的 hash value。当前 compare 的 pass / fail 都不可解释。

### 8.5 Pixel Diff

不能进入 pixel diff，因为它比 frame hash 需要更多前置条件：稳定 source、baseline artifact、threshold、颜色空间、pixel format、scale、anti-aliasing、timing、window decoration 和环境分类。

### 8.6 Offscreen Renderer

不能进入 offscreen renderer，因为它很可能越过当前 P1 smoke 边界，提前打开 Renderer / Scene truth、render target ownership 和 public runtime architecture。当前没有 execution card 授权。

## 9. 为什么当前也不能直接进入 Renderer / Scene / Widget / Layout / DSL

当前不能直接进入 Renderer / Scene / Widget / Layout / DSL，因为：

- `labs/macos_bridge_smoke` 仍是 smoke，不是正式 runtime。
- 当前 public runtime API 还没有 frozen owner / truth。
- 现有 C ABI 和 bridge API 只是 smoke 实验面，不能直接升格为公共契约。
- 当前只有 app run、single window、clear-color render、lifecycle queue 和 diagnostics guard，尚未冻结正式 runtime 的目录、模块边界、resource handle、event model 或 state truth。
- 先设计 Renderer / Scene / Widget 容易让入口层反逼底层，违反治理规则。
- 布局、控件、文本、输入法、无障碍都属于后续开口。

下一步即使 pivot 回 runtime，也应先做 smoke-to-runtime 边界 preflight，而不是直接写 runtime 代码或设计高层 API。

## 10. Runtime Pivot 判断

本轮结论：

> 当前 screenshot / frame hash verification evidence line 可以暂时收口。

不建议继续新增 scale / color space / pixel format / timing / CI-headless / pixel diff / baseline 的细分 slice。

当前验证护栏已经足够支持回到 runtime 边界讨论：

- `verify_auto_close.sh` 可作为 smoke lifecycle / capability guard。
- screenshot verification harness 可作为 user-visible smoke guard。
- frame hash / source normalization / bounds diagnostics 可作为明确的 negative guard，防止误开 baseline / pixel diff。
- 所有 harness 都仍应被视为 smoke guard，而不是正式 runtime test framework。

## 11. 推荐下一条 Opening

推荐下一条 docs-only opening：

> `P1 smoke-to-runtime boundary preflight`

它仍不是 runtime implementation。它应冻结：

- `labs/macos_bridge_smoke` 哪些内容只能留在 smoke。
- 哪些经验可以迁移为未来正式 runtime 的约束。
- 哪些 C ABI / bridge API 绝不能直接升格为 public runtime API。
- 是否需要新目录承载正式 runtime，避免把 smoke demo 扩成框架。
- 第一条正式 runtime opening 的最小边界是什么。
- 未来 runtime 是否先只抽 app / window lifecycle，而不是 Renderer / Scene / Widget。
- 当前 verification harness 如何作为 smoke guard，而不是正式 runtime test framework。

## 12. 本轮 Stop-line

本轮强制保持：

- 不写 runtime 代码。
- 不修改 harness。
- 不修改 `labs/macos_bridge_smoke`。
- 不实现 bounds normalization。
- 不实现 content interior extraction。
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

## 13. Next Opening

当前没有自动开启的直接实现 opening。

下一步推荐创建 docs-only：

> `P1 smoke-to-runtime boundary preflight`

该 opening 只冻结 smoke demo 与未来正式 runtime 的迁移边界，不自动开启 runtime implementation，不批准 Renderer / Scene / Widget / Layout / DSL，不批准 public runtime API，也不批准继续深入 pixel diff / baseline。
