# P1 Error Taxonomy Boundary Execution Card

日期：2026-04-26

性质：docs-only / execution card / error taxonomy boundary

状态：完成；不自动开启实现

## 1. Architect Sign-off

本卡把 [P1 error fact shape closure / error taxonomy boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md) 收束成受限 execution card。

创建本卡不等于实现。当前仍不写 runtime 代码，不修改 `runtime/`，不修改 `CjguiInternalErrorFact`，不定义 taxonomy，不实现 error strategy。

## 2. 唯一 Authority

本卡唯一 authority 是：

- [2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-error-taxonomy-boundary-preflight.md)

如本卡与其他历史说明冲突，以该 authority 的边界为准。

## 3. 本卡目标

本卡只冻结 future error taxonomy marker first slice 的最窄边界：

- future taxonomy owner 倾向属于 `runtime/cjgui` error strategy module。
- 该 owner 倾向仍不是 error strategy implementation。
- future first slice 最多只能创建一个默认 internal、无行为、无 `public`、无 `import` 的 taxonomy marker / placeholder。
- 该 marker 只表达：taxonomy boundary exists but taxonomy is not yet defined。
- 它不能定义完整 taxonomy，不能定义 error enum，不能定义 `Result` type，不能定义 severity / category / code 字段。

## 4. Future First Slice 允许范围

如果用户后续明确批准 `P1 error taxonomy marker first slice`，future first slice 的最大允许 runtime write set 只能是：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`

future first slice 的最大允许文档 write set 只能是：

- future closure review：`/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-taxonomy-marker-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

future first slice 只能在 `runtime/cjgui/src/error.cj` 中新增一个默认 internal taxonomy marker / placeholder type。该 marker 必须：

- 默认 internal，不带 `public`。
- 无字段，除非另有 execution card 明确批准。
- 无函数、方法、显式 init、构造逻辑或 runtime behavior。
- 无 `import`。
- 不修改 `CjguiInternalErrorFact`。
- 不引用 smoke、FFI、platform object、AppKit、Metal 或 Objective-C。
- 不定义 public runtime API。
- 不定义 public C ABI。

## 5. Future First Slice 禁止范围

future first slice 不允许：

- 定义完整 taxonomy。
- 定义 error enum。
- 定义 `Result` type。
- 定义 exception-like mechanism。
- 定义 severity / category / code 字段。
- 修改 `CjguiInternalErrorFact`。
- 把 taxonomy 写进 public API。
- 定义 public C ABI。
- 把 diagnostics / logs 写成第二状态真相源。
- 迁移 smoke `last_error`。
- 使用 platform object、raw pointer、opaque native error object、stack trace blob、global `last_error` 或 thread-local `last_error`。
- 引用 AppKit / Metal / Objective-C。
- 定义 handle、handle table、generation、多窗口或 async target message。
- 进入 Renderer / Scene / Widget / Layout / DSL。
- 进入 Text / Input / IME / Accessibility。
- 进入 semantic tree / Action Router。
- 进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 修改 `cjpm.toml`。
- 新增 `src/main.cj`。
- 新增 `package_anchor.cj`。
- 修改 `labs/macos_bridge_smoke/`、harness、native bridge 或仓颉入口。
- 迁移 smoke code 或让 runtime package 依赖 `labs/macos_bridge_smoke`。
- 创建 `CJGUI_TRUTH_MANIFEST.md`。

## 6. Cangjie 查证要求

future first slice 如果要写仓颉 source，必须先查证 CangjieSkills / 本地官方文档，至少覆盖：

- struct / enum / type declaration 规则。
- visibility / default internal 规则。
- package / build 规则。
- 空 marker type 与有字段 type 的初始化差异。

future first slice 必须倾向选择不会打开 enum、`Result`、public API 或 behavior 的最小形式。如果无法安全确认最小 marker 语法，必须 fail closed，不写代码，回到 docs-only gate。

## 7. Future Verification

future first slice 的验证必须包括：

1. 记录实际查证的 CangjieSkills / 本地官方文档来源。
2. 运行：

   ```bash
   cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
   source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
   export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
   export SDKROOT="$CJ_GUI_SDKROOT"
   cjpm build --target-dir /tmp/cjgui-error-taxonomy-marker-target --skip-script
   ```

3. 记录 exit code、stdout / stderr 关键内容。
4. 检查没有 `public` declaration。
5. 检查没有函数、方法、显式 init、构造逻辑或 runtime behavior。
6. 检查没有 `import`。
7. 检查没有 error enum、`Result` type、exception-like mechanism、severity / category / code 字段。
8. 检查没有修改 `CjguiInternalErrorFact`。
9. 检查没有 public runtime API / public C ABI。
10. 检查没有 diagnostics truth system。
11. 检查没有 smoke dependency / smoke C ABI reference / smoke `last_error` migration。
12. 检查没有 platform object、raw pointer、opaque native error object、stack trace blob、global `last_error`、thread-local `last_error`、AppKit / Metal / Objective-C reference。
13. 检查没有修改 `cjpm.toml`，没有新增 `src/main.cj` 或 `package_anchor.cj`。
14. 检查没有修改 `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口。
15. 如可行，运行 smoke guard：

    ```bash
    /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
    ```

16. `git diff --check` 必须通过。
17. closure review 必须能从 `GUI_TASK_TRACKER.md` 和 `docs/plans/README.md` 找到。

## 8. Future Closure 必须记录

future closure review 必须明确记录：

- `taxonomy_marker_present=<true|false>`
- `taxonomy_defined=false`
- `full_taxonomy_present=false`
- `error_enum_present=false`
- `result_type_present=false`
- `severity_field_present=false`
- `category_field_present=false`
- `code_field_present=false`
- `cjgui_internal_error_fact_changed=false`
- `default_internal=<true|false>`
- `public_api_present=false`
- `public_c_abi_present=false`
- `behavior_code_present=false`
- `function_present=false`
- `method_present=false`
- `explicit_init_present=false`
- `import_present=false`
- `diagnostics_truth_system_present=false`
- `smoke_last_error_migrated=false`
- `platform_object_present=false`
- `raw_pointer_present=false`
- `opaque_native_error_object_present=false`
- `stack_trace_blob_present=false`
- `global_last_error_present=false`
- `thread_local_last_error_present=false`
- `appkit_metal_objective_c_reference_present=false`
- `handle_generation_present=false`
- `cjpm_toml_changed=false`
- `smoke_changed=false`
- `build_success=<true|false>`

如果 build 失败，只有当错误仍属于 taxonomy marker / visibility / syntax 层，才允许在 future slice 内调整。若错误要求 public API、function body、behavior code、dependency、FFI、smoke C ABI、native bridge、package metadata 调整或修改 `CjguiInternalErrorFact`，必须 fail closed，记录 blocked reason，回到 docs-only gate。

## 9. 本轮 Stop-line

创建本卡这一轮保持：

- 不修改 `runtime/`。
- 不修改 `labs/macos_bridge_smoke/`。
- 不修改 harness、native bridge、仓颉入口或 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact`。
- 不新增 type / function / import。
- 不定义 error enum、`Result` type、severity / category / code 字段。
- 不定义 public runtime API 或 public C ABI。
- 不实现 error strategy。
- 不迁移 smoke `last_error`。
- 不实现 app/window/platform behavior。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 Text / Input / IME / Accessibility。
- 不进入 semantic tree / Action Router。
- 不进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 10. Current Next Opening

当前 next opening 更新为：

`P1 error taxonomy marker first slice`

它不自动开启实现。只有用户明确批准后，才允许按本 execution card 的 future first slice 边界继续。
