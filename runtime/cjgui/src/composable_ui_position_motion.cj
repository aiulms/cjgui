package cjgui

func positionCoordinateAfterDeltaAllowed(value: Float64, delta: Float64): Bool {
    if (!cjguiAnimationIsFiniteScalar(value) || !cjguiAnimationIsFiniteScalar(delta)) {
        return false
    }
    let shifted = value + delta
    return cjguiAnimationIsFiniteScalar(shifted) && shifted >= -1024.0 && shifted <= 1024.0
}

/// Window-issued capability for one accepted position channel's coordinate
/// origin. The ticket is public only so status can return it; its constructor
/// and fields stay package-private so callers cannot forge or edit it.
public class CjguiComposableUiPositionOriginTicket {
    let identityKey: String
    let binding: CjguiComposableUiAnimationBinding
    let sessionIdentity: String
    let acceptedSceneVersion: Int64
    let geometryRevision: Int64
    let channelGeneration: Int64
    let originRevision: Int64
    let requestRevision: Int64

    init(identityKey: String, binding: CjguiComposableUiAnimationBinding, sessionIdentity: String,
        acceptedSceneVersion: Int64, geometryRevision: Int64, channelGeneration: Int64, originRevision: Int64,
        requestRevision: Int64) {
        this.identityKey = identityKey
        this.binding = binding
        this.sessionIdentity = sessionIdentity
        this.acceptedSceneVersion = acceptedSceneVersion
        this.geometryRevision = geometryRevision
        this.channelGeneration = channelGeneration
        this.originRevision = originRevision
        this.requestRevision = requestRevision
    }

    func matches(other: CjguiComposableUiPositionOriginTicket): Bool {
        return identityKey == other.identityKey && binding.matches(other.binding) && sessionIdentity == other
            .sessionIdentity && acceptedSceneVersion == other.acceptedSceneVersion && geometryRevision == other
            .geometryRevision && channelGeneration == other.channelGeneration && originRevision == other.originRevision &&
            requestRevision == other.requestRevision
    }
}

/// Driver-verifiable readback for a position channel's current generation and
/// coordinate system. Session, scene, geometry, and request admission remain
/// owned by the window.
class CjguiComposableUiPositionOriginState {
    let channelGeneration: Int64
    let originRevision: Int64
    init(channelGeneration: Int64, originRevision: Int64) {
        this.channelGeneration = channelGeneration
        this.originRevision = originRevision
    }
}

/// The coordinate delta attached to one window candidate. Equal tickets and
/// equal compensation identify the same idempotent operation.
class CjguiComposableUiPositionOriginRebase {
    let ticket: CjguiComposableUiPositionOriginTicket
    let compensation: CjguiComposableUiPositionValue
    init(ticket: CjguiComposableUiPositionOriginTicket, compensation: CjguiComposableUiPositionValue) {
        this.ticket = ticket
        this.compensation = compensation
    }

    func matches(other: CjguiComposableUiPositionOriginRebase): Bool {
        return ticket.matches(other.ticket) && compensation.x == other.compensation.x && compensation.y == other
            .compensation
            .y
    }
}

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
    public let originTicket: ?CjguiComposableUiPositionOriginTicket
    public init(target: CjguiComposableUiPositionValue, presented: CjguiComposableUiPositionValue,
        binding: CjguiComposableUiAnimationBinding, sessionIdentity: String,
        acceptedSceneVersion: Int64, submittedFrameIndex: Int64, active: Bool, originTicket!: ?CjguiComposableUiPositionOriginTicket = None) {
        this.target = target
        this.presented = presented
        this.binding = binding
        this.sessionIdentity = sessionIdentity
        this.acceptedSceneVersion = acceptedSceneVersion
        this.submittedFrameIndex = submittedFrameIndex
        this.active = active
        this.originTicket = originTicket
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
    let originRevision: Int64
    init(identityKey: String, binding: CjguiComposableUiAnimationBinding,
        value: CjguiComposableUiPositionValue, velocity: CjguiComposableUiPositionValue,
        revision: Int64, channelGeneration!: Int64 = 0,
        originRevision!: Int64 = 0) {
        this.identityKey = identityKey
        this.binding = binding
        this.value = value
        this.velocity = velocity
        this.revision = revision
        this.channelGeneration = channelGeneration
        this.originRevision = originRevision
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
    private var originRevision: Int64

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
        this.originRevision = 0
    }

    func sample(): CjguiComposableUiPositionSample {
        return CjguiComposableUiPositionSample(identityKey, binding,
            CjguiComposableUiPositionValue(x.presented(), y.presented()),
            CjguiComposableUiPositionValue(x.velocity(), y.velocity()), sampleRevision,
            channelGeneration: channelGeneration, originRevision: originRevision)
    }
    func target(): CjguiComposableUiPositionValue {
        return CjguiComposableUiPositionValue(x.target(), y.target())
    }
    func accepted(): CjguiComposableUiPositionValue {
        return CjguiComposableUiPositionValue(acceptedX, acceptedY)
    }
    func originState(): CjguiComposableUiPositionOriginState {
        return CjguiComposableUiPositionOriginState(channelGeneration, originRevision)
    }
    func canRebaseOrigin(compensation: CjguiComposableUiPositionValue): Bool {
        return x.canTranslate(compensation.x) && y.canTranslate(compensation.y) &&
            positionCoordinateAfterDeltaAllowed(acceptedX, compensation.x) &&
            positionCoordinateAfterDeltaAllowed(acceptedY, compensation.y)
    }
    /// Shift all scalar coordinates without retargeting or restarting time.
    /// This preserves spring velocity, tween start time, accepted checkpoint,
    /// and the channel's existing sample revision.
    func rebaseOrigin(compensation: CjguiComposableUiPositionValue, nextOriginRevision: Int64): Bool {
        if (nextOriginRevision != originRevision + 1 || !canRebaseOrigin(compensation)) {
            return false
        }
        let shiftedX = x.translated(compensation.x)
        let shiftedY = y.translated(compensation.y)
        if (let Some(nextX) <- shiftedX) {
            if (let Some(nextY) <- shiftedY) {
                acceptedX += compensation.x
                acceptedY += compensation.y
                x = nextX
                y = nextY
                originRevision = nextOriginRevision
                return true
            }
        }
        return false
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
        if (!binding.matches(sample.binding) || sample.identityKey != identityKey) { return }
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
