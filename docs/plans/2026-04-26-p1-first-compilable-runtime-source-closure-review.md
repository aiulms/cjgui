# P1 First Compilable Runtime Source Closure Review

日期：2026-04-26

性质：closure review / package declaration first slice / no runtime behavior

状态：完成

## 0. Authority

本轮唯一 authority：

- [2026-04-26-p1-first-compilable-runtime-source-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-execution-card.md)

## 1. Toolchain / Package Declaration Lookup

本轮重新查证来源：

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [cangjie-lang-features/package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-toolchains/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-toolchains/SKILL.md)
- [cangjie-toolchains/cjpm/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-toolchains/cjpm/README.md)
- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)

查证结论：

- 仓颉 `package` declaration 必须是文件第一条非空 / 非注释行。
- 同一 package 中的所有文件必须使用相同 package declaration。
- `src/` 根目录文件没有 package declaration 时会落入默认 package。
- `cjpm.toml` 中 `name = "cjgui"` 要求当前 root package identity 与 `cjgui` 对齐。
- 当前 `output-type = "static"`，不需要新增 executable `src/main.cj`。

## 2. Landed Reality

本轮只把四个现有 runtime source 从 strict comment-only 推进到 package declaration only：

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

每个文件只新增同一行：

```cangjie
package cjgui
```

该行均为文件第 1 行，也是第一条非空 / 非注释行。

同步轻量更新：

- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

README 只记录当前 package declaration only 边界，不定义 runtime behavior 或 public API。

## 3. Boundary Flags

本轮 closure 明确记录：

```text
strict_comment_only=false
package_declaration_only=true
behavior_code_present=false
public_api_present=false
```

解释：

- `strict_comment_only=false` 只表示 `.cj` 文件现在包含 `package cjgui` declaration。
- `package_declaration_only=true` 表示除 `package cjgui` 外没有任何非注释仓颉语法。
- `behavior_code_present=false` 表示没有 runtime behavior。
- `public_api_present=false` 表示没有 public runtime API 或 public C ABI。

## 4. Build Result

执行命令：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-first-compilable-runtime-source-target --skip-script
```

结果：

- exit code：`0`
- log：`/tmp/cjgui-first-compilable-runtime-source-cjpm-build.log`
- 关键输出：`cjpm build success`
- 仓库内 `target/`：未生成。
- 仓库内 build artifact：未生成。

分类：

- `build_check_passed=true`
- `package_identity_verified=true`
- `runtime_behavior_verified=false`

说明：

- build 通过只证明当前 package declaration / package identity 可被工具链接受。
- build 通过不代表 app lifecycle、window lifecycle、platform adapter 或 error strategy 已实现。

## 5. Source Boundary Check

检查结果：

- 四个 `.cj` 文件的唯一非空 / 非注释行均为 `package cjgui`。
- 没有函数。
- 没有类型。
- 没有 import。
- 没有 stable function signature。
- 没有 public runtime API。
- 没有 public C ABI。
- 没有 runtime behavior。

未新增：

- `runtime/cjgui/src/main.cj`
- `runtime/cjgui/src/package_anchor.cj`

未修改：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)

`cjpm.toml` SHA-256 仍为：

```text
20ca1465dd8abdf0c68040eb402143a17fa3171d56c272c88de94022bb253406
```

## 6. Smoke Guard Result

执行命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- exit code：`0`
- log：`/tmp/cjgui-first-compilable-runtime-source-smoke-guard.log`
- 关键输出：`cjgui verify: auto-close log assertions passed`

说明：

- smoke guard 仍只作为旧链路 guard。
- smoke guard 不是 runtime package truth。
- smoke guard 不是正式 runtime test framework。

## 7. Forbidden File Check

本轮未修改以下 forbidden source / harness / native bridge / 仓颉入口文件：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh`
- `labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh`
- `labs/macos_bridge_smoke/README.md`

哈希复核：

- forbidden source / harness / native bridge / 仓颉入口：`unchanged=true`
- `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口：未修改。

依赖 / 引用复核：

- runtime package 没有依赖 `labs/macos_bridge_smoke`。
- runtime source 非注释语法没有 smoke C ABI reference。
- 没有迁移 smoke code、smoke C ABI 或 smoke `last_error`。

## 8. Stop-line Review

本轮守住：

- 未新增 `src/main.cj`。
- 未新增 `package_anchor.cj`。
- 未修改 `cjpm.toml`。
- 未定义函数。
- 未定义类型。
- 未写 import。
- 未定义 public runtime API。
- 未定义 public C ABI。
- 未实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 未定义 error enum / Result type。
- 未迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- 未让 runtime package 依赖 `labs/macos_bridge_smoke`。
- 未修改 smoke source / harness / native bridge / 仓颉入口。
- 未实现 handle table / generation。
- 未暴露 AppKit / Metal / Objective-C platform objects。
- 未进入 Renderer / Scene / Widget / Layout / DSL。
- 未进入 Dirty Rect / global tick / frame scheduler。
- 未进入 Text / Input / IME / Accessibility。
- 未进入 semantic tree / Action Router。
- 未进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## 9. Residual Risks

- 四个 `.cj` 文件的旧注释仍有早期 `comment-only` 表述；当前阶段的事实应以本 closure 和 README 的 `package_declaration_only=true` 为准。
- 当前 build 通过只代表最小 package identity 过关，不能被解读为 runtime API 或 lifecycle behavior 已存在。
- 下一步如果继续进入非 package declaration 的仓颉语法，必须先冻结 public / internal visibility、最小声明类型、验证命令和 fail-closed 规则。
- 当前仍没有 app lifecycle、window lifecycle、platform adapter、error strategy、handle table、Renderer / Scene / Widget / Layout / DSL、Text / Input / IME / Accessibility、semantic tree / Action Router、pixel diff、baseline 或 offscreen renderer。

## 10. Link / Diff Check

本 closure 必须能从：

- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

找到。

最终验证结果以本轮命令记录为准：

- `git diff --check`：通过。
- 绝对链接检查：`missing=0`。

## 11. Current Next Opening

建议下一条 docs-only opening：

> `P1 first compilable runtime source closure / next implementation boundary preflight`

目标：

- 复核 package declaration only first slice 的 build evidence。
- 判断下一条 implementation boundary 是否应继续围绕最小非行为声明、visibility policy、empty type anchor、还是回到 app/window lifecycle API preflight。
- 明确仍不自动开启真实 runtime implementation。
