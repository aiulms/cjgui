// S2/R2 共享生命周期正典回归（h-source-preview-followup 2026-10-02）。
// 直接驱动框架类 CjguiImeSelectionLifecycle（arkts/cjgui-text-proxy.ets）。
// 虚拟时钟（按 due 触发）替代真实延时；attach 用同步 thenable，无需事件循环。
//
// 判例（旧 harness 的共享 rejects 数组跨 case 泄漏已修复：每个 case 只触发
// 自己捕获的旧 Promise）：
//  1 成功链：arm→attach ok→install→两帧确认→INSTALLED + commit(rc=0) 一次；
//  2 确认窗 getter 抛异常→UNCONFIRMED（不 pending 挂死、无残留定时器）；
//  3 12800009（当前序号）无输入流证据→不开门；退避重试耗尽才 UNCONFIRMED；
//  4 同码**本挂载**有证据→开门沿用既有会话并安装；
//  5 确认失配→UNCONFIRMED 终态（不重置预算重投）；
//  6 旧 attach 序号的迟到失败不得为新请求开门（本 case 自己的旧 Promise）；
//  7 非 12800009 的 attach 拒绝→有界终态（不开门、UNCONFIRMED、无残留定时器）；
//  8 attach 永不回调→固定截止终结（UNCONFIRMED、无残留定时器、零 native 调用）；
//  9 证据按挂载隔离：A 有输入流不能给 B 的 12800009 开门；
// 10 native 结算拒绝（rc=1）不得记 INSTALLED；
// 11 回声票据门：程序命令回声被消费；终态后的合法收拢是 fact；真实改文关闭括号。
const fs = require('fs'), vm = require('vm'), mod = require('node:module');
const timers = [];
let now = 0, timerSerial = 0;
vm.runInContext('0', vm.createContext({}));
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
const src = mod.stripTypeScriptTypes(fs.readFileSync(
  __dirname + '/../arkts/cjgui-text-proxy.ets', 'utf8'), { mode: 'transform' });
const stripped = src.replace(/export /g, '');
vm.runInContext(stripped + ';globalThis.LC=CjguiImeSelectionLifecycle;', env);

function mountOf(name) {
  return { fieldId: name, key: { contextId: 7, describe() { return 'c7/' + name; } } };
}
const flushMicrotasks = async () => { for (let i = 0; i < 8; i++) await Promise.resolve(); };
// 相对推进：触发 (now, now+deltaMs] 内到期的全部计时器；终态后残留的
// 身份守卫计时器也随之消费（守卫使它们 no-op），因此每个 case 收尾应无计时器。
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
function makeHost(opts) {
  opts = opts || {};
  // 每个 host 自己的 rejects 登记：case 内只触发本 case 捕获的回调。
  const rejects = [];
  let installs = 0, commits = 0;
  // 平台读回跟随 setter（同值 setter 也会被组件采纳的仿真）；
  // 'mismatch' 固定回 [0,0) 以模拟平台折叠。
  let readback = { start: opts.targetStart !== undefined ? opts.targetStart : 1,
                   end: opts.targetEnd !== undefined ? opts.targetEnd : 3 };
  const h = {
    attachSession() {
      if (opts.hang) return { then() { return { catch(fn) { rejects.push(fn); } }; } };
      if (opts.attachRejects) return { then() { return { catch(fn) { rejects.push(fn); } }; } };
      return { then(fn) { fn(); return { catch() {} }; } };
    },
    hasImeTrafficEvidence(m) { return !!(opts.trafficMounts && opts.trafficMounts.has(m)); },
    readSelection() {
      if (opts.getterThrows) throw new Error('boom');
      if (opts.getter === 'mismatch') return { start: 0, end: 0 };
      return { start: readback.start, end: readback.end };
    },
    setSelection(start, end) { installs++; readback = { start, end }; },
    commitInstalled() { commits++; return opts.commitRc !== undefined ? opts.commitRc : '0'; },
    isCurrentMount: m => m === opts.mount,
    restoreTaskActive: () => false,
    logInfo() {}, logWarn() {},
    _rejects: () => rejects, _installs: () => installs, _commits: () => commits };
  return h;
}
const results = {};

(async () => {
// 1 成功链
{
  const mount = mountOf('one');
  const h = makeHost({ mount }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c1');
  const pendingBefore = lc.pendingMount() === mount;
  lc.requestAttach(mount, 'c1');
  await advance(5000);  // 确认窗口 32ms×2，远早于 8000ms 截止
  results.case1 = { pending_before_attach: pendingBefore,
    terminal: lc.terminal(), attached: lc.isAttachedTo(mount),
    installs: h._installs(), commits: h._commits(), timers_left: timers.length };
}
// 2 getter 异常
{
  const mount = mountOf('two');
  const h = makeHost({ mount, getterThrows: true }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c2'); lc.requestAttach(mount, 'c2'); await advance(9000);
  results.case2 = { terminal: lc.terminal(), pending: lc.pendingMount() === mount,
    timers_left: timers.length };
}
// 3/4/9 12800009 证据门（当前序号；证据按挂载）。退避重试链逐轮推进：
// 每轮触发全部已捕获的失败回调，再推进时钟让退避计时器发起下一次 attach。
async function detachCase(mount, trafficMounts) {
  const h = makeHost({ mount, attachRejects: true, trafficMounts }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c'); lc.requestAttach(mount, 'c');
  let fired = 0;
  for (let round = 0; round < 30 && lc.terminal() === 'pending'; round++) {
    const pending = h._rejects().splice(0);
    for (const reject of pending) { reject({ code: 12800009 }); fired += 1; }
    await advance(1000);
  }
  return { lc, h, fired: () => fired };
}
{
  const c = await detachCase(mountOf('three'), new Set([mountOf('other')]));
  await advance(9000);
  results.case3 = { gate: c.lc.isAttachedTo(mountOf('three')),
    terminal: c.lc.terminal(), retries_fired: c.fired(), timers_left: timers.length };
}
{
  const mount = mountOf('four');
  const c = await detachCase(mount, new Set([mount]));
  await advance(9000);
  results.case4 = { gate: c.lc.isAttachedTo(mount),
    terminal: c.lc.terminal(), timers_left: timers.length };
}
// 5 确认失配终态
{
  const mount = mountOf('five');
  const h = makeHost({ mount, getter: 'mismatch' }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c5'); lc.requestAttach(mount, 'c5'); await advance(9000);
  results.case5 = { terminal: lc.terminal(), pending: lc.pendingMount() === mount,
    timers_left: timers.length };
}
// 6 旧序号迟到失败不开门（只触发本 case 捕获的第一个（seq=1）回调）
{
  const mount = mountOf('six');
  const h = makeHost({ mount, attachRejects: true }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c6');
  lc.requestAttach(mount, 'old');   // seq=1
  lc.requestAttach(mount, 'new');   // seq=2 取代
  h._rejects()[0]({ code: 12800009 });  // 本 case 自己的旧 Promise
  await advance(9000);
  results.case6 = { gate_opened: lc.isAttachedTo(mount) };
}
// 7 非 12800009 的 attach 拒绝
{
  const mount = mountOf('seven');
  const trafficMounts = new Set([mount]);
  const h = makeHost({ mount, attachRejects: true, trafficMounts }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c7'); lc.requestAttach(mount, 'c7');
  h._rejects()[h._rejects().length - 1]({ code: 12900000 });
  await advance(9000);
  results.case7 = { gate: lc.isAttachedTo(mount), terminal: lc.terminal(),
    pending: lc.pendingMount() === mount, timers_left: timers.length };
}
// 8 attach 永不回调 → 固定截止（无回调永挂的生产反例）
{
  const mount = mountOf('eight');
  const h = makeHost({ mount, hang: true }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c8'); lc.requestAttach(mount, 'c8');
  await advance(9000);
  results.case8 = { terminal: lc.terminal(), pending: lc.pendingMount() === mount,
    attached: lc.isAttachedTo(mount), timers_left: timers.length,
    native_commits: h._commits() };
}
// 9 证据按挂载隔离：A 有输入流，B 被拒 → B 不开门（整链耗尽 → UNCONFIRMED）
{
  const a = mountOf('A'), b = mountOf('B');
  const c = await detachCase(b, new Set([a]));
  await advance(9000);
  results.case9 = { b_gate: c.lc.isAttachedTo(b), terminal: c.lc.terminal(),
    timers_left: timers.length };
}
// 10 native 结算拒绝不得记 INSTALLED
{
  const mount = mountOf('ten');
  const h = makeHost({ mount, commitRc: '1' }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c10'); lc.requestAttach(mount, 'c10'); await advance(9000);
  results.case10 = { terminal: lc.terminal(), pending: lc.pendingMount() === mount,
    commits: h._commits(), timers_left: timers.length };
}
// 11 回声票据门：程序回声被消费；终态后合法收拢是 fact；改文关闭括号
{
  const mount = mountOf('eleven');
  const h = makeHost({ mount }); const lc = new env.LC(h);
  lc.arm(mount, 1, 3, 'c11'); lc.requestAttach(mount, 'c11');
  await advance(5000);
  const settled = lc.terminal() === 'INSTALLED';
  // setSelection 的程序回声：括号已在 settle 清理——终态后的观测一律 fact。
  const collapseAfterSettle = lc.consumeSelectionObservation(mount, 2, 2);
  // 新一轮请求：程序命令回声按括号消费一次，第二条是 fact。
  lc.arm(mount, 5, 8, 'c11b');
  lc.requestAttach(mount, 'c11b');   // attach 已是会话级事实，立即安装
  await advance(0);
  const programEcho = lc.consumeSelectionObservation(mount, 5, 8);
  const secondObservation = lc.consumeSelectionObservation(mount, 6, 6);
  await advance(9000);
  // 改文关闭括号：真实输入后到来的收拢立即是 fact。
  lc.arm(mount, 2, 6, 'c11c');
  lc.requestAttach(mount, 'c11c'); await advance(0);
  lc.noteTraffic(mount);
  const afterTraffic = lc.consumeSelectionObservation(mount, 4, 4);
  await advance(9000);
  results.case11 = { settled, collapse_after_settle: collapseAfterSettle,
    program_echo: programEcho, second_observation: secondObservation,
    after_traffic: afterTraffic, timers_left: timers.length };
}

console.log(JSON.stringify(results, null, 1));
const fail =  !(results.case1.terminal === 'INSTALLED' && results.case1.installs >= 1 &&
    results.case1.commits === 1 && results.case1.timers_left === 0) ||
  !(results.case2.terminal === 'UNCONFIRMED' && !results.case2.pending &&
    results.case2.timers_left === 0) ||
  (results.case3.gate || results.case3.terminal !== 'UNCONFIRMED' || results.case3.timers_left !== 0) ||
  (!results.case4.gate || results.case4.terminal !== 'INSTALLED') ||
  !(results.case5.terminal === 'UNCONFIRMED' && !results.case5.pending &&
    results.case5.timers_left === 0) ||
  results.case6.gate_opened ||
  (results.case7.gate || results.case7.terminal !== 'UNCONFIRMED' || results.case7.timers_left !== 0) ||
  (results.case8.terminal !== 'UNCONFIRMED' || results.case8.pending ||
    results.case8.attached || results.case8.timers_left !== 0 || results.case8.native_commits !== 0) ||
  (results.case9.b_gate || results.case9.terminal !== 'UNCONFIRMED' || results.case9.timers_left !== 0) ||
  (results.case10.terminal !== 'UNCONFIRMED' || results.case10.commits !== 1 ||
    results.case10.timers_left !== 0) ||
  !(results.case11.settled && results.case11.collapse_after_settle === 'fact' &&
    results.case11.program_echo === 'echo' && results.case11.second_observation === 'fact' &&
    results.case11.after_traffic === 'fact' && results.case11.timers_left === 0);
process.exitCode = fail ? 1 : 0;
})().catch(err => { console.error(err); process.exitCode = 1; });
