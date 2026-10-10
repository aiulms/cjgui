// Execute the production common lifecycle with controlled platform/clock seams.
// This is not real ArkUI/IME/device performance evidence.
const fs = require('node:fs');
const vm = require('node:vm');
const mod = require('node:module');
const assert = require('node:assert/strict');
const path = require('node:path');
const source = fs.readFileSync(process.env.PROXY_SRC || path.join(__dirname, '../arkts/cjgui-text-proxy.ets'), 'utf8');
const code = mod.stripTypeScriptTypes(source.replace(/^import .*;\s*$/gm, ''), { mode: 'transform' })
  .replace(/export /g, '') + '\nglobalThis.API={Registry:CjguiTextProxyRegistry,LC:CjguiImeSelectionLifecycle,Ticket:CjguiImeRestoreTicket};';

async function run(cfg = {}) {
  let now = 0, id = 0, timers = [], selection = {start: 0, end: 0}, current = null, live = true;
  const events = [], acks = [], sets = [], commits = [];
  const env = {FrameCallback: class {}, setTimeout(fn, ms) {const n=++id; timers.push({id:n, due:now+ms, fn}); return n;},
    clearTimeout(n) {timers=timers.filter(t=>t.id!==n);}};
  vm.createContext(env); vm.runInContext(code, env);
  const {Registry, LC, Ticket} = env.API;
  const registry = new Registry({logInfo(){},logWarn(){},preview(){return '0';},previewRange(){return '0';},commit(){return '0';},finish(){return '0';},focusAuthority(key,op){return op===4?'0':'1';},grapheme(){return '0:0:0';}});
  let lc;
  const host = {
    attachSession() {events.push({ms:now,event:'attach'}); return new Promise(resolve=>{
      if(cfg.neverAttach)return;
      env.setTimeout(resolve,Math.max(0,(cfg.attachAt??0)-now));});},
    hasImeTrafficEvidence(m){return registry.hasTraffic(m);},
    isCurrentMount(m){return m===current&&registry.isCurrent(m);},
    restoreTaskActive(){return lc.hasRestore();},
    readSelection(){if(cfg.getterThrows)throw Error('getter'); return cfg.missingRead?{start:-1,end:-1}:{...selection};},
    setSelection(s,e){assert(lc.isAttachedTo(current),'zero setter before exact-mount attach');sets.push({ms:now,s,e,mount:current.key.describe()});selection={start:s,end:e};},
    commitInstalled(s,e,c){commits.push({ms:now,s,e,c});return '0';},
    restoreTargetEligible(t){return live&&t.context===12&&t.generation===1&&t.appInstance===27&&t.sessionToken===1;},
    currentMount(){return current;},
    monotonicNowMs(){return now;},
    writeRestoreText(m,text){events.push({ms:now,event:'write-text'});const old=m.draft;assert(registry.onWillChange(m,{content:text,previewText:{offset:-1,value:''},options:{oldContent:old,oldPreviewText:{offset:-1,value:''},rangeBefore:{start:0,end:old.length},rangeAfter:{start:0,end:text.length}}}));env.setTimeout(()=>lc.observeRestoreText(m,text),cfg.echoAt??10);},
    afterComponentFrame(m,fn){const n=env.setTimeout(fn,16);return {cancel(){env.clearTimeout(n);}};},
    commitRestore(t,s,e,ok,reason){const rc=cfg.ackReject?'1':'0';acks.push({ms:now,request:t.request,s,e,ok,reason,rc});return rc;},
    logInfo(msg){events.push({ms:now,event:'info',msg});},logWarn(msg){events.push({ms:now,event:'warn',msg});}
  };
  lc=new LC(host);
  const mount=()=>{current=registry.mount(12,1,'proxy','body',27,1,cfg.needsText?'OLD':'A'.repeat(12285));lc.restoreMountAvailable(current);lc.requestAttach(current,'mount');return current;};
  const advance=async(ms)=>{const end=now+ms;for(let guard=0;guard<5000;guard++){
    for(let i=0;i<6;i++)await Promise.resolve();timers.sort((a,b)=>a.due-b.due||a.id-b.id);
    const t=timers[0];if(!t||t.due>end){now=end;return;}timers.shift();now=t.due;t.fn();}throw Error('timer loop');};
  if(!cfg.gap)mount();
  if(cfg.ordinaryPending)lc.arm(current,214,214,'mount');
  const ticket=new Ticket({request:cfg.anonymous?0:29,context:12,generation:1,focusGeneration:1,appInstance:27,sessionToken:1,nodeId:107,
    resourceId:2,nodeKind:6,bindingEpoch:81,baseVersion:5,deadlineMonoMs:cfg.deadline??1500,
    field:'body',text:'A'.repeat(12285),selStart:214,selEnd:214});
  lc.restore(ticket);
  if(cfg.secondAt!==undefined)env.setTimeout(()=>lc.restore(ticket),cfg.secondAt);
  if(cfg.gap)env.setTimeout(mount,cfg.mountAt??40);
  if(cfg.resetAt!==undefined)env.setTimeout(()=>{selection={start:12285,end:12285};lc.observeRestoreSelection(current,12285,12285);},cfg.resetAt);
  if(cfg.retireAt!==undefined)env.setTimeout(()=>{lc.invalidateAttachmentFor(current);registry.retireForReconcile(current,12);current=registry.mount(12,2,'proxy-next','body',27,1,ticket.text);lc.restoreMountAvailable(current);},cfg.retireAt);
  if(cfg.humanAt!==undefined)env.setTimeout(()=>{lc.supersededByHumanInput(current);live=false;selection={start:215,end:215};},cfg.humanAt);
  if(cfg.newPendingAt!==undefined)env.setTimeout(()=>lc.arm(current,300,300,'new-intent'),cfg.newPendingAt);
  await advance(2100);await advance(20000);
  return {cfg,sets,acks,commits,events,timers:timers.length,hasRestore:lc.hasRestore(),selection};
}

(async()=>{
  const cases={};
  for(const [name,cfg] of Object.entries({ready:{},gap:{gap:true,attachAt:80},delayed:{attachAt:80},
    echo_first:{needsText:true,echoAt:10,attachAt:80},attach_first:{needsText:true,echoAt:90,attachAt:0},
    late_reset:{needsText:true,resetAt:70},retired:{attachAt:80,retireAt:10},never:{neverAttach:true},
    original_deadline:{gap:true,mountAt:80,attachAt:100,deadline:90},getter:{getterThrows:true},
    missing:{missingRead:true},ack_reject:{ackReject:true},pending:{ordinaryPending:true},
    anonymous_repeat:{anonymous:true,secondAt:120},named_late_duplicate:{secondAt:120},human:{ordinaryPending:true,attachAt:80,humanAt:10},new_pending:{ordinaryPending:true,newPendingAt:20}}))cases[name]=await run(cfg);
  const earlyDest=process.env.RESULT_PATH;if(earlyDest)fs.writeFileSync(earlyDest,JSON.stringify(cases,null,2)+'\n');
  assert.equal(cases.anonymous_repeat.acks.length,2,'each anonymous menu intent may execute');
  assert.equal(cases.anonymous_repeat.sets.length,2,'one write per anonymous intent');
  assert.equal(cases.named_late_duplicate.acks.length,1,'named terminal cannot resurrect');
  for(const name of ['ready','gap','delayed','echo_first','attach_first','pending']){
    const c=cases[name];assert.equal(c.acks.length,1,name+' one terminal');assert.equal(c.acks[0].ok,true,name+' success');assert.equal(c.sets.length,1,name+' unique setter');assert.equal(c.commits.length,0,name+' restore ACK only');}
  for(const name of ['late_reset','retired','never','original_deadline','getter','missing','ack_reject','human']){
    const c=cases[name];assert.equal(c.acks.length,1,name+' one terminal');assert(!c.acks.some(a=>a.ok&&a.rc==='0'),name+' no false success');}
  assert.equal(cases.retired.sets.length,0,'old mount must not renew on same context new generation');
  assert.equal(cases.human.sets.length,0,'human takeover zero late setter');
  assert.equal(cases.original_deadline.acks[0].ms,90,'mounting does not reopen deadline');
  assert(cases.new_pending.commits.some(c=>c.s===300),'independent new intent resumes');
  assert(Object.values(cases).every(c=>c.timers===0&&!c.hasRestore),'bounded task/timer drain');
  const dest=process.env.RESULT_PATH;if(dest)fs.writeFileSync(dest,JSON.stringify(cases,null,2)+'\n');
  console.log('PASS common restore owner contract '+Object.keys(cases).length+' cases');
})().catch(err=>{console.error(err.stack);process.exitCode=1;});
