# CJGUI shared demo_support commit harness-only demo surface cleanup 报告

本次让 CJGUI minimal UI framework 的 demo-facing commit surface 更接近 shared framework primitive：当前 10 个 runnable demo 不再把底层 `CjguiExperimentalDemoOwnerLocalCommitSession` 打印为 demo 输出，只保留 `CjguiExperimentalDemoCommitHarness` 作为 demo-facing commit/readback/result 校验入口。

证据是先更新 focused verifier，让 Settings demo 在当前实现上因 `shared_commit_model=CjguiExperimentalDemoOwnerLocalCommitSession` 输出失败；随后移除 10 个 demo 的该输出行，并由 aggregate verifier 实际编译运行 10 个 demo binary，回显 `cjgui_shared_demo_commit_demo_output_harness_only=true`、`cjgui_shared_demo_commit_demo_count=10`、readback / rollback / not-published 仍成立。

## 本次真实前进

- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 的 demo output 不再暴露底层 commit session primitive。
- 10 个 focused verifier 现在拒绝 demo binary 输出 `shared_commit_model=CjguiExperimentalDemoOwnerLocalCommitSession`。
- Aggregate verifier 新增 `cjgui_shared_demo_commit_demo_output_harness_only=true` 证据，证明 demo-facing commit surface 已收敛到 shared harness。

## before / after

- Before：10 个 runnable demo 已使用 `CjguiExperimentalDemoCommitHarness`，但 demo 输出仍同时暴露 `shared_commit_model=CjguiExperimentalDemoOwnerLocalCommitSession`，容易把底层 primitive 当成 demo-facing API。
- After：demo 输出只暴露 `shared_commit_harness=CjguiExperimentalDemoCommitHarness`、commit result、readback、rollback boundary 与 not-published facts；底层 session 仍作为 shared harness 内部 primitive，被 verifier 记录为 implementation evidence，而不是 demo-facing surface。
- Readback：业务 before -> after、readback、rollback boundary 与 `not_published=true` 均保持不变。

## 验证

- TDD RED：`runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh` 先失败于 `demo output must expose shared commit harness, not primitive session`。
- Focused GREEN：Settings verifier 通过，实际编译并运行 demo binary。
- Aggregate GREEN：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh` 通过，回显 `cjgui_shared_demo_commit_demo_count=10` 与 `cjgui_shared_demo_commit_demo_output_harness_only=true`。

## 边界

本轮不新增 public API，不新增 public C ABI，不修改 production native bridge，不修改 `runtime/cjgui/cjpm.toml`，不写 `runtime_state.cj` / renderer state，不发布 renderer truth。

`CjguiExperimentalDemoOwnerLocalCommitSession` 仍是 shared harness 的内部 implementation primitive；本轮只清理 demo-facing output，不移除底层 session 类型。

## 设计意图出口自检

- 本轮是否改变主题状态：是。shared commit harness 不仅覆盖 10 个 runnable demo，也成为 demo-facing commit surface 的唯一输出模型。
- 本轮是否改变 canonical tail / endpoint：否。不改变 Renderer canonical endpoint。
- 本轮是否改变 owner / truth / stop-line：否。truth 仍是 demo-host process-local facts；stop-line 仍禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：是。下一步转向减少 demo 对底层 shared commit implementation evidence 的 verifier 命名暴露，并继续寻找可替换 demo-specific API 的 shared primitive。
- 是否同步 topic manifest：本轮只同步 CJGUI demo/framework 进度入口，不改变 Renderer topic manifest truth。
- 已同步哪些索引：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md` 与 `CJGUI_DEMO_PROGRESS.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support demo-facing commit evidence naming cleanup`
