<?php

// Execute the page's fenced inputs in disposable starter kits, then check outcomes.
[$script, $mode, $base, $stack, $major, $modal, $work] = $argv;
require $base.'/vendor/autoload.php';
$vue = $stack === 'vue';
$extension = $vue ? 'vue' : 'tsx';
$hasModal = $modal === 'modal';
$root = 'app/Modules/Inventory/resources/js/pages/';

function demand(bool $condition, string $message): void
{
    if (! $condition) throw new RuntimeException($message);
}

function block(string $heading, string $language, int $index = 1): string
{
    $process = new Symfony\Component\Process\Process([
        PHP_BINARY, dirname(__DIR__).'/docs.php', 'block',
        dirname(__DIR__, 2).'/docs/going-further/frontend.md', $heading, $language, (string) $index,
    ]);
    $process->mustRun();
    return $process->getOutput();
}

function write(string $path, string $source): void
{
    if (! is_dir(dirname($path))) mkdir(dirname($path), 0777, true);
    file_put_contents($path, $source);
}

if ($mode === 'prepare') {
    $recipe = block('Declare the Shape', 'php');
    preg_match_all('/^use .+;$/m', $recipe, $imports);
    $body = preg_replace('/^use .+;\n?/m', '', $recipe);
    write($base.'/app/Providers/AppServiceProvider.php', "<?php\nnamespace App\\Providers;\nuse Illuminate\\Support\\ServiceProvider;\n".implode("\n", $imports[0])."\nclass AppServiceProvider extends ServiceProvider { public function register(): void {} public function boot(): void {\n".$body."\n} }\n");
    write($base.'/stubs/mod.controller.shape.stub', block('Supply the Shape Controller Templates', 'php'));
    write($base.'/stubs/mod.insert.shape-action.stub', block('Supply the Shape Controller Templates', 'php', 2));
    foreach (['page', 'tab', 'layout'] as $index => $variant) {
        write($base.'/stubs/mod.page.shape-'.$variant.'.'.$extension.'.stub', block($vue ? 'Supply the Shape Vue Templates' : 'Shape React Variant', $vue ? 'vue' : 'tsx', $index + 1));
    }
    $routes = block('Check Shape Entries and Routes', 'php', 2);
    if ($hasModal) $routes .= "\nRoute::get('/widgets/create-modal', [WidgetController::class, 'createModal']);\n";
    write($base.'/routes/widgets.php', $routes);
    // A plain handwritten helper, deliberately not declared as a recipe member.
    write($base.'/'.$root.'Widget/Partials/Card.'.$extension, $vue
        ? block('Rename the Shape Tree', 'vue')
        : "export default function Card() { return <p>Hand-written card</p>; }\n");
    echo "Documented recipe, templates, routes and handwritten partial prepared\n";
    exit;
}

if ($mode === 'wire') {
    // Apply the documented manual lookup without replacing adapter/setup/plugins.
    $file = $base.'/resources/js/app.'.($vue ? 'ts' : 'tsx');
    $source = file_get_contents($file);
    $snippet = block($vue ? 'Choose the Shape Folder Layout' : 'Shape React Variant', $vue ? 'ts' : 'tsx', $vue ? 1 : 4);
    [$declarations, $callback] = explode('// Inside createInertiaApp options:', $snippet);
    if ($vue) $source = str_replace("import type { DefineComponent } from 'vue';\n", '', $source);
    $source = $declarations."\n".$source;
    $type = $vue ? 'DefineComponent' : 'ComponentType<PropsWithChildren>';
    $appMap = "import.meta.glob<".$type.">('./pages/**/*.".$extension."')";
    $moduleMap = "import.meta.glob<".$type.">(['../../app/Modules/*/resources/js/pages/**/Page.".$extension."', '../../app/Modules/*/resources/js/pages/**/Modal.".$extension."'])";
    if ($major === '13') {
        $source = preg_replace('/^    layout: \(name\) => \{.*?^    \},/ms', trim($callback), $source, -1, $count);
        demand($count === 1, 'Pinned Inertia 3 layout callback changed');
        $resolve = '    resolve: (name) => resolveModulePage(name, '.$appMap.', '.$moduleMap.'),';
    } else {
        $pageType = $vue
            ? '{ default: DefineComponent & { layout?: DefineComponent[] } }'
            : '{ default: ComponentType & { layout?: (page: ReactNode) => ReactNode } }';
        $source = "type PageModule = ".$pageType.";\n".$source;
        $appMap = str_replace('<'.$type.'>', '<PageModule>', $appMap);
        $moduleMap = str_replace('<'.$type.'>', '<PageModule>', $moduleMap);
        if ($vue) {
            $body = block('Choose the Shape Folder Layout', 'ts', 2);
        } else {
            $source = "import { createElement, type ReactNode } from 'react';\n".$source;
            $body = block('Shape React Variant', 'tsx', 5);
        }
        $body = str_replace(['appPages', 'modulePages'], [$appMap, $moduleMap], $body);
        $resolve = "    resolve: async (name) => {\n".$body."    },";
    }
    $source = preg_replace('/^    resolve:.*$/m', $resolve, $source, -1, $count);
    demand($count === 1, 'Pinned resolver callback changed');
    write($file, $source);
    echo "Documented nearest-folder layout wired; existing app-page lookup retained\n";
    exit;
}

$app = require $base.'/bootstrap/app.php';
try {
    $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
} catch (Throwable $error) {
    fwrite(STDERR, $error->getMessage().PHP_EOL);
    exit(1);
}
set_exception_handler(function (Throwable $error): never {
    fwrite(STDERR, $error->getMessage().PHP_EOL);
    exit(1);
});
if ($mode === 'preview') {
    $plan = json_decode(file_get_contents($work.'/page-shape-'.$major.'-'.$stack.'-'.$modal.'-preview.json'), true, flags: JSON_THROW_ON_ERROR);
    demand($plan['would_write'] === true && $plan['warnings'] === [], 'Rename preview is blocked');
    $folders = array_values(array_filter($plan['moves'], fn ($move) => $move['type'] === 'folder'));
    demand(count($folders) === 1 && $folders[0]['from'] === rtrim($root, '/').'/Widget' && $folders[0]['to'] === rtrim($root, '/').'/Gadget', 'Expected one owned folder move');
    echo "Unblocked preview moves the page folder once\n";
    exit;
}
if ($mode === 'generated' || $mode === 'grown') {
    $expected = ['Index/Page', 'Create/Page', 'Edit/Layout', 'Edit/Overview/Page', 'Edit/Details/Page'];
    if ($hasModal) $expected[] = 'Create/Modal';
    if ($mode === 'grown') $expected[] = 'Edit/History/Page';
    $actual = [];
    $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($base.'/'.$root.'Widget', FilesystemIterator::SKIP_DOTS));
    foreach ($files as $file) {
        $relative = substr($file->getPathname(), strlen($base.'/'.$root.'Widget/'));
        if (str_starts_with($relative, 'Partials/')) continue;
        $actual[] = substr($relative, 0, -strlen('.'.$extension));
    }
    sort($actual); sort($expected);
    demand($actual === $expected, 'Generated page tree differs: '.json_encode($actual));
    $controller = file_get_contents($base.'/app/Modules/Inventory/Http/Controllers/WidgetController.php');
    demand(str_contains($controller, 'function createModal()') === $hasModal, 'Optional controller block disagrees with modal choice');
    foreach (['indexPage' => 'Index/Page', 'createPage' => 'Create/Page'] as $path) {
        demand(str_contains($controller, "Inertia::render('Inventory::Widget/".$path."')"), 'Controller has the wrong render identity');
    }
    if ($mode === 'generated') {
        $output = file_get_contents($work.'/page-shape-'.$major.'-'.$stack.'-'.$modal.'-generate.txt');
        demand(str_contains($output, 'Page ['.$root.'Widget/Edit/Layout.'.$extension.'] created successfully. Not a page entry; import it from a page.'), 'Layout was not generated as a non-entry page');
        demand(! str_contains($output, "Inertia::render('Inventory::Widget/Edit/Layout')"), 'Layout was advertised as a render entry');
        $snapshot = [];
        foreach ($actual as $path) $snapshot[$path] = file_get_contents($base.'/'.$root.'Widget/'.$path.'.'.$extension);
        write($work.'/shape-before-growth-'.$major.'-'.$stack.'-'.$modal.'.json', json_encode($snapshot, JSON_THROW_ON_ERROR));
    } else {
        $snapshot = json_decode(file_get_contents($work.'/shape-before-growth-'.$major.'-'.$stack.'-'.$modal.'.json'), true, flags: JSON_THROW_ON_ERROR);
        foreach ($snapshot as $path => $bytes) demand(file_get_contents($base.'/'.$root.'Widget/'.$path.'.'.$extension) === $bytes, 'Growth rewrote '.$path);
        demand(str_contains($controller, "Inertia::render('Inventory::Widget/Edit/History/Page')"), 'Grown action has the wrong render identity');
        $entry = Tey\Mod\Facades\Mod::pageEntry('Inventory::Widget/Edit/History/Page', $extension);
        demand($entry === $root.'Widget/Edit/History/Page.'.$extension, 'Entry maps to the wrong path');
        foreach (['Edit/Layout', 'Partials/Card'] as $nonEntry) {
            try {
                Tey\Mod\Facades\Mod::pageEntry('Inventory::Widget/'.$nonEntry, $extension);
                throw new RuntimeException('Non-entry was accepted: '.$nonEntry);
            } catch (InvalidArgumentException $error) {
                demand(str_contains($error->getMessage(), $root.'Widget/'.$nonEntry.'.'.$extension), 'Refusal did not name the non-entry path');
            }
        }
    }
    echo "Exact tree and modal block match; growth preserves earlier pages; helpers refused\n";
    exit;
}

if ($mode === 'renamed') {
    demand(! is_dir($base.'/'.$root.'Widget'), 'Old page folder remains');
    demand(! is_file($base.'/app/Modules/Inventory/Http/Controllers/WidgetController.php'), 'Old controller remains');
    $partial = $root.'Gadget/Partials/Card.'.$extension;
    $old = new Symfony\Component\Process\Process(['git', 'show', 'HEAD:'.$root.'Widget/Partials/Card.'.$extension], $base);
    $old->mustRun();
    demand(file_get_contents($base.'/'.$partial) === $old->getOutput(), 'Handwritten partial bytes changed');
    $controller = file_get_contents($base.'/app/Modules/Inventory/Http/Controllers/GadgetController.php');
    foreach (['Index/Page', 'Create/Page', 'Edit/Overview/Page', 'Edit/Details/Page', 'Edit/History/Page', ...($hasModal ? ['Create/Modal'] : [])] as $path) {
        demand(str_contains($controller, "Inertia::render('Inventory::Gadget/".$path."')"), 'Render literal not rewritten: '.$path);
    }
    demand(str_contains(file_get_contents($base.'/routes/widgets.php'), "inertia('Inventory::Gadget/Edit/Overview/Page')"), 'Handwritten render literal not rewritten');
    demand(is_file($base.'/'.$root.'Gadget/Edit/Layout.'.$extension), 'Folder layout did not move');
    demand(is_file($base.'/'.$root.'Gadget/Create/Modal.'.$extension) === $hasModal, 'Rename changed optional member presence');
    $manifest = json_decode(file_get_contents($base.'/public/build/manifest.json'), true, flags: JSON_THROW_ON_ERROR);
    demand(isset($manifest[$root.'Gadget/Edit/History/Page.'.$extension]), 'Build manifest lacks the renamed grown page');
    demand(! isset($manifest[$root.'Gadget/Edit/Layout.'.$extension]), 'Folder layout became a page entry');
    demand(! isset($manifest[$partial]), 'Handwritten partial became a page entry');
    echo "Owned folder and partial moved; render literals rewritten; manifest contains entries, not helpers\n";
    exit;
}

throw new RuntimeException('Unknown page-shape check: '.$mode);
