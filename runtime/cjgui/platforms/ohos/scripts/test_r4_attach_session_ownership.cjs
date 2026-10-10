// R4（2026-10-02 Astra 裁决）共享生命周期 attach 会话所有权回归。
//
// 直接驱动框架类 CjguiImeSelectionLifecycle（arkts/cjgui-text-proxy.ets），
// 虚拟时钟 + 手动可控 attach Promise（resolve/reject 由用例决定）。
//
// 背景：attach（showTextInput 会话）是**会话级事实**，其发起/确立只应依赖挂载
// 身份，不与 pending 选区耦合。此前 requestAttach 的 `selMount !== mount` 门 +
// then() 的 `selMount === mount` 判据，会让「恢复让位（settle 清 selMount）」之后
// 的焦点 attach 永久静默早退，笔记面实际以 8s request_deadline 收口（设备 trace）。
//
// 判例（每条都能区分修复前后；旧逻辑的失败点写在断言旁）：
//  R4a 让位后焦点 attach 仍建立会话 → 后续 caret arm 精确 INSTALLED（旧：门①早退→死等到截止）；
//  R4b pending 时 attach 在飞 → 让位清 pending → attach 成功仍置 attached（旧：then 判 stale→不置位）；
//  R4c 让位后 12800009 且有本挂载流量证据 → 无 pending 也沿用会话置 attached（旧：currentRequest false→跳过）；
//  R4d 重试票据归属：旧尝试的重试不得抢占更新的在飞成功（旧：++attachSeq→新成功被误判 stale）；
//  R4e 同一 (mount,seq) 平台 setter 只下发一次（防 arm 与随后 requestAttach 各进一次 install）；
//  R4f 有 pending 的真实 attach 失败仍准确结算一次（保持既有语义，不因解耦而漏结算）；
//  R4g 身份失效：挂载不再是 current 时，迟到的 attach 成功不得置 attached。
const fs = require('fs'), vm = require('vm'), mod = require('node:module');
const path = require('path');

const SRC = process.env.PROXY_SRC ||
  path.join(__dirname, '..', 'arkts', 'cjgui-text-proxy.ets');

const timers = [];
let now = 0, timerSerial = 0;
const env = {};
env.setTimeout = (fn, delay) => {
  const id = ++timerSerial;
  timers.push({ id, due: now + (delay || 0), fn });
  return id;
};
env.clearTimeout = (id) => {
  const at = timers.findIndex(t => t.id === id);
  if (at >= 0) timers.splice(at, 1);
};
vm.createContext(env);
const src = mod.stripTypeScriptTypes(fs.readFileSync(SRC, 'utf8'), { mode: 'transform' });
vm.runInContext(src.replace(/export /g, '') + ';globalThis.LC=CjguiImeSelectionLifecycle;', env);

const mountOf = (name) => ({ fieldId: name, key: { contextId: 7, describe() { return 'c7/' + name; } } });
const flushMicrotasks = async () => { for (let i = 0; i < 8; i++) await Promise.resolve(); };
async function advance(deltaMs) {
  const target = now + deltaMs;
  for (let guard = 0; guard < 5000; guard++) {
    await flushMicrotasks();
    timers.sort((a, b) => a.due - b.due || a.id - b.id);
    const next = timers[0];
    if (!next || next.due > target) break;
    now = Math.max(now, next.due);
    timers.shift();
    next.fn();
  }
  now = Math.max(now, target);
}
// 可控 attach：Promise 的 resolve/reject 由用例显式触发（模拟 attach 在飞/迟到）。
function makeCtl(opts) {
  opts = opts || {};
  const st = {
    resolvers: [], rejectors: [], installs: 0, commits: 0, attachCalls: 0,
    readback: { start: opts.initStart !== undefined ? opts.initStart : 1,
                end: opts.initEnd !== undefined ? opts.initEnd : 3 },
    logs: [],
  };
  let current = opts.mount;
  const h = {
    attachSession() {
      st.attachCalls += 1;
      return { then(fn) { st.resolvers.push(fn); return { catch(cb) { st.rejectors.push(cb); } }; } };
    },
    hasImeTrafficEvidence(m) { return !!(opts.trafficMounts && opts.trafficMounts.has(m)); },
    readSelection() {
      if (opts.getterThrows) throw new Error('boom');
      if (opts.getter === 'mismatch') return { start: 0, end: 0 };
      return { start: st.readback.start, end: st.readback.end };
    },
    setSelection(s, e) { st.installs += 1; st.readback = { start: s, end: e }; },
    commitInstalled() { st.commits += 1; return opts.commitRc !== undefined ? opts.commitRc : '0'; },
    isCurrentMount(m) { return opts.isCurrent ? opts.isCurrent(m) : m === current; },
    restoreTaskActive() { return !!opts.restoreActive; },
    logInfo(msg) { st.logs.push('I:' + msg); },
    logWarn(msg) { st.logs.push('W:' + msg); },
  };
  return {
    h, st,
    setCurrent(m) { current = m; },
    resolveAll() { for (const f of st.resolvers.splice(0)) f(); },
    rejectAll(err) { for (const f of st.rejectors.splice(0)) f(err); },
    logged(pred) { return st.logs.some(pred); },
  };
}
function armHost(mount, opts) {
  const ctl = makeCtl(Object.assign({ mount }, opts || {}));
  return { ctl, lc: new env.LC(ctl.h) };
}
const results = {};

(async () => {
// R4a：恢复让位清 pending → 焦点 attach 仍建立会话 → 后续 caret arm 精确 INSTALLED。
{
  const mount = mountOf('r4a');
  const { ctl, lc } = armHost(mount);
  lc.arm(mount, 1, 3, 'mount');
  lc.settle(mount, 'UNCONFIRMED', 'restore_task_took_over');   // 让位：清 pending
  lc.requestAttach(mount, 'focus');                            // 旧：门①（selMount null）早退
  ctl.resolveAll();                                            // attach 成功
  const attachedAfterFocus = lc.isAttachedTo(mount);
  lc.arm(mount, 0, 2, 'caret');                                // 后续 caret 请求
  lc.requestAttach(mount, 'caret');
  await advance(9000);
  results.r4a = { attached_after_focus: attachedAfterFocus,
    terminal: lc.terminal(), installs: ctl.st.installs, commits: ctl.st.commits,
    timers_left: timers.length };
}
// R4b：pending 时 attach 在飞 → 让位清 pending → attach 成功仍置 attached（Astra 核心反例）。
{
  const mount = mountOf('r4b');
  const { ctl, lc } = armHost(mount);
  lc.arm(mount, 1, 3, 'b');
  lc.requestAttach(mount, 'b');                                // attach 在飞（resolver 未触发）
  const inFlight = ctl.st.attachCalls === 1;
  lc.settle(mount, 'UNCONFIRMED', 'restore_task_took_over');   // 让位：清 pending
  ctl.resolveAll();                                            // 迟到成功：旧 then 判 stale→不置位
  const attachedAfterLateSuccess = lc.isAttachedTo(mount);
  lc.arm(mount, 2, 5, 'b2');                                   // 后续新请求应能安装
  lc.requestAttach(mount, 'b2');
  await advance(9000);
  results.r4b = { in_flight: inFlight, attached_after_late_success: attachedAfterLateSuccess,
    terminal: lc.terminal(), installs: ctl.st.installs, timers_left: timers.length };
}
// R4c：让位后 12800009 且有本挂载流量证据 → 无 pending 也沿用会话置 attached。
{
  const mount = mountOf('r4c');
  const { ctl, lc } = armHost(mount, { trafficMounts: new Set([mount]) });
  lc.arm(mount, 1, 3, 'c');
  lc.requestAttach(mount, 'c');
  lc.settle(mount, 'UNCONFIRMED', 'restore_task_took_over');
  ctl.rejectAll({ code: 12800009 });                           // 旧：currentRequest false→整段跳过
  await advance(9000);
  results.r4c = { attached: lc.isAttachedTo(mount), installs: ctl.st.installs,
    timers_left: timers.length };
}
// R4c2：让位后 12800009 且**无**流量证据 → 有界重试耗尽后只记录会话未恢复，
//       不得给已让位的旧选区追加终态（settle 无入口守卫）。
{
  const mount = mountOf('r4c2');
  const { ctl, lc } = armHost(mount);
  lc.arm(mount, 1, 3, 'c2');
  lc.requestAttach(mount, 'c2');
  lc.settle(mount, 'UNCONFIRMED', 'restore_task_took_over');
  const terminalsBefore = ctl.logged(s => s.includes('terminal=UNCONFIRMED reason=restore_task_took_over'));
  for (let round = 0; round < 30 && lc.terminal() === 'UNCONFIRMED'; round++) {
    ctl.rejectAll({ code: 12800009 });
    await advance(1000);
  }
  await advance(9000);
  results.r4c2 = { attached: lc.isAttachedTo(mount),
    spurious_terminal: ctl.logged(s => s.includes('attach_reused_without_evidence') ||
      s.includes('attach_rejected')),
    unrecovered_logged: ctl.logged(s => s.includes('attach unrecovered')),
    saw_restore_terminal: terminalsBefore, timers_left: timers.length };
}
// R4d：重试票据归属——旧尝试的重试不得抢占更新的在飞成功。
{
  const mount = mountOf('r4d');
  const { ctl, lc } = armHost(mount);
  lc.arm(mount, 1, 3, 'd');
  lc.requestAttach(mount, 'd');                                // attachSeq=1 在飞
  ctl.rejectAll({ code: 12800009 });                           // 无证据→排一次重试（retrySeq=1）
  lc.requestAttach(mount, 'focus2');                           // 新尝试 attachSeq=2 在飞
  await advance(400);                                          // 旧重试到期：旧：++attachSeq→杀 seq2
  ctl.resolveAll();                                            // 解决当前在飞的成功
  const attached = lc.isAttachedTo(mount);
  await advance(200);
  results.r4d = { attached, attach_calls: ctl.st.attachCalls, timers_left: timers.length };
}
// R4e：同一 (mount,seq) 平台 setter 只下发一次。
{
  const mount = mountOf('r4e');
  const { ctl, lc } = armHost(mount);
  lc.arm(mount, 1, 3, 'e');
  lc.requestAttach(mount, 'e');                                // 未 attached→发起 attach
  ctl.resolveAll();                                            // attached→maybeInstall→install(seq1)
  lc.requestAttach(mount, 'e-dup');                            // 同 seq 再进 install→应被守卫挡住
  await advance(9000);
  results.r4e = { installs: ctl.st.installs, terminal: lc.terminal(), timers_left: timers.length };
}
// R4f：有 pending 的真实 attach 失败仍准确结算一次（既有语义保持）。
{
  const mount = mountOf('r4f');
  const { ctl, lc } = armHost(mount);
  lc.arm(mount, 1, 3, 'f');
  lc.requestAttach(mount, 'f');
  ctl.rejectAll({ code: 12900000 });
  await advance(9000);
  results.r4f = { terminal: lc.terminal(), pending: lc.pendingMount() === mount,
    installs: ctl.st.installs, timers_left: timers.length };
}
// R4g：身份失效——迟到 attach 成功不得置 attached。
{
  const a = mountOf('r4g-a'), b = mountOf('r4g-b');
  const { ctl, lc } = armHost(a);
  lc.arm(a, 1, 3, 'g');
  lc.requestAttach(a, 'g');
  ctl.setCurrent(b);                                           // 换挂载
  ctl.resolveAll();
  await advance(9000);
  results.r4g = { attached_stale: lc.isAttachedTo(a), timers_left: timers.length };
}

console.log(JSON.stringify(results, null, 1));
const ok = (c, m) => { if (!c) { console.error('FAIL: ' + m); return 1; } return 0; };
let fail = 0;
fail += ok(results.r4a.attached_after_focus === true, 'r4a attached after restore-takeover+focus');
fail += ok(results.r4a.terminal === 'INSTALLED' && results.r4a.installs >= 1 && results.r4a.commits === 1,
  'r4a subsequent caret arm installs exactly');
fail += ok(results.r4a.timers_left === 0, 'r4a no timers left');
fail += ok(results.r4b.in_flight === true, 'r4b attach was in flight');
fail += ok(results.r4b.attached_after_late_success === true, 'r4b late success keeps attached');
fail += ok(results.r4b.terminal === 'INSTALLED', 'r4b new request installs');
fail += ok(results.r4b.timers_left === 0, 'r4b no timers left');
fail += ok(results.r4c.attached === true, 'r4c 12800009+traffic reuse without pending');
fail += ok(results.r4c.timers_left === 0, 'r4c no timers left');
fail += ok(results.r4c2.attached === false, 'r4c2 not attached without evidence');
fail += ok(results.r4c2.spurious_terminal === false, 'r4c2 no spurious selection terminal');
fail += ok(results.r4c2.unrecovered_logged === true, 'r4c2 logs session unrecovered');
fail += ok(results.r4c2.timers_left === 0, 'r4c2 no timers left');
fail += ok(results.r4d.attached === true, 'r4d newer in-flight success preserved');
fail += ok(results.r4d.attach_calls === 2, 'r4d stale retry did not start a third attach');
fail += ok(results.r4e.installs === 1, 'r4e same-seq setter sent once');
fail += ok(results.r4e.timers_left === 0, 'r4e no timers left');
fail += ok(results.r4f.terminal === 'UNCONFIRMED' && results.r4f.pending === false && results.r4f.installs === 0,
  'r4f pending failure settles exactly once');
fail += ok(results.r4f.timers_left === 0, 'r4f no timers left');
fail += ok(results.r4g.attached_stale === false, 'r4g stale success does not attach');
fail += ok(results.r4g.timers_left === 0, 'r4g no timers left');
process.exitCode = fail ? 1 : 0;
})().catch(err => { console.error(err); process.exitCode = 1; });
