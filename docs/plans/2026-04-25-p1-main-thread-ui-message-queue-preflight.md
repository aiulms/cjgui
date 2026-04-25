# P1 Main-thread UI Message Queue Preflight

日期：2026-04-25

性质：docs-only / main-thread boundary preflight / P1 runtime foundation  
状态：完成；不批准直接实现  
范围：冻结未来后台任务、Agent action、runtime 异步更新 UI 时如何回到 macOS 主线程的规则。

## 1. 背景

当前已经完成：

- [P0 macOS bridge smoke](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)。
- [P1 AppKit / Metal bridge boundary cleanup](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)。

当前代码已经证明：

- 仓颉可以通过 C ABI 调用 Objective-C / AppKit / Metal。
- smoke 可以创建窗口、进入 macOS event loop、完成 Metal 首帧并退出。
- AppKit / Metal 对象仍只停留在 bridge 内部。

但当前仍没有：

- 主线程 UI message queue。
- 跨线程 UI 更新入口。
- handle table / generation table。
- 多窗口生命周期模型。
- 正式 Scene / Renderer / Widget / Layout。

因此下一步不能直接让后台任务、Agent action 或 runtime 异步逻辑写 UI。必须先冻结：

> 所有非主线程意图如何被转换成可验证、可丢弃、不会泄露平台对象的主线程 UI message。

## 2. Authority

本轮 authority：

- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)

本 preflight 只冻结规则。

它不是：

- execution card
- approval gate
- implementation authorization
- runtime API design approval

## 3. 当前代码现实

当前现实仍是单窗口 smoke：

```text
仓颉 main.cj
-> C ABI: cjgui_app_run()
-> Objective-C bridge context
-> NSApplication / NSWindow / CJGuiMetalView / CAMetalLayer / Metal
```

当前 bridge 内部已有最小生命周期防线：

- `bridge init`
- `capability check`
- `window created`
- `metal setup complete`
- `first frame rendered`
- `close requested`
- `destroy complete`
- `event loop exited`

当前 `last_error` 是实验期全局观察口：

- `cjgui_last_error_code()`
- `cjgui_last_error_category()`
- `cjgui_last_error_message()`

这些都不构成长期并发 runtime。

## 4. 本轮要冻结什么

本轮冻结未来 message queue 的边界：

1. UI message queue 的 owner。
2. 允许 enqueue 的入口。
3. drain 的唯一 owner。
4. drain 在主线程 event loop 中的时机。
5. message payload 允许携带什么。
6. message payload 禁止携带什么。
7. 平台对象是否允许进队列。
8. window / view / handle 已销毁后的 stale message 处理。
9. handle table / generation 的必要性和当前不做的原因。
10. 自动关闭、人工关闭、未来 async message 如何避免生命周期竞态。
11. 为什么 `last_error` 不能扩展成长期并发错误系统。

## 5. Owner / Truth / Projection

### 5.1 UI message queue owner

未来 UI message queue 的 owner 必须是：

> macOS bridge runtime 的主线程 UI owner。

更具体地说：

- 队列由 bridge / runtime 在主线程初始化时创建和持有。
- 队列不是后台任务的所有物。
- 队列不是 Agent action 的所有物。
- 队列不是 Scene / Renderer / Widget 的所有物。
- 队列不由任意 C callback 自行创建。

当前 smoke 还没有正式 runtime，因此可以先把未来 owner 描述为：

```text
MainThreadUiOwner
  -> owns queue
  -> owns handle validation
  -> owns drain
  -> owns platform resource mutation
```

在当前实验代码里，这个 owner 对应的是 bridge context 的未来职责，而不是一个已经存在的正式模块名。

### 5.2 真相层

message queue 的真相不是 UI 状态树，也不是渲染结果。

本层真相是：

- 某条异步 UI 意图是否已经被接收。
- 它目标的 app / window / view handle 是否仍然 alive。
- 它是否属于当前 generation。
- 它是否被执行、合并、丢弃或拒绝。
- drain 是否发生在主线程。

### 5.3 投影层

下面这些只是投影或观察面：

- 日志。
- debug counter。
- future frame stats。
- `last_error`。
- demo README。

投影不能反向定义执行真相。

## 6. 哪些入口可以 enqueue

未来允许 enqueue 的入口必须是受控入口。

允许的入口类型：

1. 受控 C ABI 函数。
   - 例如未来可能出现的 `cjgui_enqueue_*`。
   - 只能接收脱水后的 message 数据。
   - 必须复制或接管 payload 的所有权。

2. bridge 内部的受控 post。
   - 用于把内部生命周期事件归一化到同一条主线程路径。
   - 例如自动关闭 timer 触发的 close request。

3. future runtime scheduler 的受控出口。
   - 用于 runtime 异步任务把 UI 更新意图提交给主线程。
   - scheduler 只能提交框架 message，不能直接触碰 AppKit / Metal。

4. future Agent action adapter 的受控出口。
   - Agent action 只能生成框架命令或脱水 message。
   - Agent action 不能持有平台对象。
   - Agent action 不能绕过 handle validation。

禁止的入口：

- 后台线程直接调用 `NSWindow` / `NSView` / `CAMetalLayer`。
- 仓颉协程直接写平台资源。
- 任意外部 C callback 直接塞入未经校验的指针。
- Renderer / Widget 自己拥有一条旁路 UI 队列。
- 为某个 demo 单独开一条不受 owner 管理的 fast path。

原则：

> enqueue 是提交意图，不是获得平台对象操作权。

## 7. 哪个模块负责 drain

未来 drain 的唯一 owner 必须是：

> macOS bridge runtime 的 main-thread event-loop adapter。

职责：

- 在主线程读取队列。
- 校验 message 类型。
- 校验目标 handle / generation / lifecycle state。
- 丢弃 stale message。
- 合并可合并的 redraw / invalidate message。
- 调用 bridge 内部平台资源更新函数。
- 记录 recoverable / degraded / fatal 的结果。

禁止：

- 后台线程 drain。
- Agent action drain。
- Renderer worker drain。
- 仓颉业务协程 drain。
- 从任意非主线程回调里直接 drain。

如果未来有跨平台后端，macOS 的 drain 规则也不能自动升级成公共跨平台抽象。必须先有单独 preflight。

## 8. drain 必须发生在主线程的哪个时机

drain 必须发生在 macOS 主线程，并且只能发生在 bridge 认可的 event loop 时机。

推荐未来时机：

```text
macOS main run loop turn
-> accept platform event / lifecycle event
-> drain queued UI messages on main thread
-> validate handles and lifecycle state
-> schedule redraw / apply platform mutations
-> render / present when needed
```

更具体的约束：

- `NSApplication` 初始化和 event loop 必须已经在主线程。
- drain 不能发生在后台线程。
- drain 不能在 destroy 持有不可重入状态时递归执行。
- drain 不能在平台对象已进入释放过程后继续执行普通 UI 更新。
- drain 应优先放在一次主线程 run loop tick 内的确定位置。
- redraw / present 之前必须先处理影响本帧的有效 UI message。
- close / destroy 相关 message 必须进入生命周期状态机，而不是直接释放对象。

未来实现可以选择：

- `dispatch_async(dispatch_get_main_queue(), ...)`
- `CFRunLoopSource`
- AppKit timer / event-loop hook

但无论使用哪种机制，都必须满足：

> message 的实际执行只发生在主线程 bridge owner 内部。

## 9. 消息结构允许携带什么

message payload 必须是脱水、可复制、可校验的数据。

允许携带：

- message type enum。
- target kind，例如 app / window / view / surface。
- opaque handle value。
- generation value，如果目标可复用。
- sequence number 或 request id，用于日志和 future diagnostics。
- 小型标量数据：
  - `Bool`
  - `Int32` / `UInt64`
  - `Float32` / `Float64`
  - width / height / scale factor
  - color / clear value
  - invalidation flags
- 拥有所有权的短字符串或 debug label。
- 拥有所有权的不可变 bytes，前提是长度有上限且释放路径明确。
- 可序列化的框架命令，例如 future `RequestCloseWindow(handle)` 或 `InvalidateWindow(handle, rect)`。

推荐基础形状：

```text
CjguiUiMessage {
  type
  target_kind
  target_handle
  target_generation
  sequence
  payload_kind
  payload
}
```

这只是形状建议，不是本轮批准的 ABI。

## 10. 消息结构不允许携带什么

禁止携带：

- `NSWindow*`
- `NSView*`
- `NSEvent*`
- `CAMetalLayer*`
- `id<MTLDevice>`
- `MTLCommandQueue`
- Objective-C `id`
- C / Objective-C 对象的裸指针。
- 借用的栈内存指针。
- 没有明确释放 owner 的 heap pointer。
- 捕获平台对象的 closure。
- 任意可变共享状态引用。
- 未设大小上限的大块二进制 payload。
- 平台枚举原样透传。
- 未经翻译的原生事件。

尤其禁止把平台对象放进队列，再期望主线程稍后解释它。

原因：

- 对象可能在 drain 前已销毁。
- 原生对象生命周期不受仓颉 GC 管理。
- 平台对象会把 AppKit / Metal 偶然性泄露到上层。
- 异步队列会放大悬垂指针和二次释放风险。

结论：

> message queue 不运送平台对象，只运送框架意图。

## 11. 是否允许携带平台对象

默认不允许。

唯一可接受的例外是 bridge 内部的同步临时变量：

- 只在主线程当前调用栈内存在。
- 不进入跨线程队列。
- 不越过 bridge 内部边界。
- 不暴露给仓颉层。

即使未来平台事件来自 `NSEvent`，也必须先在 bridge 内部翻译成脱水事件，例如：

```text
WindowCloseRequested(handle, generation)
WindowResized(handle, generation, width, height, scale)
RedrawRequested(handle, generation)
```

不得把 `NSEvent*` 当成 message payload。

## 12. stale message 处理

stale message 指：

- target handle 不存在。
- target handle 已 `closing`。
- target handle 已 `destroyed`。
- message generation 与当前 handle generation 不一致。
- app 正在退出，普通 UI 更新已不再接受。
- message 到达时目标 view / window / surface 已释放。

处理规则：

- drain 时必须先验证 handle / generation / lifecycle state。
- 普通 UI update message 遇到 stale target 必须丢弃。
- 丢弃 stale message 不得复活 window / view / surface。
- 丢弃 stale message 不得访问任何平台对象。
- 可以记录 debug log 或 counter。
- 对外应归类为 recoverable 或 silent stale drop，不能升级成 fatal。
- 如果发现 generation 冲突或 handle table 内部不变量损坏，才升级为 fatal。

close / destroy 类 message 需要更严格：

- 对 alive target：进入 close requested / closing。
- 对 closing target：幂等 no-op。
- 对 destroyed target：幂等 no-op 或 recoverable `already_destroyed`。
- 对 unknown handle：recoverable `invalid_handle`。

## 13. 是否需要 handle table / generation

长期需要。

原因：

- 异步 message 可能晚于 window destroy 到达。
- 旧 handle 可能误命中新创建对象。
- 多窗口必须区分目标对象。
- Agent action / runtime async update 都可能跨 event loop tick。
- 仅靠裸整数或全局单实例状态无法证明 message target 仍有效。

未来只要满足任一条件，就必须实现最小 handle table / generation：

- message 可以指定 window / view / surface target。
- 支持多窗口。
- 允许 worker / Agent / runtime 异步提交 UI action。
- handle 会被仓颉层或上层 runtime 持有超过一次同步调用。

当前不做 handle table / generation，原因是：

- 本轮是 docs-only preflight，不写运行时代码。
- 当前 smoke 仍是单窗口、单实例、同步 `cjgui_app_run()`。
- 还没有正式 public handle API。
- 还没有 Scene / Renderer / Widget 目标对象。
- 现在过早设计完整 handle table 会反向逼出正式 runtime 架构。

但是边界必须写清：

> 下一轮如果真的实现可异步投递到具体 UI target 的 message queue，就必须同时实现最小 handle validation；否则只能做不带 target 的单实例内部 lifecycle queue，不能宣称支持通用异步 UI 更新。

## 14. 自动关闭、人工关闭、未来 async message 的生命周期竞态

三类入口必须汇入同一条生命周期状态机：

```text
alive
-> close_requested
-> closing
-> destroyed
-> event_loop_exited
```

### 14.1 自动关闭

自动关闭 timer 不能直接释放平台对象。

它只能提交或触发：

```text
RequestClose(app/window)
```

然后由主线程 lifecycle owner 处理。

### 14.2 人工关闭

人工点击关闭按钮也不能走另一条释放路径。

它必须翻译成同一类：

```text
WindowCloseRequested(handle, generation)
```

然后进入同一个 `close_requested -> closing -> destroyed` 流程。

### 14.3 future async message

future async message 到达时必须先看 lifecycle state：

- `alive`：允许执行有效 UI update。
- `close_requested`：只允许生命周期相关 message，普通 update 丢弃或拒绝。
- `closing`：停止接收普通 target message。
- `destroyed`：全部 target message stale drop。
- `event_loop_exited`：队列不再 drain，enqueue 必须失败或被拒绝。

### 14.4 竞态防守规则

防守规则：

- 第一个 close request 赢得关闭权。
- 关闭流程必须幂等。
- close request 一旦生效，应停止接收新的普通 UI update。
- in-flight redraw 必须在主线程 owner 内被完成或丢弃。
- destroy 必须只执行一次。
- destroy 前必须取消 timer / redraw callback / future wakeup source。
- destroy 后不得再访问 `NSWindow`、`NSView`、`CAMetalLayer` 或 Metal resources。
- pending message 不得让已销毁对象复活。

## 15. FFI last_error 不能变成长期并发错误系统

当前 `last_error` 只适合单实例 smoke 的调试观察。

它不能扩展成长期并发错误系统，原因：

- 它是全局状态，会被后续调用覆盖。
- 它无法可靠归属到某个 request id / message id / handle / generation。
- 多线程调用时存在读写竞态。
- async message 的失败可能发生在 enqueue 之后很久，调用者读 `last_error` 时已经不是同一件事。
- 它不能表达队列中多条 message 的多个结果。
- 它不能表达 per-window / per-action diagnostics。
- 字符串生命周期和所有权容易再次变成 FFI 边界风险。
- 它鼓励调用者用“最后一次错误”推断系统真实状态，这是错误的真相模型。

未来长期方向：

- 同步 FFI 调用返回 `CjguiStatus` 或等价结构。
- 异步 enqueue 返回 request id / accepted status。
- drain 结果进入受控 diagnostics channel、debug log 或 future completion surface。
- fatal / recoverable / degraded 必须保留结构化分类。

`last_error` 可以继续作为实验期观察口，但不得成为 async runtime 的并发错误协议。

## 16. 错误分类

### 16.1 Fatal

应视为 fatal：

- handle table 内部不变量破坏。
- generation reuse 导致旧 message 命中新对象。
- bridge 状态机进入不可能状态。
- detect 到可能二次释放平台对象。
- 非主线程 drain 被触发。

### 16.2 Recoverable

应视为 recoverable：

- enqueue 时 target handle 无效。
- drain 时 message 已 stale。
- app 已退出，无法接受新 message。
- message payload 参数非法。
- queue 已关闭。

### 16.3 Degraded

可视为 degraded：

- debug diagnostics channel 不可用。
- message stats / tracing 不可用。
- future 自动化视觉验证路径不可用。

## 17. 未来最小实现边界建议

如果后续获得批准，第一轮实现仍应非常窄。

允许考虑：

- 单实例 bridge 内部 queue。
- 仅支持 lifecycle message，例如 `RequestClose`。
- 主线程 drain。
- stale drop 日志。
- 不对外暴露 public handle。

如果要支持 target update message，则必须同时支持：

- handle validation。
- generation validation。
- lifecycle state validation。
- enqueue failure status。

不允许为了“先跑通”绕过这些校验。

## 18. 验证策略

本轮 docs-only 验证：

- 新文档必须能从 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md) 找到。
- 新文档必须能从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。
- 新文档必须能从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。
- 不修改 `labs/macos_bridge_smoke`。
- 不新增运行时代码。

后续 implementation 验证必须另写 execution card。

## 19. Stop-line

本轮强制 stop-line：

- 不实现 message queue。
- 不修改 `labs/macos_bridge_smoke` 代码。
- 不设计正式 Scene / Renderer。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本、输入法、无障碍。
- 不做 AI semantic tree / Action Router。
- 不把当前 smoke demo 宣称为正式 runtime。

额外保持：

- 不把平台对象放进公共 message payload。
- 不把 `last_error` 升级为长期并发错误系统。
- 不用当前单实例 smoke 伪称已支持通用 async UI 更新。

## 20. 结论

本 preflight 完成后，当前结论是：

- UI message queue 的 owner 必须是主线程 bridge runtime owner。
- enqueue 只能来自受控入口，且只能提交脱水后的框架意图。
- drain 只能由主线程 event-loop adapter 执行。
- drain 必须在主线程 event loop 的确定时机发生，不能由后台任务触发。
- message payload 默认不允许携带平台对象。
- stale message 必须在 drain 前校验并安全丢弃。
- 长期 async UI 更新需要 handle table / generation。
- 当前不实现 handle table / generation，因为本轮不写代码，且当前仍是单实例 smoke。
- 自动关闭、人工关闭、future async message 必须共享同一条生命周期状态机。
- `last_error` 只能继续作为 smoke 观察口，不能成为长期并发错误协议。

下一步不自动进入实现。

如果继续推进实现，必须先创建单独 execution card，并明确：

- write set
- 是否只做单实例 lifecycle queue
- 是否引入最小 handle / generation validation
- enqueue / drain ABI 形状
- stale drop 验证方式
- 生命周期竞态验证方式
