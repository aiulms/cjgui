// Two live print-preset cards generated ONCE as one composite kind. Each card
// owns a different business object (owner 6301/6302) while reusing the ORIGINAL
// PrintPreset field definitions (jobName/copies/duplex, resource ids 6201-6203
// and the same APPLY_DRAFT/CANCEL_DRAFT vocabulary). The card facts are read
// through the instance-aware provider seam; no second draft, no per-card
// polling and no state machine live here beyond the business values themselves.
package cjgui_mixed_form_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.convert.*
import std.unicode.*

/// One preset card's business state. The field order matches PrintPresetDomain's
/// binding exactly, so a card and the handwritten preset edit the same declared
/// fields; only the owner target differs.
class PresetCard {
    public let ownerId: Int64
    public let title: String
    private let declarations: CjguiSharedFormBinding
    private var applied: ArrayList<CjguiSharedOperationValue>
    private var draft: ArrayList<String>
    private var fieldVersions: ArrayList<Int64>
    // Bounded per-field body history for selection rebasing. It is the owner's
    // OWN memory of what it published, not a second input state: the framework's
    // range session only asks this owner how to map a selection across a version
    // it accepted, and a refusal (None) is a legal answer.
    private let fieldBodies: HashMap<String, ArrayList<(Int64, String)>> = HashMap<String, ArrayList<(Int64, String)>>()
    private static let fieldBodyHistoryLimit: Int64 = 4
    private var draftVersion: Int64 = 0
    private var appliedVersion: Int64 = 0
    /// Owner-declared lock: while set, the card reports every field and both
    /// actions as unavailable WITH the same reason its write path refuses. It is
    /// owner state, not a second UI switch.
    private var locked: Bool = false
    private var revision: Int64 = 0

    init(ownerId: Int64, title: String, declarations: CjguiSharedFormBinding,
        defaults: ArrayList<CjguiSharedOperationValue>) {
        this.ownerId = ownerId
        this.title = title
        this.declarations = declarations
        this.applied = ArrayList<CjguiSharedOperationValue>(defaults)
        this.draft = ArrayList<String>()
        this.fieldVersions = ArrayList<Int64>()
        for (value in defaults) {
            this.draft.add(value.displayText())
            this.fieldVersions.add(0)
        }
    }

    public func ownerRevision(): Int64 {
        return revision
    }

    public func draftVersionValue(): Int64 {
        return draftVersion
    }

    public func isLocked(): Bool {
        return locked
    }

    public func setLocked(value: Bool): Unit {
        if (locked != value) {
            locked = value
            revision += 1
        }
    }

    private static func lockReason(): String {
        return "卡片已锁定，暂不可编辑"
    }

    /// The owner's reason while this card is locked ("" when editable), so a
    /// refused write names the SAME condition the projection published.
    public func lockedReason(): String {
        return if (locked) { PresetCard.lockReason() } else { "" }
    }

    public func binding(): CjguiSharedFormBinding {
        return declarations
    }

    private func indexOf(fieldId: String): Int64 {
        for (index in 0..declarations.fieldCount()) {
            if (declarations.fieldAtControlIndex(index).fieldId == fieldId) {
                return index
            }
        }
        return -1
    }

    public func validation(fieldId: String): String {
        let index = indexOf(fieldId)
        if (index < 0) {
            return "unknown_field"
        }
        let field = declarations.fieldAtControlIndex(index)
        let text = draft[index]
        if (field.required && text.trim().isEmpty()) {
            return "${field.label}不能为空"
        }
        if (field.editorKind == "TEXT" && field.maximumLength > 0 &&
            CjguiSharedFieldRule.scalarCount(text) > field.maximumLength) {
            return "${field.label}最多 ${field.maximumLength} 个字符"
        }
        if (field.editorKind == "INTEGER") {
            try {
                let value = Int64.parse(text)
                if (value < field.minimum || value > field.maximum) {
                    return "${field.label}需在 ${field.minimum}–${field.maximum} 之间"
                }
            } catch (_: Exception) {
                return "${field.label}需为整数"
            }
        }
        return ""
    }

    private func firstError(): String {
        for (index in 0..declarations.fieldCount()) {
            let error = validation(declarations.fieldAtControlIndex(index).fieldId)
            if (!error.isEmpty()) {
                return error
            }
        }
        return ""
    }

    public func draftText(fieldId: String): String {
        let index = indexOf(fieldId)
        return if (index < 0) { "" } else { draft[index] }
    }

    public func appliedText(fieldId: String): String {
        let index = indexOf(fieldId)
        return if (index < 0) { "" } else { applied[index].displayText() }
    }

    public func draftBoolean(fieldId: String): ?Bool {
        let index = indexOf(fieldId)
        if (index < 0 || declarations.fieldAtControlIndex(index).editorKind != "BOOLEAN") {
            return None
        }
        return Some(draft[index] == "true")
    }

    public func fieldVersion(fieldId: String): Int64 {
        let index = indexOf(fieldId)
        return if (index < 0) { 0 } else { fieldVersions[index] }
    }

    private func isTextField(fieldId: String): Bool {
        let index = indexOf(fieldId)
        return index >= 0 && declarations.fieldAtControlIndex(index).editorKind == "TEXT"
    }

    private func rememberFieldBody(fieldId: String, version: Int64, text: String): Unit {
        let history = match (fieldBodies.get(fieldId)) {
            case Some(value) => value
            case None =>
                let created = ArrayList<(Int64, String)>()
                fieldBodies.add(fieldId, created)
                created
        }
        var index: Int64 = 0
        while (index < history.size) {
            if (history[index][0] == version) {
                history[index] = (version, text)
                return
            }
            index += 1
        }
        history.add((version, text))
        while (history.size > PresetCard.fieldBodyHistoryLimit) {
            history.remove(at: 0)
        }
    }

    private func fieldBodyAt(fieldId: String, version: Int64): ?String {
        let history = match (fieldBodies.get(fieldId)) {
            case Some(value) => value
            case None => return None
        }
        for (entry in history) {
            if (entry[0] == version) {
                return Some(entry[1])
            }
        }
        return None
    }

    private func validTextSelection(text: String, startByte: Int64, endByte: Int64): Bool {
        let bytes = text.toArray()
        if (startByte < 0 || endByte < startByte || endByte > bytes.size) {
            return false
        }
        return cjguiIsUtf8Boundary(bytes, startByte) && cjguiIsUtf8Boundary(bytes, endByte)
    }

    /// Whether this card owns an atomic range transaction for the field. Only a
    /// TEXT field has one; INTEGER/BOOLEAN keep the whole-value intent path.
    public func rangeTextEditSupported(fieldId: String): Bool {
        return isTextField(fieldId)
    }

    /// The exact version the range transaction validates against: the same
    /// per-field input basis the whole-value writer advances.
    public func textVersion(fieldId: String): Int64 {
        return if (isTextField(fieldId)) { fieldVersion(fieldId) } else { -1 }
    }

    /// The owner's atomic range transaction: `newText` is the COMPLETE new value
    /// the framework bridge composed from the version it read; this owner only
    /// checks the version and the lock, then applies the whole value or refuses.
    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        let index = indexOf(fieldId)
        if (index < 0) {
            return CjguiRangeTextEditOutcome.rejected(-1, "unknown_field")
        }
        if (!isTextField(fieldId)) {
            return CjguiRangeTextEditOutcome.rejected(expectedVersion, "text_edit_unsupported")
        }
        if (locked) {
            return CjguiRangeTextEditOutcome.rejected(expectedVersion, PresetCard.lockReason())
        }
        let current = fieldVersions[index]
        if (current != expectedVersion) {
            rememberFieldBody(fieldId, current, draft[index])
            return CjguiRangeTextEditOutcome.conflict(current, "card_version_moved")
        }
        rememberFieldBody(fieldId, current, draft[index])
        if (!setText(fieldId, newText)) {
            return CjguiRangeTextEditOutcome.rejected(current, "text_edit_refused")
        }
        return CjguiRangeTextEditOutcome.accepted(current, fieldVersions[index])
    }

    /// Serial version confirmation used by session recovery.
    public func confirmTextVersion(fieldId: String, expectedVersion: Int64, action: () -> Bool): Bool {
        return isTextField(fieldId) && fieldVersion(fieldId) == expectedVersion && action()
    }

    /// Maps a selection this owner accepted at `fromVersion` onto the CURRENT
    /// body. Same policy as the handwritten form binding: unchanged version keeps
    /// the bytes; a later version whose body is unchanged keeps them; a body that
    /// really changed maps to the end (a whole-value write has no interior
    /// position), and an unknown/older version is refused instead of guessed.
    public func rebaseTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        let index = indexOf(fieldId)
        if (index < 0 || !isTextField(fieldId)) {
            return None
        }
        let currentVersion = fieldVersions[index]
        let current = draft[index]
        rememberFieldBody(fieldId, currentVersion, current)
        if (currentVersion == fromVersion) {
            return if (validTextSelection(current, startByte, endByte)) {
                Some((fromVersion, startByte, endByte))
            } else {
                None
            }
        }
        if (currentVersion < fromVersion) {
            return None
        }
        let previous = match (fieldBodyAt(fieldId, fromVersion)) {
            case Some(value) => value
            case None => return None
        }
        if (previous != current) {
            let end = Int64(current.toArray().size)
            return Some((currentVersion, end, end))
        }
        return if (validTextSelection(current, startByte, endByte)) {
            Some((currentVersion, startByte, endByte))
        } else {
            None
        }
    }

    public func setText(fieldId: String, text: String): Bool {
        if (locked) {
            // The owner refuses the write with the same reason the projection
            // published; the UI cannot buy a write with an old enabled state.
            return false
        }
        let index = indexOf(fieldId)
        if (index < 0 || declarations.fieldAtControlIndex(index).editorKind == "BOOLEAN") {
            return false
        }
        if (draft[index] == text) {
            // Idempotent re-delivery of the same value is not a business change.
            return true
        }
        // Whole-value writes must preserve the same input basis as range writes.
        // A modal return can still hold a selection from this exact version.
        if (isTextField(fieldId)) {
            rememberFieldBody(fieldId, fieldVersions[index], draft[index])
        }
        draft[index] = text
        fieldVersions[index] += 1
        draftVersion += 1
        revision += 1
        return true
    }

    public func setBoolean(fieldId: String, value: Bool): Bool {
        if (locked) {
            return false
        }
        let index = indexOf(fieldId)
        if (index < 0 || declarations.fieldAtControlIndex(index).editorKind != "BOOLEAN") {
            return false
        }
        draft[index] = if (value) { "true" } else { "false" }
        fieldVersions[index] += 1
        draftVersion += 1
        revision += 1
        return true
    }

    /// Apply admits only a valid draft, exactly like the handwritten preset.
    public func apply(): (Bool, String) {
        if (locked) {
            return (false, PresetCard.lockReason())
        }
        let error = firstError()
        if (!error.isEmpty()) {
            return (false, error)
        }
        for (index in 0..declarations.fieldCount()) {
            let kind = declarations.fieldAtControlIndex(index).editorKind
            applied[index] = if (kind == "BOOLEAN") {
                CjguiSharedOperationValue.boolean(draft[index] == "true")
            } else if (kind == "INTEGER") {
                CjguiSharedOperationValue.integer(Int64.parse(draft[index]))
            } else {
                CjguiSharedOperationValue.string(draft[index])
            }
        }
        // Apply copies the draft INTO the applied side. It must not advance
        // the draft revision again, or the card would remain forever dirty
        // (applied=1, draft=2) after a successful Apply.
        appliedVersion = draftVersion
        revision += 1
        return (true, "none")
    }

    /// Cancel restores the applied values for THIS card only.
    public func cancel(): (Bool, String) {
        if (locked) {
            return (false, PresetCard.lockReason())
        }
        var changed = false
        for (index in 0..declarations.fieldCount()) {
            let restored = applied[index].displayText()
            if (draft[index] != restored) {
                draft[index] = restored
                fieldVersions[index] += 1
                changed = true
            }
        }
        if (changed) {
            draftVersion += 1
        }
        // Cancel restores the applied values; the card is clean afterwards even
        // when no byte changed (only the version marker was stale).
        appliedVersion = draftVersion
        revision += 1
        return (true, "none")
    }

    public func snapshot(contextVersion: Int64): CjguiSharedFormSnapshot {
        let fields = ArrayList<CjguiSharedFormFieldProjection>()
        for (index in 0..declarations.fieldCount()) {
            let field = declarations.fieldAtControlIndex(index)
            fields.add(CjguiSharedFormFieldProjection(field.resourceId, field.fieldId, applied[index], draft[index],
                validation(field.fieldId), fieldVersions[index], false, 0, 0))
        }
        let error = firstError()
        // The owner CONTEXT version is the one the shared protocol checks for
        // CAS; the per-card draft version stays this object's own input basis.
        return CjguiSharedFormSnapshot(contextVersion, appliedVersion, draftVersion, appliedVersion, fields,
            error.isEmpty(), if (error.isEmpty()) { "卡片 ${title}" } else { error })
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        if (locked) {
            return CjguiSharedAvailability.blocked(PresetCard.lockReason(), ownerId, revision)
        }
        if (actionName == "APPLY_DRAFT") {
            let error = firstError()
            if (!error.isEmpty()) {
                return CjguiSharedAvailability.blocked(error, ownerId, revision)
            }
            return CjguiSharedAvailability.allowed(ownerId, revision)
        }
        if (actionName == "CANCEL_DRAFT") {
            var dirty = false
            for (index in 0..declarations.fieldCount()) {
                if (draft[index] != applied[index].displayText()) {
                    dirty = true
                }
            }
            if (!dirty) {
                return CjguiSharedAvailability.blocked("草稿与已应用值一致", ownerId, revision)
            }
            return CjguiSharedAvailability.allowed(ownerId, revision)
        }
        return CjguiSharedAvailability.blocked("unknown_action", ownerId, revision)
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        if (indexOf(fieldId) < 0) {
            return CjguiSharedAvailability.blocked("unknown_field", ownerId, revision)
        }
        if (locked) {
            return CjguiSharedAvailability.blocked(PresetCard.lockReason(), ownerId, revision)
        }
        return CjguiSharedAvailability.allowed(ownerId, revision)
    }
}

/// The card deck: two owners, one shared declaration set.
class PresetCardCollection {
    public static let cardAOwner: Int64 = 6301
    public static let cardBOwner: Int64 = 6302
    /// Explicit application authorization for the public client. It is the
    /// collection's own bounded owner allotment (the 30 seeded objects plus the
    /// next 30 objects this demo may create), plus the two owner ids the
    /// REBIND_CARD demonstration may target. It is not "all resources": the
    /// domain still refuses an owner that is not live, and an owner outside this
    /// declaration is refused by the transport before any domain work.
    public static func externalOwnerTargets(): ArrayList<Int64> {
        let owners = ArrayList<Int64>()
        var owner = 6301
        while (owner <= 6360) {
            owners.add(owner)
            owner += 1
        }
        owners.add(6400)
        owners.add(6500)
        return owners
    }
    private let declarations: CjguiSharedFormBinding
    private let cards: HashMap<String, PresetCard>
    /// The owner context version shared with the handwritten form. Card reads
    /// report THIS version so a client's CAS is the same CAS every other
    /// operation uses; a per-card counter would make every write stale.
    public var contextVersionReader: ?() -> Int64 = None

    // The ordered key log is the collection's identity order. A card's key never
    // changes when the view sorts/filters; only this list's PRESENTATION moves.
    private let order = ArrayList<String>(["cardA", "cardB"])
    private var selectedKeyValue: String = "cardA"
    private var filterValue: String = ""
    // The collection's sort is VIEW state owned by the app (the table consumes
    // it); it never renumbers keys or touches a draft.
    private var sortColumnValue: String = ""
    private var sortAscendingValue: Bool = true
    private var nextCardSuffix: Int64 = 3
    // Monotonic owner allotment. A retired owner id is NEVER reused: an old
    // request/session that still names it must stay refused instead of silently
    // becoming a write to a new object.
    private var nextOwnerValue: Int64 = 6303

    init(declarations: CjguiSharedFormBinding) {
        this.declarations = declarations
        this.cards = HashMap<String, PresetCard>()
        cards.add("cardA", PresetCard(PresetCardCollection.cardAOwner, "卡片 A", declarations,
            ArrayList<CjguiSharedOperationValue>([
                CjguiSharedOperationValue.string("资料 A"),
                CjguiSharedOperationValue.integer(4),
                CjguiSharedOperationValue.boolean(false)
            ])))
        cards.add("cardB", PresetCard(PresetCardCollection.cardBOwner, "卡片 B", declarations,
            ArrayList<CjguiSharedOperationValue>([
                CjguiSharedOperationValue.string("资料 B"),
                CjguiSharedOperationValue.integer(2),
                CjguiSharedOperationValue.boolean(true)
            ])))
        // 28 more ordinary objects: 30 in total, so the collection has to use its
        // existing bounded virtualization instead of laying every row out.
        for (index in 3..31) {
            let key = PresetCardCollection.orderedKey(index)
            let owner = 6300 + index
            cards.add(key, PresetCard(owner, "卡片 ${PresetCardCollection.twoDigit(index)}", declarations,
                ArrayList<CjguiSharedOperationValue>([
                    CjguiSharedOperationValue.string("资料 ${PresetCardCollection.twoDigit(index)}"),
                    CjguiSharedOperationValue.integer(Int64(index % 9 + 1)),
                    CjguiSharedOperationValue.boolean(index % 2 == 0)
                ])))
            order.add(key)
        }
        nextOwnerValue = 6301 + 30
        nextCardSuffix = 31
    }

    public func card(key: String): ?PresetCard {
        return cards.get(key)
    }

    /// Whether the key names a LIVE object. A deleted key keeps no object, so
    /// collection operations can refuse it instead of treating it as "unchanged".
    public func containsKey(key: String): Bool {
        return cards.contains(key)
    }

    // ---- collection identity ------------------------------------------------

    public func keysInOrder(): ArrayList<String> {
        let result = ArrayList<String>()
        for (key in order) {
            if (cards.contains(key)) {
                result.add(key)
            }
        }
        return result
    }

    public func count(): Int64 {
        return keysInOrder().size
    }

    public func selectedKey(): String {
        return selectedKeyValue
    }

    /// Selection is owner state; it never renumbers keys or touches a draft.
    public func selectKey(key: String): Bool {
        if (!cards.contains(key)) {
            return false
        }
        if (selectedKeyValue == key) {
            return false
        }
        selectedKeyValue = key
        return true
    }

    public func filterText(): String {
        return filterValue
    }

    public func sortColumn(): String {
        return sortColumnValue
    }

    public func sortAscending(): Bool {
        return sortAscendingValue
    }

    /// Toggles the table's own sort on one column: the same column flips the
    /// direction, a different column starts ascending.
    public func toggleSort(column: String): Bool {
        if (column != "name" && column != "owner") {
            return false
        }
        if (sortColumnValue == column) {
            sortAscendingValue = !sortAscendingValue
        } else {
            sortColumnValue = column
            sortAscendingValue = true
        }
        return true
    }

    public func setFilterText(value: String): Bool {
        if (filterValue == value) {
            return false
        }
        filterValue = value
        return true
    }

    /// Applies ONE explicit sort target (a restored view preference), rather than
    /// a repeated header toggle. The table and the business view stay the same
    /// fact: the caller writes this only when the restored snapshot says so.
    public func setSortState(column: String, ascending: Bool): Bool {
        if (column.size > 0 && column != "name" && column != "owner") {
            return false
        }
        if (sortColumnValue == column && sortAscendingValue == ascending) {
            return false
        }
        sortColumnValue = column
        sortAscendingValue = ascending
        return true
    }

    /// Adds one ordinary object at the END of the identity order. The key is a
    /// stable new identity, never a reused one; the owner id is derived from the
    /// same scale the seeded cards use (6301, 6302, ... => 6303, 6304, ...).
    public func addCard(title: String, defaults: ArrayList<CjguiSharedOperationValue>): ?String {
        while (nextCardSuffix < 1000) {
            let key = PresetCardCollection.orderedKey(nextCardSuffix)
            nextCardSuffix += 1
            if (cards.contains(key)) {
                continue
            }
            let owner = nextOwnerValue
            nextOwnerValue += 1
            cards.add(key, PresetCard(owner, title, declarations, defaults))
            order.add(key)
            return Some(key)
        }
        return None
    }

    /// Stable key for the seeded 30 objects: cardA, cardB, card03..card30.
    public static func orderedKey(index: Int64): String {
        return if (index == 1) { "cardA" } else if (index == 2) { "cardB" } else { "card${twoDigit(index)}" }
    }

    public static func twoDigit(value: Int64): String {
        return if (value < 10) { "0${value}" } else { "${value}" }
    }

    private static func suffixLetter(value: Int64): String {
        // 3 => C, 4 => D ... only the demo's small collections need this.
        return match (value) {
            case 3 => "C"
            case 4 => "D"
            case 5 => "E"
            case 6 => "F"
            case 7 => "G"
            case 8 => "H"
            case _ => "X${value}"
        }
    }

    /// A real delete retires the object: its key is gone from the identity order
    /// and its owner no longer resolves. Drafts of OTHER cards are untouched.
    public func deleteCard(key: String): Bool {
        if (!cards.contains(key) || cards.size <= 1) {
            return false
        }
        cards.remove(key)
        var index: Int64 = 0
        while (index < order.size) {
            if (order[index] == key) {
                order.remove(at: index)
            } else {
                index += 1
            }
        }
        if (selectedKeyValue == key) {
            let remaining = keysInOrder()
            selectedKeyValue = remaining[0]
        }
        return true
    }

    /// Explicit rebind: `key` now names a NEW owner object with its own values.
    /// The accepted scene keeps the old owner until the next structure canary is
    /// accepted; writes addressed to the retired owner are refused below.
    public func rebind(key: String, newOwner: Int64, title: String,
        defaults: ArrayList<CjguiSharedOperationValue>): Bool {
        if (!cards.contains(key) || newOwner <= 0) {
            return false
        }
        cards.add(key, PresetCard(newOwner, title, declarations, defaults))
        return true
    }

    public func ownerFor(key: String): Int64 {
        return match (cards.get(key)) {
            case Some(value) => value.ownerId
            case None => -1
        }
    }

    public func keyForOwner(ownerId: Int64): String {
        for ((key, card) in cards) {
            if (card.ownerId == ownerId) {
                return key
            }
        }
        return ""
    }

    public func revision(): Int64 {
        var total: Int64 = 0
        for ((_, card) in cards) {
            total += card.ownerRevision()
        }
        return total
    }

    public func feedback(key: String): ?CjguiGeneratedUiFormFeedback {
        let card = match (cards.get(key)) {
            case Some(value) => value
            case None => return None
        }
        // Every availability fact carries the SAME owner context version the
        // card's FORM_STATE reports; the reader rejects a mixed snapshot.
        let contextVersion = match (contextVersionReader) {
            case Some(reader) => reader()
            case None => card.ownerRevision()
        }
        let fieldStates = HashMap<String, CjguiSharedAvailability>()
        let actionStates = HashMap<String, CjguiSharedAvailability>()
        for (index in 0..declarations.fieldCount()) {
            let fieldId = declarations.fieldAtControlIndex(index).fieldId
            let fact = card.fieldAvailability(fieldId)
            fieldStates.add(fieldId,
                CjguiSharedAvailability(fact.known, fact.isAvailable, fact.reason, card.ownerId, contextVersion))
        }
        for (action in ["APPLY_DRAFT", "CANCEL_DRAFT"]) {
            let fact = card.actionAvailability(action)
            actionStates.add(action,
                CjguiSharedAvailability(fact.known, fact.isAvailable, fact.reason, card.ownerId, contextVersion))
        }
        return CjguiGeneratedUiFormFeedback(card.snapshot(contextVersion), declarations, card.ownerId,
            fieldStates, actionStates)
    }
}

/// The card builder. It reads only framework-resolved bindings; the one
/// application decision it makes is which control each role maps to, and how the
/// card is painted. Every node in the returned subtree carries a
/// framework-allocated element identity; the per-instance title rides the card's
/// semantic label AND the first declared child (a read-only text node the
/// framework identifies), and the card paints itself from the CURRENT theme so a
/// theme change never leaves light text on a light surface.
///
/// The visible structure is, in order:
///   child 0 title · child 1 note · child 2/3/4 per-field labels (when the
///   description declares all five) · the three field editors · the owner's
///   per-field error / blocking reason / "nothing to apply" state · actions.
/// Children are placed in DECLARED order; that order is this application's
/// contract with the descriptions it accepts, enforced by the composition check
/// and by the client that generates them. A description with fewer children still
/// renders (the extra labels are simply absent) instead of failing the scene.
class PresetCardFactory <: CjguiCompositeComponentFactory {
    private let themeReader: () -> CjguiComposableUiTheme

    init(themeReader: () -> CjguiComposableUiTheme) {
        this.themeReader = themeReader
    }

    /// The card surface, from the SAME theme object the handwritten area uses.
    private static func cardStyle(theme: CjguiComposableUiTheme): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(gap: 4, padding: 10, growX: 1,
            background: theme.card.background, border: theme.card.border,
            borderWidth: theme.card.borderWidth, cornerRadius: theme.card.cornerRadius,
            textColor: theme.body.textColor)
    }

    private static func editorStyle(theme: CjguiComposableUiTheme): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(fixedHeight: 28, fontSize: 12.5, growX: 1,
            background: theme.input.background, border: theme.input.border,
            borderWidth: theme.input.borderWidth, textColor: theme.input.textColor,
            padding: theme.input.padding, cornerRadius: theme.input.cornerRadius)
    }

    private static func actionStyle(theme: CjguiComposableUiTheme): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(fixedHeight: 26, fontSize: 12.0,
            background: theme.primaryAction.background, border: theme.primaryAction.border,
            borderWidth: theme.primaryAction.borderWidth, textColor: theme.primaryAction.textColor,
            padding: theme.primaryAction.padding, cornerRadius: theme.primaryAction.cornerRadius)
    }

    /// One red that stays readable on THIS theme's card surface: a light red on
    /// the dark card, a dark red on the light card. The card's own background is
    /// the decision input, so a theme change repaints both together.
    private static func errorStyle(theme: CjguiComposableUiTheme): CjguiComposableUiStyle {
        let surface = theme.card.background
        let lightSurface = surface.red + surface.green + surface.blue > 1.5
        return CjguiComposableUiStyle(fontSize: 11.5, growX: 1, textMaxLines: 2, textOverflow: "ellipsis",
            textColor: if (lightSurface) {
                CjguiComposableUiColor(0.70, 0.11, 0.11, 1.0)
            } else {
                CjguiComposableUiColor(0.99, 0.52, 0.48, 1.0)
            })
    }

    /// Owner-provided explanatory text (a blocking reason, a business state).
    private static func noteStyle(theme: CjguiComposableUiTheme): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(fontSize: 11.5, growX: 1, textMaxLines: 2, textOverflow: "ellipsis",
            textColor: theme.body.textColor)
    }

    /// One projection element, mounted ONLY while the owner publishes text for
    /// it: an absent error leaves no gap, and a new error appears at the same
    /// stable element identity without a structure resubmit.
    private static func addProjection(parent: CjguiComposableUiNode, context: CjguiCompositeBuildContext,
        key: String, style: CjguiComposableUiStyle): Unit {
        if (let Some(projection) <- context.element(key)) {
            if (!projection.projectionText.isEmpty()) {
                parent.add(
                    cjguiComposableText(projection.nodeId, projection.semanticId, projection.projectionText, style))
            }
        }
    }

    private func addEditor(parent: CjguiComposableUiNode, field: CjguiCompositeElementBinding,
        theme: CjguiComposableUiTheme): Unit {
        let style = PresetCardFactory.editorStyle(theme)
        if (field.editorKind == "BOOLEAN") {
            parent.add(cjguiComposableBooleanInput(field.nodeId, field.semanticId, field.label, field.draftBoolean,
                field.bindingResourceId, style, enabled: field.ownerAvailable, fieldId: field.fieldId,
                operationActionName: field.writerOperation, operationResourceId: field.ownerTargetResourceId,
                displayValueRole: "draft", interactionStyle: theme.inputInteraction))
        } else if (field.editorKind == "INTEGER") {
            parent.add(cjguiComposableIntegerInput(field.nodeId, field.semanticId, field.label, field.draftText,
                field.bindingResourceId, style, enabled: field.ownerAvailable, fieldId: field.fieldId,
                operationActionName: field.writerOperation, operationResourceId: field.ownerTargetResourceId,
                displayValueRole: "draft", interactionStyle: theme.inputInteraction))
        } else {
            // The TEXT editor carries the owner's answer like the other two: an
            // unavailable field must not look editable (the composite audit
            // refuses the opposite, so this is the one shared rule).
            parent.add(cjguiComposableTextInput(field.nodeId, field.semanticId, field.label, field.draftText,
                field.bindingResourceId, style, enabled: field.ownerAvailable, fieldId: field.fieldId,
                operationActionName: field.writerOperation, operationResourceId: field.ownerTargetResourceId,
                displayValueRole: "draft", interactionStyle: theme.inputInteraction))
        }
    }

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let theme = themeReader()
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        let title = context.property("title")
        let card = CjguiComposableUiNode(root.nodeId, root.semanticId, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "",
            -1, PresetCardFactory.cardStyle(theme), semanticLabel: title)
        // Declared children carry the readable title, the note and the per-field
        // labels: they are ORDINARY generated nodes, so their identity, style
        // reference, overflow and theme paint are the framework's own path.
        let children = context.children
        let labelled = children.size >= 5
        if (labelled) {
            card.add(children[0])
            card.add(children[1])
        } else {
            for (child in children) {
                card.add(child)
            }
        }
        if (labelled) {
            card.add(children[2])
        }
        if (let Some(field) <- context.element("name")) {
            addEditor(card, field, theme)
        }
        PresetCardFactory.addProjection(card, context, "nameError", PresetCardFactory.errorStyle(theme))
        if (labelled) {
            card.add(children[3])
        }
        if (let Some(field) <- context.element("copies")) {
            addEditor(card, field, theme)
        }
        PresetCardFactory.addProjection(card, context, "copiesError", PresetCardFactory.errorStyle(theme))
        if (labelled) {
            card.add(children[4])
        }
        if (let Some(field) <- context.element("duplex")) {
            addEditor(card, field, theme)
        }
        PresetCardFactory.addProjection(card, context, "duplexError", PresetCardFactory.errorStyle(theme))
        // The owner's own reason while a field is blocked (the card lock) and its
        // own "nothing to apply" state: both are owner facts, never guesses. Two
        // owner facts that say the SAME thing are shown once (a lock is not
        // repeated as its own explanation).
        let reason = match (context.element("cardReason")) {
            case Some(value) => value.projectionText
            case None => ""
        }
        // Evidence channel: the SAME owner reason this build projects into the
        // card is printed when it exists, so a reader can tie the visible text to
        // the owner state without parsing the scene.
        if (!reason.isEmpty()) {
            getStdOut().writeln("PRESET_CARD_OWNER_REASON key=${context.instanceKey} reason=[${reason}]")
            getStdOut().flush()
        }
        PresetCardFactory.addProjection(card, context, "cardReason", PresetCardFactory.noteStyle(theme))
        if (let Some(state) <- context.element("stateText")) {
            if (!state.projectionText.isEmpty() && state.projectionText != reason) {
                card.add(
                    cjguiComposableText(state.nodeId, state.semanticId, state.projectionText,
                        PresetCardFactory.noteStyle(theme)))
            }
        }
        if (let Some(row) <- context.element("actions")) {
            let actions = cjguiComposableHorizontal(row.nodeId, row.semanticId,
                CjguiComposableUiStyle(gap: 6, growX: 1))
            for (key in ["apply", "cancel"]) {
                if (let Some(action) <- context.element(key)) {
                    actions.add(cjguiComposableButton(action.nodeId, action.semanticId, action.label,
                        "GENERATED_ACTION", action.ownerTargetResourceId, PresetCardFactory.actionStyle(theme),
                        enabled: action.actionEnabled, operationResourceId: action.ownerTargetResourceId,
                        interactionStyle: theme.primaryActionInteraction,
                        semanticHelp: if (action.actionEnabled) { "" } else { action.blockedReason }))
                }
            }
            card.add(actions)
        }
        return card
    }
}

/// Named styles the accepted DESCRIPTION references for the readable children.
/// They are resolved through the framework's named-style catalog on every build,
/// so a theme change reaches titles/notes/labels on the next refresh without a
/// structure resubmit. The base paint comes from the theme; the description only
/// adds local geometry (growth, line limits).
func presetCardTitleStyleName(): String {
    return "preset-card-title"
}

func presetCardNoteStyleName(): String {
    return "preset-card-note"
}

func presetCardFieldLabelStyleName(): String {
    return "preset-card-field-label"
}

func syncPresetCardNamedStyles(catalog: CjguiGeneratedUiCapabilityCatalog,
    theme: CjguiComposableUiTheme): Bool {
    let definitions = ArrayList<CjguiComposableUiNamedStyle>()
    definitions.add(CjguiComposableUiNamedStyle(presetCardTitleStyleName(),
        CjguiComposableUiStyle(textColor: theme.heading.textColor, fontSize: 15.0, fontWeight: 1),
        purpose: "preset card title"))
    definitions.add(CjguiComposableUiNamedStyle(presetCardNoteStyleName(),
        CjguiComposableUiStyle(textColor: theme.body.textColor, fontSize: 11.5, textMaxLines: 2,
            textOverflow: "ellipsis"), purpose: "preset card note"))
    definitions.add(CjguiComposableUiNamedStyle(presetCardFieldLabelStyleName(),
        CjguiComposableUiStyle(textColor: theme.body.textColor, fontSize: 11.5), purpose: "preset card field label"))
    var ok = true
    for (definition in definitions) {
        if (catalog.namedStyles().forName(definition.name).isSome()) {
            if (!catalog.namedStyles().update(definition)) { ok = false }
        } else if (!catalog.namedStyles().register(definition)) {
            ok = false
        }
    }
    return ok
}

/// One composite kind over the ORIGINAL field definitions; applying it to a
/// catalog that already declares jobName/copies/duplex/APPLY_DRAFT/CANCEL_DRAFT
/// keeps a single vocabulary for the handwritten form and every card.
func registerPresetCardComposite(catalog: CjguiGeneratedUiCapabilityCatalog,
    themeReader: () -> CjguiComposableUiTheme): Bool {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    properties.add(CjguiGeneratedUiPropertySpec("title", "STRING", maxLength: 40))
    let elements = ArrayList<CjguiCompositeElementSpec>()
    elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
    elements.add(CjguiCompositeElementSpec("actions", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("name", CJGUI_COMPOSITE_ELEMENT_FIELD, fieldId: "jobName",
        argumentName: "text", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("copies", CJGUI_COMPOSITE_ELEMENT_FIELD, fieldId: "copies",
        argumentName: "text", parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("duplex", CJGUI_COMPOSITE_ELEMENT_FIELD, fieldId: "duplex",
        argumentName: "value", parentKey: "root"))
    // Per-field owner text and the card's own state are PROJECTIONS of the one
    // frozen card snapshot: a new validation error, a lock or an unlock reaches
    // the visible line without re-submitting the structure.
    for (key in ["name", "copies", "duplex"]) {
        elements.add(CjguiCompositeElementSpec("${key}Error", CJGUI_COMPOSITE_ELEMENT_PROJECTION,
            fieldId: if (key == "name") { "jobName" } else if (key == "copies") { "copies" } else { "duplex" },
            source: CJGUI_COMPOSITE_PROJECTION_FIELD_ERROR, parentKey: "root"))
    }
    elements.add(CjguiCompositeElementSpec("cardReason", CJGUI_COMPOSITE_ELEMENT_PROJECTION,
        fieldId: "jobName", source: CJGUI_COMPOSITE_PROJECTION_FIELD_REASON, parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("stateText", CJGUI_COMPOSITE_ELEMENT_PROJECTION,
        actionName: "CANCEL_DRAFT", source: CJGUI_COMPOSITE_PROJECTION_ACTION_REASON, parentKey: "root"))
    elements.add(CjguiCompositeElementSpec("apply", CJGUI_COMPOSITE_ELEMENT_ACTION,
        actionName: "APPLY_DRAFT", label: "应用", parentKey: "actions"))
    elements.add(CjguiCompositeElementSpec("cancel", CJGUI_COMPOSITE_ELEMENT_ACTION,
        actionName: "CANCEL_DRAFT", label: "取消", parentKey: "actions"))
    return catalog.registerComposite(
        CjguiCompositeComponentSpec("presetCard", properties, elements, allowsChildren: true, childLimit: 8,
            expandedNodeLimit: 22, expandedDepthLimit: 3), PresetCardFactory(themeReader))
}

/// The fallback binding for DEFAULT instances: the handwritten preset's exact
/// behaviour plus the collection row's SELECT_CARD transaction. Card instances
/// are routed by the shared `CjguiGeneratedUiMultiObjectBinding`; this class no
/// longer contains a second per-card router.
class MixedPresetProvider <: CjguiGeneratedUiRegionBinding {
    private let form: CjguiGeneratedUiFormBinding
    private let cards: PresetCardCollection
    private let domain: PrintPresetDomain

    init(form: CjguiGeneratedUiFormBinding, cards: PresetCardCollection, domain: PrintPresetDomain) {
        this.form = form
        this.cards = cards
        this.domain = domain
    }

    public func ownerRevision(): Int64 {
        return form.ownerRevision()
    }

    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        let inner = form.formFeedback()
        let reason = domain.lockReason()
        if (reason.size == 0) {
            return inner
        }
        let snapshot = domain.formSnapshot()
        let fieldStates = HashMap<String, CjguiSharedAvailability>()
        for (field in form.fieldSpecs()) {
            fieldStates.add(field.fieldId,
                CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId, snapshot.contextVersion))
        }
        let actionStates = HashMap<String, CjguiSharedAvailability>()
        for (action in domain.actionDescriptors()) {
            actionStates.add(action.name,
                CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId, snapshot.contextVersion))
        }
        return Some(CjguiGeneratedUiFormFeedback(snapshot, domain.formBinding(), PrintPresetDomain.ownerId,
            fieldStates, actionStates))
    }

    public func formFeedback(instanceKey: String): ?CjguiGeneratedUiFormFeedback {
        return form.formFeedback(instanceKey)
    }

    public func fieldResourceId(fieldId: String): Int64 {
        return form.fieldResourceId(fieldId)
    }

    public func generatedSelectBinding(fieldId: String): ?CjguiSelectFieldBinding {
        return form.generatedSelectBinding(fieldId)
    }

    public func generatedSelectBindings(): ArrayList<CjguiSelectFieldBinding> {
        return form.generatedSelectBindings()
    }

    public func fieldOperationResourceId(fieldId: String): Int64 {
        return form.fieldOperationResourceId(fieldId)
    }

    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        return form.fieldOperationResourceId(fieldId, instanceKey)
    }

    public func draftText(fieldId: String): String {
        return form.draftText(fieldId)
    }

    public func draftText(fieldId: String, instanceKey: String): String {
        return form.draftText(fieldId, instanceKey)
    }

    public func appliedText(fieldId: String): String {
        return form.appliedText(fieldId)
    }

    public func draftBoolean(fieldId: String): ?Bool {
        return form.draftBoolean(fieldId)
    }

    public func draftBoolean(fieldId: String, instanceKey: String): ?Bool {
        return form.draftBoolean(fieldId, instanceKey)
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        let reason = domain.lockReason()
        if (reason.size > 0) {
            return CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId, ownerRevision())
        }
        return form.fieldAvailability(fieldId)
    }

    public func fieldAvailability(fieldId: String, instanceKey: String): CjguiSharedAvailability {
        let reason = domain.lockReason()
        if (reason.size > 0) {
            return CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId, ownerRevision())
        }
        return form.fieldAvailability(fieldId, instanceKey)
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        let reason = domain.lockReason()
        if (reason.size > 0) {
            return CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId, ownerRevision())
        }
        return form.actionAvailability(actionName)
    }

    public func actionAvailability(actionName: String, instanceKey: String): CjguiSharedAvailability {
        let reason = domain.lockReason()
        if (reason.size > 0) {
            return CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId, ownerRevision())
        }
        return form.actionAvailability(actionName, instanceKey)
    }

    public func actionAvailable(actionName: String): Bool {
        return form.actionAvailable(actionName)
    }

    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 {
        let _ = actionName
        let _ = instanceKey
        return -1
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return form.executeAction(actionName, nodeKey)
    }

    public func executeAction(actionName: String, nodeKey: String, instanceKey: String):
        CjguiGeneratedUiActionResult {
        return form.executeAction(actionName, nodeKey, instanceKey)
    }

    /// The collection's row activation. The collection composite is NOT a card
    /// instance; its row action names the card OWNER it was built for, and this
    /// fallback is the one place that translates that public owner id into the
    /// domain's SELECT_CARD transaction (the domain still owns the selection).
    private func selectCollectionRow(nodeKey: String,
        ownerTargetResourceId: Int64): CjguiGeneratedUiActionResult {
        let _ = nodeKey
        let key = cards.keyForOwner(ownerTargetResourceId)
        if (key.size == 0) {
            return CjguiGeneratedUiActionResult(false, "unknown_target")
        }
        let call = CjguiSharedOperationActionInvocation("SELECT_CARD",
            domain.formSnapshot().contextVersion,
            ArrayList<Int64>([PrintPresetDomain.ownerId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("cardKey", CjguiSharedOperationValue.string(key))
            ]))
        let outcome = domain.executeFromHuman(call)
        return CjguiGeneratedUiActionResult(outcome.applied, outcome.reason)
    }

    public func executeAction(actionName: String, nodeKey: String, instanceKey: String,
        ownerTargetResourceId: Int64, instanceIncarnation: Int64): CjguiGeneratedUiActionResult {
        let _ = instanceIncarnation
        if (actionName == "SELECT_CARD") {
            return selectCollectionRow(nodeKey, ownerTargetResourceId)
        }
        return form.executeAction(actionName, nodeKey, instanceKey,
            ownerTargetResourceId, instanceIncarnation)
    }

    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return form.applyFieldIntent(intent)
    }

    public func rangeTextEditSupported(fieldId: String, instanceKey: String): Bool {
        return form.rangeTextEditSupported(fieldId, instanceKey)
    }

    public func fieldTextVersion(fieldId: String, instanceKey: String): Int64 {
        return form.fieldTextVersion(fieldId, instanceKey)
    }

    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64, action: () -> Bool,
        instanceKey: String): Bool {
        return form.confirmFieldTextVersion(fieldId, expectedVersion, action, instanceKey)
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String,
        instanceKey: String): CjguiRangeTextEditOutcome {
        return form.applyTextEdit(fieldId, expectedVersion, newText, instanceKey)
    }

    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64,
        endByte: Int64, instanceKey: String): ?(Int64, Int64, Int64) {
        return form.rebaseFieldTextSelection(fieldId, fromVersion, startByte, endByte, instanceKey)
    }

    public func rangeTextEditSupported(fieldId: String): Bool {
        return form.rangeTextEditSupported(fieldId)
    }

    public func fieldTextVersion(fieldId: String): Int64 {
        return form.fieldTextVersion(fieldId)
    }

    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64, action: () -> Bool): Bool {
        return form.confirmFieldTextVersion(fieldId, expectedVersion, action)
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String): CjguiRangeTextEditOutcome {
        let outcome = form.applyTextEdit(fieldId, expectedVersion, newText)
        getStdOut().writeln("PRESET_FORM_RANGE_EDIT field=${fieldId} expected=${expectedVersion} " +
            "applied=${outcome.applied} conflict=${outcome.isVersionConflict} before=${outcome.versionBefore} " +
            "after=${outcome.versionAfter} reason=${outcome.reason}")
        getStdOut().flush()
        return outcome
    }

    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64,
        endByte: Int64): ?(Int64, Int64, Int64) {
        return form.rebaseFieldTextSelection(fieldId, fromVersion, startByte, endByte)
    }
}

/// ONE card addressed by its declared instance key. The accepted owner target,
/// draft, availability and range transaction all stay on the original
/// `PresetCard`; this wrapper only presents that owner through the shared
/// object contract.
class PresetCardObjectBinding <: CjguiGeneratedUiObjectBinding {
    private let card: PresetCard
    private let feedback: () -> ?CjguiGeneratedUiFormFeedback

    init(card: PresetCard, feedback: () -> ?CjguiGeneratedUiFormFeedback) {
        this.card = card
        this.feedback = feedback
    }

    public func ownerTargetResourceId(): Int64 {
        return card.ownerId
    }

    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        return feedback()
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        return card.fieldAvailability(fieldId)
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        return card.actionAvailability(actionName)
    }

    public func draftText(fieldId: String): String {
        return card.draftText(fieldId)
    }

    public func draftBoolean(fieldId: String): ?Bool {
        return card.draftBoolean(fieldId)
    }

    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        if (!intent.isFieldEdit() || intent.ownerTargetResourceId != card.ownerId ||
            intent.fieldId.size == 0) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (card.rangeTextEditSupported(intent.fieldId)) {
            getStdOut().writeln("PRESET_CARD_WHOLE_TEXT_INTENT key=${intent.instanceKey} field=${intent.fieldId}")
            getStdOut().flush()
        }
        let applied = if (intent.value.valueType == "BOOLEAN") {
            card.setBoolean(intent.fieldId, intent.value.booleanValue)
        } else if (intent.value.valueType == "STRING") {
            card.setText(intent.fieldId, intent.value.stringValue)
        } else {
            card.setText(intent.fieldId, intent.value.displayText())
        }
        return CjguiComposableUiDispatchResult(applied)
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        let _ = nodeKey
        if (actionName == "SET_LOCK") {
            return CjguiGeneratedUiActionResult(false, "lock_is_domain_action")
        }
        let availability = card.actionAvailability(actionName)
        if (availability.known && !availability.isAvailable) {
            return CjguiGeneratedUiActionResult(false, availability.reason)
        }
        let outcome = if (actionName == "APPLY_DRAFT") {
            card.apply()
        } else if (actionName == "CANCEL_DRAFT") {
            card.cancel()
        } else {
            (false, "unknown_action")
        }
        return CjguiGeneratedUiActionResult(outcome[0], outcome[1])
    }

    public func rangeTextEditSupported(fieldId: String): Bool {
        return card.rangeTextEditSupported(fieldId)
    }

    public func fieldTextVersion(fieldId: String): Int64 {
        return card.textVersion(fieldId)
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64,
        newText: String): CjguiRangeTextEditOutcome {
        let outcome = card.applyTextEdit(fieldId, expectedVersion, newText)
        getStdOut().writeln("PRESET_CARD_RANGE_EDIT key=${card.title} field=${fieldId} expected=${expectedVersion} " +
            "applied=${outcome.applied} conflict=${outcome.isVersionConflict} before=${outcome.versionBefore} " +
            "after=${outcome.versionAfter} reason=${outcome.reason}")
        getStdOut().flush()
        return outcome
    }

    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64,
        action: () -> Bool): Bool {
        return card.confirmTextVersion(fieldId, expectedVersion, action)
    }

    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64,
        startByte: Int64, endByte: Int64): ?(Int64, Int64, Int64) {
        return card.rebaseTextSelection(fieldId, fromVersion, startByte, endByte)
    }
}

/// Resolve one DECLARED card key to its live object wrapper, or None after the
/// object was deleted. `namesObject` keeps the key named either way.
func presetCardObjectBinding(cards: PresetCardCollection,
    key: String): ?CjguiGeneratedUiObjectBinding {
    return match (cards.card(key)) {
        case Some(card) => Some(PresetCardObjectBinding(card, { => cards.feedback(key) }))
        case None => None
    }
}

// ---------------------------------------------------------------------------
// The preset object collection
//
// One ordinary object collection over the SAME PresetCard owners: stable key
// items, a filtered/sorted view, one selection object and one row action. The
// collection renders through the framework's existing generated collection
// composite (CjguiGeneratedUiCollection + table + selection); this file only
// supplies the business items, their titles and the SELECT_CARD row action. It
// does not render rows, sort, filter or virtualize anything itself.
// ---------------------------------------------------------------------------

public class PresetCardRows <: CjguiComposableUiVariableHeightListSource {
    private let cards: PresetCardCollection
    private let themeReader: () -> CjguiComposableUiTheme
    init(cards: PresetCardCollection, themeReader: () -> CjguiComposableUiTheme) {
        this.cards = cards
        this.themeReader = themeReader
    }
    public func itemCount(): Int64 {
        return cards.count()
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        let keys = cards.keysInOrder()
        if (index < 0 || index >= keys.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let key = keys[index]
        let card = match (cards.card(key)) {
            case Some(value) => value
            case None => return CjguiComposableUiVariableHeightListItem.missing()
        }
        return CjguiComposableUiVariableHeightListItem(key, card.ownerId,
            "${card.title} · ${card.ownerId}", card.ownerRevision(), estimatedHeight: 30)
    }
    public func indexForKey(key: String): Int64 {
        let keys = cards.keysInOrder()
        for (index in 0..keys.size) {
            if (keys[index] == key) {
                return index
            }
        }
        return -1
    }
    public func measurementGeneration(): Int64 {
        return 0
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, selected: Bool,
        focused: Bool): CjguiComposableUiNode {
        // DS51 §12 B1: a REAL variable-height row. The title wraps at the
        // current width (no fixed height, unlimited lines), so a long object
        // name and a short one have different measured heights; the trailing
        // button keeps the ordinary SELECT_CARD activation. It is NOT the fixed
        // table row renamed: the list presentation measures this subtree.
        let theme = themeReader()
        let background = if (selected || focused) { theme.page.background } else { theme.card.background }
        let scope = CjguiComposableUiIdentityScope("preset-card-list")
        let row = cjguiComposableVertical(-1, "preset-card-row-${item.key}",
            CjguiComposableUiStyle(growX: 1, padding: 6, gap: 3, background: background,
                border: if (selected || focused) { theme.primaryAction.background } else { theme.card.border },
                borderWidth: if (selected || focused) { 2 } else { 1 }, cornerRadius: 4),
            identity: Some(scope.child(item.key).local("row")))
        row.add(cjguiComposableText(-1, "preset-card-row-title-${item.key}", item.title,
            CjguiComposableUiStyle(growX: 1, textColor: theme.body.textColor,
                fontSize: 12.5, lineHeight: 17.0, textMaxLines: 0, textOverflow: "clip"),
            identity: Some(scope.child(item.key).local("title"))))
        row.add(cjguiComposableButton(-1, "preset-card-row-select-${item.key}", "选择", "SELECT_CARD",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 24, minWidth: 56, padding: 2,
                background: theme.card.background, textColor: theme.body.textColor,
                border: theme.card.border, borderWidth: 1, textMaxLines: 1, textOverflow: "ellipsis"),
            operationActionName: "SELECT_CARD", operationResourceId: item.resourceId,
            identity: Some(scope.child(item.key).local("select"))))
        return row
    }
}

/// The collection wiring: one framework collection composite over the rows, the
/// table view with its sort actions, and the selection object. The controller
/// owns these; the description only chooses list/table presentation.
public class PresetCardList {
    public let collection: CjguiGeneratedUiCollection
    public let selection: CjguiComposableUiCollectionSelection
    public let rows: PresetCardRows
    private let cards: PresetCardCollection
    private let filtered: CjguiComposableUiFilteredListSource
    private let table: CjguiComposableUiTableSource
    // DS51 §12 B: the SAME public view state and thin workspace the rules
    // consumer mounts. Query/sort stay projections of the business view the
    // domain owns; mode/columns and the validated snapshot text belong to the
    // public view state.
    private let viewState: CjguiComposableUiCollectionViewState
    private let workspace: CjguiCollectionWorkspace
    private let themeReader: () -> CjguiComposableUiTheme
    private var savedViewSnapshot: String = ""

    init(cards: PresetCardCollection, themeReader: () -> CjguiComposableUiTheme) {
        this.cards = cards
        this.themeReader = themeReader
        // Locals first: a closure may not read members before every member is
        // initialized, and the table needs one selection object for its paint.
        let selected = CjguiComposableUiCollectionSelection()
        let rows = PresetCardRows(cards, themeReader)
        // The filter reuses the table's existing query field: rows are matched by
        // their visible title only, so a hidden object keeps its key and draft.
        let filtered = CjguiComposableUiFilteredListSource(rows, {item => item.title})
        this.rows = rows
        this.filtered = filtered
        this.selection = selected
        let name = CjguiComposableUiTableColumn("name", "名称", "label", 200, "SORT_NAME",
            {item => item.title}, {a, b => if (a.title < b.title) {
                -1
            } else if (a.title > b.title) {
                1
            } else {
                0
            }})
        let owner = CjguiComposableUiTableColumn("owner", "拥有者", "resourceId", 90, "SORT_OWNER",
            {item => "${item.resourceId}"}, {a, b => a.resourceId - b.resourceId})
        let style = CjguiComposableUiTableStyle(30, 30, 6, 12.5, "PingFang SC",
            CjguiComposableUiColor(0.10, 0.12, 0.18, 1.0), CjguiComposableUiColor(0.28, 0.40, 0.62, 1.0),
            CjguiComposableUiColor(0.16, 0.19, 0.26, 1.0), CjguiComposableUiColor(0.30, 0.36, 0.48, 1.0),
            CjguiComposableUiColor(0.95, 0.96, 1.0, 1.0), CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            CjguiComposableUiColor(0.70, 0.75, 0.85, 1.0), CjguiComposableUiColor(0.30, 0.60, 1.0, 1.0))
        this.table = CjguiComposableUiTableSource(filtered, "preset-card-table", [name, owner], style,
            rowAction: Some({item => CjguiComposableUiTableRowAction("SELECT_CARD", item.resourceId)}),
            rowSelected: Some({key => selected.isSelected(key)}))
        this.collection = CjguiGeneratedUiCollection("presetCards", "presetCardList", rows, table, selection)
        let view = CjguiComposableUiCollectionViewState(table, ["list", "table"], "list")
        this.viewState = view
        let modePresentations = HashMap<String, String>()
        modePresentations.add("list", "list")
        modePresentations.add("table", "table")
        this.workspace = CjguiCollectionWorkspace(collection, view,
            CjguiComposableUiIdentityScope("preset-card-workspace"),
            title: "预设卡片集合", modePresentations: modePresentations,
            viewAuthority: { query, sortKey, ascending =>
                // The cards owner is the authority for query/sort. Apply the
                // restored values through it before the view adopts mode/columns;
                // the next ordinary syncFilter then projects the SAME facts.
                let _ = cards.setFilterText(query)
                let _ = cards.setSortState(sortKey, ascending)
                cards.filterText() == query && cards.sortColumn() == sortKey &&
                    cards.sortAscending() == ascending
            })
        let order = collection.order()
        if (order.indexOfKey(cards.selectedKey()) >= 0) {
            selection.click(cards.selectedKey(), false, false, order)
        } else if (order.count() > 0) {
            // No accepted owner selection: focus the first row without claiming
            // a selection the owner never made.
            let _ = selection.moveFocus(order.keyAt(0), false, order)
        }
    }

    public func register(catalog: CjguiGeneratedUiCapabilityCatalog): Bool {
        return collection.register(catalog)
    }

    /// The accepted generated mount whose EXACT viewport object this event
    /// carries. Stale generations and foreign viewports resolve to None.
    public func acceptedViewForEvent(event: CjguiComposableUiEvent): ?CjguiGeneratedCollectionView {
        let viewport = match (event.node.scrollViewport) {
            case Some(value) => value
            case None => return None
        }
        return collection.acceptedViewForViewport(viewport)
    }

    /// Applies the owner's current filter and sort to the view. This is the ONLY
    /// place either moves; the collection composite reads the same table.
    public func syncFilter(): Bool {
        if (getVariable("CJGUI_VIEW_TRACE") == Some("1")) {
            getStdOut().writeln("PRESET_VIEW_TRACE owner=[${cards.filterText()}] " +
                "sort=[${cards.sortColumn()}] asc=${cards.sortAscending()} " +
                "view=[${workspace.viewState().query()}] viewSort=[${workspace.viewState().sortColumnKey()}]")
            getStdOut().flush()
        }
        // The QUERY goes through the shared table (not straight to the filtered
        // source): the table caches its own sorted order and only a table-level
        // query change invalidates it, so a hidden object cannot survive in a
        // cached order. The public workspace applies this one business fact; the
        // rules consumer uses the same entry for its view-state-owned filter.
        var changed = workspace.projectBusinessQuery(cards.filterText())
        if (cards.sortColumn().size > 0) {
            changed = workspace.projectBusinessSort(cards.sortColumn(), cards.sortAscending()) || changed
        } else {
            changed = workspace.projectBusinessSort("", true) || changed
        }
        return changed
    }

    /// Projects the owner's ONE authoritative selection onto the view.
    /// `moveFocus` alone only moves focus, so a plain click is used: it REPLACES
    /// the selected set with this key and moves focus, which is exactly the
    /// single-selection the owner models. The caller must invoke this only after
    /// the owner transaction succeeded (or to mirror the owner's live value).
    public func projectOwnerSelection(key: String): Bool {
        let order = collection.order()
        if (order.indexOfKey(key) < 0) {
            return false
        }
        let before = selection.selectionVersion()
        let already = selection.isSelected(key) && selection.selectedCount() == 1 && selection.focus() == key
        if (!already) {
            selection.click(key, false, false, order)
        }
        return before != selection.selectionVersion()
    }

    /// Brings one object's row into the collection's visible range. Selection
    /// and drafts are untouched; only the collection viewport moves.
    public func revealItem(key: String): Bool {
        return revealItemIn(key, "preset-card-table")
    }

    /// Reveals in ONE accepted generated mount. A missing/retired instance
    /// refuses instead of moving the last built (or every) viewport.
    public func revealItemIn(key: String, instanceKey: String): Bool {
        return workspace.revealIn(CjguiComposableUiIdentityScope("print-preset-runtime"),
            instanceKey, key)
    }

    // --- DS51 §13 C: ONE public action/column surface -----------------------

    /// The workspace's ordinary action bar. Labels, node identity, action names
    /// and restore availability all come from the workspace; this consumer only
    /// supplies its own saved snapshot and mounts the row.
    public func buildViewActions(idBase: Int64, rowStyle: CjguiComposableUiStyle,
        buttonStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        return workspace.buildActionBar(idBase, rowStyle, savedViewSnapshot, buttonStyle)
    }

    /// Reusable column controls over the same TableColumnLayout the header and
    /// rows read. The application does not carry a second column branch.
    public func buildColumnControls(idBase: Int64, rowStyle: CjguiComposableUiStyle,
        buttonStyle: CjguiComposableUiStyle): CjguiComposableUiNode {
        return workspace.buildColumnEditor(idBase, rowStyle, buttonStyle)
    }

    public func commandDeclarations(): ArrayList<CjguiComposableUiCommand> {
        return workspace.commandDeclarations(savedViewSnapshot)
    }

    public func commandMetadata(resourceId: Int64): ArrayList<CjguiCommandToolbarMetadata> {
        return workspace.commandMetadata(resourceId, savedViewSnapshot)
    }

    /// The window command route (`event.text` is the scoped command id) lands
    /// on the SAME execution method as the visible button.
    public func handleCommandEvent(event: CjguiComposableUiEvent): ?Bool {
        let action = match (workspace.commandForEvent(event)) {
            case Some(value) => value
            case None => return None
        }
        let outcome = workspace.executeAction(action,
            { encoded => savedViewSnapshot = encoded; true }, { => savedViewSnapshot })
        return Some(outcome.applied)
    }

    /// Route the public workspace's action/column events with THIS application's
    /// persistence callbacks. Returns None for other scopes/components.
    public func handleWorkspaceEvent(event: CjguiComposableUiEvent): ?Bool {
        if (let Some(action) <- workspace.actionForEvent(event)) {
            let outcome = workspace.executeAction(action,
                { encoded => savedViewSnapshot = encoded; true }, { => savedViewSnapshot })
            return Some(outcome.applied)
        }
        return workspace.applyColumnEvent(event)
    }

    // --- DS51 §12 B2/B3: public view snapshot + workspace actions -----------

    public func filterQuery(): String {
        return workspace.viewState().query()
    }

    public func encodedView(): String {
        return workspace.encodedSnapshot()
    }

    public func savedView(): String {
        return savedViewSnapshot
    }

    public func saveView(): Bool {
        let encoded = workspace.encodedSnapshot()
        if (encoded.size == 0) {
            workspace.noteStatus("当前视图无法按公共快照保存")
            return false
        }
        savedViewSnapshot = encoded
        workspace.noteStatus("视图快照已保存（${encoded.size} 字节）")
        return true
    }

    public func restoreView(): Bool {
        if (savedViewSnapshot.size == 0) {
            workspace.noteStatus("尚未保存视图")
            return false
        }
        let outcome = workspace.restoreEncoded(savedViewSnapshot)
        if (!outcome.applied) { return false }
        // A restored VIEW changes the one visible fact: the business-owned
        // filter/sort is a projection of the same table. Publish it here so the
        // next ordinary refresh does not project the changed business value back
        // over the restored one.
        let _ = cards.setFilterText(viewState.query())
        let _ = cards.setSortState(viewState.sortColumnKey(), viewState.sortAscending())
        getStdOut().writeln("PRESET_COLLECTION_VIEW_RESTORED mode=${viewState.mode()} " +
            "query=[${viewState.query()}] sort=${viewState.sortColumnKey()}:${viewState.sortAscending()} " +
            "status=[${workspace.status()}]")
        getStdOut().flush()
        return true
    }

    public func resetView(): Bool {
        return workspace.resetView().applied
    }

    public func viewMode(): String {
        return viewState.mode()
    }

    public func viewStatus(): String {
        return workspace.status()
    }

    /// The accepted mount's staged scroll offset, or -1 when that instance is
    /// not currently published. Evidence-only read: never moves any view.
    public func mountOffset(instanceKey: String): Int64 {
        return match (collection.acceptedView(
            CjguiComposableUiIdentityScope("print-preset-runtime"), instanceKey)) {
            case Some(view) => view.scrollOffset()
            case None => -1
        }
    }

    /// The view's current single selection, for readback/assertions.
    public func selectedKey(): String {
        return if (selection.selectedCount() == 1) { selection.selectedKeysInOrder()[0] } else { "" }
    }

    public func toggleSort(actionName: String): Bool {
        // The shared table owns sort state; toggling the SAME column flips
        // direction and naming another column starts ascending, exactly as its
        // header implies. The public workspace is the ONE entry for that fact.
        let column = if (actionName == "SORT_OWNER") { "owner" } else { "name" }
        return workspace.toggleSort(column)
    }

    /// Sort/filter state for the evidence channel (view state, never identity).
    public func viewSnapshot(): (String, String, String) {
        let focused = selection.focus()
        return (table.sortColumnKey(), table.query(), focused)
    }
}
