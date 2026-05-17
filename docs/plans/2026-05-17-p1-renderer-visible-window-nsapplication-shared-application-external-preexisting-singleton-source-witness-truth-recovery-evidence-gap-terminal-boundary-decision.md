# P1 Renderer visible-window NSApplication shared-application source witness truth recovery evidence-gap terminal boundary decision

状态：decision / docs-only terminal boundary / external source evidence required

## 决策

本轮选择 A：将 `external preexisting singleton source witness truth recovery evidence-gap terminal boundary` 收束为 docs-only terminal branch。

该阶段不新增 runtime owner，不新增 owner probe，也不继续堆叠同构 readiness wrapper。Stage 63 已经把 source witness truth recovery false branch 路由回 external owner witness packet / source readiness evidence gap；源码与 manifest 复核显示，当前仓库内仍没有可被 production runtime 接受的外部 owner source evidence。

## 证据结论

- 现有 witness packet / admission / recovery owner 都是 dehydrated / pre-truth facts。
- isolated actual accessor probe 与 throwaway creation probe 只能证明 probe-local side effect / classification，不能证明 Renderer 以外 owner 在 Renderer 之前持有 production `NSApplication` singleton。
- 当前没有 production-acceptable external owner witness packet，无法证明 preexisting singleton source、main-thread observation、source lifetime、cleanup ownership、headless fail-closed 与 Renderer non-creation / non-accessor invariant 同时成立。
- 因此 external source witness truth、source readiness truth 与 production singleton ownership truth 必须继续保持 false。

## Canonical endpoint

本阶段不改变 runtime canonical endpoint。当前 endpoint 仍是：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness`

Default draft 仍是：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamDraft()`

Runtime input 仍是：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryValueBoundaryReadiness`

## Truth boundary

- `evidence_gap_terminal_boundary_docs_only=true`
- `new_runtime_owner_added=false`
- `new_owner_probe_added=false`
- `external_owner_source_evidence_available=false`
- `production_acceptable_external_owner_witness_packet=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `source_readiness_truth_value=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

本阶段不调用 application singleton accessor，不创建或激活 `NSApplication`，不修改 activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup / teardown，不创建 window / view / layer，不 visible order，不取 drawable，不 render，不写 renderer state，不扩 public API 或 production C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external owner source witness evidence intake / human-provided source evidence decision`
