# P1 内部渲染器 native token table no-resource shell first implementation 复核

日期：2026-05-10

状态：implementation closure / classification shell completed

## 完成结论

本轮选择并完成 `P1 internal Renderer native token table no-resource classification callable first implementation bundle`。

实际新增 / 修改：

- 修改 `runtime/cjgui/native/cjgui_native_bridge.h`。
- 修改 `runtime/cjgui/native/cjgui_native_bridge.m`。
- 修改 `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`。
- 修改 `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`。
- 修改 `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`。
- 修改 `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`。
- 修改 `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`。
- 修改 `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`。
- 修改 `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`，仅同步 no-resource token shell allowlist，并继续禁止 issue / revoke。
- 新增 `runtime/cjgui/src/runtime_renderer_native_token_table_shell.cj`。

## 新增 callable

本轮只新增 no-resource classification shell callable：

- `cjgui_native_bridge_token_invalid(void)`
- `cjgui_native_bridge_token_table_capacity(void)`
- `cjgui_native_bridge_token_table_enabled(void)`
- `cjgui_native_bridge_token_classify(uint64_t token)`

返回约定：

- invalid token 固定为 `0`。
- capacity 固定为 `0`，表示 no slot allocated / disabled shell。
- enabled 固定为 `0`。
- classify 对 invalid token 返回 `0`，对 nonzero token 返回 `-1`，表示 table disabled / unsupported。

本轮没有实现 issue / revoke，没有创建 mutable table，没有绑定 native object，没有保存 raw pointer。

## 新增 runtime owner

新增 owner：

`runtime/cjgui/src/runtime_renderer_native_token_table_shell.cj`

Endpoint：

`CjguiInternalRendererNoNativeTokenTableShellReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`

Runtime input：

`CjguiInternalRendererNoNativeTokenTableImplementationReadiness`

owner 只调用四个 token shell no-resource C ABI，并把 invalid / capacity / enabled / classification 返回值脱水成 internal facts。它不写 state，不 public，不调用 resource callable，不创建 native object。

## RED / GREEN 记录

RED：

- 先更新 `verify_native_bridge_no_resource_symbols.sh` allowlist 后运行 symbol probe。
- probe 失败于 missing symbol `cjgui_native_bridge_token_invalid`，证明验证网会捕捉未落地 callable。

GREEN：

- 新增 native callable 后，symbol probe 通过。
- skeleton compile probe 通过。
- package-adjacent direct `cjc` probe 观察 token facts 成功。
- temporary `cjpm` package link probe 观察 token facts 成功。
- no-resource call probe 观察 token shell owner source 与 package-link facts 成功。
- isolated FFI probe allowlist 同步 token shell callable 后通过，未新增 resource / issue / revoke 调用。
- 主包 `cjpm build --target-dir /tmp/cjgui-renderer-native-token-table-shell-target --skip-script` 通过，仅出现既有 unused warnings 与新 owner unused default draft warning。

## 边界确认

- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 smoke native files。
- 未新增 public API / diagnostics。
- 未新增 issue / revoke callable。
- 未新增 resource callable。
- 未创建 resource object table。
- 未创建 native object、native handle、raw pointer。
- 未保存 raw pointer。
- 未返回 native pointer / handle。
- 未导入 Cocoa / Metal / QuartzCore。
- 未调用 retain / release / destroy。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。

## GitNexus 结果

编辑 runtime symbol 前对上游入口运行 impact：

- `CjguiInternalRendererNoNativeTokenTableImplementationReadiness`：`UNKNOWN / not found`。
- `cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft`：`UNKNOWN / not found`。

按近期新增 owner 未索引记录。本轮继续用源码、probe、`cjpm build` 与 forbidden scan 兜底，未忽略 HIGH / CRITICAL 风险。

## 同形边界刹车

不得把 token table shell、token classification、capacity facts、token ownership hardening 或 smoke evidence 包装成 resource table permission、native handle permission、native object permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。Token table shell 只定义 bridge-local no-resource token mechanics，不证明 resource exists。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-resource token table shell first implementation 已完成。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeTokenTableShellReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 新增为 `runtime_renderer_native_token_table_shell.cj`；truth 限于 invalid / capacity / enabled / classification observed facts；stop-line 继续禁止 issue / revoke、resource table、native object、pointer、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table no-resource issue/revoke preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
