# P1 First Internal Runtime Step Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W1 bundled internal slice

authority：

- [2026-04-28-p1-internal-runtime-root-sanity-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-sanity-bundle-closure-review.md)

## Goal

授权后续 2 个 internal-only slices，基于 `CjguiInternalRuntimeRootState` 建立第一条默认 internal runtime step。

目标不是实现 app run、event loop、queue / drain 或 window create，而是在 root state 之上新增一个脱水 step result 与最小 step function，让后续 runtime step 方向有一个 internal-only 起点。

## Owner Choice

owner 文件：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`

owner 选择理由：

- `runtime_state.cj` 已拥有 `CjguiInternalRuntimeRootState`、root state builder 与 root ready sanity helper。
- 第一条 internal runtime step 只消费 root state，不拥有 platform object truth、app lifecycle truth 或 window lifecycle truth。
- 同 package 内继续保持默认 internal symbols，不新增 package、public runtime API 或 public C ABI。

## Slice A: Internal Runtime Step Result Type

允许后续 Slice A 在 `runtime/cjgui/src/runtime_state.cj` 新增默认 internal step result type。

建议命名：

- `CjguiInternalRuntimeStepResult`

建议 shape：

- `state: CjguiInternalRuntimeRootState`
- `didAdvance: Bool`

允许提供最小 constructor shape：

- `init(state: CjguiInternalRuntimeRootState, didAdvance: Bool)`

Slice A 不得新增 public API / public C ABI，不得实现 runtime behavior，不得改变 root state shape、bootstrap behavior、projection behavior 或 coordination behavior。

## Slice B: First Internal Runtime Step Function

允许后续 Slice B 在 `runtime/cjgui/src/runtime_state.cj` 新增默认 internal step function。

建议命名：

- `cjguiInternalRuntimeStep`

建议签名：

- 输入：`state: CjguiInternalRuntimeRootState`
- 输出：`CjguiInternalRuntimeStepResult`

建议行为：

- 不改变输入 state。
- 不改变 state shape。
- 不实现 event loop / callback binding / queue / drain。
- 根据 `state.isRuntimeReady` 返回 `didAdvance=true` 或 `false`。
- 返回原 state 与 didAdvance Bool。

这只是 internal step sanity，不是 app run，不是 public API。

## Allowed Write Set

后续 implementation slices 只允许按需修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- bundle 完成后：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-first-internal-runtime-step-bundle-closure-review.md`
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
- 不改变现有 state shape / constructor shape / projection / coordination / bootstrap behavior。

## Bundle Verification

每个 implementation slice 完成后都必须独立运行：

- `cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`
- `cjpm build --target-dir /tmp/<slice-specific-target> --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

建议 target：

- Slice A：`/tmp/cjgui-first-internal-runtime-step-bundle-slice-a-target`
- Slice B：`/tmp/cjgui-first-internal-runtime-step-bundle-slice-b-target`

bundle 结束后还必须检查 forbidden 文件未改：

- `runtime/cjgui/cjpm.toml`
- `labs/macos_bridge_smoke`
- harness
- native bridge
- 仓颉入口

## Slice Logging And Closure

- Slice A 完成后只更新 `GUI_TASK_TRACKER.md` 简短日志，不新增独立 closure review。
- Slice B 完成且 bundle 两个 slice 都完成后，新增一份 bundled closure / mini-compaction。
- bundled closure 只记录 Slice A、Slice B、验证结果、守住的 forbidden 边界和 next opening。

## Next Implementation Expectation

下一轮默认进入：

- `P1 first internal runtime step bundle slice A`

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不得继续创建新的 preflight / execution card 替代 Slice A 实现。
