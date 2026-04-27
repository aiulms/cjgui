# P1 Runtime Build / Package Boundary Preflight

日期：2026-04-26

性质：docs-only / build-package boundary preflight / no implementation

状态：完成；不批准直接实现

范围：冻结 future `runtime/cjgui` 从 comment-only skeleton 进入可编译 runtime package skeleton 前必须回答的 package owner、module boundary、build entry、非注释仓颉语法许可、验证命令和本地工具链查证边界。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime 代码，不新增 package / build config。

## 1. 本轮依据

本轮直接承接：

- [P1 minimal runtime skeleton surface phase closure / compaction preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md)

重点读取四条 runtime surface closure：

- [P1 app lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 window lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 platform adapter surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)
- [P1 error strategy surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)

同时依据：

- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 red-team risk intake / runtime guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- [P1 self-drawn platform reduction / IME / accessibility guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [Build from zero](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [Local toolchain setup](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [Cangjie issue ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

当前 runtime skeleton 只读确认：

- [runtime/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

## 2. 是否现在进入可编译 Runtime Package Skeleton

结论：可以准备，但不能直接进入实现；必须先冻结 build / package boundary。

理由：

- app lifecycle、window lifecycle、platform adapter、error strategy 四条 surface 已经 comment-only 封账。
- 当前阻塞点已经从 surface owner 转为 package owner、module layout、build entry、验证命令和非注释仓颉语法许可。
- 当前没有 `cjpm` / `cjc` build entry，也没有 package / build config，因此 Cangjie build check 仍不适用。
- 在 build / package boundary 冻结前写任何非注释仓颉 runtime syntax，都会制造未经验证的 syntax / module / visibility truth。

因此下一步只能先创建 execution card，不能直接创建 package / build config。

## 3. Future Runtime Package Owner

future runtime package owner 应属于 `runtime/cjgui` 的 runtime package boundary。

该 owner 不属于：

- `labs/macos_bridge_smoke`。
- smoke build script。
- smoke C ABI。
- screenshot / frame hash harness。
- Renderer / Scene / Widget / Layout / DSL。

package owner 的职责是冻结：

- package / module layout。
- build entry / test entry。
- source inclusion policy。
- build artifact policy。
- Cangjie toolchain command policy。
- package boundary 与 app lifecycle / window lifecycle / platform adapter / error strategy surface 的关系。

它不负责实现 app lifecycle、window lifecycle、platform adapter 或 error strategy。

## 4. Package / Module Boundary 应放在哪里

候选边界仍是：

- [runtime/cjgui](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui)

理由：

- `runtime/` 已被定位为未来正式 runtime 的实验期区域。
- `runtime/cjgui` 已承载 app lifecycle、window lifecycle、platform adapter、error strategy 四条 comment-only surface。
- 它已经与 `labs/macos_bridge_smoke` 分离。

但本轮不冻结具体 `cjpm` 文件名、package metadata 结构、module declaration 或 import syntax。涉及这些内容时，必须先查证本地仓颉工具链文档、CangjieSkills 或本地官方文档。

## 5. 是否使用 `cjpm`

结论：`cjpm` 是合理候选，但本轮不凭记忆定论。

本地 setup 文档已经确认：

- 当前机器已验证 `cjc -v`。
- 当前机器已验证 `cjpm -h`。
- 使用 `cjpm` 时需要显式设置兼容 SDK，例如 `SDKROOT="$CJ_GUI_SDKROOT" cjpm run`。
- 当前推荐 SDK 是 `/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`。

但是 future package layout、metadata 文件、module syntax、test / build command 不能靠模型记忆猜。下一张 execution card 必须要求：

- 查证 [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)。
- 查证 [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)。
- 按需使用 CangjieSkills 或本地仓颉官方文档。
- 若遇到工具链异常，按 [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md) 规则记录证据，不直接归因上游。

## 6. Build Entry 应是什么

当前不定论 executable smoke。

默认倾向：

- runtime package 先作为最小 library / package skeleton 讨论。
- executable smoke 与 runtime package 分离。
- runtime package build check 不应调用 `labs/macos_bridge_smoke` 的 C ABI、build script 或 clear-color render path。
- smoke guard 继续验证旧链路，不能成为 runtime package 的 build entry。

下一张 execution card 应明确：

- 是否只创建 package / build metadata。
- 是否允许 source file 被 package 包含。
- 是否存在 test entry。
- build output / cache 是否可写入仓库。
- build 命令和 SDK 环境变量。

在这些冻结前，不创建 build entry。

## 7. Runtime Package 是否依赖 `labs/macos_bridge_smoke`

结论：不依赖。

禁止：

- runtime package import / include / link `labs/macos_bridge_smoke` 内部 C ABI。
- runtime package 复用 smoke build script 作为 build entry。
- runtime package 把 smoke `last_error`、auto-close、clear-color render path、screenshot / frame hash diagnostics 作为 runtime contract。

允许保留的关系：

- smoke guard 继续作为旧链路 regression guard。
- future runtime package build check 是新的验证轴。
- closure review 可以同时记录 smoke guard 和 runtime build check，但二者不能互相替代。

## 8. 是否允许非注释仓颉语法

本轮答案：不允许。

future first slice 的默认上限应是：

- 创建最小 package / build metadata。
- 保持当前四个 `.cj` 文件 comment-only。
- 不定义函数签名。
- 不定义 public runtime API。
- 不写 runtime behavior。

如果工具链要求存在最小非注释 source 才能通过 package build，这必须另由 execution card 明确授权，并且必须先查证本地仓颉官方文档 / CangjieSkills。即使未来允许，也只能是 internal-only、无 runtime behavior、无 public API 的最小可验证 skeleton，不能顺手实现 app/window/platform/error。

## 9. 是否允许定义 Public API / Public C ABI / Real Behavior

本轮结论：

- public runtime API：不允许。
- public C ABI：不允许。
- real behavior：不允许。

原因：

- build / package boundary 只是让 runtime skeleton 具备可验证落点，不是 API 设计。
- 当前还没有 public / internal visibility policy。
- 当前仍未冻结 package metadata、module syntax、import syntax。
- 当前四条 surface 都明确不实现真实 behavior。

## 10. 当前四个 Comment-only `.cj` 文件如何进入 Package

当前文件：

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

当前策略：

- 继续保持 comment-only。
- 不为了 build check 自动改写成非注释仓颉语法。
- 不为它们补 package declaration、module declaration、imports 或函数签名。
- 是否被 package build 包含，必须等待 execution card 查证工具链行为后再定。

## 11. Build / Package Boundary 是否应先于任何非注释 Runtime 代码

结论：应该，而且必须。

原因：

- 没有 package owner，就没有语法 truth 的归属。
- 没有 build entry，就无法验证非注释语法。
- 没有 module boundary，函数签名容易被误认为 public API。
- 没有 artifact policy，就可能把 build output / cache 意外写入仓库。
- 没有 Cangjie toolchain 查证，就会违反 AI code quality governance。

## 12. Future Cangjie Build Check 应如何做

future build check 应在 execution card 明确后执行，至少记录：

- 是否 source 仓颉 SDK 环境。
- `CJ_GUI_SDKROOT` / `SDKROOT` 值。
- 使用 `cjc`、`cjpm` 或二者组合的原因。
- 具体命令。
- exit code。
- stdout / stderr 关键摘要。
- build artifact / cache 位置。
- 是否产生仓库内 artifact。
- 如果失败，按分类记录是环境、误用、工具链兼容还是 unknown。

当前已知本机工具链约束：

- 仓颉 Compiler 1.1.0。
- 目标 `aarch64-apple-darwin`。
- 默认 `MacOSX26.4.sdk` 有兼容问题。
- 推荐使用 `/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`。

## 13. 什么时候必须使用 CangjieSkills 或本地官方文档

涉及以下任一事项时，必须查证：

- `cjpm` package layout。
- package metadata 文件名和字段。
- module declaration syntax。
- import syntax。
- visibility / export 规则。
- test entry / build command。
- build cache / artifact 路径。
- comment-only `.cj` 是否能作为 source 被 toolchain 接受。
- internal-only skeleton 的最小合法仓颉语法。

查证顺序建议：

1. 本地 setup 文档。
2. CangjieSkills 中的 toolchain / language / regulations 内容。
3. 本地官方仓颉文档。
4. 已验证的最小 smoke / hello 经验。

不能用模型记忆替代上述查证。

## 14. 是否需要先创建 Execution Card

结论：需要。

下一步推荐 docs-only：

> `P1 runtime build/package boundary execution card`

该 execution card 最多只能授权 future implementation first slice：

- 创建最小 package / build metadata。
- 保持现有 runtime source comment-only，除非 execution card 经查证后极窄授权 internal-only 最小语法。
- 明确 `cjpm` / `cjc` 验证命令。
- 明确 SDK 环境变量。
- 明确 build artifact / cache policy。
- 明确 smoke guard 与 runtime build check 的并列关系。
- 新建 closure review 并更新索引。

它不得授权：

- runtime behavior。
- public runtime API。
- public C ABI。
- app lifecycle / window lifecycle / platform adapter / error strategy implementation。
- Renderer / Scene / Widget / Layout / DSL。
- global tick / frame scheduler。
- Text / Input / IME / Accessibility。
- semantic tree / Action Router。
- command-list hash / pixel diff / baseline / offscreen renderer。

## 15. 本轮 Stop-line

本轮强制保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不写非注释仓颉语法。
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

当前可以准备从 comment-only skeleton 进入可编译 runtime package skeleton，但不能直接实现。

下一步必须先创建 docs-only：

> `P1 runtime build/package boundary execution card`

在 execution card 落地前，不应创建 package / build config，不应写非注释仓颉 runtime code，不应定义 public API / public C ABI，也不应进入任何真实 runtime behavior。
