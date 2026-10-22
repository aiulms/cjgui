// Typed, stable-key collection view snapshots and atomic restore.
//
// A collection view is PRESENTATION only: which projection is active (a
// caller-declared mode token such as list/table), the text query, the explicit
// sort target, and each declared column's stable key, width, visibility and
// order. It never stores records, drafts, selection, pointer capture, platform
// node ids or a drag in progress.
//
// A snapshot is applied through an explicit target state. Every section is
// validated before the first mutation, so an unsupported format, an unknown
// mode, a duplicate column or an all-hidden plan leaves the current view
// exactly as it was. Column-declaration changes use one simple rule: keys that
// no longer exist are ignored, new keys are appended at their declared default,
// and saved widths are clamped to the current declaration.
//
// Named presets and their storage location stay application-owned. This file
// only provides the typed value, its stable text encoding and the restore
// entry that both a human control and an external client can share.
package cjgui

import std.collection.*
import std.convert.*
import std.overflow.*

public let CJGUI_COMPOSABLE_UI_COLLECTION_VIEW_FORMAT: String = "CJGUI_COLLECTION_VIEW"
public let CJGUI_COMPOSABLE_UI_COLLECTION_VIEW_VERSION: Int64 = 1
private let cjguiCollectionViewMaximumEncodedBytes: Int64 = 65536
private let cjguiCollectionViewMaximumModeBytes: Int64 = 64
private let cjguiCollectionViewMaximumQueryBytes: Int64 = 8192
private let cjguiCollectionViewMaximumKeyBytes: Int64 = 64

/// Immutable-by-convention presentation state of one collection view.
/// `columns` is in projected order and includes hidden columns; a hidden entry
/// keeps its width and slot, exactly like the layout object it came from.
public class CjguiComposableUiCollectionViewSnapshot {
    public let mode: String
    public let query: String
    public let sortColumnKey: String
    public let sortAscending: Bool
    public let columns: ArrayList<CjguiComposableUiTableColumnState>

    public init(mode: String, query: String, sortColumnKey: String, sortAscending: Bool,
        columns: ArrayList<CjguiComposableUiTableColumnState>) {
        this.mode = mode
        this.query = query
        this.sortColumnKey = sortColumnKey
        this.sortAscending = sortAscending
        this.columns = ArrayList<CjguiComposableUiTableColumnState>(columns)
    }
}

/// Result of decoding one saved view text. `snapshot` is None for an
/// unsupported version or any structural violation, with `reason` naming the
/// rejection; no partially decoded snapshot is returned.
public class CjguiComposableUiCollectionViewDecodeResult {
    public let snapshot: ?CjguiComposableUiCollectionViewSnapshot
    public let reason: String

    public init(snapshot: ?CjguiComposableUiCollectionViewSnapshot, reason: String) {
        this.snapshot = snapshot
        this.reason = reason
    }

    public func isValid(): Bool {
        match (snapshot) {
            case Some(_) => true
            case None => false
        }
    }
}

/// Result of encoding one snapshot. Encoding applies the SAME component bounds
/// the decoder enforces, so a successful value is always decodable.
public class CjguiComposableUiCollectionViewEncodeResult {
    public let encoded: ?String
    public let reason: String

    public init(encoded: ?String, reason: String) {
        this.encoded = encoded
        this.reason = reason
    }

    public func isValid(): Bool {
        match (encoded) {
            case Some(_) => true
            case None => false
        }
    }
}

/// Result of applying a typed snapshot. `ignoredColumnKeys` are saved keys the
/// current declaration no longer has; `addedColumnKeys` are current keys the
/// snapshot did not contain. Both are reported, not silently hidden.
public class CjguiComposableUiCollectionViewRestoreResult {
    public let applied: Bool
    public let reason: String
    public let ignoredColumnKeys: ArrayList<String>
    public let addedColumnKeys: ArrayList<String>
    public let sortCleared: Bool

    public init(applied: Bool, reason: String, ignoredColumnKeys: ArrayList<String>,
        addedColumnKeys: ArrayList<String>, sortCleared: Bool) {
        this.applied = applied
        this.reason = reason
        this.ignoredColumnKeys = ArrayList<String>(ignoredColumnKeys)
        this.addedColumnKeys = ArrayList<String>(addedColumnKeys)
        this.sortCleared = sortCleared
    }
}

/// Stable one-line text form. It is deliberately boring: a versioned header,
/// four named sections and hex-encoded free text. No temporary interaction
/// state has a place in this format.
public class CjguiComposableUiCollectionViewCodec {
    /// Encodes only when the result satisfies the decoder's bounds. A caller
    /// that persists the text must use this entry (or `encode`, which throws
    /// instead of returning text the decoder would reject).
    public static func encodeChecked(
        snapshot: CjguiComposableUiCollectionViewSnapshot
    ): CjguiComposableUiCollectionViewEncodeResult {
        if (snapshot.mode.size == 0 || snapshot.mode.size > cjguiCollectionViewMaximumModeBytes) {
            return invalidEncoding("invalid_view_mode")
        }
        if (snapshot.query.size > cjguiCollectionViewMaximumQueryBytes) {
            return invalidEncoding("view_query_too_large")
        }
        if (snapshot.sortColumnKey.size > cjguiCollectionViewMaximumKeyBytes) {
            return invalidEncoding("invalid_sort_key")
        }
        if (snapshot.columns.size == 0) {
            return invalidEncoding("empty_view_columns")
        }
        let seen = HashSet<String>()
        for (column in snapshot.columns) {
            if (column.key.size == 0 || column.key.size > cjguiCollectionViewMaximumKeyBytes) {
                return invalidEncoding("invalid_column_key")
            }
            if (seen.contains(column.key)) {
                return invalidEncoding("duplicate_column")
            }
            if (column.width < 0) {
                return invalidEncoding("invalid_column_width")
            }
            seen.add(column.key)
        }
        let builder = StringBuilder()
        builder.append(CJGUI_COMPOSABLE_UI_COLLECTION_VIEW_FORMAT)
        builder.append(" ")
        builder.append(CJGUI_COMPOSABLE_UI_COLLECTION_VIEW_VERSION.toString())
        builder.append(" | MODE ")
        builder.append(cjguiCollectionViewEncodeHex(snapshot.mode))
        builder.append(" | QUERY ")
        builder.append(if (snapshot.query.size == 0) { "-" } else { cjguiCollectionViewEncodeHex(snapshot.query) })
        builder.append(" | SORT ")
        if (snapshot.sortColumnKey.size == 0) {
            builder.append("NONE")
        } else {
            builder.append(cjguiCollectionViewEncodeHex(snapshot.sortColumnKey))
            builder.append(" ")
            builder.append(if (snapshot.sortAscending) { "A" } else { "D" })
        }
        for (column in snapshot.columns) {
            builder.append(" | COL ")
            builder.append(cjguiCollectionViewEncodeHex(column.key))
            builder.append(" ")
            builder.append(column.width.toString())
            builder.append(" ")
            builder.append(if (column.visible) { "1" } else { "0" })
        }
        let encoded = builder.toString()
        if (encoded.size > cjguiCollectionViewMaximumEncodedBytes) {
            return invalidEncoding("view_too_large")
        }
        return CjguiComposableUiCollectionViewEncodeResult(Some(encoded), "encoded")
    }

    public static func encode(snapshot: CjguiComposableUiCollectionViewSnapshot): String {
        let result = encodeChecked(snapshot)
        if (let Some(value) <- result.encoded) {
            return value
        }
        throw IllegalArgumentException("collection_view_encoding_failed:${result.reason}")
    }

    public static func decode(value: String): CjguiComposableUiCollectionViewDecodeResult {
        if (value.size == 0 || value.size > cjguiCollectionViewMaximumEncodedBytes) {
            return invalid("invalid_view_format")
        }
        let segments = value.split(" | ")
        // The header's VERSION is checked BEFORE the section count: a payload
        // that names a format version this codec does not support is an
        // unsupported VERSION, not merely a malformed section list. (A valid
        // version with missing sections still reports invalid_view_format.)
        let header = segments[0].split(" ")
        if (header.size != 2 || header[0] != CJGUI_COMPOSABLE_UI_COLLECTION_VIEW_FORMAT) {
            if (header.size >= 1 && header[0] == CJGUI_COMPOSABLE_UI_COLLECTION_VIEW_FORMAT) {
                return invalid("unsupported_view_version")
            }
            return invalid("invalid_view_format")
        }
        if (header[1] != CJGUI_COMPOSABLE_UI_COLLECTION_VIEW_VERSION.toString()) {
            return invalid("unsupported_view_version")
        }
        if (segments.size < 5) {
            return invalid("invalid_view_format")
        }
        let modeParts = segments[1].split(" ")
        if (modeParts.size != 2 || modeParts[0] != "MODE") {
            return invalid("invalid_view_format")
        }
        let mode = match (cjguiCollectionViewDecodeHex(modeParts[1], cjguiCollectionViewMaximumModeBytes)) {
            case Some(text) => text
            case None => return invalid("invalid_view_format")
        }
        if (mode.size == 0) {
            return invalid("invalid_view_format")
        }
        let queryParts = segments[2].split(" ")
        if (queryParts.size != 2 || queryParts[0] != "QUERY") {
            return invalid("invalid_view_format")
        }
        let query = if (queryParts[1] == "-") {
            ""
        } else {
            match (cjguiCollectionViewDecodeHex(queryParts[1], cjguiCollectionViewMaximumQueryBytes)) {
                case Some(text) => text
                case None => return invalid("invalid_view_format")
            }
        }
        let sortParts = segments[3].split(" ")
        if (sortParts.size < 2 || sortParts[0] != "SORT") {
            return invalid("invalid_view_format")
        }
        var sortColumnKey = ""
        var sortAscending = true
        if (sortParts[1] == "NONE") {
            if (sortParts.size != 2) {
                return invalid("invalid_view_format")
            }
        } else {
            if (sortParts.size != 3) {
                return invalid("invalid_view_format")
            }
            sortColumnKey = match (cjguiCollectionViewDecodeHex(sortParts[1], cjguiCollectionViewMaximumKeyBytes)) {
                case Some(text) => text
                case None => return invalid("invalid_view_format")
            }
            if (sortColumnKey.size == 0) {
                return invalid("invalid_view_format")
            }
            if (sortParts[2] == "D") {
                sortAscending = false
            } else if (sortParts[2] != "A") {
                return invalid("invalid_view_format")
            }
        }
        let columns = ArrayList<CjguiComposableUiTableColumnState>()
        let seen = HashSet<String>()
        var index: Int64 = 4
        while (index < segments.size) {
            let parts = segments[index].split(" ")
            if (parts.size != 4 || parts[0] != "COL") {
                return invalid("invalid_view_format")
            }
            let key = match (cjguiCollectionViewDecodeHex(parts[1], cjguiCollectionViewMaximumKeyBytes)) {
                case Some(text) => text
                case None => return invalid("invalid_view_format")
            }
            if (key.size == 0 || seen.contains(key)) {
                return invalid("invalid_view_format")
            }
            seen.add(key)
            let width = match (Int64.tryParse(parts[2])) {
                case Some(value) => value
                case None => return invalid("invalid_view_format")
            }
            if (width < 0) {
                return invalid("invalid_view_format")
            }
            if (parts[3] != "0" && parts[3] != "1") {
                return invalid("invalid_view_format")
            }
            columns.add(CjguiComposableUiTableColumnState(key, width, parts[3] == "1"))
            index += 1
        }
        if (columns.size == 0) {
            return invalid("invalid_view_format")
        }
        return CjguiComposableUiCollectionViewDecodeResult(
            Some(CjguiComposableUiCollectionViewSnapshot(mode, query, sortColumnKey, sortAscending, columns)),
            "decoded")
    }

    private static func invalid(reason: String): CjguiComposableUiCollectionViewDecodeResult {
        return CjguiComposableUiCollectionViewDecodeResult(None, reason)
    }

    private static func invalidEncoding(reason: String): CjguiComposableUiCollectionViewEncodeResult {
        return CjguiComposableUiCollectionViewEncodeResult(None, reason)
    }
}

/// Live presentation view over the caller's filtered source, sorted table and
/// column layout. It owns only the mode token and one view revision; query,
/// sort and column state stay in the components the application already uses.
public class CjguiComposableUiCollectionViewState {
    private let table: CjguiComposableUiTableSource
    private let layoutState: CjguiComposableUiTableColumnLayout
    private let validModes: ArrayList<String>
    private let defaultModeValue: String
    private var modeValue: String
    private var revisionValue: Int64

    public init(table: CjguiComposableUiTableSource, modes: Array<String>, initialMode: String) {
        this.table = table
        this.layoutState = table.layout()
        this.validModes = ArrayList<String>()
        for (mode in modes) {
            if (mode.size > 0 && !this.validModes.contains(mode)) {
                this.validModes.add(mode)
            }
        }
        let selectedMode = if (this.validModes.contains(initialMode)) {
            initialMode
        } else if (this.validModes.size > 0) {
            this.validModes[0]
        } else {
            ""
        }
        this.defaultModeValue = selectedMode
        this.modeValue = selectedMode
        this.revisionValue = 0
    }

    public func mode(): String {
        return modeValue
    }

    public func validModeNames(): ArrayList<String> {
        return ArrayList<String>(validModes)
    }

    /// Switches the projection mode token. Unknown modes are rejected; the
    /// application maps a valid token to its own composition.
    public func setMode(mode: String): Bool {
        if (!validModes.contains(mode) || mode == modeValue) {
            return false
        }
        modeValue = mode
        revisionValue = revisionValue.saturatingAdd(1)
        return true
    }

    public func query(): String {
        return table.query()
    }

    public func setQuery(value: String): Bool {
        if (!table.setQuery(value)) {
            return false
        }
        revisionValue = revisionValue.saturatingAdd(1)
        return true
    }

    public func sortColumnKey(): String {
        return table.sortColumnKey()
    }

    public func sortAscending(): Bool {
        return table.sortAscending()
    }

    /// Explicit sort target used by restore. Unlike the header click this never
    /// depends on the previous direction or on repeated toggles.
    public func setSortState(columnKey: String, ascending: Bool): Bool {
        if (!table.setSortState(columnKey, ascending)) {
            return false
        }
        revisionValue = revisionValue.saturatingAdd(1)
        return true
    }

    /// Header-click behaviour: a new column starts ascending and the active
    /// column flips.
    public func toggleSort(columnKey: String): Bool {
        if (!table.setSort(columnKey)) {
            return false
        }
        revisionValue = revisionValue.saturatingAdd(1)
        return true
    }

    public func clearSort(): Bool {
        if (!table.clearSort()) {
            return false
        }
        revisionValue = revisionValue.saturatingAdd(1)
        return true
    }

    /// Marks one accepted edit made directly on the shared layout object (the
    /// column menu or a resize gesture). Keeping this explicit means `revision`
    /// stays a pure read: an external context read cannot mutate the view while
    /// the main thread is building a scene.
    public func notePresentationChanged(): Unit {
        revisionValue = revisionValue.saturatingAdd(1)
    }

    /// Monotonic presentation revision. It advances for mode/query/sort changes
    /// made through this object, for restores, and for direct layout edits the
    /// caller reports with `notePresentationChanged`. It is never the document
    /// version.
    public func revision(): Int64 {
        return revisionValue
    }

    public func snapshot(): CjguiComposableUiCollectionViewSnapshot {
        let columns = ArrayList<CjguiComposableUiTableColumnState>()
        for (key in layoutState.columnKeys()) {
            columns.add(CjguiComposableUiTableColumnState(key, layoutState.width(key),
                layoutState.isVisible(key)))
        }
        return CjguiComposableUiCollectionViewSnapshot(modeValue, table.query(),
            table.sortColumnKey(), table.sortAscending(), columns)
    }

    public func encodedSnapshot(): String {
        let result = encodedSnapshotChecked()
        if (let Some(value) <- result.encoded) {
            return value
        }
        return ""
    }

    /// Checked form for callers that must distinguish "the live view cannot be
    /// encoded under the public snapshot contract" from a valid empty string.
    public func encodedSnapshotChecked(): CjguiComposableUiCollectionViewEncodeResult {
        return CjguiComposableUiCollectionViewCodec.encodeChecked(snapshot())
    }

    /// Decode and apply in one step. A decode failure or any validation failure
    /// returns applied=false and leaves the current view untouched.
    public func restoreEncoded(value: String): CjguiComposableUiCollectionViewRestoreResult {
        let decoded = CjguiComposableUiCollectionViewCodec.decode(value)
        match (decoded.snapshot) {
            case Some(snapshot) => return applySnapshot(snapshot)
            case None => return failure(decoded.reason)
        }
    }

    /// Validate every section, then apply all of them. Column keys that the
    /// current declaration no longer has are ignored; current keys missing from
    /// the saved view are appended at their declared width and visibility.
    /// A sort on a deleted key is cleared. No mutation happens before all checks
    /// pass, and the layout object applies its plan atomically.
    public func applySnapshot(
        snapshot: CjguiComposableUiCollectionViewSnapshot
    ): CjguiComposableUiCollectionViewRestoreResult {
        if (!validModes.contains(snapshot.mode)) {
            return failure("unknown_view_mode")
        }
        let plan = ArrayList<CjguiComposableUiTableColumnState>()
        let ignored = ArrayList<String>()
        let seen = HashSet<String>()
        for (column in snapshot.columns) {
            if (!layoutState.hasColumn(column.key)) {
                ignored.add(column.key)
                continue
            }
            if (seen.contains(column.key)) {
                return failure("duplicate_column")
            }
            if (column.width < 0) {
                return failure("invalid_column_width")
            }
            seen.add(column.key)
            plan.add(column)
        }
        let added = ArrayList<String>()
        for (key in layoutState.declaredKeys()) {
            if (!seen.contains(key)) {
                seen.add(key)
                added.add(key)
                plan.add(CjguiComposableUiTableColumnState(key, layoutState.declaredWidth(key), true))
            }
        }
        if (plan.size == 0) {
            return failure("empty_view_columns")
        }
        var anyVisible = false
        for (column in plan) {
            if (column.visible) {
                anyVisible = true
                break
            }
        }
        if (!anyVisible) {
            return failure("all_columns_hidden")
        }
        var sortKey = snapshot.sortColumnKey
        var sortCleared = false
        if (sortKey.size > 0 && !layoutState.hasColumn(sortKey)) {
            sortKey = ""
            sortCleared = true
        }
        let modeBefore = modeValue
        let queryBefore = table.query()
        let sortKeyBefore = table.sortColumnKey()
        let sortAscendingBefore = table.sortAscending()
        let layoutBefore = layoutState.revision()
        if (!layoutState.applyState(plan)) {
            return failure("layout_rejected")
        }
        let _ = table.setSortState(sortKey, snapshot.sortAscending)
        let _ = table.setQuery(snapshot.query)
        modeValue = snapshot.mode
        let queryAfter = table.query()
        let sortKeyAfter = table.sortColumnKey()
        let sortAscendingAfter = table.sortAscending()
        let layoutAfter = layoutState.revision()
        let changed = modeBefore != modeValue || queryBefore != queryAfter ||
            sortKeyBefore != sortKeyAfter || sortAscendingBefore != sortAscendingAfter ||
            layoutBefore != layoutAfter
        if (changed) {
            revisionValue = revisionValue.saturatingAdd(1)
        }
        return CjguiComposableUiCollectionViewRestoreResult(true,
            if (changed) { "view_restored" } else { "view_unchanged" }, ignored, added, sortCleared)
    }

    /// Restores the declared default: default mode, no query, no sort, every
    /// declared column at its declared width and visible.
    public func resetToDefault(): CjguiComposableUiCollectionViewRestoreResult {
        let columns = ArrayList<CjguiComposableUiTableColumnState>()
        for (key in layoutState.declaredKeys()) {
            columns.add(CjguiComposableUiTableColumnState(key, layoutState.declaredWidth(key), true))
        }
        let result = applySnapshot(CjguiComposableUiCollectionViewSnapshot(defaultModeValue, "", "",
            true, columns))
        if (!result.applied) {
            return result
        }
        return CjguiComposableUiCollectionViewRestoreResult(true,
            if (result.reason == "view_unchanged") { "view_unchanged" } else { "view_reset" },
            result.ignoredColumnKeys, result.addedColumnKeys, result.sortCleared)
    }

    private func failure(reason: String): CjguiComposableUiCollectionViewRestoreResult {
        return CjguiComposableUiCollectionViewRestoreResult(false, reason,
            ArrayList<String>(), ArrayList<String>(), false)
    }
}

private func cjguiCollectionViewEncodeHex(value: String): String {
    let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    let result = StringBuilder()
    for (byte in value) {
        let numeric = Int64(byte)
        result.append(digits[numeric / 16])
        result.append(digits[numeric % 16])
    }
    return result.toString()
}

private func cjguiCollectionViewDecodeHex(value: String, maximumBytes: Int64): ?String {
    if (value.size == 0 || value.size % 2 != 0 || value.size > maximumBytes * 2) {
        return None
    }
    let source = value.toArray()
    let bytes = ArrayList<Byte>()
    var index: Int64 = 0
    while (index < source.size) {
        if (let Some(high) <- cjguiCollectionViewHexNibble(source[index])) {
            if (let Some(low) <- cjguiCollectionViewHexNibble(source[index + 1])) {
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

private func cjguiCollectionViewHexNibble(value: Byte): ?Int64 {
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
