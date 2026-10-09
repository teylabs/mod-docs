# Layouts

A layout decides where each file type goes. You choose one in `config/mod.php`, and every `mod:*` command writes to its folders.

## Choosing a layout

Six layouts are built in. The table shows where each one writes a `Document` model for a `Knowledge` module:

```php memo="config/mod.php"
'layout' => 'modules',
```

| Layout | Organizes code as | `mod:model Knowledge:Document` writes |
| --- | --- | --- |
| `laravel` | Laravel's own folders | `app/Models/Document.php` (no `Knowledge:`) |
| `modules` | a modular monolith: one folder per module | `app/Modules/Knowledge/Models/Document.php` |
| `features` | feature folders | `app/Features/Knowledge/Models/Document.php` |
| `slices` | vertical slices: features, each split into slices | `app/Knowledge/Models/Document.php` |
| `type-first` | Laravel's folders, with an optional sub-folder | `app/Models/Knowledge/Document.php` |
| `ddd` | domain-driven design, as in laravel-ddd | `src/Domain/Knowledge/Models/Document.php` |

The default, `laravel`, places files exactly like `make:*`. Changing the layout changes where new files go; existing files stay where they are.

## Comparing the layouts

Each tree is the result of `php artisan mod:model Knowledge:Document --all` in a fresh app:

::: code-group

```text [modules]
app/Modules/Knowledge/
├── Controllers/
│   └── DocumentController.php
├── Database/
│   ├── Factories/
│   │   └── DocumentFactory.php
│   ├── Migrations/
│   │   └── 2026_10_08_120000_create_documents_table.php
│   └── Seeders/
│       └── DocumentSeeder.php
├── Models/
│   └── Document.php
├── Policies/
│   └── DocumentPolicy.php
└── Requests/
    ├── StoreDocumentRequest.php
    └── UpdateDocumentRequest.php
```

```text [features]
app/Features/Knowledge/
├── Database/
│   ├── Factories/
│   │   └── DocumentFactory.php
│   ├── Migrations/
│   │   └── 2026_10_08_120000_create_documents_table.php
│   └── Seeders/
│       └── DocumentSeeder.php
├── Http/
│   ├── Controllers/
│   │   └── DocumentController.php
│   └── Requests/
│       ├── StoreDocumentRequest.php
│       └── UpdateDocumentRequest.php
├── Models/
│   └── Document.php
└── Policies/
    └── DocumentPolicy.php
```

```text [type-first]
app/
├── Http/
│   ├── Controllers/
│   │   └── Knowledge/
│   │       └── DocumentController.php
│   └── Requests/
│       └── Knowledge/
│           ├── StoreDocumentRequest.php
│           └── UpdateDocumentRequest.php
├── Models/
│   └── Knowledge/
│       └── Document.php
└── Policies/
    └── Knowledge/
        └── DocumentPolicy.php
database/
├── factories/
│   └── Knowledge/
│       └── DocumentFactory.php
├── migrations/
│   └── Knowledge/
│       └── 2026_10_08_120000_create_documents_table.php
└── seeders/
    └── Knowledge/
        └── DocumentSeeder.php
```

```text [ddd]
app/Modules/Knowledge/
├── Controllers/
│   └── DocumentController.php
└── Requests/
    ├── StoreDocumentRequest.php
    └── UpdateDocumentRequest.php
src/Domain/Knowledge/
├── Database/
│   ├── Factories/
│   │   └── DocumentFactory.php
│   ├── Migrations/
│   │   └── 2026_10_08_120000_create_documents_table.php
│   └── Seeders/
│       └── DocumentSeeder.php
├── Models/
│   └── Document.php
└── Policies/
    └── DocumentPolicy.php
```

:::

[Commands](/reference/commands#where-each-command-writes) lists the folder of every command in every layout.

## The slices layout

`slices` groups code by feature, then splits each feature into slices: one folder per operation, such as `IndexDocument`. A slice's classes have fixed names, so the folder says what the operation is and the file says what part of it you're looking at. The commands for them take no name:

```bash
php artisan mod:model Knowledge:Document -mf
php artisan mod:handler --in=Knowledge/IndexDocument
php artisan mod:request --in=Knowledge/IndexDocument
php artisan mod:message --in=Knowledge/IndexDocument
```

```text
app/Knowledge/
├── IndexDocument/
│   ├── Command.php
│   ├── Handler.php
│   └── Request.php
├── Database/
│   ├── Factories/
│   │   └── DocumentFactory.php
│   └── Migrations/
│       └── 2026_10_08_120000_create_documents_table.php
└── Models/
    └── Document.php
```

`mod:handler`, `mod:message`, `mod:request`, `mod:query` and `mod:validator` write a slice's classes. Models, events, jobs and the other shared classes sit in the feature's own folders.

## The type-first layout

`type-first` keeps Laravel's folders and adds an optional sub-folder below each one:

```bash
php artisan mod:job Knowledge:ExtractText
# -> app/Jobs/Knowledge/ExtractText.php

php artisan mod:job ExtractText
# -> app/Jobs/ExtractText.php
```

## The DDD layout

The `ddd` layout uses [laravel-ddd](https://github.com/teylabs/laravel-ddd)'s folders, so a laravel-ddd application keeps its structure:

| Namespace | Folder | Holds |
| --- | --- | --- |
| `Domain\` | `src/Domain` | models, DTOs, value objects, view models, actions and the other domain classes |
| `App\Modules\` | `app/Modules` | controllers, requests and middleware |
| `Tests\` | `tests` | tests, in `tests/Feature/<Domain>` |

### Autoloading the domain namespace

`src/Domain` is outside `app/`. Run `php artisan mod:autoload` to add its namespace to Composer and reload the autoloader. It adds this entry:

```json memo="composer.json"
"autoload": {
    "psr-4": {
        "App\\": "app/",
        "Domain\\": "src/Domain/"
    }
}
```

```bash
php artisan mod:autoload
```

### Generating domain classes

Each class belongs to a domain, given as `Knowledge:`, `--domain=Knowledge` or `--in=Knowledge`:

```bash
php artisan mod:dto Knowledge:DocumentData
# -> src/Domain/Shared/Data/DataTransferObject.php (created once)
# -> src/Domain/Knowledge/Data/DocumentData.php

php artisan mod:action Knowledge:IndexDocument
# -> src/Domain/Knowledge/Actions/IndexDocument.php
```

A domain can be nested: `Knowledge.Search` (or `Knowledge/Search`) writes to `src/Domain/Knowledge/Search`.

`mod:dto`, `mod:value-object`, `mod:view-model` and `mod:action` start from starter stubs, and use spatie/laravel-data, spatie/laravel-view-models or lorisleiva/laravel-actions when they're installed. Their base classes go in `src/Domain/Shared`, where laravel-ddd puts them. [Stubs](/going-further/stubs#starter-stubs) covers each one.

### laravel-ddd command names

The DDD commands also answer to laravel-ddd's names:

| Command | Aliases |
| --- | --- |
| `mod:dto` | `mod:data`, `mod:data-transfer-object`, `mod:datatransferobject` |
| `mod:value-object` | `mod:value`, `mod:valueobject` |
| `mod:view-model` | `mod:viewmodel` |

Every hyphenated command also works without the dash, in every layout. In the `modules` layout, `mod:dto` answers to `mod:data` and `mod:value-object` to `mod:value` as well.

<a id="extending-a-layout"></a>

## Customizing a layout

Every built-in layout can be customized from a service provider. One line adds a file type and its `mod:*` command. `in:` is relative to the layout's root, `app/` in `modules`:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->generates('validator', in: 'Modules/{module}/Validators', suffix: 'Validator');
```

```bash
php artisan mod:validator Knowledge:Upload
# -> app/Modules/Knowledge/Validators/UploadValidator.php
```

[Custom Layouts](/going-further/custom-layouts) covers customizing, extending and defining layouts.

[Custom generators](/going-further/custom-generators) adds commands from generator templates or PHP declarations.
