package cjgui

// P1 minimal app/window lifecycle runtime skeleton.
// 日期: 2026-04-26
//
// 本文件当前只承载一个默认 internal 的 compile sanity marker,
// 一个默认 internal 的 error facts boundary type, 以及边界说明注释。
// 它不定义 stable error API。
// 它不实现 runtime errors。
// 它不定义 error enum、Result type 或 exception-like mechanism。
// 它不迁移 smoke last_error。
//
// 内部 compile sanity marker:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只验证 package cjgui 可以承载非 public symbol。
// - 它不是 error type、lifecycle type、handle type、runtime API、
//   public C ABI 或 behavior surface。

struct CjguiInternalCompileSanityMarker {}

// 内部 error facts boundary type:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它是本 package 中第一个最小 semantic runtime type。
// - 它只标记未来 internal error facts boundary。
// - 它携带一个脱水 Bool fact: 不存在 native payload。
// - 它不是 error strategy implementation。
// - 它不是 error enum、Result type、exception-like mechanism、
//   public runtime API、public C ABI、handle type、platform object wrapper
//   或 behavior surface。

struct CjguiInternalErrorFact {
    let hasNativePayload: Bool = false
}

// 内部 error taxonomy marker:
// - 这是普通顶层 struct, 使用默认 internal 可见性。
// - 它只标记 taxonomy 边界存在。
// - 它同时标记 taxonomy 尚未定义。
// - 它没有字段、函数、方法、显式 init、import 或行为。
// - 它不是 error enum、Result type、exception-like mechanism、
//   public runtime API、public C ABI、diagnostics truth system 或 smoke
//   last_error migration。

struct CjguiInternalErrorTaxonomyMarker {}

//
// 错误策略 owner (Error strategy owner):
// - 未来 ownership 属于 runtime/cjgui error strategy 模块。
// - owner 负责分类 failures 与 degraded diagnostics。
// - owner 不得变成 app state、window state 或 platform truth。
//
// 与 app lifecycle 的关系:
// - app lifecycle 拥有 run、quit、shutdown、main-thread queue acceptance 等
//   app-level policy。
// - error strategy 可在 app lifecycle 上报后, 对 app-level fatal、
//   recoverable 或 degraded outcomes 做分类。
// - error strategy 不得实现 run、shutdown、request quit、queue 或 drain 行为。
//
// 与 window lifecycle 的关系:
// - window lifecycle 拥有 created、closing、destroyed、stale target 与未来
//   window identity 等 target state。
// - error strategy 可在 window lifecycle 上报后, 对 create、request-close、
//   destroy、release、stale handle 与 stale message failures 做分类。
// - error strategy 不得实现 window create、request close、destroy、release、
//   handle table、generation 或 multi-window targeting。
//
// 与 platform adapter 的关系:
// - platform adapter 拥有 native failure details 与 platform capability facts。
// - core error strategy 只能接收脱水 failure summaries。
// - platform object pointers、raw events、native handles、callback ownership
//   与 runloop truth 不得成为 error API surface。
//
// smoke last_error 不迁移:
// - smoke last_error 只是实验性 evidence。
// - 它不得扩展成长线 concurrent error system。
// - 未来 runtime errors 必须是 call-associated、structured、non-global 且
//   concurrency-safe。
//
// 未来最小分类词表:
// - fatal: 当前 lifecycle path 已无法安全继续。
// - recoverable: caller 或 lifecycle owner 可在收到 structured failure 后重试
//   或选择替代路径。
// - degraded: 系统继续运行, 但明确记录 reduced evidence 或 reduced capability。
// - invalid usage / contract violation: caller 破坏了已冻结 contract。
// - platform capability missing: platform adapter 报告所需 capability 不可用或被拒绝。
// - stale handle / stale message: target 已被销毁、替换, 或不再接受该 message。
//
// 失败关闭策略 (Fail-closed policy):
// - unknown ownership、stale target、invalid lifecycle ordering、denied capability
//   与 ambiguous native failure 应 fail closed。
// - failure 不得被静默吞掉, 除非它被明确分类为 degraded diagnostics。
// - diagnostics 可以支持 evidence 与 closure review, 但 diagnostics 不是第二个
//   state truth source.
//
// 公共 surface stop-line:
// - 不提供 public runtime API。
// - 不提供 public C ABI。
// - 不定义 error enum。
// - 不定义 Result type。
// - 不定义 exception-like mechanism。
// - 不冻结 stable function signature。
// - 不创建 package 或 build entry。
// - 不复用 smoke C ABI。
// - 不暴露 platform object。
// - 不做 Renderer / Scene / Widget / Layout / DSL。
// - 不做 global tick、Dirty Rect、frame scheduler、Text / Input / IME /
//   Accessibility、semantic tree、Action Router、command-list hash、pixel
//   diff、baseline 或 offscreen renderer。
