# CJGUI shared demo_support demo run harness first slice 报告

本次让 CJGUI minimal UI framework 的 shared demo_support 真实前进：新增 `CjguiExperimentalDemoRunHarness` / `CjguiExperimentalDemoRunResult`，并让 Chat、FileBrowser、AI-generated UI 三个代表 demo 在 demo binary 内部消费同一组 shared run/result primitive，汇总 before -> after、shared output readback、commit readback、rollback/not-published 边界。

证据是 TDD RED/GREEN：先新增 `verify_cjgui_shared_demo_run_harness.sh`，它要求 run harness source 与三个代表 demo 的 `*_shared_run_*` evidence，初次运行失败于缺少 `runtime_cjgui_experimental_demo_run_harness.cj`。随后新增 shared run harness source，更新三个 demo 与 focused verifier；新 aggregate verifier 实际编译并运行三个 demo binary，回显 `cjgui_shared_demo_run_demo_count=3`、`cjgui_shared_demo_run_binary_execution=true`、`cjgui_shared_demo_run_readback=true` 与 `cjgui_shared_demo_run_not_published=true`。

## 本次真实前进

- 新增 [runtime_cjgui_experimental_demo_run_harness.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_run_harness.cj)，把 demo run 的 status、before/after、action trace、component action summary、UI state summary、domain summary、commit summary、readback 与 not-published facts 脱水为 `CjguiExperimentalDemoRunResult`。
- [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj)、[file_browser_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/file_browser_app.cj) 与 [ai_generated_ui_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_app.cj) 现在都持有 `CjguiExperimentalDemoRunHarness`，并把最终 `readbackOk` 绑定到 `runResult.runnable`。
- 新增 [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)，作为 aggregate run harness verifier，覆盖 Chat / FileBrowser / AI-generated UI 三个 demo binary 的真实执行证据。

## before / after

- Before：shared demo_support 已有 component/action/output 与 commit/readback harness，但 demo run 的 final runnable/readback/not-published 事实仍由每个 demo 和 shell verifier 分散表达。
- After：三个代表 demo 通过同一个 `CjguiExperimentalDemoRunHarness.finishRun(...)` 汇总 shared output + commit result，focused verifier 回显 `chat_shared_run_harness_imported=true`、`file_browser_shared_run_harness_imported=true` 与 `ai_generated_ui_shared_run_harness_imported=true`。
- Readback：三个 demo 的 run result 均要求 `readback=true`、`commit_readback=true`、`not_published=true`，并继续保持 owner-local / demo-host 范围，不发布 runtime_state / renderer_state。

## 验证结果

- TDD RED：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh` 初次运行失败于缺少 `runtime_cjgui_experimental_demo_run_harness.cj`。
- 新 aggregate GREEN：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh` 通过，实际编译并运行 Chat、FileBrowser、AI-generated UI 三个 demo binary。
- 回归 GREEN：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh` 通过，继续覆盖 10 个 runnable demo；`verify_cjgui_legacy_demo_output_api_retirement.sh` 与 `verify_cjgui_shared_contract_legacy_output_api_retirement.sh` 通过。
- Build GREEN：`cjpm build --target-dir /tmp/cjgui-shared-demo-run-harness-target --skip-script` 退出码为 `0`；仅保留既有 large stack frame warning。
- 文档与边界扫描 GREEN：`git diff --check` 通过；Markdown absolute link check 覆盖 5010 个 Markdown 文件、19027 个项目绝对链接，missing target 为 `0`；README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / CJGUI_DEMO_PROGRESS 均能检索到本轮 run harness 接续。
- Protected / public scan GREEN：`runtime/cjgui/src/runtime_state.cj` 仍为 10065 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 无 diff；public C ABI 无 diff。
- Public experimental API scan：本轮只新增 `public class CjguiExperimentalDemoRunResult` 与 `public class CjguiExperimentalDemoRunHarness` 两个 Cangjie experimental demo_support value API；稳定级别仍为 experimental，消费路径由 Chat / FileBrowser / AI-generated UI focused verifier 证明。
- GitNexus detect：`detect-changes --repo cangjie-live-codelattice --scope unstaged` 返回 affected processes `0` / risk `low`；GitNexus 对新鲜 demo_support Cangjie 符号仍有 graph non-coverage，按源码、focused verifier、build 与扫描兜底。

## 边界

本轮新增的是 Cangjie experimental demo_support public value API，不新增 public C ABI，不修改 production native bridge，不修改 `runtime/cjgui/cjpm.toml`，不写 `runtime_state.cj` / renderer state，不调用 native bridge，不发布 renderer truth。

`CjguiExperimentalDemoRunHarness` 不启动进程、不替代 shell verifier；它只在 demo binary 内部把 shared output 与 commit result 汇总为 framework-facing run result。真实可运行证据仍由 verifier 编译并执行 demo binary 证明。

## 设计意图出口自检

- 本轮是否改变主题状态：是。shared demo_support 从 output / commit harness 推进到 demo run/result harness first slice。
- 本轮是否改变 canonical tail / endpoint：否。不改变 Renderer canonical endpoint。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加“run result 是 demo-host 脱水 facts，不是 renderer truth”；stop-line 仍禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：是。下一步转向 `P1 CJGUI shared demo_support demo run harness coverage expansion`。
- 是否同步 topic manifest：本轮只同步 CJGUI demo/framework 进度入口，不改变 Renderer topic manifest truth。
- 已同步哪些索引：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md` 与 `CJGUI_DEMO_PROGRESS.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support demo run harness coverage expansion`
