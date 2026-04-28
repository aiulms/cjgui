# P1 App Lifecycle First State-changing Transition 封账复盘

日期：2026-04-27

性质：implementation first slice closure / fail-closed before runtime edit

状态：blocked / fail-closed

## 授权依据

- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md)

## 工具链 / 语法来源

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [function/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/function/README.md)
- [define_struct.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-original-docs/kernel/source_zh_cn/struct/define_struct.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

确认点：

- 顶层函数默认 `internal`。
- 函数使用 `func name(params): ReturnType { ... }` 语法。
- 当前 `CjguiInternalAppLifecycleState` 没有自定义构造函数，且两个实例字段都有默认值，因此编译器只生成无参构造函数。
- 临时编译探针确认 `ProbeState(false, true)` 和 `ProbeState(hasLifecyclePhase: true)` 都失败，错误为构造函数参数列表期望 `()`。

## 落地现实

本轮没有修改 [app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)。

原因：执行卡只授权新增一个 transition function。要返回 `hasLifecyclePhase = true` 的新 state，当前代码需要额外打开以下至少一种未授权改动：

- 给 `CjguiInternalAppLifecycleState` 增加显式 `init` 或主构造函数。
- 改写 state fields / constructor shape。
- 把 `let` 字段改成可变字段再修改副本。

这些都超出“只新增一个默认 internal state-changing transition function”的 write set，因此本轮按要求 fail closed，没有硬写 runtime。

## 实际修改范围

- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-closure-review.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Build / Smoke 结果

- Baseline build: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-first-state-changing-transition-baseline-target --skip-script` 成功，输出 `cjpm build success`，并报告既有 `cjguiInternalNoOpAppLifecycleTransition` unused warning。
- Final build: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-first-state-changing-transition-target --skip-script` 成功，输出 `cjpm build success`，同样只报告既有 unused warning。
- Smoke guard: `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 退出码为 0，输出 `auto-close log assertions passed`。

## 必要标记

- `state_changing_transition_added=false`
- `transition_name=not_added`
- `input_type=CjguiInternalAppLifecycleState`
- `output_type=CjguiInternalAppLifecycleState`
- `only_state_change=blocked_requires_unapproved_state_construction`
- `is_state_machine_active_set_true=false`
- `phase_taxonomy_defined=false`
- `no_op_transition_modified=false`
- `field_added=false`
- `enum_present=false`
- `result_type_present=false`
- `string_code_present=false`
- `int_code_present=false`
- `category_present=false`
- `severity_present=false`
- `run_behavior_present=false`
- `shutdown_behavior_present=false`
- `request_quit_behavior_present=false`
- `queue_behavior_present=false`
- `drain_behavior_present=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `behavior_scope=blocked_no_runtime_change`
- `public_present=false`
- `import_present=false`
- `platform_object_present=false`
- `appkit_metal_objective_c_reference_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## 禁止文件检查

- 未修改 `runtime/cjgui/src/app_lifecycle.cj`。
- 未修改 `runtime/cjgui/README.md`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 `runtime/cjgui/src/main.cj`。
- 未新增 `runtime/cjgui/src/package_anchor.cj`。
- 未修改 `labs/macos_bridge_smoke` source / harness / native bridge / Cangjie entry。

## Stop-Line Review

已守住：

- 不把 `isStateMachineActive` 改成 true。
- 不定义 phase taxonomy。
- 不定义 enum、`Result` type、string code、int code、category 或 severity。
- 不修改 no-op transition function。
- 不做 `run` / `shutdown` / `request quit` / `queue` / `drain`。
- 不做 platform adapter callback binding。
- 不做 window lifecycle behavior。
- 不做 error strategy behavior。
- 不做 public runtime API。
- 不做 public C ABI。
- 不加入 AppKit / Metal / Objective-C reference。

## 残留风险

- 当前 state shape 还没有获批的方式构造 `hasLifecyclePhase = true` 的新值。
- 下一步必须先决定是否允许为 `CjguiInternalAppLifecycleState` 增加默认 internal 构造边界，或改用其他受控 state construction shape。
- 在 state construction authority 冻结前，不应继续尝试真实 state-changing transition。

## 当前下一步 opening

`P1 app lifecycle state construction authority decision`

本轮不会自动开启下一步。
