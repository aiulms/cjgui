package cjgui

/// Experimental read-only identity of one actually dequeued installed-source
/// selector. Only the window can construct it. It grants no screen geometry.
public class CjguiInstalledTextIntentProof {
    public let completed: CjguiInstalledSelectionCompletion
    public let rendererSessionGeneration: UInt64
    public let sequence: UInt64
    public let previousSequence: UInt64
    public let direction: String
    public let modifierFlags: Int64
    let nativeSource: Array<Int64>
    init(completed: CjguiInstalledSelectionCompletion, input: InternalRendererInputProvenance,
        direction: String, modifiers: Int64, nativeSource: Array<Int64>) {
        this.completed = completed; this.rendererSessionGeneration = input.sessionGeneration
        this.sequence = input.sequence; this.previousSequence = input.previousSequence
        this.direction = direction; this.modifierFlags = modifiers; this.nativeSource = nativeSource
    }
}

/// Experimental opt-in owner consumer. Ordinary accepted text surfaces keep
/// their existing plain/visual route. A proof never substitutes a LayoutNode.
public interface CjguiComposableUiInstalledTextIntentProvider {
    func applyInstalledTextIntent(proof: CjguiInstalledTextIntentProof): CjguiComposableUiDispatchResult
}
