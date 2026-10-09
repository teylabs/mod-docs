import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';

export async function publishMarkdown({ sidebar, srcDir, outDir }) {
  const pages = new Map();
  function visit(items) {
    for (const item of items) {
      if (item.link?.startsWith('/')) {
        const path = item.link.split('#')[0].replace(/\/$/, '/index');
        pages.set(path, item.text);
      }
      if (item.items) visit(item.items);
    }
  }
  visit(Array.isArray(sidebar) ? sidebar : Object.values(sidebar).flat());
  const lines = ['# Mod for Laravel', '', '> Lightweight toolkit for modular development in Laravel.', '', '## Docs'];
  for (const [path, title] of pages) {
    const file = `${path.slice(1)}.md`;
    const source = await readFile(join(srcDir, file));
    const target = join(outDir, file);
    await mkdir(dirname(target), { recursive: true });
    await writeFile(target, source);
    const summary = source.toString('utf8').split(/\r?\n/).find((line) => line.trim() && !line.startsWith('#'))?.replace(/`/g, '') || '';
    lines.push(`- [${title}](https://mod.teylabs.com${path}.md): ${summary}`);
  }
  await writeFile(join(outDir, 'llms.txt'), `${lines.join('\n')}\n`);
}
