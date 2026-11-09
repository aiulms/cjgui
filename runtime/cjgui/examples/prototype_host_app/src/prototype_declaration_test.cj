package cjgui_prototype_host

import cjgui.*
import std.collection.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

// 原型项目声明的针对性测试：只覆盖本阶段新增的解析/校验/会话载荷边界。
// 运行方式（应用构建后）：
//   cd .cjgui/macos-build/application && cjpm test --skip-script --filter '*prototype*'
// 这些用例不启动窗口、不写用户文件；全部在系统临时目录内。

func prototypeTestTempProject(declaration: String, dataFileName!: String = "", dataContent!: String = ""): String {
    let directory = Directory.createTemp("/tmp")
    let root = directory.toString()
    File.writeTo(Path("${root}/prototype.json"), declaration.toArray())
    if (dataFileName.size > 0) {
        let dataPath = Path("${root}/${dataFileName}")
        let parent = dataPath.parent
        if (!exists(parent)) {
            Directory.create(parent, recursive: false)
        }
        File.writeTo(dataPath, dataContent.toArray())
    }
    return root
}

@Test
func prototypeDeclarationParsesFieldsAndRecords(): Unit {
    let declaration = """
{
  "schema": "cjgui.prototype-project.v1",
  "id": "test-project",
  "title": "测试项目",
  "view": "list",
  "window": { "width": 1000, "height": 700, "minimumWidth": 720 },
  "groups": [ { "id": "g1", "title": "组一" } ],
  "fields": [
    { "id": "name", "label": "名称", "kind": "text", "required": true, "maximumLength": 40,
      "sourceField": "title", "value": "默认" },
    { "id": "count", "label": "数量", "kind": "integer", "minimum": 1, "maximum": 9,
      "sourceField": "quantity", "value": 3 },
    { "id": "enabled", "label": "启用", "kind": "boolean", "sourceField": "enabled", "value": true },
    { "id": "status", "label": "状态", "kind": "select", "sourceField": "status", "value": "b",
      "options": [ { "value": "a", "label": "甲" }, { "value": "b", "label": "乙" } ] }
  ],
  "records": { "file": "data/records.json", "titleField": "title" },
  "actions": [ { "name": "RESTORE_DEFAULTS", "label": "恢复默认" } ]
}
"""
    let data = """
{ "records": [ { "id": "r1", "title": "记录一", "quantity": 7, "enabled": false, "status": "a" },
               { "id": "r2", "title": "记录二", "quantity": 2, "enabled": true, "status": "b" } ] }
"""
    let root = prototypeTestTempProject(declaration, dataFileName: "data/records.json", dataContent: data)
    let project = PrototypeProjectLoader.load(root)
    @Assert(project.id, "test-project")
    @Assert(project.viewKind, "list")
    @Assert(project.fields.size, 4)
    @Assert(project.fields[3].isSelect(), true)
    @Assert(project.fields[3].optionValues.size, 2)
    @Assert(project.recordSet.records.size, 2)
    @Assert(project.recordSet.records[0].key, "r1")
    @Assert(project.hasRecords(), true)
    // 记录 owner 的初值必须来自数据文件的 sourceField 映射，而不是声明默认值。
    let domain = PrototypeProjectDomain(project)
    @Assert(domain.objectCount(), 2)
    @Assert(domain.objectAt(0).draftText("name"), "记录一")
    @Assert(domain.objectAt(0).draftText("count"), "7")
    @Assert(domain.objectAt(0).draftText("enabled"), "false")
    @Assert(domain.objectAt(0).draftText("status"), "a")
}

@Test
func prototypeDeclarationRejectsUnknownSchemaAndBadSelect(): Unit {
    let badSchema = "{\"schema\": \"other\", \"id\": \"x\", \"fields\": [ { \"id\": \"a\", \"label\": \"A\" } ] }"
    let root = prototypeTestTempProject(badSchema)
    var rejected = false
    try {
        let _ = PrototypeProjectLoader.load(root)
    } catch (error: Exception) {
        rejected = error.message.contains("unsupported_schema")
    }
    @Assert(rejected, true)

    let badSelect = """
{ "schema": "cjgui.prototype-project.v1", "id": "x",
  "fields": [ { "id": "s", "label": "S", "kind": "select" } ] }
"""
    let selectRoot = prototypeTestTempProject(badSelect)
    var selectRejected = false
    try {
        let _ = PrototypeProjectLoader.load(selectRoot)
    } catch (error: Exception) {
        selectRejected = error.message.contains("select_options_missing")
    }
    @Assert(selectRejected, true)
}

@Test
func prototypeSessionPayloadRoundTripsDraftWithoutApply(): Unit {
    let declaration = """
{ "schema": "cjgui.prototype-project.v1", "id": "round-trip", "title": "往返",
  "fields": [ { "id": "note", "label": "备注", "kind": "text", "value": "已应用" } ] }
"""
    let root = prototypeTestTempProject(declaration)
    let project = PrototypeProjectLoader.load(root)
    let domain = PrototypeProjectDomain(project)
    let (appliedOk, _) = domain.activeObject().applyDraft()
    @Assert(appliedOk, true)
    @Assert(domain.activeObject().setText("note", "草稿 \"引号\" \\ 反斜杠 换行\n结束"), true)

    let escaped = prototypeJsonEscape("草稿 \"引号\" \\ 反斜杠 换行\n结束")
    @Assert(escaped.contains("\\\""), true)
    @Assert(escaped.contains("\\\\"), true)
    @Assert(escaped.contains("\\n"), true)
    let parsed = PrototypeJsonParser.parse("{\"value\":\"${escaped}\"}")
    @Assert(prototypeFieldText(parsed, "value"), domain.activeObject().draftText("note"))
}

// ——— 会话载荷按字段 ID、声明扩展（白名单修复的针对性反例） ———

private func prototypeTestWriteDeclaration(root: String, declaration: String): Unit {
    File.writeTo(Path("${root}/prototype.json"), declaration.toArray())
}

private func prototypeTestFieldsJson(orderedIds: ArrayList<String>): String {
    // 同一批字段（id/kind 固定）按给定顺序生成声明；用于“同数量字段重排”反例。
    let values = HashMap<String, String>()
    values.add("alpha", "{\"id\":\"alpha\",\"label\":\"甲\",\"kind\":\"text\",\"value\":\"a0\"}")
    values.add("beta", "{\"id\":\"beta\",\"label\":\"乙\",\"kind\":\"integer\",\"minimum\":1,\"maximum\":9,\"value\":2}")
    values.add("gamma", "{\"id\":\"gamma\",\"label\":\"丙\",\"kind\":\"boolean\",\"value\":true}")
    var result = ""
    var first = true
    for (id in orderedIds) {
        if (!first) {
            result += ","
        }
        first = false
        result += values.get(id).getOrThrow()
    }
    return result
}

private func prototypeTestFormDeclaration(orderedIds: ArrayList<String>, extra!: String = ""): String {
    return "{\"schema\":\"cjgui.prototype-project.v1\",\"id\":\"session-project\",\"title\":\"会话测试\"," +
        "\"fields\":[" + prototypeTestFieldsJson(orderedIds) + (if (extra.size > 0) { "," + extra } else { "" }) +
        "]}"
}

@Test
func prototypeSessionPayloadMatchesFieldsByIdAcrossReorder(): Unit {
    let firstRoot = prototypeTestTempProject(
        prototypeTestFormDeclaration(ArrayList<String>(["alpha", "beta", "gamma"])))
    let firstProject = PrototypeProjectLoader.load(firstRoot)
    let firstSession = PrototypeSession(firstProject, false)
    @Assert(firstSession.domain.activeObject().setText("alpha", "用户输入"), true)
    @Assert(firstSession.domain.activeObject().setText("beta", "7"), true)
    let payload = prototypeSessionPayload(firstSession)

    // 同一批字段、不同声明顺序：对应关系必须按字段 ID，而不是数组下标。
    let secondRoot = prototypeTestTempProject(
        prototypeTestFormDeclaration(ArrayList<String>(["gamma", "alpha", "beta"])))
    let secondProject = PrototypeProjectLoader.load(secondRoot)
    let secondSession = PrototypeSession(secondProject, false)
    @Assert(prototypeRestoreSessionPayload(secondSession.domain, payload, secondSession), true)
    @Assert(secondSession.domain.activeObject().draftText("alpha"), "用户输入")
    @Assert(secondSession.domain.activeObject().draftText("beta"), "7")
    @Assert(secondSession.domain.activeObject().draftText("gamma"), "true")
    @Assert(secondSession.domain.activeObject().appliedText("alpha"), "a0")
}

@Test
func prototypeSessionPayloadRejectsAddedFieldWithoutPartialRestore(): Unit {
    let firstRoot = prototypeTestTempProject(
        prototypeTestFormDeclaration(ArrayList<String>(["alpha", "beta"])))
    let firstSession = PrototypeSession(PrototypeProjectLoader.load(firstRoot), false)
    @Assert(firstSession.domain.activeObject().setText("alpha", "旧会话值"), true)
    let payload = prototypeSessionPayload(firstSession)

    // 当前声明多出一个字段：旧载荷缺字段身份，不能按位置猜，必须整体拒绝。
    let extra = "{\"id\":\"delta\",\"label\":\"丁\",\"kind\":\"text\",\"value\":\"d0\"}"
    let secondRoot = prototypeTestTempProject(
        prototypeTestFormDeclaration(ArrayList<String>(["alpha", "beta"]), extra: extra))
    let secondSession = PrototypeSession(PrototypeProjectLoader.load(secondRoot), false)
    @Assert(prototypeSessionRestorePayloadReason(secondSession.domain, payload)
        .contains("session_declaration_mismatch"), true)
    @Assert(prototypeRestoreSessionPayload(secondSession.domain, payload, secondSession), false)
    // 失败不部分写入：默认值仍在，没有被旧载荷覆盖。
    @Assert(secondSession.domain.activeObject().draftText("alpha"), "a0")
}

private func prototypeSessionRestorePayloadReason(domain: PrototypeProjectDomain, payload: String): String {
    return prototypeSessionRestoreReason(domain, payload)
}

@Test
func prototypeSessionPayloadRejectsObjectMissingOneField(): Unit {
    let root = prototypeTestTempProject(
        prototypeTestFormDeclaration(ArrayList<String>(["alpha", "beta"])))
    let session = PrototypeSession(PrototypeProjectLoader.load(root), false)
    @Assert(session.domain.activeObject().setText("alpha", "保持"), true)
    let before = session.domain.activeObject().draftText("alpha")
    // 手工构造一个“少一个字段”的对象载荷：完整校验必须拒绝，且不改动 owner。
    let truncated = "{\"schema\":\"${PROTOTYPE_SESSION_SCHEMA}\",\"payload_version\":2," +
        "\"project\":\"session-project\",\"declaration\":{\"fields\":[" +
        "{\"id\":\"alpha\",\"kind\":\"TEXT\"},{\"id\":\"beta\",\"kind\":\"INTEGER\"}]}," +
        "\"objects\":[{\"key\":\"active\",\"draft\":{\"alpha\":\"x\"}," +
        "\"applied\":{\"alpha\":\"y\"},\"fieldVersions\":{},\"draftVersion\":0,\"appliedVersion\":0}]}"
    @Assert(prototypeRestoreSessionPayload(session.domain, truncated, session), false)
    @Assert(session.domain.activeObject().draftText("alpha"), before)
}

@Test
func prototypeAdoptDeclarationAddsFieldToOwnerCatalogAndBinding(): Unit {
    let root = prototypeTestTempProject(
        prototypeTestFormDeclaration(ArrayList<String>(["alpha", "beta"])))
    let session = PrototypeSession(PrototypeProjectLoader.load(root), false)
    @Assert(session.domain.activeObject().setText("alpha", "保留草稿"), true)
    let extra = "{\"id\":\"delta\",\"label\":\"丁\",\"kind\":\"text\",\"value\":\"新默认\"}"
    prototypeTestWriteDeclaration(root,
        prototypeTestFormDeclaration(ArrayList<String>(["alpha", "beta"]), extra: extra))
    let updated = PrototypeProjectLoader.load(root)
    let outcome = session.adoptDeclaration(updated)
    @Assert(outcome, "declaration_updated:1")
    @Assert(session.domain.project.fields.size, 3)
    // 同 id 字段草稿保留；新字段按声明默认值初始化。
    @Assert(session.domain.activeObject().draftText("alpha"), "保留草稿")
    @Assert(session.domain.activeObject().draftText("delta"), "新默认")
    // 能力目录发布新字段；表单绑定能解析它（模型可发现并生成节点）。
    @Assert(session.catalog.fieldFor("delta").isSome(), true)
    session.binding.rebind()
    @Assert(session.binding.fieldResourceId("delta") > 0, true)
    @Assert(session.binding.draftText("delta"), "新默认")
}

@Test
func prototypeAdoptDeclarationRejectsExistingFieldRuleChange(): Unit {
    let root = prototypeTestTempProject(
        prototypeTestFormDeclaration(ArrayList<String>(["alpha", "beta"])))
    let session = PrototypeSession(PrototypeProjectLoader.load(root), false)
    let changed = "{\"schema\":\"cjgui.prototype-project.v1\",\"id\":\"session-project\"," +
        "\"title\":\"会话测试\",\"fields\":[" +
        "{\"id\":\"alpha\",\"label\":\"改过的标签\",\"kind\":\"text\",\"value\":\"a0\"}," +
        "{\"id\":\"beta\",\"label\":\"乙\",\"kind\":\"integer\",\"minimum\":1,\"maximum\":9,\"value\":2}]}"
    prototypeTestWriteDeclaration(root, changed)
    let updated = PrototypeProjectLoader.load(root)
    let outcome = session.adoptDeclaration(updated)
    @Assert(outcome.contains("existing_field_rule_change_unsupported"), true)
    @Assert(session.domain.project.fields.size, 2)
    @Assert(session.catalog.fieldFor("alpha").isSome(), true)
}

// ——— R2/R3 的针对性反例 ———

@Test
func prototypeDomainProtectsDraftsOnNonActiveRecords(): Unit {
    let data = """
{ "records": [ { "id": "r1", "title": "记录一", "quantity": 7, "enabled": false, "status": "a" },
               { "id": "r2", "title": "记录二", "quantity": 2, "enabled": true, "status": "b" } ] }
"""
    let declaration = """
{ "schema": "cjgui.prototype-project.v1", "id": "dirty-project", "title": "脏草稿",
  "view": "list",
  "fields": [ { "id": "name", "label": "名称", "kind": "text", "sourceField": "title", "value": "" } ],
  "records": { "file": "data/records.json", "titleField": "title" } }
"""
    let root = prototypeTestTempProject(declaration, dataFileName: "data/records.json", dataContent: data)
    let project = PrototypeProjectLoader.load(root)
    let domain = PrototypeProjectDomain(project)
    @Assert(domain.hasAnyDraftChanges(), false)
    @Assert(domain.objectAt(0).setText("name", "记录一的草稿"), true)
    // Select the clean second record: the active object is clean, but the
    // project still holds an unsaved draft and must be protected.
    @Assert(domain.selectRecordIndex(1), true)
    @Assert(domain.activeObject().isDirty(), false)
    @Assert(domain.hasAnyDraftChanges(), true)
}

@Test
func prototypeAdoptDeclarationRejectsActionChangesWithoutPartialPublish(): Unit {
    let declaration = """
{ "schema": "cjgui.prototype-project.v1", "id": "atomic-project", "title": "原子",
  "fields": [ { "id": "alpha", "label": "甲", "kind": "text", "value": "a0" } ],
  "actions": [ { "name": "RESTORE_DEFAULTS", "label": "恢复默认" } ] }
"""
    let root = prototypeTestTempProject(declaration)
    let session = PrototypeSession(PrototypeProjectLoader.load(root), false)
    @Assert(session.domain.activeObject().setText("alpha", "保留的草稿"), true)
    @Assert(session.catalog.fieldFor("alpha").isSome(), true)
    @Assert(session.catalog.actionFor("RESTORE_DEFAULTS").isSome(), true)
    // RED counterexample: one new field + two same-name new actions. The old
    // code registered the field first and only failed on the second action,
    // leaving the catalog and the owner disagreeing.
    let updated = """
{ "schema": "cjgui.prototype-project.v1", "id": "atomic-project", "title": "原子",
  "fields": [ { "id": "alpha", "label": "甲", "kind": "text", "value": "a0" },
              { "id": "delta", "label": "丁", "kind": "text", "value": "d0" } ],
  "actions": [ { "name": "RESTORE_DEFAULTS", "label": "恢复默认" },
               { "name": "NEW_ACTION", "label": "新动作" },
               { "name": "NEW_ACTION", "label": "新动作" } ] }
"""
    prototypeTestWriteDeclaration(root, updated)
    let reloaded = PrototypeProjectLoader.load(root)
    let outcome = session.adoptDeclaration(reloaded)
    @Assert(outcome, "action_change_requires_project_switch")
    // No partial publish: fields/actions/owner/draft all unchanged.
    @Assert(session.catalog.fieldFor("delta").isNone(), true)
    @Assert(session.catalog.actionFor("NEW_ACTION").isNone(), true)
    @Assert(session.catalog.fieldFor("alpha").isSome(), true)
    @Assert(session.domain.project.fields.size, 1)
    @Assert(session.domain.activeObject().draftText("alpha"), "保留的草稿")
}
