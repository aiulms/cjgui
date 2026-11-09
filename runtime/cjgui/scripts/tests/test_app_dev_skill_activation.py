"""Project activation preserves user rules and resolves a real skill entrypoint."""
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit
import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

RUNTIME=Path(__file__).resolve().parents[2]
SKILL=RUNTIME/'skills/cjgui-app-dev'


class Activation(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='cjgui activation ')
        self.root=Path(self.temp.name).resolve()
        self.app=self.root/'app'; self.app.mkdir(); (self.app/'cjpm.toml').write_text('[package]\nname="app"\n')

    def tearDown(self): self.temp.cleanup()

    def call(self,*args):
        return subprocess.run([sys.executable,'-B',str(SKILL/'scripts/activate.py'),'--project',str(self.app),*map(str,args)],text=True,capture_output=True)

    def data(self,result):
        self.assertEqual(result.returncode,0,result.stderr)
        return json.loads(result.stdout)

    def test_append_preserves_existing_rules_and_repeated_activation_is_idempotent(self):
        rules=self.app/'AGENTS.md'; original=b'# User rules\r\nKeep my conventions.\r\n'; rules.write_bytes(original)
        report=self.data(self.call()); after=rules.read_bytes()
        self.assertTrue(after.startswith(original))
        target=unquote(re.search(r'\]\(<([^>]+)>\)',after.decode()).group(1))
        self.assertEqual((self.app/target).resolve(),SKILL/'SKILL.md')
        self.assertEqual(report['host_loading'],'not_verified')
        self.assertEqual(self.data(self.call())['status'],'already_present')
        self.assertEqual(rules.read_bytes(),after)

    def test_modified_block_is_not_overwritten(self):
        self.data(self.call()); rules=self.app/'AGENTS.md'
        rules.write_text(rules.read_text().replace('cjgui-app-dev:begin','cjgui-app-dev:begin\nuser edit'))
        before=rules.read_bytes(); result=self.call()
        self.assertEqual(result.returncode,2)
        self.assertEqual(rules.read_bytes(),before)

    def test_plain_space_and_chinese_link_opens_without_url_decoding(self):
        skill=self.root/'技能 SDK with spaces'
        shutil.copytree(SKILL,skill,ignore=shutil.ignore_patterns('__pycache__'))
        self.data(self.call('--skill',skill))
        link=re.search(r'\]\(<([^>]+)>\)',(self.app/'AGENTS.md').read_text()).group(1)
        self.assertTrue((self.app/link).is_file(),link)

    def test_reserved_uri_characters_keep_link_and_file_tool_path_usable(self):
        skill=self.root/'技能 #fragment?100%20'
        shutil.copytree(SKILL,skill,ignore=shutil.ignore_patterns('__pycache__'))
        self.data(self.call('--skill',skill))
        text=(self.app/'AGENTS.md').read_text()
        link=re.search(r'\]\(<([^>]+)>\)',text).group(1)
        uri=urlsplit(link)
        self.assertFalse(uri.fragment); self.assertFalse(uri.query)
        self.assertEqual((self.app/unquote(uri.path)).resolve(),skill/'SKILL.md')
        raw=re.search(r'文件路径 JSON：`([^`]+)`',text)
        self.assertIsNotNone(raw,text)
        self.assertEqual((self.app/json.loads(raw.group(1))).resolve(),skill/'SKILL.md')

    def test_template_upgrade_is_previewable_and_refresh_preserves_surroundings(self):
        skill=self.root/'installed skill'
        shutil.copytree(SKILL,skill,ignore=shutil.ignore_patterns('__pycache__'))
        rules=self.app/'AGENTS.md'; prefix=b'# User rules\r\nPreserve bytes.\r\n'
        rules.write_bytes(prefix);self.data(self.call('--skill',skill))
        suffix=b'\n# Later user rules\r\nRemain unchanged.\r\n'
        rules.write_bytes(rules.read_bytes()+suffix);before=rules.read_bytes()
        template=skill/'assets/PROJECT_RULE.md'
        template.write_text(template.read_text().replace('## CJGUI 应用开发入口','## CJGUI 应用开发入口（新模板）'))
        preview=self.data(self.call('--skill',skill,'--dry-run'))
        self.assertEqual(preview['status'],'update_available')
        self.assertIn('新模板',preview['diff']); self.assertIn('existing_block',preview)
        self.assertEqual(rules.read_bytes(),before)
        refused=self.call('--skill',skill)
        self.assertEqual(refused.returncode,2);self.assertIn('--refresh',refused.stderr)
        self.assertIn('新模板',refused.stderr);self.assertEqual(rules.read_bytes(),before)
        result=self.data(self.call('--skill',skill,'--refresh'))
        self.assertEqual(result['status'],'refreshed')
        self.assertTrue(rules.read_bytes().startswith(prefix));self.assertTrue(rules.read_bytes().endswith(suffix))
        self.assertEqual(self.data(self.call('--skill',skill))['status'],'already_present')

    def test_template_boundary_whitespace_does_not_invalidate_its_own_stamp(self):
        skill=self.root/'spaced template'
        shutil.copytree(SKILL,skill,ignore=shutil.ignore_patterns('__pycache__'))
        template=skill/'assets/PROJECT_RULE.md'
        template.write_text('\n  '+template.read_text()+'\n')
        self.data(self.call('--skill',skill))
        before=(self.app/'AGENTS.md').read_bytes()
        self.assertEqual(self.data(self.call('--skill',skill))['status'],'already_present')
        self.assertEqual(self.data(self.call('--skill',skill,'--refresh'))['status'],'already_present')
        self.assertEqual((self.app/'AGENTS.md').read_bytes(),before)

    def test_refresh_repairs_link_after_only_app_moves(self):
        self.data(self.call());nested=self.root/'nested';nested.mkdir()
        moved=nested/'app';self.app.rename(moved);self.app=moved
        preview=self.data(self.call('--dry-run'))
        self.assertEqual(preview['existing_link_status'],'missing')
        self.assertEqual(preview['status'],'update_available')
        self.assertEqual(self.data(self.call('--refresh'))['status'],'refreshed')
        link=re.search(r'\]\(<([^>]+)>\)',(self.app/'AGENTS.md').read_text()).group(1)
        self.assertTrue((self.app/link).is_file())

    def test_refresh_never_overwrites_a_user_edited_generated_block(self):
        self.data(self.call());rules=self.app/'AGENTS.md'
        rules.write_text(rules.read_text().replace('先加载','按用户约定加载'))
        before=rules.read_bytes();preview=self.data(self.call('--dry-run'))
        self.assertEqual(preview['status'],'conflict')
        self.assertIn('按用户约定加载',preview['existing_block'])
        result=self.call('--refresh');self.assertEqual(result.returncode,2)
        self.assertEqual(rules.read_bytes(),before)

    def test_legacy_v3_rule_is_refreshable_but_custom_legacy_text_is_not(self):
        import os
        template=(SKILL/'assets/PROJECT_RULE.md').read_text()
        link=quote(Path(os.path.relpath(SKILL/'SKILL.md',self.app)).as_posix(),safe='/.-_')
        legacy=template.replace('__CJGUI_SKILL_LINK__',f'[CJGUI 应用开发技能](<{link}>)')
        rules=self.app/'AGENTS.md';rules.write_text('# Before\n'+legacy+'\n# After\n')
        self.assertEqual(self.data(self.call('--refresh'))['status'],'refreshed')
        self.assertIn('# Before',rules.read_text());self.assertIn('# After',rules.read_text())
        rules.write_text(legacy.replace('先加载','用户手动改过'))
        before=rules.read_bytes();self.assertEqual(self.call('--refresh').returncode,2)
        self.assertEqual(rules.read_bytes(),before)

    def test_duplicate_or_reversed_markers_are_not_refreshed(self):
        rules=self.app/'AGENTS.md'
        for text in ['<!-- cjgui-app-dev:end -->\n<!-- cjgui-app-dev:begin -->',
                     '<!-- cjgui-app-dev:begin -->\n<!-- cjgui-app-dev:begin -->\n<!-- cjgui-app-dev:end -->']:
            with self.subTest(text=text):
                rules.write_text(text);before=rules.read_bytes()
                self.assertEqual(self.data(self.call('--dry-run'))['status'],'conflict')
                self.assertEqual(self.call('--refresh').returncode,2)
                self.assertEqual(rules.read_bytes(),before)

    def test_damaged_rule_template_cannot_claim_success(self):
        damaged=self.root/'damaged skill'
        shutil.copytree(SKILL,damaged,ignore=shutil.ignore_patterns('__pycache__'))
        template=damaged/'assets/PROJECT_RULE.md'
        template.write_text(template.read_text().replace('__CJGUI_SKILL_LINK__','missing entry'))
        result=self.call('--skill',damaged)
        self.assertEqual(result.returncode,2)
        self.assertFalse((self.app/'AGENTS.md').exists())

    def test_explicit_rule_file_and_dry_run(self):
        result=self.data(self.call('--rules-file','RULES.md','--dry-run'))
        self.assertEqual(result['status'],'planned'); self.assertFalse((self.app/'RULES.md').exists())
        self.data(self.call('--rules-file','RULES.md'))
        self.assertTrue((self.app/'RULES.md').is_file()); self.assertFalse((self.app/'AGENTS.md').exists())

    def test_new_project_can_activate_before_a_package_exists(self):
        (self.app/'cjpm.toml').unlink()
        self.data(self.call())
        self.assertTrue((self.app/'AGENTS.md').is_file())
        self.assertFalse((self.app/'cjpm.toml').exists())

    def test_external_or_symlink_rule_file_is_rejected(self):
        outside=self.root/'outside.md'; outside.write_text('preserve')
        (self.app/'AGENTS.md').symlink_to(outside)
        result=self.call(); self.assertEqual(result.returncode,2); self.assertIn('symlink',result.stderr)
        self.assertEqual(outside.read_text(),'preserve')
        result=self.call('--rules-file','../outside.md'); self.assertEqual(result.returncode,2)
        self.assertIn('outside project',result.stderr)

    def test_new_app_rule_resolves_after_sdk_and_app_move_together(self):
        tree=self.root/'Tree with spaces'; tree.mkdir(); framework=tree/'SDK $literal'; framework.mkdir()
        shutil.copy2(RUNTIME/'cjpm.toml',framework/'cjpm.toml')
        shutil.copytree(RUNTIME/'templates/macos_application',framework/'templates/macos_application',ignore=shutil.ignore_patterns('target','.cjgui','artifacts','__pycache__'))
        shutil.copytree(SKILL,framework/'skills/cjgui-app-dev',ignore=shutil.ignore_patterns('__pycache__'))
        app=tree/'new app'
        result=subprocess.run(['zsh',str(RUNTIME/'scripts/create_macos_application.sh'),'ui-only',str(app),'--framework',str(framework)],text=True,capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertTrue((app/'AGENTS.md').exists())
        moved=self.root/'Moved tree'; tree.rename(moved)
        text=(moved/'new app/AGENTS.md').read_text()
        relative=unquote(re.search(r'\]\(<([^>]+)>\)',text).group(1))
        self.assertTrue((moved/'new app'/relative).is_file())

    def test_exported_sdk_retains_the_generated_skill_link(self):
        sdk=self.root/'exported SDK'
        result=subprocess.run(['zsh',str(RUNTIME/'scripts/export_framework_preview.sh'),str(sdk),'--profile','macos-dev'],text=True,capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr)
        app=self.root/'exported consumer'
        result=subprocess.run(['zsh',str(sdk/'framework/cjgui/scripts/create_macos_application.sh'),'ui-only',str(app)],text=True,capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr)
        rule=(app/'AGENTS.md').read_text()
        link=re.search(r'\]\(<([^>]+)>\)',rule)
        self.assertIsNotNone(link,rule)
        self.assertTrue((app/unquote(link.group(1))).is_file())


if __name__=='__main__': unittest.main()
