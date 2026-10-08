# Configuration

Every key in `config/mod.php`. Publish the file with:

```bash
php artisan vendor:publish --tag=mod-config
# -> config/mod.php
```

| Key | Default | Description |
| --- | --- | --- |
| [`layout`](#layout) | `'laravel'` | The active layout |
| [`commands`](#commands) | `true` | Register the `mod:*` commands |
| [`generators`](#generators) | `[]` | Replace the command behind a file type |
| [`layouts.ddd.bases`](#layouts) | `null` for each | The class DTOs, view models and actions extend |
| [`discovery.enabled`](#discovery) | `true` | Turn discovery on or off |
| [`discovery.kinds`](#discovery-kinds) | `[]` | Discover more file types, or stop discovering one |
| [`discovery.cache`](#discovery-cache) | `'bootstrap/cache/mod-discovery.php'` | Where the discovery cache is written |
| [`discovery.on_stale_cache`](#discovery-on-stale-cache) | `'scan'` | What happens when the cache is out of date |
| [`discovery.factories`](#discovery-factories-and-discovery-policies) | `true` | Find factories for models the layout places |
| [`discovery.policies`](#discovery-factories-and-discovery-policies) | `true` | Find policies for models the layout places |

## layout

The active layout: a built-in name (`laravel`, `modules`, `features`, `slices`, `type-first`, `ddd`) or one you define with `Mod::layout()`.

```php memo="config/mod.php"
'layout' => 'modules',
```

[Layouts](/basics/layouts) compares the built-in layouts.

## commands

`false` registers no `mod:*` commands, for a host with its own Artisan commands. Placement and discovery keep working. The discovery cache commands are registered only while this and `discovery.enabled` are both on.

## generators

The command class behind a file type, keyed by file type id. It replaces the built-in command, as `Mod::generators()->use()` does:

```php memo="config/mod.php"
'generators' => [
    'builder' => App\Console\Commands\BuilderCommand::class,
],
```

[Swapping Generators](/reference/layout-api#swapping-generators) says which class to extend.

## layouts

Settings per layout. `bases` names the class a file type's generated classes extend, by file type id:

```php memo="config/mod.php"
'layouts' => [
    'ddd' => [
        'bases' => [
            'dto' => App\Support\Data::class,
            'view-model' => null,
            'action' => null,
        ],
    ],
],
```

`null` lets mod decide: a supported package when it is installed, else a base class mod writes into your app on first use. A configured base wins over an installed package. [Stubs](/going-further/stubs#starter-stubs-in-the-ddd-layout) lists each file type's options.

## discovery

`enabled` set to `false` turns all of discovery off: providers, commands, listeners, subscribers, migration folders, factories and policies.

### discovery.kinds

Maps a file type id to the type it is discovered as: `provider`, `command`, `listener`, `subscriber`, `directory`, or `false` to stop discovering it. Merged over the defaults:

```php memo="config/mod.php"
'discovery' => [
    'kinds' => [
        'console' => 'command',
        'migration' => false,
    ],
],
```

By default, the `provider`, `command`, `listener` and `subscriber` file types are discovered as themselves, and timestamped file types such as `migration` as directories. A key must be a file type of the active layout. Class file types map to a class type, and file types such as migrations only to `directory`.

### discovery.cache

The cache file `mod:discovery-cache` writes, relative to the app.

### discovery.on_stale_cache

| Value | When the layout or discovery settings changed after the cache was written |
| --- | --- |
| `'scan'` | Ignores the cache, scans instead without rewriting it, and logs a warning |
| `'fail'` | Stops the app booting until the cache is rebuilt with `mod:discovery-cache` or removed |

### discovery.factories and discovery.policies

`true` lets `Model::factory()` and `Gate::getPolicyFor()` find a model's factory and policy through the layout's relations, with no `newFactory()` method or `Gate::policy()` call. `false` turns each off.
