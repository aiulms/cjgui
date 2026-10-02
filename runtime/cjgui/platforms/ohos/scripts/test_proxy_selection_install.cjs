// R3（h-source-preview-followup 2026-10-02）：选区安装的「同值 setter 须经
// 组件真实读回收口」纪律已上收到框架共享类 CjguiImeSelectionLifecycle
//（同值 setter 可不发组件回调 → setter 返回不是证据；安装由跨帧读数命中 +
// native 接受收口，见 test_s2_shared_lifecycle.cjs case1/case10）。本测试
// 验证消费侧事实：
//   1) Pharos 与 thermo 两个页面都不再保留内联安装状态机
//      （private installProxySelection / armProxySelection 不存在）；
//   2) 两页面都真实构造共享类（new CjguiImeSelectionLifecycle(... host)），
//      选区安装只有这一条实现（消费者 seam 契约见
//      test_ime_selection_host_seams.cjs）。
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../../../../../');
const shells = [
  ['pharos', '/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets'],
  ['thermo', path.join(root, 'labs/ohos_thermo_app/entry/src/main/ets/pages/Index.ets')],
];

for (const [name, filename] of shells) {
  const source = fs.readFileSync(filename, 'utf8');
  test(`${name} inline selection-install state machine retired`, () => {
    assert.equal(source.includes('private installProxySelection('), false,
      'inline installProxySelection must be retired');
    assert.equal(/private proxySel(Mount|Start|End|Seq)\s*[:=]/.test(source), false,
      'inline pending-selection slot fields must be retired');
    // 允许保留**薄委托**包装（方法体只有一行 selectionLifecycle 调用），
    // 不允许任何自持状态的重投实现。
    for (const m of source.matchAll(/private armProxySelection\([^)]*\)[^{]*\{\s*([^}]*)\}/g)) {
      assert.match(m[1], /selectionLifecycle\.arm\(/,
        'armProxySelection must delegate to the shared lifecycle');
    }
  });
  test(`${name} consumes the shared lifecycle as the single installer`, () => {
    assert.match(source, /new CjguiImeSelectionLifecycle\(\s*new \w+ImeSelectionHost\(this\)/,
      'page must construct the shared lifecycle with its own host seam');
    // 页面不得绕过共享类直发 setTextSelection 安装（恢复/菜单事务的
    // beginSelectionPhase 是票据化安装的另一正典入口，不经控制器兜底）。
    const installs = [...source.matchAll(/imeTextController\.setTextSelection\(/g)].length;
    const restorePhase = source.includes('private beginSelectionPhase(') ? 1 : 0;
    const seamSetters = [...source.matchAll(/this\.page\.imeTextController\.setTextSelection\(/g)].length;
    assert.ok(installs <= restorePhase + seamSetters,
      'direct controller installs beyond the restore phase/seam are not allowed');
  });
}
