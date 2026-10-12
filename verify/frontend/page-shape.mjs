import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFile, writeFile, unlink } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

// Vite executes the real glob maps and compiles the real Vue/React components.
// No browser, mocked components or replacement resolver is used.
const [base, stack] = process.argv.slice(2);
process.chdir(base);
const require = createRequire(`${base}/package.json`);
const { createServer } = await import(pathToFileURL(require.resolve('vite')));
const vue = stack === 'vue';
const ext = vue ? 'vue' : 'tsx';
const source = await readFile(`${base}/resources/js/app.${vue ? 'ts' : 'tsx'}`, 'utf8');
const layouts = source.match(/const folderLayouts = import\.meta\.glob[\s\S]*?\);/)[0];
const file = `${base}/resources/js/page-shape-check.ts`;
await writeFile(file, `
import { nearestPageFile, resolveModulePage } from '../../vendor/tey/mod/resources/js/inertia';
${layouts}
export const lookup = (name) => nearestPageFile(name, folderLayouts);
export const resolve = (name) => resolveModulePage(name,
    import.meta.glob('./pages/**/*.${ext}'),
    import.meta.glob(['../../app/Modules/*/resources/js/pages/**/Page.${ext}', '../../app/Modules/*/resources/js/pages/**/Modal.${ext}']));
`);
let server;
try {
    server = await createServer({ root: base, server: { middlewareMode: true, watch: null }, appType: 'custom' });
    const { lookup, resolve } = await server.ssrLoadModule('/resources/js/page-shape-check.ts');
    const folder = lookup('Inventory::Gadget/Edit/History/Page');
    assert.ok(folder, 'History must find the moved Edit layout');
    assert.equal(folder, lookup('Inventory::Gadget/Edit/Overview/Page'));
    assert.equal(lookup('Inventory::Gadget/Index/Page'), undefined);
    assert.equal(lookup('Inventory::Gadget/Create/Page'), undefined);
    assert.equal(lookup('Other::Gadget/Edit/History/Page'), undefined);
    const page = await resolve('Inventory::Gadget/Edit/History/Page');
    let html;
    if (vue) {
        const { h } = require('vue');
        const { renderToString } = require('@vue/server-renderer');
        html = await renderToString(h(folder, null, { default: () => h(page.default) }));
    } else {
        const { createElement } = require('react');
        const { renderToStaticMarkup } = require('react-dom/server');
        html = renderToStaticMarkup(createElement(folder, null, createElement(page.default)));
    }
    assert.ok(html.includes('<h1>Edit Widget</h1>'), html);
    assert.ok(html.includes('<p>History</p>'), html);
    console.log('Nearest folder, owner boundary, index/create controls and rendered History + Edit layout verified');
} finally {
    await server?.close();
    await unlink(file);
}
