# P1 First Internal App Lifecycle State 封账复盘

日期: 2026-04-27

性质: bounded implementation closure / first internal app lifecycle state marker / no runtime behavior

状态: 完成

## 0. 授权依据

本轮唯一 authority:

- [2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-execution-card.md)

## 1. 工具链 / 语法检查来源

本轮查证了仓颉 package、visibility、struct 和项目规范, 来源如下:

- [cangjie-lang-features/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/SKILL.md)
- [cangjie-lang-features/package/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/package/README.md)
- [cangjie-lang-features/struct/README.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-lang-features/struct/README.md)
- [cangjie-regulations/SKILL.md](/Users/jiangxuanyang/Desktop/cangjie/repos/CangjieSkills/.agents/skills/cangjie-regulations/SKILL.md)

查证结论:

- `package` declaration 必须是文件第一条非空 / 非注释语句。
- 同一 package 中所有文件必须使用相同 package declaration。
- 其他顶层声明默认 `internal`, 可见于当前包及子包。
- `public` 为全局可见; 本轮不使用 `public`。
- `struct Name {}` 是合法顶层 type declaration。
- struct 命名按 PascalCase; 本轮采用 `CjguiInternalAppLifecycleState`。

## 2. 红灯检查

修改前检查:

```text
target_marker_expected_missing=true
baseline_build_exit_code=0
baseline_build_stdout_key=cjpm build success
```

## 3. 落地现实

新增 marker 名称:

```text
CjguiInternalAppLifecycleState
```

落点:

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)

实际新增的仓颉声明:

```cangjie
struct CjguiInternalAppLifecycleState {}
```

该 marker:

- 是普通默认 internal 顶层 `struct`。
- 不带 `public`。
- 不写 `import`。
- 不包含字段、函数、方法或显式 init。
- 只表达 app lifecycle state boundary exists but lifecycle state machine is not yet defined.
- 不是 `run`、`shutdown`、`request quit`、queue、drain、platform callback binding、window lifecycle behavior、error strategy behavior、public runtime API 或 public C ABI。

同步轻量更新:

- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

README 只记录 first internal app lifecycle state marker boundary, 不定义 runtime behavior 或 public surface。

## 4. 实际修改范围

实际修改:

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

未修改:

- [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- `runtime/cjgui/src/main.cj`
- `runtime/cjgui/src/package_anchor.cj`
- [labs/macos_bridge_smoke/](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/)
- native bridge、harness、smoke 仓颉入口或 build script

## 5. 封账标记

```text
app_lifecycle_state_marker_added=true
app_lifecycle_state_marker_name=CjguiInternalAppLifecycleState
state_machine_defined=false
run_behavior_present=false
shutdown_behavior_present=false
request_quit_behavior_present=false
queue_behavior_present=false
drain_behavior_present=false
public_api_present=false
public_c_abi_present=false
behavior_code_present=false
field_present=false
function_present=false
method_present=false
explicit_init_present=false
import_present=false
platform_object_present=false
appkit_metal_objective_c_reference_present=false
cjpm_toml_changed=false
smoke_changed=false
build_success=true
```

说明: `appkit_metal_objective_c_reference_present=false` 指本轮新增 marker 和非注释 runtime syntax; 既有注释中的平台词仍只作为禁止事项存在。

## 6. 构建结果

命令:

```bash
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
export CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
export SDKROOT="$CJ_GUI_SDKROOT"
cjpm build --target-dir /tmp/cjgui-first-internal-app-lifecycle-state-target --skip-script
```

结果:

```text
exit_code=0
stdout_key=cjpm build success
stderr_key=none
repo_target_artifact_created=false
```

解释:

- build success 只证明 `runtime/cjgui` 可以承载一个默认 internal、无字段、无行为的 app lifecycle state marker。
- build success 不证明 app lifecycle state machine、`run`、`shutdown`、`request quit`、queue、drain 或任何 runtime behavior 存在。

## 7. 源码边界检查

去掉空行和注释后, 当前 `runtime/cjgui/src/app_lifecycle.cj` 的非注释仓颉语法为:

```text
package cjgui
struct CjguiInternalAppLifecycleState {}
```

检查结果:

- 没有新增 `public` declaration。
- 没有新增 `import`。
- 没有新增字段。
- 没有新增函数。
- 没有新增方法。
- 没有新增显式 init。
- 没有 runtime behavior。
- 没有 public runtime API。
- 没有 public C ABI。

## 8. Smoke guard 结果

命令:

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果:

```text
exit_code=0
stdout_key=cjgui verify: auto-close log assertions passed
stdout_key=cjgui verify: this is not user-visible window verification
```

说明:

- smoke guard 仍只是旧链路 guard, 不是 `runtime/cjgui` 的 public API、runtime behavior 或正式 runtime test framework。

## 9. 禁止文件检查

本轮记录的 forbidden / should-not-change 文件 hash 在修改前后保持不变:

```text
runtime/cjgui/cjpm.toml=20ca1465dd8abdf0c68040eb402143a17fa3171d56c272c88de94022bb253406
labs/macos_bridge_smoke/README.md=72f313191eb1bdb6589450f6dfbf0a17c1a193914d4a89a28e367f5e6e6d22a6
labs/macos_bridge_smoke/native/cjgui_macos.m=fdf7eed26dd13b3aa1a4f3d38c62c9c4c0feba21126228d0e7040e793b027fc1
labs/macos_bridge_smoke/native/cjgui_macos.h=1de5c1e02e956df18b5b0dab8a20cbf4c303bc480896404b6b488496e333f72f
labs/macos_bridge_smoke/src/main.cj=df82c0462806b1de324a7e305754f139bf8a2285c5065ed4122fba4f1f77470d
labs/macos_bridge_smoke/scripts/build_and_run.sh=d0d1ca1b856be7ba0bd5127e3e018d4d6723a6ac76de11352387fa43f9aa9f56
labs/macos_bridge_smoke/scripts/verify_auto_close.sh=562d9d0f7dd7396a1ab0e3c0146f8687e533d0088a4c34f854d1c4e2895f41ef
labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_feasibility.sh=749c5a2814191939757d526988b8e46daa49bd9ae1d81025fd122b726d29e4de
labs/macos_bridge_smoke/scripts/verify_user_visible_window_screenshot_verification.sh=8268deaed192376c7753689725c658c320621f8d28de015d9f1cef24ce146b4d
```

结果:

```text
cjpm_toml_changed=false
src_main_present=false
package_anchor_present=false
smoke_changed=false
harness_changed=false
native_bridge_changed=false
cangjie_smoke_entry_changed=false
```

## 10. Stop-line 复查

本轮守住:

- 未修改 `cjpm.toml`。
- 未新增 `src/main.cj`。
- 未新增 `package_anchor.cj`。
- 未写字段。
- 未写 `public` declaration。
- 未写 `import`。
- 未定义函数、方法、显式 init 或构造逻辑。
- 未实现 runtime behavior。
- 未实现 `run` / `shutdown` / `request quit` / queue / drain。
- 未实现 platform adapter callback binding。
- 未实现 window lifecycle behavior。
- 未实现 error strategy behavior。
- 未定义 public runtime API。
- 未定义 public C ABI。
- 未修改 smoke / harness / native bridge / 仓颉入口。
- 未进入 Renderer / Scene / Widget / Layout / DSL。
- 未进入 Dirty Rect / global tick / frame scheduler。
- 未进入 Text / Input / IME / Accessibility。
- 未进入 semantic tree / Action Router。
- 未进入 command-list hash / pixel diff / baseline / offscreen renderer。
- 未创建 `CJGUI_TRUTH_MANIFEST.md`。

## 11. 残留风险

- `CjguiInternalAppLifecycleState` 只是 marker, 不是 lifecycle state machine。后续不能把它误读成 `run` / `shutdown` / queue / drain 的实现依据。
- 当前 marker 是空 struct。仓颉编译器可能提供默认构造能力; 本项目不把它解释为 public API、public C ABI 或 runtime behavior。
- 当前尚未冻结 lifecycle state shape。不得直接添加字段、状态枚举、transition、queue policy、drain policy 或 platform callback binding。
- 当前仍没有 runtime behavior, 不能把 build success 解读为 GUI runtime 能力。

## 12. 链接 / Diff 检查

本 closure 必须能从:

- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)

找到。

`git diff --check` 结果:

```text
exit_code=0
stdout_key=none
```

## 13. 当前下一步 opening

当前 next opening:

> `P1 first internal app lifecycle state closure / lifecycle state shape decision`

它不自动开启下一步。
