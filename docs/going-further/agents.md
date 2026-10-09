# Agents

Inspect the application’s layout and preview its generated files before applying a command. The same inventory and plans are available through Artisan and optional Laravel Boost tools.

## Reading the Inventory

```bash
php artisan mod:list --json
```

Read the active layout, file types, templates, scaffolds and discovery. Frontend apps also report their stack, frontend paths, views, route entrypoints and wiring. Generator sources distinguish the module, app and package. The [inventory schema](/schemas/inventory.json) pins required keys and permits additive fields.

`frontend.import_alias` describes the intended alias/root mapping. `wiring.vite_alias` reports whether that mapping is configured. Files below `resources/js/` use the app’s `@/` alias; module files use `@modules/` relative to the reported root.

## Previewing Writes

After registering the [frontend recipe](/going-further/frontend#generating-pages-with-their-controller), preview its complete file plan:

```bash
php artisan mod:crud-pages Inventory:Widget --dry-run --json
```

The [plan schema](/schemas/plan.json) describes `command`, `group`, `name`, `files`, `inserts`, `warnings` and `would_write`. Each file includes its path, class or artifact identity, resolved group, `exists`, and `existing` policy. An explicit `existing: "keep"` policy retains the file even with `--force`.

Warnings include a message and nullable file/line locations. A missing answer sets `would_write` to false, while the preview exits 0. Supply the required flag and preview again. Informational warnings can coexist with a writable plan. Read both warnings and the flag.

Use `--dry-run` alone for the same plan as a text table. Plans do not write files or run Composer. Preview again when the app changes.

## Using Laravel Boost

With Boost installed, select Mod’s guideline and `mod-development` skill during `php artisan boost:install`. Run `php artisan boost:update` after updating Mod. The package adds two read-only tools to the existing Boost server; no extra server is needed.

| Tool | Input | Result |
| --- | --- | --- |
| `mod-inventory` | None | The same inventory as `mod:list --json` |
| `mod-plan` | Registered `command` and string `arguments` | The command’s JSON dry-run plan |

After creating the resource-tabs recipe and parent cluster, request a child plan:

```json
{"command":"mod:resource-tabs.tab","arguments":["Inventory:Widget","History"]}
```

Arguments are positional values and option tokens, not a shell command. `mod-plan` enforces `--dry-run --json` and non-interactivity. Missing answers appear as warnings. Commands without preview support, including cache maintenance, return tool errors. Neither tool applies changes.

## Applying a Reviewed Plan

```bash
php artisan mod:crud-pages Inventory:Widget --no-interaction
```

Use the same command and answers that produced the reviewed plan. Choose supported collision flags explicitly. After generation, inspect the files and run the app’s checks.

## Reading Markdown Docs

Start at [llms.txt](/llms.txt). It lists every sidebar page at its Markdown URL, such as [Frontend Files](/going-further/frontend.md). The index and Markdown files are generated from the sidebar and source pages during the docs build.
