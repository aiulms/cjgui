# P1 Platform Adapter Fact Shape Construction Ingestion Execution Card

日期: 2026-04-27

类型: execution card / W1 short card / internal concept slice
状态: 完成；创建本卡不等于实现

## Task Intent

本卡基于 `CjguiInternalPlatformAdapterFact` marker，授权下一刀完成一个 W1 internal concept slice。W1 不等于 one-symbol slice；本卡不是 marker -> field -> constructor -> no-op 的长文档链。

## Authority

- [P1 platform adapter fact marker closure review]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-marker-closure-review.md)
- [P1 platform adapter fact ingestion execution card]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-ingestion-execution-card.md)
- [P1 lifecycle parity compaction]
(/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-lifecycle-parity-compaction.md)

## Goal

未来 first slice 最多只能在
`/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj` 中围绕
`CjguiInternalPlatformAdapterFact` 完成三个小动作：

- 增加最小 immutable Bool fact shape，推荐语义等价于 `hasPlatformFact: Bool = false`。
- 增加构造期初始化能力，且只允许覆盖该 Bool fact。
- 新增一个默认 internal no-op fact ingestion function，接收并返回
  `CjguiInternalPlatformAdapterFact`，不得修改 fact。

## Write Set

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-platform-adapter-fact-shape-construction-ingestion-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## Forbidden Scope / Stop-line

不允许新增第二个字段、enum、`Result`、taxonomy、AppKit / Metal / Objective-C 引用、platform object、native handle、raw pointer、callback binding、runloop truth、delegate identity、event object、修改 app/window lifecycle state or transitions、public runtime API、public C ABI、run / shutdown / queue / drain、window create / request close / destroy / release、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、修改 `cjpm.toml`、新增 `src/main.cj` 或 `package_anchor.cj`、修改 smoke / harness / native bridge / 仓颉入口。

## Verification

Future first slice 必须：

- 查证 CangjieSkills / 本地官方文档中的 struct field / struct init / function / package / visibility / build 规则。
- 先用最小临时探针验证 construction + function 语法。
- 运行 `cjpm build --target-dir /tmp/cjgui-platform-adapter-fact-shape-construction-ingestion-target --skip-script`。
- 运行 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- 检查没有第二字段、`public`、`import`、enum、`Result`、taxonomy、platform object / native handle / raw pointer、callback binding、AppKit / Metal / Objective-C 引用、app/window lifecycle 修改、public runtime API 或 public C ABI。
- 检查 `cjpm.toml`、smoke / harness / native bridge / 仓颉入口未修改，并运行 `git diff --check`。

## Next Implementation Expectation

`P1 platform adapter fact shape + construction + no-op ingestion first slice`

本卡完成后默认进入 bounded implementation；不得再开新的 docs-only 入口，除非发现 HIGH / CRITICAL 风险或 authority 冲突。
