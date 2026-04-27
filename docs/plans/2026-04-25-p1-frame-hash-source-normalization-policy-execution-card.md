# P1 Frame Hash Source Normalization Policy Execution Card

日期：2026-04-25

性质：execution card / docs-only / bounded implementation authorization

状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行

范围：把 `P1 frame hash source normalization policy preflight` 收束成一张受限 execution card。本卡最多只授权未来一个 `source normalization readiness diagnostics` first slice；不授权直接做 source normalization runtime、不授权 baseline / golden hash、不授权 hash value persistence、不授权 baseline compare、不授权 pixel diff、不授权 offscreen renderer、不授权 public runtime API、Renderer / Scene、Widget / Layout / DSL 或跨平台抽象。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 唯一确认依据：
  - [2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 只能复用现有 smoke screenshot verification diagnostics。
- 上层尽量仓颉原生：是。不得新增 public C ABI / runtime API，也不得让仓颉层持有 screenshot artifact、hash value、baseline、window、display 或平台对象。
- 底层只保留必要平台桥接：是。本卡不允许修改 native bridge。
- 没有过早抽象跨平台：是。本卡只覆盖当前 macOS smoke verification source diagnostics，不定义跨平台 source normalization contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现需要真正实现 source normalization、保存或输出 hash value、建立 baseline / golden hash、做 baseline compare、做 pixel diff、读取或输出 raw bytes、保留成功 screenshot artifact、修改 native bridge、新增 C ABI / public runtime API、引入 offscreen renderer、设计 Renderer / Scene / Widget / Layout / DSL，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)

背景文档：

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)
- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡扩展成：

- source normalization implementation。
- baseline / golden hash creation。
- hash value persistence。
- baseline compare。
- pixel diff。
- raw bytes storage。
- successful screenshot artifact retention。
- offscreen renderer。
- native bridge 修改。
- public C ABI / runtime API。
- Renderer / Scene / Widget / Layout / DSL。

## 2. Goal

未来 first slice 的唯一目标：

> 在现有 screenshot verification harness 中输出 source normalization readiness diagnostics summary，继续明确 source normalization 尚未完成，并继续保持 `baseline_allowed=false`。

未来 first slice 最多允许回答：

- 当前 source 仍只能是 `target_window_screenshot_crop`。
- 当前 source truth 仍只能是 `user_visible_screenshot`。
- 当前 source 尚未 normalized。
- 当前 bounds、scale、color space、pixel format、decoration、timing、CI / headless policy 仍未全部定义。
- 当前 baseline 仍不允许。
- 当前 hash value persistence 仍不允许。
- 当前 pixel diff 仍不允许。

未来 first slice 不允许回答：

- 当前 source 已 normalized。
- 当前可以保存 hash value。
- 当前可以建立 baseline / golden hash。
- 当前可以执行 baseline compare。
- 当前可以执行 pixel diff。
- 当前可以把 screenshot hash 当成正式 regression truth。
- 当前 smoke demo 是正式 GUI runtime。

## 3. Scope

未来 first slice 只做：

- 在现有 screenshot verification harness 内增加脱水 readiness diagnostics，或者在 closure flow 中记录等价 checklist。
- 继续复用现有 screenshot verification、frame hash feasibility、baseline readiness、baseline owner policy、artifact cleanup 和 auto-close 验证语义。
- 继续只输出 policy / diagnostics，不改变 capture、artifact、hash 或 baseline 行为。

未来 first slice 明确不做：

- 不实现 source normalization。
- 不把 `source_normalized` 改成 `true`。
- 不保存或输出 hash value。
- 不保存成功 screenshot artifact。
- 不保存 raw bytes。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不做 offscreen renderer。
- 不修改 native bridge。
- 不新增 public C ABI / runtime API。
- 不设计 Renderer / Scene / Widget / Layout / DSL。

## 4. Source Boundary

未来 first slice 必须继续保持：

```text
source=target_window_screenshot_crop
source_truth=user_visible_screenshot
```

含义：

- 该 source 是用户可见截图证据，不是 Metal readback truth。
- 该 source 不是 offscreen renderer truth。
- 该 source 不是 Renderer / Scene truth。
- 该 source 不允许与 `source_truth=metal_readback` 共用 baseline。
- 该 source 当前只用于 diagnostics / feasibility，不是长期 baseline input contract。

不允许新增或并行支持：

- Metal readback source。
- offscreen renderer source。
- multi-source hash。
- Renderer / Scene source truth。

## 5. Future Diagnostics Fields

如果未来 first slice 修改 harness，最多允许新增这些脱水日志字段：

```text
cjgui frame hash source normalization: requested=true
cjgui frame hash source normalization: source=target_window_screenshot_crop
cjgui frame hash source normalization: source_truth=user_visible_screenshot
cjgui frame hash source normalization: source_normalized=false
cjgui frame hash source normalization: blocked_reason=source_policy_incomplete
cjgui frame hash source normalization: bounds_policy_defined=false
cjgui frame hash source normalization: scale_policy_defined=false
cjgui frame hash source normalization: color_space_defined=false
cjgui frame hash source normalization: pixel_format_defined=false
cjgui frame hash source normalization: decoration_policy_defined=false
cjgui frame hash source normalization: timing_policy_defined=false
cjgui frame hash source normalization: ci_headless_supported=false
cjgui frame hash source normalization: baseline_allowed=false
cjgui frame hash source normalization: hash_value_persistence_allowed=false
cjgui frame hash source normalization: pixel_diff_allowed=false
cjgui frame hash source normalization: success=true reason=none
```

字段语义：

- `requested=true`：harness 请求输出 source normalization readiness diagnostics。
- `source_normalized=false`：当前 source normalization 尚未完成。
- `blocked_reason=source_policy_incomplete`：bounds、scale、color space、pixel format、decoration、timing、CI / headless 等 policy 尚未冻结。
- `*_policy_defined=false`：这些字段只是阻塞说明，不是 runtime source normalization。
- `ci_headless_supported=false`：当前不能声称 CI / headless 可复核。
- `baseline_allowed=false`：当前仍不允许 baseline / golden hash。
- `hash_value_persistence_allowed=false`：当前仍不允许保存或输出 hash value。
- `pixel_diff_allowed=false`：当前仍不允许 pixel diff。
- `success=true reason=none`：只表示 diagnostics summary 成功输出，不是 source normalized、baseline、regression、pixel correctness proof 或 render correctness proof。

## 6. Write Set

未来 bounded implementation first slice 最多允许修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
  - 仅允许增加 source normalization readiness diagnostics。
  - 不得改变 capture、artifact lifecycle、hash feasibility、baseline readiness 或 owner policy 行为。
  - 不得输出 hash value。
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
  - 只记录 source normalization readiness diagnostics 字段和非 baseline 边界。
- future closure review：
  - `docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md`
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

本轮创建 execution card 时允许修改：

- 新建本 execution card。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 如有必要，轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

## 7. Forbidden Write Set

未来 implementation 默认不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- 任何 public runtime API。
- 任何 public C ABI。
- 正式 runtime 目录。
- Renderer / Scene / Widget / Layout / DSL。
- 跨平台 backend。
- 文本、输入法、无障碍相关实现。
- AI semantic tree / Action Router 相关实现。

说明：

- 当前项目实际 build script 路径为 `labs/macos_bridge_smoke/scripts/build_and_run.sh`；该路径禁止修改。
- 如果未来出现 `labs/macos_bridge_smoke/build_and_run.sh`，同样视为 build script 并禁止修改。
- 如果未来发现必须修改 forbidden write set 才能输出 readiness diagnostics，必须暂停并另开 preflight / execution card。

## 8. Truth / Projection

本卡真相层：

- `target_window_screenshot_crop` 当前只是 user-visible screenshot evidence source。
- source normalization 当前事实是未完成。
- baseline 允许状态当前事实是 `baseline_allowed=false`。

本卡只是投影 / read surface 的部分：

- source normalization readiness diagnostics。
- bounds / scale / color space / pixel format / decoration / timing / CI 的 policy completeness flags。
- success / reason summary。

这些 diagnostics 不是：

- source normalized truth。
- baseline truth。
- golden hash。
- pixel diff truth。
- Renderer / Scene truth。
- public runtime API。

## 9. Invariants

未来 first slice 必须守住：

- `source=target_window_screenshot_crop`。
- `source_truth=user_visible_screenshot`。
- `source_normalized=false`。
- `baseline_allowed=false`。
- `hash_value_persistence_allowed=false`。
- `pixel_diff_allowed=false`。
- `hash_persisted=false`。
- `hash_value_logged=false`。
- `baseline_compared=false`。
- success artifact 默认删除。
- failure artifact 只允许短期、受控、可解释保留。
- 不读取或输出 raw bytes。
- 不修改 native bridge / C ABI / public runtime API。

## 10. Verification

未来 implementation first slice 至少要验证：

- 如果修改 harness：
  - `bash -n labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
  - 运行 screenshot verification harness。
  - 运行原有 `verify_auto_close.sh`。
- 原有 screenshot verification needle 仍出现：
  - `target_pid_observed=true`
  - `window_title_matched=true`
  - `window_bounds_observed=true`
  - `sample_points=9`
  - `sample_match=true`
  - `artifact_deleted=true`
  - `artifact_retained=false`
- 原有 frame hash feasibility needle 仍出现：
  - `source=target_window_screenshot_crop`
  - `source_truth=user_visible_screenshot`
  - `algorithm=sha256`
  - `hash_computed=true`
  - `hash_persisted=false`
  - `hash_value_logged=false`
  - `baseline_compared=false`
- 原有 baseline readiness / owner policy needle 仍保持：
  - `baseline_allowed=false`
  - `human_review_required=true`
  - `ai_auto_update_allowed=false`
  - `hash_value_persistence_allowed=false`
  - `pixel_diff_allowed=false`
- 新增 source normalization readiness diagnostics 出现。
- forbidden files 未修改。
- closure review 可从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。
- `git diff --check` 通过。

允许的成功形态：

- source normalization readiness diagnostics 已输出。
- `source_normalized=false` 仍成立。
- `baseline_allowed=false` 仍成立。
- hash value 未输出、未保存。
- baseline / golden hash 未建立。
- baseline compare 未执行。
- pixel diff 未执行。

## 11. Future Closure Review Requirements

未来 closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 是否修改 harness。
- 是否只输出 readiness diagnostics。
- source 是否仍为 `target_window_screenshot_crop`。
- source truth 是否仍为 `user_visible_screenshot`。
- `source_normalized` 是否仍为 `false`。
- `blocked_reason` 是否说明 source policy incomplete。
- bounds / scale / color space / pixel format / decoration / timing / CI / headless policy 是否仍未完成或已单独证明。
- `baseline_allowed` 是否仍为 `false`。
- 是否保存 hash value：必须为否。
- 是否把 hash value 写入日志、文档或仓库：必须为否。
- 是否保存 raw bytes：必须为否。
- 是否保存成功 screenshot artifact：必须为否。
- 是否建立 baseline / golden hash：必须为否。
- 是否做 baseline compare：必须为否。
- 是否做 pixel diff：必须为否。
- 是否修改 native bridge：必须为否。
- 是否新增 public C ABI / runtime API：必须为否。
- 是否把 smoke demo 宣称为正式 GUI runtime：必须为否。

## 12. Stop-line

本轮创建 execution card 的 stop-line：

- 不实现 source normalization。
- 不修改任何 harness。
- 不修改 `labs/macos_bridge_smoke`。
- 不保存 hash value。
- 不把 hash value 写入日志、文档或仓库。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不保存成功 screenshot artifact。
- 不读取或输出 raw bytes。
- 不修改 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

未来 implementation first slice 的 stop-line：

- 只允许 source normalization readiness diagnostics。
- 不允许真正实现 source normalization。
- 不允许改变 `baseline_allowed=false`。
- 不允许保存或输出 hash value。
- 不允许建立 baseline / golden hash。
- 不允许做 baseline compare。
- 不允许 pixel diff。
- 不允许读取或输出 raw bytes。
- 不允许保存成功 screenshot artifact。
- 不允许把 source policy failure 写成 render failure。
- 不允许修改 native bridge。
- 不允许修改 `verify_auto_close.sh`。
- 不允许新增 public C ABI / runtime API。
- 不允许 offscreen renderer。
- 不允许 Renderer / Scene / Widget / Layout / DSL。
- 不允许跨平台抽象。

## 13. Next Opening

本卡之后的 next opening：

> `P1 frame hash source normalization readiness diagnostics bounded implementation first slice`

仍不自动开启实现。

如果继续推进，必须显式确认按本卡执行 bounded implementation；不得自动进入 source normalization implementation、baseline / golden hash、hash value persistence、baseline compare、pixel diff、raw bytes storage、successful screenshot artifact retention、offscreen renderer、native bridge 修改、Renderer / Scene、Widget / Layout / DSL、cross-platform abstraction 或 public runtime API。
