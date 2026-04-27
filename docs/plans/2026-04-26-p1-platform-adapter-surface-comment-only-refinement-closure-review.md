# P1 Platform Adapter Surface Comment-Only Refinement Closure Review

日期：2026-04-26

## Authority

- [2026-04-26-p1-platform-adapter-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-execution-card.md)

本轮唯一 authority 是上述 execution card。

## Landed Reality

本轮完成了 `P1 platform adapter surface comment-only refinement first slice`。

实际落地只做 comment-only / documentation-level refinement：

- `runtime/cjgui/src/platform_adapter.cj` 仍为 comment-only。
- `runtime/cjgui/README.md` 只补充 platform adapter boundary section。
- 未实现 platform adapter。
- 未实现 event loop / callback binding。
- 未定义 public runtime API。
- 未定义 public C ABI。
- 未新增 package / build config。
- 未迁移 smoke code。
- 未复用 smoke C ABI。

## Actual Write Set

- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Surface Clarified

`platform_adapter.cj` 只用注释补清了这些 future slots：

- platform adapter owner。
- app lifecycle relation。
- window lifecycle relation。
- platform object ownership stays internal。
- dehydrated facts to core。
- forbidden facts to core。
- main-thread ownership boundary。
- smoke bridge relation。
- error boundary / `last_error` non-migration。
- no platform runloop truth in core。
- no default frame scheduler / global tick。

`runtime/cjgui/README.md` 同步补充了 platform adapter / core boundary：

- adapter 可在未来内部持有 AppKit / Metal / CoreGraphics / Objective-C 平台对象。
- core runtime 只接收脱水 facts。
- core 不持有 `NSRunLoop`、`NSEvent`、`dispatch_main`、AppKit delegate truth、Objective-C callback truth、native handle 或 raw event object。
- smoke bridge 只提供经验，不提供可直接迁移的 API。
- platform adapter surface 不打开 global tick、blind redraw、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree、command-list hash、pixel diff、baseline 或 offscreen renderer。

## Verification

### Comment-Only Check

命令：

```sh
awk 'NF && $1 !~ /^\/\// { print FILENAME ":" FNR ":" $0; bad=1 } END { exit bad }' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj
```

结果：退出码 `0`，`platform_adapter.cj` 仍为 comment-only。

### Package / Build Config Check

命令：

```sh
find /Users/jiangxuanyang/Desktop/cangjie/runtime -maxdepth 5 \( -name 'cjpm.toml' -o -name 'package.json' -o -name 'CMakeLists.txt' -o -name 'Makefile' -o -name '*.toml' \) -print | sort
```

结果：退出码 `0`，无输出，未新增 package / build config。

### Smoke C ABI Reference Check

命令：

```sh
rg -n 'cjgui_app_run|cjgui_last_error|cjgui_app_|cjgui_window_|cjgui_macos' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
```

结果：无匹配。runtime skeleton 未引用具体 smoke C ABI symbol 作为 API 或实现。

### Platform Object / Raw Pointer Check

命令：

```sh
rg -n 'NSWindow\*|NSView\*|CAMetalLayer\*|MTLDevice\*|CAMetalDrawable\*|MTLCommandQueue\*|CGImageRef|void\*|UnsafePointer|CPointer|COpaquePointer|id<' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
```

结果：只发现既有 comment / README 中的禁止事项或 platform adapter 内部边界说明；未出现 platform object / raw pointer public surface。

### Platform Term Boundary Check

命令：

```sh
rg -n 'NSRunLoop|NSEvent|dispatch_main|AppKit|Metal|Objective-C|NSWindow|NSView|CAMetalLayer|MTLDevice|MTLCommandQueue|CGImageRef' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md
```

结果：相关词只作为禁止事项或 adapter 内部边界出现在 comment-only `.cj` 文件和 README 中，未作为 API 或实现出现。

### Smoke Guard

命令：

```sh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：退出码 `0`，日志路径 `/tmp/cjgui-p1-auto-close-verify.log`，auto-close log assertions passed。

### Forbidden File Check

本轮先记录 forbidden file hash baseline，再在修改后复核。运行 smoke guard 会重建 `labs/macos_bridge_smoke/build/` 下的生成物，因此 source / harness 级 forbidden check 排除了 `build/` 产物：

```sh
grep -v '/build/' /tmp/cjgui-platform-adapter-refinement-forbidden-before.sha256 > /tmp/cjgui-platform-adapter-refinement-forbidden-controlled-before.sha256
grep -v '/build/' /tmp/cjgui-platform-adapter-refinement-forbidden-after.sha256 > /tmp/cjgui-platform-adapter-refinement-forbidden-controlled-after.sha256
diff -u /tmp/cjgui-platform-adapter-refinement-forbidden-controlled-before.sha256 /tmp/cjgui-platform-adapter-refinement-forbidden-controlled-after.sha256
```

结果：退出码 `0`，forbidden source / harness 文件 hash 未变化。

### Cangjie Build Check

未运行 Cangjie build。

原因：

`Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.`

## Stop-Line Review

本轮守住：

- 未写 runtime 行为代码。
- 未写非注释仓颉语法。
- 未新增 package / build config。
- 未定义 public runtime API。
- 未定义 public C ABI。
- 未实现 platform adapter。
- 未实现 app lifecycle / event loop / queue / drain。
- 未实现 window lifecycle / window create / close / destroy。
- 未实现 handle table / generation。
- 未迁移 smoke code。
- 未复用或调用 smoke C ABI。
- 未修改 `labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 未暴露 AppKit / Metal / Objective-C platform objects。
- 未实现 Renderer / Scene / Widget / Layout / DSL。
- 未实现 Dirty Rect / global tick / frame scheduler。
- 未实现 Text / Input / IME / Accessibility。
- 未实现 semantic tree / Action Router。
- 未实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## Residual Risks

- platform adapter 仍未实现。
- app / window lifecycle 仍只是 comment-only skeleton。
- main-thread queue / drain 仍未实现。
- platform object hiding 仍只是边界声明，尚无 runtime enforcement。
- error strategy 仍未冻结。
- runtime package / build boundary 仍未打开。
- smoke guard 仍只是旧链路验证，不是正式 runtime test framework。

## Current Next Opening

建议下一步仍为 docs-only：

`P1 platform adapter surface closure / error strategy boundary preflight`

该 opening 只应复核 platform adapter surface 是否足以封账，并冻结 error strategy boundary；不自动开启 runtime implementation。
