# P1 Error Fact Shape Execution Card

日期：2026-04-26

性质：docs-only / execution card / error fact shape boundary

状态：完成；不自动开启实现

## 1. Architect Sign-off

本卡只把 `P1 first internal runtime type closure / error fact shape boundary preflight` 收束成未来 first slice 的受限执行卡。

创建本卡不等于实现，不授权本轮写 runtime 代码，也不授权直接进入 error strategy、public API、public C ABI 或 runtime behavior。

## 2. 唯一 Authority

唯一 authority：

- [2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-error-fact-shape-boundary-preflight.md)

其他 first internal type / error strategy / package metadata 文档只作为背景证据，不扩大本卡授权范围。

## 3. 本卡目标

未来 first slice 最多只能围绕 `CjguiInternalErrorFact` 做一个极窄的 internal error fact shape refinement。

该 refinement 的目标只能是：

> 证明 `CjguiInternalErrorFact` 可以承载一个最小、脱水、无平台对象、无行为、默认 internal 的 error fact shape。

本卡明确：

- 这不是 error strategy。
- 这不是 public API。
- 这不是 public C ABI。
- 这不是 error enum。
- 这不是 `Result` type。
- 这不是 exception-like mechanism。
- 这不是 diagnostics truth system。
- 这不是 smoke `last_error` 迁移。

diagnostics / logs 只能作为 evidence，不能成为第二状态真相源。

## 4. Future First Slice 允许范围

未来 first slice 如被单独批准，最大 write set 只能是：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- future closure review：`/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-fact-shape-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

未来 first slice 的 runtime source 变化最多只能是：

- 在 `runtime/cjgui/src/error.cj` 中给现有 `CjguiInternalErrorFact` 添加一个最小 error fact shape。
- 该 shape 必须保持默认 internal。
- 该 shape 必须脱水。
- 该 shape 不得包含 platform object、raw pointer、opaque native error object、stack trace blob、global `last_error` 或 thread-local `last_error`。
- 该 shape 不得引用 AppKit / Metal / Objective-C。
- 该 shape 不得包含函数、方法、构造逻辑、runtime behavior、import、public API 或 public C ABI。
- `runtime/cjgui/README.md` 只允许补充 error fact shape boundary 说明。

如果无法安全确认仓颉字段语法、visibility、初始化和 build 规则，future slice 必须 fail closed，不写代码。

## 5. Future First Slice 修改前必须冻结或记录

未来 first slice 修改 `CjguiInternalErrorFact` 前，必须记录以下状态；默认均为尚未定义：

```text
taxonomy_defined=false
taxonomy_status=absent / not yet defined
message_ownership_defined=false
message_ownership_status=not yet defined
source_module_defined=false
source_module_status=not yet defined
correlation_id_defined=false
correlation_id_status=not yet defined
lifetime_defined=false
lifetime_status=not yet defined
threading_defined=false
threading_status=not yet defined
serialization_defined=false
serialization_status=not yet defined
privacy_defined=false
privacy_status=not yet defined
```

如果 future slice 需要把任何一项从 `not yet defined` 改成已定义，必须确认该定义仍在本卡允许范围内；如果需要 error enum、`Result` type、public API、public C ABI、platform object、runtime behavior、smoke migration 或 diagnostics truth system，则必须 fail closed，回到 docs-only gate。

## 6. Future First Slice 禁止范围

未来 first slice 明确禁止：

- 不使用 `public`。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不定义 error enum。
- 不定义 `Result` type。
- 不定义 exception-like mechanism。
- 不实现 error strategy。
- 不实现 app lifecycle、window lifecycle 或 platform adapter behavior。
- 不写函数、方法、构造逻辑或 runtime behavior。
- 不写 `import`。
- 不把 diagnostics / logs 写成第二状态真相源。
- 不迁移 smoke `last_error`。
- 不复用 smoke C ABI。
- 不让 runtime package 依赖 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke`。
- 不包含 platform object、raw pointer、opaque native error object、stack trace blob、global `last_error` 或 thread-local `last_error`。
- 不引用 AppKit / Metal / Objective-C。
- 不定义 handle、handle table、generation、多窗口或 async target message。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 Dirty Rect、global tick、blind redraw 或 frame scheduler。
- 不进入 Text / Input / IME / Accessibility。
- 不进入 semantic tree / Action Router。
- 不进入 command-list hash、pixel diff、baseline 或 offscreen renderer。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml`。
- 不新增 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/main.cj`。
- 不新增 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/package_anchor.cj` 或等价 anchor 文件。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 7. Cangjie 语法查证要求

未来 first slice 如要修改仓颉 source，必须先查证：

- struct field declaration 语法。
- struct visibility / default internal 规则。
- struct 初始化规则。
- 空 struct 改为有字段 struct 后的 build 规则。
- `cjpm build` 命令和本地 SDK 环境要求。

优先查证来源：

- CangjieSkills 中 language features / struct / package / visibility 相关 skill。
- 本地仓颉官方文档。
- 当前项目 setup / toolchain 文档。

不能凭模型记忆猜字段语法或初始化规则。

如果查证结果要求 public API、函数、constructor logic、enum、`Result` type、dependency、FFI、smoke C ABI、native bridge 或 package metadata 调整，future slice 必须 fail closed。

## 8. Future Verification

未来 first slice 的验证至少包括：

1. 记录 Cangjie struct field / visibility / initialization / package / build 查证来源。
2. 运行：

   ```bash
   cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
   source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
   export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
   export SDKROOT="$CJ_GUI_SDKROOT"
   cjpm build --target-dir /tmp/cjgui-error-fact-shape-target --skip-script
   ```

3. 记录 exit code、stdout / stderr 关键内容。
4. 检查 `CjguiInternalErrorFact` 仍为默认 internal。
5. 检查没有 `public` declaration。
6. 检查没有 public runtime API / public C ABI。
7. 检查没有 error enum、`Result` type 或 exception-like mechanism。
8. 检查没有函数、方法、构造逻辑、import 或 runtime behavior。
9. 检查没有 platform object、raw pointer、opaque native error object、stack trace blob、global `last_error` 或 thread-local `last_error`。
10. 检查没有 AppKit / Metal / Objective-C 引用。
11. 检查 diagnostics / logs 没有被写成 state truth。
12. 检查没有 smoke dependency / smoke C ABI reference / smoke `last_error` migration。
13. 检查没有修改 `cjpm.toml`。
14. 检查没有新增 `src/main.cj` 或 `package_anchor.cj`。
15. 检查没有修改 `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口。
16. 如可行，运行 smoke guard：

    ```bash
    /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
    ```

17. `git diff --check` 必须通过。
18. closure review 必须能从 `GUI_TASK_TRACKER.md` 和 `docs/plans/README.md` 找到。

## 9. Future Closure 必须记录

future closure review 必须明确记录：

```text
error_fact_shape_refined=<true|false>
default_internal=true
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
function_present=false
method_present=false
constructor_logic_present=false
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
```

还必须记录：

- Cangjie struct field / visibility / initialization / build 查证来源。
- landed reality。
- build result。
- smoke guard result。
- forbidden file check。
- stop-line review。
- residual risks。
- current next opening。

## 10. 本轮 Stop-line

本轮创建 execution card 自身保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不修改 harness、native bridge 或仓颉入口。
- 不修改 `cjpm.toml`。
- 不写 runtime 代码。
- 不修改 `CjguiInternalErrorFact`。
- 不新增字段。
- 不新增 type、function 或 import。
- 不定义 error enum。
- 不定义 `Result` type。
- 不定义 exception-like mechanism。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 error strategy。
- 不迁移 smoke `last_error`。
- 不实现 app lifecycle、window lifecycle 或 platform adapter behavior。
- 不进入 handle table / generation、多窗口或 async target message。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 Text / Input / IME / Accessibility。
- 不进入 semantic tree / Action Router。
- 不进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 11. Current Next Opening

当前 next opening 更新为：

> `P1 error fact shape first slice`

这不自动开启实现。只有用户明确批准该 first slice，并以本 execution card 为唯一 authority 时，才允许进入未来极窄实现。
