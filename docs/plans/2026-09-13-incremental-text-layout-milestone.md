# 大阶段：增量文字布局与视口效率

2026-09-13；执行原任务01a08f82-b682-73c0-a9b0-25a27bc5ffd8，Terra/xhigh，原目录。

## 目标与依据

把普通多行输入/文档在局部编辑、滚动、选区与候选框定位时的成本控制在实际受影响范围，让长文本不因每次输入重建整篇布局。保留仓颉内容owner与自绘/TextKit平台适配，不改成原生控件应用、不扩富文本/多平台。

前阶段已验证旧FIFO与外部更新交错拒绝、组合态取消、真实owner undo/redo和保守Unicode边界。10,250与102,400 UTF8字节的生产路径测量显示后者owner修改1–2ms，而输入turn首中尾约90/95/152ms。源码multiline缓存按内容key重建，多个ensureLayoutForTextContainer及usedRect全量路径仍在；inputProxy开启non-contiguous不代表绘制缓存、候选定位也增量。

依据[设计导航](DESIGN_INTENT_INDEX.md)、[历史避坑](../research/gui-framework-pitfalls-intelligence.md)文字/失效/状态归属章节。六主线已有基础消费与成本，当前文字布局是明确热点，优先于新增组件数量。前阶段物理IME/VoiceOver和独立AI实际人侧消费仍未验；独立Luna只读报告是静态契约复核，不转写成运行成功。

## 实现与取舍

- 先把真实一次输入turn分解为proxy编辑、内容差异/owner、测量/布局、候选rect/选区、绘制/提交，保留基线与采样条件。别为测量每帧同步GPU回读。确认缓存创建/更新与隐藏inputProxy是否重复布局同一文字。
- 复用可保持身份的TextKit storage/layout对象，局部内容变更增量更新并传播需要重排的范围；版本、字体/宽度/样式、绑定身份变化正确失效。不能缓存旧文本真相，也不能只更换key却继续每次整篇ensure。根据证据选择TextKit增量失效或受控段落/块索引；不预先要求重写全套shaping，段落边界之外的上下文依赖必须保正确。
- 视口绘制、鼠标命中、光标与选择、候选位置使用一致布局；不要为了获得滚动总高度每次强制布局全文。允许有明确收敛语义的估计/延迟测量，但滚动锚点不能跳、End/搜索到尾部必须准确，选择跨段和外部范围对应正确。超长单段、软换行和多段分别测，不能只挑按行分块的理想样本。
- 缓存有界，编辑历史不能保留每个全文版本和layout；切换文档、删除/换绑/关闭释放或收敛，异步工作若引入则有代际与主线程规则，不后台访问AppKit不安全对象。无变化滚动不得触发业务修改/全量语义编码，无关对象改动不失效当前文字布局。
- 保住前阶段组合/外部冲突/undo与AX语义：布局变化不擅自提交preedit；只读/禁用、旧AX对象、UTF16/UTF8边界都走原规则。平台分段和公共保守边界范围明确，不借优化宣称完整国际化。

## 完整验收

复用前阶段实际controller→owner→native的长文本入口；至少两个现有字节规模，首/中/尾局部插删、连续输入、组合更新、跨行选择、视口内与远距滚动、resize/字体变化、外部稀疏修改和undo。说明字节/字符数量，不混称。包含长单段和多段。足够预热、多次样本，再给p50/p95/max与布局工作量、CPU/RSS、缓存高水位，证明改善来自通用生产路径而非取消验证或缩短负载。

预期在相同100KB场景局部输入有明显可重复改善，普通可见位置不再反复完整排版；尾部首次定位允许披露冷成本，与热路径区分。若主要成本仍线性或无法下降，给根因与下一取舍，不用一个开关宣布完成。稳定连续编辑/切换/恢复观察内存，不能仅给进程首尾两点。

正常文档与至少一个其他多行消费者使用同一实现，公共范围/观察/授权行为回归；两应用最终bundle构建并运行。安排独立Luna/Terra按公开入口实际操作/读回新产物，不能只阅读文档；桌面锁定时可以真实descriptor、已提供的生产路径/AX消费并明确界限，物理IME仍单列。有桌面时补真实输入法和跨行接续，不修改锁屏配置。成本探针不替代真实外部接续。

运行针对性native文本/场景/宿主回归、相关core/client、root build --skip-script与正常应用、diff及跨模块影响检查。索引不足用源码运行补证，不复活Bool治理。以完整布局能力、两消费者、真实成本与接续报告交付，不按一个缓存补丁停工。

## 持续推进

原目录Terra/xhigh，不worktree/分支/stage/commit/push/发布；两次同场景实际修复失败调用确切kimi-code/k3只读讨论，不能把旧错误别名失败算建议。两有效轮仍失败指导给方法；环境故障一次记录，继续独立工作。完整或实质升级回报指导01a08f0f-e1ce-71c1-9a6e-4eee08308d61，更新ACTIVE与本页。

下一候选为控件布局组合能力及无障碍/物理IME剩余验证，依据本轮结果决定，不预定无关扩展。

## 交付区

**状态：本阶段交付完成（2026-09-13）。** 本轮没有把平台文字服务替换成第二个内容 owner；`CjguiTextDocument` 和现有 controller 仍是正文真相。诊断已分离全篇 TextKit 布局、重复几何失效与后续候选/滚动几何；多段普通位置的热编辑已实质下降，长单段与多段尾部的 TextKit range 扩张作为已知限制如实保留。以下是当前工作树的源码、探针和 bundle 证据；安装、发布及物理人侧输入另列为未验。

### 已实现

- 已接入一个仅由 owner 接受的本地 multiline 文本确认标记：同一焦点、同一稳定 identity 且投影值与刚被接受的 event 值逐字相等时，native 复用已 live 的 `NSTextStorage`；任一归一化、外部替换、换焦点、重绑或值不等均回到完整权威投影。此前“本地文本已入 FIFO、随后外部同对象替换”的 probe 被测试关闭路径掩盖；硬化后复现 proxy 没有回到外部基线，现已修复为外部 projection 始终覆盖该未 pump 的旧本地值，而旧 FIFO event 仍按原版本拒绝。
- inactive multiline cache 改为以稳定 component identity、宽度和样式为 key，不再把整篇 value/字节数并入 key；同 key 的外部稀疏更新在保留的 TextKit storage 上替换内容。首次建图仍为完整布局，缓存 LRU 上限 16；本轮真实 probe 的高水位为 4，且 inactive node 外部修改后的两次 overlay draw 没有增加 build count。
- `textDidChange` 不再同步请求活跃 editor 的 caret reveal；native 测量拆为 TextKit mutation、`textDidChange`、selection callback、事件入队和 AX 通知，并增加同配置独立 `NSTextView` 基线。探针 failure path 改为直接非零返回，避免 `window.close()` 使 AppKit 进程以 0 提前结束而吞掉失败；成本模式在正式短交互前经既有 versioned external mutation 恢复同一 controller 的基线。
- 曾试验把 selection callback 的 caret reveal 延后到下一次 draw。它使多段 100KB 的同步 `input` 降至 6–15 ms，却把总 turn 移到随后 `pump`，首/中/尾变为 15/138/302 ms。该实验没有改善端到端成本，已完整回退；当前路径仍在 selection callback 做精确 caret 几何，不把时间窗口移动伪称优化。
- 生产实现已把原先一个含混的“需要完整布局”状态拆成可见 glyph、几何、目标 range、精确内容高度与滚动锚点。活跃输入、命中、绘制、caret reveal 和候选框共用**同一** `NSTextStorage`/`NSLayoutManager`/`NSTextContainer` 图；普通可见范围只请求 character/bounding range。只有越过已实现末端、必须精确钳制到 End 时，滚动路径才显式请求 container 全量布局。每个请求在 probe 中分别计数，避免把换名字当优化。
- 长文本的远距候选框曾落在自绘视口外；候选 rect 现先以目标 character range 完成布局并把该位置揭示到同一滚动锚点。probe 在 100KB 尾部确认候选框仍被映射到 multiline 节点内；没有添加第二套 TextKit 图或绕过正文 owner。
- `positionInputProxyForNode` 现在逐项比较 parked scroll frame、maximum lines、line break、container size、height tracking、min/max size、frame 与 font；相同值不再重写。红测先证明：一次尾部编辑后的普通视口滚动虽然没有业务改变，却因 18 次相同值写入把 `firstUnlaidCharacterIndex` 从 90,113 归零，bounding-range ensure 达 1,513,625µs。修复后该滚动保持 90,113、bounding ensure 为 0µs；候选路径亦为 18 个 no-op、0 个变更。连续输入测试辅助函数也只在未聚焦时才真正 focus，避免测试自身制造第二次几何重置。
- 仅测试观测记录每个 character/bounding ensure、glyph-index/line-fragment/location、候选、reveal、proxy 写入及 `firstUnlaidCharacterIndex`；没有泄露原生对象或改变 owner。SDK 的 `NSTextStorageObserving` 可公开给出 actual invalidated range，但把 observer 挂到当前 Cangjie/AppKit 边界会稳定触发 `SIGBUS`，故已移除该连接，trace 明确标记 `sdk_actual_invalidation=not_bound`，不把调用次数冒充实际失效范围。现有安全观测足以区分 range ensure 自身扩张与其后几何查询：尾部 100KB 编辑时间在前者，后者为 0µs。

### 当前成本证据

主报告使用最终二进制的 `--steady-cost`：三新进程，100KB 文本的每个形状/位置先进行 5 对真实 native 插入/删除预热，再记录 30 对，故每 action/位置为 n=90。每条原始记录包含 UTF-8 bytes、UTF-16 选区、`input → owner → pump` 的端到端时段、mutation/selection delegate 及所有 range trace。`input` 为 `insertText`/`deleteBackward` 及其同步 delegate，`turn` 包含随后的真实 owner 和一次 pump；并未把进程首次访问叫作中间或尾部热样本。

| 100KB 文本 | 固定位置热 input p50/p95 | 固定位置热 turn p50/p95 | 结论 |
| --- | --- | --- | --- |
| 多段，start insert / delete | 2/2 ms / 2/2 ms | 7/8 ms / 8/8 ms | 普通首部局部编辑稳定；owner p50 1–2ms。 |
| 多段，middle insert / delete | 6/7 ms / 2/2 ms | 9/10 ms / 6/7 ms | 同一中间位置不是冷启动。 |
| 多段，tail insert / delete | 71/73 ms / 0/0 ms | 74/76 ms / 2/3 ms | tail insert 的 selection range ensure 持续线性；删除后复用已实现范围。 |
| 单段，start insert / delete | 78/80 ms / 78/80 ms | 82/83 ms / 81/83 ms | 单一软换行段落仍持续高成本。 |
| 单段，middle insert / delete | 77/78 ms / 76/78 ms | 81/82 ms / 79/81 ms | 不是只发生在首次访问。 |
| 单段，tail insert / delete | 79/80 ms / 0/0 ms | 82/83 ms / 3/4 ms | tail 插入仍需完整段落的 caret range；此轮最大 turn 为 85ms。 |

历史对比单列：最终 `--cost` 仍保留三新进程 × 首/中/尾的 9 个点，100KB 多段的混合分布为 input 7/71/71ms、turn 10/74/74ms，单段为 input 76/78/78ms、turn 80/81/81ms（p50/p95/max）。这 9 点跨位置，不能描述为“中间热点 p50”，也不替代上表的固定位置热样本。两类普通窗口首编辑 `--cost-cold` 另在三新进程运行，记录在 `/tmp/cjgui-range-layout-final-cold-{multiple,single}-{1,2,3}.stdout`；其首/中/尾位置与稳定热样本不混算。

- 当前 trace 的因果边界是明确的：尾部多段 insert `input_mutation_us≈74,875`、selection callback `≈71,166`，其中唯一 character ensure 也为 `≈71,166`；tail candidate 之后两个 character ensure、line/glyph 查询、reveal 与 candidate 都为 0µs；普通 viewport scroll 的两个 bounding ensure 亦为 0µs，且 proxy 的 `firstUnlaid` 保持 90,113。由此不能把尾部成本归咎于候选、锚点、hit 几何或同值 proxy 重写。
- 这组稳态 action 每次都走真实 `input → native delegate → Cangjie owner → pump`：每个位置 35 对 insert/delete，丢弃 5 对预热后仍要求内容 size 复原、70 个 owner text event 与 70 个 document version；没有把三键或多次事件伪称为合并写入。常规 `--cost` 的每组三次编辑也仍为 `build_delta=3 / layout_delta=3 / submit_delta=3`，这是投影工作量，不是“零布局”声明。
- 独立 `--visible-layout-baseline` 以相同 942pt 宽度、word wrap、初始 viewport 和插入后 caret 的 character/glyph/line query 运行三新进程（每位置 n=30）；它的 standalone mutation p50 为多段 start/middle/tail 78,667/78,458/76,958µs、单段 start/middle/tail 78,000/76,416/1,084µs，post-insert caret query 接近 0µs。与活跃控件的热序列明显不同，说明这个对照的 native view 生命周期/缓存状态不等价；它只证实可见目标形状，不做加减，也不据此宣称单段成本是“平台固有限制”。旧 `standalone_fully_laid_mutation_us` 已重命名以防被误读为可扣减基线。
- `--cost-cold` 与 `--cost-cold-single` 的三新进程首编辑已在当前源码后重跑并保留原始日志；它们只回答普通窗口第一份 100KB 文档的第一轮路径，不与上述位置热样本合并，也不代表整个进程启动时间。
- 已构建 probe 的非侵入 `ps` 轮询记录每进程 34 个样本，峰值 RSS 为 196,592–203,168 KiB（约 192.0–198.4 MiB）、峰值 CPU 为 100.5–100.9%。`sample` 会暂停主线程并令候选框 probe 超时，故不用于产品资源或通过结论。
- 当前结论是：多段同位置热编辑、选择、候选和普通视口滚动已走一张 range-layout 图，且可避免的相同值 proxy 失效已经移除；远距 End 仍允许准确性优先的显式全量布局。多段尾部及超长单段的 range 请求仍可线性扩张，但证据尚不足以决定重写排版。若未来多段热尾部仍是持续性瓶颈，先在现有阶段说明输入法全局范围映射、跨段选择、字体/宽度失效和滚动锚点条件，再评估受控段落索引；公共契约不能保证时回报，而非预先锁死方案。

两条错误方向均已完整撤回：直接操纵 proxy `NSTextStorage` 的方案把 100KB 输入恶化到约 150 ms；共享第二个 TextKit layout graph 的方案在正常行为通过后，10KB cost 首次插入触发 Bus error。当前没有遗留它们的生产代码。阶段要求的 K3 只读咨询已以确切 CLI 和 `kimi-code/k3` 启动，提示词被接受但约 120 秒内没有返回咨询内容；没有把它伪称为建议或据此修改源码，也没有改用其他模型重试。

### 验证及边界

- 当前源码：core `cjpm test --timeout-each 30s` 40/40、runtime `cjpm test --timeout-each 30s` 5/5、CJGUI 项目根 `cjpm build --skip-script`、native `--cost`/`--cost-cold`/`--cost-cold-single`/`--diagnostic`/`--steady-cost`/`--visible-layout-baseline`、scene renderer、window controller 和 macOS host runner 均通过；`git diff --check` 通过。构建仍报告既有 `chmod` 与 `allowedFileTypes` deprecation、probe 中已有 unused warnings；本轮没有把 warning 静默为成功。工作区顶层不是 cjpm 项目，曾对其执行的 `cjpm build` 因缺少 `cjpm.toml` 退出 1，不计作上述项目构建失败。
- 当前源码 bundle：共享文档与规则集的 `run.sh --build-only` 均在最后 native 源改动后重建，均显示 `native_archive=rebuilt`，保留 `allowedFileTypes` deprecation 警告。
- 最终 bundle 的公开运行：`window_perf_baseline.py` 通过动态 descriptor 启动两份正常 bundle。文档真实完成 `REPLACE_RANGE`、旧版本冲突和 UTF-8 range 读回，version 0→1、后续 submitted/completed Metal frame 1→2、应用 exit 0；规则集真实完成 create、batch、旧版本冲突、定向读回和 sparse change，version 0→3、frame 1→4、应用 exit 0。报告在 `/tmp/cjgui-range-layout-final-normal-window-public.json`；这证明 AF_UNIX 公开接入、实际 owner 写入与正常窗口的完成帧，不是物理键盘、IME 或人眼 GUI。
- 已解锁桌面的补充实窗检查：`CJGUISharedDocument` 显示正常窗口及真实文本字段、撤销/重做/保存的无障碍节点；截图中报错的 `CJGUISharedOperation` 也能打开正常窗口，并暴露 1000–1007 八条记录的选择/勾选节点。该结果是当前实窗及 accessibility tree 观察，不等价于物理中文输入、VoiceOver 朗读或人工像素审阅。
- 已知限制与后续方向：超长单段和多段 tail range 扩张尚未被常数化；是否采用受控段落/视口索引必须由未来多段持续瓶颈的证据决定，并先保证输入法全局范围、跨段选择、字体/宽度失效、End 和滚动锚点。物理中文 IME、候选窗、人眼跨行选择、VoiceOver/DPI、安装、公证、发布和稳定 ABI 均未验。本轮未修改系统解锁设置，也未把程序化 AppKit/AX probe 外推为物理输入。


### 后续取舍

本轮已完成 callback、range request、候选/滚动及原生基线分解；不得回退到直接写 proxy storage 或共享第二个 TextKit graph。若未来继续降低超长单段或有证据的多段 tail 成本，应先定义候选索引/边界及越界 shaping 的正确性条件，再以同一生产入口复验热/冷、远距 End、resize/字体、跨段选择、preedit、外部 FIFO、undo、AX、cache release 和最终 bundle。不能把 range API 的隐式扩张、缩短负载或挪动 `pump` 计时当作完成。

K3 只读咨询已以确切 CLI 和 `kimi-code/k3` 发起；提示词被接受但约 120 秒未返回内容，按环境无响应记录，不虚构建议也不改用其他模型重试。下一方案先用本页的单段数据和代价回报指导；除非有真实证据，不放弃自绘路线或重新引入第二 layout graph。
