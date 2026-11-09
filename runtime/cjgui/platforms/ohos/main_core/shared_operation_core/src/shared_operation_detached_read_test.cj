package cjgui_shared_operation_core

import std.unittest.*
import std.unittest.testmacro.*

@Test
func detachedReadBudgetRetainsOldGenerationUntilHolderReleases(): Unit {
    let budget = CjguiDetachedReadBudget()
    @Assert(budget.configure(2 * (16 * 65536 + 8192 + 98)), true)
    let old = budget.reserve(1, 2, 98, 65536).getOrThrow()
    let current = budget.reserve(2, 2, 98, 65536).getOrThrow()
    let held = budget.snapshot()[1]
    @Assert(budget.configure(0), false)
    @Assert(budget.reserve(3, 2, 98, 65536).isNone(), true)
    old.release()
    @Assert(budget.snapshot()[1], held - old.bytes)
    let next = budget.reserve(3, 2, 98, 65536).getOrThrow()
    old.release()
    @Assert(budget.snapshot()[1], current.bytes + next.bytes)
    current.release(); next.release()
    @Assert(budget.snapshot()[1], 0)
    @Assert(budget.snapshot()[3], 0)
    @Assert(budget.snapshot()[5], 3)
}

@Test
func detachedReadOwnsIndependentBoundedUtf8(): Unit {
    let bytes = "Hi中😀".toArray()
    let text = String.fromUtf8(bytes)
    bytes[0] = b'Z'
    @Assert(text, "Hi中😀")
    let range = CjguiSharedOperationRangeRead(true, false, 901, 0, 0, text.size, text, "none")
    let value = CjguiDetachedRangeValue(range, 901, 0, text.size)
    @Assert(value.range.content, "Hi中😀")
    @Assert(value.range.start, 0)
    @Assert(value.range.end, text.size)
}

@Test
func detachedReadResponseDropsMaterialAndReturnsReservationOnce(): Unit {
    let budget = CjguiDetachedReadBudget()
    let reservation = budget.reserve(1, 2, 98, 1).getOrThrow()
    let range = CjguiSharedOperationRangeRead(true, false, 901, 0, 0, 1, "X", "none")
    let reply = CjguiSharedOperationPendingResponse(CjguiDetachedRangeValue(range, 901, 0, 1), reservation)
    @Assert(reply.takeRange().getOrThrow().range.content, "X")
    @Assert(reply.takeRange().isNone(), true)
    reply.discard(); reply.discard()
    @Assert(budget.snapshot()[1], 0)
    @Assert(budget.snapshot()[5], 1)
}
