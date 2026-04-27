# P1 Error Fact Shape Closure Review

日期：2026-04-26

性质：implementation first slice closure / minimal internal error fact shape

状态：完成

## 1. Authority

唯一 authority：

- [2026-04-26-p1-error-fact-shape-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-execution-card.md)

本轮只允许给现有 `CjguiInternalErrorFact` 添加一个最小、脱水、无行为、默认 internal 的 error fact shape 字段。

## 2. Cangjie Syntax Check Sources

本轮修改前查证了：

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [basic_concepts/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/basic_concepts/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

查证结论：

- `package` declaration 必须是第一条非空 / 非注释行，同一包文件保持一致。
- 顶层 struct 默认 visibility 为 `internal`。
- struct body 可包含实例成员变量。
- `let` 字段表示不可变成员。
- `Bool`、`false` 是合法类型和值。
- 布尔字段命名可使用 `has` 前缀。

## 3. Red Check

修改前现实：

- `CjguiInternalErrorFact` 是空 struct。
- `hasNativePayload` expected_missing=true。
- baseline build 通过。

baseline 命令：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-error-fact-shape-baseline-target --skip-script
```

baseline 结果：

```text
exit_code=0
stdout=cjpm build success
stderr=<empty>
```

## 4. Landed Reality

实际修改：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

`CjguiInternalErrorFact` 当前 shape：

```cangjie
struct CjguiInternalErrorFact {
    let hasNativePayload: Bool = false
}
```

该字段只证明最小脱水 shape 可编译：

- 它表示当前 error fact 不携带 native payload。
- 它不定义 error taxonomy。
- 它不定义 message ownership。
- 它不定义 source module。
- 它不定义 correlation id。
- 它不定义 lifetime。
- 它不定义 threading。
- 它不定义 serialization。
- 它不定义 privacy。
- 它不是 error strategy。
- 它不是 diagnostics truth system。

## 5. Required Flags

```text
error_fact_shape_refined=true
added_field_name=hasNativePayload
added_field_type=Bool
added_field_default=false
default_internal=true
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
function_present=false
method_present=false
explicit_init_present=false
import_present=false
error_enum_present=false
result_type_present=false
exception_like_mechanism_present=false
diagnostics_truth_system_present=false
smoke_last_error_migrated=false
platform_object_present=false
raw_pointer_present=false
opaque_native_error_object_present=false
stack_trace_blob_present=false
global_last_error_present=false
thread_local_last_error_present=false
appkit_metal_objective_c_reference_present=false
handle_generation_present=false
cjpm_toml_changed=false
smoke_changed=false
build_success=true
```

## 6. Build Result

命令：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-error-fact-shape-target --skip-script
```

结果：

```text
exit_code=0
stdout=cjpm build success
stderr=<empty>
```

## 7. Smoke Guard Result

命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

```text
exit_code=0
key_output=cjgui verify: auto-close log assertions passed
```

## 8. Forbidden File Check

本轮没有修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/main.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/package_anchor.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke`
- harness
- native bridge
- 仓颉 smoke 入口

`src/main.cj` 与 `src/package_anchor.cj` 仍不存在。

## 9. Stop-line Review

守住：

- 不新增其他字段。
- 不使用 `public`。
- 不新增 import。
- 不新增函数、方法或显式 init。
- 不定义 error enum。
- 不定义 `Result` type。
- 不定义 exception-like mechanism。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 error strategy。
- 不迁移 smoke `last_error`。
- 不包含 platform object、raw pointer、opaque native error object、stack trace blob、global `last_error` 或 thread-local `last_error`。
- 不引用 AppKit / Metal / Objective-C。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不修改 smoke / harness / native bridge / 仓颉入口。

## 10. Residual Risks

仍未冻结：

- error taxonomy。
- message ownership。
- source module。
- correlation id。
- lifetime。
- threading。
- serialization。
- privacy。
- app/window/platform 到 error fact 的真实数据流。
- error fact 与 diagnostics / logs 的输出边界。

这些都不能通过本轮字段反推为已实现。

## 11. Current Next Opening

当前 next opening 更新为 docs-only：

`P1 error fact shape closure / error taxonomy boundary preflight`

该 opening 只应复核本轮 shape 并冻结未来 error taxonomy 边界，不自动开启 error strategy、public API、public C ABI、error enum、`Result` type 或 runtime behavior implementation。
