# CJGUI shared demo_support demo proof reporter 收敛报告

本次让 CJGUI minimal UI framework 的 demo proof 输出再向 shared framework primitive 收敛：新增 `CjguiExperimentalDemoProofReporter`，统一渲染当前 10 个 runnable demo 的 public API、component action、shared UI state 与 commit/readback/not-published proof。以前这些 proof 行散落在每个 demo 的 `println` 模板里；现在它们由 shared demo_support API 承载，demo 只负责业务 before / after / readback 与调用 shared reporter。

证据是 aggregate verifier 实际编译并运行 10 个 demo binary，确认每个 demo 都 import / 调用 `CjguiExperimentalDemoProofReporter.printSharedPrimitiveProof(...)`，并拒绝 demo-local `public_api_*`、`shared_support_*`、`shared_component_action_*`、`shared_commit_*` proof `println` 回退。该切片不写 `runtime_state.cj` / renderer state，不调用 native bridge，不修改 `cjpm.toml`，不新增 public C ABI，也不改变 Renderer canonical tail。

下一步最高价值目标：`P1 CJGUI shared demo_support business snapshot reporter consolidation for demo metadata/state evidence cleanup`。

## 本轮变更

- 新增 [runtime_cjgui_experimental_demo_proof_reporter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_proof_reporter.cj)，提供 `CjguiExperimentalDemoProofReporter.printSharedPrimitiveProof(...)`。
- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 这 10 个 demo 全部改为通过 shared proof reporter 渲染 public/component/state/commit stdout proof。
- 10 个 focused demo verifier 会把 proof reporter source 复制进临时 package，确保 demo binary 真实编译运行 shared reporter 调用路径。
- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 固定 proof reporter source、10 个 demo consumer、禁止 demo-local shared proof `println` 回退，并回显 proof reporter coverage facts。

## API 说明

新增 experimental demo_support API：

```cj
public class CjguiExperimentalDemoProofReporter {
    public init(outputPrefix: String)
    public func printSharedPrimitiveProof(
        output: CjguiExperimentalDemoOutput,
        componentSession: CjguiExperimentalDemoComponentActionSession,
        commitResult: CjguiExperimentalDemoCommitResult,
        commitHarness: CjguiExperimentalDemoCommitHarness
    )
}
```

稳定性：experimental demo_support API，只服务当前 demo-host shared primitive 收敛；不是稳定 toolkit API，不是 public C ABI，不改变 Renderer canonical tail。

消费路径：当前 10 个 runnable demo 全部真实调用该 API，并由 focused / aggregate verifier 编译运行 demo binary 校验 before -> after / readback / not-published 输出。

## 验证记录

- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh`：通过，回显 `cjgui_shared_demo_proof_reporter=CjguiExperimentalDemoProofReporter`、`cjgui_shared_demo_proof_reporter_demo_count=10`、`cjgui_shared_demo_public_component_commit_output_rendering_shared=true` 与 `cjgui_shared_demo_local_shared_proof_println_retired=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh`：通过，确认 commit harness 仍覆盖 10 个 demo。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh`：通过。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh`：通过。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-proof-reporter-target --skip-script`：通过；保留仓库既有 stack-frame warnings，未出现本次 proof reporter 相关错误。
- GitNexus impact `CjguiExperimentalDemoProofReporter` / `printSharedPrimitiveProof`：`UNKNOWN` / target not found / impactedCount `0`，按 AGENTS 记录为图谱覆盖缺口，不当安全证明也不当 blocker。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 `Changes: 30 files, 2 symbols`、affected processes `0`、risk `low`；图谱只识别 README 标题级符号，仍以源码 / verifier / build / scans 兜底。
- `git diff --check`、Markdown absolute link check、reachability、public / protected / forbidden scans：通过；public declaration scan 仅新增 experimental demo_support `public class CjguiExperimentalDemoProofReporter` 与 `public func printSharedPrimitiveProof(...)`，未新增 `foreign func` 或 public C ABI；`runtime_state.cj` 仍为 `10065` 行，未修改 `runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files。

## 边界

- 未新增 public C ABI。
- 未修改 production native bridge。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未写 `runtime_state.cj` 或 renderer state。
- 未改变 Renderer canonical endpoint / next opening。
- 本轮只收敛 demo-host public/component/state/commit proof renderer，不把 demo proof 解释成 production renderer truth、runtime state publication 或 backend-ready truth。

## 后续入口

`P1 CJGUI shared demo_support business snapshot reporter consolidation for demo metadata/state evidence cleanup`
