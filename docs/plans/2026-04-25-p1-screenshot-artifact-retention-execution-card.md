# P1 Screenshot Artifact Retention Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization

状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行

范围：只授权未来一个极窄 first slice，围绕现有 screenshot verification harness 的 artifact retention / cleanup policy 做最小调整。本卡不授权 pixel diff、frame hash、baseline、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、public C ABI 或 public runtime API。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 确认依据：
  - [2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 只能调整现有 smoke verification harness 的 artifact retention / cleanup 行为。
- 上层尽量仓颉原生：是。不得新增 public C ABI / runtime API，也不得让仓颉层持有 screenshot、artifact、window、display 或平台对象。
- 底层只保留必要平台桥接：是。artifact retention 属于外部 verification harness policy，不是 runtime capability。
- 没有过早抽象跨平台：是。本卡只覆盖当前 macOS `labs/macos_bridge_smoke`，不定义跨平台 artifact contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现需要修改 native bridge、仓颉入口、构建脚本、auto-close harness、读取整图像素、建立 baseline、做 pixel diff / frame hash、设计 Renderer / Scene，或新增 public API，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-verification-artifact-retention-policy-preflight.md)

背景依据：

- [2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-closure-review.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-execution-card.md)
- [2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-verification-preflight.md)
- [2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md)
- [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡扩展成：

- screenshot verification redesign。
- pixel diff。
- frame hash。
- baseline / golden image。
- offscreen renderer。
- public C ABI / runtime API。
- Renderer / Scene。
- Widget / Layout / DSL。
- 跨平台 artifact abstraction。

## 2. Current Reality

当前 screenshot verification first slice 已完成并 closure：

- 现有独立 harness 为 `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`。
- harness 会启动现有 `build_and_run.sh`。
- harness 会等待 readiness 日志。
- harness 能通过 owner pid / title / bounds 归属目标 smoke window。
- harness 会在 `/tmp/cjgui-p1-screenshot-verification.XXXXXX/target-window.png` 创建临时 artifact。
- harness 只做中心附近 `3x3` clear-color sample summary。
- 当前本机结果为 `success=true reason=none`。
- 成功路径当前删除 artifact 和临时目录。
- 失败路径如果 artifact 已创建，可以保留临时目录并输出删除策略。

当前仍没有：

- 明确执行化的 artifact retention / cleanup policy。
- 历史 `/tmp/cjgui-p1-screenshot-verification.*` 残留清理实现。
- artifact review closure template。
- baseline policy implementation。
- pixel diff / frame hash preflight。

## 3. Goal

未来 first slice 的唯一目标：

- 围绕现有 screenshot verification harness 的 artifact retention / cleanup policy 做极窄调整，让成功 / 失败 artifact 生命周期、历史临时目录清理、输出 summary 和 closure evidence 更可控。

未来 first slice 最多允许：

- 保持成功 artifact 默认删除。
- 明确失败 artifact 只在短期、受控、可解释条件下保留。
- 明确 artifact 只能位于 `/tmp` 或 `mktemp -d` 临时目录。
- 可选增加历史 `/tmp/cjgui-p1-screenshot-verification.*` 残留清理，但必须限定 TTL / pattern。
- 更新 smoke README 说明 artifact policy。
- 创建 closure review 记录实际行为和 stop-line。

未来 first slice 不允许：

- 改变 screenshot capture truth。
- 增加 pixel diff。
- 增加 frame hash。
- 建立 baseline / golden image。
- 引入 long-term cache。
- 保存 full-screen screenshot。
- 读取整图像素或输出 raw bytes。
- 修改 native bridge、仓颉入口、build script 或 auto-close harness。
- 把 artifact policy 升级成 public runtime feature。

## 4. Artifact Retention Invariants

未来 implementation 必须守住：

- 成功 artifact 默认必须删除。
- 失败 artifact 只允许短期、受控、可解释地保留。
- artifact 默认只能位于 `/tmp` 或 `mktemp -d` 创建的临时目录。
- artifact 不允许进入仓库。
- artifact 不允许提交。
- artifact 不允许进入 baseline / golden image。
- artifact 不允许进入 long-term cache。
- artifact 不允许成为 CI 默认产物。
- 不允许 full-screen screenshot retention。
- 如果未来允许 target-window crop retention，只能服务失败诊断。
- target-window crop retention 必须记录路径、保留原因、failure classification、删除策略和人工审查责任。
- artifact 路径不能成为 public runtime API。
- artifact 内容不能被内联进 Markdown 或编码进日志。

成功 artifact：

- 默认删除 artifact 和临时目录。
- 不允许为了“好看”或“留证”默认保留。
- 若未来实现提供调试开关保留成功 artifact，必须先另开 execution card；本卡不授权。

失败 artifact：

- 只有在 artifact 有助于解释失败分类时才允许保留。
- 默认保留时间不超过 24 小时。
- 必须输出删除策略，例如 `rm -rf <dir>`。
- 必须避免保存包含大量用户桌面内容的 full-screen image。
- 若无法确认 artifact 是 target-window crop，应删除或分类为 `target_mismatch` / `unknown`。

## 5. Cleanup Policy

是否需要清理历史 `/tmp/cjgui-p1-screenshot-verification.*` 残留：

- 需要，但未来 implementation 只能做 TTL / pattern 限定的安全清理。

未来允许的最小清理规则：

- 只匹配 `/tmp/cjgui-p1-screenshot-verification.*`。
- 只删除目录，不递归处理任意用户指定路径。
- 只删除超过 TTL 的旧目录。
- TTL 默认不短于 24 小时，除非 execution card 明确收窄。
- 不删除当前运行实例的临时目录。
- 清理动作必须输出脱水 summary，例如：
  - `cleanup_requested=true`
  - `cleanup_pattern=/tmp/cjgui-p1-screenshot-verification.*`
  - `cleanup_ttl_hours=24`
  - `cleanup_deleted_count=<n>`
- 清理失败不得伪装成 render failure。

未来不允许：

- 删除任意 `/tmp` 内容。
- 删除不匹配 `cjgui-p1-screenshot-verification.*` 的路径。
- 跟随不可信 symlink。
- 读取或上传 artifact 内容。
- 把 cleanup 做成长期 daemon、service 或 runtime feature。

## 6. Future Write Set

未来 bounded implementation first slice 最多允许修改：

- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
  - 仅允许调整 artifact retention / cleanup policy。
  - 必须保留现有 readiness、target attribution、sample summary 和 success / failure classification 语义。
- [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
  - 只记录 smoke artifact policy、验证命令和非正式 runtime 边界。
- future closure review：
  - `docs/plans/2026-04-25-p1-screenshot-artifact-retention-closure-review.md`
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

本轮创建 execution card 时允许修改：

- 新建本 execution card。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 轻量更新 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 以避免孤儿文档。

## 7. Forbidden Write Set

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
- 是否允许修改 Cangjie 入口：不允许。
- 是否允许修改 `build_and_run.sh`：不允许。
- 是否允许修改 `verify_auto_close.sh`：不允许。
- 是否允许新增 public C ABI / runtime API：不允许。

如果未来发现必须修改 forbidden write set 才能实现 cleanup / retention，必须暂停并另开 preflight / execution card。

## 8. Truth / Projection Boundary

本卡的 truth：

- artifact lifecycle policy。
- artifact 是否被创建、删除或短期保留。
- cleanup 是否按 pattern / TTL 限制执行。
- harness 输出的脱水 summary。

本卡的 projection / read surface：

- 临时 artifact 路径。
- 删除策略。
- cleanup summary。
- failure classification。
- closure review 中的人工审查记录。

本卡不改变：

- render truth。
- Metal readback truth。
- screenshot sample truth。
- target attribution truth。
- UI state truth。
- Renderer / Scene truth。

artifact policy 不得反向定义 runtime 行为。

## 9. Verification Requirements For Future Implementation

未来 implementation first slice 至少要验证：

- `bash -n labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
- 运行 screenshot verification harness。
- 运行原有 `verify_auto_close.sh`，确认未破坏。
- 成功路径仍删除 artifact 和临时目录。
- 失败路径如果保留 artifact，必须输出路径、保留原因、classification 和删除策略。
- cleanup 如实现，必须只匹配 `/tmp/cjgui-p1-screenshot-verification.*` 并遵守 TTL。
- forbidden files 未修改：
  - `cjgui_macos.m`
  - `cjgui_macos.h`
  - `src/main.cj`
  - `build_and_run.sh`
  - `verify_auto_close.sh`
- closure review 可从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。

允许的成功形态：

- `success=true reason=none`
- `artifact_deleted=true`
- `artifact_retained=false`
- cleanup summary 如适用。

允许的失败形态：

- `success=false reason=<classification>`
- 若保留 artifact，必须是 target-window crop 失败诊断用途，并输出删除策略。

失败不是 implementation failure 的充分条件；权限、display、visibility、target mismatch、capture failure 或 timing failure 可以作为诚实 evidence。

## 10. Future Closure Review Requirements

未来 closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 是否修改了 screenshot verification harness。
- artifact 默认路径。
- 成功 artifact 是否删除：必须默认为是。
- 失败 artifact 是否保留。
- 如失败保留 artifact：
  - 路径。
  - 保留原因。
  - failure classification。
  - 是否为 target-window crop。
  - 删除策略。
  - 人工审查责任。
- 是否保存 full-screen screenshot：必须为否。
- artifact 是否进入仓库：必须为否。
- artifact 是否提交：必须为否。
- artifact 是否进入 baseline / golden image：必须为否。
- artifact 是否进入 long-term cache：必须为否。
- 是否清理历史 `/tmp/cjgui-p1-screenshot-verification.*`。
- 如清理：
  - pattern。
  - TTL。
  - 删除数量。
  - 是否避免删除当前运行目录。
- 是否读取或比较像素：除既有极窄 sample 外不得扩大。
- 是否读取整图像素：必须为否。
- 是否输出 raw bytes：必须为否。
- 是否做 pixel diff：必须为否。
- 是否做 frame hash：必须为否。
- 是否做 offscreen renderer：必须为否。
- 是否新增 public C ABI / runtime API：必须为否。
- 是否修改 native bridge、Cangjie 入口、`build_and_run.sh` 或 `verify_auto_close.sh`：必须为否。
- 是否把 smoke demo 宣称为正式 runtime：必须为否。

closure review 还必须明确：

- 这只是 artifact retention / cleanup policy first slice。
- 这不是 full screenshot verification。
- 这不是 pixel diff。
- 这不是 frame hash。
- 这不是 baseline。
- 这不是 offscreen renderer。
- 这不是 CI / headless proof。
- 这不是 Renderer / Scene / Widget / Layout 设计。
- 这不是正式 GUI runtime。

## 11. Runtime Pollution Guard

为了避免 artifact policy 反向污染 Renderer / Scene / Widget / Layout / DSL：

- artifact retention 只能是 verification harness policy。
- artifact 路径不能进入 public runtime API。
- cleanup policy 不能成为 framework service。
- target-window crop 不成为 Widget / Scene bounds contract。
- failure artifact review 不成为 public diagnostics API。
- 不为了 artifact 保留便利修改 bridge lifecycle。
- 不为了 artifact 清理便利新增 runtime hooks。
- 不为了 future pixel diff 预先设计 Renderer / Scene。

为了避免 smoke demo 被升级成正式 runtime：

- 始终称为 `labs/macos_bridge_smoke`。
- 始终称为 smoke demo、smoke diagnostics 或 verification harness。
- 不把 smoke window title、artifact path、cleanup pattern、sample strategy 写成 public runtime contract。
- 不把 artifact policy 写成框架承诺。
- 每个后续实现必须有 execution card 和 closure review。

## 12. Stop-Line

本轮创建 execution card 的强制 stop-line：

- 本轮不实现 artifact retention / cleanup policy。
- 本轮不修改 screenshot verification harness。
- 本轮不保存 screenshot artifact。
- 本轮不读取或比较像素。
- 本轮不实现 pixel diff。
- 本轮不实现 frame hash。
- 本轮不实现 offscreen renderer。
- 本轮不修改 `labs/macos_bridge_smoke`。
- 本轮不修改 `verify_user_visible_window_screenshot_verification.sh`。
- 本轮不修改 `verify_auto_close.sh`。
- 本轮不修改 `cjgui_macos.m`。
- 本轮不新增 public C ABI / runtime API。
- 本轮不设计 Renderer / Scene。
- 本轮不设计 Widget / Layout / DSL。
- 本轮不做跨平台抽象。
- 本轮不做文本、输入法、无障碍。
- 本轮不做 AI semantic tree / Action Router。
- 本轮不把当前 smoke demo 宣称为正式 runtime。

未来 implementation first slice 的 stop-line：

- 只允许围绕 artifact retention / cleanup policy 的极窄 harness 调整。
- 成功 artifact 默认必须删除。
- 失败 artifact 只允许短期、受控、可解释地保留。
- 不允许 artifact 进入仓库。
- 不允许 artifact 提交。
- 不允许 baseline / golden image / long-term cache。
- 不允许 full-screen screenshot retention。
- 不允许 pixel diff。
- 不允许 frame hash。
- 不允许 offscreen renderer。
- 不允许新增 public C ABI / runtime API。
- 不允许修改 native bridge、Cangjie 入口、`build_and_run.sh` 或 `verify_auto_close.sh`。
- 不允许 Renderer / Scene / Widget / Layout / DSL。

## 13. Next Opening

本卡创建后，不自动执行实现。

如果用户明确继续推进，下一条 bounded implementation opening 是：

- `P1 screenshot artifact retention bounded implementation first slice`

该 opening 只能按本卡执行：

- 最多调整现有 screenshot verification harness 的 artifact retention / cleanup policy。
- 最多增加 TTL / pattern 限定的历史 `/tmp/cjgui-p1-screenshot-verification.*` 安全清理。
- 必须保留成功默认删除。
- 必须限制失败 artifact 为短期、受控、可解释的 target-window crop 诊断。
- 完成后必须创建 closure review。

除非另开 preflight / execution card，否则不得进入 pixel diff、frame hash、baseline、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、跨平台抽象或 public runtime API。
