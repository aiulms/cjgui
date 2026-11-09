package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.fs.*

// ——— 路径与项目定位 ———

/// 取父目录（项目根的上一级）。路径按 UTF-8 字节查找最后一个 '/'，与文件 API 一致。
func prototypeParentDirectory(path: String): String {
    let bytes = path.toArray()
    var index = bytes.size - 1
    while (index > 0) {
        if (bytes[index] == 0x2Fu8) {
            return path[..index]
        }
        index -= 1
    }
    return "/"
}

/// 启动时同一二进制可打开任一受支持领域的项目：参数只给项目根，声明/数据/界面/资源
/// 都从该根解析。这里不做目录遍历猜测，也不从项目名分支到编译好的页面。
func prototypeProjectPathFromArguments(args: Array<String>): (String, String) {
    var projectPath = ""
    var collaboration = false
    var workSessionPath = ""
    var index: Int64 = 0
    while (index < args.size) {
        if (args[index] == "--project" && index + 1 < args.size) {
            projectPath = args[index + 1]
            index += 2
        } else if (args[index] == "--collaboration") {
            collaboration = true
            index += 1
        } else if (args[index] == "--self-check") {
            index += 1
        } else if (args[index] == "--minimal" || args[index] == "--no-connection" ||
            args[index] == "--diagnose-window" || args[index] == "--observe-layout" ||
            args[index] == "--split-demo" || args[index] == "--measure") {
            index += 1
        } else if ((args[index] == "--work-session" || args[index] == "--clip-probe" ||
            args[index] == "--split-demo-axis") && index + 1 < args.size) {
            workSessionPath = args[index + 1]
            index += 2
        } else {
            return ("", "usage")
        }
    }
    let _ = workSessionPath
    return (projectPath, if (collaboration) { "collaboration" } else { "" })
}

// ——— 原型业务会话（复用公共 WorkSession 的原子写与校验基线） ———
//
// 载荷按**稳定字段 ID**保存与恢复：字段顺序变化不改变对应关系；新增字段的旧会话
// 以具名原因整体拒绝，不按位置猜测。所有对象与字段在发布前整体校验，失败不部分写入。

let PROTOTYPE_SESSION_SCHEMA: String = "cjgui.prototype-host.session.v2"
let PROTOTYPE_SESSION_PAYLOAD_VERSION: Int64 = 2

class PrototypeFieldIdentity {
    let id: String
    let kind: String

    init(id: String, kind: String) {
        this.id = id
        this.kind = kind
    }
}

class PrototypeObjectSnapshot {
    let key: String
    let drafts: HashMap<String, String>
    let applied: HashMap<String, String>
    let fieldVersions: HashMap<String, Int64>
    let draftVersion: Int64
    let appliedVersion: Int64

    init(key: String, drafts: HashMap<String, String>, applied: HashMap<String, String>,
        fieldVersions: HashMap<String, Int64>, draftVersion: Int64, appliedVersion: Int64) {
        this.key = key
        this.drafts = drafts
        this.applied = applied
        this.fieldVersions = fieldVersions
        this.draftVersion = draftVersion
        this.appliedVersion = appliedVersion
    }
}

class PrototypeSessionPayload {
    let objects: ArrayList<PrototypeObjectSnapshot>
    let declaration: ArrayList<PrototypeFieldIdentity>
    let selectedKey: String
    let query: String
    let columns: Int64
    let dark: Bool

    init(objects: ArrayList<PrototypeObjectSnapshot>, declaration: ArrayList<PrototypeFieldIdentity>,
        selectedKey: String, query: String, columns: Int64, dark: Bool) {
        this.objects = objects
        this.declaration = declaration
        this.selectedKey = selectedKey
        this.query = query
        this.columns = columns
        this.dark = dark
    }
}

class PrototypeSessionParse {
    let ok: Bool
    let reason: String
    let payload: ?PrototypeSessionPayload

    init(ok: Bool, reason: String, payload!: ?PrototypeSessionPayload = None) {
        this.ok = ok
        this.reason = reason
        this.payload = payload
    }

    static func refuse(reason: String): PrototypeSessionParse {
        return PrototypeSessionParse(false, reason)
    }

    static func accept(payload: PrototypeSessionPayload): PrototypeSessionParse {
        return PrototypeSessionParse(true, "none", payload: payload)
    }
}

func prototypeOpenWorkSession(project: PrototypeProject,
    validate: (String) -> Bool): CjguiComposableUiWorkSession {
    return CjguiComposableUiWorkSession(project.sessionPath, PROTOTYPE_SESSION_SCHEMA, 8 * 1024 * 1024, validate)
}

/// 会话载荷回写：只包含原型业务草稿/已应用值、字段身份与视图选择；
/// 不含窗口、endpoint、票据或界面结构（界面结构由 ui-document 单独保存）。
func prototypeSessionPayload(session: PrototypeSession): String {
    let builder = StringBuilder()
    builder.append("{\"schema\":\"${PROTOTYPE_SESSION_SCHEMA}\",")
    builder.append("\"payload_version\":${PROTOTYPE_SESSION_PAYLOAD_VERSION},")
    builder.append("\"project\":\"${prototypeJsonEscape(session.project.id)}\",")
    builder.append("\"declaration\":{\"fields\":[")
    var firstField = true
    for (field in session.project.fields) {
        if (!firstField) {
            builder.append(",")
        }
        firstField = false
        builder.append("{\"id\":\"${prototypeJsonEscape(field.id)}\",")
        builder.append("\"kind\":\"${prototypeJsonEscape(field.editorKind())}\"}")
    }
    builder.append("]},")
    builder.append("\"selected\":\"${prototypeJsonEscape(session.domain.selectedKey())}\",")
    builder.append("\"query\":\"${prototypeJsonEscape(session.domain.queryText())}\",")
    builder.append("\"columns\":${session.domain.columnCount()},")
    builder.append("\"dark\":")
    builder.append(if (session.dark) { "true" } else { "false" })
    builder.append(",\"objects\":[")
    var firstObject = true
    var index: Int64 = 0
    while (index < session.domain.objectCount()) {
        let object = session.domain.objectAt(index)
        if (!firstObject) {
            builder.append(",")
        }
        firstObject = false
        builder.append("{\"key\":\"${prototypeJsonEscape(object.key)}\",")
        builder.append("\"draft\":{")
        firstField = true
        for (fieldId in object.fieldIds()) {
            if (!firstField) {
                builder.append(",")
            }
            firstField = false
            builder.append("\"${prototypeJsonEscape(fieldId)}\":\"${prototypeJsonEscape(object.draftText(fieldId))}\"")
        }
        builder.append("},\"applied\":{")
        firstField = true
        for (fieldId in object.fieldIds()) {
            if (!firstField) {
                builder.append(",")
            }
            firstField = false
            builder.append("\"${prototypeJsonEscape(fieldId)}\":\"${prototypeJsonEscape(object.appliedText(fieldId))}\"")
        }
        builder.append("},\"fieldVersions\":{")
        firstField = true
        for (fieldId in object.fieldIds()) {
            if (!firstField) {
                builder.append(",")
            }
            firstField = false
            builder.append("\"${prototypeJsonEscape(fieldId)}\":${object.fieldVersion(fieldId)}")
        }
        builder.append("},\"draftVersion\":${object.draftVersionValue()},")
        builder.append("\"appliedVersion\":${object.appliedVersionValue()}}")
        index += 1
    }
    builder.append("]}")
    return builder.toString()
}

/// JSON 字符串转义。只替换 ASCII 控制/引号/反斜杠，**原样保留多字节 UTF-8**：
/// 逐字节做 String.fromUtf8 会把中文字符拆成非法单字节序列（曾导致保存会话崩溃）。
func prototypeJsonEscape(text: String): String {
    let bytes = text.toArray()
    let builder = StringBuilder()
    var start: Int64 = 0
    var index: Int64 = 0
    while (index < bytes.size) {
        let byte = bytes[index]
        var replacement = ""
        if (byte == 0x22u8) {
            replacement = "\\\""
        } else if (byte == 0x5Cu8) {
            replacement = "\\\\"
        } else if (byte == 0x0Au8) {
            replacement = "\\n"
        } else if (byte == 0x0Du8) {
            replacement = "\\r"
        } else if (byte == 0x09u8) {
            replacement = "\\t"
        }
        if (replacement.size > 0) {
            if (index > start) {
                builder.append(text[start..index])
            }
            builder.append(replacement)
            start = index + 1
        }
        index += 1
    }
    if (bytes.size > start) {
        builder.append(text[start..])
    }
    return builder.toString()
}

/// WorkSession 的结构级校验：只检查信封/版本/关键段形状，不判断与当前声明的对应。
/// 与当前项目声明的完整对应在 `prototypeParseSessionPayload(project, ...)` 中校验。
func prototypeValidateSessionPayload(text: String): Bool {
    if (text.size > 8 * 1024 * 1024) {
        return false
    }
    let parsed = try {
        PrototypeJsonParser.parse(text)
    } catch (_: Exception) {
        return false
    }
    if (prototypeFieldText(parsed, "schema") != PROTOTYPE_SESSION_SCHEMA) {
        return false
    }
    if (prototypeFieldIntOr(parsed, "payload_version", -1) != PROTOTYPE_SESSION_PAYLOAD_VERSION) {
        return false
    }
    if (parsed.field("declaration").isNone() || parsed.field("objects").isNone()) {
        return false
    }
    return true
}

private func prototypeStringMap(source: ?PrototypeJson): ?HashMap<String, String> {
    let json = match (source) {
        case Some(value) => value
        case None => return None
    }
    if (json.kind != PrototypeJson.KIND_OBJECT) {
        return None
    }
    let result = HashMap<String, String>()
    for (entry in json.entries) {
        let value = match (entry[1].asString()) {
            case Some(text) => text
            case None => return None
        }
        result.add(entry[0], value)
    }
    return Some(result)
}

private func prototypeLongMap(source: ?PrototypeJson): ?HashMap<String, Int64> {
    let json = match (source) {
        case Some(value) => value
        case None => return None
    }
    if (json.kind != PrototypeJson.KIND_OBJECT) {
        return None
    }
    let result = HashMap<String, Int64>()
    for (entry in json.entries) {
        let value = match (entry[1].asInteger()) {
            case Some(number) => number
            case None => return None
        }
        if (value < 0) {
            return None
        }
        result.add(entry[0], value)
    }
    return Some(result)
}

private func prototypeFieldSetMatches(project: PrototypeProject,
    declaration: ArrayList<PrototypeFieldIdentity>): String {
    if (declaration.size != project.fields.size) {
        return "session_declaration_mismatch:field_count"
    }
    let byId = HashMap<String, String>()
    for (field in declaration) {
        if (byId.contains(field.id)) {
            return "session_declaration_mismatch:duplicate:${field.id}"
        }
        byId.add(field.id, field.kind)
    }
    for (field in project.fields) {
        let declaredKind = match (byId.get(field.id)) {
            case Some(kind) => kind
            case None => return "session_declaration_mismatch:missing:${field.id}"
        }
        if (declaredKind != field.editorKind()) {
            return "session_declaration_mismatch:type:${field.id}"
        }
    }
    return ""
}

private func prototypeObjectKeys(domain: PrototypeProjectDomain): ArrayList<String> {
    let keys = ArrayList<String>()
    var index: Int64 = 0
    while (index < domain.objectCount()) {
        keys.add(domain.objectAt(index).key)
        index += 1
    }
    return keys
}

/// 完整解析并对照当前项目声明校验会话载荷。任何不匹配都返回具名原因；
/// 调用方只在 ok 时调用 `domain.restoreSessionState(payload)`，因此没有部分写入。
func prototypeParseSessionPayload(project: PrototypeProject, domain: PrototypeProjectDomain,
    text: String): PrototypeSessionParse {
    if (text.size > 8 * 1024 * 1024) {
        return PrototypeSessionParse.refuse("session_too_large")
    }
    let parsed = try {
        PrototypeJsonParser.parse(text)
    } catch (_: Exception) {
        return PrototypeSessionParse.refuse("session_invalid_json")
    }
    if (prototypeFieldText(parsed, "schema") != PROTOTYPE_SESSION_SCHEMA) {
        return PrototypeSessionParse.refuse("session_schema_unsupported")
    }
    let version = prototypeFieldIntOr(parsed, "payload_version", -1)
    if (version != PROTOTYPE_SESSION_PAYLOAD_VERSION) {
        // 旧版载荷没有字段身份，按位置猜测会错配；明确拒绝而不是兼容迁移。
        return PrototypeSessionParse.refuse("session_payload_version_unsupported:${version}")
    }
    if (prototypeFieldText(parsed, "project") != project.id) {
        return PrototypeSessionParse.refuse("session_project_mismatch")
    }
    let declarationJson = match (parsed.field("declaration")) {
        case Some(value) => value
        case None => return PrototypeSessionParse.refuse("session_declaration_missing")
    }
    let fieldsJson = match (declarationJson.field("fields")) {
        case Some(value) => value
        case None => return PrototypeSessionParse.refuse("session_declaration_missing")
    }
    let declaration = ArrayList<PrototypeFieldIdentity>()
    for (entry in fieldsJson.items) {
        let id = prototypeFieldText(entry, "id")
        let kind = prototypeFieldText(entry, "kind")
        if (id.size == 0 || kind.size == 0) {
            return PrototypeSessionParse.refuse("session_declaration_invalid")
        }
        declaration.add(PrototypeFieldIdentity(id, kind))
    }
    let declarationIssue = prototypeFieldSetMatches(project, declaration)
    if (declarationIssue.size > 0) {
        return PrototypeSessionParse.refuse(declarationIssue)
    }
    let objectsJson = match (parsed.field("objects")) {
        case Some(value) => value
        case None => return PrototypeSessionParse.refuse("session_objects_missing")
    }
    if (objectsJson.kind != PrototypeJson.KIND_ARRAY) {
        return PrototypeSessionParse.refuse("session_objects_invalid")
    }
    let expectedKeys = prototypeObjectKeys(domain)
    if (objectsJson.items.size != expectedKeys.size) {
        return PrototypeSessionParse.refuse("session_object_set_mismatch")
    }
    let payloads = ArrayList<PrototypeObjectSnapshot>()
    for (entry in objectsJson.items) {
        let key = prototypeFieldText(entry, "key")
        let drafts = match (prototypeStringMap(entry.field("draft"))) {
            case Some(value) => value
            case None => return PrototypeSessionParse.refuse("session_draft_invalid:${key}")
        }
        let applied = match (prototypeStringMap(entry.field("applied"))) {
            case Some(value) => value
            case None => return PrototypeSessionParse.refuse("session_applied_invalid:${key}")
        }
        let versions = match (prototypeLongMap(entry.field("fieldVersions"))) {
            case Some(value) => value
            case None => return PrototypeSessionParse.refuse("session_versions_invalid:${key}")
        }
        let draftVersion = prototypeFieldIntOr(entry, "draftVersion", -1)
        let appliedVersion = prototypeFieldIntOr(entry, "appliedVersion", -1)
        if (draftVersion < 0 || appliedVersion < 0 || appliedVersion > draftVersion) {
            return PrototypeSessionParse.refuse("session_versions_invalid:${key}")
        }
        if (drafts.size != project.fields.size || applied.size != project.fields.size ||
            versions.size != project.fields.size) {
            return PrototypeSessionParse.refuse("session_field_set_mismatch:${key}")
        }
        for (field in project.fields) {
            if (!drafts.contains(field.id) || !applied.contains(field.id) || !versions.contains(field.id)) {
                return PrototypeSessionParse.refuse("session_field_set_mismatch:${key}:${field.id}")
            }
            if ((versions.get(field.id) ?? 0) > draftVersion) {
                return PrototypeSessionParse.refuse("session_versions_invalid:${key}:${field.id}")
            }
        }
        payloads.add(PrototypeObjectSnapshot(key, drafts, applied, versions, draftVersion, appliedVersion))
    }
    return PrototypeSessionParse.accept(PrototypeSessionPayload(payloads, declaration,
        prototypeFieldText(parsed, "selected"), prototypeFieldText(parsed, "query"),
        prototypeFieldIntOr(parsed, "columns", 3), prototypeFieldBoolOr(parsed, "dark", false)))
}

/// 恢复会话：载荷已由 `prototypeParseSessionPayload` 完整校验，这里只做整体发布。
/// 任一对象内部校验失败时整体返回 false，调用方按“未恢复”处理（不宣称成功）。
func prototypeRestoreSessionPayload(domain: PrototypeProjectDomain, text: String,
    session: PrototypeSession): Bool {
    let parsed = prototypeParseSessionPayload(domain.project, domain, text)
    if (!parsed.ok) {
        return false
    }
    let payload = parsed.payload.getOrThrow()
    if (!domain.restoreSessionState(payload)) {
        return false
    }
    // 恢复选择也会更换详情 owner；与正常 SELECT_RECORD 复用同一换绑入口。
    session.binding.rebind()
    session.setDark(payload.dark)
    return true
}

/// 保留旧格式会话文件：只重命名、不覆盖已存在的备份、失败返回 false；
/// 原文件与内容都保留，不删除、不部分采用。
func prototypePreserveLegacySessionFile(sessionPath: String, backupPath: String): Bool {
    if (!exists(Path(sessionPath)) || exists(Path(backupPath))) {
        return false
    }
    try {
        rename(sessionPath, to: backupPath, overwrite: false)
        return exists(Path(backupPath))
    } catch (_: Exception) {
        return false
    }
}

func prototypeSessionRestoreReason(domain: PrototypeProjectDomain, text: String): String {
    return prototypeParseSessionPayload(domain.project, domain, text).reason
}

/// 界面文档操作结果的可读描述：拒绝原因原样带出，不把令牌/票据写进状态文本。
func prototypeDescribeSessionResult(result: CjguiUiDocumentSessionResult): String {
    let outcome = if (result.applied) { "applied" } else { "refused" }
    return "${outcome}:${result.reason}"
}
