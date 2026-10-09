import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, mkdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

test('A5 publishes every sidebar page as unchanged Markdown and a canonical index', async () => {
  const { publishMarkdown } = await import('./llms.mjs');
  const root = await mkdtemp(join(tmpdir(), 'mod-llms-'));
  const docs = join(root, 'docs');
  const out = join(root, 'dist');
  await mkdir(join(docs, 'guide'), { recursive: true });
  const source = '# Start\n\n```vue\n{{ widget.id }}\n```\n';
  await writeFile(join(docs, 'guide/start.md'), source);
  await writeFile(join(docs, 'index.md'), '# Home\n');
  const sidebar = [{ text: 'Guide', items: [{ text: 'Start', link: '/guide/start' }, { text: 'Home', link: '/' }] }];
  await publishMarkdown({ sidebar, srcDir: docs, outDir: out });
  assert.equal(await readFile(join(out, 'guide/start.md'), 'utf8'), source);
  assert.equal(await readFile(join(out, 'index.md'), 'utf8'), '# Home\n');
  const index = await readFile(join(out, 'llms.txt'), 'utf8');
  assert.match(index, /\[Start\]\(https:\/\/mod.teylabs.com\/guide\/start.md\)/);
  assert.match(index, /\[Home\]\(https:\/\/mod.teylabs.com\/index.md\)/);
  assert.equal((index.match(/^- \[/gm) || []).length, 2);
});

test('A5 fails the build for a sidebar page with no Markdown source', async () => {
  const { publishMarkdown } = await import('./llms.mjs');
  const root = await mkdtemp(join(tmpdir(), 'mod-llms-'));
  await assert.rejects(publishMarkdown({ sidebar: [{ text: 'Missing', link: '/missing' }], srcDir: root, outDir: join(root, 'dist') }), /missing/i);
});

test('F16 is a default scenario with both build and type-check gates', async () => {
  const run = await readFile(new URL('../verify/run.sh', import.meta.url), 'utf8');
  assert.match(run, /scenarios=\([^\n]*frontend/);
  const scenario = await readFile(new URL('../verify/scenarios/frontend.sh', import.meta.url), 'utf8');
  for (const gate of ['npm run build', 'vue-tsc --noEmit', 'tsc --noEmit', 'mod:install', 'mod:crud-pages', '/widgets']) assert.ok(scenario.includes(gate), gate);
});
