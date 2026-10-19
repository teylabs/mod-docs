import { test } from 'node:test'
import assert from 'node:assert/strict'
import { creditLine } from '../.vitepress/credit.mjs'

const text = (html) => html.replace(/<[^>]+>/g, '')
const line = (name) => creditLine.match(new RegExp(`<span class="credit-line__${name}">(.*?)</span>(?=<span|</span>$)`))?.[1]

test('line 1 is the product name', () => {
  assert.equal(text(line('name')), 'Mod')
})

test('line 2 keeps the brand guide words', () => {
  assert.equal(text(line('built')), 'Built by Tey Labs, for fellow Laravel developers and their agents.')
})

test('the footer has no copyright sign', () => {
  assert.doesNotMatch(creditLine, /©/)
})

test('Tey Labs links to teylabs.com in a new tab', () => {
  assert.match(creditLine, /<a href="https:\/\/teylabs\.com" target="_blank" rel="noopener">Tey Labs<\/a>/)
})
