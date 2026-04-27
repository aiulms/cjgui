# P1 Frame Hash Baseline-readiness Diagnostics Closure Review

日期：2026-04-25

状态：完成

类型：bounded implementation closure review

## 1. Authority

唯一 execution card：

- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md)

本轮只执行该 execution card 授权的极窄 first slice。

## 2. 实际 Write Set

实际修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未修改 forbidden write set：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`

## 3. 实现内容

本轮只在现有 screenshot verification harness 内增加 baseline readiness diagnostics summary。

实际边界：

- source 继续只选择 `target_window_screenshot_crop`。
- source truth 继续只声明为 `user_visible_screenshot`。
- summary 只输出脱水 readiness 字段。
- 不保存 hash value。
- 不输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不保存 raw bytes。
- 不保存成功 screenshot artifact。
- 不把 baseline readiness failure 写成 render failure。

实现方式：

- 新增 `emit_frame_hash_baseline_readiness` shell helper。
- helper 固定输出当前 baseline policy readiness 状态。
- helper 挂在 `emit_frame_hash_feasibility` 之后执行，确保现有 frame hash feasibility summary、screenshot verification、artifact lifecycle 和 cleanup 语义保留。
- helper 不读取 artifact、不读取整图像素、不计算新 hash、不输出 hash value、不影响 artifact 删除路径。

## 4. 实际日志格式

本机本次成功路径新增输出：

```text
cjgui frame hash baseline readiness: baseline_readiness_requested=true
cjgui frame hash baseline readiness: source=target_window_screenshot_crop
cjgui frame hash baseline readiness: source_truth=user_visible_screenshot
cjgui frame hash baseline readiness: baseline_allowed=false
cjgui frame hash baseline readiness: baseline_blocked_reason=baseline_policy_incomplete
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

说明：

- `baseline_allowed=false` 是本轮核心事实。
- `baseline_blocked_reason=baseline_policy_incomplete` 表示 baseline owner、update policy、source normalization、color space、pixel format、CI / headless 和 human review gate 尚未完成。
- `success=true reason=none` 只表示 readiness diagnostics summary 已输出，不是 baseline、golden hash、baseline compare、pixel diff、pixel correctness proof 或 render correctness proof。

## 5. 验证记录

Forbidden hash baseline：

```bash
shasum -a 1 \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh \
  > /tmp/cjgui-p1-baseline-readiness-forbidden-before.sha1
```

结果：完成。

Red check：

```bash
CJGUI_SCREENSHOT_VERIFICATION_LOG=/tmp/cjgui-p1-baseline-readiness-red-check.log \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh \
  >/tmp/cjgui-p1-baseline-readiness-red-check.out 2>&1
rg -q "cjgui frame hash baseline readiness:" /tmp/cjgui-p1-baseline-readiness-red-check.log
```

结果：

- harness exit：`0`
- `red_check=expected_missing`
- 说明：实现前旧 harness 不输出 baseline readiness diagnostics。

语法检查：

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：exit `0`

screenshot verification harness：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：

- exit `0`
- 日志路径：`/tmp/cjgui-p1-user-visible-window-screenshot-verification.log`
- 原有 screenshot verification、frame hash feasibility、artifact cleanup、artifact lifecycle 和 success / failure classification 语义保留。
- 新增 baseline readiness diagnostics summary 输出并通过断言。

原有 auto-close harness：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- exit `0`
- 日志路径：`/tmp/cjgui-p1-auto-close-verify.log`
- 原有 capability、frame metadata / render stats、Metal readback summary、auto-close lifecycle needle 仍通过。

Forbidden hash 复核：

```bash
shasum -a 1 \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh \
  > /tmp/cjgui-p1-baseline-readiness-forbidden-after.sha1
cmp -s \
  /tmp/cjgui-p1-baseline-readiness-forbidden-before.sha1 \
  /tmp/cjgui-p1-baseline-readiness-forbidden-after.sha1
```

结果：exit `0`，`forbidden_hash_check=passed`。

链接检查：

```bash
rg -q "2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md" \
  /Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md \
  /Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md
```

结果：exit `0`，closure review 可从 `GUI_TASK_TRACKER.md` 和 `docs/plans/README.md` 找到。

空白差异检查：

```bash
git diff --check
```

结果：exit `0`。

## 6. 断言结果

原有 screenshot verification needle：

- `target_pid_observed=true`
- `window_title_matched=true`
- `window_bounds_observed=true`
- `sample_points=9`
- `sample_match=true`
- `artifact_deleted=true`
- `artifact_retained=false`

原有 frame hash feasibility needle：

- `source=target_window_screenshot_crop`
- `source_truth=user_visible_screenshot`
- `algorithm=sha256`
- `hash_computed=true`
- `hash_persisted=false`
- `hash_value_logged=false`
- `baseline_compared=false`

新增 baseline readiness diagnostics needle：

- `baseline_allowed=false`
- `baseline_blocked_reason=baseline_policy_incomplete`
- `baseline_owner_defined=false`
- `baseline_update_policy_defined=false`
- `human_review_required=true`
- `ai_auto_update_allowed=false`
- `hash_value_persistence_allowed=false`
- `source_normalized=false`
- `color_space_defined=false`
- `pixel_format_defined=false`
- `ci_headless_supported=false`
- `pixel_diff_allowed=false`
- `success=true reason=none`

## 7. Stop-line Review

本轮守住：

- 没有写 runtime 代码。
- 没有修改 native bridge。
- 没有修改 Cangjie 入口。
- 没有修改 `build_and_run.sh`。
- 没有修改 `verify_auto_close.sh`。
- 没有修改 screenshot feasibility harness。
- 没有新增 public C ABI / runtime API。
- 没有保存 hash value。
- 没有输出 hash value。
- 没有建立 baseline / golden hash。
- 没有做 baseline compare。
- 没有做 pixel diff。
- 没有保存 raw bytes。
- 没有保存成功 screenshot artifact。
- 没有提交 artifact。
- 没有做 offscreen renderer。
- 没有设计 Renderer / Scene / Widget / Layout / DSL。
- 没有把 baseline readiness failure 写成 render failure。
- 没有把 smoke demo 宣称为正式 GUI runtime。

## 8. Residual Risk

- 这不是 baseline。
- 这不是 golden hash。
- 这不是 baseline compare。
- 这不是 pixel diff。
- 这不是 pixel correctness proof。
- 这不是 Metal readback truth。
- 这不是 CI / headless proof。
- baseline owner 仍未定义。
- baseline update policy 仍未定义。
- source normalization 仍未定义。
- color space / pixel format 仍未定义。
- human approval gate 仍未落地。
- 这不是 Renderer / Scene / Widget / Layout 设计。
- 这不是正式 GUI runtime。

## 9. Next Opening

当前不自动进入新的实现。

推荐下一步仅做 docs-only：

> `P1 frame hash baseline owner / update policy preflight`

该 preflight 应先冻结 baseline owner、human review、AI auto-update 禁止规则、baseline update proposal / approval / rejection 流程，以及与 source normalization、artifact retention、CI / headless 的关系；不得自动进入 baseline / golden hash、hash value persistence、baseline compare、pixel diff、offscreen renderer、Renderer / Scene 或 public runtime API。
