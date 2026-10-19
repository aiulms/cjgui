// Execute actual consumer seams and the shared registry. Native scheduling,
// snapshots, component disappearance and mount are controlled; no SDK ACK claim.
const fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const {stripTypeScriptTypes} = require('node:module');
const frameworkPath = process.env.PROXY_SRC || path.join(__dirname, '../arkts/cjgui-text-proxy.ets');
const framework = fs.readFileSync(frameworkPath, 'utf8').replace(/^import .*;\s*$/gm, '');
const consumers = {
  thermo: path.resolve(__dirname, '../../../../../labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets'),
  pharos: '/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets',
};

function method(source, name) {
  const at = source.indexOf(`  private ${name}(`);
  if (at < 0) return '';
  const end = source.indexOf('\n  private ', at + 1);
  return source.slice(at, end < 0 ? source.length : end);
}

function run(pageSource, scenario) {
  const methods = ['onReconcileRequest', 'onProxyDisappeared', 'mountPendingReconcile']
    .map(name => method(pageSource, name)).join('\n');
  let tasks = [], messages = [], mounts = [], nativeContext = 20, nativeOperation = 1, eligible = true;
  let snap = {context: 20, generation: 3, focusGeneration: 1, baseVersion: 4,
              nodeId: 107, field: 'body', sessionToken: 1};
  const env = {FrameCallback: class {}, DOMAIN: 0, TAG: 'owned',
    setTimeout(fn, milliseconds) {if (milliseconds !== 0) throw Error('no fixed-time repair'); tasks.push(fn); return tasks.length;},
    hilog: {info(...args) {messages.push(args.slice(2));}},
  };
  vm.createContext(env);
  const code = stripTypeScriptTypes(`${framework}\nclass Consumer {${methods}}\nglobalThis.API={Registry:CjguiTextProxyRegistry,Consumer};`, {mode:'transform'}).replace(/export /g, '');
  vm.runInContext(code, env);
  const registry = new env.API.Registry({logInfo(){}, logWarn(){},closeSelectionCommandCapture(){return "0";},
    focusAuthority(key, op, generation, target, edit) {
      if (!eligible || key.appInstance !== 7 || key.sessionToken !== 1 || key.contextId !== 10) return '0';
      if (op === 3 || op === 5) return generation === 1 && target === nativeContext && edit === 3 ? String(nativeOperation) : '0';
      return '1';
    }});
  const old = registry.mount(10, 3, 'owned-A', 'body', 7, 1, 'before', 1);
  if (registry.retireForReconcile(old, 10, 20, 3, 1) !== 'retired') throw Error('original structure not registered');
  const page = new env.API.Consumer();
  Object.assign(page, {pendingReconcile: {oldMount: old, newContext: 20, targetGeneration: 3,
    baseVersion: 4, nodeId: 107, sessionToken: 1, appInstance: 7, disappeared: false, targetField: 'body'},
    proxyRegistry: registry, imeMount: null, supersededMount: null, imeCtx: 0, mountedNodeId: 0, mountedBaseVersion: 0,
    proxyFocused: false, readLiveEditingSnapshot() {return snap;}, readHostAppInstance() {return scenario === 'wrong-app' ? 8 : 7;},
    mountEditingSnapshot(value) {mounts.push({...value}); this.imeCtx = value.context;},
  });
  page.onProxyDisappeared(old);
  function next(context = 21) {nativeContext = context; nativeOperation++; snap = {...snap, context, baseVersion: context - 16};}
  function flush() {const now = tasks; tasks = []; for (const job of now) job();}
  next();
  if (scenario === 'wrong-field') snap.field = 'other';
  if (scenario === 'Back') eligible = false;
  if (scenario === 'notify-first' || scenario === 'duplicate' || scenario === 'closed' || scenario === 'C-then-D') {
    page.onReconcileRequest(10, 21);
    if (scenario === 'duplicate') page.onReconcileRequest(10, 21);
    if (scenario === 'closed') page.pendingReconcile = null;
    if (scenario === 'C-then-D') {next(22); flush(); page.onReconcileRequest(10, 22);}
  } else {
    flush();
    if (scenario !== 'no-implicit-latest') page.onReconcileRequest(10, 21);
  }
  flush();
  return {scenario, contexts: mounts.map(m => m.context), messages, pending: page.pendingReconcile !== null,
          tasks: tasks.length, scope: 'actual methods/common registry; native and component seams controlled'};
}

const expected = {'notify-late': [21], 'notify-first': [21], duplicate: [21], 'C-then-D': [22],
                  'wrong-app': [], 'wrong-field': [], Back: [], closed: [], 'no-implicit-latest': []};
const result = {};
let ok = true;
for (const [consumer, file] of Object.entries(consumers)) {
  const source = fs.readFileSync(file, 'utf8');
  result[consumer] = {};
  for (const [scenario, contexts] of Object.entries(expected)) {
    const value = run(source, scenario);
    value.ok = JSON.stringify(value.contexts) === JSON.stringify(contexts) && value.tasks === 0;
    result[consumer][scenario] = value;
    ok &&= value.ok;
  }
}
// The common owner itself must deduplicate one registered operation and retire
// its queued job on target replacement or Back, even without consumer guards.
const commonCases = {};
for (const scenario of ['same-operation', 'replaced-before-turn', 'Back-before-turn']) {
  let tasks = [], runs = 0, target = 20, operation = 1, eligible = true;
  const env = {FrameCallback: class {}, setTimeout(fn, ms) {if (ms !== 0) throw Error('fixed wait'); tasks.push(fn);}};
  vm.createContext(env);
  vm.runInContext(stripTypeScriptTypes(framework, {mode:'transform'}).replace(/export /g, '') + '\nglobalThis.Registry=CjguiTextProxyRegistry;', env);
  const registry = new env.Registry({logInfo(){},logWarn(){},focusAuthority(key, op, generation, context) {
    return op === 1 ? '1' : eligible && context === target ? String(operation) : '0';
  }});
  const m = registry.mount(10, 3, 'A', 'body', 7, 1, 'before');
  registry.retireForReconcile(m, 10, target, 3, 1);
  registry.scheduleReconcileTarget(m, target, 3, () => runs++);
  registry.scheduleReconcileTarget(m, target, 3, () => runs++);
  if (scenario === 'replaced-before-turn') {target = 21; operation = 2;}
  if (scenario === 'Back-before-turn') eligible = false;
  for (const fn of tasks) fn();
  const passed = runs === (scenario === 'same-operation' ? 1 : 0);
  commonCases[scenario] = {runs, queued: tasks.length, ok: passed};
  ok &&= passed;
}
if (process.env.RESULT_PATH) fs.writeFileSync(process.env.RESULT_PATH, JSON.stringify({ok, result, commonCases}, null, 2) + '\n');
console.log(JSON.stringify({ok, cases: Object.values(result).reduce((n,c) => n + Object.keys(c).length, 0) + Object.keys(commonCases).length,
                          failed: Object.entries(result).flatMap(([consumer,cases]) => Object.values(cases).filter(v => !v.ok).map(v => `${consumer}:${v.scenario}`))}));
process.exitCode = ok ? 0 : 2;
