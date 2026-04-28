# P1 Internal Runtime Root State Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W1 bundled internal slice

authority：

- [2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-bootstrap-owner-cleanup-bundle-closure-review.md)

## Goal

授权后续 2 个 internal-only slices，基于已有 bootstrap snapshot 建立最小 internal runtime root state。

目标不是实现 runtime 启动，而是新增一个脱水 root state，把：

- bootstrap snapshot。
- runtime 是否满足当前 bootstrap readiness 的 Bool。

组合成一个默认 internal root state summary，供后续 larger runtime slice decision 使用。

## Owner Choice

新 owner 文件：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`

owner 选择理由：

- `runtime_bootstrap.cj` 已拥有 readiness aggregate / bootstrap snapshot summary。
- runtime root state 是 bootstrap 之后的 runtime-level summary，不属于 platform adapter fact / projection owner。
- 新文件使用同一 `package cjgui`，保持默认 internal symbols，不新增 package、public API 或 C ABI。
- root state 只读取 bootstrap snapshot，不拥有 app lifecycle truth、window lifecycle truth 或 platform object truth。

## Slice A: Internal Runtime Root State Type

允许后续 Slice A 新增：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`

文件必须使用：

- `package cjgui`

允许新增一个默认 internal root state type。

建议 shape：

- `bootstrap: CjguiInternalRuntimeBootstrapSnapshot`
- `isRuntimeReady: Bool`

允许提供最小 constructor shape：

- `init(bootstrap: CjguiInternalRuntimeBootstrapSnapshot, isRuntimeReady: Bool)`

Slice A 不得新增 public API / public C ABI，不得实现 runtime behavior，不得改变现有 state shape / constructor shape / projection behavior。

建议命名：

- `CjguiInternalRuntimeRootState`
- 或等价清晰命名。

## Slice B: Internal Runtime Root State Builder

允许后续 Slice B 新增一个默认 internal builder function。

建议行为：

- 调用 `cjguiInternalBuildRuntimeBootstrapSnapshot()` 得到 bootstrap snapshot。
- 使用 `bootstrap.isBootstrapReady` 作为 `isRuntimeReady`。
- 返回 Slice A 的 root state。

Slice B 不得实现 app run、event loop、queue / drain、window create、shutdown 或真实 runtime behavior。

建议命名：

- `cjguiInternalBuildRuntimeRootState`
- 或等价清晰命名。

## Allowed Write Set

后续 implementation slices 只允许按需修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- bundle 完成后：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-internal-runtime-root-state-bundle-closure-review.md`
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`

若实现时只需要同 package 引用，不新增 import。若 Cangjie 语法或 package 可见性出现极窄问题，必须 fail closed 或先做最小 `/tmp` 探针，不得扩到 public surface。

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

- Slice A：`/tmp/cjgui-internal-runtime-root-state-bundle-slice-a-target`
- Slice B：`/tmp/cjgui-internal-runtime-root-state-bundle-slice-b-target`

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

- `P1 internal runtime root state bundle slice A`

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不得继续创建新的 preflight / execution card 替代 Slice A 实现。
