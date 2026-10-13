PAGE=$DOCS/docs/going-further/routes.md
fresh routes modules
check 'route files and documented output' doc_shell 'Loading Route Files'
# Replace the existing withRouting call with the documented chain fragment.
code=$(doc_block 'Loading Route Files' php 1)
CODE=$code "$PHP" -r '
$f=$argv[1];$s=file_get_contents($f);$code=getenv("CODE");
$s=str_replace("use Illuminate\\Foundation\\Application;", "use Illuminate\\Foundation\\Application;\nuse Tey\\Mod\\Facades\\Mod;",$s);
$code=preg_replace("/^use .+;\\n?/m","",$code);
$s=preg_replace("/->withRouting\\(.*?(?=\\s*->withMiddleware)/s",trim($code),$s,1,$count);
if($count!==1) throw new RuntimeException("Missing bootstrap routing call");
file_put_contents($f,$s);
' "$APP/bootstrap/app.php"
printf '\nRoute::get("widgets", fn () => "widgets");\n' >> "$APP/app/Modules/Inventory/routes/web.php"
check 'bootstrap loader registers the web route' out_has widgets route:list --path=widgets
check 'registrar generator output' doc_shell 'Using Route Registrars'
check 'complete registrar contents match the page' bash -c '"$PHP" "$1" block "$2" "Using Route Registrars" php 1 > "$3" && diff -u "$3" "$4"' harness "$VERIFY/docs.php" "$PAGE" "$WORK/registrar-expected.php" "$APP/app/Modules/Inventory/Http/Routing/InventoryRoutes.php"
check 'route cache' art route:cache
check 'cached route still exists' out_has widgets route:list --path=widgets
art route:clear > /dev/null
check 'route preview JSON' doc_shell 'Inspecting Route Plans'
fresh route-groups modules
art mod:routes Inventory > /dev/null
art mod:routes Knowledge > /dev/null
# Group example is the sole loader in this fixture.
code=$(doc_block 'Using Laravel Route Groups' php 1)
printf '<?php\n%s\n' "$code" > "$APP/routes/web.php"
printf '\nRoute::get("widgets", fn () => "widgets");\n' >> "$APP/app/Modules/Inventory/routes/web.php"
check 'Laravel middleware and URI prefix inheritance' out_has admin/widgets route:list --path=widgets

fresh api-prefix modules
art mod:routes Inventory --api --console > /dev/null
printf '\nRoute::get("prefix-web", fn () => "web");\n' >> "$APP/app/Modules/Inventory/routes/web.php"
printf '\nRoute::get("prefix-api", fn () => "api");\n' >> "$APP/app/Modules/Inventory/routes/api.php"
printf '\nconfig()->set("console_prefix_loaded", true);\n' >> "$APP/app/Modules/Inventory/routes/console.php"
printf '<?php\nuse Tey\\Mod\\Facades\\Mod;\nMod::routes();\n' > "$APP/routes/web.php"
check 'default API prefix remains api' out_has api/prefix-api route:list --path=prefix-api

code=$(doc_block 'Choosing the API Prefix' php 1)
printf '<?php\nuse Tey\\Mod\\Facades\\Mod;\n%s\n' "$code" > "$APP/routes/web.php"
check 'documented call prefix serves v1 API routes' out_has v1/prefix-api route:list --path=prefix-api
check 'web route is unchanged by the API prefix' out_has prefix-web route:list --path=prefix-web
check 'console file is unchanged by the API prefix' out_has true tinker --execute 'dump(config("console_prefix_loaded"));'
check 'human inventory reports the call prefix' out_has 'API prefix: v1' mod:list
check 'route cache keeps the chosen prefix' art route:cache
check 'cached v1 route still exists' out_has v1/prefix-api route:list --path=prefix-api
art route:clear > /dev/null

code=$(doc_block 'Choosing the API Prefix' php 3)
printf '<?php\nuse Tey\\Mod\\Facades\\Mod;\n%s\n' "$code" > "$APP/routes/web.php"
check 'documented empty prefix adds no API segment' out_has '"uri":"prefix-api"' route:list --path=prefix-api --json
check 'human inventory reports no API prefix' out_has 'API prefix: (none)' mod:list

fresh package-prefix modules
mkdir -p "$APP/packages/api-v1/routes" "$APP/app/Routing"
printf '<?php\n\\Illuminate\\Support\\Facades\\Route::get("file-prefix", fn () => "file");\n' > "$APP/packages/api-v1/routes/api.php"
cat > "$APP/app/Routing/ReportsRoutes.php" <<'PHP'
<?php
namespace App\Routing;
class ReportsRoutes implements \Tey\Mod\Routing\RegistersRoutes
{
    public static function web(): void
    {
        \Illuminate\Support\Facades\Route::get('registrar-web', fn () => 'web');
    }
    public static function api(): void
    {
        \Illuminate\Support\Facades\Route::get('registrar-prefix', fn () => 'registrar');
    }
}
PHP
doc_boot 'Choosing the API Prefix' 2
printf '<?php\n\\Tey\\Mod\\Facades\\Mod::routes(apiPrefix: "v2");\n' > "$APP/routes/web.php"
check 'file registration prefix wins over call prefix' out_has v1/file-prefix route:list --path=file-prefix
check 'registrar registration prefix wins over call prefix' out_has v1/registrar-prefix route:list --path=registrar-prefix
check 'registrar web route stays unprefixed' out_has '"uri":"registrar-web"' route:list --path=registrar-web --json
check 'JSON inventory reports each effective API prefix only on API entries' "$PHP" -r '
    $data=json_decode($argv[1],true,512,JSON_THROW_ON_ERROR);
    $api=[];
    foreach ($data["routes"] as $route) {
        if ($route["middleware_group"] === "api") { $api[$route["group"]]=$route["api_prefix"]; }
        elseif (array_key_exists("api_prefix",$route)) { throw new RuntimeException("Non-API entry gained a prefix"); }
    }
    if ($api !== ["api-v1" => "v1", "reports-v1" => "v1"]) { throw new RuntimeException("Unexpected effective API prefixes"); }
' "$(art mod:list --json)"
