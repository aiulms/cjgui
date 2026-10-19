// Actual registry/lifecycle, controlled SDK getter/attach and native boundary.
// Actual native receiver/service is verified separately; no SDK or owner claim here.
const{test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const{stripTypeScriptTypes}=require('node:module');
const source=fs.readFileSync(process.env.PROXY_SRC||path.join(__dirname,'../arkts/cjgui-text-proxy.ets'),'utf8');
async function fixture(start=1,end=start,autoArm=true){
 let activeSource=autoArm?3:0,nativeFocus=1;const prepared=[],attachResolvers=[];
 let now=0,serial=0,current=null,attachResolve;const timers=[],received=[],phases=[],sets=[],will=[];
 const env={FrameCallback:class{},TextDeleteDirection:{BACKWARD:0,FORWARD:1},setTimeout(fn,ms){const id=++serial;timers.push({id,due:now+(ms||0),fn});return id;},clearTimeout(id){const i=timers.findIndex(t=>t.id===id);if(i>=0)timers.splice(i,1);}};
 vm.createContext(env);vm.runInContext(stripTypeScriptTypes(source.replace(/^import .*;\s*$/gm,''),{mode:'transform'}).replace(/export /g,'')+';globalThis.A={Registry:CjguiTextProxyRegistry,LC:CjguiImeSelectionLifecycle};',env);
 let selection={start:0,end:0};const bridge={focusAuthority(){return String(nativeFocus);},logInfo(){},logWarn(){},inputWill(...a){will.push(a);return '1';},originalInsert(m,c){received.push(c);return ''+received.length;},originalInsertStatus(){return '1';},originalInsertCancel(){return '0';}};
 const registry=new env.A.Registry(bridge);current=registry.mount(10,1,'proxy','body',7,1,'A中👩‍💻');current.publication=null;current.previewKnown=true;
 const host={currentMount(){return current;},isCurrentMount(m){return m===current&&registry.isCurrent(m);},monotonicNowMs(){return now;},logInfo(){},logWarn(){},restoreTaskActive(){return false;},attachSession(){return new Promise(resolve=>{attachResolve=resolve;attachResolvers.push(resolve);});},hasImeTrafficEvidence(){return false;},readSelection(){return selection;},setSelection(a,b){sets.push([a,b]);selection={start:a,end:b};},commitInstalled(){throw Error('linked ordinary installation must confirm its original source, not create another selection');},pendingOrdinarySelection(){return activeSource>0?`${activeSource},${start},${end},8000`:"";},prepareOrdinarySelection(m,s,install){prepared.push(s.id);return s.id===activeSource?`${activeSource},${start},${end},8000`:'';},observeOrdinarySelection(e,phase,a,b,attach){phases.push({phase,a,b,sequence:e.sequence,attach});return '0';}};
 const lc=new env.A.LC(host);if(autoArm)lc.arm(current,start,end,'caret',{kind:1,id:3,deadline:8000});lc.requestAttach(current,'focus');
 async function advance(ms){const stop=now+ms;for(let i=0;i<500;i++){for(let n=0;n<8;n++)await Promise.resolve();timers.sort((a,b)=>a.due-b.due);const t=timers[0];if(!t||t.due>stop){now=stop;return;}timers.shift();now=t.due;t.fn();}throw Error('unbounded lifecycle');}
 return{registry,lc,m:current,received,phases,sets,will,advance,prepared,setNativeSource(id){activeSource=id;},setNativeFocus(id){nativeFocus=id;},attachCalls(){return attachResolvers.length;},attach(index){(index===undefined?attachResolve:attachResolvers[index])();}};
}
test('actual first J is retained once with original SDK offset0 while click1 installation is pending',async()=>{
 const f=await fixture();assert.equal(f.registry.onWillInsert(f.m,{insertValue:'J',insertOffset:0}),false,'cancel the original SDK default rather than write J@0');
 assert.equal(f.received.length,1,'reject-only loses the original first J');assert.equal(f.received[0].offset,0,'the SDK offset is evidence, never corrected to1');assert.equal(f.received[0].text,'J');
 assert.equal(f.received[0].execution.sourceKind,1,'not a fabricated physical Ctrl+A');assert.equal(f.will.length,0);assert.equal(f.sets.length,0);assert(!f.received[0].execution.installed);
 f.attach();await f.advance(100);assert.deepEqual(f.sets,[[1,1]]);assert.deepEqual(f.phases.map(x=>x.phase),[3,0,1]);assert(f.received[0].execution.installed);assert.equal(f.received.length,1,'installation never replays Will/Change or keyboard');
});
test('ordinary nonempty replacement retains the same original target and raw callback',async()=>{
 const f=await fixture(1,2);assert.equal(f.registry.onWillInsert(f.m,{insertValue:'J',insertOffset:0}),false);assert.equal(f.received.length,1);
 f.attach();await f.advance(100);assert.deepEqual(f.sets,[[1,2]]);assert.equal(f.received[0].execution.start,1);assert.equal(f.received[0].execution.end,2);assert.equal(f.received[0].offset,0);
});
test('the same original deadline terminates a never-attached choice and never installs late',async()=>{
 const f=await fixture();assert.equal(f.registry.onWillInsert(f.m,{insertValue:'J',insertOffset:0}),false);await f.advance(8001);f.attach();await f.advance(100);assert.equal(f.sets.length,0);assert(f.phases.some(x=>x.phase===2));
});
function method(s,tag){const at=s.indexOf(tag);assert(at>=0,tag);let n=0;for(let i=s.indexOf('{',at);i<s.length;i++){if(s[i]==='{')n++;if(s[i]==='}'&&--n===0)return s.slice(at,i+1);}throw Error(tag);}
for(const [name,file] of [
 ['thermo',path.resolve(__dirname,'../../../../../labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets')],
 ['pharos','/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets']]){
 test('actual '+name+' host/bridge transport original source1 without stale mount-selection substitution',()=>{
  const src=fs.readFileSync(file,'utf8'),calls=[],observed=[];
  const entryNapi={imeOrdinarySelectionPrepare(...a){calls.push(['prepare',a]);return '11,1,1,8000';},imeOrdinarySelectionObserve(...a){calls.push(['observe',a]);return '0';},imeOriginalInsert(...a){calls.push(['insert',a]);return '1';},imeOriginalInsertExit(...a){calls.push(['exit',a]);return '0';}};
  const code=source.replace(/^import .*;\s*$/gm,'')+'\nclass Host { page: Object; constructor(page:Object){this.page=page;}\n'+
   method(src,'  prepareOrdinarySelection(')+'\n'+method(src,'  observeOrdinarySelection(')+'\n}\nclass Bridge {\n'+method(src,'  originalInsert(')+'\n'+method(src,'  originalInsertExit(')+'\n}\n'+
   'globalThis.A={Host,Bridge,Key:CjguiProxyKey,Mount:CjguiTextProxyMount,Execution:CjguiOrdinarySelectionExecution,Command:CjguiOriginalInsertCommand};';
  const env={entryNapi,FrameCallback:class{}};vm.createContext(env);vm.runInContext(stripTypeScriptTypes(code,{mode:'transform'}).replace(/export /g,''),env);
  const A=env.A,m=new A.Mount(new A.Key(7,8,10,2,3),'p','body','A中👩‍💻');m.focusGeneration=6;
  m.selectionStart=0;m.selectionEnd=0;const origin={kind:1,id:9,deadline:8000};
  const page={proxyRegistry:{observeSelection(m,a,b){observed.push([a,b]);}}};const h=new A.Host(page);
  assert.equal(h.prepareOrdinarySelection(m,origin,4,1,1),'11,1,1,8000');
  assert.deepEqual(calls[0],['prepare',['A中👩‍💻',1,1,7,8,10,2,3,6,9,4,8000]]);
  const e=new A.Execution(m,origin,11,4,1,1),b=new A.Bridge();
  assert.equal(b.originalInsert(m,new A.Command(1,{insertValue:'J',insertOffset:0},e)),'1');
  assert.deepEqual(calls[1],['insert',['J',0,7,8,10,2,3,6,9,11,1]]);
  assert.equal(h.observeOrdinarySelection(e,1,1,1,5),'0');
  assert.deepEqual(calls[2],['observe',[7,8,10,2,3,6,9,11,1,1,1,5]]);assert.deepEqual(observed,[[1,1]]);
  assert.equal(b.originalInsertExit(m,e,{originalResult:13,request:14}),'0');
  assert.deepEqual(calls[3],['exit',[7,8,10,2,3,6,9,11,13,14]]);
 });
}

test('actual Will joins the existing native pending source before asynchronous typed notification',async()=>{
 const f=await fixture(1,1,false);
 f.lc.arm(f.m,1,1,'caret'); // early coordinate-only message
 assert.equal(f.m.ordinaryExecution,null);f.setNativeSource(3);
 assert.equal(f.registry.onWillInsert(f.m,{insertValue:'J',insertOffset:0},f.lc),false,'same original callback must be held, not default SDK0');
 assert.equal(f.received.length,1);assert.equal(f.received[0].offset,0);assert.equal(f.received[0].execution.sourceId,3);
 assert.equal(f.sets.length,0);f.attach();await f.advance(100);assert.deepEqual(f.sets,[[1,1]]);
 assert.equal(f.received.length,1);assert(f.received[0].execution.installed);
});
test('same range Q2 is new; late Q1 and untyped old caret cannot retire Q2',async()=>{
 const f=await fixture();const q1=f.m.ordinaryExecution;f.setNativeSource(4);
 f.lc.arm(f.m,1,1,'caret',{kind:1,id:4,deadline:8000});const q2=f.m.ordinaryExecution;
 assert.notEqual(q1,q2);assert.equal(q2.sourceId,4);
 const seq=f.lc.currentSeq();f.lc.arm(f.m,1,1,'caret',{kind:1,id:3,deadline:8000});
 assert.equal(f.m.ordinaryExecution,q2,'invalid old source cannot clear current execution before prepare');
 f.lc.arm(f.m,0,0,'caret');assert.equal(f.m.ordinaryExecution,q2,'source-less stale coordinates cannot clear typed Q2');
 assert.equal(f.lc.currentSeq(),seq);
 f.lc.arm(f.m,1,1,'caret',{kind:1,id:4,deadline:8001});assert.equal(f.m.ordinaryExecution,q2);assert.equal(f.lc.currentSeq(),seq);
 f.lc.arm(f.m,1,1,'caret',{kind:1,id:4,deadline:8000});assert.equal(f.m.ordinaryExecution,q2);assert.equal(f.lc.currentSeq(),seq);
 f.attach();await f.advance(100);assert.deepEqual(f.sets,[[1,1]]);
});

// Real native notification/source/prepare/receiver functions, persistent process.
// Only system attach, controller getters/setter and scheduling are substituted.
async function actualNativeFixture(){
 const cp=require('node:child_process'),os=require('node:os');
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'h-source-notify-')),input=path.join(dir,'in'),output=path.join(dir,'out');
 cp.execFileSync('mkfifo',[input,output]);
 const exe=process.env.NATIVE_CLICK_BIN;
 assert(exe,'NATIVE_CLICK_BIN must identify the current production-extracted native unit');
 const proc=cp.spawn(exe,['notification-rpc',input,output],{stdio:['ignore','ignore','inherit']});
 const w=fs.openSync(input,'w'),r=fs.openSync(output,'r');let now=100,serial=0,attached,selection={start:0,end:0};const timers=[],sets=[],received=[];
 function rpc(line){fs.writeSync(w,line+'\n');let answer='';const byte=Buffer.alloc(1);while(fs.readSync(r,byte,0,1,null)){if(byte[0]===10)return answer;answer+=byte.toString();}throw Error('native original process closed before response: '+line);}
 const env={FrameCallback:class{},TextDeleteDirection:{BACKWARD:0,FORWARD:1},setTimeout(fn,ms){const id=++serial;timers.push({id,due:now+(ms||0),fn});return id;},clearTimeout(id){const i=timers.findIndex(t=>t.id===id);if(i>=0)timers.splice(i,1);}};
 vm.createContext(env);vm.runInContext(stripTypeScriptTypes(source.replace(/^import .*;\s*$/gm,''),{mode:'transform'}).replace(/export /g,'')+';globalThis.A={Registry:CjguiTextProxyRegistry,LC:CjguiImeSelectionLifecycle};',env);
 const bridge={focusAuthority(){return '1';},logInfo(){},logWarn(){},originalInsert(m,c){received.push(c);return rpc('receive '+c.callback);},originalInsertStatus(){return '1';},originalInsertCancel(){return '0';}};
 const registry=new env.A.Registry(bridge),m=registry.mount(10,3,'proxy','body',7,1,'A中👩‍💻');m.publication=null;m.previewKnown=true;
 const host={pendingOrdinarySelection(){return rpc('source');},prepareOrdinarySelection(m,s,install,a,b){return rpc(`prepare ${s.id} ${install} ${a} ${b} ${s.deadline}`);},observeOrdinarySelection(e,p,a,b,attach){return rpc(`observe ${p} ${a} ${b} ${attach}`);},currentMount(){return m;},isCurrentMount(x){return x===m&&registry.isCurrent(x);},monotonicNowMs(){return now;},logInfo(){},logWarn(){},restoreTaskActive(){return false;},attachSession(){return new Promise(resolve=>attached=resolve);},hasImeTrafficEvidence(){return false;},readSelection(){return selection;},setSelection(a,b){sets.push([a,b]);selection={start:a,end:b};},commitInstalled(){throw Error('no unrelated selection command');}};
 const lc=new env.A.LC(host);lc.arm(m,1,1,'caret');lc.requestAttach(m,'focus');assert.equal(m.ordinaryExecution,null,'no owner-confirmed source exists yet');
 async function advance(ms){const end=now+ms;for(let i=0;i<500;i++){for(let n=0;n<8;n++)await Promise.resolve();timers.sort((a,b)=>a.due-b.due);const t=timers[0];if(!t||t.due>end){now=end;rpc('clock '+now);return;}timers.shift();now=t.due;rpc('clock '+now);t.fn();}throw Error('unbounded callback progression');}
 return{rpc,registry,lc,m,sets,received,advance,attach(){attached();},async close(){try{rpc('quit');}finally{fs.closeSync(w);fs.closeSync(r);proc.kill();fs.rmSync(dir,{recursive:true});}}};
}
for(const beforeNotice of [false,true])test('actual native + shared lifecycle + receiver: '+(beforeNotice?'Will before typed notice':'early coordinates then late same-range owner source'),{skip:!process.env.NATIVE_CLICK_BIN},async()=>{
 const f=await actualNativeFixture();
 try{
  assert.equal(f.rpc('source'),'','unaccepted owner choice confers no source');assert.equal(f.rpc('accept'),'0');
  if(!beforeNotice){const payload=JSON.parse(f.rpc('notice'));assert.equal(payload.selStart,1);assert.equal(payload.selectionSource.kind,1);f.lc.arm(f.m,payload.selStart,payload.selEnd,'caret',payload.selectionSource);}
  assert.equal(f.registry.onWillInsert(f.m,{insertValue:'J',insertOffset:0},f.lc),false);
  assert.equal(f.received.length,1);assert.equal(f.received[0].offset,0);assert.equal(f.rpc('stats'),'1,0,0,0','original retained once, zero owner events before actual install');
  f.attach();await f.advance(100);assert.deepEqual(f.sets,[[1,1]]);assert.equal(f.rpc('stats'),'1,1,1,0','one real kind66 event; immutable original remains held until actual owner begin');
  assert.equal(f.received.length,1);assert.equal(f.m.ordinaryExecution.installed,true);
 }finally{await f.close();}
});

// Execute both real same-identity branches: an already-focused TextInput does
// not emit another onFocus when native advances the same mount's generation.
for(const [name,file] of [
 ['thermo',path.resolve(__dirname,'../../../../../labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets')],
 ['pharos','/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets']]) {
 for(const oldInFlight of [false,true]) test(name+' same mount native focus wakes shared preparation; old '+(oldInFlight?'pending':'attached'),async()=>{
  const src=fs.readFileSync(file,'utf8');
  const branch=method(src,'    if (oldMount !== null && this.sameEditIdentity(oldMount, snap, appInstance))');
  const env={};vm.createContext(env);
  vm.runInContext(stripTypeScriptTypes('class Consumer { focus(snap) { const oldMount=this.imeMount; const appInstance=7;'+branch+'} } globalThis.Consumer=Consumer;',{mode:'transform'}),env);
  const f=await fixture(1,1,false),p=new env.Consumer();
  Object.assign(p,{imeMount:f.m,proxyRegistry:f.registry,selectionLifecycle:f.lc,sameEditIdentity(){return true;}});
  assert.equal(f.attachCalls(),1);if(!oldInFlight){f.attach(0);await f.advance(1);assert(f.lc.isAttachedTo(f.m));}
  f.setNativeFocus(2);f.setNativeSource(3);p.focus({focusGeneration:2});
  assert.equal(f.m.focusGeneration,2);assert.equal(f.attachCalls(),2,'accepted new focus must wake existing lifecycle, not wait for another component onFocus');
  assert.equal(f.registry.onWillInsert(f.m,{insertValue:'J',insertOffset:0},f.lc),false);
  assert.equal(f.received.length,1);assert.equal(f.received[0].offset,0);assert.equal(f.received[0].execution.focus,2);
  const execution=f.m.ordinaryExecution,seq=f.lc.currentSeq();
  p.focus({focusGeneration:2});p.focus({focusGeneration:3});
  assert.equal(f.attachCalls(),2,'duplicate accepted focus joins original budget; rejected snapshot does not start attach');
  assert.equal(f.lc.currentSeq(),seq);assert.equal(f.m.ordinaryExecution,execution);
  if(oldInFlight){f.attach(0);await f.advance(1);assert(!f.lc.isAttachedTo(f.m),'old focus1 promise cannot grant focus2');assert.equal(f.sets.length,0);}
  f.attach(1);await f.advance(100);
  assert(f.lc.isAttachedTo(f.m));assert.deepEqual(f.sets,[[1,1]]);assert(execution.installed);assert.equal(f.received.length,1);
 });
}
