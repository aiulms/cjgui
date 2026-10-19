## 结论
拟议接线（8KiB stack → 有界 4MiB `std::vector<char>`，仍调原一次 `imeContextQueryFn(data, size)`，0/1 fail-closed 原样）**可行，无 ABI/NAPI 破坏**；有 2 个真实边界缺口（preview 无代码上界、宿主全量 HLOGI）需处理。更小可靠机制存在（有界 grow-retry），但非必需。

## 证据（本地代码）
- native `ohos_renderer_ime_context_json`（ohos_renderer.cpp:8755–8832）：`g_sessions.lock` 下整串构造，`json.size()+1 > capacity` 才拒绝，否则整块 `memcpy`+NUL 返回 1——全有或全无，单次调用即单次原子快照。转义最坏每字节 6×（`\u00xx`，:8737 附近）。最坏 JSON ≈ 6×(body+preview 字节) + ~600B 元数据；262144×2×6 = 3,145,728 < 4MiB ✓。
- 宿主 `ImeEditingContext`（cjgui_host_bridge.cpp:2935–2954）：`char buffer[8192]` → `imeContextQueryFn(buffer, 8192)` → `napi_create_string_utf8(…, NAPI_AUTO_LENGTH)`。指针+int32 传参，换 heap 缓冲对 dlsym 私有 ABI **零影响**；4MiB < INT32_MAX，`napi_create_string_utf8` 支持兆级 NUL 结尾串。`imeContextQueryFn` 仅此一处调用。

## 缺口
1. **preview 无代码上界（你的问题核心）**：`ImeSetPreviewText`（:5858–5882）无条件拷入系统给的任意 length，“至多 256KiB preview”是环境假设而非仓内控制。即 4MiB 的“最坏覆盖”对 body（262144 准入）是代码保证，对 preview 不是。被超出时后果与今天相同：具名拒绝返回 0 → 键盘不挂载，且 native 拒绝日志已打印真实 `size=`，可诊断、无内存安全问题。**不必为此新增 native 上界**（那才是新规则）；正确表述是“代码可证上界 + preview 超额仍具名 fail-closed”。
2. **HLOGI 全量快照**（:2946 `"ime context json: %s"`）：2.6MB 快照每次 mount 灌爆 hilog（hilog 单行会截断且格式化 3MB 有成本）。建议留证改为“前 N 字节 + 总长”，这不属 0/1 语义。
3. 次要：`vector(4MiB)` 值初始化每次 query memset 4MiB——mount 频率下可忽略；host 只在 `ok==1` 读 buffer，native memcpy 自带 NUL，预置 `buffer[0]='\0'` 仅是防御，可保留可去掉。

## 更小可靠机制（若要）
有界 grow-retry（如 8K→64K→512K→4M）：每次调用各自原子，返回的是**最后成功那一次的完整一致快照**（不会混合两次状态；中途 retire 则末次返回 0 → ""），常见字段零大分配。代价：病态路径下 native 重复整串构造 2–3 次。若坚持“原一次原子调用”，固定 4MiB 单次调用同样正确且更简单——原子性本就按调用计，不按调用数计。

## 试验矩阵（认可，补两点）
- RED：262144B + 控制符组合在 8192 下拒（现有 262549 是无转义放大例；控制符例应见 size≈6×，验证转义上界）。
- GREEN 后：完整 body+preview JSON 解析回读 SHA 精确；无会话/retired context 仍 ""（:8770/:8775 原路径）；旧 context 回调仍被 `takeEditingContextLocked` 拒。
- “缓冲不足不越界”：body 受准入限制实际到不了 4MiB，该反例只能由超预算 preview 触发，而 preview 是系统驱动、无注入钩子——只能静态依赖 `json.size()+1 ≤ capacity` 才 memcpy 这条不变式，如实标注“代码论证、未动态覆盖”。
- 你标注的“原目标非空恢复仍待验”与本次修复正交：此改动不触碰 restore 路径，保存后恢复用例仍需单独跑。
