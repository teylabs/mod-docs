<?php
// A custom entry must produce actionable instructions without changing files.
[$script, $base, $stack] = $argv;
require $base.'/vendor/autoload.php';
$app = require $base.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
set_exception_handler(function (Throwable $error): never {
    fwrite(STDERR, $error->getMessage().PHP_EOL);
    exit(1);
});
$entry = $base.'/resources/js/app.'.($stack === 'vue' ? 'ts' : 'tsx');
$original = file_get_contents($entry);
$css = $base.'/resources/css/app.css';
$originalCss = file_get_contents($css);
$custom = "import { createInertiaApp } from 'custom-modal-adapter';\ncreateInertiaApp({ resolve: async (name) => customLookup(name), setup: existingSetup });\n";
try {
    file_put_contents($entry, $custom);
    unlink($css);
    Illuminate\Support\Facades\Artisan::call('mod:install', ['stack' => 'inertia', '--dry-run' => true, '--json' => true, '--no-interaction' => true]);
    $plan = json_decode(Illuminate\Support\Facades\Artisan::output(), true, flags: JSON_THROW_ON_ERROR);
    $warnings = implode("\n", array_column($plan['warnings'], 'message'));
    if ($plan['would_write'] !== false || file_get_contents($entry) !== $custom) {
        throw new RuntimeException('Custom bootstrap preview did not refuse writes.');
    }
    foreach (['resolveModulePage', 'inside your existing resolve callback', 'with the other imports at the top', 'app/Modules', 'resources/css/app.css', 'after the Tailwind import'] as $instruction) {
        if (! str_contains($warnings, $instruction)) throw new RuntimeException('Missing instruction: '.$instruction);
    }
} finally {
    file_put_contents($entry, $original);
    file_put_contents($css, $originalCss);
}
echo 'Custom adapter retained; preview refuses edits and prints resolver/Tailwind insertion points'.PHP_EOL;
