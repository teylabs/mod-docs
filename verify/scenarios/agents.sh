PAGE=$DOCS/docs/going-further/agents.md
fresh agents modules
check 'documented inventory command' doc_shell 'Reading the Inventory'
check 'complete composed inventory keys' "$PHP" -r '$j=json_decode(file_get_contents($argv[1]),true,512,JSON_THROW_ON_ERROR); foreach(["layout","types","templates","scaffolds","discovery","stack","frontend","views","routes","wiring"] as $key) { if(!array_key_exists($key,$j)) throw new RuntimeException("Missing ".$key); }' "$WORK/doc-output.txt"
check 'plan warns about missing answers without writing' art mod:model Widget --dry-run --json
check 'schema files match the package contract' bash -c 'cmp "$1/docs/public/schemas/plan.json" "$2/tests/Fixtures/schema/plan.json" && cmp "$1/docs/public/schemas/inventory.json" "$2/tests/Fixtures/schema/inventory.json"' harness "$DOCS" "$WORK/mod-src"

check 'rename schema matches the package contract' cmp "$DOCS/docs/public/schemas/rename.json" "$WORK/mod-src/tests/Fixtures/schema/rename.json"
check 'install optional Boost tool fixture' bash -c 'cd "$1" && "$PHP" "$COMPOSER_BIN" require --dev "laravel/boost:^2.10" --no-interaction -q' harness "$APP"
boot "\\Tey\\Mod\\Facades\\Mod::scaffold('model-only', fn (\\Tey\\Mod\\Scaffolds\\Scaffold \$s) => \$s->makes('model'));"
check 'actual MCP rename and recovery are read-only' "$PHP" "$VERIFY/rename/tools.php" "$APP"
check 'exact complete R14 plan and no-write preview' "$PHP" "$VERIFY/rename/r14.php" "$APP" "$PAGE"
