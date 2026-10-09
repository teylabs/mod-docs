# Self-Contained Modules

With the `modules` layout, everything a feature needs can live in one folder that you copy to the next project. Its migrations, listeners, factories, policies and routes come with it.

## Building Two Modules

The `modules` layout keeps models, migrations, factories, actions, DTOs, view models, value objects, events, listeners and jobs inside each module. Build a `Knowledge` module that stores documents, and an `Agents` module that answers questions about them:

```bash
php artisan mod:model Knowledge:Document -mf --controller --resource --requests
php artisan mod:action Knowledge:IndexDocument
php artisan mod:dto Knowledge:DocumentData
php artisan mod:event Knowledge:DocumentUploaded
php artisan mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded
php artisan mod:view-model Knowledge:ShowDocument
php artisan mod:policy Knowledge:DocumentPolicy --model=Document
php artisan mod:provider Knowledge:Knowledge

php artisan mod:model Agents:Conversation -m
php artisan mod:action Agents:AnswerQuestion
php artisan mod:value-object Agents:TokenUsage
php artisan mod:job Agents:GenerateReply
```

```text
app/Modules/
├── Agents/
│   ├── Actions/
│   │   └── AnswerQuestion.php
│   ├── Database/
│   │   └── Migrations/
│   │       └── 2026_10_08_120001_create_conversations_table.php
│   ├── Jobs/
│   │   └── GenerateReply.php
│   ├── Models/
│   │   └── Conversation.php
│   └── ValueObjects/
│       └── TokenUsage.php
└── Knowledge/
    ├── Actions/
    │   └── IndexDocument.php
    ├── Data/
    │   └── DocumentData.php
    ├── Database/
    │   ├── Factories/
    │   │   └── DocumentFactory.php
    │   └── Migrations/
    │       └── 2026_10_08_120000_create_documents_table.php
    ├── Events/
    │   └── DocumentUploaded.php
    ├── Http/
    │   ├── Controllers/
    │   │   └── DocumentController.php
    │   └── Requests/
    │       ├── StoreDocumentRequest.php
    │       └── UpdateDocumentRequest.php
    ├── Listeners/
    │   └── GenerateEmbeddings.php
    ├── Models/
    │   └── Document.php
    ├── Policies/
    │   └── DocumentPolicy.php
    ├── Providers/
    │   └── KnowledgeServiceProvider.php
    └── ViewModels/
        └── ShowDocument.php
```

`--model=Document` names the model by its short name, as `make:policy` does. Inside a module, it is the module's own `Document` model. `Gate::getPolicyFor(Document::class)` finds the policy with no `Gate::policy()` call.

The DTO and the view model extend base classes that every module shares. The first `mod:dto` and `mod:view-model` write them, once, outside the modules:

```text
   INFO  Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].
   INFO  DTO [app/Modules/Knowledge/Data/DocumentData.php] created successfully.
```

[Generated Base Classes](/going-further/stubs#generated-base-classes) covers where they go and how to change them.

## Adding Routes

Mod doesn't discover route files. Load a module's routes from a provider in the module, which discovery registers:

```php memo="app/Modules/Knowledge/routes/web.php"
<?php

use App\Modules\Knowledge\Http\Controllers\DocumentController;
use Illuminate\Support\Facades\Route;

Route::middleware('web')->group(function () {
    Route::resource('documents', DocumentController::class);
});
```

```php memo="app/Modules/Knowledge/Providers/KnowledgeServiceProvider.php" at="boot()"
$this->loadRoutesFrom(__DIR__.'/../routes/web.php');
```

`loadRoutesFrom()` adds no middleware group, so the file applies `web` itself. `php artisan route:list` shows the module's routes, and `route:cache` includes them:

```bash
php artisan route:list --path=documents
# -> GET|HEAD documents › App\Modules\Knowledge\Http\Controllers\DocumentController@index
# -> POST     documents › App\Modules\Knowledge\Http\Controllers\DocumentController@store
# -> ...
# -> Showing [7] routes
```

## Copying a Module to Another Project

Each module is one folder, and its routes, migrations, listeners, factories and policies come with it. The other project needs mod [installed](/guide/installation) with `'layout' => 'modules'` in `config/mod.php`. Copy the folder into its `app/Modules`, then run `mod:bases` once to write the base classes its DTOs and view models extend:

```bash
php artisan mod:bases
```

```text
   INFO  Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].
   INFO  Created base class App\Support\ViewModels\ViewModel [app/Support/ViewModels/ViewModel.php].
```

In the other project, they work as they did in the first:

```bash
php artisan migrate --pretend
# -> includes 2026_10_08_120000_create_documents_table

php artisan event:list --event=DocumentUploaded
# -> App\Modules\Knowledge\Events\DocumentUploaded
# ->   ⇂ App\Modules\Knowledge\Listeners\GenerateEmbeddings@handle

php artisan route:list --path=documents
# -> Showing [7] routes
```

`Document::factory()` finds the module's factory and `Gate::getPolicyFor(Document::class)` its policy, as in the first project. The copied classes extend Laravel's own `App\Http\Controllers\Controller`, which every new app has. `mod:bases` never overwrites a base that exists, so running it again writes nothing.

## Carrying Views and Generators

These examples use the `modules` layout. The `ddd` preset declares no frontend paths, view namespaces or routes root; an extended layout must opt in to those folders.

A copied module carries its `resources/views`, route files, generator templates and scaffold recipes. The destination app needs the same layout and frontend wiring. Views register on boot; route files load through [module routes](/going-further/routes) or the module provider.

Put module-owned generator templates under `<module>/stubs/mod/`, using only `@module` anchors. For a command targeting that module, precedence is module, app, then package.

Invokable scaffold classes in `<module>/Scaffolds/` declare a public string `$name` and `__invoke(Scaffold $scaffold)`. A module provider can also register recipes in `boot()`:

```php memo="app/Modules/Inventory/Providers/InventoryServiceProvider.php"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffolds([
    'stock-count' => fn (Scaffold $s) => $s->makes('tool', name: 'Count{name}')->makes('job', name: 'Recount{name}'),
]);
```

The provider’s namespace must belong to the module for this registration to be module-owned. `mod:list --json` reports canonical sources such as `module:Inventory`, `app` and `package:vendor/name`; `mod:list -v` shows the template, recipe or provider origin.

### An Invokable Module Scaffold

Put the recipe class in the module’s `Scaffolds/` folder:

```php memo="app/Modules/Inventory/Scaffolds/StockReport.php"
<?php
namespace App\Modules\Inventory\Scaffolds;
use Tey\Mod\Scaffolds\Scaffold;
final class StockReport
{
    public string $name = 'stock-report';
    public function __invoke(Scaffold $s): void { $s->makes('tool', name: 'Report{name}'); }
}
```

The module’s `stubs/mod/@module/Tools/tool.stub` defines its `tool` file type. The class registers `mod:stock-report` on the next boot; copying the module carries this recipe and its template together.
