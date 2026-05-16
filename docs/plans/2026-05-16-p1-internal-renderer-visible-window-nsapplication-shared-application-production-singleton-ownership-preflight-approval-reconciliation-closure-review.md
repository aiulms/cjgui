# P1 Internal Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Approval Reconciliation Closure Review

状态：closure review / docs-only / production ownership still blocked

## Closure 范围

本 closure 复核
[production singleton ownership approval reconciliation decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-approval-reconciliation-decision.md)
是否只关闭 approval ambiguity，并确认没有把 throwaway creation evidence 升级为
production singleton ownership truth。

## 复核结论

- 当前 endpoint 保持
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`。
- 当前 default draft 保持
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft()`。
- 当前 runtime input 保持
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`。
- 本轮没有新增 runtime owner、native C ABI、production actual accessor call site、probe
  route 或 public surface。
- `production_singleton_ownership_truth=false` 保持。

## Source / Graph 覆盖

GitNexus 对当前 endpoint 与 default draft 返回 not found / UNKNOWN / 0 impacted。
该结果不能当作安全证明；closure 以 source reading、existing owner/native probes、build、
protected path scan、forbidden scan 与 manifest reachability 兜底。

## Stop-line 复核

Stop-line 未放宽：

- actual accessor call site 仍只存在于 isolated native probe。
- throwaway singleton creation evidence 不进入 production runtime truth。
- 不 production singleton ownership。
- 不创建或持有 production `NSApplication`。
- 不 activation / activation policy mutation。
- 不 AppKit event loop / bounded pump。
- 不 visible order / drawable / render。
- 不 artifact write / diagnostics publication。
- 不 public API / production public C ABI。
- 不写 `runtime/cjgui/src/runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。

## Closure 判定

Production singleton ownership approval reconciliation 可以封账。下一步仍只能停在：

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership preflight approval decision`

自动化在新的明确人工批准前不得打开 production singleton ownership preflight 或实现 production owner。
