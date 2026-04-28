# P1 window lifecycle construction + no-op transition closure review

日期: 2026-04-27

类型: closure review / W1 light slice
状态: 完成

## Authority

- [P1 window lifecycle construction + no-op transition execution card]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-window-lifecycle-construction-no-op-transition-execution-card.md)

## Syntax / Probe Sources

查证来源:

- [struct/README.md]
(/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [function/README.md]
(/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/function/README.md)
- [cangjie-regulations/SKILL.md]
(/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

临时探针:

- 路径: `/tmp/cjgui-window-construction-noop-probe`
- 内容: 最小 static package, 验证 `let hasWindowState: Bool` + `init()` + `init(hasWindowState: Bool)` + no-op top-level `func`。
- 结果: `cjpm build --target-dir /tmp/cjgui-window-construction-noop-probe-target --skip-script` exit code 0, `cjpm build success`; 仅有 unused function warnings。

## Landed Reality

- `construction_shape_changed=true`
- `constructor_shape=default_internal_explicit_init_pair:init(),init(hasWindowState:Bool)`
- `immutable_fact_preserved=true`
- `var_present=false`
- `field_added=false`
- `no_op_transition_added=true`
- `no_op_transition_name=cjguiInternalNo0pWindowLifecycleTransition`
- `no_op_transition_returns_input_state=true`

`CjguiInternalWindowLifecycleState` 仍只保留 `hasWindowState` 这一枚 immutable Bool fact。无参构造写入 `false`; 带参构造只写入调用方传入的 `hasWindowState`。新增的 no-op function 接收并返回 `CjguiInternalWindowLifecycleState`，不修改 state。

## Verification

- `cjpm build --target-dir /tmp/cjgui-window-lifecycle-construction-no-op-transition-target --skip-script`
  - exit code: 0
  - 结果: `cjpm build success`
  - 备注: 新增 window `init` / no-op function 和既有 app lifecycle internal functions 均有 unused warnings; 它们不表示行为实现。
- smoke guard:
`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
  - exit code: 0
  - 结果: `auto-close log assertions passed`
- 非注释 source 检查: `window_lifecycle.cj` 只有 package declaration、`CjguiInternalWindowLifecycleState` 的 `let hasWindowState` / two `init` declarations, 以及 `cjguiInternalNo0pWindowLifecycleTransition`。
- `src/main.cj` / `package_anchor.cj`: 未新增。
- `git diff --check`: 通过。

## Stop-Line Review

- `enum_present=false`
- `handle_present=false`
- `handle_table_present=false`
- `generation_present=false`
- `create_behavior_present=false`
- `request_close_behavior_present=false`
- `destroy_behavior_present=false`
- `release_behavior_present=false`
- `platform_object_present=false`
- `native_handle_present=false`
- `raw_pointer_present=false`
- `app_lifecycle_modified=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `public_present=false`
- `import_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## Residual Risks

- no-op transition 只证明 internal function shape 可编译, 不证明 window lifecycle state machine、state-changing transition、create / close / destroy / release 或 handle model。
- 如果下一步要让 window state 发生变化, 必须先裁决唯一允许的 state change, 并继续禁止 handle table / generation 和 platform object leakage。

## Current Next Opening

`P1 window lifecycle construction + no-op transition closure / first state-changing transition decision`

本轮不自动开启下一步实现。
