# P1 First Compilable Runtime Source Execution Card

日期：2026-04-26

性质：docs-only execution card / first compilable source authorization / no implementation

状态：完成；不自动开启实现

## 0. Architect Sign-off

架构管理师确认：

- 状态：本轮只创建 execution card，不等于批准立即实现。
- 确认依据：[P1 first compilable runtime source boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md)

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：是。
- 上层尽量仓颉原生：是，但本轮不写仓颉 runtime code。
- 底层只保留必要平台桥接：是；本卡禁止迁移 smoke bridge。
- 没有过早抽象跨平台：是；本卡只处理 `runtime/cjgui` package identity。

## 1. Authority

本卡唯一 authority：

- [2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-boundary-preflight.md)

历史文档只作为背景，不得扩大本卡授权范围。

## 2. Goal

本卡目标：

- 将 `P1 first compilable runtime source boundary preflight` 收束成未来一个极窄 first slice 的 execution card。
- 未来 first slice 只能把现有四个 `runtime/cjgui/src/*.cj` 从“缺 package declaration”推进到“最小可编译 source”验证。
- 创建本 execution card 本身不等于实现。

未来 first slice 的唯一 runtime source 动作：

> 给现有四个 `runtime/cjgui/src/*.cj` 添加一致的 `package cjgui` declaration。

该动作只建立 package identity，不定义 runtime API，不实现 runtime behavior。

## 3. Future First Slice Scope

未来 first slice 只允许修改以下四个 runtime source：

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

每个文件只允许添加同一个 package declaration：

```cangjie
package cjgui
```

约束：

- `package cjgui` 必须是每个文件的第一个非空 / 非注释行。
- 四个文件必须使用完全相同的 package declaration。
- 其余内容继续保持既有注释边界。
- 不允许写函数、类型、import、public runtime API、public C ABI 或 runtime behavior。
- 不允许把 package declaration 解释为 app / window / platform / error surface 的实现。

## 4. Package Declaration Boundary

本卡承接 preflight 的查证结论：

- 当前 `cjpm build` 失败原因是 `runtime/cjgui/src` 缺少与 `cjpm.toml` 中 `name = "cjgui"` 匹配的 package declaration。
- 仓颉 package declaration 必须位于文件第一个非空 / 非注释行。
- 同一包中的所有文件必须具有相同 package declaration。
- 当前 `output-type = "static"`，默认不需要 `src/main.cj` executable entry。

因此未来 first slice 不使用单独 `package_anchor.cj`，也不新增 `src/main.cj`。默认只给现有四个 surface 文件添加 `package cjgui`。

## 5. Future Write Set

未来 first slice 最大允许 write set：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
  - 只允许补充 package declaration / first compilable source 说明。
- future closure review：
  - `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-compilable-runtime-source-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## 6. Future Forbidden Set

未来 first slice 禁止：

- 不新增 `src/main.cj`。
- 不新增 `package_anchor.cj`。
- 不修改 `cjpm.toml`。
- 不定义函数。
- 不定义类型。
- 不写 import。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 不定义 error enum / Result type。
- 不迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- 不让 runtime package 依赖 `labs/macos_bridge_smoke`。
- 不修改 `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口。
- 不实现 handle table / generation。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 7. Truth / Projection

未来 first slice 的 truth：

- 四个 `runtime/cjgui/src/*.cj` 是否具有一致的 `package cjgui` declaration。
- `package cjgui` 是否位于每个文件第一条非空 / 非注释行。
- `cjpm build --target-dir ... --skip-script` 的真实 exit code 与关键 stdout / stderr。
- 是否没有新增函数、类型、import、public API、public C ABI 或 runtime behavior。

不是 truth 的内容：

- package declaration 不是 public runtime API。
- package declaration 不是 app/window lifecycle behavior。
- `cjpm build` 通过不代表 runtime 已实现。
- smoke guard 日志不是 runtime package truth。
- diagnostics 不是第二状态真相源。

## 8. Future Closure Required Fields

未来 closure review 必须明确区分：

```text
strict_comment_only=false
package_declaration_only=true
behavior_code_present=false
public_api_present=false
```

解释：

- `strict_comment_only=false` 只表示 `.cj` 中出现了 package declaration。
- `package_declaration_only=true` 表示除 package declaration 外没有任何非注释仓颉语法。
- `behavior_code_present=false` 表示没有 runtime behavior。
- `public_api_present=false` 表示没有 public runtime API 或 public C ABI。

## 9. Future Verification

未来 first slice 必须重新确认仓颉 package declaration 规则，并记录查证来源。

未来 first slice 必须运行：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-first-compilable-runtime-source-target --skip-script
```

验证记录必须包含：

- exit code。
- stdout / stderr 关键内容。
- 是否生成仓库内 artifact。
- 是否留下仓库内 `target/`。
- 四个 `.cj` 文件是否只新增 `package cjgui` declaration。
- `package cjgui` 是否为每个文件第一条非空 / 非注释行。
- 没有函数、类型、import、public runtime API、public C ABI 或 runtime behavior。
- 没有新增 `src/main.cj`。
- 没有新增 `package_anchor.cj`。
- 没有修改 `cjpm.toml`。
- 没有 smoke dependency / smoke C ABI reference。
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

如果 future build 仍失败，只有当错误仍属于 package declaration / package identity 层，才允许在本 slice 内调整。

允许调整的条件：

- 错误输出直接指向 package declaration / package identity。
- 调整仍不添加函数、类型、import、public API、public C ABI 或 runtime behavior。
- 调整不新增 `src/main.cj`、`package_anchor.cj`，不修改 `cjpm.toml`，除非另有 docs-only gate。

必须 fail closed 的情况：

- 错误要求函数、类型、`main` entry、public declaration 或 behavior code。
- 错误要求依赖、FFI、smoke C ABI、native bridge 或 output-type 调整。
- 错误要求迁移 smoke code。
- 错误要求实现 app/window/platform/error behavior。
- 错误要求打开 Renderer / Scene / Widget / Layout / DSL。

遇到这些情况，future first slice 必须记录 blocked reason，并回到 docs-only gate。

## 11. This Round Stop-line

创建本 execution card 的本轮 stop-line：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不写非注释仓颉语法。
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

## 12. Next Opening

本卡之后推荐的下一条 opening：

> `P1 first compilable runtime source first slice`

它不自动开启实现。必须由用户明确批准后，才能按本卡执行 future bounded implementation first slice。
