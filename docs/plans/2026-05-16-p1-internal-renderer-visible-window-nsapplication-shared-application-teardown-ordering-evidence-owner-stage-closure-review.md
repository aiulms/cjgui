# P1 internal Renderer visible-window NSApplication shared-application teardown ordering evidence owner stage closure review

状态：implementation closure / internal value owner / no teardown execution

## 本阶段完成

本阶段按 [teardown ordering evidence owner preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-preflight-decision.md) 落地 internal value-style owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence.cj)
- [verify_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence_owner.sh)

新增 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`

## Current truth

本 owner 只固定：

- run-loop evidence readiness preserved
- teardown ordering evidence still required
- teardown-before-visible evidence required
- bounded owner shutdown evidence required
- stop-condition-before-teardown evidence required
- auto-close cleanup evidence required
- fail-closed teardown route required
- actual teardown execution still blocked
- actual AppKit event loop / bounded pump still blocked
- actual application singleton accessor call still blocked
- no public API / public C ABI / renderer state write / backend-ready truth

## 验证

- RED：新增 owner probe 后先运行，因缺少 owner file 失败，exit 3。
- GREEN：新增 owner 后 `verify_renderer_visible_window_nsapplication_shared_application_teardown_ordering_evidence_owner.sh` 通过。
- Build：待最终 closure verification 运行 `cjpm build --target-dir /tmp/cjgui-teardown-ordering-evidence-owner-build --skip-script`。

## Stop-line

本阶段未新增 native `.h` / `.m` C ABI，未执行真实 teardown，未运行 AppKit event loop，未实现 bounded run-loop pump，未调用 application singleton accessor，未创建 `NSApplication`，未 activation，未修改 activation policy，未进入 native visible order，未获取 drawable，未创建 encoder，未 draw，未 `commit` / `present`，未提交 GPU work，未执行 render，未写 `runtime_state.cj`，未新增 public API，未创建 backend-ready truth。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application teardown ordering evidence owner stop-line reconciliation decision`
