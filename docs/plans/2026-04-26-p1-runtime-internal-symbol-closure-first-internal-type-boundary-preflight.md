# P1 Runtime Internal Symbol Closure / First Internal Type Boundary Preflight

日期：2026-04-26

性质：docs-only preflight / internal symbol closure review / first internal type boundary gate / no runtime code

状态：完成；不批准直接实现

范围：复盘 `P1 runtime internal symbol boundary first slice` 是否可以封账，并判断下一步是否应该进入“第一个真正有语义的 internal type”边界冻结。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime code。

## 1. 本轮依据

直接依据：

- [P1 runtime internal symbol boundary closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md)
- [P1 runtime internal symbol boundary execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md)
- [P1 runtime visibility / internal symbol boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)
- [P1 first compilable runtime source closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-review.md)
- [P1 first compilable runtime source closure / next implementation boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-next-implementation-boundary-preflight.md)
- [P1 runtime build/package metadata closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

当前 runtime package 只读确认：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

## 2. 当前 Marker 证明了什么

`CjguiInternalCompileSanityMarker` 证明：

- `runtime/cjgui` 已经不再只是 package declaration only source。
- 当前 package 可以承载一个默认 `internal` 的普通顶层声明。
- 仓颉工具链接受当前 `cjpm.toml`、`package cjgui`、默认 internal 顶层 `struct` 与 `output-type = "static"` 的组合。
- 在没有 public API、public C ABI、function、import、runtime behavior、smoke dependency 的前提下，`cjpm build --target-dir /tmp/cjgui-runtime-internal-symbol-boundary-target --skip-script` 可以通过。
- `runtime/cjgui` 已经具备下一步讨论 internal type boundary 的最小工具链证据。

简化 truth：

```text
internal_marker_buildable=true
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
function_present=false
import_present=false
```

## 3. 当前 Marker 不证明什么

`CjguiInternalCompileSanityMarker` 不证明：

- app lifecycle 已实现。
- window lifecycle 已实现。
- platform adapter 已实现。
- error strategy 已实现。
- runtime package 已有可调用行为。
- public runtime API 已存在。
- public C ABI 已存在。
- handle table / generation 已存在。
- error enum / Result type 已存在。
- platform object hiding 已实现。
- smoke bridge 可以迁移。
- Renderer / Scene / Widget / Layout / DSL 可以打开。
- Text / Input / IME / Accessibility 可以打开。
- semantic tree / Action Router 可以打开。
- command-list hash / pixel diff / baseline / offscreen renderer 可以打开。

简化 non-truth：

```text
internal_marker_buildable != runtime_capability
internal_marker_buildable != domain_model_ready
internal_marker_buildable != api_contract
```

## 4. Marker 是否是 Runtime Domain Type

结论：否。

`CjguiInternalCompileSanityMarker` 只应被视为 compile sanity marker，不应被视为 runtime domain type。

理由：

- 名称明确包含 `CompileSanityMarker`，不承诺 app/window/platform/error domain。
- 它没有字段、函数、import、public modifier 或行为。
- 它不表达生命周期状态、窗口状态、平台事实、错误事实、handle identity 或 Result 语义。
- 它的存在只证明 package 可以承载一个非 public symbol。
- 如果把它当成 domain type，会错误扩大本轮 first slice 的 truth。

因此它可以封账为：

```text
runtime_internal_symbol_sanity=true
runtime_domain_type_present=false
```

## 5. 是否应该立刻实现第一个有语义的 Internal Type

结论：不应该直接实现。

下一步如果要推进，应先创建 docs-only execution card。

原因：

- 第一个真正有语义的 internal type 会成为命名、visibility、文件归属和测试方式的 precedent。
- 语义 type 即使默认 internal，也会比 compile sanity marker 更接近 runtime domain contract。
- 当前尚未冻结 first type 的 owner、候选边界、命名纪律、是否允许字段、是否允许 constructor、是否允许 enum / struct / class、是否允许测试访问 internal symbol。
- 直接实现容易把“内部事实锚点”误升级成 lifecycle state、error taxonomy、handle model 或 public API。

## 6. 第一批 Internal Type 候选边界

候选边界包括：

- app lifecycle state。
- window lifecycle state。
- platform facts。
- error facts。

逐项判断：

- app lifecycle state 风险较高：容易暗示 `run`、`shutdown`、request quit、queue / drain、event loop 和 app owner 行为。
- window lifecycle state 风险较高：容易暗示 create / close / destroy、public window handle、stale target、handle table / generation 和多窗口。
- platform facts 风险中等：可以保持为 dehydrated facts，但容易把 AppKit runloop、callback truth、platform object ownership 或 macOS 偶然性带进 core。
- error facts 风险相对最低：可以围绕 fail-closed / degraded diagnostics 的内部事实边界讨论，不必驱动 app/window behavior，也不需要暴露平台对象。

当前最低风险候选：

> internal error facts boundary

但该候选必须继续排除：

- error enum。
- Result type。
- exception-like mechanism。
- public API。
- behavior code。
- diagnostics as state truth。

换句话说，最低风险不是“马上定义 error system”，而是“下一张 execution card 可以讨论一个默认 internal、无行为、无 public、无 import、无平台对象的最小 error fact / diagnostics fact type 是否安全”。

## 7. 现在仍不应该定义的类型

以下类型现在仍不应定义：

- public handle。
- window handle table。
- generation / token。
- Result type。
- error enum。
- exception-like type。
- lifecycle state machine type。
- app run / shutdown command type。
- window create / request close / destroy command type。
- platform object wrapper。
- native handle / raw pointer wrapper。
- AppKit / Metal / Objective-C bridge type。
- Renderer / Scene / Widget / Layout / DSL 相关类型。
- Dirty Rect / frame scheduler / global tick 相关类型。
- Text / Input / IME / Accessibility 相关类型。
- semantic tree / Action Router 相关类型。
- command-list hash / pixel diff / baseline / offscreen renderer 相关类型。

这些类型会提前打开本阶段尚未批准的 owner、truth 或 public surface。

## 8. Public / Import / Function / Behavior 是否允许

结论：

```text
public_allowed=false
import_allowed=false
function_allowed=false
runtime_behavior_allowed=false
```

理由：

- public symbol 会立即变成外部可依赖 surface。
- import 会打开 dependency / package coupling 问题。
- function signature 会表达调用 contract。
- runtime behavior 会绕过 app/window/platform/error execution card。

第一批真正 internal type 如果未来获批，也必须保持：

```text
default_internal_only=true
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
function_present=false
import_present=false
```

## 9. Package / Entry / Anchor 是否允许修改

结论：

```text
cjpm_toml_modification_allowed=false
src_main_allowed=false
package_anchor_allowed=false
```

原因：

- `cjpm.toml` 当前已足够支持 static package build。
- `src/main.cj` 会把 runtime package 推向 executable entry 语义。
- `package_anchor.cj` 会制造新的 symbol/file ownership precedent，且已经不是本轮最小路径。
- 当前四个 surface 文件已经足够承载后续 execution card 讨论。

## 10. 是否需要查证仓颉类型语法

结论：需要。

下一步 execution card 如果涉及具体类型，必须要求重新查证：

- CangjieSkills 中的 language feature 文档。
- 本地仓颉官方文档。
- package / visibility / struct / class / enum / interface / constructor / test 规则。

必须查证的问题包括：

- 默认 visibility 是否仍满足 `internal` 边界。
- 选择 `struct`、`class`、`enum`、`interface` 的语义成本。
- 空 type、无字段 type、无 constructor source 的编译器行为。
- 是否会生成可调用 constructor，以及如何避免把它解释成 public API。
- 测试文件未来如何访问 internal type。

不能凭模型记忆直接写第一个语义 type。

## 11. First Internal Type Execution Card 应回答什么

推荐下一张 docs-only execution card：

> `P1 first internal runtime type execution card`

该卡至少应冻结：

- 唯一 authority 是本 preflight。
- 是否允许定义第一个真正语义 internal type。
- 精确选择哪个候选边界，建议优先 `internal error facts boundary`。
- 允许修改的唯一 source file。
- 类型名、形式、visibility、是否允许字段、是否允许 constructor source。
- 是否允许修改 README。
- 是否允许运行 `cjpm build`。
- 是否允许 smoke guard。
- 是否允许 closure review。
- fail-closed 条件。

该卡不得授权：

- public runtime API。
- public C ABI。
- import。
- function。
- runtime behavior。
- error enum / Result type。
- handle table / generation。
- platform object wrapper。
- Renderer / Scene / Widget / Layout / DSL。

## 12. 本轮 Stop-line

本轮强制 stop-line：

- 不修改 [runtime/](/Users/jiangxuanyang/Desktop/cangjie/runtime/)。
- 不修改 [labs/macos_bridge_smoke/](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/)。
- 不修改 harness。
- 不修改 native bridge。
- 不修改仓颉入口。
- 不修改 [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- 不写 runtime code。
- 不定义新的仓颉 type。
- 不定义 function。
- 不写 import。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 app / window / platform / error behavior。
- 不实现 handle table / generation。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 Text / Input / IME / Accessibility。
- 不进入 semantic tree / Action Router。
- 不进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 13. Current Next Opening

推荐下一条 docs-only opening：

> `P1 first internal runtime type execution card`

这不是直接实现。只有该 execution card 明确授权后，未来 first slice 才能考虑定义一个默认 internal、无行为、无 public、无 import、无平台对象、无 public API / C ABI 的最小语义类型。
