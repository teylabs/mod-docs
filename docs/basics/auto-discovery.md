# Auto-Discovery

Mod registers the providers, Artisan commands and event listeners your layout places, adds its migration folders to Laravel's migrator, and finds the factory and policy of each model. A class generated into a module works without a line of registration.

## Discovering Listeners

The `GenerateEmbeddings` listener from [Generating Files](/basics/generating-files), in the `Knowledge` module, is registered as soon as it exists:

```bash
php artisan event:list --event=DocumentUploaded
```

```text
  App\Modules\Knowledge\Events\DocumentUploaded ..
  ⇂ App\Modules\Knowledge\Listeners\GenerateEmbeddings@handle
```

A listener is registered for the events its `handle()` method accepts. It is never registered twice: whatever Laravel's own event discovery covers (`app/Listeners`, or the paths given to `withEvents()`), its event cache, or a manual `Event::listen()` already holds is left alone.

## What Is Discovered

| File type | Registered as |
| --- | --- |
| `provider` | a service provider |
| `command` | an Artisan command |
| `listener` | an event listener, for the events its `handle()` method accepts |
| `subscriber` | an event subscriber, through `Event::subscribe()` |
| `migration` | a migration folder, added to the migrator |

Discovery looks in each file type's own folder, such as `app/Modules/Knowledge/Listeners`, and runs after every provider has booted. Only classes that really are providers, commands, listeners or subscribers are registered; anything else in those folders is skipped.

Routes and views are not discovered. A module's [service provider](/going-further/self-contained-modules#adding-routes) loads its routes, and is discovered itself.

## Running Module Migrations

The folders a migration is written to, such as `app/Modules/Knowledge/Database/Migrations`, are added to Laravel's migrator. `migrate`, `migrate:rollback` and `migrate:status` include them:

```bash
php artisan migrate
```

```text
   INFO  Running migrations.

  2026_10_08_120000_create_documents_table .......... 1.91ms DONE
```

Laravel's own `database/migrations` is left to Laravel.

## Finding Factories and Policies

A model the layout places finds its factory and policy through the layout. Discovery needs no `newFactory()` method on the model and no `Gate::policy()` call:

```php
use App\Modules\Knowledge\Models\Document;
use Illuminate\Support\Facades\Gate;

Document::factory();                 // App\Modules\Knowledge\Database\Factories\DocumentFactory
Gate::getPolicyFor(Document::class); // App\Modules\Knowledge\Policies\DocumentPolicy
```

`mod:model` still writes a `newFactory()` method, so the model finds its factory even in an app without mod. A model written by hand, with only `use HasFactory;`, finds it through discovery.

A policy your app registers with `Gate::policy()` is kept. A factory resolver your app sets after mod (`Factory::guessFactoryNamesUsing()`) replaces mod's, as it would replace any earlier one. Factory and policy lookup are part of discovery, so `'discovery.enabled' => false` turns them off too.

## Discovering Event Subscribers

A subscriber in a `Listeners` folder is treated the way Laravel's own event discovery treats it: its typed `handle*()` methods are registered as listeners, and `subscribe()` isn't called.

Subscribers are discovered for a file type named `subscriber`. The built-in layouts don't have one, so add it to yours:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->kind('subscriber', in: 'Modules/{module}/Subscribers', suffix: 'Subscriber');
```

```bash
php artisan mod:subscriber Knowledge:Document
# -> app/Modules/Knowledge/Subscribers/DocumentSubscriber.php
```

A class in that folder with a public `subscribe()` method taking one parameter is registered through `Event::subscribe()`.

## Discovering Other File Types

`discovery.kinds` maps a file type id to what it is discovered as. The built-in layouts call their Artisan commands `command`, so those are discovered already. To discover a file type of your own, declare it, then map its id:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->kind('handler', in: 'Modules/{module}/Handlers');
```

```php memo="config/mod.php"
'discovery' => [
    'kinds' => ['handler' => 'listener'],
],
```

A handler generated with `mod:handler Knowledge:IndexUploadedDocument`, whose `handle()` method accepts `DocumentUploaded`, is then registered as a listener:

```bash
php artisan event:list --event=DocumentUploaded
```

```text
  App\Modules\Knowledge\Events\DocumentUploaded ..
  ⇂ App\Modules\Knowledge\Handlers\IndexUploadedDocument@handle
```

A key that isn't a file type of the active layout stops the app with an error listing the layout's file types. The value is `provider`, `command`, `listener`, `subscriber`, `directory` (for file types like migrations), or `false` to stop discovering one. For example, to manage migration folders yourself:

```php memo="config/mod.php"
'discovery' => [
    'kinds' => ['migration' => false],
],
```

### Discovering Anywhere in a Domain

To discover a file type in every PHP file below its group folder, not only its own folder, pass `discover: 'anywhere'`. `discoverExcept:` skips folders below the group folder, such as `src/Domain/Knowledge/Tests`:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('ddd')->kind('listener', in: '{domain+}/Listeners', discover: 'anywhere', discoverExcept: ['Tests']);
```

## Caching Discovery in Production

`php artisan optimize` caches discovery, and `php artisan optimize:clear` clears it. Both run mod's own commands:

```bash
php artisan mod:cache   # also run by php artisan optimize
php artisan mod:clear   # also run by php artisan optimize:clear
```

```text
   INFO  Discovery cached in [bootstrap/cache/mod-discovery.php]: 1 providers, 0 commands, 1 listeners, 0 subscribers, 2 directories, 6 rejected.

  Rejected files were found but not registered: 6 placed by no file type (helpers and plain classes; nothing to do). Run with -v to list them.
```

Rejected files are PHP files the scan found but didn't register. The second line groups them by reason:

| Reason | What to do |
| --- | --- |
| placed by no file type, such as `app/Models/User.php` in the `modules` layout, or a base class in `app/Support` | nothing |
| in a discovered folder but not a provider, command, listener or subscriber | check it: a listener's `handle()` may be missing its event type |
| placed by more than one file type | give one file type a `priority:` |
| placed by a file type that uses `place()` | nothing, unless it should be discovered |

`php artisan mod:cache -v` lists each file and its reason.

With a cache present, mod registers from the cache without scanning. Like Laravel's own caches, it doesn't pick up new classes: after adding a provider, command or listener while the cache exists, run `php artisan optimize:clear`.

When the layout or the discovery settings change after the cache was written, the cache is ignored: mod scans instead and logs a warning naming both commands. Set `'discovery.on_stale_cache' => 'fail'` to stop the app booting instead.

## Turning Discovery Off

To keep the rest of discovery and stop finding factories or policies through the layout, turn that part off:

```php memo="config/mod.php"
'discovery' => [
    'factories' => false,
    'policies' => false,
],
```

`'enabled' => false` turns all of discovery off: providers, commands, listeners, subscribers, migration folders, factories and policies.

[Configuration](/reference/configuration#discovery) lists every discovery key.
