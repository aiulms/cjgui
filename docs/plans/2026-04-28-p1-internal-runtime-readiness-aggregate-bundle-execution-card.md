# P1 Internal Runtime Readiness Aggregate Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W1 bundled internal slice

authority：

- [2026-04-28-p1-readiness-coordination-negative-path-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-coordination-negative-path-bundle-closure-review.md)

## Goal

授权后续 2 个 internal-only slices，把现有 app/window readiness coordination 能力聚合成一个最小 internal runtime readiness aggregate。

目标不是新增 runtime 行为，而是提供一个脱水 aggregate，把：

- coordination sanity 产出的 app state。
- coordination sanity 产出的 window state。
- readiness parity sanity Bool。

合成一个默认 internal summary，供后续更大 runtime slice 判断当前 skeleton 的 readiness facts 是否自洽。

## Owner Choice

本 bundle 默认把 aggregate 放在 `runtime/cjgui/src/platform_adapter.cj`。

理由：

- 当前 readiness fact 来源与 coordination sanity helper 都在 platform adapter / core boundary 内。
- aggregate 聚合的是 platform readiness fact 投影后的 app/window states 与 parity Bool。
- aggregate 不拥有 app lifecycle state truth，也不拥有 window lifecycle state truth。
- aggregate 不改变 app/window/platform state shape、constructor shape 或 projection behavior。

若后续实现发现 owner 冲突，必须 fail closed，不得自行迁移到新文件或新增 runtime module。

## Slice A: Internal Runtime Readiness Aggregate Type

允许后续 Slice A 新增一个默认 internal aggregate type。

建议 shape：

- `appState: CjguiInternalAppLifecycleState`
- `windowState: CjguiInternalWindowLifecycleState`
- `isReadinessParityClean: Bool`

允许提供最小 constructor shape。

Slice A 不得新增 public API / public C ABI，不得改变现有 state shape / constructor shape / projection behavior。

建议命名：

- `CjguiInternalRuntimeReadinessAggregate`
- 或等价清晰命名。

## Slice B: Internal Runtime Readiness Aggregate Builder

允许后续 Slice B 新增一个默认 internal builder function。

建议行为：

- 调用 `cjguiInternalLifecycleCoordinationSanity()` 得到 app/window state。
- 调用 `cjguiInternalLifecycleCoordinationReadinessSanityParity()` 得到 readiness parity Bool。
- 返回 Slice A 的 aggregate。

Slice B 不得改变 app/window/platform state shape，不得改变 projection / coordination behavior，不得新增 public API / public C ABI。

建议命名：

- `cjguiInternalBuildRuntimeReadinessAggregate`
- 或等价清晰命名。

## Allowed Write Set

后续 implementation slices 只允许按需修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- bundle 完成后：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-readiness-aggregate-bundle-closure-review.md`
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
- 不改变现有 state shape / constructor shape / projection behavior。

## Bundle Verification

每个 slice 完成后都必须独立运行：

- `cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`
- `cjpm build --target-dir /tmp/<slice-specific-target> --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

建议 target：

- Slice A：`/tmp/cjgui-internal-runtime-readiness-aggregate-bundle-slice-a-target`
- Slice B：`/tmp/cjgui-internal-runtime-readiness-aggregate-bundle-slice-b-target`

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

- `P1 internal runtime readiness aggregate bundle slice A`

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不得继续创建新的 preflight / execution card 替代 Slice A 实现。
