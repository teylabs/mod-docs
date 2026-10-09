# Scaffolds

A scaffold is a recipe of several file types generated together. Each member follows the active layout, so the same recipe can work in modules or across DDD layers.

## Generating a recipe

Register this CRUD recipe in a service provider. Create the named variants in the next section before running it:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffold('crud', fn (Scaffold $s) => $s
    ->makes('model', options: ['--migration', '--factory'])
    ->makes('request', name: 'Store{name}Request', as: 'storeRequest', stub: 'crud')
    ->makes('request', name: 'Update{name}Request', as: 'updateRequest', stub: 'crud')
    ->makes('resource', name: '{name}Resource')
    ->makes('policy', name: '{name}Policy')
    ->makes('controller', name: '{name}Controller', stub: 'crud'));
```

```bash
php artisan mod:crud Knowledge:Document --no-interaction
# -> app/Modules/Knowledge/Models/Document.php
# -> app/Modules/Knowledge/Database/Factories/DocumentFactory.php
# -> app/Modules/Knowledge/Requests/StoreDocumentRequest.php
# -> app/Modules/Knowledge/Requests/UpdateDocumentRequest.php
# -> app/Modules/Knowledge/Resources/DocumentResource.php
# -> app/Modules/Knowledge/Policies/DocumentPolicy.php
# -> app/Modules/Knowledge/Controllers/DocumentController.php
```

The plan includes all eight files, including the migration and factory requested by the model. Generated bases appear in the plan too. In a terminal, one confirmation accepts the whole plan; cancelling writes nothing. Companion output follows Laravel's native order, so a model's factory is printed before its migration.

## Named variants

`stub: 'crud'` selects `stubs/mod.<type>.crud.stub`. These request and controller variants refer to the recipe's sibling classes:

```php memo="stubs/mod.request.crud.stub"
<?php

namespace {{ namespace }};

use {{ model.fqcn }};
use Illuminate\Foundation\Http\FormRequest;

class {{ class }} extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', {{ model }}::class);
    }

    public function rules(): array
    {
        return [
            //
        ];
    }
}
```

```php memo="stubs/mod.controller.crud.stub"
<?php

namespace {{ namespace }};

use App\Http\Controllers\Controller;
use {{ model.fqcn }};
use {{ resource.fqcn }};
use {{ storeRequest.fqcn }};
use {{ updateRequest.fqcn }};

class {{ class }} extends Controller
{
    public function index()
    {
        return {{ resource }}::collection({{ model }}::paginate());
    }

    public function store({{ storeRequest }} $request)
    {
        return new {{ resource }}({{ model }}::create($request->validated()));
    }

    public function show({{ model }} ${{ model.camel }})
    {
        return new {{ resource }}(${{ model.camel }});
    }

    public function update({{ updateRequest }} $request, {{ model }} ${{ model.camel }})
    {
        ${{ model.camel }}->update($request->validated());

        return new {{ resource }}(${{ model.camel }});
    }
}
```

A missing variant offers to create it in a terminal, with publication held until the plan is accepted. Without interaction, create the named file first, for example from the file type's published stub.

## Aliases and name forms

`as:` names a member; without it, the file type id is its alias. `{{ model }}` is the short class name and `{{ model.fqcn }}` is the full name. Every member's stub can use sibling aliases, including aliases for companion files. A [generator template](/going-further/custom-generators) can be a member, with slot values forwarded through its `options:`.

The `name:` pattern uses `{name}` and question tokens. Stub name forms chain left to right: `{{ name.plural.kebab }}` pluralizes, then converts to kebab case. Literal braces surround a placeholder without an escape: `{{{ model.camel }}}` gives `{widget}`. `{{ tabs.array }}` renders a PHP array literal. Stubs do not gain loops or conditionals.

## Including another recipe

Reuse a recipe, then add members or replace an included member by its alias:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffold('audited-crud', fn (Scaffold $s) => $s
    ->include('crud')
    ->makes('job', name: 'Record{name}', as: 'audit'));
```

`include()` copies questions, members, parts and repetitions. A later `part()` replaces an inherited part of the same name. Include cycles disable the recipe with a diagnostic naming the chain. A duplicate alias declared twice in one recipe is an error; replacement applies to included members.

## Layout overrides

A layout can override a global recipe and include its original definition:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Scaffold;

Mod::layout('ddd')->generates('resource', in: 'application:{domain}/Resources')
    ->scaffolds('crud', fn (Scaffold $s) => $s
        ->include('crud')
        ->makes('dto', name: '{name}Data')
        ->makes('view-model', name: 'Show{name}ViewModel'));
```

This explicitly moves resources into the application layer. Without that override, DDD resources remain in the domain layer, alongside DTOs and view models.

## Recipe classes

An invokable class declares a string `$name` and receives the same builder:

```php memo="app/Scaffolds/DocumentScaffold.php"
<?php

namespace App\Scaffolds;

use Tey\Mod\Scaffolds\Scaffold;

class DocumentScaffold
{
    public string $name = 'document';

    public function __invoke(Scaffold $s): void
    {
        $s->makes('model')->makes('controller', name: '{name}Controller');
    }
}
```

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use App\Scaffolds\DocumentScaffold;
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffolds([DocumentScaffold::class]);
```

[Plugins](/going-further/plugins#shipping-scaffolds) shows package registration. App recipes win over package recipes; two packages with the same name disable that scaffold with a warning naming both. `mod:list` shows the effective source.

## Collisions

Mod checks all files and inserts before writing. Choose whether to keep or overwrite existing members:

```bash
php artisan mod:crud Knowledge:Document --skip-existing --no-interaction
php artisan mod:crud Knowledge:Document --force --no-interaction
```

`--skip-existing` keeps existing files and writes the rest. `--force` overwrites members, but generated bases are never overwritten. A generation-time failure rolls the subtree back.

## Asking questions

`asks()` adds a question and its command option. The types are `text`, `list`, `choice`, `confirm`, `model` and `class`. A default can use `{name}`. A model or class answer supplies its short name and `.fqcn`.

A list prompt accepts comma-separated text; scripts can use `--tabs=Overview,Details` or repeated `--tabs=Overview --tabs=Details`. Confirms take `--flag` or `--no-flag`. Without a terminal, mod uses a declared default or exits naming the option that supplies the missing answer.

## Parts: scaffolds inside scaffolds

A tab page can run independently, or become a repeated child of a resource. Create the templates below and the routes file in [Registering routes](#registering-routes), then register:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Part;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffold('tab-page', fn (Scaffold $s) => $s
    ->asks('base', type: 'class', label: 'Which base view model does the page extend?')
    ->asks('tab', type: 'text', label: 'Which tab is this?')
    ->makes('view-model', name: '{name}{tab}ViewModel', as: 'page', stub: 'tab-page'));

Mod::scaffold('resource-tabs', fn (Scaffold $s) => $s
    ->asks('model', type: 'model', default: '{name}', label: 'Which model do the tabs manage?')
    ->asks('tabs', type: 'list', default: ['Overview', 'Details', 'Notes'], label: 'Which tabs?')
    ->makes('view-model', name: 'Manage{name}ViewModel', as: 'base', stub: 'tabs-layout')
    ->makes('controller', name: '{name}Controller', stub: 'tabs')
    ->part('tab', uses: 'tab-page', with: ['base' => '{{ base.fqcn }}'],
        configure: fn (Part $p) => $p
            ->inserts(into: 'base', at: 'tabs', stub: 'tabs-entry')
            ->inserts(into: 'controller', at: 'actions', stub: 'tabs-action')
            ->inserts(into: '@module/routes/web.php', at: 'routes', stub: 'tab-route'))
    ->each('tabs', part: 'tab'));
```

With an existing `Inventory:Widget` model:

```bash
php artisan mod:resource-tabs Inventory:Widget --tabs=Overview,Details,Notes --no-interaction
# -> app/Modules/Inventory/ViewModels/ManageWidgetViewModel.php
# -> app/Modules/Inventory/ViewModels/WidgetOverviewViewModel.php
# -> app/Modules/Inventory/ViewModels/WidgetDetailsViewModel.php
# -> app/Modules/Inventory/ViewModels/WidgetNotesViewModel.php
# -> app/Modules/Inventory/Controllers/WidgetController.php
```

Values go down through `with:` and questions. Results come up through aliases: `tab.page` inside a part's inserts, or `tab.History.page` outside. Each node's inserts can edit its own member aliases; a descendant cannot edit a grandparent's aliases. Inline parts can declare their own members, including templates with slot options. Use `configure:` for a closure after named arguments, or a positional closure for an inline part.

### Templates for the tree

The layout view model owns navigation entries. Each page owns its title. Three generated page view models therefore produce three navigation entries in this recipe; a recipe that omits a navigation insert can have a different count. The controller template calls `inertia()`, so this recipe requires an Inertia app. Create the matching `Widget/Overview`, `Widget/Details`, `Widget/Notes` and later frontend pages yourself; mod does not generate them.

```php memo="stubs/mod.view-model.tabs-layout.stub"
<?php

namespace {{ namespace }};

use {{ model.fqcn }};
{{ baseImport }}
abstract class {{ class }}{{ extends }}
{
    public function __construct(protected {{ model }} ${{ model.camel }}) {}

    public function layout(): array
    {
        return [
            'tabs' => [
                // mod:tabs
            ],
        ];
    }

    abstract public function title(): string;
}
```

```php memo="stubs/mod.view-model.tab-page.stub"
<?php

namespace {{ namespace }};

use {{ base.fqcn }};

class {{ class }} extends {{ base }}
{
    public function title(): string
    {
        return '{{ tab }}';
    }
}
```

```php memo="stubs/mod.controller.tabs.stub"
<?php

namespace {{ namespace }};

use App\Http\Controllers\Controller;
use {{ model.fqcn }};

class {{ class }} extends Controller
{
    // mod:actions
}
```

```php memo="stubs/mod.insert.tabs-entry.stub"
                ['label' => '{{ tab }}', 'route' => '{{ name.kebab }}.{{ tab.kebab }}'],
```

```php memo="stubs/mod.insert.tabs-action.stub"
    public function {{ tab.camel }}({{ model }} ${{ model.camel }})
    {
        return inertia('{{ name }}/{{ tab }}', new \{{ tab.page.fqcn }}(${{ model.camel }}));
    }
```

## Growing a cluster later

Add a child using the same planner as `each()`:

```bash
php artisan mod:resource-tabs.tab Inventory:Widget History --no-interaction
# -> app/Modules/Inventory/ViewModels/WidgetHistoryViewModel.php
```

Mod finds the cluster from deterministic names, without a state file. Creating three tabs at once is byte-identical to creating two and growing the third. A terminal shows every file and every insert before one confirmation. Missing anchors, duplicate outputs and repeated inline inserts refuse before writing.

If the cluster is missing, a terminal offers to create the root first; a non-interactive run names the root command to run. A leaf such as `mod:tab-page` also runs on its own when its `--base` and `--tab` answers are supplied.

## Registering routes

An insert stub is `stubs/mod.insert.<name>.stub`. The tree above uses this route insert:

```php memo="stubs/mod.insert.tab-route.stub"
    Route::get('{{ name.plural.kebab }}/{{{ model.camel }}}/{{ tab.kebab }}', [\{{ controller.fqcn }}::class, '{{ tab.camel }}'])->name('{{ name.kebab }}.{{ tab.kebab }}');
```

Start with an anchored routes file:

```php memo="app/Modules/Inventory/routes/web.php"
<?php

use Illuminate\Support\Facades\Route;

Route::middleware('web')->group(function () {
    // mod:routes
});
```

Load it from a module provider, which discovery registers:

```php memo="app/Modules/Inventory/Providers/InventoryServiceProvider.php"
<?php

namespace App\Modules\Inventory\Providers;

use Illuminate\Support\ServiceProvider;

class InventoryServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        $this->loadRoutesFrom(__DIR__.'/../routes/web.php');
    }
}
```

Mod does not discover route files automatically. A routes file is the only file mod offers to start or add a missing anchor to; those changes wait for the final confirmation. Without interaction, prepare the file and anchor first.

Inserts go immediately before the retained `mod:<anchor>` marker. Markers match literally in `//`, `#`, Blade and HTML comments. Keep anchors in every base variant. Inserts use full class names; they do not edit imports or parse PHP. Existing CRLF files retain their line endings, anchor indentation and trailing whitespace. Stub indentation and blank lines are preserved.

## Overriding one part

Replace one node for creation and growth:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Part;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffold('resource-tabs.tab', fn (Part $p) => $p
    ->uses('tab-page', with: ['base' => '{{ base.fqcn }}'])
    ->makes('job', name: 'Log{tab}', as: 'audit')
    ->inserts(into: 'base', at: 'tabs', stub: 'tabs-entry'));
```

The parent recipe must exist. Dotted names name overrides, not new root recipes. `mod:list` shows the finite tree with Uses and From columns; JSON exposes children, references and effective provenance.

## Recursive scaffolds

A reference stays finite in the registry and expands only when invoked. This section recipe can grow under itself:

```php memo="stubs/mod.view-model.section.stub"
<?php
namespace {{ namespace }};
class {{ class }} { public function children(): array { return [
// mod:children
]; } }
```

```php memo="stubs/mod.insert.section-child.stub"
'{{ section.page.fqcn }}',
```

```php memo="app/Providers/AppServiceProvider.php"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Part;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffold('section', fn (Scaffold $s) => $s
    ->makes('view-model', name: '{name}SectionViewModel', as: 'page', stub: 'section')
    ->part('section', uses: 'section', configure: fn (Part $p) => $p
        ->inserts(into: 'page', at: 'children', stub: 'section-child')));
```

```bash
php artisan mod:section Docs:Guide --no-interaction
php artisan mod:section.section Docs:Guide Install --no-interaction
php artisan mod:section.section Docs:Guide Install/Requirements --no-interaction
# -> app/Modules/Docs/ViewModels/Guide/Install/RequirementsSectionViewModel.php
```

The deep class is named `RequirementsSectionViewModel`, with a namespace matching its folders. The recursion limit is 10. Deeper dot paths accept slash-separated ancestor inputs, such as `mod:nested.group.item Inventory:Widget First/History`.

## Writing a reusable recipe

Record required packages, import aliases, model base settings and variant files alongside the recipe. If a house variant calls a query-builder package, record it as a dependency of the recipe. Keep authorization and validation specific to the application.

Members support PHP classes and migrations. Choose the view model shape your app already uses: a layout with tabs, a request-based section index, or a public `tabs()` method with links. Keep page count and navigation count explicit when adapting it.
