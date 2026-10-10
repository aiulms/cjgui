#!/usr/bin/env python3
"""A2 presentation 租约预算——本文件已由**真实帧运行链**测试接替。

历史（2026-10-05 前）：本测试逐字抽取三处生产 if 块，在合成 Frame 模型中断言
零 Flush 链。fixla19 复核证明该模型对两类生产回归不敏感（把 redraw 溢出门挪到
SurfaceFlush 之后、把计费改成只数新表，harness 均无变化）：
  artifacts/visual-edit-20261004/guidance-review-20261005/fixla19-review/
  overflow-gate-coverage-result.json

接替：test_presentation_budget_real_frame_native.py 逐字抽取 redraw 全链
（绘制循环 → 三界判据+必需/可选分流 → Flush 前拒候选 → publishPaintedLayout →
真实命中消费）与 present 拒候选切片、真实 post/postIfRunning 队列界，运行
①②③反例并自带两类变异判别力自检（门挪后翻红、计费漏旧表翻红）。

本文件保留文件名以维持测试发现覆盖面：直接运行接替测试并原样转发其结果。
"""
import importlib.util
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
SUCCESSOR = HERE / "test_presentation_budget_real_frame_native.py"


def load_successor():
    spec = importlib.util.spec_from_file_location(
        "presentation_budget_real_frame", SUCCESSOR)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class SupersessionShimTest(unittest.TestCase):
    #: 接替文件必须一直覆盖这三组门 + 变异判别力；数量下限比魔数更有意义。
    REQUIRED_SUCCESSOR_CASES = (
        "test_real_frame_counterexamples",
        "test_production_ordering_anchors",
        "test_harness_exit_codes_are_unambiguous",
        "test_gate_moved_after_flush_is_detected",
        "test_billing_ignoring_published_table_is_detected",
        "test_billing_ignoring_transient_peak_is_detected",
        "test_admission_after_expensive_layout_is_detected",
        "test_required_reservation_removed_is_detected",
    )

    def test_successor_suite_green(self):
        mod = load_successor()
        suite = unittest.TestLoader().loadTestsFromModule(mod)
        names = set()
        def collect(node):
            for child in node:
                collect(child) if isinstance(child, unittest.TestSuite) else names.add(
                    child.id().rsplit(".", 1)[-1])
        collect(suite)
        missing = [n for n in self.REQUIRED_SUCCESSOR_CASES if n not in names]
        self.assertEqual(missing, [], "successor suite lost cases: %s" % missing)
        result = unittest.TextTestRunner(verbosity=0, stream=sys.stderr).run(suite)
        self.assertTrue(result.wasSuccessful(),
                        "successor real-frame suite regressed; see its output")


if __name__ == "__main__":
    unittest.main(verbosity=2)
