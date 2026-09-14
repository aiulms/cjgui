# 大阶段：自适应组合布局与测量复用

2026-09-13；原执行任务 Terra/xhigh、原目录。指导负责取舍和复核，执行负责完整实施。

## 目标与取舍

让应用开发者通过仓颉组件组合构建能随窗口、文字和动态内容变化的布局，不靠逐页固定尺寸补丁。沿已有 composable_ui、窗口失效/调度、真实字体测量、层宿主、虚拟集合和 normal application host 推进，不重造布局/业务状态 owner，不复制 CSS 或 GPUI 全接口。

六主线判断：组件布局已有 row/column/min/max/grow 初版但约束分配存在具体缺口，优先修正并交付可复用组合与成本证据；渲染/GPU、资源调度已有提交/空闲基线，本阶段验证布局变化的实际成本；文字阶段接受范围布局和无变化属性失效修复，100KB 多段尾部约71ms、单段约77–79ms仍为限制；语义动作和正常包已有真实接续，本阶段验证布局变化不改变身份/权限。物理IME/VoiceOver独立待验，桌面可用时补适用场景，不能阻塞无关代码。下一候选为渲染资源与局部提交效率，依据本轮测量决定。

历史依据为 DESIGN_INTENT_INDEX 的组件/布局入口、gui-framework-pitfalls-intelligence 的布局状态归属与盲目重绘教训：测量不能修改业务，派生缓存必须能丢弃重算，绘制/命中/AX使用同一最终布局；旧 opening 禁令不恢复。

## 完整实施范围

1. 复现并修正约束求解：当前 layoutHorizontal 向 crossAxisLength 的垂直计算传入 width，拉伸高度因而可能以宽为准。明确“用于文字测量的已分配宽度”和“可用高度”两个量。覆盖嵌套行列、自然高度、换行文字与跨轴 start/center/end/stretch。distributeGrowth 在子项 max 饱和后需继续分配给可增长项，整数余量稳定处理；收缩规则明确，固定/min约束不可悄悄破坏，空间不足有一致裁剪/溢出行为。先建立真实失败样例，再调整通用算法。
2. 在现有组件 API 内完善可复用自适应组合：窄/宽窗口的工具区、内容区、侧栏及长标签表单无需 native 业务分支。必要公共 API 增量保持 experimental、兼容已有调用，不为了样例引入专有节点。优先完成现有约束语义，不同时扩完整 grid/富文本/动画系统。
3. 测量与求解成本一起收敛：统计真实 measurer 调用及递归求解工作量，消除同次布局重复测量；若跨次缓存确有收益，以内容/样式/宽度/测量器身份或代际等完整依赖键、有界容量与明确失效实现。不缓存第二份可写树，不要求开发者手动维持隐藏脏标记；字体/宽度/内容变化准确重测，无关局部变化不引发可避免的全篇文字测量。保留无缓存参考求解用于差分校验，而非新增运行时双状态机。
4. 两个不同正常应用消费：复用现有规则与文档或独立消费者，至少一个具有嵌套自适应面板、长标签、动态插删/显隐、层和滚动。更换窗口尺寸/字体后布局、命中、焦点、选区、层锚点与AX对应同一稳定对象；外部授权写入仍走已有 owner，布局变化不得扩大权限或让旧事件串绑。
5. 独立消费由执行安排 Luna/Terra 只按公开说明构建/调整一个正常消费者并实际运行、操作、读回；禁止把执行者自己的探针称为独立消费。无需新建用户侧任务，使用有边界的子代理；原目录独立写集不覆盖他人改动。

## 验收与回报

以最终分配矩形、约束不变量与缓存/无缓存差分为主，覆盖小窗口、饱和max、固定项、余量、嵌套换行、动态树和重复resize；不能只断言实现内部计数。相关 native/controller/布局测试、公共声明/跨模块影响、core/root build 与 diff 检查按风险一次收口。

在正常宿主获取可重复的 resize、局部内容变更、字体切换、无变化空闲成本；区分 build/layout/measure/submit、总延迟、CPU/RSS和缓存收敛。固定测试规模不超过已声明 native 容量；大数据复用虚拟集合，不静默截断。比较相同负载与测量条件，不能只靠缓存命中率宣称高性能。保持文字已验路径无回退，尾部已知成本不要求本阶段清零。

最终两个应用构建和公开操作/读回、实际布局交互；真实桌面输入与程序化原生事件分别标记。锁屏跳过物理验证，不重试解锁、不改设置。只在生产最终变化后重建验收产物，不每个实验重跑全部。完成约束正确性、复用消费和成本整组交付后回报；重大正确性/架构取舍即时升级，并继续独立工作。

按 AGENTS 保持两次失败后只读 K3/指导诊断规则，已有环境无响应不无限重试。无 worktree/切分支/stage/commit/push/发布。更新现有 ACTIVE 与本页交付区，主动回报指导任务 01a08f0f-e1ce-71c1-9a6e-4eee08308d61。

## 交付区（2026-09-13）

指导复核后的两项缺口均已收口；以下记录区分源码、探针、正常宿主、AX/人机操作和仍未验证的呈现边界。

### 完成内容

- `distributeGrowth` 现在会在某个可增长子项触及 `max` 后把剩余空间继续按增长权重分给尚有容量的子项；无法整除的像素按声明顺序稳定分配。固定尺寸和最小尺寸不被收缩逻辑改写，空间不足仍沿既有父裁剪/溢出路径处理。
- 横向容器把行的可用**高度**与子项的已分配**文字测量宽度**分开传递：`stretch` 以高度填充 cross axis，自然高度仍按宽度换行。以行/列、嵌套换行、cross-axis start/center/end/stretch、无 fixed height、min/max、饱和 `max`、固定项和小视口的最终矩形作断言，未为示例加入页面专用布局分支。
- `CjguiComposableUiLayoutEngine.layoutWithMetrics` 作为 experimental 的只读结果入口，返回同一 canonical scene 和本轮 metrics；普通 `layout` 仍保持既有 API。每次 layout 只在本轮以完整文本/样式/可用宽度键复用测量，容量 1024，结束即可丢弃；`reuseMeasurements: false` 提供无缓存参考求解，未新增可写布局树或跨轮隐藏脏状态。
- 外部只读 projection 追加 `WINDOW_WORK_TIMING_MS`（最近一次 build/layout/native measurement/native staging+present）与 `WINDOW_MEASUREMENT_CALL_COUNT`。它们以毫秒为单位，`0` 表示低于该分辨率或该阶段未发生，不作为总延迟、GPU 完成或人工呈现声明。
- 规则集 normal app 的列表/详情区采用 `min/ideal/max/grow`，文档 normal app 的虚拟列表和可换行编辑区构成可伸缩的嵌套工作区；二者保留原有稳定节点、层、滚动、owner 和权限路径。

### 验证结果

- 先在旧分配逻辑上复现垂直与水平 `max` 饱和后剩余增长空间未再分配、嵌套文本重复测量，以及 `300×100` row 中 `fixedWidth=80` 且 `alignY=STRETCH` 子项错误得到 `80×80`（应为 `80×100`）。修正后 `verify_composable_ui_layout.sh` 通过；stretch 的无 fixed height、min/max 和嵌套换行均覆盖。相同动态树的缓存/无缓存 canonical geometry 完全一致：18 次测量请求从 18 次基础 measurer 调用降至 7 次，11 次复用命中，递归节点数为 5；宽度或字体变化会重新测量。
- `verify_composable_ui_window_controller.sh` 通过，并在真实 native window/controller 路径观察到字体切换前后测量计数 `3 -> 4`。`verify_composable_scene_renderer.sh`、`verify_macos_application_host_runner.sh` 均通过；前者的 Metal readback 是渲染探针，不等同人工视觉验收。
- `shared_operation_core` 在 macOS 15.4 SDK 下 `cjpm test --no-color` 为 40/40（含诊断字段传输红测后绿），`runtime/cjgui` 的串行测试为 5/5，`cjpm build --skip-script` 通过。仓库根目录没有 `cjpm.toml`，故根目录 build 不适用；两个 normal app 最终 bundle 都以其 `run.sh --build-only` 成功重建。`git diff --check` 和相关空白扫描均通过。GitNexus 未索引 `CjguiComposableUiLayoutEngine`，以源码、探针、构建和运行时验证补足图覆盖缺口。
- 最终 normal host 中，规则 owner 创建“自适应布局验收规则”后读回 `recordCount=1` 和稳定 `selectedRecordId=1`，scene/submission/Metal/overlay 代际均由 1 到 2；文档 owner 的 `REPLACE_RANGE` 读回新增“【自适应】”，文档版本和四类帧代际同样由 1 到 2。规则窗口在已解锁桌面呈现正常 AX 树及更新后的字段/按钮；这是 AX/公开操作证据，不宣称已完成物理鼠标、中文 IME、VoiceOver 或人工像素验收。
- 重建后的规则 normal app 在 5 秒预热后以 CUA 先点击“菜单”与“外观/字体”，再点击“新增”，最后实际拖拽右下角将 native drawable 从 `1960×1240` 缩至 `1564×948`。AX 状态确认等宽字体状态和“新规则 1”；公开读回显示三次刷新使 frame/work counts 到 `3/3/3`、`4/4/4`、`5/5/5`。三轮最近 work timing 分别为 `0/6/4/5ms`（18 次 native measurement）、`0/0/0/1ms`（3 次）和 `0/0/0/6ms`（2 次）。resize 的 native readback 同时报告非致命 `scene_color_mismatch`，故截图/AX不被当作像素正确证明。
- 独立 Luna 消费者只依公开 README 和 normal-host 文档构建运行，动态发现 descriptor 后调用 `GET_CONTEXT`、`GET_WINDOW_PROGRESS` 和 `SET_MARKED`，读回 `isMarked=1`，并观察 scene/submission/Metal/overlay `1 -> 2`。它从 `/tmp` 启动并在关闭 host 后确认 endpoint 拒绝请求；其一次 CUA “刷新领域状态”点击未产生额外可观察变化，未把该点击记为功能证明。

### 成本样本与边界

- 保留早期 5 秒零 warmup 基线作历史样本；最终工作负载报告为 `/tmp/cjgui-adaptive-layout-normal-host-workload-v3.json`：每 cycle 先由 app 自报 5 秒 warmup，随后 20 秒每秒采样，100 条可写 fixture 在同一 normal host 中创建、批量更新、冲突验证和稀疏读回，workload 为 full/targeted `1942.972ms / 1954.071ms`，并各有 18 个、约 `17.65s` 的同进程 idle-recovery 样本。full-context 与 targeted-context 读取均承载同一 fixture：full 170 次，p50/p95 `12.770/23.648ms`、44,454B；targeted 166 次，`11.642/22.671ms`、6,817B。最终 work counts 分别为 `102/102/101` 与 `103/103/102`，均远低于读取次数，并只随业务变更的合并刷新推进；只读轮询没有按自身次数追加提交。
- recovery 中 full 的 CPU `4.9% -> 4.4%`（min/max `3.6/5.3`）、RSS `+176KiB`；targeted 的 CPU `4.0% -> 3.3%`（min/max `2.2/4.0`）、RSS `-96KiB`。这是同负载、不同公开读取范围的可比诊断，不是 layout cache 开关基准；cache-free 几何/调用对照仍由平台无关 layout probe 提供。短样本也不证明长期 CPU/RSS 收敛、局部提交效率或总体高性能。
- 最后一次生产源码重建两个 bundle 后，以 `/tmp/cjgui-adaptive-layout-final-bundle-smoke.json` 对规则 bundle 再跑 1 秒 warmup、5 秒、43 次 full `GET`：p50/p95 `11.666/22.597ms`，work counts 仍 `1/1/1`，最近 timing `0/4/1/77ms`、18 次 native measurement，CPU `2.8% -> 2.0%`、RSS `+1552KiB`。这是最终 bundle 的短 smoke，不替代上面的工作负载/idle 样本。

### 仍未验证的边界

物理中文 IME、VoiceOver、人工像素检查、多显示器 DPI、安装/公证/发布和稳定 ABI 仍未验。CUA 的点击/拖拽是在已解锁桌面送入真实 AppKit 窗口的自动化 UI 操作，不等同用户亲手输入；公开 socket 调用、程序化 native controller 探针和 AX/screenshot 是不同证据，不能相互替代。resize 后的非致命 readback mismatch 更不能被写成画面正确结论。
