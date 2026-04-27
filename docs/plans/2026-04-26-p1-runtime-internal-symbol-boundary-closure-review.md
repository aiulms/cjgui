# P1 Runtime Internal Symbol Boundary Closure Review

日期：2026-04-26

性质：bounded implementation closure / internal symbol compile sanity / no runtime behavior

状态：完成

## 0. Authority

本轮唯一 authority：

- [2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-execution-card.md)

## 1. Toolchain / Visibility Check Sources

本轮重新查证了仓颉 package、visibility 和最小 marker 语法，来源如下：

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [cangjie-lang-features/package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-lang-features/struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-lang-features/class/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/class/README.md)
- [cangjie-lang-features/enum/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/enum/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

查证结论：

- `package` declaration 必须是文件第一条非空 / 非注释语句。
- 普通顶层声明默认 `internal`，可见于当前包及子包；`public` 才是全局可见。
- `struct Name {}` 是合法顶层声明形式，且可不写成员、函数或 import。
- `enum` 至少需要一个构造器，容易被误读成 domain taxonomy，因此本轮不采用。
- `class` 是引用类型，语义比本轮 compile sanity marker 更重，因此本轮不采用。

## 2. Landed Reality

本轮只落了一个最小 internal compile sanity marker：

```cangjie
struct CjguiInternalCompileSanityMarker {}
```

落点：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

命名理由：

- `CjguiInternalCompileSanityMarker` 只表达 `runtime/cjgui` package 可以承载非 public symbol。
- 名称不承诺 app lifecycle、window lifecycle、platform adapter、error taxonomy、handle、Renderer、Widget、Scene、Layout、Input、IME 或 Accessibility 行为。

该 marker：

- 是普通默认 internal 顶层 `struct`。
- 不带 `public`。
- 不定义函数。
- 不定义 import。
- 不引用 smoke、FFI、platform object、AppKit、Metal 或 Objective-C。
- 不代表 error enum、Result type、lifecycle type、handle type、runtime API、public C ABI 或 runtime behavior。

## 3. Actual Write Set

实际修改：

- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)
  - 新增一个默认 internal compile sanity marker。
  - 更新注释，说明该 marker 不是 API、C ABI 或行为。
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
  - 将状态更新为 `internal symbol sanity surface`。
  - 记录 `package_declaration_only=false`、`internal_symbol_only=true` 和无行为边界。
- [docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-runtime-internal-symbol-boundary-closure-review.md)
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
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
internal_symbol_only=true
function_present=false
import_present=false
package_declaration_only=false
strict_comment_only=false
```

补充检查：

```text
explicit_public_declaration_present=false
smoke_dependency_present=false
platform_object_exposure_present=false
src_main_present=false
package_anchor_present=false
cjpm_toml_modified=false
```

## 5. Build Result

命令：

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-runtime-internal-symbol-boundary-target --skip-script
```

结果：

```text
exit_code=0
stdout_key=cjpm build success
stderr_key=none
repo_target_artifact_created=false
```

解释：

- build success 只证明 `runtime/cjgui` 可以承载一个默认 internal marker symbol 并通过当前 package build。
- build success 不证明 app lifecycle、window lifecycle、platform adapter、error strategy 或任何 runtime behavior 存在。

## 6. Smoke Guard Result

命令：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

```text
exit_code=0
stdout_key=cjgui verify: auto-close log assertions passed
```

说明：

- smoke guard 仍只是旧链路 guard，不是 `runtime/cjgui` 的 public API 或 runtime behavior 证明。

## 7. Forbidden File Check

本轮记录的 forbidden / should-not-change 文件 hash 在修改前后保持不变：

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

## 8. Stop-line Review

本轮守住：

- 未修改 `cjpm.toml`。
- 未新增 `src/main.cj`。
- 未新增 `package_anchor.cj`。
- 未定义函数。
- 未写 import。
- 未写 public declaration。
- 未定义 public runtime API。
- 未定义 public C ABI。
- 未实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 未定义 error enum / Result type。
- 未迁移 smoke code / smoke C ABI / smoke `last_error`。
- 未让 runtime package 依赖 `labs/macos_bridge_smoke`。
- 未实现 handle table / generation。
- 未暴露 AppKit / Metal / Objective-C platform objects。
- 未进入 Renderer / Scene / Widget / Layout / DSL。
- 未进入 Dirty Rect / global tick / frame scheduler。
- 未进入 Text / Input / IME / Accessibility。
- 未进入 semantic tree / Action Router。
- 未进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## 9. Residual Risks

- 这是第一处非 package declaration 的仓颉 symbol；虽然它是默认 internal marker，但仍可能被误读为未来 API 雏形。
- 仓颉 struct 文档提到编译器可能自动生成无参构造能力；本轮不把该能力解释为 public API，但后续必须通过 first internal type boundary 进一步冻结 marker / type 的长期处理。
- 当前还没有 test boundary；未来若要测试 internal symbol，需要另开 test visibility / package boundary。
- 当前仍没有 runtime behavior，不能把 build success 解读为 GUI runtime 能力。

## 10. Current Next Opening

建议下一条 docs-only opening：

> `P1 runtime internal symbol closure / first internal type boundary preflight`

它不自动开启下一步实现。
