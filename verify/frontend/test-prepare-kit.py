#!/usr/bin/env python3
"""Run the guarded input correction without installing or building a kit."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).with_name('prepare-kit.php')
OLD = 'type Method =\n    "get" | "post" | "put" | "delete" | "patch" | "head" | "options";\n'
FIXED = OLD.replace('"options";', '"options" | "query";')


class PrepareKit(unittest.TestCase):
    def run_helper(self, app, stack):
        return subprocess.run([os.environ.get('PHP', 'php'), str(HELPER), str(app), '13', stack, 'after'],
                              capture_output=True, text=True, timeout=10)

    def test_legacy_is_corrected_once_and_corrected_input_is_unchanged(self):
        for stack in ['vue', 'react']:
            for source in [OLD, FIXED]:
                with self.subTest(stack=stack, source=source), tempfile.TemporaryDirectory() as tmp:
                    app = Path(tmp)
                    file = app / 'resources/js/wayfinder/index.ts'
                    file.parent.mkdir(parents=True)
                    file.write_text(source + 'export const sentinel = true;\n')
                    for _ in range(2):
                        result = self.run_helper(app, stack)
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertEqual(file.read_text(), FIXED + 'export const sentinel = true;\n')

    def test_unexpected_or_duplicate_definitions_fail_without_writing(self):
        inputs = ['', OLD + OLD, OLD + FIXED, FIXED.replace('"query"', '"connect"'),
                  FIXED.replace('"post" | ', ''), 'type Other = "patch" | "head" | "options";\n']
        for stack in ['vue', 'react']:
            for source in inputs:
                with self.subTest(stack=stack, source=source), tempfile.TemporaryDirectory() as tmp:
                    app = Path(tmp)
                    file = app / 'resources/js/wayfinder/index.ts'
                    file.parent.mkdir(parents=True)
                    file.write_text(source)
                    result = self.run_helper(app, stack)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('Pinned Wayfinder Method definition changed', result.stdout + result.stderr)
                    self.assertEqual(file.read_text(), source)


if __name__ == '__main__':
    unittest.main()
