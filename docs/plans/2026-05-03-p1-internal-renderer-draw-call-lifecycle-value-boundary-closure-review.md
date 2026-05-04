# P1 internal Renderer draw call lifecycle value boundary closure review

日期：2026-05-03

状态：closure review

## Scope

本轮新增一个 internal-only renderer owner：

- `runtime/cjgui/src/runtime_renderer_draw_call.cj`

本轮严格保持 no-draw-call / no-platform-object / no-render 边界：不执行 draw call，不调用 encoder，不绑定 pipeline state、vertex / index buffer 或 texture，不提交 GPU work，不创建 command buffer、render pass、drawable、platform object、native handle 或 raw pointer，不接 backend / Metal / AppKit implementation，不写 renderer state。

## Read Inputs

- [2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime_renderer_encoder.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder.cj)
- Adjacent renderer lifecycle owners: command buffer / render pass / encoder fail-closed patterns。

## GitNexus Impact

Pre-edit impact analysis：

- `CjguiInternalRendererNoEncoderReadiness`: GitNexus returned `UNKNOWN / not found`，impacted count `0`。
- `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft`: GitNexus returned `UNKNOWN / not found`，impacted count `0`。

Interpretation：

- 这两个入口 symbol 来自近期新增 owner，当前 GitNexus index 尚未覆盖。
- 源码存在性已由 `rg` 与 source read 兜底确认。
- 没有 HIGH / CRITICAL impact 结果；本轮未修改入口 symbol，只新增 downstream owner。

## Implemented Symbols

新增 internal symbols：

- `CjguiInternalRendererDrawCallLifecycleIntent`
- `CjguiInternalRendererDrawCommandShapePolicy`
- `CjguiInternalRendererGeometrySourcePolicy`
- `CjguiInternalRendererDrawSequencingGuard`
- `CjguiInternalRendererNoDrawCallReadiness`
- `cjguiInternalBuildRendererDrawCallLifecycleIntent(...)`
- `cjguiInternalBuildRendererDrawCommandShapePolicy(...)`
- `cjguiInternalBuildRendererGeometrySourcePolicy(...)`
- `cjguiInternalBuildRendererDrawSequencingGuard(...)`
- `cjguiInternalBuildRendererNoDrawCallReadiness(...)`
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoDrawCallReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

Canonical input：

- `CjguiInternalRendererNoEncoderReadiness`
- `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`

## Boundary Semantics

Open path：

- `CjguiInternalRendererNoEncoderReadiness` is open only when the upstream no-encoder endpoint is sealed, value-only, no-defer, no-blocked, no backend / render permission, and no thin wrapper.
- The default draft then forms draw call lifecycle intent, draw command shape policy, geometry source policy, draw sequencing guard, and no-draw-call readiness facts.

Defer-only path：

- Upstream defer remains defer.
- The draw-call owner does not forge readiness from a deferred no-encoder endpoint.

Blocked / inconsistent path：

- Any upstream blocked or inconsistent combination fails closed to blocked.
- Internal inconsistent facts in intent / policy / guard also fail closed to blocked.

No-draw-call readiness explicitly means:

- no draw call execution。
- no encoder call。
- no pipeline binding。
- no buffer binding。
- no texture binding。
- no GPU submission。
- no native handle or raw pointer。
- no backend permission。
- no render permission。
- no renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 生效。

本轮不是把 `CjguiInternalRendererNoEncoderReadiness` 换名包装为 draw-call receipt / record / publication。新增语义点是：

- draw call lifecycle intent。
- draw command shape policy。
- primitive kind placeholder。
- instance count placeholder。
- geometry source policy。
- vertex / index source policy facts。
- draw order relation。
- material grouping hints as sequencing facts。
- failure / no-draw fallback。
- no-draw-call readiness。

本轮明确拒绝：

- draw-call receipt / record / publication。
- backend-readiness wrapper。
- pipeline-state readiness wrapper。
- render execution wrapper。
- draw call implementation。
- encoder call implementation。
- pipeline / buffer / texture binding implementation。

## Stop-line

继续禁止：

- no backend / Metal / AppKit implementation。
- no `MTLRenderCommandEncoder` object。
- no pipeline state object。
- no vertex / index buffer object。
- no texture object。
- no command buffer / render pass / drawable object。
- no native handle / raw pointer。
- no draw call execution。
- no GPU submission。
- no render execution。
- no renderer state write。
- no module-level mutable state。
- no new public symbol。
- no C ABI。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry changes。

## Documentation Sync

同步更新：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)

## Validation

Validation results：

- `cjpm build --target-dir /tmp/cjgui-renderer-draw-call-lifecycle-value-boundary-target --skip-script`: blocked by local environment, `cjpm: command not found`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`: passed。
- `git diff --check`: passed。
- Markdown absolute link missing target check: passed。
- Closure reachability check: passed；README / GUI_TASK_TRACKER / docs/plans README / runtime README 均能找到 closure 与 next opening。
- Forbidden check: passed；未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`。
- Public declaration scan: passed；仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Stop-line source scan: passed；新文件没有 runtime backend / draw-call execution / encoder call implementation / pipeline binding implementation / buffer binding implementation / texture binding implementation / GPU submission / render execution / renderer state write / platform implementation / C ABI / native handle / raw pointer / `public` / module-level `var`。`MTLRenderCommandEncoder`、pipeline state、vertex buffer、index buffer、texture 等词只出现在禁止性注释中。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`，affected processes `0`。

## Decision

`runtime_renderer_draw_call.cj` 已足够作为 draw call lifecycle value boundary owner。

Current canonical endpoint：

- `CjguiInternalRendererNoDrawCallReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

唯一 next opening：

`P1 internal Renderer draw call lifecycle closure / next draw call decision`

下一轮必须 docs-only，评估 `CjguiInternalRendererNoDrawCallReadiness` 是否足够作为当前 no-draw-call endpoint，并决定是否先做 manifest stabilization；不得直接进入 pipeline state lifecycle implementation、render execution、backend / Metal implementation 或 renderer state write。
