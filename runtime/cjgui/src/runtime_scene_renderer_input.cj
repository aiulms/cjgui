package cjgui

// Internal Scene / Renderer Input owner:
// - 本文件不消费 Queue / Action / Runtime lower-level mutable facts。
// - Truth 是 semantic scene snapshot 到 dehydrated display list / renderer input packet 的内部 value facts。
// - Stop-line: 这里只定义 backend-agnostic input contract，不接平台后端、平台对象、原生句柄或原始指针；
//   不做真实渲染、不实现上层 UI / 排版 / 文本输入 / 辅助系统、不做增量渲染，也不回塞 critical runtime_state.cj。

// Scene version 是 semantic scene 与 display list 的 value 版本标记；
// 它不是 runtime global state，也不是 renderer backend 的同步计数器。
struct CjguiInternalSceneVersion {
    let value: Int64

    init(value: Int64) {
        this.value = value
    }
}

// Render node id 是未来 stable id 的占位 value；
// 它只服务 scene / display list contract，不实现实体组件系统分配器。
struct CjguiInternalRenderNodeId {
    let value: Int64
    let isStablePlaceholder: Bool

    init(value: Int64, isStablePlaceholder: Bool) {
        this.value = value
        this.isStablePlaceholder = isStablePlaceholder
    }
}

// Render bounds 是 renderer input 的几何 facts；
// 当前只保留坐标与尺寸，不做 layout 或 hit-test 实现。
struct CjguiInternalRenderBounds {
    let x: Int64
    let y: Int64
    let width: Int64
    let height: Int64
    let didReserveStableBounds: Bool

    init(x: Int64, y: Int64, width: Int64, height: Int64, didReserveStableBounds: Bool) {
        this.x = x
        this.y = y
        this.width = width
        this.height = height
        this.didReserveStableBounds = didReserveStableBounds
    }
}

// Render clip 只描述 display list 可携带的裁剪 facts；
// 它不是平台 clip object，也不执行任何绘制裁剪。
struct CjguiInternalRenderClip {
    let bounds: CjguiInternalRenderBounds
    let isClipEnabled: Bool
    let didReserveClipFacts: Bool

    init(bounds: CjguiInternalRenderBounds, isClipEnabled: Bool, didReserveClipFacts: Bool) {
        this.bounds = bounds
        this.isClipEnabled = isClipEnabled
        this.didReserveClipFacts = didReserveClipFacts
    }
}

// Material key 是 backend-agnostic 的材质占位 facts；
// 它不创建图形设备资源，也不绑定任何平台资源。
struct CjguiInternalRenderMaterialKey {
    let value: Int64
    let didReserveMaterialFacts: Bool

    init(value: Int64, didReserveMaterialFacts: Bool) {
        this.value = value
        this.didReserveMaterialFacts = didReserveMaterialFacts
    }
}

// Invalidation hint 只预留未来重绘提示；
// P1 固定 full rebuild，不实现局部脏区或增量更新。
struct CjguiInternalRenderInvalidationHint {
    let requiresFullDisplayListRebuild: Bool
    let allowsIncrementalRebuild: Bool
    let allowsDisplayListMutation: Bool
    let allowsPartialRepaint: Bool
    let didReserveRepaintHint: Bool

    init(
        requiresFullDisplayListRebuild: Bool,
        allowsIncrementalRebuild: Bool,
        allowsDisplayListMutation: Bool,
        allowsPartialRepaint: Bool,
        didReserveRepaintHint: Bool
    ) {
        this.requiresFullDisplayListRebuild = requiresFullDisplayListRebuild
        this.allowsIncrementalRebuild = allowsIncrementalRebuild
        this.allowsDisplayListMutation = allowsDisplayListMutation
        this.allowsPartialRepaint = allowsPartialRepaint
        this.didReserveRepaintHint = didReserveRepaintHint
    }
}

// Scene snapshot 是上游 semantic layer 的最小 value；
// 它保留语义层占位与层级根节点，不直接读取 queue / action / runtime mutable facts。
struct CjguiInternalSceneSnapshot {
    let version: CjguiInternalSceneVersion
    let rootNodeId: CjguiInternalRenderNodeId
    let bounds: CjguiInternalRenderBounds
    let clip: CjguiInternalRenderClip
    let materialKey: CjguiInternalRenderMaterialKey
    let invalidationHint: CjguiInternalRenderInvalidationHint
    let didPrepareSceneSnapshot: Bool
    let didUseMinimalDefaultSceneInput: Bool
    let didReserveSemanticSceneHints: Bool
    let shouldDeferSceneSnapshot: Bool
    let shouldReportSceneSnapshotBlocked: Bool

    init(
        version: CjguiInternalSceneVersion,
        rootNodeId: CjguiInternalRenderNodeId,
        bounds: CjguiInternalRenderBounds,
        clip: CjguiInternalRenderClip,
        materialKey: CjguiInternalRenderMaterialKey,
        invalidationHint: CjguiInternalRenderInvalidationHint,
        didPrepareSceneSnapshot: Bool,
        didUseMinimalDefaultSceneInput: Bool,
        didReserveSemanticSceneHints: Bool,
        shouldDeferSceneSnapshot: Bool,
        shouldReportSceneSnapshotBlocked: Bool
    ) {
        this.version = version
        this.rootNodeId = rootNodeId
        this.bounds = bounds
        this.clip = clip
        this.materialKey = materialKey
        this.invalidationHint = invalidationHint
        this.didPrepareSceneSnapshot = didPrepareSceneSnapshot
        this.didUseMinimalDefaultSceneInput = didUseMinimalDefaultSceneInput
        this.didReserveSemanticSceneHints = didReserveSemanticSceneHints
        this.shouldDeferSceneSnapshot = shouldDeferSceneSnapshot
        this.shouldReportSceneSnapshotBlocked = shouldReportSceneSnapshotBlocked
    }
}

// Render node 是 semantic scene 到 flat display list 之间的 value projection；
// 它保留 stable id / bounds / clip / z-order / material key，不实现上层 UI 模型。
struct CjguiInternalRenderNode {
    let sceneSnapshot: CjguiInternalSceneSnapshot
    let nodeId: CjguiInternalRenderNodeId
    let bounds: CjguiInternalRenderBounds
    let clip: CjguiInternalRenderClip
    let zOrder: Int64
    let materialKey: CjguiInternalRenderMaterialKey
    let invalidationHint: CjguiInternalRenderInvalidationHint
    let didPrepareRenderNode: Bool
    let didPreserveSceneSnapshot: Bool
    let shouldDeferRenderNode: Bool
    let shouldReportRenderNodeBlocked: Bool

    init(
        sceneSnapshot: CjguiInternalSceneSnapshot,
        nodeId: CjguiInternalRenderNodeId,
        bounds: CjguiInternalRenderBounds,
        clip: CjguiInternalRenderClip,
        zOrder: Int64,
        materialKey: CjguiInternalRenderMaterialKey,
        invalidationHint: CjguiInternalRenderInvalidationHint,
        didPrepareRenderNode: Bool,
        didPreserveSceneSnapshot: Bool,
        shouldDeferRenderNode: Bool,
        shouldReportRenderNodeBlocked: Bool
    ) {
        this.sceneSnapshot = sceneSnapshot
        this.nodeId = nodeId
        this.bounds = bounds
        this.clip = clip
        this.zOrder = zOrder
        this.materialKey = materialKey
        this.invalidationHint = invalidationHint
        this.didPrepareRenderNode = didPrepareRenderNode
        this.didPreserveSceneSnapshot = didPreserveSceneSnapshot
        this.shouldDeferRenderNode = shouldDeferRenderNode
        this.shouldReportRenderNodeBlocked = shouldReportRenderNodeBlocked
    }
}

// Display list 是 dehydrated / flat / backend-agnostic 的 renderer input value；
// P1 只表达 full rebuild 结果，不做局部脏区或增量更新。
struct CjguiInternalRenderDisplayList {
    let sceneSnapshot: CjguiInternalSceneSnapshot
    let rootNode: CjguiInternalRenderNode
    let displayListVersion: CjguiInternalSceneVersion
    let didPrepareRenderDisplayList: Bool
    let didUseFullDisplayListRebuild: Bool
    let didAvoidIncrementalRebuild: Bool
    let didAvoidDisplayListMutation: Bool
    let didAvoidPartialRepaint: Bool
    let shouldDeferRenderDisplayList: Bool
    let shouldReportRenderDisplayListBlocked: Bool
    let didPreserveRenderNode: Bool

    init(
        sceneSnapshot: CjguiInternalSceneSnapshot,
        rootNode: CjguiInternalRenderNode,
        displayListVersion: CjguiInternalSceneVersion,
        didPrepareRenderDisplayList: Bool,
        didUseFullDisplayListRebuild: Bool,
        didAvoidIncrementalRebuild: Bool,
        didAvoidDisplayListMutation: Bool,
        didAvoidPartialRepaint: Bool,
        shouldDeferRenderDisplayList: Bool,
        shouldReportRenderDisplayListBlocked: Bool,
        didPreserveRenderNode: Bool
    ) {
        this.sceneSnapshot = sceneSnapshot
        this.rootNode = rootNode
        this.displayListVersion = displayListVersion
        this.didPrepareRenderDisplayList = didPrepareRenderDisplayList
        this.didUseFullDisplayListRebuild = didUseFullDisplayListRebuild
        this.didAvoidIncrementalRebuild = didAvoidIncrementalRebuild
        this.didAvoidDisplayListMutation = didAvoidDisplayListMutation
        this.didAvoidPartialRepaint = didAvoidPartialRepaint
        this.shouldDeferRenderDisplayList = shouldDeferRenderDisplayList
        this.shouldReportRenderDisplayListBlocked = shouldReportRenderDisplayListBlocked
        this.didPreserveRenderNode = didPreserveRenderNode
    }
}

// Renderer input packet 是本轮 canonical endpoint；
// 它只是 renderer input value facts，不是真实渲染请求或 backend packet。
struct CjguiInternalRendererInputPacket {
    let displayList: CjguiInternalRenderDisplayList
    let sceneVersion: CjguiInternalSceneVersion
    let displayListVersion: CjguiInternalSceneVersion
    let isRendererInputPacketReady: Bool
    let didKeepRendererInputBackendAgnostic: Bool
    let didAvoidPlatformObjectIntake: Bool
    let didAvoidRealRendering: Bool
    let shouldDeferRendererInputPacket: Bool
    let shouldReportRendererInputPacketBlocked: Bool
    let didPreserveRenderDisplayList: Bool

    init(
        displayList: CjguiInternalRenderDisplayList,
        sceneVersion: CjguiInternalSceneVersion,
        displayListVersion: CjguiInternalSceneVersion,
        isRendererInputPacketReady: Bool,
        didKeepRendererInputBackendAgnostic: Bool,
        didAvoidPlatformObjectIntake: Bool,
        didAvoidRealRendering: Bool,
        shouldDeferRendererInputPacket: Bool,
        shouldReportRendererInputPacketBlocked: Bool,
        didPreserveRenderDisplayList: Bool
    ) {
        this.displayList = displayList
        this.sceneVersion = sceneVersion
        this.displayListVersion = displayListVersion
        this.isRendererInputPacketReady = isRendererInputPacketReady
        this.didKeepRendererInputBackendAgnostic = didKeepRendererInputBackendAgnostic
        this.didAvoidPlatformObjectIntake = didAvoidPlatformObjectIntake
        this.didAvoidRealRendering = didAvoidRealRendering
        this.shouldDeferRendererInputPacket = shouldDeferRendererInputPacket
        this.shouldReportRendererInputPacketBlocked = shouldReportRendererInputPacketBlocked
        this.didPreserveRenderDisplayList = didPreserveRenderDisplayList
    }
}

// Render command kind 是 display list 命令形状的占位分类；
// 当前只允许 node placeholder，不承诺真实 drawing op 或绘制调用绑定。
struct CjguiInternalRenderCommandKind {
    let isNoOpPlaceholder: Bool
    let isNodePlaceholder: Bool
    let isRealDrawingOp: Bool
    let didAvoidDrawCallBinding: Bool

    init(
        isNoOpPlaceholder: Bool,
        isNodePlaceholder: Bool,
        isRealDrawingOp: Bool,
        didAvoidDrawCallBinding: Bool
    ) {
        this.isNoOpPlaceholder = isNoOpPlaceholder
        this.isNodePlaceholder = isNodePlaceholder
        this.isRealDrawingOp = isRealDrawingOp
        this.didAvoidDrawCallBinding = didAvoidDrawCallBinding
    }
}

// Render command 是 dehydrated / 后端无关的 command-shape facts；
// 它携带 node id / bounds / clip / z-order / material / version / repaint hint，但不是 draw call。
struct CjguiInternalRenderCommand {
    let kind: CjguiInternalRenderCommandKind
    let nodeId: CjguiInternalRenderNodeId
    let bounds: CjguiInternalRenderBounds
    let clip: CjguiInternalRenderClip
    let zOrder: Int64
    let materialKey: CjguiInternalRenderMaterialKey
    let sceneVersion: CjguiInternalSceneVersion
    let displayListVersion: CjguiInternalSceneVersion
    let invalidationHint: CjguiInternalRenderInvalidationHint
    let didPrepareRenderCommand: Bool
    let didPreserveNodeFacts: Bool
    let didAvoidActualDrawingOp: Bool
    let shouldDeferRenderCommand: Bool
    let shouldReportRenderCommandBlocked: Bool

    init(
        kind: CjguiInternalRenderCommandKind,
        nodeId: CjguiInternalRenderNodeId,
        bounds: CjguiInternalRenderBounds,
        clip: CjguiInternalRenderClip,
        zOrder: Int64,
        materialKey: CjguiInternalRenderMaterialKey,
        sceneVersion: CjguiInternalSceneVersion,
        displayListVersion: CjguiInternalSceneVersion,
        invalidationHint: CjguiInternalRenderInvalidationHint,
        didPrepareRenderCommand: Bool,
        didPreserveNodeFacts: Bool,
        didAvoidActualDrawingOp: Bool,
        shouldDeferRenderCommand: Bool,
        shouldReportRenderCommandBlocked: Bool
    ) {
        this.kind = kind
        this.nodeId = nodeId
        this.bounds = bounds
        this.clip = clip
        this.zOrder = zOrder
        this.materialKey = materialKey
        this.sceneVersion = sceneVersion
        this.displayListVersion = displayListVersion
        this.invalidationHint = invalidationHint
        this.didPrepareRenderCommand = didPrepareRenderCommand
        this.didPreserveNodeFacts = didPreserveNodeFacts
        this.didAvoidActualDrawingOp = didAvoidActualDrawingOp
        this.shouldDeferRenderCommand = shouldDeferRenderCommand
        this.shouldReportRenderCommandBlocked = shouldReportRenderCommandBlocked
    }
}

// Render command list 只表达 full rebuild command shape；
// P1 不做局部重绘、增量更新或 display list mutation。
struct CjguiInternalRenderCommandList {
    let rendererInputPacket: CjguiInternalRendererInputPacket
    let rootCommand: CjguiInternalRenderCommand
    let commandListVersion: CjguiInternalSceneVersion
    let didPrepareRenderCommandList: Bool
    let didUseFullRebuildCommandList: Bool
    let didAvoidIncrementalCommandUpdate: Bool
    let didAvoidRendererSubmission: Bool
    let shouldDeferRenderCommandList: Bool
    let shouldReportRenderCommandListBlocked: Bool
    let didPreserveRendererInputPacket: Bool

    init(
        rendererInputPacket: CjguiInternalRendererInputPacket,
        rootCommand: CjguiInternalRenderCommand,
        commandListVersion: CjguiInternalSceneVersion,
        didPrepareRenderCommandList: Bool,
        didUseFullRebuildCommandList: Bool,
        didAvoidIncrementalCommandUpdate: Bool,
        didAvoidRendererSubmission: Bool,
        shouldDeferRenderCommandList: Bool,
        shouldReportRenderCommandListBlocked: Bool,
        didPreserveRendererInputPacket: Bool
    ) {
        this.rendererInputPacket = rendererInputPacket
        this.rootCommand = rootCommand
        this.commandListVersion = commandListVersion
        this.didPrepareRenderCommandList = didPrepareRenderCommandList
        this.didUseFullRebuildCommandList = didUseFullRebuildCommandList
        this.didAvoidIncrementalCommandUpdate = didAvoidIncrementalCommandUpdate
        this.didAvoidRendererSubmission = didAvoidRendererSubmission
        this.shouldDeferRenderCommandList = shouldDeferRenderCommandList
        this.shouldReportRenderCommandListBlocked = shouldReportRenderCommandListBlocked
        this.didPreserveRendererInputPacket = didPreserveRendererInputPacket
    }
}

// Render command packet 是 command-shape 的 canonical endpoint；
// 它不是平台命令缓冲、不是后端提交，也不会触发真实渲染。
struct CjguiInternalRenderCommandPacket {
    let commandList: CjguiInternalRenderCommandList
    let sceneVersion: CjguiInternalSceneVersion
    let displayListVersion: CjguiInternalSceneVersion
    let commandListVersion: CjguiInternalSceneVersion
    let isRenderCommandPacketReady: Bool
    let didKeepCommandPacketRendererAgnostic: Bool
    let didAvoidRenderSideEffect: Bool
    let shouldDeferRenderCommandPacket: Bool
    let shouldReportRenderCommandPacketBlocked: Bool
    let didPreserveRenderCommandList: Bool

    init(
        commandList: CjguiInternalRenderCommandList,
        sceneVersion: CjguiInternalSceneVersion,
        displayListVersion: CjguiInternalSceneVersion,
        commandListVersion: CjguiInternalSceneVersion,
        isRenderCommandPacketReady: Bool,
        didKeepCommandPacketRendererAgnostic: Bool,
        didAvoidRenderSideEffect: Bool,
        shouldDeferRenderCommandPacket: Bool,
        shouldReportRenderCommandPacketBlocked: Bool,
        didPreserveRenderCommandList: Bool
    ) {
        this.commandList = commandList
        this.sceneVersion = sceneVersion
        this.displayListVersion = displayListVersion
        this.commandListVersion = commandListVersion
        this.isRenderCommandPacketReady = isRenderCommandPacketReady
        this.didKeepCommandPacketRendererAgnostic = didKeepCommandPacketRendererAgnostic
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
        this.shouldDeferRenderCommandPacket = shouldDeferRenderCommandPacket
        this.shouldReportRenderCommandPacketBlocked = shouldReportRenderCommandPacketBlocked
        this.didPreserveRenderCommandList = didPreserveRenderCommandList
    }
}

// Render material hint 是 command packet 之后的材质提示 value facts；
// 它只保留 material key / command kind / clip / version，不绑定真实渲染资源。
struct CjguiInternalRenderMaterialHint {
    let commandPacket: CjguiInternalRenderCommandPacket
    let materialKey: CjguiInternalRenderMaterialKey
    let commandKind: CjguiInternalRenderCommandKind
    let zOrder: Int64
    let clip: CjguiInternalRenderClip
    let sceneVersion: CjguiInternalSceneVersion
    let commandListVersion: CjguiInternalSceneVersion
    let didPrepareRenderMaterialHint: Bool
    let didKeepMaterialHintRendererAgnostic: Bool
    let didAvoidMaterialResourceBinding: Bool
    let shouldDeferRenderMaterialHint: Bool
    let shouldReportRenderMaterialHintBlocked: Bool
    let didPreserveRenderCommandPacket: Bool

    init(
        commandPacket: CjguiInternalRenderCommandPacket,
        materialKey: CjguiInternalRenderMaterialKey,
        commandKind: CjguiInternalRenderCommandKind,
        zOrder: Int64,
        clip: CjguiInternalRenderClip,
        sceneVersion: CjguiInternalSceneVersion,
        commandListVersion: CjguiInternalSceneVersion,
        didPrepareRenderMaterialHint: Bool,
        didKeepMaterialHintRendererAgnostic: Bool,
        didAvoidMaterialResourceBinding: Bool,
        shouldDeferRenderMaterialHint: Bool,
        shouldReportRenderMaterialHintBlocked: Bool,
        didPreserveRenderCommandPacket: Bool
    ) {
        this.commandPacket = commandPacket
        this.materialKey = materialKey
        this.commandKind = commandKind
        this.zOrder = zOrder
        this.clip = clip
        this.sceneVersion = sceneVersion
        this.commandListVersion = commandListVersion
        this.didPrepareRenderMaterialHint = didPrepareRenderMaterialHint
        this.didKeepMaterialHintRendererAgnostic = didKeepMaterialHintRendererAgnostic
        this.didAvoidMaterialResourceBinding = didAvoidMaterialResourceBinding
        this.shouldDeferRenderMaterialHint = shouldDeferRenderMaterialHint
        this.shouldReportRenderMaterialHintBlocked = shouldReportRenderMaterialHintBlocked
        this.didPreserveRenderCommandPacket = didPreserveRenderCommandPacket
    }
}

// Render batch key 是后端无关的合批提示 key；
// 它不是真实图形管线 key，也不创建任何绘制资源。
struct CjguiInternalRenderBatchKey {
    let materialHint: CjguiInternalRenderMaterialHint
    let materialKey: CjguiInternalRenderMaterialKey
    let commandKind: CjguiInternalRenderCommandKind
    let zOrder: Int64
    let clip: CjguiInternalRenderClip
    let sceneVersion: CjguiInternalSceneVersion
    let commandListVersion: CjguiInternalSceneVersion
    let didPrepareRenderBatchKey: Bool
    let didKeepBatchKeyAsHint: Bool
    let didAvoidPipelineBinding: Bool
    let shouldDeferRenderBatchKey: Bool
    let shouldReportRenderBatchKeyBlocked: Bool
    let didPreserveMaterialHint: Bool

    init(
        materialHint: CjguiInternalRenderMaterialHint,
        materialKey: CjguiInternalRenderMaterialKey,
        commandKind: CjguiInternalRenderCommandKind,
        zOrder: Int64,
        clip: CjguiInternalRenderClip,
        sceneVersion: CjguiInternalSceneVersion,
        commandListVersion: CjguiInternalSceneVersion,
        didPrepareRenderBatchKey: Bool,
        didKeepBatchKeyAsHint: Bool,
        didAvoidPipelineBinding: Bool,
        shouldDeferRenderBatchKey: Bool,
        shouldReportRenderBatchKeyBlocked: Bool,
        didPreserveMaterialHint: Bool
    ) {
        this.materialHint = materialHint
        this.materialKey = materialKey
        this.commandKind = commandKind
        this.zOrder = zOrder
        this.clip = clip
        this.sceneVersion = sceneVersion
        this.commandListVersion = commandListVersion
        this.didPrepareRenderBatchKey = didPrepareRenderBatchKey
        this.didKeepBatchKeyAsHint = didKeepBatchKeyAsHint
        this.didAvoidPipelineBinding = didAvoidPipelineBinding
        this.shouldDeferRenderBatchKey = shouldDeferRenderBatchKey
        this.shouldReportRenderBatchKeyBlocked = shouldReportRenderBatchKeyBlocked
        this.didPreserveMaterialHint = didPreserveMaterialHint
    }
}

// Render ordering hint 是排序相关的 value fact；
// 它只记录 z-order / clip / version，不执行排序副作用或重排渲染队列。
struct CjguiInternalRenderOrderingHint {
    let batchKey: CjguiInternalRenderBatchKey
    let zOrder: Int64
    let clip: CjguiInternalRenderClip
    let sceneVersion: CjguiInternalSceneVersion
    let commandListVersion: CjguiInternalSceneVersion
    let didPrepareRenderOrderingHint: Bool
    let didPreserveCommandOrderingFacts: Bool
    let didAvoidSortSideEffect: Bool
    let shouldDeferRenderOrderingHint: Bool
    let shouldReportRenderOrderingHintBlocked: Bool
    let didPreserveRenderBatchKey: Bool

    init(
        batchKey: CjguiInternalRenderBatchKey,
        zOrder: Int64,
        clip: CjguiInternalRenderClip,
        sceneVersion: CjguiInternalSceneVersion,
        commandListVersion: CjguiInternalSceneVersion,
        didPrepareRenderOrderingHint: Bool,
        didPreserveCommandOrderingFacts: Bool,
        didAvoidSortSideEffect: Bool,
        shouldDeferRenderOrderingHint: Bool,
        shouldReportRenderOrderingHintBlocked: Bool,
        didPreserveRenderBatchKey: Bool
    ) {
        this.batchKey = batchKey
        this.zOrder = zOrder
        this.clip = clip
        this.sceneVersion = sceneVersion
        this.commandListVersion = commandListVersion
        this.didPrepareRenderOrderingHint = didPrepareRenderOrderingHint
        this.didPreserveCommandOrderingFacts = didPreserveCommandOrderingFacts
        this.didAvoidSortSideEffect = didAvoidSortSideEffect
        this.shouldDeferRenderOrderingHint = shouldDeferRenderOrderingHint
        this.shouldReportRenderOrderingHintBlocked = shouldReportRenderOrderingHintBlocked
        this.didPreserveRenderBatchKey = didPreserveRenderBatchKey
    }
}

// Render batching plan 是脱水的合批提示计划；
// P1 仍 full rebuild，不做真实绘制合并、增量补丁或渲染提交。
struct CjguiInternalRenderBatchingPlan {
    let commandPacket: CjguiInternalRenderCommandPacket
    let materialHint: CjguiInternalRenderMaterialHint
    let batchKey: CjguiInternalRenderBatchKey
    let orderingHint: CjguiInternalRenderOrderingHint
    let planVersion: CjguiInternalSceneVersion
    let didPrepareRenderBatchingPlan: Bool
    let didUseFullRebuildBatchingPlan: Bool
    let didKeepPlanRendererAgnostic: Bool
    let didAvoidCommandMerge: Bool
    let didAvoidIncrementalBatchUpdate: Bool
    let shouldDeferRenderBatchingPlan: Bool
    let shouldReportRenderBatchingPlanBlocked: Bool
    let didPreserveRenderCommandPacket: Bool

    init(
        commandPacket: CjguiInternalRenderCommandPacket,
        materialHint: CjguiInternalRenderMaterialHint,
        batchKey: CjguiInternalRenderBatchKey,
        orderingHint: CjguiInternalRenderOrderingHint,
        planVersion: CjguiInternalSceneVersion,
        didPrepareRenderBatchingPlan: Bool,
        didUseFullRebuildBatchingPlan: Bool,
        didKeepPlanRendererAgnostic: Bool,
        didAvoidCommandMerge: Bool,
        didAvoidIncrementalBatchUpdate: Bool,
        shouldDeferRenderBatchingPlan: Bool,
        shouldReportRenderBatchingPlanBlocked: Bool,
        didPreserveRenderCommandPacket: Bool
    ) {
        this.commandPacket = commandPacket
        this.materialHint = materialHint
        this.batchKey = batchKey
        this.orderingHint = orderingHint
        this.planVersion = planVersion
        this.didPrepareRenderBatchingPlan = didPrepareRenderBatchingPlan
        this.didUseFullRebuildBatchingPlan = didUseFullRebuildBatchingPlan
        this.didKeepPlanRendererAgnostic = didKeepPlanRendererAgnostic
        this.didAvoidCommandMerge = didAvoidCommandMerge
        this.didAvoidIncrementalBatchUpdate = didAvoidIncrementalBatchUpdate
        this.shouldDeferRenderBatchingPlan = shouldDeferRenderBatchingPlan
        this.shouldReportRenderBatchingPlanBlocked = shouldReportRenderBatchingPlanBlocked
        this.didPreserveRenderCommandPacket = didPreserveRenderCommandPacket
    }
}

// Render batching packet 是 material / batching hint 的 canonical endpoint；
// 它只是后端无关 value facts，不是真实合批结果、绘制队列或渲染副作用。
struct CjguiInternalRenderBatchingPacket {
    let batchingPlan: CjguiInternalRenderBatchingPlan
    let sceneVersion: CjguiInternalSceneVersion
    let displayListVersion: CjguiInternalSceneVersion
    let commandListVersion: CjguiInternalSceneVersion
    let isRenderBatchingPacketReady: Bool
    let didKeepBatchingPacketRendererAgnostic: Bool
    let didAvoidRenderSideEffect: Bool
    let didAvoidCommandMerge: Bool
    let shouldDeferRenderBatchingPacket: Bool
    let shouldReportRenderBatchingPacketBlocked: Bool
    let didPreserveRenderBatchingPlan: Bool

    init(
        batchingPlan: CjguiInternalRenderBatchingPlan,
        sceneVersion: CjguiInternalSceneVersion,
        displayListVersion: CjguiInternalSceneVersion,
        commandListVersion: CjguiInternalSceneVersion,
        isRenderBatchingPacketReady: Bool,
        didKeepBatchingPacketRendererAgnostic: Bool,
        didAvoidRenderSideEffect: Bool,
        didAvoidCommandMerge: Bool,
        shouldDeferRenderBatchingPacket: Bool,
        shouldReportRenderBatchingPacketBlocked: Bool,
        didPreserveRenderBatchingPlan: Bool
    ) {
        this.batchingPlan = batchingPlan
        this.sceneVersion = sceneVersion
        this.displayListVersion = displayListVersion
        this.commandListVersion = commandListVersion
        this.isRenderBatchingPacketReady = isRenderBatchingPacketReady
        this.didKeepBatchingPacketRendererAgnostic = didKeepBatchingPacketRendererAgnostic
        this.didAvoidRenderSideEffect = didAvoidRenderSideEffect
        this.didAvoidCommandMerge = didAvoidCommandMerge
        this.shouldDeferRenderBatchingPacket = shouldDeferRenderBatchingPacket
        this.shouldReportRenderBatchingPacketBlocked = shouldReportRenderBatchingPacketBlocked
        this.didPreserveRenderBatchingPlan = didPreserveRenderBatchingPlan
    }
}

func cjguiInternalBuildDefaultSceneVersion(): CjguiInternalSceneVersion {
    return CjguiInternalSceneVersion(0)
}

func cjguiInternalBuildDefaultRenderNodeId(): CjguiInternalRenderNodeId {
    return CjguiInternalRenderNodeId(0, true)
}

func cjguiInternalBuildDefaultRenderBounds(): CjguiInternalRenderBounds {
    return CjguiInternalRenderBounds(0, 0, 0, 0, true)
}

func cjguiInternalBuildDefaultRenderClip(): CjguiInternalRenderClip {
    let bounds = cjguiInternalBuildDefaultRenderBounds()
    return CjguiInternalRenderClip(bounds, false, true)
}

func cjguiInternalBuildDefaultRenderMaterialKey(): CjguiInternalRenderMaterialKey {
    return CjguiInternalRenderMaterialKey(0, true)
}

func cjguiInternalBuildDefaultRenderInvalidationHint(): CjguiInternalRenderInvalidationHint {
    return CjguiInternalRenderInvalidationHint(true, false, false, false, true)
}

func cjguiInternalBuildDefaultSceneSnapshot(): CjguiInternalSceneSnapshot {
    let version = cjguiInternalBuildDefaultSceneVersion()
    let rootNodeId = cjguiInternalBuildDefaultRenderNodeId()
    let bounds = cjguiInternalBuildDefaultRenderBounds()
    let clip = cjguiInternalBuildDefaultRenderClip()
    let materialKey = cjguiInternalBuildDefaultRenderMaterialKey()
    let invalidationHint = cjguiInternalBuildDefaultRenderInvalidationHint()
    return CjguiInternalSceneSnapshot(
        version,
        rootNodeId,
        bounds,
        clip,
        materialKey,
        invalidationHint,
        true,
        true,
        true,
        false,
        false
    )
}

func cjguiInternalBuildRenderNodeFromScene(
    sceneSnapshot: CjguiInternalSceneSnapshot
): CjguiInternalRenderNode {
    let sceneReady = sceneSnapshot.didPrepareSceneSnapshot &&
        sceneSnapshot.didUseMinimalDefaultSceneInput &&
        sceneSnapshot.didReserveSemanticSceneHints &&
        sceneSnapshot.rootNodeId.isStablePlaceholder &&
        sceneSnapshot.bounds.didReserveStableBounds &&
        sceneSnapshot.clip.didReserveClipFacts &&
        sceneSnapshot.materialKey.didReserveMaterialFacts &&
        sceneSnapshot.invalidationHint.requiresFullDisplayListRebuild &&
        sceneSnapshot.invalidationHint.allowsIncrementalRebuild == false &&
        sceneSnapshot.invalidationHint.allowsDisplayListMutation == false &&
        sceneSnapshot.invalidationHint.allowsPartialRepaint == false &&
        sceneSnapshot.shouldDeferSceneSnapshot == false &&
        sceneSnapshot.shouldReportSceneSnapshotBlocked == false
    let sceneDeferred = sceneSnapshot.didPrepareSceneSnapshot == false &&
        sceneSnapshot.didUseMinimalDefaultSceneInput == false &&
        sceneSnapshot.didReserveSemanticSceneHints == false &&
        sceneSnapshot.shouldDeferSceneSnapshot &&
        sceneSnapshot.shouldReportSceneSnapshotBlocked == false
    let sceneInconsistent = (
        sceneSnapshot.didPrepareSceneSnapshot &&
            (
                sceneSnapshot.didUseMinimalDefaultSceneInput == false ||
                sceneSnapshot.didReserveSemanticSceneHints == false ||
                sceneSnapshot.rootNodeId.isStablePlaceholder == false ||
                sceneSnapshot.bounds.didReserveStableBounds == false ||
                sceneSnapshot.clip.didReserveClipFacts == false ||
                sceneSnapshot.materialKey.didReserveMaterialFacts == false ||
                sceneSnapshot.invalidationHint.requiresFullDisplayListRebuild == false ||
                sceneSnapshot.invalidationHint.allowsIncrementalRebuild ||
                sceneSnapshot.invalidationHint.allowsDisplayListMutation ||
                sceneSnapshot.invalidationHint.allowsPartialRepaint ||
                sceneSnapshot.shouldDeferSceneSnapshot ||
                sceneSnapshot.shouldReportSceneSnapshotBlocked
            )
        ) ||
        (sceneSnapshot.shouldDeferSceneSnapshot && sceneSnapshot.shouldReportSceneSnapshotBlocked)

    // scene facts 不一致时必须 fail-closed，不能伪造 render node 或绕过 owner truth。
    if (sceneSnapshot.shouldReportSceneSnapshotBlocked || sceneInconsistent) {
        return CjguiInternalRenderNode(
            sceneSnapshot,
            sceneSnapshot.rootNodeId,
            sceneSnapshot.bounds,
            sceneSnapshot.clip,
            0,
            sceneSnapshot.materialKey,
            sceneSnapshot.invalidationHint,
            false,
            false,
            false,
            true
        )
    }

    if (sceneReady) {
        return CjguiInternalRenderNode(
            sceneSnapshot,
            sceneSnapshot.rootNodeId,
            sceneSnapshot.bounds,
            sceneSnapshot.clip,
            0,
            sceneSnapshot.materialKey,
            sceneSnapshot.invalidationHint,
            true,
            true,
            false,
            false
        )
    }

    if (sceneDeferred) {
        return CjguiInternalRenderNode(
            sceneSnapshot,
            sceneSnapshot.rootNodeId,
            sceneSnapshot.bounds,
            sceneSnapshot.clip,
            0,
            sceneSnapshot.materialKey,
            sceneSnapshot.invalidationHint,
            false,
            false,
            true,
            false
        )
    }

    return CjguiInternalRenderNode(
        sceneSnapshot,
        sceneSnapshot.rootNodeId,
        sceneSnapshot.bounds,
        sceneSnapshot.clip,
        0,
        sceneSnapshot.materialKey,
        sceneSnapshot.invalidationHint,
        false,
        false,
        false,
        true
    )
}

func cjguiInternalBuildFullRenderDisplayList(
    sceneSnapshot: CjguiInternalSceneSnapshot,
    rootNode: CjguiInternalRenderNode
): CjguiInternalRenderDisplayList {
    let nodeReady = rootNode.didPrepareRenderNode &&
        rootNode.didPreserveSceneSnapshot &&
        rootNode.invalidationHint.requiresFullDisplayListRebuild &&
        rootNode.invalidationHint.allowsIncrementalRebuild == false &&
        rootNode.invalidationHint.allowsDisplayListMutation == false &&
        rootNode.invalidationHint.allowsPartialRepaint == false &&
        rootNode.shouldDeferRenderNode == false &&
        rootNode.shouldReportRenderNodeBlocked == false
    let nodeDeferred = rootNode.didPrepareRenderNode == false &&
        rootNode.didPreserveSceneSnapshot == false &&
        rootNode.shouldDeferRenderNode &&
        rootNode.shouldReportRenderNodeBlocked == false
    let nodeInconsistent = (
        rootNode.didPrepareRenderNode &&
            (
                rootNode.didPreserveSceneSnapshot == false ||
                rootNode.invalidationHint.requiresFullDisplayListRebuild == false ||
                rootNode.invalidationHint.allowsIncrementalRebuild ||
                rootNode.invalidationHint.allowsDisplayListMutation ||
                rootNode.invalidationHint.allowsPartialRepaint ||
                rootNode.shouldDeferRenderNode ||
                rootNode.shouldReportRenderNodeBlocked
            )
        ) ||
        (rootNode.didPreserveSceneSnapshot && rootNode.didPrepareRenderNode == false) ||
        (rootNode.shouldDeferRenderNode && rootNode.shouldReportRenderNodeBlocked)

    // render node facts 不一致时必须 fail-closed，display list 不能伪造成可渲染输出。
    if (rootNode.shouldReportRenderNodeBlocked || nodeInconsistent) {
        return CjguiInternalRenderDisplayList(
            sceneSnapshot,
            rootNode,
            sceneSnapshot.version,
            false,
            false,
            true,
            true,
            true,
            false,
            true,
            false
        )
    }

    if (nodeReady) {
        return CjguiInternalRenderDisplayList(
            sceneSnapshot,
            rootNode,
            sceneSnapshot.version,
            true,
            true,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (nodeDeferred) {
        return CjguiInternalRenderDisplayList(
            sceneSnapshot,
            rootNode,
            sceneSnapshot.version,
            false,
            false,
            true,
            true,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRenderDisplayList(
        sceneSnapshot,
        rootNode,
        sceneSnapshot.version,
        false,
        false,
        true,
        true,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalBuildRendererInputPacket(
    displayList: CjguiInternalRenderDisplayList
): CjguiInternalRendererInputPacket {
    let displayListReady = displayList.didPrepareRenderDisplayList &&
        displayList.didUseFullDisplayListRebuild &&
        displayList.didAvoidIncrementalRebuild &&
        displayList.didAvoidDisplayListMutation &&
        displayList.didAvoidPartialRepaint &&
        displayList.didPreserveRenderNode &&
        displayList.shouldDeferRenderDisplayList == false &&
        displayList.shouldReportRenderDisplayListBlocked == false
    let displayListDeferred = displayList.didPrepareRenderDisplayList == false &&
        displayList.didUseFullDisplayListRebuild == false &&
        displayList.didPreserveRenderNode == false &&
        displayList.didAvoidIncrementalRebuild &&
        displayList.didAvoidDisplayListMutation &&
        displayList.didAvoidPartialRepaint &&
        displayList.shouldDeferRenderDisplayList &&
        displayList.shouldReportRenderDisplayListBlocked == false
    let displayListInconsistent = (
        displayList.didPrepareRenderDisplayList &&
            (
                displayList.didUseFullDisplayListRebuild == false ||
                displayList.didAvoidIncrementalRebuild == false ||
                displayList.didAvoidDisplayListMutation == false ||
                displayList.didAvoidPartialRepaint == false ||
                displayList.didPreserveRenderNode == false ||
                displayList.shouldDeferRenderDisplayList ||
                displayList.shouldReportRenderDisplayListBlocked
            )
        ) ||
        (displayList.didPreserveRenderNode && displayList.didPrepareRenderDisplayList == false) ||
        (displayList.shouldDeferRenderDisplayList && displayList.shouldReportRenderDisplayListBlocked)

    // display list facts 不一致时必须 fail-closed，packet 不能伪造成真实渲染输入。
    if (displayList.shouldReportRenderDisplayListBlocked || displayListInconsistent) {
        return CjguiInternalRendererInputPacket(
            displayList,
            displayList.sceneSnapshot.version,
            displayList.displayListVersion,
            false,
            true,
            true,
            true,
            false,
            true,
            false
        )
    }

    if (displayListReady) {
        return CjguiInternalRendererInputPacket(
            displayList,
            displayList.sceneSnapshot.version,
            displayList.displayListVersion,
            true,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (displayListDeferred) {
        return CjguiInternalRendererInputPacket(
            displayList,
            displayList.sceneSnapshot.version,
            displayList.displayListVersion,
            false,
            true,
            true,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRendererInputPacket(
        displayList,
        displayList.sceneSnapshot.version,
        displayList.displayListVersion,
        false,
        true,
        true,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalExecuteDefaultSceneRendererInputDraft(): CjguiInternalRendererInputPacket {
    // 默认 draft 只生成 renderer input value facts：minimal scene -> full display list -> packet；
    // 它不读取 queue / action / runtime mutable facts，也不触发真实渲染。
    let sceneSnapshot = cjguiInternalBuildDefaultSceneSnapshot()
    let rootNode = cjguiInternalBuildRenderNodeFromScene(sceneSnapshot)
    let displayList = cjguiInternalBuildFullRenderDisplayList(sceneSnapshot, rootNode)
    return cjguiInternalBuildRendererInputPacket(displayList)
}

func cjguiInternalDefaultRenderCommandKind(): CjguiInternalRenderCommandKind {
    return CjguiInternalRenderCommandKind(false, true, false, true)
}

func cjguiInternalBuildRenderCommandFromNode(
    rendererInputPacket: CjguiInternalRendererInputPacket
): CjguiInternalRenderCommand {
    let displayList = rendererInputPacket.displayList
    let rootNode = displayList.rootNode
    let commandKind = cjguiInternalDefaultRenderCommandKind()
    let packetReady = rendererInputPacket.isRendererInputPacketReady &&
        rendererInputPacket.didKeepRendererInputBackendAgnostic &&
        rendererInputPacket.didAvoidPlatformObjectIntake &&
        rendererInputPacket.didAvoidRealRendering &&
        rendererInputPacket.didPreserveRenderDisplayList &&
        rendererInputPacket.shouldDeferRendererInputPacket == false &&
        rendererInputPacket.shouldReportRendererInputPacketBlocked == false
    let packetDeferred = rendererInputPacket.isRendererInputPacketReady == false &&
        rendererInputPacket.didKeepRendererInputBackendAgnostic &&
        rendererInputPacket.didAvoidPlatformObjectIntake &&
        rendererInputPacket.didAvoidRealRendering &&
        rendererInputPacket.didPreserveRenderDisplayList == false &&
        rendererInputPacket.shouldDeferRendererInputPacket &&
        rendererInputPacket.shouldReportRendererInputPacketBlocked == false
    let packetInconsistent = (
        rendererInputPacket.isRendererInputPacketReady &&
            (
                rendererInputPacket.didKeepRendererInputBackendAgnostic == false ||
                rendererInputPacket.didAvoidPlatformObjectIntake == false ||
                rendererInputPacket.didAvoidRealRendering == false ||
                rendererInputPacket.didPreserveRenderDisplayList == false ||
                rendererInputPacket.shouldDeferRendererInputPacket ||
                rendererInputPacket.shouldReportRendererInputPacketBlocked
            )
        ) ||
        (
            commandKind.isRealDrawingOp ||
            commandKind.didAvoidDrawCallBinding == false ||
            (commandKind.isNoOpPlaceholder == false && commandKind.isNodePlaceholder == false)
        ) ||
        (rendererInputPacket.shouldDeferRendererInputPacket && rendererInputPacket.shouldReportRendererInputPacketBlocked)

    // renderer input packet 或 command kind 不一致时必须 fail-closed，不能伪造真实 draw command。
    if (rendererInputPacket.shouldReportRendererInputPacketBlocked || packetInconsistent) {
        return CjguiInternalRenderCommand(
            commandKind,
            rootNode.nodeId,
            rootNode.bounds,
            rootNode.clip,
            rootNode.zOrder,
            rootNode.materialKey,
            rendererInputPacket.sceneVersion,
            rendererInputPacket.displayListVersion,
            rootNode.invalidationHint,
            false,
            false,
            true,
            false,
            true
        )
    }

    if (packetReady) {
        return CjguiInternalRenderCommand(
            commandKind,
            rootNode.nodeId,
            rootNode.bounds,
            rootNode.clip,
            rootNode.zOrder,
            rootNode.materialKey,
            rendererInputPacket.sceneVersion,
            rendererInputPacket.displayListVersion,
            rootNode.invalidationHint,
            true,
            true,
            true,
            false,
            false
        )
    }

    if (packetDeferred) {
        return CjguiInternalRenderCommand(
            commandKind,
            rootNode.nodeId,
            rootNode.bounds,
            rootNode.clip,
            rootNode.zOrder,
            rootNode.materialKey,
            rendererInputPacket.sceneVersion,
            rendererInputPacket.displayListVersion,
            rootNode.invalidationHint,
            false,
            false,
            true,
            true,
            false
        )
    }

    return CjguiInternalRenderCommand(
        commandKind,
        rootNode.nodeId,
        rootNode.bounds,
        rootNode.clip,
        rootNode.zOrder,
        rootNode.materialKey,
        rendererInputPacket.sceneVersion,
        rendererInputPacket.displayListVersion,
        rootNode.invalidationHint,
        false,
        false,
        true,
        false,
        true
    )
}

func cjguiInternalBuildRenderCommandList(
    rendererInputPacket: CjguiInternalRendererInputPacket,
    rootCommand: CjguiInternalRenderCommand
): CjguiInternalRenderCommandList {
    let commandReady = rootCommand.didPrepareRenderCommand &&
        rootCommand.didPreserveNodeFacts &&
        rootCommand.didAvoidActualDrawingOp &&
        rootCommand.kind.isNodePlaceholder &&
        rootCommand.kind.isRealDrawingOp == false &&
        rootCommand.kind.didAvoidDrawCallBinding &&
        rootCommand.invalidationHint.requiresFullDisplayListRebuild &&
        rootCommand.invalidationHint.allowsIncrementalRebuild == false &&
        rootCommand.invalidationHint.allowsDisplayListMutation == false &&
        rootCommand.invalidationHint.allowsPartialRepaint == false &&
        rootCommand.shouldDeferRenderCommand == false &&
        rootCommand.shouldReportRenderCommandBlocked == false
    let commandDeferred = rootCommand.didPrepareRenderCommand == false &&
        rootCommand.didPreserveNodeFacts == false &&
        rootCommand.didAvoidActualDrawingOp &&
        rootCommand.shouldDeferRenderCommand &&
        rootCommand.shouldReportRenderCommandBlocked == false
    let commandInconsistent = (
        rootCommand.didPrepareRenderCommand &&
            (
                rootCommand.didPreserveNodeFacts == false ||
                rootCommand.didAvoidActualDrawingOp == false ||
                rootCommand.kind.isRealDrawingOp ||
                rootCommand.kind.didAvoidDrawCallBinding == false ||
                rootCommand.invalidationHint.requiresFullDisplayListRebuild == false ||
                rootCommand.invalidationHint.allowsIncrementalRebuild ||
                rootCommand.invalidationHint.allowsDisplayListMutation ||
                rootCommand.invalidationHint.allowsPartialRepaint ||
                rootCommand.shouldDeferRenderCommand ||
                rootCommand.shouldReportRenderCommandBlocked
            )
        ) ||
        (rootCommand.didPreserveNodeFacts && rootCommand.didPrepareRenderCommand == false) ||
        (rootCommand.shouldDeferRenderCommand && rootCommand.shouldReportRenderCommandBlocked)

    // command facts 不一致时必须 fail-closed，command list 不能升级成后端提交。
    if (rootCommand.shouldReportRenderCommandBlocked || commandInconsistent) {
        return CjguiInternalRenderCommandList(
            rendererInputPacket,
            rootCommand,
            rendererInputPacket.displayListVersion,
            false,
            false,
            true,
            true,
            false,
            true,
            false
        )
    }

    if (commandReady) {
        return CjguiInternalRenderCommandList(
            rendererInputPacket,
            rootCommand,
            rendererInputPacket.displayListVersion,
            true,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (commandDeferred) {
        return CjguiInternalRenderCommandList(
            rendererInputPacket,
            rootCommand,
            rendererInputPacket.displayListVersion,
            false,
            false,
            true,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRenderCommandList(
        rendererInputPacket,
        rootCommand,
        rendererInputPacket.displayListVersion,
        false,
        false,
        true,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalBuildRenderCommandPacket(
    commandList: CjguiInternalRenderCommandList
): CjguiInternalRenderCommandPacket {
    let commandListReady = commandList.didPrepareRenderCommandList &&
        commandList.didUseFullRebuildCommandList &&
        commandList.didAvoidIncrementalCommandUpdate &&
        commandList.didAvoidRendererSubmission &&
        commandList.didPreserveRendererInputPacket &&
        commandList.shouldDeferRenderCommandList == false &&
        commandList.shouldReportRenderCommandListBlocked == false
    let commandListDeferred = commandList.didPrepareRenderCommandList == false &&
        commandList.didUseFullRebuildCommandList == false &&
        commandList.didPreserveRendererInputPacket == false &&
        commandList.didAvoidIncrementalCommandUpdate &&
        commandList.didAvoidRendererSubmission &&
        commandList.shouldDeferRenderCommandList &&
        commandList.shouldReportRenderCommandListBlocked == false
    let commandListInconsistent = (
        commandList.didPrepareRenderCommandList &&
            (
                commandList.didUseFullRebuildCommandList == false ||
                commandList.didAvoidIncrementalCommandUpdate == false ||
                commandList.didAvoidRendererSubmission == false ||
                commandList.didPreserveRendererInputPacket == false ||
                commandList.shouldDeferRenderCommandList ||
                commandList.shouldReportRenderCommandListBlocked
            )
        ) ||
        (commandList.didPreserveRendererInputPacket && commandList.didPrepareRenderCommandList == false) ||
        (commandList.shouldDeferRenderCommandList && commandList.shouldReportRenderCommandListBlocked)

    // command list facts 不一致时必须 fail-closed，packet 不得伪造成渲染提交结果。
    if (commandList.shouldReportRenderCommandListBlocked || commandListInconsistent) {
        return CjguiInternalRenderCommandPacket(
            commandList,
            commandList.rendererInputPacket.sceneVersion,
            commandList.rendererInputPacket.displayListVersion,
            commandList.commandListVersion,
            false,
            true,
            true,
            false,
            true,
            false
        )
    }

    if (commandListReady) {
        return CjguiInternalRenderCommandPacket(
            commandList,
            commandList.rendererInputPacket.sceneVersion,
            commandList.rendererInputPacket.displayListVersion,
            commandList.commandListVersion,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (commandListDeferred) {
        return CjguiInternalRenderCommandPacket(
            commandList,
            commandList.rendererInputPacket.sceneVersion,
            commandList.rendererInputPacket.displayListVersion,
            commandList.commandListVersion,
            false,
            true,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRenderCommandPacket(
        commandList,
        commandList.rendererInputPacket.sceneVersion,
        commandList.rendererInputPacket.displayListVersion,
        commandList.commandListVersion,
        false,
        true,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalExecuteDefaultRenderCommandShapeDraft(): CjguiInternalRenderCommandPacket {
    // 默认 command-shape draft 只串联 renderer input packet -> command list -> command packet；
    // 它生成后端无关 value facts，不触发真实绘制或后端提交。
    let rendererInputPacket = cjguiInternalExecuteDefaultSceneRendererInputDraft()
    let rootCommand = cjguiInternalBuildRenderCommandFromNode(rendererInputPacket)
    let commandList = cjguiInternalBuildRenderCommandList(rendererInputPacket, rootCommand)
    return cjguiInternalBuildRenderCommandPacket(commandList)
}

func cjguiInternalBuildRenderMaterialHint(
    commandPacket: CjguiInternalRenderCommandPacket
): CjguiInternalRenderMaterialHint {
    let commandList = commandPacket.commandList
    let rootCommand = commandList.rootCommand
    let commandPacketReady = commandPacket.isRenderCommandPacketReady &&
        commandPacket.didKeepCommandPacketRendererAgnostic &&
        commandPacket.didAvoidRenderSideEffect &&
        commandPacket.didPreserveRenderCommandList &&
        commandPacket.shouldDeferRenderCommandPacket == false &&
        commandPacket.shouldReportRenderCommandPacketBlocked == false
    let commandPacketDeferred = commandPacket.isRenderCommandPacketReady == false &&
        commandPacket.didKeepCommandPacketRendererAgnostic &&
        commandPacket.didAvoidRenderSideEffect &&
        commandPacket.didPreserveRenderCommandList == false &&
        commandPacket.shouldDeferRenderCommandPacket &&
        commandPacket.shouldReportRenderCommandPacketBlocked == false
    let commandPacketInconsistent = (
        commandPacket.isRenderCommandPacketReady &&
            (
                commandPacket.didKeepCommandPacketRendererAgnostic == false ||
                commandPacket.didAvoidRenderSideEffect == false ||
                commandPacket.didPreserveRenderCommandList == false ||
                commandPacket.shouldDeferRenderCommandPacket ||
                commandPacket.shouldReportRenderCommandPacketBlocked
            )
        ) ||
        (
            rootCommand.kind.isRealDrawingOp ||
            rootCommand.kind.didAvoidDrawCallBinding == false ||
            rootCommand.materialKey.didReserveMaterialFacts == false ||
            rootCommand.invalidationHint.requiresFullDisplayListRebuild == false ||
            rootCommand.invalidationHint.allowsIncrementalRebuild ||
            rootCommand.invalidationHint.allowsDisplayListMutation ||
            rootCommand.invalidationHint.allowsPartialRepaint
        ) ||
        (commandPacket.shouldDeferRenderCommandPacket && commandPacket.shouldReportRenderCommandPacketBlocked)

    // command packet 或 material facts 不一致时必须 fail-closed，不能伪造真实材质绑定。
    if (commandPacket.shouldReportRenderCommandPacketBlocked || commandPacketInconsistent) {
        return CjguiInternalRenderMaterialHint(
            commandPacket,
            rootCommand.materialKey,
            rootCommand.kind,
            rootCommand.zOrder,
            rootCommand.clip,
            commandPacket.sceneVersion,
            commandPacket.commandListVersion,
            false,
            true,
            true,
            false,
            true,
            false
        )
    }

    if (commandPacketReady) {
        return CjguiInternalRenderMaterialHint(
            commandPacket,
            rootCommand.materialKey,
            rootCommand.kind,
            rootCommand.zOrder,
            rootCommand.clip,
            commandPacket.sceneVersion,
            commandPacket.commandListVersion,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (commandPacketDeferred) {
        return CjguiInternalRenderMaterialHint(
            commandPacket,
            rootCommand.materialKey,
            rootCommand.kind,
            rootCommand.zOrder,
            rootCommand.clip,
            commandPacket.sceneVersion,
            commandPacket.commandListVersion,
            false,
            true,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRenderMaterialHint(
        commandPacket,
        rootCommand.materialKey,
        rootCommand.kind,
        rootCommand.zOrder,
        rootCommand.clip,
        commandPacket.sceneVersion,
        commandPacket.commandListVersion,
        false,
        true,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalBuildRenderBatchKey(
    materialHint: CjguiInternalRenderMaterialHint
): CjguiInternalRenderBatchKey {
    let hintReady = materialHint.didPrepareRenderMaterialHint &&
        materialHint.didKeepMaterialHintRendererAgnostic &&
        materialHint.didAvoidMaterialResourceBinding &&
        materialHint.didPreserveRenderCommandPacket &&
        materialHint.commandKind.isNodePlaceholder &&
        materialHint.commandKind.isRealDrawingOp == false &&
        materialHint.commandKind.didAvoidDrawCallBinding &&
        materialHint.materialKey.didReserveMaterialFacts &&
        materialHint.shouldDeferRenderMaterialHint == false &&
        materialHint.shouldReportRenderMaterialHintBlocked == false
    let hintDeferred = materialHint.didPrepareRenderMaterialHint == false &&
        materialHint.didKeepMaterialHintRendererAgnostic &&
        materialHint.didAvoidMaterialResourceBinding &&
        materialHint.didPreserveRenderCommandPacket == false &&
        materialHint.shouldDeferRenderMaterialHint &&
        materialHint.shouldReportRenderMaterialHintBlocked == false
    let hintInconsistent = (
        materialHint.didPrepareRenderMaterialHint &&
            (
                materialHint.didKeepMaterialHintRendererAgnostic == false ||
                materialHint.didAvoidMaterialResourceBinding == false ||
                materialHint.didPreserveRenderCommandPacket == false ||
                materialHint.commandKind.isRealDrawingOp ||
                materialHint.commandKind.didAvoidDrawCallBinding == false ||
                materialHint.materialKey.didReserveMaterialFacts == false ||
                materialHint.shouldDeferRenderMaterialHint ||
                materialHint.shouldReportRenderMaterialHintBlocked
            )
        ) ||
        (materialHint.didPreserveRenderCommandPacket && materialHint.didPrepareRenderMaterialHint == false) ||
        (materialHint.shouldDeferRenderMaterialHint && materialHint.shouldReportRenderMaterialHintBlocked)

    // material hint 不一致时必须 fail-closed，batch key 只能是提示，不能变成真实资源 key。
    if (materialHint.shouldReportRenderMaterialHintBlocked || hintInconsistent) {
        return CjguiInternalRenderBatchKey(
            materialHint,
            materialHint.materialKey,
            materialHint.commandKind,
            materialHint.zOrder,
            materialHint.clip,
            materialHint.sceneVersion,
            materialHint.commandListVersion,
            false,
            true,
            true,
            false,
            true,
            false
        )
    }

    if (hintReady) {
        return CjguiInternalRenderBatchKey(
            materialHint,
            materialHint.materialKey,
            materialHint.commandKind,
            materialHint.zOrder,
            materialHint.clip,
            materialHint.sceneVersion,
            materialHint.commandListVersion,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (hintDeferred) {
        return CjguiInternalRenderBatchKey(
            materialHint,
            materialHint.materialKey,
            materialHint.commandKind,
            materialHint.zOrder,
            materialHint.clip,
            materialHint.sceneVersion,
            materialHint.commandListVersion,
            false,
            true,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRenderBatchKey(
        materialHint,
        materialHint.materialKey,
        materialHint.commandKind,
        materialHint.zOrder,
        materialHint.clip,
        materialHint.sceneVersion,
        materialHint.commandListVersion,
        false,
        true,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalBuildRenderOrderingHint(
    batchKey: CjguiInternalRenderBatchKey
): CjguiInternalRenderOrderingHint {
    let batchKeyReady = batchKey.didPrepareRenderBatchKey &&
        batchKey.didKeepBatchKeyAsHint &&
        batchKey.didAvoidPipelineBinding &&
        batchKey.didPreserveMaterialHint &&
        batchKey.commandKind.isRealDrawingOp == false &&
        batchKey.commandKind.didAvoidDrawCallBinding &&
        batchKey.shouldDeferRenderBatchKey == false &&
        batchKey.shouldReportRenderBatchKeyBlocked == false
    let batchKeyDeferred = batchKey.didPrepareRenderBatchKey == false &&
        batchKey.didKeepBatchKeyAsHint &&
        batchKey.didAvoidPipelineBinding &&
        batchKey.didPreserveMaterialHint == false &&
        batchKey.shouldDeferRenderBatchKey &&
        batchKey.shouldReportRenderBatchKeyBlocked == false
    let batchKeyInconsistent = (
        batchKey.didPrepareRenderBatchKey &&
            (
                batchKey.didKeepBatchKeyAsHint == false ||
                batchKey.didAvoidPipelineBinding == false ||
                batchKey.didPreserveMaterialHint == false ||
                batchKey.commandKind.isRealDrawingOp ||
                batchKey.commandKind.didAvoidDrawCallBinding == false ||
                batchKey.shouldDeferRenderBatchKey ||
                batchKey.shouldReportRenderBatchKeyBlocked
            )
        ) ||
        (batchKey.didPreserveMaterialHint && batchKey.didPrepareRenderBatchKey == false) ||
        (batchKey.shouldDeferRenderBatchKey && batchKey.shouldReportRenderBatchKeyBlocked)

    // batch key 不一致时必须 fail-closed，ordering hint 不执行排序副作用。
    if (batchKey.shouldReportRenderBatchKeyBlocked || batchKeyInconsistent) {
        return CjguiInternalRenderOrderingHint(
            batchKey,
            batchKey.zOrder,
            batchKey.clip,
            batchKey.sceneVersion,
            batchKey.commandListVersion,
            false,
            false,
            true,
            false,
            true,
            false
        )
    }

    if (batchKeyReady) {
        return CjguiInternalRenderOrderingHint(
            batchKey,
            batchKey.zOrder,
            batchKey.clip,
            batchKey.sceneVersion,
            batchKey.commandListVersion,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (batchKeyDeferred) {
        return CjguiInternalRenderOrderingHint(
            batchKey,
            batchKey.zOrder,
            batchKey.clip,
            batchKey.sceneVersion,
            batchKey.commandListVersion,
            false,
            false,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRenderOrderingHint(
        batchKey,
        batchKey.zOrder,
        batchKey.clip,
        batchKey.sceneVersion,
        batchKey.commandListVersion,
        false,
        false,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalBuildRenderBatchingPlan(
    commandPacket: CjguiInternalRenderCommandPacket,
    materialHint: CjguiInternalRenderMaterialHint,
    batchKey: CjguiInternalRenderBatchKey,
    orderingHint: CjguiInternalRenderOrderingHint
): CjguiInternalRenderBatchingPlan {
    let orderingReady = orderingHint.didPrepareRenderOrderingHint &&
        orderingHint.didPreserveCommandOrderingFacts &&
        orderingHint.didAvoidSortSideEffect &&
        orderingHint.didPreserveRenderBatchKey &&
        orderingHint.shouldDeferRenderOrderingHint == false &&
        orderingHint.shouldReportRenderOrderingHintBlocked == false
    let orderingDeferred = orderingHint.didPrepareRenderOrderingHint == false &&
        orderingHint.didAvoidSortSideEffect &&
        orderingHint.didPreserveRenderBatchKey == false &&
        orderingHint.shouldDeferRenderOrderingHint &&
        orderingHint.shouldReportRenderOrderingHintBlocked == false
    let orderingInconsistent = (
        orderingHint.didPrepareRenderOrderingHint &&
            (
                orderingHint.didPreserveCommandOrderingFacts == false ||
                orderingHint.didAvoidSortSideEffect == false ||
                orderingHint.didPreserveRenderBatchKey == false ||
                orderingHint.shouldDeferRenderOrderingHint ||
                orderingHint.shouldReportRenderOrderingHintBlocked
            )
        ) ||
        (orderingHint.didPreserveRenderBatchKey && orderingHint.didPrepareRenderOrderingHint == false) ||
        (orderingHint.shouldDeferRenderOrderingHint && orderingHint.shouldReportRenderOrderingHintBlocked)

    // ordering hint 不一致时必须 fail-closed，batching plan 不得变成真实合并或提交。
    if (orderingHint.shouldReportRenderOrderingHintBlocked || orderingInconsistent) {
        return CjguiInternalRenderBatchingPlan(
            commandPacket,
            materialHint,
            batchKey,
            orderingHint,
            commandPacket.commandListVersion,
            false,
            false,
            true,
            true,
            true,
            false,
            true,
            false
        )
    }

    if (orderingReady) {
        return CjguiInternalRenderBatchingPlan(
            commandPacket,
            materialHint,
            batchKey,
            orderingHint,
            commandPacket.commandListVersion,
            true,
            true,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (orderingDeferred) {
        return CjguiInternalRenderBatchingPlan(
            commandPacket,
            materialHint,
            batchKey,
            orderingHint,
            commandPacket.commandListVersion,
            false,
            false,
            true,
            true,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRenderBatchingPlan(
        commandPacket,
        materialHint,
        batchKey,
        orderingHint,
        commandPacket.commandListVersion,
        false,
        false,
        true,
        true,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalBuildRenderBatchingPacket(
    batchingPlan: CjguiInternalRenderBatchingPlan
): CjguiInternalRenderBatchingPacket {
    let planReady = batchingPlan.didPrepareRenderBatchingPlan &&
        batchingPlan.didUseFullRebuildBatchingPlan &&
        batchingPlan.didKeepPlanRendererAgnostic &&
        batchingPlan.didAvoidCommandMerge &&
        batchingPlan.didAvoidIncrementalBatchUpdate &&
        batchingPlan.didPreserveRenderCommandPacket &&
        batchingPlan.shouldDeferRenderBatchingPlan == false &&
        batchingPlan.shouldReportRenderBatchingPlanBlocked == false
    let planDeferred = batchingPlan.didPrepareRenderBatchingPlan == false &&
        batchingPlan.didUseFullRebuildBatchingPlan == false &&
        batchingPlan.didPreserveRenderCommandPacket == false &&
        batchingPlan.didKeepPlanRendererAgnostic &&
        batchingPlan.didAvoidCommandMerge &&
        batchingPlan.didAvoidIncrementalBatchUpdate &&
        batchingPlan.shouldDeferRenderBatchingPlan &&
        batchingPlan.shouldReportRenderBatchingPlanBlocked == false
    let planInconsistent = (
        batchingPlan.didPrepareRenderBatchingPlan &&
            (
                batchingPlan.didUseFullRebuildBatchingPlan == false ||
                batchingPlan.didKeepPlanRendererAgnostic == false ||
                batchingPlan.didAvoidCommandMerge == false ||
                batchingPlan.didAvoidIncrementalBatchUpdate == false ||
                batchingPlan.didPreserveRenderCommandPacket == false ||
                batchingPlan.shouldDeferRenderBatchingPlan ||
                batchingPlan.shouldReportRenderBatchingPlanBlocked
            )
        ) ||
        (batchingPlan.didPreserveRenderCommandPacket && batchingPlan.didPrepareRenderBatchingPlan == false) ||
        (batchingPlan.shouldDeferRenderBatchingPlan && batchingPlan.shouldReportRenderBatchingPlanBlocked)

    // batching plan 不一致时必须 fail-closed，packet 不得伪造成真实渲染输出。
    if (batchingPlan.shouldReportRenderBatchingPlanBlocked || planInconsistent) {
        return CjguiInternalRenderBatchingPacket(
            batchingPlan,
            batchingPlan.commandPacket.sceneVersion,
            batchingPlan.commandPacket.displayListVersion,
            batchingPlan.commandPacket.commandListVersion,
            false,
            true,
            true,
            true,
            false,
            true,
            false
        )
    }

    if (planReady) {
        return CjguiInternalRenderBatchingPacket(
            batchingPlan,
            batchingPlan.commandPacket.sceneVersion,
            batchingPlan.commandPacket.displayListVersion,
            batchingPlan.commandPacket.commandListVersion,
            true,
            true,
            true,
            true,
            false,
            false,
            true
        )
    }

    if (planDeferred) {
        return CjguiInternalRenderBatchingPacket(
            batchingPlan,
            batchingPlan.commandPacket.sceneVersion,
            batchingPlan.commandPacket.displayListVersion,
            batchingPlan.commandPacket.commandListVersion,
            false,
            true,
            true,
            true,
            true,
            false,
            false
        )
    }

    return CjguiInternalRenderBatchingPacket(
        batchingPlan,
        batchingPlan.commandPacket.sceneVersion,
        batchingPlan.commandPacket.displayListVersion,
        batchingPlan.commandPacket.commandListVersion,
        false,
        true,
        true,
        true,
        false,
        true,
        false
    )
}

func cjguiInternalExecuteDefaultRenderBatchingHintDraft(): CjguiInternalRenderBatchingPacket {
    // 默认 batching hint draft 只串联 command packet -> material / ordering / batching value facts；
    // 它不触发渲染、不执行排序、不做真实绘制合并，P1 仍保持 full rebuild。
    let commandPacket = cjguiInternalExecuteDefaultRenderCommandShapeDraft()
    let materialHint = cjguiInternalBuildRenderMaterialHint(commandPacket)
    let batchKey = cjguiInternalBuildRenderBatchKey(materialHint)
    let orderingHint = cjguiInternalBuildRenderOrderingHint(batchKey)
    let batchingPlan = cjguiInternalBuildRenderBatchingPlan(commandPacket, materialHint, batchKey, orderingHint)
    return cjguiInternalBuildRenderBatchingPacket(batchingPlan)
}
