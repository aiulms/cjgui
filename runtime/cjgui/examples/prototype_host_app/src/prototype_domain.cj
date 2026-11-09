package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.unicode.*

/// 原型 owner 的共享版本钟。同一项目的所有对象用同一个 context version 做 CAS，
/// 一个对象自己的 draft/applied 版本不冒充别的字段或别的对象的版本。
class PrototypeRevisionClock {
    private var value: Int64 = 1

    func version(): Int64 {
        return value
    }

    func advance(): Unit {
        value += 1
    }
}

/// 一个原型对象（设置表单本体 / 一条记录 / 一张卡片的可编辑侧）。
///
/// 字段声明只有一份（项目声明），草稿与已应用值、字段版本和校验都在这里；
/// 手写投影、生成式表单绑定、外部读回都读同一个对象，没有第二份草稿。
class PrototypeObject <: CjguiSharedEditableFormDomain {
    let ownerId: Int64
    let key: String
    private var project: PrototypeProject
    private var declarations: CjguiSharedFormBinding
    private let clock: PrototypeRevisionClock
    private var applied: ArrayList<CjguiSharedOperationValue>
    private var draft: ArrayList<String>
    private var fieldVersions: ArrayList<Int64>
    private var draftVersion: Int64 = 0
    private var appliedVersion: Int64 = 0
    private var revisionValue: Int64 = 0
    private var notice: String = ""

    init(project: PrototypeProject, key: String, ownerId: Int64, clock: PrototypeRevisionClock,
        initialValues: ArrayList<String>) {
        this.project = project
        this.key = key
        this.ownerId = ownerId
        this.clock = clock
        this.declarations = prototypeFormBinding(project)
        this.applied = ArrayList<CjguiSharedOperationValue>()
        this.draft = ArrayList<String>()
        this.fieldVersions = ArrayList<Int64>()
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            let descriptor = declarations.fieldAtControlIndex(index)
            let text = if (index < initialValues.size) { initialValues[index] } else { "" }
            let value = prototypeValueFor(descriptor, text)
            applied.add(value)
            draft.add(value.displayText())
            fieldVersions.add(0)
            index += 1
        }
    }

    func bindingDeclarations(): CjguiSharedFormBinding {
        return declarations
    }

    func projectDeclaration(): PrototypeProject {
        return project
    }

    func claimRevision(): Int64 {
        revisionValue += 1
        clock.advance()
        return revisionValue
    }

    func isDirty(): Bool {
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            if (draft[index] != applied[index].displayText()) {
                return true
            }
            index += 1
        }
        return false
    }

    func clearNotice(): Unit {
        notice = ""
    }

    func statusText(): String {
        if (notice.size > 0) {
            return notice
        }
        return if (isDirty()) { "有未应用的草稿" } else { "草稿已应用" }
    }

    func validationOf(fieldId: String): String {
        let index = indexOfField(fieldId)
        if (index < 0) {
            return "未知字段 ${fieldId}"
        }
        let field = project.fields[index]
        let text = draft[index]
        if (field.required && text.trim().size == 0) {
            return if (field.errorText.size > 0) { field.errorText } else { "${field.label}不能为空" }
        }
        if (field.isInteger() && text.trim().size > 0) {
            var value: ?Int64 = None
            try {
                value = Some(Int64.parse(text.trim()))
            } catch (_: Exception) {
                value = None
            }
            match (value) {
                case Some(number) =>
                    if (number < field.minimum || (field.maximum > 0 && number > field.maximum)) {
                        return if (field.errorText.size > 0) {
                            field.errorText
                        } else {
                            "${field.label}需在 ${field.minimum}–${field.maximum} 之间"
                        }
                    }
                case None => return if (field.errorText.size > 0) {
                        field.errorText
                    } else {
                        "${field.label}需为整数"
                    }
            }
        }
        if (field.editorKind() == "TEXT" && field.maximumLength > 0 && prototypeScalarCount(text) > field.maximumLength) {
            return if (field.errorText.size > 0) {
                field.errorText
            } else {
                "${field.label}最多 ${field.maximumLength} 个字符"
            }
        }
        return ""
    }

    func firstError(): String {
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            let error = validationOf(declarations.fieldAtControlIndex(index).fieldId)
            if (error.size > 0) {
                return error
            }
            index += 1
        }
        return ""
    }

    func draftText(fieldId: String): String {
        let index = indexOfField(fieldId)
        return if (index < 0) { "" } else { draft[index] }
    }

    func appliedText(fieldId: String): String {
        let index = indexOfField(fieldId)
        return if (index < 0) { "" } else { applied[index].displayText() }
    }

    func draftBooleanValue(fieldId: String): ?Bool {
        let index = indexOfField(fieldId)
        if (index < 0 || !project.fields[index].isBoolean()) {
            return None
        }
        return Some(draft[index] == "true")
    }

    func appliedBooleanValue(fieldId: String): ?Bool {
        let index = indexOfField(fieldId)
        if (index < 0 || !project.fields[index].isBoolean()) {
            return None
        }
        return Some(applied[index].booleanValue)
    }

    func fieldVersion(fieldId: String): Int64 {
        let index = indexOfField(fieldId)
        return if (index < 0) { 0 } else { fieldVersions[index] }
    }

    /// 一个字段的当前写入可用性。真正不可写的条件（未知字段）由 owner 给出同一原因。
    func availabilityOf(fieldId: String): CjguiSharedAvailability {
        if (indexOfField(fieldId) < 0) {
            return CjguiSharedAvailability.blocked("未知字段 ${fieldId}", ownerId, clock.version())
        }
        return CjguiSharedAvailability.allowed(ownerId, clock.version())
    }

    func actionAvailabilityOf(actionName: String): CjguiSharedAvailability {
        if (actionName == "APPLY_DRAFT") {
            let error = firstError()
            if (error.size > 0) {
                return CjguiSharedAvailability.blocked(error, ownerId, clock.version())
            }
            return CjguiSharedAvailability.allowed(ownerId, clock.version())
        }
        if (actionName == "CANCEL_DRAFT" || actionName == "RESTORE_DEFAULTS") {
            return CjguiSharedAvailability.allowed(ownerId, clock.version())
        }
        return CjguiSharedAvailability.unknown()
    }

    func setText(fieldId: String, text: String): Bool {
        let index = indexOfField(fieldId)
        if (index < 0 || project.fields[index].isBoolean()) {
            return false
        }
        if (draft[index] == text) {
            return true
        }
        draft[index] = text
        fieldVersions[index] += 1
        draftVersion += 1
        notice = ""
        claimRevision()
        return true
    }

    func setSelectValue(fieldId: String, value: String): Bool {
        let index = indexOfField(fieldId)
        if (index < 0 || !project.fields[index].isSelect()) {
            return false
        }
        return setText(fieldId, value)
    }

    func setBoolean(fieldId: String, value: Bool): Bool {
        let index = indexOfField(fieldId)
        if (index < 0 || !project.fields[index].isBoolean()) {
            return false
        }
        let text = if (value) { "true" } else { "false" }
        if (draft[index] == text) {
            return true
        }
        draft[index] = text
        fieldVersions[index] += 1
        draftVersion += 1
        notice = ""
        claimRevision()
        return true
    }

    func applyDraft(): (Bool, String) {
        let error = firstError()
        if (error.size > 0) {
            notice = error
            claimRevision()
            return (false, error)
        }
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            let descriptor = declarations.fieldAtControlIndex(index)
            applied[index] = prototypeValueFor(descriptor, draft[index])
            index += 1
        }
        appliedVersion = draftVersion
        notice = "已应用草稿"
        claimRevision()
        return (true, "none")
    }

    func cancelDraft(): (Bool, String) {
        var index: Int64 = 0
        var changed = false
        while (index < declarations.fieldCount()) {
            let restored = applied[index].displayText()
            if (draft[index] != restored) {
                draft[index] = restored
                fieldVersions[index] += 1
                changed = true
            }
            index += 1
        }
        if (changed) {
            draftVersion += 1
        }
        appliedVersion = draftVersion
        notice = "已取消草稿"
        claimRevision()
        return (true, "none")
    }

    /// 恢复声明里的默认值（`RESTORE_DEFAULTS`）。默认值来自项目声明，不是宿主常量。
    func restoreDefaults(): (Bool, String) {
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            let field = project.fields[index]
            if (draft[index] != field.defaultValue) {
                draft[index] = field.defaultValue
                fieldVersions[index] += 1
            }
            applied[index] = prototypeValueFor(declarations.fieldAtControlIndex(index), field.defaultValue)
            index += 1
        }
        draftVersion += 1
        appliedVersion = draftVersion
        notice = "已恢复项目默认值"
        claimRevision()
        return (true, "none")
    }

    func fieldIds(): ArrayList<String> {
        let ids = ArrayList<String>()
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            ids.add(declarations.fieldAtControlIndex(index).fieldId)
            index += 1
        }
        return ids
    }

    func draftVersionValue(): Int64 {
        return draftVersion
    }

    func appliedVersionValue(): Int64 {
        return appliedVersion
    }

    /// 项目声明新增字段时，把同一 owner 的声明与草稿数组按**稳定字段 ID**扩展：
    /// 同 id 同类型的字段保留 draft/applied/fieldVersion，新字段用声明默认值初始化。
    /// 全部新数组先在本地构建，成功后才整体替换；类型/身份不兼容时返回 false 且不改动。
    func adoptDeclaration(next: PrototypeProject, nextDeclarations: CjguiSharedFormBinding): Bool {
        let oldIndexById = HashMap<String, Int64>()
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            oldIndexById.add(declarations.fieldAtControlIndex(index).fieldId, index)
            index += 1
        }
        let newDraft = ArrayList<String>()
        let newApplied = ArrayList<CjguiSharedOperationValue>()
        let newVersions = ArrayList<Int64>()
        index = 0
        while (index < nextDeclarations.fieldCount()) {
            let descriptor = nextDeclarations.fieldAtControlIndex(index)
            let oldIndex = oldIndexById.get(descriptor.fieldId) ?? -1
            if (oldIndex >= 0) {
                let oldDescriptor = declarations.fieldAtControlIndex(oldIndex)
                if (oldDescriptor.editorKind != descriptor.editorKind) {
                    return false
                }
                newDraft.add(draft[oldIndex])
                newApplied.add(applied[oldIndex])
                newVersions.add(fieldVersions[oldIndex])
            } else {
                let field = match (next.field(descriptor.fieldId)) {
                    case Some(value) => value
                    case None => return false
                }
                newDraft.add(field.defaultValue)
                newApplied.add(prototypeValueFor(descriptor, field.defaultValue))
                newVersions.add(0)
            }
            index += 1
        }
        if (newDraft.size != nextDeclarations.fieldCount()) {
            return false
        }
        this.project = next
        this.declarations = nextDeclarations
        this.draft = newDraft
        this.applied = newApplied
        this.fieldVersions = newVersions
        claimRevision()
        return true
    }

    /// 会话恢复的纯检查：字段身份与值集合完整、版本自洽。不改动任何状态。
    func canRestoreSessionState(state: PrototypeObjectSnapshot): Bool {
        if (state.drafts.size != declarations.fieldCount() ||
            state.applied.size != declarations.fieldCount() ||
            state.fieldVersions.size != declarations.fieldCount() ||
            state.draftVersion < 0 || state.appliedVersion < 0 ||
            state.appliedVersion > state.draftVersion) {
            return false
        }
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            let fieldId = declarations.fieldAtControlIndex(index).fieldId
            if (!state.drafts.contains(fieldId) || !state.applied.contains(fieldId) ||
                !state.fieldVersions.contains(fieldId)) {
                return false
            }
            if ((state.fieldVersions.get(fieldId) ?? 0) > state.draftVersion) {
                return false
            }
            index += 1
        }
        return true
    }

    /// 已通过 `canRestoreSessionState` 的载荷按字段 ID 整体写入（不再失败）。
    func restoreSessionState(state: PrototypeObjectSnapshot): Bool {
        if (!canRestoreSessionState(state)) {
            return false
        }
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            let descriptor = declarations.fieldAtControlIndex(index)
            draft[index] = state.drafts.get(descriptor.fieldId) ?? ""
            applied[index] = prototypeValueFor(descriptor,
                state.applied.get(descriptor.fieldId) ?? "")
            fieldVersions[index] = state.fieldVersions.get(descriptor.fieldId) ?? 0
            index += 1
        }
        draftVersion = state.draftVersion
        appliedVersion = state.appliedVersion
        notice = "已恢复原型会话"
        claimRevision()
        return true
    }

    private func indexOfField(fieldId: String): Int64 {
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            if (declarations.fieldAtControlIndex(index).fieldId == fieldId) {
                return index
            }
            index += 1
        }
        return -1
    }

    func snapshot(contextVersion: Int64): CjguiSharedFormSnapshot {
        let fields = ArrayList<CjguiSharedFormFieldProjection>()
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            let descriptor = declarations.fieldAtControlIndex(index)
            fields.add(CjguiSharedFormFieldProjection(descriptor.resourceId, descriptor.fieldId, applied[index],
                draft[index], validationOf(descriptor.fieldId), fieldVersions[index], false, 0, 0))
            index += 1
        }
        let error = firstError()
        return CjguiSharedFormSnapshot(contextVersion, appliedVersion, draftVersion, appliedVersion, fields,
            error.size == 0, if (error.size == 0) { statusText() } else { error })
    }

    // ——— CjguiSharedEditableFormDomain ———

    public func formBinding(): CjguiSharedFormBinding {
        return declarations
    }

    public func formSnapshot(): CjguiSharedFormSnapshot {
        return snapshot(clock.version())
    }

    public func editTextFromHuman(resourceId: Int64, text: String, selectionStart: Int64,
        selectionEnd: Int64): CjguiSharedOperationActionResult {
        let _ = selectionStart
        let _ = selectionEnd
        let before = clock.version()
        let index = indexOfFieldResource(resourceId)
        if (index < 0) {
            return CjguiSharedOperationActionResult(false, false, before, before, "未知字段资源 ${resourceId}")
        }
        let field = project.fields[index]
        // B: the DECLARED read-only fact is enforced by the owner, not only by
        // the editor's grey state. Human, generated and replay paths all reach
        // this one write entry, so none can bypass it.
        if (field.readonly) {
            return CjguiSharedOperationActionResult(false, false, before, before, "field_read_only")
        }
        let appliedBefore = appliedVersion
        let ok = setText(field.id, text)
        if (!ok) {
            return CjguiSharedOperationActionResult(false, false, before, clock.version(), "字段拒绝写入")
        }
        let _ = appliedBefore
        return CjguiSharedOperationActionResult(true, false, before, clock.version(), "none")
    }

    public func editBooleanFromHuman(resourceId: Int64, value: Bool): CjguiSharedOperationActionResult {
        let before = clock.version()
        let index = indexOfFieldResource(resourceId)
        if (index < 0) {
            return CjguiSharedOperationActionResult(false, false, before, before, "未知字段资源 ${resourceId}")
        }
        let field = project.fields[index]
        if (field.readonly) {
            return CjguiSharedOperationActionResult(false, false, before, before, "field_read_only")
        }
        let ok = setBoolean(field.id, value)
        if (!ok) {
            return CjguiSharedOperationActionResult(false, false, before, clock.version(), "字段拒绝写入")
        }
        return CjguiSharedOperationActionResult(true, false, before, clock.version(), "none")
    }

    public func applyDraftFromHuman(expectedDraftVersion: Int64,
        expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        let before = clock.version()
        let _ = expectedBaseAppliedConfigVersion
        if (expectedDraftVersion >= 0 && expectedDraftVersion != draftVersion) {
            return CjguiSharedOperationActionResult(false, true, before, before, "草稿版本已变化")
        }
        let (ok, reason) = applyDraft()
        return CjguiSharedOperationActionResult(ok, false, before, clock.version(), reason)
    }

    public func cancelDraftFromHuman(expectedDraftVersion: Int64,
        expectedBaseAppliedConfigVersion: Int64): CjguiSharedOperationActionResult {
        let before = clock.version()
        let _ = expectedBaseAppliedConfigVersion
        if (expectedDraftVersion >= 0 && expectedDraftVersion != draftVersion) {
            return CjguiSharedOperationActionResult(false, true, before, before, "草稿版本已变化")
        }
        let (ok, reason) = cancelDraft()
        return CjguiSharedOperationActionResult(ok, false, before, clock.version(), reason)
    }

    // ——— CjguiSharedOperationDomain ———

    public func resourceType(): String {
        return "prototype-object"
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        resources.add(CjguiSharedOperationResource(ownerId, key, ArrayList<CjguiSharedOperationField>()))
        return CjguiSharedOperationContextSnapshot(clock.version(), "prototype-object", "prototype-object",
            resources, ownerState: statusText())
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        let descriptors = ArrayList<CjguiSharedOperationActionDescriptor>()
        let noParameters = ArrayList<CjguiSharedOperationParameterDescriptor>()
        for (name in ["APPLY_DRAFT", "CANCEL_DRAFT", "RESTORE_DEFAULTS"]) {
            descriptors.add(CjguiSharedOperationActionDescriptor(name, name, noParameters, 0, 0))
        }
        return descriptors
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return executeAction(invocation)
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return executeAction(invocation)
    }

    private func executeAction(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let before = clock.version()
        if (invocation.expectedVersion >= 0 && invocation.expectedVersion != before) {
            return CjguiSharedOperationActionResult(false, true, before, before, "version_conflict")
        }
        if (invocation.actionName == "APPLY_DRAFT") {
            let (ok, reason) = applyDraft()
            return CjguiSharedOperationActionResult(ok, false, before, clock.version(), reason)
        }
        if (invocation.actionName == "CANCEL_DRAFT") {
            let (ok, reason) = cancelDraft()
            return CjguiSharedOperationActionResult(ok, false, before, clock.version(), reason)
        }
        if (invocation.actionName == "RESTORE_DEFAULTS") {
            let (ok, reason) = restoreDefaults()
            return CjguiSharedOperationActionResult(ok, false, before, clock.version(), reason)
        }
        return CjguiSharedOperationActionResult(false, false, before, before, "unknown_action")
    }

    private func indexOfFieldResource(resourceId: Int64): Int64 {
        var index: Int64 = 0
        while (index < declarations.fieldCount()) {
            if (declarations.fieldAtControlIndex(index).resourceId == resourceId) {
                return index
            }
            index += 1
        }
        return -1
    }
}

func prototypeFormBinding(project: PrototypeProject): CjguiSharedFormBinding {
    let descriptors = ArrayList<CjguiSharedFormFieldDescriptor>()
    for (field in project.fields) {
        let editorKind = field.editorKind()
        descriptors.add(CjguiSharedFormFieldDescriptor(field.resourceId, field.id, field.label, editorKind,
            required: field.required, minimum: field.minimum, maximum: field.maximum,
            maximumLength: field.maximumLength, readOnly: field.readonly))
    }
    return CjguiSharedFormBinding(descriptors)
}

func prototypeValueFor(descriptor: CjguiSharedFormFieldDescriptor, text: String): CjguiSharedOperationValue {
    if (descriptor.editorKind == "BOOLEAN") {
        return CjguiSharedOperationValue.boolean(text == "true")
    }
    if (descriptor.editorKind == "INTEGER") {
        try {
            return CjguiSharedOperationValue.integer(Int64.parse(text.trim()))
        } catch (_: Exception) {
            return CjguiSharedOperationValue.integer(0)
        }
    }
    return CjguiSharedOperationValue.string(text)
}

/// 字符（Unicode 标量）计数，用于 TEXT 的最大长度校验。按 UTF-8 首字节分组，
/// 和公共字段规则一致，不把字节数当字符数。
func prototypeScalarCount(text: String): Int64 {
    let bytes = text.toArray()
    var count: Int64 = 0
    var index: Int64 = 0
    while (index < bytes.size) {
        let byte = bytes[index]
        if ((byte & 0xC0u8) != 0x80u8) {
            count += 1
        }
        index += 1
    }
    return count
}

/// 一个原型项目的运行期 owner 集合。列表里的记录/卡片分别有自己的对象；
/// 选择、筛选与列数是**项目级**状态（宿主 chrome 与生成式详情共用一份）。
class PrototypeProjectDomain <: CjguiSharedOperationDomain {
    var project: PrototypeProject
    let clock: PrototypeRevisionClock
    private var objects: ArrayList<PrototypeObject>
    private var selection: Int64 = 0
    private var query: String = ""
    private var visible: ArrayList<Int64> = ArrayList<Int64>()
    private var columnsValue: Int64 = 3
    private var revisionValue: Int64 = 1

    init(project: PrototypeProject) {
        this.project = project
        this.clock = PrototypeRevisionClock()
        this.objects = ArrayList<PrototypeObject>()
        let hasRecords = project.recordSet.records.size > 0
        if (!hasRecords) {
            let initial = ArrayList<String>()
            for (field in project.fields) {
                initial.add(field.defaultValue)
            }
            objects.add(PrototypeObject(project, "active", 2000, clock, initial))
        } else {
            var index: Int64 = 0
            for (record in project.recordSet.records) {
                objects.add(PrototypeObject(project, record.key, 3000 + index, clock, record.values))
                index += 1
            }
        }
        rebuildVisible()
    }

    func objectCount(): Int64 {
        return objects.size
    }

    func objectAt(index: Int64): PrototypeObject {
        return objects[index]
    }

    func activeIndex(): Int64 {
        return selection
    }

    func activeObject(): PrototypeObject {
        return objects[selection]
    }

    func activeRecord(): ?PrototypeRecordDeclaration {
        if (project.recordSet.records.size == 0) {
            return None
        }
        if (selection < 0 || selection >= project.recordSet.records.size) {
            return None
        }
        return Some(project.recordSet.records[selection])
    }

    func visibleIndices(): ArrayList<Int64> {
        rebuildVisibleIfNeeded()
        return visible
    }

    func queryText(): String {
        return query
    }

    func setQuery(value: String): Bool {
        if (query == value) {
            return false
        }
        query = value
        rebuildVisible()
        revisionValue += 1
        clock.advance()
        return true
    }

    func columnCount(): Int64 {
        return columnsValue
    }

    func setColumnCount(value: Int64): Bool {
        let clamped = if (value < 2) { 2 } else if (value > 4) { 4 } else { value }
        if (columnsValue == clamped) {
            return false
        }
        columnsValue = clamped
        revisionValue += 1
        clock.advance()
        return true
    }

    func selectKey(key: String): Bool {
        var index: Int64 = 0
        for (record in project.recordSet.records) {
            if (record.key == key) {
                break
            }
            index += 1
        }
        if (index >= objects.size) {
            return false
        }
        if (selection == index) {
            return false
        }
        selection = index
        revisionValue += 1
        clock.advance()
        return true
    }

    func selectRecordIndex(recordIndex: Int64): Bool {
        if (recordIndex < 0 || recordIndex >= objects.size) {
            return false
        }
        if (selection == recordIndex) {
            return false
        }
        selection = recordIndex
        revisionValue += 1
        clock.advance()
        return true
    }

    func selectedKey(): String {
        if (selection < 0 || selection >= project.recordSet.records.size) {
            return ""
        }
        return project.recordSet.records[selection].key
    }

    func selectPosition(position: Int64): Bool {
        rebuildVisibleIfNeeded()
        if (position < 0 || position >= visible.size) {
            return false
        }
        let index = visible[position]
        if (selection == index) {
            return false
        }
        selection = index
        revisionValue += 1
        clock.advance()
        return true
    }

    /// 选中项被筛掉后，详情显示空状态；不清空原来对象的草稿。
    func selectionVisible(): Bool {
        rebuildVisibleIfNeeded()
        for (index in visible) {
            if (index == selection) {
                return true
            }
        }
        return false
    }

    /// 项目内任一记录（不只当前选中的 active 对象）有未应用草稿。切换项目与
    /// 关闭窗口必须以此为准，否则编辑 A、切换到干净的 B 后草稿会被静默丢弃。
    func hasAnyDraftChanges(): Bool {
        for (object in objects) {
            if (object.isDirty()) {
                return true
            }
        }
        return false
    }

    func selectedRecordTitle(): String {
        if (!selectionVisible()) {
            return ""
        }
        return match (activeRecord()) {
            case Some(record) => record.title
            case None => ""
        }
    }

    private func rebuildVisible(): Unit {
        visible = ArrayList<Int64>()
        let keyword = query.trim()
        var index: Int64 = 0
        for (record in project.recordSet.records) {
            if (keyword.size == 0 || record.title.contains(keyword)) {
                visible.add(index)
            }
            index += 1
        }
    }

    private func rebuildVisibleIfNeeded(): Unit {
        if (visible.size == 0 && project.recordSet.records.size > 0 && query.trim().size == 0) {
            rebuildVisible()
        }
    }

    func revision(): Int64 {
        return revisionValue + clock.version()
    }

    /// 声明新增字段：所有对象先检查可扩展，再一起替换声明与草稿存储。
    /// 失败时返回 false 且不改变任何对象或项目字段。
    func adoptDeclaration(next: PrototypeProject, nextDeclarations: CjguiSharedFormBinding): Bool {
        for (object in objects) {
            if (!object.adoptDeclaration(next, nextDeclarations)) {
                // 兼容字段类型都已经在调用方校验；这里出现失败说明声明不兼容，
                // 因为前面的对象可能已更新，调用方必须丢弃整个会话而不是继续使用。
                return false
            }
        }
        project = next
        revisionValue += 1
        clock.advance()
        return true
    }

    /// 会话恢复：先整体检查（对象集合/字段身份/版本），全部通过后再写入。
    func restoreSessionState(payload: PrototypeSessionPayload): Bool {
        if (payload.objects.size != objects.size) {
            return false
        }
        let byKey = HashMap<String, PrototypeObjectSnapshot>()
        for (state in payload.objects) {
            if (byKey.contains(state.key)) {
                return false
            }
            byKey.add(state.key, state)
        }
        var index: Int64 = 0
        while (index < objects.size) {
            let object = objects[index]
            let state = match (byKey.get(object.key)) {
                case Some(value) => value
                case None => return false
            }
            if (!object.canRestoreSessionState(state)) {
                return false
            }
            index += 1
        }
        index = 0
        while (index < objects.size) {
            let object = objects[index]
            let state = byKey.get(object.key).getOrThrow()
            if (!object.restoreSessionState(state)) {
                return false
            }
            index += 1
        }
        let _ = setQuery(payload.query)
        let _ = setColumnCount(payload.columns)
        let _ = selectKey(payload.selectedKey)
        revisionValue += 1
        return true
    }

    /// 项目声明的动作：目前语义是「把当前对象的草稿/已应用值恢复到声明默认值」。
    /// 动作名来自项目声明；宿主不硬编码某个案例名。
    func performDeclaredAction(actionName: String): (Bool, String) {
        for (declared in project.actions) {
            if (declared.name == actionName) {
                let result = activeObject().restoreDefaults()
                revisionValue += 1
                return result
            }
        }
        return (false, "unknown_action:${actionName}")
    }

    func statusLine(): String {
        if (project.recordSet.records.size == 0) {
            return activeObject().statusText()
        }
        let total = project.recordSet.records.size
        let shown = visibleIndices().size
        let selected = selectedRecordTitle()
        let title = if (selected.size > 0) { "已选 ${selected}" } else { "未选择记录" }
        return "共 ${total} 条 · 当前显示 ${shown} 条 · ${title}"
    }

    // ——— CjguiSharedOperationDomain（项目级动作/读回） ———

    public func resourceType(): String {
        return "prototype-project"
    }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        let resources = ArrayList<CjguiSharedOperationResource>()
        resources.add(CjguiSharedOperationResource(2000, project.id, ArrayList<CjguiSharedOperationField>()))
        return CjguiSharedOperationContextSnapshot(revision(), project.id, "prototype-project", resources,
            ownerState: "view=${project.viewKind};visible=${visibleIndices().size};selected=${selection}")
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        let descriptors = ArrayList<CjguiSharedOperationActionDescriptor>()
        let withKey = ArrayList<CjguiSharedOperationParameterDescriptor>()
        withKey.add(CjguiSharedOperationParameterDescriptor("key", "STRING", true))
        descriptors.add(CjguiSharedOperationActionDescriptor("SELECT_RECORD", "选择记录", withKey, 0, 0))
        let withQuery = ArrayList<CjguiSharedOperationParameterDescriptor>()
        withQuery.add(CjguiSharedOperationParameterDescriptor("query", "STRING", true))
        descriptors.add(CjguiSharedOperationActionDescriptor("FILTER_RECORDS", "筛选记录", withQuery, 0, 0))
        for (declared in project.actions) {
            let parameters = ArrayList<CjguiSharedOperationParameterDescriptor>()
            descriptors.add(CjguiSharedOperationActionDescriptor(declared.name, declared.label, parameters, 0, 0))
        }
        return descriptors
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return executeAction(invocation)
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return executeAction(invocation)
    }

    private func executeAction(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        let before = revision()
        if (invocation.actionName == "SELECT_RECORD") {
            let key = prototypeArgument(invocation, "key")
            let ok = selectKey(key)
            return CjguiSharedOperationActionResult(ok, false, before, revision(),
                if (ok) { "none" } else { "record_not_found" })
        }
        if (invocation.actionName == "FILTER_RECORDS") {
            let ok = setQuery(prototypeArgument(invocation, "query"))
            return CjguiSharedOperationActionResult(true, false, before, revision(), "none")
        }
        for (declared in project.actions) {
            if (declared.name == invocation.actionName) {
                let (ok, reason) = activeObject().restoreDefaults()
                return CjguiSharedOperationActionResult(ok, false, before, revision(), reason)
            }
        }
        return CjguiSharedOperationActionResult(false, false, before, before, "unknown_action")
    }
}

func prototypeArgument(invocation: CjguiSharedOperationActionInvocation, name: String): String {
    for (argument in invocation.arguments) {
        if (argument.name == name) {
            return argument.value.displayText()
        }
    }
    return ""
}

/// 列表次行文本：只用声明/数据里已有的稳定 id、数量与启用状态，不引入第二套派生数据。
func prototypeRecordRowMeta(project: PrototypeProject, record: PrototypeRecordDeclaration): String {
    var quantity = ""
    var enabled = ""
    var index: Int64 = 0
    while (index < project.fields.size) {
        let field = project.fields[index]
        if (index < record.values.size) {
            if (field.editorKind() == "INTEGER") {
                quantity = record.values[index]
            } else if (field.editorKind() == "BOOLEAN") {
                enabled = if (record.values[index] == "true") { "启用" } else { "已停用" }
            }
        }
        index += 1
    }
    var meta = record.key
    if (quantity.size > 0) {
        meta += " · 数量 ${quantity}"
    }
    if (enabled.size > 0) {
        meta += " · ${enabled}"
    }
    return meta
}
