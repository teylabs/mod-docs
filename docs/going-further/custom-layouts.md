# Custom Layouts

A layout is one chain of calls in a service provider. You can add file types to a built-in layout, move its folders, add a layer to it, or define a layout from scratch. When you're done, `mod:*` commands write to every folder your app uses.

## Extending a Built-In Layout

Calling `Mod::layout()` with an existing name extends that layout. A new file type gets a `mod:<type>` command. `in:` is relative to the layout's root: `app/` in `modules` and `features`, and `src/Domain` for `ddd`'s domain classes. Here, a `Knowledge` module gets validators for uploads:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->kind('validator', in: 'Modules/{module}/Validators', suffix: 'Validator');
```

```bash
php artisan mod:validator Knowledge:Upload
# -> app/Modules/Knowledge/Validators/UploadValidator.php
```

A file type with no Laravel generator starts as an empty class. [Stubs](/going-further/stubs#starting-from-your-own-stub) shows how to change what it starts as.

### Moving a Folder

Repeating an existing file type changes only the arguments you pass. This moves every job in the `features` layout:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('features')->kind('job', in: 'Features/{feature}/Queue');
```

```bash
php artisan mod:job Knowledge:ExtractText
# -> app/Features/Knowledge/Queue/ExtractText.php
```

## Defining a Layout

A layout of your own starts from its roots: each maps a namespace to a folder. This one keeps the domain core in `src/Domain` and each domain's controllers in `app/Modules`:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\Root;

Mod::layout('domains')
    ->root('domain', 'Domain\\', 'src/Domain', fn (Root $root) => $root
        ->kind('model', in: '{domain}/Models')
        ->kind('action', in: '{domain}/Actions'))
    ->root('app', 'App\\', 'app', fn (Root $root) => $root
        ->kind('controller', in: 'Modules/{domain}/Controllers', suffix: 'Controller'))
    ->kind('factory', in: 'domain:{domain}/Database/Factories', suffix: 'Factory')
    ->relation('model-factory', from: 'model', to: 'factory')
    ->exclude('App\\Support\\');
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

Add `"Domain\\": "src/Domain/"` to your `composer.json` autoload, as for [the DDD layout](/basics/layouts#autoloading-the-domain-namespace).

The layout is checked the first time it is used. Every problem is reported at once, each naming the call that caused it.

### Roots

`root($name, $namespace, $path, $closure)` maps a namespace to a folder. File types declared inside the closure live in that root. A `null` namespace makes a root for plain files, such as config files.

### File Types

`kind($id, in: ...)` declares a file type and its folder below the root. A `root:` prefix, as in `domain:{domain}/Database/Factories`, places it in another root. Without one, it uses the enclosing closure's root, or else the first declared root.

Other arguments set the class name's suffix, a fixed class name, the command's name and aliases, and where discovery looks. [Layout API](/reference/layout-api#kind) lists them all.

### Related Files

`relation($id, from: ..., to: ...)` connects two file types. It drives options such as `--factory` and `--policy`, and how one generated class refers to another. With `relation('model-factory', from: 'model', to: 'factory')`, `mod:model --factory` writes the factory and the model finds it. Ids follow `<from>-<to>`, as in the built-in layouts; [Layout API](/reference/layout-api#relation) lists them.

### Exclusions

`exclude(...)` marks namespaces or paths inside a root that no file type owns. Mod never places anything there, and discovery skips them.

## Placeholders

Placeholders in `in:` are the layout's dimensions: the ways it groups code. Their order of first appearance is the order of values in `--in`, and each one is also an option of the commands whose folder uses it.

| Placeholder | Meaning | Value |
| --- | --- | --- |
| `{feature}` | one folder | `--feature=Knowledge` or `--in=Knowledge` |
| `{feature?}` | an optional folder | omit it, or `--feature=Knowledge` |
| `{area+}` | one or more folders | `--area=Knowledge.Search` writes to `.../Knowledge/Search/...` |

### Renaming an Option

An option is named after its placeholder. To call it something else, rename it on the layout:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->placementOption('area');               // mod:model Document --area=Knowledge
Mod::layout('slices')->placementOption('operation', '{slice}'); // --feature=Knowledge --operation=IndexDocument
```

With one placeholder, you don't need to say which one. With several, name the placeholder you are renaming.

### When an Option Name Is Already Taken

Some Laravel commands already have an option that could share a placeholder's name. If your layout writes controllers to `Http/Controllers/{model}`, a `--model` option would clash with `make:controller --model`. Mod keeps Laravel's option, leaves the placement option out and logs a warning. `--in` and the short form still work. Rename the placeholder's option to get it back.

## Adding a Layer

Add a root to a built-in layout. In `ddd`, file types that use the same `{domain+}` placeholder take the same `--domain` option and `Knowledge:` prefix:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\Root;

Mod::layout('ddd')
    ->root('infrastructure', 'Infrastructure\\', 'src/Infrastructure', fn (Root $root) => $root
        ->kind('repository', in: '{domain+}/Repositories', suffix: 'Repository')
        ->kind('client', in: '{domain+}/Clients', suffix: 'Client'));
```

```bash
php artisan mod:repository Knowledge:Document
# -> src/Infrastructure/Knowledge/Repositories/DocumentRepository.php

php artisan mod:client Knowledge.Search:Index
# -> src/Infrastructure/Knowledge/Search/Clients/IndexClient.php
```

Add `"Infrastructure\\": "src/Infrastructure/"` to your `composer.json` autoload as well.

To put a Laravel file type in the new layer, declare it there with a `root:` prefix. This moves every job to `src/Infrastructure/<Domain>/Jobs`:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('ddd')->kind('job', in: 'infrastructure:{domain+}/Jobs');
```
