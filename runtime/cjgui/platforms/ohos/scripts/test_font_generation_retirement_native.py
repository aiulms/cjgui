#!/usr/bin/env python3
"""Real font-pool ownership: last external lease is not a destruction scheduler."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from test_editing_typography_reuse import block

HOST = Path(__file__).resolve().parents[1] / 'host'
HEADER = HOST / 'cjgui_ohos_font_lease.h'


def execute_case(name, code, mutation=None):
    header = HEADER.read_text()
    mutations = {
        'release-sealed-owner': ('current_.reset();\n        if (observer_)',
            'current_.reset();\n        generations_.erase(std::remove_if(generations_.begin(), generations_.end(), '
            '[](const Lease &g) { return g->sealed; }), generations_.end());\n        if (observer_)'),
        'query-destroys': ('size_t liveGenerations() const { return',
            'size_t liveGenerations() const { const_cast<CjguiOhosFontPool*>(this)->retireOneUnused(); return'),
        'omit-retiring-count': ('return generations_.size() + retiringCount_;', 'return generations_.size();'),
        'omit-pressure-retirement': (
            'while (liveGenerations() >= kMaxGenerations && retireOneUnused()) {}\n'
            '            if (liveGenerations() >= kMaxGenerations) { ++stats_->refused; return {}; }',
            'while (false && liveGenerations() >= kMaxGenerations && retireOneUnused()) {}\n'
            '            if (liveGenerations() >= kMaxGenerations) { ++stats_->refused; return {}; }'),
        'omit-external-lease-guard': ('if (!(*it)->sealed || it->use_count() != 1) continue;',
            'if (!(*it)->sealed) continue;'),
        'omit-close-drain': ('void clear() { sealCurrent(); while (retireOneUnused()) {} }',
            'void clear() { sealCurrent(); }'),
    }
    compiled_header = header
    if mutation in mutations:
        old, new = mutations[mutation]
        assert compiled_header.count(old) == 1, mutation
        compiled_header = compiled_header.replace(old, new)
    name += '-' + mutation if mutation else ''
    with tempfile.TemporaryDirectory(prefix='cjgui-font-retirement-') as directory:
        temp = Path(directory)
        cpp, exe = temp / 'test.cpp', temp / 'test'
        cpp.write_text(code)
        if mutation in mutations:
            (temp / HEADER.name).write_text(compiled_header)
        command = ['clang++', '-std=c++17', '-pthread', '-I' + str(HOST), str(cpp), '-o', str(exe)]
        built = subprocess.run(command, capture_output=True, text=True, timeout=30)
        result = subprocess.run([str(exe)], capture_output=True, text=True, timeout=10) if not built.returncode else built
        print(name + ': ' + result.stdout + result.stderr, end='')
        if os.environ.get('CJGUI_H_NATIVE_TEST_ARTIFACTS'):
            out = Path(os.environ['CJGUI_H_NATIVE_TEST_ARTIFACTS'])
            out.mkdir(parents=True, exist_ok=True)
            (out / (name + '.cpp')).write_text(code)
            if mutation in mutations:
                (out / (name + '.h')).write_text(compiled_header)
            (out / (name + '.json')).write_text(json.dumps({
                'header_SHA256': hashlib.sha256(HEADER.read_bytes()).hexdigest(),
                'renderer_SHA256': hashlib.sha256((HOST / 'ohos_renderer.cpp').read_bytes()).hexdigest(),
                'compiled_header_SHA256': hashlib.sha256(compiled_header.encode()).hexdigest(),
                'mutation': mutation,
                'compile_exit': built.returncode,
                'run_exit': None if built.returncode else result.returncode,
                'stdout': result.stdout, 'stderr': result.stderr,
            }, indent=2) + '\n')
        if built.returncode:
            raise RuntimeError('compilation failure is not a behavioral RED')
        return result.returncode


def run(mutation=None):
    code = r'''
#include "cjgui_ohos_font_lease.h"
#include <cstdio>
#include <cstdlib>
#define CHECK(x,why) do{if(!(x)){fputs("FAIL " why "\n",stderr);std::exit(1);}}while(0)
struct Collection {};
using Pool = CjguiOhosFontPool<Collection>;
int main() {
    int destroyed = 0;
    Pool pool([] { return new Collection; },
              [&](Collection *p) { ++destroyed; delete p; });
    auto accepted = pool.acquire(Pool::kWorkUnitsPerGeneration, 1);
    auto privateCandidate = pool.acquire(1, 1);
    if (!accepted || !privateCandidate || accepted->id == privateCandidate->id) return 2;
    if (pool.liveGenerations() != 2) return 3;
    // This models publication releasing the old layout's last font lease.
    // Releasing that lease must not synchronously call the SDK destructor.
    accepted.reset();
    if (destroyed != 0) {
        puts("FAIL last external lease synchronously destroyed sealed font generation");
        return 1;
    }
    CHECK(pool.liveGenerations()==2&&pool.sealedGenerations()==1&&pool.retirableGenerations()==1,
          "sealed owner disappeared or a query destroyed it");
    for(int i=0;i<3;++i){
        CHECK(pool.hasRetirable()&&pool.stats().destroyed==0&&pool.retiringGenerations()==0,
              "resource queries performed retirement");
        (void)pool.oldestRetirableSealAgeMicros();
    }
    CHECK(pool.retireOneUnused()&&destroyed==1&&pool.liveGenerations()==1,
          "safe boundary did not retire exactly one unleased owner");
    privateCandidate.reset();pool.clear();
    CHECK(destroyed==2&&pool.liveGenerations()==0&&pool.stats().retired==2,
          "close did not drain actual owners");
    // A close/clear must not destroy a generation still used by Typography.
    {int live=0;Pool p([]{return new Collection;},[&](Collection*x){++live;delete x;});
     auto first=p.acquire(3,1),same=p.acquire(5,1),next=p.acquire(Pool::kWorkUnitsPerGeneration,2);
     CHECK(first&&same&&next&&first->id==same->id,"same generation setup");
     first.reset();CHECK(!p.retireOneUnused()&&live==0,"one of two Typography leases was ignored");
     same.reset();CHECK(p.retireOneUnused()&&live==1,"last external lease never became retirable");
     p.clear();CHECK(live==1&&p.liveGenerations()==1,"clear destroyed a still-referenced font");
     next.reset();CHECK(p.hasRetirable()&&live==1,"query retired final external release");
     p.clear();CHECK(live==2&&p.liveGenerations()==0,"second close did not complete");}
    // Saturation includes sealed and retiring owners, not just active leases.
    {int sdkLive=0,maxLive=0,retired=0;Pool*observed=nullptr;
     Pool p([&]{++sdkLive;maxLive=std::max(maxLive,sdkLive);return new Collection;},[&](Collection*x){
         CHECK(observed->liveGenerations()==static_cast<size_t>(sdkLive),"retiring font omitted from live cap");
         --sdkLive;++retired;delete x;
     });observed=&p;
     auto a=p.acquire(Pool::kWorkUnitsPerGeneration,1),b=p.acquire(Pool::kWorkUnitsPerGeneration,1),
          c=p.acquire(Pool::kWorkUnitsPerGeneration,1);
     CHECK(a&&b&&c&&p.liveGenerations()==3,"three generation setup");
     auto denied=p.acquire(1,1);
     CHECK(!denied&&sdkLive==3&&p.stats().refused==1,"referenced third generation did not deny a fourth");
     b.reset();CHECK(p.liveGenerations()==3&&retired==0,"unleased sealed generation unaccounted before boundary");
     auto d=p.acquire(1,1);
     CHECK(d&&sdkLive==3&&maxLive==3&&retired==1&&p.stats().created==4,
           "capacity pressure failed to retire eligible owner before admitting replacement");
     auto work=p.stats().admittedUnits;
     CHECK(!p.acquire(Pool::kWorkUnitsPerGeneration+1,1)&&!p.acquire(1,0)&&
           p.stats().admittedUnits==work,"hard invalid request changed admitted work");
     a.reset();c.reset();d.reset();p.clear();
     CHECK(sdkLive==0&&retired==4&&p.liveGenerations()==0,"pressure/close leaked actual collections");}
    {int retired=0;Pool p([]{return new Collection;},[&](Collection*x){++retired;delete x;});
     auto failed=p.acquire(17,1);failed.reset();
     CHECK(p.stats().admittedUnits==17&&retired==0,"failed Layout lost its real work charge");
     p.clear();CHECK(retired==1,"failed Layout owner not drained");}
    puts("PASS pool retains the sealed generation until an explicit safe boundary");
    return 0;
}
'''
    return execute_case('owner-contract', code, mutation)


def run_dispatch(mutation=None):
    source = (HOST / 'ohos_renderer.cpp').read_text()
    methods = '\n'.join(block(source, marker) for marker in (
        '    bool postCaretBlink(', '    void consumeCaretBlinkWakeLocked(',
        '    bool replaySupersededByLaterQueuedReplayLocked(', '    void run()'))
    if mutation == 'omit-idle-font-wake':
        old=' || fontPool.hasRetirable()'
        assert methods.count(old)==1
        methods=methods.replace(old,'')
    elif mutation == 'retire-ahead-of-queued':
        old='            if (jobs.empty()) {'
        assert methods.count(old)==1
        methods=methods.replace(old,'            g.unlock();fontPool.retireOneUnused();g.lock();\n'+old)
    code = r'''
#include "cjgui_ohos_font_lease.h"
#include <atomic>
#include <condition_variable>
#include <cstring>
#include <deque>
#include <map>
#include <mutex>
#include <cstdio>
#define RLOGE(...) ((void)0)
#define RLOGW(...) ((void)0)
constexpr int CJGUI_INTERNAL_RENDERER_OK=0,CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE=15;
enum class JobKind {Measure,CaretHitTest,Present,Redraw,ImageRealize,Teardown,Shutdown};
std::atomic<uint64_t> sequence{0};
struct WaitableJob {
 JobKind kind;const char*observationReason;uint64_t observationId=++sequence,observationRenderEpoch=1;
 std::chrono::steady_clock::time_point observationEnqueued{},observationDequeued{};
 WaitableJob(JobKind k,const char*r):kind(k),observationReason(r){}virtual~WaitableJob()=default;
 bool cancelBeforeCommit(){return true;}void finish(int){}
};
using JobRef=std::shared_ptr<WaitableJob>;
struct PresentJob:WaitableJob{uint64_t session=1,ticketId=1,generation=1;};
struct RedrawJob:WaitableJob{std::shared_ptr<int>installedCoverage;bool caretBlinkWake=false;uint64_t renderEpoch=0;
 explicit RedrawJob(const char*r):WaitableJob(JobKind::Redraw,r){} };
WaitableJob*g_observedTextJob=nullptr;
struct {bool pruneReleasedIdle(){return false;}}g_images;
template<class...A>void cjguiOhosTestGateBeforeExecute(A&&...){}
void OH_Drawing_GpuContextDestroy(void*){}
int observedCoverageInput(int){return 0;}
struct Collection{int id;};using Pool=CjguiOhosFontPool<Collection>;
struct Render {
 std::mutex lock,eventLock;std::condition_variable cv,event;
 std::deque<JobRef>jobs;JobRef activeJob;std::thread::id renderThreadId;
 bool imagePruneRequested=false,running=true,stopping=false,caretBlinkRedrawQueued=false,hasLastFrame=false;
 bool entered=false,allowDestroy=false,destroyInsideJob=false,queryWrong=false;
 int created=0,draws=0;std::atomic<int>destroyed{0};size_t duringDestroyLive=0;
 std::vector<uint64_t>executed;
 uint64_t renderEpoch=1,mergedRedrawFrames=0,lastFrameSession=0,lastFrameTicket=0,lastProjectionVersion=0;
 int64_t lastFrameMirrorOwnerVersion=0;int lastFrameCoverage=0;
 std::atomic<uint64_t>queuedCaretQueries{0},busyGeneration{0};std::map<int,int>imageBitmaps;void*gpuContext=nullptr;
 Pool fontPool;Pool::Lease latest;
 Render():fontPool([this]{return new Collection{++created};},[this](Collection*p){
  if(p->id==1){std::unique_lock<std::mutex>g(eventLock);entered=true;
   destroyInsideJob=g_observedTextJob!=nullptr;duringDestroyLive=fontPool.liveGenerations();event.notify_all();
   event.wait(g,[&]{return allowDestroy;});}
  ++destroyed;delete p;
 }){}
 void post(const JobRef&j){
  {std::lock_guard<std::mutex>g(lock);j->observationEnqueued=std::chrono::steady_clock::now();jobs.push_back(j);
   if(j->kind==JobKind::CaretHitTest)++queuedCaretQueries;}
  cv.notify_all();
 }
 void execute(WaitableJob*j){
  if(j->kind==JobKind::Measure){auto old=fontPool.acquire(Pool::kWorkUnitsPerGeneration,1);
   latest=fontPool.acquire(1,1);old.reset();
   post(std::make_shared<WaitableJob>(JobKind::CaretHitTest,"already-queued"));
   postCaretBlink(1);postCaretBlink(1);
  }else if(j->kind==JobKind::CaretHitTest){
   const int expected=std::strcmp(j->observationReason,"already-queued")==0?0:1;
   if(destroyed!=expected)queryWrong=true;
  }else if(j->kind==JobKind::Redraw){++draws;}
 }
 void observeJob(const char*phase,const WaitableJob&j){
  if(std::strcmp(phase,"executed")==0){std::lock_guard<std::mutex>g(eventLock);executed.push_back(j.observationId);event.notify_all();}
 }
 void teardownSurface(){latest.reset();fontPool.clear();}
 void pruneImageBitmaps(){}void destroyImageBitmap(int&){}
 template<class...A>void observeResources(A&&...){}
@@METHODS@@
};
int main(){
 Render r;std::thread worker([&]{r.run();});
 r.post(std::make_shared<WaitableJob>(JobKind::Measure,"setup"));
 bool idle=false;
 {std::unique_lock<std::mutex>g(r.eventLock);idle=r.event.wait_for(g,std::chrono::seconds(2),[&]{return r.entered;});}
 r.post(std::make_shared<WaitableJob>(JobKind::CaretHitTest,"arrived-during-destroy"));
 r.postCaretBlink(1);r.postCaretBlink(1);
 size_t blinkJobs=0;
 {std::lock_guard<std::mutex>g(r.lock);for(const auto&j:r.jobs)blinkJobs+=j->kind==JobKind::Redraw;}
 {std::lock_guard<std::mutex>g(r.eventLock);r.allowDestroy=true;r.event.notify_all();}
 bool complete=false;
 {std::unique_lock<std::mutex>g(r.eventLock);complete=r.event.wait_for(g,std::chrono::seconds(2),[&]{return r.executed.size()>=5;});}
 r.post(std::make_shared<WaitableJob>(JobKind::Shutdown,"close"));worker.join();
 if(!idle){puts("FAIL actual run did not retire the unleased generation at its idle boundary");return 1;}
 if(r.destroyInsideJob||r.duringDestroyLive!=2){puts("FAIL retirement moved into a job or disappeared from live cap");return 2;}
 if(!complete||r.queryWrong||blinkJobs!=1||r.draws!=2||r.caretBlinkRedrawQueued||r.queuedCaretQueries){
  puts("FAIL queued work priority, FIFO or unique blink wake changed");return 3;}
 if(r.destroyed!=2||r.fontPool.liveGenerations()!=0){puts("FAIL real run shutdown retained a font owner");return 4;}
 puts("PASS actual run idle retirement; already-queued priority; input during slow Destroy; FIFO/unique blink; close");return 0;
}
'''.replace('@@METHODS@@', methods)
    return execute_case('real-dispatch-contract', code, mutation)


if __name__ == '__main__':
    status = run()
    if status:raise SystemExit(status)
    status=run_dispatch()
    if status:raise SystemExit(status)
    if '--selftest' in sys.argv:
        for mutation in ('release-sealed-owner','query-destroys','omit-retiring-count',
                         'omit-pressure-retirement','omit-external-lease-guard','omit-close-drain'):
            if run(mutation)==0:raise AssertionError('withdrawal unexpectedly passed: '+mutation)
        for mutation in ('omit-idle-font-wake','retire-ahead-of-queued'):
            if run_dispatch(mutation)==0:raise AssertionError('withdrawal unexpectedly passed: '+mutation)
