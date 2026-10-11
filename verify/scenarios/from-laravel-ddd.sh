# Execute the two documented destination choices in disposable apps.
PAGE=$DOCS/docs/guide/from-laravel-ddd.md
fresh 'DDD replacement with existing classes' ddd
doc_config 'Choose the Like-for-like DDD Layout'
mkdir -p "$APP/src/Domain/Inventory/Models"
cat > "$APP/src/Domain/Inventory/Models/ExistingDocument.php" <<'PHP'
<?php
namespace Domain\Inventory\Models;
class ExistingDocument extends \Illuminate\Database\Eloquent\Model {}
PHP
check 'DDD autoload preview and apply run exactly as documented' doc_shell 'Choose the Like-for-like DDD Layout' 2
check 'An existing Domain class loads without a namespace move' classes_load 'Domain\Inventory\Models\ExistingDocument'
check 'DDD generation preview runs exactly as documented' doc_shell 'Choose the Like-for-like DDD Layout' 3
check 'DDD preview retains domain model and factory destinations' out_has 'src/Domain/Inventory/Database/Factories/DocumentFactory.php' mod:model Inventory:Document --factory --dry-run --json
check 'DDD generates a model and factory' art mod:model Inventory:Document --factory
check 'DDD model and factory load' classes_load 'Domain\Inventory\Models\Document' 'Domain\Inventory\Database\Factories\DocumentFactory'

fresh 'custom layout with shared UI' modules
doc_file 'Choose a Custom Layout Instead' app/Providers/ModLayoutServiceProvider.php
# Put the layout provider first, as instructed, before the app provider boots.
perl -0pi -e 's/return \[/return [\n    App\\Providers\\ModLayoutServiceProvider::class,/' "$APP/bootstrap/providers.php"
doc_config 'Choose a Custom Layout Instead' 2
check 'Custom layout autoload and inventory commands run as documented' doc_shell 'Choose a Custom Layout Instead'
check 'Custom layout generates module PHP' art mod:model Inventory:Document --factory
check 'Custom layout generates the module HTTP controller' art mod:controller Inventory:DocumentController
# Represent a migrated real UI provider, retaining its native inheritance.
mkdir -p "$APP/app/UI/Providers"
cat > "$APP/app/UI/Providers/SharedServiceProvider.php" <<'PHP'
<?php
namespace App\UI\Providers;
class SharedServiceProvider extends \Illuminate\Support\ServiceProvider {}
PHP
check 'A migrated UI provider remains valid PHP' has app/UI/Providers/SharedServiceProvider.php
check 'Custom layout generates shared UI data' art mod:ui-data Heading
check 'Module and UI classes load through the existing App root' classes_load 'App\Modules\Inventory\Models\Document' 'App\Modules\Inventory\Http\Controllers\DocumentController' 'App\UI\Providers\SharedServiceProvider' 'App\UI\Data\Heading'
check 'Custom UI provider is discovered' tinker 'if (!app()->getProvider(\App\UI\Providers\SharedServiceProvider::class)) { throw new \RuntimeException("UI provider not discovered"); }'
check 'Old Infrastructure is absent from the new layout' tinker 'foreach (\Tey\Mod\Facades\Mod::current()->roots() as $root) { if (str_contains($root->path, "Infrastructure")) { throw new \RuntimeException("Unexpected Infrastructure root"); } }'
check 'Custom layout builds its production discovery cache' art mod:cache
check 'Custom layout boots with the cache' art mod:list --json
