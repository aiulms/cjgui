# P1 Main-thread UI Message Queue Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization  
状态：已创建；创建本卡本身不等于已实现；后续实现必须严格按本卡执行  
范围：只授权未来在 `labs/macos_bridge_smoke` 内实现一个极窄的单实例 lifecycle queue first slice。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认本卡边界；未执行实现
- 确认者：Codex
- 确认依据：
  - [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。未来实现仍只允许使用当前 macOS bridge smoke 已有的 AppKit / Metal 系统能力。
- 上层尽量仓颉原生：是。不得新增正式 public runtime API，也不得让仓颉层持有平台对象。
- 底层只保留必要平台桥接：是。队列 first slice 只能服务于 bridge 内部 lifecycle。
- 没有过早抽象跨平台：是。本卡只覆盖 macOS 单平台 smoke。

重要说明：

> 创建本卡本身不等于已实现。后续实现必须严格按本卡执行；如果发现本卡不足以覆盖目标，必须暂停并另开或扩展 execution card。

## 1. Authority

本轮唯一 authority：

- [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)

其他治理文档只作为背景约束，不能把本卡授权范围扩展成：

- 正式 runtime API
- 通用 UI update queue
- 多窗口系统
- Scene / Renderer
- Widget / Layout / DSL
- 跨平台抽象

## 2. Goal

本卡授权的未来唯一目标：

- 在 `labs/macos_bridge_smoke` 内部实现一个单实例 main-thread lifecycle queue first slice，让自动关闭、人工关闭和未来 async close 都能汇入同一条主线程关闭路径。

第一刀建议只支持 lifecycle message：

- `RequestClose`

第一刀不支持：

- 通用 UI update message
- target update message
- redraw / invalidate message
- 多窗口 target message
- public handle message
- Agent action message

成功标准：

- close request 先 enqueue / post，再由主线程 drain。
- drain 只发生在主线程 event-loop adapter 内。
- 关闭路径仍然幂等。
- stale close message 被安全丢弃，不能复活已关闭窗口。
- `cjgui_app_run()` 仍返回 `0`。

## 3. Scope

本卡允许的未来实现范围：

- 只在 `labs/macos_bridge_smoke` 的 bridge 内部增加最小 queue / post / drain 机制。
- queue 只服务当前单窗口、单实例 smoke。
- message type 只允许 lifecycle message，优先 `RequestClose`。
- enqueue 入口只允许：
  - bridge 内部受控 post。
  - 实验 C ABI，且仅当后续实现确实需要外部触发 close smoke 验证。
- drain 只允许由主线程 event-loop adapter 执行。
- 自动关闭 timer 和人工关闭入口必须转成同一类 close request。
- `last_error` 只能继续作为实验期观察口。

本卡明确不做：

- 不支持通用 UI update。
- 不支持多窗口。
- 不支持 public handle。
- 不实现 handle table / generation。
- 不暴露正式 public runtime API。
- 不设计 Scene / Renderer / Widget / Layout / DSL。
- 不接入 Agent action / Action Router。
- 不把 message queue 宣称为正式 runtime。

## 4. Write Set

本卡授权的未来实现允许修改：

- [cjgui_macos.m](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m)
- [cjgui_macos.h](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h)，仅当实验 C ABI 或内部声明必须调整时
- [main.cj](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj)，仅当实验 C ABI 验证必须调整时
- [macos_bridge_smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)，仅记录 smoke 行为和验证日志
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- future closure review 文档

本卡授权的未来实现禁止触碰：

- `/Users/jiangxuanyang/cangjie-toolchains/cangjie`
- 系统 SDK symlink
- `reference_repos/`
- `sources/`
- 正式框架核心目录，例如 `src/gui`、`src/runtime`、`src/widgets`
- 公共 Widget / DSL / cross-platform backend 设计文件
- 文本、输入法、无障碍相关实现
- AI semantic tree / Action Router 相关实现

本轮创建 execution card 时允许修改：

- 本 execution card
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)，仅用于入口链接

本轮创建 execution card 时禁止修改：

- `labs/macos_bridge_smoke`
- 任何运行时代码

## 5. Truth / Projection

未来 first slice 的真相层：

- close request 是否已被 post / enqueue。
- close request 是否由主线程 drain。
- lifecycle state 是否按 `alive -> close_requested -> closing -> destroyed -> event_loop_exited` 前进。
- stale close message 是否被安全丢弃。
- destroy 是否只执行一次。

本轮只是投影 / read surface 的部分：

- 终端日志。
- debug counter。
- `last_error`。
- smoke README。
- closure review。

投影不得反向发明更大能力。例如日志里出现 `message queue`，不等于项目已经拥有正式 async UI runtime。

## 6. Invariants

未来实现必须守住：

- drain 只能在 macOS 主线程执行。
- 后台线程 / 仓颉协程不得直接写 GUI 资源。
- message payload 不允许携带平台对象裸指针。
- `RequestClose` 必须进入生命周期状态机，不能直接释放平台对象。
- 自动关闭、人工关闭、未来 async close 必须汇入同一条关闭路径。
- destroy 必须幂等。
- stale message 必须安全丢弃，不能复活已关闭窗口。
- `last_error` 不能升级为并发错误系统。
- 不新增正式 public runtime API。
- 不支持 target update message，除非另开或扩展 execution card 并同步实现最小 handle / generation validation。

禁止进入 message payload 的对象包括：

- `NSWindow*`
- `NSView*`
- `NSEvent*`
- `CAMetalLayer*`
- `id<MTLDevice>`
- `MTLCommandQueue`
- Objective-C `id`
- 任何 AppKit / Metal / Objective-C 平台对象裸指针

## 7. Handle Table / Generation Decision

本卡不授权实现 handle table / generation。

原因：

- 当前仍是单窗口、单实例 smoke。
- 当前没有 public handle。
- 当前没有多窗口。
- 当前没有 target update。
- 当前 first slice 只处理 app / window lifecycle close request。
- 过早引入 handle table 会把 first slice 扩成正式 runtime 架构。

约束：

- 如果后续要支持 target update message，必须另开或扩展 execution card。
- target update message 必须同步实现最小 handle / generation validation。
- 没有 handle / generation validation 时，不得宣称支持通用异步 UI 更新。

## 8. Enqueue / Drain Boundary

### 8.1 Enqueue

允许：

- bridge 内部受控 post。
- 实验 C ABI，仅用于 smoke 验证，且不得被文档写成正式 public runtime API。

禁止：

- 后台线程直接触碰 `NSWindow` / `NSView` / `CAMetalLayer`。
- 仓颉层持有或传递平台对象。
- Renderer / Widget / Agent action 拥有旁路 queue。
- 为 demo 增加绕过 main-thread owner 的 fast path。

### 8.2 Drain

drain 必须只由主线程 event-loop adapter 执行。

drain 必须：

- 确认当前在主线程。
- 读取 pending lifecycle message。
- 校验 lifecycle state。
- 执行或丢弃 close request。
- 记录日志证据。

drain 禁止：

- 从后台线程执行。
- 在 destroy 不可重入区间递归执行。
- 在对象已 destroyed 后访问平台对象。

## 9. Lifecycle Race Rules

自动关闭、人工关闭、未来 async close 必须共享状态机：

```text
alive
-> close_requested
-> closing
-> destroyed
-> event_loop_exited
```

规则：

- 第一个 close request 赢得关闭权。
- 后续 close request 必须幂等处理。
- 如果 target 已 `closing`，close request 是 no-op。
- 如果 target 已 `destroyed`，close request 作为 stale message 丢弃。
- stale message 不得访问平台对象。
- stale message 不得重新创建 window / view / layer。
- event loop 已退出后，enqueue 必须失败、拒绝或被安全忽略。

## 10. Error Boundary

`last_error` 只能作为实验期观察口。

不得把 `last_error` 变成并发错误系统，原因：

- 它是全局状态。
- 它无法绑定 request id / message id。
- async drain 可能晚于 enqueue 发生。
- 多条 message 的错误会互相覆盖。
- 多线程读写会制造新的竞态。

未来 first slice 的错误处理口径：

- 非主线程 drain：fatal。
- queue 已关闭后 enqueue：recoverable。
- stale close message：recoverable 或 silent stale drop。
- destroy 重入：recoverable no-op，除非发现内部不变量破坏。
- handle / generation 相关错误：本卡不覆盖。

## 11. Fallout Scan Targets

未来实现完成前必须检查：

- 公共 API：不得新增正式 public runtime API。
- 事件流：自动关闭和人工关闭是否都进入 queue / drain。
- 状态流：是否只有一条 lifecycle state truth。
- 渲染流：不能引入 redraw / invalidate update queue。
- 平台桥接：平台对象是否仍只存在于 bridge 内部。
- 视觉 / 交互：窗口仍能显示并关闭；本卡不要求自动视觉验证。
- 文档 / 示例：README 只能描述 smoke 能力，不得宣称正式 runtime。
- 测试：必须有日志断言证明 enqueue / drain / close / destroy / exit。

## 12. Verification

未来实现必须执行自动关闭日志断言。

建议命令：

```zsh
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

允许实现时调整日志措辞，但必须至少证明：

- enqueue / post close request。
- main-thread drain。
- close requested。
- destroy complete。
- event loop exited。
- `cjgui_app_run()` 返回 `0`。

建议 red check：

- 实现前运行上述断言，应因缺少 queue / drain 相关日志失败。

必须说明无法验证的内容：

- 真实多线程压力。
- handle generation。
- 多窗口。
- target update message。
- 自动视觉验证 / pixel diff。
- Agent action 或 runtime async update。

对应残留风险：

- first slice 只能证明 lifecycle close message 的主线程回流。
- first slice 不能证明通用 async UI update。
- first slice 不能支撑多窗口或 public handle。
- first slice 不能替代未来自动视觉验证。

## 13. Stop-Line

本轮 stop-line：

- 本轮只创建 execution card。
- 不实现 message queue。
- 不修改 `labs/macos_bridge_smoke` 代码。
- 不设计正式 Scene / Renderer。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本、输入法、无障碍。
- 不做 AI semantic tree / Action Router。
- 不把当前 smoke demo 宣称为正式 runtime。
- 不把 execution card 写成无限授权；只能授权一个 bounded implementation slice。

未来实现 stop-line：

- 只允许单实例 lifecycle queue first slice。
- 只允许 `RequestClose` 这类 lifecycle message。
- 不允许通用 UI update。
- 不允许 target update。
- 不允许 public runtime API。
- 不允许平台对象进入 message payload。
- 不允许跳过主线程 drain。
- 不允许没有 handle / generation validation 却宣称支持 target async update。

## 14. Closure

未来 bounded implementation 完成后必须创建 closure review：

- `2026-04-25-p1-main-thread-ui-message-queue-closure-review.md`

closure review 必须回答：

- landed code reality 是什么。
- 是否真的只有单实例 lifecycle queue。
- 自动关闭和人工关闭是否走同一条关闭路径。
- 日志断言是否通过。
- main-thread drain 是否有证据。
- stale close message 如何处理。
- stop-line 是否守住。
- 哪些能力仍未实现。

需要同步的账本：

- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [labs/macos_bridge_smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)，仅当未来实现确实改变 smoke 行为或日志

## 15. Handoff

后续执行 AI 在开始实现前必须重新读取：

- 本 execution card。
- [2026-04-25-p1-main-thread-ui-message-queue-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-preflight.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)

执行口径：

> 做一个极窄的单实例 lifecycle queue，让 close request 经由主线程 post / drain 进入已有关闭路径。除此之外都不做。
