package cjgui

// P3 首个切面的最小公共平台状态快照（C 节第 2 条）。
//
// 职责：
// - 把已存在的平台事实（系统“减少动态效果”、系统外观浅色/深色、窗口可见与
//   最小化）和应用选择的主题偏好收进一个不可变快照。
// - 只在任一事实真正变化时更新 accepted 快照；同一事实重复出现不重建快照、
//   不推进修订、不重发状态，因此调用方不会每帧重建主题或业务状态。
// - 明确用户固定主题优先于系统跟随；窗口隐藏/最小化或系统减少动效时动效确定
//   收敛，恢复可见且系统未要求减少时回到正常推进；被拒的候选保持当前
//   accepted 与有效主题不动。
//
// 边界：
// - 它只携带脱水标量/enum 值，不拥有 AppKit 对象、不返回 native handle、
//   不暴露 session token。
// - 它不重建语义树，不替代应用的主题决策，也不新增每帧调度。
// - 系统强调色由独立的 PlatformAccentTracker 采集并在窗口 scene 接受后发布；
//   本快照继续只记录动效、主题和窗口可见性，避免把采样当成已绘制颜色。

/// Stability: experimental. 解析后的平台颜色方案（浅色/深色）。它是平台外观
/// 事实，不是业务配色：应用仍决定用哪个主题渲染。
public enum CjguiComposableUiColorScheme {
    | Light
    | Dark
}

/// Stability: experimental. 应用选择的主题策略。
/// `SystemFollow` 跟随系统外观；`FixedLight`/`FixedDark` 是用户显式固定，
/// 优先级高于系统跟随。
public enum CjguiComposableUiThemePreference {
    | SystemFollow
    | FixedLight
    | FixedDark
}

/// Optional application projection hook. The host supplies the effective
/// platform scheme before an ordinary scene refresh; the application chooses
/// its shared palette and advances only its UI declaration revision. Native
/// acceptance remains the sole point at which that paint becomes visible.
public interface CjguiComposableUiPlatformThemeConsumer {
    func applyPlatformColorScheme(scheme: CjguiComposableUiColorScheme): Bool
}

/// Stability: experimental. 由平台事实推导出的动效时间策略。
/// `Advance` = 正常推进；`Converge` = 确定收敛到终值（复用现有 driver 的
/// 减少动效路径），不留下中间态。
public enum CjguiComposableUiMotionPolicy {
    | Advance
    | Converge
}

// 共享 token：消费者与诊断用它们描述平台状态，不各自拼字符串。整数 native
// 事实与这些字符串 token 是同一份定义的两种投影。
public let CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_LIGHT: String = "light"
public let CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK: String = "dark"
public let CJGUI_COMPOSABLE_UI_PLATFORM_THEME_SYSTEM: String = "system"
public let CJGUI_COMPOSABLE_UI_PLATFORM_THEME_LIGHT: String = "light"
public let CJGUI_COMPOSABLE_UI_PLATFORM_THEME_DARK: String = "dark"
public let CJGUI_COMPOSABLE_UI_PLATFORM_MOTION_ADVANCE: String = "advance"
public let CJGUI_COMPOSABLE_UI_PLATFORM_MOTION_CONVERGE: String = "converge"

/// Public capability name for the window-scoped sRGB8 accent observation.
public let CJGUI_COMPOSABLE_UI_PLATFORM_SYSTEM_ACCENT_COLOR: String = "system_accent_srgb8"

/// token 编解码的单一定义点。未知 token 一律按“被拒”处理，不做静默归一化。
/// Stability: experimental.
public class CjguiComposableUiPlatformStateCodec {
    public static func colorSchemeToken(scheme: CjguiComposableUiColorScheme): String {
        return match (scheme) {
            case Light => CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_LIGHT
            case Dark => CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK
        }
    }

    public static func colorSchemeFromToken(token: String): ?CjguiComposableUiColorScheme {
        if (token == CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_LIGHT) {
            return Some(CjguiComposableUiColorScheme.Light)
        }
        if (token == CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK) {
            return Some(CjguiComposableUiColorScheme.Dark)
        }
        return None
    }

    public static func themePreferenceToken(preference: CjguiComposableUiThemePreference): String {
        return match (preference) {
            case SystemFollow => CJGUI_COMPOSABLE_UI_PLATFORM_THEME_SYSTEM
            case FixedLight => CJGUI_COMPOSABLE_UI_PLATFORM_THEME_LIGHT
            case FixedDark => CJGUI_COMPOSABLE_UI_PLATFORM_THEME_DARK
        }
    }

    public static func themePreferenceFromToken(token: String): ?CjguiComposableUiThemePreference {
        if (token == CJGUI_COMPOSABLE_UI_PLATFORM_THEME_SYSTEM) {
            return Some(CjguiComposableUiThemePreference.SystemFollow)
        }
        if (token == CJGUI_COMPOSABLE_UI_PLATFORM_THEME_LIGHT) {
            return Some(CjguiComposableUiThemePreference.FixedLight)
        }
        if (token == CJGUI_COMPOSABLE_UI_PLATFORM_THEME_DARK) {
            return Some(CjguiComposableUiThemePreference.FixedDark)
        }
        return None
    }

    public static func motionPolicyToken(policy: CjguiComposableUiMotionPolicy): String {
        return match (policy) {
            case Advance => CJGUI_COMPOSABLE_UI_PLATFORM_MOTION_ADVANCE
            case Converge => CJGUI_COMPOSABLE_UI_PLATFORM_MOTION_CONVERGE
        }
    }
}

/// 解析规则：用户固定主题优先于系统跟随。`FixedLight`/`FixedDark` 覆盖系统
/// 外观；只有 `SystemFollow` 才读取系统外观。
/// Stability: experimental.
public class CjguiComposableUiPlatformStateResolution {
    public static func resolveColorScheme(
        preference: CjguiComposableUiThemePreference,
        system: CjguiComposableUiColorScheme
    ): CjguiComposableUiColorScheme {
        return match (preference) {
            case FixedLight => CjguiComposableUiColorScheme.Light
            case FixedDark => CjguiComposableUiColorScheme.Dark
            case SystemFollow => system
        }
    }

    public static func sameColorScheme(
        left: CjguiComposableUiColorScheme,
        right: CjguiComposableUiColorScheme
    ): Bool {
        return CjguiComposableUiPlatformStateCodec.colorSchemeToken(left) ==
            CjguiComposableUiPlatformStateCodec.colorSchemeToken(right)
    }

    public static func sameThemePreference(
        left: CjguiComposableUiThemePreference,
        right: CjguiComposableUiThemePreference
    ): Bool {
        return CjguiComposableUiPlatformStateCodec.themePreferenceToken(left) ==
            CjguiComposableUiPlatformStateCodec.themePreferenceToken(right)
    }
}

/// Stability: experimental. 不可变的平台状态快照。同一时刻只有一份 accepted
/// 实例；消费者读取它而不是自己去查询平台。
public class CjguiComposableUiPlatformStateSnapshot {
    /// 系统“减少动态效果”事实。
    public let reduceMotion: Bool
    /// 系统外观事实（与用户固定偏好无关）。
    public let systemColorScheme: CjguiComposableUiColorScheme
    /// 应用选择的主题策略。
    public let themePreference: CjguiComposableUiThemePreference
    /// 目标窗口当前是否可见。
    public let windowVisible: Bool
    /// 目标窗口当前是否最小化。
    public let windowMinimized: Bool

    public init(
        reduceMotion: Bool,
        systemColorScheme: CjguiComposableUiColorScheme,
        themePreference: CjguiComposableUiThemePreference,
        windowVisible: Bool,
        windowMinimized: Bool
    ) {
        this.reduceMotion = reduceMotion
        this.systemColorScheme = systemColorScheme
        this.themePreference = themePreference
        this.windowVisible = windowVisible
        this.windowMinimized = windowMinimized
    }

    /// 应用固定主题优先后的有效颜色方案。用户显式选择不受系统外观变化影响。
    public func effectiveColorScheme(): CjguiComposableUiColorScheme {
        return CjguiComposableUiPlatformStateResolution.resolveColorScheme(themePreference, systemColorScheme)
    }

    /// 动效时间策略。系统减少动效、窗口隐藏或窗口最小化任一条成立时确定收敛到
    /// 终值（复用现有 driver 的减少动效路径）；恢复可见且系统未要求减少时正常
    /// 推进。关闭/隐藏不是暂停：收敛意味着不再请求后续帧。
    public func motionConverges(): Bool {
        return reduceMotion || !windowVisible || windowMinimized
    }

    public func motionPolicy(): CjguiComposableUiMotionPolicy {
        if (motionConverges()) {
            return CjguiComposableUiMotionPolicy.Converge
        }
        return CjguiComposableUiMotionPolicy.Advance
    }

    /// 结构相等：用于“仅变化时更新”判定。不比较对象身份。
    public func equals(other: CjguiComposableUiPlatformStateSnapshot): Bool {
        if (reduceMotion != other.reduceMotion) {
            return false
        }
        if (windowVisible != other.windowVisible) {
            return false
        }
        if (windowMinimized != other.windowMinimized) {
            return false
        }
        if (!CjguiComposableUiPlatformStateResolution.sameColorScheme(systemColorScheme, other.systemColorScheme)) {
            return false
        }
        if (!CjguiComposableUiPlatformStateResolution.sameThemePreference(themePreference, other.themePreference)) {
            return false
        }
        return true
    }

    /// 一行诊断摘要；所有值都来自同一份 token 定义。
    public func describe(): String {
        let reduceMotionToken = if (reduceMotion) {
            "1"
        } else {
            "0"
        }
        let visibleToken = if (windowVisible) {
            "1"
        } else {
            "0"
        }
        let minimizedToken = if (windowMinimized) {
            "1"
        } else {
            "0"
        }
        return "platform_state reduce_motion=${reduceMotionToken} system=${CjguiComposableUiPlatformStateCodec.colorSchemeToken(systemColorScheme)} preference=${CjguiComposableUiPlatformStateCodec.themePreferenceToken(themePreference)} effective=${CjguiComposableUiPlatformStateCodec.colorSchemeToken(effectiveColorScheme())} window_visible=${visibleToken} window_minimized=${minimizedToken} motion=${CjguiComposableUiPlatformStateCodec.motionPolicyToken(motionPolicy())}"
    }
}

/// Stability: experimental. 仅变化时更新的平台状态追踪器。
///
/// - 首次采样建立 baseline 并记为一次变化。
/// - 之后只有任一事实不同才重建快照并返回 true；同值重复采样返回 false，
///   不重建快照、不推进修订。
/// - 未知主题 token 被拒：accepted 快照、有效主题与修订都不变。
public class CjguiComposableUiPlatformStateTracker {
    private var acceptedSnapshot: ?CjguiComposableUiPlatformStateSnapshot
    private var acceptedRevision: Int64
    private var rejectionReasonValue: String

    public init() {
        this.acceptedSnapshot = None
        this.acceptedRevision = 0
        this.rejectionReasonValue = ""
    }

    /// 采样一次平台事实。返回值 = 是否发生变化。
    public func observe(
        reduceMotion!: Bool,
        systemColorScheme!: CjguiComposableUiColorScheme,
        themePreference!: CjguiComposableUiThemePreference,
        windowVisible!: Bool,
        windowMinimized!: Bool
    ): Bool {
        if (let Some(accepted) <- acceptedSnapshot) {
            if (accepted.reduceMotion == reduceMotion && CjguiComposableUiPlatformStateResolution.sameColorScheme(
                accepted.systemColorScheme, systemColorScheme) &&
                CjguiComposableUiPlatformStateResolution.sameThemePreference(accepted.themePreference, themePreference) &&
                accepted.windowVisible == windowVisible && accepted.windowMinimized == windowMinimized) {
                return false
            }
        }
        acceptedSnapshot = Some(
            CjguiComposableUiPlatformStateSnapshot(
                reduceMotion,
                systemColorScheme,
                themePreference,
                windowVisible,
                windowMinimized
            )
        )
        acceptedRevision += 1
        return true
    }

    /// 接受一个已经构造好的候选快照；仅当它与 accepted 不同才算变化。
    public func accept(candidate: CjguiComposableUiPlatformStateSnapshot): Bool {
        if (let Some(accepted) <- acceptedSnapshot) {
            if (accepted.equals(candidate)) {
                return false
            }
        }
        acceptedSnapshot = Some(candidate)
        acceptedRevision += 1
        return true
    }

    /// 应用选择的主题策略（token 形式）。合法且与当前不同才算一次变化并返回
    /// true；未知 token 被拒：accepted 与有效主题保持不动，只记录拒绝原因。
    /// 尚未采样过平台状态时同样 fail-closed，不凭 token 造出半个快照。
    public func selectThemePreference(token: String): Bool {
        if (let Some(preference) <- CjguiComposableUiPlatformStateCodec.themePreferenceFromToken(token)) {
            if (let Some(accepted) <- acceptedSnapshot) {
                if (CjguiComposableUiPlatformStateResolution.sameThemePreference(accepted.themePreference, preference)) {
                    return false
                }
                acceptedSnapshot = Some(
                    CjguiComposableUiPlatformStateSnapshot(
                        accepted.reduceMotion,
                        accepted.systemColorScheme,
                        preference,
                        accepted.windowVisible,
                        accepted.windowMinimized
                    )
                )
                acceptedRevision += 1
                return true
            }
            rejectionReasonValue = "platform_state_not_observed"
            return false
        }
        rejectionReasonValue = "unknown_theme_preference"
        return false
    }

    /// 显式拒绝一次候选主题：accepted 快照、有效主题与修订都不变，只记录原因。
    /// 用于应用自己的策略拒绝某个候选，拒绝不产生半更新。
    public func rejectThemeSelection(candidate: CjguiComposableUiThemePreference, reason: String): Bool {
        let _ = candidate
        rejectionReasonValue = reason
        return false
    }

    public func accepted(): ?CjguiComposableUiPlatformStateSnapshot {
        return acceptedSnapshot
    }

    /// accepted 快照的修订号：每次真实变化加一，同值采样不推进。
    public func revision(): Int64 {
        return acceptedRevision
    }

    public func lastRejectionReason(): String {
        return rejectionReasonValue
    }
}

/// 平台事实读取器：把 native bridge 的脱水 C facts 转成快照输入。它是 internal
/// seam，不是公共权限；缓存与“仅变化时更新”由 tracker 负责，这里只做单次读取。
class CjguiComposableUiPlatformFacts {
    /// 复用既有减少动效入口，不重复声明 native 符号。
    static func reduceMotionEnabled(): Bool {
        return CjguiComposableUiReduceMotion.isEnabled()
    }

    static func systemColorScheme(): CjguiComposableUiColorScheme {
        unsafe {
            if (cjgui_macos_effective_dark_mode() != 0) {
                return CjguiComposableUiColorScheme.Dark
            }
        }
        return CjguiComposableUiColorScheme.Light
    }

    /// 窗口号不可用（<= 0）时不能断言“不可见”，报可见以免把正常动效误收敛；
    /// 真实不可用由 bridge 的确定默认值表达，host 只在窗口已启动后采样。
    static func windowVisible(windowNumber: Int64): Bool {
        if (windowNumber <= 0) {
            return true
        }
        unsafe {
            return cjgui_macos_window_visible(windowNumber) != 0
        }
    }

    static func windowMinimized(windowNumber: Int64): Bool {
        if (windowNumber <= 0) {
            return false
        }
        unsafe {
            return cjgui_macos_window_minimized(windowNumber) != 0
        }
    }
}

foreign func cjgui_macos_effective_dark_mode(): Int32

foreign func cjgui_macos_window_visible(windowNumber: Int64): Int32

foreign func cjgui_macos_window_minimized(windowNumber: Int64): Int32
