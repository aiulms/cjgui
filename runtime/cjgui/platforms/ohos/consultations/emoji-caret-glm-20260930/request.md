# 只读聚焦咨询：真实系统键盘输入 emoji 后 native caret 跑到第一行；光标常亮
不要写文件/构建/操作设备；质疑既有归因，区分证据和推断，给最小区分实验、机制、验收反例。
工作区 /Users/jiangxuanyang/Desktop/cangjie。
当前 normal HAP 3851dd37ddd61e4e7ad1b2dddb25d930806b98b778bd41d59337e1bbb58c3a7b PID6213。
用户真实键盘输入反例截图先是恢复后替换\nAgent:正文小艺输入法😆，native蓝光标在第一行右侧。
完整后续owner v32/58B: 恢复后替换\nAgent:正文小艺输入法😆(^～^)😀，public WINDOW_SELECTION UTF16=28:28，与实际平台 onSelection 28:28 一致。字符真实进了同一owner；不是首字丢失。
原始日志/owner/screen在 artifacts/h-overnight-final-20260930/14-user-emoji-caret-r4b/。
怀疑绘制 caretRectFor 查询 [caret-1,caret) 恰好只包含 emoji 的 low surrogate，GetRectsForRange 可能无盒→fallback prefixWidthUtf16 后把 top 置0。请勿仅凭假设认定，必须给可区分的实际SDK探针。
本机SDK /Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/native_drawing/drawing_text_typography.h 2188: start/end 明确UTF16码元，API11。GlyphInfo/LineMetrics请按实际声明可用性评审。
关键源码 runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp drawNodeText/computeTextGeometry/caretRectFor/executeCaretHitTest；底层渲染线程Job队列与redrawLastFrame；pump运行16ms，是否可以只在半周期变化时排一笔现有RedrawJob？必须沿surface generation/lease/停止协议，不另造timer争锁线程。
现有ICU公共CABI cjgui_internal_renderer_grapheme_cluster_range可返回同版本UTF8完整grapheme边界；context查询也已有，不要在ArkTS实现字素算法。坐标和cluster框只能来自同一排版。
成熟只读参考 Flutter packages/flutter/lib/src/painting/text_painter.dart _computeCaretMetrics（完整grapheme查询，不含半字素）；rendering/editable.dart caretBlink/stopCursorBlink，只参考机制。
当前确定性假排版test_text_geometry_native.py只按每码元推进，未模拟部分surrogate/ZWJ范围无盒。请指出应新增何种真实对照与严格反例。
要求：1. 根因假设/可区分实验；2. caret合法边界/硬换行/空行/emoji/combining/ZWJ的最小机制；3. blink活动、输入重置/失焦停用/selection非空隐藏/无自激无owner写入的方案；4. 需要提前Sol/Astra咨询的未决生命周期风险（若有不要用输出冒充已验证）。
