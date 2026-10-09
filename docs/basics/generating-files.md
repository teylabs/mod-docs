# Generating files

Each file type in your layout has a `mod:*` command that writes into the layout's folders. It is Laravel's own `make:*` command underneath, so it takes the same arguments and options and generates the same code.

## Running a generator

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

### Listing the commands

The commands depend on your layout: `modules` has `mod:dto` and `mod:view-model`, `slices` has `mod:handler`, and `laravel` has neither. List the ones your layout has:

```bash
php artisan list mod
```

Every hyphenated command also works without the dash: `mod:viewmodel`, `mod:valueobject`, `mod:jobmiddleware`. This applies to your own file types too, unless the name is already taken.

[Commands](/reference/commands) lists every command, its options and the layouts that have it.

## Generating related files

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

## Choosing the module

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

### Giving two values

When a layout has two dimensions, `--in` and the short form take the values in order, separated by `/`. A handler's class is always named `Handler`, so its command needs no name:

```bash
php artisan mod:handler --feature=Knowledge --slice=IndexDocument
php artisan mod:handler --in=Knowledge/IndexDocument
php artisan mod:handler Knowledge/IndexDocument:Handler
# -> app/Knowledge/IndexDocument/Handler.php
```

### Leaving the module out

A command that needs a module exits with an error naming every way to give one:

```bash
php artisan mod:model Document
```

```text
   ERROR  mod:model needs a module. Pass --module=<module>, --in=<module>, or prefix the name: <module>:Document.
```

In `features` and `slices`, `mod:command` without a feature writes to `app/Console/Commands`.

### New and misspelled modules

A command compares the module you give with the modules that exist: folders that hold the layout's files for a module. A new name creates the module's folder and says so, listing the existing modules:

```bash
php artisan mod:model Billing:Invoice
```

```text
   INFO  Created new module Billing (existing: Knowledge).
   INFO  Model [app/Modules/Billing/Models/Invoice.php] created successfully.
```

A name that differs from an existing module only by case uses that module and says so:

```bash
php artisan mod:model knowledge:Note
```

```text
   INFO  Using existing module Knowledge (you typed knowledge).
   INFO  Model [app/Modules/Knowledge/Models/Note.php] created successfully.
```

A near miss such as `Knowledg` asks whether you meant an existing module or a new one, with the closest module selected.

Without a terminal to ask in, such as with `--no-interaction` or in CI, it starts the new module and says so:

```bash
php artisan mod:model Knowledg:Note --no-interaction
```

```text
   INFO  Created new module Knowledg (existing: Knowledge).
   INFO  Model [app/Modules/Knowledg/Models/Note.php] created successfully.
```

A near miss is one or two letters away from an existing module, ignoring case, and one letter for names shorter than six, so `Agent` is close to `Agents`. On a case-sensitive disk with both `Knowledge` and `KNOWLEDGE`, `knowledge` asks which one you meant, or exits with an error naming both without a terminal.

Each message prints once per command, and other layouts word it with their own dimension: `Created new feature Knowledge.`, `Created new slice IndexDocument.` In `slices`, Laravel's own `app/Http` and `app/Models` don't count as features.

## When a file already exists

`mod:*` checks every file it is about to write before writing any of them. When every file already exists, it prints an error for each and exits with 0, as `make:*` does:

```bash
php artisan mod:model Knowledge:Document -f
```

```text
   ERROR  app/Modules/Knowledge/Models/Document.php already exists.
   ERROR  app/Modules/Knowledge/Database/Factories/DocumentFactory.php already exists.
```

When some files exist and others don't, it writes none of them, so the new ones aren't left half done. It prints `Nothing was written.` and exits with 1. Here the factory exists and the model doesn't:

```bash
php artisan mod:model Knowledge:Document -f
```

```text
   ERROR  app/Modules/Knowledge/Database/Factories/DocumentFactory.php already exists.
   ERROR  Nothing was written.
```

Pass `--force` to overwrite, on the commands whose `make:*` command has it.

For a repeating class shape, [Custom generators](/going-further/custom-generators) creates its own command. For several file types together, use a [scaffold](/going-further/scaffolds).
