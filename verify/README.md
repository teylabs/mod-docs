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
| `generating-files` | `basics/generating-files.md` | Commands, placement, related files, notices and existing-file handling |
| `auto-discovery` | `basics/auto-discovery.md` | Listeners, subscribers, commands, migrations, factory/policy lookup, exclusions and caching |
| `custom-generators` | `going-further/custom-generators.md` | E2/E3 creation and PHP equivalence, E8 quoted slots, extraction, DDD prefixes and package folders |
| `scaffolds` | `going-further/scaffolds.md` | S1 CRUD, aliases, variants, inclusion, classes, S7 overrides, S14 trees, S17 growth, S19 routes, S20 overrides and S21 recursion |
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
