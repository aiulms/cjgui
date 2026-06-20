# CJGUI shared demo_support demo-facing commit evidence naming cleanup 报告

本次让 CJGUI minimal UI framework 的 demo-facing commit evidence 更准确：10 个 runnable demo 的 focused verifier 不再把底层 `CjguiExperimentalDemoOwnerLocalCommitSession` 说成 `shared_commit_session_imported`，而是统一标记为 `CjguiExperimentalDemoCommitHarness` 的 internal primitive evidence。

证据是 TDD RED/GREEN：先更新 aggregate verifier，让它要求 `*_shared_commit_harness_internal_primitive_present=true` 并拒绝旧 `*_shared_commit_session_*` 命名；当前 focused verifier 随即在 Todo log 上失败。随后改 10 个 focused verifier 的 evidence 命名，aggregate verifier 重新实际编译并运行 10 个 demo binary，回显 `cjgui_shared_demo_commit_harness_internal_primitive=CjguiExperimentalDemoOwnerLocalCommitSession`、`cjgui_shared_demo_commit_demo_count=10` 与 `cjgui_shared_demo_commit_demo_output_harness_only=true`。

## 本次真实前进

- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 的 verifier evidence 现在只把底层 commit session 描述为 harness internal primitive。
- Aggregate verifier 现在拒绝旧 `*_shared_commit_session_imported=true` 与 `*_shared_commit_session_name=CjguiExperimentalDemoOwnerLocalCommitSession`，防止 demo-facing evidence 重新泄漏底层 primitive。
- Demo app 输出保持 harness-only：仍只暴露 `shared_commit_harness=CjguiExperimentalDemoCommitHarness`、业务 before -> after、readback、rollback boundary 与 `not_published=true`。

## before / after

- Before：demo output 已经隐藏 `shared_commit_model=CjguiExperimentalDemoOwnerLocalCommitSession`，但 focused verifier 仍回显 `*_shared_commit_session_imported=true`，容易让证据层误读为 demo 仍直接消费底层 session primitive。
- After：focused verifier 回显 `*_shared_commit_harness_internal_primitive_present=true` 与 `*_shared_commit_harness_internal_primitive_name=CjguiExperimentalDemoOwnerLocalCommitSession`，同时 aggregate verifier 输出 `cjgui_shared_demo_commit_harness_internal_primitive=CjguiExperimentalDemoOwnerLocalCommitSession`。
- Readback：10 个 demo 的 owner-local commit、readback、rollback boundary 与 not-published 证据保持不变。

## 验证结果

- TDD RED：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh` 先失败于缺少 `todo_shared_commit_harness_internal_primitive_present=true`，并展示 Todo focused verifier 仍输出旧 `todo_shared_commit_session_imported=true`。
- Focused / aggregate GREEN：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh` 通过，实际覆盖 10 个 demo binary。
- 本轮后续完整验证还包括 `cjpm build --target-dir /tmp/cjgui-shared-demo-commit-evidence-naming-target --skip-script`、legacy Output API retirement focused verifiers、`git diff --check`、Markdown link / reachability / public / protected / forbidden scans 与 GitNexus detect-changes。

## 边界

本轮不修改 demo app 行为，不新增 public API，不新增 public C ABI，不修改 production native bridge，不修改 `runtime/cjgui/cjpm.toml`，不写 `runtime_state.cj` / renderer state，不发布 renderer truth。

`CjguiExperimentalDemoOwnerLocalCommitSession` 仍是 shared harness 的 internal implementation primitive；本轮只清理 verifier evidence 命名，不移除底层 session 类型。

## 设计意图出口自检

- 本轮是否改变主题状态：是。shared commit harness 不仅是 demo-facing output model，也成为 verifier evidence 的唯一外层命名。
- 本轮是否改变 canonical tail / endpoint：否。不改变 Renderer canonical endpoint。
- 本轮是否改变 owner / truth / stop-line：否。truth 仍是 demo-host process-local facts；stop-line 仍禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：是。下一步转向 `P1 CJGUI shared demo_support demo run harness first slice`，继续减少每个 demo 中重复的 component session + commit harness 编排代码。
- 是否同步 topic manifest：本轮只同步 CJGUI demo/framework 进度入口，不改变 Renderer topic manifest truth。
- 已同步哪些索引：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md` 与 `CJGUI_DEMO_PROGRESS.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support demo run harness first slice`
