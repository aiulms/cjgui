// Run with: node --disable-warning=ExperimentalWarning test_text_proxy.cjs
// Execute the shared ArkTS template itself; only its type syntax is stripped.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { stripTypeScriptTypes } = require('node:module');

const source = fs.readFileSync(path.join(__dirname, '../arkts/cjgui-text-proxy.ets'), 'utf8');
const modulePromise = import(`data:text/javascript,${encodeURIComponent(stripTypeScriptTypes(source, { mode: 'transform' }))}`);

async function fixture(initialText = '中😀尾') {
  const { CjguiTextProxyRegistry } = await modulePromise;
  const calls = [];
  let previewHook = null;
  let commitResult = '0';
  const bridge = {
    preview(context, value) {
      calls.push(['preview', context, value]);
      if (previewHook !== null) previewHook();
      return '0';
    },
    previewRange(context, value, start, end) {
      calls.push(['previewRange', context, value, start, end]);
      if (previewHook !== null) previewHook();
      return '0';
    },
    commit(context, value) {
      calls.push(['commit', context, value]);
      return commitResult;
    },
    finish(context) {
      calls.push(['finish', context]);
      return '0';
    },
    logWarn(message) { calls.push(['warn', message]); },
    logInfo(message) { calls.push(['info', message]); },
  };
  const registry = new CjguiTextProxyRegistry(bridge);
  const mount = registry.mount(10, 7, 'proxy', 'name', 1, 1, initialText);
  calls.length = 0;
  return { registry, mount, calls, setPreviewHook: hook => { previewHook = hook; },
    setCommitResult: rc => { commitResult = rc; } };
}

test('missing PreviewText range keeps the complete uncommitted draft', async () => {
  const f = await fixture();
  assert.equal(f.registry.onChange(f.mount, '中😀拼尾', { value: '拼' }), 'ok');
  assert.equal(f.mount.draft, '中😀拼尾');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['preview', 10, '中😀拼尾']]);
});

test('negative PreviewText offset is a sentinel, not a range or cancellation', async () => {
  const f = await fixture();
  assert.equal(f.registry.onChange(f.mount, '中😀尾!', { offset: -1, value: '!' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['preview', 10, '中😀尾!']]);
  assert.equal(f.calls.some(c => c[0] === 'commit' || c[0] === 'finish'), false);
});

test('out-of-bounds PreviewText offset cannot be clamped into a marked range', async () => {
  const f = await fixture();
  assert.equal(f.registry.onChange(f.mount, '中😀尾!', { offset: 99, value: '!' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['preview', 10, '中😀尾!']]);
});

test('empty PreviewText metadata never implies a composition cancellation', async () => {
  const f = await fixture();
  assert.equal(f.registry.onChange(f.mount, '中😀尾', { offset: -1, value: '' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['preview', 10, '中😀尾']]);
  assert.equal(f.calls.some(c => c[0] === 'commit' || c[0] === 'finish'), false);
});

test('Chinese preview replacing an emoji marks the displayed UTF-16 span', async () => {
  const f = await fixture('中😀尾');
  assert.equal(f.registry.onChange(f.mount, '中拼尾', { offset: 1, value: '拼' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['previewRange', 10, '中拼尾', 1, 2]]);
});

test('emoji preview replacing one Chinese character marks two UTF-16 units', async () => {
  const f = await fixture('中尾');
  assert.equal(f.registry.onChange(f.mount, '😀尾', { offset: 0, value: '😀' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['previewRange', 10, '😀尾', 0, 2]]);
});

test('nonzero preview insertion after an emoji marks its full displayed position', async () => {
  const f = await fixture('中😀尾');
  assert.equal(f.registry.onChange(f.mount, '中😀汉尾', { offset: 3, value: '汉' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['previewRange', 10, '中😀汉尾', 3, 4]]);
});

test('PreviewText offset inside an emoji surrogate pair falls back to full draft', async () => {
  const f = await fixture('中😀尾');
  assert.equal(f.registry.onChange(f.mount, '中😀尾', { offset: 2, value: '\uDE00' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['preview', 10, '中😀尾']]);
});

test('marked span after another uncommitted edit still carries the full draft', async () => {
  const f = await fixture('ab');
  assert.equal(f.registry.onChange(f.mount, 'aXb'), 'ok');
  f.calls.length = 0;
  assert.equal(f.registry.onChange(f.mount, 'aXYb', { offset: 2, value: 'Y' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['previewRange', 10, 'aXYb', 2, 3]]);
});

test('repeated text uses the actual marked offset in the full draft', async () => {
  const f = await fixture('aaa');
  assert.equal(f.registry.onChange(f.mount, 'aaaa', { offset: 1, value: 'a' }), 'ok');
  assert.deepEqual(f.calls.filter(c => c[0] === 'preview' || c[0] === 'previewRange'),
    [['previewRange', 10, 'aaaa', 1, 2]]);
});

test('stale mount after a synchronous focus replacement cannot update the page', async () => {
  const f = await fixture();
  let replacement = null;
  f.setPreviewHook(() => {
    replacement = f.registry.mount(11, 7, 'proxy', 'other', 1, 1, 'fresh');
  });
  assert.equal(f.registry.onChange(f.mount, 'old draft'), 'stale');
  assert.equal(f.registry.currentMount(), replacement);
  assert.equal(replacement.draft, 'fresh');
  assert.equal(f.registry.submitAndFinish(f.mount, 'blur'), 'stale');
  assert.equal(f.calls.some(c => c[0] === 'commit'), false);
});

test('rejected owner commit is reported as rejected and does not claim success', async () => {
  const f = await fixture();
  f.setCommitResult('1');
  assert.equal(f.registry.onChange(f.mount, '未提交'), 'ok');
  assert.equal(f.registry.submitAndFinish(f.mount, 'submit'), 'rejected');
  assert.deepEqual(f.calls.filter(c => c[0] === 'commit'), [['commit', 10, '未提交']]);
});

test('external version reconcile retires an uncommitted draft without owner write', async () => {
  const f = await fixture('旧值');
  assert.equal(f.registry.onChange(f.mount, '未提交草稿'), 'ok');
  f.calls.length = 0;
  assert.equal(f.registry.retireForReconcile(f.mount, 10), 'retired');
  assert.equal(f.registry.currentMount(), null);
  assert.equal(f.mount.alive, false);
  assert.equal(f.mount.draft, '未提交草稿');
  assert.equal(f.registry.submitAndFinish(f.mount, 'blur'), 'stale');
  assert.equal(f.calls.some(c => ['preview', 'previewRange', 'commit', 'finish'].includes(c[0])), false);
});

test('stale reconcile callback cannot retire a newer mount', async () => {
  const f = await fixture('旧值');
  const newer = f.registry.mount(11, 8, 'proxy', 'name', 1, 1, '新值');
  f.calls.length = 0;
  assert.equal(f.registry.retireForReconcile(f.mount, 10), 'stale');
  assert.equal(f.registry.retireForReconcile(newer, 10), 'stale');
  assert.equal(f.registry.currentMount(), newer);
  assert.equal(newer.alive, true);
  assert.equal(f.calls.some(c => ['preview', 'previewRange', 'commit', 'finish'].includes(c[0])), false);
});
