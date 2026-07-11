# CJGUI 活跃方向

## 四周目标

在真实 AppKit/Metal 窗口中运行仓颉 Todo demo：

1. 显示任务列表；
2. 响应至少一次点击；
3. 更新任务状态；
4. 重绘。

本阶段只做清理和基线收敛，不实现 renderer、Node、布局、输入或 Todo 窗口。

## 当前有效资产

- **macOS smoke**：`labs/macos_bridge_smoke` —— 真实 AppKit 窗口、Metal
  clear、command buffer、readback、自动关闭、退出，全部通过。
- **demo typed state / harness**：`runtime/cjgui/demo/` 与
  `runtime/cjgui/src/demo_support/` —— 10 个 demo 验证脚本 + typed state
  + shared harness。
- **剩余 runtime 基础**：`runtime/cjgui/src/*.cj`（357 个非 stage 文件）——
  非 stage runtime、native bridge、runtime state owner。

## Stage 145–892 已冻结

stage 145–892（748 个源文件 + 1410 个验证脚本）已退出活跃源码树，仅保留在
Git 历史。它们是历史审计证据，不是 GUI 功能、runtime truth 或开发模板。

归档清单：`docs/archive/cjgui-stage-145-892-manifest.md`

## 下一阶段

把 `labs/macos_bridge_smoke` 提取为极窄 internal renderer：最小窗口 +
Metal clear + 一次 host readback，作为 Todo demo 的渲染底座。

## 禁止事项

- 不得重新引入同构 Bool 审计包装。
- 不得创建 stage 893 或任何新的 stage/audit wrapper。
- 不得把 stage 145–892 复制回活跃源码树。
