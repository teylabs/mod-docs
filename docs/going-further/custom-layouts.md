# Custom Layouts

A layout is one chain of calls in a service provider. You can add file types to a built-in layout, move its folders, add a layer to it, or define a layout from scratch. When you're done, `mod:*` commands write to every folder your app uses.

<a id="extending-a-built-in-layout"></a>

## Customizing a Built-in Layout

Calling `Mod::layout()` with an existing name customizes that layout. A new file type gets a `mod:<type>` command. `in:` is relative to the layout's root: `app/` in `modules` and `features`, and `src/Domain` for `ddd`'s domain classes. Here, a `Knowledge` module gets validators for uploads:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->generates('validator', in: 'Modules/{module}/Validators', suffix: 'Validator');
```

```bash
php artisan mod:validator Knowledge:Upload
# -> app/Modules/Knowledge/Validators/UploadValidator.php
```

For a new command from a template, see [Custom generators](/going-further/custom-generators). A file type with no Laravel generator starts as an empty class. [Stubs](/going-further/stubs#starting-from-your-own-stub) shows how to change what it starts as.

### Moving a Folder

Repeating an existing file type changes only the arguments you pass. This moves every job in the `features` layout:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('features')->generates('job', in: 'Features/{feature}/Queue');
```

```bash
php artisan mod:job Knowledge:ExtractText
# -> app/Features/Knowledge/Queue/ExtractText.php
```

## Extending a Layout

Use `->extends()` first in the chain to copy a layout, then customize the copy:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('areas')->extends('modules')->path('src/Areas/{area}');
```

Choose `'layout' => 'areas'` in `config/mod.php`, then generate:

```bash
php artisan mod:autoload
php artisan mod:model Billing:Invoice
# -> src/Areas/Billing/Models/Invoice.php
```

`extends()` copies the parent at that moment; later parent changes do not flow through. A token derived from the parent's name follows the child's name (`modules` → `areas` uses `area`). A token explicitly declared by the parent is inherited: `ddd` keeps `domain`, and `slices` keeps `feature` and `slice`, until the child supplies its own `path()`.

From mod 0.4.1, an explicit `mounts()` can reclaim an inherited exclusion. Equal exclusions are removed; broader exclusions keep the rest excluded. See [Exclusions](#exclusions) below.

`path()` is relative to the project root; absolute paths work too. A type-first path uses a wildcard for the file type folder: `->path('app/*/{feature}')`. Custom layouts can infer a path from their file type paths. [Layout API](/reference/layout-api#group-paths) covers inference and nesting.

## Defining a Layout

A layout of your own starts from its roots: each maps a namespace to a folder. This one keeps the domain core in `src/Domain` and each domain's controllers in `app/Modules`:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\Root;

Mod::layout('domains')
    ->mounts('domain', 'Domain\\', 'src/Domain', fn (Root $root) => $root
        ->generates('model', in: '{domain}/Models')
        ->generates('action', in: '{domain}/Actions'))
    ->mounts('app', 'App\\', 'app', fn (Root $root) => $root
        ->generates('controller', in: 'Modules/{domain}/Http/Controllers', suffix: 'Controller'))
    ->generates('factory', in: 'domain:{domain}/Database/Factories', suffix: 'Factory')
    ->relates('model', 'factory')
    ->excludes('App\\Support\\');
```

Name it in `config/mod.php` to use it:

```php memo="config/mod.php"
'layout' => 'domains',
```

```bash
php artisan mod:model Knowledge:Document --factory
# -> src/Domain/Knowledge/Models/Document.php
# -> src/Domain/Knowledge/Database/Factories/DocumentFactory.php
```

Run `php artisan mod:autoload` before using these classes. It adds the missing Composer mappings and reloads the autoloader.

The layout is checked the first time it is used. Every problem is reported at once, each naming the call that caused it.

### Roots

`mounts($name, $namespace, $path, $closure)` maps a namespace to a folder. File types declared inside the closure live in that root. A `null` namespace makes a root for plain files, such as config files.

### File Types

`generates($id, in: ...)` declares a file type and its folder below the root. A `root:` prefix, as in `domain:{domain}/Database/Factories`, places it in another root. Without one, it uses the enclosing closure's root, or else the first declared root.

Other arguments set the class name's suffix, a fixed class name, the command's name and aliases, and where discovery looks. [Layout API](/reference/layout-api#generates) lists them all.

### Related Files

`relates($from, $to, ...)` connects two file types. It drives options such as `--factory` and `--policy`, and how one generated class refers to another. With `relates('model', 'factory')`, `mod:model --factory` writes the factory and the model finds it. Ids follow `<from>-<to>`, as in the built-in layouts; [Layout API](/reference/layout-api#relates) lists them.

### Exclusions

`excludes(...)` marks namespaces or paths inside a root that no file type owns. Reverse mapping rejects classes there, and discovery skips them.

From mod 0.4.1, an explicit `mounts()` after `extends()` can reclaim an inherited exclusion. If the mounted namespace equals the exclusion, the exclusion is removed. If it is below a broader excluded namespace, only the mounted subtree is carved out; siblings stay excluded. Path exclusions follow the same rule using folder boundaries.

#### Mounting an Excluded Root

The `modules` layout excludes `App\UI\`. This child explicitly mounts it and places the provider file type there:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\Root;

Mod::layout('areas')
    ->extends('modules')
    ->mounts('ui', 'App\\UI\\', 'app/UI', fn (Root $root) => $root
        ->generates('provider', in: 'Providers', suffix: 'ServiceProvider'));
```

Choose `'layout' => 'areas'` in `config/mod.php`, then generate:

```bash
php artisan mod:provider Ui
# -> app/UI/Providers/UiServiceProvider.php
```

The generated provider is owned by the layout: `Mod::current()->locate(App\UI\Providers\UiServiceProvider::class)` finds it, provider discovery registers it, and `mod:list` reports it. The inherited `App\Support\` exclusion still applies.

#### Mounting Part of an Excluded Root

The `modules` layout also excludes `App\Support\`. Mounting a root below it keeps the broader exclusion and makes only this subtree available:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\Root;

Mod::layout('areas')
    ->extends('modules')
    ->mounts('kit', 'App\\Support\\Kit\\', 'app/Support/Kit', fn (Root $root) => $root
        ->generates('provider', in: 'Providers', suffix: 'ServiceProvider'));
```

With `'layout' => 'areas'` selected:

```bash
php artisan mod:provider Kit
# -> app/Support/Kit/Providers/KitServiceProvider.php
```

Generation, `locate()`, discovery and `mod:list` agree on the Kit provider. `App\Support\Other\` and `App\Support\KitExtra\` remain excluded: a mount claims a whole namespace or folder boundary, not names that merely share its prefix.

Exclusions declared by the child always apply, whether they appear before or after `mounts()`. Repeating `excludes('App\\Support\\')` in this child excludes Kit again. An inherited exclusion narrower than the mounted root also stays effective; mounting Kit does not lift an exclusion of `App\Support\Kit\Private\`. A mount still needs a file type whose placement rules own the class.

## Placeholders

Placeholders in `in:` are the layout's dimensions: the ways it groups code. Their order of first appearance is the order of values in `--in`, and each one is also an option of the commands whose folder uses it.

| Placeholder | Meaning | Value |
| --- | --- | --- |
| `{feature}` | one folder | `--feature=Knowledge` or `--in=Knowledge` |
| `{feature?}` | an optional folder | omit it, or `--feature=Knowledge` |
| `{area+}` | one or more folders | `--area=Knowledge.Search` writes to `.../Knowledge/Search/...` |

### Renaming an Option

An option is named after its placeholder. To call it something else, change the token in the group path:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->path('app/Modules/{area}');               // mod:model Document --area=Knowledge
Mod::layout('slices')->path('app/{feature}/{operation}'); // --feature=Knowledge --operation=IndexDocument
```

The path tokens name the options, anchors and placeholders. File type paths follow the new group path.

### When an Option Name Is Already Taken

Some Laravel commands already have an option that could share a placeholder's name. If your layout writes controllers to `Http/Controllers/{model}`, a `--model` option would clash with `make:controller --model`. Mod keeps Laravel's option, leaves the placement option out and logs a warning. `--in` and the short form still work. Rename the placeholder's option to get it back.

## Adding a Layer

Add a root to a built-in layout. In `ddd`, file types that use the same `{domain+}` placeholder take the same `--domain` option and `Knowledge:` prefix:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\Root;

Mod::layout('ddd')
    ->mounts('infrastructure', 'Infrastructure\\', 'src/Infrastructure', fn (Root $root) => $root
        ->generates('repository', in: '{domain+}/Repositories', suffix: 'Repository')
        ->generates('client', in: '{domain+}/Clients', suffix: 'Client'));
```

```bash
php artisan mod:repository Knowledge:Document
# -> src/Infrastructure/Knowledge/Repositories/DocumentRepository.php

php artisan mod:client Knowledge.Search:Index
# -> src/Infrastructure/Knowledge/Search/Clients/IndexClient.php
```

Run `php artisan mod:autoload` to add the Infrastructure mapping as well.

To put a Laravel file type in the new layer, declare it there with a `root:` prefix. This moves every job to `src/Infrastructure/<Domain>/Jobs`:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('ddd')->generates('job', in: 'infrastructure:{domain+}/Jobs');
```
