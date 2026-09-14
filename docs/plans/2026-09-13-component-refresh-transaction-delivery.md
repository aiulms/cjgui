# 组件刷新一致提交与失败恢复：交付记录

2026-09-13；实施依据为[阶段任务](2026-09-13-component-refresh-transaction-milestone.md)。本记录只说明
本轮 framework/source、probe、normal bundle 的实际证据；不把测试注入、AX 树、签名或公开 socket 调用
冒充为 IME、VoiceOver、安装或发布验收。

## 实现

- `CjguiComposableUiComponentRegistry` 分离已接受实例与 candidate/retry 标量。候选准备不销毁已接受
  实例；同一失败候选重试复用其候选身份；接受时才一次性淘汰未保留的旧实例。旧
  `begin()`/`finish()` 保留为低层兼容路径。
- `CjguiComposableUiSceneRefreshParticipant` 把 registry transaction 与 candidate command 集接到
  `CjguiComposableUiWindow`。窗口依次 begin、build、prepare、验证 candidate command 与 scene、native
  staging/present，只有接受后才 swap scene、component identity 和 command binding。测量/布局、duplicate、
  node setter 或 present 失败都 rollback participant 并保留旧投影、命令与输入目标。
- native 只增加 `CJGUI_INTERNAL_TESTING` 下的两个计数型失败 seam；它们没有进入 production public ABI，
  仅使 probe 能确定性拒绝下一次 staged node write 或 present。
- `adaptive_layout_public_consumer` 与 `rule_set_window_app` 都实现 participant，移除了 buildUi 内
  `finish()` 以及 pump 后的无条件 `replaceCommands()`。Rule Set 的静态菜单 command 也进入 candidate
  command 集。

## 证据

- 红测先在 controller probe 声明 setter/present seam：未实现时链接明确报两个 undefined symbol；实现后
  完整 normal-window probe 输出 `CJGUI_COMPONENT_FAILURE_REPRO refresh=false live_instances=2`、
  `CJGUI_COMPONENT_FAILURE_RECOVERY pending_alpha=4002 live_instances=1` 和
  `CJGUI_COMPONENT_NATIVE_FAILURE_REPRO setter=false present=false live_instances=2`，最终
  `cjgui composable window controller probe: native text then apply passed`。
- 同一真实窗口完成 30 轮成功/失败/重试、组件隐藏/重挂与交错输入：`build/layout/submit delta=150/150/120`、
  queue 收尾为 0（high-water 2）、live instances/commands 均为 2；随后 1,875 个 bounded idle turns 的
  build/layout/submit delta 均为 0。该采样不构成全局内存无泄漏或人眼呈现结论。
- 1.1.3/default-SDK 重建后的 Adaptive normal bundle 实窗生成私有 descriptor：完整 GET 显示两个 component
  scope；`SET_MARKED 7101` 从 version 0 到 1，读回 `isMarked=true`、accepted/submitted scene 到 2；陈旧
  CAS 返回 `version_conflict`，未授权 `GET_CHANGES` 返回 `unauthorized_action`。关闭控件后 descriptor 删除且
  process 不存在。
- 为不干扰用户正在运行的 `org.cangjie.cjgui.rule-set.example`，同一 Rule Set 源码以临时独立 bundle ID
  `org.cangjie.cjgui.rule-set.113-isolation` 构建、签名和直接运行。真实 Host 输出
  `CJGUI_RULE_SET_HOST_PROBE rejected_then_accepted_close_cleaned`；用户同 ID 窗口始终保持运行。临时配置已删除。

## 仍未验

- 用户同 ID Rule Set 的最新源码没有重新实窗启动；隔离 bundle 证明同一 source/Host 路径，但不替代用户实例。
- 物理中文 IME、VoiceOver、人眼像素呈现、安装/公证/发布、多平台与稳定 ABI 均未验。
