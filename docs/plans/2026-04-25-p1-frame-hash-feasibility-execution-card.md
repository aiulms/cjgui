# P1 Frame Hash Feasibility Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization

状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行

范围：只授权未来一个极窄 first slice：`frame hash feasibility`。本卡不授权 pixel diff、baseline / golden image、raw bytes 保存、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、public C ABI 或 public runtime API。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 唯一确认依据：
  - [2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 只能复用现有 smoke screenshot verification harness 的最小能力。
- 上层尽量仓颉原生：是。不得新增 public C ABI / runtime API，也不得让仓颉层持有 screenshot、hash、artifact、window、display 或平台对象。
- 底层只保留必要平台桥接：是。本卡选择 user-visible screenshot evidence source，不要求修改 native bridge。
- 没有过早抽象跨平台：是。本卡只覆盖当前 macOS smoke verification harness，不定义跨平台 hash contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现需要同时支持多个 source、修改 native bridge、保存 raw bytes、建立 baseline、做 pixel diff、引入 offscreen renderer、设计 Renderer / Scene，或新增 public API，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-pixel-diff-frame-hash-prerequisites-preflight.md)

背景文档：

- [2026-04-25-p1-screenshot-artifact-retention-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡扩展成：

- pixel diff。
- threshold diff。
- region diff。
- baseline compare。
- baseline / golden image。
- raw bytes artifact。
- offscreen renderer。
- Metal readback expansion。
- public C ABI / runtime API。
- Renderer / Scene / Widget / Layout / DSL。

## 2. Source Image Decision

本卡必须二选一指定未来 source image。

本卡选择：

> `target-window screenshot crop`

选择原因：

- 现有 screenshot verification first slice 已完成 target attribution。
- 现有 harness 已能记录 smoke process id、window title、bounds、frontmost app、display 和 scale diagnostics。
- 现有 harness 已能创建临时 target-window artifact，并在成功路径删除。
- artifact retention / cleanup policy first slice 已完成，成功 artifact 默认删除，失败 artifact 只允许短期受控保留。
- 该 source 最接近 user-visible window evidence，适合验证 frame hash feasibility 的输入归一化风险。
- 选择它不需要修改 native bridge，不需要扩大 Metal readback，也不需要 offscreen renderer。

本卡不选择：

- Metal readback source。
- future offscreen renderer。
- 同时支持多个 source。

如果选择 Metal readback source，本来必须解释为什么要修改 native bridge：

- 当前 Metal readback closure 只有 smoke-only、single-frame、clear-color probe summary。
- 当前没有整帧 bytes，没有 hash 输入边界。
- 扩成 frame hash source 可能需要修改 native bridge、staging buffer、row bytes、pixel format、同步点和 readback 生命周期。
- 这会重新打开 Metal / native bridge write set，并有滑向 renderer diagnostics 的风险。

本卡没有足够强理由选择 Metal readback，因此明确不选。

## 3. Truth Boundary

target-window screenshot crop 的 truth：

- OS / compositor / display presentation 之后，外部 screenshot harness 得到的 user-visible evidence source。
- 它是用户可见窗口证据线的一部分。

它不等同于：

- Metal readback truth。
- GPU render target truth。
- Renderer / Scene truth。
- UI state truth。
- public runtime capability。

本卡要求未来 implementation 明确输出 source truth，例如：

```text
cjgui frame hash feasibility: source=target_window_screenshot_crop
cjgui frame hash feasibility: source_truth=user_visible_screenshot
```

如果未来运行无法确认 source 属于目标窗口，不能计算成功 hash summary，也不能声明 success。

## 4. Goal

未来 first slice 的唯一目标：

- 在当前 smoke 运行期间，复用 target-window screenshot crop 作为唯一 source image，在当前运行内计算一个脱水 frame hash feasibility summary。

未来 first slice 最多允许证明：

- source image 可以被归属为目标 smoke window crop。
- source bounds、scale、颜色空间和 pixel format 等 hash 前置条件可以被记录，或诚实输出 `unknown` / `degraded`。
- 当前运行内可以计算一个脱水 hash summary。
- hash summary 可以被日志捕获，用于 feasibility evidence。

未来 first slice 不允许证明：

- 视觉正确。
- pixel diff 通过。
- baseline match。
- frame hash regression 通过。
- CI / headless 可复核。
- Metal render target 正确。
- Renderer / Scene / Widget / Layout 正确。
- 当前 smoke demo 是正式 GUI runtime。

## 5. Hash Feasibility Boundary

未来 first slice 允许：

- 只对 target-window screenshot crop 做当前运行内 hash feasibility。
- 只输出脱水 summary。
- 记录 source、bounds、scale、颜色空间、pixel format 或 `unknown` / `degraded` classification。
- 记录 hash algorithm 名称，例如 `sha256` 或 `unknown`。
- 记录 hash 是否计算成功。

未来 first slice 不允许：

- 建立 baseline / golden image。
- 比较 golden hash。
- 把 hash 写成长期 golden value。
- 把 hash mismatch 写成 render failure。
- 保存 raw bytes。
- 输出 raw bytes。
- 提交 artifact。
- 保存成功 screenshot artifact。
- 保存 full-screen screenshot。
- 做 pixel diff。
- 做 threshold diff。
- 做 region diff。
- 做 baseline compare。
- 对 hash 做 pass/fail regression 判断。

建议 summary 形态：

```text
cjgui frame hash feasibility: requested=true
cjgui frame hash feasibility: source=target_window_screenshot_crop
cjgui frame hash feasibility: source_truth=user_visible_screenshot
cjgui frame hash feasibility: bounds=...
cjgui frame hash feasibility: scale=...
cjgui frame hash feasibility: color_space=...|unknown
cjgui frame hash feasibility: pixel_format=...|unknown
cjgui frame hash feasibility: algorithm=sha256
cjgui frame hash feasibility: hash_computed=true
cjgui frame hash feasibility: hash_persisted=false
cjgui frame hash feasibility: baseline_compared=false
cjgui frame hash feasibility: success=true reason=none
```

如果任一前置条件无法确认，必须允许输出：

```text
cjgui frame hash feasibility: success=false reason=prerequisite_missing
```

或对应更具体分类，例如 `target_mismatch`、`window_not_visible`、`capture_failed`、`display_unavailable`、`permission_denied`、`unknown`。

## 6. Artifact Retention Policy

未来 implementation 必须继续遵守 screenshot artifact retention policy：

- 成功 artifact 默认删除。
- 失败 artifact 只允许短期、受控、可解释地保留。
- artifact 只能位于 `/tmp` 或 `mktemp -d` 临时目录。
- 历史 `/tmp/cjgui-p1-screenshot-verification.*` 残留清理只允许按 pattern / TTL 执行。
- artifact 不允许进入仓库。
- artifact 不允许提交。
- artifact 不允许进入 baseline / golden image。
- artifact 不允许进入 long-term cache。
- artifact 不允许内联进 Markdown 或日志。
- artifact 内容不允许 base64 写入日志。

成功路径：

- 允许当前运行内读取 target-window crop 以计算 hash summary。
- hash 计算完成后，成功 artifact 必须删除。
- 日志必须继续证明 `artifact_deleted=true`、`artifact_retained=false`，或等价字段。

失败路径：

- 失败 artifact 只有在服务 failure classification 时才可短期保留。
- 必须输出保留原因、failure classification、路径、TTL 和删除策略。
- 不能因为 frame hash feasibility 失败就建立 baseline 或保留成功 artifact。

## 7. 与当前 `3x3` Clear-color Sample 的区别

当前 `3x3` sample：

- 只读取目标窗口中心附近极小区域。
- 只判断 expected clear color 是否匹配。
- 输出 `sample_points` 和 `sample_match`。
- 不代表整张 source image 可归一化。
- 不产生 hash input boundary。

frame hash feasibility：

- 关注 source image 是否能被稳定归一化为 hash 输入。
- 至少要记录 source、bounds、scale、颜色空间和 pixel format。
- 输出一个脱水 hash feasibility summary。
- 不比较 baseline。
- 不证明 pixel correctness。
- 不替代 `3x3` sample 的 clear-color 语义。

二者关系：

- `3x3` sample 是极窄内容 sanity check。
- frame hash feasibility 是 source normalization / evidence compression sanity check。
- 两者都不是 pixel diff，也都不是正式 frame hash regression。

## 8. 与正式 Frame Hash Regression 的区别

frame hash feasibility 只回答：

- 当前运行内是否能计算一个 hash summary。
- hash 输入前置条件是否可被记录。
- hash 计算是否能不保存 raw bytes、不建立 baseline、不提交 artifact。

正式 frame hash regression 还需要：

- baseline / golden hash owner。
- baseline storage。
- baseline update 审批。
- hash 输入规范。
- source image 归一化规范。
- 跨机器稳定性策略。
- CI / headless 策略。
- mismatch classification。

本卡不授权正式 frame hash regression。

未来 implementation 即使成功输出 hash，也只能说明 feasibility，不得写成：

- `frame_hash_verified=true`
- `baseline_match=true`
- `visual_verified=true`
- `pixel_correct=true`
- `render_verified=true`

## 9. 为什么 Pixel Diff 仍不能作为下一刀

pixel diff 仍不能作为下一刀，原因：

- 当前没有 baseline / golden image owner。
- 当前不允许 artifact 进入 baseline。
- 当前没有 diff threshold。
- 当前没有区域 diff policy。
- 当前没有颜色空间 / scale / alpha / anti-aliasing 策略。
- 当前没有 CI / headless 复核策略。
- 当前没有 Renderer / Scene truth。
- 当前只完成 clear-color smoke，baseline 容易绑定 demo 偶然性。
- screenshot failure、target mismatch、window occlusion、permission failure 和 display failure 仍可能被误写成 render failure。

因此本卡只授权未来 frame hash feasibility，不授权 pixel diff。

## 10. Future Write Set

未来 bounded implementation first slice 最多允许修改：

- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
  - 仅允许在现有 target-window screenshot verification harness 内增加 frame hash feasibility summary。
  - 必须保留现有 readiness、target attribution、artifact lifecycle、`3x3` sample 和 success / failure classification 语义。
- [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
  - 只记录 frame hash feasibility 字段、验证命令、artifact policy 和非正式 runtime 边界。
- future closure review：
  - `docs/plans/2026-04-25-p1-frame-hash-feasibility-closure-review.md`
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

本轮创建 execution card 时允许修改：

- 新建本 execution card。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

## 11. Forbidden Write Set

未来 implementation 默认不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- 正式 runtime 目录。
- public GUI API。
- Renderer / Scene / Widget / Layout / DSL。
- 跨平台 backend。
- 文本、输入法、无障碍相关实现。
- AI semantic tree / Action Router 相关实现。

明确回答：

- 是否允许修改 native bridge：不允许。
- 是否允许修改 `verify_auto_close.sh`：不允许。
- 是否允许新增 public C ABI / runtime API：不允许。
- 是否允许做 offscreen renderer：不允许。
- 是否允许设计 Renderer / Scene / Widget / Layout / DSL：不允许。
- 是否允许做跨平台抽象：不允许。

如果未来发现必须修改 forbidden write set 才能计算 frame hash，必须暂停并另开 preflight / execution card。

## 12. Future Verification Requirements

未来 implementation first slice 至少要验证：

- `bash -n labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
- 运行 screenshot verification harness。
- 运行原有 `verify_auto_close.sh`，确认未破坏。
- 原有 readiness needle 仍出现：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- 原有 target attribution diagnostics 仍输出。
- 原有 `3x3` clear-color sample summary 仍输出。
- 成功路径仍删除 artifact。
- 新增 frame hash feasibility summary 输出。
- summary 必须说明：
  - source。
  - source truth。
  - bounds。
  - scale。
  - color space 或 `unknown` / `degraded`。
  - pixel format 或 `unknown` / `degraded`。
  - hash computed。
  - hash persisted false。
  - baseline compared false。
- forbidden files 未修改。
- closure review 可从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。

允许的成功形态：

- `success=true reason=none`
- `hash_computed=true`
- `hash_persisted=false`
- `baseline_compared=false`

允许的失败形态：

- `success=false reason=<classification>`
- 失败分类必须诚实；不能把 permission / display / target / visibility / prerequisite failure 写成 render failure。

## 13. Future Closure Review Requirements

未来 closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 是否只选择了 `target-window screenshot crop` source。
- 是否修改 native bridge：必须为否。
- 是否修改 `verify_auto_close.sh`：必须为否。
- 是否新增 public C ABI / runtime API：必须为否。
- source truth：必须为 user-visible screenshot evidence，不是 Metal readback truth。
- source bounds / scale / color space / pixel format 记录结果。
- hash algorithm。
- hash 是否只作为 feasibility summary。
- hash 是否写成 long-term golden value：必须为否。
- 是否保存 raw bytes：必须为否。
- 是否提交 artifact：必须为否。
- 是否保存成功 screenshot artifact：必须为否。
- 是否建立 baseline / golden image：必须为否。
- 是否做 pixel diff / threshold diff / region diff / baseline compare：必须为否。
- 是否把 hash mismatch 写成 render failure：必须为否。
- artifact success / failure retention 行为。
- 原有 `3x3` clear-color sample 是否仍通过或诚实分类失败。
- 原有 auto-close harness 是否仍通过。
- residual risk：
  - 这不是 pixel diff。
  - 这不是 baseline regression。
  - 这不是 Metal readback truth。
  - 这不是 CI / headless proof。
  - 这不是 Renderer / Scene / Widget / Layout 设计。
  - 这不是正式 GUI runtime。

## 14. Stop-line

本轮创建 execution card 的 stop-line：

- 不实现 frame hash。
- 不实现 pixel diff。
- 不建立 baseline / golden image。
- 不读取整图像素。
- 不保存 raw bytes。
- 不保存 screenshot artifact。
- 不修改 `labs/macos_bridge_smoke`。
- 不修改 screenshot verification harness。
- 不修改 `verify_auto_close.sh`。
- 不修改 native bridge。
- 不新增 public C ABI / runtime API。
- 不做 offscreen renderer。
- 不设计 Renderer / Scene / Widget / Layout / DSL。
- 不做跨平台抽象。
- 不把 smoke demo 宣称为正式 GUI runtime。

未来 implementation first slice 的 stop-line：

- 只允许 frame hash feasibility。
- 不允许 pixel diff。
- 不允许 baseline / golden image。
- 不允许保存 raw bytes。
- 不允许提交 artifact。
- 不允许保存成功 screenshot artifact。
- 不允许把 hash 写成长期 golden value。
- 不允许把 hash mismatch 写成 render failure。
- 不允许修改 native bridge。
- 不允许新增 public C ABI / runtime API。
- 不允许 offscreen renderer。
- 不允许 Renderer / Scene / Widget / Layout / DSL。
- 不允许跨平台抽象。

## 15. Next Opening

本卡之后的 next opening：

> `P1 frame hash feasibility bounded implementation first slice`

仍不自动开启实现。

如果继续推进，必须显式确认按本卡执行 bounded implementation；不得自动进入 pixel diff、baseline、golden image、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、cross-platform abstraction 或 public runtime API。
