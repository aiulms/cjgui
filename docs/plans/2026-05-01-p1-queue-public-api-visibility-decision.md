# P1 Queue Public API Visibility Decision

日期：2026-05-01

## Scope

本轮是 docs-only decision，不写 runtime code，不创建 execution card。

当前 endpoint 是 `CjguiInternalQueuePublicNoStableCompatibility`，来自 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_exposure.cj`。它只消费 `CjguiInternalQueuePublicEntryResultHandoff`，表达 exposure gate / symbol readiness / naming policy / no-stable-compatibility facts。

当前事实：

- `runtime_queue_public_exposure.cj` 没有 `public` 修饰符。
- `runtime_queue_public_exposure.cj` 没有 `enqueue` 命名。
- `runtime_queue_public_exposure.cj` 没有 raw pointer / native handle intake。
- 当前仍不是 public runtime API。
- 当前仍不是 public C ABI。
- 当前仍不是 real enqueue。
- 当前明确不承诺 stable public API compatibility。
- `runtime_state.cj` 仍为 10065 行 critical warning，本轮不得触碰。

## Visibility Conclusion

选择 C：`P1 internal Queue experimental public submit shell boundary bundle implementation`。

理由：

- Public boundary admission、public surface policy、public API admission、public result shape、public API shell、public exposure gate、naming policy 与 no-stable-compatibility facts 已经形成连续前置链路。
- 继续选择 A milestone 会低风险但容易空转。
- 继续选择 B internal visibility readiness 会更安全，但在 `CjguiInternalQueuePublicNoStableCompatibility` 已经明确记录 no-stable-compatibility、no public modifier 和 no side-effect naming 后，容易变成 Tail Endpoint Exit Gate 反对的薄 wrapper 回潮。
- C 能让 public exposure endpoint 退出 `runtime_queue_public_exposure.cj`，进入新的 downstream owner，同时仍把所有高风险 side effect 关住。

## Public Modifier Decision

下一轮有条件允许出现第一个极窄 `public` 修饰符，但不是无条件批准。

允许范围：

- 只允许一个 extremely narrow experimental submit shell symbol 或等价 shell-facing value boundary。
- 必须仍由新的 owner file 承载，建议 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit.cj`。
- 必须只消费 `CjguiInternalQueuePublicNoStableCompatibility`。
- 必须调用或串联 internal value pipeline，不能绕过 Action Router / Queue gates。
- 必须不承诺 stable public API compatibility。

前置条件：

- 下一轮 implementation 前必须确认仓颉 package visibility 规则。
- 如果 visibility 规则不清楚，必须保持 internal-only symbol，并在 closure 中记录 blocker。
- 即使使用 `public` 修饰符，也只能表示 experimental package-facing submit shell candidate，不是稳定 external API contract。

## Naming Decision

继续禁止 `enqueue` 命名。

下一轮优先使用：

- `submit`
- `submission`
- `queueSubmission`
- `submit shell`

理由：当前仍没有 real enqueue side effect，也没有真实 queue item collection mutation。使用 `enqueue` 会把 internal value facts 误读成实际写队列或稳定用户可见 API。

## Input / Output Shape

输入只能是 dehydrated submission value facts：

- 不接收 raw pointer。
- 不接收 native handle。
- 不接收 platform object。
- 不接收 process-wide queue storage reference。

输出只能是 result envelope / error projection value facts：

- 不直接暴露 lower-level owner facts。
- 不暴露 mutable queue holder。
- 不暴露 runtime global state。
- 不返回 C ABI error handle。

## Rejected Boundaries

本轮明确拒绝：

- D. public C ABI boundary：缺少 stable handle / lifecycle / error ABI。
- E. real enqueue implementation：当前 endpoint 不是 enqueue permission，也没有真实 storage mutation approval。
- F. drain / scheduler / event loop：过早靠近 runtime cycle。
- G. runtime state integration：会靠近 critical `runtime_state.cj` / global runtime state。
- H. tail consolidation：未发现明确 dead helper、重复 projection 或 same-owner self-wrapping，不为 cleanup 而 cleanup。

## Candidate Comparison

A. keep internal-only + milestone / manifest stabilization

- 优点：风险最低。
- 风险：没有 manifest drift 时容易空转，不推进 public shell capability。
- 结论：不选。

B. internal public visibility readiness boundary

- 优点：仍不新增 `public` 修饰符，风险低。
- 风险：`CjguiInternalQueuePublicNoStableCompatibility` 已经覆盖 visibility stop-line、naming policy 和 no-stable-compatibility，再加一层 readiness 容易变成薄 wrapper。
- 结论：不选，但如果下一轮 visibility 规则不清楚，可退回 internal-only implementation 并记录 blocker。

C. first extremely narrow public shell symbol boundary

- 优点：让 exposure endpoint 进入下游 submit shell owner，避免继续在 exposure owner 内自包；同时 public result shape、error contract、naming policy、no-stable-compatibility 和 exposure gate 已经足够支撑极窄 shell candidate。
- 风险：首次接近 `public` 修饰符，必须防止误导为 stable public API。
- 结论：选择。下一轮 opening 是 `P1 internal Queue experimental public submit shell boundary bundle implementation`。

## Stop-Line

下一轮仍必须禁止：

- stable public API compatibility promise。
- `enqueue` 命名。
- public C ABI。
- real enqueue。
- process-wide queue storage write。
- global mutable queue / singleton。
- item collection mutation。
- drain。
- scheduler / event loop / platform callback / runtime cycle。
- runtime global state write。
- raw pointer / native handle / platform object intake。
- touching `runtime_state.cj`。
- modifying `runtime/cjgui/cjpm.toml`。

## Verification Strategy For Next Implementation

下一轮 implementation 至少验证：

- `cjpm build --target-dir /tmp/cjgui-queue-experimental-public-submit-shell-boundary-target --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`
- Markdown absolute link missing target check
- GitNexus impact on `CjguiInternalQueuePublicNoStableCompatibility` and default exposure draft before editing / consuming symbols
- GitNexus detect_changes
- forbidden file check: no `runtime_state.cj`, no `runtime/cjgui/cjpm.toml`, no smoke / harness / native bridge / entry file changes
- public symbol scan: if a `public` modifier appears, it must be only the approved experimental submit shell symbol
- no `enqueue` naming scan
- no C ABI / native handle / raw pointer / platform object intake scan

## Final Decision

Final next opening：

`P1 internal Queue experimental public submit shell boundary bundle implementation`

建议下一轮新建 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit.cj`，只消费 `CjguiInternalQueuePublicNoStableCompatibility`，表达 experimental public submit shell / dehydrated submission value / result envelope handoff facts。是否真的使用 `public` 修饰符，必须在 implementation 前确认仓颉 package visibility 规则；如果不清楚，保持 internal-only 并记录 blocker。
