# P1 CJGUI shared demo support contract output builder migration 阶段报告

日期：2026-06-17

## 本轮让什么真实前进

本次让两个 contract demo 真实前进：`AI-generated UI shared contract` 与 `Reusable component contract` 不再直接消费各自 demo-specific Output API，改为真实 import `cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace, CjguiExperimentalDemoOutputBuilder}`，并用同一条 shared builder 路径生成 before / after / action / write count / readback output。

证据目标：

- [ai_generated_ui_shared_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj) 调用 `CjguiExperimentalDemoOutputBuilder().buildFromTrace(...)`，并保持 `generate_spec,preview_diff,explain_changes,accept_refresh,move_focus` 的业务 before -> after / readback。
- [reusable_component_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/reusable_component_contract_app.cj) 调用 `CjguiExperimentalDemoOutputBuilder().buildFromTrace(...)`，并保持 `register_file_row,register_ai_form,todo_add,file_select,ai_accept` 的业务 before -> after / readback。
- 两个 focused verifier 均已更新为编译并运行 demo 二进制，校验 `public_api_name=CjguiExperimentalDemoOutputBuilder`、`legacy_output_api_direct_consumption=false` 与 shared support output。

## API 收敛结果

Shared `CjguiExperimentalDemoOutputBuilder` 当前已被 7 个 demo 真实消费：

- Todo。
- Settings。
- Chat。
- FileBrowser。
- AI-generated UI。
- AI-generated UI shared contract。
- Reusable component contract。

仍保留 per-demo output API 的 demo / harness 为 3 个：

- Shared demo harness。
- Shared multi-demo harness。
- Shared layout/style/input/focus contract。

这些旧 API 暂时作为 compatibility artifact 保留。本轮只迁移真实 demo consumption，不删除 compatibility 文件，避免一次性破坏仍在运行的 harness verifier。

## Demo 业务证据

AI-generated UI shared contract 的业务状态仍从：

```text
components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card
```

推进到：

```text
components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button
```

Reusable component contract 的业务状态仍从：

```text
components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input
```

推进到：

```text
components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button
```

## 边界

- 本轮没有新增 public C ABI。
- 本轮没有新增 `Ready(): Bool` public API。
- 本轮没有修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- 本轮没有调用 native bridge，没有 AppKit / Metal / drawable / command buffer / render path。
- Shared builder output 是 demo process-local value facts，不是 renderer truth、runtime state publication 或 backend-ready truth。

## 验证记录

本轮最终验证已完成：

- Focused AI-generated UI shared contract verifier：`runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_shared_contract_app.sh` 通过，回显 `cjgui_ai_generated_ui_shared_contract_app_ran=true`、`ai_generated_ui_shared_contract_public_api_name=CjguiExperimentalDemoOutputBuilder`、`ai_generated_ui_shared_contract_legacy_output_api_direct_consumption=false`、`ai_generated_ui_shared_contract_existing_ai_api_consumed=false`、`ai_generated_ui_shared_contract_existing_shared_contract_api_consumed=false`、`ai_generated_ui_shared_contract_owner_local_write_readback=true`。
- Focused reusable component contract verifier：`runtime/cjgui/native/scripts/verify_cjgui_reusable_component_contract_app.sh` 通过，回显 `cjgui_reusable_component_contract_app_ran=true`、`reusable_component_contract_public_api_name=CjguiExperimentalDemoOutputBuilder`、`reusable_component_contract_legacy_output_api_direct_consumption=false`、`reusable_component_contract_owner_local_write_readback=true`。
- Shared builder regression verifier：`verify_cjgui_todo_demo_app.sh`、`verify_cjgui_settings_demo_app.sh`、`verify_cjgui_chat_demo_app.sh`、`verify_cjgui_file_browser_demo_app.sh`、`verify_cjgui_ai_generated_ui_demo_app.sh` 均通过，并继续回显 `*_public_api_name=CjguiExperimentalDemoOutputBuilder` 与 `*_legacy_output_api_direct_consumption=false`。
- Compatibility regression verifier：`verify_cjgui_shared_demo_harness_app.sh`、`verify_cjgui_shared_multi_demo_harness_app.sh`、`verify_cjgui_shared_layout_style_input_focus_contract_app.sh` 均通过；这 3 个 harness / contract demo 仍保留 per-demo output API，是下一轮收敛目标。
- `cjpm build --target-dir /tmp/cjgui-shared-contract-output-builder-target --skip-script` 通过；仅保留仓库既有 unused / stack-frame warnings。
- `git diff --check` 通过。
- Markdown absolute link check：项目 docs / README 范围内检查 `17240` 个绝对链接，missing target 数量为 `0`。
- Reachability：README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX、CJGUI_DEMO_PROGRESS 与本 report 均能检索到 `CjguiExperimentalDemoOutputBuilder`、`legacy_output_api_direct_consumption=false` 与下一步 `P1 CJGUI shared harness output builder migration first slice`。
- Public declaration scan：本轮 `.cj` diff 没有新增 public declaration，`public_declaration_added_lines=0`。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 未被本轮修改。
- Forbidden scan：两个 contract demo 源码中不再出现旧 direct output API 调用；本轮未新增 `Ready(): Bool` public API、foreign declaration、native bridge call、AppKit / Metal / drawable / command buffer / render path。
- CodeLattice before-edit：针对 `CjguiExperimentalDemoOutputBuilder` 的静态分析完成，结果为 static-only，impact risk `UNKNOWN` / medium；按 focused verifier、build 与源码扫描兜底。
- CodeLattice after-edit：`native_review`、`docs_tests`、`config_examples` 静态检查完成，均为 static-only、未执行目标代码；runtime proof 由 focused verifier、regression verifier 与 `cjpm build` 提供。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 `10 files / 2 symbols / affected processes 0 / risk low`；图谱只识别 README 标题级符号且不覆盖新建未跟踪 report，按源码、verifier、build 与扫描兜底。

## 下一步最高价值目标

`P1 CJGUI shared harness output builder migration first slice`

下一步应迁移剩余 3 个 harness / contract demo：Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract。这样可以继续减少 demo-specific Output API，而不是新增 owner / readiness / envelope 包装。
