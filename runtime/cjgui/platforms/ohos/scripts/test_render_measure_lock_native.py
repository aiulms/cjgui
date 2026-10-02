"""Real mutex counterexample for Session→queued renderer wait inversion.

Only the two production measurement C ABI bodies are extracted. The worker
models a redraw already ahead of Measure and requiring the Session mutex.
"""
from pathlib import Path
import subprocess
import tempfile
import unittest
from test_text_geometry_native import extract_decl

SOURCE = Path(__file__).resolve().parents[1] / 'host' / 'ohos_renderer.cpp'
MARKERS = [
    'CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_text(',
    'CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_multiline_natural_height(',
]
PREFIX = r'''
#include <cassert>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <iostream>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#define RLOGW(...) ((void)0)
enum CjguiInternalRendererStatus {CJGUI_INTERNAL_RENDERER_OK=0,CJGUI_INTERNAL_RENDERER_INVALID_SESSION=11,
 CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR=99};
struct Session {};
struct {std::mutex lock;Session session;bool valid=true;} g_sessions;
Session *lookupSessionLocked(uint64_t token){return token==17&&g_sessions.valid?&g_sessions.session:nullptr;}
struct CjguiInternalRendererTextMeasurement {uint32_t width=0,height=0,lineHeight=0,baseline=0;};
struct MeasureJob {
 std::string text;double fontSize=0,constraintWidth=0;uint32_t fontWeight=0;bool unlimitedWidth=false;
 CjguiInternalRendererTextMeasurement measurement;
 std::mutex lock;std::condition_variable cv;bool done=false;
 CjguiInternalRendererStatus waitFor(){
  std::unique_lock<std::mutex> g(lock);
  return cv.wait_for(g,std::chrono::milliseconds(200),[this]{return done;})
    ?CJGUI_INTERNAL_RENDERER_OK:CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
 }
};
using JobRef=std::shared_ptr<MeasureJob>;
struct RenderQueue {
 std::thread worker;bool invalidate=false;
 void post(const JobRef &job){
  worker=std::thread([this,job]{
   // The queued redraw takes the real Session mutex before Measure can run.
   {std::lock_guard<std::mutex> g(g_sessions.lock);if(invalidate)g_sessions.valid=false;}
   {std::lock_guard<std::mutex> g(job->lock);job->measurement.height=42;job->measurement.width=77;job->done=true;}
   job->cv.notify_all();
  });
 }
 void join(){if(worker.joinable())worker.join();}
} g_render;
'''
MAIN = r'''
int main(int argc,char **argv){
 bool multiline=argc>1&&std::string(argv[1])=="multiline";
 g_render.invalidate=argc>2;
 uint32_t height=123;CjguiInternalRendererTextMeasurement result;
 auto status=multiline?cjgui_internal_renderer_measure_composable_multiline_natural_height(17,"A",14,400,0,100,&height)
  :cjgui_internal_renderer_measure_composable_text(17,"A",14,400,0,100,&result);
 g_render.join();std::cout<<"status="<<status<<" height="<<(multiline?height:result.height)<<"\n";
 if(g_render.invalidate)return status==CJGUI_INTERNAL_RENDERER_INVALID_SESSION?0:1;
 return status==CJGUI_INTERNAL_RENDERER_OK&&(multiline?height:result.height)==42?0:1;
}
'''


class RenderMeasureLockNativeTest(unittest.TestCase):
    def run_source(self, source, args):
        with tempfile.TemporaryDirectory(prefix='ohos-measure-lock-') as directory:
            root = Path(directory)
            text = PREFIX + '\n'.join(extract_decl(source, marker) for marker in MARKERS) + MAIN
            (root / 'probe.cpp').write_text(text)
            p = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                                str(root / 'probe.cpp'), '-o', str(root / 'probe')], capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            return subprocess.run([str(root / 'probe'), *args], capture_output=True, text=True)

    def test_queued_redraw_does_not_block_measure(self):
        for args in [[], ['multiline']]:
            with self.subTest(args=args):
                p = self.run_source(SOURCE.read_text(), args)
                self.assertEqual(p.returncode, 0, p.stdout + p.stderr)

    def test_session_retirement_during_wait_is_named(self):
        for args in [['single', 'retire'], ['multiline', 'retire']]:
            with self.subTest(args=args):
                p = self.run_source(SOURCE.read_text(), args)
                self.assertEqual(p.returncode, 0, p.stdout + p.stderr)

    def test_negative_controls(self):
        source = SOURCE.read_text()
        short_lock = '''    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    }
'''
        for marker in MARKERS:
            body = extract_decl(source, marker)
            self.assertEqual(body.count(short_lock), 2)
            held = body.replace(short_lock, '''    std::lock_guard<std::mutex> g(g_sessions.lock);
    if (!lookupSessionLocked(session)) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
''', 1).replace(short_lock, '', 1)
            args = [] if 'measure_composable_text(' in marker else ['multiline']
            p = self.run_source(source.replace(body, held, 1), args)
            self.assertNotEqual(p.returncode, 0, 'holding Session across post/wait must fail')
            position = body.rindex(short_lock)
            no_recheck = body[:position] + body[position:].replace(short_lock, '', 1)
            p = self.run_source(source.replace(body, no_recheck, 1), (args or ['single']) + ['retire'])
            self.assertNotEqual(p.returncode, 0, 'retired Session must not return successful measurement')


if __name__ == '__main__':
    unittest.main()
