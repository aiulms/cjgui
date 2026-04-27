# P1 Frame Hash Baseline Owner / Update Policy Execution Card

日期：2026-04-25

性质：execution card / docs-only / bounded implementation authorization

状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行

范围：只授权未来一个极窄 policy / diagnostics first slice。本卡不授权 baseline / golden hash、hash value persistence、baseline compare、pixel diff、golden image、raw bytes 保存、成功 screenshot artifact 保留、offscreen renderer、public runtime API、Renderer / Scene、Widget / Layout / DSL 或跨平台抽象。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 唯一确认依据：
  - [2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 只能复用现有 smoke screenshot verification diagnostics / docs 流程。
- 上层尽量仓颉原生：是。不得新增 public C ABI / runtime API，也不得让仓颉层持有 baseline、hash value、artifact、window、display 或平台对象。
- 底层只保留必要平台桥接：是。本卡不允许修改 native bridge。
- 没有过早抽象跨平台：是。本卡只覆盖当前 macOS smoke verification policy，不定义跨平台 baseline contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现需要保存 hash value、建立 baseline / golden hash、做 baseline compare、做 pixel diff、保存 raw bytes、保存成功 screenshot artifact、修改 native bridge、引入 offscreen renderer、设计 Renderer / Scene，或新增 public runtime API，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md)

背景文档：

- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md)
- [2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)
- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡扩展成：

- baseline / golden hash creation。
- hash value persistence。
- baseline compare。
- pixel diff。
- golden image。
- raw bytes storage。
- successful screenshot artifact retention。
- offscreen renderer。
- public C ABI / runtime API。
- Renderer / Scene / Widget / Layout / DSL。

## 2. Goal

未来 first slice 的唯一目标：

> 将 baseline owner / update policy 以脱水 diagnostics 或 checklist 形式写入现有 verification evidence / closure 流程，同时继续保持 `baseline_allowed=false`。

未来 first slice 最多允许回答：

- baseline owner 未来必须是 human architect / maintainer。
- AI 不能成为 baseline owner。
- AI 不能自动更新 baseline。
- AI 最多只能生成 proposal、汇总 evidence、列风险并等待 human approval。
- baseline creation / update / rejection / defer 都必须 human review。
- proposal / approval / rejection / defer flow 是文档化流程，不是 runtime API。

未来 first slice 不允许回答：

- 当前 baseline 已允许。
- 当前 hash value 是什么。
- 当前 baseline 已创建。
- 当前 baseline 是否匹配。
- 当前 pixel diff 是否通过。
- 当前 smoke demo 是否是正式 GUI runtime。

## 3. Owner Boundary

未来 baseline owner 必须是：

```text
human architect / maintainer
```

明确禁止：

- AI 成为 baseline owner。
- screenshot verification harness 成为 baseline owner。
- shell script 成为 baseline owner。
- smoke demo 成为 baseline truth owner。
- 单次 closure review 自动设立 baseline owner。

如果 human architect / maintainer 未明确签署 owner policy，则未来 readiness diagnostics 必须继续保持：

```text
cjgui frame hash baseline readiness: baseline_allowed=false
cjgui frame hash baseline readiness: baseline_owner_defined=false
cjgui frame hash baseline readiness: baseline_update_policy_defined=false
cjgui frame hash baseline readiness: human_review_required=true
cjgui frame hash baseline readiness: ai_auto_update_allowed=false
```

即使未来某一轮补充了 owner / update policy checklist，只要 source normalization、hash storage、artifact baseline storage、CI / headless 或 approval gate 仍未完成，也不得自动改成 `baseline_allowed=true`。

## 4. AI Boundary

AI 未来最多可以：

- 生成 baseline creation / update proposal。
- 汇总 evidence。
- 列出 source、bounds、scale、color space、pixel format、artifact lifecycle、CI / headless 状态。
- 标出 unknown / degraded 字段。
- 列出风险和 stop-line。
- 等待 human approval。

AI 不允许：

- 自动更新 baseline。
- 自动保存 hash value。
- 自动把当前 hash 写成 golden hash。
- 自动提交 artifact。
- 自动建立 baseline compare。
- 自动把 failure artifact 提升为 baseline artifact。
- 自动把 hash mismatch 写成 render failure。
- 自动绕过 owner / review / retention / normalization policy。

## 5. Flow Boundary

proposal / approval / rejection / defer flow 必须是文档化流程：

```text
evidence collected
-> AI or human drafts proposal
-> proposal records unknowns and risks
-> human owner reviews
-> approve | reject | defer
-> closure / ledger records decision
```

该 flow 不是：

- runtime API。
- C ABI。
- public GUI API。
- harness public contract。
- Renderer / Scene API。
- Widget / Layout API。

`approve` 只允许批准进入下一张更窄 execution card；在 baseline storage、source normalization、CI / headless、artifact baseline storage 和 higher approval gate 未完成前，approve 不等于保存 hash value或建立 baseline。

`reject` 必须记录 rejection reason，并且不得保存 hash value、不得保存成功 artifact、不得更新 baseline。

`defer` 必须记录缺失前置，例如 source normalization、CI / headless policy、artifact baseline storage、color space / pixel format policy 或 mismatch classification。

## 6. Future First Slice Boundary

未来 first slice 最多允许：

- 在现有 screenshot verification harness 内增加 owner / update policy 的脱水 diagnostics，或者
- 在 closure review / smoke README 中增加受限 policy checklist。

如果修改 harness，字段必须继续表达：

```text
baseline_allowed=false
baseline_owner_defined=false
baseline_update_policy_defined=false
human_review_required=true
ai_auto_update_allowed=false
```

允许新增或记录的 policy diagnostics 示例：

```text
cjgui frame hash baseline owner policy: owner_required=human_architect_or_maintainer
cjgui frame hash baseline owner policy: owner_runtime_api=false
cjgui frame hash baseline owner policy: ai_owner_allowed=false
cjgui frame hash baseline owner policy: ai_auto_update_allowed=false
cjgui frame hash baseline owner policy: proposal_required=true
cjgui frame hash baseline owner policy: human_approval_required=true
cjgui frame hash baseline owner policy: approval_flow_runtime_api=false
cjgui frame hash baseline owner policy: baseline_allowed=false
```

这些字段只表示 policy / diagnostics：

- 不是 baseline。
- 不是 golden hash。
- 不是 baseline compare。
- 不是 pixel diff。
- 不是 pixel correctness proof。
- 不是 public runtime API。
- 不是 Renderer / Scene truth。

## 7. Write Set

未来 bounded implementation first slice 最多允许修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
  - 仅允许增加 owner / update policy 脱水 diagnostics。
  - 不得改变 `baseline_allowed=false`。
  - 不得输出 hash value。
  - 不得改变 artifact lifecycle。
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
  - 只记录 owner / update policy diagnostics 字段、非 baseline 边界和验证命令。
- future closure review：
  - `docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md`
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

本轮创建 execution card 时允许修改：

- 新建本 execution card。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

## 8. Forbidden Write Set

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

如果未来发现必须修改 forbidden write set 才能输出 policy diagnostics，必须暂停并另开 preflight / execution card。

## 9. Invariants

未来 first slice 必须守住：

- `baseline_allowed=false`。
- `baseline_owner_defined=false`，除非 human owner 明确签署并另有 approval gate。
- `baseline_update_policy_defined=false`，除非 human owner 明确签署并另有 approval gate。
- `human_review_required=true`。
- `ai_auto_update_allowed=false`。
- `hash_value_persistence_allowed=false`。
- `pixel_diff_allowed=false`。
- `hash_persisted=false`。
- `hash_value_logged=false`。
- `baseline_compared=false`。
- success artifact 默认删除。
- failure artifact 只允许短期、受控、可解释保留。

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
- baseline readiness 仍保持：
  - `baseline_allowed=false`
  - `human_review_required=true`
  - `ai_auto_update_allowed=false`
  - `hash_value_persistence_allowed=false`
  - `pixel_diff_allowed=false`
- 新增 owner / update policy diagnostics 或 checklist 输出。
- forbidden files 未修改。
- closure review 可从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。
- `git diff --check` 通过。

允许的成功形态：

- owner / update policy diagnostics 已输出。
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
- 是否只输出 policy / diagnostics 或 checklist。
- baseline owner 是否为 human architect / maintainer。
- AI 是否成为 owner：必须为否。
- AI auto-update 是否 allowed：必须为否。
- human review 是否 required：必须为是。
- proposal / approval / rejection / defer flow 是否仍是文档化流程。
- flow 是否成为 runtime API：必须为否。
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

- 不实现 baseline owner diagnostics。
- 不实现 baseline / golden hash。
- 不实现 baseline update workflow。
- 不保存 hash value。
- 不把 hash value 写入日志、文档或仓库。
- 不保存成功 screenshot artifact。
- 不保存 raw bytes。
- 不实现 baseline compare。
- 不实现 pixel diff。
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

- 只允许 owner / update policy diagnostics 或 checklist。
- 不允许改变 `baseline_allowed=false`。
- 不允许保存 hash value。
- 不允许建立 baseline / golden hash。
- 不允许做 baseline compare。
- 不允许 pixel diff。
- 不允许保存 raw bytes。
- 不允许保存成功 screenshot artifact。
- 不允许把 policy failure 写成 render failure。
- 不允许修改 native bridge。
- 不允许修改 `verify_auto_close.sh`。
- 不允许新增 public C ABI / runtime API。
- 不允许 offscreen renderer。
- 不允许 Renderer / Scene / Widget / Layout / DSL。
- 不允许跨平台抽象。

## 13. Next Opening

本卡之后的 next opening：

> `P1 frame hash baseline owner / update policy bounded implementation first slice`

仍不自动开启实现。

如果继续推进，必须显式确认按本卡执行 bounded implementation；不得自动进入 baseline / golden hash、hash value persistence、baseline compare、pixel diff、golden image、raw bytes storage、successful screenshot artifact retention、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、cross-platform abstraction 或 public runtime API。
