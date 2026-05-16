# P1 Renderer 可见窗口 NSApplication Shared-Application source readiness truth evidence recovery 决策

状态：decision / docs-only recovery / existing evidence insufficient

## Decision

本阶段打开 `external preexisting singleton source readiness truth evidence recovery decision`，但只允许恢复路径判定，不允许把现有 evidence 直接升级为 source readiness truth。

结论：现有 in-repo / automation evidence 不能恢复 source readiness truth。唯一可继续推进的恢复路径是先定义外部 owner witness packet preflight，用来描述由外部 owner 提供的 preexisting `NSApplication` singleton witness、main-thread observation、source lifetime、cleanup ownership 与 Renderer non-creation / non-accessor invariant。

## Evidence Review

已复核的现有 evidence 仍不足：

- isolated actual accessor first slice 在当前 automation 环境没有 preexisting `NSApplication` singleton，`accessor_call_attempted=false`、`application_created=false`、`classification=-240`。
- throwaway creation probe 证明 accessor 可创建 throwaway singleton，`accessor_call_attempted=true`、`throwaway_application_created=true`、`classification=241`，但该 evidence 已被 source-cleanup boundary 拒绝为 production source。
- witness contract shape、admission policy、payload schema、payload validation、acceptance gate、witness truth admission 与 source readiness admission 都是 dehydrated / pre-truth carry-forward，不是 actual source readiness truth。
- `labs/macos_bridge_smoke` 拥有 creation、activation policy mutation、activation、visible order 与 AppKit run loop 行为，不能作为 production harness 的 source truth 直接搬用。

## Recovery Contract

下一步只能打开 external owner witness packet preflight。该 preflight 必须先说明：

- witness packet 由 runtime 外部 owner 提供，不能由 Renderer 创建或补写；
- witness packet 只能是 dehydrated fact packet，不能携带 pointer、handle、`id`、`Class` 或 native object；
- packet 必须声明 preexisting singleton 在 Renderer observation 前已存在；
- packet 必须声明 observation 发生在 main thread；
- packet 必须声明 source lifetime 覆盖 runtime owner admission 之前与之后的有效区间；
- packet 必须声明 cleanup ownership 留在外部 source，不由 Renderer 执行 cleanup / teardown；
- packet 必须声明 Renderer 未调用 `NSApplication.sharedApplication`，也未创建 `NSApplication`；
- headless / missing / ambiguous / wrong-thread / Renderer-created / throwaway source 全部 fail closed。

## Canonical 状态

本阶段不新增 runtime owner。当前 canonical endpoint / default draft / runtime input 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightDraft()`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightReadiness`

## Truth

- `source_readiness_truth_evidence_recovery_opened=true`
- `existing_probe_evidence_recovery_sufficient=false`
- `external_owner_witness_packet_preflight_required=true`
- `external_owner_provided_preexisting_singleton_witness_required=true`
- `main_thread_observation_evidence_required=true`
- `source_lifetime_evidence_required=true`
- `cleanup_ownership_evidence_required=true`
- `renderer_non_creation_evidence_required=true`
- `renderer_non_accessor_evidence_required=true`
- `throwaway_singleton_rejected_as_source_truth=true`
- `renderer_created_singleton_rejected_as_source_truth=true`
- `source_readiness_truth_recovered=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`

## Stop-Line

本阶段禁止：

- source readiness truth 升级；
- production singleton owner implementation；
- actual `NSApplication` ownership；
- `NSApplication.sharedApplication` call；
- `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` / `terminate`；
- `NSWindow` / `NSView` / `CAMetalLayer` creation；
- visible order；
- `nextDrawable`；
- command queue / command buffer / encoder；
- render / commit / present / GPU submission；
- artifact write / diagnostics publication；
- pointer / handle / `id` / `Class` return；
- public API / public C ABI；
- `runtime_state.cj` / `runtime/cjgui/cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet recovery preflight decision`
