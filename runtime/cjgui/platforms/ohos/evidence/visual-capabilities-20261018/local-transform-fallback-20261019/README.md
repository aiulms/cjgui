# macOS 局部效果快路 · 变换边界收尾（2026-10-19）

本目录只收本轮新增证据：`CjguiEffectLocalPaintNodes` 的变换退出门及其定向验证。
不重跑跨平台视觉整包、编辑器、GiB、IME 或交付打包；既有结果仍以
[上级目录 README](../README.md) 为准。

**验收范围：仅 macOS 已接受。** OHOS/Windows/Linux 的组合变换保持未验；
后续平台若出现效果组缩放丢失或旋转被裁剪，应按框架/平台接入缺口核对，
不能据 macOS 结果假定已支持。

## 缺陷

局部快路只重新基址“已平移”的 CPU 绘制输入：

- 目标范围按原 body/support 的未旋转矩形计算；
- 私有 clone 的 geometry 从零初始化，只回填平移与 clip，不保留 `scaleX/scaleY`；
- clone 的矩形裁剪覆盖不了旋转后的四边形；
- 这条路径本就不接收 IMAGE 节点（`unsupported_paint`），所以普通图片演示
  无法证明它正确。

## 修法

在 `CjguiEffectLocalPaintNodes` 的预检循环中，按绘制路径同样的归一化规则
（非有限/非正的 scale 视为 1，非有限 rotation 视为 0）检查组内所有节点：

- 任一块有非单位 scale 或非零 rotation → `reason=non_translation_transform`，返回 nil；
- 由 `CjguiPrepareEffectTargets` 落到通用效果路径，其
  `CjguiEffectGroupOutputBounds` 使用绕中心“先 scale 后 rotate”的保守旋转包络，
  私有绘制输入与内容签名保留原节点变换；
- 纯平移（含小数放置与相位复用）不退出，局部纹理复用保持不变。

缓存身份不需要额外放宽：`CjguiEffectContentSignature` 已把 POD 字节
（含 `rotateDegrees`）与 sidecar 的 `translateX/Y`、`scaleX/Y`、clip 小数一起哈希。
变换改变的帧不会复用上一帧的 `effectLocalNodes`；恢复恒等变换后会重新计算局部节点。

代码位置：`runtime/cjgui/native/cjgui_internal_renderer.m`，
`CjguiEffectLocalPaintNodes` 预检（约 16247–16263 行）。

## 定向验证

构建：macOS 26 SDK，Apple clang 21.0.0，`-DCJGUI_INTERNAL_TESTING`，链接
`cjgui_native_bridge.m`；二进制与源码哈希见 `BUILD.txt`。

### 新边框用例（纯形状，无图片）

`runtime/cjgui/native/tests/composable_effect_local_transform_fallback_test.m`
以既有 `composable_effect_local_translation_production_test.m` 为夹具，
2 节点效果组：透明布局根 + 40×40 红色子节点，clip 为整视图。
下表的目标范围与 `@ (x,y)` 目标放置是 2× device pixel（窗口 drawable 840×640）；
`(139,151)` 等采样位置是逻辑点，不是设备像素。

| 提交 | 变换 | 局部快路 | 目标范围 | 关键像素 |
| --- | --- | --- | --- | --- |
| v1 | 恒等 | 是 | 80×80 @ (200,200) | 中心红 |
| v2 | scale 2× / 0.5×, rotate 45° | 否（`non_translation_transform`） | 166×166 @ (157,157)，已越过 body 左界 200 | (139,151) 红；(157,120) 非红 |
| v3 | scale 3× / 0.5×, rotate 90° | 否 | 244×244 @ (118,118) | (120,175) 红；(170,120) 非红 |
| v4 | 恒等，translate 25 | 是 | 80×80 | (145,120) 红；原位置非红 |
| v5 | 恒等，translate 57 | 是，复用 v4 已完成目标 | 目标指针不变 | `reuse +1`，目标像素逐字节相同，放置右移 64 device px |

v2/v3 的采样点用于区分组合顺序，而不只是“有变换”：

- macOS `CjguiRotateMetalPoint` 先做 `(p-center)*scale`，再做 cos/sin 旋转；
- 2×/0.5× + 45° 下，先 scale 后 rotate 的 40×40 body 变成细平行四边形，
  角点伸到 (139,151)；若先 rotate 后 scale，则 (157,120) 才会被覆盖；
- 3×/0.5× + 90° 同理：先 scale 后 rotate 是 20 宽 × 120 高，
  先 rotate 后 scale 是 120 宽 × 20 高。

结果：`rc=0`；全部状态、统计与像素断言通过。原始输出见
`transform-fallback.log`，局部路径原因与目标生命周期见
`transform-fallback-trace.log`（含三次 `reason=non_translation_transform` 与
v5 `reuse=1 gpu_ready=1`）。

### 既有纯平移正控

`runtime/cjgui/native/tests/composable_effect_local_translation_production_test.m`
原样编译运行，`rc=0`；`HOME_EFFECT_LOCAL_RESULT failures=0`，
`phase2_*` 的小数相位、半像素、非二进小数范围复用全部 PASS。
原始输出见 `translation-control.log` / `translation-control-trace.log`。

### 普通消费者连续操作

`range_text_window_app` 重建 native 与应用包后，真实鼠标点击：

| 状态 | 读回 | 证据 |
| --- | --- | --- |
| scale | `scale 1.50 · rotate 0°` | `consumer-01-scale-150.png` |
| + rotate | `scale 1.50 · rotate 20°` | `consumer-02-scale-rotate.png` |
| 复原 | `scale 1.00 · rotate 0°` | `consumer-03-restored.png` |

C 环在固定 EffectGroup 内放大并旋转，未被组内裁剪；复原后回到原尺寸/角度。
进程按 PID 关闭，无残留消费者。运行日志见 `consumer.log`。

## 组合变换口径（纠正）

- **macOS**：绘制顺序已由源码与实际像素区分——绕可视中心先 scale 后 rotate。
  本轮用非等比 2×/0.5× + 45° 及 3×/0.5× + 90° 两个反例确认，不再只依赖
  等比 1.5× + 20°。
- **OHOS**：Canvas 的调用先后不能单独证明组合顺序；须按实际矩阵乘法
  （pre/post-multiply 与 translate/rotate/scale 的相对位置）解释。本轮未在真机
  重跑非等比用例，因此 OHOS 的“先 scale 后 rotate”仍是**未验**，不引用旧等比图代替。
- **Windows / Linux**：本轮未运行组合变换像素用例，保持**未验**；不据此启动平台工程。

不再保留“四端按同一顺序”的确定性表述。

## 验收范围与平台接入提示（2026-10-19）

**已接受：仅 macOS 的效果路径修复。** macOS 已证明含非单位 scale/非零 rotation 的
效果组退出局部快路、由通用路径完整绘制，纯平移复用保持；这是 macOS 的消费级证据。

OHOS、Windows、Linux 的组合变换本轮均未运行，不在本次验收内。后续在这些平台开发或
排查时不要假定同等行为已存在：若该平台在效果组内出现缩放丢失、旋转后被矩形裁剪、
或平移复用边界异常，应先核对该平台的输出范围、私有绘制输入与缓存身份是否同样携带
变换；这可能是该平台接入需要补的框架能力，而不是已有能力的回归。

## 图片 preparation 口径

上级页记录的 preparation 次数仅是**资源解码次数**证据；不扩展为 GPU 显存或
纹理内存结论。本轮没有新增图片解码观测。
