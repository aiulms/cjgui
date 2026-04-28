# P1 First Internal Window Lifecycle State Closure Review

日期: 2026-04-27

性质: bounded implementation / W1 light slice closure

## Authority

- [2026-04-27-p1-first-internal-window-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-window-lifecycle-state-execution-card.md)

## Syntax / Governance Sources

本轮查证来源:

- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

确认点:

- 空 `struct Name {}` 是合法顶层 struct 形态。
- 普通顶层声明默认 `internal`。
- `package cjgui` 仍是文件第一条非空 / 非注释语句。

## Landed Reality

实际修改文件:

- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-first-internal-window-lifecycle-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-window-lifecycle-state-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

新增 marker:

- `CjguiInternalWindowLifecycleState`

该 marker 是默认 internal 空 struct, 只表达:

> window lifecycle state boundary exists but window state machine is not yet defined.

## Required Flags

- `window_lifecycle_state_marker_added=true`
- `window_lifecycle_state_marker_name=CjguiInternalWindowLifecycleState`
- `window_state_machine_defined=false`
- `field_present=false`
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
- `import_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## Build Result

命令:

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-first-internal-window-lifecycle-state-target --skip-script
```

结果:

- exit code: `0`
- `cjpm build success`
- 仅出现既有 `app_lifecycle.cj` unused function warnings; 本轮未新增函数。

## Smoke Guard

命令:

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果:

- exit code: `0`
- `auto-close log assertions passed`
- smoke guard 仍只是旧 smoke 链路 guard, 不是正式 runtime test framework。

## Forbidden File Check

本轮未修改:

- `runtime/cjgui/cjpm.toml`
- `labs/macos_bridge_smoke/`
- harness
- native bridge
- 仓颉入口
- app lifecycle state / transitions

## Stop-Line Review

已守住:

- 未新增字段、enum、handle、handle table 或 generation。
- 未实现 window create、request close、destroy 或 release。
- 未引入 platform object、native handle、raw pointer、AppKit、Metal 或 Objective-C 引用。
- 未定义 public runtime API 或 public C ABI。
- 未进入 Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router。

## Residual Risks

- 当前只有 window lifecycle state marker, 没有 window state shape。
- window state machine、create / request close / destroy / release 仍未定义。
- handle table / generation 仍关闭; 只有出现 public handle、多窗口、target update、async UI message targeting、destroyed-target identity reuse 或跨线程 target validation 时才可重新开启。

## Current Next Opening

`P1 first internal window lifecycle state closure / window state shape decision`

本轮不自动开启下一步。
