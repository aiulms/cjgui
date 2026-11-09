// R3（h-source-preview-followup 2026-10-02）：生成 TEXT 字段的通用范围会话桥。
//
// 缺口（设备断点）：生成 UI 的 TEXT 字段从未建立 owned 范围文本会话，系统输入
// 经共享代理接受后 native 报 `ime plain change NOT owner: enabled=0`，整值提交
// 被降级为视觉预览，永不达 owner。本桥把 provider 的 owner 事务文本写
//（applyTextEdit 等五个入口，见 CjguiGeneratedUiBindingProvider）适配成框架的
// CjguiRangeTextSource/CjguiRangeTextEditSink，由生成运行时在字段编辑聚焦时
// bindRangeTextSession 绑定——消费者只实现 owner 事务，不复制任何会话机制。
package cjgui

/// One generated TEXT field's owned range session adapter. Framework-owned;
/// the application side is entirely `CjguiGeneratedUiBindingProvider`.
public class CjguiGeneratedFieldRangeSession <: CjguiRangeTextSource & CjguiRangeTextEditSink {
    private let binding: CjguiGeneratedUiBindingProvider
    private let fieldId: String
    /// Empty keeps the single-owner contract. A composite instance carries its
    /// accepted instance key into EVERY provider call of this session, so two
    /// objects that declare the same field never share body/version/selection.
    private let instanceKey: String
    /// Accepted owner target frozen when the framework bound this session.
    /// A negative value keeps the strict single-owner contract where the
    /// provider is the only target authority.
    private let ownerTarget: Int64
    /// Optional accepted-binding guard supplied by the generated region. It
    /// answers whether the exact accepted composite element (including its
    /// instance generation) still exists.
    private let bindingCurrent: ?(() -> Bool)

    public init(binding: CjguiGeneratedUiBindingProvider, fieldId: String, instanceKey!: String = "",
        ownerTarget!: Int64 = -1, bindingCurrent!: ?(() -> Bool) = None) {
        this.binding = binding
        this.fieldId = fieldId
        this.instanceKey = instanceKey
        this.ownerTarget = ownerTarget
        this.bindingCurrent = bindingCurrent
    }

    public func targetFieldId(): String {
        return this.fieldId
    }

    public func targetInstanceKey(): String {
        return this.instanceKey
    }

    /// Empty means the session still belongs to the exact accepted object it
    /// was bound for. A removed/rebound accepted binding or a provider that now
    /// resolves the key to another owner retires the session BEFORE any read or
    /// write, so a matching numeric version cannot keep it alive.
    private func retiredReason(): String {
        if (let Some(current) <- bindingCurrent) {
            if (!current()) {
                return "binding_retired"
            }
        }
        if (ownerTarget >= 0) {
            let resolved = if (instanceKey.size > 0) {
                binding.fieldOperationResourceId(fieldId, instanceKey)
            } else {
                binding.fieldOperationResourceId(fieldId)
            }
            if (resolved != ownerTarget) {
                return "owner_target_retired"
            }
        }
        return ""
    }

    private func currentTextVersion(): Int64 {
        return if (instanceKey.size > 0) {
            binding.fieldTextVersion(fieldId, instanceKey)
        } else {
            binding.fieldTextVersion(fieldId)
        }
    }

    private func currentDraftText(): String {
        return if (instanceKey.size > 0) {
            binding.draftText(fieldId, instanceKey)
        } else {
            binding.draftText(fieldId)
        }
    }

    // ---- CjguiRangeTextSource ----

    public func rangeTextVersion(): Int64 {
        if (!retiredReason().isEmpty()) {
            return -1
        }
        return currentTextVersion()
    }

    public func confirmRangeTextVersion(expectedVersion: Int64, action: () -> Bool): Bool {
        if (!retiredReason().isEmpty()) {
            return false
        }
        return if (instanceKey.size > 0) {
            binding.confirmFieldTextVersion(fieldId, expectedVersion, action, instanceKey)
        } else {
            binding.confirmFieldTextVersion(fieldId, expectedVersion, action)
        }
    }

    public func rebaseRangeTextSelection(fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        // The provider owns the mapping decision, including a refusal. The
        // bridge never substitutes a generic caret policy for None.
        if (!retiredReason().isEmpty()) {
            return None
        }
        return if (instanceKey.size > 0) {
            binding.rebaseFieldTextSelection(fieldId, fromVersion, startByte, endByte, instanceKey)
        } else {
            binding.rebaseFieldTextSelection(fieldId, fromVersion, startByte, endByte)
        }
    }

    public func rangeTextByteLength(): Int64 {
        if (!retiredReason().isEmpty()) {
            return 0
        }
        return cjguiUtf8Length(currentDraftText())
    }

    public func readRangeText(startByte: Int64, maxBytes: Int64): CjguiRangeTextSlice {
        let retired = retiredReason()
        if (!retired.isEmpty()) {
            return CjguiRangeTextSlice(startByte, startByte, "", -1, 0, false, retired)
        }
        let version = currentTextVersion()
        let current = currentDraftText()
        let bytes = current.toArray()
        var start = startByte
        if (start < 0) {
            start = 0
        }
        if (start > bytes.size) {
            start = bytes.size
        }
        // 源契约：起点可前移到下一个标量边界；尾端只保留完整标量。
        start = cjguiAlignToUtf8Boundary(bytes, start)
        var limit = start + maxBytes
        if (limit > bytes.size) {
            limit = bytes.size
        }
        if (limit < start) {
            limit = start
        }
        let validEnd = cjguiValidUtf8End(bytes, start, limit)
        return CjguiRangeTextSlice(
            startByte,
            start,
            sliceByBytes(current, start, validEnd),
            version,
            bytes.size,
            true,
            "")
    }

    // ---- CjguiRangeTextEditSink ----

    public func applyRangeTextEdit(
        baseVersion: Int64,
        startByte: Int64,
        endByte: Int64,
        inserted: String): CjguiRangeTextEditOutcome {
        let retired = retiredReason()
        if (!retired.isEmpty()) {
            return CjguiRangeTextEditOutcome.rejected(baseVersion, retired)
        }
        // owner 版本已前进（外部改版/其他编辑面写入）：按冲突拒绝，会话镜像
        // 重建后以新版本重试；不以旧版本的坐标改写新正文。
        if (currentTextVersion() != baseVersion) {
            return CjguiRangeTextEditOutcome.conflict(baseVersion, "owner_version_moved")
        }
        let current = currentDraftText()
        let bytes = current.toArray()
        if (startByte < 0 || endByte < startByte || endByte > bytes.size) {
            return CjguiRangeTextEditOutcome.rejected(baseVersion, "invalid_range")
        }
        if (!cjguiIsUtf8Boundary(bytes, startByte) || !cjguiIsUtf8Boundary(bytes, endByte)) {
            return CjguiRangeTextEditOutcome.rejected(baseVersion, CJGUI_RANGE_TEXT_REASON_NOT_BOUNDARY)
        }
        // 范围语义在桥内兑现：按 baseVersion 现值精确重组完整新值，owner 只做
        // 版本校验 + 整体应用（事务原子性归 owner）。
        let prefix = sliceByBytes(current, 0, startByte)
        let suffix = sliceByBytes(current, endByte, bytes.size)
        let newText = prefix + inserted + suffix
        return if (instanceKey.size > 0) {
            binding.applyTextEdit(fieldId, baseVersion, newText, instanceKey)
        } else {
            binding.applyTextEdit(fieldId, baseVersion, newText)
        }
    }

    /// 按字节区间切片（两端必须已是标量边界），以标量串接保持 UTF-8 精确。
    private func sliceByBytes(value: String, startByte: Int64, endByte: Int64): String {
        if (startByte >= endByte) {
            return ""
        }
        let builder = StringBuilder()
        var cursor: Int64 = 0
        for (rune in value.runes()) {
            let width = Int64(rune.toString().toArray().size)
            if (cursor >= endByte) {
                break
            }
            if (cursor + width <= startByte) {
                cursor += width
                continue
            }
            builder.append(rune)
            cursor += width
        }
        return builder.toString()
    }
}
