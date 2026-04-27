# P1 App Lifecycle State Shape Closure Review

日期：2026-04-27

## Authority

- [2026-04-27-p1-app-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-execution-card.md)

## 查证来源

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

## Landed Reality

本轮只修改 `CjguiInternalAppLifecycleState`，给它增加一个不可变 Bool 字段：

```cangjie
struct CjguiInternalAppLifecycleState {
    let isStateMachineActive: Bool = false
}
```

该字段只表达最小脱水 state shape：当前 lifecycle state machine 不处于 active 状态。它不定义 state machine，不实现 `run` / `shutdown` / `request quit` / queue / drain。

## 实际修改文件

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Verification

- Pre-change red check: `CjguiInternalAppLifecycleState` existed as an empty default-internal struct; `isStateMachineActive` was expected-missing.
- Baseline build: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-shape-baseline-target --skip-script` exited `0`, output included `cjpm build success`.
- Final build:

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-shape-target --skip-script
```

Result: exit code `0`, output included `cjpm build success`.

- Smoke guard: `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` exited `0`, output included `auto-close log assertions passed`.
- Non-comment syntax check for `app_lifecycle.cj` only found `package cjgui`, `struct CjguiInternalAppLifecycleState`, and `let isStateMachineActive: Bool = false`.
- No `src/main.cj` or `package_anchor.cj` was added.
- `cjpm.toml` diff is empty.

## Required Flags

- `app_lifecycle_state_shape_refined=true`
- `added_field_name=isStateMachineActive`
- `added_field_type=Bool`
- `added_field_default=false`
- `state_machine_defined=false`
- `run_behavior_present=false`
- `shutdown_behavior_present=false`
- `request_quit_behavior_present=false`
- `queue_behavior_present=false`
- `drain_behavior_present=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `behavior_code_present=false`
- `function_present=false`
- `method_present=false`
- `explicit_init_present=false`
- `import_present=false`
- `platform_object_present=false`
- `appkit_metal_objective_c_reference_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## Stop-line Review

- No `public` declaration was added.
- No import was added.
- No function, method, explicit init, constructor logic, or runtime behavior was added.
- No public runtime API or public C ABI was added.
- No AppKit / Metal / Objective-C reference was added as source syntax.
- No `cjpm.toml`, smoke source, harness, native bridge, or Cangjie entry change was made by this slice.
- Renderer / Scene / Widget / Layout / DSL, Text / Input / IME / Accessibility, semantic tree / Action Router, command-list hash, pixel diff, baseline, and offscreen renderer remain closed.

## Residual Risks

- `isStateMachineActive` is only a minimal compile-level shape field; it is not a lifecycle transition model.
- Idempotence, allowed transitions, queue acceptance, drain ordering, request quit, shutdown, and adapter-driven lifecycle facts remain undefined.
- A future lifecycle transition boundary must decide whether the state shape remains Bool-only or needs a more explicit internal model.

## Current Next Opening

`P1 app lifecycle state shape closure / lifecycle transition boundary decision`

This does not automatically open the next implementation.
