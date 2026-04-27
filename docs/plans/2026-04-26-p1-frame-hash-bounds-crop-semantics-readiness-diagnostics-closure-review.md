# P1 Frame Hash Bounds / Crop Semantics Readiness Diagnostics Closure Review

日期：2026-04-26

性质：closure review / bounded implementation first slice

状态：完成

范围：封账 `P1 frame hash bounds / crop semantics readiness diagnostics bounded implementation first slice`。本轮只在现有 screenshot verification harness 中增加 bounds / crop semantics readiness 脱水 diagnostics，并同步 smoke README、计划索引和任务账本。

## 1. Authority

本轮唯一 authority：

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md)

背景依据：

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md)
- [2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md)
- [2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md)
- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)

## 2. Actual Write Set

本轮实际修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md)
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
- native bridge
- Renderer / Scene / Widget / Layout / DSL
- offscreen renderer
- baseline / golden hash / pixel diff 相关实现

## 3. Landed Code Reality

本轮在 screenshot verification harness 中新增：

```text
emit_frame_hash_bounds_crop_semantics
```

该 helper 由现有 `emit_frame_hash_source_normalization` 末尾调用，位于 frame hash feasibility / baseline readiness / owner policy / source normalization readiness diagnostics 链路末尾。

实际边界：

- 不改变 screenshot capture 行为。
- 不改变 artifact 创建、成功删除或失败短期保留策略。
- 不改变当前运行内 frame hash feasibility 行为。
- 不改变 baseline readiness 行为。
- 不改变 baseline owner / update policy 行为。
- 不改变 source normalization readiness 行为。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不实现真正 bounds normalization。
- 不实现 content interior extraction。

## 4. Actual Diagnostics Format

本轮新增日志字段：

```text
cjgui frame hash bounds crop semantics: requested=true
cjgui frame hash bounds crop semantics: source=target_window_screenshot_crop
cjgui frame hash bounds crop semantics: source_truth=user_visible_screenshot
cjgui frame hash bounds crop semantics: screen_bounds_points_observed=true
cjgui frame hash bounds crop semantics: capture_bounds_pixels_observed=true
cjgui frame hash bounds crop semantics: target_window_crop_bounds_observed=true
cjgui frame hash bounds crop semantics: content_interior_bounds_observed=false
cjgui frame hash bounds crop semantics: hash_input_bounds_defined=false
cjgui frame hash bounds crop semantics: point_pixel_conversion_defined=false
cjgui frame hash bounds crop semantics: rounding_policy_defined=false
cjgui frame hash bounds crop semantics: decoration_policy_defined=false
cjgui frame hash bounds crop semantics: content_interior_extraction_allowed=false
cjgui frame hash bounds crop semantics: whole_window_crop_baseline_allowed=false
cjgui frame hash bounds crop semantics: source_normalized=false
cjgui frame hash bounds crop semantics: baseline_allowed=false
cjgui frame hash bounds crop semantics: hash_value_persistence_allowed=false
cjgui frame hash bounds crop semantics: pixel_diff_allowed=false
cjgui frame hash bounds crop semantics: success=true reason=none
```

字段语义：

- `screen_bounds_points_observed=true`、`capture_bounds_pixels_observed=true`、`target_window_crop_bounds_observed=true` 只表示当前 harness 已有相关 diagnostics，不表示它们是 hash input contract。
- `content_interior_bounds_observed=false` 是硬边界；当前没有 content interior source，也没有 content interior extraction。
- `hash_input_bounds_defined=false` 是硬边界；当前尚未定义 hash 哪个矩形。
- `whole_window_crop_baseline_allowed=false` 是硬边界；whole window crop 不能升级为 baseline input contract。
- `success=true reason=none` 只表示 diagnostics 输出成功，不表示 bounds 已 normalized。

## 5. Red Check

实现前执行：

```bash
CJGUI_SCREENSHOT_VERIFICATION_LOG=/tmp/cjgui-p1-bounds-crop-red-check.log \
CJGUI_SCREENSHOT_VERIFICATION_PROBE_ERR=/tmp/cjgui-p1-bounds-crop-red-check.err \
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh \
  >/tmp/cjgui-p1-bounds-crop-red-check.out 2>&1
```

结果：

- harness exit：`0`
- red check：`expected_missing`
- 实现前日志中没有 `cjgui frame hash bounds crop semantics:`
- red check 日志：`/tmp/cjgui-p1-bounds-crop-red-check.log`

说明：第一次 red-check 包装脚本使用了 zsh 只读变量名 `status`，导致包装命令自身失败；已用 `harness_rc` 重新执行，以上结果来自重新执行后的有效 red check。

## 6. Verification Bundle

### 6.1 Shell Syntax

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

结果：退出码 `0`。

### 6.2 Screenshot Verification Harness

```bash
CJGUI_SCREENSHOT_VERIFICATION_LOG=/tmp/cjgui-p1-bounds-crop-verify.log \
CJGUI_SCREENSHOT_VERIFICATION_PROBE_ERR=/tmp/cjgui-p1-bounds-crop-verify.err \
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh \
  >/tmp/cjgui-p1-bounds-crop-verify.out 2>&1
```

结果：

- 退出码：`0`
- 日志路径：`/tmp/cjgui-p1-bounds-crop-verify.log`
- probe stderr 路径：`/tmp/cjgui-p1-bounds-crop-verify.err`
- probe stderr 大小：`0 bytes`
- stdout 捕获路径：`/tmp/cjgui-p1-bounds-crop-verify.out`
- artifact 成功路径：`artifact_deleted=true`、`artifact_retained=false`
- 最终 summary：`cjgui screenshot verification: success=true reason=none`

本次 observed diagnostics：

```text
cjgui screenshot verification: target_bounds=398,141,716,446
cjgui screenshot verification: artifact_size=1432x892
cjgui frame hash feasibility: bounds=398,141,716,446
cjgui frame hash feasibility: scale=2.00
```

这些 observed bounds 仍只是 diagnostics，不是 hash input contract。

### 6.3 Explicit Log Assertions

日志断言结果：

- 原有 screenshot verification diagnostics 仍在。
- 原有 frame hash feasibility diagnostics 仍在。
- 原有 source normalization readiness diagnostics 仍在。
- 新增 bounds / crop semantics diagnostics 全部出现。
- `content_interior_bounds_observed=false` 出现。
- `hash_input_bounds_defined=false` 出现。
- `whole_window_crop_baseline_allowed=false` 出现。
- `baseline_allowed=false` 出现。
- `hash_value_persistence_allowed=false` 出现。
- `pixel_diff_allowed=false` 出现。

断言命令结果：

```text
bounds_crop_log_assertions=passed
```

### 6.4 Auto-close Harness

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh \
  >/tmp/cjgui-p1-bounds-crop-auto-close.out 2>&1
```

结果：

- 退出码：`0`
- 日志路径：`/tmp/cjgui-p1-auto-close-verify.log`
- stdout 捕获路径：`/tmp/cjgui-p1-bounds-crop-auto-close.out`
- 原有 auto-close、capability、frame metadata / render stats、Metal readback summary 和返回码断言仍通过。
- 结果行：`cjgui verify: auto-close log assertions passed`

### 6.5 Forbidden File Hash

实现前记录 forbidden 文件 hash：

```text
/tmp/cjgui-p1-bounds-crop-forbidden-before.sha256
```

实现后复核：

```bash
shasum -a 256 \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh \
  /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh \
  > /tmp/cjgui-p1-bounds-crop-forbidden-after.sha256

cmp -s \
  /tmp/cjgui-p1-bounds-crop-forbidden-before.sha256 \
  /tmp/cjgui-p1-bounds-crop-forbidden-after.sha256
```

结果：退出码 `0`，forbidden 文件 hash 未变化。

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

- 没有实现真正 bounds normalization。
- 没有实现 content interior extraction。
- 没有把 `content_interior_bounds` 宣称为当前可用 source。
- 没有把 `target_window_crop_bounds` 或 whole window crop 升级为 baseline input contract。
- 没有修改 capture 行为。
- 没有修改 artifact lifecycle。
- 没有修改 frame hash feasibility 行为。
- 没有修改 baseline readiness 行为。
- 没有修改 source normalization readiness 行为。
- 没有修改 native bridge。
- 没有修改仓颉入口。
- 没有修改 build script。
- 没有修改 auto-close harness。
- 没有新增 public C ABI / public runtime API。
- 没有保存或输出 hash value。
- 没有建立 baseline / golden hash。
- 没有做 baseline compare。
- 没有做 pixel diff。
- 没有读取或输出 raw bytes。
- 没有保存成功 screenshot artifact。
- 没有做 offscreen renderer。
- 没有进入 Renderer / Scene / Widget / Layout / DSL。
- 没有把 smoke demo 宣称为正式 GUI runtime。

## 8. What This Proves

本轮只证明：

- 现有 screenshot verification harness 可以在 source normalization readiness diagnostics 之后继续输出一组 bounds / crop semantics readiness diagnostics。
- 当前 harness 已有 screen bounds、capture bounds 和 target window crop 相关 diagnostics。
- 当前仍能诚实表达 `content_interior_bounds_observed=false`、`hash_input_bounds_defined=false` 和 `whole_window_crop_baseline_allowed=false`。
- 原有 screenshot verification、frame hash feasibility、source normalization readiness、artifact lifecycle 和 auto-close 验证语义仍保持。

本轮不证明：

- bounds 已 normalized。
- content interior bounds 当前可用。
- target window crop 或 whole window crop 可以成为 baseline input contract。
- hash value 可以保存或输出。
- baseline / golden hash 可以建立。
- baseline compare 可以执行。
- pixel diff 可以开启。
- offscreen renderer 可用。
- 当前 smoke demo 是正式 GUI runtime。

## 9. Residual Risk

- source 仍未 normalized。
- hash input bounds 仍未定义。
- content interior extraction 仍未实现，也未被允许。
- whole window crop 仍不能作为长期 baseline input。
- point / pixel conversion、rounding、decoration policy 仍未冻结。
- baseline 仍不允许。
- hash value 仍不允许保存或输出。
- pixel diff 仍不允许。
- CI / headless 仍未证明。

## 10. Next Opening

当前不自动进入新的实现。

推荐下一步是 docs-only：

> `P1 frame hash verification evidence line closure / runtime pivot preflight`

该 preflight 应复核当前从 screenshot verification、frame hash feasibility、baseline readiness、source normalization readiness 到 bounds / crop semantics readiness diagnostics 的整条 evidence line，并判断是否继续在 screenshot/hash 线上推进，还是应 pivot 回 runtime / Renderer / Scene 前置边界。不得自动进入 bounds normalization、content interior extraction、baseline、pixel diff、offscreen renderer、native bridge 或 public runtime API。
