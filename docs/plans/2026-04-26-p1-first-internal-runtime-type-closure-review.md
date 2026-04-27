# P1 First Internal Runtime Type Closure Review

日期：2026-04-26

性质：bounded implementation closure / first internal runtime type / no runtime behavior

状态：完成

## 0. Authority

本轮唯一 authority：

- [2026-04-26-p1-first-internal-runtime-type-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-execution-card.md)

## 1. Type / Visibility Check Sources

本轮重新查证了仓颉 package、visibility、struct 和项目规范，来源如下：

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [cangjie-lang-features/package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-lang-features/struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

查证结论：

- `package` declaration 必须是文件第一条非空 / 非注释语句。
- 同一 package 中所有文件必须使用相同 package declaration。
- 其他顶层声明默认 `internal`，可见于当前包及子包。
- `public` 为全局可见；本轮不使用 `public`。
- `struct Name {}` 是合法顶层 type declaration。
- struct 命名按 PascalCase；本轮采用 `CjguiInternalErrorFact`。

## 2. Landed Reality

新增 type 名称：

```text
CjguiInternalErrorFact
```

落点：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

实际新增的仓颉声明：

```cangjie
struct CjguiInternalErrorFact {}
```

该 type：

- 是普通默认 internal 顶层 `struct`。
- 不带 `public`。
- 不写 `import`。
- 不包含字段、函数、方法或用户定义构造逻辑。
- 只作为 future internal error facts boundary 的 compile-level placeholder。
- 不是 error strategy implementation。
- 不是 error enum。
- 不是 `Result` type。
- 不是 exception-like mechanism。
- 不是 public runtime API。
- 不是 public C ABI。
- 不是 handle、handle table、generation、多窗口或 async target message。
- 不是 AppKit / Metal / Objective-C / platform object wrapper。

同步轻量更新：

- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

README 只记录 first internal error fact type boundary，不定义 runtime behavior 或 public surface。

## 3. Actual Write Set

实际修改：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
  - 新增默认 internal `CjguiInternalErrorFact`。
  - 更新注释，明确它只是 internal error facts boundary type。
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
  - 将状态更新为 `first internal error fact type surface`。
  - 记录 `first_internal_error_fact_type_present=true`。
- [docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-first-internal-runtime-type-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未修改：

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- `runtime/cjgui/src/main.cj`
- `runtime/cjgui/src/package_anchor.cj`
- [labs/macos_bridge_smoke/](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/)
- native bridge、harness、smoke 仓颉入口或 build script

## 4. Closure Flags

```text
new_type_name=CjguiInternalErrorFact
default_internal=true
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
function_present=false
method_present=false
constructor_logic_present=false
field_present=false
import_present=false
error_enum_present=false
result_type_present=false
exception_like_mechanism_present=false
platform_object_wrapper_present=false
cjpm_toml_changed=false
smoke_changed=false
build_success=true
```

补充边界：

```text
internal_error_fact_type_present=true
error_strategy_implemented=false
handle_table_present=false
generation_present=false
renderer_scene_widget_layout_present=false
text_input_ime_accessibility_present=false
semantic_tree_action_router_present=false
command_list_hash_pixel_diff_baseline_offscreen_present=false
```

## 5. Build Result

命令：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-first-internal-runtime-type-target --skip-script
```

结果：

```text
exit_code=0
stdout_key=cjpm build success
stderr_key=none
repo_target_artifact_created=false
```

解释：

- build success 只证明 `runtime/cjgui` 可以承载一个默认 internal、无行为的 first internal error fact type。
- build success 不证明 app lifecycle、window lifecycle、platform adapter、error strategy 或任何 runtime behavior 存在。

## 6. Source Boundary Check

去掉空行和注释后，当前 runtime source 的非注释仓颉语法为：

```text
runtime/cjgui/src/app_lifecycle.cj:
package cjgui

runtime/cjgui/src/window_lifecycle.cj:
package cjgui

runtime/cjgui/src/platform_adapter.cj:
package cjgui

runtime/cjgui/src/error.cj:
package cjgui
struct CjguiInternalCompileSanityMarker {}
struct CjguiInternalErrorFact {}
```

检查结果：

- 没有新增 `public` declaration。
- 没有新增 `import`。
- 没有新增函数。
- 没有新增方法。
- 没有新增字段。
- 没有新增 public runtime API。
- 没有新增 public C ABI。
- 没有 error enum。
- 没有 `Result` type。
- 没有 exception-like mechanism。
- 没有 platform object wrapper。

## 7. Smoke Guard Result

命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

```text
exit_code=0
stdout_key=cjgui verify: auto-close log assertions passed
stdout_key=cjgui verify: this is not user-visible window verification
```

说明：

- smoke guard 仍只是旧链路 guard，不是 `runtime/cjgui` 的 public API、runtime behavior 或正式 runtime test framework。

## 8. Forbidden File Check

本轮记录的 forbidden / should-not-change 文件 hash：

```text
runtime/cjgui/cjpm.toml=20ca1465dd8abdf0c68040eb402143a17fa3171d56c272c88de94022bb253406
runtime/cjgui/src/app_lifecycle.cj=359e2bbd3adae5cefe39d56fe98eb06b08da9575118ee718e699123ba615a784
runtime/cjgui/src/window_lifecycle.cj=10efd794f2e7e45f0dea2d0c199fb59eab37cbd0624a669374aec84e5df86ee7
runtime/cjgui/src/platform_adapter.cj=9140ce39df428247e98f54daabe9ae134e5bfe892e9c9644c600149e47b9f783
labs/macos_bridge_smoke/README.md=72f313191eb1bdb6589450f6dfbf0a17c1a193914d4a89a28e367f5e6e6d22a6
labs/macos_bridge_smoke/native/cjgui_macos.m=fdf7eed26dd13b3aa1a4f3d38c62c9c4c0feba21126228d0e7040e793b027fc1
labs/macos_bridge_smoke/native/cjgui_macos.h=1de5c1e02e956df18b5b0dab8a20cbf4c303bc480896404b6b488496e333f72f
labs/macos_bridge_smoke/src/main.cj=df82c0462806b1de324a7e305754f139bf8a2285c5065ed4122fba4f1f77470d
labs/macos_bridge_smoke/scripts/build_and_run.sh=d0d1ca1b856be7ba0bd5127e3e018d4d6723a6ac76de11352387fa43f9aa9f56
labs/macos_bridge_smoke/scripts/verify_auto_close.sh=562d9d0f7dd7396a1ab0e3c0146f8687e533d0088a4c34f854d1c4e2895f41ef
labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh=749c5a2814191939757d526988b8e46daa49bd9ae1d81025fd122b726d29e4de
labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh=8268deaed192376c7753689725c658c320621f8d28de015d9f1cef24ce146b4d
```

Allowed files after this slice:

```text
runtime/cjgui/README.md=1ed9afe3fbc5fe09a342fdd8b9c195351eda08bdbe380e348732293a86dc156d
runtime/cjgui/src/error.cj=5784670982ddc6f4afeaa39783223d1b478982edf75084613791ff0419cd0c57
```

结果：

```text
cjpm_toml_changed=false
src_main_present=false
package_anchor_present=false
smoke_changed=false
harness_changed=false
native_bridge_changed=false
cangjie_smoke_entry_changed=false
```

## 9. Stop-line Review

本轮守住：

- 未修改 `cjpm.toml`。
- 未新增 `src/main.cj`。
- 未新增 `package_anchor.cj`。
- 未写 `public` declaration。
- 未写 `import`。
- 未定义函数、方法、字段或用户定义构造逻辑。
- 未定义 public runtime API。
- 未定义 public C ABI。
- 未实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 未定义 error enum / `Result` type / exception-like mechanism。
- 未迁移 smoke code / smoke C ABI / smoke `last_error`。
- 未让 runtime package 依赖 `labs/macos_bridge_smoke`。
- 未实现 handle table / generation、多窗口或 async target message。
- 未暴露 AppKit / Metal / Objective-C platform objects。
- 未进入 Renderer / Scene / Widget / Layout / DSL。
- 未进入 Dirty Rect / global tick / frame scheduler。
- 未进入 Text / Input / IME / Accessibility。
- 未进入 semantic tree / Action Router。
- 未进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## 10. Residual Risks

- `CjguiInternalErrorFact` 是第一个有语义的 internal runtime type；虽然默认 internal 且无行为，后续仍可能被误读为完整 error strategy。
- 该 type 是空 struct。仓颉编译器可能提供默认构造能力；本项目不把它解释为 public API、public C ABI 或 runtime behavior。
- 当前尚未冻结 error fact shape；不能添加字段、分类、enum、Result-like wrapper、diagnostics conversion 或 lifecycle mapping。
- 当前仍没有 runtime behavior，不能把 build success 解读为 GUI runtime 能力。

## 11. Link / Diff Check

本 closure 必须能从：

- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

找到。

## 12. Current Next Opening

建议下一条 docs-only opening：

> `P1 first internal runtime type closure / error fact shape boundary preflight`

它不自动开启下一步实现。
