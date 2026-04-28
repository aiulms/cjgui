# P1 Platform Adapter Fact Ingestion Execution Card

日期: 2026-04-27

类型: execution card / W1 short card
状态: 完成；创建本卡不等于实现

## Task Intent

从 lifecycle mini-runtime pivot 到 platform adapter fact ingestion。

## Authority

- [P1 lifecycle parity compaction](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-lifecycle-parity-compaction.md)
- [P1 platform adapter boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-boundary-preflight.md)
- [P1 platform adapter surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)

## Goal

未来 first slice 最多只能在
`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
新增一个默认 internal platform adapter fact marker / placeholder type。

推荐形式是空 struct，语义类似 `CjguiInternalPlatformAdapterFact`。该 marker 只能表达
"platform adapter can provide dehydrated facts, but fact shape is not yet defined"。

## Write Set

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-marker-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Forbidden Scope / Stop-Line

不允许字段、AppKit / Metal / Objective-C 引用、platform object、native handle、raw pointer、callback binding、runloop truth、delegate identity、event object、修改 app/window lifecycle state or transitions、public runtime API、public C ABI、run / shutdown / queue / drain、window create / request close / destroy / release、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、修改 `cjpm.toml`、新增 `src/main.cj` 或 `package_anchor.cj`、修改 smoke / harness / native bridge / 仓颉入口。

## Verification

Future first slice 必须:

- 查证 CangjieSkills / 本地官方文档中的 struct / package / visibility / build 规则。
- 运行 `cjpm build --target-dir /tmp/cjgui-platform-adapter-fact-marker-target --skip-script`。
- 运行 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- 检查没有字段、`public`、`import`、platform object / native handle / raw pointer、callback binding、AppKit / Metal / Objective-C 引用、app/window lifecycle 修改、public runtime API 或 public C ABI。
- 检查 `cjpm.toml`、smoke / harness / native bridge / 仓颉入口未修改，并运行 `git diff --check`。

## Next Implementation Expectation

`P1 platform adapter fact marker first slice`

本卡完成后默认进入 bounded implementation；不得再开新的 docs-only 入口，除非发现 HIGH / CRITICAL 风险或 authority 冲突。
