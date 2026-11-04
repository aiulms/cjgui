// 设置与计数的私有重启缓存。
//
// 只保存已经由 owner 接受（accepted）的业务值：文件是应用私有目录里的
// 普通文本，读取时整份校验，任何一行不符都退回默认值，不做部分恢复。
// 写入先落同目录临时文件再原子替换，失败时旧文件与内存状态都不变。
// 与 rule_set_window_app 的视图偏好文件同一套有界/校验/原子写法。

package cjgui_settings_counter_application

import std.collection.*
import std.fs.*

public class CjguiSettingsCounterStateStore {
    public static let format: String = "CJGUI_SETTINGS_COUNTER_STATE"
    public static let formatVersion: Int64 = 1
    public static let maximumBytes: Int64 = 8192
    private static let maximumTextBytes: Int64 = 256

    public var lastReason: String = "settings_state_not_loaded"

    /// Missing file is a normal first run. Malformed or oversized content
    /// rejects the whole file so callers keep their in-memory defaults.
    public func load(path: String): ?CjguiSettingsCounterSnapshot {
        if (path.size == 0) {
            lastReason = "settings_state_no_path"
            return None
        }
        if (!exists(path)) {
            lastReason = "settings_state_not_found"
            return None
        }
        var payload = ""
        try (file = File(path, OpenMode.Read)) {
            let declared = file.length
            if (declared < 0 || declared > CjguiSettingsCounterStateStore.maximumBytes) {
                lastReason = "settings_state_too_large"
                return None
            }
            let chunk = Array<Byte>(1024, repeat: 0)
            let bytes = ArrayList<Byte>()
            while (true) {
                let count = file.read(chunk)
                if (count <= 0) {
                    break
                }
                if (bytes.size + count > CjguiSettingsCounterStateStore.maximumBytes) {
                    lastReason = "settings_state_too_large"
                    return None
                }
                for (index in 0..count) {
                    bytes.add(chunk[index])
                }
            }
            payload = String.fromUtf8(bytes.toArray())
        } catch (_) {
            lastReason = "settings_state_read_failed"
            return None
        }
        return decode(payload)
    }

    /// A failed save keeps the previous file: the temporary copy is only
    /// renamed over the target after a complete write.
    public func save(path: String, snapshot: CjguiSettingsCounterSnapshot): Bool {
        if (path.size == 0) {
            lastReason = "settings_state_no_path"
            return false
        }
        let payload = encode(snapshot)
        if (payload.size > CjguiSettingsCounterStateStore.maximumBytes) {
            lastReason = "settings_state_too_large"
            return false
        }
        let target = Path(path)
        try {
            let temporaryDirectory = Directory.createTemp(target.parent)
            let temporaryPath = temporaryDirectory.join("cjgui-settings-state")
            try {
                File.writeTo(temporaryPath, payload.toArray())
                rename(temporaryPath, to: target, overwrite: true)
                let _ = removeIfExists(temporaryDirectory, recursive: true)
                lastReason = "settings_state_saved"
                return true
            } catch (_) {
                try {
                    let _ = removeIfExists(temporaryDirectory, recursive: true)
                } catch (_) {}
                lastReason = "settings_state_write_failed"
                return false
            }
        } catch (_) {
            lastReason = "settings_state_temporary_failed"
            return false
        }
    }

    private func encode(snapshot: CjguiSettingsCounterSnapshot): String {
        let builder = StringBuilder()
        builder.append("${CjguiSettingsCounterStateStore.format} ${CjguiSettingsCounterStateStore.formatVersion}\n")
        builder.append("VERSION ${snapshot.version}\n")
        builder.append("COUNT ${snapshot.count}\n")
        builder.append("ENABLED ${if (snapshot.enabled) { 1 } else { 0 }}\n")
        builder.append("NAME ${CjguiSettingsCounterStateStore.encodeHex(snapshot.name)}\n")
        builder.append("ALIAS ${CjguiSettingsCounterStateStore.encodeHex(snapshot.alias)}\n")
        builder.append("SCROLL_NOTE ${CjguiSettingsCounterStateStore.encodeHex(snapshot.scrollNote)}\n")
        builder.append("IMAGE_VERSION ${snapshot.imageVersion}\n")
        builder.append("END\n")
        return builder.toString()
    }

    private func decode(payload: String): ?CjguiSettingsCounterSnapshot {
        let lines = payload.split("\n")
        // 编码以换行结束；split 会多出一个空尾行，不得因此拒绝整份状态。
        var lineCount = lines.size
        if (lineCount == 10 && lines[9].size == 0) {
            lineCount = 9
        }
        if (lineCount != 9 || lines[8] != "END") {
            lastReason = "settings_state_shape_invalid"
            return None
        }
        if (lines[0] != "${CjguiSettingsCounterStateStore.format} ${CjguiSettingsCounterStateStore.formatVersion}") {
            lastReason = "settings_state_format_unsupported"
            return None
        }
        var version: ?Int64 = None
        var count: ?Int64 = None
        var enabled: ?Bool = None
        var name: ?String = None
        var alias: ?String = None
        var scrollNote: ?String = None
        var imageVersion: ?Int64 = None
        for (index in 1..8) {
            let line = lines[index]
            if (let Some(space) <- line.indexOf(" ")) {
                let key = line[0..space]
                let value = line[space + 1..line.size]
                match (key) {
                    case "VERSION" => version = CjguiSettingsCounterStateStore.parseBounded(value, 0, Int64.Max)
                    case "COUNT" => count = CjguiSettingsCounterStateStore.parseBounded(value,
                        CjguiSettingsCounterDomain.counterMin, CjguiSettingsCounterDomain.counterMax)
                    case "ENABLED" =>
                        if (value == "0") {
                            enabled = Some(false)
                        } else if (value == "1") {
                            enabled = Some(true)
                        } else {
                            enabled = None
                        }
                    case "NAME" => name = CjguiSettingsCounterStateStore.decodeHex(value)
                    case "ALIAS" => alias = CjguiSettingsCounterStateStore.decodeHex(value)
                    case "SCROLL_NOTE" => scrollNote = CjguiSettingsCounterStateStore.decodeHex(value)
                    case "IMAGE_VERSION" => imageVersion = CjguiSettingsCounterStateStore.parseBounded(value, 1,
                        Int64.Max)
                    case _ =>
                        lastReason = "settings_state_field_unknown"
                        return None
                }
            } else {
                lastReason = "settings_state_field_invalid"
                return None
            }
        }
        if (let Some(v) <- version) {
            if (let Some(c) <- count) {
                if (let Some(e) <- enabled) {
                    if (let Some(n) <- name) {
                        if (let Some(a) <- alias) {
                            if (let Some(s) <- scrollNote) {
                                if (let Some(i) <- imageVersion) {
                                    if (!CjguiSettingsCounterStateStore.textWithinBounds(n) ||
                                        !CjguiSettingsCounterStateStore.textWithinBounds(a) ||
                                        !CjguiSettingsCounterStateStore.textWithinBounds(s)) {
                                        lastReason = "settings_state_text_invalid"
                                        return None
                                    }
                                    lastReason = "settings_state_loaded"
                                    return Some(CjguiSettingsCounterSnapshot(v, c, e, n, a, s, i))
                                }
                            }
                        }
                    }
                }
            }
        }
        lastReason = "settings_state_value_invalid"
        return None
    }

    private static func textWithinBounds(value: String): Bool {
        let size = value.toArray().size
        return size > 0 && size <= maximumTextBytes
    }

    private static func parseBounded(text: String, minimum: Int64, maximum: Int64): ?Int64 {
        if (text.size == 0 || text.size > 19) { return None }
        var value: Int64 = 0
        for (byte in text.toArray()) {
            if (byte < b'0' || byte > b'9') { return None }
            value = value * 10 + Int64(byte - b'0')
        }
        if (value < minimum || value > maximum) { return None }
        return Some(value)
    }

    private static func encodeHex(value: String): String {
        let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
        let result = StringBuilder()
        for (byte in value) {
            let numeric = Int64(byte)
            result.append(digits[numeric / 16])
            result.append(digits[numeric % 16])
        }
        return result.toString()
    }

    private static func decodeHex(value: String): ?String {
        if (value.size == 0 || value.size % 2 != 0 || value.size > maximumTextBytes * 2) {
            return None
        }
        let source = value.toArray()
        let bytes = ArrayList<Byte>()
        var index: Int64 = 0
        while (index < source.size) {
            if (let Some(high) <- CjguiSettingsCounterStateStore.hexNibble(source[index])) {
                if (let Some(low) <- CjguiSettingsCounterStateStore.hexNibble(source[index + 1])) {
                    bytes.add(UInt8(high * 16 + low))
                    index += 2
                    continue
                }
            }
            return None
        }
        try {
            return Some(String.fromUtf8(bytes.toArray()))
        } catch (_) {
            return None
        }
    }

    private static func hexNibble(value: Byte): ?Int64 {
        if (value >= b'0' && value <= b'9') {
            return Some(Int64(value) - Int64(b'0'))
        }
        if (value >= b'A' && value <= b'F') {
            return Some(Int64(value) - Int64(b'A') + 10)
        }
        if (value >= b'a' && value <= b'f') {
            return Some(Int64(value) - Int64(b'a') + 10)
        }
        return None
    }
}
