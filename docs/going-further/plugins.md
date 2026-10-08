# Plugins

A package can build on mod instead of shipping its own generators. When you're done, your package adds file types and commands to a layout, ships the stubs they start from, and uses another package's base class when it is installed.

## Writing a Plugin

A mod plugin is an ordinary Laravel package whose service provider calls the `Mod` facade in `boot()`. Require `tey/mod` in the package:

```bash
composer require tey/mod
```

Mod reads the layout when Artisan starts, so the order of providers doesn't matter. The examples on this page come from a package of tools for apps with a `Knowledge` domain that stores documents.

### Adding File Types and Commands

Extend a built-in layout with `Mod::layout()`. A new file type gets a `mod:<type>` command; `command:` renames it, `aliases:` adds other names and `label:` sets the noun its output uses:

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('ddd')
    ->kind('builder', in: '{domain+}/Builders', suffix: 'Builder', aliases: ['mod:query-builder'], label: 'Query builder');
```

```bash
php artisan mod:builder Knowledge:Document
# ->  INFO  Query builder [src/Domain/Knowledge/Builders/DocumentBuilder.php] created successfully.

php artisan mod:query-builder Knowledge:Chunk
# -> src/Domain/Knowledge/Builders/ChunkBuilder.php
```

- Repeating an existing file type changes only the arguments you pass. Aliases add up: `->kind('dto', aliases: ['mod:payload'])` keeps `mod:data` and the DTO's other aliases.
- Without `label:`, the output names the type's id in title case (`Builder`). File types with a Laravel generator keep Laravel's wording.
- A command or alias that another file type already uses stops the layout from compiling, with an error naming both.

## Registering Stubs

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

### Using Another Package When It Is Installed

A stub can name variants. The first whose package is installed (`whenInstalled`) or whose class exists (`whenClass`) supplies the base class, the stub, or both:

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Generation\Stub;

Mod::stubs()->for('dto', Stub::file(__DIR__.'/../stubs/dto.stub')
    ->whenInstalled('spatie/laravel-data', base: 'Spatie\\LaravelData\\Data')
    ->whenClass('App\\Support\\Data', stub: __DIR__.'/../stubs/dto.app.stub'));
```

```bash
php artisan mod:dto Knowledge:DocumentData
# ->  INFO  Using spatie/laravel-data (installed).
```

`stubs/dto.stub` uses `{{ baseImport }}` and `{{ extends }}`, so one file serves every variant, as in [Using the Base in Your Stub](/going-further/stubs#using-the-base-in-your-stub).

An explicit base wins over every variant. The app sets one in `config/mod.php`; a plugin can read its own config key and give a default with `->base(config: 'knowledge.base_dto', class: 'App\\Support\\Data')`.

### Generating a Base Class

When no variant applies, a stub can write a base class into the app the first time it is used:

```php memo="src/KnowledgeToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Generation\GeneratedBase;
use Tey\Mod\Generation\Stub;

Mod::stubs()->for('dto', Stub::file(__DIR__.'/../stubs/dto.stub')
    ->whenInstalled('spatie/laravel-data', base: 'Spatie\\LaravelData\\Data')
    ->generatesBase(GeneratedBase::named('DataTransferObject', in: 'Shared/Data', stub: __DIR__.'/../stubs/bases/data-transfer-object.stub')));
```

```bash
php artisan mod:dto Knowledge:DocumentData
# ->  INFO  Created base class Domain\Shared\Data\DataTransferObject [src/Domain/Shared/Data/DataTransferObject.php].
# ->  INFO  DTO [src/Domain/Knowledge/Data/DocumentData.php] created successfully.
```

- `in:` is a folder below the file type's root, so the base above lands in `src/Domain/Shared/Data`.
- The base stub fills `{{ namespace }}` and `{{ class }}`. The app can replace it with `stubs/mod.base.data-transfer-object.stub` (the base's name in kebab-case).
- Once the file exists, the app owns it: mod never overwrites it, even with `--force`.
- Stubs must not use mod's own classes, so the generated code runs without mod installed.

## Swapping a Generator

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

## Example: A DDD Plugin

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
            ->kind('builder', in: '{domain+}/Builders', suffix: 'Builder');

        Mod::stubs()
            ->for('builder', Stub::file(__DIR__.'/../stubs/builder.stub'))
            ->for('dto', Stub::file(__DIR__.'/../stubs/dto.stub')
                ->base(config: 'ddd.base_dto')
                ->whenInstalled('spatie/laravel-data', base: 'Spatie\\LaravelData\\Data')
                ->generatesBase(GeneratedBase::named('DataTransferObject', in: 'Shared/Data', stub: __DIR__.'/../stubs/bases/data-transfer-object.stub')))
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

## Supplying Discovery Candidates

A package can supply the files discovery considers, for example to reuse an existing finder or skip generated folders. Turn the built-in registration off (`'discovery.enabled' => false`) and register discovery yourself once every provider has booted:

```php memo="src/KnowledgeToolsServiceProvider.php" at="register()"
use Tey\Mod\Discovery\DiscoveryDefinition;
use Tey\Mod\Discovery\DiscoveryOptions;
use Tey\Mod\Discovery\DiscoveryRegistrar;
use Tey\Mod\Placement\Root;
use Tey\Mod\Preset\Preset;

$this->app->booted(function ($app) {
    $options = DiscoveryOptions::fromConfig([...config('mod.discovery'), 'enabled' => true])
        ->withCandidates(fn (Root $root, string $basePath, DiscoveryDefinition $definition): iterable => [
            'app/Modules/Knowledge/Listeners/GenerateEmbeddings.php',
        ]);

    DiscoveryRegistrar::register($app, $app->make(Preset::class), $options);
});
```

The candidates are paths relative to the app. The definition says which file type (and discovery type) is being collected, so candidates can be scoped per type. Mod still decides which candidates are registered, in what order, and how.

## Turning Commands Off

A package or app with its own Artisan commands can keep mod's placement and discovery without the `mod:*` commands:

```php memo="config/mod.php"
'commands' => false,
```

Or turn them off for one layout with `Mod::layout('mine')->withoutCommands()`. Its file types keep their `command:` names for a host to dispatch by, and several file types may then share one. The discovery cache commands are registered only while the `mod:*` commands and discovery are both on.
