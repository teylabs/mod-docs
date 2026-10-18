# Verifying the docs

The harness runs the docs examples in disposable Laravel 12 and 13 applications. It checks generated files and PHP syntax, output, class loading, discovery, and copying modules between apps. PHP 8.4, Composer, Git, rsync, Perl and zsh must be on your machine.

From the repository root:

```bash
verify/setup.sh /tmp/mod-docs-verify /path/to/mod 12 13
verify/run.sh /tmp/mod-docs-verify 12 13
```

On Herd, choose PHP explicitly:

```bash
export PHP='/Users/jasper/Library/Application Support/Herd/bin/php84'
```

`COMPOSER_BIN` defaults to the Composer executable on PATH. To check a release or branch instead of a local checkout:

```bash
verify/setup.sh /tmp/mod-docs-verify git:v0.1.1 12 13
verify/run.sh /tmp/mod-docs-verify 12 13
```

A Git source is fetched from `teylabs/mod` and installed through a Composer path repository with copying enabled. `mod-ref.txt` records the resolved commit. A local source is copied too; changes made after setup require setup again. Neither mode edits the source checkout.

Use a branch, tag, or full 40-character commit SHA after `git:`. Abbreviated hexadecimal IDs are rejected with full-SHA guidance, even when they are unique in your local checkout: a shallow remote fetch cannot establish their uniqueness. Obtain the full SHA with `git rev-parse --verify '<ref>^{commit}'` in your Mod checkout. For a branch or tag whose name is entirely hexadecimal, use `git:refs/heads/<name>` or `git:refs/tags/<name>` explicitly. Empty refs, options and revision expressions are not accepted.

The focused setup regression uses Python 3, Git, PHP and rsync. It creates a disposable local Git fixture and stops at the Composer installation boundary; it makes no network requests or application installations:

```bash
python3 verify/test-setup.py
```

Setup replaces its own `mod-src` and selected `base-<version>` directories. Scenarios reset these disposable apps and can replace `copy-<version>` directories. Use a dedicated work directory. The harness refuses to reset apps in an unmarked work directory.

Run selected pages with `--`:

```bash
verify/run.sh /tmp/mod-docs-verify 13 -- layouts stubs
```

Each check prints `PASS | L13 layouts | <what it proves>` or `FAIL | ...`. The final line counts passed and failed checks; any failure makes the command exit 1. Results go to `<workdir>/verify.txt`. Failure diagnostics print after their check, and the last check's captured output remains in `check-output.txt`.

| Scenario | Page | Coverage |
| --- | --- | --- |
| `quick-start` | `guide/quick-start.md` | The five steps, model/factory/migration, output and listener registration |
| `layouts` | `basics/layouts.md` | Six layouts, related-file trees, slices, aliases and DDD autoloading |
| `mcp` | `basics/generating-files.md`, `reference/commands.md` | Optional Laravel MCP generators, module/nested DDD placement, native byte parity and excluded companion views |
| `generating-files` | `basics/generating-files.md` | Commands, placement, related files, notices and existing-file handling |
| `auto-discovery` | `basics/auto-discovery.md` | Listeners, subscribers, commands, migrations, factory/policy lookup, exclusions and caching |
| `custom-generators` | `going-further/custom-generators.md` | E2/E3 creation and PHP equivalence, E8 quoted slots, extraction, DDD prefixes and package folders |
| `scaffolds` | `going-further/scaffolds.md` | S1 CRUD, aliases, variants, inclusion, classes, S7 overrides, S14 trees, S17 growth, S19 routes, S20 overrides and S21 recursion |
| `from-laravel-ddd` | `guide/from-laravel-ddd.md` | Existing Domain classes with DDD, custom modules and shared UI roots, provider discovery and cached boot |
| `upgrade` | `guide/upgrade.md` | The migrated 0.1 declaration, relation arguments and group token |
| `introduction` | `guide/introduction.md` | Model tree and listener discovery output |
| `commands` | `reference/commands.md` | Inventory forms/JSON keys, templates, autoloading, missing-command output and bases |
| `layout-api` | `reference/layout-api.md` | Public method/class availability, finite registry reads and namespace lookup |
| `configuration` | `reference/configuration.md` | Published config and the renamed discovery map |
| `custom-layouts` | `going-further/custom-layouts.md` | New file types, moved folders, roots, relations, path tokens, inheritance, moved namespaces and infrastructure layers |
| `stubs` | `going-further/stubs.md` | App overrides, starters, generated bases and configured bases |
| `self-contained-modules` | `going-further/self-contained-modules.md` | Two-module trees, routes, shared bases, and migration/listener/factory/policy behaviour after copying |
| `plugins` | `going-further/plugins.md` | Command aliases and labels, plugin/app stub precedence, generated bases, installed-package variants, generator hooks and supplied discovery candidates |

Scenarios keep their fixture setup explicit. `lib.sh` contains the shared Artisan, assertion, reset, provider, autoload and docs helpers. `docs.php` selects fenced examples by heading, language and index. Commands run through `zsh_art`, preserving the quotes in the page, so unquoted bracket paths trigger zsh's usual glob error. A quoted bracket redirection in `layouts.sh` guards this behaviour before pages add bracket-path commands.

Output comparisons normalize whitespace, migration timestamps, dot leaders and elapsed times. They retain message text, class names and paths. Documented tree comparisons exclude tracked Laravel baseline files and normalize migration timestamps. Hand-written checks cover behaviour requiring fixtures beyond a page's code blocks, such as disabling discovery and copying modules. Interactive prompt drawings are descriptive; the harness checks the documented noninteractive behaviour.

To extend coverage, add a plainly worded `check` to the page's scenario. Use `fresh` before an independent fixture. Use `doc_boot`, `doc_config` or `doc_file` to apply a page's PHP example, and `doc_shell`, `doc_output` or `doc_tree` to check its shell commands, displayed output or file tree. A new scenario must also be added to `run.sh`'s default list and name validation. Keep bracket-path quotes in the shell text passed to `zsh_art`; passing pre-split arguments would hide quoting errors.

For a negative check, temporarily change a displayed output line in a covered example and run its scenario: it must exit 1 and name the missing output. Remove the quotes around `commands[slot].txt` in the layouts shell check and run `layouts`: it must fail with zsh's `no matches found`. Restore both changes before committing.

GitHub Actions runs PHP 8.4 with Laravel 12 and 13 for pushes and pull requests targeting main, every Monday at 06:00 UTC, and manual dispatch. It verifies against the latest teylabs/mod release tag, since the docs describe the released package; dispatch with `mod_ref` (for example `main`) to check unreleased work. It caches Composer downloads and uploads `verify.txt` with the resolved mod commit.

## 0.2 evidence

Run unreleased pages against `git:main`, and record the SHA in `mod-ref.txt`. Keep these pages on the docs branch until release review; public main describes the released package.

New examples trace to mod's acceptance tests under `tests/Feature/Acceptance/Examples/`: E1–E16 and M1–M16 for templates and creation; S1–S12 for scaffolds; S13–S22 for questions, parts, inserts, growth and recursion. Recipe and template bodies come from those tests' fixtures. Page scenarios read the fenced examples directly, run quoted paths through zsh, compare displayed output, lint generated PHP and load the tree classes in fresh PHP processes. Interactive questions are covered by the package's acceptance tests; these scenarios use explicit non-interactive answers.

The 0.1 “Before” snippet on the Upgrade page is historical input, not executable 0.2 code. Its “After” snippet is executed against main.

## Frontend and Agent Verification

The default run includes `frontend`, `routes` and `agents`. The frontend scenario needs Node 24 and npm, and creates four disposable starter-kit apps: Vue and React on Laravel 12 and 13. Each app runs `mod:install inertia`, the documented CRUD/page recipe, migrations, `npm run build`, and `npx vue-tsc --noEmit` or `npx tsc --noEmit`. A request through Laravel's HTTP kernel checks status 200 and the exact Inertia component, including React's kebab casing. Resolver checks execute the shipped JavaScript for lazy/eager maps, app/module pages, uppercase `Pages`, normalized custom maps, missing/ambiguous files, invalid names and no fallback.

`frontend/setup.sh` pins the four upstream revisions recorded by the package's installer acceptance fixtures. `kit-refs.txt` records them. Kits with an upstream npm lock use `npm ci`; current kits without one use `npm install`. The app's generated lock records that dependency resolution. PHP is added to PATH so Vite's Wayfinder subprocess uses the configured PHP installation.

Two guarded input corrections are applied in disposable kits by `frontend/prepare-kit.php`: the Laravel 12 Vue kit's validation error is a flat `errors.code`, and the Laravel 13 kits' Wayfinder `Method` union includes Laravel's `query` verb. The Vue correction runs during setup; the Wayfinder correction runs after the build regenerates its upstream helper. They do not change Mod's resolver, generated pages, compiler settings or type-check assertions. Unexpected upstream expressions stop setup. Full-app type checking remains enabled.

Unreleased 0.3 docs must be verified against the matching package branch or SHA, rather than the latest 0.2 release. Use the existing workflow dispatch `mod_ref` input for that evidence; the release-default workflow policy remains unchanged. Node checks belong in this docs workflow, never in Mod's PHP matrix.

`npm test` checks Markdown publication and sidebar coverage contracts. `npm run build` checks links and emits `llms.txt` plus unchanged Markdown sources at sidebar page paths. The JSON schemas served under `/schemas/` are byte-compared with the package fixtures by the agents scenario.

## Page shape acceptance (0.7)

The Frontend Files walkthrough is unreleased. Verify it with Node 24 against mod main:

```bash
verify/setup.sh /tmp/mod-docs-page-shape git:main 12 13
verify/run.sh /tmp/mod-docs-page-shape 12 13 -- frontend
```

The frontend scenario adds eight cases: Vue and React, Laravel 12 and 13, each with and without the optional modal. It copies each real starter app into a separate disposable page-shape app, extracts the page's recipe, templates and commands, and verifies the exact generated tree and conditional controller block. It grows History without rewriting existing pages, checks `pageEntry()` accepts an entry and refuses Layout and Partials, then commits the fixture and runs the documented rename preview and apply commands. The assertions require one owned folder move, unchanged hand-written Partials bytes, rewritten controller and route render literals, and Vite manifest entries that exclude helpers.

Each case builds with `npm run build`, type-checks the full app with `vue-tsc` or `tsc`, and makes direct and Inertia HTTP kernel requests for the exact renamed components. Vite compiles the real components and glob maps for a Vue or React server render of History in the Edit layout. Index/Create and a different owner are negative controls for the nearest-folder lookup. No browser or modal presentation package is used. These apps explicitly install the same supported Babel parser fixture as the rename scenario; the existing guarded upstream kit corrections remain unchanged.

The short-lived SSR compiler uses middleware mode with HMR, file watching and browser dependency optimization disabled; it never opens a listener. It sets Laravel Vite's explicit environment override only in that Node process, so the compiler can run under `CI=true`. It closes Vite and removes its temporary module afterwards. Production builds and HTTP requests still use the real built assets without that override.

The normal workflow still verifies the latest release. Before 0.7, its frontend log explicitly skips this new walkthrough because `Scaffold::folder()` is unavailable; a dispatch against `main` fails rather than skipping if that API is missing. Dispatch `verify.yml` on `docs/07` with `mod_ref=main` for acceptance evidence, and keep the PR a draft until 0.7 ships. Record `mod-ref.txt` and the PASS/FAIL tail in the PR. CI preserves each `page-shape-*-preview.json` alongside the verification results.

The additive 0.7 plan, inventory and rename schemas live under `/schemas/0.7/`; the released `/schemas/` files stay intact. The agents scenario selects the 0.7 schemas when folder members are available and still byte-compares every contract with the installed package's fixtures.

## Rename and host API verification

The default run adds `rename` and `building-on-mod`. Run 0.4 examples against the integrated package SHA, not the latest 0.3 release:

```bash
verify/setup.sh /tmp/mod-docs-rename git:<exact-mod-sha> 12 13
verify/run.sh /tmp/mod-docs-rename 12 13
```

The rename scenario reuses each frontend kit prepared by `frontend`. With both selected, frontend defers its build/type-check/request to rename's final state: one build per distinct layout per kit. Independently selected frontend retains its existing build gates. To run only Node/application checks, select `-- frontend rename`. Use one harness run per work directory; its log/capture paths are shared.

Fixture setup explicitly installs Babel 7.29.9 in the disposable application. This is application-owned capability setup; the rename helper never installs anything. Current unpinned React kits may resolve Babel 8, and the Laravel 12 Vue lock pins Babel 7.28; these series are outside the helper's supported range and correctly fall back. Vue compiler-sfc must be in 3.5.x. `versions.cjs` prints each actual parser, compiler and build-tool version into the run transcript. Kit refs and `mod-ref.txt` pin the framework/installed package inputs.

The rename fixture changes the generation-only CRUD recipe to explicit model/factory members and declares both source/destination groups with existing model files. It commits a full cluster, adds canonical imports and an unmoved relative neighbour, then asserts schema-valid previews, exact staged path manifests, actual rewritten references and historical bytes. A fixed acceptance clock pins the exact reversible migration; its test writer throws if called. Schema assertions require widgets to remain present and gadgets absent after selected migration generation.

Parsed R1/R2 flows exercise `@modules` and moved neighbours. A separate no-parser fixture hides the ignored dependency directory, checks located fallback and byte preservation, restores dependencies and deliberately applies the reported static import fixes. Subsequent moves, mirrored `@` roots, final builds/type checks and exact Inertia HTTP identities verify that repaired wiring. Unfixed fallback has no runtime correctness claim. The final Vite manifest must contain the renamed page. Vue and React casing remain distinct.

One real subprocess termination/recovery runs per Laravel major in Vue: a TCP checkpoint kills the installed transaction after a durable operation, read-only inspection leaves bytes/index intact, and recovery restores the original raw index while preserving an outside file. Checkpoint waits inspect retained output with deadlines, never fixed sleeps. The package's PHP matrix retains exhaustive fault coverage; Windows runs the six representative R15 boundaries documented by the package owner. The docs harness does not duplicate that matrix.

The helper's actual Node test suite is run from a temporary copy with its helper import redirected to `vendor/tey/mod`; parser/compiler dependencies resolve from the fixture app. No absolute source helper shortcut is used. Host-page fenced PHP executes isolated layout placement/lookup, read-only cache fallback and targeted idempotent host service defaults. Agent fixtures install optional Boost explicitly, compare the complete documented R14 JSON, and call real `mod-plan` rename/recovery requests with an executor binding that throws if resolved. Schemas are byte-compared with package fixtures.

Build/type-check/HTTP transcripts and exact rename JSON are CI artifacts. Desktop 1440px and mobile 390px runtime screenshots are captured separately and must be opened for review. Application render checks prove minimal fixture wiring, not a production deployment. The docs workflow's 25-minute deadline includes setup and all scenarios; it adds no Node requirement to the package's PHP workflow.

Each kit builds and type-checks the module-owned state and mirrored app-page state separately. This proves both alias arrangements through actual builds/HTTP, while avoiding a third unchanged baseline build.

## 0.5 evidence

The 0.5 draft stack pins `verify/mod-ref.txt` to the integrated package commit for module anchors, Inertia page registration, page entries and custom-bootstrap instructions. The new Inertia features are labelled “since 0.5 (unreleased)” in the pages; the module anchor form was already supported. The draft branches use that pin in CI; main retains the latest-release default. The persisted-identity page is deployment guidance, not an automatic database rewrite.

The `from-laravel-ddd` scenario executes both destination declarations in fresh apps, including an existing Domain class. It does not replace end-to-end adoption of the published guide in a real application, or verify that application’s persisted identities and queue cutover.

The third 0.5 draft layer advances the pin to `f64f5c18f2e2a0388e8fc41f5cc4eb4dd19c8669` for native Laravel MCP generators. The `mcp` scenario installs `laravel/mcp` explicitly in disposable fixtures and compares all four generated classes with native output, allowing only the namespace placement change. Run it after scenarios that use the package-free baseline.
