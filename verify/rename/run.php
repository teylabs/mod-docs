<?php

// One baseline per kit; focused independent fixtures reset only this disposable app.
[$script,$base,$stack,$work] = $argv;
require $base.'/vendor/autoload.php';
require __DIR__.'/schema.php';
use Tey\Mod\Rename\Process;
use Tey\Mod\Tests\Support\JsonSchema;

function need(bool $ok, string $why): void
{
    if (! $ok) {
        throw new RuntimeException($why);
    }
}
function run(array $args, int $timeout = 120): string
{
    global $base;
    $p = new Process($args, $base, timeout: $timeout);
    $p->mustRun();

    return $p->getOutput();
}
function art(array $args): string
{
    return run([PHP_BINARY, 'artisan', ...$args, '--no-ansi', '--no-interaction']);
}
function commit(string $message): void
{
    run(['git', 'add', '-A']);
    if (trim(run(['git', 'diff', '--cached', '--name-only'])) === '') {
        return;
    } run(['git', '-c', 'user.name=Docs harness', '-c', 'user.email=harness@localhost', 'commit', '-qm', $message]);
}
function snapshot(): array
{
    global $base;
    $files = explode("\0", run(['git', 'ls-files', '-z']));
    $out = [];
    foreach (array_filter($files) as $f) {
        $out[$f] = (is_file($base.'/'.$f) ? hash_file('sha256', $base.'/'.$f) : null);
    } $out['INDEX'] = hash_file('sha256', $base.'/.git/index');

    return $out;
}
function preview(string $old, string $new, array $flags = []): array
{
    global $base,$work,$stack;
    $before = snapshot();
    $text = art(['mod:rename', $old, $new, '--scaffold=crud-pages', '--dry-run', '--json', ...$flags]);
    $j = json_decode($text, true, flags: JSON_THROW_ON_ERROR);
    $errors = JsonSchema::errors($j, json_decode(file_get_contents(dirname(__DIR__, 2).'/docs/public/schemas/rename.json'), true));
    need($errors === [], json_encode($errors));
    need(snapshot() === $before, 'Preview changed bytes/index');
    file_put_contents($work.'/rename-'.basename($base).'.json', $text);

    return $j;
}
function checkPlan(array $plan, string $mode): void
{
    global $work,$base;
    $file = $work.'/check-plan-'.basename($base).'.json';
    file_put_contents($file, json_encode($plan));
    echo run([PHP_BINARY, __DIR__.'/check.php', $base, $mode, $file]);
}
function apply(string $old, string $new, array $plan, array $flags = []): void
{
    echo art(['mod:rename', $old, $new, '--scaffold=crud-pages', '--yes', ...$flags]);
    checkPlan($plan, 'applied');
}
function resetBaseline(): void
{
    global $baseline;
    run(['git', 'reset', '--hard', $baseline]);
    run(['git', 'clean', '-fd']);
}
echo art(['--version']);
echo run(['node', __DIR__.'/versions.cjs', $base]);
$vue = $stack === 'vue';
$suffix = $vue ? '.vue' : '';
$folder = $vue ? 'Widget' : 'widget';
$next = $vue ? 'Gadget' : 'gadget';
$ext = $vue ? 'vue' : 'tsx';
$index = $vue ? 'Index' : 'index';
$oldPage = "app/Modules/Inventory/resources/js/pages/$folder/$index.$ext";
$gadgetPage = "app/Modules/Inventory/resources/js/pages/$next/$index.$ext";
commit('Commit the explicit app-owned cluster');
$baseline = trim(run(['git', 'rev-parse', 'HEAD']));
$historical = [];
foreach (glob($base.'/app/Modules/Inventory/Database/Migrations/*.php') as $f) {
    $historical[$f] = hash_file('sha256', $f);
}
$database = new PDO('sqlite:'.$base.'/database/database.sqlite');
$schemaBefore = $database->query('SELECT type,name,tbl_name,sql FROM sqlite_master ORDER BY type,name')->fetchAll(PDO::FETCH_ASSOC);
// R12 executes a selected candidate without changing the database or old migrations.
$model = $base.'/app/Modules/Inventory/Models/Widget.php';
$s = file_get_contents($model);
file_put_contents($model, str_replace("    protected \$table = 'widgets';", '', $s));
commit('Use inferred table naming');
$p = preview('Inventory:Widget', 'Inventory:Gadget', ['--table-migration']);
apply('Inventory:Widget', 'Inventory:Gadget', $p, ['--table-migration']);
checkPlan($p, 'table');
need($database->query('SELECT type,name,tbl_name,sql FROM sqlite_master ORDER BY type,name')->fetchAll(PDO::FETCH_ASSOC) === $schemaBefore, 'Rename changed the database schema');
foreach ($historical as $f => $hash) {
    need(hash_file('sha256', $f) === $hash, 'Historical migration changed');
} resetBaseline();
// R1 with actual parser edits, followed by independent fallback execution.
$p = preview('Inventory:Widget', 'Inventory:Gadget');
checkPlan($p, 'preview');
apply('Inventory:Widget', 'Inventory:Gadget', $p);
resetBaseline();
// One representative real termination/rollback for the application harness, not all fault permutations.
if ($vue) {
    $before = snapshot();
    $worker = new Process([PHP_BINARY, __DIR__.'/worker.php', $base, 'applied:2'], $base, timeout: 60);
    $worker->start();
    try {
        do {
            $worker->checkTimeout();
            $alive = $worker->isRunning();
            if (str_contains($worker->getOutput(), 'BARRIER')) {
                break;
            } need($alive, 'Worker exited before checkpoint: '.$worker->getErrorOutput());
            usleep(1000);
        } while (true);
    } finally {
        $worker->stop(0, 9);
    }
    $inspection = json_decode(art(['mod:rename', '--recover', '--dry-run', '--json']), true, flags: JSON_THROW_ON_ERROR);
    need($inspection['recovery']['phase'] === 'applying', 'Missing interrupted journal');
    $unchanged = snapshot();
    art(['mod:rename', '--recover', '--dry-run', '--json']);
    need(snapshot() === $unchanged, 'Recovery inspection wrote');
    file_put_contents($base.'/notes.txt', 'outside edit');
    echo art(['mod:rename', '--recover', '--yes']);
    need(file_get_contents($base.'/notes.txt') === 'outside edit', 'Recovery lost outside file');
    unlink($base.'/notes.txt');
    need(snapshot() === $before, 'Recovery failed exact byte/index restoration');
    echo "PASS real process interruption and recovery\n";
}
$original = file_get_contents($base.'/'.$oldPage);
$referenceBytes = [];
foreach ($p['rewrites'] as $r) {
    if (str_starts_with($r['category'], 'frontend-')) {
        $referenceBytes[$r['after_file']] = file_get_contents($base.'/'.$r['file']);
    }
}
file_put_contents($base.'/.git/info/exclude', "\n/node_modules.disabled/\n", FILE_APPEND);
rename($base.'/node_modules', $base.'/node_modules.disabled');
try {
    $fallback = preview('Inventory:Widget', 'Inventory:Gadget');
    checkPlan($fallback, 'fallback');
    apply('Inventory:Widget', 'Inventory:Gadget', $fallback);
    need(file_get_contents($base.'/'.$gadgetPage) === $original, 'Fallback changed source reference bytes');
    foreach ($referenceBytes as $file => $bytes) {
        need(file_get_contents($base.'/'.$file) === $bytes, 'Fallback changed reference bytes in '.$file);
    }
} finally {
    rename($base.'/node_modules.disabled', $base.'/node_modules');
}
// Deliberate manual fixes: only the reported static import locations, from the parsed reference plan.
foreach ($p['rewrites'] as $r) {
    if (str_starts_with($r['category'], 'frontend-')) {
        $f = $base.'/'.$r['after_file'];
        $s = file_get_contents($f);
        need(str_contains($s, $r['before']), 'Manual fix source missing');
        file_put_contents($f, str_replace($r['before'], $r['after'], $s));
    }
}
echo "PASS fallback bytes preserved; manual wiring fixes applied before runtime claims\n";
// Main parsed R1/R2 flow. Commit only in the disposable fixture between separate operations.
commit('Review the fallback rename and deliberate manual fixes');
$p = preview('Inventory:Gadget', 'Catalog:Gadget');
apply('Inventory:Gadget', 'Catalog:Gadget', $p);
commit('Review the moved cluster');
need(str_contains(file_get_contents($base.'/resources/js/rename-consumer.ts'), "@modules/Catalog/resources/js/pages/$next/$index$suffix"), 'Canonical module alias missing');
need(str_contains(file_get_contents($base.'/app/Modules/Catalog/resources/js/pages/'.$next.'/'.$index.'.'.$ext), '../../../../../Inventory/resources/js/components/'), 'Relative neighbour lost original binding');
// Build and request the renamed module pages before testing a distinct mirrored layout.
echo run(['npm', 'run', 'build'], 300);
echo run([PHP_BINARY, dirname(__DIR__).'/frontend/prepare-kit.php', $base, str_contains(basename($base), '12') ? '12' : '13', $stack, 'after']);
echo run(['npx', $vue ? 'vue-tsc' : 'tsc', '--noEmit'], 180);
$moduleComponent = $vue ? 'Catalog::Gadget/Index' : 'Catalog::gadget/index';
echo run([PHP_BINARY, dirname(__DIR__).'/frontend/request.php', $base, $moduleComponent]);
need(str_contains(file_get_contents($base.'/public/build/manifest.json'), 'app/Modules/Catalog/resources/js/pages/'.$next.'/'.$index.'.'.$ext), 'Built manifest lacks moved module page');
file_put_contents($work.'/runtime-'.basename($base).'-modules.txt', $moduleComponent."\n");
echo "PASS module aliases, repaired fallback wiring, full build/type check and HTTP\n";
// R17: mirror app-owned pages and canonical @ imports, then move through the compiled roots.
$provider = $base.'/app/Providers/AppServiceProvider.php';
$s = file_get_contents($provider);
$s = str_replace('public function boot(): void {', "public function boot(): void {\n\\Tey\\Mod\\Facades\\Mod::layout('modules')->frontend(pages: 'resources/js/pages/{module}', pageName: '{module}/{path}');", $s);
file_put_contents($provider, $s);
function relative(string $from, string $to): string
{
    $a = explode('/', dirname($from));
    $b = explode('/', $to);
    while ($a && $b && $a[0] === $b[0]) {
        array_shift($a);
        array_shift($b);
    }

    return str_repeat('../', count($a)).implode('/', $b);
}
$moduleRoot = 'app/Modules/Catalog/resources/js/pages/'.$next;
$mirrorRoot = 'resources/js/pages/Catalog/'.$next;
mkdir($base.'/'.$mirrorRoot, 0777, true);
foreach (glob($base.'/'.$moduleRoot.'/*.'.$ext) as $file) {
    $old = substr($file, strlen($base) + 1);
    $new = $mirrorRoot.'/'.basename($file);
    $bytes = file_get_contents($file);
    $bytes = str_replace('@modules/Catalog/resources/js/pages/', '@/pages/Catalog/', $bytes);
    if (str_contains($bytes, 'Inventory/resources/js/components/')) {
        $near = 'app/Modules/Inventory/resources/js/components/'.($vue ? 'Neighbour.vue' : 'neighbour');
        $bytes = preg_replace("~(?:\.\./)+Inventory/resources/js/components/[^'\\n]+~", relative($new, $near), $bytes);
    } file_put_contents($base.'/'.$new, $bytes);
    unlink($file);
}
$f = $base.'/resources/js/rename-consumer.ts';
file_put_contents($f, str_replace('@modules/Catalog/resources/js/pages/', '@/pages/Catalog/', file_get_contents($f)));
$f = $base.'/app/Modules/Catalog/Http/Controllers/GadgetController.php';
file_put_contents($f, str_replace('Catalog::', 'Catalog/', file_get_contents($f)));
commit('Configure mirrored application pages');
$p = preview('Catalog:Gadget', 'Inventory:Gadget');
apply('Catalog:Gadget', 'Inventory:Gadget', $p);
commit('Review mirrored page relocation');
need(str_contains(file_get_contents($base.'/resources/js/rename-consumer.ts'), '@/pages/Inventory/'.$next.'/'.$index.$suffix), 'Mirrored canonical app alias missing');
need(! str_contains(file_get_contents($base.'/resources/js/rename-consumer.ts'), '@modules/../'), 'Alias escaped module root');
echo "PASS mirrored @ paths and configured page identities\n";
echo run(['npm', 'run', 'build'], 300);
echo run([PHP_BINARY, dirname(__DIR__).'/frontend/prepare-kit.php', $base, str_contains(basename($base), '12') ? '12' : '13', $stack, 'after']);
echo run(['npx', $vue ? 'vue-tsc' : 'tsc', '--noEmit'], 180);
$component = $vue ? 'Inventory/Gadget/Index' : 'Inventory/gadget/index';
echo run([PHP_BINARY, dirname(__DIR__).'/frontend/request.php', $base, $component]);
$manifest = file_get_contents($base.'/public/build/manifest.json');
need(str_contains($manifest, 'resources/js/pages/Inventory/'.$next.'/'.$index.'.'.$ext), 'Built manifest lacks renamed page');
file_put_contents($work.'/runtime-'.basename($base).'.txt', $component."\n");
echo "PASS build, full type check, exact HTTP component and built page identity\n";
