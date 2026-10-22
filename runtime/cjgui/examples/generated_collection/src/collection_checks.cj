package cjgui_generated_collection

import cjgui.*
import cjgui_rule_set_application.*
import std.collection.*

func collectionSpec(presentation: String, reference!: String = "rules", kind!: String = "ruleCollection"): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("collection", reference);
    properties.add("presentation", presentation)
    properties.add("fixedHeight", "360");
    properties.add("growX", "1")
    return CjguiGeneratedUiNodeSpec("records", kind, properties: properties)
}

func checkCollection(controller: CollectionController): Int64 {
    let collection = controller.collection
    let domain = controller.domain
    let originalId = domain.selectedRecordId()
    let edited = domain.editSelectedLabelFromHuman("保留草稿😀", 6, 6)
    if (!edited.applied || controller.rows.itemCount() != 80) {
        return 10
    }
    let draft = domain.formSnapshot()
    let selection = collection.selection.snapshot(0)
    let validator = CjguiGeneratedUiValidator(controller.catalog)
    if (!validator.validate(collectionSpec("list")).accepted || validator
        .validate(collectionSpec("table", reference: "unregistered"))
        .accepted || validator.validate(collectionSpec("grid")).accepted || validator
        .validate(collectionSpec("list", kind: "unregisteredCollection"))
        .accepted) {
        return 11
    }
    let holder = CjguiGeneratedUiStructureHolder(controller.catalog,
        rootScope: CjguiComposableUiIdentityScope("collection-checks"))
    if (!holder.submit(collectionSpec("list"), controller.binding).candidateAccepted || !holder.beginCandidateRefresh()) {
        return 12
    }
    let first = holder.buildRefreshNode(controller.binding)
    if (first.children().size != 1 || controller.rows.built != 0 || !holder.prepareCandidateRefresh() ||
        !holder.commitCandidateRefresh()) {
        return 13
    }
    let viewportId = first.nodeId
    let version = holder.structureVersion()
    // A table projection can be built and rolled back without touching source,
    // logical selection, query, sort, applied values or the existing draft.
    let _ = collection.table.setQuery("规则")
    let _ = collection.table.setSort("id")
    let viewBefore = "${collection.table.query()}/${collection.table.sortColumnKey()}/${collection.table.sortAscending()}"
    if (!holder.submit(collectionSpec("table"), controller.binding).candidateAccepted || !holder.beginCandidateRefresh()) {
        return 14
    }
    let tableNode = holder.buildRefreshNode(controller.binding)
    if (tableNode.nodeId != viewportId || controller.rows.built != 0) {
        return 15
    }
    holder.rollbackCandidateRefresh()
    if (holder.structureVersion() != version || domain.selectedRecordId() != originalId ||
        domain.formSnapshot().draftVersion != draft.draftVersion || collection.selection.focus() != selection.focus ||
        collection.selection.selectionVersion() != selection.selectionVersion ||
        "${collection.table.query()}/${collection.table.sortColumnKey()}/${collection.table.sortAscending()}" !=
        viewBefore) {
        return 16
    }
    if (holder.submit(collectionSpec("table", reference: "unregistered"), controller.binding).candidateAccepted ||
        holder.structureVersion() != version) {
        return 17
    }
    if (!holder.submit(collectionSpec("table"), controller.binding).candidateAccepted || !holder.beginCandidateRefresh()) {
        return 18
    }
    let switched = holder.buildRefreshNode(controller.binding)
    if (switched.nodeId != viewportId || !holder.prepareCandidateRefresh() || !holder.commitCandidateRefresh()) {
        return 19
    }
    // Same declared key, another registered collection: its actual selection
    // and viewport come from that declaration, never the previous instance.
    let otherSelection = CjguiComposableUiCollectionSelection()
    let other = CjguiGeneratedUiCollection("other", "otherCollection", controller.rows, collection.table, otherSelection)
    if (!other.register(controller.catalog) ||
        !holder
        .submit(collectionSpec("list", reference: "other", kind: "otherCollection"), controller.binding)
        .candidateAccepted || !holder.beginCandidateRefresh()) {
        return 20
    }
    let rebound = holder.buildRefreshNode(controller.binding)
    if (otherSelection.selectedCount() != 0 || refEq(rebound.scrollViewport.getOrThrow(), collection.viewport) ||
        collection.selection.focus() != selection.focus) {
        return 21
    }
    holder.rollbackCandidateRefresh()
    if (domain.formSnapshot().fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText !=
        "保留草稿😀" || controller.rows.built != 0) {
        return 22
    }
    println(
        "COLLECTION_CHECKS_OK registered_reference rejection_retains_old rollback_no_owner_write stable_key_switch rebind_selection lazy_zero_rows")
    return 0
}
