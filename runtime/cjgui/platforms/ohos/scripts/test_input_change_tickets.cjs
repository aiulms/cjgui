const {test}=require('node:test');const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');const {stripTypeScriptTypes}=require('node:module');
global.FrameCallback=class{};global.TextDeleteDirection={BACKWARD:0,FORWARD:1};
const source=fs.readFileSync(process.env.PROXY_SRC || path.join(__dirname,'../arkts/cjgui-text-proxy.ets'),'utf8').replace(/^import .*;\s*$/gm,'');
const modulePromise=import('data:text/javascript,'+encodeURIComponent(stripTypeScriptTypes(source,{mode:'transform'})));
test('both actual consumer bridges carry the exact predecessor as a distinct final argument',()=>{
 const root=path.resolve(__dirname,'../../../../..');
 for(const file of [root+'/labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets','/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets']){
  const text=fs.readFileSync(file,'utf8'),start=text.indexOf('  inputWill(mount: CjguiTextProxyMount, change: CjguiProxyInputChange): string {');
  assert(start>=0,file);let level=0,end=-1;
  for(let i=text.indexOf('{',start);i<text.length;i++){level+=(text[i]==='{')-(text[i]==='}');if(level===0){end=i+1;break;}}
  assert(end>start);let observed;
  const code=stripTypeScriptTypes('class Bridge {\n'+text.slice(start,end)+'\n}',{mode:'transform'});
  const Bridge=new Function('entryNapi',code+';return Bridge;')({imeInputWill(...args){observed=args;return '8';}});
  const key={appInstance:7,sessionToken:1,contextId:10,editGeneration:3,mountGeneration:2};
  const mount={key,fieldId:'body'};
  for(const predecessor of [0,7]){
   const change={before:'x12',after:'x123',start:3,end:3,afterStart:3,afterEnd:4,focusGeneration:2,expectedPhysicalCommandId:0,expectedCommandExecution:0,predecessor};
   assert.equal(new Bridge().inputWill(mount,change),'8');
   assert.deepEqual(observed,['x12','x123','body',3,3,3,4,7,1,10,3,2,2,0,0,predecessor],file);
  }
 }
});
async function fixture(text='ABABAB'){
 const {CjguiTextProxyRegistry}=await modulePromise;let id=0;const calls=[];let active=true;
 const bridge={focusAuthority(k,op){return op===4?'0':active?'1':'0';},inputWill(m,c){calls.push(['will',m.key.describe(),c]);return String(++id);},
 inputChange(m,t,v){if(!active)return '1';calls.push(['change',m.key.describe(),t,v]);return '0';},
 inputChangePrefix(m,anchor,evidence){calls.push(['prefix',m.key.describe(),anchor,evidence]);return active?String(anchor):'0';},preview(){calls.push(['legacy-preview']);return '0';},
 previewRange(){calls.push(['marked-preview']);return '0';},finishProxy(){return '0';},grapheme(){return '{}';},logInfo(){},logWarn(){}};
 const registry=new CjguiTextProxyRegistry(bridge),mount=registry.mount(10,3,'proxy','body',7,1,text);
 return{registry,mount,calls,bridge,revoke(){active=false;}};
}
const empty={offset:-1,value:''};
function will(oldContent,content,start,end,afterStart=start,afterEnd=start+content.length-oldContent.length+end-start){
 return{content,previewText:empty,options:{oldContent,oldPreviewText:empty,rangeBefore:{start,end},rangeAfter:{start:afterStart,end:afterEnd}}};
}
test('actual repeated-body replacement preserves range instead of minimal diff',async()=>{
 const f=await fixture();assert(f.registry.onWillChange(f.mount,will('ABABAB','ABABABAB',0,6,0,8)));
 assert.equal(f.registry.onChange(f.mount,'ABABABAB',empty),'ok');assert.equal(f.calls[0][2].start,0);assert.equal(f.calls[0][2].end,6);
 assert.equal(f.calls.filter(c=>c[0]==='change').length,1);assert(!f.calls.some(c=>c[0]==='legacy-preview'));
});
test('three rapid different callbacks consume exact predecessors once',async()=>{
 const f=await fixture('');let old='';for(const char of ['A','中','👩‍💻']){let next=old+char;
 assert(f.registry.onWillChange(f.mount,will(old,next,old.length,old.length)));assert.equal(f.registry.onChange(f.mount,next,empty),'ok');old=next;}
 assert.equal(f.calls.filter(c=>c[0]==='change').length,3);assert.equal(f.mount.draft,'A中👩‍💻');
});
test('original Will2 Will3 Change2 Change3 keeps the admitted causal prefix',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 const two=will('x1','x12',2,2),three=will('x12','x123',3,3);
 assert(f.registry.onWillChange(f.mount,two));
 const second=f.calls.find(c=>c[0]==='will')[2];
 assert(f.registry.onWillChange(f.mount,three),'original next Will must enter the bounded native stream');
 const third=f.calls.filter(c=>c[0]==='will')[1][2];
 assert.equal(third.predecessor,1);assert.equal(second.predecessor,0);
 assert.equal(f.mount.draft,'x1','a proposed after-image is not platform text');
 assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
 // Real SDK Change2 carried later Will3 options in the preserved counterexample.
 assert.equal(f.registry.onChange(f.mount,'x12',empty,three.options),'ok');
 assert.equal(f.mount.draft,'x12');
 assert.equal(f.registry.onChange(f.mount,'x123',empty,three.options),'ok');
 assert.equal(f.mount.draft,'x123');assert.equal(f.mount.pendingInput,null);
 assert.deepEqual(f.calls.filter(c=>c[0]==='change').map(c=>c.slice(2)),[[1,'x12'],[2,'x123']]);
});
test('a later real Change with complete original evidence covers its prefix and late observations never replay',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 const two=will('x1','x12',2,2),three=will('x12','x123',3,3);
 assert(f.registry.onWillChange(f.mount,two));assert(f.registry.onWillChange(f.mount,three));
 assert.equal(f.registry.onChange(f.mount,'x123',empty,three.options),'ok');
 assert.equal(f.mount.draft,'x123','one actual Change8 proves the explicit original Will7/8 prefix');
 assert.equal(f.mount.pendingInput,null);assert.equal(f.calls.filter(c=>c[0]==='prefix').length,1);
 assert.equal(f.calls.filter(c=>c[0]==='change').length,0,'never synthesize individual Change7/8 calls');
 assert.equal(f.registry.onChange(f.mount,'x12',empty,two.options),'observation');
 assert.equal(f.registry.onChange(f.mount,'x123',empty,three.options),'observation');
 assert.equal(f.mount.draft,'x123');assert.equal(f.calls.filter(c=>c[0]==='prefix').length,1);
});
test('weak later metadata retains single-ticket waiting and cannot prove its missing predecessor',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 const two=will('x1','x12',2,2),three=will('x12','x123',3,3);delete three.options.oldPreviewText;
 assert(f.registry.onWillChange(f.mount,two));assert(f.registry.onWillChange(f.mount,will('x12','x123',3,3)));
 assert.equal(f.registry.onChange(f.mount,'x123',empty,three.options),'ok');assert.equal(f.mount.draft,'x1');
 assert.equal(f.calls.filter(c=>c[0]==='prefix').length,0);
 assert.equal(f.registry.onChange(f.mount,'x12',empty,two.options),'ok');assert.equal(f.mount.draft,'x123');
});
test('wrong postimage cannot consume Will as another Change',async()=>{
 const f=await fixture('abc');assert(f.registry.onWillChange(f.mount,will('abc','aXc',1,2)));
 assert.equal(f.registry.onChange(f.mount,'aYc',empty),'rejected');assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
});
test('same-value Will behind a pending input keeps its causal place without requiring another Change',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 assert(f.registry.onWillChange(f.mount,will('x1','x12',2,2)));
 assert(f.registry.onWillChange(f.mount,will('x12','x12',0,1,0,1)));
 assert(f.registry.onWillChange(f.mount,will('x12','x123',3,3)));
 assert.equal(f.calls.filter(c=>c[0]==='will')[2][2].predecessor,2);
 assert.equal(f.mount.draft,'x1');
 assert.equal(f.registry.onChange(f.mount,'x12',empty),'ok');
 assert.equal(f.mount.draft,'x12');assert.equal(f.mount.pendingInput.id,3);
 assert.equal(f.registry.onChange(f.mount,'x123',empty),'ok');assert.equal(f.mount.draft,'x123');
 assert.deepEqual(f.calls.filter(c=>c[0]==='change').map(c=>c[2]),[1,3]);
});
test('indistinguishable pending ABA postimages cannot grant a different original ticket',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 assert(f.registry.onWillChange(f.mount,will('x1','x12',2,2)));
 assert(f.registry.onWillChange(f.mount,will('x12','x1',2,3,2,2)));
 const last=will('x1','x12',2,2);assert(f.registry.onWillChange(f.mount,last));
 assert.equal(f.registry.onChange(f.mount,'x12',empty,last.options),'observation');
 assert.equal(f.calls.filter(c=>c[0]==='change').length,0);assert.equal(f.mount.draft,'x1');
});
test('missing Will and malformed scalar boundaries have zero business calls',async()=>{
 const f=await fixture('a😀b');assert(!f.registry.onWillChange(f.mount,will('a😀b','a😁b',2,3,2,3)));
 assert.equal(f.registry.onChange(f.mount,'aXb',empty),'rejected');assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
});
test('optional SDK range endpoints cannot inherit component defaults',async()=>{
 for(const range of ['rangeBefore','rangeAfter']) for(const endpoint of ['start','end']) {
  const f=await fixture('abc'),v=will('abc','aXc',1,2);delete v.options[range][endpoint];
  assert.equal(f.registry.onWillChange(f.mount,v),false);assert.equal(f.calls.length,0);
 }
});
test('mount and complete publication echoes are zero transactions including repeats',async()=>{
 const f=await fixture('abc');assert.equal(f.registry.onChange(f.mount,'abc',empty),'ok');
 f.mount.registerPublication('abc|PUB','restore');
 assert(f.registry.onWillChange(f.mount,will('abc','abc|PUB',0,3,0,7)));
 assert.equal(f.registry.onChange(f.mount,'abc|PUB',empty),'ok');assert.equal(f.registry.onChange(f.mount,'abc|PUB',empty),'ok');
 assert.equal(f.calls.length,0);
});
test('human Will retires the previous publication before its late text callback',async()=>{
 const f=await fixture('abc');assert(f.registry.onWillChange(f.mount,will('abc','abcX',3,3)));
 assert.equal(f.registry.onChange(f.mount,'abcX',empty),'ok');assert.equal(f.registry.onChange(f.mount,'abc',empty),'rejected');
 assert.equal(f.mount.draft,'abcX');assert.equal(f.calls.filter(c=>c[0]==='change').length,1);
});
test('old mount and revoked focus never publish a frozen input',async()=>{
 const f=await fixture('abc');assert(f.registry.onWillChange(f.mount,will('abc','abcX',3,3)));
 f.revoke();assert.equal(f.registry.onChange(f.mount,'abcX',empty),'stale');assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
});
test('same-value semantic Will queues once without Change; rapid x123 keeps actual ranges',async()=>{
 const f=await fixture('xyz');f.mount.publication=null;
 assert(f.registry.onWillChange(f.mount,will('xyz','xyz',0,1,0,1)));
 assert.equal(f.mount.pendingInput,null);assert.equal(f.calls.filter(c=>c[0]==='will').length,1);
 assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
 let text='xyz';for(let i=1;i<=3;i++){const next=text.slice(0,i)+i+text.slice(i);
 assert(f.registry.onWillChange(f.mount,will(text,next,i,i,i,i+1)));assert.equal(f.registry.onChange(f.mount,next,empty),'ok');text=next;}
 assert.equal(text,'x123yz');assert.deepEqual(f.calls.filter(c=>c[0]==='will').map(c=>[c[2].start,c[2].end]),[[0,1],[1,1],[2,2],[3,3]]);
 assert.equal(f.registry.onChange(f.mount,'xyz',empty),'ok');assert.equal(f.mount.draft,'x123yz');
 assert.equal(f.calls.filter(c=>c[0]==='change').length,3);
});
test('same-value command budget is checked before allowing platform progress',async()=>{
 const f=await fixture('xyz');f.mount.publication=null;
 for(let i=0;i<32;i++)assert(f.registry.onWillChange(f.mount,will('xyz','xyz',0,1,0,1)));
 assert.equal(f.registry.onWillChange(f.mount,will('xyz','xyz',0,1,0,1)),false);assert.equal(f.calls.filter(c=>c[0]==='will').length,32);
});
test('both actual prefix bridges transport frozen values, not mutable mount identity',async()=>{
 const root=path.resolve(__dirname,'../../../../..');
 for(const file of [root+'/labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets','/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets']){
  const text=fs.readFileSync(file,'utf8'),start=text.indexOf('  inputChangePrefix(mount: CjguiTextProxyMount, anchor: number, evidence: CjguiProxySDKChange): string {');assert(start>=0);
  let depth=0,end=-1;for(let i=text.indexOf('{',start);i<text.length;i++){depth+=(text[i]==='{')-(text[i]==='}');if(!depth){end=i+1;break;}}
  let args;const code=stripTypeScriptTypes('class Bridge {\n'+text.slice(start,end)+'\n}',{mode:'transform'});
  const Bridge=new Function('entryNapi',code+';return Bridge;')({imeInputChangePrefix(...a){args=a;return '8';}});
  const key={appInstance:7,sessionToken:1,contextId:10,editGeneration:3,mountGeneration:2};
  const e={key,focus:2,observation:27,before:'x12',value:'x123',start:3,end:3,afterStart:3,afterEnd:4,previewOffset:-1,previewValue:'',oldPreviewOffset:-1,oldPreviewValue:''};
  assert.equal(new Bridge().inputChangePrefix({key:{appInstance:99},focusGeneration:99},8,e),'8');
  assert.deepEqual(args,['x12','x123',8,7,1,10,3,2,2,27,3,3,3,4,-1,'',-1,'']);
  assert(text.includes('const original=this.proxyRegistry.observeSDKChange(m,value,previewText,options);\n          this.onProxyTextChange(m,original.value,original.preview(),original.options(),original);'));
 }
});
test('actual SDK entry copies primitive metadata before mutable options are reused',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 const a=will('x1','x12',2,2),b=will('x12','x123',3,3);
 assert(f.registry.onWillChange(f.mount,a));assert(f.registry.onWillChange(f.mount,b));
 const preview={offset:-1,value:''};const original=f.registry.observeSDKChange(f.mount,'x123',preview,b.options);
 b.options.oldContent='WRONG';b.options.rangeBefore.start=999;b.options.oldPreviewText={offset:0,value:'marked'};preview.offset=0;preview.value='marked';
 assert.equal(f.registry.onChange(f.mount,'WRONG',preview,b.options,original),'ok');assert.equal(f.mount.draft,'x123');
 const sent=f.calls.find(c=>c[0]==='prefix')[3];assert.equal(sent.before,'x12');assert.equal(sent.start,3);assert.equal(sent.previewValue,'');
});
test('confirmed prefix cannot complete an unseen non-semantic tail',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 for(const [a,b]of [['x1','x12'],['x12','x123'],['x123','x1234']])assert(f.registry.onWillChange(f.mount,will(a,b,a.length,a.length)));
 assert.equal(f.registry.onChange(f.mount,'x123',empty,will('x12','x123',3,3).options),'ok');
 assert.equal(f.mount.draft,'x123');assert.equal(f.mount.pendingInput.id,3);assert.deepEqual(f.mount.pairedInputIds,[]);
 assert.equal(f.registry.onChange(f.mount,'x1234',empty),'ok');assert.equal(f.mount.draft,'x1234');
});
test('native prefix rejection has no local ready, draft, or surrogate single-Change write',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 assert(f.registry.onWillChange(f.mount,will('x1','x12',2,2)));assert(f.registry.onWillChange(f.mount,will('x12','x123',3,3)));
 f.bridge.inputChangePrefix=()=> '0';
 assert.equal(f.registry.onChange(f.mount,'x123',empty,will('x12','x123',3,3).options),'rejected');
 assert.equal(f.mount.draft,'x1');assert.deepEqual(f.mount.pairedInputIds,[]);assert.equal(f.mount.pendingInputs.length,2);
 assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
});
test('bridge reentry cannot write a replacement mount or relabel the old original',async()=>{
 const f=await fixture('x1');f.mount.publication=null;let next;
 assert(f.registry.onWillChange(f.mount,will('x1','x12',2,2)));assert(f.registry.onWillChange(f.mount,will('x12','x123',3,3)));
 f.bridge.inputChangePrefix=(m,anchor,e)=>{next=f.registry.mount(11,4,'new','other',7,1,'new text');return String(anchor);};
 assert.equal(f.registry.onChange(f.mount,'x123',empty,will('x12','x123',3,3).options),'stale');
 assert.equal(next.draft,'new text');assert.equal(f.registry.current,next);assert.equal(f.mount.draft,'x1');
});
test('completion observations remain bounded and do not consume new pending capacity',async()=>{
 const f=await fixture('');f.mount.publication=null;let text='';
 for(let i=0;i<80;i++){const next=text+'a';assert(f.registry.onWillChange(f.mount,will(text,next,text.length,text.length)));
  assert.equal(f.registry.onChange(f.mount,next,empty),'ok');text=next;
  assert(f.mount.completedInputs.length+f.mount.pendingInputs.length+f.mount.semanticEchoes.length<=32);
 }
 assert.equal(f.mount.draft,text);assert.equal(f.calls.filter(c=>c[0]==='change').length,80);
});
test('late covered Change with reused later options remains observation only',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 const a=will('x1','x12',2,2),b=will('x12','x123',3,3);
 assert(f.registry.onWillChange(f.mount,a));assert(f.registry.onWillChange(f.mount,b));
 assert.equal(f.registry.onChange(f.mount,'x123',empty,b.options),'ok');
 assert.equal(f.registry.onChange(f.mount,'x12',empty,b.options),'observation');
 assert.equal(f.mount.draft,'x123');assert.equal(f.registry.isCurrent(f.mount),true);
 assert.equal(f.calls.filter(c=>c[0]==='prefix').length,1);assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
});
test('SDK entry freezes before diagnostic reentry can reuse its options',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 assert(f.registry.onWillChange(f.mount,will('x1','x12',2,2)));const b=will('x12','x123',3,3);
 assert(f.registry.onWillChange(f.mount,b));
 f.mount.inputDiagnostic={short(v){return String(v);},write(bridge,m,phase){if(phase==='Change-SDK-entry'){b.options.oldContent='mutated during log';b.options.rangeBefore.start=999;}}};
 const original=f.registry.observeSDKChange(f.mount,'x123',empty,b.options);
 assert.equal(f.registry.onChange(f.mount,original.value,original.preview(),original.options(),original),'ok');
 assert.equal(f.mount.draft,'x123');assert.equal(f.calls.find(c=>c[0]==='prefix')[3].before,'x12');
});
if(process.env.PREFIX_WITHDRAWAL_TEST!=='1')test('isolated completion and entry-freeze withdrawals restore discriminating failures',()=>{
 const os=require('node:os'),cp=require('node:child_process'),dir=fs.mkdtempSync(path.join(os.tmpdir(),'h-platform-prefix-'));
 try{
  const original=fs.readFileSync(path.join(__dirname,'../arkts/cjgui-text-proxy.ets'),'utf8');
  const a=original.indexOf('  observeSDKChange('),b=original.indexOf('  private pairInputChange(',a);
  const lateFreeze=`  observeSDKChange(m: CjguiTextProxyMount, value: string, previewText?: PreviewText, options?: TextChangeOptions): CjguiProxySDKChange {
    m.inputDiagnostic?.write(this.bridge,m,'Change-SDK-entry','withdrawn early freeze');
    return new CjguiProxySDKChange(m,++m.sdkChangeSequence,value,previewText,options);
  }
`;
  const variants=[['completion',original.replace('const prefix=input!==head && evidence.matches(input);','const prefix=false && input!==head && evidence.matches(input);')],['entry-freeze',original.slice(0,a)+lateFreeze+original.slice(b)]];
  const results=[];
  for(const [label,code]of variants){assert.notEqual(code,original);const file=path.join(dir,label+'.ets');fs.writeFileSync(file,code);
   const env={...process.env,PROXY_SRC:file,PREFIX_WITHDRAWAL_TEST:'1'};
   // Do not inherit the parent node:test worker marker and silently skip this run.
   delete env.NODE_TEST_CONTEXT;
   const r=cp.spawnSync(process.execPath,['--test','--test-name-pattern=a later real Change with complete|SDK entry freezes before diagnostic reentry',__filename],{encoding:'utf8',env});
   if(process.env.PREFIX_WITHDRAWAL_OUT)fs.writeFileSync(path.join(process.env.PREFIX_WITHDRAWAL_OUT,'proxy-withdraw-'+label+'.log'),r.stdout+r.stderr);
   assert(r.status===1 && /# fail [1-9]/.test(r.stdout),label+' must fail actual assertions: '+JSON.stringify({status:r.status,error:r.error,output:r.stdout,stderr:r.stderr}));
   results.push({label,exit:r.status});
  }
  console.log('PREFIX_WITHDRAWALS '+JSON.stringify(results));
 }finally{fs.rmSync(dir,{recursive:true,force:true});}
});
test('native-authorized retired prefix settles only original refs, never a new mount draft',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 const b=will('x12','x123',3,3);assert(f.registry.onWillChange(f.mount,will('x1','x12',2,2)));assert(f.registry.onWillChange(f.mount,b));
 const next=f.registry.mount(11,4,'target','other',7,1,'target text');
 f.bridge.inputChangePrefix=(m,id,e)=>{assert.equal(m,f.mount);assert.equal(e.key.contextId,10);return String(id);};
 assert.equal(f.registry.onChange(f.mount,'x123',empty,b.options),'settled');assert.equal(f.mount.pendingInput,null);
 assert.equal(f.mount.draft,'x1');assert.equal(next.draft,'target text');assert.equal(f.registry.current,next);
});
test('same-value original between changed Wills keeps its own place in a covered prefix',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 assert(f.registry.onWillChange(f.mount,will('x1','x12',2,2)));
 assert(f.registry.onWillChange(f.mount,will('x12','x12',0,1,0,1)));
 const c=will('x12','x123',3,3);assert(f.registry.onWillChange(f.mount,c));
 assert.equal(f.registry.onChange(f.mount,'x123',empty,c.options),'ok');assert.equal(f.mount.draft,'x123');assert.equal(f.mount.pendingInput,null);
 assert.equal(f.calls.filter(c=>c[0]==='prefix').length,1);assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
});
test('late-observation history retains only bounded compact facts, not old input bodies',async()=>{
 const f=await fixture('x1');f.mount.publication=null;
 assert(f.registry.onWillChange(f.mount,will('x1','x12',2,2)));const b=will('x12','x123',3,3);assert(f.registry.onWillChange(f.mount,b));
 assert.equal(f.registry.onChange(f.mount,'x123',empty,b.options),'ok');
 assert.equal(f.mount.completedInputs.length,2);
 for(const receipt of f.mount.completedInputs){assert.equal(receipt.before,undefined);assert.equal(receipt.after,undefined);assert(Number.isSafeInteger(receipt.id));}
 const calls=f.calls.length;assert.equal(f.registry.onChange(f.mount,'x12',empty,b.options),'observation');assert.equal(f.calls.length,calls);assert.equal(f.mount.draft,'x123');
});

test('complete current ASCII conversions return to historical text twice without replaying old entries',async()=>{
 const f=await fixture('X');f.mount.publication=null;
 async function done(before,after,start,end,afterStart=start,afterEnd=start+after.length-before.length+end-start){
  const w=will(before,after,start,end,afterStart,afterEnd);assert(f.registry.onWillChange(f.mount,w));
  assert.equal(f.registry.onChange(f.mount,after,empty,w.options),'ok');return w;
 }
 await done('X','A',0,1);await done('A','AB',1,1);
 const back=will('AB','A',1,2,1,1);assert(f.registry.onWillChange(f.mount,back));
 const original=f.registry.observeSDKChange(f.mount,'A',empty,back.options);
 assert.equal(f.registry.onChange(f.mount,'A',empty,back.options,original),'ok');
 await done('A','AB',1,1);const again=will('AB','A',1,2,1,1);assert(f.registry.onWillChange(f.mount,again));
 const before=f.calls.length;
 assert.equal(f.registry.onChange(f.mount,'A',empty,back.options,original),'observation','a known earlier callback entry cannot complete a later original Will');
 assert.equal(f.calls.length,before);assert.equal(f.mount.draft,'AB');assert.equal(f.mount.pendingInput.id,5);
 assert.equal(f.registry.onChange(f.mount,'A',empty,again.options),'ok');assert.equal(f.mount.draft,'A');assert.equal(f.mount.pendingInput,null);
 assert.deepEqual(f.calls.filter(c=>c[0]==='change').map(c=>c[2]),[1,2,3,4,5]);
 const calls=f.calls.length;assert.equal(f.registry.onChange(f.mount,'A',empty,again.options),'observation');assert.equal(f.calls.length,calls);
});
test('complete original ZWJ delete returns historical text and repeats its own legitimate conversion',async()=>{
 const f=await fixture('X');f.mount.publication=null;
 const first=will('X','A',0,1);assert(f.registry.onWillChange(f.mount,first));assert.equal(f.registry.onChange(f.mount,'A',empty,first.options),'ok');
 for(let round=0;round<2;round++){
  const add=will('A','A👩‍💻',1,1,1,6);assert(f.registry.onWillChange(f.mount,add));assert.equal(f.registry.onChange(f.mount,'A👩‍💻',empty,add.options),'ok');
  const del=will('A👩‍💻','A',1,6,1,1);assert(f.registry.onWillChange(f.mount,del));assert.equal(f.registry.onChange(f.mount,'A',empty,del.options),'ok');
  assert.equal(f.mount.draft,'A');assert.equal(f.mount.pendingInput,null);
 }
 assert.equal(f.calls.filter(c=>c[0]==='change').length,5);assert.equal(f.calls.filter(c=>c[0]==='prefix').length,0);
});
test('historical postimage never repairs weak or wrong current delete metadata',async()=>{
 for(const kind of ['missing-old-preview','wrong-old','wrong-range']){
  const f=await fixture('X');f.mount.publication=null;
  for(const w of [will('X','A',0,1),will('A','A👩‍💻',1,1,1,6)]){assert(f.registry.onWillChange(f.mount,w));assert.equal(f.registry.onChange(f.mount,w.content,empty,w.options),'ok');}
  const del=will('A👩‍💻','A',1,6,1,1);assert(f.registry.onWillChange(f.mount,del));
  if(kind==='missing-old-preview')delete del.options.oldPreviewText;
  if(kind==='wrong-old')del.options.oldContent='unrelated';
  if(kind==='wrong-range')del.options.rangeBefore.start=0;
  const before=f.calls.length;assert.equal(f.registry.onChange(f.mount,'A',empty,del.options),'observation');
  assert.equal(f.calls.length,before);assert.equal(f.mount.draft,'A👩‍💻');assert.equal(f.mount.pendingInput.id,3);
 }
});
