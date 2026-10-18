#!/usr/bin/env python3
"""Exercise setup's Git boundary without network or Composer installation."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SETUP = Path(__file__).with_name('setup.sh')


class SetupRefs(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='mod-setup-test-')
        cls.root = Path(cls.temp.name)
        cls.repo = cls.root / 'remote'
        cls.repo.mkdir()
        cls.git('init', '-q', '-b', 'main')
        cls.git('config', 'user.name', 'Fixture')
        cls.git('config', 'user.email', 'fixture@example.test')
        (cls.repo / 'composer.json').write_text('{"name":"tey/mod"}\n')
        cls.git('add', 'composer.json')
        cls.git('commit', '-qm', 'Fixture')
        cls.sha = cls.git('rev-parse', 'HEAD')
        cls.git('tag', '-a', 'v1.0.0', '-m', 'Fixture tag')
        cls.git('branch', 'deadbeef')
        tree = cls.git('rev-parse', 'HEAD^{tree}')
        seen = {}
        for number in range(10000):
            body = (f'tree {tree}\nauthor Fixture <fixture@example.test> 1 +0000\n'
                    f'committer Fixture <fixture@example.test> 1 +0000\n\n{number}\n').encode()
            sha = hashlib.sha1(b'commit ' + str(len(body)).encode() + b'\0' + body).hexdigest()
            prefix = sha[:4]
            if prefix in seen:
                for label, content in [('a', seen[prefix]), ('b', body)]:
                    result = subprocess.check_output(['git', '-C', str(cls.repo), 'hash-object', '-t', 'commit', '-w', '--stdin'], input=content).decode().strip()
                    cls.git('update-ref', 'refs/heads/collision-' + label, result)
                cls.ambiguous = prefix
                break
            seen[prefix] = body
        else:
            raise AssertionError('No collision fixture found')
        cls.composer = cls.root / 'composer.php'
        cls.composer.write_text('<?php exit(73); // Installation boundary, never install.\n')
        cls.env = dict(os.environ, PHP=os.environ.get('PHP', shutil.which('php')),
                       COMPOSER_BIN=str(cls.composer), GIT_CONFIG_COUNT='1',
                       GIT_CONFIG_KEY_0='url.' + cls.repo.as_uri() + '.insteadOf',
                       GIT_CONFIG_VALUE_0='https://github.com/teylabs/mod.git',
                       GIT_TERMINAL_PROMPT='0')

    @classmethod
    def git(cls, *args):
        return subprocess.check_output(['git', '-C', str(cls.repo), *args], stderr=subprocess.DEVNULL).decode().strip()

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def run_setup(self, ref, work=None):
        work = work or self.root / self.id().split('.')[-1]
        result = subprocess.run(['bash', str(SETUP), str(work), 'git:' + ref, '13'],
                                env=self.env, text=True, capture_output=True, timeout=15)
        return result, work

    def test_branch_tag_and_full_sha_record_full_commit_before_install(self):
        for index, ref in enumerate(['main', 'v1.0.0', self.sha, 'refs/heads/deadbeef']):
            with self.subTest(ref=ref):
                result, work = self.run_setup(ref, self.root / f'valid-{index}')
                self.assertEqual(result.returncode, 73, result.stderr)
                self.assertEqual((work / 'mod-ref.txt').read_text().strip(), self.sha)
                self.assertTrue((work / '.mod-docs-harness').exists())

    def test_unique_short_sha_is_rejected_with_full_sha_guidance(self):
        short = self.sha[:12]
        self.assertEqual(self.git('rev-parse', '--disambiguate=' + short), self.sha)
        result, work = self.run_setup(short)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('full 40-character commit SHA', result.stderr)
        self.assertFalse(work.exists())

    def test_ambiguous_short_sha_is_never_accepted(self):
        self.assertEqual(len(self.git('rev-parse', '--disambiguate=' + self.ambiguous).splitlines()), 2)
        result, work = self.run_setup(self.ambiguous)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('full 40-character commit SHA', result.stderr)
        self.assertFalse(work.exists())

    def test_invalid_refs_fail_before_workdir_creation(self):
        for index, ref in enumerate(['', '--help', 'main^{commit}', 'main:composer.json']):
            with self.subTest(ref=ref):
                result, work = self.run_setup(ref, self.root / f'invalid-{index}')
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Invalid Git ref', result.stderr)
                self.assertFalse(work.exists())

    def test_missing_ref_has_context_without_claiming_workdir(self):
        result, work = self.run_setup('missing-branch')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Unable to fetch Git ref', result.stderr)
        self.assertFalse((work / '.mod-docs-harness').exists())
        self.assertFalse((work / 'mod-ref.txt').exists())

    def test_unowned_workdir_is_preserved(self):
        work = self.root / 'unowned'
        (work / 'mod-src').mkdir(parents=True)
        sentinel = work / 'mod-src' / 'keep.txt'
        sentinel.write_text('keep')
        result, _ = self.run_setup('main', work)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('not owned by this harness', result.stderr)
        self.assertEqual(sentinel.read_text(), 'keep')
        self.assertFalse((work / '.mod-docs-harness').exists())


if __name__ == '__main__':
    unittest.main()
