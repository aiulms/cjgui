package cjgui_shared_document_second_consumer

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*

private let PRIMARY_DOCUMENT_ID: Int64 = 8101
private let SECONDARY_DOCUMENT_ID: Int64 = 8102
private let READ_ONLY_ARCHIVE_ID: Int64 = 8199

private func documents(): ArrayList<CjguiTextDocument> {
    return ArrayList<CjguiTextDocument>([
        CjguiTextDocument(PRIMARY_DOCUMENT_ID, "北区交接文档", "第一行：在场值班员\n第二行：等待复核🙂"),
        CjguiTextDocument(SECONDARY_DOCUMENT_ID, "南区复盘笔记", "这是独立无界面消费者创建的第二份文档。"),
        CjguiTextDocument(READ_ONLY_ARCHIVE_ID, "只读归档诱饵", "可发现，不授予远程内容读取或替换。")
    ])
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    let contentTargets = ArrayList<Int64>([PRIMARY_DOCUMENT_ID, SECONDARY_DOCUMENT_ID])
    return CjguiSharedOperationExternalAuthorization(
        "共享文档第二消费者 Agent",
        "cjgui-shared-document-second-consumer-20260912",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("GET_CHANGES", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("READ_RANGE", contentTargets, false),
            CjguiSharedOperationExternalActionScope("SELECT_DOCUMENT", ArrayList<Int64>(), true),
            CjguiSharedOperationExternalActionScope("INSERT_TEXT", contentTargets, false),
            CjguiSharedOperationExternalActionScope("DELETE_RANGE", contentTargets, false),
            CjguiSharedOperationExternalActionScope("REPLACE_RANGE", contentTargets, false)
        ])
    )
}

private func maxClientsFromArguments(args: Array<String>): ?Int64 {
    if (args.size == 0) { return Some(-1) }
    if (args.size != 2 || args[0] != "--max-clients") { return None }
    if (let Some(value) <- Int64.tryParse(args[1])) {
        if (value > 0 && value <= 1024) { return Some(value) }
    }
    return None
}

private func usage(): Int64 {
    let error = getStdErr()
    error.writeln("usage: main [--max-clients POSITIVE_COUNT]")
    error.writeln("discover the private endpoint and capability from the emitted descriptor; do not reconstruct either")
    error.flush()
    return 2
}

private func run(maxClients: Int64): Int64 {
    let workspace = CjguiTextDocumentWorkspace(documents())
    let connection = CjguiSharedOperationExternalConnection(workspace, authorization(), workspace)
    if (!connection.enableRangeReads(workspace) || !connection.start()) {
        getStdErr().writeln("shared document second consumer: external connection start failed")
        connection.close()
        return 1
    }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_SHARED_DOCUMENT_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("CJGUI_SHARED_DOCUMENT_READY PROTOCOL ${info.protocol}")
        output.writeln("CJGUI_SHARED_DOCUMENT_READY ACTION_COUNT ${info.actions.size}")
        output.flush()
    } else {
        getStdErr().writeln("shared document second consumer: descriptor unavailable")
        connection.close()
        return 1
    }
    var served: Int64 = 0
    while (maxClients < 0 || served < maxClients) {
        if (connection.pump(50u32)) { served += 1 }
    }
    connection.close()
    return 0
}

main(args: Array<String>): Int64 {
    if (let Some(maxClients) <- maxClientsFromArguments(args)) { return run(maxClients) }
    return usage()
}
