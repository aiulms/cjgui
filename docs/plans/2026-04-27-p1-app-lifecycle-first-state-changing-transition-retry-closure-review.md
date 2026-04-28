# P1 App Lifecycle First State-changing Transition Retry 封账复盘

日期：2026-04-27

性质：bounded implementation closure / W1 light slice

状态：完成

## 授权依据

- [2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md)

## 查证来源

- [function/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/function/README.md)
- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

确认点：

- 普通顶层函数默认不是 `public`。
- 函数可以接收并返回 struct value。
- 当前 `CjguiInternalAppLifecycleState` 已通过上一轮 initialization shape 具备无参和带参构造。
- 带参构造可用于保留 `isStateMachineActive` 并只推进 `hasLifecyclePhase`。

## 落地现实

本轮在 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 新增默认 internal 函数：

```cj
func cjguiInternalAppLifecyclePhaseMarkerTransition(
    state: CjguiInternalAppLifecycleState
): CjguiInternalAppLifecycleState {
    CjguiInternalAppLifecycleState(state.isStateMachineActive, true)
}
```

该函数只证明 runtime package 可以承载第一条真实但无副作用的 internal app lifecycle state-changing transition。它保留输入 state 的 `isStateMachineActive`，并只把 returned state 的 `hasLifecyclePhase` 推进为 `true`。它不定义 phase taxonomy，不实现 run / shutdown / request quit / queue / drain，也不绑定 platform adapter、window lifecycle 或 error strategy。

## 实际修改文件

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-retry-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-first-state-changing-transition-retry-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Build / Smoke 结果

构建命令：

```sh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-app-lifecycle-first-state-changing-transition-retry-target --skip-script
```

结果：退出码 `0`，输出 `cjpm build success`。编译器报告当前 internal `init` / transition functions 未使用 warning；当前仍未授权 caller，这是预期。

Smoke guard：

```sh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：退出码 `0`，输出 `auto-close log assertions passed`。

## 必要标记

- `state_changing_transition_added=true`
- `transition_name=cjguiInternalAppLifecyclePhaseMarkerTransition`
- `input_type=CjguiInternalAppLifecycleState`
- `output_type=CjguiInternalAppLifecycleState`
- `only_state_change=hasLifecyclePhase_false_to_true`
- `preserves_is_state_machine_active=true`
- `is_state_machine_active_forced_true=false`
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
- `behavior_scope=internal_phase_marker_only`
- `public_present=false`
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

## Stop-Line Review

已守住：

- 不新增字段。
- 不新增 enum、`Result` type、string code、int code、category、severity 或 phase taxonomy。
- 不修改 no-op transition function。
- 不把 `isStateMachineActive` 强制改成 `true`。
- 不做 `run` / `shutdown` / `request quit` / `queue` / `drain`。
- 不做 platform adapter callback binding。
- 不做 window lifecycle behavior。
- 不做 error strategy behavior。
- 不做 public runtime API。
- 不做 public C ABI。
- 不加入 AppKit / Metal / Objective-C reference。

## 残留风险

- 当前只证明包内可以表达一个极窄 internal phase marker transition，不证明真实 app lifecycle state machine。
- lifecycle phase taxonomy、caller responsibility、idempotency、late message、queue / drain interaction 和 shutdown policy 仍未定义。

## 当前下一步 opening

`P1 app lifecycle first state-changing transition closure / app lifecycle mini-slice compaction`

本轮不会自动开启下一步。
