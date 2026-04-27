# P1 Runtime Build / Package Metadata Closure Review

日期：2026-04-26

性质：closure review / metadata-only first slice / no runtime behavior

状态：完成

## 0. Authority

本轮唯一 authority：

- [2026-04-26-p1-runtime-build-package-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-execution-card.md)

## 1. Landed Reality

本轮只为 `runtime/cjgui` 创建最小 package / build metadata boundary，并保持 runtime source comment-only。

实际落地：

- 新增 [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- 更新 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- 新增本 closure review。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未落地：

- 未写非注释仓颉 runtime code。
- 未定义 public runtime API。
- 未定义 public C ABI。
- 未实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 未迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- 未让 runtime package 依赖 `labs/macos_bridge_smoke`。

## 2. Toolchain / Package Metadata Lookup

本轮查证来源：

- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- [cangjie-toolchains/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-toolchains/SKILL.md)
- [cangjie-toolchains/cjpm/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-toolchains/cjpm/README.md)

查证结论：

- `cjpm` project root 使用 `cjpm.toml`。
- package source 默认位于 `src/`，也可由 `src-dir` 指定。
- `[package]` 需要 `cjc-version`、`name`、`version`、`output-type`。
- `output-type` 支持 `executable`、`static`、`dynamic`。
- 本地工具链为 Cangjie Compiler `1.1.0`。
- 本地 macOS toolchain 仍应显式使用 `CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk` 并同步 `SDKROOT`，避免默认 SDK 问题。

## 3. Package Metadata Boundary

新增 metadata 内容边界：

```toml
[package]
  cjc-version = "1.1.0"
  name = "cjgui"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"
```

说明：

- `name = "cjgui"` 只定义 package metadata name，不定义 runtime API。
- `output-type = "static"` 只表达 future library package skeleton 倾向，不创建 executable smoke。
- 当前没有 `[dependencies]`，因此没有 smoke dependency。
- 当前没有 link option、native bridge、public C ABI 或 runtime behavior。
- 当前没有把 build artifact 写入仓库；build check 使用临时 target dir。

## 4. Build / Check Result

执行命令：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-runtime-build-package-metadata-target --skip-script
```

结果：

- exit code：`1`
- log：`/tmp/cjgui-runtime-build-package-metadata-cjpm-build.log`
- final verification log：`/tmp/cjgui-runtime-build-package-metadata-cjpm-build-final.log`
- 真实失败原因：`cjpm` 报告 `src` 下 package name 不匹配，正确 package name 应为 `cjgui`。

分类：

- `blocked=true`
- `blocked_reason=comment_only_source_has_no_package_declaration`
- `success=false`
- `render_failure=false`
- `runtime_failure=false`

本轮没有为了让 build check 通过而添加非注释仓颉代码；这是 execution card 要求的 fail-closed 行为。

## 5. Comment-only Source Check

检查文件：

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

结果：

- `app_lifecycle.cj`：`comment_only=true`
- `window_lifecycle.cj`：`comment_only=true`
- `platform_adapter.cj`：`comment_only=true`
- `error.cj`：`comment_only=true`
- 四个 `.cj` 文件 hash 与本轮修改前一致。

Cangjie build check 状态：

- 已执行 `cjpm build` metadata/package check。
- 当前 source 仍为 comment-only，因此 package build 失败是预期的边界暴露；下一步必须先开 preflight，不能直接写 package declaration 或非注释 source。

## 6. Smoke Guard

执行命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

- exit code：`0`
- log：`/tmp/cjgui-p1-auto-close-verify.log`
- `auto-close log assertions passed`

说明：

- smoke guard 仍只作为旧链路 guard。
- 它不是 runtime package truth。
- 它不是正式 runtime test framework。

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
- smoke guard 运行过程中重新生成了 `labs/macos_bridge_smoke/build/libcjgui_macos.a` build artifact；这不是 source / harness / native bridge / 仓颉入口修改。

## 8. Public API / ABI / Dependency Check

结果：

- 新增 public runtime API：否。
- 新增 public C ABI：否。
- 新增 stable function signature：否。
- 新增 package dependency：否。
- 依赖 `labs/macos_bridge_smoke`：否。
- 调用 smoke C ABI：否。
- 迁移 smoke `last_error`：否。
- 暴露 AppKit / Metal / Objective-C platform object：否。

备注：

- runtime comment-only source 中仍保留 smoke / `last_error` 的 non-migration 注释。这是禁止迁移说明，不是 dependency、API 或调用。

## 9. Stop-line Review

本轮守住：

- 未写 runtime behavior code。
- 未写非注释仓颉 runtime code。
- 未修改四个 `.cj` source。
- 未定义 public runtime API / public C ABI。
- 未新增 error enum / Result type。
- 未实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 未实现 handle table / generation。
- 未迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- 未修改 smoke source / harness / native bridge / 仓颉入口。
- 未进入 Renderer / Scene / Widget / Layout / DSL。
- 未进入 Dirty Rect / global tick / frame scheduler。
- 未进入 Text / Input / IME / Accessibility。
- 未进入 semantic tree / Action Router。
- 未进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## 10. Link / Diff Check

结果：

- closure review 可从 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。
- closure review 可从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 找到。
- 绝对链接检查：`missing=0`。
- `git diff --check`：exit code `0`。
- 新增 / 修改文件无 trailing whitespace。

## 11. Residual Risks

- 当前 package metadata 已存在，但 source 仍为 comment-only，不能视为可编译 runtime source。
- `cjpm build` 已暴露下一阶段必须处理 package declaration / module syntax 边界。
- 当前不应直接写 `package cjgui` 或任何非注释仓颉语法；必须先冻结 first compilable source boundary。
- 当前不代表 public runtime API 已存在。
- 当前不代表 app/window lifecycle runtime 已实现。
- smoke guard 与 runtime package build check 仍是并列验证轴，不能互相替代。

## 12. Current Next Opening

建议下一条 docs-only opening：

> `P1 runtime package metadata closure / first compilable source boundary preflight`

目标：

- 复核本轮 metadata closure。
- 冻结是否、何时、以什么最小边界允许四个 comment-only `.cj` 进入 first compilable source。
- 查证 package declaration、module syntax、visibility、空 package / placeholder source 的合法形态。
- 决定下一刀是否只允许添加 package declaration 或最小非行为 source。

该 opening 不自动开启实现。
