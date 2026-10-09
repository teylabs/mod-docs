# Checks docs/basics/auto-discovery.md.
PAGE=$DOCS/docs/basics/auto-discovery.md

# Production
fresh "production cache" modules
art mod:model Knowledge:Document -mf > /dev/null
art mod:event Knowledge:DocumentUploaded > /dev/null
art mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded > /dev/null
check "optimize writes the cache" sh -c "cd '$APP' && '$PHP' artisan optimize >/dev/null && test -f bootstrap/cache/mod-discovery.php"
check "listener once from the cache" sh -c "[ \$(cd '$APP' && '$PHP' artisan event:list --event=DocumentUploaded | grep -c GenerateEmbeddings) = 1 ]"
check "optimize:clear removes the cache" sh -c "cd '$APP' && '$PHP' artisan optimize:clear >/dev/null && test ! -f bootstrap/cache/mod-discovery.php"
check "The generator succeeds: mod:cache" art mod:cache
check "mod:cache explains rejected files" sh -c "cd '$APP' && '$PHP' artisan mod:cache --no-ansi | grep -qF 'Rejected files were found but not registered: ' && '$PHP' artisan mod:cache --no-ansi | grep -qF 'placed by no file type (helpers and plain classes; nothing to do)' && '$PHP' artisan mod:cache --no-ansi | grep -qF 'Run with -v to list them.'"
check "mod:cache -v lists app/Models/User.php" sh -c "cd '$APP' && '$PHP' artisan mod:cache -v --no-ansi | grep -qF 'app/Models/User.php: placed by no file type'"
check "The generator succeeds: mod:clear" art mod:clear

# Discovery examples
fresh "docs: discover anywhere" ddd
autoload 'Domain\' 'src/Domain/'
doc_boot 'Discovering Anywhere in a Domain'
art mod:event Knowledge:DocumentUploaded >/dev/null; art mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded >/dev/null
D="$APP/src/Domain/Knowledge"; mkdir -p "$D/Support" "$D/Tests"
sed 's/namespace Domain\\Knowledge\\Listeners;/namespace Domain\\Knowledge\\Support;/; s/class GenerateEmbeddings/class AuditChunk/' "$D/Listeners/GenerateEmbeddings.php" > "$D/Support/AuditChunk.php"
sed 's/namespace Domain\\Knowledge\\Listeners;/namespace Domain\\Knowledge\\Tests;/; s/class GenerateEmbeddings/class FakeListener/' "$D/Listeners/GenerateEmbeddings.php" > "$D/Tests/FakeListener.php"
check "the listener in Listeners/ is discovered" out_has "GenerateEmbeddings@handle" event:list --event=DocumentUploaded
check "a listener outside Listeners/ is discovered" out_has "AuditChunk@handle" event:list --event=DocumentUploaded
check "discoverExcept: ['Tests'] skips Tests/" fails out_has "FakeListener" event:list --event=DocumentUploaded
fresh "docs: migrations off" modules
doc_config 'Discovering Other File Types' 3
art mod:migration Knowledge:create_payments_table --create=payments >/dev/null
check "'migration' => false leaves module migrations out" fails out_has "create_payments_table" migrate:status
fresh "docs: factories without newFactory" modules
art mod:model Knowledge:Document -f >/dev/null
perl -0pi -e 's/\n\n    protected static function newFactory\(\).*?\n    \}\n/\n/s' "$APP/app/Modules/Knowledge/Models/Document.php"
check "newFactory() removed" fails grep -q newFactory "$APP/app/Modules/Knowledge/Models/Document.php"
check "Document::factory() still resolves" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo get_class(App\Modules\Knowledge\Models\Document::factory());' | grep -q 'App.Modules.Knowledge.Database.Factories.DocumentFactory'"
# Discovery examples: subscribers, mapping by file type id, enabled => false
fresh "docs: subscriber file type" modules
doc_boot 'Discovering Event Subscribers'
art mod:event Knowledge:DocumentUploaded >/dev/null
mkdir -p "$APP/app/Modules/Knowledge/Subscribers"
cat > "$APP/app/Modules/Knowledge/Subscribers/DocumentSubscriber.php" <<'PHP'
<?php

namespace App\Modules\Knowledge\Subscribers;

use App\Modules\Knowledge\Events\DocumentUploaded;
use Illuminate\Events\Dispatcher;

class DocumentSubscriber
{
    public function handleUploaded(DocumentUploaded $event): void {}

    public function subscribe(Dispatcher $events): array
    {
        return [DocumentUploaded::class => 'handleUploaded'];
    }
}
PHP
check "a subscriber file type is subscribed" out_has "DocumentSubscriber@handleUploaded" event:list --event=DocumentUploaded
fresh "docs: handler mapped to listener" modules
doc_boot 'Discovering Other File Types'
doc_config 'Discovering Other File Types' 2
art mod:event Knowledge:DocumentUploaded >/dev/null
check "The generator succeeds: mod:handler Knowledge:IndexUploadedDocument" art mod:handler Knowledge:IndexUploadedDocument
cat > "$APP/app/Modules/Knowledge/Handlers/IndexUploadedDocument.php" <<'PHP'
<?php

namespace App\Modules\Knowledge\Handlers;

use App\Modules\Knowledge\Events\DocumentUploaded;

class IndexUploadedDocument
{
    public function handle(DocumentUploaded $event): void {}
}
PHP
check 'The documented handler listing command succeeds' doc_shell 'Discovering Other File Types'
check 'The handler registration matches the page' doc_output 'Discovering Other File Types'
fresh "docs: unknown discovery key" modules
perl -0pi -e "s/'file_types' => \[\]/'file_types' => ['console' => 'command']/" "$APP/config/mod.php"
check "an unknown key stops the app and lists the file type ids" sh -c "cd '$APP' && '$PHP' artisan about --no-ansi 2>&1 | grep -q 'command'; ! '$PHP' artisan about >/dev/null 2>&1"
fresh "docs: enabled false" modules
art mod:model Knowledge:Document -f >/dev/null
perl -0pi -e 's/\n\n    protected static function newFactory\(\).*?\n    \}\n/\n/s' "$APP/app/Modules/Knowledge/Models/Document.php"
check "factory found with discovery on" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo get_class(App\Modules\Knowledge\Models\Document::factory());' | grep -q 'App.Modules.Knowledge.Database.Factories.DocumentFactory'"
perl -0pi -e "s/'enabled' => true/'enabled' => false/" "$APP/config/mod.php"
check "enabled => false turns factory lookup off" sh -c "cd '$APP' && ! '$PHP' artisan tinker --execute 'echo get_class(App\Modules\Knowledge\Models\Document::factory());' 2>&1 | grep -q 'App.Modules.Knowledge.Database.Factories.DocumentFactory'"

fresh 'documented listener registration' modules
art mod:model Knowledge:Document -mf > /dev/null
art mod:event Knowledge:DocumentUploaded > /dev/null
art mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded > /dev/null
check 'The event listing command from the page succeeds' doc_shell 'Discovering Listeners'
check 'Listener registration matches the documented output' doc_output 'Discovering Listeners'
check 'The migration command from the page succeeds' doc_shell 'Running Module Migrations'
check 'Migration output matches the page' doc_output 'Running Module Migrations'
fresh 'documented subscriber generator' modules
doc_boot 'Discovering Event Subscribers'
check 'The subscriber generator writes the documented path' doc_shell 'Discovering Event Subscribers'
fresh 'documented factory and policy switches' modules
art mod:model Knowledge:Document -f > /dev/null
art mod:policy Knowledge:DocumentPolicy --model=Document > /dev/null
perl -0pi -e 's/\n\n    protected static function newFactory\(\).*?\n    \}\n/\n/s' "$APP/app/Modules/Knowledge/Models/Document.php"
doc_config 'Turning Discovery Off'
check 'The documented factory switch disables factory lookup' fails out_has 'App\Modules\Knowledge\Database\Factories\DocumentFactory' tinker --execute 'echo get_class(App\Modules\Knowledge\Models\Document::factory());'
check 'The documented policy switch leaves policy registration to Laravel' out_has 'not registered' tinker --execute 'echo array_key_exists(App\Modules\Knowledge\Models\Document::class, app(Illuminate\Contracts\Auth\Access\Gate::class)->policies()) ? "registered" : "not registered";'

check "Verbose inventory lists discovered classes" doc_shell "See what's discovered"
