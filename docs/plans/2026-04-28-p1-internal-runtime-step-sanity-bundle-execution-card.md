# P1 Internal Runtime Step Sanity Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W1 bundled internal slice

authority：

- [2026-04-28-p1-first-internal-runtime-step-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-first-internal-runtime-step-bundle-closure-review.md)

## Goal

授权后续 2 个 internal-only slices，为第一条默认 internal `cjguiInternalRuntimeStep` 建立最小 sanity helper，并在 bundle 结束时封账 step sanity。

目标不是实现 app run、event loop、queue / drain 或 window create，而是验证现有 root ready path 进入 first internal runtime step 后能形成 `didAdvance=true` 的脱水 sanity 结果。

## Owner Choice

owner 文件：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`

owner 选择理由：

- `runtime_state.cj` 已拥有 `CjguiInternalRuntimeRootState`、root state builder、root ready sanity helper、`CjguiInternalRuntimeStepResult` 与 `cjguiInternalRuntimeStep`。
- step sanity 只消费 root state 与 first internal runtime step，不拥有 platform object truth、app lifecycle truth 或 window lifecycle truth。
- 同 package 内继续保持默认 internal symbols，不新增 package、public runtime API 或 public C ABI。

## Slice A: Runtime Step Ready Sanity Helper

允许后续 Slice A 在 `runtime/cjgui/src/runtime_state.cj` 新增默认 internal helper function。

建议命名：

- `cjguiInternalRuntimeStepReadySanity`

建议签名：

- 输入：无
- 输出：`Bool`

建议行为：

- 调用 `cjguiInternalBuildRuntimeRootState()`。
- 调用 `cjguiInternalRuntimeStep(root)`。
- 返回 `step.didAdvance`。

Slice A 不得改变 step behavior、root state shape、builder behavior、constructor shape、projection behavior、coordination behavior 或 bootstrap behavior。

## Slice B: Runtime Step Sanity Bundle Closure / No Further Helper Chain

Slice B 默认只做 bundled closure / mini-compaction。

要求：

- 不继续堆 helper。
- closure 中记录 step ready sanity 已足够覆盖当前最小 ready path。
- closure 中明确下一步应转向 first internal runtime tick input / step input boundary，或更大的 runtime slice decision。

除非发现现有 Slice A helper 无法表达最小 ready path，否则 Slice B 不新增 runtime helper function。

## Allowed Write Set

后续 implementation / closure slices 只允许按需修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- bundle 完成后：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-step-sanity-bundle-closure-review.md`
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`

## Bundle Forbidden

- 不接入 AppKit / Metal / Objective-C。
- 不暴露 platform object / native handle / raw pointer。
- 不实现 event loop / callback binding / queue / drain。
- 不实现 app run / shutdown。
- 不实现 window create / close / destroy / release。
- 不新增 handle table / generation。
- 不新增 public runtime API。
- 不新增 public C ABI。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` / `package_anchor.cj`。
- 不修改 `labs/macos_bridge_smoke`。
- 不改变现有 state shape / constructor shape / projection / coordination / bootstrap / step behavior。

## Bundle Verification

每个 implementation slice 完成后都必须独立运行：

- `cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`
- `cjpm build --target-dir /tmp/<slice-specific-target> --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

建议 target：

- Slice A：`/tmp/cjgui-internal-runtime-step-sanity-bundle-slice-a-target`
- Slice B：`/tmp/cjgui-internal-runtime-step-sanity-bundle-slice-b-target`

bundle 结束后还必须检查 forbidden 文件未改：

- `runtime/cjgui/cjpm.toml`
- `labs/macos_bridge_smoke`
- harness
- native bridge
- 仓颉入口

## Slice Logging And Closure

- Slice A 完成后只更新 `GUI_TASK_TRACKER.md` 简短日志，不新增独立 closure review。
- Slice B 完成且 bundle 两个 slices 都完成后，新增一份 bundled closure / mini-compaction。
- bundled closure 只记录 Slice A、Slice B、验证结果、守住的 forbidden 边界和 next opening。

## Next Implementation Expectation

下一轮默认进入：

- `P1 internal runtime step sanity bundle slice A`

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不得继续创建新的 preflight / execution card 替代 Slice A 实现。
