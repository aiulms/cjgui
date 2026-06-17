# P1 CJGUI shared demo UI state core 扩展阶段报告

日期：2026-06-17

## 本轮让什么真实前进

本轮把 [runtime_cjgui_experimental_demo_ui_state_core.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj) / `CjguiExperimentalDemoUiStateCore` 从 Settings、Chat、FileBrowser 三个代表 demo 扩展到 AI-generated UI 与 reusable contract 路线：

- [ai_generated_ui_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_app.cj) 用 shared core 管理 AI preview 的 layout、style 与 focus。
- [ai_generated_ui_shared_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj) 用 shared core 承载 shared layout / style / input / focus contract。
- [reusable_component_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/reusable_component_contract_app.cj) 用 shared core 承载 Todo、FileBrowser、AI-generated UI 复用组件合同里的 layout / style / input / focus。

这让 `CjguiExperimentalDemoUiStateCore` 的真实消费从 3 个 demo 增加到 6 个 demo，并继续减少 demo-local 重复状态字段。它不是新的 owner/readiness wrapper，也不是只在报告里出现的名字；三个目标 demo 的 focused verifier 都实际编译并运行 demo 二进制，校验 before -> after / readback 与 shared state core 输出。

## API / 状态收敛结果

新增真实消费结果：

- AI-generated UI：`layout=ai_form_preview;style=sage_panel;input=<empty>;focus=save_button`
- AI-generated UI shared contract：`layout=split_detail;style=sage_panel;input=username;focus=save_button`
- Reusable component contract：`layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button`

当前 shared UI state core 覆盖 demo：

- Settings
- Chat
- FileBrowser
- AI-generated UI
- AI-generated UI shared contract
- Reusable component contract

## 验证记录

- 红灯验证：更新后的 AI-generated UI、AI-generated UI shared contract、Reusable component contract focused verifier 在 implementation 前均失败于 missing `CjguiExperimentalDemoUiStateCore` source line，证明 verifier 能捕捉 shared primitive 缺口。
- Focused AI-generated UI verifier：`runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh` 通过，回显 `ai_generated_ui_shared_state_core_imported=true` 与 `ai_generated_ui_shared_state_core_name=CjguiExperimentalDemoUiStateCore`。
- Focused AI-generated UI shared contract verifier：`runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_shared_contract_app.sh` 通过，回显 `ai_generated_ui_shared_contract_shared_state_core_imported=true` 与 `ai_generated_ui_shared_contract_shared_state_core_name=CjguiExperimentalDemoUiStateCore`。
- Focused Reusable component contract verifier：`runtime/cjgui/native/scripts/verify_cjgui_reusable_component_contract_app.sh` 通过，回显 `reusable_component_contract_shared_state_core_imported=true` 与 `reusable_component_contract_shared_state_core_name=CjguiExperimentalDemoUiStateCore`。
- 10 个 demo focused verifier 全部通过：Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract、Reusable component contract。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-ui-state-core-expansion-target --skip-script` 通过；仅保留既有 unused variable / stack frame warning。
- `git diff --check` 通过；Markdown absolute link check 范围限定 `docs/`、`README.md`、`GUI_TASK_TRACKER.md` 与 `runtime/cjgui/README.md`，结果 `markdown_missing_links=0`。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / demo progress reachability 均能指向本报告或新的 shared state core 证据。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 均无 diff。
- Public declaration scan：本轮没有新增 `public func / class / struct / enum / let / var`；只扩展既有 experimental demo support API 的消费面。
- Forbidden scan：changed demo code 未出现 native bridge 调用、AppKit / Metal / drawable / command buffer / render path；脚本中的命中仅为 verifier guard pattern 或中文 stop-line 注释 / false 回显。
- CodeLattice after-edit：`native_review` 静态结果为 LOW，但提示 baseline stale 与部分 hunk 未索引；已按图谱覆盖缺口处理，并由源码、focused verifier、build 与扫描兜底。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：`Risk level: low`，`Affected processes: 0`。

## 边界

- 本轮只扩展 experimental Cangjie demo support API 的消费面，没有新增 public C ABI。
- 本轮没有新增 `Ready(): Bool`。
- 本轮没有修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- 本轮没有调用 native bridge，没有 AppKit / Metal / drawable / command buffer / render path。
- Shared UI state core 仍只保存 demo process-local owner-local value facts；它不是 renderer truth、runtime state publication、backend-ready truth 或 stable toolkit API。

## 下一步最高价值目标

`P1 CJGUI shared demo UI state core coverage completion for Todo and shared harnesses first slice`

下一步应继续把 Todo、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract 中剩余的 layout/style/input/focus 或同构 UI 状态迁入 `CjguiExperimentalDemoUiStateCore`，让 shared primitive 覆盖更多 runnable demo，而不是新增 owner / readiness / wrapper。
