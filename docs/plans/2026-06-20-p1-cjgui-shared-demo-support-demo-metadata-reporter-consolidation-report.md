# CJGUI 共享 demo_support demo metadata reporter 收敛报告

日期：2026-06-20

状态：工程检查点 / demo_support 复用 / demo identity evidence cleanup

## 本轮结论

本轮让 CJGUI minimal UI framework 的共享 demo 输出能力继续前进：新增 [runtime_cjgui_experimental_demo_metadata_reporter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_metadata_reporter.cj) / `CjguiExperimentalDemoMetadataReporter`，当前全部 10 个独立 runnable demo 都通过 shared reporter 渲染 `demo=...` identity 行；Settings 额外通过同一个 reporter 渲染 `main_declared` 与 `deterministic_output` 静态 runnable facts。输出语义保持不变，但 demo-local metadata `println` 模板退役。

证据是 aggregate verifier [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 已实际编译并运行 10 个 demo binary，并回显 `cjgui_shared_demo_metadata_reporter=CjguiExperimentalDemoMetadataReporter`、`cjgui_shared_demo_metadata_reporter_demo_count=10`、`cjgui_shared_demo_metadata_output_rendering_shared=true` 与 `cjgui_shared_demo_local_metadata_println_retired=true`。本轮不新增 public C ABI，不写 `runtime_state.cj` / renderer state，不调用 native bridge，不改变 Renderer canonical tail。

## 写入范围

- 新增 shared reporter：`CjguiExperimentalDemoMetadataReporter` 负责统一输出 demo identity 与静态布尔 metadata facts。
- 接入 10 个 demo：Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract。
- 更新 10 个 focused verifier 与 aggregate verifier：验证 reporter 声明、demo import / call path、旧 demo-local metadata `println` 已退役，并继续实际运行 demo binary。
- 同步 README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / demo 进度看板，固定本检查点和后续入口。

## 验证结果

- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh` 通过，且实际运行 10 个 demo binary。
- metadata 回归扫描通过：10 个 demo 源文件不再保留 `println("cjgui ...: demo=...")`、`main_declared` 或 `deterministic_output` 这类 demo-local metadata 输出模板。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh` 通过。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh` 通过。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh` 通过。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-metadata-reporter-target --skip-script` 通过。
- `git diff --check` 通过。
- Markdown absolute link / reachability / 中文标题正文抽查通过。
- experimental public function scan 只看到既有 `cjguiExperimentalQueueSubmitShellReady(): Bool`、`cjguiExperimentalComponentPreviewApiReady(): Bool` 与 `cjguiExperimentalComponentCommitApiReady(): Bool`；本轮未新增 `cjguiExperimental*` public function。
- protected path scan 确认 `runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行。
- forbidden scan 确认本轮未触碰 native bridge、renderer state、runtime_state、public C ABI 或 smoke native files。
- CodeLattice 当前未暴露可调用工具；按 AGENTS.md 记录为工具覆盖缺口，使用源码阅读、focused verifier、aggregate verifier、build 与 scans 兜底。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope staged` 已执行：`Changes: 29 files, 2 symbols`、`Affected processes: 0`、`Risk level: low`；结果作为辅助图谱证据，不替代上述源码 / build / verifier 结论。

## 边界

本轮不是 Renderer runtime truth，也不是新的 public API。`CjguiExperimentalDemoMetadataReporter` 只是 demo_support 内部实验性输出复用工具，用于减少 10 个 demo 的 identity / static fact stdout 模板重复。它不授权 renderer ready、backend ready、state publication、native bridge 扩张、runtime_state 写入或 stable API。

## 设计意图出口自检

- 本轮是否改变主题状态：是。CJGUI minimal UI framework 的 shared demo_support 输出复用从 business snapshot reporter 继续推进到 metadata reporter。
- 本轮是否改变 canonical tail / endpoint：否。Renderer canonical endpoint 仍是 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：不改变 Renderer owner / truth / stop-line；新增 demo_support reporter 只承载 demo stdout metadata 渲染。
- 本轮是否改变唯一 next opening：是。当前 CJGUI next opening 改为 `P1 CJGUI shared demo_support demo evidence presenter consolidation for reporter orchestration cleanup`。
- 是否同步 topic manifest：否。本轮是 CJGUI demo_support 普通工程检查点，按文档预算治理只同步 README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / demo 进度看板，不扩写 Renderer topic manifest。
- 已同步哪些入口：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`docs/plans/DESIGN_INTENT_INDEX.md` 与 `docs/plans/CJGUI_DEMO_PROGRESS.md`。

## 后续入口

`P1 CJGUI shared demo_support demo evidence presenter consolidation for reporter orchestration cleanup`

当前 demo-local raw stdout 模板已基本退役，10 个 demo 仍分别装配 metadata / business / proof / run result reporters。下一步最高价值目标是把多 reporter 编排继续下沉到 shared demo_support，形成更像 framework presenter 的单一 demo evidence 输出入口，而不是继续在每个 demo 中重复 reporter wiring。
