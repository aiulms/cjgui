package cjgui

/// An application installs this value in its ordinary named styles and
/// handwritten controls, then invalidates its normal scene. The window only
/// reports it as adopted after that scene is accepted.
public interface CjguiComposableUiPlatformAccentConsumer {
    func applyPlatformAccentColor(color: CjguiComposableUiColor, source: String): Bool
}

/// One window's read-only facts. `observed` describes AppKit, `requested`
/// describes policy, and `adopted` describes the last accepted scene.
public class CjguiComposableUiPlatformAccentStatus {
    public let capability: String
    public let observedStatus: String
    public let observedToken: String
    public let observedRevision: Int64
    public let preference: String
    public let requestedToken: String
    public let adoptedToken: String
    public let adoptedSource: String
    public let adoptedSceneVersion: Int64
    public let deliveryFailure: String

    public init(capability: String, observedStatus: String, observedToken: String,
        observedRevision: Int64, preference: String, requestedToken: String,
        adoptedToken: String, adoptedSource: String, adoptedSceneVersion: Int64,
        deliveryFailure!: String = "") {
        this.capability = capability
        this.observedStatus = observedStatus
        this.observedToken = observedToken
        this.observedRevision = observedRevision
        this.preference = preference
        this.requestedToken = requestedToken
        this.adoptedToken = adoptedToken
        this.adoptedSource = adoptedSource
        this.adoptedSceneVersion = adoptedSceneVersion
        this.deliveryFailure = deliveryFailure
    }

    public func describe(): String {
        return "ACCENT capability=${capability} support=macos_appkit,ohos_unverified " +
            "observed=${observedStatus} observed_color=${observedToken} " +
            "observed_revision=${observedRevision} preference=${preference} requested=${requestedToken} " +
            "adopted=${adoptedToken} adopted_source=${adoptedSource} scene=${adoptedSceneVersion} " +
            "delivery_failure=${if (deliveryFailure.size > 0) { deliveryFailure } else { "none" }}"
    }
}

/// Stability: experimental. A copied, quantized sRGB platform fact. The
/// native bridge returns one packed sample so channels cannot come from
/// different AppKit appearances. The tracker owns the last successful value;
/// a failed read changes availability but never invents a fallback color.
public class CjguiComposableUiPlatformAccentTracker {
    private var lastColor: ?CjguiComposableUiColor = None
    private var lastColorToken: String = ""
    private var readStatusValue: String = "unavailable"
    private var valueRevisionValue: Int64 = 0
    private var observationRevisionValue: Int64 = 0

    public init() {}

    /// The testable source seam. Valid samples have bit 24 set and carry
    /// RRGGBB in the low bits. Everything else is one unavailable sample.
    public func observePacked(packed: Int64): Bool {
        if (packed < 16777216 || packed >= 33554432) {
            if (readStatusValue == "unavailable") { return false }
            readStatusValue = "unavailable"
            observationRevisionValue += 1
            return true
        }
        let rgb = packed - 16777216
        let color = CjguiComposableUiColor(Float64((rgb / 65536) % 256) / 255.0,
            Float64((rgb / 256) % 256) / 255.0, Float64(rgb % 256) / 255.0, 1.0)
        let token = cjguiComposableUiColorToken(color)
        let changedColor = token != lastColorToken
        let changedStatus = readStatusValue != "available"
        if (!changedColor && !changedStatus) { return false }
        lastColor = Some(color)
        lastColorToken = token
        readStatusValue = "available"
        if (changedColor) { valueRevisionValue += 1 }
        observationRevisionValue += 1
        return true
    }

    public func observeSystem(): Bool {
        unsafe { return observePacked(cjgui_macos_control_accent_srgb8()) }
    }

    /// None before the first successful conversion; last-good on later
    /// failure. Callers must also read status before labelling it as fresh.
    public func color(): ?CjguiComposableUiColor { return lastColor }
    public func colorToken(): String { return lastColorToken }
    public func readStatus(): String { return readStatusValue }
    public func valueRevision(): Int64 { return valueRevisionValue }
    public func observationRevision(): Int64 { return observationRevisionValue }
}

/// Stability: experimental. Application policy is independent of its theme
/// preference. A fixed explicit color is validated and then takes precedence
/// over a successful or retained system sample. An unknown token is refused.
public class CjguiComposableUiAccentPreference {
    public let source: String
    public let fixedColor: ?CjguiComposableUiColor

    private init(source: String, fixedColor: ?CjguiComposableUiColor) {
        this.source = source
        this.fixedColor = fixedColor
    }

    public static func systemFollow(): CjguiComposableUiAccentPreference {
        return CjguiComposableUiAccentPreference("system", None)
    }

    public static func fromToken(token: String): ?CjguiComposableUiAccentPreference {
        if (token == "system") { return Some(CjguiComposableUiAccentPreference.systemFollow()) }
        if (let Some(color) <- cjguiComposableUiParseColorToken(token)) {
            return Some(CjguiComposableUiAccentPreference("fixed", Some(color)))
        }
        return None
    }

    public func effectiveColor(fact: CjguiComposableUiPlatformAccentTracker): ?CjguiComposableUiColor {
        if (let Some(color) <- fixedColor) { return Some(color) }
        return fact.color()
    }

    public func effectiveSource(fact: CjguiComposableUiPlatformAccentTracker): String {
        if (source == "fixed") { return "fixed" }
        if (fact.color().isNone()) { return "unavailable" }
        return if (fact.readStatus() == "available") { "system" } else { "retained_system" }
    }
}

foreign func cjgui_macos_control_accent_srgb8(): Int64
