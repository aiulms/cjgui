#!/usr/bin/env python3
"""Count actual production diagnostic boundaries and reuse complete execute QA.

OS/allocator/logging are counted SDK substitutes. Dispatch, Measure, admission,
old Redraw, Present, Flush ownership and private lifetime come from production.
Separate processes test startup configuration; no mutable runtime trace switch.
"""
import argparse
import json
import os
import re
from pathlib import Path
import subprocess
import sys
import test_private_measure_transfer as base
from test_private_measure_interleaving_native import integrate
from test_presentation_typography_reuse import block


def augment(source, code, mutation):
    code = integrate(source, code)
    policy = (block(source, 'static const bool g_textDeepDiagnostics =') + ';\n' +
              block(source, 'static bool cjguiOhosDeepDiagnosticsEnabled()')
              if 'static const bool g_textDeepDiagnostics =' in source else
              'static bool cjguiOhosDeepDiagnosticsEnabled(){return true;}')
    # The production startup initializer is a lambda invocation, not its body.
    if 'static const bool g_textDeepDiagnostics =' in source:
        start = source.index('static const bool g_textDeepDiagnostics =')
        end = source.index('}();', start) + 5
        policy = source[start:end] + '\n' + block(source, 'static bool cjguiOhosDeepDiagnosticsEnabled()')
    work = block(source, 'static void cjguiOhosObserveTextWork(')
    resources = block(source, '    void observeResources(')
    job = block(source, '    void observeJob(')
    sdk = block(source, '    Measured layoutTextStyled(')
    phase_start=sdk.index('        auto phaseStarted=')
    phase_end=sdk.index('        const auto collectionStarted',phase_start)
    phases=sdk[phase_start:phase_end]
    found=re.search(r'^#define RLOGD[^\n]+',source,re.M)
    macro=found[0] if found else '#define RLOGD(...) RLOGI(__VA_ARGS__)'
    if mutation == 'omit-resource-entry-guard':
        guard = '        if (!cjguiOhosDeepDiagnosticsEnabled()) return;'
        assert guard in resources
        resources = resources.replace(guard, '', 1)
    elif mutation == 'omit-work-entry-guard':
        guard = '    if (!cjguiOhosDeepDiagnosticsEnabled()) return;'
        assert guard in work
        work = work.replace(guard, '', 1)
    elif mutation == 'omit-sdk-phase-guard':
        guard='            if (!deepDiagnostics) return;'
        assert guard in phases;phases=phases.replace(guard,'',1)
    elif mutation == 'omit-macro-argument-guard':
        assert 'cjguiOhosDeepDiagnosticsEnabled()' in macro
        macro='#define RLOGD(...) RLOGI(__VA_ARGS__)'
    code = code.replace('template<class...A>void cjguiOhosObserveTextWork(A&&...){}', '')
    code = code.replace('static bool cjguiOhosDeepDiagnosticsEnabled(){return false;}', '')
    code = code.replace('#include <functional>', '#include <functional>\n#include <cstring>\n#include <cstdio>\n#include <deque>\n#include <array>')
    code = code.replace('struct Session {', 'struct Node;\nstruct Session { bool candidateOpen=true;uint64_t inputOwnerCompleted=0;std::vector<Node>accepted,candidate;')
    code = code.replace('struct Node{Pod pod;', 'struct Node{std::string label="label",semanticId="node";Pod pod;')
    old_destroy='void cjguiOhosDestroyObservedTypography(OH_Drawing_Typography *p) {'
    assert old_destroy in code
    code = code.replace(old_destroy, 'static void cjguiOhosDestroyObservedTypography(OH_Drawing_Typography *);\nvoid OH_Drawing_DestroyTypography(OH_Drawing_Typography *p) {',1)
    if 'static bool cjguiOhosDeepDiagnosticsEnabled(){return false;}' in code:
        raise AssertionError('fixture fallback shadowed real startup policy')
    sampling = r'''
struct DiagnosticCounts{int procOpen=0,procRead=0,procClose=0,pageSize=0,allocator=0,payload=0,formats=0,cpu=0;};
static DiagnosticCounts diagnosticCounts;
static void diagnosticLog(const char*format,...){
 if(std::strstr(format,"text resources ")||std::strstr(format,"text resource identity ")||
    std::strstr(format,"text work ")||std::strstr(format,"render job ")||
    std::strstr(format,"text typography phase=destroy"))++diagnosticCounts.formats;
}
#undef RLOGI
#define RLOGI(...) diagnosticLog(__VA_ARGS__)
@@POLICY@@
#undef RLOGD
@@DEEP_MACRO@@
static thread_local const WaitableJob*g_observedTextJob=nullptr;
static std::atomic<uint64_t>g_textObservationSequence{0};
static int64_t cjguiOhosTextMonoUs(){return 1;}
static int64_t cjguiOhosTextThreadCpuUs(){++diagnosticCounts.cpu;return 1;}
#define getpid() 123
#define syscall(...) 9
#define SYS_gettid 0
@@WORK@@
@@RESOURCE_FACTS@@
static CjguiOhosTypographyResourceFacts g_typographyResources;
@@DESTROY@@
struct mallinfo2{size_t uordblks=100,fordblks=10,arena=0;};
static mallinfo2 countedAllocator(){++diagnosticCounts.allocator;return {};}
static void*countedDlsym(void*,const char*){return reinterpret_cast<void*>(&countedAllocator);}
static int countedOpen(const char*,int){++diagnosticCounts.procOpen;return 9;}
static int countedRead(int,void*buffer,size_t){++diagnosticCounts.procRead;std::strcpy(static_cast<char*>(buffer),"100 20");return 6;}
static int countedClose(int){++diagnosticCounts.procClose;return 0;}
static long countedSysconf(int){++diagnosticCounts.pageSize;return 4096;}
#define dlsym countedDlsym
#define open countedOpen
#define read countedRead
#define close countedClose
#define sysconf countedSysconf
#define RTLD_DEFAULT nullptr
#define O_RDONLY 0
#define O_CLOEXEC 0
#define _SC_PAGESIZE 0
#define getpid() 123
#define syscall(...) 9
#define SYS_gettid 0
struct Pending{bool valid=true;std::vector<Node>nodes;std::u16string ownedMirrorText;};
static Pending g_pending[1];
static int sessionSlotLocked(uint64_t session){return session==42?0:-1;}
static std::atomic<size_t>g_imageLiveBytes{0};
'''.replace('@@POLICY@@', policy).replace('@@WORK@@', work).replace('@@DEEP_MACRO@@',macro).replace(
        '@@RESOURCE_FACTS@@', block(source, 'struct CjguiOhosTypographyResourceFacts {')+';').replace(
        '@@DESTROY@@', block(source, 'static void cjguiOhosDestroyObservedTypography('))
    marker = 'using OH_Drawing_ErrorCode=int;'
    assert marker in code
    code = code.replace(marker, sampling + '\n' + marker, 1)
    methods = block(source, '    static size_t scenePayloadBytes(')
    methods = methods.replace('{', '{ ++diagnosticCounts.payload;', 1)
    methods += '\n' + block(source, '    static size_t jobPayloadBytes(')
    methods += '''
    void probeActualSdkPhaseClosure(){
        const bool deepDiagnostics=cjguiOhosDeepDiagnosticsEnabled(),traceApi=deepDiagnostics;
        const std::string text(4096,'A');uint64_t traceHash=1,layoutId=1;double constraintWidth=319;size_t runCount=0;
'''+phases+'''
        phase("production-short-phase-call");
    }
'''
    code = code.replace('template<class...A>void observeResources(A&&...){}', methods + '\n' + resources + '\n' + job)
    code = code.replace('struct Renderer{', 'struct Renderer{\nstd::mutex lock;std::deque<JobRef>jobs;JobRef activeJob;struct Bitmap{void*bitmap=nullptr;};std::map<int,Bitmap>imageBitmaps;void*gpuContext=nullptr;uint64_t textLayoutsBuilt=0,textLayoutInputBytes=0;', 1)
    observer=block(source, '        [](const char *phase,uint64_t id,uint64_t configuration,size_t workUnits)')
    pool='OhosFontPool fontPool{[]{return new FontCollection;},[](FontCollection*p){delete p;}};'
    assert pool in code
    code=code.replace(pool, pool[:-2]+','+observer+'};',1)
    needle='m.typography=p;m.height=20;'
    assert needle in code
    code=code.replace(needle,'m.typography=p;g_typographyResources.observeCreate(p,t.size(),p->id,m.fontLease->id);m.height=20;',1)
    # The original complete execute scenarios run in both modes after the short
    # sampler test. Thus resource/queue/format probes cannot hide semantic work.
    main = r'''
 const bool expectedOn=std::getenv("H_EXPECT_DEEP")&&std::strcmp(std::getenv("H_EXPECT_DEEP"),"1")==0;
 {Renderer sampled;MeasureJob m;configure(m,"ABC");
  sampled.activeJob=std::make_shared<MeasureJob>();sampled.jobs.push_back(std::make_shared<MeasureJob>());
  g_sessions.session.accepted={Node{}};g_sessions.session.candidate={Node{}};g_pending[0].nodes={Node{}};
  sampled.observeResources("short-production-call",42,1,1,1);
  cjguiOhosObserveTextWork("short-production-call",{});
  sampled.observeJob("short-production-call",m);
  sampled.probeActualSdkPhaseClosure();
  RLOGD("text work phase=argument-evaluation cpu=%lld",(long long)cjguiOhosTextThreadCpuUs());
  auto c=diagnosticCounts;
  printf("DIAGNOSTICS {\"proc\":%d,\"read\":%d,\"close\":%d,\"allocator\":%d,\"payload\":%d,\"formats\":%d,\"cpu\":%d}\n",
         c.procOpen,c.procRead,c.procClose,c.allocator,c.payload,c.formats,c.cpu);
  if(!expectedOn)CHECK(c.procOpen==0&&c.procRead==0&&c.procClose==0&&c.allocator==0&&
       c.payload==0&&c.formats==0&&c.cpu==0,"default-off still executed real deep sampling/formatting");
  else CHECK(c.procOpen>0&&c.procRead>0&&c.procClose>0&&c.allocator>0&&c.payload>0&&c.formats>0&&c.cpu>0,
       "explicit-on could not inspect actual production boundaries");
  // Configuration is frozen at module startup, not re-read per frame.
  setenv("CJGUI_OHOS_DEEP_DIAGNOSTICS",expectedOn?"0":"1",1);
  CHECK(cjguiOhosDeepDiagnosticsEnabled()==expectedOn,"startup policy mutated after initialization");
  g_sessions.session.accepted.clear();g_sessions.session.candidate.clear();g_pending[0].nodes.clear();}
'''
    code = code.replace('int main(){', 'int main(){\n' + main, 1)
    code = code.replace(' CHECK(layouts==destroyed,', ' CHECK(g_typographyResources.created==g_typographyResources.destroyed && g_typographyResources.inputBytesLive==0 && g_typographyResources.complete,"real low-cost Typography facts stopped updating");\n CHECK(layouts==destroyed,',1)
    code = code.replace(' puts("PASS actual execute Measure', ' printf("SEMANTIC %d %d %d %d\\n",layouts,destroyed,colorUpdates,flushes);\n puts("PASS actual execute Measure', 1)
    return code


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mutation',choices=['omit-resource-entry-guard','omit-work-entry-guard','omit-sdk-phase-guard','omit-macro-argument-guard'])
    parser.add_argument('--one',action='store_true')
    args=parser.parse_args()
    if args.one:
        sys.exit(base.run(code_transform=lambda source, code: augment(source, code, args.mutation)))
    root=Path(os.environ['CJGUI_H_NATIVE_TEST_ARTIFACTS']);rows=[]
    for mode,value in [('off',None),('on','1'),('invalid','true')]:
        env=os.environ.copy();env.pop('CJGUI_OHOS_DEEP_DIAGNOSTICS',None)
        if value is not None:env['CJGUI_OHOS_DEEP_DIAGNOSTICS']=value
        env['H_EXPECT_DEEP']='1' if mode=='on' else '0';env['CJGUI_H_NATIVE_TEST_ARTIFACTS']=str(root/mode)
        child=subprocess.run([sys.executable,__file__,'--one',*(['--mutation',args.mutation]if args.mutation else [])],env=env,capture_output=True,text=True)
        print(mode,child.returncode,child.stdout,child.stderr)
        rows.append(dict(mode=mode,exit=child.returncode,stdout=child.stdout,stderr=child.stderr))
        if child.returncode:break
    root.mkdir(parents=True,exist_ok=True);(root/'modes.json').write_text(json.dumps(rows,indent=2)+'\n')
    if any(x['exit']for x in rows):sys.exit(1)
    semantic=[next(l for l in x['stdout'].splitlines()if l.startswith('SEMANTIC '))for x in rows]
    assert len(set(semantic))==1,semantic
    print('PASS frozen off/on/invalid; actual deep boundaries and identical complete execute semantics')
