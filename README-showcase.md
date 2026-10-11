# README showcase preview

The static frame shows the organised app with Agents and Knowledge modules, and a versioned API in `src`. It is the last settled stage before the timelapse, so it makes sense without the loop's `index.php` ending.

<picture>
  <source media="(prefers-reduced-motion: reduce) and (prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/teylabs/mod-docs/f85580b899118ac84384705a109283356e476c2c/docs/public/evolve-still-dark.png">
  <source media="(prefers-reduced-motion: reduce)" srcset="https://raw.githubusercontent.com/teylabs/mod-docs/f85580b899118ac84384705a109283356e476c2c/docs/public/evolve-still-light.png">
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/teylabs/mod-docs/f85580b899118ac84384705a109283356e476c2c/docs/public/evolve-dark.svg">
  <img src="https://raw.githubusercontent.com/teylabs/mod-docs/f85580b899118ac84384705a109283356e476c2c/docs/public/evolve-light.svg" width="600" alt="A terminal watching a Laravel app grow from laravel new: an Actions folder, then modules, a versioned API in src, and a timelapse of ever more folders until it all collapses into a single index.php">
</picture>

GitHub currently rewrites the combined dark/reduced-motion query into a theme-only source. In its dark theme, the first source therefore selects the dark still even when reduced motion is off. This preview records the proposed ordering; resolve that behaviour before adopting it in the package README.

The animation is unchanged: a 19.4-second loop, with the API stage settling before the accelerating timelapse and the final collapse to `index.php`.

## Light still

<img src="https://raw.githubusercontent.com/teylabs/mod-docs/f85580b899118ac84384705a109283356e476c2c/docs/public/evolve-still-light.png" width="600" alt="A Laravel app organised into Agents and Knowledge modules, with a versioned API in src beside app.">

## Dark still

<img src="https://raw.githubusercontent.com/teylabs/mod-docs/f85580b899118ac84384705a109283356e476c2c/docs/public/evolve-still-dark.png" width="600" alt="A Laravel app organised into Agents and Knowledge modules, with a versioned API in src beside app.">

Both PNGs are 1200 × 1138 pixels. The light file is 57,910 bytes; the dark file is 58,073 bytes. Regenerate the animation and stills together with `python3 scripts/evolve-animation.py`; Google Chrome is required.
