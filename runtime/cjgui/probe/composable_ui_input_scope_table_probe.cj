package cjgui

// Regression for compact native focus-scope codes.  The assignment order is
// observable by the native scene, so the table must retain first-seen codes
// while avoiding a linear scan for each of a complex tree's siblings.
main(args: Array<String>): Int64 {
    if (args.size != 0) {
        return 2
    }
    let table = CjguiComposableUiNativeInputScopeTable()
    if (table.codeFor("") != 0u64) {
        return 3
    }
    var index: Int64 = 0
    while (index < 480) {
        if (table.codeFor("scope-${index}") != UInt64(index + 1)) {
            return 4
        }
        index += 1
    }
    if (table.codeFor("scope-0") != 1u64 || table.codeFor("scope-479") != 480u64 || table.codeFor("scope-after") !=
        481u64) {
        return 5
    }
    println("cjgui composable input scope table probe: passed")
    return 0
}
