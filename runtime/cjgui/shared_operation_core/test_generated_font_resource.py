"""Typed discovery uses public font identity/outcome; paths remain application-only."""
import unittest
import client
import cjgui_generated_client as generated


def capabilities(*lines):
    payload = "GENERATED_UI 1\nBOUNDS 12 64 32 256\n" + "\n".join(lines) + "\nEND"
    return generated.parse_generated_capabilities(client.parse_response(
        "PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND GENERATED_UI_CAPABILITIES\n"
        f"PAYLOAD_LENGTH {len(payload.encode())}\n{payload}\n"))


class FontResourceDiscovery(unittest.TestCase):
    def test_ready_and_fallback_keep_distinct_facts(self):
        result = capabilities("FONT_RESOURCE body 1 ready Georgia|正文字体",
                              "FONT_RESOURCE absent 2 fallback_missing_file .AppleSystemUIFont|缺失的字体")
        self.assertEqual(result.font_resource("body", 1).resolved_family, "Georgia")
        self.assertEqual(result.font_resource("absent", 2).state, "fallback_missing_file")
        self.assertIsNone(result.font_resource("body", 2))

    def test_withdrawn_and_unsupported_are_explicit(self):
        result = capabilities("FONT_RESOURCE old 1 withdrawn Lilex|旧代",
                              "FONT_RESOURCE other 1 unsupported_fallback system|其他平台")
        self.assertEqual([font.state for font in result.font_resources], ["withdrawn", "unsupported_fallback"])

    def test_unicode_and_delimiters_use_existing_utf8_hex_transport(self):
        family, name = "甲|乙 👩🏽‍💻", "字体|用途\u2028详情"
        result = capabilities(f"FONT_RESOURCE custom 1 ready u8:{family.encode().hex()}|u8:{name.encode().hex()}")
        self.assertEqual((result.font_resources[0].resolved_family, result.font_resources[0].name), (family, name))

    def test_malformed_known_resource_does_not_silently_disappear(self):
        for line in ["FONT_RESOURCE body nope ready Georgia|正文", "FONT_RESOURCE body 1 ready",
                     "FONT_RESOURCE body 1 invented Georgia|正文"]:
            with self.subTest(line=line), self.assertRaises(generated.GeneratedUiError):
                capabilities(line)


if __name__ == "__main__":
    unittest.main()
