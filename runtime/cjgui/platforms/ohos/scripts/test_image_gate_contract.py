"""The image completion gate must reach the owner, then the native seam."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[5]
TRANSPORT = (ROOT / "runtime/cjgui/platforms/ohos/transport/verify"
             / "ohos_transport_verify.cj")
APP = ROOT / "labs/ohos_cjgui_app/entry/src/main/cangjie/ohos_app.cj"


class ImageGateContractTests(unittest.TestCase):
    def test_settings_host_does_not_link_sdk_only_hilog_kit(self) -> None:
        app = APP.read_text(encoding="utf-8")
        self.assertNotIn("kit.PerformanceAnalysisKit", app)
        self.assertNotIn("Hilog.", app)
        self.assertNotIn("println(", app)
        self.assertIn('cjguiOhosInfo("CjguiApp", "host started; pumping turns")', app)

    def test_parameterized_gate_is_published_and_executed(self) -> None:
        transport = TRANSPORT.read_text(encoding="utf-8")
        app = APP.read_text(encoding="utf-8")
        image_route = re.search(r'case "GATE_IMAGE_HOLD".*?=>', transport, re.S)
        self.assertIsNotNone(image_route)
        for op in ("GATE_IMAGE_HOLD", "GATE_IMAGE_RELEASE", "GATE_IMAGE_FORGET",
                   "GATE_IMAGE_STATS", "GATE_IMAGE_STATS_EXT"):
            self.assertIn(f'"{op}"', image_route.group())
            self.assertIn(f'"{op}', app)
        self.assertIn("cjgui_ohos_test_image_hold_completion", app)
        self.assertIn("cjgui_ohos_test_image_forget", app)
        self.assertIn("cjgui_ohos_test_image_stats", app)
        self.assertIn("cjgui_ohos_test_image_stats_ext", app)


if __name__ == "__main__":
    unittest.main()
