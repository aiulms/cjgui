# CJGUI shared demo_support commit/readback shared contracts 扩展报告

本次让 CJGUI minimal UI framework 的 shared owner-local commit/readback 主路径从 7 个 runnable demo 扩展到 10 个 runnable demo。Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 现在和 Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness 一样真实 import / 调用 `CjguiExperimentalDemoOwnerLocalCommitSession`，focused verifier 实际编译运行 demo 二进制并校验 before -> after、readback、rollback boundary 与 `not_published=true`。

这不是 renderer state write，也不是 production state-store publication。所有 commit 都停在 demo-host in-memory 范围，继续证明 shared framework primitive 可以被当前全部 10 个 demo 复用，而不是每个 contract demo 复制自己的 commit/result API。

## 本次真实前进

- [shared_layout_style_input_focus_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_layout_style_input_focus_contract_app.cj) 新增 shared commit session，并在 layout / style / text input / focus contract flow 后执行 `shared_layout_style_input_focus.commit_contract_flow` owner-local commit。
- [ai_generated_ui_shared_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj) 新增 shared commit session，并在 generated UI accept refresh 后执行 `ai_generated_ui_shared_contract.commit_accept_refresh` owner-local commit。
- [reusable_component_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/reusable_component_contract_app.cj) 新增 shared commit session，并在 Todo / FileBrowser / AI-generated UI reusable component flow 后执行 `reusable_component_contract.commit_reuse_flow` owner-local commit。
- 三个 focused verifier 现在复制 shared commit support、编译运行 demo，并断言 `shared_commit_output`、`shared_commit_readback`、`shared_commit_rollback_boundary` 与 `shared_commit_not_published=true`。
- [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh) 从 7 demo aggregate 扩展为 10 demo aggregate，回显 `cjgui_shared_demo_commit_demo_count=10`。

## before / after

- Before：`CjguiExperimentalDemoOwnerLocalCommitSession` 覆盖 Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness 七个 demo；三个 shared/contract demo 仍只消费 component/action/output shared session。
- After：当前 10 个 runnable demo 全部通过同一个 shared commit/readback primitive 产出 commit result、readback state、rollback boundary 与 not-published facts。
- Readback：Shared layout/style/input/focus contract 读回 `layout=split_detail;style=focus_accent;input=main;focus=file_filter`；AI-generated UI shared contract 读回 `components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button`；Reusable component contract 读回 `components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button`。

## 验证

- `runtime/cjgui/native/scripts/verify_cjgui_shared_layout_style_input_focus_contract_app.sh`：通过，实际编译运行 Shared layout/style/input/focus contract demo，回显 `shared_layout_style_input_focus_contract_shared_commit_readback=true` 与 `shared_layout_style_input_focus_contract_shared_commit_not_published=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_shared_contract_app.sh`：通过，实际编译运行 AI-generated UI shared contract demo，回显 `ai_generated_ui_shared_contract_shared_commit_readback=true` 与 `ai_generated_ui_shared_contract_shared_commit_not_published=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_reusable_component_contract_app.sh`：通过，实际编译运行 Reusable component contract demo，回显 `reusable_component_contract_shared_commit_readback=true` 与 `reusable_component_contract_shared_commit_not_published=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh`：通过，回显 `cjgui_shared_demo_commit_demo_count=10` 与 `cjgui_shared_demo_commit_demos=todo,settings,chat,file_browser,ai_generated_ui,shared_demo_harness,shared_multi_demo_harness,shared_layout_style_input_focus_contract,ai_generated_ui_shared_contract,reusable_component_contract`。
- 本轮 TDD RED：加严 verifier 后先运行 `verify_cjgui_shared_layout_style_input_focus_contract_app.sh`，得到缺少 `CjguiExperimentalDemoOwnerLocalCommitSession` import 的预期失败；随后实现 demo 消费并转绿。

## 边界

本轮没有新增 public API、public C ABI、native bridge callable、renderer state write 或 runtime state write；没有修改 `runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files。

`not_published=true` 仍是 stop-line：它只证明 demo-host in-memory commit/readback 成立，不是 publication receipt、renderer truth 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是。shared owner-local commit/readback primitive 覆盖从 7 个 demo 扩展到当前全部 10 个 runnable demo。
- 本轮是否改变 canonical tail / endpoint：否。不改变 Renderer canonical endpoint。
- 本轮是否改变 owner / truth / stop-line：否。truth 仍是 demo-host process-local facts；stop-line 仍禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：是。下一步转向减少 commit wrapper 重复、抽出更通用 shared demo commit harness，或继续把 owner-local commit/readback 与 shared component/state/output 主路径合并得更自然。
- 是否同步 topic manifest：本轮只同步 CJGUI demo/framework 进度入口，不改变 Renderer topic manifest truth。
- 已同步哪些索引：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md` 与 `CJGUI_DEMO_PROGRESS.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support commit/readback wrapper reduction and shared commit harness extraction first slice`
