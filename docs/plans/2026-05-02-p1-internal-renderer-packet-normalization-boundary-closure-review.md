# P1 internal Renderer packet normalization boundary closure review

日期：2026-05-02

本轮任务：实现 `P1 internal Renderer packet normalization boundary bundle implementation`。

## Landed Scope

新增 owner file：

- `runtime/cjgui/src/runtime_renderer_packet_normalization.cj`

新增 internal value-style symbols：

- `CjguiInternalRendererNormalizedPacketCandidate`
- `CjguiInternalRendererNormalizedOrderingFacts`
- `CjguiInternalRendererNormalizedMaterialGroupingFacts`
- `CjguiInternalRendererPacketNormalizationResult`
- `cjguiInternalBuildRendererNormalizedPacketCandidate`
- `cjguiInternalBuildRendererNormalizedOrderingFacts`
- `cjguiInternalBuildRendererNormalizedMaterialGroupingFacts`
- `cjguiInternalBuildRendererPacketNormalizationResult`
- `cjguiInternalExecuteDefaultRendererPacketNormalizationDraft`

Default draft 只调用 `cjguiInternalExecuteDefaultRendererCommandValidationDraft()` 获取 `CjguiInternalRendererCommandValidationResult`，再构建 normalized packet candidate -> ordering facts -> material grouping facts -> normalization result。

## Boundary Conclusion

`CjguiInternalRendererPacketNormalizationResult` 是本轮 renderer packet normalization endpoint。

它表示 validated command / batching packet 已被投影为 backend-agnostic normalized packet value facts。它不是 backend packet、command buffer、renderer state write、backend permission、render permission、真实排序结果、真实 draw-call merge 或 GPU batching。

本轮没有读取 Queue / Action / Runtime lower-level mutable facts，没有接平台资源，没有新增 public symbol，没有修改 `cjguiExperimentalQueueSubmitShellReady(): Bool`，也没有触碰 `runtime_state.cj`。

## Normalization Semantics

Normalized packet candidate 记录：

- validated command / batching facts 已被保留；
- stable node id、bounds、clip、z-order、material key、version 与 invalidation hint 仍在 value facts 内；
- P1 仍是 full rebuild only；
- candidate 不是 backend packet。

Normalized ordering facts 记录：

- order facts 已被规范化描述；
- ordering facts 只保留 value facts；
- 不执行 sorting side effect；
- 不重排 queue 或 renderer state。

Normalized material grouping facts 记录：

- material grouping 只是 backend-agnostic hints；
- batch key 仍是 hint；
- batching plan 仍是 dehydrated value plan；
- 不做真实 draw-call merge；
- 不做 GPU batching。

Normalization result 记录：

- accepted / deferred / blocked / fail-closed value facts；
- future renderer boundary 可继续评估 normalized packet；
- 不代表 backend permission、render permission 或 command buffer readiness。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮继续生效。

上一阶段 validation manifest 已封账，明确不能继续新增 validation receipt / record / publication。 本轮没有把 `CjguiInternalRendererCommandValidationResult` 包成 receipt 或 record，而是新增 normalization vocabulary、ordering facts 和 material grouping facts。

因此本轮新增语义是 packet shape / ordering / grouping normalization，不是 validation 后的同构尾巴。

## GitNexus Evidence

GitNexus 初始索引 stale，已运行：

- `npx gitnexus analyze`

Impact 结果：

- `CjguiInternalRendererCommandValidationResult`
  - risk：`LOW`
  - direct callers：`1`
  - affected processes：`0`
  - d=1：`cjguiInternalBuildRendererCommandValidationResult`
  - d=2：`cjguiInternalExecuteDefaultRendererCommandValidationDraft`
  - d=3：`cjguiInternalExecuteDefaultRendererPacketNormalizationDraft`
- `cjguiInternalExecuteDefaultRendererCommandValidationDraft`
  - risk：`LOW`
  - direct callers：`1`
  - affected processes：`0`
  - d=1：`cjguiInternalExecuteDefaultRendererPacketNormalizationDraft`

未出现 HIGH / CRITICAL 风险。

## Verification

已运行：

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-packet-normalization-boundary-target --skip-script`
  - 结果：通过；仅有既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - 结果：通过；auto-close log assertions passed。
- `git diff --check`
  - 结果：通过。
- Markdown absolute link missing target check
  - 结果：通过。
- closure reachability check
  - 结果：`README.md`、`GUI_TASK_TRACKER.md` 与 `docs/plans/README.md` 均可找到 closure 与 next opening。
- forbidden check
  - 结果：未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke / harness / native bridge / entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan
  - 结果：唯一 declaration-level public symbol 仍是 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- source stop-line scan
  - 结果：新 owner file 未包含被禁止的平台资源 / 执行性关键词或 public declaration。
- GitNexus `detect_changes(scope=unstaged)`
  - 结果：risk `low`，affected processes `0`。

## Stop-line

本轮保持：

- no platform backend implementation；
- no platform adapter；
- no graphics execution resource；
- no renderer state write；
- no backend packet or command buffer readiness；
- no render permission；
- no sorting side effect；
- no real drawing work / batching / merge；
- no dirty-region / diff / patch / incremental render；
- no Widget / Layout / Text / IME / Accessibility / ECS；
- no Queue / Action / Runtime lower-level mutable facts；
- no public symbol expansion；
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change；
- no `runtime_state.cj` touch。

## Next Opening

建议下一步：

`P1 internal Renderer packet normalization closure / next renderer packet boundary decision`

下一轮应 docs-only 判断 `CjguiInternalRendererPacketNormalizationResult` 之后是否进入 normalization manifest stabilization、validation error taxonomy、packet boundary handoff、packet consolidation，或暂缓 renderer packet runway。

不得继续凭惯性新增 normalization receipt / normalization record / publication 同构尾巴，也不得进入 backend packet、command buffer、render execution、sorting side effect、draw-call merge、GPU batching、dirty-region / diff / patch 或 public surface expansion。
