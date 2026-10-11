<?php
// Verify real Inertia finders, then apply the documented root Blade entry.
[$script, $base, $stack] = $argv;
require $base.'/vendor/autoload.php';
$app = require $base.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
set_exception_handler(function (Throwable $error): never {
    fwrite(STDERR, $error->getMessage().PHP_EOL);
    exit(1);
});
$component = $stack === 'vue' ? 'Inventory::Widget/Index' : 'Inventory::widget/index';
$extension = $stack === 'vue' ? 'vue' : 'tsx';
$entry = Tey\Mod\Facades\Mod::pageEntry($component, $extension);
if (! is_file($base.'/'.$entry)) {
    throw new RuntimeException('Page entry does not identify the generated page.');
}
foreach (['inertia.view-finder', 'inertia.testing.view-finder'] as $binding) {
    if (! $app->bound($binding)) continue;
    if (realpath($app->make($binding)->find($component)) !== realpath($base.'/'.$entry)) {
        throw new RuntimeException('Inertia finder disagrees with the page entry.');
    }
    try {
        $app->make($binding)->find('Inventory::Missing');
        throw new RuntimeException('A missing qualified page was accepted.');
    } catch (InvalidArgumentException) {
        // The missing page must still fail.
    }
}
$blade = $base.'/resources/views/app.blade.php';
$source = file_get_contents($blade);
$source = preg_replace_callback('/"resources\/js\/pages\/\{\$page\[\x27component\x27\]\}\.'.$extension.'"/',
    fn () => "\\Tey\\Mod\\Facades\\Mod::pageEntry(\$page['component'], '".$extension."')", $source, -1, $count);
if ($count !== 1) throw new RuntimeException('Pinned Blade page entry changed.');
file_put_contents($blade, $source);
echo 'Qualified page found, missing page rejected, root Blade uses pageEntry'.PHP_EOL;
