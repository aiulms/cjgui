# P1 Error Taxonomy Marker Closure Review

日期：2026-04-26

性质：bounded implementation closure / internal taxonomy marker / no runtime behavior

状态：完成

## 1. Authority

本轮唯一 authority：

- [2026-04-26-p1-error-taxonomy-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-boundary-execution-card.md)

本轮只允许新增一个默认 internal、无行为、无 public、无 import 的 error taxonomy marker / placeholder type。

## 2. Cangjie Syntax Check Sources

本轮修改前查证了：

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [cangjie-lang-features/package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-lang-features/struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

查证结论：

- `package` declaration 必须是第一条非空 / 非注释行。
- 同一包文件必须使用一致 package declaration。
- 顶层声明默认 visibility 为 `internal`。
- `struct Name {}` 是合法顶层 struct declaration。
- struct 命名遵循 PascalCase。
- 本轮不考虑 enum，因此未打开 enum 文档；execution card 明确禁止 error enum。

## 3. Red Check

修改前现实：

```text
taxonomy_marker_expected_missing=true
src/main.cj_absent=true
package_anchor.cj_absent=true
baseline_build_success=true
```

baseline build 命令：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-error-taxonomy-marker-baseline-target --skip-script
```

baseline 结果：

```text
exit_code=0
stdout=cjpm build success
stderr=<empty>
```

## 4. Landed Reality

新增 marker 名称：

```text
CjguiInternalErrorTaxonomyMarker
```

落点：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

实际新增声明：

```cangjie
struct CjguiInternalErrorTaxonomyMarker {}
```

该 marker：

- 是普通默认 internal 顶层 `struct`。
- 只表达 taxonomy boundary exists but taxonomy is not yet defined。
- 不带 `public`。
- 不包含字段。
- 不包含函数、方法、显式 init、构造逻辑或 runtime behavior。
- 不写 `import`。
- 不修改 `CjguiInternalErrorFact`。
- 不是完整 taxonomy。
- 不是 error enum。
- 不是 `Result` type。
- 不是 exception-like mechanism。
- 不是 public runtime API。
- 不是 public C ABI。
- 不是 diagnostics truth system。
- 不是 smoke `last_error` migration。

同步轻量更新：

- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

README 只记录 taxonomy marker boundary，不定义 runtime behavior 或 public surface。

## 5. Actual Write Set

实际修改：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未修改：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- `runtime/cjgui/src/main.cj`
- `runtime/cjgui/src/package_anchor.cj`
- [labs/macos_bridge_smoke/](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/)
- harness
- native bridge
- 仓颉 smoke 入口

`src/main.cj` 与 `src/package_anchor.cj` 仍不存在。

## 6. Required Flags

```text
taxonomy_marker_added=true
taxonomy_marker_name=CjguiInternalErrorTaxonomyMarker
taxonomy_defined=false
error_enum_present=false
result_type_present=false
severity_field_present=false
category_field_present=false
code_field_present=false
error_fact_modified=false
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
function_present=false
method_present=false
explicit_init_present=false
import_present=false
diagnostics_truth_system_present=false
smoke_last_error_migrated=false
platform_object_present=false
raw_pointer_present=false
appkit_metal_objective_c_reference_present=false
cjpm_toml_changed=false
smoke_changed=false
build_success=true
```

补充边界：

```text
full_taxonomy_present=false
exception_like_mechanism_present=false
opaque_native_error_object_present=false
stack_trace_blob_present=false
global_last_error_present=false
thread_local_last_error_present=false
handle_generation_present=false
```

## 7. Build Result

命令：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-error-taxonomy-marker-target --skip-script
```

结果：

```text
exit_code=0
stdout=cjpm build success
stderr=<empty>
```

解释：

- build success 只证明 `runtime/cjgui` 可以承载一个默认 internal、无行为、无字段的 taxonomy marker。
- build success 不证明 error taxonomy、error strategy、Result model、public API、public C ABI 或 runtime behavior 存在。

## 8. Source Boundary Check

去掉空行和注释后，当前 `runtime/cjgui/src/error.cj` 的非注释仓颉语法为：

```text
package cjgui
struct CjguiInternalCompileSanityMarker {}
struct CjguiInternalErrorFact {
    let hasNativePayload: Bool = false
}
struct CjguiInternalErrorTaxonomyMarker {}
```

检查结果：

- 没有新增 `public` declaration。
- 没有新增 import。
- 没有新增函数。
- 没有新增方法。
- 没有新增显式 init。
- 没有新增 error enum。
- 没有新增 `Result` type。
- 没有新增 severity / category / code 字段。
- 没有 public runtime API。
- 没有 public C ABI。
- 没有 diagnostics truth system。
- 没有 smoke dependency / smoke C ABI reference / smoke `last_error` migration。
- 没有 platform object、raw pointer、opaque native error object、stack trace blob、global `last_error`、thread-local `last_error` 或 AppKit / Metal / Objective-C reference。

## 9. Smoke Guard Result

命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

```text
exit_code=0
key_output=cjgui verify: auto-close log assertions passed
```

该 guard 仍只验证旧 smoke 链路，不是正式 runtime test framework。

## 10. Forbidden File Check

本轮先记录 forbidden write set hash baseline，再在修改后复核。

复核范围：

- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/src/app_lifecycle.cj`
- `runtime/cjgui/src/window_lifecycle.cj`
- `runtime/cjgui/src/platform_adapter.cj`
- `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口

结果：通过，forbidden write set hash 未变化。

## 11. Stop-line Review

守住：

- 不修改 `CjguiInternalErrorFact`。
- 不新增字段。
- 不使用 `public`。
- 不新增 import。
- 不新增函数、方法或显式 init。
- 不定义 error enum。
- 不定义 `Result` type。
- 不定义 severity / category / code 字段。
- 不定义 exception-like mechanism。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 error strategy。
- 不把 diagnostics 写成第二状态真相源。
- 不迁移 smoke `last_error`。
- 不包含 platform object、raw pointer、opaque native error object、stack trace blob、global `last_error` 或 thread-local `last_error`。
- 不引用 AppKit / Metal / Objective-C。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 smoke / harness / native bridge / 仓颉入口。

## 12. Residual Risks

仍未冻结：

- recoverability boundary。
- closed / open taxonomy policy。
- severity / category / code 是否存在。
- error taxonomy owner 的真实数据流。
- app/window/platform 如何产生或消费 taxonomy marker 后续形态。
- message ownership、source module、correlation id、lifetime、threading、serialization、privacy。

这些都不能通过本轮 marker 反推为已实现。

## 13. Current Next Opening

当前 next opening 更新为 docs-only：

`P1 error taxonomy marker closure / recoverability boundary preflight`

它不自动开启实现。
