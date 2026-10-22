"""Typed spans use actual UTF-8 bytes and registered logical font references."""
import unittest
import cjgui_generated_client as generated


class StyledTextRuns(unittest.TestCase):
    def test_unicode_byte_ranges_and_two_fonts_roundtrip(self):
        text = "A中文 é 👩🏽‍💻 end"
        end = len("A中文".encode())
        run = generated.GeneratedTextStyleRun(1, end, font_size=36,
            font_resource="preview-serif", font_version=2, color="#E06030")
        prop = generated.styled_text_runs_property(text, [run])
        self.assertEqual(prop.name, "textRuns")
        self.assertEqual(generated.parse_text_style_runs(text, prop.value), (run,))

    def test_base_font_and_color_only_are_explicit(self):
        run = generated.GeneratedTextStyleRun(0, 3, color="#8080FFCC")
        prop = generated.styled_text_runs_property("abc", [run])
        self.assertEqual(generated.parse_text_style_runs("abc", prop.value), (run,))

    def test_split_utf8_scalar_and_invalid_fonts_refused(self):
        for run in [generated.GeneratedTextStyleRun(1, 3),
                    generated.GeneratedTextStyleRun(0, 3, font_resource="/tmp/font.ttf", font_version=1),
                    generated.GeneratedTextStyleRun(0, 3, font_resource="body", font_version=0),
                    generated.GeneratedTextStyleRun(0, 3, font_size=float("nan"))]:
            with self.subTest(run=run), self.assertRaises(generated.GeneratedUiError):
                generated.styled_text_runs_property("中", [run])

    def test_count_and_wire_budget_are_bounded(self):
        run = generated.GeneratedTextStyleRun(0, 1)
        with self.assertRaises(generated.GeneratedUiError):
            generated.styled_text_runs_property("a", [run] * 65)
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_text_style_runs("a", "x" * 16385)

    def test_unknown_native_family_column_is_not_accepted(self):
        with self.assertRaises(generated.GeneratedUiError):
            generated.parse_text_style_runs("abc", "0:3:14:0:4:0:#FFFFFF")


if __name__ == "__main__":
    unittest.main()
