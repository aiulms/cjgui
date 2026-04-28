# P1 App Lifecycle State Initialization Shape 封账复盘

日期: 2026-04-27

性质: bounded implementation closure / W1 light slice

状态: 完成

## 授权依据

- [2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-execution-card.md)
- [2026-04-27-p1-app-lifecycle-state-construction-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-construction-closure-review.md)

## 查证来源

- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

确认点:

- struct 可以定义普通 init(params) { ... }。
- 构造函数体负责初始化未初始化的实例成员变量。
- 普通顶层声明默认为 internal。
- let 字段可以在构造期初始化; 已有默认值的 let 字段不能在显式 init 中再次赋值。
- package declaration 必须是文件第一条非空 / 非注释语句。

## 临时语法探针

探针目录: `/tmp/cjgui-state-init-shape-probe`

先试探主构造成员参数默认值:

```cj
struct ProbeState {
    ProbeState(let isStateMachineActive: Bool = false, let hasLifecyclePhase: Bool = false) {}
}
```

结果: 失败, 编译器报告 `expected ',' or ')', found '='`。因此没有采用该形态。

随后试探等价构造期初始化 shape:

```cj
struct ProbeState {
    let isStateMachineActive: Bool
    let hasLifecyclePhase: Bool

    init() {
        this.isStateMachineActive = false
        this.hasLifecyclePhase = false
    }

    init(isStateMachineActive: Bool, hasLifecyclePhase: Bool) {
        this.isStateMachineActive = isStateMachineActive
        this.hasLifecyclePhase = hasLifecyclePhase
    }
}
```

探针命令:

```sh
cd /tmp/cjgui-state-init-shape-probe
cjpm build --target-dir /tmp/cjgui-state-init-shape-probe-target --skip-script
```

结果: 退出码 `0`, 输出 `cjpm build success`, 仅报告探针函数 unused warning。探针同时验证了 `ProbeState()` 和 `ProbeState(false, true)` 可编译。

## 落地现实

本轮只修改 `CjguiInternalAppLifecycleState` 的 initialization shape:

- 移除两个字段上的默认值。
- 保留 `let isStateMachineActive: Bool`。
- 保留 `let hasLifecyclePhase: Bool`。
- 增加默认 internal 无参 `init()`, 只写入 `false / false`。
- 增加默认 internal 带参 `init(isStateMachineActive: Bool, hasLifecyclePhase: Bool)`, 只写入两个 Bool facts。

这让默认 state 继续表达 inactive / no lifecycle phase, 同时允许未来内部 transition 构造 `hasLifecyclePhase = true` 的新 state。

## 实际修改文件

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-initialization-shape-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Build / Smoke 结果

构建命令:

```sh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-initialization-shape-target --skip-script
```

结果: 退出码 `0`, 输出 `cjpm build success`。编译器报告两个新 `init` 和既有 no-op transition unused warning; 当前仍未授权 caller, 这是预期。

Smoke guard:

```sh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果: 退出码 `0`, 输出 `auto-close log assertions passed`。

## 必要标记

- `initialization_shape_changed=true`
- `constructor_shape=default_internal_explicit_init_overloads_for_immutable_fields`
- `immutable_facts_preserved=true`
- `var_present=false`
- `field_added=false`
- `default_state_active=false`
- `default_has_lifecycle_phase=false`
- `can_construct_active_phase_state=true`
- `state_changing_transition_added=false`
- `no_op_transition_modified=false`
- `enum_present=false`
- `result_type_present=false`
- `phase_taxonomy_defined=false`
- `run_behavior_present=false`
- `shutdown_behavior_present=false`
- `request_quit_behavior_present=false`
- `queue_behavior_present=false`
- `drain_behavior_present=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## 禁止文件检查

- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 `runtime/cjgui/src/main.cj`。
- 未新增 `runtime/cjgui/src/package_anchor.cj`。
- 未修改 `labs/macos_bridge_smoke` source / harness / native bridge / Cangjie entry。

## Stop-line Review

已守住:

- 不改成 var。
- 不新增字段。
- 不新增 enum、`Result` type 或 phase taxonomy。
- 不新增 state-changing transition function。
- 不修改 no-op transition function。
- 不把 default state 改成 active。
- 不做 `run` / `shutdown` / `request quit` / queue / drain。
- 不做 platform adapter callback binding。
- 不做 window lifecycle behavior。
- 不做 error strategy behavior。
- 不做 public runtime API。
- 不做 public C ABI。
- 不加入 AppKit / Metal / Objective-C reference。

## 残留风险

- 当前只证明 state construction shape 可编译, 不证明真实 transition policy、phase taxonomy、caller responsibility、queue interaction 或 shutdown policy。
- 下一步可以重试第一条 state-changing transition, 但仍必须只允许 `hasLifecyclePhase=false` 到 `true` 的内部最小变化。

## 当前下一步 opening

`P1 app lifecycle state initialization shape closure / retry first state-changing transition`

本轮不会自动开启下一步。
