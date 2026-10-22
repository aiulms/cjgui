package cjgui_mixed_form_starter

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.unicode.*

/// Application-owned, in-memory print preset. Replace this business class and
/// its declarations for a real app; the GUI/transport do not own another draft.
class PrintPresetDomain <: CjguiSharedEditableFormDomain {
    public static let ownerId: Int64 = 6200
    private let binding = CjguiSharedFormBinding(
        ArrayList<CjguiSharedFormFieldDescriptor>(
            [
                CjguiSharedFormFieldDescriptor(6201, "jobName", "打印任务", "TEXT", required: true, maximumLength: 24),
                CjguiSharedFormFieldDescriptor(6202, "copies", "份数", "INTEGER", required: true, minimum: 1,
                    maximum: 24),
                CjguiSharedFormFieldDescriptor(6203, "duplex", "双面打印", "BOOLEAN")
            ]
        )
    )
    private var applied = ArrayList<CjguiSharedOperationValue>(
        [
            CjguiSharedOperationValue.string("资料"),
            CjguiSharedOperationValue.integer(4),
            CjguiSharedOperationValue.boolean(true)
        ]
    )
    private var draft = ArrayList<String>()
    // A field's text basis is independent of the form transaction version.
    // Editing copies/duplex must not invalidate jobName's installed selection.
    private var fieldVersions = ArrayList<Int64>()
    private var version: Int64 = 0
    private var draftVersion: Int64 = 0
    private var appliedVersion: Int64 = 0
    private var baseVersion: Int64 = 0
    private var status: String = "编辑打印预设，提交后更新已应用值"
    /// Two live cards over the SAME declarations. The shared action protocol
    /// reaches them through their own owner ids; no second domain is created.
    public let cards: PresetCardCollection
    /// The handwritten preset's own lock. While set, its writes are refused by
    /// THIS reason and the provider publishes the same reason, so the handwritten
    /// and generated views agree without a second switch.
    private var locked: Bool = false

    public init() {
        this.cards = PresetCardCollection(binding)
        this.cards.contextVersionReader = Some({ => this.version })
        if (binding.fieldCount() != applied.size) {
            throw IllegalArgumentException("preset defaults do not match fields")
        }
        for (value in applied) {
            draft.add(value.displayText())
            fieldVersions.add(0)
        }
    }

    public func lockReason(): String {
        return if (locked) { "预设已锁定，暂不可编辑" } else { "" }
    }

    public func setLocked(value: Bool): Unit {
        if (locked != value) {
            locked = value
            version += 1
        }
    }

    public func resourceType(): String {
        return "print_preset"
    }
    public func formBinding(): CjguiSharedFormBinding {
        return binding
    }

    private func validation(index: Int64): String {
        let field = binding.fieldAtControlIndex(index)
        let text = draft[index]
        if (field.required && text.trim().isEmpty()) {
            return "${field.label}不能为空"
        }
        if (field.editorKind == "TEXT" && field.maximumLength > 0 && CjguiSharedFieldRule.scalarCount(text) > field
            .maximumLength) {
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
    private func validationReason(): String {
        for (index in 0..binding.fieldCount()) {
            let error = validation(index)
            if (!error.isEmpty()) {
                return error
            }
        }
        return ""
    }
    public func formSnapshot(): CjguiSharedFormSnapshot {
        let fields = ArrayList<CjguiSharedFormFieldProjection>()
        for (index in 0..binding.fieldCount()) {
            let field = binding.fieldAtControlIndex(index)
            fields.add(
                CjguiSharedFormFieldProjection(field.resourceId, field.fieldId, applied[index], draft[index],
                    validation(index), fieldVersions[index], false, 0, 0))
        }
        let error = validationReason()
        return CjguiSharedFormSnapshot(version, appliedVersion, draftVersion, baseVersion, fields,
            error.isEmpty() && baseVersion == appliedVersion, if (error.isEmpty()) {
                status
            } else {
                error
            })
    }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        let fields = ArrayList<CjguiSharedOperationField>()
        for (index in 0..binding.fieldCount()) {
            let spec = binding.fieldAtControlIndex(index)
            fields.add(CjguiSharedOperationField(spec.fieldId, applied[index]))
            fields.add(
                CjguiSharedOperationField("draft_${spec.fieldId}", CjguiSharedOperationValue.string(draft[index])))
        }
        fields.add(CjguiSharedOperationField("draftVersion", CjguiSharedOperationValue.integer(draftVersion)))
        fields.add(CjguiSharedOperationField("appliedVersion", CjguiSharedOperationValue.integer(appliedVersion)))
        return CjguiSharedOperationContextSnapshot(version, "打印预设", resourceType(),
            ArrayList<CjguiSharedOperationResource>([CjguiSharedOperationResource(ownerId, "打印预设", fields)]))
    }
    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        let result = ArrayList<CjguiSharedOperationActionDescriptor>()
        for (action in ["EDIT_DRAFT_TEXT", "EDIT_DRAFT_BOOLEAN"]) {
            let boolean = action == "EDIT_DRAFT_BOOLEAN"
            result.add(
                CjguiSharedOperationActionDescriptor(
                    action,
                    "编辑预设草稿",
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [
                            CjguiSharedOperationParameterDescriptor("fieldId", "STRING", true),
                            CjguiSharedOperationParameterDescriptor(if (boolean) {
                                "value"
                            } else {
                                "text"
                            }, if (boolean) {
                                "BOOLEAN"
                            } else {
                                "STRING"
                            }, true),
                            CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true)
                        ]
                    ),
                    1,
                    1
                )
            )
        }
        result.add(
            CjguiSharedOperationActionDescriptor("SET_LOCK", "锁定或解锁预设",
                ArrayList<CjguiSharedOperationParameterDescriptor>(
                    [CjguiSharedOperationParameterDescriptor("locked", "BOOLEAN", true)]
                ), 1, 1))
        result.add(
            CjguiSharedOperationActionDescriptor("SELECT_CARD", "选择预设卡片",
                ArrayList<CjguiSharedOperationParameterDescriptor>(
                    [CjguiSharedOperationParameterDescriptor("cardKey", "STRING", true)]
                ), 1, 1))
        result.add(
            CjguiSharedOperationActionDescriptor("ADD_CARD", "新增预设卡片",
                ArrayList<CjguiSharedOperationParameterDescriptor>(
                    [CjguiSharedOperationParameterDescriptor("title", "STRING", true)]
                ), 1, 1))
        result.add(
            CjguiSharedOperationActionDescriptor("DELETE_CARD", "删除预设卡片",
                ArrayList<CjguiSharedOperationParameterDescriptor>(
                    [CjguiSharedOperationParameterDescriptor("cardKey", "STRING", true)]
                ), 1, 1))
        result.add(
            CjguiSharedOperationActionDescriptor("SORT_CARDS", "排序预设集合",
                ArrayList<CjguiSharedOperationParameterDescriptor>(
                    [CjguiSharedOperationParameterDescriptor("column", "STRING", true)]
                ), 1, 1))
        result.add(
            CjguiSharedOperationActionDescriptor("FILTER_CARDS", "筛选预设集合",
                ArrayList<CjguiSharedOperationParameterDescriptor>(
                    [CjguiSharedOperationParameterDescriptor("query", "STRING", true)]
                ), 1, 1))
        result.add(
            CjguiSharedOperationActionDescriptor("REBIND_CARD", "换绑预设卡片",
                ArrayList<CjguiSharedOperationParameterDescriptor>(
                    [
                        CjguiSharedOperationParameterDescriptor("cardKey", "STRING", true),
                        CjguiSharedOperationParameterDescriptor("newOwner", "INTEGER", true)
                    ]
                ), 1, 1))
        for (action in ["APPLY_DRAFT", "CANCEL_DRAFT"]) {
            result.add(
                CjguiSharedOperationActionDescriptor(action, if (action == "APPLY_DRAFT") {
                    "提交打印预设"
                } else {
                    "还原草稿"
                },
                    ArrayList<CjguiSharedOperationParameterDescriptor>(
                        [CjguiSharedOperationParameterDescriptor("expectedDraftVersion", "INTEGER", true)]), 1, 1))
        }
        return result
    }
    private func argument(call: CjguiSharedOperationActionInvocation, name: String): ?CjguiSharedOperationValue {
        for (arg in call.arguments) {
            if (arg.name == name) {
                return Some(arg.value)
            }
        }
        return None
    }
    private func result(applied: Bool, reason: String, before: Int64, conflict!: Bool = false): CjguiSharedOperationActionResult {
        return CjguiSharedOperationActionResult(applied, conflict, before, version, reason)
    }
    private func stringArgument(call: CjguiSharedOperationActionInvocation, name: String): ?String {
        let value = argument(call, name)
        if (value.isNone() || value.getOrThrow().valueType != "STRING") {
            return None
        }
        return Some(value.getOrThrow().stringValue)
    }

    /// The object COLLECTION's own transactions. They change which ordinary
    /// objects exist / which is selected / which are visible, never a draft of a
    /// different object, and they are the same public vocabulary an external
    /// client uses (no UI-only side channel).
    private func executeCollection(call: CjguiSharedOperationActionInvocation,
        before: Int64): CjguiSharedOperationActionResult {
        if (call.actionName == "SELECT_CARD") {
            let key = stringArgument(call, "cardKey")
            if (key.isNone()) {
                return result(false, "unknown_argument", before)
            }
            let wanted = key.getOrThrow()
            // A key that names no live object must be REFUSED by name: the old
            // selection, version and drafts stay untouched. (selectKey's false
            // also means "already selected", so existence is checked first.)
            if (!cards.containsKey(wanted)) {
                return result(false, "unknown_target", before)
            }
            let changed = cards.selectKey(wanted)
            if (changed) { version += 1 }
            return result(true, "none", before)
        }
        if (call.actionName == "ADD_CARD") {
            let title = stringArgument(call, "title")
            if (title.isNone() || title.getOrThrow().isEmpty()) {
                return result(false, "unknown_argument", before)
            }
            let key = cards.addCard(title.getOrThrow(), ArrayList<CjguiSharedOperationValue>([
                CjguiSharedOperationValue.string("新对象"),
                CjguiSharedOperationValue.integer(1),
                CjguiSharedOperationValue.boolean(false)
            ]))
            if (key.isNone()) {
                return result(false, "collection_full", before)
            }
            version += 1
            return result(true, "none", before)
        }
        if (call.actionName == "DELETE_CARD") {
            let key = stringArgument(call, "cardKey")
            if (key.isNone()) {
                return result(false, "unknown_argument", before)
            }
            let removed = cards.deleteCard(key.getOrThrow())
            if (!removed) {
                return result(false, "unknown_target", before)
            }
            version += 1
            return result(true, "none", before)
        }
        if (call.actionName == "SORT_CARDS") {
            let column = stringArgument(call, "column")
            if (column.isNone()) {
                return result(false, "unknown_argument", before)
            }
            let changed = cards.toggleSort(column.getOrThrow())
            if (!changed) {
                return result(false, "unknown_argument", before)
            }
            version += 1
            return result(true, "none", before)
        }
        let query = stringArgument(call, "query")
        if (query.isNone()) {
            return result(false, "unknown_argument", before)
        }
        let changed = cards.setFilterText(query.getOrThrow())
        if (changed) { version += 1 }
        return result(true, "none", before)
    }

    private func execute(call: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let before = version
        if (call.expectedVersion != version) {
            return result(false, "stale_version", before, conflict: true)
        }
        if (call.targetResourceIds.size == 1 && call.targetResourceIds[0] == ownerId &&
            (call.actionName == "SELECT_CARD" || call.actionName == "ADD_CARD" ||
             call.actionName == "DELETE_CARD" || call.actionName == "FILTER_CARDS" ||
             call.actionName == "SORT_CARDS")) {
            return executeCollection(call, before)
        }
        if (call.targetResourceIds.size == 1 && cards.ownerFor(cards.keyForOwner(call.targetResourceIds[0])) ==
            call.targetResourceIds[0]) {
            return executeCard(call, before)
        }
        if (call.targetResourceIds.size != 1 || call.targetResourceIds[0] != ownerId) {
            return result(false, "unknown_target", before)
        }
        if (call.actionName == "SET_LOCK") {
            let value = argument(call, "locked")
            if (value.isNone() || value.getOrThrow().valueType != "BOOLEAN") {
                return result(false, "unknown_argument", before)
            }
            setLocked(value.getOrThrow().booleanValue)
            return result(true, "none", before)
        }
        let expected = argument(call, "expectedDraftVersion")
        if (expected.isNone() || expected.getOrThrow().valueType != "INTEGER" || expected.getOrThrow().integerValue !=
            draftVersion) {
            return result(false, "stale_draft", before, conflict: true)
        }
        if (call.actionName == "REBIND_CARD") {
            let key = argument(call, "cardKey")
            let newOwner = argument(call, "newOwner")
            if (key.isNone() || key.getOrThrow().valueType != "STRING" || newOwner.isNone() ||
                newOwner.getOrThrow().valueType != "INTEGER") {
                return result(false, "unknown_argument", before)
            }
            let updated = cards.rebind(key.getOrThrow().stringValue, newOwner.getOrThrow().integerValue,
                "卡片 ${key.getOrThrow().stringValue}", ArrayList<CjguiSharedOperationValue>([
                    CjguiSharedOperationValue.string("新对象"),
                    CjguiSharedOperationValue.integer(3),
                    CjguiSharedOperationValue.boolean(false)
                ]))
            if (updated) { version += 1 }
            return result(updated, if (updated) { "none" } else { "unknown_target" }, before)
        }
        if (locked && (call.actionName == "EDIT_DRAFT_TEXT" || call.actionName == "EDIT_DRAFT_BOOLEAN" ||
            call.actionName == "APPLY_DRAFT" || call.actionName == "CANCEL_DRAFT")) {
            return result(false, lockReason(), before)
        }
        if (call.actionName == "EDIT_DRAFT_TEXT" || call.actionName == "EDIT_DRAFT_BOOLEAN") {
            let field = argument(call, "fieldId")
            if (field.isNone() || field.getOrThrow().valueType != "STRING") {
                return result(false, "unknown_field", before)
            }
            var index: Int64 = -1
            for (i in 0..binding.fieldCount()) {
                if (binding.fieldAtControlIndex(i).fieldId == field.getOrThrow().stringValue) {
                    index = i
                }
            }
            if (index < 0) {
                return result(false, "unknown_field", before)
            }
            let boolean = binding.fieldAtControlIndex(index).editorKind == "BOOLEAN"
            let value = argument(call, if (boolean) {
                "value"
            } else {
                "text"
            })
            if (value.isNone() || value.getOrThrow().valueType != (if (boolean) {
                "BOOLEAN"
            } else {
                "STRING"
            }) || call.actionName != (if (boolean) {
                "EDIT_DRAFT_BOOLEAN"
            } else {
                "EDIT_DRAFT_TEXT"
            })) {
                return result(false, "wrong_editor_type", before)
            }
            // Invalid intermediate drafts remain editable; only Apply commits.
            draft[index] = value.getOrThrow().displayText()
            fieldVersions[index] += 1
        } else if (call.actionName == "APPLY_DRAFT") {
            let error = validationReason()
            if (!error.isEmpty()) {
                return result(false, error, before)
            }
            if (baseVersion != appliedVersion) {
                return result(false, "stale_base", before, conflict: true)
            }
            for (i in 0..binding.fieldCount()) {
                let kind = binding.fieldAtControlIndex(i).editorKind
                applied[i] = if (kind == "BOOLEAN") {
                    CjguiSharedOperationValue.boolean(draft[i] == "true")
                } else if (kind == "INTEGER") {
                    CjguiSharedOperationValue.integer(Int64.parse(draft[i]))
                } else {
                    CjguiSharedOperationValue.string(draft[i])
                }
            }
            appliedVersion += 1
            baseVersion = appliedVersion
            status = "打印预设已提交"
        } else if (call.actionName == "CANCEL_DRAFT") {
            for (i in 0..binding.fieldCount()) {
                let restored = applied[i].displayText()
                if (draft[i] != restored) {
                    draft[i] = restored
                    fieldVersions[i] += 1
                }
            }
            baseVersion = appliedVersion
            status = "草稿已还原"
        } else {
            return result(false, "unknown_action", before)
        }
        draftVersion += 1
        version += 1
        return result(true, "none", before)
    }
    public func executeFromHuman(call: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return execute(call)
    }
    public func executeFromExternal(call: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return execute(call)
    }
    /// One accepted card's action transaction. It is the SAME declared
    /// vocabulary (EDIT_DRAFT_*/APPLY_DRAFT/CANCEL_DRAFT) with the card's own
    /// expectedDraftVersion and owner target; it never writes another object.
    private func executeCard(call: CjguiSharedOperationActionInvocation,
        before: Int64): CjguiSharedOperationActionResult {
        let key = cards.keyForOwner(call.targetResourceIds[0])
        let card = match (cards.card(key)) {
            case Some(value) => value
            case None => return result(false, "unknown_target", before)
        }
        if (call.actionName == "SET_LOCK") {
            let value = argument(call, "locked")
            if (value.isNone() || value.getOrThrow().valueType != "BOOLEAN") {
                return result(false, "unknown_argument", before)
            }
            card.setLocked(value.getOrThrow().booleanValue)
            version += 1
            return result(true, "none", before)
        }
        if (call.actionName == "REBIND_CARD") {
            let key = argument(call, "cardKey")
            let newOwner = argument(call, "newOwner")
            if (key.isNone() || key.getOrThrow().valueType != "STRING" || newOwner.isNone() ||
                newOwner.getOrThrow().valueType != "INTEGER") {
                return result(false, "unknown_argument", before)
            }
            let updated = cards.rebind(key.getOrThrow().stringValue, newOwner.getOrThrow().integerValue,
                "卡片 ${key.getOrThrow().stringValue}", ArrayList<CjguiSharedOperationValue>([
                    CjguiSharedOperationValue.string("新对象"),
                    CjguiSharedOperationValue.integer(3),
                    CjguiSharedOperationValue.boolean(false)
                ]))
            if (updated) { version += 1 }
            return result(updated, if (updated) { "none" } else { "unknown_target" }, before)
        }
        let expected = argument(call, "expectedDraftVersion")
        if (expected.isNone() || expected.getOrThrow().valueType != "INTEGER" ||
            expected.getOrThrow().integerValue != card.draftVersionValue()) {
            return result(false, "stale_draft", before, conflict: true)
        }
        if (card.lockedReason().size > 0 && (call.actionName == "EDIT_DRAFT_TEXT" ||
            call.actionName == "EDIT_DRAFT_BOOLEAN" || call.actionName == "APPLY_DRAFT" ||
            call.actionName == "CANCEL_DRAFT")) {
            return result(false, card.lockedReason(), before)
        }
        if (locked && (call.actionName == "EDIT_DRAFT_TEXT" || call.actionName == "EDIT_DRAFT_BOOLEAN" ||
            call.actionName == "APPLY_DRAFT" || call.actionName == "CANCEL_DRAFT")) {
            return result(false, lockReason(), before)
        }
        if (call.actionName == "EDIT_DRAFT_TEXT" || call.actionName == "EDIT_DRAFT_BOOLEAN") {
            let field = argument(call, "fieldId")
            if (field.isNone() || field.getOrThrow().valueType != "STRING") {
                return result(false, "unknown_field", before)
            }
            let fieldId = field.getOrThrow().stringValue
            var index: Int64 = -1
            for (i in 0..binding.fieldCount()) {
                if (binding.fieldAtControlIndex(i).fieldId == fieldId) {
                    index = i
                }
            }
            if (index < 0) {
                return result(false, "unknown_field", before)
            }
            let boolean = binding.fieldAtControlIndex(index).editorKind == "BOOLEAN"
            let value = argument(call, if (boolean) { "value" } else { "text" })
            if (value.isNone() || value.getOrThrow().valueType != (if (boolean) { "BOOLEAN" } else { "STRING" }) ||
                call.actionName != (if (boolean) { "EDIT_DRAFT_BOOLEAN" } else { "EDIT_DRAFT_TEXT" })) {
                return result(false, "wrong_editor_type", before)
            }
            let applied = if (boolean) {
                card.setBoolean(fieldId, value.getOrThrow().booleanValue)
            } else {
                card.setText(fieldId, value.getOrThrow().stringValue)
            }
            if (applied) { version += 1 }
            return result(applied, if (applied) { "none" } else { "unknown_field" }, before)
        }
        if (call.actionName == "APPLY_DRAFT") {
            let outcome = card.apply()
            if (outcome[0]) { version += 1 }
            return result(outcome[0], outcome[1], before)
        }
        if (call.actionName == "CANCEL_DRAFT") {
            let outcome = card.cancel()
            if (outcome[0]) { version += 1 }
            return result(outcome[0], outcome[1], before)
        }
        return result(false, "unknown_action", before)
    }

    private func invoke(action: String, arguments: ArrayList<CjguiSharedOperationActionArgument>): CjguiSharedOperationActionResult {
        arguments.add(
            CjguiSharedOperationActionArgument("expectedDraftVersion", CjguiSharedOperationValue.integer(draftVersion)))
        return executeFromHuman(
            CjguiSharedOperationActionInvocation(action, version, ArrayList<Int64>([ownerId]), arguments))
    }
    public func editTextFromHuman(resourceId: Int64, text: String, selectionStart: Int64, selectionEnd: Int64): CjguiSharedOperationActionResult {
        let _ = selectionStart;
        let _ = selectionEnd
        let index = binding.controlIndexForResourceId(resourceId)
        if (index < 0) {
            return result(false, "unknown_field", version)
        }
        return invoke("EDIT_DRAFT_TEXT",
            ArrayList<CjguiSharedOperationActionArgument>(
                [CjguiSharedOperationActionArgument("fieldId",
                    CjguiSharedOperationValue.string(binding.fieldAtControlIndex(index).fieldId)),
                    CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text))]))
    }
    public func editBooleanFromHuman(resourceId: Int64, value: Bool): CjguiSharedOperationActionResult {
        let index = binding.controlIndexForResourceId(resourceId)
        if (index < 0) {
            return result(false, "unknown_field", version)
        }
        return invoke("EDIT_DRAFT_BOOLEAN",
            ArrayList<CjguiSharedOperationActionArgument>(
                [CjguiSharedOperationActionArgument("fieldId",
                    CjguiSharedOperationValue.string(binding.fieldAtControlIndex(index).fieldId)),
                    CjguiSharedOperationActionArgument("value", CjguiSharedOperationValue.boolean(value))]))
    }
    private func finish(action: String, expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        if (expectedDraftVersion != draftVersion || expectedBaseAppliedConfigVersion != baseVersion) {
            return result(false, "stale_draft", version, conflict: true)
        }
        return invoke(action, ArrayList<CjguiSharedOperationActionArgument>())
    }
    public func applyDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        return finish("APPLY_DRAFT", expectedDraftVersion, expectedBaseAppliedConfigVersion)
    }
    public func cancelDraftFromHuman(expectedDraftVersion: Int64, expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        return finish("CANCEL_DRAFT", expectedDraftVersion, expectedBaseAppliedConfigVersion)
    }
}
