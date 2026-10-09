# Shared helpers for disposable apps created by setup.sh.
PHP=${PHP:-$(command -v php)}
COMPOSER_BIN=${COMPOSER_BIN:-$(command -v composer)}
export PHP COMPOSER_BIN COMPOSER_NO_INTERACTION=1 COLUMNS=72 TERM=dumb
art() { (cd "$APP" && "$PHP" artisan "$@" --no-ansi --no-interaction 2>&1); }
# Keep the caller's shell text intact: zsh must see quotes and bracket globs.
zsh_art() { (cd "$APP" && zsh -f -e -o pipefail -c 'php() { "$PHP" "$@"; }; eval "$1"' harness "$1" 2>&1); }
record() {
    printf '%s | L%s %s | %s\n' "$1" "$MAJOR" "$SCENARIO" "$2" | tee -a "$LOG"
    case $1 in PASS) PASS=$((PASS+1));; FAIL) FAIL=$((FAIL+1));; esac
}
check() {
    local what=$1; shift
    if "$@" > "$WORK/check-output.txt" 2>&1; then
        record PASS "$what"
    else
        record FAIL "$what"
        cat "$WORK/check-output.txt" >&2
    fi
}
has() {
    local files=()
    # Intentional filename expansion for migration timestamps; quote APP.
    while IFS= read -r file; do files+=("$file"); done < <(compgen -G "$APP/$1" || true)
    [ "${#files[@]}" -eq 1 ] && [ -f "${files[0]}" ] && "$PHP" -l "${files[0]}" > /dev/null
}
out_has() {
    local needle=$1 output; shift
    output=$(art "$@") || return
    printf '%s\n' "$output" | grep -F -- "$needle" > /dev/null
}
fails() { if "$@"; then return 1; else return 0; fi; }
tinker() { art tinker --execute "$1"; }
fresh() {
    # The first argument labels the fixture; SCENARIO stays the page's name.
    test -f "$WORK/.mod-docs-harness" || return 1
    case $APP in "$WORK"/base-12|"$WORK"/base-13|"$WORK"/copy-12|"$WORK"/copy-13) ;; *) return 1;; esac
    (
        cd "$APP" && git reset -q --hard && git clean -fdq &&
        rm -f database/database.sqlite bootstrap/cache/mod-discovery.php &&
        touch database/database.sqlite && "$PHP" artisan migrate -q --force &&
        "$PHP" artisan vendor:publish --tag=mod-config -q
    ) || return
    LAYOUT=$2 perl -0pi -e 's/\x27layout\x27 => \x27[^\x27]*\x27/\x27layout\x27 => \x27$ENV{LAYOUT}\x27/' "$APP/config/mod.php"
}
boot() {
    EXT=$1 perl -0pi -e 's/(public function boot\(\): void\s*\{)/$1\n        $ENV{EXT}\n/' "$APP/app/Providers/AppServiceProvider.php"
}
autoload() {
    "$PHP" -r '$f=$argv[1]; $j=json_decode(file_get_contents($f),true,512,JSON_THROW_ON_ERROR); $j["autoload"]["psr-4"][$argv[2]]=$argv[3]; file_put_contents($f,json_encode($j,JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES)."\n");' "$APP/composer.json" "$1" "$2"
    (cd "$APP" && "$PHP" "$COMPOSER_BIN" dump-autoload -q)
}
# Select by heading and language so checks remain understandable when pages grow.
doc_block() { "$PHP" "$VERIFY/docs.php" block "$PAGE" "$@"; }
doc_boot() {
    local code
    code=$(doc_block "$1" php "${2:-1}") || return
    # Imports belong at file scope, statements inside boot().
    CODE=$code "$PHP" -r '
        $f=$argv[1]; $s=file_get_contents($f); $code=getenv("CODE");
        preg_match_all("/^use .+;$/m", $code, $uses);
        $code=preg_replace("/^use .+;\\n?/m", "", $code);
        foreach ($uses[0] as $use) { if (!str_contains($s,$use)) $s=str_replace("namespace App\\Providers;", "namespace App\\Providers;\n".$use, $s); }
        $s=preg_replace_callback("/public function boot\\(\\): void\\s*\\{/", fn($m) => $m[0]."\n".$code."\n", $s);
        file_put_contents($f,$s);
    ' "$APP/app/Providers/AppServiceProvider.php"
}
doc_file() {
    local code
    code=$(doc_block "$1" php "${3:-1}") || return
    mkdir -p "$(dirname "$APP/$2")"
    printf '%s\n' "$code" > "$APP/$2"
}
doc_shell() {
    local code output command_exit=0
    code=$(doc_block "$1" bash "${2:-1}") || return
    output=$(zsh_art "$code") || command_exit=$?
    printf '%s\n' "$output" > "$WORK/doc-output.txt"
    [ "$command_exit" -eq "${3:-0}" ] || { printf '%s\n' "$output"; return 1; }
    "$PHP" "$VERIFY/docs.php" output "$PAGE" "$1" bash "${2:-1}" "$WORK/doc-output.txt" "$APP"
}
doc_output() { "$PHP" "$VERIFY/docs.php" output "$PAGE" "$1" text "${2:-1}" "$WORK/doc-output.txt" "$APP"; }
doc_tree() { "$PHP" "$VERIFY/docs.php" tree "$PAGE" "$1" text "${2:-1}" "$APP"; }
doc_config() {
    local code
    code=$(doc_block "$1" php "${2:-1}") || return
    CODE=$code "$PHP" -r '
        $f=$argv[1]; $config=require $f;
        $fragment=eval("return [".getenv("CODE")."]; ");
        file_put_contents($f,"<?php\n\nreturn ".var_export(array_replace_recursive($config,$fragment),true).";\n");
    ' "$APP/config/mod.php"
}
