PAGE=$DOCS/docs/going-further/scaffolds.md
crud_setup() {
    doc_file 'Named variants' stubs/mod.request.crud.stub 1
    doc_file 'Named variants' stubs/mod.controller.crud.stub 2
    doc_boot 'Generating a recipe'
}
fresh 'S1 CRUD recipe' modules
crud_setup
check 'CRUD command writes all eight files' doc_shell 'Generating a recipe'
check 'Controller variant renders sibling aliases' grep -F 'use App\Modules\Knowledge\Requests\StoreDocumentRequest;' "$APP/app/Modules/Knowledge/Controllers/DocumentController.php"
check 'Controller is valid PHP' has app/Modules/Knowledge/Controllers/DocumentController.php
check 'Model factory follows the recipe' has app/Modules/Knowledge/Database/Factories/DocumentFactory.php
check 'Recipe collision flags keep existing files' doc_shell 'Collisions'
doc_boot 'Including another recipe'
check 'Included recipe generates its added member' art mod:audited-crud Knowledge:Note
check 'Included job exists' has app/Modules/Knowledge/Jobs/RecordNote.php
fresh 'S7 DDD override' ddd
crud_setup
doc_boot 'Layout overrides'
art mod:autoload
check 'DDD override generates a cluster' art mod:crud Knowledge:Document
check 'Resources explicitly move to the application layer' has app/Modules/Knowledge/Resources/DocumentResource.php
check 'View models remain in the domain layer' has src/Domain/Knowledge/ViewModels/ShowDocumentViewModel.php
fresh 'invokable scaffold' modules
doc_file 'Recipe classes' app/Scaffolds/DocumentScaffold.php
doc_boot 'Recipe classes' 2
check 'Invokable scaffold runs' art mod:document Knowledge:Document
check 'Invokable recipe model exists' has app/Modules/Knowledge/Models/Document.php
fresh 'S14 parts and S19 routes' modules
art mod:model Inventory:Widget
art mod:bases
doc_file 'Templates for the tree' stubs/mod.view-model.tabs-layout.stub 1
doc_file 'Templates for the tree' stubs/mod.view-model.tab-page.stub 2
doc_file 'Templates for the tree' stubs/mod.controller.tabs.stub 3
doc_file 'Templates for the tree' stubs/mod.insert.tabs-entry.stub 4
doc_file 'Templates for the tree' stubs/mod.insert.tabs-action.stub 5
doc_file 'Registering routes' stubs/mod.insert.tab-route.stub 1
doc_file 'Registering routes' app/Modules/Inventory/routes/web.php 2
doc_boot 'Parts: scaffolds inside scaffolds'
check 'Tree creation writes all pages and inserts' doc_shell 'Parts: scaffolds inside scaffolds'
for tab in Overview Details Notes; do
    check "The $tab view model is valid" has "app/Modules/Inventory/ViewModels/Widget${tab}ViewModel.php"
done
check 'Tree classes load in a fresh PHP process' classes_load 'App\Modules\Inventory\ViewModels\ManageWidgetViewModel' 'App\Modules\Inventory\ViewModels\WidgetOverviewViewModel' 'App\Modules\Inventory\ViewModels\WidgetDetailsViewModel' 'App\Modules\Inventory\ViewModels\WidgetNotesViewModel' 'App\Modules\Inventory\Controllers\WidgetController'
check 'Three tabs produce three entries' sh -c "test \$(grep -c \"'label'\" '$APP/app/Modules/Inventory/ViewModels/ManageWidgetViewModel.php') -eq 3"
check 'Route parameters retain literal braces' grep -F 'widgets/{widget}/overview' "$APP/app/Modules/Inventory/routes/web.php"
check 'Growth uses the same deterministic cluster' doc_shell 'Growing a cluster later'
check 'Grown page is valid PHP' has app/Modules/Inventory/ViewModels/WidgetHistoryViewModel.php
check 'Growth preserves the parent anchor' grep -F 'mod:tabs' "$APP/app/Modules/Inventory/ViewModels/ManageWidgetViewModel.php"
check 'Growth inserts a route' grep -F -- "->name('widget.history')" "$APP/app/Modules/Inventory/routes/web.php"
# Load the routes with a discovered module provider, as the page instructs.
art mod:provider Inventory:Inventory
doc_file 'Registering routes' app/Modules/Inventory/Providers/InventoryServiceProvider.php 3
check 'Provider loads the registered routes' out_has widget.history route:list --name=widget.history
doc_boot 'Overriding one part'
check 'Inventory shows the overridden child' art mod:list --json
check 'Child override still grows the cluster' art mod:resource-tabs.tab Inventory:Widget Audit
check 'Override adds a job' has app/Modules/Inventory/Jobs/LogAudit.php
fresh 'S21 recursive tree' modules
doc_file 'Recursive scaffolds' stubs/mod.view-model.section.stub 1
doc_file 'Recursive scaffolds' stubs/mod.insert.section-child.stub 2
doc_boot 'Recursive scaffolds' 3
check 'Recursive commands retain the short class name' doc_shell 'Recursive scaffolds'
check 'Deep view model is valid PHP' has app/Modules/Docs/ViewModels/Guide/Install/RequirementsSectionViewModel.php
check 'Deep namespace matches the folders' grep -F 'namespace App\Modules\Docs\ViewModels\Guide\Install;' "$APP/app/Modules/Docs/ViewModels/Guide/Install/RequirementsSectionViewModel.php"

check 'Recursive leaf loads in a fresh PHP process' classes_load 'App\Modules\Docs\ViewModels\Guide\Install\RequirementsSectionViewModel'
