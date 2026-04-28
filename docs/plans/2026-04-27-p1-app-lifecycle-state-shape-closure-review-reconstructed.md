# P1 App Lifecycle State Shape 封账复盘

日期: 2026-04-27

## 授权依据

- [2026-04-27-p1-app-lifecycle-state-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-execution-card.md)

## 查证来源

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

## 落地现实

本轮只修改 `CjguiInternalAppLifecycleState`，给它增加一个 immutable Bool 字段:

```cangjie
struct CjguiInternalAppLifecycleState {
    let isStateMachineActive: Bool = false
}
```

该字段只表达最小脱水 state shape: 当前 lifecycle state machine 不处于 active 状态。它不定义 state machine, 不实现 `run` / `shutdown` / `request quit` / queue / drain。

## 实际修改文件

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-state-shape-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## 验证

- 修改前红灯检查: `CjguiInternalAppLifecycleState` 已作为空的默认 internal struct 存在; `isStateMachineActive` 按预期缺失。
- 基线 build: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-shape-baseline-target --skip-script` 退出码为 `0`，输出包含 `cjpm build success`。
- 最终 build:

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-app-lifecycle-state-shape-target --skip-script
```

结果: 退出码为 `0`，输出包含 `cjpm build success`。

- Smoke guard:
`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 退出码为 `0`，输出包含 `auto-close log assertions passed`。
- 非注释语法检查只在 `app_lifecycle.cj` 中发现 `package cjgui`、`struct CjguiInternalAppLifecycleState` 和 `let isStateMachineActive: Bool = false`。
- 未新增 `src/main.cj` 或 `package_anchor.cj`。
- `cjpm.toml` diff 为空。

## 必要标记

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

## 停止线复查 (Stop-line Review)

- 未新增 `public` declaration。
- 未新增 import。
- 未新增 function、method、显式 init、构造逻辑或 runtime behavior。
- 未新增 public runtime API 或 public C ABI。
- 未把 AppKit / Metal / Objective-C reference 加入源码语法。
- 本切片未修改 `cjpm.toml`、smoke source、harness、native bridge 或 Cangjie entry。
- Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、command-list hash、pixel diff、baseline 和 offscreen renderer 仍保持关闭。

## 残留风险

- `isStateMachineActive` 只是最小 compile-level shape field, 不是 lifecycle transition model。
- Idempotence、allowed transitions、queue acceptance、drain ordering、request quit、shutdown 与 adapter-driven lifecycle facts 仍未定义。
- 未来 lifecycle transition boundary 必须决定 state shape 是继续保持 Bool-only, 还是需要更显式的 internal model。

## 当前下一步 opening

`P1 app lifecycle state shape closure / lifecycle transition boundary decision`

这不会自动打开下一轮 implementation。
