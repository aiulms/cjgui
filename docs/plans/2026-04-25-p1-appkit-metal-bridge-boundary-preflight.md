# P1 AppKit / Metal 桥接边界清理 Preflight

日期：2026-04-25

性质：docs-only / platform boundary preflight / P1 runtime foundation  
状态：完成，可进入下一轮 execution card  
范围：冻结 macOS 单平台 AppKit / Metal 桥接边界，不实现 Scene / Renderer / Widget。

## 1. 背景

P0 已经完成：

- 仓颉 SDK、`cjc`、`cjpm`、`libffi` 和 `MacOSX15.4.sdk` 已验证。
- [cffi_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/cffi_smoke) 已证明仓颉可以调用本地 C 静态库。
- [macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke) 已证明仓颉可以经 C ABI 调用 Objective-C / AppKit / Metal。
- 自动关闭模式已验证事件循环能进入、窗口能关闭、`cjgui_app_run()` 能返回 `0`。
- 人工视觉检查已确认出现青色 / 深青色 Metal 清屏窗口。

因此 P1 之前最重要的问题不是继续堆功能，而是回答：

> 这条桥接链路怎样从 smoke demo 变成可长期承载框架底座的受控边界？

## 2. Authority

本轮 authority：

- [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)

## 3. 当前代码现实

当前代码只是一条 smoke 链路：

```text
仓颉 main.cj
-> C ABI: cjgui_app_run()
-> Objective-C / AppKit / Metal
-> NSWindow + CAMetalLayer + Metal clear
```

这条链路已经证明可行，但还不具备正式运行时边界：

- 没有稳定 handle 模型。
- 没有明确资源销毁顺序。
- 没有主线程消息队列。
- 没有结构化错误返回。
- 没有 capability query。
- 没有自动化视觉验证闭环。
- 没有 Scene / Renderer 输入。

P1 必须先清理这些底层边界，不能直接从 P0 smoke 跳到 Element tree 或 Widget API。

## 4. P1 要冻结什么

P1 只冻结 macOS 桥接边界的规则：

1. FFI handle 生命周期。
2. AppKit / Metal 对象所有权。
3. UI 主线程 owner。
4. 后台任务回到 UI 主线程的消息路径。
5. FFI 错误分类和返回方式。
6. 桥接层向上暴露的极窄接口。
7. Metal capability query 的预留位置。
8. 构建链从零复现规则。
9. GUI 验证从人工视觉走向自动化的路径。

P1 不冻结最终 GUI 框架 API。

## 5. 三层判断

### 5.1 Ingress

当前入口层仍然只能是实验入口：

- 仓颉 smoke `main.cj`
- C ABI 函数
- 构建脚本
- 运行命令

入口层不能发明正式公共 API。

禁止在 P1 中引入：

- `App { }`
- `Window { }`
- `Button`
- `Element`
- `Widget`
- 声明式 DSL
- 跨平台 `Renderer` 抽象

### 5.2 Execution

P1 的执行 owner 是 macOS bridge 层。

它负责：

- 创建 `NSApplication` / `NSWindow` / `NSView`
- 创建和持有 `CAMetalLayer`
- 创建和持有 Metal device / command queue / transient command buffer
- 进入和退出 macOS event loop
- 接收未来主线程消息队列中的 UI 更新请求
- 翻译平台事件，不把平台对象向上泄露

### 5.3 Truth

P1 的真相不是 UI 状态树。

P1 的真相是：

- 每个 bridge handle 当前是否存在。
- 每个 handle 是否处于 `alive` / `closing` / `destroyed` 状态。
- 平台对象是否由 bridge 层持有并按顺序释放。
- 当前平台能力是否满足 Metal 绘制最低要求。
- 运行时错误属于 `fatal` / `recoverable` / `degraded` 哪一类。

仓颉层看到的只能是这个真相的受控投影。

## 6. FFI handle 生命周期

P1 推荐采用不透明 handle，不允许仓颉层长期持有裸平台指针语义。

推荐规则：

- Objective-C / AppKit / Metal 对象只能由 bridge 层创建。
- 仓颉层只能持有整数或 opaque token 形式的 `CjguiHandle`。
- `CjguiHandle` 不能等价于 `NSWindow*`、`NSView*` 或 `CAMetalLayer*`。
- bridge 层维护 handle table，并记录 handle generation，防止旧 handle 误操作新对象。
- 所有 public C ABI 都必须校验 handle 是否存在、是否 alive、是否属于当前 generation。

推荐生命周期：

```text
create
-> alive
-> closing
-> destroyed
```

销毁顺序必须固定：

1. 停止 timer / display link / redraw callback。
2. 停止接收新的 UI 消息。
3. 标记 handle 为 `closing`。
4. 完成或丢弃当前 in-flight draw。
5. 释放 Metal transient resources。
6. 释放 command queue / device 引用。
7. 从 view 上 detach `CAMetalLayer`。
8. 关闭并释放 `NSWindow` / `NSView`。
9. 从 handle table 移除或标记为 `destroyed`。

重复 destroy 不能造成二次释放。

建议语义：

- 对已 `destroyed` handle 再次 destroy，返回 `recoverable` 的 `already_destroyed`。
- 对未知 handle 操作，返回 `recoverable` 的 `invalid_handle`。
- 对 handle table 损坏、generation 冲突等不变量破坏，升级为 `fatal`。

## 7. 主线程 owner 与消息队列

macOS bridge 必须默认遵守：

> AppKit、窗口生命周期、UI 事件循环和 Metal layer 相关操作归主线程 owner。

P1 规则：

- `NSApplication` 初始化和 event loop 必须在主线程。
- `NSWindow` / `NSView` / `CAMetalLayer` 创建、修改、销毁必须在主线程。
- 后台线程 / 仓颉协程不得直接写 GUI 资源。
- 未来任何后台任务更新 UI，都必须投递到主线程消息队列。

推荐未来消息路径：

```text
background task / agent / worker
-> thread-safe queue
-> main thread drain
-> bridge owner validates handle
-> platform resource update
```

P1 不需要实现完整消息队列，但下一轮实现若新增任何跨线程入口，必须先有 execution card 并明确：

- 谁可以 enqueue。
- 谁负责 drain。
- drain 发生在 event loop 哪个时机。
- 消息携带的数据是否需要 copy。
- handle 销毁后未处理消息如何丢弃。

## 8. 错误处理哲学

P1 采用三类错误哲学。

### 8.1 Fatal

不可恢复，不能伪装成可继续运行。

例子：

- handle table 内部不变量破坏。
- 同一平台对象被检测到二次释放风险。
- bridge 层内部状态机进入不可能状态。
- 内存破坏、segfault 等进程级错误。

处理原则：

- fail fast。
- 写清楚日志。
- 不承诺同进程优雅恢复。
- 若未来必须隔离不可控崩溃，应考虑进程隔离，而不是在 GUI 主进程内假装可恢复。

### 8.2 Recoverable

调用失败，但进程仍可继续。

例子：

- 创建窗口失败。
- `MTLCreateSystemDefaultDevice()` 返回空。
- command queue 创建失败。
- handle 无效。
- config 参数非法。
- drawable 暂时不可用。

处理原则：

- 返回结构化错误。
- 不静默吞掉。
- 不把 recoverable 错误升级成随机崩溃。

### 8.3 Degraded

能力缺失或环境限制导致降级，但核心进程仍可运行。

例子：

- 自动截图不可用。
- 高刷新率不可用。
- 某些可选 Metal feature 不可用。
- 未来某些视觉验证路径在当前机器上不可用。

处理原则：

- 明确报告 degraded reason。
- 不把降级当作成功完成全部能力。
- 不承诺 P1 实现软渲染 fallback。

## 9. FFI 返回形状建议

P1 不冻结最终 ABI，但下一轮 implementation 应避免只返回裸成功值。

最低建议：

```c
typedef enum CjguiErrorCategory {
    CJGUI_ERROR_NONE = 0,
    CJGUI_ERROR_FATAL = 1,
    CJGUI_ERROR_RECOVERABLE = 2,
    CJGUI_ERROR_DEGRADED = 3
} CjguiErrorCategory;

typedef struct CjguiStatus {
    int32_t code;
    CjguiErrorCategory category;
} CjguiStatus;
```

如果仓颉 FFI 对结构体返回不方便，允许先采用：

```c
int32_t cjgui_last_error_code(void);
int32_t cjgui_last_error_category(void);
const char* cjgui_last_error_message(void);
```

但这只是实验期折中，不得升级为长期公共契约，除非后续 preflight 再批准。

## 10. 桥接层向上暴露的窄接口

桥接层可以厚，但向上接口必须窄。

允许向上暴露的类型形状：

- `CjguiHandle`
- `CjguiStatus`
- `CjguiWindowConfig`
- `CjguiSize`
- `CjguiDpi`
- `CjguiPlatformEvent`
- `CjguiCapabilities`

禁止向上暴露：

- `NSWindow*`
- `NSView*`
- `NSEvent*`
- `CAMetalLayer*`
- `id<MTLDevice>`
- `MTLCommandQueue`
- AppKit / Metal 枚举原样透传

平台事件必须被翻译成脱水结构。

示例方向：

```text
WindowResized(width, height, scale_factor)
WindowCloseRequested(handle)
WindowClosed(handle)
RedrawRequested(handle)
```

P1 不要求完整事件模型，但禁止把 `NSEvent` 直接传给仓颉公共层。

## 11. Metal capability query

P1 必须预留 capability query 的位置。

第一阶段最小能力：

- 是否存在默认 `MTLDevice`。
- 是否能创建 command queue。
- 是否能创建 `CAMetalLayer`。
- 当前 pixel format 是否受支持。
- 当前 drawable size / scale factor 是否可读。

能力缺失时：

- 不直接崩溃。
- 返回 `recoverable` 或 `degraded`。
- 日志说明缺失能力。
- 不承诺软渲染 fallback。

`120fps` 是长期愿景，不是 capability query 的默认承诺。

## 12. 构建链复现

P1 后续实现必须继续遵守：

- 不修改系统 `MacOSX.sdk` symlink。
- 继续显式使用 `MacOSX15.4.sdk`。
- 继续通过脚本设置 `CJ_GUI_SDKROOT` / `SDKROOT`。
- 任何 `clang` / `cjc` / `cjpm` / Metal 编译参数变化，都必须同步检查 [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)。

当前 `BUILD_FROM_ZERO.md` 已覆盖 P0 smoke。

如果 P1 implementation 只清理 bridge 内部结构且命令不变，可以不改该文档；如果新增脚本、改路径或改参数，必须同步更新。

## 13. 验证策略

P1 后续 implementation 至少需要三类证据。

### 13.1 生命周期日志

必须能看到：

- bridge init
- window create
- metal setup
- first frame draw
- window close
- resource destroy
- event loop exit

### 13.2 自动关闭 smoke

继续保留：

```bash
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

自动关闭模式必须证明进程可退出。

### 13.3 视觉验证

当前自动截图仍有残留：

```text
could not create image from display
```

P1 不要求立刻解决截图权限问题，但必须保留后续路径：

- 可控截图。
- 离屏渲染。
- 像素快照。
- frame hash。
- render stats。

人工视觉确认可以继续作为补充证据，不能长期作为唯一证据。

## 14. 失败窗口

P1 后续实现的主要失败窗口：

- handle destroy 和 AppKit window close 顺序冲突。
- window 已关闭后仍有 redraw callback。
- 后台任务未来绕过主线程直接写 GUI 资源。
- Metal drawable 暂时不可用时被当成 fatal。
- bridge 为了“薄”而泄露 AppKit / Metal 对象。
- 自动关闭路径和人工关闭路径释放顺序不一致。
- 错误处理只返回 `0 / 1`，导致无法区分 recoverable 和 fatal。

这些都必须在下一轮 execution card 中作为检查项。

## 15. 下一轮建议 write set

下一轮如果进入 implementation，建议仍然限制在实验区：

允许：

- [labs/macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)
- [docs/plans](/Users/jiangxuanyang/Desktop/cangjie/docs/plans)
- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)，仅当构建命令或脚本发生变化时
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，仅做轻量补账

禁止：

- 新建正式 `src/gui` 框架核心
- 新建公共 Widget API
- 修改参考仓库
- 修改仓颉 SDK 安装目录
- 修改系统 SDK symlink
- 引入重型 GUI 框架依赖

## 16. Stop-line

P1 bridge boundary cleanup 不做：

- Scene / Renderer 正式实现
- Entity / Context
- Element tree
- Widget / Layout
- Text / Input / IME / Accessibility
- Clipboard / Drag and drop
- Multi-window
- Cross-platform backend
- AI semantic tree
- Action router
- IPC server
- 公共声明式 DSL

本轮目标只是把 macOS bridge 从“能跑”收紧到“可控”。

## 17. 结论

允许进入下一轮：

- `P1 AppKit/Metal bridge boundary cleanup execution card`

但不允许直接开始实现。

下一轮必须先填写执行卡，明确：

- write set
- 本轮 owner
- handle 生命周期实现范围
- 主线程规则实现范围
- 错误返回形状
- 验证命令
- stop-line

只有执行卡通过后，才允许修改 `labs/macos_bridge_smoke` 中的代码。
