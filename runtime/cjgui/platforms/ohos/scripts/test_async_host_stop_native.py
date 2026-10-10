#!/usr/bin/env python3
"""Run actual appShutdown/stop monitor/async work against a pumping UI NAPI double.

Platform callbacks supply observable counters; no host success conditions are modeled.
The production 10s deadline is reduced to 120ms only in this compiled fixture.
"""
from pathlib import Path
import argparse,subprocess,tempfile
import test_presentation_budget_real_frame_native as extract
SOURCE=Path(__file__).resolve().parents[1]/'host/cjgui_host_bridge.cpp'

def build(source):
 s=source.read_text();fn=lambda key:extract.extract_function(s,key)
 globals_=''
 helpers=''
 if 'struct HostStopObservation' in s:
  begin=s.index('struct HostStopObservation');end=s.index('// 「是否已启动」',begin)
  globals_=s[begin:end].replace('std::chrono::seconds(10)','std::chrono::milliseconds(120)')
  begin=s.index('struct ShutdownAwait');end=s.index('static napi_value AppShutdown',begin)
  helpers=s[begin:end]
 monitor=extract.extract_function(s[s.rfind('static void startStopMonitorOnce(uint64_t stopAppInstance)'):],'static void startStopMonitorOnce')
 code=r'''
#include <atomic>
#include <cassert>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <map>
#include <mutex>
#include <string>
#include <thread>
#include <vector>
#define HLOGI(...) ((void)0)
#define HLOGW(...) ((void)0)
using napi_env=void*;using napi_callback_info=void*;
enum napi_status{napi_ok,napi_cancelled,napi_generic_failure};
struct Value{int state=0;std::string text;};using napi_value=Value*;using napi_ref=Value*;using napi_deferred=Value*;
constexpr size_t NAPI_AUTO_LENGTH=-1;
struct Work{void(*execute)(napi_env,void*);void(*complete)(napi_env,napi_status,void*);void*data;};using napi_async_work=Work*;
std::mutex queueLock;std::deque<Work*>uiQueue;std::vector<std::thread>workers;
std::map<void*,void(*)(void*)>cleanup;
napi_env ENV=(void*)1;
napi_status napi_create_promise(napi_env,napi_deferred*d,napi_value*p){*p=*d=new Value;return napi_ok;}
napi_status napi_create_string_utf8(napi_env,const char*s,size_t,napi_value*v){*v=new Value{0,s};return napi_ok;}
napi_status napi_create_reference(napi_env,napi_value v,uint32_t,napi_ref*r){*r=v;return napi_ok;}
napi_status napi_get_reference_value(napi_env,napi_ref r,napi_value*v){*v=r;return napi_ok;}
napi_status napi_delete_reference(napi_env,napi_ref){return napi_ok;}
napi_status napi_add_env_cleanup_hook(napi_env,void(*f)(void*),void*d){cleanup[d]=f;return napi_ok;}
napi_status napi_remove_env_cleanup_hook(napi_env,void(*)(void*),void*d){cleanup.erase(d);return napi_ok;}
napi_status napi_create_async_work(napi_env,napi_value,napi_value,void(*e)(napi_env,void*),void(*c)(napi_env,napi_status,void*),void*d,napi_async_work*w){*w=new Work{e,c,d};return napi_ok;}
napi_status napi_queue_async_work(napi_env env,napi_async_work w){workers.emplace_back([env,w]{w->execute(env,w->data);std::lock_guard<std::mutex>l(queueLock);uiQueue.push_back(w);});return napi_ok;}
napi_status napi_cancel_async_work(napi_env,napi_async_work){return napi_generic_failure;}
napi_status napi_delete_async_work(napi_env,napi_async_work w){delete w;return napi_ok;}
napi_status napi_get_undefined(napi_env,napi_value*v){*v=nullptr;return napi_ok;}
napi_status napi_create_error(napi_env,napi_value,napi_value msg,napi_value*e){*e=msg;return napi_ok;}
napi_status napi_resolve_deferred(napi_env,napi_deferred d,napi_value){d->state=1;return napi_ok;}
napi_status napi_reject_deferred(napi_env,napi_deferred d,napi_value e){d->state=2;d->text=e?e->text:"error";return napi_ok;}
napi_status napi_throw_error(napi_env,const char*,const char*){return napi_ok;}
enum HostPhase{kHostIdle,kHostStarting,kHostRunning,kHostStopping,kHostStopped,kHostFailed};
std::atomic<int>g_hostPhase{kHostRunning},g_foreground{1};std::atomic<uint64_t>g_appInstance{1};
std::atomic<bool>g_stopRequested{false},g_ownerReady{true},g_ownerExited{true};
std::mutex g_hostTransitionMutex;uint64_t g_ownerOutcomeInstance=1;int32_t g_ownerOutcome=0;
int stopRequests=0;std::atomic<int>active{1},refs{1},pendingCount{0},occupiedCount{0},renderer{1};
std::thread::id uiThread=std::this_thread::get_id();
bool ownerThreadJoinedForInstance(uint64_t id){assert(std::this_thread::get_id()!=uiThread&&"real join must never run in UI callback");return id==g_appInstance&&g_ownerExited;}
int64_t surfaceAccountingForInstance(uint64_t,int32_t*a){*a=active;return refs;}
int32_t retireAllSurfacesOfInstance(){return active;}
int requestStop(){++stopRequests;return 1;}int32_t(*requestAppStopFn)()=requestStop;
int shutdownDone(){return renderer;}int32_t(*shutdownDoneFn)()=shutdownDone;
void readout(int32_t*o,int64_t*u,int64_t*p){*o=occupiedCount;*u=0;*p=pendingCount;}
void(*g_settlementReadoutFn)(int32_t*,int64_t*,int64_t*)=readout;
const char*hostPhaseName(int){return "phase";}bool hostStarted(){return g_hostPhase==kHostRunning;}
%GLOBALS%
%MONITOR%
%REQUEST%
%HELPERS%
%SHUTDOWN%
void pump(){Work*w=nullptr;{std::lock_guard<std::mutex>l(queueLock);if(!uiQueue.empty()){w=uiQueue.front();uiQueue.pop_front();}}if(w)w->complete(ENV,napi_ok,w->data);}
void await(Value*p){auto end=std::chrono::steady_clock::now()+std::chrono::milliseconds(500);while(p->state==0&&std::chrono::steady_clock::now()<end){pump();std::this_thread::sleep_for(std::chrono::milliseconds(1));}assert(p->state!=0);}
void newInstance(uint64_t id){std::lock_guard<std::mutex>l(g_hostTransitionMutex);g_appInstance=id;g_ownerOutcomeInstance=id;g_ownerOutcome=0;g_hostPhase=kHostRunning;g_ownerExited=true;g_ownerReady=true;active=refs=1;pendingCount=occupiedCount=0;renderer=1;%RESET%}
int main(){
 auto before=std::chrono::steady_clock::now();auto*p=AppShutdown(ENV,nullptr);
 assert(p&&"appShutdown must return a bounded Promise to UIAbility");
 assert(std::chrono::steady_clock::now()-before<std::chrono::milliseconds(30));
 assert(AppShutdown(ENV,nullptr)==p&&stopRequests==1);
 // Simulated UI surface-return callback can run while native work awaits it.
 std::this_thread::sleep_for(std::chrono::milliseconds(15));pump();assert(p->state==0);
 active=refs=0;await(p);assert(p->state==1&&g_hostPhase==kHostStopped);
 assert(AppShutdown(ENV,nullptr)==p&&stopRequests==1);
 newInstance(2);auto*timeout=AppShutdown(ENV,nullptr);refs=1;active=0;await(timeout);
 assert(timeout->state==2&&timeout->text=="host_stop_timeout"&&g_hostPhase==kHostStopping);
 for(int counter=0;counter<5;++counter){
  newInstance(20+counter);active=refs=0;
  if(counter==0)occupiedCount=1;if(counter==1)pendingCount=1;if(counter==2)active=1;
  if(counter==3)renderer=0;if(counter==4)g_ownerExited=false;
  auto*q=AppShutdown(ENV,nullptr);await(q);
  assert(q->state==2&&g_hostPhase==kHostStopping&&"each actual nonzero or unreturned participant prevents success");
 }
 newInstance(30);active=refs=0;renderer=0;g_ownerReady=false;
 auto*notStarted=AppShutdown(ENV,nullptr);await(notStarted);assert(notStarted->state==1);
 newInstance(31);active=refs=0;g_hostPhase=kHostStopping;int sent=stopRequests;
 auto*adopted=AppShutdown(ENV,nullptr);await(adopted);assert(adopted->state==1&&stopRequests==sent);
 newInstance(3);auto*failed=AppShutdown(ENV,nullptr);{std::lock_guard<std::mutex>l(g_hostTransitionMutex);g_hostPhase=kHostFailed;g_ownerOutcome=1;}await(failed);assert(failed->state==2);
 newInstance(4);auto*stale=AppShutdown(ENV,nullptr);newInstance(5);await(stale);assert(stale->state==2&&stale->text=="host_stop_instance_changed");
 auto*invalid=AppShutdown(ENV,nullptr);for(auto it=cleanup.begin();it!=cleanup.end();){auto f=it->second;auto d=it->first;++it;f(d);}
 auto end=std::chrono::steady_clock::now()+std::chrono::milliseconds(200);while(std::chrono::steady_clock::now()<end){pump();std::this_thread::sleep_for(std::chrono::milliseconds(1));}
 assert(invalid->state==0&&"invalid environment must receive no callback");
 for(auto&t:workers)t.join();
 puts("PASS actual host Promise/monitor: UI free, duplicate stop shared, full zero only, failed/timeout/stale/env invalid named");
}
'''
 reset='g_stopObservation = {};g_stopCv.notify_all();' if globals_ else ''
 for k,v in {'GLOBALS':globals_,'MONITOR':monitor,'REQUEST':fn('static void requestHostStopOnce('),'HELPERS':helpers,'SHUTDOWN':fn('static napi_value AppShutdown('),'RESET':reset}.items():code=code.replace('%'+k+'%',v)
 return code

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,default=SOURCE);args=ap.parse_args()
 with tempfile.TemporaryDirectory(prefix='h-stop-promise-')as tmp:
  p=Path(tmp);(p/'main.cpp').write_text(build(args.source))
  subprocess.run(['clang++','-std=c++17','-pthread',str(p/'main.cpp'),'-o',str(p/'main')],check=True)
  raise SystemExit(subprocess.run([str(p/'main')]).returncode)
