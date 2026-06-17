# P1 CJGUI shared component/action session 覆盖完成报告

日期：2026-06-17

## 本次让什么真实前进

本次把 Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 迁入 shared `CjguiExperimentalDemoComponentActionSession`。

迁移后，当前 10 个独立 runnable demo 都通过同一组 shared demo_support primitive 记录 component/action route、维护 shared layout / style / text input / focus state、构建 `CjguiExperimentalDemoOutput`，不再由每个 demo 在 `main` 中直接拼 `CjguiExperimentalDemoInteractionTrace` + `CjguiExperimentalDemoOutputBuilder`。这让 CJGUI 的 demo 主路径更接近 minimal UI framework：业务方法负责 owner-local 写入并记录组件动作，shared session 负责可检查 output/readback。

## 代码证据

- [shared_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_demo_harness_app.cj)：`SharedDemoHarnessState` 持有 `CjguiExperimentalDemoComponentActionSession`，记录 `todo_input:shared_demo_harness.add_todo,todo_item:shared_demo_harness.complete_todo`。
- [shared_multi_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_multi_demo_harness_app.cj)：同一 session 覆盖 Todo add / complete 与 FileBrowser expand / filter / select / focus route。
- [shared_layout_style_input_focus_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_layout_style_input_focus_contract_app.cj)：layout、style、text input、focus 四类合同都通过 session 记录 component/action route。
- [ai_generated_ui_shared_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj)：AI-generated UI shared contract 通过 session 记录 generate / diff / explain / accept / focus route。
- [reusable_component_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/reusable_component_contract_app.cj)：Todo、FileBrowser 与 AI-generated UI 复用合同通过 session 记录 register / select / accept route。
- [runtime_cjgui_experimental_demo_component_action_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj)：继续作为 shared demo_support API 组合 component action route、`CjguiExperimentalDemoUiStateCore`、`CjguiExperimentalDemoInteractionTrace` 与 `CjguiExperimentalDemoOutputBuilder`。

## 验证结果

- 全量 10 个 focused verifier 已复跑通过，并且都实际编译、运行 demo 二进制，校验 before -> after / readback output：`verify_cjgui_todo_demo_app.sh`、`verify_cjgui_settings_demo_app.sh`、`verify_cjgui_chat_demo_app.sh`、`verify_cjgui_file_browser_demo_app.sh`、`verify_cjgui_ai_generated_ui_demo_app.sh`、`verify_cjgui_shared_demo_harness_app.sh`、`verify_cjgui_shared_multi_demo_harness_app.sh`、`verify_cjgui_shared_layout_style_input_focus_contract_app.sh`、`verify_cjgui_ai_generated_ui_shared_contract_app.sh`、`verify_cjgui_reusable_component_contract_app.sh`。
- 10 个 verifier 均回显 `*_public_api_name=CjguiExperimentalDemoComponentActionSession`、`*_public_api_return=CjguiExperimentalDemoOutput`、`*_legacy_output_api_direct_consumption=false` 与 `*_shared_component_action_session_imported=true`。
- 10 个 verifier 均回显 `*_owner_local_write_readback=true`，并保持 `*_runtime_state_write=false`、`*_renderer_state_write=false`、`*_public_c_abi_added=false`。
- `cjpm build --target-dir /tmp/cjgui-shared-component-action-session-coverage-target --skip-script` 已通过；构建输出仍包含既有 unused / stack-frame warnings，但没有本检查点引入的构建失败。
- `git diff --check` 已通过；Markdown absolute link check 扫描项目 docs / README 范围内 2025 个 Markdown 文件，missing project absolute links 为 `0`；README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / demo progress reachability 均可检索到本检查点。
- public declaration diff scan 无新增 public declaration；protected path scan 显示 `runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行，且 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 无 diff。
- native / renderer forbidden diff scan 对变更 demo 与 verifier 未发现 `runtime_state` / `renderer_state` 写入、native bridge、FFI、AppKit / Metal、command buffer、draw / present / renderer submission 等越线 pattern。
- CodeLattice consistency review 对新 shared demo_support 符号返回 stale baseline / unknown symbols，并把 README mention 标为 stale doc candidate；按 AGENTS 规则记录为 graph gap，不当安全证明，也不当 blocker。本检查点用源码读回、10 个 focused verifier、`cjpm build` 与安全扫描兜底。
- GitNexus `detect_changes(repo=cangjie-live-codelattice, scope=unstaged)` 返回 `changed_files=16`、`affected_count=0`、`risk_level=low`；图谱只识别 README section touch，未覆盖全部新 demo/support 符号，按源码与 focused verification 兜底。

## 边界

- 没有新增 public C ABI。
- 没有新增 native bridge 调用。
- 没有写 `runtime_state.cj` / renderer state。
- 没有修改 `runtime/cjgui/cjpm.toml`。
- 没有把 demo output 解释成 renderer-ready truth。
- `CjguiExperimentalDemoComponentActionSession` 仍是 experimental demo support public class，只保存 demo process-local in-memory facts。

## 下一步最高价值目标

`P1 CJGUI legacy demo-specific Output API retirement preflight for shared DemoOutput path`

当前 10 个 runnable demo 已经统一走 shared component/action session。下一步应盘点旧 `CjguiExperimentalXxxDemoOutput` / `cjguiExperimentalBuildXxxDemoOutput` compatibility artifact，确认哪些已经不再被 demo 消费，逐步退役 demo-specific Output API，避免 CJGUI 回到每个 demo 一套 output wrapper。
