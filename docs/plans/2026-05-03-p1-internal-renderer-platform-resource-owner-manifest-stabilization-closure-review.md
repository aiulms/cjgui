# P1 internal Renderer platform resource owner manifest stabilization closure review

日期：2026-05-03

状态：docs-only manifest stabilization closure

## Scope

本轮只做 docs / manifest stabilization，未修改 `.cj`，未实现 backend / Metal / AppKit / CAMetalLayer / command buffer / render execution / renderer state write。

新增 manifest：

- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)

同步入口：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

## Manifest Conclusion

Manifest 已固定：

- owner file：`runtime/cjgui/src/runtime_renderer_platform_resource.cj`
- canonical endpoint：`CjguiInternalRendererNoPlatformResourceReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`
- canonical upstream packet truth：`CjguiInternalRendererPacketOrderingHardeningResult` / `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

Current truth 只包含：

- platform resource owner intent value facts。
- resource confinement policy value facts。
- drawable acquisition policy value facts。
- command queue ownership policy value facts。
- no-platform-resource readiness value facts。

Future resources 只作为 policy targets 命名：device / layer / command queue / drawable / command buffer / render pass / encoder。

Allowed dehydrated facts 只包括：resize / scale / color / frame pacing hints。

Forbidden in core packet：`MTLDevice` / `CAMetalLayer` / native handle / raw pointer / drawable / command buffer / render pass / encoder。

## Boundary Conclusion

`CjguiInternalRendererNoPlatformResourceReadiness` 是当前 no-platform-resource endpoint。它不是 backend readiness、platform resource permission、command queue permission、drawable acquisition permission、command buffer permission、render permission 或 renderer state write。

当前仍没有：

- Metal / AppKit implementation。
- backend object。
- platform resource。
- command queue。
- drawable acquisition。
- command buffer。
- render pass / encoder。
- render execution。
- renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮通过 manifest 封账生效：

- 拒绝 platform resource receipt / record / publication。
- 拒绝 backend-readiness wrapper。
- 拒绝 command queue readiness wrapper。
- 拒绝 drawable acquisition readiness wrapper。
- 拒绝把 reference pack 或 packet owner-truth milestone 直接当作 backend / platform permission。

未来若靠近 command queue / drawable / platform lifecycle，必须先 docs-only preflight，并引用 backend / Metal reference pack 的具体 evidence。不得直接实现 command queue、drawable acquisition、platform resource、command buffer、render execution 或 renderer state write。

## Candidate Comparison

### A. P1 internal Renderer command queue lifecycle preflight decision

选择为唯一 next opening。

它只做 docs-only preflight，评估 command queue owner / lifecycle / readiness runway，不创建 command queue，不创建 command buffer，不实现 backend。

### B. P1 internal Renderer drawable acquisition lifecycle preflight decision

暂缓。

通常应等 command queue lifecycle preflight 后再评估 drawable acquisition lifecycle。

### C. Platform resource owner hardening

暂缓。

仅在发现 resource confinement / acquisition / ownership 表达不足时选择。当前 manifest 未发现缺口。

### D. Backend-readiness preflight revisit

暂缓。

等 command queue / drawable lifecycle 进一步拆清后再评估，避免 backend-readiness wrapper 回潮。

### E. Backend / Metal implementation

拒绝。

### F. Command buffer / render execution / renderer state write

拒绝。

### G. Metal / AppKit / platform resource / native handle implementation

拒绝。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### I. Public surface expansion

拒绝。

### J. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。

## Validation Record

Completed docs-only guards：

- `git diff --check`：passed。
- Markdown absolute link missing target check：passed。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check：passed。
- forbidden path check：passed；no tracked `.cj` diff, no `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry, AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER diff。
- public declaration scan：still only `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`：risk `low`, affected processes `0`。

本轮按要求不运行 `cjpm build` / smoke。

## Next Opening

`P1 internal Renderer command queue lifecycle preflight decision`

下一轮必须 docs-only；不得创建 command queue、command buffer、render pass、encoder、drawable、backend object、platform object、native handle 或 raw pointer；不得实现 backend / Metal / AppKit / render execution / renderer state write。
