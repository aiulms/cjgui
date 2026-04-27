# P1 Frame Hash Feasibility Closure Review

日期：2026-04-25

状态：完成

类型：bounded implementation closure review

## 1. Authority

唯一 execution card：

- [2026-04-25-p1-frame-hash-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-execution-card.md)

本轮只执行该 execution card 授权的极窄 first slice。

## 2. 实际 Write Set

实际修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
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

本轮只在现有 screenshot verification harness 内增加 frame hash feasibility summary。

实际边界：

- source 只选择 `target_window_screenshot_crop`。
- source truth 只声明为 `user_visible_screenshot`。
- hash 只作为当前运行内 feasibility summary。
- 算法为 `sha256`。
- 不记录 hash 值。
- 不持久化 hash。
- 不建立 baseline / golden image。
- 不做 baseline compare。
- 不做 pixel diff、threshold diff 或 region diff。
- 不保存成功 screenshot artifact。
- 不保存 raw bytes。

实现方式：

- harness 在 CoreGraphics target-window crop artifact 创建成功、目标窗口归属成功、`3x3` clear-color sample 成功后，对临时 `target-window.png` 执行 `shasum -a 256`。
- `shasum` 输出被丢弃，只记录 `hash_computed=true`。
- 成功路径继续在最终 artifact lifecycle 阶段删除 artifact 和临时目录。

## 4. 实际日志格式

本机本次成功路径输出：

```text
cjgui frame hash feasibility: requested=true
cjgui frame hash feasibility: source=target_window_screenshot_crop
cjgui frame hash feasibility: source_truth=user_visible_screenshot
cjgui frame hash feasibility: bounds=397,139,718,448
cjgui frame hash feasibility: scale=2.00
cjgui frame hash feasibility: color_space=unknown
cjgui frame hash feasibility: pixel_format=unknown
cjgui frame hash feasibility: algorithm=sha256
cjgui frame hash feasibility: hash_computed=true
cjgui frame hash feasibility: hash_persisted=false
cjgui frame hash feasibility: hash_value_logged=false
cjgui frame hash feasibility: baseline_compared=false
cjgui frame hash feasibility: success=true reason=none
```

说明：

- `color_space=unknown` 和 `pixel_format=unknown` 是诚实降级，不伪造 screenshot crop 的底层像素格式。
- `hash_value_logged=false` 表示不输出 hash 值，也不把它写成长期 golden value。
- `baseline_compared=false` 表示未做 regression 判定。

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
  > /tmp/cjgui-p1-frame-hash-forbidden-before.sha1
```

结果：完成。

Red check：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh > /tmp/cjgui-p1-frame-hash-red-check.out 2>&1
rg -q "cjgui frame hash feasibility:" /tmp/cjgui-p1-user-visible-window-screenshot-verification.log
```

结果：

- harness exit：`0`
- `red_check=expected_missing`

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
- 原有 readiness、target attribution、artifact lifecycle、cleanup、`3x3` sample 和 success classification 均保留。
- 新增 frame hash feasibility summary 输出并通过。

原有 auto-close harness：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- exit `0`
- 日志路径：`/tmp/cjgui-p1-auto-close-verify.log`
- 原有 capability、frame metadata / render stats、Metal readback summary、auto-close lifecycle needle 仍通过。

## 6. 断言结果

原有 screenshot verification needle：

- `target_pid_observed=true`
- `window_title_matched=true`
- `window_bounds_observed=true`
- `sample_points=9`
- `sample_match=true`
- `artifact_deleted=true`
- `artifact_retained=false`

新增 frame hash feasibility needle：

- `source=target_window_screenshot_crop`
- `source_truth=user_visible_screenshot`
- `algorithm=sha256`
- `hash_computed=true`
- `hash_persisted=false`
- `hash_value_logged=false`
- `baseline_compared=false`
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
- 没有实现 pixel diff。
- 没有建立 baseline / golden image。
- 没有保存成功 screenshot artifact。
- 没有保存 raw bytes。
- 没有提交 artifact。
- 没有做 offscreen renderer。
- 没有设计 Renderer / Scene / Widget / Layout / DSL。
- 没有把 smoke demo 宣称为正式 GUI runtime。

## 8. Residual Risk

- 这不是 pixel diff。
- 这不是 baseline regression。
- 这不是 Metal readback truth。
- 这不是 CI / headless proof。
- 这不证明窗口未被遮挡或 compositor / display presentation 总是正确。
- 这不定义长期 golden hash owner、baseline storage 或 baseline update 审批。
- 这不是 Renderer / Scene / Widget / Layout 设计。
- 这不是正式 GUI runtime。

## 9. Next Opening

当前不自动进入新的实现。

推荐下一步仅做 docs-only：

> `P1 frame hash evidence review / baseline policy preflight`

该 preflight 应先冻结是否、何时允许 baseline / golden hash、hash retention、baseline owner、CI / headless 可复核性和 pixel diff 前置条件；不得自动进入 pixel diff、baseline compare、offscreen renderer、Renderer / Scene 或 public runtime API。
