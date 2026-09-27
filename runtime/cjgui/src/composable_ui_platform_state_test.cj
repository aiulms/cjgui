// C 节第 2 条：最小公共平台状态快照的针对性测试。
//
// 覆盖：
//   * 快照仅在事实变化时更新；同值多次采样不重建、不推进修订、不产生新状态；
//   * 用户固定主题优先于系统跟随；
//   * 系统减少动效变化触发确定收敛，恢复后回到正常推进；
//   * 被拒候选保持当前 accepted 与有效主题，合法且不同才更新；
//   * 窗口隐藏/最小化收敛，恢复可见后回到正常推进；
//   * token 编解码往返与未知 token 拒绝。
package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private func platformStateSnapshot(
    reduceMotion!: Bool = false,
    systemColorScheme!: CjguiComposableUiColorScheme = CjguiComposableUiColorScheme.Light,
    themePreference!: CjguiComposableUiThemePreference = CjguiComposableUiThemePreference.SystemFollow,
    windowVisible!: Bool = true,
    windowMinimized!: Bool = false
): CjguiComposableUiPlatformStateSnapshot {
    return CjguiComposableUiPlatformStateSnapshot(reduceMotion, systemColorScheme, themePreference, windowVisible,
        windowMinimized)
}

private func platformStateColorSchemeToken(scheme: CjguiComposableUiColorScheme): String {
    return CjguiComposableUiPlatformStateCodec.colorSchemeToken(scheme)
}

private func platformStateThemeToken(preference: CjguiComposableUiThemePreference): String {
    return CjguiComposableUiPlatformStateCodec.themePreferenceToken(preference)
}

private class PlatformPaintTestController <: CjguiComposableUiController & CjguiComposableUiPlatformThemeConsumer {
    private var revision: Int64 = 1
    var dark: Bool = false
    var themeOffers: Int64 = 0

    public func uiSceneVersion(): Int64 { return revision }

    public func applyPlatformColorScheme(scheme: CjguiComposableUiColorScheme): Bool {
        themeOffers += 1
        let nextDark = CjguiComposableUiPlatformStateCodec.colorSchemeToken(scheme) ==
            CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK
        if (nextDark == dark) { return false }
        dark = nextDark
        revision += 1
        return true
    }

    public func buildUi(): CjguiComposableUiNode {
        let color = if (dark) { CjguiComposableUiColor(0.8, 0.0, 0.0, 1.0) }
            else { CjguiComposableUiColor(0.2, 0.0, 0.0, 1.0) }
        return cjguiComposableVertical(1, "platform-paint-root", CjguiComposableUiStyle(background: color))
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

private func platformPaintRed(window: CjguiComposableUiWindow): Float64 {
    for (node in window.acceptedSceneNodes()) {
        if (node.identityKey == "semantic:platform-paint-root") { return node.style.background.red }
    }
    return -1.0
}

@Test
func hostThemePreferenceReachesAcceptedPaintAndSameFactDoesNotRebuild(): Unit {
    let controller = PlatformPaintTestController()
    let host = CjguiMacosApplicationHost(controller)
    @Assert(host.setThemePreference("light"), true)
    @Assert(host.start(), true)
    let window = host.window()
    @Assert(platformPaintRed(window), 0.2)
    let versionBefore = window.windowProjection().sceneVersion
    let offersBefore = controller.themeOffers
    let _ = host.pumpOneTurn()
    @Assert(controller.themeOffers, offersBefore)
    @Assert(window.windowProjection().sceneVersion, versionBefore)

    @Assert(host.setThemePreference("dark"), true)
    let _ = host.pumpOneTurn()
    @Assert(platformPaintRed(window), 0.8)
    @Assert(controller.themeOffers, offersBefore + 1)
    @Assert(host.setThemePreference("unknown"), false)
    let _ = host.pumpOneTurn()
    @Assert(platformPaintRed(window), 0.8)
    // Return to the system policy through the normal host sampler. The
    // system fact may be light or dark on this machine; either way the
    // accepted scene must consume exactly the host's observed effective value.
    @Assert(host.setThemePreference("system"), true)
    let _ = host.pumpOneTurn()
    if (let Some(snapshot) <- host.platformState()) {
        let expectedRed = if (platformStateColorSchemeToken(snapshot.effectiveColorScheme()) == "dark") {
            0.8
        } else { 0.2 }
        @Assert(platformPaintRed(window), expectedRed)
    } else {
        @Assert(false, true)
    }
    host.close()
}

@Test
func platformStateTrackerOnlyRebuildsOnRealChange(): Unit {
    let tracker = CjguiComposableUiPlatformStateTracker()
    // 首次采样建立 baseline，记为一次变化。
    @Assert(tracker.observe(
        reduceMotion: false,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), true)
    @Assert(tracker.revision(), 1)
    // 同值重复采样不产生新状态、不推进修订。
    var repeatIndex = 0
    while (repeatIndex < 4) {
        @Assert(tracker.observe(
            reduceMotion: false,
            systemColorScheme: CjguiComposableUiColorScheme.Light,
            themePreference: CjguiComposableUiThemePreference.SystemFollow,
            windowVisible: true,
            windowMinimized: false
        ), false)
        repeatIndex += 1
    }
    @Assert(tracker.revision(), 1)
    // 只有一个事实变化才更新一次。
    @Assert(tracker.observe(
        reduceMotion: true,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), true)
    @Assert(tracker.revision(), 2)
    @Assert(tracker.observe(
        reduceMotion: true,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), false)
    // 恢复原值同样是一次真实变化。
    @Assert(tracker.observe(
        reduceMotion: false,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), true)
    @Assert(tracker.revision(), 3)
}

@Test
func userFixedThemeOutranksSystemFollow(): Unit {
    // 固定浅色：系统深色也不跟随。
    let fixedLight = platformStateSnapshot(systemColorScheme: CjguiComposableUiColorScheme.Dark,
        themePreference: CjguiComposableUiThemePreference.FixedLight)
    @Assert(platformStateColorSchemeToken(fixedLight.effectiveColorScheme()), "light")
    // 固定深色：系统浅色也不跟随。
    let fixedDark = platformStateSnapshot(systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.FixedDark)
    @Assert(platformStateColorSchemeToken(fixedDark.effectiveColorScheme()), "dark")
    // 只有 SystemFollow 才读取系统外观。
    let followDark = platformStateSnapshot(systemColorScheme: CjguiComposableUiColorScheme.Dark,
        themePreference: CjguiComposableUiThemePreference.SystemFollow)
    @Assert(platformStateColorSchemeToken(followDark.effectiveColorScheme()), "dark")
    let followLight = platformStateSnapshot(systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow)
    @Assert(platformStateColorSchemeToken(followLight.effectiveColorScheme()), "light")
}

@Test
func reduceMotionChangeDrivesDeterministicConvergence(): Unit {
    let tracker = CjguiComposableUiPlatformStateTracker()
    @Assert(tracker.observe(
        reduceMotion: false,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), true)
    if (let Some(snapshot) <- tracker.accepted()) {
        @Assert(snapshot.motionConverges(), false)
        @Assert(
            CjguiComposableUiPlatformStateCodec.motionPolicyToken(snapshot.motionPolicy()), "advance")
    }
    // 开启减少动效：确定收敛。
    @Assert(tracker.observe(
        reduceMotion: true,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), true)
    if (let Some(snapshot) <- tracker.accepted()) {
        @Assert(snapshot.motionConverges(), true)
        @Assert(
            CjguiComposableUiPlatformStateCodec.motionPolicyToken(snapshot.motionPolicy()), "converge")
    }
    // 关闭后恢复推进，且这一次同样被识别为变化。
    @Assert(tracker.observe(
        reduceMotion: false,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), true)
    if (let Some(snapshot) <- tracker.accepted()) {
        @Assert(snapshot.motionConverges(), false)
    }
    @Assert(tracker.revision(), 3)
}

@Test
func hiddenOrMinimizedWindowConvergesAndRestores(): Unit {
    // 任一“不可见/最小化”条件成立就确定收敛，不留下中间态。
    let hidden = platformStateSnapshot(windowVisible: false)
    @Assert(hidden.motionConverges(), true)
    @Assert(CjguiComposableUiPlatformStateCodec.motionPolicyToken(hidden.motionPolicy()), "converge")
    let minimized = platformStateSnapshot(windowMinimized: true)
    @Assert(minimized.motionConverges(), true)
    @Assert(CjguiComposableUiPlatformStateCodec.motionPolicyToken(minimized.motionPolicy()), "converge")
    // 隐藏 + 减少动效仍只是一次收敛，不产生额外状态。
    let both = platformStateSnapshot(reduceMotion: true, windowVisible: false)
    @Assert(both.motionConverges(), true)
    // 恢复可见且系统未要求减少时回到正常推进。
    let restored = platformStateSnapshot(windowVisible: true, windowMinimized: false)
    @Assert(restored.motionConverges(), false)
    @Assert(CjguiComposableUiPlatformStateCodec.motionPolicyToken(restored.motionPolicy()), "advance")

    // 隐藏与恢复各触发一次真实变化，重复隐藏不再重发。
    let tracker = CjguiComposableUiPlatformStateTracker()
    @Assert(tracker.observe(
        reduceMotion: false,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: false,
        windowMinimized: false
    ), true)
    @Assert(tracker.observe(
        reduceMotion: false,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: false,
        windowMinimized: false
    ), false)
    @Assert(tracker.observe(
        reduceMotion: false,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), true)
    @Assert(tracker.revision(), 2)
}

@Test
func rejectedThemeCandidateKeepsAcceptedState(): Unit {
    let tracker = CjguiComposableUiPlatformStateTracker()
    @Assert(tracker.observe(
        reduceMotion: false,
        systemColorScheme: CjguiComposableUiColorScheme.Light,
        themePreference: CjguiComposableUiThemePreference.SystemFollow,
        windowVisible: true,
        windowMinimized: false
    ), true)
    let acceptedRevision = tracker.revision()
    // 未知 token 被拒：accepted 与有效主题保持不动。
    @Assert(tracker.selectThemePreference("neon"), false)
    @Assert(tracker.revision(), acceptedRevision)
    @Assert(tracker.lastRejectionReason(), "unknown_theme_preference")
    if (let Some(snapshot) <- tracker.accepted()) {
        @Assert(platformStateColorSchemeToken(snapshot.effectiveColorScheme()), "light")
        @Assert(platformStateThemeToken(snapshot.themePreference), "system")
    }
    // 应用自己的策略拒绝候选同样保持 accepted 不动。
    @Assert(tracker.rejectThemeSelection(
        CjguiComposableUiThemePreference.FixedDark, "application_policy_rejected"), false)
    @Assert(tracker.revision(), acceptedRevision)
    @Assert(tracker.lastRejectionReason(), "application_policy_rejected")
    if (let Some(snapshot) <- tracker.accepted()) {
        @Assert(platformStateThemeToken(snapshot.themePreference), "system")
    }
    // 合法且不同才更新；重复同一固定主题不产生新状态。
    @Assert(tracker.selectThemePreference("dark"), true)
    @Assert(tracker.revision(), acceptedRevision + 1)
    @Assert(tracker.selectThemePreference("dark"), false)
    @Assert(tracker.revision(), acceptedRevision + 1)
    if (let Some(snapshot) <- tracker.accepted()) {
        @Assert(platformStateColorSchemeToken(snapshot.effectiveColorScheme()), "dark")
    }
}

@Test
func applicationThemePreferenceRejectsUnknownTokens(): Unit {
    let application = CjguiMacosApplication()
    @Assert(platformStateThemeToken(application.themePreference()), "system")
    @Assert(application.setThemePreference("dark"), true)
    @Assert(platformStateThemeToken(application.themePreference()), "dark")
    // 被拒 token 不改变当前选择。
    @Assert(application.setThemePreference("neon"), false)
    @Assert(platformStateThemeToken(application.themePreference()), "dark")
    @Assert(application.setThemePreference("system"), true)
    @Assert(platformStateThemeToken(application.themePreference()), "system")
}

@Test
func platformStateTokensRoundTripAndDescribeIsStable(): Unit {
    for (scheme in [CjguiComposableUiColorScheme.Light, CjguiComposableUiColorScheme.Dark]) {
        let token = CjguiComposableUiPlatformStateCodec.colorSchemeToken(scheme)
        if (let Some(parsed) <- CjguiComposableUiPlatformStateCodec.colorSchemeFromToken(token)) {
            @Assert(CjguiComposableUiPlatformStateCodec.colorSchemeToken(parsed), token)
        } else {
            @Assert(false, true)
        }
    }
    for (preference in [
        CjguiComposableUiThemePreference.SystemFollow,
        CjguiComposableUiThemePreference.FixedLight,
        CjguiComposableUiThemePreference.FixedDark
    ]) {
        let token = CjguiComposableUiPlatformStateCodec.themePreferenceToken(preference)
        if (let Some(parsed) <- CjguiComposableUiPlatformStateCodec.themePreferenceFromToken(token)) {
            @Assert(CjguiComposableUiPlatformStateCodec.themePreferenceToken(parsed), token)
        } else {
            @Assert(false, true)
        }
    }
    if (let Some(_) <- CjguiComposableUiPlatformStateCodec.colorSchemeFromToken("sepia")) {
        @Assert(false, true)
    } else {
        @Assert(true, true)
    }
    if (let Some(_) <- CjguiComposableUiPlatformStateCodec.themePreferenceFromToken("sepia")) {
        @Assert(false, true)
    } else {
        @Assert(true, true)
    }
    // 诊断摘要包含全部关键字段，且复用同一组 token。
    let described = platformStateSnapshot(reduceMotion: true, systemColorScheme: CjguiComposableUiColorScheme.Dark,
        themePreference: CjguiComposableUiThemePreference.FixedLight, windowVisible: false, windowMinimized: true)
        .describe()
    @Assert(described.contains("reduce_motion=1"), true)
    @Assert(described.contains("system=dark"), true)
    @Assert(described.contains("preference=light"), true)
    @Assert(described.contains("effective=light"), true)
    @Assert(described.contains("window_visible=0"), true)
    @Assert(described.contains("window_minimized=1"), true)
    @Assert(described.contains("motion=converge"), true)
}
