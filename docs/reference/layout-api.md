# Layout API

Every method of the `Mod` facade, the layout chain, stubs and generator commands. [Custom Layouts](/going-further/custom-layouts) and [Plugins](/going-further/plugins) show them in use.

## The Mod facade

`Tey\Mod\Facades\Mod`, called from a service provider's `boot()`:

| Method | Returns | Does |
| --- | --- | --- |
| `Mod::layout(string $name)` | `Layout` | Defines a layout, or customizes an existing one |
| `Mod::hasLayout(string $name)` | `bool` | Whether a layout of that name is built in or defined |
| `Mod::layouts()` | `list<string>` | The names of every built-in and defined layout |
| `Mod::current()` | `CompiledLayout` | The active layout, compiled: see [The Compiled Layout](#the-compiled-layout) |
| `Mod::discoverUsing(Closure $candidates)` | | Supplies the files discovery considers: see [Supplying Discovery Candidates](/going-further/plugins#supplying-discovery-candidates) |
| `Mod::stubs()` | `StubRegistry` | The stubs registered for file types: [`for()`](#registering-stubs) |
| `Mod::scaffold(string $name, Closure $recipe)` | `ModManager` | Registers a global recipe or dot-path part override |
| `Mod::scaffolds(array $recipes)` | `ModManager` | Registers named closures or invokable recipe classes with a string `$name` |
| `Mod::generators()` | `GeneratorRegistry` | The commands behind file types: [`use()`](#swapping-generators) |

## Layout methods

`Tey\Mod\Layout\Layout`. Every method returns the layout, so the calls chain:

| Method | Does |
| --- | --- |
| `mounts($name, $namespace, $path, $closure = null)` | Maps a namespace to a folder. File types declared in the closure live in this root. A `null` namespace makes a root for plain files |
| [`generates($id, ...)`](#generates) | Declares a file type, or changes the arguments given for an existing one |
| [`relates($from, $to, ...)`](#relates) | Connects two file types, for options such as `--factory` and for how one class refers to another |
| `excludes(string ...$excluded)` | Namespaces (`'App\\Support\\'`) or paths (`'app/Support'`) inside a root that no file type owns. Nothing is placed there, and discovery skips them |
| `path(string $path)` | Names and moves group folders; path tokens name placement options, anchors and placeholders |
| `extends(string $parent)` | Copies one defined parent; must be first in the chain |
| `allowsNesting(?string $dimension = null)` | Allows nested values for a group; name the dimension when the layout has several |
| `scaffolds(string $name, Closure $recipe)` | Defines a layout-specific scaffold override |
| `withoutCommands()` | Registers no `mod:*` commands for this layout. File types keep their command names for a host to dispatch by, and several may share one |
| `compile()` | Checks the layout and returns it compiled; throws `Tey\Mod\Exceptions\InvalidLayout` listing every problem |

Repeating `mounts()` or `generates()` changes only supplied arguments. Repeating `relates()` for the same pair or `as:` id changes that relation. A layout can't be changed once it is in use.

The closure passed to `mounts()` receives a `Tey\Mod\Layout\Root`, whose `generates()` takes the same arguments as the layout's.

## Group paths

`path()` is relative to the project root, unlike `generates(in:)`, which is below a mounted root. Absolute paths work too. The group token comes from an explicit path, otherwise the layout's own file type paths, otherwise its singularized name. Ambiguous layouts need an explicit path. Type-first uses `path('app/*/{feature}')`, with a wildcard for the file type folder.

`extends()` must be first, names one already-defined parent and copies its current definition. Later parent changes do not flow through. Name-derived tokens follow the child's name; explicitly declared tokens are inherited. Modules and features derive their tokens; DDD declares `domain`, and slices declares `feature` and `slice`.

`allowsNesting()` makes the chosen dimension accept dots or slashes throughout the layout and its anchors. DDD enables it. A nested domain named like a file type folder is ambiguous because that folder marks the group's boundary. Built-in modules and features remain flat.

A moved group outside every mount gets a folder-derived namespace. `Mod::current()->namespaceFor($path)` reports it; `mod:autoload` registers the mapping. [Custom layouts](/going-further/custom-layouts#extending-a-layout) gives a complete example.

<a id="kind"></a>

## generates()

`generates(string $id, ?string $in = null, ...)`

| Argument | Example | Effect |
| --- | --- | --- |
| `in:` | `'Modules/{module}/Models'` | the folder below the root. A `root:` prefix (`'domain:{domain}/Database/Factories'`) places it in another root; without one, it uses the enclosing `mounts()` closure's root, or else the first declared root |
| `suffix:` | `'Controller'` | appended to the class name |
| `fixed:` | `'Handler'` | a fixed class name. The command's name argument becomes optional, and a name that is given is not used |
| `timestamped:` | `true` | a timestamped file name, as for migrations; `false` keeps the name as given |
| `nested:` | `true` | accepts names like `Archived/Document`, as `make:model Archived/Document` does |
| `command:` | `'mod:repo'` | the command name, `mod:<id>` by default; `false` for none |
| `aliases:` | `['mod:repository']` | more command names. Aliases add up across calls. A hyphenated command or alias also gets a dash-free alias; when that name is already a command or alias, the existing one keeps it |
| `label:` | `'DTO'` | the noun the command prints: "DTO [...] created successfully." Without one, the stub's [`label()`](#stub), else the id in title case |
| `ungrouped:` | `'Console/Commands'` | the folder used when the group is left out |
| `discover:` | `'anywhere'` | where discovery looks: `'folder'` (the default), the file type's own folder; `'anywhere'`, every PHP file below the group folder |
| `discoverExcept:` | `['Tests']` | with `discover: 'anywhere'`, folders below the group folder discovery skips |
| `stub:` | `Stub::file(...)`, `Starters::dto()` | the [stub](#stub) its classes start from, or a [starter](#starters) |
| `priority:` | `-10` | breaks ties when two file types could own the same class; higher wins |
| `using:` | `fn (FileType $type) => $type->file()` | a closure receiving the [`FileType`](#filetype-methods), for what the arguments don't cover |

A `generates()` call without `in:` can refine a generator template, retaining its folder and contents while adding suffixes, aliases, discovery or bases.

A file type with an id Laravel has a generator for (`model`, `controller`, `listener` and the others in [Commands](/reference/commands#generator-commands)) uses that generator. A file type with a [starter's](#starters) id starts from that starter. Any other id starts as an empty class.

<a id="kind-methods"></a>

### FileType methods

`Tey\Mod\Layout\FileType`, reached through `using:`. The arguments above call the matching methods; these have no argument:

| Method | Does |
| --- | --- |
| `file()` | A plain file rather than a PHP class, such as a config file |
| `place(Closure $place, array $reads = [])` | Places files with a closure instead of `in:`. The closure receives the name and a `Tey\Mod\Placement\PlacementContext`, and returns the sub-namespace under the root. `$reads` lists the placeholders it reads, such as `['area']`. Such a file type is generated but never discovered |

<a id="relation"></a>

## relates()

`relates(string $from, string $to, $scope = null, $name = null, $mode = null, ?string $as = null)`

| Argument | Values | Effect |
| --- | --- | --- |
| `$from`, `$to` | file type ids | the file types it connects: `from: 'model', to: 'factory'` |
| `name:` | `'explicit'`, or a map of `strip-suffix`, `prefix` and `suffix` | how the related name derives from the original. `'explicit'`: the caller always names it. `['prefix' => 'Store']` turns `Document` into `StoreDocument`. The related type's own `suffix:` or `fixed:` still applies afterwards |
| `scope:` | `'same'` (default), a list of placeholders to keep such as `['feature']`, or `['keep' => [...], 'nested' => 'drop', 'name' => 'slice']` | which placement the related file keeps. `'nested' => 'drop'` stops nested folders carrying over (by default `Models/Archived/Document` relates to `Policies/Archived/DocumentPolicy`). `'name' => 'slice'` fills a missing placeholder from the original's name |
| `as:` | a relation id | names a separate relation between the same pair; defaults to `<from>-<to>` |
| `mode:` | `'generate'` (default), `'reference'`, `'none'`, or a `Tey\Mod\Relation\RelationMode` case | create the related file, only refer to it, or neither |

A relation's id names its file types, `<from>-<to>`, with a qualifier when two relations connect the same pair. Calling `relates()` with the same pair changes that relation; `as:` names a separate relation between the same pair. The built-in layouts declare:

| Id | Connects |
| --- | --- |
| `model-factory`, `model-seeder`, `model-policy`, `model-controller`, `model-migration` | a model to its factory, seeder, policy, controller and migration |
| `model-store-request`, `model-update-request` | a model to its store and update requests |
| `controller-store-request`, `controller-update-request` | a controller to its store and update requests |
| `factory-model` | a factory to its model, by reference |
| `listener-event` | a listener to its event, by reference |
| `handler-request`, `request-model` | in `slices`, a handler to its request, and a request to its model by reference |

`slices` has one request per slice, so it declares no update requests.

## Placeholders

| Placeholder | Meaning | Value |
| --- | --- | --- |
| `{feature}` | one folder | `--feature=Knowledge` or `--in=Knowledge` |
| `{feature?}` | an optional folder | omit it, or `--feature=Knowledge` |
| `{area+}` | one or more folders | `--area=Knowledge.Search` (or `Knowledge/Search`) writes to `.../Knowledge/Search/...` |

Placeholders are ordered by first appearance across the layout. That is the order of values in `--in` and in the short form.

## Stub

`Tey\Mod\Generation\Stub`:

| Method | Does |
| --- | --- |
| `Stub::file(string $path)` | The stub used when no variant applies |
| `whenInstalled(string $package, ?string $base = null, ?string $stub = null)` | When the Composer package is installed, extend `$base`, use `$stub`, or both |
| `whenClass(string $class, ?string $base = null, ?string $stub = null)` | When the class exists, extend `$base`, use `$stub`, or both |
| `base(?string $class = null, ?string $config = null)` | Always extend this base: a class, or the config key that holds one, with `$class` as its default |
| `generatesBase(GeneratedBase $base)` | When nothing else gives a base, write this one into the app on first use and extend it |
| `label(string $label)` | The noun a command prints for file types generated from this stub, unless the file type has its own `label:` |

Variants are tried in the order they were added, and the first that applies wins. An explicit base (the app's [`bases.<type>`](/reference/configuration#bases) key, or `base()`) wins over every variant.

### GeneratedBase

`Tey\Mod\Generation\GeneratedBase::named(string $name, string $in, string $stub)`:

| Argument | Example | Effect |
| --- | --- | --- |
| `$name` | `'DataTransferObject'` | the base class's name |
| `$in` | `'Data'` | its folder below the app's bases folder ([`bases_path`](/reference/configuration#bases-path), `app/Support` by default) |
| `$stub` | a path | the stub of its body, filled with `{{ namespace }}` and `{{ class }}`. The app replaces it with `stubs/mod.base.<name-in-kebab-case>.stub` |

| Method | Does |
| --- | --- |
| `inFileTypeRoot()` | Places the base below the file type's own root instead of the bases folder: `in: 'Shared/Data'` in the `ddd` layout writes `src/Domain/Shared/Data` |

A generated base is never overwritten, even with `--force`. [`mod:bases`](/reference/commands#writing-base-classes) writes any that are missing.

### Stub placeholders

| Placeholder | Filled with |
| --- | --- |
| `{{ namespace }}`, `{{ class }}` | the class's namespace and short name |
| `{{ base }}`, `{{ baseClass }}` | the base class's full and short name |
| `{{ baseImport }}` | its `use` line, or nothing when there is no base |
| `{{ extends }}` | ` extends <baseClass>`, or nothing when there is no base |

### Stub resolution order

The stub a class starts from is the first that exists:

1. the app's `stubs/mod.<type>.stub`;
2. the stub registered with `Mod::stubs()->for()` (the last registration wins);
3. the stub the layout declares (`generates(..., stub: ...)`);
4. the [starter](#starters) for the file type's id;
5. the Laravel generator's stub, or mod's empty class.

## Starters

`Tey\Mod\Generation\Starters` returns the starter stubs. A file type whose id is in the second column gets the starter in any layout; another file type uses one with `stub:`.

| Method | File type ids | Starts as |
| --- | --- | --- |
| `Starters::dto()` | `dto`, `data`, `data-transfer-object` | extends spatie/laravel-data's `Data` when installed, else a generated `DataTransferObject` base in `Data`. Label "DTO" |
| `Starters::viewModel()` | `view-model`, `viewmodel` | extends spatie/laravel-view-models' `ViewModel` when installed, else a generated `ViewModel` base in `ViewModels`. Label "View model" |
| `Starters::valueObject()` | `value-object`, `value` | a plain class with a constructor. Label "Value object" |
| `Starters::action()` | `action` | a class with `handle()`, or `use AsAction;` when lorisleiva/laravel-actions is installed. Label "Action" |

`Starters::dto()` and `Starters::viewModel()` take an optional `baseIn:` folder below the file type's root, such as `Starters::dto(baseIn: 'Shared/Data')`, which places the base there as `inFileTypeRoot()` does. The `ddd` layout uses it to keep its bases in `src/Domain/Shared`.

## Registering stubs

| Method | Does |
| --- | --- |
| `Mod::stubs()->for(string $type, Stub $stub)` | Registers the stub for a file type or named variant such as `controller.crud`. Returns the registry, so calls chain |
| `Mod::stubs()->folder(string $path)` | Registers a package generator-template folder; use `@group` for layout-neutral placement |

App generator templates take precedence over package templates. Two packages claiming one command disable only that command, with a warning naming both. The active template list is cached and fingerprinted. Flat published stubs still take precedence for their file type.

## Scaffold methods

`Tey\Mod\Scaffolds\Scaffold`; every method returns the builder:

| Method | Does |
| --- | --- |
| `makes($fileType, $name = null, $as = null, $stub = null, $options = [])` | Adds a PHP-class or migration member. `$as` defaults to the file type id; `$stub` selects a named variant; options go to the file type command |
| `include(string $name)` | Copies questions, members, parts and repetitions; later members or parts can replace included ones |
| `asks($name, $type = 'text', $default = null, $label = null, $options = [])` | Adds a question and option; types: text, list, choice, confirm, model, class. Choices use `$options` |
| `each(string $name, string $part)` | Repeats a part for each value in a list answer |
| `part($name, $uses = null, $with = [], $configure = null)` | Adds a child recipe reference or inline closure. Use `configure:` after named arguments |

`Tey\Mod\Scaffolds\Part` adds `uses(string $scaffold, array $with = [])` and `inserts(string $into, string $at, string $stub)`. An insert targets a parent-owned member alias or an anchored routes path, and uses `stubs/mod.insert.<name>.stub` before a retained `mod:<anchor>` marker. [Scaffolds](/going-further/scaffolds) covers aliases, collision choices, growth and recursion.

### Scaffold registry

Read the effective finite tree:

```php
$registry = app(\Tey\Mod\Scaffolds\ScaffoldRegistry::class);
$nodes = $registry->nodes();
$problems = $registry->problems();
```

`nodes()` returns a fresh array keyed by dot path. Rows contain `key`, `source`, `from`, alias-keyed `members` (`fileType`, `name`, `stub`, `options`), immediate `children` in declaration order, and `uses` (a referenced scaffold or null). Referenced members are included; recursive references stay finite. Disabled nodes are omitted; `problems()` gives their diagnostics. `mod:cache` stores this metadata while providers keep registering executable callbacks.

## Swapping generators

| Method | Does |
| --- | --- |
| `Mod::generators()->use(string $type, string $command)` | Generates the file type with this command class, replacing the built-in one. Returns the registry |

The class extends a mod command: `Tey\Mod\Commands\GenericClassCommand` for file types with no Laravel generator, or the matching command, such as `ModelCommand`, `ControllerCommand`, `RequestCommand`, `FactoryCommand` or `MigrationCommand`. The app can set the same mapping in [`generators`](/reference/configuration#generators).

### Generator hooks

Protected methods a command class can override:

| Hook | Use |
| --- | --- |
| `placementInput()` | the placement in `--in` syntax, for example from your own option or prompt |
| `placementContext()` | the placement context the command resolves against |
| `placementOptions()` | which placement options the command adds: option name => the placeholder it sets, with `null` for `--in`. Return `[]` to add none; related commands then receive the `Group:Name` form |
| `layout()`, `kind()` | the compiled layout and the command's file type, for use inside other hooks |
| `resolveLayout()`, `kindId()` | the layout and file type, for commands not registered through the layout |
| `stubDefinition()` | the `Stub` the class is generated from: by default the one registered with `Mod::stubs()`, else the layout's |
| `collisionPolicy()` | `CollisionPolicy::Refuse` (check every file before writing) or `CollisionPolicy::Native` (the Laravel command's own check and `--force` decide) |
| `plansEagerly()`, `resolvePlan()` | plan from inside your own `handle()` |
| `beforeGeneration(GenerationPlan $plan)`, `afterGeneration(GenerationPlan $plan, int $exitCode)` | run code around generation |
| `nativePathAllowed()` | on `MigrationCommand`: let `--path` and `--realpath` through |
| `reportRefusal(ModException $e)`, `reportReference(ResolvedArtifact $target)` | the only places the commands print on their own |

These hooks, and the methods on this page, are mod's public API. A command's other protected methods are internal and can change in any release.

## The compiled layout

`Mod::current()` returns the active layout as a `Tey\Mod\Layout\CompiledLayout`:

| Method | Returns |
| --- | --- |
| `dimensionNames()` | the layout's dimensions in order, such as `['feature', 'slice']` |
| `placementOptions()` | each dimension's option name, such as `['module' => 'module']` |
| `roots()` | the layout's roots, as `Tey\Mod\Layout\CompiledRoot` |
| `namespaceFor(string $path)` | the namespace inferred for a path, including moved groups |
| `hasKind(string $id)` | whether the layout has a file type of that id |

## Exceptions

Every exception mod throws extends `Tey\Mod\Exceptions\ModException`. The ones you are most likely to catch:

| Exception | Thrown when |
| --- | --- |
| `InvalidLayout` | a layout definition has problems, or `mod.layout` names a layout that doesn't exist |
| `UnknownFileType` | a file type id isn't in the layout |
| `InvalidName` | a class name can't be used, such as a nested name for a file type that doesn't accept one |

## Renamed in 0.2

| 0.1 | 0.2 |
| --- | --- |
| `root()` | `mounts()` |
| `kind()` | `generates()` |
| `relation($id, from: ..., to: ...)` | `relates($from, $to, as: $id)`; omit `as:` for the usual `<from>-<to>` id |
| `exclude()` | `excludes()` |
| `typeFolders()` | `path()` with a project-relative group path |
| `placementOption()` | removed; the token in `path()` names the option |
| `Tey\Mod\Layout\Kind` | `Tey\Mod\Layout\FileType` in `using:` callbacks |
| `Tey\Mod\Exceptions\UnknownKind` | `Tey\Mod\Exceptions\UnknownFileType` |
| `GeneratedBase::inKindRoot()` | `GeneratedBase::inFileTypeRoot()` |
| `discovery.kinds` | `discovery.file_types` |

[Upgrading from 0.1](/guide/upgrade) shows before/after code.
