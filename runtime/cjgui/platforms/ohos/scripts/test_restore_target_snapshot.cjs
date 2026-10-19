// Real shared ticket + both actual hosts. Controlled snapshot reads, no SDK claim.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const{stripTypeScriptTypes}=require('node:module');
const dir=path.resolve(__dirname,'..');
const common=fs.readFileSync(process.env.PROXY_SRC||path.join(dir,'arkts/cjgui-text-proxy.ets'),'utf8');
const hosts=[['thermo',path.resolve(dir,'../../../../labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets')],['pharos','/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets']];
function extract(s,tag){const at=s.indexOf(tag);assert(at>=0,tag);let n=0;for(let i=s.indexOf('{',at);i<s.length;i++){if(s[i]==='{')n++;if(s[i]==='}'&&--n===0)return s.slice(at,i+1);}throw Error(tag);}
function api(extra=''){
 const e={FrameCallback:class{}};vm.createContext(e);
 vm.runInContext(stripTypeScriptTypes(common.replace(/^import .*;\s*$/gm,'')+'\n'+extra+'\nglobalThis.Ticket=CjguiImeRestoreTicket;',{mode:'transform'}).replace(/export /g,''),e);return e;
}
const payload={request:15,context:10,generation:1,focusGeneration:2,appInstance:1,sessionToken:1,nodeId:107,resourceId:1,nodeKind:10,bindingEpoch:1,baseVersion:24,deadlineMonoMs:260514,field:'body',text:'xyz',selStart:3,selEnd:3};
const snapshot={...payload,restoreRequest:15,restoreDeadlineMonoMs:260514,restoreProjectionVersion:24,restoreBindingEpoch:1};
const e=api(),ticket=new e.Ticket(payload);assert(ticket.valid());assert.equal(ticket.targetMismatch(snapshot,1),'');
for(const field of ['appInstance','sessionToken','context','generation','focusGeneration','nodeId','resourceId','nodeKind','field','restoreRequest','restoreDeadlineMonoMs','restoreProjectionVersion','restoreBindingEpoch']){
 const s={...snapshot,[field]:typeof snapshot[field]==='string'?'other':snapshot[field]+1};
 assert.match(ticket.targetMismatch(s,1),new RegExp('^'+field+' expected='),field);
}
assert.match(ticket.targetMismatch(snapshot,2),/^hostAppInstance expected=/);
assert.match(ticket.targetMismatch(null,1),/^snapshot expected=/);
const anonymous=new e.Ticket({...payload,request:0});
for(const field of ['baseVersion','bindingEpoch'])assert.match(anonymous.targetMismatch({...snapshot,[field]:99},1),new RegExp('^'+field+' expected='));
assert.equal(anonymous.targetMismatch(snapshot,1),'');
for(const [field,value]of[['context',0],['request',NaN],['start',-1],['field','']]){
 const p={...payload};p[field==='start'?'selStart':field]=value;const t=new e.Ticket(p);assert(!t.valid());assert(t.validityMismatch().includes(field));
}
for(const[name,file]of hosts){
 const src=fs.readFileSync(file,'utf8');const method=extract(src,'  restoreTargetEligible(ticket: CjguiImeRestoreTicket): boolean {');
 const a=api('class Host {page: Object; constructor(page: Object){this.page=page;} logWarn(s:string):void{this.page.log(s);}\n'+method+'}\nglobalThis.Host=Host;');
 let reads=0,appReads=0,current=snapshot;const logs=[];
 const page={readLiveEditingSnapshot(){reads++;return current;},readHostAppInstance(){appReads++;return 1;},log(s){logs.push(s);}};
 const h=new a.Host(page),t=new a.Ticket(payload);assert(h.restoreTargetEligible(t));assert.equal(reads,1);assert.equal(appReads,1);
 current={...snapshot,context:11};assert(!h.restoreTargetEligible(t));assert.equal(reads,2);assert.equal(appReads,2);assert(logs.at(-1).includes('context expected=10 actual=11'));
 current=null;assert(!h.restoreTargetEligible(t));assert.equal(reads,3);assert.equal(appReads,2);
 console.log('PASS actual host single-snapshot first mismatch '+name);
}
console.log('PASS full frozen source/anonymous/named eligibility negatives; no body logging');
