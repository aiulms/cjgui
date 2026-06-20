# CJGUI shared demo_support commit/write/readback primitive 第一切片报告

本次让 CJGUI minimal UI framework 从 shared output / component-action session 继续向可复用状态提交语义推进：新增 `CjguiExperimentalDemoOwnerLocalCommitSession` 与 `CjguiExperimentalDemoCommitResult`，把 owner-local commit、readback、rollback boundary 与 not-published facts 抽成 shared demo_support primitive。Todo、Chat 与 FileBrowser 三个代表 demo 已真实 import / 调用该 primitive，并通过各自 focused verifier 编译运行、回显 commit summary、readback state、rollback boundary 与 `not_published=true`。

这不是 renderer state write，也不是 production state-store publication。该 primitive 只在 demo host 进程内保存短生命周期状态，用于证明 shared commit/readback 语义可以被多个 demo 复用。

## 本次真实前进

- 新增 [runtime_cjgui_experimental_demo_owner_local_commit_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_owner_local_commit_session.cj)，提供 `CjguiExperimentalDemoOwnerLocalCommitSession` 与 `CjguiExperimentalDemoCommitResult`。
- [todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj) 现在在完成 todo 后执行 `todo.commit_complete` shared commit，并读回 `items=1;first=Write first CJGUI todo;first_done=true`。
- [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj) 现在在消息流完成后执行 `chat.commit_thread` shared commit，并读回三条消息的最终 thread state。
- [file_browser_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/file_browser_app.cj) 现在在详情面板刷新后执行 `file_browser.commit_detail` shared commit，并读回展开、过滤、选择与详情状态。
- 新增 [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh)，聚合 Todo、Chat、FileBrowser 三个 focused verifier，确认同一 shared primitive 被多个 demo 消费。

## before / after

- Before：`CjguiExperimentalDemoComponentActionSession` 已统一承载 component/action route、UI state core、interaction trace 与 `CjguiExperimentalDemoOutput`，但 commit/readback/rollback boundary 仍没有独立 shared value primitive。
- After：`CjguiExperimentalDemoOwnerLocalCommitSession` 提供 owner-local `commitComponentAction(...)`、`readback()`、`rollbackBoundary()` 与 write count；`CjguiExperimentalDemoCommitResult` 脱水承载 before / after / readback / rollback / committed / readbackOk / rollbackAvailable / notPublished / summary facts。
- Readback：三个 demo 的 verifier 都检查 `shared_commit_readback`、`shared_commit_rollback_boundary` 与 `shared_commit_not_published=true`，不是只 grep 源码。

## 验证

- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh`：通过，回显 `cjgui_shared_demo_commit_write_readback_verified=true` 与 `cjgui_shared_demo_commit_demo_count=3`。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh`：通过，回归确认代表 demo 仍不直接消费 legacy Output API。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh`：通过，回归确认 shared/contract legacy Output API tombstone 仍稳定。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-commit-write-readback-target --skip-script`：通过；构建仍有既有 unused / stack-frame warnings，最终输出 `cjpm build success`。
- `git diff --check`：通过。
- Markdown absolute link check：通过，项目 docs / README / runtime README 范围检查 `2028` 个 Markdown 文件、`18894` 个项目绝对链接，missing target 数量为 `0`。
- reachability：README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX、CJGUI_DEMO_PROGRESS 与本 report 均已互相可达。
- public declaration scan：本轮新增 experimental Cangjie demo_support public surface `CjguiExperimentalDemoCommitResult` 与 `CjguiExperimentalDemoOwnerLocalCommitSession`，以及其必要 public fields / methods；没有新增 public C ABI。
- protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行，本轮未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files。
- GitNexus impact：`CjguiExperimentalDemoComponentActionSession`、`CjguiExperimentalDemoOutput`、`CjguiExperimentalDemoUiStateCore` 均返回 `UNKNOWN / not found`，按图谱未覆盖处理，不作为安全证明。
- GitNexus impact：新增 `CjguiExperimentalDemoOwnerLocalCommitSession` 与 `CjguiExperimentalDemoCommitResult` 均返回 `UNKNOWN / not found`，符合新 owner 尚未索引的图谱覆盖缺口。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 changed files `15`、affected processes `0`、risk `low`。
- CodeLattice：本轮未暴露可调用工具，按工具覆盖缺口记录；源码、focused verifier、build 与扫描兜底。

## 边界

本轮新增的是 experimental Cangjie public demo_support 类型，不新增 public C ABI，不修改 production native bridge，不调用 native bridge，不写 `runtime_state.cj` / renderer state，不修改 `runtime/cjgui/cjpm.toml`，不声明 renderer backend ready truth，不发布 state-store commit，不新增 stable public API。

`not_published=true` 是明确 stop-line：它证明 commit result 仍停在 demo-host in-memory facts，不是 publication receipt，也不是 renderer truth。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 状态，从 shared output / action session 进入 shared owner-local commit/readback primitive 第一切片。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；Renderer 当前 endpoint 仍以 stage892 链为准。
- 本轮是否改变 owner / truth / stop-line：新增 shared demo_support owner 文件；truth 仍是 demo-host process-local facts；stop-line 继续禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：把 CJGUI demo_support 下一步推进到 `P1 CJGUI shared demo_support commit/readback coverage expansion for remaining demos first slice`。
- 是否同步 topic manifest：同步 README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX、CJGUI_DEMO_PROGRESS 与三个 Renderer/macOS topic manifest的维护备注。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support commit/readback coverage expansion for remaining demos first slice`
