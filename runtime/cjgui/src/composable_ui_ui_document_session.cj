// One explicit document workspace session: save, preview, confirm, cancel and
// restore ONE portable `cjgui.ui-document` against the current accepted region.
//
// The session owns an OPERATION RECORD, never a candidate result. A preview is
// an immutable fact set (baseline, file, candidate, complete expected document,
// policy, diff). A confirm submits that one candidate and records its token.
// Settlement is queried from the region/holder ticket, so identical bytes from
// another operation can never be mistaken for this attempt.
package cjgui

import std.collection.*
import std.fs.*
import std.sync.*

public let CJGUI_UI_DOCUMENT_POLICY_MERGE = "merge"
public let CJGUI_UI_DOCUMENT_POLICY_REPLACE = "replace"
private let uiDocumentSurfaceIdentityLock = Mutex()
private var uiDocumentSurfaceIdentityNext: Int64 = 1

/// A nonzero, process-local identity for a document surface. It is not a
/// persistent or cross-process capability; it only prevents one session from
/// silently re-targeting another region.
public func cjguiNextUiDocumentSurfaceIdentity(): Int64 {
    synchronized(uiDocumentSurfaceIdentityLock) {
        let value = uiDocumentSurfaceIdentityNext
        uiDocumentSurfaceIdentityNext += 1
        return value
    }
}

/// The uniform submission/observation face the session needs. The window
/// region and an application-owned generated region expose the same accepted
/// document, versioned candidate submission and ticket read.
public class CjguiUiDocumentSubmit {
    public let accepted: Bool
    public let reason: String
    public let token: Int64

    public init(accepted: Bool, reason: String, token: Int64) {
        this.accepted = accepted
        this.reason = reason
        this.token = token
    }
}

/// One accepted structure version.
public class CjguiUiDocumentTicket {
    public let token: Int64
    public let known: Bool
    /// "PENDING" | "ACCEPTED" | "SUPERSEDED" | "REJECTED" | "UNKNOWN".
    public let terminalState: String
    public let sceneState: String
    public let reason: String
    public let acceptedVersion: Int64
    public let currentVersion: Int64
    public let currentDigest: String

    public init(token: Int64, known: Bool, terminalState: String, sceneState: String, reason: String,
        acceptedVersion: Int64, currentVersion: Int64, currentDigest: String) {
        this.token = token
        this.known = known
        this.terminalState = terminalState
        this.sceneState = sceneState
        this.reason = reason
        this.acceptedVersion = acceptedVersion
        this.currentVersion = currentVersion
        this.currentDigest = currentDigest
    }
}

public interface CjguiUiDocumentSurface {
    func acceptedUiDocument(): CjguiGeneratedUiAcceptedDocument
    /// Optional cheap revision check for an enabled history's ordinary turn.
    /// Actions still compare a full accepted version/digest fact before submit.
    func acceptedUiDocumentVersion(): Int64 { return acceptedUiDocument().version }
    /// Empty means no mount conflict. Custom legacy surfaces can keep their
    /// local workflow without publishing an external history provider.
    func attachUiDocumentWorkspace(workspace: CjguiUiDocumentWorkspace): String { return "" }
    func detachUiDocumentWorkspace(workspace: CjguiUiDocumentWorkspace): Unit {}
    func submitUiDocument(candidate: String, expectedVersion: Int64): CjguiUiDocumentSubmit
    /// A read-only ticket observation. The default reports UNKNOWN, which the
    /// session treats as still pending - never as success. Production regions
    /// answer from the holder's real candidate record under the same lock as
    /// the accepted document.
    func uiDocumentTicket(token: Int64): CjguiUiDocumentTicket {
        let accepted = acceptedUiDocument()
        return CjguiUiDocumentTicket(token, false, "UNKNOWN", "none", "", 0, accepted.version, accepted.digest)
    }
    /// Stable identity for this surface. Unknown/zero identities cannot be
    /// used as a wildcard by a session.
    func uiDocumentSurfaceIdentity(): Int64 {
        return 0
    }
}

extend CjguiGeneratedUiWindowRegion <: CjguiUiDocumentSurface {
    public func acceptedUiDocumentVersion(): Int64 { return acceptedStructureVersion() }
    public func submitUiDocument(candidate: String, expectedVersion: Int64): CjguiUiDocumentSubmit {
        let submitted = submitStructure(candidate, expectedVersion)
        return CjguiUiDocumentSubmit(submitted.candidateAccepted, submitted.reason, submitted.candidateToken)
    }

    public func uiDocumentTicket(token: Int64): CjguiUiDocumentTicket {
        return uiDocumentTicketSnapshot(token)
    }
}

public class CjguiUiDocumentSessionResult {
    public let applied: Bool
    public let reason: String
    public let detail: String
    public let submitted: Bool
    /// True only when THIS ticket was accepted at the exact expected version
    /// and no later accepted update has replaced it.
    public let accepted: Bool
    /// Immutable operation provenance. Unknown/unsubmitted versions stay -1;
    /// fileDigest is the observed file, never an inferred current digest.
    public let token: Int64
    public let path: String
    public let version: Int64
    public let fileDigest: String
    public let startup: Bool

    public init(applied: Bool, reason: String, detail!: String = "", submitted!: Bool = false, accepted!: Bool = false,
        token!: Int64 = 0, path!: String = "", version!: Int64 = -1, fileDigest!: String = "", startup!: Bool = false) {
        this.applied = applied
        this.reason = reason
        this.detail = detail
        this.submitted = submitted
        this.accepted = accepted
        this.token = token
        this.path = path
        this.version = version
        this.fileDigest = fileDigest
        this.startup = startup
    }
}

/// The full result of one preview. `expectedText` is the COMPLETE accepted
/// document this operation would produce; `candidateText` is exactly what is
/// submitted (merge may omit retained definitions; replace adds REMOVE lines).
public class CjguiUiDocumentPreview {
    public let acceptedVersion: Int64
    public let acceptedDigest: String
    public let fileDigest: String
    public let policy: String
    public let candidateText: String
    public let candidateDigest: String
    public let expectedText: String
    public let expectedDigest: String
    public let expectedVersion: Int64
    public let removals: ArrayList<String>
    public let diff: ArrayList<String>
    public let changed: Bool

    public init(acceptedVersion: Int64, acceptedDigest: String, fileDigest: String, policy: String,
        candidateText: String, candidateDigest: String, expectedText: String, expectedDigest: String,
        expectedVersion: Int64, removals: ArrayList<String>, diff: ArrayList<String>, changed: Bool) {
        this.acceptedVersion = acceptedVersion
        this.acceptedDigest = acceptedDigest
        this.fileDigest = fileDigest
        this.policy = policy
        this.candidateText = candidateText
        this.candidateDigest = candidateDigest
        this.expectedText = expectedText
        this.expectedDigest = expectedDigest
        this.expectedVersion = expectedVersion
        this.removals = removals
        this.diff = diff
        this.changed = changed
    }
}

public class CjguiUiDocumentSessionState {
    public let path: String
    public let savedDigest: String
    public let savedBaseline: Int64
    public let acceptedVersion: Int64
    public let acceptedDigest: String
    /// "idle" | "preview" | "submitted".
    public let mode: String
    public let token: Int64
    public let ticketState: String
    public let ticketReason: String
    public let lastResult: String
    public let unsaved: Bool
    public let preview: ?CjguiUiDocumentPreview
    public let history: ?CjguiUiDocumentHistoryState

    public init(path: String, savedDigest: String, savedBaseline: Int64, acceptedVersion: Int64, acceptedDigest: String,
        mode: String, token: Int64, ticketState: String, ticketReason: String, lastResult: String, unsaved: Bool,
        preview: ?CjguiUiDocumentPreview, history!: ?CjguiUiDocumentHistoryState = None) {
        this.path = path
        this.savedDigest = savedDigest
        this.savedBaseline = savedBaseline
        this.acceptedVersion = acceptedVersion
        this.acceptedDigest = acceptedDigest
        this.mode = mode
        this.token = token
        this.ticketState = ticketState
        this.ticketReason = ticketReason
        this.lastResult = lastResult
        this.unsaved = unsaved
        this.preview = preview
        this.history = history
    }
}

public class CjguiUiDocumentActionState {
    public let action: String
    public let label: String
    public let enabled: Bool
    public let disabledReason: String

    public init(action: String, label: String, enabled: Bool, disabledReason!: String = "") {
        this.action = action
        this.label = label
        this.enabled = enabled
        this.disabledReason = disabledReason
    }
}

/// One read-only close decision the application combines with its OWN business
/// close policy. The framework never applies the business decision itself.
public class CjguiUiDocumentCloseDecision {
    public let canClose: Bool
    public let reason: String
    public let options: String

    public init(canClose: Bool, reason: String, options: String) {
        this.canClose = canClose
        this.reason = reason
        this.options = options
    }
}

/// Atomic temp-file + rename. `overwrite=true` REPLACES an existing target in
/// one step (used only after the caller verified the current bytes); a new
/// file is published with `overwrite=false`, the strongest no-clobber
/// semantics the existing file API offers, so a target that appears between
/// the check and the rename fails the write instead of being clobbered.
/// A pre-read digest plus rename is cooperative, not an atomic CAS against
/// arbitrary concurrent external writers; the session's named refusals keep
/// the honest boundary visible.
private func uiDocumentAtomicWrite(path: String, text: String, overwrite!: Bool = true): String {
    if (path.size == 0) {
        return "ui_document_path_empty"
    }
    let target = Path(path)
    let directory = target.parent
    if (!exists(directory)) {
        return "ui_document_path"
    }
    var temporary: ?Path = None
    try {
        let created = Directory.createTemp(directory)
        temporary = Some(created)
        let temporaryPath = created.join("cjgui-ui-document")
        File.writeTo(temporaryPath, text.toArray())
        rename(temporaryPath, to: target, overwrite: overwrite)
        let _ = removeIfExists(created, recursive: true)
        temporary = None
        return ""
    } catch (_) {
        if (let Some(created) <- temporary) {
            try {
                let _ = removeIfExists(created, recursive: true)
            } catch (_) {}
        }
        return if (overwrite) {
            "ui_document_write_failed"
        } else {
            "ui_document_write_failed_target_busy"
        }
    }
}

private func sortStrings(values: ArrayList<String>): Unit {
    for (index in 1..values.size) {
        let value = values[index]
        var position = index
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1]
            position -= 1
        }
        values[position] = value
    }
}

private func uiDocUtf8Continuation(byte: UInt8): Bool {
    return (byte & 0xC0u8) == 0x80u8
}

/// Largest byte index <= limit that does not split a UTF-8 scalar.
private func uiDocUtf8PrefixEnd(bytes: Array<UInt8>, limit: Int64): Int64 {
    if (limit >= bytes.size) {
        return bytes.size
    }
    var end = if (limit < 0) {
        0
    } else {
        limit
    }
    while (end > 0 && uiDocUtf8Continuation(bytes[end])) {
        end -= 1
    }
    return end
}

/// Smallest byte index >= start that begins a UTF-8 scalar.
private func uiDocUtf8Start(bytes: Array<UInt8>, start: Int64): Int64 {
    var position = if (start < 0) {
        0
    } else {
        start
    }
    while (position < bytes.size && uiDocUtf8Continuation(bytes[position])) {
        position += 1
    }
    return position
}

private func uiDocUtf8Prefix(bytes: Array<UInt8>, limit: Int64): String {
    let end = uiDocUtf8PrefixEnd(bytes, limit)
    if (end <= 0) {
        return ""
    }
    return String.fromUtf8(bytes.slice(0, end))
}

private func uiDocUtf8Window(bytes: Array<UInt8>, start: Int64, limit: Int64): String {
    if (limit <= 0) {
        return ""
    }
    let first = uiDocUtf8Start(bytes, start)
    if (first >= bytes.size) {
        return ""
    }
    let end = uiDocUtf8PrefixEnd(bytes, first + limit)
    if (end <= first) {
        return ""
    }
    return String.fromUtf8(bytes.slice(first, end - first))
}

/// Stable DISPLAY-ONLY fingerprint used to distinguish long values whose
/// bounded excerpts happen to coincide. It never feeds a signature or equality.
private func uiDocDisplayFingerprint(bytes: Array<UInt8>): String {
    var hash: Int64 = 2166136261
    for (byte in bytes) {
        hash = ((hash ^ Int64(byte)) * 16777619) & 0xFFFFFFFF
    }
    let digits = "0123456789abcdef"
    var result = ""
    var shift: Int64 = 28
    while (shift >= 0) {
        result += String.fromUtf8([digits.toArray()[(hash >> shift) & 0xF]])
        shift -= 4
    }
    return result
}

/// Machine digests are ASCII; non-ASCII input is clamped at a legal boundary so
/// callers can never throw just by rendering an identifier.
private func uiDocShort(value: String): String {
    if (value.size <= 12) {
        return value
    }
    let bytes = value.toArray()
    return uiDocUtf8Prefix(bytes, 12) + "…"
}

/// DISPLAY ONLY. An empty string is rendered visibly distinct from any literal
/// text the same field could carry (including the literal "空"). This function
/// must never feed a signature or an equality decision; machine facts use
/// `uiDocFactValue`.
private func uiDocDisplayValue(value: String): String {
    if (value.size == 0) {
        return "<空字符串>"
    }
    let bytes = value.toArray()
    if (bytes.size <= 24) {
        return value
    }
    let head = uiDocUtf8Prefix(bytes, 12)
    let middle = uiDocUtf8Window(bytes, bytes.size / 2, 8)
    let tailStart = bytes.size - 8
    let tail = uiDocUtf8Window(bytes, tailStart, 8)
    return "${head}…${middle}…${tail}（共${bytes.size}字节 #${uiDocDisplayFingerprint(bytes)}）"
}

/// DISPLAY ONLY for a changed pair. When a value is long, show the first
/// differing window (after the common prefix) on both sides, so a long shared
/// prefix cannot make two different values render as the same string.
private func uiDocDisplayPair(before: String, after: String): (String, String) {
    if (before.size <= 24 && after.size <= 24) {
        return (uiDocDisplayValue(before), uiDocDisplayValue(after))
    }
    let a = before.toArray()
    let b = after.toArray()
    var common: Int64 = 0
    while (common < a.size && common < b.size && a[common] == b[common]) {
        common += 1
    }
    let boundary = uiDocUtf8PrefixEnd(a, common)
    let prefix = uiDocUtf8Prefix(a, if (boundary < 12) {
        boundary
    } else {
        12
    })
    // Include a little context BEFORE the first difference: showing only the
    // differing scalar is legal but not understandable when the tail still
    // shares most of its text.
    let contextStart = uiDocUtf8Start(a, if (boundary > 8) {
        boundary - 8
    } else {
        0
    })
    let beforeWindow = uiDocUtf8Window(a, contextStart, 16)
    let afterContextStart = uiDocUtf8Start(b, if (boundary > 8) {
        boundary - 8
    } else {
        0
    })
    let afterWindow = uiDocUtf8Window(b, afterContextStart, 16)
    return ("${prefix}…${beforeWindow}…（共${a.size}字节）", "${prefix}…${afterWindow}…（共${b.size}字节）")
}

/// LOSSLESS machine fact for ONE string field. The byte-length prefix is
/// self-delimiting, so distinct values always encode distinctly: "" / "空" /
/// "none" / values carrying separators or Chinese text can never collide
/// inside a concatenated signature, whatever separators the signature uses.
private func uiDocFactValue(value: String): String {
    return "${value.size}:${value}"
}

// --- complete semantic facts ------------------------------------------------

private func uiDocParameterFact(parameter: CjguiCompositionParameter): String {
    return "name=${uiDocFactValue(parameter.name)} type=${uiDocFactValue(parameter.valueType)} " +
        "required=${parameter.required} " +
        "min=${parameter.minimum} max=${parameter.maximum} maxLength=${parameter.maxLength} " +
        "default=${uiDocFactValue(parameter.defaultValue)}"
}

private func uiDocElementFact(element: CjguiCompositeElementSpec): String {
    return "key=${uiDocFactValue(element.elementKey)} role=${uiDocFactValue(element.role)} " +
        "field=${uiDocFactValue(element.fieldId)} " +
        "argument=${uiDocFactValue(element.argumentName)} preset=${uiDocFactValue(element.presetValue)} " +
        "action=${uiDocFactValue(element.actionName)} source=${uiDocFactValue(element.source)} " +
        "label=${uiDocFactValue(element.label)}"
}

private func uiDocTemplateFact(node: CjguiCompositionTemplateNode): String {
    return "key=${uiDocFactValue(node.key)} kind=${uiDocFactValue(node.kind)} " +
        "element=${uiDocFactValue(node.elementKey)} " +
        "presentation=${uiDocFactValue(node.presentation)} text=${uiDocFactValue(node.text)} " +
        "style=${uiDocFactValue(node.styleName)} gap=${node.gap} padding=${node.padding} " +
        "fixedHeight=${node.fixedHeight} growX=${node.growX} axis=${uiDocFactValue(node.axis)} " +
        "firstSize=${node.firstSize} minFirst=${node.minFirst} minSecond=${node.minSecond}"
}

private func uiDocDiffField(lines: ArrayList<String>, indent: String, label: String, before: String, after: String): Unit {
    if (before != after) {
        let (beforeText, afterText) = uiDocDisplayPair(before, after)
        lines.add("${indent}${label}: ${beforeText} -> ${afterText}")
    }
}

private func uiDocTemplateChildren(node: CjguiCompositionTemplateNode): HashMap<String, CjguiCompositionTemplateNode> {
    let result = HashMap<String, CjguiCompositionTemplateNode>()
    for (child in node.children) {
        result.add(child.key, child)
    }
    return result
}

private func uiDocDiffTemplate(lines: ArrayList<String>, indent: String, before: CjguiCompositionTemplateNode,
    after: CjguiCompositionTemplateNode): Unit {
    uiDocDiffField(lines, indent, "模板 ${after.key} 种类", before.kind, after.kind)
    uiDocDiffField(lines, indent, "模板 ${after.key} 元素", before.elementKey, after.elementKey)
    uiDocDiffField(lines, indent, "模板 ${after.key} 呈现", before.presentation, after.presentation)
    uiDocDiffField(lines, indent, "模板 ${after.key} 文本", before.text, after.text)
    uiDocDiffField(lines, indent, "模板 ${after.key} 样式", before.styleName, after.styleName)
    uiDocDiffField(lines, indent, "模板 ${after.key} gap", "${before.gap}", "${after.gap}")
    uiDocDiffField(lines, indent, "模板 ${after.key} padding", "${before.padding}", "${after.padding}")
    uiDocDiffField(lines, indent, "模板 ${after.key} fixedHeight", "${before.fixedHeight}", "${after.fixedHeight}")
    uiDocDiffField(lines, indent, "模板 ${after.key} growX", "${before.growX}", "${after.growX}")
    uiDocDiffField(lines, indent, "模板 ${after.key} axis", before.axis, after.axis)
    uiDocDiffField(lines, indent, "模板 ${after.key} firstSize", "${before.firstSize}", "${after.firstSize}")
    uiDocDiffField(lines, indent, "模板 ${after.key} minFirst", "${before.minFirst}", "${after.minFirst}")
    uiDocDiffField(lines, indent, "模板 ${after.key} minSecond", "${before.minSecond}", "${after.minSecond}")
    let beforeChildren = uiDocTemplateChildren(before)
    let afterChildren = uiDocTemplateChildren(after)
    for (child in after.children) {
        if (let Some(old) <- beforeChildren.get(child.key)) {
            uiDocDiffTemplate(lines, indent + "  ", old, child)
        } else {
            lines.add("${indent}添加模板 ${child.key}: ${uiDocTemplateFact(child)}")
        }
    }
    for (child in before.children) {
        if (!afterChildren.contains(child.key)) {
            lines.add("${indent}移除模板 ${child.key}: ${uiDocTemplateFact(child)}")
        }
    }
    let shared = if (before.children.size < after.children.size) {
        before.children.size
    } else {
        after.children.size
    }
    var index: Int64 = 0
    while (index < shared) {
        if (before.children[index].key != after.children[index].key) {
            lines.add("${indent}模板顺序 ${index}: ${before.children[index].key} -> " + "${after.children[index].key}")
        }
        index += 1
    }
}

private func uiDocDiffDefinition(lines: ArrayList<String>, before: CjguiRuntimeCompositionDefinition,
    after: CjguiRuntimeCompositionDefinition): Unit {
    lines.add("修改定义 ${after.name}")
    let beforeParameters = HashMap<String, CjguiCompositionParameter>()
    for (parameter in before.parameters) {
        beforeParameters.add(parameter.name, parameter)
    }
    let afterParameters = HashMap<String, CjguiCompositionParameter>()
    for (parameter in after.parameters) {
        afterParameters.add(parameter.name, parameter)
    }
    for (parameter in after.parameters) {
        if (let Some(old) <- beforeParameters.get(parameter.name)) {
            uiDocDiffField(lines, "  ", "参数 ${parameter.name} 类型", old.valueType, parameter.valueType)
            uiDocDiffField(lines, "  ", "参数 ${parameter.name} 必填", "${old.required}", "${parameter.required}")
            uiDocDiffField(lines, "  ", "参数 ${parameter.name} 范围", "${old.minimum}..${old.maximum}",
                "${parameter.minimum}..${parameter.maximum}")
            uiDocDiffField(lines, "  ", "参数 ${parameter.name} 最大长度", "${old.maxLength}", "${parameter.maxLength}")
            uiDocDiffField(lines, "  ", "参数 ${parameter.name} 默认值", old.defaultValue, parameter.defaultValue)
        } else {
            lines.add("  添加参数 ${uiDocParameterFact(parameter)}")
        }
    }
    for (parameter in before.parameters) {
        if (!afterParameters.contains(parameter.name)) {
            lines.add("  移除参数 ${uiDocParameterFact(parameter)}")
        }
    }
    let beforeElements = HashMap<String, CjguiCompositeElementSpec>()
    for (element in before.elements) {
        beforeElements.add(element.elementKey, element)
    }
    let afterElements = HashMap<String, CjguiCompositeElementSpec>()
    for (element in after.elements) {
        afterElements.add(element.elementKey, element)
    }
    for (element in after.elements) {
        if (let Some(old) <- beforeElements.get(element.elementKey)) {
            let oldFact = uiDocElementFact(old)
            let newFact = uiDocElementFact(element)
            if (oldFact != newFact) {
                lines.add("  元素 ${element.elementKey}: ${oldFact} -> ${newFact}")
            }
        } else {
            lines.add("  添加元素 ${uiDocElementFact(element)}")
        }
    }
    for (element in before.elements) {
        if (!afterElements.contains(element.elementKey)) {
            lines.add("  移除元素 ${uiDocElementFact(element)}")
        }
    }
    let sameTemplate = uiDocTemplateFact(before.template) == uiDocTemplateFact(after.template) &&
        uiDocTemplateSignature(before.template) == uiDocTemplateSignature(after.template)
    if (!sameTemplate) {
        uiDocDiffTemplate(lines, "  ", before.template, after.template)
    }
    uiDocDiffField(lines, "  ", "定义 ${after.name} 节点上限", "${before.expandedNodeLimit}",
        "${after.expandedNodeLimit}")
    uiDocDiffField(lines, "  ", "定义 ${after.name} 深度上限", "${before.expandedDepthLimit}",
        "${after.expandedDepthLimit}")
}

private func uiDocTemplateSignature(node: CjguiCompositionTemplateNode): String {
    let builder = StringBuilder()
    builder.append("[${uiDocTemplateFact(node)}")
    for (child in node.children) {
        builder.append(uiDocTemplateSignature(child))
    }
    builder.append("]")
    return builder.toString()
}

private class CjguiUiDocumentNodeFact {
    let key: String
    let parent: String
    let index: Int64
    let kind: String
    let fieldId: String
    let actionName: String
    let properties: HashMap<String, String>

    init(key: String, parent: String, index: Int64, kind: String, fieldId: String, actionName: String,
        properties: HashMap<String, String>) {
        this.key = key
        this.parent = parent
        this.index = index
        this.kind = kind
        this.fieldId = fieldId
        this.actionName = actionName
        this.properties = properties
    }
}

private func uiDocCollectNode(node: CjguiGeneratedUiNodeSpec, parent: String, index: Int64,
    facts: HashMap<String, CjguiUiDocumentNodeFact>, order: ArrayList<String>): Unit {
    // Copy: the decoded tree is immutable here, but the fact set must not share
    // a mutable map with a later decode.
    let properties = HashMap<String, String>()
    for ((name, value) in node.properties) {
        properties.add(name, value)
    }
    facts.add(node.key, CjguiUiDocumentNodeFact(node.key, parent, index, node.kind, node.fieldId, node.actionName,
        properties))
    order.add(node.key)
    var childIndex: Int64 = 0
    for (child in node.children) {
        uiDocCollectNode(child, node.key, childIndex, facts, order)
        childIndex += 1
    }
}

/// Human-readable, complete preview of what a file would change. It is a
/// derived view, never an authority: confirm rebuilds this SAME semantic plan
/// from the current accepted document and file before submitting.
public func cjguiUiDocumentDiffLines(acceptedText: String, fileText: String): ArrayList<String> {
    let lines = ArrayList<String>()
    let accepted = CjguiGeneratedUiEncoding.decode(acceptedText)
    let incoming = CjguiGeneratedUiEncoding.decode(fileText)
    if (!accepted.ok || !incoming.ok) {
        lines.add("结构无法解析：accepted=${accepted.reason} file=${incoming.reason}")
        return lines
    }
    let acceptedDefinitions = HashMap<String, CjguiRuntimeCompositionDefinition>()
    let acceptedDefinitionOrder = ArrayList<String>()
    for (payload in accepted.definitions) {
        acceptedDefinitions.add(payload.definition.name, payload.definition)
        acceptedDefinitionOrder.add(payload.definition.name)
    }
    let incomingDefinitions = HashMap<String, CjguiRuntimeCompositionDefinition>()
    let incomingDefinitionOrder = ArrayList<String>()
    for (payload in incoming.definitions) {
        incomingDefinitions.add(payload.definition.name, payload.definition)
        incomingDefinitionOrder.add(payload.definition.name)
    }
    for (name in incomingDefinitionOrder) {
        if (let Some(old) <- acceptedDefinitions.get(name)) {
            let next = incomingDefinitions.get(name).getOrThrow()
            if (uiDocDefinitionSignature(old) != uiDocDefinitionSignature(next)) {
                uiDocDiffDefinition(lines, old, next)
            } else {
                lines.add("保留定义 ${name}")
            }
        } else {
            lines.add("添加定义 ${name}")
        }
    }
    for (name in acceptedDefinitionOrder) {
        if (!incomingDefinitions.contains(name)) {
            lines.add("移除定义 ${name}")
        }
    }

    let acceptedNodes = HashMap<String, CjguiUiDocumentNodeFact>()
    let acceptedOrder = ArrayList<String>()
    if (let Some(root) <- accepted.root) {
        uiDocCollectNode(root, "$root", 0, acceptedNodes, acceptedOrder)
    }
    let incomingNodes = HashMap<String, CjguiUiDocumentNodeFact>()
    let incomingOrder = ArrayList<String>()
    if (let Some(root) <- incoming.root) {
        uiDocCollectNode(root, "$root", 0, incomingNodes, incomingOrder)
    }
    for (key in incomingOrder) {
        let next = incomingNodes.get(key).getOrThrow()
        if (let Some(old) <- acceptedNodes.get(key)) {
            if (old.parent != next.parent) {
                lines.add("移动节点 ${key}：${old.parent} -> ${next.parent}")
            } else if (old.index != next.index) {
                lines.add("重排节点 ${key}：${old.index} -> ${next.index}")
            }
            uiDocDiffField(lines, "  ", "节点 ${key} 种类", old.kind, next.kind)
            uiDocDiffField(lines, "  ", "节点 ${key} 字段", old.fieldId, next.fieldId)
            uiDocDiffField(lines, "  ", "节点 ${key} 动作", old.actionName, next.actionName)
            let names = ArrayList<String>()
            for (name in old.properties.keys()) {
                names.add(name)
            }
            for (name in next.properties.keys()) {
                if (!old.properties.contains(name)) {
                    names.add(name)
                }
            }
            sortStrings(names)
            for (name in names) {
                let before = match (old.properties.get(name)) {
                    case Some(value) => value
                    case None => ""
                }
                let after = match (next.properties.get(name)) {
                    case Some(value) => value
                    case None => ""
                }
                if (!old.properties.contains(name)) {
                    lines.add("  节点 ${key} 新增属性 ${name}=${uiDocDisplayValue(after)}")
                } else if (!next.properties.contains(name)) {
                    lines.add("  节点 ${key} 移除属性 ${name}（原 ${uiDocDisplayValue(before)}）")
                } else if (before != after) {
                    let (beforeText, afterText) = uiDocDisplayPair(before, after)
                    lines.add("  节点 ${key} 属性 ${name}：${beforeText} -> " + "${afterText}")
                }
            }
        } else {
            lines.add("添加节点 ${key}（父 ${next.parent}，位置 ${next.index}，${next.kind}）")
        }
    }
    for (key in acceptedOrder) {
        if (!incomingNodes.contains(key)) {
            let old = acceptedNodes.get(key).getOrThrow()
            lines.add("移除节点 ${key}（父 ${old.parent}）")
        }
    }
    // Same key/same parent but a different sibling ORDER is a real scene
    // change even when every node fact is equal.
    for (key in acceptedOrder) {
        if (!incomingNodes.contains(key)) {
            continue
        }
        let old = acceptedNodes.get(key).getOrThrow()
        let next = incomingNodes.get(key).getOrThrow()
        if (old.parent == next.parent && old.index != next.index) {
            // Already reported above; this loop exists to make the rule explicit
            // for a reorder where no other fact changed.
        }
    }
    lines.add("节点数 ${acceptedOrder.size} -> ${incomingOrder.size}")
    if (!uiDocDiffHasChanges(lines)) {
        // No semantic change: keep the fact list empty. Display text is a
        // presentation concern; callers must never infer change from it.
        lines.clear()
    }
    return lines
}

internal func uiDocDiffHasChanges(lines: ArrayList<String>): Bool {
    for (line in lines) {
        if (!line.startsWith("节点数 ") && !line.startsWith("保留定义 ")) {
            return true
        }
    }
    return false
}

private func uiDocDefinitionSignature(definition: CjguiRuntimeCompositionDefinition): String {
    let builder = StringBuilder()
    builder.append(
        "${uiDocFactValue(definition.name)}|${definition.expandedNodeLimit}|" + "${definition.expandedDepthLimit}")
    for (parameter in definition.parameters) {
        builder.append("|${uiDocParameterFact(parameter)}")
    }
    for (element in definition.elements) {
        builder.append("|${uiDocElementFact(element)}")
    }
    builder.append("|${uiDocTemplateSignature(definition.template)}")
    return builder.toString()
}

// --- preview construction ---------------------------------------------------

private class CjguiUiDocumentPlan {
    let preview: CjguiUiDocumentPreview

    init(preview: CjguiUiDocumentPreview) {
        this.preview = preview
    }
}

private func uiDocBuildPlan(accepted: CjguiGeneratedUiAcceptedDocument, fileText: String, fileDigest: String,
    policy: String): CjguiUiDocumentPlan {
    let acceptedDecoded = CjguiGeneratedUiEncoding.decode(accepted.text)
    let fileDecoded = CjguiGeneratedUiEncoding.decode(fileText)
    if (!acceptedDecoded.ok || !fileDecoded.ok) {
        return CjguiUiDocumentPlan(
            CjguiUiDocumentPreview(accepted.version, accepted.digest, fileDigest, policy, "", "", "", "",
                accepted.version + 1, ArrayList<String>(),
                ArrayList<String>(["结构无法解析：accepted=${acceptedDecoded.reason} file=${fileDecoded.reason}"]),
                false))
    }
    let acceptedDefinitions = ArrayList<CjguiRuntimeCompositionDefinition>()
    for (payload in acceptedDecoded.definitions) {
        acceptedDefinitions.add(payload.definition)
    }
    let fileDefinitions = ArrayList<CjguiRuntimeCompositionDefinition>()
    for (payload in fileDecoded.definitions) {
        fileDefinitions.add(payload.definition)
    }
    let fileNames = HashSet<String>()
    for (definition in fileDefinitions) {
        fileNames.add(definition.name)
    }
    let acceptedNames = HashSet<String>()
    for (definition in acceptedDefinitions) {
        acceptedNames.add(definition.name)
    }
    let expectedDefinitions = ArrayList<CjguiRuntimeCompositionDefinition>()
    let removals = ArrayList<String>()
    if (policy == CJGUI_UI_DOCUMENT_POLICY_REPLACE) {
        for (definition in fileDefinitions) {
            expectedDefinitions.add(definition)
        }
        for (definition in acceptedDefinitions) {
            if (!fileNames.contains(definition.name)) {
                removals.add(definition.name)
            }
        }
    } else {
        let fileByName = HashMap<String, CjguiRuntimeCompositionDefinition>()
        for (definition in fileDefinitions) {
            fileByName.add(definition.name, definition)
        }
        for (definition in acceptedDefinitions) {
            if (let Some(replacement) <- fileByName.get(definition.name)) {
                expectedDefinitions.add(replacement)
            } else {
                expectedDefinitions.add(definition)
            }
        }
        for (definition in fileDefinitions) {
            if (!acceptedNames.contains(definition.name)) {
                expectedDefinitions.add(definition)
            }
        }
    }
    let definitionsText = StringBuilder()
    for (definition in expectedDefinitions) {
        definitionsText.append(cjguiCompositionDefinitionPayload(definition))
    }
    let formatVersion = if (expectedDefinitions.size > 0) {
        2
    } else {
        1
    }
    let expectedText = CjguiGeneratedUiEncoding.encodeCandidate(fileDecoded.root, formatVersion,
        definitions: definitionsText.toString())
    let expectedDigest = cjguiUiDocumentDigest(expectedText)
    let diff = cjguiUiDocumentDiffLines(accepted.text, expectedText)
    let changed = uiDocDiffHasChanges(diff)
    let candidateText = if (policy == CJGUI_UI_DOCUMENT_POLICY_REPLACE && removals.size > 0) {
        let builder = StringBuilder()
        builder.append("GENERATED_UI_STRUCTURE ${formatVersion}\n")
        for (name in removals) {
            builder.append("COMPOSITION_REMOVE ${name}\n")
        }
        // Re-emit from the file body, not the old header, so the candidate is
        // exactly the file plus the explicit removals.
        var bodyStart = 0
        while (bodyStart < fileText.size && fileText[bodyStart] != UInt8(10)) {
            bodyStart += 1
        }
        if (bodyStart < fileText.size) {
            builder.append(fileText[bodyStart + 1..fileText.size])
        }
        builder.toString()
    } else {
        fileText
    }
    let candidateDigest = cjguiUiDocumentDigest(candidateText)
    return CjguiUiDocumentPlan(
        CjguiUiDocumentPreview(accepted.version, accepted.digest, fileDigest, policy, candidateText, candidateDigest,
            expectedText, expectedDigest, accepted.version + 1, removals, diff, changed))
}

private func uiDocSamePreview(left: CjguiUiDocumentPreview, right: CjguiUiDocumentPreview): Bool {
    if (left.acceptedVersion != right.acceptedVersion || left.acceptedDigest != right.acceptedDigest || left.policy != right
        .policy || left.candidateDigest != right.candidateDigest || left.expectedDigest != right.expectedDigest ||
        left.removals.size != right.removals.size) {
        return false
    }
    var index: Int64 = 0
    while (index < left.removals.size) {
        if (left.removals[index] != right.removals[index]) {
            return false
        }
        index += 1
    }
    return true
}

public class CjguiGeneratedUiDocumentSession {
    private let lock = Mutex()
    private var pathValue: String
    private var savedDigestValue: String = ""
    private var savedBaselineValue: Int64 = -1
    /// "idle" | "preview" | "submitted".
    private var modeValue: String = "idle"
    private var previewValue: ?CjguiUiDocumentPreview = None
    private var previewPathValue: String = ""
    private var submittedTokenValue: Int64 = 0
    // Provenance of the existing submitted operation, not another ticket or
    // lifecycle state machine. Close and ordinary turns publish the SAME fact.
    private var submittedFromStartup: Bool = false
    private let historyValue: ?CjguiUiDocumentHistory
    private var submittedHistoryActionValue: String = ""
    private var submittedHistoryEpochValue: Int64 = 0
    private var submittedHistoryTargetValue: Int64 = -1
    private var lastStartupResult = CjguiUiDocumentSessionResult(false, "ui_document_no_submission", startup: true)
    private var boundSurfaceIdValue: Int64 = 0
    private var lastResultValue: String = "尚未操作界面文件"
    private var lastFinish: CjguiUiDocumentSessionResult = CjguiUiDocumentSessionResult(false,
        "ui_document_no_submission", detail: "尚未提交界面载入")

    public init(path!: String = "", historyPolicy!: ?CjguiUiDocumentHistoryPolicy = None) {
        this.pathValue = path
        this.historyValue = match (historyPolicy) {
            case Some(policy) => Some(CjguiUiDocumentHistory(policy))
            case None => None
        }
    }

    public func historyEnabled(): Bool { return historyValue.isSome() }

    private func observeHistoryTurn(surface: CjguiUiDocumentSurface): Unit {
        let check = synchronized(lock) {
            match (historyValue) {
                case Some(history) => !history.closed && modeValue != "submitted" &&
                    history.headVersion != surface.acceptedUiDocumentVersion()
                case None => false
            }
        }
        if (!check) { return }
        let accepted = surface.acceptedUiDocument()
        synchronized(lock) {
            if (modeValue != "submitted") {
                if (let Some(history) <- historyValue) { history.observe(accepted) }
            }
        }
    }

    public func historyState(surface: CjguiUiDocumentSurface): CjguiUiDocumentHistoryState {
        if (!bindSurface(surface)) {
            return CjguiUiDocumentHistoryState(false, undoReason: "ui_document_surface_mismatch",
                redoReason: "ui_document_surface_mismatch")
        }
        if (historyValue.isNone()) {
            return CjguiUiDocumentHistoryState(false, surfaceIdentity: surface.uiDocumentSurfaceIdentity())
        }
        return stateFor(surface).history.getOrThrow()
    }

    /// An explicit session boundary. It does not save, apply or change the UI.
    public func resetHistory(surface: CjguiUiDocumentSurface, expectedVersion: Int64,
        expectedDigest: String): CjguiUiDocumentSessionResult {
        if (!bindSurface(surface)) { return surfaceMismatch() }
        let accepted = surface.acceptedUiDocument()
        return synchronized(lock) {
            if (modeValue != "idle") { return CjguiUiDocumentSessionResult(false, "ui_document_operation_pending") }
            let history = match (historyValue) {
                case Some(value) => value
                case None => return CjguiUiDocumentSessionResult(false, "ui_document_history_disabled")
            }
            if (history.closed) { return CjguiUiDocumentSessionResult(false, "ui_document_history_closed") }
            if (accepted.version != expectedVersion || accepted.digest != expectedDigest) {
                return CjguiUiDocumentSessionResult(false, "ui_document_history_baseline_changed")
            }
            history.reset(accepted, "ui_document_history_rebased")
            return CjguiUiDocumentSessionResult(true, "ui_document_history_rebased", version: accepted.version)
        }
    }

    /// Called when the owning session is actually disposed, not merely when
    /// a close guard asks whether closing would be legal. An in-flight region
    /// ticket remains observable, but its late result cannot move this ledger.
    public func closeHistory(surface: CjguiUiDocumentSurface): Unit {
        if (!bindSurface(surface)) { return }
        synchronized(lock) {
            if (let Some(history) <- historyValue) {
                if (!history.closed) {
                    history.clear("ui_document_history_closed")
                    history.closed = true
                }
            }
        }
    }

    public func performHistoryAction(surface: CjguiUiDocumentSurface, action: String): CjguiUiDocumentSessionResult {
        if (!bindSurface(surface)) { return surfaceMismatch() }
        if (!historyEnabled()) { return CjguiUiDocumentSessionResult(false, "ui_document_history_disabled") }
        let accepted = surface.acceptedUiDocument()
        return historyAction(surface, action, accepted.version, accepted.digest)
    }

    private func prepareHistoryOperation(action: String, expectedVersion: Int64, expectedDigest: String,
        expectedEpoch: Int64, accepted: CjguiGeneratedUiAcceptedDocument): ?CjguiUiDocumentSessionResult {
        return synchronized(lock) {
            if (modeValue != "idle") {
                return Some(CjguiUiDocumentSessionResult(false, "ui_document_operation_pending"))
            }
            let history = historyValue.getOrThrow()
            if (history.closed) { return Some(CjguiUiDocumentSessionResult(false, "ui_document_history_closed")) }
            history.observe(accepted)
            if (accepted.version != expectedVersion || accepted.digest != expectedDigest) {
                return Some(CjguiUiDocumentSessionResult(false, "ui_document_history_baseline_changed"))
            }
            if (expectedEpoch >= 0 && expectedEpoch != history.epoch) {
                return Some(CjguiUiDocumentSessionResult(false, "ui_document_history_epoch_changed"))
            }
            let target = history.target(action)
            if (target < 0) {
                let facts = history.state(boundSurfaceIdValue, accepted, modeValue, "", 0)
                return Some(CjguiUiDocumentSessionResult(false,
                    if (action == "UI_DOC_UNDO") { facts.undoReason } else { facts.redoReason }))
            }
            let plan = uiDocBuildPlan(accepted, history.snapshots[target].text, "",
                CJGUI_UI_DOCUMENT_POLICY_REPLACE).preview
            if (!plan.changed) { return Some(CjguiUiDocumentSessionResult(false, "ui_document_history_no_change")) }
            modeValue = "submitted"
            previewValue = Some(plan)
            previewPathValue = ""
            submittedTokenValue = 0
            submittedFromStartup = false
            submittedHistoryActionValue = action
            submittedHistoryEpochValue = history.epoch
            submittedHistoryTargetValue = target
            None
        }
    }

    /// Human and external CAS commands submit through this ONE operation
    /// record and finishReload. Nothing is popped when submit returns pending.
    public func historyAction(surface: CjguiUiDocumentSurface, action: String, expectedVersion: Int64,
        expectedDigest: String, expectedEpoch!: Int64 = -1): CjguiUiDocumentSessionResult {
        if (!bindSurface(surface)) { return surfaceMismatch() }
        if (action != "UI_DOC_UNDO" && action != "UI_DOC_REDO") {
            return CjguiUiDocumentSessionResult(false, "ui_document_history_unknown_action")
        }
        if (historyValue.isNone()) { return CjguiUiDocumentSessionResult(false, "ui_document_history_disabled") }
        let accepted = surface.acceptedUiDocument()
        let refused = prepareHistoryOperation(action, expectedVersion, expectedDigest, expectedEpoch, accepted)
        if (let Some(result) <- refused) { return result }
        let plan = synchronized(lock) { previewValue.getOrThrow() }
        let submitted = surface.submitUiDocument(plan.candidateText, plan.acceptedVersion)
        return synchronized(lock) {
            if (modeValue != "submitted" || submittedTokenValue != 0 || submittedHistoryActionValue != action) {
                return CjguiUiDocumentSessionResult(false, "ui_document_operation_replaced",
                    submitted: submitted.accepted, token: submitted.token,
                    version: if (submitted.accepted) { plan.expectedVersion } else { -1 })
            }
            if (!submitted.accepted) {
                modeValue = "idle"
                previewValue = None
                submittedHistoryActionValue = ""
                submittedHistoryTargetValue = -1
                lastResultValue = "界面历史候选被拒：${submitted.reason}"
                return CjguiUiDocumentSessionResult(false, "ui_document_rejected:${submitted.reason}",
                    detail: lastResultValue, token: submitted.token)
            }
            submittedTokenValue = submitted.token
            lastResultValue = "界面历史 ${action} 等待票据 ${submitted.token} 结算"
            return CjguiUiDocumentSessionResult(true, "submitted", detail: lastResultValue,
                submitted: true, token: submitted.token, version: plan.expectedVersion)
        }
    }

    /// A session belongs to ONE document surface for its lifetime. The first
    /// legitimate use binds it; a different surface is refused instead of
    /// silently submitting the same bytes to another region.
    private func bindSurface(surface: CjguiUiDocumentSurface): Bool {
        let identity = surface.uiDocumentSurfaceIdentity()
        if (identity <= 0) {
            return false
        }
        synchronized(lock) {
            if (boundSurfaceIdValue == 0) {
                boundSurfaceIdValue = identity
                return true
            }
            return boundSurfaceIdValue == identity
        }
    }

    public func isBoundTo(surface: CjguiUiDocumentSurface): Bool {
        return synchronized(lock) {
            boundSurfaceIdValue != 0 && boundSurfaceIdValue == surface.uiDocumentSurfaceIdentity()
        }
    }

    private func surfaceMismatch(): CjguiUiDocumentSessionResult {
        return finishRefusal("ui_document_surface_mismatch",
            "本会话已绑定另一界面区域，拒绝把本次操作改投到其他 Surface")
    }

    public func path(): String {
        return synchronized(lock) {
            pathValue
        }
    }

    /// Changes the save/load target only when no operation is in flight. An
    /// in-flight ticket is never silently discarded; the refusal is visible in
    /// the next status read.
    public func setPath(path: String): Unit {
        synchronized(lock) {
            if (modeValue == "submitted") {
                lastResultValue = "已提交载入，不能更换界面文件：token=${submittedTokenValue}"
                return
            }
            if (modeValue == "preview") {
                lastResultValue = "已有待确认预览，请先确认或取消后再更换界面文件"
                return
            }
            if (pathValue != path) {
                if (let Some(history) <- historyValue) { history.clear("ui_document_history_path_changed") }
                pathValue = path
                previewValue = None
                previewPathValue = ""
                // A different path has no known file content yet. The old
                // file's save fact must not represent the new target.
                savedDigestValue = ""
                savedBaselineValue = -1
                modeValue = "idle"
                lastResultValue = if (path.size > 0) {
                    "界面文件已设为 ${path}"
                } else {
                    "未配置界面文件"
                }
            }
        }
    }

    public func savedDigest(): String {
        return synchronized(lock) {
            savedDigestValue
        }
    }

    /// Records an EXPLICIT startup baseline: the application re-read the file,
    /// the accepted region already equals it (or a legal empty surface IS the
    /// baseline), and no submit was needed. This only adopts facts the caller
    /// observed; it never turns a candidate into an accepted document.
    public func adoptAcceptedBaseline(version: Int64, digest: String): Unit {
        synchronized(lock) {
            // A real in-flight operation is never erased by a startup helper.
            if (modeValue != "idle") {
                lastResultValue = "启动基线未采用：存在待处理界面操作 (${modeValue})"
                return
            }
            savedDigestValue = digest
            savedBaselineValue = version
            if (let Some(history) <- historyValue) { history.clear("ui_document_history_rebased") }
            modeValue = "idle"
            previewValue = None
            previewPathValue = ""
            submittedTokenValue = 0
            lastResultValue = "启动基线 v${version} sha=${digest}"
            lastFinish = CjguiUiDocumentSessionResult(false, "ui_document_no_submission", detail: "启动文件已是接受基线")
        }
    }

    public func savedBaseline(): Int64 {
        return synchronized(lock) {
            savedBaselineValue
        }
    }

    public func lastFinishResult(): CjguiUiDocumentSessionResult {
        return synchronized(lock) {
            lastFinish
        }
    }

    /// Most recent startup operation result. A close guard can consume the
    /// terminal ticket before the ordinary turn; that does not erase this fact.
    /// It describes its own path/token, not whether today's document is clean.
    public func startupResult(surface: CjguiUiDocumentSurface): CjguiUiDocumentSessionResult {
        if (!bindSurface(surface)) {
            return surfaceMismatch()
        }
        return synchronized(lock) {
            lastStartupResult
        }
    }

    public func startupPending(surface: CjguiUiDocumentSurface): Bool {
        if (!bindSurface(surface)) {
            return false
        }
        return synchronized(lock) {
            modeValue == "submitted" && submittedFromStartup
        }
    }

    /// The ordinary file preview/confirm protocol, used once at application
    /// startup. A busy interactive operation is never replaced by this entry.
    public func beginStartup(region: CjguiUiDocumentSurface, path: String,
        policy!: String = CJGUI_UI_DOCUMENT_POLICY_REPLACE): CjguiUiDocumentSessionResult {
        if (!bindSurface(region)) {
            return surfaceMismatch()
        }
        if (synchronized(lock) {
            modeValue != "idle"
        }) {
            return CjguiUiDocumentSessionResult(false, "ui_document_operation_pending",
                detail: "已有界面操作；启动载入未抢占该操作", path: path, startup: true)
        }
        let preview = previewReloadPath(region, path, policy: policy)
        if (!preview.applied) {
            return CjguiUiDocumentSessionResult(false, preview.reason, detail: preview.detail, path: path, startup: true)
        }
        let result = confirmReloadOperation(region, true)
        if (!result.applied) {
            return CjguiUiDocumentSessionResult(false, result.reason, detail: result.detail, path: path, startup: true)
        }
        return result
    }

    public func previewText(): String {
        let preview = synchronized(lock) {
            previewValue
        }
        return match (preview) {
            case Some(value) =>
                let builder = StringBuilder()
                builder.append(
                    "预览 ${value.policy}：基线 v${value.acceptedVersion} " + "file=${uiDocShort(value.fileDigest)}\n")
                builder.append(
                    "候选 ${uiDocShort(value.candidateDigest)} " +
                        "预期 v${value.expectedVersion} ${uiDocShort(value.expectedDigest)}\n")
                if (value.removals.size > 0) {
                    builder.append("移除定义 ${value.removals}\n")
                }
                if (value.diff.size == 0) {
                    builder.append("结构无变化\n")
                } else {
                    for (line in value.diff) {
                        builder.append("${line}\n")
                    }
                }
                builder.toString()
            case None => ""
        }
    }

    public func statusText(): String {
        return statusTextFor(None)
    }

    public func statusTextFor(surface: ?CjguiUiDocumentSurface): String {
        let (path, savedDigest, savedBaseline, mode, token, last, preview) = synchronized(lock) {
            (pathValue, savedDigestValue, savedBaselineValue, modeValue, submittedTokenValue, lastResultValue,
                previewValue)
        }
        var acceptedVersion: Int64 = -1
        var acceptedDigest = ""
        var ticketState = "none"
        var ticketReason = ""
        if (let Some(value) <- surface) {
            let accepted = value.acceptedUiDocument()
            acceptedVersion = accepted.version
            acceptedDigest = accepted.digest
            if (mode == "submitted") {
                let ticket = value.uiDocumentTicket(token)
                ticketState = ticket.terminalState
                ticketReason = ticket.reason
            }
        }
        let pathText = if (path.size > 0) {
            path
        } else {
            "未配置"
        }
        let savedText = if (savedDigest.size > 0) {
            "${uiDocShort(savedDigest)} 基线 v${savedBaseline}"
        } else {
            "尚未保存"
        }
        let acceptedText = if (acceptedVersion >= 0) {
            "v${acceptedVersion} ${uiDocShort(acceptedDigest)}"
        } else {
            "未读取"
        }
        let dirty = if (savedDigest.size > 0) {
            if (acceptedDigest.size > 0 && acceptedDigest != savedDigest) {
                "有未保存界面变更"
            } else {
                "已与保存一致"
            }
        } else {
            "界面尚未保存"
        }
        let operation = if (mode == "submitted") {
            "已提交 token=${token} 票据=${ticketState}" + (if (ticketReason.size > 0) {
                " 原因=${ticketReason}"
            } else {
                ""
            })
        } else if (mode == "preview") {
            "预览待确认"
        } else {
            "无待处理操作"
        }
        let builder = StringBuilder()
        builder.append("界面文件 ${pathText}\n")
        builder.append("保存 ${savedText}\n")
        builder.append("当前 accepted ${acceptedText} · ${dirty}\n")
        builder.append("操作 ${operation}\n")
        builder.append("最后结果 ${last}")
        if (path.size == 0 && acceptedVersion >= 0) {
            // A session without a file is legal: the caller may only be
            // presenting status, never saving.
        }
        return builder.toString()
    }

    public func stateFor(surface: CjguiUiDocumentSurface): CjguiUiDocumentSessionState {
        if (!bindSurface(surface)) {
            let last = synchronized(lock) {
                lastResultValue
            }
            return CjguiUiDocumentSessionState("", "", -1, -1, "", "mismatch", 0, "UNKNOWN",
                "ui_document_surface_mismatch", last, true, None)
        }
        let (path, savedDigest, savedBaseline, mode, token, last, preview) = synchronized(lock) {
            (pathValue, savedDigestValue, savedBaselineValue, modeValue, submittedTokenValue, lastResultValue,
                previewValue)
        }
        let accepted = surface.acceptedUiDocument()
        let historyState: ?CjguiUiDocumentHistoryState = synchronized(lock) {
            match (historyValue) {
                case Some(history) =>
                    if (modeValue != "submitted") { history.observe(accepted) }
                    Some(history.state(boundSurfaceIdValue, accepted, modeValue,
                        submittedHistoryActionValue, submittedTokenValue))
                case None => None
            }
        }
        var ticketState = "none"
        var ticketReason = ""
        if (mode == "submitted") {
            let ticket = surface.uiDocumentTicket(token)
            ticketState = if (ticket.known) {
                ticket.terminalState
            } else {
                "UNKNOWN"
            }
            ticketReason = ticket.reason
        }
        // An untouched empty v0 surface (no accepted submission yet, no file)
        // has nothing to save and must not block closing; initialization or a
        // real structure change advances the version, and THAT state without a
        // saved file is unsaved.
        let unsaved = if (savedDigest.size == 0) {
            accepted.version > 0
        } else {
            accepted.digest != savedDigest
        }
        return CjguiUiDocumentSessionState(path, savedDigest, savedBaseline, accepted.version, accepted.digest, mode,
            token, ticketState, ticketReason, last, unsaved, preview, history: historyState)
    }

    /// Enabled/disabled facts for the five public document actions. A submitted
    /// ticket disables every action until finish reports its terminal fact; a
    /// preview disables save/restore (it would silently replace the preview).
    public func actionStates(surface: CjguiUiDocumentSurface): ArrayList<CjguiUiDocumentActionState> {
        let state = stateFor(surface)
        let result = ArrayList<CjguiUiDocumentActionState>()
        let hasPath = state.path.size > 0
        let idle = state.mode == "idle"
        let previewing = state.mode == "preview"
        let submitted = state.mode == "submitted"
        result.add(
            CjguiUiDocumentActionState("UI_DOC_SAVE", "保存界面", hasPath && idle,
                disabledReason: if (!hasPath) {
                    "未配置界面文件"
                } else if (submitted) {
                    "载入已提交，等待结算"
                } else if (previewing) {
                    "请先确认或取消预览"
                } else {
                    ""
                }))
        result.add(
            CjguiUiDocumentActionState("UI_DOC_PREVIEW", "预览载入", hasPath && !submitted,
                disabledReason: if (!hasPath) {
                    "未配置界面文件"
                } else if (submitted) {
                    "载入已提交，等待结算"
                } else {
                    ""
                }))
        result.add(
            CjguiUiDocumentActionState("UI_DOC_CONFIRM", "确认载入", previewing, disabledReason: if (submitted) {
                "载入已提交，不能重复提交"
            } else {
                "没有待确认的预览"
            }))
        result.add(
            CjguiUiDocumentActionState("UI_DOC_CANCEL", "取消预览", previewing, disabledReason: if (submitted) {
                "已提交，不能取消预览"
            } else {
                "没有待取消的预览"
            }))
        result.add(
            CjguiUiDocumentActionState("UI_DOC_RESTORE", "恢复已存界面", hasPath && idle && state.savedDigest.size > 0,
                disabledReason: if (!hasPath) {
                    "未配置界面文件"
                } else if (state.savedDigest.size == 0) {
                    "尚未保存界面"
                } else if (submitted) {
                    "载入已提交，等待结算"
                } else if (previewing) {
                    "请先确认或取消预览"
                } else {
                    ""
                }))
        let history = state.history.getOrDefault({ => CjguiUiDocumentHistoryState(false) })
        result.add(CjguiUiDocumentActionState("UI_DOC_UNDO", "撤销界面改动", history.canUndo,
            disabledReason: history.undoReason))
        result.add(CjguiUiDocumentActionState("UI_DOC_REDO", "重做界面改动", history.canRedo,
            disabledReason: history.redoReason))
        return result
    }

    /// The caller combines this with the business owner's own close policy.
    /// `canClose=false` options are ordinary application decisions; the
    /// framework never writes, applies or discards business data itself.
    public func closeDecision(surface: CjguiUiDocumentSurface): CjguiUiDocumentCloseDecision {
        let state = stateFor(surface)
        if (state.mode == "mismatch") {
            return CjguiUiDocumentCloseDecision(false, "ui_document_surface_mismatch", "cancel")
        }
        if (state.mode == "submitted") {
            return CjguiUiDocumentCloseDecision(false, "ui_document_submitted", "wait|cancel")
        }
        if (state.mode == "preview") {
            return CjguiUiDocumentCloseDecision(false, "ui_document_preview_pending", "confirm|cancel")
        }
        if (state.unsaved) {
            return CjguiUiDocumentCloseDecision(false, "ui_document_unsaved", "save|discard_ui|cancel")
        }
        return CjguiUiDocumentCloseDecision(true, "", "")
    }

    /// The ONE protection every write of an existing target passes. A trusted
    /// observation (`knownDigest` from this session's own read/write) allows an
    /// atomic replace only while the bytes on disk still match it; without an
    /// observation an existing target is a named refusal, so neither `save`
    /// nor `saveAs` can convert an empty baseline into an overwrite permit.
    /// A path string that differs but resolves to the same existing file is
    /// also caught by the exists-gate: it is refused conservatively, never
    /// silently overwritten.
    private func uiDocumentExistingTargetGate(path: String, knownDigest: String): ?(String, String) {
        if (knownDigest.size > 0) {
            let currentFile = cjguiReadUiDocument(path)
            if (!currentFile.ok) {
                return Some(
                    ("ui_document_save_conflict",
                        "界面文件已变化或不可读（${currentFile.issue}）；请重新预览或另存"))
            }
            if (currentFile.structureSha256 != knownDigest) {
                return Some(("ui_document_save_conflict",
                    "界面文件在本次保存前被外部修改；请重新预览或另存"))
            }
            return None
        }
        if (exists(Path(path))) {
            return Some(
                ("ui_document_save_target_exists", "目标界面文件已存在，而本次会话还没有对它的可信观察；" +
                        "请先打开预览采用该文件，或换一个新路径"))
        }
        return None
    }

    public func save(region: CjguiUiDocumentSurface): CjguiUiDocumentSessionResult {
        if (!bindSurface(region)) {
            return surfaceMismatch()
        }
        if (synchronized(lock) {
            modeValue == "submitted"
        }) {
            return finishRefusal("ui_document_submitted", "已提交载入，不能同时保存界面；请等待票据结算")
        }
        if (synchronized(lock) {
            modeValue == "preview"
        }) {
            return finishRefusal("ui_document_preview_pending", "已有待确认预览；请先确认或取消")
        }
        let accepted = region.acceptedUiDocument()
        let exported = cjguiExportUiDocument(accepted.text)
        if (!exported.ok) {
            return finishRefusal(exported.issue, "界面导出失败：${exported.issue}")
        }
        let (path, knownDigest) = synchronized(lock) {
            (pathValue, savedDigestValue)
        }
        if (path.size == 0) {
            return finishRefusal("ui_document_path_empty", "未配置界面文件路径；请先另存选择位置")
        }
        // An existing target is written only through the shared protection
        // gate; a brand-new path is published without clobber semantics.
        if (let Some((reason, detail)) <- uiDocumentExistingTargetGate(path, knownDigest)) {
            return finishRefusal(reason, detail)
        }
        let writeIssue = uiDocumentAtomicWrite(path, exported.text, overwrite: knownDigest.size > 0)
        if (writeIssue.size > 0) {
            return finishRefusal(writeIssue, "界面保存被拒：${writeIssue}")
        }
        synchronized(lock) {
            savedDigestValue = exported.digest
            savedBaselineValue = accepted.version
            modeValue = "idle"
            previewValue = None
            previewPathValue = ""
            lastResultValue = "已保存 v${accepted.version} ${path} sha=${exported.digest}"
        }
        return CjguiUiDocumentSessionResult(true, "saved",
            detail: "已保存 accepted v${accepted.version}\n${path}\n" + "structure_sha256=${exported.digest}")
    }

    /// Writes the current complete accepted document to a NEW path and only
    /// switches the association after the atomic write succeeded. A later
    /// accepted change after this snapshot leaves the current surface dirty.
    /// Saving over the currently associated path takes the SAME conflict
    /// protection as `save`; any other existing target is a named refusal.
    public func saveAs(region: CjguiUiDocumentSurface, path: String): CjguiUiDocumentSessionResult {
        if (!bindSurface(region)) {
            return surfaceMismatch()
        }
        if (path.size == 0) {
            return finishRefusal("ui_document_path_empty", "另存路径为空")
        }
        if (synchronized(lock) {
            modeValue != "idle"
        }) {
            return finishRefusal("ui_document_operation_pending", "存在待处理界面操作；请先确认或取消")
        }
        let accepted = region.acceptedUiDocument()
        let exported = cjguiExportUiDocument(accepted.text)
        if (!exported.ok) {
            return finishRefusal(exported.issue, "界面导出失败：${exported.issue}")
        }
        let (currentPath, knownDigest) = synchronized(lock) {
            (pathValue, savedDigestValue)
        }
        let sameAssociatedTarget = currentPath.size > 0 && path == currentPath
        var overwrite = true
        if (sameAssociatedTarget) {
            // Saving over the associated file takes the SAME protection as an
            // ordinary save: observed bytes must still match, and an existing
            // file without an observation is refused by the gate.
            if (let Some((reason, detail)) <- uiDocumentExistingTargetGate(path, knownDigest)) {
                return finishRefusal(reason, detail)
            }
            overwrite = knownDigest.size > 0
        } else if (exists(Path(path))) {
            return finishRefusal("ui_document_save_as_target_exists",
                "另存目标已存在：${path}\n本次会话没有对该文件的可信观察，不能覆盖；" +
                    "请换一个新路径，或先打开预览采用该文件")
        } else {
            // Brand-new target: publish with the strongest no-clobber write.
            overwrite = false
        }
        let writeIssue = uiDocumentAtomicWrite(path, exported.text, overwrite: overwrite)
        if (writeIssue.size > 0) {
            return finishRefusal(writeIssue, "另存被拒：${writeIssue}")
        }
        synchronized(lock) {
            if (pathValue != path) {
                if (let Some(history) <- historyValue) {
                    history.reset(accepted, "ui_document_history_document_changed")
                }
            }
            pathValue = path
            savedDigestValue = exported.digest
            savedBaselineValue = accepted.version
            lastResultValue = "已另存 v${accepted.version} ${path} sha=${exported.digest}"
        }
        return CjguiUiDocumentSessionResult(true, "saved_as",
            detail: "已另存 accepted v${accepted.version}\n${path}\n" + "structure_sha256=${exported.digest}")
    }

    public func previewReload(region: CjguiUiDocumentSurface): CjguiUiDocumentSessionResult {
        return previewReload(region, policy: CJGUI_UI_DOCUMENT_POLICY_MERGE)
    }

    /// Opens a candidate path as one operation. The current path/save
    /// association does not move until this operation is really accepted (or
    /// a no-op preview is explicitly confirmed as a file association).
    public func previewReloadPath(region: CjguiUiDocumentSurface, path: String, policy!: String): CjguiUiDocumentSessionResult {
        if (!bindSurface(region)) {
            return surfaceMismatch()
        }
        if (synchronized(lock) {
            modeValue == "submitted"
        }) {
            return finishRefusal("ui_document_submitted", "已提交载入，不能重新预览；请等待票据结算")
        }
        if (policy != CJGUI_UI_DOCUMENT_POLICY_MERGE && policy != CJGUI_UI_DOCUMENT_POLICY_REPLACE) {
            return finishRefusal("ui_document_policy", "未知的界面载入策略：${policy}")
        }
        if (path.size == 0) {
            return finishRefusal("ui_document_path_empty", "未配置界面文件")
        }
        let loaded = cjguiReadUiDocument(path)
        if (!loaded.ok) {
            return finishRefusal(loaded.issue, "界面文件被拒：${loaded.issue}")
        }
        let accepted = region.acceptedUiDocument()
        let acceptedDecode = CjguiGeneratedUiEncoding.decode(accepted.text)
        let fileDecode = CjguiGeneratedUiEncoding.decode(loaded.structureText)
        if (!acceptedDecode.ok) {
            return finishRefusal("ui_document_baseline_invalid", "当前 accepted 界面无法解析：${acceptedDecode.reason}")
        }
        if (fileDecode.ok && fileDecode.root.isNone() && policy != CJGUI_UI_DOCUMENT_POLICY_REPLACE) {
            return finishRefusal("ui_document_empty_requires_replace",
                "文件没有界面节点；清空界面必须用 replace 预览并确认")
        }
        let plan = uiDocBuildPlan(accepted, loaded.structureText, loaded.structureSha256, policy)
        let preview = plan.preview
        if (!preview.changed) {
            let detail = StringBuilder()
            detail.append("预览载入 ${path}\n")
            detail.append("策略 ${policy}\n")
            detail.append("当前 accepted v${accepted.version} sha=${accepted.digest}\n")
            detail.append("文件 sha=${loaded.structureSha256}\n")
            detail.append("结构无变化；确认只采用该文件关联，不提交候选\n")
            synchronized(lock) {
                previewValue = Some(preview)
                previewPathValue = path
                modeValue = "preview"
                lastResultValue = "文件与当前界面语义一致，确认仅采用文件关联"
            }
            return CjguiUiDocumentSessionResult(true, "ui_document_no_changes", detail: detail.toString())
        }
        let detail = StringBuilder()
        detail.append("预览载入 ${path}\n")
        detail.append("策略 ${policy}\n")
        detail.append("当前 accepted v${preview.acceptedVersion} " + "sha=${uiDocShort(preview.acceptedDigest)}\n")
        detail.append("文件 sha=${uiDocShort(preview.fileDigest)} " + "候选 ${uiDocShort(preview.candidateDigest)}\n")
        detail.append("预期 accepted v${preview.expectedVersion} " + "${uiDocShort(preview.expectedDigest)}\n")
        if (preview.removals.size > 0) {
            detail.append("移除定义 ${preview.removals}\n")
        }
        for (line in preview.diff) {
            detail.append("${line}\n")
        }
        synchronized(lock) {
            previewValue = Some(preview)
            previewPathValue = path
            modeValue = "preview"
            lastResultValue = "预览待确认 v${preview.acceptedVersion} " + "file=${uiDocShort(preview.fileDigest)}"
        }
        return CjguiUiDocumentSessionResult(true, "preview", detail: detail.toString())
    }

    /// Build ONE immutable preview from the current accepted document, current
    /// catalog and the file. Selecting a different policy builds a new preview;
    /// it never reuses the previous expected facts.
    public func previewReload(region: CjguiUiDocumentSurface, policy!: String): CjguiUiDocumentSessionResult {
        let path = synchronized(lock) {
            pathValue
        }
        return previewReloadPath(region, path, policy: policy)
    }

    public func preview(): ?CjguiUiDocumentPreview {
        return synchronized(lock) {
            previewValue
        }
    }

    public func confirmReload(region: CjguiUiDocumentSurface): CjguiUiDocumentSessionResult {
        return confirmReloadOperation(region, false)
    }

    private func confirmReloadOperation(region: CjguiUiDocumentSurface, startup: Bool): CjguiUiDocumentSessionResult {
        if (!bindSurface(region)) {
            return surfaceMismatch()
        }
        if (synchronized(lock) {
            modeValue == "submitted"
        }) {
            return finishRefusal("ui_document_already_submitted", "本次载入已经提交，不能重复提交")
        }
        let stored = synchronized(lock) {
            previewValue
        }
        let pending = match (stored) {
            case Some(value) => value
            case None => return finishRefusal("ui_document_no_preview", "没有待确认的载入预览")
        }
        let operationPath = synchronized(lock) {
            if (previewPathValue.size > 0) {
                previewPathValue
            } else {
                pathValue
            }
        }
        let loaded = cjguiReadUiDocument(operationPath)
        if (!loaded.ok) {
            return finishRefusal(loaded.issue, "界面文件被拒：${loaded.issue}")
        }
        if (loaded.structureSha256 != pending.fileDigest) {
            return finishRefusal("ui_document_file_changed", "文件在预览后发生变化，请重新预览")
        }
        let accepted = region.acceptedUiDocument()
        if (accepted.version != pending.acceptedVersion || accepted.digest != pending.acceptedDigest) {
            return finishRefusal("ui_document_baseline_changed", "界面基线在预览后变化，请重新预览")
        }
        let rebuilt = uiDocBuildPlan(accepted, loaded.structureText, loaded.structureSha256, pending.policy).preview
        if (!uiDocSamePreview(pending, rebuilt)) {
            return finishRefusal("ui_document_preview_stale", "当前目录或基线无法再产生同一计划，请重新预览")
        }
        if (!pending.changed) {
            let result = CjguiUiDocumentSessionResult(true, "ui_document_file_adopted",
                detail: "文件与当前界面语义一致；只采用文件关联，未提交候选\n" +
                    "${operationPath}\nstructure_sha256=${loaded.structureSha256}", path: operationPath,
                version: accepted.version, fileDigest: loaded.structureSha256, startup: startup)
            synchronized(lock) {
                if (let Some(history) <- historyValue) {
                    if (startup || pathValue != operationPath) {
                        history.reset(accepted, "ui_document_history_document_changed")
                    }
                }
                pathValue = operationPath
                savedDigestValue = loaded.structureSha256
                savedBaselineValue = accepted.version
                modeValue = "idle"
                previewValue = None
                previewPathValue = ""
                lastResultValue = "已采用文件关联（无结构提交）${operationPath}"
                if (startup) {
                    lastStartupResult = result
                }
            }
            return result
        }
        let submitted = region.submitUiDocument(pending.candidateText, accepted.version)
        if (!submitted.accepted) {
            synchronized(lock) {
                modeValue = "idle"
                previewValue = None
                lastResultValue = "载入被当前 catalog 拒绝：${submitted.reason}"
            }
            return CjguiUiDocumentSessionResult(false, "ui_document_rejected:${submitted.reason}",
                detail: "载入被当前 catalog 拒绝：${submitted.reason}")
        }
        let result = CjguiUiDocumentSessionResult(true, "submitted",
            detail: "已通过同一预览计划提交\ntoken=${submitted.token}\n" +
                "预期 accepted v${pending.expectedVersion} ${pending.expectedDigest}", submitted: true,
            token: submitted.token, path: operationPath, fileDigest: pending.fileDigest, startup: startup)
        synchronized(lock) {
            modeValue = "submitted"
            submittedTokenValue = submitted.token
            submittedFromStartup = startup
            submittedHistoryActionValue = ""
            submittedHistoryEpochValue = 0
            submittedHistoryTargetValue = -1
            lastResultValue = "已提交载入 token=${submitted.token} " + "预期 v${pending.expectedVersion}"
            if (startup) {
                lastStartupResult = result
            }
        }
        return result
    }

    /// Commit one result only while the SAME submitted operation still owns
    /// the session. A reentrant/late finisher cannot consume a successor.
    private func publishOperationResult(token: Int64, pending: CjguiUiDocumentPreview, operationPath: String,
        startup: Bool, result: CjguiUiDocumentSessionResult, terminal: Bool, message: String): CjguiUiDocumentSessionResult {
        return synchronized(lock) {
            if (modeValue != "submitted" || submittedTokenValue != token) {
                return CjguiUiDocumentSessionResult(false, "ui_document_operation_replaced",
                    detail: "该票据不再属于当前操作；没有改动新操作或文件基线", token: token, path: operationPath,
                    startup: startup)
            }
            var outcome = result
            if (terminal) {
                modeValue = "idle"
                previewValue = None
                previewPathValue = ""
                if (submittedHistoryActionValue.size > 0) {
                    if (let Some(history) <- historyValue) {
                        if (result.accepted) {
                            let current = CjguiGeneratedUiAcceptedDocument(pending.expectedText,
                                result.version, pending.expectedDigest)
                            if (!history.settle(submittedHistoryTargetValue, submittedHistoryEpochValue, current)) {
                                outcome = CjguiUiDocumentSessionResult(result.applied,
                                    "ui_document_history_invalidated", detail: "候选曾接受；历史会话已关闭或重置，未移动游标",
                                    token: token, version: result.version)
                            }
                        } else if (result.reason == "accepted_then_changed") {
                            history.clear("ui_document_history_unobserved_change")
                        }
                    }
                } else if (result.accepted) {
                    if (let Some(history) <- historyValue) {
                        let current = CjguiGeneratedUiAcceptedDocument(pending.expectedText,
                            result.version, pending.expectedDigest)
                        if (startup || (operationPath.size > 0 && operationPath != pathValue)) {
                            history.reset(current, "ui_document_history_document_changed")
                        } else { history.observe(current) }
                    }
                    if (operationPath.size > 0) { pathValue = operationPath }
                    savedDigestValue = pending.fileDigest
                    savedBaselineValue = result.version
                } else if (result.reason == "accepted_then_changed") {
                    if (let Some(history) <- historyValue) { history.clear("ui_document_history_unobserved_change") }
                }
                submittedHistoryActionValue = ""
                submittedHistoryEpochValue = 0
                submittedHistoryTargetValue = -1
                lastResultValue = message
            }
            lastFinish = outcome
            if (startup) {
                lastStartupResult = outcome
            }
            return outcome
        }
    }

    /// Query the REAL ticket. Never infers success from an accepted digest,
    /// another token's acceptance or a higher version. Close and normal turns
    /// publish through this one operation record, including startup provenance.
    public func finishReload(region: CjguiUiDocumentSurface): CjguiUiDocumentSessionResult {
        if (!bindSurface(region)) {
            return surfaceMismatch()
        }
        let (mode, token, preview, operationPath, startup) = synchronized(lock) {
            (modeValue, submittedTokenValue, previewValue, previewPathValue, submittedFromStartup)
        }
        if (mode != "submitted") {
            observeHistoryTurn(region)
            let result = CjguiUiDocumentSessionResult(false, "ui_document_no_submission",
                detail: "没有在途的界面载入票据")
            synchronized(lock) {
                lastFinish = result
            }
            return result
        }
        let pending = match (preview) {
            case Some(value) => value
            case None => return finishRefusal("ui_document_no_preview", "提交记录缺少预览事实，不能判定结算")
        }
        let ticket = region.uiDocumentTicket(token)
        if (ticket.token != token) {
            return publishOperationResult(token, pending, operationPath, startup,
                CjguiUiDocumentSessionResult(false, "ui_document_ticket_mismatch",
                    detail: "票据查询返回 token=${ticket.token}，与被冻结提交 token=${token} 不符，不能结算",
                    token: token, path: operationPath, fileDigest: pending.fileDigest, startup: startup), false, "")
        }
        if (!ticket.known || ticket.terminalState == "UNKNOWN" || (ticket.terminalState != "ACCEPTED" &&
            ticket.terminalState != "REJECTED" && ticket.terminalState != "SUPERSEDED")) {
            return publishOperationResult(token, pending, operationPath, startup,
                CjguiUiDocumentSessionResult(false, "ui_document_pending",
                    detail: "票据 ${token} 尚无可见结算（${ticket.terminalState}）", token: token, path: operationPath,
                    fileDigest: pending.fileDigest, startup: startup), false, "")
        }
        if (ticket.terminalState == "REJECTED") {
            return publishOperationResult(token, pending, operationPath, startup,
                CjguiUiDocumentSessionResult(false, "ui_document_rejected:${ticket.reason}",
                    detail: "载入票据被拒：scene=${ticket.sceneState} reason=${ticket.reason}", token: token,
                    path: operationPath, fileDigest: pending.fileDigest, startup: startup), true,
                "载入被拒：${ticket.reason}")
        }
        if (ticket.terminalState == "SUPERSEDED") {
            return publishOperationResult(token, pending, operationPath, startup,
                CjguiUiDocumentSessionResult(false, "ui_document_superseded",
                    detail: "票据 ${token} 被更新的候选替代，未成为当前界面", token: token, path: operationPath,
                    fileDigest: pending.fileDigest, startup: startup), true, "载入票据已被更新的候选替代")
        }
        // One same-lock surface fact set, never another read of the current
        // document. File observation and expected accepted digest stay distinct.
        let exact = ticket.acceptedVersion == pending.expectedVersion && ticket.currentVersion == pending
            .expectedVersion && ticket.currentDigest == pending.expectedDigest
        let result = if (exact) {
            CjguiUiDocumentSessionResult(true, "accepted",
                detail: "票据 ${token} 接受为 v${ticket.currentVersion}\n" +
                    "structure_sha256=${ticket.currentDigest}\nfile_sha256=${pending.fileDigest}", accepted: true,
                token: token, path: operationPath, version: ticket.acceptedVersion, fileDigest: pending.fileDigest,
                startup: startup)
        } else {
            CjguiUiDocumentSessionResult(true, "accepted_then_changed",
                detail: "票据 ${token} 曾接受为 v${ticket.acceptedVersion}；当前已为 " +
                    "v${ticket.currentVersion} sha=${uiDocShort(ticket.currentDigest)}，保留原文件关联与基线",
                token: token, path: operationPath, version: ticket.acceptedVersion, fileDigest: pending.fileDigest,
                startup: startup)
        }
        return publishOperationResult(token, pending, operationPath, startup, result, true, if (exact) {
            "已载入 v${ticket.currentVersion} sha=${ticket.currentDigest}"
        } else {
            result.detail
        })
    }

    /// Compatibility wrapper for the normal turn loop: true only when the
    /// ticket reached a terminal fact. Callers that need the fact use
    /// `finishReload` (or `lastFinishResult`).
    public func verifyReload(region: CjguiUiDocumentSurface): Bool {
        let result = finishReload(region)
        return result.reason != "ui_document_pending" && result.reason != "ui_document_no_submission"
    }

    public func cancelPreview(): CjguiUiDocumentSessionResult {
        synchronized(lock) {
            if (modeValue == "submitted") {
                return CjguiUiDocumentSessionResult(false, "ui_document_submitted",
                    detail: "已提交载入，不能取消预览；票据仍可查询")
            }
            if (modeValue != "preview") {
                return CjguiUiDocumentSessionResult(false, "ui_document_no_preview", detail: "没有待取消的载入预览")
            }
            modeValue = "idle"
            previewValue = None
            previewPathValue = ""
            lastResultValue = "已取消载入预览（未提交）"
            return CjguiUiDocumentSessionResult(true, "cancelled", detail: "已取消载入预览，未提交任何候选")
        }
    }

    private func finishRefusal(reason: String, detail: String): CjguiUiDocumentSessionResult {
        synchronized(lock) {
            lastResultValue = detail
        }
        return CjguiUiDocumentSessionResult(false, reason, detail: detail)
    }
}
