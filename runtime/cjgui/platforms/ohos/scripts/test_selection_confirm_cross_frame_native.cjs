// 安装确认必须跨帧（h-visual-e，2026-10-06）。
//
// 直接驱动生产类 CjguiImeSelectionLifecycle（arkts/cjgui-text-proxy.ets），
// 虚拟时钟 + 延迟回声宿主：平台的选区读数只在下一帧改变，同一毫秒的
// getSelection() 仍是上一份文本的落点——这正是设备原件的形状：
//   ime proxy selection set [8,8) reason=attach attempt=0
//   ime selection immediate read [2,2) target=[8,8) reason=attach (not evidence by itself)
//   ime selection confirm mismatch round=0 target=[8,8) observed=[2,2)
//   ime proxy selection terminal=UNCONFIRMED reason=attach_confirm_mismatch
// 三条同毫秒；随后 req=3..11 八张恢复票全按具名终态烧尽。
//
// 判例：
//  A 延迟回声：setter 同帧读到旧落点不得终态；下一帧命中目标、再一帧稳定 →
//    INSTALLED 且 native 恰好一次接受（commits=1）。
//  B 回声永不到来：有界窗口内仍按具名失配收口，commits=0（跨帧不是"什么都接受"，
//    也不是把判据放宽成延时即就绪）。
//  变异负控由 PROXY_SRC 外部注入：把首轮确认改回 install() 内联，A 必须重新失败。
const fs = require('fs'), vm = require('vm'), mod = require('node:module');
const path = require('path');

const SRC = process.env.PROXY_SRC ||
  path.join(__dirname, '..', 'arkts', 'cjgui-text-proxy.ets');

const timers = [];
let now = 0, timerSerial = 0;
const env = {};
env.setTimeout = (fn, delay) => { const id = ++timerSerial; timers.push({ id, due: now + (delay || 0), fn }); return id; };
env.clearTimeout = (id) => { const at = timers.findIndex(t => t.id === id); if (at >= 0) timers.splice(at, 1); };
vm.createContext(env);
const src = mod.stripTypeScriptTypes(fs.readFileSync(SRC, 'utf8'), { mode: 'transform' });
vm.runInContext(src.replace(/export /g, '') + ';globalThis.LC=CjguiImeSelectionLifecycle;', env);

const mountOf = (name) => ({ fieldId: name, key: { contextId: 9, describe() { return 'c9/' + name; } } });
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

// 延迟回声宿主：setSelection 只记命令，读数在 `echoAfterMs` 之后才跳到目标。
function makeDeferredEchoMountHost(mount, stale, echoAfterMs) {
  const st = { installs: 0, commits: 0, attachCalls: 0, logs: [], resolvers: [],
    readback: { start: stale.start, end: stale.end }, sent: null, echoedAt: null };
  const h = {
    attachSession() { st.attachCalls += 1;
      return { then(fn) { st.resolvers.push(fn); return { catch() {} }; } }; },
    hasImeTrafficEvidence() { return false; },
    readSelection() {
      if (st.echoedAt !== null && now >= st.echoedAt) return st.sent;
      return { start: st.readback.start, end: st.readback.end };
    },
    setSelection(s, e) {
      st.installs += 1; st.sent = { start: s, end: e };
      st.echoedAt = echoAfterMs === null ? null : now + echoAfterMs;
    },
    commitInstalled() { st.commits += 1; return '0'; },
    isCurrentMount(m) { return m === mount; },
    restoreTaskActive() { return false; },
    logInfo(msg) { st.logs.push('I:' + msg); },
    logWarn(msg) { st.logs.push('W:' + msg); },
  };
  return { h, st, resolveAll() { for (const f of st.resolvers.splice(0)) f(); },
    logged(pred) { return st.logs.some(pred); } };
}

const results = {};
(async () => {
  // A：同帧旧读数不是证据；下一帧回声命中 → 稳定两帧 → INSTALLED，恰一次 native 接受。
  {
    const mount = mountOf('deferred-echo');
    const ctl = makeDeferredEchoMountHost(mount, { start: 2, end: 2 }, 32);
    const lc = new env.LC(ctl.h);
    lc.arm(mount, 8, 8, 'mount');
    lc.requestAttach(mount, 'focus');
    ctl.resolveAll();
    await advance(500);
    results.A = {
      terminal: lc.terminal(), installs: ctl.st.installs, commits: ctl.st.commits,
      same_frame_mismatch_logged: ctl.logged((m) => /confirm mismatch round=0/.test(m)),
      immediate_read_kept_as_log_only: ctl.logged((m) => /immediate read \[2,2\)/.test(m)),
      last_terminal: (ctl.st.logs.filter((m) => /terminal=/.test(m)).slice(-1)[0] || ''),
      timers_left: timers.length,
    };
  }
  // B：回声不到来（echoAfterMs=null 即读数永远停在旧值）→ 具名失配、零次采纳。
  {
    const mount = mountOf('no-echo');
    const ctl = makeDeferredEchoMountHost(mount, { start: 2, end: 2 }, null);
    const lc = new env.LC(ctl.h);
    lc.arm(mount, 8, 8, 'mount');
    lc.requestAttach(mount, 'focus');
    ctl.resolveAll();
    await advance(500);
    results.B = {
      terminal: lc.terminal(), commits: ctl.st.commits, installs: ctl.st.installs,
      last_terminal: (ctl.st.logs.filter((m) => /terminal=/.test(m)).slice(-1)[0] || ''),
    };
  }
  const okA = results.A.terminal === 'INSTALLED' && results.A.commits === 1 &&
    results.A.installs === 1 && results.A.same_frame_mismatch_logged === false &&
    results.A.immediate_read_kept_as_log_only === true &&
    /terminal=INSTALLED reason=[a-z_]+_confirmed/.test(results.A.last_terminal);
  const okB = results.B.terminal === 'UNCONFIRMED' && results.B.commits === 0 &&
    results.B.installs === 1 && /confirm_mismatch/.test(results.B.last_terminal);
  console.log(JSON.stringify({ results, okA, okB }, null, 1));
  process.exit(okA && okB ? 0 : 1);
})();
