# P1 internal Renderer visible-window NSApplication shared-application lifecycle evidence owner stage closure review

状态：implementation closure / internal value owner / no AppKit side effect

## 本阶段完成

本阶段按 [lifecycle evidence owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-lifecycle-evidence-owner-preflight-decision.md) 落地 internal value-style owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence.cj)
- [verify_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence_owner.sh)

新增 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`

## Current truth

本 owner 只把 cleanup / headless safety facts 接成 lifecycle evidence facts，并固定：

- lifecycle owner evidence required
- application singleton ownership evidence required
- run-loop execution evidence still required
- teardown ordering evidence still required
- headless artifact policy evidence-only
- side-effect containment evidence still required before accessor call
- actual application singleton accessor call still blocked
- no public API / public C ABI / renderer state write / backend-ready truth

## 验证

- RED：新增 owner probe 后先运行，因缺少 owner file 失败，exit 3。
- GREEN：新增 owner 后 `verify_renderer_visible_window_nsapplication_shared_application_lifecycle_evidence_owner.sh` 通过。
- Build：`cjpm build --target-dir /tmp/cjgui-lifecycle-evidence-owner-build --skip-script` 通过，仍有既有 230 条 unused warnings。

本阶段 build 前按要求 source `envsetup.sh`；自动化 sandbox 中 `ps` 被拒，使用 `/tmp/cjgui-ps-shim` 让 envsetup 正确识别 shell 后重试通过。

## Stop-line

本阶段未新增 native `.h` / `.m` C ABI，未调用 application singleton accessor，未创建 `NSApplication`，未 activation，未修改 activation policy，未运行 AppKit event loop，未进入 native visible order，未获取 drawable，未创建 encoder，未 draw，未 `commit` / `present`，未提交 GPU work，未执行 render，未写 `runtime_state.cj`，未新增 public API，未创建 backend-ready truth。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner stop-line reconciliation decision`
