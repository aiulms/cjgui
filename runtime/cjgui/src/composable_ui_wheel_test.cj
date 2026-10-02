package cjgui

import std.math.*

@Test
func wheelTransportPreservesSegmentationAndZeroTerminal(): Unit {
    var points = 0.0
    for (_ in 0..58) {
        let value = cjguiParseWheelDelta("cjgui-wheel-v1|0.00000000000000000|-1.00000000000000000|1|4|0")
        @Assert(value.isSome())
        if (let Some(delta) <- value) { points += delta.deltaY; @Assert(delta.isPrecise) }
    }
    if (let Some(single) <- cjguiParseWheelDelta("cjgui-wheel-v1|0|-58|1|1|0")) {
        @Assert(points, single.deltaY)
    } else { @Assert(false) }
    if (let Some(end) <- cjguiParseWheelDelta("cjgui-wheel-v1|0|0|1|8|0")) {
        @Assert(end.isTerminal() && !end.hasDelta())
        @Assert(end.legacyText(), "")
    } else { @Assert(false) }
}

@Test
func wheelTransportKeepsPointUnitsAndIndependentMomentum(): Unit {
    if (let Some(delta) <- cjguiParseWheelDelta("cjgui-wheel-v1|0.125|-0.01000000000000000|1|0|4")) {
        @Assert(abs(delta.deltaY + 0.01) < 0.000000000001)
        @Assert(delta.phase, 0)
        @Assert(delta.momentumPhase, 4)
        @Assert(!delta.isTerminal() && !delta.beginsGesture())
    } else { @Assert(false) }
    if (let Some(coarse) <- cjguiParseWheelDelta("cjgui-wheel-v1|2|-3|0|0|0")) {
        @Assert(!coarse.isPrecise)
        @Assert(coarse.legacyText(), "next")
    } else { @Assert(false) }
}

@Test
func wheelTransportRefusesMalformedUnboundedAndNonfiniteInputs(): Unit {
    for (text in ["next", "cjgui-wheel-v2|0|1|1|4|0", "cjgui-wheel-v1|nan|1|1|4|0",
        "cjgui-wheel-v1|0|inf|1|4|0", "cjgui-wheel-v1|0|1e-2|1|4|0",
        "cjgui-wheel-v1|0|1000001|1|4|0", "cjgui-wheel-v1|0|1|2|4|0",
        "cjgui-wheel-v1|0|1|1|64|0", "cjgui-wheel-v1|0|1|1|4|128",
        "cjgui-wheel-v1|0|1|1|4|0|extra", "cjgui-wheel-v1|0|-|1|4|0"]) {
        @Assert(cjguiParseWheelDelta(text).isNone())
    }
}
