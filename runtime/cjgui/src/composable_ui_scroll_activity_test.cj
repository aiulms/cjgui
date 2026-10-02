// H2（r10 / Astra inertial-activity）：滚动物理与候选请求代次的确定性反例。
//
// 本文件钉住 Astra 裁决里**可区分实验**的期望值，而不是实现细节：
//   * 候选接受必须保留在 stage 之后新到的请求（B）的身份，只按 A 的**新**合法
//     范围夹紧；接受 A 不能把 B 记成已确认。
//   * 截止积分：T = min(Tmax, tau*ln(|v_s|/epsilon))。长暂停、掉帧、首步 2600ms
//     必须交付**同一个**约定终值，不因积分上界判断丢掉整段。
//   * `(changed, active)` 两件事必须分开：亚像素帧不白刷，停止但仍有位移必须
//     交付末帧。
//   * 滚动物理策略是**每窗口**的不可变声明，不是可变全局开关。
package cjgui

import std.collection.*
import std.time.*

private func h2Ms(count: Int64): Duration {
    return Duration.millisecond * count
}

private func h2IsExperimental(viewport: CjguiComposableUiScrollViewport): Bool {
    return match (viewport.scrollPhysicsPolicy()) {
        case CjguiComposableUiScrollPhysicsPolicy.ExperimentalExponential => true
        case CjguiComposableUiScrollPhysicsPolicy.PlatformDefault => false
    }
}

private func h2ExperimentalViewport(content: Int64, viewport: Int64, offset: Int64):
    CjguiComposableUiScrollViewport {
    let scroll = CjguiComposableUiScrollViewport()
    scroll.setScrollPhysicsPolicy(CjguiComposableUiScrollPhysicsPolicy.ExperimentalExponential)
    scroll.stageExtents(content, viewport, offset)
    scroll.commitStagedExtents()
    return scroll
}

/// Astra 给出的 A/B 判别例：初始 accepted=0、最大偏移 300。
/// 接受 A 之后 requested 必须仍属于 B，并且已经按 A 的新范围（120）夹紧。
@Test
func scrollAcceptanceKeepsTheNewerRequestIdentity(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(400, 100, 0)
    viewport.commitStagedExtents()
    @Assert(viewport.maximumOffset(), 300)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.offset(), 0)

    // A：请求 80，代次 g；候选把新最大偏移解成 120。
    @Assert(viewport.requestOffset(80), true)
    let generationA = viewport.requestGeneration()
    viewport.stageExtents(220, 100, 80)

    // B：请求 180，代次 g+1，在 A 被接受前到达。
    @Assert(viewport.requestOffset(180), true)
    @Assert(viewport.requestGeneration() > generationA, true)

    // 接受 A：accepted 用 A 的完整布局事实，requested 保留 B 并夹到 120。
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 80)
    @Assert(viewport.offset(), 120)
    @Assert(viewport.maximumOffset(), 120)
    @Assert(viewport.hasStagedExtents(), false)

    // 接受后续 B 候选：这一次布局读到的就是 B，待决收敛为 accepted。
    viewport.stageExtents(220, 100, 120)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 120)
    @Assert(viewport.offset(), 120)
    @Assert(viewport.hasPendingRequest(), false)
}

/// 初始化定位也是一次请求：它必须让先前在途候选的确认失效，否则首帧之后、
/// 接受之前的定位会被旧候选的提交吞掉。
@Test
func scrollInitialOffsetInvalidatesTheInFlightCandidate(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(400, 100, 0)
    viewport.commitStagedExtents()
    viewport.requestInitialOffset(50)
    viewport.stageExtents(400, 100, 50)
    // 新的初始化定位在提交前到达。
    viewport.requestInitialOffset(200)
    viewport.commitStagedExtents()
    @Assert(viewport.acceptedOffset(), 50)
    @Assert(viewport.offset(), 200)
}

/// 内容缩小 / 越界请求经 `clampToAccepted` 收敛时必须推进请求代次：夹紧本身是
/// 一次真实写入，不能变成无代次写入口；已经合法的请求不重复推进。
@Test
func scrollClampAdvancesTheRequestGenerationOnlyWhenItWrites(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(400, 100, 0)
    viewport.commitStagedExtents()
    // 初始化定位不做范围夹紧，故意留下一个越界请求。
    viewport.requestInitialOffset(500)
    @Assert(viewport.offset(), 500)
    let before = viewport.requestGeneration()
    viewport.clampToAccepted()
    @Assert(viewport.offset(), 300)
    @Assert(viewport.requestGeneration() > before, true)
    // 已经合法：夹紧不再写，也不再推进代次。
    viewport.clampToAccepted()
    @Assert(viewport.offset(), 300)
    @Assert(viewport.requestGeneration(), before + 1)
}

/// 丢弃未接受的候选只丢候选：accepted 保持上一次场景的事实，较新的请求身份
/// 原样保留，下一次合法刷新可以继续呈现它。
@Test
func scrollDiscardStagedExtentsKeepsAcceptedAndNewerRequest(): Unit {
    let viewport = CjguiComposableUiScrollViewport()
    viewport.stageExtents(400, 100, 0)
    viewport.commitStagedExtents()
    @Assert(viewport.requestOffset(80), true)
    viewport.stageExtents(220, 100, 80)
    @Assert(viewport.requestOffset(180), true)
    viewport.discardStagedExtents()
    @Assert(viewport.hasStagedExtents(), false)
    @Assert(viewport.acceptedOffset(), 0)
    @Assert(viewport.maximumOffset(), 300)
    @Assert(viewport.offset(), 180)
}

/// 截止积分终值（Astra 数值表）：`v_s=1` 的阈值时刻是 1496.680310446ms，
/// 全程位移 321.75px；10ms 分步、首步 2000ms、首步 2600ms 必须都交付 321px。
@Test
func inertialCutoffIntegrationDeliversTheSameTerminalDisplacement(): Unit {
    let cutoff = CjguiComposableUiScrollViewport.inertialCutoffMs(1.0)
    @Assert(cutoff > 1496.0, true)
    @Assert(cutoff < 1497.0, true)
    let integral = CjguiComposableUiScrollViewport.inertialDisplacementPx(1.0, 0.0, cutoff)
    @Assert(integral > 321.7, true)
    @Assert(integral < 321.8, true)

    // 10ms 分步直到自然结束：累加终点必须与解析终值一致。
    let stepped = h2ExperimentalViewport(1000, 100, 0)
    let start = MonoTime.now()
    @Assert(stepped.beginInertialScroll(1.0, start), true)
    var elapsedMs: Int64 = 0
    var sawChange = false
    var last = CjguiComposableUiActivityStep(false, true)
    while (last.active) {
        elapsedMs += 10
        last = stepped.stepInertialScroll(start + h2Ms(elapsedMs))
        sawChange = sawChange || last.changed
    }
    @Assert(stepped.offset(), 321)
    @Assert(sawChange, true)
    // 末帧本身可以只落在亚像素余量里（上次已经交付过整像素），此时不白刷一帧：
    // changed=false、active=false，位置已由更早的交付帧确定。
    @Assert(last.active, false)
    @Assert(stepped.isInertialScrollActive(), false)

    // 首步 2000ms：越过了阈值时刻，仍交付同一终值。
    let jumped = h2ExperimentalViewport(1000, 100, 0)
    @Assert(jumped.beginInertialScroll(1.0, start), true)
    let twoThousand = jumped.stepInertialScroll(start + h2Ms(2000))
    @Assert(jumped.offset(), 321)
    @Assert(twoThousand.changed, true)
    @Assert(twoThousand.active, false)

    // 首步 2600ms：旧的“积分前上界判断”会丢掉整段，这里必须给同一个终值。
    let stalled = h2ExperimentalViewport(1000, 100, 0)
    @Assert(stalled.beginInertialScroll(1.0, start), true)
    let twoThousandSixHundred = stalled.stepInertialScroll(start + h2Ms(2600))
    @Assert(stalled.offset(), 321)
    @Assert(twoThousandSixHundred.changed, true)
    @Assert(twoThousandSixHundred.active, false)
}

/// 反方向：`v_s=-1` 首步 2600ms 交付 −321px，且绝不越过内容起点。
@Test
func inertialCutoffIntegrationIsSymmetricForNegativeVelocity(): Unit {
    let viewport = h2ExperimentalViewport(1000, 100, 0)
    @Assert(viewport.requestOffset(500), true)
    let start = MonoTime.now()
    @Assert(viewport.beginInertialScroll(-1.0, start), true)
    let step = viewport.stepInertialScroll(start + h2Ms(2600))
    @Assert(viewport.offset(), 500 - 321)
    @Assert(step.changed, true)
    @Assert(step.active, false)
}

/// `v_s=0.02` 首步 250ms：阈值时刻是 225.2727ms，位移 3.25px → 3px，并且本帧
/// 既改变了位置又已经停止。
@Test
func inertialSubPixelVelocityDeliversWholePixelsThenStops(): Unit {
    let viewport = h2ExperimentalViewport(1000, 100, 0)
    let start = MonoTime.now()
    @Assert(viewport.beginInertialScroll(0.02, start), true)
    let step = viewport.stepInertialScroll(start + h2Ms(250))
    @Assert(viewport.offset(), 3)
    @Assert(step.changed, true)
    @Assert(step.active, false)
}

/// 相同时间连调十次：活动仍然有效，但不制造位移、也不白刷一帧。
@Test
func inertialDuplicateTimeStaysActiveWithoutNewChange(): Unit {
    let viewport = h2ExperimentalViewport(1000, 100, 0)
    let start = MonoTime.now()
    @Assert(viewport.beginInertialScroll(1.0, start), true)
    var index: Int64 = 0
    while (index < 10) {
        let step = viewport.stepInertialScroll(start)
        @Assert(step.changed, false)
        @Assert(step.active, true)
        index += 1
    }
    @Assert(viewport.offset(), 0)
    @Assert(viewport.isInertialScrollActive(), true)
}

/// 时钟倒退：终结活动、不制造位移，也不回滚已经产生的请求。
@Test
func inertialClockBackwardsEndsWithoutChange(): Unit {
    let viewport = h2ExperimentalViewport(1000, 100, 0)
    let start = MonoTime.now()
    @Assert(viewport.beginInertialScroll(1.0, start), true)
    let step = viewport.stepInertialScroll(start - h2Ms(10))
    @Assert(step.changed, false)
    @Assert(step.active, false)
    @Assert(viewport.offset(), 0)
    @Assert(viewport.isInertialScrollActive(), false)
}

/// 触边：本帧已经移动了一部分也要交付末帧（changed=true、active=false）；
/// 随后再推进不再增加任何请求。
@Test
func inertialEdgeStopDeliversTheFinalFrameOnce(): Unit {
    let viewport = h2ExperimentalViewport(105, 100, 0)
    @Assert(viewport.maximumOffset(), 5)
    let start = MonoTime.now()
    @Assert(viewport.beginInertialScroll(1.0, start), true)
    let step = viewport.stepInertialScroll(start + h2Ms(100))
    @Assert(step.changed, true)
    @Assert(step.active, false)
    @Assert(viewport.offset(), 5)
    let after = viewport.stepInertialScroll(start + h2Ms(200))
    @Assert(after.changed, false)
    @Assert(after.active, false)
    @Assert(viewport.offset(), 5)
}

/// 准入最低契约：默认策略不合成惯性；NaN/Inf/超限、以及速度不超过阈值都不启动。
@Test
func inertialAdmissionRejectsNonFiniteBelowThresholdAndDefaultPolicy(): Unit {
    let platform = CjguiComposableUiScrollViewport()
    platform.stageExtents(1000, 100, 0)
    platform.commitStagedExtents()
    @Assert(h2IsExperimental(platform), false)
    @Assert(platform.beginInertialScroll(1.0, MonoTime.now()), false)

    let viewport = h2ExperimentalViewport(1000, 100, 0)
    @Assert(h2IsExperimental(viewport), true)
    let start = MonoTime.now()
    @Assert(viewport.beginInertialScroll(Float64.NaN, start), false)
    @Assert(viewport.beginInertialScroll(Float64.Inf, start), false)
    @Assert(viewport.beginInertialScroll(-Float64.Inf, start), false)
    @Assert(viewport.beginInertialScroll(1.0e301, start), false)
    // 等于阈值即不启动。
    @Assert(viewport.beginInertialScroll(
        CjguiComposableUiScrollViewport.inertialStopVelocityPxPerMs, start), false)
    // 刚过阈值即可启动。
    @Assert(viewport.beginInertialScroll(0.011, start), true)
    viewport.stopInertialScroll()
    @Assert(viewport.isInertialScrollActive(), false)
}

/// 策略 token：可发现的字符串入口与枚举声明走同一套校验；未知 token 具名拒绝。
@Test
func scrollPhysicsTokenAcceptsKnownRejectsUnknown(): Unit {
    let viewport = h2ExperimentalViewport(1000, 100, 0)
    @Assert(h2IsExperimental(viewport), true)
    viewport.setScrollPhysicsPolicy(CjguiComposableUiScrollPhysicsPolicy.PlatformDefault)
    @Assert(h2IsExperimental(viewport), false)
    // 声明同一个平台默认值后不合成惯性。
    @Assert(viewport.beginInertialScroll(1.0, MonoTime.now()), false)
}

private class H2ScrollController <: CjguiComposableUiController {
    let viewport: CjguiComposableUiScrollViewport
    private var revision: Int64 = 1

    init(viewport: CjguiComposableUiScrollViewport) {
        this.viewport = viewport
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "h2-host", CjguiComposableUiStyle(growX: 1, growY: 1))
        let content = cjguiComposableVertical(2, "h2-content", CjguiComposableUiStyle(gap: 0))
        var index: Int64 = 0
        while (index < 120) {
            content.add(cjguiComposableText(100 + index, "h2-row-${index}", "行${index}",
                CjguiComposableUiStyle(fixedHeight: 24)))
            index += 1
        }
        let scroll = cjguiComposableScrollArea(3, "h2-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, growY: 1))
        scroll.add(content)
        root.add(scroll)
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

/// 策略是**每窗口**的声明：一个窗口声明实验策略不会改变另一个窗口；只有被接受
/// 的滚动绑定才进入窗口活动推进，且窗口入口同时公布 `changed`/`active`。
@Test
func windowScrollPhysicsIsPerWindowAndActivitiesAreWindowOwned(): Unit {
    let experimentalViewport = CjguiComposableUiScrollViewport()
    let experimentalWindow = CjguiComposableUiWindow(H2ScrollController(experimentalViewport))
    @Assert(experimentalWindow.scrollPhysicsInfo().declared, "unset")
    // 未知 token 具名拒绝，原声明保持不变。
    @Assert(experimentalWindow.configureScrollPhysicsToken("nope"), false)
    @Assert(experimentalWindow.scrollPhysicsInfo().declared, "unset")
    @Assert(experimentalWindow.configureScrollPhysicsToken("experimental_exponential"), true)
    @Assert(experimentalWindow.scrollPhysicsInfo().declared, "experimental_exponential")
    @Assert(experimentalWindow.scrollPhysicsInfo().effective, "experimental_exponential")
    @Assert(experimentalWindow.start(), true)
    @Assert(experimentalWindow.acceptedScrollBindingCount(), 1)
    // 接受时把声明写入被接受的视口。
    @Assert(h2IsExperimental(experimentalViewport), true)

    let start = MonoTime.now()
    @Assert(experimentalViewport.beginInertialScroll(1.0, start), true)
    @Assert(experimentalWindow.hasActiveWindowActivities(), true)
    // 重复时刻：不改变位置，但活动继续，窗口必须安排下一次唤醒。
    let quiet = experimentalWindow.stepWindowActivities(start)
    @Assert(quiet.changed, false)
    @Assert(quiet.active, true)
    // 真实推进：交付位移。
    let moved = experimentalWindow.stepWindowActivities(start + h2Ms(50))
    @Assert(moved.changed, true)
    @Assert(moved.active, true)
    experimentalWindow.stopWindowActivities()
    @Assert(experimentalWindow.hasActiveWindowActivities(), false)
    experimentalWindow.close()

    // 第二个窗口保持平台默认：同一个核心策略不串扰。
    let platformViewport = CjguiComposableUiScrollViewport()
    let platformWindow = CjguiComposableUiWindow(H2ScrollController(platformViewport))
    @Assert(platformWindow.scrollPhysicsInfo().effective, "platform_default")
    @Assert(platformWindow.start(), true)
    @Assert(platformWindow.acceptedScrollBindingCount(), 1)
    @Assert(platformViewport.beginInertialScroll(1.0, MonoTime.now()), false)
    @Assert(platformWindow.hasActiveWindowActivities(), false)
    platformWindow.close()
}
