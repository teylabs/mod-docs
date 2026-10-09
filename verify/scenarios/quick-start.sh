# Checks docs/guide/quick-start.md.
PAGE=$DOCS/docs/guide/quick-start.md

# Landing + Quick Start + Related Files + Factories and Policies
fresh "quick start" modules
check "The generator succeeds: mod:model Knowledge:Document -mf" art mod:model Knowledge:Document -mf
check "The file exists and passes PHP syntax: model file" has 'app/Modules/Knowledge/Models/Document.php'
check "The file exists and passes PHP syntax: factory file" has 'app/Modules/Knowledge/Database/Factories/DocumentFactory.php'
check "The file exists and passes PHP syntax: migration file" has 'app/Modules/Knowledge/Database/Migrations/*_create_documents_table.php'
check "migrate runs the module migration" out_has "_create_documents_table" migrate
check "migrate:status lists it" out_has "_create_documents_table" migrate:status
check "Document::factory()->create()" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'App\Modules\Knowledge\Models\Document::factory()->create(); echo get_class(App\Modules\Knowledge\Models\Document::factory());' | grep -q 'App.Modules.Knowledge.Database.Factories.DocumentFactory'"
check "The generator succeeds: mod:policy Knowledge:DocumentPolicy --model=Document" art mod:policy Knowledge:DocumentPolicy --model=Document
check "Gate::getPolicyFor finds DocumentPolicy" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo get_class(Illuminate\Support\Facades\Gate::getPolicyFor(App\Modules\Knowledge\Models\Document::class));' | grep -q 'App.Modules.Knowledge.Policies.DocumentPolicy'"
check "migrate:rollback includes it" out_has "_create_documents_table" migrate:rollback
check "make:model untouched" art make:model Receipt
check "The file exists and passes PHP syntax: make:model writes app/Models" has 'app/Models/Receipt.php'


# Run the five steps straight from the page, including its displayed output.
fresh 'five documented steps' modules
check 'The documented model command succeeds' doc_shell 'Generating a Model'
check 'Model output matches the page' doc_output 'Generating a Model'
check 'The documented migration command succeeds' doc_shell 'Running the Migration'
check 'Migration output matches the page' doc_output 'Running the Migration'
check 'The documented event and listener commands succeed' doc_shell 'Adding an Event and a Listener'
check 'Event and listener output matches the page' doc_output 'Adding an Event and a Listener'
check 'The documented event list command succeeds' doc_shell 'Seeing the Listener Registered'
check 'Event registration output matches the page' doc_output 'Seeing the Listener Registered'
