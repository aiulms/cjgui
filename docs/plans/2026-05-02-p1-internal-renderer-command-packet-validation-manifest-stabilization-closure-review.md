# P1 internal Renderer command packet validation manifest stabilization closure review

日期：2026-05-02

本轮任务：实现 `P1 internal Renderer command packet validation manifest stabilization bundle implementation`。

本轮是 docs / manifest stabilization，不写 runtime code，不修改 `.cj` 文件，不运行 build / smoke。

## Landed Scope

新增 manifest：

- [2026-05-02-p1-renderer-command-packet-validation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-renderer-command-packet-validation-manifest.md)

同步文档：

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md`
- `docs/plans/2026-05-02-p1-renderer-backend-tail-milestone-manifest.md`

## Manifest Conclusion

Command packet validation manifest 固定：

- owner file：`runtime/cjgui/src/runtime_renderer_command_validation.cj`
- upstream facts：`CjguiInternalRenderBatchingPacket` / `CjguiInternalRenderCommandPacket`
- canonical endpoint：`CjguiInternalRendererCommandValidationResult`
- default endpoint：`cjguiInternalExecuteDefaultRendererCommandValidationDraft()`
- current truth：backend-agnostic command / batching packet integrity facts、validation admission / result facts、no-render / no-backend / no-command-buffer validation boundary。

该 endpoint 不是 validation receipt / record / publication，不是 backend shell、platform adapter、Metal / AppKit、command buffer、renderer state write、render permission 或真实 draw / batching。

## Same-shape Boundary Brake

Same-shape Boundary Brake 本轮通过 manifest stabilization 生效。

`CjguiInternalRendererCommandValidationResult` 已足够作为 packet integrity endpoint。继续新增 validation receipt / record / publication 只会把同一 validation result 包成新的尾巴，不会新增 owner truth、consumer、integration 或风险证据。

因此本轮没有新增 runtime owner，也没有继续 shell contract / lifecycle / receipt / record runway。下一阶段只能在 normalization preflight、validation taxonomy、consolidation 或明确 downstream owner 之间重新决策。

## Next Stage Candidate Comparison

### A. P1 internal Renderer packet normalization preflight decision

选择。

Validation endpoint 封账后，可以评估是否需要 backend-agnostic normalized packet facts。该 preflight 必须继续拒绝 sorting side effect、diff / patch、backend packet、command buffer、renderer state write 和 render permission。

### B. P1 internal Renderer validation error taxonomy boundary bundle implementation

暂缓。

当前 validation result 已表达 accepted / deferred / blocked / fail-closed facts。若后续发现 failure reason / degraded taxonomy 不足，再单独开。

### C. P1 internal Renderer command packet validation consolidation bundle implementation

暂缓。

只有发现 duplicate projection、low-value helper、self-wrapping helper 或 dead helper 时才进入。

### D. Validation receipt / record / publication

拒绝。

这正是 Same-shape Boundary Brake 要阻止的同构尾巴。

### E. Backend shell continuation / shell contract / lifecycle

拒绝。

本阶段已从 shell tail 回到 command / batching packet integrity gate，不能马上回到 shell tail。

### F. Metal / AppKit / command buffer / render execution

拒绝。

Validation endpoint 不是平台资源许可或绘制许可。

### G. Dirty-region / Widget / Layout / Text / IME / Accessibility / ECS

暂缓。

P1 仍保持 full rebuild only，相关系统需要独立 owner truth。

### H. Public surface expansion

拒绝。

public allowlist 未变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## Stop-line

本轮保持：

- no runtime code。
- no `.cj` modification。
- no Metal / AppKit / backend implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no stable backend API promise。
- no render / draw call。
- no real draw op / GPU batching / draw-call merge。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS。
- no Queue / Action / Runtime lower-level mutable facts。
- no public symbol expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。

## Verification

已运行：

- `git diff --check`
  - 结果：通过。
- Markdown absolute link missing target check
  - 结果：通过。
- manifest / closure / next opening reachability
  - 结果：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md` 与 `runtime/cjgui/README.md` 均可找到 validation manifest / closure / next opening。
- forbidden tracked diff check
  - 结果：未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke / harness / native bridge / entry、`AGENTS.md`、`CLAUDE.md`、`CANGJIE_ISSUE_LEDGER.md`。
- tracked `.cj` diff check
  - 结果：`0`。
- `wc -l runtime/cjgui/src/runtime_state.cj`
  - 结果：`10065`。
- public declaration scan
  - 结果：唯一 public declaration 仍是 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged)`
  - 结果：risk `low`，affected processes `0`。

本轮未运行 `cjpm build` / smoke guard，因为没有 runtime code change。

## Next Opening

建议下一步：

`P1 internal Renderer packet normalization preflight decision`

下一轮应保持 docs-only，评估 normalization 是否有不可替代语义。若没有清楚 owner truth，应继续选择 manifest / taxonomy / consolidation，而不是新增 validation receipt / record / publication wrapper。
