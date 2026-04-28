# P1 App Lifecycle Phase Taxonomy Execution Card

日期: 2026-04-27

性质: docs-only / W1 short execution card

## Task Intent

创建本卡不等于实现。本卡只授权下一刀最多新增一个默认 internal app lifecycle phase taxonomy marker / placeholder。

## Authority

- [2026-04-27-p1-app-lifecycle-mini-slice-compaction.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-app-lifecycle-mini-slice-compaction.md)

当前 app lifecycle mini-slice 已经有 state、state shape、transition marker、no-op transition 和 phase marker transition。

## Goal

未来 first slice 最多只能在 `runtime/cjgui/src/app_lifecycle.cj` 新增一个默认 internal 空 marker type，推荐语义类似：

```cj
struct CjguiInternalAppLifecyclePhaseTaxonomyMarker {}
```

该 marker 只能表达 `phase taxonomy boundary exists but taxonomy is not yet defined`。

## Write Set

未来 first slice 最大写入范围:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- future closure review
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Stop-line

不允许 enum、string code、int code、category、severity; 不允许修改 `CjguiInternalAppLifecycleState`; 不允许新增字段; 不允许修改 no-op transition 或 phase marker transition; 不允许新增 state-changing transition; 不允许 run / shutdown / request quit / queue / drain; 不允许 platform adapter callback binding、window lifecycle behavior、error strategy behavior、public runtime API、public C ABI、AppKit / Metal / Objective-C 引用; 不允许修改 `cjpm.toml`、新增 `src/main.cj` 或 `package_anchor.cj`; 不允许修改 smoke / harness / native bridge / 仓颉入口。

## Verification

未来 first slice 必须先查证 CangjieSkills / 本地官方文档中的 struct / package / visibility / build 规则，并运行:

- `cjpm build`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

同时检查 marker 为默认 internal、无字段、无 enum、无 public API / C ABI、无 runtime behavior，且 closure review 能从 `GUI_TASK_TRACKER.md` 和 `docs/plans/README.md` 找到。

## Next Implementation Expectation

`P1 app lifecycle phase taxonomy marker first slice`

本卡完成后默认进入 bounded implementation; 除非发现 HIGH / CRITICAL 风险或 authority 冲突，不再开新的 docs-only 入口。
