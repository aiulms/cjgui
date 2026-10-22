// Named collection-view presets and their explicit, app-owned preference file.
//
// The framework supplies the typed snapshot and its restore rules; this file
// owns the names, the preset list, the active selection and WHERE/WHEN the
// preferences are written. Presets are deliberately stored beside (not inside)
// the rule-set document: saving a view never changes business content, and a
// document save never rewrites presentation preferences.
//
// The file is written only by an explicit application action. Column drags,
// filtering, sorting and weekly refresh turns never touch the disk.
package cjgui_rule_set_window_app

import cjgui.*
import std.collection.*
import std.convert.*
import std.fs.*

public let CJGUI_RULE_SET_VIEW_PREFERENCE_FORMAT: String = "CJGUI_RULE_SET_VIEWS"
public let CJGUI_RULE_SET_VIEW_PREFERENCE_VERSION: Int64 = 1
private let cjguiRuleSetViewPreferenceMaximumNames: Int64 = 32
private let cjguiRuleSetViewPreferenceMaximumBytes: Int64 = 262144

public class CjguiRuleSetViewPreferenceResult {
    public let applied: Bool
    public let reason: String

    public init(applied: Bool, reason: String) {
        this.applied = applied
        this.reason = reason
    }
}

public class CjguiRuleSetNamedView {
    public let name: String
    public let snapshot: CjguiComposableUiCollectionViewSnapshot

    public init(name: String, snapshot: CjguiComposableUiCollectionViewSnapshot) {
        this.name = name
        this.snapshot = snapshot
    }
}

public class CjguiRuleSetViewPreferences {
    private var views: ArrayList<CjguiRuleSetNamedView>
    private var activeNameValue: String
    private var revisionValue: Int64
    private var filePathValue: String
    private var dirtyValue: Bool
    private var lastReasonValue: String

    public init() {
        this.views = ArrayList<CjguiRuleSetNamedView>()
        this.activeNameValue = ""
        this.revisionValue = 0
        this.filePathValue = ""
        this.dirtyValue = false
        this.lastReasonValue = ""
    }

    public func filePath(): String {
        return filePathValue
    }

    public func setFilePath(path: String): Unit {
        filePathValue = path
    }

    /// Catalog revision. It advances for a saved preset, a changed active name
    /// or a load; it is independent of the document version and of the live
    /// view revision.
    public func revision(): Int64 {
        return revisionValue
    }

    public func isDirty(): Bool {
        return dirtyValue
    }

    public func activeName(): String {
        return activeNameValue
    }

    public func lastReason(): String {
        return lastReasonValue
    }

    public func count(): Int64 {
        return views.size
    }

    public func names(): ArrayList<String> {
        let result = ArrayList<String>()
        for (view in views) {
            result.add(view.name)
        }
        return result
    }

    public func contains(name: String): Bool {
        return indexOf(name) >= 0
    }

    public func snapshot(name: String): ?CjguiComposableUiCollectionViewSnapshot {
        let index = indexOf(name)
        if (index < 0) {
            return None
        }
        return Some(views[index].snapshot)
    }

    /// Saves the current snapshot under a name, replacing an existing preset
    /// with the same name. Returns true only when the catalog changed.
    public func upsert(name: String, snapshot: CjguiComposableUiCollectionViewSnapshot): Bool {
        if (!validName(name)) {
            lastReasonValue = "invalid_view_name"
            return false
        }
        if (!CjguiComposableUiCollectionViewCodec.encodeChecked(snapshot).isValid()) {
            lastReasonValue = "invalid_view_snapshot"
            return false
        }
        let index = indexOf(name)
        if (index >= 0) {
            if (sameSnapshot(views[index].snapshot, snapshot)) {
                if (activeNameValue != name) {
                    activeNameValue = name
                    revisionValue += 1
                    dirtyValue = true
                    lastReasonValue = "view_active"
                    return true
                }
                lastReasonValue = "view_unchanged"
                return false
            }
            views[index] = CjguiRuleSetNamedView(name, snapshot)
        } else {
            if (views.size >= cjguiRuleSetViewPreferenceMaximumNames) {
                lastReasonValue = "too_many_views"
                return false
            }
            views.add(CjguiRuleSetNamedView(name, snapshot))
        }
        activeNameValue = name
        revisionValue += 1
        dirtyValue = true
        lastReasonValue = "view_saved"
        return true
    }

    public func setActive(name: String): Bool {
        if (name.size == 0) {
            return clearActive()
        }
        if (!contains(name) || activeNameValue == name) {
            return false
        }
        activeNameValue = name
        revisionValue += 1
        dirtyValue = true
        lastReasonValue = "view_active"
        return true
    }

    public func clearActive(): Bool {
        if (activeNameValue.size == 0) {
            return false
        }
        activeNameValue = ""
        revisionValue += 1
        dirtyValue = true
        lastReasonValue = "view_active_cleared"
        return true
    }

    /// Stable list for the existing GET/INVOKE publication. Names are hex so a
    /// display name never needs an escaping convention.
    public func catalog(): String {
        let builder = StringBuilder()
        builder.append("CJGUI_COLLECTION_VIEWS ")
        builder.append(CJGUI_RULE_SET_VIEW_PREFERENCE_VERSION.toString())
        builder.append(" | ACTIVE ")
        builder.append(if (activeNameValue.size == 0) { "-" } else { cjguiRuleSetViewEncodeHex(activeNameValue) })
        for (view in views) {
            builder.append(" | NAME ")
            builder.append(cjguiRuleSetViewEncodeHex(view.name))
        }
        return builder.toString()
    }

    /// Reads the preference file. Missing file is not an error (first run);
    /// malformed, unsupported or duplicate content rejects the WHOLE file and
    /// keeps the in-memory catalog unchanged.
    public func load(path: String): CjguiRuleSetViewPreferenceResult {
        filePathValue = path
        if (path.size == 0) {
            lastReasonValue = "no_view_preference_path"
            return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
        }
        if (!exists(path)) {
            lastReasonValue = "view_preferences_not_found"
            dirtyValue = false
            return CjguiRuleSetViewPreferenceResult(true, lastReasonValue)
        }
        var payload = ""
        try {
            payload = String.fromUtf8(File.readFrom(path))
        } catch (_) {
            lastReasonValue = "view_preferences_read_failed"
            return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
        }
        if (!decode(payload)) {
            return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
        }
        dirtyValue = false
        revisionValue += 1
        lastReasonValue = "view_preferences_loaded"
        return CjguiRuleSetViewPreferenceResult(true, lastReasonValue)
    }

    /// Explicit write. The target is first checked against the current
    /// business document (and a pending save-as target); the actual encoded
    /// payload is then checked against the SAME byte bound `load` enforces.
    /// Either failure leaves the old file and `dirty` untouched. Atomic within
    /// the target directory: a fully written private temporary file replaces
    /// the destination only after success.
    public func save(path: String, protectedPaths: ArrayList<String>): CjguiRuleSetViewPreferenceResult {
        if (path.size == 0) {
            lastReasonValue = "no_view_preference_path"
            return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
        }
        for (protectedPath in protectedPaths) {
            if (samePath(path, protectedPath)) {
                lastReasonValue = "view_preferences_conflicts_with_document"
                return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
            }
        }
        let maybePayload = encodedPayload()
        if (let None <- maybePayload) {
            lastReasonValue = "invalid_view_snapshot"
            return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
        }
        let payload = maybePayload ?? ""
        if (payload.size > cjguiRuleSetViewPreferenceMaximumBytes) {
            lastReasonValue = "view_preferences_too_large"
            return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
        }
        let targetPath = Path(path)
        try {
            let temporaryDirectory = Directory.createTemp(targetPath.parent)
            let temporaryPath = temporaryDirectory.join("cjgui-views")
            try {
                File.writeTo(temporaryPath, payload.toArray())
                rename(temporaryPath, to: targetPath, overwrite: true)
                let _ = removeIfExists(temporaryDirectory, recursive: true)
                filePathValue = path
                dirtyValue = false
                lastReasonValue = "view_preferences_saved"
                return CjguiRuleSetViewPreferenceResult(true, lastReasonValue)
            } catch (_) {
                try {
                    let _ = removeIfExists(temporaryDirectory, recursive: true)
                } catch (_) {}
                lastReasonValue = "view_preferences_write_failed"
                return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
            }
        } catch (_) {
            lastReasonValue = "view_preferences_write_failed"
            return CjguiRuleSetViewPreferenceResult(false, lastReasonValue)
        }
    }

    public func encode(): String {
        match (encodedPayload()) {
            case Some(value) => value
            case None => ""
        }
    }

    private func encodedPayload(): ?String {
        let builder = StringBuilder()
        builder.append(CJGUI_RULE_SET_VIEW_PREFERENCE_FORMAT)
        builder.append(" ")
        builder.append(CJGUI_RULE_SET_VIEW_PREFERENCE_VERSION.toString())
        builder.append("\nACTIVE ")
        builder.append(if (activeNameValue.size == 0) { "-" } else { cjguiRuleSetViewEncodeHex(activeNameValue) })
        builder.append("\n")
        for (view in views) {
            let encodedSnapshot = match (CjguiComposableUiCollectionViewCodec.encodeChecked(view.snapshot).encoded) {
                case Some(value) => value
                case None => return None
            }
            builder.append("VIEW ")
            builder.append(cjguiRuleSetViewEncodeHex(view.name))
            builder.append(" ")
            builder.append(cjguiRuleSetViewEncodeHex(encodedSnapshot))
            builder.append("\n")
        }
        builder.append("END\n")
        return Some(builder.toString())
    }

    private func decode(payload: String): Bool {
        if (payload.size == 0 || payload.size > cjguiRuleSetViewPreferenceMaximumBytes) {
            lastReasonValue = "invalid_view_preferences_format"
            return false
        }
        let lines = payload.split("\n")
        // A trailing newline is the normal write form; ignore empty trailing
        // lines instead of misreporting the file as an unsupported version.
        var lastLine = lines.size - 1
        while (lastLine >= 0 && lines[lastLine].size == 0) {
            lastLine -= 1
        }
        if (lastLine < 2 || lines[0] !=
            "${CJGUI_RULE_SET_VIEW_PREFERENCE_FORMAT} ${CJGUI_RULE_SET_VIEW_PREFERENCE_VERSION}" ||
            lines[lastLine] != "END") {
            if (lines.size >= 1 && lines[0].startsWith(CJGUI_RULE_SET_VIEW_PREFERENCE_FORMAT)) {
                lastReasonValue = "unsupported_view_preferences_version"
            } else {
                lastReasonValue = "invalid_view_preferences_format"
            }
            return false
        }
        let parsedViews = ArrayList<CjguiRuleSetNamedView>()
        var parsedActive = ""
        var sawActive = false
        var index: Int64 = 1
        while (index < lastLine) {
            let parts = lines[index].split(" ")
            if (parts.size == 2 && parts[0] == "ACTIVE") {
                if (sawActive) {
                    lastReasonValue = "invalid_view_preferences_format"
                    return false
                }
                sawActive = true
                if (parts[1] == "-") {
                    parsedActive = ""
                } else {
                    parsedActive = match (cjguiRuleSetViewDecodeHex(parts[1], 64)) {
                        case Some(text) => text
                        case None => return reject("invalid_view_preferences_format")
                    }
                    if (!validName(parsedActive)) {
                        return reject("invalid_view_name")
                    }
                }
            } else if (parts.size == 3 && parts[0] == "VIEW") {
                let name = match (cjguiRuleSetViewDecodeHex(parts[1], 64)) {
                    case Some(text) => text
                    case None => return reject("invalid_view_preferences_format")
                }
                if (!validName(name)) {
                    return reject("invalid_view_name")
                }
                if (parsedViews.size >= cjguiRuleSetViewPreferenceMaximumNames) {
                    return reject("too_many_views")
                }
                for (existing in parsedViews) {
                    if (existing.name == name) {
                        return reject("duplicate_view_name")
                    }
                }
                let encodedSnapshot = match (cjguiRuleSetViewDecodeHex(parts[2], 65536)) {
                    case Some(text) => text
                    case None => return reject("invalid_view_preferences_format")
                }
                let decodedSnapshot = CjguiComposableUiCollectionViewCodec.decode(encodedSnapshot)
                let snapshot = match (decodedSnapshot.snapshot) {
                    case Some(value) => value
                    case None => return reject("invalid_view_snapshot")
                }
                parsedViews.add(CjguiRuleSetNamedView(name, snapshot))
            } else {
                return reject("invalid_view_preferences_format")
            }
            index += 1
        }
        if (!sawActive) {
            return reject("invalid_view_preferences_format")
        }
        // A dangling active name is tolerated as "no active preset"; it is not
        // a structural error and must not discard the other saved views.
        if (parsedActive.size > 0) {
            var found = false
            for (view in parsedViews) {
                if (view.name == parsedActive) {
                    found = true
                    break
                }
            }
            if (!found) {
                parsedActive = ""
            }
        }
        views = parsedViews
        activeNameValue = parsedActive
        return true
    }

    private func reject(reason: String): Bool {
        lastReasonValue = reason
        return false
    }

    private func indexOf(name: String): Int64 {
        var index: Int64 = 0
        while (index < views.size) {
            if (views[index].name == name) {
                return index
            }
            index += 1
        }
        return -1
    }

    /// Ordinary relative/absolute path equivalence for the explicit write
    /// guard. Relative targets are anchored at the current directory and both
    /// sides are normalized; canonicalization is used when the path exists.
    private func samePath(left: String, right: String): Bool {
        if (left.size == 0 || right.size == 0) {
            return false
        }
        return comparablePath(left) == comparablePath(right)
    }

    private func comparablePath(path: String): String {
        let target = Path(path)
        var absolute = target
        if (!target.isAbsolute()) {
            try {
                absolute = canonicalize(Path(".")).join(target)
            } catch (_) {
                absolute = target
            }
        }
        let normalized = absolute.normalize()
        try {
            return canonicalize(normalized).toString()
        } catch (_) {
            return normalized.toString()
        }
    }

    private func validName(name: String): Bool {
        if (name.size == 0 || name.size > 64) {
            return false
        }
        for (byte in name) {
            if (byte == b'\n' || byte == b'\r') {
                return false
            }
        }
        return true
    }

    private func sameSnapshot(left: CjguiComposableUiCollectionViewSnapshot,
        right: CjguiComposableUiCollectionViewSnapshot): Bool {
        if (left.mode != right.mode || left.query != right.query ||
            left.sortColumnKey != right.sortColumnKey || left.sortAscending != right.sortAscending ||
            left.columns.size != right.columns.size) {
            return false
        }
        var index: Int64 = 0
        while (index < left.columns.size) {
            let leftColumn = left.columns[index]
            let rightColumn = right.columns[index]
            if (leftColumn.key != rightColumn.key || leftColumn.width != rightColumn.width ||
                leftColumn.visible != rightColumn.visible) {
                return false
            }
            index += 1
        }
        return true
    }
}

private func cjguiRuleSetViewEncodeHex(value: String): String {
    let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    let result = StringBuilder()
    for (byte in value) {
        let numeric = Int64(byte)
        result.append(digits[numeric / 16])
        result.append(digits[numeric % 16])
    }
    return result.toString()
}

private func cjguiRuleSetViewDecodeHex(value: String, maximumBytes: Int64): ?String {
    if (value.size == 0 || value.size % 2 != 0 || value.size > maximumBytes * 2) {
        return None
    }
    let source = value.toArray()
    let bytes = ArrayList<Byte>()
    var index: Int64 = 0
    while (index < source.size) {
        if (let Some(high) <- cjguiRuleSetViewHexNibble(source[index])) {
            if (let Some(low) <- cjguiRuleSetViewHexNibble(source[index + 1])) {
                bytes.add(UInt8(high * 16 + low))
                index += 2
                continue
            }
        }
        return None
    }
    try {
        return Some(String.fromUtf8(bytes.toArray()))
    } catch (_) {
        return None
    }
}

private func cjguiRuleSetViewHexNibble(value: Byte): ?Int64 {
    if (value >= b'0' && value <= b'9') {
        return Some(Int64(value) - Int64(b'0'))
    }
    if (value >= b'A' && value <= b'F') {
        return Some(Int64(value) - Int64(b'A') + 10)
    }
    if (value >= b'a' && value <= b'f') {
        return Some(Int64(value) - Int64(b'a') + 10)
    }
    return None
}
