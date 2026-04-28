# GUI 计划文档目录

这个目录用于存放后续的：

- preflight
- execution card
- approval gate
- closure review

命名建议：

- `YYYY-MM-DD-<topic>-preflight.md`
- `YYYY-MM-DD-<topic>-execution-card.md`
- `YYYY-MM-DD-<topic>-approval-gate.md`
- `YYYY-MM-DD-<topic>-closure-review.md`

这些文档只承载单次 bounded slice 的判断和封账，不承担长期总索引职责。

## 当前计划文档索引

长期入口仍以仓颉工作区根目录的 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 为准。

本目录当前已有：

- [2026-04-24-e0-cangjie-sdk-toolchain-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-24-e0-cangjie-sdk-toolchain-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结仓颉 SDK、本机工具链、`cjc` / `cjpm`、macOS SDK 兼容问题。

- [2026-04-25-p0-macos-bridge-runtime-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-runtime-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结 P0 macOS bridge smoke 的边界，允许在 `labs/macos_bridge_smoke/` 做最小窗口和 Metal 清屏验证。

- [2026-04-25-p0-macos-bridge-smoke-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：定义 P0 macOS bridge smoke 的 write set、stop-line、验证方式和执行边界。

- [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P0 bridge smoke，记录自动关闭验证与人工视觉确认。

- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结 P1 AppKit / Metal 桥接边界，回答 FFI 生命周期、主线程 owner、错误处理哲学、capability query、构建复现和桥接窄接口。

- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 P1 bridge boundary cleanup 的 write set、owner、生命周期清理范围、错误返回口径、验证命令和 stop-line。

- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 bridge boundary cleanup，记录 landed code reality、验证结果、stop-line 和残留风险。

- [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结未来后台任务、Agent action、runtime 异步更新 UI 回到 macOS 主线程的 enqueue / drain / stale message / lifecycle 规则。

- [2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：授权一个极窄的 `labs/macos_bridge_smoke` 内部单实例 lifecycle queue first slice，第一刀只支持 `RequestClose`。

- [2026-04-25-p1-main-thread-ui-message-queue-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 main-thread UI message queue first slice，记录 `RequestClose` post / main-thread drain / close / destroy / exit 验证结果和残留风险。

- [2026-04-25-p1-automated-gui-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-preflight.md)
  - 类型：preflight
  - 状态：完成
  - 用途：冻结 GUI 自动化验证路线，明确日志断言、frame metadata / render stats、截图、Metal readback、frame hash、pixel diff 和 offscreen 验证的阶段边界。

- [2026-04-25-p1-automated-gui-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：授权未来极窄 verification harness first slice，优先只封装现有自动关闭日志断言，不实现截图、pixel diff、Metal readback 或 offscreen renderer。

- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 automated GUI verification first slice，记录 `verify_auto_close.sh` 日志 harness、验证命令、日志路径、断言结果、非像素级边界和残留风险。

- [2026-04-25-p1-frame-metadata-render-stats-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结未来 frame metadata / render stats 的 owner、字段边界、输出形态、closure 证据和 stop-line，不实现元数据、不读取像素、不设计 Renderer / Scene。

- [2026-04-25-p1-frame-metadata-render-stats-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行并 closure
  - 用途：授权未来极窄 frame metadata / render stats first slice，只允许 smoke bridge 输出脱水日志，并让 `verify_auto_close.sh` 增加日志 needle。

- [2026-04-25-p1-frame-metadata-render-stats-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-metadata-render-stats-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 frame metadata / render stats first slice，记录脱水 diagnostics 日志格式、harness 断言结果、非像素级边界、stop-line 和残留风险。

- [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结未来像素级 / 视觉级 GUI 验证的第一证据链选择，比较 screenshot、Metal readback、frame hash、pixel diff 和 offscreen renderer，并建议下一步只开 Metal readback feasibility execution card。

- [2026-04-25-p1-metal-readback-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行并 closure
  - 用途：授权未来一个极窄 smoke-only、single-frame、clear-color Metal readback feasibility first slice，禁止 screenshot、raw bytes、frame hash、pixel diff、offscreen renderer、public C ABI / runtime API 和 Renderer / Scene。

- [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 Metal readback feasibility first slice，记录 command buffer completion、staging buffer 生命周期、脱水 readback summary 日志、harness 断言结果、非截图 / 非用户可见窗口边界和残留风险。

- [2026-04-25-p1-user-visible-window-verification-evidence-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-verification-evidence-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结用户可见窗口验证证据线，明确 Metal readback summary 与 OS / compositor / display presentation 后 evidence 的 truth 区别，并建议下一步只开 screenshot feasibility execution card。

- [2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行并 closure
  - 用途：授权未来一个极窄 screenshot feasibility probe first slice，只允许独立 harness 判断当前本机 smoke 运行期间能否请求一次截图并分类失败原因；禁止 screenshot artifact、像素比较、pixel diff、frame hash、offscreen renderer、public C ABI / runtime API 和 Renderer / Scene。

- [2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 user-visible window screenshot feasibility first slice，记录独立 harness、CoreGraphics screenshot probe 机制、readiness 日志、success / failure classification summary、非像素级边界、stop-line 和残留风险。

- [2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结是否从 screenshot feasibility 进入真正 screenshot verification，明确临时 artifact、极窄 pixel sample、目标窗口归属、权限 / 遮挡 / 多显示器 / Retina scale / timing、pixel diff / frame hash 延后和 stop-line。

- [2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行并 closure
  - 用途：将 screenshot verification preflight 收束为受限 implementation authorization；未来第一刀最多允许独立 harness 保存临时 screenshot artifact、确认目标窗口归属，并做极窄 clear-color sample summary，禁止 pixel diff、frame hash、baseline、offscreen renderer、public runtime API 和 Renderer / Scene。

- [2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 user-visible window screenshot verification first slice，记录独立 harness、临时 artifact 生命周期、目标窗口归属、中心 `3x3` clear-color sample、验证命令、`success=true reason=none`、stop-line 和残留风险。

- [2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 screenshot verification artifact 的审查、成功 / 失败保留、清理、隐私、baseline 边界，以及何时才允许另开 pixel diff / frame hash preflight。

- [2026-04-25-p1-screenshot-artifact-retention-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行并 closure
  - 用途：将 artifact retention policy preflight 收束成受限 implementation authorization；未来第一刀最多允许现有 screenshot verification harness 做 artifact retention / cleanup policy 极窄调整，禁止 pixel diff、frame hash、baseline、offscreen renderer、public runtime API 和 Renderer / Scene。

- [2026-04-25-p1-screenshot-artifact-retention-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 screenshot artifact retention first slice，记录 screenshot verification harness 的成功删除、失败短期保留、24 小时 TTL、pattern-limited 历史清理、验证命令、stop-line 和残留风险。

- [2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结进入 pixel diff / frame hash 之前的 source image、baseline owner、artifact policy、整图像素读取、raw bytes、颜色空间、Retina scale、CI / headless 和 stop-line 前置条件。

- [2026-04-25-p1-frame-hash-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行 bounded implementation first slice
  - 用途：将 pixel diff / frame hash prerequisites preflight 收束成受限 implementation authorization；未来第一刀只允许基于 target-window screenshot crop 做 frame hash feasibility summary，禁止 pixel diff、baseline、golden image、raw bytes 保存、offscreen renderer、public runtime API 和 Renderer / Scene。

- [2026-04-25-p1-frame-hash-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 frame hash feasibility first slice，记录 target-window screenshot crop source、`sha256` 当前运行内 summary、hash 不记录 / 不持久化、baseline 不比较、artifact 成功删除、验证命令、stop-line 和残留风险。

- [2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-evidence-review-baseline-policy-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复核 frame hash feasibility evidence 之后是否、何时允许 baseline / golden hash，冻结 baseline owner、AI update、hash value、artifact retention、source truth、CI / headless、pixel diff 延后和 stop-line。

- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行 bounded implementation first slice
  - 用途：将 frame hash evidence review / baseline policy preflight 收束成受限 implementation authorization；未来第一刀只允许基于 target-window screenshot crop 输出 baseline readiness diagnostics summary，禁止 baseline / golden hash、hash value persistence、baseline compare、pixel diff、raw bytes 保存、offscreen renderer、public runtime API 和 Renderer / Scene。

- [2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-readiness-diagnostics-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 frame hash baseline-readiness diagnostics first slice，记录 baseline readiness 脱水 summary、`baseline_allowed=false`、policy incomplete 阻塞原因、hash value 不保存、baseline 不建立、pixel diff 不允许、验证命令、stop-line 和残留风险。

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结未来 baseline / golden hash 的 human owner、human review、AI auto-update 禁止规则、baseline proposal / approval / rejection / defer 流程，以及与 source normalization、artifact retention、CI / headless policy 的关系。

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行 bounded implementation first slice
  - 用途：将 baseline owner / update policy preflight 收束成受限 implementation authorization；未来第一刀最多只允许 owner / update policy 脱水 diagnostics 或 checklist，必须继续保持 `baseline_allowed=false`，禁止 baseline / golden hash、hash value persistence、baseline compare、pixel diff、raw bytes、成功 artifact 保留、offscreen renderer、public runtime API 和 Renderer / Scene。

- [2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-baseline-owner-update-policy-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 frame hash baseline owner / update policy first slice，记录 owner / update policy 脱水 diagnostics、`baseline_allowed=false`、AI 不可成为 owner / 自动更新 baseline、验证命令、stop-line 和残留风险。

- [2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 `target-window screenshot crop` 作为 frame hash source 时的 source normalization、bounds / scale / color space / pixel format / window decoration / timing / CI 分类边界，继续禁止 hash value persistence、baseline、baseline compare、pixel diff、offscreen renderer 和 public runtime API。

- [2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-policy-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行 bounded implementation first slice
  - 用途：将 source normalization policy preflight 收束成受限 implementation authorization；未来第一刀最多只允许 source normalization readiness diagnostics，继续保持 `source_normalized=false`、`baseline_allowed=false`，禁止 source normalization implementation、hash value persistence、baseline、baseline compare、pixel diff、offscreen renderer 和 public runtime API。

- [2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-frame-hash-source-normalization-readiness-diagnostics-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 frame hash source normalization readiness diagnostics first slice，记录 source normalization readiness 脱水 summary、`source_normalized=false`、`blocked_reason=source_policy_incomplete`、`baseline_allowed=false`、hash value 不保存、baseline / pixel diff / offscreen renderer 不允许、验证命令、stop-line 和残留风险。

- [2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-source-normalization-evidence-closure-next-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复核 source normalization readiness diagnostics evidence，确认 `source_normalized=false`、`baseline_allowed=false`、hash value 不保存、baseline / baseline compare / pixel diff 不允许，并建议下一条边界优先冻结 bounds / crop semantics。

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 `target_window_screenshot_crop` 作为 frame hash source 时的 bounds / crop semantics policy，区分 `screen_bounds_points`、`capture_bounds_pixels`、`target_window_crop_bounds` 和 `content_interior_bounds`，继续禁止 bounds normalization、hash value persistence、baseline / baseline compare、pixel diff、offscreen renderer 和 public runtime API。

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-execution-card.md)
  - 类型：execution card
  - 状态：完成；已执行 bounded implementation first slice
  - 用途：将 bounds / crop semantics policy preflight 收束成受限 implementation authorization；未来第一刀最多只允许 bounds / crop semantics readiness diagnostics，继续保持 `source_normalized=false`、`baseline_allowed=false`、`hash_value_persistence_allowed=false` 和 `pixel_diff_allowed=false`，禁止真正 bounds normalization、content interior extraction、native bridge 修改、public C ABI / runtime API、baseline、pixel diff、offscreen renderer 和 Renderer / Scene / Widget / Layout / DSL。

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 frame hash bounds / crop semantics readiness diagnostics first slice，记录新增脱水 diagnostics、`content_interior_bounds_observed=false`、`hash_input_bounds_defined=false`、`whole_window_crop_baseline_allowed=false`、source / baseline / hash / pixel diff 禁令、验证命令、stop-line 和残留风险。

- [2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-verification-evidence-line-closure-runtime-pivot-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复核 automated verification、Metal readback、user-visible screenshot、artifact retention、frame hash feasibility、baseline readiness、owner policy、source normalization readiness 和 bounds / crop semantics readiness 的整条 evidence line，建议 screenshot / frame hash verification 线暂时收口并 pivot 到 smoke-to-runtime boundary preflight。

- [2026-04-26-p1-smoke-to-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 `labs/macos_bridge_smoke` 与未来正式 runtime 的迁移边界，明确 smoke 内容不能直接升格为 runtime，只有主线程 owner、受控 lifecycle、平台对象隐藏、错误边界和 smoke guard 等经验可迁移为约束，并建议下一步只做 minimal app / window lifecycle runtime boundary preflight。

- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结未来正式 runtime 的最小 app / window lifecycle 边界，明确 app owner、window lifecycle owner、main-thread event loop / queue owner、create / close / destroy contract、platform object hiding、error return strategy、single-window first slice 和 smoke guard 关系，并建议下一步只创建 minimal app / window lifecycle runtime execution card。

- [2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：接收红队提出的治理反噬、像素哈希陷阱、macOS runloop 过拟合和 AI semantic tree 热路径风险；确认当前 next opening 不变，但 minimal app / window lifecycle runtime execution card 必须吸收 governance compaction、platform adapter / core event-loop 隔离、command-list evidence future slot 和 semantic lazy / dirty future invariant。

- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 minimal app / window lifecycle runtime boundary preflight 收束成受限 implementation authorization，并吸收 red-team guardrails。未来 first slice 最多只能创建最小 runtime skeleton / app-window lifecycle surface，禁止复用 smoke 目录、直接升格 smoke C ABI、暴露平台对象、进入 Renderer / Scene / Widget / Layout / DSL、command-list hash、pixel diff、baseline、offscreen renderer、semantic tree / Action Router 或 `CJGUI_TRUTH_MANIFEST.md`。

- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 minimal app/window lifecycle runtime skeleton first slice，记录新建 `runtime/cjgui` comment-only skeleton、每个文件定位、Cangjie build check 暂不适用原因、smoke guard 验证、forbidden 文件 hash 检查、red-team guardrails、stop-line 和 residual risk。

- [2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：接收自绘降维、IME 隔离、电池 / 过度重绘、原生手感、IME 坐标同步和无障碍黑盒风险；冻结不默认 global tick、redraw 必须 future invalidation-driven、IME final string only 不能成为完整 contract、semantic bridge 保留为 future slot 等 runtime 护栏。

- [2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复核 minimal runtime comment-only skeleton 是否足以封账，确认其仍不实现 runtime、不定义 public API、不迁移 smoke、不暴露平台对象，并建议下一条优先冻结 app lifecycle surface boundary，继续禁止 runtime implementation、package / build config、Renderer / Scene / Widget / Layout / DSL、global tick、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 future app lifecycle surface 的 owner、truth、`init` / `run` / `request quit` / `shutdown`、main-thread queue / drain、platform adapter 驱动关系、shutdown 后 late message、window / error strategy 边界和 no-global-tick 护栏，并建议下一步只创建 docs-only app lifecycle surface execution card。

- [2026-04-26-p1-app-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 app lifecycle surface boundary preflight 收束成受限 execution card。未来 first slice 最多只能做 `runtime/cjgui/src/app_lifecycle.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level surface refinement，禁止真实 app lifecycle、`run` / `shutdown` / queue / drain、public runtime API、package / build config、platform runloop truth、global tick、Text / Input / IME / Accessibility、Renderer / Scene / Widget / Layout / DSL、handle table / generation、semantic tree、command-list hash、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 app lifecycle surface comment-only refinement first slice，记录 `runtime/cjgui/src/app_lifecycle.cj` 仍为 comment-only、`runtime/cjgui/README.md` 只补充 app lifecycle surface boundary、未新增 package / build config、未定义 public API、未实现 app lifecycle / run / shutdown / queue / drain、smoke guard 通过，以及 next opening 转向 docs-only window lifecycle surface boundary preflight。

- [2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：首个 app state marker。

- [2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账首个 app state marker。

- [2026-04-27-p1-app-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：追加 app Bool 状态字段。

- [2026-04-27-p1-app-lifecycle-state-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 app Bool 状态字段。

- [2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 app transition marker。

- [2026-04-27-p1-app-lifecycle-transition-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-marker-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 app transition marker。

- [2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 app phase taxonomy marker。

- [2026-04-27-p1-app-lifecycle-phase-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-marker-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 app phase taxonomy marker。

- [2026-04-27-p1-app-lifecycle-state-construction-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 app state 构造形状。

- [2026-04-27-p1-app-lifecycle-state-construction-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 app state 构造形状。

- [2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 app state 初始化形状。

- [2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 app state 初始化形状。

- [2026-04-27-p1-first-internal-window-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-window-lifecycle-state-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：首个 window state marker。

- [2026-04-27-p1-first-internal-window-lifecycle-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-window-lifecycle-state-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账首个 window state marker。

- [2026-04-27-p1-window-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-state-shape-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：追加 window Bool 状态字段。

- [2026-04-27-p1-window-lifecycle-state-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-state-shape-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 window Bool 状态字段。

- [2026-04-27-p1-window-lifecycle-construction-no-op-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-construction-no-op-transition-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 window 构造与 no-op。

- [2026-04-27-p1-window-lifecycle-construction-no-op-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-construction-no-op-transition-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 window 构造与 no-op。

- [2026-04-27-p1-window-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-first-state-changing-transition-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结首个 window 状态变更。

- [2026-04-27-p1-window-lifecycle-first-state-changing-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-first-state-changing-transition-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账首个 window 状态变更。

- [2026-04-27-p1-platform-adapter-fact-ingestion-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-ingestion-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：首个 platform fact marker。

- [2026-04-27-p1-platform-adapter-fact-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-marker-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 platform fact marker。

- [2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 platform fact 形状与 ingestion。

- [2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 platform fact 形状与 ingestion。

- [2026-04-27-p1-platform-fact-to-lifecycle-ingestion-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-fact-to-lifecycle-ingestion-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 platform 到 lifecycle 投影。

- [2026-04-27-p1-platform-fact-to-lifecycle-ingestion-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-fact-to-lifecycle-ingestion-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 platform 到 lifecycle 投影。

- [2026-04-27-p1-internal-lifecycle-coordination-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结内部 lifecycle 协调入口。

- [2026-04-27-p1-internal-lifecycle-coordination-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账内部 lifecycle 协调入口。

- [2026-04-27-p1-internal-lifecycle-coordination-sanity-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-sanity-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结内部 coordination sanity 调用。

- [2026-04-28-p1-internal-lifecycle-coordination-sanity-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-lifecycle-coordination-sanity-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账内部 coordination sanity 调用，并记录窄口恢复修正与默认 internal sanity function。

- [2026-04-28-p1-platform-readiness-fact-semantics-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-platform-readiness-fact-semantics-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 platform readiness fact 语义 first slice。

- [2026-04-28-p1-platform-readiness-fact-semantics-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-platform-readiness-fact-semantics-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 platform readiness fact 语义 first slice。

- [2026-04-28-p1-app-lifecycle-platform-readiness-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-app-lifecycle-platform-readiness-state-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 app lifecycle platform readiness observed state first slice。

- [2026-04-28-p1-app-lifecycle-platform-readiness-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-app-lifecycle-platform-readiness-state-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 app lifecycle platform readiness observed state first slice。

- [2026-04-28-p1-window-lifecycle-platform-readiness-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-window-lifecycle-platform-readiness-state-execution-card.md)
  - 类型：execution card
  - 状态：完成
  - 用途：冻结 window lifecycle platform readiness observed state first slice。

- [2026-04-28-p1-window-lifecycle-platform-readiness-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-window-lifecycle-platform-readiness-state-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 window lifecycle platform readiness observed state first slice。

- [2026-04-28-p1-readiness-state-helper-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-state-helper-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 readiness helper predicates 与 coordination readiness sanity helper 两个 internal-only slices。

- [2026-04-28-p1-readiness-state-helper-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-state-helper-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 readiness helper predicates 与 coordination readiness sanity helper 两个 internal-only slices。

- [2026-04-28-p1-readiness-coordination-negative-path-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-coordination-negative-path-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 negative platform readiness fact sanity 与 readiness sanity parity helper 两个 internal-only slices。

- [2026-04-28-p1-readiness-coordination-negative-path-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-coordination-negative-path-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 negative readiness sanity helper 与 readiness sanity parity helper 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 internal runtime readiness aggregate type 与 aggregate builder 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 internal runtime readiness aggregate type 与 aggregate builder 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-bootstrap-draft-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-draft-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 internal runtime bootstrap snapshot type 与 bootstrap snapshot builder 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-bootstrap-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-draft-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 internal runtime bootstrap snapshot type 与 bootstrap snapshot builder 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 runtime bootstrap owner file 创建与 bootstrap owner boundary cleanup 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 runtime bootstrap owner file 创建与 owner boundary cleanup 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-root-state-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-state-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 internal runtime root state type 与 root state builder 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-root-state-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-state-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 internal runtime root state type 与 root state builder 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-root-sanity-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-sanity-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 runtime root ready sanity helper 与 no-further-helper-chain closure 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-root-sanity-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-sanity-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 runtime root ready sanity helper 与 no-further-helper-chain closure 两个 internal-only slices。

- [2026-04-28-p1-first-internal-runtime-step-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-first-internal-runtime-step-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 internal runtime step result type 与 first internal runtime step function 两个 internal-only slices。

- [2026-04-28-p1-first-internal-runtime-step-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-first-internal-runtime-step-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 internal runtime step result type 与 first internal runtime step function 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-step-sanity-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-sanity-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权 runtime step ready sanity helper 与 no-further-helper-chain closure 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md)
  - 类型：bundled closure / mini-compaction
  - 状态：完成
  - 用途：封账 runtime step ready sanity helper 与 no-further-helper-chain closure 两个 internal-only slices。

- [2026-04-28-p1-internal-runtime-step-input-policy-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-input-policy-bundle-execution-card.md)
  - 类型：bundled execution card
  - 状态：完成
  - 用途：授权下一轮一次完成 internal runtime step input / policy / decision / step-with-input-policy / sanity 的完整 W2 internal behavior concept slice。

- [2026-04-27-p1-lifecycle-parity-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-lifecycle-parity-compaction.md)
  - 类型：compaction
  - 状态：完成
  - 用途：压缩 app/window 对齐摘要。

- [2026-04-27-p1-runtime-internal-concept-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-runtime-internal-concept-compaction.md)
  - 类型：compaction
  - 状态：完成
  - 用途：压缩 runtime internal 概念索引。

## 恢复后补挂索引

以下文件当前已存在；这一步先补齐索引入口，避免“文件在目录里但 README 没挂出来”的误判。为避免重复展开，这里先按主题补挂，不重复写长摘要。

### 2026-04-26 Runtime Skeleton 补挂

- 首个可编译 runtime source 链：
  - [2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md)
  - [2026-04-26-p1-first-compilable-runtime-source-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-execution-card.md)
  - [2026-04-26-p1-first-compilable-runtime-source-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-review.md)
  - [2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md)

- 首个 internal runtime type 与 symbol 链：
  - [2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)
  - [2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md)
  - [2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md)
  - [2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md)
  - [2026-04-26-p1-first-internal-runtime-type-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-execution-card.md)
  - [2026-04-26-p1-first-internal-runtime-type-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md)
  - [2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md)
  - [2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md)

- package / build 边界链：
  - [2026-04-26-p1-runtime-build-package-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)
  - [2026-04-26-p1-runtime-build-package-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-execution-card.md)
  - [2026-04-26-p1-runtime-build-package-metadata-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md)

- window lifecycle surface 链：
  - [2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)
  - [2026-04-26-p1-window-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-execution-card.md)
  - [2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)

- platform adapter boundary 链：
  - [2026-04-26-p1-platform-adapter-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-preflight.md)
  - [2026-04-26-p1-platform-adapter-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-execution-card.md)
  - [2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)

- error boundary 链：
  - [2026-04-26-p1-error-fact-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)
  - [2026-04-26-p1-error-fact-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)
  - [2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md)
  - [2026-04-26-p1-error-taxonomy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-boundary-execution-card.md)
  - [2026-04-26-p1-error-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md)
  - [2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md)
  - [2026-04-26-p1-error-strategy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md)
  - [2026-04-26-p1-error-strategy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-execution-card.md)
  - [2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)

### 2026-04-27 Runtime Internal 补挂

- app lifecycle 补挂：
  - [2026-04-27-p1-app-lifecycle-no-op-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-no-op-transition-execution-card.md)
  - [2026-04-27-p1-app-lifecycle-no-op-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-no-op-transition-closure-review.md)
  - [2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md)
  - [2026-04-27-p1-app-lifecycle-phase-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-closure-review.md)
  - [2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md)
  - [2026-04-27-p1-app-lifecycle-first-state-changing-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-closure-review.md)
  - [2026-04-27-p1-app-lifecycle-first-state-changing-transition-retry-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-retry-closure-review.md)
  - [2026-04-27-p1-app-lifecycle-mini-slice-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-mini-slice-compaction.md)

- reconstructed 并存候选版：
  - [2026-04-27-p1-first-internal-app-lifecycle-state-execution-card-reconstructed.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-execution-card-reconstructed.md)
  - [2026-04-27-p1-first-internal-app-lifecycle-state-closure-review-reconstructed.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-closure-review-reconstructed.md)
  - [2026-04-27-p1-app-lifecycle-state-shape-execution-card-reconstructed.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-execution-card-reconstructed.md)
  - [2026-04-27-p1-app-lifecycle-state-shape-closure-review-reconstructed.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review-reconstructed.md)
  - [2026-04-27-p1-app-lifecycle-transition-boundary-execution-card-reconstructed.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card-reconstructed.md)
  - [2026-04-27-p1-internal-lifecycle-coordination-sanity-execution-card-reconstructed.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-internal-lifecycle-coordination-sanity-execution-card-reconstructed.md)

定版初判：

- 上述 6 份 `-reconstructed` 与同名原始版语义基本一致，主要差异是标题、标点、局部中文化和恢复格式。
- 当前暂以无 `-reconstructed` 后缀的原始版作为 canonical reference。
- `-reconstructed` 文件先作为恢复证据保留；后续如需删除、归档或合并，应单独开一次清理动作。
- `2026-04-27-p1-app-lifecycle-transition-boundary-execution-card-reconstructed.md` 存在一处 link text 拼写偏差，进一步支持暂不把 reconstructed 版升为 canonical。

## 当前下一步 opening

下一步推荐：

- `P1 internal runtime step input policy bundle implementation`

用途：

- 基于 [2026-04-28-p1-internal-runtime-step-input-policy-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-input-policy-bundle-execution-card.md)，一次完成 step input / policy / decision / step-with-input-policy 的完整 W2 internal behavior concept。
- 不再继续一 helper 一轮。
- 完成后新增 bundled closure。

当前可执行动作：

- bounded implementation / W2 internal behavior bundle。
- 仍不得接入 AppKit / Metal / Objective-C，不得暴露 platform object / native handle / raw pointer，不得实现 callback binding、真实 event loop、queue / drain、app run / shutdown、window create / close / destroy / release、handle table / generation、public runtime API、public C ABI，不得修改 `cjpm.toml` 或 `labs/macos_bridge_smoke`。
