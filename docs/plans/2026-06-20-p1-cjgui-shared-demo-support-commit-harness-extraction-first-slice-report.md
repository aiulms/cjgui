# CJGUI shared demo_support commit harness 抽取第一切片报告

本次让 CJGUI minimal UI framework 的 owner-local commit/readback 主路径从“每个 demo 自己包 commit wrapper 和 result 校验”前进到 shared harness first slice。新增 `CjguiExperimentalDemoCommitHarness`，并让 Todo 与 AI-generated UI 两个代表 demo 真实 import / 调用它；focused verifier 实际编译运行 demo 二进制，校验 before -> after、readback、rollback boundary、`not_published=true` 与 harness 输出。

这不是 renderer state write，也不是 production publication。它只把 demo-host in-memory commit/readback 的重复校验收敛进 shared demo_support，继续保持 runtime_state / renderer_state 未写入、public C ABI 未扩展。

## 本次真实前进

- [runtime_cjgui_experimental_demo_owner_local_commit_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_owner_local_commit_session.cj) 新增 `CjguiExperimentalDemoCommitHarness`，组合既有 `CjguiExperimentalDemoOwnerLocalCommitSession` 与 `CjguiExperimentalDemoCommitResult`，并提供 `resultMatches` 统一校验 commit result、readback 与 rollback boundary。
- [todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj) 从直接持有 `CjguiExperimentalDemoOwnerLocalCommitSession` 改为持有 `CjguiExperimentalDemoCommitHarness`，移除 demo-local `commitSharedState` / `commitReadback` / `commitRollbackBoundary` wrapper。
- [ai_generated_ui_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_app.cj) 同样迁到 shared commit harness，并让 `resultMatches` 承担重复 commit result 校验。
- [verify_cjgui_todo_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh) 与 [verify_cjgui_ai_generated_ui_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh) 现在要求 demo 使用 `CjguiExperimentalDemoCommitHarness`，并拒绝本地 `commitSharedState` / `commitReadback` / `commitRollbackBoundary` wrapper。
- [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh) 继续覆盖 10 个 runnable demo，同时新增 Todo 与 AI-generated UI 的 shared commit harness evidence。
- 10 个 `verify_cjgui_*_app.sh` focused verifier 的 demo binary launch 路径从 hardcoded `darwin_x86_64_cjnative` 改为按 `${CANGJIE_HOME}/runtime/lib` 下的 `libcangjie-runtime.dylib` 自动发现 runtime library dir，修复 arm64 工具链下 `@rpath/libcangjie-runtime.dylib` 找不到的问题，确保 runnable proof 真正执行 demo binary。

## before / after

- Before：10 个 runnable demo 已共用 `CjguiExperimentalDemoOwnerLocalCommitSession`，但每个 demo 仍保留重复的 demo-local commit wrapper 与手写 result 校验。
- After：Todo 与 AI-generated UI 先迁到 `CjguiExperimentalDemoCommitHarness`；这两个代表 demo 的 commit/readback/rollback 校验路径由 shared demo_support 承担。
- Readback：Todo 仍读回 `items=1;first=Write first CJGUI todo;first_done=true`；AI-generated UI 仍读回 `components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel`。

## 验证

- TDD RED：先更新 Todo focused verifier，运行 `runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh`，预期失败于缺少 `CjguiExperimentalDemoCommitHarness` declaration。
- Launch recovery RED：在当前 arm64 工具链下 focused verifier 先复现 `dyld: Library not loaded: @rpath/libcangjie-runtime.dylib`，原因是 verifier 只注入 `darwin_x86_64_cjnative` runtime path。
- `runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh`：通过，回显 `todo_shared_commit_harness_imported=true`、`todo_shared_commit_readback=true` 与 `todo_shared_commit_not_published=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh`：通过，回显 `ai_generated_ui_shared_commit_harness_imported=true`、`ai_generated_ui_shared_commit_readback=true` 与 `ai_generated_ui_shared_commit_not_published=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh`：通过，回显 `cjgui_shared_demo_commit_harness=CjguiExperimentalDemoCommitHarness` 与 `cjgui_shared_demo_commit_demo_count=10`。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh` 与 `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh`：通过，legacy Output API 退役状态未回退。

## 边界

本轮新增的是 experimental Cangjie demo_support public class，不是 stable public API，也不是 public C ABI。未修改 `runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files；未写 `runtime_state.cj` / renderer state；未发布 renderer truth。

`not_published=true` 仍是 stop-line：它只证明 demo-host in-memory commit/readback 成立，不是 publication receipt、renderer truth 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是。commit/readback 主路径从 session-only 覆盖推进到 shared harness first slice。
- 本轮是否改变 canonical tail / endpoint：否。不改变 Renderer canonical endpoint。
- 本轮是否改变 owner / truth / stop-line：否。truth 仍是 demo-host process-local facts；stop-line 仍禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：是。下一步转向把 `CjguiExperimentalDemoCommitHarness` 扩展到 Settings、Chat、FileBrowser 与 shared/contract demos，继续减少 demo-local commit wrapper。
- 是否同步 topic manifest：本轮只同步 CJGUI demo/framework 进度入口，不改变 Renderer topic manifest truth。
- 已同步哪些索引：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md` 与 `CJGUI_DEMO_PROGRESS.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support commit harness coverage expansion for remaining demos`
