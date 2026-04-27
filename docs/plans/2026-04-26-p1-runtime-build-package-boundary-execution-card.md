# P1 Runtime Build / Package Boundary Execution Card

日期：2026-04-26

性质：docs-only execution card / build-package boundary authorization / no implementation

状态：完成；不自动开启实现

## 0. Architect Sign-off

架构管理师确认：

- 状态：本轮只创建 execution card，不等于批准立即实现。
- 确认依据：[P1 runtime build/package boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。
- 上层尽量仓颉原生：是，但本轮不写仓颉代码。
- 底层只保留必要平台桥接：是；本卡禁止迁移 smoke bridge。
- 没有过早抽象跨平台：是；本卡只处理 `runtime/cjgui` package / build metadata boundary。

## 1. Authority

本卡唯一 authority：

- [2026-04-26-p1-runtime-build-package-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-build-package-boundary-preflight.md)

历史文档只作为背景，不得扩大本卡授权范围。

## 2. Goal

本卡目标：

- 将 `P1 runtime build/package boundary preflight` 收束成未来一个极窄 first slice 的 execution card。
- 未来 first slice 最多只能创建最小可编译 runtime package skeleton 的 package / build metadata。
- 未来 first slice 必须保持 runtime source comment-only。

创建本 execution card 本身不等于实现。

## 3. Future First Slice Scope

未来 first slice 只允许做：

- 查证 `cjpm` / `cjc` package layout、metadata、命令和语法。
- 在查证后创建最小 package / build metadata。
- 记录 build / package boundary。
- 尝试按查证后的正确命令执行 metadata 语法检查、dry run 或 build check。
- 保持 app / window / platform / error 四个 `.cj` 文件 comment-only。
- 新建 closure review 并更新索引。

未来 first slice 明确不做：

- 不写非注释仓颉 runtime 代码。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不定义稳定函数签名。
- 不实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 不定义 error enum / Result type。
- 不迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- 不让 runtime package 依赖 `labs/macos_bridge_smoke`。
- 不实现 handle table / generation。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 4. Package Owner Candidate

未来 package owner 候选：

- [runtime/cjgui](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui)

该 owner 只负责 package / build metadata boundary，不负责实现 runtime behavior。

该 owner 不属于：

- [labs/macos_bridge_smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke)
- smoke build script。
- smoke C ABI。
- smoke `last_error`。
- screenshot / frame hash harness。
- Renderer / Scene / Widget / Layout / DSL。

## 5. Mandatory Toolchain Lookup Before Future Implementation

未来 first slice 在写任何 package / build metadata 前，必须查证：

- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- [LOCAL_TOOLCHAIN_SETUP.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/LOCAL_TOOLCHAIN_SETUP.md)
- [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)
- CangjieSkills 中与 toolchain / regulations 相关的 skill，至少按需查询 `cangjie-toolchains`，必要时查询 `cangjie-regulations`。
- 本地仓颉官方文档。

必须查证的具体事项：

- `cjpm` package layout。
- package metadata 文件名和字段。
- `cjpm` / `cjc` build、dry run、test 或 syntax check 命令。
- SDK 环境变量使用方式。
- build cache / artifact 路径。
- comment-only `.cj` source 是否能被 package 接受。

不能凭模型记忆猜 `cjpm` / `cjc` 结构。

当前已知工具链边界：

- Cangjie Compiler `1.1.0`。
- target 为 `aarch64-apple-darwin`。
- 默认 `MacOSX26.4.sdk` 存在已记录兼容问题。
- 当前推荐 `CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`。
- 使用 `cjpm` 时应按本地 setup 文档显式处理 `SDKROOT`。

## 6. Future Write Set

未来 first slice 最大允许 write set：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml`，或经查证后的等价 package metadata 文件。
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- 必要时只做 build metadata 所需的最小目录调整。
- future closure review：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/YYYY-MM-DD-p1-runtime-build-package-metadata-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

未来 first slice 不得修改现有 `.cj` 文件为非注释代码。

必须保留 comment-only 的文件：

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

## 7. Forbidden Write Set

未来 first slice 禁止修改：

- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- screenshot / frame hash harness。
- native bridge。
- public runtime API。
- public C ABI。
- Renderer / Scene / Widget / Layout / DSL。
- Dirty Rect / global tick / frame scheduler。
- Text / Input / IME / Accessibility。
- semantic tree / Action Router。
- command-list hash / pixel diff / baseline / offscreen renderer。
- `CJGUI_TRUTH_MANIFEST.md`。

## 8. Truth / Projection

未来 first slice 的 truth：

- package / build metadata 是否存在。
- package / build metadata 是否符合查证后的 `cjpm` / `cjc` 规则。
- build / dry run / syntax check 命令及其 exit code。
- 四个 runtime `.cj` source 是否仍为 comment-only。

不是 truth 的内容：

- smoke guard 日志不是 runtime package truth。
- package metadata 不是 public API。
- comment-only source 不是 runtime behavior。
- diagnostics 不是第二状态真相源。

## 9. Invariants

未来 first slice 必须守住：

- runtime source 保持 comment-only。
- 不新增 public runtime API。
- 不新增 public C ABI。
- 不依赖 `labs/macos_bridge_smoke`。
- 不迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现任何 runtime behavior。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 Text / Input / IME / Accessibility。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 10. Verification

未来 first slice 必须执行或记录：

- 查证记录：列出参考过的本地仓颉工具链文档、CangjieSkills 或官方文档。
- package / build metadata 语法检查、`cjpm` / `cjc` dry run 或 build check，按查证后的正确命令执行。
- 记录 `CJ_GUI_SDKROOT` / `SDKROOT`。
- 检查四个 `.cj` 文件仍为 comment-only。
- 检查没有新增 public runtime API / public C ABI。
- 检查没有 smoke dependency / smoke C ABI reference。
- 检查没有修改 `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口。
- 如可行，运行现有 smoke guard：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

- 运行：

```bash
git diff --check
```

- closure review 必须能从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 和 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。

如果查证后发现 metadata-only skeleton 不能在保持 comment-only source 的情况下通过 build check，future first slice 必须 fail closed：记录 blocked / not applicable，不得临时写非注释 runtime code 绕过。

## 11. Closure Requirements

future closure review 必须记录：

- 本 execution card 路径。
- 实际 write set。
- 查证过的本地文档 / skill / 官方文档。
- 创建的 package / build metadata 文件。
- 是否修改 `.cj` 文件；若修改，是否仍为 comment-only。
- 是否运行 `cjpm` / `cjc` command，具体命令和 exit code。
- 是否运行 smoke guard。
- 是否新增 public runtime API / public C ABI，必须为否。
- 是否存在 smoke dependency / smoke C ABI reference，必须为否。
- forbidden file check。
- `git diff --check` 结果。
- stop-line 是否守住。
- residual risks。
- current next opening。

## 12. This Round Stop-line

创建本 execution card 的本轮 stop-line：

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

## 13. Next Opening

本卡之后推荐的下一条 opening：

> `P1 runtime build/package metadata first slice`

它不自动开启实现。必须由用户明确批准后，才能按本卡执行 future bounded implementation first slice。
