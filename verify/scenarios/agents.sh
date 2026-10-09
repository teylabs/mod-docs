PAGE=$DOCS/docs/going-further/agents.md
fresh agents modules
check 'documented inventory command' doc_shell 'Reading the Inventory'
check 'complete composed inventory keys' "$PHP" -r '$j=json_decode(file_get_contents($argv[1]),true,512,JSON_THROW_ON_ERROR); foreach(["layout","types","templates","scaffolds","discovery","stack","frontend","views","routes","wiring"] as $key) { if(!array_key_exists($key,$j)) throw new RuntimeException("Missing ".$key); }' "$WORK/doc-output.txt"
check 'plan warns about missing answers without writing' art mod:model Widget --dry-run --json
check 'schema files match the package contract' bash -c 'cmp "$1/docs/public/schemas/plan.json" "$2/tests/Fixtures/schema/plan.json" && cmp "$1/docs/public/schemas/inventory.json" "$2/tests/Fixtures/schema/inventory.json"' harness "$DOCS" "$WORK/mod-src"
