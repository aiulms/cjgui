# P1 experimental public submit shell milestone manifest

## Scope

本 manifest 将第一次 experimental public submit shell 与 Bool result hardening 封为 milestone。它只记录当前 public submit shell 的允许范围、结果契约和 stop-line，不新增 runtime code，也不批准第二个 public symbol。

## Public symbol allowlist

当前唯一允许的 public symbol allowlist：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

该 symbol 位于 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit.cj`。它是 extremely narrow experimental submit shell readiness projection，不暴露 internal owner facts。

## Milestone truth

- 这是 experimental public submit shell，不是 stable public API。
- 当前不承诺 stable public API compatibility。
- 当前不允许新增第二个 public symbol。
- 当前不允许 structured public return。
- 当前不允许修改 `cjguiExperimentalQueueSubmitShellReady(): Bool` 的 Bool-only signature。

## Bool-only result contract

- Bool-only result 只投影 readiness。
- Bool-only result 不返回 structured result。
- Bool-only result 不暴露 `runtime_queue_public_submit.cj`、`runtime_queue_public_submit_result.cj` 或更低层 owner facts。
- `true` 只能表示当前 internal experimental submit shell readiness facts 允许 Bool readiness projection。
- `false` / non-ready path 必须继续覆盖 defer / blocked / rejected / incompatible / unauthorized / inconsistent facts，不得伪造 ready success。

## No-stable-compatibility

- 当前没有 stable public API compatibility promise。
- 当前 public shell name、Bool-only result、diagnostic projection 和 internal value pipeline 都仍处于 P1 experimental runway。
- 任何未来 compatibility promise 都必须先经过新的 visibility / compatibility / result-shape decision。

## No-enqueue / no-queue-write guarantee

- 当前不使用 `enqueue` 命名。
- 当前不 real enqueue。
- 当前不写 process-wide queue storage。
- 当前不创建 global mutable queue / singleton。
- 当前不做 item collection mutation。

## Stop-line

继续禁止：

- no public C ABI。
- no raw pointer / native handle / platform object intake。
- no drain / scheduler / event loop / platform callback。
- no runtime cycle。
- no runtime global state write。
- no `runtime_state.cj` modification。
- no public audit log writer。
- no observer callback。
- no AI provider / prompt / external agent / model session。

## Next direction

下一步不默认扩第二个 public symbol。若未来要扩 public surface，必须先做新的 visibility / compatibility / result-shape decision，并重新确认：

- 是否仍保持 Bool-only signature。
- 是否允许 structured public result。
- 是否允许第二个 public symbol。
- 是否继续保持 no-stable-compatibility。
- 是否仍禁止 public C ABI、real enqueue、queue write、drain、scheduler / event loop、runtime cycle 和 `runtime_state.cj` 修改。

Recommended next opening:

`P1 internal Queue experimental public submit shell milestone closure / next public surface expansion decision`
