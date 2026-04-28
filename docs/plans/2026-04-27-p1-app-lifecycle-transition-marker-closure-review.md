# P1 App Lifecycle Transition Marker 封账复盘

日期: 2026-04-27

性质: implementation first slice closure / app lifecycle transition marker

状态: 完成

## 授权依据

- [2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-boundary-execution-card.md)

## 工具链 / 语法来源

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

确认点:

- `package` declaration 必须是第一个非空 / 非注释项。
- 普通顶层声明默认是 package-internal visibility, 不需要 `public`。
- 空 `struct Name {}` 是可编译的最小无字段 marker 形式。
- 类型名使用 PascalCase。

## 落地现实

本轮只在 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 新增一个默认 internal 空 marker type:

```cangjie
struct CjguiInternalAppLifecycleTransitionMarker {}
```

它只表达 app lifecycle transition boundary exists but transition behavior is not yet defined。

同步轻量更新 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md), 记录该 marker 的 owner / stop-line。

## 实际修改范围

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-app-lifecycle-transition-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-transition-marker-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## 验证

- 编辑前红灯检查: `CjguiInternalAppLifecycleTransitionMarker` 按预期缺失。
- 编辑前基线 build: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-transition-marker-baseline-target --skip-script` 成功。
- 最终 build: `cjpm build --target-dir /tmp/cjgui-app-lifecycle-transition-marker-target --skip-script` 成功, 输出包含 `cjpm build success`。
- Smoke guard:
`/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 退出码为 0, 并报告 `auto-close log assertions passed`。
- 负向源码检查确认: 新 marker 中没有非注释 `public`、import、function、method、显式 init、额外 field、runtime behavior、public runtime API 或 public C ABI。
- 既有 AppKit / Objective-C 词只保留在既有 forbidden-comment guardrails 中; 新 marker 没有新增 platform object、platform API 或 implementation reference。
- `git diff --check` 通过。
- 已触碰文档的绝对本地链接检查未发现 missing target。
- Closure 可发现性: 本 closure 已从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 和 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 建立索引。

## 必要标记

- `app_lifecycle_transition_marker_added=true`
- `app_lifecycle_transition_marker_name=CjguiInternalAppLifecycleTransitionMarker`
- `transition_behavior_defined=false`
- `state_modified=false`
- `is_state_machine_active_modified=false`
- `field_present=false`
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

## 禁止文件检查

- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 `runtime/cjgui/src/main.cj`。
- 未新增 `runtime/cjgui/src/package_anchor.cj`。
- 未修改 `labs/macos_bridge_smoke` source / harness / native bridge / Cangjie entry。

## 停止线复查 (Stop-line Review)

已守住:

- 不做 state machine。
- 不做 transition behavior。
- 不做 `run` / `shutdown` / `request quit` / queue / drain。
- 不做 platform adapter callback binding。
- 不做 window lifecycle behavior。
- 不做 error strategy behavior。
- 不做 public runtime API。
- 不做 public C ABI。
- 不做 AppKit / Metal / Objective-C reference。

## 残留风险

- `CjguiInternalAppLifecycleTransitionMarker` 只是 marker; 它不证明 transition semantics、transition ordering、idempotence、queue interaction、platform adapter scheduling 或 shutdown policy。
- 未来 no-op transition 出现前, 仍必须单独授权任何 function、method、transition result、state mutation 或 lifecycle behavior。

## 当前下一步 opening

`P1 app lifecycle transition marker closure / first internal no-op transition decision`

本轮不会自动打开该方向。
