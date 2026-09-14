# 大阶段：可靠渲染、资源复用与局部更新成本

2026-09-13，原执行任务 Terra/xhigh、原目录。指导复核后下发，执行连续完成整组能力。

## 目标与旧项承接

沿仓颉组件/scene、Metal矩形图片、TextKit文字、单一窗口scheduler与正常Host，交付不同应用可复用的可靠缩放/资源更新与更低的局部更新成本。复用设计导航中渲染/资源/调度资产及历史避坑的盲目重绘、DPI采样、资源释放、关闭后回调教训，不恢复旧审计链。

接受布局阶段的约束修复、单轮测量复用与消费证据。**成本证据仍有限**：字体/内容/resize各一次真实操作，随后full/targeted查询对照不是布局缓存性能对照；这些限制承接本阶段，不把它们称为重复布局性能验收已全部满足。resize出现scene_color_mismatch尚未归因，必须先判断其是否影响实际渲染正确性，再接受依赖它的优化证据。

六主线取舍：布局与文字已有通用能力，当前渲染正确性及局部提交/资源实际成本是主要未知；语义和正常包继续做消费验证，资源调度与GPU同阶段推进。长文本尾部已知限制不在本阶段重写。下一候选为可复用组件交互与无障碍完整性，由本轮结果决定，不围绕样例业务扩张。

## 完整实施

1. 重现resize后的scene_color_mismatch。核对同一session/scene/frame、逻辑尺寸/backing scale/drawable、采样点、clip、z序、alpha与颜色空间。当前探针按节点中心映射像素并比较预期颜色，中心可能被遮挡或裁剪；这是待区分假设，不是已确定根因。分别构造不透明无遮挡、裁剪、重叠、透明和图片用例，并经正常Host缩放复验。实际绘制错误修生产；采样假设错误修探针并说明其证明范围，不通过扩大容差、关闭探针或忽略返回掩盖错误。不把像素样点当完整文字/画面正确证据。
2. 基于同一正常应用重复resize、局部内容变更、字体切换、图片替换/移除、稳定滚动与恢复idle，记录主线程端到端及build/layout/native-stage/submit，GPU完成单列。每类明确预热与足量样本（建议至少30次），记录运行进程CPU/RSS、资源创建/上传/缓存数量；不能再以只读GET对照代替布局/渲染负载。新WINDOW_WORK_TIMING_MS只是最近工作阶段且可嵌套，native measurement通常包含在layout，不能简单相加为总时延；核对客户端解析与既有授权、缺失值语义，不引入正文/交互泄露。
3. 按实际热点落实可复用优化：相同geometry/style/资源不重复更新；图片内容/尺寸变化正确失效，同一路径替换可见；移除/换绑/关闭缓存与GPU引用有界释放，in-flight资源不能过早回收。对每次scene提交中的重复编码、buffer分配/上传、overlay失效选择有证据的局部复用，完整scene/重建作为正确恢复路径。不要预设必须做复杂dirty-rect或保留未定义drawable内容；记录本阶段最终采用策略及成本改善。至少交付真实重复工作减少和正确生命周期能力，不能仅新增指标后结束。
4. 保住绘制顺序/裁剪/文字命中/焦点/层锚点、外部owner操作/CAS、关闭代际。缓存是派生结果，不另造业务或布局真相，不暴露native handle。native/FFI主线程、所有权和回调有界解释。原schema和容量保持兼容，必要内部修改属本阶段。
5. 两个normal消费者最终实用验证，并由独立Luna/Terra按公开入口验证资源/尺寸变化后的实际操作与读回。桌面可用时补实际窗口缩放/菜单/文本接续；物理中文IME、VoiceOver等没测则保留。锁屏只跳过其依赖，不能重复解锁或修改设置。

## 收口

先定位正确性红项，相关修复和新资源/局部更新能力一起完成；普通旧项不要求清零。相关布局/native/controller/宿主/core测试、runtime build --skip-script、影响/声明/差异扫描及最终两个bundle一次收口。无变更不重跑整套。报告同负载优化前后、样本分布与CPU/RSS/缓存恢复，分清提交、GPU完成、overlay和实际呈现，保留无法可靠测得的字段。

只更新ACTIVE和本阶段交付区；AGENTS两次失败/K3/指导升级规则继续有效，已有CLI无响应不无限等待。无worktree/分支/stage/commit/push/对外发布。完整交付或真实升级立即回报指导01a08f0f-e1ce-71c1-9a6e-4eee08308d61，不按小补丁停工。

## 交付（2026-09-13）

### 正确性与生命周期

- `scene_color_mismatch` 已经重现并归因：通用诊断原本可把节点中心（落在自身 clip 外，或会受较晚 z 序节点影响）当作确定性像素。它不是由容差扩大或关闭读回掩盖。现在仅从可见、不透明、非图片、且不会被后续填充/边框/图片影响的节点选择通用采样点；没有确定性纯色时仍完成一次真实 readback，但明确记为 `no_deterministic_scene_pixel`，不能冒充像素正确。
- `composable_scene_probe` 新增不透明重叠、透明、裁剪、图片 FIT/FILL/alpha 及部分裁剪节点的红绿用例。修复前该裁剪外中心稳定报错；修复后像素精确通过。正常 AppKit resize 由 420×180pt/840×360px 到 437×191pt/874×382px（scale 2），像素仍匹配。它证明这些受控矩形/图片场景，不代替完整文字或人工画面验收。
- 生产端将当前 native scene 克隆到隔离 staging，Cangjie 端仅为相同 layout/style/resource/input 节点跳过 `internalRendererSetComposableSceneNode`；改变节点仍走真实 FFI setter。测试计数由初始 6 节点/6 次更新，到仅修改 caption 后为 7 次，证明未把全 scene 重写伪装为局部更新。命令 buffer completion 期间强引用已提交的节点/纹理快照，资源移除或换绑不会早于 in-flight GPU 使用释放。
- 图片移除/同路径重绑以显式版本驱动失效；30 次操作结束为 `loaded=1`、`cache_entries=1`、`decode_count=16`，说明当前绑定资源和缓存收敛，而不是遗留每次替换的引用。

### 重复正常窗口负载与成本

`render_resource_efficiency_probe` 经真实 `CjguiComposableUiWindow` 和 AppKit resize callback 运行：每类预热一次、再运行 30 次内容输入、字体切换、图片移除/重绑、稳定滚动、native resize 与 idle。idle 的 native 写入增量为 0。每条样本记录端到端、build、layout、native measurement、native stage/submit 与 GPU 完成；`WINDOW_WORK_TIMING_MS` 内部可嵌套，尤其 native measurement 可属于 layout，不能相加成总时延。端到端为主线程轮转采样，常见 7–8ms；GPU completion 单列且异步，不能由此声称显示器已经呈现。

同一工作负载的全量 native 写入控制（只临时禁用复用判定）与最终结果如下；它们比较真实 setter 工作量，**不是**把两次独立运行的 wall time 宣称为加速比：

| 30 次类别 | 全量 setter 写入 | 最终写入 | 减少 |
| --- | ---: | ---: | ---: |
| 内容 | 1680 | 60 | 96.4% |
| 字体 | 1680 | 1620 | 3.6% |
| 图片移除/重绑 | 1665 | 1515 | 9.0% |
| 滚动 | 1680 | 1440 | 14.3% |
| resize | 1680 | 1620 | 3.6% |
| idle | 0 | 0 | 不适用 |

最终 probe 的进程级 CPU 样本均值 29.71%、范围 0–53%、末样本 39.5%；RSS 首样本 144KiB、峰值 102288KiB、末样本 88016KiB。首样本属于启动早期，不能作为稳定基线；该组数据记录负载而非全框架性能宣称。

### 正常消费者与桌面

- 规则集和共享文档的最终 macOS bundle 已各重建；4 秒的正常窗口进程样本各有 34 次公开 `get`，规则集 p50/p95 为 11.965/22.785ms，共享文档为 11.974/22.291ms。共享文档还实际执行外部 edit、读回与旧版本冲突，scene/frame 由 1 推至 2。这些是公开读取和既有 owner 链路，不替代上面的渲染负载。
- 独立 adaptive consumer 在最终 bundle 中实际启动：CUA 点击“切换资源”得到蓝灯塔与珊瑚灯塔两种不同画面，再以原生 zoom 改变窗口大小。公开 `GET_WINDOW_PROGRESS` 读回 scene/submission/frame 均为 5，Metal completed frame 为 5、failed 为 -1；本机 stderr 同时记录 zoom 后 drawable 为 3024×1718px（scale 2）。公开进度接口故意不泄露图片路径/版本，图像变化由实际窗口截图、像素受控 probe 和该帧进度共同证明。
- 隔离公共消费者还以动态 descriptor 验证规则集/文档的授权、写入、读回、CAS 冲突、规则持久化重开与关闭后 endpoint 拒绝；它们没有读取实现源码。物理中文 IME、VoiceOver、人工像素审阅、安装/公证/发布仍未验证。

### 收口证据

本轮末尾通过：`cjpm test --parallel 1 --no-progress`（5/5）、`cjpm build --skip-script`、`verify_composable_scene_renderer.sh`、`verify_composable_ui_window_controller.sh`、`verify_render_resource_efficiency.sh`（每类 30 样本，`passed=true`），以及最终两个 bundle 重建。`git diff --check` 和相关源码尾随空白扫描无报错。构建仍有既存的 `chmod`/AppKit `allowedFileTypes` deprecation 与若干 probe unused 警告，均非本阶段失败；没有执行 stage、commit、push、安装或发布。

`presentation_state=unavailable` 保留为未验证：submitted、GPU completed、overlay drawn 不是用户眼睛已见。下一候选是可复用组件交互与无障碍完整性，尚未开始。
