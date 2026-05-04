# P1 internal Renderer drawable acquisition lifecycle value boundary closure review

日期：2026-05-03

状态：implementation closure

## Scope

本轮新增一个 internal-only renderer owner，用于把 `CjguiInternalRendererNoCommandQueueReadiness` 投影为 drawable acquisition lifecycle 的 value facts。

本轮没有获取 drawable，没有创建或引用真实 `CAMetalLayer`、`CAMetalDrawable`、`MTLDrawable`、command buffer、render pass、encoder、native handle 或 raw pointer；没有实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Runtime Owner

新增 owner file：

- [runtime_renderer_drawable_acquisition.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj)

Input truth：

- `CjguiInternalRendererNoCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`

## Added Internal Symbols

- `CjguiInternalRendererDrawableLifecycleIntent`
- `CjguiInternalRendererDrawableAvailabilityPolicy`
- `CjguiInternalRendererDrawableAcquisitionTimingGuard`
- `CjguiInternalRendererPresentationOwnershipPolicy`
- `CjguiInternalRendererNoDrawableReadiness`
- `cjguiInternalBuildRendererDrawableLifecycleIntent`
- `cjguiInternalBuildRendererDrawableAvailabilityPolicy`
- `cjguiInternalBuildRendererDrawableAcquisitionTimingGuard`
- `cjguiInternalBuildRendererPresentationOwnershipPolicy`
- `cjguiInternalBuildRendererNoDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft`

## Boundary Conclusion

`CjguiInternalRendererNoDrawableReadiness` 只表示当前 drawable acquisition lifecycle value boundary 可以继续评估，不代表 drawable acquisition permission、platform object permission、backend readiness、command buffer permission、render pass permission、render permission 或 renderer state write。

Current truth 仅包含：

- drawable lifecycle intent value facts。
- drawable availability policy value facts。
- acquisition timing guard value facts。
- presentation ownership policy value facts。
- no-drawable readiness value facts。

Open path 从 no-command-queue readiness 形成 drawable lifecycle / availability / timing / presentation / no-drawable facts。Defer-only path 保持 defer，不伪造 drawable readiness。Blocked / inconsistent path fail-closed blocked。

## Stop-line

继续禁止：

- no drawable acquisition。
- no `CAMetalLayer` / `CAMetalDrawable` / `MTLDrawable` object creation or field ownership。
- no command queue creation。
- no command buffer / render pass / encoder。
- no backend / Metal / AppKit implementation。
- no render execution / draw call。
- no renderer state write。
- no native handle / raw pointer / platform resource token。
- no dirty-region / Widget / Layout / Text / IME / Accessibility。
- no public surface expansion。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

本 owner 新增的是 drawable lifecycle / availability / acquisition timing / presentation ownership / no-drawable readiness 语义，不是把 `CjguiInternalRendererNoCommandQueueReadiness` 包成 drawable receipt / record / publication。

本轮没有新增 drawable receipt / record / publication，没有复用旧 handoff receipt，也没有把 command buffer lifecycle 或 render pass lifecycle 混入本 owner。后续若靠近 command buffer / render pass / platform lifecycle，必须先做 docs-only preflight，不能直接实现。

## GitNexus

执行前 impact：

- `CjguiInternalRendererNoCommandQueueReadiness`：GitNexus 返回 UNKNOWN / not found，impactedCount 0。
- `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft`：GitNexus 返回 UNKNOWN / not found，impactedCount 0。

处理方式：按近期新增 owner 尚未索引记录，使用源码存在性、`cjpm build`、stop-line scan 与 `detect_changes(scope=unstaged)` 兜底。

## Verification

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-drawable-acquisition-lifecycle-value-boundary-target --skip-script`：通过；仅保留既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过；auto-close log assertions passed。
- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- closure reachability check：README / GUI_TASK_TRACKER / docs/plans README 均可找到本 closure 与 next opening。
- forbidden check：通过；未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- stop-line source scan：通过；新文件不含 `public` / module-level `var` / real backend / command buffer / render execution / platform implementation tokens，平台对象名只出现在禁止性注释中。
- GitNexus `detect_changes(scope=unstaged)`：risk low，affected processes 0。GitNexus 报告 10 changed symbols / 7 changed files，其中 runtime 新 owner 作为近期新增未索引文件未映射为 changed symbol；以源码存在性、build 与 stop-line scan 兜底。

## Next Opening

唯一 next opening：

`P1 internal Renderer drawable acquisition lifecycle closure / next drawable acquisition decision`

下一轮必须 docs-only，评估 `CjguiInternalRendererNoDrawableReadiness` 是否已足够作为当前 no-drawable endpoint，并决定是否先做 manifest stabilization；不得直接进入 command buffer lifecycle、render pass lifecycle、backend / Metal implementation 或 renderer state write。

## Downstream Next-Boundary Decision

Renderer drawable acquisition lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoDrawableReadiness` 已经足够作为当前 no-drawable endpoint。下一步唯一 opening 是 docs-only `P1 internal Renderer drawable acquisition lifecycle manifest stabilization bundle implementation`。
