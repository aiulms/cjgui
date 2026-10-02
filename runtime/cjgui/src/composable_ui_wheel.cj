package cjgui

/// Experimental wheel input in logical points when precise, platform row/line
/// units otherwise. These are observed deltas, not an animation or velocity.
/// phase and momentumPhase retain the AppKit bitset independently: began=1,
/// stationary=2, changed=4, ended=8, cancelled=16, mayBegin=32. Native objects
/// and event storage remain private; the containing event supplies the accepted
/// node/resource/projection identity.
public class CjguiComposableUiWheelDelta {
    public let deltaX: Float64
    public let deltaY: Float64
    public let isPrecise: Bool
    public let phase: Int64
    public let momentumPhase: Int64
    public init(deltaX: Float64, deltaY: Float64, isPrecise: Bool, phase: Int64, momentumPhase: Int64) {
        this.deltaX = deltaX
        this.deltaY = deltaY
        this.isPrecise = isPrecise
        this.phase = phase
        this.momentumPhase = momentumPhase
    }
    public func isTerminal(): Bool { return ((phase | momentumPhase) & 24) != 0 }
    public func beginsGesture(): Bool { return (phase & 1) != 0 }
    public func hasDelta(): Bool { return deltaX != 0.0 || deltaY != 0.0 }
    public func legacyText(): String {
        return if (deltaY < 0.0) { "next" } else if (deltaY > 0.0) { "previous" } else { "" }
    }
}

/// Opt in per accepted declaration. Other controllers keep the existing
/// next/previous vocabulary and never receive a zero-delta terminal as a step.
public interface CjguiComposableUiWheelDeltaConsumer {
    func consumesWheelDelta(node: CjguiComposableUiLayoutNode): Bool
}

// Bounded private transport over the existing FIFO formText. Decimal parsing
// refuses exponents, non-finite values, excess digits and unknown phase bits;
// no pointer field or native Node/Event ABI is repurposed.
private func cjguiWheelDecimal(token: String): ?Float64 {
    if (token.size == 0 || token.size > 28) { return None }
    var negative = false
    var dot = false
    var wholeDigits = 0
    var fractionDigits = 0
    var whole = 0.0
    var fraction = 0.0
    var divisor = 1.0
    var index = 0
    for (byte in token.toArray()) {
        if (index == 0 && byte == 45) { negative = true }
        else if (byte == 46 && !dot && wholeDigits > 0) { dot = true }
        else if (byte >= 48 && byte <= 57) {
            if (dot) {
                fractionDigits += 1
                if (fractionDigits > 17) { return None }
                fraction = fraction * 10.0 + Float64(byte - 48)
                divisor *= 10.0
            } else {
                wholeDigits += 1
                if (wholeDigits > 7) { return None }
                whole = whole * 10.0 + Float64(byte - 48)
            }
        } else { return None }
        index += 1
    }
    if (wholeDigits == 0 || (dot && fractionDigits == 0)) { return None }
    let value = whole + fraction / divisor
    if (!cjguiAnimationIsFiniteScalar(value) || value > 1000000.0) { return None }
    return Some(if (negative) { -value } else { value })
}

private func cjguiWheelPhase(token: String): ?Int64 {
    if (token.size == 0 || token.size > 2) { return None }
    var value: Int64 = 0
    for (byte in token.toArray()) {
        if (byte < 48 || byte > 57) { return None }
        value = value * 10 + Int64(byte - 48)
    }
    return if (value <= 63) { Some(value) } else { None }
}

func cjguiParseWheelDelta(text: String): ?CjguiComposableUiWheelDelta {
    if (text.size > 96) { return None }
    let fields = text.split("|")
    if (fields.size != 6 || fields[0] != "cjgui-wheel-v1" ||
        (fields[3] != "0" && fields[3] != "1")) { return None }
    let x = match (cjguiWheelDecimal(fields[1])) { case Some(v) => v; case None => return None }
    let y = match (cjguiWheelDecimal(fields[2])) { case Some(v) => v; case None => return None }
    let phase = match (cjguiWheelPhase(fields[4])) { case Some(v) => v; case None => return None }
    let momentum = match (cjguiWheelPhase(fields[5])) { case Some(v) => v; case None => return None }
    return Some(CjguiComposableUiWheelDelta(x, y, fields[3] == "1", phase, momentum))
}
