# P1 Window Lifecycle Surface Execution Card

日期：2026-04-26

类型：execution card

状态：完成；创建本卡本身不等于实现；不自动开启 runtime implementation

## 0. Authority

本卡的唯一 authority 是：

- [2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-boundary-preflight.md)

本卡只把 future first slice 收束为一个极窄的 comment-only / documentation-level surface refinement authorization。创建本卡本身不写 runtime 代码，不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不新增 public runtime API，不创建 package / build config。

## 1. Future First Slice Scope

未来 first slice 最多只能做：

- 把 [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj) 的 comment-only window lifecycle surface boundary 写得更清楚。
- 或只补充 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 中的 window lifecycle surface section。
- 新建 future closure review。
- 更新 plans README 和 GUI task tracker。

未来 first slice 不能做：

- 不实现真实 window lifecycle。
- 不实现 `window create` / `request close` / `destroy` / `release`。
- 不实现 app lifecycle / event loop / queue / drain。
- 不定义 public runtime API。
- 不新增 package / build config。
- 不迁移 smoke 代码。
- 不修改 `labs/macos_bridge_smoke/`。

该 first slice 的正确形态是边界澄清，不是 runtime behavior。

## 2. Future Write Set

未来 first slice 允许的最大 write set：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- future closure review under `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

未来 first slice 如果不需要同时修改 `.cj` 和 README，应只改其中必要的一处。不得为了填满 write set 而扩写无意义内容。

## 3. Future Forbidden Write Set

未来 first slice 默认禁止修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- screenshot / frame hash harness
- native bridge
- public C ABI / public runtime API
- Renderer / Scene / Widget / Layout / DSL
- cross-platform backend
- Text / Input / IME / Accessibility
- semantic tree / Action Router
- command-list hash / pixel diff / baseline / offscreen renderer
- `CJGUI_TRUTH_MANIFEST.md`

## 4. Comment-only Rule

未来 first slice 如果修改 `.cj`，必须保持 `.cj` comment-only。

未来 first slice 不得：

- 写任何非注释仓颉语法。
- 定义稳定函数签名。
- 定义 public runtime API。
- 创建 build config。
- 创建 package config。
- 添加 example entry。
- 添加 test entry。
- 引用或调用 smoke C ABI。

如果 future slice 仍是 comment-only，应在 closure review 中记录：

```text
Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.
```

## 5. Future Surface Slots

未来 first slice 只能强化以下 future slots 的注释边界。

### Window Lifecycle Owner

必须继续表达：

- future owner 属于 `runtime/cjgui` core window lifecycle module。
- owner 只持有脱水 window lifecycle state。
- owner 不持有 AppKit / Metal / Objective-C 平台对象。
- owner 不拥有 Renderer / Scene / Widget / Layout。

### App Lifecycle Relation

必须继续表达：

- app lifecycle 负责 app-level queue acceptance / shutdown policy。
- window lifecycle 负责 window target state、request close、destroyed / stale target classification。
- request close 未来必须经过 app lifecycle / main-thread queue / drain 的 conceptual path。
- 本卡不授权实现 app lifecycle、queue 或 drain。

### Platform Adapter Relation

必须继续表达：

- platform adapter 负责 AppKit / Metal / Objective-C 平台对象和平台 callback truth。
- core window lifecycle 只接收脱水 window facts。
- AppKit / Metal / Objective-C 术语只能作为禁止事项或 platform adapter 内部边界出现在注释中。
- 这些术语不能作为 API、字段、类型、参数、返回值或实现。

### `create window` Slot

只能记录 future 语义：

- 提交或接受 window creation request。
- 绑定 window lifecycle state。
- platform adapter 未来在平台主线程上创建平台对象。
- core 未来只记录脱水 created / failed fact。

不得实现窗口创建，不得暴露 native handle，不得隐式创建 Renderer / Scene / Widget / Layout。

### `request close` Slot

只能记录 future 语义：

- 提交 window-level close request。
- 幂等地推进 close requested / closing state。
- 让 auto-close、manual close、future async close 汇入同一 close path。

不得实现 close path，不得直接释放 platform object，不得绕过 app lifecycle / main-thread queue / drain。

### `destroy` / `release` Slot

只能记录 future 语义：

- `destroy` 是 window lifecycle terminal transition 候选。
- `release` 是 platform adapter 内部释放平台对象后的脱水完成 fact。
- destroyed window 不得被 stale message 复活。

不得实现 destroy / release，不得暴露 raw pointer lifecycle，不得变成 public C ABI。

### Stale Message / Destroyed Window Handling Slot

只能记录 future 语义：

- stale close 不得重新进入 happy path。
- stale message 不得复活 destroyed window。
- destroyed 后 message 应安全丢弃或结构化分类。
- target identity validation 属于 future handle table / generation。

不得实现 stale message routing、target update 或 async UI message targeting。

### Single-window First Slice

必须继续表达：

- 第一阶段可以继续 single-window。
- single-window 只是 first slice 收窄，不是长期 runtime 限制。
- 多窗口会引入 routing、target identity、z-order / focus、destroyed target reuse 等额外问题，必须另开边界。

### Handle Table / Generation Future Trigger

必须继续表达：

- 当前不做 handle table / generation。
- 只有出现 public window handle、multi-window、target update、async UI message targeting、destroyed target identity reuse 或跨线程 target validation 时，才必须另开 handle table / generation preflight 或 execution card。

不得在本 future first slice 中实现 handle table / generation。

### Error Strategy Relation

必须继续表达：

- window lifecycle 只记录哪些场景需要 error / diagnostics。
- error strategy 必须未来保持调用关联、结构化、非全局、并发安全。
- smoke `last_error` 不能直接迁移为 runtime error system。

不得定义 concrete error type、public error API 或迁移 `last_error`。

### No Platform Object Exposure

必须继续表达 core window lifecycle 不允许暴露：

- `NSWindow`
- `NSView`
- `CAMetalLayer`
- `MTLDevice`
- `CAMetalDrawable`
- Objective-C `id`
- `CGImageRef`
- native handle
- raw pointer

平台对象只能是 platform adapter 内部事实，不能进入 core public surface。

## 6. Explicit Non-goals

未来 first slice 不允许：

- 实现真实 window lifecycle。
- 实现 window create / request close / destroy / release。
- 实现 app lifecycle / event loop / queue / drain。
- 定义 public runtime API。
- 新增 package / build config。
- 修改 `labs/macos_bridge_smoke/`。
- 暴露 AppKit / Metal / Objective-C 平台对象。
- 实现 handle table / generation。
- 实现多窗口。
- 实现 target update。
- 实现 async UI message targeting。
- 引入 default global tick。
- 引入 blind redraw。
- 引入 frame scheduler。
- 打开 Renderer / Scene / Widget / Layout / DSL。
- 打开 Text / Input / IME / Accessibility。
- 实现 semantic tree / Action Router。
- 实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 创建 `CJGUI_TRUTH_MANIFEST.md`。

## 7. Future Verification

未来 first slice 至少必须验证：

- 如果修改 `.cj`，检查 `.cj` 是否仍为 comment-only。
- 检查未新增 package / build config。
- 检查没有 smoke C ABI reference。
- 检查没有 platform object / raw pointer public surface。
- 检查 AppKit / Metal / Objective-C 只作为禁止事项或 platform adapter 内部边界出现在注释中，不能作为 API 或实现。
- 检查没有 `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice` / `CGImageRef` 等平台对象 public surface。
- 检查没有 handle table / generation implementation。
- 检查没有 multi-window / target update / async UI message targeting implementation。
- 检查没有 Renderer / Scene / Widget / Layout / DSL。
- 检查没有 Dirty Rect / global tick / frame scheduler。
- 检查没有 Text / Input / IME / Accessibility。
- 检查没有 semantic tree / Action Router。
- 检查没有 command-list hash / pixel diff / baseline / offscreen renderer。
- 运行 `git diff --check`。
- 检查 closure review 可从 `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md` 和 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md` 找到。

如果 future slice 仍 comment-only，不需要运行 Cangjie build，但 closure review 必须记录 build check 不适用原因：

```text
Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.
```

如可行，future slice 应运行现有 smoke guard：

```zsh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

该 smoke guard 只能证明旧 smoke 链路未退化，不是正式 runtime test framework。

## 8. Stop-line For This Card Creation

本轮创建 execution card 的强制 stop-line：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 window lifecycle / window create / request close / destroy / release。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 handle table / generation。
- 不实现多窗口 / target update / async UI message targeting。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。
- 不把 smoke demo 宣称为正式 GUI runtime。

## 9. Next Opening

本卡之后的下一条 opening 建议为：

> `P1 window lifecycle surface comment-only refinement first slice`

该 opening 不自动开启实现。它只能在用户明确批准后执行，并且必须严格遵守本卡 write set、forbidden write set、comment-only rule、verification 和 stop-line。
