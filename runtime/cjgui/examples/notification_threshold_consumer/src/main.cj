package cjgui_notification_threshold_consumer

import cjgui_shared_operation_core.*
import cjgui_notification_threshold_application.*
import std.collection.*
import std.convert.*
import std.env.*

private let capabilityVariable = "CJGUI_NOTIFICATION_CONSUMER_CAPABILITY"
private func authorization(capability: String): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization("通知阈值独立消费者", capability, ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
        CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
        CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", all, true),
        CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", all, true),
        CjguiSharedOperationExternalActionScope("APPLY_DRAFT", all, true),
        CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", all, true),
        CjguiSharedOperationExternalActionScope("CONFIGURE_NOTIFICATION_THRESHOLD", all, true)
    ]))
}

private func maxClients(args: Array<String>): ?Int64 {
    if (args.size == 2 && args[0] == "--max-clients") {
        if (let Some(value) <- Int64.tryParse(args[1])) { if (value > 0 && value <= 64) { return Some(value) } }
    }
    return None
}

main(args: Array<String>): Int64 {
    if (let Some(limit) <- maxClients(args)) {
        if (let Some(capability) <- getVariable(capabilityVariable)) {
            if (capability.size > 0) {
                let domain = CjguiNotificationThresholdDomain()
                let connection = CjguiSharedOperationExternalConnection(domain, authorization(capability), domain)
                if (!connection.start()) { return 1 }
                if (let Some(info) <- connection.connectionInfo()) { getStdOut().writeln(info.descriptorPath); getStdOut().flush() } else { connection.close(); return 1 }
                var served: Int64 = 0
                while (served < limit) { if (connection.pump(50u32)) { served += 1 } }
                connection.close(); return 0
            }
        }
    }
    getStdErr().writeln("usage: set ${capabilityVariable}, then main --max-clients POSITIVE_COUNT")
    return 2
}
