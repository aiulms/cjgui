# P1 Platform Adapter Fact Marker Closure Review

日期: 2026-04-27

类型: closure review / W1 light slice
状态: 完成

## Authority

- [P1 platform adapter fact ingestion execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-ingestion-execution-card.md)
- [P1 lifecycle parity compaction](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-lifecycle-parity-compaction.md)

## Syntax / Visibility Check Sources

- [Cangjie struct README](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md): `struct Name {}` 顶层定义、结构体体成员范围、默认 `internal` visibility。
- [Cangjie package README](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md): `package` 必须是首个非注释语句，同包声明保持一致。
- [Cangjie regulations SKILL](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md): 类型命名使用 PascalCase，源文件内按 package / imports / type declarations 组织。

## Landed Reality

- `platform_adapter_fact_marker_added=true`
- `platform_adapter_fact_marker_name=CjguiInternalPlatformAdapterFact`
- `fact_shape_defined=false`
- `field_present=false`
- `appkit_metal_objective_c_reference_present=false` as runtime code; existing comments mention these only as forbidden boundary terms.
- `platform_object_present=false`
- `native_handle_present=false`
- `raw_pointer_present=false`
- `callback_binding_present=false`
- `runloop_truth_present=false`
- `delegate_identity_present=false`
- `event_object_present=false`
- `app_lifecycle_modified=false`
- `window_lifecycle_modified=false`
- `public_api_present=false`
- `public_c_abi_present=false`
- `import_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=true`

## Build Result

Command:

```sh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-platform-adapter-fact-marker-target --skip-script
```

Result:

- exit code: `0`
- key stdout / stderr: `cjpm build success`
- warnings: existing unused `init` / internal transition warnings from app/window lifecycle files; no new marker compile error.

## Smoke Guard Result

Command:

```sh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

Result:

- exit code: `0`
- key output: `cjgui verify: auto-close log assertions passed`

## Forbidden File Check

- `runtime/cjgui/cjpm.toml` unchanged.
- `runtime/cjgui/src/main.cj` absent.
- `runtime/cjgui/src/package_anchor.cj` absent.
- `labs/macos_bridge_smoke` unchanged in this slice.
- No app/window lifecycle source edits were made in this slice.

## Stop-Line Review

This slice only proves `runtime/cjgui/src/platform_adapter.cj` can carry one default internal platform adapter fact marker. It does not define fact shape, platform adapter behavior, callback binding, runloop truth, delegate identity, event objects, platform object ownership, public runtime API, or public C ABI.

## Residual Risks

- Platform fact shape is still undefined.
- Existing source comments intentionally mention AppKit / Metal / Objective-C and runloop terms as forbidden boundary language; they are not runtime code.
- The wider worktree remains dirty from prior slices, so future checks should continue to distinguish current-slice edits from pre-existing changes.

## Current Next Opening

`P1 platform adapter fact marker closure / fact shape decision`

Do not auto-open implementation. The next step should decide whether a dehydrated platform adapter fact shape is needed and, if yes, authorize it with a separate short execution card.
