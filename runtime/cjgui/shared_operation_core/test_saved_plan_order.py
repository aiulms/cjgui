"""Regression: saved-plan JSON persistence preserves authored property order.

The generated-structure grammar is order-sensitive for a node's PROPERTY
lines, and the client re-encodes a loaded plan and checks its digest against
the stored preview.  A sort_keys=True writer silently reorders an inserted
node's properties and turns a valid saved plan into `saved_preview_mismatch`.
This test covers the persistence boundary deterministically (the end-to-end
host CLI reload is covered separately).
"""
import json
import tempfile
import unittest
from pathlib import Path

from cjgui_generated_edit import write_json_file


class SavedPlanOrderTest(unittest.TestCase):
    def test_write_json_file_keeps_authored_property_order(self) -> None:
        value = {
            "format": "cjgui.generated-edit.plan.v1",
            "format_version": 1,
            "plan": {
                "base_version": 7,
                "operations": [{
                    "op": "insert",
                    "key": "field-title",
                    "node": {
                        "kind": "textInput",
                        "properties": {
                            "label": "标题",
                            "fixedHeight": 32,
                            "growX": 1,
                        },
                    },
                }],
            },
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "plan.json"
            write_json_file(path, value)
            loaded = json.loads(path.read_text(encoding="utf-8"))
        properties = loaded["plan"]["operations"][0]["node"]["properties"]
        self.assertEqual(list(properties), ["label", "fixedHeight", "growX"])

    def test_write_json_file_can_still_sort_for_display(self) -> None:
        value = {"b": 1, "a": 2}
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "display.json"
            write_json_file(path, value, sort_keys=True)
            text = path.read_text(encoding="utf-8")
        self.assertLess(text.index('"a"'), text.index('"b"'))


if __name__ == "__main__":
    unittest.main()
