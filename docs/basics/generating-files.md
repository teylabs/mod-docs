# Generating Files

Each file type in your layout has a `mod:*` command that writes into the layout's folders. It is Laravel's own `make:*` command underneath, so it takes the same arguments and options and generates the same code.

## Running a Generator

In an app that stores documents, a `Knowledge` module holds everything about them. With the `modules` layout, generate an event for an uploaded document and a listener for it:

```bash
php artisan mod:event Knowledge:DocumentUploaded
# -> app/Modules/Knowledge/Events/DocumentUploaded.php

php artisan mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded
# -> app/Modules/Knowledge/Listeners/GenerateEmbeddings.php
```

`--event=DocumentUploaded` is `make:listener`'s own option. The listener finds the event in the same module:

```php
<?php

namespace App\Modules\Knowledge\Listeners;

use App\Modules\Knowledge\Events\DocumentUploaded;

class GenerateEmbeddings
{
    public function handle(DocumentUploaded $event): void
    {
        //
    }
}
```

`make:*` is untouched and keeps writing to Laravel's default folders.

### Listing the Commands

The commands depend on your layout: `modules` has `mod:action`, `slices` has `mod:handler`, and `ddd` has `mod:dto`. List the ones your layout has:

```bash
php artisan list mod
```

[Commands](/reference/commands) lists every command, its options and the layouts that have it.

## Generating Related Files

`make:model`'s options for related files create them in the same module:

```bash
php artisan mod:model Knowledge:Document --all
```

```text
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

The same goes for `-m`, `-f`, `-s`, `--policy`, `--controller` and `--requests`. As with `make:model`, `--requests` writes form requests only for a resource controller, so pass `--controller --resource --requests` together.

Each generated class refers to the others where they are: the factory names the model, and the model finds its factory, so `Document::factory()` works wherever the factory lives.

## Choosing the Module

The `laravel` layout puts files where `make:*` does. The other layouts group your code, so each command also needs to know which group a file belongs to.

Each way a layout groups code is a **dimension**. `modules` has one: the module. `slices` has two: the feature, and the slice inside it. A layout's folders show each one as a placeholder, such as `{module}` in `app/Modules/{module}/Models`, and you give it a value, such as `Knowledge`.

These three commands do the same thing:

```bash
php artisan mod:model Document --module=Knowledge   # an option named after the placeholder
php artisan mod:model Document --in=Knowledge       # every value at once
php artisan mod:model Knowledge:Document            # the short form: value, colon, class name
```

Each layout's option:

| Layout | Options | Values |
| --- | --- | --- |
| `laravel` | none | |
| `modules` | `--module` | `Knowledge` |
| `features` | `--feature` | `Knowledge` |
| `slices` | `--feature`, `--slice` | `Knowledge`, `IndexDocument` |
| `type-first` | `--feature` (optional) | `Knowledge`, or none for `app/Models/Document.php` |
| `ddd` | `--domain` (one or more folders) | `Knowledge`, or `Knowledge.Search` for `src/Domain/Knowledge/Search` |

### Giving Two Values

When a layout has two dimensions, `--in` and the short form take the values in order, separated by `/`:

```bash
php artisan mod:handler Handler --feature=Knowledge --slice=IndexDocument
php artisan mod:handler Handler --in=Knowledge/IndexDocument
php artisan mod:handler Knowledge/IndexDocument:Handler
# -> app/Knowledge/IndexDocument/Handler.php
```

### Leaving the Module Out

A command that needs a module exits with an error naming every way to give one:

```bash
php artisan mod:model Document
```

```text
   ERROR  mod:model needs a module. Pass --module=<module>, --in=<module>, or prefix the name: <module>:Document.
```

In `features` and `slices`, `mod:command` without a feature writes to `app/Console/Commands`.

## When a File Already Exists

`mod:*` checks every file it is about to write before writing any of them. When one already exists, it prints an error and writes nothing:

```bash
php artisan mod:model Knowledge:Document -f
```

```text
   ERROR  app/Modules/Knowledge/Models/Document.php already exists.
   ERROR  app/Modules/Knowledge/Database/Factories/DocumentFactory.php already exists.
   ERROR  Nothing was written.
```

Pass `--force` to overwrite, on the commands whose `make:*` command has it.
