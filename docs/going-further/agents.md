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

## Rename plans

Inspect `rename` in `mod:list --json` for execution/recovery capabilities, effective recipe sources, required historical answers and declared parts. Preview the exact recipe-owned cluster with `mod:rename Old:Name New:Name --scaffold=<recipe> --dry-run --json`. A blocker sets `would_write` to false while preview exits 0; located `checklist` items remain advisory. Generation and rename share the existing envelope, with additive `selection`, `target`, `moves`, `rewrites`, `retained`, `checklist` and `scan_roots`.

For R14's minimal source-only fixture (no frontend sources), one-member `model-only` recipe and the exact source `<?php\nnamespace App\\Modules\\Inventory\\Models;\nclass Widget {}\n`, this is the complete schema-valid plan:

```bash
php artisan mod:rename Inventory:Widget Inventory:Gadget --scaffold=model-only --dry-run --json
```

```json
{
  "command": "mod:rename",
  "group": "Inventory",
  "name": "Widget",
  "files": [],
  "inserts": [],
  "warnings": [],
  "would_write": true,
  "selection": {
    "scaffold": "model-only",
    "source": "app",
    "answers": {}
  },
  "target": {
    "group": "Inventory",
    "name": "Gadget"
  },
  "moves": [
    {
      "alias": "model",
      "type": "model",
      "from": "app/Modules/Inventory/Models/Widget.php",
      "to": "app/Modules/Inventory/Models/Gadget.php",
      "old_class": "App\\Modules\\Inventory\\Models\\Widget",
      "new_class": "App\\Modules\\Inventory\\Models\\Gadget"
    }
  ],
  "rewrites": [
    {
      "file": "app/Modules/Inventory/Models/Widget.php",
      "after_file": "app/Modules/Inventory/Models/Gadget.php",
      "line": 3,
      "category": "php-declaration",
      "before": "Widget",
      "after": "Gadget"
    }
  ],
  "retained": [],
  "checklist": [],
  "scan_roots": [
    "app",
    "bootstrap",
    "config",
    "resources",
    "routes",
    "tests"
  ]
}
```

The [rename schema](/schemas/rename.json) also describes recovery. Optional new migrations use `files`; rename never replays `inserts`. `selection.answers` is an object, including when empty. Original file/line locations describe rewrites and review items; `after_file` gives the destination.

`mod-plan` enforces preview even if callers supply `--yes` or `--recover`:

```json
{"command":"mod:rename","arguments":["Inventory:Widget","Inventory:Gadget","--scaffold=model-only","--yes"]}
```

```json
{"command":"mod:rename","arguments":["--recover"]}
```

Neither request applies a rename, acquires a recovery lock, writes a journal or restores the index. Ordinary CLI `--json` requires `--dry-run`. There is no saved-plan execution option.

Before applying a rename:

1. Read inventory and the effective recipe source; supply all historical part/question answers.
2. Preview the schema-valid plan and inspect every move, rewrite, retained member, blocker and checklist entry.
3. Resolve blockers with recipe/configuration/flags; leave a clean Git tree and index.
4. Apply through `mod:rename ... --yes --no-interaction`, which computes a fresh plan and stages the result without committing.
5. Review the staged diff and unchanged runtime strings, table/foreign-key/binding risks and manual frontend fixes.
6. Build, type-check and exercise the application's renamed route; fallback alone does not prove working wiring.
7. After interruption, inspect `--recover --dry-run --json`, preserve outside edits, then explicitly recover before retrying a fresh rename.

[Renaming and moving](/going-further/renaming) covers parser capability, refusal, migration and recovery limits. [Building on mod](/going-further/building-on-mod) explains the member-level supported host API; rename engine services remain internal.
