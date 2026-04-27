# P1 First Internal Runtime Type Execution Card

日期：2026-04-26

性质：docs-only / execution card / first internal runtime type boundary

状态：完成；不自动开启实现

## 1. Architect Sign-off

本卡只把 `P1 runtime internal symbol closure / first internal type boundary preflight` 收束成未来 first slice 的受限执行卡。

创建本卡不等于实现，不授权本轮写 runtime 代码，也不授权直接进入真实 runtime behavior。

## 2. 唯一 Authority

唯一 authority：

- [2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-closure-first-internal-type-boundary-preflight.md)

其他 runtime package / internal symbol closure 文档只作为背景证据，不扩大本卡授权范围。

## 3. 本卡目标

未来 first slice 最多只能做一件事：

> 定义一个默认 internal、无行为、无 `public`、无 `import`、无 public runtime API / public C ABI 的最小语义 type，用来验证 `runtime/cjgui` 可以承载第一枚有语义但不含行为的 internal domain type。

第一候选边界是：

> `internal error facts boundary`

该候选只用于表达 runtime 内部错误事实的最小语义占位，不实现 error strategy，不定义 error enum，不定义 `Result` type，不引入 exception-like 机制。

## 4. Future First Slice 允许范围

未来 first slice 如被单独批准，最大 write set 只能是：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- future closure review：`/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

未来 first slice 的 runtime source 变化只能是：

- 在 `runtime/cjgui/src/error.cj` 中新增一个默认 internal 的最小 error-facts type。
- 该 type 不能带 `public`。
- 该 type 不能包含函数、方法、构造逻辑、runtime behavior、import、platform / smoke / FFI 引用。
- 该 type 不能被描述为 public API、public C ABI、error enum、`Result` type、exception-like 机制、handle、window target、platform object wrapper 或 error strategy implementation。
- `runtime/cjgui/README.md` 只允许补充 first internal type / internal error facts boundary 说明。

如果未来实现前无法从 CangjieSkills 或本地官方文档确认安全的最小 type 语法，必须 fail closed，不得凭模型记忆硬写。

## 5. Future First Slice 禁止范围

未来 first slice 明确禁止：

- 不使用 `public`。
- 不定义函数、方法、构造逻辑或 runtime behavior。
- 不写 `import`。
- 不定义 error enum、`Result` type 或 exception-like 机制。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter 或 error strategy。
- 不定义 handle、handle table、generation、多窗口或 async target message。
- 不暴露 AppKit、Metal、Objective-C 或 platform object wrapper。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect、global tick、blind redraw 或 frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash、pixel diff、baseline 或 offscreen renderer。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml`。
- 不新增 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/main.cj`。
- 不新增 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/package_anchor.cj` 或等价 anchor 文件。
- 不迁移 smoke code、smoke C ABI 或 smoke `last_error`。
- 不让 runtime package 依赖 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke`、harness、native bridge 或仓颉入口。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 6. Cangjie 语法查证要求

未来 first slice 必须先查证仓颉 type / visibility / package 规则，优先使用：

- CangjieSkills 中与 language features / package / declaration / visibility / type syntax 相关的 skill。
- 本地仓颉官方文档。
- 当前项目已验证的 toolchain / package 文档。

查证结果必须写入 closure review。

如果查证显示最小 type 必须扩展为函数、public declaration、constructor logic、enum、Result-like structure、import、dependency、FFI 或 package metadata 调整，future slice 必须 fail closed，回到 docs-only gate。

## 7. Future Verification

未来 first slice 的验证至少包括：

1. 记录 Cangjie type / visibility / package 规则查证来源。
2. 运行：

   ```bash
   cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
   source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
   export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
   export SDKROOT="$CJ_GUI_SDKROOT"
   cjpm build --target-dir /tmp/cjgui-first-internal-runtime-type-target --skip-script
   ```

3. 记录 exit code、stdout / stderr 关键内容。
4. 检查没有 `public` declaration。
5. 检查没有函数、方法、构造逻辑、import 或 runtime behavior。
6. 检查没有 error enum、`Result` type 或 exception-like 机制。
7. 检查没有 public runtime API / public C ABI。
8. 检查没有 smoke dependency / smoke C ABI reference / smoke `last_error` migration。
9. 检查没有修改 `cjpm.toml`。
10. 检查没有新增 `src/main.cj` 或 `package_anchor.cj`。
11. 检查没有修改 `labs/macos_bridge_smoke` source / harness / native bridge / 仓颉入口。
12. 如可行，运行 smoke guard：

    ```bash
    /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
    ```

13. `git diff --check` 必须通过。
14. closure review 必须能从 `GUI_TASK_TRACKER.md` 和 `docs/plans/README.md` 找到。

## 8. Future Closure 必须记录

future closure review 必须明确记录：

- `public_api_present=false`
- `public_c_abi_present=false`
- `behavior_code_present=false`
- `internal_type_only=true`
- `function_present=false`
- `method_present=false`
- `constructor_logic_present=false`
- `import_present=false`
- `error_enum_present=false`
- `result_type_present=false`
- `toolchain_type_check_source=<实际查证来源>`
- landed reality
- build result
- smoke guard result
- forbidden file check
- stop-line review
- residual risks
- current next opening

## 9. 本轮 Stop-line

本轮创建 execution card 自身保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不定义新的仓颉 type、function、method、import 或 runtime behavior。
- 不修改 `cjpm.toml`。
- 不新增 `src/main.cj` 或 `package_anchor.cj`。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 app lifecycle、window lifecycle、platform adapter 或 error strategy。
- 不定义 error enum / `Result` type。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不实现 handle table / generation。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不进入 Renderer / Scene / Widget / Layout / DSL。
- 不进入 Dirty Rect / global tick / frame scheduler。
- 不进入 Text / Input / IME / Accessibility。
- 不进入 semantic tree / Action Router。
- 不进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 10. Current Next Opening

当前 next opening 更新为：

> `P1 first internal runtime type first slice`

这不自动开启实现。只有用户明确批准该 first slice，并以本 execution card 为唯一 authority 时，才允许进入未来极窄实现。
