# Checks docs/basics/layouts.md.
PAGE=$DOCS/docs/basics/layouts.md

# Choosing a Layout: --all trees
for L in modules features type-first ddd; do
    fresh "layout $L" $L
    check "The generator succeeds: mod:model Knowledge:Document --all" art mod:model Knowledge:Document --all
    case $L in
        modules) for f in Controllers/DocumentController Database/Factories/DocumentFactory Database/Seeders/DocumentSeeder Models/Document Policies/DocumentPolicy Requests/StoreDocumentRequest Requests/UpdateDocumentRequest 'Database/Migrations/*_create_documents_table'; do check "The file exists and passes PHP syntax: app/Modules/Knowledge/$f.php" has "app/Modules/Knowledge/$f.php"; done ;;
        features) for f in Http/Controllers/DocumentController Database/Factories/DocumentFactory Database/Seeders/DocumentSeeder Models/Document Policies/DocumentPolicy Http/Requests/StoreDocumentRequest Http/Requests/UpdateDocumentRequest 'Database/Migrations/*_create_documents_table'; do check "The file exists and passes PHP syntax: app/Features/Knowledge/$f.php" has "app/Features/Knowledge/$f.php"; done ;;
        type-first) for f in app/Http/Controllers/Knowledge/DocumentController app/Http/Requests/Knowledge/StoreDocumentRequest app/Http/Requests/Knowledge/UpdateDocumentRequest app/Models/Knowledge/Document app/Policies/Knowledge/DocumentPolicy database/factories/Knowledge/DocumentFactory 'database/migrations/Knowledge/*_create_documents_table' database/seeders/Knowledge/DocumentSeeder; do check "The file exists and passes PHP syntax: $f.php" has "$f.php"; done
            check "type-first: mod:model Document without a feature" art mod:model Document
            check "The file exists and passes PHP syntax: app/Models/Document.php" has app/Models/Document.php ;;
        ddd) for f in app/Modules/Knowledge/Controllers/DocumentController app/Modules/Knowledge/Requests/StoreDocumentRequest app/Modules/Knowledge/Requests/UpdateDocumentRequest src/Domain/Knowledge/Models/Document src/Domain/Knowledge/Policies/DocumentPolicy src/Domain/Knowledge/Database/Factories/DocumentFactory 'src/Domain/Knowledge/Database/Migrations/*_create_documents_table' src/Domain/Knowledge/Database/Seeders/DocumentSeeder; do check "The file exists and passes PHP syntax: $f.php" has "$f.php"; done ;;
    esac
done
fresh "layout laravel" laravel
check "laravel: mod:model Document" art mod:model Document
check "The file exists and passes PHP syntax: app/Models/Document.php" has app/Models/Document.php
check "laravel: Knowledge: prefix exits with an error" fails art mod:model Knowledge:Order

fresh "layout slices" slices
check "slices: Laravel's own folders are not existing features" sh -c "cd '$APP' && out=\$('$PHP' artisan mod:model Knowledge:Document -mf --no-interaction --no-ansi) && echo \"\$out\" | grep -qF 'Created new feature Knowledge.' && ! echo \"\$out\" | grep -qF 'existing:' && [ \$(echo \"\$out\" | grep -c 'Created new') = 1 ]"
check "slices: Htp is not a near miss of app/Http" sh -c "cd '$APP' && '$PHP' artisan mod:model Htp:Thing --no-interaction --no-ansi | grep -qF 'Created new feature Htp (existing: Knowledge).' && rm -rf app/Htp"
check "The generator succeeds: mod:handler --in=Knowledge/IndexDocument (no name)" art mod:handler --in=Knowledge/IndexDocument
check "The generator succeeds: mod:request --in=Knowledge/IndexDocument (no name)" art mod:request --in=Knowledge/IndexDocument
check "The generator succeeds: mod:message --in=Knowledge/IndexDocument (no name)" art mod:message --in=Knowledge/IndexDocument
for f in IndexDocument/Command IndexDocument/Handler IndexDocument/Request Models/Document Database/Factories/DocumentFactory 'Database/Migrations/*_create_documents_table'; do check "The file exists and passes PHP syntax: app/Knowledge/$f.php" has "app/Knowledge/$f.php"; done
check "features/slices: command without a value goes to app/Console/Commands" art mod:command PruneDocuments
check "The file exists and passes PHP syntax: app/Console/Commands/PruneDocuments.php" has app/Console/Commands/PruneDocuments.php
check "a different name is not used, and said" sh -c "cd '$APP' && rm -f app/Knowledge/IndexDocument/Handler.php && '$PHP' artisan mod:handler IssueInvoice --in=Knowledge/IndexDocument --no-ansi | grep -qF 'mod:handler always writes Handler.php; the name [IssueInvoice] is not used.'"
rm -f "$APP/app/Knowledge/IndexDocument/Handler.php"
check "The generator succeeds: mod:handler --feature=Knowledge --slice=IndexDocument" art mod:handler --feature=Knowledge --slice=IndexDocument
check "The file exists and passes PHP syntax: app/Knowledge/IndexDocument/Handler.php" has app/Knowledge/IndexDocument/Handler.php

# The DDD Layout + stub variants
fresh "ddd" ddd
art mod:autoload
check "mod:dto Knowledge:DocumentData creates the base" out_has "Created base class Domain\\Shared\\Data\\DataTransferObject" mod:dto Knowledge:DocumentData
check "The file exists and passes PHP syntax: src/Domain/Knowledge/Data/DocumentData.php" has src/Domain/Knowledge/Data/DocumentData.php
check "The generator succeeds: mod:action Knowledge:IndexDocument" art mod:action Knowledge:IndexDocument
check "action has handle()" grep -q 'public function handle(): void' "$APP/src/Domain/Knowledge/Actions/IndexDocument.php"
check "The generator succeeds: mod:value-object Knowledge:ContentHash" art mod:value-object Knowledge:ContentHash
check "The file exists and passes PHP syntax: src/Domain/Knowledge/ValueObjects/ContentHash.php" has src/Domain/Knowledge/ValueObjects/ContentHash.php
check "The generator succeeds: mod:view-model Knowledge:ShowDocument" art mod:view-model Knowledge:ShowDocument
check "The generator succeeds: mod:data alias" art mod:data Knowledge:ChunkData
check "The generator succeeds: mod:value alias" art mod:value Knowledge:Amount
check "The generator succeeds: mod:valueobject alias" art mod:valueobject Knowledge:Rate
check "The generator succeeds: mod:data-transfer-object alias" art mod:data-transfer-object Knowledge:PageData
check "The generator succeeds: mod:datatransferobject alias" art mod:datatransferobject Knowledge:TagData
check "The generator succeeds: mod:viewmodel alias" art mod:viewmodel Knowledge:ListDocuments
check "--domain=Knowledge.Search" art mod:model Report --domain=Knowledge.Search
check "The file exists and passes PHP syntax: src/Domain/Knowledge/Search/Models/Report.php" has src/Domain/Knowledge/Search/Models/Report.php
check "DTO autoloads and round-trips" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo class_exists(Domain\Knowledge\Data\DocumentData::class) ? \"ok\" : \"no\";' | grep -q ok"
# Trees are read from the page, with only migration timestamps normalized.
index=0
for layout in modules features type-first ddd; do
    index=$((index+1))
    fresh "documented $layout tree" "$layout"
    check "$layout generates all related files" art mod:model Knowledge:Document --all
    check "$layout files match the documented tree" doc_tree 'Comparing the Layouts' "$index"
done
fresh 'documented slices tree' slices
check 'The documented slice commands succeed' doc_shell 'The Slices Layout'
check 'Slice files match the documented tree' doc_tree 'The Slices Layout'
fresh 'documented type-first paths' type-first
check 'Type-first job paths match the page' doc_shell 'The Type-First Layout'
fresh 'documented domain classes' ddd
art mod:autoload
check 'DDD commands write the documented domain paths' doc_shell 'Generating Domain Classes'
check 'The documented DTO can be autoloaded' tinker 'new Domain\Knowledge\Data\DocumentData;'
fresh 'documented layout extension' modules
doc_boot 'Customizing a layout'
check 'The documented validator extension writes the stated path' doc_shell 'Customizing a layout'
# Exercise shell globbing even before a page adds template [slot] commands.
check 'A quoted bracket path survives zsh globbing' zsh_art "php artisan list --raw > 'commands[slot].txt'"
check 'The bracket path contains the command listing' grep -F 'mod:model' "$APP/commands[slot].txt"
