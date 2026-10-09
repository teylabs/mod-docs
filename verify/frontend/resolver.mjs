import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(process.argv[2], 'utf8');
const { resolveModulePage: resolve } = await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
const Page = () => null;
const app = { './pages/Home.vue': () => Promise.resolve({ default: Page }) };
assert.equal((await resolve('Home', app, {})).default, Page);
assert.equal(resolve('Home', { './pages/Home.vue': { default: Page } }, {}).default, Page);
const modules = { '../../app/Modules/Inventory/resources/js/pages/Widget/Index.vue': () => Promise.resolve({ default: Page }) };
assert.equal((await resolve('Inventory::Widget/Index', app, modules)).default, Page);
assert.equal(resolve('Inventory::Widget/Index', {}, { '../../app/Modules/Inventory/resources/js/Pages/Widget/Index.vue': { default: Page } }).default, Page);
assert.equal(resolve('Inventory::Widget/Index', {}, { 'Inventory::Widget/Index': { default: Page } }).default, Page);
for (const name of ['Missing', 'Inventory::Missing', '../Home', 'Inventory::../Home', 'Inventory::::Home', 'Inventory::Widget//Index', '']) {
  assert.throws(() => resolve(name, app, modules));
}
assert.throws(() => resolve('Inventory::Home', app, {}));
assert.throws(() => resolve('Inventory::Widget/Index', {}, { ...modules, '../../../app/Modules/Inventory/resources/js/pages/Widget/Index.vue': { default: Page } }));
console.log('resolver: app/module, lazy/eager, Pages, normalized, missing, invalid, no fallback, ambiguous');
