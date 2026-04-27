# macOS Bridge Smoke

最后更新：2026-04-25

用途：

- 验证仓颉可以通过 C ABI 调用 Objective-C macOS 平台桥接。
- 验证 AppKit 窗口可以从仓颉程序启动。
- 验证最小 Metal 清屏绘制链路。
- 验证 bridge 生命周期日志、Metal capability 检查、单实例 lifecycle queue 和自动关闭退出路径。
- 提供一个极窄的自动关闭日志验证 harness。
- 输出脱水 frame metadata / render stats 日志，作为非像素级 diagnostics。
- 输出 smoke-only、single-frame、clear-color Metal readback summary 日志，作为非截图 / 非用户可见窗口的 feasibility diagnostics。
- 提供一个独立用户可见窗口 screenshot feasibility harness，只分类一次截图请求是否可行，不做像素正确性验证。
- 提供一个独立用户可见窗口 screenshot verification first-slice harness，只保存临时 artifact、确认目标窗口归属，并做极窄 clear-color sample summary。
- 为 screenshot verification 临时 artifact 提供 pattern-limited、TTL-limited 的失败保留和历史清理 diagnostics。
- 在 screenshot verification harness 内输出 target-window screenshot crop 的 frame hash feasibility summary；hash 只在当前运行内计算，不记录 hash 值，不建立 baseline。
- 在 screenshot verification harness 内输出 frame hash baseline readiness diagnostics summary；只说明 baseline 仍被 policy 阻塞，不保存 hash 值，不建立 baseline。
- 在 screenshot verification harness 内输出 frame hash baseline owner / update policy diagnostics summary；只说明 owner 必须是 human architect / maintainer，AI 不允许自动更新 baseline。
- 在 screenshot verification harness 内输出 frame hash source normalization readiness diagnostics summary；只说明 source normalization 尚未完成，不保存 hash 值，不建立 baseline，不做 pixel diff。
- 在 screenshot verification harness 内输出 frame hash bounds / crop semantics readiness diagnostics summary；只说明 bounds / crop semantics 尚未完成，不实现 bounds normalization，不声明 content interior source，不建立 baseline，不做 pixel diff。

## 运行

自动关闭模式：

```bash
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

自动关闭日志验证：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

验证日志默认写入：

```text
/tmp/cjgui-p1-auto-close-verify.log
```

screenshot feasibility 验证：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh
```

screenshot feasibility 日志默认写入：

```text
/tmp/cjgui-p1-user-visible-window-screenshot-feasibility.log
```

screenshot verification first-slice 验证：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

screenshot verification 日志默认写入：

```text
/tmp/cjgui-p1-user-visible-window-screenshot-verification.log
```

人工检查模式：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

人工模式下，关闭窗口后进程应退出。

## 当前边界

本实验不是正式 GUI 框架 API。

它只验证：

- 仓颉到 C ABI
- C ABI 到 Objective-C
- AppKit 单窗口
- Metal 清屏
- 最小 Metal capability check
- 单实例 lifecycle queue first slice
- `RequestClose` lifecycle message
- 受控关闭和资源销毁日志
- 自动关闭日志断言 harness
- 脱水 frame metadata / render stats 日志
- 脱水 Metal readback feasibility summary 日志
- 用户可见窗口 screenshot feasibility 请求的脱水 success / failure classification summary
- 用户可见窗口 screenshot verification first-slice 的临时 artifact、目标窗口归属和极窄 clear-color sample summary
- screenshot verification artifact 成功删除、失败短期保留和 `/tmp/cjgui-p1-screenshot-verification.*` 历史清理 summary
- target-window screenshot crop 的脱水 frame hash feasibility summary
- frame hash baseline readiness 的脱水 diagnostics summary
- frame hash baseline owner / update policy 的脱水 diagnostics summary
- frame hash source normalization readiness 的脱水 diagnostics summary
- frame hash bounds / crop semantics readiness 的脱水 diagnostics summary

它当前会输出这些关键阶段日志：

- `cjgui: using SDKROOT=...MacOSX15.4.sdk`
- `cjgui: bridge init`
- `cjgui: capability check: metal device ok`
- `cjgui: capability check: command queue ok`
- `cjgui: window created`
- `cjgui: metal setup complete`
- `cjgui: frame metadata: index=1 drawable=1440x840 scale=2.00 pixel_format=BGRA8Unorm clear_color=0.08,0.16,0.20,1.00 submitted=true committed=unknown attempts=1 success=true degraded=none`
- `cjgui: metal readback: requested=true`
- `cjgui: metal readback: command_buffer_completed=true`
- `cjgui: metal readback: source=clear_color_probe`
- `cjgui: metal readback: clear_color_match=true`
- `cjgui: metal readback: success=true degraded=none`
- `cjgui: first frame rendered`
- `cjgui: post close request: ...`
- `cjgui: main-thread drain`
- `cjgui: close requested: ...`
- `cjgui: destroy complete`
- `cjgui: event loop exited`

`verify_user_visible_window_screenshot_feasibility.sh` 另会输出这些 harness summary：

- `cjgui screenshot feasibility: requested=true`
- `cjgui screenshot feasibility: image_created=true`
- `cjgui screenshot feasibility: success=true reason=none`

`verify_user_visible_window_screenshot_verification.sh` 另会输出这些 harness summary：

- `cjgui screenshot verification: cleanup_requested=true`
- `cjgui screenshot verification: cleanup_pattern=/tmp/cjgui-p1-screenshot-verification.*`
- `cjgui screenshot verification: cleanup_ttl_hours=24`
- `cjgui screenshot verification: cleanup_deleted_count=<n>`
- `cjgui screenshot verification: artifact_path=/tmp/cjgui-p1-screenshot-verification.*/target-window.png`
- `cjgui screenshot verification: requested=true`
- `cjgui screenshot verification: target_pid_observed=true`
- `cjgui screenshot verification: window_title_matched=true`
- `cjgui screenshot verification: window_bounds_observed=true`
- `cjgui screenshot verification: frontmost_app_matched=true|false|unknown`
- `cjgui screenshot verification: display_observed=true|false|unknown`
- `cjgui screenshot verification: scale_observed=true|false|unknown`
- `cjgui screenshot verification: capture_covers_target_bounds=true`
- `cjgui screenshot verification: sample_requested=true`
- `cjgui screenshot verification: sample_points=9`
- `cjgui screenshot verification: sample_match=true|false`
- `cjgui screenshot verification: artifact_deleted=true`
- `cjgui screenshot verification: artifact_retention_reason=none|failure_diagnostic`
- `cjgui screenshot verification: artifact_retention_failure_classification=none|<classification>`
- `cjgui screenshot verification: artifact_retention_path=none|/tmp/cjgui-p1-screenshot-verification.*/target-window.png`
- `cjgui screenshot verification: artifact_retention_ttl_hours=24`
- `cjgui screenshot verification: artifact_retained=false`
- `cjgui screenshot verification: artifact_delete_strategy=none|manual rm -rf /tmp/cjgui-p1-screenshot-verification.*`
- `cjgui screenshot verification: success=true reason=none`
- `cjgui frame hash feasibility: requested=true`
- `cjgui frame hash feasibility: source=target_window_screenshot_crop`
- `cjgui frame hash feasibility: source_truth=user_visible_screenshot`
- `cjgui frame hash feasibility: bounds=<target_bounds|unknown>`
- `cjgui frame hash feasibility: scale=<scale|unknown>`
- `cjgui frame hash feasibility: color_space=<value|unknown>`
- `cjgui frame hash feasibility: pixel_format=<value|unknown>`
- `cjgui frame hash feasibility: algorithm=sha256`
- `cjgui frame hash feasibility: hash_computed=true`
- `cjgui frame hash feasibility: hash_persisted=false`
- `cjgui frame hash feasibility: hash_value_logged=false`
- `cjgui frame hash feasibility: baseline_compared=false`
- `cjgui frame hash feasibility: success=true reason=none`
- `cjgui frame hash baseline readiness: baseline_readiness_requested=true`
- `cjgui frame hash baseline readiness: source=target_window_screenshot_crop`
- `cjgui frame hash baseline readiness: source_truth=user_visible_screenshot`
- `cjgui frame hash baseline readiness: baseline_allowed=false`
- `cjgui frame hash baseline readiness: baseline_blocked_reason=baseline_policy_incomplete`
- `cjgui frame hash baseline readiness: baseline_owner_defined=false`
- `cjgui frame hash baseline readiness: baseline_update_policy_defined=false`
- `cjgui frame hash baseline readiness: human_review_required=true`
- `cjgui frame hash baseline readiness: ai_auto_update_allowed=false`
- `cjgui frame hash baseline readiness: hash_value_persistence_allowed=false`
- `cjgui frame hash baseline readiness: source_normalized=false`
- `cjgui frame hash baseline readiness: color_space_defined=false`
- `cjgui frame hash baseline readiness: pixel_format_defined=false`
- `cjgui frame hash baseline readiness: ci_headless_supported=false`
- `cjgui frame hash baseline readiness: pixel_diff_allowed=false`
- `cjgui frame hash baseline readiness: success=true reason=none`
- `cjgui frame hash baseline owner policy: owner_required=human_architect_or_maintainer`
- `cjgui frame hash baseline owner policy: owner_runtime_api=false`
- `cjgui frame hash baseline owner policy: ai_owner_allowed=false`
- `cjgui frame hash baseline owner policy: ai_auto_update_allowed=false`
- `cjgui frame hash baseline owner policy: proposal_required=true`
- `cjgui frame hash baseline owner policy: human_approval_required=true`
- `cjgui frame hash baseline owner policy: approval_flow_runtime_api=false`
- `cjgui frame hash baseline owner policy: baseline_allowed=false`
- `cjgui frame hash baseline owner policy: hash_value_persistence_allowed=false`
- `cjgui frame hash baseline owner policy: baseline_compare_allowed=false`
- `cjgui frame hash baseline owner policy: pixel_diff_allowed=false`
- `cjgui frame hash baseline owner policy: success=true reason=none`
- `cjgui frame hash source normalization: requested=true`
- `cjgui frame hash source normalization: source=target_window_screenshot_crop`
- `cjgui frame hash source normalization: source_truth=user_visible_screenshot`
- `cjgui frame hash source normalization: source_normalized=false`
- `cjgui frame hash source normalization: blocked_reason=source_policy_incomplete`
- `cjgui frame hash source normalization: bounds_policy_defined=false`
- `cjgui frame hash source normalization: scale_policy_defined=false`
- `cjgui frame hash source normalization: color_space_defined=false`
- `cjgui frame hash source normalization: pixel_format_defined=false`
- `cjgui frame hash source normalization: decoration_policy_defined=false`
- `cjgui frame hash source normalization: timing_policy_defined=false`
- `cjgui frame hash source normalization: ci_headless_supported=false`
- `cjgui frame hash source normalization: baseline_allowed=false`
- `cjgui frame hash source normalization: hash_value_persistence_allowed=false`
- `cjgui frame hash source normalization: pixel_diff_allowed=false`
- `cjgui frame hash source normalization: success=true reason=none`
- `cjgui frame hash bounds crop semantics: requested=true`
- `cjgui frame hash bounds crop semantics: source=target_window_screenshot_crop`
- `cjgui frame hash bounds crop semantics: source_truth=user_visible_screenshot`
- `cjgui frame hash bounds crop semantics: screen_bounds_points_observed=true`
- `cjgui frame hash bounds crop semantics: capture_bounds_pixels_observed=true`
- `cjgui frame hash bounds crop semantics: target_window_crop_bounds_observed=true`
- `cjgui frame hash bounds crop semantics: content_interior_bounds_observed=false`
- `cjgui frame hash bounds crop semantics: hash_input_bounds_defined=false`
- `cjgui frame hash bounds crop semantics: point_pixel_conversion_defined=false`
- `cjgui frame hash bounds crop semantics: rounding_policy_defined=false`
- `cjgui frame hash bounds crop semantics: decoration_policy_defined=false`
- `cjgui frame hash bounds crop semantics: content_interior_extraction_allowed=false`
- `cjgui frame hash bounds crop semantics: whole_window_crop_baseline_allowed=false`
- `cjgui frame hash bounds crop semantics: source_normalized=false`
- `cjgui frame hash bounds crop semantics: baseline_allowed=false`
- `cjgui frame hash bounds crop semantics: hash_value_persistence_allowed=false`
- `cjgui frame hash bounds crop semantics: pixel_diff_allowed=false`
- `cjgui frame hash bounds crop semantics: success=true reason=none`

`verify_auto_close.sh` 会检查这些日志是否存在，并断言仓颉侧输出：

- `Cangjie: cjgui_app_run returned 0`

这只证明构建、capability、lifecycle、first-frame-submitted 日志路径、脱水 frame diagnostics 日志、smoke-only clear-color readback summary 和自动关闭退出路径成立。

frame metadata / render stats 字段语义：

- `index`：smoke diagnostics 启用后的 frame index。
- `drawable`：bridge 观测到的 drawable width / height。
- `scale`：bridge 观测到的 scale factor。
- `pixel_format`：脱水 pixel format 名称，不携带 Metal 对象。
- `clear_color`：intended clear color metadata，不是真实像素证明。
- `submitted`：当前 render path 已提交 frame。
- `committed`：当前 bridge 不能诚实证明 GPU / display 完成状态，因此输出 `unknown`。
- `attempts`：smoke diagnostics 启用后的 render attempt count。
- `success` / `degraded`：当前 render attempt 在 bridge 观测范围内的成功状态和降级原因。

Metal readback diagnostics 字段语义：

- `requested`：smoke bridge 请求执行 single-frame clear-color readback feasibility probe。
- `command_buffer_completed`：readback 在 command buffer completion 之后读取；当前 smoke 使用 bridge 内部单帧同步点。
- `source`：当前只允许 `clear_color_probe`。
- `clear_color_match`：bridge 内部对一个采样点的 clear color summary 比对结果；不输出 raw bytes。
- `success` / `degraded`：当前 readback probe 的 summary 状态和降级原因。

screenshot feasibility summary 字段语义：

- `requested`：harness 在 readiness 日志出现后请求一次截图 feasibility probe。
- `image_created`：CoreGraphics probe 是否返回非空 image object；该对象不保存为文件，不读取或比较像素颜色。
- `success` / `reason`：本次 probe 的脱水分类结果；失败原因只允许使用 `permission_denied`、`display_unavailable`、`window_not_found`、`window_not_visible`、`capture_failed`、`render_not_ready`、`render_failure` 或 `unknown`。

screenshot verification first-slice summary 字段语义：

- `cleanup_requested` / `cleanup_pattern`：harness 启动时只请求清理 `/tmp/cjgui-p1-screenshot-verification.*` 目录。
- `cleanup_ttl_hours` / `cleanup_deleted_count`：只删除超过 24 小时、匹配 pattern、不是当前运行实例目录且不是 symlink 的历史临时目录，并输出删除数量。
- `artifact_path`：临时截图 artifact 路径，只能位于 `/tmp/cjgui-p1-screenshot-verification.XXXXXX`；成功时默认删除。
- `target_pid_observed`：harness 是否通过系统窗口枚举观察到 smoke process id 对应窗口。
- `window_title_matched`：目标窗口 title 是否匹配 `Cangjie macOS Bridge Smoke`；只作为 harness diagnostics。
- `window_bounds_observed`：是否观察到目标窗口 bounds。
- `frontmost_app_matched`：frontmost app 是否为 smoke 进程；非 true 不自动等价为 render failure。
- `display_observed` / `scale_observed`：截图和目标 bounds 映射时观察到的脱水 display / scale diagnostics。
- `capture_covers_target_bounds`：临时截图是否覆盖目标窗口 bounds。
- `sample_requested` / `sample_points`：是否只在目标窗口安全 interior 做极窄 sample；当前 first slice 使用中心附近 `3x3`。
- `sample_match`：极窄 clear-color sample 是否与当前 smoke expected clear color 在容忍范围内匹配。
- `artifact_deleted` / `artifact_retained`：成功路径必须删除 artifact；失败且 artifact 已创建时允许短期保留用于诊断。
- `artifact_retention_reason` / `artifact_retention_failure_classification`：失败保留时必须说明保留原因和 failure classification；成功路径为 `none`。
- `artifact_retention_path` / `artifact_retention_ttl_hours` / `artifact_delete_strategy`：失败保留时必须输出路径、24 小时 TTL 和人工删除策略；成功路径为 `none`。
- `success` / `reason`：本次 verification first slice 的脱水分类结果；失败原因只允许使用 `permission_denied`、`display_unavailable`、`window_not_found`、`window_not_visible`、`capture_failed`、`render_not_ready`、`render_failure`、`unknown`、`window_occluded`、`target_mismatch` 或 `color_mismatch`。

frame hash feasibility summary 字段语义：

- `source`：当前只允许 `target_window_screenshot_crop`，不支持 Metal readback、offscreen renderer 或多 source。
- `source_truth`：当前只能是 `user_visible_screenshot`；它不是 Metal readback truth。
- `bounds` / `scale` / `color_space` / `pixel_format`：脱水 source diagnostics；无法诚实确认时输出 `unknown`。
- `algorithm`：当前只作为 feasibility 使用的 `sha256`。
- `hash_computed`：是否在当前运行内对临时 target-window crop artifact 成功计算 hash。
- `hash_persisted` / `hash_value_logged`：必须为 `false`；不保存 hash 值，不写长期 golden value。
- `baseline_compared`：必须为 `false`；不建立 baseline / golden image，不做 baseline compare。
- `success` / `reason`：只表示 frame hash feasibility summary 是否在当前运行内成立，不是 pixel diff 或 regression 证明。

frame hash baseline readiness summary 字段语义：

- `baseline_readiness_requested`：harness 输出 baseline readiness diagnostics summary。
- `source` / `source_truth`：继续只声明 `target_window_screenshot_crop` 和 `user_visible_screenshot`，不等同于 Metal readback truth。
- `baseline_allowed`：必须为 `false`；当前不允许 baseline / golden hash。
- `baseline_blocked_reason`：当前为 `baseline_policy_incomplete`，表示 owner、update policy、source normalization、CI / headless 等仍未冻结。
- `baseline_owner_defined` / `baseline_update_policy_defined`：必须为 `false`。
- `human_review_required`：必须为 `true`；AI 不允许自动更新 baseline。
- `ai_auto_update_allowed` / `hash_value_persistence_allowed`：必须为 `false`。
- `source_normalized` / `color_space_defined` / `pixel_format_defined` / `ci_headless_supported`：必须为 `false`，表示当前还没有 baseline 所需的长期输入规范。
- `pixel_diff_allowed`：必须为 `false`；本 harness 不进入 pixel diff。
- `success` / `reason`：只表示 readiness diagnostics summary 成功输出，不是 baseline、regression、pixel correctness proof 或 render correctness proof。

frame hash baseline owner / update policy summary 字段语义：

- `owner_required`：未来 baseline owner 必须是 human architect / maintainer。
- `owner_runtime_api` / `approval_flow_runtime_api`：必须为 `false`；owner / approval flow 是文档化 policy，不是 runtime API。
- `ai_owner_allowed` / `ai_auto_update_allowed`：必须为 `false`；AI 不能成为 owner，也不能自动更新 baseline。
- `proposal_required` / `human_approval_required`：必须为 `true`；AI 未来最多生成 proposal、汇总 evidence、列风险并等待 human approval。
- `baseline_allowed`：必须为 `false`；当前不允许 baseline / golden hash。
- `hash_value_persistence_allowed` / `baseline_compare_allowed` / `pixel_diff_allowed`：必须为 `false`；不保存 hash value，不做 baseline compare，不进入 pixel diff。
- `success` / `reason`：只表示 owner policy diagnostics summary 成功输出，不是 baseline、golden hash、baseline compare、pixel diff、pixel correctness proof 或 render correctness proof。

frame hash source normalization readiness summary 字段语义：

- `requested`：harness 输出 source normalization readiness diagnostics summary。
- `source` / `source_truth`：继续只声明 `target_window_screenshot_crop` 和 `user_visible_screenshot`，不等同于 Metal readback truth、offscreen renderer truth 或 Renderer / Scene truth。
- `source_normalized`：必须为 `false`；当前 source normalization 尚未完成。
- `blocked_reason`：当前为 `source_policy_incomplete`，表示 bounds、scale、color space、pixel format、decoration、timing、CI / headless 等 policy 仍未冻结。
- `bounds_policy_defined` / `scale_policy_defined` / `color_space_defined` / `pixel_format_defined` / `decoration_policy_defined` / `timing_policy_defined`：必须为 `false`，只说明当前仍缺 source normalization policy，不是 runtime normalization。
- `ci_headless_supported`：必须为 `false`；当前不能声称 CI / headless 可复核。
- `baseline_allowed` / `hash_value_persistence_allowed` / `pixel_diff_allowed`：必须为 `false`；不允许 baseline / golden hash，不保存或输出 hash value，不进入 pixel diff。
- `success` / `reason`：只表示 source normalization readiness diagnostics summary 成功输出，不是 source normalized、baseline、regression、pixel correctness proof 或 render correctness proof。

frame hash bounds / crop semantics readiness summary 字段语义：

- `requested`：harness 输出 bounds / crop semantics readiness diagnostics summary。
- `source` / `source_truth`：继续只声明 `target_window_screenshot_crop` 和 `user_visible_screenshot`，不等同于 Metal readback truth、offscreen renderer truth 或 Renderer / Scene truth。
- `screen_bounds_points_observed` / `capture_bounds_pixels_observed` / `target_window_crop_bounds_observed`：当前 harness 已有相关 diagnostics；这不表示它们是 hash input contract。
- `content_interior_bounds_observed`：必须为 `false`；当前没有 content interior source，也不实现 content interior extraction。
- `hash_input_bounds_defined`：必须为 `false`；当前尚未定义 hash 哪个矩形。
- `point_pixel_conversion_defined` / `rounding_policy_defined` / `decoration_policy_defined`：必须为 `false`；当前还没有 point / pixel 转换、rounding 或 decoration policy。
- `content_interior_extraction_allowed` / `whole_window_crop_baseline_allowed`：必须为 `false`；不允许声明 content interior extraction，也不允许 whole window crop 成为 baseline input。
- `source_normalized` / `baseline_allowed` / `hash_value_persistence_allowed` / `pixel_diff_allowed`：必须为 `false`；不允许 source normalized、baseline、hash value persistence 或 pixel diff。
- `success` / `reason`：只表示 bounds / crop semantics readiness diagnostics summary 成功输出，不是 bounds normalized、baseline、regression、pixel correctness proof 或 render correctness proof。

它不证明：

- 屏幕像素正确。
- 完整窗口截图正确。
- 用户可见窗口真实内容、窗口遮挡、frontmost app、Space / Mission Control 或 compositor / display presentation 正确。
- 通用 Metal drawable 可读性、整帧像素非空或用户可见窗口像素正确。
- frame hash regression、baseline 或 pixel diff 通过。
- baseline / golden hash 已允许，或 baseline compare 已执行。
- target-window screenshot crop 已经完成 source normalization。
- target-window screenshot crop 已经完成 bounds normalization。
- `content_interior_bounds` 当前可用。
- whole window crop 可以成为 baseline input contract。
- headless / offscreen renderer 可用。

它不包含：

- Entity / Context
- Element tree / Scene
- Widget / Layout / DSL
- Text / Input / IME / Accessibility
- 跨平台后端
- 通用 UI update queue
- target update message
- handle table / generation
- 正式 GUI runtime API

## P1 main-thread UI message queue first slice 验证

本 smoke 当前只实现内部单实例 lifecycle queue。

验证命令：

```bash
set -o pipefail
LOG=/tmp/cjgui-p1-message-queue.log
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh 2>&1 | tee "$LOG"
for needle in \
  'cjgui: post close request' \
  'cjgui: main-thread drain' \
  'cjgui: close requested' \
  'cjgui: destroy complete' \
  'cjgui: event loop exited' \
  'Cangjie: cjgui_app_run returned 0'; do
  grep -F "$needle" "$LOG" >/dev/null || { echo "missing expected log: $needle"; exit 1; }
done
```

最近验证结果：

- 编译成功。
- 自动关闭通过内部 `RequestClose` post。
- close request 由主线程 drain。
- 关闭和销毁路径保持幂等。
- `cjgui_app_run()` 返回 `0`。

## P1 automated GUI verification first slice 验证

本 smoke 当前提供一个可复用日志验证 harness。

验证命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

验证内容：

- 默认设置 `CJGUI_AUTOCLOSE_SECONDS=1`。
- 默认调用 `scripts/build_and_run.sh`。
- 默认捕获日志到 `/tmp/cjgui-p1-auto-close-verify.log`。
- 检查 `SDKROOT`、bridge init、Metal capability check、window created、metal setup complete、first frame rendered、frame metadata / render stats、Metal readback summary、post close request、main-thread drain、close requested、destroy complete、event loop exited 和 `Cangjie: cjgui_app_run returned 0`。

当前验证结论：

- 自动关闭日志断言通过。
- 脱水 frame metadata / render stats 日志断言通过。
- 该 harness 不是用户可见窗口验证。
- 该 harness 只断言 bridge 内部 Metal readback summary 日志，不保存 raw bytes，不实现截图、frame hash、pixel diff 或 offscreen renderer。

## P1 frame metadata / render stats first slice 验证

该 first slice 只输出脱水 diagnostics 日志，不读取像素、不生成截图、不做 Metal readback；后续独立 readback feasibility slice 见下一节。

验证命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

新增断言字段：

- `cjgui: frame metadata:`
- `index=1`
- `drawable=...x...`
- `scale=...`
- `pixel_format=BGRA8Unorm`
- `clear_color=0.08,0.16,0.20,1.00`
- `submitted=true`
- `committed=unknown`
- `attempts=1`
- `success=true`
- `degraded=none`

当前边界：

- `clear_color` 只是 intended metadata，不证明屏幕颜色正确。
- `drawable` 是 bridge 观测值，不是 screenshot 尺寸证明。
- `submitted=true` 只证明当前 render path 提交，不证明 display output。
- 这些 diagnostics 不是 public runtime API，也不是 Renderer / Scene truth。

## P1 Metal readback feasibility first slice 验证

本 smoke 当前只在 bridge 内部执行 single-frame clear-color Metal readback feasibility probe。

验证命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

新增断言字段：

- `cjgui: metal readback:`
- `requested=true`
- `command_buffer_completed=true`
- `source=clear_color_probe`
- `clear_color_match=true`
- `success=true`
- `degraded=none`

当前边界：

- readback 只发生在 smoke bridge 内部，不是 public runtime API。
- readback 使用 command buffer completion 之后的 summary 结果；`committed=unknown` 仍不代表 displayed、pixel correct 或 visual verified。
- readback 不保存 raw pixel bytes，不生成 screenshot artifact，不生成 frame hash，也不做 pixel diff。
- readback 不证明用户可见窗口、compositor 或 display presentation 正确。
- 这不是正式 Renderer / Scene / Widget / Layout / DSL，也不是正式 GUI runtime 测试框架。

## P1 user-visible window screenshot feasibility first slice 验证

本 smoke 当前提供一个独立 screenshot feasibility harness。

验证命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh
```

默认日志：

```text
/tmp/cjgui-p1-user-visible-window-screenshot-feasibility.log
```

当前 harness 行为：

- 默认运行现有 `scripts/build_and_run.sh`，并设置 `CJGUI_AUTOCLOSE_SECONDS=5`。
- 等待 `cjgui: window created`、`cjgui: metal setup complete` 和 `cjgui: first frame rendered`。
- readiness 未满足时输出 `success=false reason=render_not_ready`，不继续请求截图。
- readiness 满足后，通过 `osascript -l JavaScript` 调用 CoreGraphics `CGWindowListCreateImage` 请求一次 on-screen image feasibility probe。
- 只输出 `requested`、`image_created`、`success` 和 `reason` 脱水 summary。

当前边界：

- 不保存 screenshot artifact。
- 不读取或比较像素颜色。
- 不建立 baseline。
- 不做 pixel diff、frame hash 或 offscreen renderer。
- 不新增 public C ABI / runtime API。
- 不暴露 AppKit、Metal、Objective-C 或 CoreGraphics 对象。
- 成功只说明当前本机运行期间可以请求并创建一次 screenshot image object；它不是 full screenshot verification，不证明像素正确、窗口内容正确、compositor 正确或 CI / headless 可复核。

## P1 user-visible window screenshot verification first slice 验证

本 smoke 当前提供一个独立 screenshot verification first-slice harness。

验证命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
```

默认日志：

```text
/tmp/cjgui-p1-user-visible-window-screenshot-verification.log
```

当前 harness 行为：

- 默认运行现有 `scripts/build_and_run.sh`，并设置 `CJGUI_AUTOCLOSE_SECONDS=8`。
- 等待 `cjgui: window created`、`cjgui: metal setup complete` 和 `cjgui: first frame rendered`。
- readiness 未满足时输出 `success=false reason=render_not_ready`，不继续截图。
- readiness 满足后，记录 smoke process id，并通过 CoreGraphics window list 匹配 owner pid、title 和 bounds。
- 使用 CoreGraphics 对目标 bounds 做一次 on-screen capture，临时写入 `/tmp/cjgui-p1-screenshot-verification.XXXXXX/target-window.png`。
- 使用 `NSBitmapImageRep` 只读取目标截图中心附近 `3x3` clear-color sample，并输出脱水 summary。
- 启动时只清理超过 24 小时的 `/tmp/cjgui-p1-screenshot-verification.*` 历史临时目录；不会删除任意 `/tmp` 内容，不跟随 symlink，不删除当前运行实例目录。
- 成功时默认删除 artifact 和临时目录；失败且 artifact 已创建时可以短期保留，并输出保留原因、failure classification、路径、24 小时 TTL 和删除策略。

当前边界：

- 这不是 full GUI verification。
- 这不是 pixel diff。
- 这不是 frame hash regression；当前只输出当前运行内的 frame hash feasibility summary。
- 这不是 offscreen renderer。
- 这不是 CI / headless proof。
- 这不是 Renderer / Scene / Widget / Layout 设计。
- 这不是正式 GUI runtime。
- harness 不读取整图像素，不输出 raw bytes，不建立 baseline，不提交 screenshot artifact，不新增 public C ABI / runtime API。
