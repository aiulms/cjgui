# P1 Renderer 可见窗口 NSApplication Shared-Application 外部预存 singleton source readiness truth explicit approval 决策

状态：decision / docs-only preflight / evidence insufficient

## Decision

本轮收到明确批准，可以打开 `external preexisting singleton source readiness truth explicit approval decision / preflight`，但批准范围只限决策与封账，不批准直接实现 production singleton owner。

结论：现有 evidence 不足以升级为 source readiness truth。当前阶段必须停在 blocker / recovery decision，不得伪造 `external_preexisting_singleton_source_readiness_truth=true`。

## Evidence Review

可消费 evidence：

- isolated actual accessor call probe evidence；
- throwaway creation probe evidence；
- production singleton ownership source-cleanup boundary；
- external preexisting singleton source readiness preflight；
- witness contract shape / admission policy / payload schema / payload validation / acceptance gate / witness truth admission preflight；
- source readiness admission preflight。

这些 evidence 的共同结论仍是 fail-closed：

- isolated actual accessor probe 在当前环境没有 preexisting `NSApplication` singleton，`accessor_call_attempted=false`、`classification=-240`；
- throwaway creation probe 证明 accessor 可创建 throwaway singleton，`classification=241`，但该事实已被 source-cleanup boundary 明确拒绝为 production source；
- witness truth admission preflight 仍保持 `external_preexisting_singleton_source_witness_truth=false`；
- source readiness admission preflight 仍保持 `external_preexisting_singleton_source_readiness_truth=false` 与 `production_singleton_ownership_truth=false`；
- 没有外部 owner 提供的 preexisting singleton witness truth；
- 没有 source lifetime / cleanup ownership truth；
- 没有 production singleton ownership truth。

## Boundary

本阶段不新增 internal value owner。若未来需要新增 owner，必须先明确它只能是 readiness/source-truth boundary，不能是 production `NSApplication` ownership implementation。

当前 runtime canonical endpoint 保持：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightReadiness`

当前 default draft 保持：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightDraft()`

当前 runtime input 保持：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightReadiness`

## Stop-Line

本阶段禁止：

- production singleton owner implementation；
- source readiness truth 伪造；
- actual `NSApplication` ownership；
- `NSApplication.sharedApplication` call；
- `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` / `terminate`；
- `NSWindow` / `NSView` / `CAMetalLayer` creation；
- visible order；
- `nextDrawable`；
- command queue / command buffer / encoder；
- render / commit / present / GPU submission；
- artifact write / diagnostics publication；
- public API / public C ABI；
- `runtime_state.cj` / `runtime/cjgui/cjpm.toml` change。

## Recovery Opening

当前唯一 next opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth evidence recovery decision`
