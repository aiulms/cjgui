# P1 Readiness Coordination Negative-Path Bundle Execution Card

日期：2026-04-28

类型：bundled execution card

task intent：bounded implementation authorization

prompt weight：W1 bundled internal slice

authority：

- [2026-04-28-p1-readiness-state-helper-bundle-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-state-helper-bundle-closure-review.md)

## Goal

授权后续 2 个低风险 internal-only slices，验证并收紧 platform readiness coordination 的 false-path 语义：

- `isPlatformReady=true` 的 positive sanity path 已能确认 app/window 都 observed platform ready。
- 下一步需要同样确认 `isPlatformReady=false` 不会推进 app/window observed platform ready。
- 再新增一个 parity helper，把 positive 与 negative sanity 共同作为 internal sanity summary。

本 bundle 仍保持 internal-only、脱水 Bool facts、无平台对象、无 public runtime API、无 public C ABI。

## Slice A: Negative Platform Readiness Fact Sanity

允许后续 Slice A 新增一个默认 internal helper function：

- 构造 `CjguiInternalPlatformAdapterFact(false)`。
- 构造默认 `CjguiInternalAppLifecycleState()`。
- 构造默认 `CjguiInternalWindowLifecycleState()`。
- 调用 `cjguiInternalCoordinateLifecycleFromPlatformFact`。
- 使用 app/window readiness predicate helpers 判断 app/window 是否都没有 observed platform ready。
- 输出 `Bool`。

Slice A 不得改变 state shape、constructor shape、projection behavior、coordination behavior、public API 或 public C ABI。

建议命名：

- `cjguiInternalLifecycleCoordinationSanityNotObservedPlatformReady`
- 或等价清晰命名。

## Slice B: Readiness Sanity Parity Helper

允许后续 Slice B 新增一个默认 internal helper function：

- 调用 positive sanity helper：`cjguiInternalLifecycleCoordinationSanityObservedPlatformReady()`。
- 调用 Slice A 的 negative sanity helper。
- 只有 positive path 为 `true` 且 negative path 也为 `true` 时返回 `true`。
- 输出 `Bool`。

Slice B 不得改变 projection behavior，不得新增 public API 或 public C ABI。

建议命名：

- `cjguiInternalLifecycleCoordinationReadinessSanityParity`
- 或等价清晰命名。

## Allowed Write Set

后续 implementation slices 只允许按需修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- bundle 完成后：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-28-p1-readiness-coordination-negative-path-bundle-closure-review.md`
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`

## Bundle Forbidden

- 不接入 AppKit / Metal / Objective-C。
- 不暴露 platform object / native handle / raw pointer。
- 不实现 event loop / callback binding / queue / drain。
- 不实现 app run / shutdown。
- 不实现 window create / close / destroy / release。
- 不新增 handle table / generation。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` / `package_anchor.cj`。
- 不修改 `labs/macos_bridge_smoke`。
- 不改变 app/window/platform state shape。
- 不改变 constructor shape。
- 不改变 projection behavior。
- 不新增 public runtime API。
- 不新增 public C ABI。

## Bundle Verification

每个 slice 完成后都必须独立运行：

- `cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`
- `cjpm build --target-dir /tmp/<slice-specific-target> --skip-script`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

建议 target：

- Slice A：`/tmp/cjgui-readiness-coordination-negative-path-bundle-slice-a-target`
- Slice B：`/tmp/cjgui-readiness-coordination-negative-path-bundle-slice-b-target`

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

- `P1 readiness coordination negative-path bundle slice A`

除非发现 HIGH / CRITICAL 风险、authority 冲突或仓颉语法不可成立，不得继续创建新的 preflight / execution card 替代 Slice A 实现。
