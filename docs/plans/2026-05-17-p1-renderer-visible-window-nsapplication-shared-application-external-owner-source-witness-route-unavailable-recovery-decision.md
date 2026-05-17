# P1 Renderer visible-window NSApplication shared-application external owner source witness route unavailable recovery decision

状态：decision / recovery route selected / evidence absent

## 决策

用户已人工确认：当前没有可提供的 external owner source witness evidence packet。

因此，本阶段消费 Stage 64 evidence-intake gate 的结论，并把 external preexisting singleton owner witness route 标记为 unavailable / evidence absent。该 route 不再作为当前 runway 的等待项，也不能通过同构 blocker 文档、isolated probe evidence 或推断补成 truth。

本阶段选择进入 recovery / alternative route decision：

- external owner source witness route：unavailable。
- source witness truth：不升级。
- source readiness truth：不升级。
- production singleton ownership truth：不升级。
- isolated throwaway singleton evidence：只能继续作为 evidence-only 输入，不能升级成 external owner truth。
- production singleton ownership：只能进入 feasibility / preflight recovery，不实现 owner。
- no-production-singleton-truth：继续作为当前安全 carry-forward。

## 替代路线评估

### A. internal ownership recovery feasibility

可以作为下一步的首选替代路线，但只能是 preflight / feasibility decision。它必须先回答：

- Renderer 是否有合法 internal ownership route，而不是伪装成 external preexisting singleton owner；
- 是否能在不新增 `NSApplication.sharedApplication` 调用的前提下消费已有 evidence；
- main-thread confinement、source lifetime、cleanup / teardown ownership 是否能被现有证据闭合；
- headless / CI-like 场景是否仍 fail-closed；
- 是否保持 no activation、no event loop、no visible order、no drawable、no render；
- 是否不发布 artifact、public diagnostics、native identity、pointer、handle、`id` 或 `Class`。

在这些问题闭合前，internal ownership recovery 不能升级为 production singleton ownership truth。

### B. isolated throwaway singleton evidence continuation

可以复用既有 isolated throwaway evidence 作为 alternative-route 输入，但它不能证明 external owner，也不能直接证明 production singleton ownership。它只能回答“系统知道 throwaway accessor-created singleton 的副作用边界”，不能回答“生产路径可拥有 singleton”。

### C. production singleton ownership preflight recovery

可以打开 recovery preflight 来分类生产 ownership 的可行路线，但不得实现 production singleton owner，不得新增 production C ABI，不得新增 public API，不得调用新的 `NSApplication.sharedApplication`。

### D. no-production-singleton-truth stabilization

如果 A/B/C 仍不能提供可审计证据，下一步应把 no-production-singleton-truth 作为明确 carry-forward，而不是继续等待 external owner witness。

## Truth boundary

- `human_provided_external_owner_source_witness_evidence_absent=true`
- `external_preexisting_singleton_owner_witness_route_available=false`
- `external_owner_source_evidence_available=false`
- `production_acceptable_external_owner_witness_packet=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `source_readiness_truth_value=false`
- `production_singleton_ownership_truth=false`
- `isolated_throwaway_probe_evidence_promoted_to_external_owner_truth=false`
- `isolated_throwaway_probe_evidence_promoted_to_production_ownership_truth=false`
- `internal_ownership_recovery_feasibility_selected=true`
- `no_production_singleton_truth_carry_forward=true`
- `new_runtime_owner_added=false`
- `new_owner_probe_added=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

本阶段不授权 production singleton owner implementation、新的 `NSApplication.sharedApplication` 调用、`setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`、visible `NSWindow`、visible order、production `nextDrawable`、render pass drawable texture、render command encoder、draw、commit、present、GPU submission、renderer state write、`runtime_state.cj` 修改、`runtime/cjgui/cjpm.toml` 修改、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application internal ownership recovery feasibility preflight / no-production-singleton-truth carry-forward decision`
