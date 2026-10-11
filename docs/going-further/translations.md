# Module Translations

With the `modules` layout, each module's `lang/` folder loads automatically, under the same namespace as the module's views. Nothing needs registering or publishing.

## Adding Translations

Create language files using Laravel's package convention:

```php memo="app/Modules/Inventory/lang/en/messages.php"
<?php

return ['saved' => 'Inventory saved.'];
```

Then use them with the module's namespace:

```php
__('inventory::messages.saved'); // Inventory saved.
```

Namespaces follow the same rule as module views: kebab case for each group segment, joined with dots. `AgentTools` uses `agent-tools`; a nested `Knowledge/Search` group uses `knowledge.search`. Groups without a `lang/` folder register nothing.

An existing application or package namespace keeps ownership: a clash logs a warning and skips that module's translations. If two groups produce the same namespace, the first folder in path order wins and the other warns.

## Overriding a Module's Keys

Laravel's own loader handles locales, fallback and overrides. To change selected keys, add `lang/vendor/inventory/en/messages.php` to the application. Keys missing from that file still come from the module.

```php memo="lang/vendor/inventory/en/messages.php"
<?php

return ['saved' => 'Stock saved.'];
```

## JSON Translations

A module can also ship `lang/en.json`. JSON keys use Laravel's global syntax, such as `__('Inventory saved.')`, and have no module namespace. The application's JSON files take precedence. Between modules, a later folder in path order wins a duplicate key, so use distinct phrases when modules need distinct translations.

## Declaring a Different Folder

Use `lang:` on `frontend()` to choose another path, with the same placeholders and anchors as views:

```php
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->frontend(lang: '@module/translations');
```

The other built-in layouts, including `ddd`, declare no language folder. Opt in on the layout you use:

```php
Mod::layout('ddd')->frontend(lang: 'app/Modules/{domain}/lang');
// app/Modules/Knowledge/Search/lang/en/messages.php -> knowledge.search::messages.saved
```

mod creates no language files. It checks only the declared folders and remembers the result for the request.

## Inventory and Caching

`php artisan mod:list --json` includes `frontend.lang` and a `translations` list with each folder's `group`, `namespace` and `path`.

`php artisan mod:cache` (also run by `optimize`) stores the list of translation folders with the discovery cache, and `mod:clear` removes it. After adding a module's `lang/` folder, rebuild or clear the cache. The translations themselves are loaded by Laravel, so restart long-running workers after changing them, as with any language file.
