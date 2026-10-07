# CJGUI 初赛演示

[播放或下载参赛成片](<CJGUI 初赛参赛演示.mp4>) · [完整解说字幕](<CJGUI 初赛参赛演示.srt>) · [解说词](视频解说词.txt) · [素材与版本指纹](video-provenance.json)

成片约 2 分 15 秒，1920×1080、30 fps，H.264/AAC；包含中文合成解说、章节和画面说明。网站若不提供内嵌播放，可下载 MP4 观看。

![编辑器首页实录预览](poster.png)

## 演示顺序

| 时间 | 内容 | 证据范围 |
| --- | --- | --- |
| 00:00 | CJGUI 面向谁、解决什么 | 项目介绍 |
| 00:16 | Pharos Mark 首页列表滚动、条目与 Markdown 预览更新 | 独立数据目录启动的既有 macOS 集成构建，真实窗口实录 |
| 00:41 | 生成与手写界面提交、外部备注同步、冻结标题拒绝 | 本次候选框架构建的普通 generated_panel_consumer，无 native 单元测试宏 |
| 01:17 | 鸿蒙温控与编辑器 | 已归档的真实模拟器截图；平台仍使用 XComponent 与 OH_Drawing |
| 01:41 | 测试与复现 | 框架 560/560、共享核心 100/100、公开 Python 客户端 96/96 |
| 02:02 | 作品入口与开发目标 | 源码、提案与验证材料导航 |

## 同一业务规则的实际链路

公开结构读回 `STRUCTURE_VERSION=3`、`SCENE_STATE=scene_accepted`。人在生成区点击提交，owner v3→v4，生成与手写标题同时只读；公开客户端 `SET_NOTES` 使 v4→v5，两个区域显示相同备注。在 v5 尝试 `SET_TITLE` 被 `title_frozen_after_submit` 拒绝，`APPLIED=false`、`VERSION_BEFORE/AFTER=5`；随后读回原标题及版本不变。

原始公开读回见 [结构接受](../evidence/generated-accepted-structure.json)、[窗口提交后 owner](../evidence/generated-after-ui-submit.json)、[备注结果](../evidence/generated-notes-result.json)、[标题拒绝](../evidence/generated-frozen-title-refused.json)和[最终 owner](../evidence/generated-final-owner.json)。输入直接粘贴的失败尝试没有计为通过，见 [验证报告](../VALIDATION.md)。

## 素材版本与制作

macOS 录屏按原速播放，仅做布局缩放和章节编排；UI 状态没有重绘或伪造。编辑器集成构建与本次候选框架分别记录二进制/源码指纹。鸿蒙段是截图展示，没有伪装成此次新录的动态操作或真机测试。正常消费者、契约测试和跨平台完成度分别解释。

解说使用本机 Apple Tingting 语音合成；底部为章节摘要字幕，SRT 提供完整解说文字，句子时间按合成音频时长分配。外部调用由脚本客户端完成，未宣称真实大模型自主操作。没有使用旧的 26 秒原始文档视频作为本次参赛成片。

对应源码、公开同步与下载复现状态见 [SOURCE_STATUS](../SOURCE_STATUS.md)。
