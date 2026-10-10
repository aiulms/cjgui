// Production common executor + both actual consumer hosts/reconcile/mount callbacks.
// ArkUI/controller/native/clock are controlled seams. Not device or latency evidence.
const fs=require('node:fs'),vm=require('node:vm'),mod=require('node:module'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'../../../../..');
const proxyPath=process.env.PROXY_SRC||path.join(__dirname,'../arkts/cjgui-text-proxy.ets');
const proxy=fs.readFileSync(proxyPath,'utf8');
const sources={[proxyPath]:crypto.createHash('sha256').update(proxy).digest('hex')};
const consumers=[['pharos','/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets','PharosImeSelectionHost'],['thermo',root+'/labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets','ThermoImeSelectionHost']];
function extract(src,marker){const start=src.indexOf(marker);assert(start>=0,marker);let d=0;for(let i=src.indexOf('{',start);i<src.length;i++){if(src[i]==='{')d++;if(src[i]==='}'&&--d===0)return src.slice(start,i+1);}throw Error(marker);}
function code(filename,host){const src=fs.readFileSync(filename,'utf8');sources[filename]=crypto.createHash('sha256').update(src).digest('hex');const methods=['onProxyRestore','onProxyTextChange','onProxySelectionChange','onReconcileRequest','onProxyDisappeared','mountEditingSnapshot','sameEditIdentity','readHostAppInstance','readLiveEditingSnapshot','recordProxyFinish','sameDisplayedMount'];
 const body=methods.map(m=>{const match=src.match(new RegExp('^[ \\t]*(?:(?:private|public)[ \\t]+|/\\* package \\*/[ \\t]+)?'+m+'\\(','m'));assert(match,m);return extract(src,match[0]);});
 const joined=proxy+'\n'+extract(src,'class '+host+' ')+'\nclass TestPage {\n'+body.join('\n')+'\n}\nglobalThis.API={Page:TestPage,Host:'+host+',Registry:CjguiTextProxyRegistry,LC:CjguiImeSelectionLifecycle,Ticket:CjguiImeRestoreTicket};';
 return mod.stripTypeScriptTypes(joined.replace(/^import .*;\s*$/gm,''),{mode:'transform'}).replace(/export /g,'');}
async function run(name,compiled,cfg){let now=0,id=0,timers=[],page,selection={start:0,end:0},live=true;const sets=[],acks=[],commits=[],events=[];const target='A'.repeat(12285),original=cfg.needsText?'OLD':target;
 let snap={context:12,generation:1,focusGeneration:1,appInstance:27,sessionToken:1,nodeId:107,resourceId:cfg.resource??2,nodeKind:6,bindingEpoch:81,baseVersion:5,restoreRequest:29,restoreDeadlineMonoMs:cfg.deadline??1500,restoreProjectionVersion:5,restoreBindingEpoch:81,field:'body',text:target,selStart:214,selEnd:214,geometryUnit:'vp',proxyX:0,proxyY:0,proxyWidth:100,proxyHeight:50,x:0,y:0,width:100,height:50,fontSize:16,density:1};
 const env={FrameCallback:class{},DOMAIN:0,TAG:'controlled',MenuPolicy:{HIDE:0},
 setTimeout(fn,ms){const n=++id;timers.push({id:n,due:now+(ms||0),fn});return n;},clearTimeout(n){timers=timers.filter(t=>t.id!==n);},
 systemDateTime:{TimeType:{ACTIVE:0},getUptime(){return now;}},
 hilog:Object.fromEntries(['info','warn','error'].map(k=>[k,(...args)=>events.push({ms:now,type:k,format:args[2],args:args.slice(3)})])),
 inputMethod:{getController:()=>({showTextInput:()=>new Promise(resolve=>{events.push({ms:now,type:'attach-request',mount:page.imeMount.key.describe()});if(cfg.never)return;env.setTimeout(()=>{events.push({ms:now,type:'attach-complete'});resolve();},Math.max(0,(cfg.attachAt??0)-now));})})},
 entryNapi:{hostState:()=> 'appInstance=27 state=running',imeEditingContext:()=>live?JSON.stringify(snap):'',
 imeSetSelection(s,e,ctx){commits.push({ms:now,s,e,ctx});return '0';},imeRestoreAck(ctx,req,s,e,ok){const rc=cfg.ackReject?'1':(ctx===snap.context&&req===snap.restoreRequest?'0':'1');acks.push({ms:now,ctx,req,s,e,ok:!!ok,rc});return rc;}}};
 class Controller{caretPosition(n){this.setTextSelection(n,n);}setTextSelection(s,e){const attached=page.selectionLifecycle.isAttachedTo(page.imeMount);sets.push({ms:now,s,e,attached,bodyRendered:events.some(e=>e.type==='body-rendered'),key:page.imeMount.key.describe()});if(!attached&&cfg.unboundThrows)throw Error('unbound');if(attached)selection={start:s,end:e};}getSelection(){if(cfg.getterThrows)throw Error('getter');return cfg.missing?undefined:{...selection};}}
 env.TextAreaController=env.TextInputController=Controller;
 vm.createContext(env);vm.runInContext(compiled,env);const {Page,Host,Registry,LC}=env.API;page=new Page();
 const bridge={grapheme(){return '0:0:0';},preview(){return '0';},previewRange(){return '0';},commit(){return '0';},finish(){return '0';},focusAuthority(key,op){return op===4?'0':'1';},logWarn(){},logInfo(){}};
 page.proxyRegistry=new Registry(bridge);Object.assign(page,{imeMount:null,imeCtx:0,imeText:original,imeSelStart:-1,imeSelEnd:-1,pendingReconcile:null,supersededMount:null,supersededNodeId:0,supersededBaseVersion:0,proxyMountSerial:1,mountedNodeId:107,mountedBaseVersion:4,status:'',proxyFocused:true,imeTextController:new Controller()});
 let propertyText=page.imeText;
 Object.defineProperty(page,'imeText',{get(){return propertyText;},set(text){const m=page.imeMount;
 if(m&&m.publication&&m.publication.reason==='restore'&&!m.publication.consumed){const old=m.draft;
 assert(page.proxyRegistry.onWillChange(m,{content:text,previewText:{offset:-1,value:''},options:{oldContent:old,oldPreviewText:{offset:-1,value:''},rangeBefore:{start:0,end:old.length},rangeAfter:{start:0,end:text.length}}}));}
 propertyText=text;}});
 page.selectionLifecycle=new LC(new Host(page));page.displayDensity=()=>1;page.updateInputCapabilities=()=>{};page.armSupersededTeardown=()=>{};
 page.armProxySelection=(m,s,e,r)=>page.selectionLifecycle.arm(m,s,e,r);
 page.requestProxyFocus=(m)=>page.selectionLifecycle.requestAttach(m,'focus-platform-seam');
 page.getUIContext=()=>({postFrameCallback(frame){env.setTimeout(()=>{frame.onFrame();events.push({ms:now,type:'body-rendered'});frame.onIdle();},16);}});
 const advance=async(ms)=>{const end=now+ms;for(let n=0;n<5000;n++){for(let p=0;p<8;p++)await Promise.resolve();timers.sort((a,b)=>a.due-b.due||a.id-b.id);const t=timers[0];if(!t||t.due>end){now=end;return;}timers.shift();now=t.due;t.fn();}throw Error('unbounded');};
 const old=page.proxyRegistry.mount(12,1,'old','body',27,1,original);page.imeMount=old;page.imeCtx=12;
 if(cfg.pending||cfg.inflight)page.selectionLifecycle.arm(old,214,214,'mount');
 page.selectionLifecycle.requestAttach(old,'old-mount');await advance(cfg.inflight?10:0);
 if(cfg.gap){snap={...snap,context:13,baseVersion:5};page.onReconcileRequest(12,13);assert.equal(page.imeMount,null,'production retires and removes old component');assert.equal(page.pendingReconcile.oldMount,old);env.setTimeout(()=>{events.push({ms:now,type:'actual-disappear-callback'});page.onProxyDisappeared(old);},cfg.mountAt??40);}
 const payload={request:29,context:snap.context,generation:1,focusGeneration:1,appInstance:27,sessionToken:1,nodeId:107,resourceId:snap.resourceId,nodeKind:6,bindingEpoch:81,baseVersion:5,deadlineMonoMs:snap.restoreDeadlineMonoMs,field:'body',text:target,selStart:214,selEnd:214};
 if(cfg.missingResource)delete payload.resourceId;
 page.onProxyRestore({...payload,appInstance:cfg.wrongIdentity?28:27});
 if(cfg.duplicate)env.setTimeout(()=>page.onProxyRestore({...payload}),25);
 if(cfg.needsText&&!cfg.gap)env.setTimeout(()=>page.onProxyTextChange(page.imeMount,target),cfg.echoAt??10);
 if(cfg.resetAt!==undefined)env.setTimeout(()=>{selection={start:target.length,end:target.length};events.push({ms:now,type:'late-text-reset'});page.onProxySelectionChange(page.imeMount,selection.start,selection.end);},cfg.resetAt);
 if(cfg.retireAt!==undefined)env.setTimeout(()=>{const m=page.imeMount;page.selectionLifecycle.invalidateAttachmentFor(m);page.proxyRegistry.retireForReconcile(m,m.key.contextId);snap={...snap,generation:2};page.imeMount=page.proxyRegistry.mount(snap.context,2,'next','body',27,1,target);page.selectionLifecycle.restoreMountAvailable(page.imeMount);},cfg.retireAt);
 if(cfg.humanAt!==undefined)env.setTimeout(()=>{events.push({ms:now,type:'human-input'});page.onProxyTextChange(page.imeMount,original+'X');},cfg.humanAt);
 if(cfg.newAt!==undefined)env.setTimeout(()=>page.selectionLifecycle.arm(page.imeMount,300,300,'independent-new'),cfg.newAt);
 await advance(2300);await advance(20000);return {cfg,sets,acks,commits,events,timers:timers.length,restore:page.selectionLifecycle.hasRestore(),mount:page.imeMount?.key.describe()};}
(async()=>{const result={scope:'Both production hosts and actual reconcile/disappear/mount functions under controlled platform/native/clock seams. Not ArkUI device or costs.',sources,consumers:{}};
const specs={presentation_container:{resource:-1},presentation_gap:{resource:-1,gap:true,attachAt:80},missing_resource:{resource:-1,missingResource:true},ready:{},reconcile_gap:{gap:true,attachAt:80},delayed_noop:{attachAt:80},delayed_throw:{attachAt:80,unboundThrows:true},echo_before_attach:{needsText:true,echoAt:10,attachAt:80},reset_after_echo:{needsText:true,echoAt:10,resetAt:70},superseded:{attachAt:80,retireAt:10},never_attach:{never:true},attach_before_echo:{needsText:true,echoAt:90},pending:{pending:true,attachAt:80},inflight:{inflight:true},human:{pending:true,attachAt:80,humanAt:10},new_pending:{pending:true,newAt:20},original_deadline:{gap:true,mountAt:80,attachAt:100,deadline:90},duplicate:{duplicate:true},native_reject:{ackReject:true},getter_throw:{getterThrows:true},missing_read:{missing:true},wrong_identity:{wrongIdentity:true}};
for(const [name,file,host]of consumers){const compiled=code(file,host),cases={};for(const [caseName,cfg]of Object.entries(specs))cases[caseName]=await run(name,compiled,cfg);result.consumers[name]=cases;if(process.env.RESULT_PATH)fs.writeFileSync(process.env.RESULT_PATH,JSON.stringify(result,null,2)+'\n');
for(const caseName of ['presentation_container','presentation_gap','ready','reconcile_gap','delayed_noop','delayed_throw','echo_before_attach','attach_before_echo','pending','inflight','duplicate']){const c=cases[caseName];assert.equal(c.acks.length,1,name+'/'+caseName+' one original terminal');assert(c.acks[0].ok&&c.acks[0].rc==='0',name+'/'+caseName+' confirmed success');assert.equal(c.sets.length,1,name+'/'+caseName+' one restore setter');assert(!c.sets.some(s=>!s.attached),name+'/'+caseName+' exact attach');if(caseName!=='inflight')assert(c.sets[0].bodyRendered,name+'/'+caseName+' body rendered before setter');assert.equal(c.commits.length,0,name+'/'+caseName+' ACK only');}
for(const caseName of ['missing_resource','reset_after_echo','superseded','never_attach','human','original_deadline','native_reject','getter_throw','missing_read','wrong_identity']){const c=cases[caseName];assert.equal(c.acks.length,1,name+'/'+caseName+' one terminal');assert(!c.acks.some(a=>a.ok&&a.rc==='0'),name+'/'+caseName+' must refuse');}
assert.equal(cases.original_deadline.acks[0].ms,90);assert.equal(cases.human.sets.length,0);assert.equal(cases.superseded.sets.length,0);assert(cases.new_pending.commits.some(c=>c.s===300));assert(Object.values(cases).every(c=>!c.restore&&c.timers===0),'bounded drain');}
if(process.env.RESULT_PATH)fs.writeFileSync(process.env.RESULT_PATH,JSON.stringify(result,null,2)+'\n');console.log('PASS production consumer/common '+Object.keys(specs).length*consumers.length+' cases including original 16 and real callback path');})().catch(e=>{console.error(e.stack);process.exitCode=1;});
