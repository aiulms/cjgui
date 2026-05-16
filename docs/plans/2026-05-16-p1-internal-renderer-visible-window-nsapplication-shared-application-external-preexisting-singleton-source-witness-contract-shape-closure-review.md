# P1 Internal Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Contract Shape Closure Review

状态：closure review / contract shape owner checked / no implementation

## Closure 范围

本 closure 复核 external preexisting singleton source witness contract shape 是否只定义
source witness contract 的形状，没有进入 production singleton owner implementation。

已完成：

- contract shape decision。
- value-only owner。
- owner probe。
- external source readiness preflight carry-forward。
- stop-line 继承。

## Closure 结论

可以封账。

原因：

- Owner 只消费
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness`。
- Owner 固定 witness 必须由 external owner 提供，并且必须早于 runtime owner。
- Owner 固定 Renderer creation / accessor call invariant 为 required false。
- Owner 固定 cleanup ownership 由 external source 保留，Renderer cleanup execution blocked。
- Owner 明确 `external_preexisting_singleton_source_witness_truth=false`、
  `external_preexisting_singleton_source_readiness_truth=false`、
  `production_singleton_ownership_truth=false`、
  `production_singleton_implementation_allowed=false`、
  `production_actual_accessor_call_site_allowed=false`。
- Owner / probe 都未新增 public API、native C ABI、runtime state write 或 `cjpm.toml`
  change。

## 风险备注

当前 GitNexus graph 对新增符号仍可能返回 UNKNOWN / not found；该结果不能作为安全证明。
本阶段必须继续用 owner probe、build、forbidden scan 和 manifest reachability 兜底。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness admission policy preflight decision`
