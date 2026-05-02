# P1 internal Renderer command packet validation boundary closure review

日期：2026-05-02

本轮任务：实现 `P1 internal Renderer command packet validation boundary bundle implementation`。

## Landed Scope

新增 owner file：

- `runtime/cjgui/src/runtime_renderer_command_validation.cj`

新增 internal value-style symbols：

- `CjguiInternalRendererCommandPacketValidation`
- `CjguiInternalRendererBatchingPacketIntegrity`
- `CjguiInternalRendererCommandValidationAdmission`
- `CjguiInternalRendererCommandValidationResult`
- `cjguiInternalBuildRendererCommandPacketValidation`
- `cjguiInternalBuildRendererBatchingPacketIntegrity`
- `cjguiInternalBuildRendererCommandValidationAdmission`
- `cjguiInternalBuildRendererCommandValidationResult`
- `cjguiInternalExecuteDefaultRendererCommandValidationDraft`

Default draft 只调用 `cjguiInternalExecuteDefaultRenderBatchingHintDraft()` 获取 `CjguiInternalRenderBatchingPacket`，再构建 command packet validation -> batching packet integrity -> validation admission -> validation result。

## Boundary Conclusion

`CjguiInternalRendererCommandValidationResult` 是本轮 renderer command packet validation endpoint。

它表示 backend-agnostic command / batching packet 已通过内部 value-fact integrity gate。它不是 backend shell、platform adapter、backend implementation、renderer state write、绘制许可或 command buffer readiness。

本轮没有读取 Queue / Action / Runtime lower-level mutable facts，没有接平台资源，没有新增 public symbol，没有修改 `cjguiExperimentalQueueSubmitShellReady(): Bool`，也没有触碰 `runtime_state.cj`。

## Validation Semantics

Command packet validation 校验：

- full rebuild only；
- stable node id；
- bounds；
- clip；
- z-order；
- material key；
- scene / display / command version facts；
- invalidation / repaint hint；
- placeholder command kind；
- backend-agnostic packet preservation。

Batching packet integrity 校验：

- batch key 仍是 hint；
- ordering hint 不执行排序副作用；
- batching plan 仍是 dehydrated plan；
- no real command merge；
- full rebuild batching；
- no drawing permission。

Open path：

- `CjguiInternalRenderBatchingPacket` ready；
- command packet / batching plan / material / ordering facts 保持 backend-agnostic；
- no defer；
- no blocked；
- validation result accepted。

Defer-only path：

- 保持 defer；
- 不伪造 validation accepted。

Blocked / inconsistent path：

- fail-closed blocked；
- 不伪造 validation success、backend readiness 或绘制许可。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮继续生效。

上一轮 shell next-contract decision 暂缓 shell contract boundary，因为 `runtime_renderer_backend_shell.cj` 已经固定 shell owner truth / vocabulary / entry contract / no platform shell / no stable backend interface promise。

本轮没有继续新增 shell contract / lifecycle / receipt / record wrapper，而是回到 `CjguiInternalRenderBatchingPacket`，建立 command / batching packet integrity gate。新增语义是 packet validation，不是 backend shell tail 自包。

## GitNexus Evidence

编辑前 impact：

- `CjguiInternalRenderCommandPacket`: `UNKNOWN / not found`
- `CjguiInternalRenderBatchingPacket`: `UNKNOWN / not found`
- `cjguiInternalExecuteDefaultRenderCommandShapeDraft`: `UNKNOWN / not found`
- `cjguiInternalExecuteDefaultRenderBatchingHintDraft`: `UNKNOWN / not found`

这与近期 renderer owner files 尚未进入 GitNexus 索引一致。本轮采用 fallback evidence：

- 源码入口存在于 `runtime/cjgui/src/runtime_scene_renderer_input.cj`。
- `cjpm build` 通过。
- smoke guard 通过。
- forbidden scan 确认未触碰 prohibited tracked paths。
- final `detect_changes(scope=unstaged)` 记录风险与 affected processes。

## Verification

已运行：

- `PATH=/Users/jiangxuanyang/cangjie-toolchains/cangjie/bin:/Users/jiangxuanyang/cangjie-toolchains/cangjie/tools/bin:$PATH cjpm build --target-dir /tmp/cjgui-renderer-command-packet-validation-boundary-target --skip-script`
  - 结果：通过；仅有既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - 结果：通过。

最终汇总验证：

- `git diff --check`
  - 结果：通过。
- Markdown absolute link missing target check
  - 结果：通过。
- closure reachability check
  - 结果：`GUI_TASK_TRACKER.md` 与 `docs/plans/README.md` 均可找到 closure 与 next opening。
- forbidden check
  - 结果：未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke / harness / native bridge / entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- public declaration scan
  - 结果：唯一 public declaration 仍是 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
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
- no render permission；
- no real drawing work / batching / merge；
- no dirty-region / diff / patch / incremental render；
- no Widget / Layout / Text / IME / Accessibility / ECS；
- no Queue / Action / Runtime lower-level mutable facts；
- no public symbol expansion；
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change；
- no `runtime_state.cj` touch。

## Next Opening

建议下一步：

`P1 internal Renderer command packet validation closure / next renderer packet validation decision`

下一轮应 docs-only 判断 `CjguiInternalRendererCommandValidationResult` 之后是否进入 validation manifest stabilization、validation hardening、renderer backend shell re-entry、platform abstraction preflight 或 consolidation。

不得继续凭惯性新增 validation receipt / validation record / shell contract 同构尾巴。

## Follow-up Decision Result

Renderer command packet validation next-boundary decision 已完成：

- [2026-05-02-p1-renderer-command-packet-validation-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-next-boundary-decision.md)

Decision：

`P1 internal Renderer command packet validation manifest stabilization bundle implementation`

Reason：

`CjguiInternalRendererCommandValidationResult` 已足够作为 packet integrity endpoint；继续新增 validation receipt / record / publication 会触发 Same-shape Boundary Brake。因此下一刀先做 manifest stabilization，固定 validation owner / truth / canonical endpoint / stop-line，再判断 packet normalization、validation taxonomy 或 consolidation 是否有真实新增语义。
