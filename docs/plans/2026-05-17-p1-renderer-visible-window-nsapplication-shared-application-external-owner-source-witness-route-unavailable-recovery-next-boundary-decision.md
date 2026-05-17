# P1 Renderer visible-window NSApplication shared-application external owner source witness route unavailable recovery next-boundary decision

状态：next-boundary / alternative route feasibility

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application internal ownership recovery feasibility preflight / no-production-singleton-truth carry-forward decision`

## 原因

external owner source witness route 已由人工确认 unavailable / evidence absent。继续等待或重复书写同构 blocker 不会产生 source witness truth。

下一步应改为 alternative route feasibility：

- 只使用已有 evidence；
- 不新增 `NSApplication.sharedApplication` 调用；
- 不把 throwaway evidence 升级为 external owner truth；
- 不实现 production singleton owner；
- 不升级 source readiness truth；
- 保持 no-production-singleton-truth carry-forward。

## 下一步必须回答的具体缺口

- internal ownership recovery 是否存在不依赖 external owner witness 的可审计 route；
- 该 route 是否只消费已有 evidence，而不触发新的 application singleton accessor；
- throwaway singleton evidence 能否只作为 side-effect / ownership feasibility 输入，而不是 truth；
- cleanup / teardown ownership 是否可在 no-production-singleton-truth 下继续保持外部不可伪造；
- headless / CI-like 场景是否继续 fail-closed；
- 若不能闭合，是否需要把 no-production-singleton-truth 稳定为长期 branch fact。

## 允许范围

- docs-only feasibility preflight。
- internal ownership recovery route matrix。
- no-production-singleton-truth carry-forward decision。
- manifest / tracker / topic manifest 同步。

## 禁止范围

不允许 production singleton owner implementation、新的 `NSApplication.sharedApplication` 调用、activation、event loop、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `cjpm.toml` change。
