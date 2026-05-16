# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Next-Boundary Decision

状态：next-boundary decision / docs-only / source-and-cleanup boundary selected

## 上游

- [production singleton ownership preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-decision.md)
- [production singleton ownership preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-closure-review.md)

## Boundary 选择

下一步选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership source-and-cleanup boundary decision`

该 opening 仍是 docs / decision 边界，不是 implementation opening。它只允许继续明确
production singleton ownership source、cleanup responsibility、main-thread confinement
proof route、headless fail-closed policy 与 stop-line carry-forward。

## 可选路径

- External / user app shell source：production singleton 由调用方或 future app shell 拥有；
  Renderer 只接受 preexisting singleton readiness，不创建 singleton。
- Future explicit runtime owner source：需要新的人工批准后，才可打开极窄
  production singleton owner implementation preflight。
- Rejected path：把 throwaway creation probe 的 singleton side effect 搬入 production
  runtime。该路径继续拒绝。

## 不允许的路径

下一步不得直接进入：

- production singleton owner implementation。
- runtime owner truth。
- native C ABI。
- `NSApplication.sharedApplication` actual call。
- activation / activation policy mutation。
- AppKit event loop / bounded pump。
- `NSWindow` / `NSView` / `CAMetalLayer` creation。
- visible order。
- drawable acquisition。
- command queue / command buffer / encoder creation。
- render / commit / present / GPU submission。
- artifact / diagnostics publication。
- public API / public C ABI。
- `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 修改。

## Carry-forward truth

- `production_singleton_ownership_preflight_opened=true`
- `production_singleton_ownership_truth=false`
- `production_singleton_source_selection_required=true`
- `production_singleton_cleanup_responsibility_required=true`
- `production_singleton_implementation_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership source-and-cleanup boundary decision`
