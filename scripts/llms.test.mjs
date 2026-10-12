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
  assert.ok(index.includes('Full docs in one file: https://mod.teylabs.com/llms-full.txt'));
  assert.ok(index.indexOf('Full docs in one file:') < index.indexOf('## Docs'));
  const full = await readFile(join(out, 'llms-full.txt'), 'utf8');
  assert.equal(full, `# Start\n\nSource: https://mod.teylabs.com/guide/start\n\n${source}\n# Home\n\nSource: https://mod.teylabs.com/index\n\n# Home\n`);
  await publishMarkdown({ sidebar, srcDir: docs, outDir: out });
  assert.equal(await readFile(join(out, 'llms-full.txt'), 'utf8'), full);
  const changed = `${source}\nUpdated documentation.\n`;
  await writeFile(join(docs, 'guide/start.md'), changed);
  await publishMarkdown({ sidebar, srcDir: docs, outDir: out });
  const updated = await readFile(join(out, 'llms-full.txt'), 'utf8');
  assert.notEqual(updated, full);
  assert.ok(updated.includes(changed));
});

test('publishes grouped and nested sidebar pages in order without navigation chrome', async () => {
  const { publishMarkdown } = await import('./llms.mjs');
  const root = await mkdtemp(join(tmpdir(), 'mod-llms-'));
  const out = join(root, 'dist');
  for (const name of ['last', 'first', 'middle']) {
    await writeFile(join(root, `${name}.md`), `# ${name}\n\nContent for ${name}.\n`);
  }
  const sidebar = {
    '/guide/': [{ text: 'Navigation group', items: [
      { text: 'First', link: '/first#section' },
      { text: 'Nested navigation', items: [{ text: 'Middle', link: '/middle' }] },
    ] }],
    '/reference/': [{ text: 'Last', link: '/last' }, { text: 'External', link: 'https://example.com' }],
  };
  await publishMarkdown({ sidebar, srcDir: root, outDir: out });
  const full = await readFile(join(out, 'llms-full.txt'), 'utf8');
  assert.deepEqual([...full.matchAll(/^Source: (.+)$/gm)].map((match) => match[1]), [
    'https://mod.teylabs.com/first',
    'https://mod.teylabs.com/middle',
    'https://mod.teylabs.com/last',
  ]);
  for (const title of ['First', 'Middle', 'Last']) assert.ok(full.includes(`# ${title}\n`));
  assert.doesNotMatch(full, /Navigation group|Nested navigation|External/);
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
