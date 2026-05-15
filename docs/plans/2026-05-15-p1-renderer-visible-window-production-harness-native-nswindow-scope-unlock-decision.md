# P1 Renderer 可见窗口生产 Harness 原生 NSWindow 范围解锁决策

## 决策

本轮从 tracker、README、plans index 与 topic manifest 重新读取到唯一 next opening：

`P1 internal Renderer visible-window production harness native NSWindow harness scope unlock decision`

report-4 已由人工复核确认，不再阻塞当前自动化。范围解锁结论为：允许进入 production native bridge 内部的 token-backed `NSWindow` harness first slice，并要求同轮继续完成 native NSWindow harness preflight。该解锁只覆盖固定容量 table、opaque token、main-thread create / destroy、classify、stale / double-destroy fail-closed 与 still-blocked facts。

## 允许范围

- 允许修改 production native bridge `.h` / `.m` 的窄 C ABI。
- 允许新增 runtime internal FFI owner。
- 允许新增 native probe 并更新既有 native guard allowlist，使旧 guard 表达新的 `NSWindow` harness 边界。
- 允许同步 README、tracker、plans index、runtime README、设计意图索引与相关 topic manifest。

## 停止线

- 不调用 production `nextDrawable`。
- 不 `present`，不 `commit`，不执行 render。
- 不创建 render command encoder，不绑定 pipeline 或 vertex buffer，不 draw。
- 不写 renderer state，不修改 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不新增 public API / public diagnostics。
- 不返回 native pointer / handle / `id` / `Class` 到仓颉 public surface。
- token 不使用 pointer cast。
- probe evidence 不得升格为 production runtime truth、backend-ready truth、render permission 或 GPU submission permission。

## 设计意图出口自检

- owner 已限定为 internal runtime owner 与 production native bridge 内部 C ABI。
- truth 只允许脱水 integer facts 与 opaque token lifecycle facts。
- stop-line 明确保留 drawable / color attachment / encoder / present / render 阻塞。
- Same-shape Boundary Brake：scope unlock 不是 renderer state write、backend-ready、render-ready、GPU submission 或 public API permission。

## 下一步

继续同轮 native NSWindow harness preflight；若 preflight 通过并未触发硬停止，继续实现 bounded first slice。
