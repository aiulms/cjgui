#!/usr/bin/env python3
"""Compile the bridge's production touch FIFO helpers and exercise overload cases."""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "cjgui_host_bridge.cpp"


def extract_method(text: str, signature: str) -> str:
    start = text.index(signature)
    opening = text.index("{", start)
    depth = 0
    for index in range(opening, len(text)):
        depth += (text[index] == "{") - (text[index] == "}")
        if depth == 0:
            return text[start:index + 1]
    raise ValueError("unterminated method")


def queue_policy(text: str) -> str:
    start = text.index("struct TouchRecord {")
    end = text.index("std::atomic<int> g_foreground{0};", start)
    return text[start:end]


class TouchBridgeQueueNativeTest(unittest.TestCase):
    def run_policy(self, main: str) -> subprocess.CompletedProcess[str]:
        source = SOURCE.read_text()
        policy = queue_policy(source)
        harness = r'''
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <map>
#include <mutex>
#include <optional>
#include <set>
#include <vector>
std::mutex g_touchMutex;
enum TouchAction : uint32_t { kTouchBegin = 37, kTouchUpdate = 38, kTouchEnd = 39, kTouchCancel = 40 };
''' + policy + r'''
int main() {
''' + main + r'''
}
'''
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "touch_queue.cpp"
            binary = pathlib.Path(directory) / "touch_queue"
            path.write_text(harness)
            subprocess.run(["clang++", "-std=c++11", "-Wall", "-Wextra", "-Werror",
                            "-Wno-unused-const-variable", "-Wno-unused-function",
                            str(path), "-o", str(binary)], check=True)
            return subprocess.run([str(binary)], text=True, capture_output=True)

    def test_source_level_platform_input_guards(self) -> None:
        source = SOURCE.read_text()
        dispatch = extract_method(source, "void dispatchTouchImpl(OH_NativeXComponent *component, void *window)")
        self.assertIn("OH_NATIVEXCOMPONENT_RESULT_SUCCESS", dispatch)
        self.assertIn("touch read failed: dropped", dispatch)
        self.assertIn("std::isfinite(touch.x)", dispatch)
        self.assertIn("std::isfinite(touch.y)", dispatch)
        self.assertIn("static_cast<int64_t>(touch.id)", dispatch)
        self.assertIn("rec->appInstance", dispatch)
        self.assertIn("rec->componentInstance", dispatch)

    def test_capacity_raw_fifo_and_terminal_reservation(self) -> None:
        result = self.run_policy(r'''
    enqueueTouchRecordLocked(kTouchBegin, 10, 20, 1, 2, 3, 0);
    GestureKey key = g_activeGesture;
    for (int i = 0; i < 200; ++i) enqueueTouchRecordLocked(kTouchUpdate, 10, 20 + i, 1, 2, 3, 0);
    enqueueTouchRecordLocked(kTouchEnd, 10, 220, 1, 2, 3, 0);
    if (g_touchQueue.size() != 202) return 1;
    if (g_touchQueue.front().action != kTouchBegin || g_touchQueue.front().epoch != key.epoch) return 2;
    if (g_touchQueue.back().action != kTouchEnd || g_touchQueue.back().epoch != key.epoch) return 3;
    if (touchQueueOccupancyLocked() > kTouchQueueCapacity) return 4;
    return 0;
''')
        self.assertEqual(result.returncode, 0, f"raw FIFO/reservation exit={result.returncode}: {result.stderr}")

    def test_actual_dequeue_ledger_and_full_victim_key(self) -> None:
        result = self.run_policy(r'''
    enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, 22, 77, 5);
    TouchRecord delivered{};
    if (!dequeueTouchRecordLocked(&delivered)) return 1;
    touchRecordDeliveredLocked(delivered);
    GestureKey key = touchKey(delivered);
    if (g_touchGestureLedger.find(key) == g_touchGestureLedger.end() ||
        !g_touchGestureLedger[key].beginDelivered) return 2;
    // The queue no longer contains any victim record by the time overload emits
    // its CANCEL. Every identity component must come from the frozen key.
    g_touchQueue.push_back(TouchRecord{kTouchUpdate, 1, 1, 11, 22, 77, 5, key.epoch});
    for (uint64_t i = 0; i < 255; ++i) {
        g_touchQueue.push_back(TouchRecord{kTouchUpdate, 1, 1, 100 + i, 200 + i, 300 + i,
                                           static_cast<int64_t>(i), 400 + i});
    }
    if (!makeTouchQueueRoomLocked(1, 9, 9)) return 3;
    if (g_touchQueue.empty()) return 4;
    const TouchRecord &cancel = g_touchQueue.front();
    if (cancel.action != kTouchCancel || !(touchKey(cancel) == key)) return 5;
    if (g_terminalReservations.find(key) != g_terminalReservations.end()) return 6;
    if (touchQueueOccupancyLocked() > kTouchQueueCapacity) return 7;
    return 0;
''')
        self.assertEqual(result.returncode, 0, f"dequeue/victim-key exit={result.returncode}: {result.stderr}")

    def test_undelivered_overflow_drops_the_remainder_of_that_physical_gesture(self) -> None:
        result = self.run_policy(r'''
    enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, 22, 77, 5);
    GestureKey key = g_activeGesture;
    for (int i = 0; i < 254; ++i) enqueueTouchRecordLocked(kTouchUpdate, i, i, 11, 22, 77, 5);
    // This over-capacity sample evicts the still-undelivered BEGIN and all of
    // its updates. It must not then be appended back to the suppressed gesture.
    enqueueTouchRecordLocked(kTouchUpdate, 999, 999, 11, 22, 77, 5);
    for (const TouchRecord &record : g_touchQueue) {
        if (touchKey(record) == key) return 1;
    }
    if (!gestureSuppressedLocked(key)) return 2;
    if (touchQueueOccupancyLocked() > kTouchQueueCapacity) return 3;
    return 0;
''')
        self.assertEqual(result.returncode, 0, f"undelivered gesture suppression exit={result.returncode}: {result.stderr}")

    def test_cancel_survives_terminal_pressure_and_reservations_stay_bounded(self) -> None:
        result = self.run_policy(r'''
    enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, 22, 77, 5);
    TouchRecord begin{};
    if (!dequeueTouchRecordLocked(&begin)) return 1;
    touchRecordDeliveredLocked(begin);
    GestureKey key = touchKey(begin);
    for (uint64_t i = 0; i < 255; ++i) {
        g_touchQueue.push_back(TouchRecord{kTouchCancel, 1, 1, 900 + i, 901 + i, 902 + i,
                                           static_cast<int64_t>(i), 903 + i});
    }
    if (touchQueueOccupancyLocked() != kTouchQueueCapacity) return 2;
    enqueueTouchRecordLocked(kTouchUpdate, 2, 2, 11, 22, 77, 5);
    if (g_touchQueue.size() != kTouchQueueCapacity) return 3;
    size_t priorCancels = 0;
    size_t ownCancels = 0;
    for (const TouchRecord &record : g_touchQueue) {
        if (record.action != kTouchCancel) return 4;
        if (touchKey(record) == key) ++ownCancels;
        else ++priorCancels;
    }
    if (priorCancels != 255 || ownCancels != 1) return 5;
    if (!g_terminalReservations.empty()) return 6;
    if (touchQueueOccupancyLocked() > kTouchQueueCapacity) return 7;
    return 0;
''')
        self.assertEqual(result.returncode, 0, f"terminal pressure/reservation exit={result.returncode}: {result.stderr}")

    def test_suppression_lives_until_matching_physical_terminal(self) -> None:
        result = self.run_policy(r'''
    enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, 22, 77, 5);
    TouchRecord begin{};
    if (!dequeueTouchRecordLocked(&begin)) return 1;
    touchRecordDeliveredLocked(begin);
    GestureKey oldKey = touchKey(begin);
    suppressGestureLocked(oldKey);
    enqueueTouchRecordLocked(kTouchBegin, 2, 2, 11, 22, 77, 5);
    if (!gestureSuppressedLocked(oldKey)) return 2; // duplicate DOWN cannot retire old pointer
    if (!g_hasActiveGesture || !(g_activeGesture == oldKey)) return 3;
    enqueueTouchRecordLocked(kTouchEnd, 3, 3, 11, 22, 77, 5);
    if (gestureSuppressedLocked(oldKey)) return 4;
    if (g_hasActiveGesture) return 5;
    return 0;
''')
        self.assertEqual(result.returncode, 0, f"suppression lifetime exit={result.returncode}: {result.stderr}")

    def test_recreated_surface_sweeps_old_capture_before_next_generation(self) -> None:
        source = SOURCE.read_text()
        created = extract_method(source, "static void classifyAndPublishSurface(")
        changed = extract_method(source, "void onSurfaceChangedImpl(")
        simulated = extract_method(source, "static int32_t bridgeSimulateSurfaceCreatedImpl(void)\n{")
        self.assertIn("retireReplacedTouchOrigins(retiredTouchOrigins)", created)
        self.assertGreaterEqual(changed.count("retireReplacedTouchOrigins(retiredTouchOrigins)"), 2)
        self.assertIn("retireReplacedTouchOrigins(retiredTouchOrigins)", simulated)
        result = self.run_policy(r'''
    for (uint64_t generation = 1; generation <= 600; ++generation) {
        if (generation > 1) {
            retireReplacedTouchOrigins({RetiredTouchOrigin{11, generation - 1, generation - 1}});
            TouchRecord terminal{};
            if (!dequeueTouchRecordLocked(&terminal) || terminal.action != kTouchCancel ||
                terminal.generation != generation - 1) return 1;
            touchRecordDeliveredLocked(terminal);
        }
        enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, generation, generation, 5);
        TouchRecord begin{};
        if (!dequeueTouchRecordLocked(&begin) || begin.action != kTouchBegin ||
            begin.generation != generation) return 2;
        touchRecordDeliveredLocked(begin);
        if (g_touchGestureLedger.size() != 1 || g_terminalReservations.size() != 1 ||
            !g_suppressedGestures.empty() || !g_touchQueue.empty()) return 3;
    }
    retireReplacedTouchOrigins({RetiredTouchOrigin{11, 600, 600}});
    TouchRecord terminal{};
    if (!dequeueTouchRecordLocked(&terminal) || terminal.action != kTouchCancel ||
        terminal.generation != 600) return 4;
    touchRecordDeliveredLocked(terminal);
    if (!g_touchGestureLedger.empty() || !g_terminalReservations.empty() ||
        !g_suppressedGestures.empty() || !g_touchQueue.empty()) return 5;
    // A delayed old destroy can sweep the old key again but not the new key.
    enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, 601, 601, 5);
    GestureKey newKey = g_activeGesture;
    retireReplacedTouchOrigins({RetiredTouchOrigin{11, 600, 600}});
    if (!g_hasActiveGesture || !(g_activeGesture == newKey) ||
        g_touchGestureLedger.find(newKey) == g_touchGestureLedger.end()) return 6;
    return 0;
''')
        self.assertEqual(result.returncode, 0, f"surface replacement sweep exit={result.returncode}: {result.stderr}")

    def test_retired_surface_sweep_emits_cancel_only_for_delivered_capture(self) -> None:
        result = self.run_policy(r'''
    enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, 22, 77, 5);
    TouchRecord begin{};
    if (!dequeueTouchRecordLocked(&begin)) return 1;
    touchRecordDeliveredLocked(begin);
    const GestureKey deliveredKey = touchKey(begin);
    enqueueTouchRecordLocked(kTouchUpdate, 2, 2, 11, 22, 77, 5);
    suppressGestureLocked(deliveredKey);
    retireTouchSurfaceLocked(11, 22, 77, 0, 0);
    if (g_touchQueue.size() != 1 || g_touchQueue.front().action != kTouchCancel) return 2;
    if (!(touchKey(g_touchQueue.front()) == deliveredKey)) return 3;
    if (!touchTerminalMayFinishRetiredLocked(g_touchQueue.front(), true)) return 4;
    if (touchTerminalMayFinishRetiredLocked(g_touchQueue.front(), false)) return 5;
    if (gestureSuppressedLocked(deliveredKey) || g_hasActiveGesture) return 6;
    if (touchQueueOccupancyLocked() > kTouchQueueCapacity) return 7;
    TouchRecord cancel{};
    if (!dequeueTouchRecordLocked(&cancel)) return 8;
    touchRecordDeliveredLocked(cancel);
    if (!g_touchGestureLedger.empty() || !g_terminalReservations.empty()) return 9;

    // If a normal END was queued but still behind updates at retirement, move
    // that exact delivered terminal to the front instead of purging it.
    enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, 22, 79, 5);
    if (!dequeueTouchRecordLocked(&begin)) return 10;
    touchRecordDeliveredLocked(begin);
    const GestureKey endedKey = touchKey(begin);
    enqueueTouchRecordLocked(kTouchUpdate, 2, 2, 11, 22, 79, 5);
    enqueueTouchRecordLocked(kTouchEnd, 3, 3, 11, 22, 79, 5);
    retireTouchSurfaceLocked(11, 22, 79, 0, 0);
    if (g_touchQueue.size() != 1 || g_touchQueue.front().action != kTouchEnd) return 11;
    if (!(touchKey(g_touchQueue.front()) == endedKey) ||
        !touchTerminalMayFinishRetiredLocked(g_touchQueue.front(), true)) return 12;
    if (!dequeueTouchRecordLocked(&cancel)) return 13;
    touchRecordDeliveredLocked(cancel);
    if (!g_touchGestureLedger.empty() || !g_terminalReservations.empty()) return 14;

    // An undelivered BEGIN has no controller capture to cancel on retirement.
    enqueueTouchRecordLocked(kTouchBegin, 1, 1, 11, 22, 80, 5);
    retireTouchSurfaceLocked(11, 22, 80, 0, 0);
    if (!g_touchQueue.empty() || !g_touchGestureLedger.empty() || !g_terminalReservations.empty()) return 15;
    return 0;
''')
        self.assertEqual(result.returncode, 0, f"surface retirement terminal sweep exit={result.returncode}: {result.stderr}")

    def test_retired_ingress_terminal_gate_uses_frozen_origin_identity(self) -> None:
        source = SOURCE.read_text()
        dequeue = extract_method(source, "int ingressTouchDequeueEx(uint32_t *outAction, float *outX, float *outY,")
        self.assertIn("findSurfaceByGenerationLocked(record.generation)", dequeue)
        self.assertIn("touchTerminalMayFinishRetiredLocked(record, exactOrigin)", dequeue)
        self.assertIn("origin->appInstance == record.appInstance", dequeue)
        self.assertIn("origin->componentInstance == record.componentInstance", dequeue)
        self.assertIn("retireTouchSurfaceLocked(appInstance, componentInstance, generation", source)
        self.assertIn("retireTouchSurfaceLocked(record.appInstance, record.componentInstance", dequeue)


if __name__ == "__main__":
    unittest.main()
