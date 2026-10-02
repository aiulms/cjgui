// CJGUI P2 动效基础（B 包）：公共、确定性的时间/状态模型。
//
// 本文件只包含纯仓颉状态与时间推进：不引用 native、窗口、控制器或业务 owner。
// 归属边界（与窗口/kernel 的角色划分一致）：
//   * 业务目标与业务版本     —— 由应用 owner 持有，本文件不保存、不回写；
//   * accepted 样式目标      —— 由窗口的 accepted scene 持有；
//   * 动画目标与当前视觉值   —— 由这里的时间通道持有；
//   * 帧请求与提交           —— 由窗口/宿主按“是否仍有活动通道”决定。
//
// 显式时间：所有推进都接收一个单调时间戳（毫秒，Float64）。窗口把
// `MonoTime` 转成该标量；测试可以传入任意序列，不依赖真实时钟，因此单测
// 对帧间隔变化、长暂停和改目标中途反向都可确定性重现。
//
// 本包只做“不改变布局的颜色/透明度状态过渡”：节点 paint alpha 与隔离效果组
// opacity 是互相独立的通道，窗口按 accepted 绑定分别投影；几何动画、跨容器
// 转场与玻璃仍属后续包，不在此实现。
package cjgui

import std.collection.*
import std.math.*

/// 一次动画帧最多等待的毫秒数。有活动动效时，窗口与共享宿主都把 AppKit
/// 等待上限收缩到这个值，从而每帧申请下一次机会，而不是长睡到下一批事件。
public let CJGUI_COMPOSABLE_UI_ANIMATION_FRAME_WAIT_MS: UInt32 = 8u32

/// 动画标量的有限性判据：有限值满足 `value - value == 0`，NaN 与 ±Infinity
/// 都得到 NaN。放在文件级，让规格与时间通道共用同一判据。
func cjguiAnimationIsFiniteScalar(value: Float64): Bool {
    return value - value == 0.0
}

/// 缓动曲线编码。手写、生成与注册组合组件共用同一编码：生成侧发布并校验
/// 的枚举值与此处 `apply` 的分支集合完全一致。
public class CjguiComposableUiAnimationEasing {
    public static let LINEAR: Int64 = 0
    public static let EASE_IN: Int64 = 1
    public static let EASE_OUT: Int64 = 2
    public static let EASE_IN_OUT: Int64 = 3

    public static func isValid(value: Int64): Bool {
        return value == LINEAR || value == EASE_IN || value == EASE_OUT || value == EASE_IN_OUT
    }

    /// 把 progress ∈ [0,1] 映射到 [0,1]，并保证两端精确为 0/1。非有限输入
    /// 按 0 处理，永不把 NaN/Infinity 代入场景。
    public static func apply(value: Int64, progress: Float64): Float64 {
        let t = CjguiComposableUiAnimationEasing.clampUnit(progress)
        if (value == EASE_IN) {
            return t * t
        }
        if (value == EASE_OUT) {
            let inverse = 1.0 - t
            return 1.0 - inverse * inverse
        }
        if (value == EASE_IN_OUT) {
            if (t < 0.5) {
                return 2.0 * t * t
            }
            let inverse = 1.0 - t
            return 1.0 - 2.0 * inverse * inverse
        }
        return t
    }

    static func clampUnit(value: Float64): Float64 {
        if (value.isNaN()) {
            return 0.0
        }
        if (value <= 0.0) {
            return 0.0
        }
        if (value >= 1.0) {
            return 1.0
        }
        return value
    }
}

/// 动画驱动方式编码。
public class CjguiComposableUiAnimationKind {
    public static let TWEEN: Int64 = 0
    public static let SPRING: Int64 = 1

    public static func isValid(value: Int64): Bool {
        return value == TWEEN || value == SPRING
    }
}

/// 一个不可变的动画规格。消费者复用同一份规格即可让手写、生成与注册组合
/// 组件得到相同的时间和稳态行为；越界参数在构造期被夹到合法域，而不是在
/// 运行时产生非法帧。
public class CjguiComposableUiAnimationSpec {
    public static let MAXIMUM_DURATION_MS: Int64 = 10000
    public static let MINIMUM_STIFFNESS: Float64 = 1.0
    public static let MAXIMUM_STIFFNESS: Float64 = 10000.0
    public static let MINIMUM_DAMPING_RATIO: Float64 = 0.05
    public static let MAXIMUM_DAMPING_RATIO: Float64 = 10.0

    public let kind: Int64
    public let durationMs: Int64
    public let easing: Int64
    public let stiffness: Float64
    public let dampingRatio: Float64
    /// 非有限规格输入（NaN/±Infinity）的可识别标记。存储值仍按既有规则夹到合法
    /// 域，但调用方可以据此**拒绝**，而不是把一个被静默改写的规格当成有效输入。
    private let rejectedValue: Bool
    private let rejectionReasonValue: String

    public init(
        kind!: Int64 = CjguiComposableUiAnimationKind.TWEEN,
        durationMs!: Int64 = 180,
        easing!: Int64 = CjguiComposableUiAnimationEasing.EASE_OUT,
        stiffness!: Float64 = 170.0,
        dampingRatio!: Float64 = 1.0
    ) {
        this.kind = if (CjguiComposableUiAnimationKind.isValid(kind)) {
            kind
        } else {
            CjguiComposableUiAnimationKind.TWEEN
        }
        this.durationMs = if (durationMs < 0) {
            0
        } else if (durationMs > CjguiComposableUiAnimationSpec.MAXIMUM_DURATION_MS) {
            CjguiComposableUiAnimationSpec.MAXIMUM_DURATION_MS
        } else {
            durationMs
        }
        this.easing = if (CjguiComposableUiAnimationEasing.isValid(easing)) {
            easing
        } else {
            CjguiComposableUiAnimationEasing.EASE_OUT
        }
        this.stiffness = CjguiComposableUiAnimationSpec.boundedStiffness(stiffness)
        this.dampingRatio = CjguiComposableUiAnimationSpec.boundedDampingRatio(dampingRatio)
        // 非有限输入可识别：存储仍夹到合法域（既有 clamp 语义不变），调用方用
        // isRejected/rejectionReason 明确拒绝，而不是静默接受被改写的规格。
        if (!cjguiAnimationIsFiniteScalar(stiffness)) {
            this.rejectedValue = true
            this.rejectionReasonValue = "stiffness_not_finite"
        } else if (!cjguiAnimationIsFiniteScalar(dampingRatio)) {
            this.rejectedValue = true
            this.rejectionReasonValue = "damping_ratio_not_finite"
        } else {
            this.rejectedValue = false
            this.rejectionReasonValue = ""
        }
    }

    /// 有界补间：到达目标后精确停在目标值并结束。
    public static func tween(
        durationMs!: Int64 = 180,
        easing!: Int64 = CjguiComposableUiAnimationEasing.EASE_OUT
    ): CjguiComposableUiAnimationSpec {
        return CjguiComposableUiAnimationSpec(kind: CjguiComposableUiAnimationKind.TWEEN, durationMs: durationMs,
            easing: easing)
    }

    /// 有界弹簧：默认临界阻尼（不过冲），消费者可显式选择欠阻尼以得到回弹。
    public static func spring(
        stiffness!: Float64 = 170.0,
        dampingRatio!: Float64 = 1.0
    ): CjguiComposableUiAnimationSpec {
        return CjguiComposableUiAnimationSpec(kind: CjguiComposableUiAnimationKind.SPRING, stiffness: stiffness,
            dampingRatio: dampingRatio)
    }

    public func isValid(): Bool {
        if (!CjguiComposableUiAnimationKind.isValid(this.kind)) {
            return false
        }
        if (!CjguiComposableUiAnimationEasing.isValid(this.easing)) {
            return false
        }
        if (this.durationMs < 0 || this.durationMs > CjguiComposableUiAnimationSpec.MAXIMUM_DURATION_MS) {
            return false
        }
        if (!CjguiComposableUiAnimationSpec.isBounded(this.stiffness, CjguiComposableUiAnimationSpec.MINIMUM_STIFFNESS,
            CjguiComposableUiAnimationSpec.MAXIMUM_STIFFNESS)) {
            return false
        }
        return CjguiComposableUiAnimationSpec.isBounded(this.dampingRatio,
            CjguiComposableUiAnimationSpec.MINIMUM_DAMPING_RATIO, CjguiComposableUiAnimationSpec.MAXIMUM_DAMPING_RATIO)
    }

    /// 是否由非有限输入（NaN/±Infinity）构造而来。这类规格必须被调用方拒绝，
    /// 而不是接受一个已被夹取改写的值。有限但越域的输入仍按既有 clamp 语义处理，
    /// 不在此列。
    public func isRejected(): Bool {
        return rejectedValue
    }

    /// 拒绝原因；仅当 `isRejected()` 为真时非空。
    public func rejectionReason(): String {
        return rejectionReasonValue
    }

    static func boundedStiffness(value: Float64): Float64 {
        if (value.isNaN()) {
            return 170.0
        }
        if (value < CjguiComposableUiAnimationSpec.MINIMUM_STIFFNESS) {
            return CjguiComposableUiAnimationSpec.MINIMUM_STIFFNESS
        }
        if (value > CjguiComposableUiAnimationSpec.MAXIMUM_STIFFNESS) {
            return CjguiComposableUiAnimationSpec.MAXIMUM_STIFFNESS
        }
        return value
    }

    static func boundedDampingRatio(value: Float64): Float64 {
        if (value.isNaN()) {
            return 1.0
        }
        if (value < CjguiComposableUiAnimationSpec.MINIMUM_DAMPING_RATIO) {
            return CjguiComposableUiAnimationSpec.MINIMUM_DAMPING_RATIO
        }
        if (value > CjguiComposableUiAnimationSpec.MAXIMUM_DAMPING_RATIO) {
            return CjguiComposableUiAnimationSpec.MAXIMUM_DAMPING_RATIO
        }
        return value
    }

    static func isBounded(value: Float64, minimum: Float64, maximum: Float64): Bool {
        if (value.isNaN()) {
            return false
        }
        return value >= minimum && value <= maximum
    }
}

/// 一条标量时间通道：补间或弹簧。它保存“动画目标”和“当前视觉值”，从不
/// 保存业务目标；一次业务操作只调用 retarget 一次，之后的每帧推进不会重放
/// 业务操作。
///
/// 确定性：所有推进都由显式时间戳驱动，同一时间序列必得同一结果。
public class CjguiComposableUiScalarAnimation {
    /// 弹簧积分的固定子步。半隐式欧拉在固定步长下对变帧间隔稳定，且单次
    /// advance 的子步数有上界，因此长帧/暂停不会引入无界工作量。
    public static let FIXED_STEP_MS: Float64 = 8.0
    public static let MAXIMUM_SUBSTEPS: Int64 = 256
    /// 超过此跨度的推进视为“长暂停恢复”：直接收敛到目标（确定、有界），
    /// 不模拟暂停期间不存在的瞬态过程。
    public static let MAXIMUM_RESUME_SPAN_MS: Float64 = 2000.0
    /// 完成判据：位移与速度同时进入阈值即停在目标。
    public static let REST_DISPLACEMENT: Float64 = 0.0005
    public static let REST_VELOCITY: Float64 = 0.0005

    private var presentedValue: Float64
    private var targetValue: Float64
    private var velocityValue: Float64
    private let specValue: CjguiComposableUiAnimationSpec
    private var startValue: Float64
    private var startTimeMs: Float64
    private var lastTimeMs: Float64
    private var activeValue: Bool
    private var completedValue: Bool

    private init(presented: Float64, target: Float64, velocity: Float64, spec: CjguiComposableUiAnimationSpec,
        startValue: Float64, nowMs: Float64, active: Bool, completed: Bool) {
        this.presentedValue = presented
        this.targetValue = target
        this.velocityValue = velocity
        this.specValue = spec
        this.startValue = startValue
        this.startTimeMs = nowMs
        this.lastTimeMs = nowMs
        this.activeValue = active
        this.completedValue = completed
    }

    /// Copy the scalar into a translated coordinate system while preserving
    /// its exact motion clock and phase.
    private init(presented: Float64, target: Float64, velocity: Float64, spec: CjguiComposableUiAnimationSpec,
        startValue: Float64, startTimeMs: Float64, lastTimeMs: Float64, active: Bool, completed: Bool,
        translatedState!: Bool) {
        this.presentedValue = presented
        this.targetValue = target
        this.velocityValue = velocity
        this.specValue = spec
        this.startValue = startValue
        this.startTimeMs = startTimeMs
        this.lastTimeMs = lastTimeMs
        this.activeValue = active
        this.completedValue = completed
    }

    func canTranslate(delta: Float64): Bool {
        if (!cjguiAnimationIsFiniteScalar(delta)) {
            return false
        }
        let presented = presentedValue + delta
        let target = targetValue + delta
        let start = startValue + delta
        if (!CjguiComposableUiScalarAnimation.allFinite([presented, target, start, velocityValue, startTimeMs,
            lastTimeMs]) || presented < -1024.0 || presented > 1024.0 || target < -1024.0 || target > 1024.0 || start <
            -1024.0 || start > 1024.0) {
            return false
        }
        return true
    }

    func translated(delta: Float64): ?CjguiComposableUiScalarAnimation {
        if (!canTranslate(delta)) {
            return None
        }
        return Some(
            CjguiComposableUiScalarAnimation(presentedValue + delta, targetValue + delta, velocityValue, specValue,
                startValue + delta, startTimeMs, lastTimeMs,
                activeValue, completedValue, translatedState: true))
    }

    /// 从 `from` 到 `to` 的有界补间。`from == to` 或时长为零时直接完成，
    /// 不产生中间帧。
    ///
    /// 拒绝语义：起点、目标、起始时间任一为 NaN/±Infinity，或规格由非有限输入
    /// 构造（`spec.isRejected()`），返回 None——调用方据此拒绝，且不会产生一个
    /// "看似成功却被静默改写"的通道。
    public static func tweened(from: Float64, to: Float64, nowMs: Float64,
        spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.tween()): ?CjguiComposableUiScalarAnimation {
        if (!CjguiComposableUiScalarAnimation.allFinite([from, to, nowMs]) || spec.isRejected()) {
            return None
        }
        let settled = spec.durationMs <= 0 || CjguiComposableUiScalarAnimation.atRest(from, to, 0.0)
        let presented = if (settled) {
            to
        } else {
            from
        }
        return Some(CjguiComposableUiScalarAnimation(presented, to, 0.0, spec, presented, nowMs, !settled, settled))
    }

    /// 从 `from` 以 `velocity` 起振的弹簧。改目标会保留当前值与速度，因此
    /// 中途反向的运动会连续改变而不是从零重新开始。非有限起点/目标/初速/时间或
    /// 非有限规格一律返回 None（拒绝）。
    /// 创建时已满足静止判据则精确呈现目标并归零速度，不保留起点残值。
    public static func sprung(from: Float64, to: Float64, nowMs: Float64, velocity!: Float64 = 0.0,
        spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.spring()): ?CjguiComposableUiScalarAnimation {
        if (!CjguiComposableUiScalarAnimation.allFinite([from, to, velocity, nowMs]) || spec.isRejected()) {
            return None
        }
        let settled = CjguiComposableUiScalarAnimation.atRest(from, to, velocity)
        // A terminal spring uses the same exact target/zero velocity as
        // converge and retarget. Keeping a near-target start on an inactive
        // channel leaves a permanent residual after an origin rebase.
        let presented = if (settled) { to } else { from }
        let initialVelocity = if (settled) { 0.0 } else { velocity }
        return Some(CjguiComposableUiScalarAnimation(presented, to, initialVelocity, spec, presented, nowMs,
            !settled, settled))
    }

    /// 以新规格重建同一通道，但保留当前呈现值与速度作为起点/初速。绑定已存在
    /// 时消费者再次请求换规格（例如先 tween 后 spring）必须真正生效：不重置到
    /// 1.0，也不继续沿用旧运动学。任一输入非有限或规格被拒则返回 None，调用方
    /// 必须保持旧通道与旧状态完全不变。
    public static func retuned(presented: Float64, to: Float64, velocity: Float64, nowMs: Float64,
        spec: CjguiComposableUiAnimationSpec): ?CjguiComposableUiScalarAnimation {
        if (!CjguiComposableUiScalarAnimation.allFinite([presented, to, velocity, nowMs]) || spec.isRejected()) {
            return None
        }
        if (spec.kind == CjguiComposableUiAnimationKind.SPRING) {
            return CjguiComposableUiScalarAnimation.sprung(presented, to, nowMs, velocity: velocity, spec: spec)
        }
        return CjguiComposableUiScalarAnimation.tweened(presented, to, nowMs, spec: spec)
    }

    /// 一组标量是否全部有限（NaN 与 ±Infinity 都判假）。
    static func allFinite(values: Array<Float64>): Bool {
        for (value in values) {
            if (!cjguiAnimationIsFiniteScalar(value)) {
                return false
            }
        }
        return true
    }

    /// 推进到显式时间戳，返回推进后的当前视觉值。
    ///
    /// 拒绝语义：时间戳为 NaN/±Infinity、或早于/等于上一次有效时间（时间倒退、
    /// 重复时间）时为 no-op——返回当前值且**不改变任何状态**，与未受扰对照完全
    /// 一致。只有合法且严格向前的推进才真正积分。
    public func advanceTo(nowMs: Float64): Float64 {
        if (!activeValue) {
            return presentedValue
        }
        if (!cjguiAnimationIsFiniteScalar(nowMs) || nowMs <= lastTimeMs) {
            return presentedValue
        }
        if (specValue.kind == CjguiComposableUiAnimationKind.SPRING) {
            return advanceSpring(nowMs)
        }
        return advanceTween(nowMs)
    }

    /// 改目标：补间从当前呈现值重新起步；弹簧保留当前值与既有速度，只换目标。
    ///
    /// 拒绝语义（返回假且**状态完全不变**）：目标或时间为 NaN/±Infinity，或时间
    /// 早于上一次有效时间（倒退）。时间相等允许改目标（同一帧内改目标是合法
    /// 操作）。成功返回真。
    public func retarget(target: Float64, nowMs: Float64): Bool {
        if (!cjguiAnimationIsFiniteScalar(target) || !cjguiAnimationIsFiniteScalar(nowMs) || nowMs < lastTimeMs) {
            return false
        }
        if (specValue.kind == CjguiComposableUiAnimationKind.SPRING) {
            lastTimeMs = nowMs
            let settled = CjguiComposableUiScalarAnimation.atRest(presentedValue, target, velocityValue)
            targetValue = target
            activeValue = !settled
            completedValue = settled
            if (settled) {
                presentedValue = target
                velocityValue = 0.0
            }
            return true
        }
        targetValue = target
        startValue = presentedValue
        startTimeMs = nowMs
        lastTimeMs = nowMs
        velocityValue = 0.0
        let settled = specValue.durationMs <= 0 || CjguiComposableUiScalarAnimation.atRest(presentedValue, target, 0.0)
        activeValue = !settled
        completedValue = settled
        if (settled) {
            presentedValue = target
        }
        return true
    }

    /// 立即收敛到目标（减少动态效果切换、取消前收尾等确定路径）。收敛目标
    /// 本身也必须有效：万一目标已被非有限值污染，先收敛到确定的有限值再投影。
    public func converge(): Unit {
        if (!cjguiAnimationIsFiniteScalar(targetValue)) {
            targetValue = 0.0
        }
        presentedValue = targetValue
        velocityValue = 0.0
        activeValue = false
        completedValue = true
    }

    /// 立即设置当前视觉值并结束，不移动目标。用于把无人消费的通道复位到
    /// 确定值（例如取消绑定前的最后一次投影）。
    ///
    /// 拒绝语义：值非有限则返回假且状态不变；成功返回真。
    public func settleAt(value: Float64): Bool {
        if (!cjguiAnimationIsFiniteScalar(value)) {
            return false
        }
        presentedValue = value
        velocityValue = 0.0
        activeValue = false
        completedValue = true
        return true
    }

    public func presented(): Float64 {
        return presentedValue
    }

    public func target(): Float64 {
        return targetValue
    }

    public func velocity(): Float64 {
        return velocityValue
    }

    public func isActive(): Bool {
        return activeValue
    }

    public func isCompleted(): Bool {
        return completedValue
    }

    public func spec(): CjguiComposableUiAnimationSpec {
        return specValue
    }

    /// 上一次有效推进/改目标的时间戳。供驱动做"时间倒退拒绝"判断，不做插值。
    public func lastTime(): Float64 {
        return lastTimeMs
    }

    private func advanceTween(nowMs: Float64): Float64 {
        if (specValue.durationMs <= 0) {
            converge()
            lastTimeMs = nowMs
            return presentedValue
        }
        let elapsed = nowMs - startTimeMs
        // 先判完成：到达/超过时长直接精确收敛到目标，不做任何中间插值运算，
        // 因此极大有限值的差值不会在"已完成"这条路径上被计算。
        if (elapsed >= Float64(specValue.durationMs)) {
            lastTimeMs = nowMs
            converge()
            return presentedValue
        }
        if (elapsed <= 0.0) {
            lastTimeMs = nowMs
            return presentedValue
        }
        let progress = elapsed / Float64(specValue.durationMs)
        let eased = CjguiComposableUiAnimationEasing.apply(specValue.easing, progress)
        // 稳定 lerp：`start*(1-e) + target*e` 在两端接近 Float64 极值时，不会像
        // `start + (target-start)*e` 那样先算出溢出的差值；内部若仍溢出，则
        // fail-closed 收敛到已验证的有限目标，绝不投影非有限值。
        let lerped = startValue * (1.0 - eased) + targetValue * eased
        if (!cjguiAnimationIsFiniteScalar(lerped)) {
            converge()
            lastTimeMs = nowMs
            return presentedValue
        }
        presentedValue = lerped
        lastTimeMs = nowMs
        return presentedValue
    }

    private func advanceSpring(nowMs: Float64): Float64 {
        let span = nowMs - lastTimeMs
        if (span <= 0.0) {
            return presentedValue
        }
        if (span > CjguiComposableUiScalarAnimation.MAXIMUM_RESUME_SPAN_MS) {
            // 长暂停：确定收敛，不与暂停前的瞬态拼接。
            converge()
            lastTimeMs = nowMs
            return presentedValue
        }
        // 数值子步：公开域 stiffness≤10000 时 ω=sqrt(k)≤100，8ms 的 dt·ω≤0.8 落在
        // 半隐式欧拉的稳定带内。仍显式按 ω 收紧步长，让任何未来的参数域扩大都
        // 不会把发散运动投影成场景，而不是依赖“当前上限恰好安全”。
        let omega = sqrt(specValue.stiffness)
        let stableStepMs = if (omega > 1.0) {
            1500.0 / omega
        } else {
            CjguiComposableUiScalarAnimation.FIXED_STEP_MS
        }
        let stepMs = if (stableStepMs < CjguiComposableUiScalarAnimation.FIXED_STEP_MS) {
            stableStepMs
        } else {
            CjguiComposableUiScalarAnimation.FIXED_STEP_MS
        }
        var remaining = span
        var substeps: Int64 = 0
        var stable = true
        while (remaining > 0.0 && activeValue && substeps < CjguiComposableUiScalarAnimation.MAXIMUM_SUBSTEPS) {
            let step = if (remaining < stepMs) {
                remaining
            } else {
                stepMs
            }
            if (!integrateSpringStep(step / 1000.0)) {
                stable = false
                break
            }
            remaining -= step
            substeps += 1
            settleIfAtRest()
        }
        if (!stable || (remaining > 0.0 && activeValue)) {
            // 内部溢出或超预算：停止积分并确定收敛到目标，而不是继续无界子步或
            // 投影未收敛/非有限的瞬态。长跨度已由 MAXIMUM_RESUME_SPAN_MS 提前收敛。
            converge()
        }
        lastTimeMs = nowMs
        return presentedValue
    }

    /// 一步半隐式欧拉（阻尼隐式）：把 `-damping·v` 放进分母。显式阻尼在公开域
    /// 的 `dt·damping > 2`（k=10000、ratio=10 时 8ms 即 16）下指数发散；隐式阻尼
    /// 无条件稳定，位移仍用同一子步更新，因此变帧间隔不会跳变。
    ///
    /// 所有中间量先在局部变量中计算并验证有限性，只有全部有限才写回存储；否则
    /// 返回假，由调用方 fail-closed 收敛——绝不让非有限值进入存储状态。
    private func integrateSpringStep(dtSeconds: Float64): Bool {
        let stiffness = specValue.stiffness
        let damping = 2.0 * specValue.dampingRatio * sqrt(stiffness)
        let displacement = presentedValue - targetValue
        let denominator = 1.0 + damping * dtSeconds
        let nextVelocity = (velocityValue - stiffness * displacement * dtSeconds) / denominator
        let nextPresented = presentedValue + nextVelocity * dtSeconds
        if (!cjguiAnimationIsFiniteScalar(nextVelocity) || !cjguiAnimationIsFiniteScalar(nextPresented)) {
            return false
        }
        velocityValue = nextVelocity
        presentedValue = nextPresented
        return true
    }

    private func settleIfAtRest(): Unit {
        if (CjguiComposableUiScalarAnimation.atRest(presentedValue, targetValue, velocityValue)) {
            converge()
        }
    }

    static func atRest(presented: Float64, target: Float64, velocity: Float64): Bool {
        // 任一非有限（NaN 或 ±Infinity）都视为“无处可动”：抛出非有限值的通道
        // 必须确定收敛，而不是继续用 Inf 推进。
        if (!CjguiComposableUiScalarAnimation.isFiniteScalar(presented) ||
            !CjguiComposableUiScalarAnimation.isFiniteScalar(target) ||
            !CjguiComposableUiScalarAnimation.isFiniteScalar(velocity)) {
            return true
        }
        return abs(presented - target) <= CjguiComposableUiScalarAnimation.REST_DISPLACEMENT && abs(velocity) <= CjguiComposableUiScalarAnimation
            .REST_VELOCITY
    }

    /// 有限性判据：有限值满足 `value - value == 0`，NaN 与两个无穷都得到 NaN。
    static func isFiniteScalar(value: Float64): Bool {
        return value - value == 0.0
    }
}

/// 颜色过渡契约：公开的插值空间、透明端点与预乘约定。手写、组合与生成引用
/// 同一组常量，不各自复制一份说明；`describe` 只输出这些 token。
///
/// * 插值空间 `srgb_component_linear`：在 sRGB 编码分量上逐通道线性插值，
///   **不**转换到线性光空间。中间色是"编码值的中点"，全程只做乘加，不引入
///   颜色管理依赖，也不依赖显示色域。
/// * 预乘约定 `straight`：颜色以非预乘（straight alpha）分量参与插值，RGB 与
///   alpha 相互独立；不会在 alpha→0 时把 RGB 预先乘没而不可逆。
/// * 透明端点 `rgb_independent_of_alpha`：alpha 到 0 时 RGB 仍为声明的色分量，
///   不预先乘 alpha、不归零。从"透明红"到"不透明蓝"的中间帧是 RGB 混合 +
///   alpha 线性增长，而不是预乘后的暗淡中间色。
/// * alpha 合成 `presented_paint_alpha_times_node_opacity_once`：交互状态声明的
///   是一整个颜色值（含 alpha）——某字段声明 `Some(color)` 即**替换该字段的完整
///   颜色**，未声明的字段**继承 base 值**；颜色过渡产生"呈现 RGBA"（结束态等于
///   交互解析色）；最终绘制 alpha = 呈现 alpha × 节点 opacity，**只再乘一次**，
///   绝不额外再乘一遍 base alpha。节点 opacity 对 `shadow.color.alpha` 与每个
///   gradient stop 的 alpha 同样各应用一次。native 端只把 `textColor.alpha`（此时
///   已是最终值）当作一次绘制乘子，不再重复应用同一因子。因此样式本色 0.8、
///   hover 声明完整色 alpha 0.75、opacity 0.5 → 0.375；字段未被交互覆盖则
///   0.8 × 0.5 = 0.4。
///
/// Stability: experimental.
public class CjguiComposableUiColorInterpolation {
    public static let COLOR_SPACE: String = "srgb_component_linear"
    public static let ALPHA_ASSOCIATION: String = "straight"
    public static let TRANSPARENT_ENDPOINT: String = "rgb_independent_of_alpha"
    public static let ALPHA_COMPOSITION: String = "presented_paint_alpha_times_node_opacity_once"

    /// 发布真实支持的插值契约 token（发现与验收读同一份定义）。
    public static func describe(): String {
        return "color_space=${CjguiComposableUiColorInterpolation.COLOR_SPACE} " +
            "alpha_association=${CjguiComposableUiColorInterpolation.ALPHA_ASSOCIATION} " +
            "transparent_endpoint=${CjguiComposableUiColorInterpolation.TRANSPARENT_ENDPOINT} " +
            "alpha_composition=${CjguiComposableUiColorInterpolation.ALPHA_COMPOSITION}"
    }
}

/// 一条可中断的颜色时间通道（RGBA，逐分量）。它把 4 条已有的标量通道组合成
/// 一个颜色单位，复用同一套补间/弹簧、有限性、时间倒退拒绝与"从当前呈现值
/// 续接"语义，而不是另写一套颜色运动学。
///
/// 归属边界与标量通道一致：保存"动画目标色"和"当前呈现色"，从不保存业务
/// 目标。一次状态变化只 retarget 一次；中途反向时保留当前呈现值（弹簧还保留
/// 速度），因此快进快出与中途反向都从当前视觉值连续改变。
///
/// Stability: experimental.
public class CjguiComposableUiColorChannelAnimation {
    private var red: CjguiComposableUiScalarAnimation
    private var green: CjguiComposableUiScalarAnimation
    private var blue: CjguiComposableUiScalarAnimation
    private var alpha: CjguiComposableUiScalarAnimation

    private init(red: CjguiComposableUiScalarAnimation, green: CjguiComposableUiScalarAnimation,
        blue: CjguiComposableUiScalarAnimation, alpha: CjguiComposableUiScalarAnimation) {
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }

    /// 从 `from` 到 `to` 的有界颜色补间。`from == to`（逐分量）或时长为零时
    /// 直接完成。任一分量非有限或规格被拒返回 None，调用方据此保持旧状态。
    public static func tweened(from: CjguiComposableUiColor, to: CjguiComposableUiColor, nowMs: Float64,
        spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.tween()): ?CjguiComposableUiColorChannelAnimation {
        let r = match (CjguiComposableUiScalarAnimation.tweened(from.red, to.red, nowMs, spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        let g = match (CjguiComposableUiScalarAnimation.tweened(from.green, to.green, nowMs, spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        let b = match (CjguiComposableUiScalarAnimation.tweened(from.blue, to.blue, nowMs, spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        let a = match (CjguiComposableUiScalarAnimation.tweened(from.alpha, to.alpha, nowMs, spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        return Some(CjguiComposableUiColorChannelAnimation(r, g, b, a))
    }

    /// 以目标色建立一个已静止的通道：当前呈现色即目标色（首次绑定的画面就是
    /// 目标色），之后的状态变化从中途续接。
    public static func settled(color: CjguiComposableUiColor, nowMs: Float64,
        spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.tween()): ?CjguiComposableUiColorChannelAnimation {
        return CjguiComposableUiColorChannelAnimation.tweened(color, color, nowMs, spec: spec)
    }

    /// 从 `from` 以 `velocity` 起振的颜色弹簧（逐分量）。改目标保留当前颜色与
    /// 速度，因此中途反向连续。任一输入非有限或规格被拒返回 None。
    public static func sprung(from: CjguiComposableUiColor, to: CjguiComposableUiColor, nowMs: Float64,
        velocity!: CjguiComposableUiColor = CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0),
        spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.spring()): ?CjguiComposableUiColorChannelAnimation {
        let r = match (CjguiComposableUiScalarAnimation.sprung(from.red, to.red, nowMs, velocity: velocity.red,
            spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        let g = match (CjguiComposableUiScalarAnimation.sprung(from.green, to.green, nowMs, velocity: velocity.green,
            spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        let b = match (CjguiComposableUiScalarAnimation.sprung(from.blue, to.blue, nowMs, velocity: velocity.blue,
            spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        let a = match (CjguiComposableUiScalarAnimation.sprung(from.alpha, to.alpha, nowMs, velocity: velocity.alpha,
            spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        return Some(CjguiComposableUiColorChannelAnimation(r, g, b, a))
    }

    /// 以新规格重建同一颜色通道，但保留当前呈现色与速度（逐分量）作为起点。
    public static func retuned(presented: CjguiComposableUiColor, to: CjguiComposableUiColor,
        velocity: CjguiComposableUiColor, nowMs: Float64, spec: CjguiComposableUiAnimationSpec): ?CjguiComposableUiColorChannelAnimation {
        let r = match (CjguiComposableUiScalarAnimation.retuned(presented.red, to.red, velocity.red, nowMs, spec)) {
            case Some(value) => value
            case None => return None
        }
        let g = match (CjguiComposableUiScalarAnimation.retuned(presented.green, to.green, velocity.green, nowMs, spec)) {
            case Some(value) => value
            case None => return None
        }
        let b = match (CjguiComposableUiScalarAnimation.retuned(presented.blue, to.blue, velocity.blue, nowMs, spec)) {
            case Some(value) => value
            case None => return None
        }
        let a = match (CjguiComposableUiScalarAnimation.retuned(presented.alpha, to.alpha, velocity.alpha, nowMs, spec)) {
            case Some(value) => value
            case None => return None
        }
        return Some(CjguiComposableUiColorChannelAnimation(r, g, b, a))
    }

    /// 推进到显式时间戳，返回推进后的当前呈现色。非有限时间或时间倒退按 no-op
    /// 处理（每条标量通道自身拒绝），不改变状态。
    public func advanceTo(nowMs: Float64): CjguiComposableUiColor {
        let r = this.red.advanceTo(nowMs)
        let g = this.green.advanceTo(nowMs)
        let b = this.blue.advanceTo(nowMs)
        let a = this.alpha.advanceTo(nowMs)
        return CjguiComposableUiColor(r, g, b, a)
    }

    /// 改目标：补间从当前呈现色重新起步；弹簧保留当前颜色与速度，只换目标。
    /// 目标非有限、时间非有限或时间倒退时返回假且状态完全不变。
    public func retarget(target: CjguiComposableUiColor, nowMs: Float64): Bool {
        if (!CjguiComposableUiColorChannelAnimation.isFiniteColor(target) || !cjguiAnimationIsFiniteScalar(nowMs) ||
            nowMs < this.red.lastTime()) {
            return false
        }
        let r = this.red.retarget(target.red, nowMs)
        let g = this.green.retarget(target.green, nowMs)
        let b = this.blue.retarget(target.blue, nowMs)
        let a = this.alpha.retarget(target.alpha, nowMs)
        return r && g && b && a
    }

    public func presentedColor(): CjguiComposableUiColor {
        return CjguiComposableUiColor(this.red.presented(), this.green.presented(), this.blue.presented(),
            this.alpha.presented())
    }

    public func targetColor(): CjguiComposableUiColor {
        return CjguiComposableUiColor(this.red.target(), this.green.target(), this.blue.target(), this.alpha.target())
    }

    public func velocityColor(): CjguiComposableUiColor {
        return CjguiComposableUiColor(this.red.velocity(), this.green.velocity(), this.blue.velocity(),
            this.alpha.velocity())
    }

    /// 任一分量仍在推进即为活动；只有四条通道都静止才静止。
    public func isActive(): Bool {
        return this.red.isActive() || this.green.isActive() || this.blue.isActive() || this.alpha.isActive()
    }

    public func isCompleted(): Bool {
        return this.red.isCompleted() && this.green.isCompleted() && this.blue.isCompleted() && this
            .alpha
            .isCompleted()
    }

    /// 四条通道在同一时间戳推进，时间一致；取红分量即可。
    public func lastTime(): Float64 {
        return this.red.lastTime()
    }

    public func spec(): CjguiComposableUiAnimationSpec {
        return this.red.spec()
    }

    public func matchesSpec(spec: CjguiComposableUiAnimationSpec): Bool {
        return CjguiComposableUiColorChannelAnimation.specMatches(this.red.spec(), spec)
    }

    /// 立即收敛到目标色（减少动态效果、关闭收尾）。
    public func converge(): Unit {
        this.red.converge()
        this.green.converge()
        this.blue.converge()
        this.alpha.converge()
    }

    /// 立即设置当前呈现色并结束。
    public func settleAt(color: CjguiComposableUiColor): Bool {
        if (!CjguiComposableUiColorChannelAnimation.isFiniteColor(color)) {
            return false
        }
        let r = this.red.settleAt(color.red)
        let g = this.green.settleAt(color.green)
        let b = this.blue.settleAt(color.blue)
        let a = this.alpha.settleAt(color.alpha)
        return r && g && b && a
    }

    static func isFiniteColor(color: CjguiComposableUiColor): Bool {
        return cjguiAnimationIsFiniteScalar(color.red) && cjguiAnimationIsFiniteScalar(color.green) &&
            cjguiAnimationIsFiniteScalar(color.blue) && cjguiAnimationIsFiniteScalar(color.alpha)
    }

    static func sameColor(left: CjguiComposableUiColor, right: CjguiComposableUiColor): Bool {
        return left.red == right.red && left.green == right.green && left.blue == right.blue && left.alpha == right
            .alpha
    }

    static func specMatches(left: CjguiComposableUiAnimationSpec, right: CjguiComposableUiAnimationSpec): Bool {
        return left.kind == right.kind && left.durationMs == right.durationMs && left.easing == right.easing &&
            left.stiffness == right.stiffness && left.dampingRatio == right.dampingRatio
    }
}

/// 一个节点的 paint 颜色投影值：background/border/textColor 三条颜色。它是纯
/// 值类型，供窗口覆盖已解析的交互样式，也供测试直接断言。
///
/// Stability: experimental.
public class CjguiComposableUiPaintColorSet {
    public let background: CjguiComposableUiColor
    public let border: CjguiComposableUiColor
    public let textColor: CjguiComposableUiColor

    public init(background: CjguiComposableUiColor, border: CjguiComposableUiColor, textColor: CjguiComposableUiColor) {
        this.background = background
        this.border = border
        this.textColor = textColor
    }

    public func isFinite(): Bool {
        return CjguiComposableUiColorChannelAnimation.isFiniteColor(this.background) &&
            CjguiComposableUiColorChannelAnimation.isFiniteColor(this.border) &&
            CjguiComposableUiColorChannelAnimation.isFiniteColor(this.textColor)
    }
}

/// 一个节点的 paint 颜色过渡绑定：background/border/textColor 三条可中断颜色
/// 通道，共享同一槽位身份（与 alpha 绑定相同的代际判据）与同一规格。它保存
/// 动画目标色与当前呈现色，从不写回 accepted 样式。
///
/// Stability: experimental.
public class CjguiComposableUiNodePaintColorAnimation {
    public let identityKey: String
    public let binding: CjguiComposableUiAnimationBinding
    /// 兼容视图：最新绑定的 nodeId。判据请用 `binding.matches`。
    public let nodeId: Int64
    private var background: CjguiComposableUiColorChannelAnimation
    private var border: CjguiComposableUiColorChannelAnimation
    private var textColor: CjguiComposableUiColorChannelAnimation

    private init(identityKey: String, binding: CjguiComposableUiAnimationBinding,
        background: CjguiComposableUiColorChannelAnimation, border: CjguiComposableUiColorChannelAnimation,
        textColor: CjguiComposableUiColorChannelAnimation) {
        this.identityKey = identityKey
        this.binding = binding
        this.nodeId = binding.nodeId
        this.background = background
        this.border = border
        this.textColor = textColor
    }

    static func settled(identityKey: String, binding: CjguiComposableUiAnimationBinding,
        target: CjguiComposableUiPaintColorSet, spec: CjguiComposableUiAnimationSpec, nowMs: Float64): ?CjguiComposableUiNodePaintColorAnimation {
        let background = match (CjguiComposableUiColorChannelAnimation.settled(target.background, nowMs, spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        let border = match (CjguiComposableUiColorChannelAnimation.settled(target.border, nowMs, spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        let textColor = match (CjguiComposableUiColorChannelAnimation.settled(target.textColor, nowMs, spec: spec)) {
            case Some(value) => value
            case None => return None
        }
        return Some(CjguiComposableUiNodePaintColorAnimation(identityKey, binding, background, border, textColor))
    }

    /// 把三条通道的目标改为 `target`；目标未变的分量保持原运动学（不会被无谓
    /// 重置）。任一分量拒绝则整体不变。返回真表示确有目标被改变。
    func retarget(target: CjguiComposableUiPaintColorSet, nowMs: Float64): Bool {
        if (!target.isFinite() || !cjguiAnimationIsFiniteScalar(nowMs) || nowMs < this.lastTime()) {
            return false
        }
        var changed = false
        if (!CjguiComposableUiColorChannelAnimation.sameColor(this.background.targetColor(), target.background)) {
            if (!this.background.retarget(target.background, nowMs)) {
                return false
            }
            changed = true
        }
        if (!CjguiComposableUiColorChannelAnimation.sameColor(this.border.targetColor(), target.border)) {
            if (!this.border.retarget(target.border, nowMs)) {
                return false
            }
            changed = true
        }
        if (!CjguiComposableUiColorChannelAnimation.sameColor(this.textColor.targetColor(), target.textColor)) {
            if (!this.textColor.retarget(target.textColor, nowMs)) {
                return false
            }
            changed = true
        }
        return changed
    }

    func advanceTo(nowMs: Float64): CjguiComposableUiPaintColorSet {
        return CjguiComposableUiPaintColorSet(this.background.advanceTo(nowMs), this.border.advanceTo(nowMs),
            this.textColor.advanceTo(nowMs))
    }

    func presentedColorSet(): CjguiComposableUiPaintColorSet {
        return CjguiComposableUiPaintColorSet(this.background.presentedColor(), this.border.presentedColor(),
            this.textColor.presentedColor())
    }

    func targetColorSet(): CjguiComposableUiPaintColorSet {
        return CjguiComposableUiPaintColorSet(this.background.targetColor(), this.border.targetColor(),
            this.textColor.targetColor())
    }

    func converge(): Unit {
        this.background.converge()
        this.border.converge()
        this.textColor.converge()
    }

    func isActive(): Bool {
        return this.background.isActive() || this.border.isActive() || this.textColor.isActive()
    }

    func lastTime(): Float64 {
        return this.background.lastTime()
    }

    func matchesSpec(spec: CjguiComposableUiAnimationSpec): Bool {
        return this.background.matchesSpec(spec)
    }

    /// 用新规格重建三条通道，保留当前呈现色/速度逐分量的续接语义。
    func respecify(spec: CjguiComposableUiAnimationSpec, nowMs: Float64): Bool {
        let background = match (CjguiComposableUiColorChannelAnimation.retuned(this.background.presentedColor(),
            this.background.targetColor(), this.background.velocityColor(), nowMs, spec)) {
            case Some(value) => value
            case None => return false
        }
        let border = match (CjguiComposableUiColorChannelAnimation.retuned(this.border.presentedColor(),
            this.border.targetColor(), this.border.velocityColor(), nowMs, spec)) {
            case Some(value) => value
            case None => return false
        }
        let textColor = match (CjguiComposableUiColorChannelAnimation.retuned(this.textColor.presentedColor(),
            this.textColor.targetColor(), this.textColor.velocityColor(), nowMs, spec)) {
            case Some(value) => value
            case None => return false
        }
        this.background = background
        this.border = border
        this.textColor = textColor
        return true
    }
}

/// accepted 绑定的“槽位身份”。`identityKey` 回答“这条动画属于哪个声明”，本
/// 类型回答“该声明当前解析到哪个具体绑定”。
///
/// 代际判据是 accepted 事实上会影响实际操作归属的字段：
///   * nodeId/nodeKind（解析后的节点实例与种类）；
///   * resourceId/actionName（节点自身的资源与本地动作）；
///   * operationResourceId/operationActionName（**业务**操作目标，可与节点自身的
///     resource/action 不同）；
///   * fieldId（该节点编辑的业务字段）。
/// 任一变化都是“直接同槽换绑”，旧动画的完成事实与当前数值一律失效，不得落到
/// 换绑后的新节点；纯重排或仅文案(label/value)变化不改这些判据，因此仍保持连续。
///
/// 刻意**不**纳入 `sceneVersion`：动画自身的 paint 提交也会推进它，纳入会取消
/// 自身动画。`semanticId` 已被 `identityKey` 编码；`inputScopeId`/layer owner 在
/// 现有布局中不改变实际操作归属，故不重复纳入。
///
/// 这是纯值类型：只含标量与字符串，不引用 native、窗口或控制器。窗口从
/// accepted 布局节点提取字段，驱动只按值比较，测试可完全确定地构造。
public class CjguiComposableUiAnimationBinding {
    public let windowInstanceToken: Int64
    public let acceptedBindingEpoch: Int64
    public let nodeId: Int64
    public let resourceId: Int64
    public let nodeKind: Int64
    public let actionName: String
    public let operationActionName: String
    public let operationResourceId: Int64
    public let fieldId: String

    public init(nodeId: Int64, resourceId!: Int64 = -1, nodeKind!: Int64 = -1, actionName!: String = "",
        operationActionName!: String = "", operationResourceId!: Int64 = -1, fieldId!: String = "",
        windowInstanceToken!: Int64 = 0, acceptedBindingEpoch!: Int64 = 0) {
        this.windowInstanceToken = windowInstanceToken
        this.acceptedBindingEpoch = acceptedBindingEpoch
        this.nodeId = nodeId
        this.resourceId = resourceId
        this.nodeKind = nodeKind
        this.actionName = actionName
        this.operationActionName = operationActionName
        this.operationResourceId = operationResourceId
        this.fieldId = fieldId
    }

    /// 是否同一槽位绑定：全部代际判据一致才算“同一绑定”。任一项变化都是换绑，
    /// 调用方必须丢弃旧通道，而不是把它当作改目标。
    public func matches(other: CjguiComposableUiAnimationBinding): Bool {
        return this.windowInstanceToken == other.windowInstanceToken &&
            this.acceptedBindingEpoch == other.acceptedBindingEpoch &&
            this.sameContent(other)
    }

    /// Content decides whether an accepted candidate retains the epoch. A
    /// previous A token never becomes valid again after A→B→A.
    public func sameContent(other: CjguiComposableUiAnimationBinding): Bool {
        return this.nodeId == other.nodeId && this.resourceId == other.resourceId && this.nodeKind == other.nodeKind &&
            this.actionName == other.actionName && this.operationActionName == other.operationActionName &&
            this.operationResourceId == other.operationResourceId && this.fieldId == other.fieldId
    }
}

/// 一个节点的 paint 透明度动效绑定。身份是 accepted 场景里的 `identityKey`，
/// 代际不再只是 `nodeId`：同 key 下直接换绑 resource/action/节点种类也会得到
/// 新的槽位身份，从而让旧绑定自然失效——“旧完成不会落到新实例”。同 key 重排
/// 保持 nodeId 与动画连续，被移除后重新出现会得到新 nodeId，同样失效。
public class CjguiComposableUiNodePaintAnimation {
    public let windowInstanceToken: Int64
    public let identityKey: String
    /// 建立这条绑定时 accepted 场景的槽位身份。同 key 换槽后它不再匹配新绑定，
    /// 候选 paint 与接受后存活检查都据此丢弃旧通道。
    public let binding: CjguiComposableUiAnimationBinding
    /// 兼容视图：最新绑定的 nodeId。判据请用 `binding.matches`。
    public let nodeId: Int64
    private var scalar: CjguiComposableUiScalarAnimation
    private var lastSeenProjectionEpoch: Int64

    init(windowInstanceToken: Int64, identityKey: String, binding: CjguiComposableUiAnimationBinding,
        scalar: CjguiComposableUiScalarAnimation, projectionEpoch: Int64) {
        this.windowInstanceToken = windowInstanceToken
        this.identityKey = identityKey
        this.binding = binding
        this.nodeId = binding.nodeId
        this.scalar = scalar
        this.lastSeenProjectionEpoch = projectionEpoch
    }

    public func advanceTo(nowMs: Float64): Float64 {
        return scalar.advanceTo(nowMs)
    }

    public func retarget(target: Float64, nowMs: Float64): Bool {
        return scalar.retarget(target, nowMs)
    }

    /// 用新规格重建运动学，保留当前呈现值与速度。调用方先比较规格，只有确实
    /// 不同才重建，避免每帧无谓分配。规格或输入被拒时返回假并保持旧通道不变。
    func respecify(spec: CjguiComposableUiAnimationSpec, nowMs: Float64): Bool {
        if (let Some(rebuilt) <- CjguiComposableUiScalarAnimation.retuned(scalar.presented(), scalar.target(),
            scalar.velocity(), nowMs, spec)) {
            scalar = rebuilt
            return true
        }
        return false
    }

    /// 上一次有效推进/改目标时间，供驱动做时间倒退拒绝。
    public func lastTime(): Float64 {
        return scalar.lastTime()
    }

    func matchesSpec(spec: CjguiComposableUiAnimationSpec): Bool {
        let current = scalar.spec()
        return current.kind == spec.kind && current.durationMs == spec.durationMs && current.easing == spec.easing &&
            current.stiffness == spec.stiffness && current.dampingRatio == spec.dampingRatio
    }

    public func converge(): Unit {
        scalar.converge()
    }

    public func presented(): Float64 {
        return scalar.presented()
    }

    public func target(): Float64 {
        return scalar.target()
    }

    public func isActive(): Bool {
        return scalar.isActive()
    }

    func markSeen(projectionEpoch: Int64): Unit {
        lastSeenProjectionEpoch = projectionEpoch
    }

    func isStale(projectionEpoch: Int64): Bool {
        return lastSeenProjectionEpoch < projectionEpoch
    }
}

/// 一个窗口实例的动效驱动。它只保存动画目标与当前视觉值；窗口的 accepted
/// 场景仍持有样式目标，业务 owner 仍持有业务目标。驱动从不写回 accepted
/// scene，也从不调用控制器。
public class CjguiComposableUiAnimationDriver {
    /// 有界绑定数：动画只可能绑定在已存在的 accepted 节点上，上限与场景容量
    /// 同阶，避免任何无界增长。
    public static let MAXIMUM_BINDING_COUNT: Int64 = 1024

    private let windowInstanceTokenValue: Int64
    private var entries: ArrayList<CjguiComposableUiNodePaintAnimation>
    /// A separate opacity channel for accepted isolated effect groups. Entries
    /// share the scalar clock and binding type with node paint opacity, while
    /// remaining independently retargetable and cancelable.
    private var effectGroupEntries: ArrayList<CjguiComposableUiNodePaintAnimation>
    /// paint 颜色过渡条目（background/border/textColor）。与 alpha 条目共享绑定
    /// 上限与推进/收敛/清理流程，但运动学彼此独立：颜色改变 RGB（native 需重建
    /// 文字纹理），alpha 只改绘制乘子（零重建）。
    private var colorEntries: ArrayList<CjguiComposableUiNodePaintColorAnimation>
    /// Local X/Y channels share this driver's clock and accepted binding
    /// budget, but retain a separate successful-scene checkpoint.
    private var positionEntries: ArrayList<CjguiComposableUiNodePositionAnimation>
    private var positionMutationRevisionValue: Int64
    private var positionCommittedRevisionValue: Int64
    private var nextPositionChannelGeneration: Int64
    private var reduceMotionValue: Bool
    private var pausedValue: Bool
    private var projectionEpochValue: Int64
    private var rejectedBindingCountValue: Int64
    /// 时间通道是否仍在推进，与「当前视觉投影是否尚未成功提交」是两件事：
    /// reduce-motion 收敛、零时长补间、或最后一帧提交失败后，通道已 inactive
    /// 但终值尚未落到画面。这个独立的脏标记保证终值一定被提交一次（失败可重试）。
    private var presentationMutationRevisionValue: Int64
    private var presentationCommittedRevisionValue: Int64
    /// 最近一次显式推进的时间戳（毫秒）。交互状态变化由投影触发 retarget，而
    /// 投影没有时间参数：它使用本值作为 retarget 时间起点，因此整条交互过渡
    /// 只由显式的 `advance` 序列驱动，确定性可复现。
    private var currentTimeMsValue: Float64

    public init(windowInstanceToken: Int64) {
        this.windowInstanceTokenValue = windowInstanceToken
        this.entries = ArrayList<CjguiComposableUiNodePaintAnimation>()
        this.effectGroupEntries = ArrayList<CjguiComposableUiNodePaintAnimation>()
        this.colorEntries = ArrayList<CjguiComposableUiNodePaintColorAnimation>()
        this.positionEntries = ArrayList<CjguiComposableUiNodePositionAnimation>()
        this.positionMutationRevisionValue = 0
        this.positionCommittedRevisionValue = 0
        this.nextPositionChannelGeneration = 0
        this.reduceMotionValue = false
        this.pausedValue = false
        this.projectionEpochValue = 0
        this.rejectedBindingCountValue = 0
        this.presentationMutationRevisionValue = 0
        this.presentationCommittedRevisionValue = 0
        this.currentTimeMsValue = 0.0
    }

    public func windowInstanceToken(): Int64 {
        return windowInstanceTokenValue
    }

    /// 设置系统“减少动态效果”偏好。返回真表示状态发生了变化；从关闭切到
    /// 开启时，所有活动通道立即收敛到各自目标，已有动画有确定收敛路径。
    public func setReduceMotion(enabled: Bool): Bool {
        if (reduceMotionValue == enabled) {
            return false
        }
        reduceMotionValue = enabled
        if (enabled) {
            convergeAll()
            // 收敛改变了当前视觉值：即使通道随即 inactive，也必须再提交一次终值，
            // 否则画面可能停在中间值。
            if (hasAnyBinding()) {
                presentationMutationRevisionValue += 1
            }
        }
        return true
    }

    public func reduceMotion(): Bool {
        return reduceMotionValue
    }

    /// 暂停时不推进任何通道，也不产生新帧需求；恢复后用显式时间继续，长暂停
    /// 跨度按有界收敛处理，不会跳变拼接。
    public func setPaused(paused: Bool): Unit {
        pausedValue = paused
    }

    public func isPaused(): Bool {
        return pausedValue
    }

    /// 为 accepted 节点的 paint 透明度设置目标。首次绑定从当前呈现值 1.0
    /// 起步；同一槽位身份（identityKey 与全部代际判据一致）再次调用是改目标，
    /// 保留当前值与速度。返回真表示建立了绑定或完成了改目标。
    ///
    /// 拒绝语义（返回假且**不改变任何既有绑定**）：
    ///   * identityKey 为空或 nodeId < 0；
    ///   * target 为 NaN/±Infinity（**先验证再夹取**，绝不把 NaN 静默改成 1.0、
    ///     把 ±Inf 静默改成端点）；
    ///   * nowMs 为 NaN/±Infinity，或早于该绑定上一次有效时间（时间倒退）；
    ///   * spec 由非有限输入构造（`spec.isRejected()`）；
    ///   * `token` 非空且与本次槽位身份不一致（异步旧调用落到新实例时必须失效）。
    ///
    /// 同 key 下任一槽位判据变化都是“直接同槽换绑”：旧通道被立即丢弃，新绑定
    /// 从 1.0 重新起步，旧完成不会落到新实例。
    public func animateOpacity(identityKey: String, nodeId: Int64, target: Float64,
        spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.spring(), nowMs!: Float64 = 0.0,
        resourceId!: Int64 = -1, nodeKind!: Int64 = -1, actionName!: String = "", operationActionName!: String = "",
        operationResourceId!: Int64 = -1, fieldId!: String = "", token!: ?CjguiComposableUiAnimationBinding = None,
        acceptedBindingEpoch!: Int64 = 0): Bool {
        if (identityKey.size == 0 || nodeId < 0) {
            return false
        }
        // 1) 先验证外部输入，再做任何状态变更或夹取。
        if (!cjguiAnimationIsFiniteScalar(target) || !cjguiAnimationIsFiniteScalar(nowMs) || spec.isRejected()) {
            return false
        }
        let binding = CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind,
            actionName: actionName, operationActionName: operationActionName, operationResourceId: operationResourceId,
            fieldId: fieldId, windowInstanceToken: if (acceptedBindingEpoch > 0) { windowInstanceTokenValue } else { 0 },
            acceptedBindingEpoch: acceptedBindingEpoch)
        // 2) 期望 token：异步旧调用必须与本次槽位身份一致才允许生效。
        if (let Some(expected) <- token) {
            if (!expected.matches(binding)) {
                return false
            }
        }
        // 3) 已存在的同槽绑定：拒绝时间倒退；换规格/改目标任一被拒都保持旧状态。
        let existingIndex = indexOf(identityKey)
        var reboundIndex: Int64 = -1
        if (existingIndex >= 0) {
            let existing = entries[existingIndex]
            if (existing.binding.matches(binding)) {
                if (nowMs < existing.lastTime()) {
                    return false
                }
                if (!existing.matchesSpec(spec)) {
                    if (!existing.respecify(spec, nowMs)) {
                        return false
                    }
                }
                if (!existing.retarget(clampUnit(target), nowMs)) {
                    return false
                }
                if (reduceMotionValue) {
                    existing.converge()
                }
                existing.markSeen(projectionEpochValue)
                presentationMutationRevisionValue += 1
                return true
            }
            // 换绑：同 key 已指向新的槽位身份（新代际或同槽换 resource/action/
            // 节点种类/业务操作目标/字段）。旧通道的完成与数值一律丢弃；真正的
            // 移除延迟到新绑定构造成功之后，保证被拒输入不产生副作用。
            reboundIndex = existingIndex
        }
        let capacityExceeded = reboundIndex < 0 &&
            entries.size + effectGroupEntries.size + colorEntries.size + positionEntries.size >= CjguiComposableUiAnimationDriver
                .MAXIMUM_BINDING_COUNT
        if (capacityExceeded) {
            rejectedBindingCountValue += 1
            return false
        }
        let boundedTarget = clampUnit(target)
        let built = if (spec.kind == CjguiComposableUiAnimationKind.SPRING) {
            CjguiComposableUiScalarAnimation.sprung(1.0, boundedTarget, nowMs, spec: spec)
        } else {
            CjguiComposableUiScalarAnimation.tweened(1.0, boundedTarget, nowMs, spec: spec)
        }
        if (let Some(scalar) <- built) {
            if (reboundIndex >= 0) {
                let _ = entries.remove(at: reboundIndex)
            }
            let entry = CjguiComposableUiNodePaintAnimation(windowInstanceTokenValue, identityKey, binding, scalar,
                projectionEpochValue)
            if (reduceMotionValue) {
                entry.converge()
            }
            entries.add(entry)
            // 新绑定的初始视觉值（可能已 settled）同样需要一次投影提交。
            presentationMutationRevisionValue += 1
            return true
        }
        return false
    }

    /// Animate the opacity of one accepted isolated effect group. Its scalar
    /// state is separate from `animateOpacity`, but uses the same monotonic
    /// clock, accepted binding token, redirect rules and reduced-motion path.
    public func animateEffectGroupOpacity(identityKey: String, nodeId: Int64, initial: Float64, target: Float64,
        spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.spring(), nowMs!: Float64 = 0.0,
        resourceId!: Int64 = -1, nodeKind!: Int64 = -1, actionName!: String = "", operationActionName!: String = "",
        operationResourceId!: Int64 = -1, fieldId!: String = "", token!: ?CjguiComposableUiAnimationBinding = None,
        acceptedBindingEpoch!: Int64 = 0): Bool {
        if (identityKey.size == 0 || nodeId < 0) {
            return false
        }
        if (!cjguiAnimationIsFiniteScalar(initial) || !cjguiAnimationIsFiniteScalar(target) ||
            !cjguiAnimationIsFiniteScalar(nowMs) || spec.isRejected()) {
            return false
        }
        let binding = CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind,
            actionName: actionName, operationActionName: operationActionName, operationResourceId: operationResourceId,
            fieldId: fieldId, windowInstanceToken: if (acceptedBindingEpoch > 0) { windowInstanceTokenValue } else { 0 },
            acceptedBindingEpoch: acceptedBindingEpoch)
        if (let Some(expected) <- token) {
            if (!expected.matches(binding)) {
                return false
            }
        }
        let existingIndex = effectGroupIndexOf(identityKey)
        var reboundIndex: Int64 = -1
        if (existingIndex >= 0) {
            let existing = effectGroupEntries[existingIndex]
            if (existing.binding.matches(binding)) {
                if (nowMs < existing.lastTime()) {
                    return false
                }
                if (!existing.matchesSpec(spec)) {
                    if (!existing.respecify(spec, nowMs)) {
                        return false
                    }
                }
                if (!existing.retarget(clampUnit(target), nowMs)) {
                    return false
                }
                if (reduceMotionValue) {
                    existing.converge()
                }
                existing.markSeen(projectionEpochValue)
                presentationMutationRevisionValue += 1
                return true
            }
            reboundIndex = existingIndex
        }
        let capacityExceeded = reboundIndex < 0 &&
            entries.size + effectGroupEntries.size + colorEntries.size + positionEntries.size >= CjguiComposableUiAnimationDriver.MAXIMUM_BINDING_COUNT
        if (capacityExceeded) {
            rejectedBindingCountValue += 1
            return false
        }
        let boundedInitial = clampUnit(initial)
        let boundedTarget = clampUnit(target)
        let built = if (spec.kind == CjguiComposableUiAnimationKind.SPRING) {
            CjguiComposableUiScalarAnimation.sprung(boundedInitial, boundedTarget, nowMs, spec: spec)
        } else {
            CjguiComposableUiScalarAnimation.tweened(boundedInitial, boundedTarget, nowMs, spec: spec)
        }
        if (let Some(scalar) <- built) {
            if (reboundIndex >= 0) {
                let _ = effectGroupEntries.remove(at: reboundIndex)
            }
            let entry = CjguiComposableUiNodePaintAnimation(windowInstanceTokenValue, identityKey, binding, scalar,
                projectionEpochValue)
            if (reduceMotionValue) {
                entry.converge()
            }
            effectGroupEntries.add(entry)
            presentationMutationRevisionValue += 1
            return true
        }
        return false
    }

    /// 推进所有通道。返回本轮是否有任何当前视觉值发生变化（窗口据此决定是否
    /// 走一次 paint-only 提交）。暂停时不推进。
    public func advance(nowMs: Float64): Bool {
        if (pausedValue) {
            return false
        }
        var changed = false
        for (entry in entries) {
            let before = entry.presented()
            let after = entry.advanceTo(nowMs)
            if (after != before) {
                changed = true
            }
        }
        for (entry in effectGroupEntries) {
            let before = entry.presented()
            let after = entry.advanceTo(nowMs)
            if (after != before) {
                changed = true
            }
        }
        for (entry in colorEntries) {
            let before = entry.presentedColorSet()
            let after = entry.advanceTo(nowMs)
            if (!CjguiComposableUiAnimationDriver.sameColorSet(before, after)) {
                changed = true
            }
        }
        for (entry in positionEntries) {
            if (entry.advanceTo(nowMs)) {
                changed = true
                positionMutationRevisionValue += 1
            }
        }
        if (changed) {
            // 视觉值发生了变化，终值尚未（或尚未确认）落到画面。
            presentationMutationRevisionValue += 1
        }
        // 只有严格向前的合法时间才推进"交互 retarget 的当前时间"，时间倒退/非法
        // 输入不改变它（与标量通道的拒绝语义一致）。
        if (cjguiAnimationIsFiniteScalar(nowMs) && nowMs > currentTimeMsValue) {
            currentTimeMsValue = nowMs
        }
        return changed
    }

    /// 是否必须为本窗再提交一次视觉投影：有未提交的终值。与「时间通道是否活动」
    /// 分开保存，所以 reduce-motion 收敛、零时长补间和提交失败重试都能收敛。
    public func hasPendingPresentation(): Bool {
        return presentationMutationRevisionValue > presentationCommittedRevisionValue ||
            positionMutationRevisionValue > positionCommittedRevisionValue
    }

    /// 一次投影确认成功（native 已受理或已提交）后由窗口调用，清除脏标记。
    public func presentationRevision(): Int64 { return presentationMutationRevisionValue }

    /// A receipt acknowledges only visual work that existed when its picture was
    /// projected. A later request remains dirty even if an older ticket accepts.
    public func markPresentationCommitted(revision!: Int64 = -1): Unit {
        let acknowledged = if (revision < 0) { presentationMutationRevisionValue } else { revision }
        if (acknowledged > presentationCommittedRevisionValue && acknowledged <= presentationMutationRevisionValue) {
            presentationCommittedRevisionValue = acknowledged
        }
    }

    /// 调度是否仍需要下一次机会：有活动通道，或有未提交的终值。暂停时返回假：
    /// 暂停既不推进，也不应让宿主继续按动画帧预算唤醒。
    public func needsTick(): Bool {
        if (pausedValue) {
            return false
        }
        return hasActive() || hasPendingPresentation()
    }

    /// 是否仍有活动通道。停止后为假：宿主不再为本窗申请下一帧，帧请求收敛。
    public func hasActive(): Bool {
        for (entry in entries) {
            if (entry.isActive()) {
                return true
            }
        }
        for (entry in effectGroupEntries) {
            if (entry.isActive()) {
                return true
            }
        }
        for (entry in colorEntries) {
            if (entry.isActive()) {
                return true
            }
        }
        for (entry in positionEntries) {
            if (entry.isActive()) { return true }
        }
        return false
    }

    public func activeCount(): Int64 {
        var count: Int64 = 0
        for (entry in entries) {
            if (entry.isActive()) {
                count += 1
            }
        }
        for (entry in effectGroupEntries) {
            if (entry.isActive()) {
                count += 1
            }
        }
        for (entry in colorEntries) {
            if (entry.isActive()) {
                count += 1
            }
        }
        for (entry in positionEntries) {
            if (entry.isActive()) { count += 1 }
        }
        return count
    }

    public func boundCount(): Int64 {
        return entries.size + effectGroupEntries.size + colorEntries.size + positionEntries.size
    }

    /// 是否已有任一类绑定（alpha 或颜色过渡）。
    func hasAnyBinding(): Bool {
        return entries.size > 0 || effectGroupEntries.size > 0 || colorEntries.size > 0 || positionEntries.size > 0
    }

    /// 是否已有该身份的颜色过渡绑定（窗口据此决定是否读取呈现色）。
    public func hasColorBinding(identityKey: String): Bool {
        return colorIndexOf(identityKey) >= 0
    }

    public func colorBoundCount(): Int64 {
        return colorEntries.size
    }

    public func rejectedBindingCount(): Int64 {
        return rejectedBindingCountValue
    }

    /// 当前投影用的 paint alpha 乘子，始终夹在 [0,1]。只有槽位身份完全匹配
    /// （identityKey + nodeId/resourceId/actionName/nodeKind）才返回动画值；同槽
    /// 换绑后旧绑定不再是“同一绑定”，对新节点返回 1.0，不会把旧动画画到新实例。
    /// 弹簧即使选择欠阻尼而过冲，也不会把节点 paint 推进非法 alpha 域。
    public func alphaMultiplierFor(identityKey: String, nodeId: Int64, resourceId!: Int64 = -1, nodeKind!: Int64 = -1,
        actionName!: String = "", operationActionName!: String = "", operationResourceId!: Int64 = -1,
        fieldId!: String = "", acceptedBindingEpoch!: Int64 = 0): Float64 {
        let index = indexOf(identityKey)
        if (index < 0) {
            return 1.0
        }
        let entry = entries[index]
        let binding = CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind,
            actionName: actionName, operationActionName: operationActionName, operationResourceId: operationResourceId,
            fieldId: fieldId, windowInstanceToken: if (acceptedBindingEpoch > 0) { windowInstanceTokenValue } else { 0 },
            acceptedBindingEpoch: acceptedBindingEpoch)
        if (!entry.binding.matches(binding)) {
            return 1.0
        }
        return clampUnit(entry.presented())
    }

    /// Current absolute opacity for an accepted effect group. Missing or
    /// generation-mismatched channels leave the accepted group declaration intact.
    public func effectGroupOpacityFor(identityKey: String, nodeId: Int64, resourceId!: Int64 = -1,
        nodeKind!: Int64 = -1, actionName!: String = "", operationActionName!: String = "",
        operationResourceId!: Int64 = -1, fieldId!: String = "", acceptedBindingEpoch!: Int64 = 0,
        fallback!: Float64 = 1.0): Float64 {
        let index = effectGroupIndexOf(identityKey)
        if (index < 0) {
            return fallback
        }
        let entry = effectGroupEntries[index]
        let binding = CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind,
            actionName: actionName, operationActionName: operationActionName, operationResourceId: operationResourceId,
            fieldId: fieldId, windowInstanceToken: if (acceptedBindingEpoch > 0) { windowInstanceTokenValue } else { 0 },
            acceptedBindingEpoch: acceptedBindingEpoch)
        if (!entry.binding.matches(binding)) {
            return fallback
        }
        return clampUnit(entry.presented())
    }

    public func isEffectGroupActiveFor(identityKey: String): Bool {
        let index = effectGroupIndexOf(identityKey)
        return index >= 0 && effectGroupEntries[index].isActive()
    }

    public func effectGroupOpacityPresented(identityKey: String): ?Float64 {
        let index = effectGroupIndexOf(identityKey)
        if (index < 0) { return None }
        return Some(effectGroupEntries[index].presented())
    }

    public func effectGroupOpacityTarget(identityKey: String): ?Float64 {
        let index = effectGroupIndexOf(identityKey)
        if (index < 0) { return None }
        return Some(effectGroupEntries[index].target())
    }

    /// 同步一个节点的 paint 颜色过渡目标（background/border/textColor）。窗口在
    /// 交互状态变化后的投影里调用：首次为目标值建立已静止通道（画面即目标色），
    /// 之后目标变化从当前呈现值/速度续接，因此中途反向连续。
    ///
    /// 拒绝语义（返回假且不改变任何既有颜色绑定）：identity 空、nodeId<0、
    /// 目标色含非有限分量、规格被拒、或达到绑定上限。
    public func syncInteractionPaint(identityKey: String, nodeId: Int64, target: CjguiComposableUiPaintColorSet,
        spec!: CjguiComposableUiAnimationSpec = CjguiComposableUiAnimationSpec.tween(), resourceId!: Int64 = -1,
        nodeKind!: Int64 = -1, actionName!: String = "", operationActionName!: String = "",
        operationResourceId!: Int64 = -1, fieldId!: String = "", acceptedBindingEpoch!: Int64 = 0): Bool {
        if (identityKey.size == 0 || nodeId < 0) {
            return false
        }
        if (spec.isRejected() || !target.isFinite()) {
            return false
        }
        let binding = CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind,
            actionName: actionName, operationActionName: operationActionName, operationResourceId: operationResourceId,
            fieldId: fieldId, windowInstanceToken: if (acceptedBindingEpoch > 0) { windowInstanceTokenValue } else { 0 },
            acceptedBindingEpoch: acceptedBindingEpoch)
        let existingIndex = colorIndexOf(identityKey)
        if (existingIndex >= 0) {
            let existing = colorEntries[existingIndex]
            if (existing.binding.matches(binding)) {
                // A normal refresh must not restart an in-flight tween when its
                // accepted target and rule are unchanged.
                if (CjguiComposableUiAnimationDriver.sameColorSet(existing.targetColorSet(), target) &&
                    existing.matchesSpec(spec)) {
                    return true
                }
                if (!existing.matchesSpec(spec)) {
                    if (!existing.respecify(spec, currentTimeMsValue)) {
                        return false
                    }
                }
                if (existing.retarget(target, currentTimeMsValue)) {
                    // reduce-motion 下状态过渡必须立即到达目标，而不是停在起点等
                    // 下一帧；与 alpha 动画使用同一条收敛语义。
                    if (reduceMotionValue) {
                        existing.converge()
                    }
                    presentationMutationRevisionValue += 1
                }
                return true
            }
            // 换绑：旧颜色过渡失效，丢弃后按新槽位身份重建。
            let _ = colorEntries.remove(at: existingIndex)
        }
        if (entries.size + effectGroupEntries.size + colorEntries.size + positionEntries.size >=
            CjguiComposableUiAnimationDriver.MAXIMUM_BINDING_COUNT) {
            rejectedBindingCountValue += 1
            return false
        }
        let built = match (CjguiComposableUiNodePaintColorAnimation.settled(identityKey, binding, target, spec,
            currentTimeMsValue)) {
            case Some(value) => value
            case None => return false
        }
        if (reduceMotionValue) {
            built.converge()
        }
        colorEntries.add(built)
        presentationMutationRevisionValue += 1
        return true
    }

    /// 该身份当前的颜色呈现值；无匹配槽位绑定时返回 None（窗口据此回退到
    /// 已解析的交互样式）。
    public func paintColorFor(identityKey: String, nodeId: Int64, resourceId!: Int64 = -1, nodeKind!: Int64 = -1,
        actionName!: String = "", operationActionName!: String = "", operationResourceId!: Int64 = -1,
        fieldId!: String = "", acceptedBindingEpoch!: Int64 = 0): ?CjguiComposableUiPaintColorSet {
        let index = colorIndexOf(identityKey)
        if (index < 0) {
            return None
        }
        let entry = colorEntries[index]
        let binding = CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind,
            actionName: actionName, operationActionName: operationActionName, operationResourceId: operationResourceId,
            fieldId: fieldId, windowInstanceToken: if (acceptedBindingEpoch > 0) { windowInstanceTokenValue } else { 0 },
            acceptedBindingEpoch: acceptedBindingEpoch)
        if (!entry.binding.matches(binding)) {
            return None
        }
        return Some(entry.presentedColorSet())
    }

    /// 该身份当前的颜色动画目标值；无匹配槽位绑定时返回 None。用于诊断与验收，
    /// 不参与投影合成。
    public func paintColorTargetFor(identityKey: String, nodeId: Int64, resourceId!: Int64 = -1, nodeKind!: Int64 = -1,
        actionName!: String = "", operationActionName!: String = "", operationResourceId!: Int64 = -1,
        fieldId!: String = "", acceptedBindingEpoch!: Int64 = 0): ?CjguiComposableUiPaintColorSet {
        let index = colorIndexOf(identityKey)
        if (index < 0) {
            return None
        }
        let entry = colorEntries[index]
        let binding = CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind,
            actionName: actionName, operationActionName: operationActionName, operationResourceId: operationResourceId,
            fieldId: fieldId, windowInstanceToken: if (acceptedBindingEpoch > 0) { windowInstanceTokenValue } else { 0 },
            acceptedBindingEpoch: acceptedBindingEpoch)
        if (!entry.binding.matches(binding)) {
            return None
        }
        return Some(entry.targetColorSet())
    }

    public func isColorActiveFor(identityKey: String, nodeId: Int64, resourceId!: Int64 = -1,
        nodeKind!: Int64 = -1, actionName!: String = "", operationActionName!: String = "",
        operationResourceId!: Int64 = -1, fieldId!: String = "", acceptedBindingEpoch!: Int64 = 0): Bool {
        let index = colorIndexOf(identityKey)
        if (index < 0) { return false }
        let binding = CjguiComposableUiAnimationBinding(nodeId, resourceId: resourceId, nodeKind: nodeKind,
            actionName: actionName, operationActionName: operationActionName, operationResourceId: operationResourceId,
            fieldId: fieldId, windowInstanceToken: if (acceptedBindingEpoch > 0) { windowInstanceTokenValue } else { 0 },
            acceptedBindingEpoch: acceptedBindingEpoch)
        return colorEntries[index].binding.matches(binding) && colorEntries[index].isActive()
    }

    /// Set a node's local post-layout translation in logical points. A new
    /// channel begins at the accepted local value; retargets begin at the last
    /// accepted sample, never at a speculative or rejected scalar advance.
    public func animatePosition(identityKey: String, binding: CjguiComposableUiAnimationBinding,
        initial: CjguiComposableUiPositionValue, target: CjguiComposableUiPositionValue,
        spec: CjguiComposableUiAnimationSpec, nowMs: Float64): Bool {
        if (identityKey.size == 0 || binding.nodeId < 0 || spec.isRejected() ||
            !cjguiAnimationIsFiniteScalar(nowMs) || !CjguiComposableUiAnimationDriver.validPosition(initial) ||
            !CjguiComposableUiAnimationDriver.validPosition(target)) { return false }
        let index = positionIndexOf(identityKey)
        var replacing = false
        if (index >= 0) {
            let existing = positionEntries[index]
            if (existing.binding.matches(binding)) {
                if (nowMs < existing.lastTime()) { return false }
                let oldTarget = existing.target()
                if (oldTarget.x == target.x && oldTarget.y == target.y && existing.matchesSpec(spec)) { return true }
                if (!existing.retarget(target, spec, nowMs)) { return false }
                if (reduceMotionValue) { let _ = existing.converge() }
                positionMutationRevisionValue += 1
                return true
            }
            replacing = true
        }
        if (!replacing && boundCount() >= CjguiComposableUiAnimationDriver.MAXIMUM_BINDING_COUNT) {
            rejectedBindingCountValue += 1
            return false
        }
        let builtX = CjguiComposableUiScalarAnimation.retuned(initial.x, target.x, 0.0, nowMs, spec)
        let builtY = CjguiComposableUiScalarAnimation.retuned(initial.y, target.y, 0.0, nowMs, spec)
        if (let Some(x) <- builtX) {
            if (let Some(y) <- builtY) {
                if (replacing) { let _ = positionEntries.remove(at: index) }
                nextPositionChannelGeneration += 1
                let entry = CjguiComposableUiNodePositionAnimation(identityKey, binding, x, y, initial,
                    channelGeneration: nextPositionChannelGeneration)
                if (reduceMotionValue) { let _ = entry.converge() }
                positionEntries.add(entry)
                positionMutationRevisionValue += 1
                return true
            }
        }
        return false
    }

    func positionSampleFor(identityKey: String,
        binding: CjguiComposableUiAnimationBinding): ?CjguiComposableUiPositionSample {
        let index = positionIndexOf(identityKey)
        if (index < 0 || !positionEntries[index].binding.matches(binding)) { return None }
        return Some(positionEntries[index].sample())
    }

    func positionOriginStateFor(identityKey: String, binding: CjguiComposableUiAnimationBinding): ?CjguiComposableUiPositionOriginState {
        let index = positionIndexOf(identityKey)
        if (index < 0 || !positionEntries[index].binding.matches(binding)) {
            return None
        }
        return Some(positionEntries[index].originState())
    }

    func canRebasePositionOrigin(identityKey: String, binding: CjguiComposableUiAnimationBinding,
        compensation: CjguiComposableUiPositionValue): Bool {
        let index = positionIndexOf(identityKey)
        return index >= 0 && positionEntries[index].binding.matches(binding) &&
            positionEntries[index].canRebaseOrigin(compensation)
    }

    /// Transform one immutable candidate sample into the ticket's next local
    /// origin. The operation does not mutate the live animation channel.
    func rebasePositionSample(sample: CjguiComposableUiPositionSample, rebase: CjguiComposableUiPositionOriginRebase): ?CjguiComposableUiPositionSample {
        let ticket = rebase.ticket
        let currentState = match (positionOriginStateFor(ticket.identityKey, ticket.binding)) {
            case Some(value) => value
            case None => return None
        }
        if (sample.identityKey != ticket.identityKey || !sample.binding.matches(ticket.binding) ||
            sample.channelGeneration != ticket.channelGeneration || sample.originRevision != ticket.originRevision ||
            currentState.channelGeneration != ticket.channelGeneration || currentState.originRevision != ticket
            .originRevision || ticket.originRevision < 0 || ticket.originRevision == Int64.Max ||
            !CjguiComposableUiAnimationDriver.validPosition(sample.value) ||
            !canRebasePositionOrigin(ticket.identityKey, ticket.binding, rebase.compensation)) {
            return None
        }
        let shifted = CjguiComposableUiPositionValue(sample.value.x + rebase.compensation.x,
            sample.value.y + rebase.compensation.y)
        if (!CjguiComposableUiAnimationDriver.validPosition(shifted)) {
            return None
        }
        return Some(
            CjguiComposableUiPositionSample(sample.identityKey, sample.binding, shifted, sample.velocity,
                sample.revision, channelGeneration: sample.channelGeneration, originRevision: ticket.originRevision + 1))
    }

    public func positionRevision(): Int64 { return positionMutationRevisionValue }

    /// Publish only the samples of the scene that native accepted. A later
    /// retarget keeps its pending revision, including across an in-flight
    /// ticket that accepts an older candidate.
    func markPositionSamplesAccepted(samples: HashMap<String, CjguiComposableUiPositionSample>,
        stagedRevision: Int64,
        originRebases!: HashMap<String, CjguiComposableUiPositionOriginRebase> = HashMap()): Unit {
        for ((identityKey, sample) in samples) {
            let index = positionIndexOf(identityKey)
            if (index < 0) {
                continue
            }
            let entry = positionEntries[index]
            if (let Some(rebase) <- originRebases.get(identityKey)) {
                let ticket = rebase.ticket
                let state = entry.originState()
                let ticketRevisionCanAdvance = ticket.originRevision >= 0 && ticket.originRevision < Int64.Max
                let candidateIsRebased = ticketRevisionCanAdvance && sample.identityKey == identityKey &&
                    sample.binding.matches(ticket.binding) && sample.channelGeneration == ticket.channelGeneration &&
                    sample.originRevision == ticket.originRevision + 1
                let ticketIsCurrent = ticket.identityKey == identityKey && entry.binding.matches(ticket.binding) &&
                    state.channelGeneration == ticket.channelGeneration && state.originRevision == ticket
                    .originRevision && ticket.originRevision >= 0 && ticketRevisionCanAdvance &&
                    cjguiAnimationIsFiniteScalar(rebase.compensation.x) && cjguiAnimationIsFiniteScalar(
                    rebase.compensation.y)
                if (candidateIsRebased && ticketIsCurrent && entry.canRebaseOrigin(rebase.compensation)) {
                    if (entry.rebaseOrigin(rebase.compensation, ticket.originRevision + 1)) {
                        entry.accept(sample, currentTimeMsValue) }
                    continue
                }
                // Once a candidate carries an origin operation, a stale or
                // malformed sample for that identity cannot fall through to
                // ordinary acceptance in the previous coordinate system.
                continue
            }
            let state = entry.originState()
            let sameChannel = sample.channelGeneration == state.channelGeneration
            // An ordinary receipt can outlive cancellation/recreation after a
            // prior rebase. Its pixels still use the same accepted layout:
            // acknowledge them on the recreated, origin-zero channel while
            // preserving its latest target. A rebased live channel cannot be
            // overwritten by an older channel's coordinate system.
            if ((sameChannel && sample.originRevision != state.originRevision) ||
                (!sameChannel && state.originRevision != 0)) {
                continue
            }
            entry.accept(sample, currentTimeMsValue)
        }
        if (stagedRevision > positionCommittedRevisionValue && stagedRevision <= positionMutationRevisionValue) {
            positionCommittedRevisionValue = stagedRevision
        }
    }

    public func positionTargetFor(identityKey: String): ?CjguiComposableUiPositionValue {
        let index = positionIndexOf(identityKey)
        if (index < 0) { return None }
        return Some(positionEntries[index].target())
    }

    public func positionAcceptedFor(identityKey: String): ?CjguiComposableUiPositionValue {
        let index = positionIndexOf(identityKey)
        if (index < 0) { return None }
        return Some(positionEntries[index].accepted())
    }

    public func isPositionActiveFor(identityKey: String): Bool {
        let index = positionIndexOf(identityKey)
        return index >= 0 && positionEntries[index].isActive()
    }

    public func stopPositionAtAccepted(identityKey: String, nowMs: Float64): Bool {
        let index = positionIndexOf(identityKey)
        if (index < 0 || !cjguiAnimationIsFiniteScalar(nowMs) || nowMs < positionEntries[index].lastTime()) {
            return false
        }
        positionEntries[index].stopAtAccepted(nowMs)
        positionMutationRevisionValue += 1
        return true
    }

    public func cancelPosition(identityKey: String): Bool {
        let index = positionIndexOf(identityKey)
        if (index < 0) { return false }
        let _ = positionEntries.remove(at: index)
        positionMutationRevisionValue += 1
        return true
    }

    func convergePositions(): Unit {
        for (entry in positionEntries) {
            if (entry.converge()) { positionMutationRevisionValue += 1 }
        }
    }

    private static func validPosition(value: CjguiComposableUiPositionValue): Bool {
        return cjguiAnimationIsFiniteScalar(value.x) && cjguiAnimationIsFiniteScalar(value.y) &&
            value.x >= -1024.0 && value.x <= 1024.0 && value.y >= -1024.0 && value.y <= 1024.0
    }

    public func targetFor(identityKey: String): ?Float64 {
        let index = indexOf(identityKey)
        if (index < 0) {
            return None
        }
        return Some(entries[index].target())
    }

    public func presentedFor(identityKey: String): ?Float64 {
        let index = indexOf(identityKey)
        if (index < 0) {
            return None
        }
        return Some(entries[index].presented())
    }

    public func isActiveFor(identityKey: String): Bool {
        let index = indexOf(identityKey)
        if (index < 0) {
            return false
        }
        return entries[index].isActive()
    }

    /// 取消一个身份上的绑定。返回真表示确有绑定被移除。
    public func cancel(identityKey: String): Bool {
        let index = indexOf(identityKey)
        if (index < 0) {
            return false
        }
        let _ = entries.remove(at: index)
        // 取消恢复了该节点的 accepted 样式，画面需要一次重新投影。
        presentationMutationRevisionValue += 1
        return true
    }

    public func cancelEffectGroupOpacity(identityKey: String): Bool {
        let index = effectGroupIndexOf(identityKey)
        if (index < 0) { return false }
        let _ = effectGroupEntries.remove(at: index)
        presentationMutationRevisionValue += 1
        return true
    }

    public func cancelAll(): Unit {
        if (hasAnyBinding()) {
            presentationMutationRevisionValue += 1
        }
        entries.clear()
        effectGroupEntries.clear()
        colorEntries.clear()
        if (positionEntries.size > 0) { positionMutationRevisionValue += 1 }
        positionEntries.clear()
    }

    /// 把所有活动通道立即收敛到目标（减少动态效果切换、窗口关闭前的确定收尾）。
    public func convergeAll(): Unit {
        for (entry in entries) {
            entry.converge()
        }
        for (entry in effectGroupEntries) {
            entry.converge()
        }
        for (entry in colorEntries) {
            entry.converge()
        }
        for (entry in positionEntries) {
            if (entry.converge()) { positionMutationRevisionValue += 1 }
        }
        if (hasAnyBinding()) {
            presentationMutationRevisionValue += 1
        }
    }

    /// 按“本轮实际存在的 accepted 节点槽位”清理绑定。`liveBindings` 只包含窗口
    /// accepted 场景里真实投影的节点，值是它们的完整槽位身份。被移除、换代或
    /// 同槽换 resource/action/节点种类的身份在这里释放——包括已经收敛（inactive）
    /// 的残留绑定，旧完成不会落在新实例上。
    public func reconcileAccepted(liveBindings: HashMap<String, CjguiComposableUiAnimationBinding>): Unit {
        if (entries.size == 0 && effectGroupEntries.size == 0 && colorEntries.size == 0 && positionEntries.size == 0) {
            return
        }
        if (entries.size > 0) {
            let remaining = ArrayList<CjguiComposableUiNodePaintAnimation>()
            for (entry in entries) {
                if (CjguiComposableUiAnimationDriver.isLive(entry, liveBindings)) {
                    remaining.add(entry)
                }
            }
            if (remaining.size != entries.size) {
                entries = remaining
            }
        }
        if (colorEntries.size > 0) {
            let remainingColors = ArrayList<CjguiComposableUiNodePaintColorAnimation>()
            for (entry in colorEntries) {
                if (CjguiComposableUiAnimationDriver.isLiveColor(entry, liveBindings)) {
                    remainingColors.add(entry)
                }
            }
            if (remainingColors.size != colorEntries.size) {
                colorEntries = remainingColors
            }
        }
        if (positionEntries.size > 0) {
            let remainingPositions = ArrayList<CjguiComposableUiNodePositionAnimation>()
            for (entry in positionEntries) {
                if (let Some(binding) <- liveBindings.get(entry.identityKey)) {
                    if (binding.matches(entry.binding)) { remainingPositions.add(entry) }
                }
            }
            if (remainingPositions.size != positionEntries.size) {
                positionEntries = remainingPositions
            }
        }
        reconcileEffectGroupAccepted(liveBindings)
    }

    public func reconcileEffectGroupAccepted(liveBindings: HashMap<String, CjguiComposableUiAnimationBinding>): Unit {
        if (effectGroupEntries.size == 0) { return }
        let remaining = ArrayList<CjguiComposableUiNodePaintAnimation>()
        for (entry in effectGroupEntries) {
            if (CjguiComposableUiAnimationDriver.isLive(entry, liveBindings)) {
                remaining.add(entry)
            }
        }
        if (remaining.size != effectGroupEntries.size) {
            effectGroupEntries = remaining
        }
    }

    private static func isLive(entry: CjguiComposableUiNodePaintAnimation,
        liveBindings: HashMap<String, CjguiComposableUiAnimationBinding>): Bool {
        if (let Some(binding) <- liveBindings.get(entry.identityKey)) {
            return binding.matches(entry.binding)
        }
        return false
    }

    private static func isLiveColor(entry: CjguiComposableUiNodePaintColorAnimation,
        liveBindings: HashMap<String, CjguiComposableUiAnimationBinding>): Bool {
        if (let Some(binding) <- liveBindings.get(entry.identityKey)) {
            return binding.matches(entry.binding)
        }
        return false
    }

    private static func sameColorSet(left: CjguiComposableUiPaintColorSet, right: CjguiComposableUiPaintColorSet): Bool {
        return CjguiComposableUiColorChannelAnimation.sameColor(left.background, right.background) &&
            CjguiComposableUiColorChannelAnimation.sameColor(left.border, right.border) &&
            CjguiComposableUiColorChannelAnimation.sameColor(left.textColor, right.textColor)
    }

    private func indexOf(identityKey: String): Int64 {
        var index: Int64 = 0
        while (index < entries.size) {
            if (entries[index].identityKey == identityKey) {
                return index
            }
            index += 1
        }
        return -1
    }

    private func colorIndexOf(identityKey: String): Int64 {
        var index: Int64 = 0
        while (index < colorEntries.size) {
            if (colorEntries[index].identityKey == identityKey) {
                return index
            }
            index += 1
        }
        return -1
    }

    private func positionIndexOf(identityKey: String): Int64 {
        var index: Int64 = 0
        while (index < positionEntries.size) {
            if (positionEntries[index].identityKey == identityKey) { return index }
            index += 1
        }
        return -1
    }

    private func effectGroupIndexOf(identityKey: String): Int64 {
        var index: Int64 = 0
        while (index < effectGroupEntries.size) {
            if (effectGroupEntries[index].identityKey == identityKey) { return index }
            index += 1
        }
        return -1
    }

    static func clampUnit(value: Float64): Float64 {
        if (value.isNaN()) {
            return 1.0
        }
        if (value <= 0.0) {
            return 0.0
        }
        if (value >= 1.0) {
            return 1.0
        }
        return value
    }
}

/// macOS “减少动态效果”偏好查询。bridge 在 Apple 平台读
/// `NSWorkspace.accessibilityDisplayShouldReduceMotion`，不可用或非 Apple
/// 平台返回确定的默认值 0（关闭），不静默把偏好当成开启或忽略。
public class CjguiComposableUiReduceMotion {
    public static func isEnabled(): Bool {
        unsafe {
            return cjgui_macos_reduce_motion_enabled() != 0
        }
    }
}

foreign func cjgui_macos_reduce_motion_enabled(): Int32

// ===================== B2：框架级共同动效规则 =====================
//
// This is the shared rule contract used by handwritten controls, generated
// candidates and the window's interaction transition. Apps own a registry
// instance and register the rules their generated catalog can reference. The
// compatibility static readers below describe the framework's built-in set;
// consumers must use their catalog registry for application declarations.

/// One bounded tween declaration. A malformed value has a stable named refusal
/// and cannot be converted into a fallback animation.
public class CjguiGeneratedMotionRule {
    public static let MAX_NAME_LENGTH: Int64 = 64
    public static let MIN_DURATION_MS: Int64 = 40
    public static let MAX_DURATION_MS: Int64 = 2000
    public static let TOKEN_EASE_IN_OUT: String = "ease_in_out"
    public static let TOKEN_EASE_OUT: String = "ease_out"

    public let name: String
    public let durationMs: Int64
    public let easingToken: String

    public init(name: String, durationMs: Int64, easingToken: String) {
        this.name = name
        this.durationMs = durationMs
        this.easingToken = easingToken
    }

    public static func isKnownEasingToken(token: String): Bool {
        return token == TOKEN_EASE_IN_OUT || token == TOKEN_EASE_OUT
    }

    public func rejectionReason(): String {
        if (name.size == 0) {
            return "motion_name_empty"
        }
        if (name.size > CjguiGeneratedMotionRule.MAX_NAME_LENGTH) {
            return "motion_name_too_long"
        }
        let nameBytes = name.toArray()
        let first = nameBytes[0]
        let firstLetter = (first >= 65 && first <= 90) || (first >= 97 && first <= 122)
        if (!firstLetter && first != 95) {
            return "motion_name_invalid"
        }
        for (byte in nameBytes) {
            let letter = (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122)
            let digit = byte >= 48 && byte <= 57
            if (!letter && !digit && byte != 95 && byte != 45 && byte != 46) {
                return "motion_name_invalid"
            }
        }
        if (durationMs < MIN_DURATION_MS || durationMs > MAX_DURATION_MS) {
            return "motion_duration_out_of_range"
        }
        if (!CjguiGeneratedMotionRule.isKnownEasingToken(easingToken)) {
            return "motion_easing_unknown"
        }
        return ""
    }

    public func isAccepted(): Bool {
        return rejectionReason().size == 0
    }

    public func spec(): ?CjguiComposableUiAnimationSpec {
        if (!isAccepted()) {
            return None
        }
        let easing = if (easingToken == TOKEN_EASE_OUT) {
            CjguiComposableUiAnimationEasing.EASE_OUT
        } else {
            CjguiComposableUiAnimationEasing.EASE_IN_OUT
        }
        return Some(CjguiComposableUiAnimationSpec.tween(durationMs: durationMs, easing: easing))
    }
}

/// App-owned bounded registry of rules that generated declarations may name.
/// Registration is explicit and idempotence is rejected, so a published name
/// cannot silently change meaning midway through an accepted interface.
public class CjguiGeneratedMotionRegistry {
    public static let OPACITY_TRANSITION: String = "generated.opacity"
    public static let INTERACTION_TRANSITION: String = "interaction.state"
    public static let POSITION_TRANSITION: String = "generated.position"
    public static let MAX_REGISTERED_RULES: Int64 = 32

    private let rules: HashMap<String, CjguiGeneratedMotionRule>
    private let orderedNames: ArrayList<String>
    private var lastIssueValue: String

    public init() {
        this.rules = HashMap<String, CjguiGeneratedMotionRule>()
        this.orderedNames = ArrayList<String>()
        this.lastIssueValue = ""
    }

    /// Framework presets live next to the contract; applications register the
    /// returned value into their own catalog registry.
    public static func opacityTransitionRule(): CjguiGeneratedMotionRule {
        return CjguiGeneratedMotionRule(OPACITY_TRANSITION, 160, CjguiGeneratedMotionRule.TOKEN_EASE_IN_OUT)
    }

    public static func interactionTransitionRule(): CjguiGeneratedMotionRule {
        return CjguiGeneratedMotionRule(INTERACTION_TRANSITION, 180, CjguiGeneratedMotionRule.TOKEN_EASE_OUT)
    }

    public static func positionTransitionRule(): CjguiGeneratedMotionRule {
        return CjguiGeneratedMotionRule(POSITION_TRANSITION, 240, CjguiGeneratedMotionRule.TOKEN_EASE_IN_OUT)
    }

    public func registerRule(rule: CjguiGeneratedMotionRule): Bool {
        lastIssueValue = ""
        let rejection = rule.rejectionReason()
        if (rejection.size > 0) {
            lastIssueValue = rejection
            return false
        }
        if (rules.contains(rule.name)) {
            lastIssueValue = "motion_rule_duplicate:${rule.name}"
            return false
        }
        if (rules.size >= CjguiGeneratedMotionRegistry.MAX_REGISTERED_RULES) {
            lastIssueValue = "motion_rule_capacity"
            return false
        }
        rules.add(rule.name, rule)
        orderedNames.add(rule.name)
        return true
    }

    public func lastIssue(): String {
        return lastIssueValue
    }

    public func ruleFor(name: String): ?CjguiGeneratedMotionRule {
        return rules.get(name)
    }

    public func specForName(name: String): ?CjguiComposableUiAnimationSpec {
        return match (ruleFor(name)) {
            case Some(rule) => rule.spec()
            case None => None
        }
    }

    public func rejectionReasonForName(name: String): String {
        return match (ruleFor(name)) {
            case Some(rule) => rule.rejectionReason()
            case None => "motion_rule_unregistered"
        }
    }

    public func ruleNames(): ArrayList<String> {
        let names = ArrayList<String>()
        for (name in orderedNames) {
            names.add(name)
        }
        return names
    }

    public func describe(): String {
        let builder = StringBuilder()
        for (name in ruleNames()) {
            if (let Some(rule) <- ruleFor(name)) {
                builder.append("MOTION_RULE ${rule.name} duration_ms=${rule.durationMs} " +
                    "easing=${rule.easingToken} stability=experimental backend=tween\n")
            }
        }
        return builder.toString()
    }

    private static func frameworkRules(): CjguiGeneratedMotionRegistry {
        let registry = CjguiGeneratedMotionRegistry()
        let _ = registry.registerRule(opacityTransitionRule())
        let _ = registry.registerRule(interactionTransitionRule())
        let _ = registry.registerRule(positionTransitionRule())
        return registry
    }

    // Compatibility discovery functions used by existing framework callers.
    // Generated catalogs use the instance methods above.
    public static func motionRuleFor(name: String): ?CjguiGeneratedMotionRule {
        return frameworkRules().ruleFor(name)
    }

    public static func specFor(name: String): ?CjguiComposableUiAnimationSpec {
        return frameworkRules().specForName(name)
    }

    public static func rejectionReasonFor(name: String): String {
        return frameworkRules().rejectionReasonForName(name)
    }

    public static func interactionSpec(): CjguiComposableUiAnimationSpec {
        return match (frameworkRules().specForName(INTERACTION_TRANSITION)) {
            case Some(spec) => spec
            case None => CjguiComposableUiAnimationSpec.tween(durationMs: 0,
                easing: CjguiComposableUiAnimationEasing.EASE_OUT)
        }
    }

    public static func supportedRuleNames(): ArrayList<String> {
        return frameworkRules().ruleNames()
    }

    public static func capabilityLine(): String {
        return "motion_rule=${OPACITY_TRANSITION} interaction_rule=${INTERACTION_TRANSITION} " +
            "position_rule=${POSITION_TRANSITION} position_unit=logical_points " +
            "position_local_limit=-1024..1024 position_cumulative_limit=-4096..4096 " +
            "duration_range=${CjguiGeneratedMotionRule.MIN_DURATION_MS}..${CjguiGeneratedMotionRule.MAX_DURATION_MS} " +
            "easing_tokens=${CjguiGeneratedMotionRule.TOKEN_EASE_IN_OUT}|${CjguiGeneratedMotionRule.TOKEN_EASE_OUT} " +
            "backend=CjguiComposableUiAnimationSpec.tween stability=experimental " +
            CjguiComposableUiColorInterpolation.describe()
    }
}
