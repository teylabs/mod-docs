<?php

use Tey\Mod\Rename\Process;

[$script,$base,$page] = $argv;
require $base.'/vendor/autoload.php';
function run(array $args): string
{
    global $base;
    $p = new Process($args, $base, timeout: 60);
    $p->mustRun();

    return $p->getOutput();
}
$file = $base.'/app/Modules/Inventory/Models/Widget.php';
mkdir(dirname($file), 0777, true);
file_put_contents($file, "<?php\nnamespace App\\Modules\\Inventory\\Models;\nclass Widget {}\n");
foreach (glob($base.'/resources/js/*.{js,ts}', GLOB_BRACE) as $source) {
    unlink($source);
}
run(['git', 'add', '-A']);
run(['git', '-c', 'user.name=Docs harness', '-c', 'user.email=harness@localhost', 'commit', '-qm', 'Commit the exact single-member plan fixture']);
// R14 is deliberately the minimal source-only catalogue fixture, not a frontend kit.
$before = file_get_contents($base.'/.git/index');
$actualText = run([PHP_BINARY, 'artisan', 'mod:rename', 'Inventory:Widget', 'Inventory:Gadget', '--scaffold=model-only', '--dry-run', '--json', '--no-interaction']);
$actual = json_decode($actualText, true, flags: JSON_THROW_ON_ERROR);
if (! json_decode($actualText)->selection->answers instanceof stdClass) {
    throw new RuntimeException('Empty historical answers must remain an object');
}
$expected = json_decode(run([PHP_BINARY, dirname(__DIR__).'/docs.php', 'block', $page, 'Rename plans', 'json', '1']), true, flags: JSON_THROW_ON_ERROR);
if ($actual !== $expected) {
    throw new RuntimeException('Complete R14 plan differs from the documented JSON: '.json_encode($actual));
}
if (file_get_contents($base.'/.git/index') !== $before || run(['git', 'status', '--porcelain']) !== '') {
    throw new RuntimeException('R14 preview wrote');
}
echo "PASS exact complete R14 JSON and preview no-write\n";
