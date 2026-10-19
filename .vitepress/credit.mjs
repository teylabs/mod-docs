/*
 * The footer's two lines, as the Tey Labs brand guide sets them for every
 * product: the product's name, then `Built by Tey Labs, for {who it's for}.`
 * There is no ©. scripts/credit-line.test.mjs pins these words, so a tidy-up
 * can't reword this product's lines away from the others'.
 */
export const CREDIT_NAME = 'Mod'
export const CREDIT_BUILT = 'Built by <a href="https://teylabs.com" target="_blank" rel="noopener">Tey Labs</a>, for fellow Laravel developers and their agents.'

export const creditLine = '<span class="credit-line">'
  + `<span class="credit-line__name">${CREDIT_NAME}</span>`
  + `<span class="credit-line__built">${CREDIT_BUILT}</span>`
  + '</span>'
