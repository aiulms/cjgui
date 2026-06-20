# CJGUI shared/contract legacy Output API 退役第二切片报告

本次让 CJGUI 的 shared demo output 主路径继续前进：Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 五个 shared/contract demo 的旧 Output API public declaration 已退役。当前 10 个独立 runnable demo 都只通过 `CjguiExperimentalDemoComponentActionSession` / `CjguiExperimentalDemoOutput` 产出 demo output，不再保留并行的 per-demo 或 shared/contract legacy Output public wrapper。

证据是 5 个 legacy API 文件只保留 tombstone 注释与 `package cjgui`，不再声明 `CjguiExperimentalXxxOutput` 或 `cjguiExperimentalBuildXxxOutput(...)`；新增 verifier 实际调用 5 个 shared/contract demo verifier，确认 demo 二进制仍运行，并回显 `legacy_output_api_direct_consumption=false` 与 `shared_component_action_session_imported=true`。

## 本次真实前进

- [runtime_cjgui_experimental_shared_demo_harness_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_demo_harness_api.cj)：退役 `CjguiExperimentalSharedDemoHarnessOutput` / `cjguiExperimentalBuildSharedDemoHarnessOutput(...)`。
- [runtime_cjgui_experimental_shared_multi_demo_harness_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_multi_demo_harness_api.cj)：退役 `CjguiExperimentalSharedMultiDemoHarnessOutput` / `cjguiExperimentalBuildSharedMultiDemoHarnessOutput(...)`。
- [runtime_cjgui_experimental_shared_layout_style_input_focus_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_layout_style_input_focus_contract_api.cj)：退役 `CjguiExperimentalSharedLayoutStyleInputFocusContractOutput` / `cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput(...)`。
- [runtime_cjgui_experimental_ai_generated_ui_shared_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_ai_generated_ui_shared_contract_api.cj)：退役 `CjguiExperimentalAiGeneratedUiSharedContractOutput` / `cjguiExperimentalBuildAiGeneratedUiSharedContractOutput(...)`。
- [runtime_cjgui_experimental_reusable_component_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_reusable_component_contract_api.cj)：退役 `CjguiExperimentalReusableComponentContractOutput` / `cjguiExperimentalBuildReusableComponentContractOutput(...)`。
- 新增 [verify_cjgui_shared_contract_legacy_output_api_retirement.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh)，把 tombstone scan 与 5 个 shared/contract demo binary verifier 串成 focused proof。

## before / after

- Before：第一切片已经退役 Todo、Settings、Chat、FileBrowser 与 AI-generated UI 五个代表 demo-specific Output API，但 shared/contract demo 仍保留 5 组 legacy Output public declarations。
- After：全部 10 组 legacy Output public declarations 已从 package surface 退役为 tombstone；历史链接保留，真实 output path 统一走 `demo_support`。
- Readback：5 个 shared/contract verifier 继续实际编译运行 demo 二进制，回显 owner-local before / after / readback 与 shared session facts。

## 验证

- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh`：通过，回显 `shared_contract_legacy_output_api_retired_count=5`、`shared_contract_demo_shared_output_path_verified=true` 与 `shared_contract_demo_binary_verifier_count=5`。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh`：通过，回归确认第一切片仍回显 `legacy_demo_output_api_retired_count=5` 与 `representative_demo_binary_verifier_count=5`。
- `cjpm build --target-dir /tmp/cjgui-shared-contract-legacy-output-api-retirement-target --skip-script`：通过；构建仍有既有 unused / stack-frame warnings，最终输出 `cjpm build success`。
- `git diff --check`：通过。
- Markdown absolute link check：通过，项目 docs / README 范围检查 `2027` 个 Markdown 文件、`18882` 个项目绝对链接，missing target 数量为 `0`。
- protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行，本轮未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files。
- public declaration scan：本轮删除 10 个 shared/contract experimental public declarations；没有新增 public declaration。
- legacy public declaration scan：`runtime/cjgui/src` 中 10 组 legacy Output API public class / builder 均无匹配。
- GitNexus impact：`CjguiExperimentalSharedDemoHarnessOutput`、`CjguiExperimentalSharedMultiDemoHarnessOutput`、`CjguiExperimentalSharedLayoutStyleInputFocusContractOutput`、`CjguiExperimentalAiGeneratedUiSharedContractOutput` 与 `CjguiExperimentalReusableComponentContractOutput` 均返回 `UNKNOWN / not found`，按图谱未覆盖处理，不作为安全证明。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 affected processes `0` / risk `low`。
- CodeLattice：`codelattice_workflow`、`codelattice_project` 与 `codelattice_change_review` 当前均返回 unsupported call，按工具覆盖缺口记录；本轮以源码、focused verifier、build 与扫描兜底。

## 边界

本轮不新增 public C ABI，不写 `runtime_state.cj` / renderer state，不调用 native bridge，不声明 Renderer backend ready truth。Tombstone 文件只为历史链接稳定存在，不是 runtime truth，也不是新的 compatibility surface。

## 下一步最高价值目标

`P1 CJGUI shared demo_support commit/write/readback primitive expansion first slice`
