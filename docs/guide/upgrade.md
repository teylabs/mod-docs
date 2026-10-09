# Upgrading

0.2 renames the Layout API outright. Update layout declarations, config keys and exception imports before upgrading an app that customizes mod.

## Upgrading to 0.3

HTTP classes (controllers, requests, middleware, resources) now live under Http/

## Renamed in 0.2

| 0.1 | 0.2 |
| --- | --- |
| `root()` | `mounts()` |
| `kind()` | `generates()` |
| `relation($id, from: ..., to: ...)` | `relates($from, $to, as: $id)`; omit `as:` for the usual `<from>-<to>` id |
| `exclude()` | `excludes()` |
| `typeFolders()` | `path()` with a project-relative group path |
| `placementOption()` | removed; the token in `path()` names the option |
| `Tey\Mod\Layout\Kind` | `Tey\Mod\Layout\FileType` in `using:` callbacks |
| `Tey\Mod\Exceptions\UnknownKind` | `Tey\Mod\Exceptions\UnknownFileType` |
| `GeneratedBase::inKindRoot()` | `GeneratedBase::inFileTypeRoot()` |
| `discovery.kinds` | `discovery.file_types` |

Compiled-layout reads such as `hasKind()`, `kind()` and `kinds()` and the generator's protected `kind()` hook keep their names. The table covers the renamed builder API and public identifiers.

## Before

A 0.1 declaration adds a file type and customizes a model's factory relation:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')
    ->kind('validator', in: 'Modules/{module}/Validators', suffix: 'Validator')
    ->relation('model-factory', from: 'model', to: 'factory')
    ->placementOption('area');
```

## After

The group path now names the placement token:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')
    ->generates('validator', in: 'Modules/{module}/Validators', suffix: 'Validator')
    ->relates('model', 'factory')
    ->path('app/Modules/{area}');
```

```bash
php artisan mod:validator Knowledge:Upload
# -> app/Modules/Knowledge/Validators/UploadValidator.php
```

The option is `--area`; `Knowledge:Upload` and `--in=Knowledge` still work. Generator templates use `@area` and `{{ area }}`. [Custom layouts](/going-further/custom-layouts#extending-a-layout) explains inherited token names and moved paths.

Change the discovery map's key from `kinds` to `file_types`, retaining its entries. Run `php artisan mod:clear` to remove an old discovery cache, then rebuild with `php artisan mod:cache` during deployment. For paths outside the app's autoload mappings, run `php artisan mod:autoload`.
