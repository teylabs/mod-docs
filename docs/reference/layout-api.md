# Layout API

Every method of the `Mod` facade, the layout chain, stubs and generator commands. [Custom Layouts](/going-further/custom-layouts) and [Plugins](/going-further/plugins) show them in use.

## The Mod Facade

`Tey\Mod\Facades\Mod`, called from a service provider's `boot()`:

| Method | Returns | Does |
| --- | --- | --- |
| `Mod::layout(string $name)` | `Layout` | Defines a layout, or extends a built-in or defined one |
| `Mod::has(string $name)` | `bool` | Whether a layout of that name exists |
| `Mod::names()` | `list<string>` | The names of every layout |
| `Mod::stubs()` | `StubRegistry` | The stubs registered for file types: [`for()`](#registering-stubs) |
| `Mod::generators()` | `GeneratorRegistry` | The commands behind file types: [`use()`](#swapping-generators) |

## Layout Methods

`Tey\Mod\Layout\Layout`. Every method returns the layout, so the calls chain:

| Method | Does |
| --- | --- |
| `root($name, $namespace, $path, $closure = null)` | Maps a namespace to a folder. File types declared in the closure live in this root. A `null` namespace makes a root for plain files |
| [`kind($id, ...)`](#kind) | Declares a file type, or changes the arguments given for an existing one |
| [`relation($id, ...)`](#relation) | Connects two file types, for options such as `--factory` and for how one class refers to another |
| `exclude(string ...$excluded)` | Namespaces (`'App\\Support\\'`) or paths (`'app/Support'`) inside a root that no file type owns. Nothing is placed there, and discovery skips them |
| `placementOption($option, $placeholder = null)` | Renames a placeholder's option. With one placeholder, `$placeholder` can be left out; with several, name it, as in `'{slice}'` |
| `withoutCommands()` | Registers no `mod:*` commands for this layout. File types keep their command names for a host to dispatch by, and several may share one |
| `compile()` | Checks the layout and returns it compiled; throws `Tey\Mod\Exceptions\InvalidLayout` listing every problem |

Calling `root()`, `kind()` or `relation()` again with an existing name changes only the arguments you pass. A layout can't be changed once it is in use.

The closure passed to `root()` receives a `Tey\Mod\Layout\Root`, whose `kind()` takes the same arguments as the layout's.

## kind()

```php
kind(string $id, ?string $in = null, ...)
```

| Argument | Example | Effect |
| --- | --- | --- |
| `in:` | `'Modules/{module}/Models'` | the folder below the root. A `root:` prefix (`'domain:{domain}/Database/Factories'`) places it in another root; without one, it uses the enclosing `root()` closure's root, or else the first declared root |
| `suffix:` | `'Controller'` | appended to the class name |
| `fixed:` | `'Handler'` | a fixed class name, whatever name is given |
| `timestamped:` | `true` | a timestamped file name, as for migrations; `false` keeps the name as given |
| `nested:` | `true` | accepts names like `Archived/Document`, as `make:model Archived/Document` does |
| `command:` | `'mod:repo'` | the command name, `mod:<id>` by default; `false` for none |
| `aliases:` | `['mod:repository']` | more command names. Aliases add up across calls |
| `label:` | `'DTO'` | the noun the command prints: "DTO [...] created successfully." Without one, the id in title case |
| `fallback:` | `'Console/Commands'` | the folder used when the group is left out |
| `discoverAnywhere:` | `true` | discovered in every PHP file below the group folder, not only its own folder. `false` is not accepted: leave it out instead |
| `except:` | `['Tests']` | with `discoverAnywhere:`, folders below the group folder discovery skips |
| `stub:` | `Stub::file(...)` | the [stub](#stub) its classes start from |
| `priority:` | `-10` | breaks ties when two file types could own the same class; higher wins |
| `using:` | `fn (Kind $kind) => $kind->file()` | a closure receiving the [`Kind`](#kind-methods), for what the arguments don't cover |

A file type with an id Laravel has a generator for (`model`, `controller`, `listener` and the others in [Commands](/reference/commands#generator-commands)) uses that generator. Any other id starts as an empty class.

### Kind Methods

`Tey\Mod\Layout\Kind`, reached through `using:`. The arguments above call the matching methods; these have no argument:

| Method | Does |
| --- | --- |
| `file()` | A plain file rather than a PHP class, such as a config file |
| `place(Closure $place, array $reads = [])` | Places files with a closure instead of `in:`. The closure receives the name and a `Tey\Mod\Placement\PlacementContext`, and returns the sub-namespace under the root. `$reads` lists the placeholders it reads, such as `['area']`. Such a file type is generated but never discovered |

## relation()

```php
relation(string $id, ?string $from = null, ?string $to = null, $scope = null, $name = null, $policy = null)
```

| Argument | Values | Effect |
| --- | --- | --- |
| `from:`, `to:` | file type ids | the file types it connects: `from: 'model', to: 'factory'` |
| `name:` | `'explicit'`, or a map of `strip-suffix`, `prefix` and `suffix` | how the related name derives from the original. `'explicit'`: the caller always names it. `['prefix' => 'Store']` turns `Document` into `StoreDocument`. The related type's own `suffix:` or `fixed:` still applies afterwards |
| `scope:` | `'same'` (default), a list of placeholders to keep such as `['feature']`, or `['keep' => [...], 'nested' => 'drop', 'name' => 'slice']` | which placement the related file keeps. `'nested' => 'drop'` stops nested folders carrying over (by default `Models/Archived/Document` relates to `Policies/Archived/DocumentPolicy`). `'name' => 'slice'` fills a missing placeholder from the original's name |
| `policy:` | `'generate'` (default), `'reference'`, `'none'` | create the related file, only refer to it, or neither |

The built-in layouts relate a model to its `factory`, `seeder`, `policy`, `controller`, `migration` and store and update requests, a factory to its `model`, a listener to its `event`, and a controller to its store and update requests.

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

Variants are tried in the order they were added, and the first that applies wins. An explicit base (the app's `layouts.<layout>.bases.<type>` key, or `base()`) wins over every variant.

### GeneratedBase

`Tey\Mod\Generation\GeneratedBase::named(string $name, string $in, string $stub)`:

| Argument | Example | Effect |
| --- | --- | --- |
| `$name` | `'DataTransferObject'` | the base class's name |
| `$in` | `'Shared/Data'` | its folder below the file type's root |
| `$stub` | a path | the stub of its body, filled with `{{ namespace }}` and `{{ class }}`. The app replaces it with `stubs/mod.base.<name-in-kebab-case>.stub` |

A generated base is never overwritten, even with `--force`.

### Stub Placeholders

| Placeholder | Filled with |
| --- | --- |
| `{{ namespace }}`, `{{ class }}` | the class's namespace and short name |
| `{{ base }}`, `{{ baseClass }}` | the base class's full and short name |
| `{{ baseImport }}` | its `use` line, or nothing when there is no base |
| `{{ extends }}` | ` extends <baseClass>`, or nothing when there is no base |

### Stub Resolution Order

The stub a class starts from is the first that exists:

1. the app's `stubs/mod.<type>.stub`;
2. the stub registered with `Mod::stubs()->for()` (the last registration wins);
3. the stub the layout declares (`kind(..., stub: ...)`);
4. the Laravel generator's stub, or mod's empty class.

## Registering Stubs

| Method | Does |
| --- | --- |
| `Mod::stubs()->for(string $type, Stub $stub)` | Registers the stub for a file type. Returns the registry, so calls chain |

## Swapping Generators

| Method | Does |
| --- | --- |
| `Mod::generators()->use(string $type, string $command)` | Generates the file type with this command class, replacing the built-in one. Returns the registry |

The class extends a mod command: `Tey\Mod\Commands\GenericClassCommand` for file types with no Laravel generator, or the matching command, such as `ModelCommand`, `ControllerCommand`, `RequestCommand`, `FactoryCommand` or `MigrationCommand`. The app can set the same mapping in [`generators`](/reference/configuration#generators).

### Generator Hooks

Protected methods a command class can override:

| Hook | Use |
| --- | --- |
| `placementInput()` | the placement in `--in` syntax, for example from your own option or prompt |
| `placementContext()` | the placement context the command resolves against |
| `placementOptions()` | which placement options the command adds: option name => the placeholder it sets, with `null` for `--in`. Return `[]` to add none; related commands then receive the `Group:Name` form |
| `resolvePreset()`, `kindId()` | the layout and file type, for commands not registered through the layout |
| `stubDefinition()` | the `Stub` the class is generated from: by default the one registered with `Mod::stubs()`, else the layout's |
| `collisionPolicy()` | `CollisionPolicy::Refuse` (check every file before writing) or `CollisionPolicy::Native` (the Laravel command's own check and `--force` decide) |
| `plansEagerly()`, `resolvePlan()` | plan from inside your own `handle()` |
| `beforeGeneration(GenerationPlan $plan)`, `afterGeneration(GenerationPlan $plan, int $exitCode)` | run code around generation |
| `nativePathAllowed()` | on `MigrationCommand`: let `--path` and `--realpath` through |
| `reportRefusal(ModException $e)`, `reportReference(ResolvedArtifact $target)` | the only places the commands print on their own |

`Preset::dimensions()` lists the layout's placeholders in order, and `Preset::placementOptions()` maps each one to its option name. Every exception mod throws extends `Tey\Mod\Exceptions\ModException`.
