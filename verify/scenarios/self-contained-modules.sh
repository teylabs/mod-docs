# Checks docs/going-further/self-contained-modules.md.
PAGE=$DOCS/docs/going-further/self-contained-modules.md

# Self-Contained Modules + the copy test (modules has view models and value objects built in)
fresh "self-contained modules" modules
check "The generator succeeds: mod:model Knowledge:Document -mf --controller --resource --requests" art mod:model Knowledge:Document -mf --controller --resource --requests
check "The generator succeeds: mod:policy Knowledge:DocumentPolicy --model=Document" art mod:policy Knowledge:DocumentPolicy --model=Document
check "the policy imports the module's model" grep -q 'use App\\Modules\\Knowledge\\Models\\Document;' "$APP/app/Modules/Knowledge/Policies/DocumentPolicy.php"
check "mod:model -f wrote newFactory()" grep -q 'protected static function newFactory()' "$APP/app/Modules/Knowledge/Models/Document.php"
check "the factory names its model by short name" grep -q 'protected \$model = Document::class;' "$APP/app/Modules/Knowledge/Database/Factories/DocumentFactory.php"
check "The generator succeeds: mod:action Knowledge:IndexDocument" art mod:action Knowledge:IndexDocument
check "mod:dto Knowledge:DocumentData writes the base in app/Support" sh -c "cd '$APP' && '$PHP' artisan mod:dto Knowledge:DocumentData --no-ansi | grep -qF 'Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php]'"
check "The generator succeeds: mod:event Knowledge:DocumentUploaded" art mod:event Knowledge:DocumentUploaded
check "The generator succeeds: mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded" art mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded
check "mod:view-model Knowledge:ShowDocument writes the base in app/Support" sh -c "cd '$APP' && '$PHP' artisan mod:view-model Knowledge:ShowDocument --no-ansi | grep -qF 'app/Support/ViewModels/ViewModel.php'"
check "The generator succeeds: mod:model Agents:Conversation -m" art mod:model Agents:Conversation -m
check "The generator succeeds: mod:action Agents:AnswerQuestion" art mod:action Agents:AnswerQuestion
check "mod:value-object Agents:TokenUsage" sh -c "cd '$APP' && '$PHP' artisan mod:value-object Agents:TokenUsage --no-ansi | grep -qF 'Value object [app/Modules/Agents/ValueObjects/TokenUsage.php]'"
check "The generator succeeds: mod:job Agents:GenerateReply" art mod:job Agents:GenerateReply
TREE=$(cd "$APP" && find app/Modules -type f | sort | sed -E 's/[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{6}_/TS_/' | tr '\n' ' ')
EXPECT="app/Modules/Agents/Actions/AnswerQuestion.php app/Modules/Agents/Database/Migrations/TS_create_conversations_table.php app/Modules/Agents/Jobs/GenerateReply.php app/Modules/Agents/Models/Conversation.php app/Modules/Agents/ValueObjects/TokenUsage.php app/Modules/Knowledge/Actions/IndexDocument.php app/Modules/Knowledge/Http/Controllers/DocumentController.php app/Modules/Knowledge/Data/DocumentData.php app/Modules/Knowledge/Database/Factories/DocumentFactory.php app/Modules/Knowledge/Database/Migrations/TS_create_documents_table.php app/Modules/Knowledge/Events/DocumentUploaded.php app/Modules/Knowledge/Listeners/GenerateEmbeddings.php app/Modules/Knowledge/Models/Document.php app/Modules/Knowledge/Policies/DocumentPolicy.php app/Modules/Knowledge/Http/Requests/StoreDocumentRequest.php app/Modules/Knowledge/Http/Requests/UpdateDocumentRequest.php app/Modules/Knowledge/ViewModels/ShowDocument.php "
EXPECT=$(printf '%s\n' "$EXPECT" | tr ' ' '\n' | sed '/^$/d' | sort | tr '\n' ' ')
check "The two modules contain exactly the expected files" test "$TREE" = "$EXPECT"
[ "$TREE" = "$EXPECT" ] || printf 'Actual tree: %s\n' "$TREE" >&2
check "bases live outside app/Modules, in app/Support" sh -c "test -f '$APP/app/Support/Data/DataTransferObject.php' && test -f '$APP/app/Support/ViewModels/ViewModel.php'"
for f in $(cd "$APP" && find app/Modules app/Support -name '*.php'); do check "php -l $f" "$PHP" -l "$APP/$f"; done
# Module Routes
check "mod:provider Knowledge:Knowledge" sh -c "cd '$APP' && '$PHP' artisan mod:provider Knowledge:Knowledge --no-ansi | grep -qF 'app/Modules/Knowledge/Providers/KnowledgeServiceProvider.php'"
perl -0pi -e 's/(public function boot\(\): void\s*\{)\s*\/\/\n/$1\n        \$this->loadRoutesFrom(__DIR__.\x27\/..\/routes\/web.php\x27);\n/' "$APP/app/Modules/Knowledge/Providers/KnowledgeServiceProvider.php"
check "provider boot loads routes" grep -qF "\$this->loadRoutesFrom(__DIR__.'/../routes/web.php');" "$APP/app/Modules/Knowledge/Providers/KnowledgeServiceProvider.php"
mkdir -p "$APP/app/Modules/Knowledge/routes"; cat > "$APP/app/Modules/Knowledge/routes/web.php" <<'PHP'
<?php

use App\Modules\Knowledge\Http\Controllers\DocumentController;
use Illuminate\Support\Facades\Route;

Route::middleware('web')->group(function () {
    Route::resource('documents', DocumentController::class);
});
PHP
check "route:list shows the module's routes" out_has "documents.index" route:list --path=documents
check "the route has the web middleware" sh -c "cd '$APP' && '$PHP' artisan route:list --path=documents --json | grep -q '\"web\"'"
check "GET /documents returns 200" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo app(Illuminate\Contracts\Http\Kernel::class)->handle(Illuminate\Http\Request::create(\"/documents\"))->getStatusCode();' | grep -q 200"
check "discovery.md's mod:cache output, verbatim" sh -c "cd '$APP' && out=\$('$PHP' artisan mod:cache --no-ansi) && '$PHP' artisan mod:clear -q && echo \"\$out\" | grep -qF 'Discovery cached in [bootstrap/cache/mod-discovery.php]: 1 providers, 0 commands, 1 listeners, 0 subscribers, 2 directories, 5 rejected.' && echo \"\$out\" | grep -qF 'Rejected files were found but not registered: 5 placed by no file type (helpers and plain classes; nothing to do). Run with -v to list them.'"
(cd "$APP" && "$PHP" artisan mod:cache --no-ansi; "$PHP" artisan mod:clear -q) >> "$WORK/modcache-$MAJOR.txt"
check "route:cache includes them" sh -c "cd '$APP' && '$PHP' artisan route:cache -q && '$PHP' artisan route:list --path=documents | grep -q documents.store && '$PHP' artisan route:clear -q"
SRCAPP=$APP
# The copy test: a second fresh app of the same Laravel version on the plain modules layout.
COPY=$WORK/copy-$MAJOR; rm -rf "$COPY"; cp -R "$WORK/base-$MAJOR" "$COPY"; APP=$COPY
fresh "copy test" modules
check "the second app has no modules and no bases" sh -c "test ! -d '$APP/app/Modules' && test ! -d '$APP/app/Support'"
mkdir -p "$APP/app/Modules"; cp -R "$SRCAPP/app/Modules/Knowledge" "$APP/app/Modules/Knowledge"; cp -R "$SRCAPP/app/Modules/Agents" "$APP/app/Modules/Agents"
check "before mod:bases the DTO's base is missing" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'new App\Modules\Knowledge\Data\DocumentData;' 2>&1 | grep -q 'DataTransferObject\" not found'"
check "mod:bases writes both bases" sh -c "cd '$APP' && out=\$('$PHP' artisan mod:bases --no-ansi) && echo \"\$out\" | grep -qF 'app/Support/Data/DataTransferObject.php' && echo \"\$out\" | grep -qF 'app/Support/ViewModels/ViewModel.php'"
check "mod:bases a second time writes nothing" sh -c "cd '$APP' && '$PHP' artisan mod:bases --no-ansi | grep -qF 'Every base class already exists.'"
check "the DTO and view model load after mod:bases" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'new App\Modules\Knowledge\Data\DocumentData; echo class_exists(App\Modules\Knowledge\ViewModels\ShowDocument::class) ? \"ok\" : \"no\";' | grep -q ok"
check "migrate --pretend sees both module tables" sh -c "cd '$APP' && out=\$('$PHP' artisan migrate --pretend) && echo \"\$out\" | grep -q 'create table \"documents\"' && echo \"\$out\" | grep -q 'create table \"conversations\"'"
check "event:list shows GenerateEmbeddings exactly once" sh -c "[ \$(cd '$APP' && '$PHP' artisan event:list --event=DocumentUploaded | grep -c 'App.Modules.Knowledge.Listeners.GenerateEmbeddings@handle') = 1 ]"
check "both modules migrate" sh -c "cd '$APP' && '$PHP' artisan migrate --force 2>&1 | grep -q create_conversations_table && '$PHP' artisan migrate:status | grep -q create_documents_table"
check "Document::factory()->create() resolves the module factory" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo get_class(App\Modules\Knowledge\Models\Document::factory()), \" \", App\Modules\Knowledge\Models\Document::factory()->create()->id;' | grep -q 'App.Modules.Knowledge.Database.Factories.DocumentFactory 1'"
check "copy: the policy resolves" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo get_class(Illuminate\Support\Facades\Gate::getPolicyFor(App\Modules\Knowledge\Models\Document::class));' | grep -q 'App.Modules.Knowledge.Policies.DocumentPolicy'"
check "copy: the module's routes come along" out_has "documents.index" route:list --path=documents
check "copy: GET /documents returns 200" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo app(Illuminate\Contracts\Http\Kernel::class)->handle(Illuminate\Http\Request::create(\"/documents\"))->getStatusCode();' | grep -q 200"
APP=$WORK/base-$MAJOR


fresh 'documented two-module tree' modules
check 'All commands in the two-module example succeed' doc_shell 'Building Two Modules'
check 'The generated modules match the documented tree' doc_tree 'Building Two Modules'
check 'The shared DTO base output matches the page' doc_output 'Building Two Modules' 2
doc_file 'Adding Routes' app/Modules/Knowledge/routes/web.php
# This provider already belongs to the module, rather than AppServiceProvider.
route_boot=$(doc_block 'Adding Routes' php 2)
EXT=$route_boot perl -0pi -e 's/(public function boot\(\): void\s*\{)/$1\n        $ENV{EXT}\n/' "$APP/app/Modules/Knowledge/Providers/KnowledgeServiceProvider.php"
check 'The documented routes register with web middleware' out_has 'documents.index' route:list --path=documents
export APP WORK
check 'The documented provider and modules produce the stated discovery counts' bash -c 'cd "$APP" && "$PHP" artisan mod:cache --no-ansi > "$WORK/doc-output.txt" && "$PHP" artisan mod:clear -q'
PAGE=$DOCS/docs/basics/auto-discovery.md
check 'Discovery cache output matches its page verbatim' doc_output 'Caching Discovery in Production'
