// Execute the actual shared task and production shell callbacks under the
// recorded TextArea order. Controller readback before the text echo is stale.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {stripTypeScriptTypes} = require('node:module');
const root = path.resolve(__dirname, '../../../../../');
const shells = [
  process.env.PHAROS_INDEX || '/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets',
  path.join(root, 'labs/ohos_cjgui_app/entry/src/main/ets/pages/Index.ets'),
  path.join(root, 'labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets'),
];
function extract(source, marker) {
  const start = source.indexOf(marker), body = source.indexOf('{', start);
  assert.ok(start >= 0 && body >= 0, marker);
  let depth = 1, end = body + 1;
  for (; end < source.length && depth; end++) depth += (source[end] === '{') - (source[end] === '}');
  assert.equal(depth, 0, marker);
  return source.slice(start, end);
}
const proxy = fs.readFileSync(__dirname + '/../arkts/cjgui-text-proxy.ets', 'utf8');
const taskSource = extract(proxy, 'export class CjguiProxyInstallTask').replace('export class', 'class');
global.ProxyRestoreTask = new Function(stripTypeScriptTypes(taskSource, {mode:'transform'}) + ';return CjguiProxyInstallTask;')();
// R2/R3（2026-10-02）：页面选区安装改由共享类承担；fixture 注入**真实**
// CjguiImeSelectionLifecycle（seam 绑到本 fixture 的控制器与 native），
// 页面方法经 this.selectionLifecycle 消费它。
const lifecycleBundle = stripTypeScriptTypes(
  '(function(){\n' + proxy.replace(/export /g, '') + '\nreturn CjguiImeSelectionLifecycle;\n})()', {mode:'transform'});
const LifecycleClass = new Function('return ' + lifecycleBundle)();
global.DOMAIN = 0; global.TAG = 'test'; global.MenuPolicy = {HIDE:1};
// R3：内联 installProxySelection 已退役；页面方法集合不含它。
const methodNames = ['onMenuInstalled', 'onProxyTextChange', 'onProxySelectionChange', 'onProxyCaret',
  'armRestoreDeadline', 'beginSelectionPhase', 'observeSelection', 'ackProxyRestore'];
const base = '前行保留\nalpha beta😆 gamma\n末行保留';
const cut = '前行保留\n beta😆 gamma\n末行保留';

for (const filename of shells) {
  const source = fs.readFileSync(filename, 'utf8');
  // 缩进不敏感（Pharos/thermo 的方法缩进历史不一）。
  const methods = methodNames.map(n => extract(source, 'private ' + n + '(')).join('\n');
  const Shell = new Function(stripTypeScriptTypes('class Shell {\n' + methods + '\n}', {mode:'transform'}) + ';return Shell;')();
  function fixture(snapshot = {context:1,generation:2,text:cut,selStart:5,selEnd:5}) {
    const shell = new Shell(), calls = [], timers = [], mount = {
      key:{contextId:1,editGeneration:2,describe:()=>'m1'},fieldId:'body',draft:base,
    };
    let now = 0, text = base, current = true, actual = {start:5,end:5};
    Object.defineProperty(shell, 'imeText', {get:()=>text,set:v=>{text=v;calls.push(['assign',now,v]);}});
    const controller = {caretPosition:a=>{calls.push(['set',now,a,a]);actual={start:a,end:a};},
      setTextSelection:(a,b)=>{calls.push(['set',now,a,b]);actual={start:a,end:b};},
      getSelection:()=>{calls.push(['get',now,actual.start,actual.end]);return actual;}};
    Object.assign(shell, {imeMount:mount,imeCtx:1,proxyRestoreTask:null,
      proxyFocused:true,imeSelStart:5,imeSelEnd:10,
      proxyRegistry:{isCurrent:m=>current && m===mount,
        observeSelection:(m,a,b)=>calls.push(['observe',now,a,b]),
        hasTraffic:()=>false,
        onChange:(m,v)=>{calls.push(['preview',now,m.draft,v]);m.draft=v;return 'ok';}},
      imeTextController:controller});
    const napi = {imeEditingContext:()=>JSON.stringify(snapshot),
      imeSetSelection:(a,b,c)=>{calls.push(['forward',now,a,b,c]);return '0';},
      imeRestoreAck:(...a)=>{calls.push(['ack',now,...a]);return '0';}};
    global.entryNapi = napi;
    global.hilog = {info:(...a)=>calls.push(['info',now,...a]),warn:(...a)=>calls.push(['warn',now,...a]),error:(...a)=>calls.push(['error',now,...a])};
    // 真实共享生命周期：seam 只包 fixture 的事实（控制器/注册表/恢复占用）。
    const seam = {
      attachSession: () => Promise.resolve(),
      hasImeTrafficEvidence: () => false,
      readSelection: () => controller.getSelection(),
      setSelection: (a,b) => a===b ? controller.caretPosition(a) : controller.setTextSelection(a,b),
      commitInstalled: (a,b,c) => napi.imeSetSelection(a,b,c),
      isCurrentMount: m => current && m === mount,
      restoreTaskActive: () => shell.proxyRestoreTask !== null && !shell.proxyRestoreTask.terminal,
      logInfo(){}, logWarn(){},
    };
    shell.selectionLifecycle = new LifecycleClass(seam);
    // 页面的共享类薄委托（Pharos 以包装方法调用；thermo 直调，不受影响）。
    shell.requestProxyAttach = (m, r) => shell.selectionLifecycle.requestAttach(m, r);
    shell.maybeInstallSelection = (m, r) => shell.selectionLifecycle.maybeInstall(m, r);
    shell.settleSelection = (m, t, r) => shell.selectionLifecycle.settle(m, t, r);
    shell.armProxySelection = (m, s, e, r) => shell.selectionLifecycle.arm(m, s, e, r);
    const realTimeout = global.setTimeout;
    global.setTimeout = (fn,ms)=>{timers.push({at:now+ms,fn});return timers.length;};
    return {shell,mount,calls,selection:(a,b)=>{actual={start:a,end:b};},
      retire:()=>{current=false;},
      advance:deadline=>{while(timers.some(t=>t.at<=deadline)){timers.sort((a,b)=>a.at-b.at);const t=timers.shift();now=t.at;t.fn();}now=deadline;},
      close:()=>{global.setTimeout=realTimeout;}};
  }
  test(filename + ' menu waits for exact text echo and owns every caret entry', () => {
    const f = fixture();
    try {
      f.shell.onMenuInstalled(1); const task = f.shell.proxyRestoreTask;
      assert.equal(task.kind, 'menu'); assert.equal(task.request, 0); assert.equal(task.textObserved, false);
      // R3：恢复任务占用期间 caret 入口让路（不再有内联 installProxySelection；
      // 共享生命周期也不会被该入口签发新请求）。
      f.shell.onProxyCaret({context:1,selStart:5,selEnd:5});
      assert.equal(f.shell.selectionLifecycle.pendingMount(), null);
      f.shell.beginSelectionPhase(task); f.shell.observeSelection(task); // misleading old getter would equal target
      f.shell.onProxySelectionChange(f.mount,cut.length,cut.length); // pre-echo platform reset
      assert.equal(f.calls.some(c=>['set','get','forward','observe'].includes(c[0])),false);
      f.advance(100); f.selection(cut.length,cut.length);
      f.shell.onProxyTextChange(f.mount,cut);
      f.shell.onProxySelectionChange(f.mount,cut.length,cut.length); // component reset after echo
      assert.equal(f.calls.some(c=>c[0]==='forward'),false);
      f.advance(130);
      assert.equal(f.shell.proxyRestoreTask,null);
      assert.equal(task.terminal,true);
      assert.deepEqual(f.calls.filter(c=>c[0]==='set'),[['set',130,5,5]]);
      assert.ok(f.calls.filter(c=>c[0]==='get').every(c=>c[1]>=100));
      assert.deepEqual(f.calls.filter(c=>c[0]==='observe').at(-1),['observe',130,5,5]);
      assert.equal(f.calls.some(c=>c[0]==='ack'||c[0]==='preview'),false);
    } finally {f.close();}
  });
  test(filename + ' unchanged text select-all installs without waiting for nonexistent echo', () => {
    const f=fixture({context:1,generation:2,text:base,selStart:0,selEnd:base.length});
    try {f.shell.onMenuInstalled(1);assert.equal(f.shell.proxyRestoreTask,null);
      assert.equal(f.calls.some(c=>c[0]==='assign'),false);
      assert.deepEqual(f.calls.filter(c=>c[0]==='set'),[['set',0,0,base.length]]);
    } finally {f.close();}
  });
  test(filename + ' cut to empty forwards the observed collapsed selection without another component callback', () => {
    const f=fixture({context:1,generation:2,text:'',selStart:0,selEnd:0});
    try {f.shell.onMenuInstalled(1);f.selection(0,0);f.shell.onProxyTextChange(f.mount,'');
      f.shell.onProxySelectionChange(f.mount,0,0);f.advance(30);
      assert.equal(f.shell.proxyRestoreTask,null);assert.equal(f.mount.draft,'');
      assert.deepEqual(f.calls.filter(c=>c[0]==='forward'),[['forward',0,0,0,1]]);
      assert.equal(f.calls.some(c=>c[0]==='ack'||c[0]==='preview'),false);
    } finally {f.close();}
  });
  test(filename + ' first real text supersedes the installation and uses accepted menu text as baseline', () => {
    const f=fixture();
    try {f.shell.onMenuInstalled(1);const task=f.shell.proxyRestoreTask;
      f.shell.onProxyTextChange(f.mount,cut+'Q');
      assert.equal(task.terminal,true);assert.equal(f.shell.proxyRestoreTask,null);
      assert.deepEqual(f.calls.filter(c=>c[0]==='preview'),[['preview',0,cut,cut+'Q']]);
      assert.equal(f.mount.draft,cut+'Q');f.advance(1500);
      assert.equal(f.calls.some(c=>c[0]==='set'||c[0]==='ack'),false);
    } finally {f.close();}
  });
  test(filename + ' missing echo terminates and ordinary selection continues', () => {
    const f=fixture();
    try {f.shell.onMenuInstalled(1);const task=f.shell.proxyRestoreTask;f.advance(1500);
      assert.equal(task.terminal,true);assert.equal(f.shell.proxyRestoreTask,null);
      assert.equal(f.calls.some(c=>c[0]==='get'||c[0]==='ack'),false);
      f.shell.onProxySelectionChange(f.mount,2,2);
      assert.deepEqual(f.calls.filter(c=>c[0]==='forward'),[['forward',1500,2,2,1]]);
    } finally {f.close();}
  });
  test(filename + ' retired mount and replaced slot cannot be mutated by old timers', () => {
    const f=fixture();
    try {f.shell.onMenuInstalled(1);const old=f.shell.proxyRestoreTask;
      const newer={terminal:false};f.shell.proxyRestoreTask=newer;f.retire();
      f.shell.beginSelectionPhase(old);f.shell.observeSelection(old);f.advance(1500);
      assert.equal(f.shell.proxyRestoreTask,newer);assert.equal(f.calls.some(c=>['set','get','ack','forward'].includes(c[0])),false);
    } finally {f.close();}
  });
}
