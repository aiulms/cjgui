// R3（h-source-preview-followup 2026-10-02）：消费者 seam 契约测试。
// 从 Pharos 与 thermo 两个页面**原样提取**各自的 CjguiImeSelectionHost 实现，
// 与框架模板 CjguiImeSelectionLifecycle 组装，验证同一共享类被两个消费者
// 真实消费（不是页面各自留一份状态机）：
//   1 positive：attach ok → 两帧确认 → INSTALLED + native rc=0；
//   2 hang：attach 永不回调 → 固定截止 UNCONFIRMED，零 native 调用；
//   3 证据按挂载：正文 A 的输入流不给备注 B 开门（页面 seam 必须经注册表
//     按挂载查询，不得回退页面级布尔）；
//   4 native 拒绝（rc=1）不得记 INSTALLED。
// 只控制平台响应；不构建 HAP、不触设备。
const fs = require('fs'), vm = require('vm'), mod = require('node:module');
const crypto = require('crypto');
const frameworkPath = __dirname + '/../arkts/cjgui-text-proxy.ets';
const consumers = [
  ['pharos', '/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets',
    'class PharosImeSelectionHost '],
  ['thermo', '/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets',
    'class ThermoImeSelectionHost '],
];

function extractHost(pagePath, marker) {
  const src = fs.readFileSync(pagePath, 'utf8');
  const at = src.indexOf(marker);
  if (at < 0) throw Error('host class not found in ' + pagePath);
  // 类体到大括号闭合（列 0 的 '}'）。
  let depth = 0, end = -1;
  for (let i = src.indexOf('{', at); i < src.length; ++i) {
    if (src[i] === '{') depth += 1;
    else if (src[i] === '}') { depth -= 1; if (depth === 0) { end = i + 1; break; } }
  }
  if (end < 0) throw Error('host class unterminated in ' + pagePath);
  return { host: src.slice(at, end), sha: crypto.createHash('sha256').update(src).digest('hex') };
}

const framework = fs.readFileSync(frameworkPath, 'utf8');
const results = { sources: {} };

async function runConsumer(name, pagePath, marker) {
  const { host: hostSource, sha } = extractHost(pagePath, marker);
  results.sources[pagePath] = sha;
  let now = 0, serial = 0;
  let timers = [];
  const logs = [], nativeCalls = [];
  const aMount = { fieldId: 'A-body', key: { contextId: 21, describe() { return 's1/c21/m1'; } } };
  const mount = { fieldId: 'B-note', key: { contextId: 22, describe() { return 's1/c22/m2'; } } };
  let selection = { start: 1, end: 3 };
  const registry = {
    _traffic: new Set([aMount]),   // 正文 A 有输入流；备注 B 没有
    hasTraffic(m) { return this._traffic.has(m); },
    isCurrent(m) { return m === mount; },
    observeSelection() {},
  };
  const page = {
    imeTextController: {
      getSelection() { return { ...selection }; },
      caretPosition(n) { selection = { start: n, end: n }; },
      setTextSelection(s, e) { selection = { start: s, end: e }; },
    },
    imeMount: mount, proxyRegistry: registry, proxyRestoreTask: null,
    imeSelStart: -1, imeSelEnd: -1,
  };
  let attachBehavior = 'ok';
  const env = {
    inputMethod: { getController() { return { showTextInput() {
      if (attachBehavior === 'hang') return new Promise(() => {});
      return Promise.resolve();
    } }; } },
    entryNapi: { imeSetSelection(start, end, contextId) {
      const rc = attachBehavior === 'native-reject' ? '1' : '0';
      nativeCalls.push({ start, end, contextId, rc });
      return rc;
    } },
    MenuPolicy: { HIDE: 0 }, DOMAIN: 0, TAG: 'seam',
    hilog: { info() {}, warn() {} },
    setTimeout(fn, delay) { const id = ++serial; timers.push({ id, due: now + (delay || 0), fn }); return id; },
    clearTimeout(id) { timers = timers.filter(t => t.id !== id); },
  };
  vm.createContext(env);
  const executable = mod.stripTypeScriptTypes(framework + '\n' + hostSource, { mode: 'transform' })
    .replace(/export /g, '');
  vm.runInContext(executable + '\nglobalThis.LC=CjguiImeSelectionLifecycle;', env);
  const hostClass = vm.runInContext(
    "typeof PharosImeSelectionHost !== 'undefined' ? PharosImeSelectionHost : ThermoImeSelectionHost", env);

  const advance = async (ms) => {
    const target = now + ms;
    for (let guard = 0; guard < 5000; guard++) {
      for (let i = 0; i < 8; i++) await Promise.resolve();
      timers.sort((x, y) => x.due - y.due || x.id - y.id);
      const next = timers[0];
      if (!next || next.due > target) break;
      now = Math.max(now, next.due);
      timers.shift();
      next.fn();
    }
    now = Math.max(now, target);
  };
  // 每个用例独立的 lifecycle 实例与页面账目（attach 是会话级事实，跨用例
  // 复用会让 hang 用例借到已建立的会话）。
  const freshLifecycle = () => {
    page.imeSelStart = -1; page.imeSelEnd = -1;
    return new env.LC(new hostClass(page));
  };
  const cases = {};
  // 1 positive
  let lifecycle = freshLifecycle();
  lifecycle.arm(mount, 1, 3, 'positive');
  lifecycle.requestAttach(mount, 'positive');
  await advance(5000);
  cases.positive = { terminal: lifecycle.terminal(), native: nativeCalls.length,
    rc: nativeCalls[0] ? nativeCalls[0].rc : null };
  // 2 hang：attach 永不回调 → 固定截止
  attachBehavior = 'hang';
  nativeCalls.length = 0;
  lifecycle = freshLifecycle();
  lifecycle.arm(mount, 2, 4, 'hang');
  lifecycle.requestAttach(mount, 'hang');
  await advance(9000);
  cases.hang = { terminal: lifecycle.terminal(), pending: lifecycle.pendingMount() === mount,
    native: nativeCalls.length, timers_left: timers.length };
  // 3 证据按挂载（A 有流量，B 无）：直接查询 seam 的证据实现。
  const hostInstance = new hostClass(page);
  cases.evidence = { a: hostInstance.hasImeTrafficEvidence(aMount),
    b: hostInstance.hasImeTrafficEvidence(mount) };
  // 4 native 拒绝
  attachBehavior = 'native-reject';
  nativeCalls.length = 0;
  lifecycle = freshLifecycle();
  lifecycle.arm(mount, 1, 3, 'reject');
  lifecycle.requestAttach(mount, 'reject');
  await advance(5000);
  cases.native_reject = { terminal: lifecycle.terminal(), native: nativeCalls.length,
    recorded: page.imeSelStart === 1 && page.imeSelEnd === 3 };
  // 清理：耗尽剩余计时器
  await advance(20000);
  return { name, cases, timers_left: timers.length, logs };
}

(async () => {
  for (const [name, path, marker] of consumers) {
    results[name] = await runConsumer(name, path, marker);
  }
  const ok = (r) =>
    r.cases.positive.terminal === 'INSTALLED' && r.cases.positive.rc === '0' &&
    r.cases.hang.terminal === 'UNCONFIRMED' && !r.cases.hang.pending &&
    r.cases.hang.native === 0 && r.cases.hang.timers_left === 0 &&
    r.cases.evidence.a === true && r.cases.evidence.b === false &&
    r.cases.native_reject.terminal === 'UNCONFIRMED' &&
    r.cases.native_reject.native === 1 && r.cases.native_reject.recorded === false &&
    r.timers_left === 0;
  results.verdict = { pharos: ok(results.pharos), thermo: ok(results.thermo) };
  const outDir = __dirname + '/../../../artifacts/h-seam-consumers-20261002';
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(outDir + '/result.json', JSON.stringify(results, null, 2) + '\n');
  console.log(JSON.stringify({ verdict: results.verdict,
    pharos: results.pharos.cases, thermo: results.thermo.cases }, null, 1));
  process.exitCode = results.verdict.pharos && results.verdict.thermo ? 0 : 1;
})().catch(err => { console.error(err); process.exitCode = 1; });
