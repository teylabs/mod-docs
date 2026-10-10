<?php

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\Schema;
use Tey\Mod\Rename\Process;

// Behaviour assertions run against the installed package and real Git index.
[$script, $app, $mode, $planFile] = array_pad($argv, 4, '');
require $app.'/vendor/autoload.php';
function demand(bool $ok, string $why): void
{
    if (! $ok) {
        throw new RuntimeException($why);
    }
}
function command(array $args, string $cwd): string
{
    $p = new Process($args, $cwd, timeout: 60);
    $p->mustRun();

    return $p->getOutput();
}
$plan = $planFile ? json_decode(file_get_contents($planFile), true, flags: JSON_THROW_ON_ERROR) : [];
if ($mode === 'preview') {
    demand($plan['would_write'] && ! $plan['warnings'], json_encode($plan['warnings']));
    demand(count($plan['moves']) === 11, 'Expected seven PHP members and four pages');
    demand(count(array_filter($plan['rewrites'], fn ($r) => $r['category'] === 'frontend-import')) >= 2, 'Real parser must rewrite imports');
    demand(command(['git', 'status', '--porcelain'], $app) === '', 'Preview dirtied the app');
} elseif ($mode === 'applied') {
    foreach ($plan['moves'] as $move) {
        demand(! file_exists($app.'/'.$move['from']) && is_file($app.'/'.$move['to']), 'Move failed: '.$move['to']);
    }
    $staged = array_filter(explode("\n", trim(command(['git', 'diff', '--cached', '--no-renames', '--name-only'], $app))));
    $expected = [];
    foreach ($plan['moves'] as $m) {
        $expected[] = $m['from'];
        $expected[] = $m['to'];
    }
    foreach ($plan['rewrites'] as $r) {
        $expected[] = $r['after_file'];
    }
    foreach ($plan['files'] as $f) {
        $expected[] = $f['path'];
    }
    sort($staged);
    $expected = array_values(array_unique($expected));
    sort($expected);
    demand($staged === $expected, 'Staged manifest differs: '.json_encode([$expected, $staged]));
    demand(command(['git', 'diff', '--name-only'], $app) === '', 'Unstaged source changes');
    foreach ($plan['rewrites'] as $r) {
        demand(str_contains(file_get_contents($app.'/'.$r['after_file']), $r['after']), 'Missing rewrite '.$r['after']);
    }
} elseif ($mode === 'fallback') {
    demand($plan['would_write'] && ! $plan['warnings'], 'Fallback must permit reviewed moves');
    demand(count(array_filter($plan['checklist'], fn ($r) => $r['category'] === 'frontend-toolchain' && $r['line'] > 0 && $r['after_file'] && $r['suggestion'])) >= 2, 'Located fallback suggestions missing');
    demand(! array_filter($plan['rewrites'], fn ($r) => str_starts_with($r['category'], 'frontend-')), 'Fallback guessed source edits');
} elseif ($mode === 'table') {
    demand(count($plan['files']) === 1, 'Selected migration absent');
    $f = $plan['files'][0];
    $bytes = file_get_contents($app.'/'.$f['path']);
    $expected = "<?php\n\nuse Illuminate\\Database\\Migrations\\Migration;\nuse Illuminate\\Support\\Facades\\Schema;\n\nreturn new class extends Migration\n{\n    public function up(): void\n    {\n        Schema::rename('widgets', 'gadgets');\n    }\n\n    public function down(): void\n    {\n        Schema::rename('gadgets', 'widgets');\n    }\n};\n";
    demand($bytes === $expected, 'Migration bytes differ');
    demand($f['path'] === 'app/Modules/Inventory/Database/Migrations/2026_10_09_163000_rename_widgets_to_gadgets_table.php', 'Migration placement/name differs');
    $laravel = require $app.'/bootstrap/app.php';
    $laravel->make(Kernel::class)->bootstrap();
    demand(Schema::hasTable('widgets') && ! Schema::hasTable('gadgets'), 'Rename changed database schema');
}
echo 'PASS '.$mode."\n";
