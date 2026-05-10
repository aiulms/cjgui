# P1 内部渲染器 platform object token-backed NSView object table 清单封账复核

日期：2026-05-10

状态：manifest stabilization closure / validated

## 封账结论

token-backed `NSView` object table stage 已按 manifest 封账为 no-allocation table shell + runtime internal owner。当前 tail 固定为：

`CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()`

该 tail 只证明 production bridge 能暴露 fixed-capacity `NSView` table shell 与 fail-closed token classification facts，不证明 `NSView` 被创建、保存、销毁或绑定到 token。

## 验证记录

本轮阶段验证已通过：

- 新 `NSView` object table probe 通过，输出 `success=true reason=none`，并观察到 `table_capacity_observed=true`、`table_enabled_observed=true`、`table_empty_observed=true`、`invalid_token_fail_closed_observed=true`、`token_not_bound_observed=true`、`allocation_blocked_observed=true`、`destroy_blocked_observed=true`、`revoke_observed=true`。
- 新 probe 同时确认 `nsview_allocated=false`、`nsview_saved=false`、`pointer_returned=false`、`native_handle_returned=false`、`metal_quartzcore_imported=false`。
- `NSView` allocation feasibility probe 仍通过，并保持 isolated immediate cleanup route。
- no-resource call probe 通过，并观察到新增 `nsview_table_*` facts。
- package link / `cjpm` package link probe 已观察新增 `nsview_table_*` facts。
- `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-nsview-object-table-target --skip-script` 通过；既有 unused warnings 不构成失败。
- skeleton compile、symbol probe、`cjpm` boundary、macOS smoke auto-close、`git diff --check`、Markdown absolute link / reachability / 中文标题正文抽查、protected path scan、comment-aware public declaration scan、native forbidden scan 与 GitNexus `detect_changes` 已执行通过。
- `runtime_state.cj` 行数仍为 `10065`；`runtime/cjgui/cjpm.toml`、smoke native files 与 `runtime_state.cj` 未修改。
- GitNexus impact 对上游 endpoint / default draft 返回 UNKNOWN / not found，按近期新增 owner 未索引记录；最终 `detect_changes(scope=unstaged)` 返回 risk low / affected processes 0。

若后续验证发现 build / probe 不稳定，应回退到 recovery，不得把本 manifest 当成 retention permission。

## 下游指向

唯一后续入口固定为：

`P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed `NSView` object table 进入 manifest stabilization closure。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_object_table.cj`；truth 固定为 table shell / no-allocation / fail-closed facts；stop-line 继续禁止 `NSView` allocation / storage、token-to-object binding、pointer / handle / `id` / `Class` return、Metal / QuartzCore、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
