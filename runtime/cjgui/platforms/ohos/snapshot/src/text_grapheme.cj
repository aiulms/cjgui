// 普通文字的用户感知字符（扩展字素簇）公共服务：纯文本、无会话、无场景。
// macOS 采用 CFString composed range，HarmonyOS 采用系统 ICU character iterator
// （root locale，不自建 UAX#29）；本机验收语料（组合重音、ZWJ 家庭、旗帜、肤色、代理对）实测返回
// 完整扩展簇。单位契约：输入输出都是调用方编辑所用的 UTF-8 字节域；不能证明
// 簇边界时返回 None（具名失败在 native 侧为 GRAPHEME_BOUNDARY_INVALID /
// INVALID_UTF8），调用方保持原文并报告状态，绝不静默钳位。

package cjgui

foreign {
    func cjgui_internal_renderer_grapheme_cluster_range(
        utf8: CString,
        declaredLength: UInt64,
        offsetByte: UInt64,
        outStartByte: CPointer<UInt64>,
        outEndByte: CPointer<UInt64>
    ): Int32
}

/// `text` 中包含 `offsetByte` 那个字节的字素簇的 UTF-8 字节区间（左闭右开）；
/// `offsetByte` 恰在簇起点、或落在多字节标量内部（归入其所属标量的簇）时都返回
/// 该簇。不能证明（越界、编码错误、内嵌 NUL 截断）时返回 None —— 这是
/// "无簇可名"的诚实答案，不是空簇。
public func cjguiGraphemeClusterRangeUtf8(text: String, offsetByte: Int64): ?(Int64, Int64) {
    let bytes = text.toArray()
    let totalBytes = Int64(bytes.size)
    if (offsetByte < 0 || offsetByte >= totalBytes) {
        return None
    }
    let cText = unsafe { LibC.mallocCString(text) }
    var startByte: UInt64 = 0
    var endByte: UInt64 = 0
    var status: Int32 = 99
    try (held = cText.asResource()) {
        status = unsafe {
            cjgui_internal_renderer_grapheme_cluster_range(held.value, UInt64(totalBytes),
                UInt64(offsetByte), inout startByte, inout endByte)
        }
    }
    if (status != 0) {
        return None
    }
    if (endByte <= startByte || endByte > UInt64(totalBytes)) {
        return None
    }
    var start = Int64(startByte)
    var end = Int64(endByte)
    // 编辑配置（Astra e-grapheme-position-contract Q1）：CRLF 是不可拆的换行单元。
    // 平台 composed-sequence 把 CR 与 LF 分成两簇，这里把恰好覆盖单个 CR/LF 的
    // 簇与它的另一半合并；其他簇不受影响。
    if (end - start == 1) {
        let CR: UInt8 = 0x0D
        let LF: UInt8 = 0x0A
        if (bytes[start] == CR && end < totalBytes && bytes[end] == LF) {
            end += 1
        } else if (bytes[start] == LF && start > 0 && bytes[start - 1] == CR) {
            start -= 1
        }
    }
    return (start, end)
}
