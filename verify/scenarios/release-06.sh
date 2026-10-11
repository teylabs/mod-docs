# Executable 0.6 provider declarations, read directly from the published pages.
PAGE=$DOCS/docs/going-further/frontend.md
fresh 'stack declarations' modules
check 'Mod::stack matches the JSON inventory' tinker 'if (\Tey\Mod\Facades\Mod::stack()->toArray() !== json_decode(\Illuminate\Support\Facades\Artisan::call("mod:list", ["--json" => true]) === 0 ? \Illuminate\Support\Facades\Artisan::output() : "{}", true)["stack"]) throw new \RuntimeException("Stack differs");'
# Declare Svelte and Livewire without installing either dependency.
"$PHP" -r '$f=$argv[1]; $j=json_decode(file_get_contents($f),true); $j["dependencies"]["@inertiajs/svelte"]="*"; file_put_contents($f,json_encode($j)); $f=$argv[2]; $j=json_decode(file_get_contents($f),true); $j["require"]["livewire/livewire"]="*"; file_put_contents($f,json_encode($j));' "$APP/package.json" "$APP/composer.json"
check 'Stack detects Svelte and Livewire declarations' tinker 'if (\Tey\Mod\Facades\Mod::stack()->inertia() !== "svelte" || !\Tey\Mod\Facades\Mod::stack()->livewire()) throw new \RuntimeException("Wrong stack");'
check 'Svelte pages generate' art mod:page Inventory:Widget
check 'Svelte page path exists' test -f "$APP/app/Modules/Inventory/resources/js/pages/Widget.svelte"

fresh 'mounted root pages' modules
mkdir -p "$APP/app/UI/screens" "$APP/app/UI/templates"
printf '<template>Mounted</template>\n' > "$APP/app/UI/screens/Dashboard.vue"
printf 'Mounted view\n' > "$APP/app/UI/templates/dashboard.blade.php"
doc_boot 'Frontend files in mounted roots' 2
LAYOUT=custom perl -0pi -e 's/\x27layout\x27 => \x27modules\x27/\x27layout\x27 => \x27custom\x27/' "$APP/config/mod.php"
check 'Mounted-root page name resolves to the declared directory' tinker 'if (\Tey\Mod\Facades\Mod::pageEntry("UI::Dashboard", "vue") !== "app/UI/screens/Dashboard.vue") throw new \RuntimeException("Wrong entry");'
check 'Mounted-root view namespace resolves' tinker 'if (!view()->exists("ui::dashboard")) throw new \RuntimeException("Missing view");'
check 'Mounted-root owner appears in inventory' out_has 'UI::{path}' mod:list --json
fresh 'mounted components' modules
doc_boot 'Frontend files in mounted roots' 1
LAYOUT=custom perl -0pi -e 's/\x27layout\x27 => \x27modules\x27/\x27layout\x27 => \x27custom\x27/' "$APP/config/mod.php"
check 'Component-only owner declares its alias' out_has '@/UI' mod:list --json

fresh 'package pages and wiring' modules
mkdir -p "$APP/app/resources/js/pages"
printf '<template>Invoices</template>\n' > "$APP/app/resources/js/pages/Invoices.vue"
doc_boot 'Package pages and wiring'
check 'Package page entry resolves' tinker 'if (\Tey\Mod\Facades\Mod::pageEntry("billing::Invoices", "vue") !== "app/resources/js/pages/Invoices.vue") throw new \RuntimeException("Wrong package entry");'
check 'Package page and wiring records appear' out_has '@acme/billing' mod:list --json
check 'Package installation preview runs' art mod:install inertia --dry-run --json

fresh 'module assets' modules
mkdir -p "$APP/app/Modules/Editor/images" "$APP/app/Modules/Editor/styles"
printf '<svg xmlns="http://www.w3.org/2000/svg"/>\n' > "$APP/app/Modules/Editor/images/logo.svg"
printf 'body { color: black; }\n' > "$APP/app/Modules/Editor/styles/editor.css"
doc_boot 'Static assets and executable entries'
check 'Assets report the independent entry' out_has 'app/Modules/Editor/styles/editor.css' mod:list --json
PAGE=$DOCS/docs/reference/commands.md
check 'Documented asset preview and apply run' doc_shell 'Installing Assets'
check 'Structured missing placement has code and data' bash -c 'cd "$1"; "$PHP" artisan mod:model Widget --dry-run --json | "$PHP" -r '\''$j=json_decode(stream_get_contents(STDIN),true,512,JSON_THROW_ON_ERROR); foreach($j["warnings"] as $w) if($w["code"] === "missing_placement" && isset($w["data"]["file_type"],$w["data"]["dimension"],$w["data"]["options"],$w["data"]["choices"])) exit(0); exit(1);'\''' harness "$APP"

PAGE=$DOCS/docs/going-further/building-on-mod.md
fresh 'vendor scaffolds' modules
"$PHP" -r '$f=$argv[1];$j=json_decode(file_get_contents($f),true);$j["dependencies"]["@inertiajs/vue3"]="*";file_put_contents($f,json_encode($j));' "$APP/package.json"
doc_boot 'Shipping scaffolds'
check 'Vendor scaffold, part and inventory commands run' doc_shell 'Shipping scaffolds'
check 'Vendor scaffold writes its page' test -f "$APP/app/Modules/Inventory/resources/js/pages/Widget/Index.vue"
check 'Vendor part writes its page' test -f "$APP/app/Modules/Inventory/resources/js/pages/Widget/Form.vue"
# Move the provider outside app/, preserving the page's exact registration.
mkdir -p "$APP/pkg"
cp "$APP/app/Providers/AppServiceProvider.php" "$APP/pkg/AcmeServiceProvider.php"
sed 's/namespace App\\Providers;/namespace Acme;/; s/class AppServiceProvider/class AcmeServiceProvider/' "$APP/pkg/AcmeServiceProvider.php" > "$WORK/package-provider.php"
cp "$WORK/package-provider.php" "$APP/pkg/AcmeServiceProvider.php"
autoload 'Acme\' 'pkg/'
printf '<?php\nnamespace App\\Providers;\nclass AppServiceProvider extends \\Illuminate\\Support\\ServiceProvider {}\n' > "$APP/app/Providers/AppServiceProvider.php"
"$PHP" -r '$f=$argv[1];$s=file_get_contents($f);$s=str_replace("return [","return [\n    Acme\\AcmeServiceProvider::class,",$s);file_put_contents($f,$s);' "$APP/bootstrap/providers.php"
check 'Simulated package retains vendor command' out_has 'acme/pages' mod:list --vendor=acme --json
# A second provider demonstrates deterministic conflict reconciliation.
sed 's/class AcmeServiceProvider/class OtherServiceProvider/' "$APP/pkg/AcmeServiceProvider.php" > "$APP/pkg/OtherServiceProvider.php"
"$PHP" -r '$f=$argv[1];$s=file_get_contents($f);$s=str_replace("return [","return [\n    Acme\\OtherServiceProvider::class,",$s);file_put_contents($f,$s);' "$APP/bootstrap/providers.php"
check 'Conflicting package providers expose their notice' out_has vendor_scaffold_conflict mod:list --vendor=acme --json
check 'Unpinned package conflict refuses generation' fails art mod:acme/pages Inventory:Conflict
check 'Documented provider pin selects a registered provider' doc_config 'Shipping scaffolds' 2
check 'Pinned package conflict allows generation' art mod:acme/pages Inventory:Pinned
rm "$APP/pkg/OtherServiceProvider.php"
"$PHP" -r '$f=$argv[1];$s=file_get_contents($f);$s=str_replace("    Acme\\OtherServiceProvider::class,\n","",$s);file_put_contents($f,$s);' "$APP/bootstrap/providers.php"
perl -0pi -e "s/Mod::vendor\('acme'\)->scaffold/Mod::scaffold/" "$APP/pkg/AcmeServiceProvider.php"
check 'Vendorless package registration is refused with vendor_required' out_has vendor_required mod:list --json
check 'Vendorless package command refuses execution' fails art mod:pages Inventory:Refused

PAGE=$DOCS/docs/going-further/routes.md
fresh 'package routes' modules
mkdir -p "$APP/app/routes"
printf '<?php\n\\Illuminate\\Support\\Facades\\Route::get("billing-check", fn () => "billing");\n' > "$APP/app/routes/web.php"
# Registrar referenced by the documented registration block.
mkdir -p "$APP/app/Providers"
printf '<?php\nnamespace App\\Providers;\nclass ReportsRoutes implements \\Tey\\Mod\\Routing\\RegistersRoutes { public static function web(): void { \\Illuminate\\Support\\Facades\\Route::get("reports-check", fn () => "reports"); } public static function api(): void {} }\n' > "$APP/app/Providers/ReportsRoutes.php"
doc_boot 'Package Routes'
printf '\n\\Tey\\Mod\\Facades\\Mod::routes();\n' >> "$APP/routes/web.php"
check 'Package route files load' out_has billing-check route:list --path=billing-check
check 'Package registrar loads' out_has reports-check route:list --path=reports-check
check 'Package routes are listed with package kind' out_has '"kind": "package"' mod:list --json
code=$(doc_block 'Package Routes' php 2)
printf '<?php\n%s\n' "$code" > "$APP/routes/web.php"
check 'Documented package route group inherits its prefix' out_has admin/billing-check route:list --path=billing-check

PAGE=$DOCS/docs/going-further/database-connections.md
fresh 'database connections' modules
# Define a second SQLite database before the documented declaration.
: > "$APP/database/catalogue.sqlite"
boot "config(['database.connections.catalogue' => ['driver' => 'sqlite', 'database' => database_path('catalogue.sqlite'), 'prefix' => '', 'foreign_key_constraints' => true]]);"
doc_boot 'Database Connections'
doc_file 'Models and factories' app/Modules/Catalogue/Models/Item.php
check 'Model adopts its group connection' tinker 'if ((new \App\Modules\Catalogue\Models\Item)->getConnectionName() !== "catalogue") throw new \RuntimeException("Wrong model connection");'
check 'Connected model keeps an explicit override' tinker 'if ((new \App\Modules\Catalogue\Models\Item)->setConnection("sqlite")->getConnectionName() !== "sqlite") throw new \RuntimeException("Lost override");'
check 'Group migration is generated' art mod:migration Catalogue:create_items_table
check 'Group migration carries its connection' bash -c 'grep -F "catalogue" "$1"/app/Modules/Catalogue/Database/Migrations/*create_items_table.php' harness "$APP"
check 'Default migrate omits separate group' art migrate --force
check 'Default database has no group table' tinker 'if (\Illuminate\Support\Facades\Schema::hasTable("items")) throw new \RuntimeException("Wrong database");'
check 'Default migrate has not touched the separate database' tinker 'if (\Illuminate\Support\Facades\Schema::connection("catalogue")->hasTable("items")) throw new \RuntimeException("Group migration leaked into default migrate");'
check 'Selected migrate runs group migration' art migrate --database=catalogue --force
check 'Selected database has group table' tinker 'if (!\Illuminate\Support\Facades\Schema::connection("catalogue")->hasTable("items")) throw new \RuntimeException("Missing table");'
check 'Connection inventory names declared group' out_has catalogue mod:list --json
doc_file 'Seeders' app/Modules/Catalogue/Database/Seeders/CatalogueSeeder.php
check 'Documented fresh and seed commands run' doc_shell 'Migrations' 2
check 'Seeder writes to the group connection' tinker 'if (\Illuminate\Support\Facades\DB::connection("catalogue")->table("items")->count() !== 1) throw new \RuntimeException("Missing seeded row");'
check 'Seeder restores the default connection' tinker '$before = config("database.default"); \Illuminate\Support\Facades\DB::connection("catalogue")->table("items")->delete(); (new \App\Modules\Catalogue\Database\Seeders\CatalogueSeeder)(); if (config("database.default") !== $before) throw new \RuntimeException("Default changed");' 

PAGE=$DOCS/docs/going-further/stubs.md
fresh 'stack-aware member stubs' modules
"$PHP" -r '$f=$argv[1];$j=json_decode(file_get_contents($f),true);$j["dependencies"]["@inertiajs/vue3"]="*";file_put_contents($f,json_encode($j));' "$APP/package.json"
mkdir -p "$APP/app/stubs"
printf '<template>package-vue</template>\n' > "$APP/app/stubs/list.vue.stub"
printf 'export default function Page() { return null; }\n' > "$APP/app/stubs/list.tsx.stub"
cp "$APP/app/stubs/list.tsx.stub" "$APP/app/stubs/list.jsx.stub"
doc_boot 'Stack-aware Scaffold Stubs'
boot "\\Tey\\Mod\\Facades\\Mod::vendor('acme')->scaffold('list', fn (\\Tey\\Mod\\Scaffolds\\Scaffold \$s) => \$s->makes('page', stub: 'list'));"
check 'Package scaffold chooses its stack-specific stub' art mod:acme/list Inventory:Package
check 'Vue variant content appears' grep -F package-vue "$APP/app/Modules/Inventory/resources/js/pages/Package.vue"
mkdir -p "$APP/stubs"
printf '<template>app-vue</template>\n' > "$APP/stubs/mod.page.list.vue.stub"
check 'App variant wins over the registered package stub' art mod:acme/list Inventory:Override
check 'App variant content appears' grep -F app-vue "$APP/app/Modules/Inventory/resources/js/pages/Override.vue"

boot "\\Tey\\Mod\\Facades\\Mod::vendor('acme')->scaffold('custom', fn (\\Tey\\Mod\\Scaffolds\\Scaffold \$s) => \$s->makes('page'), command: 'kit:pages');"
check 'Explicit package command runs with normal placement' art kit:pages Inventory:Custom
check 'Explicit command adds no default alias' fails art mod:acme/custom Inventory:NoAlias
