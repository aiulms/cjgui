#!/usr/bin/env node
// Execute the production proxy construction chain before its event callbacks.
const fs=require('fs'), assert=require('assert'), vm=require('vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/arktsdoc/node_modules/typescript');
const file='labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets';
function run(withdraw=false){
 let source=fs.readFileSync(file,'utf8');let start=source.indexOf('proxyTextInput(m:');
 let a=source.indexOf('TextInput({',start),b=source.indexOf('.onAppear(',a);
 let chain=source.slice(a,b);
 if(withdraw)chain=chain.replace('.hitTestBehavior(HitTestMode.None)','').replace('.focusOnTouch(false)','.focusOnTouch(true)');
 const calls={};const fluent=new Proxy({}, {get:(_,name)=>(value)=>{calls[name]=value;return fluent;}});
 const context={TextInput:()=>fluent,HitTestMode:{None:2},page:{imeText:'A\nB',imeX:36,imeY:310,imeW:305,imeH:934}};
 const code=ts.transpileModule(`function build(m:any){${chain};} build.call(page,{controlId:'owned'});`,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText;
 vm.runInNewContext(code,context);
 assert.equal(calls.focusable,true,'proxy must remain programmatically focusable');
 assert.equal(calls.focusOnTouch,false,'transparent proxy stole normal pointer focus');
 assert.equal(calls.hitTestBehavior,2,'transparent proxy stole CJGUI gesture');
 console.log('PASS production thermo proxy forwards pointer to CJGUI while keeping IME focus');
}
run(process.argv.includes('--withdraw-only'));if(process.argv.includes('--selftest')){let red=false;try{run(true);}catch(e){red=true;console.log('PASS isolated withdrawal RED:',e.message);}assert(red,'withdrawal stayed green');}
