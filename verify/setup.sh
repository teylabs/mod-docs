#!/usr/bin/env bash
# Create disposable Laravel apps; never run against an existing application.
set -euo pipefail
if [ "$#" -lt 3 ]; then
    echo 'Usage: verify/setup.sh <workdir> <mod-path|git:ref> <12|13> [...]' >&2
    exit 1
fi
WORK=$1; SRC=$2; shift 2
PHP=${PHP:-$(command -v php)}
COMPOSER_BIN=${COMPOSER_BIN:-$(command -v composer)}
export PHP COMPOSER_BIN COMPOSER_NO_INTERACTION=1
composer() { "$PHP" "$COMPOSER_BIN" "$@"; }
for major in "$@"; do
    case $major in 12|13) ;; *) echo "Unsupported Laravel version: $major" >&2; exit 1;; esac
done
case $SRC in
    git:*)
        ref=${SRC#git:}
        if [[ -z "$ref" || "$ref" == -* ]] || ! git check-ref-format "refs/heads/$ref"; then
            echo "Invalid Git ref: '$ref'. Use a branch, tag, or full 40-character commit SHA." >&2
            exit 1
        fi
        # A shallow fetch cannot prove that an abbreviated object ID is unique.
        if [[ "$ref" =~ ^[0-9a-fA-F]+$ && ${#ref} -ne 40 ]]; then
            echo "Abbreviated Git object IDs are unsupported; use the full 40-character commit SHA. For a hexadecimal branch or tag name, use refs/heads/<name> or refs/tags/<name>." >&2
            exit 1
        fi
        ;;
esac
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
        checkout=$(mktemp -d)
        trap 'rm -rf "$checkout"' EXIT
        git -C "$checkout" init -q
        git -C "$checkout" remote add origin https://github.com/teylabs/mod.git
        if ! git -C "$checkout" fetch --depth=1 origin "$ref"; then
            echo "Unable to fetch Git ref '$ref' from teylabs/mod. Check the branch, tag, or full commit SHA and remote access." >&2
            exit 1
        fi
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
git -C "$SRC" rev-parse --verify 'HEAD^{commit}' > "$WORK/mod-ref.txt"
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
