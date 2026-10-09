# Module Routes

Load module route files with `Mod::routes()`. They use Laravel’s route groups and middleware, with no module-derived URI or name prefix.

## Loading Route Files

Add the facade import to `bootstrap/app.php`, then supply a `then` callback in its existing routing configuration:

```php memo="bootstrap/app.php"
use Tey\Mod\Facades\Mod;

->withRouting(
    web: __DIR__.'/../routes/web.php',
    commands: __DIR__.'/../routes/console.php',
    then: fn () => Mod::routes(),
)
```

```bash
php artisan mod:routes Inventory --api --console
# -> app/Modules/Inventory/routes/web.php
# -> app/Modules/Inventory/routes/api.php
# -> app/Modules/Inventory/routes/console.php
```

Web files use `web` middleware. API files use `api` middleware and the `/api` prefix. Console files load only in the console. Add routes at the generated `// mod:routes` anchor.

## Using Laravel Route Groups

A loading call inherits the surrounding middleware, URI prefix and name prefix:

```php memo="routes/web.php"
use Illuminate\Support\Facades\Route;
use Tey\Mod\Facades\Mod;

Route::middleware(['auth', 'can:admin'])->prefix('admin')->name('admin.')->group(function () {
    Mod::routes(only: ['Inventory', 'Knowledge']);
});

Mod::routes(except: ['Inventory', 'Knowledge']);
```

Use `only` and `except` to select modules. Loading the same module twice exits with an error naming both call locations. Put the call before an app fallback route.

## Setting the Order

Set the leading modules in `config/mod.php`:

```php memo="config/mod.php"
'routes' => [
    'order' => ['Billing', 'Knowledge'],
],
```

Listed modules load first; the rest load alphabetically. Unknown configured names produce a warning. Order matters when routes overlap.

## Using Route Registrars

```bash
php artisan mod:route-registrar Inventory
# -> app/Modules/Inventory/Http/Routing/InventoryRoutes.php
```

```php memo="app/Modules/Inventory/Http/Routing/InventoryRoutes.php"
<?php

namespace App\Modules\Inventory\Http\Routing;

use Illuminate\Support\Facades\Route;
use Tey\Mod\Routing\RegistersRoutes;

class InventoryRoutes implements RegistersRoutes
{
    public static function web(): void
    {
        // mod:routes
    }

    public static function api(): void
    {
        // mod:api-routes
    }
}
```

Classes in the HTTP Routing folder implement `RegistersRoutes` with static `web(): void` and `api(): void`. Route files load before the corresponding methods. The class name is not used for registration. Keep bindings and rate limiters in providers.

## Routes Loaded by Providers

A module provider can still load its own routes. Put this call in its `boot()` method:

```php memo="app/Modules/Knowledge/Providers/KnowledgeServiceProvider.php"
$this->loadRoutesFrom(__DIR__.'/../routes/web.php');
```

`Mod::routes()` skips files already included by providers in the current application. In test suites that recreate an application at the same physical path within one PHP process, a provider-loaded route file can run again because PHP records each included filename only once.

## Caching Routes

```bash
php artisan route:cache
php artisan route:list --json
```

When routes are cached, `Mod::routes()` returns before inspecting modules or loading files. Inventory listing inspects registrar implementations without calling their methods.

## Routes in Scaffolds

Use route aliases in anchored inserts: `routes` targets the web file; `routes.web` and `routes.api` prefer registrar methods when present. Missing files are included in the plan with their anchors. [Scaffolds](/going-further/scaffolds#registering-routes) shows an insert recipe.

## Inspecting Route Plans

```bash
php artisan mod:routes Inventory --api --dry-run --json
php artisan mod:route-registrar Inventory --dry-run --json
php artisan mod:list --json
```

Both generators check all collisions before writing. Pass `--force` to replace existing output. Inventory route entries contain `group`, `entrypoint`, `kind`, `middleware_group`, `order`, and `loaded_by`. The last field records the loading call or provider.
