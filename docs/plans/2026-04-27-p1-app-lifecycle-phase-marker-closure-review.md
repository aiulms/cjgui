# P1 App Lifecycle Phase Marker 封账复盘

日期: 2026-04-27

性质: implementation first slice closure / internal app lifecycle phase marker field

状态: 完成

## 授权依据

- [2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-execution-card.md)

## 工具链 / 语法来源

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

确认点:

- 普通顶层 struct 默认为 internal。
- struct 内可定义带默认值的不可变 `let` 实例字段。
- Bool 字段命名可使用 `has...` 前缀。

## 落地现实

本轮只修改 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 中既有 `CjguiInternalAppLifecycleState`，新增一个不可变 Bool 字段:

```cangjie
let hasLifecyclePhase: Bool = false
```

该字段只表达 phase boundary exists；lifecycle phase taxonomy 尚未定义。它不定义 enum、`Result` type、string / int code、category、severity、state machine、真实 transition、`run` / `shutdown` / `request quit` / queue / drain，且不改变 no-op transition function。

## 实际修改范围

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-marker-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## 验证

- 编辑前红灯检查: `hasLifecyclePhase` 按预期缺失。
- 编辑前基线构建: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-phase-marker-baseline-target --skip-script` 成功。
- 最终构建: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-phase-marker-target --skip-script` 退出码为 0, 并输出 `cjpm build success`。
- 最终构建警告: 编译器报告既有 `cjguiInternalNoOpAppLifecycleTransition` 未使用; 因为当前仍未授权 caller, 这是预期现象。
- Smoke guard:
  `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 退出码为 0, 并报告 `auto-close log assertions passed`。
- 非注释源码检查只发现 `package cjgui`、`CjguiInternalAppLifecycleState`、`isStateMachineActive`、`hasLifecyclePhase`、`CjguiInternalAppLifecycleTransitionMarker` 和既有 `cjguiInternalNoOpAppLifecycleTransition`。
- Closure 可发现性: 本 closure 已从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 建立索引。

## 必要标记

- `app_lifecycle_phase_marker_added=true`
- `added_field_name=hasLifecyclePhase`
- `added_field_type=Bool`
- `added_field_default=false`
- `phase_taxonomy_defined=false`
- `state_machine_defined=false`
- `no_op_transition_modified=false`
- `is_state_machine_active_modified=false`
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
- `behavior_code_present=false`
- `function_added=false`
- `method_present=false`
- `explicit_init_present=false`
- `import_present=false`
- `platform_object_present=false`
- `appkit_metal_objective_c_reference_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## 禁止文件检查

- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 `runtime/cjgui/src/main.cj`。
- 未新增 `runtime/cjgui/src/package_anchor.cj`。
- 未修改 `labs/macos_bridge_smoke` source / harness / native bridge / Cangjie entry。

## 停止线复查 (Stop-Line Review)

已守住:

- 不定义 lifecycle phase taxonomy。
- 不定义 enum、`Result` type、string code、int code、category 或 severity。
- 不修改 no-op transition function。
- 不让 no-op transition 改变 state。
- 不把 `isStateMachineActive` 改成 true。
- 不做 `run` / `shutdown` / `request quit` / queue / drain。
- 不做 platform adapter callback binding。
- 不做 window lifecycle behavior。
- 不做 error strategy behavior。
- 不做 public runtime API。
- 不做 public C ABI。
- 非注释源码中不出现 AppKit / Metal / Objective-C reference。

## 残留风险

- `hasLifecyclePhase` 只是 compile-level、脱水的 phase marker 字段; 它不证明 phase taxonomy、allowed transitions、transition mutation policy、queue interaction、adapter scheduling 或 shutdown policy。
- 未来第一条真实 transition 仍必须先单独决定 phase taxonomy 是否需要打开, 以及 state mutation、caller responsibility、failure behavior 和 verification shape。

## 当前下一步 opening

`P1 app lifecycle phase marker closure / first real transition readiness decision`

本轮不会自动打开该方向。
