# CJGUI 首页真实演示素材

本目录素材来自一个独立的、临时复制的 `CJGUI Shared Document` 正常应用窗口；录制和截图只裁取该窗口，未捕获其他应用、账户或通知。

## 建议使用顺序

1. `cjgui-demo-01-ui-edit.png` — **界面编辑**：桌面自动化在原生文本框内点击并键入，窗口把内容、选区与版本回读为文档 `v3`。
2. `cjgui-demo-02-public-interface-sync.png` — **外部接口调用演示**：录制中的后续界面键入先将目标文档推进到 `v13`；公开 descriptor-gated `REPLACE_RANGE` 再以该版本、UTF-8 范围 `150..150` 成功追加“演示二：外部接口调用演示，已同步。”；窗口显示“已同步外部文档：v14”。
3. `cjgui-demo-03-ui-continuation.png` — **界面续接编辑**：同一文本框继续键入，窗口到达 `v20`；随后通过公开接口读回同一文档的版本 `20`、长度 `208`。

`cjgui-shared-document-real-demo.mov` 是同一隔离窗口的 26 秒无音频、1960×1296 窗口裁剪录制，未加速。文件头为 `ftypqt`，是 QuickTime/MOV 容器；已在 QuickTime Player 中实播核验。它用于首页视频位；PNG 可用于不自动播放视频的 README 或项目页。

建议图注：**“同一份仓颉文档：界面编辑、公开接口调用演示与界面续接。”**

## 真实性与边界

- 外部调用是本地公开接口演示，不是模型、Agent 或聊天任务。调用者使用应用签发的私有 descriptor 和通用 `client.py`，并保留 CAS/读回日志。
- 界面输入通过桌面自动化的窗口坐标点击与文本事件完成；它不是用户物理键盘或输入法实测。
- 素材仅操作临时实例与临时保存路径，未读取、写入或关闭用户正在使用的文档窗口。
- 当前没有使用 GIF 转码：本机未发现已安装的 `ffmpeg` 或 `gifski`，未为素材安装额外依赖。

## 版本与可追溯记录

- Git 基线：`172609c955053582adbe1ac2a8399e08bbbd1aa0`
- 演示源码 `shared_document_window_app/src/main.cj` SHA-256：`bbb5a6196359147a16d51da860f5cdddc80053e38e9e7f227f914fb41fb1696c`
- 演示二进制 SHA-256：`feb1625d3a7a4d5a39815192bb235a48ea175d49aaad1d1b452cb4ce7afc8e63`
- 原始实例、公开调用与读回日志：`/private/tmp/cjgui-homepage-demo.fgm0bK/`

该目录只提供素材和说明；未修改项目首页，也不构成安装、公证、发布、物理输入或模型能力声明。
