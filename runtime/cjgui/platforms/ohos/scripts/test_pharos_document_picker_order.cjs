// Run the real Index.ets document methods; only SDK IO/picker boundaries are adapted.
const fs = require('fs');
const os = require('os');
const path = require('path');
const vm = require('vm');
const ts = require('/Applications/DevEco-Studio.app/Contents/tools/arktsdoc/node_modules/typescript');
const source = fs.readFileSync('/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets', 'utf8');
const methods = source.slice(source.indexOf('  private docIntentDir()'), source.indexOf('  private onFocusRequest('));
const js = ts.transpileModule(`class Page { ${methods} } globalThis.Page = Page;`,
  { compilerOptions: { target: ts.ScriptTarget.ES2020 } }).outputText;
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pharos-picker-order-'));
const fileIo = {
  OpenMode: { READ_ONLY: 1, WRITE_ONLY: 2, READ_WRITE: 4, CREATE: 8, TRUNC: 16 },
  mkdirSync: (p, recursive) => fs.mkdirSync(p, { recursive: !!recursive }),
  renameSync: fs.renameSync, unlinkSync: fs.unlinkSync, accessSync: fs.existsSync,
  openSync(p, mode) {
    const flags = mode & 16 ? 'w+' : mode & 8 ? 'a+' : 'r';
    return { fd: fs.openSync(p, flags) };
  },
  closeSync: f => fs.closeSync(f.fd), fsyncSync: fs.fsyncSync,
  writeSync(fd, data, options) {
    const buf = typeof data === 'string' ? Buffer.from(data) : Buffer.from(data);
    return fs.writeSync(fd, buf, options?.offset ?? 0, options?.length ?? buf.length);
  },
  readSync: (fd, buf) => fs.readSync(fd, new Uint8Array(buf)),
};
let resolvePicker;
const ctx = { filesDir: root };
const sandbox = { fileIo, getContext: () => ctx, hilog: { info(){}, warn(){}, error(){} },
  TAG: '', DOMAIN: 0, picker: { DocumentViewPicker: class {
    save() { return new Promise(resolve => { resolvePicker = resolve; }); }
    select() { return new Promise(resolve => { resolvePicker = resolve; }); }
  } } };
vm.createContext(sandbox); vm.runInContext(js, sandbox);

async function scenario(cancel) {
  const dir = path.join(root, 'pharos-doc-intent', cancel ? 'i100-0' : 'i100-1', 'r1');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'waiting'), 'permit');
  const staging = path.join(dir, 'export.bin');
  fs.writeFileSync(staging, 'frozen version');
  const target = path.join(root, cancel ? 'cancel-target.md' : 'export-target.md');
  fs.writeFileSync(target, 'owned original');
  const payload = { action: 'export', request: 1, requestIdentity: path.basename(path.dirname(dir)) + '-r1',
    requestDir: dir, originDocument: '646f63', originSession: '7', originVersion: '3',
    staging, suggestedName: 'owned-test.md', maxBytes: 262144 };
  const operation = new sandbox.Page().onDocumentIntent(JSON.stringify(payload));
  if (cancel) fs.renameSync(path.join(dir, 'waiting'), path.join(dir, 'cancelled'));
  fs.writeFileSync(staging, 'later editor version');
  resolvePicker([target]); await operation;
  const actual = fs.readFileSync(target, 'utf8');
  const expected = cancel ? 'owned original' : 'frozen version';
  const good = actual === expected;
  console.log(`${good ? 'PASS' : 'FAIL'} ${cancel ? 'cancel wins before write claim' : 'export preserves frozen bytes'} actual=${actual}`);
  return good;
}
(async () => {
  let failed = 0;
  try { for (const cancel of [true, false]) if (!await scenario(cancel)) failed++; }
  finally { fs.rmSync(root, { recursive: true, force: true }); }
  process.exitCode = failed;
})().catch(error => { console.error(error); process.exitCode = 99; });
