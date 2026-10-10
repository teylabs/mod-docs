# Building on mod


Packages can own their layout, discovery lifecycle and generator commands while using Mod's placement engine. Use only members marked `@api`. A public PHP method or property marked `@internal` is not a compatibility promise, even when its class is public. The published signatures, parameter names and nested value types are pinned in `tests/Fixtures/published-api.json`.

## Isolated layouts and public values

`Layout::fresh(string $name): Layout` starts with shipped defaults for a built-in name or an empty definition otherwise. It does not read or mutate app customisations. `extends()` resolves built-ins in its private registry; use `Mod::layout()` for application definitions. Call `compiled(): CompiledLayout` to compile without sealing the mutable definition. Repeated compilation produces independent values.

```php
use Tey\Mod\Layout\Layout;
use Tey\Mod\Placement\PlacementContext;

$definition = Layout::fresh('ddd');
$layout = $definition->compiled();
$invoice = $layout->place('model', 'Invoice', PlacementContext::of(['domain' => 'Billing/Internal']));
$owned = $layout->locate('Domain\\Billing\\Internal\\Models\\Invoice');
```

`CompiledLayout::place(string $fileType, string $name, PlacementContext $context, array $attributes = []): ResolvedArtifact` performs placement without writing or checking collisions. Attributes are `array<string,string|int|float|bool|null>`. `locate(string $fqcn): ?ResolvedArtifact` returns null for an unowned or ambiguous class; ownership does not prove existence.

Inspect `ResolvedArtifact::$fileType`, `$context`, `$name`, `$nested`, `fqcn(): ?string`, `namespace(): ?string`, `path(): string` and `nestedName(): string`. `namespace()` returns null for files and an empty string for global-namespace classes. For schema callbacks, `ResolvedArtifact::phpClass(string $fileType, string $namespace, string $basename, string $path, ?PlacementContext $context = null): self` preserves the chosen identity verbatim and normalises the path; it does not reapply naming policy or infer child commands.

`Artifact\CompiledFileType` is the immutable compiled metadata; `Layout\FileType` remains the mutable builder. The compiled value exposes `id`, `command`, `aliases`, `label`, `extension`, `case`, `isClass(): bool` and `isTimestamped(): bool`. Use `CompiledLayout::fileTypes(): array<string,CompiledFileType>`, `fileType(string $fileType): CompiledFileType` and `hasFileType(string $fileType): bool`. The old `ArtifactKind`, `kind()`, `kinds()`, `hasKind()` and artifact `$kind` remain internal.

Enumerate `array_keys($layout->fileTypes())` when disabling discovery. Resolve `artifact->path()` against the host base with its path utilities, retaining absolute paths and Windows drive paths. Do not inspect placement rules, identity objects, naming policies or `ExistingArtifacts`. A host with only a `domain` dimension formats its child option from `context->get('domain')`, replacing `/` with `.`, and retains its existing fallback when absent.

## Host discovery and cache policy

```php
use Tey\Mod\Discovery\Discovery;
use Tey\Mod\Discovery\DiscoveryOptions;
use Tey\Mod\Discovery\DiscoveryType;
use Tey\Mod\Exceptions\InvalidDiscoveryCache;

$discovery = new Discovery(layout: $layout, options: DiscoveryOptions::fromConfig([
    'cache' => 'bootstrap/cache/host-discovery.php',
    'file_types' => ['provider' => 'provider'],
]), basePath: $app->basePath());

try {
    $inventory = $discovery->readCache();
} catch (InvalidDiscoveryCache $exception) {
    $inventory = $discovery->scan(); // The host chooses its own fallback policy.
}
$providers = $inventory->ofType(DiscoveryType::Provider);
```

The constructor is `Discovery(CompiledLayout $layout, DiscoveryOptions $options, string $basePath)`. `scan(): Inventory` is a cold scan. `readCache(): Inventory` validates the existing cache and throws `InvalidDiscoveryCache` for missing, foreign, stale or malformed data. It never scans or writes, and leaves memoised application discovery state alone. `cacheInventory(): Inventory` explicitly cold-scans and writes the current cache format with no scaffold payload. Use a host-owned cache path; writing a shared app cache would replace its scaffold payload. Rebuild on deployment when a custom candidate callback changes: its fingerprint records presence, not closure contents.

`Inventory::ofType(DiscoveryType $type): array` returns `list<DiscoveredArtifact>` in inventory order; `directories(string $fileType): array` returns sorted directory paths. Entries expose `fileType`, `type`, `class`, `path`, `context: array<string,string>`, `events: list<array{event:string,method:string}>` and `target: ?string`. Preserve existing path representation; directory entries have an empty class. Rejections, payload serialisation, cache objects, fingerprint helpers and listener registration remain internal.

`DiscoveryType` is the string-backed enum `Provider`, `Command`, `Listener`, `Subscriber`, `Directory`, `Factory`, `Policy`. Use its standard `from()`, `tryFrom()` and `cases()`. `DiscoveryDefinition::forFileType(string $fileType, DiscoveryType $type, bool $enabled = true): self` constructs public candidate metadata; inspect `$fileType`, `$type` and `$enabled`. Existing definition factories with old parameter names are internal. `DiscoveryOptions::withCandidates()` accepts `Closure(CompiledRoot, string, DiscoveryDefinition): iterable<string>`; candidates do not override ownership or eligibility. Use `file_types` in configuration.

## Generator support without app feature boot

A host Laravel provider calls `ModServiceProvider::registerGenerationServices($app)` in `register()`. It supplies adapter defaults with `bindIf`, preserves host bindings and is safe to call repeatedly. It registers no Mod commands, active layout, routes, views or discovered providers/listeners. Laravel's application/files/config services are prerequisites; a bare container is insufficient for the application-dependent factories.

The host supplies its own compiled layout through `resolveLayout()` or `layout()`, and its file type id through `fileTypeId()`. Normal stubs, package variants, generated bases and model migration companions work without registering the full provider. Module-owned generator template rebinding requires the full provider and app layouts. Do not depend on the internal registry/template selection helpers for isolated layouts.

Register a package stub using `Mod::stubs()->forFileType(string $fileType, Stub $stub)` and a generator replacement using `Mod::generators()->useFileType(string $fileType, string $command)`. Old registration methods with internal vocabulary remain callable for compatibility but are not published API.

## Supported planning and dispatch hooks

These are protected hooks on the public command subclasses. Concern traits are internal implementation locations, not host mixins.

| Hook | Supported purpose |
| --- | --- |
| `plan(): GenerationPlan` | Class adapters: build a candidate with a custom primary. |
| `currentPlan(): ?GenerationPlan` | Inspect an already-resolved invocation without causing planning. |
| `plannedRelations(ResolvedArtifact $primary): array` | Select native option relations or supply host-placed request targets; returns `list<RelationResolution>`. |
| `plannedRelation(string $relationId): ?RelationResolution` | Read the running plan by id; hosts may supply a prefixed-id fallback. |
| `relatedFileType(string $role): string` | Map a native model/factory/request/migration role to a canonical file type id; defaults to the input. |
| `followRelation(RelationResolution $resolution, array $arguments = []): void` | Generate a related target or report a reference; arguments are `array<string,mixed>`. |
| `argumentsFor(ResolvedArtifact $target): array` | Format child name and placement options; returns `array<string,mixed>`. |
| `generateOwnedClass(string $fqcn, string $fileType): void` | Override missing model/parent dispatch; the file type id is already canonical. |

`fileType(): CompiledFileType` and `fileTypeId(): string` replace the old internal metadata hooks. Existing documented layout, placement, stub, collision, timing and reporting hooks stay supported. `plannedRelationsTo()`, `relationsTo()`, `placeSibling()`, `inOption()` and collision/preview/scaffold helpers remain internal. Native adapters map roles once at their call boundaries, including migration preflight. Remove translator overrides of those internal helpers. Hosts inspect `currentPlan()?->relations ?? []` and filter by public `relation->toFileType` instead.

```php
protected function relatedFileType(string $role): string
{
    return 'domain-'.$role;
}

protected function plan(): GenerationPlan
{
    $primary = $this->blueprint->artifact();
    return new GenerationPlan($primary, $this->plannedRelations($primary));
}
```

`plan()` and `plannedRelations()` can run more than once while group answers settle; they must not write files. For input preparation in `handle()`, return false from `plansEagerly()` and call `resolvePlan()` after preparation. Resolution remains idempotent per invocation and performs Mod's collision checks. `currentPlan()` is null before resolution and after invocation cleanup. Do not substitute it with a call that would resolve input or prompt too early.

`GenerationPlan` exposes `primary` and `relations: list<RelationResolution>` and accepts those public values in its constructor. Relations expose `id`, `fromFileType`, `toFileType`, `mode`; use `CompiledLayout::relations()`, `relation(string $relationId)` or `relationsFrom(string $fileType)`. To change an inherited mode, call `relates($relation->fromFileType, $relation->toFileType, mode: 'none', as: $relation->id)`. Scope/name engines remain internal.

For controller store/update forwarding, place targets through the host's request file type, then return `RelationResolution::resolved($relation, $primary, $target)` from `plannedRelations()`. A resolution exposes `relation`, `source`, `target`, `isResolved()` and `mode()`. Override `plannedRelation()` for custom relation ids and `followRelation()`/`argumentsFor()` for host dispatch. Retain generation/reference semantics and non-zero child failure propagation. Calling the parent preserves Mod's related-generation scope; bypassing it makes the host responsible for that scope and recursion policy.

## Migration creators

`MigrationCommand::__construct(Illuminate\Database\Migrations\MigrationCreator $creator, Illuminate\Support\Composer $composer)` accepts the framework creator directly. Mod adapts an exact framework creator internally, preserving filesystem and custom stub path, and pins planned timestamps. Existing internal Mod creators still work. Native `--path`/`--realpath` require the supported `nativePathAllowed(): bool` opt-in.

An application creator subclass keeps its actual native dispatch and bypasses Mod planning independently of `--path`. It has no Mod plan and does not run plan-specific callbacks. A host can retain its domain directory override using only the public framework creator classification; do not reflect into or construct a Mod creator. Arbitrary creator output cannot be promised to match a Mod timestamp/path plan.
