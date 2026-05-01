# P1 Queue Public API Shape Preflight Decision

日期：2026-05-01

## 当前事实

- `P1 internal Queue public surface policy boundary bundle implementation` 已完成，owner file 为 [runtime_queue_public_surface.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_surface.cj)。
- 当前 endpoint 是 `CjguiInternalQueuePublicApiReadinessCandidate`。
- 它只消费 `CjguiInternalQueuePublicBoundaryReadiness`，表达 public surface policy / compatibility / error contract / audit requirement / api-readiness candidate value facts。
- 当前仍不是 public API implementation，不是 public C ABI，不是 real enqueue。
- 仍未写 process-wide queue storage，未创建 global mutable queue，未做 item collection mutation，未 drain，未接 scheduler / event loop / runtime cycle。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## 候选比较

- A. milestone / manifest stabilization：风险最低，但当前 manifest / README 已跟上 public-surface endpoint；若只 stabilization，会让 public API-boundary 继续文档空转。
- B. public API shape preflight：选择。它先固定 public API 命名、输入输出、错误返回、compatibility promise、permission / audit linkage、rollback linkage 与 verification strategy，不实现 public API / C ABI / real enqueue。
- C. internal public API admission value boundary：暂缓为下一刀 implementation。当前应先完成 API shape preflight，避免把 internal readiness 误读成 API contract；preflight 后可作为 bounded implementation 打开。
- D. direct public runtime API implementation：拒绝。当前缺少 API shape preflight、compatibility strategy、error return model、versioning 与 tests。
- E. public C ABI boundary：拒绝。C ABI 需要稳定 runtime handle、lifecycle 与 error ABI，当前风险高于 internal value facts。
- F. real enqueue：拒绝。`CjguiInternalQueuePublicApiReadinessCandidate` 不是 enqueue permission，也不授权 queue storage write。
- G. drain / scheduler / event loop：拒绝。当前仍未进入 queue drain、scheduler 或 runtime cycle owner。
- H. runtime state integration：拒绝。它会靠近 critical `runtime_state.cj` 与 runtime global state write。
- I. tail consolidation：不选。未发现明确 dead helper、重复 projection 或 same-owner self-wrapping；不为 cleanup 而 cleanup。

## Public API Shape Preflight

- 命名：暂不使用 `enqueue` 作为 public API 名称，因为它会承诺真实 enqueue side effect。下一刀优先使用 `public API submission request`、`queueSubmission`、`submit intent` 或 `public API admission` 术语。
- 输入：只能是 dehydrated intent / submission value facts，不能接受 raw pointer、native handle、platform object、callback 或外部 mutable reference。
- 输出：只能是 admission / accepted / deferred / blocked / rejected / incompatible / unauthorized value result；不得返回真实 enqueue record、queue item handle、scheduler task 或 runtime state reference。
- Compatibility：当前不承诺 stable public API compatibility promise；compatibility 只能作为 internal value facts 记录。
- Gate linkage：任何 future public-facing request 必须经过 Action Router / Queue gates，不能绕过 `CjguiInternalQueuePublicApiReadinessCandidate` 之前的 pipeline。
- Error model：错误从 `CjguiInternalQueuePublicErrorContract` 投影为 value result，不暴露真实 runtime error surface 或 C ABI error layout。
- Audit / rollback：audit requirement、permission linkage、rollback linkage 必须保留现有 facts；不得创建 public audit log、observer callback 或 rollback side effect。
- Verification：下一轮 implementation 需运行 build、smoke、diff、link、forbidden guard，并额外检查 no C ABI、no native handle/raw pointer、no runtime_state touch、no real enqueue、no drain / scheduler / event loop。

## Decision

本轮选择 B，完成 public API shape preflight；preflight 结论允许下一轮进入 bounded internal value implementation：

> `P1 internal Queue public API admission value boundary bundle implementation`

下一轮默认新建 `runtime/cjgui/src/runtime_queue_public_api_admission.cj` 或等价 owner file，只消费 `CjguiInternalQueuePublicApiReadinessCandidate`。

下一轮只能表达：

- internal-only public API submission request facts
- public API admission / rejection facts
- public API value result facts
- public API readiness facts

下一轮仍不得实现 public runtime API、public C ABI、real enqueue、process-wide queue storage write、global mutable queue、item collection mutation、drain、scheduler / event loop、platform callback、runtime cycle 或 runtime global state write。

## Verification Plan

- `git diff --check`
- README / GUI_TASK_TRACKER / docs/plans README 均能找到本 preflight 与 next opening。
- Markdown 绝对链接 missing target 检查。
- forbidden 检查：本轮不得修改 runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke tracked source、harness、native bridge、entry、`AGENTS.md`、`CLAUDE.md` 或 `CANGJIE_ISSUE_LEDGER.md`。
- 本轮 docs-only，不运行 `cjpm build` / smoke guard，除非意外修改 runtime code。

## Next Opening

`P1 internal Queue public API admission value boundary bundle implementation`
