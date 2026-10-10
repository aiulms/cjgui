// R5（2026-10-02 Astra 裁决）退役前驱（交接记录）回归：共享注册表 CjguiTextProxyRegistry。
// 直接驱动框架类（arkts/cjgui-text-proxy.ets）。
//
// 背景：owned 节点同值换版会在页面挂载回声落地前推进 context，使该回声被 stale 拒
// （native preview 唯一非零返回即 takeEditingContextLocked 失败）。输入必须立即关闭，
// 但保留**至多一条**可一次性消费的退役前驱供合法 reconcile 交接；新挂载／明确终结／
// 会话更换即失效；绝不误清另一份 current。
//
// 判例：
//  R5a preview 被拒 → 输入立即关闭（isCurrent=false），但 retireForReconcile 仍可消费该前驱（一次性）；
//  R5b 消费后再调 retireForReconcile → 'stale'（不得重复消费）；
//  R5c 退役 A 后挂载 B → 前驱失效；A 的迟到 retire 不得误清 B 的 current；
//  R5d 提交终结（submitAndFinish）使前驱失效；
//  R5e 框架 end 对退役前驱也响应并清记录（current=null 不得使 end 静默失效）。
const fs = require('fs'), vm = require('vm'), mod = require('node:module');
const SRC = process.env.PROXY_SRC ||
  __dirname + '/../arkts/cjgui-text-proxy.ets';
const env = { setTimeout: () => 0, clearTimeout: () => {} };
vm.createContext(env);
const src = mod.stripTypeScriptTypes(fs.readFileSync(SRC, 'utf8'), { mode: 'transform' });
vm.runInContext(src.replace(/export /g, '') +
  ';globalThis.Registry=CjguiTextProxyRegistry;globalThis.Key=CjguiProxyKey;', env);

function makeBridge(previewRc) {
  const logs = [];
  return {
    logs,
    grapheme() { return '{"status":0,"start":0,"end":0}'; },
    preview() { return previewRc; }, previewRange() { return previewRc; },
    commit() { return '0'; }, finish() { return '0'; },
    logWarn(m) { logs.push('W:' + m); }, logInfo(m) { logs.push('I:' + m); },
  };
}
const results = {};
const ok = (c, m) => { if (!c) { console.error('FAIL: ' + m); return 1; } return 0; };
let fail = 0;

// R5a：preview 被拒 → 关输入但保留可一次性消费的前驱。
{
  const b = makeBridge('1'); const reg = new env.Registry(b);
  const m = reg.mount(15, 1, 'ctl', 'pharos-document-note', 1, 1, 'abc');
  const verdict = reg.onChange(m, 'abc', undefined);          // rc=1 → 退役
  const closed = reg.isCurrent(m) === false && reg.currentMount() === null;
  const retired = reg.retireForReconcile(m, 15);
  const consumedAgain = reg.retireForReconcile(m, 15);
  results.r5a = { verdict, closed, retired, consumed_again: consumedAgain };
}
// R5c：退役 A 后挂载 B → 前驱失效；A 的迟到 retire 不得误清 B。
{
  const b = makeBridge('1'); const reg = new env.Registry(b);
  const a = reg.mount(15, 1, 'ctl', 'pharos-document-note', 1, 1, 'abc');
  reg.onChange(a, 'abc', undefined);                          // A 退役为前驱
  const bm = reg.mount(16, 1, 'ctl', 'pharos-document-note', 1, 1, 'abd');  // 新挂载 → 前驱失效
  const aRetire = reg.retireForReconcile(a, 15);              // 应 stale
  const bStillCurrent = reg.isCurrent(bm) && reg.currentMount() === bm;
  results.r5c = { a_retire: aRetire, b_still_current: bStillCurrent };
}
// R5d：提交终结使前驱失效。
{
  const b = makeBridge('1'); const reg = new env.Registry(b);
  const m = reg.mount(15, 1, 'ctl', 'pharos-document-note', 1, 1, 'abc');
  reg.onChange(m, 'abc', undefined);
  const fin = reg.submitAndFinish(m, 'blur');
  const retired = reg.retireForReconcile(m, 15);
  results.r5d = { finish: fin, retire_after_finish: retired };
}
// R5e：框架 end 对退役前驱也响应。
{
  const b = makeBridge('1'); const reg = new env.Registry(b);
  const m = reg.mount(15, 1, 'ctl', 'pharos-document-note', 1, 1, 'abc');
  reg.onChange(m, 'abc', undefined);
  const ended = reg.onFrameworkEnd(15);
  const retired = reg.retireForReconcile(m, 15);              // 记录已被 end 清除 → stale
  results.r5e = { ended, retire_after_end: retired };
}
// R5f：正常路径（rc=0）不受影响：current 保持、无前驱。
{
  const b = makeBridge('0'); const reg = new env.Registry(b);
  const m = reg.mount(15, 1, 'ctl', 'pharos-document-note', 1, 1, 'abc');
  const verdict = reg.onChange(m, 'abc', undefined);
  const stillCurrent = reg.isCurrent(m);
  const retire = reg.retireForReconcile(m, 15);               // 当前挂载仍可 retire（既有语义）
  results.r5f = { verdict, still_current: stillCurrent, retire_as_current: retire };
}

console.log(JSON.stringify(results, null, 1));
fail += ok(results.r5a.verdict === 'rejected' && results.r5a.closed === true, 'r5a input closed on reject');
fail += ok(results.r5a.retired === 'retired', 'r5a predecessor consumable once');
fail += ok(results.r5a.consumed_again === 'stale', 'r5a predecessor not double-consumed');
fail += ok(results.r5c.a_retire === 'stale' && results.r5c.b_still_current === true,
  'r5c new mount invalidates predecessor; stale retire must not clear new current');
fail += ok(results.r5d.retire_after_finish === 'stale', 'r5d finish invalidates predecessor');
fail += ok(results.r5e.ended === true && results.r5e.retire_after_end === 'stale',
  'r5e framework end handles predecessor');
fail += ok(results.r5f.verdict === 'ok' && results.r5f.still_current === true,
  'r5f clean path unaffected');
process.exitCode = fail ? 1 : 0;
