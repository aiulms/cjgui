# P1 Platform Adapter Boundary Execution Card

日期：2026-04-26

类型：docs-only execution card

状态：完成；创建本卡本身不等于实现；不自动开启 runtime implementation

## 0. Authority

本卡的唯一 authority 是：

- [2026-04-26-p1-platform-adapter-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-preflight.md)

本卡只把 platform adapter boundary preflight 收束成受限 execution card。它不写 runtime 代码，不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不定义 public runtime API 或 public C ABI。

## 1. Future First Slice Scope

未来 first slice 最多只能做：

- comment-only / documentation-level surface refinement。
- 更清楚地记录 platform adapter owner。
- 更清楚地记录 app lifecycle relation。
- 更清楚地记录 window lifecycle relation。
- 更清楚地记录 platform object ownership stays internal。
- 更清楚地记录 dehydrated facts to core。
- 更清楚地记录 forbidden facts to core。
- 更清楚地记录 main-thread ownership boundary。
- 更清楚地记录 smoke bridge relation。
- 更清楚地记录 error boundary / `last_error` non-migration。
- 更清楚地记录 no platform runloop truth in core。
- 更清楚地记录 no default frame scheduler / global tick。

未来 first slice 不允许：

- 实现 platform adapter。
- 实现 app lifecycle / event loop / queue / drain。
- 实现 window lifecycle / window create / close / destroy。
- 定义 public runtime API。
- 定义 public C ABI。
- 新增 package / build config。
- 迁移 smoke code。
- 复用 smoke C ABI。
- 暴露 AppKit / Metal / Objective-C platform objects。
- 让 core 持有 `NSRunLoop`、`NSEvent`、`dispatch_main` 或 Objective-C callback truth。
- 引入 default global tick / blind redraw / frame scheduler。
- 进入 Renderer / Scene / Widget / Layout / DSL。
- 打开 Text / Input / IME / Accessibility。
- 实现 semantic tree / Action Router。
- 实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 创建 `CJGUI_TRUTH_MANIFEST.md`。

## 2. Future Write Set

未来 first slice 的最大 write set 仅限：

- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- future closure review under `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/`
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未来 first slice 不得写非注释仓颉语法。

未来 first slice 不得创建 build config。

未来 first slice 不得定义稳定函数签名、public API 或 public C ABI。

未来 first slice 可以轻量更新 `runtime/cjgui/README.md` 的 platform adapter boundary section，但不得把 README 写成 API contract、package guide 或 implementation spec。

## 3. Future Forbidden Write Set

未来 first slice 禁止修改：

- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
- public runtime API
- public C ABI
- native bridge
- Renderer / Scene / Widget / Layout / DSL
- Dirty Rect / global tick / frame scheduler
- Text / Input / IME / Accessibility
- semantic tree / Action Router
- command-list hash / pixel diff / baseline / offscreen renderer
- `CJGUI_TRUTH_MANIFEST.md`

## 4. Surface Boundary To Clarify

未来 first slice 只能强化以下注释边界。

### Platform Adapter Owner

future platform adapter owner 属于 `runtime/cjgui` platform adapter module。

它可以在 adapter / bridge 内部拥有：

- platform event loop truth。
- platform callback truth。
- platform main-thread execution truth。
- platform object ownership。
- platform readiness / failure observation。

它不拥有：

- core app lifecycle policy。
- core window lifecycle target state。
- public runtime API。
- Renderer / Scene / Widget / Layout。
- Text / Input / IME / Accessibility。

### App Lifecycle Relation

platform adapter 可以驱动 core app lifecycle，但 core app lifecycle 只能消费脱水 lifecycle facts。

允许表达的 future relation：

```text
platform adapter owns platform runloop / callbacks / main-thread execution
platform adapter emits dehydrated lifecycle facts
core app lifecycle consumes dehydrated facts and owns policy
core app lifecycle never owns platform runloop truth
```

### Window Lifecycle Relation

platform adapter 可以持有平台窗口对象并输出脱水 window facts；core window lifecycle 只拥有 window target state 和 stale / destroyed classification。

允许表达的 future relation：

```text
platform adapter owns platform window objects
platform adapter emits dehydrated window facts
core window lifecycle owns target state and stale / destroyed classification
core window lifecycle never owns platform object identity
```

### Platform Object Ownership Stays Internal

platform adapter 可以在内部持有 AppKit / Metal / Objective-C 平台对象，但不得泄露到 core public surface。

禁止把以下对象作为 core truth、public API、public C ABI、字段、参数、返回值或长期 identity：

- `NSWindow`
- `NSView`
- `CAMetalLayer`
- `MTLDevice`
- `MTLCommandQueue`
- `NSEvent`
- Objective-C `id`
- `CGImageRef`
- raw pointer
- native handle

### Dehydrated Facts To Core

future adapter 只允许向 core 交付脱水 facts 候选，例如：

- lifecycle facts。
- platform readiness / failure facts。
- queue drain request / result facts。
- quit request / close request facts。
- window state facts。
- future input facts。
- future frame / redraw facts。

这些候选 facts 不是 API，不是实现，也不承诺 frame scheduler、input system 或 redraw system。

### Forbidden Facts To Core

future adapter 不应向 core 交付：

- platform object pointer。
- AppKit / Metal object ownership。
- raw event object。
- raw `NSEvent`。
- Objective-C callback ownership。
- runloop truth。
- delegate identity。
- dispatch queue identity。
- native handle。
- smoke diagnostics fields as runtime truth。

### Main-thread Ownership Boundary

future boundary 必须保持：

- platform adapter owns platform main-thread execution。
- app lifecycle owns app-level queue acceptance policy。
- window lifecycle owns window target state transitions。
- error strategy classifies failures。

本卡不授权 queue / drain implementation。

### Smoke Bridge Relation

smoke bridge 提供经验，不提供直接可迁移 API。

可迁移的是约束：

- macOS UI 必须有主线程 owner。
- 平台对象必须留在 bridge / adapter 内部。
- close / destroy 必须受控。
- platform failure 必须可观察、可分类。
- smoke guard 可以继续保护旧链路不退化。

不能迁移的是：

- `labs/macos_bridge_smoke` 目录结构。
- smoke build script。
- smoke C ABI。
- smoke `cjgui_app_run()`。
- smoke `last_error` global shape。
- smoke single-instance global state。
- smoke diagnostics fields。

### Error Boundary / `last_error` Non-migration

smoke `last_error` 只能迁移为“future adapter 需要错误边界”的经验。

future adapter error boundary 应倾向：

- call-associated。
- structured。
- non-global。
- concurrency-safe。
- 能表达 platform readiness / failure。
- 能表达 platform object create / release failure。

本卡不定义 concrete error type，也不修改 `runtime/cjgui/src/error.cj`。

### No Platform Runloop Truth In Core

core runtime 不允许持有或暴露：

- `NSRunLoop`
- `NSEvent`
- `dispatch_main`
- Objective-C callback truth
- AppKit delegate identity
- platform event object
- platform object pointer
- native handle

这些词在 future comment-only refinement 中只能作为禁止事项或 adapter 内部边界出现，不能成为 API 或实现。

### No Default Frame Scheduler / Global Tick

future adapter 可以登记 expose / resize / visibility / scale / surface invalidation 等脱水 facts 候选。

这些 facts 不得自动变成：

- default global tick。
- blind redraw。
- frame scheduler。
- Dirty Rect implementation。
- Renderer / Scene entry。

任何 redraw / Dirty Rect / frame scheduling 都必须另开 preflight。

## 5. Future Verification Requirements

未来 first slice 至少需要验证：

- 如果修改 `.cj`，必须检查 `.cj` 是否仍为 comment-only。
- 必须检查未新增 package / build config。
- 必须检查没有 smoke C ABI reference。
- 必须检查没有 platform object / raw pointer public surface。
- 必须检查 `NSRunLoop` / `NSEvent` / `dispatch_main` / AppKit / Metal / Objective-C 只作为禁止事项或 adapter 内部边界出现在注释中，不能作为 API 或实现。
- 必须运行 `git diff --check`。
- 必须检查 closure review 可从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 和 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。
- 如果 future slice 仍 comment-only，应记录：`Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.`
- 如可行，future slice 应运行现有 smoke guard：`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。

## 6. Stop-line For This Card Creation

本轮创建 execution card 的强制 stop-line：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 platform adapter。
- 不实现 app lifecycle / event loop / queue / drain。
- 不实现 window lifecycle / window create / close / destroy。
- 不实现 handle table / generation。
- 不迁移 smoke code。
- 不复用 smoke C ABI。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 7. Current Next Opening

本卡之后的 next opening 建议更新为：

> `P1 platform adapter surface comment-only refinement first slice`

该 opening 不自动开启实现。只有用户明确批准后，未来 first slice 才能在本卡授权范围内做极窄 comment-only / documentation-level surface refinement。
