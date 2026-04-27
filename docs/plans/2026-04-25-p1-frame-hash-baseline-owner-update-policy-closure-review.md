# P1 Frame Hash Baseline Owner / Update Policy Closure Review

日期：2026-04-25

性质：closure review / bounded implementation first slice

状态：完成

范围：封账 `P1 frame hash baseline owner / update policy bounded implementation first slice`。本轮只在现有 screenshot verification harness 中增加 owner / update policy 脱水 diagnostics，并同步 smoke README、计划索引和任务账本。

## 1. Authority

本轮唯一 authority：

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md)

背景依据：

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md)
- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)

## 2. 实际 Write Set

本轮实际修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`

## 3. Landed Code Reality

本轮在 screenshot verification harness 中新增：

```text
emit_frame_hash_baseline_owner_policy
```

该函数在 `emit_frame_hash_baseline_readiness` 之后输出 owner / update policy 脱水 diagnostics。

新增日志字段：

```text
cjgui frame hash baseline owner policy: owner_required=human_architect_or_maintainer
cjgui frame hash baseline owner policy: owner_runtime_api=false
cjgui frame hash baseline owner policy: ai_owner_allowed=false
cjgui frame hash baseline owner policy: ai_auto_update_allowed=false
cjgui frame hash baseline owner policy: proposal_required=true
cjgui frame hash baseline owner policy: human_approval_required=true
cjgui frame hash baseline owner policy: approval_flow_runtime_api=false
cjgui frame hash baseline owner policy: baseline_allowed=false
cjgui frame hash baseline owner policy: hash_value_persistence_allowed=false
cjgui frame hash baseline owner policy: baseline_compare_allowed=false
cjgui frame hash baseline owner policy: pixel_diff_allowed=false
cjgui frame hash baseline owner policy: success=true reason=none
```

这些字段只说明 policy / diagnostics：

- baseline owner 未来必须是 human architect / maintainer。
- owner / approval flow 不是 runtime API。
- AI 不能成为 owner，也不能自动更新 baseline。
- proposal 和 human approval 仍然必须存在。
- 当前仍 `baseline_allowed=false`。
- 当前仍不允许 hash value persistence、baseline compare 或 pixel diff。

## 4. Red Check

实现前执行：

```bash
CJGUI_SCREENSHOT_VERIFICATION_LOG=/tmp/cjgui-p1-baseline-owner-policy-red-check.log \
CJGUI_SCREENSHOT_VERIFICATION_PROBE_ERR=/tmp/cjgui-p1-baseline-owner-policy-red-check.err \
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：

- harness exit：`0`
- red check：`expected_missing`
- 实现前日志中没有 `cjgui frame hash baseline owner policy:`
- red check 日志：`/tmp/cjgui-p1-baseline-owner-policy-red-check.log`

## 5. Verification Bundle

### 5.1 Shell Syntax

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：退出码 `0`。

### 5.2 Screenshot Verification Harness

```bash
CJGUI_SCREENSHOT_VERIFICATION_LOG=/tmp/cjgui-p1-baseline-owner-policy-verify.log \
CJGUI_SCREENSHOT_VERIFICATION_PROBE_ERR=/tmp/cjgui-p1-baseline-owner-policy-verify.err \
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：

- 退出码：`0`
- 日志路径：`/tmp/cjgui-p1-baseline-owner-policy-verify.log`
- 原有 screenshot verification 字段仍通过：
  - `target_pid_observed=true`
  - `window_title_matched=true`
  - `window_bounds_observed=true`
  - `sample_points=9`
  - `sample_match=true`
  - `artifact_deleted=true`
  - `artifact_retained=false`
- 原有 frame hash feasibility 字段仍通过：
  - `source=target_window_screenshot_crop`
  - `source_truth=user_visible_screenshot`
  - `algorithm=sha256`
  - `hash_computed=true`
  - `hash_persisted=false`
  - `hash_value_logged=false`
  - `baseline_compared=false`
- 原有 baseline readiness 字段仍通过：
  - `baseline_allowed=false`
  - `human_review_required=true`
  - `ai_auto_update_allowed=false`
  - `hash_value_persistence_allowed=false`
  - `pixel_diff_allowed=false`
- 新增 owner / update policy 字段全部出现。

### 5.3 Auto-close Harness

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- 退出码：`0`
- 日志路径：`/tmp/cjgui-p1-auto-close-verify.log`
- 原有 auto-close、capability、frame metadata / render stats、Metal readback summary 和返回码断言仍通过。

### 5.4 Forbidden File Hash

实现前已记录 forbidden 文件 hash：

```text
/tmp/cjgui-p1-baseline-owner-policy-forbidden-before.sha1
```

实现后复核结果：通过；forbidden 文件 hash 未变化。

### 5.5 Link Check

closure review 链接检查：

- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 可找到本 closure review。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 可找到本 closure review。

### 5.6 Diff Check

```bash
git diff --check
```

结果：通过。

## 6. Stop-line Review

本轮守住：

- 没有写 runtime 代码。
- 没有修改 native bridge。
- 没有修改 Cangjie 入口。
- 没有修改 build script。
- 没有修改 auto-close harness。
- 没有修改 screenshot feasibility harness。
- 没有新增 public C ABI / runtime API。
- 没有保存 hash value。
- 没有输出 hash value。
- 没有建立 baseline / golden hash。
- 没有做 baseline compare。
- 没有做 pixel diff。
- 没有保存 raw bytes。
- 没有保存成功 screenshot artifact。
- 没有做 offscreen renderer。
- 没有设计 Renderer / Scene / Widget / Layout / DSL。
- 没有把 policy failure 写成 render failure。
- 没有把 smoke demo 宣称为正式 GUI runtime。

## 7. Residual Risk

仍然成立：

- baseline / golden hash 仍不允许。
- baseline owner 仍未签署设立。
- baseline update policy 仍未达到可执行 approval gate。
- source normalization 仍未冻结。
- color space / pixel format / crop decoration policy 仍未冻结。
- CI / headless 仍未证明可复核。
- 当前 diagnostics 不是 baseline、不是 regression、不是 pixel diff、不是 pixel correctness proof。

## 8. Next Opening

当前没有自动开启的直接实现 opening。

如果继续推进，推荐下一步仍为 docs-only：

> `P1 frame hash source normalization policy preflight`

该 preflight 只能冻结 target-window screenshot crop 的 source normalization、bounds / scale / color space / pixel format / decoration / timing / CI 分类边界，不得自动进入 baseline / golden hash、hash value persistence、baseline compare、pixel diff、offscreen renderer、public runtime API 或 Renderer / Scene。
