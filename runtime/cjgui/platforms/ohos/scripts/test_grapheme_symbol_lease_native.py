#!/usr/bin/env python3
"""Real production grapheme queries and system ICU library ownership.

Only loader faults and iterator scheduling are controlled. Segmentation,
UTF conversion and iterator creation/destruction use the host system ICU.
This is a native lifetime test, not device feedback or allocation evidence.
"""
from pathlib import Path
import argparse
import importlib.util
import json
import subprocess
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("system_grapheme", HERE / "test_grapheme_service_native.py")
system = importlib.util.module_from_spec(spec)
spec.loader.exec_module(system)

INSTRUMENT = r'''
#include <atomic>
#include <condition_variable>
#include <cstdlib>
#include <mutex>
#include <thread>
static std::atomic<int> loads{0}, unloads{0}, opened{0}, closed{0}, live{0}, earlyUnload{0};
static std::atomic<int> handleReferences{0};
static std::atomic<int> failLoad{0}, failSymbol{0};
static std::atomic<decltype(&ubrk_open)> realOpen{nullptr};
static std::atomic<decltype(&ubrk_close)> realClose{nullptr};
static std::mutex pauseLock;
static std::condition_variable pauseChanged;
static bool pauseIterator=false, iteratorEntered=false, iteratorContinue=false;
static UBreakIterator* countedOpen(UBreakIteratorType type, const char* locale,
                                  const UChar* text, int32_t length, UErrorCode* error) {
 auto* iterator=realOpen.load()(type,locale,text,length,error);
 if(iterator) {
  ++opened; ++live;
  std::unique_lock<std::mutex> lock(pauseLock);
  if(pauseIterator) {
   iteratorEntered=true; pauseChanged.notify_all();
   pauseChanged.wait(lock,[]{return iteratorContinue;});
  }
 }
 return iterator;
}
static void countedClose(UBreakIterator* iterator) {
 realClose.load()(iterator);
 if(iterator) { ++closed; --live; }
}
static void* countedDlopen(const char* path,int flags) {
 ++loads;
 if(failLoad.exchange(0)) return nullptr;
 void* handle=::dlopen(path,flags);
 if(handle) ++handleReferences;
 return handle;
}
static void* countedDlsym(void* handle,const char* symbol) {
 if(!std::strcmp(symbol,"ubrk_following") && failSymbol.exchange(0)) return nullptr;
 void* actual=::dlsym(handle,symbol);
 if(actual && !std::strcmp(symbol,"ubrk_open")) {
  realOpen.store(reinterpret_cast<decltype(&ubrk_open)>(actual));
  return reinterpret_cast<void*>(&countedOpen);
 }
 if(actual && !std::strcmp(symbol,"ubrk_close")) {
  realClose.store(reinterpret_cast<decltype(&ubrk_close)>(actual));
  return reinterpret_cast<void*>(&countedClose);
 }
 return actual;
}
static int countedDlclose(void* handle) {
 if(handleReferences.fetch_sub(1)==1 && live.load()) ++earlyUnload;
 ++unloads;
 return ::dlclose(handle);
}
#define dlopen countedDlopen
#define dlsym countedDlsym
#define dlclose countedDlclose
#define CJGUI_OHOS_ICU_LIBRARY "/usr/lib/libicucore.dylib"
'''

MAIN = r'''
#undef dlopen
#undef dlsym
#undef dlclose
static std::atomic<int> failures{0};
static void check(bool okay,const char* reason) {
 if(!okay) { fprintf(stderr,"CONTRACT RED: %s\n",reason); ++failures; }
}
static void query(const std::string& cluster) {
 const std::string text="X"+cluster+"Y";
 for(size_t i=1;i<1+cluster.size();++i) {
  uint64_t lo=0,hi=0;
  auto result=cjgui_internal_renderer_grapheme_cluster_range(text.c_str(),text.size(),i,&lo,&hi);
  check(result==0 && lo==1 && hi==1+cluster.size(),"real system ICU cluster bytes");
 }
}
static void snapshot(const char* stage) {
 printf("{\"stage\":\"%s\",\"loads\":%d,\"unloads\":%d,\"opened\":%d,\"closed\":%d,\"live\":%d,\"earlyUnload\":%d}\n",
        stage,loads.load(),unloads.load(),opened.load(),closed.load(),live.load(),earlyUnload.load());
}
int main(int argc,char** argv) {
 std::atexit([]{snapshot("module-exit");});
 const std::string mode=argc>1?argv[1]:"reuse";
 if(mode=="shutdown") {
#ifdef HAS_ICU_LEASE
  query(u8"中");
  g_render.result=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
  check(ohos_renderer_shutdown_render_thread()==99 && unloads==0,"failed shutdown keeps provider");
  g_render.result=CJGUI_INTERNAL_RENDERER_OK;
  check(ohos_renderer_shutdown_render_thread()==0 && unloads==1 && live==0,"confirmed shutdown releases provider");
  query("a");
  check(loads==2 && unloads==1,"new lifecycle acquires a fresh provider");
  check(ohos_renderer_shutdown_render_thread()==0 && unloads==2,"second lifecycle closes its provider");
#else
  check(false,"production service has no owned retirement path");
#endif
 } else if(mode=="retry-load" || mode=="retry-symbol") {
  if(mode=="retry-load") failLoad=1; else failSymbol=1;
  uint64_t lo=12,hi=34;
  auto result=cjgui_internal_renderer_grapheme_cluster_range("a",1,0,&lo,&hi);
  check(result==32 && lo==0 && hi==0,"initial unavailable provider refuses exactly");
  check(unloads==(mode=="retry-load"?0:1),"failed provider has no retained handle");
  query(u8"中");
  check(loads==2 && opened==closed && live==0,"failed load/symbol retries actual ICU");
  check(unloads==(mode=="retry-load"?0:1),"successful retry is retained");
 } else if(mode=="retire-pin") {
#ifdef HAS_ICU_LEASE
  { std::lock_guard<std::mutex> lock(pauseLock); pauseIterator=true; }
  std::thread inFlight([]{query("a");});
  { std::unique_lock<std::mutex> lock(pauseLock);
    pauseChanged.wait(lock,[]{return iteratorEntered;}); }
  cjguiOhosReleaseSystemIcu();
  check(live==1 && unloads==0,"retirement cannot close in-flight iterator provider");
  { std::lock_guard<std::mutex> lock(pauseLock); iteratorContinue=true; pauseIterator=false; }
  pauseChanged.notify_all(); inFlight.join();
  check(live==0 && unloads==1 && earlyUnload==0,"retired provider closes after original iterator");
  query(u8"👍🏽");
  check(loads==2 && unloads==1,"post-retirement service reacquires a real provider");
  cjguiOhosReleaseSystemIcu();
  check(unloads==2 && live==0 && earlyUnload==0,"successful shutdown releases current provider");
#else
  check(false,"production service has no owned retirement path");
#endif
 } else {
  const std::vector<std::string> clusters={"e\xCC\x81",u8"中",u8"👨‍👩‍👧‍👦",u8"👍🏽",u8"🇨🇳","\r\n"};
  for(const auto& cluster:clusters) query(cluster);
  std::vector<std::thread> workers;
  for(int n=0;n<8;++n) workers.emplace_back([&,n]{
   for(int i=0;i<12;++i) query(clusters[(n+i)%clusters.size()]);
  });
  for(auto& worker:workers) worker.join();
  check(loads==1 && unloads==0,"one successful provider for consecutive/concurrent queries");
  check(opened==closed && live==0 && earlyUnload==0,"each query owns and closes its real iterator");
 }
 snapshot(mode.c_str());
 return failures.load()?90:0;
}
'''


def compile_probe(directory, production=None):
    production = system.production_service() if production is None else production
    flags = "#define HAS_ICU_LEASE 1\n" if "cjguiOhosReleaseSystemIcu()" in production else ""
    source = directory / "main.cpp"
    shutdown = ""
    if flags:
        native = system.SOURCE.read_text()
        signature = "int32_t ohos_renderer_shutdown_render_thread()"
        begin = native.index(signature)
        end = native.index("\n}\n", begin) + 3
        shutdown = r'''
#define RLOGI(...) ((void)0)
#define RLOGE(...) ((void)0)
struct {void invalidate(){}} g_images;
struct {int result=0; int submittedFrames=0,rejectedFlushes=0;
 CjguiInternalRendererStatus shutdownAndJoin(){return static_cast<CjguiInternalRendererStatus>(result);}
} g_render;
static std::atomic<bool> g_rendererShutdownDone{false};
static void cjguiOhosLogImageSnapshot(const char*){}
''' + native[begin:end]
    source.write_text(system.PREFIX + INSTRUMENT + flags + production + shutdown + MAIN)
    binary = directory / "probe"
    build = subprocess.run(["xcrun", "clang++", "-std=c++17", "-pthread", "-idirafter",
                            str(system.SDK_INCLUDE), str(source), "-o", str(binary)],
                           capture_output=True, text=True)
    (directory / "build.stderr").write_text(build.stderr)
    if build.returncode:
        raise RuntimeError(build.stderr)
    return binary


class SymbolLeaseTests(unittest.TestCase):
    def test_actual_queries_reuse_retry_and_inflight_retirement(self):
        with tempfile.TemporaryDirectory(prefix="cjgui-icu-symbol-lease-") as temp:
            binary = compile_probe(Path(temp))
            for mode in ("reuse", "retry-load", "retry-symbol", "retire-pin", "shutdown"):
                with self.subTest(mode=mode):
                    run = subprocess.run([str(binary), mode], capture_output=True, text=True, timeout=20)
                    self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
                    rows = [json.loads(line) for line in run.stdout.splitlines()]
                    final = rows[-1]
                    self.assertEqual(final["live"], 0)
                    self.assertEqual(final["earlyUnload"], 0)
                    self.assertEqual(final["loads"] - (mode == "retry-load"), final["unloads"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--before", type=Path)
    args, rest = parser.parse_known_args()
    if args.evidence:
        args.evidence.mkdir(parents=True, exist_ok=False)
        binary = compile_probe(args.evidence, args.before.read_text() if args.before else None)
        results = []
        for mode in ("reuse", "retry-load", "retry-symbol", "retire-pin", "shutdown"):
            run = subprocess.run([str(binary), mode], capture_output=True, text=True, timeout=20)
            (args.evidence / f"{mode}.stdout").write_text(run.stdout)
            (args.evidence / f"{mode}.stderr").write_text(run.stderr)
            results.append({"mode": mode, "exit": run.returncode})
        (args.evidence / "results.json").write_text(json.dumps(results, indent=2) + "\n")
        print(json.dumps(results))
        raise SystemExit(0 if all(row["exit"] == 0 for row in results) else 90)
    unittest.main(argv=[__file__] + rest)
