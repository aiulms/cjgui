# ohos_main_surface_probe

独立技术实验：**普通 normal HAP 不创建 XComponent，能否直接向应用主窗口的 Surface/Buffer 提交自绘画面。**

- 实验报告（结论、证据、ABI 陷阱、接线缺口、下一步）：[REPORT.md](./REPORT.md)
- 原始日志 / 截图 / 崩溃日志：`artifacts/`
- 本目录是独立实验，**不改动** `labs/ohos_cjgui_app`、`labs/ohos_thermo_app`
  与 `runtime/cjgui/platforms/ohos` 的任何文件，也不依赖 `runtime/cjgui` 的构建入口。

## 一句话结论

公开 API 里**没有**任何入口能返回本应用主窗口的 surface/surfaceId（精确断点见 REPORT §0）；
本次成功依赖 `libwm.z.so` / `librender_service_client.z.so` 的**内部 ABI + 一处 ABI 布局推断**，
只能记为「私有接口实验成功」。提交能力本身（`OH_NativeWindow_CreateNativeWindowFromSurfaceId`）
是公开且好用的，缺的只是 surfaceId 的公开来源。

## 前置条件

```bash
export HDC=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc
export DEVECO_CLI=~/.local/bin/devecocli        # DevEco 26.0.0.821
$HDC list targets                               # 需要模拟器已启动（实测 127.0.0.1:5555）
```

## 常用命令

```bash
cd labs/ohos_main_surface_probe

bash scripts/probe.sh build                     # devecocli build --build-mode debug
bash scripts/probe.sh install                   # hdc install -r（未签名 HAP，普通 normal HAP）
bash scripts/probe.sh start <level> [frame] [cand]
bash scripts/probe.sh logs                      # 抓 MainSurfaceProbe 的 hilog
bash scripts/probe.sh shot <name>               # snapshot_display + 回传到 artifacts/run/$RUN_ID
```

`level` 是位掩码（顺序固定）：

| 位 | 含义 |
| --- | --- |
| 1 | 装载私有库 + dlsym 内部符号 |
| 2 | 取 Window → vtable → `GetSurfaceNode` → `GetSurface` → OHNativeWindow |
| 4 | 提交两帧（纯蓝、橙白棋盘） |
| 8 | `RSSurfaceNode::SetContainerWindow` / `SetHardwareEnabled`（**已崩，勿用**） |
| 16 | 有界盲扫 `WindowSessionImpl::GetWindowWithId(id)` 枚举窗口 |
| 32 | 用**公开 NDK** 把窗口底色设成透明（自绘可见的硬前提） |

`cand` 选窗口入口：1=`Window::GetWindowWithId` 2=`WindowSessionImpl::…` 3=`WindowSceneSessionImpl::GetMainWindowWithId` 4=`WindowImpl::…`（返回空）。

其他启动参数（经 `aa start --pi` 传入，应用内唯一控制面）：

- `probeLevel` / `probeCandidate` / `frame`（0 蓝、1 橙白棋盘、2 青黑竖条）
- `rotate` = 1/0（切横屏/竖屏，用于验证 surface geometry 跟随）
- `arktsTransparency` = 0（跳过 ArkTS 侧设透明，用于把透明归因到公开 NDK 调用）

复现主判据（控制组 + 三帧 + 触摸 + 释放重取）：

```bash
bash scripts/probe.sh install
RUN_ID=final_evidence bash scripts/probe.sh start 3 -1 2 && sleep 6
# 用 uitest dumpLayout 取按钮坐标，再 uitest uiInput click 逐个点「帧0/帧1/帧2」并截图
```

## 页面按钮

`公开层 / 私有库 / 取Surface / +硬件合成 / 候选1..4 / 帧0 蓝 / 帧1 橙格 / 帧2 青条 / 转横屏 / 转竖屏 / 释放`

页面根容器透明，只有顶部一条控制卡有底色 —— 控制卡是用来提供**真实触摸落点**的，
也正是「ArkUI 内容会画在自绘 buffer 之上」这条结论的直观对照。

## 不要提交的内容

`entry/build/`、`entry/.cxx/`、`artifacts/` 是本地产物与取证目录，按仓库惯例不入库。
本实验未 stage / commit / push 任何文件。
