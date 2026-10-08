# Quick Start

In five steps, you'll have a `Knowledge` module with a model, its migration and factory, and an event listener that Laravel registers on its own.

## Choosing the Modules Layout

After [installing mod](/guide/installation), set the layout:

```php memo="config/mod.php"
'layout' => 'modules',
```

## Generating a Model

Generate a `Document` model in the `Knowledge` module, with its migration and factory:

```bash
php artisan mod:model Knowledge:Document -mf
```

```text
   INFO  Model [app/Modules/Knowledge/Models/Document.php] created successfully.
   INFO  Factory [app/Modules/Knowledge/Database/Factories/DocumentFactory.php] created successfully.
   INFO  Migration [app/Modules/Knowledge/Database/Migrations/2026_10_08_120000_create_documents_table.php] created successfully.
```

`Knowledge:` names the module. `-m` and `-f` are `make:model`'s own options.

## Running the Migration

```bash
php artisan migrate
```

```text
   INFO  Running migrations.

  2026_10_08_120000_create_documents_table .......... 1.91ms DONE
```

## Adding an Event and a Listener

```bash
php artisan mod:event Knowledge:DocumentUploaded
php artisan mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded
```

```text
   INFO  Event [app/Modules/Knowledge/Events/DocumentUploaded.php] created successfully.
   INFO  Listener [app/Modules/Knowledge/Listeners/GenerateEmbeddings.php] created successfully.
```

The listener's `handle()` method accepts `App\Modules\Knowledge\Events\DocumentUploaded`, from the same module.

## Seeing the Listener Registered

```bash
php artisan event:list --event=DocumentUploaded
```

```text
  App\Modules\Knowledge\Events\DocumentUploaded ..
  ⇂ App\Modules\Knowledge\Listeners\GenerateEmbeddings@handle
```

The listener is registered, and `Document::factory()` resolves to `App\Modules\Knowledge\Database\Factories\DocumentFactory`.
