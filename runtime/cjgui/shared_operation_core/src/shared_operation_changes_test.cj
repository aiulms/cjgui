package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private class ChangeProbeDomain <: CjguiSharedOperationDomain & CjguiSharedOperationChangeDomain {
    public func resourceType(): String { return "change_probe" }
    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        return CjguiSharedOperationContextSnapshot(1, "变化测试", resourceType(), ArrayList<CjguiSharedOperationResource>([
            CjguiSharedOperationResource(901, "目标", ArrayList<CjguiSharedOperationField>([
                CjguiSharedOperationField("title", CjguiSharedOperationValue.string("已更新"))
            ]))
        ]))
    }
    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> { return ArrayList<CjguiSharedOperationActionDescriptor>() }
    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult { return CjguiSharedOperationActionResult(false, false, 1, 1, "not_supported") }
    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult { return CjguiSharedOperationActionResult(false, false, 1, 1, "not_supported") }
    public func changesSince(sinceVersion: Int64, resourceFilter: ArrayList<Int64>, expectedStreamIdentity: String): CjguiSharedOperationChanges {
        if (expectedStreamIdentity.size > 0 && expectedStreamIdentity != "probe_stream_1") {
            return CjguiSharedOperationChanges(sinceVersion, 1, "probe_stream_1", true, ArrayList<CjguiSharedOperationChangeEntry>())
        }
        let entries = ArrayList<CjguiSharedOperationChangeEntry>()
        if (sinceVersion == 0 && (resourceFilter.size == 0 || resourceFilter[0] == 901)) {
            entries.add(CjguiSharedOperationChangeEntry(1, 901, "updated"))
        }
        return CjguiSharedOperationChanges(sinceVersion, 1, "probe_stream_1", false, entries)
    }
}

@Test
func transportReturnsBoundedAuthorizedChangesAndRequiresResyncExplicitly(): Unit {
    let domain = ChangeProbeDomain()
    let authorization = CjguiSharedOperationExternalAuthorization("变化读取者", "changes-capability", ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([901]), false),
        CjguiSharedOperationExternalActionScope("GET_CHANGES", ArrayList<Int64>([901]), false)
    ]))
    let connection = CjguiSharedOperationExternalConnection(domain, authorization, domain)
    let response = connection.dispatchPayload("PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH changes-capability\nGET_CHANGES 0 1\nID 901")
    @Assert(response.contains("KIND CHANGES"), true)
    @Assert(response.contains("STREAM_ID probe_stream_1"), true)
    @Assert(response.contains("SINCE_VERSION 0"), true)
    @Assert(response.contains("CURRENT_VERSION 1"), true)
    @Assert(response.contains("RESYNC_REQUIRED false"), true)
    @Assert(response.contains("CHANGE 1 901 updated"), true)

    let denied = connection.dispatchPayload("PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH changes-capability\nGET_CHANGES 0 1\nID 902")
    @Assert(denied.contains("ERROR unauthorized_resource"), true)
}

@Test
func changeCursorWithAnotherDocumentIdentityRequiresResyncRatherThanEmptyChanges(): Unit {
    let domain = ChangeProbeDomain()
    let authorization = CjguiSharedOperationExternalAuthorization("变化读取者", "changes-capability", ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>([901]), false),
        CjguiSharedOperationExternalActionScope("GET_CHANGES", ArrayList<Int64>([901]), false)
    ]))
    let connection = CjguiSharedOperationExternalConnection(domain, authorization, domain)
    let stale = connection.dispatchPayload("PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH changes-capability\nGET_CHANGES 1 another_document 1\nID 901")
    @Assert(stale.contains("KIND CHANGES"), true)
    @Assert(stale.contains("RESYNC_REQUIRED true"), true)
}
