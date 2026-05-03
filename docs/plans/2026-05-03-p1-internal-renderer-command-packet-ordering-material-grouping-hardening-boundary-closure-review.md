# P1 internal Renderer command packet ordering / material grouping hardening boundary closure review

日期：2026-05-03

状态：closed

## Scope

本轮新增 internal-only Renderer packet ordering / material grouping hardening owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_packet_ordering.cj`

它只消费：

- `CjguiInternalRendererPacketNormalizationResult`

Canonical endpoint：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

## New Internal Symbols

- `CjguiInternalRendererPacketOrderingBasis`
- `CjguiInternalRendererMaterialGroupingScope`
- `CjguiInternalRendererHintPreservationPolicy`
- `CjguiInternalRendererNoSortNoMergeGate`
- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalBuildRendererPacketOrderingBasis`
- `cjguiInternalBuildRendererMaterialGroupingScope`
- `cjguiInternalBuildRendererHintPreservationPolicy`
- `cjguiInternalBuildRendererNoSortNoMergeGate`
- `cjguiInternalBuildRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft`

## Boundary Conclusion

该 boundary 回到 command packet / normalized packet 的非 diagnostics 路线，补强以下 backend-agnostic value facts：

- ordering basis：只说明 normalized ordering facts 的 value basis，不执行真实排序。
- material grouping scope：只说明 material / batch hint 的 value scope，不做真实绘制合并或图形合批。
- hint preservation policy：只说明 material / ordering / invalidation hints 如何被保留，不改 packet。
- no-sort-no-merge gate：明确当前没有排序副作用、没有合并副作用、没有 packet mutation、没有 renderer state write、没有绘制许可。
- hardening result：只表示 internal ordering / grouping hardening facts 成立，不代表 downstream handoff、后端许可或渲染许可。

Default draft 只串联：

1. `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft()`
2. `cjguiInternalBuildRendererPacketOrderingBasis(...)`
3. `cjguiInternalBuildRendererMaterialGroupingScope(...)`
4. `cjguiInternalBuildRendererHintPreservationPolicy(...)`
5. `cjguiInternalBuildRendererNoSortNoMergeGate(...)`
6. `cjguiInternalBuildRendererPacketOrderingHardeningResult(...)`

## Stop-line

本轮没有：

- 修改 `runtime_state.cj`。
- 修改 `runtime/cjgui/cjpm.toml`。
- 触碰 smoke / harness / native bridge / entry / AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 新增 public symbol。
- 复用旧 `runtime_renderer_handoff.cj` 的 handoff receipt 语义。
- 新增 handoff receipt / record / publication。
- 接入 backend、command buffer、renderer state write 或 render execution。
- 执行真实 sorting side effect。
- 执行 draw-call merge / GPU batching。
- 接入 Metal / AppKit / platform resource。
- 做 dirty-region / diff / patch / incremental render。
- 实现 Widget / Layout / Text / IME / Accessibility。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过新增不可替代语义生效：

- 不是把 `CjguiInternalRendererPacketNormalizationResult` 包成 receipt / record / publication。
- 不是 post-normalization handoff wrapper。
- 不是旧 `CjguiInternalRendererPacketHandoffReceipt` 语义复用。
- 新增语义集中在 ordering basis、material grouping scope、hint preservation policy、no-sort-no-merge gate。

如果下一轮继续推进，必须先判断 `CjguiInternalRendererPacketOrderingHardeningResult` 是否已经足够作为当前 endpoint。不得默认继续新增 ordering readiness、hardening receipt、publication 或 handoff wrapper。

## GitNexus

执行前 impact upstream：

- `CjguiInternalRendererPacketNormalizationResult`：risk `LOW`，direct `1`，affected processes `0`。
- `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft`：risk `LOW`，direct `0`，affected processes `0`。

执行后 `detect_changes(scope=unstaged)`：

- risk：`low`。
- changed files：`7` indexed files。
- changed symbols：`19` indexed documentation sections。
- affected processes：`0`。
- note：`runtime_renderer_packet_ordering.cj` 是本轮新增 owner，属于近期未索引源码；本轮用源码存在、build、smoke、forbidden scan 与 stop-line source scan 兜底。

## Verification

- `cjpm build --target-dir /tmp/cjgui-renderer-command-packet-ordering-material-grouping-hardening-target --skip-script`：通过。当前 shell 未直接暴露 `cjpm`，验证使用工具链绝对路径并临时加入 `cjc` 所在 PATH；最终输出 `cjpm build success`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，auto-close log assertions passed。
- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- closure reachability check：通过，README / GUI_TASK_TRACKER / docs/plans README / runtime README 均能找到 closure 与 next opening。
- forbidden check：通过，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- stop-line source scan：通过，新 owner 未命中 backend / command buffer / render execution / draw call / GPU batching / Metal / AppKit / platform resource / C ABI / native handle / raw pointer / `public` / module-level `var` / real sorting side effect / merge implementation 等 forbidden terms。

## Next Opening

`P1 internal Renderer command packet ordering / material grouping hardening closure / next renderer packet boundary decision`
