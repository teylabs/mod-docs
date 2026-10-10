<?php

use Illuminate\Contracts\Console\Kernel;
use Laravel\Mcp\Request;
use Tey\Mod\Boost\PlanTool;
use Tey\Mod\Rename\Executor;
use Tey\Mod\Rename\Process;

[$script,$base] = $argv;
require $base.'/vendor/autoload.php';
$app = require $base.'/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();
$tool = new PlanTool;
$app->bind(Executor::class, fn () => throw new RuntimeException('Read-only tools resolved the executor'));
function bytes(string $base): array
{
    $git = new Process(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], $base, timeout: 60);
    $git->mustRun();
    $paths = array_filter(explode("\0", $git->getOutput()));
    $snapshot = [];
    foreach ($paths as $path) {
        $snapshot[$path] = hash_file('sha256', $base.'/'.$path);
    }
    $snapshot['INDEX'] = hash_file('sha256', $base.'/.git/index');
    ksort($snapshot);

    return $snapshot;
}
$before = bytes($base);
foreach ([['Inventory:Widget', 'Inventory:Gadget', '--scaffold=model-only', '--yes'], ['--recover', '--yes']] as $arguments) {
    $response = $tool->handle(new Request(['command' => 'mod:rename', 'arguments' => $arguments]));
    if ($response->isError()) {
        throw new RuntimeException((string) $response->content());
    }
    $j = json_decode($response->content()->toTool($tool)['text'], true, flags: JSON_THROW_ON_ERROR);
    if ($j['command'] !== 'mod:rename' || ! array_key_exists('would_write', $j)) {
        throw new RuntimeException('Tool plan shape changed');
    }
}
if (bytes($base) !== $before) {
    throw new RuntimeException('MCP changed application bytes, paths or index');
}
if (file_exists($base.'/.git/mod-rename/journal.json') || file_exists($base.'/.git/mod-rename/lock')) {
    throw new RuntimeException('MCP created rename metadata');
}
echo "PASS actual mod-plan rename/recovery requests cannot resolve executor or write\n";
