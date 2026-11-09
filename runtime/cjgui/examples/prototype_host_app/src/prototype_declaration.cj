package cjgui_prototype_host

import cjgui.*
import std.collection.*
import std.convert.*
import std.fs.*
import std.unicode.*

// ——— 受约束的 Option/JSON 读取辅助（不引入第二套解析器） ———

func prototypeOptionText(value: ?PrototypeJson): String {
    if (let Some(found) <- value) {
        if (let Some(text) <- found.asString()) {
            return text
        }
    }
    return ""
}

func prototypeFieldText(json: PrototypeJson, name: String): String {
    if (let Some(found) <- json.field(name)) {
        if (let Some(text) <- found.asString()) {
            return text
        }
    }
    return ""
}

func prototypeFieldTextOr(json: PrototypeJson, name: String, alternate: String): String {
    if (let Some(found) <- json.field(name)) {
        if (let Some(text) <- found.asString()) {
            if (text.size > 0) {
                return text
            }
        }
    }
    return alternate
}

func prototypeFieldIntOr(json: PrototypeJson, name: String, alternate: Int64): Int64 {
    if (let Some(found) <- json.field(name)) {
        if (let Some(value) <- found.asInteger()) {
            return value
        }
    }
    return alternate
}

func prototypeFieldBoolOr(json: PrototypeJson, name: String, alternate: Bool): Bool {
    if (let Some(found) <- json.field(name)) {
        if (let Some(value) <- found.asBool()) {
            return value
        }
    }
    return alternate
}

/// 一个原型字段的**唯一声明**。同一份声明供：原型 owner 的写入/校验、手写控件投影、
/// 生成式能力目录（外部发现）与生成式表单绑定。字段类型只支持 TEXT/INTEGER/BOOLEAN，
/// 以及建立在其上的 select 呈现。
class PrototypeFieldDeclaration {
    let id: String
    let label: String
    let kind: String          // "text" | "integer" | "boolean" | "select"
    let group: String
    let help: String
    let errorText: String
    let placeholder: String
    let required: Bool
    let minimum: Int64
    let maximum: Int64
    let maximumLength: Int64
    let options: ArrayList<CjguiSelectOption>
    let optionValues: ArrayList<String>
    let defaultValue: String  // 规范文本（select 为 option value）
    let resourceId: Int64
    let sourceField: String   // 记录数据源里对应的属性名
    let readonly: Bool

    init(id: String, label: String, kind: String, group: String, help: String, errorText: String,
        placeholder: String, required: Bool, minimum: Int64, maximum: Int64, maximumLength: Int64,
        options: ArrayList<CjguiSelectOption>, optionValues: ArrayList<String>, defaultValue: String,
        resourceId: Int64, sourceField: String, readonly: Bool) {
        this.id = id
        this.label = label
        this.kind = kind
        this.group = group
        this.help = help
        this.errorText = errorText
        this.placeholder = placeholder
        this.required = required
        this.minimum = minimum
        this.maximum = maximum
        this.maximumLength = maximumLength
        this.options = options
        this.optionValues = optionValues
        this.defaultValue = defaultValue
        this.resourceId = resourceId
        this.sourceField = sourceField
        this.readonly = readonly
    }

    /// 生成式目录/edit 层使用的字段类型；select 以 TEXT 承载并由 select 绑定换呈现。
    func editorKind(): String {
        if (kind == "integer") {
            return "INTEGER"
        }
        if (kind == "boolean") {
            return "BOOLEAN"
        }
        return "TEXT"
    }

    func isSelect(): Bool {
        return kind == "select"
    }

    func isBoolean(): Bool {
        return kind == "boolean"
    }

    func isInteger(): Bool {
        return kind == "integer"
    }

    func propertyName(): String {
        return if (sourceField.size > 0) { sourceField } else { id }
    }
}

/// 一个原型对象（记录/卡片）的初始声明。运行期草稿与已应用值归 owner，不在这里。
class PrototypeRecordDeclaration {
    let key: String
    let title: String
    let values: ArrayList<String>   // 与 project.fields 对齐的初始值（规范文本）
    let image: String
    let tags: ArrayList<String>
    let status: String

    init(key: String, title: String, values: ArrayList<String>, image: String,
        tags: ArrayList<String>, status: String) {
        this.key = key
        this.title = title
        this.values = values
        this.image = image
        this.tags = tags
        this.status = status
    }
}

class PrototypeGroupDeclaration {
    let id: String
    let title: String
    let help: String

    init(id: String, title: String, help: String) {
        this.id = id
        this.title = title
        this.help = help
    }
}

class PrototypeActionDeclaration {
    let name: String
    let label: String
    let emphasis: String  // "primary" | "secondary" | "quiet"

    init(name: String, label: String, emphasis: String) {
        this.name = name
        this.label = label
        this.emphasis = emphasis
    }
}

class PrototypeRecordSetDeclaration {
    let records: ArrayList<PrototypeRecordDeclaration>
    let titleField: String
    let filterField: String
    let imageProperty: String
    let tagsProperty: String
    let statusProperty: String

    init(records: ArrayList<PrototypeRecordDeclaration>, titleField: String, filterField: String,
        imageProperty: String, tagsProperty: String, statusProperty: String) {
        this.records = records
        this.titleField = titleField
        this.filterField = filterField
        this.imageProperty = imageProperty
        this.tagsProperty = tagsProperty
        this.statusProperty = statusProperty
    }

    static func empty(): PrototypeRecordSetDeclaration {
        return PrototypeRecordSetDeclaration(ArrayList<PrototypeRecordDeclaration>(), "title", "title",
            "image", "tags", "status")
    }
}

/// 一个可搬移的原型项目：声明 + 数据 + 界面文件 + 资源，全部相对**项目根**解析。
/// 宿主只用这一份读取路径，因此换 cwd、搬移项目目录都得到同一资源身份。
class PrototypeProject {
    let root: String
    let id: String
    let title: String
    let viewKind: String      // "form" | "list" | "cards"
    let themeName: String     // "hig" | "paper" | "beacon"
    let windowWidth: Int64
    let windowHeight: Int64
    let minimumWidth: Int64
    let groups: ArrayList<PrototypeGroupDeclaration>
    let fields: ArrayList<PrototypeFieldDeclaration>
    let recordSet: PrototypeRecordSetDeclaration
    let actions: ArrayList<PrototypeActionDeclaration>
    let uiDocumentPath: String
    let sessionPath: String
    let assetDeclarations: ArrayList<(String, String, String)>
    let declarationSize: Int64

    init(root: String, id: String, title: String, viewKind: String, themeName: String, windowWidth: Int64,
        windowHeight: Int64, minimumWidth: Int64, groups: ArrayList<PrototypeGroupDeclaration>,
        fields: ArrayList<PrototypeFieldDeclaration>, recordSet: PrototypeRecordSetDeclaration,
        actions: ArrayList<PrototypeActionDeclaration>, uiDocumentPath: String, sessionPath: String,
        assetDeclarations: ArrayList<(String, String, String)>, declarationSize: Int64) {
        this.root = root
        this.id = id
        this.title = title
        this.viewKind = viewKind
        this.themeName = themeName
        this.windowWidth = windowWidth
        this.windowHeight = windowHeight
        this.minimumWidth = minimumWidth
        this.groups = groups
        this.fields = fields
        this.recordSet = recordSet
        this.actions = actions
        this.uiDocumentPath = uiDocumentPath
        this.sessionPath = sessionPath
        this.assetDeclarations = assetDeclarations
        this.declarationSize = declarationSize
    }

    func fieldIndex(fieldId: String): Int64 {
        var index: Int64 = 0
        while (index < fields.size) {
            if (fields[index].id == fieldId) {
                return index
            }
            index += 1
        }
        return -1
    }

    func field(fieldId: String): ?PrototypeFieldDeclaration {
        let index = fieldIndex(fieldId)
        if (index < 0) {
            return None
        }
        return Some(fields[index])
    }

    func groupTitle(groupId: String): String {
        for (group in groups) {
            if (group.id == groupId) {
                return group.title
            }
        }
        return ""
    }

    func hasRecords(): Bool {
        return recordSet.records.size > 0
    }

    func record(key: String): ?PrototypeRecordDeclaration {
        for (record in recordSet.records) {
            if (record.key == key) {
                return Some(record)
            }
        }
        return None
    }

    func assets(): ArrayList<(String, String, String)> {
        return assetDeclarations
    }

    func assetPath(key: String): String {
        for (asset in assetDeclarations) {
            if (asset[0] == key) {
                return asset[2]
            }
        }
        return ""
    }

    func hasView(view: String): Bool {
        return viewKind == view
    }
}

/// 复制一个项目但替换字段表（运行期声明扩展用）。其余数据、动作、资源与界面/会话
/// 路径保持同一身份，避免第二个项目声明来源。
func prototypeProjectWithFields(project: PrototypeProject, title: String,
    fields: ArrayList<PrototypeFieldDeclaration>): PrototypeProject {
    return PrototypeProject(project.root, project.id, title, project.viewKind, project.themeName,
        project.windowWidth, project.windowHeight, project.minimumWidth, project.groups, fields,
        project.recordSet, project.actions, project.uiDocumentPath, project.sessionPath,
        project.assetDeclarations, project.declarationSize)
}

private func prototypeFieldsEqual(a: PrototypeFieldDeclaration, b: PrototypeFieldDeclaration): Bool {
    if (a.label != b.label || a.kind != b.kind || a.group != b.group || a.help != b.help ||
        a.errorText != b.errorText || a.placeholder != b.placeholder || a.required != b.required ||
        a.minimum != b.minimum || a.maximum != b.maximum || a.maximumLength != b.maximumLength ||
        a.defaultValue != b.defaultValue || a.sourceField != b.sourceField || a.readonly != b.readonly) {
        return false
    }
    if (a.options.size != b.options.size || a.optionValues.size != b.optionValues.size) {
        return false
    }
    var index: Int64 = 0
    while (index < a.options.size) {
        if (a.options[index].key != b.options[index].key || a.options[index].label != b.options[index].label ||
            a.options[index].value != b.options[index].value) {
            return false
        }
        index += 1
    }
    index = 0
    while (index < a.optionValues.size) {
        if (a.optionValues[index] != b.optionValues[index]) {
            return false
        }
        index += 1
    }
    return true
}

private func prototypeActionsEqual(a: ArrayList<PrototypeActionDeclaration>,
    b: ArrayList<PrototypeActionDeclaration>): Bool {
    if (a.size > b.size) {
        return false
    }
    var index: Int64 = 0
    while (index < a.size) {
        if (a[index].name != b[index].name || a[index].label != b[index].label ||
            a[index].emphasis != b[index].emphasis) {
            return false
        }
        index += 1
    }
    return true
}

/// 运行期声明扩展的兼容性判断：只允许“新增字段 + 新增动作 + 标题变化”。
/// 视图、记录集、主题、窗口、分组、既有字段规则和既有动作的变化都不在本轮支持范围，
/// 以具名原因拒绝（由调用方保留旧项目），不做部分更新或静默忽略。
func prototypeDeclarationAdoptionIssue(current: PrototypeProject, updated: PrototypeProject): String {
    if (updated.id != current.id) {
        return "declaration_project_mismatch"
    }
    if (updated.viewKind != current.viewKind) {
        return "view_change_requires_project_switch"
    }
    if (updated.themeName != current.themeName) {
        return "theme_change_requires_project_switch"
    }
    if (updated.recordSet.records.size != current.recordSet.records.size ||
        updated.recordSet.titleField != current.recordSet.titleField ||
        updated.recordSet.filterField != current.recordSet.filterField ||
        updated.recordSet.imageProperty != current.recordSet.imageProperty ||
        updated.recordSet.tagsProperty != current.recordSet.tagsProperty ||
        updated.recordSet.statusProperty != current.recordSet.statusProperty) {
        return "records_change_requires_project_switch"
    }
    if (updated.windowWidth != current.windowWidth || updated.windowHeight != current.windowHeight ||
        updated.minimumWidth != current.minimumWidth) {
        return "window_change_requires_restart"
    }
    if (updated.groups.size != current.groups.size) {
        return "group_change_requires_project_switch"
    }
    var index: Int64 = 0
    while (index < current.groups.size) {
        if (updated.groups[index].id != current.groups[index].id ||
            updated.groups[index].title != current.groups[index].title ||
            updated.groups[index].help != current.groups[index].help) {
            return "group_change_requires_project_switch"
        }
        index += 1
    }
    // 记录数据按 recordSet 顺序对齐；本阶段记录集必须完全一致。
    index = 0
    while (index < current.fields.size) {
        let field = current.fields[index]
        let nextIndex = updated.fieldIndex(field.id)
        if (nextIndex < 0) {
            return "field_removal_requires_project_switch:${field.id}"
        }
        if (!prototypeFieldsEqual(field, updated.fields[nextIndex])) {
            return "existing_field_rule_change_unsupported:${field.id}"
        }
        index += 1
    }
    // R3: this round only hot-updates FIELDS. Any action declaration change
    // (add/remove/relabel/re-emphasize) is explicitly rejected so a new action
    // can never reach the catalog while the project declaration stays old.
    if (!prototypeActionsEqual(current.actions, updated.actions) ||
        current.actions.size != updated.actions.size) {
        return "action_change_requires_project_switch"
    }
    // 新增字段：上限、select 选项唯一性在这里先查，避免注册一半。
    if (updated.fields.size > 24) {
        return "declaration_too_many_fields"
    }
    for (field in updated.fields) {
        if (current.fieldIndex(field.id) >= 0) {
            continue
        }
        if (field.isSelect()) {
            let keys = HashSet<String>()
            let values = HashSet<String>()
            for (option in field.options) {
                if (!keys.add(option.key) || !values.add(option.value)) {
                    return "new_field_choice_duplicate:${field.id}"
                }
            }
        }
    }
    return ""
}

/// 读取并校验一个原型项目目录。任何声明错误都以具名异常拒绝
/// （`prototype_declaration:<reason>`）；调用方据此保留旧项目，不采用半份声明。
class PrototypeProjectLoader {
    static func load(root: String): PrototypeProject {
        // 项目根必须是绝对路径：资源、界面文件与会话文件都以它为唯一锚点，
        // 相对路径会随 cwd 变化而指向不同文件。
        if (!root.startsWith("/")) {
            throw Exception("prototype_project:absolute_path_required")
        }
        if (!exists(Path(root))) {
            throw Exception("prototype_project:missing_directory")
        }
        let declarationPath = "${root}/prototype.json"
        let text = prototypeReadFile(declarationPath, 1024 * 1024, "prototype_declaration")
        let json = PrototypeJsonParser.parse(text)
        if (json.kind != PrototypeJson.KIND_OBJECT) {
            throw Exception("prototype_declaration:not_an_object")
        }
        let schema = prototypeFieldText(json, "schema")
        if (schema != "cgui.prototype-project.v1" && schema != "cjgui.prototype-project.v1") {
            throw Exception("prototype_declaration:unsupported_schema")
        }
        let id = prototypeFieldText(json, "id")
        if (id.size == 0) {
            throw Exception("prototype_declaration:missing_id")
        }
        let title = prototypeFieldTextOr(json, "title", id)
        let viewKind = validViewKind(prototypeFieldTextOr(json, "view", "form"))
        let themeName = prototypeFieldTextOr(json, "theme", "hig")
        let window = json.field("window")
        let windowWidth = window.map({ value => prototypeFieldIntOr(value, "width", 980) }) ?? 980
        let windowHeight = window.map({ value => prototypeFieldIntOr(value, "height", 760) }) ?? 760
        let minimumWidth = window.map({ value => prototypeFieldIntOr(value, "minimumWidth", 720) }) ?? 720
        let groups = parseGroups(json.field("groups"))
        let fields = parseFields(json.field("fields"), groups)
        let recordSet = parseRecords(root, json.field("records"), fields)
        let actions = parseActions(json.field("actions"))
        let assets = parseAssets(root, json.field("assets"), viewKind, recordSet)
        let uiRelative = prototypeFieldTextOr(json, "ui", "ui/main.json")
        let sessionRelative = prototypeFieldTextOr(json, "session", "session.json")
        return PrototypeProject(root, id, title, viewKind, themeName, windowWidth, windowHeight, minimumWidth,
            groups, fields, recordSet, actions, "${root}/${uiRelative}", "${root}/${sessionRelative}", assets,
            text.size)
    }

    private static func validViewKind(kind: String): String {
        if (kind == "form" || kind == "list" || kind == "cards") {
            return kind
        }
        throw Exception("prototype_declaration:unknown_view")
    }

    private static func parseGroups(source: ?PrototypeJson): ArrayList<PrototypeGroupDeclaration> {
        let groups = ArrayList<PrototypeGroupDeclaration>()
        let values = match (source) {
            case Some(value) => value
            case None => return groups
        }
        if (values.kind != PrototypeJson.KIND_ARRAY) {
            throw Exception("prototype_declaration:groups_not_array")
        }
        if (values.items.size > 16) {
            throw Exception("prototype_declaration:too_many_groups")
        }
        for (item in values.items) {
            let id = prototypeFieldText(item, "id")
            if (id.size == 0) {
                throw Exception("prototype_declaration:missing_group_id")
            }
            groups.add(PrototypeGroupDeclaration(id, prototypeFieldTextOr(item, "title", id),
                prototypeFieldText(item, "help")))
        }
        return groups
    }

    private static func parseFields(source: ?PrototypeJson,
        groups: ArrayList<PrototypeGroupDeclaration>): ArrayList<PrototypeFieldDeclaration> {
        let fields = ArrayList<PrototypeFieldDeclaration>()
        let values = match (source) {
            case Some(value) => value
            case None => throw Exception("prototype_declaration:missing_fields")
        }
        if (values.kind != PrototypeJson.KIND_ARRAY) {
            throw Exception("prototype_declaration:fields_not_array")
        }
        if (values.items.size == 0) {
            throw Exception("prototype_declaration:fields_empty")
        }
        if (values.items.size > 24) {
            throw Exception("prototype_declaration:too_many_fields")
        }
        let seen = HashSet<String>()
        var index: Int64 = 0
        for (item in values.items) {
            let id = prototypeFieldText(item, "id")
            if (id.size == 0) {
                throw Exception("prototype_declaration:missing_field_id")
            }
            if (seen.contains(id)) {
                throw Exception("prototype_declaration:duplicate_field")
            }
            seen.add(id)
            let kind = prototypeFieldTextOr(item, "kind", "text")
            if (kind != "text" && kind != "integer" && kind != "boolean" && kind != "select") {
                throw Exception("prototype_declaration:unknown_field_kind")
            }
            let group = prototypeFieldText(item, "group")
            if (group.size > 0 && groups.size > 0) {
                var known = false
                for (declared in groups) {
                    if (declared.id == group) {
                        known = true
                    }
                }
                if (!known) {
                    throw Exception("prototype_declaration:unknown_group")
                }
            }
            let options = ArrayList<CjguiSelectOption>()
            let optionValues = ArrayList<String>()
            if (kind == "select") {
                let declaredOptions = match (item.field("options")) {
                    case Some(value) => value
                    case None => throw Exception("prototype_declaration:select_options_missing")
                }
                for (option in declaredOptions.items) {
                    let value = if (option.kind == PrototypeJson.KIND_OBJECT) {
                        prototypeFieldText(option, "value")
                    } else {
                        option.asString() ?? ""
                    }
                    if (value.size == 0) {
                        throw Exception("prototype_declaration:select_option_value")
                    }
                    optionValues.add(value)
                    let label = if (option.kind == PrototypeJson.KIND_OBJECT) {
                        prototypeFieldTextOr(option, "label", value)
                    } else {
                        value
                    }
                    options.add(CjguiSelectOption(value, label, value))
                }
                if (options.size == 0) {
                    throw Exception("prototype_declaration:select_options_missing")
                }
            }
            let minimum = prototypeFieldIntOr(item, "minimum", 0)
            let maximum = prototypeFieldIntOr(item, "maximum", 0)
            if (kind == "integer" && maximum > 0 && minimum > maximum) {
                throw Exception("prototype_declaration:integer_range")
            }
            let rawDefault = fieldDefaultText(item, kind)
            let defaultValue = if (kind == "boolean") {
                if (rawDefault == "true") { "true" } else { "false" }
            } else if (kind == "select") {
                guardOption(rawDefault, optionValues)
            } else {
                rawDefault
            }
            fields.add(PrototypeFieldDeclaration(id, prototypeFieldTextOr(item, "label", id), kind, group,
                prototypeFieldText(item, "help"), prototypeFieldText(item, "error"),
                prototypeFieldText(item, "placeholder"), prototypeFieldBoolOr(item, "required", false),
                minimum, maximum, prototypeFieldIntOr(item, "maximumLength", 0), options, optionValues,
                defaultValue, 1000 + index * 10,
                prototypeFieldTextOr(item, "sourceField", id), prototypeFieldBoolOr(item, "readonly", false)))
            index += 1
        }
        return fields
    }

    private static func guardOption(value: String, options: ArrayList<String>): String {
        for (option in options) {
            if (option == value) {
                return value
            }
        }
        return options[0]
    }

    private static func fieldDefaultText(item: PrototypeJson, kind: String): String {
        let value = match (item.field("value")) {
            case Some(found) => found
            case None => return if (kind == "boolean") { "false" } else { "" }
        }
        if (kind == "boolean") {
            if (let Some(flag) <- value.asBool()) {
                return if (flag) { "true" } else { "false" }
            }
            return "false"
        }
        if (let Some(text) <- value.asString()) {
            return text
        }
        if (let Some(number) <- value.asInteger()) {
            return "${number}"
        }
        return ""
    }

    /// 记录/卡片声明既可以在 `prototype.json` 里内联数组，也可以指向相对项目根的
    /// 数据文件（大集合默认放文件）；两者走同一校验，不产生第二套数据模型。
    private static func parseRecords(root: String, source: ?PrototypeJson,
        fields: ArrayList<PrototypeFieldDeclaration>): PrototypeRecordSetDeclaration {
        let declared = match (source) {
            case Some(value) => value
            case None => return PrototypeRecordSetDeclaration.empty()
        }
        let titleField = prototypeFieldTextOr(declared, "titleField", "title")
        let filterField = prototypeFieldTextOr(declared, "filterField", titleField)
        let imageProperty = prototypeFieldTextOr(declared, "imageProperty", "image")
        let tagsProperty = prototypeFieldTextOr(declared, "tagsProperty", "tags")
        let statusProperty = prototypeFieldTextOr(declared, "statusProperty", "status")
        let file = prototypeFieldText(declared, "file")
        let payload = if (file.size > 0) {
            PrototypeJsonParser.parse(prototypeReadFile("${root}/${file}", 4 * 1024 * 1024, "prototype_records"))
        } else {
            declared
        }
        var items: ArrayList<PrototypeJson> = ArrayList<PrototypeJson>()
        if (payload.kind == PrototypeJson.KIND_ARRAY) {
            items = payload.items
        } else if (let Some(list) <- payload.field("records")) {
            items = list.items
        } else if (let Some(list) <- payload.field("cards")) {
            items = list.items
        }
        if (items.size > 2000) {
            throw Exception("prototype_declaration:too_many_records")
        }
        let records = ArrayList<PrototypeRecordDeclaration>()
        var index: Int64 = 0
        for (item in items) {
            let key = prototypeFieldTextOr(item, "id", "record-${index}")
            let title = prototypeFieldTextOr(item, titleField, key)
            let tags = match (item.field(tagsProperty)) {
                case Some(value) => value.stringArray()
                case None => ArrayList<String>()
            }
            records.add(PrototypeRecordDeclaration(key, title, recordValues(item, fields),
                prototypeFieldText(item, imageProperty), tags, prototypeFieldText(item, statusProperty)))
            index += 1
        }
        return PrototypeRecordSetDeclaration(records, titleField, filterField, imageProperty, tagsProperty,
            statusProperty)
    }

    /// 一条记录的字段初始值：按字段的 `sourceField` 从共享数据里读取一次，
    /// 转成与 owner 相同的规范文本。缺失属性回落到声明默认值。
    private static func recordValues(item: PrototypeJson,
        fields: ArrayList<PrototypeFieldDeclaration>): ArrayList<String> {
        let values = ArrayList<String>()
        for (field in fields) {
            let raw = item.field(field.propertyName())
            let text = match (raw) {
                case Some(value) => prototypePropertyText(value, field)
                case None => field.defaultValue
            }
            values.add(text)
        }
        return values
    }

    private static func prototypePropertyText(value: PrototypeJson, field: PrototypeFieldDeclaration): String {
        if (field.isBoolean()) {
            if (let Some(flag) <- value.asBool()) {
                return if (flag) { "true" } else { "false" }
            }
            if (let Some(text) <- value.asString()) {
                return if (text == "true") { "true" } else { "false" }
            }
            return field.defaultValue
        }
        if (field.isInteger()) {
            if (let Some(number) <- value.asInteger()) {
                return "${number}"
            }
            return field.defaultValue
        }
        if (let Some(text) <- value.asString()) {
            if (field.isSelect()) {
                for (option in field.optionValues) {
                    if (option == text) {
                        return text
                    }
                }
                return field.defaultValue
            }
            return text
        }
        return field.defaultValue
    }

    /// 资源声明：界面只引用逻辑 key，宿主按项目根解析成同一个实际文件。
    /// 卡片项目还会把每条记录自己的图片自动登记（同一目录、同一份数据声明），
    /// 避免为每张图再写一遍清单。
    private static func parseAssets(root: String, source: ?PrototypeJson, viewKind: String,
        recordSet: PrototypeRecordSetDeclaration): ArrayList<(String, String, String)> {
        let assets = ArrayList<(String, String, String)>()
        if (let Some(values) <- source) {
            for (item in values.items) {
                let key = prototypeFieldText(item, "key")
                let relative = prototypeFieldText(item, "path")
                if (key.size == 0 || relative.size == 0) {
                    throw Exception("prototype_declaration:asset_entry")
                }
                let contentType = prototypeFieldTextOr(item, "contentType", prototypeImageContentType(relative))
                assets.add((key, contentType, "${root}/${relative}"))
            }
        }
        if (viewKind == "cards") {
            for (record in recordSet.records) {
                if (record.image.size == 0) {
                    continue
                }
                var declared = false
                for (asset in assets) {
                    if (asset[0] == record.key) {
                        declared = true
                    }
                }
                if (!declared) {
                    assets.add((record.key, prototypeImageContentType(record.image), "${root}/${record.image}"))
                }
            }
        }
        return assets
    }

    private static func prototypeImageContentType(path: String): String {
        if (path.endsWith(".jpg") || path.endsWith(".jpeg")) {
            return "JPEG"
        }
        return "PNG"
    }

    private static func parseActions(source: ?PrototypeJson): ArrayList<PrototypeActionDeclaration> {
        let actions = ArrayList<PrototypeActionDeclaration>()
        let values = match (source) {
            case Some(value) => value
            case None => return actions
        }
        for (item in values.items) {
            let name = prototypeFieldText(item, "name")
            if (name.size == 0) {
                throw Exception("prototype_declaration:missing_action_name")
            }
            actions.add(PrototypeActionDeclaration(name, prototypeFieldTextOr(item, "label", name),
                prototypeFieldTextOr(item, "emphasis", "secondary")))
        }
        return actions
    }
}
