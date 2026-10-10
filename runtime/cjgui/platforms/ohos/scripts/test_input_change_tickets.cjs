const {test}=require('node:test');const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');const {stripTypeScriptTypes}=require('node:module');
global.FrameCallback=class{};global.TextDeleteDirection={BACKWARD:0,FORWARD:1};
const source=fs.readFileSync(path.join(__dirname,'../arkts/cjgui-text-proxy.ets'),'utf8').replace(/^import .*;\s*$/gm,'');
const modulePromise=import('data:text/javascript,'+encodeURIComponent(stripTypeScriptTypes(source,{mode:'transform'})));
async function fixture(text='ABABAB'){
 const {CjguiTextProxyRegistry}=await modulePromise;let id=0;const calls=[];let active=true;
 const bridge={focusAuthority(k,op){return op===4?'0':active?'1':'0';},inputWill(m,c){calls.push(['will',m.key.describe(),c]);return String(++id);},
 inputChange(m,t,v){calls.push(['change',m.key.describe(),t,v]);return '0';},preview(){calls.push(['legacy-preview']);return '0';},
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
test('wrong postimage cannot consume Will as another Change',async()=>{
 const f=await fixture('abc');assert(f.registry.onWillChange(f.mount,will('abc','aXc',1,2)));
 assert.equal(f.registry.onChange(f.mount,'aYc',empty),'rejected');assert.equal(f.calls.filter(c=>c[0]==='change').length,0);
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
