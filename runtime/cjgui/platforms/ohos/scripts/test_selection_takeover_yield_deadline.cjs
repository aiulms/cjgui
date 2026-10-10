// 恢复让位与截止 + 迟到完成的拒绝参数例（h-visual-e，2026-10-06，Astra 反例组 3）。
//
// 直接驱动生产类 CjguiImeSelectionLifecycle（arkts/cjgui-text-proxy.ets），
// 虚拟时钟 + 可控 attach/恢复事务宿主。要证的事件顺序：
//  C 普通安装 pending 时恢复事务接管：让位只转移执行权——旧执行者零 setter、
//    零采纳，同一待办（selMount）与原 seq 保留、原绝对截止保留（不清计时器），
//    无提前终态；恢复落定后**原请求**凭原 seq 继续（不重新 arm）→ 精确
//    INSTALLED 且恰一次采纳（r18 接缝 1）。
//  F 换绑显式退役旧请求 → 具名终态（mount_changed_retired）恰一次，迟到旧回执
//    零影响（不置会话、不安装）。
//  D 迟到的旧 attach 完成：挂载已换代（isCurrentMount=false）时，成功回调不得
//    为新挂载置会话事实，也不得触发安装（日志 attach completed but stale）。
//  E 迟到的旧 focus/安装重投：新目标入账（seq 递增）后，旧 seq 的在飞计时器
//    不得 setter、不得终结新请求。
//  C2 在飞确认之间接管（首轮已过、次轮未到）：次轮确认让位，零采纳、无提前终态，
//    同一待办/原 seq/原绝对截止保留；释放后接续原轮次（不重发 setter）。
//    截止断言核原绝对到期值（同 id 同 due），不只查“还有计时器”。
//  G 持续接管至原截止：在原绝对到期值恰一次 request_deadline 终态，不提前不延后。
// 变异负控由 PROXY_SRC 注入（把让位分支改成"什么都不做"或把 seq 门去掉）。
const fs = require('fs'), vm = require('vm'), mod = require('node:module');
const path = require('path');

const SRC = process.env.PROXY_SRC ||
  path.join(__dirname, '..', 'arkts', 'cjgui-text-proxy.ets');

const timers = [];
let now = 0, timerSerial = 0;
const env = {};
env.setTimeout = (fn, delay) => { const id = ++timerSerial; timers.push({ id, due: now + (delay || 0), fn }); return id; };
env.clearTimeout = (id) => { const at = timers.findIndex(t => t.id === id); if (at >= 0) timers.splice(at, 1); };
env.clearInterval = env.clearTimeout;
vm.createContext(env);
const src = mod.stripTypeScriptTypes(fs.readFileSync(SRC, 'utf8'), { mode: 'transform' });
vm.runInContext(src.replace(/export /g, '') + ';globalThis.LC=CjguiImeSelectionLifecycle;', env);

const mountOf = (name) => ({ fieldId: name, key: { contextId: 9, describe() { return 'c9/' + name; } } });
const flushMicrotasks = async () => { for (let i = 0; i < 8; i++) await Promise.resolve(); };
async function advance(deltaMs) {
  const target = now + deltaMs;
  for (let guard = 0; guard < 8000; guard++) {
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

// 可控宿主：attach 的 resolve/reject 由用例触发；restoreTaskActive 可切换；
// 读数只有在回声落地后才等于已下发命令。
function makeHost(opts) {
  const st = {
    resolvers: [], rejectors: [], installs: 0, commits: 0, attachCalls: 0,
    readback: { start: opts.initStart ?? 1, end: opts.initEnd ?? 1 },
    sent: null, echoedAt: null, logs: [],
  };
  let current = opts.mount;
  const h = {
    attachSession() {
      st.attachCalls += 1;
      return { then(fn) { st.resolvers.push(fn); return { catch(cb) { st.rejectors.push(cb); } }; } };
    },
    hasImeTrafficEvidence() { return false; },
    readSelection() {
      if (st.echoedAt !== null && now >= st.echoedAt) return st.sent;
      return { start: st.readback.start, end: st.readback.end };
    },
    setSelection(s, e) {
      st.installs += 1; st.sent = { start: s, end: e };
      st.echoedAt = now + 32;
    },
    commitInstalled() { st.commits += 1; return '0'; },
    isCurrentMount(m) { return m === current; },
    restoreTaskActive() { return !!opts.restoreActive; },
    logInfo(msg) { st.logs.push('I:' + msg); },
    logWarn(msg) { st.logs.push('W:' + msg); },
  };
  return {
    h, st,
    setCurrent(m) { current = m; },
    resolveAll() { for (const f of st.resolvers.splice(0)) f(); },
    rejectAll(err) { for (const f of st.rejectors.splice(0)) f(err); },
    terminals() { return st.logs.filter((m) => /terminal=/.test(m)); },
    logged(pred) { return st.logs.some(pred); },
  };
}

const results = {};
(async () => {
  // C：pending 时恢复接管 → 让位期间零 setter/零采纳、无提前终态，同一待办与
  //    原 seq/原截止保留；恢复落定后原请求凭原 seq 继续（不重 arm）→ INSTALLED、
  //    commits 只加一次。
  {
    const mount = mountOf('takeover');
    const opts = { mount, restoreActive: true };
    const ctl = makeHost(opts);
    const lc = new env.LC(ctl.h);
    lc.arm(mount, 1, 3, 'mount');
    const dlC = timers.find((t) => t.due === now + 8000);
    lc.requestAttach(mount, 'focus');
    ctl.resolveAll();
    await advance(200);
    const during = {
      installs: ctl.st.installs, commits: ctl.st.commits, terminal: lc.terminal(),
      pending_kept: lc.pendingMount() === mount,
      deadline_same: !!dlC && timers.some((t) => t.id === dlC.id && t.due === dlC.due),
      seq: lc.currentSeq(),
      yield_rows: ctl.st.logs.filter((m) => /restore_task_took_over/.test(m)).length,
    };
    opts.restoreActive = false;                       // 恢复事务落定，不重 arm
    await advance(600);
    results.C = {
      during, terminal_after: lc.terminal(), installs_after: ctl.st.installs,
      commits_after: ctl.st.commits, seq_after: lc.currentSeq(),
      terminal_rows_total: ctl.terminals().length,
      last_terminal: (ctl.terminals().slice(-1)[0] || ''),
    };
  }
  // D：attach 在飞时挂载换代 → 迟到成功不得置会话、不得安装。
  {
    const oldM = mountOf('old-mount');
    const newM = mountOf('new-mount');
    const ctl = makeHost({ mount: oldM });
    const lc = new env.LC(ctl.h);
    lc.arm(oldM, 4, 6, 'mount');
    lc.requestAttach(oldM, 'focus');                  // 在飞，未回调
    ctl.setCurrent(newM);                             // 换挂载（外部改版）
    ctl.resolveAll();                                 // 旧 attach 迟到成功
    await advance(400);
    results.D = {
      attached_old: lc.isAttachedTo(oldM), installs: ctl.st.installs,
      commits: ctl.st.commits, terminal: lc.terminal(),
      stale_logged: ctl.logged((m) => /attach completed but stale/.test(m)),
    };
  }
  // E：旧 seq 的在飞重投不得改写新请求。
  {
    const mount = mountOf('seq-guard');
    const opts = { mount, restoreActive: true };      // 先让第一笔让位（不装）
    const ctl = makeHost(opts);
    const lc = new env.LC(ctl.h);
    lc.arm(mount, 4, 6, 'caret');                     // seq=1
    lc.requestAttach(mount, 'focus');
    ctl.resolveAll();
    await advance(50);                                // 让位发生在这里
    opts.restoreActive = false;
    lc.arm(mount, 9, 9, 'caret');                     // seq=2（新目标）
    await advance(900);
    results.E = {
      seq: lc.currentSeq(), installs: ctl.st.installs, commits: ctl.st.commits,
      terminal: lc.terminal(), target: lc.target(),
      installed_9: ctl.st.installs === 1 && ctl.st.commits === 1,
    };
  }
  // F：换绑显式退役旧请求 → 具名终态恰一次，迟到旧回执零影响。
  {
    const oldM = mountOf('rebind-old');
    const newM = mountOf('rebind-new');
    const ctl = makeHost({ mount: oldM });
    const lc = new env.LC(ctl.h);
    lc.arm(oldM, 4, 6, 'mount');
    lc.requestAttach(oldM, 'focus');                  // 在飞，未回调
    lc.invalidateAttachmentFor(oldM);                 // 换绑：显式退役旧请求
    ctl.setCurrent(newM);                             // 挂载已换代
    ctl.resolveAll();                                 // 旧 attach 迟到成功
    await advance(400);
    results.F = {
      pending_cleared: lc.pendingMount() === null,
      attached_old: lc.isAttachedTo(oldM), installs: ctl.st.installs,
      commits: ctl.st.commits, terminal: lc.terminal(),
      retire_rows: ctl.terminals().filter((m) => /mount_changed_retired/.test(m)).length,
    };
  }
  // C2：在飞确认（首轮已过、次轮未到）时接管 → 次轮确认让位：零采纳、无提前终态，
  //    同一待办/原 seq/原绝对截止保留；释放后接续原轮次（不重发 setter）→ INSTALLED。
  {
    timers.splice(0); now = 0; timerSerial = 0;
    const mount = mountOf('confirm-yield');
    const opts = { mount, restoreActive: false };
    const ctl = makeHost(opts);
    const lc = new env.LC(ctl.h);
    lc.arm(mount, 1, 3, 'mount');
    const dlAtArm = timers.find((t) => t.due === now + 8000);
    lc.requestAttach(mount, 'focus');
    ctl.resolveAll();
    await advance(40);                            // 首轮确认已过，次轮待发
    const round0done = ctl.st.installs === 1 && lc.terminal() === 'pending';
    opts.restoreActive = true;                    // 两次确认之间接管
    await advance(300);
    const during = {
      round0done, installs: ctl.st.installs, commits: ctl.st.commits,
      terminal: lc.terminal(), pending_kept: lc.pendingMount() === mount,
      deadline_same: !!dlAtArm && timers.some((t) => t.id === dlAtArm.id && t.due === dlAtArm.due),
      seq: lc.currentSeq(),
      yield_rows: ctl.st.logs.filter((m) => /confirm yielded to restore task/.test(m)).length,
    };
    opts.restoreActive = false;                   // 释放：接续原轮次，不重 arm
    await advance(600);
    results.C2 = {
      during, terminal_after: lc.terminal(), installs_after: ctl.st.installs,
      commits_after: ctl.st.commits, seq_after: lc.currentSeq(),
      terminal_rows_total: ctl.terminals().length,
      last_terminal: (ctl.terminals().slice(-1)[0] || ''),
    };
  }
  // G：持续接管至原截止 → 持有期间零采纳且在原绝对到期值恰一次终态
  // （request_deadline），不提前、不延后、不重复。
  {
    timers.splice(0); now = 0; timerSerial = 0;
    const mount = mountOf('hold-to-deadline');
    const opts = { mount, restoreActive: false };
    const ctl = makeHost(opts);
    const lc = new env.LC(ctl.h);
    lc.arm(mount, 1, 3, 'mount');
    const dlAtArm = timers.find((t) => t.due === now + 8000);
    lc.requestAttach(mount, 'focus');
    ctl.resolveAll();
    await advance(1);                             // setter 已发，首轮确认未到
    opts.restoreActive = true;                    // 持续接管至截止之后
    const dlDue = dlAtArm ? dlAtArm.due : -1;
    await advance((dlDue - now) + 50);             // 刚过原绝对到期值
    results.G = {
      deadline_found: !!dlAtArm, deadline_due: dlDue,
      installs: ctl.st.installs, commits: ctl.st.commits,
      terminal: lc.terminal(), pending_cleared: lc.pendingMount() === null,
      terminal_rows_total: ctl.terminals().length,
      deadline_rows: ctl.terminals().filter((m) => /request_deadline/.test(m)).length,
      last_terminal: (ctl.terminals().slice(-1)[0] || ''),
    };
  }
  const okC = results.C.during.installs === 0 && results.C.during.commits === 0 &&
    results.C.during.terminal === 'pending' && results.C.during.pending_kept === true &&
    results.C.during.deadline_same === true && results.C.during.seq === 1 &&
    results.C.during.yield_rows === 1 &&
    results.C.commits_after === 1 && results.C.installs_after === 1 &&
    results.C.seq_after === 1 &&
    results.C.terminal_after === 'INSTALLED' && results.C.terminal_rows_total === 1;
  const okD = results.D.attached_old === false && results.D.installs === 0 &&
    results.D.commits === 0 && results.D.stale_logged === true;
  const okE = results.E.installed_9 === true && results.E.target.start === 9 &&
    results.E.terminal === 'INSTALLED';
  const okF = results.F.pending_cleared === true && results.F.attached_old === false &&
    results.F.installs === 0 && results.F.commits === 0 &&
    results.F.retire_rows === 1 && results.F.terminal === 'UNCONFIRMED';
  const okC2 = results.C2.during.round0done === true &&
    results.C2.during.installs === 1 && results.C2.during.commits === 0 &&
    results.C2.during.terminal === 'pending' && results.C2.during.pending_kept === true &&
    results.C2.during.deadline_same === true && results.C2.during.seq === 1 &&
    results.C2.during.yield_rows === 1 &&
    results.C2.installs_after === 1 && results.C2.commits_after === 1 &&
    results.C2.seq_after === 1 &&
    results.C2.terminal_after === 'INSTALLED' && results.C2.terminal_rows_total === 1;
  const okG = results.G.deadline_found === true &&
    results.G.installs === 1 && results.G.commits === 0 &&
    results.G.terminal === 'UNCONFIRMED' && results.G.pending_cleared === true &&
    results.G.terminal_rows_total === 1 && results.G.deadline_rows === 1;
  console.log(JSON.stringify({ results, okC, okD, okE, okF, okC2, okG }, null, 1));
  process.exit(okC && okD && okE && okF && okC2 && okG ? 0 : 1);
})();
