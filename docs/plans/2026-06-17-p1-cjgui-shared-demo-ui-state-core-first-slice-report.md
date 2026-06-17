# P1 CJGUI shared demo UI state core first slice 阶段报告

日期：2026-06-17

## 本轮让什么真实前进

本次把 `layout / style / text input / focus` 从三个代表性 demo 的 demo-local 字段里抽出第一条 shared primitive：

- 新增 [runtime_cjgui_experimental_demo_ui_state_core.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj)，提供 `CjguiExperimentalDemoUiStateCore`。
- [settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj) 用 shared core 管理 layout、theme style、username input 与 focus。
- [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj) 用 shared core 管理 chat layout、composer input、message focus 与 reply style。
- [file_browser_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/file_browser_app.cj) 用 shared core 管理 tree/detail layout、filter input、pane focus 与 selection/detail style。

这不是新的 readiness wrapper，也不是只输出 report 的名字；三个 demo 的业务 before -> after / readback 仍由 focused verifier 编译并运行二进制证明。

## API / 状态收敛结果

`CjguiExperimentalDemoUiStateCore` 当前承载：

- `applyLayout(mode: String)`
- `applyStyle(token: String)`
- `typeInput(text: String)`
- `moveFocus(target: String)`
- `layout() / style() / textInput() / focus() / summary()`

当前真实消费 demo：

- Settings：`layout=sectioned_form;style=theme_dark;input=owner-updated;focus=theme_select`
- Chat：`layout=threaded_chat;style=assistant_reply;input=;focus=message_list`
- FileBrowser：`layout=tree_detail_split;style=detail_ready;input=main;focus=detail_pane`

## 验证记录

- 红灯验证：更新后的 Settings、Chat、FileBrowser focused verifier 在 implementation 前均失败于 missing shared UI state core source，证明 verifier 能捕捉 shared primitive 缺口。
- Focused Settings verifier：`runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh` 通过，回显 `settings_shared_state_core_imported=true` 与 `settings_shared_state_core_name=CjguiExperimentalDemoUiStateCore`。
- Focused Chat verifier：`runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh` 通过，回显 `chat_shared_state_core_imported=true` 与 `chat_shared_state_core_name=CjguiExperimentalDemoUiStateCore`。
- Focused FileBrowser verifier：`runtime/cjgui/native/scripts/verify_cjgui_file_browser_demo_app.sh` 通过，回显 `file_browser_shared_state_core_imported=true` 与 `file_browser_shared_state_core_name=CjguiExperimentalDemoUiStateCore`。
- 10 个 demo focused verifier 全部通过：Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract、Reusable component contract。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-ui-state-core-target --skip-script` 通过；仅保留既有 unused variable / stack frame warning。
- `git diff --check` 通过；Markdown absolute link check 范围限定 `docs/`、`README.md`、`GUI_TASK_TRACKER.md` 与 `runtime/cjgui/README.md`，结果 `markdown_missing_links=0`。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / demo progress reachability 均能指向本报告或 `CjguiExperimentalDemoUiStateCore`。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 均无 diff。
- Public declaration scan：新增 public 声明仅限 [runtime_cjgui_experimental_demo_ui_state_core.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj) 的 experimental demo support Cangjie API；未新增 public C ABI，未新增 `Ready(): Bool`。
- Forbidden scan：changed demo/support code 未出现 native bridge 调用、AppKit / Metal / drawable / command buffer / render path；脚本中的命中仅为 verifier guard pattern 或中文 stop-line 注释。
- CodeLattice after-edit：`native_review` 静态结果为 LOW，但提示新文件导致 stale baseline / 部分 hunk 未索引；已按图谱覆盖缺口处理，并由源码、focused verifier、build 与扫描兜底。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：`Risk level: low`，`Affected processes: 0`。

## 边界

- 本轮新增的是 experimental Cangjie demo support API，不是 public C ABI。
- 本轮没有新增 `Ready(): Bool`。
- 本轮没有修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- 本轮没有调用 native bridge，没有 AppKit / Metal / drawable / command buffer / render path。
- Shared UI state core 只保存 demo process-local owner-local value facts；它不是 renderer truth、runtime state publication、backend-ready truth 或 stable toolkit API。

## 下一步最高价值目标

`P1 CJGUI shared demo UI state core expansion to AI-generated UI and reusable contracts first slice`

下一步应把 AI-generated UI、AI-generated UI shared contract、Reusable component contract 中仍手写的 layout/style/input/focus 字段迁到同一个 `CjguiExperimentalDemoUiStateCore`，继续减少 demo-local 状态模型，而不是新增 owner / readiness / wrapper。
