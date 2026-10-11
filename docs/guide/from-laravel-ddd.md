# Moving from Laravel-DDD to Mod

You can replace `tey/laravel-ddd` while keeping its default folders, or use the change to bring each feature into one module. Choose the destination first, then separate the package change, PHP moves, shared UI and frontend moves into reviewable steps. Keep routes and behaviour stable while moving files.

Mod requires PHP 8.3+ and Laravel 12 or 13. Check those requirements and your application's dependencies before replacing the package. The Inertia page checks, `Mod::pageEntry()` and custom-bootstrap instructions linked below need mod 0.5.0 or later.

## Record the Existing App

Start from a clean branch with passing tests. Read `config/ddd.php`, Composer's PSR-4 roots, custom stubs, service providers and the commands used by scripts or agents. Record which namespaces and folders each layer owns, which objects go into the application layer, and how providers, listeners, migrations, factories and policies are registered.

Before moving models, record their old/new class names, tables, connections and effective morph identities while the old classes still load. Follow [Moving an existing app](/going-further/moving-layouts) for old polymorphic rows, serialized jobs and rollback. A namespace-only move can break old rows even when no table changes. Arrange the queue cutover before deployment; restarting workers alone does not update queued payloads.

Capture the existing route list, generated frontend types, test results and a production-style boot. These are your comparison points after each step.

## Choose the Like-for-like DDD Layout

Use `ddd` when the goal is to replace the tooling and keep Laravel-DDD's default structure:

| Root | Namespace | Files |
| --- | --- | --- |
| `src/Domain` | `Domain\` | Domain classes, factories and migrations |
| `app/Modules` | `App\Modules\` | Controllers, requests and middleware |
| `tests` | `Tests\` | Domain tests under `Feature/<Domain>` |

Replace the dependency in `composer.json`: remove `tey/laravel-ddd` from the section that contains it, add `tey/mod` to runtime `require`, then resolve and review the lockfile with Composer. Keep Mod available in production if you use its discovery or frontend helpers. Do not run both packages' discovery over the same classes during the cutover.

Publish Mod's configuration and choose `ddd`:

```bash
php artisan vendor:publish --tag=mod-config
```

```php memo="config/mod.php"
'layout' => 'ddd',
```

Keep the `Domain\` Composer mapping. Preview any missing mappings before applying them:

```bash
php artisan mod:autoload --dry-run
php artisan mod:autoload
```

This updates Composer mappings; it does not move files. The default preset keeps the old namespaces, so those classes do not need a namespace rewrite. Check generated paths before using commands in your app:

```bash
php artisan mod:model Inventory:Document --factory --dry-run --json
```

This plans `src/Domain/Inventory/Models/Document.php` and `src/Domain/Inventory/Database/Factories/DocumentFactory.php`. It preserves the domain/application split; it does not put controllers in `Http/Controllers`.

The preset has no frontend paths, view namespaces or routes root. Existing app routes and pages stay where they are. Markdown mail/notification views use Laravel's `resources/views`. To add module pages or routes, [extend DDD explicitly](/basics/layouts#opting-in-to-frontend-and-routes).

The like-for-like option covers the default layout. Custom `domain_path`, application objects, extra layers, base classes and stubs still need translating; selecting `ddd` does not read `config/ddd.php`.

## Choose a Custom Layout Instead

An app that wants a feature's domain and HTTP classes together can extend `modules`. This example also gives a shared UI kit its own root. Register the declaration in a dedicated provider's `boot()` method:

```php memo="app/Providers/ModLayoutServiceProvider.php"
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\Root;

class ModLayoutServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Mod::layout('application')
            ->extends('modules')
            ->path('app/Modules/{module}')
            ->mounts('ui', 'App\\UI\\', 'app/UI', fn (Root $root) => $root
                ->generates('ui-provider', in: 'Providers', suffix: 'ServiceProvider')
                ->generates('ui-data', in: 'Data')
                ->generates('ui-view-model', in: 'ViewModels'));
    }
}
```

Put `App\Providers\ModLayoutServiceProvider::class` first in `bootstrap/providers.php`, before application providers that use the layout. The explicit `path()` retains the `module` option despite the custom layout name. From 0.4.1, the explicit UI mount reclaims the inherited `App\UI\` exclusion. Choose the layout and opt in to discovery for the custom provider type:

```php memo="config/mod.php"
'layout' => 'application',
'discovery' => [
    'file_types' => [
        'ui-provider' => 'provider',
        // Keep explicit listener wiring during the move.
        'listener' => false,
    ],
],
```

The `ui-*` declarations place custom classes; they do not automatically inherit Laravel’s provider or your UI data/view-model bases. Move the existing kit classes with their working inheritance, and supply [custom stubs](/going-further/stubs) before generating new ones.

Preserving explicit listeners is one migration choice. If you choose automatic discovery instead, review and remove duplicate registration deliberately. Check subscribers too.

Mod registers discovered providers after the providers in `bootstrap/providers.php` have booted. If their order matters, for example when a Filament panel provider must come first, keep them listed there and turn provider discovery off:

```php memo="config/mod.php"
'discovery' => [
    'file_types' => [
        'provider' => false,
        'listener' => false,
    ],
],
```

New module providers then need adding to `bootstrap/providers.php` by hand. Commands and migrations are still discovered.

### When Domain and Application Share a Folder

Some apps set Laravel-DDD's `domain_path` and `application_path` to the same folder, such as `app/Modules`. Don't remount `ddd`'s domain root there: two roots can't share a namespace or a path, and the layout fails to compile. Extend `modules` instead, and point its placements at the folders the app already uses:

```php
Mod::layout('website')
    ->extends('modules')
    ->path('app/Modules/{module}')
    ->generates('controller', in: '@module/Controllers')
    ->generates('request', in: '@module/Requests')
    ->generates('command', in: '@module/Commands');
```

Nothing moves, and new files land beside the existing ones.

In this layout, move `src/Domain/Inventory` to `app/Modules/Inventory`, and change `Domain\Inventory\` references to `App\Modules\Inventory\`. Controllers, requests and middleware belonging to Inventory go into its `Http` folders. App-wide middleware, the base controller and shared account entrypoints can stay in Laravel's app folders. Module providers use the native `*ServiceProvider` suffix; rename existing providers and update references where needed.

Use `git mv` for reviewed file moves, then update imports, routes, configuration, tests, fixture paths and generator stubs. Keep route files in `routes/` if that is already working; module route files are optional. Do not change URLs or route names just to change PHP ownership.

For a shared kit, move PHP to `app/UI` and change its namespace to `App\UI\`. Frontend components can live at `app/UI/resources/js`: update Vite and TypeScript aliases, include paths, Tailwind sources and formatter/test roots. A kit should own its utilities and avoid importing host-specific classes or components. Move host-dependent presentation code into its owning module or app support folder, and verify that boundary.

An extra Infrastructure layer does not have to survive as a folder. An app can move its adapters into the owning modules and app-wide support into `app/Support`, then remove the old root once it is empty. If Infrastructure remains a useful boundary, keep it as an explicit mount instead; [Adding a layer](/going-further/custom-layouts#adding-a-layer) shows how. Never delete a layer or its Composer mapping while live classes still depend on it.

Once all moved references are updated, remove obsolete PSR-4 roots, rebuild the autoloader and inspect the inventory:

```bash
composer dump-autoload
php artisan mod:autoload --dry-run
php artisan mod:list --json
```

The custom root above uses the existing `App\` mapping. Remove `Domain\`, `Infrastructure\` or a former `UI\` root only after proving no classes or persisted identities still need the old names. [Model identity review](/going-further/moving-layouts) is a separate deployment gate.

## Translate Config, Layers and Commands

Keep `config/ddd.php` as a reference during the work, then remove it with the package once every relevant setting has a replacement. It is not imported automatically.

| Laravel-DDD setting or command | Mod replacement |
| --- | --- |
| Domain/application paths and namespaces | `ddd`, or explicit `mounts()` roots and `generates()` placements |
| `application_objects` and object `namespaces` | File type declarations in the root that owns each kind |
| Custom `layers` | Named mounts, with file types declared inside each root |
| `base_dto`, `base_view_model`, `base_action` | Corresponding `config/mod.php` `bases` entries; review existing constructor/contracts |
| Custom model base | A model stub importing and extending the intended base |
| `autoload` switches and ignored folders | `discovery` settings and layout `excludes()`; review each kind rather than copying keys |
| `ddd:install` | Publish `mod-config`, choose a layout, then `mod:autoload` |
| `ddd:config wizard`, `update`, `layers` | Edit `config/mod.php` and the provider declaration; inspect `mod:list --json` |
| `ddd:<object>` | The matching `mod:<file-type>` with placement for the new layout |
| `ddd:list` | `mod:list`, including `--json` |
| `ddd:optimize` / `ddd:cache` | `mod:cache`, also included in Laravel's `optimize` |
| `ddd:clear` / `ddd:optimize:clear` | `mod:clear`, also included in `optimize:clear` |

`mod:value-object` also has `mod:value`; DDD's DTO aliases include `mod:data` and `mod:data-transfer-object`. Inspect [Commands](/reference/commands) for exact names, options and destinations. `--domain` belongs to `ddd`; the custom layout above uses `--module`, `--in` or `Inventory:Document`. Laravel's native `make:*` commands retain their usual destinations.

Laravel-DDD's own traits and base classes stop loading when the package is removed. Search for them before removing it:

```bash
rg -n 'Tey\\LaravelDDD' app src tests database
```

Replace `Tey\LaravelDDD\Factories\HasDomainFactory` with Laravel's `Illuminate\Database\Eloquent\Factories\HasFactory`; Mod resolves the module factory. Review any other hit the same way: a model that still uses one of them stops the app from booting as soon as Mod scans it.

Recreate custom generator stubs using [Mod's stub names and placeholders](/going-further/stubs). Do not assume an old `ddd` stub name, custom hook or command option transfers unchanged. Preview representative model/factory/policy, DTO, view-model, provider and custom-layer commands before generating real files. Changing a configured base affects new generation; it does not rewrite existing subclasses.

For a shared view-model base, configure `'bases' => ['view-model' => App\UI\ViewModels\ViewModel::class]` only after verifying the application's real typed and legacy contracts. Keep working constructor and collection behaviour rather than hiding incompatibilities with casts or exclusions.

## Wire Pages After the PHP Move

Moving PHP does not require moving frontend pages in the same step. Once that layer is stable, choose module page folders and Inertia identities, then preview:

```bash
php artisan mod:install inertia --dry-run --json
```

Review `would_write` and the warnings. Recognized starter kits can be wired automatically. For a custom bootstrap, retain the modal adapter, plugins, setup callback and persistent layout; use the [printed insertion points](/going-further/frontend#customized-inertia-bootstraps) to replace only the page lookup.

Update app/module globs, aliases, TypeScript inclusion, Tailwind scanning and Blade refresh paths. Render a module page with its qualified identity, such as `Inventory::Document/Index` in Vue. Since 0.5, [Inertia page registration](/going-further/frontend#inertia-page-checks) supports page-existence checks and test assertions without an application-owned finder workaround. Keep those checks enabled and verify that a missing module page fails.

Use [Mod::pageEntry()](/going-further/frontend#full-page-inertia-loads) in the root Blade view instead of treating a qualified page name as an app-relative filename. Build and test a direct URL load as well as client navigation. Type checking a resolver alone does not prove that Vite's manifest contains the entry.

## Refresh Boost and App Guidance

With Laravel Boost installed, run `php artisan boost:install` and select Mod's guideline and `mod-development` skill. Remove the old Laravel-DDD guideline/skill selection, then run `php artisan boost:update`. Update application-owned guidance in `.ai/guidelines` and rules to name the new namespaces and generator commands, and regenerate the agent files from those sources.

Inspect the generated `AGENTS.md`, `CLAUDE.md` and Boost metadata. Remove stale `ddd:*` instructions and source paths. The [Mod inventory and preview tools](/going-further/agents#using-laravel-boost) let agents read the configured layout rather than guess where classes go. Keep app-specific ownership and behaviour rules in the app's guidance.

## Verify Before Deployment

Use the same checks after each reviewable step, then verify the complete result:

- Review `mod:list --json` for roots, file types, discovery and frontend wiring. Preview representative generators and check their paths, imports and bases.
- Compare route names, methods, URIs and middleware with the baseline; regenerate route helpers and frontend types after controller moves.
- Run the full PHP suite, static analysis and formatting with the existing strictness. Include fixtures outside Laravel's default app folders. Resolve exposed errors without weakening assertions or excluding moved code.
- Prove provider, command, migration and listener registration once each, factory lookup and policy resolution. Exercise authorization and real application entrypoints.
- Check frontend formatting, lint, types and production builds. Exercise direct module loads, client navigation, persistent layouts and a rejecting missing-page check.
- Verify the shared kit's PHP/frontend import boundary and all changed alias, scan, formatter and test roots.
- Restore representative old polymorphic rows and serialized work in an isolated snapshot. Test relation reads and the reviewed identity migration, including its rollback/provenance limits.
- Install from the exact final commit without dev dependencies in a disposable copy. Verify package discovery, migrations and the application's production cache/boot commands. Investigate each failing gate separately.
- Search for obsolete namespaces, `ddd:*`, old stub names and stale paths in configuration, tests, scripts and generated guidance. Review historical migrations individually; do not rewrite already-run migrations as a shortcut for a data migration.
- Review the backup, producers/workers, delayed jobs, cutover order and rollback plan before deployment. Rebuild discovery/cache state and restart workers under the new code at the planned time.

Keep the old/new class mapping and verification evidence with the change. A passing local build is useful evidence; publication, deployment and post-deployment checks are separate steps.
