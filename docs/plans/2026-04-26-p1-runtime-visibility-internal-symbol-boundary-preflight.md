# P1 Runtime Visibility / Internal Symbol Boundary Preflight

日期：2026-04-26

性质：docs-only / visibility boundary preflight / internal symbol gate / no runtime code

状态：完成；不批准直接实现

范围：复核 first-compilable runtime source closure 之后，冻结 `runtime/cjgui` 第一批非 package declaration 仓颉 symbol 出现前的 visibility / internal symbol 边界。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写新的仓颉 symbol。

## 1. 本轮依据

直接依据：

- [P1 first compilable runtime source closure / next implementation boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md)
- [P1 first compilable runtime source closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-review.md)
- [P1 first compilable runtime source execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-execution-card.md)
- [P1 runtime build/package metadata closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md)
- [P1 minimal runtime skeleton surface phase closure / compaction preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [Build from zero](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [Local toolchain setup](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [Cangjie issue ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

仓颉 visibility / package / module / test 查证来源：

- [Cangjie language features skill](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [Cangjie package guide](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [Cangjie regulations skill](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

当前 runtime package 只读确认：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

## 2. 当前 Runtime Package 状态

当前 `runtime/cjgui` 已经进入：

```text
strict_comment_only=false
package_declaration_only=true
behavior_code_present=false
public_api_present=false
```

已知事实：

- 四个现有 `runtime/cjgui/src/*.cj` 均已有一致的 `package cjgui` declaration。
- `package cjgui` 是每个文件第一条非空 / 非注释行。
- 除 `package cjgui` 外，四个 `.cj` 文件仍只有注释。
- `cjpm build --target-dir /tmp/cjgui-first-compilable-runtime-source-target --skip-script` 已在 closure review 中通过。
- 未新增 `src/main.cj`。
- 未新增 `package_anchor.cj`。
- 未修改 `cjpm.toml`。
- 未定义函数、类型、import、public runtime API、public C ABI 或 runtime behavior。

因此本轮讨论的是：

> 第一批非 `package cjgui` 的仓颉 symbol 未来是否允许出现、应以什么 visibility 出现，以及出现前需要哪张 execution card。

本轮不写任何 symbol。

## 3. 第一批非 Package Declaration Symbol 是否应该是 Public

结论：不应该。

第一批 runtime symbol 不应为 `public`，理由如下：

- 当前 `cjpm build success` 只证明 package identity / metadata / package-declaration-only source 可被工具链接受，不证明 runtime 能力。
- `public` symbol 会被外部包视为可导入、可依赖、可兼容承诺的 runtime surface。
- 当前 app lifecycle、window lifecycle、platform adapter、error strategy 仍没有行为实现。
- 当前还没有 public runtime API policy、C ABI policy、error return strategy、handle table / generation 或 test boundary。
- 过早 public 会把内部 sanity anchor 伪装成 API，反过来约束未来设计。

因此 future first symbol 的目标若被批准，也只能服务：

```text
internal_package_sanity
```

不能服务：

```text
public_runtime_api
```

## 4. 仓颉 Visibility / Package / Module 规则查证结论

基于 [Cangjie package guide](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)，当前采用以下查证事实：

- `package pkg1.sub1` 必须是文件第一条非空 / 非注释行。
- 同一包中所有文件必须有相同 package declaration。
- `package` 声明需要与相对于 `src/` 的目录路径匹配。
- `src/` 根目录的文件如果没有 package declaration，则默认为 `default` 包。
- `import` 必须位于 `package` 之后、其他声明之前。
- 包是最小编译单元，模块是包的集合。
- `private` 顶层声明只在当前文件可见。
- `internal` 顶层声明在当前包及子包可见。
- `protected` 顶层声明在当前模块可见。
- `public` 顶层声明全局可见。
- `package` 声明默认为 `public`。
- `import` 默认为 `private`。
- 其他顶层声明默认为 `internal`。
- 声明的访问级别不能超过其使用的类型在参数、返回类型、泛型或 where 约束中的访问级别。

基于 [Cangjie regulations skill](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)，当前采用以下工程约束：

- 公共 API 应放在包顶层文件中，内部实现应通过 `internal` / `private` 控制可见性。
- 遵循最小可见性原则，默认使用更窄可见性，按需提升到 `internal`、`protected`、`public`。
- 子目录对应包，包名与目录名一致。
- `package` 声明必须是文件第一条非注释语句。
- 单元测试文件通常命名为 `xxx_test.cj`，与被测文件同目录放置。
- 集成 / 端到端测试可放入 `tests/`。
- 测试使用 `@Test` / `@TestCase`，并通过 `cjpm test` 或 `cjpm test --filter "pattern"` 运行。

当前结论：

> 仓颉已经有直接的 `internal` 语义，且普通顶层声明默认 `internal`。因此第一批非 package declaration symbol 不需要用 `public` 暴露。

## 5. 如果 Internal 语义不足，应如何 Fail Closed

当前查证资料显示仓颉存在 `internal`，所以本轮不需要用替代方案冒充 internal。

若未来实际工具链、版本差异或包布局导致 `internal` 语义无法满足项目需要，则必须 fail closed，回到 docs-only gate，不得以 `public` 代替 internal。

可讨论的约束手段包括：

- package layout：把未稳定 symbol 限制在 `runtime/cjgui` 内部包。
- module layout：在模块边界上避免把实验性 symbol 暴露给外部依赖。
- naming discipline：对内部 anchor 使用明确内部命名，避免误读为 public API。
- README / closure discipline：明确 `public_api_present=false` 或记录任何例外。
- import discipline：不从外部包导入或重新导出内部 symbol。
- test boundary：如果测试需要访问 internal symbol，另开 test / package / visibility preflight。

不能采用的做法：

- 用 `public` 暂代 internal。
- 用文档声称 public symbol 不是 public API。
- 用 `public import` 或重新导出扩大内部 symbol 可见性。
- 用 `protected` / module 可见性绕开尚未冻结的 module boundary。

## 6. 哪些 Symbol 绝不能先暴露为 Public

以下 symbol 类型绝不能作为第一批 public runtime surface 出现：

- app lifecycle owner、init、run、request quit、shutdown、queue / drain 相关 symbol。
- window lifecycle owner、create window、request close、destroy / release、stale message 相关 symbol。
- platform adapter owner、platform readiness / failure、queue drain request、window state fact 相关 symbol。
- error strategy owner、error category、error enum、Result-like type、diagnostics conversion 相关 symbol。
- handle、window id、generation、target update、async UI message target 相关 symbol。
- platform object wrapper 或裸指针相关 symbol。
- AppKit / Metal / Objective-C、`NSRunLoop`、`NSEvent`、`dispatch_main`、Objective-C callback truth 相关 symbol。
- Renderer / Scene / Widget / Layout / DSL 相关 symbol。
- Dirty Rect、global tick、frame scheduler、Text / Input / IME / Accessibility 相关 symbol。
- semantic tree / Action Router 相关 symbol。
- command-list hash、pixel diff、baseline、offscreen renderer 相关 symbol。
- smoke C ABI、smoke `last_error`、smoke bridge migration 相关 symbol。

这些名字即使只以空 type、marker、函数签名或 placeholder 出现，也会制造错误的 API 暗示。

## 7. App / Window / Platform / Error 第一批 Symbol 边界

结论：四条 runtime surface 的第一批 symbol 都应保持 `internal` 或等价受限边界；当前仍不允许定义。

具体判断：

- app lifecycle：未来第一批 symbol 若出现，应只用于 internal package sanity，不应公开 `run` / `shutdown` / queue / drain。
- window lifecycle：未来第一批 symbol 若出现，应只用于 internal owner sanity，不应公开 create / close / destroy。
- platform adapter：未来第一批 symbol 若出现，应只用于内部 adapter 边界，不应暴露平台对象或 runloop truth。
- error strategy：未来第一批 symbol 若出现，应只用于内部错误语义锚点，不应定义 public enum / Result type。

当前仍保持：

```text
behavior_code_present=false
public_api_present=false
public_c_abi_present=false
```

## 8. 是否允许 Empty Marker Type / Namespace Anchor

结论：本轮不允许。

未来可以讨论一个极窄 internal / package-private compile sanity anchor，但必须先创建 execution card。

原因：

- empty marker type 仍然是仓颉语义代码。
- namespace-like anchor 可能被误读为长期组织方式。
- 类型名会成为命名 precedent。
- 即使默认 `internal`，也会改变 package source 的事实状态。
- 当前尚未冻结 symbol owner、命名规范、file ownership、test visibility 和 verification。

因此下一步不能直接写 empty marker type 或 namespace anchor。

## 9. 是否允许定义函数签名

结论：不允许。

原因：

- 函数签名会立即表达调用契约。
- `run`、`shutdown`、`createWindow`、`requestClose`、`drain` 等名字会被读作 lifecycle API。
- 当前没有 behavior authorization。
- 当前没有 error strategy、threading contract 或 handle lifecycle contract。
- 当前没有 public / internal API review。

因此 future first symbol slice 不得定义函数签名。

## 10. 是否允许 Public Runtime API / Public C ABI

结论：

```text
public_runtime_api_allowed=false
public_c_abi_allowed=false
```

原因：

- 当前 runtime package 不是稳定框架入口。
- 当前没有真实 app/window lifecycle 行为。
- 当前没有 platform hiding implementation。
- 当前没有 structured error strategy。
- 当前没有 handle table / generation。
- 当前 smoke C ABI 已明确不得迁移为 public runtime API。
- public C ABI 风险高于 internal Cangjie symbol，必须另开独立 gate。

## 11. 是否允许测试访问 Internal Symbol

结论：本轮不打开。

查证资料确认：

- 单元测试文件可使用 `xxx_test.cj` 与被测文件同目录放置。
- 测试通过 `@Test` / `@TestCase` 组织。
- `cjpm test` / `cjpm test --filter` 是测试运行入口。

但本轮没有冻结：

- runtime package 是否现在允许 test source。
- test source 与 `internal` symbol 的访问关系如何在当前 layout 下使用。
- 测试是否应与 package source 同目录，还是另开 `tests/`。
- 测试是否会把 internal anchor 变成稳定行为 contract。

因此若未来需要测试访问 internal symbol，必须另开：

> `P1 runtime internal symbol test boundary preflight`

在该 gate 前，不新增 test source，不定义 test-only visibility policy。

## 12. 是否应先冻结命名规范 / File Ownership / Symbol Ownership

结论：应该。

第一批 symbol 前必须冻结：

- symbol owner：属于 app lifecycle、window lifecycle、platform adapter、error strategy，还是独立 internal package sanity。
- file owner：落在哪个 `.cj` 文件，是否允许新增文件。
- name discipline：是否允许 `Internal*`、`_*` 或其他内部命名约束。
- visibility style：依赖默认 `internal`，还是显式写 `internal`。
- doc discipline：是否必须在 README / closure 中记录 `public_api_present=false`。
- test discipline：是否允许 tests 访问，若允许如何避免升级为 API。
- build discipline：`cjpm build --target-dir ... --skip-script` 是否仍为必跑验证。

在这些边界冻结前，不应新增任何 symbol。

## 13. 第一批 Symbol 应优先服务什么

结论：

```text
first_symbol_purpose=internal_package_sanity
first_symbol_purpose!=public_api
first_symbol_purpose!=runtime_behavior
```

第一批 symbol 的唯一合理目标是验证：

- 仓颉 package 内部 symbol 的最小可编译形态。
- visibility policy 是否能维持 `public_api_present=false`。
- package source 能从 package-declaration-only 进入 internal-symbol-only，而不引入行为。

它不应验证：

- app run。
- window create。
- platform adapter callback。
- error enum / Result。
- public API。
- C ABI。
- smoke migration。

## 14. 是否需要先创建 Execution Card

结论：需要。

推荐下一张 docs-only opening：

> `P1 runtime internal symbol boundary execution card`

该 execution card 最多只能授权未来一个极窄 first slice：

- 定义一个 internal / package-private compile sanity anchor，或继续决定暂不定义。
- 明确是否使用显式 `internal` 还是依赖默认 internal。
- 明确只允许一个最小 symbol，且不得是 app/window/platform/error behavior。
- 明确不得定义 function signature、public API、public C ABI、import、type hierarchy、enum / Result、handle、platform object wrapper。
- 明确不得新增 `src/main.cj`、`package_anchor.cj` 或修改 `cjpm.toml`，除非 execution card 单独证明必要。
- 明确验证 `public_api_present=false`、`behavior_code_present=false`、无 smoke dependency、无 runtime behavior。

在 execution card 创建前，不允许实现。

## 15. Stop-Line

本轮强制 stop-line：

- 不修改 [runtime/](/Users/jiangxuanyang/Desktop/cangjie/runtime/)。
- 不修改 [labs/macos_bridge_smoke/](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/)。
- 不写 runtime 代码。
- 不写新的仓颉 symbol。
- 不修改 [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- 不新增 `src/main.cj`。
- 不新增 `package_anchor.cj`。
- 不定义函数。
- 不定义类型。
- 不写 import。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 不定义 error enum / Result type。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不实现 handle table / generation。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 16. 结论

当前 first-compilable runtime source 可以继续保持封账。

`runtime/cjgui` 下一步不应直接进入真实 implementation，也不应先定义 public API、C ABI、函数签名、empty marker type 或 behavior。

仓颉查证资料显示：

- 普通顶层声明默认 `internal`。
- `internal` 可见于当前包及子包。
- `public` 是全局可见，不能作为第一批 runtime symbol 的默认出口。

因此下一步推荐：

> `P1 runtime internal symbol boundary execution card`

该下一步仍是 docs-only，不自动开启实现。
