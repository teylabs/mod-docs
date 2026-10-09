#!/usr/bin/env bash
set -euo pipefail
WORK=$1; MAJOR=$2; STACK=$3
VERIFY=$(cd "$(dirname "$0")/.." && pwd)
DOCS=$(cd "$VERIFY/.." && pwd)
PHP=${PHP:-php}; COMPOSER_BIN=${COMPOSER_BIN:-$(command -v composer)}
export PATH="$(dirname "$PHP"):$PATH"
test -f "$WORK/.mod-docs-harness"
APP=$WORK/frontend-$MAJOR-$STACK
case "$STACK:$MAJOR" in
    vue:12) REV=3c59b1edaeefd31561ae3854a5b2af10a9483292;;
    react:12) REV=b4712e343ea9b1a684999026f127c6e091fd7427;;
    vue:13) REV=d282e817c6c2fa1bd475f7c42ea785ccfc67d0ab;;
    react:13) REV=717b8f55aefd82d25d4119eaebdc8e3a72b8d7e5;;
    *) exit 1;;
esac
if [ ! -d "$APP/.git" ]; then
    mkdir -p "$APP"
    git -C "$APP" init -q
    git -C "$APP" remote add origin "https://github.com/laravel/$STACK-starter-kit.git"
fi
if ! git -C "$APP" cat-file -e "$REV^{commit}" 2>/dev/null; then
    git -C "$APP" fetch --depth=1 origin "$REV"
fi
git -C "$APP" checkout -q --detach "$REV"
git -C "$APP" reset -q --hard "$REV"
git -C "$APP" clean -fdq -e vendor -e node_modules
printf '%s %s\n' "$STACK" "$REV" >> "$WORK/kit-refs.txt"
(
    cd "$APP"
    "$PHP" "$COMPOSER_BIN" config repositories.mod "{\"type\":\"path\",\"url\":\"$WORK/mod-src\",\"options\":{\"symlink\":false}}"
    "$PHP" "$COMPOSER_BIN" require 'tey/mod:*@dev' --no-interaction --no-scripts -q
    cp .env.example .env
    rm -f database/database.sqlite
    touch database/database.sqlite
    "$PHP" artisan package:discover -q
    "$PHP" artisan key:generate -q
    "$PHP" artisan vendor:publish --tag=mod-config -q
    LAYOUT=modules perl -0pi -e 's/\x27layout\x27 => \x27[^\x27]*\x27/\x27layout\x27 => \x27modules\x27/' config/mod.php
    if [ -f package-lock.json ]; then npm ci --no-audit --no-fund; else npm install --no-audit --no-fund; fi
)
mkdir -p "$APP/stubs" "$APP/app/Modules/Inventory"
# Copy the exact request variant already exercised by the PHP acceptance tests.
cp "$WORK/mod-src/tests/Feature/Scaffolds/Support/request.stub" "$APP/stubs/mod.request.crud.stub"
"$PHP" "$VERIFY/docs.php" block "$DOCS/docs/going-further/scaffolds.md" 'Generating a Recipe' php 1 > "$WORK/crud.php"
"$PHP" "$VERIFY/docs.php" block "$DOCS/docs/going-further/frontend.md" 'Generating Pages With Their Controller' php 1 > "$WORK/crud-pages.php"
"$PHP" -r '
$parts = array_map(fn ($file) => file_get_contents($file), array_slice($argv, 2));
$imports = ["use Tey\\Mod\\Facades\\Mod;", "use Tey\\Mod\\Scaffolds\\Scaffold;"];
$code = implode("\n", array_map(fn ($part) => preg_replace("/^use .+;\\n?/m", "", $part), $parts));
file_put_contents($argv[1], "<?php\nnamespace App\\Providers;\nuse Illuminate\\Support\\ServiceProvider;\n".implode("\n",$imports)."\nclass AppServiceProvider extends ServiceProvider { public function register(): void {} public function boot(): void {\n".$code."\n} }\n");
' "$APP/app/Providers/AppServiceProvider.php" "$WORK/crud.php" "$WORK/crud-pages.php"
"$PHP" "$VERIFY/docs.php" block "$DOCS/docs/going-further/frontend.md" 'The Controller Template' php 1 > "$APP/stubs/mod.controller.inertia-crud.stub"
"$PHP" "$VERIFY/docs.php" block "$DOCS/docs/going-further/frontend.md" 'The Vue Index Template' vue 1 > "$APP/stubs/mod.page.crud-index.vue.stub"
"$PHP" "$VERIFY/docs.php" block "$DOCS/docs/going-further/frontend.md" 'The React Index Template' tsx 1 > "$APP/stubs/mod.page.crud-index.tsx.stub"
for variant in crud-form crud-show; do
    "$PHP" "$VERIFY/docs.php" block "$DOCS/docs/going-further/frontend.md" 'The Remaining Pages' vue 1 > "$APP/stubs/mod.page.$variant.vue.stub"
    "$PHP" "$VERIFY/docs.php" block "$DOCS/docs/going-further/frontend.md" 'The Remaining Pages' tsx 1 > "$APP/stubs/mod.page.$variant.tsx.stub"
done
# Load the same route example shown with the frontend recipe.
"$PHP" "$VERIFY/docs.php" block "$DOCS/docs/going-further/frontend.md" 'Loading the Widgets Route' php 1 > "$APP/routes/widgets.php"
printf '\nrequire __DIR__.\x27/widgets.php\x27;\n' >> "$APP/routes/web.php"

"$PHP" "$VERIFY/frontend/prepare-kit.php" "$APP" "$MAJOR" "$STACK"
