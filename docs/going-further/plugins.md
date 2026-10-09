# Plugins

A package can build on mod instead of shipping its own generators. When you're done, your package adds file types and commands to a layout, ships the stubs they start from, and uses another package's base class when it is installed.

## Writing a plugin

A mod plugin is an ordinary Laravel package whose service provider calls the `Mod` facade in `boot()`. Require `tey/mod` in the package:

```bash
composer require tey/mod
```

Mod reads the layout when Artisan starts, so the order of providers doesn't matter. The examples on this page come from a package of tools for apps with a `Knowledge` domain that stores documents.

### Adding file types and commands

Extend a built-in layout with `Mod::layout()`. A new file type gets a `mod:<type>` command; `command:` renames it, `aliases:` adds other names and `label:` sets the noun its output uses:

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('ddd')
    ->generates('builder', in: '{domain+}/Builders', suffix: 'Builder', aliases: ['mod:query-builder'], label: 'Query builder');
```

```bash
php artisan mod:builder Knowledge:Document
# ->  INFO  Query builder [src/Domain/Knowledge/Builders/DocumentBuilder.php] created successfully.

php artisan mod:query-builder Knowledge:Chunk
# -> src/Domain/Knowledge/Builders/ChunkBuilder.php
```

A hyphenated command or alias also gets a dash-free alias, so `mod:query-builder` works as `mod:querybuilder`. When that name is already a command or alias, the existing one keeps it.

- Repeating an existing file type changes only the arguments you pass. Aliases add up: `->generates('dto', aliases: ['mod:payload'])` keeps `mod:data` and the DTO's other aliases.
- Without `label:`, the output names the type's id in title case (`Builder`). File types with a Laravel generator keep Laravel's wording.
- A command or alias that another file type already uses stops the layout from compiling, with an error naming both.

## Registering stubs

Register the stub a file type starts from:

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Generation\Stub;

Mod::stubs()->for('builder', Stub::file(__DIR__.'/../stubs/builder.stub'));
```

```php memo="stubs/builder.stub"
<?php

namespace {{ namespace }};

use Illuminate\Database\Eloquent\Builder;

class {{ class }} extends Builder
{
    //
}
```

`Mod::stubs()->for()` works for any file type, including those with a Laravel generator. An app's own `stubs/mod.<type>.stub` still wins over a plugin's stub; [Layout API](/reference/layout-api#stub-resolution-order) gives the full order.

### Using another package when it is installed

A stub can name variants. The first whose package is installed (`whenInstalled`) or whose class exists (`whenClass`) supplies the base class, the stub, or both:

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Generation\Stub;

Mod::stubs()->for('dto', Stub::file(__DIR__.'/../stubs/dto.stub')
    ->whenInstalled('spatie/laravel-data', base: 'Spatie\\LaravelData\\Data')
    ->whenClass('App\\Support\\BaseData', stub: __DIR__.'/../stubs/dto.app.stub'));
```

```bash
php artisan mod:dto Knowledge:DocumentData
# ->  INFO  Using spatie/laravel-data (installed).
```

`stubs/dto.stub` uses `{{ baseImport }}` and `{{ extends }}`, so one file serves every variant, as in [Using the Base in Your Stub](/going-further/stubs#using-the-base-in-your-stub).

An explicit base wins over every variant. The app sets one in `config/mod.php`; a plugin can read its own config key and give a default with `->base(config: 'knowledge.base_dto', class: 'App\\Support\\BaseData')`.

### Generating a base class

When no variant applies, a stub can write a base class into the app the first time it is used. The base goes in the app's bases folder, `app/Support` by default:

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Generation\GeneratedBase;
use Tey\Mod\Generation\Stub;

Mod::stubs()->for('dto', Stub::file(__DIR__.'/../stubs/dto.stub')
    ->whenInstalled('spatie/laravel-data', base: 'Spatie\\LaravelData\\Data')
    ->generatesBase(GeneratedBase::named('DataTransferObject', in: 'Data', stub: __DIR__.'/../stubs/bases/data-transfer-object.stub')));
```

```bash
php artisan mod:dto Knowledge:DocumentData
# ->  INFO  Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].
# ->  INFO  DTO [app/Modules/Knowledge/Data/DocumentData.php] created successfully.
```

- `in:` is a folder below the bases folder, which the app sets with [`bases_path`](/reference/configuration#bases-path).
- To place the base below the file type's own root instead, add `->inFileTypeRoot()`. In the `ddd` layout, `GeneratedBase::named('DataTransferObject', in: 'Shared/Data', stub: ...)->inFileTypeRoot()` writes `src/Domain/Shared/Data/DataTransferObject.php`.
- The base stub fills `{{ namespace }}` and `{{ class }}`. The app can replace it with `stubs/mod.base.data-transfer-object.stub` (the base's name in kebab-case).
- Once the file exists, the app owns it: mod never overwrites it, even with `--force`. `mod:bases` writes it when it is missing.
- Stubs must not use mod's own classes, so the generated code runs without mod installed.

## Swapping a generator

Replace the command behind a file type with `Mod::generators()->use()`. Extend the command it replaces: `GenericClassCommand` for file types with no Laravel generator, or the matching command such as `ModelCommand`:

```php memo="src/Commands/BuilderCommand.php"
<?php

namespace Knowledge\Tools\Commands;

use Tey\Mod\Commands\GenericClassCommand;
use Tey\Mod\Generation\GenerationPlan;

class BuilderCommand extends GenericClassCommand
{
    protected function afterGeneration(GenerationPlan $plan, int $exitCode): void
    {
        $this->components->info('Add a newEloquentBuilder() method to the model to use it.');
    }
}
```

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Knowledge\Tools\Commands\BuilderCommand;
use Tey\Mod\Facades\Mod;

Mod::generators()->use('builder', BuilderCommand::class);
```

An app can do the same from `config/mod.php` with the [`generators`](/reference/configuration#generators) key. The hooks a command offers are listed in [Layout API](/reference/layout-api#generator-hooks).

## Example: a DDD plugin

The provider below is the shape of [laravel-ddd](https://github.com/teylabs/laravel-ddd) on mod. It keeps laravel-ddd's own config keys for base classes, adds a file type the built-in layout doesn't have, and ships its own stubs:

```php memo="src/DddServiceProvider.php"
<?php

namespace Vendor\Ddd;

use Illuminate\Support\ServiceProvider;
use Tey\Mod\Facades\Mod;
use Tey\Mod\Generation\GeneratedBase;
use Tey\Mod\Generation\Stub;

class DddServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Mod::layout('ddd')
            ->generates('builder', in: '{domain+}/Builders', suffix: 'Builder');

        Mod::stubs()
            ->for('builder', Stub::file(__DIR__.'/../stubs/builder.stub'))
            ->for('dto', Stub::file(__DIR__.'/../stubs/dto.stub')
                ->base(config: 'ddd.base_dto')
                ->whenInstalled('spatie/laravel-data', base: 'Spatie\\LaravelData\\Data')
                ->generatesBase(GeneratedBase::named('DataTransferObject', in: 'Shared/Data', stub: __DIR__.'/../stubs/bases/data-transfer-object.stub')->inFileTypeRoot()))
            ->for('view-model', Stub::file(__DIR__.'/../stubs/view-model.stub')
                ->base(config: 'ddd.base_view_model')
                ->whenInstalled('spatie/laravel-view-models', base: 'Spatie\\ViewModels\\ViewModel'));
    }
}
```

```bash
php artisan mod:builder Knowledge:Document
# -> src/Domain/Knowledge/Builders/DocumentBuilder.php

php artisan mod:view-model Knowledge:ShowDocument
# with ddd.base_view_model set to Domain\Shared\ViewModels\ViewModel:
# ->  INFO  Using the configured base Domain\Shared\ViewModels\ViewModel.
```

## Supplying discovery candidates

A package can supply the files discovery considers, for example to reuse an existing finder or skip generated folders. Pass a closure to `Mod::discoverUsing()`:

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Tey\Mod\Discovery\DiscoveryDefinition;
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\CompiledRoot;

Mod::discoverUsing(fn (CompiledRoot $root, string $basePath, DiscoveryDefinition $definition): iterable => [
    'app/Modules/Knowledge/Listeners/GenerateEmbeddings.php',
]);
```

The closure receives a root of the layout and the definition of what is being collected, and returns paths relative to the app. The definition names the file type (`$definition->kindId`) and its discovery type, so candidates can be scoped per type. Mod still decides which candidates are registered, in what order, and how. Factory and policy lookup work as before, following `discovery.factories` and `discovery.policies`.

## Turning commands off

A package or app with its own Artisan commands can keep mod's placement and discovery without the `mod:*` commands:

```php memo="config/mod.php"
'commands' => false,
```

Or turn them off for one layout with `Mod::layout('mine')->withoutCommands()`. Its file types keep their `command:` names for a host to dispatch by, and several file types may then share one. The discovery cache commands are registered only while the `mod:*` commands and discovery are both on.

## Shipping generator templates

Register a folder from the package's provider, and use `@group` inside it:

```php memo="src/ToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::stubs()->folder(dirname(__DIR__).'/stubs');
```

For example, `stubs/@group/Tools/tool.stub` gives the app a `mod:tool` command whose folder follows its layout. [Custom generators](/going-further/custom-generators#editing-the-template) shows the contents. The app's template takes precedence. Two packages claiming the same command disable only that command with a warning naming both; the other commands keep working.

## Shipping scaffolds

A package provider registers recipes with the same API as an app. If mod is optional, list `tey/mod` in Composer's `suggest` and guard registration:

```php memo="src/ToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Generation\Stub;
use Tey\Mod\Scaffolds\Scaffold;

if (class_exists(Mod::class)) {
    Mod::stubs()->for('controller.crud', Stub::file(__DIR__.'/../stubs/controller.crud.stub'));
    Mod::scaffold('document', fn (Scaffold $s) => $s
        ->makes('model')
        ->makes('controller', name: '{name}Controller', stub: 'crud'));
}
```

The app can `include('document')` or replace the recipe. App registration wins; two packages using one name disable that scaffold with a warning naming both. Placement follows the app's layout. `mod:list` reports the effective source, including part overrides. [Scaffolds](/going-further/scaffolds#writing-a-reusable-recipe) covers recipe dependencies and manual work.
