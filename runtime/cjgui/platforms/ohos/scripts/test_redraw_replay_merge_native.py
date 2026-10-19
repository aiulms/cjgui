"""Production replay-merge predicate: only contiguous plain replays may merge.

The render thread may skip a plain redraw replay only when the immediately
following queued job is another plain redraw replay. Any other job -- Present,
a frozen-value (installedCoverage) redraw, CaretHitTest, Measure, ImageRealize,
Teardown, Shutdown, or any unknown kind -- is a barrier: it can depend on the
layout published by the preceding draw (real production: postCaretHitAfterRedraw
enqueues Redraw+hit atomically and the pump waits for the hit), so the draw it
was queued behind must really execute.

RED on the pre-fix source: the old predicate skipped any non-redraw job while
scanning forward, so Redraw -> CaretHitTest -> Redraw returned true and the hit
ran before any draw published a layout (see test_caret_hit_after_redraw_merge_native).
"""
from pathlib import Path
import subprocess
import tempfile
import unittest
from test_text_geometry_native import extract_decl

SOURCE = Path(__file__).resolve().parents[1] / 'host' / 'ohos_renderer.cpp'

PREFIX = r'''
#include <cassert>
#include <cstdint>
#include <deque>
#include <memory>
enum class JobKind { Measure, CaretHitTest, Present, Redraw, ImageRealize, Teardown, Shutdown };
struct WaitableJob { JobKind kind; const char *observationReason="unspecified";
 uint64_t observationId=0; explicit WaitableJob(JobKind k):kind(k){} virtual ~WaitableJob()=default; };
using JobRef = std::shared_ptr<WaitableJob>;
struct Coverage {};
using CjguiOhosCoverage = std::shared_ptr<Coverage>;
'''

RENDER_OPEN = r'''
struct Render {
 std::deque<JobRef> jobs;
'''
RENDER_CLOSE = r'''
};
'''

MAIN = r'''
int main(){
 Render r;
 // Empty queue / single job: nothing to merge.
 assert(!r.replaySupersededByLaterQueuedReplayLocked());
 r.jobs.push_back(std::make_shared<RedrawJob>("a"));
 assert(!r.replaySupersededByLaterQueuedReplayLocked());
 // Two immediately adjacent plain replays: the later one redraws the editing
 // view right after, so the earlier transient draw is covered.
 r.jobs.clear();
 r.jobs.push_back(std::make_shared<RedrawJob>("a"));
 r.jobs.push_back(std::make_shared<RedrawJob>("b"));
 assert(r.replaySupersededByLaterQueuedReplayLocked());
 // Present behind is a barrier: the local committed frame keeps its draw.
 r.jobs.clear();
 r.jobs.push_back(std::make_shared<RedrawJob>("a"));
 r.jobs.push_back(std::make_shared<WaitableJob>(JobKind::Present));
 assert(!r.replaySupersededByLaterQueuedReplayLocked());
 // CaretHitTest behind is a barrier: the hit reads the layout published by
 // the draw it was queued after.
 r.jobs.clear();
 r.jobs.push_back(std::make_shared<RedrawJob>("a"));
 r.jobs.push_back(std::make_shared<WaitableJob>(JobKind::CaretHitTest));
 assert(!r.replaySupersededByLaterQueuedReplayLocked());
 // Measure / ImageRealize / Teardown / Shutdown kinds are barriers.
 for (JobKind kind : {JobKind::Measure, JobKind::ImageRealize, JobKind::Teardown, JobKind::Shutdown}) {
   r.jobs.clear();
   r.jobs.push_back(std::make_shared<RedrawJob>("a"));
   r.jobs.push_back(std::make_shared<WaitableJob>(kind));
   assert(!r.replaySupersededByLaterQueuedReplayLocked());
 }
 // Frozen-value (coverage) wake at either position is not a plain replay.
 r.jobs.clear();
 r.jobs.push_back(std::make_shared<RedrawJob>("a"));
 { auto cov=std::make_shared<RedrawJob>("b"); cov->installedCoverage=std::make_shared<Coverage>(); r.jobs.push_back(cov); }
 assert(!r.replaySupersededByLaterQueuedReplayLocked());
 r.jobs.clear();
 { auto cov=std::make_shared<RedrawJob>("a"); cov->installedCoverage=std::make_shared<Coverage>(); r.jobs.push_back(cov); }
 r.jobs.push_back(std::make_shared<RedrawJob>("b"));
 assert(!r.replaySupersededByLaterQueuedReplayLocked());
 // Head is not a redraw: no merge even when a plain redraw follows.
 r.jobs.clear();
 r.jobs.push_back(std::make_shared<WaitableJob>(JobKind::Present));
 r.jobs.push_back(std::make_shared<RedrawJob>("b"));
 assert(!r.replaySupersededByLaterQueuedReplayLocked());
 // A barrier anywhere in the contiguous run blocks even with a plain replay
 // further behind.
 r.jobs.clear();
 r.jobs.push_back(std::make_shared<RedrawJob>("a"));
 r.jobs.push_back(std::make_shared<WaitableJob>(JobKind::CaretHitTest));
 r.jobs.push_back(std::make_shared<RedrawJob>("b"));
 assert(!r.replaySupersededByLaterQueuedReplayLocked());
 // Adjacent run of three: still mergeable (head covered by the next draw).
 r.jobs.clear();
 r.jobs.push_back(std::make_shared<RedrawJob>("a"));
 r.jobs.push_back(std::make_shared<RedrawJob>("b"));
 r.jobs.push_back(std::make_shared<RedrawJob>("c"));
 assert(r.replaySupersededByLaterQueuedReplayLocked());
 return 0;
}
'''


def harness(source):
    text = PREFIX + extract_decl(source, 'struct RedrawJob : WaitableJob {')
    text += RENDER_OPEN
    text += extract_decl(source, 'bool replaySupersededByLaterQueuedReplayLocked() const')
    text += RENDER_CLOSE
    return text + MAIN


class RedrawReplayMergeNativeTest(unittest.TestCase):
    def run_source(self, source):
        with tempfile.TemporaryDirectory(prefix='ohos-redraw-replay-') as directory:
            root = Path(directory)
            (root / 'probe.cpp').write_text(harness(source))
            p = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                                str(root / 'probe.cpp'), '-o', str(root / 'probe')], capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            return subprocess.run([str(root / 'probe')], capture_output=True, text=True).returncode

    def test_predicate_merges_only_contiguous_plain_replays(self):
        self.assertEqual(self.run_source(SOURCE.read_text()), 0)

    def test_negative_controls(self):
        source = SOURCE.read_text()
        controls = [
            ('if (jobs.size() < 2) return false;', 'if (jobs.size() < 2) return true;'),
            ('if (jobs[1]->kind != JobKind::Redraw) return false;',
             'if (jobs[1]->kind != JobKind::Redraw) return jobs.size() > 2;'),
            ('if (head->installedCoverage) return false;',
             'if (head->installedCoverage && false) return false;'),
            ('if (next->installedCoverage) return false;',
             'if (next->installedCoverage && false) return false;'),
        ]
        for old, new in controls:
            with self.subTest(guard=old):
                self.assertIn(old, source)
                self.assertNotEqual(self.run_source(source.replace(old, new, 1)), 0)


if __name__ == '__main__':
    unittest.main()
