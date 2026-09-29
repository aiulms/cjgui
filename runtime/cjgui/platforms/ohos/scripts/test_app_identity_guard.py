#!/usr/bin/env python3
"""Offline negative control for build_and_run.sh app-identity resolution
(handoff h-touch-scroll-review D).

验证：身份从目标工程（app.json5/module.json5）解析；显式覆盖与目标工程
不一致时具名失败（不允许“构建 thermo、启动设置、断言成功”）；一致时放行。
不构建、不启动、不触碰设备。
"""
import pathlib
import subprocess
import unittest

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[4]
SETTINGS_LAB = REPO / "labs" / "ohos_cjgui_app"
THERMO_LAB = REPO / "labs" / "ohos_thermo_app"

RESOLVE = r'''
LAB="$1"
BUNDLE_NAME="$(grep -oE '"bundleName"\s*:\s*"[^"]+"' "$LAB/AppScope/app.json5" | sed 's/.*"\([^"]*\)"$/\1/' | head -1)"
ABILITY_NAME="$(grep -oE '"name"\s*:\s*"[^"]*Ability"' "$LAB/entry/src/main/module.json5" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
if [ -z "$BUNDLE_NAME" ] || [ -z "$ABILITY_NAME" ]; then
  echo "PRODUCT-FAIL 无法从目标工程解析应用身份：bundle='$BUNDLE_NAME' ability='$ABILITY_NAME'（lab=$LAB）"
  exit 1
fi
if [ "${CJGUI_APP_BUNDLE_SET:-0}" = "1" ] && [ "$CJGUI_APP_BUNDLE" != "$BUNDLE_NAME" ]; then
  echo "PRODUCT-FAIL 显式 CJGUI_APP_BUNDLE=$CJGUI_APP_BUNDLE 与目标工程 bundle=$BUNDLE_NAME 不一致（lab=$LAB）"
  exit 1
fi
if [ "${CJGUI_APP_ABILITY_SET:-0}" = "1" ] && [ "$CJGUI_APP_ABILITY" != "$ABILITY_NAME" ]; then
  echo "PRODUCT-FAIL 显式 CJGUI_APP_ABILITY=$CJGUI_APP_ABILITY 与目标工程 ability=$ABILITY_NAME 不一致（lab=$LAB）"
  exit 1
fi
CJGUI_APP_BUNDLE="$BUNDLE_NAME"
CJGUI_APP_ABILITY="$ABILITY_NAME"
echo "resolved bundle=$CJGUI_APP_BUNDLE ability=$CJGUI_APP_ABILITY"
'''


def run_resolve(lab: pathlib.Path, bundle: str = "", ability: str = "",
                bundle_set: str = "0", ability_set: str = "0"):
    env = {
        "PATH": "/usr/bin:/bin",
        "CJGUI_APP_BUNDLE_SET": bundle_set,
        "CJGUI_APP_ABILITY_SET": ability_set,
    }
    if bundle:
        env["CJGUI_APP_BUNDLE"] = bundle
    if ability:
        env["CJGUI_APP_ABILITY"] = ability
    return subprocess.run(["bash", "-c", RESOLVE + "\necho done", "resolve", str(lab)],
                          capture_output=True, text=True, env=env)


class AppIdentityGuardTest(unittest.TestCase):
    def test_settings_lab_resolves_own_bundle(self) -> None:
        r = run_resolve(SETTINGS_LAB)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("bundle=com.example.cjguiapp", r.stdout)
        self.assertIn("ability=EntryAbility", r.stdout)

    def test_thermo_lab_resolves_own_bundle(self) -> None:
        r = run_resolve(THERMO_LAB)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("bundle=com.example.cjguithermo", r.stdout)

    def test_explicit_mismatch_fails_named(self) -> None:
        # 构建 thermo、启动设置：必须具名失败。
        r = run_resolve(THERMO_LAB, bundle="com.example.cjguiapp", bundle_set="1")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("PRODUCT-FAIL", r.stdout)
        self.assertIn("不一致", r.stdout)

    def test_explicit_match_passes(self) -> None:
        r = run_resolve(THERMO_LAB, bundle="com.example.cjguithermo", bundle_set="1")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_default_env_does_not_trigger_guard(self) ->  None:
        # env 默认值（未显式指定）不触发守卫：以目标工程为准。
        r = run_resolve(THERMO_LAB, bundle="com.example.cjguiapp")  # 无 SET 标志
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("bundle=com.example.cjguithermo", r.stdout)


if __name__ == "__main__":
    unittest.main()
