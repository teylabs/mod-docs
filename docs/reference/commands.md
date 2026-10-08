# Commands

Every Artisan command mod registers, the options each one takes, and the folder each one writes to in each built-in layout. `php artisan list mod` shows the commands your layout has.

## Placement Options

Every generator takes these, in addition to its own options:

| Option | Takes | Example |
| --- | --- | --- |
| `--in` | every value of the layout's placeholders, in order, separated by `/`; a value spanning folders separates them with `.` | `--in=Knowledge/IndexDocument` |
| `--<placeholder>` | one placeholder's value, one option per placeholder the command's folder uses | `--module=Knowledge`, `--feature=Knowledge --slice=IndexDocument`, `--domain=Knowledge.Search` |
| `<values>:` prefix on the name | the same values as `--in`, before a colon | `Knowledge:Document`, `Knowledge/IndexDocument:Handler` |

The `laravel` layout takes no placement. A placeholder option is left out when the Laravel command already has an option of that name; see [When an Option Name Is Already Taken](/going-further/custom-layouts#when-an-option-name-is-already-taken).

A value that differs from an existing group only by case, such as `knowledge` for `Knowledge`, uses that group and says so. A near miss, such as `Knowledg`, asks which you meant in a terminal; with `--no-interaction` it creates the new group. A new value creates its folder and says so. [New and Misspelled Modules](/basics/generating-files#new-and-misspelled-modules) shows the output.

Before writing, a generator checks every file it is about to write, related files included. When one exists, it prints an error and writes nothing. `--force` overwrites, on the commands that list it below.

## Generator Commands

Each command runs the Laravel command in the second column and takes that command's options, listed in the last column. The options come from Laravel, so they follow your Laravel version; these are Laravel 13's. Commands marked "none" have no Laravel generator: they write an empty class, or the file type's [stub](/going-further/stubs).

| Command | Runs | Layouts | Options |
| --- | --- | --- | --- |
| `mod:action` | none | `modules`, `ddd` | `--force` |
| `mod:cast` | `make:cast` | all | `--inbound`, `--force` |
| `mod:channel` | `make:channel` | all | `--force` |
| `mod:class` | `make:class` | all | `--invokable`, `--force` |
| `mod:command` | `make:command` | all | `--command`, `--test`, `--pest`, `--phpunit`, `--force` |
| `mod:config` | `make:config` | `laravel`, `type-first` | `--force` |
| `mod:controller` | `make:controller` | all | `--api`, `--type`, `--invokable`, `--model`, `--parent`, `--resource`, `--requests`, `--singleton`, `--creatable`, `--test`, `--pest`, `--phpunit`, `--force` |
| `mod:dto` | none | `modules`, `ddd` | `--force` |
| `mod:enum` | `make:enum` | all | `--string`, `--int`, `--force` |
| `mod:event` | `make:event` | all | `--force` |
| `mod:exception` | `make:exception` | all | `--render`, `--report`, `--force` |
| `mod:factory` | `make:factory` | all | `--model` |
| `mod:handler` | none | `slices` | `--force` |
| `mod:interface` | `make:interface` | all | `--force` |
| `mod:job` | `make:job` | all | `--sync`, `--batched`, `--test`, `--pest`, `--phpunit`, `--force` |
| `mod:job-middleware` | `make:job-middleware` | all | `--test`, `--pest`, `--phpunit`, `--force` |
| `mod:listener` | `make:listener` | all | `--event`, `--queued`, `--test`, `--pest`, `--phpunit`, `--force` |
| `mod:mail` | `make:mail` | all | `--markdown`, `--view`, `--test`, `--pest`, `--phpunit`, `--force` |
| `mod:message` | none | `slices` | `--force` |
| `mod:middleware` | `make:middleware` | all | `--test`, `--pest`, `--phpunit` |
| `mod:migration` | `make:migration` | all | `--create`, `--table`, `--fullpath` |
| `mod:model` | `make:model` | all | `--all`, `--controller`, `--factory`, `--migration`, `--morph-pivot`, `--policy`, `--seed`, `--pivot`, `--resource`, `--api`, `--requests`, `--test`, `--pest`, `--phpunit`, `--force` |
| `mod:notification` | `make:notification` | all | `--markdown`, `--test`, `--pest`, `--phpunit`, `--force` |
| `mod:observer` | `make:observer` | all | `--model`, `--force` |
| `mod:policy` | `make:policy` | all | `--model`, `--guard`, `--force` |
| `mod:provider` | `make:provider` | all | `--force`. In `ddd`, the provider is named as given, with no `ServiceProvider` suffix |
| `mod:query` | none | `modules`, `features`, `slices`, `type-first` | `--force` |
| `mod:request` | `make:request` | all | `--force` |
| `mod:resource` | `make:resource` | all | `--json-api`, `--collection`, `--force` |
| `mod:rule` | `make:rule` | all | `--implicit`, `--force` |
| `mod:scope` | `make:scope` | all | `--force` |
| `mod:seeder` | `make:seeder` | all | none |
| `mod:test` | `make:test` | all | `--unit`, `--pest`, `--phpunit`, `--force` |
| `mod:trait` | `make:trait` | all | `--force` |
| `mod:validator` | none | `features`, `slices` | `--force` |
| `mod:value-object` | none | `modules`, `ddd` | `--force` |
| `mod:view-model` | none | `modules`, `ddd` | `--force` |

- `mod:migration` places migrations from the layout, so it exits with an error for `--path` and `--realpath`. Use `--in` instead.
- `mod:dto`, `mod:view-model`, `mod:value-object` and `mod:action` start from [starter stubs](/going-further/stubs#starter-stubs), and the first `mod:dto` or `mod:view-model` writes its [base class](/going-further/stubs#generated-base-classes).
- `mod:model`'s related-file options (`--factory`, `--migration`, `--seed`, `--policy`, `--controller`, `--requests`, `--all`) write each file in the same group.

### Aliases

| Command | Aliases |
| --- | --- |
| `mod:dto` | `mod:data` in `modules` and `ddd`; `mod:data-transfer-object` in `ddd` |
| `mod:value-object` | `mod:value` |

Every hyphenated command or alias also works without the dash: `mod:viewmodel`, `mod:valueobject`, `mod:jobmiddleware`, `mod:datatransferobject`. When that name is already a command or alias, the existing one keeps it. `php artisan list mod` shows each command's aliases in brackets:

```text
  mod:value-object    [mod:value|mod:valueobject] Create a new value object class
```

### Commands for Your Own File Types

A file type you add with `kind()` gets `mod:<id>`, or the name given in `command:`, plus any `aliases:`, each also without the dash: `kind('api-resource', ...)` answers to `mod:api-resource` and `mod:apiresource`. Without a Laravel generator, it takes `--force` and the placement options.

### Commands From Another Layout

A built-in command your layout doesn't have exits with an error naming the layouts that have it:

```bash
php artisan mod:handler Knowledge:Thing
```

```text
   ERROR  mod:handler is not a command of the modules layout. The slices layout has it.

  To add it, declare the file type in a service provider: Mod::layout('modules')->kind('handler', in: '...'). Or switch layouts in config/mod.php.
```

[Extending a Built-In Layout](/going-further/custom-layouts#extending-a-built-in-layout) shows the `kind()` line.

## Where Each Command Writes

Folders below each layout's group folder:

| Layout | Group folder |
| --- | --- |
| `modules` | `app/Modules/<Module>` |
| `features` | `app/Features/<Feature>` |
| `slices` | `app/<Feature>`, and `app/<Feature>/<Slice>` for a slice's classes |
| `ddd` | `src/Domain/<Domain>` |

| Command | `modules` | `features` | `slices` | `ddd` |
| --- | --- | --- | --- | --- |
| `mod:action` | `Actions` | | | `Actions` |
| `mod:cast` | `Casts` | `Casts` | `Casts` | `Casts` |
| `mod:channel` | `Channels` | `Broadcasting` | `Broadcasting` | `Channels` |
| `mod:class`, `mod:interface`, `mod:trait` | the group folder | the group folder | the group folder | the group folder |
| `mod:command` | `Console` | `Console/Commands` | `Console/Commands` | `Commands` |
| `mod:controller` | `Controllers` | `Http/Controllers` | `Http/Controllers` | `app/Modules/<Domain>/Controllers` |
| `mod:dto` | `Data` | | | `Data` |
| `mod:enum` | `Enums` | `Enums` | `Enums` | `Enums` |
| `mod:event` | `Events` | `Events` | `Events` | `Events` |
| `mod:exception` | `Exceptions` | `Exceptions` | `Exceptions` | `Exceptions` |
| `mod:factory` | `Database/Factories` | `Database/Factories` | `Database/Factories` | `Database/Factories` |
| `mod:handler` | | | `<Slice>/Handler.php` | |
| `mod:job` | `Jobs` | `Jobs` | `Jobs` | `Jobs` |
| `mod:job-middleware` | `Jobs/Middleware` | `Jobs/Middleware` | `Jobs/Middleware` | `Jobs/Middleware` |
| `mod:listener` | `Listeners` | `Listeners` | `Listeners` | `Listeners` |
| `mod:mail` | `Mail` | `Mail` | `Mail` | `Mail` |
| `mod:message` | | | `<Slice>/Command.php` | |
| `mod:middleware` | `Middleware` | `Http/Middleware` | `Http/Middleware` | `app/Modules/<Domain>/Middleware` |
| `mod:migration` | `Database/Migrations` | `Database/Migrations` | `Database/Migrations` | `Database/Migrations` |
| `mod:model` | `Models` | `Models` | `Models` | `Models` |
| `mod:notification` | `Notifications` | `Notifications` | `Notifications` | `Notifications` |
| `mod:observer` | `Observers` | `Observers` | `Observers` | `Observers` |
| `mod:policy` | `Policies` | `Policies` | `Policies` | `Policies` |
| `mod:provider` | `Providers` | `Providers` | `Providers` | `Providers` |
| `mod:query` | `Queries` | `Queries` | `<Slice>/Query.php` | |
| `mod:request` | `Requests` | `Http/Requests` | `<Slice>/Request.php` | `app/Modules/<Domain>/Requests` |
| `mod:resource` | `Resources` | `Http/Resources` | `Http/Resources` | `Resources` |
| `mod:rule` | `Rules` | `Rules` | `Rules` | `Rules` |
| `mod:scope` | `Scopes` | `Scopes` | `Scopes` | `Scopes` |
| `mod:seeder` | `Database/Seeders` | `Database/Seeders` | `Database/Seeders` | `Database/Seeders` |
| `mod:test` | `tests/Feature/Modules/<Module>` | `tests/Feature/<Feature>` | `tests/Feature/<Feature>/<Slice>` | `tests/Feature/<Domain>` |
| `mod:validator` | | `Validation` | `<Slice>/Validator.php` | |
| `mod:value-object` | `ValueObjects` | | | `ValueObjects` |
| `mod:view-model` | `ViewModels` | | | `ViewModels` |

- The `laravel` layout writes every file where the matching `make:*` command does. `type-first` uses the same folders with an optional sub-folder for the feature, such as `app/Models/Knowledge` or `database/factories/Knowledge`, and adds `mod:query`, which writes to `app/Queries/<Feature>`.
- A slice's classes have fixed names, so the name can be left out: `mod:handler --in=Knowledge/IndexDocument` writes `app/Knowledge/IndexDocument/Handler.php`. A different name is not used, and the command says so. In `slices`, `mod:test` takes the slice as an optional second value.
- `mod:test --unit` writes to `tests/Unit` instead of `tests/Feature`.
- In `features` and `slices`, `mod:command` without a feature writes to `app/Console/Commands`.
- Class names take the file type's suffix: `Controller`, `Request`, `Policy`, `Factory`, `Seeder`, and `ServiceProvider` for providers in every layout but `ddd`. In `ddd`, a provider is named as given: `mod:provider Knowledge:Knowledge` writes `src/Domain/Knowledge/Providers/Knowledge.php`, and `Knowledge:KnowledgeServiceProvider` writes `KnowledgeServiceProvider.php`.

## Writing Base Classes

| Command | Does |
| --- | --- |
| `mod:bases` | Writes every [generated base class](/going-further/stubs#generated-base-classes) the layout can use that is missing, whether or not a class extends it yet. It never overwrites one, and takes no options |

```bash
php artisan mod:bases
```

```text
   INFO  Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].
   INFO  Created base class App\Support\ViewModels\ViewModel [app/Support/ViewModels/ViewModel.php].
```

When every base exists, it prints `Every base class already exists.` In a layout whose file types extend no generated base, such as `laravel`, it prints `No file type in this layout extends a generated base class.` A configured base or an installed package means there is no base to write. It is registered with the `mod:*` commands.

## Discovery Commands

| Command | Does | Also run by |
| --- | --- | --- |
| `mod:cache` | Scans the layout and caches the discovered providers, commands, listeners, subscribers and migration folders | `php artisan optimize` |
| `mod:clear` | Removes the discovery cache file | `php artisan optimize:clear` |

```bash
php artisan mod:cache
```

```text
   INFO  Discovery cached in [bootstrap/cache/mod-discovery.php]: 1 providers, 0 commands, 1 listeners, 0 subscribers, 2 directories, 6 rejected.

  Rejected files were found but not registered: 6 placed by no file type (helpers and plain classes; nothing to do). Run with -v to list them.
```

The second line counts the files it found but didn't register, grouped by reason. `php artisan mod:cache -v` lists each rejected file with its reason; [Caching Discovery in Production](/basics/auto-discovery#caching-discovery-in-production) explains each reason.

Both are registered only while the `mod:*` commands and discovery are both on. [Caching Discovery in Production](/basics/auto-discovery#caching-discovery-in-production) covers when the cache is used.
