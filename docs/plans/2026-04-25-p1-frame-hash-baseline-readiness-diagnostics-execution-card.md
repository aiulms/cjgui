# P1 Frame Hash Baseline-readiness Diagnostics Execution Card

日期：2026-04-25

性质：execution card / docs-only / bounded implementation authorization

状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行

范围：只授权未来一个极窄 first slice：`baseline readiness diagnostics`。本卡不授权 baseline / golden hash、hash value persistence、baseline compare、pixel diff、raw bytes 保存、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、public C ABI 或 public runtime API。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 唯一确认依据：
  - [2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 只能复用现有 smoke screenshot verification harness 的诊断日志能力。
- 上层尽量仓颉原生：是。不得新增 public C ABI / runtime API，也不得让仓颉层持有 screenshot、hash、artifact、window、display 或平台对象。
- 底层只保留必要平台桥接：是。本卡不允许修改 native bridge。
- 没有过早抽象跨平台：是。本卡只覆盖当前 macOS smoke verification harness，不定义跨平台 baseline contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现需要保存 hash value、建立 baseline、做 baseline compare、做 pixel diff、读取或保存 raw bytes、保存成功 screenshot artifact、修改 native bridge、引入 offscreen renderer、设计 Renderer / Scene，或新增 public API，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)

背景文档：

- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [2026-04-25-p1-frame-hash-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-execution-card.md)
- [2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)
- [2026-04-25-p1-screenshot-artifact-retention-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡扩展成：

- baseline / golden hash。
- hash value persistence。
- baseline compare。
- pixel diff。
- threshold diff。
- region diff。
- raw bytes artifact。
- screenshot artifact baseline。
- offscreen renderer。
- Metal readback hash。
- public C ABI / runtime API。
- Renderer / Scene / Widget / Layout / DSL。

## 2. Goal

未来 first slice 的唯一目标：

> 在现有 screenshot verification harness 内输出一组脱水 baseline readiness diagnostics summary，明确当前仍不允许 baseline / golden hash。

未来 first slice 只允许回答：

- 当前是否请求 baseline readiness diagnostics。
- 当前是否允许 baseline。
- 当前为什么阻塞 baseline。
- baseline owner / update policy / human review / AI auto-update 是否就绪。
- hash value persistence 是否允许。
- source normalization、color space、pixel format、CI / headless、pixel diff 是否就绪。

未来 first slice 不允许回答：

- 当前 hash value 是什么。
- 当前 baseline 是否匹配。
- 当前 pixel diff 是否通过。
- 当前视觉是否正确。
- 当前 render 是否正确。
- 当前 smoke demo 是否是正式 GUI runtime。

## 3. Source Boundary

未来 first slice 继续只能使用：

```text
target_window_screenshot_crop
```

未来 first slice 继续只能声明：

```text
source_truth=user_visible_screenshot
```

含义：

- 这是 OS / compositor / display presentation 之后的 user-visible screenshot evidence source。
- 它不等同于 Metal readback truth。
- 它不等同于 Renderer / Scene truth。
- 它不等同于 UI state truth。
- 它不构成 public runtime capability。

本卡不允许：

- 同时支持 Metal readback source。
- 同时支持 offscreen renderer source。
- 同时支持多个 source。
- 混用 screenshot hash 与 Metal readback hash。

如果未来需要 Metal readback hash 或 offscreen source，必须另开 preflight / execution card。

## 4. Readiness Diagnostics Boundary

未来 first slice 最多只能输出脱水 readiness summary。

建议字段：

```text
cjgui frame hash baseline readiness: baseline_readiness_requested=true
cjgui frame hash baseline readiness: source=target_window_screenshot_crop
cjgui frame hash baseline readiness: source_truth=user_visible_screenshot
cjgui frame hash baseline readiness: baseline_allowed=false
cjgui frame hash baseline readiness: baseline_blocked_reason=<reason>
cjgui frame hash baseline readiness: baseline_owner_defined=false
cjgui frame hash baseline readiness: baseline_update_policy_defined=false
cjgui frame hash baseline readiness: human_review_required=true
cjgui frame hash baseline readiness: ai_auto_update_allowed=false
cjgui frame hash baseline readiness: hash_value_persistence_allowed=false
cjgui frame hash baseline readiness: source_normalized=false
cjgui frame hash baseline readiness: color_space_defined=false
cjgui frame hash baseline readiness: pixel_format_defined=false
cjgui frame hash baseline readiness: ci_headless_supported=false
cjgui frame hash baseline readiness: pixel_diff_allowed=false
cjgui frame hash baseline readiness: success=true reason=none
```

`baseline_blocked_reason` 建议使用脱水 reason，例如：

- `baseline_owner_missing`
- `source_not_normalized`
- `color_space_unknown`
- `pixel_format_unknown`
- `ci_headless_unsupported`
- `human_review_missing`
- `baseline_policy_incomplete`
- `unknown`

这些字段只表示 readiness diagnostics：

- 不是 baseline。
- 不是 golden hash。
- 不是 regression。
- 不是 baseline compare。
- 不是 pixel diff。
- 不是 pixel correctness proof。
- 不是 compositor correctness proof。
- 不是 Renderer / Scene truth。
- 不是正式 GUI runtime 能力。

## 5. Explicit Non-goals

未来 first slice 不允许：

- 保存 hash value。
- 输出 hash value。
- 把 hash value 写入日志。
- 把 hash value 写入文档。
- 把 hash value 写入仓库。
- 建立 baseline / golden hash。
- 建立 baseline / golden image。
- 保存成功 screenshot artifact。
- 保存 raw bytes。
- 做 baseline compare。
- 做 pixel diff。
- 做 threshold diff。
- 做 region diff。
- 做 offscreen renderer。
- 把 baseline readiness failure 写成 render failure。
- 把 screenshot failure 写成 render failure。
- 把 target mismatch 写成 render failure。
- 把 permission / display / visibility failure 写成 render failure。

## 6. Artifact Retention Policy

未来 implementation 必须继续遵守 screenshot artifact retention policy：

- 成功 artifact 默认删除。
- 失败 artifact 只允许短期、受控、可解释地保留。
- artifact 只能位于 `/tmp` 或 `mktemp -d` 临时目录。
- 历史 `/tmp/cjgui-p1-screenshot-verification.*` 残留清理只允许按 pattern / TTL 执行。
- artifact 不允许进入仓库。
- artifact 不允许提交。
- artifact 不允许进入 baseline / golden image。
- artifact 不允许进入 long-term cache。
- artifact 不允许内联进 Markdown 或日志。
- artifact 内容不允许 base64 写入日志。

baseline readiness diagnostics 不得改变 artifact lifecycle：

- 成功路径仍必须输出 `artifact_deleted=true`、`artifact_retained=false`，或等价字段。
- 失败路径仍必须输出 retention reason、failure classification、path、TTL 和 deletion strategy。
- baseline readiness failure 不能成为保留成功 artifact 的理由。

## 7. Preserve Existing Semantics

未来 first slice 必须继续保留：

- screenshot verification readiness 语义：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- target attribution diagnostics：
  - `target_pid_observed`
  - `window_title_matched`
  - `window_bounds_observed`
  - `frontmost_app_matched`
  - `display_observed`
  - `scale_observed`
- `3x3` clear-color sample summary：
  - `sample_points=9`
  - `sample_match=true|false`
- frame hash feasibility summary：
  - `source=target_window_screenshot_crop`
  - `source_truth=user_visible_screenshot`
  - `algorithm=sha256`
  - `hash_computed=true|false`
  - `hash_persisted=false`
  - `hash_value_logged=false`
  - `baseline_compared=false`
- artifact cleanup summary：
  - `cleanup_requested=true`
  - `cleanup_pattern=/tmp/cjgui-p1-screenshot-verification.*`
  - `cleanup_ttl_hours=24`
  - `cleanup_deleted_count=<n>`
- artifact lifecycle summary：
  - success artifact deleted。
  - failure artifact short controlled retention。
- auto-close harness 语义：
  - `verify_auto_close.sh` 不修改。
  - 原有 capability、frame metadata、Metal readback summary、lifecycle 和 return code needle 仍通过。

## 8. Future Write Set

未来 bounded implementation first slice 最多允许修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
  - 仅允许在现有 screenshot verification harness 内增加 baseline readiness diagnostics summary。
  - 必须保留现有 readiness、target attribution、artifact lifecycle、cleanup、`3x3` sample、frame hash feasibility 和 success / failure classification 语义。
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
  - 只记录 baseline readiness diagnostics 字段、验证命令、artifact policy 和非正式 runtime 边界。
- future closure review：
  - `docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md`
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

本轮创建 execution card 时允许修改：

- 新建本 execution card。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

## 9. Forbidden Write Set

未来 implementation 默认不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- 正式 runtime 目录。
- public GUI API。
- Renderer / Scene / Widget / Layout / DSL。
- 跨平台 backend。
- 文本、输入法、无障碍相关实现。
- AI semantic tree / Action Router 相关实现。

明确回答：

- 是否允许修改 native bridge：不允许。
- 是否允许修改 `verify_auto_close.sh`：不允许。
- 是否允许新增 public C ABI / runtime API：不允许。
- 是否允许做 offscreen renderer：不允许。
- 是否允许设计 Renderer / Scene / Widget / Layout / DSL：不允许。
- 是否允许做跨平台抽象：不允许。

如果未来发现必须修改 forbidden write set 才能输出 readiness diagnostics，必须暂停并另开 preflight / execution card。

## 10. Future Verification Requirements

未来 implementation first slice 至少要验证：

- `bash -n labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
- 运行 screenshot verification harness。
- 运行原有 `verify_auto_close.sh`，确认未破坏。
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
- 新增 baseline readiness diagnostics summary 输出。
- summary 必须说明：
  - baseline requested。
  - baseline allowed false。
  - blocked reason。
  - owner defined false。
  - update policy defined false。
  - human review required true。
  - AI auto update allowed false。
  - hash value persistence allowed false。
  - source normalized false。
  - CI / headless supported false。
  - pixel diff allowed false。
- forbidden files 未修改。
- closure review 可从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。
- `git diff --check` 通过。

允许的成功形态：

- `success=true reason=none`
- `baseline_allowed=false`
- `hash_value_persistence_allowed=false`
- `pixel_diff_allowed=false`

允许的失败形态：

- `success=false reason=<classification>`
- 失败分类必须诚实；不能把 permission / display / target / visibility / readiness prerequisite failure 写成 render failure。

## 11. Future Closure Review Requirements

未来 closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 是否只选择了 `target_window_screenshot_crop` source。
- source truth 是否仍为 `user_visible_screenshot`。
- 是否修改 native bridge：必须为否。
- 是否修改 `verify_auto_close.sh`：必须为否。
- 是否新增 public C ABI / runtime API：必须为否。
- baseline readiness summary 实际日志格式。
- baseline 是否允许：必须为否。
- baseline blocked reason。
- baseline owner 是否定义：必须为否。
- baseline update policy 是否定义：必须为否。
- human review 是否 required：必须为是。
- AI auto update 是否 allowed：必须为否。
- hash value persistence 是否 allowed：必须为否。
- source normalized 是否已完成：必须为否，除非另有 execution card。
- color space / pixel format 是否 defined。
- CI / headless 是否 supported：必须为否。
- pixel diff 是否 allowed：必须为否。
- 是否保存 hash value：必须为否。
- 是否保存 raw bytes：必须为否。
- 是否保存成功 screenshot artifact：必须为否。
- 是否建立 baseline / golden hash：必须为否。
- 是否做 baseline compare：必须为否。
- 是否做 pixel diff：必须为否。
- 是否把 readiness failure 写成 render failure：必须为否。
- artifact success / failure retention 行为。
- 原有 frame hash feasibility summary 是否仍通过或诚实分类失败。
- 原有 auto-close harness 是否仍通过。
- residual risk：
  - 这不是 baseline。
  - 这不是 golden hash。
  - 这不是 baseline regression。
  - 这不是 pixel diff。
  - 这不是 pixel correctness proof。
  - 这不是 Metal readback truth。
  - 这不是 CI / headless proof。
  - 这不是 Renderer / Scene / Widget / Layout 设计。
  - 这不是正式 GUI runtime。

## 12. Stop-line

本轮创建 execution card 的 stop-line：

- 不实现 baseline readiness diagnostics。
- 不实现 baseline / golden hash。
- 不实现 pixel diff。
- 不实现 baseline compare。
- 不保存 hash value。
- 不保存 raw bytes。
- 不保存成功 screenshot artifact。
- 不修改 screenshot verification harness。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 `verify_auto_close.sh`。
- 不修改 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

未来 implementation first slice 的 stop-line：

- 只允许 baseline readiness diagnostics。
- 不允许保存 hash value。
- 不允许建立 baseline / golden hash。
- 不允许做 baseline compare。
- 不允许 pixel diff。
- 不允许保存 raw bytes。
- 不允许保存成功 screenshot artifact。
- 不允许把 baseline readiness failure 写成 render failure。
- 不允许修改 native bridge。
- 不允许修改 `verify_auto_close.sh`。
- 不允许新增 public C ABI / runtime API。
- 不允许 offscreen renderer。
- 不允许 Renderer / Scene / Widget / Layout / DSL。
- 不允许跨平台抽象。

## 13. Next Opening

本卡之后的 next opening：

> `P1 frame hash baseline-readiness diagnostics bounded implementation first slice`

仍不自动开启实现。

如果继续推进，必须显式确认按本卡执行 bounded implementation；不得自动进入 baseline / golden hash、hash value persistence、baseline compare、pixel diff、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、cross-platform abstraction 或 public runtime API。
