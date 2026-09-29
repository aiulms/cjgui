package cjgui

import std.collection.*
import std.overflow.*

/// An accepted clip and the innermost-to-outermost scroll prefix that can move
/// the target relative to that clip. -1 means the clip moves with the target.
class CjguiComposableUiRevealClip {
    let rect: CjguiComposableUiRect
    let scrollPrefix: Int64
    init(rect: CjguiComposableUiRect, scrollPrefix: Int64) {
        this.rect = rect
        this.scrollPrefix = scrollPrefix
    }
}

class CjguiComposableUiRevealPlan {
    let reason: String
    let offsets: ArrayList<Int64>
    init(reason: String, offsets: ArrayList<Int64>) {
        this.reason = reason
        this.offsets = offsets
    }
    func isReachable(): Bool {
        return reason != "reveal_unreachable" && reason != "reveal_geometry_invalid"
    }
}

/// Resolve the whole accepted clip chain before changing any viewport request.
/// The preferred pending offsets survive when feasible; an incompatible inner
/// request is replaced so focus cannot begin outside its own accepted clip.
class CjguiComposableUiRevealPlanner {
    private static func bounded(value: Int64, lower: Int64, upper: Int64): Int64 {
        if (value < lower) {
            return lower
        }
        if (value > upper) {
            return upper
        }
        return value
    }
    static func plan(target: CjguiComposableUiRect, clips: ArrayList<CjguiComposableUiRevealClip>,
        acceptedOffsets: ArrayList<Int64>, maximumOffsets: ArrayList<Int64>, preferredOffsets!: ?ArrayList<Int64> = None): CjguiComposableUiRevealPlan {
        let count = acceptedOffsets.size
        let empty = ArrayList<Int64>()
        if (count != maximumOffsets.size || target.width <= 0 || target.height <= 0) {
            return CjguiComposableUiRevealPlan("reveal_geometry_invalid", empty)
        }
        let preferences = match (preferredOffsets) {
            case Some(value) => value
            case None => ArrayList<Int64>(acceptedOffsets)
        }
        if (preferences.size != count) {
            return CjguiComposableUiRevealPlan("reveal_geometry_invalid", empty)
        }
        let allowedLow = ArrayList<Int64>()
        let allowedHigh = ArrayList<Int64>()
        var index: Int64 = 0
        while (index < count) {
            allowedLow.add(-2000000000)
            allowedHigh.add(2000000000)
            index += 1
        }
        for (clip in clips) {
            if (clip.rect.width <= 0 || clip.rect.height <= 0 || clip.scrollPrefix < -1 || clip.scrollPrefix >= count) {
                return CjguiComposableUiRevealPlan("reveal_geometry_invalid", empty)
            }
            if (target.x >= clip.rect.x + clip.rect.width || target.x + target.width <= clip.rect.x) {
                return CjguiComposableUiRevealPlan("reveal_unreachable", empty)
            }
            let lower = target.y + target.height - clip.rect.y - clip.rect.height
            let upper = target.y - clip.rect.y
            if (clip.scrollPrefix < 0) {
                if (lower > 0 || upper < 0) {
                    return CjguiComposableUiRevealPlan("reveal_unreachable", empty)
                }
            } else {
                let slot = clip.scrollPrefix
                if (lower > allowedLow[slot]) {
                    allowedLow[slot] = lower
                }
                if (upper < allowedHigh[slot]) {
                    allowedHigh[slot] = upper
                }
            }
        }
        let reachLow = ArrayList<Int64>()
        let reachHigh = ArrayList<Int64>()
        var previousLow: Int64 = 0
        var previousHigh: Int64 = 0
        index = 0
        while (index < count) {
            let accepted = acceptedOffsets[index]
            let maximum = maximumOffsets[index]
            let preferred = preferences[index]
            if (accepted < 0 || maximum < accepted || preferred < 0 || preferred > maximum) {
                return CjguiComposableUiRevealPlan("reveal_geometry_invalid", empty)
            }
            let deltaMin = -accepted
            let deltaMax = maximum - accepted
            let fromLower = previousLow.saturatingAdd(deltaMin)
            let fromUpper = previousHigh.saturatingAdd(deltaMax)
            let lower = if (allowedLow[index] > fromLower) {
                allowedLow[index]
            } else {
                fromLower
            }
            let upper = if (allowedHigh[index] < fromUpper) {
                allowedHigh[index]
            } else {
                fromUpper
            }
            if (lower > upper) {
                return CjguiComposableUiRevealPlan("reveal_unreachable", empty)
            }
            reachLow.add(lower)
            reachHigh.add(upper)
            previousLow = lower
            previousHigh = upper
            index += 1
        }
        let desired = ArrayList<Int64>()
        index = 0
        while (index < count) {
            desired.add(preferences[index]);
            index += 1
        }
        if (count > 0) {
            var preferredTotalDelta: Int64 = 0
            index = 0
            while (index < count) {
                preferredTotalDelta = preferredTotalDelta.saturatingAdd(preferences[index] - acceptedOffsets[index])
                index += 1
            }
            var sum = bounded(preferredTotalDelta, reachLow[count - 1], reachHigh[count - 1])
            index = count - 1
            while (index >= 0) {
                let priorLow = if (index > 0) {
                    reachLow[index - 1]
                } else {
                    0
                }
                let priorHigh = if (index > 0) {
                    reachHigh[index - 1]
                } else {
                    0
                }
                let deltaMin = -acceptedOffsets[index]
                let deltaMax = maximumOffsets[index] - acceptedOffsets[index]
                let feasibleLow = if (priorLow > sum - deltaMax) {
                    priorLow
                } else {
                    sum - deltaMax
                }
                let feasibleHigh = if (priorHigh < sum - deltaMin) {
                    priorHigh
                } else {
                    sum - deltaMin
                }
                if (feasibleLow > feasibleHigh) {
                    return CjguiComposableUiRevealPlan("reveal_unreachable", empty)
                }
                let preferredPrior = sum - (preferences[index] - acceptedOffsets[index])
                let prior = bounded(preferredPrior, feasibleLow, feasibleHigh)
                desired[index] = acceptedOffsets[index] + sum - prior
                sum = prior
                index -= 1
            }
        }
        var changed = false
        index = 0
        while (index < count) {
            if (desired[index] != acceptedOffsets[index]) {
                changed = true
            }
            index += 1
        }
        return CjguiComposableUiRevealPlan(if (changed) {
            "reveal_requested"
        } else {
            "reveal_visible"
        }, desired)
    }
}
