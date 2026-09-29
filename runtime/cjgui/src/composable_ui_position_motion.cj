package cjgui

/// A node's local post-layout translation, in logical points. The accepted
/// scene resolves parent translations and clip owners from these local values.
/// Stability: experimental.
public class CjguiComposableUiPositionValue {
    public let x: Float64
    public let y: Float64
    public init(x: Float64, y: Float64) {
        this.x = x
        this.y = y
    }
}

/// Bounded readback of one accepted motion binding. Target is the requested
/// local translation; presented is the last native-accepted local value.
/// Frame identity comes from the same window observation as the scene.
/// Stability: experimental.
public class CjguiComposableUiPositionStatus {
    public let target: CjguiComposableUiPositionValue
    public let presented: CjguiComposableUiPositionValue
    public let binding: CjguiComposableUiAnimationBinding
    public let sessionIdentity: String
    public let acceptedSceneVersion: Int64
    public let submittedFrameIndex: Int64
    public let active: Bool
    public init(target: CjguiComposableUiPositionValue, presented: CjguiComposableUiPositionValue,
        binding: CjguiComposableUiAnimationBinding, sessionIdentity: String,
        acceptedSceneVersion: Int64, submittedFrameIndex: Int64, active: Bool) {
        this.target = target
        this.presented = presented
        this.binding = binding
        this.sessionIdentity = sessionIdentity
        this.acceptedSceneVersion = acceptedSceneVersion
        this.submittedFrameIndex = submittedFrameIndex
        this.active = active
    }
}

/// Immutable candidate sample. Its velocity belongs to this exact position
/// and may become a retarget start only after that sample is accepted.
class CjguiComposableUiPositionSample {
    let identityKey: String
    let binding: CjguiComposableUiAnimationBinding
    let value: CjguiComposableUiPositionValue
    let velocity: CjguiComposableUiPositionValue
    let revision: Int64
    let channelGeneration: Int64
    init(identityKey: String, binding: CjguiComposableUiAnimationBinding,
        value: CjguiComposableUiPositionValue, velocity: CjguiComposableUiPositionValue,
        revision: Int64, channelGeneration!: Int64 = 0) {
        this.identityKey = identityKey
        this.binding = binding
        this.value = value
        this.velocity = velocity
        this.revision = revision
        this.channelGeneration = channelGeneration
    }
}

/// One accepted identity with two P2 scalar channels. Scalar values are
/// speculative; `acceptedValue` advances only with an accepted scene sample.
class CjguiComposableUiNodePositionAnimation {
    let identityKey: String
    let binding: CjguiComposableUiAnimationBinding
    private var x: CjguiComposableUiScalarAnimation
    private var y: CjguiComposableUiScalarAnimation
    private var acceptedX: Float64
    private var acceptedY: Float64
    private var acceptedVelocityX: Float64
    private var acceptedVelocityY: Float64
    private var sampleRevision: Int64
    private var acceptedRevision: Int64
    private let channelGeneration: Int64

    init(identityKey: String, binding: CjguiComposableUiAnimationBinding,
        x: CjguiComposableUiScalarAnimation, y: CjguiComposableUiScalarAnimation,
        accepted: CjguiComposableUiPositionValue, channelGeneration!: Int64 = 0) {
        this.identityKey = identityKey
        this.binding = binding
        this.x = x
        this.y = y
        this.acceptedX = accepted.x
        this.acceptedY = accepted.y
        this.acceptedVelocityX = 0.0
        this.acceptedVelocityY = 0.0
        this.sampleRevision = 1
        this.acceptedRevision = 0
        this.channelGeneration = channelGeneration
    }

    func sample(): CjguiComposableUiPositionSample {
        return CjguiComposableUiPositionSample(identityKey, binding,
            CjguiComposableUiPositionValue(x.presented(), y.presented()),
            CjguiComposableUiPositionValue(x.velocity(), y.velocity()), sampleRevision,
            channelGeneration: channelGeneration)
    }
    func target(): CjguiComposableUiPositionValue {
        return CjguiComposableUiPositionValue(x.target(), y.target())
    }
    func accepted(): CjguiComposableUiPositionValue {
        return CjguiComposableUiPositionValue(acceptedX, acceptedY)
    }
    func isActive(): Bool { return x.isActive() || y.isActive() }
    func lastTime(): Float64 { return x.lastTime() }
    func matchesSpec(spec: CjguiComposableUiAnimationSpec): Bool {
        let old = x.spec()
        return old.kind == spec.kind && old.durationMs == spec.durationMs && old.easing == spec.easing &&
            old.stiffness == spec.stiffness && old.dampingRatio == spec.dampingRatio
    }
    /// Rebuild both axes before mutation. A failed input leaves both channels
    /// untouched. The successful accepted checkpoint is the start, even if an
    /// earlier frame advanced but native rejected its scene.
    func retarget(target: CjguiComposableUiPositionValue, spec: CjguiComposableUiAnimationSpec,
        nowMs: Float64): Bool {
        if (target.x == x.target() && target.y == y.target() && matchesSpec(spec)) { return true }
        if (nowMs < lastTime()) { return false }
        let nextX = match (CjguiComposableUiScalarAnimation.retuned(acceptedX, target.x,
            acceptedVelocityX, nowMs, spec)) {
            case Some(value) => value
            case None => return false
        }
        let nextY = match (CjguiComposableUiScalarAnimation.retuned(acceptedY, target.y,
            acceptedVelocityY, nowMs, spec)) {
            case Some(value) => value
            case None => return false
        }
        x = nextX
        y = nextY
        sampleRevision += 1
        return true
    }
    func advanceTo(nowMs: Float64): Bool {
        let oldX = x.presented()
        let oldY = y.presented()
        let nextX = x.advanceTo(nowMs)
        let nextY = y.advanceTo(nowMs)
        // A spring can overshoot a legal target. An intermediate that cannot
        // enter the bounded scene must not keep retrying an invalid frame.
        if (!cjguiAnimationIsFiniteScalar(nextX) || !cjguiAnimationIsFiniteScalar(nextY) ||
            nextX < -1024.0 || nextX > 1024.0 || nextY < -1024.0 || nextY > 1024.0) {
            x.converge()
            y.converge()
        }
        if (oldX != x.presented() || oldY != y.presented()) {
            sampleRevision += 1
            return true
        }
        return false
    }
    func converge(): Bool {
        let changed = x.presented() != x.target() || y.presented() != y.target()
        x.converge()
        y.converge()
        if (changed) { sampleRevision += 1 }
        return changed
    }
    func accept(sample: CjguiComposableUiPositionSample, nowMs: Float64): Unit {
        if (!binding.matches(sample.binding)) { return }
        let sameChannel = sample.channelGeneration == channelGeneration
        if (sameChannel && sample.revision < acceptedRevision) { return }
        acceptedX = sample.value.x
        acceptedY = sample.value.y
        acceptedVelocityX = if (sameChannel) { sample.velocity.x } else { 0.0 }
        acceptedVelocityY = if (sameChannel) { sample.velocity.y } else { 0.0 }
        if (sameChannel) { acceptedRevision = sample.revision }
        // A newer target may have been requested while this native ticket was
        // pending. Rebase it on the picture that actually won acceptance.
        if (!sameChannel || sample.revision < sampleRevision) {
            let targetX = x.target()
            let targetY = y.target()
            if (let Some(nextX) <- CjguiComposableUiScalarAnimation.retuned(acceptedX, targetX,
                acceptedVelocityX, nowMs, x.spec())) {
                if (let Some(nextY) <- CjguiComposableUiScalarAnimation.retuned(acceptedY, targetY,
                    acceptedVelocityY, nowMs, y.spec())) {
                    x = nextX
                    y = nextY
                    sampleRevision += 1
                }
            }
        }
    }
    func stopAtAccepted(nowMs: Float64): Unit {
        if (let Some(nextX) <- CjguiComposableUiScalarAnimation.tweened(acceptedX, acceptedX, nowMs)) {
            x = nextX
        }
        if (let Some(nextY) <- CjguiComposableUiScalarAnimation.tweened(acceptedY, acceptedY, nowMs)) {
            y = nextY
        }
        sampleRevision += 1
    }
}
