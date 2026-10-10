package cjgui

/// Experimental opt-in separation of advisory progress from preparation
/// invalidation. Every owner/source, editing, selection, input route, command,
/// theme, layout or lifetime change must advance this nonnegative identity.
/// Only informational progress in a fixed, noninteractive region may change
/// uiSceneVersion alone. The current frozen frame completes first; the existing
/// UI revision then schedules its successor. Legacy controllers remain strict.
public interface CjguiComposableUiPreparationDependencyProvider {
    func uiPreparationDependencyVersion(): Int64
}

func cjguiRetainedPreparationDeclarationMatches(frozenDeclared: Int64, currentDeclared: Int64,
    frozenDependency: ?Int64, currentDependency: ?Int64): Bool {
    if (frozenDependency.isNone() && currentDependency.isNone()) {
        return frozenDeclared == currentDeclared
    }
    if (frozenDependency.isNone() || currentDependency.isNone()) { return false }
    let frozen = frozenDependency.getOrThrow(); let current = currentDependency.getOrThrow()
    return frozen >= 0 && current >= 0 && frozen == current
}
