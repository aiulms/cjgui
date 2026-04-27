# P1 First Compilable Runtime Source Closure / Next Implementation Boundary Preflight

日期：2026-04-26

性质：docs-only / closure evidence review / next implementation boundary preflight / no runtime code

状态：完成；不批准直接实现

范围：复核 `P1 first compilable runtime source first slice` 的 package declaration only evidence，并判断下一条真正进入非 package declaration 仓颉语义代码之前，必须先冻结哪条边界。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime code。

## 1. 本轮依据

直接依据：

- [P1 first compilable runtime source closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-review.md)
- [P1 first compilable runtime source execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-execution-card.md)
- [P1 first compilable runtime source boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md)
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

当前 runtime package 只读确认：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

## 2. 当前 First Compilable Runtime Source 是否可以封账

结论：可以封账。

理由：

- 四个现有 `runtime/cjgui/src/*.cj` 均已有一致的 `package cjgui` declaration。
- `package cjgui` 是每个文件第一条非空 / 非注释行。
- 除 `package cjgui` 外，四个 `.cj` 文件没有任何非注释仓颉语法。
- closure review 已明确记录：

```text
strict_comment_only=false
package_declaration_only=true
behavior_code_present=false
public_api_present=false
```

- `cjpm build --target-dir /tmp/cjgui-first-compilable-runtime-source-target --skip-script` 已通过，exit code 为 `0`。
- 未新增 `src/main.cj`。
- 未新增 `package_anchor.cj`。
- 未修改 `cjpm.toml`。
- 未引入 smoke dependency、public runtime API、public C ABI 或 runtime behavior。

因此本阶段可以封账为：

> `runtime/cjgui` 已经从 package metadata skeleton 推进到 package declaration only 的最小可编译 source skeleton。

它仍不是 runtime implementation。

## 3. `cjpm build success` 证明了什么

`cjpm build success` 当前只证明：

- `runtime/cjgui/cjpm.toml` 的 minimal metadata 可被本地 `cjpm` 接受。
- `name = "cjgui"` 与四个 source 文件中的 `package cjgui` package identity 对齐。
- `output-type = "static"` 与当前无 `main` 的 package skeleton 可被工具链接受。
- 当前 source layout、package declaration 位置和 root package identity 没有阻塞 package build。
- 在显式使用 `CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk` / `SDKROOT` 的环境下，当前 package skeleton 可以通过 build check。

它不证明：

- app lifecycle 已实现。
- window lifecycle 已实现。
- platform adapter 已实现。
- error strategy 已实现。
- event loop、queue / drain、window create / close / destroy 已存在。
- public runtime API 已存在。
- public C ABI 已存在。
- handle table / generation 已存在。
- runtime package 能创建窗口、处理事件、渲染或暴露用户可见行为。
- smoke guard 与 runtime package 已合并。
- Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、pixel diff / baseline / offscreen renderer 已打开。

简化结论：

```text
cjpm_build_success == package_identity_and_empty_source_package_accepted
cjpm_build_success != runtime_capability
```

## 4. 是否应该进入真实 Runtime Implementation

结论：不应该。

原因：

- 当前只完成 package identity 验证。
- public / internal visibility policy 尚未冻结。
- 第一个非 package declaration 的 symbol 形态尚未冻结。
- 还没有定义哪些声明可以存在于 source、哪些会被误读成 API。
- 还没有冻结 future tests / imports / internal-only ownership 的规则。
- app lifecycle、window lifecycle、platform adapter、error strategy 仍只有 comment boundary。
- 直接进入真实 runtime implementation 会跳过治理门，容易把第一个函数、类型或 marker 误升级为长期 runtime contract。

因此下一步仍应是 docs-only，不是 implementation。

## 5. 下一份非 Package Declaration 的仓颉语义代码应先冻结什么边界

下一条最应先冻结：

> `P1 runtime visibility / internal symbol boundary preflight`

理由：

- 当前 package 已可编译，下一步如果出现任何非 package declaration 语法，它很可能是函数、类型、import、enum、struct、class、interface、internal symbol 或 public symbol。
- 这些语法一旦落地，就会产生工具链事实、包内可见性事实和未来 API 误读风险。
- 在 visibility / internal symbol boundary 未冻结前，即使是空 type、marker、internal namespace 或最小 anchor，也可能被后续误当成正式 surface。
- public API、C ABI、app/window/platform/error behavior 都必须建立在 visibility policy 之后。

该 preflight 应先回答：

- `runtime/cjgui` 内第一批非 package declaration symbol 是否只能是 internal。
- 默认 visibility 是否可以依赖语言默认值，还是必须显式声明。
- 是否允许 empty type / marker / internal namespace。
- 是否允许 stable function signature。
- 是否允许 public symbol。
- test / import / package-private 规则如何影响未来 source。
- 什么 symbol 会被视为 public runtime API。
- 什么 symbol 只是 internal build anchor。
- 未来如果引入 symbol，如何做 build check、diff check 和 fail-closed。

## 6. 是否应先冻结 Public API / Visibility / Internal Symbol Boundary

结论：应该。

当前不应直接定义任何 public API 或 internal anchor。

原因：

- 仓颉包内默认 visibility、`public` / `internal` 等语义会影响长期 surface。
- 当前项目明确禁止 public runtime API 过早出现。
- 即使不写 `public`，如果默认可见性、导入规则、测试规则未冻结，也可能形成隐性 API。
- 第一个 symbol 的名字、位置、visibility、文档注释和测试方式都会成为后续代码模仿对象。

在冻结该 boundary 前，所有非 package declaration 仓颉语义都应继续关闭。

## 7. 是否允许先定义空 Type / Internal Namespace / Marker

结论：当前不允许直接定义。

未来可以讨论，但必须先做 `runtime visibility / internal symbol boundary preflight`，并按需查证仓颉语法。

需要查证的内容包括：

- 仓颉是否有适合本项目的空 type / marker 表达。
- class / struct / interface / enum 的默认 visibility。
- 顶层声明默认 visibility。
- 包内 / 模块内 / 外部包导入规则。
- 是否存在 namespace-like idiom，或者应避免引入伪 namespace。
- 测试文件和普通 source 对 internal symbol 的可见性。
- 空 symbol 是否能通过 `cjpm build` 且不产生误导性 public surface。

当前不允许的原因：

- 空 type / marker 也会成为真实语义代码，不再是 package declaration only。
- 它会打开命名、visibility、owner 和未来 API 解释问题。
- 如果没有 preflight，很容易为了“让代码有个锚点”而制造长期符号债。

## 8. 是否允许先定义函数签名

结论：不允许。

原因：

- 函数签名最容易被误读为 API contract。
- 即使函数体为空或只返回 placeholder，也会暗示调用语义、错误语义和 owner。
- 当前 app lifecycle / window lifecycle / platform adapter / error strategy 的真实行为仍未授权。
- `init`、`run`、`request quit`、`create window`、`destroy` 等词已经在注释中作为 future slot 出现，但还不是函数。

因此在 visibility / internal symbol boundary、API boundary 和具体 lifecycle execution card 之前，不应定义函数。

## 9. 是否允许 Public API

结论：不允许。

原因：

- 当前 runtime package 只证明可编译，不证明能力。
- public API 只能投影真实底座能力，不能先于底座出现。
- public API 会扩大长期兼容承诺。
- public API 会把入口层想象反逼执行层，违反治理总则。

未来若要定义 public runtime API，至少需要独立 preflight / execution card，回答 owner、truth、input / output、error、threading、platform hiding、verification 和 compatibility。

## 10. 是否允许 Public C ABI

结论：不允许。

原因：

- 正式 runtime 不应直接升格 smoke C ABI。
- C ABI 涉及跨语言 owner、内存、错误、句柄、线程和平台对象隐藏。
- 当前还没有 handle table / generation。
- 当前还没有 structured error strategy。
- 当前还没有 platform adapter implementation。
- 当前还没有 app/window lifecycle behavior。

未来 public C ABI 必须另开更高风险 docs-only gate，不能从 package skeleton 推导出来。

## 11. 是否允许 App / Window / Platform / Error Behavior

结论：不允许。

当前仍不允许：

- app lifecycle behavior。
- window lifecycle behavior。
- platform adapter behavior。
- error strategy behavior。
- event loop。
- main-thread queue / drain。
- window create / request close / destroy / release。
- handle table / generation。
- platform callback binding。
- smoke C ABI binding。

原因：

- 这些能力都已有 comment-only surface，但没有 implementation authorization。
- 每一项都会改变 owner、truth、error path 或 platform boundary。
- 任何真实行为都必须先有 execution card，不能从 `cjpm build success` 自动推出。

## 12. 是否应先做 `P1 runtime visibility / internal symbol boundary preflight`

结论：应该。

推荐下一条 opening：

> `P1 runtime visibility / internal symbol boundary preflight`

它应是 docs-only。

它的目标不是写代码，而是冻结：

- 第一个非 package declaration symbol 的许可条件。
- internal-only symbol 是否允许。
- public symbol 是否仍禁止。
- 空 type / marker / namespace-like anchor 是否允许。
- 函数签名是否仍禁止。
- import 是否仍禁止或如何查证。
- visibility / module / package / test 规则的查证来源。
- build check 和 fail-closed 规则。
- 与 smoke guard 的分离关系。

## 13. 是否应先做 `P1 runtime empty internal anchor execution card`

结论：还太早。

原因：

- empty internal anchor 本身已经是非 package declaration 的语义代码。
- 当前尚未冻结 visibility、internal symbol、public API 判定和测试导入规则。
- 如果直接创建 execution card，可能会跳过“为什么需要 anchor、anchor 放哪里、叫什么、是否可见、是否长期保留”的判断。

正确顺序应是：

1. `P1 runtime visibility / internal symbol boundary preflight`
2. 若 preflight 允许，再创建极窄 execution card，例如 `P1 runtime empty internal anchor execution card`
3. 若 execution card 明确授权，才允许写第一个非 package declaration symbol

## 14. 如何继续保持 Smoke 与 Runtime Package 分离

继续保持以下边界：

- runtime package 不依赖 `labs/macos_bridge_smoke`。
- runtime package 不引用 smoke C ABI。
- runtime package 不迁移 smoke `last_error`。
- runtime package 不复用 smoke build script。
- runtime package 不复用 smoke `src/main.cj`。
- smoke guard 继续作为旧链路 guard，不是 runtime package truth。
- smoke diagnostics 继续作为 evidence，不是 runtime API。
- future runtime build check 与 smoke guard 是并列验证轴，不能互相替代。

未来即使进入 internal symbol，也必须继续检查：

- `cjpm.toml` 不添加 smoke dependency。
- source 非注释语法不出现 smoke C ABI。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不把 smoke 的 auto-close、clear-color render path、screenshot / frame hash diagnostics 迁入 runtime。

## 15. Current Stop-line

本轮 stop-line：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不写非 package declaration 的仓颉语法。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj`。
- 不新增 `package_anchor.cj`。
- 不定义函数。
- 不定义类型。
- 不写 import。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 不定义 error enum / Result type。
- 不迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- 不实现 handle table / generation。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 16. Next Opening

建议下一条 docs-only opening：

> `P1 runtime visibility / internal symbol boundary preflight`

它不自动开启实现。

该 opening 完成前，不应定义函数、类型、public API、internal anchor、empty marker、import、public C ABI 或任何 runtime behavior。
