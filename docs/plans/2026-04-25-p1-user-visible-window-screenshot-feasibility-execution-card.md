# P1 User-Visible Window Screenshot Feasibility Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization

状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行

范围：只授权未来一个极窄 first slice，用独立 harness 探索当前本机 smoke 运行期间是否能请求一次用户可见窗口 / 屏幕截图，并把失败原因分类。本卡不授权 full screenshot verification、pixel diff、frame hash、artifact baseline 或 offscreen renderer。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 确认依据：
  - [2026-04-25-p1-user-visible-window-verification-evidence-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-verification-evidence-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来 first slice 只能使用当前 smoke、shell harness 和系统最小截图探测能力。
- 上层尽量仓颉原生：是。不得新增 public C ABI / runtime API，也不得让仓颉层持有截图、display 或 AppKit 对象。
- 底层只保留必要平台桥接：是。未来 probe 只能作为 smoke verification harness，不是 runtime capability。
- 没有过早抽象跨平台：是。本卡只覆盖 macOS smoke feasibility，不定义跨平台 screenshot contract。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现必须修改 bridge、读取像素、保存 screenshot artifact、建立 baseline、做 pixel diff / frame hash、设计 Renderer / Scene、或新增 public API，必须暂停并另开 preflight / execution card。

## 1. Authority

本卡唯一 authority：

- [2026-04-25-p1-user-visible-window-verification-evidence-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-user-visible-window-verification-evidence-preflight.md)

背景约束：

- [2026-04-25-p1-metal-readback-feasibility-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-closure-review.md)
- [2026-04-25-p1-metal-readback-feasibility-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-metal-readback-feasibility-execution-card.md)
- [2026-04-25-p1-screenshot-metal-readback-verification-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-screenshot-metal-readback-verification-preflight.md)
- [2026-04-25-p1-automated-gui-verification-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-closure-review.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)

这些背景文档不能把本卡扩展成：

- full screenshot verification。
- pixel diff。
- frame hash。
- offscreen renderer。
- public C ABI / runtime API。
- Renderer / Scene。
- Widget / Layout / DSL。
- 跨平台 screenshot abstraction。

## 2. Why Feasibility, Not Full Verification

当前只允许 screenshot feasibility，而不是 full screenshot verification，原因是：

- 当前没有稳定 screenshot source image。
- 当前没有 baseline artifact owner。
- 当前没有 hash / diff 阈值、颜色空间、Retina scale、遮挡和多显示器策略。
- 当前本机历史上出现过 `could not create image from display`，说明截图路径存在真实环境失败。
- screenshot failure 可能来自权限、display、窗口可见性、Space、遮挡或 timing，不能直接判定为 render failure。
- 当前 smoke demo 不是正式 runtime，不能为了验证反向设计 Renderer / Scene / Widget / Layout / DSL。

因此未来 first slice 只能回答：

- 当前本机 smoke 运行期间能否请求一次 screenshot / window capture。
- 如果不能，能否给出不伪装的失败分类。

它不能回答：

- 用户可见窗口像素是否正确。
- 截图是否与 expected image 一致。
- frame hash 或 pixel diff 是否通过。
- CI / headless 是否稳定。

## 3. Truth Boundary

Screenshot feasibility 不能替代 Metal readback truth。

Metal readback truth 是：

- command buffer completion 之后，受控 Metal render target 的 sample / summary。

Screenshot truth 是：

- OS / compositor / display presentation 之后，外部截图路径拿到的用户可见图像 evidence。

两者关系：

- Metal readback 更接近 GPU render target。
- screenshot 更接近用户最终看到的窗口。
- screenshot 失败可能完全来自桌面环境，而不是 render target。
- Metal readback 成功也不证明用户可见窗口成功。
- 两者都不是 Renderer / Scene / UI state truth，也都不是 public runtime API。

本卡只授权未来验证 screenshot path 的 feasibility，不授权把 screenshot 结果解释为视觉正确性。

## 4. Goal

未来 first slice 的唯一目标：

- 新增一个独立 screenshot feasibility harness，用于在 `labs/macos_bridge_smoke` 运行期间请求一次用户可见窗口 / 屏幕截图，并输出脱水 feasibility summary 或分类失败原因。

未来 first slice 只验证：

- smoke process 是否能启动。
- readiness 日志是否到达，例如 `window created`、`metal setup complete`、`first frame rendered`。
- screenshot probe 是否被请求。
- screenshot API / 命令是否返回可分类结果。
- 分类结果是否能被 closure review 复核。

未来 first slice 不验证：

- 像素颜色正确。
- screenshot 与 baseline 一致。
- frame hash 一致。
- pixel diff 通过。
- CI / headless 稳定可用。
- 用户可见窗口在所有环境中稳定可验证。

## 5. Scope

未来 first slice 只允许：

- 新增独立 screenshot feasibility harness。
- 调用现有 smoke build / run 路径作为被测对象。
- 观察现有 readiness 日志。
- 请求一次 screenshot / window capture feasibility probe。
- 输出脱水 summary 和 failure classification。
- 创建 closure review 并更新计划索引 / 任务账本。

未来 first slice 明确不允许：

- 修改 Objective-C bridge。
- 修改 `verify_auto_close.sh`。
- 修改 Cangjie 入口。
- 保存 screenshot artifact。
- 读取并比较像素颜色。
- 做 pixel diff。
- 做 frame hash。
- 做 offscreen renderer。
- 新增 public C ABI / runtime API。
- 暴露平台对象。
- 设计 Renderer / Scene / Widget / Layout / DSL。

## 6. Write Set

未来 implementation 最多允许修改：

- 新增独立 harness：
  - `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- 轻量更新：
  - [labs/macos_bridge_smoke/README.md](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- future closure review：
  - 建议路径：`docs/plans/2026-04-25-p1-user-visible-window-screenshot-feasibility-closure-review.md`
- 更新：
  - [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
  - [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未来 implementation 默认不允许修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `README.md`
- 正式 runtime 目录。
- public GUI API。
- Renderer / Scene / Widget / Layout / DSL。
- 跨平台 backend。
- 文本、输入法、无障碍相关实现。
- AI semantic tree / Action Router 相关实现。

明确回答：

- 是否允许修改 `cjgui_macos.m`：默认不允许。
- 是否允许修改 `verify_auto_close.sh`：默认不允许。
- 是否允许新增独立 harness：可以，但只能用于 screenshot feasibility probe。
- 建议 harness 路径：`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`。

例外规则：

- 如果未来发现不修改 `cjgui_macos.m` 就无法可靠定位窗口，必须暂停并另开 execution card；不得在本卡下顺手修改 bridge。
- 如果未来发现必须修改 `build_and_run.sh` 或仓颉入口，必须暂停并另开 execution card。
- 如果未来需要保存 artifact 才能解释失败，必须暂停并扩展 execution card；默认不允许。

本轮创建 execution card 时允许修改：

- 本 execution card。
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)，仅用于入口链接。

本轮创建 execution card 时禁止修改：

- `labs/macos_bridge_smoke`。
- `verify_auto_close.sh`。
- `cjgui_macos.m`。
- 任何运行时代码。

## 7. Harness Contract

未来 harness 最多能断言：

- `build_and_run.sh` 或等价 smoke runner 可以启动。
- smoke 日志出现 readiness needle：
  - `cjgui: window created`
  - `cjgui: metal setup complete`
  - `cjgui: first frame rendered`
- screenshot probe 被请求。
- screenshot API / 命令返回可分类结果。
- 成功时只输出脱水 summary，例如：
  - `cjgui screenshot feasibility: requested=true`
  - `cjgui screenshot feasibility: image_created=true`
  - `cjgui screenshot feasibility: success=true reason=none`
- 失败时只输出分类 summary，例如：
  - `cjgui screenshot feasibility: requested=true`
  - `cjgui screenshot feasibility: success=false reason=permission_denied`

未来 harness 不能断言：

- 像素颜色正确。
- Metal readback truth。
- screenshot 与 baseline 一致。
- frame hash 一致。
- pixel diff 通过。
- 用户可见窗口在所有环境中稳定正确。
- compositor / display presentation 对所有场景都正确。
- CI / headless 环境稳定可复核。
- smoke demo 是正式 runtime。

## 8. Artifact / Pixel Boundary

默认不允许：

- 保存 screenshot artifact。
- 保存 raw screen pixels。
- 读取并比较像素颜色。
- 输出 sampled pixel values。
- 建立 baseline artifact。
- 做 pixel diff。
- 做 frame hash。
- 做 offscreen renderer。

如果未来 implementation 想保存临时 screenshot 以便人工排查，必须先暂停并更新 execution card，明确：

- 临时路径。
- 是否保留。
- 是否提交。
- 删除策略。
- 为什么没有 artifact 就无法判断 feasibility。

在没有额外授权前，harness 只能依据截图 API / 命令的返回状态和脱水 metadata 判断 feasibility。

## 9. Failure Classification

未来 harness 必须支持这些分类：

- `permission_denied`
- `display_unavailable`
- `window_not_found`
- `window_not_visible`
- `capture_failed`
- `render_not_ready`
- `render_failure`
- `unknown`

分类语义：

- `permission_denied`：截图 API 明确因屏幕录制 / 截图权限失败，或返回符合权限缺失特征的错误。
- `display_unavailable`：没有可用 display，或出现类似 `could not create image from display` 的环境错误。
- `window_not_found`：无法找到 smoke window 或可用于定位的窗口信息。
- `window_not_visible`：窗口存在但不可见、最小化、隐藏、被切到其他 Space，或无法确认可见区域。
- `capture_failed`：readiness 和环境看似满足，但截图 API / 命令返回 nil、空图、非零退出或不可分类 capture error。
- `render_not_ready`：现有 readiness 日志未到 `first frame rendered`。
- `render_failure`：只有在 render readiness 明确失败、且与截图环境无关时才使用。
- `unknown`：证据不足，不能伪装成更具体原因。

必须避免：

- 把 screenshot failure 误判为 render failure。
- 把 permission failure 误判为 render failure。
- 把 window-not-visible failure 误判为 Metal readback failure。
- 把 `display_unavailable` 误判为 pixel incorrect。

历史错误处理：

- `could not create image from display` 默认归类为 `display_unavailable`。
- 如果未来能证明该错误由权限导致，可归类为 `permission_denied`，但 closure review 必须记录证据。

## 10. Platform Risk Handling

Screen Recording 权限：

- 未来 harness 必须把权限失败作为第一等 failure classification。
- 不允许把权限失败写成 render failure。
- 不允许在 runtime 中要求或管理权限。

Retina scale：

- 未来 first slice 不做像素比较，因此不需要归一化 scale。
- 如果记录 scale 或 bounds，只能作为脱水 diagnostics，不能写成 public contract。

多显示器：

- 未来 first slice 不承诺多显示器稳定。
- 如果 capture API 因 display 选择失败，应分类为 `display_unavailable` 或 `capture_failed`。

窗口遮挡：

- 未来 first slice 不做 pixel correctness，因此不判断遮挡后的内容。
- 如果无法确认窗口可见，应分类为 `window_not_visible`。

Space / Mission Control：

- 未来 first slice 不负责切换 Space 或控制 Mission Control。
- Space 导致不可见时，应分类为 `window_not_visible` 或 `capture_failed`。

frontmost app：

- 未来 first slice 不把 frontmost / focus 要求升级成 runtime API。
- 如果非前台导致无法 capture，应分类为 `window_not_visible` 或 `capture_failed`。

timing：

- 未来 harness 必须等待 readiness 日志后再请求 screenshot。
- `CJGUI_AUTOCLOSE_SECONDS` 或等价生命周期 timing 必须留出 probe 窗口。
- 如果 readiness 未达成，应分类为 `render_not_ready`，不能继续截图。

## 11. Platform Object Boundary

未来 first slice 不允许暴露：

- `NSWindow*`
- `NSView*`
- `NSScreen*`
- `CGWindowID`
- `CGImageRef`
- `CGDisplayID`
- `CAMetalLayer*`
- `CAMetalDrawable*`
- `id<MTLTexture>`
- Objective-C `id`
- 任何平台对象裸指针或 native handle

这些对象如被系统命令或内部 API 暂时使用，只能留在 harness / platform boundary 内，不得：

- 写入仓颉公共层。
- 暴露为 C ABI。
- 出现在 public runtime API。
- 进入 Renderer / Scene / Widget / Layout 设计。
- 以裸指针或 object identity 形式写进日志。

## 12. Future Closure Review Requirements

未来 closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 是否修改了 `cjgui_macos.m`：预期必须为否。
- 是否修改了 `verify_auto_close.sh`：预期必须为否。
- screenshot probe 使用的机制 / 命令 / API。
- 实际命令。
- 日志路径。
- readiness needle 是否出现。
- screenshot request 是否发起。
- 最终分类结果。
- 如果成功，是否只输出脱水 summary。
- 如果失败，具体 failure classification 和证据。
- 是否保存 screenshot artifact：默认必须为否。
- 是否读取或比较像素颜色：必须为否。
- 是否做 pixel diff：必须为否。
- 是否做 frame hash：必须为否。
- 是否做 offscreen renderer：必须为否。
- 是否新增 public C ABI / runtime API：必须为否。
- 是否暴露平台对象：必须为否。
- 是否把 screenshot failure 写成 render failure：必须为否。
- 是否把 smoke demo 宣称为正式 runtime：必须为否。

closure review 还必须明确：

- 这只是 screenshot feasibility。
- 这不是 full screenshot verification。
- 这不是 pixel correctness proof。
- 这不是 compositor correctness proof。
- 这不是 CI / headless proof。
- 这不是 Renderer / Scene / Widget / Layout 设计。

## 13. Runtime Pollution Guard

为了避免截图 feasibility 反向污染 runtime 设计：

- harness 只能是 verification harness。
- screenshot evidence 只能是外部 evidence。
- 不把 screenshot 坐标、display id、window id、window bounds 写成 public API。
- 不为了截图便利调整 formal render pipeline。
- 不为了截图便利修改 bridge lifecycle。
- 不为了截图便利设计 Renderer / Scene。
- 不为了截图便利设计 Widget / Layout / DSL。
- 不为了截图便利引入跨平台 backend。
- 不建立 baseline / diff / artifact 系统。

为了避免 smoke demo 被升级成正式 runtime：

- 始终称为 `labs/macos_bridge_smoke`。
- 始终称为 smoke demo、smoke diagnostics 或 verification harness。
- 不把 smoke 日志字段写成 public runtime contract。
- 不让 screenshot feasibility 定义 future Renderer / Scene truth。
- 每个后续实现必须有 closure review，说明“这不是正式 GUI runtime”。

## 14. Verification Plan For Future First Slice

未来 implementation 必须至少验证：

- 新 harness shell 语法检查。
- 新 harness 在当前本机运行一次。
- harness 输出 readiness / screenshot requested / success or failure classification summary。
- 没有生成 screenshot artifact。
- 没有读取或比较像素。
- 没有修改 forbidden files。
- 新 closure review 可从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。

允许的成功形态：

- `success=true reason=none image_created=true` 这类脱水 summary。

允许的失败形态：

- `success=false reason=<classification>`，其中 `<classification>` 必须来自本卡的 failure classification。

失败不是 implementation failure 的充分条件。

如果本机因为权限或 display 环境失败，closure review 可以接受失败分类本身作为 feasibility evidence，但必须诚实说明未获得用户可见窗口截图。

## 15. Current Stop-Line

本轮创建 execution card 的强制 stop-line：

- 本轮不实现 screenshot。
- 本轮不实现 window screenshot。
- 本轮不读取屏幕像素。
- 本轮不保存 screenshot artifact。
- 本轮不实现 pixel diff。
- 本轮不实现 frame hash。
- 本轮不实现 offscreen renderer。
- 本轮不修改 `labs/macos_bridge_smoke`。
- 本轮不修改 `verify_auto_close.sh`。
- 本轮不修改 `cjgui_macos.m`。
- 本轮不新增 public C ABI / runtime API。
- 本轮不设计 Renderer / Scene。
- 本轮不设计 Widget / Layout / DSL。
- 本轮不做跨平台抽象。
- 本轮不做文本、输入法、无障碍。
- 本轮不做 AI semantic tree / Action Router。
- 本轮不把当前 smoke demo 宣称为正式 runtime。

## 16. Next Opening

本卡之后的推荐 next opening：

- `P1 user-visible window screenshot feasibility bounded implementation first slice`

但它仍然不自动开启实现。

若未来用户明确开启该 implementation first slice，必须严格按本卡执行；不得扩成 full screenshot verification、pixel diff、frame hash、offscreen renderer、Renderer / Scene、Widget / Layout / DSL、跨平台抽象或 public runtime API。
