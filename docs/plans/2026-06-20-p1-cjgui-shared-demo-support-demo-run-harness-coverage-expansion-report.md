# CJGUI shared demo_support demo run harness 覆盖扩展报告

本轮把 `CjguiExperimentalDemoRunHarness` 从三个代表 demo 扩展到当前全部 10 个独立 runnable demo：Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract。每个 demo binary 现在都通过 shared run harness 汇总 runnable / readback / commit-readback / not-published facts，而不是继续只在少数代表 demo 上证明运行结果。

## 本轮变更

- 已把剩余 demo / verifier 补齐到 shared run harness 覆盖面；aggregate verifier 现在固定 `cjgui_shared_demo_run_demo_count=10`。
- 三个此前仍停留在 commit/readback verifier 形态的 contract verifier 现在也检查 `CjguiExperimentalDemoRunHarness` / `CjguiExperimentalDemoRunResult` import、binary 输出、readback 与 not-published facts。
- 保持 `CjguiExperimentalDemoCommitHarness` 为 commit/readback/result 校验主路径；run harness 只负责 demo-host runnable 汇总，不替代 commit primitive。

## 验证证据

- RED：扩展前 `verify_cjgui_shared_demo_run_harness.sh` 在 shared layout/style/input/focus contract 上失败，提示缺少 `CjguiExperimentalDemoCommitHarness` import 形态，说明 aggregate verifier 已开始要求 10-demo run harness coverage。
- GREEN：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh` 通过，回显 `cjgui_shared_demo_run_demo_count=10`、`cjgui_shared_demo_run_binary_execution=true`、`cjgui_shared_demo_run_readback=true`、`cjgui_shared_demo_run_not_published=true`。
- 回归：`verify_cjgui_shared_demo_commit_write_readback.sh`、`verify_cjgui_legacy_demo_output_api_retirement.sh`、`verify_cjgui_shared_contract_legacy_output_api_retirement.sh` 均通过。
- 构建：`cjpm build --target-dir /tmp/cjgui-shared-demo-run-harness-coverage-target --skip-script` 通过。

## 边界

本轮不新增 public C ABI，不修改 production native bridge，不写 `runtime_state.cj` / renderer state，不修改 `runtime/cjgui/cjpm.toml`，不改变 Renderer canonical tail。Run harness coverage 只证明 demo binary 能共用 shared demo_support 汇总运行证据，不授予 renderer backend-ready、state publication 或 public API 稳定性。

## 后续入口

下一步建议转向 `P1 CJGUI shared demo_support demo run harness boilerplate reduction and API shape cleanup`：减少每个 demo 里重复的 `buildRunResult` 模板，把 run harness 进一步从“覆盖完整”推进到“使用形态更像 framework primitive”。
