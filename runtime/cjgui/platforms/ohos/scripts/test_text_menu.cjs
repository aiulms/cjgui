// Run the exact production async command class, stripping type syntax only.
const {test}=require('node:test');const assert=require('node:assert/strict');
const fs=require('node:fs');const {stripTypeScriptTypes}=require('node:module');
const raw=fs.readFileSync(__dirname+'/../arkts/cjgui-text-menu.ets','utf8');
const start=raw.indexOf('export interface CjguiMenuSnapshot');
const end=raw.indexOf('class EntryMenuBridge');
const modulePromise=import('data:text/javascript,'+encodeURIComponent(stripTypeScriptTypes(raw.slice(start,end),{mode:'transform'})));
const snapshot=()=>({context:1,generation:2,baseVersion:3,selStart:1,selEnd:4,text:'中😆x尾',menuAvailable:true});
async function fixture(){
 const {CjguiMenuCommands}=await modulePromise;const calls=[];let valid=true,writeFail=false,readFail=false,afterAwait=null;
 const bridge={command(a,i,s){calls.push(['command',a,i,s]);return valid;},async write(t){calls.push(['write',t]);if(writeFail)throw Error('write failure');if(afterAwait)afterAwait();},async read(){calls.push(['read']);if(readFail)throw Error('read failure');if(afterAwait)afterAwait();return '粘😆';},installed(c){calls.push(['installed',c]);}};
 return {controller:new CjguiMenuCommands(bridge),calls,stale(){valid=false;},writeFail(){writeFail=true;},readFail(){readFail=true;},after(f){afterAwait=f;}};
}
test('copy exact UTF16 selection without editing',async()=>{const f=await fixture();assert(await f.controller.copy(snapshot(),false));assert.deepEqual(f.calls.map(x=>x.slice(0,3)),[['command','validate',''],['write','😆x'],['command','validate','']]);});
test('cut waits for successful clipboard write',async()=>{const f=await fixture();f.writeFail();await assert.rejects(f.controller.copy(snapshot(),true));assert.equal(f.calls.some(x=>x[1]==='replace'),false);assert.equal(f.controller.busy,false);});
test('cut stale async return fails without edit or retry',async()=>{const f=await fixture();f.after(()=>f.stale());assert.equal(await f.controller.copy(snapshot(),true),false);assert.equal(f.calls.filter(x=>x[1]==='replace').length,1);assert.equal(f.calls.some(x=>x[0]==='installed'),false);});
test('paste denial never reads clipboard',async()=>{const f=await fixture();assert.equal(await f.controller.paste(snapshot(),false),false);assert.deepEqual(f.calls,[]);});
test('paste retains original exact snapshot across await',async()=>{const f=await fixture();const s=snapshot();assert(await f.controller.paste(s,true));assert.equal(f.calls[2][1],'replace');assert.equal(f.calls[2][2],'粘😆');assert.equal(f.calls[2][3],s);assert.deepEqual(f.calls[3],['installed',1]);});
test('paste stale version/selection never installs or retries',async()=>{const f=await fixture();f.after(()=>f.stale());assert.equal(await f.controller.paste(snapshot(),true),false);assert.equal(f.calls.filter(x=>x[1]==='replace').length,1);assert.equal(f.calls.some(x=>x[0]==='installed'),false);});
test('pasteboard read failure preserves text and frees busy state',async()=>{const f=await fixture();f.readFail();await assert.rejects(f.controller.paste(snapshot(),true));assert.equal(f.calls.some(x=>x[1]==='replace'),false);assert.equal(f.controller.busy,false);});
test('select all uses existing selection adapter',async()=>{const f=await fixture();assert(f.controller.selectAll(snapshot()));assert.equal(f.calls[0][1],'selectAll');assert.deepEqual(f.calls[1],['installed',1]);});
