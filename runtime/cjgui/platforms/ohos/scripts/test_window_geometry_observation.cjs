const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const {stripTypeScriptTypes}=require('node:module');
const source=fs.readFileSync(process.env.GEOMETRY_SRC||path.join(__dirname,'../arkts/cjgui-window-geometry.ets'),'utf8');
function fixture(enabled=false){
 let now=1000,mode=2,surfaceUnavailable=false;const handlers={},logs=[],published=[];
 const rect={size:{width:1320,height:1612},windowOffset:{x:0,y:136},screenOffset:{x:0,y:136}};
 const zero=()=>({left:0,top:0,width:0,height:0});
 let area={visible:true,leftRect:zero(),rightRect:zero(),topRect:zero(),bottomRect:{left:0,top:0,width:0,height:1010}};
 const win={on(k,fn){handlers[k]=fn;},off(k,fn){assert.equal(handlers[k],fn);delete handlers[k];},getWindowAvoidArea(){return area;},getWindowProperties(){return {windowRect:{left:0,top:136,width:1320,height:2622},id:7};}};
 const ui={getKeyboardAvoidMode(){return mode;},setKeyboardAvoidMode(v){mode=v;},getComponentUtils(){return {getRectangleById(){if(surfaceUnavailable)throw Error('component not laid out');return rect;}};}};
 const env={systemDateTime:{TimeType:{ACTIVE:1},getUptime(type,nano){assert.equal(nano,false);return now;}},window:{AvoidAreaType:{TYPE_KEYBOARD:3}},KeyboardAvoidMode:{NONE:0},hilog:{info(...a){logs.push(a);},warn(...a){logs.push(a);}},Date:{now(){return now;}}};vm.createContext(env);
 vm.runInContext(stripTypeScriptTypes(source.replace(/^import .*;\s*$/gm,''),{mode:'transform'}).replace(/export /g,'')+';globalThis.Geometry=CjguiWindowGeometry;',env);
 const model=new env.Geometry(ui,win,'owned_surface',n=>published.push(n),enabled);
 function observations(){const pending=new Map(),result=[];for(const l of logs){if(l[2]!=='geometry observation chunk seq=%{public}d part=%{public}d count=%{public}d %{public}s')continue;const [seq,part,count,payload]=l.slice(3);assert(payload.length<=160);let r=pending.get(seq);if(!r){r={count,parts:new Map()};pending.set(seq,r);}assert.equal(r.count,count);assert(!r.parts.has(part));r.parts.set(part,payload);if(r.parts.size===count){result.push(JSON.parse(Array.from({length:count},(_,i)=>r.parts.get(i)).join('')));pending.delete(seq);}}return result;}
 return{model,handlers,published,observations,rect,logs,begin(){model.beginObservation();},setArea(a){area=a;},setNow(v){now=v;},getMode(){return mode;},setSurfaceUnavailable(){surfaceUnavailable=true;}};
}
test('diagnostics are opt-in and have the same empty-area decision as normal mode',()=>{
 const f=fixture(false),g=fixture(true);assert.equal(f.published.at(-1),-1);assert.deepEqual(f.published,g.published);assert.equal(f.observations().length,0);
});
test('bounded observation freezes event payload separately from getter, surface and window',()=>{
 const f=fixture(true);assert.equal(f.observations().length,0,'startup does not consume the first-focus observation window');f.begin();
 const event={type:3,area:{visible:true,leftRect:{left:0,top:0,width:0,height:0},rightRect:{left:0,top:0,width:0,height:0},topRect:{left:0,top:0,width:0,height:0},bottomRect:{left:0,top:1750,width:1320,height:1106}}};
 f.handlers.keyboardHeightChange(1106);f.handlers.avoidAreaChange(event);
 const o=f.observations().at(-1);assert.equal(o.event,'avoidAreaChange');assert.equal(o.keyboardHeight,1106);assert.equal(o.eventArea.bottomRect.top,1750);assert.equal(o.getterArea.bottomRect.width,0);assert.equal(o.getterArea.bottomRect.height,1010);assert.equal(o.windowRect.top,136);assert.equal(o.surface.windowOffset.y,136);assert.equal(o.surface.size.height,1612);assert.equal(o.publishedTop,-1,'event keyboard starts below this already resized surface');assert.equal(o.geometryStatus,'no_intersection');
 event.area.bottomRect.top=9;f.rect.windowOffset.y=99;assert.equal(o.eventArea.bottomRect.top,1750);assert.equal(o.surface.windowOffset.y,136,'logged values cannot refer to later mutable SDK data');
});
test('observation has both a hard event count and original30s boundary',()=>{
 const f=fixture(true);f.begin();for(let i=0;i<100;i++)f.handlers.keyboardHeightChange(1010);
 assert.equal(f.observations().length,64);f.setNow(32000);f.handlers.keyboardHeightChange(0);assert.equal(f.observations().length,64);
 const g=fixture(true);g.setNow(31001);g.handlers.keyboardHeightChange(0);assert.equal(g.observations().length,0);g.begin();g.handlers.keyboardHeightChange(0);assert.equal(g.observations().length,1);g.setNow(61002);g.begin();g.handlers.keyboardHeightChange(7);assert.equal(g.observations().length,1,'actual first-focus deadline is not refreshed by later focus/events');
});
test('released original window callbacks cannot publish or log into a replacement lifetime',()=>{
 const f=fixture(true);f.begin();const old=f.handlers.avoidAreaChange;f.model.release();const n=f.published.length,c=f.observations().length;old({type:4,area:{}});assert.equal(f.published.length,n);assert.equal(f.observations().length,c);assert.equal(f.getMode(),2);
});

test('oversized metadata is explicitly unavailable rather than partial JSON evidence',()=>{
 const f=fixture(true);f.begin();f.handlers.keyboardHeightChange(1);assert.equal(f.observations().length,1);f.rect.windowOffset.extra='x'.repeat(9000);f.handlers.keyboardHeightChange(7);assert.equal(f.observations().length,1);assert(f.logs.some(l=>l.at(-1)==='metadata_over_budget'));
});

function areaWith(bottom, others={}) {
 const empty=()=>({left:0,top:0,width:0,height:0});
 return {visible:true,leftRect:empty(),rightRect:empty(),topRect:empty(),bottomRect:bottom,...others};
}
test('zero-area and horizontally nonintersecting rectangles cannot erase the surface band',()=>{
 const f=fixture();
 for(const bottom of [{left:0,top:0,width:0,height:1010},{left:1400,top:0,width:200,height:2856},{left:0,top:0,width:1320,height:0}]) {
  f.setArea(areaWith(bottom));f.model.report();assert.equal(f.published.at(-1),-1);
 }
});
test('legitimate full occlusion retains zero, then an explicit empty area clears it',()=>{
 const f=fixture();f.setArea(areaWith({left:0,top:0,width:1320,height:2856}));f.model.report();assert.equal(f.published.at(-1),0);
 f.setArea(areaWith({left:0,top:0,width:0,height:0}));f.model.report();assert.equal(f.published.at(-1),-1);
});
test('window-local origin and fractional bottom are converted once; already resized surface is clear',()=>{
 const f=fixture();f.rect.windowOffset={x:100,y:200};f.rect.screenOffset={x:300,y:500};f.rect.size={width:600,height:1000};
 f.setArea(areaWith({left:100,top:900.75,width:600,height:300}));f.model.report();assert.equal(f.published.at(-1),700);
 f.rect.size.height=700;f.model.report();assert.equal(f.published.at(-1),-1,'keyboard starts beyond resized surface, do not subtract height twice');
});
test('keyboard event owns its payload; a different avoid-area type does not resample stale keyboard getter',()=>{
 const f=fixture();const a=areaWith({left:0,top:1500,width:1320,height:1356});
 f.handlers.avoidAreaChange({type:3,area:a});assert.equal(f.published.at(-1),1364);
 const n=f.published.length;f.handlers.avoidAreaChange({type:0,area:areaWith({left:0,top:0,width:0,height:0})});assert.equal(f.published.length,n);
});
test('top/side or partial-width occlusion is not silently converted to a full-width bottom cut',()=>{
 const f=fixture();for(const a of [areaWith({left:0,top:0,width:0,height:0},{topRect:{left:0,top:136,width:1320,height:200}}),areaWith({left:400,top:1500,width:200,height:1356})]) {
  f.setArea(a);const n=f.published.length;f.model.report();assert.equal(f.published.length,n,'single bottom-band representation does not describe this shape');
 }
});
test('missing/nonfinite rectangle and unavailable surface are unknown, not a clear/full occlusion fact',()=>{
 const f=fixture();for(const a of [areaWith({left:0,top:NaN,width:1320,height:2856}),areaWith({left:0,top:0,width:1320,height:2856},{topRect:null})]) {
  f.setArea(a);const n=f.published.length;f.model.report();assert.equal(f.published.length,n);
 }
 f.setArea(areaWith({left:0,top:0,width:1320,height:2856}));f.rect.size.width=0;const n=f.published.length;f.model.report();assert.equal(f.published.length,n);
});
test('component not laid out does not crash a real geometry callback or publish fabricated visibility',()=>{
 const f=fixture();f.setArea(areaWith({left:0,top:0,width:1320,height:2856}));f.setSurfaceUnavailable();const n=f.published.length;
 assert.doesNotThrow(()=>f.handlers.keyboardHeightChange(1000));assert.equal(f.published.length,n);
});
