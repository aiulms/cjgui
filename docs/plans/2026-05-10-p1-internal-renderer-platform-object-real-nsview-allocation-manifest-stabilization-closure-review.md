# P1 内部渲染器 platform object 真实 NSView allocation 清单封账复核

日期：2026-05-10

状态：manifest stabilization closure / validated

## 封账结论

真实 `NSView` allocation feasibility stage 已按 manifest 封账为 isolated feasibility + planning owner。当前 tail 固定为：

`CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft()`

该 tail 只证明 isolated immediate-release `NSView` allocation feasibility 与 production retention blocked facts，不证明 production object exists。

## 验证记录

本轮最终验证通过：

- 新 `NSView` feasibility probe 通过，输出 `success=true reason=none`，并观察到 `main_thread_observed=true`、`nsview_allocation_observed=true`、`immediate_cleanup_observed=true`、`background_thread_allocation_denied=true`、`pointer_returned=false`、`native_handle_returned=false`、`nsview_saved=false`、`window_created=false`、`application_created=false`、`layer_created=false`、`metal_quartzcore_imported=false`。
- no-object creation、AppKit import、class availability、main-thread admission、teardown admission、token issue/revoke、no-resource call、isolated FFI、package link、`cjpm` package link、skeleton compile、symbol probe 与 `cjpm` boundary 均通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-real-nsview-allocation-feasibility-target --skip-script` 通过；仓库既有 unused warnings 仍存在，未形成构建失败。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。
- runtime / native / script / docs whitespace check 通过。
- Markdown absolute link missing target check 通过，检查 `942` 个项目 Markdown / README 文件，`missing_count=0`。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / 三个 topic manifest reachability 通过，`missing_count=0`。
- 中文标题与中文正文抽查通过。
- Comment-aware public declaration scan 通过，仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Production native forbidden scan 通过：未发现 production `NSView` allocation、`NSWindow` / `NSApplication` / layer creation、Metal / QuartzCore import、pointer / handle / `Class` / `id` return 或 long-lived native object storage。
- Owner header / stop-line scan 通过。
- Protected path scan 通过：`runtime_state.cj` 仍为 `10065` 行，`runtime/cjgui/cjpm.toml`、smoke native files 与 `runtime_state.cj` 无 diff。
- GitNexus upstream impact 对上游 endpoint / default draft 已记录 not found / UNKNOWN、`impactedCount=0`，无 HIGH / CRITICAL；GitNexus `detect_changes(scope=unstaged)` 返回 `Risk level: low`、`Affected processes: 0`。

## 下游指向

该入口已由 [token-backed NSView object table stage](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，真实 `NSView` allocation feasibility 进入 manifest stabilization closure。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_allocation_planning.cj`；truth 固定为 isolated feasibility 与 production retention blocked facts；stop-line 继续禁止 production retention、object table、pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
