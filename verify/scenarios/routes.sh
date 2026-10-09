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
