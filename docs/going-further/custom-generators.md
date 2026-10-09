# Custom generators

A generator is a `mod:*` command for one file type. A template file declares what a layout generates. So does `->generates()` in PHP.

## Creating a generator

With the `modules` layout and an existing `Agents` module, create a generator template:

```bash
php artisan mod:template tool
```

```text
   INFO  Template [stubs/mod/@module/Tools/tool.stub] created.

  Starts as .................................................. a class
  Command ................................................... mod:tool
  Writes ....................... app/Modules/<module>/Tools/<Name>.php
  Try ............................. php artisan mod:tool Agents:<Name>
```

## Editing the template

Edit the template to hold your repeating class shape. It starts with namespace, class and base placeholders:

```php memo="stubs/mod/@module/Tools/tool.stub"
<?php

namespace {{ namespace }};
{{ baseImport }}
class {{ class }}{{ extends }}
{
    /**
     * Create a new class instance.
     */
    public function __construct()
    {
        //
    }
}
```

Generate a class from it:

```bash
php artisan mod:tool Agents:SearchDocuments
# -> app/Modules/Agents/Tools/SearchDocuments.php
```

No PHP registration is needed. The filename names the command. `show-document-page.stub`, `ShowDocumentPage.stub` and `show_document_page.stub` all name `mod:show-document-page`; its dash-free alias also accepts `mod:showDocumentPage` and `mod:ShowDocumentPage`. Two templates that normalize to the same command are a configuration error.

## Choosing a starting type

One argument is a name for a class template. With two arguments, the first is the starting type and the second is the name or path:

```bash
php artisan mod:template dto payload
php artisan mod:template interface contract
php artisan mod:template job background-task
```

A bare name also names its folder: `payload` goes in `Payloads/`. Give a path such as `@module/Data/payload` to choose a folder.

Starting types include `class`, `interface`, `trait`, `enum`, [starters](/going-further/stubs#starter-stubs), file types with usable stubs and other accepted templates. With no arguments, the command asks for a starting type and a name.

Native listener, controller, model, factory, policy, test and observer stubs need context and cannot be used directly. Publish a self-contained stub for that file type, or choose `class`. Plain-file templates are not supported.

## Paths and slots

An anchor follows the layout's group folder. `@module`, `@domain`, `@feature` and `@slice` name a level; `@group` is the neutral form for packages. A slot becomes an option and a placeholder:

```bash
php artisan mod:template class '@module/Webhooks/[source]/webhook'
php artisan mod:webhook Agents:FileChanged --source=Drive
# -> app/Modules/Agents/Webhooks/Drive/FileChanged.php
```

Quote shell paths containing a `[slot]`; anchors alone need no quotes. Fill slots through their options, rather than adding them to the group before the colon.

Without an anchor, a path is relative to `app/`, or another layout root when it starts with that root's path. There can be one anchor. A literal prefix before it must match a place where the layout keeps that group. In `slices`, `Feature/Slice:` fills the levels down to `@slice`. In `type-first`, the feature is optional. Built-in modules and features are flat; DDD domains can nest.

### The application layer in DDD

`@domain/Workflows/workflow` belongs to `src/Domain/<domain>/Workflows`. A literal application path puts the template in the other layer:

```bash
php artisan mod:template class Modules/@domain/Presenters/presenter
php artisan mod:presenter Knowledge:ShowDocument
# -> app/Modules/Knowledge/Presenters/ShowDocument.php
```

### Placeholders

| Family | Examples | Filled with |
| --- | --- | --- |
| Group | `{{ module }}`, `{{ domain }}` | the selected group |
| Slot | `{{ source }}` | the value of `--source` |
| Name | `{{ class }}`, `{{ class.camel }}`, `{{ class.plural.kebab }}` | the class name and chained name forms |
| Root | `{{ rootNamespace }}` | the root namespace, as in Laravel's stubs |

Name forms include `studly`, `camel`, `snake`, `kebab`, `plural`, `singular`, `lower`, `upper`, `title` and `headline`. They apply left to right. Namespace and base placeholders are described in [Stubs](/going-further/stubs#starting-from-your-own-stub). Stubs have no loops or conditionals. [Scaffolds](/going-further/scaffolds) also supply sibling aliases and question answers.

## From an existing class

Extract the namespace and declared name from a class you already like, without loading it:

```bash
php artisan mod:template --from=SearchDocuments --into=@module/Tools/search
```

Source forms, from shortest to most explicit:

| Form | Example |
| --- | --- |
| Short name | `--from=SearchDocuments` |
| Namespace suffix | `--from=Tools/SearchDocuments` |
| Slash-separated full name | `--from=App/Modules/Agents/Tools/SearchDocuments` |
| Quoted full name | `--from="App\Modules\Agents\Tools\SearchDocuments"` |
| File path | `--from=app/Modules/Agents/Tools/SearchDocuments.php` |

A short-name search uses the layout's roots and declared PHP names, never `vendor/`. Full names use Composer's file lookup. A bare `--from` opens a search; several matches open a choice. A near miss offers a suggestion.

Without `--into`, the wizard asks for the destination and template name. In a non-interactive run, extraction uses the source-folder suggestion and kebab-case declared name. This is the destination-default exception to the usual missing-answer errors.

Extraction replaces the namespace declaration and name tokens equal to the declared name. Strings, longer names, comments, qualified names and imports remain as they are. The output reports comments and qualified references left untouched. Edit the rest to generalize the template. Source folders such as `Webhooks/Drive` stay literal unless you replace them with a slot.

## The same, in PHP

`stubs/mod/@module/Tools/tool.stub` and this declaration both give you `mod:tool`:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Generation\Stub;

Mod::layout('modules')->generates('tool', in: 'Modules/{module}/Tools',
    stub: Stub::file(base_path('stubs/tool.stub')));
```

Copy the template contents to `stubs/tool.stub` for the PHP form. Either way you get `mod:tool`, with the same namespace and class contents.

PHP also sets `suffix:`, `aliases:`, `fixed:`, discovery rules and base selection. [Layout API](/reference/layout-api#generates) lists the arguments.

### Refining a template

Create `stubs/mod/@module/Data/links.stub` from the DTO starter, then add only a suffix in PHP:

```php memo="app/Providers/AppServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::layout('modules')->generates('links', suffix: 'Links');
```

A `generates()` call without `in:` refines the template instead of replacing its folder. This has the same result as a PHP declaration with `in: 'Modules/{module}/Data'`, `suffix: 'Links'` and `stub: Starters::dto()`.

## When something is off

In a terminal, commands ask when one answer resolves the problem: a missing slot, an existing template, reversed arguments, an unknown starting type or an ambiguous source. A template name already used by a built-in command offers to customize its published stub instead.

With `--no-interaction`, in CI or without a terminal, give the answering option. A missing slot prints:

```bash
php artisan mod:webhook Agents:AnotherChange --no-interaction
```

```text
   ERROR  mod:webhook needs a source. Pass --source=<source>.
```

Use `--force` to answer an overwrite, `--into` for an extraction destination, and slot options such as `--source=Drive`. Configuration errors remain errors. Broken templates are warned about and skipped; inspect the “Templates with problems” section:

```bash
php artisan mod:list
```

## Packages

A package registers its template folder in its provider:

```php memo="src/ToolsServiceProvider.php" at="boot()"
use Tey\Mod\Facades\Mod;

Mod::stubs()->folder(__DIR__.'/../stubs/mod');
```

Use `@group` inside the folder so placement follows the app's layout. The app's templates win over package templates; `mod:list` identifies them as `app (overrides <package>)`. Two packages claiming one command disable that command with a warning naming both; other commands keep working. [Plugins](/going-further/plugins#shipping-generator-templates) covers package registration.
