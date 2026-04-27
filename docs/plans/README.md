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
  - 状态：完成；不自动开启实现
  - 用途：短卡授权未来 `P1 first internal app lifecycle state first slice`；未来第一刀最多只能在 `runtime/cjgui/src/app_lifecycle.cj` 新增一个默认 internal、无字段、无 `public`、无 import、无函数 / 方法 / 显式 init、无行为的 app lifecycle state marker，表达 state boundary exists 但 state machine 未定义；继续禁止 run / shutdown / request quit / queue / drain、platform callback binding、window / error behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。

- [2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 first internal app lifecycle state first slice，记录 `runtime/cjgui/src/app_lifecycle.cj` 新增默认 internal 空 `struct CjguiInternalAppLifecycleState {}`，它只表达 app lifecycle state boundary exists but lifecycle state machine is not yet defined；`state_machine_defined=false`、`run_behavior_present=false`、`shutdown_behavior_present=false`、`request_quit_behavior_present=false`、`queue_behavior_present=false`、`drain_behavior_present=false`、`public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`field_present=false`、`function_present=false`、`method_present=false`、`explicit_init_present=false`、`import_present=false`、`cjpm_toml_changed=false`、`smoke_changed=false`、`cjpm build --target-dir /tmp/cjgui-first-internal-app-lifecycle-state-target --skip-script` 通过、smoke guard 通过，并将 next opening 转向 `P1 first internal app lifecycle state closure / lifecycle state shape decision`。

- [2026-04-27-p1-app-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：短卡授权未来 `P1 app lifecycle state shape first slice`；未来第一刀只允许修改 `runtime/cjgui/src/app_lifecycle.cj` 中的 `CjguiInternalAppLifecycleState`，最多新增一个不可变 `Bool` 字段，语义等价于 `stateMachineActive: Bool = false`，只表达最小脱水 state shape；继续禁止其他字段、`public`、import、函数 / 方法 / 显式 init、构造逻辑、runtime behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。

- [2026-04-27-p1-app-lifecycle-state-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 app lifecycle state shape first slice，记录 `CjguiInternalAppLifecycleState` 新增唯一默认 internal 不可变字段 `isStateMachineActive: Bool = false`、`app_lifecycle_state_shape_refined=true`、`state_machine_defined=false`、`run_behavior_present=false`、`shutdown_behavior_present=false`、`request_quit_behavior_present=false`、`queue_behavior_present=false`、`drain_behavior_present=false`、`public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`function_present=false`、`method_present=false`、`explicit_init_present=false`、`import_present=false`、`cjpm_toml_changed=false`、`smoke_changed=false`、`cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-shape-target --skip-script` 通过、smoke guard 通过，并将 next opening 转向 `P1 app lifecycle state shape closure / lifecycle transition boundary decision`。

- [2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md)
  - 类型：execution card
  - 状态：完成；默认进入 bounded implementation
  - 用途：短卡判断并授权下一刀 `P1 app lifecycle transition marker first slice`；未来第一刀最多只能在 `runtime/cjgui/src/app_lifecycle.cj` 新增一个默认 internal、无 `public`、无 import 的空 transition marker type，语义为 transition boundary exists but transition behavior is not yet defined；继续禁止函数、修改 `isStateMachineActive`、新增第二个 state 字段、`run` / `shutdown` / `request quit` / queue / drain、platform adapter callback binding、window / error behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj`、smoke / harness / native bridge / 仓颉入口修改。

- [2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 future window lifecycle surface 的 owner、app lifecycle / platform adapter 边界、`create window` / `request close` / `destroy` / `release` future slot、stale message、single-window、handle table / generation、error strategy 和 self-drawn guardrails；继续禁止 runtime implementation、platform object exposure、public API、package / build config、Renderer / Scene / Widget / Layout / DSL、global tick、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-window-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 window lifecycle surface boundary preflight 收束成受限 execution card。未来 first slice 最多只能做 `runtime/cjgui/src/window_lifecycle.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level surface refinement，禁止真实 window lifecycle、window create / request close / destroy / release、app lifecycle / queue / drain、public runtime API、package / build config、platform object exposure、handle table / generation、多窗口、target update、async UI message targeting、global tick、Text / Input / IME / Accessibility、Renderer / Scene / Widget / Layout / DSL、semantic tree、command-list hash、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 window lifecycle surface comment-only refinement first slice，记录 `runtime/cjgui/src/window_lifecycle.cj` 仍为 comment-only、`runtime/cjgui/README.md` 只补充 window lifecycle surface boundary、未新增 package / build config、未定义 public API、未实现 window lifecycle / create / request close / destroy / release、smoke guard 通过，以及 next opening 转向 docs-only platform adapter boundary preflight。

- [2026-04-26-p1-platform-adapter-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 future platform adapter 与 app lifecycle / window lifecycle / core runtime 的边界，明确 adapter 可以在内部持有 AppKit / Metal / Objective-C 平台对象，但 core 只能接收脱水 lifecycle / readiness / failure / queue drain / quit / close / window state / future input / future frame facts；继续禁止 public C ABI / runtime API、package / build config、smoke code 迁移、真实 adapter implementation、global tick、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-platform-adapter-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 platform adapter boundary preflight 收束成受限 execution card。未来 first slice 最多只能做 `runtime/cjgui/src/platform_adapter.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level surface refinement，禁止真实 platform adapter、app lifecycle / event loop / queue / drain、window lifecycle / window create / close / destroy、public runtime API、public C ABI、package / build config、smoke code 迁移、smoke C ABI 复用、platform object exposure、core runloop truth、global tick、Text / Input / IME / Accessibility、Renderer / Scene / Widget / Layout / DSL、semantic tree、command-list hash、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 platform adapter surface comment-only refinement first slice，记录 `runtime/cjgui/src/platform_adapter.cj` 仍为 comment-only、`runtime/cjgui/README.md` 只补充 platform adapter / core boundary、未新增 package / build config、未定义 public runtime API / public C ABI、未实现 platform adapter / event loop / callback binding、未迁移 smoke code、smoke guard 通过，以及 next opening 转向 docs-only error strategy boundary preflight。

- [2026-04-26-p1-error-strategy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 future runtime error strategy 的 owner、app lifecycle / window lifecycle / platform adapter 边界、smoke `last_error` 迁移口径、fatal / recoverable / degraded / invalid usage / capability missing / stale message 等最小分类语义、fail-closed 规则、diagnostics 与 AI / harness / logs 的关系，以及 error strategy 不能成为第二状态真相源。

- [2026-04-26-p1-error-strategy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 error strategy boundary preflight 收束成受限 execution card。未来 first slice 最多只能做 `runtime/cjgui/src/error.cj` 和 / 或 `runtime/cjgui/README.md` 的 comment-only / documentation-level surface refinement，禁止真实 error strategy、error enum / Result type / exception-like mechanism、public runtime API、public C ABI、package / build config、smoke `last_error` migration、smoke C ABI 复用、diagnostics 第二状态真相源、Renderer / Scene / Widget / Layout / DSL、global tick、Text / Input / IME / Accessibility、semantic tree、command-list hash、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 error strategy surface comment-only refinement first slice，记录 `runtime/cjgui/src/error.cj` 仍为 comment-only、`runtime/cjgui/README.md` 只补充 error strategy surface boundary、未新增 package / build config、未定义 public runtime API / public C ABI、未实现 error strategy / error enum / Result type、未迁移 smoke `last_error`、未把 diagnostics 写成第二状态真相源、smoke guard 通过，以及 next opening 转向 docs-only minimal runtime skeleton surface phase closure / compaction preflight。

- [2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：收束 minimal runtime skeleton surface phase，确认 app lifecycle、window lifecycle、platform adapter、error strategy 四条 comment-only surface 已足够封账，不建议继续拆更多 surface，也不建议直接进入 runtime implementation；下一步推荐 docs-only `P1 runtime build/package boundary preflight`，先冻结 package owner、build entry、module boundary、非注释仓颉语法许可、最小可编译 skeleton 范围、验证命令和 CangjieSkills / 本地官方文档查证边界。

- [2026-04-26-p1-runtime-build-package-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 future `runtime/cjgui` 从 comment-only skeleton 进入可编译 runtime package skeleton 前的 build / package boundary，明确 package owner、module boundary、`cjpm` / `cjc` 查证要求、build entry 倾向、runtime package 不依赖 `labs/macos_bridge_smoke`、smoke guard 与 runtime build check 的并列关系、非注释仓颉语法默认不允许、public runtime API / public C ABI / real behavior 均不允许，以及下一步应创建 docs-only `P1 runtime build/package boundary execution card`。

- [2026-04-26-p1-runtime-build-package-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 runtime build / package boundary preflight 收束成受限 execution card。未来 first slice 最多只能创建最小 package / build metadata，并保持 runtime source comment-only；必须先查证 `cjpm` / `cjc` layout、命令和语法，禁止凭模型记忆猜 package 结构；禁止非注释仓颉 runtime 代码、public runtime API、public C ABI、runtime behavior、smoke code / C ABI / `last_error` 迁移、`labs/macos_bridge_smoke` 依赖、Renderer / Scene / Widget / Layout / DSL、global tick、Text / Input / IME / Accessibility、semantic tree、command-list hash、pixel diff、baseline、offscreen renderer 和 `CJGUI_TRUTH_MANIFEST.md`。

- [2026-04-26-p1-runtime-build-package-metadata-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 runtime build/package metadata first slice，记录已按本地 `cjpm` 文档创建 `runtime/cjgui/cjpm.toml` 最小 metadata、`runtime/cjgui/README.md` 补充 package / build metadata boundary、四个 `.cj` source 仍为 comment-only、`cjpm build` 因 comment-only source 缺少 package declaration 而 fail closed、无 smoke dependency / public runtime API / public C ABI / runtime behavior、smoke guard 通过，以及 next opening 转向 docs-only first compilable source boundary preflight。

- [2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：冻结 first compilable runtime source 的最小边界，确认当前 `cjpm build` 失败原因是 `src/` 缺少与 `name = "cjgui"` 匹配的 package declaration；基于仓颉 package 规则，建议下一刀只允许一致的 `package cjgui` declaration，不允许函数、public API、public C ABI、runtime behavior、`src/main.cj`、smoke dependency、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 或 offscreen renderer。

- [2026-04-26-p1-first-compilable-runtime-source-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 first compilable runtime source boundary preflight 收束成受限 execution card；未来 first slice 只允许给四个现有 `runtime/cjgui/src/*.cj` 添加一致的 `package cjgui` declaration，并运行 `cjpm build --target-dir /tmp/... --skip-script` 验证，继续禁止函数、类型、import、public runtime API、public C ABI、runtime behavior、`src/main.cj`、`package_anchor.cj`、`cjpm.toml` 修改、smoke dependency、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-first-compilable-runtime-source-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 first compilable runtime source first slice，记录四个现有 `runtime/cjgui/src/*.cj` 只新增一致的 `package cjgui` declaration、`strict_comment_only=false`、`package_declaration_only=true`、`behavior_code_present=false`、`public_api_present=false`、`cjpm build --target-dir /tmp/... --skip-script` 通过、未新增 `src/main.cj` / `package_anchor.cj`、未修改 `cjpm.toml`、无 smoke dependency / public runtime API / public C ABI / runtime behavior、smoke guard 通过，以及 next opening 转向 docs-only next implementation boundary preflight。

- [2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复核 first compilable runtime source 是否可以封账，确认 `cjpm build success` 只证明 package identity / metadata / empty source package 可被工具链接受，不证明 runtime 能力；明确不建议直接进入真实 runtime implementation，下一步推荐 docs-only `P1 runtime visibility / internal symbol boundary preflight`，在冻结 visibility / internal symbol boundary 前不定义函数、类型、public API、internal anchor、import、public C ABI 或 runtime behavior。

- [2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：查证仓颉 package / module / visibility / test 规则，确认普通顶层声明默认 `internal`、`internal` 可见于当前包及子包、`public` 为全局可见；明确第一批 runtime 非 package declaration symbol 不应 public，不应定义函数签名、public runtime API、public C ABI 或 behavior，下一步推荐 docs-only `P1 runtime internal symbol boundary execution card`。

- [2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 runtime visibility / internal symbol boundary preflight 收束成受限 execution card；未来 first slice 最多只能在一个 existing runtime source 中定义一个普通默认 internal 的 compile sanity marker，继续禁止 public runtime API、public C ABI、函数签名、import、runtime behavior、smoke 迁移、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 runtime internal symbol boundary first slice，记录 `runtime/cjgui/src/error.cj` 新增一个默认 internal compile sanity marker、`public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`internal_symbol_only=true`、`function_present=false`、`import_present=false`、`cjpm build --target-dir /tmp/... --skip-script` 通过、smoke guard 通过，以及 next opening 转向 docs-only first internal type boundary preflight。

- [2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复盘 P1 runtime internal symbol boundary first slice，确认 `CjguiInternalCompileSanityMarker` 只证明 internal compile sanity、不证明 runtime domain type 或 runtime capability；判断第一个真正语义 internal type 仍需先创建 execution card，推荐下一步 docs-only `P1 first internal runtime type execution card`。

- [2026-04-26-p1-first-internal-runtime-type-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 first internal type boundary preflight 收束成受限 execution card；未来 first slice 最多只能在 `runtime/cjgui/src/error.cj` 定义一个默认 internal、无行为、无 `public`、无 `import`、无 public runtime API / public C ABI 的最小 error-facts type，继续禁止 error strategy、error enum / Result type、函数 / 方法 / 构造逻辑、handle、platform object wrapper、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline、offscreen renderer、`cjpm.toml` 修改、`src/main.cj` / `package_anchor.cj` 和 smoke 迁移。

- [2026-04-26-p1-first-internal-runtime-type-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 first internal runtime type first slice，记录 `runtime/cjgui/src/error.cj` 新增默认 internal `CjguiInternalErrorFact`、`public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`function_present=false`、`import_present=false`、`error_enum_present=false`、`result_type_present=false`、`platform_object_wrapper_present=false`、`cjpm build --target-dir /tmp/... --skip-script` 通过、smoke guard 通过、`cjpm.toml` / smoke / harness / native bridge / 仓颉入口未修改，以及 next opening 转向 docs-only error fact shape boundary preflight。

- [2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复盘 `CjguiInternalErrorFact` 是否可以封账，确认它只证明默认 internal、无行为、无 public / import / public API / public C ABI 的 first internal error facts boundary type 可构建，不证明 error strategy、error taxonomy、diagnostics truth、Result type 或 public API；冻结当前不得给该 type 添加字段，不得迁移 smoke `last_error`，并建议下一步 docs-only `P1 error fact shape execution card`。

- [2026-04-26-p1-error-fact-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 error fact shape boundary preflight 收束成受限 execution card；未来 first slice 最多只能围绕 `CjguiInternalErrorFact` 做一个极窄 internal error fact shape refinement，必须保持默认 internal、脱水、无平台对象、无行为、无 public API / public C ABI，并在修改前记录 taxonomy、message ownership、source module、correlation id、lifetime、threading、serialization、privacy 均默认 not yet defined；继续禁止 error strategy、error enum、Result type、exception-like mechanism、diagnostics truth system、smoke `last_error` 迁移、platform object / raw pointer / native error object、handle / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-error-fact-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 error fact shape first slice，记录 `CjguiInternalErrorFact` 新增唯一默认 internal 不可变字段 `hasNativePayload: Bool = false`、`error_fact_shape_refined=true`、`public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`function_present=false`、`method_present=false`、`explicit_init_present=false`、`import_present=false`、`error_enum_present=false`、`result_type_present=false`、`exception_like_mechanism_present=false`、`smoke_last_error_migrated=false`、`platform_object_present=false`、`cjpm_toml_changed=false`、`smoke_changed=false`、`cjpm build --target-dir /tmp/cjgui-error-fact-shape-target --skip-script` 通过、smoke guard 通过，并将 next opening 转向 docs-only error taxonomy boundary preflight。

- [2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复盘 P1 error fact shape first slice 可以封账，确认 `hasNativePayload: Bool = false` 只证明最小脱水 fact 字段可编译，不证明 error taxonomy、error strategy、error enum、`Result` type、public runtime API、public C ABI 或 diagnostics truth system；冻结 future taxonomy owner 倾向属于 `runtime/cjgui` error strategy module，明确 taxonomy 与 app/window/platform 只交换脱水 failure facts，继续禁止 severity / category / code 字段、smoke `last_error` 迁移、platform object / raw pointer / native error object、stack trace blob、global / thread-local last_error，并建议下一步 docs-only `P1 error taxonomy boundary execution card`。

- [2026-04-26-p1-error-taxonomy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-boundary-execution-card.md)
  - 类型：execution card
  - 状态：完成；不自动开启实现
  - 用途：将 error taxonomy boundary preflight 收束成受限 execution card；明确 future taxonomy owner 倾向属于 `runtime/cjgui` error strategy module 但当前仍不是 error strategy implementation；future first slice 最多只能新增一个默认 internal、无行为、无 public、无 import 的 taxonomy marker / placeholder，用于表达 taxonomy boundary exists but taxonomy is not yet defined；继续禁止完整 taxonomy、error enum、`Result` type、severity / category / code 字段、修改 `CjguiInternalErrorFact`、public runtime API、public C ABI、exception-like mechanism、diagnostics truth system、smoke `last_error` 迁移、platform object / raw pointer / native error object、handle / generation、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。

- [2026-04-26-p1-error-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md)
  - 类型：closure review
  - 状态：完成
  - 用途：封账 P1 error taxonomy marker first slice，记录 `runtime/cjgui/src/error.cj` 新增默认 internal 空 `struct CjguiInternalErrorTaxonomyMarker {}`，它只表达 taxonomy boundary exists but taxonomy is not yet defined；`taxonomy_defined=false`、`error_enum_present=false`、`result_type_present=false`、`severity_field_present=false`、`category_field_present=false`、`code_field_present=false`、`error_fact_modified=false`、`public_api_present=false`、`public_c_abi_present=false`、`behavior_code_present=false`、`function_present=false`、`method_present=false`、`explicit_init_present=false`、`import_present=false`、`diagnostics_truth_system_present=false`、`smoke_last_error_migrated=false`、`cjpm_toml_changed=false`、`smoke_changed=false`、`cjpm build --target-dir /tmp/cjgui-error-taxonomy-marker-target --skip-script` 通过、smoke guard 通过，并将 next opening 转向 docs-only recoverability boundary preflight。

- [2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-recoverability-boundary-preflight.md)
  - 类型：preflight
  - 状态：完成；不批准直接实现
  - 用途：复盘 P1 error taxonomy marker first slice 可以封账，确认 `CjguiInternalErrorTaxonomyMarker` 只证明 taxonomy boundary marker 可构建，不证明 taxonomy、recoverability、severity / category / code、error enum、`Result` type、public runtime API、public C ABI 或 error strategy 已打开；冻结 recoverability 与 taxonomy / error strategy / app lifecycle / window lifecycle / platform adapter / diagnostics 的关系，继续禁止 recoverability enum、fatal / recoverable / degraded enum、severity / category / code 字段、修改 `CjguiInternalErrorFact` 或 taxonomy marker、smoke `last_error` 迁移、platform object / raw pointer / native error object、global / thread-local last_error，并建议下一步 docs-only `P1 error recoverability boundary execution card`。

## 当前下一步 opening

下一步推荐：

- `P1 app lifecycle transition marker first slice`

用途：

- 基于 [2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md)，只新增一个默认 internal、无 `public`、无 import 的 app lifecycle transition marker type。
- 该 marker 只表达 transition boundary exists but transition behavior is not yet defined，不得实现 state machine、transition behavior、`run` / `shutdown` / `request quit`、queue / drain、public runtime API 或 public C ABI。

当前可执行动作：

- 不自动开启实现。
- 根据 Docs Exit Rule，下一轮默认应进入 bounded implementation；除非发现 HIGH / CRITICAL 风险或 authority 冲突，不再新开 docs-only 入口替代实现。
