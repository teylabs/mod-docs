<?php

use Illuminate\Config\Repository;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Filesystem\Filesystem;
use Illuminate\Foundation\Application;
use Tey\Mod\Facades\Mod;
use Tey\Mod\Layout\CompiledLayout;
use Tey\Mod\ModServiceProvider;
use Tey\Mod\Rename\Process;

[$script,$base,$page] = $argv;
require $base.'/vendor/autoload.php';
$app = require $base.'/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();
function block(string $page, string $heading): string
{
    $p = new Process([PHP_BINARY, __DIR__.'/docs.php', 'block', $page, $heading, 'php', '1']);
    $p->mustRun();

    return $p->getOutput();
}
$before = Mod::current()->fileTypes();
eval(block($page, 'Isolated layouts and public values'));
if ($invoice->fqcn() !== 'Domain\\Billing\\Internal\\Models\\Invoice' || $owned?->path() !== $invoice->path()) {
    throw new RuntimeException('Placement and lookup disagree');
}
if (Mod::current()->fileTypes() !== $before) {
    throw new RuntimeException('Isolated layout changed the app');
}
$cache = $base.'/bootstrap/cache/host-discovery.php';
if (file_exists($cache)) {
    throw new RuntimeException('Host cache fixture must start absent');
}
eval(block($page, 'Host discovery and cache policy'));
if (file_exists($cache)) {
    throw new RuntimeException('Cache read/fallback wrote');
}
$host = new Application($base);
$host->instance('files', new Filesystem);
$host->instance('config', new Repository([]));
$sentinel = new stdClass;
$host->instance('migration.creator', $sentinel);
ModServiceProvider::registerGenerationServices($host);
ModServiceProvider::registerGenerationServices($host);
if ($host->make('migration.creator') !== $sentinel || $host->bound(CompiledLayout::class)) {
    throw new RuntimeException('Targeted defaults overwrote host bindings or bound an active layout');
}
echo "PASS isolated placement/lookup, cache-only read/cold fallback, idempotent host defaults\n";
