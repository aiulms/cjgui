# 仓颉 GUI 项目风险账本

最后更新：2026-05-04

## 用途

本文件记录：

- GUI 框架历史上的常见深坑
- 个人开发者最容易忽略的盲点
- 我们这个仓颉 GUI 项目当前必须长期防守的禁忌

它不是实现计划，而是长期风险提醒。

## Sidecar Risk Intelligence

### GUI framework historical pitfalls

- 入口：[gui-framework-pitfalls-intelligence.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/gui-framework-pitfalls-intelligence.md)
- 性质：sidecar risk intelligence / architecture research。
- 说明：该文档提炼现有 GUI framework / UI runtime 的常见工程坑，只作为排雷雷达，不阻塞当前 runtime implementation，不改变当前 runtime next opening。
- 读取规则：它不是每轮 implementation 的默认必读项；仅在开启 event loop / queue / drain、renderer / invalidation / layout、Text / IME / Accessibility、platform handle / public API / C ABI、semantic tree / Action Router 等相关高风险 opening 前按需读取对应章节。

### AI-native GUI runtime architecture intake

- 入口：[ai-native-gui-runtime-architecture-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/ai-native-gui-runtime-architecture-intake.md)
- 性质：sidecar architecture intake / future risk radar。
- 说明：该文档记录 AI-native GUI runtime 的外部架构提醒，包括 Hard / Soft Cycle、owner 编译期与运行时契约、semantic projection、Action Router、AI intent arbitration、三条生死线、owner 粒度 / cycle driver / Action Router 位置岔路、面向 AI 生成的长期 contract 思路和最小语义 demo。
- 读取规则：它不是每轮 implementation 的默认必读项；仅在开启 semantic projection / semantic tree、Action Router、AI action protocol、controller handle、local state snapshot、Hard / Soft Cycle、input / animation fast path、最小控件 / 声明式 surface、渲染后端选择、AI generation contract / schema 或 AI-native semantic demo 前按需读取。

### AI-native generated UI / semantic UI spec north-star intake

- 入口：[2026-05-15-p1-ai-native-generated-ui-semantic-spec-north-star-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-ai-native-generated-ui-semantic-spec-north-star-intake.md)
- 性质：docs-only north-star intake / future opening registry。
- 说明：该文档把 AI 生成 UI、semantic UI spec、AI-native WYSIWYG、preview / diff / reject loop 和 widget schema capability gate 显式登记为 future radar；它不批准 semantic tree、Action Router 新能力、public DSL、widget generator、AI provider、prompt runtime、preview runtime、renderer implementation 或 public API implementation。
- 读取规则：仅在开启 AI generation contract / schema、semantic UI spec、AI-authored widget schema、generated UI preview / diff / reject loop、AI-native WYSIWYG、public DSL 或 semantic projection gate 前按需读取。

### AI Action Protocol workflow / EDN-like grammar correction note

- 入口：[2026-05-15-p1-ai-action-protocol-workflow-edn-like-grammar-correction-note.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-ai-action-protocol-workflow-edn-like-grammar-correction-note.md)
- 性质：docs-only correction note / future protocol guard。
- 说明：该文档固定 workflow layer 未来只能作为受控 proposal producer / adapter / requestor，不能拥有 UI truth 或绕过 Action Gateway；restricted S-expression / EDN-like grammar 只是未来 data grammar 候选，不批准完整 EDN、macro、`eval`、reader extension、tagged literal、workflow runtime、public DSL、renderer implementation 或 public API implementation。
- 读取规则：仅在开启 AI action protocol grammar、workflow proposal producer、Action Gateway adapter、typed `ActionRequest` surface、audit trail / rollback workflow 或 semantic UI spec action integration 前按需读取。

### AI-native operability / foreign surface risk intake

- 入口：[2026-05-04-p1-ai-native-operability-foreign-surface-risk-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-ai-native-operability-foreign-surface-risk-intake.md)
- 性质：docs-only risk intake / future opening registry。
- 说明：该文档把 physical operability、interaction stability、layout-derived semantic association 和 foreign surface / browser-kernel containment 显式登记为 future openings；它不批准 semantic tree、Action Router 新能力、browser kernel / WebView、layout / hit-test、IME、accessibility 或 public API implementation。
- 读取规则：仅在开启 semantic physical operability、semantic stability / pending gate、layout-derived semantic association、foreign surface / browser-kernel containment、IME cursor rect bridge、accessibility semantic bridge 或 AI action operability gate 前按需读取。

### Cangjie 1.1 owner / tooling / FFI capability intake

- 入口：[cangjie-1.1-owner-tooling-ffi-capability-intake.md](/Users/jiangxuanyang/Desktop/cangjie/docs/research/cangjie-1.1-owner-tooling-ffi-capability-intake.md)
- 性质：sidecar language capability risk intake / future migration radar。
- 说明：该文档冻结仓颉 1.1.0 下 owner 语言保证、debug / profiling / memory tooling、C FFI / platform bridge 和未来语言能力迁移的判断。当前 Owner 边界应理解为“编译期辅助 + 运行时 / 治理契约”，未来若仓颉提供线性类型、move-only resource、borrow / lifetime-like 检查或 resource type，应优先把这些契约下沉到类型系统。
- 读取规则：它不是每轮 implementation 的默认必读项；仅在 owner boundary 进入 public-facing contract、state owner 进入真实 mutable runtime store、FFI handle / native object / platform bridge lifecycle、debug / profiling / memory leak investigation、language feature migration 或 public API / C ABI capability review 前按需读取。

## 一、架构与分层陷阱

### 1. 过早抽象跨平台

典型表现：

- 第一平台还没跑稳，就开始抽象 `Window`、`Renderer`、`Surface`

后果：

- 抽象被第一个平台的偶然性污染
- 后面接新平台时要推翻重来
- 抽象层自己变成负担

当前防守规则：

- 先单平台跑通，再谈跨平台
- 没有真实平台经验，不升公共抽象

### 2. 入口层反逼底层

典型表现：

- 为了让 demo 好看，先设计一套声明式 API
- 再逼着底层去适配这个 API 的想象行为

后果：

- 底层充满 workaround
- demo 的美观程度开始定义真实边界

当前防守规则：

- 入口层只能消费底层真实能力
- 不允许 demo 成为底座真相

### 3. 状态真相和渲染真相分裂

典型表现：

- UI 状态存一份
- 渲染缓存再存一份
- 两边靠回调或事件松散同步

后果：

- 永远搞不清哪个值才是真的
- 高频更新下出现闪烁、残影、幽灵状态

当前防守规则：

- 渲染永远是状态的投影
- 渲染结果不能自持 UI 真相

### 4. 布局被写死在控件里

典型表现：

- 控件内部充满绝对坐标
- 大量 `x + 10`、`parent.width - 20`

后果：

- 控件难以复用
- resize、DPI、字体变化时到处崩

当前防守规则：

- 布局计算必须有独立 owner
- 早期即使不做完整布局，也不能让控件直接绑死绝对坐标思维

### 5. 控件状态机碎片化

典型表现：

- 每个控件都自己发明 hover / focus / press 逻辑

后果：

- 行为不一致
- 后续统一策略、统一无障碍接口会非常痛苦

当前防守规则：

- 控件状态未来应走统一状态模型
- 不能让每个 widget 都变成自己的小王国

## 二、平台与系统交互陷阱

### 6. 把平台原生事件直接泄露给上层

典型表现：

- 直接把 `NSEvent`、`MSG` 之类对象抛给高层

后果：

- 公共 API 被平台绑定
- 事件语义不可测试、不可回放、不可记录

当前防守规则：

- 平台桥接层先翻译事件
- 上层只接框架自己的事件结构

### 7. 低估窗口管理器和操作系统边缘行为

常见地雷：

- 关闭和隐藏
- 全屏和分屏
- 最小化后的绘制暂停
- 跨屏 DPI 突变
- 睡眠唤醒后的上下文失效
- 深色模式切换

后果：

- 正常路径都没问题，但某天在边缘场景突然崩

当前防守规则：

- 正常路径跑通不等于平台层稳定
- 设计阶段就要知道这些边缘行为存在

### 8. 低估 GPU 资源生命周期

典型表现：

- 以为关窗口就等于一切都释放

后果：

- GPU 资源泄漏
- 上下文失效
- 崩溃信息极难读懂

当前防守规则：

- 任何手动创建的非托管对象，都必须提前想好释放路径

## 三、底层物理实现陷阱

### 9. FFI 跨界内存所有权不清

典型表现：

- 仓颉侧拿到平台对象句柄，但没有定义谁释放
- C / Objective-C / Metal 对象生命周期和仓颉 GC 生命周期混在一起
- 关闭窗口、销毁 layer、释放 GPU 资源时没有统一路径

后果：

- GPU / 平台对象泄漏
- 悬垂指针
- 二次释放
- 随机崩溃，且排查难度极高

当前防守规则：

- P1 桥接边界清理必须定义 FFI handle 的 owner、retain/release、destroy 顺序
- 仓颉侧不能长期持有裸指针语义，必须通过受控 handle 访问平台对象
- 任何跨界对象都必须有明确 `create -> use -> destroy` 合约

### 10. 主线程独占与跨线程 UI 写入

典型表现：

- 后台任务、协程、网络回调直接触发窗口或渲染资源更新
- 平台事件循环和应用状态更新没有线程边界

后果：

- AppKit / Metal 调用落到非主线程导致崩溃
- UI 状态和平台状态竞争
- 渲染时序不可复现

当前防守规则：

- macOS 平台事件循环和平台 UI 资源默认归主线程 owner
- 后台任务不得直接写 GUI 资源
- 跨线程更新必须进入主线程消息队列 / channel，再由 UI owner 处理

### 11. FFI 错误边界被过度乐观化

典型表现：

- 假设平台调用永远成功
- C / Objective-C 层直接崩溃或返回非法状态
- 仓颉侧把所有 FFI 调用当作普通函数调用

后果：

- 可恢复错误变成进程崩溃
- 参数错误变成内存错误
- AI 或测试看到的是随机挂掉，而不是结构化错误

当前防守规则：

- FFI 对外入口应尽量返回错误码 / 结果结构，而不是只返回裸成功值
- C / Objective-C 边界必须做参数校验、空指针校验、状态校验
- 不伪称能在同进程内优雅捕获所有 `segfault`；内存错误应通过所有权设计和校验预防
- 未来若确实需要隔离不可控崩溃，应考虑进程隔离，而不是在 GUI 主进程内假装可恢复

### 12. 自动化验证的物理缺失

典型表现：

- GUI 验证长期依赖人类肉眼看窗口
- AI 无法独立判断渲染结果是否为空白、错色或错位
- screenshot 权限或显示环境问题导致验证断裂

后果：

- AI 工作流无法闭环
- 容易出现“说已验证但其实没看见”的假证据
- 渲染回归难以及时发现

当前防守规则：

- P1 之后应逐步探索可自动化的视觉验证路径
- 优先考虑离屏渲染、像素快照、哈希比对或可控截图方案
- 人工视觉确认可以作为补充证据，但不能永远是唯一证据

### 13. “极薄桥接”的厚度错觉

典型表现：

- 为了追求桥接层薄，把 macOS 的复杂事件、DPI、窗口状态直接抛给仓颉核心
- 平台脏活没有被桥接层消化，反而污染上层模型

后果：

- 框架核心被平台偶然性绑死
- 未来跨平台抽象更困难
- 公共 API 被 AppKit / Metal 行为污染

当前防守规则：

- 桥接层目标不是“代码越少越好”，而是“向上暴露的接口越窄越好”
- macOS 脏活可以留在平台层消化
- 向上输出必须是脱水、标准化、可测试的结构，如 `WindowResized(w, h, dpi)`

### 13A. 构建系统与跨平台编译静默腐化

典型表现：

- P0 smoke 一次跑通后，构建脚本长期不再维护
- 仓颉 SDK、Xcode、macOS SDK、libffi、clang 参数任一变化后，构建链悄悄失效
- Metal shader、Objective-C shim、静态库链接、`cjpm` / `cjc` 参数散落在脚本和记忆里

后果：

- 几周后无法从零复现构建
- 新机器无法接手
- AI 只能在旧环境上“看起来能跑”，项目可迁移性变差

当前防守规则：

- 维护 [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)
- 任何 SDK、构建脚本、编译参数、依赖路径变化都必须同步更新从零构建手册
- P1 preflight 必须说明构建链是否可从零复现

### 13B. 错误处理哲学不一致

典型表现：

- 有的模块直接崩溃
- 有的模块吞错继续跑
- 有的模块返回 `null` 或裸错误码
- FFI 层、渲染层、应用层对同一类错误的处理方式不一致

后果：

- 框架行为不可预测
- 可恢复错误和不可恢复错误混在一起
- 调试困难，AI 也难以给出可靠验证结论

当前防守规则：

- P1 preflight 必须先定义最小错误处理哲学
- 至少区分 `fatal`、`recoverable`、`degraded` 三类错误
- 不允许静默吞掉影响状态真相或资源生命周期的错误
- 不伪称不可恢复错误可被优雅恢复

### 13C. 资源限制与降级策略缺位

典型表现：

- 假设所有机器都有足够 GPU / 内存 / Metal 能力
- 渲染管线初始化失败时直接崩溃
- 多窗口、Retina、高刷新率、低端硬件资源压力没有表达方式

后果：

- 框架只能在当前开发机 happy path 上工作
- 用户遇到低端硬件或能力缺失时无法得到清楚错误
- 未来通用性被硬件假设锁死

当前防守规则：

- P1 preflight 必须预留 capability query 的位置
- 渲染初始化失败应返回结构化原因
- 第一阶段不要求软渲染降级，但必须能诚实报告能力缺失
- 不把 `120fps` 愿景写成所有设备的默认承诺

## 四、文本与输入系统深渊

### 14. 把文本系统误以为只是“画文字”

现实里文本系统涉及：

- 字体查找与 fallback
- 文本度量
- shaping
- 换行与断词
- 多语言混排

后果：

- 早期 `drawText("你好")` 看起来能用
- 真到 `Text` widget 阶段时，底层完全不够

当前防守规则：

- `Text` 可以早一点
- 但必须提前定义清楚第一阶段文本能力边界

### 15. 过早打开输入框与 IME

典型表现：

- 事件系统还没稳，就顺手开始做输入框

后果：

- 一下子牵出光标、选区、组合态、候选窗、文本模型、布局度量
- 整个阶段计划被拖进输入法深渊

当前防守规则：

- `Input` 必须晚于窗口、事件、绘制稳定之后
- IME 默认属于升格审查事项

## 五、工程与个人项目陷阱

### 16. 重构时机错误

两种常见极端：

- 永远不重构，最后底座脏到推不动
- 过早重构，真实能力都没跑稳就开始抽象大一统方案

当前防守规则：

- 只为下一刀需要更干净底座而重构
- 不为“看起来更架构化”而重构

### 17. 架构美感瘫痪

典型表现：

- 每一层都想做到完美，结果永远停在最初模块

后果：

- 项目不前进
- 讨论替代实现

当前防守规则：

- 美感是选窄切口的罗盘
- 不能成为不切口的理由

### 18. 盲信单一平台行为会永远不变

典型表现：

- 把当前平台的偶然行为焊死成框架核心抽象

后果：

- 平台一变，框架整体重写

当前防守规则：

- 平台相关部分必须圈养在薄层内
- 不让平台偶然性上升为公共契约

### 19. demo 舒适区效应

典型表现：

- 反复跑熟悉 demo，以为系统整体健康

后果：

- 一离开舒适区就暴露结构问题

当前防守规则：

- demo 只能证明现象
- 后续每个看似稳定的系统，都要找不熟悉的小应用去打破它

### 20. 治理反噬与上下文过载

典型表现：

- 每个小 slice 都留下 preflight / execution card / closure review，历史文档越来越多
- 执行 AI 每轮需要读取过多前置文档
- 旧 policy 与新 policy 出现隐性冲突
- 为了遵守所有历史规则，代码开始过度防御或无法推进

后果：

- 文档本身成为系统复杂度来源
- AI 上下文窗口被治理材料挤满，反而遗漏当前 authority
- 历史结论无法被压缩成当前最小 truth
- 项目速度在进入 runtime / renderer 深水区前被文档负担拖慢

当前防守规则：

- 当前 execution card 永远是本轮局部 authority，历史文档不能无限扩大本轮 scope
- 稳定结论需要阶段性 compaction，未来应开 `governance compaction / truth manifest preflight`
- compaction 只能压缩已有决策，不能发明新能力
- 未来执行 AI 的默认上下文应是当前 tracker / manifest / current card，而不是所有历史文档全文

### 21. 像素哈希和 pixel diff 的确定性幻觉

典型表现：

- 把单次 screenshot hash 当成长期 regression truth
- 在 GPU、字体、颜色空间、Retina scale、抗锯齿和硬件差异未冻结前建立 baseline
- AI 自动更新 golden hash
- pixel diff mismatch 被直接归因为 render failure

后果：

- CI 噪声极高
- baseline 更新变成日常维护泥潭
- GPU / compositor / font / display 环境差异被误判成 UI 逻辑回归
- 测试系统制造第二真相源

当前防守规则：

- 当前继续保持 `hash_value_persistence_allowed=false`、`baseline_allowed=false`、`pixel_diff_allowed=false`
- screenshot / frame hash 只作为 smoke guard 和 feasibility evidence
- 未来进入 render pipeline 前，应单独评估 `render command list / display list hash` 作为更稳定 evidence 的可能性
- command list / display list 也不能提前定义，必须等 Renderer / render truth owner 出现后再开 preflight

### 22. macOS runloop / AppKit 事件语义过拟合

典型表现：

- 把 `NSRunLoop`、`dispatch_get_main_queue`、`NSEvent` 或 Objective-C callback 语义写成 core runtime 真相
- future core API 被 AppKit event loop 驱动方式反向定义
- main-thread queue 的 macOS 单实例 smoke 形态被升级成长期通用 UI message system

后果：

- 后续 Windows / Wayland / Linux backend 难以接入
- 平台偶然性污染公共 runtime API
- event ingress、frame scheduling、input batching 和 lifecycle owner 后期要推翻重写

当前防守规则：

- macOS event loop 只能属于 platform adapter / bridge
- core runtime 不应持有 AppKit runloop truth
- core 层未来只能消费脱水 lifecycle / input / frame step / queue drain 等抽象事实
- `tick` / `step` / input buffer 可以作为 future candidate，但不能在当前 app/window lifecycle slice 里仓促承诺
- 防过拟合不等于提前做跨平台抽象

### 23. AI semantic tree 热路径性能陷阱

典型表现：

- 每帧维护完整 semantic tree
- render tree 和 semantic tree 双轨状态各自缓存 UI truth
- 动画、滚动、进度条等高频视觉变化触发语义树重建
- Agent action 读取或修改语义树绕过应用 owner

后果：

- CPU / 内存 / GC 压力拖垮轻量 runtime
- semantic tree 成为第二真相源
- AI action 获得普通用户不可见或不可操作的后门能力

当前防守规则：

- semantic tree 默认应是 cold / lazy / on-demand projection
- render hot path 不应维护完整 semantic tree
- 未来必须区分 render dirty 与 semantic dirty
- Semantic projection 和 Action Router 必须另开 preflight，不能进入 app/window lifecycle first slice
- AI action 必须经 owner / gateway，不得绕过应用状态真相

### 24. 自绘路线的过度重绘 / 电池杀手风险

典型表现：

- 为了简化 runtime，把 GUI 做成默认全局 `tick`
- 没有 UI 状态变化时仍以 `60fps` / `120fps` 重绘整个窗口
- 动画、输入、resize 和普通 idle 状态使用同一条无差别 frame loop

后果：

- CPU / GPU 空转
- 笔记本耗电、发热、风扇噪声上升
- 轻量 GUI 框架变成高功耗 runtime
- 后续再补 dirty rect / invalidation 时会反向重构核心调度模型

当前防守规则：

- 默认不允许 global tick 驱动全窗口盲重绘
- redraw 应由 event / invalidation / dirty region / explicit animation request 触发
- 任何引入 frame loop 的 execution card 必须说明 idle 时如何不重绘
- dirty rect / invalidation owner 必须另开 preflight，不得在 lifecycle slice 中顺手实现

### 25. 自绘手感与视觉的恐怖谷风险

典型表现：

- 自绘滚动惯性、焦点反馈、selection、文本 raster 和字体 fallback 与原生平台存在细微偏差
- 控件内部直接写死滚动物理、文本渲染策略或平台手感常量
- 早期 demo 看起来可用，但真实应用里“摸起来不对劲”

后果：

- 用户感知质量低于视觉截图能证明的水平
- 后续统一滚动、文本、focus、selection 策略时需要拆控件内部逻辑
- 自绘路线的主权变成长期手感债务

当前防守规则：

- 第一阶段可以接受手感不完美，但不能把手感策略写死在控件里
- 滚动物理模型、文本 shaping / raster backend、focus / selection visual policy 必须未来有独立 owner
- 在 layout / widget 之前不提前承诺具体滚动或文本渲染行为

### 26. IME 隔离导致候选窗 / 光标坐标错位

典型表现：

- 为了避免 IME 状态机，把输入法完全放在框架外部输入区
- 框架只接收最终 committed text
- 用户滚动、resize、跨屏或 DPI 切换后，IME candidate window 仍停在旧的屏幕坐标

后果：

- 输入体验不可用
- 文本模型、layout、scroll 和平台 IME 坐标同步被迫在后期补洞
- “只提交最终字符串”被误当成完整输入系统 contract

当前防守规则：

- P1 不做 Input / IME
- `final committed string only` 只能是 future early isolation candidate，不是长期完整方案
- 未来 IME preflight 必须回答 preedit、candidate position、cursor rect / screen coordinate sync、composition cancel / commit、selection 和 scroll / layout 更新
- 当前只登记 IME cursor rect sync channel 作为 future slot

### 27. 自绘窗口的无障碍黑盒风险

典型表现：

- 自绘窗口对 OS accessibility 来说只是一张不可读图片
- 控件、文本、role、action、focus 和 selection 没有语义投影
- AI semantic tree 和 accessibility semantic tree 各造一套第二真相

后果：

- VoiceOver / screen reader 等辅助技术无法使用
- 后续补无障碍时需要从控件、layout、scene、state 层一起返工
- semantic projection 进入 render hot path 后拖慢 runtime

当前防守规则：

- P1 不做无障碍
- 未来 accessibility 应尽量复用同一 UI truth 的 semantic projection
- semantic projection 必须 lazy / on-demand，不能成为 render hot path 的每帧维护对象
- render dirty 与 semantic dirty 未来必须分离

### 28. AI 动作协议选型错误导致安全漏洞或 token 爆炸

典型表现：

- 让 AI 使用隐式栈协议生成 UI action command
- 使用过度自由的 JSON DSL 表达复杂嵌套 UI 操作，导致 scope / generation / target context 字段遗漏
- 把 S-expression 误当成可执行 Lisp，允许 `eval`、macro 或任意 symbol execution
- action command 字符串绕过 typed AST / ActionRequest / owner gateway，直接触发内部函数

后果：

- AI 从局部操作退化到全局寻址，误操作危险按钮或批量对象
- 指令 token 成本膨胀，长任务上下文更容易丢失
- parser 无法 fail closed，安全审计困难
- Action Router 变成 AI 后门，绕过应用 owner 和人类可见 UI 权限

当前防守规则：

- RPN 不作为 AI-authored UI action command 格式
- JSON 不作为复杂 AI-authored action DSL 的默认首选，但仍可作为 snapshot、debug、IPC envelope、audit log 等普通数据格式候选
- Lisp-style S-expression 登记为 future AI-authored Action Command 的 preferred north-star candidate
- S-expression 只能作为 data grammar，必须 parse 成受限 AST / typed ActionRequest
- 禁止 `eval`、macro、user-defined function、arbitrary symbol execution
- Action Router protocol 必须另开 preflight，不能进入 app/window lifecycle first slice

### 29. AI 物理可操作性绕过风险

典型表现：

- AI 只看 semantic tree 中的 `enabled: true`，不看物理可见性。
- 被 Modal / Overlay 遮挡、在 ScrollView 可视区外、透明或被裁剪的控件仍可被 AI action 调用。
- semantic action target 不校验 hit-test、z-order、clip、occlusion 或 stale generation。

后果：

- AI 获得人类没有的“隔山打牛”特权。
- 业务状态出现人类界面不可能触发的转换。
- 安全、审计和用户信任边界被破坏。

当前防守规则：

- `enabled` 不等于 physically operable。
- 未来 semantic action eligibility 必须引用 layout / clip / z-order / occlusion / viewport / modal / hit-test 的脱水证据。
- physical operability 需要独立 preflight；不得在 semantic tree first slice 中顺手实现。
- Action Router 必须 fail closed：缺少物理可操作证据时默认拒绝或降级，而不是猜测可执行。

### 30. Foreign surface / browser kernel 圈养失败风险

典型表现：

- 为了富文本或 Web 文档能力，把 WebView / browser kernel 当成宿主或主渲染管线。
- 浏览器内核直接拥有窗口、输入事件、焦点、IME 或 semantic truth。
- DOM / accessibility tree 被直接当成 CJGUI semantic tree。
- browser kernel 作为默认依赖进入 runtime，破坏轻量目标。

后果：

- CJGUI 的渲染主权、交互主权和 AI action owner gate 被外部 surface 反向污染。
- runtime 体积、进程模型、权限模型和 IPC failure 复杂度暴涨。
- legacy Web truth 与 CJGUI app truth 形成第二真相源。

当前防守规则：

- CJGUI 不把浏览器作为宿主，不把 WebView 作为主渲染管线。
- browser kernel 只能作为远期可选 `foreign surface` / component / plugin 雷达。
- foreign surface 必须由 CJGUI host / compositor / Action Router / focus owner 圈养。
- future preflight 必须先回答 texture handoff、input proxy、IME cursor rect sync、sandbox / IPC failure、semantic projection provenance 和 runtime weight。
- 不得直接实现 browser kernel integration、WebView widget、Chromium / WebKit embedding 或 DOM semantic bridge。

## 六、当前项目的长期禁忌

以下是当前项目的长期禁忌：

- 在第一平台未稳时做跨平台抽象
- 用 demo 反向定义底层 API
- 把平台原生对象泄露到上层
- 让状态真相和渲染真相双源化
- 过早开启 `Input` / `IME` / 无障碍
- 为了“纯仓颉”拒绝最小平台桥接
- 让 FFI 对象以裸指针语义在仓颉层长期游荡
- 让后台线程 / 协程直接写 GUI 资源
- 把桥接层做得“薄”到平台复杂性穿透上层
- 把人工肉眼验证长期当作唯一 GUI 验证方式
- 伪称所有 FFI 崩溃都能被同进程优雅捕获
- 让构建脚本、SDK 选择、编译参数只存在于个人记忆里
- 各模块各自发明错误处理哲学
- 假设所有硬件都满足高性能渲染路径
- 为了“为爱发电”接受结构性补丁
- 为了“更优雅”跳过真实验证
- 让治理文档无限堆叠而没有 compaction / manifest 机制
- 把 screenshot hash / pixel diff 当成默认业务回归真相
- 把 AppKit runloop / callback 语义写进 core runtime truth
- 在热路径维护完整 AI semantic tree
- 用 global tick / blind redraw 作为 GUI runtime 默认调度模型
- 把“只提交最终字符串”误写成完整 IME / 输入系统 contract
- 因为选择自绘就忽略未来无障碍和 semantic bridge
- 让 AI action command 绕过 typed AST / owner gateway 直接执行
- 把 S-expression 当成 executable Lisp 而不是 data grammar
- 让 AI action 调用物理上不可见、被遮挡、过期或不可 hit-test 的目标
- 把 browser kernel / WebView 升格为 CJGUI host、主渲染管线、input owner 或 semantic truth owner

## 七、每次开工前的风险自问

每次准备推进前，可以先问自己：

1. 这一步是不是做早了？
2. 这一步有没有让 demo 开始定义底座？
3. 这一步会不会让平台细节泄露到公共层？
4. 这一步是不是把未来的大坑提前引爆了？
5. 这一步会不会让结构更乱，而不是更清楚？
6. 这一步有没有定义 FFI 对象谁创建、谁持有、谁释放？
7. 这一步有没有跨线程直写 GUI 资源？
8. 这一步有没有把可恢复平台错误变成进程崩溃？
9. 这一步有没有至少规划一条未来可自动化的 GUI 验证路径？
10. 这一步是在追求“桥接层很薄”，还是在确保“向上接口很窄”？
11. 这一步是否仍能按 `BUILD_FROM_ZERO.md` 从零复现？
12. 这一步的错误处理属于 fatal、recoverable 还是 degraded？
13. 这一步是否假设了过强的 GPU / 内存 / Metal 能力？
14. 这一步是否让治理上下文继续膨胀，而没有压缩当前 truth？
15. 这一步是否把平台 runloop / callback 语义泄露进 core truth？
16. 这一步是否把 pixel hash / screenshot evidence 当成长期 regression truth？
17. 这一步是否让 semantic projection 进入 render hot path？
18. 这一步是否引入了默认 global tick 或 idle 时全窗口重绘？
19. 这一步是否把滚动物理、文本渲染或平台手感写死在控件里？
20. 这一步是否把 IME 的 final committed string 当成完整输入系统答案？
21. 这一步是否让自绘路线忘记未来 accessibility / semantic bridge？
22. 这一步是否让 AI action protocol 绕过 typed AST、validation 或 owner gateway？
23. 这一步是否让 AI 拥有了人类当前物理界面不可执行的 action？
24. 这一步是否把 optional foreign surface 变成了默认 runtime、host、input owner 或第二 semantic truth？

如果这些问题里有 2 个以上答不稳，就应该先暂停，回到治理文档和思考框架。
