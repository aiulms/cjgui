# P1 Frame Hash Source Normalization Readiness Diagnostics Closure Review

日期：2026-04-25

性质：closure review / bounded implementation first slice

状态：完成

范围：封账 `P1 frame hash source normalization readiness diagnostics bounded implementation first slice`。本轮只在现有 screenshot verification harness 中增加 source normalization readiness 脱水 diagnostics，并同步 smoke README、计划索引和任务账本。

## 1. Authority

本轮唯一 authority：

- [2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md)

背景依据：

- [2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)
- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)
- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)

## 2. Actual Write Set

本轮实际修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未修改 forbidden write set：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- public C ABI / public runtime API
- Renderer / Scene / Widget / Layout / DSL
- offscreen renderer

## 3. Landed Code Reality

本轮在 screenshot verification harness 中新增：

```text
emit_frame_hash_source_normalization
```

该 helper 由现有 `emit_frame_hash_baseline_owner_policy` 之后调用，位于 frame hash feasibility / baseline readiness / owner policy diagnostics 链路末尾。

实际边界：

- 不改变 screenshot capture。
- 不改变 artifact 创建、成功删除或失败短期保留策略。
- 不改变当前运行内 frame hash feasibility 行为。
- 不改变 baseline readiness 行为。
- 不改变 baseline owner / update policy 行为。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。

## 4. Actual Diagnostics Format

本轮新增日志字段：

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

- `source=target_window_screenshot_crop`：继续只使用 target-window screenshot crop。
- `source_truth=user_visible_screenshot`：该 source 是用户可见截图证据，不是 Metal readback truth、offscreen renderer truth 或 Renderer / Scene truth。
- `source_normalized=false`：当前 source normalization 尚未完成。
- `blocked_reason=source_policy_incomplete`：bounds、scale、color space、pixel format、decoration、timing、CI / headless 等 policy 尚未冻结。
- `baseline_allowed=false`：当前仍不允许 baseline / golden hash。
- `hash_value_persistence_allowed=false`：当前仍不允许保存或输出 hash value。
- `pixel_diff_allowed=false`：当前仍不允许 pixel diff。
- `success=true reason=none`：只表示 diagnostics summary 成功输出，不是 source normalized、baseline、regression、pixel correctness proof 或 render correctness proof。

## 5. Red Check

实现前执行：

```bash
CJGUI_SCREENSHOT_VERIFICATION_LOG=/tmp/cjgui-p1-source-normalization-red-check.log \
CJGUI_SCREENSHOT_VERIFICATION_PROBE_ERR=/tmp/cjgui-p1-source-normalization-red-check.err \
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh \
  >/tmp/cjgui-p1-source-normalization-red-check.out 2>&1
```

结果：

- harness exit：`0`
- red check：`expected_missing`
- 实现前日志中没有 `cjgui frame hash source normalization:`
- red check 日志：`/tmp/cjgui-p1-source-normalization-red-check.log`

## 6. Verification Bundle

### 6.1 Shell Syntax

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：退出码 `0`。

### 6.2 Screenshot Verification Harness

```bash
CJGUI_SCREENSHOT_VERIFICATION_LOG=/tmp/cjgui-p1-source-normalization-verify.log \
CJGUI_SCREENSHOT_VERIFICATION_PROBE_ERR=/tmp/cjgui-p1-source-normalization-verify.err \
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：

- 退出码：`0`
- 日志路径：`/tmp/cjgui-p1-source-normalization-verify.log`
- probe stderr 路径：`/tmp/cjgui-p1-source-normalization-verify.err`
- artifact 成功路径：`artifact_deleted=true`、`artifact_retained=false`
- 最终 summary：`cjgui screenshot verification: success=true reason=none`

原有 screenshot verification 字段仍通过：

- `target_pid_observed=true`
- `window_title_matched=true`
- `window_bounds_observed=true`
- `sample_points=9`
- `sample_match=true`
- `artifact_deleted=true`
- `artifact_retained=false`

原有 frame hash feasibility 字段仍通过：

- `source=target_window_screenshot_crop`
- `source_truth=user_visible_screenshot`
- `algorithm=sha256`
- `hash_computed=true`
- `hash_persisted=false`
- `hash_value_logged=false`
- `baseline_compared=false`

原有 baseline readiness / owner policy 字段仍保持：

- `baseline_allowed=false`
- `human_review_required=true`
- `ai_auto_update_allowed=false`
- `hash_value_persistence_allowed=false`
- `pixel_diff_allowed=false`

新增 source normalization readiness diagnostics 全部出现：

- `requested=true`
- `source=target_window_screenshot_crop`
- `source_truth=user_visible_screenshot`
- `source_normalized=false`
- `blocked_reason=source_policy_incomplete`
- `bounds_policy_defined=false`
- `scale_policy_defined=false`
- `color_space_defined=false`
- `pixel_format_defined=false`
- `decoration_policy_defined=false`
- `timing_policy_defined=false`
- `ci_headless_supported=false`
- `baseline_allowed=false`
- `hash_value_persistence_allowed=false`
- `pixel_diff_allowed=false`
- `success=true reason=none`

### 6.3 Explicit Log Assertions

```bash
LOG=/tmp/cjgui-p1-source-normalization-verify.log
# checked original screenshot, frame hash, baseline readiness / owner policy,
# and all new source normalization readiness diagnostics needles.
```

结果：

- `source_normalization_log_assertions=passed`

### 6.4 Auto-close Harness

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- 退出码：`0`
- 日志路径：`/tmp/cjgui-p1-auto-close-verify.log`
- 原有 auto-close、capability、frame metadata / render stats、Metal readback summary 和返回码断言仍通过。
- 结果行：`cjgui verify: auto-close log assertions passed`

### 6.5 Forbidden File Hash

实现前记录 forbidden 文件 hash：

```text
/tmp/cjgui-p1-source-normalization-forbidden-before.sha256
```

实现后复核：

```bash
cmp -s \
  /tmp/cjgui-p1-source-normalization-forbidden-before.sha256 \
  /tmp/cjgui-p1-source-normalization-forbidden-after.sha256
```

结果：

- 退出码：`0`
- `forbidden_hash_check=passed`

### 6.6 Link Check

closure review 链接检查：

- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 可找到本 closure review。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 可找到本 closure review。

### 6.7 Diff Check

```bash
git diff --check
```

结果：退出码 `0`。

## 7. Stop-line Review

本轮守住：

- 没有实现真正 source normalization。
- 没有把 `source_normalized` 改成 `true`。
- 没有保存或输出 hash value。
- 没有建立 baseline / golden hash。
- 没有做 baseline compare。
- 没有做 pixel diff。
- 没有读取或输出 raw bytes。
- 没有保存成功 screenshot artifact。
- 没有修改 native bridge。
- 没有修改仓颉入口。
- 没有修改 build script。
- 没有修改 auto-close harness。
- 没有修改 screenshot feasibility harness。
- 没有新增 public C ABI / runtime API。
- 没有做 offscreen renderer。
- 没有设计 Renderer / Scene / Widget / Layout / DSL。
- 没有把 smoke demo 宣称为正式 GUI runtime。

## 8. What This Proves

本轮只证明：

- 现有 screenshot verification harness 可以输出 source normalization readiness diagnostics。
- 当前 source 仍固定为 `target_window_screenshot_crop`。
- 当前 source truth 仍固定为 `user_visible_screenshot`。
- 当前 source normalization 仍明确为未完成。
- 当前 baseline 仍明确为不允许。
- 当前 hash value persistence、baseline compare 和 pixel diff 仍明确为不允许。
- 原有 screenshot verification、frame hash feasibility、baseline readiness、owner policy、artifact lifecycle 和 auto-close harness 语义未被破坏。

## 9. What This Does Not Prove

本轮不证明：

- source normalization 已完成。
- bounds / scale / color space / pixel format / decoration / timing policy 已冻结。
- baseline / golden hash 已允许。
- baseline compare 已允许。
- pixel diff 已允许。
- hash value 可以保存或输出。
- target-window screenshot crop 可以成为长期 baseline contract。
- CI / headless 可复核。
- Metal readback truth、offscreen renderer truth 或 Renderer / Scene truth。
- 当前 smoke demo 是正式 GUI runtime。

## 10. Residual Risk

仍然成立：

- source normalization 仍未完成。
- bounds、scale、color space、pixel format、window decoration、timing 和 CI / headless policy 仍需后续 docs-only 边界冻结。
- baseline / golden hash 仍不允许。
- hash value 仍不允许保存或输出。
- baseline compare、pixel diff 和 offscreen renderer 仍不允许。
- 当前 diagnostics 只是 readiness summary，不是 regression proof。

## 11. Next Opening

当前没有自动开启的直接实现 opening。

推荐下一步仅做 docs-only：

> `P1 frame hash source normalization evidence closure / next-boundary preflight`

该 preflight 只能复核 source normalization readiness diagnostics evidence，并判断下一条边界应该继续冻结 source normalization 的哪一项；不得自动进入真正 source normalization implementation、baseline / golden hash、hash value persistence、baseline compare、pixel diff、offscreen renderer、public runtime API 或 Renderer / Scene / Widget / Layout / DSL。
