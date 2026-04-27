# P1 Frame Hash Bounds / Crop Semantics Policy Execution Card

日期：2026-04-26

性质：docs-only / execution card / bounded implementation authorization

状态：完成；创建本卡本身不等于实现；后续实现必须严格按本卡执行

范围：把 `P1 frame hash bounds / crop semantics policy preflight` 收束成一张受限 execution card。本卡最多只授权未来一个极窄的 `bounds / crop semantics readiness diagnostics` first slice，不授权真正 bounds normalization、content interior extraction、native bridge 修改、public C ABI / runtime API、baseline / golden hash、baseline compare、pixel diff、offscreen renderer、Renderer / Scene / Widget / Layout / DSL。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认 docs-only execution card 边界。
- 确认依据：[2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。
- 上层尽量仓颉原生：是，本卡不新增 public runtime API。
- 底层只保留必要平台桥接：是，本卡不允许修改 native bridge。
- 没有过早抽象跨平台：是。

创建本卡本身不等于已实现。未来如果需要真正 bounds normalization、content interior extraction、native bridge 改动、public API、baseline / golden hash、pixel diff 或 offscreen renderer，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-frame-hash-bounds-crop-semantics-policy-preflight.md)

背景文档只能提供上下文，不能扩大本卡授权范围。若提示词、实现冲动或既有 harness 现实与 authority 冲突，以 authority 和本卡 stop-line 为准。

## 2. Goal

未来 first slice 的唯一目标：

- 在现有 screenshot verification harness 中输出脱水 `bounds / crop semantics readiness diagnostics`。

未来 first slice 最多证明：

- 当前 bounds / crop semantics policy 仍未完成。
- 当前若继续使用 `target_window_screenshot_crop`，必须把已有 bounds 仅视为 diagnostics。
- 当前 hash input bounds 尚未定义。
- 当前 whole window crop 不允许升级成 baseline input contract。
- 当前 content interior extraction 不允许实现，也不能被宣称为已可用 source。

未来 first slice 不能证明：

- source 已 normalized。
- content interior bounds 已可用。
- point / pixel conversion、rounding、decoration、timing policy 已冻结。
- target window whole crop 可以长期作为 baseline source。
- baseline / golden hash、baseline compare、pixel diff 或 regression truth 已经可用。

## 3. Scope

未来 first slice 只做：

- 输出 bounds / crop semantics readiness diagnostics。
- 继续保留现有 screenshot verification、frame hash feasibility、baseline readiness、owner policy、source normalization readiness、artifact cleanup、artifact lifecycle 和 auto-close 验证语义。
- 继续声明当前 source 只是 `target_window_screenshot_crop`。
- 继续声明 source truth 只是 `user_visible_screenshot`。
- 继续保持 `source_normalized=false`。
- 继续保持 `baseline_allowed=false`。
- 继续保持 `hash_value_persistence_allowed=false`。
- 继续保持 `pixel_diff_allowed=false`。

未来 first slice 明确不做：

- 不实现真正 bounds normalization。
- 不实现 content interior extraction。
- 不修改 native bridge。
- 不新增 public C ABI / public runtime API。
- 不把 `content_interior_bounds` 宣称为当前可用 source。
- 不把 `target_window_crop_bounds` 或 whole window crop 升级为 baseline input contract。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 4. Required Invariants

未来 first slice 必须继续输出或保留等价含义：

```text
source=target_window_screenshot_crop
source_truth=user_visible_screenshot
source_normalized=false
baseline_allowed=false
hash_value_persistence_allowed=false
pixel_diff_allowed=false
```

这些字段是 readiness diagnostics，不是 source contract、baseline contract、pixel correctness proof 或 runtime API。

## 5. Future Diagnostics Fields

未来 first slice 可新增以下脱水日志字段，但本轮不实现：

```text
cjgui frame hash bounds crop semantics: requested=true
cjgui frame hash bounds crop semantics: source=target_window_screenshot_crop
cjgui frame hash bounds crop semantics: source_truth=user_visible_screenshot
cjgui frame hash bounds crop semantics: screen_bounds_points_observed=<true|false|unknown>
cjgui frame hash bounds crop semantics: capture_bounds_pixels_observed=<true|false|unknown>
cjgui frame hash bounds crop semantics: target_window_crop_bounds_observed=<true|false|unknown>
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

- `*_observed` 只能表示 harness 当前是否观察到某类 bounds diagnostics，不表示这些 bounds 已成为 hash input contract。
- `content_interior_bounds_observed=false` 是硬边界：当前没有正式 runtime view / content geometry API，不允许假装 content interior source 已可用。
- `hash_input_bounds_defined=false` 表示还没有冻结到底 hash 哪个矩形。
- `point_pixel_conversion_defined=false` 和 `rounding_policy_defined=false` 表示 Retina scale、multi-display、negative origin 和 rounding 仍未成为稳定规则。
- `decoration_policy_defined=false` 表示 title bar、shadow、rounded corner、traffic-light buttons、active / inactive state 是否进入 hash 仍未冻结。
- `whole_window_crop_baseline_allowed=false` 表示 whole window crop 不能升级为 baseline input contract。
- `success=true reason=none` 只表示 diagnostics 输出成功，不表示 source 已 normalized。

## 6. Future Implementation Write Set

未来 bounded implementation first slice 最多允许修改：

- [verify_user_visible_window_screenshot_verification.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh)
- [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- future closure review：`2026-04-26-p1-frame-hash-bounds-crop-semantics-readiness-diagnostics-closure-review.md`（由未来 implementation 回合创建）
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未来 implementation 不得因为“只是 diagnostics”而修改 capture、artifact、hash feasibility、baseline readiness、owner policy、source normalization readiness 或 auto-close 的既有语义。

## 7. Forbidden Write Set

未来 bounded implementation first slice 禁止修改：

- [cjgui_macos.m](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m)
- [cjgui_macos.h](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h)
- [src/main.cj](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj)
- [build_and_run.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh)
- [verify_auto_close.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh)
- [verify_user_visible_window_screenshot_feasibility.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh)
- public C ABI / public runtime API。
- native bridge。
- Renderer / Scene / Widget / Layout / DSL。
- offscreen renderer。
- baseline / golden hash / pixel diff 相关实现。
- 正式 runtime 目录。
- 跨平台 backend。
- 文本、输入法、无障碍。
- AI semantic tree / Action Router。

## 8. Truth / Projection

本卡的 truth：

- `target_window_screenshot_crop` 仍只是当前用户可见截图 evidence source。
- `source_truth=user_visible_screenshot` 仍只表示 screenshot / compositor / display presentation 后的证据线，不等同于 Metal readback truth。
- bounds / crop semantics 当前仍未 normalized。

本卡的 projection / read surface：

- readiness diagnostics 是脱水 read surface。
- bounds observed 字段是 harness diagnostics。
- source normalization、baseline readiness、owner policy、bounds / crop semantics diagnostics 都不是 Renderer / Scene truth。

## 9. Fallout Scan Targets

未来实现完成前必须确认：

- 公共 API：没有新增或改变 public C ABI / public runtime API。
- 事件流：没有改变 smoke event loop、auto-close 或 lifecycle queue 语义。
- 状态流：没有制造 baseline / hash / screenshot artifact 的第二真相源。
- 渲染流：没有修改 native bridge、Metal render path 或 content geometry。
- 平台桥接：没有暴露 `NSWindow*`、`NSView*`、`CGWindowID`、`CGImageRef`、Metal 对象或 Objective-C `id`。
- 视觉 / 交互：没有把 diagnostics 成功误写成 pixel correctness、source normalized 或 baseline readiness。
- 文档 / 示例：README、closure review、plans README、tracker 必须同步。
- 测试：原有 screenshot verification 和 auto-close harness 必须仍通过。

## 10. Future Verification

未来 bounded implementation first slice 至少必须执行：

```bash
bash -n /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

必须检查：

- 原有 screenshot verification diagnostics 仍在。
- 原有 frame hash feasibility diagnostics 仍在。
- 原有 source normalization readiness diagnostics 仍在。
- 新增 bounds / crop semantics diagnostics 出现。
- `content_interior_bounds_observed=false`。
- `hash_input_bounds_defined=false`。
- `whole_window_crop_baseline_allowed=false`。
- `baseline_allowed=false`。
- `hash_value_persistence_allowed=false`。
- `pixel_diff_allowed=false`。
- forbidden 文件 hash 未变。
- future closure review 能从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 和 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。
- `git diff --check` 通过。

如果任何验证失败，不能把 bounds policy / screenshot 环境 / permission / target mismatch 失败写成 render failure，除非有明确 render 日志证据。

## 11. Future Closure Review Requirements

future closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 是否只新增独立 readiness diagnostics。
- 是否实现 bounds normalization：必须为否。
- 是否实现 content interior extraction：必须为否。
- 是否修改 native bridge：必须为否。
- 是否新增 public C ABI / runtime API：必须为否。
- 实际 diagnostics 字段。
- 原有 screenshot verification / frame hash feasibility / source normalization readiness diagnostics 是否仍通过。
- 新增 bounds / crop semantics diagnostics 是否出现。
- `source=target_window_screenshot_crop` 是否保持。
- `source_truth=user_visible_screenshot` 是否保持。
- `source_normalized=false` 是否保持。
- `baseline_allowed=false` 是否保持。
- `hash_value_persistence_allowed=false` 是否保持。
- `pixel_diff_allowed=false` 是否保持。
- 是否保存或输出 hash value：必须为否。
- 是否保存成功 screenshot artifact：必须为否。
- 是否建立 baseline / golden hash：必须为否。
- 是否做 baseline compare：必须为否。
- 是否做 pixel diff：必须为否。
- 是否读取或输出 raw bytes：必须为否。
- 是否做 offscreen renderer：必须为否。
- 是否把 smoke demo 宣称为正式 GUI runtime：必须为否。
- residual risk：source 仍未 normalized，content interior 仍不可用，baseline 仍不允许，pixel diff 仍不允许，CI / headless 仍未证明。

## 12. This-Round Stop-line

本轮创建本卡时明确不做：

- 不实现 bounds normalization。
- 不实现 bounds readiness diagnostics。
- 不修改 harness。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不新增 public C ABI / public runtime API。
- 不保存或输出 hash value。
- 不建立 baseline / golden hash。
- 不做 baseline compare。
- 不做 pixel diff。
- 不读取或输出 raw bytes。
- 不保存成功 screenshot artifact。
- 不做 offscreen renderer。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 13. Next Opening

本卡之后的 next opening 是：

> `P1 frame hash bounds / crop semantics readiness diagnostics bounded implementation first slice`

这不是自动开启的实现。后续必须由用户显式确认后，才能严格按本 execution card 进入 bounded implementation。
