package cjgui

// Internal declaration transport. The Cangjie packet keeps its existing
// cursors; this state owns only the one native request/completion identity.
class CjguiPreparationOperationState {
    var nonce: UInt64 = 0u64
    var kind: UInt32 = 0u32
    var capacity = false
    func clear(): Unit { nonce = 0u64; kind = 0u32; capacity = false }
}

class CjguiPreparationOperationData {
    let kind: UInt32
    var firstIndex: UInt32 = 0u32
    var nodes: Array<CjguiInternalRendererComposableNode> = []
    var geometry: Array<CjguiInternalRendererComposableGeometry> = []
    var strings: Array<String> = []
    let values = Array<UInt64>(32, repeat: 0u64)
    let signedValues = Array<Int64>(32, repeat: 0)
    init(kind: UInt32) { this.kind = kind }
}

@C
struct CjguiNativePreparationOperation {
    var kind: UInt32 = 0u32
    var firstIndex: UInt32 = 0u32
    var count: UInt32 = 0u32
    var stringCount: UInt32 = 0u32
    var values: CPointer<UInt64> = CPointer<UInt64>()
    var signedValues: CPointer<Int64> = CPointer<Int64>()
    var nodes: CPointer<CjguiInternalRendererComposableNode> = CPointer<CjguiInternalRendererComposableNode>()
    var geometry: CPointer<CjguiInternalRendererComposableGeometry> = CPointer<CjguiInternalRendererComposableGeometry>()
    var strings: CPointer<CString> = CPointer<CString>()
}

@C
struct CjguiPreparationOperationResult {
    var state: UInt32 = 0u32
    var stop: UInt32 = 0u32
    var status: Int32 = 0
    var prefix: UInt32 = 0u32
    var nonce: UInt64 = 0u64
    var requiredBytes: UInt64 = 0u64
    var generation: UInt64 = 0u64
}

@When[os == "macOS"]
foreign {
    func cjgui_internal_renderer_preparation_operation_admit(session: UInt64, preparation: UInt64,
        deadline: UInt64, operation: CPointer<CjguiNativePreparationOperation>,
        result: CPointer<CjguiPreparationOperationResult>): Int32
    func cjgui_internal_renderer_preparation_operation_poll(session: UInt64, preparation: UInt64,
        nonce: UInt64, consume: UInt8, result: CPointer<CjguiPreparationOperationResult>): Int32
    func cjgui_internal_renderer_preparation_operation_waiting(session: UInt64): UInt8
    func cjgui_internal_renderer_preparation_operation_retire(session: UInt64, preparation: UInt64): Unit
}

@When[os == "macOS"]
func internalRendererPreparationOperationWaiting(session: UInt64): Bool {
    return unsafe { cjgui_internal_renderer_preparation_operation_waiting(session) != 0u8 }
}
@When[os != "macOS"]
func internalRendererPreparationOperationWaiting(session: UInt64): Bool { return false }

@When[os == "macOS"]
func internalRendererRetirePreparationOperation(session: UInt64, preparation: UInt64): Unit {
    unsafe { cjgui_internal_renderer_preparation_operation_retire(session, preparation) }
}
@When[os != "macOS"]
func internalRendererRetirePreparationOperation(session: UInt64, preparation: UInt64): Unit {
    let _ = internalRendererCancelComposablePreparation(session, preparation)
}

@When[os == "macOS"]
func internalRendererStepPreparationOperation(session: UInt64, preparation: UInt64,
    deadline: UInt64, state: CjguiPreparationOperationState,
    data: CjguiPreparationOperationData): CjguiPreparationOperationResult {
    var result = CjguiPreparationOperationResult()
    // A pending packet already owns its complete payload. Poll before payload
    // validation so the caller need not reconstruct/copy the same arrays.
    if (state.nonce != 0u64) {
        if (state.kind != data.kind) {
            result.state = 4u32; result.status = CJGUI_INTERNAL_RENDERER_SCENE_STALE
            return result
        }
        let status = unsafe { cjgui_internal_renderer_preparation_operation_poll(session,
            preparation, state.nonce, 1u8, inout result) }
        if (status != CJGUI_INTERNAL_RENDERER_OK) { result.status = status; result.state = 2u32 }
        if (result.state != 1u32) { state.clear() }
        return result
    }
    if ((data.kind == 2u32 || data.kind == 3u32 || data.kind == 9u32) &&
        (data.nodes.size <= 0 || data.nodes.size > 8 || data.geometry.size != data.nodes.size ||
         data.strings.size != data.nodes.size * 9) ||
        (data.kind == 6u32 && data.strings.size != 2) ||
        (data.kind == 8u32 && data.strings.size != 4)) {
        result.state = 2u32; result.status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        return result
    }
    var raw = CjguiNativePreparationOperation()
    raw.kind = data.kind; raw.firstIndex = data.firstIndex
    raw.count = UInt32(data.nodes.size); raw.stringCount = UInt32(data.strings.size)
    let status = unsafe {
        let nodes = acquireArrayRawData(data.nodes)
        let geometry = acquireArrayRawData(data.geometry)
        let values = acquireArrayRawData(data.values)
        let signedValues = acquireArrayRawData(data.signedValues)
        let strings = LibC.malloc<CString>(count: max(1, data.strings.size))
        var filled: Int64 = 0
        try {
            for (text in data.strings) {
                strings.write(filled, LibC.mallocCString(text)); filled += 1
            }
            raw.nodes = nodes.pointer; raw.geometry = geometry.pointer
            raw.values = values.pointer; raw.signedValues = signedValues.pointer; raw.strings = strings
            cjgui_internal_renderer_preparation_operation_admit(session, preparation, deadline,
                inout raw, inout result)
        } finally {
            for (i in 0..filled) { LibC.free(strings.read(i)) }
            LibC.free(strings)
            releaseArrayRawData(signedValues); releaseArrayRawData(values)
            releaseArrayRawData(geometry); releaseArrayRawData(nodes)
        }
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK) { result.status = status; result.state = 2u32 }
    if (result.state == 1u32) { state.nonce = result.nonce; state.kind = data.kind }
    state.capacity = result.state == 3u32
    return result
}

// Other platforms keep their existing synchronous preparation implementation.
// Its zero reuse prefix is the existing completed cache miss, never pending.
@When[os != "macOS"]
func internalRendererStepPreparationOperation(session: UInt64, preparation: UInt64,
    deadline: UInt64, state: CjguiPreparationOperationState,
    data: CjguiPreparationOperationData): CjguiPreparationOperationResult {
    var result = CjguiPreparationOperationResult(); result.state = 2u32
    if (data.kind == 1u32) {
        result.status = internalRendererBeginComposablePreparation(session, preparation,
            data.values[0], data.values[1], UInt32(data.values[2]))
    } else if (data.kind == 2u32 || data.kind == 3u32) {
        let (status, prefix) = if (data.kind == 3u32) {
            internalRendererReuseComposableNodeBatch(session, preparation, data.firstIndex,
                data.nodes, data.geometry, deadline)
        } else {
            let strings = Array<String>(data.nodes.size * 8, { i => data.strings[i / 8 * 9 + i % 8] })
            internalRendererPrepareComposableNodeBatch(session, preparation, data.firstIndex,
                data.nodes, data.geometry, strings, deadline)
        }
        result.status = status; result.prefix = prefix
        if (status == CJGUI_INTERNAL_RENDERER_OK && Int64(prefix) < data.nodes.size) {
            result.stop = if (data.kind == 3u32) { 1u32 } else { 2u32 }
        }
        for (i in 0..Int64(prefix)) {
            if (!data.strings[i * 9 + 8].isEmpty()) {
                result.status = internalRendererSetComposableSemanticHelp(session, preparation,
                    data.firstIndex + UInt32(i), data.strings[i * 9 + 8])
                if (result.status != CJGUI_INTERNAL_RENDERER_OK) { break }
            }
        }
    } else if (data.kind == 6u32) {
        result.status = internalRendererPrepareComposableImageResource(session, preparation,
            data.firstIndex, data.strings[0], data.strings[1], data.values[0])
    } else {
        result.status = CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED
    }
    return result
}

@When[os == "macOS"]
func internalRendererUsesOwnedPreparationOperations(): Bool { return true }
@When[os != "macOS"]
func internalRendererUsesOwnedPreparationOperations(): Bool { return false }
