# P1 App Lifecycle Phase Taxonomy Marker 封账复盘

日期: 2026-04-27

性质: bounded implementation closure / W1 light slice

状态: 完成

## 授权依据

- [2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-execution-card.md)
- [2026-04-27-p1-app-lifecycle-mini-slice-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-mini-slice-compaction.md)

## 查证来源

- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

确认点: 顶层 `struct` 可作为空 marker type; 普通顶层声明默认 internal; `package cjgui` 必须保持文件第一条非空 / 非注释语句; 本轮不需要 import、enum、字段、函数或 public 声明。

## 落地现实

本轮只在 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 新增一个默认 internal 空 marker type:

```cj
struct CjguiInternalAppLifecyclePhaseTaxonomyMarker {}
```

它只表达 phase taxonomy boundary exists but taxonomy is not yet defined。它不是 enum, 不携带 string code、int code、category 或 severity, 不修改 state 或 transition functions, 也不实现 state machine、run、shutdown、request quit、queue 或 drain。

## 实际修改文件

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-phase-taxonomy-marker-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

## Build / Smoke 结果

构建命令:

```sh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-app-lifecycle-phase-taxonomy-marker-target --skip-script
```

结果: 退出码 `0`, 输出 `cjpm build success`。编译器仍报告当前 internal init / transition functions unused warning; 本轮没有授权 caller, 这是预期。

Smoke guard:

```sh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果: 退出码 `0`, 输出 `auto-close log assertions passed`。

## 必要标记

- `phase_taxonomy_marker_added=true`
- `phase_taxonomy_marker_name=CjguiInternalAppLifecyclePhaseTaxonomyMarker`
- `phase_taxonomy_defined=false`
- `enum_present=false`
- `string_code_present=false`
- `int_code_present=false`
- `category_present=false`
- `severity_present=false`
- `state_modified=false`
- `transition_modified=false`
- `state_changing_transition_added=false`
- `run_behavior_present=false`
- `shutdown_behavior_present=false`
- `request_quit_behavior_present=false`
- `queue_behavior_present=false`
- `drain_behavior_present=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `public_present=false`
- `import_present=false`
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

- 不定义真实 phase taxonomy、enum、string code、int code、category 或 severity。
- 不修改 `CjguiInternalAppLifecycleState`。
- 不新增字段。
- 不修改 no-op transition 或 phase marker transition。
- 不新增 state-changing transition。
- 不做 `run` / `shutdown` / `request quit` / queue / drain。
- 不做 platform adapter callback binding、window lifecycle behavior 或 error strategy behavior。
- 不做 public runtime API 或 public C ABI。
- 不加入 AppKit / Metal / Objective-C reference。

## 残留风险

- 当前只证明 phase taxonomy marker / placeholder 可编译, 不证明 taxonomy owner、closed/open set、phase naming、transition graph、caller responsibility 或 state machine policy。
- 下一步如果继续 app lifecycle 以外的线, 应按 compaction 建议优先读取本 closure / compaction 和当前 execution card, 避免回灌长历史。

## 当前下一步 opening

`P1 app lifecycle phase taxonomy marker closure / window lifecycle pivot decision`

本轮不会自动开启下一步。
