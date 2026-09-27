#!/usr/bin/env python3
"""Discriminating scalar scenarios for P4 effect-group pixels."""

from __future__ import annotations

import unittest

from p4_pixel_oracle import TRANSPARENT, isolated_group, over


def assert_color_close(test: unittest.TestCase, actual, expected, places: int = 12) -> None:
    test.assertEqual(len(actual), 4)
    for channel, (got, want) in enumerate(zip(actual, expected)):
        test.assertAlmostEqual(want, got, places=places, msg=f"RGBA channel {channel}")


class P4PixelOracleTest(unittest.TestCase):
    def test_group_opacity_is_applied_after_overlapping_children_are_flattened(self) -> None:
        red = (1.0, 0.0, 0.0, 1.0)
        blue = (0.0, 0.0, 1.0, 1.0)
        white = (1.0, 1.0, 1.0, 1.0)

        correct = isolated_group((red, blue), white, opacity=0.5)
        per_node_opacity_regression = over(
            (0.0, 0.0, 1.0, 0.5),
            over((1.0, 0.0, 0.0, 0.5), white),
        )

        assert_color_close(self, correct, (0.5, 0.5, 1.0, 1.0))
        self.assertNotEqual(correct, per_node_opacity_regression)
        assert_color_close(self, per_node_opacity_regression, (0.5, 0.25, 0.75, 1.0))

    def test_nested_group_opacity_is_applied_once_at_each_boundary(self) -> None:
        red = (1.0, 0.0, 0.0, 1.0)
        blue = (0.0, 0.0, 1.0, 1.0)
        white = (1.0, 1.0, 1.0, 1.0)
        inner = isolated_group((red, blue), TRANSPARENT, opacity=0.5)

        nested = isolated_group((inner,), white, opacity=0.5)

        assert_color_close(self, nested, (0.75, 0.75, 1.0, 1.0))

    def test_half_alpha_normal_and_multiply_match_scalar_formula(self) -> None:
        source = (0.8, 0.2, 0.6, 0.4)
        backdrop = (0.2, 0.7, 0.4, 0.5)

        normal = over(source, backdrop, "normal")
        multiply = over(source, backdrop, "multiply")
        swapped = over(backdrop, source, "multiply")
        normal_swapped = over(backdrop, source, "normal")

        assert_color_close(self, normal, (0.5428571428571428, 0.41428571428571426,
                                           0.5142857142857142, 0.7))
        assert_color_close(self, multiply, (0.36, 0.3971428571428572,
                                             0.4114285714285714, 0.7))
        # The two-layer multiply blend itself is symmetric; painter order
        # inside an isolated group still matters because its children use
        # source-over before the group is blended with the parent.
        assert_color_close(self, swapped, multiply)
        self.assertNotEqual(normal, normal_swapped)

    def test_reversing_translucent_group_children_changes_multiply_result(self) -> None:
        first = (0.8, 0.2, 0.6, 0.4)
        second = (0.2, 0.7, 0.4, 0.5)
        backdrop = (0.1, 0.3, 0.9, 0.65)

        forward = isolated_group((first, second), backdrop, mode="multiply")
        reversed_order = isolated_group((second, first), backdrop, mode="multiply")

        assert_color_close(self, forward, (0.1423463687150838, 0.3028491620111731,
                                            0.530391061452514, 0.895))
        assert_color_close(self, reversed_order, (0.19798882681564248, 0.24195530726256986,
                                                  0.5721787709497207, 0.895))
        self.assertNotEqual(forward, reversed_order)

    def test_transparent_colored_edge_does_not_tint_the_backdrop(self) -> None:
        transparent_magenta = (1.0, 0.0, 1.0, 0.0)
        backdrop = (0.15, 0.6, 0.85, 0.7)

        for mode in ("normal", "multiply"):
            assert_color_close(self, over(transparent_magenta, backdrop, mode), backdrop)

    def test_mask_zero_half_and_one_scale_the_whole_isolated_group(self) -> None:
        red = (1.0, 0.0, 0.0, 1.0)
        black = (0.0, 0.0, 0.0, 1.0)

        samples = [isolated_group((red,), black, mask_alpha=mask) for mask in (0.0, 0.5, 1.0)]

        assert_color_close(self, samples[0], black)
        assert_color_close(self, samples[1], (0.5, 0.0, 0.0, 1.0))
        assert_color_close(self, samples[2], red)


if __name__ == "__main__":
    unittest.main()
