# Stubs

A stub is the template a generated class starts from. Laravel's file types start from Laravel's own stubs. File types mod adds start from mod's stubs, or from an empty class, and your app can replace any of them.

## Starting From Your Own Stub

A file type with no Laravel generator starts as an empty class. To start from your own stub, add `stubs/mod.<type>.stub` to your app. For the `repository` file type from [Adding a Layer](/going-further/custom-layouts#adding-a-layer), which writes a repository for a `Document` model in the `Knowledge` domain:

```php memo="stubs/mod.repository.stub"
<?php

namespace {{ namespace }};

class {{ class }}
{
    //
}
```

```bash
php artisan mod:repository Knowledge:Document
# -> src/Infrastructure/Knowledge/Repositories/DocumentRepository.php, from stubs/mod.repository.stub
```

`stubs/mod.<type>.stub` works for every file type, including those with a Laravel generator, and wins over every other stub. Its placeholders:

| Placeholder | Filled with |
| --- | --- |
| `{{ namespace }}`, `{{ class }}` | the class's namespace and short name |
| `{{ base }}`, `{{ baseClass }}` | the base class's full and short name |
| `{{ baseImport }}` | its `use` line, or nothing when there is no base |
| `{{ extends }}` | ` extends <baseClass>`, or nothing when there is no base |

## Starter Stubs in the DDD Layout

In the `ddd` layout, DTOs, value objects, view models and actions start as plain Laravel-style classes. When a package for them is installed, mod uses it instead:

| Command | When installed | Otherwise |
| --- | --- | --- |
| `mod:dto` | [spatie/laravel-data](https://github.com/spatie/laravel-data): extends `Data` | extends a `DataTransferObject` base with `fromArray()` and `toArray()` |
| `mod:view-model` | [spatie/laravel-view-models](https://github.com/spatie/laravel-view-models): extends `ViewModel` | extends a `ViewModel` base |
| `mod:action` | [lorisleiva/laravel-actions](https://github.com/lorisleiva/laravel-actions): `use AsAction;` | a plain class with `handle()` |
| `mod:value` | | a plain class with a constructor |

The command says which it used:

```bash
php artisan mod:dto Knowledge:DocumentData
# ->  INFO  Using spatie/laravel-data (installed).
```

## Generated Base Classes

Without spatie/laravel-data, the first `mod:dto` writes a `DataTransferObject` base into your app:

```bash
php artisan mod:dto Knowledge:DocumentData
```

```text
   INFO  Created base class Domain\Shared\Data\DataTransferObject [src/Domain/Shared/Data/DataTransferObject.php].
   INFO  DTO [src/Domain/Knowledge/Data/DocumentData.php] created successfully.
```

The base is written the first time it is needed, and it is yours from then on: mod never overwrites it, not even with `--force`. To change what it starts as, add `stubs/mod.base.data-transfer-object.stub` or `stubs/mod.base.view-model.stub` to your app.

### Extending Your Own Base Class

To extend a class of your own instead, set it in `config/mod.php`. A configured base wins over an installed package:

```php memo="config/mod.php"
'layouts' => [
    'ddd' => [
        'bases' => [
            'dto' => App\Support\Data::class,
        ],
    ],
],
```

`view-model` and `action` take a base the same way.

### Using the Base in Your Stub

A stub of your own uses `{{ baseImport }}` and `{{ extends }}` for the base mod chose, so one file serves every case:

```php memo="stubs/mod.dto.stub"
<?php

namespace {{ namespace }};
{{ baseImport }}
class {{ class }}{{ extends }}
{
    public function __construct(
        //
    ) {}
}
```
