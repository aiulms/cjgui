# P1 App Lifecycle Surface Comment-only Refinement Closure Review

日期：2026-04-26

性质：closure review / comment-only bounded implementation first slice

状态：完成

对应 execution card：

- [2026-04-26-p1-app-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-execution-card.md)

唯一 authority：

- [2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)

## 1. Landed Reality

本轮只完成 `P1 app lifecycle surface comment-only refinement first slice`。

落地内容：

- 在 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 中补清 app lifecycle future slot 的 comment-only 边界。
- 在 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md) 中补充 app lifecycle surface boundary 小节。
- 没有实现真实 runtime behavior。
- 没有定义 public runtime API。
- 没有新增 package / build config。
- 没有修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。

本轮写入仍是 boundary clarification，不是 runtime implementation。

## 2. Actual Write Set

实际修改文件：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

未修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`
- native bridge
- harness
- 仓颉 smoke 入口

## 3. App Lifecycle Comment Boundary

[runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 现在只以注释记录：

- app lifecycle owner。
- platform adapter relation。
- future `run` slot。
- future `shutdown` slot。
- future `request quit` slot。
- main-thread queue / drain conceptual owner。
- no platform runloop truth in core。
- no default global tick / blind redraw。
- error strategy relation。
- window lifecycle boundary relation。

这些仍不是函数、类型、模块 API、package entry 或 runtime behavior。

## 4. Comment-only Check

检查命令：

```zsh
awk 'NF && $1 !~ /^\/\// { print FILENAME ":" FNR ":" $0; bad=1 } END { exit bad }' runtime/cjgui/src/app_lifecycle.cj
```

结果：

- 退出码：`0`
- 未发现任何非注释仓颉语法。

本轮记录：

```text
Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.
```

没有为了验证而创建 package / build config。

## 5. Package / Build Config Check

检查命令：

```zsh
find runtime -maxdepth 4 \( -name 'cjpm.toml' -o -name 'package.json' -o -name 'CMakeLists.txt' -o -name 'Makefile' -o -name '*.toml' \) -print | sort
```

结果：

- 退出码：`0`
- 无输出。
- 未新增 package / build config。

## 6. Smoke C ABI / Platform Surface Check

smoke C ABI identifier 检查命令：

```zsh
rg -n 'cjgui_app_run|cjgui_last_error|cjgui_app_|cjgui_window_|cjgui_macos' runtime/cjgui
```

结果：

- 未发现匹配。
- runtime skeleton 没有引用 smoke C ABI identifier 作为 public API 或实现。

platform object / raw pointer public surface 检查命令：

```zsh
rg -n 'NSWindow\*|NSView\*|CAMetalLayer\*|MTLDevice\*|CGImageRef|void\*|UnsafePointer|CPointer|COpaquePointer|id<' runtime/cjgui
```

结果：

- 未发现匹配。
- 未暴露 platform object / raw pointer public surface。

`NSRunLoop` / `NSEvent` / `dispatch_main` 检查结果：

- 这些词只作为禁止事项出现在 comment-only `.cj` 注释和 README 边界说明中。
- 没有作为 API、字段、函数参数、类型或实现出现。

## 7. Smoke Guard Result

执行命令：

```zsh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

日志路径：

```text
/tmp/cjgui-p1-auto-close-verify.log
```

结果：

- 退出码：`0`
- `cjgui verify: auto-close log assertions passed`
- `Cangjie: cjgui_app_run returned 0`

该 smoke guard 只证明旧 smoke 链路未因本轮 comment-only runtime surface refinement 退化；它不是正式 runtime test framework。

## 8. Forbidden File Check

本轮前后复核以下 forbidden 文件 hash：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`

结果：

```text
forbidden hash check: OK
```

说明：工作区在本轮开始前已有 `labs/macos_bridge_smoke` 的未提交 / 未跟踪状态；本轮通过 hash 对比确认没有继续修改这些 forbidden 文件。

## 9. Stop-line Review

已守住：

- 未实现 app lifecycle / event loop / run / shutdown / queue / drain。
- 未实现 window lifecycle / window create / close / destroy。
- 未实现 handle table / generation。
- 未定义 public runtime API。
- 未新增 package / build config。
- 未引用或调用 smoke C ABI identifier。
- 未暴露 platform object / raw pointer public surface。
- 未修改 `labs/macos_bridge_smoke`。
- 未修改 harness、native bridge 或仓颉入口。
- 未进入 Renderer / Scene / Widget / Layout / DSL。
- 未进入 Dirty Rect / global tick / frame scheduler。
- 未进入 Text / Input / IME / Accessibility。
- 未进入 semantic tree / Action Router。
- 未进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## 10. Residual Risks

仍未完成：

- app lifecycle 仍只有 comment-only boundary。
- 没有 runtime package / build entry。
- 没有真实 app lifecycle owner 实现。
- 没有 main-thread queue / drain implementation。
- 没有 platform adapter implementation。
- 没有 window lifecycle surface 进一步冻结。
- 没有 structured runtime error type。
- 没有正式 runtime tests。

这些 residual 不阻塞本轮 closure，因为本轮唯一目标是 comment-only surface refinement。

## 11. Current Next Opening

当前不自动开启下一轮实现。

推荐下一条 docs-only opening：

> `P1 app lifecycle surface closure / window lifecycle surface boundary preflight`

用途：

- 复核 app lifecycle surface comment-only refinement 是否足以封账。
- 判断下一条边界是否应转向 window lifecycle surface。
- 继续禁止真实 runtime behavior、package / build config、public API、Renderer / Scene / Widget / Layout / DSL、global tick、Text / Input / IME / Accessibility、semantic tree、pixel diff、baseline 和 offscreen renderer。
