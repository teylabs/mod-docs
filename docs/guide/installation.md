# Installation

Mod requires PHP 8.3+ and Laravel 12 or 13.

## Installing Mod

Install mod with Composer:

```bash
composer require tey/mod
```

Then publish the configuration file, which is where you choose your layout:

```bash
php artisan vendor:publish --tag=mod-config
# -> config/mod.php
```

Every key in the file is listed in [Configuration](/reference/configuration).

## Choosing a Layout

The published file starts on the `laravel` layout, which places files exactly like `make:*`. Set `layout` to the structure you want:

```php memo="config/mod.php"
'layout' => 'modules',
```

[Layouts](/basics/layouts) compares the six built-in layouts.

## Adding Mod to an Existing App

Mod doesn't move or change existing files, and `make:*` keeps working. Classes already in Laravel's default folders keep working as before. Start on the `laravel` layout and switch when you're ready: files generated from then on go to the new layout's folders.

A layout that writes outside `app/`, such as `ddd`'s `src/Domain`, needs a PSR-4 entry in your `composer.json`. [The DDD Layout](/basics/layouts#the-ddd-layout) shows the entry.
