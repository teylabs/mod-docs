#!/usr/bin/env bash
# Create disposable Laravel apps; never run against an existing application.
set -euo pipefail
if [ "$#" -lt 3 ]; then
    echo 'Usage: verify/setup.sh <workdir> <mod-path|git:ref> <12|13> [...]' >&2
    exit 1
fi
WORK=$1; SRC=$2; shift 2
PHP=${PHP:-php}
COMPOSER_BIN=${COMPOSER_BIN:-$(command -v composer)}
export PHP COMPOSER_BIN COMPOSER_NO_INTERACTION=1
composer() { "$PHP" "$COMPOSER_BIN" "$@"; }
for major in "$@"; do
    case $major in 12|13) ;; *) echo "Unsupported Laravel version: $major" >&2; exit 1;; esac
done
mkdir -p "$WORK"
WORK=$(cd "$WORK" && pwd)
# Only replace directories created by this harness.
for target in mod-src "$@"; do
    case $target in mod-src) dir=$WORK/mod-src;; *) dir=$WORK/base-$target;; esac
    if [ -e "$dir" ] && [ ! -f "$WORK/.mod-docs-harness" ]; then
        echo "Refusing to replace $dir: work directory is not owned by this harness." >&2
        exit 1
    fi
done
case $SRC in
    git:*)
        ref=${SRC#git:}
        test -n "$ref"
        checkout=$(mktemp -d)
        trap 'rm -rf "$checkout"' EXIT
        git -C "$checkout" init -q
        git -C "$checkout" remote add origin https://github.com/teylabs/mod.git
        git -C "$checkout" fetch --depth=1 origin "$ref"
        git -C "$checkout" checkout -q --detach FETCH_HEAD
        SRC=$checkout
        ;;
    *) SRC=$(cd "$SRC" && pwd);;
esac
test -f "$SRC/composer.json"
"$PHP" -r '$j=json_decode(file_get_contents($argv[1]),true,512,JSON_THROW_ON_ERROR); exit(($j["name"]??"") === "tey/mod" ? 0 : 1);' "$SRC/composer.json"
touch "$WORK/.mod-docs-harness"
rm -rf "$WORK/mod-src"
mkdir -p "$WORK/mod-src"
rsync -a --exclude vendor --exclude composer.lock --exclude build --exclude .phpunit.cache --exclude .git "$SRC/" "$WORK/mod-src/"
git -C "$SRC" rev-parse HEAD > "$WORK/mod-ref.txt"
for major in "$@"; do
    base=$WORK/base-$major
    rm -rf "$base"
    composer create-project "laravel/laravel:^$major.0" "$base" --prefer-dist -q
    (
        cd "$base"
        composer config repositories.mod "{\"type\":\"path\",\"url\":\"$WORK/mod-src\",\"options\":{\"symlink\":false}}"
        composer require 'tey/mod:*@dev' -q
        git init -q
        git add -A
        git -c user.name='Docs harness' -c user.email='harness@localhost' commit -qm 'Create the disposable app'
    )
    echo "ready: $base ($("$PHP" "$base/artisan" --version))"
done
