# Frontend Files

Generate Inertia pages, Blade views and frontend files beside their module’s PHP classes. Page identities and imports follow the active layout.

## Generating a Page

```bash
php artisan mod:page Inventory:Widget/Index
# -> app/Modules/Inventory/resources/js/pages/Widget/Index.vue
```

In a Vue app, render the page as `Inventory::Widget/Index`. In a React app, the same command writes `widget/index.tsx` and its identity is `Inventory::widget/index`. The default page imports `Head`. An app with no Inertia dependency in `package.json` has no page file type.

## Generator Templates

A generator template’s filename sets its command and extension. Put this template in `stubs/mod/@module/resources/js/components/card.vue.stub`:

```vue memo="stubs/mod/@module/resources/views/components/card.blade.php.stub"
@props(['title'])

<div {{ $attributes->class('rounded border p-4') }}>
    <h3>{{ $title }}</h3>
    {{ $slot }}
</div>
```

Vue files use StudlyCase; React, Blade, Markdown and CSS use kebab-case. JavaScript and TypeScript retain the typed name. Custom file types can set `case:`. An app’s `stubs/mod.page.vue.stub` or `.tsx.stub` replaces the minimal page. Quote template paths containing `[slot]`.

### Markdown Templates

Plain templates can also generate prompts. Save this template at `stubs/mod/@module/resources/prompts/prompt.md.stub`:

```markdown memo="stubs/mod/@module/resources/prompts/prompt.md.stub"
# {{ name.headline }}

You are the {{ module }} assistant. Answer using only the documents provided.
```

`mod:prompt Agents:AnswerQuestion` writes `resources/prompts/answer-question.md` inside the Agents module.

## Placeholders

Only known placeholder names are replaced. Unknown Vue and Blade expressions pass through. Use explicit name forms for known names; ambiguous bare forms produce a warning with the template and line. `@{{ name }}` emits literal `{{ name }}`.

```vue memo="stubs/mod/@module/resources/js/components/badge.vue.stub"
<template>
    <span>{{ name }}</span>
    <span>@{{ name.kebab }}</span>
    <span>{{ count }}</span>
</template>
```

Lists support `.json` and `.array`; `.headline` formats a value for prose. Artifact aliases expose `.name` (framework identity), `.import`, `.tag` and `.path`. Imports under the group root use `@modules/`; files below `resources/js/` use `@/`. An alias import never traverses its root with `../`.

## Generating Pages with Their Controller

This recipe adds four pages and replaces the controller in the [CRUD scaffold](/going-further/scaffolds#generating-a-recipe). Register it after that scaffold in `AppServiceProvider::boot()`:

```php memo="app/Providers/AppServiceProvider.php"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffold('crud-pages', fn (Scaffold $s) => $s
    ->include('crud')
    ->makes('page', name: '{name}/Index', as: 'indexPage', stub: 'crud-index')
    ->makes('page', name: '{name}/Create', as: 'createPage', stub: 'crud-form')
    ->makes('page', name: '{name}/Edit', as: 'editPage', stub: 'crud-form')
    ->makes('page', name: '{name}/Show', as: 'showPage', stub: 'crud-show')
    ->makes('controller', name: '{name}Controller', stub: 'inertia-crud'));
```

Create the templates below, then generate the twelve files:

```bash
php artisan mod:crud-pages Inventory:Widget --no-interaction
# -> app/Modules/Inventory/Http/Controllers/WidgetController.php
```

The four pages sit in the same plan as the model, migration, factory, requests, resource, policy and controller. `{{ indexPage.name }}` supplies the controller’s Inertia identity for either stack.

### The Controller Template

Save this complete generator template as `stubs/mod.controller.inertia-crud.stub`:

```php memo="stubs/mod.controller.inertia-crud.stub"
<?php

namespace {{ namespace }};

use {{ resource.fqcn }};
use {{ model.fqcn }};
use Inertia\Inertia;

class {{ class }}
{
    public function index()
    {
        return Inertia::render('{{ indexPage.name }}', [
            '{{ name.plural.camel }}' => {{ resource }}::collection({{ model }}::paginate()),
        ]);
    }

    public function edit({{ model }} ${{ model.camel }})
    {
        return Inertia::render('{{ editPage.name }}', [
            '{{ model.camel }}' => new {{ resource }}(${{ model.camel }}),
        ]);
    }
}
```

### The Vue Index Template

Save this variant in a Vue app:

```vue memo="stubs/mod.page.crud-index.vue.stub"
<script setup lang="ts">
import { Head } from '@inertiajs/vue3';

defineProps<{
    {{ name.plural.camel }}: { data: Array<{ id: number }> };
}>();
</script>

<template>
    <Head title="{{ name.plural }}" />
    <ul>
        <li v-for="{{ name.camel }} in {{ name.plural.camel }}.data" :key="{{ name.camel }}.id">{{ {{ name.camel }}.id }}</li>
    </ul>
</template>
```

### The React Index Template

Save this variant in a React app:

```tsx memo="stubs/mod.page.crud-index.tsx.stub"
import { Head } from '@inertiajs/react';

type Props = { {{ name.plural.camel }}: { data: Array<{ id: number }> } };

export default function Index({ {{ name.plural.camel }} }: Props) {
    return <>
        <Head title="{{ name.plural }}" />
        <ul>{ {{ name.plural.camel }}.data.map(({{ name.camel }}) => <li key={ {{ name.camel }}.id }>{ {{ name.camel }}.id }</li>)}</ul>
    </>;
}
```

### The Remaining Pages

For each of `crud-form` and `crud-show`, save the matching variant below. These minimal pages provide a starting point for your form and detail screen:

```vue memo="stubs/mod.page.crud-form.vue.stub"
<template><p>{{ name.studly }}</p></template>
```

```tsx memo="stubs/mod.page.crud-form.tsx.stub"
export default function {{ name.studly }}() { return <p>{{ name.studly }}</p>; }
```

### Loading the Widgets Route

After generating the files, add this route to `routes/web.php` and run `php artisan migrate`:

```php memo="routes/web.php"
<?php

use App\Modules\Inventory\Http\Controllers\WidgetController;
use Illuminate\Support\Facades\Route;

Route::get('/widgets', [WidgetController::class, 'index']);
```

`GET /widgets` returns the generated index page with its paginated resource data. To keep routes beside the module, use [module routes](/going-further/routes).

## Pages in Scaffold Trees

A page member can accompany each repeated tab. The same aliases supply framework identities, imports and anchored inserts.

```php memo="app/Providers/AppServiceProvider.php"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Part;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffold('tab-page', fn (Scaffold $s) => $s
    ->asks('base', type: 'class')
    ->asks('layout', type: 'file')
    ->asks('tab', type: 'text')
    ->makes('view-model', name: '{name}{tab}ViewModel', as: 'page', stub: 'tab-page')
    ->makes('page', name: '{name}/{tab}', as: 'view', stub: 'tab-page'));

Mod::scaffold('resource-tabs', fn (Scaffold $s) => $s
    ->asks('model', type: 'model', default: '{name}')
    ->asks('tabs', type: 'list', default: ['Overview', 'Details', 'Notes'])
    ->makes('view-model', name: 'Manage{name}ViewModel', as: 'base', stub: 'tabs-layout')
    ->makes('tabs-layout', name: '{name}Layout', as: 'layout')
    ->makes('controller', name: '{name}Controller', stub: 'tabs')
    ->part('tab', uses: 'tab-page', with: ['base' => '{{ base.fqcn }}', 'layout' => '{{ layout.path }}'], configure: fn (Part $p) => $p
        ->inserts(into: 'base', at: 'tabs', stub: 'tabs-entry')
        ->inserts(into: 'controller', at: 'actions', stub: 'tabs-action'))
    ->each('tabs', part: 'tab'));
```

Create the recipe’s variants and insert templates before running it. A `file` question accepts an existing frontend path or a planned plain artifact and exposes its identity forms. Child commands can add a tab later; see [scaffold trees](/going-further/scaffolds#parts-scaffolds-inside-scaffolds).

### Frontend Tree Templates

Use the PHP view-model variants and entry insert from [Templates for the Tree](/going-further/scaffolds#templates-for-the-tree). Add these frontend variants:

```vue memo="stubs/mod/@module/resources/js/components/tabs-layout.vue.stub"
<script setup lang="ts">
import { Link, usePage } from '@inertiajs/vue3';

defineProps<{ title: string }>();

const page = usePage<{ layout: { tabs: Array<{ label: string; href: string; active: boolean }> } }>();
</script>

<template>
    <nav>
        <Link v-for="item in page.props.layout.tabs" :key="item.href" :href="item.href" :class="{ active: item.active }">{{ item.label }}</Link>
    </nav>
    <h1>{{ title }}</h1>
    <slot />
</template>
```

```vue memo="stubs/mod.page.tab-page.vue.stub"
<script setup lang="ts">
import {{ layout }} from '{{ layout.import }}';
</script>

<template>
    <{{ layout }} title="{{ tab }}">
        <!-- {{ tab }} -->
    </{{ layout }}>
</template>
```

```php memo="stubs/mod.insert.tabs-action.stub"
    public function {{ tab.camel }}({{ model }} ${{ model.camel }})
    {
        return Inertia::render('{{ tab.view.name }}', new \{{ tab.page.fqcn }}(${{ model.camel }}));
    }

```

### Artifact Identities

| Form | Example | Used By |
| --- | --- | --- |
| `{{ indexPage.name }}` | `Inventory::Widget/Index` | Inertia rendering |
| `{{ layout.import }}` | `@modules/Inventory/resources/js/components/WidgetLayout.vue` | JavaScript imports |
| `{{ layout }}` | `WidgetLayout` | Component tags |
| `{{ mail.view.name }}` | `inventory::mail.widget-restocked` | Blade views and mail |
| `{{ badge.tag }}` | `x-inventory::stock-badge` | Anonymous Blade tags |
| `{{ card.path }}` | `app/Modules/Inventory/resources/js/components/LowStockCard.vue` | Project-relative files |

A `file` question supplies the same forms from its selected artifact. Moving a frontend root changes the forms with it.

## Dashboard Widgets

Repeated dashboard parts can write a metric class and card while inserting their registration into the parent. The part’s question value names the child; `{name}` stays the cluster name.

```php memo="app/Providers/AppServiceProvider.php"
use Tey\Mod\Facades\Mod;
use Tey\Mod\Scaffolds\Part;
use Tey\Mod\Scaffolds\Scaffold;

Mod::scaffold('metric', fn (Scaffold $s) => $s
    ->makes('class', name: 'Metrics/{widget}Metric', as: 'metric', stub: 'metric')
    ->makes('metric-card', name: '{widget}Card', as: 'card'));

Mod::scaffold('dashboard', fn (Scaffold $s) => $s
    ->makes('view-model', name: '{name}DashboardViewModel', as: 'dashboard', stub: 'dashboard')
    ->makes('page', name: '{name}/Dashboard', as: 'view', stub: 'dashboard')
    ->part('widget', uses: 'metric', configure: fn (Part $p) => $p
        ->inserts(into: 'dashboard', at: 'widgets', stub: 'dashboard-metric')
        ->inserts(into: 'view', at: 'card-imports', stub: 'dashboard-card-import')
        ->inserts(into: 'view', at: 'widgets', stub: 'dashboard-card')));
```

Registration comes from the recipe’s anchored inserts. There is no folder-scanning widget registry.

## Stack Variants

Use an extension-specific variant for each stack:

```text
stubs/mod.page.crud-index.vue.stub
stubs/mod.page.crud-index.tsx.stub
stubs/mod.page.crud-form.vue.stub
stubs/mod.page.crud-form.tsx.stub
```

When a variant is missing, a terminal offers to create its minimal source. A non-interactive run exits with the filename to supply. Vue pages omit `lang="ts"` without `tsconfig.json`; React uses `.jsx` without it.

## Copying a Frontend File

```bash
php artisan mod:template --from=app/Modules/Inventory/resources/js/pages/Widget/Index.vue --into=@module/resources/js/pages/list-page
# -> stubs/mod/@module/resources/js/pages/list-page.vue.stub
```

The source bytes are copied unchanged. The output identifies name and group mentions to generalize manually. `--dry-run --json` includes `mentions` without writing.

## Views and Blade Components

```bash
php artisan mod:view Inventory:widgets.show
# -> app/Modules/Inventory/resources/views/widgets/show.blade.php
php artisan mod:component Inventory:StockBadge --view
# -> app/Modules/Inventory/resources/views/components/stock-badge.blade.php
```

Use `view('inventory::widgets.show')` and `<x-inventory::stock-badge />`. Without `--view`, the component command creates a class and view; `--inline` creates an inline class component. Grouped mail and notification commands qualify their companion views too.

Namespaces register after providers boot. Generate a folder, then boot the app again to use it. Reserved or existing namespaces are skipped with a warning. Type-first grouped views use `resources/views/inventory`; ungrouped app views have no namespace.

## Installing for Inertia

```bash
php artisan mod:install inertia --dry-run --json
php artisan mod:install inertia --no-interaction
php artisan mod:list --json
```

The installer previews edits to the app entry, Vite, TypeScript and Tailwind configuration. It imports the resolver from `vendor/tey/mod/resources/js/inertia`; no npm package is required. A second run prints `Already wired.`

The resolver uses literal app and module glob maps. Missing or ambiguous pages throw an error; module names never fall back to app pages. Mirrored pages already matched by the app glob keep the existing resolver. Custom resolvers and unrecognized configuration receive manual instructions without edits.

For manual wiring, add the reported `@modules` root to Vite and TypeScript paths, include module scripts in TypeScript, append module views to Vite refresh paths, and include the module resources in Tailwind scanning. Inspect `frontend.import_alias` for the intended mapping and `wiring.inertia`, `wiring.vite_alias`, and `wiring.tailwind` for detected configuration. [Commands](/reference/commands#installing-inertia) lists installer options.

## Checking Generated Frontend Code

The docs harness creates Vue and React starter-kit apps for Laravel 12 and 13. It runs this recipe, builds with Vite, checks Vue/React types, and requests `/widgets` through Laravel’s HTTP kernel. Run it from the docs repository:

```bash
verify/setup.sh /tmp/mod-docs-verify /path/to/mod 12 13
verify/run.sh /tmp/mod-docs-verify 12 13 -- frontend
```
