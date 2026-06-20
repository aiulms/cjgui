# CJGUI shared demo_support commit harness 覆盖扩展报告

本次让 CJGUI minimal UI framework 的 owner-local commit/readback 主路径从 2 个代表 demo 扩展到当前全部 10 个 runnable demo。Settings、Chat、FileBrowser、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 已从 demo-local commit wrapper / 手写 result 校验迁到 `CjguiExperimentalDemoCommitHarness`；Todo 与 AI-generated UI 保持已迁移状态。

证据是 focused verifier 实际编译并运行 demo 二进制，逐个校验业务 before -> after、readback、rollback boundary、`not_published=true` 与 `*_shared_commit_harness_imported=true`。Aggregate verifier 进一步回显 `cjgui_shared_demo_commit_demo_count=10`，证明 shared commit harness 覆盖全部 runnable demo。

## 本次真实前进

- [settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj)、[chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj) 与 [file_browser_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/file_browser_app.cj) 现在直接持有 `CjguiExperimentalDemoCommitHarness`，不再定义 demo-local `commitSharedState` / `commitReadback` / `commitRollbackBoundary` wrapper。
- [shared_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_demo_harness_app.cj)、[shared_multi_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_multi_demo_harness_app.cj)、[shared_layout_style_input_focus_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_layout_style_input_focus_contract_app.cj)、[ai_generated_ui_shared_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj) 与 [reusable_component_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/reusable_component_contract_app.cj) 同步迁入 shared harness。
- 8 个 focused verifier 与 aggregate verifier 已更新为要求 `CjguiExperimentalDemoCommitHarness`，并拒绝本地 commit wrappers。Todo 与 AI-generated UI 的 first-slice verifier 保持 green。
- `CjguiExperimentalDemoCommitHarness.resultMatches` 现在是 10 个 runnable demo 的统一 commit result / readback / rollback boundary 校验入口。

## before / after

- Before：`CjguiExperimentalDemoCommitHarness` 只覆盖 Todo 与 AI-generated UI；其余 8 个 runnable demo 仍直接持有 `CjguiExperimentalDemoOwnerLocalCommitSession` 并保留本地 wrapper / 手写 result 校验。
- After：10 个 runnable demo 全部通过 `CjguiExperimentalDemoCommitHarness` 执行 owner-local commit，并通过 shared `resultMatches` 校验 readback、rollback boundary 与 not-published facts。
- Readback：所有 demo 的业务 before -> after 输出保持稳定；本轮只收敛 commit/readback 校验路径，不改变业务状态机。

## 验证

- TDD RED：`runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh` 先失败于缺少 `import cjgui.demo_support.{CjguiExperimentalDemoCommitHarness}`。
- Focused verifier：Settings、Chat、FileBrowser、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract、Reusable component contract、Todo 与 AI-generated UI focused verifier 均通过，并实际运行 demo binary。
- Aggregate verifier：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh` 通过，回显 `cjgui_shared_demo_commit_harness=CjguiExperimentalDemoCommitHarness` 与 `cjgui_shared_demo_commit_demo_count=10`。

## 边界

本轮不新增 public C ABI，不修改 production native bridge，不修改 `runtime/cjgui/cjpm.toml`，不写 `runtime_state.cj` / renderer state，不发布 renderer truth。

`not_published=true` 仍只证明 demo-host in-memory commit/readback 成立，不是 publication receipt、renderer truth 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是。shared commit harness 从 first slice 扩展为当前 10 个 runnable demo 的 commit/readback/result 校验主路径。
- 本轮是否改变 canonical tail / endpoint：否。不改变 Renderer canonical endpoint。
- 本轮是否改变 owner / truth / stop-line：否。truth 仍是 demo-host process-local facts；stop-line 仍禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：是。下一步转向 demo-facing commit surface cleanup，让 demo 和 verifier 更少直接暴露底层 owner-local session。
- 是否同步 topic manifest：本轮只同步 CJGUI demo/framework 进度入口，不改变 Renderer topic manifest truth。
- 已同步哪些索引：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md` 与 `CJGUI_DEMO_PROGRESS.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support commit harness-only demo surface cleanup`
