# GUI Framework Pitfalls Intelligence

日期：2026-04-28

性质：research sidecar / governance review / architecture risk radar

范围：为 CJGUI 后续 runtime / framework opening 提供排雷雷达；不是 execution card，不批准实现，不改变当前 runtime next opening。

## 使用规则

- 本文只记录行业常见 GUI / UI runtime 工程坑及对 CJGUI 的 watchpoint。
- 本文不评价框架优劣，不作为框架对比表。
- 本文不能扩大当前 execution card 的 write set。
- 本文不是每轮 implementation 的默认必读项。
- 只有在开启 event loop / queue / drain、renderer / invalidation / layout、Text / IME / Accessibility、platform handle / public API / C ABI、semantic tree / Action Router 等相关高风险 opening 前，才按需读取对应章节。
- 具体实现仍以当前 execution card、项目文档、已验证 smoke / harness 和本地官方文档为准。

## 1. Event Loop / Main Thread

### Observed Pitfall

- GUI runtime 容易把 nested runloop 当成普通等待机制，导致 modal、menu、drag、sheet 或平台 callback 期间重入应用逻辑。
- callback reentrancy 会让 close、resize、paint、timer、input 在未完成的状态转换中再次进入。
- background task 直接回 UI 线程写资源，短期能跑，长期出现竞态、死锁或平台调用崩溃。
- shutdown / close 生命周期常被拆散在多个 callback 中，最后出现 close 后仍投递 redraw / timer / async completion 的尾部消息。

### Risk To CJGUI

- CJGUI 当前刚进入 internal runtime step；如果过早把 `step` 扩成真实 event loop，可能把平台 runloop 语义写进 core truth。
- macOS smoke 经验可能诱导我们把 AppKit main-thread 规则升级成跨平台 runtime API。
- 如果未来 queue / drain 没有 generation / lifecycle gate，关闭窗口后仍可能消费 stale UI message。

### Current Guardrail

- 当前 opening 明确禁止 event loop、callback binding、queue / drain、app run / shutdown、window create / close / destroy。
- `GUI_GOVERNANCE.md` 要求后台线程 / 协程不得直接写 GUI 资源。
- `GUI_RISK_LEDGER.md` 已登记 macOS runloop / AppKit 事件语义过拟合和主线程独占风险。

### Future Watchpoint

- 在开启 app run、event loop、main-thread queue / drain、callback ingress、window close / destroy 或 async task UI update 前重新检查。
- 任何 nested runloop、modal、timer、deferred task、shutdown drain 方案都应先有 docs-only boundary。

## 2. Rendering / Invalidation

### Observed Pitfall

- 自绘 GUI 很容易从“先跑起来”滑向 global tick / blind redraw，idle 时仍 60fps / 120fps 重绘整窗。
- dirty rect / invalidation 粒度如果没有 owner，后期会在 widget、layout、renderer、platform adapter 间互相甩锅。
- GPU 输出、抗锯齿、字体 raster、颜色空间、Retina scale 和 compositor timing 都会让 pixel hash 非确定。
- screenshot / CI 常被权限、焦点、遮挡、多屏、DPI、headless、timing 影响，容易制造假失败或假成功。

### Risk To CJGUI

- 项目长期倾向 GPU 自绘；如果第一版 renderer 以 frame loop 为默认调度，会背上电池和发热债务。
- 如果 screenshot hash 被当成长期 regression truth，会在 renderer truth 尚未出现前制造第二真相源。
- 如果 invalidation 直接塞进控件或 platform callback，未来 layout / renderer owner 会被反向污染。

### Current Guardrail

- 当前 runtime opening 禁止 Dirty Rect / global tick / frame scheduler、Renderer / Scene / Widget / Layout、pixel diff / baseline / offscreen renderer。
- 风险账本已禁止 global tick / blind redraw 作为默认调度模型。
- frame hash / screenshot 目前只作为 smoke / feasibility evidence，不允许作为长期 baseline truth。

### Future Watchpoint

- 在开启 renderer、frame scheduler、animation tick、dirty rect、display list、command-list hash、pixel diff、baseline policy 前重新检查。
- 第一个 renderer preflight 必须说明 idle 时如何不重绘，以及 render dirty 与 semantic dirty 是否分离。

## 3. Layout / State Ownership

### Observed Pitfall

- retained tree 和 immediate mode 边界不清时，状态可能同时藏在 widget tree、layout cache、render cache 和 platform view 中。
- layout invalidation 风暴常来自“父改子、子改父、measure 触发 state update、state update 再触发 layout”的环。
- parent / child ownership 若没有 clear dispose / detach 规则，容易出现 child 持有 parent、platform object 悬挂或重复释放。
- state 双真相在小 demo 中不明显，到了动画、resize、scroll、focus 时会变成幽灵状态。

### Risk To CJGUI

- CJGUI 想保持 AI-readable / Agent-operable；如果 UI truth 分裂，语义投影、渲染投影和 action target 都会失去共同来源。
- 早期如果为方便把 layout 信息写进 widget 或 renderer，后续 owner 会难以拆开。
- window lifecycle、app lifecycle、runtime root state 已经在内部聚合；未来不能让 aggregate 反过来拥有 app/window truth。

### Current Guardrail

- 项目方向明确渲染永远是状态投影，渲染结果不能自持 UI 真相。
- 当前 runtime root / readiness / bootstrap 文档反复声明 summary / aggregate 不拥有 app/window state truth。
- 当前 opening 禁止 Widget / Layout / Scene / Renderer。

### Future Watchpoint

- 在开启 retained UI tree、layout engine、widget ownership、focus tree、render cache、scene graph 或 diff system 前重新检查。
- 任何 parent / child lifecycle、detach、dispose、layout invalidation owner 都应先冻结边界。

## 4. Text / IME / Accessibility

### Observed Pitfall

- 文本系统常被误判为 `drawText`，实际包含 shaping、fallback、measurement、selection、bidi、emoji、line breaking 和 raster quality。
- IME 不只是最终字符串；preedit、candidate window、cursor rect、selection、scroll、DPI 和 screen coordinate 都要同步。
- 自绘窗口如果没有 accessibility bridge，对 OS 来说可能只是一张不可读图片。
- 过早实现 Text / Input 会拖垮底座；完全忘记接口位又会让后期补洞成本巨大。

### Risk To CJGUI

- CJGUI 自绘路线会天然绕开原生控件提供的文本 / IME / accessibility 能力，后期债务很大。
- 如果未来输入系统只收 committed string，会误写成无法承载 composition 的长期 contract。
- 如果 accessibility 和 AI semantic tree 各造一套 truth，会同时损害无障碍、AI 操作安全和性能。

### Current Guardrail

- 当前统一 stop-line 禁止 Text / Input / IME / Accessibility。
- 风险账本已登记 IME candidate / cursor coordinate、accessibility black box、自绘文本和 semantic projection 热路径风险。
- 项目方向允许预留接口位，但不允许提前打开系统级深坑。

### Future Watchpoint

- 在开启 Text、Input、IME、selection、focus、cursor rect、font fallback、accessibility role / action、semantic projection 前重新检查。
- 第一个 text / IME preflight 必须回答 preedit、candidate position、layout / scroll sync 和 accessibility projection 是否共享 UI truth。

## 5. Platform Abstraction

### Observed Pitfall

- 最低公分母 API 看似可移植，实际会抹平平台能力，并把复杂功能推给上层 workaround。
- native handle 泄漏让公共层绑定某个平台的对象生命周期、线程规则和错误模型。
- platform philosophy leak 会让 AppKit、Win32、Wayland、GTK 等事件 / DPI / window manager 差异渗入 core runtime。
- lifecycle、DPI、scale、multi-monitor、sleep / wake、fullscreen、minimize 的差异经常晚于 happy path 暴露。

### Risk To CJGUI

- 当前 macOS + Metal 是第一平台；如果 core runtime 复用 AppKit callback 名词或顺序，将来跨平台会被迫重写。
- 如果把平台 handle 作为方便的调试出口留给上层，后续 public API 会被锁死。
- 如果桥接层追求“极薄”，平台脏活会穿透进仓颉核心。

### Current Guardrail

- 项目方向要求桥接层向上接口极窄、脱水、标准化、可测试。
- 当前 governance 禁止平台原生对象、native handle、raw pointer 泄露到公共层。
- 当前 opening 禁止接入 AppKit / Metal / Objective-C。

### Future Watchpoint

- 在开启 platform adapter real binding、window handle、capability query、DPI / scale、fullscreen、multi-window 或跨平台 backend 前重新检查。
- 任何 public surface 出现平台名词时都应触发 architecture review。

## 6. Public API Ossification

### Observed Pitfall

- Widget / Layout / Event / Error / Handle API 一旦公开，应用和示例会迅速依赖，后续修正成本很高。
- 早期 API 往往服务 demo，而不是服务真实 runtime owner 和 truth。
- 错误类型、handle lifetime、event payload、layout contract 如果过早冻结，会把实验期判断变成长期包袱。
- internal-only 过久也有风险：若没有出口，会形成只会堆 marker / helper 的治理惯性。

### Risk To CJGUI

- CJGUI 当前仍在 internal runtime step；过早 public 化会把 `ready`、`step`、lifecycle marker 等诊断形态误认成用户 API。
- 反过来，如果 internal-first 没有 clear exit，runtime 可能停在 helper 链而不进入真实 app run / event loop decision。

### Current Guardrail

- README 明确当前不是成熟 GUI toolkit，不提供稳定 public runtime API 或 public C ABI。
- `GUI_GOVERNANCE.md` 已有 Docs Exit / Implementation Bias Rule、Internal Concept Slice Rule 和 Bundled Execution Card Rule。
- 当前 execution card 保持 internal-only，并禁止 public runtime API / public C ABI。

### Future Watchpoint

- 在公开任何 Widget / Layout / Event / Error / Handle / App / Window API 前重新检查。
- 每次 internal summary / helper 增加时，都应确认它是通向下一步 behavior decision，而不是替代 behavior。

## 7. AI Native UI

### Observed Pitfall

- semantic tree 如果每帧维护，会成为 CPU / memory / GC 热点，并与 render tree 分裂成第二真相源。
- action protocol 如果缺少 target scoping、generation、owner gateway 和 permission check，AI 操作会变成后门。
- AI 可见目标若比人类 UI 权限更宽，会破坏产品安全边界。
- 语义投影如果反过来驱动状态，会让 accessibility、AI action、debug snapshot 与 app state 互相污染。

### Risk To CJGUI

- 项目长期目标包含 AI-readable / Agent-operable；这会诱惑我们过早设计 semantic tree / Action Router。
- 如果 semantic tree 在 renderer hot path 维护，轻量 runtime 会被语义成本拖慢。
- 如果 AI action target 直接绑定 internal handle，未来 handle generation / stale target 校验会很难补。

### Current Guardrail

- 当前 opening 明确禁止 semantic tree / Action Router。
- 项目方向规定 AI 语义树只能是 UI 状态真相的投影，不能成为第二真相源。
- 风险账本已登记 semantic tree 热路径性能陷阱和 AI action protocol 安全边界。

### Future Watchpoint

- 在开启 semantic tree、accessibility projection、Action Router、AI action command、target id / handle、automation API 前重新检查。
- 首个 AI native UI preflight 必须定义 owner gateway、permission model、target scoping、generation check、auditability 和 lazy projection 策略。

## Sidecar Summary

- CJGUI 当前最需要守住的是 `internal runtime summary` 不要滑成 `runtime behavior`。
- Event loop、render scheduler、layout owner、Text / IME / Accessibility、platform handle、public API 和 AI action 都是高风险开口。
- 每个高风险开口前都应先回答 owner、truth、projection、lifecycle、verification 和 fail-closed path。
- 本文只提供排雷雷达，不改变当前 runtime next opening。
