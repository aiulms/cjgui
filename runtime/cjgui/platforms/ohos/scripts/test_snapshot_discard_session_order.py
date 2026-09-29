#!/usr/bin/env python3
"""Source contract for retryable HarmonyOS window teardown (no cjpm target)."""
from pathlib import Path
import unittest

SOURCE = (Path(__file__).resolve().parents[1] / "snapshot" / "src" /
          "composable_ui_window.cj")


def discard_body() -> str:
    source = SOURCE.read_text(encoding="utf-8")
    start = source.index("private func discardSession(reason: String) {")
    opening = source.index("{", start)
    depth = 0
    for index in range(opening, len(source)):
        depth += (source[index] == "{") - (source[index] == "}")
        if depth == 0:
            return source[opening:index + 1]
    raise ValueError("discardSession body unterminated")


class RetryableDiscardOrderTest(unittest.TestCase):
    def test_unacknowledged_native_ticket_retains_all_window_owned_resources(self):
        body = discard_body()
        destroy = body.index("internalRendererDestroy(sessionToken)")
        failure_return = body.index("discardRetryReason = reason", destroy)
        failure_return = body.index("return", failure_return)
        for release in ("discardStagedSceneViewports()", "discardStagedSceneSplitTracks()",
                        "releaseOwnedViewStateOwnership()", "value.disposeSceneRefreshResources()"):
            with self.subTest(release=release):
                self.assertEqual(body.count(release), 1)
                self.assertGreater(body.index(release), failure_return,
                    "a refused destroy leaves session live, so resources must remain owned")
        self.assertIn("lastNativeStatus = status", body[destroy:failure_return])
        self.assertIn("discardRetryReason = reason", body[destroy:failure_return])
        self.assertGreater(body.index("sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN"),
                           failure_return)
        self.assertGreater(body.index("isWindowOpen = false"), failure_return)
        self.assertGreater(body.index("acceptedBindingKeys.clear()"), failure_return)

    def test_successful_destroy_releases_resources_once_before_state_reset(self):
        body = discard_body()
        destroy = body.index("internalRendererDestroy(sessionToken)")
        release = body.index("discardStagedSceneViewports()")
        reset = body.index("sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN")
        self.assertLess(destroy, release)
        self.assertLess(release, reset)
        self.assertLess(body.index("releaseOwnedViewStateOwnership()"), reset)
        self.assertLess(body.index("value.disposeSceneRefreshResources()"), reset)


if __name__ == "__main__":
    unittest.main()
