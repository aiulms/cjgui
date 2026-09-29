"""Public-discovery-only prompt inputs for a real external image candidate."""

import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prepare_model_image_prompt as prompt  # noqa: E402


class ModelImagePromptTests(unittest.TestCase):
    def test_uses_current_public_version_and_rejects_unregistered_version(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            discovery = {"capabilities": {
                "image_resources": [{"key": "settings-beacon", "content_type": "PNG",
                                     "version": 2, "name": "设置标志图"}],
                "components": [{"kind": "image", "properties": [
                    {"name": name} for name in
                    ("resource", "resourceVersion", "contentMode", "fixedWidth", "fixedHeight")]}],
                "fields": [{"field_id": "name"}, {"field_id": "enabled"}],
                "actions": [{"name": "INCREMENT"}]},
                "accepted_structure": {"version": 3}}
            (root / "model_discovery.json").write_text(json.dumps(discovery), encoding="utf-8")
            exchange = {"command": "GET_CONTEXT 0", "response_kind": "SNAPSHOT",
                        "raw_response": "PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\n"
                        "FIELD 9700 imageVersion INTEGER 2\nEND"}
            (root / "exchanges.jsonl").write_text(json.dumps(exchange) + "\n", encoding="utf-8")
            message, version = prompt.prepare_prompt("settings", root)
            self.assertEqual(version, 2)
            self.assertIn("settings-beacon", message)
            self.assertIn("resourceVersion 2", message)
            self.assertNotIn("/data/storage", message)
            exchange["raw_response"] = exchange["raw_response"].replace("INTEGER 2", "INTEGER 1")
            (root / "exchanges.jsonl").write_text(json.dumps(exchange) + "\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                prompt.prepare_prompt("settings", root)


if __name__ == "__main__":
    unittest.main()
