// Read-only loader for the portable `cjgui.ui-document` v1 file that the
// public Python tooling exports. The window uses it to start from a saved
// interface: the document is validated (bounded read, strict JSON, format,
// digest, structure, derived requirements) and only then submitted through the
// ordinary generated-structure candidate path. It never grants permissions:
// the current catalog still validates every declaration on submit.
package cjgui

import std.collection.*
import std.fs.*
import std.convert.*
import std.sort.*

public let CJGUI_UI_DOCUMENT_FORMAT = "cjgui.ui-document"
public let CJGUI_UI_DOCUMENT_VERSION: Int64 = 1
/// The Python writer and this reader share ONE file limit.
public let CJGUI_UI_DOCUMENT_MAX_BYTES: Int64 = 4 * 1024 * 1024

public class CjguiUiDocumentLoadResult {
    public let ok: Bool
    public let issue: String
    public let structureText: String
    public let structureFormat: Int64
    public let structureSha256: String
    public let formatVersion: Int64

    public init(ok: Bool, issue: String, structureText!: String = "",
                structureFormat!: Int64 = 0, structureSha256!: String = "",
                formatVersion!: Int64 = 0) {
        this.ok = ok
        this.issue = issue
        this.structureText = structureText
        this.structureFormat = structureFormat
        this.structureSha256 = structureSha256
        this.formatVersion = formatVersion
    }

    public static func refused(issue: String): CjguiUiDocumentLoadResult {
        return CjguiUiDocumentLoadResult(false, issue)
    }
}

private class CjguiUiJsonFailure <: Exception {
    let issue: String

    init(issue: String) {
        super(issue)
        this.issue = issue
    }
}

private let CJGUI_UI_JSON_NULL: Int64 = 0
private let CJGUI_UI_JSON_BOOLEAN: Int64 = 1
private let CJGUI_UI_JSON_NUMBER: Int64 = 2
private let CJGUI_UI_JSON_TEXT: Int64 = 3
private let CJGUI_UI_JSON_ARRAY: Int64 = 4
private let CJGUI_UI_JSON_OBJECT: Int64 = 5

private class CjguiUiJsonValue {
    let kind: Int64
    let text: String
    let boolean: Bool
    let numberText: String
    let items: ArrayList<CjguiUiJsonValue>
    let entries: ArrayList<(String, CjguiUiJsonValue)>

    init(kind: Int64, text!: String = "", boolean!: Bool = false,
        numberText!: String = "", items!: ArrayList<CjguiUiJsonValue> =
            ArrayList<CjguiUiJsonValue>(),
        entries!: ArrayList<(String, CjguiUiJsonValue)> =
            ArrayList<(String, CjguiUiJsonValue)>()) {
        this.kind = kind
        this.text = text
        this.boolean = boolean
        this.numberText = numberText
        this.items = items
        this.entries = entries
    }
}

private class CjguiUiJsonCursor {
    let bytes: Array<UInt8>
    var index: Int64

    init(bytes: Array<UInt8>) {
        this.bytes = bytes
        this.index = 0
    }
}

private func uiJsonIsSpace(value: UInt8): Bool {
    return value == UInt8(32) || value == UInt8(9) || value == UInt8(10) ||
        value == UInt8(13)
}

private func uiJsonSkipSpace(cursor: CjguiUiJsonCursor): Unit {
    while (cursor.index < cursor.bytes.size && uiJsonIsSpace(cursor.bytes[cursor.index])) {
        cursor.index += 1
    }
}

private func uiJsonIsDigit(value: UInt8): Bool {
    return value >= UInt8(48) && value <= UInt8(57)
}

private func uiJsonHexValue(value: UInt8): Int64 {
    if (value >= UInt8(48) && value <= UInt8(57)) { return Int64(value) - 48 }
    if (value >= UInt8(65) && value <= UInt8(70)) { return Int64(value) - 55 }
    if (value >= UInt8(97) && value <= UInt8(102)) { return Int64(value) - 87 }
    return -1
}

private func uiJsonAppendScalar(bytes: ArrayList<UInt8>, codePoint: Int64): Unit {
    if (codePoint <= 0x7f) {
        bytes.add(UInt8(codePoint))
    } else if (codePoint <= 0x7ff) {
        bytes.add(UInt8(0xc0 | (codePoint >> 6)))
        bytes.add(UInt8(0x80 | (codePoint & 0x3f)))
    } else if (codePoint <= 0xffff) {
        bytes.add(UInt8(0xe0 | (codePoint >> 12)))
        bytes.add(UInt8(0x80 | ((codePoint >> 6) & 0x3f)))
        bytes.add(UInt8(0x80 | (codePoint & 0x3f)))
    } else {
        bytes.add(UInt8(0xf0 | (codePoint >> 18)))
        bytes.add(UInt8(0x80 | ((codePoint >> 12) & 0x3f)))
        bytes.add(UInt8(0x80 | ((codePoint >> 6) & 0x3f)))
        bytes.add(UInt8(0x80 | (codePoint & 0x3f)))
    }
}

/// Read exactly one JSON string at `cursor.index` (which must be `"`).
private func uiJsonReadString(cursor: CjguiUiJsonCursor): String {
    let bytes = cursor.bytes
    var index = cursor.index
    if (index >= bytes.size || bytes[index] != UInt8(34)) {
        throw CjguiUiJsonFailure("ui_document_not_object")
    }
    index += 1
    let decoded = ArrayList<UInt8>()
    while (index < bytes.size) {
        let value = bytes[index]
        if (value == UInt8(34)) {
            cursor.index = index + 1
            return String.fromUtf8(decoded.toArray())
        }
        if (value < UInt8(32)) {
            throw CjguiUiJsonFailure("ui_document_not_object")
        }
        if (value != UInt8(92)) {
            decoded.add(value)
            index += 1
            continue
        }
        if (index + 1 >= bytes.size) { throw CjguiUiJsonFailure("ui_document_not_object") }
        let escape = bytes[index + 1]
        if (escape == UInt8(34) || escape == UInt8(92) || escape == UInt8(47)) {
            decoded.add(escape)
            index += 2
        } else if (escape == UInt8(98)) {
            decoded.add(UInt8(8)); index += 2
        } else if (escape == UInt8(102)) {
            decoded.add(UInt8(12)); index += 2
        } else if (escape == UInt8(110)) {
            decoded.add(UInt8(10)); index += 2
        } else if (escape == UInt8(114)) {
            decoded.add(UInt8(13)); index += 2
        } else if (escape == UInt8(116)) {
            decoded.add(UInt8(9)); index += 2
        } else if (escape == UInt8(117)) {
            if (index + 5 >= bytes.size) { throw CjguiUiJsonFailure("ui_document_not_object") }
            var codePoint: Int64 = 0
            var offset = 2
            while (offset < 6) {
                let digit = uiJsonHexValue(bytes[index + offset])
                if (digit < 0) { throw CjguiUiJsonFailure("ui_document_not_object") }
                codePoint = codePoint * 16 + digit
                offset += 1
            }
            index += 6
            if (codePoint >= 0xdc00 && codePoint <= 0xdfff) {
                // A lone low surrogate is not a Unicode scalar value.
                throw CjguiUiJsonFailure("ui_document_not_object")
            }
            if (codePoint >= 0xd800 && codePoint <= 0xdbff) {
                if (index + 5 >= bytes.size || bytes[index] != UInt8(92) ||
                    bytes[index + 1] != UInt8(117)) {
                    throw CjguiUiJsonFailure("ui_document_not_object")
                }
                var low: Int64 = 0
                var lowOffset = 2
                while (lowOffset < 6) {
                    let digit = uiJsonHexValue(bytes[index + lowOffset])
                    if (digit < 0) { throw CjguiUiJsonFailure("ui_document_not_object") }
                    low = low * 16 + digit
                    lowOffset += 1
                }
                if (low < 0xdc00 || low > 0xdfff) {
                    throw CjguiUiJsonFailure("ui_document_not_object")
                }
                codePoint = 0x10000 + ((codePoint - 0xd800) << 10) + (low - 0xdc00)
                index += 6
            }
            uiJsonAppendScalar(decoded, codePoint)
        } else {
            throw CjguiUiJsonFailure("ui_document_not_object")
        }
    }
    throw CjguiUiJsonFailure("ui_document_not_object")
}

private func uiJsonNumberEnd(bytes: Array<UInt8>, from: Int64): Int64 {
    var index = from
    if (index < bytes.size && bytes[index] == UInt8(45)) { index += 1 }
    if (index >= bytes.size) { return -1 }
    if (bytes[index] == UInt8(48)) {
        index += 1
    } else if (bytes[index] >= UInt8(49) && bytes[index] <= UInt8(57)) {
        index += 1
        while (index < bytes.size && uiJsonIsDigit(bytes[index])) { index += 1 }
    } else {
        return -1
    }
    if (index < bytes.size && bytes[index] == UInt8(46)) {
        index += 1
        if (index >= bytes.size || !uiJsonIsDigit(bytes[index])) { return -1 }
        while (index < bytes.size && uiJsonIsDigit(bytes[index])) { index += 1 }
    }
    if (index < bytes.size && (bytes[index] == UInt8(101) || bytes[index] == UInt8(69))) {
        index += 1
        if (index < bytes.size && (bytes[index] == UInt8(43) || bytes[index] == UInt8(45))) {
            index += 1
        }
        if (index >= bytes.size || !uiJsonIsDigit(bytes[index])) { return -1 }
        while (index < bytes.size && uiJsonIsDigit(bytes[index])) { index += 1 }
    }
    return index
}

private func uiJsonLiteral(cursor: CjguiUiJsonCursor, text: String,
    value: CjguiUiJsonValue): CjguiUiJsonValue {
    let raw = text.toArray()
    if (cursor.index + raw.size > cursor.bytes.size) {
        throw CjguiUiJsonFailure("ui_document_not_object")
    }
    for (offset in 0..raw.size) {
        if (cursor.bytes[cursor.index + offset] != raw[offset]) {
            throw CjguiUiJsonFailure("ui_document_not_object")
        }
    }
    cursor.index += raw.size
    return value
}

private func uiJsonParseValue(cursor: CjguiUiJsonCursor, depth: Int64): CjguiUiJsonValue {
    if (depth > 32) { throw CjguiUiJsonFailure("ui_document_not_object") }
    uiJsonSkipSpace(cursor)
    if (cursor.index >= cursor.bytes.size) {
        throw CjguiUiJsonFailure("ui_document_not_object")
    }
    let first = cursor.bytes[cursor.index]
    if (first == UInt8(34)) {
        return CjguiUiJsonValue(CJGUI_UI_JSON_TEXT, text: uiJsonReadString(cursor))
    }
    if (first == UInt8(123)) {
        cursor.index += 1
        let entries = ArrayList<(String, CjguiUiJsonValue)>()
        let seen = HashSet<String>()
        uiJsonSkipSpace(cursor)
        if (cursor.index < cursor.bytes.size &&
            cursor.bytes[cursor.index] == UInt8(125)) {
            cursor.index += 1
            return CjguiUiJsonValue(CJGUI_UI_JSON_OBJECT, entries: entries)
        }
        while (true) {
            uiJsonSkipSpace(cursor)
            let key = uiJsonReadString(cursor)
            if (seen.contains(key)) { throw CjguiUiJsonFailure("ui_document_not_object") }
            seen.add(key)
            uiJsonSkipSpace(cursor)
            if (cursor.index >= cursor.bytes.size ||
                cursor.bytes[cursor.index] != UInt8(58)) {
                throw CjguiUiJsonFailure("ui_document_not_object")
            }
            cursor.index += 1
            let item = uiJsonParseValue(cursor, depth + 1)
            entries.add((key, item))
            uiJsonSkipSpace(cursor)
            if (cursor.index >= cursor.bytes.size) {
                throw CjguiUiJsonFailure("ui_document_not_object")
            }
            let separator = cursor.bytes[cursor.index]
            cursor.index += 1
            if (separator == UInt8(125)) {
                return CjguiUiJsonValue(CJGUI_UI_JSON_OBJECT, entries: entries)
            }
            if (separator != UInt8(44)) {
                throw CjguiUiJsonFailure("ui_document_not_object")
            }
        }
    }
    if (first == UInt8(91)) {
        cursor.index += 1
        let items = ArrayList<CjguiUiJsonValue>()
        uiJsonSkipSpace(cursor)
        if (cursor.index < cursor.bytes.size &&
            cursor.bytes[cursor.index] == UInt8(93)) {
            cursor.index += 1
            return CjguiUiJsonValue(CJGUI_UI_JSON_ARRAY, items: items)
        }
        while (true) {
            items.add(uiJsonParseValue(cursor, depth + 1))
            uiJsonSkipSpace(cursor)
            if (cursor.index >= cursor.bytes.size) {
                throw CjguiUiJsonFailure("ui_document_not_object")
            }
            let separator = cursor.bytes[cursor.index]
            cursor.index += 1
            if (separator == UInt8(93)) {
                return CjguiUiJsonValue(CJGUI_UI_JSON_ARRAY, items: items)
            }
            if (separator != UInt8(44)) {
                throw CjguiUiJsonFailure("ui_document_not_object")
            }
        }
    }
    if (first == UInt8(116)) {
        return uiJsonLiteral(cursor, "true",
            CjguiUiJsonValue(CJGUI_UI_JSON_BOOLEAN, boolean: true))
    }
    if (first == UInt8(102)) {
        return uiJsonLiteral(cursor, "false",
            CjguiUiJsonValue(CJGUI_UI_JSON_BOOLEAN, boolean: false))
    }
    if (first == UInt8(110)) {
        return uiJsonLiteral(cursor, "null", CjguiUiJsonValue(CJGUI_UI_JSON_NULL))
    }
    let end = uiJsonNumberEnd(cursor.bytes, cursor.index)
    if (end <= cursor.index) { throw CjguiUiJsonFailure("ui_document_not_object") }
    let raw = String.fromUtf8(cursor.bytes[cursor.index..end])
    cursor.index = end
    return CjguiUiJsonValue(CJGUI_UI_JSON_NUMBER, numberText: raw)
}

private func uiJsonParse(bytes: Array<UInt8>): CjguiUiJsonValue {
    let cursor = CjguiUiJsonCursor(bytes)
    let value = uiJsonParseValue(cursor, 0)
    uiJsonSkipSpace(cursor)
    if (cursor.index != bytes.size) {
        throw CjguiUiJsonFailure("ui_document_not_object")
    }
    return value
}

private func uiJsonObject(value: CjguiUiJsonValue,
    issue: String): HashMap<String, CjguiUiJsonValue> {
    if (value.kind != CJGUI_UI_JSON_OBJECT) {
        throw CjguiUiJsonFailure(issue)
    }
    let result = HashMap<String, CjguiUiJsonValue>()
    for ((key, item) in value.entries) {
        result.add(key, item)
    }
    return result
}

private func uiJsonText(value: CjguiUiJsonValue, issue: String): String {
    if (value.kind != CJGUI_UI_JSON_TEXT) { throw CjguiUiJsonFailure(issue) }
    return value.text
}

private func uiJsonInteger(value: CjguiUiJsonValue, issue: String): Int64 {
    if (value.kind != CJGUI_UI_JSON_NUMBER) { throw CjguiUiJsonFailure(issue) }
    let raw = value.numberText
    if (raw.size == 0) { throw CjguiUiJsonFailure(issue) }
    var index = 0
    if (raw[0] == 45) { index = 1 }
    if (index >= raw.size) { throw CjguiUiJsonFailure(issue) }
    while (index < raw.size) {
        let digit = raw[index]
        if (digit < 48 || digit > 57) { throw CjguiUiJsonFailure(issue) }
        index += 1
    }
    return match (Int64.tryParse(raw)) {
        case Some(parsed) => parsed
        case None => throw CjguiUiJsonFailure(issue)
    }
}

private func uiJsonNonNegativeInteger(value: CjguiUiJsonValue, issue: String): Int64 {
    let parsed = uiJsonInteger(value, issue)
    if (parsed < 0) { throw CjguiUiJsonFailure(issue) }
    return parsed
}

private func uiJsonTextSet(value: CjguiUiJsonValue, issue: String): HashSet<String> {
    if (value.kind != CJGUI_UI_JSON_ARRAY) { throw CjguiUiJsonFailure(issue) }
    let result = HashSet<String>()
    for (item in value.items) {
        let text = uiJsonText(item, issue)
        if (text.size == 0) { throw CjguiUiJsonFailure(issue) }
        result.add(text)
    }
    return result
}

private func uiJsonResourceSet(value: CjguiUiJsonValue, issue: String): HashSet<String> {
    if (value.kind != CJGUI_UI_JSON_ARRAY) { throw CjguiUiJsonFailure(issue) }
    let result = HashSet<String>()
    for (item in value.items) {
        if (item.kind != CJGUI_UI_JSON_ARRAY || item.items.size != 2) {
            throw CjguiUiJsonFailure(issue)
        }
        let key = uiJsonText(item.items[0], issue)
        if (key.size == 0) { throw CjguiUiJsonFailure(issue) }
        let version = uiJsonNonNegativeInteger(item.items[1], issue)
        result.add("${key}@${version}")
    }
    return result
}

private func uiJsonSameSet(left: HashSet<String>, right: HashSet<String>): Bool {
    if (left.size != right.size) { return false }
    for (item in left) {
        if (!right.contains(item)) { return false }
    }
    return true
}

private class CjguiUiDocumentRequirements {
    let components: HashSet<String>
    let fields: HashSet<String>
    let actions: HashSet<String>
    let styles: HashSet<String>
    let images: HashSet<String>
    let fonts: HashSet<String>
    let runtimeCompositions: HashSet<String>

    init() {
        this.components = HashSet<String>()
        this.fields = HashSet<String>()
        this.actions = HashSet<String>()
        this.styles = HashSet<String>()
        this.images = HashSet<String>()
        this.fonts = HashSet<String>()
        this.runtimeCompositions = HashSet<String>()
    }

    func addNode(node: CjguiGeneratedUiNodeSpec): Unit {
        components.add(node.kind)
        if (node.fieldId.size > 0) { fields.add(node.fieldId) }
        if (node.actionName.size > 0) { actions.add(node.actionName) }
        let resource = node.property("resource")
        let resourceVersion = Int64.tryParse(node.property("resourceVersion"))
        if (resource.size > 0 && resourceVersion.isSome() && resourceVersion.getOrThrow() > 0) {
            images.add("${resource}@${resourceVersion.getOrThrow()}")
        }
        let fontResource = node.property("fontResource")
        let fontVersion = Int64.tryParse(node.property("fontVersion"))
        if (fontResource.size > 0) {
            let version = if (fontVersion.isSome() && fontVersion.getOrThrow() > 0) {
                fontVersion.getOrThrow()
            } else {
                1
            }
            fonts.add("${fontResource}@${version}")
        }
        for (child in node.children) { addNode(child) }
    }

    func addTemplate(node: CjguiCompositionTemplateNode): Unit {
        if (node.styleName.size > 0) { styles.add(node.styleName) }
        for (child in node.children) { addTemplate(child) }
    }
}

private func uiDocumentDerivedRequirements(
    decoded: CjguiGeneratedUiDecoded): CjguiUiDocumentRequirements {
    let derived = CjguiUiDocumentRequirements()
    if (let Some(root) <- decoded.root) { derived.addNode(root) }
    for (payload in decoded.definitions) {
        let definition = payload.definition
        derived.components.add(definition.name)
        derived.runtimeCompositions.add(definition.name)
        for (element in definition.elements) {
            if (element.fieldId.size > 0) { derived.fields.add(element.fieldId) }
            if (element.actionName.size > 0) { derived.actions.add(element.actionName) }
        }
        derived.addTemplate(definition.template)
    }
    return derived
}

private func uiDocumentDeclaredRequirements(value: CjguiUiJsonValue):
    CjguiUiDocumentRequirements {
    let issue = "ui_document_requirements"
    let fields = uiJsonObject(value, issue)
    let expected = ["components", "fields", "actions", "styles", "image_resources",
        "fonts", "runtime_compositions"]
    for (key in fields.keys()) {
        if (!expected.contains(key)) { throw CjguiUiJsonFailure(issue) }
    }
    for (key in expected) {
        if (!fields.contains(key)) { throw CjguiUiJsonFailure(issue) }
    }
    let declared = CjguiUiDocumentRequirements()
    declared.components.add(all: uiJsonTextSet(fields.get("components").getOrThrow(), issue))
    declared.fields.add(all: uiJsonTextSet(fields.get("fields").getOrThrow(), issue))
    declared.actions.add(all: uiJsonTextSet(fields.get("actions").getOrThrow(), issue))
    declared.styles.add(all: uiJsonTextSet(fields.get("styles").getOrThrow(), issue))
    declared.images.add(all: uiJsonResourceSet(fields.get("image_resources").getOrThrow(), issue))
    declared.fonts.add(all: uiJsonResourceSet(fields.get("fonts").getOrThrow(), issue))
    declared.runtimeCompositions.add(all:
        uiJsonTextSet(fields.get("runtime_compositions").getOrThrow(), issue))
    return declared
}

private func uiDocumentRequirementsMatch(declared: CjguiUiDocumentRequirements,
    derived: CjguiUiDocumentRequirements): Bool {
    return uiJsonSameSet(declared.components, derived.components) &&
        uiJsonSameSet(declared.fields, derived.fields) &&
        uiJsonSameSet(declared.actions, derived.actions) &&
        uiJsonSameSet(declared.styles, derived.styles) &&
        uiJsonSameSet(declared.images, derived.images) &&
        uiJsonSameSet(declared.fonts, derived.fonts) &&
        uiJsonSameSet(declared.runtimeCompositions, derived.runtimeCompositions)
}

private func uiJsonTextOrNone(value: CjguiUiJsonValue): ?String {
    if (value.kind != CJGUI_UI_JSON_TEXT) { return None }
    return Some(value.text)
}

private func uiJsonIntegerOrNone(value: CjguiUiJsonValue): ?Int64 {
    if (value.kind != CJGUI_UI_JSON_NUMBER) { return None }
    let raw = value.numberText
    if (raw.size == 0) { return None }
    var index = 0
    if (raw[0] == 45) { index = 1 }
    if (index >= raw.size) { return None }
    while (index < raw.size) {
        let digit = raw[index]
        if (digit < 48 || digit > 57) { return None }
        index += 1
    }
    return Int64.tryParse(raw)
}

private func uiDocumentDeclaredOrNone(value: CjguiUiJsonValue):
    ?CjguiUiDocumentRequirements {
    try {
        return Some(uiDocumentDeclaredRequirements(value))
    } catch (_) {
        return None
    }
}

private func uiDocumentValidDigest(value: String): Bool {
    if (value.size != 64) { return false }
    for (index in 0..value.size) {
        let character = value[index]
        if (!((character >= 48 && character <= 57) ||
            (character >= 97 && character <= 102))) {
            return false
        }
    }
    return true
}

/// Read at most the declared regular-file size plus one probe byte from ONE
/// descriptor, so a growing file or an oversized file is refused before it is
/// loaded. A zero-sized path (FIFO/device/empty file) is refused without an
/// open that could wait for a writer.
private func uiDocumentReadBounded(path: String): (Bool, String, Array<UInt8>) {
    var declared: Int64 = 0
    try {
        declared = FileInfo(path).size
    } catch (_) {
        return (false, "ui_document_unreadable", Array<UInt8>())
    }
    if (declared <= 0) { return (false, "ui_document_empty", Array<UInt8>()) }
    if (declared > CJGUI_UI_DOCUMENT_MAX_BYTES) {
        return (false, "ui_document_too_large", Array<UInt8>())
    }
    let content = ArrayList<UInt8>()
    var readIssue = ""
    try {
        try (file = File(path, OpenMode.Read)) {
            var remaining = declared
            while (remaining > 0) {
                let chunkSize = if (remaining > 65536) { 65536 } else { remaining }
                let buffer = Array<UInt8>(chunkSize, repeat: 0)
                let read = file.read(buffer)
                if (read <= 0) { break }
                var offset: Int64 = 0
                while (offset < read) {
                    content.add(buffer[offset])
                    offset += 1
                }
                remaining -= read
            }
            if (remaining != 0) {
                readIssue = "ui_document_unreadable"
            } else {
                let probe = Array<UInt8>(1, repeat: 0)
                let extra = file.read(probe)
                if (extra > 0) {
                    // The file grew after the size check; refuse the changed
                    // input rather than parse a truncated document.
                    readIssue = "ui_document_too_large"
                }
            }
        }
    } catch (_) {
        return (false, "ui_document_unreadable", Array<UInt8>())
    }
    if (readIssue.size > 0) {
        return (false, readIssue, Array<UInt8>())
    }
    return (true, "", content.toArray())
}

private func uiDocumentLoadUnlocked(path: String): CjguiUiDocumentLoadResult {
    let (readOk, readIssue, content) = uiDocumentReadBounded(path)
    if (!readOk) { return CjguiUiDocumentLoadResult.refused(readIssue) }
    let text = try {
        String.fromUtf8(content)
    } catch (_) {
        return CjguiUiDocumentLoadResult.refused("ui_document_not_utf8")
    }
    return uiDocumentLoadText(text)
}

/// Validate one already-decoded document body. File reading, the exporter's
/// self-check and the startup path all go through THIS one contract.
private func uiDocumentLoadText(text: String): CjguiUiDocumentLoadResult {
    let root = try {
        uiJsonParse(text.toArray())
    } catch (failure: CjguiUiJsonFailure) {
        return CjguiUiDocumentLoadResult.refused(failure.issue)
    } catch (_) {
        return CjguiUiDocumentLoadResult.refused("ui_document_not_object")
    }
    let fields = uiJsonObject(root, "ui_document_not_object")
    let allowed = ["format", "format_version", "requirements", "structure", "structure_format",
        "structure_sha256"]
    for (key in fields.keys()) {
        if (!allowed.contains(key)) {
            return CjguiUiDocumentLoadResult.refused("ui_document_unknown_key:${key}")
        }
    }
    for (key in allowed) {
        if (!fields.contains(key)) {
            return CjguiUiDocumentLoadResult.refused("ui_document_missing_key:${key}")
        }
    }
    let format = match (uiJsonTextOrNone(fields.get("format").getOrThrow())) {
        case Some(value) => value
        case None => return CjguiUiDocumentLoadResult.refused("ui_document_format")
    }
    if (format != CJGUI_UI_DOCUMENT_FORMAT) {
        return CjguiUiDocumentLoadResult.refused("ui_document_format")
    }
    let version = match (uiJsonIntegerOrNone(fields.get("format_version").getOrThrow())) {
        case Some(value) => value
        case None => return CjguiUiDocumentLoadResult.refused("ui_document_version")
    }
    if (version != CJGUI_UI_DOCUMENT_VERSION) {
        return CjguiUiDocumentLoadResult.refused("ui_document_version")
    }
    let structureFormat = match (
        uiJsonIntegerOrNone(fields.get("structure_format").getOrThrow())) {
        case Some(value) => value
        case None => return CjguiUiDocumentLoadResult.refused("ui_document_structure_format")
    }
    if (structureFormat != 1 && structureFormat != 2) {
        return CjguiUiDocumentLoadResult.refused("ui_document_structure_format")
    }
    let structure = match (uiJsonTextOrNone(fields.get("structure").getOrThrow())) {
        case Some(value) => value
        case None => return CjguiUiDocumentLoadResult.refused("ui_document_structure")
    }
    if (structure.toArray().size > CJGUI_GENERATED_UI_DECODE_MAX_BYTES) {
        return CjguiUiDocumentLoadResult.refused("ui_document_structure_too_large")
    }
    let digest = match (
        uiJsonTextOrNone(fields.get("structure_sha256").getOrThrow())) {
        case Some(value) => value
        case None => return CjguiUiDocumentLoadResult.refused("ui_document_structure_digest")
    }
    if (!uiDocumentValidDigest(digest)) {
        return CjguiUiDocumentLoadResult.refused("ui_document_structure_digest")
    }
    let prefix = "GENERATED_UI_STRUCTURE ${structureFormat}"
    if (!structure.startsWith(prefix)) {
        return CjguiUiDocumentLoadResult.refused("ui_document_structure_format_mismatch")
    }
    let actual = cjguiSha256Hex(structure.toArray())
    if (actual != digest) {
        return CjguiUiDocumentLoadResult.refused("ui_document_structure_digest")
    }
    let declared = match (
        uiDocumentDeclaredOrNone(fields.get("requirements").getOrThrow())) {
        case Some(value) => value
        case None => return CjguiUiDocumentLoadResult.refused("ui_document_requirements")
    }
    let decoded = CjguiGeneratedUiEncoding.decode(structure)
    if (!decoded.ok) {
        return CjguiUiDocumentLoadResult.refused(
            "ui_document_structure_invalid:${decoded.reason}")
    }
    if (decoded.removals.size > 0) {
        return CjguiUiDocumentLoadResult.refused("ui_document_delta_content")
    }
    if (!uiDocumentRequirementsMatch(declared, uiDocumentDerivedRequirements(decoded))) {
        return CjguiUiDocumentLoadResult.refused("ui_document_requirements_mismatch")
    }
    return CjguiUiDocumentLoadResult(true, "", structureText: structure,
        structureFormat: structureFormat, structureSha256: actual, formatVersion: version)
}

public func cjguiReadUiDocument(path: String): CjguiUiDocumentLoadResult {
    if (path.size == 0) { return CjguiUiDocumentLoadResult.refused("ui_document_path_empty") }
    return uiDocumentLoadUnlocked(path)
}

/// The digest the portable document format covers: the structure text bytes.
public func cjguiUiDocumentDigest(structureText: String): String {
    return cjguiSha256Hex(structureText.toArray())
}

public class CjguiUiDocumentExport {
    public let ok: Bool
    public let issue: String
    public let text: String
    public let digest: String
    public let structureFormat: Int64
    public let formatVersion: Int64

    public init(ok: Bool, issue: String, text!: String = "", digest!: String = "",
        structureFormat!: Int64 = 0, formatVersion!: Int64 = 0) {
        this.ok = ok
        this.issue = issue
        this.text = text
        this.digest = digest
        this.structureFormat = structureFormat
        this.formatVersion = formatVersion
    }

    public static func refused(issue: String): CjguiUiDocumentExport {
        return CjguiUiDocumentExport(false, issue)
    }
}

private func uiJsonQuoted(value: String): String {
    let escaped = value.replace("\\", "\\\\").replace("\"", "\\\"")
        .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
    return "\"${escaped}\""
}

private func uiJsonTextArray(values: HashSet<String>): String {
    let sorted = ArrayList<String>()
    for (value in values) { sorted.add(value) }
    sort(sorted)
    let builder = StringBuilder()
    builder.append("[")
    var first = true
    for (value in sorted) {
        if (!first) { builder.append(",") }
        builder.append(uiJsonQuoted(value))
        first = false
    }
    builder.append("]")
    return builder.toString()
}

private func uiJsonResourceArray(values: HashSet<String>): String {
    let sorted = ArrayList<String>()
    for (value in values) { sorted.add(value) }
    sort(sorted)
    let builder = StringBuilder()
    builder.append("[")
    var first = true
    for (value in sorted) {
        let parts = value.split("@")
        if (parts.size != 2) { continue }
        if (!first) { builder.append(",") }
        builder.append("[${uiJsonQuoted(parts[0])},${parts[1]}]")
        first = false
    }
    builder.append("]")
    return builder.toString()
}

/// Export one accepted structure as the SAME portable `cjgui.ui-document` v1
/// file the Python tooling reads. It only writes a complete, lossless document:
/// a structure with unknown content or a candidate-only removal is refused.
public func cjguiExportUiDocument(structureText: String): CjguiUiDocumentExport {
    let structureFormat = if (structureText.startsWith("GENERATED_UI_STRUCTURE 2")) {
        2
    } else if (structureText.startsWith("GENERATED_UI_STRUCTURE 1")) {
        1
    } else {
        return CjguiUiDocumentExport.refused("ui_document_structure_format_mismatch")
    }
    let decoded = CjguiGeneratedUiEncoding.decode(structureText)
    if (!decoded.ok) {
        return CjguiUiDocumentExport.refused("ui_document_structure_invalid:${decoded.reason}")
    }
    if (decoded.removals.size > 0) {
        return CjguiUiDocumentExport.refused("ui_document_delta_content")
    }
    let derived = uiDocumentDerivedRequirements(decoded)
    let digest = cjguiSha256Hex(structureText.toArray())
    let text = "{\"format\":\"${CJGUI_UI_DOCUMENT_FORMAT}\",\"format_version\":1," +
        "\"requirements\":{\"actions\":${uiJsonTextArray(derived.actions)}," +
        "\"components\":${uiJsonTextArray(derived.components)}," +
        "\"fields\":${uiJsonTextArray(derived.fields)}," +
        "\"fonts\":${uiJsonResourceArray(derived.fonts)}," +
        "\"image_resources\":${uiJsonResourceArray(derived.images)}," +
        "\"runtime_compositions\":${uiJsonTextArray(derived.runtimeCompositions)}," +
        "\"styles\":${uiJsonTextArray(derived.styles)}}," +
        "\"structure\":${uiJsonQuoted(structureText)},\"structure_format\":${structureFormat}," +
        "\"structure_sha256\":\"${digest}\"}"
    // Prove the exporter's own output is readable before handing it to a file.
    let check = uiDocumentLoadText(text)
    if (!check.ok) {
        return CjguiUiDocumentExport.refused("ui_document_export_check:${check.issue}")
    }
    return CjguiUiDocumentExport(true, "", text: text, digest: digest,
        structureFormat: structureFormat, formatVersion: 1)
}

@OverflowWrapping
private func cjguiSha256Hex(input: Array<UInt8>): String {
    var hash = Array<UInt32>(8, repeat: 0u32)
    hash[0] = 0x6a09e667u32
    hash[1] = 0xbb67ae85u32
    hash[2] = 0x3c6ef372u32
    hash[3] = 0xa54ff53au32
    hash[4] = 0x510e527fu32
    hash[5] = 0x9b05688cu32
    hash[6] = 0x1f83d9abu32
    hash[7] = 0x5be0cd19u32
    let constants = [
        0x428a2f98u32, 0x71374491u32, 0xb5c0fbcfu32, 0xe9b5dba5u32, 0x3956c25bu32,
        0x59f111f1u32, 0x923f82a4u32, 0xab1c5ed5u32, 0xd807aa98u32, 0x12835b01u32,
        0x243185beu32, 0x550c7dc3u32, 0x72be5d74u32, 0x80deb1feu32, 0x9bdc06a7u32,
        0xc19bf174u32, 0xe49b69c1u32, 0xefbe4786u32, 0x0fc19dc6u32, 0x240ca1ccu32,
        0x2de92c6fu32, 0x4a7484aau32, 0x5cb0a9dcu32, 0x76f988dau32, 0x983e5152u32,
        0xa831c66du32, 0xb00327c8u32, 0xbf597fc7u32, 0xc6e00bf3u32, 0xd5a79147u32,
        0x06ca6351u32, 0x14292967u32, 0x27b70a85u32, 0x2e1b2138u32, 0x4d2c6dfcu32,
        0x53380d13u32, 0x650a7354u32, 0x766a0abbu32, 0x81c2c92eu32, 0x92722c85u32,
        0xa2bfe8a1u32, 0xa81a664bu32, 0xc24b8b70u32, 0xc76c51a3u32, 0xd192e819u32,
        0xd6990624u32, 0xf40e3585u32, 0x106aa070u32, 0x19a4c116u32, 0x1e376c08u32,
        0x2748774cu32, 0x34b0bcb5u32, 0x391c0cb3u32, 0x4ed8aa4au32, 0x5b9cca4fu32,
        0x682e6ff3u32, 0x748f82eeu32, 0x78a5636fu32, 0x84c87814u32, 0x8cc70208u32,
        0x90befffau32, 0xa4506cebu32, 0xbef9a3f7u32, 0xc67178f2u32
    ]
    let padded = ArrayList<UInt8>()
    for (value in input) { padded.add(value) }
    padded.add(UInt8(128))
    while (padded.size % 64 != 56) { padded.add(UInt8(0)) }
    let bitLength = UInt64(input.size) * 8
    var shift: Int64 = 56
    while (shift >= 0) {
        padded.add(UInt8((bitLength >> UInt64(shift)) & 0xff))
        shift -= 8
    }
    let data = padded.toArray()
    var blockStart = 0
    while (blockStart < data.size) {
        var words = Array<UInt32>(64, repeat: 0u32)
        var index = 0
        while (index < 16) {
            let base = blockStart + index * 4
            words[index] = (UInt32(data[base]) << 24) | (UInt32(data[base + 1]) << 16) |
                (UInt32(data[base + 2]) << 8) | UInt32(data[base + 3])
            index += 1
        }
        while (index < 64) {
            let s0 = cjguiRotateRight(words[index - 15], 7) ^ cjguiRotateRight(words[index - 15], 18) ^
                (words[index - 15] >> 3)
            let s1 = cjguiRotateRight(words[index - 2], 17) ^ cjguiRotateRight(words[index - 2], 19) ^
                (words[index - 2] >> 10)
            words[index] = words[index - 16] + s0 + words[index - 7] + s1
            index += 1
        }
        var a = hash[0]
        var b = hash[1]
        var c = hash[2]
        var d = hash[3]
        var e = hash[4]
        var f = hash[5]
        var g = hash[6]
        var h = hash[7]
        index = 0
        while (index < 64) {
            let s1 = cjguiRotateRight(e, 6) ^ cjguiRotateRight(e, 11) ^ cjguiRotateRight(e, 25)
            let choose = (e & f) ^ ((e ^ 0xffffffffu32) & g)
            let temp1 = h + s1 + choose + constants[index] + words[index]
            let s0 = cjguiRotateRight(a, 2) ^ cjguiRotateRight(a, 13) ^ cjguiRotateRight(a, 22)
            let majority = (a & b) ^ (a & c) ^ (b & c)
            let temp2 = s0 + majority
            h = g
            g = f
            f = e
            e = d + temp1
            d = c
            c = b
            b = a
            a = temp1 + temp2
            index += 1
        }
        hash[0] += a
        hash[1] += b
        hash[2] += c
        hash[3] += d
        hash[4] += e
        hash[5] += f
        hash[6] += g
        hash[7] += h
        blockStart += 64
    }
    let output = StringBuilder()
    for (value in hash) {
        var shiftBits: Int64 = 28
        while (shiftBits >= 0) {
            let digit = Int64((value >> UInt64(shiftBits)) & 0xfu32)
            output.append(digit.toString(radix: 16))
            shiftBits -= 4
        }
    }
    return output.toString()
}

@OverflowWrapping
private func cjguiRotateRight(value: UInt32, bits: Int64): UInt32 {
    return (value >> UInt64(bits)) | (value << UInt64(32 - bits))
}
