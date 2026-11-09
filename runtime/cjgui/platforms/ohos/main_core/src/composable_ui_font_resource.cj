package cjgui

import std.collection.*
import std.convert.*

/// Experimental application-owned font declaration. Generated descriptions may
/// reference its key/version only; they cannot supply a family or file path.
public class CjguiFontResourceSpec {
    public let key: String
    public let version: Int64
    public let name: String
    public let kind: String
    public let source: String
    public let fallback: String
    private init(key: String, version: Int64, name: String, kind: String, source: String, fallback: String) {
        this.key = key
        this.version = version
        this.name = name
        this.kind = kind
        this.source = source
        this.fallback = fallback
    }
    public static func systemFamily(key: String, version: Int64, family: String, name!: String = "",
        fallback!: String = "system"): CjguiFontResourceSpec {
        return CjguiFontResourceSpec(key, version, if (name.isEmpty()) {
            family
        } else {
            name
        }, "system-family", family, fallback)
    }
    public static func file(key: String, version: Int64, path: String, name!: String = "", fallback!: String = "system"): CjguiFontResourceSpec {
        return CjguiFontResourceSpec(key, version, if (name.isEmpty()) {
            key
        } else {
            name
        }, "font-file", path, fallback)
    }
    func valid(): Bool {
        if (key.isEmpty() || key.size > 64 || version < 1 || version > 1000000 || source.isEmpty() || source.size > 4096 ||
            name.isEmpty() || name.size > 256 || (fallback != "system" && fallback != "monospaced" && fallback !=
            "system-italic" && fallback != "monospaced-italic")) {
            return false
        }
        for (byte in key.toArray()) {
            if (!((byte >= 65u8 && byte <= 90u8) || (byte >= 97u8 && byte <= 122u8) || (byte >= 48u8 && byte <= 57u8) ||
                byte == 45u8 || byte == 46u8 || byte == 95u8)) {
                return false
            }
        }
        for (byte in (source + name).toArray()) {
            if (byte == 0u8 || byte == 10u8 || byte == 13u8) {
                return false
            }
        }
        return true
    }
    func identity(): String {
        return "${version}:${kind}:${source}:${fallback}"
    }
}

/// Immutable resolved font facts. `state` is the explicit resolution outcome;
/// a missing/invalid asset uses the declared fallback for ALL text consumers.
/// The style string is a value-only reference, never a platform object/pointer.
public class CjguiFontResourceReference {
    public let key: String
    public let version: Int64
    public let name: String
    public let state: String
    public let resolvedFamily: String
    public let fontFamily: String
    private let code: UInt32
    private var active: Bool = true
    init(spec: CjguiFontResourceSpec, code: UInt32, status: Int32, resolved: String) {
        this.key = spec.key
        this.version = spec.version
        this.name = spec.name
        this.code = code
        this.resolvedFamily = resolved
        // A fallback outcome must expose the DECLARED fallback family. The
        // native registry still assigns a diagnostic code, but that code is
        // not a usable family for any text consumer.
        this.fontFamily = if (status == 0 && code >= 4u32) {
            "cjgui-font:${code}"
        } else {
            spec.fallback
        }
        this.state = match (status) {
            case 0 => "ready"
            case 1 => "fallback_missing_family"
            case 2 => "fallback_missing_file"
            case 3 => "fallback_invalid_font"
            case 4 => "fallback_capacity"
            case -2 => "unsupported_fallback"
            case _ => "fallback_backend_failure"
        }
    }
    public func isRegistered(): Bool {
        return active
    }
    public func isReady(): Bool {
        return active && state == "ready"
    }
    func retire(): Unit {
        if (!active) {
            return
        }
        active = false
        cjguiReleaseFontResource(code)
    }
}

/// One explicit resource owner, normally closed AFTER its application windows.
/// Repeated declarations reuse one resolution. Replacement requires a new
/// version; old native scenes/jobs retain their immutable generation leases.
public class CjguiFontResourceRegistry {
    private let resources = HashMap<String, CjguiFontResourceReference>()
    private let identities = HashMap<String, String>()
    private let highestVersions = HashMap<String, Int64>()
    private var closed: Bool = false
    public init() {}
    public func register(spec: CjguiFontResourceSpec): CjguiFontResourceReference {
        if (closed || !spec.valid()) {
            throw Exception("font_resource_declaration_invalid:${spec.key}")
        }
        if (let Some(existing) <- resources.get(spec.key)) {
            if (identities[spec.key] == spec.identity()) {
                return existing
            }
            throw Exception("font_resource_identity_conflict:${spec.key}")
        }
        if (let Some(previous) <- highestVersions.get(spec.key)) {
            if (spec.version <= previous) {
                throw Exception("font_resource_new_version_required:${spec.key}")
            }
        } else if (highestVersions.size >= 256) {
            throw Exception("font_resource_identity_capacity")
        }
        let (status, code, resolved) = cjguiRegisterFontResource(spec)
        let reference = CjguiFontResourceReference(spec, code, status, resolved)
        resources[spec.key] = reference
        identities[spec.key] = spec.identity()
        highestVersions[spec.key] = spec.version
        return reference
    }
    public func replace(spec: CjguiFontResourceSpec): CjguiFontResourceReference {
        if (let Some(existing) <- resources.get(spec.key)) {
            if (spec.version <= existing.version) {
                throw Exception("font_resource_new_version_required:${spec.key}")
            }
            if (!spec.valid() || closed) {
                throw Exception("font_resource_declaration_invalid:${spec.key}")
            }
            // Resolve the replacement before retiring the old owner reference.
            let (status, code, resolved) = cjguiRegisterFontResource(spec)
            let reference = CjguiFontResourceReference(spec, code, status, resolved)
            resources[spec.key] = reference
            identities[spec.key] = spec.identity()
            highestVersions[spec.key] = spec.version
            existing.retire()
            return reference
        }
        return register(spec)
    }
    public func withdraw(key: String): Bool {
        if (let Some(reference) <- resources.get(key)) {
            reference.retire();
            let _ = resources.remove(key);
            let _ = identities.remove(key)
            return true
        }
        return false
    }
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        for ((_, reference) in resources) {
            reference.retire()
        }
        resources.clear();
        identities.clear();
        highestVersions.clear()
    }
}

func cjguiFontResourceCode(family: String): UInt32 {
    if (!family.startsWith("cjgui-font:")) {
        return 0u32
    }
    let parts = family.split(":")
    if (parts.size != 2) {
        return 0u32
    }
    if (let Some(value) <- UInt64.tryParse(parts[1])) {
        if (value >= 4u64 && value <= 4294967295u64) {
            return UInt32(value)
        }
    }
    return 0u32
}

func cjguiNormalizeFontFamily(family: String): String {
    if (family == "monospaced" || family == "system-italic" || family == "monospaced-italic" ||
        cjguiFontResourceCode(family) >= 4u32) {
        return family
    }
    return "system"
}

@When[os == "macOS" || os == "Linux"]
foreign {
    func cjgui_internal_renderer_font_resource_register(kind: UInt32, source: CString, fallback: UInt32,
        code: CPointer<UInt32>): Int32

    func cjgui_internal_renderer_font_resource_release(code: UInt32): Int32

    func cjgui_internal_renderer_font_resource_copy_family(code: UInt32, buffer: CPointer<UInt8>, capacity: UInt64): Int64

    func cjgui_internal_renderer_font_resource_stats(values: CPointer<UInt64>): Int32

    func cjgui_internal_renderer_font_resource_version(): UInt32
}

/// Zero means unsupported; references still report their explicit fallback.
@When[os == "macOS" || os == "Linux"]
public func cjguiFontResourceSupportVersion(): UInt32 {
    return unsafe { cjgui_internal_renderer_font_resource_version() }
}

@When[os != "macOS" && os != "Linux"]
public func cjguiFontResourceSupportVersion(): UInt32 {
    return 0u32
}

@When[os == "macOS" || os == "Linux"]
func cjguiRegisterFontResource(spec: CjguiFontResourceSpec): (Int32, UInt32, String) {
    let text = unsafe { LibC.mallocCString(spec.source) }
    var code: UInt32 = 0u32
    var status: Int32 = -1
    try (resource = text.asResource()) {
        status = unsafe { cjgui_internal_renderer_font_resource_register(if (spec.kind == "font-file") {
            2u32
        } else {
            1u32
        }, resource.value, composableFontFamilyCode(spec.fallback), inout code) }
    }
    let bytes = Array<UInt8>(4096, repeat: 0u8)
    let count = unsafe {
        let raw = acquireArrayRawData(bytes)
        let result = cjgui_internal_renderer_font_resource_copy_family(code, raw.pointer, UInt64(bytes.size))
        releaseArrayRawData(raw);
        result
    }
    return (status, code, if (count >= 0 && count <= bytes.size) {
            String.fromUtf8(bytes.slice(0, count))
        } else {
            spec.fallback
        })
}

@When[os != "macOS" && os != "Linux"]
func cjguiRegisterFontResource(spec: CjguiFontResourceSpec): (Int32, UInt32, String) {
    return (-2, 0u32, spec.fallback)
}

@When[os == "macOS" || os == "Linux"]
func cjguiReleaseFontResource(code: UInt32): Unit {
    if (code >= 4u32) {
        let _ = unsafe { cjgui_internal_renderer_font_resource_release(code) }
    }
}

@When[os != "macOS" && os != "Linux"]
func cjguiReleaseFontResource(code: UInt32): Unit {}

/// Experimental scalar diagnostic: active registrations, leased generations,
/// registered file bytes, font snapshots built, successful registrations.
/// It is not a process/RSS or end-to-end latency measurement.
@When[os == "macOS" || os == "Linux"]
public func cjguiFontResourceDiagnostics(): Array<UInt64> {
    let values = Array<UInt64>(5, repeat: 0u64)
    unsafe {
        let raw = acquireArrayRawData(values)
        let _ = cjgui_internal_renderer_font_resource_stats(raw.pointer)
        releaseArrayRawData(raw)
    }
    return values
}

@When[os != "macOS" && os != "Linux"]
public func cjguiFontResourceDiagnostics(): Array<UInt64> {
    return [0u64, 0u64, 0u64, 0u64, 0u64]
}
