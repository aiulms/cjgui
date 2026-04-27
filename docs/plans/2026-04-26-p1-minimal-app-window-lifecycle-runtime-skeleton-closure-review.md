# P1 Minimal App / Window Lifecycle Runtime Skeleton Closure Review

日期：2026-04-26

性质：closure review / bounded implementation first slice

状态：完成

对应执行卡：

- [2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-execution-card.md)

## 1. Landed Reality

本轮只落地了极窄 runtime skeleton / app-window lifecycle surface。它不是正式 runtime implementation，不实现真实 app/window lifecycle，不迁移 smoke 代码。

执行前检查：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui` 不存在。
- 因此按 execution card 新建最小 skeleton。

实际 write set：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

没有更新根 `/Users/jiangxuanyang/Desktop/cangjie/README.md`。

## 2. Runtime Skeleton Tree

```text
runtime/
  README.md
  cjgui/
    README.md
    src/
      app_lifecycle.cj
      error.cj
      platform_adapter.cj
      window_lifecycle.cj
```

## 3. File Roles

`runtime/README.md`：

- 说明 runtime 区域仍是 experimental skeleton。
- 说明与 `labs/` 的边界。
- 明确当前不稳定、不代表 public API、不迁移 smoke C ABI。

`runtime/cjgui/README.md`：

- 说明 minimal app/window lifecycle skeleton 的 owner 边界。
- 记录 app lifecycle owner、window lifecycle owner、platform adapter / core boundary、error strategy placeholder、smoke guard relationship 和 red-team guardrails。

`runtime/cjgui/src/app_lifecycle.cj`：

- comment-only skeleton。
- 只记录 future app lifecycle slots：init、run、request quit、shutdown、drain main-thread queue。
- 不实现 event loop，不调用 smoke C ABI，不定义 public API。

`runtime/cjgui/src/window_lifecycle.cj`：

- comment-only skeleton。
- 只记录 future window lifecycle slots：create window、request close、destroy / release、stale token guard、single-window first slice。
- 不实现真实 window create / close / destroy，不实现 handle table / generation。

`runtime/cjgui/src/platform_adapter.cj`：

- comment-only skeleton。
- 只记录 platform adapter / core boundary。
- 明确 AppKit event loop 属于 platform adapter，core runtime 不持有 `NSRunLoop` / `NSEvent` / `dispatch_main` / Objective-C callback truth。

`runtime/cjgui/src/error.cj`：

- comment-only skeleton。
- 只记录 error strategy placeholder。
- 明确 smoke `last_error` 不能直接迁移，future errors 必须调用关联、结构化、非全局、并发安全。

## 4. Cangjie Syntax / Build Check

本轮 `.cj` 文件均为 comment-only skeleton，没有 package / build config，也没有 runtime package entry。

因此本轮记录：

```text
Cangjie build check not applicable yet: no runtime package/build entry by design.
```

没有为了验证而创建 build config，也没有写入非注释仓颉语法。

验证命令：

```zsh
for f in runtime/cjgui/src/*.cj; do
  echo "$f"
  awk 'NF && $1 !~ /^\/\//' "$f"
done
```

结果：

- 每个 `.cj` 文件只输出文件名。
- 未发现非注释内容。

## 5. Smoke Guard Verification

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

该验证只证明旧 smoke guard 未因本轮 runtime skeleton 退化；它不是正式 runtime test framework。

## 6. Boundary Checks

本轮检查：

- runtime skeleton 没有引用 smoke C ABI 作为 public API。
- runtime skeleton 没有调用 `cjgui_app_run()` 或 `cjgui_last_error_*()`。
- runtime skeleton 没有暴露平台对象裸指针。
- runtime skeleton 中出现的 `NSRunLoop` / `NSEvent` / `dispatch_main` 只作为禁止 core truth 的注释边界，不是 API 或实现。
- runtime skeleton 没有实现 Renderer / Scene / Widget / Layout / DSL。
- runtime skeleton 没有实现 semantic tree / Action Router。
- runtime skeleton 没有实现 command-list hash、pixel diff、baseline、offscreen renderer。
- 没有创建 `CJGUI_TRUTH_MANIFEST.md`。

## 7. Forbidden File Check

本轮开始前记录了 forbidden 文件 hash baseline，覆盖：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`

本轮结束复核结果：

```text
forbidden hash check: OK
```

说明：工作区在本轮开始前已经存在 `labs/macos_bridge_smoke` 的未提交 / 未跟踪改动；本轮只用 hash baseline 证明这些 forbidden 文件未被本轮继续修改。

## 8. Red-team Guardrails Review

已守住：

- 不扩大每轮必读历史文档集。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。
- 不进入 pixel diff / baseline。
- 不保存或输出 hash value。
- 不实现 command-list hash。
- 不定义 Display List / Command Buffer API。
- 不让 core runtime 持有 AppKit runloop truth。
- 不实现 semantic tree / Action Router。
- render hot path 不维护完整 semantic tree。

## 9. Stop-line Review

已守住：

- 不实现真实 app lifecycle。
- 不实现真实 window lifecycle。
- 不实现 event loop。
- 不实现 window create / close / destroy。
- 不实现 handle table / generation。
- 不实现 public C ABI / public runtime API。
- 不迁移 smoke 代码。
- 不修改 smoke。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 不进入 semantic tree / Action Router。
- 不创建 governance manifest。

## 10. Residual Risk

仍未完成：

- 没有 runtime package / build entry。
- 没有真实 app lifecycle owner 实现。
- 没有真实 window lifecycle owner 实现。
- 没有 event loop adapter。
- 没有 platform adapter implementation。
- 没有 handle table / generation。
- 没有 structured runtime error type。
- 没有正式 runtime tests。

这些 residual 不阻塞本轮 closure，因为本轮目标只是 minimal comment-only skeleton。

## 11. Next Opening

当前不自动开启下一轮实现。

推荐下一条 docs-only opening：

- `P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight`

用途：

- 复核 comment-only skeleton 是否足以承接下一步 runtime surface 讨论。
- 判断下一条边界应先冻结 app lifecycle surface、window lifecycle surface、platform adapter boundary、error strategy，还是 runtime build/package boundary。
- 继续禁止直接进入 Renderer / Scene / Widget / Layout / DSL、public runtime API、pixel diff、baseline、command-list hash、semantic tree / Action Router。

## 12. Index / Diff Checks

本 closure review 已能从以下入口找到：

- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

本轮最终验证要求：

- 绝对链接目标无 missing。
- `git diff --check` 通过。
