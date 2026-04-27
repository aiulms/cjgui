# P1 Window Lifecycle Surface Comment-Only Refinement Closure Review

日期：2026-04-26

## Authority

唯一 authority：

- [2026-04-26-p1-window-lifecycle-surface-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-execution-card.md)

本轮执行：

- `P1 window lifecycle surface comment-only refinement first slice`

## Landed Reality

本轮只完成 window lifecycle surface 的 comment-only / documentation-level refinement。

落地事实：

- `runtime/cjgui/src/window_lifecycle.cj` 仍是 comment-only。
- `runtime/cjgui/README.md` 只补充 window lifecycle surface boundary。
- 未写任何非注释仓颉语法。
- 未定义稳定函数签名。
- 未定义 public runtime API。
- 未新增 package / build config。
- 未实现 window lifecycle、window create、request close、destroy 或 release。
- 未实现 app lifecycle、event loop、main-thread queue 或 drain。
- 未实现 handle table / generation。
- 未实现多窗口、target update 或 async UI message targeting。
- 未引用或调用 smoke C ABI。
- 未暴露 platform object / raw pointer public surface。

## Write Set

实际修改文件：

- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Surface Clarified

`window_lifecycle.cj` 只用注释补清这些 future slots：

- window lifecycle owner。
- app lifecycle relation。
- platform adapter relation。
- create window slot。
- request close slot。
- destroy / release slot。
- stale message / destroyed window handling slot。
- single-window first slice。
- handle table / generation future trigger。
- error strategy relation。
- no platform object exposure。

`runtime/cjgui/README.md` 同步补充 window lifecycle surface boundary，说明它不是 public runtime API，也不是 runtime behavior。

## Verification

### Comment-Only Check

命令：

```bash
awk 'NF && $1 !~ /^\/\// { print FILENAME ":" FNR ":" $0; bad=1 } END { exit bad }' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj
```

结果：

- 退出码：`0`
- `window_lifecycle.cj` 仍为 comment-only。

### Package / Build Config Check

命令：

```bash
find /Users/jiangxuanyang/Desktop/cangjie/runtime -maxdepth 5 \( -name 'cjpm.toml' -o -name 'package.json' -o -name 'CMakeLists.txt' -o -name 'Makefile' -o -name '*.toml' \) -print | sort
```

结果：

- 退出码：`0`
- 未发现新增 package / build config。

### Cangjie Build Check

结果：

- `Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.`

### Smoke C ABI Reference Check

命令：

```bash
rg -n 'cjgui_app_run|cjgui_last_error|cjgui_app_|cjgui_window_|cjgui_macos' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
```

结果：

- 退出码：`1`
- 未发现 runtime skeleton 引用 smoke C ABI。

### Platform Object / Raw Pointer Check

命令：

```bash
rg -n 'NSWindow\*|NSView\*|CAMetalLayer\*|MTLDevice\*|CAMetalDrawable\*|CGImageRef|void\*|UnsafePointer|CPointer|COpaquePointer|id<' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
```

结果：

- 相关平台对象 / raw pointer 名称只在注释或 README 中作为禁止事项、platform adapter 内部边界出现。
- 未作为 API、字段、参数、返回值或实现出现。

### AppKit / Metal / Objective-C Term Check

命令：

```bash
rg -n 'NSWindow|NSView|CAMetalLayer|MTLDevice|CAMetalDrawable|CGImageRef|Objective-C|AppKit|Metal' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md
```

结果：

- AppKit / Metal / Objective-C 相关词只作为禁止事项或 platform adapter 内部边界出现在注释 / README 中。
- 未成为 core runtime API 或实现。

### Smoke Guard

命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- 退出码：`0`
- 日志路径：`/tmp/cjgui-p1-auto-close-verify.log`
- 旧 smoke guard 仍通过，包含 auto-close assertions passed。
- smoke guard 仍只是旧链路 guard，不是正式 runtime test framework。

### Forbidden File Check

本轮先记录 forbidden 文件 hash baseline，再在修改后复核。

结果：

- `forbidden_hash_check=OK`
- `labs/macos_bridge_smoke`、harness、native bridge、仓颉 smoke 入口、build script、auto-close harness、其他 runtime skeleton 文件未被本轮修改。

## Stop-Line Review

已守住：

- 未写 runtime 行为代码。
- 未写非注释仓颉语法。
- 未新增 package / build config。
- 未定义 public runtime API。
- 未实现 window lifecycle / window create / request close / destroy / release。
- 未实现 app lifecycle / event loop / queue / drain。
- 未实现 handle table / generation。
- 未实现多窗口 / target update / async UI message targeting。
- 未修改 `labs/macos_bridge_smoke`。
- 未修改 harness、native bridge 或仓颉入口。
- 未引用或调用 smoke C ABI。
- 未暴露 platform object / raw pointer public surface。
- 未实现 Renderer / Scene / Widget / Layout / DSL。
- 未实现 Dirty Rect / global tick / frame scheduler。
- 未实现 Text / Input / IME / Accessibility。
- 未实现 semantic tree / Action Router。
- 未实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## Residual Risks

- window lifecycle 仍只是 comment-only surface，不是实现。
- `create window` / `request close` / `destroy` / `release` 仍没有 runtime behavior。
- request close 与 app lifecycle queue / drain 的真实协作仍未实现。
- stale message / destroyed target classification 仍只是 future boundary。
- handle table / generation 仍未打开；未来 public handle、多窗口、target update 或 async UI message targeting 出现前必须另开边界。
- platform adapter 仍没有真实实现。
- structured error strategy 仍未实现。
- runtime 仍没有 package / build config，仓颉 build check 暂不适用。

## Current Next Opening

当前 next opening 建议更新为 docs-only：

`P1 window lifecycle surface closure / platform adapter boundary preflight`

该 opening 只用于复核 window lifecycle surface comment-only refinement 是否足以封账，并冻结下一条 platform adapter boundary。它不自动开启 runtime implementation。
