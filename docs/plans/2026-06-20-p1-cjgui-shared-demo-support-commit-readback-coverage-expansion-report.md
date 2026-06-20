# CJGUI shared demo_support commit/readback 覆盖扩展报告

本次让 CJGUI minimal UI framework 的 shared owner-local commit/readback 主路径从 3 个代表 demo 扩展到 5 个代表 demo。Settings 与 AI-generated UI 现在和 Todo、Chat、FileBrowser 一样真实 import / 调用 `CjguiExperimentalDemoOwnerLocalCommitSession`，focused verifier 实际编译运行 demo 二进制并校验 before -> after、readback、rollback boundary 与 `not_published=true`。

这不是 renderer state write，也不是 production state-store publication。所有 commit 都停在 demo-host in-memory 范围，继续证明 shared framework primitive 可以被多个真实 demo 复用，而不是每个 demo 复制自己的 commit/result API。

## 本次真实前进

- [settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj) 新增 shared commit session，并在 preferences 更新后执行 `settings.commit_preferences` owner-local commit。
- [ai_generated_ui_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_app.cj) 新增 shared commit session，并在 generated UI accept refresh 后执行 `ai_generated_ui.commit_accept_refresh` owner-local commit。
- [verify_cjgui_settings_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh) 与 [verify_cjgui_ai_generated_ui_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh) 现在复制 shared commit support、编译运行 demo，并断言 `shared_commit_output`、`shared_commit_readback`、`shared_commit_rollback_boundary` 与 `shared_commit_not_published=true`。
- Todo、Settings、Chat、FileBrowser、AI-generated UI 五个 focused verifier 现在都会生成无 public 声明的临时 `cjgui` package root shim，避免依赖 `/private/tmp` 旧残留文件。
- [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh) 从 3 demo aggregate 扩展为 5 demo aggregate，回显 `cjgui_shared_demo_commit_demo_count=5`。

## before / after

- Before：`CjguiExperimentalDemoOwnerLocalCommitSession` 已覆盖 Todo、Chat、FileBrowser；Settings 与 AI-generated UI 仍只消费 component/action/output shared session。
- After：Todo、Settings、Chat、FileBrowser、AI-generated UI 五个代表 demo 全部通过同一个 shared commit/readback primitive 产出 commit result、readback state、rollback boundary 与 not-published facts。
- Readback：Settings 读回 `autosave=true;theme=dark;username=owner-updated;focus=theme_select`；AI-generated UI 读回 `components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel`。

## 验证

- `runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh`：通过，实际编译运行 Settings demo，回显 `settings_shared_commit_readback=true` 与 `settings_shared_commit_not_published=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh`：通过，实际编译运行 AI-generated UI demo，回显 `ai_generated_ui_shared_commit_readback=true` 与 `ai_generated_ui_shared_commit_not_published=true`。
- 五个 focused verifier 均通过干净自定义临时目录验证，确认不依赖 stale `/private/tmp` package 文件。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh`：通过，回显 `cjgui_shared_demo_commit_demo_count=5` 与 `cjgui_shared_demo_commit_demos=todo,settings,chat,file_browser,ai_generated_ui`。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh`：通过，保持 `legacy_demo_output_api_retired_count=5` 与 `representative_demo_binary_verifier_count=5`。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh`：通过，保持 shared / contract legacy Output API retirement guard。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-commit-readback-coverage-expansion-target --skip-script`：通过；输出包含既有 unused / stack frame warning，未形成阻断。

## 边界

本轮没有新增 public API、public C ABI、native bridge callable、renderer state write 或 runtime state write；没有修改 `runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files。

`not_published=true` 仍是 stop-line：它只证明 demo-host in-memory commit/readback 成立，不是 publication receipt、renderer truth 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是。shared owner-local commit/readback primitive 覆盖从 3 个代表 demo 扩展到 5 个代表 demo。
- 本轮是否改变 canonical tail / endpoint：否。不改变 Renderer canonical endpoint。
- 本轮是否改变 owner / truth / stop-line：否。truth 仍是 demo-host process-local facts；stop-line 仍禁止 runtime_state / renderer_state write、native bridge、public C ABI、backend-ready truth。
- 本轮是否改变唯一 next opening：是。下一步转向把 commit/readback primitive 扩展到 shared harness / contract demos，或抽出更通用的 shared demo commit harness。
- 是否同步 topic manifest：本轮只同步 CJGUI demo/framework 进度入口，不改变 Renderer topic manifest truth。
- 已同步哪些索引：`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md` 与 `CJGUI_DEMO_PROGRESS.md`。

## 下一步最高价值目标

`P1 CJGUI shared demo_support commit/readback coverage expansion for shared harnesses first slice`
