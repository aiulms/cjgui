# 只读技术咨询：H2 thermo normal 生成视口在 accepted 后仍屏外

只读分析，不修改文件、不运行构建、不操作桌面。只查下列直接相关文件；不要从头扫描工程。

目标：华为模拟器 normal HAP 上真实消费 CJGUI 的手写与公开生成 scrollArea。保留已有 H2 共同 host、惯性积分、接管、旧 release 与准入实现。本问题不改变框架/产品定位，不引入外部 GUI 依赖。

本轮事实：
- 正确使用 thermostat canonical source 构建，HAP sha256 5e9e6734f0520aea37183d443f65939441b85512f441452c2ba288c309f2a6ea，PID 14568，平台指纹 4d6f2b91eaf5ee50b717a2ff3e41c017e8cc894327d0f09591bbb201d6d23e8e。CompileCangjie 实际执行，normal seam absent。
- 公开 SUBMIT_GENERATED_UI 候选逐节点回读完全一致，status=accepted；owner 没有因提交而改变。
- accepted generated viewport bounds=[28,554,340,220]，semantic=component-2-1，visible=false；trigger y554、editor y830 同样 visible=false。
- 本机模拟器 density=3.5；表面布局采用 vp，当前表面约 487vp 高（物理屏1320x2856，表面y137..1842px）。不能把 accepted 结构当真实可触消费。
- settings 对照当前可消费：root 顶部标题/描述后直接 add(generatedRegion.buildNode())，手写 viewport 150vp，再放大 cardBox。thermo 仍有 52vp 标题、420vp 手写 viewport、大 cardBox，最后另包一层无显式高度的 generatedBox。

必要文件（本地绝对路径）：
1. /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/thermostat_application/src/thermostat_app.cj 的 CjguiThermostatController.buildUi（307-431附近）。
2. /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/settings_counter_application/src/settings_counter.cj 的 buildUi（379-569附近）。
3. /Users/jiangxuanyang/Desktop/cangjie/labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets 的 surface 布局；ArkTS 只允许窄宿主，不把业务界面搬进去。
4. /Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/h2-2-thermo-normal-20260930-correct-src/generated_r1/result.json。
5. /Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/h2-2-thermo-normal-20260930/candidates/candidate_thermo_v1.raw.txt（根fixedHeight226、viewport220，非零内禀高度）。

已有归因假设（请质疑）：这是消费方的旧像素时代尺寸/放置顺序，而不是共同 scroll/惯性机制。extra generatedBox 可能同时影响内禀高度。普通可辨识布局应令生成视口在上方可触，再以公开几何选点完成拖动/惯性/公开owner写入；不能通过放宽visible判据或只读回结构通过。

请给：可确定的根因与仍需区分的假设；最小可实施布局方案；必要的 source/normal 行为反例；适用前提和当前SDK单位边界。不要重设计框架、不扩功能、不重新提出已绿积分算法。
