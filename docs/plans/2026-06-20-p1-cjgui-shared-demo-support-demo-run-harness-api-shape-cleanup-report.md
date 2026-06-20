# CJGUI shared demo_support demo run harness API 形态清理报告

本次让 shared demo_support 的 run harness 更像可复用 framework primitive：`CjguiExperimentalDemoRunHarness` 新增 `finishCommittedSessionRun(...)`，直接消费 `CjguiExperimentalDemoComponentActionSession`、`CjguiExperimentalDemoOutput` 与 `CjguiExperimentalDemoCommitResult`，10 个 runnable demo 不再各自维护重复的 demo-local `buildRunResult` 包装。

证据是 aggregate verifier 实际编译并运行 10 个 demo binary，回显 `cjgui_shared_demo_run_demo_count=10`、`cjgui_shared_demo_run_binary_execution=true`、`cjgui_shared_demo_run_readback=true`、`cjgui_shared_demo_run_not_published=true`、`cjgui_shared_demo_run_harness_boilerplate_reduced=true` 与 `cjgui_shared_demo_run_session_api=finishCommittedSessionRun`；10 个 focused demo verifier 也全部通过。`cjpm build --target-dir /tmp/cjgui-shared-demo-run-harness-api-cleanup-target-repro --skip-script` 复跑通过。

下一步最高价值目标：`P1 CJGUI shared demo_support demo run result reporter/output rendering cleanup`。

## 本轮变更

- 在 [runtime_cjgui_experimental_demo_run_harness.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_run_harness.cj) 中新增 `finishCommittedSessionRun(...)`，把 component/action summary 与 UI state summary 的组装下沉到 shared run harness。
- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 这 10 个 demo 全部改为调用 `runHarness.finishCommittedSessionRun(...)`。
- 10 个 demo-local `buildRunResult` wrapper 已删除；aggregate verifier 和 focused verifier 都会拒绝 `func buildRunResult(` 回退。
- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 固定 `finishCommittedSessionRun` 与 `CjguiExperimentalDemoComponentActionSession` 为 run harness session API evidence。

## API 说明

新增 experimental demo_support API：

```cj
public func finishCommittedSessionRun(
    statusBefore: String,
    statusAfter: String,
    output: CjguiExperimentalDemoOutput,
    componentSession: CjguiExperimentalDemoComponentActionSession,
    commitResult: CjguiExperimentalDemoCommitResult,
    commitReadbackOk: Bool
): CjguiExperimentalDemoRunResult
```

稳定性：experimental demo_support API，只服务当前 demo-host shared primitive 收敛；不是稳定 toolkit API，不是 public C ABI，不改变 Renderer canonical tail。

消费路径：当前 10 个 runnable demo 全部真实调用该 API，并由 focused verifier 编译运行 demo binary 校验 before -> after / readback / not-published 输出。

## 验证记录

- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh`：通过，回显 `cjgui_shared_demo_run_harness_boilerplate_reduced=true` 与 `cjgui_shared_demo_run_session_api=finishCommittedSessionRun`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh`：通过，确认 commit harness 仍覆盖 10 个 demo。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh`：通过。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh`：通过。
- 10 个 focused demo verifier：全部通过，均实际编译并运行 demo binary。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-run-harness-api-cleanup-target-repro --skip-script`：复跑通过。第一次主包 build 曾触发一次 transient Cangjie runtime `SIGABRT`，同一环境显式 source toolchain 后复跑成功；未做代码修复性猜测。

## 边界

- 未新增 public C ABI。
- 未修改 production native bridge。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未写 `runtime_state.cj` 或 renderer state。
- 未改变 Renderer canonical endpoint / next opening。
- 本轮只收敛 demo_support API shape，不把 demo run result 解释成 production renderer truth 或 backend-ready truth。

## GitNexus 记录

GitNexus impact：

- `CjguiExperimentalDemoRunHarness`：`UNKNOWN` / target not found / impactedCount `0`。
- `finishCommittedSessionRun`：`UNKNOWN` / target not found / impactedCount `0`。

按 [AGENTS.md](/Users/jiangxuanyang/Desktop/cangjie/AGENTS.md) 规则，这属于图谱未覆盖新鲜 Cangjie/demo_support symbol，不当安全证明也不当 blocker；本轮使用源码阅读、focused demo verifier、`cjpm build` 与扫描兜底。

## 后续入口

`P1 CJGUI shared demo_support demo run result reporter/output rendering cleanup`
