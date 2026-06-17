# P1 CJGUI shared demo support harness output builder migration 阶段报告

日期：2026-06-17

## 本轮让什么真实前进

本次让剩余 3 个 harness / contract demo 真实前进：`Shared demo harness`、`Shared multi-demo harness` 与 `Shared layout/style/input/focus contract` 不再直接消费各自 demo-specific Output API，改为真实 import `cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}`，并用同一条 shared builder 路径生成 before / after / action / write count / readback output。

证据目标：

- [shared_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_demo_harness_app.cj) 调用 `CjguiExperimentalDemoOutputBuilder().buildFromTrace(...)`，并保持 Todo add / complete 的业务 before -> after / readback。
- [shared_multi_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_multi_demo_harness_app.cj) 调用 `CjguiExperimentalDemoOutputBuilder().buildFromTrace(...)`，并保持 Todo add / complete 与 FileBrowser expand / filter / select / focus 两条业务流的 before -> after / readback。
- [shared_layout_style_input_focus_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_layout_style_input_focus_contract_app.cj) 调用 `CjguiExperimentalDemoOutputBuilder().buildFromTrace(...)`，并保持 layout / style / input / focus 四类 owner-local 状态写入读回。
- 三个 focused verifier 均已更新为编译并运行 demo 二进制，先红灯确认旧 demo 缺少 shared support import，再绿灯校验 `public_api_name=CjguiExperimentalDemoOutputBuilder`、`legacy_output_api_direct_consumption=false` 与 shared support output。

## API 收敛结果

Shared `CjguiExperimentalDemoOutputBuilder` 当前已被 10 个 demo 真实消费：

- Todo。
- Settings。
- Chat。
- FileBrowser。
- AI-generated UI。
- Shared demo harness。
- Shared multi-demo harness。
- Shared layout/style/input/focus contract。
- AI-generated UI shared contract。
- Reusable component contract。

旧 per-demo output API 文件暂时作为 compatibility artifact 保留，但当前 `runtime/cjgui/demo/*_app.cj` 不再直接消费它们。本轮不删除 compatibility 文件，避免把 API cleanup 与 demo consumption migration 混在同一个检查点里。

## Demo 业务证据

Shared demo harness 的业务状态仍从：

```text
items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list
```

推进到：

```text
items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent
```

Shared multi-demo harness 的业务状态仍从：

```text
todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list
```

推进到：

```text
todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent
```

Shared layout/style/input/focus contract 的业务状态仍从：

```text
layout=single_column;style=neutral_list;input=<empty>;focus=todo_input
```

推进到：

```text
layout=split_detail;style=focus_accent;input=main;focus=file_filter
```

## 边界

- 本轮没有新增 public C ABI。
- 本轮没有新增 `Ready(): Bool` public API。
- 本轮没有修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- 本轮没有调用 native bridge，没有 AppKit / Metal / drawable / command buffer / render path。
- Shared builder output 是 demo process-local value facts，不是 renderer truth、runtime state publication 或 backend-ready truth。
- 旧 per-demo output API 文件只保留为 compatibility artifact，不再作为当前 demo app 的直接消费路径。

## 验证记录

本轮最终验证已完成：

- 红灯验证：三个 focused verifier 在 demo 迁移前均失败于 missing shared support import，证明 verifier 能抓住旧 per-demo Output API 消费路径。
- Focused shared demo harness verifier：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_harness_app.sh` 通过，回显 `cjgui_shared_demo_harness_app_ran=true`、`shared_demo_harness_public_api_name=CjguiExperimentalDemoOutputBuilder`、`shared_demo_harness_legacy_output_api_direct_consumption=false`、`shared_demo_harness_shared_support_imported=true` 与 `shared_demo_harness_owner_local_write_readback=true`。
- Focused shared multi-demo harness verifier：`runtime/cjgui/native/scripts/verify_cjgui_shared_multi_demo_harness_app.sh` 通过，回显 `cjgui_shared_multi_demo_harness_app_ran=true`、`shared_multi_demo_harness_public_api_name=CjguiExperimentalDemoOutputBuilder`、`shared_multi_demo_harness_legacy_output_api_direct_consumption=false`、`shared_multi_demo_harness_shared_support_imported=true` 与 `shared_multi_demo_harness_owner_local_write_readback=true`。
- Focused shared layout/style/input/focus contract verifier：`runtime/cjgui/native/scripts/verify_cjgui_shared_layout_style_input_focus_contract_app.sh` 通过，回显 `cjgui_shared_layout_style_input_focus_contract_app_ran=true`、`shared_layout_style_input_focus_contract_public_api_name=CjguiExperimentalDemoOutputBuilder`、`shared_layout_style_input_focus_contract_legacy_output_api_direct_consumption=false`、`shared_layout_style_input_focus_contract_shared_support_imported=true` 与 `shared_layout_style_input_focus_contract_owner_local_write_readback=true`。
- Shared builder regression verifier：`verify_cjgui_todo_demo_app.sh`、`verify_cjgui_settings_demo_app.sh`、`verify_cjgui_chat_demo_app.sh`、`verify_cjgui_file_browser_demo_app.sh`、`verify_cjgui_ai_generated_ui_demo_app.sh`、`verify_cjgui_ai_generated_ui_shared_contract_app.sh`、`verify_cjgui_reusable_component_contract_app.sh` 均通过，并继续回显 `*_public_api_name=CjguiExperimentalDemoOutputBuilder` 与 `*_legacy_output_api_direct_consumption=false`。
- `cjpm build --target-dir /tmp/cjgui-shared-harness-output-builder-target --skip-script` 通过；由于沙箱中 `envsetup.sh` 的 shell 探测不能直接调用 `ps`，最终使用 focused verifier 同款 `ps` shim 重新 source toolchain。构建仅保留仓库既有 unused / stack-frame warnings。
- `git diff --check` 通过。
- Markdown absolute link check 通过：项目 docs / README 范围内检查 2019 个 Markdown / README 文件、18838 个 absolute link，missing 为 0。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / demo progress reachability 通过：7 个同步入口均可检索到 `CjguiExperimentalDemoOutputBuilder`、`legacy_output_api_direct_consumption=false` 与下一步 `P1 CJGUI shared demo state/action primitives consolidation first slice`。
- 中文标题与正文抽查通过：本轮新增报告标题与正文均包含中文维护内容。
- public declaration scan 通过：本轮 `.cj` diff 没有新增 `public func/class/struct/enum/let/var`。
- protected path scan 通过：`runtime/cjgui/src/runtime_state.cj` 仍为 10065 行，且 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 macOS smoke native 路径无 diff。
- 当前 demo app 旧 per-demo output API 直接消费扫描通过：`runtime/cjgui/demo` 中不再命中 10 条旧 output builder / output type 符号。
- Demo source forbidden scan 通过：三个迁移 demo source 未命中 `foreign func`、native bridge、renderer/runtime state、AppKit / Metal / drawable / command buffer / present / commit / draw / encoder 相关路径；verifier script 中保留的命中仅为 stop-line / guard / echo 文本。
- CodeLattice after-edit 静态复核返回 LOW，但同时标记 static-only / stale baseline / file_added；本轮不把图结果作为安全证明，只作为辅助低风险信号。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged` 返回 low / affected processes 0，并仅识别 README 相关 2 个符号；新增报告与 fresh demo owner 未完全索引，按图覆盖缺口记录，最终以源码、focused verifier、build 与扫描兜底。

## 下一步最高价值目标

`P1 CJGUI shared demo state/action primitives consolidation first slice`

现在 output API 收敛已经覆盖当前 10 个 demo，下一步不应继续包装 output。更高价值的方向是把 Todo / Settings / Chat / FileBrowser / AI-generated UI 中重复的 demo-local state/action primitives 往 `demo_support` 收敛，至少让两个 demo 真实复用同一组 action / state transition helper，并继续由 verifier 执行业务 before -> after / readback。
