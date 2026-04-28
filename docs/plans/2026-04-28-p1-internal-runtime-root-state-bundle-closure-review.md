# P1 Internal Runtime Root State Bundle Closure Review

日期：2026-04-28

类型：bundled closure / mini-compaction

authority：

- [2026-04-28-p1-internal-runtime-root-state-bundle-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-state-bundle-execution-card.md)

## Closed Scope

Slice A：

- 新增 `runtime/cjgui/src/runtime_state.cj`。
- 新增默认 internal `CjguiInternalRuntimeRootState`。
- root state 只持有 `bootstrap: CjguiInternalRuntimeBootstrapSnapshot` 与 `isRuntimeReady: Bool`。

Slice B：

- 新增默认 internal `cjguiInternalBuildRuntimeRootState()`。
- builder 调用 `cjguiInternalBuildRuntimeBootstrapSnapshot()`。
- builder 使用 `bootstrap.isBootstrapReady` 作为 `isRuntimeReady`。

## Verification

- Slice A：envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-root-state-bundle-slice-a-target --skip-script` 通过，仅 unused warnings。
- Slice B：envsetup 后 `cjpm build --target-dir /tmp/cjgui-runtime-root-state-bundle-slice-b-target --skip-script` 通过，仅 unused warnings。
- Slice B smoke guard：`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- Slice B `git diff --check` 通过。

## Forbidden Boundary

本 bundle 未新增 public runtime API 或 public C ABI。

本 bundle 未接入 AppKit / Metal / Objective-C，未暴露 platform object / native handle / raw pointer，未实现 event loop、callback binding、queue / drain、app run / shutdown、window create / close / destroy / release，也未新增 handle table / generation。

本 bundle 未修改 `cjpm.toml`、`labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。

## Next Opening

建议 next opening：

- `P1 internal runtime root state closure / first runtime module boundary decision`

下一轮应先决定 runtime module boundary，不应自动进入 public API、public C ABI、platform bridge、event loop、queue / drain、app run 或 window create。
