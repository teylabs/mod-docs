// The Mod brand kit's single source of truth.
//
// Every file in kit/ (and the copies deployed to ../docs/public/) is produced
// by this script: the mark's geometry, the Clay palette, the outlined
// wordmark, the favicons, avatars, banners and the share card. Change the
// mark here, run `npm run build`, and commit what changes.
//
// The mark is "Corner": six pieces of six different sizes packed into a
// square on a 5 × 5 grid, with the 1 × 1 piece in the bottom-right corner in
// Tey orange: the last piece in, the one that completes the square.

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import opentype from 'opentype.js'
import sharp from 'sharp'

const here = path.dirname(fileURLToPath(import.meta.url))
const KIT = path.join(here, 'kit')
const PUBLIC = path.join(here, '..', 'docs', 'public')

// Bump when a deployed file changes; the docs reference these files with ?v=N.
export const ASSET_VERSION = 1

// ─── Palette ────────────────────────────────────────────────────────────────

export const ORANGE = '#B65326'
export const INK = '#28231F'
export const PAPER = '#FAF6EF'
export const DARK = '#1E1B18'      // the dark surface the dark variants are drawn for
export const MUTED = '#5C524A'     // secondary text on paper (7.0:1)
export const MUTED_DARK = '#B5ABA0' // secondary text on the dark surface

// Clay: four steps around Tey orange, one ramp per surface. Index 0 is the
// strongest contrast with the surface; 3 is the quietest.
export const CLAY = {
  light: ['#3E2D24', '#7A4B30', '#A8794F', '#D2B07F'], // umber, clay, tan, sand
  dark: ['#F4E9D8', '#DCC3A0', '#B88C62', '#8F6446'],  // cream, sand, tan, clay
}

// ─── Geometry ───────────────────────────────────────────────────────────────

// Pieces are clockwise rectangles on an n × n grid: [column, row, columns, rows, tone].
// Tone is a Clay ramp index, or 'o' for Tey orange.
export const CORNER = {
  n: 5,
  pieces: [
    [0, 0, 3, 3, 0], // 3 × 3, area 9
    [3, 0, 2, 3, 2], // 2 × 3, area 6
    [0, 3, 2, 2, 1], // 2 × 2, area 4
    [2, 3, 3, 1, 3], // 3 × 1, area 3
    [2, 4, 2, 1, 0], // 2 × 1, area 2
    [4, 4, 1, 1, 'o'], // 1 × 1, area 1: the last piece
  ],
}

// A favicon-only cut of the same mark, drawn from the same rules: the big
// piece, a bar on each side and the same orange corner, on a 3 × 3 grid. At
// 16 px it gives the orange a 5 × 5 px square instead of 3 × 3. Not used:
// kept as the fallback, and drawn in kit/favicon-check.png for comparison.
export const CORNER_CUT = {
  n: 3,
  pieces: [
    [0, 0, 2, 2, 0],
    [2, 0, 1, 2, 2],
    [0, 2, 2, 1, 1],
    [2, 2, 1, 1, 'o'],
  ],
}

// The gap is 1 px up to 31 px, then 1/16 of the size. Corners: the square's
// outer corners take 1/24 of the size, inner corners half that.
const gapFor = (N) => Math.max(1, Math.floor(N / 16))

// Split T pixels across n cells symmetrically, so a 5-cell grid that can't
// divide evenly gives its spare pixels to matching outer cells.
const spread = (T, n) => {
  const base = Math.floor(T / n)
  let rem = T - base * n
  const w = Array(n).fill(base)
  if (n % 2 === 1 && rem % 2 === 1) { w[(n - 1) / 2]++; rem-- }
  if (rem % 2 === 1) return null
  for (let i = 0; rem > 0; i++, rem -= 2) { w[i]++; w[n - 1 - i]++ }
  return w
}

// Lay a packing out at N pixels with `margin` pixels of clear space each side.
// Every edge lands on a whole pixel.
export function layout(packing, N, margin = 0) {
  const g = gapFor(N)
  for (let S = N - 2 * margin; S > 0; S--) {
    const w = spread(S - (packing.n - 1) * g, packing.n)
    if (!w) continue
    const pos = [Math.floor((N - S) / 2)]
    w.forEach((v, i) => pos.push(pos[i] + v + g))
    return {
      N, g, S, origin: pos[0],
      pieces: packing.pieces.map(([c, r, cs, rs, tone]) => ({
        x: pos[c], y: pos[r], w: pos[c + cs] - pos[c] - g, h: pos[r + rs] - pos[r] - g, tone,
        corners: [ // top-left, top-right, bottom-right, bottom-left: is it a corner of the square?
          c === 0 && r === 0, c + cs === packing.n && r === 0,
          c + cs === packing.n && r + rs === packing.n, c === 0 && r + rs === packing.n,
        ],
      })),
    }
  }
}

const num = (v) => +v.toFixed(3)

function piecePath({ x, y, w, h, corners }, N) {
  const R = N / 24, r = R / 2
  const [tl, tr, br, bl] = corners.map((outer) => Math.min(outer ? R : r, w / 2, h / 2))
  return `M${num(x + tl)} ${y}H${num(x + w - tr)}A${num(tr)} ${num(tr)} 0 0 1 ${x + w} ${num(y + tr)}`
    + `V${num(y + h - br)}A${num(br)} ${num(br)} 0 0 1 ${num(x + w - br)} ${y + h}`
    + `H${num(x + bl)}A${num(bl)} ${num(bl)} 0 0 1 ${x} ${num(y + h - bl)}`
    + `V${num(y + tl)}A${num(tl)} ${num(tl)} 0 0 1 ${num(x + tl)} ${y}Z`
}

// Colour modes: 'light' and 'dark' use the Clay ramp for that surface;
// 'mono' is all ink; 'reversed' is all paper, for dark or orange fields.
const fillFor = (mode) => (tone) => {
  if (mode === 'mono') return INK
  if (mode === 'reversed') return PAPER
  return tone === 'o' ? ORANGE : CLAY[mode][tone]
}

// The mark's paths at N pixels, positioned at (dx, dy).
export function markPaths(N, mode, { margin = 0, packing = CORNER, dx = 0, dy = 0 } = {}) {
  const L = layout(packing, N, margin)
  const fill = fillFor(mode)
  const body = L.pieces.map((p) => `<path d="${piecePath(p, N)}" fill="${fill(p.tone)}"/>`).join('')
  return dx || dy ? `<g transform="translate(${dx} ${dy})">${body}</g>` : body
}

export function markSvg(N, mode, opts = {}) {
  const size = opts.display ?? N
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${N} ${N}">`
    + `<title>Mod</title>${markPaths(N, mode, opts)}</svg>\n`
}

// favicon.svg follows the browser's colour scheme: the light-surface ramp by
// default, the dark-surface ramp in a dark tab. Drawn on the 16 px grid, so it
// is crisp at 16 and at 32 (a 2× tab).
function faviconSvg(packing) {
  const L = layout(packing, 16, 0)
  const paths = L.pieces.map((p) => `<path class="t${p.tone}" d="${piecePath(p, 16)}"/>`).join('')
  const rules = (ramp) => ramp.map((c, i) => `.t${i}{fill:${c}}`).join('')
  return `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><title>Mod</title>`
    + `<style>${rules(CLAY.light)}.to{fill:${ORANGE}}@media (prefers-color-scheme:dark){${rules(CLAY.dark)}}</style>`
    + `${paths}</svg>\n`
}

// ─── Type, as outlines ──────────────────────────────────────────────────────

const font = (file) => opentype.loadSync(path.join(here, 'fonts', file))
const DISPLAY = font('SchibstedGrotesk-ExtraBold.woff')
const TEXT = font('SchibstedGrotesk-Medium.woff')
const MONO = font('IBMPlexMono-Regular.woff')

// Text as one path: kerning on, with tracking in em. Returns the path data and
// its ink bounds, so lockups can align on real glyph edges.
function textPath(f, text, size, { x = 0, y = 0, tracking = 0 } = {}) {
  const scale = size / f.unitsPerEm
  const glyphs = f.stringToGlyphs(text)
  const p = new opentype.Path()
  let cx = x
  glyphs.forEach((gl, i) => {
    p.extend(gl.getPath(cx, y, size))
    cx += gl.advanceWidth * scale + tracking * size
    if (i < glyphs.length - 1) cx += f.getKerningValue(gl, glyphs[i + 1]) * scale
  })
  return { d: p.toPathData(2), box: p.getBoundingBox(), advance: cx - x }
}

const capHeight = (f, size) => (f.tables.os2.sCapHeight / f.unitsPerEm) * size

// "Mod" in Schibsted Grotesk ExtraBold, tracked in a little.
const wordmark = (size, at = {}) => textPath(DISPLAY, 'Mod', size, { tracking: -0.02, ...at })

// ─── Lockup ─────────────────────────────────────────────────────────────────

// Mark + wordmark. The wordmark's cap height is 62% of the mark, centred on it,
// a quarter of the mark's height away.
function lockupSvg(mode) {
  const H = 240
  const cap = H * 0.62
  const size = cap / (DISPLAY.tables.os2.sCapHeight / DISPLAY.unitsPerEm)
  const gapX = Math.round(H / 4)
  const baseline = Math.round((H + cap) / 2)
  const probe = wordmark(size, { y: baseline })
  const word = wordmark(size, { x: H + gapX - probe.box.x1, y: baseline }) // ink edge exactly gapX from the mark
  const W = Math.ceil(H + gapX + probe.box.x2 - probe.box.x1)
  const color = mode === 'dark' || mode === 'reversed' ? PAPER : INK
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><title>Mod</title>`
    + markPaths(H, mode)
    + `<path d="${word.d}" fill="${color}"/></svg>\n`
}

// ─── Banner, 1200 × 320, drawn at 2× ───────────────────────────────────────

function bannerSvg(mode) {
  const W = 2400, Hh = 640
  const bg = mode === 'dark' ? DARK : PAPER
  const fg = mode === 'dark' ? PAPER : INK
  const muted = mode === 'dark' ? MUTED_DARK : MUTED
  const M = 384
  const mx = 192, my = (Hh - M) / 2
  const nameSize = 300
  const nameCap = capHeight(DISPLAY, nameSize)
  const name = wordmark(nameSize, { x: mx + M + 112, y: my + nameCap + 18 })
  const tag = textPath(TEXT, 'Modular Development Toolkit for Laravel', 68, { x: mx + M + 120, y: my + M - 30 })
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${Hh}" viewBox="0 0 ${W} ${Hh}">`
    + `<rect width="${W}" height="${Hh}" fill="${bg}"/>`
    + markPaths(M, mode, { dx: mx, dy: my })
    + `<path d="${name.d}" fill="${fg}"/><path d="${tag.d}" fill="${muted}"/></svg>\n`
}

// ─── Share card, 2400 × 1200 ────────────────────────────────────────────────

// The app/Modules/ folder and the commands that build it, from mod's README
// ("Self-Contained Modules"). Tree connectors are drawn as lines on the
// monospace grid, so the card needs no box-drawing glyphs.
const TREE = [
  ['', 'app/Modules/'],
  ['├', 'Agents/'],
  ['│├', 'Actions/'],
  ['││└', 'AnswerQuestion.php'],
  ['│├', 'Database/'],
  ['││└', 'Migrations/'],
  ['││ └', '2026_10_08_120001_create_conversations_table.php'],
  ['│├', 'Jobs/'],
  ['││└', 'GenerateReply.php'],
  ['│├', 'Models/'],
  ['││└', 'Conversation.php'],
  ['│└', 'ValueObjects/'],
  ['│ └', 'TokenUsage.php'],
  ['└', 'Knowledge/'],
  [' ├', 'Actions/'],
  [' │└', 'IndexDocument.php'],
  [' ├', 'Controllers/'],
  [' │└', 'DocumentController.php'],
  [' ├', 'Database/'],
  [' │├', 'Factories/'],
  [' ││└', 'DocumentFactory.php'],
  [' │└', 'Migrations/'],
  [' │ └', '2026_10_08_120000_create_documents_table.php'],
  [' ├', 'Events/'],
  [' │└', 'DocumentUploaded.php'],
  [' ├', 'Listeners/'],
  [' │└', 'GenerateEmbeddings.php'],
  [' ├', 'Models/'],
  [' │└', 'Document.php'],
  [' ├', 'Requests/'],
  [' │├', 'StoreDocumentRequest.php'],
  [' │└', 'UpdateDocumentRequest.php'],
  [' └', 'ViewModels/'],
  ['  └', 'ShowDocument.php'],
]

const COMMANDS = [
  'php artisan mod:model Knowledge:Document -mf --controller --resource --requests',
  'php artisan mod:action Knowledge:IndexDocument',
  'php artisan mod:event Knowledge:DocumentUploaded',
  'php artisan mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded',
  'php artisan mod:view-model Knowledge:ShowDocument',
  'php artisan mod:model Agents:Conversation -m',
  'php artisan mod:action Agents:AnswerQuestion',
  'php artisan mod:value Agents:TokenUsage',
  'php artisan mod:job Agents:GenerateReply',
]

function treeSvg(x0, y0, size, lineH, color) {
  const adv = (MONO.charToGlyph('M').advanceWidth / MONO.unitsPerEm) * size
  const col = adv * 4 // one tree level is four characters wide
  const xHeight = (MONO.tables.os2.sxHeight / MONO.unitsPerEm) * size
  const stroke = Math.max(2, size / 12)
  let lines = '', text = ''
  TREE.forEach(([prefix, name], i) => {
    const base = y0 + i * lineH
    const mid = base - xHeight / 2, top = mid - lineH / 2, bottom = mid + lineH / 2
    ;[...prefix].forEach((ch, level) => {
      const cx = x0 + level * col + adv / 2
      if (ch === '│' || ch === '├') lines += `M${num(cx)} ${num(top)}V${num(bottom)}`
      if (ch === '└') lines += `M${num(cx)} ${num(top)}V${num(mid)}`
      if (ch === '├' || ch === '└') lines += `M${num(cx)} ${num(mid)}H${num(cx + adv * 2.6)}`
    })
    text += textPath(MONO, name, size, { x: x0 + prefix.length * col, y: base }).d
  })
  return `<path d="${lines}" stroke="${color}" stroke-width="${num(stroke)}" fill="none"/><path d="${text}" fill="${color}"/>`
}

function cardSvg() {
  const W = 2400, H = 1200
  const faded = 0.52 // faded, but still visible in print and on projectors
  const M = 400, mx = 120, my = 120
  const nameSize = 330
  const name = wordmark(nameSize, { x: mx + M + 96, y: my + M - 6 })
  const tag = textPath(TEXT, 'Modular Development Toolkit for Laravel', 66, { x: mx + 6, y: 680 })
  const install = textPath(MONO, 'composer require tey/mod', 44, { x: mx + 6, y: 762 })
  const site = textPath(TEXT, 'mod.teylabs.com', 38, { x: 0, y: 0 })
  const siteD = textPath(TEXT, 'mod.teylabs.com', 38, { x: W - 120 - site.advance, y: H - 64 }).d
  const prompt = COMMANDS.map((_, i) => textPath(MONO, '$', 25, { x: mx + 6, y: 880 + i * 34 }).d).join('')
  const cmds = COMMANDS.map((c, i) => textPath(MONO, c, 25, { x: mx + 6 + 30, y: 880 + i * 34 }).d).join('')
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">`
    + `<rect width="${W}" height="${H}" fill="${PAPER}"/>`
    + `<g opacity="${faded}">${treeSvg(1450, 72, 24, 31, INK)}<path d="${cmds}" fill="${INK}"/></g>`
    + `<path d="${prompt}" fill="${ORANGE}" opacity="0.85"/>`
    + markPaths(M, 'light', { dx: mx, dy: my })
    + `<path d="${name.d}" fill="${INK}"/>`
    + `<path d="${tag.d}" fill="${INK}"/>`
    + `<path d="${install.d}" fill="${ORANGE}"/>`
    + `<path d="${siteD}" fill="${MUTED}"/></svg>\n`
}

// ─── Tiles and rasters ──────────────────────────────────────────────────────

// An opaque paper tile with the mark centred. No baked corner radius: GitHub,
// social sites and iOS apply their own mask.
function tileSvg(N, markSize) {
  const off = Math.round((N - markSize) / 2)
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${N}" height="${N}" viewBox="0 0 ${N} ${N}">`
    + `<rect width="${N}" height="${N}" fill="${PAPER}"/>${markPaths(markSize, 'light', { dx: off, dy: off })}</svg>\n`
}

const png = (svg) => sharp(Buffer.from(svg)).png({ compressionLevel: 9 }).toBuffer()

// ICO with real PNGs embedded at each size.
function ico(images) {
  const head = Buffer.alloc(6 + 16 * images.length)
  head.writeUInt16LE(0, 0); head.writeUInt16LE(1, 2); head.writeUInt16LE(images.length, 4)
  let offset = head.length
  images.forEach(({ size, data }, i) => {
    const e = 6 + 16 * i
    head.writeUInt8(size >= 256 ? 0 : size, e); head.writeUInt8(size >= 256 ? 0 : size, e + 1)
    head.writeUInt8(0, e + 2); head.writeUInt8(0, e + 3)
    head.writeUInt16LE(1, e + 4); head.writeUInt16LE(32, e + 6)
    head.writeUInt32LE(data.length, e + 8); head.writeUInt32LE(offset, e + 12)
    offset += data.length
  })
  return Buffer.concat([head, ...images.map((im) => im.data)])
}

// ─── Build ──────────────────────────────────────────────────────────────────

// The favicon uses the full mark at every size: at 16 px the orange corner is
// 3 × 3 px and still reads on light and dark tabs (kit/favicon-check.png).
// CORNER_CUT is the fallback if that ever changes.
export const FAVICON_PACKING = () => CORNER
const faviconMargin = (N) => Math.floor(N / 32)

async function build() {
  fs.rmSync(KIT, { recursive: true, force: true })
  fs.mkdirSync(KIT, { recursive: true })
  const out = (name, data) => fs.writeFileSync(path.join(KIT, name), data)

  // Marks: scalable files are laid out on a 480 px grid.
  out('mark-light.svg', markSvg(480, 'light'))
  out('mark-dark.svg', markSvg(480, 'dark'))
  out('mark-mono.svg', markSvg(480, 'mono'))
  out('mark-reversed.svg', markSvg(480, 'reversed'))
  out('lockup-light.svg', lockupSvg('light'))
  out('lockup-dark.svg', lockupSvg('dark'))

  // The VitePress header shows the logo at 24 px: draw it on the 24 px grid.
  out('logo-light.svg', markSvg(24, 'light'))
  out('logo-dark.svg', markSvg(24, 'dark'))

  // Favicons
  out('favicon.svg', faviconSvg(CORNER))
  const icoImages = []
  for (const N of [16, 32, 48]) {
    const data = await png(markSvg(N, 'light', { packing: FAVICON_PACKING(N), margin: faviconMargin(N) }))
    out(`favicon-${N}.png`, data)
    icoImages.push({ size: N, data })
  }
  out('favicon.ico', ico(icoImages))

  // Opaque tiles
  out('apple-touch-icon.png', await png(tileSvg(180, 128)))
  out('avatar-512.png', await png(tileSvg(512, 320)))
  out('avatar-1000.png', await png(tileSvg(1000, 624)))

  // README banners and the share card
  out('banner-light@2x.png', await png(bannerSvg('light')))
  out('banner-dark@2x.png', await png(bannerSvg('dark')))
  out('og-image.jpg', await sharp(Buffer.from(cardSvg())).flatten({ background: PAPER })
    .jpeg({ quality: 72, mozjpeg: true, chromaSubsampling: '4:4:4' }).toBuffer())

  // Favicon check: both cuts at 16 and 32 px, on light and dark tabs, at 8×.
  out('favicon-check.png', await faviconCheck())

  // Deploy copies (outputs, not sources)
  fs.mkdirSync(PUBLIC, { recursive: true })
  for (const f of ['favicon.svg', 'favicon.ico', 'apple-touch-icon.png', 'og-image.jpg', 'logo-light.svg', 'logo-dark.svg']) {
    fs.copyFileSync(path.join(KIT, f), path.join(PUBLIC, f))
  }

  const sizes = fs.readdirSync(KIT).sort().map((f) => `${f}  ${fs.statSync(path.join(KIT, f)).size} B`)
  console.log(sizes.join('\n'))
}

async function faviconCheck() {
  const tabs = [['#FFFFFF', 'light'], ['#DFE1E5', 'light'], ['#35363A', 'dark'], ['#202124', 'dark']]
  const Z = 8, pad = 8
  const tiles = []
  let y = 0
  for (const packing of [CORNER, CORNER_CUT]) {
    let x = 0
    for (const N of [16, 32]) for (const [bg, mode] of tabs) {
      const raw = await sharp(Buffer.from(markSvg(N, mode, { packing, margin: faviconMargin(N) })))
        .flatten({ background: bg }).png().toBuffer()
      const big = await sharp(raw).resize(N * Z, N * Z, { kernel: 'nearest' }).png().toBuffer()
      tiles.push({ input: big, left: x, top: y })
      x += N * Z + pad
    }
    y += 32 * Z + pad
  }
  const width = 4 * (16 * Z + pad) + 4 * (32 * Z + pad)
  return sharp({ create: { width, height: y, channels: 4, background: '#F2F1EE' } }).composite(tiles).png().toBuffer()
}

if (process.argv[1] === fileURLToPath(import.meta.url)) await build()
