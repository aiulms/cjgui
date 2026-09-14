# 大阶段：局部更新的布局复用与稳定性能

## 本轮最终收口：计时、默认策略与核心集成

最终 v4 同进程报告位于 `/private/tmp/cjgui-incremental-layout-timing-v4-final/incremental-layout-reuse-report.json`，probe binary SHA-256 为 `7316e3a68eaac22cb672a7afef8c736ab8f55f831a5ab0192f9fa9ada90d1807`。它在一个进程内预热并交错 canonical-no-cache、显式 diagnostic structural-signature 与生产 opt-in 三种策略，覆盖 6 条件 × 3 行数，每条件每模式 30 个有效样本。Cangjie `MonoTime` 分别记录 build/layout；进程启动、比较、打印、native COW/FFI/Metal 与人工呈现均在计时外。每个 cache 结果随后以关闭本轮 cross-pass cache、保留相同测量缓存的 canonical target 做完整 projection 比较。

760 行的 build+layout p50/p95（ms）为：warm canonical 3.720/3.795、opt-in 3.395/3.484；local 3.771/4.094、opt-in 3.415/3.511；resize 3.762/3.903、opt-in 4.164/4.555；font 3.748/3.823、opt-in 4.176/4.264；full invalidation 3.805/3.972、opt-in 4.220/4.381。显式 full structural signature 诊断在 local 的 p50 为 9.293ms，明显不适合生产默认。结论只覆盖本进程的组件构建/布局：稳定显式区域在 warm/local 减少工作并有可测收益；需要完整失效时不主张收益。

据此生产默认收窄为只复用明确 `layoutReuseKey` 的安全区域。`CjguiComposableUiLayoutReuseCache(allowStructuralSignatures: true)` 仅保留给诊断/实验；无 key 的普通区域走规范布局、不遍历或编码完整结构签名。新 RED→GREEN probe 证明默认无 key 连续两轮命中为零且 projection 与 canonical 相同，显式 key 的两普通消费者仍实际命中并保持失效正确。既有文字测量、变量集合与 native COW 未改变；没有为挽救完整签名另加哈希或第二脏树。

PendingClientRequest 并非源码可见性缺陷：第一次失败是同一 `shared_operation_core/target` 被并行 `cjpm build` 与 `cjpm test` 写入时的临时 module metadata 竞争。避免并行后，完整 core `cjpm test` 串行通过 45/45；没有扩大 internal 类型、跳过或删除生命周期测试。最终生产变更后已重建 runtime 与 rule/document app，并从最新导出副本在含空格路径构建 ui-only/collaboration/document 三消费者；人工窗口、IME、VoiceOver、安装/公证/发布仍为 `not_run`。

## 最新指导复核与立即接续

初版已实现跨轮区域复用及两消费者接线，指导抽查布局缓存、窗口接受边界和原始 JSON，接受已有功能/工作量结论，但尚不接受整阶段完成。以下必要边界与真实收益验证合并继续，不另开阶段：

1. **测量环境属于依赖。** 公共 layoutWithMetrics 接受任意 measurer 与同一个 reuseCache，但 signatureFor 没有 measurer 身份/环境代际。用同树、同 bounds、同 cache，先后提供两种实际不同字体度量的 measurer，与无缓存规范结果比较；也覆盖同实例度量环境改变。由 Terra 明确绑定/代际契约并实现安全失效，不能只说正常窗口目前常用同实例。窗口尺寸/字体/平台度量环境的变化同步遵循契约，不建第二文字引擎。
2. **限制实际保留数据。** maximumSignatureBytes 仅限制签名；显式短 layoutReuseKey 跳过正文编码后，entry.nodes 仍保留 label/value 等字符串与节点集合。以合法显式 key、较大正文及多个候选区域验证 committed 与 pending 的总保留量；增加实际节点/字符串负载和候选阶段预算，超限只拒绝缓存、规范布局仍正确。不将4条目或256KiB签名称为整个缓存内存上限。显式路径也须检查嵌套 scroll/layer 等不可复用后代，不能只检查顶层 kind 后跳过内部可变依赖；短 key 不应绕过框架自己承诺的安全边界。调用者相关业务依赖仍可按清楚的 opt-in 契约声明，不强制每轮遍历所有正文来抵消所有收益。
3. **补全真实成本结论。** 原 JSON 的244097/236949µs是进程启动加12批18种条件的合计，保留为该混合运行的历史结果；fb71486f 是 binary_sha256，不是 JSON 文件哈希。新的性能证据在同一进程内分开计时暖态/局部/全量失效，分别测默认全结构签名与正确显式 key 两种路径；保留原生文字缓存等既有优化。至少每个主要条件30样本并交错参照/优化，报告实际签名访问/字节、求解、重放和保留量，不用递归计数掩盖签名/数组复制成本。两个普通消费者中至少给出实际局部修改的缓存命中及相关阶段工作量，公共CAS通过不自动证明优化生效；若只减少求解但总耗时无显著收益，如实说明并按实际热点调整，不能不断堆缓存。

Terra 负责依赖/预算契约与必要修复，Luna 承接明确的反例、分条件采样和消费者证据工作包；合并完成后一次相关回归和最新导出，不反复重做无关矩阵。当前 GUI 欠项照旧，锁屏继续独立工作。完成或重大阻塞主动报告指导，不在单项修复后停工。

2026-09-14，指导授权原执行任务继续实施。Terra/xhigh 负责方案、正确性与整阶段交付，复用 Luna/high 完成明确工作包；原目录，无新 worktree，无提交、安装或发布。

## 本轮完成记录（2026-09-14）

本轮已把复核提出的边界与性能结论收口，且没有另建内容 owner、文字引擎或 native 缓存。`CjguiComposableUiLayoutMeasurementEnvironment` 是公共 cache 的显式环境契约：没有 key 的任意 `TextMeasurer` 不跨轮复用；fallback、测试环境和 native renderer session 均提供 key，后者按 session 隔离。签名 v2 包含该 key，窗口在 resize/backing-scale generation 改变前重建其 session cache。生产 cache 又默认拒绝无 `layoutReuseKey` 的结构签名；完整 structural signature 必须由诊断调用方显式传入 `allowStructuralSignatures: true`。

`CjguiComposableUiLayoutReuseCache` 的默认上限为 4 entries、1,024 retained nodes、262,144 retained string bytes 与 524,288 retained estimated bytes（签名 bytes 仍单独受限）。候选在 pending 阶段先做节点、字符串与总量检查，commit 时按 LRU 回收后再检查；超过任一边界只记 budget skip 并走规范布局。保留量覆盖每个 resolved node 的所有 retained string 字段、signature、固定标量及 clip constraint 标量。显式 key 的普通区域也递归检查 descendants，内嵌 scroll/layer 或 layer identity 必须留在 canonical 路径；该扫描节点计入 revalidation counter，不把签名工作藏成零。

`layoutWithMetrics` 的 pending candidate 只在 window 的 semantic/native scene acceptance 后 `commitPass`；重复 ID、构建、测量、stage 或 native 提交失败会 `discardPass`。受控 probe 先红后绿地覆盖不同 measurer、同一 measurer 环境改变、30 万字节短 key 输出、嵌套 scroll/layer、候选 pending、拒绝后不晋升及接受后晋升。`verify_composable_ui_layout.sh` 当前通过，输出 `warm_hits=3 local_hits=2 resize_hits=0 font_hits=0 scroll_hits=2 structural_hits=2 eviction_entries=2`。

最终计时报告以 v4 为准：`/private/tmp/cjgui-incremental-layout-timing-v4-final/incremental-layout-reuse-report.json`，probe SHA-256 `7316e3a68eaac22cb672a7afef8c736ab8f55f831a5ab0192f9fa9ada90d1807`。它同进程交错三种模式、6 条件 × 3 行数、每条件每模式 30 个有效样本，并在计时外与 canonical target 比较 projection。760 行 local 时 canonical/diagnostic structural/production opt-in 的 build+layout p50 为 3.771/9.293/3.415ms，递归节点为 769/765/4，重放为 0/4/765。resize/font/full invalidation 都完整求解，且 opt-in 的 p50 为 4.164/4.176/4.220ms，分别高于 canonical 的 3.762/3.748/3.805ms；不把这种失效开销称为收益。

两个普通 bundle 已在最终默认策略下通过公开真实操作读回：`/private/tmp/cjgui-incremental-layout-normal-window-v4-final.json` 中，规则批次在 scene/frame 6 后给出 `WINDOW_LAYOUT_REUSE 1 0 14 14 1` 并通过 batch、sparse target 与 stale CAS；共享文档 `REPLACE_RANGE` 在 scene/frame 2 后给出 `1 0 6 6 1` 并通过范围读回与 stale CAS。它们证明同一业务 owner、窗口完成帧和显式派生 cache 计数链路，不代表人眼可见结果。最终 `verify_framework_preview_consumption.sh` 已从最新导出副本迁移到含空格路径，ui-only/collaboration/document 三消费者构建通过；source/preview payload 都是 `59270f894920aa41f2782aa50dd21250655be363ea4c4d6e9b3e55c5554b33c7`，原始根为 `/private/tmp/cjgui-framework-preview-consumption.a0y9Qx`。本阶段仍未进行人工窗口、IME、VoiceOver 或安装/公证/发布验收，均为 `not_run`。

## 交付目标与取舍

开发者组合一个包含工具区、集合与编辑区的自绘界面；人或外部系统只改其中一个值时，无关区域的派生布局工作可以复用。改宽度、字体、层级或内容高度时，受影响部分仍正确重排，画面、命中、焦点与外部上下文保持一致。交付通用框架能力，并由现有消费者真实使用，不能只交一个优化探针或新增缓存类型。

多窗口阶段的身份、异常恢复、公开定向读取、受控积压进展与最终导出已由指导抽查源码及原始日志，按这些范围接受。人工 GUI/IME、真实呈现仍未验。下一投入转向仓颉组件/布局的局部更新成本：当前 syncProjection 每次实际版本变化仍 buildUi 并进入全树 layout；native 已按未变节点 COW 复用且跳过未变节点 FFI，不应把它重做一遍。

复用 [布局主链](../../runtime/cjgui/src/composable_ui.cj)、[窗口提交](../../runtime/cjgui/src/composable_ui_window.cj)、[文字测量适配](../../runtime/cjgui/src/runtime_renderer_session.cj)。已存在单次布局测量复用、跨轮 native 文字测量缓存（128 项）、变量行高稀疏缓存和 native 场景 COW。先区分这些资产的命中与失效，再定位额外成本；不能宣称此前完全无缓存。旧研究的局部视觉更新与领域写入分工继续适用，不恢复旧研究中的历史禁令，不建立第二内容 owner 或第二文字排版引擎。

## 完整工作范围

1. **建立真实成本基线后落地优化。** 在当前支持容量内选择小/中/大三个有代表性的真实组合树（例如约32/256/768节点，按实际展开后的节点计数），覆盖暖态无变化、单字段修改、兄弟区域不变、尺寸/字体变化、集合滚动与结构变化。记录 build、布局遍历/测量请求/原生测量、字符串转换或 FFI 节点写入、stage/submit 的实际工作量和时间。区分全树构建、求解、比较和纹理成本，不能把少测量宣称成少构建。基线使用当前源码，不借旧文字时延推算。该步骤是实施前定位，不是阶段终点。
2. **跨轮可解释的布局复用。** Terra 根据基线确定最小有效方案：优先复用稳定区域的测量/求解派生结果及改进已有缓存的失效/淘汰；必要时提供实验性、可选的稳定区域或修订标识入口，让现有 controller 可以采用，旧接口继续正确。不要求所有开发者手写脏矩形或 native 对象，不凭指针相等或单一全局版本判断内容相同。不要为了实现增量先重建整个响应式系统。若主要热点在已有缓存抖动，先修真实热点并把正常消费接通，不强制无收益的复杂子树机制。
3. **正确的失效与事务。** 缓存键与依赖必须覆盖实际布局输入：内容、约束/可用宽高、相关样式、子项结构/顺序、测量环境。将局部尺寸与最终坐标/clip/input scope 区分，父布局移动不能复用旧命中坐标。字体、窗口尺寸、变量行高、层显示/隐藏、插删重排和重复ID检查均不能因命中缓存被跳过；只影响视觉的变化不要无故失效所有测量。缓存仅存派生数据且有明确条目/内存界限，长文本大小也计入；场景构建/测量/提交失败后保持已接受场景，失败结果不缓存为成功。关闭或代际切换释放对应状态。
4. **人与外部操作同路消费。** 在现有规则或文档消费者中接入，至少两个不同组合场景验证通用性；不增加备份等业务功能。在多窗口同 owner 模式下，本地事件及一次真实公开 CAS 都只让相关区域重新求解；不相关窗口保持既有空闲行为。最终 window-context、target progress/interaction 与当前布局一致，旧事件不能因为复用误命中新节点。窗口局部选区/滚动不从缓存变成另一份可写 owner。
5. **差异正确性、性能与最终包一起交付。** 复用同一个规范布局求解器，在受控测试中关闭优化作为参照；比较最终几何、顺序、clip、语义和输入目标，覆盖局部变化、祖先变化、结构变化、失败恢复及缓存淘汰返回。保留 native COW 和文字缓存，不用故意清空所有缓存制造对照。固定同一 binary、等量工作、至少每个主要条件30有效样本，计时分辨率足够（低于分辨率如实标明），同时报复用命中/访问量、缓存规模及p50/p95。既要证明局部场景减少真实工作，也要检验全量失效没有明显不可解释回退；不能只用测试数量或0ms作性能结论。

核心改动稳定后一次运行必要回归、根构建和差异/公共声明检查；最终从最新正式导出副本的含空格路径消费，保存 source/payload/binary 与原始日志。不重跑不受影响的1440条文字矩阵。前台可用则将旧中文/集合滚动、多窗A→B及本轮局部修改合在当前普通bundle验证；锁屏跳过前台，不反复解锁或动用户实例。

## 分工与连续推进

Terra 先确定依赖与缓存归属、基线和公共入口，再给 Luna 精简上下文及完整写集（例如消费者/差异回归/成本采样），由它自验；Terra 审关键衔接，不全套重做。性能实现和正确性相互依赖的部分由 Terra 直接处理，不能为分工制造等待。

必要旧问题与本轮新能力一起推进，若发现局部布局优化无收益或需要重大架构取舍，带实际基线和替代思路及时回报指导，继续独立验收，不盲目堆缓存。失败按 AGENTS 累计并升级 K3/指导。整阶段完成立即发送原始证据、真实收益、剩余边界与下一建议给指导任务 01a08f0f-e1ce-71c1-9a6e-4eee08308d61；不要按单个补丁或基线采样停工。
