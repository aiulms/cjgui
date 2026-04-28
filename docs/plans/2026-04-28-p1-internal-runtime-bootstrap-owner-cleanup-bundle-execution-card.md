# P1 Internal Runtime Bootstrap Owner Cleanup Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W1 bundled internal cleanup slice

authority：

- [2026-04-28-p1-internal-runtime-bootstrap-draft-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-draft-bundle-closure-review.md)

## Goal

授权后续 2 个 internal-only slices，把当前放在 `platform_adapter.cj` 里的 runtime readiness aggregate / bootstrap snapshot 迁移到更合适的 internal runtime bootstrap owner 文件。

目标是 owner cleanup，不是行为扩展：

- `platform_adapter.cj` 继续作为 platform fact、platform readiness projection、lifecycle coordination 和 adapter-facing readiness sanity helper 的 owner。
- runtime readiness aggregate 与 bootstrap snapshot 迁移到 internal runtime bootstrap owner。
- 不改变任何 existing state shape、constructor shape、projection behavior 或 coordination behavior。
- 不新增 public runtime API 或 public C ABI。

## Owner Cleanup Strategy

新 owner 文件：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_bootstrap.cj`

owner 选择理由：

- readiness aggregate 与 bootstrap snapshot 已经超出单纯 platform adapter fact / projection owner 边界。
- 它们组合的是 runtime-level readiness / bootstrap summary，不拥有 app lifecycle truth、window lifecycle truth 或 platform object truth。
- 新文件使用同一 `package cjgui`，保持默认 internal symbols，不新增 package、public API 或 C ABI。
- `platform_adapter.cj` 仍保留 platform adapter fact、projection、coordination result / function，以及合理属于 adapter-facing summary 的 readiness sanity helpers。

## Slice A: Create Internal Runtime Bootstrap Owner File

允许后续 Slice A 新增：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_bootstrap.cj`

文件必须使用：

- `package cjgui`

Slice A 可以把以下默认 internal symbols 从 `platform_adapter.cj` 移到 `runtime_bootstrap.cj`：

- `CjguiInternalRuntimeReadinessAggregate`
- `cjguiInternalBuildRuntimeReadinessAggregate`
- `CjguiInternalRuntimeBootstrapSnapshot`
- `cjguiInternalBuildRuntimeBootstrapSnapshot`

Slice A 不得改变这些 type / function 的 shape、constructor shape 或行为。

Slice A 可以保留 `CjguiInternalLifecycleCoordinationResult`、platform fact、projection、coordination entry 与 readiness sanity helpers 在 `platform_adapter.cj`。除非实现时发现明确 owner 冲突并在 closure 说明，否则不要迁移这些 adapter-facing symbols。

Slice A 需要同步更新 `runtime/cjgui/README.md`，并运行 build / smoke / diff check。

## Slice B: Owner Boundary Cleanup / Imports If Needed

允许后续 Slice B 做极窄 owner boundary cleanup：

- 确保 moved symbols 仍是默认 internal。
- 确保 `platform_adapter.cj` 只保留 platform fact、projection、coordination sanity / readiness sanity helpers 中合理属于 adapter-facing summary 的部分。
- 若 Cangjie 同 package 不需要 import，不新增 import。
- 若语法或 package 可见性需要极窄调整，只允许在同 package internal 边界内处理。
- 不改变任何函数行为和类型 shape。
- bundle 完成后新增 bundled closure / mini-compaction。

## Allowed Write Set

后续 implementation slices 只允许按需修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_bootstrap.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- bundle 完成后：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-closure-review.md`
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`

## Bundle Forbidden

- 不改变 app/window/platform state shape。
- 不改变 constructor shape。
- 不改变 projection / coordination behavior。
- 不新增 public runtime API。
- 不新增 public C ABI。
- 不接入 AppKit / Metal / Objective-C。
- 不暴露 platform object / native handle / raw pointer。
- 不实现 event loop / callback binding / queue / drain。
- 不实现 app run / shutdown。
- 不实现 window create / close / destroy / release。
- 不新增 handle table / generation。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` / `package_anchor.cj`。
- 不修改 `labs/macos_bridge_smoke`。

## Bundle Verification

每个 slice 完成后都必须独立运行：

- `cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`
- `cjpm build --target-dir /tmp/<slice-specific-target> --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

建议 target：

- Slice A：`/tmp/cjgui-bootstrap-owner-cleanup-bundle-slice-a-target`
- Slice B：`/tmp/cjgui-bootstrap-owner-cleanup-bundle-slice-b-target`

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

- `P1 internal runtime bootstrap owner cleanup bundle slice A`

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不得继续创建新的 preflight / execution card 替代 Slice A 实现。
