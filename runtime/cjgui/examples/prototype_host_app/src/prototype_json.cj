package cjgui_prototype_host

import std.collection.*
import std.convert.*
import std.fs.*
import std.unicode.*

/// 一个受约束的本地 JSON 值。原型项目声明是**数据**，不是脚本：这里只解析有限结构
/// （对象/数组/字符串/数字/布尔/null），不执行任何代码。
class PrototypeJson {
    static let KIND_NULL: Int64 = 0
    static let KIND_BOOLEAN: Int64 = 1
    static let KIND_NUMBER: Int64 = 2
    static let KIND_STRING: Int64 = 3
    static let KIND_ARRAY: Int64 = 4
    static let KIND_OBJECT: Int64 = 5

    let kind: Int64
    let booleanValue: Bool
    let numberText: String
    let text: String
    let items: ArrayList<PrototypeJson>
    let entries: ArrayList<(String, PrototypeJson)>

    init(kind: Int64, booleanValue!: Bool = false, numberText!: String = "", text!: String = "",
        items!: ArrayList<PrototypeJson> = ArrayList<PrototypeJson>(),
        entries!: ArrayList<(String, PrototypeJson)> = ArrayList<(String, PrototypeJson)>()) {
        this.kind = kind
        this.booleanValue = booleanValue
        this.numberText = numberText
        this.text = text
        this.items = items
        this.entries = entries
    }

    static func nullValue(): PrototypeJson {
        return PrototypeJson(KIND_NULL)
    }

    static func stringValue(value: String): PrototypeJson {
        return PrototypeJson(KIND_STRING, text: value)
    }

    static func booleanValueOf(value: Bool): PrototypeJson {
        return PrototypeJson(KIND_BOOLEAN, booleanValue: value)
    }

    static func arrayValue(values: ArrayList<PrototypeJson>): PrototypeJson {
        return PrototypeJson(KIND_ARRAY, items: values)
    }

    static func objectValue(values: ArrayList<(String, PrototypeJson)>): PrototypeJson {
        return PrototypeJson(KIND_OBJECT, entries: values)
    }

    func isNull(): Bool {
        return kind == KIND_NULL
    }

    func field(name: String): ?PrototypeJson {
        if (kind != KIND_OBJECT) {
            return None
        }
        for (entry in entries) {
            if (entry[0] == name) {
                return Some(entry[1])
            }
        }
        return None
    }

    func at(index: Int64): ?PrototypeJson {
        if (kind != KIND_ARRAY || index < 0 || index >= items.size) {
            return None
        }
        return Some(items[index])
    }

    func asString(): ?String {
        if (kind == KIND_STRING) {
            return Some(text)
        }
        return None
    }

    func asStringOr(alternate: String): String {
        if (let Some(value) <- asString()) {
            return value
        }
        return alternate
    }

    func asInteger(): ?Int64 {
        if (kind == KIND_NUMBER || kind == KIND_STRING) {
            try {
                return Some(Int64.parse(numberText.trim()))
            } catch (_: Exception) {
                return None
            }
        }
        return None
    }

    func asIntegerOr(alternate: Int64): Int64 {
        if (let Some(value) <- asInteger()) {
            return value
        }
        return alternate
    }

    func asBool(): ?Bool {
        if (kind == KIND_BOOLEAN) {
            return Some(booleanValue)
        }
        return None
    }

    func asBoolOr(alternate: Bool): Bool {
        if (let Some(value) <- asBool()) {
            return value
        }
        return alternate
    }

    func stringArray(): ArrayList<String> {
        let result = ArrayList<String>()
        if (kind != KIND_ARRAY) {
            return result
        }
        for (item in items) {
            if (let Some(value) <- item.asString()) {
                result.add(value)
            }
        }
        return result
    }
}

/// 递归下降 JSON 解析器。边界：4 MiB 输入、深度 64。字符串支持 `\" \\ \/ \b \f \n \r \t`
/// 转义；`\uXXXX` 以具名错误拒绝（声明文件直接写 UTF-8 中文字面量即可）。
/// 失败以具名异常拒绝，调用方保留旧项目而不是采用半份声明。
class PrototypeJsonParser {
    private let source: String
    private let bytes: Array<Byte>
    private var cursor: Int64 = 0

    private init(source: String) {
        this.source = source
        this.bytes = source.toArray()
    }

    static func parse(text: String): PrototypeJson {
        if (text.toArray().size > 4 * 1024 * 1024) {
            throw Exception("prototype_declaration_too_large")
        }
        let parser = PrototypeJsonParser(text)
        let value = parser.parseValue(0)
        parser.skipWhitespace()
        if (parser.cursor != parser.bytes.size) {
            throw Exception("prototype_declaration_trailing_content")
        }
        return value
    }

    private func skipWhitespace(): Unit {
        while (cursor < bytes.size) {
            let byte = bytes[cursor]
            if (byte == 0x20u8 || byte == 0x09u8 || byte == 0x0Au8 || byte == 0x0Du8) {
                cursor += 1
            } else {
                return
            }
        }
    }

    private func expect(byte: UInt8, reason: String): Unit {
        if (cursor >= bytes.size || bytes[cursor] != byte) {
            throw Exception("prototype_declaration_${reason}")
        }
        cursor += 1
    }

    private func parseValue(depth: Int64): PrototypeJson {
        if (depth > 64) {
            throw Exception("prototype_declaration_nested_too_deep")
        }
        skipWhitespace()
        if (cursor >= bytes.size) {
            throw Exception("prototype_declaration_unexpected_end")
        }
        let byte = bytes[cursor]
        if (byte == 0x7Bu8) {
            return parseObject(depth)
        }
        if (byte == 0x5Bu8) {
            return parseArray(depth)
        }
        if (byte == 0x22u8) {
            return PrototypeJson.stringValue(parseString())
        }
        if (byte == 0x74u8) {
            return parseLiteral("true", PrototypeJson.booleanValueOf(true))
        }
        if (byte == 0x66u8) {
            return parseLiteral("false", PrototypeJson.booleanValueOf(false))
        }
        if (byte == 0x6Eu8) {
            return parseLiteral("null", PrototypeJson.nullValue())
        }
        return parseNumber()
    }

    private func parseLiteral(literal: String, value: PrototypeJson): PrototypeJson {
        let expected = literal.toArray()
        for (index in 0..expected.size) {
            if (cursor + index >= bytes.size || bytes[cursor + index] != expected[index]) {
                throw Exception("prototype_declaration_invalid_literal")
            }
        }
        cursor += expected.size
        return value
    }

    private func parseNumber(): PrototypeJson {
        let start = cursor
        while (cursor < bytes.size) {
            let byte = bytes[cursor]
            if ((byte >= 0x30u8 && byte <= 0x39u8) || byte == 0x2Du8 || byte == 0x2Eu8 ||
                byte == 0x65u8 || byte == 0x45u8 || byte == 0x2Bu8) {
                cursor += 1
            } else {
                break
            }
        }
        if (cursor == start) {
            throw Exception("prototype_declaration_invalid_number")
        }
        return PrototypeJson(PrototypeJson.KIND_NUMBER, numberText: source[start..cursor])
    }

    private func parseObject(depth: Int64): PrototypeJson {
        expect(0x7Bu8, "object_open")
        let entries = ArrayList<(String, PrototypeJson)>()
        skipWhitespace()
        if (cursor < bytes.size && bytes[cursor] == 0x7Du8) {
            cursor += 1
            return PrototypeJson.objectValue(entries)
        }
        while (true) {
            skipWhitespace()
            let name = parseString()
            skipWhitespace()
            expect(0x3Au8, "object_colon")
            let value = parseValue(depth + 1)
            entries.add((name, value))
            skipWhitespace()
            if (cursor < bytes.size && bytes[cursor] == 0x2Cu8) {
                cursor += 1
                continue
            }
            expect(0x7Du8, "object_close")
            break
        }
        return PrototypeJson.objectValue(entries)
    }

    private func parseArray(depth: Int64): PrototypeJson {
        expect(0x5Bu8, "array_open")
        let items = ArrayList<PrototypeJson>()
        skipWhitespace()
        if (cursor < bytes.size && bytes[cursor] == 0x5Du8) {
            cursor += 1
            return PrototypeJson.arrayValue(items)
        }
        while (true) {
            items.add(parseValue(depth + 1))
            skipWhitespace()
            if (cursor < bytes.size && bytes[cursor] == 0x2Cu8) {
                cursor += 1
                continue
            }
            expect(0x5Du8, "array_close")
            break
        }
        return PrototypeJson.arrayValue(items)
    }

    private func parseString(): String {
        expect(0x22u8, "string_open")
        let builder = StringBuilder()
        var plainStart = cursor
        while (cursor < bytes.size) {
            let byte = bytes[cursor]
            if (byte == 0x22u8) {
                if (cursor > plainStart) {
                    builder.append(source[plainStart..cursor])
                }
                cursor += 1
                return builder.toString()
            }
            if (byte == 0x5Cu8) {
                if (cursor > plainStart) {
                    builder.append(source[plainStart..cursor])
                }
                cursor += 1
                if (cursor >= bytes.size) {
                    throw Exception("prototype_declaration_string_escape")
                }
                let escaped = bytes[cursor]
                cursor += 1
                if (escaped == 0x22u8) {
                    builder.append("\"")
                } else if (escaped == 0x5Cu8) {
                    builder.append("\\")
                } else if (escaped == 0x2Fu8) {
                    builder.append("/")
                } else if (escaped == 0x62u8) {
                    builder.append("\b")
                } else if (escaped == 0x66u8) {
                    builder.append("\f")
                } else if (escaped == 0x6Eu8) {
                    builder.append("\n")
                } else if (escaped == 0x72u8) {
                    builder.append("\r")
                } else if (escaped == 0x74u8) {
                    builder.append("\t")
                } else if (escaped == 0x75u8) {
                    // 不实现 \uXXXX：声明文件直接写 UTF-8 字面量，避免第二套编码路径。
                    throw Exception("prototype_declaration_unicode_escape_unsupported")
                } else {
                    throw Exception("prototype_declaration_string_escape")
                }
                plainStart = cursor
                continue
            }
            cursor += 1
        }
        throw Exception("prototype_declaration_string_unterminated")
    }
}

func prototypeReadFile(path: String, maximumBytes: Int64, reason: String): String {
    if (!exists(Path(path))) {
        throw Exception("${reason}:missing")
    }
    let bytes = File.readFrom(Path(path))
    if (bytes.size > maximumBytes) {
        throw Exception("${reason}:too_large")
    }
    return String.fromUtf8(bytes)
}
