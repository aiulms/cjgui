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
        appliedVersion += 1
        draftVersion += 1
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
            revision += 1
        }
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

/// The region binding: every single-owner call keeps the handwritten preset's
/// exact behaviour, and every instance-aware call reads/writes the card deck.
/// A card action carries the ORIGINAL accepted owner target; a key that moved
/// is refused by name instead of writing whatever object it maps to now.
class MixedPresetProvider <: CjguiGeneratedUiRegionBinding {
    private let form: CjguiGeneratedUiFormBinding
    private let cards: PresetCardCollection
    private let domain: PrintPresetDomain

    init(form: CjguiGeneratedUiFormBinding, cards: PresetCardCollection, domain: PrintPresetDomain) {
        this.form = form
        this.cards = cards
        this.domain = domain
    }

    /// Whether an instance key NAMES a card object. It deliberately stays true
    /// for a key whose object was DELETED, so the card branches below can refuse
    /// by name instead of silently falling back to the handwritten preset (a
    /// deleted card is not the handwritten owner).
    private func isCard(instanceKey: String): Bool {
        return instanceKey.size > 0 && instanceKey.startsWith("card")
    }

    public func ownerRevision(): Int64 {
        // The ONE owner context version the transport checks for CAS. Card
        // writes advance the same domain version, so no second counter is
        // mixed in (a synthetic number would make every client CAS stale).
        return form.ownerRevision()
    }

    public func formFeedback(): ?CjguiGeneratedUiFormFeedback {
        let inner = form.formFeedback()
        let reason = domain.lockReason()
        if (reason.size == 0) {
            return inner
        }
        // A locked handwritten preset publishes the SAME owner reason the write
        // path refuses; the projection is rebuilt from the one snapshot, never
        // from a second UI switch.
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
        if (isCard(instanceKey)) {
            return cards.feedback(instanceKey)
        }
        return form.formFeedback()
    }

    public func fieldResourceId(fieldId: String): Int64 {
        return form.fieldResourceId(fieldId)
    }

    public func fieldOperationResourceId(fieldId: String): Int64 {
        return form.fieldOperationResourceId(fieldId)
    }

    public func fieldOperationResourceId(fieldId: String, instanceKey: String): Int64 {
        if (isCard(instanceKey)) {
            // A deleted/never-bound key resolves to NO owner; the accepted
            // element's operationResourceId stays the frozen target and the
            // range/generation guards can then name the retirement.
            return cards.ownerFor(instanceKey)
        }
        return form.fieldOperationResourceId(fieldId)
    }

    public func draftText(fieldId: String): String {
        return form.draftText(fieldId)
    }

    public func draftText(fieldId: String, instanceKey: String): String {
        if (!isCard(instanceKey)) {
            return form.draftText(fieldId)
        }
        let card = match (cards.card(instanceKey)) {
            case Some(value) => value
            case None => return ""
        }
        return card.draftText(fieldId)
    }

    public func appliedText(fieldId: String): String {
        return form.appliedText(fieldId)
    }

    public func draftBoolean(fieldId: String): ?Bool {
        return form.draftBoolean(fieldId)
    }

    public func draftBoolean(fieldId: String, instanceKey: String): ?Bool {
        if (!isCard(instanceKey)) {
            return form.draftBoolean(fieldId)
        }
        return match (cards.card(instanceKey)) {
            case Some(card) => card.draftBoolean(fieldId)
            case None => None
        }
    }

    public func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        let reason = domain.lockReason()
        if (reason.size > 0) {
            return CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId, ownerRevision())
        }
        return form.fieldAvailability(fieldId)
    }

    public func fieldAvailability(fieldId: String, instanceKey: String): CjguiSharedAvailability {
        if (!isCard(instanceKey)) {
            return form.fieldAvailability(fieldId)
        }
        return match (cards.card(instanceKey)) {
            case Some(card) => card.fieldAvailability(fieldId)
            case None => CjguiSharedAvailability.blocked("对象已删除", -1, ownerRevision())
        }
    }

    public func actionAvailability(actionName: String): CjguiSharedAvailability {
        let reason = domain.lockReason()
        if (reason.size > 0) {
            return CjguiSharedAvailability.blocked(reason, PrintPresetDomain.ownerId, ownerRevision())
        }
        return form.actionAvailability(actionName)
    }

    public func actionAvailability(actionName: String, instanceKey: String): CjguiSharedAvailability {
        if (!isCard(instanceKey)) {
            return form.actionAvailability(actionName)
        }
        return match (cards.card(instanceKey)) {
            case Some(card) => card.actionAvailability(actionName)
            case None => CjguiSharedAvailability.blocked("对象已删除", -1, ownerRevision())
        }
    }

    public func actionAvailable(actionName: String): Bool {
        return form.actionAvailable(actionName)
    }

    public func actionOperationResourceId(actionName: String, instanceKey: String): Int64 {
        let _ = actionName
        if (isCard(instanceKey)) {
            return cards.ownerFor(instanceKey)
        }
        return -1
    }

    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return form.executeAction(actionName, nodeKey)
    }

    /// The collection's row activation. The collection composite is NOT a card
    /// instance; its row action names the card OWNER it was built for, and this
    /// provider is the one place that translates that public owner id into the
    /// domain's SELECT_CARD transaction (the domain still owns the selection).
    private func selectCollectionRow(nodeKey: String,
        ownerTargetResourceId: Int64): CjguiGeneratedUiActionResult {
        let _ = nodeKey
        let key = cards.keyForOwner(ownerTargetResourceId)
        if (key.size == 0) {
            return CjguiGeneratedUiActionResult(false, "unknown_target")
        }
        // The domain's published context version is the CAS the same public
        // transaction checks; the provider reads it from the owner snapshot.
        let call = CjguiSharedOperationActionInvocation("SELECT_CARD",
            domain.formSnapshot().contextVersion,
            ArrayList<Int64>([PrintPresetDomain.ownerId]),
            ArrayList<CjguiSharedOperationActionArgument>([
                CjguiSharedOperationActionArgument("cardKey", CjguiSharedOperationValue.string(key))
            ]))
        let outcome = domain.executeFromHuman(call)
        return CjguiGeneratedUiActionResult(outcome.applied, outcome.reason)
    }

    /// The card transaction: the accepted owner target must still be this key's
    /// object, and only then does the action run on THAT card.
    public func executeAction(actionName: String, nodeKey: String, instanceKey: String,
        ownerTargetResourceId: Int64, instanceIncarnation: Int64): CjguiGeneratedUiActionResult {
        let _ = instanceIncarnation
        if (!isCard(instanceKey)) {
            if (actionName == "SELECT_CARD") {
                return selectCollectionRow(nodeKey, ownerTargetResourceId)
            }
            return form.executeAction(actionName, nodeKey)
        }
        if (cards.ownerFor(instanceKey) != ownerTargetResourceId) {
            return CjguiGeneratedUiActionResult(false, "owner_target_retired")
        }
        let card = cards.card(instanceKey).getOrThrow()
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

    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        if (!isCard(intent.instanceKey)) {
            return form.applyFieldIntent(intent)
        }
        let card = match (cards.card(intent.instanceKey)) {
            case Some(value) => value
            case None => return CjguiComposableUiDispatchResult(false)
        }
        if (!intent.isFieldEdit() || intent.ownerTargetResourceId != card.ownerId ||
            intent.fieldId.size == 0) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (isCard(intent.instanceKey) &&
            cards.card(intent.instanceKey).getOrThrow().rangeTextEditSupported(intent.fieldId)) {
            // A TEXT card field that supports the owned range session must NOT
            // arrive here as a whole-value write; if it does, that is a route
            // regression and this line makes it visible.
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

    /// A card's TEXT field opts into the SAME owned range session the handwritten
    /// form uses: the framework binds CjguiGeneratedFieldRangeSession with this
    /// accepted instance key, owner target and generation, and this provider only
    /// forwards the owner's own transaction probes. No second input state machine
    /// lives here or in the card.
    public func rangeTextEditSupported(fieldId: String, instanceKey: String): Bool {
        if (isCard(instanceKey)) {
            return match (cards.card(instanceKey)) {
                case Some(card) => card.rangeTextEditSupported(fieldId)
                case None => false
            }
        }
        return form.rangeTextEditSupported(fieldId)
    }

    public func fieldTextVersion(fieldId: String, instanceKey: String): Int64 {
        if (isCard(instanceKey)) {
            return match (cards.card(instanceKey)) {
                case Some(card) => card.textVersion(fieldId)
                case None => -1
            }
        }
        return form.fieldTextVersion(fieldId)
    }

    public func confirmFieldTextVersion(fieldId: String, expectedVersion: Int64, action: () -> Bool,
        instanceKey: String): Bool {
        if (isCard(instanceKey)) {
            return match (cards.card(instanceKey)) {
                case Some(card) => card.confirmTextVersion(fieldId, expectedVersion, action)
                case None => false
            }
        }
        return form.confirmFieldTextVersion(fieldId, expectedVersion, action)
    }

    public func applyTextEdit(fieldId: String, expectedVersion: Int64, newText: String,
        instanceKey: String): CjguiRangeTextEditOutcome {
        if (isCard(instanceKey)) {
            let outcome = match (cards.card(instanceKey)) {
                case Some(card) => card.applyTextEdit(fieldId, expectedVersion, newText)
                case None => CjguiRangeTextEditOutcome.rejected(expectedVersion, "unknown_instance")
            }
            // Evidence channel: the OWNER transaction this range edit reached.
            // A whole-value intent would print nothing here (and is counted
            // separately), so a reader can tell the two paths apart.
            getStdOut().writeln("PRESET_CARD_RANGE_EDIT key=${instanceKey} field=${fieldId} expected=${expectedVersion} " +
                "applied=${outcome.applied} conflict=${outcome.isVersionConflict} before=${outcome.versionBefore} " +
                "after=${outcome.versionAfter} reason=${outcome.reason}")
            getStdOut().flush()
            return outcome
        }
        return form.applyTextEdit(fieldId, expectedVersion, newText)
    }

    public func rebaseFieldTextSelection(fieldId: String, fromVersion: Int64, startByte: Int64,
        endByte: Int64, instanceKey: String): ?(Int64, Int64, Int64) {
        if (isCard(instanceKey)) {
            return match (cards.card(instanceKey)) {
                case Some(card) => card.rebaseTextSelection(fieldId, fromVersion, startByte, endByte)
                case None => None
            }
        }
        return form.rebaseFieldTextSelection(fieldId, fromVersion, startByte, endByte)
    }

    // The five LEGACY single-owner range entries: the handwritten preset (owner
    // 6200, empty instance key) keeps the same capability/version/CAS/confirm/
    // rebase contract as the card instances, so an empty-instance probe is NOT
    // answered by the interface's unsupported defaults. A card key never falls
    // through to these: the instance-aware overloads above decide per card and
    // refuse unknown/retired objects by name.
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
        // Evidence channel for the LEGACY single-owner path: the handwritten
        // preset area's range session is bound only when the empty-instance
        // probe above answers true; this line proves the edit reached the owner
        // transaction (a visual-only preview prints nothing).
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
    init(cards: PresetCardCollection) {
        this.cards = cards
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
        let background = if (selected || focused) {
            CjguiComposableUiColor(0.28, 0.40, 0.62, 1.0)
        } else {
            CjguiComposableUiColor(0.14, 0.17, 0.24, 1.0)
        }
        let scope = CjguiComposableUiIdentityScope("preset-card-list")
        return cjguiComposableButton(-1, "preset-card-row-${item.key}", item.title, "SELECT_CARD",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 30, growX: 1, padding: 6,
                background: background, textColor: CjguiComposableUiColor(0.95, 0.96, 1.0, 1.0),
                textMaxLines: 1, textOverflow: "ellipsis"),
            operationActionName: "SELECT_CARD", operationResourceId: item.resourceId,
            identity: Some(scope.child(item.key).local("row")))
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

    init(cards: PresetCardCollection) {
        this.cards = cards
        // Locals first: a closure may not read members before every member is
        // initialized, and the table needs one selection object for its paint.
        let selected = CjguiComposableUiCollectionSelection()
        let rows = PresetCardRows(cards)
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

    /// Applies the owner's current filter and sort to the view. This is the ONLY
    /// place either moves; the collection composite reads the same table.
    public func syncFilter(): Bool {
        // The QUERY goes through the table (not straight to the filtered source):
        // the table caches its own sorted order and only a table-level query
        // change invalidates it, so a hidden object cannot survive in a cached
        // order.
        var changed = table.setQuery(cards.filterText())
        if (cards.sortColumn().size > 0 && table.sortColumnKey() != cards.sortColumn()) {
            changed = table.setSortState(cards.sortColumn(), cards.sortAscending()) || changed
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
        return collection.revealItem(key)
    }

    /// The view's current single selection, for readback/assertions.
    public func selectedKey(): String {
        return if (selection.selectedCount() == 1) { selection.selectedKeysInOrder()[0] } else { "" }
    }

    public func toggleSort(actionName: String): Bool {
        // The table owns sort state; toggling the SAME column flips direction and
        // naming another column starts ascending, exactly as its header implies.
        let column = if (actionName == "SORT_OWNER") { "owner" } else { "name" }
        return table.setSort(column)
    }

    /// Sort/filter state for the evidence channel (view state, never identity).
    public func viewSnapshot(): (String, String, String) {
        let focused = selection.focus()
        return (table.sortColumnKey(), table.query(), focused)
    }
}
