# P1 App Lifecycle State Construction 封账复盘

日期: 2026-04-27

性质: implementation first slice closure / fail-closed after compile probe

状态: blocked / fail-closed

## 授权依据

- [2026-04-27-p1-app-lifecycle-state-construction-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-execution-card.md)

## 工具链 / 语法来源

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [function/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/function/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

确认点:

- `struct` 可以定义显式 `init(params) { ... }`。
- 构造函数体负责初始化未初始化字段。
- 当前 `CjguiInternalAppLifecycleState` 的两个字段均为带默认值的 `let` 字段。
- 在当前字段形态下，显式 `init` 中执行 `this.isStateMachineActive = isStateMachineActive` 和 `this.hasLifecyclePhase = hasLifecyclePhase` 会被编译器判定为给不可变值赋值。

## Baseline

修改前确认:

- `CjguiInternalAppLifecycleState` 没有显式 `init`。
- 上一轮 `P1 app lifecycle first state-changing transition first slice` fail-closed 的直接原因是无法在已授权范围内构造 `hasLifecyclePhase = true` 的新 state。
- Baseline build: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-construction-baseline-target --skip-script` 成功，输出 `cjpm build success`，并报告既有 `cjguiInternalNo0pAppLifecycleTransition` unused warning。

## Compile Probe

本轮曾按执行卡建议尝试加入最小显式 `init`:

```cj
init(isStateMachineActive: Bool, hasLifecyclePhase: Bool) {
    this.isStateMachineActive = isStateMachineActive
    this.hasLifecyclePhase = hasLifecyclePhase
}
```

编译探针命令:

```sh
cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-construction-probe-target --
skip-script
```

结果: 失败。

关键错误:

```text
cannot assign to immutable value
```

编译器分别指向:

- `this.isStateMachineActive = isStateMachineActive`
- `this.hasLifecyclePhase = hasLifecyclePhase`

结论: 显式 `init` 与当前默认初始化的不可变 `let` 字段形态冲突。本轮执行卡要求"如果显式 `init` 与默认字段初始化冲突，或需要改变字段语义，必须 fail closed"，因此本轮不能硬写。

## 落地现实

本轮没有保留 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 的代码修改。

原因:

- 若保留当前显式 `init`，构建失败。
- 若改掉字段默认初始化、改 `let` 为 `var`、改字段语义、引入 factory 或其他构造策略，均超出本轮"只增加最小构造能力"的已批准 shape。
- 因此本轮按 fail-closed 处理，临时代码已撤回。

## 实际修改范围

- [docs/plans/2026-04-27-p1-app-lifecycle-state-construction-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Build / Smoke 结果

- Final build: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-construction-target --skip-script` 成功，输出 `cjpm build success`，同样只报告既有 unused function warning。
- Smoke guard: `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 退出码为 0，输出 `auto-close log assertions passed`。

## 必要标记

- `state_construction_added=false`
- `constructor_kind=blocked_default_initialized_let_conflict`
- `constructor_params=blocked`
- `constructor_side_effects=false`
- `field_added=false`
- `enum_present=false`
- `result_type_present=false`
- `phase_taxonomy_defined=false`
- `state_changing_transition_added=false`
- `no_op_transition_modified=false`
- `default_state_active=false`
- `default_has_lifecycle_phase=false`
- `run_behavior_present=false`
- `shutdown_behavior_present=false`
- `request_quit_behavior_present=false`
- `queue_behavior_present=false`
- `drain_behavior_present=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `public_present=false`
- `import_present=false`
- `platform_object_present=false`
- `appkit_metal_objective_c_reference_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## 禁止文件检查

- 未保留 `runtime/cjgui/src/app_lifecycle.cj` 修改。
- 未修改 `runtime/cjgui/README.md`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 `runtime/cjgui/src/main.cj`。
- 未新增 `runtime/cjgui/src/package_anchor.cj`。
- 未修改 `labs/macos_bridge_smoke` source / harness / native bridge / Cangjie entry。

## Stop-line Review

已守住:

- 不新增字段。
- 不新增 enum、`Result` type 或 phase taxonomy。
- 不新增 state-changing transition function。
- 不修改 no-op transition function。
- 不把默认 state 改成 active。
- 不做 `run` / `shutdown` / `request quit` / queue / drain。
- 不做 platform adapter callback binding。
- 不做 window lifecycle behavior。
- 不做 error strategy behavior。
- 不做 public runtime API。
- 不做 public C ABI。
- 不加入 AppKit / Metal / Objective-C reference。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` 或 `package_anchor.cj`。

## 残留风险

- 当前 state shape 仍没有获批且可编译的方式构造 `hasLifecyclePhase = true` 的新值。
- 下一步需要单独裁决 construction shape：例如是否允许改变字段初始化策略、是否允许可变字段、是否允许受控 factory，或是否改走其他仓颉可编译的不可变 state construction 方案。
- 在 construction shape 冻结前，不应继续尝试真实 state-changing transition。

## 当前下一步 opening

`P1 app lifecycle state construction fail-closed / constructor shape decision`

本轮不会自动开启下一步。
