# P1 Runtime Internal Symbol Boundary Execution Card

日期：2026-04-26

性质：docs-only execution card / internal symbol boundary authorization / no implementation

状态：完成；不自动开启实现

## 0. Architect Sign-off

架构管理师确认：

- 状态：本轮只创建 execution card，不等于批准立即实现。
- 确认依据：[P1 runtime visibility / internal symbol boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。
- 上层尽量仓颉原生：是，但本轮不写 runtime code。
- 底层只保留必要平台桥接：是；本卡继续禁止 smoke bridge 迁移。
- 没有过早抽象跨平台：是；本卡只处理 `runtime/cjgui` 的 internal symbol sanity。

## 1. Authority

本卡唯一 authority：

- [2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-visibility-internal-symbol-boundary-preflight.md)

历史文档只作为背景，不得扩大本卡授权范围。

## 2. Goal

本卡目标：

- 将 `P1 runtime visibility / internal symbol boundary preflight` 收束成未来一个极窄 first slice 的 execution card。
- 创建本 execution card 本身不等于实现。
- 未来 first slice 最多只能验证 `runtime/cjgui` 可以承载非 public 的内部 symbol。

未来 first slice 只允许做一件事：

> 在不定义 public API、不定义函数、不实现行为的前提下，定义一个最小 internal / package-private compile sanity symbol 或 marker。

该 symbol 只服务：

```text
internal_package_sanity
```

不服务：

```text
public_runtime_api
runtime_behavior
public_c_abi
```

## 3. Should We Allow An Empty Marker

结论：允许未来 first slice 讨论并落一个极窄 internal marker，但必须 fail closed。

允许的理由：

- preflight 已确认仓颉普通顶层声明默认 `internal`，`internal` 可见于当前包及子包。
- `runtime/cjgui` 已通过 package declaration only build check；下一步需要验证 package 是否能承载非 public symbol。
- 一个最小 internal marker 可以帮助确认 `public_api_present=false` 时 package 仍可编译。

谨慎边界：

- 不允许 public marker。
- 不允许 function signature。
- 不允许 enum / Result / error taxonomy。
- 不允许 app/window/platform/error behavior。
- 不允许把 marker 命名成 future API。
- 如果仓颉语法或 build 输出要求函数、行为、public declaration、dependency、FFI、smoke C ABI、native bridge 或 package metadata 调整，future first slice 必须 fail closed。

## 4. Future First Slice Scope

未来 first slice 最多允许：

- 重新确认仓颉 visibility / `internal` / `public` / marker 语法规则。
- 在一个现有 runtime source 文件中定义一个最小普通默认 internal 顶层 marker。
- 轻量更新 `runtime/cjgui/README.md`，说明该 marker 只是 internal compile sanity，不是 public API。
- 新建 closure review 并更新索引 / 任务账本。

未来 first slice 不允许：

- 定义 public runtime API。
- 定义 public C ABI。
- 定义函数签名。
- 写 import。
- 实现 app lifecycle / window lifecycle / platform adapter / error strategy 行为。
- 定义 error enum / Result type。
- 实现 handle table / generation。
- 迁移 smoke code / smoke C ABI / smoke `last_error`。
- 让 runtime package 依赖 `labs/macos_bridge_smoke`。
- 暴露 AppKit / Metal / Objective-C platform object。
- 进入 Renderer / Scene / Widget / Layout / DSL。
- 进入 Dirty Rect / global tick / frame scheduler。
- 进入 Text / Input / IME / Accessibility。
- 进入 semantic tree / Action Router。
- 进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 创建 `CJGUI_TRUTH_MANIFEST.md`。

## 5. Future Write Set

未来 first slice 最大允许 write set：

- 最多一个 runtime source file。优先候选：
  - [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
- 如果 future re-check 证明其他 existing surface file 更合适，也只能在以下四个文件中选择一个：
  - [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
  - [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
  - [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
  - [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
  - 只允许补充 internal symbol / visibility 说明。
- future closure review：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md`
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未来 first slice 不得修改：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- `runtime/cjgui/src/main.cj`
- `runtime/cjgui/src/package_anchor.cj`
- [labs/macos_bridge_smoke/](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/)
- native bridge、harness、smoke 仓颉入口或 build script。

## 6. Future Symbol Boundary

如果 future first slice 定义 symbol，必须满足：

- symbol 是普通默认 `internal` 顶层声明，不带 `public`。
- symbol 必须只服务 compile sanity / internal visibility boundary。
- source 中不得出现 `public` declaration。
- source 中不得出现 `func`。
- source 中不得出现 `import`。
- source 中不得出现 FFI、foreign、native handle、smoke C ABI、platform object 或 AppKit / Metal / Objective-C API 依赖。
- symbol 名称不得承诺 app/window/platform/error behavior。
- symbol 名称不得包含 `Run`、`WindowCreate`、`RequestClose`、`Adapter`, `ErrorResult`、`Handle`、`Renderer`、`Widget`、`Scene`、`Layout`、`Input`、`IME`、`Accessibility` 等 future behavior / API 暗示。

优先候选形式：

```text
default-internal empty marker type
```

未来 first slice 必须在执行前重新查证最小合法仓颉语法。若选择 `struct`，必须确认：

- 空 struct 或 marker struct 在仓颉中合法。
- 不需要显式 constructor / function。
- source diff 不包含函数、import、public modifier 或 behavior。
- 任何编译器自动生成的构造能力不会被解释为 public runtime API；closure 必须记录该风险。

如果查证结果不支持安全的 empty marker，future first slice 必须改为 docs-only closure / blocked review，不得临时改成函数、enum、Result type、dependency 或 package metadata 调整。

## 7. Truth / Projection

未来 first slice 的 truth：

- 是否只新增一个 internal / package-private marker symbol。
- 是否没有 `public` declaration。
- 是否没有函数、import、public runtime API、public C ABI 或 runtime behavior。
- `cjpm build --target-dir ... --skip-script` 的真实 exit code 与关键 stdout / stderr。
- 是否没有 smoke dependency / smoke C ABI reference。

不是 truth 的内容：

- marker 不是 runtime API。
- marker 不是 app lifecycle。
- marker 不是 window lifecycle。
- marker 不是 platform adapter。
- marker 不是 error strategy implementation。
- marker 不是 public C ABI。
- marker 不是 Renderer / Scene / Widget / Layout / DSL。
- smoke guard 日志不是 runtime package truth。
- diagnostics 不是第二状态真相源。

## 8. Required Closure Flags

future closure review 必须明确记录：

```text
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
internal_symbol_only=true
```

并额外记录：

```text
function_signature_present=false
import_present=false
smoke_dependency_present=false
platform_object_exposure_present=false
```

## 9. Future Verification

未来 first slice 必须重新确认仓颉 visibility / `internal` / `public` / marker 语法规则，并记录查证来源。

未来 first slice 必须运行：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-runtime-internal-symbol-boundary-target --skip-script
```

验证记录必须包含：

- exit code。
- stdout / stderr 关键内容。
- 是否生成仓库内 artifact。
- 是否留下仓库内 `target/`。
- 没有 `public` declaration。
- 没有函数。
- 没有 import。
- 没有 public runtime API / public C ABI。
- 没有 runtime behavior。
- 没有 smoke dependency / smoke C ABI reference。
- 没有修改 [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- 没有新增 `src/main.cj`。
- 没有新增 `package_anchor.cj`。
- 没有修改 `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口。
- 如可行，运行 smoke guard：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

- 运行：

```bash
git diff --check
```

- closure review 必须能从 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 和 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md) 找到。

## 10. Future Failure Handling

如果 future build 失败，只有当错误仍属于 internal symbol / visibility / marker syntax 层，才允许在本 slice 内调整。

允许调整的条件：

- 错误输出直接指向 marker syntax、visibility、default internal 或同包 symbol 编译问题。
- 调整仍只触碰一个 runtime source file 和 README / closure / indexes。
- 调整仍不添加 public declaration、function signature、import、behavior、dependency、FFI 或 smoke reference。

必须 fail closed 的情况：

- 错误要求 public API。
- 错误要求 function body 或 stable function signature。
- 错误要求 runtime behavior code。
- 错误要求 dependency、FFI、smoke C ABI、native bridge 或 package metadata 调整。
- 错误要求 `src/main.cj`、`package_anchor.cj` 或 `cjpm.toml` 改动。
- 错误要求实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 错误要求打开 Renderer / Scene / Widget / Layout / DSL。

遇到这些情况，future first slice 必须记录 blocked reason，并回到 docs-only gate。

## 11. This Round Stop-line

创建本 execution card 的本轮 stop-line：

- 不修改 [runtime/](/Users/jiangxuanyang/Desktop/cangjie/runtime/)。
- 不修改 [labs/macos_bridge_smoke/](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/)。
- 不写 runtime 代码。
- 不新增仓颉 symbol。
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

## 12. Closure Expectations

future closure review 必须记录：

- 本轮 authority。
- 查证来源。
- landed reality。
- 实际 write set。
- 选择哪个 runtime source file，为什么。
- symbol 具体形式和命名理由。
- `public_api_present=false`。
- `public_c_abi_present=false`。
- `behavior_code_present=false`。
- `internal_symbol_only=true`。
- build result。
- smoke guard result。
- forbidden file check。
- stop-line review。
- residual risks。
- current next opening。

## 13. Current Next Opening

建议下一条 opening：

> `P1 runtime internal symbol boundary first slice`

它不自动开启实现。

该 first slice 只能在本卡边界内执行；若用户未明确批准，不得写 symbol。
