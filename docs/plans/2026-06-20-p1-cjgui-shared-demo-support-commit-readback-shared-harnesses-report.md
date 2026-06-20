# CJGUI shared demo_support commit/readback shared harnesses 扩展报告

本次让 CJGUI minimal UI framework 的 shared owner-local commit/readback 主路径从 5 个代表 demo 扩展到 7 个 demo。Shared demo harness 与 Shared multi-demo harness 现在和 Todo、Settings、Chat、FileBrowser、AI-generated UI 一样真实 import / 调用 `CjguiExperimentalDemoOwnerLocalCommitSession`，focused verifier 实际编译运行 demo 二进制并校验 before -> after、readback、rollback boundary 与 `not_published=true`。

这不是 renderer state write，也不是 production state-store publication。所有 commit 都停在 demo-host in-memory 范围，继续证明 shared framework primitive 可以被多个真实 demo 和 shared harness 复用，而不是每个 harness 复制自己的 commit/result API。

## 本次真实前进

- [shared_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_demo_harness_app.cj) 新增 shared commit session，并在 Todo harness flow 后执行 `shared_demo_harness.commit_todo_flow` owner-local commit。
- [shared_multi_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_multi_demo_harness_app.cj) 新增 shared commit session，并在 Todo + FileBrowser multi-flow 后执行 `shared_multi_demo_harness.commit_multi_flow` owner-local commit。
- [verify_cjgui_shared_demo_harness_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_harness_app.sh) 与 [verify_cjgui_shared_multi_demo_harness_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_multi_demo_harness_app.sh) 现在复制 shared commit support、编译运行 demo，并断言 `shared_commit_output`、`shared_commit_readback`、`shared_commit_rollback_boundary` 与 `shared_commit_not_published=true`。
- [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh) 从 5 demo aggregate 扩展为 7 demo aggregate，回显 `cjgui_shared_demo_commit_demo_count=7`。

## before / after

- Before：`CjguiExperimentalDemoOwnerLocalCommitSession` 覆盖 Todo、Settings、Chat、FileBrowser、AI-generated UI 五个代表 demo；Shared demo harness 与 Shared multi-demo harness 仍只消费 component/action/output shared session。
- After：Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness 七个 demo 全部通过同一个 shared commit/readback primitive 产出 commit result、readback state、rollback boundary 与 not-published facts。
- Readback：Shared demo harness 读回 `items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent`；Shared multi-demo harness 读回 `todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent`。

## 验证

- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_harness_app.sh`：通过，实际编译运行 Shared demo harness demo，回显 `shared_demo_harness_shared_commit_readback=true` 与 `shared_demo_harness_shared_commit_not_published=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_multi_demo_harness_app.sh`：通过，实际编译运行 Shared multi-demo harness demo，回显 `shared_multi_demo_harness_shared_commit_readback=true` 与 `shared_multi_demo_harness_shared_commit_not_published=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh`：通过，回显 `cjgui_shared_demo_commit_demo_count=7` 与 `cjgui_shared_demo_commit_demos=todo,settings,chat,file_browser,ai_generated_ui,shared_demo_harness,shared_multi_demo_harness`。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh`：通过，保持 `legacy_demo_output_api_retired_count=5` 与 `representative_demo_binary_verifier_count=5`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh`：通过，保持 `shared_contract_legacy_output_api_retired_count=5` 与 `shared_contract_demo_binary_verifier_count=5`。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-commit-readback-shared-harnesses-target --skip-script`：通过；输出包含既有 unused / stack frame warning，未形成阻断。
- `git diff --check`、Markdown absolute link check、README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / CJGUI_DEMO_PROGRESS reachability、public declaration scan、protected path scan、code-scope forbidden scan 均通过；`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 affected processes `0` / risk `low`；CodeLattice 当前会话无可调用工具，按 AGENTS.md 以源码、focused verifier、build 与 scans 兜底。

## 边界

本轮没有新增 public API、public C ABI、native bridge callable、renderer state write 或 runtime state write；没有修改 `runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files。

`not_published=true` 仍是 stop-line：它只证明 demo-host in-memory commit/readback 成立，不是 publication receipt、renderer truth 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是。shared owner-local commit/readback primitive 覆盖从 5 个代表 demo 扩展到 7 个 demo。
- 本轮是否改变 canonical tail / endpoint：否。不改变 Renderer canonical endpoint。
- 本轮是否改变 owner / truth / stop-line：否。truth 仍是 demo-host process-local facts；stop-line 仍禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：是。下一步转向把 commit/readback primitive 扩展到 shared contract demos，或抽出更通用的 shared demo commit harness。
- 是否同步 topic manifest：本轮只同步 CJGUI demo/framework 进度入口，不改变 Renderer topic manifest truth。
- 已同步哪些索引：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md` 与 `CJGUI_DEMO_PROGRESS.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support commit/readback coverage expansion for shared contract demos first slice`
