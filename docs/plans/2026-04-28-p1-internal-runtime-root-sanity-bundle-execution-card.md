# P1 Internal Runtime Root Sanity Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W1 bundled internal slice

authority：

- [2026-04-28-p1-internal-runtime-root-state-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-state-bundle-closure-review.md)

## Goal

授权后续 2 个 internal-only slices，为 `CjguiInternalRuntimeRootState` 建立最小 ready sanity helper，并在 bundle 完成后封账。

目标不是继续堆 helper 链，也不是实现 runtime step。目标只是让已有 root state builder 的 readiness marker 有一个默认 internal sanity 入口，然后明确下一步应转向 first internal runtime step / step result 方向。

## Slice A: Runtime Root Ready Sanity Helper

允许后续 Slice A 在 `runtime/cjgui/src/runtime_state.cj` 新增默认 internal helper function。

建议行为：

- 调用 `cjguiInternalBuildRuntimeRootState()`。
- 返回 `root.isRuntimeReady`。
- 输出 `Bool`。

建议命名：

- `cjguiInternalRuntimeRootReadySanity`
- 或等价清晰命名。

Slice A 不得改变 root state shape、constructor shape、root state builder behavior、bootstrap behavior、projection behavior 或 coordination behavior。

## Slice B: Runtime Root Sanity Bundle Closure / No Further Helper Chain

Slice B 默认只做 closure / mini-compaction，不继续新增 helper。

如果实现时发现确有必要，可以新增一个默认 internal helper 用于说明 root sanity 与 bootstrap parity 的一致性；但默认选择是不再继续堆 helper chain。

Slice B closure 必须记录：

- root state 已有 ready sanity helper。
- 不继续堆 helper 链。
- 下一步应进入 first internal runtime step / step result 方向，而不是继续 root sanity helper 细分。

## Allowed Write Set

后续 implementation slices 只允许按需修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- bundle 完成后：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-sanity-bundle-closure-review.md`
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

- Slice A：`/tmp/cjgui-internal-runtime-root-sanity-bundle-slice-a-target`
- Slice B：`/tmp/cjgui-internal-runtime-root-sanity-bundle-slice-b-target`

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

- `P1 internal runtime root sanity bundle slice A`

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不得继续创建新的 preflight / execution card 替代 Slice A 实现。
