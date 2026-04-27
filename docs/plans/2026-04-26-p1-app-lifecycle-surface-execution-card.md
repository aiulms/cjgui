# P1 App Lifecycle Surface Execution Card

日期：2026-04-26

类型：execution card / docs-only authorization card

状态：完成；创建本卡本身不等于实现；不自动开启 runtime implementation

## 0. Authority

本卡的唯一 authority 是：

- [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)

本卡只把 future first slice 收束为极窄的 comment-only / documentation-level surface refinement authorization。任何实现仍必须由后续明确 opening 执行；本卡不写 runtime 代码，不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`。

## 1. Architect Sign-off Status

当前状态：

- 本卡创建本身：docs-only，允许。
- future implementation：未自动批准。
- future first slice：只有在用户明确要求执行 `P1 app lifecycle surface comment-only refinement first slice` 后，才能按本卡执行。

本卡不授权：

- 真实 app lifecycle implementation。
- `run` / `shutdown` / `request quit` implementation。
- main-thread queue / drain implementation。
- public runtime API。
- package / build config。

## 2. Future First Slice Goal

future first slice 的唯一目标：

> 只把 app lifecycle surface 的 comment-only boundary 写得更清楚。

允许的具体形式只能是二选一或同时做很小范围：

- 只在 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 中强化 comment-only future slot 注释。
- 只在 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 中补充 app lifecycle surface section。

future first slice 不得把 comment-only surface refinement 解释成 runtime behavior。

## 3. Future First Slice Scope

future first slice 只允许强化以下 future slots 的注释边界：

- app lifecycle owner。
- platform adapter relation。
- `run` slot。
- `shutdown` slot。
- `request quit` slot。
- main-thread queue / drain conceptual owner。
- no platform runloop truth in core。
- no global tick default。
- error strategy relation。
- window lifecycle boundary relation。

这些内容仍只是 future slot / boundary note，不是 API，不是实现，不是 buildable runtime surface。

## 4. Future Maximum Write Set

future first slice 最大允许 write set：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- future closure review under `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

任何 future first slice 都不得为了“顺手补清楚”触碰其他 runtime files。尤其不得修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`

除非另开新的 execution card。

## 5. This Card Creation Write Set

本轮创建本卡只允许修改：

- 新建 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md`
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- 更新 `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- 如有必要，轻量更新 `/Users/jiangxuanyang/Desktop/cangjie/README.md`

本轮创建本卡不得修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`
- harness
- native bridge
- 仓颉入口

## 6. Future Forbidden Write Set

future first slice 禁止修改：

- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- screenshot / frame hash harness
- native bridge
- public C ABI / public runtime API
- package / build config
- Renderer / Scene / Widget / Layout / DSL
- Dirty Rect / global tick / frame scheduler
- Text / Input / IME / Accessibility
- semantic tree / Action Router
- command-list hash / pixel diff / baseline / offscreen renderer
- `CJGUI_TRUTH_MANIFEST.md`

## 7. Public API Boundary

future first slice 不允许定义 public runtime API。

禁止内容：

- 稳定函数签名。
- 稳定 type / class / struct / enum。
- 可被 example 或外部代码依赖的 public surface。
- public C ABI。
- buildable package entry。

如果 future first slice 修改 `.cj` 文件，则该文件必须仍为 comment-only。不得写任何非注释仓颉语法。

## 8. AppKit / Platform Truth Boundary

future first slice 不允许把以下内容写进 core runtime truth：

- `NSRunLoop`
- `NSEvent`
- `dispatch_main`
- Objective-C callback truth
- AppKit delegate callback identity
- native handle
- raw pointer
- platform object identity

允许出现这些词的唯一场景：

> 作为注释中的禁止事项或边界说明。

例如可以写：

```text
// core app lifecycle must not hold NSRunLoop truth.
```

不得写成 API、函数参数、类型、字段、实现或 stable contract。

## 9. App Lifecycle Slot Boundary

future first slice 可补充注释，但不得实现：

### app lifecycle owner

只能说明：

- owner 属于 `runtime/cjgui` core app lifecycle module。
- owner 持有脱水 app lifecycle state。
- owner 不属于 smoke bridge。
- owner 不持有 platform runloop truth。

### platform adapter relation

只能说明：

- platform adapter owns platform runloop / callback facts。
- platform adapter emits dehydrated lifecycle facts。
- core app lifecycle consumes dehydrated facts。
- core app lifecycle does not own platform runloop truth。

### `run` slot

只能说明：

- `run` 是 future slot。
- blocking / pump / step / adapter-driven 语义未冻结。
- `run` 不是 AppKit runloop alias。
- `run` 不是 default global tick。
- `run` 不隐式创建 window。

### `shutdown` slot

只能说明：

- `shutdown` 是 future terminal transition slot。
- shutdown 后 late message 必须丢弃或分类。
- shutdown 未来需要幂等 contract。
- shutdown 不直接释放 platform object。

### `request quit` slot

只能说明：

- `request quit` 是 app-level request slot。
- manual quit、future async quit、platform close-all request 应汇入同一 lifecycle path。
- request 不等于 immediate destroy。

### main-thread queue / drain conceptual owner

只能说明：

- policy owner 倾向 app lifecycle。
- platform main-thread execution owner 属于 platform adapter / bridge。
- queue payload 必须脱水。
- drain 不能在后台线程执行。

### error strategy relation

只能说明：

- app lifecycle 会产生 wrong thread、platform readiness failure、late message、invalid state 等错误场景。
- concrete error type 不在本 slice。
- smoke `last_error` 不能直接迁移。

### window lifecycle relation

只能说明：

- app lifecycle 不拥有 window target identity。
- stale handle / destroyed window / handle generation 属于 window lifecycle / future handle table。
- app lifecycle 可定义 app-level queue acceptance 和 shutdown terminal policy。

## 10. No Global Tick / Self-drawn Guardrails

future first slice 必须继续吸收 self-drawn guardrails：

- 不允许 default global tick。
- 不允许 blind redraw。
- 不允许 frame scheduler。
- 不允许把 `run` 写成 render loop。
- 不允许暗中打开 Dirty Rect / invalidation system。
- 不允许暗中打开 Text / Input / IME / Accessibility。
- 不允许把自绘解释为可以忽略 platform adapter、IME cursor rect sync 或 accessibility semantic bridge。

如需 redraw / invalidation / animation frame scheduling，必须另开 preflight。

## 11. Handle Table / Generation Boundary

future first slice 不允许进入 handle table / generation。

原因：

- app lifecycle 不拥有 target identity。
- 当前无 public handle。
- 当前无 multi-window routing。
- 当前无 async target update。
- 当前只允许 comment-only app lifecycle surface refinement。

一旦 future opening 允许 public window handle、multi-window、target update 或 async target UI message，必须另开 window lifecycle / handle table / generation preflight 或 execution card。

## 12. Truth / Projection

future first slice 的真相层：

- 只有文档化的 app lifecycle surface boundary。
- 不是 runtime state truth。
- 不是 platform runloop truth。
- 不是 public API truth。

future first slice 的 projection：

- `.cj` 注释和 README section 只是说明 future surface 的边界。
- closure review 只是审计和封账。

不得制造第二真相源。

## 13. Future Verification Requirements

future first slice 必须验证：

- 如果修改 `.cj`，检查 `.cj` 是否仍为 comment-only。
- 检查未新增 package / build config。
- 检查没有 smoke C ABI reference。
- 检查没有 platform object / raw pointer public surface。
- 检查没有 `NSRunLoop` / `NSEvent` / `dispatch_main` 作为 API 或实现；这些词只能作为禁止事项出现在注释。
- 检查没有稳定函数签名 / public API。
- 检查没有 Renderer / Scene / Widget / Layout / DSL。
- 检查没有 Dirty Rect / global tick / frame scheduler。
- 检查没有 Text / Input / IME / Accessibility。
- 检查没有 semantic tree / Action Router。
- 检查没有 command-list hash / pixel diff / baseline / offscreen renderer。
- 检查 closure review 可从 `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md` 和 `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md` 找到。
- 运行 `git diff --check`。

如果 future first slice 仍只写 comment-only `.cj` 和 README：

```text
Cangjie build check not applicable yet: no runtime package/build entry by design; modified .cj files remain comment-only.
```

不得为了验证而创建 package / build config。

## 14. Future Closure Review Requirements

future closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 是否修改 `.cj`。
- `.cj` 是否仍 comment-only。
- 是否写了非注释仓颉语法。
- 是否新增 package / build config。
- 是否定义 public runtime API。
- 是否引用 smoke C ABI。
- 是否暴露平台对象或 raw pointer。
- 是否把 `NSRunLoop` / `NSEvent` / `dispatch_main` 写成 API 或实现。
- 是否引入 default global tick / blind redraw / frame scheduler。
- 是否打开 Text / Input / IME / Accessibility。
- 是否进入 Renderer / Scene / Widget / Layout / DSL。
- 是否进入 handle table / generation。
- 是否进入 semantic tree / Action Router。
- 是否进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 验证命令和结果。
- stop-line 是否守住。
- 当前 next opening。

## 15. Stop-line For This Card Creation

本轮创建 execution card 的强制 stop-line：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不实现 app lifecycle / event loop / run / shutdown / queue / drain。
- 不实现 window lifecycle / window create / close / destroy。
- 不实现 handle table / generation。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 16. Next Opening

本卡之后的下一条 opening 建议为：

> `P1 app lifecycle surface comment-only refinement first slice`

该 opening 不自动开启实现。

如果用户明确批准执行，它也只能按本卡做极窄 comment-only / documentation-level refinement，不能进入真实 runtime behavior。
