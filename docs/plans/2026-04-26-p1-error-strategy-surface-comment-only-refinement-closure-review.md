# P1 Error Strategy Surface Comment-Only Refinement Closure Review

日期：2026-04-26

## Authority

- [2026-04-26-p1-error-strategy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-boundary-execution-card.md)

## Landed Reality

本轮完成 `P1 error strategy surface comment-only refinement first slice`。

- `runtime/cjgui/src/error.cj` 仍为 comment-only。
- `runtime/cjgui/README.md` 只扩展 error strategy surface boundary 文档。
- 未写任何 runtime behavior code。
- 未定义 public runtime API 或 public C ABI。
- 未定义 error enum、Result type、exception-like mechanism 或稳定函数签名。
- 未新增 package / build config。
- 未迁移 smoke `last_error`。
- 未复用 smoke C ABI。
- 未把 diagnostics 写成第二状态真相源。

## Actual Write Set

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Surface Clarified

`error.cj` 现在只用注释冻结以下 future slots：

- error strategy owner。
- app lifecycle relation。
- window lifecycle relation。
- platform adapter relation。
- smoke `last_error` non-migration。
- structured / call-associated / non-global / concurrency-safe future errors。
- fatal / recoverable / degraded / invalid usage / capability missing / stale handle categories。
- fail-closed policy。
- diagnostics as evidence, not state truth。
- no public API / enum / Result type yet。

## Comment-Only Check

`runtime/cjgui/src/error.cj` 检查结果：通过，文件仍为 comment-only。

Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.

## Forbidden File Check

本轮先记录 forbidden write set hash baseline，再在修改后复核。

复核范围包括：

- `labs/macos_bridge_smoke` 下 source / harness 文件，不含 build artifact。
- `runtime/README.md`。
- `runtime/cjgui/src/app_lifecycle.cj`。
- `runtime/cjgui/src/window_lifecycle.cj`。
- `runtime/cjgui/src/platform_adapter.cj`。

结果：通过，forbidden write set hash 未变化。

## Smoke Guard

运行现有 smoke guard：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：通过，exit code 0。

该 guard 仍只验证旧 smoke 链路，不是正式 runtime test framework。

## Verification Commands

```bash
awk 'NF && $1 !~ /^\/\// { print FILENAME ":" FNR ":" $0; bad=1 } END { exit bad }' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj
find /Users/jiangxuanyang/Desktop/cangjie/runtime -maxdepth 5 \( -name 'cjpm.toml' -o -name 'package.json' -o -name 'CMakeLists.txt' -o -name 'Makefile' -o -name '*.toml' \) -print | sort
rg -n 'cjgui_app_run|cjgui_last_error|cjgui_app_|cjgui_window_|cjgui_macos' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
rg -n 'cjgui_last_error|last_error\s*\(|last_error_code|last_error_category|last_error_message' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
rg -n '^(public|func|class|struct|enum|interface|foreign|type|let|var)\b|Result\s*<' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md
rg -n 'diagnostics.*state truth|second state truth|第二状态真相源|diagnostics.*truth' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md
rg -n 'NSWindow|NSView|CAMetalLayer|MTLDevice|CGImageRef|raw pointer|native handle|platform object' /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md
git diff --check
```

结果：通过。diagnostics 检查只命中禁止性说明，未发现 diagnostics 被写成 state truth。platform object / raw pointer 检查只命中禁止事项或 platform adapter 内部边界说明，未发现 public surface 或实现。

## Stop-Line Review

本轮守住 stop-line：

- 未实现 error strategy。
- 未定义 error enum、Result type 或 exception-like mechanism。
- 未定义 public runtime API 或 public C ABI。
- 未新增 package / build config。
- 未迁移 smoke `last_error`。
- 未复用 smoke C ABI。
- 未修改 `labs/macos_bridge_smoke`。
- 未修改 harness、native bridge 或仓颉入口。
- 未实现 app lifecycle、window lifecycle、platform adapter、handle table / generation。
- 未暴露 platform object / raw pointer public surface。
- 未进入 Renderer / Scene / Widget / Layout / DSL。
- 未进入 Dirty Rect / global tick / frame scheduler。
- 未进入 Text / Input / IME / Accessibility。
- 未进入 semantic tree / Action Router。
- 未进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## Residual Risks

- error strategy 仍未实现。
- 仍没有 concrete error type、Result model、recoverability contract 或 public API。
- app lifecycle、window lifecycle、platform adapter 仍为 comment-only surface。
- 没有 package / build entry，因此还不能做 Cangjie build check。
- smoke guard 不是正式 runtime test framework。
- 下一步需要对 minimal runtime skeleton surface phase 做收口和上下文压缩，避免继续堆叠过长 execution history。

## Current Next Opening

`P1 minimal runtime skeleton surface phase closure / compaction preflight`

这是 docs-only opening，不自动开启 runtime implementation。
