# CJGUI shared demo_support demo run result reporter 输出渲染清理报告

本次继续把 demo app 从各自拼 stdout proof 的形态收敛到 shared demo_support primitive：新增 `CjguiExperimentalDemoRunResultReporter`，由它统一渲染 `CjguiExperimentalDemoRunResult` 的四行 shared run evidence。当前 10 个 runnable demo 仍各自保留业务 before / after / action / commit 输出，但 `shared_run_harness`、`shared_run_result`、`shared_run_readback` 与 `shared_run_not_published` 的输出模板不再散落在 demo-local `println` 中。

证据要求是 aggregate verifier 实际编译并运行 10 个 demo binary，确认 10 个 demo 都 import `CjguiExperimentalDemoRunResultReporter` 并调用 `runReporter.printRunResult(runResult)`，同时拒绝 demo-local `println("cjgui ... shared_run_...")` 回退。该切片只收敛 demo-host stdout proof renderer，不写 `runtime_state.cj` / renderer state，不调用 native bridge，不新增 public C ABI，也不改变 Renderer canonical tail。

下一步最高价值目标：`P1 CJGUI shared demo_support demo proof reporter consolidation for commit/public API evidence cleanup`。

## 本轮变更

- 新增 [runtime_cjgui_experimental_demo_run_result_reporter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_run_result_reporter.cj)，提供 `CjguiExperimentalDemoRunResultReporter.printRunResult(...)`。
- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 这 10 个 demo 全部改为通过 shared reporter 渲染 run result proof。
- 10 个 focused demo verifier 会把 reporter source 复制进临时 package，确保 demo binary 真实编译运行 shared reporter 调用路径。
- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 固定 reporter source、10 个 demo consumer、禁止 demo-local shared run `println` 回退，并回显 reporter coverage facts。

## API 说明

新增 experimental demo_support API：

```cj
public class CjguiExperimentalDemoRunResultReporter {
    public init(outputPrefix: String)
    public func printRunResult(runResult: CjguiExperimentalDemoRunResult)
}
```

稳定性：experimental demo_support API，只服务当前 demo-host shared primitive 收敛；不是稳定 toolkit API，不是 public C ABI，不改变 Renderer canonical tail。

消费路径：当前 10 个 runnable demo 全部真实调用该 API，并由 focused verifier 编译运行 demo binary 校验 before -> after / readback / not-published 输出。

## 验证记录

- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh`：通过，回显 `cjgui_shared_demo_run_result_reporter=CjguiExperimentalDemoRunResultReporter`、`cjgui_shared_demo_run_result_reporter_demo_count=10`、`cjgui_shared_demo_run_result_output_rendering_shared=true` 与 `cjgui_shared_demo_run_local_shared_run_println_retired=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh`：通过，确认 commit harness 仍覆盖 10 个 demo。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh`：通过。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh`：通过。
- 10 个 focused demo verifier：全部通过，均实际编译并运行 demo binary。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-run-result-reporter-target --skip-script`：通过；保留仓库既有 unused / stack-frame warnings，未出现本次 reporter 相关错误。
- `git diff --check`、Markdown absolute link check、reachability、protected path / forbidden diff scan：通过；`runtime_state.cj` 仍为 `10065` 行，未修改 `runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files。

## 边界

- 未新增 public C ABI。
- 未修改 production native bridge。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未写 `runtime_state.cj` 或 renderer state。
- 未改变 Renderer canonical endpoint / next opening。
- 本轮只收敛 demo run result stdout renderer，不把 demo run result 解释成 production renderer truth、runtime state publication 或 backend-ready truth。

## 工具覆盖说明

CodeLattice 当前未提供可调用工具；GitNexus impact `CjguiExperimentalDemoRunResultReporter` 返回 `UNKNOWN` / target not found / impactedCount `0`，detect-changes 返回 low / affected processes `0`。按 [AGENTS.md](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md) 规则，这属于图谱覆盖缺口，不当安全证明也不当 blocker；本轮以源码阅读、focused demo verifier、`cjpm build` 与扫描兜底。

## 后续入口

`P1 CJGUI shared demo_support demo proof reporter consolidation for commit/public API evidence cleanup`
