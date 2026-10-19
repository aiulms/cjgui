只读聚焦机制审阅，不写源码、不构建、不操作设备、不重扫仓库。新问题独立上下文，模型 gpt-6-astra/max。
目标：CJGUI OHOS native 自绘 caret 修复 emoji 错行与无blink；不改变 owner、编辑协议或架构；用户刚实测两缺陷。
读取：runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp 的 Session/RenderThread::postIfRunning/run/executeRedraw/drawNodeText/caretRectFor/pump。
日常 Pi GLM5.3 咨询答复 runtime/cjgui/platforms/ohos/consultations/emoji-caret-glm-20260930/answer.md，模型意见不算运行证据。
实际本机 HarmonyOS 6.1.1 API24 SDK，device API26 1320x2856 density3.5；normal独立counter HAP54b26e4... PID17216。探针 artifacts/h-overnight-final-20260930/platform-delete-probe/typography-r7c/typography.txt 已证：emoji/combining/ZWJ/skin/flag partial最后1码元范围 boxes=0，完整簇 boxes=1且top>22；hardnewline范围给零宽上一行盒，旧fallback top=0。
生产反例HAP3851dd... PID6213，用户正文恢复后替换\nAgent:正文小艺输入法😆(^～^)😀 58B28UTF16，owner完整字节和platform/core选区28:28一致，但caret在首行。位置问题已用实际SDK对照确认。
拟议几何：同一render Session快照一次拷贝正文、caret/选区；纯系统ICU既有CABI返回完整grapheme区间（不是ArkTS算法），UTF8/UTF16机械映射；GetRectsForRange查完整簇而非半代理。当前最低SDK/API24可用GetLineMetricsAt(API12)，硬换行及尾空行优先下游字素/实际行指标定位，禁止回退wholeprefix longestLine+top=0；服务或排版拒答named无caret而非伪造首行。
拟议blink：Session caretBlinkVisible/nextDue500ms、resetPending+editingContext/signature；同一pump锁内决策，input/preview/新humananchor置reset；同值平台selection回声不置reset。活动条件editing live&&!retired&&collapsed；第一次亮，500ms相变一次，nextDue=now+500，逾期不补发burst。
锁外postIfRunning RedrawJob，使用已有render thread和surface lease/geometry检查，不另开线程、不调用post自动重启renderer。需要一个最多1笔queued blink redraw位（renderer::lock）或已有redraw合并；executeRedraw先清queued位但旧任务因resize/retire仍必须只作用live lease，停机/启动清位；无owner/projection version写入、无输入事件、无restore票据改变。
请求：审阅1. 锁序/lease/resize/停止潜在风险与唯一责任方；2. 队列去重、per-session绘制与lastNodes归属是否需要额外身份守卫；3. caret同一排版/尾空行机制公共边界；4. 最小确定性反例和真实normal汇合判据（包含失焦停帧、输入即时亮且回声不常亮、emoji正确行、命中往返）。如存在未决风险请给可区分实验与最小方案，不泛泛提出架构重写。不需要从头审核N1–N4。
成熟只读参考已实读 /Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/painting/text_painter.dart:1592–1668 及 widgets/editable_text.dart:4907–4982：完整grapheme盒/500ms相位/焦点停用，只借鉴机制，禁止引依赖。
