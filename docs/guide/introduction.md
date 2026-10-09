# Introduction

Mod is a lightweight toolkit for modular development in Laravel. It makes Laravel's own generators and discovery work in the folder structure you choose: a modular monolith, feature folders, vertical slices, domain-driven design, or a layout of your own.

## Organizing an App by Module

A new Laravel app keeps every model in `app/Models`, every listener in `app/Listeners` and every migration in `database/migrations`. As the app grows, many teams group code by module, feature or domain instead, so that each part of the app keeps its models, listeners and migrations together.

That usually means fighting Laravel's defaults. `make:model` still writes to `app/Models`, so each new file is moved by hand. Each module's providers, commands and listeners need registering, its migration folder needs adding to the migrator, and each model needs pointing at its factory.

## Generating Files in Your Structure

Mod gives every file type in your layout a `mod:*` command. It is Laravel's `make:*` command underneath, with the same options, writing into your structure. With the `modules` layout, an app that stores documents can keep them in a `Knowledge` module:

```bash
php artisan mod:model Knowledge:Document -mf
```

```text
app/Modules/Knowledge/
├── Database/
│   ├── Factories/
│   │   └── DocumentFactory.php
│   └── Migrations/
│       └── 2026_10_08_120000_create_documents_table.php
└── Models/
    └── Document.php
```

`php artisan migrate` runs that migration, and `Document::factory()` finds that factory, with nothing registered by hand.

## Discovery Without Registration

Providers, Artisan commands and event listeners are registered wherever your layout puts them. A listener generated into a module is listening straight away:

```bash
php artisan mod:event Knowledge:DocumentUploaded
php artisan mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded
php artisan event:list --event=DocumentUploaded
```

```text
  App\Modules\Knowledge\Events\DocumentUploaded ..
  ⇂ App\Modules\Knowledge\Listeners\GenerateEmbeddings@handle
```

## How Mod Fits Laravel

- **`make:*` is untouched.** It keeps writing to Laravel's default folders. Mod adds `mod:*` beside it.
- **The generated code is Laravel's.** Each `mod:*` command runs the matching `make:*` command, so a model, listener or migration is what Laravel would write, in a different folder and namespace.
- **A module is a folder.** There is no per-module `composer.json`, manifest or Composer plugin. Classes autoload through your app's own PSR-4 entries.
- **You can start where you are.** The default layout, `laravel`, places files exactly like `make:*`, so you can install mod in an existing app and switch layouts when you're ready.

[Custom generators](/going-further/custom-generators) turn a repeating class shape into a command; [scaffolds](/going-further/scaffolds) generate a recipe of several file types together.

Six [layouts](/basics/layouts) are built in, and you can extend any of them or [define your own](/going-further/custom-layouts).

---

Created by [Jasper Tey](https://github.com/jaspertey), building on the lessons from [laravel-ddd](https://github.com/teylabs/laravel-ddd) and generalized for the many different ways developers organize their growing Laravel applications.
