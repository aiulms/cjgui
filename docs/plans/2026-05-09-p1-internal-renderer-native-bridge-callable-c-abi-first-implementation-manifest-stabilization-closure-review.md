# P1 渲染器 native bridge callable C ABI 第一实现 manifest 稳定化收口复核

日期：2026-05-09

状态：manifest stabilization closure / no-resource callable only

## 文件定位

本 closure 记录 native bridge callable `C ABI` first implementation manifest 已完成封账。本轮只固定四个 no-resource callable、probe allowlist、构建边界和 stop-line，不接仓颉 FFI，不修改 build config，不创建 native object，不暴露 public runtime API。

## 封账结果

已新增并封账：

- [callable C ABI first implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-preflight-decision.md)
- [callable C ABI first implementation closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-first-implementation-closure-review.md)
- [callable C ABI first implementation next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-next-boundary-decision.md)
- [callable C ABI first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-manifest.md)

固定 callable：

- `cjgui_native_bridge_surface_version(void)`
- `cjgui_native_bridge_surface_capabilities(void)`
- `cjgui_native_bridge_status_ok(void)`
- `cjgui_native_bridge_no_resource_admission(void)`

## 边界确认

本轮修改 production native skeleton `.h` / `.m`，但只新增 no-resource callable `C ABI`。本轮没有接 FFI，没有新增 runtime `.cj` FFI declaration，没有修改 `runtime/cjgui/cjpm.toml`，没有修改 package / build config，没有修改 smoke native files，没有创建 native object、native handle、raw pointer，没有返回 native pointer，没有 import / use Cocoa / Metal / QuartzCore，没有调用 retain / release / destroy，没有提交 GPU work，没有执行 render，没有写 renderer state，没有修改 `runtime_state.cj`，没有新增 public runtime API / diagnostics。

## 验证记录

最终验证结果：

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过。
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`：通过，继续证明 `cjpm build` 与 production native isolated compile 分离。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-callable-c-abi-first-implementation-target --skip-script`：通过，仅保留既有 `230 warnings`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。
- 新 native / docs no-index whitespace check：通过。
- Markdown absolute link missing target check：通过。
- README / tracker / plans README / runtime README reachability：通过。
- Markdown 中文标题与正文抽查：通过。
- protected path check：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行，tracked diff 为 `0`；`runtime/cjgui/cjpm.toml` tracked diff 为 `0`；`labs/macos_bridge_smoke/native/*` status 为 `0`。
- comment-aware public declaration scan：仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- native forbidden scan：通过，未出现 `cjgui_app_run`、`cjgui_last_error`、Cocoa / Metal / QuartzCore import、AppKit / Metal object creation、pointer return、native handle / token return。
- GitNexus `detect_changes(scope=unstaged)`：risk `low`，affected processes `0`，affected_count `17 files / 18 symbols`。

## 设计意图出口自检

- 本轮是否改变主题状态：是。native bridge callable `C ABI` 从 planning manifest 推进到 no-resource first implementation manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否。runtime planning endpoint 仍是 `CjguiInternalRendererNoCallableCAbiReadiness` / `cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`；production native callable list 成为当前 artifact endpoint。
- 本轮是否改变 owner / truth / stop-line：是。production native skeleton owner truth 扩展为 no-resource callable surface；stop-line 继续禁止 FFI、runtime `.cj` declaration、native object、pointer return、AppKit / Metal、state write 与 public API。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`
