# P1 First Compilable Runtime Source Boundary Preflight

日期：2026-04-26

性质：docs-only / first compilable source boundary preflight / no runtime code

状态：完成；不批准直接实现

范围：复核 `runtime/cjgui` package metadata closure 之后，冻结是否、何时、以什么最小边界允许第一份非注释仓颉 source 进入 `runtime/cjgui/src/`。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写非注释仓颉语法。

## 1. 本轮依据

直接依据：

- [P1 runtime build/package metadata closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-metadata-closure-review.md)
- [P1 runtime build/package boundary execution card](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-execution-card.md)
- [P1 runtime build/package boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)
- [P1 minimal runtime skeleton surface phase closure / compaction preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-surface-phase-closure-compaction-preflight.md)
- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [Build from zero](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [Local toolchain setup](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [Cangjie issue ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

本轮查证的仓颉资料：

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [cangjie-lang-features/package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-lang-features/project_management/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/project_management/README.md)
- [cangjie-toolchains/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-toolchains/SKILL.md)
- [cangjie-toolchains/cjpm/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-toolchains/cjpm/README.md)
- [cangjie-toolchains/cjc/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-toolchains/cjc/README.md)

当前 runtime package 只读确认：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

## 2. 当前 Build 失败的真实原因

当前 `runtime/cjgui/cjpm.toml` 内容：

```toml
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
```

metadata closure 中执行 `cjpm build --target-dir ... --skip-script` 的结果：

- exit code：`1`
- 关键错误：`the package name in .../runtime/cjgui/src is wrong, the right name should be 'cjgui'`

真实原因：

- 当前四个 `runtime/cjgui/src/*.cj` 仍为 comment-only。
- 仓颉 package 文档说明，`package` 声明必须是文件中第一个非空 / 非注释行。
- 同一包中的所有文件必须有相同 package 声明。
- `src/` 根目录文件如果没有 package 声明，会落入默认 package。
- `cjpm.toml` 的 `name = "cjgui"` 是模块名 / 根包名；`cjpm` 因此期待 `src/` 的根包名为 `cjgui`。

因此当前失败不是 runtime failure，也不是 smoke failure，而是：

```text
blocked_reason=comment_only_source_has_no_package_declaration
```

## 3. 是否应该允许第一份非注释仓颉 Source

结论：可以考虑允许，但本轮不允许；必须先创建 execution card。

理由：

- package metadata 已经存在。
- 当前唯一明确阻塞是 package declaration / package name mismatch。
- 若永远保持 `src/*.cj` strict comment-only，`cjpm build` 无法进入真正 package check。
- 但任何非注释仓颉语法都会从“文档占位”进入“工具链验证事实”，必须由 execution card 明确授权。

未来 first compilable source slice 的目标应极窄：

> 只让 package build 从“缺 package declaration”推进到“空包 / 无行为 package source 可被工具链接受或给出下一层真实错误”。

它不能顺手变成 runtime implementation。

## 4. Future First Slice 最多允许写什么

未来 first slice 最大范围应仅限：

- 添加最小 package declaration。
- 不添加函数。
- 不添加 import。
- 不添加 public / internal API surface。
- 不添加 enum / Result type / class / struct / interface。
- 不添加 app lifecycle / window lifecycle / platform adapter / error strategy behavior。
- 不添加 smoke dependency、FFI、public C ABI 或 native bridge binding。

推荐的最小语法上限：

```cangjie
package cjgui
```

该语法只能作为 package identity anchor，不得被解释为 public runtime API。

## 5. 是否只允许 Package / Module Declaration / Empty Package Anchor

结论：未来 first slice 只能允许 package declaration 级别的最小 source identity。

当前不建议打开：

- module-level API。
- public API。
- function signature。
- error enum / Result type。
- app / window / platform / error behavior。

仓颉资料中本轮确认：

- `package pkg1.sub1` 是 package 声明语法。
- package 声明必须匹配 source 在 `src/` 下的 package path / root package expectation。
- package 声明必须位于第一个非空 / 非注释行。
- 同一包所有文件必须具有相同 package 声明。
- `main` 是 executable entry 的入口；当前 `output-type = "static"`，不应默认新增 `src/main.cj`。

## 6. 是否允许定义函数 / Public API / Runtime Behavior

本轮结论：

- 定义函数：不允许。
- 定义稳定函数签名：不允许。
- 定义 public runtime API：不允许。
- 定义 public C ABI：不允许。
- 实现 app lifecycle：不允许。
- 实现 window lifecycle：不允许。
- 实现 platform adapter：不允许。
- 实现 error strategy：不允许。

原因：

- 当前 preflight 只解决 package identity mismatch。
- 函数签名很容易被误读为 runtime API。
- public / internal visibility policy 尚未冻结。
- error enum / Result type、handle table、event loop、window create / destroy 都仍是后续独立边界。

## 7. 哪个文件应首先变成非注释

基于当前仓颉 package 规则，不推荐只新增一个 `src/package_anchor.cj` 来解决问题。

原因：

- `src/` 根目录已有四个 `.cj` source。
- 这些文件当前无 package declaration，会被视作默认 package。
- 文档要求同一包中的所有文件具有相同 package 声明。
- metadata closure 中 `cjpm` 已经把 `src/` 根包名错误报告为不匹配。
- 如果只新增一个 `package cjgui` anchor，而其余四个文件仍无 package declaration，可能形成 root source package identity 混杂，仍不满足“同一包相同声明”的规则。

推荐 future execution card 优先授权：

- 在四个现有 surface 文件的第一条非注释位置添加完全相同的 `package cjgui` 声明。
- 不移动文件。
- 不新增行为文件。
- 不新增 `main.cj`。
- 不定义任何函数、类型、import 或 public symbol。

也可以讨论的替代方案：

- 新建 `src/package_anchor.cj`，同时把四个 comment-only surface 文件移出 `src/` 或调整 `src-dir`。

但该替代方案更宽：

- 会改变 source layout。
- 会触碰 runtime skeleton 文档 / source ownership。
- 可能需要调整 `cjpm.toml` 或 README。

因此它不适合作为默认 first compilable slice。

## 8. 四个 Surface 文件是否应继续保持 Comment-only

本轮必须继续保持 strict comment-only。

未来 first compilable slice 可以把它们推进为：

```text
package declaration + comment-only surface
```

这意味着：

- 它们不再是 strict comment-only。
- 但它们仍然没有 runtime behavior。
- 它们仍然没有 public API。
- 它们仍然没有函数签名。

execution card 必须清楚区分：

- `strict_comment_only=false`
- `behavior_code_present=false`
- `public_api_present=false`
- `package_declaration_only=true`

如果项目仍要求四个 surface 文件保持 strict comment-only，则必须选择更宽的 layout 方案，并另行冻结。

## 9. 是否需要新增 `src/main.cj`

结论：当前不需要，未来 first slice 默认也不应新增。

理由：

- 当前 `cjpm.toml` 使用 `output-type = "static"`。
- 仓颉项目管理资料说明 executable 类型会生成 / 需要 `src/main.cj`。
- `main` 是 executable entry。
- 当前 runtime package 不是 executable smoke。
- 本项目明确禁止把 runtime package 变成 smoke executable 或迁移 smoke entry。

因此 future first compilable slice 不应新增 `src/main.cj`。

## 10. 是否需要调整 `cjpm.toml`

结论：默认不需要。

当前 metadata 与查证资料一致：

- 使用 root `cjpm.toml`。
- `[package]` 具备必填字段。
- `name = "cjgui"` 与预期 root package name 对齐。
- `output-type = "static"` 与非 executable runtime skeleton 倾向一致。
- `src-dir = "src"` 与当前目录布局一致。

只有在 future execution card 查证发现 metadata 字段错误，或 `cjpm` 对 static package 的空源要求与当前判断冲突时，才允许另行调整。

本轮不修改 `cjpm.toml`。

## 11. Future Verification 应如何运行

future first slice 应按本地 setup 文档执行：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-first-compilable-runtime-source-target --skip-script
```

验证记录必须包含：

- 查证来源。
- 命令。
- exit code。
- 关键 stdout / stderr。
- 是否生成仓库内 artifact。
- 是否仍有 `target/` 留在仓库。
- 四个 source 是否只新增 package declaration。
- 是否没有函数 / public API / public C ABI / runtime behavior。
- 是否没有 smoke dependency / smoke C ABI reference。
- forbidden source / harness / native bridge / 仓颉入口 hash 是否未变。
- `git diff --check`。

## 12. 如果 Build 仍失败，何时可调整 Source

可以调整的前提：

- execution card 已明确允许。
- 调整仍限于 package declaration / package identity。
- 调整不定义函数、类型、import、public API、public C ABI 或 behavior。
- 调整原因直接来自 `cjpm` / `cjc` error output 或本地官方 / skill 文档。

必须 fail closed 的情况：

- 工具链要求必须有函数、`main`、public declaration、类型声明或行为代码。
- 需要新增 executable entry。
- 需要修改 `output-type`。
- 需要引入依赖、FFI、smoke C ABI 或 native bridge。
- 需要迁移 smoke code。
- 需要定义 app/window/platform/error behavior。
- 需要打开 Renderer / Scene / Widget / Layout / DSL。

遇到这些情况，future first slice 必须记录 blocked reason，并回到 docs-only gate。

## 13. 是否需要先创建 Execution Card

结论：需要。

下一步推荐 docs-only：

> `P1 first compilable runtime source execution card`

该 execution card 最多只能授权：

- 在 `runtime/cjgui/src/*.cj` 中添加最小 `package cjgui` declaration。
- 保持无函数、无类型、无 import、无 runtime behavior。
- 保持无 public runtime API / public C ABI。
- 运行 `cjpm build --target-dir /tmp/... --skip-script`。
- 新建 closure review 并更新索引。

它不得授权：

- app lifecycle / window lifecycle / platform adapter / error strategy implementation。
- `src/main.cj` executable entry。
- `cjpm.toml` 调整，除非 execution card 明确记录查证后的必要性。
- smoke code / smoke C ABI / smoke `last_error` 迁移。
- Renderer / Scene / Widget / Layout / DSL。
- Dirty Rect / global tick / frame scheduler。
- Text / Input / IME / Accessibility。
- semantic tree / Action Router。
- command-list hash / pixel diff / baseline / offscreen renderer。

## 14. 本轮 Stop-line

本轮强制保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不写非注释仓颉语法。
- 不新增 package / build config。
- 不修改 `cjpm.toml`。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不定义函数签名。
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

## 15. 结论

当前可以准备进入一个极窄 first compilable runtime source execution card，但不能直接实现。

本 preflight 推荐：

- 不新增 `src/main.cj`。
- 不调整 `cjpm.toml`。
- 不定义函数。
- 不定义 public API。
- 不实现 runtime behavior。
- 不使用 single package anchor 独自解决当前问题。
- 默认 future first slice 只给四个现有 `src/*.cj` 添加一致的 `package cjgui` declaration，并立即运行 `cjpm build` 验证。

当前 next opening：

> `P1 first compilable runtime source execution card`

它不自动开启实现。
