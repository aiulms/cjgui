# P1 Frame Hash Baseline Owner / Update Policy Preflight

日期：2026-04-25

性质：docs-only / baseline owner policy preflight / no implementation

状态：完成；不批准直接实现

范围：冻结未来 baseline / golden hash 的 owner、human review、AI auto-update 禁止规则，以及 baseline update proposal / approval / rejection 流程。本轮不实现 baseline，不保存 hash value，不修改 harness，不修改 runtime。

## 1. 背景

当前已经完成：

- [P1 frame hash feasibility first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [P1 frame hash evidence review / baseline policy preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)
- [P1 frame hash baseline-readiness diagnostics first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)

当前 evidence 表明：

- `target_window_screenshot_crop` 可以作为当前本机一次 user-visible screenshot evidence source。
- 当前运行内可以计算 `sha256` feasibility summary。
- hash value 没有输出、没有持久化。
- baseline compare 没有执行。
- 成功 screenshot artifact 默认删除。
- baseline readiness diagnostics 已明确输出 `baseline_allowed=false`。

这些 evidence 仍然不足以允许 baseline / golden hash。

## 2. 当前是否允许 Baseline / Golden Hash

结论：

> 当前不允许建立 baseline / golden hash。

不允许的范围：

- 不允许建立 baseline / golden hash。
- 不允许建立 baseline / golden image。
- 不允许保存 hash value。
- 不允许把 hash value 写入日志、文档或仓库。
- 不允许做 baseline compare。
- 不允许把 hash mismatch 写成 render failure。
- 不允许保存成功 screenshot artifact 作为 baseline 输入。
- 不允许把 failure artifact 提升为 baseline artifact。
- 不允许进入 pixel diff。

原因：

- baseline owner 尚未设立。
- baseline creation / update / rejection 流程尚未冻结。
- source normalization 尚未冻结。
- color space / pixel format / scale / decoration / crop policy 尚未冻结。
- artifact retention policy 仍禁止成功 artifact 长期保留。
- CI / headless 复核策略尚未冻结。
- 当前 smoke demo 不是正式 GUI runtime。

## 3. Baseline Owner

当前 owner：

> 尚未设立。

未来 baseline owner 应该是显式 human owner，而不是 harness、脚本、AI 或单次 closure review 自然继承。

建议 owner 分层：

- `Baseline Owner`：human architect / human maintainer，负责批准 baseline creation、update、rejection 和 defer。
- `Verification Harness Owner`：负责 screenshot capture、target attribution、artifact cleanup、failure classification 和 diagnostics 输出。
- `Evidence Producer`：可以是 AI 或人工运行者，负责生成 proposal、汇总 evidence、列出风险。
- `Future Renderer / Scene Owner`：未来如果 Renderer / Scene 出现，负责声明 render input / scene truth；当前 P1 smoke 阶段尚未设立。

当前阶段只确认：

- human architect / maintainer 是唯一可批准 baseline policy 的角色。
- AI 不能成为 baseline owner。
- screenshot verification harness 不能成为 baseline owner。
- 当前 smoke demo 不能成为 baseline truth owner。

## 4. Creation / Update / Rejection Approval

### 4.1 Baseline Creation

未来 baseline creation 必须由 human architect / maintainer 批准。

批准前必须至少完成：

- baseline owner 已明确。
- source truth 已唯一选择。
- source normalization 已冻结。
- artifact retention / privacy / cleanup policy 已冻结。
- hash value storage / deletion / access policy 已冻结。
- CI / headless classification policy 已冻结。
- mismatch classification 已冻结。
- human review 记录已写入 closure / approval 文档。

当前不满足，因此 creation 不允许。

### 4.2 Baseline Update

未来 baseline update 必须由 human architect / maintainer 批准。

AI 不允许自动更新 baseline。

更新前必须说明：

- 更新原因是 intentional visual change、capture policy change、source normalization change、environment policy change，还是旧 baseline 错误。
- 是否存在 render regression、capture failure、target mismatch、permission / display issue、window occlusion 或 timing risk。
- 更新是否影响 historical comparability。
- 是否需要同时更新 documentation、CI matrix 或 artifact retention policy。

### 4.3 Baseline Rejection

baseline proposal 可以被 human architect / maintainer 拒绝。

拒绝原因应分类，例如：

- `owner_missing`
- `source_not_normalized`
- `artifact_policy_incomplete`
- `ci_headless_unsupported`
- `color_space_unknown`
- `pixel_format_unknown`
- `target_attribution_unstable`
- `window_occlusion_risk`
- `hash_value_policy_missing`
- `insufficient_evidence`
- `not_a_baseline_change`

被拒绝的 proposal 不得由 AI 重试为“自动更新”。

### 4.4 Defer

proposal 可以 defer。

defer 表示：

- 当前 evidence 不足。
- 不判断为 render failure。
- 不更新 baseline。
- 不保存 hash value。
- 不保留成功 artifact。
- 后续需要先补 preflight 或 execution card。

## 5. Human Review

结论：

> Human review 必须存在。

human review 至少要确认：

- proposal 的 source truth 是否正确。
- evidence 是否来自目标 smoke window。
- artifact lifecycle 是否合规。
- hash value 是否未泄露。
- CI / headless 是否诚实分类。
- mismatch / failure 是否没有被误写成 render failure。
- 本次是否真的应该创建或更新 baseline。

human review 不能被以下内容替代：

- harness exit `0`。
- `hash_computed=true`。
- `sample_match=true`。
- `baseline_readiness_requested=true`。
- AI 自动总结。
- 单次本机 screenshot 成功。

## 6. AI Auto-update Policy

结论：

> AI 不允许自动更新 baseline。

AI 未来最多可以做：

- 生成 baseline creation / update proposal。
- 汇总 evidence。
- 列出 source、bounds、scale、color space、pixel format、artifact lifecycle、CI / headless 状态。
- 标出未知项和降级项。
- 列出 mismatch / failure classification 候选。
- 标出 stop-line 和 residual risk。
- 等待 human approval。

AI 不允许：

- 自动保存 hash value。
- 自动把当前 hash 写成 golden hash。
- 自动更新 baseline 文件。
- 自动提交 artifact。
- 自动把 failure artifact 提升为 baseline artifact。
- 自动把 hash mismatch 标成 render failure。
- 自动绕过 owner / review / retention / normalization policy。

## 7. Baseline Update Proposal Evidence

未来 proposal 至少必须包含：

- proposal id / 日期 / 发起者。
- 本轮 authority 文档。
- 当前 source：
  - `source=target_window_screenshot_crop`
  - `source_truth=user_visible_screenshot`
- 截图归属 evidence：
  - `target_pid_observed`
  - `window_title_matched`
  - `window_bounds_observed`
  - `frontmost_app_matched`
  - `display_observed`
  - `scale_observed`
  - `capture_covers_target_bounds`
- artifact lifecycle evidence：
  - 成功 artifact 是否删除。
  - 失败 artifact 是否短期保留。
  - artifact path 是否只在 `/tmp` / `mktemp -d`。
  - 是否未提交 artifact。
  - 是否未进入 baseline。
- sample evidence：
  - `sample_points=9`
  - `sample_match=true|false`
- frame hash feasibility evidence：
  - `algorithm=sha256`
  - `hash_computed=true|false`
  - `hash_persisted=false`
  - `hash_value_logged=false`
  - `baseline_compared=false`
- baseline readiness evidence：
  - `baseline_allowed=false`
  - `baseline_blocked_reason=<reason>`
  - `baseline_owner_defined=<true|false>`
  - `baseline_update_policy_defined=<true|false>`
  - `human_review_required=true`
  - `ai_auto_update_allowed=false`
  - `hash_value_persistence_allowed=false`
  - `source_normalized=<true|false>`
  - `color_space_defined=<true|false>`
  - `pixel_format_defined=<true|false>`
  - `ci_headless_supported=<true|false>`
  - `pixel_diff_allowed=false`
- environment / risk evidence：
  - OS / display / scale / color space / pixel format / CI availability if known.
  - unknown / degraded fields if not known.
  - window occlusion / Space / Mission Control / timing risk.
- explicit negative assertions：
  - no raw bytes saved.
  - no hash value logged.
  - no successful screenshot artifact retained.
  - no pixel diff.
  - no baseline compare.
  - no public runtime API.

本轮仍不允许 proposal 保存 hash value。

## 8. Approval / Rejection / Defer Flow

未来流程应为：

```text
evidence collected
-> AI or human drafts proposal
-> proposal records unknowns and risks
-> human owner reviews
-> approve | reject | defer
-> closure / ledger records decision
```

### Approve

`approve` 只表示 human owner 同意进入下一张更窄 execution card。

在真正 baseline policy 完成前，approve 仍不等于：

- 保存 hash value。
- 建立 baseline。
- 执行 baseline compare。
- 开启 pixel diff。

### Reject

`reject` 表示该 proposal 不能继续。

reject 后：

- 不保存 hash value。
- 不保存成功 artifact。
- 不更新 baseline。
- 不把 mismatch 写成 render failure。
- 必须记录 rejection reason。

### Defer

`defer` 表示需要先补前置条件。

常见 defer 前置条件：

- source normalization preflight。
- artifact retention / baseline storage preflight。
- CI / headless policy preflight。
- color space / pixel format policy preflight。
- mismatch classification preflight。

## 9. Owner 与其他 Policy 的关系

### 9.1 Source Normalization

baseline owner 不能绕过 source normalization。

如果 source normalization 未冻结：

- `baseline_allowed=false` 必须继续成立。
- proposal 只能记录 unknown / degraded。
- 不能保存 hash value。
- 不能建立 baseline。

### 9.2 Artifact Retention

baseline owner 不能绕过 artifact retention policy。

当前约束：

- 成功 screenshot artifact 默认删除。
- 失败 artifact 只允许短期、受控、可解释保留。
- failure artifact 不能提升为 baseline artifact。
- artifact 不能进入仓库。
- artifact 不能进入 baseline / golden image。

如果未来要允许 baseline artifact，必须先另开 artifact / baseline storage preflight。

### 9.3 CI / Headless

baseline owner 不能声称 CI / headless 已支持。

在 CI / headless policy 未冻结前：

- display / permission / target / visibility failure 必须诚实分类。
- skipped / unavailable 不能写成 pass。
- CI 不可用不能写成 render failure。
- baseline compare 不能开启。

## 10. Hash Value Policy

本轮答案：

> hash value 不允许保存。

继续禁止：

- hash value 写入日志。
- hash value 写入文档。
- hash value 写入仓库。
- hash value 长期保存。
- hash value 作为 closure evidence。
- hash value 被 AI 自动复制为 golden value。

原因：

- 当前没有 owner / storage / review / update / deletion policy。
- 当前 source normalization 不完整。
- 当前 `color_space=unknown` / `pixel_format=unknown` 仍可能存在。
- 当前 CI / headless 不可复核。
- hash value 一旦进入文档或仓库，容易被误当成长期 truth。

## 11. Artifact 与 Baseline 输入

成功 screenshot artifact：

> 不允许作为 baseline 输入。

失败 artifact：

> 不能提升为 baseline artifact。

原因：

- 成功 artifact 当前默认删除，是 artifact retention policy 的核心约束。
- 失败 artifact 只服务 failure diagnosis。
- baseline artifact 是长期期望输出，必须有 owner、review、privacy、storage、update、deletion policy。
- `/tmp` 临时目录中的 artifact 不能自然升级为 baseline。

## 12. Harness 行为

baseline owner 未设立时，harness 应继续输出：

```text
cjgui frame hash baseline readiness: baseline_allowed=false
cjgui frame hash baseline readiness: baseline_blocked_reason=baseline_policy_incomplete
cjgui frame hash baseline readiness: baseline_owner_defined=false
cjgui frame hash baseline readiness: baseline_update_policy_defined=false
cjgui frame hash baseline readiness: human_review_required=true
cjgui frame hash baseline readiness: ai_auto_update_allowed=false
```

如果未来仅完成 owner policy，但 source normalization、hash storage、CI / headless 或 artifact baseline storage 仍未完成，harness 仍不得自动变成 `baseline_allowed=true`。

`baseline_allowed=true` 必须另有更高层 approval gate，并且不得由本 preflight 或当前 harness 自行决定。

## 13. Pixel Diff 是否可以作为下一步

结论：

> 不可以。

原因：

- baseline / golden hash 仍不允许。
- golden image / baseline artifact 仍不允许。
- source normalization 未冻结。
- threshold / color space / scale / alpha / anti-aliasing policy 未冻结。
- CI / headless 不可复核。
- mismatch classification 未冻结。
- 当前 smoke demo 只有 clear-color，pixel diff 容易把偶然画面写成长期 truth。

下一步不能是 pixel diff execution card。

## 14. Future Execution Card 最大边界

如果未来继续推进，下一张最多只能是 docs-only：

> `P1 frame hash baseline owner / update policy execution card`

该 execution card 最多只能授权一个极窄 policy / diagnostics first slice，例如：

- 在文档中正式声明 baseline owner 仍为 human architect / maintainer。
- 在 readiness diagnostics 或 closure review 中继续记录 `baseline_owner_defined=false` / `baseline_update_policy_defined=false`，除非 human owner 明确签署。
- 将 proposal / approval / rejection / defer 流程写成受限 checklist。
- 不保存 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不修改 native bridge。
- 不新增 public C ABI / runtime API。

它不能授权：

- baseline / golden hash creation。
- hash value persistence。
- baseline compare。
- pixel diff。
- golden image。
- raw bytes storage。
- success artifact retention。
- offscreen renderer。
- Renderer / Scene / Widget / Layout / DSL。

## 15. Stop-line

本轮明确不做：

- 不实现 baseline / golden hash。
- 不实现 baseline owner runtime。
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

## 16. Next Opening

当前没有自动开启的直接实现 opening。

推荐下一步仍为 docs-only：

> `P1 frame hash baseline owner / update policy execution card`

该 execution card 必须继续禁止 baseline / golden hash、hash value persistence、baseline compare、pixel diff、offscreen renderer、native bridge 修改、public runtime API 和 Renderer / Scene。
